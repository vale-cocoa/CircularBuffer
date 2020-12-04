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

extension CircularBuffer {
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
    
    @usableFromInline
    internal func fastInsert<C: Collection>(at position: Int, other: C) where Element == C.Iterator.Element {
        guard
            position != 0
        else {
            fastPrepend(other)
            
            return
        }
        
        guard position != count else {
            fastAppend(other)
            
            return
        }
        
        let otherCount = other.count
        guard otherCount > 0 else { return }
        
        let newCapacity = count + otherCount
        let storageFirstHalfCount = position
        let storageSecondHalfCount = count - storageFirstHalfCount
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        newBuff.advanced(by: storageFirstHalfCount).initialize(from: other)
        
        let next = storageFirstHalfCount > 0 ? moveInitializeFromElements(advancedToBufferIndex: head, count: storageFirstHalfCount, to: newBuff) : head
        if storageSecondHalfCount > 0 {
            moveInitializeFromElements(advancedToBufferIndex: next, count: storageSecondHalfCount, to: newBuff.advanced(by: storageFirstHalfCount + otherCount))
        }
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
    @usableFromInline
    internal func fastPrepend<C: Collection>(_ other: C) where Element == C.Iterator.Element {
        let otherCount = other.count
        guard otherCount > 0 else { return }
        
        let newCapacity = count + otherCount
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        newBuff.initialize(from: other)
        
        moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff.advanced(by: otherCount))
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
    @usableFromInline
    internal func fastAppend<C: Collection>(_ other: C) where Element == C.Iterator.Element {
        let otherCount = other.count
        guard otherCount > 0 else { return }
        
        let newCapacity = count + otherCount
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        newBuff.advanced(by: count).initialize(from: other)
        
        moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
    @usableFromInline
    internal func fastRemove(at position: Int, count k: Int) {
        guard k > 0 else { return }
        
        if position == 0 && k == count {
            removeAll(keepCapacity: false)
            
            return
        }
        
        let storageFirstHalfCount = position
        let storageSecondHalfCount = count - (position + k)
        let newCapacity = count - k
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        var next = storageFirstHalfCount > 0 ? moveInitializeFromElements(advancedToBufferIndex: head, count: storageFirstHalfCount, to: newBuff) : head
        next = deinitializeElements(advancedToBufferIndex: next, count: k)
        if storageSecondHalfCount > 0 {
            moveInitializeFromElements(advancedToBufferIndex: next, count: storageSecondHalfCount, to: newBuff.advanced(by: storageFirstHalfCount))
        }
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
    @usableFromInline
    internal func fastReplace<C: Collection>(subrange: Range<Int>, with other: C) where Element == C.Iterator.Element {
        let otherCount = other.count
        let storageFirstHalfCount = subrange.lowerBound
        let storageSecondHalfCount = count - (subrange.lowerBound + subrange.count)
        let newCapacity = count - subrange.count + otherCount
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        newBuff.advanced(by: storageFirstHalfCount).initialize(from: other)
        
        let subrangeBuffIdx = storageFirstHalfCount > 0 ? moveInitializeFromElements(advancedToBufferIndex: head, count: storageFirstHalfCount, to: newBuff) : head
        let next = deinitializeElements(advancedToBufferIndex: subrangeBuffIdx, count: subrange.count)
        if storageSecondHalfCount > 0 {
            moveInitializeFromElements(advancedToBufferIndex: next, count: storageSecondHalfCount, to: newBuff.advanced(by: storageFirstHalfCount + otherCount))
        }
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
}
