// snippet: tsp-imports
import AdjacencyListModule
import GraphProtocols
import RandomGraphs
import Tours
import Walks
// snippet end

// The towns of the travelling salesman page and the tours it asks for. The marked regions are
// its code panels.

// snippet: tsp-towns
// Each town and where it is, in km east and south of the map's corner.
let towns: [(name: String, x: Double, y: Double)] = [
    ("Ashby", 10, 22), ("Brook", 32, 6), ("Carlow", 56, 16), ("Dunmore", 82, 5),
    ("Elmsford", 112, 20), ("Fenwick", 94, 46), ("Glenby", 114, 74), ("Harlow", 74, 64),
    ("Ivybridge", 46, 76), ("Kelso", 18, 60), ("Lynton", 52, 42),
]

// Every pair of towns, joined by a straight road of its length in whole km.
let roadList = towns.indices.flatMap { i in towns[(i + 1)...].map { UndirectedEdge(towns[i].name, $0.name) } }
let tourMap = UndirectedAdjacencyList<String> {
    for road in roadList { road }
}
let km = tourMap.edges.map { road in
    let a = towns.first { $0.name == road.u }!, b = towns.first { $0.name == road.v }!
    return Int(((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)).squareRoot().rounded())
}
// snippet end

typealias TownTour = Cycle<String, Int>

/// The nearest-neighbour tour from `start`.
func nearestTour(from start: String) -> TownTour {
    // snippet: tsp-nearest
    let greedy = tourMap.nearestNeighborTour(from: start) { km[$0] }!
    // snippet end
    return greedy
}

/// The tours the page compares, each with its length, starting from `start`'s nearest-neighbour tour.
func tourMenu(from start: String) -> [(name: String, tour: TownTour)] {
    let greedy = nearestTour(from: start)
    // snippet: tsp-two-opt
    let improved = tourMap.twoOptTour(improving: greedy) { km[$0] }!
    // snippet end
    // snippet: tsp-menu
    var generator = Xoshiro256StarStar(seed: 1)
    let annealed = tourMap.simulatedAnnealingTour(improving: greedy, weight: { km[$0] }, using: &generator)!
    let christofides = tourMap.christofidesTour { km[$0] }!
    let shortest = tourMap.shortestTour { km[$0] }!
    // snippet end
    return [("Nearest neighbour", greedy), ("2-opt", improved), ("Simulated annealing", annealed), ("Christofides", christofides), ("Shortest", shortest)]
}

/// The length of `tour` in km.
func tourLength(_ tour: TownTour) -> Int {
    // snippet: tsp-length
    let length = tour.weight { km[$0] }  // →
    // snippet end
    return length
}
