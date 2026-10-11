// Properties with shrinking (swift-property-based), each against a model written out in the test.
// The matrix identities, computed from the public cells: B·Bᵀ = D + A for a loopless multigraph
// (A counting parallel edges), Bᵀ·B = 2I + A(L(G)) for a loopless simple graph, and, oriented,
// B·Bᵀ = L = D − A of the loopless underlying multigraph, self-loops included in the input. Then
// cell-edit sequences on both matrices against a set of set cells (one set per plane), checking every
// cell, column, row, degree and the handshake law after each step; `transposed()` as an involution
// that swaps rows and columns; `reversed` as negation; and equality as cell-for-cell. See README.md.

import GrafluentTestSupport
import GraphProtocols
import IncidenceMatrixModule
import Multigraphs
import PropertyBased
import Testing

@Suite("IncidenceMatrix properties against a model, with shrinking", .tags(.randomized))
struct IncidenceMatrixPropertyTests {
    @Test("B·Bᵀ = D + A on loopless multigraphs; Bᵀ·B = 2I + A(L(G)) on loopless simple graphs")
    func unorientedIdentities() async {
        let input = zip(Gen.int(in: 1 ... 7), zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14))
        await propertyCheck(count: 300, input: input) { n, raw in
            let edges = raw.map { ($0.0 % n, $0.1 % n) }.filter { $0.0 != $0.1 }
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let matrix = IncidenceMatrix(graph)
            let m = graph.edgeCount
            #expect(matrix.vertexCount == n && matrix.hyperedgeCount == m)
            func b(_ v: Int, _ p: Int) -> Int { matrix[vertex: v, hyperedge: p] ? 1 : 0 }
            for u in 0 ..< n {
                for v in 0 ..< n {
                    let product = (0 ..< m).reduce(0) { $0 + b(u, $1) * b(v, $1) }
                    let adjacency = graph.edges.filter { ($0.u == u && $0.v == v) || ($0.u == v && $0.v == u) }.count
                    #expect(product == (u == v ? graph.degree(of: u) : adjacency), "B·Bᵀ at (\(u), \(v)) for \(edges)")
                }
            }
            let ends = graph.edges.map { Set([$0.u, $0.v]) }
            if Set(ends).count == ends.count {
                for p in 0 ..< m {
                    for q in 0 ..< m {
                        let product = (0 ..< n).reduce(0) { $0 + b($1, p) * b($1, q) }
                        let line = p == q ? 2 : (ends[p].isDisjoint(with: ends[q]) ? 0 : 1)
                        #expect(product == line, "Bᵀ·B at (\(p), \(q)) for \(edges)")
                    }
                }
            }
        }
    }

    @Test("Oriented B·Bᵀ = L, the Laplacian of the loopless underlying multigraph; columns sum to zero")
    func orientedLaplacian() async {
        let input = zip(Gen.int(in: 1 ... 7), zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14))
        await propertyCheck(count: 300, input: input) { n, raw in
            let arcs = raw.map { DirectedEdge(from: $0.0 % n, to: $0.1 % n) }
            let digraph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)
            let matrix = OrientedIncidenceMatrix(digraph)
            let m = matrix.hyperedgeCount
            #expect(m == arcs.count)
            for p in 0 ..< m { #expect((0 ..< n).reduce(0) { $0 + matrix[vertex: $1, hyperedge: p] } == 0) }
            let loopless = arcs.filter { $0.source != $0.target }
            for u in 0 ..< n {
                for v in 0 ..< n {
                    let product = (0 ..< m).reduce(0) { $0 + matrix[vertex: u, hyperedge: $1] * matrix[vertex: v, hyperedge: $1] }
                    let laplacian = u == v
                        ? loopless.filter { $0.source == u || $0.target == u }.count
                        : -loopless.filter { ($0.source == u && $0.target == v) || ($0.source == v && $0.target == u) }.count
                    #expect(product == laplacian, "B·Bᵀ at (\(u), \(v)) for \(arcs)")
                }
            }
            // |B| is the unoriented matrix except where a column's sides meet.
            let unoriented = IncidenceMatrix(matrix)
            for p in 0 ..< m {
                for v in 0 ..< n where matrix[vertex: v, hyperedge: p] != 0 {
                    #expect(unoriented[vertex: v, hyperedge: p])
                }
            }
            #expect(unoriented == IncidenceMatrix(digraph))
        }
    }

    @Test("IncidenceMatrix cell edits agree with a set of cells after every step")
    func unorientedEditsAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 70), Gen.int(in: 0 ... 70)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var matrix = IncidenceMatrix()
            var n = 0, m = 0
            var cells = Set<[Int]>()
            for (step, (kind, x, y)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0, 1:
                    #expect(matrix.appendVertex() == n, "\(context)")
                    n += 1
                case 2, 3:
                    let members = n == 0 ? [] : [x % n, y % n, (x + y) % n].prefix(x % 4)
                    #expect(matrix.insert(hyperedge: members) == m, "\(context)")
                    for v in members { cells.insert([v, m]) }
                    m += 1
                case 4 ... 6 where n > 0 && m > 0:
                    let changed = matrix.insert(x % n, intoHyperedgeAt: y % m)
                    #expect(changed == !cells.contains([x % n, y % m]), "\(context)")
                    cells.insert([x % n, y % m])
                case 7 ... 8 where n > 0 && m > 0:
                    let changed = matrix.remove(x % n, fromHyperedgeAt: y % m)
                    #expect(changed == cells.contains([x % n, y % m]), "\(context)")
                    cells.remove([x % n, y % m])
                case 9 where x < 6:
                    matrix.removeAll(keepingCapacity: y.isMultiple(of: 2))
                    n = 0
                    m = 0
                    cells.removeAll()
                default:
                    matrix.reserveCapacity(vertexCount: x, hyperedgeCount: y)
                }
                #expect(matrix.vertexCount == n && matrix.hyperedgeCount == m && matrix.vertexIndexBound == n && matrix.hyperedgeIndexBound == m, "\(context)")
                for v in 0 ..< n {
                    let row = (0 ..< m).filter { cells.contains([v, $0]) }
                    #expect(Array(matrix.incidentHyperedges(of: v)) == row && matrix.degree(of: v) == row.count, "\(context)")
                    #expect(Array(matrix.incidentHyperedges(ofIndex: v)) == row && matrix.degree(ofIndex: v) == row.count, "\(context)")
                }
                for p in 0 ..< m {
                    let column = (0 ..< n).filter { cells.contains([$0, p]) }
                    #expect(Array(matrix.members(ofHyperedgeAt: p)) == column && matrix.size(ofHyperedgeAt: p) == column.count, "\(context)")
                    #expect((0 ..< n).allSatisfy { matrix[vertex: $0, hyperedge: p] == cells.contains([$0, p]) }, "\(context)")
                }
                // The transpose swaps rows and columns, and is an involution.
                let transposed = matrix.transposed()
                #expect(transposed.vertexCount == m && transposed.hyperedgeCount == n && transposed.transposed() == matrix, "\(context)")
                #expect((0 ..< n).allSatisfy { v in Array(transposed.members(ofHyperedgeAt: v)) == Array(matrix.incidentHyperedges(of: v)) }, "\(context)")
                #expect((0 ..< n).reduce(0) { $0 + matrix.degree(of: $1) } == cells.count, "handshake, \(context)")
            }
        }
    }

    @Test("OrientedIncidenceMatrix plane edits agree with two sets of cells after every step")
    func orientedEditsAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 70), Gen.int(in: 0 ... 70)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var matrix = OrientedIncidenceMatrix()
            var n = 0, m = 0
            var sources = Set<[Int]>(), targets = Set<[Int]>()
            for (step, (kind, x, y)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0, 1:
                    #expect(matrix.appendVertex() == n, "\(context)")
                    n += 1
                case 2 where n > 0:
                    #expect(matrix.insert(edge: DirectedEdge(from: x % n, to: y % n)) == m, "\(context)")
                    sources.insert([x % n, m])
                    targets.insert([y % n, m])
                    m += 1
                case 3:
                    let s = n == 0 ? [] : [x % n, (x + 3) % n].prefix(x % 3), t = n == 0 ? [] : [y % n].prefix(y % 2)
                    #expect(matrix.insert(sources: s, targets: t) == m, "\(context)")
                    for v in s { sources.insert([v, m]) }
                    for v in t { targets.insert([v, m]) }
                    m += 1
                case 4 ... 5 where n > 0 && m > 0:
                    let changed = matrix.insert(x % n, intoSourcesOfHyperedgeAt: y % m)
                    #expect(changed == sources.insert([x % n, y % m]).inserted, "\(context)")
                case 6 ... 7 where n > 0 && m > 0:
                    let changed = matrix.insert(x % n, intoTargetsOfHyperedgeAt: y % m)
                    #expect(changed == targets.insert([x % n, y % m]).inserted, "\(context)")
                case 8 where n > 0 && m > 0:
                    let changed = matrix.remove(x % n, fromSourcesOfHyperedgeAt: y % m)
                    #expect(changed == (sources.remove([x % n, y % m]) != nil), "\(context)")
                case 9 where n > 0 && m > 0:
                    let changed = matrix.remove(x % n, fromTargetsOfHyperedgeAt: y % m)
                    #expect(changed == (targets.remove([x % n, y % m]) != nil), "\(context)")
                case 10 where x < 6:
                    matrix.removeAll(keepingCapacity: y.isMultiple(of: 2))
                    n = 0
                    m = 0
                    sources.removeAll()
                    targets.removeAll()
                default:
                    matrix.reserveCapacity(vertexCount: x, hyperedgeCount: y)
                }
                #expect(matrix.vertexCount == n && matrix.hyperedgeCount == m, "\(context)")
                for v in 0 ..< n {
                    let out = (0 ..< m).filter { sources.contains([v, $0]) }, into = (0 ..< m).filter { targets.contains([v, $0]) }
                    #expect(Array(matrix.outHyperedges(of: v)) == out && Array(matrix.inHyperedges(of: v)) == into, "\(context)")
                    #expect(matrix.outDegree(of: v) == out.count && matrix.inDegree(of: v) == into.count && matrix.degree(of: v) == out.count + into.count, "\(context)")
                    for p in 0 ..< m {
                        let entry = (targets.contains([v, p]) ? 1 : 0) - (sources.contains([v, p]) ? 1 : 0)
                        #expect(matrix[vertex: v, hyperedge: p] == entry && matrix.reversed[vertex: v, hyperedge: p] == -entry, "\(context)")
                    }
                }
                for p in 0 ..< m {
                    #expect(Array(matrix.sources(ofHyperedgeAt: p)) == (0 ..< n).filter { sources.contains([$0, p]) }, "\(context)")
                    #expect(Array(matrix.targets(ofHyperedgeAt: p)) == (0 ..< n).filter { targets.contains([$0, p]) }, "\(context)")
                }
                let transposed = matrix.transposed()
                #expect(transposed.vertexCount == m && transposed.hyperedgeCount == n && transposed.transposed() == matrix, "\(context)")
                #expect((0 ..< n).allSatisfy { v in Array(transposed.sources(ofHyperedgeAt: v)) == Array(matrix.outHyperedges(of: v)) && Array(transposed.targets(ofHyperedgeAt: v)) == Array(matrix.inHyperedges(of: v)) }, "\(context)")
                #expect(matrix.reversed.reversed == matrix, "\(context)")
                #expect((0 ..< n).reduce(0) { $0 + matrix.outDegree(of: $1) } == sources.count && (0 ..< n).reduce(0) { $0 + matrix.inDegree(of: $1) } == targets.count, "handshake, \(context)")
            }
        }
    }

    @Test("Equality is cell for cell with equal shape; swapping two different columns breaks it")
    func equalityIsCellForCell() async {
        let input = zip(Gen.int(in: 1 ... 6), Gen.int(in: 0 ... 5).array(of: 0 ... 3).array(of: 2 ... 6))
        await propertyCheck(count: 300, input: input) { n, raw in
            let columns = raw.map { $0.map { $0 % n } }
            let matrix = IncidenceMatrix(vertexCount: n, hyperedges: columns)
            let same = IncidenceMatrix(vertexCount: n, hyperedges: columns.map { $0.reversed() + $0 })
            #expect(matrix == same && matrix.hashValue == same.hashValue)
            var swapped = columns
            swapped.swapAt(0, 1)
            #expect((IncidenceMatrix(vertexCount: n, hyperedges: swapped) == matrix) == (Set(columns[0]) == Set(columns[1])))
            var wider = matrix
            wider.appendVertex()
            #expect(wider != matrix)
        }
    }
}
