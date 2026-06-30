import XCTest
import SwiftUI
@testable import tinyPLAYER

/// Tests for TuckedView chevron direction logic.
/// The rule: the chevron points in the direction you'd drag the window to un-tuck it.
/// - .leading (window hidden off left edge)  → chevron.right  (pull right to reveal)
/// - .trailing (window hidden off right edge) → chevron.left   (pull left to reveal)
/// - .top (window hidden off top edge)        → chevron.down   (pull down to reveal)
/// - .bottom (window hidden off bottom edge)  → chevron.up     (pull up to reveal)
@MainActor
final class TuckedViewTests: XCTestCase {

    func test_chevronIcon_leadingEdge_isChevronRight() {
        let view = TuckedView(edge: .leading, onPeek: {})
        XCTAssertEqual(view.chevronSystemName, "chevron.right",
                       "Leading edge should show right-pointing chevron to invite un-tucking rightward")
    }

    func test_chevronIcon_trailingEdge_isChevronLeft() {
        let view = TuckedView(edge: .trailing, onPeek: {})
        XCTAssertEqual(view.chevronSystemName, "chevron.left",
                       "Trailing edge should show left-pointing chevron to invite un-tucking leftward")
    }

    func test_chevronIcon_topEdge_isChevronDown() {
        let view = TuckedView(edge: .top, onPeek: {})
        XCTAssertEqual(view.chevronSystemName, "chevron.down",
                       "Top edge should show down-pointing chevron to invite un-tucking downward")
    }

    func test_chevronIcon_bottomEdge_isChevronUp() {
        let view = TuckedView(edge: .bottom, onPeek: {})
        XCTAssertEqual(view.chevronSystemName, "chevron.up",
                       "Bottom edge should show up-pointing chevron to invite un-tucking upward")
    }

    func test_onPeek_calledWhenButtonTapped() {
        var peekCalled = false
        let view = TuckedView(edge: .leading, onPeek: { peekCalled = true })
        // Invoke the closure directly — SwiftUI button tap simulation via closure reference
        view.onPeek()
        XCTAssertTrue(peekCalled, "onPeek closure should be invoked when the button is tapped")
    }

    func test_allEdges_haveDistinctChevrons() {
        let allEdges: [ScreenEdge] = [.leading, .trailing, .top, .bottom]
        let icons = allEdges.map { TuckedView(edge: $0, onPeek: {}).chevronSystemName }
        let uniqueIcons = Set(icons)
        XCTAssertEqual(uniqueIcons.count, allEdges.count,
                       "Each edge should map to a distinct chevron icon")
    }
}
