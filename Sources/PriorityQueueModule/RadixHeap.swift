/// A monotone min-priority queue of values with nonnegative integer keys, where no key inserted
/// is below the last key removed.
///
/// The radix heap of Ahuja, Mehlhorn, Orlin and Tarjan, in the form with one bucket per bit:
/// bucket `b` holds the keys whose highest bit differing from the last key removed is bit
/// `b - 1`, and bucket 0 the keys equal to it. `insert` is O(1). `popMin()` is O(1) when bucket 0
/// holds a pair; otherwise it empties the lowest nonempty bucket into lower ones. A pair moves
/// only to lower buckets, so it moves at most `UInt.bitWidth` times, and for keys spread over a
/// range of `C` at most log₂ C + 1 times: amortized O(log C) a pop.
///
/// Use it where keys never go below the last one removed, as in Dijkstra's algorithm with
/// integer weights. It has no decrease-key: insert the value again with the lower key and skip
/// the stale pair when it comes out. Values with equal keys leave in an unspecified order.
///
/// The queue is not a `Sequence`. Storage is an array of bucket arrays, copied on write.
@frozen
public struct RadixHeap<Value> {
    public typealias Element = (key: UInt, value: Value)

    /// `_buckets[b]` holds the pairs whose key's highest bit differing from `_lastKey` is bit
    /// `b - 1`; `_buckets[0]` those equal to `_lastKey`.
    @usableFromInline var _buckets: [[Element]]

    /// The key of the last pair removed, or 0; every queued key is at least this.
    @usableFromInline var _lastKey: UInt

    @usableFromInline var _count: Int

    /// An empty queue whose first key may be any value.
    @inlinable
    public init() {
        _buckets = [[Element]](repeating: [], count: UInt.bitWidth &+ 1)
        _lastKey = 0
        _count = 0
    }

    /// The number of queued pairs.
    @inlinable
    public var count: Int { _count }

    /// Whether no pair is queued.
    @inlinable
    public var isEmpty: Bool { _count == 0 }

    /// The key of the last pair removed, or 0 before the first removal. Every key inserted must be
    /// at least this.
    @inlinable
    public var lastRemovedKey: UInt { _lastKey }

    /// The bucket of `key` relative to `lastKey`: 0 when they are equal, otherwise one more than
    /// the index of their highest differing bit.
    @inlinable
    @inline(__always)
    static func _bucket(of key: UInt, after lastKey: UInt) -> Int {
        UInt.bitWidth &- (key ^ lastKey).leadingZeroBitCount
    }

    /// Queues `value` with `key`. O(1) amortized.
    ///
    /// - Precondition: `key >= lastRemovedKey`.
    @inlinable
    public mutating func insert(_ value: Value, key: UInt) {
        precondition(key >= _lastKey, "A radix heap's keys cannot go below the last key removed")
        _buckets[Self._bucket(of: key, after: _lastKey)].append((key, value))
        _count &+= 1
    }

    /// Removes and returns a pair with the lowest key, or `nil` when the queue is empty. O(log C)
    /// amortized, where C bounds the difference between any queued key and the last key removed.
    @inlinable
    public mutating func popMin() -> Element? {
        guard _count > 0 else { return nil }
        _count &-= 1
        // The buffer's closure must not touch `self`, which it holds exclusively.
        var lastKey = _lastKey
        defer { _lastKey = lastKey }
        return _buckets.withUnsafeMutableBufferPointer { buckets in
            if let top = buckets[0].popLast() { return top }
            var i = 1
            while buckets[i].isEmpty { i &+= 1 }
            var moving: [Element] = []
            swap(&moving, &buckets[i])
            var smallest = moving[0].key
            for pair in moving where pair.key < smallest { smallest = pair.key }
            lastKey = smallest
            // Every pair in bucket `i` agrees with the new last key above bit `i - 1`, so each
            // lands in a lower bucket.
            for pair in moving { buckets[Self._bucket(of: pair.key, after: smallest)].append(pair) }
            moving.removeAll(keepingCapacity: true)
            swap(&moving, &buckets[i])
            return buckets[0].removeLast()
        }
    }

    /// Removes and returns a pair with the lowest key. O(log C) amortized.
    ///
    /// - Precondition: the queue is not empty.
    @inlinable
    @discardableResult
    public mutating func removeMin() -> Element {
        guard let top = popMin() else { preconditionFailure("removeMin() on an empty queue") }
        return top
    }
}

extension RadixHeap: Sendable where Value: Sendable {}
