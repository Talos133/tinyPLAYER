import XCTest
import CoreData
@testable import tinyPLAYER

@MainActor
final class ScoreStoreTests: XCTestCase {
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

    func test_setScore_persistsCorrectValue() throws {
        let song = SongIdentity(id: "s1", title: "Bohemian Rhapsody",
                                artist: "Queen", album: "A Night at the Opera")
        try store.setScore(10, for: song)
        let result = store.score(for: "s1")
        XCTAssertEqual(result?.scoreValue, 10)
    }

    func test_setScore_storesGreekGradeForAlpha() throws {
        let song = SongIdentity(id: "s2", title: "T", artist: "A", album: "L")
        try store.setScore(10, for: song)
        XCTAssertEqual(GreekGrade(score: Int(store.score(for: "s2")!.scoreValue)), .alpha)
    }

    func test_setScore_invalidValue_throwsScoreError() {
        let song = SongIdentity(id: "s3", title: "T", artist: "A", album: "L")
        XCTAssertThrowsError(try store.setScore(0,  for: song))
        XCTAssertThrowsError(try store.setScore(11, for: song))
    }

    func test_clearScore_removesEntry() throws {
        let song = SongIdentity(id: "s4", title: "T", artist: "A", album: "L")
        try store.setScore(7, for: song)
        try store.clearScore(for: "s4")
        XCTAssertNil(store.score(for: "s4"))
    }

    func test_filtered_byAlpha_returnsOnlyAlphaSongs() throws {
        let s1 = SongIdentity(id: "f1", title: "A", artist: "X", album: "L")
        let s2 = SongIdentity(id: "f2", title: "B", artist: "X", album: "L")
        try store.setScore(10, for: s1) // Alpha
        try store.setScore(5,  for: s2) // Zeta
        let results = store.filtered(grades: [.alpha], sortedBy: .gradeDesc)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.songID, "f1")
    }

    func test_filtered_emptyGrades_returnsAll() throws {
        let s1 = SongIdentity(id: "g1", title: "A", artist: "X", album: "L")
        let s2 = SongIdentity(id: "g2", title: "B", artist: "X", album: "L")
        try store.setScore(10, for: s1)
        try store.setScore(5,  for: s2)
        let results = store.filtered(grades: [], sortedBy: .gradeDesc)
        XCTAssertEqual(results.count, 2)
    }

    func test_sorted_byTitle_isCaseInsensitiveAscending() throws {
        let s1 = SongIdentity(id: "h1", title: "Zephyr",  artist: "A", album: "L")
        let s2 = SongIdentity(id: "h2", title: "Andante", artist: "A", album: "L")
        try store.setScore(8, for: s1)
        try store.setScore(8, for: s2)
        let results = store.filtered(grades: [], sortedBy: .title)
        XCTAssertEqual(results.first?.songTitle, "Andante")
    }
}
