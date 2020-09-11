import XCTest

import CircularBufferTests

var tests = [XCTestCaseEntry]()
tests += CircularBufferTests.allTests()
XCTMain(tests)
