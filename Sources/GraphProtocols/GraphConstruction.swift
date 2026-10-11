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
/// the generators on the concrete types (`CompressedSparseRow.complete(vertexCount: 5)`). The
/// requirement also takes a `_ConstructionToken`, which only this package can create, so code
/// outside it cannot call the unchecked initializer at all. Debug builds still check the input
/// (`_isSortedSimple`), in O(m).
public protocol _DirectedGraphConstruction: DirectedGraph where Vertex == Int {
    /// The graph on `0..<vertexCount` with `sortedEdges`, unchecked: see the protocol.
    init(_vertexCount: Int, sortedEdges: some Collection<DirectedEdge<Int>>, _: _ConstructionToken)
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
    init(_vertexCount: Int, sortedEdges: some Collection<UndirectedEdge<Int>>, _: _ConstructionToken)
}

/// The proof that a call to an unchecked bulk initializer (`_DirectedGraphConstruction`,
/// `_GraphConstruction`) comes from inside the package. The type is public so that the protocols
/// can name it, but its only initializer is `package`: a caller outside the package cannot make
/// one, and so cannot hand a conformer edges it would write out of bounds.
@frozen
public struct _ConstructionToken {
    @inlinable
    package init() {}
}

/// Whether `edges` are what `_DirectedGraphConstruction` requires: endpoints in `0..<vertexCount`,
/// no self-loop, and strictly increasing in row-major order (so no repeats). O(m). The conformers
/// `assert` it, so the check runs in debug builds only. It also checks that the collection is
/// consistent: iteration, the indices with their subscript, and `count` give the same edges, since a
/// conformer sizes its storage by `count` and the generators' lazy collections compute all three.
@inlinable
package func _isSortedSimple(vertexCount n: Int, _ edges: some Collection<DirectedEdge<Int>>) -> Bool {
    var previous: (source: Int, target: Int) = (-1, -1)
    var index = edges.startIndex
    var count = 0
    for edge in edges {
        let source = edge.source, target = edge.target
        guard 0 <= source, source < n, 0 <= target, target < n, source != target,
              (source, target) > previous,
              index < edges.endIndex, edges[index] == edge
        else { return false }
        previous = (source, target)
        edges.formIndex(after: &index)
        count += 1
    }
    return index == edges.endIndex && count == edges.count
}

/// Whether `edges` are what `_GraphConstruction` requires: every edge `UndirectedEdge(u, v)` with
/// `0 <= u < v < vertexCount`, strictly increasing in lexicographic order (so no repeats), in a
/// consistent collection, as the directed form checks. O(m).
@inlinable
package func _isSortedSimple(vertexCount n: Int, _ edges: some Collection<UndirectedEdge<Int>>) -> Bool {
    var previous: (u: Int, v: Int) = (-1, -1)
    var index = edges.startIndex
    var count = 0
    for edge in edges {
        let u = edge.u, v = edge.v
        guard 0 <= u, u < v, v < n, (u, v) > previous,
              index < edges.endIndex, edges[index].u == u, edges[index].v == v
        else { return false }
        previous = (u, v)
        edges.formIndex(after: &index)
        count += 1
    }
    return index == edges.endIndex && count == edges.count
}
