import SwiftUI
import AppKit

struct ActionBarView: View {
    @EnvironmentObject var music:  MusicService
    @EnvironmentObject var scores: ScoreStore
    @EnvironmentObject var radio:  RadioService
    @EnvironmentObject var theme:  ThemeManager

    @State private var showScorePicker    = false
    @State private var showRadioSheet     = false
    @State private var showPlaylistNaming = false
    @State private var playlistName       = ""
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 18) {
            // Library toggle
            actionButton(icon: music.inLibrary ? "heart.fill" : "heart",
                         tint: music.inLibrary ? theme.current.accent : theme.current.textMuted) {
                Task {
                    if music.inLibrary { try? await music.removeFromLibrary() }
                    else               { try? await music.addToLibrary() }
                }
            }

            // Score
            actionButton(icon: "star", tint: theme.current.textMuted) {
                showScorePicker.toggle()
            }
            .popover(isPresented: $showScorePicker) { scorePicker }

            // Radio station
            actionButton(icon: "antenna.radiowaves.left.and.right",
                         tint: theme.current.textMuted) {
                showRadioSheet = true
            }
            .confirmationDialog("Create Station", isPresented: $showRadioSheet) {
                Button("Play Station Now") {
                    Task { try? await radio.createStation(seedSongID: music.currentSongID ?? "") }
                }
                Button("Play & Save as Playlist…") {
                    showPlaylistNaming = true
                    Task { try? await radio.createStation(seedSongID: music.currentSongID ?? "") }
                }
            }
            .alert("Name Playlist", isPresented: $showPlaylistNaming) {
                TextField("Playlist name", text: $playlistName)
                Button("Save") {
                    let name = playlistName
                    playlistName = ""
                    Task { try? await radio.saveAsPlaylist(name: name) }
                }
                Button("Cancel", role: .cancel) { playlistName = "" }
            }

            // Share — uses NSView bridge for NSSharingServicePicker
            ShareButtonView(title: music.currentTitle,
                            artist: music.currentArtist,
                            url: music.artworkURL)

            Spacer()

            // Settings gear
            actionButton(icon: "gearshape", tint: theme.current.textMuted) {
                showSettings.toggle()
            }
        }
    }

    private var scorePicker: some View {
        VStack(spacing: 4) {
            Text("Score this song")
                .font(.system(size: theme.fontSize.label))
                .foregroundStyle(theme.current.textMuted)
                .padding(.top, 8)

            let currentScore = music.currentSongID
                .flatMap { scores.score(for: $0) }
                .map    { Int($0.scoreValue) }

            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 6) {
                ForEach(GreekGrade.allCases.reversed(), id: \.rawValue) { grade in
                    Button {
                        guard let id = music.currentSongID else { return }
                        let identity = SongIdentity(id: id,
                                                    title: music.currentTitle,
                                                    artist: music.currentArtist,
                                                    album: music.currentAlbum)
                        if currentScore == grade.rawValue {
                            try? scores.clearScore(for: id)
                        } else {
                            try? scores.setScore(grade.rawValue, for: identity)
                        }
                        showScorePicker = false
                    } label: {
                        VStack(spacing: 2) {
                            Text(grade.symbol)
                                .font(.system(size: 18, weight: .bold))
                            Text(String(grade.rawValue))
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(currentScore == grade.rawValue
                            ? theme.current.accent : theme.current.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(currentScore == grade.rawValue
                            ? theme.current.accentSoft.opacity(0.3) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 240)
        .background(theme.current.bgPanel)
    }

    private func actionButton(icon: String, tint: Color,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: theme.fontSize.body + 1))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

// NSViewRepresentable bridge so NSSharingServicePicker has a real NSView anchor
struct ShareButtonView: NSViewRepresentable {
    let title: String
    let artist: String
    let url: URL?
    @EnvironmentObject var theme: ThemeManager

    func makeNSView(context: Context) -> NSButton {
        let btn = NSButton()
        btn.bezelStyle = .regularSquare
        btn.isBordered = false
        btn.image = NSImage(systemSymbolName: "square.and.arrow.up",
                            accessibilityDescription: nil)
        btn.target = context.coordinator
        btn.action = #selector(Coordinator.share(_:))
        return btn
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: ShareButtonView
        init(_ parent: ShareButtonView) { self.parent = parent }

        @objc func share(_ sender: NSButton) {
            SharingService.share(title: parent.title,
                                 artist: parent.artist,
                                 url: parent.url,
                                 relativeTo: sender.bounds,
                                 in: sender)
        }
    }
}
