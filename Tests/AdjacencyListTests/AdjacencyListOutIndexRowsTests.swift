// `_withOutIndexRows` lends the stored out-rows (targets and edge positions, each row a block of a
// shared pool), and `_compressedRows(readsEdges:dropsLoops:)` copies them a row at a time. Each
// test checks them against `successorIndices(ofIndex:)` and `outEdges(ofIndex:)` after rows have
// grown out of place and a swap-remove has moved a vertex and an edge, so rows do not start at 0
// and are not in slot order in the pool.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("AdjacencyList out-index rows")
struct AdjacencyListOutIndexRowsTests {
    @Test("AdjacencyList: the lent rows are successorIndices and outEdges, after growth and removals")
    func lentRows() {
        var graph = AdjacencyList<String>(vertices: ["p", "q", "r", "s", "t"])
        for (u, v) in [("p", "q"), ("q", "r"), ("r", "s"), ("s", "t"), ("t", "p"), ("p", "r"), ("p", "s"), ("p", "p"), ("q", "t"), ("p", "t")] {
            graph.insert(edge: DirectedEdge(from: u, to: v))
        }
        #expect(graph.remove("q") == "q")
        #expect(graph.remove(edge: DirectedEdge(from: "p", to: "r")) != nil)
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
        #expect(graph.successorIndices(ofIndex: graph.vertexIndex(of: "p")).count == 3)
    }

    @Test("AdjacencyList: compressed rows copy the pooled rows, with and without loops, with and without edges")
    func compressedRows() {
        var graph = AdjacencyList<Int>(vertices: 0 ..< 6)
        for (u, v) in [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 2), (0, 0), (0, 3), (3, 3), (0, 4), (2, 5), (0, 5)] {
            graph.insert(edge: DirectedEdge(from: u, to: v))
        }
        #expect(graph.remove(1) == 1)
        #expect(graph.remove(edge: DirectedEdge(from: 2, to: 3)) != nil)
        let n = graph.vertexIndexBound!
        for dropsLoops in [false, true] {
            var offsets = [0], targets: [Int] = [], edges: [Int] = []
            for v in 0 ..< n {
                for (w, e) in zip(graph.successorIndices(ofIndex: v), graph.outEdges(ofIndex: v)) where !dropsLoops || w != v {
                    targets.append(w)
                    edges.append(e)
                }
                offsets.append(targets.count)
            }
            let (rows, numbering) = graph._compressedRows(readsEdges: true, dropsLoops: dropsLoops)
            #expect(numbering == nil)
            #expect(rows.offsets == offsets, "offsets, dropsLoops \(dropsLoops)")
            #expect(rows.targets == targets, "targets, dropsLoops \(dropsLoops)")
            #expect(rows.edges == edges, "edges, dropsLoops \(dropsLoops)")
            let bare = graph._compressedRows(readsEdges: false, dropsLoops: dropsLoops).rows
            #expect(bare.offsets == offsets)
            #expect(bare.targets == targets)
            #expect(bare.edges.isEmpty)
        }
        #expect(graph._compressedRows(readsEdges: true, dropsLoops: true).rows.targets.count == graph.edgeCount - 2)
    }
}
