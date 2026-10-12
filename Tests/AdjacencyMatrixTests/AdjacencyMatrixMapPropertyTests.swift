// Attached maps against a model (swift-property-based, with shrinking): random insertions,
// removals (one edge, a row, a column, a vertex's edges, a whole-matrix operation, every edge),
// vertex appends and value writes on an AdjacencyMatrix with two edge maps and a vertex map,
// against dictionaries keyed by edge and by vertex. After every step each edge's and vertex's
// value is checked through the subscripts and `values(of:)`, and a cell with no edge must throw on
// the checked read. A copy taken mid-run must keep its own values. See README.md.

import AdjacencyMatrixModule
import BitCollections
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("AdjacencyMatrix attached maps against a model", .tags(.randomized))
struct AdjacencyMatrixMapPropertyTests {
    @Test("Every value follows its cell or vertex through random mutations")
    func model() async {
        // (operation, a, b): a and b name vertices modulo the current vertex count.
        let operations = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 50)
        await propertyCheck(count: 300, input: operations) { operations in
            var matrix = AdjacencyMatrix(vertexCount: 3)
            let weights = matrix.addEdgeMap(default: -1)
            let labels = matrix.addEdgeMap(of: String.self)
            let ranks = matrix.addVertexMap(default: 0.5)
            var weightModel: [DirectedEdge<Int>: Int] = [:]
            var labelModel: [DirectedEdge<Int>: String] = [:]
            var rankModel: [Double] = [0.5, 0.5, 0.5]
            var snapshot: (AdjacencyMatrix, [DirectedEdge<Int>: Int], [Double])?
            for (step, (operation, x, y)) in operations.enumerated() {
                let n = matrix.vertexCount
                let a = x % n, b = y % n
                let edge = DirectedEdge(from: a, to: b)
                func position(_ e: DirectedEdge<Int>) -> AdjacencyMatrix.Edges.Index {
                    matrix.outEdges(of: e.source).first { $0.target == e.target }!
                }
                func dropModel(_ removed: (DirectedEdge<Int>) -> Bool) {
                    for e in weightModel.keys where removed(e) {
                        weightModel[e] = nil
                        labelModel[e] = nil
                    }
                }
                switch operation {
                case 0, 1:
                    if matrix.insert(edge: edge).inserted { weightModel[edge] = -1 }
                case 2:
                    if matrix.remove(edge: edge) != nil { dropModel { $0 == edge } }
                case 3, 4:
                    if matrix.contains(edge: edge) {
                        matrix[weights, ofEdgeAt: position(edge)] = step
                        weightModel[edge] = step
                        if operation == 4 {
                            matrix[labels, ofEdgeAt: position(edge)] = "s\(step)"
                            labelModel[edge] = "s\(step)"
                        }
                    }
                case 5:
                    matrix[ranks, of: a] = Double(step)
                    rankModel[a] = Double(step)
                case 6:
                    if n < 9 {
                        #expect(matrix.appendVertex() == n)
                        rankModel.append(0.5)
                    }
                case 7:
                    switch b % 3 {
                    case 0: matrix.removeEdges(from: a); dropModel { $0.source == a }
                    case 1: matrix.removeEdges(to: a); dropModel { $0.target == a }
                    default: matrix.removeEdges(incidentTo: a); dropModel { $0.source == a || $0.target == a }
                    }
                case 8:
                    // A whole-matrix operation with a pseudo-random mask of the same size.
                    let mask = AdjacencyMatrix(vertexCount: n, edges: (0 ..< n).flatMap { s in (0 ..< n).compactMap { t in (s * 7 + t * 3 + x + y) % 4 == 0 ? DirectedEdge(from: s, to: t) : nil } })
                    switch x % 4 {
                    case 0:
                        matrix.formIntersection(mask)
                        dropModel { !mask.contains(edge: $0) }
                    case 1:
                        matrix.subtract(mask)
                        dropModel { mask.contains(edge: $0) }
                    case 2:
                        let before = Set(weightModel.keys)
                        matrix.formSymmetricDifference(mask)
                        dropModel { mask.contains(edge: $0) }
                        for e in mask.edges where !before.contains(e) { weightModel[e] = -1 }
                    default:
                        matrix.formUnion(mask)
                        for e in mask.edges where weightModel[e] == nil { weightModel[e] = -1 }
                    }
                case 9:
                    if y % 5 == 0 {
                        matrix.removeAllEdges(keepingCapacity: x % 2 == 0)
                        dropModel { _ in true }
                    }
                case 10:
                    if snapshot == nil { snapshot = (matrix, weightModel, rankModel) }
                default:
                    _ = matrix.insertEdges(from: a, to: BitSet([b, (b + 1) % n]))
                    for t in [b, (b + 1) % n] where weightModel[DirectedEdge(from: a, to: t)] == nil {
                        weightModel[DirectedEdge(from: a, to: t)] = -1
                    }
                }

                // The edges are the model's, and every value is the model's.
                #expect(Set(matrix.edges) == Set(weightModel.keys), "step \(step)")
                let w = matrix.values(of: weights)
                for p in matrix.edges.indices {
                    let e = matrix.edges[p]
                    #expect(matrix[weights, ofEdgeAt: p] == weightModel[e], "step \(step) \(e)")
                    #expect(w[p] == weightModel[e], "step \(step) \(e)")
                    #expect(matrix[labels, ofEdgeAt: p] == labelModel[e], "step \(step) \(e)")
                }
                for v in matrix.vertices {
                    #expect(matrix[ranks, of: v] == rankModel[v], "step \(step) \(v)")
                    for t in matrix.vertices where !matrix.contains(edge: DirectedEdge(from: v, to: t)) {
                        // A cell with no edge holds the default: the invariant that lets an
                        // insertion write nothing.
                        let cell = AdjacencyMatrix(vertexCount: matrix.vertexCount, edges: [DirectedEdge(from: v, to: t)]).edges.startIndex
                        #expect(w[cell] == -1, "step \(step) \(v)→\(t)")
                        #expect((try? matrix[weights, checkedEdgeAt: cell]) == nil, "step \(step) \(v)→\(t)")
                    }
                }
                #expect(matrix.vertexCount == rankModel.count)
            }
            // A copy taken mid-run kept its own values.
            if let snapshot {
                let (copy, copyWeights, copyRanks) = snapshot
                #expect(Set(copy.edges) == Set(copyWeights.keys))
                for p in copy.edges.indices { #expect(copy[weights, ofEdgeAt: p] == copyWeights[copy.edges[p]]) }
                for v in copy.vertices { #expect(copy[ranks, of: v] == copyRanks[v]) }
            }
        }
    }
}
