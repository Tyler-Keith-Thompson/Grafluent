// snippet: representations-imports
import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import LabeledGraphs
// snippet end

/// The friends' graph in its three forms. The matrix and CSR forms number the people in
/// `people` order.
struct ThreeForms {
    var rows: [[String]]
    var matrix: LabeledGraph<String, AdjacencyMatrix>
    var csr: LabeledGraph<String, CompressedSparseRow>
}

/// Who follows whom, as a directed graph.
func followForms(people: [String], arrows: [(String, String)]) -> ThreeForms {
    // snippet: representations-follows
    let follows = AdjacencyList<String> {
        for name in people { name }
        for (who, whom) in arrows { DirectedEdge(from: who, to: whom) }
    }
    let rows = people.map { Array(follows.successors(of: $0)) }
    let matrix = LabeledGraph<String, AdjacencyMatrix>(follows)
    let csr = LabeledGraph<String, CompressedSparseRow>(follows)
    // snippet end
    return ThreeForms(rows: rows, matrix: matrix, csr: csr)
}

/// The same pairs as friendships, which go both ways.
func friendForms(people: [String], arrows: [(String, String)]) -> ThreeForms {
    // snippet: representations-friends
    let friends = UndirectedAdjacencyList<String> {
        for name in people { name }
        for (a, b) in arrows { UndirectedEdge(a, b) }
    }
    let rows = people.map { Array(friends.neighbors(of: $0)) }
    let matrix = LabeledGraph<String, AdjacencyMatrix>(friends.directedView)
    let csr = LabeledGraph<String, CompressedSparseRow>(friends.directedView)
    // snippet end
    return ThreeForms(rows: rows, matrix: matrix, csr: csr)
}

/// What the code panel prints from the three forms.
func readBack(_ forms: ThreeForms) -> [String] {
    let (rows, matrix, csr) = (forms.rows, forms.matrix, forms.csr)
    // snippet: representations-read
    let anaRow = rows[0]                                            // →
    let anaToBen = matrix.contains(edge: DirectedEdge(from: "Ana", to: "Ben"))  // →
    let offsets = csr.base.offsets                                  // →
    let targets = csr.base.targets.map { csr.vertex(atIndex: $0) }  // →
    // snippet end
    func names(_ list: [String]) -> String { "[" + list.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
    return [names(anaRow), "\(anaToBen)", "\(offsets)", names(targets)]
}
