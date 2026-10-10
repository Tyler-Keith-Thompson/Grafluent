// Conventions the catalog rows do not isolate: results are plain arrays in `vertices` order (not
// label order, not insertion order of the seeds), generic code over `some Graph`,
// `CompressedSparseRow` through `AdjacencyList(csr).undirected`, an undirected graph read as directed
// and back (every edge a parallel pair), other weight types (`Int32`, `UInt8`, `Float`, `Int8`),
// the weight closure read once per vertex, integer ratios compared exactly where `Double` would tie,
// the unweighted entry points as the unit weights, any `Sequence` for seeds and checks, an edge
// cover built from a matching that is not maximum (and one with a `Double` weight), and König's
// cover on a `BipartiteGraph` through `bipartition()`. Expected values are worked out in each test's
// comments. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import CompressedSparseRowModule
import Covering
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("Covering results and conventions", .tags(.conformance))
struct CoveringConformanceTests {
    @Test("Vertex sets are in `vertices` order, not label order: P4 listed as c, a, d, b")
    func verticesOrder() {
        // Vertices [c, a, d, b], path c–a–d–b. Indices: c 0, a 1, d 2, b 3. The least maximum
        // independent set by index is {c, d} (indices 0, 2), listed as [c, d].
        let graph = UndirectedAdjacencyList(vertices: ["c", "a", "d", "b"], edges: [UndirectedEdge("c", "a"), UndirectedEdge("a", "d"), UndirectedEdge("d", "b")])
        #expect(graph.maximumIndependentSet() == ["c", "d"])
        #expect(graph.minimumVertexCover() == ["a", "b"])
        // Seeds in any order: the result is still in `vertices` order.
        #expect(graph.maximalIndependentSet(containing: ["b", "c"]) == ["c", "b"])
        // γ(P4) = 2; the least by index of the dominating pairs is {c, d}.
        #expect(graph.minimumDominatingSet() == ["c", "d"])
        #expect(graph.approximateMinimumDominatingSet() == ["a", "d"])
    }

    @Test("Generic code over some Graph sees the same results as concrete code")
    func genericCode() {
        func everything(_ graph: some Graph<Int>) -> [[Int]] {
            [graph.maximumIndependentSet(), graph.minimumVertexCover(), graph.maximalIndependentSet(), graph.minimumDominatingSet(),
             graph.approximateMinimumVertexCover(), graph.approximateMinimumDominatingSet(), [graph.independenceNumber()]]
        }
        // C5: MIS [0, 2] (CV-015), cover [1, 3, 4] (CV-059), α = 2.
        let cycle = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) })
        let concrete = [cycle.maximumIndependentSet(), cycle.minimumVertexCover(), cycle.maximalIndependentSet(), cycle.minimumDominatingSet(),
                        cycle.approximateMinimumVertexCover(), cycle.approximateMinimumDominatingSet(), [cycle.independenceNumber()]]
        #expect(everything(cycle) == concrete)
        #expect(concrete[0] == [0, 2] && concrete[1] == [1, 3, 4] && concrete[6] == [2])
        #expect(cycle.isVertexCover(concrete[4]))
    }

    @Test("CompressedSparseRow through AdjacencyList(csr).undirected: K3,3")
    func compressedSparseRow() throws {
        let csr = CompressedSparseRow(vertexCount: 6, edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = AdjacencyList(csr).undirected
        // Both sides are maximum independent sets; the lesser by index is {0, 1, 2} (CV-025).
        #expect(graph.maximumIndependentSet() == [0, 1, 2])
        #expect(graph.minimumVertexCover() == [3, 4, 5])
        let sides = try #require(graph.bipartition())
        #expect(graph.minimumVertexCover(bipartition: sides) == [0, 1, 2])
        // γ(K3,3) = 2: {0, 3} is the least dominating pair.
        #expect(graph.minimumDominatingSet() == [0, 3])
        let cover = try #require(graph.minimumEdgeCover())
        #expect(cover.count == 3 && graph.isEdgeCover(cover))
    }

    @Test("An undirected graph read as directed and back: every edge a parallel pair, the same vertex sets")
    func directedAndBack() throws {
        // The bull: triangle 0–1–2 with pendants 3 at 0 and 4 at 1 (NetworkX's bull_graph, CV-033).
        let bull = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 4)])
        let doubled = bull.directed.undirected
        #expect(doubled.edgeCount == 10)
        #expect(doubled.maximumIndependentSet() == bull.maximumIndependentSet())
        #expect(bull.maximumIndependentSet() == [0, 3, 4])
        #expect(doubled.minimumVertexCover() == bull.minimumVertexCover())
        #expect(doubled.minimumDominatingSet() == bull.minimumDominatingSet())
        #expect(doubled.approximateMinimumDominatingSet() == bull.approximateMinimumDominatingSet())
        #expect(doubled.maximalIndependentSet() == bull.maximalIndependentSet())
        #expect(doubled.isVertexCover(doubled.approximateMinimumVertexCover()))
        let cover = try #require(doubled.minimumEdgeCover())
        #expect(cover.count == 5 - 2 && doubled.isEdgeCover(cover))
    }

    @Test("Other weight types: Int32, UInt8 and Float for the vertex cover, Int8, UInt8 and Float for the dominating set; zero weights")
    func weightTypes() {
        // CV-105: path 0–1–2–3, weights [2, 3, 2, 3]: [0, 1, 2].
        let path = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let weights = [2, 3, 2, 3]
        #expect(path.approximateMinimumVertexCover(weight: { Int32(weights[$0]) }) == [0, 1, 2])
        #expect(path.approximateMinimumVertexCover(weight: { UInt8(weights[$0]) }) == [0, 1, 2])
        // CV-109 in Float: [0.5, 0.75, 0.25] on 0–1–2 gives [0, 1].
        let short = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let floats: [Float] = [0.5, 0.75, 0.25]
        #expect(short.approximateMinimumVertexCover(weight: { floats[$0] }) == [0, 1])
        // CV-163: edges 0–1, 2–3, 1–2, weights [2, 4, 4, 2]: [0, 3] in every type.
        let tie = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(1, 2)])
        let tieWeights = [2, 4, 4, 2]
        #expect(tie.approximateMinimumDominatingSet(weight: { Int8(tieWeights[$0]) }) == [0, 3])
        #expect(tie.approximateMinimumDominatingSet(weight: { UInt8(tieWeights[$0]) }) == [0, 3])
        #expect(tie.approximateMinimumDominatingSet(weight: { Float(tieWeights[$0]) }) == [0, 3])
        // Every weight zero: each ratio is 0, so the least index that dominates anything new wins:
        // 0 (dominating 0, 1), then 1 (dominating 2), then 2 (dominating 3).
        #expect(tie.approximateMinimumDominatingSet(weight: { (_: Int) -> Int in 0 }) == [0, 1, 2])
        // Every cost zero in Bar-Yehuda–Even: each uncovered edge takes its lesser end, 0, then 1 (edge 1–2), then 2 (2–3).
        #expect(path.approximateMinimumVertexCover(weight: { (_: Int) -> Int in 0 }) == [0, 1, 2])
    }

    @Test("The unweighted entry points are the unit weights; the vertex-cover weight is read once per vertex")
    func unitWeights() {
        // Petersen (NetworkX's numbering).
        let petersen = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: petersen.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.approximateMinimumVertexCover() == graph.approximateMinimumVertexCover(weight: { (_: Int) -> Int in 1 }))
        #expect(graph.approximateMinimumVertexCover() == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(graph.approximateMinimumDominatingSet() == graph.approximateMinimumDominatingSet(weight: { (_: Int) -> Int in 1 }))
        #expect(graph.approximateMinimumDominatingSet() == graph.approximateMinimumDominatingSet(weight: { (_: Int) -> Double in 1 }))
        var seen: [Int] = []
        _ = graph.approximateMinimumVertexCover(weight: { (v: Int) -> Int in
            seen.append(v)
            return 1
        })
        #expect(seen.sorted() == Array(0 ..< 10))
    }

    @Test("Integer weights compare ratios exactly: 2⁵³ + 1 against 2⁵³ on one edge, where Double division would tie")
    func exactIntegerRatios() {
        // Each vertex dominates both: ratios (2⁵³ + 1) / 2 and 2⁵³ / 2. Exactly, vertex 1 is lighter;
        // as doubles both are 2⁵² and the tie would go to vertex 0.
        let edge = UndirectedAdjacencyList(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        let weights = [(1 << 53) + 1, 1 << 53]
        #expect(edge.approximateMinimumDominatingSet(weight: { weights[$0] }) == [1])
        // The same doubles tie, and the least index wins, as in NetworkX.
        #expect(edge.approximateMinimumDominatingSet(weight: { Double(weights[$0]) }) == [0])
    }

    @Test("Seeds and checked elements may be any Sequence, with repeats")
    func sequences() {
        let path = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: (0 ..< 5).map { UndirectedEdge($0, $0 + 1) })
        #expect(path.maximalIndependentSet(containing: Set([1, 4])) == [1, 4])
        #expect(path.maximalIndependentSet(containing: stride(from: 1, to: 6, by: 2)) == [1, 3, 5])
        #expect(path.maximalIndependentSet(containing: [3, 3, 3]) == [0, 3, 5])
        #expect(path.isVertexCover(stride(from: 1, to: 6, by: 2)))
        #expect(path.isIndependentSet((0 ..< 6).lazy.filter { $0.isMultiple(of: 2) }))
        #expect(path.isDominatingSet(Set([1, 4])))
        #expect(!path.isDominatingSet([1, 1, 1]))
        #expect(path.isEdgeCover(stride(from: 0, to: 5, by: 2)))
        #expect(path.isEdgeCover(Set([0, 2, 4, 1])))
        #expect(!path.isEdgeCover(0 ..< 2))
    }

    @Test("minimumEdgeCover(matching:) from a matching that is not maximum: still an edge cover, larger than minimumEdgeCover(); an empty matching; a Double-weighted matching")
    func edgeCoverFromOtherMatchings() {
        // P4 with the middle edge first: positions 0 = 1–2, 1 = 0–1, 2 = 2–3. The greedy matching is
        // [0]; then 0 takes its first edge (1) and 3 its first edge (2): [0, 1, 2]. Edmonds' matching
        // is [1, 2], perfect, so minimumEdgeCover() is [1, 2].
        let middle = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        #expect(middle.maximalMatching().edges == [0])
        #expect(middle.minimumEdgeCover(matching: middle.maximalMatching()) == [0, 1, 2])
        #expect(middle.minimumEdgeCover() == [1, 2])
        // Edges 0 = 1–3, 1 = 0–1, 2 = 3–2 and the empty matching (every weight negative): 0 takes edge
        // 1, which covers 1 too, so 1 is skipped (its first edge, 0, is not taken); 2 takes edge 2,
        // covering 3. [1, 2], two edges, the minimum.
        let skip = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(1, 3), UndirectedEdge(0, 1), UndirectedEdge(3, 2)])
        let empty = skip.maximumWeightMatching(weight: { (_: Int) -> Int in -1 })
        #expect(empty.edges.isEmpty)
        #expect(skip.minimumEdgeCover(matching: empty) == [1, 2])
        // A Double-weighted maximum matching of P4: the perfect one, so the cover is its edges.
        let path = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let heavy = path.maximumWeightMatching(weight: { (_: Int) -> Double in 1.5 })
        #expect(heavy.edges == [0, 2])
        #expect(path.minimumEdgeCover(matching: heavy) == [0, 2])
        #expect(UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).minimumEdgeCover() == nil)
    }

    @Test("König's cover on a BipartiteGraph through bipartition(): its own sides wherever an edge is (an isolated right vertex goes left), so the cover with the most of its left vertices")
    func koenigOnBipartiteGraph() throws {
        // CV-064 / CV-065 shapes: L [0, 1, 2], R [3, 4, 5, 6] with 6 isolated.
        let graph = try #require(BipartiteGraph(left: [0, 1, 2], right: [3, 4, 5, 6], edges: [UndirectedEdge(0, 3), UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(2, 4), UndirectedEdge(2, 5)]))
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 1, 2, 6])
        #expect(graph.minimumVertexCover(bipartition: sides) == [0, 1, 2])
        // minimumVertexCover() is the other extreme here: the right side.
        #expect(graph.minimumVertexCover() == [3, 4, 5])
        #expect(graph.maximumIndependentSet() == [0, 1, 2, 6])
    }

    @Test("Empty and edgeless graphs: empty results, every vertex independent and dominating, no edge cover")
    func edgeless() {
        let empty = UndirectedAdjacencyList<Int>()
        #expect(empty.maximumIndependentSet().isEmpty && empty.minimumVertexCover().isEmpty && empty.minimumDominatingSet().isEmpty)
        #expect(empty.minimumEdgeCover() == [])
        #expect(empty.independenceNumber() == 0)
        let three = UndirectedAdjacencyList(vertices: [5, 3, 9])
        #expect(three.maximumIndependentSet() == [5, 3, 9])
        #expect(three.minimumVertexCover() == [])
        #expect(three.minimumDominatingSet() == [5, 3, 9])
        #expect(three.approximateMinimumDominatingSet() == [5, 3, 9])
        #expect(three.approximateMinimumVertexCover() == [])
        #expect(three.maximalIndependentSet() == [5, 3, 9])
        #expect(three.minimumEdgeCover() == nil)
        #expect(three.isVertexCover([]) && !three.isDominatingSet([5, 3]) && !three.isEdgeCover([]))
    }
}
