import AdjacencyListModule
import GraphProtocols

/// A directed graph whose adjacency rows stay packed in slot order, with spare cells between
/// them: a packed compressed sparse row graph (Wheatman and Xu's PCSR).
///
/// The vertex set is any set of `Hashable` values. The edge set is a set of ordered pairs of
/// vertices: self-loops are allowed, parallel edges are not. Vertices are kept in dense slots with
/// a dictionary from vertex to slot (none while the vertices are the `Int`s `0..<n` in order), and
/// edges in an array, so an edge's position in `edges` is an `Int` in `0..<edgeCount`. A value
/// per edge or vertex lives in a map attached to the graph (`addEdgeMap(default:)`,
/// `PropertyGraph`), which every mutation keeps in step.
///
/// Each slot has a row of the slots of its out-neighbors with the edges' positions beside them,
/// and a row of its in-neighbors. The rows of each kind share one storage as a packed memory array:
/// row by row in slot order, each row contiguous and followed by its spare cells. A walk over the
/// rows in slot order therefore reads the storage once, forward, as it would compressed sparse
/// rows, however the graph was built or changed. An insertion into a row with no spare cell lays
/// out again the smallest window of cells around it whose density stays under a threshold, so an
/// insertion moves O(log² n) cells amortized; removals halve the storage when it is mostly spare.
/// A hash table from slot pair to position answers `contains(edge:)` in O(1) expected.
///
/// Removing an edge is O(1) plus the rebalance: the last edge moves into its position, and the
/// last entry of each row into the hole. Removing a vertex costs O(degree) plus moving the last
/// slot's rows into its place. Vertex order, edge order and edge positions are therefore
/// unspecified and may change after a removal, as for `AdjacencyList`; spare cells never change
/// positions. The bulk initializers lay the rows out packed, with no spare cells, and the first
/// insertion spreads them.
///
/// Use it where a graph is both walked and changed: `AdjacencyList` walks slower once its rows
/// have grown out of place, and `CompressedSparseRow` cannot change.
@frozen
public struct PackedCompressedSparseRow<Vertex: Hashable> {
    /// The vertex in each slot.
    @usableFromInline
    internal var _vertices: ContiguousArray<Vertex>

    /// The slot of each vertex.
    @usableFromInline
    internal var _slots: _VertexSlots<Vertex>

    /// For each slot, its out-neighbors' slots and those edges' positions, packed in slot order.
    @usableFromInline
    internal var _out: _PackedRowPool

    /// For each slot, its in-neighbors' slots and those edges' positions, packed in slot order.
    @usableFromInline
    internal var _in: _PackedRowPool

    /// Every edge, at its position: its slots, and its offsets in its source's out-row and its
    /// target's in-row.
    @usableFromInline
    internal var _records: ContiguousArray<_ArcRecord>

    /// The position of each edge, keyed by its pair of slots. Empty while `_deferredEdges` holds
    /// the table instead.
    @usableFromInline
    internal var _edges: _SlotPairTable<Int>

    /// After a bulk build, the pair table to build on the first lookup; `nil` once the graph has
    /// its own.
    @usableFromInline
    internal var _deferredEdges: _DeferredSlotPairTable?

    /// The attached vertex maps, one value per slot, moved with the slots.
    @usableFromInline
    internal var _vertexMaps: _AttachedMaps

    /// The attached edge maps, one value per edge position, moved with the edges.
    @usableFromInline
    internal var _edgeMaps: _AttachedMaps

    /// The generation, advanced by every structural mutation, each of which writes the out-row
    /// table.
    @usableFromInline
    internal var _generation: _GenerationStamp

    /// The empty graph.
    @inlinable
    public init() {
        _vertices = []
        _slots = _VertexSlots()
        _out = _PackedRowPool()
        _in = _PackedRowPool()
        _records = []
        _edges = _SlotPairTable()
        _deferredEdges = nil
        _vertexMaps = _AttachedMaps()
        _edgeMaps = _AttachedMaps()
        _generation = _GenerationStamp()
    }

    @inlinable
    internal func _position(ofPair pair: _SlotPair) -> Int? {
        guard let deferred = _deferredEdges else { return _edges[pair] }
        return deferred.table().table[pair]
    }

    @inlinable
    @inline(__always)
    internal mutating func _takeEdgeTable() {
        guard let deferred = _deferredEdges else { return }
        _edges = deferred.builtTable ?? _DeferredSlotPairTable.makeTable(_records)
        _deferredEdges = nil
    }

    /// The graph with packed rows from a bulk build.
    @inlinable
    internal init(_vertices vertices: ContiguousArray<Vertex>, slots: _VertexSlots<Vertex>, rows: _ArcRows) {
        self.init()
        _vertices = vertices
        _slots = slots
        _out = _PackedRowPool(packedTargets: rows.out.storage, positions: rows.outEdges.storage, rows: rows.out.rows)
        _in = _PackedRowPool(packedTargets: rows.in.storage, positions: rows.inEdges.storage, rows: rows.in.rows)
        _records = rows.records
        _deferredEdges = rows.records.isEmpty ? nil : _DeferredSlotPairTable(records: rows.records)
        _generation.stamp()
    }

    @inlinable
    internal init(_vertices vertices: ContiguousArray<Vertex>, slots: _VertexSlots<Vertex>, sortedRows rows: _SortedArcRows) {
        self.init()
        _vertices = vertices
        _slots = slots
        _out = _PackedRowPool(packedTargets: rows.out.storage, positions: rows.outEdges.storage, rows: rows.out.rows)
        _in = _PackedRowPool(packedTargets: rows.in.storage, positions: rows.inEdges.storage, rows: rows.in.rows)
        _records = rows.records
        _deferredEdges = rows.records.isEmpty ? nil : _DeferredSlotPairTable(records: rows.records)
        _generation.stamp()
    }

    @inlinable
    internal init(_vertices vertices: ContiguousArray<Vertex>, slots: _VertexSlots<Vertex>, distinctSources sources: [Int], targets: [Int]) {
        self.init(_vertices: vertices, slots: slots, rows: _ArcRows(vertexCount: vertices.count, sources: sources, targets: targets))
    }

    @inlinable
    internal init(_pairs pairs: _SlotPairs<Vertex>) {
        let kept = _keptPairs(pairs.firsts, pairs.seconds, vertexCount: pairs.vertices.count, undirected: false)
        self.init(_vertices: pairs.vertices, slots: pairs.slots, distinctSources: kept.firsts, targets: kept.seconds)
    }
}

// MARK: - Construction

extension PackedCompressedSparseRow {
    /// A graph with these vertices and no edges.
    @inlinable
    public init(vertices: some Sequence<Vertex>) {
        self.init()
        for v in vertices { insert(v) }
    }

    /// A graph with these edges, and their endpoints as vertices. Repeated edges are one edge.
    @inlinable
    public init(edges: some Sequence<DirectedEdge<Vertex>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// A graph with these vertices and edges; an edge's endpoints are added as vertices too.
    /// Repeated vertices and edges are one each. The rows are laid out packed in slot order.
    @inlinable
    public init(vertices: some Sequence<Vertex>, edges: some Sequence<DirectedEdge<Vertex>>) {
        var pairs = _SlotPairs<Vertex>(reservingPairs: edges.underestimatedCount)
        for v in vertices { pairs.insert(v) }
        for edge in edges { pairs.append(edge.source, edge.target) }
        self.init(_pairs: pairs)
    }

    /// A graph from each vertex's out-neighbors.
    @inlinable
    public init<Neighbors: Sequence<Vertex>>(adjacency: [Vertex: Neighbors]) {
        var pairs = _SlotPairs<Vertex>(reservingPairs: adjacency.count)
        for (source, targets) in adjacency {
            pairs.insert(source)
            for target in targets { pairs.append(source, target) }
        }
        self.init(_pairs: pairs)
    }

    /// A graph from a builder of vertices and edges.
    @inlinable
    public init(@DirectedGraphBuilder<Vertex> _ content: () -> DirectedGraphBuilder<Vertex>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// Any directed graph, copied: its vertices in order, its edges in position order.
    @inlinable
    public init(_ graph: some DirectedGraph<Vertex>) {
        if let same = graph as? PackedCompressedSparseRow {
            self = same
            return
        }
        var pairs = _SlotPairs<Vertex>(reservingPairs: graph.edgeCount)
        pairs.slots.reserveCapacity(graph.vertexCount)
        for v in graph.vertices { pairs.insert(v) }
        for edge in graph.edges { pairs.append(edge.source, edge.target) }
        self.init(_pairs: pairs)
    }
}

extension PackedCompressedSparseRow: ExpressibleByDictionaryLiteral {
    /// A graph from each vertex's out-neighbors; a repeated key traps.
    @inlinable
    public init(dictionaryLiteral elements: (Vertex, [Vertex])...) {
        var pairs = _SlotPairs<Vertex>(reservingPairs: elements.count)
        var keys = Set<Vertex>(minimumCapacity: elements.count)
        for (source, targets) in elements {
            precondition(keys.insert(source).inserted, "Dictionary literal of PackedCompressedSparseRow contains duplicate key \(source)")
            pairs.insert(source)
            for target in targets { pairs.append(source, target) }
        }
        self.init(_pairs: pairs)
    }
}

extension PackedCompressedSparseRow where Vertex == Int {
    /// The graph on `0..<n` with these edges, which are sorted row-major, simple and in range;
    /// the rows are laid out packed.
    @inlinable
    package init(_uncheckedVertexCount n: Int, sortedEdges edges: some Collection<DirectedEdge<Int>>) {
        self.init(_vertices: ContiguousArray(0 ..< n), slots: _VertexSlots(identityCount: n), sortedRows: _SortedArcRows(vertexCount: n, sortedEdges: edges))
    }
}

extension PackedCompressedSparseRow: _DirectedGraphConstruction where Vertex == Int {
    @inlinable
    public init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken) {
        assert(_isSortedSimple(vertexCount: _vertexCount, sortedEdges), "unsorted, repeated or out-of-range edges")
        self.init(_uncheckedVertexCount: _vertexCount, sortedEdges: sortedEdges)
    }
}

// MARK: - Queries

extension PackedCompressedSparseRow {
    /// The number of vertices.
    @inlinable
    public var vertexCount: Int { _vertices.count }

    /// The number of edges.
    @inlinable
    public var edgeCount: Int { _records.count }

    /// Whether `vertex` is a vertex. O(1) expected.
    @inlinable
    public func contains(_ vertex: Vertex) -> Bool { _slots[vertex] != nil }

    /// Whether `edge` is an edge. O(1) expected.
    @inlinable
    public func contains(edge: DirectedEdge<Vertex>) -> Bool {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return false }
        return _position(ofPair: _SlotPair(source, target)) != nil
    }

    /// The position of the edge from `source` to `target`, as a collection of at most one. O(1)
    /// expected; empty when either is not a vertex.
    @inlinable
    public func edges(from source: Vertex, to target: Vertex) -> EdgesConnecting {
        guard let s = _slots[source], let t = _slots[target], let position = _position(ofPair: _SlotPair(s, t)) else { return EdgesConnecting(position: -1) }
        return EdgesConnecting(position: position)
    }

    /// The out-neighbors of `vertex`, in the order their edges were inserted until a removal.
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func successors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _out.targetRow(_slot(of: vertex)))
    }

    /// The in-neighbors of `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex.
    @inlinable
    public func predecessors(of vertex: Vertex) -> Neighbors {
        Neighbors(vertices: _vertices, slots: _in.targetRow(_slot(of: vertex)))
    }

    /// The number of edges leaving `vertex`. O(1).
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int { _out.count(ofRow: _slot(of: vertex)) }

    /// The number of edges entering `vertex`. O(1).
    @inlinable
    public func inDegree(of vertex: Vertex) -> Int { _in.count(ofRow: _slot(of: vertex)) }

    /// `outDegree(of:) + inDegree(of:)`; a self-loop counts twice. O(1).
    @inlinable
    public func degree(of vertex: Vertex) -> Int {
        let slot = _slot(of: vertex)
        return _out.count(ofRow: slot) + _in.count(ofRow: slot)
    }

    /// `successors(of:)`, throwing instead of trapping.
    @inlinable
    public func successors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return Neighbors(vertices: _vertices, slots: _out.targetRow(slot))
    }

    /// `predecessors(of:)`, throwing instead of trapping.
    @inlinable
    public func predecessors(checked vertex: Vertex) throws(VertexNotFound) -> Neighbors {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return Neighbors(vertices: _vertices, slots: _in.targetRow(slot))
    }

    /// `outEdges(of:)`, throwing instead of trapping.
    @inlinable
    public func outEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _out.positionRow(slot)
    }

    /// `inEdges(of:)`, throwing instead of trapping.
    @inlinable
    public func inEdges(checked vertex: Vertex) throws(VertexNotFound) -> ArraySlice<Int> {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _in.positionRow(slot)
    }

    /// `outDegree(of:)`, throwing instead of trapping.
    @inlinable
    public func outDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _out.count(ofRow: slot)
    }

    /// `inDegree(of:)`, throwing instead of trapping.
    @inlinable
    public func inDegree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _in.count(ofRow: slot)
    }

    /// `degree(of:)`, throwing instead of trapping.
    @inlinable
    public func degree(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return _out.count(ofRow: slot) + _in.count(ofRow: slot)
    }

    /// `vertexIndex(of:)`, throwing instead of trapping.
    @inlinable
    public func vertexIndex(checked vertex: Vertex) throws(VertexNotFound) -> Int {
        guard let slot = _slots[vertex] else { throw VertexNotFound() }
        return slot
    }

    /// `source(ofEdgeAt:)`, throwing instead of trapping.
    @inlinable
    public func source(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex {
        guard UInt(bitPattern: position) < UInt(bitPattern: _records.count) else { throw EdgeNotFound() }
        return _vertices[_records[position].source]
    }

    /// `target(ofEdgeAt:)`, throwing instead of trapping.
    @inlinable
    public func target(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Vertex {
        guard UInt(bitPattern: position) < UInt(bitPattern: _records.count) else { throw EdgeNotFound() }
        return _vertices[_records[position].target]
    }

    @inlinable
    @inline(__always)
    internal func _slot(of vertex: Vertex) -> Int {
        guard let slot = _slots[vertex] else { preconditionFailure("\(vertex) is not a vertex of this graph") }
        return slot
    }
}

// MARK: - Mutation

extension PackedCompressedSparseRow {
    /// Inserts `vertex` if it is not a vertex already. O(1) expected, amortized.
    @inlinable
    @discardableResult
    public mutating func insert(_ vertex: Vertex) -> (inserted: Bool, memberAfterInsert: Vertex) {
        if let slot = _slots[vertex] { return (false, _vertices[slot]) }
        _appendSlot(for: vertex)
        return (true, vertex)
    }

    /// Inserts `edge`, and its endpoints as vertices if they are not vertices already. An edge
    /// already present is not inserted again. O(log² n) cells moved amortized, plus O(1) expected
    /// for the hashes.
    @inlinable
    @discardableResult
    public mutating func insert(edge: DirectedEdge<Vertex>) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Vertex>) {
        let source = _slots[edge.source] ?? _appendSlot(for: edge.source)
        let target = _slots[edge.target] ?? _appendSlot(for: edge.target)
        let member = DirectedEdge(from: _vertices[source], to: _vertices[target])
        let count = _records.count
        return (_insertEdge(slots: source, target) == count, member)
    }

    /// Inserts `edge` between two vertices, throwing when either is not a vertex.
    @inlinable
    @discardableResult
    public mutating func insert(checked edge: DirectedEdge<Vertex>) throws(VertexNotFound) -> (inserted: Bool, memberAfterInsert: DirectedEdge<Vertex>) {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { throw VertexNotFound() }
        let member = DirectedEdge(from: _vertices[source], to: _vertices[target])
        let count = _records.count
        return (_insertEdge(slots: source, target) == count, member)
    }

    @inlinable
    @discardableResult
    internal mutating func _insertEdge(slots source: Int, _ target: Int) -> Int {
        let pair = _SlotPair(source, target)
        if let existing = _position(ofPair: pair) { return existing }
        _takeEdgeTable()
        let position = _records.count
        let out = _out.append(target: target, position: position, toRow: source)
        _generation.advance(writing: _out.rows)
        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaultsToOwnTable(count: 1) }
        let into = _in.append(target: source, position: position, toRow: target)
        _records.append(_ArcRecord(source: source, target: target, out: out, in: into))
        _edges.insert(pair, position)
        return position
    }

    /// Removes `vertex` and every edge at it, returning it, or nil if it was not a vertex. The last
    /// slot moves into its place. O(degree) plus the cells moved.
    @inlinable
    @discardableResult
    public mutating func remove(_ vertex: Vertex) -> Vertex? {
        guard let slot = _slots[vertex] else { return nil }
        return _removeSlot(slot)
    }

    @inlinable
    internal mutating func _removeSlot(_ slot: Int) -> Vertex {
        let removed = _vertices[slot]
        _takeEdgeTable()
        if !_vertexMaps.isEmpty { _vertexMaps.swapRemove(at: slot) }
        while let position = _out.lastPosition(ofRow: slot) { _detach(position) }
        while let position = _in.lastPosition(ofRow: slot) { _detach(position) }
        // Move the last slot into the hole, renaming it in its edges' records and keys, and in the
        // row entries that name it.
        let last = _vertices.count - 1
        if slot != last {
            let moved = _vertices[last]
            var renamed: [Int] = []
            for position in _out.positionRow(last) { renamed.append(position) }
            for position in _in.positionRow(last) where _records[position].source != last { renamed.append(position) }
            for position in renamed {
                var record = _records[position]
                _edges.removeValue(forKey: record.pair)
                if record.source == last {
                    _in[target: record.target, record.in] = slot
                    record.source = slot
                }
                if record.target == last {
                    _out[target: record.source == slot ? last : record.source, record.out] = slot
                    record.target = slot
                }
                _records[position] = record
                _edges.insert(record.pair, position)
            }
            _vertices.swapAt(slot, last)
            _slots[moved] = slot
        }
        _vertices.removeLast()
        _out.moveLastRow(into: slot)
        _in.moveLastRow(into: slot)
        _slots.removeValue(forKey: removed)
        _generation.advance(writing: _out.rows)
        return removed
    }

    /// Removes `edge`, returning it, or nil if it was not an edge. The last edge moves into its
    /// position. O(1) expected, plus the cells moved when the storage shrinks.
    @inlinable
    @discardableResult
    public mutating func remove(edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex>? {
        guard let source = _slots[edge.source], let target = _slots[edge.target] else { return nil }
        guard let position = _position(ofPair: _SlotPair(source, target)) else { return nil }
        _detachFromRows(position)
        _generation.advance(writing: _out.rows)
        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }
        return DirectedEdge(from: _vertices[source], to: _vertices[target])
    }

    @inlinable
    internal mutating func _detach(_ position: Int) {
        if !_edgeMaps.isEmpty { _edgeMaps.swapRemove(at: position) }
        _detachFromRows(position)
    }

    @inlinable
    internal mutating func _detachFromRows(_ position: Int) {
        _takeEdgeTable()
        let record = _records[position]
        _edges.removeValue(forKey: record.pair)
        let movedOut = _out.swapRemove(at: record.out, fromRow: record.source)
        let movedIn = _in.swapRemove(at: record.in, fromRow: record.target)
        let last = _records.count - 1
        let moved: _ArcRecord? = _records.withUnsafeMutableBufferPointer { records in
            if let movedOut { records[movedOut.position].out = record.out }
            if let movedIn { records[movedIn.position].in = record.in }
            guard position != last else { return nil }
            records[position] = records[last]
            return records[position]
        }
        if let moved {
            _out[position: moved.source, moved.out] = position
            _in[position: moved.target, moved.in] = position
            _edges.updateValue(position, forKey: moved.pair)
        }
        _records.removeLast()
    }

    /// Removes every vertex and edge.
    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        let changes = !_vertices.isEmpty
        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _vertices.removeAll(keepingCapacity: keepingCapacity)
        _slots.removeAll(keepingCapacity: keepingCapacity)
        _out.removeAll(keepingCapacity: keepingCapacity)
        _in.removeAll(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _deferredEdges = nil
        _edges.removeAll(keepingCapacity: keepingCapacity)
        if changes { _generation.advance(writing: _out.rows) } else { _generation.storageMayHaveMoved(_out.rows) }
    }

    /// Removes every edge, keeping the vertices.
    @inlinable
    public mutating func removeAllEdges(keepingCapacity: Bool = false) {
        guard !_records.isEmpty else { return }
        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }
        _out.removeAllEntries(keepingCapacity: keepingCapacity)
        _generation.advance(writing: _out.rows)
        _in.removeAllEntries(keepingCapacity: keepingCapacity)
        _records.removeAll(keepingCapacity: keepingCapacity)
        _deferredEdges = nil
        _edges.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Reserves room for `vertexCount` vertices and `edgeCount` edges.
    @inlinable
    public mutating func reserveCapacity(vertexCount: Int, edgeCount: Int) {
        precondition(vertexCount >= 0, "Negative vertex count")
        precondition(edgeCount >= 0, "Negative edge count")
        if !_vertexMaps.isEmpty { _vertexMaps.reserveCapacity(vertexCount) }
        if !_edgeMaps.isEmpty { _edgeMaps.reserveCapacity(edgeCount) }
        _vertices.reserveCapacity(vertexCount)
        _slots.reserveCapacity(vertexCount)
        _out.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _generation.storageMayHaveMoved(_out.rows)
        _in.reserveCapacity(rows: vertexCount, entries: edgeCount)
        _records.reserveCapacity(edgeCount)
        _takeEdgeTable()
        _edges.reserveCapacity(edgeCount)
    }

    @inlinable
    @discardableResult
    internal mutating func _appendSlot(for vertex: Vertex) -> Int {
        let slot = _vertices.count
        _vertices.append(vertex)
        _slots[vertex] = slot
        _out.appendRow()
        _generation.advance(writing: _out.rows)
        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaultsToOwnTable(count: 1) }
        _in.appendRow()
        return slot
    }
}

// MARK: - Views

extension PackedCompressedSparseRow {
    /// The vertices, in slot order.
    @inlinable
    public var vertices: Vertices { Vertices(base: _vertices) }

    /// The edges, in position order.
    @inlinable
    public var edges: Edges { Edges(vertices: _vertices, records: _records) }

    /// The vertices of a graph, in slot order.
    @frozen
    public struct Vertices: RandomAccessCollection {
        @usableFromInline let base: ContiguousArray<Vertex>

        @inlinable
        init(base: ContiguousArray<Vertex>) { self.base = base }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { base.count }
        @inlinable public subscript(position: Int) -> Vertex { base[position] }
    }

    /// The out- or in-neighbors of a vertex.
    @frozen
    public struct Neighbors: RandomAccessCollection {
        @usableFromInline let vertices: ContiguousArray<Vertex>
        @usableFromInline let slots: ArraySlice<Int>

        @inlinable
        init(vertices: ContiguousArray<Vertex>, slots: ArraySlice<Int>) {
            self.vertices = vertices
            self.slots = slots
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { slots.count }

        @inlinable
        public subscript(position: Int) -> Vertex {
            precondition(position >= 0 && position < slots.count, "Index out of range")
            return vertices[slots[slots.startIndex &+ position]]
        }
    }

    /// The edges of a graph, in position order.
    @frozen
    public struct Edges: RandomAccessCollection {
        @usableFromInline let vertices: ContiguousArray<Vertex>
        @usableFromInline let records: ContiguousArray<_ArcRecord>

        @inlinable
        init(vertices: ContiguousArray<Vertex>, records: ContiguousArray<_ArcRecord>) {
            self.vertices = vertices
            self.records = records
        }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { records.count }

        @inlinable
        public subscript(position: Int) -> DirectedEdge<Vertex> {
            let record = records[position]
            return DirectedEdge(from: vertices[record.source], to: vertices[record.target])
        }
    }

    /// The positions of the edges from one vertex to another: at most one.
    @frozen
    public struct EdgesConnecting: RandomAccessCollection {
        @usableFromInline let position: Int

        @inlinable
        init(position: Int) { self.position = position }

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { position >= 0 ? 1 : 0 }

        @inlinable
        public subscript(index: Int) -> Int {
            precondition(index == 0 && position >= 0, "Index out of range")
            return position
        }
    }
}

// MARK: - Equatable and Hashable

extension PackedCompressedSparseRow: Equatable {
    /// Equal when the vertex sets and the edge sets are equal, whatever the slots and positions.
    @inlinable
    public static func == (lhs: PackedCompressedSparseRow, rhs: PackedCompressedSparseRow) -> Bool {
        guard lhs.vertexCount == rhs.vertexCount, lhs.edgeCount == rhs.edgeCount else { return false }
        if lhs._vertices == rhs._vertices {
            for record in lhs._records where rhs._position(ofPair: record.pair) == nil { return false }
            return true
        }
        for v in lhs._vertices where rhs._slots[v] == nil { return false }
        for record in lhs._records {
            guard let source = rhs._slots[lhs._vertices[record.source]],
                  let target = rhs._slots[lhs._vertices[record.target]],
                  rhs._position(ofPair: _SlotPair(source, target)) != nil
            else { return false }
        }
        return true
    }
}

extension PackedCompressedSparseRow: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        var vertexHashes = 0
        for v in _vertices {
            var h = Hasher()
            h.combine(v)
            vertexHashes &+= h.finalize()
        }
        var edgeHashes = 0
        for record in _records {
            var h = Hasher()
            h.combine(_vertices[record.source])
            h.combine(_vertices[record.target])
            edgeHashes &+= h.finalize()
        }
        hasher.combine(vertexCount)
        hasher.combine(edgeCount)
        hasher.combine(vertexHashes)
        hasher.combine(edgeHashes)
    }
}

extension PackedCompressedSparseRow: Sendable where Vertex: Sendable {}
extension PackedCompressedSparseRow.Vertices: Sendable where Vertex: Sendable {}
extension PackedCompressedSparseRow.Neighbors: Sendable where Vertex: Sendable {}
extension PackedCompressedSparseRow.Edges: Sendable where Vertex: Sendable {}
extension PackedCompressedSparseRow.EdgesConnecting: Sendable {}

// MARK: - Codable

extension PackedCompressedSparseRow: Encodable where Vertex: Encodable {
    /// Encodes as `{"vertices": [...], "edges": [s0, t0, s1, t1, ...]}` with slots, as `AdjacencyList`.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(Array(_vertices), forKey: .vertices)
        var edges: [Int] = []
        edges.reserveCapacity(2 * _records.count)
        for record in _records {
            edges.append(record.source)
            edges.append(record.target)
        }
        try container.encode(edges, forKey: .edges)
    }
}

extension PackedCompressedSparseRow: Decodable where Vertex: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        let vertices = try container.decode([Vertex].self, forKey: .vertices)
        let edges = try container.decode([Int].self, forKey: .edges)
        guard edges.count.isMultiple(of: 2) else {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge list has odd length")
        }
        var pairs = _SlotPairs<Vertex>(reservingPairs: edges.count / 2)
        pairs.slots.reserveCapacity(vertices.count)
        for v in vertices {
            guard pairs.insert(v).inserted else {
                throw DecodingError.dataCorruptedError(forKey: .vertices, in: container, debugDescription: "Repeated vertex")
            }
        }
        for i in stride(from: 0, to: edges.count, by: 2) {
            guard vertices.indices.contains(edges[i]), vertices.indices.contains(edges[i + 1]) else {
                throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Edge endpoint out of range")
            }
            pairs.firsts.append(edges[i])
            pairs.seconds.append(edges[i + 1])
        }
        let firstCopies = _firstCopies(pairs.firsts, pairs.seconds, vertexCount: vertices.count, undirected: false)
        for (i, first) in firstCopies.enumerated() where first != i {
            throw DecodingError.dataCorruptedError(forKey: .edges, in: container, debugDescription: "Repeated edge")
        }
        self.init(_vertices: pairs.vertices, slots: pairs.slots, distinctSources: pairs.firsts, targets: pairs.seconds)
    }
}

extension PackedCompressedSparseRow {
    @usableFromInline
    internal enum _CodingKeys: String, CodingKey {
        case vertices
        case edges
    }
}

// MARK: - Descriptions

extension PackedCompressedSparseRow: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        GraphDescription.graph(vertices: _vertices, vertexCount: vertexCount, edges: edges, edgeCount: edgeCount)
    }

    public var debugDescription: String {
        "PackedCompressedSparseRow<\(Vertex.self)>(vertexCount: \(vertexCount), edgeCount: \(edgeCount), vertices: "
            + GraphDescription.list(_vertices, count: vertexCount) { String(reflecting: $0) }
            + ", edges: "
            + GraphDescription.list(edges, count: edgeCount) { GraphDescription.edge($0) }
            + ")"
    }

    public var customMirror: Mirror {
        Mirror(self, children: ["vertices": Array(_vertices), "edges": Array(edges)], displayStyle: .struct)
    }
}

// MARK: - DirectedGraph

extension PackedCompressedSparseRow: BidirectionalDirectedGraph {
    @inlinable
    public var generation: GraphGeneration { _generation.generation }

    /// The positions of the edges leaving `vertex`, beside its successors.
    @inlinable
    public func outEdges(of vertex: Vertex) -> ArraySlice<Int> { _out.positionRow(_slot(of: vertex)) }

    /// The positions of the edges entering `vertex`, beside its predecessors.
    @inlinable
    public func inEdges(of vertex: Vertex) -> ArraySlice<Int> { _in.positionRow(_slot(of: vertex)) }

    @inlinable
    public func source(ofEdgeAt position: Int) -> Vertex { _vertices[_records[position].source] }

    @inlinable
    public func target(ofEdgeAt position: Int) -> Vertex { _vertices[_records[position].target] }

    @inlinable
    public var vertexIndexBound: Int? { _vertices.count }

    @inlinable
    public func vertexIndex(of vertex: Vertex) -> Int { _slot(of: vertex) }

    @inlinable
    public func vertex(atIndex index: Int) -> Vertex { _vertices[index] }

    @inlinable
    public func successorIndices(ofIndex index: Int) -> ArraySlice<Int> { _out.targetRow(index) }

    @inlinable
    public func predecessorIndices(ofIndex index: Int) -> ArraySlice<Int> { _in.targetRow(index) }

    @inlinable
    public func outEdges(ofIndex index: Int) -> ArraySlice<Int> { _out.positionRow(index) }

    @inlinable
    public func inEdges(ofIndex index: Int) -> ArraySlice<Int> { _in.positionRow(index) }

    @inlinable
    public func outDegree(ofIndex index: Int) -> Int { _out.count(ofRow: index) }

    @inlinable
    public func inDegree(ofIndex index: Int) -> Int { _in.count(ofRow: index) }

    @inlinable
    public func sourceIndex(ofEdgeAt position: Int) -> Int { _records[position].source }

    @inlinable
    public func targetIndex(ofEdgeAt position: Int) -> Int { _records[position].target }

    @inlinable
    public var edgeIndexBound: Int? { _records.count }

    @inlinable
    public func edgeIndex(of position: Int) -> Int { position }

    @inlinable
    public func _withOutIndexRows<Result>(
        _ body: (
            _ targets: UnsafeBufferPointer<Int>, _ targetRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result? {
        _out.withUnsafeRows { targets, rows, positions in body(targets, rows, positions, rows) }
    }
}

// MARK: - MutableDirectedGraph

extension PackedCompressedSparseRow: MutableDirectedGraph {
    @inlinable public func _key(of vertex: Vertex) -> Int? { _slots[vertex] }
    @inlinable public func _vertex(atKey key: Int) -> Vertex { _vertices[key] }
    @inlinable public func _successors(ofKey key: Int) -> Neighbors { Neighbors(vertices: _vertices, slots: _out.targetRow(key)) }
    @inlinable public func _predecessors(ofKey key: Int) -> Neighbors { Neighbors(vertices: _vertices, slots: _in.targetRow(key)) }
    @inlinable public func _successorKeys(ofKey key: Int) -> ArraySlice<Int> { _out.targetRow(key) }
    @inlinable public func _predecessorKeys(ofKey key: Int) -> ArraySlice<Int> { _in.targetRow(key) }
    @inlinable public func _outEdges(ofKey key: Int) -> ArraySlice<Int> { _out.positionRow(key) }
    @inlinable public func _inEdges(ofKey key: Int) -> ArraySlice<Int> { _in.positionRow(key) }
    @inlinable public func _outDegree(ofKey key: Int) -> Int { _out.count(ofRow: key) }
    @inlinable public func _inDegree(ofKey key: Int) -> Int { _in.count(ofRow: key) }
    @inlinable public func _sourceKey(ofEdgeAt position: Int) -> Int { _records[position].source }
    @inlinable public func _targetKey(ofEdgeAt position: Int) -> Int { _records[position].target }
    @inlinable public mutating func _insertVertex(_ vertex: Vertex) -> Int { _appendSlot(for: vertex) }

    @inlinable
    public mutating func _insertEdge(fromKey source: Int, toKey target: Int) -> Int { _insertEdge(slots: source, target) }

    @inlinable
    public mutating func _removeVertex(atKey key: Int) -> Int? {
        let last = _vertices.count - 1
        _ = _removeSlot(key)
        return key == last ? nil : last
    }

    @inlinable
    public mutating func _removeEdge(at position: Int) -> DirectedEdge<Vertex> {
        let record = _records[position]
        _detachFromRows(position)
        _generation.advance(writing: _out.rows)
        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }
        return DirectedEdge(from: _vertices[record.source], to: _vertices[record.target])
    }

    @inlinable
    public static func _built(
        vertices: ContiguousArray<Vertex>, sourceKeys: [Int], targetKeys: [Int], reportingPositions: Bool, _: _ConstructionToken
    ) -> (graph: Self, positions: [Int]) {
        precondition(sourceKeys.count == targetKeys.count, "Unpaired keys")
        let n = vertices.count
        precondition(sourceKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) } && targetKeys.allSatisfy { UInt(bitPattern: $0) < UInt(n) }, "Key out of range")
        let kept = _keptPairs(sourceKeys, targetKeys, vertexCount: n, undirected: false)
        let graph = Self(_vertices: vertices, slots: _vertexSlots(of: vertices), distinctSources: kept.firsts, targets: kept.seconds)
        return (graph, reportingPositions ? kept.positions : [])
    }
}
