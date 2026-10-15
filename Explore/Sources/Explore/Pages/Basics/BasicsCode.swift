// snippet: basics-imports
import AdjacencyListModule
import GraphProtocols
// snippet end

/// What the basics page reads about the picked vertex: its neighbours (or successors and
/// predecessors), and the lightest edge.
struct BasicsAnswers {
    var lines: [String]
    var lightest: (String, String)
}

func undirectedBasics(pairs: [(String, String)], weights numbers: [Int], picked: String) -> BasicsAnswers {
    // snippet: basics-undirected
    let graph = UndirectedAdjacencyList<String> {
        for (u, v) in pairs { UndirectedEdge(u, v) }
    }
    let neighbors = Array(graph.neighbors(of: picked))  // →
    let degree = graph.degree(of: picked)               // →
    // snippet end
    // snippet: basics-undirected-weights
    let weights = Dictionary(uniqueKeysWithValues: zip(pairs.map { UndirectedEdge($0.0, $0.1) }, numbers))
    let lightest = graph.edges.min { weights[$0]! < weights[$1]! }!  // →
    // snippet end
    return BasicsAnswers(lines: [names(neighbors), "\(degree)", "\(lightest.u)–\(lightest.v), weight \(weights[lightest]!)"], lightest: (lightest.u, lightest.v))
}

func directedBasics(pairs: [(String, String)], weights numbers: [Int], picked: String) -> BasicsAnswers {
    // snippet: basics-directed
    let graph = AdjacencyList<String> {
        for (u, v) in pairs { DirectedEdge(from: u, to: v) }
    }
    let successors = Array(graph.successors(of: picked))      // →
    let predecessors = Array(graph.predecessors(of: picked))  // →
    // snippet end
    // snippet: basics-directed-weights
    let weights = Dictionary(uniqueKeysWithValues: zip(pairs.map { DirectedEdge(from: $0.0, to: $0.1) }, numbers))
    let lightest = graph.edges.min { weights[$0]! < weights[$1]! }!  // →
    // snippet end
    return BasicsAnswers(lines: [names(successors), names(predecessors), "\(lightest.source) → \(lightest.target), weight \(weights[lightest]!)"], lightest: (lightest.source, lightest.target))
}

/// `["A", "B"]`, as Swift prints an array of strings.
func names(_ list: [String]) -> String { "[" + list.map { "\"\($0)\"" }.joined(separator: ", ") + "]" }
