// Isomorphism at either `Int` width: rows are sorted by (neighbour, edge colour) as one key,
// neighbour · span + colour, which passes 2³¹ once the vertex count times the number of edge
// colours does. Where `Int` is 32 bits (arm64_32, wasm32) that key is 64 bits wide.

import AdjacencyListModule
import GraphProtocols
import IsomorphismModule
import Testing

@Suite("Isomorphism at either Int width")
struct IsomorphismIntWidthTests {
    @Test("A path of 46,342 vertices with every edge its own colour: n · colours passes 2³¹")
    func edgeColoredPathPastInt32() {
        let n = 46_342
        let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        // The same path numbered from the other end: edge k joins n − 1 − k and n − 2 − k.
        let reversed = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge(n - 1 - $0, n - 2 - $0) })
        let mapping = path.isomorphism(to: reversed, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { $0 }, otherEdgeColor: { $0 })
        #expect(mapping?.image(of: 0) == n - 1)
        #expect(mapping?.image(of: n - 1) == 0)
        // Two colours swapped in the copy: no colour-preserving isomorphism is left.
        let swapped = path.isIsomorphic(to: reversed, vertexColor: { _ in 0 }, otherVertexColor: { _ in 0 }, edgeColor: { $0 }, otherEdgeColor: { $0 < 2 ? 1 - $0 : $0 })
        #expect(!swapped)
    }
}
