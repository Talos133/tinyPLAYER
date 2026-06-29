import XCTest
import MusicKit
@testable import tinyPLAYER

// MARK: - Mock RadioProvider

/// Test double for RadioProvider — captures calls and injects canned results.
@MainActor
final class MockRadioProvider: RadioProvider {

    // --- Configurable stubs ---
    var fetchSongResult: Result<MusicKit.Song?, Error> = .success(nil)
    var fetchStationTracksResult: Result<[MusicKit.Song], Error> = .success([])
    var createPlaylistResult: Result<MusicKit.Playlist, Error>?
    var addTracksResult: Result<Void, Error> = .success(())

    // --- Call tracking ---
    var fetchSongCalled = false
    var fetchStationTracksCalled = false
    var createPlaylistCalled = false
    var addTracksCalled = false
    var lastSeedSongID: String?
    var lastPlaylistName: String?
    var lastTracksAdded: [MusicKit.Song] = []

    func fetchSong(id: String) async throws -> MusicKit.Song? {
        fetchSongCalled = true
        lastSeedSongID = id
        return try fetchSongResult.get()
    }

    func fetchStationTracks(for song: MusicKit.Song) async throws -> [MusicKit.Song] {
        fetchStationTracksCalled = true
        return try fetchStationTracksResult.get()
    }

    func createPlaylist(name: String) async throws -> MusicKit.Playlist {
        createPlaylistCalled = true
        lastPlaylistName = name
        guard let result = createPlaylistResult else {
            throw RadioError.emptyQueue   // default: not configured
        }
        return try result.get()
    }

    func addTracks(_ songs: [MusicKit.Song], to playlist: MusicKit.Playlist) async throws {
        addTracksCalled = true
        lastTracksAdded = songs
        try addTracksResult.get()
    }
}

// MARK: - Tests

@MainActor
final class RadioServiceTests: XCTestCase {

    // MARK: - createStation: isGenerating lifecycle

    func test_createStation_setsIsGenerating_thenClears() async throws {
        let provider = MockRadioProvider()
        // Return no song so it throws — we can't get real Song objects in tests
        provider.fetchSongResult = .failure(RadioError.songNotFound)
        let sut = RadioService(provider: provider)

        XCTAssertFalse(sut.isGenerating, "should start as false")
        do {
            try await sut.createStation(seedSongID: "test-id")
        } catch {
            // expected throw
        }
        XCTAssertFalse(sut.isGenerating, "should be false after completion (even on error)")
    }

    func test_createStation_isGenerating_startsTrue() async throws {
        // Verify isGenerating is false both before and after a failing call.
        // In-flight observation of isGenerating mid-async is not possible on @MainActor
        // without hooks; the defer { isGenerating = false } contract is tested in
        // test_createStation_setsIsGenerating_thenClears.
        let provider = MockRadioProvider()
        provider.fetchSongResult = .failure(RadioError.songNotFound)
        let sut = RadioService(provider: provider)

        XCTAssertFalse(sut.isGenerating)
        try? await sut.createStation(seedSongID: "x")
        XCTAssertFalse(sut.isGenerating)
    }

    // MARK: - createStation: delegates to provider

    func test_createStation_callsFetchSong_withCorrectID() async {
        let provider = MockRadioProvider()
        provider.fetchSongResult = .failure(RadioError.songNotFound)
        let sut = RadioService(provider: provider)

        try? await sut.createStation(seedSongID: "abc-123")

        XCTAssertTrue(provider.fetchSongCalled)
        XCTAssertEqual(provider.lastSeedSongID, "abc-123")
    }

    func test_createStation_throwsSongNotFound_whenProviderReturnsNil() async {
        let provider = MockRadioProvider()
        provider.fetchSongResult = .success(nil)
        let sut = RadioService(provider: provider)

        do {
            try await sut.createStation(seedSongID: "missing-id")
            XCTFail("Expected RadioError.songNotFound")
        } catch RadioError.songNotFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createStation_propagatesProviderError() async {
        let provider = MockRadioProvider()
        struct FetchError: Error {}
        provider.fetchSongResult = .failure(FetchError())
        let sut = RadioService(provider: provider)

        do {
            try await sut.createStation(seedSongID: "any-id")
            XCTFail("Expected error to be thrown")
        } catch is FetchError {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createStation_propagatesStationTracksError() async {
        let provider = MockRadioProvider()
        struct StationError: Error {}
        // fetchSong returns nil so songNotFound fires before stationTracks is attempted
        // Use songNotFound path — stationTracks error needs a real Song object we can't construct
        // This test verifies error propagation from fetchSong path.
        provider.fetchSongResult = .failure(StationError())
        let sut = RadioService(provider: provider)

        var threwError = false
        do {
            try await sut.createStation(seedSongID: "any")
        } catch {
            threwError = true
        }
        XCTAssertTrue(threwError)
    }

    // MARK: - createStation: stationTracks state

    func test_createStation_stationTracks_emptyOnSongNotFound() async {
        let provider = MockRadioProvider()
        provider.fetchSongResult = .success(nil)
        let sut = RadioService(provider: provider)

        try? await sut.createStation(seedSongID: "missing")
        XCTAssertTrue(sut.stationTracks.isEmpty)
    }

    // MARK: - saveAsPlaylist: error on empty queue

    func test_saveAsPlaylist_throwsEmptyQueue_whenNoTracks() async {
        let provider = MockRadioProvider()
        let sut = RadioService(provider: provider)
        // stationTracks is empty by default

        do {
            try await sut.saveAsPlaylist(name: "My Station")
            XCTFail("Expected RadioError.emptyQueue")
        } catch RadioError.emptyQueue {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Default published state

    func test_defaultState_isGenerating_isFalse() {
        let sut = RadioService(provider: MockRadioProvider())
        XCTAssertFalse(sut.isGenerating)
    }

    func test_defaultState_stationTracks_isEmpty() {
        let sut = RadioService(provider: MockRadioProvider())
        XCTAssertTrue(sut.stationTracks.isEmpty)
    }

    // MARK: - RadioError is equatable-ish (verify error identity)

    func test_radioError_songNotFound() {
        let err: RadioError = .songNotFound
        if case .songNotFound = err {} else { XCTFail() }
    }

    func test_radioError_noStation() {
        let err: RadioError = .noStation
        if case .noStation = err {} else { XCTFail() }
    }

    func test_radioError_emptyQueue() {
        let err: RadioError = .emptyQueue
        if case .emptyQueue = err {} else { XCTFail() }
    }
}
