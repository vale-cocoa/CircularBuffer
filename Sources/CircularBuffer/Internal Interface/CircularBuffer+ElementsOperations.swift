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
    static var minSmartCapacity: Int { 4 }
    
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
    func growToNextSmartCapacityLevel() {
        precondition(capacity < Int.max, "Can't grow capacity more than Int.max value: \(Int.max)")
        let newCapacity = capacity << 1
        fastResizeElements(to: newCapacity)
    }
    
    @usableFromInline
    func reduceSmartCapacityForCurrentElementsCount() {
        guard !isEmpty else {
            if capacity > Self.minSmartCapacity {
                fastResizeElements(to: Self.minSmartCapacity)
            }
            
            return
        }
        
        let candidateCapacity = capacity >> 2
        
        guard
            capacity >= (Self.minSmartCapacity << 2),
             candidateCapacity >= count
        else { return }
        
        fastResizeElements(to: candidateCapacity)
    }
    
    @usableFromInline
    func fastRotateElementsHeadToZero() {
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        
        moveInitialzeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        head = 0
        tail = incrementIndex(count - 1)
    }
    
    @usableFromInline
    func fastResizeElements(to newCapacity: Int) {
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        
        moveInitialzeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        head = 0
        tail = incrementIndex(count - 1)
    }
    
    @usableFromInline
    func fastResizeElements<C: Collection>(to newCapacity: Int, insert newElements: C, at index: Int) where C.Iterator.Element == Element {
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
            moveInitialzeFromElements(advancedToBufferIndex: head, count: count, to: newBuffer.advanced(by: leftSplitStart))
        } else {
            // elements will occupy two splits inside the newBuffer
            let countOfFirstSplit = index
            let countOfSecondSplit = count - index
            // move first split:
            if countOfFirstSplit > 0 {
                moveInitialzeFromElements(advancedToBufferIndex: head, count: countOfFirstSplit, to: newBuffer)
            }
            // move second split:
            if countOfSecondSplit > 0 {
                moveInitialzeFromElements(advancedToBufferIndex: buffIdx, count: countOfSecondSplit, to: newBuffer.advanced(by: rightSplitStart))
            }
        }
        elements.deallocate()
        elements = newBuffer
        capacity = newCapacity
        count += newElements.count
        head = 0
        tail = incrementIndex(count - 1)
    }
    
    @usableFromInline
    @discardableResult
    func fastDownsizeElements(removingAt index: Int, count k: Int, newCapacityExactlyMatchesNewCount: Bool = false) -> [Element] {
        let result = UnsafeMutablePointer<Element>.allocate(capacity: k)
        moveInitialzeFromElements(advancedToBufferIndex: index, count: k, to: result)
        
        defer {
            result.deinitialize(count: k)
            result.deallocate()
            let newCount = count - k
            let newCapacity = newCapacityExactlyMatchesNewCount ? newCount : Self.smartCapacityFor(count: newCount)
            let newElements = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
            moveInitialzeFromElements(advancedToBufferIndex: head, count: index, to: newElements)
            let buffIdx = bufferIndex(from: index + k)
            moveInitialzeFromElements(advancedToBufferIndex: buffIdx, count: count - (index + k), to: newElements.advanced(by: index))
            elements.deallocate()
            elements = newElements
            capacity = newCapacity
            count = newCount
            head = 0
            tail = incrementIndex(newCount - 1)
        }
        
        return Array(UnsafeBufferPointer(start: result, count: k))
    }
    
    @usableFromInline
    func shouldSmartDownsizeCapacityByRemoving(countOfElementsToRemove k: Int) -> Bool {
        guard capacity > Self.minSmartCapacity else { return false }
        
        let newCount = count - k
        guard newCount > 0 else {
            
            return capacity > Self.minSmartCapacity
        }
        
        let candidateCapacity = Self.smartCapacityFor(count: newCount)
        
        return (candidateCapacity << 2) >= capacity
    }
    
}

// MARK: - elements pointer operations
extension CircularBuffer {
    @usableFromInline
    @discardableResult
    func moveInitialzeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
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
    func initializeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
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
    func initializeElements<C: Collection>(advancedToBufferIndex startIdx : Int, from newElements: C) -> Int where C.Iterator.Element == Element {
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
    func moveInitializeToElements(advancedToBufferIndex startIdx: Int, from other: UnsafeMutablePointer<Element>, count k: Int) -> Int {
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
    
    @discardableResult
    func assignElements<C: Collection>(advancedToBufferIndex startIdx: Int, from newElements: C) -> Int where Element == C.Iterator.Element {
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
    func moveAssignFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
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
    func assignFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
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
    func deinitializeElements(advancedToBufferIndex startIdx : Int, count: Int) -> Int {
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
