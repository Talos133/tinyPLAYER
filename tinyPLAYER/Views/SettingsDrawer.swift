import SwiftUI

struct SettingsDrawer: View {
    @EnvironmentObject var theme: ThemeManager

    @AppStorage("tinyplayer_quit_music_on_exit") private var quitMusicOnExit = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Palette")
                .font(.system(size: theme.fontSize.label, weight: .medium))
                .foregroundStyle(theme.current.textMuted)

            paletteGrid

            Divider().overlay(theme.current.border)

            Text("Text Size")
                .font(.system(size: theme.fontSize.label, weight: .medium))
                .foregroundStyle(theme.current.textMuted)

            fontSizePicker

            Divider().overlay(theme.current.border)

            Toggle(isOn: $quitMusicOnExit) {
                Text("Quit Music.app on exit")
                    .font(.system(size: theme.fontSize.label))
                    .foregroundStyle(theme.current.textPrimary)
            }
            .toggleStyle(.switch)

            HStack {
                Spacer()
                Text("v\(appVersion)")
                    .font(.system(size: theme.fontSize.label - 1))
                    .foregroundStyle(theme.current.textMuted)
            }
        }
        .padding(16)
        .background(theme.current.bgPanel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var paletteGrid: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
            ForEach(Palettes.all, id: \.name) { palette in
                Button { theme.apply(palette: palette) } label: {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(palette.accent)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(
                                    theme.current.name == palette.name
                                        ? theme.current.textPrimary : Color.clear,
                                    lineWidth: 2)
                            )
                        Text(palette.name.components(separatedBy: " ").first ?? palette.name)
                            .font(.system(size: 9))
                            .foregroundStyle(theme.current.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var fontSizePicker: some View {
        HStack(spacing: 0) {
            ForEach(AppFontSize.allCases, id: \.self) { size in
                Button { theme.apply(fontSize: size) } label: {
                    Text(size.rawValue.capitalized)
                        .font(.system(size: theme.fontSize.label))
                        .foregroundStyle(theme.fontSize == size
                            ? theme.current.bgApp : theme.current.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(theme.fontSize == size
                            ? theme.current.accent : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.current.border))
    }
}
