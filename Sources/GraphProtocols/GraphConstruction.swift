/// A directed representation on the vertices `0..<vertexCount` that can be built in one bulk step
/// from a sorted edge list. The generators (`NamedGraphs`, `RandomGraphs`) are written once as
/// extensions of this protocol and reach every conformer through it, as Boost's generators reach
/// every graph type through its edge-iterator constructor `Graph(first, last, n)`.
///
/// The requirement checks nothing. The caller guarantees that the edges are in row-major order
/// (by source, then by target), with no repeats and no self-loops, and that every endpoint is in
/// `0..<vertexCount`. A conformer may then skip its own sorting, deduplication and membership
/// checks: `CompressedSparseRow` writes its rows in a single pass. The result has the vertices
/// `0..<vertexCount` in order, at vertex index `v` for vertex `v`, and the edges at positions
/// `0..<edgeCount` in the given order.
///
/// Underscored because it is a hook for the library's generators, not a name for callers: they call
/// the generators on the concrete types (`CompressedSparseRow.complete(vertexCount: 5)`).
public protocol _DirectedGraphConstruction: DirectedGraph where Vertex == Int {
    /// The graph on `0..<vertexCount` with `sortedEdges`, unchecked: see the protocol.
    init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>)
}

/// An undirected representation on the vertices `0..<vertexCount` that can be built in one bulk
/// step from a sorted edge list: `_DirectedGraphConstruction`'s undirected counterpart.
///
/// The caller guarantees that every edge is `UndirectedEdge(u, v)` with `u < v` (so no self-loop),
/// that the edges are in lexicographic order with no repeats, and that every endpoint is in
/// `0..<vertexCount`. The result has the vertices `0..<vertexCount` in order and the edges at
/// positions `0..<edgeCount` in the given order and orientation, so each vertex's incident edges
/// come in edge order: its smaller neighbors first, then its larger ones, each ascending.
public protocol _GraphConstruction: Graph where Vertex == Int {
    /// The graph on `0..<vertexCount` with `sortedEdges`, unchecked: see the protocol.
    init(_vertexCount: Int, sortedEdges: some Collection<UndirectedEdge<Int>>)
}
