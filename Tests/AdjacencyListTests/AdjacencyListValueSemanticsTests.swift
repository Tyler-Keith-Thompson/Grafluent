// Value semantics (K-08). Every kind of mutation, applied while a copy exists, must leave the copy
// exactly as it was, and must give the same result as on a uniquely referenced value.
//
// Only behavior is tested, through the public API. Whether storage is actually shared, copied
// lazily, or reused in place is a performance property, measured by the benchmarks.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList value semantics", .tags(.copyOnWrite))
struct AdjacencyListValueSemanticsTests {
    @Test("K-08 inserting a vertex leaves a copy unchanged", arguments: DirectedFixture<Int>.nonempty)
    func insertVertex(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let copy = graph
        graph.insert(1_000)
        #expect(Set(copy.vertices) == fixture.vertexSet)
        #expect(Set(copy.edges) == fixture.edgeSet)
        #expect(!copy.contains(1_000))
        #expect(graph.contains(1_000))
        #expect(graph.vertexCount == copy.vertexCount + 1)
    }

    @Test("K-08 removing a vertex leaves a copy unchanged", arguments: DirectedFixture<Int>.nonempty)
    func removeVertex(_ fixture: DirectedFixture<Int>) {
        let v = fixture.vertexSet.min()!
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let copy = graph
        graph.remove(v)
        #expect(Set(copy.vertices) == fixture.vertexSet)
        #expect(Set(copy.edges) == fixture.edgeSet)
        #expect(copy.contains(v))
        #expect(Set(copy.successors(of: v)) == Set(fixture.edgeSet.filter { $0.source == v }.map(\.target)))
        #expect(Set(copy.predecessors(of: v)) == Set(fixture.edgeSet.filter { $0.target == v }.map(\.source)))
        #expect(!graph.contains(v))
    }

    @Test("K-08 inserting an edge leaves a copy unchanged", arguments: DirectedFixture<Int>.nonempty)
    func insertEdge(_ fixture: DirectedFixture<Int>) {
        let v = fixture.vertexSet.min()!
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let copy = graph
        graph.insert(DirectedEdge(from: v, to: 1_000))
        graph.insert(DirectedEdge(from: 1_000, to: 1_000))
        #expect(Set(copy.vertices) == fixture.vertexSet)
        #expect(Set(copy.edges) == fixture.edgeSet)
        #expect(Set(copy.successors(of: v)) == Set(fixture.edgeSet.filter { $0.source == v }.map(\.target)))
        #expect(graph.edgeCount == copy.edgeCount + 2)
    }

    @Test("K-08 removing an edge leaves a copy unchanged", arguments: DirectedFixture<Int>.nonempty)
    func removeEdge(_ fixture: DirectedFixture<Int>) {
        let edge = fixture.edgeSet.min { ($0.source, $0.target) < ($1.source, $1.target) }!
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let copy = graph
        graph.remove(edge)
        #expect(Set(copy.edges) == fixture.edgeSet)
        #expect(copy.contains(edge))
        #expect(copy.successors(of: edge.source).contains(edge.target))
        #expect(copy.predecessors(of: edge.target).contains(edge.source))
        #expect(!graph.contains(edge))
    }

    @Test("K-08 removeAllEdges leaves a copy unchanged", arguments: DirectedFixture<Int>.nonempty, [false, true])
    func removeAllEdges(_ fixture: DirectedFixture<Int>, keepingCapacity: Bool) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let copy = graph
        graph.removeAllEdges(keepingCapacity: keepingCapacity)
        #expect(Set(copy.vertices) == fixture.vertexSet)
        #expect(Set(copy.edges) == fixture.edgeSet)
        #expect(copy.edgeCount == fixture.edgeCount)
        for v in fixture.vertexSet {
            #expect(copy.outDegree(of: v) == fixture.outDegree[v])
        }
        #expect(graph.edgeCount == 0)
    }

    @Test("K-08 removeAll leaves a copy unchanged", arguments: DirectedFixture<Int>.nonempty, [false, true])
    func removeAll(_ fixture: DirectedFixture<Int>, keepingCapacity: Bool) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let copy = graph
        graph.removeAll(keepingCapacity: keepingCapacity)
        #expect(Set(copy.vertices) == fixture.vertexSet)
        #expect(Set(copy.edges) == fixture.edgeSet)
        #expect(graph.vertexCount == 0)
    }

    @Test("K-08 reserveCapacity leaves both values unchanged", arguments: DirectedFixture<Int>.nonempty)
    func reserveCapacity(_ fixture: DirectedFixture<Int>) {
        var graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let copy = graph
        graph.reserveCapacity(vertexCount: 1_000, edgeCount: 1_000)
        #expect(graph == copy)
        #expect(Set(copy.edges) == fixture.edgeSet)
        #expect(Set(graph.edges) == fixture.edgeSet)
    }

    @Test("K-08 mutating the copy never changes the original", arguments: DirectedFixture<Int>.nonempty)
    func mutatingCopyLeavesOriginal(_ fixture: DirectedFixture<Int>) {
        let original = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        var copy = original
        copy.insert(DirectedEdge(from: 1_000, to: 1_001))
        copy.remove(fixture.vertexSet.min()!)
        copy.removeAllEdges()
        #expect(Set(original.vertices) == fixture.vertexSet)
        #expect(Set(original.edges) == fixture.edgeSet)
        for v in fixture.vertexSet {
            #expect(original.outDegree(of: v) == fixture.outDegree[v])
            #expect(original.inDegree(of: v) == fixture.inDegree[v])
        }
    }

    @Test("K-12 swap exchanges values")
    func swapExchangesValues() {
        var a = AdjacencyList(edges: DirectedFixture<Int>.petersen.edges)
        var b = AdjacencyList(edges: DirectedFixture<Int>.cube.edges)
        swap(&a, &b)
        #expect(Set(a.edges) == DirectedFixture<Int>.cube.edgeSet)
        #expect(Set(b.edges) == DirectedFixture<Int>.petersen.edgeSet)
    }

    @Test("S-01 a long random sequence of mutations, each made while a copy may exist", .tags(.randomized), arguments: 0 ..< 25 as Range<UInt64>)
    func randomMutationsWithCopies(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var graph = AdjacencyList<Int>()
        for step in 0 ..< 200 {
            let u = Int.random(in: 0 ..< 10, using: &rng)
            let v = Int.random(in: 0 ..< 10, using: &rng)
            let copy: AdjacencyList<Int>? = Bool.random(using: &rng) ? graph : nil
            let vertices = Set(graph.vertices)
            let edges = Set(graph.edges)

            switch Int.random(in: 0 ..< 6, using: &rng) {
            case 0: graph.insert(u)
            case 1: graph.remove(u)
            case 2, 3: graph.insert(DirectedEdge(from: u, to: v))
            case 4: graph.remove(DirectedEdge(from: u, to: v))
            default: graph.removeAllEdges(keepingCapacity: Bool.random(using: &rng))
            }

            if let copy {
                #expect(Set(copy.vertices) == vertices, "step \(step)")
                #expect(Set(copy.edges) == edges, "step \(step)")
                for w in vertices {
                    #expect(Set(copy.successors(of: w)) == Set(edges.filter { $0.source == w }.map(\.target)), "step \(step)")
                    #expect(Set(copy.predecessors(of: w)) == Set(edges.filter { $0.target == w }.map(\.source)), "step \(step)")
                }
            }
        }
    }
}
