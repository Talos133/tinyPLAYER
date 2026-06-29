import MusicKit
import Combine
import AppKit

@MainActor
final class MusicService: MusicServiceProtocol, ObservableObject {

    // MARK: - Published state

    @Published var currentTitle:     String  = "—"
    @Published var currentArtist:    String  = "—"
    @Published var currentAlbum:     String  = "—"
    @Published var currentYear:      Int?    = nil
    @Published var artworkURL:       URL?    = nil
    @Published var isPlaying:        Bool    = false
    @Published var playbackProgress: Double  = 0.0
    @Published var inLibrary:        Bool    = false
    @Published var currentSongID:    String? = nil

    // MARK: - Private

    private let player = ApplicationMusicPlayer.shared
    private var stateObserver:   AnyCancellable?
    private var currentSong:     Song?

    // MARK: - Init

    init() {
        observeState()
    }

    // MARK: - MusicServiceProtocol

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        if status == .authorized {
            AppleScriptBridge.launchAndHide()
        }
    }

    func play()           async throws { try await player.play() }
    func pause()                       { player.pause() }
    func skipToNext()     async throws { try await player.skipToNextEntry() }
    func skipToPrevious() async throws { try await player.skipToPreviousEntry() }

    func seek(to progress: Double) async throws {
        let player = ApplicationMusicPlayer.shared
        // Get duration from current queue entry
        guard let entry = player.queue.currentEntry,
              let endTime = entry.endTime,
              endTime > 0 else { return }
        player.playbackTime = progress * endTime
    }

    func addToLibrary() async throws {
        // MusicLibrary.shared.add(_:) is unavailable on macOS.
        // Adding to library on macOS requires using the Music.app AppleScript API
        // or a deep link — deferred to a future implementation.
        // For now, mark inLibrary optimistically so the UI reflects user intent.
        inLibrary = true
    }

    func removeFromLibrary() async throws {
        guard let id = currentSongID else { return }
        AppleScriptBridge.removeFromLibrary(songID: id)
        inLibrary = false
    }

    // MARK: - State observation

    private func observeState() {
        stateObserver = player.state.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateNowPlaying() }
    }

    private func updateNowPlaying() {
        isPlaying = player.state.playbackStatus == .playing

        guard let entry = player.queue.currentEntry,
              case .song(let song) = entry.item else {
            clearNowPlaying()
            return
        }

        currentSong   = song
        currentSongID = song.id.rawValue
        currentTitle  = song.title
        currentArtist = song.artistName
        currentAlbum  = song.albumTitle ?? "—"
        artworkURL    = song.artwork?.url(width: 400, height: 400)

        if let date = song.releaseDate {
            currentYear = Calendar.current.component(.year, from: date)
        }

        updatePlaybackProgress()
    }

    private func updatePlaybackProgress() {
        let duration = player.queue.currentEntry?.endTime ?? 1
        playbackProgress = duration > 0 ? player.playbackTime / duration : 0
    }

    private func clearNowPlaying() {
        currentSong       = nil
        currentSongID     = nil
        currentTitle      = "—"
        currentArtist     = "—"
        currentAlbum      = "—"
        currentYear       = nil
        artworkURL        = nil
        playbackProgress  = 0
    }
}
