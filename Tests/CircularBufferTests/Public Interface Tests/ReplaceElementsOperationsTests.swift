//
//  ReplaceElementsOperationsTests.swift
//  CircularBufferTests
//
//  Created by Valeriano Della Longa on 2020/12/04.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import XCTest
@testable import CircularBuffer

final class ReplaceElementsOperationsTests: XCTestCase {
    var sut: CircularBuffer<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularBuffer<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    /*
    // MARK: - replace(subRange:with:) tests
    func test_replaceSubrange_whenBothSubrangeCountAndNewElementsCountAreZero_doesNothing() {
        var prevCount = sut.count
        sut.replace(subrange: 0..<0, with: [])
        XCTAssertEqual(sut.count, prevCount)
        
        whenFull()
        prevCount = sut.count
        let prevElements = containedElementsWhenFull()
        var result = [Int]()
        for i in 0...sut.count {
            sut.replace(subrange: i..<i, with: [])
            XCTAssertEqual(sut.count, prevCount)
            result = sutContainedElements()
            XCTAssertEqual(result, prevElements)
            
            // Restore SUT state and result to previous state for
            // next iteration
            whenFull()
            result.removeAll()
        }
    }
    
    func test_replaceSubrange_whenSubrangeCountIsZeroAndNewElementsCountGreaterThanZero_newElementsAreInsertedAtSubrangeLowerBoundPosition() {
        var prevCount = sut.count
        var result = [Int]()
        let newElements = [5, 6, 7, 8]
        sut.replace(subrange: 0..<0, with: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
        result = sutContainedElements()
        XCTAssertEqual(result, newElements)
        
        whenFull()
        prevCount = sut.count
        let previousElements = containedElementsWhenFull()
        result.removeAll()
        for i in 0...sut.count {
            let subrange = i..<i
            sut.replace(subrange: subrange, with: newElements)
            result = sutContainedElements()
            XCTAssertEqual(result.count, prevCount + newElements.count)
            let expectedResult = Array(previousElements[0..<subrange.lowerBound]) + newElements + Array(previousElements[subrange.lowerBound..<previousElements.count])
            XCTAssertEqual(result, expectedResult)
            
            // Restore SUT state and result to previous state for
            // next iteration
            whenFull()
            result.removeAll()
        }
    }
    
    func test_replaceSubrange_whenSubrangeCountIsGreaterThanZeroAndNewElementsCountIsZero_removesElementsAtSubrangePositions() {
        whenFull()
        let prevCount = sut.count
        let prevElements = containedElementsWhenFull()
        var result = [Int]()
        for startIdx in 0...(sut.count - 1) {
            for endIdx in (startIdx + 1)...sut.count {
                let subrange = startIdx..<endIdx
                XCTAssertGreaterThan(subrange.count, 0)
                
                sut.replace(subrange: subrange, with: [])
                XCTAssertEqual(sut.count, prevCount - subrange.count)
                result = sutContainedElements()
                let expectedResult = Array(prevElements[0..<startIdx]) + Array(prevElements[endIdx..<prevElements.endIndex])
                XCTAssertEqual(result, expectedResult)
                
                // restore SUT state and result for next iteration
                whenFull()
                result.removeAll()
            }
        }
    }
    
    func testReplaceSubrange_whenSubrangeCountIsGreaterThanZeroAndNewElementsCountIsGreaterThanZero_replacesElementsAtSubrangeWithNewElements() {
        whenFull()
        let prevElements = containedElementsWhenFull()
        let prevCount = sut.count
        let newElements = [5, 6, 7, 8]
        var result = [Int]()
        for startIdx in 0...(sut.count - 1) {
            for endIdx in (startIdx + 1)...sut.count {
                let subrange = startIdx..<endIdx
                XCTAssertGreaterThan(subrange.count, 0)
                
                sut.replace(subrange: subrange, with: newElements)
                result = sutContainedElements()
                var expectedResult = prevElements
                expectedResult.replaceSubrange(subrange, with: newElements)
                
                XCTAssertEqual(sut.count, prevCount - subrange.count + newElements.count)
                XCTAssertEqual(result, expectedResult)
                
                // restore SUT state and result for next iteration
                whenFull()
                result.removeAll()
            }
        }
    }
    
    func testReplaceSubRange_withSubrangeInMiddleAndNoBufferResizeWillOccur() {
        sut = nil
        sut = CircularBuffer<Int>(elements: [1, 2, 10, 11, 8])
        let prevCount = sut.count
        let prevCapacity = sut.capacity
        let prevElements = sutContainedElements()
        let subrange = 2..<4
        let newElements = [3, 4, 5, 6, 7]
        var expectedResult = prevElements
        expectedResult.replaceSubrange(subrange, with: newElements)
        XCTAssertEqual(expectedResult, [1, 2, 3, 4, 5, 6, 7 ,8])
        
        sut.replace(subrange: subrange, with: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.count, prevCount - subrange.count + newElements.count)
        let result = sutContainedElements()
        XCTAssertEqual(result, expectedResult)
    }
    */
}
