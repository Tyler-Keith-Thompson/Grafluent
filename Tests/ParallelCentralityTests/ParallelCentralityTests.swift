//
//  ParallelCentralityTests.swift
//  Grafluent
//
//  The parallel measures against the sequential ones, at several task counts and on several
//  representations.
//

import AdjacencyListModule
import AdjacencyMatrixModule
import Centrality
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import ParallelCentrality
import PropertyBased
import StableGraphs
import Testing

@Suite struct ParallelCentralityTests {
    @Test("PC-1 betweenness of a path and a star, undirected, at 1, 2 and 5 tasks", arguments: [1, 2, 5])
    func undirectedBetweenness(parallelism: Int) async {
        let path = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let star = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (1 ..< 5).map { UndirectedEdge(0, $0) })
        let pathScores = await path.betweennessCentrality(parallelism: parallelism)
        let starScores = await star.betweennessCentrality(parallelism: parallelism)
        let expectedPath = [0.0, 0.5, 2.0 / 3.0, 0.5, 0.0]
        let expectedStar = [1.0, 0.0, 0.0, 0.0, 0.0]
        for v in 0 ..< 5 {
            #expect(abs(pathScores.score(of: v) - expectedPath[v]) < 1e-12)
            #expect(abs(starScores.score(of: v) - expectedStar[v]) < 1e-12)
        }
        let rawPath = await path.betweennessCentrality(parallelism: parallelism, normalized: false)
        let sequentialRaw = path.betweennessCentrality(normalized: false)
        for v in 0 ..< 5 { #expect(abs(rawPath.score(of: v) - sequentialRaw.score(of: v)) < 1e-12) }
        let ends = await path.betweennessCentrality(parallelism: parallelism, normalized: false, endpoints: true)
        let sequentialEnds = path.betweennessCentrality(normalized: false, endpoints: true)
        for v in 0 ..< 5 { #expect(abs(ends.score(of: v) - sequentialEnds.score(of: v)) < 1e-12) }
    }

    @Test("PC-2 directed betweenness, closeness and harmonic of a cycle with a chord agree with the sequential measures", arguments: [1, 3, 100])
    func directedMeasures(parallelism: Int) async {
        let graph = AdjacencyList<Int>(vertices: 0 ..< 6, edges: (0 ..< 6).map { DirectedEdge(from: $0, to: ($0 + 1) % 6) } + [DirectedEdge(from: 0, to: 3)])
        let betweenness = await graph.betweennessCentrality(parallelism: parallelism)
        let closeness = await graph.closenessCentrality(parallelism: parallelism)
        let plain = await graph.closenessCentrality(parallelism: parallelism, wfImproved: false)
        let harmonic = await graph.harmonicCentrality(parallelism: parallelism)
        let sequentialBetweenness = graph.betweennessCentrality()
        let sequentialCloseness = graph.closenessCentrality()
        let sequentialPlain = graph.closenessCentrality(wfImproved: false)
        let sequentialHarmonic = graph.harmonicCentrality()
        for v in 0 ..< 6 {
            #expect(abs(betweenness.score(of: v) - sequentialBetweenness.score(of: v)) < 1e-12)
            #expect(closeness.score(of: v) == sequentialCloseness.score(of: v))
            #expect(plain.score(of: v) == sequentialPlain.score(of: v))
            #expect(harmonic.score(of: v) == sequentialHarmonic.score(of: v))
        }
        // Vertex 3 is reached by 2 at distance 1, by 1 at 2, by 0 at 1 (the chord), by 5 at 2 (through
        // the chord) and by 4 at 3.
        let expectedHarmonic = 1.0 + 1.0 / 2 + 1.0 + 1.0 / 2 + 1.0 / 3
        #expect(abs(harmonic.score(of: 3) - expectedHarmonic) < 1e-12)
    }

    @Test("PC-3 weighted betweenness, both kinds, agrees with the sequential measure at 1 and 4 tasks", arguments: [1, 4])
    func weighted(parallelism: Int) async {
        var directed = DirectedPseudograph<String>(vertices: ["a", "b", "c", "d"])
        let w = directed.addEdgeMap(default: 1.0)
        let ab = directed.insert(edge: DirectedEdge(from: "a", to: "b"))
        let bc = directed.insert(edge: DirectedEdge(from: "b", to: "c"))
        let ac = directed.insert(edge: DirectedEdge(from: "a", to: "c"))
        let cd = directed.insert(edge: DirectedEdge(from: "c", to: "d"))
        let ab2 = directed.insert(edge: DirectedEdge(from: "a", to: "b"))
        directed[w, ofEdgeAt: ab] = 1
        directed[w, ofEdgeAt: bc] = 1
        directed[w, ofEdgeAt: ac] = 2
        directed[w, ofEdgeAt: cd] = 0.5
        directed[w, ofEdgeAt: ab2] = 1
        let weights = directed.values(of: w)
        let parallel = await directed.betweennessCentrality(weight: { weights[$0] }, parallelism: parallelism, normalized: false)
        let sequential = directed.betweennessCentrality(weight: { weights[$0] }, normalized: false)
        for v in ["a", "b", "c", "d"] { #expect(abs(parallel.score(of: v) - sequential.score(of: v)) < 1e-12) }
        // c is interior to every a→d path (three of them, all of length 2.5) and to the one b→d path.
        let expectedC = 2.0
        #expect(abs(parallel.score(of: "c") - expectedC) < 1e-12)

        let undirected = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(0, 4), UndirectedEdge(1, 3)])
        let lengths = [3, 1, 1, 1, 7, 1]
        let parallelUndirected = await undirected.betweennessCentrality(weight: { lengths[$0] }, parallelism: parallelism, endpoints: true)
        let sequentialUndirected = undirected.betweennessCentrality(weight: { lengths[$0] }, endpoints: true)
        for v in 0 ..< 5 { #expect(abs(parallelUndirected.score(of: v) - sequentialUndirected.score(of: v)) < 1e-12) }
    }

    @Test("PC-4 the empty graph, one vertex, and a graph with self-loops and no edges between others")
    func degenerate() async {
        let empty = AdjacencyList<Int>()
        let one = UndirectedAdjacencyList<Int>(vertices: [7])
        let loops = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 2, to: 2)])
        let emptyScores = await empty.betweennessCentrality(parallelism: 4)
        let emptyCloseness = await empty.closenessCentrality(parallelism: nil)
        #expect(emptyScores.scores.isEmpty)
        #expect(emptyCloseness.scores.isEmpty)
        let oneScores = await one.betweennessCentrality(parallelism: 3)
        let oneHarmonic = await one.harmonicCentrality(parallelism: 3)
        #expect(oneScores.score(of: 7) == 0)
        #expect(oneHarmonic.score(of: 7) == 0)
        let loopScores = await loops.betweennessCentrality(parallelism: 2, normalized: false)
        let loopCloseness = await loops.closenessCentrality(parallelism: 2)
        for v in 0 ..< 3 {
            #expect(loopScores.score(of: v) == 0)
            #expect(loopCloseness.score(of: v) == 0)
        }
    }

    @Test("PC-5 the default task count is at least one, and nil runs the measures")
    func defaults() async {
        #expect(defaultParallelism >= 1)
        let graph = CompressedSparseRow(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
        let parallel = await graph.betweennessCentrality(parallelism: nil, normalized: false)
        let harmonic = await graph.harmonicCentrality(parallelism: nil)
        let sequential = graph.betweennessCentrality(normalized: false)
        let sequentialHarmonic = graph.harmonicCentrality()
        for v in 0 ..< 4 {
            #expect(abs(parallel.score(of: v) - sequential.score(of: v)) < 1e-12)
            #expect(harmonic.score(of: v) == sequentialHarmonic.score(of: v))
        }
    }

    @Test("PC-6 a stable graph with holes, a vertex type without indices, agrees at every task count", arguments: [1, 2, 3, 8])
    func stableGraphWithHoles(parallelism: Int) async {
        var graph = StableDirectedGraph<String>(vertices: ["a", "b", "c", "d", "e", "gone"])
        graph.insert(edge: DirectedEdge(from: "a", to: "b"))
        graph.insert(edge: DirectedEdge(from: "b", to: "c"))
        graph.insert(edge: DirectedEdge(from: "c", to: "d"))
        graph.insert(edge: DirectedEdge(from: "d", to: "e"))
        graph.insert(edge: DirectedEdge(from: "e", to: "a"))
        let removed = graph.insert(edge: DirectedEdge(from: "gone", to: "a"))
        graph.remove(edgeAt: removed)
        graph.remove("gone")
        let betweenness = await graph.betweennessCentrality(parallelism: parallelism)
        let closeness = await graph.closenessCentrality(parallelism: parallelism)
        let sequential = graph.betweennessCentrality()
        let sequentialCloseness = graph.closenessCentrality()
        for v in ["a", "b", "c", "d", "e"] {
            #expect(abs(betweenness.score(of: v) - sequential.score(of: v)) < 1e-12)
            #expect(closeness.score(of: v) == sequentialCloseness.score(of: v))
        }
        #expect(throws: VertexNotFound.self) { try betweenness.score(checked: "gone") }
    }

    @Test("PC-7 zero or negative parallelism traps", .tags(.precondition))
    func parallelismTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = await graph.betweennessCentrality(parallelism: 0)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = await graph.closenessCentrality(parallelism: -1)
        }
    }

    @Test("PC-8 a weight of zero traps in the weighted parallel measure", .tags(.precondition))
    func zeroWeightTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
            _ = await graph.betweennessCentrality(weight: { _ in 0 }, parallelism: 2)
        }
    }

    @Test("PC-9 random graphs: every parallel measure agrees with the sequential one at every task count")
    func randomGraphs() async {
        let edges = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 11)).array(of: 0 ... 40)
        await propertyCheck(count: 60, input: edges, Gen.int(in: 1 ... 13)) { raw, parallelism in
            let directed = AdjacencyList<Int>(vertices: 0 ..< 12, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< 12, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let weights = (0 ..< directed.edgeCount).map { Double($0 % 5 + 1) }
            let undirectedWeights = (0 ..< undirected.edgeCount).map { ($0 % 3) + 1 }
            let a = await directed.betweennessCentrality(parallelism: parallelism)
            let b = directed.betweennessCentrality()
            let c = await directed.betweennessCentrality(weight: { weights[$0] }, parallelism: parallelism, endpoints: true)
            let d = directed.betweennessCentrality(weight: { weights[$0] }, endpoints: true)
            let e = await directed.closenessCentrality(parallelism: parallelism)
            let f = directed.closenessCentrality()
            let g = await directed.harmonicCentrality(parallelism: parallelism)
            let h = directed.harmonicCentrality()
            let i = await undirected.betweennessCentrality(parallelism: parallelism, normalized: false)
            let j = undirected.betweennessCentrality(normalized: false)
            let k = await undirected.betweennessCentrality(weight: { undirectedWeights[$0] }, parallelism: parallelism)
            let l = undirected.betweennessCentrality(weight: { undirectedWeights[$0] })
            let m = await undirected.closenessCentrality(parallelism: parallelism, wfImproved: false)
            let n = undirected.closenessCentrality(wfImproved: false)
            let o = await undirected.harmonicCentrality(parallelism: parallelism)
            let p = undirected.harmonicCentrality()
            for v in 0 ..< 12 {
                #expect(abs(a.score(of: v) - b.score(of: v)) <= 1e-9 * max(1, b.score(of: v)), "betweenness \(raw) \(parallelism)")
                #expect(abs(c.score(of: v) - d.score(of: v)) <= 1e-9 * max(1, d.score(of: v)), "weighted betweenness \(raw) \(parallelism)")
                #expect(e.score(of: v) == f.score(of: v), "closeness \(raw) \(parallelism)")
                #expect(g.score(of: v) == h.score(of: v), "harmonic \(raw) \(parallelism)")
                #expect(abs(i.score(of: v) - j.score(of: v)) <= 1e-9 * max(1, j.score(of: v)), "undirected betweenness \(raw) \(parallelism)")
                #expect(abs(k.score(of: v) - l.score(of: v)) <= 1e-9 * max(1, l.score(of: v)), "undirected weighted betweenness \(raw) \(parallelism)")
                #expect(m.score(of: v) == n.score(of: v), "undirected closeness \(raw) \(parallelism)")
                #expect(o.score(of: v) == p.score(of: v), "undirected harmonic \(raw) \(parallelism)")
            }
        }
    }

    @Test("PC-10 the same input gives the same scores bit for bit on repeated runs")
    func deterministic() async {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 30, edges: (0 ..< 30).flatMap { v in [UndirectedEdge(v, (v + 1) % 30), UndirectedEdge(v, (v * 7 + 3) % 30)] })
        let first = await graph.betweennessCentrality(parallelism: 4)
        for _ in 0 ..< 5 {
            let again = await graph.betweennessCentrality(parallelism: 4)
            #expect(again.scores == first.scores)
        }
    }
}
