# CircularBuffer

A memory buffer providing amortized O(1) performance for operations on its stored elements at both start and end positions.

This reference type can suit as the underlaying buffer of `MutableCollection` value types needing to perform better than other buffer types that won't guarantee such performance of O(1) for operations of insertion and removal on the first and last elements.
For example `Array` performs in O(1) on operations involving removal/insertion of its last element, but only O(n) on its first element (where n is the number of elements successive the first one).
That's due to the fact that `Array` has to shift elements successive its first one in order to keep its indexing order intact.
On the other hand, `CircularBuffer` uses a clever *head* and *tail* internal indexes system which makes possible not to shift elements when removing/inserting at the first and last indexes.
