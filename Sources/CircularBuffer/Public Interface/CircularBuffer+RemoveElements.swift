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
            reduceCapacityForCurrentCount(usingSmartCapacityPolicy: true)
        }
        
        let element = elements.advanced(by: head).move()
        head = incrementBufferIndex(head)
        count -= 1
        
        return element
    }
    
    /// Removes and returns —if present— the element stored at first position, without reducing the storage capacity.
    ///
    /// - Returns: `first` element.
    /// - Complexity: O(1)
    @discardableResult
    func popFront() -> Element? {
        guard !isEmpty else { return nil }
        
        let firstElement = elements.advanced(by: head).move()
        defer {
            head = incrementBufferIndex(head)
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
        
        tail = decrementBufferIndex(tail)
        let element = elements.advanced(by: tail).move()
        count -= 1
        reduceCapacityForCurrentCount(usingSmartCapacityPolicy: true)
        
        return element
    }
    
    /// Removes and returns —if present— the element stored at last position, without reducing the storage capacity.
    ///
    /// - Returns: `last` element.
    /// - Complexity: O(1)
    @discardableResult
    public func popBack() -> Element? {
        guard !isEmpty else { return nil }
        
        tail = decrementBufferIndex(tail)
        let lastElement = elements.advanced(by: tail).move()
        count -= 1
        
        return lastElement
    }
    
    /// Removes and returns first *k* number of elements from the storage.
    /// Eventually reduces the buffer capacity at the end of the removal operation,
    /// by specifying a value of `true` as `keepCapacity` parameter value.
    /// The capacity resizing will be done by adopting the smart capacity policy
    /// if `true` is specified as `usingSmartCapacityPolicy` value, otherwise
    /// it will match the `count` value of the calle at the end of the removal operation.
    ///
    /// - Parameter _:  An `Int` value representing the *k* number of elements to remove from the
    ///                 head of the storage.
    ///                 Must be greater than or equal to `0`, and less than or equal `count` value.
    /// - Parameter keepCapacity:   Boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Parameter usingSmartCapacityPolicy:   Boolean value, when specifying `true` as its value,
    ///                                         then the smart capacity policy is adopted for resizing the
    ///                                         storage; otherwise when `false`, then the resizing
    ///                                         of the storage will match exactly the count of elements after
    ///                                         the removal operation has taken effect.
    ///                                         **Defaults to true**.
    /// - Returns: An `Array` containing the removed elements, in the same order as they were inside the storage.
    /// - Note: The `usingSmartCapacityPolicy` flag value has effect only when
    ///         `keepCapacity` specified value is `false`.
    ///         Calling this method with `0` as *k* elements to remove and `true` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with a value equals to `count` as *k* elements to remove,
    ///         and `true` as `keepCapacity` value, all elements will be removed from the storage,
    ///         and its capacity will be reduced to the minimum.
    @discardableResult
    public func removeFirst(_ k: Int, keepCapacity: Bool = true, usingSmartCapacityPolicy: Bool = true) -> [Element] {
        precondition(k >= 0 && k <= count, "operation not permitted with given count value")
        guard
            k < count
        else { return removeAll(keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy) }
        
        let newCount = count - k
        let newCapacity = capacityFor(newCount: newCount, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
        guard k > 0 else {
            defer {
                if newCapacity < capacity {
                    fastResizeElements(to: newCapacity)
                }
            }
            
            return []
        }
        
        if newCapacity == capacity {
            
            return fastInPlaceRemoveFirstElements(k)
        } else {
            
            return fastResizeElements(to: newCapacity, removingAt: 0, count: k)
        }
    }
    
    /// Removes and returns last *k* number of elements from the storage.
    /// Eventually reduces the buffer capacity at the end of the removal operation,
    /// by specifying a value of `true` as `keepCapacity` parameter value.
    /// The capacity resizing will be done by adopting the smart capacity policy
    /// if `true` is specified as `usingSmartCapacityPolicy` value, otherwise
    /// it will match the `count` value of the calle at the end of the removal operation.
    ///
    /// - Parameter _:  An `Int` value representing the *k* number of elements to remove from the tail
    ///                 of the storage.
    ///                 Must be greater than or equal to `0`, and less than or equal `count` value.
    /// - Parameter keepCapacity:   Boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Parameter usingSmartCapacityPolicy:   Boolean value, when specifying `true` as its value,
    ///                                         then the smart capacity policy is adopted for resizing the
    ///                                         storage; otherwise when `false`, then the resizing
    ///                                         of the storage will match exactly the count of elements after
    ///                                         the removal operation has taken effect.
    ///                                         **Defaults to true**.
    /// - Returns: An `Array` containing the removed elements, in the same order as they were inside the storage.
    /// - Note: The `usingSmartCapacityPolicy` flag value has effect only when
    ///         `keepCapacity` specified value is `false`.
    ///         Calling this method with `0` as *k* elements to remove and `true` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with a value equals to `count` as *k* elements to remove,
    ///         and `true` as `keepCapacity` value, all elements will be removed from the storage,
    ///         and its capacity will be reduced to the minimum possible one.
    @discardableResult
    public func removeLast(_ k: Int, keepCapacity: Bool = true, usingSmartCapacityPolicy: Bool = true) -> [Element] {
        precondition(k >= 0 && k <= count, "operation not permitted with given count value")
        guard
            k < count
        else { return removeAll(keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy) }
        
        let newCount = count - k
        let newCapacity = capacityFor(newCount: newCount, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
        guard k > 0 else {
            defer {
                if newCapacity < capacity {
                    fastResizeElements(to: newCapacity)
                }
            }
            
            return []
        }
        
        if newCapacity == capacity {
            
            return fastInPlaceRemoveLastElements(k)
        } else {
            
            return fastResizeElements(to: newCapacity, removingAt: count - k, count: k)
        }
    }
    
    /// Removes and returns *k* number of elements from the storage starting from the one at the given `index`
    /// parameter.
    /// Eventually reduces the buffer capacity at the end of the removal operation,
    /// by specifying a value of `true` as `keepCapacity` parameter value.
    /// The capacity resizing will be done by adopting the smart capacity policy
    /// if `true` is specified as `usingSmartCapacityPolicy` value, otherwise
    /// it will match the `count` value of the calle at the end of the removal operation.
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
    /// - Parameter usingSmartCapacityPolicy:   Boolean value, when specifying `true` as its value,
    ///                                         then the smart capacity policy is adopted for resizing the
    ///                                         storage; otherwise when `false`, then the resizing
    ///                                         of the storage will match exactly the count of elements after
    ///                                         the removal operation has taken effect.
    ///                                         **Defaults to true**.
    /// - Returns:  An `Array` containing the removed elements, in the same order as they were inside the storage.
    /// - Note: The `usingSmartCapacityPolicy` flag value has effect only when
    ///         `keepCapacity` specified value is `false`.
    ///         Calling this method with `0` as *k* elements to remove and `false` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with an `index` value of `0`,
    ///         a value equals to `count` as *k* elements to remove, and `true` as `keepCapacity` value,
    ///         all elements will be removed from the storage, and its capacity will be reduced
    ///         to the minimum possible one.
    @discardableResult
    public func removeAt(index: Int, count k: Int, keepCapacity: Bool = true, usingSmartCapacityPolicy: Bool = true) -> [Element] {
        checkSubscriptBounds(for: index)
        precondition(k >= 0 && k <= count - index, "operation not permitted with given count value")
        guard index != 0 else { return removeFirst(k, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy) }
        
        guard index != count - 1 else { return removeLast(k, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy) }
        
        let newCount = count - k
        let newCapacity = capacityFor(newCount: newCount, keepCapacity: keepCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
        guard k > 0 else {
            defer {
                if newCapacity < capacity {
                    fastResizeElements(to: newCapacity)
                }
            }
            
            return []
        }
        
        if newCapacity == capacity {
            
            return fastInPlaceRemoveElements(at: index, count: k)
        } else {
            
            return fastResizeElements(to: newCapacity, removingAt: index, count: k)
        }
    }
    
    /// Removes and returns all elements stored in the same order as they were stored in the storage.
    /// Eventually reduces the buffer capacity at the end of the removal operation,
    /// by specifying a value of `true` as `keepCapacity` parameter value.
    /// The capacity resizing will be done by adopting the smart capacity policy
    /// if `true` is specified as `usingSmartCapacityPolicy` value, otherwise
    /// it will match the `count` value of the calle at the end of the removal operation.
    ///
    /// - Parameter keepCapacity:   Boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Parameter usingSmartCapacityPolicy:   Boolean value, when specifying `true` as its value,
    ///                                         then the smart capacity policy is adopted for resizing the
    ///                                         storage; otherwise when `false`, then the resizing
    ///                                         of the storage will match exactly the count of elements after
    ///                                         the removal operation has taken effect.
    ///                                         **Defaults to true**.
    /// - Returns:  An `Array` containing the removed elements, in the same order as they were
    ///             stored inside the storage.
    /// - Note: The `usingSmartCapacityPolicy` flag value has effect only when
    ///         `keepCapacity` specified value is `false`.
    @discardableResult
    public func removeAll(keepCapacity: Bool = true, usingSmartCapacityPolicy: Bool = true) -> [Element] {
        defer {
            let minCapacity = usingSmartCapacityPolicy ? Self.minSmartCapacity : 0
            if !keepCapacity && capacity > minCapacity {
                self.capacity = minCapacity
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
