//
//  CircularBuffer+Operations.swift
//  CircularBuffer
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

// MARK: - Store new elements
extension CircularBuffer {
    @usableFromInline
    internal func append<C: Collection>(contentsOf newElements: C, usingSmartCapacityPolicy: Bool = true) where C.Iterator.Element == Element {
        let newElementsCount = newElements.count
        guard newElementsCount > 0 else {
            reduceCapacityForCurrentCount(usingSmartCapacityPolicy: usingSmartCapacityPolicy)
            
            return
        }
        
        if newElementsCount <= residualCapacity
        {
            // actual buffer can hold all elements, thus append newElements in place
            fastInplaceAppend(newElements)
        } else {
            // resize buffer to the right capacity and append newElements
            let newCount = count + newElementsCount
            let newCapacity = usingSmartCapacityPolicy ? Self.smartCapacityFor(count: newCount) : newCount
            fastResizeElements(to: newCapacity, insert: newElements, at: count)
        }
    }
    
    @inlinable
    internal func prepend<C: Collection>(contentsOf newElements: C, usingSmartCapacityPolicy: Bool = true) where Element == C.Iterator.Element {
        let newElementsCount = newElements.count
        guard newElementsCount > 0 else {
            reduceCapacityForCurrentCount(usingSmartCapacityPolicy: usingSmartCapacityPolicy)
            
            return
        }
        
        if newElementsCount <= residualCapacity
        {
            // actual buffer can hold all elements, thus prepend newElements in place…
            fastInplacePrepend(newElements)
        } else {
            // resize buffer to the right capacity prepending newElements
            let newCount = count + newElementsCount
            let newCapacity = usingSmartCapacityPolicy ? Self.smartCapacityFor(count: newCount) : newCount
            fastResizeElements(to: newCapacity, insert: newElements, at: 0)
        }
    }
    // MARK: - Store new elements in place
    @usableFromInline
    internal func fastInplaceInsert<C: Collection>(_ newElements: C, at index: Int) where Element == C.Iterator.Element {
        assert(index >= 0 && index <= count)
        let buffIdx = bufferIndex(from: index)
        guard buffIdx != head else {
            fastInplacePrepend(newElements)
            
            return
        }
        
        guard buffIdx != tail else {
            fastInplaceAppend(newElements)
            
            return
        }
        
        let newElementsCount = newElements.count
        assert(newElementsCount <= residualCapacity)
        guard newElementsCount > 0 else { return }
        
        let newCount = count + newElementsCount
        
        // Temporarly move out elements that has to be shifted:
        let elementsToShiftCount = count - index
        let swap = UnsafeMutablePointer<Element>.allocate(capacity: elementsToShiftCount)
        unsafeMoveInitializeFromElements(advancedToBufferIndex: buffIdx, count: elementsToShiftCount, to: swap)
        
        // Copy newElements in place, obtaining the buffer index where the shifted
        // elements have to be moved back in:
        let buffIdxForFirstShifted = unsafeInitializeElements(advancedToBufferIndex: buffIdx, from: newElements)
        
        // Move back into the buffer the elements which shift position, obtaining the
        // next buffer index after them (which will be used to calculate the
        // new tail index):
        let lastBuffIdx = unsafeMoveInitializeToElements(advancedToBufferIndex: buffIdxForFirstShifted, from: swap, count: elementsToShiftCount)
        
        // Cleanup, update both cout and tail to new values:
        swap.deallocate()
        count = newCount
        tail = incrementBufferIndex(lastBuffIdx - 1)
    }
    
    @usableFromInline
    internal func fastInplacePrepend<C: Collection>(_ newElements: C) where Element == C.Iterator.Element {
        let newElementsCount = newElements.count
        guard newElementsCount > 0 else { return }
        assert(newElementsCount <= residualCapacity)
        
        let newHead = bufferIndex(from: head, offsetBy: -newElementsCount)
        unsafeInitializeElements(advancedToBufferIndex: newHead, from: newElements)
        count += newElementsCount
        head = newHead
    }
    
    @usableFromInline
    internal func fastInplaceAppend<C: Collection>(_ newElements: C) where Element == C.Iterator.Element {
        let newElementsCount = newElements.count
        assert(newElementsCount <= residualCapacity)
        guard newElementsCount > 0 else { return }
        
        let newTail = unsafeInitializeElements(advancedToBufferIndex: tail, from: newElements)
        count += newElementsCount
        tail = newTail
    }
    
}

// MARK: - Remove stored elements in place
extension CircularBuffer {
    @usableFromInline
    internal func fastInplaceRemoveFirstElements(_ k: Int) -> [Element] {
        assert(k >= 0 && k <= count)
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        let newHead = unsafeMoveInitializeFromElements(advancedToBufferIndex: head, count: k, to: removed)
        defer {
            removed.deinitialize(count: k)
            removed.deallocate()
            head = newHead
            count -= k
        }
        
        return Array(UnsafeBufferPointer(start: removed, count: k))
    }
    
    @usableFromInline
    internal func fastInplaceRemoveLastElements(_ k: Int) -> [Element] {
        assert(k >= 0 && k <= count)
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        let buffIdx = bufferIndex(from: count - k)
        let newTail = unsafeMoveInitializeFromElements(advancedToBufferIndex: buffIdx, count: k, to: removed)
        defer {
            removed.deinitialize(count: k)
            removed.deallocate()
            tail = incrementBufferIndex(newTail - 1)
            count -= k
        }
        
        return Array(UnsafeBufferPointer(start: removed, count: k))
    }
    
    @usableFromInline
    internal func fastInplaceRemoveElements(at index: Int, count k: Int) -> [Element] {
        assert(index >= 0 && index <= count)
        assert(k >= 0 && k <= count - index)
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        let buffIdx = bufferIndex(from: index)
        unsafeMoveInitializeFromElements(advancedToBufferIndex: buffIdx, count: k, to: removed)
        defer {
            removed.deinitialize(count: k)
            removed.deallocate()
            let countOfSwapped = count - (index + k)
            let swap = UnsafeMutablePointer<Element>.allocate(capacity: countOfSwapped)
            let swappedBuffIdx = bufferIndex(from: index + k)
            unsafeMoveInitializeFromElements(advancedToBufferIndex: swappedBuffIdx, count: countOfSwapped, to: swap)
            let newTail = unsafeMoveInitializeToElements(advancedToBufferIndex: buffIdx, from: swap, count: countOfSwapped)
            swap.deallocate()
            count -= k
            tail = incrementBufferIndex(newTail - 1)
        }
        
        return Array(UnsafeBufferPointer(start: removed, count: k))
    }
    
    @usableFromInline
    internal func fastInplaceReplaceElements<C: Collection>(subrange: Range<Int>, with newElements: C) where Element == C.Iterator.Element {
        assert(subrange.lowerBound >= 0 && subrange.upperBound <= count)
        let newElementsCount = newElements.count
        assert(capacity >= (count - subrange.count + newElementsCount))
        let buffIdx = bufferIndex(from: subrange.lowerBound)
        guard subrange.count != newElementsCount else {
            unsafeAssignElements(advancedToBufferIndex: buffIdx, from: newElements)
            
            return
        }
        
        let countOfElementsToShift = count - subrange.lowerBound - subrange.count
        // Deinitialize the elements to remove obtaining the buffer index to
        // the first element that eventually gets shifted:
        let bufIdxOfFirstElementToShift = unsafeDeinitializeElements(advancedToBufferIndex: buffIdx, count: subrange.count)
        
        let lastBuffIdx: Int!
        if countOfElementsToShift > 0 {
            // We've got some elements to shift in the process.
            // Let's move them temporarly out:
            let swap = UnsafeMutablePointer<Element>.allocate(capacity: countOfElementsToShift)
            unsafeMoveInitializeFromElements(advancedToBufferIndex: bufIdxOfFirstElementToShift, count: countOfElementsToShift, to: swap)
            
            // Let's put newElements in place obtaining the buffer index
            // where to put back the shifted elements:
            let newBuffIdxForShifted = unsafeInitializeElements(advancedToBufferIndex: buffIdx, from: newElements)
            
            // Let's now put back th elements that were shifted, obtaining
            // the bufferIndex for calculating the new tail:
            lastBuffIdx = unsafeMoveInitializeToElements(advancedToBufferIndex: newBuffIdxForShifted, from: swap, count: countOfElementsToShift)
            swap.deallocate()
        } else {
            // The operation doesn't involve any element to be shifted,
            // thus let's just put in place newElements obtainig the buffer
            // index for calculating the new tail:
            lastBuffIdx = unsafeInitializeElements(advancedToBufferIndex: buffIdx, from: newElements)
        }
        // Update count and tail to new values
        count = count - subrange.count + newElementsCount
        tail = incrementBufferIndex(lastBuffIdx - 1)
    }
}
