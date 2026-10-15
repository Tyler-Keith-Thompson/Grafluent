// snippet: postman-imports
import AdjacencyListModule
import GraphProtocols
import ShortestPaths
import Tours
// snippet end

// The estate the snowplough clears and the calls the postman page makes. The marked regions are
// its code panels.

// snippet: postman-estate
let streets = [
    UndirectedEdge("Depot", "Church"), UndirectedEdge("Depot", "School"),
    UndirectedEdge("Church", "School"), UndirectedEdge("Church", "Park"),
    UndirectedEdge("School", "Market"), UndirectedEdge("Park", "Market"),
    UndirectedEdge("Park", "Bridge"), UndirectedEdge("Market", "Mill"),
    UndirectedEdge("Bridge", "Mill"),
]

let estate = UndirectedAdjacencyList<String> {
    for street in streets { street }
}
// snippet end

typealias EstateTour = PostmanTour<String, Int, Int>

/// The shortest round of every street, with `minutes` the time to drive each, by position.
func ploughTour(minutes: [Int]) -> EstateTour {
    // snippet: postman-tour
    let tour = estate.chinesePostmanTour { minutes[$0] }!
    let total = tour.weight                                    // →
    let twice = tour.duplicatedEdges.map { estate.edges[$0] }  // →
    let route = tour.walk.vertices                             // →
    // snippet end
    _ = (total, twice, route)
    return tour
}

/// The junctions with an odd number of streets, and the quickest time between each pair of them.
func oddJunctions(minutes: [Int]) -> (odd: [String], distance: [[Int]]) {
    // snippet: postman-odd
    let odd = estate.vertices.filter { estate.degree(of: $0) % 2 == 1 }  // →
    let quickest = odd.map { a in estate.dijkstraShortestPaths(from: a) { minutes[$0] } }
    let distance = quickest.map { tree in odd.map { tree.distance(to: $0)! } }  // →
    // snippet end
    return (odd, distance)
}
