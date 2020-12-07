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
    
    func testReplace_whenSubrangeIsEmptyAndNewElementsIsEmpty() {
        var subrange = 0..<0
        let newElements: Array<Int> = []
        var prevStoredElements = sut.allStoredElements
        sut.replace(subrange: subrange, with: newElements)
        XCTAssertEqual(sut.allStoredElements, prevStoredElements)
        
        prevStoredElements = (1...10).shuffled()
        for lowerBound in prevStoredElements.startIndex...prevStoredElements.endIndex {
            subrange = lowerBound..<lowerBound
            sut = CircularBuffer(elements: prevStoredElements)
            sut.replace(subrange: subrange, with: newElements)
            XCTAssertEqual(sut.allStoredElements, prevStoredElements)
            
            // let's also do this test when storage wraps around
            for headShift in 1...prevStoredElements.count {
                sut = CircularBuffer.headShiftedInstance(contentsOf: prevStoredElements, headShift: headShift)
                sut.replace(subrange: subrange, with: newElements, keepCapacity: true, usingSmartCapacityPolicy: true)
                XCTAssertEqual(sut.allStoredElements, prevStoredElements)
            }
        }
    }
    
    func testReplace_whenSubrangeIsEmptyAndNewElementsIsNotEmpty() {
        var subrange = 0..<0
        let newElements = 11...15
        var prevStoredElements = sut.allStoredElements
        var expectedResult = Array(newElements) + prevStoredElements
        sut.replace(subrange: subrange, with: newElements)
        XCTAssertEqual(sut.allStoredElements, expectedResult)
        
        prevStoredElements = (1...10).shuffled()
        for lowerBound in prevStoredElements.startIndex...prevStoredElements.endIndex {
            subrange = lowerBound..<lowerBound
            expectedResult = prevStoredElements
            expectedResult.replaceSubrange(subrange, with: newElements)
            
            sut = CircularBuffer(elements: prevStoredElements)
            sut.replace(subrange: subrange, with: newElements)
            // let's also do this test when storage wraps around
            for headShift in 1...prevStoredElements.count {
                sut = CircularBuffer.headShiftedInstance(contentsOf: prevStoredElements, headShift: headShift)
                sut.replace(subrange: subrange, with: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
            }
        }
    }
    
    func testReplace_whenSubrangeIsNotEmptyAndNewElementsIsEmpty() {
        let prevStoredElements = (1...10).shuffled()
        let newElements: Array<Int> = []
        for lowerBound in prevStoredElements.startIndex..<prevStoredElements.endIndex {
            for upperBound in (lowerBound + 1)...prevStoredElements.endIndex {
                let subrange = lowerBound..<upperBound
                var expectedResult = prevStoredElements
                expectedResult.replaceSubrange(subrange, with: newElements)
                sut = CircularBuffer(elements: prevStoredElements)
                sut.replace(subrange: subrange, with: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                // Let's also do this test when storage wraps around
                for headShift in 1...prevStoredElements.count {
                    sut = CircularBuffer.headShiftedInstance(contentsOf: prevStoredElements, headShift: headShift)
                    sut.replace(subrange: subrange, with: newElements)
                    XCTAssertEqual(sut.allStoredElements, expectedResult)
                }
            }
        }
    }
    
    func testReplace_whenSubRangeIsNotEmptyAndNewElementsIsNotEmpty() {
        let prevStoredElements = (1...10).shuffled()
        let newElementsBase = Array(11...25)
        for lowerBound in prevStoredElements.startIndex..<prevStoredElements.endIndex {
            for upperBound in (lowerBound + 1)...prevStoredElements.endIndex {
                let subrange = lowerBound..<upperBound
                for k in 1..<newElementsBase.count {
                    let newElements = newElementsBase[newElementsBase.startIndex...k]
                    var expectedResult = prevStoredElements
                    expectedResult.replaceSubrange(subrange, with: newElements)
                    sut = CircularBuffer(elements: prevStoredElements)
                    sut.replace(subrange: subrange, with: newElements)
                    XCTAssertEqual(sut.allStoredElements, expectedResult)
                    
                    // Let's also do this test when storage wraps around
                    for headShift in 1...prevStoredElements.count {
                        sut = CircularBuffer.headShiftedInstance(contentsOf: prevStoredElements, headShift: headShift)
                        sut.replace(subrange: subrange, with: newElements)
                        XCTAssertEqual(sut.allStoredElements, expectedResult)
                    }
                }
            }
        }
    }
    
    // MARK: - Tests for capacity management:
    // MARK: - Replace operation will decrease or keep the same actual sut's count:
    func testReplace_whenCapacityShouldDecreaseAndKeepCapacityIsTrue() {
        var prevStoredElements: Array<Int> = []
        var newElements: Array<Int> = []
        var subrange = 0..<0
        // when sut.isEmpty == true, sut.capacity > 0,
        // and operation doesn't increase sut.count:
        sut = CircularBuffer(elements: prevStoredElements)
        var prevCapacity = sut.capacity
        XCTAssertGreaterThan(sut.capacity, sut.count)
        sut.replace(subrange: subrange, with: newElements, keepCapacity: true)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        prevStoredElements = (1...10).shuffled()
        for lowerBound in prevStoredElements.startIndex..<prevStoredElements.endIndex {
            for upperBound in (lowerBound + 1)...prevStoredElements.endIndex {
                subrange = lowerBound..<upperBound
                guard !subrange.isEmpty else { continue }
                
                // when after the replace operation the count stays the same and it was
                // already smaller than capacity:
                sut = CircularBuffer(elements: prevStoredElements)
                XCTAssertGreaterThan(sut.capacity, sut.count)
                prevCapacity = sut.capacity
                let prevCount = sut.count
                newElements = prevStoredElements[subrange].map { $0 * 10 }
                sut.replace(subrange: subrange, with: newElements, keepCapacity: true)
                XCTAssertEqual(sut.count, prevCount)
                XCTAssertEqual(sut.capacity, prevCapacity)
                
                // when after the replace operation the count gets reduced
                sut = CircularBuffer(elements: prevStoredElements)
                let _ = newElements.popLast()
                sut.replace(subrange: subrange, with: newElements, keepCapacity: true)
                XCTAssertEqual(sut.count, prevCount - 1)
                XCTAssertEqual(sut.capacity, prevCapacity)
            }
        }
    }
    
    func testReplace_whenCapacityShouldDecreaseAndKeepCapacityIsFalse() {
        var prevStoredElements: Array<Int> = []
        var newElements: Array<Int> = []
        var subrange = 0..<0
        // when sut.isEmpty == true, sut.capacity > 0,
        // and operation doesn't increase sut.count
        sut = CircularBuffer(elements: prevStoredElements)
        sut.reserveCapacity(16)
        var prevCapacity = sut.capacity
        XCTAssertGreaterThan(sut.capacity, sut.count)
        sut.replace(subrange: subrange, with: newElements, keepCapacity: false, usingSmartCapacityPolicy: true)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.minSmartCapacity)
        // same test when usingSmartCapacityPolicy == false:
        sut = CircularBuffer(elements: prevStoredElements)
        sut.reserveCapacity(16)
        prevCapacity = sut.capacity
        XCTAssertGreaterThan(sut.capacity, sut.count)
        sut.replace(subrange: subrange, with: newElements, keepCapacity: false, usingSmartCapacityPolicy: false)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, sut.count)
        
        prevStoredElements = (1...10).shuffled()
        for lowerBound in prevStoredElements.startIndex..<prevStoredElements.endIndex {
            for upperBound in (lowerBound + 1)...prevStoredElements.endIndex {
                subrange = lowerBound..<upperBound
                guard !subrange.isEmpty else { continue }
                
                // when after the replace operation the count stays the same and it was
                // already smaller than capacity:
                sut = CircularBuffer(elements: prevStoredElements)
                sut.reserveCapacity(32)
                XCTAssertGreaterThan(sut.capacity, sut.count)
                prevCapacity = sut.capacity
                let prevCount = sut.count
                newElements = prevStoredElements[subrange].map { $0 * 10 }
                sut.replace(subrange: subrange, with: newElements, keepCapacity: false, usingSmartCapacityPolicy: true)
                XCTAssertEqual(sut.count, prevCount)
                XCTAssertLessThan(sut.capacity, prevCapacity)
                // same test when usingSmartCapacityPolicy == false:
                sut = CircularBuffer(elements: prevStoredElements)
                XCTAssertGreaterThan(sut.capacity, sut.count)
                prevCapacity = sut.capacity
                sut.replace(subrange: subrange, with: newElements, keepCapacity: false, usingSmartCapacityPolicy: false)
                XCTAssertEqual(sut.count, prevCount)
                XCTAssertLessThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, sut.count)
                
                // when after the replace operation the count gets reduced
                sut = CircularBuffer(elements: prevStoredElements)
                sut.reserveCapacity(32)
                prevCapacity = sut.capacity
                let _ = newElements.popLast()
                sut.replace(subrange: subrange, with: newElements, keepCapacity: false, usingSmartCapacityPolicy: true)
                XCTAssertEqual(sut.count, prevCount - 1)
                XCTAssertLessThan(sut.capacity, prevCapacity)
                // same test when usingSmartCapacityPolicy == false:
                sut = CircularBuffer(elements: prevStoredElements)
                XCTAssertGreaterThan(sut.capacity, sut.count)
                prevCapacity = sut.capacity
                sut.replace(subrange: subrange, with: newElements, keepCapacity: false, usingSmartCapacityPolicy: false)
                XCTAssertEqual(sut.count, prevCount - 1)
                XCTAssertLessThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, sut.count)
            }
        }
    }
    
    // MARK: - Replace operation will increase actual sut's count
    func testReplace_whenCapacityShouldIncrease() {
        var prevStoredElements: Array<Int> = []
        sut = CircularBuffer(elements: prevStoredElements)
        var prevCapacity = sut.capacity
        var prevCount = sut.count
        var newelements = (1...5).shuffled()
        var subrange = 0..<0
        var newCount = prevCount - subrange.count + newelements.count
        XCTAssertGreaterThan(newCount, sut.residualCapacity)
        sut.replace(subrange: subrange, with: newelements, usingSmartCapacityPolicy: true)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: newCount))
        // same test when usingSmartCapacityPolicy == false:
        sut = CircularBuffer(elements: prevStoredElements)
        sut.replace(subrange: subrange, with: newelements, usingSmartCapacityPolicy: false)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, sut.count)
        
        prevStoredElements = (1...10).shuffled()
        newelements = (1...17).map { $0 + 10 }
        for lowerBound in prevStoredElements.startIndex..<prevStoredElements.endIndex {
            for upperBound in (lowerBound + 1)...prevStoredElements.endIndex {
                subrange = lowerBound..<upperBound
                sut = CircularBuffer(elements: prevStoredElements)
                prevCapacity = sut.capacity
                prevCount = sut.count
                newCount = prevCount - subrange.count + newelements.count
                XCTAssertGreaterThan(newCount, sut.residualCapacity)
                sut.replace(subrange: subrange, with: newelements, usingSmartCapacityPolicy: true)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: newCount))
                // same test when usingSmartCapacityPolicy == false:
                sut = CircularBuffer(elements: prevStoredElements)
                sut.replace(subrange: subrange, with: newelements, usingSmartCapacityPolicy: false)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, sut.count)
            }
        }
    }
    
}
