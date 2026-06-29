import MusicKit
import Combine

// MARK: - Errors

enum RadioError: Error {
    case songNotFound
    case noStation
    case emptyQueue
    case unavailableOnMacOS
}

// MARK: - RadioProvider Protocol

/// Abstracts MusicKit calls that require device authorisation so RadioService
/// logic can be tested without a real Apple Music account.
@MainActor
protocol RadioProvider {
    /// Fetches a single Song by catalog ID. Returns `nil` when not found.
    func fetchSong(id: String) async throws -> MusicKit.Song?

    /// Returns a list of songs for a radio station seeded by `song`.
    /// Typically loads up to 25 tracks via `song.with([.station])`.
    func fetchStationTracks(for song: MusicKit.Song) async throws -> [MusicKit.Song]

    /// Creates a new user playlist with the given name.
    /// Note: `MusicLibrary.shared.createPlaylist` is unavailable on macOS.
    func createPlaylist(name: String) async throws -> MusicKit.Playlist

    /// Adds songs to an existing playlist.
    /// Note: `MusicLibrary.shared.add(_:to:)` is unavailable on macOS.
    func addTracks(_ songs: [MusicKit.Song], to playlist: MusicKit.Playlist) async throws

    /// Fetches a single user playlist by ID. Returns `nil` when not found.
    func fetchPlaylist(id: MusicKit.Playlist.ID) async throws -> MusicKit.Playlist?

    /// Returns all playlists in the user's library.
    func userPlaylists() async throws -> MusicItemCollection<MusicKit.Playlist>
}

// MARK: - Live RadioProvider

/// Production implementation backed by real MusicKit / ApplicationMusicPlayer.
@MainActor
final class LiveRadioProvider: RadioProvider {

    func fetchSong(id: String) async throws -> MusicKit.Song? {
        let request = MusicCatalogResourceRequest<MusicKit.Song>(
            matching: \.id, equalTo: MusicItemID(rawValue: id))
        let response = try await request.response()
        return response.items.first
    }

    func fetchStationTracks(for song: MusicKit.Song) async throws -> [MusicKit.Song] {
        // Load the station relationship (`.station` not `.radioStation` on macOS MusicKit)
        let detailed = try await song.with([.station])
        guard let station = detailed.station else {
            throw RadioError.noStation
        }

        // Queue the station and prepare playback so entries are populated
        ApplicationMusicPlayer.shared.queue = ApplicationMusicPlayer.Queue(
            arrayLiteral: station)
        try await ApplicationMusicPlayer.shared.prepareToPlay()

        // Harvest up to 25 songs from the now-loaded queue
        var songs: [MusicKit.Song] = []
        for entry in ApplicationMusicPlayer.shared.queue.entries.prefix(25) {
            if case .song(let s) = entry.item {
                songs.append(s)
            }
        }
        return songs
    }

    func createPlaylist(name: String) async throws -> MusicKit.Playlist {
        // `MusicLibrary.shared.createPlaylist` is @available(macOS, unavailable).
        // Playlist creation on macOS requires AppleScript or the Music app.
        // This is a known macOS MusicKit SDK limitation — deferred for a future task.
        throw RadioError.unavailableOnMacOS
    }

    func addTracks(_ songs: [MusicKit.Song], to playlist: MusicKit.Playlist) async throws {
        // `MusicLibrary.shared.add(_:to:)` is @available(macOS, unavailable).
        // Same SDK limitation as createPlaylist — deferred.
        throw RadioError.unavailableOnMacOS
    }

    func fetchPlaylist(id: MusicKit.Playlist.ID) async throws -> MusicKit.Playlist? {
        var request = MusicLibraryRequest<MusicKit.Playlist>()
        request.filter(matching: \.id, equalTo: id)
        let response = try await request.response()
        return response.items.first
    }

    func userPlaylists() async throws -> MusicItemCollection<MusicKit.Playlist> {
        let request = MusicLibraryRequest<MusicKit.Playlist>()
        return try await request.response().items
    }
}

// MARK: - RadioService

@MainActor
final class RadioService: ObservableObject {

    // MARK: Published state

    @Published var isGenerating: Bool = false
    @Published var stationTracks: [MusicKit.Song] = []

    // MARK: Private

    private let provider: RadioProvider

    // MARK: Init

    /// Designated init for testing — inject a mock provider.
    init(provider: RadioProvider) {
        self.provider = provider
    }

    /// Convenience init for production use — uses the live MusicKit provider.
    convenience init() {
        self.init(provider: LiveRadioProvider())
    }

    // MARK: Public API

    /// Loads a radio station seeded by the given catalog song ID and populates
    /// `stationTracks` with up to 25 tracks. Sets `isGenerating` while loading.
    func createStation(seedSongID: String) async throws {
        isGenerating = true
        defer { isGenerating = false }

        guard let song = try await provider.fetchSong(id: seedSongID) else {
            throw RadioError.songNotFound
        }

        stationTracks = try await provider.fetchStationTracks(for: song)
    }

    /// Creates a new user playlist from the current `stationTracks`.
    /// Throws `RadioError.emptyQueue` when `stationTracks` is empty.
    /// Note: Playlist write APIs are unavailable on macOS; throws
    /// `RadioError.unavailableOnMacOS` when provider raises that error.
    func saveAsPlaylist(name: String) async throws {
        guard !stationTracks.isEmpty else { throw RadioError.emptyQueue }
        let playlist = try await provider.createPlaylist(name: name)
        try await provider.addTracks(stationTracks, to: playlist)
    }

    /// Adds a single song to an existing playlist.
    /// Note: Playlist write APIs are unavailable on macOS via MusicKit.
    func addTrackToPlaylist(_ track: MusicKit.Song,
                            playlistID: MusicKit.Playlist.ID) async throws {
        guard let playlist = try await provider.fetchPlaylist(id: playlistID) else { return }
        try await provider.addTracks([track], to: playlist)
    }

    /// Returns all playlists in the user's library.
    func userPlaylists() async throws -> MusicItemCollection<MusicKit.Playlist> {
        return try await provider.userPlaylists()
    }
}
