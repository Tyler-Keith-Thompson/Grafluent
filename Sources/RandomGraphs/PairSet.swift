/// A set of vertex pairs, for the membership tests of G(n, m) and Watts–Strogatz: open addressing
/// with linear probing over a power-of-two table at most half full, a multiplicative (Fibonacci)
/// hash, and backward-shift deletion, so removals leave no tombstones. `Set<Int>` hashes with
/// SipHash, several times the cost of one multiply, and these loops do little else.
///
/// Keys are pair codes `u · n + v + 1`, so 0 marks an empty slot; for n < 2^32 they are distinct.
/// The table never grows: the caller sizes it for the most pairs it will hold.
@frozen
@usableFromInline
struct _PairSet {
    @usableFromInline var keys: [UInt64]
    @usableFromInline let shift: UInt64
    @usableFromInline let mask: Int

    /// A table for up to `capacity` pairs: at least twice that many slots, and at least 16.
    @inlinable
    init(capacity: Int) {
        var bits = 4
        while (1 << bits) < 2 * capacity { bits += 1 }
        keys = [UInt64](repeating: 0, count: 1 << bits)
        shift = UInt64(64 - bits)
        mask = (1 << bits) - 1
    }

    @inlinable
    @inline(__always)
    static func home(_ key: UInt64, _ shift: UInt64) -> Int {
        Int(truncatingIfNeeded: (key &* 0x9E37_79B9_7F4A_7C15) >> shift)
    }

    /// Whether `key` is present.
    @inlinable
    @inline(__always)
    func contains(_ key: UInt64) -> Bool {
        let mask = mask
        var i = Self.home(key, shift)
        return keys.withUnsafeBufferPointer { keys in
            while true {
                let k = keys[i]
                if k == key { return true }
                if k == 0 { return false }
                i = (i &+ 1) & mask
            }
        }
    }

    /// Inserts `key`; false when it was already present.
    @inlinable
    @inline(__always)
    mutating func insert(_ key: UInt64) -> Bool {
        let mask = mask
        var i = Self.home(key, shift)
        return keys.withUnsafeMutableBufferPointer { keys in
            while true {
                let k = keys[i]
                if k == key { return false }
                if k == 0 {
                    keys[i] = key
                    return true
                }
                i = (i &+ 1) & mask
            }
        }
    }

    /// Removes `key`, which must be present, moving later entries of its probe run back so that
    /// every remaining key stays reachable from its home slot.
    @inlinable
    mutating func remove(_ key: UInt64) {
        let mask = mask, shift = shift
        var hole = Self.home(key, shift)
        keys.withUnsafeMutableBufferPointer { keys in
            while keys[hole] != key { hole = (hole &+ 1) & mask }
            var j = hole
            while true {
                j = (j &+ 1) & mask
                let k = keys[j]
                if k == 0 { break }
                // `k` may fill the hole unless its home lies cyclically in (hole, j].
                let h = Self.home(k, shift)
                let reachable = hole <= j ? (hole < h && h <= j) : (hole < h || h <= j)
                if !reachable {
                    keys[hole] = k
                    hole = j
                }
            }
            keys[hole] = 0
        }
    }
}
