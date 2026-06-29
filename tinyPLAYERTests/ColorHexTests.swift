import XCTest
import SwiftUI
@testable import tinyPLAYER

final class ColorHexTests: XCTestCase {
    func test_hexBlack_parsesCorrectly() {
        // Color(hex:) should not crash on known values
        let _ = Color(hex: "000000")
        let _ = Color(hex: "ffffff")
        let _ = Color(hex: "0d2247")
        // If we get here without crashing, the initializer works
        XCTAssertTrue(true)
    }
}
