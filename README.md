# CircularBuffer

A memory buffer providing amortized O(1) performance for operations on its stored elements at both start and end positions.

This reference type can suit as the underlaying buffer of `MutableCollection` value types needing to perform O(1) for operations of insertion and removal on both, the first and last elements.
For example `Array` performs in O(1) on operations involving removal/insertion of its last element, but only O(*n*) on its first element (where *n* is the number of elements successive the first one).
That's due to the fact that `Array` has to shift elements successive its first one in order to keep its indexing order intact.
On the other hand, `CircularBuffer` uses a clever *head* and *tail* internal indexes system which makes possible not to shift elements when removing/inserting at the first and last indexes.
`CircularBuffer` provides functionalities for storing and removing elements which may overwrite elements previously stored when its storage capacity has been filled-up, allowing it be used effectively as a ring-buffer.
It also provides functionalities for storing and removing new elements with the increase/decrease of the storage capacity. 
These latter functionalities might as well be used in conjuction with the *smart capacity policy*, that is a strategy for increasing/decreasing the capacity of the storage so that the operations for elements addition/removal won't trigger the resize of the underlaying memory buffer too often, hence not affecting the overall performance of those operations.

