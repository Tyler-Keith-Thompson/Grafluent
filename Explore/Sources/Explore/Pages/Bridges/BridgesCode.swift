// snippet: bridges-imports
import AdjacencyListModule
import Connectivity
import GraphProtocols
import Traversal
// snippet end

// The village and the calls the bridges page makes. The marked regions are its code panels.

// snippet: bridges-village
let villageRoads = [
    UndirectedEdge("Farm", "Mill"),
    UndirectedEdge("Mill", "Church"),
    UndirectedEdge("Church", "Square"),
    UndirectedEdge("Square", "School"),
    UndirectedEdge("School", "Mill"),
    UndirectedEdge("Square", "Station"),
    UndirectedEdge("Station", "Market"),
    UndirectedEdge("Market", "Harbour"),
    UndirectedEdge("Harbour", "Station"),
    UndirectedEdge("Harbour", "Lighthouse"),
]

let village = UndirectedAdjacencyList<String> {
    for road in villageRoads { road }
}
// snippet end

typealias VillageSearchEvent = EdgeDepthFirstSearchEvent<String, UndirectedAdjacencyList<String>.Edges.Index>

/// Every event of a depth-first search of the village from `start`, each road by its position.
func villageSearch(from start: String) -> [VillageSearchEvent] {
    // snippet: bridges-search
    let events = Array(village.edgeDepthFirstSearch(from: start))  // →
    // snippet end
    return events
}

/// The bridges, as roads, and the articulation points.
func villageWeakSpots() -> (bridges: [UndirectedEdge<String>], cutVertices: [String]) {
    // snippet: bridges-answer
    let bridges = village.bridges().map { village.edges[$0] }  // →
    let cutVertices = village.articulationPoints()               // →
    // snippet end
    return (bridges, cutVertices)
}

/// The pieces of the village with nothing closed.
func villagePieces() -> [[String]] {
    // snippet: bridges-whole
    let pieces = village.connectedComponents()  // →
    // snippet end
    return pieces.map(Array.init)
}

/// The pieces of the village with `road` closed.
func villagePieces(closingRoad road: UndirectedEdge<String>) -> [[String]] {
    // snippet: bridges-close-road
    var closed = village
    closed.remove(edge: road)
    let pieces = closed.connectedComponents()  // →
    // snippet end
    return pieces.map(Array.init)
}

/// The pieces of the village with `place` closed, and every road into it.
func villagePieces(closingPlace place: String) -> [[String]] {
    // snippet: bridges-close-place
    var closed = village
    closed.remove(place)
    let pieces = closed.connectedComponents()  // →
    // snippet end
    return pieces.map(Array.init)
}
