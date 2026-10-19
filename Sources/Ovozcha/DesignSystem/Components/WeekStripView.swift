import SwiftUI

/// Oxirgi 7 kunlik faollik chizig'i: har kun uchun bitta doira.
/// To'ldirilgan — shu kuni kamida bitta mashq bajarilgan.
/// Bugungi kun qo'shimcha halqa bilan ajratiladi.
///
/// IOS va Android (Skip) uchun umumiy.
struct WeekStripView: View {
    let days: [ActivityStore.DayMark]

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(days) { day in
                dayColumn(day)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func dayColumn(_ day: ActivityStore.DayMark) -> some View {
        return VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(day.isActive ? Color.ovGreenStrong : Color.ovBorder)
                    .frame(width: 28, height: 28)
                if day.isToday {
                    Circle()
                        .strokeBorder(Color.ovPurpleStrong, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }
            }
            .frame(width: 36, height: 36)

            Text(day.label)
                .ovStyle(.caption, color: day.isToday ? .ovPurpleStrong : .ovTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        #if !SKIP
        .accessibilityElement(children: .ignore)
        #endif
        .accessibilityLabel(Strings.Home.dayLabel(day.label, active: day.isActive))
    }
}
