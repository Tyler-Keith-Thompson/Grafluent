// snippet: cores-imports
import AdjacencyListModule
import Cliques
import GraphProtocols
// snippet end

// The friendship network and the calls the cores page makes. The marked regions are its code
// panels.

// snippet: cores-friends
let ties = [
    UndirectedEdge("Ana", "Ben"), UndirectedEdge("Ana", "Cy"), UndirectedEdge("Ana", "Dee"),
    UndirectedEdge("Ana", "Eli"), UndirectedEdge("Ben", "Cy"), UndirectedEdge("Ben", "Dee"),
    UndirectedEdge("Ben", "Eli"), UndirectedEdge("Cy", "Dee"), UndirectedEdge("Cy", "Eli"),
    UndirectedEdge("Dee", "Eli"), UndirectedEdge("Fay", "Ana"), UndirectedEdge("Fay", "Ben"),
    UndirectedEdge("Fay", "Gus"), UndirectedEdge("Gus", "Ben"), UndirectedEdge("Gus", "Hal"),
    UndirectedEdge("Hal", "Fay"), UndirectedEdge("Hal", "Cy"), UndirectedEdge("Ivy", "Dee"),
    UndirectedEdge("Ivy", "Jo"), UndirectedEdge("Jo", "Eli"), UndirectedEdge("Kai", "Cy"),
    UndirectedEdge("Kai", "Lea"), UndirectedEdge("Lea", "Hal"), UndirectedEdge("Max", "Ivy"),
    UndirectedEdge("Ned", "Kai"), UndirectedEdge("Ola", "Lea"), UndirectedEdge("Pat", "Gus"),
]

let club = UndirectedAdjacencyList<String> {
    for tie in ties { tie }
}
// snippet end

/// The people in the k-core, and the greatest k with anyone in it.
func clubCore(_ k: Int) -> (core: [String], degeneracy: Int) {
    // snippet: cores-core
    let cores = club.coreNumbers()
    let inner = cores.kCore(k)         // →
    let degeneracy = cores.degeneracy  // →
    // snippet end
    return (inner, degeneracy)
}

/// The friendships in the k-truss, by position.
func clubTruss(_ k: Int) -> [Int] {
    // snippet: cores-truss
    let trusses = club.trussNumbers()
    let strong = trusses.kTruss(k)  // →
    // snippet end
    return strong
}

/// Everyone's core number, in `vertices` order.
func clubCoreNumbers() -> [Int] {
    let cores = club.coreNumbers()
    return club.vertices.map { cores.coreNumber(of: $0) }
}

/// The onion layers, outermost first.
func clubLayers() -> [[String]] {
    // snippet: cores-onion
    let onion = club.onionLayers()
    let layers = (1 ... onion.layerCount).map { n in
        club.vertices.filter { onion.layer(of: $0) == n }
    }  // →
    // snippet end
    return layers
}
