//
//  ClosureBasedOperationsTests.swift
//  CircularBufferTests
//
//  Created by Valeriano Della Longa on 2020/12/02.
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

import XCTest
@testable import CircularBuffer

final class ClosureBasedOperationsTests: XCTestCase {
    var sut: CircularBuffer<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularBuffer<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - forEach(_:) tests
    func testForEach_whenIsEmpty() {
        XCTAssert(sut.isEmpty)
        let elements = [Int]()
        var expectedResult = [String]()
        elements.forEach { expectedResult.append(String($0)) }
        
        var result = [String]()
        sut.forEach { result.append(String($0)) }
        XCTAssertEqual(result, expectedResult)
        
        // Let's now also test it with a shifted buffer:
        XCTAssertGreaterThan(sut.capacity, 0)
        for headShift in 1..<sut.capacity {
            sut.head = headShift
            sut.tail = headShift
            
            result.removeAll()
            sut.forEach { result.append(String($0)) }
            XCTAssertEqual(result, expectedResult)
        }
        
        XCTAssertNoThrow(try sut.forEach(throwingBody))
    }
    
    func testForEach_whenIsNotEmpty() {
        let elements = (1...100).shuffled()
        var expectedResult = [String]()
        elements.forEach { expectedResult.append(String($0)) }
        
        sut = CircularBuffer(elements: elements)
        var result = [String]()
        sut.forEach { result.append(String($0)) }
        XCTAssertEqual(result, expectedResult)
        
        // Let's now also test it with a shifted buffer:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            result.removeAll(keepingCapacity: true)
            sut.forEach { result.append(String($0)) }
            XCTAssertEqual(result, expectedResult)
            XCTAssertThrowsError(try sut.forEach(throwingBody))
            do {
                try sut.forEach(throwingBody)
            } catch {
                XCTAssertEqual(error as NSError, testsThrownError)
            }
        }
    }
    
    func testForEach_whenIsNotEmptyAndBodyThrows() {
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        
        XCTAssertThrowsError(try sut.forEach(throwingBody))
        do {
            try sut.forEach(throwingBody)
        } catch {
            XCTAssertEqual(error as NSError, testsThrownError)
        }
        
        // Let's now also test it with a shifted buffer:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            XCTAssertThrowsError(try sut.forEach(throwingBody))
            do {
                try sut.forEach(throwingBody)
            } catch {
                XCTAssertEqual(error as NSError, testsThrownError)
            }
        }
    }
    
    // MARK: - allSatisfy(_:) tests
    func testAllSatisfy_whenIsEmpty() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertTrue(sut.allSatisfy(isEvenPredicate))
        
        // Let's now also test it with a shifted buffer:
        XCTAssertGreaterThan(sut.capacity, 0)
        for headShift in 1..<sut.capacity {
            sut.head = headShift
            sut.tail = headShift
            XCTAssertTrue(sut.allSatisfy(isEvenPredicate))
        }
        
        XCTAssertNoThrow(try sut.allSatisfy(throwingPredicate))
    }
    
    func testAllSatisfy_whenIsNotEmptyAndPredicateThrows() {
        let elements = 1...100
        sut = CircularBuffer(elements: elements)
        XCTAssertThrowsError(try sut.allSatisfy(throwingPredicate))
        do {
            let _ = try sut.allSatisfy(throwingPredicate)
        } catch {
            XCTAssertEqual(error as NSError, testsThrownError)
        }
    }
    
    func testAllSatisfy_whenIsNotEmptyAndNoElementSatisfyPredicate() {
        let elements = stride(from: 1, through: 100, by: 2).shuffled()
        let expectedResult = elements.allSatisfy(isEvenPredicate)
        XCTAssertFalse(expectedResult)
        sut = CircularBuffer(elements: elements)
        XCTAssertEqual(sut.allSatisfy(isEvenPredicate), expectedResult)
        
        // let's also do the same test when the storage is shifted:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            XCTAssertEqual(sut.allSatisfy(isEvenPredicate), expectedResult)
        }
    }
    
    func testAllSatisfy_whenIsNotEmptyAndAllElementsSatisfyPredicate() {
        let elements = stride(from: 2, through: 100, by: 2).shuffled()
        let expectedResult = elements.allSatisfy(isEvenPredicate)
        XCTAssertTrue(expectedResult)
        sut = CircularBuffer(elements: elements)
        XCTAssertEqual(sut.allSatisfy(isEvenPredicate), expectedResult)
        
        // let's also do the same test when the storage is shifted:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            XCTAssertEqual(sut.allSatisfy(isEvenPredicate), expectedResult)
        }
    }
    
    func testAllSatisfy_whenIsNotEmptyAndSomeElementsDontSatisfyPredicate() {
        let elements = (1...100).shuffled()
        let expectedResult = elements.allSatisfy(isEvenPredicate)
        XCTAssertFalse(expectedResult)
        sut = CircularBuffer(elements: elements)
        XCTAssertEqual(sut.allSatisfy(isEvenPredicate), expectedResult)
        
        // let's also do the same test when the storage is shifted:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            XCTAssertEqual(sut.allSatisfy(isEvenPredicate), expectedResult)
        }
    }
    
    // MARK: - removeAll(where:) tests
    func testRemoveAllWhere_whenIsEmpty() {
        XCTAssertTrue(sut.isEmpty)
        sut.removeAll(where: isEvenPredicate)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        
        // Let's now also test it with a shifted buffer:
        XCTAssertGreaterThan(sut.capacity, 0)
        for headShift in 1..<sut.capacity {
            sut.head = headShift
            sut.tail = headShift
            sut.removeAll(where: isEvenPredicate)
            XCTAssertTrue(sut.isEmpty)
            XCTAssertEqual(sut.head, headShift)
            XCTAssertEqual(sut.tail, headShift)
        }
        
        // when isEmpty and predicate throws, doesn't throw:
        XCTAssertNoThrow(try sut.removeAll(where: throwingPredicate))
    }
    
    func testRemoveAllWhere_whenIsNotEmptyAndShouldBeRemovedThrows() {
        let elements = 1...100
        sut = CircularBuffer(elements: elements)
        XCTAssertThrowsError(try sut.removeAll(where: throwingPredicate))
        do {
            try sut.removeAll(where: throwingPredicate)
        } catch {
            XCTAssertEqual(error as NSError, testsThrownError)
        }
    }
    
    func testRemoveAllWhere_whenIsNotEmptyAndNoElementShouldBeRemoved() {
        let elements = stride(from: 1, through: 100, by: 2).shuffled()
        XCTAssertEqual(elements.compactMap(isEvenOptionalTransform).count, 0)
        sut = CircularBuffer(elements: elements)
        sut.removeAll(where: isEvenPredicate)
        XCTAssertEqual(sut.allStoredElements, elements)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, elements.count)
        
        // let's also do the same test when the storage is shifted:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            sut.removeAll(where: isEvenPredicate)
            XCTAssertEqual(sut.allStoredElements, elements)
            XCTAssertEqual(sut.head, headShift)
            let expectedTail = sut.incrementBufferIndex(sut.bufferIndex(from: sut.count - 1))
            XCTAssertEqual(sut.tail, expectedTail)
            for i in 0..<sut.count {
                XCTAssertEqual(sut[i], elements[i])
            }
        }
    }
    
    func testRemoveAllWhere_whenIsNotEmptyAndAllElementsShouldBeRemoved() {
        let elements = stride(from: 2, through: 100, by: 2).shuffled()
        XCTAssertEqual(elements.compactMap(isEvenOptionalTransform).count, elements.count)
        sut = CircularBuffer(elements: elements)
        sut.removeAll(where: isEvenPredicate)
        XCTAssertTrue(sut.isEmpty)
        
        // let's also do the same test when the storage is shifted:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            sut.removeAll(where: isEvenPredicate)
            XCTAssertTrue(sut.isEmpty)
        }
    }
    
    func testRemoveAllWhere_whenHalfElementsShouldBeRemoved() {
        var elements: Array<Int> = [2, 4, 6, 8, 10, 12, 14, 15, 13, 11, 9, 7, 5, 3, 1]
        sut = CircularBuffer(elements: elements)
        var expectedResult = elements
        expectedResult.removeAll(where: isEvenPredicate)
        sut.removeAll(where: isEvenPredicate)
        XCTAssertEqual(sut.allStoredElements, expectedResult)
        
        // let's also do the same test when the storage is shifted:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            sut.removeAll(where: isEvenPredicate)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
        }
        
        elements = elements.reversed()
        sut = CircularBuffer(elements: elements)
        expectedResult = elements
        expectedResult.removeAll(where: isEvenPredicate)
        sut.removeAll(where: isEvenPredicate)
        XCTAssertEqual(sut.allStoredElements, expectedResult)
        
        // let's also do the same test when the storage is shifted:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            sut.removeAll(where: isEvenPredicate)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
        }
        
        elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        sut.removeAll(where: isEvenPredicate)
        expectedResult = elements
        expectedResult.removeAll(where: isEvenPredicate)
        XCTAssertEqual(sut.allStoredElements, expectedResult)
        
        // let's also do the same test when the storage is shifted:
        for headShift in 1...elements.count {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            sut.removeAll(where: isEvenPredicate)
            XCTAssertEqual(sut.allStoredElements, expectedResult)
        }
    }
    
    // MARK: - withUnsafeBufferPointer(_:) tests
    func testWithUnsafeBufferPointer_whenIsEmpty() {
        XCTAssertTrue(sut.isEmpty)
        let result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertEqual(result, [])
        
        // Let's now also test it with a shifted buffer:
        XCTAssertGreaterThan(sut.capacity, 0)
        for headShift in 1..<sut.capacity {
            sut.head = headShift
            sut.tail = headShift
            let result = sut.withUnsafeBufferPointer { Array($0) }
            XCTAssertEqual(result, [])
        }
        
        XCTAssertThrowsError(try sut.withUnsafeBufferPointer { _ in throw testsThrownError })
    }
    func testWithUnsafeBufferPointer_whenIsNotEmptyAndBodyDoesntThrow() {
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        let result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertEqual(result, elements)
        
        // Let's now also test it with a shifted buffer:
        for headShift in 1..<sut.capacity {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            let result = sut.withUnsafeBufferPointer { Array($0) }
            XCTAssertEqual(result, elements)
        }
    }
    
    func testWithUnsafeBufferPointer_whenIsNotEmptyAndBodyThrows() {
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        let throwingBody: (UnsafeBufferPointer<Int>) throws -> Array<Int> = { _ in throw testsThrownError }
        XCTAssertThrowsError(try sut.withUnsafeBufferPointer(throwingBody))
        // Let's now also test it with a shifted buffer:
        for headShift in 1..<sut.capacity {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            XCTAssertThrowsError(try sut.withUnsafeBufferPointer(throwingBody))
        }
    }
    
    
    // MARK: - withUnsafeMutableBufferPointer(_:) tests
    func testWithUnsafeMutableBufferPointer_whenIsEmpty() {
        XCTAssertTrue(sut.isEmpty)
        let result = sut.withUnsafeMutableBufferPointer { Array($0) }
        XCTAssertEqual(result, [])
        
        // Let's now also test it with a shifted buffer:
        XCTAssertGreaterThan(sut.capacity, 0)
        for headShift in 1..<sut.capacity {
            sut.head = headShift
            sut.tail = headShift
            let result = sut.withUnsafeMutableBufferPointer { Array($0) }
            XCTAssertEqual(result, [])
        }
        
        XCTAssertThrowsError(try sut.withUnsafeMutableBufferPointer { _ in throw testsThrownError })
    }
    
    func testWithUnsafeMuatbleBufferPointer_whenIsNotEmptyAndBodyDoesntThrow() {
        let notThrowingBody: (inout UnsafeMutableBufferPointer<Int>) -> Bool = { buff in
            for i in 0..<buff.count {
                buff[i] *= 10
            }
            
            return true
        }
        let elements = (1...100).shuffled()
        let expectedResult = elements.map { $0 * 10 }
        sut = CircularBuffer(elements: elements)
        XCTAssertTrue(sut.withUnsafeMutableBufferPointer(notThrowingBody))
        XCTAssertEqual(sut.allStoredElements, expectedResult)
        
        // Let's now also test it with a shifted buffer:
        for headShift in 1..<sut.capacity {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            XCTAssertTrue(sut.withUnsafeMutableBufferPointer(notThrowingBody))
            XCTAssertEqual(sut.allStoredElements, expectedResult)
        }
    }
    
    func testWithUnsafeMutableBufferPointer_whenIsNotEmptyAndBodyThrows() {
        let elements = (1...100).shuffled()
        sut = CircularBuffer(elements: elements)
        let throwingBody: (inout UnsafeMutableBufferPointer<Int>) throws -> Bool = { _ in throw testsThrownError }
        XCTAssertThrowsError(try sut.withUnsafeMutableBufferPointer(throwingBody))
        // Let's now also test it with a shifted buffer:
        for headShift in 1..<sut.capacity {
            sut = CircularBuffer.headShiftedInstance(contentsOf: elements, headShift: headShift)
            XCTAssertThrowsError(try sut.withUnsafeMutableBufferPointer(throwingBody))
        }
    }
    
}

// MARK: - Helpers for tests
let testsThrownError = NSError(domain: "com.vdl.circularBuffer", code: 1, userInfo: nil)

// MARK: - Common predicates and closures
let throwingBody: (Int) throws -> Void = { _ in throw testsThrownError }

let isEvenPredicate: (Int) -> Bool = { $0 % 2 == 0 }

let throwingPredicate: (Int) throws -> Bool = { _ in throw testsThrownError }

let multiplyByTenTransform: (Int) -> Int = { $0 * 10 }

let throwingTransform: (Int) throws -> Int = { _ in throw testsThrownError }

let isEvenOptionalTransform: (Int) -> Int? = { isEvenPredicate($0) ? $0 : nil }

let throwingOptionalTransform: (Int) throws -> Int? = { _ in throw testsThrownError }
