// snippet: topo-imports
import AdjacencyListModule
import GraphProtocols
import Traversal
// snippet end

/// What the topological-sort page computes from the steps and their dependencies.
struct BuildPlan {
    var events: [DepthFirstSearchEvent<String>]
    var order: [String]?
    var waves: [[String]]?
    var cycle: [String]?
}

func plan(clothes: [String], rules: [(String, String)]) -> BuildPlan {
    // snippet: topo-plan
    let wardrobe = AdjacencyList<String> {
        for item in clothes { item }
        for (first, then) in rules { DirectedEdge(from: first, to: then) }
    }
    let events = Array(wardrobe.depthFirstSearch())     // →
    let order = wardrobe.topologicalSort()              // →
    let waves = wardrobe.topologicalGenerations()          // →
    let cycle = wardrobe.findCycle().map(Array.init)       // →
    // snippet end
    return BuildPlan(events: events, order: order, waves: waves, cycle: cycle)
}
