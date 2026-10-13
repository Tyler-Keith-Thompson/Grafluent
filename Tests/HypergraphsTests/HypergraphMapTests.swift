// Attached maps (`PropertyGraph`) on both representations: a value per vertex index and per
// hyperedge position, the default for every element until it is set and for every new element
// (vertices inserted by a hyperedge's insertion included), reads by index, by vertex and through
// `values(of:)`, the checked reads, `removeAll` emptying the maps and keeping them attached,
// several maps and removed maps, copy-on-write (two copies, whichever mutates first, keep their own
// values), `reversed` carrying the maps, and equality, hashing and `Codable` ignoring them.
// Hand-written: the catalog (cases.md) does not cover the maps. See README.md.

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

    @Test("Both: two copies keep their own values whichever mutates first, every mutation on one then every mutation on the other")
    func copiesMutatedInTurn() {
        // One hyperedge map of Ints (the one-map fast paths of the upkeep) and a vertex map. Each
        // copy's values must be what its own mutation alone gives a fresh hypergraph, and so after
        // a further insertion on each.
        func undirected() -> (UndirectedIncidenceList<Int>, EdgeMap<Int>, VertexMap<Double>) {
            var hypergraph = UndirectedIncidenceList<Int>(vertices: 0 ..< 4)
            let weights = hypergraph.addEdgeMap(default: -1)
            let ranks = hypergraph.addVertexMap(default: 0.5)
            for members in [[0, 1], [1, 2, 3], [3]] { hypergraph.insert(hyperedge: members) }
            for p in 0 ..< hypergraph.hyperedgeCount { hypergraph[weights, ofEdgeAt: p] = 10 * p + 1 }
            for v in 0 ..< 4 { hypergraph[ranks, of: v] = Double(v) }
            return (hypergraph, weights, ranks)
        }
        let undirectedSteps: [(String, (inout UndirectedIncidenceList<Int>, EdgeMap<Int>, VertexMap<Double>) -> Void)] = [
            ("insert(_:)", { h, _, _ in h.insert(9) }),
            ("insert(hyperedge:)", { h, _, _ in h.insert(hyperedge: [0, 2]) }),
            ("insert(hyperedge:) with new vertices", { h, _, _ in h.insert(hyperedge: [1, 7, 8]) }),
            ("insert(checked:)", { h, _, _ in _ = try? h.insert(checked: [2, 3]) }),
            ("reserveCapacity", { h, _, _ in h.reserveCapacity(vertexCount: 64, hyperedgeCount: 64, incidenceCount: 256) }),
            ("removeAll", { h, _, _ in h.removeAll() }),
            ("removeAll(keepingCapacity: true)", { h, _, _ in h.removeAll(keepingCapacity: true) }),
            ("a hyperedge value written", { h, w, _ in h[w, ofEdgeAt: 1] = -7 }),
            ("a vertex value written", { h, _, r in h[r, of: 0] = -7 }),
        ]
        // Each map holds one value per element, and every value is its element's own (set by
        // `undirected()` and `directed()`), the default or the written -7.
        func undirectedState(_ h: UndirectedIncidenceList<Int>, _ w: EdgeMap<Int>, _ r: VertexMap<Double>) -> [String] {
            let values = (0 ..< h.hyperedgeCount).map { "\(Array(h.members(ofHyperedgeAt: $0)))=\(h[w, ofEdgeAt: $0])" } + h.vertices.map { "\($0)=\(h[r, of: $0])" }
            let own = (0 ..< h.hyperedgeCount).allSatisfy { [10 * $0 + 1, -1, -7].contains(h[w, ofEdgeAt: $0]) } && h.vertices.allSatisfy { [Double($0), 0.5, -7].contains(h[r, of: $0]) }
            let counts = h.values(of: w)._storage.dense.count == h.hyperedgeCount && h.values(of: r)._storage.dense.count == h.vertexCount
            return values + ["own values: \(own)", "one value per element: \(counts)"]
        }
        func undirectedReplay(_ names: [String]) -> [String] {
            var (h, w, r) = undirected()
            for name in names { undirectedSteps.first { $0.0 == name }!.1(&h, w, r) }
            return undirectedState(h, w, r)
        }
        for (first, a) in undirectedSteps {
            for (second, b) in undirectedSteps {
                for firstOnCopy in [true, false] {
                    var (original, w, r) = undirected()
                    var copy = original
                    if firstOnCopy { a(&copy, w, r); b(&original, w, r) } else { a(&original, w, r); b(&copy, w, r) }
                    let label = "undirected: \(first) on the \(firstOnCopy ? "copy" : "original"), then \(second) on the other"
                    #expect(undirectedState(firstOnCopy ? copy : original, w, r) == undirectedReplay([first]), "\(label): the first")
                    #expect(undirectedState(original, w, r).suffix(2) == ["own values: true", "one value per element: true"] && undirectedState(copy, w, r).suffix(2) == ["own values: true", "one value per element: true"], "\(label): own values")
                    #expect(undirectedState(firstOnCopy ? original : copy, w, r) == undirectedReplay([second]), "\(label): the second")
                    original.insert(hyperedge: [0, 2])
                    copy.insert(hyperedge: [0, 2])
                    let originalSteps = firstOnCopy ? [second] : [first], copySteps = firstOnCopy ? [first] : [second]
                    #expect(undirectedState(original, w, r) == undirectedReplay(originalSteps + ["insert(hyperedge:)"]), "\(label): then an insertion on the original")
                    #expect(undirectedState(copy, w, r) == undirectedReplay(copySteps + ["insert(hyperedge:)"]), "\(label): then an insertion on the copy")
                }
            }
        }

        func directed() -> (IncidenceList<Int>, EdgeMap<Int>, VertexMap<Double>) {
            var hypergraph = IncidenceList<Int>(vertices: 0 ..< 4)
            let weights = hypergraph.addEdgeMap(default: -1)
            let ranks = hypergraph.addVertexMap(default: 0.5)
            for (sources, targets) in [([0], [1]), ([1, 2], [3]), ([3], [])] { hypergraph.insert(sources: sources, targets: targets) }
            for p in 0 ..< hypergraph.hyperedgeCount { hypergraph[weights, ofEdgeAt: p] = 10 * p + 1 }
            for v in 0 ..< 4 { hypergraph[ranks, of: v] = Double(v) }
            return (hypergraph, weights, ranks)
        }
        let directedSteps: [(String, (inout IncidenceList<Int>, EdgeMap<Int>, VertexMap<Double>) -> Void)] = [
            ("insert(_:)", { h, _, _ in h.insert(9) }),
            ("insert(sources:targets:)", { h, _, _ in h.insert(sources: [0], targets: [2]) }),
            ("insert(sources:targets:) with new vertices", { h, _, _ in h.insert(sources: [1, 7], targets: [8]) }),
            ("insert(checked:targets:)", { h, _, _ in _ = try? h.insert(checked: [2], targets: [3]) }),
            ("reserveCapacity", { h, _, _ in h.reserveCapacity(vertexCount: 64, hyperedgeCount: 64, sourceCount: 256, targetCount: 256) }),
            ("removeAll", { h, _, _ in h.removeAll() }),
            ("removeAll(keepingCapacity: true)", { h, _, _ in h.removeAll(keepingCapacity: true) }),
            ("a hyperedge value written", { h, w, _ in h[w, ofEdgeAt: 1] = -7 }),
            ("a vertex value written", { h, _, r in h[r, of: 0] = -7 }),
        ]
        func directedState(_ h: IncidenceList<Int>, _ w: EdgeMap<Int>, _ r: VertexMap<Double>) -> [String] {
            let values = (0 ..< h.hyperedgeCount).map { "\(Array(h.sources(ofHyperedgeAt: $0)))→\(Array(h.targets(ofHyperedgeAt: $0)))=\(h[w, ofEdgeAt: $0])" }
                + h.vertices.map { "\($0)=\(h[r, of: $0])" }
            let own = (0 ..< h.hyperedgeCount).allSatisfy { [10 * $0 + 1, -1, -7].contains(h[w, ofEdgeAt: $0]) } && h.vertices.allSatisfy { [Double($0), 0.5, -7].contains(h[r, of: $0]) }
            let counts = h.values(of: w)._storage.dense.count == h.hyperedgeCount && h.values(of: r)._storage.dense.count == h.vertexCount
            return values + ["own values: \(own)", "one value per element: \(counts)"]
        }
        func directedReplay(_ names: [String]) -> [String] {
            var (h, w, r) = directed()
            for name in names { directedSteps.first { $0.0 == name }!.1(&h, w, r) }
            return directedState(h, w, r)
        }
        for (first, a) in directedSteps {
            for (second, b) in directedSteps {
                for firstOnCopy in [true, false] {
                    var (original, w, r) = directed()
                    var copy = original
                    if firstOnCopy { a(&copy, w, r); b(&original, w, r) } else { a(&original, w, r); b(&copy, w, r) }
                    let label = "directed: \(first) on the \(firstOnCopy ? "copy" : "original"), then \(second) on the other"
                    #expect(directedState(firstOnCopy ? copy : original, w, r) == directedReplay([first]), "\(label): the first")
                    #expect(directedState(original, w, r).suffix(2) == ["own values: true", "one value per element: true"] && directedState(copy, w, r).suffix(2) == ["own values: true", "one value per element: true"], "\(label): own values")
                    #expect(directedState(firstOnCopy ? original : copy, w, r) == directedReplay([second]), "\(label): the second")
                    original.insert(sources: [0], targets: [2])
                    copy.insert(sources: [0], targets: [2])
                    let originalSteps = firstOnCopy ? [second] : [first], copySteps = firstOnCopy ? [first] : [second]
                    #expect(directedState(original, w, r) == directedReplay(originalSteps + ["insert(sources:targets:)"]), "\(label): then an insertion on the original")
                    #expect(directedState(copy, w, r) == directedReplay(copySteps + ["insert(sources:targets:)"]), "\(label): then an insertion on the copy")
                }
            }
        }
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
