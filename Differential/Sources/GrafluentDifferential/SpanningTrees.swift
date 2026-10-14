import GraphProtocols
import Multigraphs
import SpanningTrees

/// Spanning arborescences and branchings of a directed case (its edges as a `DirectedPseudograph`,
/// position k the case's k-th edge): the weights, nil where none exists, and each answer's edges
/// as offsets in the case's edge list. Rooted at the first source.
struct ArborescenceAnswers: Encodable {
    var minimum: Int?
    var minimumEdges: [Int]?
    var maximum: Int?
    var maximumEdges: [Int]?
    var rootedMinimum: Int?
    var rootedMinimumEdges: [Int]?
    var rootedMaximum: Int?
    var rootedMaximumEdges: [Int]?
    var minimumBranching = 0
    var minimumBranchingEdges: [Int] = []
    var maximumBranching = 0
    var maximumBranchingEdges: [Int] = []
}

func arborescenceAnswers(n: Int, edges: [[Int]], root: Int) -> ArborescenceAnswers {
    let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
    let w: (Int) -> Int = { edges[$0][2] }
    var a = ArborescenceAnswers()
    let minimum = graph.minimumSpanningArborescence(weight: w), maximum = graph.maximumSpanningArborescence(weight: w)
    a.minimum = minimum?.weight
    a.minimumEdges = minimum?.edges
    a.maximum = maximum?.weight
    a.maximumEdges = maximum?.edges
    let rootedMinimum = graph.minimumSpanningArborescence(from: root, weight: w)
    let rootedMaximum = graph.maximumSpanningArborescence(from: root, weight: w)
    a.rootedMinimum = rootedMinimum?.weight
    a.rootedMinimumEdges = rootedMinimum?.edges
    a.rootedMaximum = rootedMaximum?.weight
    a.rootedMaximumEdges = rootedMaximum?.edges
    let minimumBranching = graph.minimumBranching(weight: w), maximumBranching = graph.maximumBranching(weight: w)
    a.minimumBranching = minimumBranching.weight
    a.minimumBranchingEdges = minimumBranching.edges
    a.maximumBranching = maximumBranching.weight
    a.maximumBranchingEdges = maximumBranching.edges
    return a
}

/// Steiner trees of an undirected case (its edges as a `Pseudograph`), weights |w|, connecting
/// the sources and the target: each method's weight and edges as offsets, nil when the terminals
/// are in different components.
struct SteinerAnswers: Encodable {
    var terminals: [Int] = []
    var mehlhorn: Int?
    var mehlhornEdges: [Int]?
    var kou: Int?
    var kouEdges: [Int]?
}

func steinerAnswers(n: Int, edges: [[Int]], terminals: [Int]) -> SteinerAnswers {
    let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
    let w: (Int) -> Int = { abs(edges[$0][2]) }
    var a = SteinerAnswers()
    a.terminals = terminals
    let mehlhorn = graph.steinerTree(terminals: terminals, weight: w), kou = graph.kouSteinerTree(terminals: terminals, weight: w)
    a.mehlhorn = mehlhorn?.weight
    a.mehlhornEdges = mehlhorn?.edges
    a.kou = kou?.weight
    a.kouEdges = kou?.edges
    return a
}
