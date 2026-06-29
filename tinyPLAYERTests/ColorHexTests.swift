import XCTest
import SwiftUI
import AppKit
@testable import tinyPLAYER

final class ColorHexTests: XCTestCase {

    func test_hexColor_parsesRGBComponentsCorrectly() {
        // Greek Aegean background: #0d2247
        let color = Color(hex: "0d2247")
        let ns = NSColor(color).usingColorSpace(.sRGB)
        XCTAssertNotNil(ns)
        XCTAssertEqual(ns!.redComponent,   Double(0x0d) / 255, accuracy: 0.005)
        XCTAssertEqual(ns!.greenComponent, Double(0x22) / 255, accuracy: 0.005)
        XCTAssertEqual(ns!.blueComponent,  Double(0x47) / 255, accuracy: 0.005)
    }

    func test_hexColor_withHashPrefix_parsesCorrectly() {
        let withHash    = Color(hex: "#ff6b35")
        let withoutHash = Color(hex: "ff6b35")
        let ns1 = NSColor(withHash).usingColorSpace(.sRGB)!
        let ns2 = NSColor(withoutHash).usingColorSpace(.sRGB)!
        XCTAssertEqual(ns1.redComponent, ns2.redComponent, accuracy: 0.005)
    }

    func test_hexBlack_isBlack() {
        let color = Color(hex: "000000")
        let ns = NSColor(color).usingColorSpace(.sRGB)!
        XCTAssertEqual(ns.redComponent,   0, accuracy: 0.005)
        XCTAssertEqual(ns.greenComponent, 0, accuracy: 0.005)
        XCTAssertEqual(ns.blueComponent,  0, accuracy: 0.005)
    }
}
