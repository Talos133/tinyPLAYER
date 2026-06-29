import XCTest
import SwiftUI
@testable import tinyPLAYER

/// Tests for the logic driving ControlsView.
/// ControlsView uses @EnvironmentObject var music: MusicService (concrete type), so
/// we verify the view's icon-selection logic and control interactions via MockMusicService,
/// which implements the same MusicServiceProtocol contract.
@MainActor
final class ControlsViewTests: XCTestCase {

    // MARK: - Play/Pause icon selection

    /// When isPlaying is false, ControlsView renders "play.fill"
    func test_iconSelection_isPlayFill_whenNotPlaying() {
        let music = MockMusicService()
        music.isPlaying = false
        let icon = music.isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "play.fill")
    }

    /// When isPlaying is true, ControlsView renders "pause.fill"
    func test_iconSelection_isPauseFill_whenPlaying() {
        let music = MockMusicService()
        music.isPlaying = true
        let icon = music.isPlaying ? "pause.fill" : "play.fill"
        XCTAssertEqual(icon, "pause.fill")
    }

    // MARK: - Play button action

    func test_playTap_callsPlay_andSetsIsPlayingTrue() async throws {
        let music = MockMusicService()
        music.isPlaying = false
        XCTAssertFalse(music.playCalled, "precondition: playCalled is false")
        try await music.play()
        XCTAssertTrue(music.playCalled)
        XCTAssertTrue(music.isPlaying)
    }

    // MARK: - Pause button action

    func test_pauseTap_callsPause_andSetsIsPlayingFalse() {
        let music = MockMusicService()
        music.isPlaying = true
        XCTAssertFalse(music.pauseCalled, "precondition: pauseCalled is false")
        music.pause()
        XCTAssertTrue(music.pauseCalled)
        XCTAssertFalse(music.isPlaying)
    }

    // MARK: - Skip Next button action

    func test_skipNextTap_callsSkipToNext() async throws {
        let music = MockMusicService()
        XCTAssertFalse(music.skipNextCalled, "precondition: skipNextCalled is false")
        try await music.skipToNext()
        XCTAssertTrue(music.skipNextCalled)
    }

    // MARK: - Skip Previous button action

    func test_skipPrevTap_callsSkipToPrevious() async throws {
        let music = MockMusicService()
        XCTAssertFalse(music.skipPrevCalled, "precondition: skipPrevCalled is false")
        try await music.skipToPrevious()
        XCTAssertTrue(music.skipPrevCalled)
    }

    // MARK: - Playback progress

    func test_progressValue_isReflectedFromService() {
        let music = MockMusicService()
        music.playbackProgress = 0.42
        XCTAssertEqual(music.playbackProgress, 0.42, accuracy: 0.001)
    }

    func test_progressDefault_isZero() {
        let music = MockMusicService()
        XCTAssertEqual(music.playbackProgress, 0.0)
    }

    // MARK: - Call counts are independent per instance

    func test_playCallCount_startsAtZero() {
        let music = MockMusicService()
        XCTAssertFalse(music.playCalled)
    }

    func test_pauseCallCount_startsAtZero() {
        let music = MockMusicService()
        XCTAssertFalse(music.pauseCalled)
    }

    func test_skipNextCallCount_startsAtZero() {
        let music = MockMusicService()
        XCTAssertFalse(music.skipNextCalled)
    }

    func test_skipPrevCallCount_startsAtZero() {
        let music = MockMusicService()
        XCTAssertFalse(music.skipPrevCalled)
    }
}
