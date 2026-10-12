// Attached maps (catalog MG-212 – MG-226, `PropertyGraph`): a map's values follow their edge copy or
// vertex through every removal path (`remove(edgeAt:)`, `remove(edge:)`'s newest copy,
// `removeAllEdges(between:and:)` / `(from:to:)`, vertex removal and the slot that moves in), new
// elements read the default, `removeAllEdges()` / `removeAll()` empty the maps and keep them
// attached, the `checked` reads throw `EdgeNotFound` / `VertexNotFound`, and the multigraphs' maps
// are their base's. ref.py keys each value by its edge's insertion stamp or its vertex, and checks
// it against NetworkX's edge and node attributes. Beyond the catalog cell, each final state checks
// every attached map at every position and vertex.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs attached maps")
struct MultigraphMapTests {
    @Test("MG-212 edge map with a default: set, read, the last edge's value moves into the hole, a new edge reads the default")
    func mg212() {
        // Pseudograph V []; E [0–1, 1–2, 2–0]; let w = addEdgeMap(default: 1.5) / [w, ofEdgeAt: 0] = 2.5 / [w, ofEdgeAt: 2] = 4.0 / values(of: w) / remove(edgeAt: 0) / [w, ofEdgeAt: 0] / values(of: w) / insert(edge: UndirectedEdge(3, 3)) / values(of: w)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let w = graph.addEdgeMap(default: 1.5)
        graph[w, ofEdgeAt: 0] = 2.5
        graph[w, ofEdgeAt: 2] = 4.0
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [2.5, 1.5, 4.0]) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        #expect(graph[w, ofEdgeAt: 0] == 4.0)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [4.0, 1.5]) }
        #expect(graph.insert(edge: UndirectedEdge(3, 3)) == 2)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [4.0, 1.5, 1.5]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 2], [3, 3]])
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.neighbors(of: 0)) == [2])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [1])
        #expect(Array(graph.neighbors(of: 2)) == [1, 0])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0])
        #expect(Array(graph.neighbors(of: 3)) == [3, 3])
        #expect(Array(graph.incidentEdges(of: 3)) == [2, 2])
        #expect(Array(graph.edges(between: 2, and: 0)) == [0])
        #expect(graph.edgeCount(between: 2, and: 0) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect(Array(graph.edges(between: 3, and: 3)) == [2])
        #expect(graph.edgeCount(between: 3, and: 3) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [4.0, 1.5, 1.5])
    }

    @Test("MG-213 map of an Optional: nil until set, nil clears")
    func mg213() {
        // Pseudograph V []; E [0–1, 0–1]; let labels = addEdgeMap(of: String.self) / [labels, ofEdgeAt: 0] / [labels, ofEdgeAt: 1] = "b" / [labels, ofEdgeAt: 0] = "a" / [labels, ofEdgeAt: 1] / [labels, ofEdgeAt: 1] = nil / values(of: labels)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let labels = graph.addEdgeMap(of: String.self)
        #expect(graph[labels, ofEdgeAt: 0] == nil)
        graph[labels, ofEdgeAt: 1] = "b"
        graph[labels, ofEdgeAt: 0] = "a"
        #expect(graph[labels, ofEdgeAt: 1] == "b")
        graph[labels, ofEdgeAt: 1] = nil
        do { let values = graph.values(of: labels); #expect((0 ..< graph.edgeCount).map { values[$0] } == ["a", nil]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
        #expect((0 ..< graph.edgeCount).map { graph[labels, ofEdgeAt: $0] } == ["a", nil])
    }

    @Test("MG-214 remove(edge:) removes the newest copy's value; the moved copy keeps its own")
    func mg214() {
        // Pseudograph V []; E [0–1, 0–1, 1–2, 0–1]; let labels = addEdgeMap(of: String.self) / [labels, ofEdgeAt: 0] = "a" / [labels, ofEdgeAt: 1] = "b" / [labels, ofEdgeAt: 2] = "c" / [labels, ofEdgeAt: 3] = "d" / remove(edge: UndirectedEdge(0, 1)) / values(of: labels) / remove(edge: UndirectedEdge(1, 0)) / values(of: labels) / edges(between: 0, and: 1)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1)])
        let labels = graph.addEdgeMap(of: String.self)
        graph[labels, ofEdgeAt: 0] = "a"
        graph[labels, ofEdgeAt: 1] = "b"
        graph[labels, ofEdgeAt: 2] = "c"
        graph[labels, ofEdgeAt: 3] = "d"
        #expect(graph.remove(edge: UndirectedEdge(0, 1)).map { [$0.u, $0.v] } == [0, 1])
        do { let values = graph.values(of: labels); #expect((0 ..< graph.edgeCount).map { values[$0] } == ["a", "b", "c"]) }
        #expect(graph.remove(edge: UndirectedEdge(1, 0)).map { [$0.u, $0.v] } == [0, 1])
        do { let values = graph.values(of: labels); #expect((0 ..< graph.edgeCount).map { values[$0] } == ["a", "c"]) }
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edges(between: 0, and: 1).count == 1)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0, 2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[labels, ofEdgeAt: $0] } == ["a", "c"])
    }

    @Test("MG-215 removeAllEdges(between:and:) removes every copy's value")
    func mg215() {
        // Pseudograph V []; E [0–1, 2–3, 1–0, 0–0, 0–1]; let w = addEdgeMap(default: 0) / [w, ofEdgeAt: 0] = 10 / [w, ofEdgeAt: 1] = 11 / [w, ofEdgeAt: 2] = 12 / [w, ofEdgeAt: 3] = 13 / [w, ofEdgeAt: 4] = 14 / removeAllEdges(between: 0, and: 1) / values(of: w)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3), UndirectedEdge(1, 0), UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        let w = graph.addEdgeMap(default: 0)
        graph[w, ofEdgeAt: 0] = 10
        graph[w, ofEdgeAt: 1] = 11
        graph[w, ofEdgeAt: 2] = 12
        graph[w, ofEdgeAt: 3] = 13
        graph[w, ofEdgeAt: 4] = 14
        #expect(graph.removeAllEdges(between: 0, and: 1) == 3)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [13, 11]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 0], [2, 3]])
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 0])
        #expect(Array(graph.neighbors(of: 1)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 2)) == [3])
        #expect(Array(graph.incidentEdges(of: 2)) == [1])
        #expect(Array(graph.neighbors(of: 3)) == [2])
        #expect(Array(graph.incidentEdges(of: 3)) == [1])
        #expect(Array(graph.edges(between: 0, and: 0)) == [0])
        #expect(graph.edgeCount(between: 0, and: 0) == 1)
        #expect(Array(graph.edges(between: 2, and: 3)) == [1])
        #expect(graph.edgeCount(between: 2, and: 3) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [13, 11])
    }

    @Test("MG-216 vertex removal removes its edges' and its own values; the last slot's vertex keeps its value")
    func mg216() {
        // Pseudograph V []; E [0–1, 1–2, 2–2, 2–3, 3–0, 1–3]; let w = addEdgeMap(of: Int.self) / let name = addVertexMap(default: "?") / [w, ofEdgeAt: 0] = 0 / [w, ofEdgeAt: 1] = 1 / [w, ofEdgeAt: 2] = 2 / [w, ofEdgeAt: 3] = 3 / [w, ofEdgeAt: 4] = 4 / [w, ofEdgeAt: 5] = 5 / [name, of: 0] = "zero" / [name, of: 3] = "three" / [name, of: 1] = "one" / remove(1) / values(of: w) / values(of: name) / [name, of: 3] / [name, ofVertexAt: 1] / insert(edge: UndirectedEdge(1, 0)) / [name, of: 1] / values(of: w)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(1, 3)])
        let w = graph.addEdgeMap(of: Int.self)
        let name = graph.addVertexMap(default: "?")
        graph[w, ofEdgeAt: 0] = 0
        graph[w, ofEdgeAt: 1] = 1
        graph[w, ofEdgeAt: 2] = 2
        graph[w, ofEdgeAt: 3] = 3
        graph[w, ofEdgeAt: 4] = 4
        graph[w, ofEdgeAt: 5] = 5
        graph[name, of: 0] = "zero"
        graph[name, of: 3] = "three"
        graph[name, of: 1] = "one"
        #expect(graph.remove(1) == 1)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [3, 4, 2]) }
        do { let values = graph.values(of: name); #expect((0 ..< graph.vertexCount).map { values[$0] } == ["zero", "three", "?"]) }
        #expect(graph[name, of: 3] == "three")
        #expect(graph[name, ofVertexAt: 1] == "three")
        #expect(graph.insert(edge: UndirectedEdge(1, 0)) == 3)
        #expect(graph[name, of: 1] == "?")
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [3, 4, 2, nil]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 3, 2, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 3], [3, 0], [2, 2], [1, 0]])
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.neighbors(of: 0)) == [3, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [1, 3])
        #expect(Array(graph.neighbors(of: 3)) == [2, 0])
        #expect(Array(graph.incidentEdges(of: 3)) == [0, 1])
        #expect(Array(graph.neighbors(of: 2)) == [3, 2, 2])
        #expect(Array(graph.incidentEdges(of: 2)) == [0, 2, 2])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [3])
        #expect(Array(graph.edges(between: 2, and: 3)) == [0])
        #expect(graph.edgeCount(between: 2, and: 3) == 1)
        #expect(Array(graph.edges(between: 3, and: 0)) == [1])
        #expect(graph.edgeCount(between: 3, and: 0) == 1)
        #expect(Array(graph.edges(between: 2, and: 2)) == [2])
        #expect(graph.edgeCount(between: 2, and: 2) == 1)
        #expect(Array(graph.edges(between: 1, and: 0)) == [3])
        #expect(graph.edgeCount(between: 1, and: 0) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [3, 4, 2, nil])
        #expect(graph.vertices.map { graph[name, of: $0] } == ["zero", "three", "?", "?"])
        #expect((0 ..< graph.vertexCount).map { graph[name, ofVertexAt: $0] } == ["zero", "three", "?", "?"])
    }

    @Test("MG-217 checked reads throw for a non-vertex and a position out of range; plain reads at live positions")
    func mg217() throws {
        // Pseudograph V [5]; E [0–1, 1–1]; let w = addEdgeMap(default: 2) / let t = addVertexMap(default: 0) / [t, of: 1] = 7 / [w, checkedEdgeAt: 1] / [w, checkedEdgeAt: 2] / [w, checkedEdgeAt: -1] / [t, checked: 1] / [t, checked: 9] / [t, checkedVertexAt: 2] / [t, checkedVertexAt: 3] / [t, checkedVertexAt: -1] / remove(edgeAt: 1) / [w, checkedEdgeAt: 1]
        var graph = Pseudograph<Int>(vertices: [5], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let w = graph.addEdgeMap(default: 2)
        let t = graph.addVertexMap(default: 0)
        graph[t, of: 1] = 7
        #expect(try graph[w, checkedEdgeAt: 1] == 2)
        #expect(throws: EdgeNotFound()) { try graph[w, checkedEdgeAt: 2] }
        #expect(throws: EdgeNotFound()) { try graph[w, checkedEdgeAt: -1] }
        #expect(try graph[t, checked: 1] == 7)
        #expect(throws: VertexNotFound()) { try graph[t, checked: 9] }
        #expect(try graph[t, checkedVertexAt: 2] == 7)
        #expect(throws: VertexNotFound()) { try graph[t, checkedVertexAt: 3] }
        #expect(throws: VertexNotFound()) { try graph[t, checkedVertexAt: -1] }
        do { let removed = graph.remove(edgeAt: 1); #expect([removed.u, removed.v] == [1, 1]) }
        #expect(throws: EdgeNotFound()) { try graph[w, checkedEdgeAt: 1] }
        // Final state.
        #expect(Array(graph.vertices) == [5, 0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 5)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 5)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [2])
        #expect(graph.vertices.map { graph[t, of: $0] } == [0, 0, 7])
        #expect((0 ..< graph.vertexCount).map { graph[t, ofVertexAt: $0] } == [0, 0, 7])
    }

    @Test("MG-218 removeAllEdges() empties the edge maps, which stay attached; vertex maps keep their values")
    func mg218() {
        // Pseudograph V []; E [0–1, 1–2]; let w = addEdgeMap(default: 1) / let t = addVertexMap(default: 0) / [w, ofEdgeAt: 1] = 5 / [t, of: 2] = 9 / removeAllEdges() / values(of: w) / insert(edge: UndirectedEdge(2, 0)) / values(of: w) / values(of: t)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let w = graph.addEdgeMap(default: 1)
        let t = graph.addVertexMap(default: 0)
        graph[w, ofEdgeAt: 1] = 5
        graph[t, of: 2] = 9
        graph.removeAllEdges()
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [] as [Int]) }
        #expect(graph.insert(edge: UndirectedEdge(2, 0)) == 0)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [1]) }
        do { let values = graph.values(of: t); #expect((0 ..< graph.vertexCount).map { values[$0] } == [0, 0, 9]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 0)) == [2])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [] as [Int])
        #expect(Array(graph.incidentEdges(of: 1)) == [] as [Int])
        #expect(Array(graph.neighbors(of: 2)) == [0])
        #expect(Array(graph.incidentEdges(of: 2)) == [0])
        #expect(Array(graph.edges(between: 2, and: 0)) == [0])
        #expect(graph.edgeCount(between: 2, and: 0) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [1])
        #expect(graph.vertices.map { graph[t, of: $0] } == [0, 0, 9])
        #expect((0 ..< graph.vertexCount).map { graph[t, ofVertexAt: $0] } == [0, 0, 9])
    }

    @Test("MG-219 removeAll() empties every map; a re-inserted vertex reads the default")
    func mg219() {
        // Pseudograph V []; E [0–1, 1–2]; let w = addEdgeMap(default: 1) / let t = addVertexMap(default: 0) / [w, ofEdgeAt: 0] = 5 / [t, of: 1] = 9 / removeAll() / values(of: w) / values(of: t) / insert(edge: UndirectedEdge(1, 0)) / values(of: w) / values(of: t)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let w = graph.addEdgeMap(default: 1)
        let t = graph.addVertexMap(default: 0)
        graph[w, ofEdgeAt: 0] = 5
        graph[t, of: 1] = 9
        graph.removeAll()
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [] as [Int]) }
        do { let values = graph.values(of: t); #expect((0 ..< graph.vertexCount).map { values[$0] } == [] as [Int]) }
        #expect(graph.insert(edge: UndirectedEdge(1, 0)) == 0)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [1]) }
        do { let values = graph.values(of: t); #expect((0 ..< graph.vertexCount).map { values[$0] } == [0, 0]) }
        // Final state.
        #expect(Array(graph.vertices) == [1, 0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 1)) == [0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.edges(between: 1, and: 0)) == [0])
        #expect(graph.edgeCount(between: 1, and: 0) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [1])
        #expect(graph.vertices.map { graph[t, of: $0] } == [0, 0])
        #expect((0 ..< graph.vertexCount).map { graph[t, ofVertexAt: $0] } == [0, 0])
    }

    @Test("MG-220 two maps, one removed: the other keeps its values")
    func mg220() {
        // Pseudograph V []; E [0–1, 1–2, 2–0]; let a = addEdgeMap(default: 0) / let b = addEdgeMap(default: "x") / [a, ofEdgeAt: 1] = 1 / [b, ofEdgeAt: 2] = "z" / removeEdgeMap(a) / remove(edgeAt: 0) / values(of: b) / [b, ofEdgeAt: 0]
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let a = graph.addEdgeMap(default: 0)
        let b = graph.addEdgeMap(default: "x")
        graph[a, ofEdgeAt: 1] = 1
        graph[b, ofEdgeAt: 2] = "z"
        graph.removeEdgeMap(a)
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.u, removed.v] == [0, 1]) }
        do { let values = graph.values(of: b); #expect((0 ..< graph.edgeCount).map { values[$0] } == ["z", "x"]) }
        #expect(graph[b, ofEdgeAt: 0] == "z")
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[2, 0], [1, 2]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [2])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [1])
        #expect(Array(graph.neighbors(of: 2)) == [1, 0])
        #expect(Array(graph.incidentEdges(of: 2)) == [1, 0])
        #expect(Array(graph.edges(between: 2, and: 0)) == [0])
        #expect(graph.edgeCount(between: 2, and: 0) == 1)
        #expect(Array(graph.edges(between: 1, and: 2)) == [1])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[b, ofEdgeAt: $0] } == ["z", "x"])
    }

    @Test("MG-221 string vertices: a vertex map by vertex, by slot, after the last slot moves")
    func mg221() {
        // Pseudograph V ["a", "b", "c"]; E ["a"–"b", "c"–"a"]; let t = addVertexMap(of: Int.self) / [t, of: "a"] = 1 / [t, of: "c"] = 3 / remove("a") / [t, of: "c"] / [t, ofVertexAt: 0] / values(of: t) / insert("a") / [t, of: "a"]
        var graph = Pseudograph<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("c", "a")])
        let t = graph.addVertexMap(of: Int.self)
        graph[t, of: "a"] = 1
        graph[t, of: "c"] = 3
        #expect(graph.remove("a") == "a")
        #expect(graph[t, of: "c"] == 3)
        #expect(graph[t, ofVertexAt: 0] == 3)
        do { let values = graph.values(of: t); #expect((0 ..< graph.vertexCount).map { values[$0] } == [3, nil]) }
        do { let result = graph.insert("a"); #expect(result.inserted); #expect(result.memberAfterInsert == "a") }
        #expect(graph[t, of: "a"] == nil)
        // Final state.
        #expect(Array(graph.vertices) == ["c", "b", "a"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[String]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.neighbors(of: "c")) == [] as [String])
        #expect(Array(graph.incidentEdges(of: "c")) == [] as [Int])
        #expect(Array(graph.neighbors(of: "b")) == [] as [String])
        #expect(Array(graph.incidentEdges(of: "b")) == [] as [Int])
        #expect(Array(graph.neighbors(of: "a")) == [] as [String])
        #expect(Array(graph.incidentEdges(of: "a")) == [] as [Int])
        #expect(graph.vertices.map { graph[t, of: $0] } == [3, nil, nil])
        #expect((0 ..< graph.vertexCount).map { graph[t, ofVertexAt: $0] } == [3, nil, nil])
    }

    @Test("MG-222 directed: removal by position, by pair (newest copy), and removeAllEdges(from:to:)")
    func mg222() {
        // DirectedPseudograph V []; E [0→1, 1→0, 0→1, 1→1, 0→1, 2→0]; let w = addEdgeMap(of: Int.self) / [w, ofEdgeAt: 0] = 0 / [w, ofEdgeAt: 1] = 1 / [w, ofEdgeAt: 2] = 2 / [w, ofEdgeAt: 3] = 3 / [w, ofEdgeAt: 4] = 4 / [w, ofEdgeAt: 5] = 5 / remove(edgeAt: 1) / values(of: w) / remove(edge: DirectedEdge(from: 0, to: 1)) / values(of: w) / removeAllEdges(from: 0, to: 1) / values(of: w)
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0)])
        let w = graph.addEdgeMap(of: Int.self)
        graph[w, ofEdgeAt: 0] = 0
        graph[w, ofEdgeAt: 1] = 1
        graph[w, ofEdgeAt: 2] = 2
        graph[w, ofEdgeAt: 3] = 3
        graph[w, ofEdgeAt: 4] = 4
        graph[w, ofEdgeAt: 5] = 5
        do { let removed = graph.remove(edgeAt: 1); #expect([removed.source, removed.target] == [1, 0]) }
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [0, 5, 2, 3, 4]) }
        #expect(graph.remove(edge: DirectedEdge(from: 0, to: 1)).map { [$0.source, $0.target] } == [0, 1])
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [0, 5, 2, 3]) }
        #expect(graph.removeAllEdges(from: 0, to: 1) == 2)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [3, 5]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 1], [2, 0]])
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [] as [Int])
        #expect(Array(graph.outEdges(of: 0)) == [] as [Int])
        #expect(Array(graph.predecessors(of: 0)) == [2])
        #expect(Array(graph.inEdges(of: 0)) == [1])
        #expect(Array(graph.successors(of: 1)) == [1])
        #expect(Array(graph.outEdges(of: 1)) == [0])
        #expect(Array(graph.predecessors(of: 1)) == [1])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.successors(of: 2)) == [0])
        #expect(Array(graph.outEdges(of: 2)) == [1])
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int])
        #expect(Array(graph.inEdges(of: 2)) == [] as [Int])
        #expect(Array(graph.edges(from: 1, to: 1)) == [0])
        #expect(graph.edgeCount(from: 1, to: 1) == 1)
        #expect(Array(graph.edges(from: 2, to: 0)) == [1])
        #expect(graph.edgeCount(from: 2, to: 0) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [3, 5])
    }

    @Test("MG-223 directed vertex removal with loops, in- and out-edges; values follow the moved slot")
    func mg223() throws {
        // DirectedPseudograph V []; E [0→1, 1→2, 2→1, 1→1, 2→0, 0→2]; let w = addEdgeMap(of: Int.self) / let t = addVertexMap(default: -1) / [w, ofEdgeAt: 0] = 0 / [w, ofEdgeAt: 1] = 1 / [w, ofEdgeAt: 2] = 2 / [w, ofEdgeAt: 3] = 3 / [w, ofEdgeAt: 4] = 4 / [w, ofEdgeAt: 5] = 5 / [t, of: 2] = 2 / [t, of: 0] = 0 / remove(0) / values(of: w) / values(of: t) / [t, ofVertexAt: 0] / [t, checked: 0]
        var graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 2)])
        let w = graph.addEdgeMap(of: Int.self)
        let t = graph.addVertexMap(default: -1)
        graph[w, ofEdgeAt: 0] = 0
        graph[w, ofEdgeAt: 1] = 1
        graph[w, ofEdgeAt: 2] = 2
        graph[w, ofEdgeAt: 3] = 3
        graph[w, ofEdgeAt: 4] = 4
        graph[w, ofEdgeAt: 5] = 5
        graph[t, of: 2] = 2
        graph[t, of: 0] = 0
        #expect(graph.remove(0) == 0)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [3, 1, 2]) }
        do { let values = graph.values(of: t); #expect((0 ..< graph.vertexCount).map { values[$0] } == [2, -1]) }
        #expect(graph[t, ofVertexAt: 0] == 2)
        #expect(throws: VertexNotFound()) { try graph[t, checked: 0] }
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[1, 1], [1, 2], [2, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.successors(of: 2)) == [1])
        #expect(Array(graph.outEdges(of: 2)) == [2])
        #expect(Array(graph.predecessors(of: 2)) == [1])
        #expect(Array(graph.inEdges(of: 2)) == [1])
        #expect(Array(graph.successors(of: 1)) == [2, 1])
        #expect(Array(graph.outEdges(of: 1)) == [1, 0])
        #expect(Array(graph.predecessors(of: 1)) == [1, 2])
        #expect(Array(graph.inEdges(of: 1)) == [0, 2])
        #expect(Array(graph.edges(from: 1, to: 1)) == [0])
        #expect(graph.edgeCount(from: 1, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 2)) == [1])
        #expect(graph.edgeCount(from: 1, to: 2) == 1)
        #expect(Array(graph.edges(from: 2, to: 1)) == [2])
        #expect(graph.edgeCount(from: 2, to: 1) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [3, 1, 2])
        #expect(graph.vertices.map { graph[t, of: $0] } == [2, -1])
        #expect((0 ..< graph.vertexCount).map { graph[t, ofVertexAt: $0] } == [2, -1])
    }

    @Test("MG-224 directed checked insertion appends the default; a failed one changes no map; checked reads out of range")
    func mg224() throws {
        // DirectedPseudograph V [0, 1]; E [0→1]; let w = addEdgeMap(default: 0.5) / let t = addVertexMap(default: 0) / [w, ofEdgeAt: 0] = 2.0 / insert(checked: DirectedEdge(from: 1, to: 0)) / insert(checked: DirectedEdge(from: 1, to: 7)) / values(of: w) / [w, checkedEdgeAt: 2] / [w, checkedEdgeAt: -1] / [t, checkedVertexAt: 1] / [t, checkedVertexAt: 2] / [t, checkedVertexAt: -1]
        var graph = DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])
        let w = graph.addEdgeMap(default: 0.5)
        let t = graph.addVertexMap(default: 0)
        graph[w, ofEdgeAt: 0] = 2.0
        #expect(try graph.insert(checked: DirectedEdge(from: 1, to: 0)) == 1)
        #expect(throws: VertexNotFound()) { try graph.insert(checked: DirectedEdge(from: 1, to: 7)) }
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [2.0, 0.5]) }
        #expect(throws: EdgeNotFound()) { try graph[w, checkedEdgeAt: 2] }
        #expect(throws: EdgeNotFound()) { try graph[w, checkedEdgeAt: -1] }
        #expect(try graph[t, checkedVertexAt: 1] == 0)
        #expect(throws: VertexNotFound()) { try graph[t, checkedVertexAt: 2] }
        #expect(throws: VertexNotFound()) { try graph[t, checkedVertexAt: -1] }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [1])
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [2.0, 0.5])
        #expect(graph.vertices.map { graph[t, of: $0] } == [0, 0])
        #expect((0 ..< graph.vertexCount).map { graph[t, ofVertexAt: $0] } == [0, 0])
    }

    @Test("MG-225 multigraph: the base's maps through the wrapper; a rejected self-loop changes no map")
    func mg225() throws {
        // Multigraph V []; E [0–1, 1–2, 0–1]; let w = addEdgeMap(default: 1.0) / let t = addVertexMap(of: String.self) / [w, ofEdgeAt: 0] = 3.0 / [w, ofEdgeAt: 2] = 5.0 / [t, of: 2] = "two" / insert(edge: UndirectedEdge(1, 1)) / values(of: w) / remove(edge: UndirectedEdge(1, 0)) / values(of: w) / remove(0) / values(of: w) / values(of: t) / [w, checkedEdgeAt: 1]
        var graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1)]))
        let w = graph.addEdgeMap(default: 1.0)
        let t = graph.addVertexMap(of: String.self)
        graph[w, ofEdgeAt: 0] = 3.0
        graph[w, ofEdgeAt: 2] = 5.0
        graph[t, of: 2] = "two"
        #expect(throws: LooplessEdgeError.selfLoop) { try graph.insert(edge: UndirectedEdge(1, 1)) }
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [3.0, 1.0, 5.0]) }
        #expect(graph.remove(edge: UndirectedEdge(1, 0)).map { [$0.u, $0.v] } == [0, 1])
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [3.0, 1.0]) }
        #expect(graph.remove(0) == 0)
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [1.0]) }
        do { let values = graph.values(of: t); #expect((0 ..< graph.vertexCount).map { values[$0] } == ["two", nil]) }
        #expect(throws: EdgeNotFound()) { try graph[w, checkedEdgeAt: 1] }
        // Final state.
        #expect(Array(graph.vertices) == [2, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.neighbors(of: 2)) == [1])
        #expect(Array(graph.incidentEdges(of: 2)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [2])
        #expect(Array(graph.incidentEdges(of: 1)) == [0])
        #expect(Array(graph.edges(between: 1, and: 2)) == [0])
        #expect(graph.edgeCount(between: 1, and: 2) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [1.0])
        #expect(graph.vertices.map { graph[t, of: $0] } == ["two", nil])
        #expect((0 ..< graph.vertexCount).map { graph[t, ofVertexAt: $0] } == ["two", nil])
    }

    @Test("MG-226 directed multigraph: the base's maps through the wrapper, checked reads")
    func mg226() throws {
        // DirectedMultigraph V []; E [0→1, 1→0, 0→1]; let w = addEdgeMap(of: Int.self) / let t = addVertexMap(default: 0) / [w, ofEdgeAt: 1] = 10 / [t, of: 1] = 4 / insert(checked: DirectedEdge(from: 1, to: 1)) / remove(edgeAt: 0) / values(of: w) / [w, checkedEdgeAt: 2] / [t, checked: 1] / [t, checked: 3] / [t, checkedVertexAt: 1]
        var graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1)]))
        let w = graph.addEdgeMap(of: Int.self)
        let t = graph.addVertexMap(default: 0)
        graph[w, ofEdgeAt: 1] = 10
        graph[t, of: 1] = 4
        #expect(throws: LooplessEdgeError.selfLoop) { try graph.insert(checked: DirectedEdge(from: 1, to: 1)) }
        do { let removed = graph.remove(edgeAt: 0); #expect([removed.source, removed.target] == [0, 1]) }
        do { let values = graph.values(of: w); #expect((0 ..< graph.edgeCount).map { values[$0] } == [nil, 10]) }
        #expect(throws: EdgeNotFound()) { try graph[w, checkedEdgeAt: 2] }
        #expect(try graph[t, checked: 1] == 4)
        #expect(throws: VertexNotFound()) { try graph[t, checked: 3] }
        #expect(try graph[t, checkedVertexAt: 1] == 4)
        // Final state.
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.successors(of: 0)) == [1])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [1])
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [1])
        #expect(Array(graph.predecessors(of: 1)) == [0])
        #expect(Array(graph.inEdges(of: 1)) == [0])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0])
        #expect(graph.edgeCount(from: 0, to: 1) == 1)
        #expect(Array(graph.edges(from: 1, to: 0)) == [1])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [nil, 10])
        #expect(graph.vertices.map { graph[t, of: $0] } == [0, 4])
        #expect((0 ..< graph.vertexCount).map { graph[t, ofVertexAt: $0] } == [0, 4])
    }
}
