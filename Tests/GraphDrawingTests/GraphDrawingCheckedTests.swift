// `LayeredDrawing.layer(checked:)` and `bends(checkedEdgeAt:)`: the plain lookup's value for a
// vertex or edge position of the graph, and `VertexNotFound` / `EdgeNotFound` for anything else.
// Also `FruchtermanReingoldLayout`'s initializer without a generator, which draws its start from
// the system's generator: only its shape is checked, as its positions are random.

import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import Multigraphs
import Testing

@Suite("Graph drawing checked lookups")
struct GraphDrawingCheckedTests {
    // 0 → 1 → 2 and 0 → 2: the long edge (position 2) bends once, on layer 1.
    static let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)])

    @Test("layer(checked:) agrees with layer(of:) and throws VertexNotFound off the graph")
    func layer() throws {
        let layered = Self.graph.sugiyamaLayout()
        for v in 0 ..< 3 { #expect(try layered.layer(checked: v) == layered.layer(of: v)) }
        #expect(try layered.layer(checked: 0) == 0)
        #expect(try layered.layer(checked: 2) == 2)
        #expect(throws: VertexNotFound.self) { try layered.layer(checked: 3) }
        #expect(throws: VertexNotFound.self) { try layered.layer(checked: -1) }
    }

    @Test("bends(checkedEdgeAt:) agrees with bends(ofEdgeAt:) and throws EdgeNotFound off the graph")
    func bends() throws {
        let layered = Self.graph.sugiyamaLayout()
        for position in 0 ..< 3 { #expect(try layered.bends(checkedEdgeAt: position) == layered.bends(ofEdgeAt: position)) }
        #expect(try layered.bends(checkedEdgeAt: 2).count == 1)
        #expect(try layered.bends(checkedEdgeAt: 0).isEmpty)
        #expect(throws: EdgeNotFound.self) { try layered.bends(checkedEdgeAt: 3) }
        #expect(throws: EdgeNotFound.self) { try layered.bends(checkedEdgeAt: -1) }
    }

    @Test("FruchtermanReingoldLayout(_:) without a generator draws every vertex at a finite position")
    func systemGeneratorLayout() {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        var layout = FruchtermanReingoldLayout(graph, iterations: 20)
        layout.run()
        let drawing = layout.drawing
        #expect(Array(drawing.vertices) == Array(graph.vertices))
        #expect(drawing.allSatisfy { $0.position.x.isFinite && $0.position.y.isFinite })
    }
}
