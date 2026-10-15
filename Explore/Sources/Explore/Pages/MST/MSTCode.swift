// snippet: mst-imports
import AdjacencyListModule
import GraphProtocols
import SpanningTrees
// snippet end

// The six houses and the two algorithms the minimum-spanning-tree page runs. The marked regions
// are its code panel.

// snippet: mst-houses
let cableCost: [UndirectedEdge<String>: Int] = [
    UndirectedEdge("Ada", "Ben"): 4,
    UndirectedEdge("Ada", "Dev"): 3,
    UndirectedEdge("Ada", "Eli"): 6,
    UndirectedEdge("Ben", "Eli"): 2,
    UndirectedEdge("Ben", "Cleo"): 8,
    UndirectedEdge("Cleo", "Fay"): 1,
    UndirectedEdge("Dev", "Eli"): 5,
    UndirectedEdge("Eli", "Fay"): 7,
    UndirectedEdge("Dev", "Fay"): 9,
]

let houses = UndirectedAdjacencyList<String> {
    for cable in cableCost.keys.sorted() { cable }
}
// snippet end

typealias HouseKruskalEvent = KruskalEvent<String, UndirectedAdjacencyList<String>.Edges.Index, Int>
typealias HousePrimEvent = PrimEvent<String, UndirectedAdjacencyList<String>.Edges.Index, Int>

/// Every event of Kruskal's algorithm on the houses.
func kruskalCabling() -> [HouseKruskalEvent] {
    // snippet: mst-kruskal
    let kruskal = Array(houses.kruskalEvents { cableCost[houses.edges[$0]]! })  // →
    // snippet end
    return kruskal
}

/// Every event of Prim's algorithm on the houses, from `start`.
func primCabling(from start: String) -> [HousePrimEvent] {
    // snippet: mst-prim
    let prim = Array(houses.primEvents(from: start) { cableCost[houses.edges[$0]]! })  // →
    // snippet end
    return prim
}

/// The total cost of each algorithm's network.
func cablingTotals(from start: String) -> (kruskal: Int, prim: Int) {
    // snippet: mst-totals
    let byKruskal = houses.kruskalMinimumSpanningTree { cableCost[houses.edges[$0]]! }.weight              // →
    let byPrim = houses.primMinimumSpanningTree(from: start) { cableCost[houses.edges[$0]]! }.weight  // →
    // snippet end
    return (byKruskal, byPrim)
}
