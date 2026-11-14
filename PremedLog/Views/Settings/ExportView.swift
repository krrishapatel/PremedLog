import SwiftUI
import SwiftData

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Activity.createdAt) private var activities: [Activity]

    @State private var output: ExportService.Output?
    @State private var errorMessage: String?
    @State private var includeArchived = false

    private var selected: [Activity] { activities.filter { includeArchived || !$0.isArchived } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Include archived activities", isOn: $includeArchived)
                } footer: {
                    Text("\(selected.count) activities · \(Stats.totalHours(selected).hoursText) hours")
                }

                if let output {
                    Section("Ready to share") {
                        ShareLink(item: output.pdf) {
                            exportRow(symbol: "doc.richtext.fill", color: .red, title: "AMCAS-style PDF",
                                      subtitle: "Every activity laid out like the application")
                        }
                        ShareLink(item: output.activitiesCSV) {
                            exportRow(symbol: "tablecells.fill", color: .green, title: "Activities CSV",
                                      subtitle: "One row per activity, all AMCAS fields")
                        }
                        ShareLink(item: output.logCSV) {
                            exportRow(symbol: "list.bullet.clipboard.fill", color: .blue, title: "Hours log CSV",
                                      subtitle: "Every entry with date, hours and reflection")
                        }
                    }
                } else if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                } else {
                    Section { HStack { ProgressView(); Text("Preparing files…").foregroundStyle(.secondary) } }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .task(id: includeArchived) { generate() }
        }
    }

    private func exportRow(symbol: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ActivityIcon(symbol: symbol, color: color, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "square.and.arrow.up").foregroundStyle(Color.accentColor)
        }
    }

    private func generate() {
        output = nil
        do {
            output = try ExportService.export(activities: selected)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
