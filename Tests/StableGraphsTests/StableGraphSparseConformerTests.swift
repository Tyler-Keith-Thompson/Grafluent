// SparselyIndexedDirectedGraph conformed to outside the library: a test-local wrapper that
// forwards the public members of a StableDirectedGraph and leaves `_numberedRows` to the default.
// Every algorithm that numbers a graph with holes (components, dominators, post-dominators,
// traversals, reachability) must agree with the wrapped graph, whose own override is the fast
// path, and with the compacted copy. Then post-dominators and component lookups by vertex with one
// vertex hole, against the hole-free graph. See README.md.

import Connectivity
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing
import Traversal

/// A conformer outside the package: public members only, `_numberedRows` from the default.
private struct Forwarding: SparselyIndexedDirectedGraph {
    let base: StableDirectedGraph<Int>
    var vertices: StableDirectedGraph<Int>.Vertices { base.vertices }
    var edges: StableDirectedGraph<Int>.Edges { base.edges }
    var vertexCount: Int { base.vertexCount }
    var edgeCount: Int { base.edgeCount }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
    func successors(of vertex: Int) -> StableDirectedGraph<Int>.Neighbors { base.successors(of: vertex) }
    func predecessors(of vertex: Int) -> StableDirectedGraph<Int>.Neighbors { base.predecessors(of: vertex) }
    func outEdges(of vertex: Int) -> StableDirectedGraph<Int>.OutEdges { base.outEdges(of: vertex) }
    func inEdges(of vertex: Int) -> StableDirectedGraph<Int>.InEdges { base.inEdges(of: vertex) }
    func source(ofEdgeAt position: Int) -> Int { base.source(ofEdgeAt: position) }
    func target(ofEdgeAt position: Int) -> Int { base.target(ofEdgeAt: position) }
    var vertexPositionBound: Int { base.vertexPositionBound }
    var edgePositionBound: Int { base.edgePositionBound }
    func vertexPosition(of vertex: Int) -> Int { base.vertexPosition(of: vertex) }
    func vertex(atPosition position: Int) -> Int { base.vertex(atPosition: position) }
    func containsVertex(atPosition position: Int) -> Bool { base.containsVertex(atPosition: position) }
    func containsEdge(atPosition position: Int) -> Bool { base.containsEdge(atPosition: position) }
}

@Suite("StableGraphs: SparselyIndexedDirectedGraph outside the library", .tags(.conformance))
struct StableGraphSparseConformerTests {
    @Test("The default _numberedRows gives every numbered algorithm the wrapped graph's results", arguments: [1, 2, 3, 4, 5, 6])
    func defaultNumberedRows(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = 10 + seed * 4
        var graph = StableDirectedGraph<Int>(vertices: 0 ..< n)
        for _ in 0 ..< n * 3 {
            graph.insert(edge: DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)))
        }
        for v in 0 ..< n where Int.random(in: 0 ..< 3, using: &rng) == 0 { graph.remove(v) }
        for p in Array(graph.edges.indices) where Int.random(in: 0 ..< 4, using: &rng) == 0 { graph.remove(edgeAt: p) }
        graph.insert(n)
        #expect(graph.vertexIndexBound == nil)
        let wrapped = Forwarding(base: graph)
        #expect(wrapped.vertexIndexBound == nil)
        let compacted = DirectedPseudograph<Int>(graph)
        #expect(wrapped.stronglyConnectedComponents().map { Array($0) } == graph.stronglyConnectedComponents().map { Array($0) })
        #expect(wrapped.weaklyConnectedComponents().map { Array($0) } == compacted.weaklyConnectedComponents().map { Array($0) })
        #expect(Array(wrapped.depthFirstSearch()) == Array(graph.depthFirstSearch()))
        for vertex in graph.vertices {
            #expect(wrapped.descendants(of: vertex) == compacted.descendants(of: vertex))
            #expect(wrapped.ancestors(of: vertex) == compacted.ancestors(of: vertex))
            #expect(Array(wrapped.breadthFirstSearch(from: vertex)) == Array(graph.breadthFirstSearch(from: vertex)))
            let dominators = wrapped.dominatorTree(root: vertex)
            let copyDominators = compacted.dominatorTree(root: vertex)
            let post = wrapped.postDominatorTree(exit: vertex)
            let copyPost = compacted.postDominatorTree(exit: vertex)
            for other in graph.vertices {
                #expect(dominators.immediateDominator(of: other) == copyDominators.immediateDominator(of: other))
                #expect(post.immediateDominator(of: other) == copyPost.immediateDominator(of: other))
            }
        }
    }

    @Test("Post-dominators and component lookups with one vertex hole equal the hole-free graph's")
    func oneVertexHole() {
        var rng = SeededRandomNumberGenerator(seed: 17)
        let n = 200
        var dense = StableDirectedGraph<Int>(vertices: 0 ..< n)
        for _ in 0 ..< n * 4 {
            dense.insert(edge: DirectedEdge(from: Int.random(in: 0 ..< n, using: &rng), to: Int.random(in: 0 ..< n, using: &rng)))
        }
        var holed = dense
        holed.insert(-1)
        holed.remove(-1)
        #expect(dense.vertexIndexBound == n && holed.vertexIndexBound == nil)
        let components = dense.stronglyConnectedComponents()
        let holedComponents = holed.stronglyConnectedComponents()
        #expect((0 ..< n).map { holedComponents.component(of: $0) } == (0 ..< n).map { components.component(of: $0) })
        for exit in [0, 7, 199] {
            let post = dense.postDominatorTree(exit: exit)
            let holedPost = holed.postDominatorTree(exit: exit)
            #expect((0 ..< n).map { holedPost.immediateDominator(of: $0) } == (0 ..< n).map { post.immediateDominator(of: $0) })
        }
    }
}
