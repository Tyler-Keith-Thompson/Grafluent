// snippet: bellmanford-imports
import AdjacencyListModule
import GraphProtocols
import ShortestPaths
// snippet end

// The currency market of the Bellman–Ford page and the search it runs. The marked regions are
// its code panel.

typealias MarketEvent = BellmanFordEvent<String, AdjacencyList<String>.Edges.Index, Int>

/// The market of `quotes`, and every event of Bellman–Ford from dollars over the trades' costs.
func marketSearch(_ quotes: [(trade: DirectedEdge<String>, rate: Double, cost: Int)])
    -> (market: AdjacencyList<String>, events: [MarketEvent], cycle: [String]?) {
    // snippet: bellmanford-market
    let market = AdjacencyList<String> {
        for quote in quotes { quote.trade }
    }
    let cost = Dictionary(uniqueKeysWithValues: quotes.map { ($0.trade, $0.cost) })
    // snippet end
    // snippet: bellmanford-run
    let events = Array(market.lazy.bellmanFord(from: "USD") { cost[market.edges[$0]]! })  // →
    let cycle: [String]? = switch events.last {
    case .negativeCycle(let loop)?: loop.vertices
    default: nil
    }
    let tradeRound = cycle ?? []                                                           // →
    // snippet end
    return (market, events, cycle)
}
