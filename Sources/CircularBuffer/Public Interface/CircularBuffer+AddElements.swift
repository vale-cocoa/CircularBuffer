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
    // MARK: - Appending new elements
    /// Stores the given element at the last position of the storage. Eventually grows the capacity of the storage when
    /// `isFull` equals to `true`, adopting the smart capacity policy.
    ///
    /// - Parameter _: The element to store.
    /// - Complexity: Amortized O(1).
    /// - Note: When `isFull` is `true`, grows the capacity of the storage so it can hold the new count of elements.
    public func append(_ newElement: Element) {
        if isFull {
            growToNextSmartCapacityLevel()
        }
        elements.advanced(by: tail).initialize(to: newElement)
        tail = incrementBufferIndex(tail)
        count += 1
    }
    
    /// Stores the given sequence of elements starting at the last position of the storage. Eventually grows the capacity of
    /// the storage if needed, adopting the smart capacity resizing policy.
    ///
    /// - Parameter contentsOf: A sequence of elements to append. **Must be finite**.
    /// - Note: Calls iteratively `append(:_)` for each element of the given sequence.
    ///         Capacity is grown when necessary to hold all new elements, adopting the smart capacity policy.
    ///         A better appending performance is obtained when the given sequence's `underestimatedCount`
    ///         value is the closest to the real count of elements of the sequence.
    @inlinable
    public func append<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    append(contentsOf: buff, usingSmartCapacityPolicy: true)
                    
                    return true
                })
        else {
            var elementsIterator = newElements.makeIterator()
            guard
                let firstNewElement = elementsIterator.next()
                else { return }
            
            let additionalElementsCount = newElements.underestimatedCount - residualCapacity
            if additionalElementsCount > 0 {
                let newCapacity = Self.smartCapacityFor(count: count + additionalElementsCount)
                fastResizeElements(to: newCapacity)
            }
            append(firstNewElement)
            while let nextNewElement = elementsIterator.next() {
                append(nextNewElement)
            }
            
            return
        }
    }
    
    /// Stores the specified new element at the last position of the storage.
    /// In case `isFull` is `true`, it'll make room in the buffer by trumping the value stored at first position.
    ///
    /// - Parameter _: The new element to store at the last position of the storage.
    /// - Complexity: O(1)
    /// - Note: This method effectively uses the storage as a ring buffer.
    public func pushBack(_ newElement: Element) {
        guard capacity > 0 else { return }
        
        if isFull {
            elements.advanced(by: tail).pointee = newElement
            tail = incrementBufferIndex(tail)
            head = incrementBufferIndex(head)
        } else {
            elements.advanced(by: tail).initialize(to: newElement)
            tail = incrementBufferIndex(tail)
            count += 1
        }
    }
    
    /// Iteratively stores the elements contained in the specified sequence at the last position of the storage.
    /// In case `isFull` is `true`, it'll make room in the buffer by trumping iteratively enough stored values starting
    /// from first position.
    ///
    /// - Parameter contentsOf: The sequence of elements to store starting from the last position of the storage.
    ///                         **Must be finite**.
    /// - Note: This method effectively uses the storage as a ring buffer.
    public func pushBack<S: Sequence>(contentsOf newElements: S) where Element == S.Iterator.Element {
        guard capacity > 0 else { return }
        
        let done: Bool = newElements
            .withContiguousStorageIfAvailable { buff -> Bool in
                let addedCount = buff.count
                guard
                    buff.baseAddress != nil,
                    addedCount > 0
                else { return true }
                
                guard
                    addedCount > self.residualCapacity
                else {
                    self.fastInplaceAppend(buff)
                    
                    return true
                }
                
                if addedCount > self.capacity {
                    let slice = buff[(buff.endIndex - self.capacity)..<buff.endIndex]
                    self.deinitializeElements(advancedToBufferIndex: self.head, count: self.count)
                    self.initializeElements(advancedToBufferIndex: 0, from: slice)
                    self.head = 0
                    self.tail = 0
                } else {
                    let countToDeinitialize = addedCount - self.residualCapacity >= self.count ? self.count : addedCount - self.residualCapacity
                    let newHead = self.deinitializeElements(advancedToBufferIndex: self.head, count: countToDeinitialize)
                    self.initializeElements(advancedToBufferIndex: self.tail, from: buff)
                    self.head = newHead
                    self.tail = self.head
                }
                self.count = self.capacity
                
                return true
            } ?? false
        
        if !done {
            for newElement in newElements {
                pushBack(newElement)
            }
        }
    }
    
    // MARK: - Prepending new elements
    /// Stores given element at the first position of the storage. Eventually grows the capacity of the storage when
    /// `isFull` equals to `true`, adopting the smart capacity policy.
    ///
    /// - Parameter _: The element to store.
    /// - Complexity: Amortized O(1)
    /// - Note: When `isFull` is `true`, grows the capacity of the storage so it can hold the new count of elements.
    public func push(_ newElement: Element) {
        if isFull {
            growToNextSmartCapacityLevel()
        }
        head = decrementBufferIndex(head)
        elements.advanced(by: head).initialize(to: newElement)
        count += 1
    }
    
    /// Stores the given sequence of elements at the first position of the storage by iteratively pushing them.
    /// Eventually grows the capacity of the storage if needed, adopting the smart capacity policy.
    ///
    /// Since the sequence is iterated and at each iteration an element is pushed, the elements will appear in
    /// reversed order inside the `CircularBuffer`:
    /// ```
    /// let sequence = AnySequence(1..<4)
    /// let buffer = CircularBuffer<Int>()
    /// buffer.push(contentsOf: sequence)
    /// // buffer's storage: [3, 2, 1]
    /// ```
    /// - Parameter contentsOf: A sequence of elements to push. **Must be finite**.
    /// - Note: Calls iteratively `push(:_)` for each element of the given sequence.
    ///         Capacity is grown when necessary to hold all new elements.
    ///         A better appending performance is obtained when the given sequence's `underestimatedCount`
    ///         value is the closest to the real count of elements of the sequence.
    @inlinable
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
    
    /// Stores the given sequence of elements starting from first position of the storage, mainteining their order.
    /// Eventually grows the capacity of the storage if needed, adopting the smart capacity policy.
    ///
    /// ```
    /// let newElements = AnySequence([1, 2, 3])
    /// let buffer = CircularBuffer<Int>()
    /// buffer.prepend(contentsOf: newElements)
    /// // buffer's storage: [1, 2, 3]
    /// ```
    /// - Parameter contentsOf: A sequence of `Element` instances to store at the top of the storage.
    ///                         **Must be finite**.
    @inlinable
    public func prepend<S: Sequence>(contentsOf newElements: S) where Element == S.Iterator.Element {
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    prepend(contentsOf: buff, usingSmartCapacityPolicy: true)
                    
                    return true
                })
        else {
            let asArray = Array(newElements)
            prepend(contentsOf: asArray, usingSmartCapacityPolicy: true)
            
            return
        }
    }
    
    /// Stores the  specified new element at the first position of the storage.
    /// In case `isFull` is `true`, it'll make room in the buffer by trumping the value stored at last position.
    ///
    /// - Parameter _: The new element to store at the first position of the storage.
    /// - Complexity: O(1)
    /// - Note: This method effectively uses the storage as a ring buffer.
    public func pushFront(_ newElement: Element) {
        guard capacity > 0 else { return }
        
        head = decrementBufferIndex(head)
        if isFull {
            elements.advanced(by: head).pointee = newElement
            tail = decrementBufferIndex(tail)
        } else {
            elements.advanced(by: head).initialize(to: newElement)
            count += 1
        }
    }
    
    /// Iteratively pushes the elements contained in the specified sequence at the first position of the storage.
    /// In case `isFull` is `true`, it'll make room in the buffer by trumping iteratively enough stored values starting
    /// from last position.
    ///
    /// - Parameter contentsOf: The sequence of elements to push at the first position of the storage.
    /// - Note: This method effectively uses the storage as a ring buffer.
    ///         The new elements will appear in reverse order than the one they had in the sequence;
    ///         that is this operation is equivalent to calling iteratively `pushFront(_:)`
    ///         for each element in specified seqeunce.
    public func pushFront<S: Sequence>(contentsOf newElements: S) where Element == S.Iterator.Element {
        guard capacity > 0 else { return }
        
        let done: Bool = newElements
            .withContiguousStorageIfAvailable { buff -> Bool in
                let addedCount = buff.count
                guard
                    buff.baseAddress != nil,
                    addedCount > 0
                else { return true }
                
                guard
                    addedCount > self.residualCapacity
                else {
                    //self.fastPrepend(buff.reversed())
                    self.fastInplacePrepend(buff.reversed())
                    
                    return true
                }
                
                if addedCount > self.capacity {
                    let slice = buff[buff.endIndex - self.capacity..<buff.endIndex]
                        .reversed()
                    self.deinitializeElements(advancedToBufferIndex: self.head, count: self.count)
                    self.initializeElements(advancedToBufferIndex: 0, from: slice)
                    self.head = 0
                    self.tail = 0
                } else {
                    let countToDeinitialize = addedCount - self.residualCapacity >= self.count ? self.count : addedCount - self.residualCapacity
                    let newTail = self.bufferIndex(from: self.count - countToDeinitialize)
                    self.deinitializeElements(advancedToBufferIndex: newTail, count: countToDeinitialize)
                    self.tail = newTail
                    self.initializeElements(advancedToBufferIndex: newTail, from: buff.reversed())
                    self.head = newTail
                }
                self.count = self.capacity
                
                return true
            } ?? false
        
        if !done {
            for newElement in newElements {
                pushFront(newElement)
            }
        }
    }
    
    // MARK: - Inserting
    /// Insert all elements in given collection starting from given index, keeping their original order.
    /// Eventually grows the capacity of the storage if needed, adopting the smart capacity policy
    /// on the basis of the specified value for `usingSmartCapacityPolicy` parameter.
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
    /// - Parameter usingSmartCapacityPolicy:   A Boolean value. When set to `true`, the eventual resizing
    ///                                         of the buffer `capacity` value is done by adopting
    ///                                         the smart capacity policy.
    ///                                         Otherwise, when set to `false`, the eventual resize of the
    ///                                         buffer `capacity` value will match exctly the instance's
    ///                                         `count` value after the insert operation.
    ///                                         **Defaults to true**.
    @inlinable
    public func insertAt<C: Collection>(index: Int, contentsOf newElements: C,  usingSmartCapacityPolicy: Bool = true) where C.Iterator.Element == Element {
        precondition(index >= 0 && index <= count, "Index is out of bounds")
        // Check if there are elements to insert:
        guard
            !newElements.isEmpty
        else { return }
        
        let newCount = count + newElements.count
        if newCount <= capacity {
            // capacity is enough to hold addition, thus insert newElements in place
            fastInplaceInsert(newElements, at: index)
        } else {
            // We have to resize
            let newCapacity = usingSmartCapacityPolicy ? Self.smartCapacityFor(count: newCount) : newCount
            fastResizeElements(to: newCapacity, insert: newElements, at: index)
        }
    }
    
}
