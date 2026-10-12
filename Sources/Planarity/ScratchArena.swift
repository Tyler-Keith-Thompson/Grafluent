/// A flat array of 32-bit integers read and written as `Int`: the storage of the planarity
/// engines and of an embedding's rows. Half the memory traffic of `Int` arrays, and on 64-bit
/// targets the widening load costs nothing. A debug build checks every index; an optimized build
/// checks none.
@usableFromInline
struct _Int32Buffer {
    @usableFromInline let base: UnsafeMutableBufferPointer<Int32>

    @inlinable
    init(_ base: UnsafeMutableBufferPointer<Int32>) { self.base = base }

    @inlinable
    init(_ base: UnsafeBufferPointer<Int32>) { self.base = UnsafeMutableBufferPointer(mutating: base) }

    @inlinable
    var count: Int { base.count }

    @inlinable
    subscript(i: Int) -> Int {
        @inline(__always) get { Int(base[i]) }
        @inline(__always) nonmutating set { base[i] = Int32(truncatingIfNeeded: newValue) }
    }
}

extension _Int32Buffer {
    /// The most vertices plus half-edges the engines take: every vertex number, half-edge number
    /// and count they store fits in an `Int32`.
    @inlinable
    static var indexLimit: Int { Int(Int32.max) / 8 }
}

/// Scratch memory for the planarity engines: one allocation carved into 32-bit integer arrays, freed
/// when the arena ends.
@usableFromInline
struct _ScratchArena: ~Copyable {
    @usableFromInline let storage: UnsafeMutableBufferPointer<Int32>
    @usableFromInline var used = 0

    @usableFromInline
    init(capacity: Int) {
        storage = .allocate(capacity: Swift.max(capacity, 1))
    }

    /// The next `count` integers, each set to `value`.
    @usableFromInline
    mutating func take(_ count: Int, repeating value: Int) -> _Int32Buffer {
        let slice = takeUninitialized(count)
        slice.base.initialize(repeating: Int32(truncatingIfNeeded: value))
        return slice
    }

    /// The next `count` integers, left as they are: for arrays written before they are read.
    @usableFromInline
    mutating func takeUninitialized(_ count: Int) -> _Int32Buffer {
        precondition(count >= 0 && used + count <= storage.count, "Scratch arena overflow")
        let slice = UnsafeMutableBufferPointer(rebasing: storage[used ..< used + count])
        used += count
        return _Int32Buffer(slice)
    }

    deinit {
        storage.deallocate()
    }
}
