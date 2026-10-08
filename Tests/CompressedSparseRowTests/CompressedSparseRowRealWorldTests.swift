// Graphs read from other projects' data files: realistic duplicate density, self-loops and degree
// skew, which the hand-written fixtures lack. Case IDs (CSR-Cnn, CSR-Gnn, CSR-Tnn) refer to the
// catalog; see README.md. Expected values were computed from the files by a script.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("CompressedSparseRow on real data")
struct CompressedSparseRowRealWorldTests {
    @Test("CSR-C16 GAP 4.el: 256 lines collapse to 58 edges, keeping 5 self-loops")
    func gap4() {
        let fixture = DirectedFixture<Int>.gap4
        #expect(fixture.edges.count == 256)
        let graph = CompressedSparseRow(vertexCount: 14, edges: fixture.edges)
        #expect(graph.vertexCount == 14)
        #expect(graph.edgeCount == 58)
        // GAP's own squish reports 53 edges: it also drops the self-loops.
        #expect(graph.edges.filter(\.isSelfLoop).map(\.source) == [0, 7, 8, 9, 13])
        #expect(Set(graph.edges) == fixture.edgeSet)
    }

    @Test("CSR-G02 Graph500 scale 8: 4096 packed edges are 2171 distinct, 19 of them self-loops")
    func graph500() {
        let fixture = DirectedFixture<Int>.graph500Scale8
        #expect(fixture.edges.count == 4096)
        let graph = CompressedSparseRow(vertexCount: 256, edges: fixture.edges)
        #expect(graph.edgeCount == 2171)
        #expect(graph.edges.filter(\.isSelfLoop).count == 19)
        #expect(Array(graph.successors(of: 0)) == [37, 157])
        #expect(graph.vertices.map { graph.outDegree(of: $0) }.max() == 168)
        let inDegrees = graph.inDegrees
        #expect(graph.vertices.filter { graph.outDegree(of: $0) == 0 && inDegrees[$0] == 0 }.count == 15)
    }

    @Test("CSR-T08 Graph500 scale 8: in-edges repeated in the file appear once in the transpose")
    func graph500Transpose() {
        let graph = CompressedSparseRow(vertexCount: 256, edges: DirectedFixture<Int>.graph500Scale8.edges)
        // neo4j's sorted layout keeps the repeats: [12, 26, 50, 50, 52, 82, 82, 82, 106, 109, 172, 186, 250, 250].
        #expect(Array(graph.transposed().successors(of: 0)) == [12, 26, 50, 52, 82, 106, 109, 172, 186, 250])
        #expect(graph.inDegrees[0] == 10)
    }

    @Test("CSR-G03 Ligra rMat: already canonical and symmetric, so its arrays survive and it is its own transpose")
    func ligra() throws {
        let fixture = DirectedFixture<Int>.ligraRMat
        let graph = CompressedSparseRow(vertexCount: 128, edges: fixture.edges)
        #expect(graph.edgeCount == 708)
        #expect(Array(graph.edges) == fixture.edges)
        #expect(Array(graph.successors(of: 0)) == [22, 36, 39, 45, 56, 81, 89, 106])
        #expect(graph.vertices.map { graph.outDegree(of: $0) }.max() == 19)
        #expect(graph.vertices.filter { graph.outDegree(of: $0) == 0 }.count == 3)
        #expect(!graph.edges.contains { $0.isSelfLoop })
        #expect(graph.transposed() == graph)
        #expect(try CompressedSparseRow(offsets: graph.offsets, targets: graph.targets) == graph)
    }

    @Test("CSR-G08 real data agrees with the fixture's degrees and with an adjacency list", .tags(.fixture), arguments: DirectedFixture<Int>.realWorld)
    func agreesWithAdjacencyList(_ fixture: DirectedFixture<Int>) {
        let graph = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        var list = AdjacencyList<Int>(vertices: 0 ..< fixture.vertexCount)
        for edge in fixture.edges { list.insert(edge: edge) }
        #expect(graph.edgeCount == fixture.edgeCount)
        #expect(graph.edgeCount == list.edgeCount)
        let inDegrees = graph.inDegrees
        for v in graph.vertices {
            #expect(graph.outDegree(of: v) == fixture.outDegree[v], "outDegree(of: \(v))")
            #expect(inDegrees[v] == fixture.inDegree[v], "inDegree(of: \(v))")
            #expect(Array(graph.successors(of: v)) == list.successors(of: v).sorted())
        }
        // Shuffled input builds the same graph.
        var generator = SeededRandomNumberGenerator(seed: 8)
        #expect(CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges.shuffled(using: &generator)) == graph)
    }

    @Test("CSR-G07 a hub of out-degree 20 000 given in shuffled order: its row is complete and ascending")
    func hub() {
        var generator = SeededRandomNumberGenerator(seed: 7)
        let n = 20_001
        let input = (1 ..< n).map { DirectedEdge(from: 0, to: $0) }.shuffled(using: &generator)
            + (1 ..< n).map { DirectedEdge(from: $0, to: 0) }.shuffled(using: &generator)
        let graph = CompressedSparseRow(vertexCount: n, edges: input)
        #expect(graph.edgeCount == 40_000)
        #expect(Array(graph.successors(of: 0)) == Array(1 ..< n))
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 1)))
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: n - 1)))
        #expect(!graph.contains(edge: DirectedEdge(from: 0, to: 0)))
        #expect(graph.edgeIndex(of: DirectedEdge(from: 0, to: n - 1)) == n - 2)
        #expect(graph.inDegrees[0] == n - 1)
        #expect(graph.transposed().transposed() == graph)
    }
}
