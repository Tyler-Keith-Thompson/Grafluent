// snippet: mincostflow-imports
import AdjacencyListModule
import Flows
import GraphProtocols
// snippet end

// The deliveries of the minimum-cost flow page and the plans it asks for. The marked regions are
// its code panel.

// snippet: mincostflow-roads
let roads: [(road: DirectedEdge<String>, crates: Int, cost: Int)] = [
    (DirectedEdge(from: "Stock", to: "North"), 6, 0),
    (DirectedEdge(from: "Stock", to: "South"), 5, 0),
    (DirectedEdge(from: "North", to: "Ashby"), 4, 3),
    (DirectedEdge(from: "North", to: "Barton"), 3, 4),
    (DirectedEdge(from: "North", to: "Hub"), 3, 1),
    (DirectedEdge(from: "South", to: "Colby"), 2, 5),
    (DirectedEdge(from: "South", to: "Denton"), 3, 2),
    (DirectedEdge(from: "South", to: "Hub"), 3, 1),
    (DirectedEdge(from: "Hub", to: "Ashby"), 3, 1),
    (DirectedEdge(from: "Hub", to: "Barton"), 3, 1),
    (DirectedEdge(from: "Hub", to: "Colby"), 4, 2),
    (DirectedEdge(from: "Hub", to: "Denton"), 2, 3),
]
let demand = ["Ashby": 3, "Barton": 2, "Colby": 4, "Denton": 2]

let deliveries = AdjacencyList<String> {
    for r in roads { r.road }
}
let crates = Dictionary(uniqueKeysWithValues: roads.map { ($0.road, $0.crates) })
let cost = Dictionary(uniqueKeysWithValues: roads.map { ($0.road, $0.cost) })
// snippet end

/// The cheapest plan that supplies the shops in `open`: the crates on each road, by offset in
/// `roads`, its total cost, and the crates shipped.
func deliveryPlan(open: [String]) -> (flows: [Int], total: Int, shipped: Int)? {
    // snippet: mincostflow-plan
    let wanted = open.reduce(0) { $0 + demand[$1]! }
    let plan = deliveries.minimumCostFlow(
        supply: { place in place == "Stock" ? wanted : open.contains(place) ? -demand[place]! : 0 },
        capacity: { crates[deliveries.edges[$0]]! },
        cost: { cost[deliveries.edges[$0]]! })
    let total = plan?.cost      // →
    let shipped = plan?.value   // →
    // snippet end
    guard let plan, let total, let shipped else { return nil }
    let position = Dictionary(uniqueKeysWithValues: deliveries.edges.indices.map { (deliveries.edges[$0], $0) })
    return (roads.map { plan.flow(ofEdgeAt: position[$0.road]!) }, total, shipped)
}
