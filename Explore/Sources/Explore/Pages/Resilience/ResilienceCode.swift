// snippet: resilience-imports
import AdjacencyListModule
import Connectivity
import Flows
import GraphProtocols
// snippet end

// The data machineRoom and the calls the resilience page makes. The marked regions are its code panels.

// snippet: resilience-centre
/// Two rings of four racks, each ring fully cross-linked, joined by two patch panels, with a lab
/// and a desk looped through one ring.
let patches = [
    UndirectedEdge("R1", "R2"), UndirectedEdge("R1", "R3"), UndirectedEdge("R1", "R4"), UndirectedEdge("R2", "R3"),
    UndirectedEdge("R2", "R4"), UndirectedEdge("R3", "R4"),
    UndirectedEdge("S1", "S2"), UndirectedEdge("S1", "S3"), UndirectedEdge("S1", "S4"), UndirectedEdge("S2", "S3"),
    UndirectedEdge("S2", "S4"), UndirectedEdge("S3", "S4"),
    UndirectedEdge("R4", "P1"), UndirectedEdge("R3", "P2"), UndirectedEdge("P1", "S1"), UndirectedEdge("P2", "S2"),
    UndirectedEdge("P1", "P2"),
    UndirectedEdge("S4", "Lab"), UndirectedEdge("Lab", "Desk"), UndirectedEdge("Desk", "S3"),
]

let machineRoom = UndirectedAdjacencyList<String> {
    for patch in patches { patch }
}
// snippet end

/// How many must fail to split the machineRoom, and which.
func centreResilience() -> (vertices: Int, edges: Int, cut: [String]) {
    // snippet: resilience-numbers
    let racks = machineRoom.vertexConnectivity()   // →
    let links = machineRoom.edgeConnectivity()     // →
    let weakest = machineRoom.minimumVertexCut()   // →
    // snippet end
    return (racks, links, weakest)
}

/// The k-components: at each k, the groups that survive any k − 1 failures among them.
func centreLevels() -> [[[String]]] {
    // snippet: resilience-levels
    let cohesion = machineRoom.kComponents()
    let levels = (1 ... cohesion.maximumK).map { k in cohesion[k].map(Array.init) }  // →
    // snippet end
    return levels
}
