import XCTest
@testable import tinyPLAYER

@MainActor
final class MockMusicServiceTests: XCTestCase {

    // MARK: - Default State

    func test_defaultTitle_isMockSong() {
        let sut = MockMusicService()
        XCTAssertEqual(sut.currentTitle, "Mock Song")
    }

    func test_defaultArtist_isMockArtist() {
        let sut = MockMusicService()
        XCTAssertEqual(sut.currentArtist, "Mock Artist")
    }

    func test_defaultAlbum_isMockAlbum() {
        let sut = MockMusicService()
        XCTAssertEqual(sut.currentAlbum, "Mock Album")
    }

    func test_defaultYear_is2024() {
        let sut = MockMusicService()
        XCTAssertEqual(sut.currentYear, 2024)
    }

    func test_defaultArtworkURL_isNil() {
        let sut = MockMusicService()
        XCTAssertNil(sut.artworkURL)
    }

    func test_defaultIsPlaying_isFalse() {
        let sut = MockMusicService()
        XCTAssertFalse(sut.isPlaying)
    }

    func test_defaultPlaybackProgress_isZero() {
        let sut = MockMusicService()
        XCTAssertEqual(sut.playbackProgress, 0.0)
    }

    func test_defaultInLibrary_isTrue() {
        let sut = MockMusicService()
        XCTAssertTrue(sut.inLibrary)
    }

    func test_defaultCurrentSongID_isMockID() {
        let sut = MockMusicService()
        XCTAssertEqual(sut.currentSongID, "mock-id-001")
    }

    // MARK: - Call Tracking: play

    func test_play_setsIsPlayingTrue() async throws {
        let sut = MockMusicService()
        try await sut.play()
        XCTAssertTrue(sut.isPlaying)
    }

    func test_play_setsPlayCalledTrue() async throws {
        let sut = MockMusicService()
        try await sut.play()
        XCTAssertTrue(sut.playCalled)
    }

    func test_playCalledFalse_beforePlay() {
        let sut = MockMusicService()
        XCTAssertFalse(sut.playCalled)
    }

    // MARK: - Call Tracking: pause

    func test_pause_setsIsPlayingFalse() async throws {
        let sut = MockMusicService()
        try await sut.play()
        sut.pause()
        XCTAssertFalse(sut.isPlaying)
    }

    func test_pause_setsPauseCalledTrue() {
        let sut = MockMusicService()
        sut.pause()
        XCTAssertTrue(sut.pauseCalled)
    }

    func test_pauseCalledFalse_beforePause() {
        let sut = MockMusicService()
        XCTAssertFalse(sut.pauseCalled)
    }

    // MARK: - Call Tracking: skipToNext

    func test_skipToNext_setsSkipNextCalledTrue() async throws {
        let sut = MockMusicService()
        try await sut.skipToNext()
        XCTAssertTrue(sut.skipNextCalled)
    }

    func test_skipNextCalledFalse_beforeSkip() {
        let sut = MockMusicService()
        XCTAssertFalse(sut.skipNextCalled)
    }

    // MARK: - Call Tracking: skipToPrevious

    func test_skipToPrevious_setsSkipPrevCalledTrue() async throws {
        let sut = MockMusicService()
        try await sut.skipToPrevious()
        XCTAssertTrue(sut.skipPrevCalled)
    }

    func test_skipPrevCalledFalse_beforeSkip() {
        let sut = MockMusicService()
        XCTAssertFalse(sut.skipPrevCalled)
    }

    // MARK: - Call Tracking: addToLibrary

    func test_addToLibrary_setsAddCalledTrue() async throws {
        let sut = MockMusicService()
        try await sut.addToLibrary()
        XCTAssertTrue(sut.addToLibraryCalled)
    }

    func test_addToLibrary_setsInLibraryTrue() async throws {
        let sut = MockMusicService()
        sut.inLibrary = false
        try await sut.addToLibrary()
        XCTAssertTrue(sut.inLibrary)
    }

    // MARK: - Call Tracking: removeFromLibrary

    func test_removeFromLibrary_setsRemoveCalledTrue() async throws {
        let sut = MockMusicService()
        try await sut.removeFromLibrary()
        XCTAssertTrue(sut.removeFromLibraryCalled)
    }

    func test_removeFromLibrary_setsInLibraryFalse() async throws {
        let sut = MockMusicService()
        try await sut.removeFromLibrary()
        XCTAssertFalse(sut.inLibrary)
    }

    // MARK: - requestAuthorization

    func test_requestAuthorization_doesNotThrow() async {
        let sut = MockMusicService()
        await sut.requestAuthorization()
        // No assertion needed — just verifies it completes without crashing
    }

    // MARK: - Properties are mutable (settable for test control)

    func test_canSetCurrentTitle() {
        let sut = MockMusicService()
        sut.currentTitle = "Custom Title"
        XCTAssertEqual(sut.currentTitle, "Custom Title")
    }

    func test_canSetIsPlaying() {
        let sut = MockMusicService()
        sut.isPlaying = true
        XCTAssertTrue(sut.isPlaying)
    }

    func test_canSetPlaybackProgress() {
        let sut = MockMusicService()
        sut.playbackProgress = 0.75
        XCTAssertEqual(sut.playbackProgress, 0.75)
    }

    func test_canSetCurrentSongID() {
        let sut = MockMusicService()
        sut.currentSongID = "custom-id"
        XCTAssertEqual(sut.currentSongID, "custom-id")
    }
}
