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
public final class CircularBuffer<Element> {
    private(set) var _elements: UnsafeMutablePointer<Element>
    
    private(set) var _capacity: Int
    
    private(set) var _head: Int
    
    private(set) var _tail: Int
    
    private(set) var _elementsCount: Int
    
    // MARK: - Initializing and deinitializing
    /// Returns a new empty `CircularBuffer` instance, with its capacity set to the minimum value.
    public init() {
        self._elements = UnsafeMutablePointer<Element>.allocate(capacity: Self._minCapacity)
        self._capacity = Self._minCapacity
        self._elementsCount = 0
        self._head = 0
        self._tail = 0
    }
    
    /// Returns a new empty `CircularBuffer` instance, initialized with a capacity value which can hold the
    /// given number of elements.
    ///
    /// - Parameter capacity: the number of elements this instance can hold. Must be greater than or equal to zero.
    /// - Note: when given a `capacity` value of 0, the returned instance will be initialized to the minimum capacity
    ///         level. In general the returned instance might have a bigger capacity level than the given one, due to
    ///         internal optimizations.
    public init(capacity: Int) {
        let nCapacity = Self._convenientCapacityFor(capacity: capacity)
        self._elements = UnsafeMutablePointer<Element>.allocate(capacity: nCapacity)
        self._capacity = nCapacity
        self._elementsCount = 0
        self._head = 0
        self._tail = 0
    }
    
    /// Returns a new `CircularBuffer` instance initialized to contain the same element for the given number of times.
    ///
    /// - Parameter repeating: the element to store repeatedly.
    /// - Parameter count:  the number of times to repeat the given element in the storage. Must be greater than
    ///                     or equal to zero
    /// - Note: if `count` is zero, returns an empty instance.
    public init(repeating repeated: Element, count: Int) {
        precondition(count >= 0)
        let nCapacity = Self._convenientCapacityFor(capacity: count)
        self._elements = UnsafeMutablePointer<Element>.allocate(capacity: nCapacity)
        
        if count > 0 {
            self._elements.initialize(repeating: repeated, count: count)
        }
        self._capacity = nCapacity
        self._elementsCount = count
        self._tail = count == nCapacity ? 0 : count
        self._head = 0
    }
    
    /// Returns a new `CircularBuffer` instance initialized to contain the same elements of the given sequence,
    /// in the same order.
    ///
    /// - Parameter elements: a sequence of elements to store.
    /// - Note: when given an empty sequence, it returns an empty instance.
    public init<S: Sequence>(elements: S) where Element == S.Iterator.Element {
        var capacity: Int!
        var buffer: UnsafeMutablePointer<Element>!
        var count: Int!
        
        let done: Bool = elements
            .withContiguousStorageIfAvailable({ buff -> Bool in
                capacity = Self._convenientCapacityFor(capacity: buff.count)
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
                capacity = Self._convenientCapacityFor(capacity: sequenceCount)
                count = 1
                buffer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
                buffer.initialize(to: firstElement)
                while let nextElement = sequenceIterator.next() {
                    if count + 1 >= capacity {
                        capacity = Self._convenientCapacityFor(capacity: count + 1)
                        let swap = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
                        swap.moveInitialize(from: buffer, count: count)
                        buffer.deallocate()
                        buffer = swap
                    }
                    buffer.advanced(by: count).initialize(to: nextElement)
                    count += 1
                }
            } else {
                capacity = Self._minCapacity
                count = 0
                buffer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
            }
        }
        
        self._elements = buffer
        self._capacity = capacity
        self._elementsCount = count
        self._head = 0
        self._tail = count == capacity ? 0 : count
    }
    
    deinit {
        _deinitializeElements(advancedToBufferIndex: _head, count: _elementsCount)
        _elements.deallocate()
    }
    
}

// MARK: - Public Interface
// MARK: - Computed properties
extension CircularBuffer {
    /// The total number of elements the buffer can hold without having to reallocate memory.
    public var capacity: Int { _capacity }
    
    /// Flags if all the capacity is taken.
    public var isFull: Bool {
        _elementsCount == _capacity
    }
    
    /// Flags if there aren't elements stored.
    public var isEmpty: Bool {
        _elementsCount == 0
    }
    
    /// The number of stored elements
    public var count: Int {
        _elementsCount
    }
    
    /// The number of additional elements that can be stored without reallocating memory.
    public var residualCapacity: Int { _residualCapacity }
    
    /// The element stored at first position.
    ///
    /// - Note: equals `last` when there is just one element stored, `nil` when `isEmpty` is `true`
    public var first: Element? {
        guard !isEmpty else { return nil }
        
        return _elements.advanced(by: _head).pointee
    }
    
    /// The element stored at last position.
    ///
    /// - Note: equals `first` when there is just one elment stored, `nil` when `isEmpty` is `true`
    public var last: Element? {
        guard !isEmpty else { return nil }
        
        return _elements.advanced(by: decrementIndex(_tail)).pointee
    }
    
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
        if _head + _elementsCount > _capacity {
            _fastRotateBufferHeadToZero()
        }
        
        let buff = UnsafeBufferPointer(start: _elements.advanced(by: _head), count: _elementsCount)
        
        return try body(buff)
    }
    
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
        if _head + _elementsCount > _capacity {
            _fastRotateBufferHeadToZero()
        }
        // save actual state:
        let elements = _elements
        let prevCapacity = _capacity
        let prevCount = _elementsCount
        let prevHead = _head
        let prevTail = _tail
        
        // temporarly change internal state to empty
        _elements = UnsafeMutablePointer<Element>.allocate(capacity: Self._minCapacity)
        _capacity = Self._minCapacity
        _elementsCount = 0
        _head = 0
        _tail = 0
        
        // prepare the buffer that will be passed to body
        var buff = UnsafeMutableBufferPointer<Element>(start: elements.advanced(by: prevHead), count: prevCount)
        
        defer {
            // Once body has executed, restore the state:
            precondition(buff.baseAddress == elements && buff.count == prevCount, "CircularBuffer withUnsafeMutableBufferPointer: replacing the buffer is not allowed")
            self._elements.deallocate()
            self._elements = elements
            self._capacity = prevCapacity
            self._elementsCount = prevCount
            self._head = prevHead
            self._tail = prevTail
        }
        
        // execute body and return its result
        return try body(&buff)
    }
    
}

// MARK: - Common operations
extension CircularBuffer {
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
    /// - Parameter position: an `Int` value representing the `index` of the element to access. The range of
    /// possible indexes is zero-based —i.e. first element stored is at index 0. Must be greater than or equal `0` and less
    /// than `count` value of the instance. **When isEmpty is true, no index value is valid for subscript.**
    /// - Complexity: O(1) for both write and read access.
    public subscript(position: Int) -> Element {
        get {
            _checkSubscriptBounds(for: position)
            let idx = bufferIndex(from: position)
            
            return _elements.advanced(by: idx).pointee
        }
        
        set {
            _checkSubscriptBounds(for: position)
            let idx = bufferIndex(from: position)
            _elements.advanced(by: idx).pointee = newValue
        }
    }
    
    // MARK: - ForEach
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
        for i in 0..<_elementsCount {
            let idx = bufferIndex(from: i)
            try body(_elements.advanced(by: idx).pointee)
        }
    }
    
    // MARK: - Copy
    /// Returns a copy of the `CircularBuffer` instance, eventually with increased capacity, containing a copy of the
    ///  same elements stored in the calee in the same order.
    ///
    /// - Parameter additionalCapacity: additional capacity to add to the copy. Must be greater than or equal
    /// to zero. Defaults to zero.
    /// - Complexity: amortized O(1).
    public func copy(additionalCapacity: Int = 0) -> CircularBuffer {
        let newCapacity = additionalCapacity > 0 ? Self._convenientCapacityFor(capacity: _capacity + additionalCapacity) : _capacity
        let copy = CircularBuffer(capacity: newCapacity)
        if !isEmpty {
            _initializeFromElements(advancedToBufferIndex: _head, count: _elementsCount, to: copy._elements)
        }
        
        copy._elementsCount = _elementsCount
        copy._head = 0
        copy._tail = copy.incrementIndex(copy._elementsCount - 1)
        
        return copy
    }
    
    // MARK: - reserveCapacity(_:)
    /// Allocate more space in the underlying buffer to hold actual elements count plus the addtional number in the
    /// request.
    ///
    /// - Parameter _: the number of minimum free slots the buffer should have. Must be positive.
    public func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0)
        guard
            minimumCapacity > 0,
            _residualCapacity < minimumCapacity
        else { return }
        
        let newCapacity = Self._convenientCapacityFor(capacity: _elementsCount + minimumCapacity)
        _fastResizeElements(to: newCapacity)
    }
    
}

// MARK: - Add new elements
extension CircularBuffer {
    // MARK: - Appending
    /// Stores the given element, puttting it at the last position of the storage.
    ///
    /// - Parameter _: the element to store of type `Element`.
    /// - Complexity: amortized O(1).
    /// - Note: when `isFull` is `true`, grows the capacity of the storage so it can hold the new count of elements.
    public func append(_ newElement: Element) {
        if isFull {
            _growToNextCapacityLevel()
        }
        _elements.advanced(by: _tail).initialize(to: newElement)
        _tail = incrementIndex(_tail)
        _elementsCount += 1
    }
    
    /// Stores the given sequence of elements at the last position of the storage.
    ///
    /// - Parameter contentsOf: a sequence of elements to append.
    /// - Note: calls iteratively `append(:_)` for each element of the given sequence.
    ///         Capacity is grown when necessary to hold all new elements.
    ///         A better appending performance is obtained when the given sequence's `underestimatedCount`
    ///         value is the closest to the real count of elements of the sequence.
    @inline(__always)
    public func append<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    append(contentsOf: buff)
                    
                    return true
                })
        else {
            var elementsIterator = newElements.makeIterator()
            guard
                let firstNewElement = elementsIterator.next()
                else { return }
            
            let additionalElementsCount = newElements.underestimatedCount - _residualCapacity
            if additionalElementsCount > 0 {
                let newCapacity = Self._convenientCapacityFor(capacity: _capacity + additionalElementsCount)
                _fastResizeElements(to: newCapacity)
            }
            append(firstNewElement)
            while let nextNewElement = elementsIterator.next() {
                append(nextNewElement)
            }
            
            return
        }
    }
    
    @usableFromInline
    internal func append<C: Collection>(contentsOf newElements: C) where C.Iterator.Element == Element {
        guard newElements.count > 0 else { return }
        
        if _elementsCount + newElements.count <= _capacity
        {
            // actual buffer can hold all elements, thus append newElements in place
            let finalBufIdx = _initializeElements(advancedToBufferIndex: _tail, from: newElements)
            _elementsCount += newElements.count
            _tail = incrementIndex(finalBufIdx - 1)
        } else {
            // resize buffer to the right capacity and append newElements
            let newCapacity = Self._convenientCapacityFor(capacity: _capacity + newElements.count)
            _fastResizeElements(to: newCapacity, insert: newElements, at: _elementsCount)
        }
    }
    
    // MARK: - Prepending
    /// Stores given element at the topmost position of the storage.
    ///
    /// - Parameter _: the element to store of type `Element`.
    /// - Complexity: amortized O(1)
    /// - Note: when `isFull` is `true`, grows the capacity of the storage so it can hold the new count of elements.
    public func push(_ newElement: Element) {
        if isFull {
            _growToNextCapacityLevel()
        }
        _head = decrementIndex(_head)
        _elements.advanced(by: _head).initialize(to: newElement)
        _elementsCount += 1
    }
    
    /// Stores the given sequence of elements at the first position of the storage.
    ///
    /// Since the sequence is iterated and at each iteration an element is pushed, the elements will appear in
    /// reversed order inside the `CircularBuffer`:
    /// ```
    /// let sequence = AnySequence(1..<4)
    /// let buffer = CircularBuffer<Int>()
    /// buffer.push(contentsOf: sequence)
    /// // buffer's storage: [3, 2, 1]
    /// ```
    /// - Parameter contentsOf: a sequence of elements to push.
    /// - Note: calls iteratively `push(:_)` for each element of the given sequence.
    ///         Capacity is grown when necessary to hold all new elements.
    ///         A better appending performance is obtained when the given sequence's `underestimatedCount`
    ///         value is the closest to the real count of elements of the sequence.
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
            
            let additionalElementsCount = newElements.underestimatedCount - _residualCapacity
            if additionalElementsCount > 0 {
                let newCapacity = Self._convenientCapacityFor(capacity: _capacity + additionalElementsCount) 
                _fastResizeElements(to: newCapacity)
            }
            push(firstNewElement)
            while let nextNewElement = elementsIterator.next() {
                push(nextNewElement)
            }
            
            return
        }
        
    }
    
    /// Stores the given collection of elements at first position of the storage, mainteining their order.
    ///
    /// ```
    /// let newElements = [1, 2, 3]
    /// let buffer = CircularBuffer<Int>()
    /// buffer.prepend(contentsOf: newElements)
    /// // buffer's storage: [1, 2, 3]
    /// ```
    /// - Parameter contentsOf: a collection of `Element` instances to store at the top of the storage.
    /// - Complexity: amortized O(1) when given collection implements
    /// `withContiguousStorageIfAvailable(body:)` method. Otherwise O(n),
    /// where n is the number of elements stored in the collection.
    public func prepend<C: Collection>(contentsOf newElements: C) where C.Iterator.Element == Element {
        guard newElements.count > 0 else { return }
        
        if _elementsCount + newElements.count <= _capacity
        {
            // actual buffer can hold all elements, thus prepend _newElements in place…
            // Calculate the buffer index where newElements have to be appended:
            let newHead = _head - newElements.count < 0 ? _capacity - (newElements.count - _head) : _head - newElements.count
            // Copy newElements in place:
            _initializeElements(advancedToBufferIndex: newHead, from: newElements)
            
            // Update both _elementsCount and _head to new values:
            _elementsCount += newElements.count
            _head = newHead
        } else {
            // resize buffer to the right capacity prepending _newElements
            let newCapacity = Self._convenientCapacityFor(capacity: _capacity + newElements.count)
            _fastResizeElements(to: newCapacity, insert: newElements, at: 0)
        }
    }
    
    // MARK: - Inserting
    /// Insert all elements in given collection starting from given index., keeping their original order.
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
    /// - Parameter index:  an `Int` value representing the index where to start inserting the given
    ///                     collection of elements.
    ///                     Must be greater than or equal zero and less than or equal `count`.
    ///                     When specifying zero as `index` the operation is same as in
    ///                     `prepend(contentsOf:)`;
    ///                     on the other hand when `index` has a value equal to`count`,
    ///                     the operation is the same as in `append(contentsOf:)`.
    /// - Parameter contentsOf: a collection of `Element` instances to insert in the buffer starting from given
    ///                         `index` parameter.
    public func insertAt<C: Collection>(index: Int, contentsOf newElements: C) where C.Iterator.Element == Element {
        precondition(index >= 0 && index <= _elementsCount)
        
        // Check if it's a prepend operation:
        guard
            index != 0
        else {
            prepend(contentsOf: newElements)
            
            return
        }
        
        // Otherwise could be an append operation:
        guard
            index != _elementsCount
        else {
            append(contentsOf: newElements)
            
            return
        }
        
        // Check if there's elements to insert:
        guard
            !newElements.isEmpty
        else { return }
        
        if _elementsCount + newElements.count <= _capacity {
            // capacity is enough to hold addition, thus insert newElements in place
            let buffIdx = bufferIndex(from: index)
            
            // Temporarly move out elements that has to be shifted:
            let elementsToShiftCount = _elementsCount - index
            let swap = UnsafeMutablePointer<Element>.allocate(capacity: elementsToShiftCount)
            _moveInitialzeFromElements(advancedToBufferIndex: buffIdx, count: elementsToShiftCount, to: swap)
            
            // Copy newElements in place, obtaining the buffer index where the shifted
            // elements have to be moved back in:
            let buffIdxForFirstShifted = _initializeElements(advancedToBufferIndex: buffIdx, from: newElements)
            
            // Move back into the buffer the elements which shift position, obtaining the
            // next buffer index after them (which will be used to calculate the
            // new _tail index):
            let lastBuffIdx = _moveInitializeToElements(advancedToBufferIndex: buffIdxForFirstShifted, from: swap, count: elementsToShiftCount)
            
            // Cleanup, update both _elementsCount and _tail to new values:
            swap.deallocate()
            _elementsCount += newElements.count
            _tail = incrementIndex(lastBuffIdx - 1)
        } else {
            // We have to resize
            let newCapacity = Self._convenientCapacityFor(capacity: _elementsCount + newElements.count)
            _fastResizeElements(to: newCapacity, insert: newElements, at: index)
        }
    }
    
}

// MARK: - Remove elements
extension CircularBuffer {
    /// Removes and returns –if present– the first element in the storage.
    ///
    /// - Returns: the first element of type `Element` of the storage; `nil` when `isEmpty` is `true`.
    /// - Complexity: amortized O(1)
    /// - Note: the capacity of the buffer might get downsized after the operation has removed a stored element, and
    ///         will get downsized to the minimum value when after the removal operation the buffer will be empty.
    @discardableResult
    public func popFirst() -> Element? {
        guard !self.isEmpty else { return nil }
        
        let element = _elements.advanced(by: _head).move()
        _head = incrementIndex(_head)
        _elementsCount -= 1
        _reduceCapacityForCurrentElementsCount()
        
        return element
    }
    
    /// Removes and returns –if present– the last element in the storage.
    ///
    /// - Returns: the flast element of type `Element` of the storage; `nil` when `isEmpty` is `true`.
    /// - Complexity: amortized O(1)
    /// - Note: the capacity of the buffer might get downsized after the operation has removed a stored element, and
    ///         will get downsized to the minimum value when after the removal operation the buffer will be empty.
    @discardableResult
    public func popLast() -> Element? {
        guard !self.isEmpty else { return nil }
        
        _tail = decrementIndex(_tail)
        let element = _elements.advanced(by: _tail).move()
        _elementsCount -= 1
        _reduceCapacityForCurrentElementsCount()
        
        return element
    }
    
    /// Removes and returns first *k* number of elements from the storage. Eventually reduces the buffer capacity when
    /// specified in the callee by giving a value of `true` as `keepCapacity` parameter value.
    ///
    /// - Parameter _:  an `Int` value representing the *k* number of elements to remove from the
    ///                 head of the storage.
    ///                 Must be greater than or equal to `0`, and less than or equal `count` value.
    /// - Parameter keepCapacity:   boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Returns: an `Array<Element>` containing the removed elements, in the same order as they were inside
    /// the storage.
    /// - Complexity: amortized O(1).
    /// - Note: calling this method with `0` as *k* elements to remove and `true` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with a value equals to `count` as *k* elements to remove,
    ///         and `true` as `keepCapacity` value, all elements will be removed from the storage,
    ///         and its capacity will be reduced to the minimum possible one.
    @discardableResult
    public func removeFirst(_ k: Int, keepCapacity: Bool = true) -> [Element] {
        precondition(k >= 0 && k <= _elementsCount, "operation not permitted with given count value")
        guard
            k < _elementsCount
        else { return removeAll(keepCapacity: keepCapacity) }
        
        guard k > 0 else {
            defer {
                if !keepCapacity {
                    _reduceCapacityForCurrentElementsCount()
                }
            }
            
            return []
        }
        
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        _moveInitialzeFromElements(advancedToBufferIndex: _head, count: k, to: removed)
        
        defer {
            _head = _head + k > _capacity ? incrementIndex(k - (_capacity - _head) - 1) : incrementIndex(_head + k - 1)
            _elementsCount -= k
            _tail = incrementIndex(_head + _elementsCount - 1)
            if !keepCapacity {
                _reduceCapacityForCurrentElementsCount()
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
    /// - Parameter _:  an `Int` value representing the *k* number of elements to remove from the tail
    ///                 of the storage.
    ///                 Must be greater than or equal to `0`, and less than or equal `count` value.
    /// - Parameter keepCapacity:   boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Complexity: amortized O(1).
    /// - Note: calling this method with `0` as *k* elements to remove and `true` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with a value equals to `count` as *k* elements to remove,
    ///         and `true` as `keepCapacity` value, all elements will be removed from the storage,
    ///         and its capacity will be reduced to the minimum possible one.
    @discardableResult
    public func removeLast(_ k: Int, keepCapacity: Bool = true) -> [Element] {
        precondition(k >= 0 && k <= _elementsCount, "operation not permitted with given count value")
        guard k < _elementsCount else { return removeAll(keepCapacity: keepCapacity) }
        
        guard k > 0 else {
            defer {
                if !keepCapacity {
                    _reduceCapacityForCurrentElementsCount()
                }
            }
            
            return []
        }
        
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        let buffIdxStart = _tail - k < 0 ? _capacity - k - _tail : _tail - k
        _moveInitialzeFromElements(advancedToBufferIndex: buffIdxStart, count: k, to: removed)
        
        defer {
            _elementsCount -= k
            _tail = buffIdxStart
            if !keepCapacity {
                _reduceCapacityForCurrentElementsCount()
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
    /// - Parameter index:  an `Int` value representing the position where to start the removal.
    ///                     Must be a valid subscript index: hence greater than or equal `zero`
    ///                     and less than `count` when `isEmpty` is false.
    /// - Parameter count:  an `Int` value representing the *k* number of elements to remove
    ///                     starting from the given `index` position.
    ///                     Must be greater than or equal `0`, less than or equal to the count of elements
    ///                     between the given `index` position and the end postion of the storage
    ///                     (`count - index`).
    /// - Parameter keepCapacity:   boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Returns:  an `Array<Element>` containing the removed elements, in the same order
    ///             as they were stored inside the storage.
    /// - Complexity: amortized O(1).
    /// - Note: calling this method with `0` as *k* elements to remove and `true` as `keepCapacity` value,
    ///         will result in not removing any stored element, but in possibly reducing the capacity of the storage.
    ///         On the other hand, when calling it with an `index` value of `0`,
    ///         a value equals to `count` as *k* elements to remove, and `true` as `keepCapacity` value,
    ///         all elements will be removed from the storage, and its capacity will be reduced
    ///         to the minimum possible one.
    @discardableResult
    public func removeAt(index: Int, count k: Int, keepCapacity: Bool = true) -> [Element] {
        _checkSubscriptBounds(for: index)
        precondition(k >= 0 && k <= _elementsCount - index, "operation not permitted with given count value")
        guard index != 0 else { return removeFirst(k, keepCapacity: keepCapacity) }
        
        guard index != _elementsCount - 1 else { return removeLast(k, keepCapacity: keepCapacity) }
        
        guard k > 0 else {
            defer {
                if !keepCapacity {
                    _reduceCapacityForCurrentElementsCount()
                }
            }
            
            return []
        }
        
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: k)
        
        // Get the real buffer index from given index:
        let buffIdx = bufferIndex(from: index)
        
        // move elements to remove, obtaining the buffer index from where some elements
        // might remain:
        let bufIdxOfSecondSplit = _moveInitialzeFromElements(advancedToBufferIndex: buffIdx, count: k, to: removed)
        
        // We defer the shifting of remaining elements/rejoining in a smaller buffer
        // operation after we have returned the removed elements
        defer {
            // Check if we ought move remaining elements to a smaller buffer, or if we
            // ought shift them inside the actual buffer to occupy the space left by
            //the removal:
            let newCapacity = keepCapacity ? _capacity : Self._convenientCapacityFor(capacity: _elementsCount - k)
            if newCapacity < _capacity {
                // Let's move remaining elements to a smaller buffer…
                let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
                
                // Remaining elements could be placed in two splits of current buffer:
                let countOfFirstSplit = index
                let countOfSecondSplit = _elementsCount - index - k
                
                // move into newBuff first split of _elements
                if countOfFirstSplit > 0 {
                    _moveInitialzeFromElements(advancedToBufferIndex: _head, count: countOfFirstSplit, to: newBuff)
                }
                
                // move into newBuff second split of _elements
                if countOfSecondSplit > 0 {
                    _moveInitialzeFromElements(advancedToBufferIndex: bufIdxOfSecondSplit, count: countOfSecondSplit, to: newBuff.advanced(by: countOfFirstSplit))
                }
                
                // Apply the change of buffer:
                _elements.deallocate()
                _elements = newBuff
                
                // update _capacity, _head, _elementsCount and _tail to new values
                _capacity = newCapacity
                _head = 0
                _elementsCount -= k
                _tail = incrementIndex(_elementsCount - 1)
            } else {
                // _capacity stays the same.
                // We have to eventually shift up remaining elements placed after the
                // removed ones:
                let countOfElementsToShift = _elementsCount - index - k
                let lastBufIdx: Int!
                if countOfElementsToShift > 0 {
                    // There are some remaining elements in the buffer, occupying positions
                    // below the removed ones.
                    // Let's first move them out _elements:
                    let swap = UnsafeMutablePointer<Element>.allocate(capacity: countOfElementsToShift)
                    _moveInitialzeFromElements(advancedToBufferIndex: bufIdxOfSecondSplit, count: countOfElementsToShift, to: swap)
                    
                    // then back in _elements at the index where the removal started,
                    // obtaining also the buffer index for recalculating the _tail:
                    lastBufIdx = _moveInitializeToElements(advancedToBufferIndex: buffIdx, from: swap, count: countOfElementsToShift)
                    swap.deallocate()
                } else {
                    // The removal ended up to the last element, hence the buffer index
                    // for calculating the new _tail is the one obtained from the removal.
                    lastBufIdx = bufIdxOfSecondSplit
                }
                
                // Update _elementsCount and _tail to the newValues:
                _elementsCount -= k
                _tail = incrementIndex(lastBufIdx - 1)
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
    /// - Parameter keepCapacity:   boolean value, when `true` is specified then
    ///                             the storage capacity gets eventually reduced at the end of removal; otherwise
    ///                             when set to `false`, storage capacity doesn't get reduced after the
    ///                             elements removal.
    ///                             Defaults to `false`.
    /// - Returns:  an `Array` containing the removed elements, in the same order as they were
    ///             stored inside the storage.
    @discardableResult
    public func removeAll(keepCapacity: Bool = true) -> [Element] {
        guard _elementsCount > 0 else {
            defer {
                if !keepCapacity && _capacity > Self._minCapacity {
                    self._capacity = Self._minCapacity
                    self._elements.deallocate()
                    self._elements = UnsafeMutablePointer<Element>.allocate(capacity: Self._minCapacity)
                    self._head = 0
                    self._tail = 0
                }
            }
            
            return []
        }
        
        let removed = UnsafeMutablePointer<Element>.allocate(capacity: _elementsCount)
        _moveInitialzeFromElements(advancedToBufferIndex: _head, count: _elementsCount, to: removed)
        let result = Array(UnsafeBufferPointer(start: removed, count: _elementsCount))
        removed.deinitialize(count: _elementsCount)
        removed.deallocate()
        
        defer {
            if !keepCapacity && _capacity > Self._minCapacity {
                _capacity = Self._minCapacity
                self._elements.deallocate()
                self._elements = UnsafeMutablePointer<Element>.allocate(capacity: _capacity)
            }
            _elementsCount = 0
            _head = 0
            _tail = 0
        }
        
        return result
    }
    
}

// MARK: - Replace elements
extension CircularBuffer {
    /// Replaces the elements stored at given range with the ones in the given collection.
    /// Eventually reduces the capacity of the buffer after the replace operation have occured, in case it will significally
    /// reduce the `count` value in respect to the current buffer capacity.
    /// Increases the buffer capacity when the operation will result in a `count` value larger than actual buffer capacity.
    ///
    /// When given `subRange.count` equals `0` –i.e. `0..<0`–, the given elements are inserted at the index
    /// position represented by the `subRange.lowerBound` –i.e. for `0..<0` elements are prepended in the storage.
    /// When given `subRange.count` is greater than `0` –i.e. `0..<2`–, but the given colletion of elements for
    ///  replacement is empty, then elements at the indexes in `subRange` are removed.
    /// - Parameter subrange:   a `Range<Int>`expression  representing the indexes of elements to replace.
    ///                         Must be in range of `0`...`count`.
    /// - Parameter with:   a collection of `Element` to insert in the storage as replacement of those elements
    ///                     stored at the given `subRange` indexes.
    public func replace<C: Collection>(subRange: Range<Int>, with newElements: C) where C.Iterator.Element == Element {
        precondition(subRange.lowerBound >= 0 && subRange.upperBound <= _elementsCount, "range of indexes out of bounds")
        if subRange.count == 0 {
            // It's an insertion
            guard !newElements.isEmpty else { return }
            
            if subRange.lowerBound == 0 {
                // newElements have to be prepended
                prepend(contentsOf: newElements)
            } else if subRange.lowerBound == _elementsCount {
                // newElements have to be appended
                append(contentsOf: newElements)
            } else {
                // newElements have to be inserted
                insertAt(index: subRange.lowerBound, contentsOf: newElements)
            }
        } else {
            // subRange count is greater than zero…
            if newElements.isEmpty {
                // …But the given colletion is empty.
                // It's a delete operation involving the _elements at indexes in subRange
                if subRange.lowerBound == 0 {
                    removeFirst(subRange.count, keepCapacity: false)
                } else if subRange.upperBound == _elementsCount {
                    removeLast(subRange.count, keepCapacity: false)
                } else {
                    removeAt(index: subRange.lowerBound, count: subRange.count, keepCapacity: false)
                }
            } else {
                // It's a replace operation!
                let newCount = _elementsCount - subRange.count + newElements.count
                let newCapacity = Self._convenientCapacityFor(capacity: newCount)
                if newCapacity == _capacity {
                    // No resize is needed, operation has to be done in place
                    let buffIdx = bufferIndex(from: subRange.lowerBound)
                    let countOfElementsToShift = _elementsCount - subRange.lowerBound - subRange.count
                    // Deinitialize the elements to remove obtaining the buffer index to
                    // the first element that eventually gets shifted:
                    let bufIdxOfFirstElementToShift = _deinitializeElements(advancedToBufferIndex: buffIdx, count: subRange.count)
                    
                    let lastBuffIdx: Int!
                    if countOfElementsToShift > 0 {
                        // We've got some elements to shift in the process.
                        // Let's move them temporarly out:
                        let swap = UnsafeMutablePointer<Element>.allocate(capacity: countOfElementsToShift)
                        _moveInitialzeFromElements(advancedToBufferIndex: bufIdxOfFirstElementToShift, count: countOfElementsToShift, to: swap)
                        
                        // Let's put newElements in place obtaining the buffer index
                        // where to put back the shifted elements:
                        let newBuffIdxForShifted = _initializeElements(advancedToBufferIndex: buffIdx, from: newElements)
                        
                        // Let's now put back th eelements that were shifted, obtaining
                        // the bufferIndex for calculating the new _tail:
                        lastBuffIdx = _moveInitializeToElements(advancedToBufferIndex: newBuffIdxForShifted, from: swap, count: countOfElementsToShift)
                        swap.deallocate()
                    } else {
                        // The operation doesn't involve any element to be shifted,
                        // thus let's just put in place newElements obtainig the buffer
                        // index for calculating the new _tail:
                        lastBuffIdx = _initializeElements(advancedToBufferIndex: buffIdx, from: newElements)
                    }
                    // Update _elementsCount and _tail to new values
                    _elementsCount = newCount
                    _tail = incrementIndex(lastBuffIdx - 1)
                } else {
                    // Resize is needed…
                    let buffIdx = bufferIndex(from: subRange.lowerBound)
                    let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
                    
                    let countOfFirstSplit = subRange.lowerBound
                    let countOfSecondSplit = _elementsCount - countOfFirstSplit - subRange.count
                    
                    // Deinitialize in _elements the replaced subrange and obtain the
                    // buffer index to second split of elements to move from _elements:
                    let secondSplitStartBuffIdx = _deinitializeElements(advancedToBufferIndex: buffIdx, count: subRange.count)
                    
                    // Now move everything in newBuff…
                    // Eventually the first split from _elements:
                    var newBuffIdx = 0
                    if countOfFirstSplit > 0 {
                        _moveInitialzeFromElements(advancedToBufferIndex: _head, count: countOfFirstSplit, to: newBuff)
                        newBuffIdx += countOfFirstSplit
                    }
                    
                    // Then newElements:
                    newBuff.advanced(by: newBuffIdx).initialize(from: newElements)
                    newBuffIdx += newElements.count
                    
                    // Eventually the second split from _elements:
                    if countOfSecondSplit > 0 {
                        _moveInitialzeFromElements(advancedToBufferIndex: secondSplitStartBuffIdx, count: countOfSecondSplit, to: newBuff.advanced(by: newBuffIdx))
                    }
                    
                    // deallocate and update _elements with newBuff:
                    _elements.deallocate()
                    _elements = newBuff
                    
                    // Update _capacity, _head, _elementsCount, _tail to new values:
                    _capacity = newCapacity
                    _head = 0
                    _elementsCount = newCount
                    _tail = incrementIndex(_elementsCount - 1)
                }
            }
        }
    }
    
}

// MARK: - Private Interface
// MARK: - Index helpers
extension CircularBuffer {
    @inline(__always)
    private func _checkSubscriptBounds(for position: Int) {
        precondition(position >= 0 && position < _elementsCount, "subscript index out of bounds")
    }
    
    @inline(__always)
    private func bufferIndex(from index: Int) -> Int {
        let advanced = _head + index
        
        return advanced < _capacity ? advanced : advanced - _capacity
    }
    
    @inline(__always)
    private func incrementIndex(_ index: Int) -> Int {
        index == _capacity - 1 ? 0 : index + 1
    }
    
    @inline(__always)
    private func decrementIndex(_ index: Int) -> Int {
        index == 0 ? _capacity - 1 : index - 1
    }
    
}

// MARK: - Capacity and Resizing helpers
extension CircularBuffer {
    @inline(__always)
    private static var _minCapacity: Int { 4 }
    
    // Returns the next power of 2 for given capacity value, or minCapacity for
    // a given value less than or equal to 2.
    // Returned value is clamped to Int.max, and given value must not be negative.
    @inline(__always)
    private static func _convenientCapacityFor(capacity: Int) -> Int {
        precondition(capacity >= 0, "Negative capacity values are not allowed.")
        
        guard capacity > (_minCapacity >> 1) else { return _minCapacity }
        
        guard capacity < ((Int.max >> 1) + 1) else { return Int.max }
        
        return 1 << (Int.bitWidth - (capacity - 1).leadingZeroBitCount)
    }
    
    @inline(__always)
    private var _residualCapacity: Int { (_capacity - _elementsCount) }
    
    @inline(__always)
    private func _growToNextCapacityLevel() {
        precondition(_capacity < Int.max, "Can't grow capacity more than Int.max value: \(Int.max)")
        let newCapacity = _capacity << 1
        _fastResizeElements(to: newCapacity)
    }
    
    @inline(__always)
    private func _reduceCapacityForCurrentElementsCount() {
        guard
            _capacity > Self._minCapacity,
            (_capacity >> 2) >= _elementsCount
        else { return }
        
        guard !isEmpty else {
            _fastResizeElements(to: Self._minCapacity)
            
            return
        }
        
        let newCapacity = Self._convenientCapacityFor(capacity: _elementsCount)
        if newCapacity <= _capacity >> 2 {
            _fastResizeElements(to: newCapacity)
        }
        
    }
    
    @inline(__always)
    private func _fastRotateBufferHeadToZero() {
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: _capacity)
        
        _moveInitialzeFromElements(advancedToBufferIndex: _head, count: _elementsCount, to: newBuff)
        _elements.deallocate()
        _elements = newBuff
        _head = 0
        _tail = incrementIndex(_elementsCount - 1)
    }
    
    @inline(__always)
    private func _fastResizeElements(to newCapacity: Int) {
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        
        _moveInitialzeFromElements(advancedToBufferIndex: _head, count: _elementsCount, to: newBuff)
        _elements.deallocate()
        _elements = newBuff
        _capacity = newCapacity
        _head = 0
        _tail = incrementIndex(_elementsCount - 1)
    }
    
    @inline(__always)
    private func _fastResizeElements<C: Collection>(to newCapacity: Int, insert newElements: C, at index: Int) where C.Iterator.Element == Element {
        let newBuffer = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        
        // copy newElements inside newBuffer
        newBuffer.advanced(by: index).initialize(from: newElements)
        
        // Find out how and where to move _elements into newBuffer
        let buffIdx = index == _elementsCount ? _head + _elementsCount : bufferIndex(from: index)
        let leftSplitStart: Int!
        let rightSplitStart: Int!
        if buffIdx == _head {
            leftSplitStart = newElements.count
            rightSplitStart = newElements.count
        } else if buffIdx == _head + _elementsCount {
            leftSplitStart = 0
            rightSplitStart = 0
        } else {
            leftSplitStart = 0
            rightSplitStart = newElements.count + index
        }
        
        // move _elements into newBuffer
        if leftSplitStart == rightSplitStart {
            // _elements are either appended or prepended to newBuffer
            _moveInitialzeFromElements(advancedToBufferIndex: _head, count: _elementsCount, to: newBuffer.advanced(by: leftSplitStart))
        } else {
            // _elements will occupy two splits inside the newBuffer
            let countOfFirstSplit = index
            let countOfSecondSplit = _elementsCount - index
            // move first split:
            if countOfFirstSplit > 0 {
                _moveInitialzeFromElements(advancedToBufferIndex: _head, count: countOfFirstSplit, to: newBuffer)
            }
            // move second split:
            if countOfSecondSplit > 0 {
                _moveInitialzeFromElements(advancedToBufferIndex: buffIdx, count: countOfSecondSplit, to: newBuffer.advanced(by: rightSplitStart))
            }
        }
        _elements.deallocate()
        _elements = newBuffer
        _capacity = newCapacity
        _elementsCount += newElements.count
        _head = 0
        _tail = incrementIndex(_elementsCount - 1)
    }
    
}

// MARK: - Helpers for inserting and removing from _elements
extension CircularBuffer {
    @inline(__always)
    @discardableResult
    private func _moveInitialzeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
        let nextBufferIdx: Int!
        if startIdx + k > _capacity {
            let segmentCount = _capacity - startIdx
            destination.moveInitialize(from: _elements.advanced(by: startIdx), count: segmentCount)
            destination.advanced(by: segmentCount).moveInitialize(from: _elements, count: k - segmentCount)
            nextBufferIdx = k - segmentCount
        } else {
            destination.moveInitialize(from: _elements.advanced(by: startIdx), count: k)
            nextBufferIdx = startIdx + k
        }
        
        return nextBufferIdx == _capacity ? 0 : nextBufferIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _initializeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
        let nextBufferIdx: Int!
        if startIdx + k > _capacity {
            let segmentCount = _capacity - startIdx
            destination.initialize(from: _elements.advanced(by: startIdx), count: segmentCount)
            destination.advanced(by: segmentCount).initialize(from: _elements, count: k - segmentCount)
            nextBufferIdx = k - segmentCount
        } else {
            destination.initialize(from: _elements.advanced(by: startIdx), count: k)
            nextBufferIdx = startIdx + k
        }
        
        return nextBufferIdx == _capacity ? 0 : nextBufferIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _initializeElements<C: Collection>(advancedToBufferIndex startIdx : Int, from newElements: C) -> Int where C.Iterator.Element == Element {
        let nextBufferIdx: Int
        if startIdx + newElements.count > _capacity {
            let segmentCount = _capacity - startIdx
            let firstSplitRange = newElements.startIndex..<newElements.index(newElements.startIndex, offsetBy: segmentCount)
            let secondSplitRange = newElements.index(newElements.startIndex, offsetBy: segmentCount)..<newElements.endIndex
            _elements.advanced(by: startIdx).initialize(from: newElements[firstSplitRange])
            _elements.initialize(from: newElements[secondSplitRange])
            nextBufferIdx = newElements.count - segmentCount
        } else {
            _elements.advanced(by: startIdx).initialize(from: newElements)
            nextBufferIdx = startIdx + newElements.count
        }
        
        return nextBufferIdx == _capacity ? 0 : nextBufferIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _moveInitializeToElements(advancedToBufferIndex startIdx: Int, from other: UnsafeMutablePointer<Element>, count k: Int) -> Int {
        let nextBuffIdx: Int!
        if startIdx + k > _capacity {
            let segmentCount = _capacity - startIdx
            _elements.advanced(by: startIdx).moveInitialize(from: other, count: segmentCount)
            _elements.moveInitialize(from: other.advanced(by: segmentCount), count: k - segmentCount)
            nextBuffIdx = k - segmentCount
        } else {
            _elements.advanced(by: startIdx).moveInitialize(from: other, count: k)
            nextBuffIdx = startIdx + k
        }
        
        return nextBuffIdx == _capacity ? 0 : nextBuffIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _deinitializeElements(advancedToBufferIndex startIdx : Int, count: Int) -> Int {
        let nextBufferIdx: Int!
        if startIdx + count > _capacity {
            let segmentCount = _capacity - startIdx
            _elements.advanced(by: startIdx).deinitialize(count: segmentCount)
            _elements.deinitialize(count: count - segmentCount)
            nextBufferIdx = count - segmentCount
        } else {
            _elements.advanced(by: startIdx).deinitialize(count: count)
            nextBufferIdx = startIdx + count
        }
        
        return nextBufferIdx == _capacity ? 0 : nextBufferIdx
    }
    
}

// MARK: - Pointers helpers
extension UnsafeMutablePointer {
    fileprivate func initialize<C: Collection>(from newElements: C) where C.Iterator.Element == Pointee {
        guard !newElements.isEmpty else { return }
        
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    self.initialize(from: buff.baseAddress!, count: buff.count)
                    
                    return true
            })
        else {
            var i = 0
            for element in newElements {
                self.advanced(by: i).initialize(to: element)
                i += 1
            }
            
            return
        }
    }
    
}

