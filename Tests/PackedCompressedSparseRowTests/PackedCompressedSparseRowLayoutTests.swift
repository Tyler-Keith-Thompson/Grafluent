// The packed memory array under PackedCompressedSparseRow: rows stay contiguous in slot order with
// spare cells between them, a bulk build has no spare cells until the first insertion, insertions
// into one row push its neighbours apart rather than moving the row away, the storage doubles
// when dense and halves when sparse, and offsets inside rows survive every rebalance. The pool
// is read through the lent rows (`_withOutIndexRows`) and the package-visible pool.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import PackedCompressedSparseRowModule
import Testing

@Suite("PackedCompressedSparseRow layout")
struct PackedCompressedSparseRowLayoutTests {
    /// The out-row table as (start, count, capacity) per slot, and the storage size.
    func rows(_ graph: PackedCompressedSparseRow<Int>) -> (rows: [(Int, Int, Int)], capacity: Int) {
        graph._withOutIndexRows { targets, table, _, _ in
            ((0 ..< graph.vertexCount).map { (table[3 * $0], table[3 * $0 + 1], table[3 * $0 + 2]) }, targets.count)
        }!
    }

    @Test("A bulk build packs the rows exactly; the first insertion spreads spare cells over every row")
    func packedThenSpread() {
        let edges = (0 ..< 20).flatMap { u in (0 ..< 3).map { DirectedEdge(from: u, to: (u + $0 + 1) % 20) } }
        var graph = PackedCompressedSparseRow(vertices: 0 ..< 20, edges: edges)
        let packed = rows(graph)
        #expect(packed.capacity == 60 && packed.rows.allSatisfy { $0.1 == 3 && $0.2 == 3 })
        #expect(packed.rows.map(\.0) == (0 ..< 20).map { 3 * $0 })
        graph.insert(edge: DirectedEdge(from: 7, to: 15))
        let spread = rows(graph)
        #expect(spread.capacity >= 61 && spread.capacity.nonzeroBitCount == 1, "capacity \(spread.capacity)")
        #expect(spread.rows[7].1 == 4)
        #expect(spread.rows.allSatisfy { $0.2 >= $0.1 }, "a row has fewer cells than entries")
        #expect(spread.rows.filter { $0.2 > $0.1 }.count >= 10, "spare cells are not spread")
        // In slot order and disjoint.
        for s in 1 ..< 20 { #expect(spread.rows[s].0 >= spread.rows[s - 1].0 + spread.rows[s - 1].2, "row \(s) overlaps") }
        #expect(Set(graph.successors(of: 7)) == [8, 9, 10, 15])
    }

    @Test("Filling one row repeatedly keeps it in place among its neighbours and the walk order intact")
    func oneRowGrows() {
        var graph = PackedCompressedSparseRow(vertices: 0 ..< 50, edges: (0 ..< 50).map { DirectedEdge(from: $0, to: ($0 + 1) % 50) })
        for k in 0 ..< 200 { graph.insert(edge: DirectedEdge(from: 25, to: (k * 7) % 50)) }
        let layout = rows(graph)
        for s in 1 ..< 50 { #expect(layout.rows[s].0 >= layout.rows[s - 1].0 + layout.rows[s - 1].2, "row \(s) out of order") }
        #expect(layout.rows[25].1 == graph.outDegree(of: 25) && graph.outDegree(of: 25) == 50)
        // The walk in slot order reads every row forward.
        var walked: [Int] = []
        for v in 0 ..< 50 { walked.append(contentsOf: graph.outEdges(ofIndex: v).map { graph.sourceIndex(ofEdgeAt: $0) }) }
        #expect(walked == walked.sorted())
        #expect(graph == PackedCompressedSparseRow(vertices: 0 ..< 50, edges: Array(graph.edges)))
    }

    @Test("Growth doubles the storage as edges arrive; removals halve it once it is mostly spare")
    func growAndShrink() {
        var graph = PackedCompressedSparseRow<Int>(vertices: 0 ..< 100)
        var capacities: [Int] = []
        for k in 0 ..< 2000 {
            graph.insert(edge: DirectedEdge(from: k % 100, to: (k * 31) % 100))
            let c = rows(graph).capacity
            if capacities.last != c { capacities.append(c) }
        }
        #expect(capacities.allSatisfy { $0.nonzeroBitCount == 1 }, "capacities \(capacities)")
        #expect(zip(capacities, capacities.dropFirst()).allSatisfy { $1 == 2 * $0 }, "growth not by doubling: \(capacities)")
        let full = rows(graph).capacity
        #expect(Double(graph.edgeCount) <= 0.7 * Double(full) && Double(graph.edgeCount) > 0.3 * Double(full))
        var rng = SeededRandomNumberGenerator(seed: 5)
        for edge in Array(graph.edges).shuffled(using: &rng) { graph.remove(edge: edge) }
        #expect(graph.edgeCount == 0 && rows(graph).capacity < full)
        verify(graph, Set(0 ..< 100), [])
    }

    @Test("Removing a vertex moves the last slot's rows into its place and keeps every other row where it was")
    func vertexRemovalMovesLastRow() {
        var graph = PackedCompressedSparseRow(vertices: 0 ..< 8, edges: [DirectedEdge(from: 7, to: 0), DirectedEdge(from: 7, to: 1), DirectedEdge(from: 7, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 7)])
        graph.insert(edge: DirectedEdge(from: 4, to: 5))
        graph.remove(2)
        #expect(graph.vertexIndex(of: 7) == 2 && graph.vertexCount == 7)
        #expect(Set(graph.successors(of: 7)) == [0, 1] && Set(graph.predecessors(of: 7)) == [3])
        verify(graph, [0, 1, 3, 4, 5, 6, 7], [DirectedEdge(from: 7, to: 0), DirectedEdge(from: 7, to: 1), DirectedEdge(from: 3, to: 7), DirectedEdge(from: 4, to: 5)])
        // Removing the last slot itself.
        graph.remove(7)
        verify(graph, [0, 1, 3, 4, 5, 6], [DirectedEdge(from: 4, to: 5)])
    }

    @Test("A self-loop and a star: offsets in both rows stay right through rebalances")
    func selfLoopsAndStar() {
        var graph = PackedCompressedSparseRow<Int>()
        for v in 0 ..< 300 {
            graph.insert(edge: DirectedEdge(from: 0, to: v))
            graph.insert(edge: DirectedEdge(from: v, to: 0))
        }
        #expect(graph.outDegree(of: 0) == 300 && graph.inDegree(of: 0) == 300 && graph.degree(of: 0) == 600)
        #expect(graph.contains(edge: DirectedEdge(from: 0, to: 0)))
        for v in stride(from: 1, to: 300, by: 2) { graph.remove(edge: DirectedEdge(from: v, to: 0)) }
        #expect(graph.inDegree(of: 0) == 150)
        verify(graph, Set(0 ..< 300), Set((0 ..< 300).map { DirectedEdge(from: 0, to: $0) } + stride(from: 0, to: 300, by: 2).map { DirectedEdge(from: $0, to: 0) }))
    }
}
