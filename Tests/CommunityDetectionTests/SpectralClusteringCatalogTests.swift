// §K: spectral clustering (Ng–Jordan–Weiss): the unit rows of the normalized Laplacian's k smallest
// eigenvectors, clustered by k-means (10 k-means++ runs from the seeded generator, the least inertia
// kept). Expected is the labeling of least inertia over every labeling (ref.py, by brute force),
// on graphs whose k smallest eigenvalues stand apart from the next. Trap rows are exit tests.
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); scalars compare within 1e-12 relative to max(1, |value|), partitions
// exactly, in canonical order (communities by least vertex number, each in `vertices` order). Every
// partition row also checks `count`, `community(of:)` against membership, `community(ofIndex:)`
// against `community(of:)`, and the modularity of the result (at the call's weight and resolution)
// against ref.py's; undirected rows of the measures, Louvain and greedy modularity also run on
// `graph.directedView` (the same values). Case IDs (CD-nnn) refer to the catalog; see README.md.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Spectral clustering (Ng–Jordan–Weiss)")
struct SpectralClusteringCatalogTests {
    @Test("CD-241 U(K(0..2), K(3..5), 2-3).spectralClustering(clusterCount: 2, using: rng(1)) is [[0, 1, 2], [3, 4, 5]]: The two triangles")
    func spectralClustering241() throws {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = try graph.spectralClustering(clusterCount: 2, using: &generator)
        let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        var again = SeededRandomNumberGenerator(seed: 1)
        #expect(try graph.spectralClustering(clusterCount: 2, using: &again) == result, "the same seed again")
    }

    @Test("CD-242 U(P(0,1,2), P(3,4,5)).spectralClustering(clusterCount: 2, using: rng(1)) is [[0, 1, 2], [3, 4, 5]]: Two components")
    func spectralClustering242() throws {
        // U: P(0,1,2), P(3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = try graph.spectralClustering(clusterCount: 2, using: &generator)
        let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        var again = SeededRandomNumberGenerator(seed: 1)
        #expect(try graph.spectralClustering(clusterCount: 2, using: &again) == result, "the same seed again")
    }

    @Test("CD-243 U(P(0..3)).spectralClustering(clusterCount: 1, using: rng(1)) is [[0, 1, 2, 3]]: One cluster")
    func spectralClustering243() throws {
        // U: P(0..3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = try graph.spectralClustering(clusterCount: 1, using: &generator)
        let expected: [[Int]] = [[0, 1, 2, 3]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q) <= 1e-12)
        var again = SeededRandomNumberGenerator(seed: 1)
        #expect(try graph.spectralClustering(clusterCount: 1, using: &again) == result, "the same seed again")
    }

    @Test("CD-244 U(0-1, 0-2, 0-5, 1-6, 2-3, 3-4, 4-7).spectralClustering(clusterCount: 2, using: rng(1)) is [[0, 1, 5, 6], [2, 3, 4, 7]]: A tree where the unit rows decide: without the row scaling, 2 goes with 0")
    func spectralClustering244() throws {
        // U: 0-1, 0-2, 0-5, 1-6, 2-3, 3-4, 4-7
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 5), (1, 6), (2, 3), (3, 4), (4, 7)]
        let listed: [Int] = [0, 1, 2, 5, 6, 3, 4, 7]
        let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = try graph.spectralClustering(clusterCount: 2, using: &generator)
        let expected: [[Int]] = [[0, 1, 5, 6], [2, 3, 4, 7]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        var again = SeededRandomNumberGenerator(seed: 1)
        #expect(try graph.spectralClustering(clusterCount: 2, using: &again) == result, "the same seed again")
    }

    @Test("CD-245 U(K(0..2), K(3..5), K(6..8), 2-3, 5-6).spectralClustering(clusterCount: 3, using: rng(1)) is [[0, 1, 2], [3, 4, 5], [6, 7, 8]]: Three triangles in a chain")
    func spectralClustering245() throws {
        // U: K(0..2), K(3..5), K(6..8), 2-3, 5-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (6, 7), (6, 8), (7, 8),
            (2, 3), (5, 6)]
        let graph = ReferencePseudograph(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = try graph.spectralClustering(clusterCount: 3, using: &generator)
        let expected: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result)
        #expect(abs(q - 0.48347107438016523) <= 1e-12 * max(1, abs(0.48347107438016523)))
        var again = SeededRandomNumberGenerator(seed: 1)
        #expect(try graph.spectralClustering(clusterCount: 3, using: &again) == result, "the same seed again")
    }

    @Test("CD-246 U(P(0..5)).spectralClustering(clusterCount: 2, weight: [3, 3, 0, 3, 3], using: r… is [[0, 1, 2], [3, 4, 5]]: A weight-0 edge separates")
    func spectralClustering246() throws {
        // U: P(0..5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w: [Double] = [3, 3, 0, 3, 3]
        var generator = SeededRandomNumberGenerator(seed: 1)
        let result = try graph.spectralClustering(clusterCount: 2, weight: { w[$0] }, using: &generator)
        let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
        #expect(result.map { Array($0) } == expected)
        #expect(result.count == expected.count)
        for (c, community) in expected.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
        for (i, v) in graph.vertices.enumerated() {
            #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
        }
        // The modularity of the result (ref.py's model).
        let q = graph.modularity(of: result, weight: { w[$0] })
        #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        var again = SeededRandomNumberGenerator(seed: 1)
        #expect(try graph.spectralClustering(clusterCount: 2, weight: { w[$0] }, using: &again) == result, "the same seed again")
    }

    @Test("CD-247 U(P(0,1,2)).spectralClustering(clusterCount: 4, using: rng(1)) traps: clusterCount > vertexCount")
    func spectralClustering247() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = try graph.spectralClustering(clusterCount: 4, using: &generator)
        }
    }

    @Test("CD-248 U(P(0,1,2)).spectralClustering(clusterCount: 0, using: rng(1)) traps: clusterCount < 1")
    func spectralClustering248() async {
        await #expect(processExitsWith: .failure) {
            // U: P(0,1,2)
            let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var generator = SeededRandomNumberGenerator(seed: 1)
            _ = try graph.spectralClustering(clusterCount: 0, using: &generator)
        }
    }
}
