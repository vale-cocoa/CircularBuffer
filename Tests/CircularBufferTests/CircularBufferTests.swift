import XCTest
@testable import CircularBuffer

final class CircularBufferTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CircularBuffer().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
