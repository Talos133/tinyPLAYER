import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var music:   MusicService
    @EnvironmentObject var scores:  ScoreStore
    @EnvironmentObject var theme:   ThemeManager
    @EnvironmentObject var windows: WindowManager

    private var currentGrade: GreekGrade? {
        music.currentSongID
            .flatMap { scores.score(for: $0) }
            .flatMap { GreekGrade(score: Int($0.scoreValue)) }
    }

    var body: some View {
        HStack(spacing: 8) {
            ArtworkView(url: music.artworkURL, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(music.currentTitle)
                    .font(.system(size: theme.fontSize.body, weight: .semibold))
                    .foregroundStyle(theme.current.textPrimary)
                    .lineLimit(1)
                Text(music.currentArtist)
                    .font(.system(size: theme.fontSize.label))
                    .foregroundStyle(theme.current.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                miniButton("backward.fill") { Task { try? await music.skipToPrevious() } }
                miniButton(music.isPlaying ? "pause.fill" : "play.fill") {
                    if music.isPlaying { music.pause() }
                    else { Task { try? await music.play() } }
                }
                miniButton("forward.fill") { Task { try? await music.skipToNext() } }
            }

            if let grade = currentGrade {
                Text(grade.symbol)
                    .font(.system(size: theme.fontSize.body, weight: .bold))
                    .foregroundStyle(theme.current.accent)
            }
        }
        .padding(.horizontal, 10)
        .frame(width: 145, height: 72)
        .background(theme.current.bgApp)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(count: 2) { windows.toggleMiniNormal() }
    }

    private func miniButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: theme.fontSize.label))
                .foregroundStyle(theme.current.textPrimary)
        }
        .buttonStyle(.plain)
    }
}
