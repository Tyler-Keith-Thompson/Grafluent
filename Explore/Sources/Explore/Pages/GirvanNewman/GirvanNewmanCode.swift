// snippet: girvannewman-imports
import AdjacencyListModule
import Centrality
import CommunityDetection
import Connectivity
import GraphProtocols
// snippet end

// The crowd of the Girvan–Newman page and the calls it makes. The marked regions are its code
// panel.

// snippet: girvannewman-crowd
let hangOut = [
    UndirectedEdge("Abe", "Bea"), UndirectedEdge("Abe", "Cam"), UndirectedEdge("Bea", "Cam"),
    UndirectedEdge("Bea", "Dan"), UndirectedEdge("Cam", "Dan"),
    UndirectedEdge("Ela", "Fox"), UndirectedEdge("Ela", "Gil"), UndirectedEdge("Fox", "Gil"),
    UndirectedEdge("Fox", "Hal"), UndirectedEdge("Gil", "Hal"),
    UndirectedEdge("Ian", "Jo"), UndirectedEdge("Ian", "Kai"), UndirectedEdge("Jo", "Kai"),
    UndirectedEdge("Jo", "Lu"), UndirectedEdge("Kai", "Lu"),
    UndirectedEdge("Dan", "Ela"), UndirectedEdge("Hal", "Ian"), UndirectedEdge("Cam", "Kai"),
]

let crowd = UndirectedAdjacencyList<String> {
    for pair in hangOut { pair }
}
// snippet end

/// Grafluent's Girvan–Newman partitions of the crowd, coarsest first, and the one of greatest
/// modularity.
func friendGroups() -> (partitions: [[[String]]], best: [[String]]) {
    // snippet: girvannewman-partitions
    let partitions = Array(crowd.girvanNewmanCommunities())                               // →
    let best = partitions.max { crowd.modularity(of: $0) < crowd.modularity(of: $1) }!  // →
    // snippet end
    return (partitions.map { $0.map(Array.init) }, best.map(Array.init))
}

/// The links in the order the method takes them out: recompute every link's betweenness, take
/// out the busiest (the first, on a tie), and repeat until none is left.
func friendRemovals() -> [UndirectedEdge<String>] {
    // snippet: girvannewman-remove
    var left = hangOut
    var removed: [UndirectedEdge<String>] = []
    while !left.isEmpty {
        let now = UndirectedAdjacencyList<String> {
            for person in crowd.vertices { person }
            for pair in left { pair }
        }
        let busy = now.edgeBetweennessCentrality(normalized: false)
        let busiest = now.edges.indices.max { busy.score(ofEdgeAt: $0) < busy.score(ofEdgeAt: $1) }!
        removed.append(left.remove(at: busiest))
    }
    // snippet end
    return removed
}

/// The crowd with the first `k` removals made: every link left with its betweenness, and the
/// groups that are still connected.
func friendsAfter(removing gone: ArraySlice<UndirectedEdge<String>>) -> (scores: [(link: UndirectedEdge<String>, score: Double)], groups: [[String]]) {
    // snippet: girvannewman-after
    let left = UndirectedAdjacencyList<String> {
        for person in crowd.vertices { person }
        for pair in hangOut where !gone.contains(pair) { pair }
    }
    let busy = left.edgeBetweennessCentrality(normalized: false)
    let groups = left.connectedComponents()      // →
    // snippet end
    return (left.edges.indices.map { (left.edges[$0], busy.score(ofEdgeAt: $0)) }, groups.map(Array.init))
}
