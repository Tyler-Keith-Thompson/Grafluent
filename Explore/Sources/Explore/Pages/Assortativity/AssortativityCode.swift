// snippet: assortativity-imports
import AdjacencyListModule
import Assortativity
import GraphProtocols
// snippet end

// The two networks and the calls the assortativity page makes. The marked regions are its code
// panels.

// snippet: assortativity-networks
/// A newsroom: three editors who talk to each other, each with a reporter who has a junior.
let newsroom = UndirectedAdjacencyList<String> {
    UndirectedEdge("Ed", "Flo"); UndirectedEdge("Flo", "Gil"); UndirectedEdge("Gil", "Ed")
    UndirectedEdge("Ed", "Ana"); UndirectedEdge("Ana", "Ben"); UndirectedEdge("Flo", "Cat")
    UndirectedEdge("Cat", "Dan"); UndirectedEdge("Gil", "Eve"); UndirectedEdge("Eve", "Hal")
}

/// An airline: one hub that every small airport flies to, and two links between small airports.
let airline = UndirectedAdjacencyList<String> {
    UndirectedEdge("Hub", "Ames"); UndirectedEdge("Hub", "Bend"); UndirectedEdge("Hub", "Cody")
    UndirectedEdge("Hub", "Dale"); UndirectedEdge("Hub", "Elko"); UndirectedEdge("Hub", "Fargo")
    UndirectedEdge("Hub", "Gary"); UndirectedEdge("Hub", "Hilo")
    UndirectedEdge("Ames", "Bend"); UndirectedEdge("Cody", "Dale")
}
// snippet end

/// Each person's degree and their neighbours' average degree, and the coefficient, for one network.
func mixing(_ graph: UndirectedAdjacencyList<String>) -> (degree: [Int], neighborDegree: [Double], coefficient: Double?, byDegree: [Int: Double]) {
    // snippet: assortativity-measure
    let r = graph.degreeAssortativityCoefficient()         // →
    let around = graph.averageNeighborDegrees()
    let friendsOfFriends = graph.vertices.map { around.averageNeighborDegree(of: $0) }  // →
    let byDegree = graph.averageDegreeConnectivity()       // →
    // snippet end
    return (graph.vertices.map { graph.degree(of: $0) }, friendsOfFriends, r, byDegree)
}
