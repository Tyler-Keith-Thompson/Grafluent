import GraphProtocols

/// The block of every vertex index of a graph with `n` vertices, from a partition given as
/// blocks of vertices: one `index` call per listed vertex.
@inlinable
func _blocks<Blocks: Sequence>(
    count n: Int, _ partition: Blocks, index: (Blocks.Element.Element) -> Int
) -> (owner: [Int], count: Int) where Blocks.Element: Sequence {
    var owner = [Int](repeating: -1, count: n)
    var k = 0
    for block in partition {
        for vertex in block {
            let b = index(vertex)
            precondition(UInt(bitPattern: b) < UInt(bitPattern: n), "\(vertex) is not a vertex")
            precondition(owner[b] < 0, "\(vertex) is in two blocks")
            owner[b] = k
        }
        k += 1
    }
    precondition(!owner.contains(-1), "The blocks do not cover every vertex")
    return (owner, k)
}

/// The block of every vertex index of a graph, grouping vertices by `key`: block `k` is the
/// vertices sharing the `k`th distinct key in `vertices` order. One hash per vertex.
@inlinable
func _keyBlocks<G: DirectedGraph, Key: Hashable>(_ graph: G, count n: Int, _ key: (G.Vertex) -> Key) -> (owner: [Int], count: Int) {
    var owner = [Int](repeating: 0, count: n)
    var block: [Key: Int] = [:]
    for v in graph.vertices {
        let k = key(v)
        if let b = block[k] {
            owner[graph.vertexIndex(of: v)] = b
        } else {
            owner[graph.vertexIndex(of: v)] = block.count
            block[k] = block.count
        }
    }
    return (owner, block.count)
}

/// `_keyBlocks` for an undirected graph.
@inlinable
func _keyBlocks<G: Graph, Key: Hashable>(_ graph: G, count n: Int, _ key: (G.Vertex) -> Key) -> (owner: [Int], count: Int) {
    var owner = [Int](repeating: 0, count: n)
    var block: [Key: Int] = [:]
    for v in graph.vertices {
        let k = key(v)
        if let b = block[k] {
            owner[graph.vertexIndex(of: v)] = b
        } else {
            owner[graph.vertexIndex(of: v)] = block.count
            block[k] = block.count
        }
    }
    return (owner, block.count)
}

/// Pairs sorted row-major with repeats removed.
@inlinable
func _sortedUnique(_ pairs: inout [(Int, Int)]) {
    pairs.sort { $0 < $1 }
    var write = 0
    for read in pairs.indices where write == 0 || pairs[read] != pairs[write - 1] {
        pairs[write] = pairs[read]
        write += 1
    }
    pairs.removeLast(pairs.count - write)
}

extension _DirectedGraphConstruction {
    /// The quotient of `graph` by a partition of its vertices: a vertex for each block, and an
    /// arc from block a to block b ≠ a when some arc of the graph goes from a vertex of a to a
    /// vertex of b. Also called vertex contraction. Block `i` is vertex `i`, and an empty block is
    /// an isolated vertex. Arcs inside a block vanish, and parallel crossings merge.
    ///
    /// O(n + m + the sort), with one hash per listed vertex.
    ///
    /// - Precondition: the graph has vertex indices, and every vertex of the graph is in exactly
    ///   one block; every listed vertex is a vertex of the graph.
    @inlinable
    public static func quotient<G: DirectedGraph, Blocks: Sequence>(of graph: G, by partition: Blocks) -> Self
    where Blocks.Element: Sequence<G.Vertex> {
        let n = _requireIndices(graph.vertexIndexBound, "quotient(of:by:)")
        let (owner, k) = _blocks(count: n, partition) { graph.vertexIndex(of: $0) }
        var pairs: [(Int, Int)] = []
        for v in 0 ..< n {
            let a = owner[v]
            for w in graph.successorIndices(ofIndex: v) where owner[w] != a { pairs.append((a, owner[w])) }
        }
        _sortedUnique(&pairs)
        return Self(_vertexCount: k, sortedEdges: pairs.lazy.map { DirectedEdge(from: $0.0, to: $0.1) }, _ConstructionToken())
    }

    /// The quotient of `graph` by a key: the vertices with equal keys merge into one, and an arc
    /// goes from block a to block b ≠ a when some arc of the graph goes from a vertex of a to a
    /// vertex of b. Block `k` is the vertices sharing the `k`th distinct key in `vertices` order,
    /// and is vertex `k`. Arcs inside a block vanish, and parallel crossings merge.
    ///
    /// Merging duplicate entities of a knowledge graph is a quotient by a normalized name.
    ///
    /// O(n + m + the sort), with one hash per vertex; `key` is called once per vertex.
    ///
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public static func quotient<G: DirectedGraph, Key: Hashable>(of graph: G, byKey key: (G.Vertex) -> Key) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "quotient(of:byKey:)")
        let (owner, k) = _keyBlocks(graph, count: n, key)
        var pairs: [(Int, Int)] = []
        for v in 0 ..< n {
            let a = owner[v]
            for w in graph.successorIndices(ofIndex: v) where owner[w] != a { pairs.append((a, owner[w])) }
        }
        _sortedUnique(&pairs)
        return Self(_vertexCount: k, sortedEdges: pairs.lazy.map { DirectedEdge(from: $0.0, to: $0.1) }, _ConstructionToken())
    }
}

extension _GraphConstruction {
    /// The quotient of `graph` by a partition of its vertices: a vertex for each block, and an
    /// edge between two blocks when some edge of the graph joins them. Block `i` is vertex `i`.
    /// Edges inside a block vanish, and parallel crossings merge.
    ///
    /// O(n + m + the sort), with one hash per listed vertex.
    ///
    /// - Precondition: the graph has vertex indices, and every vertex of the graph is in exactly
    ///   one block; every listed vertex is a vertex of the graph.
    @inlinable
    public static func quotient<G: Graph, Blocks: Sequence>(of graph: G, by partition: Blocks) -> Self
    where Blocks.Element: Sequence<G.Vertex> {
        let n = _requireIndices(graph.vertexIndexBound, "quotient(of:by:)")
        let (owner, k) = _blocks(count: n, partition) { graph.vertexIndex(of: $0) }
        var pairs: [(Int, Int)] = []
        for v in 0 ..< n {
            let a = owner[v]
            for w in graph.neighborIndices(ofIndex: v) where a < owner[w] { pairs.append((a, owner[w])) }
        }
        _sortedUnique(&pairs)
        return Self(_vertexCount: k, sortedEdges: pairs.lazy.map { UndirectedEdge($0.0, $0.1) }, _ConstructionToken())
    }

    /// The quotient of `graph` by a key: the vertices with equal keys merge into one, and an edge
    /// joins two blocks when some edge of the graph joins them. Block `k` is the vertices sharing
    /// the `k`th distinct key in `vertices` order, and is vertex `k`. Edges inside a block vanish,
    /// and parallel crossings merge.
    ///
    /// Merging duplicate entities of a knowledge graph is a quotient by a normalized name.
    ///
    /// O(n + m + the sort), with one hash per vertex; `key` is called once per vertex.
    ///
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public static func quotient<G: Graph, Key: Hashable>(of graph: G, byKey key: (G.Vertex) -> Key) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "quotient(of:byKey:)")
        let (owner, k) = _keyBlocks(graph, count: n, key)
        var pairs: [(Int, Int)] = []
        for v in 0 ..< n {
            let a = owner[v]
            for w in graph.neighborIndices(ofIndex: v) where a < owner[w] { pairs.append((a, owner[w])) }
        }
        _sortedUnique(&pairs)
        return Self(_vertexCount: k, sortedEdges: pairs.lazy.map { UndirectedEdge($0.0, $0.1) }, _ConstructionToken())
    }
}
