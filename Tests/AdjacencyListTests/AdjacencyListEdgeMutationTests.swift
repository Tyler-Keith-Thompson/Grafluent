// Inserting and removing edges. Case IDs (E-nn, P-nn) refer to the harvested test catalog.
//
// Tests taking `isShared` run twice: once on a uniquely referenced graph, and once while a copy
// of it exists, which must come through the mutation unchanged.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList edge insertion and removal")
struct AdjacencyListEdgeMutationTests {
    // MARK: Insertion

    @Test("inserting a new edge between existing vertices", arguments: [false, true])
    func insertNew(isShared: Bool) {
        // The Boost.Graph house DAG.
        var graph = AdjacencyList(edges: [
            DirectedEdge(from: 5, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0),
        ])
        let copy: AdjacencyList<Int>? = isShared ? graph : nil

        let result = graph.insert(DirectedEdge(from: 0, to: 5))

        #expect(result.inserted)
        #expect(result.memberAfterInsert == DirectedEdge(from: 0, to: 5))
        #expect(graph.edgeCount == 8)
        #expect(graph.vertexCount == 6)
        #expect(graph.contains(DirectedEdge(from: 0, to: 5)))
        #expect(Array(graph.successors(of: 0)) == [5])
        #expect(Set(graph.predecessors(of: 5)) == [0])
        #expect(graph.outDegree(of: 0) == 1)
        #expect(graph.inDegree(of: 5) == 1)
        if let copy {
            #expect(copy.edgeCount == 7)
            #expect(!copy.contains(DirectedEdge(from: 0, to: 5)))
            #expect(copy.successors(of: 0).isEmpty)
        }
    }

    @Test("E-01 inserting an existing edge changes nothing and reports it", .tags(.fixture), arguments: DirectedFixture<Int>.nonempty, [false, true])
    func insertExisting(_ fixture: DirectedFixture<Int>, isShared: Bool) {
        let original = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for edge in fixture.edgeSet {
            var graph = original
            let copy: AdjacencyList<Int>? = isShared ? graph : nil

            let result = graph.insert(edge)

            #expect(!result.inserted, "\(edge)")
            #expect(result.memberAfterInsert == edge)
            #expect(graph == original)
            #expect(graph.edgeCount == fixture.edgeCount)
            if let copy {
                #expect(copy == original)
            }
        }
    }

    @Test("P-05 insert reports exactly whether the edge was absent", .tags(.exhaustive, .fixture), arguments: DirectedFixture<Int>.all)
    func insertReportsAbsence(_ fixture: DirectedFixture<Int>) {
        // Every ordered pair, self-loops included, over a 4-vertex universe.
        for source in 0 ..< 4 {
            for target in 0 ..< 4 {
                var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
                let edge = DirectedEdge(from: source, to: target)
                let wasPresent = graph.contains(edge)
                #expect(wasPresent == fixture.edgeSet.contains(edge))
                #expect(graph.insert(edge).inserted == !wasPresent, "\(edge)")
                #expect(graph.contains(edge))
                #expect(graph.edgeCount == fixture.edgeCount + (wasPresent ? 0 : 1))
            }
        }
    }

    @Test("E-03 the antiparallel edge is a different edge")
    func insertAntiparallel() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: "d", to: "e")])
        #expect(graph.insert(DirectedEdge(from: "e", to: "d")).inserted)
        #expect(graph.edgeCount == 2)
        #expect(graph.degree(of: "d") == 2)
        #expect(graph.degree(of: "e") == 2)
    }

    @Test("E-06 a self-loop can be inserted and removed", .tags(.selfLoops), arguments: [false, true])
    func selfLoop(isShared: Bool) {
        var graph = AdjacencyList(vertices: ["a"])
        let copy: AdjacencyList<String>? = isShared ? graph : nil
        let selfLoop = DirectedEdge(from: "a", to: "a")
        #expect(selfLoop.isSelfLoop)

        graph.insert(selfLoop)
        #expect(graph.contains(selfLoop))
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.successors(of: "a")) == ["a"])
        #expect(Array(graph.predecessors(of: "a")) == ["a"])
        #expect(!graph.insert(selfLoop).inserted)
        #expect(graph.edgeCount == 1)

        #expect(graph.remove(selfLoop) == selfLoop)
        #expect(!graph.contains(selfLoop))
        #expect(graph.edgeCount == 0)
        #expect(graph.vertexCount == 1)
        #expect(graph.successors(of: "a").isEmpty)
        if let copy {
            #expect(copy.edgeCount == 0)
            #expect(copy.vertexCount == 1)
        }
    }

    @Test("E-09 inserting an edge inserts any missing endpoint")
    func insertInsertsEndpoints() {
        var graph = AdjacencyList(vertices: [1])
        graph.insert(DirectedEdge(from: 1, to: 2))
        #expect(Set(graph.vertices) == [1, 2])
        graph.insert(DirectedEdge(from: 3, to: 4))
        #expect(Set(graph.vertices) == [1, 2, 3, 4])
        graph.insert(DirectedEdge(from: 5, to: 5))
        #expect(Set(graph.vertices) == [1, 2, 3, 4, 5])
        #expect(graph.edgeCount == 3)
        #expect(graph.inDegree(of: 4) == 1)
        #expect(graph.outDegree(of: 3) == 1)
    }

    @Test("V-03 an inserted edge's endpoints are the stored vertex instances")
    func insertedEdgeUsesStoredVertices() {
        let stored = HashableBox(1, label: "stored")
        var graph = AdjacencyList(vertices: [stored])
        let result = graph.insert(DirectedEdge(from: HashableBox(1, label: "probe"), to: HashableBox(2)))
        #expect(result.inserted)
        #expect(result.memberAfterInsert.source === stored)
        #expect(graph.edges.first?.source === stored)
        #expect(graph.predecessors(of: HashableBox(2)).first === stored)
        #expect(graph.vertexCount == 2)
    }

    // MARK: Removal

    @Test("E-10 removing an edge removes that direction only", arguments: [false, true])
    func removeOneDirection(isShared: Bool) {
        var graph = AdjacencyList(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 0),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1),
        ])
        let copy: AdjacencyList<Int>? = isShared ? graph : nil

        #expect(graph.remove(DirectedEdge(from: 0, to: 1)) == DirectedEdge(from: 0, to: 1))

        #expect(Set(graph.successors(of: 0)) == [2])
        #expect(Set(graph.predecessors(of: 1)) == [2])
        #expect(Set(graph.successors(of: 1)) == [0, 2])
        #expect(Set(graph.predecessors(of: 0)) == [1, 2])
        #expect(graph.contains(DirectedEdge(from: 1, to: 0)))
        #expect(!graph.contains(DirectedEdge(from: 0, to: 1)))
        #expect(graph.edgeCount == 5)
        if let copy {
            #expect(copy.edgeCount == 6)
            #expect(copy.contains(DirectedEdge(from: 0, to: 1)))
            #expect(Set(copy.successors(of: 0)) == [1, 2])
        }
    }

    @Test("E-12 removing an absent edge returns nil and changes nothing", .tags(.fixture), arguments: DirectedFixture<Int>.all, [false, true])
    func removeAbsent(_ fixture: DirectedFixture<Int>, isShared: Bool) {
        let original = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        // Reversed edges that are not themselves present, plus edges with absent endpoints.
        var candidates = fixture.edgeSet.map { DirectedEdge(from: $0.target, to: $0.source) }.filter { !fixture.edgeSet.contains($0) }
        candidates += [DirectedEdge(from: -1, to: -2), DirectedEdge(from: -1, to: -1)]
        if let v = fixture.vertexSet.min() {
            candidates += [DirectedEdge(from: v, to: -1), DirectedEdge(from: -1, to: v)]
        }
        for edge in candidates {
            var graph = original
            let copy: AdjacencyList<Int>? = isShared ? graph : nil

            #expect(graph.remove(edge) == nil, "\(edge)")

            #expect(graph == original, "removing \(edge) changed the graph")
            #expect(graph.vertexCount == fixture.vertexCount)
            if let copy {
                #expect(copy == original)
            }
        }
    }

    @Test("E-12 removing an edge never inserts its endpoints")
    func removeDoesNotInsert() {
        var graph = AdjacencyList(vertices: [1])
        #expect(graph.remove(DirectedEdge(from: 1, to: 2)) == nil)
        #expect(graph.remove(DirectedEdge(from: 3, to: 4)) == nil)
        #expect(Array(graph.vertices) == [1])
    }

    @Test("P-04 remove succeeds exactly when the edge is present, and only once", .tags(.fixture), arguments: DirectedFixture<Int>.nonempty)
    func removeSucceedsOnce(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for edge in fixture.edgeSet {
            #expect(graph.remove(edge) == edge)
            #expect(graph.remove(edge) == nil)
            #expect(!graph.contains(edge))
        }
        #expect(graph.edgeCount == 0)
    }

    @Test("E-17 removing every edge keeps every vertex", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func removingEdgesKeepsVertices(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for (i, edge) in fixture.edgeSet.enumerated() {
            graph.remove(edge)
            #expect(graph.edgeCount == fixture.edgeCount - i - 1)
            #expect(graph.vertexCount == fixture.vertexCount)
            #expect(!graph.successors(of: edge.source).contains(edge.target))
            #expect(!graph.predecessors(of: edge.target).contains(edge.source))
        }
        #expect(graph == AdjacencyList(vertices: fixture.vertexSet))
    }

    @Test("E-18 Boost.Graph disconnect sequence on the house DAG")
    func boostDisconnectSequence() {
        // Boost.Graph test/test_destruction.hpp.
        var graph = AdjacencyList(edges: [
            DirectedEdge(from: 5, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0),
        ])
        graph.remove(DirectedEdge(from: 5, to: 3))
        #expect(graph.edgeCount == 6)
        graph.remove(DirectedEdge(from: 3, to: 2))
        #expect(graph.edgeCount == 5)
        // Boost's clear_vertex(0): remove the edges incident to 0 but keep the vertex.
        for u in Array(graph.predecessors(of: 0)) { graph.remove(DirectedEdge(from: u, to: 0)) }
        for w in Array(graph.successors(of: 0)) { graph.remove(DirectedEdge(from: 0, to: w)) }
        #expect(graph.edgeCount == 3)
        #expect(graph.remove(DirectedEdge(from: 5, to: 0)) == nil)
        #expect(graph.edgeCount == 3)
        #expect(graph.vertexCount == 6)
        #expect(Set(graph.edges) == [DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 1), DirectedEdge(from: 2, to: 1)])
    }

    @Test("remove returns the stored edge, whose endpoints are the stored instances")
    func removeReturnsStoredEdge() {
        let a = HashableBox(1, label: "stored")
        let b = HashableBox(2, label: "stored")
        var graph = AdjacencyList(edges: [DirectedEdge(from: a, to: b)])
        let removed = graph.remove(DirectedEdge(from: HashableBox(1), to: HashableBox(2)))
        #expect(removed?.source === a)
        #expect(removed?.target === b)
    }

    // MARK: Removing while iterating

    @Test("E-16 removing every self-loop while iterating over `edges`", .tags(.selfLoops, .copyOnWrite), arguments: DirectedFixture<Int>.all)
    func removeSelfLoopsWhileIterating(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for edge in graph.edges where edge.isSelfLoop {
            graph.remove(edge)
        }
        #expect(Set(graph.edges) == fixture.edgeSet.filter { !$0.isSelfLoop })
        #expect(graph.vertexCount == fixture.vertexCount)
    }

    @Test("removing every edge while iterating over `edges`", .tags(.copyOnWrite), arguments: DirectedFixture<Int>.all)
    func removeEdgesWhileIterating(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        var visited: [DirectedEdge<Int>] = []
        for edge in graph.edges {
            visited.append(edge)
            #expect(graph.remove(edge) != nil)
        }
        #expect(visited.count == fixture.edgeCount)
        #expect(Set(visited) == fixture.edgeSet)
        #expect(graph.edgeCount == 0)
    }
}
