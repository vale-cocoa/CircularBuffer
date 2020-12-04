//
//  ContiguousBufferBased.swift
//  CircularBuffer
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

/// A type that implements `withUnsafeBufferPointer(_:)` method.
/// This protocol is an helper to allow slicing via `Swift.Slice` type `of Collection` value types implementing
/// `withContiguousStorageIfAvailable(_:)`, and of `RangeReplaceableCollection` value types
/// implementing `withContiguousMutableStorageIfAvailable(_:)`.
public protocol ContiguousBufferBased {
    associatedtype Element
    
    func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R
}

extension Slice where Base: ContiguousBufferBased {
    var bufferRange: Range<Int> {
        let lowerBound = distance(from: base.startIndex, to: startIndex)
        let upperBound = distance(from: base.startIndex, to: endIndex)
        
        return lowerBound..<upperBound
    }
    
    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
        try base
            .withUnsafeBufferPointer { buffer in
                let sliced = UnsafeBufferPointer(rebasing: buffer[bufferRange])
                
                return try body(sliced)
            }
    }
    
}

extension Slice where Base: ContiguousBufferBased, Base.Index == Int {
    var bufferRange: Range<Int> { startIndex..<endIndex }
    
}

extension Slice where Base: RangeReplaceableCollection, Base: ContiguousBufferBased {
    public mutating func withContiguousMutableStorageIfAvailable<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) rethrows -> R? {
        var work = Self()
        (work, self) = (self, work)
        
        defer {
            (work, self) = (self, work)
        }
        
        return try work.base.withUnsafeBufferPointer { immutableBuffer in
            let mutableBuffer = UnsafeMutableBufferPointer(mutating: immutableBuffer)
            var slicedMutableBuffer = UnsafeMutableBufferPointer(rebasing: mutableBuffer[bufferRange])
            let originalBaseAddress = slicedMutableBuffer.baseAddress
            let originalCount = slicedMutableBuffer.count
            defer {
                precondition(
                    slicedMutableBuffer.baseAddress == originalBaseAddress &&
                        slicedMutableBuffer.count == originalCount, "Slice withContiguousMutableStorageIfAvailable: replacing the buffer is not allowed"
                )
                var newWorkBase = work.base
                newWorkBase.replaceSubrange(work.startIndex..<work.endIndex, with: slicedMutableBuffer)
                work = Slice(base: newWorkBase, bounds: work.startIndex..<work.endIndex)
                slicedMutableBuffer.deallocate()
                mutableBuffer.deallocate()
            }
            
            return try body(&slicedMutableBuffer)
        }
    }
    
}
                      
