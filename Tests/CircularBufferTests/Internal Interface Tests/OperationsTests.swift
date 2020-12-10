//
//  OperationsTests.swift
//  CircularBufferTests
//
//  Created by Valeriano Della Longa on 2020/12/10.
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

import XCTest
@testable import CircularBuffer

final class OperationsTests: XCTestCase {
    var sut: CircularBuffer<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularBuffer<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - append(contentsOf:usingSmartCapacity:)
    func testAppendContentsOf_whenNewElementsIsEmpty() {
        // elements won't change
        let storedElements = (1...10).shuffled()
        sut = CircularBuffer(elements: storedElements)
        sut.append(contentsOf: [])
        XCTAssertEqual(sut.allStoredElements, storedElements)
        
        // capacity decreases when needed:
        sut.reserveCapacity(64)
        var prevCapacity = sut.capacity
        sut.append(contentsOf: [], usingSmartCapacityPolicy: true)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        prevCapacity = sut.capacity
        
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        sut.append(contentsOf: [], usingSmartCapacityPolicy: false)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, sut.count)
    }
    
    func testAppendContentsOf_whenNewElementsIsNotEmpty() {
        let newElements = (1...10).map { $0 + 1 }
        let capacityForNewElements = CircularBuffer<Int>.smartCapacityFor(count: newElements.count)
        // when sut is empty:
        for headShift in 0..<capacityForNewElements {
            sut = CircularBuffer(capacity: capacityForNewElements, usingSmartCapacityPolicy: true)
            sut.head = headShift
            sut.tail = headShift
            sut.append(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, newElements)
        }
        
        // when sut is not empty:
        let storedElements = (1...10).shuffled()
        let capacityForStoredElements = CircularBuffer<Int>.smartCapacityFor(count: storedElements.count)
        for headShift in 0..<capacityForStoredElements {
            sut = CircularBuffer(capacity: capacityForStoredElements, usingSmartCapacityPolicy: true)
            sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
            sut.count = storedElements.count
            sut.head = headShift
            sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
            sut.append(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, storedElements + newElements)
        }
    }
    
    func testAppendContentsOf_whenResidualCapacityIsEnough() {
        sut = CircularBuffer(elements: 1...10)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        let newElements = (1...sut.residualCapacity).map { $0 + 1 }
        let prevBaseAddress = sut.elements
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.elements, prevBaseAddress)
    }
    
    func testAppendContentsOf_whenResidualCapacityIsNotEnough() {
        sut = CircularBuffer(elements: 1...10)
        var newElements = (1...sut.residualCapacity + 1).map { $0 + 1 }
        XCTAssertGreaterThan(newElements.count, sut.residualCapacity)
        var prevBaseAddress = sut.elements
        sut.append(contentsOf: newElements, usingSmartCapacityPolicy: true)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        newElements = (1...sut.residualCapacity + 1).map { $0 * 10 }
        prevBaseAddress = sut.elements
        sut.append(contentsOf: newElements, usingSmartCapacityPolicy: false)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.residualCapacity, 0)
    }
    
    // MARK: prepend(contentsOf:usingSmartCapacity:) tests
    func testPrependContentsOf_whenNewElementsIsEmpty() {
        // elements won't change
        let storedElements = (1...10).shuffled()
        sut = CircularBuffer(elements: storedElements)
        sut.prepend(contentsOf: [])
        XCTAssertEqual(sut.allStoredElements, storedElements)
        
        // capacity decreases when needed:
        sut.reserveCapacity(64)
        var prevCapacity = sut.capacity
        sut.prepend(contentsOf: [], usingSmartCapacityPolicy: true)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        prevCapacity = sut.capacity
        
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        sut.prepend(contentsOf: [], usingSmartCapacityPolicy: false)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, sut.count)
    }
    
    func testPrependContentsOf_whenNewElementsIsNotEmpty() {
        let newElements = (1...10).map { $0 + 1 }
        let capacityForNewElements = CircularBuffer<Int>.smartCapacityFor(count: newElements.count)
        // when sut is empty:
        for headShift in 0..<capacityForNewElements {
            sut = CircularBuffer(capacity: capacityForNewElements, usingSmartCapacityPolicy: true)
            sut.head = headShift
            sut.tail = headShift
            sut.prepend(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, newElements)
        }
        
        // when sut is not empty:
        let storedElements = (1...10).shuffled()
        let capacityForStoredElements = CircularBuffer<Int>.smartCapacityFor(count: storedElements.count)
        for headShift in 0..<capacityForStoredElements {
            sut = CircularBuffer(capacity: capacityForStoredElements, usingSmartCapacityPolicy: true)
            sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
            sut.count = storedElements.count
            sut.head = headShift
            sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
            sut.prepend(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, newElements + storedElements)
        }
    }
    
    func testPrependContentsOf_whenResidualCapacityIsEnough() {
        sut = CircularBuffer(elements: 1...10)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        let newElements = (1...sut.residualCapacity).map { $0 + 1 }
        let prevBaseAddress = sut.elements
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.elements, prevBaseAddress)
    }
    
    func testPrependContentsOf_whenResidualCapacityIsNotEnough() {
        sut = CircularBuffer(elements: 1...10)
        var newElements = (1...sut.residualCapacity + 1).map { $0 + 1 }
        XCTAssertGreaterThan(newElements.count, sut.residualCapacity)
        var prevBaseAddress = sut.elements
        sut.prepend(contentsOf: newElements, usingSmartCapacityPolicy: true)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        newElements = (1...sut.residualCapacity + 1).map { $0 * 10 }
        prevBaseAddress = sut.elements
        sut.prepend(contentsOf: newElements, usingSmartCapacityPolicy: false)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.residualCapacity, 0)
    }
    
    // MARK: - Buffer inplace operations
    func testFastInplaceInsertAt() {
        let storedElements = (1...10).shuffled()
        let capacity = 16
        let insertedElements = (1...6).map { $0 + 10 }
        for headShift in 0..<capacity {
            for idx in 0...storedElements.count {
                sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
                sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
                sut.count = storedElements.count
                sut.head = headShift
                sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
                
                let prevBuffer = sut.elements
                sut.fastInplaceInsert([], at: idx)
                XCTAssertEqual(sut.allStoredElements, storedElements)
                XCTAssertEqual(sut.elements, prevBuffer)
                
                sut.fastInplaceInsert(insertedElements, at: idx)
                var expectedResult = storedElements
                expectedResult.insert(contentsOf: insertedElements, at: idx)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                XCTAssertEqual(sut.elements, prevBuffer)
            }
        }
    }
    
    func testFastInplacePrepend() {
        let storedElements = (1...10).shuffled()
        let capacity = 16
        let prependedElements = (1...6).map { $0 + 10 }
        for headShift in 0..<capacity {
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
            sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
            sut.count = storedElements.count
            sut.head = headShift
            sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
            
            let prevBuffer = sut.elements
            sut.fastInplacePrepend([])
            XCTAssertEqual(sut.allStoredElements, storedElements)
            XCTAssertEqual(sut.elements, prevBuffer)
            
            sut.fastInplacePrepend(prependedElements)
            XCTAssertEqual(sut.allStoredElements, prependedElements + storedElements)
            XCTAssertEqual(sut.elements, prevBuffer)
        }
    }
    
    func testFastInplaceAppend() {
        let storedElements = (1...10).shuffled()
        let capacity = 16
        let appendedElements = (1...6).map { $0 + 10 }
        for headShift in 0..<capacity {
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
            sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
            sut.count = storedElements.count
            sut.head = headShift
            sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
            
            let prevBuffer = sut.elements
            sut.fastInplaceAppend([])
            XCTAssertEqual(sut.allStoredElements, storedElements)
            XCTAssertEqual(sut.elements, prevBuffer)
            
            sut.fastInplaceAppend(appendedElements)
            XCTAssertEqual(sut.allStoredElements, storedElements + appendedElements, "headShift: \(headShift)")
            XCTAssertEqual(sut.elements, prevBuffer)
        }
    }
    
    
    func testFastInplaceRemoveFirstElements() {
        let storedElements = (1...10).shuffled()
        let capacity = 16
        for headShift in 0..<capacity {
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
            sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
            sut.count = storedElements.count
            sut.head = headShift
            sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
            
            let prevBuffer = sut.elements
            XCTAssertEqual(sut.fastInplaceRemoveFirstElements(0), [])
            XCTAssertEqual(sut.allStoredElements, storedElements)
            XCTAssertEqual(sut.elements, prevBuffer)
            
            let k = Int.random(in: 1...storedElements.count)
            let expectedRemovedResult = Array(storedElements[storedElements.startIndex..<k])
            let expectedRemainingElements = Array(storedElements[k..<storedElements.endIndex])
            XCTAssertEqual(sut.fastInplaceRemoveFirstElements(k), expectedRemovedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertEqual(sut.elements, prevBuffer)
        }
    }
    
    
    func testFastInplaceRemoveLastElements() {
        let storedElements = (1...10).shuffled()
        let capacity = 16
        for headShift in 0..<capacity {
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
            sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
            sut.count = storedElements.count
            sut.head = headShift
            sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
            
            let prevBuffer = sut.elements
            XCTAssertEqual(sut.fastInplaceRemoveLastElements(0), [])
            XCTAssertEqual(sut.allStoredElements, storedElements)
            XCTAssertEqual(sut.elements, prevBuffer)
            
            let k = Int.random(in: 1...storedElements.count)
            let expectedRemovedResult = Array(storedElements[(storedElements.endIndex - k)..<storedElements.endIndex])
            let expectedRemainingElements = Array(storedElements[storedElements.startIndex..<(storedElements.endIndex - k)])
            XCTAssertEqual(sut.fastInplaceRemoveLastElements(k), expectedRemovedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertEqual(sut.elements, prevBuffer)
        }
    }
    
    func testFastInplaceRemoveElementsAt() {
        let storedElements = (1...10).shuffled()
        let capacity = 16
        for headShift in 0..<capacity {
            for idx in 0..<storedElements.endIndex {
                sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
                sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
                sut.count = storedElements.count
                sut.head = headShift
                sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
                
                let prevBuffer = sut.elements
                XCTAssertEqual(sut.fastInplaceRemoveElements(at: idx, count: 0), [])
                XCTAssertEqual(sut.allStoredElements, storedElements)
                XCTAssertEqual(sut.elements, prevBuffer)
                
                let k = Int.random(in: 1...(storedElements.endIndex - idx))
                var expectedRemainingElements = storedElements
                expectedRemainingElements.removeSubrange(idx..<(idx + k))
                XCTAssertEqual(sut.removeAt(index: idx, count: k), Array(storedElements[idx..<(idx + k)]))
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.elements, prevBuffer)
            }
            
        }
    }
    
    func testFastInplaceReplaceElements() {
        let storedElements = (1...10).shuffled()
        let capacity = 16
        for headShift in 0..<capacity {
            for lowerBound in storedElements.startIndex...storedElements.endIndex {
                for upperBound in lowerBound...storedElements.endIndex {
                    let subrange = lowerBound..<upperBound
                    sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
                    sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
                    sut.count = storedElements.count
                    sut.head = headShift
                    sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
                    
                    // newElements is empty:
                    var prevBaseAddress = sut.elements
                    sut.fastInplaceReplaceElements(subrange: subrange, with: [])
                    var expectedResult = storedElements
                    expectedResult.replaceSubrange(subrange, with: [])
                    XCTAssertEqual(sut.allStoredElements, expectedResult)
                    XCTAssertEqual(sut.elements, prevBaseAddress)
                    
                    // newElements.count < subrange.count:
                    sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
                    sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
                    sut.count = storedElements.count
                    sut.head = headShift
                    sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
                    prevBaseAddress = sut.elements
                    
                    var newElements = storedElements[subrange].map { $0 * 10 }
                    let _ = newElements.popLast()
                    expectedResult = storedElements
                    expectedResult.replaceSubrange(subrange, with: newElements)
                    sut.fastInplaceReplaceElements(subrange: subrange, with: newElements)
                    XCTAssertEqual(sut.allStoredElements, expectedResult)
                    XCTAssertEqual(sut.elements, prevBaseAddress)
                    
                    // newElements.count == subrange.count:
                    sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
                    sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
                    sut.count = storedElements.count
                    sut.head = headShift
                    sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
                    prevBaseAddress = sut.elements
                    
                    newElements = storedElements[subrange].map { $0 * 10 }
                    expectedResult = storedElements
                    expectedResult.replaceSubrange(subrange, with: newElements)
                    sut.fastInplaceReplaceElements(subrange: subrange, with: newElements)
                    XCTAssertEqual(sut.allStoredElements, expectedResult)
                    XCTAssertEqual(sut.elements, prevBaseAddress)
                    
                    // newElements.count > subrange.count, won't overflow capacity:
                    sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: true)
                    sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: storedElements)
                    sut.count = storedElements.count
                    sut.head = headShift
                    sut.tail = sut.bufferIndex(from: headShift, offsetBy: storedElements.count)
                    prevBaseAddress = sut.elements
                    
                    newElements = storedElements[subrange].map { $0 * 10 }
                    for i in 0..<sut.residualCapacity {
                        newElements.append(i + 1000)
                    }
                    XCTAssertEqual(sut.count - subrange.count + newElements.count, sut.capacity)
                    expectedResult = storedElements
                    expectedResult.replaceSubrange(subrange, with: newElements)
                    sut.fastInplaceReplaceElements(subrange: subrange, with: newElements)
                    XCTAssertEqual(sut.allStoredElements, expectedResult)
                    XCTAssertEqual(sut.elements, prevBaseAddress)
                }
            }
        }
    }
    
}
