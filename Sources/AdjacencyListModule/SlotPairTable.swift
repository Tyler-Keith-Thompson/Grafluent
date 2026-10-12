/// An edge as a pair of slots.
@frozen
@usableFromInline
package struct _SlotPair: Hashable {
    @usableFromInline package var source: Int
    @usableFromInline package var target: Int

    @inlinable
    package init(_ source: Int, _ target: Int) {
        self.source = source
        self.target = target
    }
}

/// The per-process seed of every `_SlotPairTable`, so that which pairs collide differs between
/// processes, as with `Hasher`.
@usableFromInline
package let _slotPairSeed: UInt64 = .random(in: .min ... .max)

/// A map from slot pairs to values: open addressing with linear probing over a power-of-two table
/// at most three-quarters full, as `Dictionary` keeps it, but with a multiplicative (Fibonacci)
/// hash of the packed pair, salted with a per-process seed, in place of SipHash, and backward-shift
/// deletion, so removals leave no tombstones. One bucket is the pair packed into a `UInt64` and the
/// value, 16 bytes for an `Int` and 8 for `Void` (a set).
///
/// Both slots must be below 2³² − 1: a graph with that many vertices would not fit in memory.
/// A bucket index (from `index(forKey:)` or `insert`) stays valid until the next insertion or
/// removal.
@frozen
@usableFromInline
package struct _SlotPairTable<Value: BitwiseCopyable> {
    @frozen
    @usableFromInline
    package struct _Bucket {
        /// The packed pair, or `_empty`.
        @usableFromInline package var key: UInt64
        @usableFromInline package var value: Value

        @inlinable
        package init(key: UInt64, value: Value) {
            self.key = key
            self.value = value
        }
    }

    /// The buckets: none, or a power of two of them.
    @usableFromInline package var _buckets: ContiguousArray<_Bucket>
    @usableFromInline package var _count: Int
    /// `64 − log₂(bucket count)`: the hash's top bits are the home bucket.
    @usableFromInline package var _shift: UInt64
    @usableFromInline package var _seed: UInt64

    @inlinable @inline(__always)
    package static var _empty: UInt64 { .max }

    /// The empty table. Allocates nothing.
    @inlinable
    package init() {
        _buckets = []
        _count = 0
        _shift = 64
        _seed = 0
    }

    /// An empty table with room for `capacity` entries.
    @inlinable
    package init(minimumCapacity capacity: Int) {
        self.init()
        reserveCapacity(capacity)
    }

    @inlinable
    package var count: Int { _count }

    @inlinable
    package var isEmpty: Bool { _count == 0 }

    @inlinable @inline(__always)
    package static func _key(_ pair: _SlotPair) -> UInt64 {
        UInt64(truncatingIfNeeded: pair.source) << 32 | UInt64(truncatingIfNeeded: pair.target) & 0xFFFF_FFFF
    }

    @inlinable @inline(__always)
    package static func _pair(_ key: UInt64) -> _SlotPair {
        _SlotPair(Int(truncatingIfNeeded: key >> 32), Int(truncatingIfNeeded: key & 0xFFFF_FFFF))
    }

    @inlinable @inline(__always)
    package func _home(_ key: UInt64) -> Int {
        Int(truncatingIfNeeded: ((key ^ _seed) &* 0x9E37_79B9_7F4A_7C15) &>> _shift)
    }

    /// The bucket holding `pair`, or nil. O(1) expected.
    @inlinable
    package func index(forKey pair: _SlotPair) -> Int? {
        guard _count > 0 else { return nil }
        let key = Self._key(pair)
        let mask = _buckets.count &- 1
        var i = _home(key)
        return _buckets.withUnsafeBufferPointer { buckets in
            while true {
                let k = buckets[i].key
                if k == key { return i }
                if k == Self._empty { return nil }
                i = (i &+ 1) & mask
            }
        }
    }

    /// The value for `pair`, or nil.
    @inlinable
    package subscript(pair: _SlotPair) -> Value? {
        guard let i = index(forKey: pair) else { return nil }
        return _buckets[i].value
    }

    /// Whether `pair` is a key.
    @inlinable
    package func contains(_ pair: _SlotPair) -> Bool { index(forKey: pair) != nil }

    /// The key in bucket `i`.
    @inlinable
    package func key(at i: Int) -> _SlotPair { Self._pair(_buckets[i].key) }

    /// The value in bucket `i`.
    @inlinable
    package func value(at i: Int) -> Value { _buckets[i].value }

    /// Replaces the value in bucket `i`.
    @inlinable
    package mutating func setValue(_ value: Value, at i: Int) { _buckets[i].value = value }

    /// Inserts `pair` with `value` unless it is already a key; returns its bucket either way, with
    /// the existing value left in place.
    @inlinable
    @discardableResult
    package mutating func insert(_ pair: _SlotPair, _ value: Value) -> (inserted: Bool, index: Int) {
        precondition(
            UInt(bitPattern: pair.source) < 0xFFFF_FFFF && UInt(bitPattern: pair.target) < 0xFFFF_FFFF,
            "Slot out of the table's range"
        )
        if (_count &+ 1) &* 4 > _buckets.count &* 3 { _resize(minimumCapacity: _count &+ 1) }
        let key = Self._key(pair)
        let mask = _buckets.count &- 1
        var i = _home(key)
        let inserted = _buckets.withUnsafeMutableBufferPointer { buckets in
            while true {
                let k = buckets[i].key
                if k == key { return false }
                if k == Self._empty {
                    buckets[i] = _Bucket(key: key, value: value)
                    return true
                }
                i = (i &+ 1) & mask
            }
        }
        if inserted { _count &+= 1 }
        return (inserted, i)
    }

    /// Inserts `count` entries, `entry(k)` for `k` in `0..<count`, whose pairs are distinct from
    /// each other and from every key: unchecked. Into an empty table the entries go in in the
    /// order of their home buckets, by a counting sort on the home's top bits, so the probes walk
    /// the table front to back instead of missing the cache once per entry (a bulk build of
    /// 5·10⁵ pairs: 3.7 against 6.7 ms for one `insert` each). Any order gives the same set of keys
    /// reachable from their homes, so lookups do not depend on it. O(count) expected.
    @inlinable
    package mutating func _insertDistinct(count: Int, _ entry: (Int) -> (pair: _SlotPair, value: Value)) {
        guard count > 0 else { return }
        reserveCapacity(_count &+ count)
        let mask = _buckets.count &- 1
        let seed = _seed, shift = _shift
        @inline(__always)
        func hash(_ key: UInt64) -> UInt64 { (key ^ seed) &* 0x9E37_79B9_7F4A_7C15 }
        // A table that fits in the cache gains nothing from the sort.
        guard _count == 0, _buckets.count >= 1 << 14 else {
            _buckets.withUnsafeMutableBufferPointer { buckets in
                for k in 0 ..< count {
                    let (pair, value) = entry(k)
                    let key = Self._checkedKey(pair)
                    var i = Int(truncatingIfNeeded: hash(key) &>> shift)
                    while buckets[i].key != Self._empty { i = (i &+ 1) & mask }
                    buckets[i] = _Bucket(key: key, value: value)
                }
            }
            _count &+= count
            return
        }
        // 1024 runs by the top 10 bits of the hash, which are the top bits of the home bucket:
        // each run's writes are sequential, and its probes stay within 1/1024 of the table.
        var starts = [Int](repeating: 0, count: 1025)
        starts.withUnsafeMutableBufferPointer { starts in
            for k in 0 ..< count {
                starts[Int(truncatingIfNeeded: hash(Self._checkedKey(entry(k).pair)) &>> 54) &+ 1] &+= 1
            }
            for b in 0 ..< 1024 { starts[b &+ 1] &+= starts[b] }
        }
        let sorted = ContiguousArray<_Bucket>(unsafeUninitializedCapacity: count) { buffer, initialized in
            starts.withUnsafeMutableBufferPointer { starts in
                for k in 0 ..< count {
                    let (pair, value) = entry(k)
                    let key = Self._key(pair)
                    let bin = Int(truncatingIfNeeded: hash(key) &>> 54)
                    buffer.initializeElement(at: starts[bin], to: _Bucket(key: key, value: value))
                    starts[bin] &+= 1
                }
            }
            initialized = count
        }
        _buckets.withUnsafeMutableBufferPointer { buckets in
            sorted.withUnsafeBufferPointer { sorted in
                for bucket in sorted {
                    var i = Int(truncatingIfNeeded: hash(bucket.key) &>> shift)
                    while buckets[i].key != Self._empty { i = (i &+ 1) & mask }
                    buckets[i] = bucket
                }
            }
        }
        _count = count
    }

    /// The packed key of `pair`, trapping when a slot is out of range.
    @inlinable @inline(__always)
    package static func _checkedKey(_ pair: _SlotPair) -> UInt64 {
        precondition(
            UInt(bitPattern: pair.source) < 0xFFFF_FFFF && UInt(bitPattern: pair.target) < 0xFFFF_FFFF,
            "Slot out of the table's range"
        )
        return _key(pair)
    }

    /// Sets the value for `pair`, inserting it if it is not a key.
    @inlinable
    package mutating func updateValue(_ value: Value, forKey pair: _SlotPair) {
        let (inserted, i) = insert(pair, value)
        if !inserted { _buckets[i].value = value }
    }

    /// Removes the entry in bucket `i`, moving later entries of its probe run back so that every
    /// remaining key stays reachable from its home bucket.
    @inlinable
    package mutating func remove(at i: Int) {
        let mask = _buckets.count &- 1
        var hole = i
        let seed = _seed, shift = _shift
        _buckets.withUnsafeMutableBufferPointer { buckets in
            var j = hole
            while true {
                j = (j &+ 1) & mask
                let k = buckets[j].key
                if k == Self._empty { break }
                // `k` may fill the hole unless its home lies cyclically in (hole, j].
                let h = Int(truncatingIfNeeded: ((k ^ seed) &* 0x9E37_79B9_7F4A_7C15) &>> shift)
                let reachable = hole <= j ? (hole < h && h <= j) : (hole < h || h <= j)
                if !reachable {
                    buckets[hole] = buckets[j]
                    hole = j
                }
            }
            buckets[hole].key = Self._empty
        }
        _count &-= 1
    }

    /// Removes `pair` and returns its value, or nil when it is not a key.
    @inlinable
    @discardableResult
    package mutating func removeValue(forKey pair: _SlotPair) -> Value? {
        guard let i = index(forKey: pair) else { return nil }
        let value = _buckets[i].value
        remove(at: i)
        return value
    }

    @inlinable
    package mutating func removeAll(keepingCapacity: Bool = false) {
        guard keepingCapacity, !_buckets.isEmpty else {
            self = Self()
            return
        }
        if _count == 0 { return }
        _buckets.withUnsafeMutableBufferPointer { buckets in
            for i in buckets.indices { buckets[i].key = Self._empty }
        }
        _count = 0
    }

    /// Makes room for `capacity` entries without growing.
    @inlinable
    package mutating func reserveCapacity(_ capacity: Int) {
        if capacity &* 4 > _buckets.count &* 3 { _resize(minimumCapacity: capacity) }
    }

    /// Moves every entry into the smallest power-of-two table, at least 16 buckets, that holds
    /// `minimumCapacity` entries at most three-quarters full.
    @inlinable
    package mutating func _resize(minimumCapacity: Int) {
        var bits = 4
        while (1 << bits) &* 3 < Swift.max(minimumCapacity, _count) &* 4 { bits &+= 1 }
        let size = 1 << bits
        var buckets = ContiguousArray<_Bucket>(unsafeUninitializedCapacity: size) { buffer, initialized in
            let raw = UnsafeMutableRawPointer(buffer.baseAddress!)
            let stride = MemoryLayout<_Bucket>.stride
            // Only the keys need a value: a value is read only beside a key.
            for i in 0 ..< size { raw.storeBytes(of: Self._empty, toByteOffset: i &* stride, as: UInt64.self) }
            initialized = size
        }
        let seed = _buckets.isEmpty ? _slotPairSeed : _seed
        let shift = UInt64(64 &- bits)
        let mask = size &- 1
        buckets.withUnsafeMutableBufferPointer { buckets in
            _buckets.withUnsafeBufferPointer { old in
                for bucket in old where bucket.key != Self._empty {
                    var i = Int(truncatingIfNeeded: ((bucket.key ^ seed) &* 0x9E37_79B9_7F4A_7C15) &>> shift)
                    while buckets[i].key != Self._empty { i = (i &+ 1) & mask }
                    buckets[i] = bucket
                }
            }
        }
        _buckets = buckets
        _shift = shift
        _seed = seed
    }
}

extension _SlotPairTable: Sequence {
    /// The entries, in bucket order (which depends on the process's seed).
    @frozen
    @usableFromInline
    package struct Iterator: IteratorProtocol {
        @usableFromInline let _buckets: ContiguousArray<_Bucket>
        @usableFromInline var _next: Int

        @inlinable
        package init(_buckets: ContiguousArray<_Bucket>) {
            self._buckets = _buckets
            _next = 0
        }

        @inlinable
        package mutating func next() -> (key: _SlotPair, value: Value)? {
            while _next < _buckets.count {
                let bucket = _buckets[_next]
                _next &+= 1
                if bucket.key != _SlotPairTable._empty { return (_SlotPairTable._pair(bucket.key), bucket.value) }
            }
            return nil
        }
    }

    @inlinable
    package func makeIterator() -> Iterator { Iterator(_buckets: _buckets) }

    @inlinable
    package var underestimatedCount: Int { _count }
}

extension _SlotPairTable._Bucket: Sendable where Value: Sendable {}
extension _SlotPairTable: Sendable where Value: Sendable {}
extension _SlotPair: Sendable {}
