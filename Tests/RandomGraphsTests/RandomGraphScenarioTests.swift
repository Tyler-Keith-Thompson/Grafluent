// Scenarios the catalog rows are too small for: the random geometric graph's cell grid against
// every pair at n ≈ 2000 (irregular radii, radius 0, and 3^d > n, where every pair is checked), in
// both forms; and random DAGs built in bulk, then mutated by a random script of insertions and
// removals against a model written out here. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("RandomGraphs scenarios")
struct RandomGraphScenarioTests {
    @Test("Random geometric up to n ≈ 2000: the cell grid finds exactly the pairs a check of every pair finds, for irregular radii, radius 0 and 3^d > n")
    func geometricGridAgainstEveryPair() {
        // (vertex count, radius, dimension). The first four are n ≈ 2000; the rest are smaller, to
        // keep the check of every pair quick in a debug build, since 3^d > n makes the factory check
        // every pair too. 3^7 = 2187 exceeds every n here, so the d = 7 cases check every pair, while
        // 3^6 = 729 is below 800, so (800, 0.3, 6) is gridded. Radius 0 and tiny radii size the grid
        // by n; 0.4999 is the largest radius gridded.
        let cases: [(Int, Double, Int)] = [
            (2000, 0.0137, 2), (2003, 0.1618, 2), (1999, 0.0419, 3), (2000, 0.0, 2), (900, 0.55, 7),
            (600, 0.0291, 2), (601, 0.0733, 2), (600, 0.3141, 2), (600, 0.4999, 2), (600, 0.0007, 1), (600, 0.000_313, 1),
            (600, 0.2071, 3), (800, 0.3, 6), (600, 0.0, 1), (600, 0.0, 3), (600, 0.9, 7), (600, 0.0, 7), (600, 1e-300, 2),
        ]
        for (n, radius, dimension) in cases {
            let label = "n \(n), radius \(radius), dimension \(dimension)"
            var generator = Xoshiro256StarStar(seed: UInt64(n) &* 31 &+ UInt64(dimension))
            let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(
                vertexCount: n, radius: radius, dimension: dimension, using: &generator)
            #expect(positions.count == n * dimension, "\(label)")
            // Every pair, with the test the factory documents: Σᵢ (aᵢ − bᵢ)², in coordinate order, ≤ r².
            // Pairs are compared as codes u·n + v.
            var expected: [Int] = []
            positions.withUnsafeBufferPointer { position in
                for u in 0 ..< n {
                    for v in u + 1 ..< n {
                        var sum = 0.0
                        for i in 0 ..< dimension {
                            let delta = position[u * dimension + i] - position[v * dimension + i]
                            sum += delta * delta
                        }
                        if sum <= radius * radius { expected.append(u * n + v) }
                    }
                }
            }
            #expect(graph.vertexCount == n, "\(label)")
            #expect(graph.edges.map { $0.u * n + $0.v } == expected, "\(label): \(graph.edgeCount) edges against \(expected.count)")
            if radius == 0 || radius == 1e-300 { #expect(expected.isEmpty, "\(label)") }
            // The directed form: the same draws and positions, both arcs of every pair, row-major.
            var directedGenerator = Xoshiro256StarStar(seed: UInt64(n) &* 31 &+ UInt64(dimension))
            let (directed, directedPositions) = CompressedSparseRow.randomGeometric(
                vertexCount: n, radius: radius, dimension: dimension, using: &directedGenerator)
            let arcs = (expected + expected.map { $0 % n * n + $0 / n }).sorted()
            #expect(directedPositions == positions && directedGenerator == generator, "\(label)")
            #expect(directed.edges.map { $0.source * n + $0.target } == arcs, "\(label)")
        }
    }

    @Test("Random geometric: radius 0 at n = 5·10⁴ uses the grid (it was every pair: 1.25·10⁹ checks), and a radius past 1/2 checks every pair")
    func geometricRadiusZeroAndLarge() {
        var generator = Xoshiro256StarStar(seed: 9)
        let (graph, positions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 50_000, radius: 0, using: &generator)
        // 10⁵ 53-bit coordinates: a coincident pair has probability about 10⁻⁶.
        #expect(graph.vertexCount == 50_000 && graph.edgeCount == 0 && positions.count == 100_000)
        var other = Xoshiro256StarStar(seed: 10)
        let (large, largePositions) = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 300, radius: 0.75, using: &other)
        var expected = 0
        for u in 0 ..< 300 {
            for v in u + 1 ..< 300 {
                let dx = largePositions[2 * u] - largePositions[2 * v], dy = largePositions[2 * u + 1] - largePositions[2 * v + 1]
                if dx * dx + dy * dy <= 0.75 * 0.75 { expected += 1 }
            }
        }
        #expect(large.edgeCount == expected)
    }

    @Test("Random DAG built in bulk, then a random script of insertions and removals: every base matches a model with its own cycle check")
    func randomDAGThenMutation() {
        for seed in 0 ..< UInt64(12) {
            var generator = Xoshiro256StarStar(seed: seed)
            let n = 30
            let built = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: n, edgeProbability: 0.12, using: &generator)
            var adjacencyList = built
            var g1 = Xoshiro256StarStar(seed: seed)
            var stable = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: n, edgeProbability: 0.12, using: &g1)
            var g2 = Xoshiro256StarStar(seed: seed)
            var pseudograph = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: n, edgeProbability: 0.12, using: &g2)
            // The model: vertices and edges as sets.
            var vertices = Set(0 ..< n)
            var edges = Set(built.edges.map { [$0.source, $0.target] })
            func reaches(_ from: Int, _ to: Int) -> Bool {
                var seen: Set<Int> = [from], stack = [from]
                while let v = stack.popLast() {
                    if v == to { return true }
                    for edge in edges where edge[0] == v && seen.insert(edge[1]).inserted { stack.append(edge[1]) }
                }
                return false
            }
            // The same edges inserted one at a time into an empty DAG give the same graph as edges.
            var incremental = DirectedAcyclicGraph<AdjacencyList<Int>>()
            for v in 0 ..< n { incremental.insert(v) }
            for edge in built.edges { #expect(incremental.insert(edge: edge) != nil, "seed \(seed)") }
            #expect(Set(incremental.edges.map { [$0.source, $0.target] }) == edges, "seed \(seed)")

            var script = Xoshiro256StarStar(seed: seed &+ 1000)
            for step in 0 ..< 400 {
                let action = Int(script.next() % 10)
                let u = Int(script.next() % UInt64(n + 5)), v = Int(script.next() % UInt64(n + 5))
                let label = "seed \(seed), step \(step)"
                switch action {
                case 0 ..< 5:
                    // Insert u → v: rejected exactly when it closes a cycle (a self-loop included).
                    let closes = u == v || (vertices.contains(u) && vertices.contains(v) && reaches(v, u))
                    let a = adjacencyList.insert(edge: DirectedEdge(from: u, to: v))
                    let b = stable.insert(edge: DirectedEdge(from: u, to: v))
                    let c = pseudograph.insert(edge: DirectedEdge(from: u, to: v))
                    #expect((a == nil) == closes && (b == nil) == closes, "\(label): insert \(u) → \(v)")
                    // The pseudograph keeps parallel copies; the model counts edges as a set.
                    #expect((c == nil) == closes, "\(label): insert \(u) → \(v) on DirectedPseudograph")
                    if !closes {
                        vertices.insert(u)
                        vertices.insert(v)
                        edges.insert([u, v])
                    }
                case 5 ..< 8:
                    let removed = adjacencyList.remove(edge: DirectedEdge(from: u, to: v))
                    // Remove every parallel copy, so the other bases keep the model's edge set.
                    while stable.remove(edge: DirectedEdge(from: u, to: v)) != nil {}
                    while pseudograph.remove(edge: DirectedEdge(from: u, to: v)) != nil {}
                    #expect((removed != nil) == edges.contains([u, v]), "\(label): remove \(u) → \(v)")
                    edges.remove([u, v])
                case 8:
                    #expect((adjacencyList.remove(u) != nil) == vertices.contains(u), "\(label): remove vertex \(u)")
                    _ = stable.remove(u)
                    _ = pseudograph.remove(u)
                    vertices.remove(u)
                    edges = edges.filter { $0[0] != u && $0[1] != u }
                default:
                    #expect(adjacencyList.insert(u).inserted == !vertices.contains(u), "\(label): insert vertex \(u)")
                    stable.insert(u)
                    pseudograph.insert(u)
                    vertices.insert(u)
                }
                func check(_ dag: some DirectedGraph<Int>, _ order: [Int], _ type: String) {
                    #expect(Set(dag.vertices) == vertices && dag.vertexCount == vertices.count, "\(label) \(type)")
                    #expect(Set(dag.edges.map { [$0.source, $0.target] }) == edges, "\(label) \(type)")
                    // The kept order is topological: every edge goes forward in it.
                    var place: [Int: Int] = [:]
                    for (i, v) in order.enumerated() { place[v] = i }
                    #expect(order.count == vertices.count && dag.edges.allSatisfy { place[$0.source]! < place[$0.target]! }, "\(label) \(type)")
                }
                check(adjacencyList, Array(adjacencyList.topologicalOrder), "AdjacencyList")
                check(stable, Array(stable.topologicalOrder), "StableDirectedGraph")
                check(pseudograph, Array(pseudograph.topologicalOrder), "DirectedPseudograph")
            }
        }
    }

    @Test("Random geometric: a pair exactly r apart is an edge, in the check of every pair, within a cell and between neighbouring cells")
    func geometricTies() {
        // A generator that returns the given words in turn: uniform01 is the top 53 bits × 2⁻⁵³, so
        // 2⁶² draws 0.25 and 2⁶³ draws 0.5, and the points sit exactly where the test puts them.
        struct Words: RandomNumberGenerator {
            let words: [UInt64]
            var index = 0
            mutating func next() -> UInt64 {
                defer { index = (index + 1) % words.count }
                return words[index]
            }
        }
        // Two coincident points at radius 0: 3^1 > 2, so every pair is checked.
        var g = Words(words: [1 << 62])
        let coincident = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 2, radius: 0, dimension: 1, using: &g)
        #expect(coincident.positions == [0.25, 0.25])
        #expect(Array(coincident.graph.edges).map { [$0.u, $0.v] } == [[0, 1]])
        // Four coincident points at radius 0: the grid of 4 cells, all four in one cell.
        g = Words(words: [1 << 62])
        let cell = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 4, radius: 0, dimension: 1, using: &g)
        #expect(Array(cell.graph.edges).map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]])
        // Points at 0.25 and 0.5, radius 0.25 (0.25² = 0.0625 exactly): cells of side 1/3, so 0.25 and
        // 0.5 fall in neighbouring cells, and every pair is within the radius.
        var h = Words(words: [1 << 62, 1 << 63])
        let neighbours = UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 4, radius: 0.25, dimension: 1, using: &h)
        #expect(neighbours.positions == [0.25, 0.5, 0.25, 0.5])
        #expect(Array(neighbours.graph.edges).map { [$0.u, $0.v] } == [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]])
    }

    @Test("Random bipartite and block model: a probability for which 1 − p rounds to 1 gives no edges and makes no draws")
    func probabilityRoundingToZero() {
        var generator = Xoshiro256StarStar(seed: 7)
        let bipartite = UndirectedAdjacencyList<Int>.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 1e-17, using: &generator)
        #expect(bipartite.vertexCount == 7 && bipartite.edgeCount == 0)
        #expect(generator == Xoshiro256StarStar(seed: 7))
        let directed = CompressedSparseRow.randomBipartite(leftCount: 3, rightCount: 4, edgeProbability: 1e-17, using: &generator)
        #expect(directed.vertexCount == 7 && directed.edgeCount == 0)
        #expect(generator == Xoshiro256StarStar(seed: 7))
        let blocks = UndirectedAdjacencyList<Int>.stochasticBlockModel(
            blockSizes: [3, 2], edgeProbabilities: [[1e-17, 1e-17], [1e-17, 1e-17]], using: &generator)
        #expect(blocks.vertexCount == 5 && blocks.edgeCount == 0)
        #expect(generator == Xoshiro256StarStar(seed: 7))
    }
}
