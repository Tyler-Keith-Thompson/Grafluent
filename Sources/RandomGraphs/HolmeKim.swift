import AdjacencyListModule
import GraphProtocols
import NamedGraphs

/// Holme–Kim growth from m isolated vertices. `repeated` holds each vertex once per edge end (the
/// first m once each). New vertex s draws `repeated[below(count)]` until it has m distinct
/// candidates, which it takes in ascending order. Its first edge goes to the first candidate t; each
/// later one, with probability p, goes to a uniform neighbor of t not yet joined to s (neighbors in
/// the order their edges were added), and otherwise, or when there is none, to the next candidate
/// not yet joined to s. The uniform neighbor is `below(open)`-th of t's list once the excluded
/// entries are skipped: s itself, last in t's list, and each neighbor of s found in t's list by the
/// position table, so a triangle step costs O(m log m), not t's degree. Pairs: undirected (t, s),
/// directed s → t, both sorted.
@inlinable
func _holmeKimPairs<G: RandomNumberGenerator>(_ n: Int, _ m: Int, _ p: Double, directed: Bool, _ g: inout G) -> [DirectedEdge<Int>] {
    _checkCount(n)
    precondition(m >= 1 && m <= n, "edgesPerVertex \(m) is not in 1...\(n)")
    _checkProbability(p, "triangleProbability")
    precondition(_productFits(m, n - m) && m * (n - m) <= Int.max / 4, "edge count overflows Int")
    let edgeCount = m * (n - m)
    var pairs: [DirectedEdge<Int>] = []
    pairs.reserveCapacity(edgeCount)
    var repeated = Array(0 ..< m)
    repeated.reserveCapacity(m + 2 * edgeCount)
    // Each vertex's neighbors in the order their edges were added, and `position[(a, b)]` the index
    // of b in a's list.
    var neighbors = [[Int]](repeating: [], count: n)
    var position = _SlotPairTable<Int>(minimumCapacity: p > 0 ? 2 * edgeCount : 0)
    // `joined[v] == s` while v is a neighbor of the new vertex s, `chosen[v] == s` while v is one
    // of its candidates.
    var joined = [Int](repeating: -1, count: n)
    var chosen = [Int](repeating: -1, count: n)
    var candidates: [Int] = []
    candidates.reserveCapacity(m)
    var excluded: [Int] = []
    excluded.reserveCapacity(m)
    for s in m ..< n {
        candidates.removeAll(keepingCapacity: true)
        let count = repeated.count
        while candidates.count < m {
            let t = repeated[_below(count, &g)]
            if chosen[t] != s {
                chosen[t] = s
                candidates.append(t)
            }
        }
        if m <= 16 {
            for a in 1 ..< m {
                let value = candidates[a]
                var b = a
                while b > 0, candidates[b - 1] > value {
                    candidates[b] = candidates[b - 1]
                    b -= 1
                }
                candidates[b] = value
            }
        } else {
            candidates.sort()
        }
        var cursor = 0
        var target = -1
        for step in 0 ..< m {
            var w = -1
            if step > 0, _uniform01(&g) < p {
                // The entries of t's list that are not open: s, and the neighbors of s in it.
                excluded.removeAll(keepingCapacity: true)
                excluded.append(neighbors[target].count - 1)
                for x in neighbors[s] where x != target {
                    if let i = position[_SlotPair(target, x)] { excluded.append(i) }
                }
                let open = neighbors[target].count - excluded.count
                if open > 0 {
                    var i = _below(open, &g)
                    // The i-th open entry: step past each excluded one at or before it, in order.
                    for a in 1 ..< excluded.count {
                        let value = excluded[a]
                        var b = a
                        while b > 0, excluded[b - 1] > value {
                            excluded[b] = excluded[b - 1]
                            b -= 1
                        }
                        excluded[b] = value
                    }
                    for e in excluded {
                        guard e <= i else { break }
                        i += 1
                    }
                    w = neighbors[target][i]
                }
            }
            if w < 0 {
                // The next candidate not yet joined; there is always one (see holmeKim).
                while joined[candidates[cursor]] == s { cursor += 1 }
                w = candidates[cursor]
                cursor += 1
                target = w
            }
            joined[w] = s
            // The edge s – w at the end of both ends' lists.
            if p > 0 {
                position.insert(_SlotPair(s, w), neighbors[s].count)
                position.insert(_SlotPair(w, s), neighbors[w].count)
            }
            neighbors[s].append(w)
            neighbors[w].append(s)
            repeated.append(w)
            pairs.append(directed ? DirectedEdge(from: s, to: w) : DirectedEdge(from: w, to: s))
        }
        repeated.append(contentsOf: repeatElement(s, count: m))
    }
    return _sortedRowMajor(n, pairs)
}

extension _GraphConstruction {
    /// The Holme–Kim graph: Barabási–Albert growth with triangle formation, which gives a
    /// power-law degree distribution with a tunable clustering coefficient.
    ///
    /// > Petter Holme and Beom Jun Kim. Growing scale-free networks with tunable clustering.
    /// > *Physical Review E* 65, 026107 (2002). doi:10.1103/PhysRevE.65.026107
    ///
    /// It starts from m isolated vertices, and each new vertex s in `m..<n` makes m edges. It first
    /// draws m distinct candidates, each with probability proportional to its degree (the first m
    /// vertices once each), from the list that holds each vertex once per edge end, and takes them
    /// in ascending order. Its first edge goes to the first candidate t. Each later edge is, with
    /// probability `triangleProbability`, a triangle step: an edge to a uniform neighbor of t that s
    /// is not yet joined to, if there is one. Otherwise it is a preferential step, to the next
    /// candidate s is not yet joined to, which becomes the new t. Every vertex after the first m has
    /// m older neighbors, so the result has m(n − m) edges. p = 0 is the Barabási–Albert process on
    /// this start.
    ///
    /// - Complexity: O(n·m²) expected: O(m) expected per preferential step, O(m log m) per
    ///   triangle step.
    /// - Precondition: `edgesPerVertex` in `1...vertexCount`, and `triangleProbability` in 0...1.
    @inlinable
    public static func holmeKim(
        vertexCount n: Int, edgesPerVertex m: Int, triangleProbability p: Double, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexCount: n, sortedEdges: _holmeKimPairs(n, m, p, directed: false, &generator).lazy.map(_undirected), _ConstructionToken())
    }

    /// `holmeKim(vertexCount:edgesPerVertex:triangleProbability:using:)` with the system's random
    /// number generator.
    @inlinable
    public static func holmeKim(vertexCount n: Int, edgesPerVertex m: Int, triangleProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return holmeKim(vertexCount: n, edgesPerVertex: m, triangleProbability: p, using: &generator)
    }
}

extension _DirectedGraphConstruction {
    /// The Holme–Kim graph with each edge directed from the newer vertex to the older one. It
    /// makes the same draws as the undirected form, and each vertex after the first m has
    /// out-degree m.
    ///
    /// - Complexity: as for the undirected form.
    /// - Precondition: `edgesPerVertex` in `1...vertexCount`, and `triangleProbability` in 0...1.
    @inlinable
    public static func holmeKim(
        vertexCount n: Int, edgesPerVertex m: Int, triangleProbability p: Double, using generator: inout some RandomNumberGenerator
    ) -> Self {
        Self(_vertexCount: n, sortedEdges: _holmeKimPairs(n, m, p, directed: true, &generator), _ConstructionToken())
    }

    /// `holmeKim(vertexCount:edgesPerVertex:triangleProbability:using:)` with the system's random
    /// number generator.
    @inlinable
    public static func holmeKim(vertexCount n: Int, edgesPerVertex m: Int, triangleProbability p: Double) -> Self {
        var generator = SystemRandomNumberGenerator()
        return holmeKim(vertexCount: n, edgesPerVertex: m, triangleProbability: p, using: &generator)
    }
}
