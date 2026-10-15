// snippet: semirings-imports
import AdjacencyListModule
import GraphProtocols
import Semirings
import ShortestPaths
// snippet end

// The network of the semirings page and the five questions it asks of it. The marked regions are
// its code panel.

// snippet: semirings-network
let connections = [
    (edge: DirectedEdge(from: "Server", to: "North"), minutes: 4, megabits: 100, up: 0.99),
    (edge: DirectedEdge(from: "Server", to: "South"), minutes: 2, megabits: 40, up: 0.95),
    (edge: DirectedEdge(from: "North", to: "Mill"), minutes: 3, megabits: 80, up: 0.98),
    (edge: DirectedEdge(from: "South", to: "Mill"), minutes: 2, megabits: 30, up: 0.90),
    (edge: DirectedEdge(from: "North", to: "Bank"), minutes: 7, megabits: 90, up: 0.97),
    (edge: DirectedEdge(from: "South", to: "Bank"), minutes: 6, megabits: 60, up: 0.99),
    (edge: DirectedEdge(from: "Mill", to: "Bank"), minutes: 1, megabits: 50, up: 0.95),
    (edge: DirectedEdge(from: "Mill", to: "Dock"), minutes: 5, megabits: 70, up: 0.90),
    (edge: DirectedEdge(from: "Bank", to: "Dock"), minutes: 2, megabits: 100, up: 0.99),
    (edge: DirectedEdge(from: "Bank", to: "Farm"), minutes: 6, megabits: 20, up: 0.80),
    (edge: DirectedEdge(from: "Dock", to: "Farm"), minutes: 3, megabits: 60, up: 0.97),
]

let network = AdjacencyList<String> {
    for connection in connections { connection.edge }
}
let link = Dictionary(uniqueKeysWithValues: connections.map { ($0.edge, $0) })
// snippet end

/// The best value at every place, the link each best route arrives by, and the value at Farm.
struct SemiringAnswer<S: Semiring> {
    var value: [String: S]
    var via: [String: DirectedEdge<String>] = [:]
    var farm: S?
}

/// Every place's answer from a shortest-path tree.
func semiringAnswer<S: SelectiveSemiring>(_ best: ShortestPathTree<AdjacencyList<String>, S>, farm: S?) -> SemiringAnswer<S> {
    var answer = SemiringAnswer<S>(value: [:], farm: farm)
    for place in network.vertices {
        if let d = best.distance(to: place) { answer.value[place] = d }
        if let e = best.parentEdge(of: place) { answer.via[place] = network.edges[e] }
    }
    return answer
}

func quickestRoutes() -> SemiringAnswer<TropicalSemiring<Int>> {
    // snippet: semirings-quickest
    let best = network.dijkstraShortestPaths(from: "Server") { TropicalSemiring(link[network.edges[$0]]!.minutes) }
    let farm = best.distance(to: "Farm")  // →
    // snippet end
    return semiringAnswer(best, farm: farm)
}

func widestRoutes() -> SemiringAnswer<BottleneckSemiring<Int>> {
    // snippet: semirings-widest
    let best = network.dijkstraShortestPaths(from: "Server") { BottleneckSemiring(link[network.edges[$0]]!.megabits) }
    let farm = best.distance(to: "Farm")  // →
    // snippet end
    return semiringAnswer(best, farm: farm)
}

func mostReliableRoutes() -> SemiringAnswer<ViterbiSemiring<Double>> {
    // snippet: semirings-reliable
    let best = network.dijkstraShortestPaths(from: "Server") { ViterbiSemiring(link[network.edges[$0]]!.up) }
    let farm = best.distance(to: "Farm")  // →
    // snippet end
    return semiringAnswer(best, farm: farm)
}

func reachableRoutes() -> SemiringAnswer<BooleanSemiring> {
    // snippet: semirings-reachable
    let best = network.dijkstraShortestPaths(from: "Server") { _ in BooleanSemiring(true) }
    let farm = best.distance(to: "Farm")  // →
    // snippet end
    return semiringAnswer(best, farm: farm)
}

func routeCounts() -> SemiringAnswer<CountingSemiring<Int>> {
    // snippet: semirings-count
    let best = network.dagShortestDistances(from: "Server") { _ in CountingSemiring(1) }
    let farm = best?.distance(to: "Farm")  // →
    // snippet end
    var answer = SemiringAnswer<CountingSemiring<Int>>(value: [:], farm: farm)
    for place in network.vertices { answer.value[place] = best?.distance(to: place) }
    return answer
}
