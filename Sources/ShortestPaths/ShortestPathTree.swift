import GraphProtocols
import Trees
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
/// **Several sources.** Each source starts at distance zero (`.one` over a semiring) with no parent. Dijkstra's algorithm
/// and breadth-first search never improve on that, so a source keeps no parent even when another
/// source reaches it. Bellman–Ford treats the sources as one super-source (NetworkX's
/// `_bellman_ford`): a negative path from one source to another improves the second, which then
/// has that distance, a parent and a path from the first.
///
/// **Semirings.** Over a `SelectiveSemiring` a distance is the ⊗-product of a path's weights, the
/// best by the natural order `<`, and a vertex is reached exactly when its distance is not `.zero`.
///
/// Not `Equatable`: two correct trees can choose different parents on ties.
@frozen
public struct ShortestPathTree<G: DirectedGraph, Distance: Comparable> {
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
        _parentEdge(ofIndex: _index(of: vertex))
    }

    @inlinable
    func _parentEdge(ofIndex i: Int) -> G.Edges.Index? {
        _parent[i] >= 0 ? _parentEdge[i] : nil
    }

    /// A shortest path from a source to `vertex`, both included, with the edges it takes (which
    /// tell parallel edges apart): the trivial path `[vertex]` for a source, `nil` when `vertex` is
    /// not reached. O(length).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func path(to vertex: G.Vertex) -> Path<G.Vertex, G.Edges.Index>? {
        _path(toIndex: _index(of: vertex))
    }

    @inlinable
    func _path(toIndex index: Int) -> Path<G.Vertex, G.Edges.Index>? {
        var i = index
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

// MARK: - checked: lookups

// README Principle 6: `VertexNotFound` for a vertex that is not in the graph, where the trapping
// spellings are the fast path. Each makes the one lookup its trapping spelling makes; `try?` gives
// an Optional. A nil the trapping spelling returns (unreached, or a source) is still nil; `try?`
// flattens it with a missing vertex's, so a caller that must tell them apart catches.

extension ShortestPathTree {
    /// `distance(to: vertex)`, throwing instead of trapping when `vertex` is not a vertex of the
    /// graph: nil still means no path reaches it.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func distance(checkedTo vertex: G.Vertex) throws(VertexNotFound) -> Distance? {
        distance(toIndex: try _ids.graph._checkedIndex(of: vertex, _ids))
    }

    /// `hasPath(to: vertex)`, throwing instead of trapping when `vertex` is not a vertex of the
    /// graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func hasPath(checkedTo vertex: G.Vertex) throws(VertexNotFound) -> Bool {
        _parent[try _ids.graph._checkedIndex(of: vertex, _ids)] != Self._unreached
    }

    /// `parent(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex of the
    /// graph: nil still means a source or a vertex not reached.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func parent(checked vertex: G.Vertex) throws(VertexNotFound) -> G.Vertex? {
        parent(ofIndex: try _ids.graph._checkedIndex(of: vertex, _ids)).map { _ids.vertex($0) }
    }

    /// `parentEdge(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex of the
    /// graph: nil still means a source or a vertex not reached.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func parentEdge(checked vertex: G.Vertex) throws(VertexNotFound) -> G.Edges.Index? {
        _parentEdge(ofIndex: try _ids.graph._checkedIndex(of: vertex, _ids))
    }

    /// `path(to: vertex)`, throwing instead of trapping when `vertex` is not a vertex of the
    /// graph: nil still means `vertex` is not reached. O(length).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func path(checkedTo vertex: G.Vertex) throws(VertexNotFound) -> Path<G.Vertex, G.Edges.Index>? {
        _path(toIndex: try _ids.graph._checkedIndex(of: vertex, _ids))
    }
}

extension Arborescence {
    /// The shortest-path tree of a one-source search, as an arborescence rooted at the source:
    /// every reached vertex, each with its `parent(of:)` as parent (the tree LEMON's `predMap`
    /// encodes).
    ///
    /// Vertices are listed in the tree's index order (the indices of `distance(toIndex:)`, the
    /// graph's vertex indices when it has them), unreached ones left out, so the source need not
    /// come first. Edge positions are the arborescence's own, in vertex order: edge k leads to
    /// the k-th listed vertex other than the root, counting from 0. The graph's edge into a
    /// vertex stays `tree.parentEdge(of:)`. O(n); the vertices are hashed once, into the
    /// arborescence's lookup table, unless they are the `Int`s `0..<k` in order.
    ///
    /// - Precondition: `tree.sources.count == 1`. Several sources make a rooted forest, which
    ///   Trees has no type for; the source count is the caller's own argument to the search, so
    ///   asking for one root with several is a programming error, not a lookup that may miss.
    @inlinable
    public init<G: DirectedGraph, Distance>(_ tree: ShortestPathTree<G, Distance>) where G.Vertex == Vertex {
        precondition(tree.sources.count == 1, "An arborescence has one root; the shortest-path tree has \(tree.sources.count) sources")
        let parent = tree._parent
        let unreached = ShortestPathTree<G, Distance>._unreached
        // Each reached index's number in the arborescence.
        var number = [Int](repeating: -1, count: parent.count)
        var vertices = ContiguousArray<Vertex>()
        for i in parent.indices where parent[i] != unreached {
            number[i] = vertices.count
            vertices.append(tree._ids.vertex(i))
        }
        var parents = [Int](repeating: -1, count: vertices.count)
        for i in parent.indices where parent[i] >= 0 { parents[number[i]] = number[parent[i]] }
        self.init(vertices: vertices, parents: parents)
    }

    /// The shortest-path tree of a one-source search, as `init(_:)` builds it, throwing instead of
    /// trapping when the search had several sources: a shortest-path forest is then not a tree.
    /// `Forest(tree)` takes any number of sources. O(n).
    ///
    /// - Throws: `NotATree` unless `tree.sources.count == 1`.
    @inlinable
    public init<G: DirectedGraph, Distance>(checked tree: ShortestPathTree<G, Distance>) throws(NotATree) where G.Vertex == Vertex {
        guard tree.sources.count == 1 else { throw NotATree() }
        self.init(tree)
    }
}

extension Forest {
    /// The shortest-path forest of a search from any number of sources, with the edges'
    /// directions and the roots dropped: every reached vertex, in the tree's index order as
    /// `Arborescence(_:)` lists them (unreached ones left out), and one edge (parent, child) per
    /// reached vertex with a parent, in that order. Edge positions are the forest's own: edge k
    /// joins the k-th listed vertex with a parent to its parent; the graph's edge stays
    /// `tree.parentEdge(of:)`. The tree holds a copy of its graph, so none is passed, unlike
    /// `Forest(_:in:)` for a spanning forest. O(n); the vertices are hashed once, into the
    /// forest's lookup table, unless they are the `Int`s `0..<k` in order.
    @inlinable
    public init<G: DirectedGraph, Distance>(_ tree: ShortestPathTree<G, Distance>) where G.Vertex == Vertex {
        let parent = tree._parent
        let unreached = ShortestPathTree<G, Distance>._unreached
        var number = [Int](repeating: -1, count: parent.count)
        var vertices = ContiguousArray<Vertex>()
        for i in parent.indices where parent[i] != unreached {
            number[i] = vertices.count
            vertices.append(tree._ids.vertex(i))
        }
        var parents = [Int](repeating: -1, count: vertices.count)
        for i in parent.indices where parent[i] >= 0 { parents[number[i]] = number[parent[i]] }
        self.init(vertices: vertices, parents: parents)
    }
}

extension ShortestPathTree: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable, Distance: Sendable {}

extension DirectedGraph {
    /// The distinct source indices, in the order given; empty when `sources` is and `allowsEmpty`.
    ///
    /// - Precondition: each source is a vertex; `sources` is not empty unless `allowsEmpty`.
    @inlinable
    func _sourceIndices(_ sources: some Sequence<Vertex>, _ ids: _VertexIdentifiers<Self>, allowsEmpty: Bool = false) -> (indices: [Int], vertices: [Vertex]) {
        if let only = sources as? CollectionOfOne<Vertex> {
            return ([_index(of: only.first!, ids)], [only.first!])
        }
        var indices: [Int] = []
        var listed: [Vertex] = []
        var seen = Set<Int>()
        for s in sources {
            let i = _index(of: s, ids)
            if seen.insert(i).inserted {
                indices.append(i)
                listed.append(s)
            }
        }
        precondition(allowsEmpty || !indices.isEmpty, "A shortest-path search needs at least one source")
        return (indices, listed)
    }
}
