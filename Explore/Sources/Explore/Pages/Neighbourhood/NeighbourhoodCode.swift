// snippet: neighbourhood-imports
import AdjacencyListModule
import GraphOperations
import GraphProtocols
// snippet end

// The knowledge graph and the calls the neighbourhood page makes. The marked regions are its code
// panels.

// snippet: neighbourhood-facts
let mentions = [
    UndirectedEdge("Ada Lovelace", "Analytical Engine"), UndirectedEdge("Ada Lovelace", "Charles Babbage"),
    UndirectedEdge("Charles Babbage", "Analytical Engine"), UndirectedEdge("Charles Babbage", "Difference Engine"),
    UndirectedEdge("Ada Lovelace", "Lord Byron"), UndirectedEdge("Lord Byron", "Poetry"), UndirectedEdge("Lord Byron", "Greece"),
    UndirectedEdge("Analytical Engine", "Punched cards"), UndirectedEdge("Punched cards", "Jacquard loom"),
    UndirectedEdge("Jacquard loom", "Weaving"), UndirectedEdge("Analytical Engine", "Programming"),
    UndirectedEdge("Programming", "Alan Turing"), UndirectedEdge("Alan Turing", "Enigma"), UndirectedEdge("Alan Turing", "Bletchley Park"),
    UndirectedEdge("Difference Engine", "Logarithm tables"), UndirectedEdge("Logarithm tables", "Navigation"),
    UndirectedEdge("Charles Babbage", "Royal Society"), UndirectedEdge("Royal Society", "Isaac Newton"),
]

let facts = UndirectedAdjacencyList<String> {
    for mention in mentions { mention }
}
// snippet end

/// Everything within `hops` of the seeds.
func factsNearby(_ seeds: [String], hops: Int) -> [String] {
    // snippet: neighbourhood-hops
    let nearby = facts.egoGraphView(of: seeds, radius: hops)
    let entities = Array(nearby.vertices)   // →
    let links = nearby.edgeCount            // →
    // snippet end
    _ = links
    return entities
}

/// The same, cut to a budget: the best-connected entities first when a ring overflows.
func factsNearby(_ seeds: [String], hops: Int, budget: Int) -> [String] {
    // snippet: neighbourhood-budget
    let nearby = facts.egoGraphView(of: seeds, radius: hops, maximumVertexCount: budget) { facts.degree(of: $0) }
    let entities = Array(nearby.vertices)   // →
    // snippet end
    return entities
}
