// The generation (GraphProtocols' `GraphGeneration`): the graph is immutable, so its initializer
// stamps one generation and nothing advances it. Copies share it; another graph built from the
// same closure has its own. It has no attached maps: its edge positions have no dense offset. See
// README.md.

import GraphProtocols
import ImplicitGraphs
import Testing

@Suite("ImplicitDirectedGraph generation")
struct ImplicitGraphGenerationTests {
    @Test("Stamped once by the initializer; a copy shares it, a graph built again does not")
    func generation() {
        let successors: (Int) -> [Int] = { [($0 + 1) % 4] }
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: successors)
        #expect(graph.generation.isCurrent(for: graph))
        let copy = graph
        #expect(graph.generation.isCurrent(for: copy) && copy.generation.isCurrent(for: graph))
        // Reading it calls nothing and changes nothing.
        _ = Array(graph.edges)
        #expect(copy.generation.isCurrent(for: graph))
        let again = ImplicitDirectedGraph(vertexCount: 4, successors: successors)
        #expect(!graph.generation.isCurrent(for: again) && !again.generation.isCurrent(for: graph))
        let empty = ImplicitDirectedGraph(vertexCount: 0) { _ in [Int]() }
        #expect(empty.generation.isCurrent(for: empty) && !empty.generation.isCurrent(for: graph))
    }
}
