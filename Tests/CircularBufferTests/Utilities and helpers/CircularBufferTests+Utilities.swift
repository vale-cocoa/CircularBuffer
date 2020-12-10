//
//  CircularBufferTests+Utilities.swift
//  CircularBufferTests
//
//  Created by Valeriano Della Longa on 2020/12/03.
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

extension CircularBuffer {
    static func headShiftedInstance(contentsOf containedElements: [Element], headShift: Int) -> CircularBuffer {
        assert(headShift >= 0)
        let minSmartCapacity = headShift >= containedElements.count ? smartCapacityFor(count: containedElements.count + 1) : smartCapacityFor(count: containedElements.count)
        let result = CircularBuffer(capacity: minSmartCapacity)
        result.tail = result.unsafeInitializeElements(advancedToBufferIndex: headShift, from: containedElements)
        result.head = headShift
        result.count = containedElements.count
        
        return result
    }
    
    static func headShiftedEmptyInstance(capacity: Int, headShift: Int, usingSmartCapacityPolicy: Bool = true) -> CircularBuffer {
        assert(capacity >= 0 && headShift >= 0)
        let result = CircularBuffer(capacity: capacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
        result.head = headShift % result.capacity
        result.tail = result.head
        
        return result
    }
    
    var allStoredElements: [Element] {
        var result = [Element]()
        for idx in 0..<count {
            let buffIdx = bufferIndex(from: idx)
            result.append(elements.advanced(by: buffIdx).pointee)
        }
        
        return result
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

let minSmartCapacity = CircularBuffer<Int>.minSmartCapacity

let testsThrownError = NSError(domain: "com.vdl.circularBuffer", code: 1, userInfo: nil)

let throwingBody: (Int) throws -> Void = { _ in throw testsThrownError }

let isEvenPredicate: (Int) -> Bool = { $0 % 2 == 0 }

let throwingPredicate: (Int) throws -> Bool = { _ in throw testsThrownError }

let multiplyByTenTransform: (Int) -> Int = { $0 * 10 }

let throwingTransform: (Int) throws -> Int = { _ in throw testsThrownError }

let isEvenOptionalTransform: (Int) -> Int? = { isEvenPredicate($0) ? $0 : nil }

let throwingOptionalTransform: (Int) throws -> Int? = { _ in throw testsThrownError }
