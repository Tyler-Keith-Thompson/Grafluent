// Equatable and Hashable. Equality means equal vertex sets and equal edge sets, with each edge an
// unordered pair: neither insertion order nor the orientation an edge was written in matters. Case
// IDs (UG-Rnn) refer to the protocol catalog; see Tests/GraphProtocolsTests/README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("UndirectedAdjacencyList equality and hashing", .tags(.conformance))
struct UndirectedAdjacencyListEqualityTests {
    @Test("UG-R16 equality ignores orientation and order, and sees vertices, loops and endpoints")
    func equality() {
        let path = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let reversed = UndirectedAdjacencyList(edges: [UndirectedEdge(2, 1), UndirectedEdge(1, 0)])
        #expect(path == reversed)
        #expect(path.hashValue == reversed.hashValue)
        var withIsolated = path
        withIsolated.insert(3)
        #expect(withIsolated != path)
        var withLoop = path
        withLoop.insert(edge: UndirectedEdge(0, 0))
        #expect(withLoop != path)
        #expect(UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]) != UndirectedAdjacencyList(edges: [UndirectedEdge(0, 2)]))
    }

    @Test("UG-R16 equality and hashing follow the equivalence classes")
    func equivalenceClassLaws() {
        // The house graph, built in different ways, against graphs that differ from it by one thing.
        let edges = UndirectedFixture<Int>.house.edges

        var addedThenRemovedEdge = UndirectedAdjacencyList(edges: edges)
        addedThenRemovedEdge.insert(edge: UndirectedEdge(0, 4))
        addedThenRemovedEdge.remove(edge: UndirectedEdge(4, 0))

        var addedThenRemovedVertex = UndirectedAdjacencyList(edges: edges)
        addedThenRemovedVertex.insert(edge: UndirectedEdge(9, 9))
        addedThenRemovedVertex.insert(edge: UndirectedEdge(1, 9))
        addedThenRemovedVertex.remove(9)

        var clearedAndRebuilt = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.petersen.edges)
        clearedAndRebuilt.removeAll()
        for edge in edges.reversed() { clearedAndRebuilt.insert(edge: UndirectedEdge(edge.v, edge.u)) }

        var withLoop = UndirectedAdjacencyList(edges: edges)
        withLoop.insert(edge: UndirectedEdge(2, 2))

        var missingEdge = UndirectedAdjacencyList(edges: edges)
        missingEdge.remove(edge: UndirectedEdge(3, 2))

        var edgesRemoved = UndirectedAdjacencyList(edges: edges)
        edgesRemoved.removeAllEdges()

        let classes: [[UndirectedAdjacencyList<Int>]] = [
            [
                UndirectedAdjacencyList(edges: edges),
                UndirectedAdjacencyList(edges: edges.map { UndirectedEdge($0.v, $0.u) }),
                UndirectedAdjacencyList(edges: edges + edges),
                UndirectedAdjacencyList(vertices: [4, 3, 2, 1, 0], edges: edges),
                addedThenRemovedEdge, addedThenRemovedVertex, clearedAndRebuilt,
            ],
            [withLoop, UndirectedAdjacencyList(edges: [UndirectedEdge(2, 2)] + edges)],
            [missingEdge],
            [edgesRemoved, UndirectedAdjacencyList(vertices: 0 ..< 5)],
            [UndirectedAdjacencyList(), UndirectedAdjacencyList(vertices: [Int]())],
        ]
        for (i, group) in classes.enumerated() {
            for (j, other) in classes.enumerated() {
                for a in group {
                    for b in other {
                        #expect((a == b) == (i == j), "classes \(i) and \(j)")
                        if i == j { #expect(a.hashValue == b.hashValue, "class \(i)") }
                    }
                }
            }
        }
    }

    @Test("UG-R16 all 64 graphs on three vertices with loops allowed are pairwise distinct", .tags(.exhaustive))
    func everyGraphOnThreeVertices() {
        // The six possible edges on {0, 1, 2}: three loops and three pairs.
        let possible = [UndirectedEdge(0, 0), UndirectedEdge(1, 1), UndirectedEdge(2, 2), UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)]
        var graphs: [UndirectedAdjacencyList<Int>] = []
        for mask in 0 ..< 64 {
            graphs.append(UndirectedAdjacencyList(vertices: 0 ..< 3, edges: possible.indices.filter { mask & (1 << $0) != 0 }.map { possible[$0] }))
        }
        #expect(Set(graphs).count == 64)
        for (i, a) in graphs.enumerated() {
            // The same graph written the other way round, in reverse order.
            let mirrored = UndirectedAdjacencyList(vertices: [2, 1, 0], edges: a.edges.reversed().map { UndirectedEdge($0.v, $0.u) })
            #expect(mirrored == a)
            #expect(mirrored.hashValue == a.hashValue)
            for (j, b) in graphs.enumerated() where j != i { #expect(a != b) }
        }
    }
}
