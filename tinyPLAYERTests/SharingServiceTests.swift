import XCTest
@testable import tinyPLAYER

final class SharingServiceTests: XCTestCase {

    // MARK: - buildShareItems

    func testBuildShareItems_containsURL() {
        let items = SharingService.buildShareItems(
            for: "12345",
            title: "Test Song",
            artist: "Test Artist"
        )

        let urls = items.compactMap { $0 as? URL }
        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls.first?.absoluteString,
                       "music://music.apple.com/song/12345")
    }

    func testBuildShareItems_containsTitleByArtistString() {
        let items = SharingService.buildShareItems(
            for: "12345",
            title: "Test Song",
            artist: "Test Artist"
        )

        let strings = items.compactMap { $0 as? String }
        XCTAssertTrue(
            strings.contains(where: { $0.contains("Test Song") && $0.contains("Test Artist") }),
            "Items should contain a string with both title and artist"
        )
    }

    func testBuildShareItems_urlUsesCorrectScheme() {
        let items = SharingService.buildShareItems(
            for: "987",
            title: "Another",
            artist: "Band"
        )

        let url = items.compactMap { $0 as? URL }.first
        XCTAssertEqual(url?.scheme, "music")
    }

    func testBuildShareItems_urlContainsSongID() {
        let songID = "abc-song-id"
        let items = SharingService.buildShareItems(
            for: songID,
            title: "Title",
            artist: "Artist"
        )

        let url = items.compactMap { $0 as? URL }.first
        XCTAssertTrue(
            url?.absoluteString.hasSuffix(songID) == true,
            "URL should end with the song ID"
        )
    }

    func testBuildShareItems_stringContainsLink() {
        let songID = "999"
        let items = SharingService.buildShareItems(
            for: songID,
            title: "My Track",
            artist: "My Artist"
        )

        let strings = items.compactMap { $0 as? String }
        let linkString = "music://music.apple.com/song/\(songID)"
        XCTAssertTrue(
            strings.contains(where: { $0.contains(linkString) }),
            "Items should contain a string that includes the deep link"
        )
    }

    func testBuildShareItems_returnsAtLeastTwoItems() {
        let items = SharingService.buildShareItems(
            for: "1",
            title: "T",
            artist: "A"
        )
        XCTAssertGreaterThanOrEqual(items.count, 2,
            "Should return at least a text string and a URL")
    }
}
