import GraphProtocols
import Trees

// Binomial trees and full r-ary trees. Both list their edges parent first, in lexicographic
// order, so the undirected form maps them and the directed form takes them as they are.

/// The binomial tree B_k on 2^k vertices: the parent of v > 0 is v with its lowest set bit
/// cleared, so the children of p are p + 2^j for every 2^j below p's lowest set bit (every 2^j
/// below 2^k for the root), ascending.
@usableFromInline
func _binomialTreePairs(_ k: Int) -> (vertexCount: Int, pairs: [DirectedEdge<Int>]) {
    precondition(k >= 0, "order \(k) is negative")
    precondition(k <= Int.bitWidth - 2, "2^\(k) vertices overflow Int")
    let n = 1 << k
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(n - 1)
    for p in 0 ..< n {
        let below = p == 0 ? k : p.trailingZeroBitCount
        for j in 0 ..< below { pairs.append(DirectedEdge(from: p, to: p + (1 << j))) }
    }
    return (n, pairs)
}

/// The full r-ary tree on n vertices in breadth-first order: the parent of c > 0 is (c − 1)/r.
@usableFromInline
func _fullRaryTreePairs(_ r: Int, _ n: Int) -> [DirectedEdge<Int>] {
    precondition(r >= 1, "branchingFactor \(r) < 1")
    _checkCount(n)
    guard n >= 2 else { return [] }
    return (1 ..< n).map { DirectedEdge(from: ($0 - 1) / r, to: $0) }
}

extension _GraphConstruction {
    /// The binomial tree B_k of `order` k: B₀ is one vertex, and B_k is two copies of B_{k−1},
    /// on `0..<2^(k−1)` and `2^(k−1)..<2^k`, with an edge between their roots 0 and 2^(k−1). So
    /// the parent of v > 0 is v with its lowest set bit cleared, `v & (v − 1)`. 2^k vertices,
    /// one fewer edges, sorted; vertex 0 has degree k. As a `Tree`, `Tree.binomialTree(order:)`.
    /// O(n).
    ///
    /// - Precondition: 0 ≤ `order` ≤ 62.
    @inlinable
    public static func binomialTree(order k: Int) -> Self {
        let (n, pairs) = _binomialTreePairs(k)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }

    /// The full r-ary tree on `vertexCount` vertices: vertices in breadth-first order, root 0,
    /// and the children of p are r·p + 1 … r·p + r, as many as there are vertices. Every level
    /// is full but the last, which is filled from the left. n − 1 edges (none when n ≤ 1),
    /// sorted. `balancedTree(branchingFactor:height:)` is the case where the last level is full.
    /// As a `Tree`, `Tree.fullRaryTree(branchingFactor:vertexCount:)`. O(n).
    ///
    /// - Precondition: `branchingFactor ≥ 1` and `vertexCount ≥ 0`.
    @inlinable
    public static func fullRaryTree(branchingFactor r: Int, vertexCount n: Int) -> Self {
        let pairs = _fullRaryTreePairs(r, n)
        return Self(_vertexCount: n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())
    }
}

extension _DirectedGraphConstruction {
    /// The binomial tree with every edge directed from parent to child, in row-major order.
    /// O(n).
    ///
    /// - Precondition: 0 ≤ `order` ≤ 62.
    @inlinable
    public static func binomialTree(order k: Int) -> Self {
        let (n, pairs) = _binomialTreePairs(k)
        return Self(_vertexCount: n, sortedEdges: pairs, _ConstructionToken())
    }

    /// The full r-ary tree with every edge directed from parent to child: the out-tree from root
    /// 0, in row-major order. O(n).
    ///
    /// - Precondition: `branchingFactor ≥ 1` and `vertexCount ≥ 0`.
    @inlinable
    public static func fullRaryTree(branchingFactor r: Int, vertexCount n: Int) -> Self {
        let pairs = _fullRaryTreePairs(r, n)
        return Self(_vertexCount: n, sortedEdges: pairs, _ConstructionToken())
    }
}

extension Tree where Vertex == Int {
    /// The binomial tree as a tree, numbered as `binomialTree(order:)` on the representations,
    /// with its edges in the same sorted order. Uses the dense layout with no vertex dictionary.
    /// O(n).
    ///
    /// - Precondition: 0 ≤ `order` ≤ 62.
    @inlinable
    public static func binomialTree(order k: Int) -> Tree {
        let (n, pairs) = _binomialTreePairs(k)
        var ends: [Int] = []
        ends.reserveCapacity(2 * (n - 1))
        for pair in pairs {
            ends.append(pair.source)
            ends.append(pair.target)
        }
        return Tree(_vertexCount: n, treeEnds: ends)
    }

    /// The full r-ary tree as a tree: edge k − 1 joins vertex k to its parent (k − 1)/r, numbered
    /// as `fullRaryTree(branchingFactor:vertexCount:)` on the representations. O(n).
    ///
    /// - Precondition: `branchingFactor ≥ 1` and `vertexCount ≥ 1`: a tree is never empty.
    @inlinable
    public static func fullRaryTree(branchingFactor r: Int, vertexCount n: Int) -> Tree {
        precondition(r >= 1, "branchingFactor \(r) < 1")
        precondition(n >= 1, "a Tree has at least one vertex")
        var ends: [Int] = []
        ends.reserveCapacity(2 * (n - 1))
        for c in 1 ..< n {
            ends.append((c - 1) / r)
            ends.append(c)
        }
        return Tree(_vertexCount: n, treeEnds: ends)
    }
}
