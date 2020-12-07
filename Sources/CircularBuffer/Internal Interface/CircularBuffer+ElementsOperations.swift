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
    
    @usableFromInline
    internal func growToNextSmartCapacityLevel() {
        precondition(capacity < Int.max, "Can't grow capacity more than Int.max value: \(Int.max)")
        let newCapacity = capacity << 1
        fastResizeElements(to: newCapacity)
    }
    
    @usableFromInline
    internal func capacityFor(newCount: Int, keepCapacity: Bool = true, usingSmartCapacityPolicy: Bool = true) -> Int {
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
    
    @usableFromInline
    internal func fastRotateElementsHeadToZero() {
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        
        moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        head = 0
        tail = incrementBufferIndex(count - 1)
    }
    
    @usableFromInline
    internal func fastResizeElements(to newCapacity: Int) {
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        
        moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        head = 0
        tail = incrementBufferIndex(count - 1)
    }
    
    @usableFromInline
    internal func fastResizeElements<C: Collection>(to newCapacity: Int, insert newElements: C, at index: Int) where C.Iterator.Element == Element {
        let newBuffer = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        
        // copy newElements inside newBuffer
        newBuffer.advanced(by: index).initialize(from: newElements)
        
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
            moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuffer.advanced(by: leftSplitStart))
        } else {
            // elements will occupy two splits inside the newBuffer
            let countOfFirstSplit = index
            let countOfSecondSplit = count - index
            // move first split:
            if countOfFirstSplit > 0 {
                moveInitializeFromElements(advancedToBufferIndex: head, count: countOfFirstSplit, to: newBuffer)
            }
            // move second split:
            if countOfSecondSplit > 0 {
                moveInitializeFromElements(advancedToBufferIndex: buffIdx, count: countOfSecondSplit, to: newBuffer.advanced(by: rightSplitStart))
            }
        }
        elements.deallocate()
        elements = newBuffer
        capacity = newCapacity
        count += newElements.count
        head = 0
        tail = incrementBufferIndex(count - 1)
    }
    
    @usableFromInline
    func fastResizeElements<C: Collection>(to newCapacity: Int, replacing subrange: Range<Int>, with newElements: C) where Element == C.Iterator.Element {
        let buffIdx = bufferIndex(from: subrange.lowerBound)
        let newBuffer = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        let newElementsCount = newElements.count
        
        let countOfFirstSplit = subrange.lowerBound
        let countOfSecondSplit = count - countOfFirstSplit - subrange.count
        
        // Deinitialize in elements the replaced subrange and obtain the
        // buffer index to second split of elements to move from elements:
        let secondSplitStartBuffIdx = deinitializeElements(advancedToBufferIndex: buffIdx, count: subrange.count)
        
        // Now move everything in newBuff…
        // Eventually the first split from elements:
        var newBuffIdx = 0
        if countOfFirstSplit > 0 {
            moveInitializeFromElements(advancedToBufferIndex: head, count: countOfFirstSplit, to: newBuffer)
            newBuffIdx += countOfFirstSplit
        }
        
        // Then newElements:
        newBuffer.advanced(by: newBuffIdx).initialize(from: newElements)
        newBuffIdx += newElementsCount
        
        // Eventually the second split from _elements:
        if countOfSecondSplit > 0 {
            moveInitializeFromElements(advancedToBufferIndex: secondSplitStartBuffIdx, count: countOfSecondSplit, to: newBuffer.advanced(by: newBuffIdx))
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
    
    @usableFromInline
    @discardableResult
    internal func fastResizeElements(to newCapacity: Int, removingAt index: Int, count k: Int) -> [Element] {
        let result = UnsafeMutablePointer<Element>.allocate(capacity: k)
        let buffIdx = bufferIndex(from: index)
        moveInitializeFromElements(advancedToBufferIndex: buffIdx, count: k, to: result)
        defer {
            result.deinitialize(count: k)
            result.deallocate()
            let newCount = count - k
            let newElements = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
            moveInitializeFromElements(advancedToBufferIndex: head, count: index, to: newElements)
            let buffIdxOfLastChunk = bufferIndex(from: index + k)
            moveInitializeFromElements(advancedToBufferIndex: buffIdxOfLastChunk, count: count - (index + k), to: newElements.advanced(by: index))
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

// MARK: - elements pointer operations
extension CircularBuffer {
    @usableFromInline
    @discardableResult
    internal func initializeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
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
    
    @usableFromInline
    @discardableResult
    internal func initializeElements<C: Collection>(advancedToBufferIndex startIdx : Int, from newElements: C) -> Int where C.Iterator.Element == Element {
        let nextBufferIdx: Int
        if startIdx + newElements.count > capacity {
            let segmentCount = capacity - startIdx
            let firstSplitRange = newElements.startIndex..<newElements.index(newElements.startIndex, offsetBy: segmentCount)
            let secondSplitRange = newElements.index(newElements.startIndex, offsetBy: segmentCount)..<newElements.endIndex
            elements.advanced(by: startIdx).initialize(from: newElements[firstSplitRange])
            elements.initialize(from: newElements[secondSplitRange])
            nextBufferIdx = newElements.count - segmentCount
        } else {
            elements.advanced(by: startIdx).initialize(from: newElements)
            nextBufferIdx = startIdx + newElements.count
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    @usableFromInline
    @discardableResult
    internal func moveInitializeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
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
    
    @usableFromInline
    @discardableResult
    internal func moveInitializeToElements(advancedToBufferIndex startIdx: Int, from other: UnsafeMutablePointer<Element>, count k: Int) -> Int {
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
    
    @usableFromInline
    @discardableResult
    internal func assignElements<C: Collection>(advancedToBufferIndex startIdx: Int, from newElements: C) -> Int where Element == C.Iterator.Element {
        let nextBufferIdx: Int
        if startIdx + newElements.count > capacity {
            let segmentCount = capacity - startIdx
            let firstSplitRange = newElements.startIndex..<newElements.index(newElements.startIndex, offsetBy: segmentCount)
            let secondSplitRange = newElements.index(newElements.startIndex, offsetBy: segmentCount)..<newElements.endIndex
            elements.advanced(by: startIdx).assign(from: newElements[firstSplitRange])
            elements.assign(from: newElements[secondSplitRange])
            nextBufferIdx = newElements.count - segmentCount
        } else {
            elements.advanced(by: startIdx).assign(from: newElements)
            nextBufferIdx = startIdx + newElements.count
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    @usableFromInline
    @discardableResult
    internal func moveAssignFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
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
    
    @usableFromInline
    @discardableResult
    internal func assignFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
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
    
    @usableFromInline
    @discardableResult
    internal func deinitializeElements(advancedToBufferIndex startIdx : Int, count: Int) -> Int {
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

