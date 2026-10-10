// Large inputs, each inside a Task (whose stack is much smaller than the main thread's, so a
// recursive search over a long path would overflow) with a one-minute limit, meant to finish within
// seconds in a debug build; the benchmarks take timings. Expected values are known by construction:
// the colours of every strategy on a long path; the crown graph's n/2-colour order; disjoint copies
// of catalog rows (each component's colouring is the catalog's, since every entry point works
// component by component); a grid's checkerboard; a d-regular bipartite graph's d colours (König),
// doubled with parallel edges; the Mycielski graph M₆, χ = 6 by Mycielski's theorem; and, on
// random graphs from the package's seeded generator, the definitions and bounds checked in the
// test. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Coloring on large inputs")
struct ColoringStressTests {
    @Test("Every strategy on a random graph of 10⁵ vertices and about 3 · 10⁵ edges: proper, first fit, at most Δ + 1", .timeLimit(.minutes(1)))
    func greedyOnRandomGraph() async {
        await Task {
            let n = 100_000
            var rng = SeededRandomNumberGenerator(seed: 11)
            var pairs: [(Int, Int)] = []
            for _ in 0 ..< 300_000 {
                let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
                if u != v { pairs.append((u, v)) }
            }
            // UndirectedAdjacencyList keeps one copy of a repeated pair.
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var adjacent = [[Int]](repeating: [], count: n)
            for edge in graph.edges {
                adjacent[edge.u].append(edge.v)
                adjacent[edge.v].append(edge.u)
            }
            let maxDegree = adjacent.map(\.count).max()!
            for strategy in ColoringStrategy.allCases {
                let coloring = graph.greedyColoring(strategy: strategy)
                let colors = (0 ..< n).map { coloring.color(ofIndex: $0) }
                let proper = graph.edges.allSatisfy { colors[$0.u] != colors[$0.v] }
                #expect(proper, "\(strategy)")
                #expect(coloring.colorCount <= maxDegree + 1, "\(strategy)")
                #expect(coloring.colorClasses.map(\.count).reduce(0, +) == n, "\(strategy)")
                // First fit: a vertex of colour c sees every colour below c (a stamp per vertex).
                var stamp = [Int](repeating: -1, count: maxDegree + 2)
                var firstFit = true
                for v in 0 ..< n {
                    for w in adjacent[v] { stamp[colors[w]] = v }
                    if (0 ..< colors[v]).contains(where: { stamp[$0] != v }) { firstFit = false }
                }
                #expect(firstFit, "\(strategy)")
            }
            // A random order, given as one.
            let order = Array(0 ..< n).shuffled(using: &rng)
            let random = graph.greedyColoring(order: order)
            let randomIsProper = graph.isColoring { random.color(of: $0) }
            #expect(randomIsProper)
            #expect(random.colorCount <= maxDegree + 1)
        }.value
    }

    @Test("The path P₁₀₀₀₀₁: largest first and DSatur colour vertex i with (i + 1) mod 2, the other strategies with i mod 2; χ = 2", .timeLimit(.minutes(1)))
    func longPath() async {
        await Task {
            // Largest first and DSatur start at vertex 1 (degree 2, the least index), then go along the
            // path, and the end 0 last. Smallest last removes 0, 1, 2, … (each the least-index vertex of
            // degree ≤ 1) and colours from the far end, n even; the searches go from 0; the independent
            // set takes 0, 2, 4, … as class 0.
            let n = 100_000
            let path = UndirectedAdjacencyList(vertices: 0 ... n, edges: (0 ..< n).map { UndirectedEdge($0, $0 + 1) })
            let odd = (0 ... n).map { ($0 + 1) % 2 }
            let even = (0 ... n).map { $0 % 2 }
            for strategy in ColoringStrategy.allCases {
                let coloring = path.greedyColoring(strategy: strategy)
                let expected = strategy == .largestFirst || strategy == .saturationLargestFirst ? odd : even
                let colors = (0 ... n).map { coloring.color(ofIndex: $0) }
                #expect(colors == expected, "\(strategy)")
            }
            #expect(path.chromaticNumber() == 2)
            let minimum = path.minimumColoring()
            let minimumColors = (0 ... n).map { minimum.color(ofIndex: $0) }
            #expect(minimumColors == even)
            // Misra–Gries and König alternate along it.
            let misraGries = path.edgeColoring()
            let edgeColors = path.edges.indices.map { misraGries.color(ofEdgeAt: $0) }
            let alternating = (0 ..< n).map { $0 % 2 }
            #expect(edgeColors == alternating)
            #expect(path.bipartiteEdgeColoring()?.colorCount == 2)
        }.value
    }

    @Test("crown(300): interleaved order 300 colours, sides first 2; χ = 2, minimumColoring() the sides", .timeLimit(.minutes(1)))
    func crownGraph() async throws {
        try await Task {
            // Left i, right k + i; edge i–(k + j) for i ≠ j (CO-122, CO-123 at scale).
            let k = 300
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< k { for j in 0 ..< k where i != j { edges.append(UndirectedEdge(i, k + j)) } }
            let crown = try #require(BipartiteGraph(left: 0 ..< k, right: k ..< 2 * k, edges: edges))
            let interleaved = crown.greedyColoring(order: (0 ..< k).flatMap { [$0, k + $0] })
            #expect(interleaved.colorCount == k)
            let interleavedColors = (0 ..< 2 * k).map { interleaved.color(of: $0) }
            let pairsColoured = (0 ..< 2 * k).map { $0 % k }
            #expect(interleavedColors == pairsColoured)
            let sidesFirst = crown.greedyColoring(order: 0 ..< 2 * k)
            #expect(sidesFirst.colorCount == 2)
            #expect(crown.chromaticNumber() == 2)
            let minimum = crown.minimumColoring()
            let minimumColors = (0 ..< 2 * k).map { minimum.color(of: $0) }
            let bySides = (0 ..< 2 * k).map { $0 < k ? 0 : 1 }
            #expect(minimumColors == bySides)
            #expect(crown.greedyColoring(strategy: .saturationLargestFirst).colorCount == 2)
            #expect(crown.bipartiteEdgeColoring()?.colorCount == k - 1)
        }.value
    }

    @Test("1,000 disjoint Grötzsch graphs (11,000 vertices): χ = 4; minimumColoring() and DSatur give each copy CO-185's and CO-082's colours", .timeLimit(.minutes(1)))
    func grotzschCopies() async {
        await Task {
            // NetworkX's mycielski_graph(4), copy c shifted by 11c.
            let grotzsch = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
            let copies = 1_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 11 * copies, edges: (0 ..< copies).flatMap { c in grotzsch.map { UndirectedEdge(11 * c + $0.0, 11 * c + $0.1) } })
            #expect(graph.chromaticNumber() == 4)
            let minimum = graph.minimumColoring()
            let lexicographic = [0, 1, 0, 1, 2, 0, 1, 0, 1, 2, 3]
            let minimumColors = (0 ..< 11 * copies).map { minimum.color(ofIndex: $0) }
            #expect(minimumColors == Array(repeatElement(lexicographic, count: copies).joined()))
            // DSatur finishes a copy before the next: every other vertex then has saturation 0, and the
            // next copy's greatest-degree vertex with the least index starts it.
            let dsatur = graph.greedyColoring(strategy: .saturationLargestFirst)
            let single = [1, 0, 1, 2, 0, 1, 2, 1, 2, 3, 0]
            let dsaturColors = (0 ..< 11 * copies).map { dsatur.color(ofIndex: $0) }
            #expect(dsaturColors == Array(repeatElement(single, count: copies).joined()))
        }.value
    }

    @Test("The Mycielski graph M₆ (47 vertices, triangle-free): χ = 6; minimumColoring() a proper 6-colouring", .timeLimit(.minutes(1)))
    func mycielskiSix() async {
        await Task {
            // Mycielski's construction from K2: vertices v, then u (a copy of each), then w; edges of the
            // graph, v_i–u_j and u_i–v_j for each edge ij, and u_i–w. χ rises by one each time: M₂ = K2,
            // M₃ = C5, M₄ Grötzsch, M₅, M₆.
            var n = 2
            var pairs = [(0, 1)]
            for _ in 3 ... 6 {
                var next = pairs
                for (i, j) in pairs { next += [(i, n + j), (n + i, j)] }
                for i in 0 ..< n { next.append((n + i, 2 * n)) }
                pairs = next
                n = 2 * n + 1
            }
            #expect(n == 47 && pairs.count == 236)
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(graph.chromaticNumber() == 6)
            let minimum = graph.minimumColoring()
            #expect(minimum.colorCount == 6)
            let proper = pairs.allSatisfy { minimum.color(of: $0.0) != minimum.color(of: $0.1) }
            #expect(proper)
            #expect(graph.greedyColoring(strategy: .saturationLargestFirst).colorCount >= 6)
        }.value
    }

    @Test("grid(300, 300): the checkerboard; König with 4 colours; DSatur exact", .timeLimit(.minutes(1)))
    func grid() async throws {
        try await Task {
            let r = 300, c = 300
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< r {
                for j in 0 ..< c {
                    if j + 1 < c { edges.append(UndirectedEdge(i * c + j, i * c + j + 1)) }
                    if i + 1 < r { edges.append(UndirectedEdge(i * c + j, (i + 1) * c + j)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< r * c, edges: edges)
            let checkerboard = (0 ..< r * c).map { ($0 / c + $0 % c) % 2 }
            #expect(graph.chromaticNumber() == 2)
            let minimum = graph.minimumColoring()
            let minimumColors = (0 ..< r * c).map { minimum.color(ofIndex: $0) }
            #expect(minimumColors == checkerboard)
            #expect(graph.greedyColoring(strategy: .saturationLargestFirst).colorCount == 2)
            let koenig = try #require(graph.bipartiteEdgeColoring())
            #expect(koenig.colorCount == 4)
            let proper = graph.isEdgeColoring { koenig.color(ofEdgeAt: $0) }
            #expect(proper)
        }.value
    }

    @Test("Misra–Gries on a random graph of 10⁴ vertices and about 4 · 10⁴ edges: proper, Δ ≤ colours ≤ Δ + 1", .timeLimit(.minutes(1)))
    func misraGriesRandom() async {
        await Task {
            let n = 10_000
            var rng = SeededRandomNumberGenerator(seed: 5)
            var pairs: [(Int, Int)] = []
            for _ in 0 ..< 40_000 {
                let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
                if u != v { pairs.append((u, v)) }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let coloring = graph.edgeColoring()
            let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }
            // At each vertex the colours of its edges differ.
            var at = [[Int]](repeating: [], count: n)
            for (k, edge) in graph.edges.enumerated() {
                at[edge.u].append(colors[k])
                at[edge.v].append(colors[k])
            }
            let proper = at.allSatisfy { Set($0).count == $0.count }
            #expect(proper)
            let maxDegree = at.map(\.count).max()!
            #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)
            #expect(coloring.colorClasses.map(\.count).reduce(0, +) == graph.edgeCount)
        }.value
    }

    @Test("König on a 10-regular bipartite graph of 2,000 vertices: 10 colours; with every edge doubled, 20", .timeLimit(.minutes(1)))
    func koenigRegular() async throws {
        try await Task {
            // Left i, right 1000 + (i + s) mod 1000 for 10 distinct shifts s: ten perfect matchings.
            let half = 1_000
            let shifts = [0, 1, 3, 7, 12, 20, 33, 54, 88, 143]
            let edges = (0 ..< half).flatMap { i in shifts.map { UndirectedEdge(i, half + (i + $0) % half) } }
            let graph = try #require(BipartiteGraph(left: 0 ..< half, right: half ..< 2 * half, edges: edges))
            #expect(graph.edgeCount == 10_000)
            let coloring = try #require(graph.bipartiteEdgeColoring())
            #expect(coloring.colorCount == 10)
            let proper = graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) }
            #expect(proper)
            // Each colour class is a perfect matching.
            let perfect = coloring.colorClasses.allSatisfy { $0.count == half }
            #expect(perfect)
            let doubled = ReferencePseudograph(vertices: 0 ..< 2 * half, edges: edges + edges)
            let twice = try #require(doubled.bipartiteEdgeColoring())
            #expect(twice.colorCount == 20)
            let doubledProper = doubled.isEdgeColoring { twice.color(ofEdgeAt: $0) }
            #expect(doubledProper)
        }.value
    }

    @Test("10⁵ isolated vertices, every tenth with a self-loop: one colour everywhere, χ = 1", .timeLimit(.minutes(1)))
    func isolatedVertices() async {
        await Task {
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: stride(from: 0, to: n, by: 10).map { UndirectedEdge($0, $0) })
            for strategy in ColoringStrategy.allCases {
                let coloring = graph.greedyColoring(strategy: strategy)
                #expect(coloring.colorCount == 1, "\(strategy)")
                #expect(coloring.colorClasses.first?.count == n, "\(strategy)")
            }
            #expect(graph.chromaticNumber() == 1)
            #expect(graph.minimumColoring().colorCount == 1)
            #expect(graph.bipartiteEdgeColoring() == nil)
        }.value
    }
}
