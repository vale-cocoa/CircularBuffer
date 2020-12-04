//
//  RemoveElementsOperationsTests.swift
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

final class RemoveElementsOperationsTests: XCTestCase {
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
    // MARK: - popFirst() tests
    func testPopFirst_whenEmpty_returnsNil() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popFirst())
    }
    
    func testPopFirst_whenNotEmpty_countDecreasesByOne() {
        whenFull()
        let previousCount = sut.count
        sut.popFirst()
        XCTAssertEqual(sut.count, previousCount - 1)
    }
    
    func testPopFirst_whenNotEmpty_removesAndReturnsFirst() {
        whenFull()
        let oldFirst = sut.first
        XCTAssertEqual(sut.popFirst(), oldFirst)
        XCTAssertNotEqual(sut.first, oldFirst)
    }
    
    func testPopFirst_reducesCapacityWhenPossible() {
        sut = CircularBuffer(elements: 1...6)
        var prevCapacity = sut.capacity
        while let _ = sut.popFirst() {
            if !sut.isEmpty {
                XCTAssertEqual(sut.capacity, prevCapacity)
            }
        }
        XCTAssertTrue(sut.isEmpty)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        
        sut = CircularBuffer(elements: 1...24)
        prevCapacity = sut.capacity
        for _ in 1...8 { sut.popFirst() }
        XCTAssertEqual(sut.capacity, prevCapacity)
        for _ in 1...8 { sut.popFirst() }
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, prevCapacity >> 2)
        
        // when a push triggers a capacity resize, a pop immediately after
        // doesn't trigger a capacity downsizing:
        prevCapacity = sut.capacity
        sut.push(10)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        prevCapacity = sut.capacity
        sut.popFirst()
        XCTAssertEqual(sut.capacity, prevCapacity)
    }
    
    // MARK: - removeFirst(_:keepCapacity:) tests
    func testRemoveFirst_whenZero_doesntRemoveAnyElementAndReturnsEmptyArray() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        let prevCount = sut.count
        XCTAssertEqual(sut.removeFirst(0), [])
        XCTAssertEqual(prevCount, sut.count)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func testRemoveFirst_whenOne_removesAndReturnsFirstElementAndDecreasesCountByOne() {
        whenFull()
        let prevCount = sut.count
        let firstElement = [sut.first]
        XCTAssertEqual(sut.removeFirst(1), firstElement)
        XCTAssertEqual(sut.count, prevCount - 1)
        XCTAssertNotEqual(sut.first, firstElement.first!)
    }
    
    func testRemoveFirst_whenEqualCount_removesAndReturnsAllElements() {
        whenFull()
        XCTAssertEqual(sut.removeFirst(sut.count), containedElementsWhenFull())
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testRemoveFirst_whenMoreThanOneAndLessThanCount_removesAndReturnsFirstElements() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        XCTAssertEqual(sut.removeFirst(containedElements.count / 2), Array(containedElements[0..<containedElements.count / 2]))
        XCTAssertEqual(sut.count, (containedElements.count - (containedElements.count / 2)))
    }
    
    func testRemoveFirst_whenContainedElementsAreSplitInBuffer() {
        sut.push(2)
        sut.push(1)
        sut.append(3)
        sut.append(4)
        XCTAssertGreaterThan(sut.head + 3, sut.capacity)
        XCTAssertEqual([sut[0], sut[1], sut[2], sut[3]], [1, 2, 3, 4])
        
        XCTAssertEqual(sut.removeFirst(3), [1, 2, 3])
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, sut.last)
        XCTAssertEqual(sut.first, 4)
    }
    
    func testRemoveFirst_whenZeroAndKeepCapacityIsFalseAndCapacityCantBeReducedAnyFurther_thenDoesntReduceCapacity() {
        whenFull()
        XCTAssert(sut.isFull)
        var expectedCapacity = sut.capacity
        sut.removeFirst(0, keepCapacity: false)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        sut.append(5)
        expectedCapacity = sut.capacity
        sut.removeFirst(0, keepCapacity: false)
        XCTAssertEqual(sut.capacity, expectedCapacity)
    }
    
    func testRemoveFirst_whenCountIsZeroAndKeepCapacityIsFalse_thenReducesCapacityWhenPossible() {
        whenFull()
        let expectedCapacity = sut.capacity
        sut.reserveCapacity(5)
        XCTAssertGreaterThan(sut.capacity, expectedCapacity)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        sut.removeFirst(0, keepCapacity: false)
        XCTAssertEqual(sut.capacity, expectedCapacity)
    }
    
    func testRemoveFirst_whenKeepCapacityFalseAndRemovesEnoughElementsToTriggerResize_thenCapacityGetsResized() {
        whenFull()
        var prevCapacity = sut.capacity
        var added = 0
        while sut.capacity <= (prevCapacity << 1) {
            added += 1
            sut.append(added + 4)
        }
        prevCapacity = sut.capacity
        sut.removeFirst(added, keepCapacity: false)
        XCTAssertLessThan(sut.capacity, prevCapacity)
    }
    
    // MARK: - popLast() tests
    func testPopLast_whenEmpty_returnsNil() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popLast())
    }
    
    func testPopLast_whenNotEmpty_countDecreasesByOne() {
        whenFull()
        let previousCount = sut.count
        sut.popLast()
        XCTAssertEqual(sut.count, previousCount - 1)
    }
    
    func testPopLast_whenNotEmpty_removesAndReturnsLast() {
        whenFull()
        let oldLast = sut.last
        XCTAssertEqual(sut.popLast(), oldLast)
        XCTAssertNotEqual(sut.last, oldLast)
    }
    
    func testPopLast_reducesCapacityWhenPossible() {
        sut = CircularBuffer(elements: 1...6)
        var prevCapacity = sut.capacity
        while let _ = sut.popLast() {
            if !sut.isEmpty {
                XCTAssertEqual(sut.capacity, prevCapacity)
            }
        }
        XCTAssertTrue(sut.isEmpty)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        
        sut = CircularBuffer(elements: 1...24)
        prevCapacity = sut.capacity
        for _ in 1...8 { sut.popLast() }
        XCTAssertEqual(sut.capacity, prevCapacity)
        for _ in 1...8 { sut.popLast() }
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, prevCapacity >> 2)
        
        // when a push triggers a capacity resize, a pop immediately after
        // doesn't trigger a capacity downsizing:
        prevCapacity = sut.capacity
        sut.push(10)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        prevCapacity = sut.capacity
        sut.popLast()
        XCTAssertEqual(sut.capacity, prevCapacity)
    }
    
    // MARK: - removeLast(_:keepCapacity:) tests
    func test_removeLast_whenZero_doesntRemoveElementsAndReturnsEmptyArray() {
        whenFull()
        let previousCount = sut.count
        let containedElements = containedElementsWhenFull()
        XCTAssertEqual(sut.removeLast(0, keepCapacity: true), [])
        XCTAssertEqual(sut.count, previousCount)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func testRemoveLast_whenOne_removesAndReturnsLastElementAndDecreasesByOneCount() {
        whenFull()
        let lastElement = [sut.last]
        let previousCount = sut.count
        
        XCTAssertEqual(sut.removeLast(1), lastElement)
        XCTAssertEqual(sut.count, previousCount - 1)
        XCTAssertNotEqual(sut.last, lastElement.first!)
    }
    
    func testRemoveLast_whenEqualCount_removesAndReturnsAllElements() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        XCTAssertEqual(sut.removeLast(sut.count), containedElements)
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testRemoveLast_whenMoreThanOneAndLessThanCount_removesAndReturnsLastElements() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        XCTAssertEqual(sut.removeLast(sut.count / 2), Array(containedElements[containedElements.count / 2..<containedElements.count]))
        XCTAssertEqual(sut.count, (containedElements.count -  (containedElements.count / 2)))
        var restOfElements = [Int]()
        while let el = sut.popFirst() {
            restOfElements.append(el)
        }
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.head, sut.tail)
        XCTAssertEqual(restOfElements, Array(containedElements[0..<(containedElements.count / 2)]))
    }
    
    func testRemoveLast_whenContainedElementsAreSplitInBuffer() {
        sut.append(2)
        sut.append(3)
        sut.append(4)
        sut.push(1)
        XCTAssertGreaterThanOrEqual(sut.tail - 3, 0)
        
        let lastElements = [sut[1], sut[2], sut[3]]
        XCTAssertEqual(sut.removeLast(3), lastElements)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, sut.last)
        XCTAssertEqual(sut.first, 1)
    }
    
    func testRemoveLast_whenZeroAndKeepCapacityIsFalseAndCapacityCantBeReducedAnyFurther_doesntReduceCapacity() {
        whenFull()
        XCTAssert(sut.isFull)
        var expectedCapacity = sut.capacity
        sut.removeLast(0, keepCapacity: false)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        sut.append(5)
        expectedCapacity = sut.capacity
        sut.removeLast(0, keepCapacity: false)
        XCTAssertEqual(sut.capacity, expectedCapacity)
    }
    
    func testRemoveLast_whenCountIsZeroAndKeepCapacityIsFalse_reducesCapacityWhenPossible() {
        whenFull()
        let expectedCapacity = sut.capacity
        sut.reserveCapacity(5)
        XCTAssertGreaterThan(sut.capacity, expectedCapacity)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        sut.removeLast(0, keepCapacity: false)
        XCTAssertEqual(sut.capacity, expectedCapacity)
    }
    
    func testRemoveLast_whenKeepCapacityFalseAndRemovesEnoughElementsToTriggerResize_capacityGetsResized() {
        whenFull()
        var prevCapacity = sut.capacity
        var added = 0
        while sut.capacity <= (prevCapacity << 1) {
            added += 1
            sut.append(added + 4)
        }
        prevCapacity = sut.capacity
        sut.removeLast(added, keepCapacity: false)
        XCTAssertLessThan(sut.capacity, prevCapacity)
    }
    
    // MARK: - removeAt(index:count:keepCapacity:) tests
    func testRemoveAt_whenCountIsZero_doesntRemoveElementsAndReturnsEmptyArray() {
        whenFull()
        let expectedCount = sut.count
        let containedElements = containedElementsWhenFull()
        
        for idx in 0..<sut.count {
            XCTAssertEqual(sut.removeAt(index: idx, count: 0), [])
            XCTAssertEqual(sut.count, expectedCount)
            for i in 0..<sut.count {
                XCTAssertEqual(sut[i], containedElements[i])
            }
        }
    }
    
    func testRemoveAt_whenCountIsOne_removesAndReturnsElementAtIdxAndDecreasesCountByOne() {
        whenFull()
        let prevCount = sut.count
        let containedElements = containedElementsWhenFull()
        for idx in 0..<4 {
            XCTAssertEqual(sut.removeAt(index: idx, count: 1), [containedElements[idx]])
            XCTAssertEqual(sut.count, prevCount - 1)
            
            // restore SUT state to full on each iteration
            whenFull()
        }
    }
    
    func testRemoveAt_whenCountMoreThanOneAndLessThanCount_removesAndReturnsTheElementAtIndexAndElementsAfterAndDecreasesCount() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        for idx in 0..<sut.count {
            let prevCount = sut.count
            let k = sut.count - idx
            let expectedRemoved = Array(containedElements[idx..<(idx + k)])
            var expectedRemaining = containedElements
            expectedRemaining.removeSubrange(idx..<(idx + k))
            XCTAssertEqual(sut.removeAt(index: idx, count: k), expectedRemoved)
            XCTAssertEqual(sut.count, prevCount - k)
            XCTAssertEqual(sut.count, expectedRemaining.count)
            for i in 0..<sut.count {
                XCTAssertEqual(sut[i], expectedRemaining[i])
            }
            
            // restore SUT state to full on each iteration
            whenFull()
        }
    }
    
    func testRemoveAt_whenCountIsZeroAndKeepCapacityIsFalseAndCapacityCantBeReducedAnyFurther_doesntReduceCapacity() {
        whenFull()
        XCTAssert(sut.isFull)
        var expectedCapacity = sut.capacity
        
        for idx in 0..<sut.count {
            sut.removeAt(index: idx, count: 0, keepCapacity: false)
            XCTAssertEqual(sut.count, expectedCapacity)
        }
        
        sut.append(5)
        expectedCapacity = sut.capacity
        
        for idx in 0..<sut.count {
            sut.removeAt(index: idx, count: 0, keepCapacity: false)
            XCTAssertEqual(sut.capacity, expectedCapacity)
        }
    }
    
    func testRemoveAt_whenCountIsZeroAndKeepCapacityIsFalse_reducesCapacityWhenPossible() {
        whenFull()
        let expectedCapacity = sut.capacity
        sut.reserveCapacity(5)
        XCTAssertGreaterThan(sut.capacity, expectedCapacity)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        for idx in 0..<sut.count {
            sut.removeAt(index: idx, count: 0, keepCapacity: false)
            XCTAssertEqual(sut.capacity, expectedCapacity)
        }
    }
    
    // MARK: - removeAll(keepCapacity:) tests
    func testRemoveAll_whenEmpty_thenReturnsEmptyArrayAndKeepsOrReducesCapacityAccordingly() {
        sut.reserveCapacity(10)
        let prevCapacity = sut.capacity
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.removeAll(keepCapacity: true), [])
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        sut.removeAll(keepCapacity: false)
        XCTAssertLessThan(sut.capacity, prevCapacity)
    }
    
    func testRemoveAll_whenNotEmpty_thenReturnsContainedElementsAndKeepsOrReducesCapacityAccordingly() {
        let expectedResult = Array(1...24)
        sut = CircularBuffer(elements: expectedResult)
        var prevCapacity = sut.capacity
        XCTAssertEqual(sut.removeAll(keepCapacity: true), expectedResult)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        sut = CircularBuffer(elements: expectedResult)
        prevCapacity = sut.capacity
        sut.removeAll(keepCapacity: false)
        XCTAssertLessThan(sut.capacity, prevCapacity)
    }
    */
}
