// The families that defeat a matcher without automorphism pruning, each inside a Task with a
// one-minute limit and meant to finish in well under a second even in a debug build (the
// benchmarks take timings): disjoint unions of equal components against unions with one component
// changed, Latin-square graphs of two groups of one order (strongly regular with equal parameters),
// twisted CFI pairs over a cubic base of 40, and pairs of random regular graphs. Then the
// automorphism group and canonical labeling on the same families, an iterator copied in the middle
// of a sequence, cancellation, and the inverse mapping. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import Multigraphs
import RandomGraphs
import Testing

@Suite("Isomorphism on hard families")
struct IsomorphismHardFamiliesTests {
    @Test("20 hexagons against 19 hexagons and two triangles, and 20 copies of K3,3 against 19 and a prism, are not isomorphic; 20 hexagons against a relabelled copy have 20! · 12²⁰ mappings", .timeLimit(.minutes(1)))
    func disjointUnions() async throws {
        try await Task {
            let k = 20
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 21)
            let permutation = Array(0 ..< 6 * k).shuffled(using: &rng)
            func cycle(_ length: Int, _ offset: Int) -> [[Int]] { (0 ..< length).map { [offset + $0, offset + ($0 + 1) % length] } }
            var hexagons: [[Int]] = [], changed: [[Int]] = []
            for i in 0 ..< k { hexagons += cycle(6, 6 * i) }
            for i in 0 ..< k - 1 { changed += cycle(6, 6 * i) }
            changed += cycle(3, 6 * (k - 1)) + cycle(3, 6 * (k - 1) + 3)
            let g = UndirectedAdjacencyList(vertices: 0 ..< 6 * k, edges: hexagons.map { UndirectedEdge($0[0], $0[1]) })
            let h = UndirectedAdjacencyList(vertices: 0 ..< 6 * k, edges: changed.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[0]], permutation[$0[1]]) })
            let clock = ContinuousClock()
            let start = clock.now
            #expect(!g.isIsomorphic(to: h))
            #expect(g.isomorphism(to: h) == nil)
            var bipartite: [[Int]] = [], withPrism: [[Int]] = []
            func k33(_ o: Int) -> [[Int]] { (0 ..< 3).flatMap { i in (3 ..< 6).map { [o + i, o + $0] } } }
            for i in 0 ..< k { bipartite += k33(6 * i) }
            for i in 0 ..< k - 1 { withPrism += k33(6 * i) }
            let o = 6 * (k - 1)
            withPrism += cycle(3, o) + cycle(3, o + 3) + [[o, o + 3], [o + 1, o + 4], [o + 2, o + 5]]
            let a = UndirectedAdjacencyList(vertices: 0 ..< 6 * k, edges: bipartite.map { UndirectedEdge($0[0], $0[1]) })
            let b = UndirectedAdjacencyList(vertices: 0 ..< 6 * k, edges: withPrism.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[0]], permutation[$0[1]]) })
            #expect(!a.isIsomorphic(to: b))
            #expect(clock.now - start < .seconds(10))
            // The isomorphic pair: a mapping, and the automorphism group's order 20! · 12²⁰.
            let copy = UndirectedAdjacencyList(vertices: 0 ..< 6 * k, edges: hexagons.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[0]], permutation[$0[1]]) })
            let mapping = try #require(g.isomorphism(to: copy))
            #expect(Set(mapping.images).count == 6 * k)
            #expect(g.edges.allSatisfy { copy.contains(edge: UndirectedEdge(mapping.image(of: $0.u), mapping.image(of: $0.v))) })
            var order = 1.0
            for i in 1 ... k { order *= Double(i) * 12 }
            let group = g.automorphismGroup()
            #expect(abs(group.order / order - 1) < 1e-12)
            #expect(group.orbits.count == 1)
            // The first five mappings of the sequence are distinct and valid.
            let first = Array(g.isomorphisms(to: copy).prefix(5))
            #expect(first.count == 5 && Set(first).count == 5)
            for m in first { #expect(g.edges.allSatisfy { copy.contains(edge: UndirectedEdge(m.image(of: $0.u), m.image(of: $0.v))) }) }
        }.value
    }

    @Test("Latin-square graphs of Z16 and of Z2 × Z8 (strongly regular, equal parameters) are not isomorphic; Z16 against a relabelled copy is", .timeLimit(.minutes(1)))
    func latinSquareGraphs() async throws {
        try await Task {
            let n = 16, half = 8
            // Vertices are the cells (row, column) of the group's table; two cells are adjacent
            // when they share a row, a column or an entry.
            func latinSquare(_ op: (Int, Int) -> Int, _ relabel: [Int]) -> UndirectedAdjacencyList<Int> {
                var edges: [UndirectedEdge<Int>] = []
                for a in 0 ..< n * n {
                    for b in a + 1 ..< n * n where a / n == b / n || a % n == b % n || op(a / n, a % n) == op(b / n, b % n) {
                        edges.append(UndirectedEdge(relabel[a], relabel[b]))
                    }
                }
                return UndirectedAdjacencyList(vertices: 0 ..< n * n, edges: edges)
            }
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 22)
            let identity = Array(0 ..< n * n)
            let shuffled = identity.shuffled(using: &rng)
            let cyclic = latinSquare({ ($0 + $1) % n }, identity)
            let cyclicCopy = latinSquare({ ($0 + $1) % n }, shuffled)
            let product = latinSquare({ a, b in ((a / half + b / half) % 2) * half + (a % half + b % half) % half }, shuffled)
            #expect((0 ..< n * n).allSatisfy { cyclic.degree(of: $0) == 3 * (n - 1) && product.degree(of: $0) == 3 * (n - 1) })
            let clock = ContinuousClock()
            let start = clock.now
            #expect(!cyclic.isIsomorphic(to: product))
            let mapping = try #require(cyclic.isomorphism(to: cyclicCopy))
            #expect(cyclic.edges.allSatisfy { cyclicCopy.contains(edge: UndirectedEdge(mapping.image(of: $0.u), mapping.image(of: $0.v))) })
            #expect(cyclic.canonicalLabeling().form == cyclicCopy.canonicalLabeling().form)
            #expect(cyclic.canonicalLabeling().form != product.canonicalLabeling().form)
            #expect(clock.now - start < .seconds(10))
            // Every generator is an automorphism; the group is transitive.
            let group = cyclic.automorphismGroup()
            #expect(group.orbits.count == 1)
            for generator in group.generators {
                #expect(cyclic.edges.allSatisfy { cyclic.contains(edge: UndirectedEdge(generator.image(of: $0.u), generator.image(of: $0.v))) })
            }
            #expect(group.basicOrbitLengths.reduce(1, *) == Int(group.order))
        }.value
    }

    @Test("CFI graphs over a random cubic base of 40 vertices: the twisted pair is not isomorphic, a relabelled copy is, and the automorphism group has order at least 2²¹", .timeLimit(.minutes(1)))
    func cfiOverForty() async throws {
        try await Task {
            var generator = Xoshiro256StarStar(seed: 40)
            let base = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: 40, degree: 3, using: &generator)
            let baseEdges = Array(base.edges)
            // Each base vertex of degree 3 becomes 4 middle vertices (the even subsets of its edges)
            // and a pair a0, a1 per edge; middle vertex S is adjacent to a1 of the edges in S and to
            // a0 of the others. Each base edge joins the pairs at its ends straight, or crossed
            // (twisted) for the first edge.
            func cfi(twisted: Bool) -> UndirectedAdjacencyList<Int> {
                var incident = [[Int]](repeating: [], count: 40)
                for (k, e) in baseEdges.enumerated() { incident[e.u].append(k); incident[e.v].append(k) }
                var next = 0
                var pair = [[Int: [Int]]](repeating: [:], count: 40)
                var edges: [UndirectedEdge<Int>] = []
                for v in 0 ..< 40 {
                    var middles: [(Int, Int)] = []
                    for mask in 0 ..< 8 where mask.nonzeroBitCount % 2 == 0 {
                        middles.append((next, mask))
                        next += 1
                    }
                    for j in 0 ..< 3 {
                        pair[v][incident[v][j]] = [next, next + 1]
                        next += 2
                    }
                    for (m, mask) in middles {
                        for j in 0 ..< 3 { edges.append(UndirectedEdge(m, pair[v][incident[v][j]]![(mask >> j) & 1])) }
                    }
                }
                for (k, e) in baseEdges.enumerated() {
                    let t = twisted && k == 0 ? 1 : 0
                    for i in 0 ..< 2 { edges.append(UndirectedEdge(pair[e.u][k]![i], pair[e.v][k]![i ^ t])) }
                }
                return UndirectedAdjacencyList(vertices: 0 ..< next, edges: edges)
            }
            let plain = cfi(twisted: false), twisted = cfi(twisted: true)
            #expect(plain.vertexCount == 400 && plain.edgeCount == 600)
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 23)
            let permutation = Array(0 ..< 400).shuffled(using: &rng)
            let twistedCopy = UndirectedAdjacencyList(vertices: 0 ..< 400, edges: twisted.edges.shuffled(using: &rng).map { UndirectedEdge(permutation[$0.u], permutation[$0.v]) })
            let plainCopy = UndirectedAdjacencyList(vertices: 0 ..< 400, edges: plain.edges.shuffled(using: &rng).map { UndirectedEdge(permutation[$0.u], permutation[$0.v]) })
            let clock = ContinuousClock()
            let start = clock.now
            #expect(!plain.isIsomorphic(to: twistedCopy))
            let mapping = try #require(plain.isomorphism(to: plainCopy))
            #expect(plain.edges.allSatisfy { plainCopy.contains(edge: UndirectedEdge(mapping.image(of: $0.u), mapping.image(of: $0.v))) })
            #expect(plain.canonicalLabeling().form != twistedCopy.canonicalLabeling().form)
            #expect(plain.canonicalLabeling().form == plainCopy.canonicalLabeling().form)
            #expect(clock.now - start < .seconds(10))
            // The cycle space of the base (60 − 40 + 1 = 21 independent cycles) gives 2²¹
            // automorphisms; the base's own automorphisms multiply it.
            let group = plain.automorphismGroup()
            let order = group.basicOrbitLengths.reduce(1, *)
            #expect(order % (1 << 21) == 0)
            #expect(Double(order) == group.order)
            #expect(twisted.automorphismGroup().order == group.order)
        }.value
    }

    @Test("Two random 3-regular graphs on 2,000 vertices and two random 10-regular graphs on 1,000: not isomorphic", .timeLimit(.minutes(1)))
    func randomRegularPairs() async {
        await Task {
            for (n, d) in [(2000, 3), (1000, 10)] {
                var first = Xoshiro256StarStar(seed: 30)
                var second = Xoshiro256StarStar(seed: 31)
                let g = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: n, degree: d, using: &first)
                let h = UndirectedAdjacencyList<Int>.randomRegular(vertexCount: n, degree: d, using: &second)
                #expect(!g.isIsomorphic(to: h))
                #expect(g.canonicalLabeling().form != h.canonicalLabeling().form)
                #expect(g.automorphismGroup().order == 1)
            }
        }.value
    }

    @Test("An iterator copied in the middle of a sequence goes on with the same mappings as the original")
    func iteratorCopiedMidSequence() {
        var k5: [UndirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { k5.append(UndirectedEdge(u, v)) } }
        let complete = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: k5)
        let path = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        for sequence in [complete.isomorphisms(to: complete), path.monomorphisms(to: complete), path.subgraphIsomorphisms(to: path)] {
            let all = Array(sequence)
            for cut in [0, 1, 7, all.count - 1] where cut < all.count {
                var original = sequence.makeIterator()
                for _ in 0 ..< cut { _ = original.next() }
                var copy = original
                var fromOriginal: [Isomorphism<UndirectedAdjacencyList<Int>, UndirectedAdjacencyList<Int>>] = []
                var fromCopy = fromOriginal
                while let m = original.next() { fromOriginal.append(m) }
                while let m = copy.next() { fromCopy.append(m) }
                #expect(fromOriginal == Array(all[cut...]))
                #expect(fromCopy == Array(all[cut...]))
            }
        }
        #expect(Array(complete.isomorphisms(to: complete)).count == 120)
    }

    @Test("In a cancelled task the isomorphism sequence ends after its first mapping and the monomorphism search stops early")
    func cancellation() async {
        let empty = UndirectedAdjacencyList<Int>(vertices: 0 ..< 8, edges: [])
        var complete: [UndirectedEdge<Int>] = []
        for u in 0 ..< 60 { for v in u + 1 ..< 60 { complete.append(UndirectedEdge(u, v)) } }
        let target = UndirectedAdjacencyList(vertices: 0 ..< 60, edges: complete)
        let path = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return (Array(empty.isomorphisms(to: empty)).count, path.monomorphisms(to: target).reduce(0) { n, _ in n + 1 })
        }
        let (isomorphisms, monomorphisms) = await task.value
        #expect(isomorphisms == 1)
        #expect(monomorphisms < 60 * 59 * 58)
        // Without cancellation: 8! and 60 · 59 · 58.
        #expect(Array(empty.isomorphisms(to: empty)).count == 40320)
        let monomorphismCount: Int = path.monomorphisms(to: target).reduce(0) { n, _ in n + 1 }
        #expect(monomorphismCount == 60 * 59 * 58)
    }

    @Test("The inverse of an isomorphism maps each image back; preimage(safe:) is nil off the target and outside the image")
    func inverseAndSafePreimage() throws {
        let g = UndirectedAdjacencyList(vertices: [1, 2, 3, 4], edges: [UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let h = UndirectedAdjacencyList(vertices: [10, 20, 30, 40], edges: [UndirectedEdge(30, 10), UndirectedEdge(10, 40), UndirectedEdge(40, 20)])
        for mapping in g.isomorphisms(to: h) {
            let inverse = mapping.inverse
            #expect(g.vertices.allSatisfy { inverse.image(of: mapping.image(of: $0)) == $0 })
            #expect(h.vertices.allSatisfy { inverse.image(of: $0) == mapping.preimage(of: $0) })
            #expect(h.edges.allSatisfy { g.contains(edge: UndirectedEdge(inverse.image(of: $0.u), inverse.image(of: $0.v))) })
            #expect(mapping.preimage(safe: 99) == nil)
            #expect(mapping.preimage(safe: 20) == mapping.preimage(of: 20))
        }
        let pattern = UndirectedAdjacencyList(vertices: [1, 2], edges: [UndirectedEdge(1, 2)])
        let mapping = try #require(pattern.subgraphIsomorphism(to: h))
        let outside = try #require(h.vertices.first { !mapping.images.contains($0) })
        #expect(mapping.preimage(safe: outside) == nil)
    }

    @Test("Canonical labelings: relabelled copies get equal forms, a permutation and matching indices; directed C3 and its two orientations")
    func canonicalLabelings() {
        let petersen: [[Int]] = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [0, 5], [1, 6], [2, 7], [3, 8], [4, 9], [5, 7], [7, 9], [9, 6], [6, 8], [8, 5]]
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 24)
        let permutation = Array(0 ..< 10).shuffled(using: &rng)
        let g = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: petersen.map { UndirectedEdge($0[0], $0[1]) })
        let h = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: petersen.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[0]], permutation[$0[1]]) })
        let a = g.canonicalLabeling(), b = h.canonicalLabeling()
        #expect(a.form == b.form && a.form.hashValue == b.form.hashValue)
        #expect(Set(a.permutation) == Set(0 ..< 10))
        #expect(g.vertices.allSatisfy { a.canonicalIndex(of: $0) == a.permutation[$0] })
        // Renumbering both by their labelings gives the same edge set.
        let left = Set(g.edges.map { Set([a.canonicalIndex(of: $0.u), a.canonicalIndex(of: $0.v)]) })
        let right = Set(h.edges.map { Set([b.canonicalIndex(of: $0.u), b.canonicalIndex(of: $0.v)]) })
        #expect(left == right)
        // A parallel edge or a loop changes the form.
        let doubled = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let looped = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        let shifted = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(2, 1), UndirectedEdge(2, 1), UndirectedEdge(1, 0)])
        #expect(doubled.canonicalLabeling().form != looped.canonicalLabeling().form)
        #expect(doubled.canonicalLabeling().form == shifted.canonicalLabeling().form)
        let forward = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let backward = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 0, to: 2)])
        let transitive = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)])
        #expect(forward.canonicalLabeling().form == backward.canonicalLabeling().form)
        #expect(forward.canonicalLabeling().form != transitive.canonicalLabeling().form)
    }
}
