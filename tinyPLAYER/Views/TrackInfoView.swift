import SwiftUI

struct TrackInfoView: View {
    let title:  String
    let artist: String
    let album:  String
    let year:   Int?
    let grade:  GreekGrade?
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: theme.fontSize.title, weight: .semibold))
                    .foregroundStyle(theme.current.textPrimary)
                    .lineLimit(1)

                Text(subtitleText)
                    .font(.system(size: theme.fontSize.label))
                    .foregroundStyle(theme.current.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if let grade {
                Text(grade.symbol)
                    .font(.system(size: theme.fontSize.title, weight: .bold))
                    .foregroundStyle(theme.current.accent)
                    .help("\(grade.displayName) — \(grade.rawValue)/10")
            }
        }
    }

    private var subtitleText: String {
        var parts = [artist, album]
        if let year { parts.append(String(year)) }
        return parts.joined(separator: " · ")
    }
}
