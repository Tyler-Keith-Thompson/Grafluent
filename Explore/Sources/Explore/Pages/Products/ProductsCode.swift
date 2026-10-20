// snippet: products-imports
import AdjacencyListModule
import GraphProducts
import GraphProtocols
// snippet end

// The board and the calls the graph products page makes. The marked regions are its code panels.

// snippet: products-board
let files = UndirectedAdjacencyList<String> {
    UndirectedEdge("a", "b"); UndirectedEdge("b", "c"); UndirectedEdge("c", "d")
}

let ranks = UndirectedAdjacencyList<String> {
    UndirectedEdge("1", "2"); UndirectedEdge("2", "3")
}
// snippet end

/// The moves of each product, as pairs of squares written `a1`.
func boardMoves(_ kind: Int) -> [(String, String)] {
    func square(_ p: Pair<String, String>) -> String { p.first + p.second }
    switch kind {
    case 0:
        // snippet: products-cartesian
        let rook = cartesianProductView(files, ranks)
        let squares = rook.vertexCount           // →
        let steps = rook.edgeCount               // →
        let from = rook.neighbors(of: Pair("b", "2")).map { $0.first + $0.second }  // →
        // snippet end
        _ = (squares, steps, from)
        return rook.edges.map { (square($0.u), square($0.v)) }
    case 1:
        // snippet: products-tensor
        let diagonal = tensorProductView(files, ranks)
        let steps = diagonal.edgeCount           // →
        let from = diagonal.neighbors(of: Pair("b", "2")).map { $0.first + $0.second }  // →
        // snippet end
        _ = (steps, from)
        return diagonal.edges.map { (square($0.u), square($0.v)) }
    case 2:
        // snippet: products-strong
        let king = strongProductView(files, ranks)
        let steps = king.edgeCount               // →
        let from = king.neighbors(of: Pair("b", "2")).map { $0.first + $0.second }  // →
        // snippet end
        _ = (steps, from)
        return king.edges.map { (square($0.u), square($0.v)) }
    default:
        // snippet: products-lexicographic
        let courier = lexicographicProductView(files, ranks)
        let steps = courier.edgeCount            // →
        let from = courier.neighbors(of: Pair("b", "2")).map { $0.first + $0.second }  // →
        // snippet end
        _ = (steps, from)
        return courier.edges.map { (square($0.u), square($0.v)) }
    }
}
