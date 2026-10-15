// snippet: chordal-imports
import AdjacencyListModule
import Cliques
import GraphProtocols
import Traversal
// snippet end

// The friends of the chordal page and the calls it makes. The marked regions are its code panels.

// snippet: chordal-friends
let acquaintances = [
    UndirectedEdge("Ana", "Ben"), UndirectedEdge("Ben", "Cy"), UndirectedEdge("Cy", "Dee"),
    UndirectedEdge("Dee", "Eli"), UndirectedEdge("Eli", "Fay"), UndirectedEdge("Fay", "Ana"),
    UndirectedEdge("Ana", "Cy"), UndirectedEdge("Ana", "Dee"), UndirectedEdge("Ana", "Eli"),
    UndirectedEdge("Cy", "Gus"), UndirectedEdge("Dee", "Gus"),
    UndirectedEdge("Eli", "Hal"), UndirectedEdge("Fay", "Hal"),
]
// snippet end

/// The friends, without the friendships in `removed`.
func circleOfFriends(removing removed: [UndirectedEdge<String>]) -> UndirectedAdjacencyList<String> {
    // snippet: chordal-graph
    let friends = UndirectedAdjacencyList<String> {
        for pair in acquaintances where !removed.contains(pair) { pair }
    }
    // snippet end
    return friends
}

/// Whether `friends` is chordal, a perfect elimination ordering, and a hole.
func chordalAnswers(_ friends: UndirectedAdjacencyList<String>) -> (chordal: Bool, ordering: [String]?, hole: [String]?) {
    // snippet: chordal-test
    let chordal = friends.isChordal                         // →
    let ordering = friends.perfectEliminationOrdering()     // →
    let hole = friends.findHole()?.vertices                 // →
    // snippet end
    return (chordal, ordering, hole)
}

/// The maximum cardinality search order and the LexBFS order of `friends`.
func chordalOrders(_ friends: UndirectedAdjacencyList<String>) -> (mcs: [String], lexBFS: [String]) {
    // snippet: chordal-orders
    let mcs = friends.maximumCardinalitySearch()           // →
    let lexBFS = friends.lexicographicBreadthFirstSearch()  // →
    // snippet end
    return (mcs, lexBFS)
}
