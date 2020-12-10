//
//  ElementsOperationsTests.swift
//  CircularBufferTests
//
//  Created by Valeriano Della Longa on 2020/12/08.
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

final class ElementsOperationsTests: XCTestCase {
    var sut: CircularBuffer<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularBuffer<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - smartCapacityFor(count:) tests
    func testSmartCapacityFor() {
        // When specified count is 0:
        XCTAssertEqual(CircularBuffer<Int>.smartCapacityFor(count: 0), minSmartCapacity)
        
        // when specified value is in range ((Int.max >> 1) + 1)...Int.max:
        XCTAssertEqual(CircularBuffer<Int>.smartCapacityFor(count: (Int.max >> 1) + 1), Int.max)
        XCTAssertEqual(CircularBuffer<Int>.smartCapacityFor(count: Int.max - 1), Int.max)
        XCTAssertEqual(CircularBuffer<Int>.smartCapacityFor(count: Int.max), Int.max)
        
        // when specified value is smaller than or equal to minSmartCapacity:
        for k in 1...minSmartCapacity {
            XCTAssertEqual(CircularBuffer<Int>.smartCapacityFor(count: k), minSmartCapacity)
        }
        
        // when specified value is greater than minSmartCapacity:
        let randomBitShift = Int.random(in: 2...16)
        let expectedResult = minSmartCapacity << randomBitShift
        for k in ((expectedResult >> 1) + 1)...expectedResult {
            XCTAssertEqual(CircularBuffer<Int>.smartCapacityFor(count: k), expectedResult)
        }
        XCTAssertEqual(CircularBuffer<Int>.smartCapacityFor(count: expectedResult + 1), expectedResult << 1)
    }
    
    // MARK: - growToNextSmartCapacityLevel() tests
    func testGrowToNextSmartCapacityLevel() {
        var prevCapacity = sut.capacity
        sut.growToNextSmartCapacityLevel()
        XCTAssertEqual(sut.capacity, prevCapacity << 1)
        
        prevCapacity = sut.capacity
        sut.growToNextSmartCapacityLevel()
        XCTAssertEqual(sut.capacity, prevCapacity << 1)
        sut = CircularBuffer(elements: 1...10, usingSmartCapacityPolicy: false)
        let expectedResult = CircularBuffer<Int>.smartCapacityFor(count: sut.count) << 1
        sut.growToNextSmartCapacityLevel()
        XCTAssertEqual(sut.capacity, expectedResult)
    }
    
    // MARK: - capacityFor(newCount:) tests
    func testCapacityFor_whenNewCountIsZero() {
        // when keepCapacity == true, result is actual capacity:
        var expectedResult = sut.capacity
        XCTAssertEqual(sut.capacityFor(newCount: 0, keepCapacity: true), expectedResult)
        
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: true)
        expectedResult = sut.capacity
        XCTAssertEqual(sut.capacityFor(newCount: 0, keepCapacity: true), expectedResult)
        
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        expectedResult = sut.capacity
        XCTAssertEqual(sut.capacityFor(newCount: 0, keepCapacity: true, usingSmartCapacityPolicy: false), expectedResult)
        
        // when keepCapacity == false and usingSmartCapacityPolicy == true, then
        // returns minSmartCapacity value:
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: true)
        expectedResult = CircularBuffer<Int>.minSmartCapacity
        XCTAssertEqual(sut.capacityFor(newCount: 0, keepCapacity: false, usingSmartCapacityPolicy: true), expectedResult)
        
        // when keepCapacity == false and usingSmartCapacityPolicy == false, then
        // returns 0:
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: true)
        expectedResult = 0
        XCTAssertEqual(sut.capacityFor(newCount: 0, keepCapacity: false, usingSmartCapacityPolicy: false), expectedResult)
    }
    
    func testCapacityFor_whenNewCountIsGreaterThanOrEqualToActualCapacity() {
        // keepCapacity parameter value doesn't take effect:
        let prevCapacity = sut.capacity
        let newCount = prevCapacity + 1
        XCTAssertGreaterThan(sut.capacityFor(newCount: newCount, keepCapacity: true), prevCapacity)
        XCTAssertGreaterThan(sut.capacityFor(newCount: newCount, keepCapacity: false), prevCapacity)
        XCTAssertEqual(sut.capacityFor(newCount: prevCapacity, keepCapacity: true), prevCapacity)
        XCTAssertEqual(sut.capacityFor(newCount: prevCapacity, keepCapacity: false), prevCapacity)
        
        // when usingSmartCapacityPolicy == true, returns the same value
        // as doing smartCapacityValueFor(count: newCount):
        var expectedResult = CircularBuffer<Int>.smartCapacityFor(count: newCount)
        XCTAssertEqual(sut.capacityFor(newCount: newCount, usingSmartCapacityPolicy: true), expectedResult)
        
        // when usingSmartCapacityPolicy == false, returns same value of newCount:
        expectedResult = newCount
        XCTAssertEqual(sut.capacityFor(newCount: newCount, usingSmartCapacityPolicy: false), expectedResult)
    }
    
    func testCapacityFor_whenNewCountIsLessThanActualCapacity() {
        // when keepCapacity == true, then it'll return actual capacity:
        sut = CircularBuffer(capacity: 16, usingSmartCapacityPolicy: true)
        var prevCapacity = sut.capacity
        var newCount = prevCapacity - 8
        XCTAssertEqual(sut.capacityFor(newCount: newCount, keepCapacity: true, usingSmartCapacityPolicy: true), prevCapacity)
        XCTAssertEqual(sut.capacityFor(newCount: newCount, keepCapacity: true, usingSmartCapacityPolicy: false), prevCapacity)
        
        // when keepCapacity == false and usingSmartCapacityPolicy == false, it'll
        // return newCount value:
        XCTAssertEqual(sut.capacityFor(newCount: newCount, keepCapacity: false, usingSmartCapacityPolicy: false), newCount)
        
        // when keepCapacity == false and usingSmartCapacity == true, it'll return
        // a reduced capacity value if the reduction of capacity is enough to hold
        // newCount and it's value is two smart capacity levels under:
        sut = CircularBuffer(capacity: 32, usingSmartCapacityPolicy: true)
        prevCapacity = sut.capacity
        newCount = CircularBuffer<Int>.smartCapacityFor(count: ((prevCapacity >> 2) - 1))
        XCTAssertEqual(sut.capacityFor(newCount: newCount, keepCapacity: false, usingSmartCapacityPolicy: true), CircularBuffer<Int>.smartCapacityFor(count: newCount))
        
        // …Otherwise it'll return the smart capacity level for current capacity:
        newCount = CircularBuffer<Int>.smartCapacityFor(count: (prevCapacity >> 1) + 1)
        XCTAssertEqual(sut.capacityFor(newCount: newCount, keepCapacity: false, usingSmartCapacityPolicy: true), CircularBuffer<Int>.smartCapacityFor(count: sut.capacity))
    }
    
    // MARK: - reduceCapacityForCurrentCount() tests
    func testReduceCapacityForCurrentCount_whenIsEmptyIsTrue() {
        // when usingSmartCapacityPolicy == true and capacity > minSmartCapacityPolicy,
        // then reduces capacity to minSmartCapacityValue
        sut = CircularBuffer(capacity: minSmartCapacity + 1, usingSmartCapacityPolicy: true)
        var prevBaseAddress = sut.elements
        XCTAssertTrue(sut.isEmpty)
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: true)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.capacity, minSmartCapacity)
        
        // when usingSmartCapacityPolicy == true and capacity == minSmartCapacity,
        // then does nothing:
        prevBaseAddress = sut.elements
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: true)
        XCTAssertEqual(sut.elements, prevBaseAddress)
        
        // when usingSmartCapacityPolicy == false and capacity > 0,
        // then reduces capacity to zero:
        XCTAssertGreaterThan(sut.capacity, 0)
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: false)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.capacity, 0)
        
        // when usingSmartCapacityPolicy == false and capacity == 0,
        // then does nothing:
        prevBaseAddress = sut.elements
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: false)
        XCTAssertEqual(sut.elements, prevBaseAddress)
    }
    
    func testReduceCapacityForCurrentCount_whenIsNotEmpty() {
        let storedElements = (1...10).shuffled()
        
        // when usingSmartCapacity == false and capacity > count,
        // then reduces capacity to count:
        sut = CircularBuffer(elements: storedElements)
        XCTAssertGreaterThan(sut.capacity, sut.count)
        var prevBaseAddress = sut.elements
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: false)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.allStoredElements, storedElements)
        XCTAssertEqual(sut.capacity, sut.count)
        
        // when usingSmartCapacity == false and capacity == count,
        // then does nothing:
        prevBaseAddress = sut.elements
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: false)
        XCTAssertEqual(sut.elements, prevBaseAddress)
        
        // when usingSmartCapacity == true and smart capacity for current count would be
        // two or more levels lower than actual capacity, then it reduces capacity:
        sut = CircularBuffer(elements: storedElements)
        sut.reserveCapacity(sut.capacity << 2)
        prevBaseAddress = sut.elements
        var prevCapacity = sut.capacity
        XCTAssertGreaterThanOrEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count) << 2)
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: true)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count))
        XCTAssertEqual(sut.allStoredElements, storedElements)
        
        // when usingSmartCapacity == true and smart capacity for current count would be
        // just one level lower than actual capacity, then it does nothing:
        sut.reserveCapacity(8, usingSmartCapacityPolicy: true)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count) << 1)
        prevCapacity = sut.capacity
        prevBaseAddress = sut.elements
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: true)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.allStoredElements, storedElements)
        
        // when usingSmartCapacity == true and capacity is not a smart capacity value,
        // then it resize to smart capacity value for current count:
        sut = CircularBuffer(elements: storedElements)
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        XCTAssertNotEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.capacity))
        prevCapacity = sut.capacity
        prevBaseAddress = sut.elements
        sut.reduceCapacityForCurrentCount(usingSmartCapacityPolicy: true)
        XCTAssertNotEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count))
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.allStoredElements, storedElements)
    }
    
    // MARK: - makeElementsContiguous() tests
    func testMakeElementsContiguous() {
        let elements = (1...10).map { $0 * 10 }
        for headShift in 1..<elements.count {
            let wrappedElementsCount = elements.count - headShift
            // sut.residualCapacity == 0
            sut = CircularBuffer(capacity: elements.count, usingSmartCapacityPolicy: false)
            var tail = sut.unsafeInitializeElements(advancedToBufferIndex: headShift, from: elements)
            sut.count = elements.count
            sut.head = headShift
            sut.tail = tail
            XCTAssertEqual(sut.residualCapacity, 0)
            var prevElementsBaseAddress = sut.elements
            sut.makeElementsContiguous()
            XCTAssertEqual(sut.allStoredElements, elements)
            XCTAssertEqual(sut.elements, prevElementsBaseAddress)
            XCTAssert(sut.head + sut.count <= sut.capacity)
            
            // sut.residualCapacity == wrappedElementsCount
            var capacity = elements.count + wrappedElementsCount
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: false)
            var head = capacity - headShift
            tail = sut.unsafeInitializeElements(advancedToBufferIndex: head, from: elements)
            sut.count = elements.count
            sut.head = head
            sut.tail = tail
            prevElementsBaseAddress = sut.elements
            sut.makeElementsContiguous()
            XCTAssertEqual(sut.allStoredElements, elements)
            XCTAssertEqual(sut.elements, prevElementsBaseAddress)
            XCTAssert(sut.head + sut.count <= sut.capacity)
            
            // sut.residualCapacity > wrappedElementsCount
            capacity = elements.count + wrappedElementsCount + 1
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: false)
            head = capacity - headShift
            tail = sut.unsafeInitializeElements(advancedToBufferIndex: head, from: elements)
            sut.count = elements.count
            sut.head = head
            sut.tail = tail
            prevElementsBaseAddress = sut.elements
            sut.makeElementsContiguous()
            XCTAssertEqual(sut.allStoredElements, elements)
            XCTAssertEqual(sut.elements, prevElementsBaseAddress)
            XCTAssert(sut.head + sut.count <= sut.capacity)
            
            // sut.residualCapacity < wrappedElementsCount
            capacity = elements.count + wrappedElementsCount - 1
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: false)
            head = capacity - headShift
            tail = sut.unsafeInitializeElements(advancedToBufferIndex: head, from: elements)
            sut.count = elements.count
            sut.head = head
            sut.tail = tail
            prevElementsBaseAddress = sut.elements
            sut.makeElementsContiguous()
            XCTAssertEqual(sut.allStoredElements, elements)
            XCTAssertEqual(sut.elements, prevElementsBaseAddress)
            XCTAssert(sut.head + sut.count <= sut.capacity)
        }
    }
    
    // MARK: - fastResizeElements(to:) tests
    func testFastResizeElements() {
        // Resize to a larger capacity
        let storedElements = (1...10).shuffled()
        sut = CircularBuffer(elements: storedElements)
        var newCapacity = sut.capacity << 1
        var prevCapacity = sut.capacity
        var prevBaseAddress = sut.elements
        sut.fastResizeElements(to: newCapacity)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.allStoredElements, storedElements)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, sut.incrementBufferIndex(sut.count - 1))
        
        // Resize to a smaller capacity
        newCapacity = sut.capacity >> 1
        prevCapacity = sut.capacity
        prevBaseAddress = sut.elements
        sut.fastResizeElements(to: newCapacity)
        XCTAssertNotEqual(sut.elements, prevBaseAddress)
        XCTAssertEqual(sut.allStoredElements, storedElements)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, sut.incrementBufferIndex(sut.count - 1))
    }
    
    // MARK: - fastResizeElements(to:insert:at:)
    func testFastResizeElementsToInsertAt() {
        let storedElements = (1...10).shuffled()
        let newElements = (1...10).map { $0 + 10 }
        for idx in 0...storedElements.count {
            var newCapacity = storedElements.count + newElements.count + 12
            sut = CircularBuffer(elements: storedElements)
            var prevCapacity = sut.capacity
            var prevBaseAddress = sut.elements
            var expectedResult = storedElements
            expectedResult.insert(contentsOf: newElements, at: idx)
            sut.fastResizeElements(to: newCapacity, insert: newElements, at: idx)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            XCTAssertNotEqual(sut.elements, prevBaseAddress)
            XCTAssertNotEqual(prevCapacity, newCapacity)
            XCTAssertEqual(sut.capacity, newCapacity)
            XCTAssertEqual(sut.head, 0)
            XCTAssertEqual(sut.tail, sut.incrementBufferIndex(sut.count - 1))
            
            newCapacity = storedElements.count + newElements.count
            sut = CircularBuffer(elements: storedElements)
            prevCapacity = sut.capacity
            prevBaseAddress = sut.elements
            sut.fastResizeElements(to: newCapacity, insert: newElements, at: idx)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            XCTAssertNotEqual(sut.elements, prevBaseAddress)
            XCTAssertNotEqual(prevCapacity, newCapacity)
            XCTAssertEqual(sut.capacity, newCapacity)
            XCTAssertEqual(sut.head, 0)
            XCTAssertEqual(sut.tail, sut.incrementBufferIndex(sut.count - 1))
        }
    }
    
    // MARK: - fastResizeElements(to:replacing:with:) tests
    func testFastResizeElementsToReplacingWith() {
        let storedElements = (1...10).shuffled()
        for lowerBound in storedElements.startIndex...storedElements.count {
            for upperBound in lowerBound...storedElements.count {
                let subrange = lowerBound..<upperBound
                sut = CircularBuffer(elements: storedElements)
                var prevBaseAddress = sut.elements
                var newElements: Array<Int> = []
                var newCapacity = sut.count - subrange.count + newElements.count
                var expectedResult = storedElements
                expectedResult.replaceSubrange(subrange, with: newElements)
                sut.fastResizeElements(to: newCapacity, replacing: subrange, with: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                XCTAssertNotEqual(sut.elements, prevBaseAddress)
                XCTAssertEqual(sut.capacity, newCapacity)
                XCTAssertEqual(sut.head, 0)
                XCTAssertEqual(sut.tail, sut.incrementBufferIndex(sut.count - 1))
                
                sut = CircularBuffer(elements: storedElements)
                prevBaseAddress = sut.elements
                newElements = (1...10).map { $0 + 10 }
                newCapacity = sut.count - subrange.count + newElements.count
                expectedResult = storedElements
                expectedResult.replaceSubrange(subrange, with: newElements)
                sut.fastResizeElements(to: newCapacity, replacing: subrange, with: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                XCTAssertNotEqual(sut.elements, prevBaseAddress)
                XCTAssertEqual(sut.capacity, newCapacity)
                XCTAssertEqual(sut.head, 0)
                XCTAssertEqual(sut.tail, sut.incrementBufferIndex(sut.count - 1))
            }
        }
    }
    
    // MARK: - fastResizeElements(to:removingAt:count:) tests
    func testFastResizeElementsToRemovingAtCount() {
        let storedElements = (1...10).shuffled()
        for idx in storedElements.startIndex..<storedElements.endIndex {
            for k in 0...(storedElements.endIndex - idx) {
                sut = CircularBuffer(elements: storedElements)
                let prevBaseAddress = sut.elements
                let expectedResult = Array(storedElements[idx..<(idx + k)])
                var expectedRemainingElements = storedElements
                expectedRemainingElements.removeSubrange(idx..<(idx + k))
                let newCapacity = sut.capacity - k
                let result = sut.fastResizeElements(to: newCapacity, removingAt: idx, count: k)
                XCTAssertNotEqual(sut.elements, prevBaseAddress)
                XCTAssertEqual(result, expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, newCapacity)
                XCTAssertEqual(sut.head, 0)
                XCTAssertEqual(sut.tail, sut.incrementBufferIndex(sut.count - 1))
            }
        }
    }
    
    // MARK: - Unsafe operations tests
    func testUnsafeInitializeFromElements() {
        let storedElements = (1...10).shuffled()
        sut = CircularBuffer(elements: storedElements, usingSmartCapacityPolicy: false)
        let k = 5
        let dest = UnsafeMutablePointer<Int>.allocate(capacity: k)
        for idx in storedElements.startIndex..<storedElements.endIndex {
            let startBuffIdx = sut.bufferIndex(from: idx)
            let buffIdxResult = sut.unsafeInitializeFromElements(advancedToBufferIndex: startBuffIdx, count: k, to: dest)
            let expectedBufferIdx = (idx + k) % storedElements.count
            XCTAssertEqual(buffIdxResult, expectedBufferIdx)
            let expectedResult: Array<Int>!
            if idx + k >= storedElements.endIndex {
                let firstChunckCount = storedElements.endIndex - idx
                let firstChunk = Array(storedElements[idx..<idx + firstChunckCount])
                let secondChunkCount = k - firstChunckCount
                let secondChunk = Array(storedElements[storedElements.startIndex..<secondChunkCount])
                expectedResult = firstChunk + secondChunk
            } else {
                expectedResult = Array(storedElements[idx..<(idx + k)])
            }
            XCTAssertEqual(Array(UnsafeBufferPointer(start: dest, count: k)), expectedResult)
            dest.deinitialize(count: k)
        }
    }
    
    func testsUnsafeInitializeElements() {
        let elements = (1...10).shuffled()
        let capacity = 32
        for buffIdx in 0..<capacity {
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: false)
            let nextBuffIdx = sut.unsafeInitializeElements(advancedToBufferIndex: buffIdx, from: elements)
            let expectedBuffIdx = (buffIdx + elements.count) % capacity
            XCTAssertEqual(nextBuffIdx, expectedBuffIdx)
            for idx in 0..<elements.count {
                XCTAssertEqual(sut.elements.advanced(by: (buffIdx + idx) % capacity).pointee, elements[idx])
            }
        }
    }
    
    func testUnsafeMoveInitializeFromElements() {
        let storedElements = (1...10).shuffled()
        let k = 5
        let dest = UnsafeMutablePointer<Int>.allocate(capacity: k)
        for idx in storedElements.startIndex..<storedElements.endIndex {
            sut = CircularBuffer(elements: storedElements, usingSmartCapacityPolicy: false)
            let startBuffIdx = sut.bufferIndex(from: idx)
            let buffIdxResult = sut.unsafeMoveInitializeFromElements(advancedToBufferIndex: startBuffIdx, count: k, to: dest)
            let expectedBufferIdx = (idx + k) % storedElements.count
            XCTAssertEqual(buffIdxResult, expectedBufferIdx)
            let expectedResult: Array<Int>!
            if idx + k >= storedElements.endIndex {
                let firstChunckCount = storedElements.endIndex - idx
                let firstChunk = Array(storedElements[idx..<idx + firstChunckCount])
                let secondChunkCount = k - firstChunckCount
                let secondChunk = Array(storedElements[storedElements.startIndex..<secondChunkCount])
                expectedResult = firstChunk + secondChunk
            } else {
                expectedResult = Array(storedElements[idx..<(idx + k)])
            }
            XCTAssertEqual(Array(UnsafeBufferPointer(start: dest, count: k)), expectedResult)
            dest.deinitialize(count: k)
        }
    }
    
    func testUnsafeMoveInitializeFromElements_deinitializesMovedElements() {
        var elements = [Deinitializable]()
        var deinitializedCount = 0
        let capacity = 16
        for i in 0..<16 {
            let new = Deinitializable(value: i + 1, onDeinit: {_ in deinitializedCount += 1 })
            elements.append(new)
        }
        let testing = CircularBuffer(elements: elements, usingSmartCapacityPolicy: false)
        elements.removeAll()
        let dest = UnsafeMutablePointer<Deinitializable>.allocate(capacity: capacity)
        testing.unsafeMoveInitializeFromElements(advancedToBufferIndex: 0, count: capacity, to: dest)
        testing.count = 0
        dest.deinitialize(count: capacity)
        dest.deallocate()
        XCTAssertEqual(deinitializedCount, capacity)
    }
    
    func testUnsafeMoveInitializeToElements() {
        let capacity = 10
        let other = UnsafeMutablePointer<Int>.allocate(capacity: capacity)
        other.initialize(repeating: 100, count: capacity)
        for idx in 0..<capacity {
            sut = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: false)
            let buffIdx = sut.bufferIndex(from: idx)
            let nextBuffIdx = sut.unsafeMoveInitializeToElements(advancedToBufferIndex: buffIdx, from: other, count: capacity)
            let expectedBufferIdx = (buffIdx + capacity) % capacity
            XCTAssertEqual(nextBuffIdx, expectedBufferIdx)
            for offset in 0..<capacity {
                let bIdx = (buffIdx + offset) % capacity
                XCTAssertEqual(sut.elements.advanced(by: bIdx).pointee, 100)
            }
        }
    }
    
    func testUnsafeMoveInitializeToElements_deinitializesMovedElements() {
        var elements = [Deinitializable]()
        var deinitializedCount = 0
        let capacity = 16
        for i in 0..<16 {
            let new = Deinitializable(value: i + 1, onDeinit: {_ in deinitializedCount += 1 })
            elements.append(new)
        }
        let source = UnsafeMutablePointer<Deinitializable>.allocate(capacity: capacity)
        elements.withUnsafeBufferPointer { buff in
            source.initialize(from: buff.baseAddress!, count: capacity)
        }
        elements.removeAll()
        var testing: CircularBuffer<Deinitializable>? = CircularBuffer<Deinitializable>(capacity: capacity, usingSmartCapacityPolicy: false)
        testing!.unsafeMoveInitializeToElements(advancedToBufferIndex: 0, from: source, count: capacity)
        testing!.count = capacity
        testing = nil
        XCTAssertEqual(deinitializedCount, capacity)
        source.deallocate()
    }
    
    func testUnsafeAssignElements() {
        let newElements = Array(1...10)
        let capacity = 10
        for idx in 0..<capacity {
            sut = CircularBuffer(repeating: 1000, count: capacity, usingSmartCapacityPolicy: false)
            let buffIdx = sut.bufferIndex(from: idx)
            let nextBufferIdx = sut.unsafeAssignElements(advancedToBufferIndex: buffIdx, from: newElements)
            let expectedNextBuffIdx = (buffIdx + newElements.count) % sut.capacity
            XCTAssertEqual(nextBufferIdx, expectedNextBuffIdx)
            for offset in 0..<newElements.count {
                let bIdx = (buffIdx + offset) % capacity
                XCTAssertEqual(sut.elements.advanced(by: bIdx).pointee, newElements[offset])
            }
        }
    }
    
    func testUnsafeAssignFromElements() {
        let storedElements = (1...10).shuffled()
        sut = CircularBuffer(elements: storedElements, usingSmartCapacityPolicy: false)
        let k = 5
        let dest = UnsafeMutablePointer<Int>.allocate(capacity: k)
        for idx in storedElements.startIndex..<storedElements.endIndex {
            dest.initialize(repeating: 1000, count: k)
            let startBuffIdx = sut.bufferIndex(from: idx)
            let buffIdxResult = sut.unsafeAssignFromElements(advancedToBufferIndex: startBuffIdx, count: k, to: dest)
            let expectedBufferIdx = (idx + k) % storedElements.count
            XCTAssertEqual(buffIdxResult, expectedBufferIdx)
            let expectedResult: Array<Int>!
            if idx + k >= storedElements.endIndex {
                let firstChunckCount = storedElements.endIndex - idx
                let firstChunk = Array(storedElements[idx..<idx + firstChunckCount])
                let secondChunkCount = k - firstChunckCount
                let secondChunk = Array(storedElements[storedElements.startIndex..<secondChunkCount])
                expectedResult = firstChunk + secondChunk
            } else {
                expectedResult = Array(storedElements[idx..<(idx + k)])
            }
            XCTAssertEqual(Array(UnsafeBufferPointer(start: dest, count: k)), expectedResult)
            dest.deinitialize(count: k)
        }
    }
    
    func testUnsafeMoveAssignFromElements() {
        let storedElements = (1...10).shuffled()
        let k = 5
        let dest = UnsafeMutablePointer<Int>.allocate(capacity: k)
        for idx in storedElements.startIndex..<storedElements.endIndex {
            sut = CircularBuffer(elements: storedElements, usingSmartCapacityPolicy: false)
            dest.initialize(repeating: 1000, count: k)
            let startBuffIdx = sut.bufferIndex(from: idx)
            let buffIdxResult = sut.unsafeMoveAssignFromElements(advancedToBufferIndex: startBuffIdx, count: k, to: dest)
            let expectedBufferIdx = (idx + k) % storedElements.count
            XCTAssertEqual(buffIdxResult, expectedBufferIdx)
            let expectedResult: Array<Int>!
            if idx + k >= storedElements.endIndex {
                let firstChunckCount = storedElements.endIndex - idx
                let firstChunk = Array(storedElements[idx..<idx + firstChunckCount])
                let secondChunkCount = k - firstChunckCount
                let secondChunk = Array(storedElements[storedElements.startIndex..<secondChunkCount])
                expectedResult = firstChunk + secondChunk
            } else {
                expectedResult = Array(storedElements[idx..<(idx + k)])
            }
            XCTAssertEqual(Array(UnsafeBufferPointer(start: dest, count: k)), expectedResult)
            dest.deinitialize(count: k)
        }
    }
    
    func testUnsafeMoveAssignFromElements_deinitializesMovedElements() {
        var elements = [Deinitializable]()
        var deinitializedCount = 0
        let capacity = 16
        for i in 0..<16 {
            let new = Deinitializable(value: i + 1, onDeinit: {_ in deinitializedCount += 1 })
            elements.append(new)
        }
        let testing = CircularBuffer(elements: elements, usingSmartCapacityPolicy: false)
        elements.removeAll()
        let dest = UnsafeMutablePointer<Deinitializable>.allocate(capacity: capacity)
        dest.initialize(repeating: Deinitializable(value: 1000, onDeinit: {_ in }), count: capacity)
        testing.unsafeMoveAssignFromElements(advancedToBufferIndex: 0, count: capacity, to: dest)
        testing.count = 0
        dest.deinitialize(count: capacity)
        dest.deallocate()
        XCTAssertEqual(deinitializedCount, capacity)
    }
    
    func testUnsafeDeinitializeElements() {
        let capacity = 16
        for buffIdx in 0..<capacity {
            var onDeinitCalls = 0
            var elements = [Deinitializable]()
            for i in 0..<capacity {
                let new = Deinitializable(value: i, onDeinit: { _ in onDeinitCalls += 1 })
                elements.append(new)
            }
            let testing = CircularBuffer<Deinitializable>(elements: elements, usingSmartCapacityPolicy: false)
            elements.removeAll()
            let nextBuffIdx = testing.unsafeDeinitializeElements(advancedToBufferIndex: buffIdx, count: 16)
            testing.count = 0
            let expectedNextBuffIdx = (buffIdx + 16) % 16
            XCTAssertEqual(nextBuffIdx, expectedNextBuffIdx)
            XCTAssertEqual(onDeinitCalls, capacity)
        }
    }
    
}

// MARK: - Tests helpers
let minSmartCapacity = CircularBuffer<Int>.minSmartCapacity

final class Deinitializable {
    let value: Int
    
    let onDeinit: (Int) -> Void
    
    init(value: Int, onDeinit: @escaping (Int) -> Void ) {
        self.value = value
        self.onDeinit = onDeinit
    }
    
    deinit {
        onDeinit(self.value)
    }
    
}
