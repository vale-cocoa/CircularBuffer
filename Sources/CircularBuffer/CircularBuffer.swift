//
// CircularBuffer.swift
// CircularBuffer
//
//  Created by Valeriano Della Longa on 2020/09/24.
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

/// A memory buffer providing amortized O(1) performance for operations on its stored elements at both start and end
/// positions.
///
/// This reference type can suit as the underlaying buffer of `MutableCollection` value types needing to perform O(1)
/// for operations of insertion and removal on both, the first and last elements.
/// For example `Array` performs in O(1) on operations involving removal/insertion of its last element,
/// but only O(*n*) on its first element (where *n* is the number of elements successive the first one).
/// That's due to the fact that `Array` has to shift elements successive its first one in order to keep its indexing order intact.
/// On the other hand, `CircularBuffer` uses a clever *head* and *tail* internal indexes system which makes possible
/// not to shift elements when removing/inserting at the first and last indexes.
/// `CircularBuffer` provides functionalities for storing and removing elements which may overwrite
/// elements previously stored when its storage capacity has been filled-up, allowing it be used effectively as a ring-buffer.
/// It also provides functionalities for storing and removing new elements with the increase/decrease of the storage capacity.
/// These latter functionalities might as well be used in conjuction with the *smart capacity policy*,
/// that is a strategy for increasing/decreasing the capacity of the storage so that the operations
/// for elements addition/removal won't trigger the resize of the underlaying memory buffer too often,
/// hence not affecting the overall performance of those operations.
public final class CircularBuffer<Element> {
    var elements: UnsafeMutablePointer<Element>
    
    /// The total number of elements the buffer can hold without having to reallocate memory.
    public internal(set) var capacity: Int
    
    /// The number of stored elements
    public internal(set) var count: Int
    
    var head: Int
    
    var tail: Int
    
    // MARK: - Initializing and deinitializing
    /// Returns a new empty `CircularBuffer` instance, initialized with a capacity value which can hold the
    /// given number of elements.
    ///
    /// - Parameter capacity:   An `Int` value representing the number of elements this instance can hold
    ///                         without having to reallocate memory. **Must not be negative**.
    ///                         Defaults to `0`.
    /// - Parameter usingSmartCapacityPolicy:   A Boolean value. When `true` is specified, then the
    ///                                         `capacity` value of the returned instance is calculated
    ///                                         by using the smart capacity policy.
    ///                                         When `false` is specified, the `capacity` value of the
    ///                                         returned instance will match exactly the value specified in the
    ///                                         call.
    ///                                         **Defaults to true**.
    /// - Note: The `usingSmartCapacityPolicy` flag plays an important role in regards to how the buffer
    ///         sizing will result in the returned instance. For example when specifying a `capacity` value of `0`
    ///         in conjuction with a `usingSmartCapacityPolicy` value of `true`, the returned instance will have
    ///         a `capacity` value greater than `0`.
    public init(capacity: Int = 0, usingSmartCapacityPolicy: Bool = true) {
        precondition(capacity >= 0, "Negative capacity values are not allowed.")
        let newCapacity = usingSmartCapacityPolicy ? Self.smartCapacityFor(count: capacity) : capacity
        self.elements = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        self.capacity = newCapacity
        self.count = 0
        self.head = 0
        self.tail = 0
    }
    
    /// Returns a new `CircularBuffer` instance initialized and containing the same element
    /// specified as `repeated` parameter for the specified number of times specified as `count` parameter value.
    ///
    /// - Parameter repeating: The element to store repeatedly.
    /// - Parameter count:  The number of times to repeat the given element in the storage. Must be greater than
    ///                     or equal to zero
    /// - Parameter usingSmartCapacityPolicy:   A Boolean value. When `true` is specified, then the
    ///                                         `capacity` value of the returned instance is calculated
    ///                                         by using the smart capacity policy.
    ///                                         When `false` is specified, the `capacity` value of the
    ///                                         returned instance will match exactly the value specified
    ///                                         as `count` parameter.
    ///                                         **Defaults to true**.
    /// - Returns:  A new `CircularBuffer` instance initialized and containing the same element
    ///             specified as `repeated` parameter for the specified number of times
    ///             specified as `count` parameter value.
    /// - Note: If `count` is zero, returns an empty instance.
    ///         The `usingSmartCapacityPolicy` flag plays an important role in regards to how the buffer
    ///         sizing will result in the returned instance.
    ///         For example when specifying a `count` value of `0` in conjuction with a
    ///         `usingSmartCapacityPolicy` value of `true`, the returned instance will have
    ///         a `capacity` value greater than `0`.
    public init(repeating repeated: Element, count: Int, usingSmartCapacityPolicy: Bool = true) {
        precondition(count >= 0)
        let nCapacity = usingSmartCapacityPolicy ? Self.smartCapacityFor(count: count) : count
        self.elements = UnsafeMutablePointer<Element>.allocate(capacity: nCapacity)
        
        if count > 0 {
            self.elements.initialize(repeating: repeated, count: count)
        }
        self.capacity = nCapacity
        self.count = count
        self.tail = count == nCapacity ? 0 : count
        self.head = 0
    }
    
    /// A new `CircularBuffer` instance initialized and containing the same elements of the sequence
    /// specified as `elements` parameter, stored in the same order of the sequence enumeration.
    ///
    /// - Parameter elements: A sequence of elements to store. **Must be finite**.
    /// - Parameter usingSmartCapacityPolicy:   A Boolean value. When `true` is specified, then the
    ///                                         `capacity` value of the returned instance is calculated
    ///                                         by using the smart capacity policy.
    ///                                         When `false` is specified, the `capacity` value of the
    ///                                         returned instance will match exactly the lenght of the specified
    ///                                         sequence.
    ///                                         **Defaults to true**.
    /// - Returns: A new `CircularBuffer` instance initialized and containing the same elements of the sequence
    ///            specified as `elements` parameter, stored in the same order of the sequence enumeration.
    /// - Note: When `elements`is an empty sequence, it returns an empty instance.
    ///         The `usingSmartCapacityPolicy` flag plays an important role in regards to how the buffer
    ///         sizing will result in the returned instance.
    ///         For example when specifying a `usingSmartCapacityPolicy` value of `true`,
    ///         the returned instance might have a `capacity` value greater than
    ///         the lenght of the specified sequence.
    public convenience init<S: Sequence>(elements: S, usingSmartCapacityPolicy: Bool = true) where Element == S.Iterator.Element {
        var capacity: Int!
        var buffer: UnsafeMutablePointer<Element>!
        var count: Int!
        
        let done: Bool = elements
            .withContiguousStorageIfAvailable({ buff -> Bool in
                capacity = usingSmartCapacityPolicy ? Self.smartCapacityFor(count: buff.count) : buff.count
                buffer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
                count = buff.count
                if count > 0 {
                    buffer.initialize(from: buff.baseAddress!, count: count)
                }
                
                return true
            }) ?? false
        
        if !done {
            let sequenceCount = elements.underestimatedCount
            var sequenceIterator = elements.makeIterator()
            if
                let firstElement = sequenceIterator.next()
            {
                capacity = usingSmartCapacityPolicy ? Self.smartCapacityFor(count: sequenceCount) : sequenceCount
                count = 1
                buffer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
                buffer.initialize(to: firstElement)
                while let nextElement = sequenceIterator.next() {
                    if count + 1 >= capacity {
                        capacity = usingSmartCapacityPolicy ? Self.smartCapacityFor(count: count + 1) : count + 1
                        let swap = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
                        swap.moveInitialize(from: buffer, count: count)
                        buffer.deallocate()
                        buffer = swap
                    }
                    buffer.advanced(by: count).initialize(to: nextElement)
                    count += 1
                }
            } else {
                capacity = usingSmartCapacityPolicy ? Self.minSmartCapacity : 0
                count = 0
                buffer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
            }
        }
        
        self.init(elements: buffer, capacity: capacity, count: count, head: 0, tail: (count == capacity ? 0 : count))
    }
    
    /// Returns a new instance initialized to contain a copy of the elements stored in the `CircularBuffer` instance
    /// specified as `other` parameter, also with same `capacity`, `count`, `head` and `tail` values of the
    /// other instance.
    ///
    /// - Parameter other: A `CircularBuffer` instance to copy values from for the initializing instance.
    /// - Returns:  A new instance initialized to contain a copy of the elements stored in `other` as well as
    ///             the adopting same `capacity`, `count`, `head` and `tail` values from `other`.
    public init(other: CircularBuffer) {
        self.capacity = other.capacity
        self.elements = UnsafeMutablePointer<Element>.allocate(capacity: other.capacity)
        if other.head + other.count > other.capacity {
            let rightCount = other.capacity - other.head
            self.elements.advanced(by: other.head).initialize(from: other.elements.advanced(by: other.head), count: rightCount)
            self.elements.initialize(from: other.elements, count: other.count - rightCount)
        } else {
            self.elements.advanced(by: other.head).initialize(from: other.elements.advanced(by: other.head), count: other.count)
        }
        self.count = other.count
        self.head = other.head
        self.tail = other.tail
    }
    
    init(elements: UnsafeMutablePointer<Element>, capacity: Int, count: Int, head: Int, tail: Int) {
        self.elements = elements
        self.capacity = capacity
        self.count = count
        self.head = head
        self.tail = tail
    }
    
    deinit {
        unsafeDeinitializeElements(advancedToBufferIndex: head, count: count)
        elements.deallocate()
    }
    
    // MARK: - Computed properties
    /// Flags if all the capacity is taken.
    public var isFull: Bool {
        count == capacity
    }
    
    /// Flags if there aren't elements stored.
    public var isEmpty: Bool {
        count == 0
    }
    
    /// The number of additional elements that can be stored without having to reallocate memory.
    public var residualCapacity: Int { (capacity - count) }
    
    /// The element stored at first position.
    ///
    /// - Note: equals `last` when there is just one element stored, `nil` when `isEmpty` is `true`
    public var first: Element? {
        guard !isEmpty else { return nil }
        
        return elements.advanced(by: head).pointee
    }
    
    /// The element stored at last position.
    ///
    /// - Note: equals `first` when there is just one elment stored, `nil` when `isEmpty` is `true`
    public var last: Element? {
        guard !isEmpty else { return nil }
        
        return elements.advanced(by: decrementBufferIndex(tail)).pointee
    }
    
    // MARK: - Subscript
    /// Access stored element at specified position.
    ///
    /// The following example uses indexed subscripting to update the second element. After assigning the new value
    /// at a specific position, that value is immediately available at that same position.
    /// ```
    /// let buffer = CircularBuffer<Int>(repeating: 1, count: 3)
    /// // buffer's elements: [1, 1, 1]
    /// buffer[1] = 10
    /// // buffer's elements now are: [1, 10, 1]
    /// print("buffer[1]")
    /// // prints "10"
    /// ```
    /// - Parameter position:   An `Int` value representing the `index` of the element to access.
    ///                         The range of possible indexes is zero-based —i.e. first element stored is
    ///                         at index 0. Must be greater than or equal `0` and less than `count` value
    ///                         of the instance.
    ///                          **When isEmpty is true, no index value is valid for subscript.**
    /// - Complexity: O(1) for both write and read access.
    public subscript(position: Int) -> Element {
        get {
            checkSubscriptBounds(for: position)
            let idx = bufferIndex(from: position)
            
            return elements.advanced(by: idx).pointee
        }
        
        set {
            checkSubscriptBounds(for: position)
            let idx = bufferIndex(from: position)
            elements.advanced(by: idx).pointee = newValue
        }
    }
    
    // MARK: - Copy
    /// Returns a copy of the `CircularBuffer` instance, eventually with increased capacity, containing a copy of the
    /// elements stored in the calee stored in the same order.
    ///
    /// - Parameter additionalCapacity: Additional capacity to add to the copy. **Must not be negative**.
    ///                                 Defaults to zero.
    /// - Parameter usingSmartCapacityPolicy:   A Boolean value. When `true` is specified, then the
    ///                                         `capacity` value of the returned copy is calculated
    ///                                         by using the smart capacity policy.
    ///                                         When `false` is specified, the `capacity` value of the
    ///                                         returned copy will match exactly
    ///                                         the value of callee's `capacity` plus the value specified
    ///                                         as `additionalCapacity` parameter.
    ///                                         **Defaults to true**
    /// - Returns:  A copy of the `CircularBuffer` instance, eventually with increased capacity,
    ///             containing a copy of the elements stored in the calee in the same order.
    /// - Note: The `usingSmartCapacityPolicy` flag plays an important role in regards to how the buffer
    ///         sizing will result in the returned instance.
    ///         For example when specifying `true` as `usingSmartCapacityPolicy` value ,
    ///         the returned instance might have a `capacity` value greater than the value obtained by the sum of
    ///         the callee's `capacity` value and the value specified as `additionalCapacity` parameter.
    public func copy(additionalCapacity: Int = 0, usingSmartCapacityPolicy: Bool = true) -> CircularBuffer {
        let newCapacity = additionalCapacity > 0 ? (usingSmartCapacityPolicy ? Self.smartCapacityFor(count: capacity + additionalCapacity) : additionalCapacity + capacity) : capacity
        let copy = CircularBuffer(capacity: newCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
        if !isEmpty {
            unsafeInitializeFromElements(advancedToBufferIndex: head, count: count, to: copy.elements)
        }
        
        copy.count = count
        copy.head = 0
        copy.tail = copy.incrementBufferIndex(copy.count - 1)
        
        return copy
    }
    
    // MARK: - reserveCapacity(_:usingSmartCapacityPolicy:)
    /// Reserve enough memory in the underlaying buffer so that it has enough free spots for new elements
    /// at least equal to the value specified as `minimumCapacity`.
    ///
    /// - Parameter _:  An `Int` value representing the minimum number of free slots
    ///                 the buffer should have for storing new elements without reallocating memory.
    ///                 **Must not be negative**.
    /// - Parameter usingSmartCapacityPolicy:   A Boolean value. When `true` is specified, then the
    ///                                         `capacity` value of the instance is calculated
    ///                                         by using the smart capacity policy.
    ///                                         When `false` is specified, the `capacity` value of the
    ///                                         instance will match exactly its `count` value plus the
    ///                                         value specified as `minimumCapacity`.
    ///                                         **Defaults to true**
    /// - Note: The `usingSmartCapacityPolicy` flag plays an important role in regards to how the buffer
    ///         sizing will be done.
    ///         For example when specifying `true` as `usingSmartCapacityPolicy` value ,
    ///         the `capacity` value might be greater than the value obtained by the sum of
    ///         the callee's `count` value and the value specified as `minimumCapacity` parameter.
    ///         If callee's `residualCapacity` is greater than or equal to the value specified as
    ///         `minimumCapacity` parameter, no resizing will occur.
    public func reserveCapacity(_ minimumCapacity: Int, usingSmartCapacityPolicy: Bool = true) {
        precondition(minimumCapacity >= 0)
        guard
            minimumCapacity > 0,
            residualCapacity < minimumCapacity
        else { return }
        
        let newCapacity = capacityFor(newCount: count + minimumCapacity, usingSmartCapacityPolicy: usingSmartCapacityPolicy)
        fastResizeElements(to: newCapacity)
    }
}
