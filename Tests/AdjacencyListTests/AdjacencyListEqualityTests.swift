// Equatable and Hashable. Equality means equal vertex sets and equal edge sets; it is not
// isomorphism, and it does not depend on insertion order. Case IDs (K-nn, D-14, FX-21) refer to
// the harvested test catalog.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("AdjacencyList equality and hashing", .tags(.conformance))
struct AdjacencyListEqualityTests {
    @Test("K-01 – K-07, D-14 equality and hashing follow the equivalence classes")
    func equivalenceClassLaws() {
        // Graphs grouped so that two graphs are equal exactly when they share a group. The base
        // graph is JGraphT's triangle with a reciprocal edge: 1→2, 2→1, 2→3, 3→1.
        let edges = [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 1)]

        var addedThenRemovedEdge = AdjacencyList(edges: edges)
        addedThenRemovedEdge.insert(edge: DirectedEdge(from: 3, to: 2))
        addedThenRemovedEdge.remove(edge: DirectedEdge(from: 3, to: 2))

        var addedThenRemovedVertex = AdjacencyList(edges: edges)
        addedThenRemovedVertex.insert(edge: DirectedEdge(from: 1, to: 9))
        addedThenRemovedVertex.remove(9)

        var clearedAndRebuilt = AdjacencyList(edges: (0 ..< 10).map { DirectedEdge(from: $0, to: ($0 + 1) % 10) })
        clearedAndRebuilt.removeAll()
        for edge in edges.reversed() { clearedAndRebuilt.insert(edge: edge) }

        var withIsolatedVertex = AdjacencyList(edges: edges)
        withIsolatedVertex.insert(4)

        var withSelfLoop = AdjacencyList(edges: edges)
        withSelfLoop.insert(edge: DirectedEdge(from: 2, to: 2))

        var missingEdge = AdjacencyList(edges: edges)
        missingEdge.remove(edge: DirectedEdge(from: 2, to: 3))

        var emptiedByRemoval = AdjacencyList(edges: edges)
        for v in [1, 2, 3] { emptiedByRemoval.remove(v) }

        var emptiedByRemoveAll = AdjacencyList(edges: edges)
        emptiedByRemoveAll.removeAll(keepingCapacity: true)

        var edgesRemoved = AdjacencyList(edges: edges)
        edgesRemoved.removeAllEdges()

        let classes: [[AdjacencyList<Int>]] = [
            [
                AdjacencyList(edges: edges),
                AdjacencyList(edges: edges.reversed()),
                AdjacencyList(edges: [edges[2], edges[0], edges[3], edges[1]]),
                AdjacencyList(adjacency: [1: [2], 2: [1, 3], 3: [1]]),
                [3: [1], 2: [3, 1], 1: [2]],
                AdjacencyList<Int> {
                    DirectedEdge(from: 3, to: 1)
                    DirectedEdge(from: 2, to: 3)
                    DirectedEdge(from: 2, to: 1)
                    DirectedEdge(from: 1, to: 2)
                },
                addedThenRemovedEdge,
                addedThenRemovedVertex,
                clearedAndRebuilt,
            ],
            [withIsolatedVertex, AdjacencyList(vertices: [4, 3, 2, 1], edges: edges)],
            [withSelfLoop],
            [missingEdge],
            // 2→3 replaced by 3→2.
            [AdjacencyList(edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 3, to: 1)])],
            [AdjacencyList(), emptiedByRemoval, emptiedByRemoveAll, AdjacencyList(vertices: []), AdjacencyList(edges: [])],
            [edgesRemoved, AdjacencyList(vertices: [1, 2, 3])],
            [AdjacencyList(vertices: [0])],
            [AdjacencyList(vertices: [1])],
            [AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])],
            [AdjacencyList(edges: [DirectedEdge(from: 1, to: 0)])],
        ]

        // Every pair: == holds exactly within a class, and is reflexive and symmetric; != is its
        // negation; equal graphs hash equally, including after a prefix has been hashed.
        let instances = classes.enumerated().flatMap { c, members in members.map { (c, $0) } }
        for (i, (ci, a)) in instances.enumerated() {
            #expect(a == a, "instance \(i) is not equal to itself")
            for (j, (cj, b)) in instances.enumerated() {
                #expect((a == b) == (ci == cj), "instances \(i) and \(j): == is \(a == b), expected \(ci == cj)")
                #expect((a == b) == (b == a), "== is not symmetric for \(i) and \(j)")
                #expect((a != b) == !(a == b))
                if ci == cj {
                    #expect(a.hashValue == b.hashValue, "equal instances \(i) and \(j) hash differently")
                    var ha = Hasher()
                    ha.combine(42)
                    ha.combine(a)
                    var hb = Hasher()
                    hb.combine(42)
                    hb.combine(b)
                    #expect(ha.finalize() == hb.finalize(), "equal instances \(i) and \(j) feed a hasher differently")
                }
            }
        }
    }

    @Test("K-09 a copy is equal and hashes equally", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func copyIsEqual(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        let copy = graph
        #expect(copy == graph)
        #expect(copy.hashValue == graph.hashValue)
    }

    @Test("distinct fixtures are unequal", .tags(.fixture))
    func distinctFixturesAreUnequal() {
        let graphs = DirectedFixture<Int>.all.map { AdjacencyList(vertices: $0.vertices, edges: $0.edges) }
        for (i, a) in graphs.enumerated() {
            for (j, b) in graphs.enumerated() where i != j {
                #expect(a != b, "\(DirectedFixture<Int>.all[i].name) == \(DirectedFixture<Int>.all[j].name)")
            }
        }
        #expect(Set(graphs).count == graphs.count)
    }

    @Test("equality is not isomorphism: relabeling a vertex gives an unequal graph")
    func notIsomorphism() {
        let a = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
        let b = AdjacencyList(edges: [DirectedEdge(from: 0, to: 2)])
        #expect(a != b)
    }

    @Test("D-14 equality respects direction")
    func direction() {
        let a = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
        let b = AdjacencyList(edges: [DirectedEdge(from: 1, to: 0)])
        #expect(a != b)
        #expect(a.vertexCount == b.vertexCount)
        #expect(a.edgeCount == b.edgeCount)
    }

    @Test("FX-21 every directed graph on 3 labeled vertices is distinct, and each is order-independent", .tags(.exhaustive))
    func allGraphsOnThreeVertices() {
        // 9 possible edges (self-loops included), so 2⁹ = 512 graphs; 2⁶ = 64 without self-loops.
        // petgraph tests/graph.rs enumerates the same space.
        let possibleEdges = (0 ..< 3).flatMap { u in (0 ..< 3).map { DirectedEdge(from: u, to: $0) } }
        var seen = Set<AdjacencyList<Int>>()
        var withoutSelfLoops = Set<AdjacencyList<Int>>()
        for mask in 0 ..< (1 << possibleEdges.count) {
            let subset = possibleEdges.indices.filter { mask & (1 << $0) != 0 }.map { possibleEdges[$0] }
            let forward = AdjacencyList(vertices: 0 ..< 3, edges: subset)
            let backward = AdjacencyList(vertices: (0 ..< 3).reversed(), edges: subset.reversed())
            #expect(forward == backward)
            #expect(forward.hashValue == backward.hashValue)
            #expect(forward.edgeCount == subset.count)
            #expect(forward.vertexCount == 3)
            seen.insert(forward)
            if !subset.contains(where: { $0.isSelfLoop }) { withoutSelfLoops.insert(forward) }
        }
        #expect(seen.count == 512)
        #expect(withoutSelfLoops.count == 64)
    }

    @Test("equality and hashing with every vertex in one hash bucket")
    func collidingVertices() {
        let petersen = DirectedFixture<Int>.petersen
        let a = AdjacencyList(edges: petersen.edges.map { DirectedEdge(from: Collider($0.source), to: Collider($0.target)) })
        let b = AdjacencyList(edges: petersen.edges.reversed().map { DirectedEdge(from: Collider($0.source), to: Collider($0.target)) })
        var c = a
        c.remove(edge: DirectedEdge(from: Collider(0), to: Collider(1)))
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        #expect(a != c)
        #expect(b != c)
    }
}
