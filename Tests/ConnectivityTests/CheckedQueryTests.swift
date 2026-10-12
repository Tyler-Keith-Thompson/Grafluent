// The `checked:` spellings of the result queries (README Principle 6): each answers a vertex or an
// edge position of the graph as its trapping spelling does, nil keeping its meaning (the root, an
// unreachable vertex, a self-loop, a vertex in no block), and throws `VertexNotFound` or
// `EdgeNotFound` where the trapping spelling would trap. Every result is read on an indexed graph
// and on one without indices, which looks vertices and positions up in dictionaries.

import AdjacencyListModule
import Connectivity
import GraphProtocols
import Testing

/// Supplies only what DirectedGraph requires: no vertex indices.
private struct UnindexedDirectedGraph: DirectedGraph {
    let vertices: [String]
    let edges: [DirectedEdge<String>]
    func successors(of vertex: String) -> [String] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: String) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

/// An undirected pseudograph with no vertex or edge indices.
private struct UnindexedGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

@Suite("Connectivity checked: result queries")
struct CheckedQueryTests {
    @Test("component(checked:) answers as component(of:) and throws for a non-vertex")
    func components() throws {
        // r→a→b→a, c alone: the strong components {a, b}, {c}, {r}.
        let vertices = ["r", "a", "b", "c"]
        let edges = [("r", "a"), ("a", "b"), ("b", "a")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let indexed = AdjacencyList(vertices: vertices, edges: edges).stronglyConnectedComponents()
        let unindexed = UnindexedDirectedGraph(vertices: vertices, edges: edges).stronglyConnectedComponents()
        for v in vertices {
            #expect(try indexed.component(checked: v) == indexed.component(of: v))
            #expect(try unindexed.component(checked: v) == unindexed.component(of: v))
        }
        #expect(try indexed.component(checked: "a") == indexed.component(checked: "b"))
        #expect(try indexed.component(checked: "a") != indexed.component(checked: "c"))
        #expect(throws: VertexNotFound.self) { try indexed.component(checked: "z") }
        #expect(throws: VertexNotFound.self) { try unindexed.component(checked: "z") }
        #expect((try? indexed.component(checked: "z")) == nil)
    }

    @Test("DominatorTree checked: spellings keep nil for the root and an unreachable vertex, and throw for a non-vertex")
    func dominatorTree() throws {
        // r→a, r→b, a→c, b→c, c→d, u→c: u is unreachable from r.
        let vertices = ["r", "a", "b", "c", "d", "u"]
        let edges = [("r", "a"), ("r", "b"), ("a", "c"), ("b", "c"), ("c", "d"), ("u", "c")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let indexed = AdjacencyList(vertices: vertices, edges: edges).dominatorTree(root: "r")
        let unindexed = UnindexedDirectedGraph(vertices: vertices, edges: edges).dominatorTree(root: "r")
        for v in vertices {
            #expect(try indexed.immediateDominator(checked: v) == indexed.immediateDominator(of: v))
            #expect(try unindexed.immediateDominator(checked: v) == unindexed.immediateDominator(of: v))
            #expect(try indexed.dominators(checked: v) == indexed.dominators(of: v))
            #expect(try unindexed.dominators(checked: v) == unindexed.dominators(of: v))
            #expect(try indexed.strictDominators(checked: v) == indexed.strictDominators(of: v))
            #expect(try Array(indexed.children(checked: v)) == Array(indexed.children(of: v)))
            #expect(try Array(unindexed.children(checked: v)) == Array(unindexed.children(of: v)))
            for w in vertices {
                #expect(try indexed.dominates(checked: v, w) == indexed.dominates(v, w))
                #expect(try unindexed.dominates(checked: v, w) == unindexed.dominates(v, w))
            }
        }
        #expect(try indexed.immediateDominator(checked: "d") == "c")
        #expect(try indexed.immediateDominator(checked: "r") == nil)
        #expect(try indexed.immediateDominator(checked: "u") == nil)
        #expect(try indexed.dominators(checked: "d") == ["d", "c", "r"])
        #expect(try indexed.dominators(checked: "u") == nil)
        #expect(try indexed.strictDominators(checked: "d") == ["c", "r"])
        #expect(try indexed.strictDominators(checked: "u") == nil)
        #expect(try Array(indexed.children(checked: "r")) == ["a", "b", "c"])
        #expect(try indexed.dominates(checked: "c", "d"))
        #expect(try !indexed.dominates(checked: "a", "c"))
        for tree in [indexed, AdjacencyList(vertices: vertices, edges: edges).postDominatorTree(exit: "d")] {
            #expect(throws: VertexNotFound.self) { try tree.immediateDominator(checked: "z") }
            #expect(throws: VertexNotFound.self) { try tree.dominators(checked: "z") }
            #expect(throws: VertexNotFound.self) { try tree.strictDominators(checked: "z") }
            #expect(throws: VertexNotFound.self) { try tree.children(checked: "z") }
            #expect(throws: VertexNotFound.self) { try tree.dominates(checked: "z", "r") }
            #expect(throws: VertexNotFound.self) { try tree.dominates(checked: "r", "z") }
        }
        #expect(throws: VertexNotFound.self) { try unindexed.immediateDominator(checked: "z") }
        #expect(throws: VertexNotFound.self) { try unindexed.dominates(checked: "r", "z") }
        // The post-dominator tree: every path from a, b, c, r to d passes through c.
        let post = AdjacencyList(vertices: vertices, edges: edges).postDominatorTree(exit: "d")
        #expect(try post.immediateDominator(checked: "a") == "c")
        #expect(try post.immediateDominator(checked: "d") == nil)
        #expect(try post.dominates(checked: "c", "u"))
    }

    @Test("DominanceFrontiers[checked:] keeps nil for an unreachable vertex and throws for a non-vertex")
    func dominanceFrontiers() throws {
        let vertices = ["r", "a", "b", "c", "d", "u"]
        let edges = [("r", "a"), ("r", "b"), ("a", "c"), ("b", "c"), ("c", "d"), ("u", "c")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let indexed = AdjacencyList(vertices: vertices, edges: edges).dominanceFrontiers(root: "r")
        let unindexed = UnindexedDirectedGraph(vertices: vertices, edges: edges).dominanceFrontiers(root: "r")
        for v in vertices {
            #expect(try indexed[checked: v].map(Array.init) == indexed[v].map(Array.init))
            #expect(try unindexed[checked: v].map(Array.init) == unindexed[v].map(Array.init))
        }
        #expect(try indexed[checked: "a"].map(Array.init) == ["c"])
        #expect(try indexed[checked: "u"] == nil)
        #expect(throws: VertexNotFound.self) { try indexed[checked: "z"] }
        #expect(throws: VertexNotFound.self) { try unindexed[checked: "z"] }
    }

    @Test("BiconnectedComponents and BlockCutTree checked: spellings keep nil for a self-loop and a vertex in no block, and throw for a non-member")
    func blocks() throws {
        // The triangle 0-1-2 at positions 0 – 2, the bridge 2-3 at 3, a loop at 3 at 4, 4 isolated.
        let edges = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 3)].map { UndirectedEdge($0.0, $0.1) }
        let list = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: edges)
        let plain = UnindexedGraph(vertices: [0, 1, 2, 3, 4], edges: edges)
        let indexed = list.biconnectedComponents(), unindexed = plain.biconnectedComponents()
        #expect(plain.edgeIndexBound == nil && plain.vertexIndexBound == nil)
        for position in list.edges.indices {
            #expect(try indexed.component(checkedEdgeAt: position) == indexed.component(ofEdgeAt: position))
        }
        for position in plain.edges.indices {
            #expect(try unindexed.component(checkedEdgeAt: position) == unindexed.component(ofEdgeAt: position))
        }
        #expect(try indexed.component(checkedEdgeAt: 4) == nil)
        #expect(try unindexed.component(checkedEdgeAt: 4) == nil)
        #expect(try indexed.component(checkedEdgeAt: 3) != indexed.component(checkedEdgeAt: 0))
        for bad in [-1, 5, 99] {
            #expect(throws: EdgeNotFound.self) { try indexed.component(checkedEdgeAt: bad) }
            #expect(throws: EdgeNotFound.self) { try unindexed.component(checkedEdgeAt: bad) }
        }
        for v in 0 ..< 5 {
            #expect(try Array(indexed.components(checkedContaining: v)) == Array(indexed.components(containing: v)))
            #expect(try Array(unindexed.components(checkedContaining: v)) == Array(unindexed.components(containing: v)))
        }
        #expect(try indexed.components(checkedContaining: 2).count == 2)
        #expect(try indexed.components(checkedContaining: 4).isEmpty)
        #expect(throws: VertexNotFound.self) { try indexed.components(checkedContaining: 5) }
        #expect(throws: VertexNotFound.self) { try unindexed.components(checkedContaining: -1) }

        let tree = list.blockCutTree(), plainTree = plain.blockCutTree()
        for v in 0 ..< 5 {
            #expect(try tree.node(checked: v) == tree.node(of: v))
            #expect(try plainTree.node(checked: v) == plainTree.node(of: v))
        }
        #expect(try tree.node(checked: 2) == .articulationPoint(0))
        #expect(try tree.node(checked: 0) == .block(indexed.component(ofEdgeAt: 0)!))
        #expect(try tree.node(checked: 4) == nil)
        #expect(throws: VertexNotFound.self) { try tree.node(checked: 5) }
        #expect(throws: VertexNotFound.self) { try plainTree.node(checked: 5) }
        #expect((try? tree.node(checked: 5)) == nil)
    }
}
