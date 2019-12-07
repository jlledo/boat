import XCTest
@testable import Boat

final class BoatTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Boat().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
