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
    /// Eventually reduces the capacity of the buffer after the replace operation have occured, in case it will significally
    /// reduce the `count` value in respect to the current buffer capacity.
    /// Increases the buffer capacity when the operation will result in a `count` value larger than actual buffer capacity.
    ///
    /// When given `subrange.count` equals `0` –i.e. `0..<0`–, the given elements are inserted at the index
    /// position represented by the `subrange.lowerBound` –i.e. for `0..<0` elements are prepended in the storage.
    /// When given `subrange.count` is greater than `0` –i.e. `0..<2`–, but the given colletion of elements for
    ///  replacement is empty, then elements at the indexes in `subrange` are removed.
    /// - Parameter subrange:   A `Range<Int>`expression  representing the indexes of elements to replace.
    ///                         Must be in range of `0`...`count`.
    /// - Parameter with:   A collection of `Element` to insert in the storage as replacement of those elements
    ///                     stored at the given `subrange` indexes.
    public func replace<C: Collection>(subrange: Range<Int>, with newElements: C) where C.Iterator.Element == Element {
        precondition(subrange.lowerBound >= 0 && subrange.upperBound <= count, "range of indexes out of bounds")
        if subrange.count == 0 {
            // It's an insertion
            guard !newElements.isEmpty else { return }
            
            if subrange.lowerBound == 0 {
                // newElements have to be prepended
                prepend(contentsOf: newElements)
            } else if subrange.lowerBound == count {
                // newElements have to be appended
                append(contentsOf: newElements)
            } else {
                // newElements have to be inserted
                insertAt(index: subrange.lowerBound, contentsOf: newElements)
            }
        } else {
            // subRange count is greater than zero…
            if newElements.isEmpty {
                // …But the given colletion is empty.
                // It's a delete operation involving the _elements at indexes in subrange
                if subrange.lowerBound == 0 {
                    removeFirst(subrange.count, keepCapacity: false)
                } else if subrange.upperBound == count {
                    removeLast(subrange.count, keepCapacity: false)
                } else {
                    removeAt(index: subrange.lowerBound, count: subrange.count, keepCapacity: false)
                }
            } else {
                // It's a replace operation!
                let newCount = count - subrange.count + newElements.count
                let newCapacity = Self.smartCapacityFor(count: newCount)
                if newCapacity == capacity {
                    // No resize is needed, operation has to be done in place
                    let buffIdx = bufferIndex(from: subrange.lowerBound)
                    let countOfElementsToShift = count - subrange.lowerBound - subrange.count
                    // Deinitialize the elements to remove obtaining the buffer index to
                    // the first element that eventually gets shifted:
                    let bufIdxOfFirstElementToShift = deinitializeElements(advancedToBufferIndex: buffIdx, count: subrange.count)
                    
                    let lastBuffIdx: Int!
                    if countOfElementsToShift > 0 {
                        // We've got some elements to shift in the process.
                        // Let's move them temporarly out:
                        let swap = UnsafeMutablePointer<Element>.allocate(capacity: countOfElementsToShift)
                        moveInitialzeFromElements(advancedToBufferIndex: bufIdxOfFirstElementToShift, count: countOfElementsToShift, to: swap)
                        
                        // Let's put newElements in place obtaining the buffer index
                        // where to put back the shifted elements:
                        let newBuffIdxForShifted = initializeElements(advancedToBufferIndex: buffIdx, from: newElements)
                        
                        // Let's now put back th eelements that were shifted, obtaining
                        // the bufferIndex for calculating the new _tail:
                        lastBuffIdx = moveInitializeToElements(advancedToBufferIndex: newBuffIdxForShifted, from: swap, count: countOfElementsToShift)
                        swap.deallocate()
                    } else {
                        // The operation doesn't involve any element to be shifted,
                        // thus let's just put in place newElements obtainig the buffer
                        // index for calculating the new _tail:
                        lastBuffIdx = initializeElements(advancedToBufferIndex: buffIdx, from: newElements)
                    }
                    // Update _elementsCount and _tail to new values
                    count = newCount
                    tail = incrementIndex(lastBuffIdx - 1)
                } else {
                    // Resize is needed…
                    let buffIdx = bufferIndex(from: subrange.lowerBound)
                    let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
                    
                    let countOfFirstSplit = subrange.lowerBound
                    let countOfSecondSplit = count - countOfFirstSplit - subrange.count
                    
                    // Deinitialize in _elements the replaced subrange and obtain the
                    // buffer index to second split of elements to move from _elements:
                    let secondSplitStartBuffIdx = deinitializeElements(advancedToBufferIndex: buffIdx, count: subrange.count)
                    
                    // Now move everything in newBuff…
                    // Eventually the first split from _elements:
                    var newBuffIdx = 0
                    if countOfFirstSplit > 0 {
                        moveInitialzeFromElements(advancedToBufferIndex: head, count: countOfFirstSplit, to: newBuff)
                        newBuffIdx += countOfFirstSplit
                    }
                    
                    // Then newElements:
                    newBuff.advanced(by: newBuffIdx).initialize(from: newElements)
                    newBuffIdx += newElements.count
                    
                    // Eventually the second split from _elements:
                    if countOfSecondSplit > 0 {
                        moveInitialzeFromElements(advancedToBufferIndex: secondSplitStartBuffIdx, count: countOfSecondSplit, to: newBuff.advanced(by: newBuffIdx))
                    }
                    
                    // deallocate and update _elements with newBuff:
                    elements.deallocate()
                    elements = newBuff
                    
                    // Update _capacity, _head, _elementsCount, _tail to new values:
                    capacity = newCapacity
                    head = 0
                    count = newCount
                    tail = incrementIndex(count - 1)
                }
            }
        }
    }
    
}


