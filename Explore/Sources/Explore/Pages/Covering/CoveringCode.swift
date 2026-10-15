// snippet: covering-imports
import AdjacencyListModule
import Covering
import GraphProtocols
// snippet end

// The town of the covering page and the calls it makes. The marked regions are its code panels.

// snippet: covering-town
let townStreets = [
    UndirectedEdge("Church", "Mill"), UndirectedEdge("Mill", "Park"), UndirectedEdge("Park", "Dock"),
    UndirectedEdge("School", "Square"), UndirectedEdge("Square", "Market"), UndirectedEdge("Market", "Pier"),
    UndirectedEdge("Farm", "Bakery"), UndirectedEdge("Bakery", "Library"), UndirectedEdge("Library", "Station"),
    UndirectedEdge("Church", "School"), UndirectedEdge("School", "Farm"), UndirectedEdge("Mill", "Square"),
    UndirectedEdge("Square", "Bakery"), UndirectedEdge("Park", "Market"), UndirectedEdge("Market", "Library"),
    UndirectedEdge("Dock", "Pier"), UndirectedEdge("Pier", "Station"), UndirectedEdge("Square", "Library"),
    UndirectedEdge("Mill", "School"),
]

let crossroads = UndirectedAdjacencyList<String> {
    for street in townStreets { street }
}
// snippet end

/// What Grafluent says about cameras on the corners in `chosen`.
func cameraAnswers(chosen: [String]) -> (fewest: Int, first: [String], quick: [String], allSeen: Bool) {
    // snippet: covering-cameras
    let fewest = crossroads.minimumVertexCover().count                    // →
    let first = crossroads.lexicographicallyFirstMinimumVertexCover()     // →
    let quick = crossroads.approximateMinimumVertexCover()                // →
    let allSeen = crossroads.isVertexCover(chosen)                        // →
    // snippet end
    return (fewest, first, quick, allSeen)
}

/// What Grafluent says about fire stations on the corners in `chosen`.
func stationAnswers(chosen: [String]) -> (fewest: Int, first: [String], quick: [String], allReached: Bool) {
    // snippet: covering-stations
    let fewest = crossroads.minimumDominatingSet().count                  // →
    let first = crossroads.lexicographicallyFirstMinimumDominatingSet()   // →
    let quick = crossroads.approximateMinimumDominatingSet()              // →
    let allReached = crossroads.isDominatingSet(chosen)                   // →
    // snippet end
    return (fewest, first, quick, allReached)
}
