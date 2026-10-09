/// An undirected graph's incidence in index space: for vertex number `v`, `count(v)` edge ends,
/// the `k`th with neighbor number `neighbor(v, k)` and edge number `edge(v, k)`, in
/// `incidentEdges` order (a self-loop twice, with the neighbor `v`).
@usableFromInline
package protocol _IncidenceRowSource {
    mutating func count(_ v: Int) -> Int
    mutating func neighbor(_ v: Int, _ k: Int) -> Int
    mutating func edge(_ v: Int, _ k: Int) -> Int
}

/// Rows stored by the representation (`_withIncidentIndexRows`): flat storage and row tables of
/// three entries per vertex (start, length, unused). Unchecked; valid only inside that call.
@frozen
@usableFromInline
package struct _IncidenceRows: _IncidenceRowSource {
    @usableFromInline let neighbors: UnsafeBufferPointer<Int>
    @usableFromInline let neighborRows: UnsafeBufferPointer<Int>
    @usableFromInline let edges: UnsafeBufferPointer<Int>
    @usableFromInline let edgeRows: UnsafeBufferPointer<Int>

    @inlinable
    package init(neighbors: UnsafeBufferPointer<Int>, neighborRows: UnsafeBufferPointer<Int>, edges: UnsafeBufferPointer<Int>, edgeRows: UnsafeBufferPointer<Int>) {
        self.neighbors = neighbors
        self.neighborRows = neighborRows
        self.edges = edges
        self.edgeRows = edgeRows
    }

    @inlinable @inline(__always)
    package mutating func count(_ v: Int) -> Int { neighborRows[3 &* v &+ 1] }

    @inlinable @inline(__always)
    package mutating func neighbor(_ v: Int, _ k: Int) -> Int { neighbors[neighborRows[3 &* v] &+ k] }

    @inlinable @inline(__always)
    package mutating func edge(_ v: Int, _ k: Int) -> Int { edges[edgeRows[3 &* v] &+ k] }
}

/// Rows read from any conformer, each copied into flat arrays the first time it is asked for and
/// never again: an early exit reads only the rows it reaches, and no row is read twice. Numbering
/// the vertices of a graph without vertex indices (and its edges, without edge indices, when the
/// algorithm reads edges) still takes one pass first.
///
/// A struct, used `inout`: reading the graph from a class property would copy it out, retaining
/// every buffer the representation holds, on each row read.
@frozen
@usableFromInline
package struct _LazyIncidenceRows<G: Graph>: _IncidenceRowSource {
    @usableFromInline let graph: G
    /// Without vertex indices: the vertices by number, and each one's number.
    @usableFromInline let listed: [G.Vertex]
    @usableFromInline let vertexNumbers: [G.Vertex: Int]
    /// Without edge indices: each position's number.
    @usableFromInline let edgeNumbers: [G.Edges.Index: Int]
    /// Whether the algorithm reads edge numbers; when not, `edges` stays empty.
    @usableFromInline let readsEdges: Bool
    @usableFromInline var neighbors: [Int] = []
    @usableFromInline var edges: [Int] = []
    /// Per vertex number: the row's start, or −1 before it is read; and its length.
    @usableFromInline var starts: [Int]
    @usableFromInline var lengths: [Int]

    @inlinable
    package init(_ graph: G, count n: Int, readsEdges: Bool, edgeNumbers: [G.Edges.Index: Int]?) {
        self.graph = graph
        if graph.vertexIndexBound == nil {
            listed = Array(graph.vertices)
            var numbers: [G.Vertex: Int] = [:]
            numbers.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { numbers[v] = i }
            vertexNumbers = numbers
        } else {
            listed = []
            vertexNumbers = [:]
        }
        self.readsEdges = readsEdges
        self.edgeNumbers = !readsEdges || graph.edgeIndexBound != nil ? [:] : edgeNumbers ?? graph._edgeNumbers()
        starts = [Int](repeating: -1, count: n)
        lengths = [Int](repeating: 0, count: n)
    }

    @inlinable @inline(__always)
    mutating func _read(_ v: Int) {
        if starts[v] < 0 { _fill(v) }
    }

    @inlinable
    mutating func _fill(_ v: Int) {
        let start = neighbors.count
        let indexedEdges = graph.edgeIndexBound != nil
        if graph.vertexIndexBound != nil {
            // Plain loops: `append(contentsOf:)` on a lazy sequence was several times slower.
            for w in graph.neighborIndices(ofIndex: v) { neighbors.append(w) }
            if readsEdges {
                if indexedEdges {
                    // Not `incidentEdgeIndices(ofIndex:)`: its default is a lazy map capturing the
                    // graph, which copies a view's base, retaining all its storage, per row.
                    for position in graph.incidentEdges(ofIndex: v) { edges.append(graph.edgeIndex(of: position)) }
                } else {
                    for position in graph.incidentEdges(ofIndex: v) { edges.append(edgeNumbers[position]!) }
                }
                precondition(edges.count == neighbors.count, "neighborIndices and incidentEdges differ in length")
            }
        } else {
            let vertex = listed[v]
            for position in graph.incidentEdges(of: vertex) {
                neighbors.append(vertexNumbers[graph.oppositeVertex(to: vertex, acrossEdgeAt: position)]!)
                if readsEdges { edges.append(indexedEdges ? graph.edgeIndex(of: position) : edgeNumbers[position]!) }
            }
        }
        starts[v] = start
        lengths[v] = neighbors.count - start
    }

    @inlinable
    package mutating func count(_ v: Int) -> Int {
        _read(v)
        return lengths[v]
    }

    @inlinable
    package mutating func neighbor(_ v: Int, _ k: Int) -> Int {
        _read(v)
        return neighbors[starts[v] + k]
    }

    @inlinable
    package mutating func edge(_ v: Int, _ k: Int) -> Int {
        _read(v)
        return edges[starts[v] + k]
    }
}

/// An algorithm over an undirected graph's rows in index space: vertex numbers `0..<count` in
/// `vertices` order, edge numbers `0..<edgeCount` in `edges` order.
@usableFromInline
package protocol _UndirectedRowsAlgorithm {
    associatedtype Output
    /// Whether the algorithm calls `edge(_:_:)`; when not, edge numbers are never built.
    var readsEdges: Bool { get }
    func run<Rows: _IncidenceRowSource>(count: Int, edgeCount: Int, _ rows: inout Rows) -> Output
}

extension _UndirectedRowsAlgorithm {
    @inlinable
    package var readsEdges: Bool { true }
}

extension Graph {
    /// Runs `algorithm` over the graph's incidence in index space: its stored rows when it offers
    /// them (`_withIncidentIndexRows`), so nothing is hashed or copied; otherwise each row read
    /// once, when first asked for, through `neighborIndices` and `incidentEdgeIndices` with vertex
    /// and edge indices, with one dictionary lookup per edge end for the edge numbers with vertex
    /// indices only, and one more for the neighbors without vertex indices.
    ///
    /// `edgeNumbers`, when given, is `_edgeNumbers()` already computed by the caller.
    @inlinable
    package func _runOnUndirectedRows<A: _UndirectedRowsAlgorithm>(_ algorithm: A, edgeNumbers: [Edges.Index: Int]? = nil) -> A.Output {
        let m = edgeCount
        if let n = vertexIndexBound, edgeIndexBound != nil, let output = _withIncidentIndexRows({ neighbors, neighborRows, edges, edgeRows in
            // The buffers are unchecked from here on, so check every row once: in bounds in both
            // storages, the two rows of a vertex equally long. O(n).
            precondition(neighborRows.count >= 3 * n && edgeRows.count >= 3 * n, "The row tables are shorter than vertexIndexBound")
            for v in 0 ..< n {
                let (ns, nl, es, el) = (neighborRows[3 * v], neighborRows[3 * v + 1], edgeRows[3 * v], edgeRows[3 * v + 1])
                precondition(nl == el && nl >= 0 && ns >= 0 && es >= 0 && ns + nl <= neighbors.count && es + el <= edges.count, "Row \(v) of the incidence tables is out of bounds")
            }
            var rows = _IncidenceRows(neighbors: neighbors, neighborRows: neighborRows, edges: edges, edgeRows: edgeRows)
            return algorithm.run(count: n, edgeCount: m, &rows)
        }) {
            return output
        }
        let n = vertexIndexBound ?? vertexCount
        var rows = _LazyIncidenceRows(self, count: n, readsEdges: algorithm.readsEdges, edgeNumbers: edgeNumbers)
        return algorithm.run(count: n, edgeCount: m, &rows)
    }

    /// Each edge position's offset in `edges`.
    @inlinable
    package func _edgeNumbers() -> [Edges.Index: Int] {
        var numbers: [Edges.Index: Int] = [:]
        numbers.reserveCapacity(edgeCount)
        for (k, position) in edges.indices.enumerated() { numbers[position] = k }
        return numbers
    }

    /// The number of the edge at `position`: its edge index, or its offset in `edges`.
    @inlinable
    package func _edgeNumber(of position: Edges.Index, _ numbers: [Edges.Index: Int]) -> Int {
        edgeIndexBound != nil ? edgeIndex(of: position) : numbers[position]!
    }
}

