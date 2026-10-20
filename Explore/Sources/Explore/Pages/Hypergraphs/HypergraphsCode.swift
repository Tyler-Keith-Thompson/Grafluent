// snippet: hypergraphs-imports
import Hypergraphs
// snippet end

// The committees and the calls the hypergraphs page makes. The marked regions are its code panels.

// snippet: hypergraphs-committees
let committees: [[String]] = [
    ["Ann", "Bert", "Cleo"],                 // budget
    ["Cleo", "Dev", "Ezra", "Fay"],          // hiring
    ["Ann", "Fay"],                          // audit
    ["Gus", "Hana", "Ivo"],                  // social
    ["Bert", "Dev", "Gus"],                  // safety
    ["Jude"],                                // archive, one person
]

let council = UndirectedIncidenceList(hyperedges: committees)
// snippet end

/// The facts about the council the page reads.
func councilFacts() -> (sizes: [Int], degrees: [Int], neighborsOfCleo: [String], components: [[String]], rank: Int) {
    // snippet: hypergraphs-facts
    let sizes = council.hyperedges.indices.map { council.size(ofHyperedgeAt: $0) }  // →
    let busiest = council.vertices.map { council.degree(of: $0) }                   // →
    let colleagues = council.neighbors(of: "Cleo")                                  // →
    let groups = council.connectedComponents()                                       // →
    let largest = council.rank                                                       // →
    // snippet end
    return (sizes, busiest, colleagues, groups, largest)
}

/// The council as an ordinary graph: two people joined when they sit together.
func councilPairs() -> [(String, String)] {
    // snippet: hypergraphs-expansion
    let acquaintance = council.cliqueExpansion()
    let pairs = acquaintance.edgeCount   // →
    // snippet end
    _ = pairs
    return acquaintance.edges.map { ($0.u, $0.v) }
}
