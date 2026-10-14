// Graph edit distance against brute force over every edit path, with shrinking
// (swift-property-based). Random pseudographs and directed pseudographs (parallel edges and
// self-loops) on up to 4 and 5 vertices, at unit costs with optional vertex and edge colours (a
// substitution between different colours costs 1, NetworkX's node_match and edge_match), and
// simple graphs with self-loops at random costs. The model tries every partial injection of the
// first graph's vertices into the second's: the edges between two vertices (or a vertex's loops)
// are matched as groups, the rest deleted or inserted. The returned path must cost what its own
// operations add up to, substitute edges only between images, and be optimal. See README.md.

import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import Multigraphs
import PropertyBased
import Testing

@Suite("Graph edit distance against brute force, with shrinking", .tags(.randomized))
struct GraphEditDistancePropertyTests {
    @Test("Undirected pseudographs, unit costs with optional colours: the distance is the brute-force minimum, and the path costs what its operations add up to")
    func undirectedUnitCosts() async {
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 1)).array(of: 0 ... 7)
        let shape = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 1_000_000))
        await propertyCheck(count: 200, input: edges, edges, shape) { rawG, rawH, shape in
            let (n1, n2, flags, seed) = shape
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let useVertexColors = flags & 1 != 0, useEdgeColors = flags & 2 != 0
            let gEdges = n1 == 0 ? [] : rawG.map { [$0.0 % n1, $0.1 % n1, useEdgeColors ? $0.2 : 0] }
            let hEdges = n2 == 0 ? [] : rawH.map { [$0.0 % n2, $0.1 % n2, useEdgeColors ? $0.2 : 0] }
            let gColors = (0 ..< n1).map { _ in useVertexColors ? Int.random(in: 0 ... 1, using: &rng) : 0 }
            let hColors = (0 ..< n2).map { _ in useVertexColors ? Int.random(in: 0 ... 1, using: &rng) : 0 }
            let g = Pseudograph<Int>(vertices: Array(0 ..< n1), edges: gEdges.map { UndirectedEdge($0[0], $0[1]) })
            let h = Pseudograph<Int>(vertices: Array(0 ..< n2), edges: hEdges.map { UndirectedEdge($0[0], $0[1]) })
            // The colours of the edges between a and b (a self-loop once), sorted.
            func group(_ edges: [[Int]], _ a: Int, _ b: Int) -> [Int] {
                edges.filter { ($0[0] == a && $0[1] == b) || ($0[0] == b && $0[1] == a) }.map { $0[2] }.sorted()
            }
            // Matching two groups at unit costs: equal colours substitute for free, the rest cost
            // one each on the larger side (a substitution between colours costs 1, a deletion and
            // an insertion 2).
            func groupCost(_ a: [Int], _ b: [Int]) -> Int {
                var common = 0, rest = b
                for c in a { if let k = rest.firstIndex(of: c) { rest.remove(at: k); common += 1 } }
                return max(a.count, b.count) - common
            }
            func cost(_ f: [Int]) -> Int {
                var total = 0
                for u in 0 ..< n1 { total += f[u] < 0 ? 1 : (gColors[u] == hColors[f[u]] ? 0 : 1) }
                total += (0 ..< n2).filter { !f.contains($0) }.count
                for a in 0 ..< n1 {
                    for b in a ..< n1 {
                        let mine = group(gEdges, a, b)
                        total += f[a] >= 0 && f[b] >= 0 ? groupCost(mine, group(hEdges, f[a], f[b])) : mine.count
                    }
                }
                total += hEdges.filter { !f.contains($0[0]) || !f.contains($0[1]) }.count
                return total
            }
            var best = Int.max
            var f = [Int](repeating: -1, count: n1)
            func visit(_ u: Int) {
                if u == n1 {
                    best = min(best, cost(f))
                    return
                }
                for x in -1 ..< n2 where x < 0 || !f[0 ..< u].contains(x) {
                    f[u] = x
                    visit(u + 1)
                }
                f[u] = -1
            }
            visit(0)
            let path = g.optimalEditPath(to: h, vertexSubstitutionCost: { gColors[$0] == hColors[$1] ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                                         edgeSubstitutionCost: { gEdges[$0][2] == hEdges[$1][2] ? 0 : 1 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
            let context = "G \(gEdges) \(gColors), H \(hEdges) \(hColors)"
            guard let path else {
                Issue.record("no path: \(context)")
                return
            }
            #expect(path.cost == best, "\(context)")
            #expect(path.isOptimal)
            if !useVertexColors && !useEdgeColors { #expect(g.graphEditDistance(to: h) == best, "\(context)") }
            // The path's own operations: vertex images distinct, edge images between the images of
            // the ends, every element accounted for once.
            let images = g.vertices.map { path.image(of: $0) }
            let substitutes = images.compactMap { $0 }
            let numbers = images.map { $0 ?? -1 }
            #expect(Set(substitutes).count == substitutes.count)
            #expect(cost(numbers) == best, "\(context)")
            var total = 0
            for u in g.vertices { total += images[u].map { gColors[u] == hColors[$0] ? 0 : 1 } ?? 1 }
            total += path.insertedVertices.count
            for p in g.edges.indices {
                guard let q = path.edgeImage(ofEdgeAt: p) else {
                    total += 1
                    continue
                }
                let e = g.edges[p], target = h.edges[q]
                let ends = [images[e.u], images[e.v]]
                #expect(ends == [target.u, target.v] || ends == [target.v, target.u], "\(context)")
                #expect(path.edgePreimage(ofEdgeAt: q) == p)
                total += gEdges[p][2] == hEdges[q][2] ? 0 : 1
            }
            total += path.insertedEdges.count
            #expect(total == best, "\(context)")
            #expect(path.deletedEdges.count + h.edgeCount - path.insertedEdges.count == g.edgeCount)
            let deleted = g.vertices.filter { images[$0] == nil }
            #expect(path.deletedVertices == deleted)
        }
    }

    @Test("Directed pseudographs, unit costs: the distance is the brute-force minimum, and arcs are substituted only in the same direction")
    func directedUnitCosts() async {
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 7)
        let shape = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 5))
        await propertyCheck(count: 200, input: edges, edges, shape) { rawG, rawH, shape in
            let (n1, n2) = shape
            let gEdges = n1 == 0 ? [] : rawG.map { [$0.0 % n1, $0.1 % n1] }
            let hEdges = n2 == 0 ? [] : rawH.map { [$0.0 % n2, $0.1 % n2] }
            let g = DirectedPseudograph<Int>(vertices: Array(0 ..< n1), edges: gEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let h = DirectedPseudograph<Int>(vertices: Array(0 ..< n2), edges: hEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
            func multiplicity(_ edges: [[Int]], _ a: Int, _ b: Int) -> Int { edges.filter { $0 == [a, b] }.count }
            func cost(_ f: [Int]) -> Int {
                var total = f.filter { $0 < 0 }.count + (0 ..< n2).filter { !f.contains($0) }.count
                for a in 0 ..< n1 {
                    for b in 0 ..< n1 {
                        let mine = multiplicity(gEdges, a, b)
                        total += f[a] >= 0 && f[b] >= 0 ? abs(mine - multiplicity(hEdges, f[a], f[b])) : mine
                    }
                }
                total += hEdges.filter { !f.contains($0[0]) || !f.contains($0[1]) }.count
                return total
            }
            var best = Int.max
            var f = [Int](repeating: -1, count: n1)
            func visit(_ u: Int) {
                if u == n1 {
                    best = min(best, cost(f))
                    return
                }
                for x in -1 ..< n2 where x < 0 || !f[0 ..< u].contains(x) {
                    f[u] = x
                    visit(u + 1)
                }
                f[u] = -1
            }
            visit(0)
            let context = "G \(gEdges), H \(hEdges)"
            #expect(g.graphEditDistance(to: h) == best, "\(context)")
            guard let path = g.optimalEditPath(to: h) else {
                Issue.record("no path: \(context)")
                return
            }
            #expect(path.cost == best)
            let images = g.vertices.map { path.image(of: $0) }
            let numbers = images.map { $0 ?? -1 }
            #expect(cost(numbers) == best, "\(context)")
            for p in g.edges.indices {
                guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
                #expect([images[g.source(ofEdgeAt: p)], images[g.target(ofEdgeAt: p)]] == [h.source(ofEdgeAt: q), h.target(ofEdgeAt: q)], "\(context)")
            }
            let substituted = g.edgeCount - path.deletedEdges.count
            #expect(path.cost == path.deletedVertices.count + path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count)
            #expect(substituted == h.edgeCount - path.insertedEdges.count)
            // At unit costs the distance is symmetric.
            #expect(h.graphEditDistance(to: g) == best, "\(context)")
        }
    }

    @Test("Simple graphs with self-loops at random costs: the distance is the brute-force minimum, undirected and directed")
    func randomCosts() async {
        let edges = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 3)).array(of: 0 ... 6)
        let costs = Gen.int(in: 0 ... 4).array(of: 60)
        let shape = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 4), Gen.bool)
        await propertyCheck(count: 600, input: edges, edges, zip(costs, shape)) { rawG, rawH, rest in
            let (c, (n1, n2, directed)) = rest
            func simple(_ raw: [(Int, Int)], _ n: Int) -> [[Int]] {
                var seen: [[Int]] = []
                for (a, b) in raw where n > 0 {
                    let pair = directed ? [a % n, b % n] : [min(a % n, b % n), max(a % n, b % n)]
                    if !seen.contains(pair) { seen.append(pair) }
                }
                return seen
            }
            let gEdges = simple(rawG, n1), hEdges = simple(rawH, n2)
            // Costs from the generated list, by element.
            func vsub(_ u: Int, _ x: Int) -> Int { c[u * 5 + x] }
            func vdel(_ u: Int) -> Int { c[20 + u] }
            func vins(_ x: Int) -> Int { c[24 + x] }
            func esub(_ e: Int, _ f: Int) -> Int { c[(29 + e * 7 + f) % 60] }
            func edel(_ e: Int) -> Int { c[(43 + e) % 60] }
            func eins(_ f: Int) -> Int { c[(50 + f) % 60] }
            func index(_ edges: [[Int]], _ a: Int, _ b: Int) -> Int? {
                edges.firstIndex { directed ? $0 == [a, b] : ($0 == [a, b] || $0 == [b, a]) }
            }
            func cost(_ f: [Int]) -> Int {
                var total = 0
                for u in 0 ..< n1 { total += f[u] < 0 ? vdel(u) : vsub(u, f[u]) }
                for x in 0 ..< n2 where !f.contains(x) { total += vins(x) }
                var matched = Set<Int>()
                for (e, pair) in gEdges.enumerated() {
                    let x = f[pair[0]], y = f[pair[1]]
                    if x >= 0, y >= 0, let q = index(hEdges, x, y) {
                        matched.insert(q)
                        total += min(esub(e, q), edel(e) + eins(q))
                    } else {
                        total += edel(e)
                    }
                }
                for q in hEdges.indices where !matched.contains(q) { total += eins(q) }
                return total
            }
            var best = Int.max
            var f = [Int](repeating: -1, count: n1)
            func visit(_ u: Int) {
                if u == n1 {
                    best = min(best, cost(f))
                    return
                }
                for x in -1 ..< n2 where x < 0 || !f[0 ..< u].contains(x) {
                    f[u] = x
                    visit(u + 1)
                }
                f[u] = -1
            }
            visit(0)
            let context = "G \(gEdges), H \(hEdges), directed \(directed), costs \(c)"
            if directed {
                let g = DirectedPseudograph<Int>(vertices: Array(0 ..< n1), edges: gEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
                let h = DirectedPseudograph<Int>(vertices: Array(0 ..< n2), edges: hEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
                let path = g.optimalEditPath(to: h, vertexSubstitutionCost: vsub, vertexDeletionCost: vdel, vertexInsertionCost: vins,
                                             edgeSubstitutionCost: esub, edgeDeletionCost: edel, edgeInsertionCost: eins)
                #expect(path?.cost == best, "\(context)")
                var images: [Int] = []
                for v in g.vertices { images.append(path?.image(of: v) ?? -1) }
                #expect(cost(images) == best, "\(context)")
                let bounded = g.optimalEditPath(to: h, vertexSubstitutionCost: vsub, vertexDeletionCost: vdel, vertexInsertionCost: vins,
                                                edgeSubstitutionCost: esub, edgeDeletionCost: edel, edgeInsertionCost: eins, upperBound: best)
                #expect(bounded?.cost == best, "\(context)")
            } else {
                let g = Pseudograph<Int>(vertices: Array(0 ..< n1), edges: gEdges.map { UndirectedEdge($0[0], $0[1]) })
                let h = Pseudograph<Int>(vertices: Array(0 ..< n2), edges: hEdges.map { UndirectedEdge($0[0], $0[1]) })
                let path = g.optimalEditPath(to: h, vertexSubstitutionCost: vsub, vertexDeletionCost: vdel, vertexInsertionCost: vins,
                                             edgeSubstitutionCost: esub, edgeDeletionCost: edel, edgeInsertionCost: eins)
                #expect(path?.cost == best, "\(context)")
                var images: [Int] = []
                for v in g.vertices { images.append(path?.image(of: v) ?? -1) }
                #expect(cost(images) == best, "\(context)")
                #expect(g.graphEditDistance(to: h, vertexSubstitutionCost: vsub, vertexDeletionCost: vdel, vertexInsertionCost: vins,
                                            edgeSubstitutionCost: esub, edgeDeletionCost: edel, edgeInsertionCost: eins) == best, "\(context)")
                // At the distance as an upper bound the search must still reach an optimal path:
                // the bipartite start is not kept when it costs more, so only the lower bound
                // guides the search there.
                let bounded = g.optimalEditPath(to: h, vertexSubstitutionCost: vsub, vertexDeletionCost: vdel, vertexInsertionCost: vins,
                                                edgeSubstitutionCost: esub, edgeDeletionCost: edel, edgeInsertionCost: eins, upperBound: best)
                #expect(bounded?.cost == best, "\(context)")
            }
        }
    }

    @Test("upperBound and expansionLimit: nil exactly when the distance exceeds the bound; a limited search returns a path no cheaper than the distance, optimal when it finished")
    func boundsAndLimits() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 9)
        let shape = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 30))
        await propertyCheck(count: 200, input: edges, edges, shape) { rawG, rawH, shape in
            let (n1, n2, bound, limit) = shape
            let g = Pseudograph<Int>(vertices: Array(0 ..< n1), edges: n1 == 0 ? [] : rawG.map { UndirectedEdge($0.0 % n1, $0.1 % n1) })
            let h = Pseudograph<Int>(vertices: Array(0 ..< n2), edges: n2 == 0 ? [] : rawH.map { UndirectedEdge($0.0 % n2, $0.1 % n2) })
            let exact = g.graphEditDistance(to: h)
            let bounded = g.optimalEditPath(to: h, upperBound: bound)
            #expect((bounded == nil) == (exact > bound), "G \(rawG) H \(rawH) n \(n1) \(n2) bound \(bound)")
            if let bounded { #expect(bounded.cost == exact && bounded.isOptimal) }
            let limited = g.optimalEditPath(to: h, expansionLimit: limit)
            guard let limited else {
                Issue.record("no path without a bound")
                return
            }
            #expect(limited.cost >= exact)
            if limited.isOptimal { #expect(limited.cost == exact) }
            #expect(limited.cost == limited.deletedVertices.count + limited.insertedVertices.count + limited.deletedEdges.count + limited.insertedEdges.count)
            // Zero exactly for isomorphic graphs.
            #expect((exact == 0) == g.isIsomorphic(to: h))
        }
    }
}
