/// Scratch memory for the planarity engines: one allocation carved into integer arrays, freed when
/// the arena ends. The slices are buffers, so a debug build checks every index and an optimized
/// build checks none.
@usableFromInline
struct _ScratchArena: ~Copyable {
    @usableFromInline let storage: UnsafeMutableBufferPointer<Int>
    @usableFromInline var used = 0

    @usableFromInline
    init(capacity: Int) {
        storage = .allocate(capacity: Swift.max(capacity, 1))
    }

    /// The next `count` integers, each set to `value`.
    @usableFromInline
    mutating func take(_ count: Int, repeating value: Int) -> UnsafeMutableBufferPointer<Int> {
        precondition(count >= 0 && used + count <= storage.count, "Scratch arena overflow")
        let slice = UnsafeMutableBufferPointer(rebasing: storage[used ..< used + count])
        slice.initialize(repeating: value)
        used += count
        return slice
    }

    /// The next `count` integers, left as they are: for arrays written before they are read.
    @usableFromInline
    mutating func takeUninitialized(_ count: Int) -> UnsafeMutableBufferPointer<Int> {
        precondition(count >= 0 && used + count <= storage.count, "Scratch arena overflow")
        let slice = UnsafeMutableBufferPointer(rebasing: storage[used ..< used + count])
        used += count
        return slice
    }

    deinit {
        storage.deallocate()
    }
}
