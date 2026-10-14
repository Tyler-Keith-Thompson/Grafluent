// Spectral clustering (Ng–Jordan–Weiss): planted blocks recovered exactly, components, the cluster
// count at its bounds, determinism under a seeded generator, canonical order, weights, lookups and
// a graph without vertex indices; the preconditions as exit tests; planted cliques as a property.

import AdjacencyListModule
import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Spectral clustering")
struct SpectralClusteringTests {
    @Test("Two K5s joined by one edge: the two cliques")
    func barbell() throws {
        var edges: [UndirectedEdge<Int>] = []
        for base in [0, 5] { for u in 0 ..< 5 { for v in u + 1 ..< 5 { edges.append(UndirectedEdge(base + u, base + v)) } } }
        edges.append(UndirectedEdge(4, 5))
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: edges)
        var generator = SeededRandomNumberGenerator(seed: 1)
        let clusters = try graph.spectralClustering(clusterCount: 2, using: &generator)
        #expect(clusters.count == 2)
        #expect(Array(clusters[0]) == [0, 1, 2, 3, 4] && Array(clusters[1]) == [5, 6, 7, 8, 9])
        #expect((0 ..< 10).allSatisfy { clusters.community(of: $0) == ($0 < 5 ? 0 : 1) })
        #expect(clusters.description == "[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]")
    }

    @Test("Three planted blocks of 40 with sparse links between them, for many seeds")
    func plantedBlocks() throws {
        var state: UInt64 = 7
        func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state >> 33
        }
        // Vertices interleaved, so block b is {v : v % 3 == b}.
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< 120 {
            for v in u + 1 ..< 120 {
                let same = u % 3 == v % 3
                if next() % 1000 < (same ? 300 : 5) { edges.append(UndirectedEdge(u, v)) }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 120, edges: edges)
        for seed in 0 ..< 5 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let clusters = try graph.spectralClustering(clusterCount: 3, using: &generator)
            #expect(clusters.count == 3)
            #expect(Array(clusters[0]) == Array(stride(from: 0, to: 120, by: 3)), "seed \(seed)")
            #expect(Array(clusters[1]) == Array(stride(from: 1, to: 120, by: 3)), "seed \(seed)")
            #expect(Array(clusters[2]) == Array(stride(from: 2, to: 120, by: 3)), "seed \(seed)")
        }
    }

    @Test("Row normalization decides: on this tree the unit rows put vertex 2 with 3, 4, 7 (inertia 0.554 against 0.653)")
    func rowNormalization() throws {
        // The rows before normalization have their least inertia with vertex 2 on the other side.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 5), UndirectedEdge(1, 6), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 7)])
        for seed in 0 ..< 5 {
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let clusters = try graph.spectralClustering(clusterCount: 2, using: &generator)
            #expect(clusters.map(Array.init) == [[0, 1, 5, 6], [2, 3, 4, 7]], "seed \(seed)")
        }
    }

    @Test("k-means++ seeding, draw for draw: ten SplitMix64 seeds on a 10-vertex multigraph give one partition")
    func seeding() throws {
        // SplitMix64 (Steele, Lea and Flood 2014).
        struct SplitMix64: RandomNumberGenerator {
            var state: UInt64
            mutating func next() -> UInt64 {
                state &+= 0x9E37_79B9_7F4A_7C15
                var z = state
                z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                return z ^ (z >> 31)
            }
        }
        // λ₅ − λ₄ of N is 0.154. Each k-means++ center is drawn by the squared distance to the
        // nearest center so far; drawn by the distance to the first center only, three of these
        // seeds end elsewhere.
        let pairs = [(2, 6), (9, 0), (0, 9), (3, 1), (4, 2), (6, 4), (9, 8), (4, 9), (6, 8), (4, 2), (8, 4), (4, 3), (1, 6), (5, 6), (8, 4), (1, 5), (9, 0), (8, 4), (4, 3), (3, 5), (7, 5), (3, 0), (2, 8), (1, 4), (2, 4), (7, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for seed in UInt64(0) ..< 10 {
            var generator = SplitMix64(state: seed)
            let clusters = try graph.spectralClustering(clusterCount: 4, using: &generator)
            #expect(clusters.map(Array.init) == [[0, 9], [1, 5, 7], [2, 6, 8], [3, 4]], "seed \(seed)")
        }
    }

    @Test("Components are clusters when the count is the number of components")
    func components() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 3), UndirectedEdge(3, 6), UndirectedEdge(1, 4), UndirectedEdge(2, 5)])
        var generator = SeededRandomNumberGenerator(seed: 3)
        let clusters = try graph.spectralClustering(clusterCount: 3, using: &generator)
        #expect(clusters.map(Array.init) == [[0, 3, 6], [1, 4], [2, 5]])
    }

    @Test("A count of 1 is everything; a count of n is one vertex per cluster")
    func bounds() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        var generator = SeededRandomNumberGenerator(seed: 5)
        #expect(try graph.spectralClustering(clusterCount: 1, using: &generator).map(Array.init) == [[0, 1, 2, 3]])
        #expect(try graph.spectralClustering(clusterCount: 4, using: &generator).map(Array.init) == [[0], [1], [2], [3]])
        // Identical rows (K3's vertices are alike to two clusters): still exactly the count asked for.
        let triangle = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(try triangle.spectralClustering(clusterCount: 3, using: &generator).count == 3)
        let edgeless = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [])
        #expect(try edgeless.spectralClustering(clusterCount: 2, using: &generator).count == 2)
    }

    @Test("The same seed gives the same clustering; the system generator overload answers too")
    func determinism() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 12, edges: (0 ..< 12).map { UndirectedEdge($0, ($0 + 1) % 12) })
        var a = SeededRandomNumberGenerator(seed: 11), b = SeededRandomNumberGenerator(seed: 11)
        let first = try graph.spectralClustering(clusterCount: 3, using: &a)
        let second = try graph.spectralClustering(clusterCount: 3, using: &b)
        #expect(first == second)
        #expect(try graph.spectralClustering(clusterCount: 3).count == 3)
                #expect(try graph.spectralClustering(clusterCount: 3, weight: { _ in 1.0 }).count == 3)
    }

    @Test("Weights: a weight-0 middle edge cuts the path into its halves")
    func weights() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5)])
        var generator = SeededRandomNumberGenerator(seed: 2)
        let clusters = try graph.spectralClustering(clusterCount: 2, weight: { [9.0, 9, 0, 9, 9][$0] }, using: &generator)
        #expect(clusters.map(Array.init) == [[0, 1, 2], [3, 4, 5]])
        let single = try graph.spectralClustering(clusterCount: 2, weight: { [Float(9), 9, 0, 9, 9][$0] }, using: &generator)
        #expect(single == clusters)
    }

    @Test("community(checked:) and community(ofIndex:) agree with community(of:); a graph without indices")
    func lookups() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        var generator = SeededRandomNumberGenerator(seed: 4)
        let clusters = try graph.spectralClustering(clusterCount: 2, using: &generator)
        for v in 0 ..< 4 {
            #expect(try clusters.community(checked: v) == clusters.community(of: v))
            #expect(clusters.community(ofIndex: v) == clusters.community(of: v))
        }
        #expect(throws: VertexNotFound.self) { try clusters.community(checked: 4) }
        let names = UnindexedGraph(vertices: ["d", "c", "b", "a"], edges: [UndirectedEdge("d", "a"), UndirectedEdge("c", "b")])
        let named = try names.spectralClustering(clusterCount: 2, using: &generator)
        // Canonical order follows `vertices`.
        #expect(named.map(Array.init) == [["d", "a"], ["c", "b"]])
        #expect(try named.community(checked: "b") == 1)
        #expect(throws: VertexNotFound.self) { try named.community(checked: "z") }
    }
}

@Suite("Spectral clustering preconditions")
struct SpectralClusteringTrapTests {
    @Test("A cluster count outside 1...n, a lookup off the graph, tolerance ≤ 0, maxIterations 0, a negative weight")
    func preconditions() async throws {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = try graph.spectralClustering(clusterCount: 4, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = try graph.spectralClustering(clusterCount: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = try graph.spectralClustering(clusterCount: 2, using: &generator).community(of: 7)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = try graph.spectralClustering(clusterCount: 2, tolerance: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = try graph.spectralClustering(clusterCount: 2, maxIterations: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = try graph.spectralClustering(clusterCount: 2, weight: { [1.0, -1][$0] }, using: &generator)
        }
        // Without the faults.
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var generator = SeededRandomNumberGenerator(seed: 1)
        #expect(try graph.spectralClustering(clusterCount: 3, using: &generator).count == 3)
        #expect(try graph.spectralClustering(clusterCount: 1, using: &generator).community(of: 2) == 0)
        #expect(try graph.spectralClustering(clusterCount: 2, tolerance: 1e-6, maxIterations: 1_000, using: &generator).count == 2)
        #expect(try graph.spectralClustering(clusterCount: 2, weight: { [1.0, 0][$0] }, using: &generator).map(Array.init) == [[0, 1], [2]])
    }
}

@Suite("Spectral clustering against planted cliques, with shrinking", .tags(.randomized))
struct SpectralClusteringPropertyTests {
    @Test("Spectral clustering recovers 2 to 4 planted cliques of 3 to 8 vertices joined in a chain by single edges")
    func plantedCliques() async {
        func check(_ sizes: [Int], _ seed: Int) throws {
            var edges: [UndirectedEdge<Int>] = []
            var start = 0
            var blocks: [[Int]] = []
            for size in sizes {
                let block = Array(start ..< start + size)
                for u in block { for v in block where u < v { edges.append(UndirectedEdge(u, v)) } }
                if start > 0 { edges.append(UndirectedEdge(start - 1, start)) }
                blocks.append(block)
                start += size
            }
            let graph = ReferencePseudograph(vertices: 0 ..< start, edges: edges)
            var generator = SeededRandomNumberGenerator(seed: UInt(seed))
            let clusters = try graph.spectralClustering(clusterCount: sizes.count, using: &generator)
            #expect(clusters.map(Array.init) == blocks, "sizes \(sizes), seed \(seed)")
        }
        await propertyCheck(count: 100, input: Gen.int(in: 3 ... 8).array(of: 2 ... 4), Gen.int(in: 0 ... 1_000_000)) { sizes, seed in
            try check(sizes, seed)
        }
    }
}
