// snippet: lca-imports
import AdjacencyListModule
import GraphProtocols
import TreeAlgorithms
import Trees
// snippet end

// The family of the lowest common ancestor page and the questions it asks. The marked regions
// are its code panel.

// snippet: lca-family
let childOf: [(child: String, parent: String)] = [
    ("Arthur", "Rose"), ("Beth", "Rose"), ("Clara", "Arthur"), ("David", "Arthur"), ("Ellen", "Beth"),
    ("Finn", "Clara"), ("Gemma", "Clara"), ("Harry", "David"), ("Iris", "Ellen"), ("Jack", "Ellen"),
    ("Kate", "Gemma"), ("Leo", "Iris"),
]

let family = RootedTree(UndirectedAdjacencyList<String> {
    for link in childOf { UndirectedEdge(link.parent, link.child) }
}, root: "Rose")!
// snippet end

/// The climb from `a` and `b` to their lowest common ancestor, one step at a time, and what
/// Grafluent answers directly: the ancestor, and how many parent–child links apart they are.
func familyClimb(_ a: String, _ b: String) -> (climb: [(String, String)], ancestor: String, apart: Int) {
    // snippet: lca-climb
    var (x, y) = (a, b)
    var climb = [(x, y)]
    while x != y {
        let dx = family.depth(of: x), dy = family.depth(of: y)
        if dx >= dy { x = family.parent(of: x)! }
        if dy >= dx { y = family.parent(of: y)! }
        climb.append((x, y))
    }
    // snippet end
    // snippet: lca-answer
    let ancestor = family.lowestCommonAncestor(of: a, b)       // →
    let apart = LowestCommonAncestors(family).distance(from: a, to: b)  // →
    // snippet end
    return (climb, ancestor, apart)
}
