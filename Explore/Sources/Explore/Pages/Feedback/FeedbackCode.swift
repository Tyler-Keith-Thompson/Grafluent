// snippet: feedback-imports
import AdjacencyListModule
import Cycles
import GraphProtocols
import Traversal
// snippet end

// The packages and the calls the feedback page makes. The marked regions are its code panels.

// snippet: feedback-packages
/// Nine packages and who depends on whom: an arrow from a package to one it imports.
let packages = ["App", "Test", "UI", "Auth", "Net", "Core", "Log", "DB", "Cache"]
let dependsOn: [(String, String)] = [
    ("App", "UI"), ("App", "Auth"), ("App", "Test"), ("Test", "App"), ("UI", "Core"), ("UI", "Net"), ("Net", "Core"),
    ("Core", "Log"), ("Log", "Core"), ("Log", "Net"), ("Auth", "DB"), ("DB", "Cache"), ("Cache", "Auth"), ("Cache", "Core"),
]
let dependencies = AdjacencyList<String> {
    for package in packages { package }
    for (from, to) in dependsOn { DirectedEdge(from: from, to: to) }
}
// snippet end

/// The loops, the fewest arrows and packages that break them all, and the heuristic's arrows.
func cutPlan() -> (loops: Int, cuts: [Int], cheap: [Int], culprits: [String]) {
    // snippet: feedback-plan
    let loops = Array(dependencies.simpleCycles()).count          // →
    let cuts = dependencies.minimumFeedbackArcSet()               // →
    let cheap = dependencies.feedbackArcSet()                     // →
    let culprits = dependencies.minimumFeedbackVertexSet()        // →
    // snippet end
    return (loops, cuts, cheap, culprits)
}

/// The packages without the first `count` cut arrows: how many loops are left, and a build order
/// once there are none.
func afterCuts(_ cuts: [Int], count: Int) -> (loops: Int, order: [String]?) {
    // snippet: feedback-after
    let removed = Set(cuts.prefix(count))
    let trimmed = AdjacencyList<String> {
        for package in packages { package }
        for position in dependencies.edges.indices where !removed.contains(position) { dependencies.edges[position] }
    }
    let loops = Array(trimmed.simpleCycles()).count   // →
    let order = trimmed.topologicalSort()             // →
    // snippet end
    return (loops, order)
}
