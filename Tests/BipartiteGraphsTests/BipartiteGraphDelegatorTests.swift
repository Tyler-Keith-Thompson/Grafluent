// BipartiteGraph as a `GraphDelegator` of its `UndirectedAdjacencyList`: `base` is the wrapped
// graph, every read requirement answers as the base's does when called through a generic context
// (where only the protocol witnesses are visible), and attached maps (`PropertyGraph`) are the
// base's: attached through either, read and written through either, kept by `init?(_ graph:)` from
// an adjacency list, following every removal (the side lists' own bookkeeping included), unchanged
// by a mutation that throws `BipartitionError`, and ignored by equality, hashing and coding. Each
// test is self-contained.

import AdjacencyListModule
import BipartiteGraphs
import Foundation
import GraphProtocols
import Testing

@Suite("BipartiteGraph as a delegator")
struct BipartiteGraphDelegatorTests {
    @Test("answers every Graph requirement as its base, generically")
    func requirements() throws {
        var graph = try #require(BipartiteGraph(left: [0, 2, 4, 9], right: [1, 3, 5], edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(3, 2), UndirectedEdge(4, 5), UndirectedEdge(0, 5), UndirectedEdge(3, 4),
        ]))
        _ = graph.remove(edge: UndirectedEdge(2, 1))
        _ = graph.remove(0)
        let base = graph.base

        func reads<G: Graph>(_ g: G) -> [String] where G.Vertex == Int, G.Edges.Index == Int {
            var out = ["\(Array(g.vertices))", "\(g.edges.map { [$0.u, $0.v] })", "\(g.vertexCount) \(g.edgeCount)",
                       "\(String(describing: g.vertexIndexBound)) \(String(describing: g.edgeIndexBound))"]
            for v in [2, 3, 4, 5, 9] {
                out.append("\(v): \(Array(g.neighbors(of: v))) \(Array(g.incidentEdges(of: v))) \(g.degree(of: v)) \(g.contains(v)) \(g.vertexIndex(of: v))")
            }
            for i in 0 ..< g.vertexIndexBound! {
                var visited: [Int] = []
                g._forEachNeighborIndex(ofIndex: i) { visited.append($0) }
                out.append("#\(i): \(g.vertex(atIndex: i)) \(Array(g.neighborIndices(ofIndex: i))) \(Array(g.incidentEdges(ofIndex: i))) \(Array(g.incidentEdgeIndices(ofIndex: i))) \(g.degree(ofIndex: i)) \(visited)")
            }
            for p in g.edges.indices {
                let e = g.edges[p]
                let ends = g.endpointIndices(ofEdgeAt: p)
                out.append("e\(p): \(g.oppositeVertex(to: e.u, acrossEdgeAt: p)) \(ends.u) \(ends.v) \(g.edgeIndex(of: p))")
            }
            out.append("\(g.contains(edge: UndirectedEdge(5, 4))) \(g.contains(edge: UndirectedEdge(2, 9))) \(g.contains(0))")
            let rows = g._withIncidentIndexRows { neighbors, neighborRows, edges, edgeRows in [Array(neighbors), Array(neighborRows), Array(edges), Array(edgeRows)] }
            out.append("\(String(describing: rows))")
            return out
        }
        #expect(reads(graph) == reads(base))
        // The rows are the base's own, not the protocol's fallback.
        #expect(graph._withIncidentIndexRows { _, _, _, _ in true } == true)
        // Left endpoint first, as the base stores it.
        #expect(base.edges.allSatisfy { graph.side(of: $0.u) == .left })
    }

    @Test("maps attached through the wrapper are the base's")
    func maps() throws {
        var graph = try #require(BipartiteGraph(left: ["a", "b"], right: ["x", "y"], edges: [
            UndirectedEdge("a", "x"), UndirectedEdge("y", "a"), UndirectedEdge("b", "y"),
        ]))
        let w = graph.addEdgeMap(default: 1.0)
        let t = graph.addVertexMap(of: String.self)
        graph[w, ofEdgeAt: 1] = 5
        graph[t, of: "y"] = "why"
        graph[t, ofVertexAt: 0] = "ay"
        #expect(graph.base[w, ofEdgeAt: 1] == 5)
        #expect(graph.base[t, of: "y"] == "why")
        #expect(graph[t, of: "a"] == "ay")
        #expect(try graph[w, checkedEdgeAt: 1] == 5)
        #expect(try graph[t, checked: "y"] == "why")
        #expect(try graph[t, checkedVertexAt: 3] == "why")
        #expect(throws: EdgeNotFound.self) { try graph[w, checkedEdgeAt: 3] }
        #expect(throws: VertexNotFound.self) { try graph[t, checked: "z"] }
        #expect(throws: VertexNotFound.self) { try graph[t, checkedVertexAt: 4] }
        let values: EdgeValues<BipartiteGraph<String>, Double> = graph.values(of: w)
        #expect([values[0], values[1], values[2]] == [1, 5, 1])
        #expect(values.defaultValue == 1)
        let names: VertexValues<BipartiteGraph<String>, String?> = graph.values(of: t)
        #expect(graph.vertices.map { names[graph.vertexIndex(of: $0)] } == ["ay", nil, nil, "why"])
        // A new vertex and a new edge read the defaults.
        _ = try graph.insert("z", on: .right)
        _ = try graph.insert(edge: UndirectedEdge("z", "b"))
        #expect(graph[t, of: "z"] == nil)
        #expect(graph[w, ofEdgeAt: 3] == 1)
        graph.removeEdgeMap(w)
        graph.removeVertexMap(t)
        #expect(graph.edgeCount == 4)
    }

    @Test("a mutation that throws BipartitionError changes no map")
    func rejectedMutations() throws {
        var graph = try #require(BipartiteGraph(left: [0, 1], right: [2], edges: [UndirectedEdge(0, 2)]))
        let w = graph.addEdgeMap(default: 0)
        let t = graph.addVertexMap(default: "-")
        graph[w, ofEdgeAt: 0] = 7
        graph[t, of: 1] = "one"
        let before = graph
        #expect(throws: BipartitionError.onOtherSide(.left)) { try graph.insert(0, on: .right) }
        #expect(throws: BipartitionError.sameSide(.left)) { try graph.insert(edge: UndirectedEdge(0, 1)) }
        #expect(throws: BipartitionError.sameSide(.right)) { try graph.insert(edge: UndirectedEdge(2, 2)) }
        #expect(throws: BipartitionError.missingEndpoint) { try graph.insert(checked: UndirectedEdge(0, 5)) }
        #expect(throws: BipartitionError.sameSide(.left)) { try graph.insert(checked: UndirectedEdge(1, 0)) }
        // Inserting what is already there adds nothing either.
        #expect(try graph.insert(1, on: .left).inserted == false)
        #expect(try graph.insert(edge: UndirectedEdge(2, 0)).inserted == false)
        #expect(graph == before)
        #expect(graph.values(of: w).defaultValue == 0)
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [7])
        #expect(graph.vertices.map { graph[t, of: $0] } == ["-", "one", "-"])
    }

    @Test("vertex removal moves the last slot's values into the hole, on either side")
    func vertexRemoval() throws {
        // Slots: a0 x1 b2 y3 c4; edges a–x, b–x, b–y, c–y, a–y.
        var graph = try #require(BipartiteGraph(left: ["a"], right: ["x"]))
        _ = try graph.insert("b", on: .left)
        _ = try graph.insert("y", on: .right)
        _ = try graph.insert("c", on: .left)
        for (u, v) in [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y"), ("a", "y")] { _ = try graph.insert(edge: UndirectedEdge(u, v)) }
        let w = graph.addEdgeMap(of: String.self)
        let t = graph.addVertexMap(default: 0)
        for p in 0 ..< graph.edgeCount {
            let e = graph.edges[p]
            graph[w, ofEdgeAt: p] = e.u + e.v
        }
        for (k, v) in graph.vertices.enumerated() { graph[t, of: v] = k + 1 }
        // Removing a right vertex: c (left, last slot) moves into x's slot.
        #expect(graph.remove("x") == "x")
        #expect(Array(graph.vertices) == ["a", "c", "b", "y"])
        #expect(Array(graph.left) == ["a", "b", "c"])
        #expect(Array(graph.right) == ["y"])
        #expect(graph.side(of: "c") == .left)
        #expect(graph.vertices.map { graph[t, of: $0] } == [1, 5, 3, 4])
        #expect(graph.vertices.map { graph[t, ofVertexAt: graph.vertexIndex(of: $0)] } == [1, 5, 3, 4])
        for p in 0 ..< graph.edgeCount {
            let e = graph.edges[p]
            #expect(graph[w, ofEdgeAt: p] == e.u + e.v)
        }
        // Removing a left vertex: y (right, last slot) moves into a's slot.
        #expect(graph.remove("a") == "a")
        #expect(Array(graph.vertices) == ["y", "c", "b"])
        #expect(Array(graph.left) == ["c", "b"])
        #expect(graph.side(of: "y") == .right)
        #expect(graph.vertices.map { graph[t, of: $0] } == [4, 5, 3])
        #expect(Set((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] }) == ["by", "cy"])
        for p in 0 ..< graph.edgeCount {
            let e = graph.edges[p]
            #expect(graph[w, ofEdgeAt: p] == e.u + e.v)
        }
        // Removing the last slot moves nothing.
        #expect(graph.remove("b") == "b")
        #expect(graph.vertices.map { graph[t, of: $0] } == [4, 5])
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == ["cy"])
        #expect(graph.remove("q") == nil)
    }

    @Test("edge removal, removeAllEdges and removeAll keep the maps attached")
    func clears() throws {
        var graph = try #require(BipartiteGraph(left: [0, 1], right: [2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(3, 0)]))
        let w = graph.addEdgeMap(default: -1)
        let t = graph.addVertexMap(default: 0.5)
        for p in 0 ..< 3 { graph[w, ofEdgeAt: p] = p * 10 }
        graph[t, of: 3] = 3
        #expect(graph.remove(edge: UndirectedEdge(2, 0)) == UndirectedEdge(0, 2))
        // The last edge, 0–3, moved into position 0.
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [20, 10])
        #expect(graph.remove(edge: UndirectedEdge(0, 1)) == nil)
        graph.removeAllEdges()
        #expect(graph.edgeCount == 0)
        #expect(graph.vertices.map { graph[t, of: $0] } == [0.5, 0.5, 0.5, 3])
        _ = try graph.insert(edge: UndirectedEdge(1, 2))
        #expect(graph[w, ofEdgeAt: 0] == -1)
        graph.removeAll(keepingCapacity: true)
        _ = try graph.insert(3, on: .left)
        #expect(graph[t, of: 3] == 0.5)
        #expect(Array(graph.left) == [3])
    }

    @Test("init?(_:) from an adjacency list keeps its maps, edges turned left end first")
    func conversionKeepsMaps() throws {
        var list = UndirectedAdjacencyList<Int>()
        for (u, v) in [(0, 1), (2, 1), (3, 2)] { list.insert(edge: UndirectedEdge(u, v)) }
        let w = list.addEdgeMap(of: String.self)
        let t = list.addVertexMap(default: 0)
        list[w, ofEdgeAt: 1] = "2–1"
        list[w, ofEdgeAt: 2] = "3–2"
        list[t, of: 2] = 2
        var graph = try #require(BipartiteGraph(list))
        // Sides: 0 and 2 left. Edge 1 was stored 2–1 and keeps it; edge 2 (3–2) is turned to 2–3.
        #expect(Array(graph.left) == [0, 2])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3]])
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [nil, "2–1", "3–2"])
        #expect(graph[t, of: 2] == 2)
        // The wrapper's copy is its own.
        graph[t, of: 2] = 20
        #expect(list[t, of: 2] == 2)
        #expect(graph.base[t, of: 2] == 20)
    }

    @Test("equality, hashing and coding ignore maps")
    func mapsIgnored() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var a = try #require(BipartiteGraph(left: [0], right: [1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 0)]))
        let b = a
        let w = a.addEdgeMap(default: 0)
        a[w, ofEdgeAt: 1] = 7
        _ = a.addVertexMap(default: "x")
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        #expect(try encoder.encode(a) == encoder.encode(b))
        #expect(a.description == b.description)
        #expect(a.debugDescription == b.debugDescription)
        let decoded = try JSONDecoder().decode(BipartiteGraph<Int>.self, from: encoder.encode(a))
        #expect(decoded == a)
    }
}
