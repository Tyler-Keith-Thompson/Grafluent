// snippet: knowledge-imports
import Centrality
import GraphFormats
import GraphOperations
import GraphProtocols
import Multigraphs
// snippet end

// The claims and the calls the knowledge page makes. The marked regions are its code panels.

// snippet: knowledge-claims
/// Facts pulled out of a few paragraphs as subject, relation, object. The extractor spelled some
/// names more than one way.
let claims: [(subject: String, relation: String, object: String)] = [
    ("Ada Lovelace", "wrote notes on", "Analytical Engine"), ("A. Lovelace", "daughter of", "Lord Byron"),
    ("Lovelace, Ada", "corresponded with", "Charles Babbage"), ("Charles Babbage", "designed", "Analytical Engine"),
    ("Babbage", "designed", "Difference Engine"), ("Analytical Engine", "read", "Punched cards"),
    ("Punched cards", "came from", "Jacquard loom"), ("Lord Byron", "wrote", "Poetry"),
    ("Lord Byron", "died in", "Greece"), ("Difference Engine", "tabulated", "Logarithms"),
    ("C. Babbage", "fellow of", "Royal Society"), ("Royal Society", "once led by", "Isaac Newton"),
    ("Alan Turing", "built on", "Analytical Engine"), ("Alan Turing", "worked at", "Bletchley Park"),
]

/// One spelling per entity: the key that merges duplicates.
func canonicalName(_ name: String) -> String {
    switch name {
    case "A. Lovelace", "Lovelace, Ada": "Ada Lovelace"
    case "Babbage", "C. Babbage": "Charles Babbage"
    default: name
    }
}
// snippet end

/// The graph as extracted, one vertex per spelling, and how many entities merging leaves.
func mergedCount() -> (spellings: Int, entities: Int) {
    // snippet: knowledge-merge
    let spellings = DirectedPseudograph<String> {
        for claim in claims { DirectedEdge(from: claim.subject, to: claim.object) }
    }
    let merged = DirectedPseudograph<Int>.quotient(of: spellings, byKey: canonicalName)
    let entities = merged.vertexCount   // →
    // snippet end
    return (spellings.vertexCount, entities)
}

// snippet: knowledge-graph
/// The knowledge graph on canonical names, each relation kept in an edge map.
let (knowledgeGraph, relationOf): (DirectedPseudograph<String>, EdgeMap<String>) = {
    var graph = DirectedPseudograph<String>()
    let relation = graph.addEdgeMap(default: "")
    for claim in claims {
        _ = graph.insert(canonicalName(claim.subject))
        _ = graph.insert(canonicalName(claim.object))
        let position = graph.insert(edge: DirectedEdge(from: canonicalName(claim.subject), to: canonicalName(claim.object)))
        graph[relation, ofEdgeAt: position] = claim.relation
    }
    return (graph, relation)
}()
// snippet end

/// The entities a question mentions.
let questionSeeds = ["Ada Lovelace", "Analytical Engine"]

/// Every entity ranked from the questionSeeds, the facts within two hops cut to a budget by that rank,
/// and those facts as lines for a prompt.
func retrieveFacts(budget: Int) throws -> (ranks: [String: Double], kept: [String], prompt: String) {
    // snippet: knowledge-retrieve
    let ranks = try knowledgeGraph.pageRank(personalization: { questionSeeds.contains($0) ? 1 : 0 })
    let nearby = knowledgeGraph.egoGraphView(of: questionSeeds, radius: 2, undirected: true, maximumVertexCount: budget) { ranks.score(of: $0) }
    let kept = Array(nearby.vertices)   // →
    var prompt = ""
    try nearby.writeEdgeList(to: &prompt, columns: ["relation"], delimiter: "|") { [("relation", .string(knowledgeGraph[relationOf, ofEdgeAt: $0]))] }
    // snippet end
    return (Dictionary(uniqueKeysWithValues: knowledgeGraph.vertices.map { ($0, ranks.score(of: $0)) }), kept, prompt)
}
