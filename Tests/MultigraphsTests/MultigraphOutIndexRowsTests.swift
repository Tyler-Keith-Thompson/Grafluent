// `_withOutIndexRows` lends the stored out-rows (targets and edge positions, each row a block of a
// shared pool). Each test checks them against `successorIndices(ofIndex:)` and
// `outEdges(ofIndex:)` after a swap-remove of a vertex and the removal of an edge, copies and
// self-loops included.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs out-index rows")
struct MultigraphOutIndexRowsTests {
    @Test("DirectedPseudograph: the lent rows are successorIndices and outEdges after removals")
    func directedPseudograph() {
        var graph = DirectedPseudograph<String>(
            vertices: ["v7", "v2", "v9", "v4", "v1"],
            edges: [
                DirectedEdge(from: "v7", to: "v2"), DirectedEdge(from: "v7", to: "v2"), DirectedEdge(from: "v2", to: "v2"),
                DirectedEdge(from: "v9", to: "v4"), DirectedEdge(from: "v4", to: "v1"), DirectedEdge(from: "v1", to: "v1"),
                DirectedEdge(from: "v1", to: "v7"), DirectedEdge(from: "v2", to: "v9"), DirectedEdge(from: "v1", to: "v9"),
                DirectedEdge(from: "v7", to: "v9"), DirectedEdge(from: "v7", to: "v7"), DirectedEdge(from: "v7", to: "v4"),
            ])
        #expect(graph.remove("v2") == "v2")
        _ = graph.remove(edgeAt: graph.edges.startIndex)
        let n = graph.vertexIndexBound!
        let lent = graph._withOutIndexRows { targets, targetRows, edges, edgeRows -> [([Int], [Int])] in
            (0 ..< n).map { v in
                let (ts, tl, es, el) = (targetRows[3 * v], targetRows[3 * v + 1], edgeRows[3 * v], edgeRows[3 * v + 1])
                return (Array(targets[ts ..< ts + tl]), Array(edges[es ..< es + el]))
            }
        }
        #expect(lent != nil)
        for v in 0 ..< n {
            #expect(lent?[v].0 == Array(graph.successorIndices(ofIndex: v)), "targets of row \(v)")
            #expect(lent?[v].1 == Array(graph.outEdges(ofIndex: v)), "edges of row \(v)")
        }
        #expect(graph.outDegree(of: "v7") == 3)
    }

    @Test("DirectedMultigraph: the lent rows are its pseudograph's, successorIndices and outEdges")
    func directedMultigraph() {
        var graph = DirectedMultigraph<Int>(
            vertices: 0 ..< 5,
            edges: [
                DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2),
                DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 0),
                DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 4),
            ])!
        #expect(graph.remove(1) == 1)
        let n = graph.vertexIndexBound!
        let lent = graph._withOutIndexRows { targets, targetRows, edges, edgeRows -> [([Int], [Int])] in
            (0 ..< n).map { v in
                let (ts, tl, es, el) = (targetRows[3 * v], targetRows[3 * v + 1], edgeRows[3 * v], edgeRows[3 * v + 1])
                return (Array(targets[ts ..< ts + tl]), Array(edges[es ..< es + el]))
            }
        }
        #expect(lent != nil)
        for v in 0 ..< n {
            #expect(lent?[v].0 == Array(graph.successorIndices(ofIndex: v)), "targets of row \(v)")
            #expect(lent?[v].1 == Array(graph.outEdges(ofIndex: v)), "edges of row \(v)")
        }
    }
}
