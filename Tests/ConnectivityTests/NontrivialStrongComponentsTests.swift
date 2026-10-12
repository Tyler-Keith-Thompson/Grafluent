// nontrivialStronglyConnectedComponents(): fixtures for the edge cases (no vertices, a lone vertex
// with and without a self-loop, a self-loop inside a larger component, a DAG), the documented
// order, and a PropertyBased law against a brute-force model on every representation the target
// links: adjacency list, matrix, CSR, a multigraph with repeated edges and loops, a conformer
// without vertex indices, and a sparsely indexed conformer with vertex holes.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Traversal

/// Supplies only what DirectedGraph requires: no vertex indices, so algorithms use dictionaries.
private struct DictionaryGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

/// A sparsely indexed graph whose vertices are their positions, with holes where `alive` is false:
/// no vertex indices, so algorithms number it through its rows.
private struct HoleyGraph: SparselyIndexedDirectedGraph {
    let alive: [Bool]
    let edges: [DirectedEdge<Int>]
    var vertices: [Int] { alive.indices.filter { alive[$0] } }
    func successors(of vertex: Int) -> [Int] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func predecessors(of vertex: Int) -> [Int] { edges.filter { $0.target == vertex }.map(\.source) }
    func inEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].target == vertex } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < alive.count && alive[vertex] }
    var vertexPositionBound: Int { alive.count }
    var edgePositionBound: Int { edges.count }
    func vertexPosition(of vertex: Int) -> Int { vertex }
    func vertex(atPosition position: Int) -> Int { position }
    func containsVertex(atPosition position: Int) -> Bool { contains(position) }
    func containsEdge(atPosition position: Int) -> Bool { position >= 0 && position < edges.count }
}

@Suite("Nontrivial strong components")
struct NontrivialStrongComponentsTests {
    @Test("no vertices, or only trivial components, give no nontrivial component")
    func noneWithoutCycles() {
        #expect(AdjacencyList<Int>().nontrivialStronglyConnectedComponents().isEmpty)
        #expect(AdjacencyMatrix(vertexCount: 0).nontrivialStronglyConnectedComponents().isEmpty)
        #expect(CompressedSparseRow(vertexCount: 0).nontrivialStronglyConnectedComponents().isEmpty)
        #expect(DictionaryGraph<Int>(vertices: [], edges: []).nontrivialStronglyConnectedComponents().isEmpty)
        let dag = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)]
        #expect(AdjacencyList(vertices: 0 ..< 4, edges: dag).nontrivialStronglyConnectedComponents().isEmpty)
        #expect(AdjacencyMatrix(vertexCount: 4, edges: dag).nontrivialStronglyConnectedComponents().isEmpty)
        #expect(CompressedSparseRow(vertexCount: 4, edges: dag).nontrivialStronglyConnectedComponents().isEmpty)
        #expect(DictionaryGraph(vertices: Array(0 ..< 4), edges: dag).nontrivialStronglyConnectedComponents().isEmpty)
    }

    @Test("a lone vertex is nontrivial exactly when it has a self-loop")
    func loneVertex() {
        #expect(AdjacencyList(vertices: [7], edges: []).nontrivialStronglyConnectedComponents().isEmpty)
        let loop = [DirectedEdge(from: 0, to: 0)]
        #expect(AdjacencyList(vertices: 0 ..< 1, edges: loop).nontrivialStronglyConnectedComponents().map(Array.init) == [[0]])
        #expect(AdjacencyMatrix(vertexCount: 1, edges: loop).nontrivialStronglyConnectedComponents().map(Array.init) == [[0]])
        #expect(CompressedSparseRow(vertexCount: 1, edges: loop).nontrivialStronglyConnectedComponents().map(Array.init) == [[0]])
        #expect(DictionaryGraph(vertices: [0], edges: loop).nontrivialStronglyConnectedComponents().map(Array.init) == [[0]])
        // A loop on the last vertex only, after loopless ones: the noted vertex is the right one.
        let last = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)]
        #expect(CompressedSparseRow(vertexCount: 3, edges: last).nontrivialStronglyConnectedComponents().map(Array.init) == [[2]])
        #expect(AdjacencyList(vertices: 0 ..< 3, edges: last).nontrivialStronglyConnectedComponents().map(Array.init) == [[2]])
    }

    @Test("a self-loop inside a larger component adds nothing; components keep the documented order")
    func orderAndLoopsInsideComponents() {
        // 0 ⇄ 1 with a loop at 1, 1 → 2, 2 → 3 → 2, 4 alone, 5 with a loop, 3 → 5, 5 → 6.
        let edges = [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2),
            DirectedEdge(from: 5, to: 5), DirectedEdge(from: 3, to: 5), DirectedEdge(from: 5, to: 6),
        ]
        // Reverse topological: {5} before {2, 3} before {0, 1}.
        let expected = [[5], [2, 3], [0, 1]]
        #expect(AdjacencyList(vertices: 0 ..< 7, edges: edges).nontrivialStronglyConnectedComponents().map(Array.init) == expected)
        #expect(AdjacencyMatrix(vertexCount: 7, edges: edges).nontrivialStronglyConnectedComponents().map(Array.init) == expected)
        #expect(CompressedSparseRow(vertexCount: 7, edges: edges).nontrivialStronglyConnectedComponents().map(Array.init) == expected)
        #expect(DictionaryGraph(vertices: Array(0 ..< 7), edges: edges).nontrivialStronglyConnectedComponents().map(Array.init) == expected)
        // Vertices out of label order: each component lists its vertices in `vertices` order.
        let labeled = DictionaryGraph(vertices: ["c", "a", "b"], edges: [DirectedEdge(from: "a", to: "c"), DirectedEdge(from: "c", to: "b"), DirectedEdge(from: "b", to: "a")])
        #expect(labeled.nontrivialStronglyConnectedComponents().map(Array.init) == [["c", "a", "b"]])
    }

    @Test("each component is a slice of a shared array, whose indices need not start at 0")
    func slices() {
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 2)]
        let components = AdjacencyList(vertices: 0 ..< 4, edges: edges).nontrivialStronglyConnectedComponents()
        #expect(components.count == 2)
        #expect(components.map(\.count) == [2, 2])
        #expect(components.map { $0.first! } == [0, 2])
        #expect(components[1].startIndex == 2)
    }

    @Test("law: the strong components with a cycle, against reachability, in stronglyConnectedComponents() order; a failure shrinks")
    func law() async {
        // Up to 20 edges on vertices 0..<8, repeats and self-loops allowed.
        let raw = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 20)
        await propertyCheck(count: 400, input: raw) { pairs in
            let n = 8
            let edges = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
            var successors = [[Int]](repeating: [], count: n)
            for e in edges { successors[e.source].append(e.target) }
            // Model: u and v share a nontrivial component when each reaches the other by a path of
            // at least one edge (so a lone vertex needs a self-loop).
            var reaches = [Set<Int>](repeating: [], count: n)
            for s in 0 ..< n {
                var stack = successors[s]
                while let u = stack.popLast() {
                    if reaches[s].insert(u).inserted { stack += successors[u] }
                }
            }
            var model = Set<Set<Int>>()
            for v in 0 ..< n where reaches[v].contains(v) {
                model.insert(Set((0 ..< n).filter { reaches[v].contains($0) && reaches[$0].contains(v) }))
            }
            func check<G: DirectedGraph<Int>>(_ g: G) {
                let components = g.nontrivialStronglyConnectedComponents().map(Array.init)
                #expect(Set(components.map(Set.init)) == model)
                #expect(components.allSatisfy { $0 == $0.sorted() })
                // The same order as the full partition.
                let all = g.stronglyConnectedComponents().map(Array.init)
                #expect(components == all.filter { model.contains(Set($0)) })
                #expect(components.isEmpty == g.isAcyclic)
            }
            check(AdjacencyList(vertices: 0 ..< n, edges: edges))
            check(AdjacencyMatrix(vertexCount: n, edges: edges))
            check(CompressedSparseRow(vertexCount: n, edges: edges))
            check(ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: edges))
            check(DictionaryGraph(vertices: Array(0 ..< n), edges: edges))
            // Vertex v at position 2v, the odd positions holes.
            let holey = HoleyGraph(alive: (0 ..< 2 * n).map { $0.isMultiple(of: 2) }, edges: edges.map { DirectedEdge(from: 2 * $0.source, to: 2 * $0.target) })
            #expect(holey.vertexIndexBound == nil)
            let halved = holey.nontrivialStronglyConnectedComponents().map { $0.map { $0 / 2 } }
            #expect(Set(halved.map(Set.init)) == model)
            #expect(halved == holey.stronglyConnectedComponents().map { $0.map { $0 / 2 } }.filter { model.contains(Set($0)) })
        }
    }
}
