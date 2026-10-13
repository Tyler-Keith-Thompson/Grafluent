/// A directed graph whose vertices and edges sit at integer positions in `0..<vertexPositionBound`
/// and `0..<edgePositionBound`, with possible holes.
///
/// `DirectedGraph`'s `vertexIndexBound` and `edgeIndexBound` describe dense indices with no holes
/// and keep their laws. A conformer reports them only while it has no holes.
///
/// Algorithms use this refinement to number the live vertices and edges with arrays while holes
/// exist, instead of hashing every vertex and edge they meet. The bounds are upper bounds only.
/// Positions are never reused, so a bound counts every position ever handed out, and nothing in
/// the library allocates by it. Position-keyed state goes through a paged map
/// (`_PositionNumbers`), O(live elements + pages).
///
/// In addition to `BidirectionalDirectedGraph`'s laws:
/// - `containsVertex(atPosition: p)` is true exactly for the positions of live vertices, all in
///   `0..<vertexPositionBound`. `vertexPosition(of:)` and `vertex(atPosition:)` are inverses, and
///   `vertices` lists the live vertices in increasing position. Likewise
///   `containsEdge(atPosition:)` is true exactly for the positions in `edges`, all in
///   `0..<edgePositionBound`, which `edges` lists in increasing order.
/// - Without holes, the bounds equal `vertexIndexBound` and `edgeIndexBound`, and positions are
///   indices.
/// - `_numberedRows(outward:edges:)` numbers the live vertices `0..<vertexCount` in `vertices` order and
///   lists, for each number, the numbers of its successors (outward) or predecessors, with the edge
///   positions beside them, in `outEdges(of:)` or `inEdges(of:)` order.
public protocol SparselyIndexedDirectedGraph<Vertex>: BidirectionalDirectedGraph where Edges.Index == Int {
    /// One more than the highest vertex position ever handed out. For a graph whose
    /// `Vertices.Index` is the position, this is `vertices.endIndex`.
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

    /// The live vertices numbered in `vertices` order, with their successor rows (`outward`) or
    /// predecessor rows in that numbering. When `edges` is true, each entry carries its edge
    /// position; otherwise `_NumberedRows.edges` is empty. `StableDirectedGraph`'s implementation
    /// runs in O(`vertexCount` + `edgeCount` + pages) with no hashing, independent of how many
    /// positions were ever handed out.
    ///
    /// Not for use outside the library. Index-space algorithms call it once per run. A conformer
    /// outside the library gets a default built from the public members above.
    func _numberedRows(outward: Bool, edges: Bool) -> _NumberedRows
}

extension SparselyIndexedDirectedGraph {
    /// Numbers the live vertices in one pass over `vertices`, finding each position through
    /// `vertexPosition(of:)`, and reads each row through `outEdges(of:)` or `inEdges(of:)`, with
    /// the far end numbered through `vertexPosition(of:)`. That is one hash per vertex and per
    /// edge. The position map is paged, so its memory does not grow with `vertexPositionBound`.
    ///
    /// - Complexity: O(`vertexCount` + `edgeCount`), plus the cost of iterating `vertices`.
    @inlinable
    public func _numberedRows(outward: Bool, edges withEdges: Bool) -> _NumberedRows {
        var builder = _PositionNumbers.Builder()
        var listed: [Vertex] = []
        listed.reserveCapacity(vertexCount)
        for vertex in vertices {
            builder.append(vertexPosition(of: vertex), number: listed.count)
            listed.append(vertex)
        }
        let numbers = builder.build()
        var offsets = [0]
        offsets.reserveCapacity(listed.count + 1)
        var neighbors: [Int] = []
        neighbors.reserveCapacity(edgeCount)
        var edges: [Int] = []
        if withEdges { edges.reserveCapacity(edgeCount) }
        for vertex in listed {
            if outward {
                for edge in outEdges(of: vertex) {
                    neighbors.append(numbers[vertexPosition(of: target(ofEdgeAt: edge))])
                    if withEdges { edges.append(edge) }
                }
            } else {
                for edge in inEdges(of: vertex) {
                    neighbors.append(numbers[vertexPosition(of: source(ofEdgeAt: edge))])
                    if withEdges { edges.append(edge) }
                }
            }
            offsets.append(neighbors.count)
        }
        return _NumberedRows(numbers: numbers, offsets: offsets, neighbors: neighbors, edges: edges)
    }
}

/// A graph's adjacency in a dense numbering of its live vertices, returned by
/// `SparselyIndexedDirectedGraph._numberedRows(outward:edges:)`.
@frozen
public struct _NumberedRows {
    /// Each live vertex position's number (-1 at any other position), paged: O(live pages + page
    /// span) memory, not O(`vertexPositionBound`).
    @usableFromInline package let numbers: _PositionNumbers
    /// Row offsets: row `v` is `offsets[v] ..< offsets[v + 1]`; `vertexCount + 1` entries.
    @usableFromInline package let offsets: [Int]
    /// Neighbor numbers, by row.
    @usableFromInline package let neighbors: [Int]
    /// Edge positions, parallel to `neighbors`; empty when not asked for.
    @usableFromInline package let edges: [Int]

    @inlinable
    package init(numbers: _PositionNumbers, offsets: [Int], neighbors: [Int], edges: [Int]) {
        self.numbers = numbers
        self.offsets = offsets
        self.neighbors = neighbors
        self.edges = edges
    }

    /// The number of live vertices.
    @inlinable
    package var count: Int { offsets.count - 1 }
}

extension _NumberedRows: Sendable {}

extension DirectedGraph {
    /// The graph as a `SparselyIndexedDirectedGraph` while it has holes (no `vertexIndexBound`);
    /// nil when it has vertex indices or does not conform.
    @inlinable
    package func _sparselyIndexed() -> (any SparselyIndexedDirectedGraph<Vertex>)? {
        guard vertexIndexBound == nil else { return nil }
        return self as? any SparselyIndexedDirectedGraph<Vertex>
    }
}
