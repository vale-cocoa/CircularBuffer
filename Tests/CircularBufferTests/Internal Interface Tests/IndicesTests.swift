//
//  IndicesTests.swift
//  CircularBufferTests
//
//  Created by Valeriano Della Longa on 2020/12/11.
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

final class IndicesTests: XCTestCase {
    var sut: CircularBuffer<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularBuffer<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    func testBufferIndexFrom() {
        let capacity = 16
        for headShift in 1..<capacity {
            sut = CircularBuffer.headShiftedEmptyInstance(capacity: capacity, headShift: headShift)
            for position in 0..<sut.capacity {
                let result = sut.bufferIndex(from: position)
                XCTAssertTrue(0..<sut.capacity ~= result)
                let expectedResult = headShift + position < capacity ? headShift + position : (headShift + position - capacity)
                XCTAssertEqual(result, expectedResult)
            }
        }
    }
    
    func testIncrementBufferIndex() {
        let capacity = 16
        for headShift in 1..<capacity {
            sut = CircularBuffer.headShiftedEmptyInstance(capacity: capacity, headShift: headShift)
            for bIdx in 0..<sut.capacity {
                let result = sut.incrementBufferIndex(bIdx)
                XCTAssertTrue(0..<sut.capacity ~= result)
            }
        }
    }
    
    
    func testDecrementBufferIndex() {
        let capacity = 16
        for headShift in 1..<capacity {
            sut = CircularBuffer.headShiftedEmptyInstance(capacity: capacity, headShift: headShift)
            for bIdx in 0..<sut.capacity {
                let result = sut.decrementBufferIndex(bIdx)
                XCTAssertTrue(0..<sut.capacity ~= result)
            }
        }
    }
    
    
    func testBufferIndexFromOffsetBy() {
        let capacity = 16
        for headShift in 1..<capacity {
            sut = CircularBuffer.headShiftedEmptyInstance(capacity: capacity, headShift: headShift)
            let doubledCapacity = sut.capacity * 2
            for bIdx in 0..<sut.capacity {
                for offset in stride(from: -doubledCapacity, through: doubledCapacity , by: 1) {
                    let result = sut.offsettedBufferIndex(from: bIdx, offsetBy: offset)
                    XCTAssertTrue(0..<sut.capacity ~= result)
                }
            }
        }
    }
    
}
