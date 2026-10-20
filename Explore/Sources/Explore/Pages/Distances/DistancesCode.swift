// snippet: distances-imports
import AdjacencyListModule
import Distances
import GraphProtocols
import ShortestPaths
import Walks
// snippet end

// The villages and the calls the distances page makes. The marked regions are its code panels.

// snippet: distances-villages
let lanes = [
    UndirectedEdge("Ash", "Birch"), UndirectedEdge("Birch", "Cedar"), UndirectedEdge("Cedar", "Dale"),
    UndirectedEdge("Dale", "Elm"), UndirectedEdge("Elm", "Fir"), UndirectedEdge("Birch", "Glen"),
    UndirectedEdge("Glen", "Dale"), UndirectedEdge("Glen", "Holt"), UndirectedEdge("Holt", "Elm"),
    UndirectedEdge("Holt", "Ivy"), UndirectedEdge("Ivy", "Fir"), UndirectedEdge("Cedar", "Glen"),
]

let drivingMinutes: [UndirectedEdge<String>: Int] = [
    UndirectedEdge("Ash", "Birch"): 12, UndirectedEdge("Birch", "Cedar"): 7, UndirectedEdge("Cedar", "Dale"): 9,
    UndirectedEdge("Dale", "Elm"): 6, UndirectedEdge("Elm", "Fir"): 14, UndirectedEdge("Birch", "Glen"): 5,
    UndirectedEdge("Glen", "Dale"): 11, UndirectedEdge("Glen", "Holt"): 8, UndirectedEdge("Holt", "Elm"): 4,
    UndirectedEdge("Holt", "Ivy"): 6, UndirectedEdge("Ivy", "Fir"): 5, UndirectedEdge("Cedar", "Glen"): 3,
]

let county = UndirectedAdjacencyList<String> {
    for lane in lanes { lane }
}
// snippet end

/// Every village's eccentricity in hops, and the measures that follow.
func countyHops() -> (eccentricity: [Int?], radius: Int?, diameter: Int?, center: [String], periphery: [String]) {
    // snippet: distances-hops
    let hops = county.eccentricities()
    let radius = hops.radius          // →
    let diameter = hops.diameter      // →
    let center = hops.center          // →
    let periphery = hops.periphery    // →
    // snippet end
    return (county.vertices.map { hops.eccentricity(of: $0) }, radius, diameter, center, periphery)
}

/// The same by driving time.
func countyMinutes() -> (eccentricity: [Int?], radius: Int?, diameter: Int?, center: [String], periphery: [String]) {
    // snippet: distances-minutes
    let times = county.eccentricities { drivingMinutes[county.edges[$0]]! }
    let radius = times.radius         // →
    let diameter = times.diameter     // →
    let center = times.center         // →
    let periphery = times.periphery   // →
    // snippet end
    return (county.vertices.map { times.eccentricity(of: $0) }, radius, diameter, center, periphery)
}

/// The longest shortest drive in the county.
func countyDiameterPath() -> [String] {
    // snippet: distances-path
    let longest = county.diameterPath { drivingMinutes[county.edges[$0]]! }
    let stops = longest.map { Array($0.path.vertices) }  // →
    // snippet end
    return stops ?? []
}

/// The countyFarthest village from `start` and the way there, in hops or drivingMinutes.
func countyFarthest(from start: String, byMinutes: Bool) -> (village: String, distance: Int, stops: [String]) {
    let tree = byMinutes ? county.dijkstraShortestPaths(from: start) { drivingMinutes[county.edges[$0]]! } : county.dijkstraShortestPaths(from: start) { _ in 1 }
    var best = (village: start, distance: 0, stops: [start])
    for village in county.vertices {
        if let d = tree.distance(to: village), d > best.distance, let path = tree.path(to: village) {
            best = (village, d, Array(path.vertices))
        }
    }
    return best
}
