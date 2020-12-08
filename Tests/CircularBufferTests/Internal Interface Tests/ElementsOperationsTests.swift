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
    
    // MARK: - makeElementsContiguous() tests
    func testFastShiftWrappingElements() {
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
    
}







































