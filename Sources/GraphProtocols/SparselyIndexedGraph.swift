/// An undirected graph whose vertices and edges sit at integer positions in
/// `0..<vertexPositionBound` and `0..<edgePositionBound`, with possible holes: the undirected
/// counterpart of `SparselyIndexedDirectedGraph`.
///
/// `Graph`'s `vertexIndexBound` and `edgeIndexBound` describe dense indices with no holes and keep
/// their laws. A conformer reports them only while it has no holes of that kind.
///
/// Algorithms over the incidence rows use this refinement to number the live vertices and edges
/// with arrays while holes exist, instead of hashing every vertex and edge they meet. The bounds
/// are upper bounds only. Positions are never reused, so a bound counts every position ever handed
/// out, and nothing in the library allocates by it.
///
/// In addition to `Graph`'s laws:
/// - `containsVertex(atPosition: p)` is true exactly for the positions of live vertices, all in
///   `0..<vertexPositionBound`. `vertexPosition(of:)` and `vertex(atPosition:)` are inverses, and
///   `vertices` lists the live vertices in increasing position. Likewise
///   `containsEdge(atPosition:)` is true exactly for the positions in `edges`, all in
///   `0..<edgePositionBound`, which `edges` lists in increasing order.
/// - Without holes, the bounds equal `vertexIndexBound` and `edgeIndexBound`, and positions are
///   indices.
/// - `_numberedIncidenceRows()` numbers the live vertices `0..<vertexCount` in `vertices` order and
///   the live edges `0..<edgeCount` in `edges` order, and lists, for each vertex number, the
///   numbers of the far ends of its edge ends with the edge numbers beside them, in
///   `incidentEdges(of:)` order (a self-loop twice).
public protocol SparselyIndexedGraph<Vertex>: Graph where Edges.Index == Int {
    /// One more than the highest vertex position ever handed out.
    var vertexPositionBound: Int { get }

    /// One more than the highest edge position ever handed out.
    var edgePositionBound: Int { get }

    /// The position of `vertex`. O(1) expected.
    ///
    /// - Precondition: `contains(vertex)`.
    func vertexPosition(of vertex: Vertex) -> Int

    /// The vertex at `position`. O(1).
    ///
    /// - Precondition: `containsVertex(atPosition: position)`.
    func vertex(atPosition position: Int) -> Vertex

    /// Whether a live vertex sits at `position`; false, without trapping, for any other integer.
    /// O(1).
    func containsVertex(atPosition position: Int) -> Bool

    /// Whether a live edge sits at `position`; false, without trapping, for any other integer.
    /// O(1).
    func containsEdge(atPosition position: Int) -> Bool

    /// The live vertices numbered in `vertices` order, with their incidence rows in that numbering:
    /// `neighbors` holds the far ends' vertex numbers and `edges` the edge numbers (offsets in
    /// `edges`), both in `incidentEdges(of:)` order. `StableUndirectedGraph`'s implementation runs
    /// in O(`vertexCount` + `edgeCount` + pages) with no hashing.
    ///
    /// Not for use outside the library. Index-space algorithms call it once per run. A conformer
    /// outside the library gets a default built from the public members above.
    func _numberedIncidenceRows() -> _NumberedRows
}

extension SparselyIndexedGraph {
    /// Numbers the live vertices in one pass over `vertices` and the live edges in one pass over
    /// `edges.indices`, and reads each row through `incidentEdges(of:)`, with the far end found
    /// through `oppositeVertex(to:acrossEdgeAt:)` and `vertexPosition(of:)`. That is one hash per
    /// vertex and per edge end. The position maps are paged, so their memory does not grow with
    /// the position bounds.
    ///
    /// - Complexity: O(`vertexCount` + `edgeCount`), plus the cost of iterating `vertices` and
    ///   `edges.indices`.
    @inlinable
    public func _numberedIncidenceRows() -> _NumberedRows {
        var builder = _PositionNumbers.Builder()
        var listed: [Vertex] = []
        listed.reserveCapacity(vertexCount)
        for vertex in vertices {
            builder.append(vertexPosition(of: vertex), number: listed.count)
            listed.append(vertex)
        }
        let numbers = builder.build()
        var edgeBuilder = _PositionNumbers.Builder()
        for (k, position) in edges.indices.enumerated() { edgeBuilder.append(position, number: k) }
        let edgeNumbers = edgeBuilder.build()
        var offsets = [0]
        offsets.reserveCapacity(listed.count + 1)
        var neighbors: [Int] = []
        neighbors.reserveCapacity(2 * edgeCount)
        var edges: [Int] = []
        edges.reserveCapacity(2 * edgeCount)
        for vertex in listed {
            for position in incidentEdges(of: vertex) {
                neighbors.append(numbers[vertexPosition(of: oppositeVertex(to: vertex, acrossEdgeAt: position))])
                edges.append(edgeNumbers[position])
            }
            offsets.append(neighbors.count)
        }
        return _NumberedRows(numbers: numbers, offsets: offsets, neighbors: neighbors, edges: edges)
    }
}

extension _NumberedRows {
    /// The rows as `_withIncidentIndexRows` lends them: a row table of three entries per vertex
    /// number (start, length, unused) over `neighbors`, and the same table over `edges`. O(n).
    @inlinable
    package func _withIncidenceTables<Result>(
        _ body: (
            _ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>,
            _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>
        ) -> Result
    ) -> Result {
        let n = count
        let table = [Int](unsafeUninitializedCapacity: 3 &* n) { table, initialized in
            offsets.withUnsafeBufferPointer { offsets in
                for v in 0 ..< n {
                    table[3 &* v] = offsets[v]
                    table[3 &* v &+ 1] = offsets[v &+ 1] &- offsets[v]
                    table[3 &* v &+ 2] = 0
                }
            }
            initialized = 3 &* n
        }
        return neighbors.withUnsafeBufferPointer { neighbors in
            edges.withUnsafeBufferPointer { edges in
                table.withUnsafeBufferPointer { table in body(neighbors, table, edges, table) }
            }
        }
    }
}

extension Graph {
    /// The graph as a `SparselyIndexedGraph` while it has vertex or edge holes (no
    /// `vertexIndexBound` or no `edgeIndexBound`); nil when it has both indices or does not
    /// conform.
    @inlinable
    package func _sparselyIndexedGraph() -> (any SparselyIndexedGraph<Vertex>)? {
        guard vertexIndexBound == nil || edgeIndexBound == nil else { return nil }
        return self as? any SparselyIndexedGraph<Vertex>
    }
}
