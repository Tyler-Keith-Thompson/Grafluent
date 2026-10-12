// Attached maps of both matrices against a model (swift-property-based, with shrinking): random
// column and row appends, cell edits, value writes and resets, against arrays indexed by column and
// by row. After every step each column's and row's value is checked through the subscripts and
// `values(of:)`, and positions past the end must throw on the checked reads. A copy taken mid-run
// must keep its own values. See README.md.

import GrafluentTestSupport
import GraphProtocols
import IncidenceMatrixModule
import PropertyBased
import Testing

@Suite("IncidenceMatrix attached maps against a model", .tags(.randomized))
struct IncidenceMatrixMapPropertyTests {
    @Test("IncidenceMatrix: every value follows its column or row through random mutations")
    func unoriented() async {
        let operations = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 50)
        await propertyCheck(count: 300, input: operations) { operations in
            var matrix = IncidenceMatrix(vertexCount: 2)
            let weights = matrix.addEdgeMap(default: -1)
            let labels = matrix.addEdgeMap(of: String.self)
            let ranks = matrix.addVertexMap(default: 0.5)
            var weightModel: [Int] = [], labelModel: [String?] = [], rankModel: [Double] = [0.5, 0.5]
            var snapshot: (IncidenceMatrix, [Int], [Double])?
            for (step, (operation, x, y)) in operations.enumerated() {
                let n = matrix.vertexCount, m = matrix.hyperedgeCount
                switch operation {
                case 0:
                    #expect(matrix.insert(hyperedge: [x % n, y % n]) == m)
                    weightModel.append(-1)
                    labelModel.append(nil)
                case 1:
                    #expect(matrix.appendVertex() == n)
                    rankModel.append(0.5)
                case 2:
                    if m > 0 {
                        matrix[weights, ofEdgeAt: x % m] = step
                        weightModel[x % m] = step
                        matrix[labels, ofEdgeAt: y % m] = "s\(step)"
                        labelModel[y % m] = "s\(step)"
                    }
                case 3:
                    if m > 0 {
                        matrix[labels, ofEdgeAt: x % m] = nil
                        labelModel[x % m] = nil
                    }
                case 4:
                    matrix[ranks, of: x % n] = Double(step)
                    rankModel[x % n] = Double(step)
                case 5:
                    if m > 0 { _ = y.isMultiple(of: 2) ? matrix.insert(x % n, intoHyperedgeAt: y % m) : matrix.remove(x % n, fromHyperedgeAt: y % m) }
                case 6:
                    if snapshot == nil { snapshot = (matrix, weightModel, rankModel) }
                default:
                    if x == 0, y < 3 {
                        matrix.removeAll(keepingCapacity: y == 0)
                        weightModel = []
                        labelModel = []
                        rankModel = []
                        matrix.appendVertex()
                        rankModel.append(0.5)
                    }
                }
                #expect(matrix.hyperedgeCount == weightModel.count && matrix.vertexCount == rankModel.count, "step \(step)")
                let w = matrix.values(of: weights), r = matrix.values(of: ranks)
                for p in 0 ..< matrix.hyperedgeCount {
                    #expect(matrix[weights, ofEdgeAt: p] == weightModel[p] && w[p] == weightModel[p], "step \(step) column \(p)")
                    #expect(matrix[labels, ofEdgeAt: p] == labelModel[p], "step \(step) column \(p)")
                }
                for v in matrix.vertices {
                    #expect(matrix[ranks, of: v] == rankModel[v] && r[v] == rankModel[v], "step \(step) row \(v)")
                }
                #expect((try? matrix[weights, checkedEdgeAt: matrix.hyperedgeCount]) == nil)
                #expect((try? matrix[ranks, checked: matrix.vertexCount]) == nil)
            }
            if let snapshot {
                let (copy, copyWeights, copyRanks) = snapshot
                #expect((0 ..< copy.hyperedgeCount).map { copy[weights, ofEdgeAt: $0] } == copyWeights)
                #expect(copy.vertices.map { copy[ranks, of: $0] } == copyRanks)
            }
        }
    }

    @Test("OrientedIncidenceMatrix: every value follows its column or row through random mutations")
    func oriented() async {
        let operations = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 50)
        await propertyCheck(count: 300, input: operations) { operations in
            var matrix = OrientedIncidenceMatrix(vertexCount: 2)
            let weights = matrix.addEdgeMap(default: -1)
            let ranks = matrix.addVertexMap(default: 0.5)
            var weightModel: [Int] = [], rankModel: [Double] = [0.5, 0.5]
            var snapshot: (OrientedIncidenceMatrix, [Int], [Double])?
            for (step, (operation, x, y)) in operations.enumerated() {
                let n = matrix.vertexCount, m = matrix.hyperedgeCount
                switch operation {
                case 0:
                    let p = x.isMultiple(of: 2) ? matrix.insert(edge: DirectedEdge(from: x % n, to: y % n)) : matrix.insert(sources: [x % n], targets: [y % n, (y + 1) % n])
                    #expect(p == m)
                    weightModel.append(-1)
                case 1:
                    #expect(matrix.appendVertex() == n)
                    rankModel.append(0.5)
                case 2:
                    if m > 0 {
                        matrix[weights, ofEdgeAt: x % m] = step
                        weightModel[x % m] = step
                    }
                case 3:
                    matrix[ranks, of: x % n] = Double(step)
                    rankModel[x % n] = Double(step)
                case 4:
                    if m > 0 {
                        switch y % 4 {
                        case 0: matrix.insert(x % n, intoSourcesOfHyperedgeAt: y % m)
                        case 1: matrix.insert(x % n, intoTargetsOfHyperedgeAt: y % m)
                        case 2: matrix.remove(x % n, fromSourcesOfHyperedgeAt: y % m)
                        default: matrix.remove(x % n, fromTargetsOfHyperedgeAt: y % m)
                        }
                    }
                case 5:
                    if snapshot == nil { snapshot = (matrix, weightModel, rankModel) }
                default:
                    if x == 0, y < 3 {
                        matrix.removeAll()
                        weightModel = []
                        rankModel = []
                        matrix.appendVertex()
                        rankModel.append(0.5)
                    }
                }
                #expect(matrix.hyperedgeCount == weightModel.count && matrix.vertexCount == rankModel.count, "step \(step)")
                let w = matrix.values(of: weights), r = matrix.values(of: ranks)
                for p in 0 ..< matrix.hyperedgeCount {
                    #expect(matrix[weights, ofEdgeAt: p] == weightModel[p] && w[p] == weightModel[p], "step \(step) column \(p)")
                }
                for v in matrix.vertices {
                    #expect(matrix[ranks, of: v] == rankModel[v] && r[v] == rankModel[v], "step \(step) row \(v)")
                }
                #expect((try? matrix[weights, checkedEdgeAt: matrix.hyperedgeCount]) == nil)
                #expect((try? matrix[ranks, checkedVertexAt: matrix.vertexCount]) == nil)
            }
            if let snapshot {
                let (copy, copyWeights, copyRanks) = snapshot
                #expect((0 ..< copy.hyperedgeCount).map { copy[weights, ofEdgeAt: $0] } == copyWeights)
                #expect(copy.vertices.map { copy[ranks, of: $0] } == copyRanks)
            }
        }
    }
}
