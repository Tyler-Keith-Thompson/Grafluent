// Properties against oracles written inside each test, with shrinking (swift-property-based): on
// a failure, PropertyBased shrinks the generated input and prints the smallest one that still
// fails. Graphs are multigraphs with self-loops on 1 … 10 vertices listed in an order shuffled by a
// seed (so vertex numbers are not vertex values), on `ReferencePseudograph` and, with parallel
// edges collapsed, on `UndirectedAdjacencyList`; bipartite graphs have their sides interleaved in
// the vertex order, or are `BipartiteGraph`s with both sides inserted in shuffled orders. The
// oracles: every vertex subset (bit i of a mask is the vertex at index i) for the exact optima,
// their lexicographic rule and the least weights; every edge subset for the least edge cover; the
// definitions of the four checks; and api.md's procedures written out (Bar-Yehuda–Even, the greedy
// independent set, the greedy set cover, the edge cover from a matching, König's construction).
// See README.md.

import AdjacencyListModule
import BipartiteGraphs
import Covering
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import PropertyBased
import Testing

@Suite("Covering properties against oracles, with shrinking", .tags(.randomized))
struct CoveringPropertyTests {
    @Test("maximumIndependentSet() is the lexicographically least maximum independent set by brute force; minimumVertexCover() is its complement; α + τ = n")
    func exactIndependentSet() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 20)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            let context = "\(pairs) on \(listed)"
            // Brute force: of the independent subsets the largest, and of those the one holding the
            // least vertex of the symmetric difference.
            var best = -1
            for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
                let least = (mask ^ max(best, 0)).trailingZeroBitCount
                if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
            }
            let expected = (0 ..< n).filter { best & (1 << $0) != 0 }.map { listed[$0] }
            let independent = graph.maximumIndependentSet()
            #expect(independent == expected, "\(context)")
            #expect(graph.independenceNumber() == expected.count, "\(context)")
            let cover = graph.minimumVertexCover()
            #expect(cover == listed.filter { !expected.contains($0) }, "\(context)")
            #expect(graph.independenceNumber() + cover.count == n)
            #expect(graph.isIndependentSet(independent) && graph.isVertexCover(cover), "\(context)")
            // No vertex cover is smaller.
            var fewest = n
            for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) { fewest = min(fewest, mask.nonzeroBitCount) }
            #expect(cover.count == fewest, "\(context)")
            // A looped vertex is in every cover, and never independent.
            for (a, b) in ends where a == b { #expect(cover.contains(listed[a]) && !independent.contains(listed[a])) }
            // Parallel edges change nothing.
            let simple = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(simple.maximumIndependentSet() == expected, "\(context)")
            #expect(simple.minimumVertexCover() == cover, "\(context)")
        }
    }

    @Test("Bipartite graphs, sides interleaved in the vertex order: the lexicographic set by brute force; König's cover the unique minimum cover with the most left vertices, NetworkX's construction, as large as the maximum matching")
    func bipartiteCovers() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 16)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 6), Gen.int(in: 1 ... 6), Gen.int(in: 0 ... 1_000_000)) { raw, l, r, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let n = l + r
            // Left vertices 0..<l, right l..<n, all listed in one shuffled order.
            let pairs = raw.map { ($0.0 % l, l + $0.1 % r) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            let context = "\(pairs) on \(listed)"
            var best = -1
            for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
                let least = (mask ^ max(best, 0)).trailingZeroBitCount
                if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
            }
            let expected = (0 ..< n).filter { best & (1 << $0) != 0 }.map { listed[$0] }
            #expect(graph.maximumIndependentSet() == expected, "\(context)")
            let cover = graph.minimumVertexCover()
            #expect(cover == listed.filter { !expected.contains($0) }, "\(context)")
            guard let sides = graph.bipartition() else {
                Issue.record("not bipartite: \(context)")
                return
            }
            let matching = graph.maximumBipartiteMatching(bipartition: sides)
            #expect(cover.count == matching.edges.count, "König: \(context)")
            let koenig = graph.minimumVertexCover(bipartition: sides)
            #expect(koenig.count == matching.edges.count && graph.isVertexCover(koenig), "\(context)")
            #expect(koenig == listed.filter { koenig.contains($0) }, "in vertices order: \(context)")
            // NetworkX's construction: Z is every vertex reached from a free left vertex by an
            // alternating path; the cover is (left − Z) ∪ (right ∩ Z).
            let leftSide = Set(sides.left)
            var reached = Set(sides.left.filter { matching.mate(of: $0) == nil })
            var frontier = Array(reached)
            while let x = frontier.popLast() {
                if leftSide.contains(x) {
                    for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
                } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                    frontier.append(y)
                }
            }
            #expect(koenig == listed.filter { leftSide.contains($0) != reached.contains($0) }, "\(context)")
            // Brute force: of the minimum covers, exactly one has the most left vertices, and it is König's.
            let leftMask = sides.left.reduce(0) { $0 | (1 << index[$1]!) }
            var fewest = n + 1
            var minimumCovers: [Int] = []
            for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
                if mask.nonzeroBitCount < fewest {
                    fewest = mask.nonzeroBitCount
                    minimumCovers = []
                }
                if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
            }
            let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
            let koenigMask = koenig.reduce(0) { $0 | (1 << index[$1]!) }
            #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [koenigMask], "\(context)")
            // The same graph as a BipartiteGraph with its sides in shuffled orders: its own vertex
            // order (left, then right) decides the lexicographic rule.
            let leftOrder = Array(0 ..< l).shuffled(using: &rng)
            let rightOrder = Array(l ..< n).shuffled(using: &rng)
            guard let bipartite = BipartiteGraph(left: leftOrder, right: rightOrder, edges: pairs.map { UndirectedEdge($0.0, $0.1) }) else {
                Issue.record("not a bipartite graph: \(context)")
                return
            }
            let order = leftOrder + rightOrder
            let at = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
            let bipartiteEnds = pairs.map { (at[$0.0]!, at[$0.1]!) }
            var bipartiteBest = -1
            for mask in 0 ..< 1 << n where bipartiteEnds.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
                let least = (mask ^ max(bipartiteBest, 0)).trailingZeroBitCount
                if bipartiteBest < 0 || mask.nonzeroBitCount > bipartiteBest.nonzeroBitCount || (mask.nonzeroBitCount == bipartiteBest.nonzeroBitCount && mask & (1 << least) != 0) { bipartiteBest = mask }
            }
            let bipartiteExpected = (0 ..< n).filter { bipartiteBest & (1 << $0) != 0 }.map { order[$0] }
            #expect(bipartite.maximumIndependentSet() == bipartiteExpected, "\(context), left \(leftOrder), right \(rightOrder)")
            #expect(bipartite.minimumVertexCover().count == bipartite.maximumBipartiteMatching().edges.count)
        }
    }

    @Test("approximateMinimumVertexCover is Bar-Yehuda–Even in position order, written out: a cover within twice the least weight, Int and Double weights, the weight read once per vertex")
    func approximateVertexCover() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 18)
        let weights = Gen.int(in: 0 ... 5).array(of: 9)
        await propertyCheck(count: 400, input: edges, weights, Gen.int(in: 1 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, rawWeights, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            // Weights by vertex value.
            let weight = Array(rawWeights.prefix(n))
            let context = "\(pairs) on \(listed), weights \(weight)"
            // Bar-Yehuda–Even, written out: each edge in position order with neither end in the cover
            // takes its lesser-index end when that end's remaining cost is not greater, else the other,
            // and the other end's cost drops by the taken end's.
            func localRatio<W: Comparable & AdditiveArithmetic>(_ start: [W]) -> [Int] {
                var cost = start
                var inCover = [Bool](repeating: false, count: n)
                for (u, v) in ends {
                    let (a, b) = (min(u, v), max(u, v))
                    if inCover[a] || inCover[b] { continue }
                    if cost[a] <= cost[b] {
                        inCover[a] = true
                        cost[b] -= cost[a]
                    } else {
                        inCover[b] = true
                        cost[a] -= cost[b]
                    }
                }
                return (0 ..< n).filter { inCover[$0] }.map { listed[$0] }
            }
            var calls = 0
            let cover = graph.approximateMinimumVertexCover(weight: { (v: Int) -> Int in
                calls += 1
                return weight[v]
            })
            #expect(calls == n, "weight called \(calls) times for \(n) vertices")
            #expect(cover == localRatio(listed.map { weight[$0] }), "\(context)")
            #expect(graph.isVertexCover(cover), "\(context)")
            // Within twice the least weight of a vertex cover (brute force).
            var least = weight.reduce(0, +)
            for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
                least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weight[listed[$1]] : $0 })
            }
            #expect(cover.reduce(0) { $0 + weight[$1] } <= 2 * least, "\(context)")
            // Halved weights as Double follow the same subtractions exactly.
            let halves = graph.approximateMinimumVertexCover(weight: { (v: Int) -> Double in Double(weight[v]) / 2 })
            #expect(halves == localRatio(listed.map { Double(weight[$0]) / 2 }), "\(context)")
            // Unweighted: every weight 1; on a loop-free graph inside the ends of maximalMatching().
            let unweighted = graph.approximateMinimumVertexCover()
            #expect(unweighted == localRatio([Int](repeating: 1, count: n)), "\(context)")
            var fewest = n
            for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) { fewest = min(fewest, mask.nonzeroBitCount) }
            #expect(unweighted.count <= 2 * fewest, "\(context)")
            if ends.allSatisfy({ $0.0 != $0.1 }) {
                let matched = Set(graph.maximalMatching().edges.flatMap { [pairs[$0].0, pairs[$0].1] })
                #expect(unweighted.allSatisfy { matched.contains($0) }, "\(context)")
            }
        }
    }

    @Test("maximalIndependentSet(containing:) is the greedy pass in vertex order after the seeds: independent and maximal, or nil exactly when the seeds are not independent")
    func maximalIndependentSet() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 18)
        let seeds = Gen.int(in: 0 ... 9).array(of: 0 ... 4)
        await propertyCheck(count: 500, input: edges, seeds, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, rawSeeds, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            let given = rawSeeds.map { $0 % n }
            let context = "\(pairs) on \(listed), seeds \(given)"
            func adjacent(_ a: Int, _ b: Int) -> Bool { ends.contains { ($0.0 == a && $0.1 == b) || ($0.0 == b && $0.1 == a) } }
            // The greedy pass, written out: the seeds, then each vertex in index order that has no
            // self-loop and no neighbour in the set yet.
            func greedy(_ start: Set<Int>) -> [Int] {
                var set = start
                for v in 0 ..< n where !set.contains(v) && !adjacent(v, v) && !set.contains(where: { adjacent($0, v) }) { set.insert(v) }
                return set.sorted().map { listed[$0] }
            }
            let plain = graph.maximalIndependentSet()
            #expect(plain == greedy([]), "\(context)")
            #expect(graph.isIndependentSet(plain))
            let seedIndices = Set(given.map { index[$0]! })
            let feasible = seedIndices.allSatisfy { a in seedIndices.allSatisfy { b in !adjacent(a, b) } }
            let seeded = graph.maximalIndependentSet(containing: given)
            if feasible {
                #expect(seeded == greedy(seedIndices), "\(context)")
                if let set = seeded {
                    #expect(given.allSatisfy { set.contains($0) } && graph.isIndependentSet(set), "\(context)")
                    // Maximal: every vertex outside has a self-loop or a neighbour inside.
                    let inside = Set(set.map { index[$0]! })
                    for v in 0 ..< n where !inside.contains(v) { #expect(adjacent(v, v) || inside.contains { adjacent($0, v) }, "\(context)") }
                }
            } else {
                #expect(seeded == nil, "\(context)")
            }
        }
    }

    @Test("minimumDominatingSet() is the lexicographically least minimum dominating set by brute force; the greedy approximation is the eager set cover written out, within H(Δ + 1) of the least weight")
    func dominatingSets() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 16)
        let weights = Gen.int(in: 0 ... 4).array(of: 10)
        await propertyCheck(count: 300, input: edges, weights, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, rawWeights, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            let weight = Array(rawWeights.prefix(n))   // by vertex value
            let context = "\(pairs) on \(listed), weights \(weight)"
            // Closed neighbourhoods by index.
            let closed: [Set<Int>] = (0 ..< n).map { v in Set([v] + ends.filter { $0.0 == v }.map(\.1) + ends.filter { $0.1 == v }.map(\.0)) }
            // Brute force: the smallest dominating subsets, the lexicographically least of them, and the least weight.
            var best = -1
            var leastWeight = weight.reduce(0, +)
            for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ v in closed[v].contains { mask & (1 << $0) != 0 } }) {
                let least = (mask ^ max(best, 0)).trailingZeroBitCount
                if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
                leastWeight = min(leastWeight, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weight[listed[$1]] : $0 })
            }
            let exact = graph.minimumDominatingSet()
            #expect(exact == (0 ..< n).filter { best & (1 << $0) != 0 }.map { listed[$0] }, "\(context)")
            #expect(graph.isDominatingSet(exact))
            // The greedy set cover, written out eagerly: the unchosen vertex of least weight per newly
            // dominated vertex (none if it dominates nothing new), the least index on ties.
            func greedy(_ less: (Int, Int, Int, Int) -> Bool) -> [Int] {
                var dominated = Set<Int>()
                var chosen: [Int] = []
                while dominated.count < n {
                    var pick = -1
                    var pickNew = 0
                    for v in 0 ..< n where !chosen.contains(v) {
                        let fresh = closed[v].subtracting(dominated).count
                        if fresh > 0 && (pick < 0 || less(v, fresh, pick, pickNew)) {
                            pick = v
                            pickNew = fresh
                        }
                    }
                    chosen.append(pick)
                    dominated.formUnion(closed[pick])
                }
                return chosen.sorted().map { listed[$0] }
            }
            let byIndex = listed.map { weight[$0] }
            let weighted = graph.approximateMinimumDominatingSet(weight: { weight[$0] })
            #expect(weighted == greedy { a, ka, b, kb in byIndex[a] * kb < byIndex[b] * ka }, "\(context)")
            #expect(graph.isDominatingSet(weighted))
            let largestClosed = closed.map(\.count).max() ?? 1
            let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
            #expect(Double(weighted.reduce(0) { $0 + weight[$1] }) <= harmonic * Double(leastWeight) + 1e-9, "\(context)")
            let doubles = graph.approximateMinimumDominatingSet(weight: { Double(weight[$0]) / 4 })
            #expect(doubles == greedy { a, ka, b, kb in Double(byIndex[a]) / 4 / Double(ka) < Double(byIndex[b]) / 4 / Double(kb) }, "\(context)")
            let unweighted = graph.approximateMinimumDominatingSet()
            #expect(unweighted == greedy { _, ka, _, kb in ka > kb }, "\(context)")
            #expect(Double(unweighted.count) <= harmonic * Double(exact.count) + 1e-9, "\(context)")
        }
    }

    @Test("minimumEdgeCover() is maximumMatching()'s edges plus each uncovered vertex's first edge: n − ν edges, none fewer by brute force; nil exactly when a vertex has no edge; from any matching still an edge cover")
    func edgeCovers() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 13)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let context = "\(pairs) on \(listed)"
            // The construction, written out from a matching: its edges, then for each vertex in
            // `vertices` order not yet covered, its first incident edge.
            func construction(_ matched: [Int]) -> [Int]? {
                guard listed.allSatisfy({ graph.degree(of: $0) > 0 }) else { return nil }
                var chosen = Set(matched)
                var covered = Set(matched.flatMap { [pairs[$0].0, pairs[$0].1] })
                for v in listed where !covered.contains(v) {
                    let first = graph.incidentEdges(of: v)[0]
                    chosen.insert(first)
                    covered.formUnion([pairs[first].0, pairs[first].1])
                }
                return chosen.sorted()
            }
            let maximum = graph.maximumMatching()
            let cover = graph.minimumEdgeCover()
            #expect(cover == construction(maximum.edges), "\(context)")
            #expect((cover == nil) == listed.contains { graph.degree(of: $0) == 0 }, "\(context)")
            if let cover {
                #expect(graph.isEdgeCover(cover), "\(context)")
                #expect(cover.count == n - maximum.edges.count, "Gallai: \(context)")
                // Brute force over every set of edges: none smaller covers every vertex.
                var fewest = pairs.count + 1
                for mask in 0 ..< 1 << pairs.count {
                    var reached = Set<Int>()
                    for k in pairs.indices where mask & (1 << k) != 0 { reached.formUnion([pairs[k].0, pairs[k].1]) }
                    if reached.count == n { fewest = min(fewest, mask.nonzeroBitCount) }
                }
                #expect(cover.count == fewest, "\(context)")
            }
            // From the greedy matching, which need not be maximum: the same rule, still an edge cover.
            let maximal = graph.maximalMatching()
            let fromMaximal = graph.minimumEdgeCover(matching: maximal)
            #expect(fromMaximal == construction(maximal.edges), "\(context)")
            if let fromMaximal { #expect(graph.isEdgeCover(fromMaximal) && fromMaximal.count >= (cover?.count ?? 0), "\(context)") }
            // From a weighted matching (another Weight type).
            let weighted = graph.maximumWeightMatching(weight: { (_: Int) -> Double in 1 }, maximumCardinality: true)
            #expect(graph.minimumEdgeCover(matching: weighted)?.count == cover?.count, "\(context)")
        }
    }

    @Test("isVertexCover, isIndependentSet, isDominatingSet and isEdgeCover against their definitions, on random lists with repeats")
    func checksAgainstDefinitions() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 12)
        let picks = Gen.int(in: 0 ... 20).array(of: 0 ... 7)
        await propertyCheck(count: 500, input: edges, picks, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, rawPicks, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let given = rawPicks.map { $0 % n }
            let inSet = Set(given)
            let context = "\(given) in \(pairs) on \(listed)"
            let isCover = pairs.allSatisfy { inSet.contains($0.0) || inSet.contains($0.1) }
            let isIndependent = pairs.allSatisfy { !(inSet.contains($0.0) && inSet.contains($0.1)) }
            let isDominating = listed.allSatisfy { v in inSet.contains(v) || pairs.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) } }
            #expect(graph.isVertexCover(given) == isCover, "\(context)")
            #expect(graph.isIndependentSet(given) == isIndependent, "\(context)")
            #expect(graph.isDominatingSet(given) == isDominating, "\(context)")
            #expect(graph.isVertexCover(given.shuffled(using: &rng)) == isCover, "\(context)")
            // A set is independent exactly when the rest of the vertices cover every edge.
            #expect(graph.isVertexCover(listed.filter { !inSet.contains($0) }) == isIndependent, "\(context)")
            guard !pairs.isEmpty else { return }
            let positions = rawPicks.map { $0 % pairs.count }
            let reached = Set(positions.flatMap { [pairs[$0].0, pairs[$0].1] })
            #expect(graph.isEdgeCover(positions) == (reached.count == n), "\(positions) in \(pairs) on \(listed)")
        }
    }
}
