//
//  CircularBuffer+ClosureBasedOperations.swift
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
    // MARK: - forEach(_:)
    /// Calls the given closure on each element in the storage in the same order as a for-in loop.
    ///
    /// The two loops in the following example produce the same output:
    /// ```
    /// let numberWords = CircularBuffer(elements: ["one", "two", "three"])
    /// for word in numberWords {
    ///    print(word)
    /// }
    /// // Prints "one"
    /// // Prints "two"
    /// // Prints "three"
    ///
    /// numberWords.forEach { word in
    ///     print(word)
    /// }
    /// // Same as above
    /// ```
    /// Using the forEach method is distinct from a for-in loop in two important ways:
    /// 1. You cannot use a break or continue statement to exit the current call of the body closure or skip subsequent calls.
    /// 2. Using the return statement in the body closure will exit only from the current call to body, not from any outer
    /// scope, and won’t skip subsequent calls.
    /// - Parameter _: A closure that takes an element of the storage as a parameter.
    public func forEach(_ body: (Element) throws -> ()) rethrows {
        for i in 0..<count {
            let buffIdx = bufferIndex(from: i)
            try body(elements.advanced(by: buffIdx).pointee)
        }
    }
    
    // MARK: - allSatisfy(_:)
    /// Returns a Boolean value indicating whether every stored element
    /// satisfies a given predicate.
    ///
    /// The following code uses this method to test whether all the stored numbers are even:
    ///
    ///     let numbers = CircularBuffer(elements: [2, 4, 6, 8, 10])
    ///     let areAllEven = numbers.allSatisfy({ $0 % 2 == 0 })
    ///     // areAllEven == true
    ///
    /// - Parameter predicate:  A closure that takes a stored element as its argument and
    ///                         returns a Boolean value that indicates whether the passed element
    ///                         satisfies a condition.
    /// - Returns:  `true` if the sequence contains only elements that satisfy
    ///             `predicate`; otherwise, `false`.
    ///
    /// - Complexity: O(*n*), where *n* is the count of stored elements.
    public func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        for i in 0..<count {
            let buffIdx = bufferIndex(from: i)
            guard try predicate(elements.advanced(by: buffIdx).pointee) else { return false }
        }
        
        return true
    }
    
    // MARK: - REFACTOR THIS
    // MARK: - removeAll(where:)
    /// Removes all the elements that satisfy the given predicate.
    ///
    /// Use this method to remove every element in a
    /// `CircularBuffer` intance that meets particular criteria.
    /// The order of the remaining elements is preserved.
    /// This example removes all the odd values from a
    /// `CircularBuffer<Int>` instance:
    ///
    ///     var numbers = [5, 6, 7, 8, 9, 10, 11]
    ///     numbers.removeAll(where: { $0 % 2 != 0 })
    ///     // numbers == [6, 8, 10]
    ///
    /// - Parameter shouldBeRemoved:    A closure that takes an element of the
    ///                                 `CircularBuffer` instance  as its argument
    ///                                 and returns a Boolean value indicating whether the element
    ///                                 should be removed from it.
    ///
    /// - Complexity: O(*n*), where *n* is the count of elements in the `CircularBuffer` instance.
    public func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        guard !isEmpty else { return }
        
        var newCount = count
        var topIdx = 0
        var bottomIdx = count - 1
        var newHead: Int? = nil
        var newLast: Int? = nil
        var countToDeinitialize = 0
        var buffIdx = bufferIndex(from: topIdx)
        var newHeadBuffIdx = head
        var newTailBuffIdx = tail
        MAINLOOP: repeat {
            let topStart = topIdx
            INNERTOP: while try shouldBeRemoved(elements.advanced(by: buffIdx).pointee) {
                countToDeinitialize += 1
                guard topIdx < bottomIdx else { break INNERTOP }
                
                topIdx += 1
                buffIdx = bufferIndex(from: topIdx)
            }
            if countToDeinitialize > 0 {
                let buffIdxStartToDeinit = bufferIndex(from: topStart)
                deinitializeElements(advancedToBufferIndex: buffIdxStartToDeinit, count: countToDeinitialize)
                newCount -= countToDeinitialize
                if let oldNewHead = newHead {
                    let countToMove = topStart - oldNewHead
                    let temp = UnsafeMutablePointer<Element>.allocate(capacity: countToMove)
                    let oldNewHeadBuffIdx = bufferIndex(from: oldNewHead)
                    moveInitialzeFromElements(advancedToBufferIndex: oldNewHeadBuffIdx, count: countToMove, to: temp)
                    let updatedNewHead = oldNewHead + countToDeinitialize
                    newHeadBuffIdx = bufferIndex(from: updatedNewHead)
                    newHead = updatedNewHead
                    moveInitializeToElements(advancedToBufferIndex: newHeadBuffIdx, from: temp, count: countToMove)
                    temp.deallocate()
                } else {
                    newHead = topIdx
                    newHeadBuffIdx = buffIdx
                }
                countToDeinitialize = 0
            } else if newHead == nil {
                newHead = topStart
                newHeadBuffIdx = bufferIndex(from: topStart)
            }
            guard topIdx < bottomIdx else { break MAINLOOP }
            
            let bottomStart = bottomIdx
            buffIdx = bufferIndex(from: bottomIdx)
            INNERBOTTOM: while try shouldBeRemoved(elements.advanced(by: buffIdx).pointee) {
                countToDeinitialize += 1
                bottomIdx -= 1
                buffIdx = bufferIndex(from: bottomIdx)
                
                guard topIdx < bottomIdx else { break INNERBOTTOM }
            }
            if countToDeinitialize > 0 {
                let buffIdxStartToDeinit = incrementIndex(buffIdx)
                deinitializeElements(advancedToBufferIndex: buffIdxStartToDeinit, count: countToDeinitialize)
                newCount -= countToDeinitialize
                if let oldNewLast = newLast {
                    let countToMove = oldNewLast - bottomStart
                    let temp = UnsafeMutablePointer<Element>.allocate(capacity: countToMove)
                    let bottomStartBuffIdx = bufferIndex(from: bottomIdx + 1 + countToDeinitialize)
                    moveInitialzeFromElements(advancedToBufferIndex: bottomStartBuffIdx, count: countToMove, to: temp)
                    let reInsertBuffIdx = incrementIndex(buffIdx)
                    moveInitializeToElements(advancedToBufferIndex: reInsertBuffIdx, from: temp, count: countToMove)
                    newLast = oldNewLast - countToDeinitialize
                } else {
                    newLast = bottomIdx
                }
                countToDeinitialize = 0
            } else if newLast == nil {
                newLast = bottomStart
            }
            newTailBuffIdx = incrementIndex(bufferIndex(from: newLast!))
            topIdx += topIdx == topStart ? 1 : 0
            bottomIdx -= bottomIdx == bottomStart ? 1 : 0
            buffIdx = bufferIndex(from: topIdx)
        } while topIdx <= bottomIdx
        head = newHeadBuffIdx
        tail = newTailBuffIdx
        count = newCount
    }
    
    // MARK: - withUnsafeBufferPointer(_:)
    /// Calls a closure with a pointer to the CircularBuffer contiguous storage.
    ///
    /// Often, the optimizer can eliminate bounds checks within an CircularBuffer
    /// algorithm, but when that fails, invoking the same algorithm on the
    /// buffer pointer passed into your closure lets you trade safety for speed.
    ///
    /// The pointer passed as an argument to `body` is valid only during the
    /// execution of `withUnsafeBufferPointer(_:)`. Do not store or return the
    /// pointer for later use.
    ///
    /// - Parameter body:   A closure with an `UnsafeBufferPointer` parameter that
    ///                     points to the contiguous storage for the CircularBuffer.  If no such storage exists, it is
    ///                     created. If `body` has a return value, that value is also used as the return value
    ///                     for the `withUnsafeBufferPointer(_:)` method. The pointer argument is
    ///                     valid only for the duration of the method's execution.
    /// - Returns: The return value, if any, of the `body` closure parameter.
    public func withUnsafeBufferPointer<R>(_ body:(UnsafeBufferPointer<Element>) throws -> R) rethrows -> R {
        if head + count > capacity {
            fastRotateElementsHeadToZero()
        }
        
        let buff = UnsafeBufferPointer(start: elements.advanced(by: head), count: count)
        
        return try body(buff)
    }
    
    // MARK: - withUnsafeMutableBufferPointer(_:)
    /// Calls the given closure with a pointer to the CircularBuffer's mutable contiguous storage.
    ///
    /// Often, the optimizer can eliminate bounds checks within an CircularBuffer
    /// algorithm, but when that fails, invoking the same algorithm on the
    /// buffer pointer passed into your closure lets you trade safety for speed.
    ///
    /// The pointer passed as an argument to `body` is valid only during the
    /// execution of `withUnsafeMutableBufferPointer(_:)`. Do not store or
    /// return the pointer for later use.
    ///
    /// - Warning:  Do not rely on anything about the CircularBuffer that is the target of
    ///             this method during execution of the `body` closure; it might not
    ///             appear to have its correct value. Instead, use only the
    ///             `UnsafeMutableBufferPointer` argument to `body`.
    ///
    /// - Parameter body:   A closure with an `UnsafeMutableBufferPointer`
    ///                     parameter that points to the contiguous storage for the CircularBuffer.
    ///                     If no such storage exists, it is created. If `body` has a return value, that value is also
    ///                     used as the return value for the `withUnsafeMutableBufferPointer(_:)`
    ///                     method. The pointer argument is valid only for the duration of the
    ///                     method's execution.
    /// - Returns: The return value, if any, of the `body` closure parameter.
    public func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) rethrows -> R {
        if head + count > capacity {
            fastRotateElementsHeadToZero()
        }
        // save actual state:
        let prevElements = elements
        let prevCapacity = capacity
        let prevCount = count
        let prevHead = head
        let prevTail = tail
        
        // temporarly change internal state to empty
        elements = UnsafeMutablePointer<Element>.allocate(capacity: Self.minSmartCapacity)
        capacity = Self.minSmartCapacity
        count = 0
        head = 0
        tail = 0
        
        // prepare the buffer that will be passed to body
        var buff = UnsafeMutableBufferPointer<Element>(start: prevElements.advanced(by: prevHead), count: prevCount)
        
        defer {
            // Once body has executed, restore the state:
            precondition(buff.baseAddress == prevElements.advanced(by: prevHead) && buff.count == prevCount, "CircularBuffer withUnsafeMutableBufferPointer: replacing the buffer is not allowed")
            self.elements.deallocate()
            self.elements = prevElements
            self.capacity = prevCapacity
            self.count = prevCount
            self.head = prevHead
            self.tail = prevTail
        }
        
        // execute body and return its result
        return try body(&buff)
    }
    
}
