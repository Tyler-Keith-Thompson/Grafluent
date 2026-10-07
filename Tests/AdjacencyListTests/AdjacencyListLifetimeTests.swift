// Object lifetimes. Vertices are `LifetimeTracked` instances; each test fails if any instance
// outlives it (`.lifetimeChecked`). Within a test, the live-instance count shows whether the graph
// releases what it no longer holds: removing a vertex must release it immediately, not when the
// graph is destroyed.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList object lifetimes", .lifetimeChecked, .tags(.lifetime))
struct AdjacencyListLifetimeTests {
    @Test("K-11 a graph releases every vertex when it is destroyed", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func destroyReleasesEverything(_ fixture: DirectedFixture<Int>) {
        do {
            // One object per vertex, shared by every edge that names it.
            let objects = Dictionary(uniqueKeysWithValues: fixture.vertexSet.map { ($0, LifetimeTracked($0)) })
            let graph = AdjacencyList(
                vertices: fixture.vertices.map { objects[$0]! },
                edges: fixture.edges.map { DirectedEdge(from: objects[$0.source]!, to: objects[$0.target]!) }
            )
            #expect(LifetimeTracker.current!.instances == fixture.vertexCount)
            withExtendedLifetime((graph, objects)) {}
        }
        #expect(LifetimeTracker.current!.instances == 0)
    }

    @Test("V-04 removing a vertex releases it immediately", .tags(.fixture), arguments: DirectedFixture<Int>.nonempty)
    func removeVertexReleases(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList<LifetimeTracked<Int>>()
        do {
            let objects = Dictionary(uniqueKeysWithValues: fixture.vertexSet.map { ($0, LifetimeTracked($0)) })
            for v in fixture.vertices {
                graph.insert(objects[v]!)
            }
            for edge in fixture.edges {
                graph.insert(DirectedEdge(from: objects[edge.source]!, to: objects[edge.target]!))
            }
        }
        #expect(LifetimeTracker.current!.instances == fixture.vertexCount)
        for v in fixture.vertexSet.sorted() {
            graph.remove(LifetimeTracked(v))
            // The probe was released at the end of the statement above.
            #expect(LifetimeTracker.current!.instances == graph.vertexCount)
        }
        #expect(graph.vertexCount == 0)
        #expect(LifetimeTracker.current!.instances == 0)
    }

    @Test("V-06 / E-08 removing a vertex with a self-loop releases it exactly once", .tags(.selfLoops))
    func removeVertexWithSelfLoopReleases() {
        var graph = AdjacencyList<LifetimeTracked<Int>>()
        do {
            let v0 = LifetimeTracked(0), v1 = LifetimeTracked(1), v2 = LifetimeTracked(2)
            graph.insert(DirectedEdge(from: v1, to: v1))
            graph.insert(DirectedEdge(from: v1, to: v0))
            graph.insert(DirectedEdge(from: v0, to: v1))
            graph.insert(DirectedEdge(from: v1, to: v2))
        }
        #expect(LifetimeTracker.current!.instances == 3)
        graph.remove(LifetimeTracked(1))
        #expect(LifetimeTracker.current!.instances == 2)
        #expect(graph.edgeCount == 0)
        graph.remove(LifetimeTracked(0))
        #expect(LifetimeTracker.current!.instances == 1)
    }

    @Test("removing edges never releases a vertex")
    func removeEdgesKeepsVertices() {
        var graph = AdjacencyList<LifetimeTracked<Int>>()
        do {
            let objects = (0 ..< 10).map { LifetimeTracked($0) }
            for u in objects {
                for v in objects where v != u {
                    graph.insert(DirectedEdge(from: u, to: v))
                }
            }
        }
        for edge in graph.edges { graph.remove(edge) }
        #expect(LifetimeTracker.current!.instances == 10)
        #expect(graph.edgeCount == 0)
        #expect(graph.vertexCount == 10)
    }

    @Test("an equal vertex that was not inserted is released; the stored one is kept")
    func duplicateInsertReleasesArgument() {
        var graph = AdjacencyList<LifetimeTracked<Int>>()
        let first = LifetimeTracked(1)
        graph.insert(first)
        do {
            let duplicate = LifetimeTracked(1)
            let result = graph.insert(duplicate)
            #expect(result.memberAfterInsert === first)
        }
        #expect(LifetimeTracker.current!.instances == 1)
        graph.insert(DirectedEdge(from: LifetimeTracked(1), to: LifetimeTracked(1)))
        #expect(LifetimeTracker.current!.instances == 1, "edge endpoints equal to stored vertices must not be retained")
        #expect(graph.edgeCount == 1)
    }

    @Test("V-13 removeAll and removeAllEdges release exactly what they remove", arguments: [false, true])
    func clearingReleases(keepingCapacity: Bool) {
        var graph = AdjacencyList<LifetimeTracked<Int>>()
        do {
            let objects = (0 ..< 10).map { LifetimeTracked($0) }
            for i in 0 ..< 10 {
                graph.insert(DirectedEdge(from: objects[i], to: objects[(i + 1) % 10]))
            }
        }
        graph.removeAllEdges(keepingCapacity: keepingCapacity)
        #expect(LifetimeTracker.current!.instances == 10)
        graph.removeAll(keepingCapacity: keepingCapacity)
        #expect(LifetimeTracker.current!.instances == 0, "removeAll must release vertices even when it keeps capacity")
    }

    @Test("K-10 a copy shares vertex objects instead of duplicating them, and both release them")
    func copiesShareObjects() {
        var graph = AdjacencyList<LifetimeTracked<Int>>()
        do {
            let objects = (0 ..< 6).map { LifetimeTracked($0) }
            for i in 0 ..< 5 {
                graph.insert(DirectedEdge(from: objects[i + 1], to: objects[i]))
            }
        }
        let created = LifetimeTracker.current!.created
        var copy = graph
        copy.insert(DirectedEdge(from: copy.vertices.first!, to: copy.vertices.first!))
        #expect(LifetimeTracker.current!.created == created)
        graph.removeAll()
        #expect(LifetimeTracker.current!.instances == 6, "the copy still holds every vertex")
        copy.removeAll()
        #expect(LifetimeTracker.current!.instances == 0)
    }

    @Test("random mutations never leak", .tags(.randomized), arguments: 0 ..< 20 as Range<UInt64>)
    func randomMutations(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var graph = AdjacencyList<LifetimeTracked<Int>>()
        for step in 0 ..< 200 {
            let u = Int.random(in: 0 ..< 8, using: &rng)
            let v = Int.random(in: 0 ..< 8, using: &rng)
            switch Int.random(in: 0 ..< 5, using: &rng) {
            case 0: graph.insert(LifetimeTracked(u))
            case 1: graph.remove(LifetimeTracked(u))
            case 2, 3: graph.insert(DirectedEdge(from: LifetimeTracked(u), to: LifetimeTracked(v)))
            default: graph.remove(DirectedEdge(from: LifetimeTracked(u), to: LifetimeTracked(v)))
            }
            #expect(LifetimeTracker.current!.instances == graph.vertexCount, "step \(step)")
        }
    }
}
