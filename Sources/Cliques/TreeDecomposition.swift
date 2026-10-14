import GraphProtocols
import PriorityQueueModule

/// A tree decomposition of a graph: bags of vertices, joined by edges into a tree, such that
/// every vertex is in a bag, both ends of every edge are together in a bag, and the bags holding
/// any one vertex form a connected subtree.
///
/// The heuristics (`treewidthMinDegree()`, `treewidthMinFillIn()`) eliminate vertices one at a
/// time and stop when the rest form a clique. `bags[0]` is that clique, the root; `bags[i]` for
/// i ≥ 1 is the i-th vertex eliminated with its neighbors at the time, and it is joined to the
/// bag of the first of those neighbors to be eliminated after it, or to the root.
@frozen
public struct TreeDecomposition<Vertex: Hashable> {
    /// The bags, each listing its vertices in the graph's vertex order.
    public let bags: [[Vertex]]

    /// The tree's edges, between positions in `bags`: `bags.count - 1` of them in a
    /// decomposition the heuristics return.
    public let edges: [UndirectedEdge<Int>]

    /// A decomposition with these bags and tree edges, unchecked; `isTreeDecomposition(_:)`
    /// checks one against a graph.
    @inlinable
    public init(bags: [[Vertex]], edges: [UndirectedEdge<Int>]) {
        self.bags = bags
        self.edges = edges
    }

    /// One less than the size of the largest bag: an upper bound on the graph's treewidth. −1
    /// when every bag is empty, as for the empty graph.
    @inlinable
    public var width: Int { (bags.lazy.map(\.count).max() ?? 0) - 1 }
}

/// Two decompositions are equal when they list the same bags and edges in the same order.
extension TreeDecomposition: Hashable {}
extension TreeDecomposition: Sendable where Vertex: Sendable {}

/// Eliminates vertices of the simple graph `rows` one at a time, by least degree or by least
/// fill-in, until the remaining vertices form a clique, and builds the decomposition in index
/// space: the bags (the remaining clique first, each bag sorted) and each later bag's parent.
///
/// Least degree takes the least vertex among ties. Least fill-in scans the vertices by degree,
/// in index order within a degree, and takes the first of least fill-in, stopping early at
/// fill-in zero: NetworkX's `min_fill_in_heuristic` on a graph whose nodes are in index order.
@inlinable
func _eliminationDecomposition(_ rows: _CompressedRows, minimumFillIn: Bool) -> (bags: [[Int]], parents: [Int]) {
    let n = rows.count
    var adjacency = (0 ..< n).map { v in Array(rows.targets[rows.offsets[v] ..< rows.offsets[v + 1]]) }
    var alive = [Bool](repeating: true, count: n)
    var stamp = [Int](repeating: -1, count: n)
    var eliminated: [Int] = []
    var neighborhoods: [[Int]] = []
    var remaining = n
    // Least degree: priority degree · n + vertex, so least degree, then least vertex.
    var queue = IndexedPriorityQueue<Int>(indexBound: minimumFillIn ? 0 : n)
    if !minimumFillIn {
        for v in 0 ..< n { queue.insert(v, priority: rows.degree(v) &* n &+ v) }
    }
    // Least fill-in: the alive vertices bucketed by degree, each bucket in index order.
    var byDegree: [Int] = []
    var bucketStart = [Int](repeating: 0, count: n + 1)
    var round = 0
    while remaining > 0 {
        var v = -1
        if minimumFillIn {
            for d in bucketStart.indices { bucketStart[d] = 0 }
            for u in 0 ..< n where alive[u] { bucketStart[adjacency[u].count + 1] += 1 }
            for d in 0 ..< n { bucketStart[d + 1] += bucketStart[d] }
            byDegree = [Int](repeating: 0, count: remaining)
            for u in 0 ..< n where alive[u] {
                byDegree[bucketStart[adjacency[u].count]] = u
                bucketStart[adjacency[u].count] += 1
            }
            if adjacency[byDegree[0]].count == remaining - 1 { break }
            // Twice the fill-in: each missing pair counted from both ends.
            var best = Int.max
            for u in byDegree {
                round += 1
                let around = adjacency[u]
                for w in around { stamp[w] = round }
                var missing = 0
                for w in around {
                    var shared = 0
                    for x in adjacency[w] where stamp[x] == round { shared += 1 }
                    missing += around.count - 1 - shared
                    if best != Int.max && missing >= best { break }
                }
                if missing < best {
                    best = missing
                    v = u
                    if missing == 0 { break }
                }
            }
        } else {
            guard let (u, _) = queue.min, adjacency[u].count != remaining - 1 else { break }
            v = u
            queue.remove(u)
        }
        let around = adjacency[v]
        // Make `around` a clique, and drop `v` from its neighbors' rows.
        for u in around {
            round += 1
            for w in adjacency[u] { stamp[w] = round }
            for w in around where w != u && stamp[w] != round { adjacency[u].append(w) }
            let k = adjacency[u].firstIndex(of: v)!
            adjacency[u].swapAt(k, adjacency[u].count - 1)
            adjacency[u].removeLast()
            if !minimumFillIn { queue.updatePriority(of: u, to: adjacency[u].count &* n &+ u) }
        }
        adjacency[v] = []
        alive[v] = false
        remaining -= 1
        eliminated.append(v)
        neighborhoods.append(around)
    }
    // Bag 0 is the clique left; bag i + 1 the i-th eliminated vertex with its neighborhood,
    // joined to the bag of the neighbor eliminated first after it, or to bag 0.
    var step = [Int](repeating: -1, count: n)
    for (i, v) in eliminated.enumerated() { step[v] = i }
    var bags: [[Int]] = [(0 ..< n).filter { alive[$0] }]
    var parents = [-1]
    bags.reserveCapacity(eliminated.count + 1)
    parents.reserveCapacity(eliminated.count + 1)
    for (i, v) in eliminated.enumerated() {
        let around = neighborhoods[i]
        var next = -1
        for u in around where step[u] >= 0 && (next < 0 || step[u] < step[next]) { next = u }
        bags.append(([v] + around).sorted())
        parents.append(next < 0 ? 0 : step[next] + 1)
    }
    return (bags, parents)
}

extension Graph {
    /// A tree decomposition by the minimum-degree heuristic: repeatedly eliminate a vertex of
    /// least degree in the graph as filled in so far, the vertex earliest in `vertices` among
    /// ties, making its neighbors a clique; stop when the remaining vertices form a clique. Its
    /// `width` is an upper bound on the treewidth.
    ///
    /// Self-loops and parallel edges are ignored. NetworkX's `treewidth_min_degree` follows the
    /// same rule but breaks ties among equal degrees in another order.
    ///
    /// - Complexity: O(n (w² + Δ⁺) + n w log n), where w is the width found and Δ⁺ the largest
    ///   degree once the fill edges are added.
    @inlinable
    public func treewidthMinDegree() -> TreeDecomposition<Vertex> {
        _treeDecomposition(minimumFillIn: false)
    }

    /// A tree decomposition by the minimum fill-in heuristic: repeatedly eliminate the vertex
    /// whose neighbors lack the fewest edges to form a clique, making them one; stop when the
    /// remaining vertices form a clique. Its `width` is an upper bound on the treewidth, and is
    /// the treewidth of a chordal graph.
    ///
    /// Among vertices of equal fill-in, the one of least degree, then earliest in `vertices`, is
    /// taken: the rule of NetworkX's `treewidth_min_fill_in` for a graph whose nodes are in the
    /// same order. Self-loops and parallel edges are ignored.
    ///
    /// - Complexity: O(n (n + Σ_v d(v)²)) in the graph as filled in.
    @inlinable
    public func treewidthMinFillIn() -> TreeDecomposition<Vertex> {
        _treeDecomposition(minimumFillIn: true)
    }

    @inlinable
    func _treeDecomposition(minimumFillIn: Bool) -> TreeDecomposition<Vertex> {
        let (bags, parents) = _eliminationDecomposition(_simpleRows(), minimumFillIn: minimumFillIn)
        let listed = _listedVertices()
        let edges = (1 ..< max(bags.count, 1)).map { UndirectedEdge($0, parents[$0]) }
        return TreeDecomposition(bags: bags.map { $0.map { _vertex(number: $0, listed) } }, edges: edges)
    }

    /// Whether `decomposition` is a tree decomposition of this graph: at least one bag; its
    /// edges join distinct bags and form a tree on them; every vertex in a bag is a vertex of the
    /// graph, and every vertex of the graph is in a bag; both ends of every edge other than a
    /// self-loop are together in some bag; and the bags holding any one vertex form a connected
    /// subtree.
    ///
    /// - Complexity: O(n + m + B + Σ |bag| + m · b), where B is the number of bags and b the most
    ///   bags any vertex is in.
    @inlinable
    public func isTreeDecomposition(_ decomposition: TreeDecomposition<Vertex>) -> Bool {
        let bagCount = decomposition.bags.count
        guard bagCount > 0, decomposition.edges.count == bagCount - 1 else { return false }
        // The tree: B − 1 edges between bags, connecting them all, so no cycle.
        var tree = [[Int]](repeating: [], count: bagCount)
        for edge in decomposition.edges {
            guard edge.u != edge.v, (0 ..< bagCount).contains(edge.u), (0 ..< bagCount).contains(edge.v) else { return false }
            tree[edge.u].append(edge.v)
            tree[edge.v].append(edge.u)
        }
        var seen = [Bool](repeating: false, count: bagCount)
        var stack = [0]
        seen[0] = true
        var reached = 1
        while let b = stack.popLast() {
            for c in tree[b] where !seen[c] {
                seen[c] = true
                reached += 1
                stack.append(c)
            }
        }
        guard reached == bagCount else { return false }
        // The bags of each vertex, by vertex number.
        let numbering = _vertexNumbering()
        let n = vertexCount
        var holding = [[Int]](repeating: [], count: n)
        for (b, bag) in decomposition.bags.enumerated() {
            for vertex in bag {
                let v: Int
                if let numbering {
                    guard let number = numbering.numbers[vertex] else { return false }
                    v = number
                } else {
                    guard contains(vertex) else { return false }
                    v = vertexIndex(of: vertex)
                }
                // A vertex listed twice in one bag counts once.
                if holding[v].last != b { holding[v].append(b) }
            }
        }
        // Each vertex's bags connected in the tree: a search from its first bag through bags
        // holding it reaches them all.
        var inSet = [Int](repeating: -1, count: bagCount)
        var visited = [Int](repeating: -1, count: bagCount)
        for v in 0 ..< n {
            let bags = holding[v]
            guard let start = bags.first else { return false }
            for b in bags { inSet[b] = v }
            visited[start] = v
            stack = [start]
            var count = 1
            while let b = stack.popLast() {
                for c in tree[b] where inSet[c] == v && visited[c] != v {
                    visited[c] = v
                    count += 1
                    stack.append(c)
                }
            }
            guard count == bags.count else { return false }
        }
        // Every edge's ends share a bag: the bags of each are sorted, so merge them.
        let rows = _simpleRows()
        for u in 0 ..< n {
            for k in rows.offsets[u] ..< rows.offsets[u + 1] {
                let w = rows.targets[k]
                guard u < w else { continue }
                let a = holding[u], b = holding[w]
                var i = 0, j = 0
                var shared = false
                while i < a.count && j < b.count {
                    if a[i] == b[j] {
                        shared = true
                        break
                    }
                    if a[i] < b[j] { i += 1 } else { j += 1 }
                }
                guard shared else { return false }
            }
        }
        return true
    }
}
