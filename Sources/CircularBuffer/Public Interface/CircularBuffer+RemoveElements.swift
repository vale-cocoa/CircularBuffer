//
//  CircularBuffer+RemoveElements.swift
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

// MARK: - Remove elements
extension CircularBuffer {
    /// Removes and returns —if present— the element stored at first position storage.
    /// Eventually reduces capacity if necessary by adopting the smart capacity policy.
    ///
    /// - Returns: The first element of the storage; `nil` when `isEmpty` is `true`.
    /// - Complexity: Amortized O(1)
    /// - Note: The capacity of the buffer might get downsized after the operation has removed a stored element, and
    ///         will get downsized to the minimum value if after the removal operation the buffer will be empty.
    @discardableResult
    public func popFirst() -> Element? {
        guard !self.isEmpty else { return nil }
        
        defer {
            reduceSmartCapacityForCurrentElementsCount()
        }
        
        let element = elements.advanced(by: head).move()
        head = incrementIndex(head)
        count -= 1
        
        return element
    }
    
    /// Removes and returns —if present— the element stored at first position, keeping the capacity intact.
    ///
    /// - Returns: `first` element.
    /// - Complexity: O(1)
    @discardableResult
    func popFront() -> Element? {
        guard !isEmpty else { return nil }
        
        let firstElement = elements.advanced(by: head).move()
        defer {
            head = incrementIndex(head)
            count -= 1
        }
        
        return firstElement
    }
    
    /// Removes and returns —if present— the element stored at last position storage.
    /// Eventually reduces capacity if necessary by adopting the smart capacity policy.
    ///
    /// - Returns: The last element of the storage; `nil` when `isEmpty` is `true`.
    /// - Complexity: Amortized O(1)
    /// - Note: The capacity of the buffer might get downsized after the operation has removed a stored element, and
    ///         will get downsized to the minimum value if after the removal operation the buffer will be empty.
    @discardableResult
    public func popLast() -> Element? {
        guard !self.isEmpty else { return nil }
        
        tail = decrementIndex(tail)
        let element = elements.advanced(by: tail).move()
        count -= 1
        reduceSmartCapacityForCurrentElementsCount()
        
        return element
    }
    
    /// Removes and returns —if present— the element stored at last position, keeping the capacity intact.
    ///
    /// - Returns: `last` element.
    /// - Complexity: O(1)
    @discardableResult
    public func popBack() -> Element? {
        guard !isEmpty else { return nil }
        
        tail = decrementIndex(tail)
        let lastElement = elements.advanced(by: tail).move()
        count -= 1
        
        return lastElement
    }
    
    /// Removes and returns first *k* number of elements from the storage. Eventually reduces the buffer capacity when
    /// specified in the callee by giving a value of `true` as `keepCapacity` parameter value.
    ///
    /// - Parameter _:  An `Int` value representing the *k* number of elements to remove from the
    ///                 head of the storage.
    ///                 Must be greater than or equal to `0`, and less than or equal `count` value.
    /// - Parameter keepCapacity:   Boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Returns: An `Array` containing the removed elements, in the same order as they were inside the storage.
    /// - Note: Calling this method with `0` as *k* elements to remove and `true` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with a value equals to `count` as *k* elements to remove,
    ///         and `true` as `keepCapacity` value, all elements will be removed from the storage,
    ///         and its capacity will be reduced to the minimum possible one.
    @discardableResult
    public func removeFirst(_ k: Int, keepCapacity: Bool = true) -> [Element] {
        precondition(k >= 0 && k <= count, "operation not permitted with given count value")
        guard
            k < count
        else { return removeAll(keepCapacity: keepCapacity) }
        
        guard k > 0 else {
            defer {
                if !keepCapacity {
                    reduceSmartCapacityForCurrentElementsCount()
                }
            }
            
            return []
        }
        
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        moveInitializeFromElements(advancedToBufferIndex: head, count: k, to: removed)
        
        defer {
            head = head + k > capacity ? incrementIndex(k - (capacity - head) - 1) : incrementIndex(head + k - 1)
            count -= k
            tail = incrementIndex(head + count - 1)
            if !keepCapacity {
                reduceSmartCapacityForCurrentElementsCount()
            }
        }
        
        let result = Array<Element>(UnsafeBufferPointer(start: removed, count: k))
        removed.deinitialize(count: k)
        removed.deallocate()
        
        return result
    }
    
    /// Removes and returns last *k* number of elements from the storage. Eventually reduces the buffer capacity when
    /// specified in the callee by giving a value of `true` as `keepCapacity` parameter value.
    ///
    /// - Parameter _:  An `Int` value representing the *k* number of elements to remove from the tail
    ///                 of the storage.
    ///                 Must be greater than or equal to `0`, and less than or equal `count` value.
    /// - Parameter keepCapacity:   Boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Returns: An `Array` containing the removed elements, in the same order as they were inside the storage.
    /// - Note: Calling this method with `0` as *k* elements to remove and `true` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with a value equals to `count` as *k* elements to remove,
    ///         and `true` as `keepCapacity` value, all elements will be removed from the storage,
    ///         and its capacity will be reduced to the minimum possible one.
    @discardableResult
    public func removeLast(_ k: Int, keepCapacity: Bool = true) -> [Element] {
        precondition(k >= 0 && k <= count, "operation not permitted with given count value")
        guard k < count else { return removeAll(keepCapacity: keepCapacity) }
        
        guard k > 0 else {
            defer {
                if !keepCapacity {
                    reduceSmartCapacityForCurrentElementsCount()
                }
            }
            
            return []
        }
        
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        let buffIdxStart = tail - k < 0 ? capacity - k - tail : tail - k
        moveInitializeFromElements(advancedToBufferIndex: buffIdxStart, count: k, to: removed)
        
        defer {
            count -= k
            tail = buffIdxStart
            if !keepCapacity {
                reduceSmartCapacityForCurrentElementsCount()
            }
        }
        
        let result = Array<Element>(UnsafeBufferPointer(start: removed, count: k))
        removed.deinitialize(count: k)
        removed.deallocate()
        
        return result
    }
    
    /// Removes and returns *k* number of elements from the storage starting from the one at the given `index`
    /// parameter. Eventually reduces the buffer capacity when specified in the callee by giving a value of `true` as
    /// `keepCapacity` parameter value.
    ///
    /// - Parameter index:  An `Int` value representing the position where to start the removal.
    ///                     Must be a valid subscript index: hence greater than or equal `zero`
    ///                     and less than `count` when `isEmpty` is false.
    /// - Parameter count:  An `Int` value representing the *k* number of elements to remove
    ///                     starting from the given `index` position.
    ///                     Must be greater than or equal `0`, less than or equal to the count of elements
    ///                     between the given `index` position and the end postion of the storage
    ///                     (`count - index`).
    /// - Parameter keepCapacity:   Boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Returns:  An `Array` containing the removed elements, in the same order as they were inside the storage.
    /// - Note: Calling this method with `0` as *k* elements to remove and `true` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with an `index` value of `0`,
    ///         a value equals to `count` as *k* elements to remove, and `true` as `keepCapacity` value,
    ///         all elements will be removed from the storage, and its capacity will be reduced
    ///         to the minimum possible one.
    @discardableResult
    public func removeAt(index: Int, count k: Int, keepCapacity: Bool = true) -> [Element] {
        checkSubscriptBounds(for: index)
        precondition(k >= 0 && k <= count - index, "operation not permitted with given count value")
        guard index != 0 else { return removeFirst(k, keepCapacity: keepCapacity) }
        
        guard index != count - 1 else { return removeLast(k, keepCapacity: keepCapacity) }
        
        guard k > 0 else {
            defer {
                if !keepCapacity {
                    reduceSmartCapacityForCurrentElementsCount()
                }
            }
            
            return []
        }
        
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        
        // Get the real buffer index from given index:
        let buffIdx = bufferIndex(from: index)
        
        // move elements to remove, obtaining the buffer index from where some elements
        // might remain:
        let bufIdxOfSecondSplit = moveInitializeFromElements(advancedToBufferIndex: buffIdx, count: k, to: removed)
        
        // We defer the shifting of remaining elements/rejoining in a smaller buffer
        // operation after we have returned the removed elements
        defer {
            // Check if we ought move remaining elements to a smaller buffer, or if we
            // ought shift them inside the actual buffer to occupy the space left by
            //the removal:
            let newCapacity = keepCapacity ? capacity : Self.smartCapacityFor(count: count - k)
            if newCapacity < capacity {
                // Let's move remaining elements to a smaller buffer…
                let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
                
                // Remaining elements could be placed in two splits of current buffer:
                let countOfFirstSplit = index
                let countOfSecondSplit = count - index - k
                
                // move into newBuff first split of _elements
                if countOfFirstSplit > 0 {
                    moveInitializeFromElements(advancedToBufferIndex: head, count: countOfFirstSplit, to: newBuff)
                }
                
                // move into newBuff second split of _elements
                if countOfSecondSplit > 0 {
                    moveInitializeFromElements(advancedToBufferIndex: bufIdxOfSecondSplit, count: countOfSecondSplit, to: newBuff.advanced(by: countOfFirstSplit))
                }
                
                // Apply the change of buffer:
                elements.deallocate()
                elements = newBuff
                
                // update _capacity, _head, _elementsCount and _tail to new values
                capacity = newCapacity
                head = 0
                count -= k
                tail = incrementIndex(count - 1)
            } else {
                // _capacity stays the same.
                // We have to eventually shift up remaining elements placed after the
                // removed ones:
                let countOfElementsToShift = count - index - k
                let lastBufIdx: Int!
                if countOfElementsToShift > 0 {
                    // There are some remaining elements in the buffer, occupying positions
                    // below the removed ones.
                    // Let's first move them out _elements:
                    let swap = UnsafeMutablePointer<Element>.allocate(capacity: countOfElementsToShift)
                    moveInitializeFromElements(advancedToBufferIndex: bufIdxOfSecondSplit, count: countOfElementsToShift, to: swap)
                    
                    // then back in _elements at the index where the removal started,
                    // obtaining also the buffer index for recalculating the _tail:
                    lastBufIdx = moveInitializeToElements(advancedToBufferIndex: buffIdx, from: swap, count: countOfElementsToShift)
                    swap.deallocate()
                } else {
                    // The removal ended up to the last element, hence the buffer index
                    // for calculating the new _tail is the one obtained from the removal.
                    lastBufIdx = bufIdxOfSecondSplit
                }
                
                // Update _elementsCount and _tail to the newValues:
                count -= k
                tail = incrementIndex(lastBufIdx - 1)
            }
        }
        
        let result = Array(UnsafeBufferPointer(start: removed, count: k))
        removed.deinitialize(count: k)
        removed.deallocate()
        
        return result
    }
    
    /// Removes and returns all elements stored in the same order as they were stored in the storage.
    /// Eventually reduces the buffer capacity when specified in the callee by giving a value of `true` as
    /// `keepCapacity` parameter value.
    ///
    /// - Parameter keepCapacity:   Boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Returns:  An `Array` containing the removed elements, in the same order as they were
    ///             stored inside the storage.
    @discardableResult
    public func removeAll(keepCapacity: Bool = true) -> [Element] {
        defer {
            if !keepCapacity && capacity > Self.minSmartCapacity {
                self.capacity = Self.minSmartCapacity
                self.elements.deallocate()
                self.elements = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
                head = 0
                tail = 0
            }
        }
        
        guard count > 0 else { return [] }
        
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: count)
        moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: removed)
        let result = Array(UnsafeBufferPointer(start: removed, count: count))
        removed.deinitialize(count: count)
        removed.deallocate()
        count = 0
        head = 0
        tail = 0
        
        return result
    }
    
}
