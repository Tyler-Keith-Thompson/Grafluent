// snippet: isomorphism-imports
import AdjacencyListModule
import GraphProtocols
import IsomorphismModule
// snippet end

// The pairs of drawings of the isomorphism page and the questions it asks of them. The marked
// region is its code panel.

/// Whether two graphs hash alike, each vertex's colour after each round of colour refinement,
/// and a mapping between them if there is one.
func compareDrawings(_ firstEdges: [UndirectedEdge<String>], _ secondEdges: [UndirectedEdge<String>])
    -> (sameHash: Bool, firstColours: [String: [Int]], secondColours: [String: [Int]], mapping: [String: String]?) {
    // snippet: isomorphism-compare
    let first = UndirectedAdjacencyList<String> {
        for edge in firstEdges { edge }
    }
    let second = UndirectedAdjacencyList<String> {
        for edge in secondEdges { edge }
    }
    let sameHash = first.weisfeilerLehmanGraphHash() == second.weisfeilerLehmanGraphHash()  // →
    let firstRounds = first.weisfeilerLehmanSubgraphHashes(iterations: 3)
    let secondRounds = second.weisfeilerLehmanSubgraphHashes(iterations: 3)
    let mapping = first.isomorphism(to: second)                                                // →
    // snippet end
    var a: [String: [Int]] = [:], b: [String: [Int]] = [:]
    for v in first.vertices { a[v] = Array(firstRounds.hashes(of: v)) }
    for v in second.vertices { b[v] = Array(secondRounds.hashes(of: v)) }
    let images = mapping.map { m in Dictionary(uniqueKeysWithValues: first.vertices.map { ($0, m.image(of: $0)) }) }
    return (sameHash, a, b, images)
}
