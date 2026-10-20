import GraphProtocols

// Bulk construction from edges in insertion order: `MutableDirectedGraph._built` and
// `MutableGraph._built`, which the `GraphFormats` readers build through, and the public bulk
// initializers, through `_SlotPairs`. Each row is laid out at its exact size by a stable counting
// sort, so it lists its edges in position order, as inserting the edges one at a time would leave
// it. O(n + m), with no row growing. Repeated pairs are found by a counting sort and a stamp per
// row, without hashing. The simple lists drop them, and the multigraphs link them into their
// parallel classes.

/// The rows and records of a directed graph on `0..<n` whose edge at position `p` is
/// `(sources[p], targets[p])`, for `AdjacencyList` and `DirectedPseudograph`.
@frozen
@usableFromInline
package struct _ArcRows {
    @usableFromInline package var out: _RowPool
    @usableFromInline package var outEdges: _RowPool
    @usableFromInline package var `in`: _RowPool
    @usableFromInline package var inEdges: _RowPool
    @usableFromInline package var records: ContiguousArray<_ArcRecord>

    /// Two counting sorts, by source and by target, each stable in position order. O(n + m).
    @inlinable
    package init(vertexCount n: Int, sources: [Int], targets: [Int]) {
        let m = sources.count
        var outOffsets = [Int](repeating: 0, count: n + 1)
        var inOffsets = [Int](repeating: 0, count: n + 1)
        for p in 0 ..< m {
            outOffsets[sources[p] &+ 1] &+= 1
            inOffsets[targets[p] &+ 1] &+= 1
        }
        for v in 0 ..< n {
            outOffsets[v &+ 1] &+= outOffsets[v]
            inOffsets[v &+ 1] &+= inOffsets[v]
        }
        var outStorage = ContiguousArray<Int>(repeating: 0, count: m)
        var outEdgeStorage = ContiguousArray<Int>(repeating: 0, count: m)
        var inStorage = ContiguousArray<Int>(repeating: 0, count: m)
        var inEdgeStorage = ContiguousArray<Int>(repeating: 0, count: m)
        var records = ContiguousArray<_ArcRecord>()
        records.reserveCapacity(m)
        var outFill = outOffsets
        var inFill = inOffsets
        outStorage.withUnsafeMutableBufferPointer { outStorage in
            outEdgeStorage.withUnsafeMutableBufferPointer { outEdgeStorage in
                inStorage.withUnsafeMutableBufferPointer { inStorage in
                    inEdgeStorage.withUnsafeMutableBufferPointer { inEdgeStorage in
                        for p in 0 ..< m {
                            let source = sources[p], target = targets[p]
                            let o = outFill[source]
                            outFill[source] = o &+ 1
                            outStorage[o] = target
                            outEdgeStorage[o] = p
                            let i = inFill[target]
                            inFill[target] = i &+ 1
                            inStorage[i] = source
                            inEdgeStorage[i] = p
                            records.append(_ArcRecord(source: source, target: target, out: o &- outOffsets[source], in: i &- inOffsets[target]))
                        }
                    }
                }
            }
        }
        let outRows = _RowPool._packedRows(offsets: outOffsets), inRows = _RowPool._packedRows(offsets: inOffsets)
        out = _RowPool(storage: outStorage, rows: outRows)
        outEdges = _RowPool(storage: outEdgeStorage, rows: outRows)
        self.in = _RowPool(storage: inStorage, rows: inRows)
        inEdges = _RowPool(storage: inEdgeStorage, rows: inRows)
        self.records = records
    }
}

/// The rows and records of an undirected graph on `0..<n` whose edge at position `p` is
/// `(us[p], vs[p])`, stored in that orientation, for `UndirectedAdjacencyList` and `Pseudograph`.
/// A self-loop takes two entries of its row, as an insertion appends it twice.
@frozen
@usableFromInline
package struct _EdgeRows {
    @usableFromInline package var neighbors: _RowPool
    @usableFromInline package var incident: _RowPool
    @usableFromInline package var records: ContiguousArray<_EdgeRecord>

    /// One counting sort over both ends, stable in position order (the `u` end before the `v`
    /// end). O(n + m).
    @inlinable
    package init(vertexCount n: Int, us: [Int], vs: [Int]) {
        let m = us.count
        var offsets = [Int](repeating: 0, count: n + 1)
        for p in 0 ..< m {
            offsets[us[p] &+ 1] &+= 1
            offsets[vs[p] &+ 1] &+= 1
        }
        for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
        var neighborStorage = ContiguousArray<Int>(repeating: 0, count: 2 &* m)
        var incidentStorage = ContiguousArray<Int>(repeating: 0, count: 2 &* m)
        var records = ContiguousArray<_EdgeRecord>()
        records.reserveCapacity(m)
        var fill = offsets
        neighborStorage.withUnsafeMutableBufferPointer { neighborStorage in
            incidentStorage.withUnsafeMutableBufferPointer { incidentStorage in
                for p in 0 ..< m {
                    let u = us[p], v = vs[p]
                    let uSlot = fill[u]
                    fill[u] = uSlot &+ 1
                    let vSlot = fill[v]
                    fill[v] = vSlot &+ 1
                    neighborStorage[uSlot] = v
                    incidentStorage[uSlot] = p
                    neighborStorage[vSlot] = u
                    incidentStorage[vSlot] = p
                    records.append(_EdgeRecord(u: u, v: v, uOffset: uSlot &- offsets[u], vOffset: vSlot &- offsets[v]))
                }
            }
        }
        let rows = _RowPool._packedRows(offsets: offsets)
        neighbors = _RowPool(storage: neighborStorage, rows: rows)
        incident = _RowPool(storage: incidentStorage, rows: rows)
        self.records = records
    }
}

/// For each pair `(firsts[i], seconds[i])` (unordered when `undirected`), the index of the first
/// pair equal to it: `i` itself for a first copy. A stable counting sort on one end, then a stamp per
/// other end within each row, so no pair is hashed. O(n + m).
@inlinable
package func _firstCopies(_ firsts: [Int], _ seconds: [Int], vertexCount n: Int, undirected: Bool) -> [Int] {
    let m = firsts.count
    var offsets = [Int](repeating: 0, count: n &+ 1)
    var order = [Int](repeating: 0, count: m)
    var group = [Int](repeating: 0, count: m)
    offsets.withUnsafeMutableBufferPointer { offsets in
        order.withUnsafeMutableBufferPointer { order in
            group.withUnsafeMutableBufferPointer { group in
                firsts.withUnsafeBufferPointer { firsts in
                    seconds.withUnsafeBufferPointer { seconds in
                        for i in 0 ..< m {
                            let a = undirected ? min(firsts[i], seconds[i]) : firsts[i]
                            offsets[a &+ 1] &+= 1
                        }
                        for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }
                        var fill = Array(offsets[0 ..< n])
                        fill.withUnsafeMutableBufferPointer { fill in
                            for i in 0 ..< m {
                                let a = undirected ? min(firsts[i], seconds[i]) : firsts[i]
                                order[fill[a]] = i
                                fill[a] &+= 1
                            }
                        }
                        var stamp = [Int](repeating: -1, count: n)
                        var first = [Int](repeating: 0, count: n)
                        stamp.withUnsafeMutableBufferPointer { stamp in
                            first.withUnsafeMutableBufferPointer { first in
                                for a in 0 ..< n {
                                    for k in offsets[a] ..< offsets[a &+ 1] {
                                        let i = order[k]
                                        let b = undirected ? max(firsts[i], seconds[i]) : seconds[i]
                                        if stamp[b] != a {
                                            stamp[b] = a
                                            first[b] = i
                                            group[i] = i
                                        } else {
                                            group[i] = first[b]
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return group
}

/// The pairs with repeats dropped (`_firstCopies`): the kept pairs in order of first appearance,
/// and each input pair's kept number.
@inlinable
package func _keptPairs(
    _ firsts: [Int], _ seconds: [Int], vertexCount n: Int, undirected: Bool
) -> (firsts: [Int], seconds: [Int], positions: [Int]) {
    let group = _firstCopies(firsts, seconds, vertexCount: n, undirected: undirected)
    let m = firsts.count
    var keptFirsts: [Int] = [], keptSeconds: [Int] = []
    keptFirsts.reserveCapacity(m)
    keptSeconds.reserveCapacity(m)
    var positions = [Int](repeating: 0, count: m)
    for i in 0 ..< m {
        let g = group[i]
        if g == i {
            positions[i] = keptFirsts.count
            keptFirsts.append(firsts[i])
            keptSeconds.append(seconds[i])
        } else {
            positions[i] = positions[g]
        }
    }
    return (keptFirsts, keptSeconds, positions)
}

/// The slot table for `vertices`, each at its index: identity while they are `0..<n` in order.
@inlinable
package func _vertexSlots<Vertex: Hashable>(of vertices: ContiguousArray<Vertex>) -> _VertexSlots<Vertex> {
    var slots = _VertexSlots<Vertex>()
    slots.reserveCapacity(vertices.count)
    for (slot, vertex) in vertices.enumerated() { slots[vertex] = slot }
    precondition((slots._isIdentity ? slots._identityCount : slots._table.count) == vertices.count, "Repeated vertex")
    return slots
}

/// Vertices numbered into slots in order of first appearance, and edges as pairs of slots in
/// order, as inserting them one at a time would number them: the input of the bulk initializers,
/// which lay the rows out once at the end.
@frozen
@usableFromInline
package struct _SlotPairs<Vertex: Hashable> {
    @usableFromInline package var vertices: ContiguousArray<Vertex>
    @usableFromInline package var slots: _VertexSlots<Vertex>
    @usableFromInline package var firsts: [Int]
    @usableFromInline package var seconds: [Int]

    /// No vertices and no pairs, with room for `pairCount` pairs.
    @inlinable
    package init(reservingPairs pairCount: Int) {
        vertices = []
        slots = _VertexSlots()
        firsts = []
        seconds = []
        firsts.reserveCapacity(pairCount)
        seconds.reserveCapacity(pairCount)
    }

    /// The slot of `vertex`, numbering it next if it has none. Returns whether it was new.
    @inlinable
    @discardableResult
    package mutating func insert(_ vertex: Vertex) -> (inserted: Bool, slot: Int) {
        if let slot = slots[vertex] { return (false, slot) }
        let slot = vertices.count
        vertices.append(vertex)
        slots[vertex] = slot
        return (true, slot)
    }

    /// Appends the pair `(first, second)`, numbering `first` and then `second` if they are new.
    @inlinable
    package mutating func append(_ first: Vertex, _ second: Vertex) {
        let a = insert(first).slot
        let b = insert(second).slot
        firsts.append(a)
        seconds.append(b)
    }
}

extension AdjacencyList {
    /// The graph on `vertices` (slot `i` holds `vertices[i]`, and `slots` maps them back) with the
    /// edges `sources[p] → targets[p]` at positions `p`, which must be distinct pairs of slots in
    /// range: unchecked. Every row at its exact size, in slot order. O(n + m); the pair table is
    /// built on the first lookup.
    @inlinable
    internal init(_vertices vertices: ContiguousArray<Vertex>, slots: _VertexSlots<Vertex>, distinctSources sources: [Int], targets: [Int]) {
        let rows = _ArcRows(vertexCount: vertices.count, sources: sources, targets: targets)
        self.init()
        _slots = slots
        _vertices = vertices
        _out = _PairedRowPool(storage: rows.out.storage, positions: rows.outEdges.storage, rows: rows.out.rows)
        _in = _PairedRowPool(storage: rows.in.storage, positions: rows.inEdges.storage, rows: rows.in.rows)
        _records = rows.records
        _deferredEdges = rows.records.isEmpty ? nil : _DeferredSlotPairTable(records: rows.records)
        _generation.stamp()
    }

    /// The graph `pairs` numbers, repeated pairs dropped (`_keptPairs`), each kept pair at the
    /// position of its first appearance: the graph that inserting the pairs in order builds, with
    /// its rows packed. O(n + m).
    @inlinable
    internal init(_pairs pairs: _SlotPairs<Vertex>) {
        let kept = _keptPairs(pairs.firsts, pairs.seconds, vertexCount: pairs.vertices.count, undirected: false)
        self.init(_vertices: pairs.vertices, slots: pairs.slots, distinctSources: kept.firsts, targets: kept.seconds)
    }

    /// See `MutableDirectedGraph._built`: repeated pairs dropped by counting sort, then the rows by
    /// counting sort. O(n + m) expected.
    @inlinable
    public static func _built(
        vertices: ContiguousArray<Vertex>, sourceKeys: [Int], targetKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Int]) {
        precondition(sourceKeys.count == targetKeys.count, "Unpaired keys")
        let n = vertices.count
        precondition(sourceKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) } && targetKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) },
                     "Key out of range")
        // Repeats found by counting sort, without hashing; the pair table is built on the first
        // lookup (`_DeferredSlotPairTable`), as for the sorted bulk builds.
        let kept = _keptPairs(sourceKeys, targetKeys, vertexCount: n, undirected: false)
        let graph = Self(_vertices: vertices, slots: _vertexSlots(of: vertices), distinctSources: kept.firsts, targets: kept.seconds)
        return (graph, reportingPositions ? kept.positions : [])
    }
}

extension UndirectedAdjacencyList {
    /// The graph on `vertices` (slot `i` holds `vertices[i]`, and `slots` maps them back) with the
    /// edges `{us[p], vs[p]}` at positions `p`, stored in that orientation, which must be distinct
    /// unordered pairs of slots in range: unchecked. Every row at its exact size, in slot order.
    /// O(n + m) expected.
    @inlinable
    internal init(_vertices vertices: ContiguousArray<Vertex>, slots: _VertexSlots<Vertex>, distinctUs us: [Int], vs: [Int]) {
        let rows = _EdgeRows(vertexCount: vertices.count, us: us, vs: vs)
        self.init()
        _slots = slots
        _vertices = vertices
        _neighbors = _PairedRowPool(storage: rows.neighbors.storage, positions: rows.incident.storage, rows: rows.neighbors.rows)
        _records = rows.records
        _positions._insertDistinct(count: us.count) { (us[$0] <= vs[$0] ? _SlotPair(us[$0], vs[$0]) : _SlotPair(vs[$0], us[$0]), $0) }
        _generation.stamp()
    }

    /// The graph `pairs` numbers, repeated pairs (in either orientation) dropped, each kept edge at
    /// the position and in the orientation of its first appearance: the graph that inserting the
    /// pairs in order builds, with its rows packed. O(n + m) expected.
    @inlinable
    internal init(_pairs pairs: _SlotPairs<Vertex>) {
        let kept = _keptPairs(pairs.firsts, pairs.seconds, vertexCount: pairs.vertices.count, undirected: true)
        self.init(_vertices: pairs.vertices, slots: pairs.slots, distinctUs: kept.firsts, vs: kept.seconds)
    }

    /// See `MutableGraph._built`: repeated pairs (in either orientation) dropped by counting sort,
    /// each kept edge in its first orientation, then the rows by counting sort. O(n + m) expected.
    @inlinable
    public static func _built(
        vertices: ContiguousArray<Vertex>, uKeys: [Int], vKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Int]) {
        precondition(uKeys.count == vKeys.count, "Unpaired keys")
        let n = vertices.count
        precondition(uKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) } && vKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) },
                     "Key out of range")
        let kept = _keptPairs(uKeys, vKeys, vertexCount: n, undirected: true)
        let graph = Self(_vertices: vertices, slots: _vertexSlots(of: vertices), distinctUs: kept.firsts, vs: kept.seconds)
        return (graph, reportingPositions ? kept.positions : [])
    }
}
