import Foundation
@testable import tinyPLAYER

@MainActor
final class MockMusicService: MusicServiceProtocol, ObservableObject {
    @Published var currentTitle:     String  = "Mock Song"
    @Published var currentArtist:    String  = "Mock Artist"
    @Published var currentAlbum:     String  = "Mock Album"
    @Published var currentYear:      Int?    = 2024
    @Published var artworkURL:       URL?    = nil
    @Published var isPlaying:        Bool    = false
    @Published var playbackProgress: Double  = 0.0
    @Published var inLibrary:        Bool    = true
    @Published var currentSongID:    String? = "mock-id-001"
    @Published var currentSongURL:   URL?    = nil

    var playCalled              = false
    var pauseCalled             = false
    var skipNextCalled          = false
    var skipPrevCalled          = false
    var addToLibraryCalled      = false
    var removeFromLibraryCalled = false
    var seekCalled              = false
    var lastSeekProgress: Double = 0

    func play()              async throws { playCalled = true;  isPlaying = true  }
    func pause()                         { pauseCalled = true; isPlaying = false }
    func skipToNext()        async throws { skipNextCalled = true }
    func skipToPrevious()    async throws { skipPrevCalled = true }
    func addToLibrary()      async throws { addToLibraryCalled = true;     inLibrary = true  }
    func removeFromLibrary() async throws { removeFromLibraryCalled = true; inLibrary = false }
    func requestAuthorization() async {}
    func seek(to progress: Double) async throws {
        seekCalled = true
        lastSeekProgress = progress
        playbackProgress = progress
    }
}
