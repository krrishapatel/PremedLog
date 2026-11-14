import Foundation
import UIKit

/// Builds a PDF laid out like the AMCAS Work & Activities section, plus CSV files.
enum ExportService {
    struct Output {
        let pdf: URL
        let activitiesCSV: URL
        let logCSV: URL
    }

    static func export(activities: [Activity]) throws -> Output {
        let ordered = activities.sorted {
            if $0.isMostMeaningful != $1.isMostMeaningful { return $0.isMostMeaningful }
            return $0.totalHours > $1.totalHours
        }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("Export", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let pdfURL = dir.appendingPathComponent("PremedLog AMCAS Activities.pdf")
        try makePDF(activities: ordered, to: pdfURL)

        let activitiesURL = dir.appendingPathComponent("PremedLog Activities.csv")
        try activitiesCSV(ordered).write(to: activitiesURL, atomically: true, encoding: .utf8)

        let logURL = dir.appendingPathComponent("PremedLog Hours Log.csv")
        try logCSV(ordered).write(to: logURL, atomically: true, encoding: .utf8)

        return Output(pdf: pdfURL, activitiesCSV: activitiesURL, logCSV: logURL)
    }

    // MARK: CSV

    static func activitiesCSV(_ activities: [Activity]) -> String {
        let header = ["Experience Type", "Experience Name", "Organization", "City", "State/Province",
                      "Start (MM/YYYY)", "End (MM/YYYY)", "Total Hours", "Contact Name", "Contact Title",
                      "Contact Email", "Contact Phone", "Most Meaningful", "Experience Description",
                      "Most Meaningful Remarks"]
        let f = DateFormatter()
        f.dateFormat = "MM/yyyy"
        var rows = [header.map(escape).joined(separator: ",")]
        for a in activities {
            let fields = [
                a.type.amcasName, a.title, a.organization, a.city, a.state,
                f.string(from: a.startDate), a.endDate.map { f.string(from: $0) } ?? "Present",
                String(Int(a.totalHours.rounded())), a.contactName, a.contactTitle,
                a.contactEmail, a.contactPhone, a.isMostMeaningful ? "Yes" : "No",
                a.amcasDescription, a.isMostMeaningful ? a.meaningfulEssay : ""
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func logCSV(_ activities: [Activity]) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        var rows = ["Date,Activity,Experience Type,Hours,Memorable,Reflection"]
        let entries = activities.flatMap { a in a.entries.map { (a, $0) } }.sorted { $0.1.date < $1.1.date }
        for (a, e) in entries {
            rows.append([f.string(from: e.date), a.title, a.type.amcasName, e.hours.hoursText,
                         e.isMemorable ? "Yes" : "No", e.note].map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: PDF

    static func makePDF(activities: [Activity], to url: URL) throws {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let margin: CGFloat = 50
        let width = page.width - margin * 2
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "AMCAS Work & Activities",
            kCGPDFContextCreator as String: "PremedLog"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: page, format: format)

        let teal = UIColor(red: 0.05, green: 0.62, blue: 0.60, alpha: 1)
        let gray = UIColor(white: 0.4, alpha: 1)

        func attr(_ s: String, _ font: UIFont, _ color: UIColor = .black) -> NSAttributedString {
            let p = NSMutableParagraphStyle()
            p.lineSpacing = 2
            return NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: p])
        }

        try renderer.writePDF(to: url) { ctx in
            var y: CGFloat = margin

            func height(of s: NSAttributedString) -> CGFloat {
                ceil(s.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                    options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
            }
            func newPage() {
                ctx.beginPage()
                y = margin
            }
            func draw(_ s: NSAttributedString, after spacing: CGFloat = 4) {
                let h = height(of: s)
                if y + h > page.height - margin { newPage() }
                s.draw(with: CGRect(x: margin, y: y, width: width, height: h),
                       options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                y += h + spacing
            }
            func rule(color: UIColor = UIColor(white: 0.85, alpha: 1)) {
                color.setFill()
                UIRectFill(CGRect(x: margin, y: y, width: width, height: 1))
                y += 10
            }

            newPage()
            draw(attr("Work & Activities", .systemFont(ofSize: 24, weight: .bold)), after: 2)
            let total = activities.reduce(0) { $0 + $1.totalHours }
            draw(attr("\(activities.count) experiences · \(total.hoursText) total hours · Exported \(Date.now.formatted(date: .abbreviated, time: .omitted)) from PremedLog",
                      .systemFont(ofSize: 10), gray), after: 14)
            rule(color: teal)

            for (index, a) in activities.enumerated() {
                // Keep each header block together.
                if y + 140 > page.height - margin { newPage() }
                let mm = a.isMostMeaningful ? "  ★ MOST MEANINGFUL" : ""
                draw(attr("EXPERIENCE \(index + 1) · \(a.type.amcasName.uppercased())\(mm)",
                          .systemFont(ofSize: 9, weight: .semibold), teal), after: 2)
                draw(attr(a.title, .systemFont(ofSize: 15, weight: .semibold)), after: 6)

                let lines: [(String, String)] = [
                    ("Organization", a.organization),
                    ("Location", a.locationText),
                    ("Dates", a.amcasDateRangeText),
                    ("Total hours", String(Int(a.totalHours.rounded()))),
                    ("Contact", [a.contactName, a.contactTitle].filter { !$0.isEmpty }.joined(separator: ", ")),
                    ("Contact email / phone", [a.contactEmail, a.contactPhone].filter { !$0.isEmpty }.joined(separator: " · "))
                ].filter { !$0.1.isEmpty }

                for (label, value) in lines {
                    let s = NSMutableAttributedString(attributedString: attr("\(label): ", .systemFont(ofSize: 10, weight: .medium), gray))
                    s.append(attr(value, .systemFont(ofSize: 10)))
                    draw(s, after: 2)
                }
                y += 6

                draw(attr("Experience Description (\(a.amcasDescription.count)/\(Limits.descriptionLimit))",
                          .systemFont(ofSize: 9, weight: .semibold), gray), after: 2)
                draw(attr(a.amcasDescription.isEmpty ? "—" : a.amcasDescription, .systemFont(ofSize: 10.5)), after: 8)

                if a.isMostMeaningful {
                    draw(attr("Most Meaningful Experience (\(a.meaningfulEssay.count)/\(Limits.meaningfulLimit))",
                              .systemFont(ofSize: 9, weight: .semibold), gray), after: 2)
                    draw(attr(a.meaningfulEssay.isEmpty ? "—" : a.meaningfulEssay, .systemFont(ofSize: 10.5)), after: 8)
                }
                y += 4
                rule()
            }
        }
    }
}
