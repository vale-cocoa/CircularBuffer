//
//  UnsafeMutablePointer+Utilities.swift
//  CircularBuffer
//
//  Created by Valeriano Della Longa on 2020/12/01.
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

extension UnsafeMutablePointer {
    // Initializes from a given collection: it's your responsibility
    //not to go beyond allocated memory.
    @usableFromInline
    func unsafeInitialize<C: Collection>(from newElements: C) where C.Iterator.Element == Pointee {
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
    
    // Assign from given collection: it's your responsibility not to go beyond allocated
    // memory and that the portion of memory assigned was previously initialized.
    @usableFromInline
    func unsafeAssign<C: Collection>(from newElements: C) where Pointee == C.Iterator.Element {
        guard !newElements.isEmpty else { return }
        
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    self.assign(from: buff.baseAddress!, count: buff.count)
                    
                    return true
                })
        else {
            var i = 0
            for element in newElements {
                self.advanced(by: i).pointee = element
                i += 1
            }
            
            return
        }
    }
    
}
