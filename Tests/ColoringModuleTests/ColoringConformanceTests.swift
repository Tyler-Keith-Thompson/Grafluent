// Conventions the catalog rows do not isolate: the default strategy, the strategy enum, equality on
// colour vectors (not graphs, not classes), generic code over `some Graph`, `CompressedSparseRow`
// through `AdjacencyList(csr).undirected`, an undirected graph read as directed and back (every
// edge a parallel pair), string and hash-colliding vertices, the check closures called once per
// vertex or edge even when the answer is false, any `Sequence` as an order (single-pass, lazy,
// shuffled), `Sendable`, the result's own copy of the graph, the descriptions, edge-colouring
// equality, isolated looped vertices, a directed graph coloured through `.undirected`, equality
// between colourings with the same class sizes, DSatur past 64 colours and with a neighbour colour
// above a vertex's degree met twice, and χ below DSatur's count on a graph whose greedy clique is a
// triangle. Expected values are worked out in each test's comments or are catalog rows. See
// README.md.

import AdjacencyListModule
import BipartiteGraphs
import ColoringModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Coloring results and conventions", .tags(.conformance))
struct ColoringConformanceTests {
    @Test("greedyColoring() is greedyColoring(strategy: .largestFirst): P5, where smallest last differs")
    func defaultStrategy() {
        // P5: largest first [1, 0, 1, 0, 1] (CO-028), smallest last [0, 1, 0, 1, 0] (CO-050).
        let path = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let byDefault = path.greedyColoring()
        #expect(byDefault == path.greedyColoring(strategy: .largestFirst))
        #expect((0 ..< 5).map { byDefault.color(of: $0) } == [1, 0, 1, 0, 1])
        #expect(byDefault != path.greedyColoring(strategy: .smallestLast))
    }

    @Test("ColoringStrategy has NetworkX's six strategies, in that order, then igraph's colored neighbours, distinct and hashable")
    func strategyCases() {
        let all = ColoringStrategy.allCases
        #expect(Array(all) == [.largestFirst, .smallestLast, .saturationLargestFirst, .independentSet, .connectedSequentialBreadthFirst, .connectedSequentialDepthFirst, .coloredNeighbors])
        #expect(Set(all).count == 7)
    }

    @Test("== compares colour vectors: the same classes under other numbers differ; the graphs are not compared")
    func equalityOnColourVectors() {
        // P5 by largest first [1, 0, 1, 0, 1] and by smallest last [0, 1, 0, 1, 0]: the same two classes,
        // numbered the other way round.
        let path = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let first = path.greedyColoring(strategy: .largestFirst)
        let last = path.greedyColoring(strategy: .smallestLast)
        #expect(first != last)
        #expect(Set(first.colorClasses.map { Set($0) }) == Set(last.colorClasses.map { Set($0) }))
        // K3 by largest first and by DSatur: both [0, 1, 2] (CO-026, CO-065).
        let triangle = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
        #expect(triangle.greedyColoring(strategy: .largestFirst) == triangle.greedyColoring(strategy: .saturationLargestFirst))
        // P3 and the graph with the one edge 0–1 and vertex 2: both minimum colourings are [0, 1, 0].
        let p3 = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let oneEdge = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(p3.minimumColoring() == oneEdge.minimumColoring())
        #expect((0 ..< 3).map { oneEdge.minimumColoring().color(of: $0) } == [0, 1, 0])
    }

    @Test("Generic code over some Graph sees the same results as concrete code")
    func genericCode() {
        func everything(_ graph: some Graph<Int>) -> [[Int]] {
            let greedy = ColoringStrategy.allCases.map { graph.greedyColoring(strategy: $0) }.map { coloring in (0 ..< graph.vertexCount).map { coloring.color(ofIndex: $0) } }
            let first = graph.lexicographicallyFirstMinimumColoring()
            let minimum = graph.minimumColoring()
            let edges = graph.edgeColoring()
            return greedy + [(0 ..< graph.vertexCount).map { first.color(ofIndex: $0) }, (0 ..< graph.vertexCount).map { minimum.color(ofIndex: $0) }, [graph.chromaticNumber()], graph.edges.indices.map { edges.color(ofEdgeAt: $0) }]
        }
        // Petersen (NetworkX's numbering): largest first and the lexicographically first minimum
        // colouring [0, 1, 0, 1, 2, 1, 0, 2, 2, 1] (CO-034, CO-180), colored neighbours python-igraph
        // 1.0's [0, 2, 0, 2, 1, 1, 1, 2, 0, 0], χ = 3 (CO-145), Misra–Gries CO-206.
        let pairs = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let petersen = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let colorings = ColoringStrategy.allCases.map { petersen.greedyColoring(strategy: $0) } + [petersen.lexicographicallyFirstMinimumColoring(), petersen.minimumColoring()]
        let edgeColoring = petersen.edgeColoring()
        let concrete = colorings.map { coloring in (0 ..< 10).map { coloring.color(of: $0) } } + [[petersen.chromaticNumber()], petersen.edges.indices.map { edgeColoring.color(ofEdgeAt: $0) }]
        #expect(everything(petersen) == concrete)
        #expect(concrete[0] == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
        #expect(concrete[6] == [0, 2, 0, 2, 1, 1, 1, 2, 0, 0])
        #expect(concrete[7] == [0, 1, 0, 1, 2, 1, 0, 2, 2, 1])
        #expect(Set(concrete[8]) == [0, 1, 2])
        #expect(concrete[9] == [3])
        #expect(concrete[10] == [2, 1, 0, 1, 0, 0, 2, 3, 1, 0, 1, 2, 3, 2, 3])
    }

    @Test("CompressedSparseRow through AdjacencyList(csr).undirected: K3,3 with its arcs row-major")
    func compressedSparseRow() throws {
        let csr = CompressedSparseRow(vertexCount: 6, edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = AdjacencyList(csr).undirected
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]])
        // The sides, χ = 2; the edge colourings of Kb(3,3) with the same positions (CO-208, CO-221).
        let minimum = graph.minimumColoring()
        #expect((0 ..< 6).map { minimum.color(of: $0) } == [0, 0, 0, 1, 1, 1])
        #expect(graph.chromaticNumber() == 2)
        #expect(graph.greedyColoring(strategy: .saturationLargestFirst).colorCount == 2)
        let misraGries = graph.edgeColoring()
        #expect(graph.edges.indices.map { misraGries.color(ofEdgeAt: $0) } == [0, 1, 2, 1, 2, 0, 2, 0, 1])
        let koenig = try #require(graph.bipartiteEdgeColoring())
        #expect(graph.edges.indices.map { koenig.color(ofEdgeAt: $0) } == [2, 0, 1, 1, 2, 0, 0, 1, 2])
    }

    @Test("graph.directed.undirected: every edge a parallel pair; vertex colourings as on the graph, König with 2Δ colours")
    func directedThenUndirected() throws {
        // C6 read as directed and back: each edge twice, so degree 4 counting parallel edges, 2 simple.
        let cycle = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: (0 ..< 6).map { UndirectedEdge($0, ($0 + 1) % 6) })
        let doubled = cycle.directed.undirected
        #expect(doubled.edgeCount == 12)
        // Parallel edges count once, so the strategies that read degrees and adjacency only, the
        // chromatic number and the minimum colouring are the cycle's.
        for strategy in [ColoringStrategy.largestFirst, .smallestLast, .saturationLargestFirst, .independentSet] {
            let here = doubled.greedyColoring(strategy: strategy)
            let there = cycle.greedyColoring(strategy: strategy)
            #expect((0 ..< 6).map { here.color(of: $0) } == (0 ..< 6).map { there.color(of: $0) }, "\(strategy)")
        }
        #expect(doubled.chromaticNumber() == 2)
        let minimum = doubled.minimumColoring()
        #expect((0 ..< 6).map { minimum.color(of: $0) } == [0, 1, 0, 1, 0, 1])
        // König's theorem with parallel edges: Δ = 4 colours, the two copies of each edge different.
        let koenig = try #require(doubled.bipartiteEdgeColoring())
        #expect(koenig.colorCount == 4)
        #expect(doubled.isEdgeColoring { koenig.color(ofEdgeAt: $0) })
        // One colour per pair of copies is not an edge colouring.
        #expect(!doubled.isEdgeColoring { _ in 0 })
    }

    @Test("String vertices: color(of:) by label, classes in `vertices` order (CO-039's graph, d, a, c, b)")
    func stringVertices() {
        let graph = UndirectedAdjacencyList(vertices: ["d", "a", "c", "b"], edges: [UndirectedEdge("d", "a"), UndirectedEdge("a", "c"), UndirectedEdge("c", "b"), UndirectedEdge("b", "d"), UndirectedEdge("d", "c")])
        // Largest first: d and c have degree 3, so d (index 0), c, then a, b: d 0, c 1, a 2, b 2.
        let coloring = graph.greedyColoring()
        #expect(coloring.color(of: "d") == 0 && coloring.color(of: "a") == 2 && coloring.color(of: "c") == 1 && coloring.color(of: "b") == 2)
        #expect(coloring.colorClasses.map { Array($0) } == [["d"], ["c"], ["a", "b"]])
        // Both minimum colourings go by index, not by label: [0, 1, 2, 1] (CO-184, and CO-271: d and c
        // are adjacent to every other vertex, so a and b share the third colour in every 3-colouring).
        for minimum in [graph.minimumColoring(), graph.lexicographicallyFirstMinimumColoring()] {
            #expect(["d", "a", "c", "b"].map { minimum.color(of: $0) } == [0, 1, 2, 1])
            #expect(minimum.colorClasses.map { Array($0) } == [["d"], ["a", "b"], ["c"]])
        }
    }

    @Test("Vertices whose hashes all collide (Collider): C5 coloured as on Int vertices")
    func collidingHashes() {
        let vertices = (0 ..< 5).map { Collider($0) }
        let graph = UndirectedAdjacencyList(vertices: vertices, edges: (0 ..< 5).map { UndirectedEdge(vertices[$0], vertices[($0 + 1) % 5]) })
        // C5: largest first [0, 1, 0, 1, 2] (CO-029), the lexicographically first minimum colouring the
        // same (CO-176), χ = 3.
        let greedy = graph.greedyColoring(), first = graph.lexicographicallyFirstMinimumColoring()
        #expect(vertices.map { greedy.color(of: $0) } == [0, 1, 0, 1, 2])
        #expect(vertices.map { first.color(of: $0) } == [0, 1, 0, 1, 2])
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == 3 && graph.isVertexColoring { minimum.color(of: $0) })
        #expect(graph.chromaticNumber() == 3)
        let smallestLast = graph.greedyColoring(strategy: .smallestLast)
        #expect(graph.isVertexColoring { smallestLast.color(of: $0) })
    }

    @Test("isVertexColoring and isEdgeColoring call the closure once per vertex or edge, also when the answer is false")
    func closureCalls() {
        let triangle = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)])
        var vertexCalls: [Int] = []
        let proper = triangle.isVertexColoring { vertexCalls.append($0); return 0 }
        #expect(!proper)
        #expect(vertexCalls.sorted() == [0, 1, 2])
        var edgeCalls: [Int] = []
        let properEdges = triangle.isEdgeColoring { edgeCalls.append($0); return 0 }
        #expect(!properEdges)
        #expect(edgeCalls.sorted() == [0, 1, 2])
    }

    @Test("greedyColoring(order:) takes any Sequence: single-pass with an underestimated count, lazy, reversed, a stride")
    func anySequence() {
        // P5 reversed: [0, 1, 0, 1, 0] (CO-121).
        let path = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        let expected = [0, 1, 0, 1, 0]
        let single = path.greedyColoring(order: MinimalSequence(elements: [4, 3, 2, 1, 0], underestimatedCount: .value(0)))
        #expect((0 ..< 5).map { single.color(of: $0) } == expected)
        #expect((0 ..< 5).map { path.greedyColoring(order: (0 ..< 5).reversed()).color(of: $0) } == expected)
        #expect((0 ..< 5).map { path.greedyColoring(order: (0 ..< 5).lazy.map { 4 - $0 }).color(of: $0) } == expected)
        #expect((0 ..< 5).map { path.greedyColoring(order: stride(from: 4, through: 0, by: -1)).color(of: $0) } == expected)
    }

    @Test("A random order (random_sequential): first fit in that order, proper, at most Δ + 1", .tags(.randomized))
    func randomSequential() {
        var rng = SeededRandomNumberGenerator(seed: 7)
        let n = 40
        var pairs: [(Int, Int)] = []
        for u in 0 ..< n { for v in u + 1 ..< n where Int.random(in: 0 ..< 5, using: &rng) == 0 { pairs.append((u, v)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs {
            adjacent[a].append(b)
            adjacent[b].append(a)
        }
        for _ in 0 ..< 20 {
            let order = Array(0 ..< n).shuffled(using: &rng)
            let coloring = graph.greedyColoring(order: order)
            var expected = [Int](repeating: -1, count: n)
            for v in order {
                var c = 0
                while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
                expected[v] = c
            }
            #expect((0 ..< n).map { coloring.color(of: $0) } == expected)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
            #expect(coloring.colorCount <= adjacent.map(\.count).max()! + 1)
        }
    }

    @Test("Coloring and EdgeColoring are Sendable for Sendable graphs")
    func sendable() async throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: (0 ..< 4).map { UndirectedEdge($0, ($0 + 1) % 4) })
        let coloring = graph.minimumColoring()
        let edges = try #require(graph.bipartiteEdgeColoring())
        let colors = await Task { (0 ..< 4).map { coloring.color(of: $0) } }.value
        let edgeColors = await Task { (0 ..< 4).map { edges.color(ofEdgeAt: $0) } }.value
        #expect(colors == [0, 1, 0, 1])
        #expect(Set(edgeColors) == [0, 1])
    }

    @Test("A colouring keeps its own copy of the graph: mutating the original afterwards changes nothing in it")
    func ownCopy() {
        var graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let coloring = graph.minimumColoring()
        #expect((0 ..< 4).map { coloring.color(of: $0) } == [0, 1, 0, 1])
        graph.insert(edge: UndirectedEdge(0, 2))
        graph.insert(4)
        #expect((0 ..< 4).map { coloring.color(of: $0) } == [0, 1, 0, 1])
        #expect(coloring.colorCount == 2)
        #expect(coloring.colorClasses.map { Array($0) } == [[0, 2], [1, 3]])
        // The new edge joins two vertices of colour 0.
        #expect(!graph.isVertexColoring { $0 < 4 ? coloring.color(of: $0) : 0 })
    }

    @Test("descriptions are not empty")
    func descriptions() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(!graph.greedyColoring().description.isEmpty)
        #expect(!graph.edgeColoring().description.isEmpty)
    }

    @Test("EdgeColoring == compares colours by position: Misra–Gries and König agree on P5 and C6")
    func edgeColoringEquality() {
        // P5: both [0, 1, 0, 1] (CO-198; König colours the path alternately). C6: both [0, 1, 0, 1, 0, 1]
        // (CO-203, CO-220).
        let path = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })
        #expect(path.edgeColoring() == path.bipartiteEdgeColoring())
        let cycle = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: (0 ..< 6).map { UndirectedEdge($0, ($0 + 1) % 6) })
        #expect(cycle.edgeColoring() == cycle.bipartiteEdgeColoring())
        // C(4) in another edge order is coloured differently (CO-211: [0, 0, 1, 1]).
        let listed = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(1, 2), UndirectedEdge(3, 0)])
        let coloring = listed.edgeColoring()
        #expect((0 ..< 4).map { coloring.color(ofEdgeAt: $0) } == [0, 0, 1, 1])
    }

    @Test("Isolated vertices with self-loops: one colour, χ = 1, no bipartite edge colouring")
    func isolatedLoops() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 5).map { UndirectedEdge($0, $0) })
        for strategy in ColoringStrategy.allCases {
            let coloring = graph.greedyColoring(strategy: strategy)
            #expect((0 ..< 5).map { coloring.color(of: $0) } == [0, 0, 0, 0, 0], "\(strategy)")
            #expect(coloring.colorClasses.map { Array($0) } == [[0, 1, 2, 3, 4]])
        }
        #expect(graph.chromaticNumber() == 1)
        #expect(graph.minimumColoring().colorCount == 1)
        #expect(graph.isVertexColoring { _ in 0 })
        #expect(graph.bipartiteEdgeColoring() == nil)
        // A self-loop alone at its vertex: one colour each is an edge colouring.
        #expect(graph.isEdgeColoring { _ in 0 })
    }

    @Test("A directed graph is coloured through .undirected: the DAG 0→1, 0→2, 1→2, 2→3 has χ = 3")
    func directedThroughUndirected() {
        let dag = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
        let graph = dag.undirected
        #expect(graph.chromaticNumber() == 3)
        // Lexicographically first: 0 → 0, 1 → 1, 2 → 2, 3 (adjacent only to 2) → 0.
        let first = graph.lexicographicallyFirstMinimumColoring()
        #expect((0 ..< 4).map { first.color(of: $0) } == [0, 1, 2, 0])
        // minimumColoring(): the triangle 0, 1, 2 takes 0, 1, 2 by first appearance; 3 is 0 or 1.
        let minimum = graph.minimumColoring()
        #expect((0 ..< 3).map { minimum.color(of: $0) } == [0, 1, 2] && [0, 1].contains(minimum.color(of: 3)))
        // Misra–Gries within Δ + 1 = 4.
        let edges = graph.edgeColoring()
        #expect(edges.colorCount <= 4 && graph.isEdgeColoring { edges.color(ofEdgeAt: $0) })
    }

    @Test("== compares colour vectors, not class sizes: P4 as [0, 1, 0, 1] and [1, 0, 1, 0] differ")
    func equalityNotClassSizes() {
        // First fit in order 0, 1, 2, 3 gives [0, 1, 0, 1]; in order 1, 0, 3, 2 vertex 1 takes 0, then 0
        // takes 1, 3 (its neighbour 2 uncoloured) takes 0 and 2 (beside 1 and 3) takes 1: [1, 0, 1, 0].
        // Both have two classes of two vertices.
        let path = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: (0 ..< 3).map { UndirectedEdge($0, $0 + 1) })
        let ascending = path.greedyColoring(order: [0, 1, 2, 3])
        let swapped = path.greedyColoring(order: [1, 0, 3, 2])
        #expect((0 ..< 4).map { ascending.color(of: $0) } == [0, 1, 0, 1])
        #expect((0 ..< 4).map { swapped.color(of: $0) } == [1, 0, 1, 0])
        #expect(ascending.colorClasses.map(\.count) == swapped.colorClasses.map(\.count))
        #expect(ascending != swapped)
        #expect(ascending == path.greedyColoring(order: [0, 1, 2, 3]))
    }

    @Test("EdgeColoring == compares colour vectors, not class sizes: [0, 0, 1] and [0, 1, 0] differ")
    func edgeColoringEqualityNotClassSizes() {
        // Edges 0–1, 2–3, 1–2: the first two take 0, and 1–2 takes 1, the least colour free at 1.
        let first = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(1, 2)])
        // Edges 0–1, 1–2, 3–4: 0–1 takes 0, 1–2 takes 1 (0 is used at 1), and 3–4 takes 0.
        let second = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(3, 4)])
        let a = first.edgeColoring(), b = second.edgeColoring()
        #expect((0 ..< 3).map { a.color(ofEdgeAt: $0) } == [0, 0, 1])
        #expect((0 ..< 3).map { b.color(ofEdgeAt: $0) } == [0, 1, 0])
        #expect(a.colorClasses.map(\.count) == b.colorClasses.map(\.count))
        #expect(a != b)
    }

    @Test("DSatur on K70: vertex i takes colour i, past the first 64 colours")
    func saturationBeyondSixtyFourColours() {
        // Every vertex has degree 69, so ties go to the lesser index each time, and vertex i sees colours
        // 0..<i.
        let n = 70
        var pairs: [UndirectedEdge<Int>] = []
        for a in 0 ..< n { for b in a + 1 ..< n { pairs.append(UndirectedEdge(a, b)) } }
        let complete = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs)
        let coloring = complete.greedyColoring(strategy: .saturationLargestFirst)
        #expect((0 ..< n).map { coloring.color(of: $0) } == Array(0 ..< n))
        #expect(coloring.colorCount == n)
        #expect(complete.isVertexColoring { coloring.color(of: $0) })
    }

    @Test("DSatur counts a neighbour colour above a vertex's degree once: vertex 13 (degree 4) meets colour 5 twice")
    func saturationRepeatedHighColour() {
        let pairs = [(0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (1, 5), (2, 10), (3, 7), (3, 9), (3, 11), (4, 5), (4, 6), (4, 7), (4, 8), (4, 10), (4, 11), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 7), (6, 8), (6, 11), (7, 8), (7, 10), (7, 11), (8, 10), (8, 11), (9, 10), (10, 11), (5, 12), (4, 13), (0, 13), (6, 13), (3, 13), (8, 14), (6, 14), (8, 15)]
        let n = 16
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        // Vertices 0 and 4, not adjacent, both take colour 5 before 13 is coloured: 13 has saturation 1
        // from them, not 2.
        #expect(colors == [5, 0, 0, 0, 5, 1, 1, 2, 0, 2, 3, 4, 0, 2, 2, 1])
        // DSatur written out: the uncoloured vertex with the most distinct neighbour colours, then the
        // greatest degree, then the lesser index, takes the least colour free.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs {
            adjacent[a].append(b)
            adjacent[b].append(a)
        }
        var expected = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
            let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(colors == expected)
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
    }

    @Test("χ = 3 where DSatur needs 4 and the greedy clique is the triangle 0–4–9")
    func chromaticNumberAboveGreedyCliqueSeeds() {
        // The greedy clique search seeds from every vertex by degree descending; the clique it keeps must
        // be a clique. Here the only triangles are 0–4–9 and 6–7–8, and a 3-colouring exists.
        let pairs = [(0, 4), (0, 7), (0, 9), (1, 4), (2, 5), (2, 6), (2, 8), (3, 9), (4, 5), (4, 9), (5, 6), (6, 7), (6, 8), (7, 8), (9, 10)]
        let n = 11
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.greedyColoring(strategy: .saturationLargestFirst).colorCount == 4)
        // The least k with a proper k-colouring, by exhaustive search.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs {
            adjacent[a].append(b)
            adjacent[b].append(a)
        }
        func colorable(_ k: Int) -> Bool {
            var color = [Int](repeating: -1, count: n)
            func place(_ v: Int) -> Bool {
                if v == n { return true }
                for c in 0 ..< k where !adjacent[v].contains(where: { color[$0] == c }) {
                    color[v] = c
                    if place(v + 1) { return true }
                }
                color[v] = -1
                return false
            }
            return place(0)
        }
        let chi = (1 ... n).first(where: colorable)!
        #expect(chi == 3)
        #expect(graph.chromaticNumber() == 3)
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == 3)
        for (a, b) in pairs { #expect(minimum.color(of: a) != minimum.color(of: b)) }
    }

    @Test("A triangle, then a component with χ = 3 where DSatur needs 4: χ = 3, and both minimum colourings use 3 (added for a planted bug)")
    func componentOneAboveTheBestSoFar() {
        // The component of chromaticNumberAboveGreedyCliqueSeeds, shifted by 3 behind the triangle
        // 0–1–2: its DSatur count, 4, is one above the triangle's 3, so its own χ must be decided.
        let pairs = [(0, 4), (0, 7), (0, 9), (1, 4), (2, 5), (2, 6), (2, 8), (3, 9), (4, 5), (4, 9), (5, 6), (6, 7), (6, 8), (7, 8), (9, 10)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 14, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2)] + pairs.map { UndirectedEdge($0.0 + 3, $0.1 + 3) })
        #expect(graph.chromaticNumber() == 3)
        for coloring in [graph.minimumColoring(), graph.lexicographicallyFirstMinimumColoring()] {
            #expect(coloring.colorCount == 3)
            #expect(graph.isVertexColoring { coloring.color(of: $0) })
        }
    }
}
