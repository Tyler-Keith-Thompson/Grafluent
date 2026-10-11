import GraphProtocols
import Trees

/// The vertex count of the balanced tree: 1 + r + r² + … + r^h, the levels summed until one is
/// empty (r = 0 stops after the root).
@usableFromInline
func _balancedTreeVertexCount(_ r: Int, _ h: Int) -> Int {
    _checkCount(r, "branchingFactor")
    _checkCount(h, "height")
    var n = 1, level = 1
    for _ in 0 ..< h {
        guard level > 0 else { break }
        precondition(_productFits(level, r), "vertex count overflows Int")
        level *= r
        precondition(n <= Int.max - level, "vertex count overflows Int")
        n += level
    }
    return n
}

/// The balanced tree's edges, parent first: vertex c > 0 is a child of (c − 1)/r, so the children
/// of p are r·p + 1 … r·p + r, and the edges in child order are in lexicographic order.
@usableFromInline
func _balancedTreePairs(_ r: Int, _ h: Int) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    let n = _balancedTreeVertexCount(r, h)
    return (n, (1 ..< n).map { DirectedEdge(from: ($0 - 1) / r, to: $0) })
}

extension _GraphConstruction {
    /// The balanced tree: every vertex above the last level has `branchingFactor` children, down to
    /// `height` levels below the root (NetworkX `balanced_tree(r, h)`, igraph `Tree(n, r)`). Vertices
    /// in breadth-first order: root 0, and the children of p are r·p + 1 … r·p + r. (r^(h+1) − 1)/(r − 1)
    /// vertices (h + 1 when r = 1, and the root alone when r = 0 or h = 0), one fewer edges,
    /// sorted. As a `Tree`, `Tree.balancedTree(branchingFactor:height:)`. O(n).
    ///
    /// - Precondition: `branchingFactor ≥ 0` and `height ≥ 0`, and the vertex count fits in `Int`.
    @inlinable
    public static func balancedTree(branchingFactor r: Int, height h: Int) -> Self {
        let (n, pairs) = _balancedTreePairs(r, h)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The balanced tree with every edge from parent to child (NetworkX `balanced_tree(r, h,
    /// create_using=nx.DiGraph)`): the out-tree from root 0, in row-major order. O(n).
    ///
    /// - Precondition: `branchingFactor ≥ 0` and `height ≥ 0`, and the vertex count fits in `Int`.
    @inlinable
    public static func balancedTree(branchingFactor r: Int, height h: Int) -> Self {
        let (n, pairs) = _balancedTreePairs(r, h)
        return Self(_vertexCount: n, sortedEdges: pairs, _ConstructionToken())
    }
}

extension Tree where Vertex == Int {
    /// The balanced tree as a tree: edge k joins vertex k + 1 to its parent k/r, numbered as
    /// `balancedTree(branchingFactor:height:)` on the representations. Built on the dense layout
    /// with no vertex dictionary, as `Tree.path(vertexCount:)` is. O(n).
    ///
    /// - Precondition: `branchingFactor ≥ 0` and `height ≥ 0`, and the vertex count fits in `Int`.
    @inlinable
    public static func balancedTree(branchingFactor r: Int, height h: Int) -> Tree {
        let n = _balancedTreeVertexCount(r, h)
        var ends: [Int] = []
        ends.reserveCapacity(2 * (n - 1))
        for c in 1 ..< n {
            ends.append((c - 1) / r)
            ends.append(c)
        }
        return Tree(_vertexCount: n, treeEnds: ends)
    }
}
