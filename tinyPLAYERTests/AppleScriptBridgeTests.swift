import XCTest
@testable import tinyPLAYER

final class AppleScriptBridgeTests: XCTestCase {

    // MARK: - AppleScript execution

    func testRunReturnsNilForInvalidScript() {
        // A syntactically broken script should produce nil (error path),
        // not crash the process.
        let result = AppleScriptBridge.run("this is not valid AppleScript!!!")
        // We don't assert a value — just that it didn't throw / crash.
        _ = result
    }

    func testRunReturnsStringForMathExpression() {
        // A simple arithmetic AppleScript returns a result string.
        let result = AppleScriptBridge.run("return 2 + 2")
        XCTAssertEqual(result, "4")
    }

    func testRunReturnsStringForStringLiteral() {
        let result = AppleScriptBridge.run("return \"hello\"")
        XCTAssertEqual(result, "hello")
    }

    // MARK: - removeFromLibrary script structure

    func testRemoveFromLibraryDoesNotCrash() {
        // This runs against a non-existent song ID; Music.app need not be open.
        // The script should complete (possibly with an error we silently swallow)
        // without crashing or throwing.
        AppleScriptBridge.removeFromLibrary(songID: "999999999")
    }

    // MARK: - hideMusicApp / quitMusicApp (smoke tests — no Music.app required)

    func testHideMusicAppWhenNotRunningDoesNotCrash() {
        // If Music.app is not running this should be a no-op.
        AppleScriptBridge.hideMusicApp()
    }

    func testQuitMusicAppWhenNotRunningDoesNotCrash() {
        // Sending a quit script when Music isn't open should silently fail.
        AppleScriptBridge.quitMusicApp()
    }
}
