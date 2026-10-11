/// A directed graph whose vertices and edges sit at integer positions in `0..<vertexPositionBound`
/// and `0..<edgePositionBound` that may have holes: petgraph's `NodeIndexable` and
/// `EdgeIndexable`, whose `node_bound()` and `edge_bound()` are "an upper bound of the indices,
/// suitable for the size of a bitmap", as against `NodeCompactIndexable`, whose indices have no
/// holes. `DirectedGraph`'s `vertexIndexBound` and `edgeIndexBound` are the compact kind and keep
/// their laws; a conformer reports them only while it has no holes.
///
/// Algorithms use this refinement to keep per-vertex and per-edge state in arrays sized by the
/// bounds while holes exist, instead of hashing every vertex and edge they meet.
///
/// **Laws.** In addition to `BidirectionalDirectedGraph`'s:
/// - `containsVertex(atPosition: p)` is true exactly for the positions of live vertices, all in
///   `0..<vertexPositionBound`; `vertexPosition(of:)` and `vertex(atPosition:)` are inverse; and
///   `vertices` lists the live vertices in increasing position. Likewise `containsEdge(atPosition:)`
///   for the positions in `edges`, all in `0..<edgePositionBound`, in increasing order.
/// - Without holes, the bounds equal `vertexIndexBound` and `edgeIndexBound`, and positions are
///   indices.
/// - `_numberedRows(outward:edges:)` numbers the live vertices `0..<vertexCount` in `vertices` order and
///   lists, for each number, the numbers of its successors (outward) or predecessors, with the edge
///   positions beside them, in `outEdges(of:)` or `inEdges(of:)` order.
public protocol SparselyIndexedDirectedGraph<Vertex>: BidirectionalDirectedGraph where Edges.Index == Int {
    /// One more than the highest vertex position ever handed out: `vertices.endIndex` for a
    /// graph whose `Vertices.Index` is the position (petgraph's `node_bound()`).
    var vertexPositionBound: Int { get }

    /// One more than the highest edge position ever handed out (petgraph's `edge_bound()`).
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

    /// The live vertices numbered in `vertices` order and their successor rows (`outward`) or
    /// predecessor rows in that numbering, with each entry's edge position when `edges` (otherwise
    /// `_NumberedRows.edges` is empty), in O(`vertexPositionBound` + `edgeCount`) with no hashing.
    ///
    /// Not for use outside the library: index-space algorithms call it once per run. A conformer
    /// outside it gets a default built from the public members above.
    func _numberedRows(outward: Bool, edges: Bool) -> _NumberedRows
}

extension SparselyIndexedDirectedGraph {
    /// The default: live vertices numbered by one pass over `0..<vertexPositionBound`, and each row
    /// read through `outEdges(of:)` or `inEdges(of:)`, the far end numbered through
    /// `vertexPosition(of:)`, so one hash per vertex and per edge. O(`vertexPositionBound` +
    /// `edgeCount`).
    @inlinable
    public func _numberedRows(outward: Bool, edges withEdges: Bool) -> _NumberedRows {
        let bound = vertexPositionBound
        var numbers = [Int](repeating: -1, count: bound)
        var n = 0
        for position in 0 ..< bound where containsVertex(atPosition: position) {
            numbers[position] = n
            n += 1
        }
        var offsets = [0]
        offsets.reserveCapacity(n + 1)
        var neighbors: [Int] = []
        neighbors.reserveCapacity(edgeCount)
        var edges: [Int] = []
        if withEdges { edges.reserveCapacity(edgeCount) }
        for position in 0 ..< bound where numbers[position] >= 0 {
            let vertex = vertex(atPosition: position)
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

/// A graph's adjacency in a dense numbering of its live vertices: what
/// `SparselyIndexedDirectedGraph._numberedRows(outward:edges:)` returns.
@frozen
public struct _NumberedRows {
    /// Each vertex position's number, or -1 at a hole: `vertexPositionBound` entries.
    @usableFromInline package let numbers: [Int]
    /// Row offsets: row `v` is `offsets[v] ..< offsets[v + 1]`; `vertexCount + 1` entries.
    @usableFromInline package let offsets: [Int]
    /// Neighbor numbers, by row.
    @usableFromInline package let neighbors: [Int]
    /// Edge positions, parallel to `neighbors`; empty when not asked for.
    @usableFromInline package let edges: [Int]

    @inlinable
    package init(numbers: [Int], offsets: [Int], neighbors: [Int], edges: [Int]) {
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
