// randomWalk(from:length:…using:): uniform, weighted and node2vec-biased random walks, directed and
// undirected, as Walks `Walk`s with edge positions. Every walk is checked draw for draw against a
// reference written in the test that reads the generator's bits the same way; the transition
// frequencies of many walks are checked against the exact probabilities; early stops, zero
// weights, self-loops, parallel edges and the preconditions are pinned. Case IDs (TR-nn) refer to
// the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import StableGraphs
import Testing
import Traversal
import Walks

/// A directed multigraph without vertex indices.
private struct UnindexedDigraph: DirectedGraph {
    let base: ReferenceDirectedMultigraph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [DirectedEdge<Int>] { base.edges }
    func successors(of vertex: Int) -> [Int] { base.successors(of: vertex) }
    func outEdges(of vertex: Int) -> [Int] { base.outEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

/// An undirected pseudograph without vertex indices.
private struct UnindexedPseudograph: Graph {
    let base: ReferencePseudograph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [UndirectedEdge<Int>] { base.edges }
    func neighbors(of vertex: Int) -> [Int] { base.neighbors(of: vertex) }
    func incidentEdges(of vertex: Int) -> [Int] { base.incidentEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

@Suite("Random walks")
struct RandomWalkTests {
    @Test("TR-250 a walk of the graph, of the length asked for, reproduced by the same seed")
    func validAndReproducible() {
        let graph = CompressedSparseRow(vertexCount: 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0),
        ])
        var g1 = SeededRandomNumberGenerator(seed: 42)
        var g2 = SeededRandomNumberGenerator(seed: 42)
        let walk = graph.randomWalk(from: 0, length: 50, using: &g1)
        #expect(walk.length == 50)
        #expect(walk.source == 0)
        #expect(Walk(vertices: walk.vertices, edges: walk.edges, in: graph) != nil)
        #expect(graph.randomWalk(from: 0, length: 50, using: &g2) == walk)
        // The first two steps are forced.
        #expect(Array(walk.vertices.prefix(3)) == [0, 1, 2])
        #expect(Array(walk.edges.prefix(2)) == [0, 1])
        #expect(graph.randomWalk(from: 3, length: 0, using: &g1) == Walk(vertex: 3))
    }

    @Test("TR-251 the walk stops early at a vertex with no out-edges, an isolated vertex, or edges that all weigh zero")
    func earlyStops() {
        var generator = SeededRandomNumberGenerator(seed: 7)
        let path = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let walk = path.randomWalk(from: 0, length: 10, using: &generator)
        #expect(walk.vertices == [0, 1, 2])
        let isolated = UndirectedAdjacencyList(vertices: [0, 1], edges: [])
        #expect(isolated.randomWalk(from: 1, length: 5, using: &generator) == Walk(vertex: 1))
        let weighted = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 0)])
        // From 1 both edges weigh zero.
        let stopped = weighted.randomWalk(from: 0, length: 10, weight: { $0 == 0 ? 1.0 : 0.0 }, using: &generator)
        #expect(stopped.vertices == [0, 1])
        // CSR positions: 0→1 is 0, 1→0 is 1, 1→2 is 2. A zero-weight edge is never taken.
        #expect(weighted.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0], [1, 2]])
        for _ in 0 ..< 50 {
            let w = weighted.randomWalk(from: 0, length: 20, weight: { $0 == 2 ? 0.0 : 1.0 }, using: &generator)
            #expect(!w.edges.contains(2))
            #expect(w.length == 20)
        }
    }

    @Test("TR-252 parallel edges are separate choices and the walk records the copy taken; an undirected self-loop has two ends")
    func multigraphs() {
        var graph = DirectedPseudograph<Int>()
        let a = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let b = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let c = graph.insert(edge: DirectedEdge(from: 0, to: 2))
        var generator = SeededRandomNumberGenerator(seed: 1)
        var counts: [Int: Int] = [:]
        for _ in 0 ..< 6000 {
            let walk = graph.randomWalk(from: 0, length: 1, using: &generator)
            counts[walk.edges[0], default: 0] += 1
        }
        for e in [a, b, c] { #expect(abs(Double(counts[e] ?? 0) / 6000 - 1.0 / 3) < 0.03, "edge \(e)") }
        // Undirected: the loop 0–0 has two ends at 0, the edge 0–1 one.
        let looped = Pseudograph(edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        var loops = 0
        for _ in 0 ..< 6000 where looped.randomWalk(from: 0, length: 1, using: &generator).edges == [0] { loops += 1 }
        #expect(abs(Double(loops) / 6000 - 2.0 / 3) < 0.03)
    }

    @Test("TR-253 weighted steps follow the weights; node2vec's 1/p, 1 and 1/q bias the second step")
    func transitionFrequencies() {
        // Directed: from 0, weights 1, 2, 3, 4 to 1, 2, 3, 4.
        let star = CompressedSparseRow(vertexCount: 5, edges: (1 ... 4).map { DirectedEdge(from: 0, to: $0) })
        var generator = SeededRandomNumberGenerator(seed: 11)
        var hits = [Int](repeating: 0, count: 5)
        for _ in 0 ..< 10000 { hits[star.randomWalk(from: 0, length: 1, weight: { Double($0 + 1) }, using: &generator).target] += 1 }
        for v in 1 ... 4 { #expect(abs(Double(hits[v]) / 10000 - Double(v) / 10) < 0.02, "vertex \(v)") }
        // Undirected: 0–1, then from 1 back to 0 (1/p), to 2, a neighbor of 0 (1), or to 3 (1/q).
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(1, 3)])
        for (p, q) in [(0.5, 2.0), (4.0, 0.25), (1.0, 3.0), (2.0, 1.0)] {
            var second = [Int](repeating: 0, count: 4)
            var walks = 0
            for _ in 0 ..< 20000 {
                let walk = graph.randomWalk(from: 0, length: 2, returnParameter: p, inOutParameter: q, using: &generator)
                guard walk.vertices[1] == 1 else { continue }
                walks += 1
                second[walk.vertices[2]] += 1
            }
            let total = 1 / p + 1 + 1 / q
            #expect(abs(Double(second[0]) / Double(walks) - (1 / p) / total) < 0.025, "p \(p) q \(q)")
            #expect(abs(Double(second[2]) / Double(walks) - 1 / total) < 0.025, "p \(p) q \(q)")
            #expect(abs(Double(second[3]) / Double(walks) - (1 / q) / total) < 0.025, "p \(p) q \(q)")
        }
        // Directed node2vec: 0 → 1, then 1 → 0 (1/p), 1 → 2 where 0 → 2 (1), 1 → 3 (1/q); the
        // edge 2 → 0 does not make 2 a successor of 0.
        let digraph = AdjacencyList(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 3, to: 0),
        ])
        var second = [Int](repeating: 0, count: 4)
        var walks = 0
        for _ in 0 ..< 20000 {
            let walk = digraph.randomWalk(from: 0, length: 2, returnParameter: 0.5, inOutParameter: 4, using: &generator)
            guard walk.vertices[1] == 1 else { continue }
            walks += 1
            second[walk.vertices[2]] += 1
        }
        let total = 2 + 1 + 0.25
        #expect(abs(Double(second[0]) / Double(walks) - 2 / total) < 0.025)
        #expect(abs(Double(second[2]) / Double(walks) - 1 / total) < 0.025)
        #expect(abs(Double(second[3]) / Double(walks) - 0.25 / total) < 0.025)
    }

    @Test("TR-254 directed: every walk is the reference's draw for draw, on every representation")
    func directedAgainstReference() async {
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 16)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 1_000_000)) { raw, source, length, mode, seed in
            let edges = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            // Mode 0 uniform, 1 weighted, 2 biased, 3 weighted and biased; some weights zero.
            let (p, q) = mode >= 2 ? (0.5, 3.0) : (1.0, 1.0)
            func check<G: DirectedGraph<Int>>(_ g: G, _ weightOf: @escaping (G.Edges.Index) -> Double, _ name: String) {
                var reference = SeededRandomNumberGenerator(seed: UInt(seed))
                var vertices = [source]
                var taken: [G.Edges.Index] = []
                var u = source
                var previous: Int?
                while taken.count < length {
                    let row = Array(g.outEdges(of: u))
                    if row.isEmpty { break }
                    let pick: Int
                    if mode == 0 || (mode == 2 && previous == nil) {
                        let shift = UInt64(row.count.leadingZeroBitCount)
                        var r = row.count
                        while r >= row.count { r = Int(truncatingIfNeeded: reference.next() >> shift) }
                        pick = r
                    } else {
                        var cumulative: [Double] = []
                        var total = 0.0
                        for e in row {
                            var x = mode == 1 || mode == 3 ? weightOf(e) : 1
                            if mode >= 2, let previous {
                                let t = g.target(ofEdgeAt: e)
                                x *= t == previous ? 1 / p : g.successors(of: previous).contains(t) ? 1 : 1 / q
                            }
                            total += x
                            cumulative.append(total)
                        }
                        if total <= 0 { break }
                        let r = Double(reference.next() >> 11) * 0x1p-53 * total
                        pick = cumulative.firstIndex { $0 > r }!
                    }
                    taken.append(row[pick])
                    previous = u
                    u = g.target(ofEdgeAt: row[pick])
                    vertices.append(u)
                }
                var generator = SeededRandomNumberGenerator(seed: UInt(seed))
                let walk = mode == 0 || mode == 2
                    ? g.randomWalk(from: source, length: length, returnParameter: p, inOutParameter: q, using: &generator)
                    : g.randomWalk(from: source, length: length, weight: weightOf, returnParameter: p, inOutParameter: q, using: &generator)
                #expect(walk.vertices == vertices, "\(name)")
                #expect(walk.edges == taken, "\(name)")
                #expect(Walk(vertices: walk.vertices, edges: walk.edges, in: g) != nil, "\(name)")
            }
            // Weights by endpoints, so every representation weighs an edge alike.
            func weight(_ edge: DirectedEdge<Int>) -> Double { Double((edge.source * 7 + edge.target * 3) % 4) }
            let reference = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: edges)
            check(reference, { weight(reference.edges[$0]) }, "ReferenceDirectedMultigraph")
            check(UnindexedDigraph(base: reference), { weight(reference.edges[$0]) }, "without vertex indices")
            let pseudograph = DirectedPseudograph(vertices: 0 ..< 6, edges: edges)
            check(pseudograph, { weight(pseudograph.edges[$0]) }, "DirectedPseudograph")
            let sparse = CompressedSparseRow(vertexCount: 6, edges: edges)
            check(sparse, { weight(sparse.edges[$0]) }, "CompressedSparseRow")
            let list = AdjacencyList(vertices: 0 ..< 6, edges: edges)
            check(list, { weight(list.edges[$0]) }, "AdjacencyList")
            let matrix = AdjacencyMatrix(vertexCount: 6, edges: edges)
            check(matrix, { weight(matrix.edges[$0]) }, "AdjacencyMatrix")
            var stable = StableDirectedGraph(vertices: 0 ..< 7, edges: [DirectedEdge(from: 6, to: 6), DirectedEdge(from: 6, to: 0)] + edges)
            _ = stable.remove(6)
            let holed = stable
            check(holed, { weight(holed.edges[$0]) }, "StableDirectedGraph with holes")
        }
    }

    @Test("TR-255 undirected: every walk is the reference's draw for draw, on every representation")
    func undirectedAgainstReference() async {
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 12), Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 1_000_000)) { raw, source, length, mode, seed in
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            let (p, q) = mode >= 2 ? (2.0, 0.5) : (1.0, 1.0)
            func check<G: Graph<Int>>(_ g: G, _ weightOf: @escaping (G.Edges.Index) -> Double, _ name: String) {
                var reference = SeededRandomNumberGenerator(seed: UInt(seed))
                var vertices = [source]
                var taken: [G.Edges.Index] = []
                var u = source
                var previous: Int?
                while taken.count < length {
                    let row = Array(g.incidentEdges(of: u))
                    if row.isEmpty { break }
                    let pick: Int
                    if mode == 0 || (mode == 2 && previous == nil) {
                        let shift = UInt64(row.count.leadingZeroBitCount)
                        var r = row.count
                        while r >= row.count { r = Int(truncatingIfNeeded: reference.next() >> shift) }
                        pick = r
                    } else {
                        var cumulative: [Double] = []
                        var total = 0.0
                        for e in row {
                            var x = mode == 1 || mode == 3 ? weightOf(e) : 1
                            if mode >= 2, let previous {
                                let t = g.oppositeVertex(to: u, acrossEdgeAt: e)
                                x *= t == previous ? 1 / p : g.neighbors(of: previous).contains(t) ? 1 : 1 / q
                            }
                            total += x
                            cumulative.append(total)
                        }
                        if total <= 0 { break }
                        let r = Double(reference.next() >> 11) * 0x1p-53 * total
                        pick = cumulative.firstIndex { $0 > r }!
                    }
                    taken.append(row[pick])
                    previous = u
                    u = g.oppositeVertex(to: u, acrossEdgeAt: row[pick])
                    vertices.append(u)
                }
                var generator = SeededRandomNumberGenerator(seed: UInt(seed))
                let walk = mode == 0 || mode == 2
                    ? g.randomWalk(from: source, length: length, returnParameter: p, inOutParameter: q, using: &generator)
                    : g.randomWalk(from: source, length: length, weight: weightOf, returnParameter: p, inOutParameter: q, using: &generator)
                #expect(walk.vertices == vertices, "\(name)")
                #expect(walk.edges == taken, "\(name)")
                #expect(Walk(vertices: walk.vertices, edges: walk.edges, in: g) != nil, "\(name)")
            }
            func weight(_ edge: UndirectedEdge<Int>) -> Double { Double((edge.u + edge.v) % 3) }
            let reference = ReferencePseudograph(vertices: 0 ..< 6, edges: edges)
            check(reference, { weight(reference.edges[$0]) }, "ReferencePseudograph")
            check(UnindexedPseudograph(base: reference), { weight(reference.edges[$0]) }, "without vertex indices")
            let pseudograph = Pseudograph(vertices: 0 ..< 6, edges: edges)
            check(pseudograph, { weight(pseudograph.edges[$0]) }, "Pseudograph")
            let list = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: edges)
            check(list, { weight(list.edges[$0]) }, "UndirectedAdjacencyList")
        }
    }

    @Test("TR-256 Float weights, String vertices")
    func otherTypes() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "a")])
        var generator = SeededRandomNumberGenerator(seed: 3)
        let walk = graph.randomWalk(from: "a", length: 4, weight: { _ in Float(0.5) }, using: &generator)
        #expect(walk.vertices == ["a", "b", "a", "b", "a"])
    }

    @Test("TR-257 a source that is not a vertex, a negative length, a parameter not positive and finite, or a bad weight traps")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).randomWalk(from: 5, length: 1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).randomWalk(from: 0, length: -1, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).randomWalk(from: 0, length: 1, returnParameter: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).randomWalk(from: 0, length: 1, inOutParameter: .infinity, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).randomWalk(from: 0, length: 1, weight: { _ in -1.0 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).randomWalk(from: 0, length: 1, weight: { _ in Double.nan }, using: &generator)
        }
    }
}
