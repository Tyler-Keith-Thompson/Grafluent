// Attached maps (`PropertyGraph`): edge maps by cell, laid out at Szudzik's pairing so that
// `appendVertex()` moves no value; every way of removing an edge (one at a time, the subscript, a
// row, a column, a whole-matrix operation, `removeAllEdges`) sets the cell back to the default, so
// an edge inserted there later starts at the default; vertex maps appended with the vertex; the
// checked reads; `values(of:)` snapshots; copies, conversions, equality and coding. See README.md.

import AdjacencyMatrixModule
import Foundation
import GraphProtocols
import Testing

@Suite("AdjacencyMatrix maps")
struct AdjacencyMatrixMapTests {
    @Test("An edge map reads its default until set, and a set value stays with its cell")
    func edgeMapBasics() throws {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 1)])
        let weights = matrix.addEdgeMap(default: 1.5)
        let p01 = matrix.edges.firstIndex(of: DirectedEdge(from: 0, to: 1))!
        let p20 = matrix.edges.firstIndex(of: DirectedEdge(from: 2, to: 0))!
        let p11 = matrix.edges.firstIndex(of: DirectedEdge(from: 1, to: 1))!
        #expect(matrix[weights, ofEdgeAt: p01] == 1.5 && matrix[weights, ofEdgeAt: p20] == 1.5 && matrix[weights, ofEdgeAt: p11] == 1.5)
        matrix[weights, ofEdgeAt: p01] = 2
        matrix[weights, ofEdgeAt: p20] = 3
        matrix[weights, ofEdgeAt: p11] += 4
        #expect(matrix[weights, ofEdgeAt: p01] == 2 && matrix[weights, ofEdgeAt: p20] == 3 && matrix[weights, ofEdgeAt: p11] == 5.5)
        #expect(try matrix[weights, checkedEdgeAt: p20] == 3)
        // A position names its cell: the index of the same edge from outEdges reads the same value.
        #expect(matrix[weights, ofEdgeAt: matrix.outEdges(of: 2).first!] == 3)
        #expect(matrix[weights, ofEdgeAt: matrix.inEdges(of: 1).first!] == 2)
        let all = matrix.edges.indices.map { matrix[weights, ofEdgeAt: $0] }
        #expect(all == [2, 5.5, 3])
        #expect(matrix.edgeCount == 3)
    }

    @Test("addEdgeMap(of:) is a map of Optionals whose default is nil; assigning nil clears")
    func optionalMap() {
        var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let labels = matrix.addEdgeMap(of: String.self)
        let p = matrix.edges.firstIndex(of: DirectedEdge(from: 1, to: 0))!
        #expect(matrix[labels, ofEdgeAt: p] == nil)
        matrix[labels, ofEdgeAt: p] = "back"
        #expect(matrix[labels, ofEdgeAt: p] == "back")
        matrix[labels, ofEdgeAt: p] = nil
        #expect(matrix[labels, ofEdgeAt: p] == nil)
        let names = matrix.addVertexMap(of: Int.self)
        #expect(matrix[names, of: 1] == nil)
        matrix[names, of: 1] = 7
        #expect(matrix[names, ofVertexAt: 1] == 7)
    }

    @Test("Szudzik offsets: values keep their cells across appendVertex past 64 vertices, and new cells read the default")
    func growthKeepsValues() {
        var matrix = AdjacencyMatrix(vertexCount: 3)
        let weights = matrix.addEdgeMap(default: -1)
        let names = matrix.addVertexMap(default: "")
        var expected: [DirectedEdge<Int>: Int] = [:]
        func set(_ s: Int, _ t: Int) {
            matrix.insert(edge: DirectedEdge(from: s, to: t))
            let p = matrix.outEdges(of: s).first { $0.target == t }!
            matrix[weights, ofEdgeAt: p] = s * 1000 + t
            expected[DirectedEdge(from: s, to: t)] = s * 1000 + t
        }
        set(0, 2)
        set(2, 0)
        set(1, 1)
        set(2, 2)
        matrix[names, of: 2] = "two"
        for _ in 0 ..< 70 {
            let v = matrix.appendVertex()
            #expect(matrix[names, of: v] == "")
            set(v, 0)
            set(0, v)
            if v % 7 == 0 { set(v, v) }
        }
        // Every edge, new or old, has exactly its own value; no cell moved.
        for p in matrix.edges.indices {
            let edge = matrix.edges[p]
            #expect(matrix[weights, ofEdgeAt: p] == expected[edge], "\(edge)")
        }
        #expect(matrix.edgeCount == expected.count)
        #expect(matrix[names, of: 2] == "two")
        // An edge inserted where none was set reads the default.
        matrix.insert(edge: DirectedEdge(from: 70, to: 69))
        #expect(matrix[weights, ofEdgeAt: matrix.outEdges(of: 70).first { $0.target == 69 }!] == -1)
        // values(of:) agrees with the subscript at every edge.
        let values = matrix.values(of: weights)
        for p in matrix.edges.indices { #expect(values[p] == matrix[weights, ofEdgeAt: p]) }
        #expect(values.defaultValue == -1)
    }

    @Test("Every removal path sets the removed cells back to the default; an edge inserted there later reads the default")
    func removalResetsCells() {
        // Each step removes some edges of the complete 5-vertex matrix with loops, whose every cell
        // was given the value s·10 + t; then every edge is re-inserted and the cells read.
        let steps: [(String, (inout AdjacencyMatrix) -> Void)] = [
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 1, to: 3)) }),
            ("subscript false", { $0[3, 1] = false }),
            ("toggle", { $0[2, 2].toggle() }),
            ("removeEdges(from:)", { _ = $0.removeEdges(from: 4) }),
            ("removeEdges(to:)", { _ = $0.removeEdges(to: 0) }),
            ("removeEdges(incidentTo:)", { _ = $0.removeEdges(incidentTo: 2) }),
            ("formIntersection", { $0.formIntersection(AdjacencyMatrix(vertexCount: 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 4, to: 4)])) }),
            ("subtract", { $0.subtract(AdjacencyMatrix(vertexCount: 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 3, to: 4)])) }),
            ("formSymmetricDifference", { $0.formSymmetricDifference(AdjacencyMatrix(vertexCount: 5, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 4, to: 0)])) }),
            ("formUnion (removes nothing)", { $0.formUnion(AdjacencyMatrix(vertexCount: 5, edges: [DirectedEdge(from: 1, to: 2)])) }),
            ("removeAllEdges()", { $0.removeAllEdges() }),
            ("removeAllEdges(keepingCapacity: true)", { $0.removeAllEdges(keepingCapacity: true) }),
        ]
        for (name, step) in steps {
            var matrix = AdjacencyMatrix(vertexCount: 5, repeating: true)
            let weights = matrix.addEdgeMap(default: -1)
            let other = matrix.addEdgeMap(default: "d")
            for p in matrix.edges.indices {
                matrix[weights, ofEdgeAt: p] = p.source * 10 + p.target
                matrix[other, ofEdgeAt: p] = "\(p.source)\(p.target)"
            }
            let before = Set(matrix.edges)
            step(&matrix)
            let after = Set(matrix.edges)
            // Survivors keep their values; new edges (symmetric difference) read the default.
            for p in matrix.edges.indices {
                let survived = before.contains(matrix.edges[p])
                #expect(matrix[weights, ofEdgeAt: p] == (survived ? p.source * 10 + p.target : -1), "\(name) \(p)")
                #expect(matrix[other, ofEdgeAt: p] == (survived ? "\(p.source)\(p.target)" : "d"), "\(name) \(p)")
            }
            // Removed cells were reset: re-inserting them reads the default.
            for edge in before.subtracting(after) { matrix.insert(edge: edge) }
            for p in matrix.edges.indices where !after.contains(matrix.edges[p]) {
                #expect(matrix[weights, ofEdgeAt: p] == -1, "\(name) \(p)")
                #expect(matrix[other, ofEdgeAt: p] == "d", "\(name) \(p)")
            }
            #expect(matrix.edgeCount == before.union(after).count, "\(name)")
        }
    }

    @Test("Removals past the first word of a row reset the right cells")
    func removalsPastOneWord() {
        let steps: [(String, (inout AdjacencyMatrix) -> Void)] = [
            ("removeEdges(from:)", { _ = $0.removeEdges(from: 3) }),
            ("removeEdges(to:)", { _ = $0.removeEdges(to: 100) }),
            ("subtract", { $0.subtract(AdjacencyMatrix(vertexCount: 130, edges: [DirectedEdge(from: 3, to: 100), DirectedEdge(from: 129, to: 70)])) }),
            ("formIntersection", { $0.formIntersection(AdjacencyMatrix(vertexCount: 130, edges: [DirectedEdge(from: 3, to: 1)])) }),
        ]
        for (name, step) in steps {
            var matrix = AdjacencyMatrix(vertexCount: 130, edges: [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 3, to: 70), DirectedEdge(from: 3, to: 100), DirectedEdge(from: 3, to: 129), DirectedEdge(from: 129, to: 70), DirectedEdge(from: 64, to: 100)])
            let weights = matrix.addEdgeMap(default: 0)
            for p in matrix.edges.indices { matrix[weights, ofEdgeAt: p] = p.source * 1000 + p.target }
            let before = Set(matrix.edges)
            step(&matrix)
            let after = Set(matrix.edges)
            for p in matrix.edges.indices { #expect(matrix[weights, ofEdgeAt: p] == p.source * 1000 + p.target, "\(name) \(p)") }
            for edge in before.subtracting(after) { matrix.insert(edge: edge) }
            for p in matrix.edges.indices where !after.contains(matrix.edges[p]) { #expect(matrix[weights, ofEdgeAt: p] == 0, "\(name) \(p)") }
            #expect(before != after, "\(name)")
        }
    }

    @Test("A removed edge has no value: the checked read throws EdgeNotFound, as for a cell out of range")
    func checkedEdgeReads() throws {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let weights = matrix.addEdgeMap(default: 0.5)
        let p = matrix.edges.firstIndex(of: DirectedEdge(from: 1, to: 2))!
        matrix[weights, ofEdgeAt: p] = 9
        #expect(try matrix[weights, checkedEdgeAt: p] == 9)
        matrix.remove(edge: DirectedEdge(from: 1, to: 2))
        #expect(throws: EdgeNotFound.self) { try matrix[weights, checkedEdgeAt: p] }
        #expect((try? matrix[weights, checkedEdgeAt: p]) == nil)
        // A position past the matrix after removeAll throws too.
        matrix.removeAll()
        let q = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1)]).edges.startIndex
        #expect(throws: EdgeNotFound.self) { try matrix[weights, checkedEdgeAt: q] }
    }

    @Test("Vertex maps: one value per vertex, by vertex or position; appended vertices read the default; checked reads throw VertexNotFound")
    func vertexMaps() throws {
        var matrix = AdjacencyMatrix(vertexCount: 2)
        let names = matrix.addVertexMap(default: "?")
        let ranks = matrix.addVertexMap(default: 0)
        matrix[names, of: 0] = "a"
        matrix[ranks, ofVertexAt: 1] = 5
        let v = matrix.appendVertex()
        #expect(v == 2)
        #expect(matrix[names, of: 0] == "a" && matrix[names, of: 1] == "?" && matrix[names, of: 2] == "?")
        #expect(matrix[ranks, of: 1] == 5 && matrix[ranks, ofVertexAt: 2] == 0)
        #expect(try matrix[names, checked: 0] == "a")
        #expect(try matrix[ranks, checkedVertexAt: 1] == 5)
        #expect(throws: VertexNotFound.self) { try matrix[names, checked: 3] }
        #expect(throws: VertexNotFound.self) { try matrix[names, checked: -1] }
        #expect(throws: VertexNotFound.self) { try matrix[ranks, checkedVertexAt: 3] }
        let snapshot = matrix.values(of: names)
        #expect((0 ..< 3).map { snapshot[$0] } == ["a", "?", "?"])
        #expect(snapshot.defaultValue == "?")
        // Edge removals leave vertex maps alone.
        matrix.insert(edge: DirectedEdge(from: 2, to: 0))
        matrix.removeAllEdges()
        #expect(matrix[names, of: 0] == "a" && matrix[ranks, of: 1] == 5)
    }

    @Test("removeAll keeps every map attached and empty; new vertices and edges read the defaults")
    func removeAllKeepsMaps() {
        for keepingCapacity in [false, true] {
            var matrix = AdjacencyMatrix(vertexCount: 3, repeating: true)
            let weights = matrix.addEdgeMap(default: 0)
            let names = matrix.addVertexMap(default: "")
            for p in matrix.edges.indices { matrix[weights, ofEdgeAt: p] = 1 }
            matrix[names, of: 2] = "x"
            matrix.removeAll(keepingCapacity: keepingCapacity)
            #expect(matrix.vertexCount == 0 && matrix.edgeCount == 0)
            for _ in 0 ..< 3 { matrix.appendVertex() }
            matrix.insert(edge: DirectedEdge(from: 2, to: 1))
            #expect(matrix[weights, ofEdgeAt: matrix.edges.startIndex] == 0)
            #expect(matrix[names, of: 2] == "")
        }
    }

    @Test("reserveCapacity changes no value")
    func reserve() {
        var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 1, to: 0)])
        let weights = matrix.addEdgeMap(default: 0)
        let names = matrix.addVertexMap(default: 0)
        matrix[weights, ofEdgeAt: matrix.edges.startIndex] = 4
        matrix[names, of: 1] = 3
        matrix.reserveCapacity(vertexCount: 200)
        #expect(matrix[weights, ofEdgeAt: matrix.edges.startIndex] == 4 && matrix[names, of: 1] == 3)
        for _ in 0 ..< 100 { matrix.appendVertex() }
        #expect(matrix[weights, ofEdgeAt: matrix.edges.startIndex] == 4 && matrix[names, of: 101] == 0)
    }

    @Test("Several maps are independent; removeEdgeMap detaches one and leaves the others")
    func severalMaps() {
        var matrix = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        let a = matrix.addEdgeMap(default: 1)
        let b = matrix.addEdgeMap(default: 2)
        let c = matrix.addEdgeMap(default: 3)
        let p = matrix.edges.startIndex
        matrix[a, ofEdgeAt: p] = 10
        matrix[c, ofEdgeAt: p] = 30
        matrix.removeEdgeMap(b)
        #expect(matrix[a, ofEdgeAt: p] == 10 && matrix[c, ofEdgeAt: p] == 30)
        let d = matrix.addEdgeMap(default: 4)
        #expect(matrix[d, ofEdgeAt: p] == 4 && matrix[c, ofEdgeAt: p] == 30)
        #expect(a != c && a == a)
        let names = matrix.addVertexMap(default: 0)
        matrix.removeVertexMap(names)
        let ranks = matrix.addVertexMap(default: 9)
        #expect(matrix[ranks, of: 1] == 9)
    }

    @Test("A copy carries the maps, copy-on-write: writes and removals on one leave the other's values")
    func copies() {
        var original = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let weights = original.addEdgeMap(default: 0)
        let names = original.addVertexMap(default: "")
        let p01 = original.edges.firstIndex(of: DirectedEdge(from: 0, to: 1))!
        let p12 = original.edges.firstIndex(of: DirectedEdge(from: 1, to: 2))!
        original[weights, ofEdgeAt: p01] = 1
        original[weights, ofEdgeAt: p12] = 2
        original[names, of: 0] = "zero"
        var copy = original
        copy[weights, ofEdgeAt: p01] = 100
        copy[names, of: 0] = "copy"
        copy.remove(edge: DirectedEdge(from: 1, to: 2))
        #expect(original[weights, ofEdgeAt: p01] == 1 && original[weights, ofEdgeAt: p12] == 2)
        #expect(original[names, of: 0] == "zero")
        #expect(copy[weights, ofEdgeAt: p01] == 100 && copy[names, of: 0] == "copy")
        copy.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(copy[weights, ofEdgeAt: p12] == 0 && original[weights, ofEdgeAt: p12] == 2)
        // A snapshot does not see later writes.
        let snapshot = original.values(of: weights)
        original[weights, ofEdgeAt: p01] = 50
        #expect(snapshot[p01] == 1 && original.values(of: weights)[p01] == 50)
    }

    @Test("A copy that attaches or removes a map, or writes one, leaves the original's later removals and insertions to the original")
    func copyReplacesTable() {
        let triggers: [(String, (inout AdjacencyMatrix, EdgeMap<Int>) -> Void)] = [
            ("addEdgeMap", { matrix, _ in _ = matrix.addEdgeMap(default: "x") }),
            ("addVertexMap", { matrix, _ in _ = matrix.addVertexMap(default: 0) }),
            ("removeEdgeMap", { matrix, cost in matrix.removeEdgeMap(cost) }),
            ("a map write", { matrix, cost in matrix[cost, ofEdgeAt: matrix.edges.startIndex] = 7 }),
        ]
        let mutations: [(String, (inout AdjacencyMatrix) -> Void)] = [
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 0, to: 1)) }),
            ("removeEdges(from:)", { _ = $0.removeEdges(from: 0) }),
            ("removeEdges(to:)", { _ = $0.removeEdges(to: 1) }),
            ("removeEdges(incidentTo:)", { _ = $0.removeEdges(incidentTo: 0) }),
            ("appendVertex", { _ = $0.appendVertex() }),
            ("removeAllEdges", { $0.removeAllEdges() }),
        ]
        for (trigger, replace) in triggers {
            for (name, mutate) in mutations {
                var matrix = AdjacencyMatrix(vertexCount: 3)
                _ = matrix.insert(edge: DirectedEdge(from: 0, to: 1))
                let cost = matrix.addEdgeMap(default: 0)
                let p = matrix.edges.startIndex
                matrix[cost, ofEdgeAt: p] = 99
                var copy = matrix
                replace(&copy, cost)
                mutate(&matrix)
                #expect(copy.contains(edge: DirectedEdge(from: 0, to: 1)), "\(trigger) on the copy, then \(name)")
                if trigger != "removeEdgeMap" {
                    #expect(copy[cost, ofEdgeAt: p] == (trigger == "a map write" ? 7 : 99), "\(trigger) on the copy, then \(name)")
                }
            }
        }
    }

    @Test("Whole-matrix results: union and friends carry this matrix's maps; complement and transposed carry none")
    func derivedMatrices() {
        var matrix = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let weights = matrix.addEdgeMap(default: 0)
        let p01 = matrix.edges.firstIndex(of: DirectedEdge(from: 0, to: 1))!
        let p12 = matrix.edges.firstIndex(of: DirectedEdge(from: 1, to: 2))!
        matrix[weights, ofEdgeAt: p01] = 7
        matrix[weights, ofEdgeAt: p12] = 8
        let other = AdjacencyMatrix(vertexCount: 3, edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let union = matrix.union(other)
        #expect(union[weights, ofEdgeAt: p01] == 7 && union[weights, ofEdgeAt: p12] == 8)
        #expect(union[weights, ofEdgeAt: union.edges.firstIndex(of: DirectedEdge(from: 2, to: 0))!] == 0)
        let intersection = matrix.intersection(other)
        #expect(Array(intersection.edges) == [DirectedEdge(from: 1, to: 2)])
        #expect(intersection[weights, ofEdgeAt: p12] == 8)
        let difference = matrix.subtracting(other)
        #expect(difference[weights, ofEdgeAt: p01] == 7)
        var regrown = difference
        regrown.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(regrown[weights, ofEdgeAt: p12] == 0)
        let symmetric = matrix.symmetricDifference(other)
        #expect(symmetric[weights, ofEdgeAt: p01] == 7)
        #expect(symmetric[weights, ofEdgeAt: symmetric.edges.firstIndex(of: DirectedEdge(from: 2, to: 0))!] == 0)
        // The original is unchanged by the derived results.
        #expect(matrix[weights, ofEdgeAt: p12] == 8)
        // A complement or transpose is a new graph: the handle is not attached to it.
        var complement = matrix.complement()
        _ = complement.addEdgeMap(default: 1)
        let fresh = complement.addEdgeMap(default: "c")
        #expect(complement[fresh, ofEdgeAt: complement.edges.startIndex] == "c")
        var transposed = matrix.transposed()
        let t = transposed.addEdgeMap(default: 2)
        #expect(transposed[t, ofEdgeAt: transposed.edges.firstIndex(of: DirectedEdge(from: 1, to: 0))!] == 2)
    }

    @Test("Equality, hashing and Codable ignore maps; a decoded matrix has none")
    func valueSemantics() throws {
        var a = AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)])
        let b = a
        let weights = a.addEdgeMap(default: 0)
        a[weights, ofEdgeAt: a.edges.startIndex] = 5
        #expect(a == b && a.hashValue == b.hashValue)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(a)
        #expect(try encoder.encode(b) == data)
        var decoded = try JSONDecoder().decode(AdjacencyMatrix.self, from: data)
        #expect(decoded == a)
        let fresh = decoded.addEdgeMap(default: 3)
        #expect(decoded[fresh, ofEdgeAt: decoded.edges.startIndex] == 3)
        #expect(a.description == b.description)
    }

    @Test("values(of:) reads the cells' values by position, as an algorithm's weight closure")
    func valuesAsWeights() {
        var matrix = AdjacencyMatrix(vertexCount: 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 3)])
        let weights = matrix.addEdgeMap(default: 1.0)
        matrix[weights, ofEdgeAt: matrix.edges.firstIndex(of: DirectedEdge(from: 0, to: 1))!] = 10
        let w = matrix.values(of: weights)
        let viaMap = matrix.edges.indices.map { w[$0] }
        #expect(viaMap == [10, 1, 1, 1, 1])
        var total = 0.0
        for v in matrix.vertices { for p in matrix.outEdges(of: v) { total += w[p] } }
        #expect(total == 14)
    }
}
