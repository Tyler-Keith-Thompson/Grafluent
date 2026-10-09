// §F: `path(from:to:)`, the unique path with its edge positions, as a Walks `Path<Vertex, Int>`:
// up from the source to the meeting vertex, then down to the target. It does not depend on the
// root (TS-304 = TS-305); `Tree`, `RootedTree` and `Forest` answer it (`Forest` with nil across
// trees, TS-312); on an `Arborescence` it follows arcs, nil unless the source is the target or an
// ancestor of it (TS-307 – TS-310). The trivial path is `[v]`. A vertex that is not in the tree
// traps (TS-315, in TreePreconditionTests.swift). Sources are written on the reference conformers
// as the catalog writes them. Expected values come from the catalog's reference (`ref.py`,
// cross-checked against NetworkX's `shortest_path`). Case IDs (TS-nnn) refer to the catalog; see
// README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees
import Walks

@Suite("Tree paths")
struct TreePathTests {
    @Test("TS-300 Tree(E1).path(from: 6, to: 5) is [6, 4, 1, 0, 2, 5] / [5, 3, 0, 1, 4]")
    func pathAcrossTheRoot() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.path(from: 6, to: 5)
        #expect(path.vertices == [6, 4, 1, 0, 2, 5])
        #expect(path.edges == [5, 3, 0, 1, 4])
        #expect(path.source == 6)
        #expect(path.target == 5)
        #expect(path.length == 5)
        // A path of the graph itself, edge positions included.
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
    }

    @Test("TS-301 Tree(E1).path(from: 5, to: 6) is [5, 2, 0, 1, 4, 6] / [4, 1, 0, 3, 5]: the reverse of TS-300")
    func reversePath() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.path(from: 5, to: 6)
        #expect(path.vertices == [5, 2, 0, 1, 4, 6])
        #expect(path.edges == [4, 1, 0, 3, 5])
        #expect(path == tree.path(from: 6, to: 5).reversed())
    }

    @Test("TS-302 Tree(E1).path(from: 3, to: 3) is [3] / []: trivial")
    func trivialPath() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.path(from: 3, to: 3)
        #expect(path.vertices == [3])
        #expect(path.edges.isEmpty)
        #expect(path.isTrivial)
        #expect(path == Path(vertex: 3))
    }

    @Test("TS-303 Tree(E1).path(from: 3, to: 4) is [3, 1, 4] / [2, 3]: siblings")
    func siblings() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.path(from: 3, to: 4)
        #expect(path.vertices == [3, 1, 4])
        #expect(path.edges == [2, 3])
    }

    @Test("TS-304 RootedTree(E1, root: 6).path(from: 3, to: 5) is [3, 1, 0, 2, 5] / [2, 0, 1, 4]: whatever the root")
    func rootedPathIgnoresRoot() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 6))
        let path = rooted.path(from: 3, to: 5)
        #expect(path.vertices == [3, 1, 0, 2, 5])
        #expect(path.edges == [2, 0, 1, 4])
    }

    @Test("TS-305 Tree(E1).path(from: 3, to: 5) is [3, 1, 0, 2, 5] / [2, 0, 1, 4]")
    func unrootedPath() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.path(from: 3, to: 5)
        #expect(path.vertices == [3, 1, 0, 2, 5])
        #expect(path.edges == [2, 0, 1, 4])
        // At every root, the same path.
        for root in 0 ... 6 {
            #expect(RootedTree(tree, root: root).path(from: 3, to: 5) == path, "root \(root)")
        }
    }

    @Test("TS-306 RootedTree(E1, root: 0).path(from: 0, to: 6) is [0, 1, 4, 6] / [0, 3, 5]")
    func rootedPathDown() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let path = rooted.path(from: 0, to: 6)
        #expect(path.vertices == [0, 1, 4, 6])
        #expect(path.edges == [0, 3, 5])
    }

    @Test("TS-307 Arborescence(E1).path(from: 0, to: 6) is [0, 1, 4, 6] / [0, 3, 5]: down the tree")
    func arborescencePathDown() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let path = try #require(arborescence.path(from: 0, to: 6))
        #expect(path.vertices == [0, 1, 4, 6])
        #expect(path.edges == [0, 3, 5])
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
    }

    @Test("TS-308 Arborescence(E1).path(from: 6, to: 0) is nil: against the arcs")
    func arborescencePathUpIsNil() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.path(from: 6, to: 0) == nil)
    }

    @Test("TS-309 Arborescence(E1).path(from: 3, to: 5) is nil: no directed path")
    func arborescencePathAcrossIsNil() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(arborescence.path(from: 3, to: 5) == nil)
    }

    @Test("TS-310 Arborescence(E1).path(from: 4, to: 4) is [4] / []")
    func arborescenceTrivialPath() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let path = try #require(arborescence.path(from: 4, to: 4))
        #expect(path.vertices == [4])
        #expect(path.edges.isEmpty)
    }

    @Test("TS-311 Forest(g).path(from: 2, to: 4) is [2, 3, 4] / [1, 2]")
    func forestPath() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        let path = try #require(forest.path(from: 2, to: 4))
        #expect(path.vertices == [2, 3, 4])
        #expect(path.edges == [1, 2])
    }

    @Test("TS-312 Forest(g).path(from: 0, to: 4) is nil: different trees")
    func forestPathAcrossTrees() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(forest.path(from: 0, to: 4) == nil)
        let trivial = try #require(forest.path(from: 0, to: 0))
        #expect(trivial.vertices == [0])
    }

    @Test("TS-313 Tree(E2).path(from: 4, to: 3) is [4, 2, 1, 3] / [0, 2, 3]")
    func pathE2() throws {
        // U: 4-2, 0-2, 2-1, 1-3
        let pairs: [(Int, Int)] = [(4, 2), (0, 2), (2, 1), (1, 3)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.path(from: 4, to: 3)
        #expect(path.vertices == [4, 2, 1, 3])
        #expect(path.edges == [0, 2, 3])
    }

    @Test("TS-314 Tree(g).path(from: d, to: c) is [d, b, c] / [2, 1]: String vertices")
    func stringPath() throws {
        // U: a-b, b-c, b-d
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = tree.path(from: "d", to: "c")
        #expect(path.vertices == ["d", "b", "c"])
        #expect(path.edges == [2, 1])
    }

    @Test("Every pair of E1: the path is a Path of the tree, its length the distance, its reverse the other way")
    func everyPair() throws {
        // Distances by breadth-first search over the tree's own rows, written here.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let forest = Forest(tree)
        let arborescence = Arborescence(RootedTree(tree, root: 0))
        for a in 0 ... 6 {
            var distance = [a: 0]
            var queue = [a]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in tree.neighbors(of: v) where distance[w] == nil {
                    distance[w] = distance[v]! + 1
                    queue.append(w)
                }
            }
            for b in 0 ... 6 {
                let path = tree.path(from: a, to: b)
                #expect(path.source == a && path.target == b, "\(a) to \(b)")
                #expect(path.length == distance[b], "\(a) to \(b)")
                #expect(Path(vertices: path.vertices, edges: path.edges, in: tree) != nil, "\(a) to \(b)")
                #expect(tree.path(from: b, to: a) == path.reversed(), "\(a) to \(b)")
                #expect(forest.path(from: a, to: b) == path, "\(a) to \(b)")
                let directed = arborescence.path(from: a, to: b)
                let downward = a == b || arborescence.isAncestor(a, of: b)
                #expect((directed != nil) == downward, "\(a) to \(b)")
                if let directed { #expect(directed == path, "\(a) to \(b)") }
            }
        }
    }
}
