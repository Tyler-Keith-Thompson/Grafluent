import Cliques
import GraphProtocols

/// k-clique percolation in index space: the maximal cliques (as ascending vertex numbers) of at
/// least k vertices, joined when they share k − 1 vertices; each group's vertices, ascending, the
/// groups in lexicographic order.
@inlinable
func _kCliquePercolation(_ cliques: [[Int]], count n: Int, k: Int) -> [[Int]] {
    let kept = cliques.filter { $0.count >= k }
    let c = kept.count
    // The cliques of each vertex, as a flat CSR.
    var start = [Int](repeating: 0, count: n + 1)
    for clique in kept { for v in clique { start[v + 1] += 1 } }
    for v in 0 ..< n { start[v + 1] += start[v] }
    var fill = start
    var member = [Int](repeating: 0, count: start[n])
    for (i, clique) in kept.enumerated() {
        for v in clique {
            member[fill[v]] = i
            fill[v] += 1
        }
    }
    var parent = Array(0 ..< c)
    func find(_ x: Int, _ parent: inout [Int]) -> Int {
        var x = x
        while parent[x] != x {
            parent[x] = parent[parent[x]]
            x = parent[x]
        }
        return x
    }
    var shared = [Int](repeating: 0, count: c)
    var stamp = [Int](repeating: -1, count: c)
    for i in 0 ..< c {
        for v in kept[i] {
            for slot in start[v] ..< start[v + 1] {
                let j = member[slot]
                guard j > i else { continue }
                if stamp[j] != i {
                    stamp[j] = i
                    shared[j] = 0
                }
                shared[j] += 1
                if shared[j] == k - 1 {
                    let a = find(i, &parent), b = find(j, &parent)
                    if a != b { parent[max(a, b)] = min(a, b) }
                }
            }
        }
    }
    // Each group's vertices, sorted and deduplicated.
    var group = [Int](repeating: -1, count: c)
    var groups: [[Int]] = []
    for i in 0 ..< c {
        let root = find(i, &parent)
        if group[root] < 0 {
            group[root] = groups.count
            groups.append([])
        }
        groups[group[root]].append(contentsOf: kept[i])
    }
    for g in groups.indices {
        groups[g].sort()
        var unique = 0
        for v in groups[g] where unique == 0 || groups[g][unique - 1] != v {
            groups[g][unique] = v
            unique += 1
        }
        groups[g].removeLast(groups[g].count - unique)
    }
    groups.sort { $0.lexicographicallyPrecedes($1) }
    return groups
}

extension Graph {
    /// k-clique communities by clique percolation (Palla, Derényi, Farkas and Vicsek 2005): the
    /// unions of k-cliques that can be reached from one another through k-cliques sharing k − 1
    /// vertices. Communities can overlap, and a vertex in no k-clique is in none. Computed from the
    /// maximal cliques of at least k vertices (`maximalCliques()`), two joined when they share at
    /// least k − 1 vertices. Self-loops and parallel edges are ignored.
    ///
    /// - Parameter k: the clique size, at least 2 (k = 2 gives the components with an edge).
    /// - Returns: the communities, each in `vertices` order, in lexicographic order of their vertex
    ///   numbers (by least vertex first).
    /// - Complexity: the maximal clique enumeration, then O(Σ_C Σ_{v ∈ C} c_v) for the cliques C
    ///   kept, c_v the number of kept cliques containing v.
    /// - Precondition: `k` is at least 2.
    @inlinable
    public func kCliqueCommunities(_ k: Int) -> [[Vertex]] {
        precondition(k >= 2, "k-clique communities need k of at least 2")
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let cliques = maximalCliques().map { clique in
            clique.map { _communityNumber(of: $0, numbers)! }.sorted()
        }
        return _kCliquePercolation(cliques, count: vertexCount, k: k).map { group in
            group.map { listed?[$0] ?? vertex(atIndex: $0) }
        }
    }
}
