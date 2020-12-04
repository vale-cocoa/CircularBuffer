//
//  CircularBuffer+AddElements.swift
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

// MARK: - Add new elements
extension CircularBuffer {
    // MARK: - Appending
    /// Stores the given element at the last position of the storage.
    ///
    /// - Parameter _: The element to store.
    /// - Complexity: Amortized O(1).
    /// - Note: When `isFull` is `true`, grows the capacity of the storage so it can hold the new count of elements.
    public func append(_ newElement: Element) {
        if isFull {
            growToNextSmartCapacityLevel()
        }
        elements.advanced(by: tail).initialize(to: newElement)
        tail = incrementIndex(tail)
        count += 1
    }
    
    /// Stores the given sequence of elements starting at the last position of the storage.
    ///
    /// - Parameter contentsOf: A sequence of elements to append.
    /// - Note: Calls iteratively `append(:_)` for each element of the given sequence.
    ///         Capacity is grown when necessary to hold all new elements.
    ///         A better appending performance is obtained when the given sequence's `underestimatedCount`
    ///         value is the closest to the real count of elements of the sequence.
    @inline(__always)
    public func append<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    append(contentsOf: buff)
                    
                    return true
                })
        else {
            var elementsIterator = newElements.makeIterator()
            guard
                let firstNewElement = elementsIterator.next()
                else { return }
            
            let additionalElementsCount = newElements.underestimatedCount - residualCapacity
            if additionalElementsCount > 0 {
                let newCapacity = Self.smartCapacityFor(count: capacity + additionalElementsCount)
                fastResizeElements(to: newCapacity)
            }
            append(firstNewElement)
            while let nextNewElement = elementsIterator.next() {
                append(nextNewElement)
            }
            
            return
        }
    }
    
    @usableFromInline
    internal func append<C: Collection>(contentsOf newElements: C) where C.Iterator.Element == Element {
        guard newElements.count > 0 else { return }
        
        if count + newElements.count <= capacity
        {
            // actual buffer can hold all elements, thus append newElements in place
            let finalBufIdx = initializeElements(advancedToBufferIndex: tail, from: newElements)
            count += newElements.count
            tail = incrementIndex(finalBufIdx - 1)
        } else {
            // resize buffer to the right capacity and append newElements
            let newCapacity = Self.smartCapacityFor(count: capacity + newElements.count)
            fastResizeElements(to: newCapacity, insert: newElements, at: count)
        }
    }
    
    // MARK: - Prepending
    /// Stores given element at the first position of the storage.
    ///
    /// - Parameter _: The element to store.
    /// - Complexity: Amortized O(1)
    /// - Note: When `isFull` is `true`, grows the capacity of the storage so it can hold the new count of elements.
    public func push(_ newElement: Element) {
        if isFull {
            growToNextSmartCapacityLevel()
        }
        head = decrementIndex(head)
        elements.advanced(by: head).initialize(to: newElement)
        count += 1
    }
    
    /// Stores the given sequence of elements at the first position of the storage.
    ///
    /// Since the sequence is iterated and at each iteration an element is pushed, the elements will appear in
    /// reversed order inside the `CircularBuffer`:
    /// ```
    /// let sequence = AnySequence(1..<4)
    /// let buffer = CircularBuffer<Int>()
    /// buffer.push(contentsOf: sequence)
    /// // buffer's storage: [3, 2, 1]
    /// ```
    /// - Parameter contentsOf: A sequence of elements to push.
    /// - Note: Calls iteratively `push(:_)` for each element of the given sequence.
    ///         Capacity is grown when necessary to hold all new elements.
    ///         A better appending performance is obtained when the given sequence's `underestimatedCount`
    ///         value is the closest to the real count of elements of the sequence.
    public func push<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    prepend(contentsOf: buff.reversed())
                    
                    return true
                })
        else {
            var elementsIterator = newElements.makeIterator()
            guard
                let firstNewElement = elementsIterator.next()
                else { return }
            
            let additionalElementsCount = newElements.underestimatedCount - residualCapacity
            if additionalElementsCount > 0 {
                let newCapacity = Self.smartCapacityFor(count: capacity + additionalElementsCount)
                fastResizeElements(to: newCapacity)
            }
            push(firstNewElement)
            while let nextNewElement = elementsIterator.next() {
                push(nextNewElement)
            }
            
            return
        }
        
    }
    
    /// Stores the given collection of elements at first position of the storage, mainteining their order.
    ///
    /// ```
    /// let newElements = [1, 2, 3]
    /// let buffer = CircularBuffer<Int>()
    /// buffer.prepend(contentsOf: newElements)
    /// // buffer's storage: [1, 2, 3]
    /// ```
    /// - Parameter contentsOf: A collection of `Element` instances to store at the top of the storage.
    public func prepend<C: Collection>(contentsOf newElements: C) where C.Iterator.Element == Element {
        guard newElements.count > 0 else { return }
        
        if count + newElements.count <= capacity
        {
            // actual buffer can hold all elements, thus prepend _newElements in place…
            // Calculate the buffer index where newElements have to be appended:
            let newHead = head - newElements.count < 0 ? capacity - (newElements.count - head) : head - newElements.count
            // Copy newElements in place:
            initializeElements(advancedToBufferIndex: newHead, from: newElements)
            
            // Update both _elementsCount and _head to new values:
            count += newElements.count
            head = newHead
        } else {
            // resize buffer to the right capacity prepending _newElements
            let newCapacity = Self.smartCapacityFor(count: capacity + newElements.count)
            fastResizeElements(to: newCapacity, insert: newElements, at: 0)
        }
    }
    
    // MARK: - Inserting
    /// Insert all elements in given collection starting from given index, keeping their original order.
    ///
    /// ```
    /// let newElements = [1, 2, 3]
    /// let buffer = CircularBuffer<Int>()
    /// buffer.append(4)
    /// buffer.append(5)
    /// buffer.append(6)
    /// // buffer's storage: [4, 5, 6]
    /// buffer.insertAt(idx: 1, contentsOf: newElements)
    /// // buffer's storage: [4, 1, 2, 3, 5, 6]
    /// ```
    /// - Parameter index:  An `Int` value representing the index where to start inserting the given
    ///                     collection of elements.
    ///                     Must be greater than or equal zero and less than or equal `count`.
    ///                     When specifying zero as `index` the operation is same as in
    ///                     `prepend(contentsOf:)`;
    ///                     on the other hand when `index` has a value equal to`count`,
    ///                     the operation is the same as in `append(contentsOf:)`.
    /// - Parameter contentsOf: A collection of `Element` instances to insert in the buffer starting from given
    ///                         `index` parameter.
    public func insertAt<C: Collection>(index: Int, contentsOf newElements: C) where C.Iterator.Element == Element {
        precondition(index >= 0 && index <= count)
        
        // Check if it's a prepend operation:
        guard
            index != 0
        else {
            prepend(contentsOf: newElements)
            
            return
        }
        
        // Otherwise could be an append operation:
        guard
            index != count
        else {
            append(contentsOf: newElements)
            
            return
        }
        
        // Check if there's elements to insert:
        guard
            !newElements.isEmpty
        else { return }
        
        if count + newElements.count <= capacity {
            // capacity is enough to hold addition, thus insert newElements in place
            let buffIdx = bufferIndex(from: index)
            
            // Temporarly move out elements that has to be shifted:
            let elementsToShiftCount = count - index
            let swap = UnsafeMutablePointer<Element>.allocate(capacity: elementsToShiftCount)
            moveInitialzeFromElements(advancedToBufferIndex: buffIdx, count: elementsToShiftCount, to: swap)
            
            // Copy newElements in place, obtaining the buffer index where the shifted
            // elements have to be moved back in:
            let buffIdxForFirstShifted = initializeElements(advancedToBufferIndex: buffIdx, from: newElements)
            
            // Move back into the buffer the elements which shift position, obtaining the
            // next buffer index after them (which will be used to calculate the
            // new _tail index):
            let lastBuffIdx = moveInitializeToElements(advancedToBufferIndex: buffIdxForFirstShifted, from: swap, count: elementsToShiftCount)
            
            // Cleanup, update both _elementsCount and _tail to new values:
            swap.deallocate()
            count += newElements.count
            tail = incrementIndex(lastBuffIdx - 1)
        } else {
            // We have to resize
            let newCapacity = Self.smartCapacityFor(count: count + newElements.count)
            fastResizeElements(to: newCapacity, insert: newElements, at: index)
        }
    }
    
}
