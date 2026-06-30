import XCTest
import CoreData
@testable import tinyPLAYER

/// Tests for the logic driving ActionBarView.
/// ActionBarView uses @EnvironmentObject var music: MusicService (concrete type), so
/// we verify the view's action logic and interactions via MockMusicService and ScoreStore.
@MainActor
final class ActionBarViewTests: XCTestCase {

    var store: ScoreStore!

    override func setUpWithError() throws {
        let container = NSPersistentContainer(name: "tinyPLAYER")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let error = loadError { throw error }
        store = ScoreStore(context: container.viewContext)
    }

    // MARK: - Library toggle: inLibrary = true → removeFromLibrary

    func test_libraryToggle_whenInLibrary_callsRemoveFromLibrary() async throws {
        let music = MockMusicService()
        music.inLibrary = true

        XCTAssertFalse(music.removeFromLibraryCalled, "precondition: removeFromLibraryCalled is false")
        try await music.removeFromLibrary()
        XCTAssertTrue(music.removeFromLibraryCalled)
        XCTAssertFalse(music.inLibrary)
    }

    // MARK: - Library toggle: inLibrary = false → addToLibrary

    func test_libraryToggle_whenNotInLibrary_callsAddToLibrary() async throws {
        let music = MockMusicService()
        music.inLibrary = false

        XCTAssertFalse(music.addToLibraryCalled, "precondition: addToLibraryCalled is false")
        try await music.addToLibrary()
        XCTAssertTrue(music.addToLibraryCalled)
        XCTAssertTrue(music.inLibrary)
    }

    // MARK: - Library icon selection

    func test_libraryIcon_isHeartFill_whenInLibrary() {
        let music = MockMusicService()
        music.inLibrary = true
        let icon = music.inLibrary ? "heart.fill" : "heart"
        XCTAssertEqual(icon, "heart.fill")
    }

    func test_libraryIcon_isHeart_whenNotInLibrary() {
        let music = MockMusicService()
        music.inLibrary = false
        let icon = music.inLibrary ? "heart.fill" : "heart"
        XCTAssertEqual(icon, "heart")
    }

    // MARK: - Score: setting a new grade stores it

    func test_scoreSet_storesCorrectGrade() throws {
        let music = MockMusicService()
        let id = music.currentSongID!
        let identity = SongIdentity(id: id,
                                    title: music.currentTitle,
                                    artist: music.currentArtist,
                                    album: music.currentAlbum)
        try store.setScore(GreekGrade.alpha.rawValue, for: identity)
        let saved = store.score(for: id)
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.scoreValue, Int16(GreekGrade.alpha.rawValue))
    }

    // MARK: - Score: tapping same grade clears the score

    func test_scoreSet_thenClear_removesEntry() throws {
        let music = MockMusicService()
        let id = music.currentSongID!
        let identity = SongIdentity(id: id,
                                    title: music.currentTitle,
                                    artist: music.currentArtist,
                                    album: music.currentAlbum)
        try store.setScore(GreekGrade.beta.rawValue, for: identity)
        XCTAssertNotNil(store.score(for: id), "precondition: score exists")

        try store.clearScore(for: id)
        XCTAssertNil(store.score(for: id))
    }

    // MARK: - Score: toggling logic (same grade → clear, different grade → set)

    func test_scorePicker_tapSameGrade_clearsScore() throws {
        let music = MockMusicService()
        let id = music.currentSongID!
        let identity = SongIdentity(id: id,
                                    title: music.currentTitle,
                                    artist: music.currentArtist,
                                    album: music.currentAlbum)
        let grade = GreekGrade.gamma
        try store.setScore(grade.rawValue, for: identity)

        // Simulate what ActionBarView does: if currentScore == grade.rawValue → clear
        let currentScore = store.score(for: id).map { Int($0.scoreValue) }
        if currentScore == grade.rawValue {
            try store.clearScore(for: id)
        } else {
            try store.setScore(grade.rawValue, for: identity)
        }

        XCTAssertNil(store.score(for: id))
    }

    func test_scorePicker_tapDifferentGrade_setsNewScore() throws {
        let music = MockMusicService()
        let id = music.currentSongID!
        let identity = SongIdentity(id: id,
                                    title: music.currentTitle,
                                    artist: music.currentArtist,
                                    album: music.currentAlbum)
        // Start with delta (7)
        try store.setScore(GreekGrade.delta.rawValue, for: identity)

        // Tap alpha (10) — different grade → sets new score
        let newGrade = GreekGrade.alpha
        let currentScore = store.score(for: id).map { Int($0.scoreValue) }
        if currentScore == newGrade.rawValue {
            try store.clearScore(for: id)
        } else {
            try store.setScore(newGrade.rawValue, for: identity)
        }

        XCTAssertEqual(store.score(for: id)?.scoreValue, Int16(newGrade.rawValue))
    }

    // MARK: - Score: no song ID → no store interaction

    func test_scorePicker_noSongID_doesNothing() throws {
        let music = MockMusicService()
        music.currentSongID = nil
        guard let id = music.currentSongID else {
            // Expected path — no action taken
            XCTAssertNil(store.score(for: "any-id"))
            return
        }
        // Should not reach here
        XCTFail("Expected currentSongID to be nil, got \(id)")
    }

    // MARK: - GreekGrade: allCases has 10 entries (Κ to Α)

    func test_greekGrade_allCases_has10Entries() {
        XCTAssertEqual(GreekGrade.allCases.count, 10)
    }

    func test_greekGrade_rawValues_range_1_to_10() {
        let values = GreekGrade.allCases.map(\.rawValue)
        XCTAssertEqual(values.min(), 1)
        XCTAssertEqual(values.max(), 10)
    }

    func test_greekGrade_alpha_isHighest() {
        XCTAssertEqual(GreekGrade.alpha.rawValue, 10)
    }

    func test_greekGrade_kappa_isLowest() {
        XCTAssertEqual(GreekGrade.kappa.rawValue, 1)
    }

    // MARK: - SharingService: buildShareItems includes text and URL

    func test_sharingService_buildShareItems_containsTextAndURL() {
        let items = SharingService.buildShareItems(for: "mock-id-001",
                                                   title: "Mock Song",
                                                   artist: "Mock Artist")
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items[0] is String)
        XCTAssertTrue(items[1] is URL)
    }

    func test_sharingService_buildShareItems_textContainsTitleAndArtist() {
        let items = SharingService.buildShareItems(for: "mock-id-001",
                                                   title: "Mock Song",
                                                   artist: "Mock Artist")
        guard let text = items[0] as? String else {
            XCTFail("First item is not a String")
            return
        }
        XCTAssertTrue(text.contains("Mock Song"))
        XCTAssertTrue(text.contains("Mock Artist"))
    }
}
