// snippet: cliques-imports
import AdjacencyListModule
import Cliques
import GraphProtocols
// snippet end

// The party of the cliques page and the calls it makes. The marked regions are its code panel.

// snippet: cliques-party
let haveMet = [
    UndirectedEdge("Ana", "Ben"), UndirectedEdge("Ana", "Cy"), UndirectedEdge("Ana", "Dee"),
    UndirectedEdge("Ben", "Cy"), UndirectedEdge("Ben", "Dee"), UndirectedEdge("Cy", "Dee"),
    UndirectedEdge("Cy", "Eli"), UndirectedEdge("Dee", "Eli"),
    UndirectedEdge("Eli", "Fay"), UndirectedEdge("Eli", "Gus"), UndirectedEdge("Fay", "Gus"),
    UndirectedEdge("Fay", "Hal"), UndirectedEdge("Gus", "Hal"), UndirectedEdge("Ben", "Hal"),
]

let party = UndirectedAdjacencyList<String> {
    for pair in haveMet { pair }
}
// snippet end

/// Every event of Bron–Kerbosch on the party, the maximal cliques and the largest.
func partyCliques() -> (events: [BronKerboschEvent<String>], cliques: [[String]], largest: [String]) {
    // snippet: cliques-search
    let events = Array(party.bronKerboschEvents())       // →
    let cliques = Array(party.maximalCliques())          // →
    let largest = party.maximumClique()                   // →
    // snippet end
    return (events, cliques, largest)
}
