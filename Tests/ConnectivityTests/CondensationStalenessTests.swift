// Condensation staleness: a condensation records its graph's generation, and `isCurrent(for:)`
// says whether the graph has been structurally mutated since. The graph is a digraph local to this
// file that tracks generations the way the library's representations do. See README.md.

import Connectivity
import GraphProtocols
import Testing

/// A digraph on 0..<n whose edges are an array, with a generation every insertion or removal
/// starts.
private struct TrackedDigraph: DirectedGraph {
    typealias Vertex = Int

    var vertexTotal: Int
    var arcs: [DirectedEdge<Int>] = []
    var stamp = _GenerationStamp()

    init(vertexCount: Int, edges: [(Int, Int)]) {
        vertexTotal = vertexCount
        for (s, t) in edges { insert(edge: DirectedEdge(from: s, to: t)) }
    }

    var vertices: Range<Int> { 0 ..< vertexTotal }
    var edges: [DirectedEdge<Int>] { arcs }
    var vertexIndexBound: Int? { vertexTotal }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertexTotal }
    func successors(of vertex: Int) -> [Int] { arcs.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Int) -> [Int] { arcs.indices.filter { arcs[$0].source == vertex } }

    var generation: GraphGeneration { stamp.generation }

    mutating func insert(edge: DirectedEdge<Int>) {
        arcs.append(edge)
        stamp.advance()
    }

    mutating func removeLastEdge() {
        arcs.removeLast()
        stamp.advance()
    }
}

@Suite("Condensation staleness")
struct CondensationStalenessTests {
    @Test("A condensation is current for its graph and copies of it until one of them is structurally mutated")
    func currentUntilMutated() {
        var graph = TrackedDigraph(vertexCount: 4, edges: [(0, 1), (1, 0), (1, 2)])
        let condensation = graph.condensation()
        #expect(condensation.components.count == 3)
        #expect(condensation.isCurrent(for: graph))
        #expect(condensation.sourceGeneration.isCurrent(for: graph) && graph.generation.isCurrent(for: condensation.sourceGeneration))
        // A copy shares the generation until it is mutated; mutating the copy leaves the original current.
        var copy = graph
        #expect(condensation.isCurrent(for: copy))
        copy.insert(edge: DirectedEdge(from: 2, to: 3))
        #expect(!condensation.isCurrent(for: copy) && condensation.isCurrent(for: graph))
        // Closing a cycle merges components: the condensation is stale.
        graph.insert(edge: DirectedEdge(from: 2, to: 1))
        #expect(!condensation.isCurrent(for: graph))
        let merged = graph.condensation()
        #expect(merged.components.count == 2 && merged.isCurrent(for: graph))
        // Undoing the edge restores the structure but not the generation.
        graph.removeLastEdge()
        #expect(!merged.isCurrent(for: graph) && !condensation.isCurrent(for: graph))
        #expect(graph.condensation().components.count == 3)
    }

    @Test("Two condensations of one generation are both current, and another graph's condensation is not")
    func sameGeneration() {
        var graph = TrackedDigraph(vertexCount: 3, edges: [(0, 1)])
        let first = graph.condensation()
        let second = graph.condensation()
        #expect(first.isCurrent(for: graph) && second.isCurrent(for: graph))
        #expect(first.sourceGeneration.isCurrent(for: second.sourceGeneration))
        let other = TrackedDigraph(vertexCount: 3, edges: [(0, 1)])
        #expect(!first.isCurrent(for: other) && !other.condensation().isCurrent(for: graph))
        graph.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(!first.isCurrent(for: graph) && !second.isCurrent(for: graph))
    }

    @Test("A graph with no generation yet gives a condensation current for nothing")
    func untracked() {
        // Never mutated: no generation yet.
        let empty = TrackedDigraph(vertexCount: 2, edges: [])
        let condensation = empty.condensation()
        #expect(!condensation.isCurrent(for: empty) && condensation.sourceGeneration._lineage == 0)
    }
}
