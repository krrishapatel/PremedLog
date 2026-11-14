import SwiftUI
import UIKit

enum Theme {
    static let teal = Color(red: 0.05, green: 0.62, blue: 0.60)
    static let indigo = Color(red: 0.30, green: 0.28, blue: 0.78)
    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.04, green: 0.60, blue: 0.58), Color(red: 0.28, green: 0.27, blue: 0.76)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let background = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View { modifier(CardModifier(padding: padding)) }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.semibold))
            Spacer()
            if let trailing {
                Text(trailing).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct ProgressRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.spring(duration: 0.6), value: progress)
    }
}

struct ProgressBar: View {
    var progress: Double
    var color: Color
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.18))
                Capsule().fill(color)
                    .frame(width: max(height, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
        .animation(.spring(duration: 0.6), value: progress)
    }
}

/// Rounded icon tile used for activities.
struct ActivityIcon: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}

struct CopyButton: View {
    let text: String
    var compact = false
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { copied = true }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation { copied = false }
            }
        } label: {
            Group {
                if compact {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                } else {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
            }
            .font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .tint(copied ? .green : .accentColor)
        .disabled(text.isEmpty)
        .accessibilityLabel(copied ? "Copied" : "Copy")
    }
}

struct CharacterCounter: View {
    let count: Int
    let limit: Int

    var body: some View {
        let over = count > limit
        HStack(spacing: 4) {
            if over { Image(systemName: "exclamationmark.triangle.fill") }
            Text(over ? "\(count)/\(limit) · \(count - limit) over" : "\(count)/\(limit)")
                .monospacedDigit()
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(over ? Color.red : (count > Int(Double(limit) * 0.9) ? Color.orange : Color.secondary))
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.heavy))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.heroGradient, in: Capsule())
            .foregroundStyle(.white)
    }
}

struct EntryRow: View {
    let entry: LogEntry
    var showActivity = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if showActivity, let activity = entry.activity {
                ActivityIcon(symbol: activity.type.symbol, color: activity.color, size: 34)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(showActivity ? (entry.activity?.title ?? "Activity") : entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if entry.isMemorable {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                    }
                    Spacer()
                    Text("\(entry.hours.hoursText) h")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                if showActivity {
                    Text(entry.date.formatted(.relative(presentation: .named)).capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if entry.hasNote {
                    Text(entry.note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(showActivity ? 2 : nil)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 44))
                .foregroundStyle(Theme.heroGradient)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
