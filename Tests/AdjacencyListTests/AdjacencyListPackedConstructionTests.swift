// The bulk initializers lay the rows out once, packed in slot order, and must build the graph that
// inserting the same vertices and edges one at a time builds: the same vertex slots, the same edge
// positions (and, undirected, orientations), the same rows. The lent row tables are checked for
// the packed layout (row v starts where row v - 1 ends, at its exact size) and for the one table
// both pools share, before and after mutations that grow, move and remove rows.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("AdjacencyList and UndirectedAdjacencyList packed bulk construction")
struct AdjacencyListPackedConstructionTests {
    @Test("AdjacencyList(vertices:edges:) is the inserted graph, slot for slot and position for position, with packed rows")
    func directedMatchesInsertion() {
        let vertices = ["c", "a", "c", "e"]
        let edges = [("a", "b"), ("b", "a"), ("a", "b"), ("d", "d"), ("c", "a"), ("b", "a"), ("e", "c"), ("d", "d"), ("a", "d")]
            .map { DirectedEdge(from: $0.0, to: $0.1) }
        let bulk = AdjacencyList(vertices: vertices, edges: edges)
        var inserted = AdjacencyList<String>()
        for v in vertices { inserted.insert(v) }
        for edge in edges { inserted.insert(edge: edge) }
        #expect(Array(bulk.vertices) == ["c", "a", "e", "b", "d"])
        #expect(Array(bulk.vertices) == Array(inserted.vertices))
        #expect(Array(bulk.edges) == Array(inserted.edges))
        #expect(bulk.edgeCount == 6)
        for v in 0 ..< bulk.vertexCount {
            #expect(Array(bulk.successorIndices(ofIndex: v)) == Array(inserted.successorIndices(ofIndex: v)))
            #expect(Array(bulk.outEdges(ofIndex: v)) == Array(inserted.outEdges(ofIndex: v)))
            #expect(Array(bulk.predecessorIndices(ofIndex: v)) == Array(inserted.predecessorIndices(ofIndex: v)))
            #expect(Array(bulk.inEdges(ofIndex: v)) == Array(inserted.inEdges(ofIndex: v)))
        }
        #expect(bulk.contains(edge: DirectedEdge(from: "d", to: "d")))
        #expect(!bulk.contains(edge: DirectedEdge(from: "d", to: "a")))
        #expect(Array(bulk.edges(from: "e", to: "c")) == Array(inserted.edges(from: "e", to: "c")))
        let packed = bulk._withOutIndexRows { _, targetRows, _, edgeRows -> Bool in
            var next = 0
            for v in 0 ..< bulk.vertexCount {
                guard targetRows[3 * v] == next, targetRows[3 * v + 2] == targetRows[3 * v + 1] else { return false }
                next += targetRows[3 * v + 1]
            }
            return next == bulk.edgeCount && edgeRows.baseAddress == targetRows.baseAddress
        }
        #expect(packed == true)
    }

    @Test("AdjacencyList: init(edges:), init(adjacency:), the dictionary literal, init(_:) and decoding build packed rows")
    func directedOtherInitializers() throws {
        let edges = [(1, 2), (2, 3), (1, 2), (3, 1), (4, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let fromEdges = AdjacencyList(edges: edges)
        #expect(Array(fromEdges.vertices) == [1, 2, 3, 4])
        #expect(Array(fromEdges.edges) == [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 1), DirectedEdge(from: 4, to: 4)])
        let literal: AdjacencyList<Int> = [1: [2, 2], 2: [3], 3: [1], 4: [4], 5: []]
        #expect(Array(literal.vertices) == [1, 2, 3, 4, 5])
        #expect(Array(literal.edges) == Array(fromEdges.edges))
        let adjacency = AdjacencyList(adjacency: [1: [2, 2], 2: [3], 3: [1], 4: [4], 5: []])
        #expect(adjacency.vertexCount == 5 && adjacency.edgeCount == 4 && adjacency.contains(edge: DirectedEdge(from: 3, to: 1)))
        // Each undirected edge as two arcs (a self-loop's arcs collapse into one).
        let copy = AdjacencyList(UndirectedAdjacencyList(edges: [UndirectedEdge(1, 2), UndirectedEdge(4, 4)]).directedView)
        #expect(Array(copy.vertices) == [1, 2, 4] && copy.edgeCount == 3)
        #expect(copy.contains(edge: DirectedEdge(from: 1, to: 2)) && copy.contains(edge: DirectedEdge(from: 2, to: 1)) && copy.contains(edge: DirectedEdge(from: 4, to: 4)))
        let decoded = try JSONDecoder().decode(AdjacencyList<Int>.self, from: JSONEncoder().encode(fromEdges))
        #expect(Array(decoded.vertices) == Array(fromEdges.vertices))
        #expect(Array(decoded.edges) == Array(fromEdges.edges))
        for graph in [fromEdges, literal, adjacency, copy, decoded] {
            let packed = graph._withOutIndexRows { _, targetRows, _, edgeRows -> Bool in
                var next = 0
                for v in 0 ..< graph.vertexCount {
                    guard targetRows[3 * v] == next, targetRows[3 * v + 2] == targetRows[3 * v + 1] else { return false }
                    next += targetRows[3 * v + 1]
                }
                return next == graph.edgeCount && edgeRows.baseAddress == targetRows.baseAddress
            }
            #expect(packed == true)
        }
    }

    @Test("AdjacencyList: decoding rejects a repeated edge, a repeated vertex and an endpoint out of range")
    func directedDecodingRejects() {
        for json in [#"{"vertices":[0,1],"edges":[0,1,1,0,0,1]}"#, #"{"vertices":[0,0],"edges":[]}"#, #"{"vertices":[0,1],"edges":[0,2]}"#] {
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(AdjacencyList<Int>.self, from: Data(json.utf8)) }
        }
        let loops = #"{"vertices":[0,1],"edges":[0,0,1,1,0,1,1,0]}"#
        #expect((try? JSONDecoder().decode(AdjacencyList<Int>.self, from: Data(loops.utf8)))?.edgeCount == 4)
    }

    @Test("UndirectedAdjacencyList(vertices:edges:) is the inserted graph, with each edge in its first orientation and packed rows")
    func undirectedMatchesInsertion() {
        let vertices = ["c", "a"]
        let edges = [("a", "b"), ("b", "a"), ("d", "d"), ("c", "a"), ("a", "c"), ("d", "d"), ("b", "d")].map { UndirectedEdge($0.0, $0.1) }
        let bulk = UndirectedAdjacencyList(vertices: vertices, edges: edges)
        var inserted = UndirectedAdjacencyList<String>()
        for v in vertices { inserted.insert(v) }
        for edge in edges { inserted.insert(edge: edge) }
        #expect(Array(bulk.vertices) == ["c", "a", "b", "d"])
        #expect(Array(bulk.vertices) == Array(inserted.vertices))
        #expect(bulk.edgeCount == 4)
        for p in 0 ..< bulk.edgeCount {
            #expect(bulk.endpointIndices(ofEdgeAt: p) == inserted.endpointIndices(ofEdgeAt: p))
        }
        #expect(bulk.endpointIndices(ofEdgeAt: 0) == (1, 2))
        for v in 0 ..< bulk.vertexCount {
            #expect(Array(bulk.neighborIndices(ofIndex: v)) == Array(inserted.neighborIndices(ofIndex: v)))
            #expect(Array(bulk.incidentEdges(ofIndex: v)) == Array(inserted.incidentEdges(ofIndex: v)))
        }
        #expect(bulk.degree(of: "d") == 3)
        #expect(bulk.contains(edge: UndirectedEdge("a", "c")))
        let packed = bulk._withIncidentIndexRows { _, rows, _, edgeRows -> Bool in
            var next = 0
            for v in 0 ..< bulk.vertexCount {
                guard rows[3 * v] == next, rows[3 * v + 2] == rows[3 * v + 1] else { return false }
                next += rows[3 * v + 1]
            }
            return next == 2 * bulk.edgeCount && edgeRows.baseAddress == rows.baseAddress
        }
        #expect(packed == true)
    }

    @Test("UndirectedAdjacencyList: init(edges:), init(adjacency:), the dictionary literal, init(_:) and decoding build packed rows")
    func undirectedOtherInitializers() throws {
        let edges = [(1, 2), (2, 3), (2, 1), (3, 1), (4, 4)].map { UndirectedEdge($0.0, $0.1) }
        let fromEdges = UndirectedAdjacencyList(edges: edges)
        #expect(Array(fromEdges.vertices) == [1, 2, 3, 4])
        #expect(fromEdges.edgeCount == 4)
        let literal: UndirectedAdjacencyList<Int> = [1: [2], 2: [3, 1], 3: [1], 4: [4], 5: []]
        #expect(Array(literal.vertices) == [1, 2, 3, 4, 5] && literal.edgeCount == 4)
        #expect(literal.contains(edge: UndirectedEdge(1, 3)) && literal.degree(of: 5) == 0)
        let adjacency = UndirectedAdjacencyList(adjacency: [1: [2], 2: [1, 3], 3: [1], 4: [4], 5: []])
        #expect(adjacency.vertexCount == 5 && adjacency.edgeCount == 4)
        // Each edge comes back twice through the two views, and the copies collapse.
        let copy = UndirectedAdjacencyList(fromEdges.directedView.undirectedView)
        #expect(copy == fromEdges)
        let decoded = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(fromEdges))
        #expect(Array(decoded.vertices) == Array(fromEdges.vertices))
        for p in 0 ..< fromEdges.edgeCount { #expect(decoded.endpointIndices(ofEdgeAt: p) == fromEdges.endpointIndices(ofEdgeAt: p)) }
        for graph in [fromEdges, literal, adjacency, copy, decoded] {
            let packed = graph._withIncidentIndexRows { _, rows, _, edgeRows -> Bool in
                var next = 0
                for v in 0 ..< graph.vertexCount {
                    guard rows[3 * v] == next, rows[3 * v + 2] == rows[3 * v + 1] else { return false }
                    next += rows[3 * v + 1]
                }
                return next == 2 * graph.edgeCount && edgeRows.baseAddress == rows.baseAddress
            }
            #expect(packed == true)
        }
    }

    @Test("UndirectedAdjacencyList: decoding rejects an edge repeated in either orientation")
    func undirectedDecodingRejects() {
        for json in [#"{"vertices":[0,1],"edges":[0,1,1,0]}"#, #"{"vertices":[0,1],"edges":[1,1,1,1]}"#, #"{"vertices":[0,0],"edges":[]}"#, #"{"vertices":[0],"edges":[0,1]}"#] {
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: Data(json.utf8)) }
        }
        let distinct = #"{"vertices":[0,1],"edges":[0,0,1,1,0,1]}"#
        #expect((try? JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: Data(distinct.utf8)))?.edgeCount == 3)
    }

    @Test("Graphs built and changed by insertion lend one row table for both pools")
    func sharedTableAfterInsertion() {
        var directed = AdjacencyList<Int>()
        var undirected = UndirectedAdjacencyList<Int>()
        for (u, v) in [(0, 1), (1, 2), (2, 0), (0, 3), (0, 4), (0, 5), (3, 3)] {
            directed.insert(edge: DirectedEdge(from: u, to: v))
            undirected.insert(edge: UndirectedEdge(u, v))
        }
        #expect(directed.remove(edge: DirectedEdge(from: 0, to: 1)) != nil)
        #expect(undirected.remove(1) == 1)
        #expect(directed._withOutIndexRows { _, targetRows, _, edgeRows in edgeRows.baseAddress == targetRows.baseAddress } == true)
        #expect(undirected._withIncidentIndexRows { _, rows, _, edgeRows in edgeRows.baseAddress == rows.baseAddress } == true)
        let lent = directed._withOutIndexRows { _, _, edges, edgeRows in (0 ..< directed.vertexCount).map { v in Array(edges[edgeRows[3 * v] ..< edgeRows[3 * v] + edgeRows[3 * v + 1]]) } }
        #expect(lent == (0 ..< directed.vertexCount).map { Array(directed.outEdges(ofIndex: $0)) })
    }

    @Test("Empty and edgeless bulk builds")
    func empty() {
        let none = AdjacencyList<Int>(edges: [])
        #expect(none.vertexCount == 0 && none.edgeCount == 0 && !none.contains(edge: DirectedEdge(from: 0, to: 0)))
        let isolated = AdjacencyList(vertices: [3, 1, 3], edges: [])
        #expect(Array(isolated.vertices) == [3, 1] && isolated.edgeCount == 0 && isolated.outDegree(of: 1) == 0)
        let undirected = UndirectedAdjacencyList(vertices: ["x"], edges: [])
        #expect(undirected.vertexCount == 1 && undirected.edgeCount == 0 && undirected.degree(of: "x") == 0)
        var grown = isolated
        grown.insert(edge: DirectedEdge(from: 1, to: 3))
        #expect(grown.contains(edge: DirectedEdge(from: 1, to: 3)) && isolated.edgeCount == 0)
    }

    @Test("AdjacencyList: a bulk build then random mutations matches the same inserted and mutated graph, rows and shared table included", .tags(.randomized))
    func directedProperty() async {
        // Edges among vertices 0...7, then (operation, a, b) mutations.
        let input = zip(
            zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 40),
            zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 40)
        )
        await propertyCheck(count: 300, input: input) { input in
            let (pairs, operations) = input
            let edges = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            var bulk = AdjacencyList(edges: edges)
            var inserted = AdjacencyList<Int>()
            for edge in edges { inserted.insert(edge: edge) }
            #expect(Array(bulk.vertices) == Array(inserted.vertices))
            #expect(Array(bulk.edges) == Array(inserted.edges))
            for (operation, a, b) in operations {
                let edge = DirectedEdge(from: a, to: b)
                switch operation {
                case 0, 1:
                    #expect(bulk.insert(edge: edge).inserted == inserted.insert(edge: edge).inserted)
                case 2:
                    #expect(bulk.remove(edge: edge) == inserted.remove(edge: edge))
                default:
                    #expect(bulk.remove(a) == inserted.remove(a))
                }
            }
            #expect(Array(bulk.vertices) == Array(inserted.vertices))
            #expect(Array(bulk.edges) == Array(inserted.edges))
            let n = bulk.vertexCount
            let lent = bulk._withOutIndexRows { targets, targetRows, edges, edgeRows -> [[Int]] in
                (0 ..< n).map { v in
                    let start = targetRows[3 * v], length = targetRows[3 * v + 1], edgeStart = edgeRows[3 * v]
                    return Array(targets[start ..< start + length]) + Array(edges[edgeStart ..< edgeStart + length])
                }
            }
            #expect(bulk._withOutIndexRows { _, targetRows, _, edgeRows in edgeRows.baseAddress == targetRows.baseAddress } == true)
            for v in 0 ..< n {
                #expect(lent?[v] == Array(bulk.successorIndices(ofIndex: v)) + Array(bulk.outEdges(ofIndex: v)))
                #expect(Array(bulk.successorIndices(ofIndex: v)) == Array(inserted.successorIndices(ofIndex: v)))
                #expect(Array(bulk.inEdges(ofIndex: v)) == Array(inserted.inEdges(ofIndex: v)))
            }
        }
    }

    @Test("UndirectedAdjacencyList: a bulk build then random mutations matches the same inserted and mutated graph, rows and shared table included", .tags(.randomized))
    func undirectedProperty() async {
        let input = zip(
            zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 40),
            zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 40)
        )
        await propertyCheck(count: 300, input: input) { input in
            let (pairs, operations) = input
            let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
            var bulk = UndirectedAdjacencyList(edges: edges)
            var inserted = UndirectedAdjacencyList<Int>()
            for edge in edges { inserted.insert(edge: edge) }
            #expect(Array(bulk.vertices) == Array(inserted.vertices))
            for p in 0 ..< bulk.edgeCount { #expect(bulk.endpointIndices(ofEdgeAt: p) == inserted.endpointIndices(ofEdgeAt: p)) }
            for (operation, a, b) in operations {
                let edge = UndirectedEdge(a, b)
                switch operation {
                case 0, 1:
                    #expect(bulk.insert(edge: edge).inserted == inserted.insert(edge: edge).inserted)
                case 2:
                    #expect(bulk.remove(edge: edge) == inserted.remove(edge: edge))
                default:
                    #expect(bulk.remove(a) == inserted.remove(a))
                }
            }
            #expect(Array(bulk.vertices) == Array(inserted.vertices))
            #expect(bulk.edgeCount == inserted.edgeCount)
            for p in 0 ..< bulk.edgeCount { #expect(bulk.endpointIndices(ofEdgeAt: p) == inserted.endpointIndices(ofEdgeAt: p)) }
            let n = bulk.vertexCount
            let lent = bulk._withIncidentIndexRows { neighbors, rows, edges, edgeRows -> [[Int]] in
                (0 ..< n).map { v in
                    let start = rows[3 * v], length = rows[3 * v + 1], edgeStart = edgeRows[3 * v]
                    return Array(neighbors[start ..< start + length]) + Array(edges[edgeStart ..< edgeStart + length])
                }
            }
            #expect(bulk._withIncidentIndexRows { _, rows, _, edgeRows in edgeRows.baseAddress == rows.baseAddress } == true)
            for v in 0 ..< n {
                #expect(lent?[v] == Array(bulk.neighborIndices(ofIndex: v)) + Array(bulk.incidentEdges(ofIndex: v)))
                #expect(Array(bulk.neighborIndices(ofIndex: v)) == Array(inserted.neighborIndices(ofIndex: v)))
                #expect(Array(bulk.incidentEdges(ofIndex: v)) == Array(inserted.incidentEdges(ofIndex: v)))
            }
        }
    }
}
