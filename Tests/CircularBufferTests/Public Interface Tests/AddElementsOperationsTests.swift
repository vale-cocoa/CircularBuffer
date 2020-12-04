//
//  AddElementsOperationsTests.swift
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

final class AddElementsOperationsTests: XCTestCase {
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
    // MARK: - append(_:) tests
    func testAppend_countIncreasesByOne() {
        let prevCount = sut.count
        sut.append(10)
        XCTAssertEqual(sut.count, prevCount + 1)
    }
    
    func testAppend_newElementBecomesLast() {
        let prevLast = sut.last
        sut.append(10)
        XCTAssertNotEqual(sut.last, prevLast)
        XCTAssertEqual(sut.last, 10)
    }
    
    func testAppend_whenFull_capacityGrows() {
        whenFull()
        let prevCapacity = sut.capacity
        sut.append(10)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
    }
    
    // MARK: - append(contentsOf:) tests
    func testAppendContentsOf() {
        let newElements = AnySequence<Int>([])
        sut.append(contentsOf: newElements)
        XCTAssertTrue(sut.isEmpty)
        
        let newElements1 = AnySequence<Int>(1...4)
        sut.append(contentsOf: newElements1)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.first, 1)
        XCTAssertEqual(sut.last, 4)
        for i in 0..<4 {
            XCTAssertEqual(sut[i], i + 1)
        }
        
        let newElements2 = AnySequence<Int>(5...8)
        sut.append(contentsOf: newElements2)
        XCTAssertEqual(sut.count, 8)
        XCTAssertEqual(sut.first, 1)
        XCTAssertEqual(sut.last, 8)
        for i in 0..<8 {
            XCTAssertEqual(sut[i], i + 1)
        }
        
        let newElements3 = SequenceImplementingWithContiguousStorage(base: [9, 10, 11, 12])
        sut.append(contentsOf: newElements3)
        XCTAssertEqual(sut.count, 12)
        XCTAssertEqual(sut.first, 1)
        XCTAssertEqual(sut.last, 12)
        for i in 0..<12 {
            XCTAssertEqual(sut[i], i + 1)
        }
        
        let empty1 = AnySequence<Int>([])
        sut.append(contentsOf: empty1)
        XCTAssertEqual(sut.count, 12)
        XCTAssertEqual(sut.first, 1)
        XCTAssertEqual(sut.last, 12)
        for i in 0..<12 {
            XCTAssertEqual(sut[i], i + 1)
        }
        
        let empty2 = SequenceImplementingWithContiguousStorage(base: [])
        sut.append(contentsOf: empty2)
        XCTAssertEqual(sut.count, 12)
        XCTAssertEqual(sut.first, 1)
        XCTAssertEqual(sut.last, 12)
        for i in 0..<12 {
            XCTAssertEqual(sut[i], i + 1)
        }
    }
    
    // MARK: - push(_:) tests
    func testPush_countIncreasesByOne() {
        let prevCount = sut.count
        sut.push(10)
        XCTAssertEqual(sut.count, prevCount + 1)
    }
    
    func testPush_newElementBecomesFirst() {
        let prevFirst = sut.first
        sut.append(10)
        XCTAssertNotEqual(sut.first, prevFirst)
        XCTAssertEqual(sut.first, 10)
    }
    
    func testPush_whenFull_capacityGrows() {
        whenFull()
        let prevCapacity = sut.capacity
        sut.push(10)
        XCTAssertGreaterThan(sut.count, prevCapacity)
    }
    
    // MARK: - push(contentsOf:) tests
    func testPushContentsOf() {
        let newElements = AnySequence<Int>([])
        sut.push(contentsOf: newElements)
        XCTAssertTrue(sut.isEmpty)
        
        let newElements1 = AnySequence<Int>(1...4)
        sut.push(contentsOf: newElements1)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.first, 4)
        XCTAssertEqual(sut.last, 1)
        for i in 0..<4 {
            XCTAssertEqual(sut[i], 4 - i)
        }
        
        let newElements2 = AnySequence<Int>(5...8)
        sut.push(contentsOf: newElements2)
        XCTAssertEqual(sut.count, 8)
        XCTAssertEqual(sut.first, 8)
        XCTAssertEqual(sut.last, 1)
        for i in 0..<8 {
            XCTAssertEqual(sut[i], (8 - i))
        }
        
        let newElements3 = SequenceImplementingWithContiguousStorage(base: [9, 10, 11, 12])
        sut.push(contentsOf: newElements3)
        XCTAssertEqual(sut.count, 12)
        XCTAssertEqual(sut.first, 12)
        XCTAssertEqual(sut.last, 1)
        for i in 0..<8 {
            XCTAssertEqual(sut[i], (12 - i))
        }
        
        let empty1 = AnySequence<Int>([])
        sut.push(contentsOf: empty1)
        XCTAssertEqual(sut.count, 12)
        XCTAssertEqual(sut.first, 12)
        XCTAssertEqual(sut.last, 1)
        for i in 0..<8 {
            XCTAssertEqual(sut[i], (12 - i))
        }
        
        let empty2 = SequenceImplementingWithContiguousStorage(base: [])
        sut.push(contentsOf: empty2)
        XCTAssertEqual(sut.count, 12)
        XCTAssertEqual(sut.first, 12)
        XCTAssertEqual(sut.last, 1)
        for i in 0..<8 {
            XCTAssertEqual(sut[i], (12 - i))
        }
    }
    
    // MARK: - prepend(contentsOf:) tests
    func testPrependContentsOf_whenNewElementsIsEmpty_doesNothing() {
        sut.prepend(contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        
        whenFull()
        let containedElements = containedElementsWhenFull()
        sut.prepend(contentsOf: [])
        XCTAssertEqual(sut.count, containedElements.count)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func testPrependContentsOf_whenNewElementsCountIsGreaterThanZero_increasesCountByNewElementsCount() {
        var prevCount = sut.count
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
        
        whenFull()
        prevCount = sut.count
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
    }
    
    func testPrependContentsOf_whenNewElementsIsNotEmpty_newElementsGetPrepended() {
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.prepend(contentsOf: newElements)
        var result = [Int]()
        for i in 0..<sut.count {
            result.append(sut[i])
        }
        XCTAssertEqual(result, newElements)
        
        whenFull()
        let previousElements = containedElementsWhenFull()
        sut.prepend(contentsOf: newElements)
        result = sutContainedElements()
        XCTAssertEqual(result, newElements + previousElements)
    }
    
    func testPrependContentsOf_whenLeftCapacityIsSufficientToStoreNewElements() {
        whenFull()
        sut.append(5)
        sut.append(6)
        sut.append(7)
        sut.append(8)
        sut.append(9)
        let newElements = [10, 11, 12, 13, 14, 15, 16]
        XCTAssertGreaterThanOrEqual(sut.capacity - (sut.count + newElements.count), 0)
        let prevElements = containedElementsWhenFull() + [5, 6, 7, 8, 9]
        
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevElements.count + newElements.count)
        var result = sutContainedElements()
        XCTAssertEqual(result, newElements + prevElements)
        
        // test for appending in splits
        let copy = sut.copy()
        for _ in 0..<newElements.count {
            copy.popFirst()
        }
        XCTAssertGreaterThan(copy.head, 0)
        XCTAssertEqual(copy.head, newElements.count)
        copy.prepend(contentsOf: newElements)
        XCTAssertEqual(copy.count, prevElements.count + newElements.count)
        result.removeAll()
        copy.forEach { result.append($0) }
        XCTAssertEqual(result, newElements + prevElements)
    }
    
    // MARK: - append<C: Collection>(contentsOf:) tests
    func testAppendContentsOf_whenNewElementsIsEmpty_doesNothing() {
        sut.append(contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        
        whenFull()
        let containedElements = containedElementsWhenFull()
        sut.append(contentsOf: [])
        XCTAssertEqual(sut.count, containedElements.count)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func testAppendContentsOf_whenNewElementsCountIsGreaterThanZero_increasesCountByNewElementsCount() {
        var prevCount = sut.count
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
        
        whenFull()
        prevCount = sut.count
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
    }
    
    func testAppendContentsOf_whenNewElementsIsNotEmpty_newElementsGetAppended() {
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.append(contentsOf: newElements)
        var result = [Int]()
        for i in 0..<sut.count {
            result.append(sut[i])
        }
        XCTAssertEqual(result, newElements)
        
        whenFull()
        let previousElements = containedElementsWhenFull()
        sut.append(contentsOf: newElements)
        result = sutContainedElements()
        XCTAssertEqual(result, previousElements + newElements)
    }
    
    func testAppendContentsOf_whenLeftCapacityIsSufficientToStoreNewElements() {
        whenLeftCapacityIsSeven()
        let newElements = [10, 11, 12, 13, 14, 15, 16]
        XCTAssertGreaterThanOrEqual(sut.capacity - (sut.count + newElements.count), 0)
        let prevElements = containedElementsWhenLeftCapacityIsSeven()
        
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevElements.count + newElements.count)
        var result = sutContainedElements()
        XCTAssertEqual(result, prevElements + newElements)
        
        // Test for appending in splits
        let copy = sut.copy()
        for _ in 0..<newElements.count - 2 {
            copy.popLast()
        }
        copy.popFirst()
        copy.popFirst()
        XCTAssertEqual(copy.count, prevElements.count)
        for i in 0..<prevElements.count {
            copy[i] = prevElements[i]
        }
        XCTAssertGreaterThan(copy.tail + newElements.count, copy.capacity)
        XCTAssertGreaterThanOrEqual(copy.capacity, copy.count + newElements.count)
        
        copy.append(contentsOf:newElements)
        result.removeAll()
        copy.forEach({ result.append($0) })
        XCTAssertEqual(result, prevElements + newElements)
    }
    
    // MARK: - insertAt(index:ContentsOf:)
    func testInsertAt_whenNewElementsIsEmpty_doesNothing() {
        XCTAssertEqual(sut.count, 0)
        sut.insertAt(index: sut.count, contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        
        whenFull()
        let containedElements = containedElementsWhenFull()
        for i in 0...sut.count {
            sut.insertAt(index: i, contentsOf: [])
            XCTAssertEqual(sut.count, containedElements.count)
            for j in 0..<sut.count {
                XCTAssertEqual(sut[j], containedElements[j])
            }
            // restore SUT state for next iteration:
            whenFull()
        }
    }
    
    func test_insertAt_whenNewElementsCountIsGreaterThanZero_increasesCountByNewElementsCount() {
        var prevCount = sut.count
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.insertAt(index: 0, contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
        
        whenFull()
        for i in 0...sut.count {
            prevCount = sut.count
            sut.insertAt(index: i, contentsOf: newElements)
            XCTAssertEqual(sut.count, prevCount + newElements.count)
            
            // restore SUT state for next iteration:
            whenFull()
        }
    }
    
    func testInsertAt__whenNewElementsIsNotEmpty_newElementsGetAppended() {
        XCTAssertEqual(sut.count, 0)
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.insertAt(index: sut.count, contentsOf: newElements)
        var result = sutContainedElements()
        XCTAssertEqual(result, newElements)
        
        whenFull()
        let previousElements = containedElementsWhenFull()
        for i in 0...sut.count {
            sut.insertAt(index: i, contentsOf: newElements)
            result = sutContainedElements()
            let expectedResult = Array(previousElements[0..<i] + newElements + Array(previousElements[i..<previousElements.endIndex]))
            XCTAssertEqual(result, expectedResult)
            
            // restore SUT state for next iteration:
            whenFull()
        }
    }
    
    func testInsertAt_whenLeftCapacityIsSufficientToStoreNewElements() {
        whenLeftCapacityIsSeven()
        let newElements = [10, 11, 12, 13, 14, 15, 16]
        XCTAssertGreaterThanOrEqual(sut.capacity - (sut.count + newElements.count), 0)
        let prevElements = containedElementsWhenLeftCapacityIsSeven()
        
        var result = [Int]()
        for i in 0...sut.count {
            sut.insertAt(index: i, contentsOf: newElements)
            XCTAssertEqual(sut.count, prevElements.count + newElements.count)
            result = sutContainedElements()
            let expectedResult = Array(prevElements[0..<i]) + newElements + Array(prevElements[i..<prevElements.endIndex])
            XCTAssertEqual(result, expectedResult)
            XCTAssertTrue(sut.isFull)
            XCTAssertEqual(sut[sut.count - 1], sut.last, "Iteration: \(i)")
            
            // restore SUT state for next iteration:
            whenLeftCapacityIsSeven()
            // restore result:
            result.removeAll()
        }
        
        // Test for appending in splits
        let copy = sut.copy()
        copy.append(contentsOf: newElements)
        for _ in 0..<newElements.count - 2 {
            copy.popLast()
        }
        copy.popFirst()
        copy.popFirst()
        XCTAssertEqual(copy.count, prevElements.count)
        for i in 0..<prevElements.count {
            copy[i] = prevElements[i]
        }
        XCTAssertGreaterThan(copy.tail + newElements.count, copy.capacity)
        XCTAssertGreaterThanOrEqual(copy.capacity, copy.count + newElements.count)
        
        copy.insertAt(index: 2, contentsOf: newElements)
        result.removeAll()
        copy.forEach { result.append($0) }
        let expectedResult = Array(prevElements[0..<2] + newElements + Array(prevElements[2..<prevElements.endIndex]))
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(sut[sut.count - 1], sut.last)
    }
    */
}
