import AdjacencyListModule
import OrderedCollections

/// One plane of incidences, stored both ways: the hyperedges as compressed sparse rows of vertex
/// indices, and each vertex's row of incidence numbers. `UndirectedIncidenceList` keeps one plane,
/// `IncidenceList` two (sources and targets), as SimpleDirectedHypergraphs.jl keeps `hg_tail` and
/// `hg_head`.
///
/// Incidence `q` is the `q`th entry of `members`: hyperedge `p` is
/// `members[memberOffsets[p] ..< memberOffsets[p + 1]]`, ascending, and `hyperedgeOfIncidence[q]`
/// is the hyperedge holding incidence `q`. Vertex `i`'s row in `incidences` lists the incidence
/// numbers of its memberships, ascending, because hyperedges are only appended, and its row in
/// `positions`, parallel to it, the hyperedges of those incidences: so `incidentHyperedges` is a
/// stored row, read without a dependent load per entry, as `UndirectedAdjacencyList` keeps its
/// neighbor and incident-edge rows side by side. The incidence graph views use the incidence
/// numbers as edge positions.
@frozen
@usableFromInline
package struct _IncidencePlane {
    /// `hyperedgeCount + 1` offsets into `members`, starting at 0.
    @usableFromInline package var memberOffsets: ContiguousArray<Int>
    /// The vertex index of each incidence.
    @usableFromInline package var members: ContiguousArray<Int>
    /// The hyperedge of each incidence, parallel to `members`.
    @usableFromInline package var hyperedgeOfIncidence: ContiguousArray<Int>
    /// For each vertex index, its incidence numbers.
    @usableFromInline package var incidences: _RowPool
    /// For each vertex index, its hyperedge positions, parallel to `incidences`.
    @usableFromInline package var positions: _RowPool

    /// No vertices and no hyperedges.
    @inlinable
    package init() {
        memberOffsets = [0]
        members = []
        hyperedgeOfIncidence = []
        incidences = _RowPool()
        positions = _RowPool()
    }

    /// The plane of `vertexCount` vertices whose hyperedges are given as flat rows: hyperedge `p`
    /// is `members[offsets[p] ..< offsets[p + 1]]`, each row strictly ascending and in range
    /// (unchecked). The vertex rows are laid out at their exact sizes in one counting pass. O(n + p).
    @inlinable
    package init(vertexCount n: Int, offsets: ContiguousArray<Int>, members: ContiguousArray<Int>) {
        let m = offsets.count - 1
        let total = members.count
        var hyperedgeOfIncidence = ContiguousArray<Int>(repeating: 0, count: total)
        var rowOffsets = [Int](repeating: 0, count: n + 1)
        var storage = ContiguousArray<Int>(repeating: 0, count: total)
        var positionStorage = ContiguousArray<Int>(repeating: 0, count: total)
        members.withUnsafeBufferPointer { members in
            offsets.withUnsafeBufferPointer { offsets in
                hyperedgeOfIncidence.withUnsafeMutableBufferPointer { hyperedgeOf in
                    rowOffsets.withUnsafeMutableBufferPointer { rowOffsets in
                        for p in 0 ..< m {
                            for q in offsets[p] ..< offsets[p &+ 1] { hyperedgeOf[q] = p }
                        }
                        for q in 0 ..< total { rowOffsets[members[q] &+ 1] &+= 1 }
                        for i in 0 ..< n { rowOffsets[i &+ 1] &+= rowOffsets[i] }
                    }
                }
            }
        }
        var fill = rowOffsets
        members.withUnsafeBufferPointer { members in
            hyperedgeOfIncidence.withUnsafeBufferPointer { hyperedgeOf in
                storage.withUnsafeMutableBufferPointer { storage in
                    positionStorage.withUnsafeMutableBufferPointer { positionStorage in
                        fill.withUnsafeMutableBufferPointer { fill in
                            for q in 0 ..< total {
                                let i = members[q]
                                let slot = fill[i]
                                storage[slot] = q
                                positionStorage[slot] = hyperedgeOf[q]
                                fill[i] = slot &+ 1
                            }
                        }
                    }
                }
            }
        }
        memberOffsets = offsets
        self.members = members
        self.hyperedgeOfIncidence = hyperedgeOfIncidence
        incidences = _RowPool(storage: storage, offsets: rowOffsets)
        positions = _RowPool(storage: positionStorage, offsets: rowOffsets)
    }

    @inlinable
    package var hyperedgeCount: Int { memberOffsets.count &- 1 }

    @inlinable
    package var incidenceCount: Int { members.count }

    @inlinable
    @inline(__always)
    package func checkHyperedge(_ p: Int) {
        precondition(p >= 0 && p < memberOffsets.count &- 1, "Hyperedge position \(p) is out of range 0..<\(memberOffsets.count &- 1)")
    }

    @inlinable
    @inline(__always)
    package func checkVertex(_ i: Int) {
        precondition(i >= 0 && i < incidences.rowCount, "Vertex index \(i) is out of range 0..<\(incidences.rowCount)")
    }

    /// The incidence numbers of hyperedge `p`.
    @inlinable
    package func range(of p: Int) -> Range<Int> {
        checkHyperedge(p)
        return memberOffsets[p] ..< memberOffsets[p &+ 1]
    }

    /// The vertex indices of hyperedge `p`, ascending.
    @inlinable
    package func memberIndices(of p: Int) -> ArraySlice<Int> {
        members[range(of: p)]
    }

    @inlinable
    package func size(of p: Int) -> Int {
        checkHyperedge(p)
        return memberOffsets[p &+ 1] &- memberOffsets[p]
    }

    /// The incidence numbers of vertex `i`.
    @inlinable
    package func row(_ i: Int) -> ArraySlice<Int> {
        checkVertex(i)
        return incidences[row: i]
    }

    /// The hyperedge positions of vertex `i`, ascending.
    @inlinable
    package func hyperedgeRow(_ i: Int) -> ArraySlice<Int> {
        checkVertex(i)
        return positions[row: i]
    }

    @inlinable
    package func degree(_ i: Int) -> Int {
        checkVertex(i)
        return incidences.count(ofRow: i)
    }

    @inlinable
    package mutating func appendVertex() {
        incidences.appendRow()
        positions.appendRow()
    }

    /// Appends a hyperedge of `sortedMembers`, strictly ascending vertex indices in range
    /// (unchecked). Amortized O(k).
    @inlinable
    package mutating func appendHyperedge(_ sortedMembers: some Sequence<Int>) {
        let p = hyperedgeCount
        for i in sortedMembers {
            let q = members.count
            members.append(i)
            hyperedgeOfIncidence.append(p)
            incidences.append(q, toRow: i)
            positions.append(p, toRow: i)
        }
        memberOffsets.append(members.count)
    }

    @inlinable
    package mutating func removeAll(keepingCapacity: Bool) {
        memberOffsets.removeAll(keepingCapacity: keepingCapacity)
        memberOffsets.append(0)
        members.removeAll(keepingCapacity: keepingCapacity)
        hyperedgeOfIncidence.removeAll(keepingCapacity: keepingCapacity)
        incidences.removeAll(keepingCapacity: keepingCapacity)
        positions.removeAll(keepingCapacity: keepingCapacity)
    }

    @inlinable
    package mutating func reserveCapacity(vertexCount: Int, hyperedgeCount: Int, incidenceCount: Int) {
        memberOffsets.reserveCapacity(hyperedgeCount &+ 1)
        members.reserveCapacity(incidenceCount)
        hyperedgeOfIncidence.reserveCapacity(incidenceCount)
        incidences.reserveCapacity(rows: vertexCount, entries: incidenceCount)
        positions.reserveCapacity(rows: vertexCount, entries: incidenceCount)
    }

    /// The hyperedges, each as an ascending row, by position.
    @inlinable
    package func rows() -> [[Int]] {
        (0 ..< hyperedgeCount).map { Array(memberIndices(of: $0)) }
    }

    /// The transpose: hyperedge `i` of the result is vertex `i`'s row of hyperedge positions, over
    /// `hyperedgeCount` vertices. O(n + m + p).
    @inlinable
    package func transposed(vertexCount n: Int) -> _IncidencePlane {
        var offsets = ContiguousArray<Int>()
        offsets.reserveCapacity(n &+ 1)
        offsets.append(0)
        var flat = ContiguousArray<Int>()
        flat.reserveCapacity(incidenceCount)
        for i in 0 ..< n {
            flat.append(contentsOf: positions[row: i])
            offsets.append(flat.count)
        }
        return _IncidencePlane(vertexCount: hyperedgeCount, offsets: offsets, members: flat)
    }
}

extension _IncidencePlane: Sendable {}

/// `indices` sorted ascending without repeats, in place. O(k) when already strictly ascending,
/// O(k log k) otherwise.
@inlinable
package func _sortUnique(_ indices: inout [Int]) {
    var ascending = true
    var k = 1
    while k < indices.count {
        if indices[k &- 1] >= indices[k] {
            ascending = false
            break
        }
        k &+= 1
    }
    if ascending { return }
    indices.sort()
    var write = 1
    for read in 1 ..< indices.count where indices[read] != indices[write &- 1] {
        indices[write] = indices[read]
        write &+= 1
    }
    indices.removeLast(indices.count &- write)
}

/// Whether two lists of rows hold the same multiset of rows: sorts each list (by length, then
/// lexicographically) and compares them in order. O(p log m) index comparisons, no hashing.
@inlinable
package func _sameRowMultiset(_ lhs: [[Int]], _ rhs: [[Int]]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    let order: ([Int], [Int]) -> Bool = { a, b in
        a.count != b.count ? a.count < b.count : a.lexicographicallyPrecedes(b)
    }
    return lhs.sorted(by: order) == rhs.sorted(by: order)
}

/// Assigns vertex indices during a bulk build: an `OrderedSet` that, while its elements are the
/// `Int`s `0..<identityCount` in order, answers an `Int` member below that count as its own index
/// without hashing it (`AdjacencyListModule`'s identity slots do the same). Any other vertex, or
/// an `Int` out of order, goes through the set, and an out-of-order insertion ends the identity.
@frozen
@usableFromInline
internal struct _VertexIndexer<Vertex: Hashable> {
    @usableFromInline internal var set: OrderedSet<Vertex>
    /// The vertices are `0..<identityCount` in order when it is not negative; always −1 unless
    /// `Vertex` is `Int`.
    @usableFromInline internal var identityCount: Int

    @inlinable
    internal init() {
        set = []
        identityCount = Vertex.self == Int.self ? 0 : -1
    }

    /// The index of `vertex`, inserting it at the next index if it is new.
    @inlinable
    @inline(__always)
    internal mutating func index(of vertex: Vertex) -> Int {
        if identityCount >= 0 {
            let i = unsafeBitCast(vertex, to: Int.self)
            if UInt(bitPattern: i) < UInt(bitPattern: identityCount) { return i }
            let (inserted, index) = set.append(vertex)
            if inserted { identityCount = i == identityCount ? identityCount &+ 1 : -1 }
            return index
        }
        return set.append(vertex).index
    }
}

/// `flat[start...]` sorted ascending without repeats, in place, the rest untouched. O(k) when
/// already strictly ascending, O(k log k) otherwise.
@inlinable
package func _sortUniqueTail(_ flat: inout ContiguousArray<Int>, from start: Int) {
    let end = flat.count
    var k = start &+ 1
    while k < end {
        if flat[k &- 1] >= flat[k] { break }
        k &+= 1
    }
    if k >= end { return }
    if end &- start <= 16 {
        // Insertion sort: the standard sort's setup dominates on a hyperedge of a few members.
        flat.withUnsafeMutableBufferPointer { flat in
            for i in k ..< end {
                let x = flat[i]
                var j = i
                while j > start, flat[j &- 1] > x {
                    flat[j] = flat[j &- 1]
                    j &-= 1
                }
                flat[j] = x
            }
        }
    } else {
        flat[start ..< end].sort()
    }
    var write = start &+ 1
    for read in start &+ 1 ..< end where flat[read] != flat[write &- 1] {
        flat[write] = flat[read]
        write &+= 1
    }
    flat.removeLast(end &- write)
}
