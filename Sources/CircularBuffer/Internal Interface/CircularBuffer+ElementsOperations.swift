//
//  CircularBuffer+ElementsOperations.swift
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

extension CircularBuffer {
    // The minimum number of elements the smart capacity policy establish to allocate
    // memory for.
    @usableFromInline
    internal static var minSmartCapacity: Int { 4 }
    
    // Returns the next power of 2 for given capacity value, or minCapacity for
    // a given value less than or equal to 2.
    // Returned value is clamped to Int.max, and given value must not be negative.
    @usableFromInline
    static func smartCapacityFor(count: Int) -> Int {
        guard count > (minSmartCapacity >> 1) else { return minSmartCapacity }
        
        guard count < ((Int.max >> 1) + 1) else { return Int.max }
        
        return 1 << (Int.bitWidth - (count - 1).leadingZeroBitCount)
    }
    
    // Resize the buffer with a larger capacity than actual one; the new size of the
    // buffer will be the next one according to the smart capacity policy.
    @usableFromInline
    internal func growToNextSmartCapacityLevel() {
        precondition(capacity < Int.max, "Can't grow capacity more than Int.max value: \(Int.max)")
        let newCapacity = capacity << 1
        fastResizeElements(to: newCapacity)
    }
    
    // Returns an adeguate capacity value to store the specified new count of elements,
    // taking into account whether we want to use the smart capacity policy in doing the
    // calcultion or not, if we want to keep capacity or not in case we are specifying a
    // newCount value which is less than the actual count.
    @usableFromInline
    internal func capacityFor(newCount: Int, keepCapacity: Bool = true, usingSmartCapacityPolicy: Bool = true) -> Int {
        assert(newCount >= 0)
        guard capacity > newCount else {
            if usingSmartCapacityPolicy {
                
                return Self.smartCapacityFor(count: newCount)
            } else {
                
                return newCount
            }
        }
        
        guard !keepCapacity else { return capacity }
        
        guard
            newCount > 0
        else {
            
            return usingSmartCapacityPolicy ? Self.minSmartCapacity : 0
        }
        
        let minCapacity = usingSmartCapacityPolicy ? (Self.minSmartCapacity << 2) : newCount
        let candidateCapacity = usingSmartCapacityPolicy ? capacity >> 2 : newCount
        guard
            capacity >= minCapacity,
            candidateCapacity >= newCount
        else { return capacity }
        
        return candidateCapacity
    }
    
    // Eventually resize the buffer to a smaller capacity suitable for current count of
    // elements and according whether to use the smart capacity policy or not in doing so,
    // as per specified value of usingSmartCapacityPolicy parameter.
    @usableFromInline
    internal func reduceCapacityForCurrentCount(usingSmartCapacityPolicy: Bool = true) {
        guard !isEmpty else {
            let minCapacity = usingSmartCapacityPolicy ? Self.minSmartCapacity : 0
            if capacity > minCapacity {
                fastResizeElements(to: minCapacity)
            }
            
            return
        }
        
        let minCapacity = usingSmartCapacityPolicy ? (Self.minSmartCapacity << 2) : count
        let candidateCapacity = usingSmartCapacityPolicy ? capacity >> 2 : count
        
        guard
            capacity >= minCapacity,
            candidateCapacity >= count
        else { return }
        
        fastResizeElements(to: candidateCapacity)
    }
    
    // Shift the elements in the buffer so they won't wrap around the last buffer position,
    // but instead are all stored in a contiguous range of indexes; that is, after the
    // operation took effect: head + count <= capacity
    @usableFromInline
    internal func makeElementsContiguous() {
        assert(!isEmpty, "No elements to wrap around")
        assert(head + count > capacity, "Elements aren't wrapping around")
        let wrappingElementsCount = count - (capacity - head)
        let headElementsCount = capacity - head
        var newHead: Int!
        if residualCapacity < wrappingElementsCount {
            newHead = bufferIndex(from: head, offsetBy: -wrappingElementsCount)
            let swap = UnsafeMutablePointer<Element>.allocate(capacity: wrappingElementsCount)
            swap.moveInitialize(from: elements, count: wrappingElementsCount)
            elements.advanced(by: newHead).moveInitialize(from: elements.advanced(by: head), count: headElementsCount)
            elements.advanced(by: newHead + headElementsCount).moveInitialize(from: swap, count: wrappingElementsCount)
            swap.deallocate()
        } else if wrappingElementsCount <= headElementsCount {
            newHead = bufferIndex(from: head, offsetBy: -wrappingElementsCount)
            elements.advanced(by: newHead).moveInitialize(from: elements.advanced(by: head), count: headElementsCount)
            elements.advanced(by: newHead + headElementsCount).moveInitialize(from: elements, count: wrappingElementsCount)
        } else {
            newHead = tail - headElementsCount
            elements.advanced(by: tail).moveInitialize(from: elements, count: wrappingElementsCount)
            elements.advanced(by: newHead).moveInitialize(from: elements.advanced(by: head), count: headElementsCount)
        }
        head = newHead
        tail = bufferIndex(from: head, offsetBy: count)
    }
    
    // Resizes buffer to specified capacity value, which is assumed to be enough to
    // store current count of elements.
    @usableFromInline
    internal func fastResizeElements(to newCapacity: Int) {
        assert(newCapacity >= count)
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        
        unsafeMoveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        head = 0
        tail = incrementBufferIndex(count - 1)
    }
    
    // Resizes buffer to specified capacity value, which is assumed to be enough to
    // store current count of elements plus the count of the given collection of elements
    // that will be inserted at specified position (which also is assumed to be in range
    // of 0...count)
    @usableFromInline
    internal func fastResizeElements<C: Collection>(to newCapacity: Int, insert newElements: C, at index: Int) where C.Iterator.Element == Element {
        assert(newCapacity >= count + newElements.count)
        let newBuffer = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        
        // copy newElements inside newBuffer
        newBuffer.advanced(by: index).unsafeInitialize(from: newElements)
        
        // Find out how and where to move elements into newBuffer
        let buffIdx = index == count ? head + count : bufferIndex(from: index)
        let leftSplitStart: Int!
        let rightSplitStart: Int!
        if buffIdx == head {
            leftSplitStart = newElements.count
            rightSplitStart = newElements.count
        } else if buffIdx == head + count {
            leftSplitStart = 0
            rightSplitStart = 0
        } else {
            leftSplitStart = 0
            rightSplitStart = newElements.count + index
        }
        
        // move elements into newBuffer
        if leftSplitStart == rightSplitStart {
            // elements are either appended or prepended to newBuffer
            unsafeMoveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuffer.advanced(by: leftSplitStart))
        } else {
            // elements will occupy two splits inside the newBuffer
            let countOfFirstSplit = index
            let countOfSecondSplit = count - index
            // move first split:
            if countOfFirstSplit > 0 {
                unsafeMoveInitializeFromElements(advancedToBufferIndex: head, count: countOfFirstSplit, to: newBuffer)
            }
            // move second split:
            if countOfSecondSplit > 0 {
                unsafeMoveInitializeFromElements(advancedToBufferIndex: buffIdx, count: countOfSecondSplit, to: newBuffer.advanced(by: rightSplitStart))
            }
        }
        elements.deallocate()
        elements = newBuffer
        capacity = newCapacity
        count += newElements.count
        head = 0
        tail = incrementBufferIndex(count - 1)
    }
    
    // Resizes buffer to specified capacity value, which is assumed to be enough to
    // store the count of elements deriving from replacing the elements at the
    // specified positions range with the one stored in the specified collection.
    @usableFromInline
    func fastResizeElements<C: Collection>(to newCapacity: Int, replacing subrange: Range<Int>, with newElements: C) where Element == C.Iterator.Element {
        assert(newCapacity >= 0)
        assert(subrange.lowerBound >= 0 && subrange.upperBound <= count)
        let buffIdx = bufferIndex(from: subrange.lowerBound)
        let newBuffer = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        let newElementsCount = newElements.count
        assert(newCapacity >= newElementsCount)
        
        let countOfFirstSplit = subrange.lowerBound
        let countOfSecondSplit = count - countOfFirstSplit - subrange.count
        
        // Deinitialize in elements the replaced subrange and obtain the
        // buffer index to second split of elements to move from elements:
        let secondSplitStartBuffIdx = unsafeDeinitializeElements(advancedToBufferIndex: buffIdx, count: subrange.count)
        
        // Now move everything in newBuff…
        // Eventually the first split from elements:
        var newBuffIdx = 0
        if countOfFirstSplit > 0 {
            unsafeMoveInitializeFromElements(advancedToBufferIndex: head, count: countOfFirstSplit, to: newBuffer)
            newBuffIdx += countOfFirstSplit
        }
        
        // Then newElements:
        newBuffer.advanced(by: newBuffIdx).unsafeInitialize(from: newElements)
        newBuffIdx += newElementsCount
        
        // Eventually the second split from _elements:
        if countOfSecondSplit > 0 {
            unsafeMoveInitializeFromElements(advancedToBufferIndex: secondSplitStartBuffIdx, count: countOfSecondSplit, to: newBuffer.advanced(by: newBuffIdx))
        }
        
        // deallocate and update elements with newBuff:
        elements.deallocate()
        elements = newBuffer
        // Update capacity, count, head and tail to new values:
        capacity = newCapacity
        count = count - subrange.count + newElementsCount
        head = 0
        tail = incrementBufferIndex(count - 1)
    }
    
    // Resizes buffer to specified capacity value, which is assumed to be enough to
    // store the count of elements deriving from removing elements from the specified
    // position in number of specified k parameter.
    // Assuming also that the index is in 0..<count range, and the count k of elements to
    // remove is not larger than those stored in the buffer after and including the one at
    // the specified position.
    // Removed elements will also be returned in an array.
    @usableFromInline
    @discardableResult
    internal func fastResizeElements(to newCapacity: Int, removingAt index: Int, count k: Int) -> [Element] {
        assert(k >= 0 && k <= count - index)
        assert(newCapacity >= count - k)
        assert(index >= 0 && index < count)
        let result = UnsafeMutablePointer<Element>.allocate(capacity: k)
        let buffIdx = bufferIndex(from: index)
        unsafeMoveInitializeFromElements(advancedToBufferIndex: buffIdx, count: k, to: result)
        defer {
            result.deinitialize(count: k)
            result.deallocate()
            let newCount = count - k
            let newElements = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
            unsafeMoveInitializeFromElements(advancedToBufferIndex: head, count: index, to: newElements)
            let buffIdxOfLastChunk = bufferIndex(from: index + k)
            unsafeMoveInitializeFromElements(advancedToBufferIndex: buffIdxOfLastChunk, count: count - (index + k), to: newElements.advanced(by: index))
            elements.deallocate()
            elements = newElements
            capacity = newCapacity
            count = newCount
            head = 0
            tail = incrementBufferIndex(newCount - 1)
        }
        
        return Array(UnsafeBufferPointer(start: result, count: k))
    }
    
}

// MARK: - elements pointer unsafe operations
// All these methods are manipulating directly the memory buffers of their parameters.
// It is assumed that preconditions as boundaries checking, allocations count,
// and correct state of affected memory portions were met before call.
// They all take into account the possibility that elements could wrap around
// the last buffer position, i.e. head + count > capacity
// Indeed they are helpers for move, assign, initialize and deinitialize to and from the
// buffer operations.
extension CircularBuffer {
    // Initializes destination memory pointer from elements in buffer,
    // starting from the one stored at given index and
    // for the given count of elements.
    // It then returns the next valid buffer index after
    // the last initialized one.
    @usableFromInline
    @discardableResult
    internal func unsafeInitializeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
        let nextBufferIdx: Int!
        if startIdx + k > capacity {
            let segmentCount = capacity - startIdx
            destination.initialize(from: elements.advanced(by: startIdx), count: segmentCount)
            destination.advanced(by: segmentCount).initialize(from: elements, count: k - segmentCount)
            nextBufferIdx = k - segmentCount
        } else {
            destination.initialize(from: elements.advanced(by: startIdx), count: k)
            nextBufferIdx = startIdx + k
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    // Initializes elements memory buffer with given collection of elements,
    // starting from the given buffer position.
    // It then returns the next valid buffer index after
    // the last initialized from the given collection.
    @usableFromInline
    @discardableResult
    internal func unsafeInitializeElements<C: Collection>(advancedToBufferIndex startIdx : Int, from newElements: C) -> Int where C.Iterator.Element == Element {
        let nextBufferIdx: Int
        if startIdx + newElements.count > capacity {
            let segmentCount = capacity - startIdx
            let firstSplitRange = newElements.startIndex..<newElements.index(newElements.startIndex, offsetBy: segmentCount)
            let secondSplitRange = newElements.index(newElements.startIndex, offsetBy: segmentCount)..<newElements.endIndex
            elements.advanced(by: startIdx).unsafeInitialize(from: newElements[firstSplitRange])
            elements.unsafeInitialize(from: newElements[secondSplitRange])
            nextBufferIdx = newElements.count - segmentCount
        } else {
            elements.advanced(by: startIdx).unsafeInitialize(from: newElements)
            nextBufferIdx = startIdx + newElements.count
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    // Initializes destination memory pointer by moving in it elements form the buffer,
    // starting from the one stored at given index in the buffer and
    // for the given count of elements.
    // It then returns the next valid buffer index after the last moved one.
    @usableFromInline
    @discardableResult
    internal func unsafeMoveInitializeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
        let nextBufferIdx: Int!
        if startIdx + k > capacity {
            let segmentCount = capacity - startIdx
            destination.moveInitialize(from: elements.advanced(by: startIdx), count: segmentCount)
            destination.advanced(by: segmentCount).moveInitialize(from: elements, count: k - segmentCount)
            nextBufferIdx = k - segmentCount
        } else {
            destination.moveInitialize(from: elements.advanced(by: startIdx), count: k)
            nextBufferIdx = startIdx + k
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    // Initializes memory buffer starting from given index, with the elements moved from
    // the other pointer.
    // It then returns the next valid buffer index after the last initialized one.
    @usableFromInline
    @discardableResult
    internal func unsafeMoveInitializeToElements(advancedToBufferIndex startIdx: Int, from other: UnsafeMutablePointer<Element>, count k: Int) -> Int {
        let nextBuffIdx: Int!
        if startIdx + k > capacity {
            let segmentCount = capacity - startIdx
            elements.advanced(by: startIdx).moveInitialize(from: other, count: segmentCount)
            elements.moveInitialize(from: other.advanced(by: segmentCount), count: k - segmentCount)
            nextBuffIdx = k - segmentCount
        } else {
            elements.advanced(by: startIdx).moveInitialize(from: other, count: k)
            nextBuffIdx = startIdx + k
        }
        
        return nextBuffIdx == capacity ? 0 : nextBuffIdx
    }
    
    // Assign elements memory buffer with given collection of elements,
    // starting from the given buffer position.
    // It then returns the next valid buffer index after
    // the last modified one.
    @usableFromInline
    @discardableResult
    internal func unsafeAssignElements<C: Collection>(advancedToBufferIndex startIdx: Int, from newElements: C) -> Int where Element == C.Iterator.Element {
        let nextBufferIdx: Int
        if startIdx + newElements.count > capacity {
            let segmentCount = capacity - startIdx
            let firstSplitRange = newElements.startIndex..<newElements.index(newElements.startIndex, offsetBy: segmentCount)
            let secondSplitRange = newElements.index(newElements.startIndex, offsetBy: segmentCount)..<newElements.endIndex
            elements.advanced(by: startIdx).unsafeAssign(from: newElements[firstSplitRange])
            elements.unsafeAssign(from: newElements[secondSplitRange])
            nextBufferIdx = newElements.count - segmentCount
        } else {
            elements.advanced(by: startIdx).unsafeAssign(from: newElements)
            nextBufferIdx = startIdx + newElements.count
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    // Assigns destination memory pointer by moving in it elements form the buffer,
    // starting from the one stored at given index in the buffer and
    // for the given count of elements.
    // It then returns the next valid buffer index after the last moved one.
    @usableFromInline
    @discardableResult
    internal func unsafeMoveAssignFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
        let nextBufferIdx: Int!
        if startIdx + k > capacity {
            let segmentCount = capacity - startIdx
            destination.moveAssign(from: elements.advanced(by: startIdx), count: segmentCount)
            destination.advanced(by: segmentCount).moveAssign(from: elements, count: k - segmentCount)
            nextBufferIdx = k - segmentCount
        } else {
            destination.moveAssign(from: elements.advanced(by: startIdx), count: k)
            nextBufferIdx = startIdx + k
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    // Assigns destination memory pointer by copying in it elements form the buffer,
    // starting from the one stored at given index in the buffer and
    // for the given count of elements.
    // It then returns the next valid buffer index after the last copied one.
    @usableFromInline
    @discardableResult
    internal func unsafeAssignFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
        let nextBufferIdx: Int!
        if startIdx + k > capacity {
            let segmentCount = capacity - startIdx
            destination.assign(from: elements.advanced(by: startIdx), count: segmentCount)
            destination.advanced(by: segmentCount).assign(from: elements, count: k - segmentCount)
            nextBufferIdx = k - segmentCount
        } else {
            destination.assign(from: elements.advanced(by: startIdx), count: k)
            nextBufferIdx = startIdx + k
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    // Deinitializes elements in the buffer, starting from the given buffer index and
    // in number equal to the specified count value.
    // It then returns the next valid buffer index after the last deinitialized one.
    @usableFromInline
    @discardableResult
    internal func unsafeDeinitializeElements(advancedToBufferIndex startIdx : Int, count: Int) -> Int {
        let nextBufferIdx: Int!
        if startIdx + count > capacity {
            let segmentCount = capacity - startIdx
            elements.advanced(by: startIdx).deinitialize(count: segmentCount)
            elements.deinitialize(count: count - segmentCount)
            nextBufferIdx = count - segmentCount
        } else {
            elements.advanced(by: startIdx).deinitialize(count: count)
            nextBufferIdx = startIdx + count
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
}

