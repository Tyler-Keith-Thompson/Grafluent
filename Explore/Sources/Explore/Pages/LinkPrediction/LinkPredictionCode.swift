// snippet: linkprediction-imports
import AdjacencyListModule
import GraphProtocols
import Similarity
// snippet end

// The friends of the link prediction page and the scores it asks for. The marked regions are its
// code panel.

// snippet: linkprediction-friends
let palPairs = [
    UndirectedEdge("Ana", "Ben"), UndirectedEdge("Ana", "Cy"), UndirectedEdge("Ana", "Dee"),
    UndirectedEdge("Ben", "Eli"), UndirectedEdge("Ben", "Fay"), UndirectedEdge("Ben", "Gus"),
    UndirectedEdge("Ben", "Hal"), UndirectedEdge("Cy", "Eli"), UndirectedEdge("Cy", "Ivy"),
    UndirectedEdge("Dee", "Ivy"), UndirectedEdge("Gus", "Hal"),
]

let pals = UndirectedAdjacencyList<String> {
    for pair in palPairs { pair }
}
// snippet end

/// Everyone `person` doesn't know yet, each with the friends they share, the Jaccard coefficient
/// and the Adamic–Adar index.
func friendSuggestions(for person: String) -> [(candidate: String, shared: [String], jaccard: Double, adamicAdar: Double)] {
    // snippet: linkprediction-scores
    let strangers = pals.vertices.filter { $0 != person && !pals.contains(edge: UndirectedEdge(person, $0)) }
    let scores = strangers.map { candidate in
        (candidate,
         pals.jaccardCoefficient(of: person, and: candidate),
         pals.adamicAdarIndex(of: person, and: candidate))
    }
    let best = scores.max { $0.2 < $1.2 }?.0                                            // →
    // snippet end
    _ = best
    let mine = Set(pals.neighbors(of: person))
    return scores.map { s in (s.0, pals.vertices.filter { mine.contains($0) && pals.contains(edge: UndirectedEdge(s.0, $0)) }, s.1, s.2) }
}
