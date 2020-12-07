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
    
    // MARK: - popFirst() tests
    func testPopFirst() {
        // when sut.isEmpty == true
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popFirst())
        
        // when sut.isEmpty == false
        let elements = (1...10).shuffled()
        sut = CircularBuffer(elements: elements)
        while !sut.isEmpty {
            let oldFirst = sut.first
            let previousCount = sut.count
            XCTAssertEqual(sut.popFirst(), oldFirst)
            XCTAssertNotEqual(sut.first, oldFirst)
            XCTAssertEqual(sut.count, previousCount - 1)
        }
        
        // let's also do this test when storage wraps around
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            while !sut.isEmpty {
                let oldFirst = sut.first
                let previousCount = sut.count
                XCTAssertEqual(sut.popFirst(), oldFirst)
                XCTAssertNotEqual(sut.first, oldFirst)
                XCTAssertEqual(sut.count, previousCount - 1)
            }
        }
    }
    
    func testPopFirst_reducesCapacityUsingSmartPolicy() {
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
    
    // MARK: - popFront() tests
    func testPopFront() {
        // when isEmpty, returns nil:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popFront())
        
        // when not empty, removes and returns first, capacity stays the same:
        let elements = (1...10).shuffled()
        sut = CircularBuffer(elements: elements)
        let expectedCapacity = sut.capacity
        for i in 0..<elements.count {
            let prevFirst = sut.first
            let expectedResult = Array(elements[(i + 1)..<elements.endIndex])
            XCTAssertEqual(sut.popFront(), prevFirst)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
        }
        
        // let's also do this test when storage wraps around
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            for i in 0..<elements.count {
                let prevFirst = sut.first
                let expectedResult = Array(elements[(i + 1)..<elements.endIndex])
                XCTAssertEqual(sut.popFront(), prevFirst)
                XCTAssertEqual(sut.capacity, expectedCapacity)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
            }
        }
    }
    
    // MARK: - popLast() tests
    func testPopLast() {
        // when sut.isEmpty == true
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popLast())
        
        // when sut.isEmpty == false
        let elements = (1...10).shuffled()
        sut = CircularBuffer(elements: elements)
        while !sut.isEmpty {
            let oldLast = sut.last
            let previousCount = sut.count
            XCTAssertEqual(sut.popLast(), oldLast)
            XCTAssertNotEqual(sut.last, oldLast)
            XCTAssertEqual(sut.count, previousCount - 1)
        }
        
        // let's also do this test when storage wraps around
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            while !sut.isEmpty {
                let oldLast = sut.last
                let previousCount = sut.count
                XCTAssertEqual(sut.popLast(), oldLast)
                XCTAssertNotEqual(sut.last, oldLast)
                XCTAssertEqual(sut.count, previousCount - 1)
            }
        }
    }
        
    func testPopLast_reducesCapacityUsingSmartPolicy() {
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
    
    // MARK: - popBack() tests
    func testPopBack() {
        // when isEmpty, returns nil:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popBack())
        
        // when not empty, removes and returns last, capacity stays the same:
        let elements = (1...10).shuffled()
        sut = CircularBuffer(elements: elements)
        let expectedCapacity = sut.capacity
        for i in 1...elements.count {
            let prevLast = sut.last
            let expectedResult = Array(elements[0..<(elements.endIndex - i)])
            XCTAssertEqual(sut.popBack(), prevLast)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
        }
        
        // let's also do this test when storage wraps around
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            for i in 1...elements.count {
                let prevLast = sut.last
                let expectedResult = Array(elements[0..<(elements.endIndex - i)])
                XCTAssertEqual(sut.popBack(), prevLast)
                XCTAssertEqual(sut.capacity, expectedCapacity)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
            }
        }
    }
    
    // MARK: - removeFirst(_:keepCapacity:usingSmartCapacityPolicy:) tests
    func testRemoveFirst_whenKIsZero() {
        let elements = (1...10).shuffled()
        sut = CircularBuffer(elements: elements)
        var prevCapacity = sut.capacity
        var prevContainedElements = sut.allStoredElements
        // when keepCapacity == true
        XCTAssertEqual(sut.removeFirst(0), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        // when keepCapacity == false and usingSmartCapacity == true
        // and capacity is too big, reduces capacity:
        var greaterSmartCapacity = sut.capacity << 2
        sut.reserveCapacity(greaterSmartCapacity - sut.count)
        XCTAssertEqual(sut.capacity, greaterSmartCapacity)
        prevCapacity = sut.capacity
        prevContainedElements = sut.allStoredElements
        XCTAssertEqual(sut.removeFirst(0, keepCapacity: false), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, greaterSmartCapacity >> 2)
        
        // when keepCapacity == false and usingSmartCapacity == true
        // and capacity is not too big, doesn't reduce capacity:
        greaterSmartCapacity = sut.capacity << 1
        sut.reserveCapacity(greaterSmartCapacity - sut.count)
        XCTAssertEqual(sut.capacity, greaterSmartCapacity)
        prevCapacity = sut.capacity
        prevContainedElements = sut.allStoredElements
        XCTAssertEqual(sut.removeFirst(0, keepCapacity: false), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        // when keepCapacity == false and usingSmartCapacity == false
        // and capacity is greater than count, reduces capacity to count:
        XCTAssertGreaterThan(sut.capacity, sut.count)
        prevCapacity = sut.capacity
        prevContainedElements = sut.allStoredElements
        XCTAssertEqual(sut.removeFirst(0, keepCapacity: false, usingSmartCapacityPolicy: false), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertEqual(sut.capacity, sut.count)
        
        // when keepCapacity == false and usingSmartCapacity == false
        // and capacity is equal to count, doesn't reduce capacity:
        prevCapacity = sut.capacity
        prevContainedElements = sut.allStoredElements
        XCTAssertEqual(sut.removeFirst(0, keepCapacity: false, usingSmartCapacityPolicy: false), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
    }
    
    func testRemoveFirst_whenKIsGreaterThanZeroAndKeepCapacityIsTrue() {
        let elements = (1...10).shuffled()
        for k in 1...elements.count {
            sut = CircularBuffer(elements: elements)
            let prevCapacity = sut.capacity
            let expectedResult = Array(sut.allStoredElements[0..<k])
            let expectedRemainingElements = Array(sut.allStoredElements[k..<sut.count])
            XCTAssertEqual(sut.removeFirst(k), expectedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
        }
        
        // let's also do this test when storage wraps around
        for headShift in 1...elements.count {
            for k in 1...elements.count {
                sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                let prevCapacity = sut.capacity
                let expectedResult = Array(sut.allStoredElements[0..<k])
                let expectedRemainingElements = Array(sut.allStoredElements[k..<sut.count])
                XCTAssertEqual(sut.removeFirst(k), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, prevCapacity)
            }
        }
    }
    
    func testRemoveFirst_whenKIsGreaterThanZeroAndKeepCapacityIsFalse() {
        let elements = (1...10).shuffled()
        for k in 1...elements.count {
            // usingSmartCapacityPolicy == true and capacity is big enough to get
            // reduced after removal:
            sut = CircularBuffer(elements: elements)
            let biggerSmartCapacity = CircularBuffer<Int>.smartCapacityFor(count: sut.count - k) << 2
            sut.reserveCapacity(biggerSmartCapacity - sut.count)
            var prevCapacity = sut.capacity
            let expectedResult = Array(sut.allStoredElements[0..<k])
            let expectedRemainingElements = Array(sut.allStoredElements[k..<sut.count])
            XCTAssertEqual(sut.removeFirst(k, keepCapacity: false), expectedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertLessThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count))
            
            // usingSmartCapacityPolicy == true and capacity is not that big to get
            // reduced after removal every time:
            sut = CircularBuffer(elements: elements)
            prevCapacity = sut.capacity
            XCTAssertEqual(sut.removeFirst(k, keepCapacity: false), expectedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertEqual(sut.capacity, (sut.isEmpty ? CircularBuffer<Int>.minSmartCapacity : (1...5 ~= k ? prevCapacity : CircularBuffer<Int>.smartCapacityFor(count: sut.count))))
            
            // usingSmartCapacityPolicy == false
            sut = CircularBuffer(elements: elements)
            prevCapacity = sut.capacity
            XCTAssertEqual(sut.removeFirst(k, keepCapacity: false, usingSmartCapacityPolicy: false), expectedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertEqual(sut.capacity, sut.count)
        }
        
        // Let's also do these tests when storage wraps around
        for headShift in 1...elements.count {
            for k in 1...elements.count {
                // usingSmartCapacityPolicy == true and capacity is big enough to get
                // reduced after removal:
                sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                let biggerSmartCapacity = CircularBuffer<Int>.smartCapacityFor(count: sut.count - k) << 2
                sut.reserveCapacity(biggerSmartCapacity - sut.count)
                var prevCapacity = sut.capacity
                let expectedResult = Array(sut.allStoredElements[0..<k])
                let expectedRemainingElements = Array(sut.allStoredElements[k..<sut.count])
                XCTAssertEqual(sut.removeFirst(k, keepCapacity: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertLessThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count))
                
                // usingSmartCapacityPolicy == true and capacity is not that big to get
                // reduced after removal every time:
                sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                prevCapacity = sut.capacity
                XCTAssertEqual(sut.removeFirst(k, keepCapacity: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, (sut.isEmpty ? CircularBuffer<Int>.minSmartCapacity : (1...5 ~= k ? prevCapacity : CircularBuffer<Int>.smartCapacityFor(count: sut.count))))
                
                // usingSmartCapacityPolicy == false
                sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                prevCapacity = sut.capacity
                XCTAssertEqual(sut.removeFirst(k, keepCapacity: false, usingSmartCapacityPolicy: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, sut.count)
            }
        }
    }
    
    // MARK: - removeLast(_:keepCapacity:usingSmartCapacityPolicy:) tests
    func testRemoveLast_whenKIsZero() {
        let elements = (1...10).shuffled()
        sut = CircularBuffer(elements: elements)
        var prevCapacity = sut.capacity
        var prevContainedElements = sut.allStoredElements
        // when keepCapacity == true
        XCTAssertEqual(sut.removeLast(0), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        // when keepCapacity == false and usingSmartCapacity == true
        // and capacity is too big, reduces capacity:
        var greaterSmartCapacity = sut.capacity << 2
        sut.reserveCapacity(greaterSmartCapacity - sut.count)
        XCTAssertEqual(sut.capacity, greaterSmartCapacity)
        prevCapacity = sut.capacity
        prevContainedElements = sut.allStoredElements
        XCTAssertEqual(sut.removeLast(0, keepCapacity: false), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, greaterSmartCapacity >> 2)
        
        // when keepCapacity == false and usingSmartCapacity == true
        // and capacity is not too big, doesn't reduce capacity:
        greaterSmartCapacity = sut.capacity << 1
        sut.reserveCapacity(greaterSmartCapacity - sut.count)
        XCTAssertEqual(sut.capacity, greaterSmartCapacity)
        prevCapacity = sut.capacity
        prevContainedElements = sut.allStoredElements
        XCTAssertEqual(sut.removeLast(0, keepCapacity: false), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        // when keepCapacity == false and usingSmartCapacity == false
        // and capacity is greater than count, reduces capacity to count:
        XCTAssertGreaterThan(sut.capacity, sut.count)
        prevCapacity = sut.capacity
        prevContainedElements = sut.allStoredElements
        XCTAssertEqual(sut.removeLast(0, keepCapacity: false, usingSmartCapacityPolicy: false), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertEqual(sut.capacity, sut.count)
        
        // when keepCapacity == false and usingSmartCapacity == false
        // and capacity is equal to count, doesn't reduce capacity:
        prevCapacity = sut.capacity
        prevContainedElements = sut.allStoredElements
        XCTAssertEqual(sut.removeLast(0, keepCapacity: false, usingSmartCapacityPolicy: false), [])
        XCTAssertEqual(sut.allStoredElements, prevContainedElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
    }
    
    func testRemoveLast_whenKIsGreaterThanZeroAndKeepCapacityIsTrue() {
        let elements = (1...10).shuffled()
        for k in 1...elements.count {
            sut = CircularBuffer(elements: elements)
            let prevCapacity = sut.capacity
            let expectedResult = Array(sut.allStoredElements[(sut.count - k)..<sut.count])
            let expectedRemainingElements = Array(sut.allStoredElements[0..<(sut.count - k)])
            XCTAssertEqual(sut.removeLast(k), expectedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
        }
        
        // let's also do this test when storage wraps around
        for headShift in 1...elements.count {
            for k in 1...elements.count {
                sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                let prevCapacity = sut.capacity
                let expectedResult = Array(sut.allStoredElements[(sut.count - k)..<sut.count])
                let expectedRemainingElements = Array(sut.allStoredElements[0..<(sut.count - k)])
                XCTAssertEqual(sut.removeLast(k), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, prevCapacity)
            }
        }
    }
    
    func testRemoveLast_whenKIsGreaterThanZeroAndKeepCapacityIsFalse() {
        let elements = (1...10).shuffled()
        for k in 1...elements.count {
            // usingSmartCapacityPolicy == true and capacity is big enough to get
            // reduced after removal:
            sut = CircularBuffer(elements: elements)
            let biggerSmartCapacity = CircularBuffer<Int>.smartCapacityFor(count: sut.count - k) << 2
            sut.reserveCapacity(biggerSmartCapacity - sut.count)
            var prevCapacity = sut.capacity
            let expectedResult = Array(sut.allStoredElements[(sut.count - k)..<sut.count])
            let expectedRemainingElements = Array(sut.allStoredElements[0..<(sut.count - k)])
            XCTAssertEqual(sut.removeLast(k, keepCapacity: false), expectedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertLessThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count))
            
            // usingSmartCapacityPolicy == true and capacity is not that big to get
            // reduced after removal every time:
            sut = CircularBuffer(elements: elements)
            prevCapacity = sut.capacity
            XCTAssertEqual(sut.removeLast(k, keepCapacity: false), expectedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertEqual(sut.capacity, (sut.isEmpty ? CircularBuffer<Int>.minSmartCapacity : (1...5 ~= k ? prevCapacity : CircularBuffer<Int>.smartCapacityFor(count: sut.count))))
            
            // usingSmartCapacityPolicy == false
            sut = CircularBuffer(elements: elements)
            prevCapacity = sut.capacity
            XCTAssertEqual(sut.removeLast(k, keepCapacity: false, usingSmartCapacityPolicy: false), expectedResult)
            XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
            XCTAssertEqual(sut.capacity, sut.count)
        }
        
        // Let's also do these tests when storage wraps around
        for headShift in 1...elements.count {
            for k in 1...elements.count {
                // usingSmartCapacityPolicy == true and capacity is big enough to get
                // reduced after removal:
                sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                let biggerSmartCapacity = CircularBuffer<Int>.smartCapacityFor(count: sut.count - k) << 2
                sut.reserveCapacity(biggerSmartCapacity - sut.count)
                var prevCapacity = sut.capacity
                let expectedResult = Array(sut.allStoredElements[(sut.count - k)..<sut.count])
                let expectedRemainingElements = Array(sut.allStoredElements[0..<(sut.count - k)])
                XCTAssertEqual(sut.removeLast(k, keepCapacity: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertLessThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count))
                
                // usingSmartCapacityPolicy == true and capacity is not that big to get
                // reduced after removal every time:
                sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                prevCapacity = sut.capacity
                XCTAssertEqual(sut.removeLast(k, keepCapacity: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, (sut.isEmpty ? CircularBuffer<Int>.minSmartCapacity : (1...5 ~= k ? prevCapacity : CircularBuffer<Int>.smartCapacityFor(count: sut.count))))
                
                // usingSmartCapacityPolicy == false
                sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                prevCapacity = sut.capacity
                XCTAssertEqual(sut.removeLast(k, keepCapacity: false, usingSmartCapacityPolicy: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, sut.count)
            }
        }
    }
    
    // MARK: - removeAt(index:count:keepCapacity:usingSmartCapacityPolicy:) tests
    func testRemoveAt_whenCountToRemoveIsZero() {
        let elements = (1...10).shuffled()
        for idx in 0..<elements.count {
            // when keepCapacity == true
            sut = CircularBuffer(elements: elements)
            var prevCapacity = sut.capacity
            var prevContainedElements = sut.allStoredElements
            XCTAssertEqual(sut.removeAt(index: idx, count: 0), [])
            XCTAssertEqual(sut.allStoredElements, prevContainedElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            
            // when keepCapacity == false and usingSmartCapacity == true
            // and capacity is too big, reduces capacity:
            var greaterSmartCapacity = sut.capacity << 2
            sut.reserveCapacity(greaterSmartCapacity - sut.count)
            XCTAssertEqual(sut.capacity, greaterSmartCapacity)
            prevCapacity = sut.capacity
            prevContainedElements = sut.allStoredElements
            XCTAssertEqual(sut.removeAt(index: idx, count: 0, keepCapacity: false), [])
            XCTAssertEqual(sut.allStoredElements, prevContainedElements)
            XCTAssertLessThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, greaterSmartCapacity >> 2)
            
            // when keepCapacity == false and usingSmartCapacity == true
            // and capacity is not too big, doesn't reduce capacity
            greaterSmartCapacity = sut.capacity << 1
            sut.reserveCapacity(greaterSmartCapacity - sut.count)
            XCTAssertEqual(sut.capacity, greaterSmartCapacity)
            prevCapacity = sut.capacity
            prevContainedElements = sut.allStoredElements
            XCTAssertEqual(sut.removeAt(index: idx, count: 0, keepCapacity: false), [])
            XCTAssertEqual(sut.allStoredElements, prevContainedElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            
            // when keepCapacity == false and usingSmartCapacity == false
            // and capacity is greater than count, reduces capacity to count
            XCTAssertGreaterThan(sut.capacity, sut.count)
            prevCapacity = sut.capacity
            prevContainedElements = sut.allStoredElements
            XCTAssertEqual(sut.removeAt(index: idx, count: 0, keepCapacity: false, usingSmartCapacityPolicy: false), [])
            XCTAssertEqual(sut.allStoredElements, prevContainedElements)
            XCTAssertEqual(sut.capacity, sut.count)
            
            // when keepCapacity == false and usingSmartCapacity == false
            // and capacity is equal to count, doesn't reduce capacity
            prevCapacity = sut.capacity
            prevContainedElements = sut.allStoredElements
            XCTAssertEqual(sut.removeAt(index: idx, count: 0, keepCapacity: false, usingSmartCapacityPolicy: false), [])
            XCTAssertEqual(sut.allStoredElements, prevContainedElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
        }
    }
    
    func testRemoveAt_whenCountToRemoveIsGreaterThanZeroAndKeepCapacityIsTrue() {
        let elements = (1...10).shuffled()
        for idx in 0..<elements.count {
            for k in 1...(elements.count - idx) {
                let expectedResult = Array(elements[idx..<(idx + k)])
                var expectedRemainingElements = elements
                expectedRemainingElements.removeSubrange(idx..<(idx + k))
                sut = CircularBuffer(elements: elements)
                var prevCapacity = sut.capacity
                XCTAssertEqual(sut.removeAt(index: idx, count: k), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, prevCapacity)
                
                // let's also do this test when storage wraps around
                for headShift in 1...elements.count {
                    sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                    prevCapacity = sut.capacity
                    XCTAssertEqual(sut.removeAt(index: idx, count: k), expectedResult)
                    XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                    XCTAssertEqual(sut.capacity, prevCapacity)
                }
            }
        }
    }
    
    func testRemoveAt_whenCountIsGreaterThanZeroAndKeepCapacityIsFalse() {
        let elements = (1...10).shuffled()
        for idx in 0..<elements.count {
            for k in 1...(elements.count - idx) {
                let expectedResult = Array(elements[idx..<(idx + k)])
                var expectedRemainingElements = elements
                expectedRemainingElements.removeSubrange(idx..<(idx + k))
                // usingSmartCapacityPolicy == true and capacity is big enough to get
                // reduced after removal
                sut = CircularBuffer(elements: elements)
                let biggerSmartCapacity = CircularBuffer<Int>.smartCapacityFor(count: sut.count - k) << 2
                sut.reserveCapacity(biggerSmartCapacity - sut.count)
                var prevCapacity = sut.capacity
                XCTAssertEqual(sut.removeAt(index: idx, count: k, keepCapacity: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertLessThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count))
                
                // usingSmartCapacity == true
                // and capacity is not too big, doesn't reduce capacity after removal
                sut = CircularBuffer(elements: elements)
                prevCapacity = sut.capacity
                XCTAssertEqual(sut.removeAt(index: idx, count: k, keepCapacity: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, (sut.isEmpty ? CircularBuffer<Int>.minSmartCapacity : (1...5 ~= k ? prevCapacity : CircularBuffer<Int>.smartCapacityFor(count: sut.count))))
                
                // usingSmartCapacity == false
                sut = CircularBuffer(elements: elements)
                prevCapacity = sut.capacity
                XCTAssertEqual(sut.removeAt(index: idx, count: k, keepCapacity: false, usingSmartCapacityPolicy: false), expectedResult)
                XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                XCTAssertEqual(sut.capacity, sut.count)
                
                // let's also do these tests when storage wraps around:
                for headShift in 1...elements.count {
                    // usingSmartCapacityPolicy == true and capacity is big enough to get
                    // reduced after removal
                    sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                    let biggerSmartCapacity = CircularBuffer<Int>.smartCapacityFor(count: sut.count - k) << 2
                    sut.reserveCapacity(biggerSmartCapacity - sut.count)
                    var prevCapacity = sut.capacity
                    XCTAssertEqual(sut.removeAt(index: idx, count: k, keepCapacity: false), expectedResult)
                    XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                    XCTAssertLessThan(sut.capacity, prevCapacity)
                    XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: sut.count))
                    
                    // usingSmartCapacity == true
                    // and capacity is not too big, doesn't reduce capacity after removal
                    sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                    prevCapacity = sut.capacity
                    XCTAssertEqual(sut.removeAt(index: idx, count: k, keepCapacity: false), expectedResult)
                    XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                    XCTAssertEqual(sut.capacity, (sut.isEmpty ? CircularBuffer<Int>.minSmartCapacity : (1...5 ~= k ? prevCapacity : CircularBuffer<Int>.smartCapacityFor(count: sut.count))))
                    
                    // usingSmartCapacity == false
                    sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
                    prevCapacity = sut.capacity
                    XCTAssertEqual(sut.removeAt(index: idx, count: k, keepCapacity: false, usingSmartCapacityPolicy: false), expectedResult)
                    XCTAssertEqual(sut.allStoredElements, expectedRemainingElements)
                    XCTAssertEqual(sut.capacity, sut.count)
                }
            }
        }
    }
    
    
    // MARK: - removeAll(keepCapacity:usingSmartCapacityPolicy:) tests
    func testRemoveAll_whenIsEmpty() {
        // keepCapacity == true
        XCTAssertTrue(sut.isEmpty)
        var prevCapacity = sut.capacity
        sut.removeAll()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        // keepCapacity == false and usingSmartCapacityPolicy == true
        let minSmartCapacity = CircularBuffer<Int>.minSmartCapacity
        sut.reserveCapacity(16)
        prevCapacity = sut.capacity
        XCTAssertTrue(sut.isEmpty)
        XCTAssertGreaterThan(sut.capacity, minSmartCapacity)
        sut.removeAll(keepCapacity: false)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, minSmartCapacity)
        
        // keepCapacity == false and usingSmartCapacityPolicy == false
        sut.reserveCapacity(16)
        prevCapacity = sut.capacity
        XCTAssertTrue(sut.isEmpty)
        XCTAssertGreaterThan(sut.capacity, 0)
        sut.removeAll(keepCapacity: false, usingSmartCapacityPolicy: false)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertLessThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, 0)
    }
    
    func testRemoveAll_whenIsNotEmpty() {
        let elements = (1...10).shuffled()
        
        // keepCapacity == true
        sut = CircularBuffer(elements: elements)
        var prevCapacity = sut.capacity
        sut.removeAll()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        // keepCapacity == false and usingSmartCapacityPolicy == true
        let minSmartCapacity = CircularBuffer<Int>.minSmartCapacity
        sut = CircularBuffer(elements: elements)
        prevCapacity = sut.capacity
        sut.removeAll(keepCapacity: false)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, minSmartCapacity)
        
        // keepCapacity == false and usingSmartCapacityPolicy == false
        sut = CircularBuffer(elements: elements)
        prevCapacity = sut.capacity
        sut.removeAll(keepCapacity: false, usingSmartCapacityPolicy: false)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, 0)
        
        // Let's also do these tests when storage wraps around
        for headshift in 1...elements.count {
            // keepCapacity == true
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headshift)
            var prevCapacity = sut.capacity
            sut.removeAll()
            XCTAssertTrue(sut.isEmpty)
            XCTAssertEqual(sut.capacity, prevCapacity)
            
            // keepCapacity == false and usingSmartCapacityPolicy == true
            let minSmartCapacity = CircularBuffer<Int>.minSmartCapacity
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headshift)
            prevCapacity = sut.capacity
            sut.removeAll(keepCapacity: false)
            XCTAssertTrue(sut.isEmpty)
            XCTAssertEqual(sut.capacity, minSmartCapacity)
            
            // keepCapacity == false and usingSmartCapacityPolicy == false
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headshift)
            prevCapacity = sut.capacity
            sut.removeAll(keepCapacity: false, usingSmartCapacityPolicy: false)
            XCTAssertTrue(sut.isEmpty)
            XCTAssertEqual(sut.capacity, 0)
        }
    }
    
}
