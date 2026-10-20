// snippet: steiner-imports
import AdjacencyListModule
import GraphProtocols
import SpanningTrees
// snippet end

// The road network and the calls the Steiner tree page makes. The marked regions are its code
// panels.

// snippet: steiner-network
let mains = [
    UndirectedEdge("Plant", "Mill"), UndirectedEdge("Plant", "Ford"), UndirectedEdge("Mill", "Ford"),
    UndirectedEdge("Mill", "Quarry"), UndirectedEdge("Ford", "Cross"), UndirectedEdge("Quarry", "Cross"),
    UndirectedEdge("Cross", "Hill"), UndirectedEdge("Cross", "Marsh"), UndirectedEdge("Hill", "Bay"),
    UndirectedEdge("Marsh", "Bay"), UndirectedEdge("Quarry", "Hill"), UndirectedEdge("Ford", "Marsh"),
]

let cableKilometres: [UndirectedEdge<String>: Int] = [
    UndirectedEdge("Plant", "Mill"): 4, UndirectedEdge("Plant", "Ford"): 7, UndirectedEdge("Mill", "Ford"): 2,
    UndirectedEdge("Mill", "Quarry"): 6, UndirectedEdge("Ford", "Cross"): 3, UndirectedEdge("Quarry", "Cross"): 5,
    UndirectedEdge("Cross", "Hill"): 4, UndirectedEdge("Cross", "Marsh"): 3, UndirectedEdge("Hill", "Bay"): 5,
    UndirectedEdge("Marsh", "Bay"): 6, UndirectedEdge("Quarry", "Hill"): 8, UndirectedEdge("Ford", "Marsh"): 5,
]

let utility = UndirectedAdjacencyList<String> {
    for main in mains { main }
}
// snippet end

/// The mains that connect the given places, and their length.
func gridSteinerTree(_ places: [String]) -> (edges: [Int], kilometres: Int) {
    // snippet: steiner-tree
    let tree = utility.steinerTree(terminals: places) { cableKilometres[utility.edges[$0]]! }
    let laid = tree?.edges ?? []         // →
    let kilometres = tree?.weight ?? 0   // →
    // snippet end
    return (laid, kilometres)
}

/// The mains that connect every place, for comparison.
func gridSpanningTree() -> (edges: [Int], kilometres: Int) {
    // snippet: steiner-spanning
    let all = utility.kruskalMinimumSpanningTree { cableKilometres[utility.edges[$0]]! }
    let everywhere = all.weight          // →
    // snippet end
    return (all.edges, everywhere)
}
