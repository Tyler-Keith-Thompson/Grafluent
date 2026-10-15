// snippet: betweenness-imports
import AdjacencyListModule
import Centrality
import GraphProtocols
import ShortestPaths
// snippet end

// The workplace of the betweenness page and the questions it asks. The marked regions are its code
// panel.

// snippet: betweenness-workplace
let talksTo = [
    UndirectedEdge("Ana", "Ben"), UndirectedEdge("Ana", "Cara"), UndirectedEdge("Ben", "Cara"),
    UndirectedEdge("Ben", "Dev"), UndirectedEdge("Cara", "Dev"), UndirectedEdge("Cara", "Eve"),
    UndirectedEdge("Dev", "Eve"), UndirectedEdge("Eve", "Fay"), UndirectedEdge("Eve", "Gus"),
    UndirectedEdge("Fay", "Gus"), UndirectedEdge("Fay", "Hana"), UndirectedEdge("Gus", "Hana"),
    UndirectedEdge("Gus", "Ivo"), UndirectedEdge("Hana", "Ivo"),
]

let workplace = UndirectedAdjacencyList<String> {
    for pair in talksTo { pair }
}
// snippet end

/// Every shortest path between `a` and `b`: each one's people and its links, as positions in
/// `workplace`.
func shortestPaths(between a: String, and b: String) -> [(people: [String], links: [Int])] {
    // snippet: betweenness-pair
    var routes = workplace.shortestSimplePaths(from: a, to: b).makeIterator()
    let first = routes.next()!
    var shortest = [first.path]
    while let next = routes.next(), next.distance == first.distance {
        shortest.append(next.path)
    }
    // snippet end
    return shortest.map { ($0.vertices, $0.edges.map(\.position)) }
}

/// Grafluent's betweenness of every person and every link, unnormalized, and the busiest link.
func workplaceBetweenness() -> (people: CentralityScores<DirectedView<UndirectedAdjacencyList<String>>>, links: EdgeCentralityScores<Int>, busiest: UndirectedEdge<String>) {
    // snippet: betweenness-scores
    let brokerage = workplace.betweennessCentrality(normalized: false)
    let links = workplace.edgeBetweennessCentrality(normalized: false)
    let eve = brokerage.score(of: "Eve")                                  // →
    let dev = brokerage.score(of: "Dev")                                  // →
    let busiest = workplace.edges.indices.max { links.score(ofEdgeAt: $0) < links.score(ofEdgeAt: $1) }!
    let busiestLink = workplace.edges[busiest]                               // →
    // snippet end
    _ = (eve, dev)
    return (brokerage, links, busiestLink)
}
