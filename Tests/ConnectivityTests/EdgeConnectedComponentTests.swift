// k-edge-connected components (pairs joined by k edge-disjoint paths in the whole graph) and
// k-edge-connected subgraphs (maximal vertex sets whose induced subgraph is k-edge-connected).
// Parallel edges are separate paths; self-loops count for nothing. Hand-computed graphs, the
// representations, exits, and a property test against minimum cuts over every vertex subset.

import AdjacencyListModule
import AdjacencyMatrixModule
import Connectivity
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("k-edge-connected components and subgraphs")
struct EdgeConnectedComponentTests {
    @Test("Two K₄s joined by two edges: one class for k ≤ 2, the two K₄s for k = 3; for k = 4 the joined pairs, through the other K₄, but no subgraph")
    func twoCliques() {
        var pairs: [(Int, Int)] = []
        for base in [0, 4] { for u in 0 ..< 4 { for v in u + 1 ..< 4 { pairs.append((base + u, base + v)) } } }
        pairs += [(0, 4), (1, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.kEdgeConnectedComponents(1).map(Array.init) == [Array(0 ..< 8)])
        #expect(graph.kEdgeConnectedComponents(2).map(Array.init) == [Array(0 ..< 8)])
        #expect(graph.kEdgeConnectedComponents(3).map(Array.init) == [[0, 1, 2, 3], [4, 5, 6, 7]])
        // 0 and 1 have three paths inside their K₄ and a fourth through 4–5; so have 4 and 5.
        #expect(graph.kEdgeConnectedComponents(4).map(Array.init) == [[0, 1], [2], [3], [4, 5], [6], [7]])
        #expect(graph.kEdgeConnectedSubgraphs(4).map(Array.init) == (0 ..< 8).map { [$0] })
        #expect(graph.kEdgeConnectedSubgraphs(2).map(Array.init) == [Array(0 ..< 8)])
        #expect(graph.kEdgeConnectedSubgraphs(3).map(Array.init) == [[0, 1, 2, 3], [4, 5, 6, 7]])
        let components = graph.kEdgeConnectedComponents(3)
        #expect(components.component(of: 6) == 1)
    }

    @Test("K₂,₃: its two hubs are joined by three paths through the graph, but induce no edge, so they are a 3-edge-connected component and not a subgraph")
    func componentsAreNotSubgraphs() {
        let pairs = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.kEdgeConnectedComponents(3).map(Array.init) == [[0, 1], [2], [3], [4]])
        #expect(graph.kEdgeConnectedSubgraphs(3).map(Array.init) == [[0], [1], [2], [3], [4]])
        #expect(graph.kEdgeConnectedSubgraphs(2).map(Array.init) == [Array(0 ..< 5)])
    }

    @Test("K₄ with two more vertices on three of its corners: the fourth corner, of degree 3, is alone at k = 4")
    func refinedTwice() {
        // K₄ on 0…3; 4 and 5 each joined to 0, 1, 2 and each other.
        let pairs = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 0), (4, 1), (4, 2), (5, 0), (5, 1), (5, 2), (4, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.kEdgeConnectedComponents(4).map(Array.init) == [[0, 1, 2, 4, 5], [3]])
        #expect(graph.kEdgeConnectedSubgraphs(4).map(Array.init) == [[0, 1, 2, 4, 5], [3]])
        #expect(graph.kEdgeConnectedComponents(3).map(Array.init) == [Array(0 ..< 6)])
    }

    @Test("Two K₅s linked by four paths through vertices of degree 2: one 4-edge-connected component, but two subgraphs, since inside them the paths are gone")
    func pathsOutsideTheSubgraph() {
        var pairs: [(Int, Int)] = []
        for base in [0, 5] { for u in 0 ..< 5 { for v in u + 1 ..< 5 { pairs.append((base + u, base + v)) } } }
        for i in 0 ..< 4 { pairs += [(i, 10 + i), (10 + i, 5 + i)] }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 14, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.kEdgeConnectedComponents(4).map(Array.init) == [Array(0 ..< 10), [10], [11], [12], [13]])
        #expect(graph.kEdgeConnectedSubgraphs(4).map(Array.init) == [Array(0 ..< 5), Array(5 ..< 10), [10], [11], [12], [13]])
    }

    @Test("Flows that must cancel an earlier path's edge: the breadth-first paths in row order send a unit back along an edge already used")
    func cancellingFlows() {
        // Found by replaying the flows: without cancelling, 1 and 3 would part at k = 4.
        let first = [(0, 3), (6, 5), (1, 3), (6, 6), (2, 6), (4, 3), (7, 0), (1, 3), (4, 4), (5, 6), (3, 5), (4, 2), (1, 7), (5, 0), (1, 2)]
        let one = ReferencePseudograph(vertices: 0 ..< 8, edges: first.map { UndirectedEdge($0.0, $0.1) })
        #expect(one.kEdgeConnectedComponents(4).map(Array.init) == [[0], [1, 3], [2], [4], [5], [6], [7]])
        // A cancelled edge must carry nothing afterwards, not the reverse unit.
        let second = [(5, 0), (2, 5), (6, 0), (4, 3), (1, 2), (3, 2), (7, 6), (7, 7), (7, 2), (2, 3), (3, 0), (1, 0), (6, 5), (3, 4), (7, 6), (4, 2), (3, 2), (6, 7), (1, 0), (6, 5)]
        let two = ReferencePseudograph(vertices: 0 ..< 8, edges: second.map { UndirectedEdge($0.0, $0.1) })
        #expect(two.kEdgeConnectedComponents(4).map(Array.init) == [[0, 2, 3, 5, 6, 7], [1], [4]])
    }

    @Test("Parallel edges are separate paths and loops count for nothing")
    func parallelsAndLoops() {
        let pairs = [(0, 1), (0, 1), (0, 1), (0, 0), (1, 2), (1, 2), (2, 2), (2, 2), (2, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.kEdgeConnectedComponents(2).map(Array.init) == [[0, 1, 2], [3]])
        #expect(graph.kEdgeConnectedComponents(3).map(Array.init) == [[0, 1], [2], [3]])
        #expect(graph.kEdgeConnectedSubgraphs(3).map(Array.init) == [[0, 1], [2], [3]])
        #expect(graph.kEdgeConnectedComponents(4).map(Array.init) == [[0], [1], [2], [3]])
        #expect(graph.kEdgeConnectedSubgraphs(1).map(Array.init) == [[0, 1, 2], [3]])
    }

    @Test("The empty graph has no components; one vertex is one; String vertices listed in reverse")
    func degenerate() throws {
        let empty = ReferencePseudograph<Int>(edges: [])
        #expect(empty.kEdgeConnectedComponents(3).isEmpty)
        #expect(empty.kEdgeConnectedSubgraphs(3).isEmpty)
        let one = ReferencePseudograph(vertices: [7], edges: [UndirectedEdge(7, 7)])
        #expect(one.kEdgeConnectedComponents(5).map(Array.init) == [[7]])
        #expect(one.kEdgeConnectedSubgraphs(5).map(Array.init) == [[7]])
        let names = ["d", "c", "b", "a"]
        var pairs: [UndirectedEdge<String>] = []
        for u in 0 ..< 4 { for v in u + 1 ..< 4 { pairs.append(UndirectedEdge(names[u], names[v])) } }
        let named = UndirectedAdjacencyList(vertices: names + ["e"], edges: pairs + [UndirectedEdge("e", "a")])
        #expect(named.kEdgeConnectedComponents(3).map(Array.init) == [["d", "c", "b", "a"], ["e"]])
        #expect(try named.kEdgeConnectedSubgraphs(3).component(checked: "e") == 1)
    }

    @Test("Representations: AdjacencyList and AdjacencyMatrix through undirectedView, whose opposite arcs are parallel edges")
    func representations() {
        let arcs = [(0, 1), (1, 2), (2, 0), (1, 0), (2, 3)]
        let list = AdjacencyList(vertices: 0 ..< 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
        // 0–1 is doubled, so 0 and 1 have three paths: the two copies and 0–2–1.
        #expect(list.kEdgeConnectedComponents(3).map(Array.init) == [[0, 1], [2], [3]])
        // Inside {0, 1} the doubled edge is only two paths.
        #expect(list.kEdgeConnectedSubgraphs(3).map(Array.init) == [[0], [1], [2], [3]])
        #expect(list.kEdgeConnectedSubgraphs(2).map(Array.init) == [[0, 1, 2], [3]])
        let matrix = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirectedView
        #expect(matrix.kEdgeConnectedComponents(3).map(Array.init) == [[0, 1], [2], [3]])
        #expect(matrix.kEdgeConnectedSubgraphs(2).map(Array.init) == [[0, 1, 2], [3]])
    }

    @Test("Both trap on k < 1")
    func traps() async {
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).kEdgeConnectedComponents(0)
        }
        await #expect(processExitsWith: .failure) {
            _ = ReferencePseudograph(edges: [UndirectedEdge(0, 1)]).kEdgeConnectedSubgraphs(0)
        }
    }

    @Test("Components are the classes of pairs whose minimum cut has at least k edges; subgraphs the maximal sets whose induced graph has no smaller cut", .tags(.randomized))
    func againstCuts() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 24)
        await propertyCheck(count: 200, input: Gen.int(in: 1 ... 7), edges, Gen.int(in: 1 ... 5)) { n, raw, k in
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // The fewest edges of `within` crossing a cut that parts u from v inside the set `within`.
            func cut(_ u: Int, _ v: Int, within: Int) -> Int {
                var best = Int.max
                for side in 0 ..< 1 << n where side & ~within == 0 && side & (1 << u) != 0 && side & (1 << v) == 0 {
                    var crossing = 0
                    for (a, b) in pairs where a != b && within & (1 << a) != 0 && within & (1 << b) != 0 && (side & (1 << a) != 0) != (side & (1 << b) != 0) {
                        crossing += 1
                    }
                    best = min(best, crossing)
                }
                return best
            }
            let all = (1 << n) - 1
            var expected: [[Int]] = []
            var placed = Set<Int>()
            for u in 0 ..< n where !placed.contains(u) {
                let group = (0 ..< n).filter { $0 == u || cut(u, $0, within: all) >= k }
                placed.formUnion(group)
                expected.append(group)
            }
            #expect(graph.kEdgeConnectedComponents(k).map(Array.init) == expected, "\(pairs) k = \(k)")
            // Every k-edge-connected set, then the maximal ones.
            var connected: [Int] = []
            for set in 1 ... all {
                let members = (0 ..< n).filter { set & (1 << $0) != 0 }
                if members.allSatisfy({ a in members.allSatisfy { b in a >= b || cut(a, b, within: set) >= k } }) { connected.append(set) }
            }
            let maximal = connected.filter { set in !connected.contains { $0 != set && $0 & set == set } }
            let subgraphs = maximal.map { set in (0 ..< n).filter { set & (1 << $0) != 0 } }.sorted { $0[0] < $1[0] }
            #expect(graph.kEdgeConnectedSubgraphs(k).map(Array.init) == subgraphs, "\(pairs) k = \(k)")
        }
    }
}
