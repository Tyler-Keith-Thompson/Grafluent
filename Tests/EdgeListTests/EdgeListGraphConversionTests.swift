// An edge list and the DirectedGraph protocol: the list is not a DirectedGraph itself (its
// adjacency queries scan every edge, so a generic traversal over it would be O(n·m)), but it can be
// made from any graph's edges, and graphs can be made from it. Case IDs (DG-Tnn, DG-Cnn) refer to
// the protocol catalog; see Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import EdgeListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("EdgeList and DirectedGraph")
struct EdgeListGraphConversionTests {
    @Test("DG-T08 an edge list is not a DirectedGraph")
    func notADirectedGraph() {
        #expect(!((EdgeList<Int>() as Any) is any DirectedGraph))
    }

    @Test("DG-C05 an edge list from any graph lists its edges in that graph's order", .tags(.fixture), arguments: DirectedFixture<Int>.zeroBased)
    func fromGraph(_ fixture: DirectedFixture<Int>) {
        let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges)
        let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges)
        #expect(Array(EdgeList(list)) == Array(list.edges))
        #expect(Array(EdgeList(matrix)) == Array(matrix.edges))
        #expect(Array(EdgeList(sparse)) == Array(sparse.edges))
        #expect(EdgeList(sparse) == EdgeList(sparse.edges))
    }

    @Test("DG-C15 graphs from an edge list, through their edge initializers")
    func toGraphs() {
        let chord = EdgeList(DirectedFixture<Int>.pathWithChord.edges)
        #expect(AdjacencyList(edges: chord).edgeCount == 6)
        #expect(CompressedSparseRow(vertexCount: 6, edges: chord).edgeCount == 6)
        #expect(AdjacencyMatrix(vertexCount: 6, edges: chord).edgeCount == 6)
    }

    @Test("DG-T06 on AnyHashable vertices, an edge argument means edge membership and a vertex argument vertex membership")
    func anyHashableOverloads() {
        let list = EdgeList<AnyHashable>([DirectedEdge(from: 1, to: 2)])
        #expect(list.contains(DirectedEdge<AnyHashable>(from: 1, to: 2)))
        #expect(list.contains(AnyHashable(1)))
        #expect(!list.contains(AnyHashable(DirectedEdge(from: 1, to: 2))))
    }

    @Test("DG-T07 EdgeList(list) still copies a list, next to the conversion from a graph")
    func copyInitializer() {
        let list = EdgeList(DirectedFixture<Int>.pathWithChord.edges)
        #expect(EdgeList(list) == list)
        #expect(EdgeList(list).count == 7)
    }
}
