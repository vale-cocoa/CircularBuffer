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
    
    // MARK: - append(_:) tests
    func testAppend() {
        for i in 1...10 {
            let prevCount = sut.count
            let prevElements = sut.allStoredElements
            sut.append(i)
            XCTAssertEqual(sut.count, prevCount + 1)
            XCTAssertEqual(sut.allStoredElements, (prevElements + [i]))
            XCTAssertEqual(sut.last, i)
        }
        
        // let's also do this test when storage wraps around
        for headshift in 1...10 {
            sut = CircularBuffer.headShiftedInstance(contentsOf: (1...10).shuffled(), headShift: headshift)
            let prevCount = sut.count
            let prevElements = sut.allStoredElements
            let newElement = headshift * 10
            sut.append(newElement)
            XCTAssertEqual(sut.count, prevCount + 1)
            XCTAssertEqual(sut.allStoredElements, (prevElements + [newElement]))
            XCTAssertEqual(sut.last, newElement)
        }
    }
    
    func testAppend_whenIsFull() {
        for k in 1...100 where CircularBuffer<Int>.smartCapacityFor(count: k) == k {
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            let prevCapacity = sut.capacity
            sut.append(2000)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, prevCapacity << 1)
            
            // let's also do this test when storage wraps around
            for headShift in 1..<k {
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                let prevCapacity = sut.capacity
                sut.append(2000)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, prevCapacity << 1)
            }
        }
    }
    
    // MARK: - append(contentsOf:) tests
    func testAppendContentsOf_whenSequenceImplementsWithContiguousStorageIfAvailable() {
        // sut isEmpty == true
        // newElements.isEmpty == true
        XCTAssertTrue(sut.isEmpty)
        var newElements: Array<Int> = []
        sut.append(contentsOf: TestSequence(elements: newElements))
        XCTAssertTrue(sut.isEmpty)
        
        // sut isEmpty == true
        // newElements.isEmpty == false
        XCTAssertTrue(sut.isEmpty)
        newElements = (1...100).shuffled()
        sut.append(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, newElements)
        
        // sut.isEmpty == false
        // newElements.isEmpty == true
        let sutElements = (101...200).shuffled()
        sut = CircularBuffer(elements: sutElements)
        newElements = []
        sut.append(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.append(contentsOf: TestSequence(elements: newElements))
            XCTAssertEqual(sut.allStoredElements, sutElements)
        }
        
        // sut.isEmpty == false
        // newElements.isEmpty == false
        sut = CircularBuffer(elements: sutElements)
        newElements = (1...100).shuffled()
        sut.append(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, sutElements + newElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.append(contentsOf: TestSequence(elements: newElements))
            XCTAssertEqual(sut.allStoredElements, sutElements + newElements)
        }
    }
    
    func testAppendContentsOf_whenSequenceDoesntImplementWithContiguousStorageIfAvailable() {
        // sut isEmpty == true
        // newElements.isEmpty == true
        XCTAssertTrue(sut.isEmpty)
        var newElements: Array<Int> = []
        sut.append(contentsOf: AnySequence(newElements))
        XCTAssertTrue(sut.isEmpty)
        
        // sut isEmpty == true
        // newElements.isEmpty == false
        XCTAssertTrue(sut.isEmpty)
        newElements = (1...100).shuffled()
        sut.append(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, newElements)
        
        // sut.isEmpty == false
        // newElements.isEmpty == true
        let sutElements = (101...200).shuffled()
        sut = CircularBuffer(elements: sutElements)
        newElements = []
        sut.append(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.append(contentsOf: AnySequence(newElements))
            XCTAssertEqual(sut.allStoredElements, sutElements)
        }
        
        // sut.isEmpty == false
        // newElements.isEmpty == false
        sut = CircularBuffer(elements: sutElements)
        newElements = (1...100).shuffled()
        sut.append(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, sutElements + newElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.append(contentsOf: AnySequence(newElements))
            XCTAssertEqual(sut.allStoredElements, sutElements + newElements)
        }
        
        // We're also gonna test with a sequence which returns 0 as
        // its underestimatedCount value even if its lenght is greater than zero:
        let seq = AnySequence { () -> AnyIterator<Int> in
            var idx = 0
            
            return AnyIterator {
                guard idx < newElements.count else { return nil }
                
                defer { idx += 1 }
                
                return newElements[idx]
            }
        }
        XCTAssertEqual(seq.underestimatedCount, 0)
        sut = CircularBuffer(elements: sutElements)
        sut.append(contentsOf: seq)
        XCTAssertEqual(sut.allStoredElements, sutElements + newElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.append(contentsOf: seq)
            XCTAssertEqual(sut.allStoredElements, sutElements + newElements)
        }
    }
    
    func testAppendContentsOf_whenIsFull() {
        let newElements = (101...200).shuffled()
        // We're also gonna test with a sequence which returns 0 as
        // its underestimatedCount value even if its lenght is greater than zero:
        let seq = AnySequence { () -> AnyIterator<Int> in
            var idx = 0
            
            return AnyIterator {
                guard idx < newElements.count else { return nil }
                
                defer { idx += 1 }
                
                return newElements[idx]
            }
        }
        
        for k in 1...100 where CircularBuffer<Int>.smartCapacityFor(count: k) == k {
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            var prevCapacity = sut.capacity
            // newElements implements withContiguousStorageIfAvailable
            sut.append(contentsOf: newElements)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            // newElements doesn't implement withContiguousStorageIfAvailable
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            prevCapacity = sut.capacity
            sut.append(contentsOf: AnySequence(newElements))
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            prevCapacity = sut.capacity
            sut.append(contentsOf: seq)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            // let's also do this test when storage wraps around
            for headShift in 1..<k {
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                // newElements implements withContiguousStorageIfAvailable
                sut.append(contentsOf: newElements)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
                
                // newElements doesn't implement withContiguousStorageIfAvailable
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                sut.append(contentsOf: AnySequence(newElements))
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
                
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                sut.append(contentsOf: seq)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            }
        }
    }
    
    func testAppendContentsOf_whenResidualCapacityIsEnoughToStoreNewElements() {
        let sutElements = (101...200).shuffled()
        let newElementsStorage = (1..<(CircularBuffer<Int>.smartCapacityFor(count: sutElements.count) - sutElements.count)).shuffled()
        XCTAssertFalse(newElementsStorage.isEmpty)
        
        // sequence implements withContiguousStorageIfAvailable
        var newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: true, underEstimatedCountMatchesCount: true)
        sut = CircularBuffer(elements: sutElements)
        var prevCapacity = sut.capacity
        var prevSutElementsAddress = sut.elements
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // sequence doesn't implements withContiguousStorageIfAvailable
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: true)
        sut = CircularBuffer(elements: sutElements)
        prevCapacity = sut.capacity
        prevSutElementsAddress = sut.elements
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // sequence doesn't implements withContiguousStorageIfAvailable and
        // its underestimatedCount is zero despite it stores some elements
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: false)
        sut = CircularBuffer(elements: sutElements)
        prevCapacity = sut.capacity
        prevSutElementsAddress = sut.elements
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // let's also do these tests when storage wraps around
        for headShift in 1..<sutElements.count {
            // sequence implements withContiguousStorageIfAvailable
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: true, underEstimatedCountMatchesCount: true)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.append(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
            
            // sequence doesn't implements withContiguousStorageIfAvailable
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: true)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.append(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
            
            // sequence doesn't implements withContiguousStorageIfAvailable and
            // its underestimatedCount is zero despite it stores some elements
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: false)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.append(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
        }
    }
    
    // MARK: - pushBack(_:) tests
    func testPushBack() {
        sut = CircularBuffer(capacity: 0, usingSmartCapacityPolicy: false)
        // when capacity is 0 nothing happens:
        XCTAssertEqual(sut.capacity, 0)
        sut.pushBack(10)
        XCTAssertEqual(sut.capacity, 0)
        
        // when residualCapacity is greater than 0, then element is stored as new last:
        sut.reserveCapacity(5, usingSmartCapacityPolicy: false)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        let expectedCapacity = sut.capacity
        var newElement = 5
        var expectedResult: Array<Int> = []
        while sut.residualCapacity > 0 {
            expectedResult.append(newElement)
            sut.pushBack(newElement)
            XCTAssertEqual(sut.last, newElement)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            
            newElement -= 1
        }
        
        // when residualCapacity is equal to 0, then element is stored as new last, and
        // old first gets trumped:
        XCTAssertEqual(sut.residualCapacity, 0)
        newElement = 50
        for i in 1...10 {
            let _ = expectedResult.remove(at: 0)
            expectedResult.append(newElement)
            sut.pushBack(newElement)
            XCTAssertEqual(sut.last, newElement)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            
            newElement += i*10
        }
        
        // let's also do these tests when storage wraps around
        let preStored = (1...10).shuffled()
        for headShift in 1..<preStored.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: preStored, headShift: headShift)
            sut.reserveCapacity(5, usingSmartCapacityPolicy: false)
            XCTAssertGreaterThan(sut.residualCapacity, 0)
            // when residual capacity is greater than zero, then element is stored at
            // last position and elements previously stored don't get trumped:
            var newElement = 5
            while sut.residualCapacity > 0 {
                let prevElements = sut.allStoredElements
                sut.pushBack(newElement)
                XCTAssertEqual(sut.allStoredElements, prevElements + [newElement])
                newElement -= 1
            }
            XCTAssertEqual(sut.residualCapacity, 0)
            // when residualCapacity is equal to 0, then element is stored as new last, and
            // old first gets trumped:
            expectedResult = sut.allStoredElements
            for i in 1...sut.capacity {
                newElement = i * 100
                let _ = expectedResult.remove(at: 0)
                expectedResult.append(newElement)
                sut.pushBack(newElement)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
            }
        }
    }
    
    // MARK: - pushBack(contentsOf:) tests
    func testPushBackContentsOf_whenCapacityIsZero() {
        // nothing happens whether newElements contains elements or is empty:
        sut = CircularBuffer(capacity: 0, usingSmartCapacityPolicy: false)
        XCTAssertTrue(sut.isEmpty)
        sut.pushBack(contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        sut.pushBack(contentsOf: 1...10)
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testPushBackContentsOf_whenIsEmptyAndSequenceImplementsWithContiguousStorage() {
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        var sutPrevElements = sut.allStoredElements
        
        // newElements is empty
        var newElements = TestSequence<Int>(elements: [])
        sut.pushBack(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, sutPrevElements)
        
        // newElements is not empty and sut.residualCapacity is enough
        // to store all new elements:
        // then all sequence elements are appended to sut
        var newElementsStorage = (1...sut.residualCapacity).shuffled()
        XCTAssertFalse(newElementsStorage.isEmpty)
        newElements = TestSequence(elements: newElementsStorage)
        sutPrevElements = sut.allStoredElements
        sut.pushBack(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, sutPrevElements + newElementsStorage)
        
        // newElements is not empty and sut residualCapacity is not enough
        // to store all new elements:
        // then only last m elements are stored, where m is the sut capacity
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        newElementsStorage = (1...(sut.residualCapacity + 1)).shuffled()
        newElements = TestSequence(elements: newElementsStorage)
        sutPrevElements = sut.allStoredElements
        sut.pushBack(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, Array(newElementsStorage[(newElementsStorage.endIndex - sut.capacity)..<newElementsStorage.endIndex]))
    }
    
    func testPushBackContentsOf_whenIsNotEmptyAndSequenceImplementsWithContiguousStorage() {
        var sutPrevStoredElements = (1...10).shuffled()
        sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
        
        // newElements is empty, nothing happens:
        sut.pushBack(contentsOf: [])
        XCTAssertEqual(sut.allStoredElements, sutPrevStoredElements)
        
        // newElements is not empty and sut.residualCapacity is greater zero:
        
        // when newElements lenght is less than or equal to sut.residualCapacity, then all
        // newElements get appended to sut:
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        var newElementsStorage = (11...20).shuffled()
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, newElementsStorage.count)
        var newElements = TestSequence(elements: newElementsStorage)
        sutPrevStoredElements = sut.allStoredElements
        sut.pushBack(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, sutPrevStoredElements + newElementsStorage)
        // let's also do this test when sut storage wraps around
        for headShift in 1..<19 {
            sut = CircularBuffer(capacity: 20, usingSmartCapacityPolicy: false)
            let tail = sut.initializeElements(advancedToBufferIndex: headShift, from: (1...10).map { $0 * 10 } )
            sut.head = headShift
            sut.count = 10
            sut.tail = tail
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, newElementsStorage.count)
            newElements = TestSequence(elements: newElementsStorage)
            sutPrevStoredElements = sut.allStoredElements
            sut.pushBack(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, sutPrevStoredElements + newElementsStorage)
        }
        
        // when newElements is not empty, and sut residual capacity is not enough to
        // store all newElements, then sequence elements are sequentially appended to sut,
        // while sut drops elements from its front to make room for new elements:
        sutPrevStoredElements = sut.allStoredElements
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        newElementsStorage = (1...(sut.residualCapacity + 1)).map { $0 * 2000 }
        XCTAssertGreaterThan(newElementsStorage.count, sut.residualCapacity)
        // here we'll just trump previously stored elements to make room for new elements:
        sutPrevStoredElements = sut.allStoredElements
        var lastNew = newElementsStorage.last!
        for countOfTrumped in 1...sutPrevStoredElements.count {
            sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
            sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
            let expectedResult = Array(sutPrevStoredElements[countOfTrumped..<sutPrevStoredElements.endIndex]) + newElementsStorage
            newElements = TestSequence(elements: newElementsStorage)
            sut.pushBack(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            newElementsStorage.append(lastNew + 1)
            lastNew = newElementsStorage.last!
        }
        
        // From now on we'll have to trump all previously stored elements, and then
        // also newly stored elements to keep making room for new elements
        lastNew = newElementsStorage.last!
        for countOfTrumped in 1...sut.capacity {
            sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
            sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
            let expectedResult = Array(newElementsStorage.dropFirst(countOfTrumped))
            newElements = TestSequence(elements: newElementsStorage)
            sut.pushBack(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            newElementsStorage.append(lastNew + 1)
            lastNew = newElementsStorage.last!
        }
        
        // we also do these tests when sut storage wraps around
        for headShift in 1...19 {
            newElementsStorage = (1...11).map { $0 * 2000 }
            // here we'll just trump previously stored elements to make room for new elements:
            for countOfTrumped in 1...10 {
                XCTAssertGreaterThan(newElementsStorage.count, sut.residualCapacity)
                sut = CircularBuffer(capacity: 20, usingSmartCapacityPolicy: false)
                let tail = sut.initializeElements(advancedToBufferIndex: headShift, from: (1...10).map { $0 * 10 } )
                sut.head = headShift
                sut.count = 10
                sut.tail = tail
                sutPrevStoredElements = sut.allStoredElements
                let expectedResult = Array(sutPrevStoredElements[countOfTrumped..<sutPrevStoredElements.endIndex]) + newElementsStorage
                newElements = TestSequence(elements: newElementsStorage)
                sut.pushBack(contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                newElementsStorage.append(lastNew + 1)
                lastNew = newElementsStorage.last!
            }
            // From now on we'll have to trump all previously stored elements, and then
            // also newly stored elements to keep making room for new elements
            lastNew = newElementsStorage.last!
            for countOfTrumped in 1...sut.capacity {
                sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
                sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
                let expectedResult = Array(newElementsStorage.dropFirst(countOfTrumped))
                newElements = TestSequence(elements: newElementsStorage)
                sut.pushBack(contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                newElementsStorage.append(lastNew + 1)
                lastNew = newElementsStorage.last!
            }
        }
    }
    
    func testPushBackContentsOf_whenIsEmptyAndSequenceDoesntImplementWithContiguousStorage() {
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        var sutPrevElements = sut.allStoredElements
        
        // newElements is empty
        var newElements = TestSequence<Int>(elements: [], implementsWithContiguousStorage: false)
        sut.pushBack(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, sutPrevElements)
        
        // newElements is not empty and sut.residualCapacity is enough
        // to store all new elements:
        // then all sequence elements are appended to sut
        var newElementsStorage = (1...sut.residualCapacity).shuffled()
        XCTAssertFalse(newElementsStorage.isEmpty)
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
        sutPrevElements = sut.allStoredElements
        sut.pushBack(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, sutPrevElements + newElementsStorage)
        
        // newElements is not empty and sut residualCapacity is not enough
        // to store all new elements:
        // then only last m elements are stored, where m is the sut capacity
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        newElementsStorage = (1...(sut.residualCapacity + 1)).shuffled()
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
        sutPrevElements = sut.allStoredElements
        sut.pushBack(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, Array(newElementsStorage[(newElementsStorage.endIndex - sut.capacity)..<newElementsStorage.endIndex]))
    }
    
    func testPushBackContentsOf_whenIsNotEmptyAndSequenceDoesntImplementsWithContiguousStorage() {
        var sutPrevStoredElements = (1...10).shuffled()
        sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
        
        // newElements is empty, nothing happens:
        sut.pushBack(contentsOf: TestSequence(elements: [], implementsWithContiguousStorage: false))
        XCTAssertEqual(sut.allStoredElements, sutPrevStoredElements)
        
        // newElements is not empty and sut.residualCapacity is greater zero:
        
        // when newElements lenght is less than or equal to sut.residualCapacity, then all
        // newElements get appended to sut:
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        var newElementsStorage = (11...20).shuffled()
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, newElementsStorage.count)
        var newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
        sutPrevStoredElements = sut.allStoredElements
        sut.pushBack(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, sutPrevStoredElements + newElementsStorage)
        // let's also do this test when sut storage wraps around
        for headShift in 1..<19 {
            sut = CircularBuffer(capacity: 20, usingSmartCapacityPolicy: false)
            let tail = sut.initializeElements(advancedToBufferIndex: headShift, from: (1...10).map { $0 * 10 } )
            sut.head = headShift
            sut.count = 10
            sut.tail = tail
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, newElementsStorage.count)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
            sutPrevStoredElements = sut.allStoredElements
            sut.pushBack(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, sutPrevStoredElements + newElementsStorage)
        }
        
        // when newElements is not empty, and sut residual capacity is not enough to
        // store all newElements, then sequence elements are sequentially appended to sut,
        // while sut drops elements from its front to make room for new elements:
        sutPrevStoredElements = sut.allStoredElements
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        newElementsStorage = (1...(sut.residualCapacity + 1)).map { $0 * 2000 }
        XCTAssertGreaterThan(newElementsStorage.count, sut.residualCapacity)
        // here we'll just trump previously stored elements to make room for new elements:
        sutPrevStoredElements = sut.allStoredElements
        var lastNew = newElementsStorage.last!
        for countOfTrumped in 1...sutPrevStoredElements.count {
            sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
            sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
            let expectedResult = Array(sutPrevStoredElements[countOfTrumped..<sutPrevStoredElements.endIndex]) + newElementsStorage
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
            sut.pushBack(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            newElementsStorage.append(lastNew + 1)
            lastNew = newElementsStorage.last!
        }
        
        // From now on we'll have to trump all previously stored elements, and then
        // also newly stored elements to keep making room for new elements
        lastNew = newElementsStorage.last!
        for countOfTrumped in 1...sut.capacity {
            sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
            sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
            let expectedResult = Array(newElementsStorage.dropFirst(countOfTrumped))
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
            sut.pushBack(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            newElementsStorage.append(lastNew + 1)
            lastNew = newElementsStorage.last!
        }
        
        // we also do these tests when sut storage wraps around
        for headShift in 1...19 {
            newElementsStorage = (1...11).map { $0 * 2000 }
            // here we'll just trump previously stored elements to make room for new elements:
            for countOfTrumped in 1...10 {
                XCTAssertGreaterThan(newElementsStorage.count, sut.residualCapacity)
                sut = CircularBuffer(capacity: 20, usingSmartCapacityPolicy: false)
                let tail = sut.initializeElements(advancedToBufferIndex: headShift, from: (1...10).map { $0 * 10 } )
                sut.head = headShift
                sut.count = 10
                sut.tail = tail
                sutPrevStoredElements = sut.allStoredElements
                let expectedResult = Array(sutPrevStoredElements[countOfTrumped..<sutPrevStoredElements.endIndex]) + newElementsStorage
                newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
                sut.pushBack(contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                newElementsStorage.append(lastNew + 1)
                lastNew = newElementsStorage.last!
            }
            // From now on we'll have to trump all previously stored elements, and then
            // also newly stored elements to keep making room for new elements
            lastNew = newElementsStorage.last!
            for countOfTrumped in 1...sut.capacity {
                sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
                sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
                let expectedResult = Array(newElementsStorage.dropFirst(countOfTrumped))
                newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
                sut.pushBack(contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                newElementsStorage.append(lastNew + 1)
                lastNew = newElementsStorage.last!
            }
        }
    }
    
    // MARK: - push(_:) tests
    func testPush() {
        for i in 1...10 {
            let prevCount = sut.count
            let prevElements = sut.allStoredElements
            sut.push(i)
            XCTAssertEqual(sut.count, prevCount + 1)
            XCTAssertEqual(sut.allStoredElements, ([i] + prevElements))
            XCTAssertEqual(sut.first, i)
        }
        
        // let's also do this test when storage wraps around
        for headshift in 1...10 {
            sut = CircularBuffer.headShiftedInstance(contentsOf: (1...10).shuffled(), headShift: headshift)
            let prevCount = sut.count
            let prevElements = sut.allStoredElements
            let newElement = headshift * 10
            sut.push(newElement)
            XCTAssertEqual(sut.count, prevCount + 1)
            XCTAssertEqual(sut.allStoredElements, ([newElement] + prevElements))
            XCTAssertEqual(sut.first, newElement)
        }
    }
    
    func testPush_whenIsFull() {
        for k in 1...100 where CircularBuffer<Int>.smartCapacityFor(count: k) == k {
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            let prevCapacity = sut.capacity
            sut.push(2000)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, prevCapacity << 1)
            
            // let's also do this test when storage wraps around
            for headShift in 1..<k {
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                let prevCapacity = sut.capacity
                sut.push(2000)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, prevCapacity << 1)
            }
        }
    }
    
    // MARK: - push(contentsOf:) tests
    func testPushContentsOf_whenSequenceImplementsWithContiguousStorageIfAvailable() {
        // sut isEmpty == true
        // newElements.isEmpty == true
        XCTAssertTrue(sut.isEmpty)
        var newElements: Array<Int> = []
        sut.push(contentsOf: TestSequence(elements: newElements))
        XCTAssertTrue(sut.isEmpty)
        
        // sut isEmpty == true
        // newElements.isEmpty == false
        XCTAssertTrue(sut.isEmpty)
        newElements = (1...100).shuffled()
        sut.push(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, newElements.reversed())
        
        // sut.isEmpty == false
        // newElements.isEmpty == true
        let sutElements = (101...200).shuffled()
        sut = CircularBuffer(elements: sutElements)
        newElements = []
        sut.push(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.push(contentsOf: TestSequence(elements: newElements))
            XCTAssertEqual(sut.allStoredElements, sutElements)
        }
        
        // sut.isEmpty == false
        // newElements.isEmpty == false
        sut = CircularBuffer(elements: sutElements)
        newElements = (1...100).shuffled()
        sut.push(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, newElements.reversed() + sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.push(contentsOf: TestSequence(elements: newElements))
            XCTAssertEqual(sut.allStoredElements, newElements.reversed() + sutElements)
        }
    }
    
    func testPushContentsOf_whenSequenceDoesntImplementWithContiguousStorageIfAvailable() {
        // sut isEmpty == true
        // newElements.isEmpty == true
        XCTAssertTrue(sut.isEmpty)
        var newElements: Array<Int> = []
        sut.push(contentsOf: AnySequence(newElements))
        XCTAssertTrue(sut.isEmpty)
        
        // sut isEmpty == true
        // newElements.isEmpty == false
        XCTAssertTrue(sut.isEmpty)
        newElements = (1...100).shuffled()
        sut.push(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, newElements.reversed())
        
        // sut.isEmpty == false
        // newElements.isEmpty == true
        let sutElements = (101...200).shuffled()
        sut = CircularBuffer(elements: sutElements)
        newElements = []
        sut.push(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.push(contentsOf: AnySequence(newElements))
            XCTAssertEqual(sut.allStoredElements, sutElements)
        }
        
        // sut.isEmpty == false
        // newElements.isEmpty == false
        sut = CircularBuffer(elements: sutElements)
        newElements = (1...100).shuffled()
        sut.push(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, newElements.reversed() + sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.push(contentsOf: AnySequence(newElements))
            XCTAssertEqual(sut.allStoredElements, newElements.reversed() + sutElements)
        }
        
        // We're also gonna test with a sequence which returns 0 as
        // its underestimatedCount value even if its lenght is greater than zero:
        let seq = AnySequence { () -> AnyIterator<Int> in
            var idx = 0
            
            return AnyIterator {
                guard idx < newElements.count else { return nil }
                
                defer { idx += 1 }
                
                return newElements[idx]
            }
        }
        XCTAssertEqual(seq.underestimatedCount, 0)
        sut = CircularBuffer(elements: sutElements)
        sut.push(contentsOf: seq)
        XCTAssertEqual(sut.allStoredElements, newElements.reversed() + sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.push(contentsOf: seq)
            XCTAssertEqual(sut.allStoredElements, newElements.reversed() + sutElements)
        }
    }
    
    func testPushContentsOf_whenIsFull() {
        let newElements = (101...200).shuffled()
        // We're also gonna test with a sequence which returns 0 as
        // its underestimatedCount value even if its lenght is greater than zero:
        let seq = AnySequence { () -> AnyIterator<Int> in
            var idx = 0
            
            return AnyIterator {
                guard idx < newElements.count else { return nil }
                
                defer { idx += 1 }
                
                return newElements[idx]
            }
        }
        
        for k in 1...100 where CircularBuffer<Int>.smartCapacityFor(count: k) == k {
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            var prevCapacity = sut.capacity
            // newElements implements withContiguousStorageIfAvailable
            sut.push(contentsOf: newElements)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            // newElements doesn't implement withContiguousStorageIfAvailable
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            prevCapacity = sut.capacity
            sut.push(contentsOf: AnySequence(newElements))
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            prevCapacity = sut.capacity
            sut.push(contentsOf: seq)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            // let's also do this test when storage wraps around
            for headShift in 1..<k {
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                // newElements implements withContiguousStorageIfAvailable
                sut.push(contentsOf: newElements)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
                
                // newElements doesn't implement withContiguousStorageIfAvailable
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                sut.push(contentsOf: AnySequence(newElements))
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
                
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                sut.push(contentsOf: seq)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            }
        }
    }
    
    func testPushContentsOf_whenResidualCapacityIsEnoughToStoreNewElements() {
        let sutElements = (101...200).shuffled()
        let newElementsStorage = (1..<(CircularBuffer<Int>.smartCapacityFor(count: sutElements.count) - sutElements.count)).shuffled()
        XCTAssertFalse(newElementsStorage.isEmpty)
        
        // sequence implements withContiguousStorageIfAvailable
        var newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: true, underEstimatedCountMatchesCount: true)
        sut = CircularBuffer(elements: sutElements)
        var prevCapacity = sut.capacity
        var prevSutElementsAddress = sut.elements
        sut.push(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // sequence doesn't implements withContiguousStorageIfAvailable
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: true)
        sut = CircularBuffer(elements: sutElements)
        prevCapacity = sut.capacity
        prevSutElementsAddress = sut.elements
        sut.push(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // sequence doesn't implements withContiguousStorageIfAvailable and
        // its underestimatedCount is zero despite it stores some elements
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: false)
        sut = CircularBuffer(elements: sutElements)
        prevCapacity = sut.capacity
        prevSutElementsAddress = sut.elements
        sut.push(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // let's also do these tests when storage wraps around
        for headShift in 1..<sutElements.count {
            // sequence implements withContiguousStorageIfAvailable
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: true, underEstimatedCountMatchesCount: true)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.push(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
            
            // sequence doesn't implements withContiguousStorageIfAvailable
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: true)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.push(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
            
            // sequence doesn't implements withContiguousStorageIfAvailable and
            // its underestimatedCount is zero despite it stores some elements
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: false)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.push(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
        }
    }
    
    // MARK: - prepend(contentsOf:) tests
    func testPrependContentsOf_whenSequenceImplementsWithContiguousStorageIfAvailable() {
        // sut isEmpty == true
        // newElements.isEmpty == true
        XCTAssertTrue(sut.isEmpty)
        var newElements: Array<Int> = []
        sut.prepend(contentsOf: TestSequence(elements: newElements))
        XCTAssertTrue(sut.isEmpty)
        
        // sut isEmpty == true
        // newElements.isEmpty == false
        XCTAssertTrue(sut.isEmpty)
        newElements = (1...100).shuffled()
        sut.prepend(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, newElements)
        
        // sut.isEmpty == false
        // newElements.isEmpty == true
        let sutElements = (101...200).shuffled()
        sut = CircularBuffer(elements: sutElements)
        newElements = []
        sut.prepend(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.prepend(contentsOf: TestSequence(elements: newElements))
            XCTAssertEqual(sut.allStoredElements, sutElements)
        }
        
        // sut.isEmpty == false
        // newElements.isEmpty == false
        sut = CircularBuffer(elements: sutElements)
        newElements = (1...100).shuffled()
        sut.prepend(contentsOf: TestSequence(elements: newElements))
        XCTAssertEqual(sut.allStoredElements, newElements + sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.prepend(contentsOf: TestSequence(elements: newElements))
            XCTAssertEqual(sut.allStoredElements, newElements + sutElements)
        }
    }
    
    func testPrependContentsOf_whenSequenceDoesntImplementWithContiguousStorageIfAvailable() {
        // sut isEmpty == true
        // newElements.isEmpty == true
        XCTAssertTrue(sut.isEmpty)
        var newElements: Array<Int> = []
        sut.prepend(contentsOf: AnySequence(newElements))
        XCTAssertTrue(sut.isEmpty)
        
        // sut isEmpty == true
        // newElements.isEmpty == false
        XCTAssertTrue(sut.isEmpty)
        newElements = (1...100).shuffled()
        sut.prepend(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, newElements)
        
        // sut.isEmpty == false
        // newElements.isEmpty == true
        let sutElements = (101...200).shuffled()
        sut = CircularBuffer(elements: sutElements)
        newElements = []
        sut.prepend(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.prepend(contentsOf: AnySequence(newElements))
            XCTAssertEqual(sut.allStoredElements, sutElements)
        }
        
        // sut.isEmpty == false
        // newElements.isEmpty == false
        sut = CircularBuffer(elements: sutElements)
        newElements = (1...100).shuffled()
        sut.prepend(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.allStoredElements, newElements + sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.prepend(contentsOf: AnySequence(newElements))
            XCTAssertEqual(sut.allStoredElements, newElements + sutElements)
        }
        
        // We're also gonna test with a sequence which returns 0 as
        // its underestimatedCount value even if its lenght is greater than zero:
        let seq = AnySequence { () -> AnyIterator<Int> in
            var idx = 0
            
            return AnyIterator {
                guard idx < newElements.count else { return nil }
                
                defer { idx += 1 }
                
                return newElements[idx]
            }
        }
        XCTAssertEqual(seq.underestimatedCount, 0)
        sut = CircularBuffer(elements: sutElements)
        sut.prepend(contentsOf: seq)
        XCTAssertEqual(sut.allStoredElements, newElements + sutElements)
        // let's also do this test when storage wraps around
        for headShift in 1...sutElements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            sut.prepend(contentsOf: seq)
            XCTAssertEqual(sut.allStoredElements, newElements + sutElements)
        }
    }
    
    func testPrependContentsOf_whenIsFull() {
        let newElements = (101...200).shuffled()
        // We're also gonna test with a sequence which returns 0 as
        // its underestimatedCount value even if its lenght is greater than zero:
        let seq = AnySequence { () -> AnyIterator<Int> in
            var idx = 0
            
            return AnyIterator {
                guard idx < newElements.count else { return nil }
                
                defer { idx += 1 }
                
                return newElements[idx]
            }
        }
        
        for k in 1...100 where CircularBuffer<Int>.smartCapacityFor(count: k) == k {
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            var prevCapacity = sut.capacity
            // newElements implements withContiguousStorageIfAvailable
            sut.prepend(contentsOf: newElements)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            // newElements doesn't implement withContiguousStorageIfAvailable
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            prevCapacity = sut.capacity
            sut.prepend(contentsOf: AnySequence(newElements))
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            sut = CircularBuffer(elements: 1...k)
            XCTAssertTrue(sut.isFull)
            prevCapacity = sut.capacity
            sut.prepend(contentsOf: seq)
            XCTAssertGreaterThan(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            
            // let's also do this test when storage wraps around
            for headShift in 1..<k {
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                // newElements implements withContiguousStorageIfAvailable
                sut.prepend(contentsOf: newElements)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
                
                // newElements doesn't implement withContiguousStorageIfAvailable
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                sut.prepend(contentsOf: AnySequence(newElements))
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
                
                sut = CircularBuffer.headShiftedInstance(contentsOf: Array(1...k), headShift: headShift)
                XCTAssertTrue(sut.isFull)
                prevCapacity = sut.capacity
                sut.prepend(contentsOf: seq)
                XCTAssertGreaterThan(sut.capacity, prevCapacity)
                XCTAssertEqual(sut.capacity, CircularBuffer<Int>.smartCapacityFor(count: k + newElements.count))
            }
        }
    }
    
    func testPrependContentsOf_whenResidualCapacityIsEnoughToStoreNewElements() {
        let sutElements = (101...200).shuffled()
        let newElementsStorage = (1..<(CircularBuffer<Int>.smartCapacityFor(count: sutElements.count) - sutElements.count)).shuffled()
        XCTAssertFalse(newElementsStorage.isEmpty)
        
        // sequence implements withContiguousStorageIfAvailable
        var newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: true, underEstimatedCountMatchesCount: true)
        sut = CircularBuffer(elements: sutElements)
        var prevCapacity = sut.capacity
        var prevSutElementsAddress = sut.elements
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // sequence doesn't implements withContiguousStorageIfAvailable
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: true)
        sut = CircularBuffer(elements: sutElements)
        prevCapacity = sut.capacity
        prevSutElementsAddress = sut.elements
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // sequence doesn't implements withContiguousStorageIfAvailable and
        // its underestimatedCount is zero despite it stores some elements
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: false)
        sut = CircularBuffer(elements: sutElements)
        prevCapacity = sut.capacity
        prevSutElementsAddress = sut.elements
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevSutElementsAddress)
        
        // let's also do these tests when storage wraps around
        for headShift in 1..<sutElements.count {
            // sequence implements withContiguousStorageIfAvailable
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: true, underEstimatedCountMatchesCount: true)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.prepend(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
            
            // sequence doesn't implements withContiguousStorageIfAvailable
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: true)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.prepend(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
            
            // sequence doesn't implements withContiguousStorageIfAvailable and
            // its underestimatedCount is zero despite it stores some elements
            sut = CircularBuffer.headShiftedInstance(contentsOf: sutElements, headShift: headShift)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false, underEstimatedCountMatchesCount: false)
            prevCapacity = sut.capacity
            prevSutElementsAddress = sut.elements
            sut.prepend(contentsOf: newElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            XCTAssertEqual(sut.elements, prevSutElementsAddress)
        }
    }
    
    // MARK: - pushFront(_:) tests
    func testPushFront() {
        sut = CircularBuffer(capacity: 0, usingSmartCapacityPolicy: false)
        // when capacity is 0 nothing happens:
        XCTAssertEqual(sut.capacity, 0)
        sut.pushFront(10)
        XCTAssertEqual(sut.capacity, 0)
        
        // when residualCapacity is greater than 0, then element is stored as new first:
        sut.reserveCapacity(5, usingSmartCapacityPolicy: false)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        let expectedCapacity = sut.capacity
        var newElement = 1
        var expectedResult: Array<Int> = []
        while sut.residualCapacity > 0 {
            expectedResult.insert(newElement, at: 0)
            sut.pushFront(newElement)
            XCTAssertEqual(sut.first, newElement)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            
            newElement += 1
        }
        
        // when residualCapacity is equal to 0, then element is stored as new first, and
        // old first gets trumped:
        XCTAssertEqual(sut.residualCapacity, 0)
        newElement = 10
        for i in 1...10 {
            let _ = expectedResult.popLast()
            expectedResult.insert(newElement, at: 0)
            sut.pushFront(newElement)
            XCTAssertEqual(sut.first, newElement)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            
            newElement += i*10
        }
        
        // let's also do these tests when storage wraps around
        let preStored = (1...10).shuffled()
        for headShift in 1..<preStored.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: preStored, headShift: headShift)
            sut.reserveCapacity(5, usingSmartCapacityPolicy: false)
            XCTAssertGreaterThan(sut.residualCapacity, 0)
            // when residual capacity is greater than zero, then element is stored at
            // first position and elements previously stored don't get trumped:
            var newElement = 1
            while sut.residualCapacity > 0 {
                let prevElements = sut.allStoredElements
                sut.pushFront(newElement)
                XCTAssertEqual(sut.allStoredElements, [newElement] + prevElements)
                newElement += 1
            }
            XCTAssertEqual(sut.residualCapacity, 0)
            // when residualCapacity is equal to 0, then element is stored as new first,
            // and old last gets trumped:
            expectedResult = sut.allStoredElements
            for i in 1...sut.capacity {
                newElement = i * 100
                let _ = expectedResult.popLast()
                expectedResult.insert(newElement, at: 0)
                sut.pushFront(newElement)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
            }
        }
    }
    
    // MARK: - pushFront(contentsOf:) tests
    func testPushFrontContentsOf_whenCapacityIsZero() {
        // nothing happens whether newElements contains elements or is empty:
        sut = CircularBuffer(capacity: 0, usingSmartCapacityPolicy: false)
        XCTAssertTrue(sut.isEmpty)
        sut.pushFront(contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        sut.pushFront(contentsOf: 1...10)
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testPushFrontContentsOf_whenIsEmptyAndSequenceImplementsWithContiguousStorage() {
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        var sutPrevElements = sut.allStoredElements
        
        // newElements is empty
        var newElements = TestSequence<Int>(elements: [])
        sut.pushFront(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, sutPrevElements)
        
        // newElements is not empty and sut.residualCapacity is enough
        // to store all new elements:
        // then all sequence elements are pushed at sut first:
        var newElementsStorage = (1...sut.residualCapacity).shuffled()
        XCTAssertFalse(newElementsStorage.isEmpty)
        newElements = TestSequence(elements: newElementsStorage)
        sutPrevElements = sut.allStoredElements
        sut.pushFront(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, newElementsStorage.reversed() + sutPrevElements)
        
        // newElements is not empty and sut residualCapacity is not enough
        // to store all new elements:
        // then only last m elements are stored, where m is the sut capacity
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        newElementsStorage = (1...(sut.residualCapacity + 1)).shuffled()
        newElements = TestSequence(elements: newElementsStorage)
        sutPrevElements = sut.allStoredElements
        sut.pushFront(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, Array(newElementsStorage[(newElementsStorage.endIndex - sut.capacity)..<newElementsStorage.endIndex]).reversed())
    }
    
    func testPushFrontContentsOf_whenIsNotEmptyAndSequenceImplementsWithContiguousStorage() {
        var sutPrevStoredElements = (1...10).shuffled()
        sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
        
        // newElements is empty, nothing happens:
        sut.pushFront(contentsOf: [])
        XCTAssertEqual(sut.allStoredElements, sutPrevStoredElements)
        
        // newElements is not empty and sut.residualCapacity is greater zero:
        
        // when newElements lenght is less than or equal to sut.residualCapacity, then all
        // newElements get pushed at sut first:
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        var newElementsStorage = (11...20).shuffled()
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, newElementsStorage.count)
        var newElements = TestSequence(elements: newElementsStorage)
        sutPrevStoredElements = sut.allStoredElements
        sut.pushFront(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, newElementsStorage.reversed() + sutPrevStoredElements)
        // let's also do this test when sut storage wraps around
        for headShift in 1..<19 {
            sut = CircularBuffer(capacity: 20, usingSmartCapacityPolicy: false)
            let tail = sut.initializeElements(advancedToBufferIndex: headShift, from: (1...10).map { $0 * 10 } )
            sut.head = headShift
            sut.count = 10
            sut.tail = tail
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, newElementsStorage.count)
            newElements = TestSequence(elements: newElementsStorage)
            sutPrevStoredElements = sut.allStoredElements
            sut.pushFront(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, newElementsStorage.reversed() + sutPrevStoredElements)
        }
        
        // when newElements is not empty, and sut residual capacity is not enough to
        // store all newElements, then sequence elements are sequentially pushed
        // at sut first,
        // while sut drops elements from its back to make room for new elements:
        sutPrevStoredElements = sut.allStoredElements
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        newElementsStorage = (1...(sut.residualCapacity + 1)).map { $0 * 2000 }
        XCTAssertGreaterThan(newElementsStorage.count, sut.residualCapacity)
        // here we'll just trump previously stored elements to make room for new elements:
        sutPrevStoredElements = sut.allStoredElements
        var lastNew = newElementsStorage.last!
        for countOfTrumped in 1...sutPrevStoredElements.count {
            sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
            sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
            let expectedResult = newElementsStorage.reversed() + Array(sutPrevStoredElements[0..<(sutPrevStoredElements.endIndex - countOfTrumped)])
            newElements = TestSequence(elements: newElementsStorage)
            sut.pushFront(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            newElementsStorage.append(lastNew + 1)
            lastNew = newElementsStorage.last!
        }
        
        // From now on we'll have to trump all previously stored elements, and then
        // also newly stored elements to keep making room for new elements
        lastNew = newElementsStorage.last!
        for countOfTrumped in 1...sut.capacity {
            sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
            sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
            let expectedResult = Array(newElementsStorage.dropFirst(countOfTrumped).reversed())
            newElements = TestSequence(elements: newElementsStorage)
            sut.pushFront(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            newElementsStorage.append(lastNew + 1)
            lastNew = newElementsStorage.last!
        }
        
        // we also do these tests when sut storage wraps around
        for headShift in 1...19 {
            newElementsStorage = (1...11).map { $0 * 2000 }
            // here we'll just trump previously stored elements to make room for new elements:
            for countOfTrumped in 1...10 {
                XCTAssertGreaterThan(newElementsStorage.count, sut.residualCapacity)
                sut = CircularBuffer(capacity: 20, usingSmartCapacityPolicy: false)
                let tail = sut.initializeElements(advancedToBufferIndex: headShift, from: (1...10).map { $0 * 10 } )
                sut.head = headShift
                sut.count = 10
                sut.tail = tail
                sutPrevStoredElements = sut.allStoredElements
                let expectedResult = newElementsStorage.reversed() + Array(sutPrevStoredElements[0..<(sutPrevStoredElements.endIndex - countOfTrumped)])
                newElements = TestSequence(elements: newElementsStorage)
                sut.pushFront(contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                newElementsStorage.append(lastNew + 1)
                lastNew = newElementsStorage.last!
            }
            // From now on we'll have to trump all previously stored elements, and then
            // also newly stored elements to keep making room for new elements
            lastNew = newElementsStorage.last!
            for countOfTrumped in 1...sut.capacity {
                sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
                sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
                let expectedResult = Array(newElementsStorage.dropFirst(countOfTrumped).reversed())
                newElements = TestSequence(elements: newElementsStorage)
                sut.pushFront(contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                newElementsStorage.append(lastNew + 1)
                lastNew = newElementsStorage.last!
            }
        }
    }
    
    func testPushFrontContentsOf_whenIsEmptyAndSequenceDoesntImplementWithContiguousStorage() {
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        var sutPrevElements = sut.allStoredElements
        
        // newElements is empty
        var newElements = TestSequence<Int>(elements: [], implementsWithContiguousStorage: false)
        sut.pushFront(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, sutPrevElements)
        
        // newElements is not empty and sut.residualCapacity is enough
        // to store all new elements:
        // then all sequence elements are pushed to sut
        var newElementsStorage = (1...sut.residualCapacity).shuffled()
        XCTAssertFalse(newElementsStorage.isEmpty)
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
        sutPrevElements = sut.allStoredElements
        sut.pushFront(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, newElementsStorage.reversed() +  sutPrevElements)
        
        // newElements is not empty and sut residualCapacity is not enough
        // to store all new elements:
        // then only last m elements are stored, where m is the sut capacity
        sut = CircularBuffer(capacity: 10, usingSmartCapacityPolicy: false)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        newElementsStorage = (1...(sut.residualCapacity + 1)).shuffled()
        newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
        sutPrevElements = sut.allStoredElements
        sut.pushFront(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, Array(newElementsStorage[(newElementsStorage.endIndex - sut.capacity)..<newElementsStorage.endIndex]).reversed())
    }
    
    func testPushFrontContentsOf_whenIsNotEmptyAndSequenceDoesntImplementsWithContiguousStorage() {
        var sutPrevStoredElements = (1...10).shuffled()
        sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
        
        // newElements is empty, nothing happens:
        sut.pushFront(contentsOf: TestSequence(elements: [], implementsWithContiguousStorage: false))
        XCTAssertEqual(sut.allStoredElements, sutPrevStoredElements)
        
        // newElements is not empty and sut.residualCapacity is greater zero:
        
        // when newElements lenght is less than or equal to sut.residualCapacity, then all
        // newElements get pushed at sut first:
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        var newElementsStorage = (11...20).shuffled()
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, newElementsStorage.count)
        var newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
        sutPrevStoredElements = sut.allStoredElements
        sut.pushFront(contentsOf: newElements)
        XCTAssertEqual(sut.allStoredElements, newElementsStorage.reversed() + sutPrevStoredElements)
        // let's also do this test when sut storage wraps around
        for headShift in 1..<19 {
            sut = CircularBuffer(capacity: 20, usingSmartCapacityPolicy: false)
            let tail = sut.initializeElements(advancedToBufferIndex: headShift, from: (1...10).map { $0 * 10 } )
            sut.head = headShift
            sut.count = 10
            sut.tail = tail
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, newElementsStorage.count)
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
            sutPrevStoredElements = sut.allStoredElements
            sut.pushFront(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, newElementsStorage.reversed() + sutPrevStoredElements)
        }
        
        // when newElements is not empty, and sut residual capacity is not enough to
        // store all newElements, then sequence elements are sequentially
        // pushed at sut front, while sut drops elements from its back
        // to make room for new elements:
        sutPrevStoredElements = sut.allStoredElements
        sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
        newElementsStorage = (1...(sut.residualCapacity + 1)).map { $0 * 2000 }
        XCTAssertGreaterThan(newElementsStorage.count, sut.residualCapacity)
        // here we'll just trump previously stored elements to make room for new elements:
        sutPrevStoredElements = sut.allStoredElements
        var lastNew = newElementsStorage.last!
        for countOfTrumped in 1...sutPrevStoredElements.count {
            sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
            sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
            let expectedResult = newElementsStorage.reversed() + Array(sutPrevStoredElements[0..<(sutPrevStoredElements.endIndex - countOfTrumped)])
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
            sut.pushFront(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            newElementsStorage.append(lastNew + 1)
            lastNew = newElementsStorage.last!
        }
        
        // From now on we'll have to trump all previously stored elements, and then
        // also newly stored elements to keep making room for new elements
        lastNew = newElementsStorage.last!
        for countOfTrumped in 1...sut.capacity {
            sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
            sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
            let expectedResult = Array(newElementsStorage.dropFirst(countOfTrumped).reversed())
            newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
            sut.pushFront(contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            newElementsStorage.append(lastNew + 1)
            lastNew = newElementsStorage.last!
        }
        
        // we also do these tests when sut storage wraps around
        for headShift in 1...19 {
            newElementsStorage = (1...11).map { $0 * 2000 }
            // here we'll just trump previously stored elements to make room for new elements:
            for countOfTrumped in 1...10 {
                XCTAssertGreaterThan(newElementsStorage.count, sut.residualCapacity)
                sut = CircularBuffer(capacity: 20, usingSmartCapacityPolicy: false)
                let tail = sut.initializeElements(advancedToBufferIndex: headShift, from: (1...10).map { $0 * 10 } )
                sut.head = headShift
                sut.count = 10
                sut.tail = tail
                sutPrevStoredElements = sut.allStoredElements
                let expectedResult = newElementsStorage.reversed() + Array(sutPrevStoredElements[0..<(sutPrevStoredElements.endIndex - countOfTrumped)])
                newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
                sut.pushFront(contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                newElementsStorage.append(lastNew + 1)
                lastNew = newElementsStorage.last!
            }
            // From now on we'll have to trump all previously stored elements, and then
            // also newly stored elements to keep making room for new elements
            lastNew = newElementsStorage.last!
            for countOfTrumped in 1...sut.capacity {
                sut = CircularBuffer(elements: sutPrevStoredElements, usingSmartCapacityPolicy: false)
                sut.reserveCapacity(10, usingSmartCapacityPolicy: false)
                let expectedResult = Array(newElementsStorage.dropFirst(countOfTrumped).reversed())
                newElements = TestSequence(elements: newElementsStorage, implementsWithContiguousStorage: false)
                sut.pushFront(contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
                
                newElementsStorage.append(lastNew + 1)
                lastNew = newElementsStorage.last!
            }
        }
    }
    
    // MARK: - insertAt(index:ContentsOf:)
    func testInsertAt_whenNewElementsIsEmpty() {
        XCTAssertEqual(sut.count, 0)
        sut.insertAt(index: sut.count, contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        
        sut = CircularBuffer(elements: 1...4)
        let containedElements = sut.allStoredElements
        for i in 0...sut.count {
            sut.insertAt(index: i, contentsOf: [])
            XCTAssertEqual(sut.count, containedElements.count)
            for j in 0..<sut.count {
                XCTAssertEqual(sut[j], containedElements[j])
            }
            // restore SUT state for next iteration:
            sut = CircularBuffer(elements: 1...4)
        }
    }
    
    func test_insertAt_whenNewElementsIsNotEmpty() {
        let newElements = 10...50
        sut = CircularBuffer(elements: 1...4)
        for i in 0...sut.count {
            var expectedResult = sut.allStoredElements
            expectedResult.insert(contentsOf: newElements, at: i)
            sut.insertAt(index: i, contentsOf: newElements)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
            
            // restore SUT state for next iteration:
            sut = CircularBuffer(elements: 1...4)
        }
        
        // Let's do the same test when storage wraps around:
        for headShift in 1...4 {
            for i in 0...4 {
                sut = CircularBuffer.headShiftedInstance(contentsOf: (1...4).shuffled(), headShift: headShift)
                var expectedResult = sut.allStoredElements
                expectedResult.insert(contentsOf: newElements, at: i)
                sut.insertAt(index: i, contentsOf: newElements)
                XCTAssertEqual(sut.allStoredElements, expectedResult)
            }
        }
    }
    
    func testInsertAt_whenLeftCapacityIsSufficientToStoreNewElements() {
        sut = CircularBuffer(elements: 1...5)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        let newElements = (1...sut.residualCapacity).map { $0 * 10 }
        for i in 0..<sut.count {
            let prevSutElementsBaseAddress = sut.elements
            sut.insertAt(index: i, contentsOf: newElements)
            XCTAssertEqual(sut.elements, prevSutElementsBaseAddress)
            
            // restore SUT state for next iteration:
            sut = CircularBuffer(elements: 1...5)
        }
    }
}

struct TestSequence<Element>: Sequence {
    let containedElements: [Element]
    
    let implementsWithContiguousStorage: Bool
    
    let underEstimatedCountMatchesCount: Bool
    
    init(elements: [Element], implementsWithContiguousStorage: Bool = true, underEstimatedCountMatchesCount: Bool = true) {
        self.containedElements = elements
        self.implementsWithContiguousStorage = implementsWithContiguousStorage
        self.underEstimatedCountMatchesCount = underEstimatedCountMatchesCount
    }
    
    var underestimatedCount: Int { return underEstimatedCountMatchesCount ? containedElements.count : 0 }
    
    func makeIterator() -> AnyIterator<Element> {
        var idx = 0
        
        return AnyIterator {
            guard idx < containedElements.count else { return nil }
            
            defer { idx += 1 }
            
            return containedElements[idx]
        }
    }
    
    func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
        guard implementsWithContiguousStorage else { return nil }
        
        return try containedElements.withUnsafeBufferPointer(body)
    }
    
}
