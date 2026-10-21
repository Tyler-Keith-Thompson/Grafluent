// EliasFanoGraph against CompressedSparseRow on random graphs of up to 200 vertices and 400 edges
// (so the bit arrays span many words), parallel edges and self-loops included: the same offsets,
// every row by the iterator and by the index-space walk, every edge's source and target by index,
// the edge collection and a slice of it, contains(edge:) and edgeIndex(of:) on present and absent
// edges, equality and hashing with a copy built from the rows, the round trip through the rows,
// the transpose, and the bits an edge takes within 2 + ⌈log₂ n⌉.

import CompressedSparseRowModule
import EliasFanoGraphModule
import FuzzSupport
import GraphProtocols

@main
enum FuzzEliasFanoGraph {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 0 ... 200)
        let m = input.int(in: 0 ... 400)
        var edges: [DirectedEdge<Int>] = []
        for _ in 0 ..< m where n > 0 {
            let u = input.int(below: n)
            // Clustered targets stress long unary runs and short ones.
            let v = input.byte() % 3 == 0 ? min(n - 1, u + input.int(below: 4)) : input.int(below: n)
            edges.append(DirectedEdge(from: u, to: v))
        }
        let rows = CompressedSparseRow(vertexCount: n, edges: edges)
        let coded = EliasFanoGraph(vertexCount: n, edges: edges)
        check(coded.offsets == rows.offsets, "offsets \(n) \(edges)")
        check(coded.edgeCount == rows.edgeCount && coded.vertexCount == n, "counts")
        for v in 0 ..< n {
            let expected = Array(rows.successors(of: v))
            check(Array(coded.successors(of: v)) == expected, "row \(v) of \(n) \(edges)")
            var walked: [Int] = []
            coded._forEachSuccessorIndex(ofIndex: v) { walked.append($0) }
            check(walked == expected, "walk \(v) of \(n) \(edges)")
            check(coded.outDegree(of: v) == expected.count && coded.outEdges(of: v) == rows.outEdges(of: v), "degree \(v)")
        }
        for k in 0 ..< rows.edgeCount {
            check(coded.source(ofEdgeAt: k) == rows.source(ofEdgeAt: k), "source \(k)")
            check(coded.target(ofEdgeAt: k) == rows.target(ofEdgeAt: k), "target \(k)")
            check(coded.edgeIndex(of: rows.edges[k]) == k, "edgeIndex \(k)")
        }
        check(Array(coded.edges) == Array(rows.edges), "edges \(n) \(edges)")
        if rows.edgeCount > 0 {
            let a = input.int(below: rows.edgeCount), b = input.int(below: rows.edgeCount)
            let slice = min(a, b) ..< max(a, b)
            check(Array(coded.edges[slice]) == Array(rows.edges[slice]), "slice \(slice) \(n) \(edges)")
        }
        for _ in 0 ..< 4 where n > 0 {
            let edge = DirectedEdge(from: input.int(below: n), to: input.int(below: n))
            check(coded.contains(edge: edge) == rows.contains(edge: edge), "contains \(edge)")
            check(coded.edgeIndex(of: edge) == rows.edgeIndex(of: edge), "edgeIndex \(edge)")
        }
        check(!coded.contains(edge: DirectedEdge(from: n, to: 0)) && coded.edgeIndex(of: DirectedEdge(from: 0, to: -1)) == nil, "out of range")
        let again = EliasFanoGraph(rows)
        check(again == coded && again.hashValue == coded.hashValue, "equality")
        check(CompressedSparseRow(coded) == rows, "round trip")
        check(coded.transposed() == EliasFanoGraph(rows.transposed()), "transpose")
        if rows.edgeCount > 0 {
            let logN = Double(Int.bitWidth - (n - 1).leadingZeroBitCount)
            check(coded.bitsPerEdge <= 2 + logN + 1, "bits per edge \(coded.bitsPerEdge) for n \(n)")
        }
    }
}
