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
    var sut: (outerCount: Int, innerCount: Int)!
    
    // MARK: - performance tests
    func testCircularBufferPerformance_smallCount() {
        whenSmallCount()
        measure { performanceLoop(for: .circularBuffer) }
    }
    
    func testArrayPerformance_smallCount() {
        whenSmallCount()
        measure { performanceLoop(for: .array) }
    }
    
    func testCircularBufferPerformance_largeCount() {
        whenLargeCount()
        measure { performanceLoop(for: .circularBuffer) }
    }
    
    func testArrayPerformance_largeCount() {
        whenLargeCount()
        measure { performanceLoop(for: .array) }
    }
    
    private func whenSmallCount() {
        sut = (10_000, 20)
    }
    
    private func whenLargeCount() {
        sut = (10, 20_000)
    }
    
    private func performanceLoop(for kind: KindOfTestable) {
        var accumulator = 0
        for _ in 1...sut.outerCount {
            var testable = kind.newTestable(capacity: sut.innerCount)
            for i in 1...sut.innerCount {
                testable.enqueue(i)
                accumulator ^= (testable.last ?? 0)
            }
            for _ in 1...sut.innerCount {
                accumulator ^= (testable.first ?? 0)
                testable.dequeue()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private enum KindOfTestable {
        case circularBuffer
        case array
        
        func newTestable(capacity: Int) -> PerformanceTestable {
            switch self {
            case .circularBuffer:
                return CircularBuffer<Int>(capacity: capacity)
            case .array:
                return Array<Int>(capacity: capacity)
            }
        }
    }
    
}

fileprivate protocol PerformanceTestable {
    init(capacity: Int)
    
    var first: Int? { get }
    
    var last: Int? { get }
    
    mutating func enqueue(_ newElement: Int)
    
    @discardableResult
    mutating func dequeue() -> Int?
}

extension CircularBuffer: PerformanceTestable where Element == Int{
    convenience init(capacity: Int) {
        self.init(capacity: capacity, usingSmartCapacityPolicy: true)
    }
    
    func enqueue(_ newElement: Element) {
        append(newElement)
    }
    
    func dequeue() -> Element? {
        popFirst()
    }
    
}

extension Array: PerformanceTestable where Element == Int {
    init(capacity: Int) {
        self.init()
        reserveCapacity(capacity)
    }
    
    mutating func enqueue(_ newElement: Element) {
        append(newElement)
    }
    
    mutating func dequeue() -> Element? {
        isEmpty ? nil : removeFirst()
    }
    
}
