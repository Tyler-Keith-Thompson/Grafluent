// The position of the edge between two endpoints: `edges(from:to:)` on `AdjacencyList` and
// `edges(between:and:)` on `UndirectedAdjacencyList` (catalog Q-25). Each answer is checked
// against a scan of `edges`.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

@Suite("AdjacencyList edges(from:to:)")
struct AdjacencyListEdgesConnectingTests {
    @Test("Q-25 edges(from:to:) is the edge's position, and respects direction")
    func positionOfEdge() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 3)])
        let forward = graph.edges(from: 1, to: 2)
        #expect(forward.count == 1)
        #expect(!forward.isEmpty)
        #expect(forward.startIndex == 0)
        #expect(forward.endIndex == 1)
        #expect(graph.edges[forward[0]] == DirectedEdge(from: 1, to: 2))
        #expect(forward.first == graph.edges.firstIndex(of: DirectedEdge(from: 1, to: 2)))
        #expect(Array(graph.edges(from: 2, to: 3)) == [graph.edges.firstIndex(of: DirectedEdge(from: 2, to: 3))!])
        #expect(Array(graph.edges(from: 3, to: 3)) == [graph.edges.firstIndex(of: DirectedEdge(from: 3, to: 3))!])
        let backward = graph.edges(from: 2, to: 1)
        #expect(backward.isEmpty)
        #expect(backward.count == 0)
        #expect(backward.startIndex == backward.endIndex)
        #expect(Array(backward) == [])
        #expect(graph.edges(from: 1, to: 3).isEmpty)
        #expect(graph.edges(from: 1, to: 1).isEmpty)
    }

    @Test("Q-25 edges(from:to:) with an absent endpoint is empty and never traps")
    func absentEndpoint() {
        let graph = AdjacencyList(edges: [DirectedEdge(from: 5, to: 3), DirectedEdge(from: 1, to: 0)])
        #expect(graph.edges(from: 0, to: -1).isEmpty)
        #expect(graph.edges(from: -1, to: 0).isEmpty)
        #expect(graph.edges(from: -1, to: -1).isEmpty)
        #expect(AdjacencyList<Int>().edges(from: 0, to: 0).isEmpty)
        let named = AdjacencyList(edges: [DirectedEdge(from: "a", to: "b")])
        #expect(named.edges(from: "a", to: "z").isEmpty)
        #expect(named.edges(from: "z", to: "b").isEmpty)
        #expect(named.edges(from: "a", to: "b").count == 1)
        let loop = AdjacencyList(edges: [DirectedEdge(from: "a", to: "a")])
        #expect(loop.edges(from: "a", to: "z").isEmpty)
        #expect(loop.edges(from: "z", to: "a").isEmpty)
        #expect(loop.edges(from: "a", to: "a").count == 1)
    }

    @Test("Q-25 edges(from:to:) follows the edge that a removal moves")
    func followsMovedEdge() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        #expect(Array(graph.edges(from: 2, to: 0)) == [2])
        graph.remove(edge: DirectedEdge(from: 0, to: 1))
        // The last edge moved into the hole at position 0.
        #expect(Array(graph.edges(from: 2, to: 0)) == [0])
        #expect(graph.edges[0] == DirectedEdge(from: 2, to: 0))
        #expect(graph.edges(from: 0, to: 1).isEmpty)
        #expect(Array(graph.edges(from: 1, to: 2)) == [1])
        graph.remove(1)
        #expect(graph.edges(from: 1, to: 2).isEmpty)
        #expect(Array(graph.edges(from: 2, to: 0)) == [0])
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(Array(graph.edges(from: 0, to: 1)) == [1])
    }

    @Test("Q-25 edges(from:to:) on a bulk-built graph, before and after its first mutation")
    func bulkBuilt() {
        let sorted = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 3, to: 0)]
        var graph = AdjacencyList<Int>(_vertexCount: 4, sortedEdges: sorted, _ConstructionToken())
        let copy = graph
        for source in 0 ..< 4 {
            for target in 0 ..< 4 {
                let expected = graph.edges.indices.filter { graph.edges[$0] == DirectedEdge(from: source, to: target) }
                #expect(Array(graph.edges(from: source, to: target)) == expected, "\(source) → \(target)")
            }
        }
        graph.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(graph.edges(from: 0, to: 1).isEmpty)
        #expect(Array(graph.edges(from: 3, to: 0)) == [0])
        #expect(Array(copy.edges(from: 0, to: 1)) == [0])
        #expect(Array(copy.edges(from: 3, to: 0)) == [3])
    }

    @Test("Q-25 edges(from:to:) agrees with a scan on every fixture", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func fixtures(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        var found = 0
        for source in fixture.vertexSet {
            for target in fixture.vertexSet {
                var expected: [Int] = []
                for p in graph.edges.indices where graph.edges[p] == DirectedEdge(from: source, to: target) { expected.append(p) }
                let positions = graph.edges(from: source, to: target)
                #expect(Array(positions) == expected, "\(source) → \(target)")
                #expect(positions.count == (graph.contains(edge: DirectedEdge(from: source, to: target)) ? 1 : 0))
                found += positions.count
            }
        }
        #expect(found == graph.edgeCount)
    }

    @Test("Q-25 edges(from:to:) agrees with a scan through random mutations", .tags(.randomized))
    func randomMutations() async {
        // (operation, a, b): a and b name vertices 0...5.
        let operations = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = AdjacencyList<Int>()
            for (operation, a, b) in operations {
                switch operation {
                case 0, 1: graph.insert(edge: DirectedEdge(from: a, to: b))
                case 2: graph.remove(edge: DirectedEdge(from: a, to: b))
                default: graph.remove(a)
                }
                for source in 0 ... 5 {
                    for target in 0 ... 5 {
                        var expected: [Int] = []
                        for p in graph.edges.indices where graph.edges[p] == DirectedEdge(from: source, to: target) { expected.append(p) }
                        #expect(Array(graph.edges(from: source, to: target)) == expected, "\(source) → \(target)")
                    }
                }
            }
        }
    }

    @Test("Q-25 the result is a value, unaffected by later changes to the graph")
    func valueSemantics() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let positions = graph.edges(from: 1, to: 2)
        graph.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(Array(positions) == [1])
        #expect(Array(graph.edges(from: 1, to: 2)) == [0])
    }

    @Test("Q-25 subscripting past the edge traps")
    func subscriptTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges(from: 0, to: 1)[1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.edges(from: 1, to: 0)[0]
        }
    }
}

@Suite("UndirectedAdjacencyList edges(between:and:)")
struct UndirectedAdjacencyListEdgesConnectingTests {
    @Test("Q-25 edges(between:and:) is the edge's position in either orientation")
    func positionOfEdge() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(1, 2), UndirectedEdge(3, 2), UndirectedEdge(3, 3)])
        let p = graph.edges.firstIndex(of: UndirectedEdge(1, 2))!
        #expect(Array(graph.edges(between: 1, and: 2)) == [p])
        #expect(Array(graph.edges(between: 2, and: 1)) == [p])
        let q = graph.edges.firstIndex(of: UndirectedEdge(2, 3))!
        #expect(Array(graph.edges(between: 2, and: 3)) == [q])
        #expect(Array(graph.edges(between: 3, and: 2)) == [q])
        // A self-loop once, though it is twice in its vertex's incident edges.
        let loop = graph.edges(between: 3, and: 3)
        #expect(loop.count == 1)
        #expect(graph.edges[loop[0]] == UndirectedEdge(3, 3))
        #expect(graph.edges(between: 1, and: 3).isEmpty)
        #expect(graph.edges(between: 1, and: 1).isEmpty)
        #expect(graph.edges(between: 1, and: 1).startIndex == graph.edges(between: 1, and: 1).endIndex)
    }

    @Test("Q-25 edges(between:and:) with an absent endpoint is empty and never traps")
    func absentEndpoint() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        #expect(graph.edges(between: 0, and: -1).isEmpty)
        #expect(graph.edges(between: -1, and: 0).isEmpty)
        #expect(graph.edges(between: 7, and: 7).isEmpty)
        #expect(UndirectedAdjacencyList<Int>().edges(between: 0, and: 0).isEmpty)
        let named = UndirectedAdjacencyList(edges: [UndirectedEdge("a", "b")])
        #expect(named.edges(between: "b", and: "z").isEmpty)
        #expect(named.edges(between: "b", and: "a").count == 1)
        let loop = UndirectedAdjacencyList(edges: [UndirectedEdge("a", "a")])
        #expect(loop.edges(between: "a", and: "z").isEmpty)
        #expect(loop.edges(between: "z", and: "a").isEmpty)
        #expect(loop.edges(between: "a", and: "a").count == 1)
    }

    @Test("Q-25 edges(between:and:) follows the edge that a removal moves")
    func followsMovedEdge() {
        var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(Array(graph.edges(between: 0, and: 2)) == [2])
        graph.remove(edge: UndirectedEdge(1, 0))
        #expect(Array(graph.edges(between: 0, and: 2)) == [0])
        #expect(graph.edges(between: 0, and: 1).isEmpty)
        #expect(Array(graph.edges(between: 2, and: 1)) == [1])
        graph.remove(2)
        #expect(graph.edges(between: 0, and: 2).isEmpty)
        #expect(graph.edgeCount == 0)
    }

    @Test("Q-25 edges(between:and:) on a bulk-built graph")
    func bulkBuilt() {
        let sorted = [UndirectedEdge(0, 1), UndirectedEdge(0, 3), UndirectedEdge(1, 2)]
        let graph = UndirectedAdjacencyList<Int>(_vertexCount: 4, sortedEdges: sorted, _ConstructionToken())
        for u in 0 ..< 4 {
            for v in 0 ..< 4 {
                var expected: [Int] = []
                for p in graph.edges.indices where graph.edges[p] == UndirectedEdge(u, v) { expected.append(p) }
                #expect(Array(graph.edges(between: u, and: v)) == expected, "\(u) – \(v)")
            }
        }
    }

    @Test("Q-25 edges(between:and:) agrees with a scan on every fixture", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func fixtures(_ fixture: UndirectedFixture<Int>) {
        let graph = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        var found = 0
        for u in graph.vertices {
            for v in graph.vertices {
                var expected: [Int] = []
                for p in graph.edges.indices where graph.edges[p] == UndirectedEdge(u, v) { expected.append(p) }
                let positions = graph.edges(between: u, and: v)
                #expect(Array(positions) == expected, "\(u) – \(v)")
                if u <= v { found += positions.count }
            }
        }
        #expect(found == graph.edgeCount)
    }

    @Test("Q-25 edges(between:and:) agrees with a scan through random mutations", .tags(.randomized))
    func randomMutations() async {
        // (operation, a, b): a and b name vertices 0...5.
        let operations = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = UndirectedAdjacencyList<Int>()
            for (operation, a, b) in operations {
                switch operation {
                case 0, 1: graph.insert(edge: UndirectedEdge(a, b))
                case 2: graph.remove(edge: UndirectedEdge(a, b))
                default: graph.remove(a)
                }
                for u in 0 ... 5 {
                    for v in 0 ... 5 {
                        var expected: [Int] = []
                        for p in graph.edges.indices where graph.edges[p] == UndirectedEdge(u, v) { expected.append(p) }
                        #expect(Array(graph.edges(between: u, and: v)) == expected, "\(u) – \(v)")
                    }
                }
            }
        }
    }

    @Test("Q-25 subscripting past the edge traps")
    func subscriptTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.edges(between: 1, and: 0)[1]
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.edges(between: 0, and: 0)[0]
        }
    }
}
