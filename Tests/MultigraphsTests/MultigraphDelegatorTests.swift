// The multigraphs as `GraphDelegator`s of their pseudographs: `base` is the wrapped graph, every
// read requirement answers as the base's does when called through a generic context (where only
// the protocol witnesses are visible), and attached maps (`PropertyGraph`) are the base's: attached
// through either, read and written through either, carried by the O(1) conversions both ways, and
// ignored by equality, hashing and coding. Each test is self-contained.

import Foundation
import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs as delegators")
struct MultigraphDelegatorTests {
    @Test("DirectedMultigraph answers every BidirectionalDirectedGraph requirement as its base, generically")
    func directedRequirements() throws {
        var graph = try #require(DirectedMultigraph(vertices: [9], edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 0),
        ]))
        graph.remove(edgeAt: 0)
        _ = graph.remove(2)
        let base = graph.base
        #expect(base == DirectedPseudograph(graph))

        func reads<G: BidirectionalDirectedGraph>(_ g: G) -> [String] where G.Vertex == Int, G.Edges.Index == Int {
            var out = ["\(Array(g.vertices))", "\(g.edges.map { [$0.source, $0.target] })", "\(g.vertexCount) \(g.edgeCount)",
                       "\(String(describing: g.vertexIndexBound)) \(String(describing: g.edgeIndexBound))"]
            for v in [0, 1, 9] {
                out.append("\(v): \(Array(g.successors(of: v))) \(Array(g.outEdges(of: v))) \(Array(g.predecessors(of: v))) \(Array(g.inEdges(of: v)))")
                out.append("\(v): \(g.outDegree(of: v)) \(g.inDegree(of: v)) \(g.degree(of: v)) \(g.contains(v)) \(g.vertexIndex(of: v))")
            }
            for i in 0 ..< g.vertexIndexBound! {
                var visited: [Int] = []
                g._forEachSuccessorIndex(ofIndex: i) { visited.append($0) }
                var visitedBack: [Int] = []
                g._forEachPredecessorIndex(ofIndex: i) { visitedBack.append($0) }
                out.append("#\(i): \(g.vertex(atIndex: i)) \(Array(g.successorIndices(ofIndex: i))) \(Array(g.outEdges(ofIndex: i))) \(g.outDegree(ofIndex: i)) \(visited)")
                out.append("#\(i): \(Array(g.predecessorIndices(ofIndex: i))) \(Array(g.inEdges(ofIndex: i))) \(g.inDegree(ofIndex: i)) \(visitedBack)")
            }
            for p in g.edges.indices {
                out.append("e\(p): \(g.source(ofEdgeAt: p)) \(g.target(ofEdgeAt: p)) \(g.sourceIndex(ofEdgeAt: p)) \(g.targetIndex(ofEdgeAt: p)) \(g.edgeIndex(of: p))")
            }
            out.append("\(g.contains(edge: DirectedEdge(from: 0, to: 1))) \(g.contains(edge: DirectedEdge(from: 1, to: 9))) \(g.contains(7))")
            let rows = g._withOutIndexRows { targets, targetRows, edges, edgeRows in [Array(targets), Array(targetRows), Array(edges), Array(edgeRows)] }
            out.append("\(String(describing: rows))")
            let successorRows = g._withSuccessorIndexRows { offsets, targets in [Array(offsets), Array(targets)] }
            out.append("\(String(describing: successorRows))")
            return out
        }
        #expect(reads(graph) == reads(base))
    }

    @Test("Multigraph answers every Graph requirement as its base, generically")
    func undirectedRequirements() throws {
        var graph = try #require(Multigraph(vertices: [9], edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 0), UndirectedEdge(2, 0), UndirectedEdge(2, 3),
        ]))
        graph.remove(edgeAt: 1)
        _ = graph.remove(3)
        let base = graph.base
        #expect(base == Pseudograph(graph))

        func reads<G: Graph>(_ g: G) -> [String] where G.Vertex == Int, G.Edges.Index == Int {
            var out = ["\(Array(g.vertices))", "\(g.edges.map { [$0.u, $0.v] })", "\(g.vertexCount) \(g.edgeCount)",
                       "\(String(describing: g.vertexIndexBound)) \(String(describing: g.edgeIndexBound))"]
            for v in [0, 1, 2, 9] {
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
            out.append("\(g.contains(edge: UndirectedEdge(1, 0))) \(g.contains(edge: UndirectedEdge(1, 9))) \(g.contains(7))")
            let rows = g._withIncidentIndexRows { neighbors, neighborRows, edges, edgeRows in [Array(neighbors), Array(neighborRows), Array(edges), Array(edgeRows)] }
            out.append("\(String(describing: rows))")
            return out
        }
        #expect(reads(graph) == reads(base))
    }

    @Test("Multigraph: maps attached through the wrapper are the base's, and the conversions carry them")
    func undirectedMaps() throws {
        var graph = try #require(Multigraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1)]))
        let w = graph.addEdgeMap(default: 1.0)
        let t = graph.addVertexMap(of: String.self)
        graph[w, ofEdgeAt: 2] = 5
        graph[t, of: 1] = "one"
        // The base holds the values.
        #expect(graph.base[w, ofEdgeAt: 2] == 5)
        #expect(graph.base[t, of: 1] == "one")
        #expect(try graph[w, checkedEdgeAt: 2] == 5)
        #expect(try graph[t, checkedVertexAt: 1] == "one")
        #expect(try graph[t, checked: 1] == "one")
        let values: EdgeValues<Multigraph<Int>, Double> = graph.values(of: w)
        #expect([values[0], values[1], values[2]] == [1, 1, 5])
        #expect(values.defaultValue == 1)
        let vertexValues: VertexValues<Multigraph<Int>, String?> = graph.values(of: t)
        #expect([vertexValues[0], vertexValues[1], vertexValues[2]] == [nil, "one", nil])
        // The O(1) unwrap keeps the maps, and so does wrapping a pseudograph back.
        var pseudograph = Pseudograph(graph)
        #expect(pseudograph[w, ofEdgeAt: 2] == 5)
        pseudograph[w, ofEdgeAt: 0] = 3
        let rewrapped = try #require(Multigraph(pseudograph))
        #expect(rewrapped[w, ofEdgeAt: 0] == 3)
        #expect(rewrapped[t, ofVertexAt: 1] == "one")
        // The copy is its own: the wrapper's values did not change.
        #expect(graph[w, ofEdgeAt: 0] == 1)
        graph.removeEdgeMap(w)
        graph.removeVertexMap(t)
        #expect(rewrapped[w, ofEdgeAt: 2] == 5)
    }

    @Test("DirectedMultigraph: maps attached to the base before wrapping read through the wrapper")
    func directedMaps() throws {
        var base = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let w = base.addEdgeMap(of: Int.self)
        let t = base.addVertexMap(default: -1)
        base[w, ofEdgeAt: 1] = 12
        base[t, of: 2] = 2
        var graph = try #require(DirectedMultigraph(base))
        #expect(graph[w, ofEdgeAt: 1] == 12)
        #expect(graph[t, of: 2] == 2)
        _ = try graph.insert(edge: DirectedEdge(from: 2, to: 0))
        graph.remove(edgeAt: 0)
        // The base's swap-remove moved the last copy (2→0, default) into position 0.
        #expect((0 ..< graph.edgeCount).map { graph[w, ofEdgeAt: $0] } == [nil, 12])
        #expect(throws: EdgeNotFound.self) { try graph[w, checkedEdgeAt: 2] }
        #expect(throws: VertexNotFound.self) { try graph[t, checked: 5] }
        let values = graph.values(of: t)
        #expect(graph.vertices.map { values[graph.vertexIndex(of: $0)] } == [-1, -1, 2])
        // The base before wrapping is unchanged.
        #expect((0 ..< base.edgeCount).map { base[w, ofEdgeAt: $0] } == [nil, 12])
        #expect(DirectedPseudograph(graph)[w, ofEdgeAt: 1] == 12)
    }

    @Test("equality, hashing and coding ignore maps")
    func mapsIgnored() throws {
        // Sorted keys: a dictionary-backed container's key order varies between encodings.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var a = try #require(Multigraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]))
        let b = a
        let w = a.addEdgeMap(default: 0)
        a[w, ofEdgeAt: 0] = 7
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        #expect(try encoder.encode(a) == encoder.encode(b))
        var c = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1)])
        let d = c
        _ = c.addVertexMap(default: "x")
        #expect(c == d)
        #expect(c.hashValue == d.hashValue)
        #expect(try encoder.encode(c) == encoder.encode(d))
        #expect(c.description == d.description)
    }
}
