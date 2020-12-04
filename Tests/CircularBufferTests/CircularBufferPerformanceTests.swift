//
//  CircularBufferPerformanceTests.swift
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

final class CircularBufferPerformanceTests: XCTestCase {
    // MARK: - performance tests
    func testCircularBufferPerformance_smallCount() {
        measure(performanceLoopCircularBuffer_smallCount)
    }
    
    func testArrayPerformance_smallCount() {
        measure(performanceLoopArray_smallCount)
    }
    
    func testCircularBufferPerformance_largeCount() {
        measure(performanceLoopCircularBuffer_largeCount)
    }
    
    func testArrayPerformance_largeCount() {
        measure(performanceLoopArray_largeCount)
    }
    
    private func performanceLoopCircularBuffer_smallCount() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            let ringBuffer = CircularBuffer<Int>(capacity: innerCount)
            for i in 1...innerCount {
                ringBuffer.append(i)
                accumulator ^= (ringBuffer.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (ringBuffer.first ?? 0)
                ringBuffer.popFirst()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopArray_smallCount() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            var array = Array<Int>()
            array.reserveCapacity(innerCount)
            for i in 1...innerCount {
                array.append(i)
                accumulator ^= (array.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (array.first ?? 0)
                array.remove(at: 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopCircularBuffer_largeCount() {
        let outerCount: Int = 10
        let innerCount: Int = 20_000
        var accumulator = 0
        for _ in 1...outerCount {
            let ringBuffer = CircularBuffer<Int>(capacity: innerCount)
            for i in 1...innerCount {
                ringBuffer.append(i)
                accumulator ^= (ringBuffer.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (ringBuffer.first ?? 0)
                ringBuffer.popFirst()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopArray_largeCount() {
        let outerCount: Int = 10
        let innerCount: Int = 20_000
        var accumulator = 0
        for _ in 1...outerCount {
            var array = Array<Int>()
            array.reserveCapacity(innerCount)
            for i in 1...innerCount {
                array.append(i)
                accumulator ^= (array.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (array.first ?? 0)
                array.remove(at: 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
}
