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
    /// (unchecked). One counting pass sizes the vertex rows; one scatter then writes each
    /// incidence's hyperedge and its place in its vertex's rows, into uninitialized storage.
    /// O(n + p).
    @inlinable
    package init(vertexCount n: Int, offsets: ContiguousArray<Int>, members: ContiguousArray<Int>) {
        let m = offsets.count &- 1
        let total = members.count
        var rowOffsets = [Int](repeating: 0, count: n &+ 1)
        members.withUnsafeBufferPointer { members in
            rowOffsets.withUnsafeMutableBufferPointer { rowOffsets in
                for q in 0 ..< total { rowOffsets[members[q] &+ 1] &+= 1 }
                for i in 0 ..< n { rowOffsets[i &+ 1] &+= rowOffsets[i] }
            }
        }
        var fill = rowOffsets
        var storage = ContiguousArray<Int>()
        var positionStorage = ContiguousArray<Int>()
        let hyperedgeOfIncidence = ContiguousArray<Int>(unsafeUninitializedCapacity: total) { hyperedgeOf, hyperedgeCount in
            storage = ContiguousArray(unsafeUninitializedCapacity: total) { storage, storageCount in
                positionStorage = ContiguousArray(unsafeUninitializedCapacity: total) { positionStorage, positionCount in
                    members.withUnsafeBufferPointer { members in
                        offsets.withUnsafeBufferPointer { offsets in
                            fill.withUnsafeMutableBufferPointer { fill in
                                for p in 0 ..< m {
                                    for q in offsets[p] ..< offsets[p &+ 1] {
                                        hyperedgeOf[q] = p
                                        let i = members[q]
                                        let slot = fill[i]
                                        fill[i] = slot &+ 1
                                        storage[slot] = q
                                        positionStorage[slot] = p
                                    }
                                }
                            }
                        }
                    }
                    positionCount = total
                }
                storageCount = total
            }
            hyperedgeCount = total
        }
        memberOffsets = offsets
        self.members = members
        self.hyperedgeOfIncidence = hyperedgeOfIncidence
        incidences = _RowPool(storage: storage, offsets: rowOffsets)
        positions = _RowPool(storage: positionStorage, offsets: rowOffsets)
    }

    /// `Hypergraph._withIncidenceRows`, lent from the storage: the member rows and both vertex
    /// row pools, whose row tables are (start, count, capacity).
    @inlinable
    package func withIncidenceRows<Result>(
        _ body: (
            _ memberOffsets: UnsafeBufferPointer<Int>, _ members: UnsafeBufferPointer<Int>,
            _ incidences: UnsafeBufferPointer<Int>, _ incidenceRows: UnsafeBufferPointer<Int>,
            _ hyperedges: UnsafeBufferPointer<Int>, _ hyperedgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result {
        memberOffsets.withUnsafeBufferPointer { offsets in
            members.withUnsafeBufferPointer { members in
                incidences.withUnsafeRows { incidences, incidenceRows in
                    positions.withUnsafeRows { positions, positionRows in
                        body(offsets, members, incidences, incidenceRows, positions, positionRows)
                    }
                }
            }
        }
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

/// Assigns vertex indices during a bulk build. While the vertices are the `Int`s
/// `0..<identityCount` in order, an `Int` member below that count, or equal to it (a new vertex),
/// is its own index and nothing is hashed or stored; `vertices()` then builds the set at once
/// with `OrderedSet(uncheckedUniqueElements:)`. Any other vertex, or an `Int` out of order, moves
/// the identity prefix into `set` and goes through it from then on.
@frozen
@usableFromInline
internal struct _VertexIndexer<Vertex: Hashable> {
    /// The vertices, once the identity has ended (empty before).
    @usableFromInline internal var set: OrderedSet<Vertex>
    /// The vertices are `0..<identityCount` in order and `set` is empty when it is not negative;
    /// always −1 unless `Vertex` is `Int`.
    @usableFromInline internal var identityCount: Int

    @inlinable
    internal init() {
        set = []
        identityCount = Vertex.self == Int.self ? 0 : -1
    }

    /// The number of vertices so far.
    @inlinable
    internal var count: Int { identityCount >= 0 ? identityCount : set.count }

    /// The index of `vertex`, inserting it at the next index if it is new.
    @inlinable
    @inline(__always)
    internal mutating func index(of vertex: Vertex) -> Int {
        if identityCount >= 0 {
            let i = unsafeBitCast(vertex, to: Int.self)
            if UInt(bitPattern: i) < UInt(bitPattern: identityCount) { return i }
            if i == identityCount {
                identityCount &+= 1
                return i
            }
            _endIdentity()
        }
        return set.append(vertex).index
    }

    @inlinable
    internal mutating func _endIdentity() {
        // `Vertex` is `Int` here; building from the range itself is what makes this fast.
        set = OrderedSet<Int>(uncheckedUniqueElements: 0 ..< identityCount) as! OrderedSet<Vertex>
        identityCount = -1
    }

    /// The vertices, in index order.
    @inlinable
    internal mutating func vertices() -> OrderedSet<Vertex> {
        if identityCount >= 0 { _endIdentity() }
        return set
    }
}

/// Flat rows built one entry at a time, each kept strictly ascending, in one buffer: an entry is
/// inserted in place from the row's end and a repeat is dropped as it arrives, so a short row
/// needs no separate sort. A row that grows past 32 entries is appended unsorted and sorted once
/// at its end, keeping long rows at O(k log k). The buffer is raw memory grown by doubling, so
/// an insertion has no bounds or uniqueness checks; `finish()` copies it into the members array
/// and frees it, and must be called exactly once.
@frozen
@usableFromInline
internal struct _SortedRowsBuilder {
    @usableFromInline internal var offsets: ContiguousArray<Int>
    @usableFromInline internal var buffer: UnsafeMutablePointer<Int>
    @usableFromInline internal var capacity: Int
    @usableFromInline internal var count: Int
    @usableFromInline internal var rowStart: Int
    @usableFromInline internal var rowSorted: Bool

    @inlinable
    internal init(rowCapacity: Int) {
        offsets = [0]
        offsets.reserveCapacity(rowCapacity &+ 1)
        capacity = Swift.max(16, rowCapacity &* 4)
        buffer = .allocate(capacity: capacity)
        count = 0
        rowStart = 0
        rowSorted = true
    }

    @inlinable
    internal mutating func _grow() {
        let newCapacity = capacity &* 2
        let moved = UnsafeMutablePointer<Int>.allocate(capacity: newCapacity)
        moved.moveInitialize(from: buffer, count: count)
        buffer.deallocate()
        buffer = moved
        capacity = newCapacity
    }

    @inlinable
    @inline(__always)
    internal mutating func append(_ x: Int) {
        if count == capacity { _grow() }
        guard rowSorted, count &- rowStart < 32 else {
            rowSorted = false
            buffer[count] = x
            count &+= 1
            return
        }
        var j = count
        while j > rowStart {
            let y = buffer[j &- 1]
            if y < x { break }
            if y == x { return }
            j &-= 1
        }
        var k = count
        while k > j {
            buffer[k] = buffer[k &- 1]
            k &-= 1
        }
        buffer[j] = x
        count &+= 1
    }

    @inlinable
    internal mutating func endRow() {
        if !rowSorted {
            var row = UnsafeMutableBufferPointer(start: buffer + rowStart, count: count &- rowStart)
            row.sort()
            var write = 1
            for read in 1 ..< row.count where row[read] != row[write &- 1] {
                row[write] = row[read]
                write &+= 1
            }
            count = rowStart &+ write
            rowSorted = true
        }
        offsets.append(count)
        rowStart = count
    }

    /// The offsets and the members; frees the buffer.
    @inlinable
    internal mutating func finish() -> (offsets: ContiguousArray<Int>, members: ContiguousArray<Int>) {
        let members = ContiguousArray(UnsafeBufferPointer(start: buffer, count: count))
        buffer.deallocate()
        capacity = 0
        count = 0
        return (offsets, members)
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
