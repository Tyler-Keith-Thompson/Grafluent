// Where loops and parallel copies go in a clockwise order when the first incident edge is not the
// first copy of its pair in that order: the copies stay side by side (a face of length 2 between
// them) and the loop's two ends sit together just before the group. See README.md.

import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("Planarity: loops and parallel copies in a clockwise order")
struct PlanarityLayoutTests {
    @Test("A loop at the far end of a doubled edge goes before the copies, not between them")
    func loopBesideLaterCopy() throws {
        // At vertex 1, the copies 0 and 1 of the pair {0, 1} are in descending order (1 is the
        // greater end), so the first incident edge, 0, is the second of its group.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        #expect(Array(graph.incidentEdges(of: 1)).first == 0)
        let embedding = try #require(graph.planarEmbedding())
        #expect(Array(embedding.clockwiseIncidentEdges(of: 1)) == [0, 3, 2, 2, 1])
        #expect(Array(embedding.clockwiseIncidentEdges(of: 0)) == [0, 1])
        // m − n + 2 = 4 − 3 + 2: the loop's face, the face between the copies, and one more.
        #expect(embedding.faceCount == 3)
        #expect(embedding.faces.map(\.length).sorted() == [1, 2, 5])
    }
}
