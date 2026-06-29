import XCTest
@testable import tinyPLAYER

@MainActor
final class ThemeManagerTests: XCTestCase {

    func test_defaultPalette_isGreekAegean() {
        UserDefaults.standard.removeObject(forKey: "tinyplayer_palette")
        let mgr = ThemeManager()
        XCTAssertEqual(mgr.current.name, "Greek Aegean")
    }

    func test_applyPalette_changesCurrentTheme() {
        let mgr = ThemeManager()
        mgr.apply(palette: Palettes.forest)
        XCTAssertEqual(mgr.current.name, "Forest")
    }

    func test_defaultFontSize_isMedium() {
        UserDefaults.standard.removeObject(forKey: "tinyplayer_fontsize")
        let mgr = ThemeManager()
        XCTAssertEqual(mgr.fontSize, .medium)
    }

    func test_applyFontSize_updatesSize() {
        let mgr = ThemeManager()
        mgr.apply(fontSize: .large)
        XCTAssertEqual(mgr.fontSize, .large)
    }

    func test_palettes_containsSixEntries() {
        XCTAssertEqual(Palettes.all.count, 6)
    }

    func test_fontSizeBodyPoints() {
        XCTAssertEqual(AppFontSize.small.body,  11)
        XCTAssertEqual(AppFontSize.medium.body, 13)
        XCTAssertEqual(AppFontSize.large.body,  15)
    }
}
