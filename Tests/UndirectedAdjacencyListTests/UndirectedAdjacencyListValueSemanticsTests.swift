// Value semantics: every kind of mutation leaves an existing copy, and views taken before the
// mutation, unchanged. Case IDs (UG-Rnn) refer to the protocol catalog; see
// Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("UndirectedAdjacencyList value semantics", .tags(.copyOnWrite))
struct UndirectedAdjacencyListValueSemanticsTests {
    @Test("UG-R17 inserting an edge into a copy leaves the original unchanged")
    func insertEdgeIntoCopy() {
        let a = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.house.edges)
        var b = a
        b.insert(edge: UndirectedEdge(5, 6))
        #expect(a.edgeCount == 6)
        #expect(a.vertexCount == 5)
        #expect(!a.contains(5))
        #expect(!a.contains(edge: UndirectedEdge(5, 6)))
        #expect(b.edgeCount == 7)
        #expect(a == UndirectedAdjacencyList(edges: UndirectedFixture<Int>.house.edges))
    }

    @Test("UG-R17 every kind of mutation leaves the original unchanged", arguments: 0 ..< 7)
    func everyMutation(_ kind: Int) {
        let original = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.k3WithLoop.edges)
        let snapshot = Set(original.edges)
        let neighbors = original.neighbors(of: 0)
        let edges = original.edges
        var copy = original
        switch kind {
        case 0: copy.insert(9)
        case 1: copy.insert(edge: UndirectedEdge(1, 1))
        case 2: copy.remove(0)
        case 3: copy.remove(edge: UndirectedEdge(0, 0))
        case 4: copy.removeAll()
        case 5: copy.removeAllEdges()
        default: copy.reserveCapacity(vertexCount: 100, edgeCount: 100)
        }
        #expect(Set(original.edges) == snapshot)
        #expect(original.edgeCount == 4)
        #expect(original.degree(of: 0) == 4)
        // Views taken before the mutation are values too.
        #expect(neighbors.sorted() == [0, 0, 1, 2])
        #expect(Set(edges) == snapshot)
        #expect(edges.count == 4)
    }
}
