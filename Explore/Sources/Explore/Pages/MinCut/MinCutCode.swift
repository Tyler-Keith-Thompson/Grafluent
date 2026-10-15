// snippet: mincut-imports
import AdjacencyListModule
import Flows
import GraphProtocols
// snippet end

// The network of the minimum cut page and the cuts it asks for. The marked regions are its code
// panel.

/// The offices joined by `cables`, the cheapest cut of all, and Gomory and Hu's tree with the
/// minimum cut each of its edges stands for.
func officeCuts(_ cables: [UndirectedEdge<String>: Int])
    -> (offices: UndirectedAdjacencyList<String>, cheapest: Cut<DirectedView<UndirectedAdjacencyList<String>>, Int>,
        tree: [(pair: UndirectedEdge<String>, cut: Cut<DirectedView<UndirectedAdjacencyList<String>>, Int>)]) {
    // snippet: mincut-network
    let offices = UndirectedAdjacencyList<String> {
        for link in cables.keys.sorted() { link }
    }
    // snippet end
    // snippet: mincut-global
    let cheapest = offices.minimumCut { cables[offices.edges[$0]]! }!
    let fewest = cheapest.value                  // →
    let cutOff = cheapest.sinkSide               // →
    // snippet end
    _ = (fewest, cutOff)
    // snippet: mincut-tree
    let gomoryHu = offices.gomoryHuTree { cables[offices.edges[$0]]! }!
    let pairs = Array(gomoryHu.tree.edges)                                   // →
    let cuts = pairs.map { gomoryHu.minimumCut(between: $0.u, and: $0.v) }
    let values = cuts.map(\.value)                                           // →
    // snippet end
    _ = values
    return (offices, cheapest, Array(zip(pairs, cuts)).map { ($0.0, $0.1) })
}
