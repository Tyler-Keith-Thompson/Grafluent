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
        case .graph6: "graph6 or digraph6"
        case .edgeList: "Edge list"
        }
    }
}

/// The pasted graph: undirected or directed, as the text says.
enum PastedGraph {
    case undirected(UndirectedAdjacencyList<String>)
    case directed(AdjacencyList<String>)

    var isDirected: Bool { if case .directed = self { true } else { false } }
    var vertexCount: Int {
        switch self {
        case .undirected(let g): g.vertexCount
        case .directed(let g): g.vertexCount
        }
    }
    var edgeCount: Int {
        switch self {
        case .undirected(let g): g.edgeCount
        case .directed(let g): g.edgeCount
        }
    }
    var vertices: [String] {
        switch self {
        case .undirected(let g): Array(g.vertices)
        case .directed(let g): Array(g.vertices)
        }
    }
    /// The two ends of the edge at `position`, in writing order.
    func ends(_ position: Int) -> (String, String) {
        switch self {
        case .undirected(let g): (g.edges[position].u, g.edges[position].v)
        case .directed(let g): (g.edges[position].source, g.edges[position].target)
        }
    }
    func contains(_ vertex: String) -> Bool {
        switch self {
        case .undirected(let g): g.contains(vertex)
        case .directed(let g): g.contains(vertex)
        }
    }
}

/// The graph in `text`, read as `format`, with any `weight` attribute of each edge by position.
/// A text that says it is directed (a DOT `digraph`, a GraphML `edgedefault="directed"`, a
/// digraph6 line) is read as one.
func readPasted(_ text: String, as format: PasteFormat) -> Result<(graph: PastedGraph, weights: [Int: Int]), ParseError> {
    do throws(ParseError) {
        var weights: [Int: Int] = [:]
        switch format {
        case .dot:
            do throws(ParseError) {
                // snippet: paste-read-dot
                let graph = try UndirectedAdjacencyList<String>(dot: Array(text.utf8), edgeAttribute: { edge, key, value in
                    if key == "weight", let w = Int(value.description) { weights[edge] = w }
                })
                // snippet end
                return .success((.undirected(graph), weights))
            } catch where error.kind == .kindMismatch {
                weights = [:]
                // snippet: paste-read-digraph
                let graph = try AdjacencyList<String>(dot: Array(text.utf8), edgeAttribute: { edge, key, value in
                    if key == "weight", let w = Int(value.description) { weights[edge] = w }
                })
                // snippet end
                return .success((.directed(graph), weights))
            }
        case .graphML:
            do throws(ParseError) {
                // snippet: paste-read-graphml
                let graph = try UndirectedAdjacencyList<String>(graphML: Array(text.utf8), edgeAttribute: { edge, key, value in
                    if key == "weight", let w = Int(value.description) { weights[edge] = w }
                })
                // snippet end
                return .success((.undirected(graph), weights))
            } catch where error.kind == .kindMismatch {
                weights = [:]
                // snippet: paste-read-graphml-directed
                let graph = try AdjacencyList<String>(graphML: Array(text.utf8), edgeAttribute: { edge, key, value in
                    if key == "weight", let w = Int(value.description) { weights[edge] = w }
                })
                // snippet end
                return .success((.directed(graph), weights))
            }
        case .graph6:
            if text.hasPrefix("&") {
                // snippet: paste-read-digraph6
                let graph = try AdjacencyList<String>(digraph6: Array(text.utf8), vertex: { "\($0)" })
                // snippet end
                return .success((.directed(graph), [:]))
            }
            // snippet: paste-read-graph6
            let graph = try UndirectedAdjacencyList<String>(graph6: Array(text.utf8), vertex: { "\($0)" })
            // snippet end
            return .success((.undirected(graph), [:]))
        case .edgeList:
            // snippet: paste-read-edgelist
            let graph = try UndirectedAdjacencyList<String>(edgeList: Array(text.utf8), edgeAttribute: { edge, key, value in
                if key == "weight", let w = Int(value.description) { weights[edge] = w }
            })
            // snippet end
            return .success((.undirected(graph), weights))
        }
    } catch {
        return .failure(error)
    }
}

/// A seeded force-directed drawing of the vertices with the given pairs joined. One extra, undrawn
/// vertex is tied weakly to everyone, so separate pieces stay near each other instead of drifting
/// to the corners.
func pastedDrawing(_ vertices: [String], _ pairs: [(String, String)]) -> Drawing<String> {
    // snippet: paste-layout
    let centre = "\u{2063}"  // an invisible name, for the undrawn centre
    let tied = UndirectedAdjacencyList<String> {
        for v in vertices where v != centre { UndirectedEdge(v, centre) }
        for (u, v) in pairs { UndirectedEdge(u, v) }
    }
    var placer = Xoshiro256StarStar(seed: 1)
    let drawing = tied.fruchtermanReingoldLayout(iterations: 150, weight: { tied.edges[$0].v == centre ? 0.15 : 1 }, using: &placer)
    // snippet end
    return drawing
}

/// Every event of a breadth-first search of `graph` from `start`.
func pastedBreadthFirst(_ graph: PastedGraph, from start: String) -> [EdgeBreadthFirstSearchEvent<String, Int>] {
    switch graph {
    case .undirected(let graph):
        // snippet: paste-bfs
        let events = Array(graph.lazy.edgeBreadthFirstSearch(from: start))  // →
        // snippet end
        return events
    case .directed(let graph):
        return Array(graph.lazy.edgeBreadthFirstSearch(from: start))
    }
}

/// What the page keeps of a Dijkstra event: a vertex settled at a distance, or an edge relaxed.
enum PasteDijkstraEvent {
    case examine(String, Int)
    case relaxed(Int)
}

/// Every event of Dijkstra's search of `graph` from `start`, each edge its weight or 1; the page
/// keeps the examine and edgeRelaxed events, by edge position.
func pastedDijkstra(_ graph: PastedGraph, weights: [Int: Int], from start: String) -> (count: Int, kept: [PasteDijkstraEvent]) {
    switch graph {
    case .undirected(let graph):
        // snippet: paste-dijkstra
        let events = Array(graph.lazy.dijkstra(from: start) { weights[$0] ?? 1 })  // →
        // snippet end
        return (events.count, events.compactMap { event in
            switch event {
            case .examine(let v, let d): .examine(v, d)
            case .edgeRelaxed(let e, _): .relaxed(e.position)
            default: nil
            }
        })
    case .directed(let graph):
        let events = Array(graph.lazy.dijkstra(from: start) { weights[$0] ?? 1 })
        return (events.count, events.compactMap { event in
            switch event {
            case .examine(let v, let d): .examine(v, d)
            case .edgeRelaxed(let e, _): .relaxed(e)
            default: nil
            }
        })
    }
}

/// The connected components of `graph` (weakly, when directed), and a breadth-first search of
/// each from its first vertex.
func pastedComponents(_ graph: PastedGraph) -> (pieces: [[String]], events: [EdgeBreadthFirstSearchEvent<String, Int>]) {
    switch graph {
    case .undirected(let graph):
        // snippet: paste-components
        let pieces = graph.connectedComponents()  // →
        let events = pieces.flatMap { piece in Array(graph.lazy.edgeBreadthFirstSearch(from: piece.first!)) }
        // snippet end
        return (pieces.map(Array.init), events)
    case .directed(let graph):
        // snippet: paste-weak-components
        let pieces = graph.weaklyConnectedComponents()  // →
        let events = pieces.flatMap { piece in Array(graph.undirectedView.lazy.edgeBreadthFirstSearch(from: piece.first!)) }
        // snippet end
        return (pieces.map(Array.init), events)
    }
}
