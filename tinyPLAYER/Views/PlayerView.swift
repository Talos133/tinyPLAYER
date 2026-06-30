import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var music:   MusicService
    @EnvironmentObject var scores:  ScoreStore
    @EnvironmentObject var radio:   RadioService
    @EnvironmentObject var theme:   ThemeManager
    @EnvironmentObject var windows: WindowManager

    @State private var showSettings     = false
    @State private var showScoreBrowser = false

    private var currentGrade: GreekGrade? {
        music.currentSongID
            .flatMap { scores.score(for: $0) }
            .flatMap { GreekGrade(score: Int($0.scoreValue)) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Album art
            ArtworkView(url: music.artworkURL, size: 180)
                .padding(.top, 16)

            // Track info
            TrackInfoView(title:  music.currentTitle,
                          artist: music.currentArtist,
                          album:  music.currentAlbum,
                          year:   music.currentYear,
                          grade:  currentGrade)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Controls
            ControlsView()
                .padding(.horizontal, 20)
                .padding(.top, 10)

            // Action bar
            ActionBarView(showSettings: $showSettings)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Settings drawer (slides in from bottom)
            if showSettings {
                SettingsDrawer()
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: 12)
        }
        .frame(width: 360, height: 360)
        .background(theme.current.bgApp)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .onTapGesture(count: 2) { windows.toggleMiniNormal() }
        .contextMenu {
            Button("Score Browser") { showScoreBrowser = true }
            Button("Mini Player")   { windows.toggleMiniNormal() }
        }
        .sheet(isPresented: $showScoreBrowser) {
            ScoreBrowserView()
                .environmentObject(scores)
                .environmentObject(music)
                .environmentObject(theme)
        }
    }
}
