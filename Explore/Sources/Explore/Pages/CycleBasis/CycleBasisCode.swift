// snippet: cyclebasis-imports
import AdjacencyListModule
import Cycles
import GraphProtocols
import Walks
// snippet end

// The commons footpaths and the calls the cycle basis page makes. The marked regions are its code panels.

// snippet: cyclebasis-park
let footpaths = [
    UndirectedEdge("Gate", "Pond"), UndirectedEdge("Pond", "Oak"), UndirectedEdge("Oak", "Gate"),
    UndirectedEdge("Oak", "Kiosk"), UndirectedEdge("Kiosk", "Bridge"), UndirectedEdge("Bridge", "Pond"),
    UndirectedEdge("Kiosk", "Lawn"), UndirectedEdge("Lawn", "Fountain"), UndirectedEdge("Fountain", "Bridge"),
    UndirectedEdge("Lawn", "Shed"), UndirectedEdge("Shed", "Fountain"),
]

let commons = UndirectedAdjacencyList<String> {
    for path in footpaths { path }
}
// snippet end

/// The fundamental cycles of the breadth-first spanning forest.
func parkFundamentalBasis() -> [Cycle<String, Int>] {
    // snippet: cyclebasis-fundamental
    let fundamental = commons.cycleBasis()           // →
    let length = fundamental.reduce(0) { $0 + $1.edges.count }  // →
    // snippet end
    _ = length
    return fundamental
}

/// A minimum cycle basis.
func parkMinimumBasis() -> [Cycle<String, Int>] {
    // snippet: cyclebasis-minimum
    let minimum = commons.minimumCycleBasis()        // →
    let length = minimum.reduce(0) { $0 + $1.edges.count }  // →
    // snippet end
    _ = length
    return minimum
}

/// A minimum-weight cycle basis, with the given path lengths in metres.
func parkWeightedBasis(_ metres: [Int]) -> [Cycle<String, Int>] {
    // snippet: cyclebasis-weighted
    let lightest = commons.minimumCycleBasis(weight: { Double(metres[$0]) })  // →
    // snippet end
    return lightest
}
