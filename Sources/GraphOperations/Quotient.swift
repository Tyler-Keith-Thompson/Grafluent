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
    /// vertex of b (NetworkX's `quotient_graph`; igraph's `contract_vertices` then `simplify`).
    /// Also called vertex contraction. Block `i` is vertex `i`; an empty block is an isolated
    /// vertex; arcs inside a block vanish, and parallel crossings merge.
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
}

extension _GraphConstruction {
    /// The quotient of `graph` by a partition of its vertices: a vertex for each block, and an
    /// edge between two blocks when some edge of the graph joins them (NetworkX's
    /// `quotient_graph`). Block `i` is vertex `i`; edges inside a block vanish, and parallel
    /// crossings merge.
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
}
