// GraphProtocols gives every conformer default `checked:` lookups (`contains(_:)`, then the
// trapping spelling). A representation that declares its own must still be the one called on its
// concrete type. `StableDirectedGraph`'s own `vertexIndex(checked:)` traps on a graph with vertex
// holes before it looks the vertex up, where the default would throw `VertexNotFound` for a
// non-vertex, so the two are told apart by whether the process exits.

import GraphProtocols
import StableGraphs
import Testing

@Suite("StableDirectedGraph checked-lookup dispatch")
struct StableGraphCheckedDispatchTests {
    @Test("the concrete type calls its own vertexIndex(checked:), which traps on vertex holes")
    func ownVertexIndexChecked() async {
        await #expect(processExitsWith: .failure) {
            var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2])
            _ = graph.remove(1)
            _ = try? graph.vertexIndex(checked: 7)
        }
    }

    @Test("generic code calls the GraphProtocols default, which throws for a non-vertex instead")
    func genericVertexIndexChecked() {
        func index<G: DirectedGraph<Int>>(_ g: G, _ v: Int) -> Int? { try? g.vertexIndex(checked: v) }
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2])
        _ = graph.remove(1)
        #expect(index(graph, 7) == nil)
    }

    @Test("the concrete type's other checked reads are its own and agree with the trapping ones")
    func ownReads() throws {
        let graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0)])
        let successors: StableDirectedGraph<Int>.Neighbors = try graph.successors(checked: 0)
        #expect(Array(successors) == [1])
        #expect(try graph.degree(checked: 0) == 2)
        #expect(throws: VertexNotFound.self) { try graph.predecessors(checked: 9) }
    }
}
