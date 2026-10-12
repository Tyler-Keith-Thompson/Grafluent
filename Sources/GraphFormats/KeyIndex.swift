/// An index of keys by hash for the duplicate checks of the JSON and XML scanners (object keys,
/// attribute names), one table reused for every object or tag that needs it.
///
/// A scanner indexes a frame (one object's keys, one tag's attributes) once it has 16 of them;
/// fewer are compared in turn. Each indexed frame gets a generation; a slot belongs to the frame
/// whose generation it holds and counts as occupied only while that frame is open, so ending a
/// frame is O(1) and the table is never cleared. Frames nest (a JSON object inside a member's
/// value), and only the innermost open one inserts: so a live entry's probe run holds only entries
/// of frames open when it was inserted, which stay open as long as it does, and a lookup can stop
/// at the first slot that is not occupied.
@usableFromInline internal struct _KeyIndex {
    /// Per slot: the generation of the frame that filled it (0: never filled), the key's number in
    /// the scanner's list, and its hash.
    @usableFromInline var slots: [(generation: Int, key: Int, hash: Int)]
    @usableFromInline var mask: Int
    /// Per generation: whether its frame is open.
    @usableFromInline var open: [Bool] = [false]
    /// Entries of open frames.
    @usableFromInline var liveCount = 0
    /// Per open frame, innermost last: its generation and how many entries it has.
    @usableFromInline var frames: [(generation: Int, count: Int)] = []

    @inlinable init() {
        slots = Array(repeating: (0, 0, 0), count: 64)
        mask = 63
    }

    /// Opens a frame; its entries go in until `end()`.
    @inlinable mutating func begin() {
        open.append(true)
        frames.append((open.count &- 1, 0))
    }

    /// Closes the innermost frame.
    @inlinable mutating func end() {
        let frame = frames.removeLast()
        open[frame.generation] = false
        liveCount &-= frame.count
    }

    @inline(__always)
    @inlinable func isOccupied(_ slot: Int) -> Bool { open[slots[slot].generation] }

    /// The number of a key of the innermost frame with `hash` for which `matches` holds, if any.
    @inlinable func find(hash: Int, _ matches: (Int) -> Bool) -> Int? {
        let generation = frames[frames.count &- 1].generation
        var slot = hash & mask
        while isOccupied(slot) {
            let entry = slots[slot]
            if entry.generation == generation && entry.hash == hash && matches(entry.key) { return entry.key }
            slot = (slot &+ 1) & mask
        }
        return nil
    }

    /// Adds key number `key` with `hash` to the innermost frame.
    @inlinable mutating func insert(hash: Int, key: Int) {
        if (liveCount &+ 1) &* 4 > (mask &+ 1) &* 3 { grow() }
        let f = frames.count &- 1
        var slot = hash & mask
        while isOccupied(slot) { slot = (slot &+ 1) & mask }
        slots[slot] = (frames[f].generation, key, hash)
        frames[f].count &+= 1
        liveCount &+= 1
    }

    /// Doubles the table, moving the open frames' entries (outermost frame first, so that each
    /// probe run again holds only entries of frames at least as old as its own).
    @inlinable mutating func grow() {
        let old = slots
        let size = (mask &+ 1) &* 2
        slots = Array(repeating: (0, 0, 0), count: size)
        mask = size &- 1
        var depth: [Int: Int] = [:]
        for (k, frame) in frames.enumerated() { depth[frame.generation] = k }
        let live = old.filter { open[$0.generation] }.sorted { depth[$0.generation]! < depth[$1.generation]! }
        for entry in live {
            var slot = entry.hash & mask
            while isOccupied(slot) { slot = (slot &+ 1) & mask }
            slots[slot] = entry
        }
    }
}
