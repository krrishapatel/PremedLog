import Foundation
import Observation
import StoreKit

/// StoreKit 2 purchases + entitlement state.
/// In the simulator, products come from `PremedLog.storekit` (wired into the scheme's Run action).
@MainActor
@Observable
final class EntitlementManager {
    enum ProductID {
        static let monthly = "premedlog.pro.monthly"
        static let yearly = "premedlog.pro.yearly"
        static let lifetime = "premedlog.pro.lifetime"
        static let all = [yearly, monthly, lifetime]
    }

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoadingProducts = false
    private(set) var productLoadError: String?

    /// DEBUG-only override (launch with `-pro`) so screenshots can show Pro features.
    let debugUnlocked: Bool

    var isPro: Bool { debugUnlocked || !purchasedProductIDs.isEmpty }

    private var updatesTask: Task<Void, Never>?

    init() {
        debugUnlocked = LaunchOptions.forcePro
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
            productLoadError = loaded.isEmpty ? "Store unavailable. Run from Xcode with the PremedLog.storekit configuration to test purchases." : nil
        } catch {
            productLoadError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIDs = owned
        UserDefaults.standard.set(isPro, forKey: "isProCached")
    }

    /// Returns true if the purchase completed and Pro is now unlocked.
    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    var activePlanName: String? {
        if purchasedProductIDs.contains(ProductID.lifetime) { return "Lifetime" }
        if purchasedProductIDs.contains(ProductID.yearly) { return "Yearly" }
        if purchasedProductIDs.contains(ProductID.monthly) { return "Monthly" }
        if debugUnlocked { return "Debug unlock" }
        return nil
    }
}
