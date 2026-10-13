// Attached maps (`PropertyGraph`) on both representations: a value per vertex index and per
// hyperedge position, the default for every element until it is set and for every new element
// (vertices inserted by a hyperedge's insertion included), reads by index, by vertex and through
// `values(of:)`, the checked reads, `removeAll` emptying the maps and keeping them attached,
// several maps and removed maps, copy-on-write, `reversed` carrying the maps, and equality,
// hashing and `Codable` ignoring them. Hand-written: the catalog (cases.md) models the storage
// against XGI and HyperNetX, which have no attached maps. See README.md.

import Foundation
import GraphProtocols
import Hypergraphs
import Testing

@Suite("Hypergraphs attached maps")
struct HypergraphMapTests {
    @Test("Undirected: defaults, values by position, index and vertex; new elements get the default")
    func undirectedValues() throws {
        var hypergraph = UndirectedIncidenceList(hyperedges: [["a", "b"], ["b", "c"], []])
        let weights = hypergraph.addEdgeMap(default: 1.5)
        let colors = hypergraph.addVertexMap(default: 7)
        #expect((0 ..< 3).map { hypergraph[weights, ofEdgeAt: $0] } == [1.5, 1.5, 1.5])
        #expect((0 ..< 3).map { hypergraph[colors, ofVertexAt: $0] } == [7, 7, 7])
        hypergraph[weights, ofEdgeAt: 1] = 4
        hypergraph[colors, of: "c"] = 2
        hypergraph[colors, ofVertexAt: 0] = 9
        #expect((0 ..< 3).map { hypergraph[weights, ofEdgeAt: $0] } == [1.5, 4, 1.5])
        #expect(["a", "b", "c"].map { hypergraph[colors, of: $0] } == [9, 7, 2])
        #expect((0 ..< 3).map { hypergraph[colors, ofVertexAt: $0] } == [9, 7, 2])

        // A new vertex and a new hyperedge with two new members: the default, at their places.
        hypergraph.insert("d")
        #expect(hypergraph.insert(hyperedge: ["e", "a", "f"]) == 3)
        #expect(hypergraph.vertexCount == 6 && hypergraph.hyperedgeCount == 4)
        #expect((0 ..< 6).map { hypergraph[colors, ofVertexAt: $0] } == [9, 7, 2, 7, 7, 7])
        #expect((0 ..< 4).map { hypergraph[weights, ofEdgeAt: $0] } == [1.5, 4, 1.5, 1.5])
        // A vertex already present and a checked insertion that throws add nothing.
        hypergraph.insert("a")
        #expect(throws: VertexNotFound.self) { try hypergraph.insert(checked: ["a", "q"]) }
        #expect(try hypergraph.insert(checked: ["f", "b"]) == 4)
        #expect((0 ..< 6).map { hypergraph[colors, ofVertexAt: $0] } == [9, 7, 2, 7, 7, 7])
        #expect((0 ..< 5).map { hypergraph[weights, ofEdgeAt: $0] } == [1.5, 4, 1.5, 1.5, 1.5])
        hypergraph[weights, ofEdgeAt: 4] = -1
        hypergraph[colors, of: "f"] = 0

        // The snapshots read the same values, and later writes do not show through them.
        let w = hypergraph.values(of: weights), c = hypergraph.values(of: colors)
        #expect(w.defaultValue == 1.5 && c.defaultValue == 7)
        #expect((0 ..< 5).map { w[$0] } == [1.5, 4, 1.5, 1.5, -1])
        #expect((0 ..< 6).map { c[$0] } == [9, 7, 2, 7, 7, 0])
        hypergraph[weights, ofEdgeAt: 0] = 100
        #expect(w[0] == 1.5 && hypergraph[weights, ofEdgeAt: 0] == 100)

        // Checked reads answer for every element and throw outside.
        #expect(try hypergraph[weights, checkedEdgeAt: 4] == -1)
        #expect(try hypergraph[colors, checkedVertexAt: 5] == 0)
        #expect(try hypergraph[colors, checked: "c"] == 2)
        #expect(throws: EdgeNotFound.self) { try hypergraph[weights, checkedEdgeAt: 5] }
        #expect(throws: EdgeNotFound.self) { try hypergraph[weights, checkedEdgeAt: -1] }
        #expect(throws: VertexNotFound.self) { try hypergraph[colors, checkedVertexAt: 6] }
        #expect(throws: VertexNotFound.self) { try hypergraph[colors, checkedVertexAt: -1] }
        #expect(throws: VertexNotFound.self) { try hypergraph[colors, checked: "q"] }
    }

    @Test("Directed: defaults, values by position, index and vertex; new elements get the default")
    func directedValues() throws {
        var hypergraph = IncidenceList(hyperedges: [(sources: ["a"], targets: ["b", "c"]), (sources: [], targets: [])])
        let weights = hypergraph.addEdgeMap(default: 0)
        let names = hypergraph.addVertexMap(of: String.self)
        #expect((0 ..< 2).map { hypergraph[weights, ofEdgeAt: $0] } == [0, 0])
        #expect((0 ..< 3).map { hypergraph[names, ofVertexAt: $0] } == [nil, nil, nil])
        hypergraph[weights, ofEdgeAt: 0] = 5
        hypergraph[names, of: "b"] = "bee"
        // Two new vertices, sources before targets, and the new hyperedge: defaults.
        #expect(hypergraph.insert(sources: ["e", "a"], targets: ["d"]) == 2)
        #expect(Array(hypergraph.vertices) == ["a", "b", "c", "e", "d"])
        #expect((0 ..< 5).map { hypergraph[names, ofVertexAt: $0] } == [nil, "bee", nil, nil, nil])
        #expect((0 ..< 3).map { hypergraph[weights, ofEdgeAt: $0] } == [5, 0, 0])
        hypergraph.insert("f")
        hypergraph.insert("a")
        #expect(throws: VertexNotFound.self) { try hypergraph.insert(checked: ["a"], targets: ["q"]) }
        #expect(try hypergraph.insert(checked: ["f"], targets: ["a"]) == 3)
        #expect((0 ..< 6).map { hypergraph[names, ofVertexAt: $0] } == [nil, "bee", nil, nil, nil, nil])
        #expect((0 ..< 4).map { hypergraph[weights, ofEdgeAt: $0] } == [5, 0, 0, 0])
        hypergraph[names, ofVertexAt: 5] = "eff"
        hypergraph[names, of: "b"] = nil
        hypergraph[weights, ofEdgeAt: 3] = 8
        #expect(["a", "b", "c", "e", "d", "f"].map { hypergraph[names, of: $0] } == [nil, nil, nil, nil, nil, "eff"])

        let w = hypergraph.values(of: weights), n = hypergraph.values(of: names)
        #expect((0 ..< 4).map { w[$0] } == [5, 0, 0, 8] && w.defaultValue == 0)
        #expect(n[5] == "eff" && n[1] == nil && n.defaultValue == nil)

        #expect(try hypergraph[weights, checkedEdgeAt: 3] == 8)
        #expect(try hypergraph[names, checkedVertexAt: 5] == "eff")
        #expect(try hypergraph[names, checked: "f"] == "eff")
        #expect(throws: EdgeNotFound.self) { try hypergraph[weights, checkedEdgeAt: 4] }
        #expect(throws: EdgeNotFound.self) { try hypergraph[weights, checkedEdgeAt: -1] }
        #expect(throws: VertexNotFound.self) { try hypergraph[names, checkedVertexAt: 6] }
        #expect(throws: VertexNotFound.self) { try hypergraph[names, checkedVertexAt: -1] }
        #expect(throws: VertexNotFound.self) { try hypergraph[names, checked: "q"] }
    }

    @Test("Undirected: removeAll empties the maps and keeps them attached; reserveCapacity keeps the values")
    func undirectedRemoveAll() {
        var hypergraph = UndirectedIncidenceList(vertices: ["a", "b"], hyperedges: [["a", "b"]])
        let weights = hypergraph.addEdgeMap(default: 2)
        let colors = hypergraph.addVertexMap(default: "x")
        hypergraph[weights, ofEdgeAt: 0] = 3
        hypergraph[colors, of: "b"] = "y"
        hypergraph.reserveCapacity(vertexCount: 100, hyperedgeCount: 100, incidenceCount: 100)
        #expect(hypergraph[weights, ofEdgeAt: 0] == 3 && hypergraph[colors, of: "b"] == "y")
        for keepingCapacity in [true, false] {
            hypergraph.removeAll(keepingCapacity: keepingCapacity)
            #expect(throws: EdgeNotFound.self) { try hypergraph[weights, checkedEdgeAt: 0] }
            #expect(throws: VertexNotFound.self) { try hypergraph[colors, checked: "b"] }
            #expect(hypergraph.insert(hyperedge: ["b", "c"]) == 0)
            #expect(hypergraph[weights, ofEdgeAt: 0] == 2)
            #expect(hypergraph[colors, of: "b"] == "x" && hypergraph[colors, of: "c"] == "x")
            hypergraph[weights, ofEdgeAt: 0] = 3
            hypergraph[colors, of: "b"] = "y"
        }
    }

    @Test("Directed: removeAll empties the maps and keeps them attached; reserveCapacity keeps the values")
    func directedRemoveAll() {
        var hypergraph = IncidenceList(vertices: ["a", "b"], hyperedges: [(sources: ["a"], targets: ["b"])])
        let weights = hypergraph.addEdgeMap(default: 2)
        let colors = hypergraph.addVertexMap(default: "x")
        hypergraph[weights, ofEdgeAt: 0] = 3
        hypergraph[colors, of: "b"] = "y"
        hypergraph.reserveCapacity(vertexCount: 100, hyperedgeCount: 100, sourceCount: 100, targetCount: 100)
        #expect(hypergraph[weights, ofEdgeAt: 0] == 3 && hypergraph[colors, of: "b"] == "y")
        for keepingCapacity in [true, false] {
            hypergraph.removeAll(keepingCapacity: keepingCapacity)
            #expect(throws: EdgeNotFound.self) { try hypergraph[weights, checkedEdgeAt: 0] }
            #expect(throws: VertexNotFound.self) { try hypergraph[colors, checked: "b"] }
            #expect(hypergraph.insert(sources: ["b"], targets: ["c"]) == 0)
            #expect(hypergraph[weights, ofEdgeAt: 0] == 2)
            #expect(hypergraph[colors, of: "b"] == "x" && hypergraph[colors, of: "c"] == "x")
            hypergraph[weights, ofEdgeAt: 0] = 3
            hypergraph[colors, of: "b"] = "y"
        }
    }

    @Test("Undirected: several maps, a removed map, copy-on-write, and reference values")
    func undirectedSeveralMapsAndCopies() {
        final class Box: Sendable {
            let value: Int
            init(_ value: Int) { self.value = value }
        }
        var hypergraph = UndirectedIncidenceList(hyperedges: [[0, 1], [1, 2]])
        let first = hypergraph.addEdgeMap(default: 0)
        let second = hypergraph.addEdgeMap(default: "s")
        let third = hypergraph.addEdgeMap(default: Box(1))
        let vertexFirst = hypergraph.addVertexMap(default: 0.5)
        let vertexSecond = hypergraph.addVertexMap(default: Box(2))
        hypergraph[first, ofEdgeAt: 1] = 10
        hypergraph[second, ofEdgeAt: 0] = "t"
        hypergraph[third, ofEdgeAt: 1] = Box(3)
        hypergraph[vertexSecond, of: 2] = Box(4)
        // Removing the first maps moves the others in the table; their handles search past the
        // stale hint.
        hypergraph.removeEdgeMap(first)
        hypergraph.removeVertexMap(vertexFirst)
        #expect(hypergraph[second, ofEdgeAt: 0] == "t" && hypergraph[third, ofEdgeAt: 1].value == 3)
        #expect(hypergraph[third, ofEdgeAt: 0].value == 1 && hypergraph[vertexSecond, of: 2].value == 4)
        // A map attached after the removals.
        let fourth = hypergraph.addEdgeMap(default: 4)
        #expect(hypergraph[fourth, ofEdgeAt: 1] == 4)

        // A copy shares the values until one of them writes or grows.
        let copy = hypergraph
        hypergraph[second, ofEdgeAt: 0] = "u"
        hypergraph.insert(hyperedge: [3])
        hypergraph[third, ofEdgeAt: 2] = Box(5)
        hypergraph[vertexSecond, of: 3] = Box(6)
        #expect(copy[second, ofEdgeAt: 0] == "t" && copy.hyperedgeCount == 2)
        #expect(throws: EdgeNotFound.self) { try copy[third, checkedEdgeAt: 2] }
        #expect(throws: VertexNotFound.self) { try copy[vertexSecond, checked: 3] }
        #expect(hypergraph[second, ofEdgeAt: 0] == "u" && hypergraph[second, ofEdgeAt: 2] == "s")
        #expect(hypergraph[third, ofEdgeAt: 2].value == 5 && hypergraph[vertexSecond, of: 3].value == 6)
        var other = copy
        other[fourth, ofEdgeAt: 0] = 40
        #expect(copy[fourth, ofEdgeAt: 0] == 4 && other[fourth, ofEdgeAt: 0] == 40 && hypergraph[fourth, ofEdgeAt: 0] == 4)
    }

    @Test("Directed: several maps, a removed map, copy-on-write; reversed carries the maps")
    func directedSeveralMapsCopiesAndReversal() {
        var hypergraph = IncidenceList(hyperedges: [(sources: [0], targets: [1]), (sources: [1, 2], targets: [])])
        let first = hypergraph.addVertexMap(default: 0)
        let second = hypergraph.addVertexMap(default: 1)
        let weights = hypergraph.addEdgeMap(default: 1.0)
        hypergraph[second, of: 2] = 20
        hypergraph[weights, ofEdgeAt: 1] = 3
        hypergraph.removeVertexMap(first)
        #expect((0 ..< 3).map { hypergraph[second, ofVertexAt: $0] } == [1, 1, 20])

        // Reversal keeps the positions, so the handles read the same values.
        var reversed = hypergraph.reversed
        #expect(Array(reversed.sources(ofHyperedgeAt: 0)) == [1])
        #expect(reversed[weights, ofEdgeAt: 1] == 3 && reversed[second, of: 2] == 20)
        reversed[weights, ofEdgeAt: 0] = 9
        reversed.insert(sources: [3], targets: [0])
        #expect(reversed[weights, ofEdgeAt: 2] == 1 && reversed[second, of: 3] == 1)
        #expect(hypergraph[weights, ofEdgeAt: 0] == 1 && hypergraph.hyperedgeCount == 2)
        #expect(hypergraph.reversed.reversed[weights, ofEdgeAt: 1] == 3)

        let copy = hypergraph
        hypergraph[second, ofVertexAt: 0] = 5
        hypergraph.insert(4)
        #expect(copy[second, ofVertexAt: 0] == 1 && copy.vertexCount == 3)
        #expect(hypergraph[second, ofVertexAt: 0] == 5 && hypergraph[second, of: 4] == 1)
    }

    @Test("Maps attached to an empty hypergraph grow with it")
    func attachedWhenEmpty() {
        var undirected = UndirectedIncidenceList<Int>()
        let u = undirected.addEdgeMap(default: -1)
        let uv = undirected.addVertexMap(default: -2)
        for k in 0 ..< 50 { undirected.insert(hyperedge: [k, k + 1]) }
        #expect((0 ..< 50).allSatisfy { undirected[u, ofEdgeAt: $0] == -1 })
        #expect((0 ... 50).allSatisfy { undirected[uv, of: $0] == -2 })

        var directed = IncidenceList<Int>()
        let d = directed.addEdgeMap(default: -1)
        let dv = directed.addVertexMap(default: -2)
        for k in 0 ..< 50 { directed.insert(sources: [k], targets: [k + 1, k + 2]) }
        #expect((0 ..< 50).allSatisfy { directed[d, ofEdgeAt: $0] == -1 })
        #expect((0 ... 51).allSatisfy { directed[dv, of: $0] == -2 })
    }

    @Test("Equality, hashing, descriptions and Codable ignore the maps")
    func valueSemanticsIgnoreMaps() throws {
        var undirected = UndirectedIncidenceList(hyperedges: [["a", "b"]])
        let plain = undirected
        let colors = undirected.addVertexMap(default: 1)
        undirected[colors, of: "a"] = 2
        #expect(undirected == plain && undirected.hashValue == plain.hashValue)
        #expect(undirected.description == plain.description && undirected.debugDescription == plain.debugDescription)
        let decoded = try JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: JSONEncoder().encode(undirected))
        #expect(decoded == undirected)
        // Sorted keys: a keyed container's key order is otherwise unspecified.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(try encoder.encode(undirected) == encoder.encode(plain))
        // The conversion of the same type returns the hypergraph itself, maps included.
        #expect(UndirectedIncidenceList(undirected)[colors, of: "a"] == 2)

        var directed = IncidenceList(hyperedges: [(sources: ["a"], targets: ["b"])])
        let plainDirected = directed
        let weights = directed.addEdgeMap(default: 1)
        directed[weights, ofEdgeAt: 0] = 2
        #expect(directed == plainDirected && directed.hashValue == plainDirected.hashValue)
        #expect(directed.description == plainDirected.description)
        #expect(try encoder.encode(directed) == encoder.encode(plainDirected))
        #expect(IncidenceList(directed)[weights, ofEdgeAt: 0] == 2)
    }
}
