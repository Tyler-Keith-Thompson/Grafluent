/// The slot of each vertex, as a `[Vertex: Int]` would hold it, except while the vertices are the
/// `Int`s `0..<count`, each in its own slot: then nothing is stored and a vertex is its own slot, as
/// in the trees' dense layout. Building a generator's graph, or inserting `0, 1, 2, …` in order,
/// then hashes no vertex. The first change that breaks the identity (a vertex out of order, or a
/// removal that moves a slot) writes the table out once, in O(n), and from then on it is a
/// dictionary.
@frozen
@usableFromInline
package struct _VertexSlots<Vertex: Hashable> {
    /// The slots, while `_identityCount < 0`; empty otherwise.
    @usableFromInline package var _table: [Vertex: Int]
    /// When ≥ 0, the vertices are the `Int`s `0..<_identityCount` and each is its own slot.
    /// Always −1 unless `Vertex` is `Int`.
    @usableFromInline package var _identityCount: Int

    /// No vertices.
    @inlinable
    package init() {
        _table = [:]
        _identityCount = Vertex.self == Int.self ? 0 : -1
    }

    /// The vertices `0..<count`, each its own slot. Precondition: `Vertex` is `Int`.
    @inlinable
    package init(identityCount count: Int) {
        precondition(Vertex.self == Int.self && count >= 0)
        _table = [:]
        _identityCount = count
    }

    @inlinable @inline(__always)
    package var _isIdentity: Bool { Vertex.self == Int.self && _identityCount >= 0 }

    /// The slot of `vertex`, or nil; setting nil removes it.
    @inlinable
    package subscript(vertex: Vertex) -> Int? {
        @inline(__always)
        get {
            if _isIdentity {
                let v = unsafeBitCast(vertex, to: Int.self)
                return UInt(bitPattern: v) < UInt(bitPattern: _identityCount) ? v : nil
            }
            return _table[vertex]
        }
        set {
            if _isIdentity {
                let v = unsafeBitCast(vertex, to: Int.self)
                if let newValue {
                    // The next vertex into the next slot keeps the identity.
                    if v == _identityCount, newValue == v {
                        _identityCount &+= 1
                        return
                    }
                } else {
                    if v == _identityCount &- 1 {
                        _identityCount &-= 1
                        return
                    }
                    if UInt(bitPattern: v) >= UInt(bitPattern: _identityCount) { return }
                }
                _writeTable()
            }
            _table[vertex] = newValue
        }
    }

    /// Ends the identity: every vertex `0..<_identityCount` into the table.
    @inlinable
    package mutating func _writeTable() {
        let count = _identityCount
        _identityCount = -1
        _table.reserveCapacity(count)
        for v in 0 ..< count { _table[unsafeBitCast(v, to: Vertex.self)] = v }
    }

    @inlinable
    @discardableResult
    package mutating func removeValue(forKey vertex: Vertex) -> Int? {
        guard let slot = self[vertex] else { return nil }
        self[vertex] = nil
        return slot
    }

    @inlinable
    package mutating func removeAll(keepingCapacity: Bool = false) {
        _table.removeAll(keepingCapacity: keepingCapacity)
        _identityCount = Vertex.self == Int.self ? 0 : -1
    }

    /// Reserves table space, unless the identity needs none.
    @inlinable
    package mutating func reserveCapacity(_ count: Int) {
        if !_isIdentity { _table.reserveCapacity(count) }
    }
}

extension _VertexSlots: Sendable where Vertex: Sendable {}
