// snippet: hierarchy-imports
import AdjacencyListModule
import CommunityDetection
import GraphProtocols
import RandomGraphs
// snippet end

// The company and the calls the community hierarchy page makes. The marked regions are its code
// panels.

// snippet: hierarchy-company
/// Three departments of two teams each: teams are tight, departments are linked, the company is thin.
let companyTeams: [[String]] = [
    ["Ada", "Bo", "Cal", "Di"], ["Eve", "Flo", "Gil", "Hu"],
    ["Ira", "Jed", "Kim", "Lou"], ["Mia", "Ned", "Oz", "Pia"],
    ["Quin", "Rae", "Sol", "Tam"], ["Uma", "Vic", "Wen", "Xi"],
]

let company = UndirectedAdjacencyList<String> {
    // Everyone in a team works with everyone in it.
    for team in companyTeams {
        for i in team.indices {
            for j in team.indices where j > i { UndirectedEdge(team[i], team[j]) }
        }
    }
    // Each department's two teams share a few pairs.
    UndirectedEdge("Ada", "Eve"); UndirectedEdge("Cal", "Gil"); UndirectedEdge("Di", "Hu")
    UndirectedEdge("Ira", "Mia"); UndirectedEdge("Kim", "Oz"); UndirectedEdge("Lou", "Pia")
    UndirectedEdge("Quin", "Uma"); UndirectedEdge("Sol", "Wen"); UndirectedEdge("Tam", "Xi")
    // One liaison between each pair of departments.
    UndirectedEdge("Bo", "Jed"); UndirectedEdge("Flo", "Rae"); UndirectedEdge("Ned", "Vic")
}
// snippet end

/// The community hierarchy with the given cap, from a fixed seed.
func companyHierarchy(cap: Int) -> CommunityHierarchy<DirectedView<UndirectedAdjacencyList<String>>> {
    // snippet: hierarchy-leiden
    var generator = Xoshiro256StarStar(seed: 7)
    let tree = company.hierarchicalLeidenCommunities(maximumCommunitySize: cap, using: &generator)
    let levels = tree.levelCount                             // →
    let top = tree.communities(atLevel: 0).map { Array(tree[$0]) }  // →
    let leaves = tree.leaves.map { Array(tree[$0]) }         // →
    let parent = tree.parent(of: tree.community(of: "Ada"))  // →
    // snippet end
    _ = (levels, top, leaves, parent)
    return tree
}
