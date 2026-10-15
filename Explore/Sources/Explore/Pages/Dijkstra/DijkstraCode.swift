// snippet: dijkstra-imports
import AdjacencyListModule
import GraphProtocols
import ShortestPaths
// snippet end

// The town and the two searches the Dijkstra page runs. The marked regions are its code panel.

// snippet: dijkstra-town
let minutes: [UndirectedEdge<String>: Int] = [
    UndirectedEdge("Home", "Bakery"): 4,
    UndirectedEdge("Home", "Park"): 6,
    UndirectedEdge("Bakery", "Park"): 3,
    UndirectedEdge("Bakery", "School"): 7,
    UndirectedEdge("Park", "Library"): 5,
    UndirectedEdge("School", "Library"): 4,
    UndirectedEdge("School", "Café"): 6,
    UndirectedEdge("Library", "Café"): 3,
    UndirectedEdge("Library", "Station"): 8,
    UndirectedEdge("Café", "Station"): 5,
    UndirectedEdge("Park", "Market"): 6,
    UndirectedEdge("Market", "Station"): 4,
    UndirectedEdge("Library", "Market"): 7,
]

let town = UndirectedAdjacencyList<String> {
    for street in minutes.keys.sorted() { street }
}
// snippet end

typealias TownSearchEvent = DijkstraSearchEvent<String, DirectedView<UndirectedAdjacencyList<String>>.Edges.Index, Int>

/// Every event of Dijkstra's search from `start`, for the timeline.
func townSearch(from start: String) -> [TownSearchEvent] {
    // snippet: dijkstra-search
    let events = Array(town.dijkstraSearch(from: start) { minutes[town.edges[$0]]! })  // →
    // snippet end
    return events
}

/// The quickest walk from `start` to `goal`: its minutes and its stops.
func quickestWalk(from start: String, to goal: String) -> (minutes: Int?, stops: [String]) {
    // snippet: dijkstra-walk
    let walks = town.dijkstraShortestPaths(from: start) { minutes[town.edges[$0]]! }
    let distance = walks.distance(to: goal)           // →
    let stops = walks.path(to: goal).map(Array.init)  // →
    // snippet end
    return (distance, stops ?? [])
}
