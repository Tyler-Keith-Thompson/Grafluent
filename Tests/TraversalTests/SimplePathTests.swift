// allSimplePaths(from:to:maxLength:): every simple path from a source to one target or several,
// directed and undirected, as Walks `Path`s with edge positions. Hand-computed cases pin the order
// (a depth-first search taking edges in row order), parallel edges, self-loops, several targets,
// the trivial path and the length bound; a property test compares every representation with a
// recursive enumeration written in the test. Case IDs (TR-nn) refer to the catalog; see README.md.

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
import Walks

/// A directed multigraph without vertex indices.
private struct UnindexedDigraph: DirectedGraph {
    let base: ReferenceDirectedMultigraph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [DirectedEdge<Int>] { base.edges }
    func successors(of vertex: Int) -> [Int] { base.successors(of: vertex) }
    func outEdges(of vertex: Int) -> [Int] { base.outEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

/// An undirected pseudograph without vertex indices.
private struct UnindexedPseudograph: Graph {
    let base: ReferencePseudograph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [UndirectedEdge<Int>] { base.edges }
    func neighbors(of vertex: Int) -> [Int] { base.neighbors(of: vertex) }
    func incidentEdges(of vertex: Int) -> [Int] { base.incidentEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

@Suite("All simple paths")
struct SimplePathTests {
    @Test("TR-230 directed: every path to one target, in depth-first order, with its edge positions")
    func directedOneTarget() {
        let graph = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3),
        ])
        let paths = Array(graph.allSimplePaths(from: 0, to: 3))
        #expect(paths.map(\.vertices) == [[0, 1, 2, 3], [0, 2, 3]])
        #expect(paths.map(\.edges) == [[0, 1, 3], [2, 3]])
        #expect(Array(graph.allSimplePaths(from: 3, to: 0)).isEmpty)
        #expect(Array(graph.allSimplePaths(from: 1, to: 3)).map(\.vertices) == [[1, 2, 3]])
    }

    @Test("TR-231 several targets: a path through one target goes on to the others; the source as a target is the trivial path")
    func severalTargets() {
        let graph = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3),
        ])
        // NetworkX 3.7 all_simple_paths(G, 0, [2, 3]) lists the same paths in the same order.
        #expect(Array(graph.allSimplePaths(from: 0, to: [2, 3])).map(\.vertices) == [[0, 1, 2], [0, 1, 2, 3], [0, 2], [0, 2, 3]])
        #expect(Array(graph.allSimplePaths(from: 0, to: [0, 2])).map(\.vertices) == [[0], [0, 1, 2], [0, 2]])
        #expect(Array(graph.allSimplePaths(from: 0, to: 0)).map(\.vertices) == [[0]])
        #expect(Array(graph.allSimplePaths(from: 0, to: 0)).map(\.edges) == [[]])
        // A repeated target counts once.
        #expect(Array(graph.allSimplePaths(from: 0, to: [3, 3])).map(\.vertices) == [[0, 1, 2, 3], [0, 2, 3]])
        #expect(Array(graph.allSimplePaths(from: 0, to: [Int]())).isEmpty)
    }

    @Test("TR-232 maxLength keeps the paths of at most that many edges, in the same order")
    func lengthBound() {
        let graph = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 2, to: 3),
        ])
        // NetworkX 3.7 all_simple_paths(G, 0, [1, 2, 3], cutoff=2).
        #expect(Array(graph.allSimplePaths(from: 0, to: [1, 2, 3], maxLength: 2)).map(\.vertices) == [[0, 1], [0, 1, 2], [0, 2], [0, 2, 3]])
        #expect(Array(graph.allSimplePaths(from: 0, to: 3, maxLength: 2)).map(\.vertices) == [[0, 2, 3]])
        #expect(Array(graph.allSimplePaths(from: 0, to: 3, maxLength: 1)).isEmpty)
        #expect(Array(graph.allSimplePaths(from: 0, to: [0, 1], maxLength: 0)).map(\.vertices) == [[0]])
        #expect(graph.allSimplePaths(from: 0, to: 3, maxLength: 2).maxLength == 2)
        #expect(graph.allSimplePaths(from: 0, to: 3).maxLength == .max)
    }

    @Test("TR-233 directed parallel edges give one path per copy; self-loops and cycles are never entered twice")
    func directedMultigraph() {
        var graph = DirectedPseudograph<Int>()
        let a = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let b = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let loop = graph.insert(edge: DirectedEdge(from: 1, to: 1))
        let c = graph.insert(edge: DirectedEdge(from: 1, to: 2))
        let back = graph.insert(edge: DirectedEdge(from: 2, to: 0))
        let paths = Array(graph.allSimplePaths(from: 0, to: 2))
        #expect(paths.map(\.vertices) == [[0, 1, 2], [0, 1, 2]])
        #expect(Set(paths.map(\.edges)) == [[a, c], [b, c]])
        #expect(!paths.contains { $0.edges.contains(loop) || $0.edges.contains(back) })
        for path in paths { #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil) }
    }

    @Test("TR-234 undirected: each path once from the source, parallel edges apart, self-loops never taken")
    func undirected() {
        // C(0..3): row order at 0 is 0–1 (position 0), then 3–0 (position 3).
        let cycle = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let around = Array(cycle.allSimplePaths(from: 0, to: 2))
        #expect(around.map(\.vertices) == [[0, 1, 2], [0, 3, 2]])
        #expect(around.map(\.edges) == [[0, 1], [3, 2]])
        let multi = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 0), UndirectedEdge(2, 2)])
        let paths = Array(multi.allSimplePaths(from: 0, to: 2))
        #expect(paths.map(\.vertices) == [[0, 1, 2], [0, 1, 2]])
        #expect(paths.map(\.edges) == [[0, 2], [1, 2]])
        // Reversed, the same paths from the other end.
        #expect(Array(multi.allSimplePaths(from: 2, to: 0)).map(\.edges) == [[2, 0], [2, 1]])
        // NetworkX 3.7 all_simple_edge_paths on MultiGraph([(0,1),(0,1),(1,2)]) gives the two.
        #expect(Array(multi.allSimplePaths(from: 0, to: [1, 2])).map(\.edges) == [[0], [0, 2], [1], [1, 2]])
    }

    @Test("TR-235 unreachable and disconnected targets, isolated vertices, the empty sequence")
    func unreachable() {
        let graph = AdjacencyList(vertices: 0 ..< 5, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3)])
        #expect(Array(graph.allSimplePaths(from: 0, to: 3)).isEmpty)
        #expect(Array(graph.allSimplePaths(from: 4, to: 0)).isEmpty)
        #expect(Array(graph.allSimplePaths(from: 4, to: 4)).map(\.vertices) == [[4]])
        let undirected = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        #expect(Array(undirected.allSimplePaths(from: 1, to: [2, 3])).isEmpty)
        #expect(Array(undirected.allSimplePaths(from: 1, to: 0)).map(\.vertices) == [[1, 0]])
    }

    @Test("TR-236 complete digraphs: the number of paths between two vertices is the sum over k of (n − 2)!/(n − 2 − k)!")
    func completeCounts() {
        for n in 2 ... 7 {
            var edges: [DirectedEdge<Int>] = []
            for u in 0 ..< n { for v in 0 ..< n where u != v { edges.append(DirectedEdge(from: u, to: v)) } }
            let graph = CompressedSparseRow(vertexCount: n, edges: edges)
            var expected = 0, term = 1
            for k in 0 ... n - 2 {
                expected += term
                term *= n - 2 - k
            }
            #expect(graph.allSimplePaths(from: 0, to: n - 1).reduce(0) { count, _ in count + 1 } == expected, "n = \(n)")
            let undirected = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).flatMap { u in (u + 1 ..< n).map { UndirectedEdge(u, $0) } })
            #expect(undirected.allSimplePaths(from: 0, to: n - 1).reduce(0) { count, _ in count + 1 } == expected, "n = \(n)")
        }
    }

    @Test("TR-237 String vertices, a sequence held by value and iterated twice, Sendable")
    func valueSemantics() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "c"), DirectedEdge(from: "a", to: "c")])
        let paths = graph.allSimplePaths(from: "a", to: "c")
        graph.insert(edge: DirectedEdge(from: "a", to: "d"))
        graph.insert(edge: DirectedEdge(from: "d", to: "c"))
        let first = Set(paths.map(\.vertices))
        #expect(first == [["a", "b", "c"], ["a", "c"]])
        #expect(Set(paths.map(\.vertices)) == first)
        #expect(Set(graph.allSimplePaths(from: "a", to: "c").map(\.vertices)) == [["a", "b", "c"], ["a", "c"], ["a", "d", "c"]])
        let sendable: any Sendable = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).allSimplePaths(from: 0, to: 1)
        #expect(sendable is DirectedSimplePaths<CompressedSparseRow>)
    }

    @Test("TR-238 a source or target that is not a vertex, or a negative maxLength, traps")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).allSimplePaths(from: 7, to: 1)
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).allSimplePaths(from: 0, to: [1, 7])
        }
        await #expect(processExitsWith: .failure) {
            _ = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)]).allSimplePaths(from: 0, to: 1, maxLength: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)]).allSimplePaths(from: 0, to: 9)
        }
    }

    @Test("TR-239 directed: content and order are a recursive enumeration's, on every representation")
    func directedAgainstRecursion() async {
        // Up to 14 edges on 0..<6, repeats and self-loops allowed; a source, two targets, a bound
        // (6 for none).
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)) { raw, source, target, other, bound in
            let edges = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            let targets = other == 6 ? [target] : [target, other]
            let maxLength = bound == 6 ? Int.max : bound
            func check<G: DirectedGraph<Int>>(_ g: G, _ name: String) {
                var expected: [(vertices: [Int], edges: [G.Edges.Index])] = []
                var vertices = [source]
                var taken: [G.Edges.Index] = []
                func extend() {
                    if targets.contains(vertices[vertices.count - 1]) { expected.append((vertices, taken)) }
                    // One target: nothing lies beyond it.
                    if Set(targets).count == 1, targets.contains(vertices[vertices.count - 1]) { return }
                    guard taken.count < maxLength else { return }
                    for e in g.outEdges(of: vertices[vertices.count - 1]) where !vertices.contains(g.target(ofEdgeAt: e)) {
                        vertices.append(g.target(ofEdgeAt: e))
                        taken.append(e)
                        extend()
                        vertices.removeLast()
                        taken.removeLast()
                    }
                }
                extend()
                let paths = Array(g.allSimplePaths(from: source, to: targets, maxLength: maxLength))
                #expect(paths.map(\.vertices) == expected.map(\.vertices), "\(name)")
                #expect(paths.map(\.edges) == expected.map(\.edges), "\(name)")
                for path in paths { #expect(Path(vertices: path.vertices, edges: path.edges, in: g) != nil, "\(name)") }
            }
            let reference = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: edges)
            check(reference, "ReferenceDirectedMultigraph")
            check(UnindexedDigraph(base: reference), "without vertex indices")
            check(DirectedPseudograph(vertices: 0 ..< 6, edges: edges), "DirectedPseudograph")
            check(CompressedSparseRow(vertexCount: 6, edges: edges), "CompressedSparseRow")
            check(AdjacencyList(vertices: 0 ..< 6, edges: edges), "AdjacencyList")
            check(AdjacencyMatrix(vertexCount: 6, edges: edges), "AdjacencyMatrix")
            var stable = StableDirectedGraph(vertices: 0 ..< 7, edges: [DirectedEdge(from: 6, to: 6), DirectedEdge(from: 6, to: 0)] + edges)
            _ = stable.remove(6)
            check(stable, "StableDirectedGraph with holes")
        }
    }

    @Test("TR-240 undirected: content and order are a recursive enumeration's, on every representation")
    func undirectedAgainstRecursion() async {
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)) { raw, source, target, other, bound in
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            let targets = other == 6 ? [target] : [target, other]
            let maxLength = bound == 6 ? Int.max : bound
            func check<G: Graph<Int>>(_ g: G, _ name: String) {
                var expected: [(vertices: [Int], edges: [G.Edges.Index])] = []
                var vertices = [source]
                var taken: [G.Edges.Index] = []
                func extend() {
                    let v = vertices[vertices.count - 1]
                    if targets.contains(v) { expected.append((vertices, taken)) }
                    if Set(targets).count == 1, targets.contains(v) { return }
                    guard taken.count < maxLength else { return }
                    for e in g.incidentEdges(of: v) where !vertices.contains(g.oppositeVertex(to: v, acrossEdgeAt: e)) {
                        vertices.append(g.oppositeVertex(to: v, acrossEdgeAt: e))
                        taken.append(e)
                        extend()
                        vertices.removeLast()
                        taken.removeLast()
                    }
                }
                extend()
                let paths = Array(g.allSimplePaths(from: source, to: targets, maxLength: maxLength))
                #expect(paths.map(\.vertices) == expected.map(\.vertices), "\(name)")
                #expect(paths.map(\.edges) == expected.map(\.edges), "\(name)")
                for path in paths { #expect(Path(vertices: path.vertices, edges: path.edges, in: g) != nil, "\(name)") }
            }
            let reference = ReferencePseudograph(vertices: 0 ..< 6, edges: edges)
            check(reference, "ReferencePseudograph")
            check(UnindexedPseudograph(base: reference), "without vertex indices")
            check(Pseudograph(vertices: 0 ..< 6, edges: edges), "Pseudograph")
            check(UndirectedAdjacencyList(vertices: 0 ..< 6, edges: edges), "UndirectedAdjacencyList")
        }
    }
}
