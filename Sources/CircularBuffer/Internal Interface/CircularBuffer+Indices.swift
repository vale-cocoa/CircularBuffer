//
//  CircularBuffer+Indices.swift
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
    internal func checkSubscriptBounds(for position: Int) {
        precondition(position >= 0 && position < count, "subscript index out of bounds")
    }
    
    @usableFromInline
    internal func bufferIndex(from position: Int) -> Int {
        let advanced = head + position
        
        return advanced < capacity ? advanced : advanced - capacity
    }
    
    
    @usableFromInline
    internal func incrementBufferIndex(_ bufferIdx: Int) -> Int {
        
        return bufferIdx == capacity - 1 ? 0 : bufferIdx + 1
    }
    
    @usableFromInline
    internal func decrementBufferIndex(_ bufferIdx: Int) -> Int {
        
        return bufferIdx == 0 ? capacity - 1 : bufferIdx - 1
    }
    
    @usableFromInline
    internal func bufferIndex(from bufferIdx: Int, offsetBy offset: Int) -> Int {
        guard offset != 0 else { return bufferIdx }
        
        let amount = offset % capacity
        guard amount != 0 else { return bufferIdx }
        
        if amount > 0 {
            
            let increased = bufferIdx + amount
            return increased < capacity ? increased : (increased == capacity ? 0 : (amount - (capacity - bufferIdx)))
        } else {
            
            return bufferIdx == 0 ? capacity + amount : ((bufferIdx + amount) < 0 ? (capacity - (-amount - bufferIdx)) : bufferIdx + amount)
        }
    }
    
}
