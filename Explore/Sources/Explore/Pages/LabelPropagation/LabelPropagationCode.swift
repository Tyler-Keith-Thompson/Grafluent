// snippet: labelpropagation-imports
import AdjacencyListModule
import CommunityDetection
import GraphProtocols
import RandomGraphs
// snippet end

// The playground of the label propagation page and the calls it makes. The marked regions are
// its code panels.

// snippet: labelpropagation-playground
let playmates = [
    UndirectedEdge("Ada", "Ben"), UndirectedEdge("Ada", "Cleo"), UndirectedEdge("Ada", "Dan"),
    UndirectedEdge("Ben", "Cleo"), UndirectedEdge("Ben", "Dan"), UndirectedEdge("Cleo", "Dan"),
    UndirectedEdge("Dan", "Eve"), UndirectedEdge("Eve", "Ada"), UndirectedEdge("Cleo", "Fox"),
    UndirectedEdge("Fox", "Gil"), UndirectedEdge("Fox", "Hana"), UndirectedEdge("Gil", "Hana"),
    UndirectedEdge("Gil", "Iris"), UndirectedEdge("Hana", "Iris"), UndirectedEdge("Iris", "Jude"),
    UndirectedEdge("Hana", "Jude"), UndirectedEdge("Kit", "Lou"), UndirectedEdge("Kit", "Max"),
    UndirectedEdge("Lou", "Max"), UndirectedEdge("Lou", "Nell"), UndirectedEdge("Max", "Nell"),
    UndirectedEdge("Nell", "Oz"), UndirectedEdge("Oz", "Kit"), UndirectedEdge("Max", "Pip"),
    UndirectedEdge("Oz", "Pip"), UndirectedEdge("Eve", "Kit"), UndirectedEdge("Jude", "Lou"),
    UndirectedEdge("Dan", "Gil"),
]

let playground = UndirectedAdjacencyList<String> {
    for pair in playmates { pair }
}
// snippet end

/// The groups each form of label propagation finds, with their modularity: `variant` 0 is the
/// asynchronous sweep in order, 1 the semi-synchronous rounds, 2 shuffled sweeps from `seed`.
func rumourGroups(variant: Int, seed: UInt64) -> (groups: [[String]], score: Double) {
    switch variant {
    case 0:
        // snippet: labelpropagation-async
        let groups = playground.asynchronousLabelPropagationCommunities()  // →
        let score = playground.modularity(of: groups)                       // →
        // snippet end
        return (groups.map(Array.init), score)
    case 1:
        // snippet: labelpropagation-semi
        let groups = playground.labelPropagationCommunities()  // →
        let score = playground.modularity(of: groups)          // →
        // snippet end
        return (groups.map(Array.init), score)
    default:
        // snippet: labelpropagation-shuffled
        var generator = Xoshiro256StarStar(seed: seed)
        let groups = playground.asynchronousLabelPropagationCommunities(using: &generator)  // →
        let score = playground.modularity(of: groups)                                        // →
        // snippet end
        return (groups.map(Array.init), score)
    }
}
