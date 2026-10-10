// Inputs found by planted-bug (mutation) testing and by fuzzing (`FuzzTours`), each pinning a rule
// no catalog row isolates. Expected values are worked out in each test's comments, or computed in
// the test from a procedure written out in it. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

@Suite("Tours regressions")
struct ToursRegressionTests {
    @Test("Directed: one vertex with out − in = 1 and one with in − out = 1 is not enough when another is unbalanced by 2")
    func directedTrailNeedsTheRestBalanced() {
        // Edges 0→2, 2→3, 2→3, 2→1: out − in is +1 at 0, −1 at 1, +2 at 2, −2 at 3. Every vertex is
        // reached from 0, so only the balance rule says no.
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 1),
        ])
        #expect(!graph.hasEulerianTrail)
        #expect(!graph.isEulerian)
        #expect(graph.eulerianTrail() == nil)
        #expect(graph.eulerianTrail(from: 0) == nil)
    }

    @Test("Directed: a trail is found from its start even when the first vertex with an edge reaches nothing")
    func directedTrailReachedFromItsStart() throws {
        // 1→0: vertex 0 comes first and has an edge, but no out-edge; the trail starts at 1.
        let graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [DirectedEdge(from: 1, to: 0)])
        #expect(graph.hasEulerianTrail)
        #expect(!graph.isEulerian)
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [1, 0] && trail.edges == [0])
        // The same on a longer one: 2→1→0 with 0 first.
        let path = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1)])
        #expect(path.hasEulerianTrail)
        let walk = try #require(path.eulerianTrail())
        #expect(walk.vertices == [2, 1, 0] && walk.edges == [1, 0])
    }

    @Test("FuzzTours: Hierholzer on edges in two components stops cleanly (it read before its edge buffer when the walk ended early)")
    func hierholzerMissingEdges() {
        // Self-loops at two vertices: each is even (balanced), but the edges are not connected.
        // The walk from vertex 0 takes its two loops and ends with edges left; the last pop used
        // to copy the edge below the bottom of the stack.
        let directed = DirectedPseudograph<Int>(vertices: [1, 0], edges: [
            DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 0),
        ])
        #expect(!directed.isEulerian && !directed.hasEulerianTrail)
        #expect(directed.eulerianCircuit() == nil && directed.eulerianTrail() == nil)
        #expect(directed.eulerianCircuit(from: 0) == nil && directed.eulerianTrail(from: 0) == nil)
        let undirected = Pseudograph<Int>(vertices: [1, 0], edges: [
            UndirectedEdge(0, 0), UndirectedEdge(1, 1), UndirectedEdge(1, 1), UndirectedEdge(0, 0),
        ])
        #expect(!undirected.isEulerian && !undirected.hasEulerianTrail)
        #expect(undirected.eulerianCircuit() == nil && undirected.eulerianTrail() == nil)
        #expect(undirected.eulerianCircuit(from: 0) == nil && undirected.eulerianTrail(from: 0) == nil)
    }

    @Test("Hamiltonian cycle through a cut vertex: K(5) and K(14) joined only through one vertex have none, found without walking K(14) once K(5) is left unfinished; undirected and directed", .timeLimit(.minutes(1)))
    func cutVertexNeedsReachability() async {
        await Task {
            // A = 0 ..< 5, c = 5, B = 6 ..< 20, c joined to every vertex of A and of B. A cycle would
            // pass c twice, so there is none. Each vertex keeps two neighbours (a predecessor and a
            // successor) inside its own clique however far the search has gone, so the degree
            // rules never cut; only reachability does, on the step from c into B while A has
            // vertices left. Without it every ordering of B (13!) is tried.
            var pairs: [(Int, Int)] = []
            for u in 0 ..< 6 { for v in u + 1 ..< 6 { pairs.append((u, v)) } }
            for u in 5 ..< 20 { for v in u + 1 ..< 20 { pairs.append((u, v)) } }
            let undirected = UndirectedAdjacencyList<Int>(vertices: 0 ..< 20, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(undirected.hamiltonianCycle() == nil)
            let directed = AdjacencyList<Int>(vertices: 0 ..< 20, edges: pairs.flatMap { [DirectedEdge(from: $0.0, to: $0.1), DirectedEdge(from: $0.1, to: $0.0)] })
            #expect(directed.hamiltonianCycle() == nil)
        }.value
    }

    @Test("twoOptTour(improving:) is JGraphT's best-improvement procedure, written out, on 400 seeded complete graphs of 9 to 16 vertices with weights 0, 1 and 2 (many tied moves)")
    func twoOptTiesAgainstTheProcedure() throws {
        // JGraphT `TwoOptHeuristicTSP.improve`: each round the move (i, j), 0 ≤ i < n − 2,
        // i + 2 ≤ j < n, of the greatest gain d(t[i], t[i+1]) + d(t[j], t[j+1]) − d(t[i], t[j]) −
        // d(t[i+1], t[j+1]), the first in row-major order on ties, reversing t[i+1 ... j]; stop when
        // no gain is positive. Small weights tie many moves, so the incremental bookkeeping's tie
        // rule (the lower column) is what decides.
        var rng = SeededRandomNumberGenerator(seed: 41)
        for round in 0 ..< 400 {
            let n = 9 + Int(rng.next() % 8)
            var edges: [UndirectedEdge<Int>] = [], weights: [Int] = []
            var d = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
            for u in 0 ..< n {
                for v in u + 1 ..< n {
                    let w = Int(rng.next() % 3)
                    edges.append(UndirectedEdge(u, v))
                    weights.append(w)
                    d[u][v] = w
                    d[v][u] = w
                }
            }
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: edges)
            var start = Array(0 ..< n)
            for i in stride(from: n - 1, to: 0, by: -1) { start.swapAt(i, Int(rng.next() % UInt64(i + 1))) }
            var t = start + [start[0]]
            while true {
                var best = 0, bi = -1, bj = -1
                for i in 0 ..< n - 2 {
                    for j in i + 2 ..< n {
                        let gain = d[t[i]][t[i + 1]] + d[t[j]][t[j + 1]] - d[t[i]][t[j]] - d[t[i + 1]][t[j + 1]]
                        if gain > best {
                            best = gain
                            bi = i
                            bj = j
                        }
                    }
                }
                if bi < 0 { break }
                t[(bi + 1) ... bj].reverse()
            }
            let initial = try #require(Cycle(start, in: graph))
            let improved = try #require(graph.twoOptTour(improving: initial, weight: { weights[$0] }))
            #expect(improved.vertices == Array(t.dropLast()), "round \(round): \(n) vertices, weights \(weights), from \(start)")
        }
    }

    @Test("twoOptTour(improving:) below three vertices is nil, as the other tours: two parallel edges make a Cycle, but not a tour")
    func twoOptImprovingSmall() throws {
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let cycle = try #require(Cycle(vertices: [0, 1], edges: [0, 1], in: graph))
        #expect(graph.twoOptTour(improving: cycle, weight: { _ in 1 }) == nil)
    }

    @Test("christofidesTour with Int8 weights traps just past the matching's bound: n = 3 allows |weight| ≤ (⌊⌊127 / 8⌋ / 3⌋ − 1) / 2 = 2, so 3 traps")
    func christofidesInt8Bound() async {
        // 2 is accepted: K(3) with weights 2, 2, −2 is a tour of weight 2.
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
        let ok: [Int8] = [2, 2, -2]
        #expect(graph.christofidesTour(weight: { ok[$0] })?.weight({ ok[$0] }) == 2)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
            let weights: [Int8] = [1, 1, 3]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
            let weights: [Int8] = [1, 1, -3]
            _ = graph.christofidesTour(weight: { weights[$0] })
        }
    }
}
