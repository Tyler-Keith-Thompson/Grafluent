// The index-space hooks of the tree types (`degree(ofIndex:)` and `endpointIndices(ofEdgeAt:)` on
// `Tree`, `Forest` and `RootedTree`; `outDegree(ofIndex:)`, `inDegree(ofIndex:)`,
// `sourceIndex(ofEdgeAt:)` and `targetIndex(ofEdgeAt:)` on `Arborescence`) read the layout without
// a lookup. Checked against the vertex-space members, with labels that are not their indices.

import AdjacencyListModule
import GraphProtocols
import Testing
import Trees

@Suite("Trees index-space hooks")
struct TreeIndexHookTests {
    @Test("Tree: degrees and edge ends by index agree with the members")
    func tree() {
        let tree = Tree<String>(
            vertices: ["m", "c", "x", "a", "q", "b"],
            edges: [UndirectedEdge("x", "m"), UndirectedEdge("m", "c"), UndirectedEdge("a", "m"), UndirectedEdge("q", "a"), UndirectedEdge("b", "q")])!
        let n = tree.vertexIndexBound!
        #expect(n == 6)
        for i in 0 ..< n {
            let v = tree.vertex(atIndex: i)
            #expect(tree.vertexIndex(of: v) == i)
            #expect(tree.degree(ofIndex: i) == tree.degree(of: v), "degree at \(i)")
        }
        var count = 0
        for p in tree.edges.indices {
            let edge = tree.edges[p]
            let ends = tree.endpointIndices(ofEdgeAt: p)
            #expect(ends.u == tree.vertexIndex(of: edge.u))
            #expect(ends.v == tree.vertexIndex(of: edge.v))
            count += 1
        }
        #expect(count == 5)
        #expect(tree.degree(ofIndex: tree.vertexIndex(of: "m")) == 3)
    }

    @Test("Forest: degrees and edge ends by index agree with the members")
    func forest() {
        let graph = UndirectedAdjacencyList<String>(
            vertices: ["m", "k", "c", "z", "x", "e", "f", "lone"],
            edges: [
                UndirectedEdge("x", "m"), UndirectedEdge("m", "c"), UndirectedEdge("z", "k"), UndirectedEdge("f", "z"),
                UndirectedEdge("e", "z"),
            ])
        let forest = Forest<String>(graph)!
        let n = forest.vertexIndexBound!
        #expect(n == 8)
        for i in 0 ..< n {
            let v = forest.vertex(atIndex: i)
            #expect(forest.vertexIndex(of: v) == i)
            #expect(forest.degree(ofIndex: i) == forest.degree(of: v), "degree at \(i)")
        }
        var count = 0
        for p in forest.edges.indices {
            let edge = forest.edges[p]
            let ends = forest.endpointIndices(ofEdgeAt: p)
            #expect(ends.u == forest.vertexIndex(of: edge.u))
            #expect(ends.v == forest.vertexIndex(of: edge.v))
            count += 1
        }
        #expect(count == 5)
        #expect(forest.degree(ofIndex: forest.vertexIndex(of: "z")) == 3)
        #expect(forest.degree(ofIndex: forest.vertexIndex(of: "lone")) == 0)
    }

    @Test("RootedTree: degrees and edge ends by index agree with the members")
    func rootedTree() {
        let tree = Tree<String>(
            vertices: ["m", "c", "x", "a", "q", "b"],
            edges: [UndirectedEdge("x", "m"), UndirectedEdge("m", "c"), UndirectedEdge("a", "m"), UndirectedEdge("q", "a"), UndirectedEdge("b", "q")])!
        let rooted = RootedTree(tree, root: "q")
        let n = rooted.vertexIndexBound!
        for i in 0 ..< n {
            let v = rooted.vertex(atIndex: i)
            #expect(rooted.vertexIndex(of: v) == i)
            #expect(rooted.degree(ofIndex: i) == rooted.degree(of: v), "degree at \(i)")
        }
        var count = 0
        for p in rooted.edges.indices {
            let edge = rooted.edges[p]
            let ends = rooted.endpointIndices(ofEdgeAt: p)
            #expect(ends.u == rooted.vertexIndex(of: edge.u))
            #expect(ends.v == rooted.vertexIndex(of: edge.v))
            count += 1
        }
        #expect(count == 5)
    }

    @Test("Arborescence: degrees and edge ends by index agree with the members")
    func arborescence() {
        let arborescence = Arborescence<String>(
            vertices: ["m", "c", "x", "a", "q", "b"],
            edges: [
                DirectedEdge(from: "q", to: "a"), DirectedEdge(from: "a", to: "m"), DirectedEdge(from: "m", to: "x"),
                DirectedEdge(from: "m", to: "c"), DirectedEdge(from: "q", to: "b"),
            ])!
        let n = arborescence.vertexIndexBound!
        #expect(n == 6)
        for i in 0 ..< n {
            let v = arborescence.vertex(atIndex: i)
            #expect(arborescence.vertexIndex(of: v) == i)
            #expect(arborescence.outDegree(ofIndex: i) == arborescence.outDegree(of: v), "out-degree at \(i)")
            #expect(arborescence.inDegree(ofIndex: i) == arborescence.inDegree(of: v), "in-degree at \(i)")
        }
        var count = 0
        for p in arborescence.edges.indices {
            #expect(arborescence.sourceIndex(ofEdgeAt: p) == arborescence.vertexIndex(of: arborescence.source(ofEdgeAt: p)))
            #expect(arborescence.targetIndex(ofEdgeAt: p) == arborescence.vertexIndex(of: arborescence.target(ofEdgeAt: p)))
            count += 1
        }
        #expect(count == 5)
        #expect(arborescence.outDegree(ofIndex: arborescence.vertexIndex(of: "q")) == 2)
        #expect(arborescence.inDegree(ofIndex: arborescence.vertexIndex(of: "q")) == 0)
    }
}
