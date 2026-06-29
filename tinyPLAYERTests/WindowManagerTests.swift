import XCTest
@testable import tinyPLAYER

@MainActor
final class WindowManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "tinyplayer_windowmode")
        UserDefaults.standard.removeObject(forKey: "tinyplayer_position")
        UserDefaults.standard.removeObject(forKey: "tinyplayer_tuckededge")
    }

    func test_initialMode_isNormal() {
        let mgr = WindowManager(panel: FloatingPanel())
        XCTAssertEqual(mgr.mode, .normal)
    }

    func test_toggleMiniNormal_fromNormal_goesMini() {
        let mgr = WindowManager(panel: FloatingPanel())
        mgr.toggleMiniNormal()
        XCTAssertEqual(mgr.mode, .mini)
    }

    func test_toggleMiniNormal_fromMini_goesNormal() {
        let mgr = WindowManager(panel: FloatingPanel())
        mgr.toggleMiniNormal()
        mgr.toggleMiniNormal()
        XCTAssertEqual(mgr.mode, .normal)
    }

    func test_untuck_whenNotTucked_doesNotChangeModeOrCrash() {
        let mgr = WindowManager(panel: FloatingPanel())
        mgr.untuck()
        XCTAssertEqual(mgr.mode, .normal)
    }

    func test_windowModeEquality_tuckedSameEdge() {
        XCTAssertEqual(WindowMode.tucked(.leading), WindowMode.tucked(.leading))
        XCTAssertNotEqual(WindowMode.tucked(.leading), WindowMode.tucked(.trailing))
    }
}
