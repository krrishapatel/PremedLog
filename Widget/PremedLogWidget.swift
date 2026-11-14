import WidgetKit
import SwiftUI

// MARK: - Timeline

struct HoursEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct HoursProvider: TimelineProvider {
    func placeholder(in context: Context) -> HoursEntry {
        HoursEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (HoursEntry) -> Void) {
        let snapshot = context.isPreview ? .placeholder : (SharedStore.read() ?? .placeholder)
        completion(HoursEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HoursEntry>) -> Void) {
        // The app calls WidgetCenter.reloadAllTimelines() whenever data changes;
        // the hourly refresh is just a safety net.
        let entry = HoursEntry(date: .now, snapshot: SharedStore.read() ?? .empty)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

private let tealColor = Color(red: 0.05, green: 0.62, blue: 0.60)
private let indigoColor = Color(red: 0.30, green: 0.28, blue: 0.78)

// MARK: - Home screen widget (small is free, medium is Pro)

struct HoursWidget: Widget {
    let kind = "PremedLogHoursWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HoursProvider()) { entry in
            HoursWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color("WidgetBackground") }
                .widgetURL(URL(string: "premedlog://log"))
        }
        .configurationDisplayName("Hours")
        .description("Your total hours and progress toward your goals.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HoursWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HoursEntry

    var body: some View {
        switch family {
        case .systemMedium:
            if entry.snapshot.isPro { MediumView(snapshot: entry.snapshot) } else { ProLockedView(compact: false) }
        default:
            SmallView(snapshot: entry.snapshot)
        }
    }
}

struct SmallView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "cross.case.fill")
                Text("PremedLog")
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(tealColor)

            Spacer(minLength: 0)

            Text(snapshot.totalHours.hoursText)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text("total hours")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            if snapshot.weekStreak > 0 {
                Label("\(snapshot.weekStreak)-week streak", systemImage: "flame.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            } else {
                Label("Tap to log", systemImage: "plus.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(indigoColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct MediumView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 16) {
            SmallView(snapshot: snapshot)
                .frame(maxWidth: 120)
            VStack(alignment: .leading, spacing: 7) {
                ForEach(snapshot.categories) { category in
                    let group = category.categoryGroup
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: group.symbol).font(.caption2).foregroundStyle(group.color)
                            Text(group.title).font(.caption2.weight(.semibold))
                            Spacer()
                            Text(category.goal > 0
                                 ? "\(category.hours.hoursText)/\(category.goal.hoursText)"
                                 : category.hours.hoursText)
                                .font(.caption2.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(group.color.opacity(0.18))
                                Capsule().fill(group.color)
                                    .frame(width: max(4, geo.size.width * (category.goal > 0 ? category.progress : (category.hours > 0 ? 1 : 0))))
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
        }
    }
}

struct ProLockedView: View {
    let compact: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(compact ? .caption : .title2)
                .foregroundStyle(indigoColor)
            Text(compact ? "Pro" : "Unlock all widgets with PremedLog Pro")
                .font(compact ? .caption2 : .subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Lock screen accessories (Pro)

struct LockScreenWidget: Widget {
    let kind = "PremedLogLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HoursProvider()) { entry in
            LockScreenView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
                .widgetURL(URL(string: "premedlog://log"))
        }
        .configurationDisplayName("Hours (Lock Screen)")
        .description("Total hours on your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HoursEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }

    private var clinical: WidgetSnapshot.Category? {
        snapshot.categories.first { $0.group == CategoryGroup.clinical.rawValue }
    }

    var body: some View {
        if !snapshot.isPro {
            switch family {
            case .accessoryInline: Label("PremedLog Pro", systemImage: "lock.fill")
            default: ProLockedView(compact: true)
            }
        } else {
            switch family {
            case .accessoryCircular:
                let goalTotal = snapshot.categories.reduce(0) { $0 + $1.goal }
                Gauge(value: min(snapshot.totalHours, max(goalTotal, 1)), in: 0...max(goalTotal, 1)) {
                    Image(systemName: "cross.case.fill")
                } currentValueLabel: {
                    Text(snapshot.totalHours.hoursText).minimumScaleFactor(0.5)
                }
                .gaugeStyle(.accessoryCircularCapacity)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Label("PremedLog", systemImage: "cross.case.fill")
                        .font(.caption2.weight(.bold))
                    Text("\(snapshot.totalHours.hoursText) hours")
                        .font(.headline)
                        .minimumScaleFactor(0.7)
                    if let clinical, clinical.goal > 0 {
                        Gauge(value: clinical.progress) {
                            Text("Clinical")
                        }
                        .gaugeStyle(.accessoryLinearCapacity)
                    } else {
                        Text("\(snapshot.weekStreak)-week streak").font(.caption2)
                    }
                }
            default:
                Label("\(snapshot.totalHours.hoursText) hours logged", systemImage: "cross.case.fill")
            }
        }
    }
}

// MARK: - Bundle

@main
struct PremedLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        HoursWidget()
        LockScreenWidget()
    }
}

#Preview(as: .systemMedium) {
    HoursWidget()
} timeline: {
    HoursEntry(date: .now, snapshot: .placeholder)
}
