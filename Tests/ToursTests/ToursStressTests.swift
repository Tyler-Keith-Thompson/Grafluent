// Large inputs, each inside a Task with a one-minute limit, meant to finish within seconds in a
// debug build; the benchmarks take timings. Expected values are known by construction: a torus is
// Eulerian (every degree 4) and a closed walk's arcs balance, so the circuit exists and is checked
// edge by edge; a long cycle's and path's walks are themselves, exactly (each vertex's first unused
// edge leads on); a long cycle, path and complete graph are their own first Hamiltonian cycle and
// path, two disjoint cliques and a transitive tournament have no cycle (the documented pruning makes
// the search fail fast), nor two cliques at a cut vertex (the reachability test alone does); nearest neighbour on collinear points walks the line; on points of a circle
// (Euclidean) Christofides' tree is the hull less one edge, so its tour is the hull order, 2-opt
// removes every crossing, which leaves the hull order, and Held–Karp's optimum is the hull order in
// its lexicographically least direction; a cycle with weights has one tour. See README.md.
// Conditions with a closure are computed into a constant before `#expect`: inside these closures a
// closure in an `#expect` expansion failed SIL verification with this toolchain (README.md).

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

@Suite("Tours on large inputs")
struct ToursStressTests {
    @Test("A 200 × 200 torus (40,000 vertices, 80,000 edges, every degree 4): Eulerian; the circuit uses every edge once, consecutively, from vertex 0; the trail is the circuit closed", .timeLimit(.minutes(1)))
    func torus() async {
        await Task {
            let r = 200, c = 200, n = r * c
            var ends: [(Int, Int)] = []
            for i in 0 ..< r {
                for j in 0 ..< c {
                    ends.append((i * c + j, i * c + (j + 1) % c))
                    ends.append((i * c + j, (i + 1) % r * c + j))
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.isEulerian && graph.hasEulerianTrail)
            guard let circuit = graph.eulerianCircuit() else {
                Issue.record("no circuit")
                return
            }
            #expect(circuit.vertices.count == ends.count && circuit.vertices.first == 0)
            var used = [Bool](repeating: false, count: ends.count)
            var genuine = true
            for (i, k) in circuit.edges.enumerated() {
                let x = circuit.vertices[i], y = circuit.vertices[(i + 1) % ends.count]
                let (a, b) = ends[k]
                if used[k] || !((a == x && b == y) || (a == y && b == x)) { genuine = false }
                used[k] = true
            }
            #expect(genuine && !used.contains(false))
            let trail = graph.eulerianTrail()
            let closed = trail == Trail(circuit)
            #expect(closed)
        }.value
    }

    @Test("A seeded directed closed walk of 200,000 arcs on 10,000 vertices (parallel arcs, self-loops): the circuit uses every arc once from vertex 0; without its last arc, the trail runs from the walk's start to that arc's tail", .timeLimit(.minutes(1)))
    func directedWalk() async {
        await Task {
            let n = 10_000, length = 200_000
            var x: UInt64 = 2026
            var walk = [0]
            while walk.count < length {
                x = x &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                walk.append(Int((x >> 33) % UInt64(n)))
            }
            // Make the last step come back to 0 from a vertex other than 0.
            if walk[walk.count - 1] == 0 { walk.append(1) }
            walk.append(0)
            let arcs = (0 ..< walk.count - 1).map { (walk[$0], walk[$0 + 1]) }
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(graph.isEulerian)
            guard let circuit = graph.eulerianCircuit() else {
                Issue.record("no circuit")
                return
            }
            var used = [Bool](repeating: false, count: arcs.count)
            var genuine = circuit.vertices.count == arcs.count && circuit.vertices.first == 0
            for (i, k) in circuit.edges.enumerated() {
                let (a, b) = arcs[k]
                if used[k] || a != circuit.vertices[i] || b != circuit.vertices[(i + 1) % arcs.count] { genuine = false }
                used[k] = true
            }
            #expect(genuine && !used.contains(false))

            let open = Array(arcs.dropLast())
            let tail = open[open.count - 1].1
            let opened = DirectedPseudograph(vertices: 0 ..< n, edges: open.map { DirectedEdge(from: $0.0, to: $0.1) })
            #expect(!opened.isEulerian && opened.hasEulerianTrail)
            guard let trail = opened.eulerianTrail() else {
                Issue.record("no trail")
                return
            }
            var trailUsed = [Bool](repeating: false, count: open.count)
            var trailGenuine = trail.vertices.count == open.count + 1 && trail.source == 0 && trail.target == tail
            for (i, k) in trail.edges.enumerated() {
                let (a, b) = open[k]
                if trailUsed[k] || a != trail.vertices[i] || b != trail.vertices[i + 1] { trailGenuine = false }
                trailUsed[k] = true
            }
            #expect(trailGenuine && !trailUsed.contains(false))
        }.value
    }

    @Test("C(100,000), Cd(100,000) and P(100,000): the Eulerian walks are the cycle and the path themselves, exactly, and from the middle the cycle backwards", .timeLimit(.minutes(1)))
    func longCycleAndPath() async {
        await Task {
            let n = 100_000
            let cycle = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            let circuit = cycle.eulerianCircuit()
            #expect(circuit?.vertices == Array(0 ..< n) && circuit?.edges == Array(0 ..< n))
            // From v the first edge in v's row is v−1's, so the walk runs backwards: v, v−1, …, 0, n−1, …, v+1.
            let v = n / 2
            let backwards = cycle.eulerianCircuit(from: v)
            let backwardVertices = Array((0 ... v).reversed()) + Array((v + 1 ..< n).reversed())
            let backwardEdges = Array((0 ..< v).reversed()) + Array((v ..< n).reversed())
            #expect(backwards?.vertices == backwardVertices && backwards?.edges == backwardEdges)
            let directed = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) })
            let directedCircuit = directed.eulerianCircuit()
            #expect(directedCircuit?.vertices == Array(0 ..< n) && directedCircuit?.edges == Array(0 ..< n))
            let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let trail = path.eulerianTrail()
            #expect(trail?.vertices == Array(0 ..< n) && trail?.edges == Array(0 ..< n - 1))
            let reversedTrail = path.eulerianTrail(from: n - 1)
            #expect(reversedTrail?.vertices == Array((0 ..< n).reversed()) && reversedTrail?.edges == Array((0 ..< n - 1).reversed()))
        }.value
    }

    @Test("Hamiltonian search at scale: C(3,000), P(3,000) and K(60) are their own first cycle and path; two disjoint K(12) and the transitive tournament on 40 vertices have none", .timeLimit(.minutes(1)))
    func hamiltonianAtScale() async {
        await Task {
            let n = 3_000
            let cycle = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            let hamiltonian = cycle.hamiltonianCycle()
            #expect(hamiltonian?.vertices == Array(0 ..< n) && hamiltonian?.edges == Array(0 ..< n))
            let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let hamiltonianPath = path.hamiltonianPath()
            #expect(hamiltonianPath?.vertices == Array(0 ..< n) && hamiltonianPath?.edges == Array(0 ..< n - 1))
            #expect(path.hamiltonianCycle() == nil)
            // K(60), pairs i < j lexicographic: the pair (i, j) is at i·(2·60 − i − 1)/2 + j − i − 1.
            let k = 60
            let complete = UndirectedAdjacencyList(vertices: 0 ..< k, edges: (0 ..< k).flatMap { i in (i + 1 ..< k).map { UndirectedEdge(i, $0) } })
            let position = { (i: Int, j: Int) in i * (2 * k - i - 1) / 2 + j - i - 1 }
            let completeCycle = complete.hamiltonianCycle()
            let completeEdges = (0 ..< k - 1).map { position($0, $0 + 1) } + [position(0, k - 1)]
            #expect(completeCycle?.vertices == Array(0 ..< k) && completeCycle?.edges == completeEdges)
            let twoCliques = UndirectedAdjacencyList(vertices: 0 ..< 24, edges: [0, 12].flatMap { o in (0 ..< 12).flatMap { i in (i + 1 ..< 12).map { UndirectedEdge(o + i, o + $0) } } })
            #expect(twoCliques.hamiltonianPath() == nil && twoCliques.hamiltonianCycle() == nil)
            let t = 40
            let transitive = AdjacencyList(vertices: 0 ..< t, edges: (0 ..< t).flatMap { i in (i + 1 ..< t).map { DirectedEdge(from: i, to: $0) } })
            let only = transitive.hamiltonianPath()
            #expect(only?.vertices == Array(0 ..< t))
            #expect(transitive.hamiltonianCycle() == nil)
        }.value
    }

    @Test("Two K(14) joined at a cut vertex 0: no Hamiltonian cycle and no path from 0, found at the first step by the reachability test (without it the search would try 13! orderings of the first clique); from 1 the path through the first clique, 0, then the second", .timeLimit(.minutes(1)))
    func reachabilityAtACutVertex() async {
        await Task {
            // Edges 0–i first, so each clique vertex's row starts at 0; then each clique's pairs. The degree
            // counts never fire here (every vertex keeps many free neighbours): only reachability does.
            let m = 14, n = 2 * m + 1
            var ends = (1 ..< n).map { (0, $0) }
            for base in [1, m + 1] {
                for i in base ..< base + m {
                    for j in i + 1 ..< base + m { ends.append((i, j)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.hamiltonianCycle() == nil)
            #expect(graph.hamiltonianPath(from: 0) == nil)
            let path = graph.hamiltonianPath()
            #expect(path?.vertices == Array(1 ... m) + [0] + Array(m + 1 ..< n))
            let genuine = path.map { Path(vertices: $0.vertices, edges: $0.edges, in: graph) != nil } ?? false
            #expect(genuine)
        }.value
    }

    @Test("Nearest neighbour on 400 collinear points (79,800 edges) walks the line: [0, 1, …, 399], weight 2 · 399", .timeLimit(.minutes(1)))
    func nearestNeighborOnALine() async {
        await Task {
            let n = 400
            let pairs = (0 ..< n).flatMap { i in (i + 1 ..< n).map { (i, $0) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let distance = pairs.map { $0.1 - $0.0 }
            let tour = graph.nearestNeighborTour(weight: { distance[$0] })
            #expect(tour?.vertices == Array(0 ..< n))
            let weight = tour?.weight({ distance[$0] })
            #expect(weight == 2 * (n - 1))
        }.value
    }

    @Test("Points on a circle, Euclidean: Christofides (150 points) and 2-opt from a seeded random tour (100 points) give the hull order; Held–Karp (15 points, integer millionths) the hull order in its lexicographically least direction", .timeLimit(.minutes(1)))
    func circlePoints() async {
        await Task {
            for (n, which) in [(150, 0), (100, 1), (15, 2)] {
                var rng = SeededRandomNumberGenerator(seed: UInt(n))
                // Distinct angles, then the points listed in a shuffled order; rank[v] is v's place around the circle.
                let angles = (0 ..< n).map { Double($0) * 2 * .pi / Double(n) + Double.random(in: 0 ..< 0.5, using: &rng) * 2 * .pi / Double(n) }
                var rank = Array(0 ..< n)
                rank.shuffle(using: &rng)
                let points = (0 ..< n).map { (cos(angles[rank[$0]]), sin(angles[rank[$0]])) }
                let pairs = (0 ..< n).flatMap { i in (i + 1 ..< n).map { (i, $0) } }
                let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
                let distance = pairs.map { ((points[$0.0].0 - points[$0.1].0) * (points[$0.0].0 - points[$0.1].0) + (points[$0.0].1 - points[$0.1].1) * (points[$0.0].1 - points[$0.1].1)).squareRoot() }
                let tour: Cycle<Int, Int>?
                let first: Int
                switch which {
                case 0:
                    tour = graph.christofidesTour(weight: { distance[$0] })
                    first = 0
                case 1:
                    var scrambled = Array(0 ..< n)
                    scrambled.shuffle(using: &rng)
                    first = scrambled[0]
                    let start = Cycle(vertices: scrambled, edges: Array(0 ..< n))!
                    tour = graph.twoOptTour(improving: start, weight: { distance[$0] })
                default:
                    // In millionths, rounded: a tour and its reverse then weigh exactly the same, so the
                    // direction is decided by the lexicographic rule alone.
                    let micro = distance.map { Int(($0 * 1_000_000).rounded()) }
                    tour = graph.shortestTour(weight: { micro[$0] })
                    first = 0
                }
                guard let order = tour?.vertices else {
                    Issue.record("no tour for \(n)")
                    continue
                }
                // The hull order: consecutive vertices one step apart around the circle, all the same way.
                let step = (rank[order[1]] - rank[order[0]] + n) % n
                let hull = (step == 1 || step == n - 1) && (0 ..< n).allSatisfy { (rank[order[($0 + 1) % n]] - rank[order[$0]] + n) % n == step }
                let hullFromFirst = hull && order.count == n && order[0] == first
                #expect(hullFromFirst, "\(n)")
                if which == 2 {
                    // Lexicographically least: of 0's two neighbours around the circle, the lesser second.
                    let neighbours = (0 ..< n).filter { (rank[$0] - rank[0] + n) % n == 1 || (rank[0] - rank[$0] + n) % n == 1 }
                    let leastDirection = order[1] == neighbours.min()
                    #expect(leastDirection, "\(n)")
                }
            }
        }.value
    }

    @Test("shortestTour on C(16) with seeded weights, a graph with one Hamiltonian cycle: that cycle and its weight", .timeLimit(.minutes(1)))
    func heldKarpOnACycle() async {
        await Task {
            let n = 16
            var rng = SeededRandomNumberGenerator(seed: 16)
            let weights = (0 ..< n).map { _ in Int.random(in: -5 ... 20, using: &rng) }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            let tour = graph.shortestTour(weight: { weights[$0] })
            #expect(tour?.vertices == Array(0 ..< n) && tour?.edges == Array(0 ..< n))
            let weight = tour?.weight({ weights[$0] })
            #expect(weight == weights.reduce(0, +))
        }.value
    }
}
