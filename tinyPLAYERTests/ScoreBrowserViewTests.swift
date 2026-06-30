import XCTest
import CoreData
@testable import tinyPLAYER

/// Tests for the logic driving ScoreBrowserView.
/// ScoreBrowserView uses ScoreStore for filtered/sorted results and
/// GreekGrade for filter chips. We verify the underlying data logic here
/// without instantiating the SwiftUI view (which requires EnvironmentObjects).
@MainActor
final class ScoreBrowserViewTests: XCTestCase {

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

    // MARK: - Filter chip: no filter → all songs shown

    func test_filterChips_noSelection_showsAllSongs() throws {
        try seedThreeSongs()
        let results = store.filtered(grades: [], sortedBy: .gradeDesc)
        XCTAssertEqual(results.count, 3)
    }

    // MARK: - Filter chip: single grade → only matching songs

    func test_filterChips_alpha_showsOnlyAlphaSongs() throws {
        try seedThreeSongs()
        let results = store.filtered(grades: [.alpha], sortedBy: .gradeDesc)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.scoreValue, 10)
    }

    func test_filterChips_kappa_showsOnlyKappaSongs() throws {
        try seedThreeSongs()
        let results = store.filtered(grades: [.kappa], sortedBy: .gradeDesc)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.scoreValue, 1)
    }

    // MARK: - Filter chip: multi-select → union of matching songs

    func test_filterChips_multiSelect_returnsUnion() throws {
        try seedThreeSongs()
        // Alpha (10) + Zeta (5) — two of the three seeded songs
        let results = store.filtered(grades: [.alpha, .zeta], sortedBy: .gradeDesc)
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - Filter chip: grade with no matches → empty

    func test_filterChips_unmatchedGrade_returnsEmpty() throws {
        try seedThreeSongs()
        // seedThreeSongs uses scores 10, 5, 1 — no score 9 (Beta)
        let results = store.filtered(grades: [.beta], sortedBy: .gradeDesc)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Empty state: no scored songs at all → empty

    func test_emptyState_noScoredSongs_returnsEmptyList() {
        let results = store.filtered(grades: [], sortedBy: .gradeDesc)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Empty state: filter applied to empty store → empty

    func test_emptyState_filterOnEmptyStore_returnsEmpty() {
        let results = store.filtered(grades: [.alpha], sortedBy: .gradeDesc)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Sort: gradeDesc orders highest first

    func test_sort_gradeDesc_highestScoreFirst() throws {
        try seedThreeSongs()
        let results = store.filtered(grades: [], sortedBy: .gradeDesc)
        XCTAssertEqual(results[0].scoreValue, 10)
        XCTAssertEqual(results[1].scoreValue, 5)
        XCTAssertEqual(results[2].scoreValue, 1)
    }

    // MARK: - Sort: gradeAsc orders lowest first

    func test_sort_gradeAsc_lowestScoreFirst() throws {
        try seedThreeSongs()
        let results = store.filtered(grades: [], sortedBy: .gradeAsc)
        XCTAssertEqual(results[0].scoreValue, 1)
        XCTAssertEqual(results[1].scoreValue, 5)
        XCTAssertEqual(results[2].scoreValue, 10)
    }

    // MARK: - Sort: title sorts alphabetically ascending

    func test_sort_title_alphabeticalAscending() throws {
        let songs = [
            (id: "t1", title: "Zephyr Song", artist: "RHCP",  album: "By the Way", score: 8),
            (id: "t2", title: "Andante",     artist: "Bach",  album: "Suite",       score: 7),
            (id: "t3", title: "Moonlight",   artist: "Elton", album: "Classic",     score: 9),
        ]
        for s in songs {
            try store.setScore(s.score, for: SongIdentity(id: s.id, title: s.title,
                                                          artist: s.artist, album: s.album))
        }
        let results = store.filtered(grades: [], sortedBy: .title)
        XCTAssertEqual(results[0].songTitle, "Andante")
        XCTAssertEqual(results[1].songTitle, "Moonlight")
        XCTAssertEqual(results[2].songTitle, "Zephyr Song")
    }

    // MARK: - Sort: artist sorts alphabetically ascending

    func test_sort_artist_alphabeticalAscending() throws {
        let songs = [
            (id: "a1", title: "Song A", artist: "Zappa",  album: "L", score: 6),
            (id: "a2", title: "Song B", artist: "Adele",  album: "L", score: 7),
            (id: "a3", title: "Song C", artist: "Mingus", album: "L", score: 8),
        ]
        for s in songs {
            try store.setScore(s.score, for: SongIdentity(id: s.id, title: s.title,
                                                          artist: s.artist, album: s.album))
        }
        let results = store.filtered(grades: [], sortedBy: .artist)
        XCTAssertEqual(results[0].artistName, "Adele")
        XCTAssertEqual(results[1].artistName, "Mingus")
        XCTAssertEqual(results[2].artistName, "Zappa")
    }

    // MARK: - Sort: dateScored orders most recent first

    func test_sort_dateScored_mostRecentFirst() throws {
        // Insert in ascending date order; dateScored desc should reverse them
        let s1 = SongIdentity(id: "d1", title: "Old",    artist: "A", album: "L")
        let s2 = SongIdentity(id: "d2", title: "Newest", artist: "B", album: "L")
        try store.setScore(7, for: s1)
        // Small delay to guarantee distinct timestamps
        Thread.sleep(forTimeInterval: 0.01)
        try store.setScore(7, for: s2)

        let results = store.filtered(grades: [], sortedBy: .dateScored)
        XCTAssertEqual(results.first?.songTitle, "Newest")
        XCTAssertEqual(results.last?.songTitle, "Old")
    }

    // MARK: - ScoreSortOption: allCases has 5 entries with correct rawValues

    func test_scoreSortOption_allCases_hasFiveOptions() {
        XCTAssertEqual(ScoreSortOption.allCases.count, 5)
    }

    func test_scoreSortOption_rawValues_matchDisplayNames() {
        XCTAssertEqual(ScoreSortOption.gradeDesc.rawValue,  "Grade ↓")
        XCTAssertEqual(ScoreSortOption.gradeAsc.rawValue,   "Grade ↑")
        XCTAssertEqual(ScoreSortOption.dateScored.rawValue, "Date Scored")
        XCTAssertEqual(ScoreSortOption.artist.rawValue,     "Artist")
        XCTAssertEqual(ScoreSortOption.title.rawValue,      "Title")
    }

    // MARK: - GreekGrade filter chips: all 10 grades available

    func test_filterChips_allGreekGrades_available() {
        XCTAssertEqual(GreekGrade.allCases.count, 10)
    }

    func test_filterChips_eachGrade_hasSymbolAndDisplayName() {
        for grade in GreekGrade.allCases {
            XCTAssertFalse(grade.symbol.isEmpty,      "\(grade) symbol is empty")
            XCTAssertFalse(grade.displayName.isEmpty, "\(grade) displayName is empty")
        }
    }

    // MARK: - Row data: scoreValue maps back to GreekGrade

    func test_songRow_scoreValue_mapsToGreekGrade() throws {
        let identity = SongIdentity(id: "gr1", title: "Test", artist: "A", album: "L")
        try store.setScore(GreekGrade.gamma.rawValue, for: identity)
        let item = store.score(for: "gr1")!
        let grade = GreekGrade(score: Int(item.scoreValue))
        XCTAssertEqual(grade, .gamma)
    }

    // MARK: - Filter + sort combined

    func test_filterAndSort_combined_returnsCorrectSubset() throws {
        try seedThreeSongs()
        // Seed an extra Alpha
        let extra = SongIdentity(id: "extra", title: "Aaardvark", artist: "Z", album: "L")
        try store.setScore(10, for: extra)

        let results = store.filtered(grades: [.alpha], sortedBy: .title)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.songTitle, "Aaardvark") // A before Z title-wise
    }

    // MARK: - Helpers

    /// Seeds three songs with scores: Alpha(10), Zeta(5), Kappa(1)
    private func seedThreeSongs() throws {
        let songs: [(id: String, title: String, artist: String, score: Int)] = [
            ("sb1", "Zero Hour",    "Artist A", 10),
            ("sb2", "Middle Road",  "Artist B",  5),
            ("sb3", "Kappa King",   "Artist C",  1),
        ]
        for s in songs {
            try store.setScore(s.score, for: SongIdentity(id: s.id, title: s.title,
                                                          artist: s.artist, album: "Album"))
        }
    }
}
