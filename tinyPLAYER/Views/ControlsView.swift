import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var music: MusicService
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(spacing: 10) {
            progressBar
            buttons
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.current.border).frame(height: 3)
                Capsule()
                    .fill(theme.current.accent)
                    .frame(width: geo.size.width * min(max(music.playbackProgress, 0), 1), height: 3)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let progress = min(max(value.location.x / geo.size.width, 0), 1)
                        Task { try? await music.seek(to: progress) }
                    }
            )
        }
        .frame(height: 3)
    }

    private var buttons: some View {
        HStack(spacing: 28) {
            controlButton("backward.fill") { Task { try? await music.skipToPrevious() } }
            controlButton(music.isPlaying ? "pause.fill" : "play.fill", size: theme.fontSize.body + 6) {
                if music.isPlaying { music.pause() }
                else               { Task { try? await music.play() } }
            }
            controlButton("forward.fill")  { Task { try? await music.skipToNext() } }
        }
    }

    private func controlButton(_ icon: String,
                                size: CGFloat? = nil,
                                action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size ?? theme.fontSize.body + 2))
                .foregroundStyle(theme.current.textPrimary)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }
}
