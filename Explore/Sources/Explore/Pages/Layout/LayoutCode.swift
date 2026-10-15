// snippet: layout-imports
import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import NamedGraphs
// snippet end

typealias LayoutGraph = UndirectedAdjacencyList<Int>

// snippet: layout-families
let families: [(name: String, graph: UndirectedAdjacencyList<Int>)] = [
    ("Dodecahedron", .dodecahedral()),
    ("Petersen graph", .petersen()),
    ("Cube", .hypercube(dimension: 3)),
    ("Grid", .grid(dimensions: [4, 5])),
    ("Tree", .balancedTree(branchingFactor: 2, height: 3)),
    ("Barbell", .barbell(cliqueVertexCount: 5, pathVertexCount: 3)),
]
// snippet end

/// A new layout of family `choice`, from random positions.
func startLayout(_ choice: Int) -> FruchtermanReingoldLayout<LayoutGraph> {
    // snippet: layout-start
    var layout = FruchtermanReingoldLayout(families[choice].graph, iterations: 200)
    // snippet end
    return layout
}

/// Every drawing `layout` passes through, with the temperature after each step.
func trajectory(of start: FruchtermanReingoldLayout<LayoutGraph>) -> [(drawing: Drawing<Int>, temperature: Double)] {
    var layout = start
    // snippet: layout-step
    var frames = [(drawing: layout.drawing, temperature: layout.temperature)]
    while !layout.isFinished {
        layout.step()
        frames.append((layout.drawing, layout.temperature))
    }
    // snippet end
    return frames
}

/// A layout that starts where `layout` is, except that `vertex` is at `point`.
func drag(_ drawing: Drawing<Int>, choice: Int, vertex: Int, to point: SIMD2<Double>) -> FruchtermanReingoldLayout<LayoutGraph> {
    // snippet: layout-drag
    var positions = drawing.positions
    positions[drawing.vertices.firstIndex(of: vertex)!] = point
    let moved = Drawing(vertices: drawing.vertices, positions: positions)
    let restarted = FruchtermanReingoldLayout(families[choice].graph, initial: moved, iterations: 80)
    // snippet end
    return restarted
}
