// Inserting and removing vertices. Case IDs (V-nn) refer to the harvested test catalog.
//
// Tests taking `isShared` run twice: once on a uniquely referenced graph, and once while a copy
// of it exists, which must come through the mutation unchanged.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList vertex insertion and removal")
struct AdjacencyListVertexMutationTests {
    // MARK: Insertion

    @Test("V-01 / V-02 inserting a new vertex reports it, and the vertex is isolated", arguments: [false, true])
    func insertNew(isShared: Bool) {
        // The Boost.Graph house DAG: 6 vertices, 7 edges.
        var graph = AdjacencyList(edges: [
            DirectedEdge(from: 5, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0),
        ])
        let copy: AdjacencyList<Int>? = isShared ? graph : nil

        let result = graph.insert(99)

        #expect(result.inserted)
        #expect(result.memberAfterInsert == 99)
        #expect(graph.vertexCount == 7)
        #expect(graph.edgeCount == 7)
        #expect(graph.contains(99))
        #expect(graph.degree(of: 99) == 0)
        #expect(graph.successors(of: 99).isEmpty)
        #expect(graph.predecessors(of: 99).isEmpty)
        if let copy {
            #expect(copy.vertexCount == 6)
            #expect(!copy.contains(99))
        }
    }

    @Test("V-01 inserting an existing vertex changes nothing", arguments: [false, true])
    func insertExisting(isShared: Bool) {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 5, to: 3)])
        let copy: AdjacencyList<Int>? = isShared ? graph : nil

        let result = graph.insert(3)

        #expect(!result.inserted)
        #expect(result.memberAfterInsert == 3)
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 3)
        #expect(graph.outDegree(of: 3) == 2, "inserting an existing vertex must not clear its edges")
        #expect(graph.inDegree(of: 3) == 1)
        if let copy {
            #expect(copy == graph)
        }
    }

    @Test("V-01 inserting the same vertex repeatedly is idempotent")
    func insertIdempotent() {
        var graph = AdjacencyList<String>()
        for _ in 0 ..< 5 { graph.insert("m") }
        #expect(graph.vertexCount == 1)
        #expect(Array(graph.vertices) == ["m"])
    }

    @Test("V-03 an equal vertex is not stored again: the first instance is kept and returned")
    func insertKeepsFirstInstance() {
        let first = HashableBox(1, label: "first")
        let second = HashableBox(1, label: "second")
        var graph = AdjacencyList<HashableBox>()
        graph.insert(first)
        let result = graph.insert(second)
        #expect(!result.inserted)
        #expect(result.memberAfterInsert === first)
        #expect(graph.vertices.first === first)
        #expect(graph.vertexCount == 1)
    }

    // MARK: Removal

    @Test("V-04 removing a vertex removes its edges in both directions")
    func removeFromCycle() {
        // JGraphT SimpleDirectedGraphTest g4: 1→2→3→4→1. Each removal takes the vertex's one
        // incoming and one outgoing edge.
        var graph = AdjacencyList(edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 4, to: 1)])

        #expect(graph.remove(1) == 1)
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(graph.predecessors(of: 2).isEmpty)
        #expect(graph.successors(of: 4).isEmpty)
        #expect(Set(graph.edges) == [DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 4)])

        #expect(graph.remove(2) == 2)
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)

        #expect(graph.remove(3) == 3)
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0)

        #expect(graph.remove(4) == 4)
        #expect(graph.vertexCount == 0)
        #expect(graph == AdjacencyList())
    }

    @Test(
        "removing any vertex removes exactly its incident edges",
        .tags(.fixture),
        arguments: DirectedFixture<Int>.all.filter { !$0.vertexSet.isEmpty }, [false, true]
    )
    func removeEachVertex(_ fixture: DirectedFixture<Int>, isShared: Bool) {
        for v in fixture.vertexSet {
            var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
            let copy: AdjacencyList<Int>? = isShared ? graph : nil

            let removed = graph.remove(v)

            #expect(removed == v)
            #expect(!graph.contains(v))
            #expect(graph.vertexCount == fixture.vertexCount - 1)
            #expect(Set(graph.vertices) == fixture.vertexSet.subtracting([v]))
            #expect(Set(graph.edges) == fixture.edgeSet.filter { $0.source != v && $0.target != v })
            #expect(graph.edgeCount == graph.edges.count)
            for u in graph.vertices {
                #expect(!graph.successors(of: u).contains(v), "successors(of: \(u)) still lists removed vertex \(v)")
                #expect(!graph.predecessors(of: u).contains(v), "predecessors(of: \(u)) still lists removed vertex \(v)")
                #expect(Set(graph.successors(of: u)) == Set(graph.edges.filter { $0.source == u }.map(\.target)))
                #expect(Set(graph.predecessors(of: u)) == Set(graph.edges.filter { $0.target == u }.map(\.source)))
            }
            if let copy {
                #expect(Set(copy.vertices) == fixture.vertexSet)
                #expect(Set(copy.edges) == fixture.edgeSet)
            }
        }
    }

    @Test("V-06 removing a vertex with a self-loop", .tags(.selfLoops))
    func removeVertexWithSelfLoop() {
        var single = AdjacencyList(edges: [DirectedEdge(from: 0, to: 0)])
        #expect(single.remove(0) == 0)
        #expect(single.vertexCount == 0)
        #expect(single.edgeCount == 0)

        // NetworkX test_function graph. Vertex 1 has a self-loop, an edge to 0, an edge from 0, and an
        // edge to 2.
        var graph = AdjacencyList(adjacency: [0: [1, 2, 3], 1: [1, 2, 0], 4: []])
        graph.remove(1)
        #expect(graph.vertexCount == 4)
        #expect(Set(graph.edges) == [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3)])
        #expect(graph.edgeCount == 2)
        #expect(graph.predecessors(of: 0).isEmpty)
        #expect(Array(graph.predecessors(of: 2)) == [0])
        #expect(Set(graph.successors(of: 0)) == [2, 3])
    }

    @Test("V-07 no dangling reference after removing an edge's target")
    func noDanglingReference() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 1, to: 2)])
        graph.remove(2)
        #expect(graph.successors(of: 1).isEmpty)
        #expect(graph.outDegree(of: 1) == 0)
        #expect(graph.edges.isEmpty)
        #expect(graph.edgeCount == 0)
        #expect(!graph.contains(DirectedEdge(from: 1, to: 2)))
    }

    @Test("V-09 removing an absent vertex returns nil and changes nothing", arguments: [false, true])
    func removeAbsent(isShared: Bool) {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 6, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 6)])
        let copy: AdjacencyList<Int>? = isShared ? graph : nil

        #expect(graph.remove(-1) == nil)

        #expect(graph == AdjacencyList(edges: [DirectedEdge(from: 6, to: 0), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 3, to: 6)]))
        if let copy {
            #expect(copy == graph)
        }
        var empty = AdjacencyList<Int>()
        #expect(empty.remove(0) == nil)
        #expect(empty.vertexCount == 0)
    }

    @Test("V-09 removing twice: the second removal returns nil")
    func removeTwice() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(graph.remove(1) == 1)
        #expect(graph.remove(1) == nil)
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 0)
    }

    @Test("V-09 remove returns the stored instance, not the argument")
    func removeReturnsStoredInstance() {
        let stored = HashableBox(1, label: "stored")
        var graph = AdjacencyList(vertices: [stored])
        let removed = graph.remove(HashableBox(1, label: "probe"))
        #expect(removed === stored)
    }

    @Test("V-10 a removed and re-inserted vertex comes back isolated")
    func reinsertAfterRemoval() {
        var graph = AdjacencyList(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 0),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1),
        ])
        graph.remove(0)
        graph.insert(0)
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 2)
        #expect(graph.degree(of: 0) == 0)
        #expect(!graph.contains(DirectedEdge(from: 0, to: 1)))
        #expect(!graph.contains(DirectedEdge(from: 1, to: 0)))
        #expect(!graph.predecessors(of: 1).contains(0))
        #expect(!graph.successors(of: 2).contains(0))
    }

    @Test("V-14 removing every vertex, in a random order, empties the graph", .tags(.randomized), arguments: 0 ..< 10 as Range<UInt64>)
    func removeAllVerticesOneByOne(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        for fixture in DirectedFixture<Int>.all {
            var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
            var remaining = fixture.edgeSet
            // Sorted first: a Set's order differs between instances, which would make the seed
            // useless for reproducing a failure.
            for (i, v) in fixture.vertexSet.sorted().shuffled(using: &rng).enumerated() {
                graph.remove(v)
                remaining = remaining.filter { $0.source != v && $0.target != v }
                #expect(graph.vertexCount == fixture.vertexCount - i - 1, "\(fixture.name)")
                #expect(Set(graph.edges) == remaining, "\(fixture.name)")
                #expect(graph.edgeCount == remaining.count, "\(fixture.name)")
                for u in graph.vertices {
                    #expect(Set(graph.successors(of: u)) == Set(remaining.filter { $0.source == u }.map(\.target)), "\(fixture.name)")
                    #expect(Set(graph.predecessors(of: u)) == Set(remaining.filter { $0.target == u }.map(\.source)), "\(fixture.name)")
                }
            }
            #expect(graph == AdjacencyList(), "\(fixture.name)")
        }
    }

    // MARK: Clearing

    @Test("V-13 removeAllEdges keeps every vertex and leaves each one isolated", .tags(.fixture), arguments: DirectedFixture<Int>.all, [false, true])
    func removeAllEdges(_ fixture: DirectedFixture<Int>, keepingCapacity: Bool) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        graph.removeAllEdges(keepingCapacity: keepingCapacity)
        #expect(Set(graph.vertices) == fixture.vertexSet)
        #expect(graph.vertexCount == fixture.vertexCount)
        #expect(graph.edgeCount == 0)
        #expect(graph.edges.isEmpty)
        for v in graph.vertices {
            #expect(graph.degree(of: v) == 0)
            #expect(graph.successors(of: v).isEmpty)
            #expect(graph.predecessors(of: v).isEmpty)
        }
        #expect(graph == AdjacencyList(vertices: fixture.vertexSet))
    }

    @Test("V-13 removeAll leaves the empty graph, still usable", .tags(.fixture), arguments: DirectedFixture<Int>.all, [false, true])
    func removeAll(_ fixture: DirectedFixture<Int>, keepingCapacity: Bool) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        graph.removeAll(keepingCapacity: keepingCapacity)
        #expect(graph == AdjacencyList())
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
        #expect(graph.vertices.isEmpty)
        #expect(graph.edges.isEmpty)
        graph.insert(DirectedEdge(from: 1, to: 2))
        #expect(graph.edgeCount == 1)
        #expect(graph.vertexCount == 2)
    }

    // MARK: Mutating while iterating

    @Test("V-15 removing every vertex while iterating over `vertices`", .tags(.copyOnWrite), arguments: DirectedFixture<Int>.all)
    func removeWhileIterating(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        // `graph.vertices` is evaluated once, before the self-loop; it must be unaffected by the
        // mutations that follow, and every vertex must be visited exactly once.
        var visited: [Int] = []
        for v in graph.vertices {
            visited.append(v)
            #expect(graph.remove(v) == v)
        }
        #expect(visited.count == fixture.vertexCount)
        #expect(Set(visited) == fixture.vertexSet)
        #expect(graph == AdjacencyList())
    }

    @Test("V-15 removing every vertex's out-neighbors while iterating over them", .tags(.copyOnWrite), arguments: DirectedFixture<Int>.nonempty)
    func removeNeighborsWhileIterating(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for v in fixture.vertexSet.sorted() where graph.contains(v) {
            for w in graph.successors(of: v) where w != v {
                graph.remove(w)
            }
        }
        // What is left has no edge between distinct vertices.
        #expect(graph.edges.allSatisfy { $0.isSelfLoop })
        #expect(graph.edgeCount == graph.edges.count)
        for v in graph.vertices {
            #expect(graph.successors(of: v).allSatisfy { $0 == v })
        }
    }
}
