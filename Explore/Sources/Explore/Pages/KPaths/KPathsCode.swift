// snippet: kpaths-imports
import AdjacencyListModule
import GraphProtocols
import ShortestPaths
// snippet end

// The town of the k shortest paths page and the routes it asks for. The marked regions are its
// code panel.

// snippet: kpaths-town
let driveMinutes: [UndirectedEdge<String>: Int] = [
    UndirectedEdge("Home", "Mill"): 6,
    UndirectedEdge("Home", "Bridge"): 8,
    UndirectedEdge("Home", "Square"): 14,
    UndirectedEdge("Mill", "Square"): 4,
    UndirectedEdge("Mill", "Museum"): 5,
    UndirectedEdge("Bridge", "Square"): 5,
    UndirectedEdge("Bridge", "Market"): 6,
    UndirectedEdge("Square", "Museum"): 6,
    UndirectedEdge("Square", "Park"): 6,
    UndirectedEdge("Square", "Harbor"): 9,
    UndirectedEdge("Museum", "Harbor"): 5,
    UndirectedEdge("Market", "Park"): 7,
    UndirectedEdge("Harbor", "Park"): 3,
    UndirectedEdge("Harbor", "Stadium"): 6,
    UndirectedEdge("Park", "Stadium"): 5,
]

let crosstown = UndirectedAdjacencyList<String> {
    for road in driveMinutes.keys.sorted() { road }
}
// snippet end

/// The first `count` routes from `start` to `goal`, quickest first: each route's stops, its
/// roads (as positions in `crosstown`) and its minutes.
func alternativeRoutes(from start: String, to goal: String, count: Int) -> [(stops: [String], roads: [Int], minutes: Int)] {
    // snippet: kpaths-routes
    let routes = crosstown.shortestSimplePaths(from: start, to: goal) { driveMinutes[crosstown.edges[$0]]! }
    let firstFew = Array(routes.prefix(count))             // →
    let minutes = firstFew.map(\.distance)                 // →
    let quickest = firstFew.first?.path.vertices ?? []     // →
    // snippet end
    _ = quickest
    return firstFew.map { ($0.path.vertices, $0.path.edges.map(\.position), $0.distance) }
}
