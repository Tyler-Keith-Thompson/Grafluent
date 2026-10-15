// snippet: flow-imports
import AdjacencyListModule
import Flows
import GraphProtocols
// snippet end

// The waterworks of the maximum flow page and the calls it makes. The marked regions are its code
// panel.

typealias WaterworksEvent = EdmondsKarpEvent<AdjacencyList<String>.Edges.Index, Int>

/// The waterworks with `pipes`, every event of Edmonds–Karp on it, the most it carries, and the
/// pipes of its minimum cut.
func waterworksFlow(_ pipes: [(pipe: DirectedEdge<String>, capacity: Int)])
    -> (waterworks: AdjacencyList<String>, events: [WaterworksEvent], most: Int, cut: [DirectedEdge<String>]) {
    // snippet: flow-waterworks
    let waterworks = AdjacencyList<String> {
        for p in pipes { p.pipe }
    }
    let capacity = Dictionary(uniqueKeysWithValues: pipes.map { ($0.pipe, $0.capacity) })
    // snippet end
    // snippet: flow-run
    let events = Array(waterworks.lazy.edmondsKarp(from: "Reservoir", to: "Town") { capacity[waterworks.edges[$0]]! })  // →
    let flow = waterworks.edmondsKarpMaximumFlow(from: "Reservoir", to: "Town") { capacity[waterworks.edges[$0]]! }
    let most = flow.value                                                       // →
    let cut = flow.minimumCut.edges.map { waterworks.edges[$0] }                // →
    // snippet end
    return (waterworks, events, most, cut)
}
