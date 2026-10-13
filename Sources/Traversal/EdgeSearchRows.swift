import GraphProtocols

/// The out-rows an edge search walks: for each vertex identifier, the position of each edge out
/// of it with the identifier of the vertex across, in the graph's order. Identifiers are dense
/// (`0..<count` in `vertices` order) when the graph has vertex indices or is numbered, and are
/// handed out as vertices are first seen otherwise.
@usableFromInline
package protocol _EdgeSearchRows {
    associatedtype Vertex: Hashable
    associatedtype Edge: Hashable
    /// The rest of one row.
    associatedtype Row

    /// Whether each edge is in the rows of both its ends (an undirected graph), so a search
    /// reports it from the end that reaches it first and skips it at the other.
    static var isUndirected: Bool { get }

    /// The number of identifiers when every vertex has one from the start; `nil` otherwise.
    var denseCount: Int? { get }

    /// Every vertex, in `vertices` order.
    var vertexList: [Vertex] { get }

    /// The identifier of `vertex`, handing out a new one if it has not been seen.
    mutating func identifier(of vertex: Vertex) -> Int

    /// The vertex whose identifier is `id`.
    func vertex(_ id: Int) -> Vertex

    /// Whether rows are read by slot, with `bounds(of:)` and `edge(atSlot:shift:)`, so a search
    /// keeps integer cursors; otherwise with `load`, `next(in:)` and `clear`.
    var readsBySlot: Bool { get }

    /// Whether rows can be read with `load`, `next(in:)` and `clear`: a breadth-first search,
    /// which has one row open at a time, reads them so when it can.
    var readsByIterator: Bool { get }

    /// The slots of `id`'s row, and the shift from a slot to its position's slot.
    ///
    /// - Precondition: `readsBySlot`.
    func bounds(of id: Int) -> (start: Int, end: Int, shift: Int)

    /// The edge in slot `k`, and the identifier across it.
    ///
    /// - Precondition: `readsBySlot`, and `k` is a slot of a row whose shift is `shift`.
    func edge(atSlot k: Int, shift: Int) -> (edge: Edge, target: Int)

    /// Sets `row` to the row of `id`, from its start, field by field: replacing the whole value
    /// would release the old one through its value witness.
    func load(_ row: inout Row, of id: Int)

    /// Empties `row`, for a vertex whose edges are not explored.
    func clear(_ row: inout Row)

    /// A row with nothing in it.
    static var emptyRow: Row { get }

    /// The next edge of `row` and the identifier across it, or `nil` at the end of the row.
    mutating func next(in row: inout Row) -> (edge: Edge, target: Int)?

    /// Calls `body` with the graph's rows as flat index-space buffers, with `Int` positions, and
    /// returns its result; `nil`, without calling `body`, when the graph does not lend them. The
    /// buffers are checked once, here, so `body` may read them unchecked.
    func withFlatRows<Result>(_ body: (_EdgeFlatRows) -> Result) -> Result?
}

/// A graph's rows as flat buffers in index space, read with integer cursors. Two layouts:
/// compressed (`table` holds `n + 1` offsets, as `_withSuccessorIndexRows` lends them) and pooled
/// (`table` and `edgeTable` hold three entries per vertex, start, length and one ignored, as
/// `_withOutIndexRows` and `_withIncidentIndexRows` lend them). Positions are the slots
/// themselves, or read from `edges` beside the targets.
@frozen
@usableFromInline
package struct _EdgeFlatRows {
    @usableFromInline let targets: UnsafeBufferPointer<Int>
    @usableFromInline let table: UnsafeBufferPointer<Int>
    @usableFromInline let edges: UnsafeBufferPointer<Int>
    @usableFromInline let edgeTable: UnsafeBufferPointer<Int>
    @usableFromInline let pooled: Bool
    /// Whether positions are read from `edges`; otherwise slot `k` is position `k`.
    @usableFromInline let readsPositions: Bool

    @inlinable
    init(targets: UnsafeBufferPointer<Int>, table: UnsafeBufferPointer<Int>, edges: UnsafeBufferPointer<Int>, edgeTable: UnsafeBufferPointer<Int>, pooled: Bool, readsPositions: Bool) {
        self.targets = targets
        self.table = table
        self.edges = edges
        self.edgeTable = edgeTable
        self.pooled = pooled
        self.readsPositions = readsPositions
    }

    /// Compressed rows, checked: `n + 1` nondecreasing offsets within `targets`, and `edges`, when
    /// read, as long as `targets`. Traps otherwise.
    @inlinable
    static func compressed(offsets: UnsafeBufferPointer<Int>, targets: UnsafeBufferPointer<Int>, edges: UnsafeBufferPointer<Int>?, count n: Int) -> _EdgeFlatRows {
        precondition(offsets.count == n + 1 && offsets[0] >= 0 && offsets[n] <= targets.count, "The row offsets do not match the vertex count")
        for v in 0 ..< n { precondition(offsets[v] <= offsets[v + 1], "The row offsets decrease") }
        if let edges { precondition(edges.count >= offsets[n], "The edge rows are shorter than the target rows") }
        return _EdgeFlatRows(targets: targets, table: offsets, edges: edges ?? UnsafeBufferPointer(start: nil, count: 0), edgeTable: UnsafeBufferPointer(start: nil, count: 0), pooled: false, readsPositions: edges != nil)
    }

    /// Pooled rows, checked: every row within its storage, a vertex's two rows of equal length.
    /// Traps otherwise.
    @inlinable
    static func pooled(targets: UnsafeBufferPointer<Int>, targetRows: UnsafeBufferPointer<Int>, edges: UnsafeBufferPointer<Int>, edgeRows: UnsafeBufferPointer<Int>, count n: Int) -> _EdgeFlatRows {
        precondition(targetRows.count >= 3 * n && edgeRows.count >= 3 * n, "The row tables are shorter than vertexIndexBound")
        for v in 0 ..< n {
            let (ts, tl, es, el) = (targetRows[3 * v], targetRows[3 * v + 1], edgeRows[3 * v], edgeRows[3 * v + 1])
            precondition(tl == el && tl >= 0 && ts >= 0 && es >= 0 && ts + tl <= targets.count && es + el <= edges.count, "Row \(v) of the row tables is out of bounds")
        }
        return _EdgeFlatRows(targets: targets, table: targetRows, edges: edges, edgeTable: edgeRows, pooled: true, readsPositions: true)
    }

    /// The slots of `u`'s row, and the shift from a slot to its position's slot in `edges`.
    @inlinable
    @inline(__always)
    func bounds(of u: Int) -> (start: Int, end: Int, shift: Int) {
        if pooled {
            let start = table[3 &* u]
            return (start, start &+ table[3 &* u &+ 1], edgeTable[3 &* u] &- start)
        }
        return (table[u], table[u &+ 1], 0)
    }

    /// The position of the edge in slot `k` of a row with `shift`.
    @inlinable
    @inline(__always)
    func position(at k: Int, shift: Int) -> Int {
        readsPositions ? edges[k &+ shift] : k
    }
}

/// How a directed graph's rows are read one edge at a time. `compressed` and `pooled` keep
/// integer cursors into the rows the graph lends, fetched again by index for each edge, so a row
/// on the search's stack holds no reference.
@frozen
@usableFromInline
package enum _RowReading: UInt8 {
    case compressed, pooled, numbered, indexed, unindexed
}

/// A directed graph's out-edges. By slot, for the depth-first stack: the lent compressed or
/// pooled rows, or the numbered rows for a graph with holes. By iterator, for breadth-first
/// search and graphs that lend no rows: `outEdges(ofIndex:)` beside `successorIndices(ofIndex:)`
/// with vertex indices, and `outEdges(of:)` with `target(ofEdgeAt:)` without them.
@frozen
@usableFromInline
package struct _DirectedEdgeRows<G: DirectedGraph>: _EdgeSearchRows {
    @usableFromInline var ids: _VertexIdentifiers<G>
    @usableFromInline let reading: _RowReading

    @inlinable
    init(_ graph: G) {
        ids = _VertexIdentifiers(graph)
        if ids.isIndexed {
            let n = ids.count
            if G.Edges.Index.self == Int.self, graph._withSuccessorIndexRows({ offsets, targets in
                _ = _EdgeFlatRows.compressed(offsets: offsets, targets: targets, edges: nil, count: n)
            }) != nil {
                reading = .compressed
            } else if graph._withCheckedOutIndexRows({ _, _, _, _ in }) != nil {
                reading = .pooled
            } else {
                reading = .indexed
            }
        } else {
            reading = ids.rows != nil ? .numbered : .unindexed
        }
    }

    /// The rest of a row read by iterators: positions beside successor indices with vertex
    /// indices, positions alone without.
    @frozen
    @usableFromInline
    package struct Row {
        @usableFromInline var positions: G.OutEdges.Iterator?
        @usableFromInline var targets: G.SuccessorIndices.Iterator?

        @inlinable
        init() {
            positions = nil
            targets = nil
        }
    }

    @inlinable package static var isUndirected: Bool { false }

    @inlinable package static var emptyRow: Row { Row() }

    @inlinable package var denseCount: Int? { ids.isDense ? ids.count : nil }

    @inlinable package var vertexList: [G.Vertex] { Array(ids.graph.vertices) }

    @inlinable
    package mutating func identifier(of vertex: G.Vertex) -> Int { ids.identifier(of: vertex) }

    @inlinable
    package func vertex(_ id: Int) -> G.Vertex { ids.vertex(id) }

    @inlinable
    package var readsBySlot: Bool {
        switch reading {
        case .compressed, .pooled, .numbered: true
        case .indexed, .unindexed: false
        }
    }

    /// Every reading but the numbered rows'.
    @inlinable
    package var readsByIterator: Bool { reading != .numbered }

    @inlinable
    @inline(__always)
    package func bounds(of id: Int) -> (start: Int, end: Int, shift: Int) {
        switch reading {
        case .compressed:
            return ids.graph._withSuccessorIndexRows { offsets, _ in (offsets[id], offsets[id &+ 1], 0) }.unsafelyUnwrapped
        case .pooled:
            return ids.graph._withOutIndexRows { _, targetRows, _, edgeRows in
                let start = targetRows[3 &* id]
                return (start, start &+ targetRows[3 &* id &+ 1], edgeRows[3 &* id] &- start)
            }.unsafelyUnwrapped
        case .numbered:
            let offsets = ids.rows.unsafelyUnwrapped.offsets
            return (offsets[id], offsets[id &+ 1], 0)
        case .indexed, .unindexed:
            preconditionFailure("These rows are read by iterators")
        }
    }

    @inlinable
    @inline(__always)
    package func edge(atSlot k: Int, shift: Int) -> (edge: G.Edges.Index, target: Int) {
        switch reading {
        case .compressed:
            let target = ids.graph._withSuccessorIndexRows { _, targets in targets[k] }.unsafelyUnwrapped
            return (unsafeBitCast(k, to: G.Edges.Index.self), target)
        case .pooled:
            let (position, target) = ids.graph._withOutIndexRows { targets, _, edges, _ in (edges[k &+ shift], targets[k]) }.unsafelyUnwrapped
            return (unsafeBitCast(position, to: G.Edges.Index.self), target)
        case .numbered:
            let rows = ids.rows.unsafelyUnwrapped
            return (unsafeBitCast(rows.edges[k], to: G.Edges.Index.self), rows.neighbors[k])
        case .indexed, .unindexed:
            preconditionFailure("These rows are read by iterators")
        }
    }

    /// With vertex indices, `outEdges(ofIndex:)` beside `successorIndices(ofIndex:)`; without,
    /// `outEdges(of:)`.
    ///
    /// - Precondition: `readsByIterator`.
    @inlinable
    package func load(_ row: inout Row, of id: Int) {
        if reading != .unindexed {
            let graph = ids.graph
            row.positions = graph.outEdges(ofIndex: id).makeIterator()
            row.targets = graph.successorIndices(ofIndex: id).makeIterator()
        } else {
            row.positions = ids.graph.outEdges(of: ids.vertices[id]).makeIterator()
        }
    }

    @inlinable
    package func clear(_ row: inout Row) {
        row.positions = nil
        row.targets = nil
    }

    @inlinable
    @inline(__always)
    package mutating func next(in row: inout Row) -> (edge: G.Edges.Index, target: Int)? {
        if reading != .unindexed {
            // `outEdges` and `successorIndices` have the same length.
            guard let edge = row.positions?.next(), let target = row.targets?.next() else { return nil }
            return (edge, target)
        }
        guard let edge = row.positions?.next() else { return nil }
        return (edge, ids.identifier(of: ids.graph.target(ofEdgeAt: edge)))
    }

    @inlinable
    package func withFlatRows<Result>(_ body: (_EdgeFlatRows) -> Result) -> Result? {
        guard G.Edges.Index.self == Int.self else { return nil }
        let n = ids.count
        switch reading {
        case .compressed:
            return ids.graph._withSuccessorIndexRows { offsets, targets in
                body(_EdgeFlatRows.compressed(offsets: offsets, targets: targets, edges: nil, count: n))
            }
        case .pooled:
            return ids.graph._withCheckedOutIndexRows { targets, targetRows, edges, edgeRows in
                body(_EdgeFlatRows.pooled(targets: targets, targetRows: targetRows, edges: edges, edgeRows: edgeRows, count: n))
            }
        case .numbered:
            let rows = ids.rows.unsafelyUnwrapped
            return rows.offsets.withUnsafeBufferPointer { offsets in
                rows.neighbors.withUnsafeBufferPointer { neighbors in
                    rows.edges.withUnsafeBufferPointer { edges in
                        body(_EdgeFlatRows.compressed(offsets: offsets, targets: neighbors, edges: edges, count: n))
                    }
                }
            }
        case .indexed, .unindexed:
            return nil
        }
    }
}

/// An undirected graph's incident edges: `incidentEdges(ofIndex:)` beside
/// `neighborIndices(ofIndex:)` with vertex indices, and `incidentEdges(of:)` with
/// `oppositeVertex(to:acrossEdgeAt:)` otherwise. A self-loop is in its vertex's row twice. The
/// rows lent by `_withIncidentIndexRows` are read by slot, one edge at a time, only when the graph
/// lends them in constant time; `withFlatRows` reads them once per search.
@frozen
@usableFromInline
package struct _UndirectedEdgeRows<G: Graph>: _EdgeSearchRows {
    @usableFromInline let graph: G
    @usableFromInline let isIndexed: Bool
    /// Whether the lent incident rows can be read as positions (`_flatRowsArePositions`).
    @usableFromInline let lendsPositions: Bool
    /// Whether the rows are read by slot: lent in constant time, and checked once here.
    @usableFromInline package let readsBySlot: Bool
    /// Without vertex indices: the identifiers handed out, and the vertex of each.
    @usableFromInline var identifiers: [G.Vertex: Int] = [:]
    @usableFromInline var vertices: [G.Vertex] = []

    @inlinable
    init(_ graph: G) {
        self.graph = graph
        let n = graph.vertexIndexBound
        isIndexed = n != nil
        lendsPositions = n != nil && Self._flatRowsArePositions(graph)
        if lendsPositions, G._lendsIncidentRowsInConstantTime {
            readsBySlot = graph._withIncidentIndexRows { neighbors, neighborRows, edges, edgeRows in
                _ = _EdgeFlatRows.pooled(targets: neighbors, targetRows: neighborRows, edges: edges, edgeRows: edgeRows, count: n!)
            } != nil
        } else {
            readsBySlot = false
        }
    }

    /// Whether the edge indices in the lent incident rows are the positions: `Int` positions
    /// `0..<edgeCount` in order, with edge indices, as `_withIncidentIndexRows` documents.
    @inlinable
    static func _flatRowsArePositions(_ graph: G) -> Bool {
        G.Edges.Index.self == Int.self && graph.edgeIndexBound == graph.edgeCount
            && unsafeBitCast(graph.edges.startIndex, to: Int.self) == 0
            && unsafeBitCast(graph.edges.endIndex, to: Int.self) == graph.edgeCount
    }

    /// The rest of a row: incident positions, beside neighbor indices with vertex indices.
    @frozen
    @usableFromInline
    package struct Row {
        @usableFromInline var positions: G.IncidentEdges.Iterator?
        @usableFromInline var targets: G.NeighborIndices.Iterator?
        /// The vertex the row belongs to.
        @usableFromInline var source: Int

        @inlinable
        init() {
            positions = nil
            targets = nil
            source = -1
        }
    }

    @inlinable package static var isUndirected: Bool { true }

    @inlinable package static var emptyRow: Row { Row() }

    @inlinable package var denseCount: Int? { isIndexed ? graph.vertexIndexBound! : nil }

    @inlinable package var vertexList: [G.Vertex] { Array(graph.vertices) }

    @inlinable
    package mutating func identifier(of vertex: G.Vertex) -> Int {
        if isIndexed { return graph.vertexIndex(of: vertex) }
        if let id = identifiers[vertex] { return id }
        let id = vertices.count
        identifiers[vertex] = id
        vertices.append(vertex)
        return id
    }

    @inlinable
    package func vertex(_ id: Int) -> G.Vertex {
        isIndexed ? graph.vertex(atIndex: id) : vertices[id]
    }

    @inlinable package var readsByIterator: Bool { true }

    @inlinable
    @inline(__always)
    package func bounds(of id: Int) -> (start: Int, end: Int, shift: Int) {
        graph._withIncidentIndexRows { _, neighborRows, _, edgeRows in
            let start = neighborRows[3 &* id]
            return (start, start &+ neighborRows[3 &* id &+ 1], edgeRows[3 &* id] &- start)
        }.unsafelyUnwrapped
    }

    @inlinable
    @inline(__always)
    package func edge(atSlot k: Int, shift: Int) -> (edge: G.Edges.Index, target: Int) {
        let (position, target) = graph._withIncidentIndexRows { neighbors, _, edges, _ in (edges[k &+ shift], neighbors[k]) }.unsafelyUnwrapped
        return (unsafeBitCast(position, to: G.Edges.Index.self), target)
    }

    @inlinable
    package func load(_ row: inout Row, of id: Int) {
        if isIndexed {
            row.positions = graph.incidentEdges(ofIndex: id).makeIterator()
            row.targets = graph.neighborIndices(ofIndex: id).makeIterator()
        } else {
            row.positions = graph.incidentEdges(of: vertices[id]).makeIterator()
        }
        row.source = id
    }

    @inlinable
    package func clear(_ row: inout Row) {
        row.positions = nil
        row.targets = nil
    }

    @inlinable
    @inline(__always)
    package mutating func next(in row: inout Row) -> (edge: G.Edges.Index, target: Int)? {
        if isIndexed {
            // `incidentEdges` and `neighborIndices` have the same length.
            guard let edge = row.positions?.next(), let target = row.targets?.next() else { return nil }
            return (edge, target)
        }
        guard let edge = row.positions?.next() else { return nil }
        return (edge, identifier(of: graph.oppositeVertex(to: vertices[row.source], acrossEdgeAt: edge)))
    }

    /// The lent incident rows, when their edge indices are the positions.
    @inlinable
    package func withFlatRows<Result>(_ body: (_EdgeFlatRows) -> Result) -> Result? {
        guard lendsPositions else { return nil }
        let n = graph.vertexIndexBound!
        return graph._withIncidentIndexRows { neighbors, neighborRows, edges, edgeRows in
            body(_EdgeFlatRows.pooled(targets: neighbors, targetRows: neighborRows, edges: edges, edgeRows: edgeRows, count: n))
        }
    }
}

extension _DirectedEdgeRows: Sendable where G: Sendable, G.Vertex: Sendable {}
extension _DirectedEdgeRows.Row: Sendable where G.OutEdges.Iterator: Sendable, G.SuccessorIndices.Iterator: Sendable {}
extension _UndirectedEdgeRows: Sendable where G: Sendable, G.Vertex: Sendable {}
extension _UndirectedEdgeRows.Row: Sendable where G.IncidentEdges.Iterator: Sendable, G.NeighborIndices.Iterator: Sendable {}

/// Per-vertex flags of an edge search, one byte per vertex beside its discovery order or depth.
@frozen
@usableFromInline
package enum _EdgeSearchFlag {
    @inlinable @inline(__always) static var finished: UInt8 { 1 }
    /// The vertex's edges are examined: it was not pruned and is not at the depth limit.
    @inlinable @inline(__always) static var explored: UInt8 { 2 }
    @inlinable @inline(__always) static var pruned: UInt8 { 4 }
}
