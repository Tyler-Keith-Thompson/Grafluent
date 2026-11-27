// snippet: layout-imports
import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import NamedGraphs
import RandomGraphs
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

/// Every drawing a new layout of family `choice` passes through, from random positions drawn from
/// `seed`, with the temperature after each step.
func startTrajectory(_ choice: Int, seed: UInt64) -> [(drawing: Drawing<Int>, temperature: Double)] {
    // snippet: layout-start
    var generator = Xoshiro256StarStar(seed: seed)
    var layout = FruchtermanReingoldLayout(families[choice].graph, iterations: 200, using: &generator)
    // snippet end
    return trajectory(of: &layout)
}

/// Every drawing `layout` passes through as it runs to the end, with the temperature after each
/// step.
func trajectory(of layout: inout FruchtermanReingoldLayout<LayoutGraph>) -> [(drawing: Drawing<Int>, temperature: Double)] {
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
