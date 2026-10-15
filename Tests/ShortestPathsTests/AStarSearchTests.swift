// A* as an event sequence (`aStarSearch`): a hand-traced graph with an inconsistent heuristic
// (reopening, a loop, a parallel copy) on every representation, a grid, the trivial cases, a zero
// heuristic against `dijkstraSearch`, an undirected graph, value semantics, the preconditions, and
// a property test replaying the events against `aStarShortestPath`. Case IDs (SP-nn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import ShortestPaths
import StableGraphs
import Testing

/// A directed multigraph with no vertex indices, so the search numbers its vertices itself.
private struct UnindexedDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("A* search events")
struct AStarSearchTests {
    @Test("SP-201 an inconsistent heuristic: every event in order, reopening twice, on every representation", .tags(.fixture, .selfLoops))
    func handTraced() {
        // Row order: 0→1 (1), 0→2 (4), 0→2 (6), 1→2 (1), 1→1 (2), 2→3 (1), 3→4 (5); to 4, h = 0, 5, 0, 0, 0.
        let raw: [(Int, Int, Int)] = [(0, 1, 1), (0, 2, 4), (0, 2, 6), (1, 2, 1), (1, 1, 2), (2, 3, 1), (3, 4, 5)]
        let edges = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
        let h = [0, 5, 0, 0, 7]
        // Tests/Catalogs/ShortestPaths/cases_astarsearch.out, SP-201.
        let expected: [AStarSearchEvent<Int, Int, Int>] = [
            .discover(0, distance: 0, estimate: 0), .examine(0, distance: 0, estimate: 0),
            .examineEdge(0, distance: 1), .edgeRelaxed(0, distance: 1), .discover(1, distance: 1, estimate: 5),
            .examineEdge(1, distance: 4), .edgeRelaxed(1, distance: 4), .discover(2, distance: 4, estimate: 0),
            .examineEdge(2, distance: 6), .edgeNotRelaxed(2, distance: 4), .finish(0, distance: 0),
            .examine(2, distance: 4, estimate: 0),
            .examineEdge(5, distance: 5), .edgeRelaxed(5, distance: 5), .discover(3, distance: 5, estimate: 0), .finish(2, distance: 4),
            .examine(3, distance: 5, estimate: 0),
            .examineEdge(6, distance: 10), .edgeRelaxed(6, distance: 10), .discover(4, distance: 10, estimate: 0), .finish(3, distance: 5),
            .examine(1, distance: 1, estimate: 5),
            .examineEdge(3, distance: 2), .edgeRelaxed(3, distance: 2), .reopen(2, distance: 2, estimate: 0),
            .examineEdge(4, distance: 3), .edgeNotRelaxed(4, distance: 1), .finish(1, distance: 1),
            .examine(2, distance: 2, estimate: 0),
            .examineEdge(5, distance: 3), .edgeRelaxed(5, distance: 3), .reopen(3, distance: 3, estimate: 0), .finish(2, distance: 2),
            .examine(3, distance: 3, estimate: 0),
            .examineEdge(6, distance: 8), .edgeRelaxed(6, distance: 8), .finish(3, distance: 3),
            .examine(4, distance: 8, estimate: 0),
        ]
        func check<G: DirectedGraph<Int>>(_ g: G) where G.Edges.Index == Int {
            var estimated: [Int] = []
            let events = Array(g.aStarSearch(from: 0, to: 4, weight: { raw[$0].2 }, heuristic: { estimated.append($0); return h[$0] }))
            #expect(events == expected, "\(G.self)")
            #expect(estimated == [0, 1, 2, 3], "\(G.self): once per vertex, never the target")
            let plain = g.aStarShortestPath(from: 0, to: 4, weight: { raw[$0].2 }, heuristic: { h[$0] })
            #expect(plain?.path.edges == [0, 3, 5, 6] && plain?.distance == 8, "\(G.self)")
        }
        check(ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: edges))
        check(DirectedPseudograph(vertices: 0 ..< 5, edges: edges))
        check(UnindexedDigraph(vertices: Array(0 ..< 5), edges: edges))
        var stable = StableDirectedGraph(vertices: [99] + Array(0 ..< 5), edges: edges)
        stable.remove(99)
        check(stable)
        #expect(expected[0].description == "discover(0, 0, 0)")
        #expect(expected[24].description == "reopen(2, 2, 0)")
        #expect(expected[9].description == "edgeNotRelaxed(2, 4)")
        #expect(expected.suffix(3).map(\.description) == ["edgeRelaxed(6, 8)", "finish(3, 3)", "examine(4, 8, 0)"])
        #expect(expected[2].description == "examineEdge(0, 1)" && expected[10].description == "finish(0, 0)")
    }

    @Test("SP-202 a 3 × 3 grid with 4 → 5 blocked, Manhattan estimate to the far corner: a consistent estimate closes each vertex once, in nondecreasing priority", .tags(.fixture))
    func grid() {
        var arcs: [DirectedEdge<Int>] = []
        for r in 0 ..< 3 {
            for c in 0 ..< 3 {
                for (dr, dc) in [(0, 1), (1, 0), (0, -1), (-1, 0)] where (0 ..< 3).contains(r + dr) && (0 ..< 3).contains(c + dc) {
                    if 3 * r + c == 4 && 3 * (r + dr) + c + dc == 5 { continue }
                    arcs.append(DirectedEdge(from: 3 * r + c, to: 3 * (r + dr) + c + dc))
                }
            }
        }
        let graph = AdjacencyList(vertices: 0 ..< 9, edges: arcs)
        let events = Array(graph.aStarSearch(from: 0, to: 8, weight: { _ in 1 }, heuristic: { (2 - $0 / 3) + (2 - $0 % 3) }))
        // Every priority is 4 (every vertex lies on a shortest route but 4 → 5 is blocked), so the
        // ties decide which vertices close before 8; each closes once.
        let examined = events.compactMap { event -> Int? in if case .examine(let v, let d, let h) = event { d + h == 4 ? v : -1 } else { nil } }
        #expect(!examined.contains(-1) && Set(examined).count == examined.count && examined.first == 0 && examined.last == 8)
        #expect(!events.contains { if case .reopen = $0 { true } else { false } })
        #expect(events.last == .examine(8, distance: 4, estimate: 0))
        var parent: [Int: Int] = [:]
        for case .edgeRelaxed(let e, _) in events { parent[graph.target(ofEdgeAt: e)] = e }
        var chain: [Int] = []
        var v = 8
        while v != 0 { chain.append(parent[v]!); v = graph.source(ofEdgeAt: parent[v]!) }
        #expect(chain.reversed() == graph.aStarShortestPath(from: 0, to: 8, weight: { _ in 1 }, heuristic: { (2 - $0 / 3) + (2 - $0 % 3) })!.path.edges)
    }

    @Test("SP-203 the source is the target; an unreachable target; descriptions with Double weights")
    func trivial() {
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0)])
        var calls = 0
        let alone = Array(graph.aStarSearch(from: 1, to: 1, weight: { _ in 1 }, heuristic: { _ in calls += 1; return 9 }))
        #expect(alone == [.discover(1, distance: 0, estimate: 0), .examine(1, distance: 0, estimate: 0)])
        #expect(calls == 0)
        // 2 is never reached: the search ends when nothing is open, after finishing 1.
        let away = Array(graph.aStarSearch(from: 0, to: 2, weight: { _ in 2.5 }, heuristic: { _ in 0 }))
        #expect(away.map(\.description) == [
            "discover(0, 0.0, 0.0)", "examine(0, 0.0, 0.0)", "examineEdge(0, 2.5)", "edgeRelaxed(0, 2.5)",
            "discover(1, 2.5, 0.0)", "finish(0, 0.0)", "examine(1, 2.5, 0.0)", "finish(1, 2.5)",
        ])
        #expect(graph.aStarShortestPath(from: 0, to: 2, weight: { _ in 2.5 }, heuristic: { _ in 0 }) == nil)
    }

    @Test("SP-204 a zero heuristic examines vertices in dijkstraSearch's order, up to the target")
    func zeroHeuristic() {
        var rng = SeededRandomNumberGenerator(seed: 204)
        let edges = (0 ..< 300).map { _ in DirectedEdge(from: Int.random(in: 0 ..< 60, using: &rng), to: Int.random(in: 0 ..< 60, using: &rng)) }
        let graph = CompressedSparseRow(vertexCount: 60, edges: edges)
        let weights = (0 ..< graph.edgeCount).map { _ in Int.random(in: 0 ... 9, using: &rng) }
        let dijkstra = graph.dijkstraSearch(from: 0) { weights[$0] }.compactMap { event -> Int? in if case .examine(let v, _) = event { v } else { nil } }
        let target = dijkstra[dijkstra.count / 2]
        let aStar = graph.aStarSearch(from: 0, to: target, weight: { weights[$0] }, heuristic: { _ in 0 }).compactMap { event -> Int? in if case .examine(let v, _, _) = event { v } else { nil } }
        #expect(aStar == Array(dijkstra.prefix(through: dijkstra.count / 2)))
    }

    @Test("SP-205 undirected: each edge examined from both ends; the distance and path of aStarShortestPath")
    func undirected() {
        let raw: [(Int, Int, Int)] = [(0, 1, 2), (1, 2, 2), (0, 2, 5), (2, 3, 1), (1, 3, 6), (3, 3, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: raw.map { UndirectedEdge($0.0, $0.1) })
        let h = [3, 2, 1, 0]
        let events = Array(graph.aStarSearch(from: 0, to: 3, weight: { raw[$0].2 }, heuristic: { h[$0] }))
        let plain = graph.aStarShortestPath(from: 0, to: 3, weight: { raw[$0].2 }, heuristic: { h[$0] })!
        #expect(events.last == .examine(3, distance: 5, estimate: 0) && plain.distance == 5)
        var parent: [Int: DirectedView<UndirectedAdjacencyList<Int>>.Edges.Index] = [:]
        for case .edgeRelaxed(let arc, _) in events { parent[graph.directedView.target(ofEdgeAt: arc)] = arc }
        var chain: [DirectedView<UndirectedAdjacencyList<Int>>.Edges.Index] = []
        var v = 3
        while v != 0 { chain.append(parent[v]!); v = graph.directedView.source(ofEdgeAt: parent[v]!) }
        #expect(chain.reversed().map(\.position) == [0, 1, 3])
        #expect(plain.path.edges.map(\.position) == [0, 1, 3])
        // Edge 0–1 is read from 0 and again from 1 (into the closed 0, not relaxed).
        let reads = events.compactMap { event -> Int? in if case .examineEdge(let arc, _) = event { arc.position } else { nil } }
        #expect(reads.filter { $0 == 0 }.count == 2)
    }

    @Test("SP-206 value semantics: a later insertion does not change the search; each iterator starts over; stopping early")
    func valueSemantics() {
        var graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let search = graph.aStarSearch(from: 0, to: 2, weight: { _ in 1 }, heuristic: { _ in 0 })
        _ = graph.insert(edge: DirectedEdge(from: 0, to: 2))
        let first = Array(search)
        #expect(first.count == 12)
        #expect(Array(search) == first)
        #expect(Array(search.prefix(2)) == Array(first.prefix(2)))
        var iterator = search.makeIterator()
        for _ in first { _ = iterator.next() }
        #expect(iterator.next() == nil)
        #expect(iterator.next() == nil)
    }

    @Test("SP-207 a negative examined weight, a missing source or target trap; a negative edge never examined does not")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            for _ in graph.aStarSearch(from: 0, to: 1, weight: { _ in -1 }, heuristic: { _ in 0 }) {}
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.aStarSearch(from: 5, to: 1, weight: { _ in 1 }, heuristic: { _ in 0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UnindexedDigraph(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.aStarSearch(from: 0, to: 5, weight: { _ in 1 }, heuristic: { _ in 0 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            for _ in graph.aStarSearch(from: 0, to: 1, weight: { _ in -1 }, heuristic: { _ in 0 }) {}
        }
        // The edge into 2 traps as it is examined, before it is relaxed.
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(vertices: 0 ..< 2, edges: [DirectedEdge(from: 0, to: 1)])
            var events = graph.aStarSearch(from: 0, to: 1, weight: { _ in -1 }, heuristic: { _ in 0 }).makeIterator()
            for _ in 0 ..< 3 { _ = events.next() }
        }
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let events = Array(graph.aStarSearch(from: 0, to: 1, weight: { [1, -5][$0] }, heuristic: { _ in 0 }))
        #expect(events.last == .examine(1, distance: 1, estimate: 0))
    }

    @Test("SP-208 property: admissible, possibly inconsistent estimates; the target's relaxed-edge chain and distance are aStarShortestPath's", .tags(.randomized))
    func property() async {
        // Up to 30 edges on vertices 0..<8 with weights 0...9; repeats and self-loops allowed; the
        // estimate of v is the smaller of its true distance to the target and a random 0...9.
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 9)).array(of: 0 ... 30)
        let guesses = Gen.int(in: 0 ... 9).array(of: 8)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 7), guesses) { raw, target, guess in
            // Distances to the target by Bellman–Ford over the reversed edges.
            var toTarget = [Int?](repeating: nil, count: 8)
            toTarget[target] = 0
            for _ in 0 ..< 8 {
                for (u, v, w) in raw { if let d = toTarget[v], toTarget[u].map({ d + w < $0 }) ?? true { toTarget[u] = d + w } }
            }
            let h = (0 ..< 8).map { min(toTarget[$0] ?? 9, guess[$0]) }
            let arcs = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            func check<G: DirectedGraph<Int>>(_ graph: G, _ name: String) where G.Edges.Index == Int {
                let events = Array(graph.aStarSearch(from: 0, to: target, weight: { raw[$0].2 }, heuristic: { h[$0] }))
                let plain = graph.aStarShortestPath(from: 0, to: target, weight: { raw[$0].2 }, heuristic: { h[$0] })
                var parent: [Int: Int] = [:]
                var state = [Int](repeating: 0, count: 8)
                var current = -1
                var pending = -1
                var reached: Int?
                for event in events {
                    switch event {
                    case .discover(let v, _, let e):
                        #expect(state[v] == 0 && e == (v == target ? 0 : h[v]), "\(name)")
                        state[v] = 1
                    case .examine(let v, let d, _):
                        #expect(state[v] == 1, "\(name)")
                        state[v] = 2
                        current = v
                        if v == target { reached = d }
                    case .examineEdge(let e, let d):
                        #expect(pending == -1 && raw[e].0 == current && d >= raw[e].2, "\(name)")
                        pending = e
                    case .edgeRelaxed(let e, _):
                        #expect(e == pending, "\(name)")
                        parent[raw[e].1] = e
                        if state[raw[e].1] == 1 { pending = -1 } else { pending = -2 }
                    case .edgeNotRelaxed(let e, _):
                        #expect(e == pending, "\(name)")
                        pending = -1
                    case .reopen(let v, _, _):
                        #expect(pending == -2 && state[v] == 2, "\(name)")
                        state[v] = 1
                        pending = -1
                    case .finish(let v, _):
                        #expect(v == current && pending == -1, "\(name)")
                    }
                    if case .discover = event, pending == -2 { pending = -1 }
                }
                #expect(reached == plain?.distance && reached == toTarget[0], "\(name)")
                guard let plain else { return }
                var chain: [Int] = []
                var v = target
                while v != 0, let e = parent[v], chain.count < 8 {
                    chain.append(e)
                    v = raw[e].0
                }
                #expect(Array(chain.reversed()) == plain.path.edges, "\(name)")
            }
            check(ReferenceDirectedMultigraph(vertices: 0 ..< 8, edges: arcs), "reference multigraph")
            check(DirectedPseudograph(vertices: 0 ..< 8, edges: arcs), "pseudograph")
            check(UnindexedDigraph(vertices: Array(0 ..< 8), edges: arcs), "unindexed")
        }
    }
}
