// snippet: paste-imports
import AdjacencyListModule
import Connectivity
import GraphDrawing
import GraphFormats
import GraphProtocols
import RandomGraphs
import ShortestPaths
import Traversal
// snippet end

// The paste page's reading, drawing and searches. The marked regions are its code panels.

/// The formats the page reads.
enum PasteFormat: Int, CaseIterable {
    case dot, graphML, graph6, edgeList

    var name: String {
        switch self {
        case .dot: "DOT"
        case .graphML: "GraphML"
        case .graph6: "graph6"
        case .edgeList: "Edge list"
        }
    }
}

/// The graph in `text`, read as `format`, with any `weight` attribute of each edge by position.
func readPasted(_ text: String, as format: PasteFormat) -> Result<(graph: UndirectedAdjacencyList<String>, weights: [Int: Int]), ParseError> {
    do throws(ParseError) {
        switch format {
        case .dot:
            // snippet: paste-read-dot
            var weights: [Int: Int] = [:]
            let graph = try UndirectedAdjacencyList<String>(dot: Array(text.utf8), edgeAttribute: { edge, key, value in
                if key == "weight", let w = Int(value.description) { weights[edge] = w }
            })
            // snippet end
            return .success((graph, weights))
        case .graphML:
            // snippet: paste-read-graphml
            var weights: [Int: Int] = [:]
            let graph = try UndirectedAdjacencyList<String>(graphML: Array(text.utf8), edgeAttribute: { edge, key, value in
                if key == "weight", let w = Int(value.description) { weights[edge] = w }
            })
            // snippet end
            return .success((graph, weights))
        case .graph6:
            // snippet: paste-read-graph6
            let graph = try UndirectedAdjacencyList<String>(graph6: Array(text.utf8), vertex: { "\($0)" })
            // snippet end
            return .success((graph, [:]))
        case .edgeList:
            // snippet: paste-read-edgelist
            var weights: [Int: Int] = [:]
            let graph = try UndirectedAdjacencyList<String>(edgeList: Array(text.utf8), edgeAttribute: { edge, key, value in
                if key == "weight", let w = Int(value.description) { weights[edge] = w }
            })
            // snippet end
            return .success((graph, weights))
        }
    } catch {
        return .failure(error)
    }
}

/// A seeded force-directed drawing of `graph`. One extra, undrawn vertex is tied weakly to
/// everyone, so separate pieces stay near each other instead of drifting to the corners.
func pastedDrawing(_ graph: UndirectedAdjacencyList<String>) -> Drawing<String> {
    // snippet: paste-layout
    let centre = "\u{2063}"  // an invisible name, for the undrawn centre
    let tied = UndirectedAdjacencyList<String> {
        for v in graph.vertices where v != centre { UndirectedEdge(v, centre) }
        for edge in graph.edges { edge }
    }
    var placer = Xoshiro256StarStar(seed: 1)
    let drawing = tied.fruchtermanReingoldLayout(iterations: 150, weight: { tied.edges[$0].v == centre ? 0.15 : 1 }, using: &placer)
    // snippet end
    return drawing
}

/// Every event of a breadth-first search of `graph` from `start`.
func pastedBreadthFirst(_ graph: UndirectedAdjacencyList<String>, from start: String) -> [EdgeBreadthFirstSearchEvent<String, Int>] {
    // snippet: paste-bfs
    let events = Array(graph.lazy.edgeBreadthFirstSearch(from: start))  // →
    // snippet end
    return events
}

/// Every event of Dijkstra's search of `graph` from `start`, each edge its weight or 1.
func pastedDijkstra(_ graph: UndirectedAdjacencyList<String>, weights: [Int: Int], from start: String) -> [DijkstraSearchEvent<String, DirectedView<UndirectedAdjacencyList<String>>.Edges.Index, Int>] {
    // snippet: paste-dijkstra
    let events = Array(graph.lazy.dijkstra(from: start) { weights[$0] ?? 1 })  // →
    // snippet end
    return events
}

/// The connected components of `graph`, and a breadth-first search of each from its first vertex.
func pastedComponents(_ graph: UndirectedAdjacencyList<String>) -> (pieces: [[String]], events: [EdgeBreadthFirstSearchEvent<String, Int>]) {
    // snippet: paste-components
    let pieces = graph.connectedComponents()  // →
    let events = pieces.flatMap { piece in Array(graph.lazy.edgeBreadthFirstSearch(from: piece.first!)) }
    // snippet end
    return (pieces.map(Array.init), events)
}
