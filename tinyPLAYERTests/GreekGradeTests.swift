import XCTest
@testable import tinyPLAYER

final class GreekGradeTests: XCTestCase {

    func test_alpha_rawValue_is10() {
        XCTAssertEqual(GreekGrade.alpha.rawValue, 10)
    }

    func test_kappa_rawValue_is1() {
        XCTAssertEqual(GreekGrade.kappa.rawValue, 1)
    }

    func test_alpha_symbol_isCorrectUnicode() {
        XCTAssertEqual(GreekGrade.alpha.symbol, "Α")
    }

    func test_kappa_symbol_isCorrectUnicode() {
        XCTAssertEqual(GreekGrade.kappa.symbol, "Κ")
    }

    func test_init_validScore_returnsGrade() {
        XCTAssertEqual(GreekGrade(score: 10), .alpha)
        XCTAssertEqual(GreekGrade(score: 1),  .kappa)
        XCTAssertEqual(GreekGrade(score: 8),  .gamma)
    }

    func test_init_invalidScore_returnsNil() {
        XCTAssertNil(GreekGrade(score: 0))
        XCTAssertNil(GreekGrade(score: 11))
    }

    func test_allCases_hasTenEntries() {
        XCTAssertEqual(GreekGrade.allCases.count, 10)
    }

    func test_comparable_alphaGreaterThanKappa() {
        XCTAssertTrue(GreekGrade.alpha > GreekGrade.kappa)
    }
}
