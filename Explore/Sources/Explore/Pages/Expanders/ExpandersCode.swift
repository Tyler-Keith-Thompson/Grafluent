// snippet: expanders-imports
import AdjacencyListModule
import Distances
import GraphProtocols
import NamedGraphs
import SpectralGraphTheory
import Traversal
// snippet end

// The three wirings and the calls the expanders page makes. The marked regions are its code panels.

// snippet: expanders-wirings
/// Twenty-nine machines, wired three ways: a ring, a ring where each machine also reaches the one
/// two along, and the chordal cycle, a ring with a chord from each machine to its inverse mod 29.
let machines = 29
let plainRing = UndirectedAdjacencyList<Int>.cycle(vertexCount: machines)
let skipRing = UndirectedAdjacencyList<Int>.circulant(vertexCount: machines, offsets: [1, 2])
let chordRing = UndirectedAdjacencyList<Int>.chordalCycle(prime: machines)
// snippet end

/// A message spreading from machine 0, one hop a step, and the wiring's numbers.
func wiringNumbers(_ graph: UndirectedAdjacencyList<Int>) throws -> (hops: [[Int]], cables: Int, farthest: Int, gap: Double) {
    // snippet: expanders-numbers
    let hops = graph.directedView.breadthFirstLayers(from: 0)   // →
    let cables = graph.edgeCount                                 // →
    let farthest = graph.diameter()!                             // →
    let gap = try graph.fiedlerVector()!.algebraicConnectivity   // →
    // snippet end
    return (hops, cables, farthest, gap)
}
