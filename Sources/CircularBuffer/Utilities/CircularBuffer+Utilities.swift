//
//  CircularBuffer+Utilities.swift
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

// MARK: - Specific interface for tests and debug only
#if DEBUG
extension CircularBuffer {
    static func headShiftedInstance(contentsOf elements: [Element], headShift: Int) -> CircularBuffer {
        precondition(headShift > 0, "Head shift must be greater than 0")
        let minSmartCapacity = headShift >= elements.count ? smartCapacityFor(count: elements.count + 1) : smartCapacityFor(count: elements.count)
        let result = CircularBuffer(capacity: minSmartCapacity)
        result.tail = result.initializeElements(advancedToBufferIndex: headShift, from: elements)
        result.head = headShift
        result.count = elements.count
        
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
#endif
