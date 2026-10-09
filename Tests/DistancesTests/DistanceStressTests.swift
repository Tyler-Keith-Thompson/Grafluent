// §H: 10⁵-vertex shapes, which no recursive search survives and no distance matrix fits (10¹⁰
// entries). Each runs inside a Task, whose stack is much smaller than the main thread's, with a
// one-minute limit. The undirected unweighted extrema run the bounding algorithm: a handful of
// searches on the path and the star (DI-901 – DI-908), about n on the 10⁴-cycle (DI-910, DI-911,
// every eccentricity equal), 11 – 19 on a 300 × 300 grid. The all-pairs measures (Wiener index,
// centroid) take one search per vertex, 10¹⁰ steps at 10⁵ vertices: DI-905, DI-909, DI-913 and
// DI-914 run here at 10⁴ vertices (their full size is a benchmark), with the catalog's closed forms
// evaluated by `ref.py` at that size. Directed and weighted shapes stop early where api.md says so:
// a directed path's `diameter()` after the second search, a disconnected weighted graph after the
// first. Expected values are catalog cells or were computed with `ref.py` (its bounding model, its
// closed forms, or one search). Case IDs (DI-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import Distances
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Distances at 10⁵ vertices, without recursion")
struct DistanceStressTests {
    @Test("DI-901 U(P(0..99999)).diameter() is 99999", .timeLimit(.minutes(1)))
    func pathDiameter() async throws {
        try await Task {
            // U: [] P(0..99999)
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(graph.diameter() == 99_999)
            // Computed with ref.py: from 0, the first peripheral vertex, to the other end.
            let path = try #require(graph.diameterPath())
            #expect(path.vertices == Array(0 ..< n))
            #expect(path.edges == Array(0 ..< n - 1))
        }.value
    }

    @Test("DI-902 U(P(0..99999)).radius() is 50000", .timeLimit(.minutes(1)))
    func pathRadius() async {
        await Task {
            // U: [] P(0..99999)
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(graph.radius() == 50_000)
        }.value
    }

    @Test("DI-903 U(P(0..99999)).center() is [49999, 50000]", .timeLimit(.minutes(1)))
    func pathCenter() async {
        await Task {
            // U: [] P(0..99999)
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(graph.center() == [49_999, 50_000])
        }.value
    }

    @Test("DI-904 U(P(0..99999)).periphery() is [0, 99999]", .timeLimit(.minutes(1)))
    func pathPeriphery() async {
        await Task {
            // U: [] P(0..99999)
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(graph.periphery() == [0, 99_999])
        }.value
    }

    @Test("DI-901 – DI-904 U(P(0..99999)).eccentricities() on UndirectedAdjacencyList: every vertex's max(i, n − 1 − i)", .timeLimit(.minutes(1)))
    func pathEccentricities() async {
        await Task {
            // U: [] P(0..99999)
            let n = 100_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let eccentricities = graph.eccentricities()
            // Computed with ref.py: its bounding model gives max(i, n − 1 − i) after 5 searches.
            let values = (0 ..< n).map { eccentricities.eccentricity(ofIndex: $0) }
            let expected: [Int?] = (0 ..< n).map { max($0, n - 1 - $0) }
            #expect(values == expected)
            #expect(eccentricities.radius == 50_000)
            #expect(eccentricities.diameter == 99_999)
            #expect(eccentricities.center == [49_999, 50_000])
            #expect(eccentricities.periphery == [0, 99_999])
        }.value
    }

    @Test("DI-905 at 10⁴ vertices: U(P(0..9999)).wienerIndex() is 166666665000, (n³ − n)/6", .timeLimit(.minutes(1)))
    func pathWienerIndex() async {
        await Task {
            // U: [] P(0..9999); the catalog's row is P(0..99999), 166666666650000 (benchmark only).
            let n = 10_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            // Computed with ref.py: the closed form at n = 10⁴.
            #expect(graph.wienerIndex() == 166_666_665_000)
        }.value
    }

    @Test("DI-913 at 10⁴ vertices: U(P(0..9999)).centroid() is [4999, 5000]", .timeLimit(.minutes(1)))
    func pathCentroid() async {
        await Task {
            // U: [] P(0..9999); the catalog's row is P(0..99999), [49999, 50000] (benchmark only).
            let n = 10_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            // Computed with ref.py: the closed form at n = 10⁴.
            #expect(graph.centroid() == [4_999, 5_000])
        }.value
    }

    @Test("DI-915 U(P(0..99999)).density is 2e-05", .timeLimit(.minutes(1)))
    func pathDensity() async {
        await Task {
            // U: [] P(0..99999)
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            #expect(graph.density == 2e-05)
        }.value
    }

    @Test("DI-906 U(S(0; 1..99999)).diameter() is 2", .timeLimit(.minutes(1)))
    func starDiameter() async {
        await Task {
            // U: [] S(0;1..99999)
            let graph = ReferencePseudograph(edges: (1 ... 99_999).map { UndirectedEdge(0, $0) })
            #expect(graph.diameter() == 2)
        }.value
    }

    @Test("DI-907 U(S(0; 1..99999)).radius() is 1", .timeLimit(.minutes(1)))
    func starRadius() async {
        await Task {
            // U: [] S(0;1..99999)
            let graph = ReferencePseudograph(edges: (1 ... 99_999).map { UndirectedEdge(0, $0) })
            #expect(graph.radius() == 1)
        }.value
    }

    @Test("DI-908 U(S(0; 1..99999)).center() is [0]; the periphery is every leaf", .timeLimit(.minutes(1)))
    func starCenter() async {
        await Task {
            // U: [] S(0;1..99999)
            let graph = UndirectedAdjacencyList(edges: (1 ... 99_999).map { UndirectedEdge(0, $0) })
            #expect(graph.center() == [0])
            // Computed with ref.py: the closed form and the bounding model agree.
            #expect(graph.periphery() == Array(1 ... 99_999))
            let path = graph.diameterPath()
            #expect(path?.length == 2)
        }.value
    }

    @Test("DI-909 at 10⁴ vertices: U(S(0; 1..9999)).wienerIndex() is 99980001, (n − 1) + (n − 1)(n − 2)", .timeLimit(.minutes(1)))
    func starWienerIndex() async {
        await Task {
            // U: [] S(0;1..9999); the catalog's row is S(0;1..99999), 9999800001 (benchmark only).
            let graph = ReferencePseudograph(edges: (1 ... 9_999).map { UndirectedEdge(0, $0) })
            // Computed with ref.py: the closed form at n = 10⁴.
            #expect(graph.wienerIndex() == 99_980_001)
        }.value
    }

    @Test("DI-914 at 10⁴ vertices: U(S(0; 1..9999)).centroid() is [0]", .timeLimit(.minutes(1)))
    func starCentroid() async {
        await Task {
            // U: [] S(0;1..9999); the catalog's row is S(0;1..99999), [0] (benchmark only).
            let graph = ReferencePseudograph(edges: (1 ... 9_999).map { UndirectedEdge(0, $0) })
            #expect(graph.centroid() == [0])
        }.value
    }

    @Test("DI-910 U(C(0..9999)).diameter() is 5000: bounding's worst shape, every eccentricity equal", .timeLimit(.minutes(1)))
    func cycleDiameter() async {
        await Task {
            // U: [] C(0..9999)
            let n = 10_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            #expect(graph.diameter() == 5_000)
        }.value
    }

    @Test("DI-911 U(C(0..9999)).radius() is 5000", .timeLimit(.minutes(1)))
    func cycleRadius() async {
        await Task {
            // U: [] C(0..9999)
            let n = 10_000
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            #expect(graph.radius() == 5_000)
        }.value
    }

    @Test("DI-912 U(C(0..9999)).wienerIndex() is 125000000000", .timeLimit(.minutes(1)))
    func cycleWienerIndex() async {
        await Task {
            // U: [] C(0..9999)
            let n = 10_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
            #expect(graph.wienerIndex() == 125_000_000_000)
        }.value
    }

    @Test("A 300 × 300 grid: diameter 598, radius 300, four central and four peripheral vertices", .timeLimit(.minutes(1)))
    func grid() async {
        await Task {
            // U: [] grid(300,300)
            let c = 300
            let pairs: [(Int, Int)] = (0 ..< c * c).flatMap { v -> [(Int, Int)] in
                (v % c + 1 < c ? [(v, v + 1)] : []) + (v / c + 1 < c ? [(v, v + c)] : [])
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< c * c, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // Computed with ref.py's bounding model (11 – 19 searches).
            #expect(graph.diameter() == 598)
            #expect(graph.radius() == 300)
            #expect(graph.center() == [44_849, 44_850, 45_149, 45_150])
            #expect(graph.periphery() == [0, 299, 89_700, 89_999])
        }.value
    }

    @Test("K₄₀₀: diameter and radius 1, every vertex central, Wiener index 79800 (vertex-transitive: n searches)", .timeLimit(.minutes(1)))
    func completeGraph() async {
        await Task {
            // U: [] K(400)
            let n = 400
            let pairs: [(Int, Int)] = (0 ..< n).flatMap { i in (i + 1 ..< n).map { (i, $0) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // Computed with ref.py.
            #expect(graph.diameter() == 1)
            #expect(graph.radius() == 1)
            #expect(graph.center() == Array(0 ..< n))
            #expect(graph.wienerIndex() == 79_800)
        }.value
    }

    @Test("D(P(0..99999)) on CompressedSparseRow: diameter() is nil (the second search misses vertex 0); eccentricity(of: 0) is 99999", .timeLimit(.minutes(1)))
    func directedPath() async {
        await Task {
            // D: [0..99999] P(0..99999)
            let n = 100_000
            let graph = CompressedSparseRow(vertexCount: n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
            // Computed with ref.py: one search from 0 reaches everything, one from 1 does not.
            #expect(graph.diameter() == nil)
            #expect(graph.diameterPath() == nil)
            #expect(graph.eccentricity(of: 0) == 99_999)
            #expect(graph.eccentricity(of: 1) == nil)
        }.value
    }

    @Test("U(P(0..99999)) weighted e mod 3 + 1: one Dijkstra per eccentricity(of:weight:)", .timeLimit(.minutes(1)))
    func weightedPathEccentricity() async {
        await Task {
            // U: [] P(0..99999), weight: e%3+1
            let n = 100_000
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            // Computed with ref.py: Dijkstra from 0 and from 50000.
            #expect(graph.eccentricity(of: 0, weight: { $0 % 3 + 1 }) == 199_998)
            #expect(graph.eccentricity(of: 50_000, weight: { $0 % 3 + 1 }) == 99_999)
        }.value
    }

    @Test("U(P(0..49999), P(50000..99999)) weighted: not connected, so every all-pairs measure is nil after one search", .timeLimit(.minutes(1)))
    func weightedDisconnected() async {
        await Task {
            // U: [] P(0..49999), P(50000..99999), weight: 1
            let half = 50_000
            let edges = (0 ..< half - 1).map { UndirectedEdge($0, $0 + 1) } + (half ..< 2 * half - 1).map { UndirectedEdge($0, $0 + 1) }
            let graph = ReferencePseudograph(vertices: 0 ..< 2 * half, edges: edges)
            // Computed with ref.py: the search from 0 misses vertex 50000.
            #expect(graph.diameter(weight: { _ in 1 }) == nil)
            #expect(graph.radius(weight: { _ in 1 }) == nil)
            #expect(graph.wienerIndex(weight: { _ in 1 }) == nil)
            #expect(graph.centroid(weight: { _ in 1 }).count == 2 * half)
            #expect(graph.averageShortestPathLength(weight: { _ in 1.0 }) == nil)
        }.value
    }
}
