// snippet: coloring-imports
import AdjacencyListModule
import BipartiteGraphs
import ColoringModule
import GraphProtocols
// snippet end

typealias Exams = UndirectedAdjacencyList<String>

func examGraph(courses: [String], clashes: [(String, String)]) -> Exams {
    // snippet: coloring-exams
    let exams = UndirectedAdjacencyList<String> {
        for course in courses { course }
        for (a, b) in clashes { UndirectedEdge(a, b) }
    }
    // snippet end
    return exams
}

func greedyInOrder(_ exams: Exams, order: [String]) -> Coloring<Exams> {
    // snippet: coloring-order
    let greedy = exams.greedyColoring(order: order)  // →
    // snippet end
    return greedy
}

/// The orders the page can colour in. Each is a snippet, shown when chosen.
func alphabeticalOrder(_ exams: Exams, courses: [String]) -> [String]? {
    // snippet: coloring-alphabetical
    let order = courses
    // snippet end
    return order
}

func busiestFirstOrder(_ exams: Exams, courses: [String]) -> [String]? {
    // snippet: coloring-busiest
    let order = courses.sorted { exams.degree(of: $0) > exams.degree(of: $1) }
    // snippet end
    return order
}

func groupByGroupOrder(_ exams: Exams, courses: [String]) -> [String]? {
    // snippet: coloring-groups
    let order = exams.bipartition().map { Array($0.left) + Array($0.right) }  // →
    // snippet end
    return order
}

func fewestSlots(_ exams: Exams) -> (count: Int, coloring: Coloring<Exams>) {
    // snippet: coloring-exact
    let fewest = exams.chromaticNumber()  // →
    let best = exams.minimumColoring()    // →
    // snippet end
    return (fewest, best)
}
