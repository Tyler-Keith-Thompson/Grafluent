// Construction and validation. Case IDs (CSR-Cnn, CSR-Inn) refer to the catalog of cases harvested
// from petgraph, Boost.Graph, scipy, neo4j's graph crate, GAP, NetworkX, JGraphT, GraphBLAS and
// Ligra; see README.md. Expected arrays come from those suites or were computed independently of
// the code under test.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("CompressedSparseRow construction")
struct CompressedSparseRowConstructionTests {
    // MARK: Empty and isolated vertices

    @Test("CSR-C01 the empty graph has one offset and no targets")
    func empty() {
        for graph in [CompressedSparseRow(), CompressedSparseRow(vertexCount: 0), CompressedSparseRow(vertexCount: 0, edges: [])] {
            #expect(graph.vertexCount == 0)
            #expect(graph.edgeCount == 0)
            #expect(graph.offsets == [0])
            #expect(graph.targets == [])
            #expect(graph.vertices.isEmpty)
            #expect(graph.edges.isEmpty)
            #expect(!graph.contains(0))
            #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 0)))
        }
    }

    @Test("CSR-C02 isolated vertices give n + 1 zero offsets", arguments: [1, 3, 10, 64])
    func isolated(_ n: Int) {
        let graph = CompressedSparseRow(vertexCount: n)
        #expect(graph.offsets == Array(repeating: 0, count: n + 1))
        #expect(graph.targets == [])
        #expect(graph.vertices == 0 ..< n)
        for v in 0 ..< n {
            #expect(graph.outDegree(of: v) == 0)
            #expect(graph.successors(of: v).isEmpty)
        }
    }

    @Test("CSR-C03 an explicit vertex count is kept even with no edges")
    func explicitCountWithoutEdges() {
        // neo4j infers one vertex from an empty edge list, petgraph infers none; neither is right.
        let graph = CompressedSparseRow(vertexCount: 4, edges: [])
        #expect(graph.vertexCount == 4)
        #expect(graph.offsets == [0, 0, 0, 0, 0])
    }

    @Test("CSR-C04 trailing isolated vertices survive")
    func trailingIsolated() {
        // neo4j directed_from_node_values_exceeding_edge_list_max_id.
        let graph = CompressedSparseRow(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.offsets == [0, 1, 2, 2, 2])
        #expect(graph.targets == [1, 2])
        #expect(graph.outDegree(of: 3) == 0)
    }

    @Test("CSR-C05 leading and middle empty rows")
    func leadingEmptyRows() {
        // scipy sparse/tests/test_base.py constructor2.
        let graph = CompressedSparseRow(vertexCount: 6, edges: [DirectedEdge(from: 3, to: 4)])
        #expect(graph.offsets == [0, 0, 0, 0, 1, 1, 1])
        #expect(graph.targets == [4])
    }

    // MARK: Canonical rows

    @Test("CSR-C06 unsorted input produces sorted rows")
    func unsortedInput() {
        // Boost.Graph test/csr_graph_test.cpp. Boost itself keeps input order: targets [2,2,1,0,0,2].
        let graph = CompressedSparseRow(vertexCount: 6, edges: [
            DirectedEdge(from: 5, to: 0), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 1),
            DirectedEdge(from: 4, to: 0), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 5, to: 2),
        ])
        #expect(graph.offsets == [0, 1, 1, 1, 2, 4, 6])
        #expect(graph.targets == [2, 2, 0, 1, 0, 2])
    }

    @Test("CSR-C07 construction is order-independent: identical arrays for any edge order", .tags(.randomized), arguments: 0 ..< 20 as Range<UInt>)
    func orderIndependence(seed: UInt) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        for fixture in [DirectedFixture<Int>.boost24, .boostWebGraph, .jgraphtSparseDirected, .petgraphBellmanFord] {
            let reference = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            let reversed = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges.reversed())
            let shuffled = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges.shuffled(using: &rng))
            #expect(reversed.offsets == reference.offsets, "\(fixture.name)")
            #expect(reversed.targets == reference.targets, "\(fixture.name)")
            #expect(shuffled.offsets == reference.offsets, "\(fixture.name)")
            #expect(shuffled.targets == reference.targets, "\(fixture.name)")
            #expect(shuffled == reference)
        }
    }

    @Test("CSR-C09 rows already grouped by source but unsorted within come out sorted")
    func unsortedWithinRows() {
        // neo4j sort_targets_test: rows [1, 0], [4, 2, 3], [], [5, 6, 7].
        let rows: [[Int]] = [[1, 0], [4, 2, 3], [], [5, 6, 7]]
        let edges = rows.enumerated().flatMap { source, targets in targets.map { DirectedEdge(from: source, to: $0) } }
        let graph = CompressedSparseRow(vertexCount: 8, edges: edges)
        #expect(graph.offsets == [0, 2, 5, 5, 8, 8, 8, 8, 8])
        #expect(graph.targets == [0, 1, 2, 3, 4, 5, 6, 7])
    }

    @Test("CSR-C10 duplicate edges collapse")
    func duplicatesCollapse() {
        // scipy: entries at (0,0), (2,1), (2,1), (0,0).
        let graph = CompressedSparseRow(vertexCount: 3, edges: [
            DirectedEdge(from: 0, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 0, to: 0),
        ])
        #expect(graph.edgeCount == 2)
        #expect(graph.offsets == [0, 1, 1, 2])
        #expect(graph.targets == [0, 1])
    }

    @Test("CSR-C11 duplicates and self-loops together")
    func duplicateSelfLoops() {
        // Boost keeps all four: rowstart [0,2,4,4], column [1,1,1,1].
        let graph = CompressedSparseRow(vertexCount: 3, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 1),
        ])
        #expect(graph.offsets == [0, 1, 2, 2])
        #expect(graph.targets == [1, 1])
        #expect(graph.edgeCount == 2)
    }

    @Test("CSR-C12 deduplicating keeps self-loops, unlike neo4j's Deduplicated layout and GAP's squish")
    func dedupKeepsSelfLoops() {
        // neo4j's kernel input; neo4j drops 0→0, Grafluent keeps it.
        let rows: [[Int]] = [[1, 1, 0], [4, 2, 3, 2], [], [5, 6, 7]]
        let edges = rows.enumerated().flatMap { source, targets in targets.map { DirectedEdge(from: source, to: $0) } }
        let graph = CompressedSparseRow(vertexCount: 8, edges: edges)
        #expect(graph.offsets == [0, 2, 5, 5, 8, 8, 8, 8, 8])
        #expect(graph.targets == [0, 1, 2, 3, 4, 5, 6, 7])
    }

    @Test("CSR-C13 one input that pins sorting, deduplication and self-loops at once")
    func neo4jLayouts() {
        let graph = CompressedSparseRow(vertexCount: 3, edges: [
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2),
            DirectedEdge(from: 0, to: 0), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 0),
        ])
        #expect(graph.offsets == [0, 3, 4, 5])
        #expect(graph.targets == [0, 1, 2, 1, 0])
        #expect(graph.edgeCount == 5)
    }

    @Test("CSR-C14 / CSR-C15 self-loops", .tags(.selfLoops))
    func selfLoops() {
        let single = CompressedSparseRow(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0)])
        #expect(single.offsets == [0, 1])
        #expect(single.targets == [0])
        #expect(single.contains(edge: DirectedEdge(from: 0, to: 0)))

        // petgraph src/csr.rs csr1.
        let mixed = CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.petgraphCsr1.edges)
        #expect(mixed.offsets == [0, 2, 5, 6])
        #expect(mixed.targets == [0, 2, 0, 1, 2, 2])
    }

    @Test("CSR-F exact arrays for the fixtures whose arrays the reference libraries publish", .tags(.fixture))
    func publishedArrays() {
        let cases: [(DirectedFixture<Int>, offsets: [Int], targets: [Int])] = [
            (.directedPath3, [0, 1, 2, 2], [1, 2]),
            (.completeDirected3, [0, 2, 4, 6], [1, 2, 0, 2, 0, 1]),
            (.networkXFunctionGraph, [0, 3, 6, 6, 6, 6], [1, 2, 3, 0, 1, 2]),
            (.house, [0, 0, 1, 2, 4, 6, 7], [0, 1, 2, 4, 0, 1, 3]),
            (.scc9, [0, 1, 2, 3, 4, 5, 6, 7, 9, 11], [3, 7, 5, 6, 1, 8, 0, 4, 5, 2, 6]),
            (.pathWithChord, [0, 1, 3, 4, 5, 6, 6], [1, 2, 3, 3, 4, 5]),
            (.boostExample, [0, 0, 2, 4, 5, 6, 7], [2, 5, 0, 2, 4, 3, 0]),
            (.petgraphEdgesDirected, [0, 4, 5, 7, 7, 8, 8, 9], [1, 2, 3, 5, 3, 3, 4, 0, 6]),
            (.igraphReverseEdges, [0, 1, 3, 4, 5, 5], [1, 2, 4, 3, 1]),
            (.jgraphtMatrixCSV, [0, 2, 2, 4, 5, 10], [1, 2, 0, 3, 4, 0, 1, 2, 3, 4]),
            (.boost24, [0, 0, 1, 3, 5, 7, 8, 9, 11, 13, 15, 18, 21, 24, 27, 29, 31, 33, 34, 35, 37, 39, 41, 42, 43],
             [2, 5, 10, 0, 10, 0, 5, 14, 3, 11, 17, 1, 17, 1, 11, 8, 15, 19, 4, 15, 19, 4, 8, 19, 4, 8, 15, 12, 22, 6, 22, 6, 12, 20, 9, 18, 23, 13, 23, 13, 18, 21, 16]),
            (.boostCsrUnsorted, [0, 1, 1, 1, 2, 4, 6], [2, 2, 0, 1, 0, 2]),
            (.boostWebGraph, [0, 3, 6, 8, 10, 11, 13], [1, 2, 3, 0, 3, 5, 0, 5, 1, 4, 1, 0, 2]),
            (.petgraphCsr1, [0, 2, 5, 6], [0, 2, 0, 1, 2, 2]),
            (.petgraphCsrFrom, [0, 2, 4, 6, 6, 6], [1, 2, 0, 1, 2, 4]),
            (.petgraphBellmanFord, [0, 2, 6, 7, 7, 8, 9, 10, 11, 11], [1, 2, 0, 1, 2, 3, 3, 5, 7, 7, 8]),
            (.neo4jDirected, [0, 2, 4, 5, 6, 6], [1, 2, 2, 3, 4, 4]),
            (.jgraphtSparseDirected, [0, 1, 5, 6, 7, 8, 9, 9, 11], [1, 0, 4, 5, 6, 4, 4, 5, 6, 6, 7]),
            (.scipyConstructor2, [0, 0, 0, 0, 1, 1, 1], [4]),
        ]
        for (fixture, offsets, targets) in cases {
            let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
            #expect(graph.offsets == offsets, "\(fixture.name)")
            #expect(graph.targets == targets, "\(fixture.name)")
        }
    }

    @Test("CSR-I every fixture satisfies the CSR invariants and matches its fixture data", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func invariants(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let n = fixture.vertexCount
        // I01–I04.
        #expect(graph.offsets.count == n + 1)
        #expect(graph.offsets.first == 0)
        #expect(zip(graph.offsets, graph.offsets.dropFirst()).allSatisfy { $0 <= $1 })
        #expect(graph.offsets.last == graph.targets.count)
        #expect(graph.targets.count == fixture.edgeCount)
        #expect(graph.edgeCount == fixture.edgeCount)
        // I05–I06.
        #expect(graph.targets.allSatisfy { (0 ..< n).contains($0) })
        for v in 0 ..< n {
            let row = Array(graph.targets[graph.offsets[v] ..< graph.offsets[v + 1]])
            #expect(zip(row, row.dropFirst()).allSatisfy { $0 < $1 }, "row \(v) is not strictly ascending")
            #expect(row == fixture.edgeSet.filter { $0.source == v }.map(\.target).sorted(), "row \(v)")
            #expect(graph.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
        }
        // I07.
        #expect(graph.edges.count == fixture.edgeCount)
        #expect(Set(graph.edges) == fixture.edgeSet)
        #expect(graph.vertices.map(graph.outDegree(of:)).reduce(0, +) == graph.edgeCount)
    }

    // MARK: From other representations

    @Test("CSR-C28 / CSR-C31 agrees with AdjacencyList and AdjacencyMatrix built from the same edges", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func agreesWithOtherRepresentations(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let list = AdjacencyList(vertices: 0 ..< fixture.vertexCount, edges: fixture.edges)
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)

        #expect(CompressedSparseRow(vertexCount: list.vertexCount, edges: list.edges) == graph)
        #expect(CompressedSparseRow(vertexCount: matrix.vertexCount, edges: matrix.edges) == graph)
        #expect(AdjacencyList(vertices: graph.vertices, edges: graph.edges) == list)
        #expect(AdjacencyMatrix(vertexCount: graph.vertexCount, edges: graph.edges) == matrix)
        // A matrix lists edges in the same row-major order.
        #expect(Array(graph.edges) == Array(matrix.edges))
        for v in 0 ..< fixture.vertexCount {
            #expect(Array(graph.successors(of: v)) == Array(matrix.successors(of: v)))
            #expect(Array(graph.successors(of: v)) == list.successors(of: v).sorted())
        }
    }

    @Test("CSR-C29 from a dense matrix, row = source")
    func fromDenseMatrix() {
        // scipy constructor1: [[0,4,0],[3,0,0],[0,2,0]], read as a 0/1 matrix.
        let matrix: AdjacencyMatrix = [[0, 1, 0], [1, 0, 0], [0, 1, 0]]
        let graph = CompressedSparseRow(vertexCount: matrix.vertexCount, edges: matrix.edges)
        #expect(graph.offsets == [0, 1, 2, 3])
        #expect(graph.targets == [1, 0, 1])
    }

    @Test("CSR-C33 rebuilding from `edges` gives identical arrays", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func rebuildFromEdges(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let rebuilt = CompressedSparseRow(vertexCount: graph.vertexCount, edges: graph.edges)
        #expect(rebuilt.offsets == graph.offsets)
        #expect(rebuilt.targets == graph.targets)
    }

    @Test("CSR-C35 a single-pass edge sequence is consumed once", arguments: UnderestimatedCount.all)
    func singlePass(_ hint: UnderestimatedCount) {
        let fixture = DirectedFixture<Int>.boost24
        let graph = CompressedSparseRow(vertexCount: 24, edges: MinimalSequence(elements: fixture.edges, underestimatedCount: hint))
        #expect(graph.edgeCount == 43)
        #expect(Set(graph.edges) == fixture.edgeSet)
    }

    // MARK: From raw arrays

    @Test("init(offsets:targets:) accepts canonical arrays and gives the same graph", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func fromValidArrays(_ fixture: DirectedFixture<Int>) throws {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let fromArrays = try CompressedSparseRow(offsets: graph.offsets, targets: graph.targets)
        #expect(fromArrays == graph)
        #expect(fromArrays.vertexCount == fixture.vertexCount)
    }

    @Test("CSR-D10 – D18 init(offsets:targets:) rejects every invariant violation with a specific error")
    func fromInvalidArrays() {
        func error(_ offsets: [Int], _ targets: [Int]) -> CompressedSparseRow.ValidationError? {
            do {
                _ = try CompressedSparseRow(offsets: offsets, targets: targets)
                return nil
            } catch {
                return error
            }
        }
        #expect(error([], []) == .emptyOffsets)
        #expect(error([1, 1], [0]) == .firstOffsetNotZero)
        #expect(error([0, 2, 1, 3], [1, 2, 0]) == .decreasingOffsets(vertex: 1))
        #expect(error([0, 1, 2], [1]) == .lastOffsetMismatch(lastOffset: 2, targetCount: 1))
        #expect(error([0, 1], [0, 0]) == .lastOffsetMismatch(lastOffset: 1, targetCount: 2))
        #expect(error([0, 1, 1], [2]) == .targetOutOfRange(edgeIndex: 0))
        #expect(error([0, 1], [-1]) == .targetOutOfRange(edgeIndex: 0))
        #expect(error([0, 2, 2], [1, 0]) == .unsortedRow(vertex: 0))
        #expect(error([0, 2, 2], [1, 1]) == .duplicateEdge(vertex: 0))
        #expect(error([0, 1, 9_223_372_036_854_775_807], [0]) == .lastOffsetMismatch(lastOffset: 9_223_372_036_854_775_807, targetCount: 1))
        #expect(error([0, 0, 2, 3], [0, 2, 1]) == nil)
    }
}

@Suite("CompressedSparseRow construction inputs and storage")
struct CompressedSparseRowConstructionInputTests {
    @Test("CSR-C35 a graph built from heavily repeated edges keeps no more storage than its edges need")
    func repeatsDoNotRetainCapacity() {
        // 100 distinct edges, each given 1000 times, interleaved so the input is not canonical.
        var input: [DirectedEdge<Int>] = []
        for _ in 0 ..< 1000 {
            for k in 0 ..< 100 { input.append(DirectedEdge(from: (k * 37) % 100, to: k)) }
        }
        let graph = CompressedSparseRow(vertexCount: 100, edges: input)
        #expect(graph.edgeCount == 100)
        #expect(graph.targets.capacity < 2 * graph.edgeCount + 16)

        // Sorted input with a repeat at the very end takes the general path, too.
        var sorted = (0 ..< 1000).map { DirectedEdge(from: $0 / 10, to: $0 % 10) }
        sorted.append(DirectedEdge(from: 99, to: 9))
        let tail = CompressedSparseRow(vertexCount: 100, edges: sorted)
        #expect(tail.edgeCount == 1000)
        #expect(tail.targets == (0 ..< 1000).map { $0 % 10 })
    }

    @Test("CSR-C36 parallel source and target arrays build the same graph as their edges", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func parallelArrays(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, sources: fixture.edges.map(\.source), targets: fixture.edges.map(\.target))
        #expect(graph == CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges))
    }

    @Test("CSR-C37 a sequence that can be read only once builds the same graph as an array", arguments: UnderestimatedCount.all)
    func singlePassSequence(_ underestimatedCount: UnderestimatedCount) {
        let edges = DirectedFixture<Int>.boost24.edges.reversed()
        let graph = CompressedSparseRow(vertexCount: 24, edges: MinimalSequence(elements: edges, underestimatedCount: underestimatedCount))
        #expect(graph == CompressedSparseRow(vertexCount: 24, edges: Array(edges)))
        #expect(graph.edgeCount == 43)
    }

    @Test("CSR-C38 a lazy collection of edges is read in place")
    func lazyCollection() {
        let pairs = [(2, 0), (0, 1), (1, 2), (0, 1), (2, 2)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: pairs.lazy.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.offsets == [0, 1, 2, 4])
        #expect(graph.targets == [1, 2, 0, 2])
    }

    @Test("CSR-C39 an adjacency matrix's or list's edges build the same graph")
    func fromOtherEdges() {
        let fixture = DirectedFixture<Int>.boost24
        let list = AdjacencyList(vertices: 0 ..< 24, edges: fixture.edges)
        let matrix = AdjacencyMatrix(vertexCount: 24, edges: fixture.edges)
        let expected = CompressedSparseRow(vertexCount: 24, edges: fixture.edges)
        #expect(CompressedSparseRow(vertexCount: 24, edges: list.edges) == expected)
        #expect(CompressedSparseRow(vertexCount: 24, edges: matrix.edges) == expected)
    }
}
