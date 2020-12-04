//
//  CircularBufferTests.swift
//  CircularBufferTests
//
//  Created by Valeriano Della Longa on 2020/09/24.
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

final class CircularBufferTests: XCTestCase {
    var sut: CircularBuffer<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularBuffer<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Init tests
    func testInit() {
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.minSmartCapacity)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
    }
    
    func testInitCapacity_whenCapacityIsGreaterThanZero() {
        sut = CircularBuffer<Int>(capacity: 1)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertGreaterThan(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
    }
    
    func testInitCapacity_whenMatchingExactlyIsFalse() {
        for i in 2..<5 {
            sut = CircularBuffer<Int>(capacity: i, matchingExactly: false)
            XCTAssertEqual(sut.capacity, 4)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: i))
        }
        
        for i in 5..<9 {
            sut = CircularBuffer<Int>(capacity: i, matchingExactly: false)
            XCTAssertEqual(sut.capacity, 8)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: i))
        }
        
        for i in 9..<17 {
            sut = CircularBuffer<Int>(capacity: i, matchingExactly: false)
            XCTAssertEqual(sut.capacity, 16)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: i))
        }
        
        for i in 17..<33 {
            sut = CircularBuffer<Int>(capacity: i, matchingExactly: false)
            XCTAssertEqual(sut.capacity, 32)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: i))
        }
    }
    
    func testInitCapacity_whenwhenMatchingExactlyIsTrue() {
        for k in 0..<100 {
            sut = CircularBuffer(capacity: k, matchingExactly: true)
            XCTAssertEqual(sut.capacity, k)
        }
    }
    
    func testInitRepeating() {
        sut = CircularBuffer<Int>(repeating: 90, count: 9)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 9)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 9)
        for idx in 0..<9 {
            XCTAssertEqual(sut.elements.advanced(by: idx).pointee, 90)
        }
    }
    
    func testInitRepeating_whenCapacityMatchesExactlyCountIsFalse() {
        for k in 1..<100 {
            sut = CircularBuffer<Int>(repeating: 90, count: k, capacityMatchesExactlyCount: false)
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.elements)
            XCTAssertFalse(sut.isEmpty)
            XCTAssertEqual(sut.count, k)
            XCTAssertEqual(sut.head, 0)
            let expectedTail = k == sut.capacity ? 0 : k
            XCTAssertEqual(sut.tail, expectedTail)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k))
            XCTAssertEqual(sut.allStoredElements, Array<Int>(repeating: 90, count: k))
        }
    }
    
    func testInitRepeating_whenCapacityMatchesExactlyCountIsTrue() {
        for k in 1..<100 {
            sut = CircularBuffer<Int>(repeating: 90, count: k, capacityMatchesExactlyCount: true)
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.elements)
            XCTAssertFalse(sut.isEmpty)
            XCTAssertEqual(sut.count, k)
            XCTAssertEqual(sut.head, 0)
            XCTAssertEqual(sut.head, sut.tail)
            XCTAssertEqual(sut.capacity, k)
            XCTAssertEqual(sut.allStoredElements, Array<Int>(repeating: 90, count: k))
        }
    }
    
    func testInitSequence_whenSequenceImplementsWithContiguousStorageIfAvailaable() {
        // empty sequence
        // capacityMatchesExactlyCount == false
        sut = CircularBuffer(elements: [])
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.minSmartCapacity)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
        
        // empty sequence
        // capacityMatchesExactlyCount == true
        sut = CircularBuffer(elements: [], capacityMatchesExactlyCount: true)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
        
        // not empty sequence
        // capacityMatchesExactlyCount == false
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: elements.count))
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        let expectedTail = elements.count == sut.capacity ? 0 : elements.count
        XCTAssertEqual(sut.tail, expectedTail)
        
        // not empty sequence
        // capacityMatchesExactlyCount == true
        sut = CircularBuffer(elements: elements, capacityMatchesExactlyCount: true)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, elements.count)
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
    }
    
    func testInitSequence_whenSequenceDoesntImplementsWithContiguousStorageIfAvailaable() {
        // Sequence has an underestimatedCount matching its lenght:
        
        // empty sequence
        // capacityMatchesExactlyCount == false
        sut = CircularBuffer(elements: AnySequence([]))
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.minSmartCapacity)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
        
        // empty sequence
        // capacityMatchesExactlyCount == true
        sut = CircularBuffer(elements: AnySequence([]), capacityMatchesExactlyCount: true)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
        
        // not empty sequence
        // capacityMatchesExactlyCount == false
        let elements = (1...100).shuffled()
        XCTAssertEqual(AnySequence(elements).underestimatedCount, elements.count)
        sut = CircularBuffer(elements: AnySequence(elements))
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: elements.count))
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        var expectedTail = elements.count == sut.capacity ? 0 : elements.count
        XCTAssertEqual(sut.tail, expectedTail)
        
        // not empty sequence
        // capacityMatchesExactlyCount == true
        sut = CircularBuffer(elements: AnySequence(elements), capacityMatchesExactlyCount: true)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, elements.count)
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
        
        // Sequence has an underestimatedCount always equal to zero even when not empty
        let seq = AnySequence { () -> AnyIterator<Int> in
            var idx = 0
            
            return AnyIterator {
                guard idx < elements.count else { return nil }
                
                defer { idx += 1 }
                
                return elements[idx]
            }
        }
        XCTAssertEqual(seq.underestimatedCount, 0)
        
        // capacityMatchesExactlyCount == false
        sut = CircularBuffer(elements: seq)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: elements.count))
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        expectedTail = elements.count == sut.capacity ? 0 : elements.count
        XCTAssertEqual(sut.tail, expectedTail)
        
        // capacityMatchesExactlyCount == true
        sut = CircularBuffer(elements: seq, capacityMatchesExactlyCount: true)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, elements.count)
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.head, sut.tail)
    }
    
    func testInitOther_whenOtherIsEmpty() {
        let other = CircularBuffer<Int>()
        sut = CircularBuffer(other: other)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, other.capacity)
        XCTAssertNotEqual(sut.elements, other.elements)
        XCTAssertEqual(sut.head, other.head)
        XCTAssertEqual(sut.tail, other.tail)
    }
    
    func testInitOther_whenOtherIsNotEmpty() {
        let elements = (1...100).shuffled()
        for headShift in 1...elements.count {
            let other = CircularBuffer<Int>.headShiftedInstance(contentsOf: elements, headShift: headShift)
            sut = CircularBuffer(other: other)
            XCTAssertEqual(sut.count, other.count)
            XCTAssertEqual(sut.capacity, other.capacity)
            XCTAssertNotEqual(sut.elements, other.elements)
            XCTAssertEqual(sut.head, other.head)
            XCTAssertEqual(sut.tail, other.tail)
            XCTAssertEqual(sut.allStoredElements, other.allStoredElements)
        }
        
    }
    
    // MARK: - deinit() tests
    func test_deinit() {
        sut = nil
        XCTAssertNil(sut?.elements)
        
        sut = CircularBuffer(elements: 1...100)
        sut = nil
        XCTAssertNil(sut?.elements)
        
        sut = CircularBuffer<Int>()
        sut.append(3)
        sut.push(2)
        XCTAssertGreaterThan(sut.head + sut.count, sut.capacity)
        sut = nil
        XCTAssertNil(sut?.elements)
    }
    
    // MARK: - Computed properties tests
    func testIsEmpty() {
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
        sut.append(10)
        XCTAssertGreaterThan(sut.count, 0)
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testIsFull() {
        XCTAssertGreaterThan(sut.capacity, sut.count)
        XCTAssertFalse(sut.isFull)
        sut = CircularBuffer(elements: 1...4)
        XCTAssertEqual(sut.capacity, sut.count)
        XCTAssertEqual(sut.head, sut.tail)
        XCTAssertTrue(sut.isFull)
    }
    
    func testResidualCapacity() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.residualCapacity, sut.capacity)
        sut = CircularBuffer(elements: 1...4)
        XCTAssertTrue(sut.isFull)
        XCTAssertEqual(sut.residualCapacity, 0)
        sut.removeLast(2)
        XCTAssertFalse(sut.isFull)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
    }
    
    func test_first() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.first)
        sut = CircularBuffer<Int>(repeating: 90, count: 4)
        XCTAssertNotNil(sut.first)
        XCTAssertEqual(sut.first, 90)
        XCTAssertEqual(sut.first, sut.elements.advanced(by: sut.head).pointee)
    }
    
    func test_last() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.last)
        sut = CircularBuffer<Int>(repeating: 90, count: 4)
        XCTAssertNotNil(sut.last)
        XCTAssertEqual(sut.last, 90)
        XCTAssertEqual(sut.last, sut.elements.advanced(by: sut.count - 1).pointee)
    }
    
    // MARK: - subscript tests
    func test_subscriptGetter() {
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        for i in 0..<sut.count {
            let buffIdx = sut.bufferIndex(from: i)
            XCTAssertEqual(sut[i], sut.elements.advanced(by: buffIdx).pointee)
            XCTAssertEqual(sut[i], elements[i])
        }
        
        // let's also test for when storage is wrapping around
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            for i in 0..<sut.count {
                let buffIdx = sut.bufferIndex(from: i)
                XCTAssertEqual(sut[i], sut.elements.advanced(by: buffIdx).pointee)
                XCTAssertEqual(sut[i], elements[i])
            }
        }
    }
    
    func test_subscriptSetter() {
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        for i in 0..<sut.count {
            sut[i] += 10
            let buffIdx = sut.bufferIndex(from: i)
            XCTAssertEqual(sut[i], sut.elements.advanced(by: buffIdx).pointee)
            XCTAssertEqual(sut[i], elements[i] + 10)
        }
        
        // let's also test for when storage is wrapping around
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            for i in 0..<sut.count {
                sut[i] += 10
                let buffIdx = sut.bufferIndex(from: i)
                XCTAssertEqual(sut[i], sut.elements.advanced(by: buffIdx).pointee)
                XCTAssertEqual(sut[i], elements[i] + 10)
            }
        }
    }
    
    // MARK: - copy tests
    func testCopy() {
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        let copy = sut.copy()
        XCTAssertNotEqual(sut.elements, copy.elements)
        XCTAssertEqual(sut.count, copy.count)
        XCTAssertEqual(sut.capacity, copy.capacity)
        XCTAssertEqual(sut.allStoredElements, elements)
        
        // let's also so this test when storage wraps around
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            let copy = sut.copy()
            XCTAssertNotEqual(sut.elements, copy.elements)
            XCTAssertEqual(sut.count, copy.count)
            XCTAssertEqual(sut.capacity, copy.capacity)
            XCTAssertEqual(sut.allStoredElements, elements)
        }
    }
    
    func testCopy_whenAdditionalCapacityGreaterThanZero() {
        // when matchingExactlyCapacity is false
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        var copy = sut.copy(additionalCapacity: 10)
        XCTAssertNotEqual(sut.elements, copy.elements)
        XCTAssertEqual(sut.count, copy.count)
        XCTAssertGreaterThanOrEqual(copy.capacity, sut.capacity + 10)
        XCTAssertEqual(sut.allStoredElements, elements)
        
        // when matchingExactlyCapacity is true
        copy = sut.copy(additionalCapacity: 10, matchingExactlyCapacity: true)
        XCTAssertNotEqual(sut.elements, copy.elements)
        XCTAssertEqual(sut.count, copy.count)
        XCTAssertEqual(copy.capacity, sut.capacity + 10)
        XCTAssertEqual(sut.allStoredElements, elements)
        
        // let's also so these tests when storage wraps around
        for headShift in 1...elements.count {
            // when matchingExactlyCapacity is false
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            copy = sut.copy(additionalCapacity: 10)
            XCTAssertNotEqual(sut.elements, copy.elements)
            XCTAssertEqual(sut.count, copy.count)
            XCTAssertGreaterThanOrEqual(copy.capacity, sut.capacity + 10)
            XCTAssertEqual(sut.allStoredElements, elements)
            
            // when matchingExactlyCapacity is true
            copy = sut.copy(additionalCapacity: 10, matchingExactlyCapacity: true)
            XCTAssertNotEqual(sut.elements, copy.elements)
            XCTAssertEqual(sut.count, copy.count)
            XCTAssertEqual(copy.capacity, sut.capacity + 10)
            XCTAssertEqual(sut.allStoredElements, elements)
        }
    }
    
    // MARK: - reserveCapacity(_:matchingExactlyCapacity:) tests
    func testReserveCapacity_whenMinimumCapacityIsZero() {
        let prevCapacity = sut.capacity
        let prevBuffer = sut.elements
        
        sut.reserveCapacity(0)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevBuffer)
    }
    
    func testReserveCapacity_whenResidualCapacityIsGreaterThanOrEqualToMinimumCapacity() {
        sut = CircularBuffer(elements: 1...5)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        for k in 1...sut.residualCapacity {
            let prevCapacity = sut.capacity
            let prevBuffer = sut.elements
            sut.reserveCapacity(k)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevBuffer)
        }
        
        // let's also test for when storage is wrapping around
        for headShift in 1...5 {
            sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...5), headShift: headShift)
            XCTAssertGreaterThan(sut.residualCapacity, 0)
            for k in 1...sut.residualCapacity {
                let prevCapacity = sut.capacity
                let prevBuffer = sut.elements
                sut.reserveCapacity(k)
                XCTAssertEqual(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.elements, prevBuffer)
            }
        }
        
    }
    
    func testReserveCapacity_whenResidualCapacityIsLessThanMinimumCapacity() {
        // when matchingExactlyCapacity is false
        let elements = Array(1...5)
        sut = CircularBuffer(elements: elements)
        
        var prevResidualCapacity = sut.residualCapacity
        var minimumCapacity = prevResidualCapacity + 1
        var prevCapacity = sut.capacity
        var prevBuffer = sut.elements
        sut.reserveCapacity(minimumCapacity)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertNotEqual(sut.elements, prevBuffer)
        XCTAssertEqual(sut.allStoredElements, elements)
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, minimumCapacity)
        
        // when matchingExactlyCapacity is true
        sut = CircularBuffer(elements: elements)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        prevResidualCapacity = sut.residualCapacity
        minimumCapacity = prevResidualCapacity + 1
        prevCapacity = sut.capacity
        prevBuffer = sut.elements
        sut.reserveCapacity(minimumCapacity, matchingExactlyCapacity: true)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertNotEqual(sut.elements, prevBuffer)
        XCTAssertEqual(sut.allStoredElements, elements)
        XCTAssertEqual(sut.residualCapacity, minimumCapacity)
        
        // let's also do the tests when storage is wrapping around
        for headShift in 1...elements.count {
            // when matchingExactlyCapacity is false
            sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...5), headShift: headShift)
            XCTAssertGreaterThan(sut.residualCapacity, 0)
            
            sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...5), headShift: headShift)
            XCTAssertGreaterThan(sut.residualCapacity, 0)
            prevResidualCapacity = sut.residualCapacity
            minimumCapacity = prevResidualCapacity + 1
            prevCapacity = sut.capacity
            prevBuffer = sut.elements
            sut.reserveCapacity(minimumCapacity)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertNotEqual(sut.elements, prevBuffer)
            XCTAssertEqual(sut.allStoredElements, elements)
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, minimumCapacity)
            
            // when matchingExactlyCapacity is true
            sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...5), headShift: headShift)
            XCTAssertGreaterThan(sut.residualCapacity, 0)
            prevResidualCapacity = sut.residualCapacity
            minimumCapacity = prevResidualCapacity + 1
            prevCapacity = sut.capacity
            prevBuffer = sut.elements
            sut.reserveCapacity(minimumCapacity, matchingExactlyCapacity: true)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertNotEqual(sut.elements, prevBuffer)
            XCTAssertEqual(sut.allStoredElements, elements)
            XCTAssertEqual(sut.residualCapacity, minimumCapacity)
        }
    }
    
}
