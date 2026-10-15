// StableUndirectedGraph's conformances: `Graph`'s laws with and without holes, equality and hashing
// that ignore positions and orientations, Codable keeping every position and orientation, the
// descriptions, `Sendable`, generations, attached maps that keep positions across removals, and
// algorithms on a graph with holes against its compacted copy
// (`Pseudograph(g)`, whose edge k is the kth live position). See README.md.

import Connectivity
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import ShortestPaths
import StableGraphs
import Testing
import Traversal

@Suite("StableUndirectedGraph conformances")
struct StableUndirectedGraphConformanceTests {
    @Test("Graph's laws hold on random graphs before and after removals")
    func laws() {
        var rng = SeededRandomNumberGenerator(seed: 41)
        for round in 0 ..< 40 {
            var graph = StableUndirectedGraph<Int>(vertices: 0 ..< 8)
            for _ in 0 ..< 20 { graph.insert(edge: UndirectedEdge(Int.random(in: 0 ..< 8, using: &rng), Int.random(in: 0 ..< 8, using: &rng))) }
            if round % 2 == 1 {
                for _ in 0 ..< 6 where !graph.edges.isEmpty { graph.remove(edgeAt: Array(graph.edges.indices).randomElement(using: &rng)!) }
                graph.remove(Int.random(in: 0 ..< 8, using: &rng))
            }
            let context = "round \(round): \(graph)"
            #expect(graph.vertexCount == graph.vertices.count && graph.edgeCount == graph.edges.count, "\(context)")
            var degreeSum = 0
            for v in graph.vertices {
                let incident = Array(graph.incidentEdges(of: v))
                // Each incident edge has v as an end, once per end.
                for p in Set(incident) {
                    let e = graph.edges[p]
                    #expect(e.u == v || e.v == v, "\(context)")
                    #expect(incident.filter { $0 == p }.count == (e.u == e.v ? 2 : 1), "\(context)")
                }
                #expect(Array(graph.neighbors(of: v)) == incident.map { graph.edges[$0].oppositeVertex(to: v) }, "\(context)")
                #expect(incident.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) } == Array(graph.neighbors(of: v)), "\(context)")
                #expect(graph.degree(of: v) == incident.count, "\(context)")
                degreeSum += incident.count
            }
            #expect(degreeSum == 2 * graph.edgeCount, "\(context)")
            for p in graph.edges.indices {
                let e = graph.edges[p]
                #expect(graph.contains(edge: e) && graph.contains(edge: UndirectedEdge(e.v, e.u)), "\(context)")
                #expect(Array(graph.edges(between: e.u, and: e.v)).contains(p), "\(context)")
            }
            for a in 0 ..< 8 {
                for b in 0 ..< 8 {
                    let copies = graph.edges.indices.filter { graph.edges[$0] == UndirectedEdge(a, b) }
                    #expect(Array(graph.edges(between: a, and: b)) == copies, "\(context) \(a) \(b)")
                    #expect(graph.contains(edge: UndirectedEdge(a, b)) == !copies.isEmpty, "\(context)")
                }
            }
            // The index-space rows, where the graph has indices.
            if let bound = graph.vertexIndexBound {
                for i in 0 ..< bound {
                    let v = graph.vertex(atIndex: i)
                    #expect(graph.vertexIndex(of: v) == i)
                    #expect(Array(graph.neighborIndices(ofIndex: i)) == graph.neighbors(of: v).map { graph.vertexIndex(of: $0) }, "\(context)")
                    #expect(Array(graph.incidentEdges(ofIndex: i)) == Array(graph.incidentEdges(of: v)), "\(context)")
                    #expect(graph.degree(ofIndex: i) == graph.degree(of: v))
                }
                for p in graph.edges.indices {
                    let ends = graph.endpointIndices(ofEdgeAt: p)
                    #expect(graph.vertex(atIndex: ends.u) == graph.edges[p].u && graph.vertex(atIndex: ends.v) == graph.edges[p].v)
                }
                if graph.edgeIndexBound != nil {
                    for i in 0 ..< bound { #expect(Array(graph.incidentEdgeIndices(ofIndex: i)) == Array(graph.incidentEdges(ofIndex: i))) }
                    #expect(graph.edges.indices.map { graph.edgeIndex(of: $0) } == Array(0 ..< graph.edgeCount))
                }
            } else {
                #expect(round % 2 == 1)
            }
            #expect(graph.edgeIndexBound == (graph.edges.endIndex == graph.edgeCount ? graph.edgeCount : nil))
        }
    }

    @Test("Algorithms on a graph with holes agree with the compacted copy")
    func algorithmsWithHoles() {
        var rng = SeededRandomNumberGenerator(seed: 42)
        for _ in 0 ..< 30 {
            var graph = StableUndirectedGraph<Int>(vertices: 0 ..< 10)
            for _ in 0 ..< 18 { graph.insert(edge: UndirectedEdge(Int.random(in: 0 ..< 10, using: &rng), Int.random(in: 0 ..< 10, using: &rng))) }
            for _ in 0 ..< 4 where !graph.edges.isEmpty { graph.remove(edgeAt: Array(graph.edges.indices).randomElement(using: &rng)!) }
            graph.remove(Int.random(in: 0 ..< 10, using: &rng))
            let compacted = Pseudograph(graph)
            let positions = Array(graph.edges.indices)
            let weights = graph.addEdgeMap(default: 0)
            for p in positions { graph[weights, ofEdgeAt: p] = Int.random(in: 1 ... 9, using: &rng) }
            let weight = graph.values(of: weights)
            let components = graph.connectedComponents()
            let compactedComponents = compacted.connectedComponents()
            #expect(components.count == compactedComponents.count)
            #expect(Set(graph.bridges().map { graph.edges[$0] }) == Set(compacted.bridges().map { compacted.edges[$0] }))
            #expect(Set(graph.articulationPoints()) == Set(compacted.articulationPoints()))
            for source in graph.vertices {
                #expect(Array(graph.directedView.lazy.breadthFirstSearch(from: source)).count == Array(compacted.directedView.lazy.breadthFirstSearch(from: source)).count)
                let tree = graph.dijkstraShortestPaths(from: source) { weight[$0] }
                let copy = compacted.dijkstraShortestPaths(from: source) { weight[positions[$0]] }
                for target in graph.vertices {
                    #expect(tree.distance(to: target) == copy.distance(to: target))
                    #expect((components.component(of: source) == components.component(of: target)) == (tree.distance(to: target) != nil))
                }
            }
        }
    }

    @Test("Equality and hashing ignore positions, holes and orientations; copies and multiplicities count")
    func equality() {
        let a = StableUndirectedGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        var b = StableUndirectedGraph(vertices: [2, 1, 0, 9], edges: [UndirectedEdge(2, 2), UndirectedEdge(9, 0), UndirectedEdge(2, 1), UndirectedEdge(1, 0)])
        #expect(a != b)
        b.remove(9)
        #expect(a == b && b == a)
        #expect(a.hashValue == b.hashValue)
        var c = a
        c.insert(edge: UndirectedEdge(1, 0))
        #expect(a != c)
        var d = b
        d.insert(edge: UndirectedEdge(2, 1))
        #expect(c != d)
        // The same edge count, different pairs.
        let e = StableUndirectedGraph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        #expect(a != e)
        // Two loops at one vertex are not one loop at each of two.
        let twoLoops = StableUndirectedGraph(vertices: [0, 1], edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        let loopEach = StableUndirectedGraph(vertices: [0, 1], edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 1)])
        #expect(twoLoops != loopEach)
        #expect(Set([a, b, c]).count == 2)
        #expect(StableUndirectedGraph<Int>() == StableUndirectedGraph<Int>(vertices: [Int]()))
        #expect(StableUndirectedGraph(vertices: [0]) != StableUndirectedGraph(vertices: [1]))
    }

    @Test("Codable keeps every position, orientation and end; a malformed payload throws")
    func codable() throws {
        var graph = StableUndirectedGraph(vertices: ["x", "y", "z"], edges: [UndirectedEdge("x", "y"), UndirectedEdge("z", "y"), UndirectedEdge("y", "y")])
        graph.remove("x")
        graph.insert(edge: UndirectedEdge("z", "w"))
        let data = try JSONEncoder().encode(graph)
        let decoded = try JSONDecoder().decode(StableUndirectedGraph<String>.self, from: data)
        #expect(decoded == graph)
        #expect(Array(decoded.vertices.indices) == Array(graph.vertices.indices) && decoded.vertices.endIndex == 4)
        #expect(Array(decoded.edges.indices) == [1, 2, 3] && decoded.edges.endIndex == 4)
        #expect(decoded.edges.map { [$0.u, $0.v] } == [["z", "y"], ["y", "y"], ["z", "w"]])
        var next = decoded
        #expect(next.insert(edge: UndirectedEdge("w", "y")) == 4)
        #expect(next.insert("v").inserted && Array(next.vertices.indices).last == 4)
        // The same format as StableDirectedGraph's.
        let directed = try JSONDecoder().decode(StableDirectedGraph<String>.self, from: data)
        #expect(Array(directed.edges) == [DirectedEdge(from: "z", to: "y"), DirectedEdge(from: "y", to: "y"), DirectedEdge(from: "z", to: "w")])
        let odd = #"{"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0],"edgePositions":[0],"edgeEnd":1}"#
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(StableUndirectedGraph<Int>.self, from: Data(odd.utf8)) }
        let repeated = #"{"vertices":[0,0],"vertexPositions":[0,1],"vertexEnd":2,"edges":[],"edgePositions":[],"edgeEnd":0}"#
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(StableUndirectedGraph<Int>.self, from: Data(repeated.utf8)) }
    }

    @Test("Descriptions, Sendable, and the mirror")
    func descriptions() async {
        var graph = StableUndirectedGraph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        graph.remove(edgeAt: 0)
        #expect(graph.description == "[0, 1]; [1–1]")
        #expect(graph.debugDescription == "StableUndirectedGraph<Int>(vertexCount: 2, edgeCount: 1, vertices: [0, 1], edges: [1–1])")
        #expect(Mirror(reflecting: graph).children.map { $0.label } == ["vertices", "edges"])
        let copy = graph
        let count = await Task { copy.edgeCount }.value
        #expect(count == 1)
    }

    @Test("Every structural mutation starts a generation; a call that changes nothing and map writes do not")
    func generations() {
        var graph = StableUndirectedGraph(vertices: [0, 1])
        var seen = [graph.generation]
        func changed() -> Bool {
            let now = graph.generation
            defer { seen.append(now) }
            return !seen.contains(now)
        }
        graph.insert(edge: UndirectedEdge(0, 1))
        #expect(changed())
        graph.insert(2)
        #expect(changed())
        graph.insert(2)
        #expect(!changed())
        #expect(graph.remove(edge: UndirectedEdge(0, 2)) == nil)
        #expect(!changed())
        let weights = graph.addEdgeMap(default: 0)
        graph[weights, ofEdgeAt: 0] = 3
        #expect(!changed())
        graph.remove(edge: UndirectedEdge(1, 0))
        #expect(changed())
        graph.remove(1)
        #expect(changed())
        #expect(graph.generation.isCurrent(for: graph))
        let copy = graph
        #expect(copy.generation == graph.generation)
        graph.insert(edge: UndirectedEdge(0, 2))
        #expect(copy.generation != graph.generation)
    }

    @Test("Attached maps keep each element's value at its position across removals; removed elements have none")
    func maps() throws {
        var graph = StableUndirectedGraph(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "a")])
        let weights = graph.addEdgeMap(default: 1.0)
        let labels = graph.addEdgeMap(of: String.self)
        let ranks = graph.addVertexMap(default: 0)
        graph[weights, ofEdgeAt: 2] = 5
        graph[labels, ofEdgeAt: 1] = "bc"
        graph[ranks, of: "c"] = 7
        graph[ranks, ofVertexAt: 1] = 4
        graph.remove(edgeAt: 0)
        #expect(graph[weights, ofEdgeAt: 2] == 5 && graph[labels, ofEdgeAt: 1] == "bc")
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 0] }
        #expect(try graph[weights, checkedEdgeAt: 1] == 1)
        graph.remove("b")
        #expect(throws: EdgeNotFound.self) { try graph[labels, checkedEdgeAt: 1] }
        #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: 1] }
        #expect(throws: VertexNotFound.self) { try graph[ranks, checked: "b"] }
        #expect(try graph[ranks, checked: "c"] == 7 && graph[ranks, ofVertexAt: 2] == 7)
        // A new element reads the default.
        let p = graph.insert(edge: UndirectedEdge("a", "d"))
        #expect(p == 3 && graph[weights, ofEdgeAt: p] == 1 && graph[labels, ofEdgeAt: p] == nil && graph[ranks, of: "d"] == 0)
        let snapshot = graph.values(of: weights)
        graph[weights, ofEdgeAt: 2] = 6
        #expect(snapshot[2] == 5 && graph.values(of: weights)[2] == 6)
        #expect(graph.values(of: ranks)[2] == 7)
        graph.removeEdgeMap(labels)
        graph.removeVertexMap(ranks)
        // A copy shares the maps until either writes.
        var copy = graph
        copy[weights, ofEdgeAt: 3] = 9
        #expect(graph[weights, ofEdgeAt: 3] == 1 && copy[weights, ofEdgeAt: 3] == 9)
        // Equality and coding ignore maps.
        #expect(copy == graph)
    }

    @Test("Through MutableGraph: generic building by key and the bulk build give the same graph and positions")
    func mutableGraph() {
        func build<G: MutableGraph<Int>>(_: G.Type) -> G {
            var graph = G()
            let a = graph._insertVertex(4), b = graph._insertVertex(7)
            _ = graph._insertEdge(fromKey: b, toKey: a)
            _ = graph._insertEdge(fromKey: a, toKey: a)
            return graph
        }
        let graph = build(StableUndirectedGraph<Int>.self)
        #expect(Array(graph.vertices) == [4, 7] && graph.edges.map { [$0.u, $0.v] } == [[7, 4], [4, 4]])
        #expect(graph._key(of: 7) == 1 && graph._key(of: 5) == nil && graph._vertex(atKey: 0) == 4)
        let (built, positions) = StableUndirectedGraph<Int>._built(vertices: [4, 7], uKeys: [1, 0], vKeys: [0, 0], reportingPositions: true, _ConstructionToken())
        #expect(built == graph && positions == [0, 1] && built.edges.map { [$0.u, $0.v] } == [[7, 4], [4, 4]])
    }
}
