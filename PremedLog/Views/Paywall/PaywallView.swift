import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(EntitlementManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedID = EntitlementManager.ProductID.yearly
    @State private var purchasing = false
    @State private var errorMessage: String?

    private struct Plan: Identifiable {
        let id: String
        let title: String
        let fallbackPrice: String
        let period: String
        let note: String?
        let badge: String?
    }

    private let plans: [Plan] = [
        Plan(id: EntitlementManager.ProductID.yearly, title: "Yearly", fallbackPrice: "$29.99", period: "/ year",
             note: "Just $2.50 a month", badge: "Save 50%"),
        Plan(id: EntitlementManager.ProductID.monthly, title: "Monthly", fallbackPrice: "$4.99", period: "/ month",
             note: nil, badge: nil),
        Plan(id: EntitlementManager.ProductID.lifetime, title: "Lifetime", fallbackPrice: "$49.99", period: "once",
             note: "Pay once, through med school", badge: nil)
    ]

    private let features: [(String, String, String)] = [
        ("infinity", "Unlimited activities", "Track every experience, not just 5"),
        ("wand.and.stars", "Draft from your notes", "Turn reflections into AMCAS-ready descriptions"),
        ("doc.richtext", "PDF & CSV export", "AMCAS-formatted, ready for advisors"),
        ("rectangle.3.group", "All widgets", "Home & Lock Screen progress at a glance")
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    if store.isPro {
                        Label("You're Pro — thank you!", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.teal)
                            .padding()
                    } else {
                        planPicker
                        purchaseButton
                    }
                    footer
                }
                .padding(.bottom, 32)
            }
            .background(Theme.background)
            .ignoresSafeArea(edges: .top)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.25), in: Circle())
            }
            .padding()
            .accessibilityLabel("Close")
        }
        .alert("Purchase failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .task { await store.loadProducts() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(.white.opacity(0.18)).frame(width: 92, height: 92)
                Image(systemName: "stethoscope")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 70)
            Text("PremedLog Pro")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Text("Your hours are logged. Now let them write your application.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 32)
        .background(Theme.heroGradient)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.1) { symbol, title, subtitle in
                HStack(spacing: 14) {
                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundStyle(Theme.teal)
                        .frame(width: 36, height: 36)
                        .background(Theme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).font(.subheadline.weight(.semibold))
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planPicker: some View {
        VStack(spacing: 10) {
            ForEach(plans) { plan in
                let selected = plan.id == selectedID
                let product = store.product(for: plan.id)
                Button {
                    withAnimation(.snappy) { selectedID = plan.id }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selected ? Theme.teal : Color.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(plan.title).font(.headline)
                                if let badge = plan.badge {
                                    Text(badge)
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Theme.teal, in: Capsule())
                                        .foregroundStyle(.white)
                                }
                            }
                            if let note = plan.note {
                                Text(note).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(product?.displayPrice ?? plan.fallbackPrice).font(.headline).monospacedDigit()
                            Text(plan.period).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? Theme.teal : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var purchaseButton: some View {
        let product = store.product(for: selectedID)
        return VStack(spacing: 8) {
            Button {
                guard let product else { return }
                Task { await buy(product) }
            } label: {
                Group {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(selectedID == EntitlementManager.ProductID.yearly ? "Start 1-week free trial" : "Continue")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 16))
            .controlSize(.large)
            .disabled(product == nil || purchasing)
            .padding(.horizontal)

            if product == nil {
                Text(store.isLoadingProducts ? "Loading prices…" : (store.productLoadError ?? "Store unavailable."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.subheadline.weight(.semibold))
            Text("Free forever: unlimited logging, dashboard, the basic widget and up to 5 activities. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the period. Manage in Settings › Apple ID › Subscriptions.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func buy(_ product: Product) async {
        purchasing = true
        defer { purchasing = false }
        do {
            if try await store.purchase(product) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
