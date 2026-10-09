// Cases added after planting bugs: a forest with a parallel pair (caught only by skipping the edge
// a vertex was reached by, not its parent vertex), edges keeping the orientation they had in the
// source graph, and hashes that depend on the edges. Case IDs (TS-nnn) refer to the catalog; see
// README.md.

import AdjacencyListModule
import Foundation
import GraphProtocols
import Testing
import Trees

@Suite("Tree review cases")
struct TreeReviewTests {
    @Test("TS-1001 a parallel pair is a cycle in a forest too: Forest is nil, with spare vertices for the edge count")
    func forestParallelPair() {
        // 3 vertices, 2 edges (m <= n − 1), but 0–1 twice.
        #expect(Forest(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]) == nil)
        #expect(Forest(vertices: 0 ..< 4, edges: [UndirectedEdge(2, 3), UndirectedEdge(0, 1), UndirectedEdge(1, 0)]) == nil)
        #expect(Forest(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("c", "d"), UndirectedEdge("d", "c")]) == nil)
        #expect(Forest(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]) != nil)
    }

    @Test("TS-1002 edges keep their orientation from an UndirectedAdjacencyList, a conformer read through its rows")
    func orientationKept() throws {
        // Edges written with the larger vertex first, so the rows meet each from its other end.
        let list = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(1, 0), UndirectedEdge(4, 1), UndirectedEdge(3, 1), UndirectedEdge(2, 0)])
        let tree = try #require(Tree(list))
        let pairs = tree.edges.map { [$0.u, $0.v] }
        let expected = list.edges.map { [$0.u, $0.v] }
        #expect(pairs == expected)
        #expect(pairs == [[1, 0], [4, 1], [3, 1], [2, 0]])
        let forest = try #require(Forest(list))
        #expect(forest.edges.map { [$0.u, $0.v] } == expected)
        let rooted = try #require(RootedTree(list, root: 3))
        #expect(rooted.edges.map { [$0.u, $0.v] } == expected)
    }

    @Test("TS-1003 hashes depend on the edges: the 16 labeled trees on 4 vertices hash apart")
    func hashesSeeEdges() {
        var trees = Set<Tree<Int>>()
        var hashes = Set<Int>()
        // Every Prüfer code of length 2 on 0..<4: the 16 labeled trees (Cayley).
        for a in 0 ..< 4 {
            for b in 0 ..< 4 {
                let tree = Tree(pruferSequence: [a, b])!
                trees.insert(tree)
                hashes.insert(tree.hashValue)
            }
        }
        #expect(trees.count == 16)
        // Collisions are allowed, but a hash of the vertices alone would give one value for all 16.
        #expect(hashes.count > 12)
        var forestHashes = Set<Int>()
        for a in 0 ..< 4 {
            for b in 0 ..< 4 { forestHashes.insert(Forest(Tree(pruferSequence: [a, b])!).hashValue) }
        }
        #expect(forestHashes.count > 12)
        var rootedHashes = Set<Int>()
        let path = Tree(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])!
        let star = Tree(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])!
        for root in 0 ..< 4 {
            rootedHashes.insert(RootedTree(path, root: root).hashValue)
            rootedHashes.insert(RootedTree(star, root: root).hashValue)
        }
        #expect(rootedHashes.count > 6)
    }

    @Test("TS-1004 Int vertices from edges alone keep first-appearance order, dense or not")
    func intFirstAppearance() throws {
        // 0, 1, 2 appear in order: vertex k is the Int k.
        let dense = try #require(Tree(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)]))
        #expect(Array(dense.vertices) == [0, 1, 2, 3])
        // 0, 2, then 1: the order of first appearance, not of value.
        let skipped = try #require(Tree(edges: [UndirectedEdge(0, 2), UndirectedEdge(2, 1)]))
        #expect(Array(skipped.vertices) == [0, 2, 1])
        #expect(skipped.vertexIndex(of: 1) == 2)
        let negative = try #require(Tree(edges: [UndirectedEdge(-1, Int.max), UndirectedEdge(Int.max, Int.min)]))
        #expect(Array(negative.vertices) == [-1, Int.max, Int.min])
        #expect(negative.path(from: -1, to: Int.min).vertices == [-1, Int.max, Int.min])
        // Listed vertices 0..<3 then a new endpoint 3: still dense; then 5 before 4: not.
        let listed = try #require(Tree(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 5), UndirectedEdge(5, 4)]))
        #expect(Array(listed.vertices) == [0, 1, 2, 3, 5, 4])
        #expect(listed.vertexIndex(of: 4) == 5)
        let arborescence = try #require(Arborescence(edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 1)]))
        #expect(Array(arborescence.vertices) == [2, 0, 1])
        #expect(arborescence.root == 2)
    }

    @Test("TS-1005 small trees find vertices without a table, larger ones with one; both answer contains and lookups")
    func smallAndLargeLookup() throws {
        for count in [1, 2, 8, 9, 20] {
            let names = (0 ..< count).map { "v\($0)" }
            let edges = (1 ..< max(count, 1)).map { UndirectedEdge(names[$0 - 1], names[$0]) }
            let tree = try #require(count == 1 ? Tree(vertices: names, edges: []) : Tree(edges: edges))
            for (i, name) in names.enumerated() {
                #expect(tree.contains(name))
                #expect(tree.vertexIndex(of: name) == i)
            }
            #expect(!tree.contains("absent"))
            let rooted = RootedTree(tree, root: names[count - 1])
            #expect(rooted.depth(of: names[0]) == count - 1)
        }
    }

    @Test("TS-1006 a forest of isolated non-zero Int vertices: each tree is one vertex, built when read")
    func isolatedTrees() throws {
        let forest = try #require(Forest(vertices: [7, 3, 5], edges: []))
        let trees = Array(forest.trees)
        #expect(trees.map { Array($0.vertices) } == [[7], [3], [5]])
        #expect(trees.allSatisfy { $0.edgeCount == 0 && $0.vertexCount == 1 })
        #expect(trees[1].contains(3) && !trees[1].contains(7))
        #expect(RootedTree(trees[2], root: 5).preorder.map { $0 } == [5])
        #expect(forest.component(of: 5) == 2)
    }

    @Test("TS-1007 children(of:) with the parent's edge first, in the middle and last in the row")
    func childrenHoles() throws {
        // Vertex 1's row in position order: edges 0 (1–2), 1 (0–1), 2 (1–3).
        let tree = try #require(Tree(vertices: 0 ..< 4, edges: [UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(1, 3)]))
        #expect(Array(RootedTree(tree, root: 0).children(of: 1)) == [2, 3])
        #expect(Array(RootedTree(tree, root: 2).children(of: 1)) == [0, 3])
        #expect(Array(RootedTree(tree, root: 3).children(of: 1)) == [2, 0])
        #expect(Array(RootedTree(tree, root: 1).children(of: 1)) == [2, 0, 3])
        let children = RootedTree(tree, root: 2).children(of: 1)
        #expect(children[children.startIndex] == 0)
        #expect(tree.neighbors(of: 1).first == 2)
        #expect(Array(tree.neighbors(of: 3)) == [1])
    }

    @Test("TS-1008 parent arrays: a 2-cycle away from the root and the empty array are not trees")
    func parentArrays() {
        #expect(RootedTree(parents: [nil, 2, 1]) == nil)
        #expect(Arborescence(parents: [nil, 2, 1]) == nil)
        #expect(RootedTree(parents: []) == nil)
        #expect(RootedTree(parents: [nil, 0, 0, 1]) != nil)
    }

    @Test("TS-1009 decoding a rooted tree without a root, or with one out of range, throws")
    func rootedDecoding() throws {
        let decoder = JSONDecoder()
        let missing = Data(#"{"vertices":[0,1],"edges":[0,1]}"#.utf8)
        #expect(throws: DecodingError.self) { try decoder.decode(RootedTree<Int>.self, from: missing) }
        let outOfRange = Data(#"{"vertices":[0,1],"edges":[0,1],"root":2}"#.utf8)
        #expect(throws: DecodingError.self) { try decoder.decode(RootedTree<Int>.self, from: outOfRange) }
        let repeated = Data(#"{"vertices":["a","a"],"edges":[0,1]}"#.utf8)
        #expect(throws: DecodingError.self) { try decoder.decode(Arborescence<String>.self, from: repeated) }
        let tree = RootedTree(Tree(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])!, root: 2)
        let decoded = try decoder.decode(RootedTree<Int>.self, from: JSONEncoder().encode(tree))
        #expect(decoded == tree && decoded.root == 2)
    }

    @Test("TS-1010 equal values hash equal under shuffled vertices and reversed orientation")
    func equalHashes() throws {
        let a = try #require(Tree(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 3)]))
        let b = try #require(Tree(vertices: [3, 2, 1, 0], edges: [UndirectedEdge(3, 1), UndirectedEdge(2, 1), UndirectedEdge(1, 0)]))
        #expect(a == b && a.hashValue == b.hashValue)
        #expect(Forest(a) == Forest(b) && Forest(a).hashValue == Forest(b).hashValue)
        let ra = RootedTree(a, root: 1), rb = RootedTree(b, root: 1)
        #expect(ra == rb && ra.hashValue == rb.hashValue)
        let arcs = try #require(Arborescence(edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 1, to: 3)]))
        #expect(Arborescence(ra) == arcs && Arborescence(ra).hashValue == arcs.hashValue)
    }
}
