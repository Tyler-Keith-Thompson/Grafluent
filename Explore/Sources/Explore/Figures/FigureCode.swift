// The code beside each static figure: it builds the graph the figure draws and makes the call the
// figure illustrates. The marked regions are the samples; the results are computed here.

import AdjacencyListModule
import Connectivity
import GraphProtocols
import Multigraphs
import Tours
import ShortestPaths
import Walks

func directionFigure() -> [String] {
    // snippet: figure-direction
    let friendship = UndirectedAdjacencyList<String> {
        UndirectedEdge("A", "B")
    }
    let link = AdjacencyList<String> {
        DirectedEdge(from: "A", to: "B")
    }
    let bothWays = friendship.contains(edge: UndirectedEdge("B", "A"))   // →
    let backwards = link.contains(edge: DirectedEdge(from: "B", to: "A"))  // →
    // snippet end
    return ["\(bothWays)", "\(backwards)"]
}

func weightsFigure() -> [String] {
    // snippet: figure-weights
    let minutes: [UndirectedEdge<String>: Int] = [
        UndirectedEdge("A", "B"): 4,
        UndirectedEdge("B", "C"): 3,
        UndirectedEdge("A", "C"): 9,
    ]
    let triangle = UndirectedAdjacencyList<String> {
        for edge in minutes.keys { edge }
    }
    let routes = triangle.dijkstraShortestPaths(from: "A") { minutes[triangle.edges[$0]]! }
    let cost = routes.distance(to: "C")                // →
    let stops = routes.path(to: "C").map(Array.init)   // →
    // snippet end
    return [cost.map { "\($0)" } ?? "nil", names(stops ?? [])]
}

func walksFigure() -> [String] {
    // snippet: figure-walks
    let graph = UndirectedAdjacencyList<String> {
        UndirectedEdge("A", "B")
        UndirectedEdge("B", "C")
        UndirectedEdge("C", "D")
        UndirectedEdge("B", "D")
        UndirectedEdge("A", "D")
        UndirectedEdge("E", "B")
    }
    let walk = Walk(["A", "B", "C", "B", "D"], in: graph)       // →
    let path = Path(["A", "B", "D"], in: graph)                 // →
    let notAPath = Path(["A", "B", "C", "B", "D"], in: graph)   // →
    let cycle = Cycle(["B", "C", "D"], in: graph)               // →
    // snippet end
    func shown<C: Collection>(_ route: C?, _ what: String) -> String where C.Element == String {
        route.map { "a \(what) through " + Array($0).joined(separator: " → ") } ?? "nil"
    }
    return [shown(walk, "walk"), shown(path, "path"), notAPath == nil ? "nil: B comes twice" : "a path", shown(cycle, "cycle")]
}

func loopsFigure() -> [String] {
    do throws(LooplessEdgeError) {
        // snippet: figure-loops
        let town = Pseudograph<String> {
            UndirectedEdge("A", "A")
        }
        let loops = town.hasSelfLoops  // →

        var roads = Multigraph<String>()
        let minutes = roads.addEdgeMap(default: 0)
        let highway = try roads.insert(edge: UndirectedEdge("A", "B"))
        let backRoad = try roads.insert(edge: UndirectedEdge("A", "B"))
        roads[minutes, ofEdgeAt: highway] = 12
        roads[minutes, ofEdgeAt: backRoad] = 20
        let between = roads.edgeCount(between: "A", and: "B")  // →
        // snippet end
        return ["\(loops)", "\(between)"]
    } catch {
        return []
    }
}

func negativeFigure() -> [String] {
    // snippet: figure-negative
    let cost: [DirectedEdge<String>: Int] = [
        DirectedEdge(from: "S", to: "A"): 2,
        DirectedEdge(from: "S", to: "B"): 4,
        DirectedEdge(from: "B", to: "A"): -3,
    ]
    let graph = AdjacencyList<String> {
        for edge in cost.keys { edge }
    }
    let routes = graph.bellmanFordShortestPaths(from: "S") { cost[graph.edges[$0]]! }
    let toA = routes?.distance(to: "A")                     // →
    let stops = routes?.path(to: "A").map(Array.init)       // →
    // snippet end
    return [toA.flatMap { $0 }.map { "\($0)" } ?? "nil", names(stops.flatMap { $0 } ?? [])]
}

func bowtieFigure() -> [String] {
    // snippet: figure-bowtie
    let bowtie = UndirectedAdjacencyList<String> {
        UndirectedEdge("A", "B")
        UndirectedEdge("B", "C")
        UndirectedEdge("C", "A")
        UndirectedEdge("C", "D")
        UndirectedEdge("D", "E")
        UndirectedEdge("E", "C")
    }
    let bridges = bowtie.bridges().count                    // →
    let cutVertices = bowtie.articulationPoints()           // →
    let blocks = bowtie.biconnectedComponents().count       // →
    // snippet end
    return ["\(bridges)", "[" + cutVertices.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "\(blocks)"]
}

func konigsbergFigure() -> [String] {
    // snippet: figure-konigsberg
    let konigsberg = Multigraph<String> {
        UndirectedEdge("North bank", "Kneiphof")
        UndirectedEdge("North bank", "Kneiphof")
        UndirectedEdge("South bank", "Kneiphof")
        UndirectedEdge("South bank", "Kneiphof")
        UndirectedEdge("Kneiphof", "Lomse")
        UndirectedEdge("North bank", "Lomse")
        UndirectedEdge("South bank", "Lomse")
    }!
    let bridges = konigsberg.vertices.map { konigsberg.degree(of: $0) }  // →
    let walkable = konigsberg.hasEulerianTrail                            // →
    // snippet end
    return ["[" + bridges.map(String.init).joined(separator: ", ") + "]", "\(walkable)"]
}
