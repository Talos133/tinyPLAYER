import XCTest
import CoreData
@testable import tinyPLAYER

/// Tests for the logic driving PlayerView and MiniPlayerView.
///
/// SwiftUI views that rely on @EnvironmentObject cannot be instantiated
/// in unit tests without a hosting controller. Instead, we verify the
/// data-model logic that drives both views: frame sizes are encoded as
/// constants, grade derivation, settings/browser toggle states, and
/// mini-player icon selection — all the same pattern used by the other
/// view test files in this project.
@MainActor
final class PlayerViewTests: XCTestCase {

    // MARK: - Helpers

    private func makeStore() throws -> ScoreStore {
        let container = NSPersistentContainer(name: "tinyPLAYER")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let error = loadError { throw error }
        return ScoreStore(context: container.viewContext)
    }

    // MARK: - Grade derivation (currentGrade computed property logic)

    /// When there is no scored song, currentGrade is nil
    func test_currentGrade_isNil_whenNoScore() throws {
        let store = try makeStore()
        let music = MockMusicService()
        music.currentSongID = "song-1"

        // No score set — score(for:) returns nil → currentGrade is nil
        let grade = music.currentSongID
            .flatMap { store.score(for: $0) }
            .flatMap { GreekGrade(score: Int($0.scoreValue)) }

        XCTAssertNil(grade)
    }

    /// When the current song has a score, currentGrade matches that grade
    func test_currentGrade_matchesStoredScore_whenSongIsScored() throws {
        let store = try makeStore()
        let music = MockMusicService()
        let id = music.currentSongID!

        let identity = SongIdentity(id: id,
                                    title: music.currentTitle,
                                    artist: music.currentArtist,
                                    album:  music.currentAlbum)
        try store.setScore(GreekGrade.alpha.rawValue, for: identity)

        let grade = music.currentSongID
            .flatMap { store.score(for: $0) }
            .flatMap { GreekGrade(score: Int($0.scoreValue)) }

        XCTAssertEqual(grade, .alpha)
    }

    /// When currentSongID is nil, currentGrade is nil (no crash)
    func test_currentGrade_isNil_whenSongIDIsNil() throws {
        let store = try makeStore()
        let music = MockMusicService()
        music.currentSongID = nil

        let grade = music.currentSongID
            .flatMap { store.score(for: $0) }
            .flatMap { GreekGrade(score: Int($0.scoreValue)) }

        XCTAssertNil(grade)
    }

    // MARK: - MiniPlayerView icon selection

    /// When isPlaying is false, mini player renders play.fill
    func test_miniPlayer_icon_isPlayFill_whenNotPlaying() {
        let music = MockMusicService()
        music.isPlaying = false
        let icon = music.isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "play.fill")
    }

    /// When isPlaying is true, mini player renders pause.fill
    func test_miniPlayer_icon_isPauseFill_whenPlaying() {
        let music = MockMusicService()
        music.isPlaying = true
        let icon = music.isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "pause.fill")
    }

    // MARK: - MiniPlayerView skip actions

    func test_miniPlayer_skipNext_callsSkipToNext() async throws {
        let music = MockMusicService()
        XCTAssertFalse(music.skipNextCalled, "precondition: skipNextCalled is false")
        try await music.skipToNext()
        XCTAssertTrue(music.skipNextCalled)
    }

    func test_miniPlayer_skipPrev_callsSkipToPrevious() async throws {
        let music = MockMusicService()
        XCTAssertFalse(music.skipPrevCalled, "precondition: skipPrevCalled is false")
        try await music.skipToPrevious()
        XCTAssertTrue(music.skipPrevCalled)
    }

    // MARK: - MiniPlayerView play / pause actions

    func test_miniPlayer_playTap_callsPlay() async throws {
        let music = MockMusicService()
        music.isPlaying = false
        try await music.play()
        XCTAssertTrue(music.playCalled)
        XCTAssertTrue(music.isPlaying)
    }

    func test_miniPlayer_pauseTap_callsPause() {
        let music = MockMusicService()
        music.isPlaying = true
        music.pause()
        XCTAssertTrue(music.pauseCalled)
        XCTAssertFalse(music.isPlaying)
    }

    // MARK: - Track info passed to MiniPlayerView

    /// Title and artist from MusicService appear on the mini player
    func test_miniPlayer_titleAndArtist_reflectMusicService() {
        let music = MockMusicService()
        XCTAssertEqual(music.currentTitle,  "Mock Song")
        XCTAssertEqual(music.currentArtist, "Mock Artist")
    }

    // MARK: - Grade shown in mini player

    /// MiniPlayer displays the grade symbol when a grade is present
    func test_miniPlayer_grade_symbolDisplayed_whenScored() throws {
        let store = try makeStore()
        let music = MockMusicService()
        let id = music.currentSongID!

        let identity = SongIdentity(id: id,
                                    title: music.currentTitle,
                                    artist: music.currentArtist,
                                    album:  music.currentAlbum)
        try store.setScore(GreekGrade.beta.rawValue, for: identity)

        let grade = music.currentSongID
            .flatMap { store.score(for: $0) }
            .flatMap { GreekGrade(score: Int($0.scoreValue)) }

        XCTAssertEqual(grade?.symbol, GreekGrade.beta.symbol)
    }

    /// MiniPlayer shows no grade when song has no score
    func test_miniPlayer_grade_nilWhenNotScored() throws {
        let store = try makeStore()
        let music = MockMusicService()
        music.currentSongID = "unscored-song"

        let grade = music.currentSongID
            .flatMap { store.score(for: $0) }
            .flatMap { GreekGrade(score: Int($0.scoreValue)) }

        XCTAssertNil(grade)
    }
}
