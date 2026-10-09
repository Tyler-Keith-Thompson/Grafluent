import GraphProtocols
import Walks

/// Shortest paths from one or more sources: for each reached vertex, its distance, its parent and
/// the edge from the parent (a forest when there are several sources, LEMON's "shortest path tree
/// (forest)").
///
/// **Ties.** The first relaxation to a vertex's final distance wins. So `parent(of: v)` is a
/// shortest-path predecessor of `v` settled first. Vertices at equal distance settle in an
/// unspecified order, so when several vertices at the same smallest distance lead to `v` along
/// shortest paths, which one is the parent is unspecified. Among parallel edges from the parent,
/// the parent edge is the cheapest, and the first in `outEdges(of:)` order among equals.
///
/// A tree holds a copy of the graph, so looking a vertex up never hashes on a representation
/// with cheap vertex indices. While the tree is alive, the next mutation of the original copies
/// it; a tree of a graph about to change should be read and dropped first.
///
/// **Several sources.** Each source starts at distance zero with no parent. Dijkstra's algorithm
/// and breadth-first search never improve on that, so a source keeps no parent even when another
/// source reaches it. Bellman–Ford treats the sources as one super-source (NetworkX's
/// `_bellman_ford`): a negative path from one source to another improves the second, which then
/// has that distance, a parent and a path from the first.
///
/// Not `Equatable`: two correct trees can choose different parents on ties.
@frozen
public struct ShortestPathTree<G: DirectedGraph, Distance: Comparable & AdditiveArithmetic> {
    @usableFromInline let _ids: _VertexIdentifiers<G>
    /// Each index's distance; meaningful only where `_parent[i] != _unreached`.
    @usableFromInline let _distance: [Distance]
    /// Each index's parent index; `_source` for a source no other source improved; `_unreached`
    /// for an index not reached.
    @usableFromInline let _parent: [Int]
    /// Each index's parent edge; meaningful only where the parent is an index.
    @usableFromInline let _parentEdge: [G.Edges.Index]

    /// The sources, in the order given, each once.
    public let sources: [G.Vertex]

    @usableFromInline static var _source: Int { -1 }
    @usableFromInline static var _unreached: Int { -2 }

    @inlinable
    init(ids: _VertexIdentifiers<G>, distance: [Distance], parent: [Int], parentEdge: [G.Edges.Index], sources: [G.Vertex]) {
        _ids = ids
        _distance = distance
        _parent = parent
        _parentEdge = parentEdge
        self.sources = sources
    }

    @inlinable
    func _index(of vertex: G.Vertex) -> Int {
        _ids.graph._index(of: vertex, _ids)
    }

    /// The length of a shortest path from a source to `vertex`, or `nil` when no path reaches it
    /// (or every path is longer than the cutoff).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func distance(to vertex: G.Vertex) -> Distance? {
        distance(toIndex: _index(of: vertex))
    }

    /// Whether a path from a source reaches `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func hasPath(to vertex: G.Vertex) -> Bool {
        _parent[_index(of: vertex)] != Self._unreached
    }

    /// The vertex before `vertex` on its shortest path, or `nil` for a source and for a vertex not
    /// reached. On ties, and on a source that Bellman–Ford reached from another, see the type's
    /// documentation.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func parent(of vertex: G.Vertex) -> G.Vertex? {
        parent(ofIndex: _index(of: vertex)).map { _ids.vertex($0) }
    }

    /// The edge from `parent(of: vertex)` to `vertex`, which tells parallel edges apart, or `nil`
    /// for a source and for a vertex not reached.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func parentEdge(of vertex: G.Vertex) -> G.Edges.Index? {
        let i = _index(of: vertex)
        return _parent[i] >= 0 ? _parentEdge[i] : nil
    }

    /// A shortest path from a source to `vertex`, both included, with the edges it takes (which
    /// tell parallel edges apart): the trivial path `[vertex]` for a source, `nil` when `vertex` is
    /// not reached. O(length).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func path(to vertex: G.Vertex) -> Path<G.Vertex, G.Edges.Index>? {
        var i = _index(of: vertex)
        guard _parent[i] != Self._unreached else { return nil }
        var vertices = [_ids.vertex(i)]
        var edges: [G.Edges.Index] = []
        while _parent[i] >= 0 {
            edges.append(_parentEdge[i])
            i = _parent[i]
            vertices.append(_ids.vertex(i))
        }
        vertices.reverse()
        edges.reverse()
        // Parent pointers form a forest, so a tree path never repeats a vertex.
        return Path(_uncheckedVertices: vertices, edges: edges)
    }

    /// The distance to the vertex with index `index`, as `distance(to:)`. With vertex indices
    /// these are the graph's; otherwise positions in `vertices`.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func distance(toIndex index: Int) -> Distance? {
        precondition(index >= 0 && index < _parent.count, "Index \(index) is out of range 0..<\(_parent.count)")
        return _parent[index] == Self._unreached ? nil : _distance[index]
    }

    /// The index of the parent of the vertex with index `index`, as `parent(of:)`.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func parent(ofIndex index: Int) -> Int? {
        precondition(index >= 0 && index < _parent.count, "Index \(index) is out of range 0..<\(_parent.count)")
        let p = _parent[index]
        return p >= 0 ? p : nil
    }
}

extension ShortestPathTree: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Distance: Sendable {}

extension DirectedGraph {
    /// The distinct source indices, in the order given.
    ///
    /// - Precondition: `sources` is not empty, and each is a vertex.
    @inlinable
    func _sourceIndices(_ sources: some Sequence<Vertex>, _ ids: _VertexIdentifiers<Self>) -> (indices: [Int], vertices: [Vertex]) {
        var indices: [Int] = []
        var listed: [Vertex] = []
        if let only = sources as? CollectionOfOne<Vertex> {
            return ([_index(of: only.first!, ids)], [only.first!])
        }
        var seen = Set<Int>()
        for s in sources {
            let i = _index(of: s, ids)
            if seen.insert(i).inserted {
                indices.append(i)
                listed.append(s)
            }
        }
        precondition(!indices.isEmpty, "A shortest-path search needs at least one source")
        return (indices, listed)
    }
}
