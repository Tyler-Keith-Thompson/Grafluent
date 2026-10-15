// Edge colouring at either `Int` width: the slot table packs a base and a mask in 64 bits, with an
// all-ones mask marking a vertex's colours as a row. Where `Int` is 32 bits (arm64_32, wasm32)
// that mask is not an `Int`, and the table's size bound is not a 32-bit shift.

import AdjacencyListModule
import ColoringModule
import GraphProtocols
import Testing

@Suite("Edge colouring at either Int width")
struct EdgeColoringIntWidthTests {
    @Test("A wheel of 20 spokes: the hub's colours in a row, each rim vertex's in a probed table; Δ or Δ + 1 colours")
    func wheelRowsAndTables() {
        var edges = (1 ... 20).map { UndirectedEdge(0, $0) }
        edges += (1 ... 20).map { UndirectedEdge($0, $0 % 20 + 1) }
        let graph = UndirectedAdjacencyList(vertices: 0 ... 20, edges: edges)
        let coloring = graph.edgeColoring()
        #expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })
        #expect(coloring.colorCount == 20 || coloring.colorCount == 21)
        #expect(coloring.colorClasses.map(\.count).reduce(0, +) == 40)
    }
}
