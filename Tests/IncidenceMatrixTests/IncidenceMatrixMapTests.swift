// Attached maps (`PropertyGraph`) and generations of both matrices. A hyperedge map holds one value
// per column and a vertex map one per row, each appended with its column or row; cell edits move
// no value; removeAll keeps every map attached and empty; the checked reads throw out of range;
// `values(of:)` is a snapshot; copies carry the maps copy-on-write; transposed(), reversed and the
// conversions carry none; equality and coding ignore them. Every structural mutation starts a new
// generation, and map writes and reserving capacity do not. See README.md.

import Foundation
import GraphProtocols
import IncidenceMatrixModule
import Testing

@Suite("IncidenceMatrix maps and generations")
struct IncidenceMatrixMapTests {
    @Test("IncidenceMatrix: column and row values follow appends and survive cell edits")
    func unorientedMaps() throws {
        var matrix = IncidenceMatrix(vertexCount: 3, hyperedges: [[0, 1], [2]])
        let weights = matrix.addEdgeMap(default: 1.0)
        let labels = matrix.addEdgeMap(of: String.self)
        let names = matrix.addVertexMap(default: "")
        #expect(matrix[weights, ofEdgeAt: 0] == 1 && matrix[weights, ofEdgeAt: 1] == 1)
        #expect(matrix[labels, ofEdgeAt: 1] == nil)
        matrix[weights, ofEdgeAt: 1] = 4
        matrix[labels, ofEdgeAt: 0] = "pair"
        matrix[names, of: 2] = "c"
        let p = matrix.insert(hyperedge: [0, 2])
        #expect(p == 2 && matrix[weights, ofEdgeAt: 2] == 1 && matrix[labels, ofEdgeAt: 2] == nil)
        let v = matrix.appendVertex()
        #expect(v == 3 && matrix[names, of: 3] == "" && matrix[names, ofVertexAt: 2] == "c")
        matrix.insert(3, intoHyperedgeAt: 1)
        matrix.remove(2, fromHyperedgeAt: 1)
        #expect(matrix[weights, ofEdgeAt: 1] == 4 && matrix[labels, ofEdgeAt: 0] == "pair")
        #expect(try matrix[weights, checkedEdgeAt: 1] == 4)
        #expect(throws: EdgeNotFound.self) { try matrix[weights, checkedEdgeAt: 3] }
        #expect(throws: EdgeNotFound.self) { try matrix[weights, checkedEdgeAt: -1] }
        #expect(try matrix[names, checked: 2] == "c")
        #expect(try matrix[names, checkedVertexAt: 3] == "")
        #expect(throws: VertexNotFound.self) { try matrix[names, checked: 4] }
        #expect(throws: VertexNotFound.self) { try matrix[names, checkedVertexAt: -1] }
        let w = matrix.values(of: weights)
        #expect((0 ..< 3).map { w[$0] } == [1, 4, 1] && w.defaultValue == 1)
        let n = matrix.values(of: names)
        #expect((0 ..< 4).map { n[$0] } == ["", "", "c", ""])
        // A snapshot does not see later writes.
        matrix[weights, ofEdgeAt: 0] = 9
        #expect(w[0] == 1 && matrix.values(of: weights)[0] == 9)
        // Many columns past a word boundary.
        for k in 0 ..< 70 { matrix.insert(hyperedge: [k % 4]) }
        matrix[weights, ofEdgeAt: 72] = 72
        #expect(matrix[weights, ofEdgeAt: 1] == 4 && matrix[weights, ofEdgeAt: 72] == 72 && matrix[weights, ofEdgeAt: 71] == 1)
    }

    @Test("OrientedIncidenceMatrix: column and row values follow appends and survive cell edits")
    func orientedMaps() throws {
        var matrix = OrientedIncidenceMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 2)])
        let weights = matrix.addEdgeMap(default: 0)
        let names = matrix.addVertexMap(of: String.self)
        matrix[weights, ofEdgeAt: 1] = 7
        matrix[names, of: 0] = "s"
        #expect(matrix.insert(edge: DirectedEdge(from: 1, to: 2)) == 2)
        #expect(matrix.insert(sources: [0], targets: [1, 2]) == 3)
        #expect(matrix[weights, ofEdgeAt: 2] == 0 && matrix[weights, ofEdgeAt: 3] == 0 && matrix[weights, ofEdgeAt: 1] == 7)
        #expect(matrix.appendVertex() == 3)
        #expect(matrix[names, of: 3] == nil && matrix[names, ofVertexAt: 0] == "s")
        matrix.insert(3, intoSourcesOfHyperedgeAt: 1)
        matrix.insert(3, intoTargetsOfHyperedgeAt: 0)
        matrix.remove(2, fromSourcesOfHyperedgeAt: 1)
        matrix.remove(1, fromTargetsOfHyperedgeAt: 0)
        #expect(matrix[weights, ofEdgeAt: 1] == 7 && matrix[names, of: 0] == "s")
        #expect(try matrix[weights, checkedEdgeAt: 1] == 7)
        #expect(throws: EdgeNotFound.self) { try matrix[weights, checkedEdgeAt: 4] }
        #expect(throws: EdgeNotFound.self) { try matrix[weights, checkedEdgeAt: -1] }
        #expect(throws: VertexNotFound.self) { try matrix[names, checked: 4] }
        #expect(throws: VertexNotFound.self) { try matrix[names, checkedVertexAt: 4] }
        #expect(try matrix[names, checked: 0] == "s")
        let w = matrix.values(of: weights)
        #expect((0 ..< 4).map { w[$0] } == [0, 7, 0, 0])
        #expect(matrix.values(of: names)[0] == "s")
        // Removing a map leaves the others.
        let other = matrix.addEdgeMap(default: "x")
        matrix.removeEdgeMap(weights)
        #expect(matrix[other, ofEdgeAt: 3] == "x")
        let ranks = matrix.addVertexMap(default: 2)
        matrix.removeVertexMap(names)
        #expect(matrix[ranks, of: 3] == 2)
    }

    @Test("removeAll keeps every map attached and empty, and reserveCapacity changes no value")
    func removeAllAndReserve() {
        for keepingCapacity in [false, true] {
            var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0], [1]])
            let weights = matrix.addEdgeMap(default: 0)
            let names = matrix.addVertexMap(default: 0)
            matrix[weights, ofEdgeAt: 1] = 5
            matrix[names, of: 1] = 6
            matrix.reserveCapacity(vertexCount: 100, hyperedgeCount: 100)
            #expect(matrix[weights, ofEdgeAt: 1] == 5 && matrix[names, of: 1] == 6)
            matrix.removeAll(keepingCapacity: keepingCapacity)
            matrix.appendVertex()
            matrix.appendVertex()
            matrix.insert(hyperedge: [0])
            matrix.insert(hyperedge: [1])
            #expect(matrix[weights, ofEdgeAt: 1] == 0 && matrix[names, of: 1] == 0)

            var oriented = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
            let o = oriented.addEdgeMap(default: 0)
            let r = oriented.addVertexMap(default: 0)
            oriented[o, ofEdgeAt: 0] = 3
            oriented[r, of: 1] = 4
            oriented.reserveCapacity(vertexCount: 100, hyperedgeCount: 100)
            #expect(oriented[o, ofEdgeAt: 0] == 3 && oriented[r, of: 1] == 4)
            oriented.removeAll(keepingCapacity: keepingCapacity)
            oriented.appendVertex()
            oriented.appendVertex()
            oriented.insert(edge: DirectedEdge(from: 1, to: 0))
            #expect(oriented[o, ofEdgeAt: 0] == 0 && oriented[r, of: 1] == 0)
        }
    }

    @Test("Copies carry the maps copy-on-write; equality, hashing and Codable ignore them")
    func copiesAndValueSemantics() throws {
        var matrix = IncidenceMatrix(vertexCount: 2, hyperedges: [[0, 1]])
        let weights = matrix.addEdgeMap(default: 0)
        matrix[weights, ofEdgeAt: 0] = 1
        var copy = matrix
        copy[weights, ofEdgeAt: 0] = 2
        copy.insert(hyperedge: [1])
        #expect(matrix[weights, ofEdgeAt: 0] == 1 && copy[weights, ofEdgeAt: 0] == 2 && copy[weights, ofEdgeAt: 1] == 0)
        let plain = IncidenceMatrix(vertexCount: 2, hyperedges: [[0, 1]])
        #expect(matrix == plain && matrix.hashValue == plain.hashValue)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(try encoder.encode(matrix) == encoder.encode(plain))
        var decoded = try JSONDecoder().decode(IncidenceMatrix.self, from: JSONEncoder().encode(matrix))
        #expect(decoded == matrix)
        let fresh = decoded.addEdgeMap(default: 8)
        #expect(decoded[fresh, ofEdgeAt: 0] == 8)

        var oriented = OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        let o = oriented.addEdgeMap(default: 0)
        oriented[o, ofEdgeAt: 0] = 1
        var orientedCopy = oriented
        orientedCopy[o, ofEdgeAt: 0] = 2
        #expect(oriented[o, ofEdgeAt: 0] == 1 && orientedCopy[o, ofEdgeAt: 0] == 2)
        #expect(oriented == OrientedIncidenceMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]))
        // Derived matrices are new hypergraphs: they can attach their own maps.
        var transposed = oriented.transposed()
        let t = transposed.addEdgeMap(default: "t")
        #expect(transposed[t, ofEdgeAt: 1] == "t")
        var unoriented = IncidenceMatrix(oriented)
        let u = unoriented.addVertexMap(default: 1)
        #expect(unoriented[u, of: 1] == 1)
    }

    @Test("Every structural mutation starts a generation; a call that changes nothing, a map write and reserveCapacity do not")
    func generations() throws {
        var matrix = IncidenceMatrix(vertexCount: 3)
        #expect(!matrix.generation.isCurrent(for: matrix))
        matrix.appendVertex()
        var seen = matrix.generation
        #expect(seen.isCurrent(for: matrix))
        let steps: [(String, (inout IncidenceMatrix) throws -> Void)] = [
            ("insert(hyperedge:)", { _ = $0.insert(hyperedge: [0, 1]) }),
            ("insert(checked:)", { _ = try $0.insert(checked: [2]) }),
            ("insert(_:intoHyperedgeAt:)", { _ = $0.insert(3, intoHyperedgeAt: 0) }),
            ("remove(_:fromHyperedgeAt:)", { _ = $0.remove(0, fromHyperedgeAt: 0) }),
            ("appendVertex()", { _ = $0.appendVertex() }),
            ("removeAll(keepingCapacity: true)", { $0.removeAll(keepingCapacity: true) }),
            ("removeAll()", { $0.removeAll() }),
        ]
        for (name, step) in steps {
            try step(&matrix)
            #expect(!seen.isCurrent(for: matrix), "\(name)")
            #expect(matrix.generation.isCurrent(for: matrix), "\(name)")
            seen = matrix.generation
        }
        matrix.appendVertex()
        matrix.appendVertex()
        matrix.insert(hyperedge: [0])
        seen = matrix.generation
        let unchanged: [(String, (inout IncidenceMatrix) throws -> Void)] = [
            ("insert of a set cell", { _ = $0.insert(0, intoHyperedgeAt: 0) }),
            ("remove of a clear cell", { _ = $0.remove(1, fromHyperedgeAt: 0) }),
            ("insert(checked:) throwing", { _ = try? $0.insert(checked: [5]) }),
            ("reserveCapacity", { $0.reserveCapacity(vertexCount: 10, hyperedgeCount: 10) }),
            ("maps and writes", { let m = $0.addEdgeMap(default: 0); $0[m, ofEdgeAt: 0] = 1; let v = $0.addVertexMap(default: 0); $0[v, of: 0] = 1 }),
        ]
        for (name, step) in unchanged {
            try step(&matrix)
            #expect(seen.isCurrent(for: matrix), "\(name)")
        }
        // Copies share a generation until either mutates; derived matrices are other graphs.
        var copy = matrix
        #expect(seen.isCurrent(for: copy))
        copy.appendVertex()
        #expect(!seen.isCurrent(for: copy) && seen.isCurrent(for: matrix))
        #expect(!seen.isCurrent(for: matrix.transposed()))

        var oriented = OrientedIncidenceMatrix(vertexCount: 2)
        #expect(!oriented.generation.isCurrent(for: oriented))
        oriented.appendVertex()
        var orientedSeen = oriented.generation
        let orientedSteps: [(String, (inout OrientedIncidenceMatrix) throws -> Void)] = [
            ("insert(edge:)", { _ = $0.insert(edge: DirectedEdge(from: 0, to: 1)) }),
            ("insert(sources:targets:)", { _ = $0.insert(sources: [2], targets: []) }),
            ("insert(checked:targets:)", { _ = try $0.insert(checked: [1], targets: [0]) }),
            ("insert(checked:) edge", { _ = try $0.insert(checked: DirectedEdge(from: 2, to: 2)) }),
            ("insert(_:intoSourcesOfHyperedgeAt:)", { _ = $0.insert(2, intoSourcesOfHyperedgeAt: 0) }),
            ("insert(_:intoTargetsOfHyperedgeAt:)", { _ = $0.insert(2, intoTargetsOfHyperedgeAt: 0) }),
            ("remove(_:fromSourcesOfHyperedgeAt:)", { _ = $0.remove(2, fromSourcesOfHyperedgeAt: 0) }),
            ("remove(_:fromTargetsOfHyperedgeAt:)", { _ = $0.remove(2, fromTargetsOfHyperedgeAt: 0) }),
            ("appendVertex()", { _ = $0.appendVertex() }),
            ("removeAll()", { $0.removeAll() }),
        ]
        for (name, step) in orientedSteps {
            try step(&oriented)
            #expect(!orientedSeen.isCurrent(for: oriented), "\(name)")
            #expect(oriented.generation.isCurrent(for: oriented), "\(name)")
            orientedSeen = oriented.generation
        }
        oriented.appendVertex()
        oriented.appendVertex()
        oriented.insert(edge: DirectedEdge(from: 0, to: 0))
        orientedSeen = oriented.generation
        // The column 0 → 0: both cells at vertex 0 set, none at vertex 1.
        let changed = [
            oriented.insert(0, intoSourcesOfHyperedgeAt: 0),
            oriented.insert(0, intoTargetsOfHyperedgeAt: 0),
            oriented.remove(1, fromSourcesOfHyperedgeAt: 0),
            oriented.remove(1, fromTargetsOfHyperedgeAt: 0),
        ]
        #expect(changed == [false, false, false, false])
        let thrown = (try? oriented.insert(checked: [7], targets: [])) == nil
        #expect(thrown)
        _ = oriented.addEdgeMap(default: 0)
        oriented.reserveCapacity(vertexCount: 9, hyperedgeCount: 9)
        #expect(orientedSeen.isCurrent(for: oriented))
        #expect(!orientedSeen.isCurrent(for: oriented.reversed))
        #expect(!orientedSeen.isCurrent(for: oriented.transposed()))
        #expect(!orientedSeen.isCurrent(for: IncidenceMatrix(oriented)))
    }
}
