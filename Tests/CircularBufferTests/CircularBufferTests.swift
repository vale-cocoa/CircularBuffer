import XCTest
@testable import CircularBuffer

final class CircularBufferTests: XCTestCase {
    var sut: CircularBuffer<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularBuffer<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Init tests
    func test_init() {
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertFalse(sut.isFull)
        XCTAssertEqual(sut._capacity, 4)
        XCTAssertEqual(sut._elementsCount, 0)
        XCTAssertEqual(sut._head, 0)
        XCTAssertEqual(sut._head, sut._tail)
        XCTAssertNil(sut.first)
        XCTAssertNil(sut.last)
    }
    
    func test_initCapacity_whenCapacityIsGreaterThanZero() {
        sut = CircularBuffer<Int>(capacity: 1)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertFalse(sut.isFull)
        XCTAssertGreaterThan(sut._capacity, 0)
        XCTAssertEqual(sut._elementsCount, 0)
        XCTAssertEqual(sut._head, 0)
        XCTAssertEqual(sut._head, sut._tail)
        XCTAssertNil(sut.first)
        XCTAssertNil(sut.last)
    }
    
    func test_initCapacity_whenCapacityIsGreaterThanOne_setsCapacityToNextPowOfTwo() {
        for i in 2..<5 {
            sut = CircularBuffer<Int>(capacity: i)
            XCTAssertEqual(sut._capacity, 4)
        }
        
        for i in 5..<9 {
            sut = CircularBuffer<Int>(capacity: i)
            XCTAssertEqual(sut._capacity, 8)
        }
        
        for i in 9..<17 {
            sut = CircularBuffer<Int>(capacity: i)
            XCTAssertEqual(sut._capacity, 16)
        }
        
        for i in 17..<33 {
            sut = CircularBuffer<Int>(capacity: i)
            XCTAssertEqual(sut._capacity, 32)
        }
    }
    
    func testInitRepeating() {
        sut = CircularBuffer<Int>(repeating: 90, count: 9)
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut._elementsCount, 9)
        XCTAssertEqual(sut._head, 0)
        XCTAssertEqual(sut._tail, 9)
        for idx in 0..<9 {
            XCTAssertEqual(sut._elements.advanced(by: idx).pointee, 90)
        }
    }
    
    func testInitCollection() {
        let collection = AnyCollection(10..<20)
        sut = CircularBuffer<Int>(elements: collection)
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut._elementsCount, collection.count)
        XCTAssertEqual(sut._head, 0)
        XCTAssertEqual(sut._tail, sut._elementsCount)
        for offset in 0..<collection.count {
            let colIdx = collection.index(collection.startIndex, offsetBy: offset)
            XCTAssertEqual(sut._elements.advanced(by: offset).pointee, collection[colIdx])
        }
    }
    
    func testInitSequence() {
        let emptySequence = AnySequence<Int>([])
        sut = CircularBuffer(elements: emptySequence)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut._head, 0)
        XCTAssertEqual(sut._tail, sut._elementsCount)
        
        let notEmptyWithoutContiguousBuffer = AnySequence([1, 2, 3, 4])
        let implemented = notEmptyWithoutContiguousBuffer.withContiguousStorageIfAvailable { _ in
            return true
        }
        XCTAssertNil(implemented)
        
        sut = CircularBuffer(elements: notEmptyWithoutContiguousBuffer)
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sutContainedElements(), [1, 2, 3 ,4])
        
        let notEmptyWithContiguousBuffer = NotEmptySequenceWithContiguous()
        sut = CircularBuffer(elements: notEmptyWithContiguousBuffer)
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sutContainedElements(), notEmptyWithContiguousBuffer.content)
    }
    
    // MARK: - deinit() tests
    func test_deinit() {
        sut = nil
        XCTAssertNil(sut?._elements)
        
        whenFull()
        sut = nil
        XCTAssertNil(sut?._elements)
        
        sut = CircularBuffer<Int>()
        sut.append(3)
        sut.push(2)
        XCTAssertGreaterThan(sut._head + sut._elementsCount, sut._capacity)
        sut = nil
        XCTAssertNil(sut?._elements)
    }
    
    // MARK: - first, last, count public vars tests
    func test_first() {
        XCTAssertNil(sut.first)
        sut = CircularBuffer<Int>(repeating: 90, count: 4)
        XCTAssertNotNil(sut.first)
        XCTAssertEqual(sut.first, 90)
        XCTAssertEqual(sut.first, sut._elements.advanced(by: sut._head).pointee)
    }
    
    func test_last() {
        XCTAssertNil(sut.last)
        sut = CircularBuffer<Int>(repeating: 90, count: 4)
        XCTAssertNotNil(sut.last)
        XCTAssertEqual(sut.last, 90)
        XCTAssertEqual(sut.last, sut._elements.advanced(by: sut._elementsCount - 1).pointee)
    }
    
    func testCount() {
        XCTAssertEqual(sut.count, sut._elementsCount)
        sut.push(1)
        XCTAssertEqual(sut.count, sut._elementsCount)
        sut.append(2)
        XCTAssertEqual(sut.count, sut._elementsCount)
        sut.popFirst()
        XCTAssertEqual(sut.count, sut._elementsCount)
        sut.popLast()
        XCTAssertEqual(sut.count, sut._elementsCount)
        
        whenFull()
        XCTAssertEqual(sut.count, sut._elementsCount)
    }
    
    // MARK: - allocateAdditionalCapacity(_:) tests
    func testAllocateAdditionalCapacity_whenGivenZero_thenDoesNothing() {
        let prevCapacity = sut._capacity
        let prevBuffer = sut._elements
        
        sut.allocateAdditionalCapacity(0)
        XCTAssertEqual(sut._capacity, prevCapacity)
        XCTAssertEqual(sut._elements, prevBuffer)
    }
    
    func testAllocateAdditionalCapacity_whenGivenMoreThanZeroAndActualCapacityIsEnough_thenDoesNothing() {
        whenFull()
        sut.append(5)
        let prevCapacity = sut._capacity
        let prevContainedElements = sutContainedElements()
        let prevBuffer = sut._elements
        
        let residualEmptySpots = sut._capacity - sut._elementsCount
        XCTAssertGreaterThan(residualEmptySpots, 0)
        
        sut.allocateAdditionalCapacity(residualEmptySpots)
        XCTAssertEqual(sut._capacity, prevCapacity)
        XCTAssertEqual(sut._elements, prevBuffer)
        XCTAssertEqual(sutContainedElements(), prevContainedElements)
    }
    
    func testAllocateAdditionalCapacity_whenGivenMoreThanZeroAndActualCapacityIsNotEnough_thenCapacityIncreasesAndBufferGetCopiedToALargerOne() {
        whenFull()
        let prevCapacity = sut._capacity
        let prevContainedElements = sutContainedElements()
        let prevBuffer = sut._elements
        let prevFirst = sut.first
        let prevLast = sut.last
        
        let residualEmptySpots = sut._capacity - sut._elementsCount
        XCTAssertEqual(residualEmptySpots, 0)
        
        sut.allocateAdditionalCapacity(1)
        XCTAssertGreaterThan(sut._capacity, prevCapacity)
        XCTAssertEqual(sutContainedElements(), prevContainedElements)
        XCTAssertNotEqual(sut._elements, prevBuffer)
        XCTAssertEqual(sut.first, prevFirst)
        XCTAssertEqual(sut.last, prevLast)
    }
    
    // MARK: - append(_:) tests
    func testAppend_countIncreasesByOne() {
        let prevCount = sut._elementsCount
        sut.append(10)
        XCTAssertEqual(sut._elementsCount, prevCount + 1)
    }
    
    func testAppend_newElementBecomesLast() {
        let prevLast = sut.last
        sut.append(10)
        XCTAssertNotEqual(sut.last, prevLast)
        XCTAssertEqual(sut.last, 10)
    }
    
    func testAppend_whenFull_capacityGrows() {
        whenFull()
        let prevCapacity = sut._capacity
        sut.append(10)
        XCTAssertGreaterThan(sut._capacity, prevCapacity)
    }
    
    // MARK: - append(contentsOf:) tests
    func testAppendContentsOf() {
        let newElements = AnySequence<Int>([])
        sut.append(contentsOf: newElements)
        XCTAssertTrue(sut.isEmpty)
        
        let newElements1 = AnySequence<Int>(1...4)
        sut.append(contentsOf: newElements1)
        XCTAssertEqual(sut.count, 4)
        for i in 0..<4 {
            XCTAssertEqual(sut[i], i + 1)
        }
        
        let newElements2 = AnySequence<Int>(5...8)
        sut.append(contentsOf: newElements2)
        XCTAssertEqual(sut.count, 8)
        for i in 0..<8 {
            XCTAssertEqual(sut[i], i + 1)
        }
    }
    
    // MARK: - push(_:) tests
    func testPush_countIncreasesByOne() {
        let prevCount = sut._elementsCount
        sut.push(10)
        XCTAssertEqual(sut._elementsCount, prevCount + 1)
    }
    
    func testPush_newElementBecomesFirst() {
        let prevFirst = sut.first
        sut.append(10)
        XCTAssertNotEqual(sut.first, prevFirst)
        XCTAssertEqual(sut.first, 10)
    }
    
    func testPush_whenFull_capacityGrows() {
        whenFull()
        let prevCapacity = sut._capacity
        sut.push(10)
        XCTAssertGreaterThan(sut._elementsCount, prevCapacity)
    }
    
    // MARK: - push(contentsOf:) tests
    func testPushContentsOf() {
        let newElements = AnySequence<Int>([])
        sut.push(contentsOf: newElements)
        XCTAssertTrue(sut.isEmpty)
        
        let newElements1 = AnySequence<Int>(1...4)
        sut.push(contentsOf: newElements1)
        XCTAssertEqual(sut.count, 4)
        for i in 0..<4 {
            XCTAssertEqual(sut[i], 4 - i)
        }
        
        let newElements2 = AnySequence<Int>(5...8)
        sut.push(contentsOf: newElements2)
        XCTAssertEqual(sut.count, 8)
        for i in 0..<8 {
            XCTAssertEqual(sut[i], (8 - i))
        }
    }
    
    // MARK: - popFirst() tests
    func testPopFirst_whenEmpty_returnsNil() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popFirst())
    }
    
    func testPopFirst_whenNotEmpty_countDecreasesByOne() {
        whenFull()
        let previousCount = sut._elementsCount
        sut.popFirst()
        XCTAssertEqual(sut._elementsCount, previousCount - 1)
    }
    
    func testPopFirst_whenNotEmpty_removesAndReturnsFirst() {
        whenFull()
        let oldFirst = sut.first
        XCTAssertEqual(sut.popFirst(), oldFirst)
        XCTAssertNotEqual(sut.first, oldFirst)
    }
    
    // MARK: - removeFirst(_:keepCapacity:) tests
    func testRemoveFirst_whenZero_doesntRemoveAnyElementAndReturnsEmptyArray() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        let prevCount = sut.count
        XCTAssertEqual(sut.removeFirst(0), [])
        XCTAssertEqual(prevCount, sut.count)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func testRemoveFirst_whenOne_removesAndReturnsFirstElementAndDecreasesCountByOne() {
        whenFull()
        let prevCount = sut.count
        let firstElement = [sut.first]
        XCTAssertEqual(sut.removeFirst(1), firstElement)
        XCTAssertEqual(sut.count, prevCount - 1)
        XCTAssertNotEqual(sut.first, firstElement.first!)
    }
    
    func testRemoveFirst_whenEqualCount_removesAndReturnsAllElements() {
        whenFull()
        XCTAssertEqual(sut.removeFirst(sut.count), containedElementsWhenFull())
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testRemoveFirst_whenMoreThanOneAndLessThanCount_removesAndReturnsFirstElements() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        XCTAssertEqual(sut.removeFirst(containedElements.count / 2), Array(containedElements[0..<containedElements.count / 2]))
        XCTAssertEqual(sut.count, (containedElements.count - (containedElements.count / 2)))
    }
    
    func testRemoveFirst_whenContainedElementsAreSplitInBuffer() {
        sut.push(2)
        sut.push(1)
        sut.append(3)
        sut.append(4)
        XCTAssertGreaterThan(sut._head + 3, sut._capacity)
        XCTAssertEqual([sut[0], sut[1], sut[2], sut[3]], [1, 2, 3, 4])
        
        XCTAssertEqual(sut.removeFirst(3), [1, 2, 3])
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, sut.last)
        XCTAssertEqual(sut.first, 4)
    }
    
    func testRemoveFirst_whenZeroAndKeepCapacityIsFalseAndCapacityCantBeReducedAnyFurther_doesntReduceCapacity() {
        whenFull()
        XCTAssert(sut.isFull)
        var expectedCapacity = sut._capacity
        sut.removeFirst(0, keepCapacity: false)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        sut.append(5)
        expectedCapacity = sut._capacity
        sut.removeFirst(0, keepCapacity: false)
        XCTAssertEqual(sut._capacity, expectedCapacity)
    }
    
    func testRemoveFirst_whenCountIsZeroAndKeepCapacityIsFalse_reducesCapacityWhenPossible() {
        whenFull()
        let expectedCapacity = sut._capacity
        sut.append(5)
        sut.popLast()
        XCTAssertGreaterThan(sut._capacity, expectedCapacity)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        sut.removeFirst(0, keepCapacity: false)
        XCTAssertEqual(sut._capacity, expectedCapacity)
    }
    
    func testRemoveFirst_whenKeepCapacityFalseAndRemovesEnoughElementsToTriggerResize_capacityGetsResized() {
        whenFull()
        var prevCapacity = sut._capacity
        var added = 0
        while sut._capacity <= prevCapacity {
            added += 1
            sut.append(added + 4)
        }
        prevCapacity = sut._capacity
        sut.removeFirst(added, keepCapacity: false)
        XCTAssertLessThan(sut._capacity, prevCapacity)
    }
    
    // MARK: - popLast() tests
    func testPopLast_whenEmpty_returnsNil() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popLast())
    }
    
    func testPopLast_whenNotEmpty_countDecreasesByOne() {
        whenFull()
        let previousCount = sut._elementsCount
        sut.popLast()
        XCTAssertEqual(sut._elementsCount, previousCount - 1)
    }
    
    func testPopLast_whenNotEmpty_removesAndReturnsLast() {
        whenFull()
        let oldLast = sut.last
        XCTAssertEqual(sut.popLast(), oldLast)
        XCTAssertNotEqual(sut.last, oldLast)
    }
    
    // MARK: - removeLast(_:keepCapacity:) tests
    func test_removeLast_whenZero_doesntRemoveElementsAndReturnsEmptyArray() {
        whenFull()
        let previousCount = sut.count
        let containedElements = containedElementsWhenFull()
        XCTAssertEqual(sut.removeLast(0, keepCapacity: true), [])
        XCTAssertEqual(sut.count, previousCount)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func testRemoveLast_whenOne_removesAndReturnsLastElementAndDecreasesByOneCount() {
        whenFull()
        let lastElement = [sut.last]
        let previousCount = sut.count
        
        XCTAssertEqual(sut.removeLast(1), lastElement)
        XCTAssertEqual(sut.count, previousCount - 1)
        XCTAssertNotEqual(sut.last, lastElement.first!)
    }
    
    func testRemoveLast_whenEqualCount_removesAndReturnsAllElements() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        XCTAssertEqual(sut.removeLast(sut.count), containedElements)
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testRemoveLast_whenMoreThanOneAndLessThanCount_removesAndReturnsLastElements() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        XCTAssertEqual(sut.removeLast(sut.count / 2), Array(containedElements[containedElements.count / 2..<containedElements.count]))
        XCTAssertEqual(sut.count, (containedElements.count -  (containedElements.count / 2)))
        var restOfElements = [Int]()
        while let el = sut.popFirst() {
            restOfElements.append(el)
        }
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut._head, sut._tail)
        XCTAssertEqual(restOfElements, Array(containedElements[0..<(containedElements.count / 2)]))
    }
    
    func testRemoveLast_whenContainedElementsAreSplitInBuffer() {
        sut.append(2)
        sut.append(3)
        sut.append(4)
        sut.push(1)
        XCTAssertGreaterThanOrEqual(sut._tail - 3, 0)
        
        let lastElements = [sut[1], sut[2], sut[3]]
        XCTAssertEqual(sut.removeLast(3), lastElements)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, sut.last)
        XCTAssertEqual(sut.first, 1)
    }
    
    func testRemoveLast_whenZeroAndKeepCapacityIsFalseAndCapacityCantBeReducedAnyFurther_doesntReduceCapacity() {
        whenFull()
        XCTAssert(sut.isFull)
        var expectedCapacity = sut._capacity
        sut.removeLast(0, keepCapacity: false)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        sut.append(5)
        expectedCapacity = sut._capacity
        sut.removeLast(0, keepCapacity: false)
        XCTAssertEqual(sut._capacity, expectedCapacity)
    }
    
    func testRemoveLast_whenCountIsZeroAndKeepCapacityIsFalse_reducesCapacityWhenPossible() {
        whenFull()
        let expectedCapacity = sut._capacity
        sut.append(5)
        sut.popLast()
        XCTAssertGreaterThan(sut._capacity, expectedCapacity)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        sut.removeLast(0, keepCapacity: false)
        XCTAssertEqual(sut._capacity, expectedCapacity)
    }
    
    func testRemoveLast_whenKeepCapacityFalseAndRemovesEnoughElementsToTriggerResize_capacityGetsResized() {
        whenFull()
        var prevCapacity = sut._capacity
        var added = 0
        while sut._capacity <= prevCapacity {
            added += 1
            sut.append(added + 4)
        }
        prevCapacity = sut._capacity
        sut.removeLast(added, keepCapacity: false)
        XCTAssertLessThan(sut._capacity, prevCapacity)
    }
    
    // MARK: - removeAt(index:count:keepCapacity:) tests
    func testRemoveAt_whenCountIsZero_doesntRemoveElementsAndReturnsEmptyArray() {
        whenFull()
        let expectedCount = sut.count
        let containedElements = containedElementsWhenFull()
        
        for idx in 0..<sut.count {
            XCTAssertEqual(sut.removeAt(index: idx, count: 0), [])
            XCTAssertEqual(sut.count, expectedCount)
            for i in 0..<sut.count {
                XCTAssertEqual(sut[i], containedElements[i])
            }
        }
    }
    
    func testRemoveAt_whenCountIsOne_removesAndReturnsElementAtIdxAndDecreasesCountByOne() {
        whenFull()
        let prevCount = sut.count
        let containedElements = containedElementsWhenFull()
        for idx in 0..<4 {
            XCTAssertEqual(sut.removeAt(index: idx, count: 1), [containedElements[idx]])
            XCTAssertEqual(sut.count, prevCount - 1)
            
            // restore SUT state to full on each iteration
            whenFull()
        }
    }
    
    func testRemoveAt_whenCountMoreThanOneAndLessThanCount_removesAndReturnsTheElementAtIndexAndElementsAfterAndDecreasesCount() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        for idx in 0..<sut.count {
            let prevCount = sut.count
            let k = sut.count - idx
            let expectedRemoved = Array(containedElements[idx..<(idx + k)])
            var expectedRemaining = containedElements
            expectedRemaining.removeSubrange(idx..<(idx + k))
            XCTAssertEqual(sut.removeAt(index: idx, count: k), expectedRemoved)
            XCTAssertEqual(sut.count, prevCount - k)
            XCTAssertEqual(sut.count, expectedRemaining.count)
            for i in 0..<sut.count {
                XCTAssertEqual(sut[i], expectedRemaining[i])
            }
            
            // restore SUT state to full on each iteration
            whenFull()
        }
    }
    
    func testRemoveAt_whenCountIsZeroAndKeepCapacityIsFalseAndCapacityCantBeReducedAnyFurther_doesntReduceCapacity() {
        whenFull()
        XCTAssert(sut.isFull)
        var expectedCapacity = sut._capacity
        
        for idx in 0..<sut.count {
            sut.removeAt(index: idx, count: 0, keepCapacity: false)
            XCTAssertEqual(sut.count, expectedCapacity)
        }
        
        sut.append(5)
        expectedCapacity = sut._capacity
        
        for idx in 0..<sut.count {
            sut.removeAt(index: idx, count: 0, keepCapacity: false)
            XCTAssertEqual(sut._capacity, expectedCapacity)
        }
    }
    
    func testRemoveAt_whenCountIsZeroAndKeepCapacityIsFalse_reducesCapacityWhenPossible() {
        whenFull()
        let expectedCapacity = sut._capacity
        sut.append(5)
        sut.popLast()
        XCTAssertGreaterThan(sut._capacity, expectedCapacity)
        XCTAssertEqual(sut.count, expectedCapacity)
        
        for idx in 0..<sut.count {
            sut.removeAt(index: idx, count: 0, keepCapacity: false)
            XCTAssertEqual(sut._capacity, expectedCapacity)
        }
    }
    
    // MARK: - prepend(contentsOf:) tests
    func testPrependContentsOf_whenNewElementsIsEmpty_doesNothing() {
        sut.prepend(contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        
        whenFull()
        let containedElements = containedElementsWhenFull()
        sut.prepend(contentsOf: [])
        XCTAssertEqual(sut.count, containedElements.count)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func testPrependContentsOf_whenNewElementsCountIsGreaterThanZero_increasesCountByNewElementsCount() {
        var prevCount = sut.count
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
        
        whenFull()
        prevCount = sut.count
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
    }
    
    func testPrependContentsOf_whenNewElementsIsNotEmpty_newElementsGetPrepended() {
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.prepend(contentsOf: newElements)
        var result = [Int]()
        for i in 0..<sut.count {
            result.append(sut[i])
        }
        XCTAssertEqual(result, newElements)
        
        whenFull()
        let previousElements = containedElementsWhenFull()
        sut.prepend(contentsOf: newElements)
        result = sutContainedElements()
        XCTAssertEqual(result, newElements + previousElements)
    }
    
    func testPrependContentsOf_whenLeftCapacityIsSufficientToStoreNewElements() {
        whenFull()
        sut.append(5)
        sut.append(6)
        sut.append(7)
        sut.append(8)
        sut.append(9)
        let newElements = [10, 11, 12, 13, 14, 15, 16]
        XCTAssertGreaterThanOrEqual(sut._capacity - (sut._elementsCount + newElements.count), 0)
        let prevElements = containedElementsWhenFull() + [5, 6, 7, 8, 9]
        
        sut.prepend(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevElements.count + newElements.count)
        var result = sutContainedElements()
        XCTAssertEqual(result, newElements + prevElements)
        
        // test for appending in splits
        let copy = sut.copy()
        for _ in 0..<newElements.count {
            copy.popFirst()
        }
        XCTAssertGreaterThan(copy._head, 0)
        XCTAssertEqual(copy._head, newElements.count)
        copy.prepend(contentsOf: newElements)
        XCTAssertEqual(copy.count, prevElements.count + newElements.count)
        result.removeAll()
        copy.forEach { result.append($0) }
        XCTAssertEqual(result, newElements + prevElements)
    }
    
    // MARK: - append<C: Collection>(contentsOf:) tests
    func testAppendContentsOf_whenNewElementsIsEmpty_doesNothing() {
        sut.append(contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        
        whenFull()
        let containedElements = containedElementsWhenFull()
        sut.append(contentsOf: [])
        XCTAssertEqual(sut.count, containedElements.count)
        for i in 0..<sut.count {
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func testAppendContentsOf_whenNewElementsCountIsGreaterThanZero_increasesCountByNewElementsCount() {
        var prevCount = sut.count
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
        
        whenFull()
        prevCount = sut.count
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
    }
    
    func testAppendContentsOf_whenNewElementsIsNotEmpty_newElementsGetAppended() {
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.append(contentsOf: newElements)
        var result = [Int]()
        for i in 0..<sut.count {
            result.append(sut[i])
        }
        XCTAssertEqual(result, newElements)
        
        whenFull()
        let previousElements = containedElementsWhenFull()
        sut.append(contentsOf: newElements)
        result = sutContainedElements()
        XCTAssertEqual(result, previousElements + newElements)
    }
    
    func testAppendContentsOf_whenLeftCapacityIsSufficientToStoreNewElements() {
        whenLeftCapacityIsSeven()
        let newElements = [10, 11, 12, 13, 14, 15, 16]
        XCTAssertGreaterThanOrEqual(sut._capacity - (sut._elementsCount + newElements.count), 0)
        let prevElements = containedElementsWhenLeftCapacityIsSeven()
        
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.count, prevElements.count + newElements.count)
        var result = sutContainedElements()
        XCTAssertEqual(result, prevElements + newElements)
        
        // Test for appending in splits
        let copy = sut.copy()
        for _ in 0..<newElements.count - 2 {
            copy.popLast()
        }
        copy.popFirst()
        copy.popFirst()
        XCTAssertEqual(copy.count, prevElements.count)
        for i in 0..<prevElements.count {
            copy[i] = prevElements[i]
        }
        XCTAssertGreaterThan(copy._tail + newElements.count, copy._capacity)
        XCTAssertGreaterThanOrEqual(copy._capacity, copy.count + newElements.count)
        
        copy.append(contentsOf:newElements)
        result.removeAll()
        copy.forEach({ result.append($0) })
        XCTAssertEqual(result, prevElements + newElements)
    }
    
    // MARK: - insertAt(index:ContentsOf:)
    func testInsertAt_whenNewElementsIsEmpty_doesNothing() {
        XCTAssertEqual(sut.count, 0)
        sut.insertAt(index: sut.count, contentsOf: [])
        XCTAssertTrue(sut.isEmpty)
        
        whenFull()
        let containedElements = containedElementsWhenFull()
        for i in 0...sut.count {
            sut.insertAt(index: i, contentsOf: [])
            XCTAssertEqual(sut.count, containedElements.count)
            for j in 0..<sut.count {
                XCTAssertEqual(sut[j], containedElements[j])
            }
            // restore SUT state for next iteration:
            whenFull()
        }
    }
    
    func test_insertAt_whenNewElementsCountIsGreaterThanZero_increasesCountByNewElementsCount() {
        var prevCount = sut.count
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.insertAt(index: 0, contentsOf: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
        
        whenFull()
        for i in 0...sut.count {
            prevCount = sut.count
            sut.insertAt(index: i, contentsOf: newElements)
            XCTAssertEqual(sut.count, prevCount + newElements.count)
            
            // restore SUT state for next iteration:
            whenFull()
        }
    }
    
    func testInsertAt__whenNewElementsIsNotEmpty_newElementsGetAppended() {
        XCTAssertEqual(sut.count, 0)
        let newElements = [5, 6, 7, 8 ,9, 10]
        sut.insertAt(index: sut.count, contentsOf: newElements)
        var result = sutContainedElements()
        XCTAssertEqual(result, newElements)
        
        whenFull()
        let previousElements = containedElementsWhenFull()
        for i in 0...sut.count {
            sut.insertAt(index: i, contentsOf: newElements)
            result = sutContainedElements()
            let expectedResult = Array(previousElements[0..<i] + newElements + Array(previousElements[i..<previousElements.endIndex]))
            XCTAssertEqual(result, expectedResult)
            
            // restore SUT state for next iteration:
            whenFull()
        }
    }
    
    func testInsertAt_whenLeftCapacityIsSufficientToStoreNewElements() {
        whenLeftCapacityIsSeven()
        let newElements = [10, 11, 12, 13, 14, 15, 16]
        XCTAssertGreaterThanOrEqual(sut._capacity - (sut._elementsCount + newElements.count), 0)
        let prevElements = containedElementsWhenLeftCapacityIsSeven()
        
        var result = [Int]()
        for i in 0...sut.count {
            sut.insertAt(index: i, contentsOf: newElements)
            XCTAssertEqual(sut.count, prevElements.count + newElements.count)
            result = sutContainedElements()
            let expectedResult = Array(prevElements[0..<i]) + newElements + Array(prevElements[i..<prevElements.endIndex])
            XCTAssertEqual(result, expectedResult)
            XCTAssertTrue(sut.isFull)
            XCTAssertEqual(sut[sut.count - 1], sut.last, "Iteration: \(i)")
            
            // restore SUT state for next iteration:
            whenLeftCapacityIsSeven()
            // restore result:
            result.removeAll()
        }
        
        // Test for appending in splits
        let copy = sut.copy()
        copy.append(contentsOf: newElements)
        for _ in 0..<newElements.count - 2 {
            copy.popLast()
        }
        copy.popFirst()
        copy.popFirst()
        XCTAssertEqual(copy.count, prevElements.count)
        for i in 0..<prevElements.count {
            copy[i] = prevElements[i]
        }
        XCTAssertGreaterThan(copy._tail + newElements.count, copy._capacity)
        XCTAssertGreaterThanOrEqual(copy._capacity, copy.count + newElements.count)
        
        copy.insertAt(index: 2, contentsOf: newElements)
        result.removeAll()
        copy.forEach { result.append($0) }
        let expectedResult = Array(prevElements[0..<2] + newElements + Array(prevElements[2..<prevElements.endIndex]))
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(sut[sut.count - 1], sut.last)
    }
    
    // MARK: - replace(subRange:with:) tests
    func test_replaceSubrange_whenBothSubrangeCountAndNewElementsCountAreZero_doesNothing() {
        var prevCount = sut.count
        sut.replace(subRange: 0..<0, with: [])
        XCTAssertEqual(sut.count, prevCount)
        
        whenFull()
        prevCount = sut.count
        let prevElements = containedElementsWhenFull()
        var result = [Int]()
        for i in 0...sut.count {
            sut.replace(subRange: i..<i, with: [])
            XCTAssertEqual(sut.count, prevCount)
            result = sutContainedElements()
            XCTAssertEqual(result, prevElements)
            
            // Restore SUT state and result to previous state for
            // next iteration
            whenFull()
            result.removeAll()
        }
    }
    
    func test_replaceSubrange_whenSubrangeCountIsZeroAndNewElementsCountGreaterThanZero_newElementsAreInsertedAtSubrangeLowerBoundPosition() {
        var prevCount = sut.count
        var result = [Int]()
        let newElements = [5, 6, 7, 8]
        sut.replace(subRange: 0..<0, with: newElements)
        XCTAssertEqual(sut.count, prevCount + newElements.count)
        result = sutContainedElements()
        XCTAssertEqual(result, newElements)
        
        whenFull()
        prevCount = sut.count
        let previousElements = containedElementsWhenFull()
        result.removeAll()
        for i in 0...sut.count {
            let subrange = i..<i
            sut.replace(subRange: subrange, with: newElements)
            result = sutContainedElements()
            XCTAssertEqual(result.count, prevCount + newElements.count)
            let expectedResult = Array(previousElements[0..<subrange.lowerBound]) + newElements + Array(previousElements[subrange.lowerBound..<previousElements.count])
            XCTAssertEqual(result, expectedResult)
            
            // Restore SUT state and result to previous state for
            // next iteration
            whenFull()
            result.removeAll()
        }
    }
    
    func test_replaceSubrange_whenSubrangeCountIsGreaterThanZeroAndNewElementsCountIsZero_removesElementsAtSubrangePositions() {
        whenFull()
        let prevCount = sut.count
        let prevElements = containedElementsWhenFull()
        var result = [Int]()
        for startIdx in 0...(sut.count - 1) {
            for endIdx in (startIdx + 1)...sut.count {
                let subrange = startIdx..<endIdx
                XCTAssertGreaterThan(subrange.count, 0)
                
                sut.replace(subRange: subrange, with: [])
                XCTAssertEqual(sut.count, prevCount - subrange.count)
                result = sutContainedElements()
                let expectedResult = Array(prevElements[0..<startIdx]) + Array(prevElements[endIdx..<prevElements.endIndex])
                XCTAssertEqual(result, expectedResult)
                
                // restore SUT state and result for next iteration
                whenFull()
                result.removeAll()
            }
        }
    }
    
    func testReplaceSubrange_whenSubrangeCountIsGreaterThanZeroAndNewElementsCountIsGreaterThanZero_replacesElementsAtSubrangeWithNewElements() {
        whenFull()
        let prevElements = containedElementsWhenFull()
        let prevCount = sut.count
        let newElements = [5, 6, 7, 8]
        var result = [Int]()
        for startIdx in 0...(sut.count - 1) {
            for endIdx in (startIdx + 1)...sut.count {
                let subrange = startIdx..<endIdx
                XCTAssertGreaterThan(subrange.count, 0)
                
                sut.replace(subRange: subrange, with: newElements)
                result = sutContainedElements()
                var expectedResult = prevElements
                expectedResult.replaceSubrange(subrange, with: newElements)
                
                XCTAssertEqual(sut.count, prevCount - subrange.count + newElements.count)
                XCTAssertEqual(result, expectedResult)
                
                // restore SUT state and result for next iteration
                whenFull()
                result.removeAll()
            }
        }
    }
    
    func testReplaceSubRange_withSubrangeInMiddleAndNoBufferResizeWillOccur() {
        sut = nil
        sut = CircularBuffer<Int>(elements: [1, 2, 10, 11, 8])
        let prevCount = sut.count
        let prevCapacity = sut._capacity
        let prevElements = sutContainedElements()
        let subrange = 2..<4
        let newElements = [3, 4, 5, 6, 7]
        var expectedResult = prevElements
        expectedResult.replaceSubrange(subrange, with: newElements)
        XCTAssertEqual(expectedResult, [1, 2, 3, 4, 5, 6, 7 ,8])
        
        sut.replace(subRange: subrange, with: newElements)
        XCTAssertEqual(sut._capacity, prevCapacity)
        XCTAssertEqual(sut.count, prevCount - subrange.count + newElements.count)
        let result = sutContainedElements()
        XCTAssertEqual(result, expectedResult)
    }
    
    // MARK: - subscript tests
    func test_subscriptGetter() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        for i in 0..<containedElements.count {
            XCTAssertEqual(sut._elements.advanced(by: i).pointee, sut[i])
            XCTAssertEqual(sut[i], containedElements[i])
        }
    }
    
    func test_subscriptSetter() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        for i in 0..<containedElements.count {
            sut[i] += 10
            XCTAssertEqual(sut._elements.advanced(by: i).pointee, sut[i])
            XCTAssertEqual(sut[i], containedElements[i] + 10)
        }
    }
    
    // MARK: - _head index tests
    func test_head_whenPointsToZero_pushMakesItWrapAroundToLastBufferElement() {
        XCTAssertEqual(sut._head, 0)
        
        sut.push(4)
        XCTAssertEqual(sut._head, sut._capacity - 1)
    }
    
    func test_head_whenPointsToLastBufferElement_popFirstMakesItWrapAroundToZero() {
        sut.push(4)
        XCTAssertEqual(sut._head, sut._capacity - 1)
        
        sut.popFirst()
        XCTAssertEqual(sut._head, 0)
    }
    
    // MARK: - _tail index tests
    func test_tail_whenPointsToZero_popLastMakesItWrapAroundToLastBufferElement() {
        whenFull()
        XCTAssertEqual(sut._tail, 0)
        
        sut.popLast()
        XCTAssertEqual(sut._tail, sut._capacity - 1)
    }
    
    func test_tail_whenPointsToLastBufferElement_appendMakesItWrapAroundToZero() {
        whenFull()
        sut.popLast()
        XCTAssertEqual(sut._tail, sut._capacity - 1)
        
        sut.append(4)
        XCTAssertEqual(sut._tail, 0)
    }
    
    // MARK: - forEach tests
    func testForEach_executesOnContainedElementsInOrder() {
        whenFull()
        let containedElements = containedElementsWhenFull()
        var result: [Int] = []
        sut.forEach { result.append($0) }
        XCTAssertEqual(result, containedElements)
    }
    
    // MARK: - copy tests
    func testCopy() {
        whenFull()
        let copy = sut.copy()
        XCTAssertNotEqual(sut._elements, copy._elements)
        XCTAssertEqual(sut._elementsCount, copy._elementsCount)
        XCTAssertEqual(sut._capacity, copy._capacity)
        for i in 0..<sut._elementsCount {
            XCTAssertEqual(sut[i], copy[i])
        }
    }
    
    func testCopy_whenFullAndAdditionalCapacityGreaterThanZero_copyHasIncreasedCapacity() {
        whenFull()
        let copy = sut.copy(additionalCapacity: 90)
        XCTAssertNotEqual(sut._elements, copy._elements)
        XCTAssertEqual(sut._elementsCount, copy._elementsCount)
        XCTAssertGreaterThan(copy._capacity, sut._capacity)
        for i in 0..<sut._elementsCount {
            XCTAssertEqual(sut[i], copy[i])
        }
    }
    
    // MARK: - Unsafe(Mutable)BufferPointer tests
    func test_unsafeMutableBufferPointer() {
        var bufferPointer = sut.unsafeMutableBufferPointer
        XCTAssertEqual(bufferPointer.baseAddress, sut._elements)
        XCTAssertEqual(bufferPointer.count, sut.count)
        XCTAssertEqual(Array(bufferPointer), sutContainedElements())
        
        whenFull()
        bufferPointer = sut.unsafeMutableBufferPointer
        XCTAssertEqual(bufferPointer.baseAddress, sut._elements)
        XCTAssertEqual(bufferPointer.count, sut.count)
        XCTAssertEqual(Array(bufferPointer), sutContainedElements())
        
        bufferPointer[2] += 10
        XCTAssertEqual(bufferPointer[2], sut[2])
        XCTAssertEqual(Array(bufferPointer), sutContainedElements())
        
        sut[2] -= 10
        XCTAssertEqual(bufferPointer[2], sut[2])
        XCTAssertEqual(Array(bufferPointer), sutContainedElements())
    }
    
    func test_unsafeBufferPointer() {
        var bufferPointer = sut.unsafeBufferPointer
        XCTAssertEqual(bufferPointer.baseAddress, sut._elements)
        XCTAssertEqual(bufferPointer.count, sut.count)
        XCTAssertEqual(Array(bufferPointer), sutContainedElements())
        
        whenFull()
        bufferPointer = sut.unsafeBufferPointer
        XCTAssertEqual(bufferPointer.baseAddress, sut._elements)
        XCTAssertEqual(bufferPointer.count, sut.count)
        XCTAssertEqual(Array(bufferPointer), sutContainedElements())
    }
    
    // MARK: - performance tests
    func testCircularBufferPerformance() {
        measure(performanceLoopCircularBuffer)
    }
    
    func testArrayPerformance() {
        measure(performanceLoopArray)
    }
    
    // MARK: - private helpers
    private func containedElementsWhenFull() -> [Int] {
        [1, 2, 3, 4]
    }
    
    private func whenFull() {
        sut = nil
        sut = CircularBuffer<Int>(elements: containedElementsWhenFull())
        XCTAssertTrue(sut.isFull)
    }
    
    private func containedElementsWhenLeftCapacityIsSeven() -> [Int] {
        containedElementsWhenFull() + [5, 6, 7, 8, 9]
    }
    
    private func whenLeftCapacityIsSeven() {
        whenFull()
        sut.append(5)
        sut.append(6)
        sut.append(7)
        sut.append(8)
        sut.append(9)
        XCTAssertEqual(sut._capacity - sut.count, 7)
    }
    
    private func sutContainedElements() -> [Int] {
        guard !sut.isEmpty else { return [] }
        
        var result = Array<Int>()
        sut.forEach { result.append($0) }
        
        return result
    }
    
    private func performanceLoopCircularBuffer() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            let ringBuffer = CircularBuffer<Int>(capacity: innerCount)
            for i in 1...innerCount {
                ringBuffer.append(i)
                accumulator ^= (ringBuffer.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (ringBuffer.first ?? 0)
                ringBuffer.popFirst()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopArray() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            var array = Array<Int>()
            for i in 1...innerCount {
                array.append(i)
                accumulator ^= (array.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (array.first ?? 0)
                array.remove(at: 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
}

fileprivate struct NotEmptySequenceWithContiguous: Sequence {
    let content = [1, 2, 3, 4]
    
    var underestimatedCount: Int = 4
    
    typealias Element = Int
    
     typealias Iterator = AnyIterator<Int>
    
    func makeIterator() -> Iterator {
        var idx = 0
        
        return AnyIterator<Int> {
            guard idx < content.count else { return nil }
            
            defer { idx += 1 }
            
            return content[idx]
        }
    }
    
    func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Int>) throws -> R) rethrows -> R? {
        
        return try content.withContiguousStorageIfAvailable(body)
    }
    
}
