// allTopologicalSorts(): every topological order, lazily, in lexicographic order of the vertices'
// positions in `vertices`. Hand-computed cases, cycles and self-loops, parallel edges, and a
// property test against every permutation filtered, on every representation. Case IDs (TR-nn)
// refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import StableGraphs
import Testing
import Traversal

/// A directed multigraph without vertex indices.
private struct UnindexedDigraph: DirectedGraph {
    let base: ReferenceDirectedMultigraph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [DirectedEdge<Int>] { base.edges }
    func successors(of vertex: Int) -> [Int] { base.successors(of: vertex) }
    func outEdges(of vertex: Int) -> [Int] { base.outEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

@Suite("All topological sorts")
struct AllTopologicalSortsTests {
    @Test("TR-260 hand-computed orders, in lexicographic order of vertex positions")
    func handComputed() {
        // NetworkX 3.7 all_topological_sorts(DiGraph([(0, 1), (0, 2)])) gives the same two.
        let fork = CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2)])
        #expect(Array(fork.allTopologicalSorts()) == [[0, 1, 2], [0, 2, 1]])
        let diamond = AdjacencyList(vertices: 0 ..< 4, edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3),
        ])
        #expect(Array(diamond.allTopologicalSorts()) == [[0, 1, 2, 3], [0, 2, 1, 3]])
        let chain = AdjacencyMatrix(vertexCount: 4, edges: [DirectedEdge(from: 3, to: 2), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(Array(chain.allTopologicalSorts()) == [[3, 2, 1, 0]])
        // Positions, not values: vertices listed as 5, 1, 3.
        let listed = AdjacencyList(vertices: [5, 1, 3], edges: [DirectedEdge(from: 1, to: 3)])
        #expect(Array(listed.allTopologicalSorts()) == [[5, 1, 3], [1, 5, 3], [1, 3, 5]])
    }

    @Test("TR-261 the empty graph has one order, the empty one; isolated vertices have every permutation")
    func emptyAndIsolated() {
        #expect(Array(AdjacencyList<Int>().allTopologicalSorts()) == [[]])
        let isolated = CompressedSparseRow(vertexCount: 3, edges: [])
        #expect(Array(isolated.allTopologicalSorts()) == [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]])
        #expect(CompressedSparseRow(vertexCount: 7, edges: []).allTopologicalSorts().reduce(0) { n, _ in n + 1 } == 5040)
    }

    @Test("TR-262 a cycle or a self-loop leaves no order; parallel edges change nothing")
    func cyclesAndMultigraphs() {
        let cycle = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 4)])
        #expect(Array(cycle.allTopologicalSorts()).isEmpty)
        let loop = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        #expect(Array(loop.allTopologicalSorts()).isEmpty)
        let parallel = DirectedPseudograph(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
        #expect(Array(parallel.allTopologicalSorts()) == [[0, 2, 1], [2, 0, 1]])
    }

    @Test("TR-263 more than 64 vertices: the ready set spans several words")
    func wide() {
        // 70 vertices: 0 before everything, then 69 before 68; the rest free. The first three orders.
        var edges = (1 ..< 70).map { DirectedEdge(from: 0, to: $0) }
        edges.append(DirectedEdge(from: 69, to: 68))
        let graph = CompressedSparseRow(vertexCount: 70, edges: edges)
        var iterator = graph.allTopologicalSorts().makeIterator()
        let first = iterator.next()!
        #expect(first == [0] + Array(1 ..< 68) + [69, 68])
        let second = iterator.next()!
        #expect(second == [0] + Array(1 ..< 67) + [69, 67, 68])
        #expect(iterator.next()! == [0] + Array(1 ..< 67) + [69, 68, 67])
    }

    @Test("TR-264 every order is a filtered permutation, in lexicographic order, on every representation")
    func againstPermutations() async {
        // Up to 9 edges on 0..<6; mostly forward pairs (acyclic), sometimes any pair.
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 9)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 3)) { raw, mode in
            let edges = raw.map { mode == 0 ? DirectedEdge(from: $0.0, to: $0.1) : DirectedEdge(from: min($0.0, $0.1), to: max($0.0, $0.1)) }
                .filter { mode == 0 || !$0.isSelfLoop }
            func check<G: DirectedGraph<Int>>(_ g: G, _ name: String) {
                let listed = Array(g.vertices)
                var expected: [[Int]] = []
                var order: [Int] = []
                func extend() {
                    if order.count == listed.count {
                        expected.append(order)
                        return
                    }
                    for v in listed where !order.contains(v) {
                        // Every edge into it from a placed vertex.
                        if g.edges.contains(where: { $0.target == v && !order.contains($0.source) }) { continue }
                        order.append(v)
                        extend()
                        order.removeLast()
                    }
                }
                extend()
                #expect(Array(g.allTopologicalSorts()) == expected, "\(name)")
            }
            let reference = ReferenceDirectedMultigraph(vertices: [3, 0, 5, 1, 4, 2], edges: edges)
            check(reference, "ReferenceDirectedMultigraph, vertices out of order")
            check(UnindexedDigraph(base: reference), "without vertex indices")
            check(DirectedPseudograph(vertices: 0 ..< 6, edges: edges), "DirectedPseudograph")
            check(CompressedSparseRow(vertexCount: 6, edges: edges), "CompressedSparseRow")
            check(AdjacencyList(vertices: 0 ..< 6, edges: edges), "AdjacencyList")
            check(AdjacencyMatrix(vertexCount: 6, edges: edges), "AdjacencyMatrix")
            var stable = StableDirectedGraph(vertices: 0 ..< 7, edges: [DirectedEdge(from: 6, to: 0)] + edges)
            _ = stable.remove(6)
            check(stable, "StableDirectedGraph with holes")
        }
    }

    @Test("TR-265 the sequence holds the graph and iterates again the same; Sendable")
    func valueSemantics() {
        var graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
        let sorts = graph.allTopologicalSorts()
        graph.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(Array(sorts) == [[0, 1, 2], [0, 2, 1], [2, 0, 1]])
        #expect(Array(sorts) == Array(sorts))
        #expect(Array(graph.allTopologicalSorts()) == [[0, 1, 2]])
        let sendable: any Sendable = CompressedSparseRow(vertexCount: 1, edges: []).allTopologicalSorts()
        #expect(sendable is AllTopologicalSorts<CompressedSparseRow>)
    }
}
