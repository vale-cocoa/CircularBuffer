//
//  CircularBuffer+ReplaceElements.swift
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

// MARK: - Replace elements
extension CircularBuffer {
    /// Replaces the elements stored at given range with the ones in the given collection.
    ///
    /// Operations affecting the instance's final `capacity` value are done according the `keepCapacity`
    /// and `usingSmartCapacityPolicy` values specified in the call.
    /// It will —eventually— reduce the buffer `capacity`when `false` is specified as
    /// `keepCapacity` value and the operation will decrese the `count` value of the instance or if the `capacity` value
    /// would be —significally— greater than the `count` after the replace operation took effect.
    /// On the other hand, increases the buffer `capacity` when the replace operation will overflow the current `capacity` value.
    ///
    /// - Parameter subrange:   A `Range<Int>`expression  representing the indexes of elements to replace.
    ///                         **Must be in range of** `0...count`.
    /// - Parameter with:   A collection of `Element` to insert in the storage as replacement of those elements
    ///                     stored at the given `subrange` indexes.
    /// - Parameter keepCapacity:   A Boolean value. When set to `false` and the operation would result
    ///                             in a reduced `count` of elements, attempts to reduce the capacity level
    ///                             according to the `usingSmartCapacityPolicy` specified value.
    ///                             Otherwise when set to `true` and the operation would result in a reduced
    ///                             `count` value, then the `capacity`is left the same.
    ///                             **This parameter value as no effect when the operation will increase the count of stored elements, hence when an increased capacity value is needed to perform the operation.**
    ///                             **Defaults to true.**
    /// - Parameter usingSmartCapacityPolicy:   A Boolean value. When set to `true`,
    ///                                         the eventual resizing of the buffer `capacity`
    ///                                         value is done by adopting the smart capacity policy.
    ///                                         Otherwise, when set to `false`, the eventual resize of the
    ///                                         buffer `capacity` value will match exctly the instance's
    ///                                         `count` value after the replace operation.
    ///                                         **Defaults to true**.
    @inlinable
    public func replace<C: Collection>(subrange: Range<Int>, with newElements: C, keepCapacity: Bool = true, usingSmartCapacityPolicy: Bool = true) where Element == C.Iterator.Element
    {
        precondition(subrange.lowerBound >= 0 && subrange.upperBound <= count, "range of indexes out of bounds")
        if subrange.count == 0 {
            // It's an insertion
            if subrange.lowerBound == 0 {
                // newElements gets prependend
                prepend(contentsOf: newElements, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
            } else if subrange.lowerBound == count {
                // newElements gets appended
                append(contentsOf: newElements, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
                
            } else {
                // newElements gets inserted
                insertAt(index: subrange.lowerBound, contentsOf: newElements, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
            }
        } else {
            // subRange count is greater than zero…
            if newElements.isEmpty {
                // …But the given colletion is empty.
                // It's a delete operation involving the elements at indexes in subrange
                if subrange.lowerBound == 0 {
                    removeFirst(subrange.count, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
                } else if subrange.upperBound == count {
                    removeLast(subrange.count, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
                } else {
                    removeAt(index: subrange.lowerBound, count: subrange.count, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
                }
            } else {
                // It's a replace operation!
                let newElementsCount = newElements.count
                let newCount = count - subrange.count + newElementsCount
                let newCapacity = capacityFor(newCount: newCount, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
                if newCapacity == capacity {
                    // we must do the replace in place without resizing the buffer
                    fastInPlaceReplaceElements(subrange: subrange, with: newElements)
                } else {
                    // we must resize the buffer
                    fastResizeElements(to: newCapacity, replacing: subrange, with: newElements)
                }
            }
        }
    }
    
}


