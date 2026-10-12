/// A map from an ID's bytes to a dense number `0..<count`, in order of first insertion: how a
/// reader recognizes an ID it has seen without making a `String` (one hash per occurrence, with the
/// standard `Hasher`, so its per-process seed protects against collision floods). The bytes of each
/// ID are copied once, into one growing arena.
@usableFromInline internal struct _IDTable: ~Copyable {
    /// Open addressing with linear probing. A slot is two words: the entry number plus one (0 when
    /// empty) in the low 32 bits, the ID's length (saturated at 255) in the next 8 and 24 bits of
    /// its hash above; then the ID's first 8 bytes. An ID of at most 8 bytes is recognized from its
    /// slot alone, without touching the arena.
    @usableFromInline var slots: UnsafeMutablePointer<(meta: UInt64, prefix: UInt64)>
    @usableFromInline var slotMask: Int
    /// Per entry: its hash, and its bytes' start in the arena (the next entry's start is its end).
    @usableFromInline var hashes: UnsafeMutablePointer<Int>
    @usableFromInline var starts: UnsafeMutablePointer<Int>
    @usableFromInline var entryCapacity: Int
    @usableFromInline var count = 0
    @usableFromInline var arena: UnsafeMutablePointer<UInt8>
    @usableFromInline var arenaCount = 0
    @usableFromInline var arenaCapacity: Int

    @inlinable init() {
        self.init(capacity: 8)
    }

    /// Room for `capacity` entries (of about eight bytes) before growing.
    @inlinable init(capacity: Int) {
        let entries = max(8, capacity)
        var size = 16
        while size &* 3 < entries &* 4 { size &*= 2 }
        slotMask = size &- 1
        slots = .allocate(capacity: size)
        slots.initialize(repeating: (0, 0), count: size)
        entryCapacity = entries
        hashes = .allocate(capacity: entries)
        starts = .allocate(capacity: entries &+ 1)
        starts[0] = 0
        arenaCapacity = max(64, entries &* 8)
        arena = .allocate(capacity: arenaCapacity)
    }

    @inlinable deinit {
        slots.deallocate()
        hashes.deallocate()
        starts.deallocate()
        arena.deallocate()
    }

    /// The hash of `bytes`. At most 8 bytes are hashed as one word, in one round of the hasher
    /// instead of its byte loop: fewer than 8 zero-padded with their count in the top byte (which
    /// tells them apart as the bytes do), 8 as they are (so a word of 8 can share a hash with at
    /// most one shorter ID).
    @inline(__always)
    @inlinable static func hash(_ bytes: UnsafeBufferPointer<UInt8>) -> Int {
        let count = bytes.count
        // One word: its `hashValue`, the hasher's one-shot form, with the same per-process seed.
        if count < 8 { return (prefix(bytes) | UInt64(truncatingIfNeeded: count) << 56).hashValue }
        if count == 8 { return prefix(bytes).hashValue }
        var hasher = Hasher()
        hasher.combine(bytes: UnsafeRawBufferPointer(bytes))
        return hasher.finalize()
    }

    /// The slot's meta word for `bytes` with `hash`, without the entry number.
    @inline(__always)
    @inlinable static func tag(_ bytes: UnsafeBufferPointer<UInt8>, _ hash: Int) -> UInt64 {
        (UInt64(truncatingIfNeeded: hash) & 0xFFFF_FF00_0000_0000) | (UInt64(min(bytes.count, 255)) << 32)
    }

    /// The first 8 bytes of `bytes`, zero-padded, as one word.
    @inline(__always)
    @inlinable static func prefix(_ bytes: UnsafeBufferPointer<UInt8>) -> UInt64 {
        guard let base = bytes.baseAddress else { return 0 }
        let raw = UnsafeRawPointer(base)
        let count = bytes.count
        if count >= 8 { return raw.loadUnaligned(as: UInt64.self).littleEndian }
        // Fewer than eight: a load of four, two and one byte as the count's bits say, none past the
        // end.
        var word: UInt64 = 0
        var k = 0
        if count & 4 != 0 {
            word = UInt64(raw.loadUnaligned(as: UInt32.self).littleEndian)
            k = 4
        }
        if count & 2 != 0 {
            word |= UInt64(raw.loadUnaligned(fromByteOffset: k, as: UInt16.self).littleEndian) << UInt64(8 &* k)
            k &+= 2
        }
        if count & 1 != 0 { word |= UInt64(base[k]) << UInt64(8 &* k) }
        return word
    }

    /// The number of `bytes`, or `nil` when they are new.
    @inlinable func find(_ bytes: UnsafeBufferPointer<UInt8>, hash: Int) -> Int? {
        let tag = Self.tag(bytes, hash)
        let prefix = Self.prefix(bytes)
        var slot = hash & slotMask
        while true {
            let (meta, first) = slots[slot]
            if meta == 0 { return nil }
            if meta & 0xFFFF_FFFF_0000_0000 == tag && first == prefix {
                let entry = Int(truncatingIfNeeded: meta & 0xFFFF_FFFF) &- 1
                if bytes.count <= 8 || equal(entry, bytes) { return entry }
            }
            slot = (slot &+ 1) & slotMask
        }
    }

    /// Adds `bytes`, which must be new, and returns its number.
    @inlinable mutating func insert(_ bytes: UnsafeBufferPointer<UInt8>, hash: Int) -> Int {
        if count == entryCapacity { growEntries() }
        if (count &+ 1) &* 4 > (slotMask &+ 1) &* 3 { growSlots() }
        var slot = hash & slotMask
        while slots[slot].meta != 0 { slot = (slot &+ 1) & slotMask }
        return store(bytes, hash: hash, at: slot)
    }

    /// Adds `bytes` unless they are already an entry, in one probe; whether they were added.
    @inlinable mutating func insertIfAbsent(_ bytes: UnsafeBufferPointer<UInt8>, hash: Int) -> Bool {
        if count == entryCapacity { growEntries() }
        if (count &+ 1) &* 4 > (slotMask &+ 1) &* 3 { growSlots() }
        let tag = Self.tag(bytes, hash)
        let prefix = Self.prefix(bytes)
        var slot = hash & slotMask
        while true {
            let (meta, first) = slots[slot]
            if meta == 0 { break }
            if meta & 0xFFFF_FFFF_0000_0000 == tag && first == prefix {
                let entry = Int(truncatingIfNeeded: meta & 0xFFFF_FFFF) &- 1
                if bytes.count <= 8 || equal(entry, bytes) { return false }
            }
            slot = (slot &+ 1) & slotMask
        }
        _ = store(bytes, hash: hash, at: slot)
        return true
    }

    /// Stores `bytes` as a new entry in the empty `slot`.
    @inlinable mutating func store(_ bytes: UnsafeBufferPointer<UInt8>, hash: Int, at slot: Int) -> Int {
        let entry = count
        let start = arenaCount
        if arenaCount &+ bytes.count > arenaCapacity {
            var capacity = arenaCapacity
            while capacity < arenaCount &+ bytes.count { capacity &*= 2 }
            let grown = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
            grown.update(from: arena, count: arenaCount)
            arena.deallocate()
            arena = grown
            arenaCapacity = capacity
        }
        if let source = bytes.baseAddress { (arena + start).update(from: source, count: bytes.count) }
        arenaCount &+= bytes.count
        hashes[entry] = hash
        starts[entry &+ 1] = arenaCount
        count &+= 1
        slots[slot] = (Self.tag(bytes, hash) | UInt64(entry &+ 1), Self.prefix(bytes))
        return entry
    }

    /// The bytes of entry `entry`, valid until the next insertion.
    @inlinable func bytes(of entry: Int) -> UnsafeBufferPointer<UInt8> {
        UnsafeBufferPointer(start: arena + starts[entry], count: starts[entry &+ 1] &- starts[entry])
    }

    @inlinable func equal(_ entry: Int, _ bytes: UnsafeBufferPointer<UInt8>) -> Bool {
        let start = starts[entry]
        let n = starts[entry &+ 1] &- start
        guard n == bytes.count else { return false }
        guard let other = bytes.baseAddress else { return true }
        let mine = arena + start
        var k = 0
        while k &+ 8 <= n {
            if UnsafeRawPointer(mine + k).loadUnaligned(as: UInt64.self)
                != UnsafeRawPointer(other + k).loadUnaligned(as: UInt64.self)
            {
                return false
            }
            k &+= 8
        }
        while k < n {
            if mine[k] != other[k] { return false }
            k &+= 1
        }
        return true
    }

    @inlinable mutating func growEntries() {
        let capacity = entryCapacity &* 2
        let newHashes = UnsafeMutablePointer<Int>.allocate(capacity: capacity)
        newHashes.update(from: hashes, count: count)
        hashes.deallocate()
        hashes = newHashes
        let newStarts = UnsafeMutablePointer<Int>.allocate(capacity: capacity &+ 1)
        newStarts.update(from: starts, count: count &+ 1)
        starts.deallocate()
        starts = newStarts
        entryCapacity = capacity
    }

    @inlinable mutating func growSlots() {
        let size = (slotMask &+ 1) &* 2
        let newSlots = UnsafeMutablePointer<(meta: UInt64, prefix: UInt64)>.allocate(capacity: size)
        newSlots.initialize(repeating: (0, 0), count: size)
        let mask = size &- 1
        for old in 0 ... slotMask where slots[old].meta != 0 {
            let entry = Int(truncatingIfNeeded: slots[old].meta & 0xFFFF_FFFF) &- 1
            var slot = hashes[entry] & mask
            while newSlots[slot].meta != 0 { slot = (slot &+ 1) & mask }
            newSlots[slot] = slots[old]
        }
        slots.deallocate()
        slots = newSlots
        slotMask = mask
    }
}
