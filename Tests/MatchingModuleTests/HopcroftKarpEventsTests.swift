// The Hopcroft–Karp algorithm as an event sequence (`hopcroftKarpEvents`): a hand-traced graph
// against Tests/Catalogs/MatchingModule/cases_events.py on `BipartiteGraph` and on a `Graph` with
// its bipartition, the trivial cases, value semantics, the preconditions, and a property test
// replaying the augmenting paths against `maximumBipartiteMatching`. Case IDs (MA-11nn) are listed
// in README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import PropertyBased
import Testing

@Suite("Hopcroft–Karp events")
struct HopcroftKarpEventsTests {
    @Test("MA-1100 two phases, the second's path through both matched edges: every event in order", .tags(.fixture))
    func handTraced() throws {
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (1, 3), (2, 4), (2, 5)]
        // Tests/Catalogs/MatchingModule/cases_events.out, MA-1100.
        let expected: [HopcroftKarpEvent<Int>] = [
            .phase(length: 1), .augmentingPath([0]), .augmentingPath([3]),
            .phase(length: 5), .augmentingPath([2, 0, 1, 3, 4]),
        ]
        let bipartite = try #require(BipartiteGraph(left: [0, 1, 2], right: [3, 4, 5], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(bipartite.hopcroftKarpEvents()) == expected)
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let bipartition = try #require(graph.bipartition(left: [0, 1, 2]))
        #expect(Array(graph.hopcroftKarpEvents(bipartition: bipartition)) == expected)
        #expect(Set(graph.maximumBipartiteMatching(bipartition: bipartition).edges) == [2, 1, 4])
        #expect(expected[0].description == "phase(1)" && expected[4].description == "augmentingPath([2, 0, 1, 3, 4])")
    }

    @Test("MA-1101 no edges or no vertices: no events; value semantics: each iterator starts over; stopping early; String vertices")
    func trivialAndValueSemantics() throws {
        let empty = try #require(BipartiteGraph<Int>(left: [], right: []))
        #expect(Array(empty.hopcroftKarpEvents()).isEmpty)
        let apart = try #require(BipartiteGraph<Int>(left: [0, 1], right: [2]))
        #expect(Array(apart.hopcroftKarpEvents()).isEmpty)
        let named = try #require(BipartiteGraph(left: ["a", "b"], right: ["x"], edges: [UndirectedEdge("a", "x"), UndirectedEdge("b", "x")]))
        let events = named.hopcroftKarpEvents()
        let first = Array(events)
        #expect(first == [.phase(length: 1), .augmentingPath([0])])
        #expect(Array(events) == first)
        #expect(Array(events.prefix(1)) == [.phase(length: 1)])
        var iterator = events.makeIterator()
        for _ in first { _ = iterator.next() }
        #expect(iterator.next() == nil)
        #expect(iterator.next() == nil)
    }

    @Test("MA-1102 a bipartition of another graph, or an edge inside one side, traps")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            let other = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
            _ = graph.hopcroftKarpEvents(bipartition: other.bipartition()!)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            let sides = graph.bipartition()!
            var wider = graph
            _ = wider.insert(edge: UndirectedEdge(0, 2))
            _ = wider.hopcroftKarpEvents(bipartition: sides)
        }
    }

    @Test("MA-1103 property: augmenting paths alternate from a free left vertex to a free right one at the phase's length, are disjoint within a phase, and add up to maximumBipartiteMatching", .tags(.randomized))
    func property() async {
        // Up to 30 edges between left 0..<6 and right 6..<12; repeats allowed.
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 6 ... 11)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges) { raw in
            let graph = ReferencePseudograph(vertices: 0 ..< 12, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            guard let bipartition = graph.bipartition(left: 0 ..< 6) else {
                Issue.record("not bipartite")
                return
            }
            var matched = Set<Int>()
            var mate = [Int?](repeating: nil, count: 12)
            var length = 0
            var usedInPhase = Set<Int>()
            var lengths: [Int] = []
            for event in graph.hopcroftKarpEvents(bipartition: bipartition) {
                switch event {
                case .phase(let k):
                    #expect(k > length && k % 2 == 1)
                    length = k
                    lengths.append(k)
                    usedInPhase = []
                case .augmentingPath(let path):
                    #expect(path.count == length)
                    var at = raw[path[0]].0
                    #expect(mate[at] == nil)
                    var visited = [at]
                    for (i, e) in path.enumerated() {
                        #expect(matched.contains(e) == (i % 2 == 1))
                        let (u, v) = raw[e]
                        #expect(u == at || v == at)
                        at = u == at ? v : u
                        visited.append(at)
                    }
                    #expect(mate[at] == nil && at >= 6)
                    #expect(usedInPhase.isDisjoint(with: visited))
                    usedInPhase.formUnion(visited)
                    for e in path where !matched.insert(e).inserted { matched.remove(e) }
                    for e in path where matched.contains(e) {
                        mate[raw[e].0] = raw[e].1
                        mate[raw[e].1] = raw[e].0
                    }
                }
            }
            let plain = graph.maximumBipartiteMatching(bipartition: bipartition)
            #expect(matched == Set(plain.edges))
            #expect(Double(lengths.count) <= 2 * Double(12).squareRoot() + 2)
        }
    }
}
