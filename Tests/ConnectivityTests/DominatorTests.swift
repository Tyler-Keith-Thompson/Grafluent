// Dominator trees, their queries, dominance frontiers and post-dominator trees. Immediate
// dominators are unique, so they are exact on every representation; `children(of:)` and
// frontiers are in `vertices` order, so they are exact on the matrix, CSR and the Multigraph and
// compared as sets on adjacency lists. Expected values come from the catalog's reference, where
// brute force, Cooper–Harvey–Kennedy and Lengauer–Tarjan agree with NetworkX, and Boost's own
// `correctIdoms`. Case IDs (CN-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Immediate dominators")
struct ImmediateDominatorTests {
    @Test("CN-77 NetworkX's docstring graph")
    func networkXDocstring() {
        let edges = [(1, 2), (1, 3), (2, 5), (3, 4), (4, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected = [2: 1, 3: 1, 4: 3, 5: 1]
        let tree = Multigraph(vertices: 1 ... 5, edges: edges).dominatorTree(root: 1)
        #expect(tree.root == 1)
        for v in 1 ... 5 { #expect(tree.immediateDominator(of: v) == expected[v], "\(v)") }
        let list = AdjacencyList(vertices: 1 ... 5, edges: edges).dominatorTree(root: 1)
        for v in 1 ... 5 { #expect(list.immediateDominator(of: v) == expected[v], "\(v)") }
    }

    @Test("CN-78 Cooper et al.'s irreducible graphs (figures 2 and 4)")
    func irreducible() {
        let figure2 = [(1, 2), (2, 1), (3, 2), (4, 1), (5, 3), (5, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let figure4 = [(1, 2), (2, 1), (2, 3), (3, 2), (4, 2), (4, 3), (5, 1), (6, 4), (6, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let two = Multigraph(vertices: 1 ... 5, edges: figure2).dominatorTree(root: 5)
        let twoList = AdjacencyList(vertices: 1 ... 5, edges: figure2).dominatorTree(root: 5)
        for v in 1 ... 4 {
            #expect(two.immediateDominator(of: v) == 5, "\(v)")
            #expect(twoList.immediateDominator(of: v) == 5, "\(v)")
        }
        let four = Multigraph(vertices: 1 ... 6, edges: figure4).dominatorTree(root: 6)
        let fourList = AdjacencyList(vertices: 1 ... 6, edges: figure4).dominatorTree(root: 6)
        for v in 1 ... 5 {
            #expect(four.immediateDominator(of: v) == 6, "\(v)")
            #expect(fourList.immediateDominator(of: v) == 6, "\(v)")
        }
    }

    @Test("CN-79 Wikipedia's Domrel graph")
    func domrel() {
        let edges = [(1, 2), (2, 3), (2, 4), (2, 6), (3, 5), (4, 5), (5, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected = [2: 1, 3: 2, 4: 2, 5: 2, 6: 2]
        let multigraph = Multigraph(vertices: 1 ... 6, edges: edges).dominatorTree(root: 1)
        let list = AdjacencyList(vertices: 1 ... 6, edges: edges).dominatorTree(root: 1)
        for v in 1 ... 6 {
            #expect(multigraph.immediateDominator(of: v) == expected[v], "\(v)")
            #expect(list.immediateDominator(of: v) == expected[v], "\(v)")
        }
    }

    @Test("CN-80 Boost's documentation figure 1 (Boost test set 3)")
    func boostFigure1() {
        let edges = [(0, 1), (1, 2), (1, 3), (2, 7), (3, 4), (4, 5), (4, 6), (5, 7), (6, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected = [1: 0, 2: 1, 3: 1, 4: 3, 5: 4, 6: 4, 7: 1]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dominatorTree(root: 0)
            for v in 0 ..< 8 { #expect(tree.immediateDominator(of: v) == expected[v], "\(v)") }
        }
        check(AdjacencyMatrix(vertexCount: 8, edges: edges))
        check(CompressedSparseRow(vertexCount: 8, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 8, edges: edges))
    }

    @Test("CN-81 Boost set 0: Tarjan's paper")
    func boostSet0() {
        let edges = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 1), (2, 4), (2, 5), (3, 6), (3, 7), (4, 12), (5, 8), (6, 9), (7, 9), (7, 10), (8, 5), (8, 11), (9, 11), (10, 9), (11, 0), (11, 9), (12, 8)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let idoms = [0, 0, 0, 0, 0, 3, 3, 0, 0, 7, 0, 4]
        let children = [0: [1, 2, 3, 4, 5, 8, 9, 11], 3: [6, 7], 4: [12], 7: [10]]
        func check<G: DirectedGraph<Int>>(_ g: G, exactChildren: Bool) {
            let tree = g.dominatorTree(root: 0)
            #expect(tree.immediateDominator(of: 0) == nil)
            for v in 1 ... 12 { #expect(tree.immediateDominator(of: v) == idoms[v - 1], "\(v)") }
            for v in 0 ... 12 {
                if exactChildren {
                    #expect(Array(tree.children(of: v)) == children[v, default: []], "\(v)")
                } else {
                    #expect(Set(tree.children(of: v)) == Set(children[v, default: []]), "\(v)")
                }
            }
        }
        check(AdjacencyMatrix(vertexCount: 13, edges: edges), exactChildren: true)
        check(CompressedSparseRow(vertexCount: 13, edges: edges), exactChildren: true)
        check(AdjacencyList(vertices: 0 ..< 13, edges: edges), exactChildren: false)
    }

    @Test("CN-82 Boost set 1: Appel figure 19.4")
    func boostSet1() {
        let edges = [(0, 1), (1, 2), (1, 3), (2, 4), (2, 5), (4, 6), (5, 6), (6, 1)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let idoms = [0, 1, 1, 2, 2, 2]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dominatorTree(root: 0)
            for v in 1 ... 6 { #expect(tree.immediateDominator(of: v) == idoms[v - 1], "\(v)") }
        }
        check(AdjacencyMatrix(vertexCount: 7, edges: edges))
        check(CompressedSparseRow(vertexCount: 7, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 7, edges: edges))
    }

    @Test("CN-83 Boost set 2: Appel figure 19.8")
    func boostSet2() {
        let edges = [(0, 1), (0, 2), (1, 3), (1, 6), (2, 4), (2, 7), (3, 5), (3, 6), (4, 7), (4, 2), (5, 8), (5, 10), (6, 9), (7, 12), (8, 11), (9, 8), (10, 11), (11, 1), (11, 12)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let idoms = [0, 0, 1, 2, 3, 1, 2, 1, 6, 5, 1, 0]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dominatorTree(root: 0)
            for v in 1 ... 12 { #expect(tree.immediateDominator(of: v) == idoms[v - 1], "\(v)") }
        }
        check(AdjacencyMatrix(vertexCount: 13, edges: edges))
        check(CompressedSparseRow(vertexCount: 13, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 13, edges: edges))
    }

    @Test("CN-84 Boost set 4: Muchnick figure 8.21")
    func boostSet4() {
        let edges = [(0, 1), (1, 2), (2, 3), (2, 4), (3, 2), (4, 5), (4, 6), (5, 7), (6, 7)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let idoms = [0, 1, 2, 2, 4, 4, 4]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dominatorTree(root: 0)
            for v in 1 ... 7 { #expect(tree.immediateDominator(of: v) == idoms[v - 1], "\(v)") }
        }
        check(AdjacencyMatrix(vertexCount: 8, edges: edges))
        check(CompressedSparseRow(vertexCount: 8, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 8, edges: edges))
    }

    @Test("CN-85 Boost set 5: Muchnick figure 8.18, with an unreachable predecessor")
    func boostSet5() {
        // 5→7, and 5 is unreachable from 0.
        let edges = [(0, 1), (0, 2), (1, 6), (2, 3), (2, 4), (3, 7), (5, 7), (6, 7)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected = [1: 0, 2: 0, 3: 2, 4: 2, 6: 1, 7: 0]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dominatorTree(root: 0)
            for v in 0 ..< 8 { #expect(tree.immediateDominator(of: v) == expected[v], "\(v)") }
            #expect(tree.immediateDominator(of: 5) == nil)
        }
        check(AdjacencyMatrix(vertexCount: 8, edges: edges))
        check(CompressedSparseRow(vertexCount: 8, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 8, edges: edges))
    }

    @Test("CN-86 Boost set 6: Cytron's paper figure 9")
    func boostSet6() {
        let edges = [(0, 1), (0, 13), (1, 2), (2, 3), (2, 7), (3, 4), (3, 5), (4, 6), (5, 6), (6, 8), (7, 8), (8, 9), (9, 10), (9, 11), (10, 11), (11, 9), (11, 12), (12, 2), (12, 13)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let idoms = [0, 1, 2, 3, 3, 3, 2, 2, 8, 9, 9, 11, 0]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dominatorTree(root: 0)
            for v in 1 ... 13 { #expect(tree.immediateDominator(of: v) == idoms[v - 1], "\(v)") }
        }
        check(AdjacencyMatrix(vertexCount: 14, edges: edges))
        check(CompressedSparseRow(vertexCount: 14, edges: edges))
        check(AdjacencyList(vertices: 0 ..< 14, edges: edges))
    }

    @Test("CN-87 Lengauer and Tarjan's figure 1 (petgraph), with an isolated vertex")
    func lengauerTarjanFigure1() {
        let names = ["r", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"]
        let pairs = [("r", "a"), ("r", "b"), ("r", "c"), ("a", "d"), ("b", "a"), ("b", "d"), ("b", "e"), ("c", "f"), ("c", "g"), ("d", "l"), ("e", "h"), ("f", "i"), ("g", "i"), ("g", "j"), ("h", "e"), ("h", "k"), ("i", "k"), ("j", "i"), ("k", "r"), ("k", "i"), ("l", "h")]
        let edges = pairs.map { DirectedEdge(from: $0.0, to: $0.1) }
        var expected: [String: String] = [:]
        for v in ["a", "b", "c", "d", "e", "h", "i", "k"] { expected[v] = "r" }
        expected["f"] = "c"
        expected["g"] = "c"
        expected["j"] = "g"
        expected["l"] = "d"
        let multigraph = Multigraph(vertices: names + ["z"], edges: edges).dominatorTree(root: "r")
        let list = AdjacencyList(vertices: names + ["z"], edges: edges).dominatorTree(root: "r")
        for v in names + ["z"] {
            #expect(multigraph.immediateDominator(of: v) == expected[v], "\(v)")
            #expect(list.immediateDominator(of: v) == expected[v], "\(v)")
        }
        #expect(multigraph.immediateDominator(of: "z") == nil)
    }

    @Test("CN-88 paths and cycles, and a path from its second vertex")
    func pathsAndCycles() {
        for n in [5, 10, 20] {
            let path = (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) }
            let cycle = (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) }
            for edges in [path, cycle] {
                let matrix = AdjacencyMatrix(vertexCount: n, edges: edges).dominatorTree(root: 0)
                let sparse = CompressedSparseRow(vertexCount: n, edges: edges).dominatorTree(root: 0)
                let list = AdjacencyList(vertices: 0 ..< n, edges: edges).dominatorTree(root: 0)
                for v in 1 ..< n {
                    #expect(matrix.immediateDominator(of: v) == v - 1)
                    #expect(sparse.immediateDominator(of: v) == v - 1)
                    #expect(list.immediateDominator(of: v) == v - 1)
                }
            }
        }
        let path = (0 ..< 4).map { DirectedEdge(from: $0, to: $0 + 1) }
        let expected = [2: 1, 3: 2, 4: 3]
        let tree = CompressedSparseRow(vertexCount: 5, edges: path).dominatorTree(root: 1)
        for v in 0 ..< 5 { #expect(tree.immediateDominator(of: v) == expected[v], "\(v)") }
        #expect(tree.dominators(of: 0) == nil)
    }

    @Test("CN-89 a singleton, with and without a self-loop", .tags(.selfLoops))
    func singleton() {
        for fixture in [DirectedFixture<Int>.trivial, .singleSelfLoop] {
            let tree = CompressedSparseRow(vertexCount: 1, edges: fixture.edges).dominatorTree(root: 0)
            #expect(tree.immediateDominator(of: 0) == nil)
            #expect(tree.dominators(of: 0) == [0])
            let matrix = AdjacencyMatrix(vertexCount: 1, edges: fixture.edges).dominatorTree(root: 0)
            #expect(matrix.immediateDominator(of: 0) == nil)
            #expect(matrix.dominators(of: 0) == [0])
        }
    }

    @Test("CN-90 NetworkX's String graphs")
    func networkXStrings() {
        let discard = [("b0", "b1"), ("b1", "b2"), ("b2", "b3"), ("b3", "b1"), ("b1", "b5"), ("b5", "b6"), ("b5", "b8"), ("b6", "b7"), ("b8", "b7"), ("b7", "b3"), ("b3", "b4")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let discardExpected = ["b1": "b0", "b2": "b1", "b3": "b1", "b4": "b3", "b5": "b1", "b6": "b5", "b7": "b5", "b8": "b5"]
        let discardTree = Multigraph(edges: discard).dominatorTree(root: "b0")
        for v in Multigraph(edges: discard).vertices { #expect(discardTree.immediateDominator(of: v) == discardExpected[v], "\(v)") }
        let loop = [("a", "b"), ("b", "c"), ("b", "a")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let loopTree = Multigraph(edges: loop).dominatorTree(root: "a")
        #expect(loopTree.immediateDominator(of: "a") == nil)
        #expect(loopTree.immediateDominator(of: "b") == "a")
        #expect(loopTree.immediateDominator(of: "c") == "b")
        let missing = [("entry_1", "b1"), ("b1", "b2"), ("b2", "b3"), ("b3", "exit"), ("entry_2", "b3")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let missingExpected = ["b1": "entry_1", "b2": "b1", "b3": "b2", "exit": "b3"]
        let missingTree = Multigraph(edges: missing).dominatorTree(root: "entry_1")
        for v in Multigraph(edges: missing).vertices { #expect(missingTree.immediateDominator(of: v) == missingExpected[v], "\(v)") }
        #expect(missingTree.dominators(of: "entry_2") == nil)
        let listTree = AdjacencyList(edges: missing).dominatorTree(root: "entry_1")
        for v in Multigraph(edges: missing).vertices { #expect(listTree.immediateDominator(of: v) == missingExpected[v], "\(v)") }
    }

    @Test("CN-91 immediate dominators of the fixtures", .tags(.fixture))
    func fixtures() {
        let cases: [(DirectedFixture<Int>, Int, [Int: Int])] = [
            (.house, 5, [0: 3, 1: 3, 2: 3, 3: 5, 4: 3]),
            (.scc9, 1, [0: 6, 2: 8, 3: 0, 4: 7, 5: 7, 6: 8, 7: 1, 8: 5]),
            (.scc9, 0, [3: 0, 6: 3]),
            (.petgraphEdgesDirected, 0, [1: 0, 2: 0, 3: 0, 4: 2, 5: 0]),
            (.boostExample, 1, [0: 1, 2: 1, 5: 1]),
            (.igraphReverseEdges, 0, [1: 0, 2: 1, 3: 2, 4: 1]),
            (.boostWebGraph, 0, [1: 0, 2: 0, 3: 0, 4: 3, 5: 0]),
            (.neo4jDirected, 0, [1: 0, 2: 0, 3: 1, 4: 0]),
            (.pathWithChord, 0, [1: 0, 2: 1, 3: 1, 4: 3, 5: 4]),
            (.cube, 0, Dictionary(uniqueKeysWithValues: (1 ..< 8).map { ($0, 0) })),
            (.petersen, 0, Dictionary(uniqueKeysWithValues: (1 ..< 10).map { ($0, 0) })),
            (.completeDirected3, 0, [1: 0, 2: 0]),
            (.jgraphtMatrixCSV, 4, [0: 4, 1: 4, 2: 4, 3: 4]),
        ]
        for (fixture, root, expected) in cases {
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).dominatorTree(root: root)
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).dominatorTree(root: root)
            let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges).dominatorTree(root: root)
            for v in 0 ..< fixture.vertexCount {
                #expect(matrix.immediateDominator(of: v) == expected[v], "\(fixture.name) from \(root): \(v)")
                #expect(sparse.immediateDominator(of: v) == expected[v], "\(fixture.name) from \(root): \(v)")
                #expect(list.immediateDominator(of: v) == expected[v], "\(fixture.name) from \(root): \(v)")
            }
        }
    }

    @Test("CN-92 boost24 from 7")
    func boost24() {
        let fixture = DirectedFixture<Int>.boost24
        let expected = [0: 7, 1: 7, 2: 1, 3: 6, 4: 7, 5: 7, 6: 7, 8: 7, 9: 18, 10: 7, 11: 7, 12: 7, 13: 7, 14: 5, 15: 7, 16: 23, 17: 7, 18: 7, 19: 7, 20: 17, 21: 22, 22: 7, 23: 7]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            let tree = g.dominatorTree(root: 7)
            for v in 0 ..< 24 { #expect(tree.immediateDominator(of: v) == expected[v], "\(v)") }
        }
        check(AdjacencyMatrix(vertexCount: 24, edges: fixture.edges))
        check(CompressedSparseRow(vertexCount: 24, edges: fixture.edges))
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(Multigraph(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("CN-93 immediate dominators of the Multigraph fixtures", .tags(.fixture))
    func multigraphFixtures() {
        let dag = DirectedFixture<String>.petgraphDAG
        let dagTree = Multigraph(vertices: dag.vertices, edges: dag.edges).dominatorTree(root: "a")
        let dagExpected = ["b": "a", "d": "a", "c": "b", "e": "a", "f": "d", "g": "a"]
        for v in ["a", "b", "c", "d", "e", "f", "g"] { #expect(dagTree.immediateDominator(of: v) == dagExpected[v], "\(v)") }
        let abcd = DirectedFixture<String>.networkXABCD
        let abcdTree = Multigraph(vertices: abcd.vertices, edges: abcd.edges).dominatorTree(root: "A")
        let abcdExpected = ["B": "A", "C": "A", "D": "A"]
        for v in ["A", "B", "C", "D", "G", "J", "K"] { #expect(abcdTree.immediateDominator(of: v) == abcdExpected[v], "\(v)") }
        for v in ["G", "J", "K"] { #expect(abcdTree.dominators(of: v) == nil, "\(v)") }
        let loops = DirectedFixture<Int>.selfLoopsAndDuplicates
        let graph = Multigraph(vertices: loops.vertices, edges: loops.edges)
        let fromOne = graph.dominatorTree(root: 1)
        let fromOneExpected = [2: 1, 3: 2, 4: 2]
        for v in 1 ... 5 { #expect(fromOne.immediateDominator(of: v) == fromOneExpected[v], "\(v)") }
        #expect(fromOne.dominators(of: 5) == nil)
        let fromFive = graph.dominatorTree(root: 5)
        let fromFiveExpected = [2: 5, 3: 2, 4: 2]
        for v in 1 ... 5 { #expect(fromFive.immediateDominator(of: v) == fromFiveExpected[v], "\(v)") }
        #expect(fromFive.dominators(of: 1) == nil)
    }
}

@Suite("Dominator tree queries")
struct DominatorTreeQueryTests {
    @Test("CN-94 neither the root nor an unreachable vertex has an immediate dominator")
    func noImmediateDominator() {
        let set0 = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 1), (2, 4), (2, 5), (3, 6), (3, 7), (4, 12), (5, 8), (6, 9), (7, 9), (7, 10), (8, 5), (8, 11), (9, 11), (10, 9), (11, 0), (11, 9), (12, 8)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let tree = CompressedSparseRow(vertexCount: 13, edges: set0).dominatorTree(root: 0)
        #expect(tree.root == 0)
        #expect(tree.immediateDominator(of: 0) == nil)
        let set5 = [(0, 1), (0, 2), (1, 6), (2, 3), (2, 4), (3, 7), (5, 7), (6, 7)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let five = CompressedSparseRow(vertexCount: 8, edges: set5).dominatorTree(root: 0)
        #expect(five.immediateDominator(of: 5) == nil)
        #expect(AdjacencyList(vertices: 0 ..< 8, edges: set5).dominatorTree(root: 0).immediateDominator(of: 5) == nil)
    }

    @Test("CN-95 dominators(of:) and strictDominators(of:)")
    func dominatorChains() {
        let set0 = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 1), (2, 4), (2, 5), (3, 6), (3, 7), (4, 12), (5, 8), (6, 9), (7, 9), (7, 10), (8, 5), (8, 11), (9, 11), (10, 9), (11, 0), (11, 9), (12, 8)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let tree = AdjacencyMatrix(vertexCount: 13, edges: set0).dominatorTree(root: 0)
        #expect(tree.dominators(of: 10) == [10, 7, 3, 0])
        #expect(tree.strictDominators(of: 10) == [7, 3, 0])
        #expect(tree.dominators(of: 12) == [12, 4, 0])
        #expect(tree.dominators(of: 0) == [0])
        #expect(tree.strictDominators(of: 0) == [])
        let list = AdjacencyList(vertices: 0 ..< 13, edges: set0).dominatorTree(root: 0)
        #expect(list.dominators(of: 10) == [10, 7, 3, 0])
        #expect(list.strictDominators(of: 12) == [4, 0])
        let set5 = [(0, 1), (0, 2), (1, 6), (2, 3), (2, 4), (3, 7), (5, 7), (6, 7)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let five = CompressedSparseRow(vertexCount: 8, edges: set5).dominatorTree(root: 0)
        #expect(five.dominators(of: 5) == nil)
        #expect(five.strictDominators(of: 5) == nil)
        // petgraph's test_iter_dominators: idoms {2: 1, 1: 0}.
        let path = CompressedSparseRow(vertexCount: 3, edges: DirectedFixture<Int>.directedPath3.edges).dominatorTree(root: 0)
        #expect(path.dominators(of: 2) == [2, 1, 0])
        #expect(path.strictDominators(of: 2) == [1, 0])
    }

    @Test("CN-96 children(of:) in vertices order")
    func children() {
        let set0 = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 1), (2, 4), (2, 5), (3, 6), (3, 7), (4, 12), (5, 8), (6, 9), (7, 9), (7, 10), (8, 5), (8, 11), (9, 11), (10, 9), (11, 0), (11, 9), (12, 8)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected = [0: [1, 2, 3, 4, 5, 8, 9, 11], 3: [6, 7], 4: [12], 7: [10]]
        let tree = CompressedSparseRow(vertexCount: 13, edges: set0).dominatorTree(root: 0)
        for v in 0 ..< 13 { #expect(Array(tree.children(of: v)) == expected[v, default: []], "\(v)") }
        #expect(tree.children(of: 12).isEmpty)
        let names = ["r", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"]
        let pairs = [("r", "a"), ("r", "b"), ("r", "c"), ("a", "d"), ("b", "a"), ("b", "d"), ("b", "e"), ("c", "f"), ("c", "g"), ("d", "l"), ("e", "h"), ("f", "i"), ("g", "i"), ("g", "j"), ("h", "e"), ("h", "k"), ("i", "k"), ("j", "i"), ("k", "r"), ("k", "i"), ("l", "h")]
        let figure1 = Multigraph(vertices: names + ["z"], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) }).dominatorTree(root: "r")
        #expect(Array(figure1.children(of: "r")) == ["a", "b", "c", "d", "e", "h", "i", "k"])
        #expect(Array(figure1.children(of: "c")) == ["f", "g"])
        #expect(Array(figure1.children(of: "z")) == [])
    }

    @Test("CN-97 dominates(_:_:)")
    func dominates() {
        let set0 = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 1), (2, 4), (2, 5), (3, 6), (3, 7), (4, 12), (5, 8), (6, 9), (7, 9), (7, 10), (8, 5), (8, 11), (9, 11), (10, 9), (11, 0), (11, 9), (12, 8)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let tree = AdjacencyMatrix(vertexCount: 13, edges: set0).dominatorTree(root: 0)
        #expect(tree.dominates(3, 10))
        #expect(tree.dominates(7, 10))
        for v in 0 ..< 13 {
            #expect(tree.dominates(0, v))
            #expect(tree.dominates(v, v))
        }
        #expect(!tree.dominates(7, 9))
        #expect(!tree.dominates(10, 7))
        let set5 = [(0, 1), (0, 2), (1, 6), (2, 3), (2, 4), (3, 7), (5, 7), (6, 7)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let five = AdjacencyMatrix(vertexCount: 8, edges: set5).dominatorTree(root: 0)
        #expect(!five.dominates(0, 5))
        #expect(!five.dominates(5, 5))
        #expect(!five.dominates(5, 7))
    }

    @Test("CN-98 dominates agrees with dominators(of:) for every root and pair", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func dominatesAgrees(_ fixture: DirectedFixture<Int>) {
        let graph = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        for root in graph.vertices {
            let tree = graph.dominatorTree(root: root)
            for b in graph.vertices {
                let dominators = tree.dominators(of: b)
                #expect(tree.strictDominators(of: b) == dominators.map { Array($0.dropFirst()) })
                #expect(dominators?.first == (dominators == nil ? nil : b))
                #expect(dominators?.last == (dominators == nil ? nil : root))
                for a in graph.vertices {
                    #expect(tree.dominates(a, b) == (dominators?.contains(a) ?? false), "from \(root): \(a) dominates \(b)")
                }
            }
        }
    }

    @Test("CN-98 dominates agrees with dominators(of:) on String fixtures")
    func dominatesAgreesStrings() {
        for fixture in DirectedFixture<String>.all {
            let graph = Multigraph(vertices: fixture.vertices, edges: fixture.edges)
            for root in graph.vertices {
                let tree = graph.dominatorTree(root: root)
                for b in graph.vertices {
                    let dominators = tree.dominators(of: b)
                    for a in graph.vertices {
                        #expect(tree.dominates(a, b) == (dominators?.contains(a) ?? false), "from \(root): \(a) dominates \(b)")
                    }
                }
            }
        }
    }
}

@Suite("Dominance frontiers")
struct DominanceFrontierTests {
    @Test("CN-99 NetworkX's docstring graph")
    func networkXDocstring() {
        let edges = [(1, 2), (1, 3), (2, 5), (3, 4), (4, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected = [1: [], 2: [5], 3: [5], 4: [5], 5: [Int]()]
        let frontiers = Multigraph(vertices: 1 ... 5, edges: edges).dominanceFrontiers(root: 1)
        for v in 1 ... 5 { #expect(frontiers[v].map { Array($0) } == expected[v], "\(v)") }
        let list = AdjacencyList(vertices: 1 ... 5, edges: edges).dominanceFrontiers(root: 1)
        for v in 1 ... 5 { #expect(list[v].map { Set($0) } == expected[v].map { Set($0) }, "\(v)") }
    }

    @Test("CN-100 singletons, cycles and paths; the root in its own frontier", .tags(.selfLoops))
    func rootInItsFrontier() {
        #expect(CompressedSparseRow(vertexCount: 1).dominanceFrontiers(root: 0)[0].map { Array($0) } == [])
        #expect(CompressedSparseRow(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0)]).dominanceFrontiers(root: 0)[0].map { Array($0) } == [0])
        #expect(AdjacencyMatrix(vertexCount: 1, edges: [DirectedEdge(from: 0, to: 0)]).dominanceFrontiers(root: 0)[0].map { Array($0) } == [0])
        for n in [5, 10] {
            let cycle = (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) }
            let cycleFrontiers = CompressedSparseRow(vertexCount: n, edges: cycle).dominanceFrontiers(root: 0)
            let cycleMatrix = AdjacencyMatrix(vertexCount: n, edges: cycle).dominanceFrontiers(root: 0)
            let path = (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) }
            let pathFrontiers = CompressedSparseRow(vertexCount: n, edges: path).dominanceFrontiers(root: 0)
            for v in 0 ..< n {
                #expect(cycleFrontiers[v].map { Array($0) } == [0], "cycle \(n): \(v)")
                #expect(cycleMatrix[v].map { Array($0) } == [0], "cycle \(n): \(v)")
                #expect(pathFrontiers[v].map { Array($0) } == [], "path \(n): \(v)")
            }
        }
    }

    @Test("CN-101 unreachable vertices have no frontier")
    func unreachable() {
        let path = (0 ..< 4).map { DirectedEdge(from: $0, to: $0 + 1) }
        let frontiers = CompressedSparseRow(vertexCount: 5, edges: path).dominanceFrontiers(root: 1)
        #expect(frontiers[0] == nil)
        for v in 1 ..< 5 { #expect(frontiers[v].map { Array($0) } == [], "\(v)") }
        #expect(AdjacencyList(vertices: 0 ..< 5, edges: path).dominanceFrontiers(root: 1)[0] == nil)
    }

    @Test("CN-102 Cooper et al.'s irreducible graphs")
    func irreducible() {
        let figure2 = [(1, 2), (2, 1), (3, 2), (4, 1), (5, 3), (5, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let two = Multigraph(vertices: 1 ... 5, edges: figure2.sorted()).dominanceFrontiers(root: 5)
        let twoExpected = [1: [2], 2: [1], 3: [2], 4: [1], 5: []]
        for v in 1 ... 5 { #expect(two[v].map { Array($0) } == twoExpected[v], "\(v)") }
        let figure4 = [(1, 2), (2, 1), (2, 3), (3, 2), (4, 2), (4, 3), (5, 1), (6, 4), (6, 5)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let four = Multigraph(vertices: 1 ... 6, edges: figure4.sorted()).dominanceFrontiers(root: 6)
        let fourExpected = [1: [2], 2: [1, 3], 3: [2], 4: [2, 3], 5: [1], 6: []]
        for v in 1 ... 6 { #expect(four[v].map { Array($0) } == fourExpected[v], "\(v)") }
        let fourList = AdjacencyList(vertices: 1 ... 6, edges: figure4).dominanceFrontiers(root: 6)
        for v in 1 ... 6 { #expect(fourList[v].map { Set($0) } == fourExpected[v].map { Set($0) }, "\(v)") }
    }

    @Test("CN-103 Domrel and Boost's figure 1")
    func domrelAndBoost() {
        let domrel = [(1, 2), (2, 3), (2, 4), (2, 6), (3, 5), (4, 5), (5, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let domrelFrontiers = Multigraph(vertices: 1 ... 6, edges: domrel).dominanceFrontiers(root: 1)
        let domrelExpected = [1: [], 2: [2], 3: [5], 4: [5], 5: [2], 6: []]
        for v in 1 ... 6 { #expect(domrelFrontiers[v].map { Array($0) } == domrelExpected[v], "\(v)") }
        let boost = [(0, 1), (1, 2), (1, 3), (2, 7), (3, 4), (4, 5), (4, 6), (5, 7), (6, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let boostExpected = [0: [], 1: [], 2: [7], 3: [7], 4: [4, 7], 5: [7], 6: [4], 7: []]
        let matrix = AdjacencyMatrix(vertexCount: 8, edges: boost).dominanceFrontiers(root: 0)
        let sparse = CompressedSparseRow(vertexCount: 8, edges: boost).dominanceFrontiers(root: 0)
        for v in 0 ..< 8 {
            #expect(matrix[v].map { Array($0) } == boostExpected[v], "\(v)")
            #expect(sparse[v].map { Array($0) } == boostExpected[v], "\(v)")
        }
    }

    @Test("CN-104 NetworkX's String cases")
    func networkXStrings() {
        let discard = [("b0", "b1"), ("b1", "b2"), ("b2", "b3"), ("b3", "b1"), ("b1", "b5"), ("b5", "b6"), ("b5", "b8"), ("b6", "b7"), ("b8", "b7"), ("b7", "b3"), ("b3", "b4")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let discardExpected = ["b0": [], "b1": ["b1"], "b2": ["b3"], "b3": ["b1"], "b4": [], "b5": ["b3"], "b6": ["b7"], "b7": ["b3"], "b8": ["b7"]]
        let discardFrontiers = Multigraph(edges: discard).dominanceFrontiers(root: "b0")
        for (v, frontier) in discardExpected { #expect(discardFrontiers[v].map { Array($0) } == frontier, "\(v)") }
        let loop = [("a", "b"), ("b", "c"), ("b", "a")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let loopFrontiers = Multigraph(edges: loop).dominanceFrontiers(root: "a")
        #expect(loopFrontiers["a"].map { Array($0) } == ["a"])
        #expect(loopFrontiers["b"].map { Array($0) } == ["a"])
        #expect(loopFrontiers["c"].map { Array($0) } == [])
        // Written order: entry, exit, 1…6.
        let larger = [("entry", "exit"), ("entry", "1"), ("1", "2"), ("2", "3"), ("3", "4"), ("4", "5"), ("5", "6"), ("6", "exit"), ("6", "2"), ("5", "3"), ("4", "4")].map { DirectedEdge(from: $0.0, to: $0.1) }
        let largerGraph = Multigraph(edges: larger)
        #expect(largerGraph.vertices == ["entry", "exit", "1", "2", "3", "4", "5", "6"])
        let largerExpected = ["entry": [], "exit": [], "1": ["exit"], "2": ["exit", "2"], "3": ["exit", "2", "3"], "4": ["exit", "2", "3", "4"], "5": ["exit", "2", "3"], "6": ["exit", "2"]]
        let largerFrontiers = largerGraph.dominanceFrontiers(root: "entry")
        for (v, frontier) in largerExpected { #expect(largerFrontiers[v].map { Array($0) } == frontier, "\(v)") }
    }

    @Test("CN-105 Boost sets 0 and 6 (computed; Boost does not test frontiers)")
    func boostSets() {
        let set0 = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 1), (2, 4), (2, 5), (3, 6), (3, 7), (4, 12), (5, 8), (6, 9), (7, 9), (7, 10), (8, 5), (8, 11), (9, 11), (10, 9), (11, 0), (11, 9), (12, 8)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected0 = [0: [0], 1: [4], 2: [1, 4, 5], 3: [9], 4: [8], 5: [8], 6: [9], 7: [9], 8: [5, 11], 9: [11], 10: [9], 11: [0, 9], 12: [8]]
        let matrix0 = AdjacencyMatrix(vertexCount: 13, edges: set0).dominanceFrontiers(root: 0)
        let sparse0 = CompressedSparseRow(vertexCount: 13, edges: set0).dominanceFrontiers(root: 0)
        for v in 0 ..< 13 {
            #expect(matrix0[v].map { Array($0) } == expected0[v], "\(v)")
            #expect(sparse0[v].map { Array($0) } == expected0[v], "\(v)")
        }
        let set6 = [(0, 1), (0, 13), (1, 2), (2, 3), (2, 7), (3, 4), (3, 5), (4, 6), (5, 6), (6, 8), (7, 8), (8, 9), (9, 10), (9, 11), (10, 11), (11, 9), (11, 12), (12, 2), (12, 13)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let expected6 = [0: [], 1: [13], 2: [2, 13], 3: [8], 4: [6], 5: [6], 6: [8], 7: [8], 8: [2, 13], 9: [2, 9, 13], 10: [11], 11: [2, 9, 13], 12: [2, 13], 13: []]
        let matrix6 = AdjacencyMatrix(vertexCount: 14, edges: set6).dominanceFrontiers(root: 0)
        let sparse6 = CompressedSparseRow(vertexCount: 14, edges: set6).dominanceFrontiers(root: 0)
        let list6 = AdjacencyList(vertices: 0 ..< 14, edges: set6).dominanceFrontiers(root: 0)
        for v in 0 ..< 14 {
            #expect(matrix6[v].map { Array($0) } == expected6[v], "\(v)")
            #expect(sparse6[v].map { Array($0) } == expected6[v], "\(v)")
            #expect(list6[v].map { Set($0) } == expected6[v].map { Set($0) }, "\(v)")
        }
    }

    @Test("CN-106 frontiers of the fixtures", .tags(.fixture))
    func fixtures() {
        let cases: [(DirectedFixture<Int>, Int, [Int: [Int]])] = [
            (.house, 5, [0: [], 1: [0], 2: [1], 3: [], 4: [0, 1], 5: []]),
            (.scc9, 1, [0: [6], 1: [1], 2: [5], 3: [6], 4: [1], 5: [5], 6: [6], 7: [1], 8: [5]]),
            (.petgraphEdgesDirected, 0, [0: [0], 1: [3], 2: [0, 3], 3: [], 4: [0], 5: []]),
            (.cube, 0, [0: [0], 1: [0, 3, 5], 2: [0, 3, 6], 3: [1, 2, 7], 4: [0, 5, 6], 5: [1, 4, 7], 6: [2, 4, 7], 7: [3, 5, 6]]),
        ]
        for (fixture, root, expected) in cases {
            let matrix = AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges).dominanceFrontiers(root: root)
            let sparse = CompressedSparseRow(vertexCount: fixture.vertexCount, edges: fixture.edges).dominanceFrontiers(root: root)
            let list = AdjacencyList(vertices: fixture.vertices, edges: fixture.edges).dominanceFrontiers(root: root)
            for v in 0 ..< fixture.vertexCount {
                #expect(matrix[v].map { Array($0) } == expected[v], "\(fixture.name): \(v)")
                #expect(sparse[v].map { Array($0) } == expected[v], "\(fixture.name): \(v)")
                #expect(list[v].map { Set($0) } == expected[v].map { Set($0) }, "\(fixture.name): \(v)")
            }
        }
        // petgraphEdgesDirected: 6 is unreachable from 0.
        #expect(CompressedSparseRow(vertexCount: 7, edges: DirectedFixture<Int>.petgraphEdgesDirected.edges).dominanceFrontiers(root: 0)[6] == nil)
    }

    @Test("CN-107 a self-loop on a join point puts it in its own frontier", .tags(.selfLoops))
    func selfLoopJoinPoint() {
        let loops = DirectedFixture<Int>.selfLoopsAndDuplicates
        let loopFrontiers = Multigraph(vertices: loops.vertices, edges: loops.edges).dominanceFrontiers(root: 1)
        let loopExpected = [1: [], 2: [], 3: [], 4: [4]]
        for v in 1 ... 5 { #expect(loopFrontiers[v].map { Array($0) } == loopExpected[v], "\(v)") }
        let function = DirectedFixture<Int>.networkXFunctionGraph
        let functionExpected = [0: [0], 1: [0, 1, 2], 2: [], 3: []]
        let matrix = AdjacencyMatrix(vertexCount: 5, edges: function.edges).dominanceFrontiers(root: 0)
        let sparse = CompressedSparseRow(vertexCount: 5, edges: function.edges).dominanceFrontiers(root: 0)
        for v in 0 ..< 5 {
            #expect(matrix[v].map { Array($0) } == functionExpected[v], "\(v)")
            #expect(sparse[v].map { Array($0) } == functionExpected[v], "\(v)")
        }
        let csr1 = DirectedFixture<Int>.petgraphCsr1
        let csr1Expected = [0: [0, 2], 1: [1], 2: [2]]
        let csr1Matrix = AdjacencyMatrix(vertexCount: 3, edges: csr1.edges).dominanceFrontiers(root: 1)
        let csr1Sparse = CompressedSparseRow(vertexCount: 3, edges: csr1.edges).dominanceFrontiers(root: 1)
        for v in 0 ..< 3 {
            #expect(csr1Matrix[v].map { Array($0) } == csr1Expected[v], "\(v)")
            #expect(csr1Sparse[v].map { Array($0) } == csr1Expected[v], "\(v)")
        }
    }

    @Test("CN-108 parallel edges into a join point")
    func parallelEdges() {
        // 1→3 is written twice.
        let fixture = DirectedFixture<Int>.pathWithChord
        let frontiers = Multigraph(vertices: fixture.vertices, edges: fixture.edges).dominanceFrontiers(root: 0)
        for v in 0 ..< 6 { #expect(frontiers[v].map { Array($0) } == (v == 2 ? [3] : []), "\(v)") }
    }
}

@Suite("Post-dominators")
struct PostDominatorTests {
    @Test("CN-109 NetworkX's examples")
    func networkX() {
        let first = [(1, 2), (2, 3), (2, 4), (3, 5), (4, 5), (5, 6)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let firstExpected = [5: 6, 4: 5, 3: 5, 2: 5, 1: 2]
        let firstMultigraph = Multigraph(vertices: 1 ... 6, edges: first).postDominatorTree(exit: 6)
        let firstList = AdjacencyList(vertices: 1 ... 6, edges: first).postDominatorTree(exit: 6)
        #expect(firstMultigraph.root == 6)
        for v in 1 ... 6 {
            #expect(firstMultigraph.immediateDominator(of: v) == firstExpected[v], "\(v)")
            #expect(firstList.immediateDominator(of: v) == firstExpected[v], "\(v)")
        }
        let domrel = [(1, 2), (2, 3), (2, 4), (2, 6), (3, 5), (4, 5), (5, 2)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let domrelExpected = [1: 2, 2: 6, 3: 5, 4: 5, 5: 2]
        let domrelMultigraph = Multigraph(vertices: 1 ... 6, edges: domrel).postDominatorTree(exit: 6)
        let domrelList = AdjacencyList(vertices: 1 ... 6, edges: domrel).postDominatorTree(exit: 6)
        for v in 1 ... 6 {
            #expect(domrelMultigraph.immediateDominator(of: v) == domrelExpected[v], "\(v)")
            #expect(domrelList.immediateDominator(of: v) == domrelExpected[v], "\(v)")
        }
        let boost = [(0, 1), (1, 2), (1, 3), (2, 7), (3, 4), (4, 5), (4, 6), (5, 7), (6, 4)].map { DirectedEdge(from: $0.0, to: $0.1) }
        let boostExpected = [0: 1, 1: 7, 2: 7, 3: 4, 4: 5, 5: 7, 6: 4]
        let boostMatrix = AdjacencyMatrix(vertexCount: 8, edges: boost).postDominatorTree(exit: 7)
        let boostList = AdjacencyList(vertices: 0 ..< 8, edges: boost).postDominatorTree(exit: 7)
        for v in 0 ..< 8 {
            #expect(boostMatrix.immediateDominator(of: v) == boostExpected[v], "\(v)")
            #expect(boostList.immediateDominator(of: v) == boostExpected[v], "\(v)")
        }
    }

    @Test("CN-110 post-dominators of the fixtures (adjacency list, matrix, Multigraph)", .tags(.fixture))
    func fixtures() {
        let house = DirectedFixture<Int>.house
        let houseExpected = [1: 0, 2: 1, 3: 0, 4: 0, 5: 3]
        func checkHouse<G: BidirectionalDirectedGraph<Int>>(_ g: G) {
            let tree = g.postDominatorTree(exit: 0)
            #expect(tree.root == 0)
            for v in 0 ..< 6 { #expect(tree.immediateDominator(of: v) == houseExpected[v], "house: \(v)") }
        }
        checkHouse(AdjacencyList(vertices: house.vertices, edges: house.edges))
        checkHouse(AdjacencyMatrix(vertexCount: 6, edges: house.edges))
        checkHouse(Multigraph(vertices: house.vertices, edges: house.edges))
        let directed = DirectedFixture<Int>.petgraphEdgesDirected
        let directedExpected = [0: 3, 1: 3, 2: 3, 4: 0]
        func checkDirected<G: BidirectionalDirectedGraph<Int>>(_ g: G) {
            let tree = g.postDominatorTree(exit: 3)
            for v in 0 ..< 7 { #expect(tree.immediateDominator(of: v) == directedExpected[v], "petgraphEdgesDirected: \(v)") }
            // 5 and 6 cannot reach 3.
            #expect(tree.dominators(of: 5) == nil)
            #expect(tree.dominators(of: 6) == nil)
        }
        checkDirected(AdjacencyList(vertices: directed.vertices, edges: directed.edges))
        checkDirected(AdjacencyMatrix(vertexCount: 7, edges: directed.edges))
        checkDirected(Multigraph(vertices: directed.vertices, edges: directed.edges))
    }

    @Test("CN-111 the post-dominator tree is the dominator tree of the reversed graph", .tags(.fixture), arguments: DirectedFixture<Int>.all)
    func reversedGraph(_ fixture: DirectedFixture<Int>) {
        func check<G: BidirectionalDirectedGraph<Int>>(_ g: G) {
            // The reversed Multigraph lists g's vertices first, so `vertices` order is the same.
            let reversed = Multigraph(vertices: Array(g.vertices), edges: fixture.edges.map { DirectedEdge(from: $0.target, to: $0.source) })
            for exit in g.vertices {
                let post = g.postDominatorTree(exit: exit)
                let tree = reversed.dominatorTree(root: exit)
                #expect(post.root == tree.root)
                for v in g.vertices {
                    #expect(post.immediateDominator(of: v) == tree.immediateDominator(of: v), "exit \(exit): \(v)")
                    #expect(post.dominators(of: v) == tree.dominators(of: v), "exit \(exit): \(v)")
                    #expect(post.strictDominators(of: v) == tree.strictDominators(of: v), "exit \(exit): \(v)")
                    #expect(Array(post.children(of: v)) == Array(tree.children(of: v)), "exit \(exit): \(v)")
                    for w in g.vertices { #expect(post.dominates(v, w) == tree.dominates(v, w), "exit \(exit): \(v), \(w)") }
                }
            }
        }
        check(AdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(Multigraph(vertices: fixture.vertices, edges: fixture.edges))
        if fixture.vertexSet == Set(0 ..< fixture.vertexCount) {
            check(AdjacencyMatrix(vertexCount: fixture.vertexCount, edges: fixture.edges))
        }
    }
}
