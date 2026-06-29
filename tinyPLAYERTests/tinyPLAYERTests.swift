import XCTest
@testable import tinyPLAYER

final class tinyPLAYERTests: XCTestCase {

    func testExample() throws {
        // Placeholder test — Task 1 bootstrap
        XCTAssertTrue(true)
    }

    func testPersistenceControllerInit() throws {
        let controller = PersistenceController(inMemory: true)
        XCTAssertNotNil(controller.container)
        XCTAssertEqual(controller.container.name, "tinyPLAYER")
    }
}
