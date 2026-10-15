// snippet: criticalpath-imports
import AdjacencyListModule
import DirectedAcyclicGraphModule
import GraphProtocols
import Traversal
// snippet end

// The school play of the critical path page and the calls it makes. The marked regions are its
// code panel.

// snippet: criticalpath-project
let days = [
    "Choose play": 2, "Cast actors": 3, "Build set": 6, "Print posters": 2, "Make costumes": 4,
    "Rehearse": 5, "Sell tickets": 4, "Dress rehearsal": 1, "Opening night": 0,
]
let comesBefore = [
    DirectedEdge(from: "Choose play", to: "Cast actors"), DirectedEdge(from: "Choose play", to: "Build set"),
    DirectedEdge(from: "Choose play", to: "Print posters"), DirectedEdge(from: "Cast actors", to: "Make costumes"),
    DirectedEdge(from: "Cast actors", to: "Rehearse"), DirectedEdge(from: "Build set", to: "Dress rehearsal"),
    DirectedEdge(from: "Make costumes", to: "Dress rehearsal"), DirectedEdge(from: "Rehearse", to: "Dress rehearsal"),
    DirectedEdge(from: "Print posters", to: "Sell tickets"), DirectedEdge(from: "Sell tickets", to: "Opening night"),
    DirectedEdge(from: "Dress rehearsal", to: "Opening night"),
]

let play = DirectedAcyclicGraph<AdjacencyList<String>> {
    for step in comesBefore { step }
}!
// snippet end

typealias PlayKahnEvent = KahnEvent<String, DirectedAcyclicGraph<AdjacencyList<String>>.Edges.Index>

/// Every event of Kahn's sort of the play, and its critical path with its length in days.
func playSchedule() -> (events: [PlayKahnEvent], critical: [String], length: Int) {
    // snippet: criticalpath-kahn
    let events = Array(play.lazy.kahn())                             // →
    // snippet end
    // snippet: criticalpath-longest
    let critical = play.longestPath { days[play.edges[$0].source]! }!
    let tasks = critical.vertices                                     // →
    let length = critical.weight { days[play.edges[$0].source]! }    // →
    // snippet end
    return (events, tasks, length)
}
