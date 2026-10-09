// §B: `LowestCommonAncestors`, the O(1)-query structure built from a `RootedTree` or an
// `Arborescence`, and its `distance(from:to:)` (edges between the two, independent of the root:
// TA-110 = TA-108). The `allPairsAgree` rows ask that the structure, the one-shot query, the
// heavy–light decomposition's query and an oracle written in the test (the first vertex of one
// argument's ancestor chain, itself included, that lies on the other's) give the same vertex for
// every ordered pair; `ref.py` also checks those pairs against NetworkX 3.7's
// `tree_all_pairs_lowest_common_ancestor`. The implementation answers by a range minimum over
// preorder in blocks of 64 entries, so the paths and stars of TA-116 – TA-120 and the block test
// below cross block boundaries (0/63/64/127/128/…); the oracle there is written on the tree's own
// parent and depth by index. Index-space queries take and return vertex indices
// (`vertexIndex(of:)`, which is `vertices` order). Sources are written on the
// `ReferencePseudograph` / `ReferenceDirectedMultigraph` as the catalog writes them. Literals are
// catalog cells or were computed with `ref.py`'s model (the extra queries on catalog sources).
// TA-123 is an exit test in `TreeAlgorithmPreconditionTests.swift`. Case IDs (TA-nnn) refer to
// the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees

@Suite("LowestCommonAncestors")
struct LowestCommonAncestorsTests {
    @Test("TA-101 LowestCommonAncestors(K₁).lowestCommonAncestor(of: 0, 0) is 0")
    func singleVertex() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: 0, 0) == 0)
        #expect(lca.lowestCommonAncestor(ofIndex: 0, 0) == 0)
    }

    @Test("TA-102 LowestCommonAncestors(K₁).distance(from: 0, to: 0) is 0")
    func singleVertexDistance() throws {
        // U: [0]
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.distance(from: 0, to: 0) == 0)
        #expect(lca.distance(fromIndex: 0, toIndex: 0) == 0)
    }

    @Test("TA-103 LowestCommonAncestors(K₂, root: 0).lowestCommonAncestor(of: 1, 0) is 0")
    func edge() throws {
        // U: [] 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: 1, 0) == 0)
        #expect(lca.lowestCommonAncestor(of: 0, 1) == 0)
        #expect(lca.lowestCommonAncestor(of: 1, 1) == 1)
    }

    @Test("TA-104 LowestCommonAncestors(F1, root: 0).lowestCommonAncestor(of: 3, 7) is 1 (= TA-003)")
    func f1Cousins() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: 3, 7) == 1)
    }

    @Test("TA-105 LowestCommonAncestors(F1, root: 0).lowestCommonAncestor(of: 7, 3) is 1: arguments in either preorder order")
    func f1CousinsSwapped() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: 7, 3) == 1)
    }

    @Test("TA-106 LowestCommonAncestors(F1, root: 0).lowestCommonAncestor(of: 1, 7) is 1: an ancestor")
    func f1Ancestor() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: 1, 7) == 1)
        #expect(lca.lowestCommonAncestor(of: 7, 1) == 1)
    }

    @Test("TA-107 LowestCommonAncestors(F1, root: 0).lowestCommonAncestor(of: 0, 8) is 0: the root")
    func f1Root() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: 0, 8) == 0)
    }

    @Test("TA-108 LowestCommonAncestors(F1, root: 0).distance(from: 3, to: 8) is 5")
    func f1Distance() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.distance(from: 3, to: 8) == 5)
        #expect(lca.distance(from: 8, to: 3) == 5)
    }

    @Test("TA-109 LowestCommonAncestors(F1, root: 0).distance(from: 6, to: 7) is 2")
    func f1SiblingDistance() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.distance(from: 6, to: 7) == 2)
    }

    @Test("TA-110 LowestCommonAncestors(F1, root: 4).distance(from: 3, to: 8) is 5: the distance does not depend on the root")
    func f1DistanceRerooted() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.distance(from: 3, to: 8) == 5)
        // Every pair: the same as at root 0, and the length of the tree's path.
        let atZero = LowestCommonAncestors(RootedTree(Tree(rooted), root: 0))
        let tree = Tree(rooted)
        for a in 0 ... 8 {
            for b in 0 ... 8 {
                let here = lca.distance(from: a, to: b)
                #expect(here == atZero.distance(from: a, to: b))
                #expect(here == tree.path(from: a, to: b).length)
            }
        }
    }

    @Test("TA-111 LowestCommonAncestors(F1, root: 0): every ordered pair agrees with the one-shot query, HLD and ancestor chains")
    func f1AllPairs() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        // The oracle: the first vertex of a's chain (a, then its ancestors) on b's chain.
        var chains: [Int: [Int]] = [:]
        for v in rooted.vertices { chains[v] = [v] + Array(rooted.ancestors(of: v)) }
        for a in rooted.vertices {
            for b in rooted.vertices {
                let onChainOfB = Set(chains[b, default: []])
                let expected = try #require(chains[a, default: []].first { onChainOfB.contains($0) })
                #expect(lca.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(rooted.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(hld.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
            }
        }
    }

    @Test("TA-112 LowestCommonAncestors(F1, root: 4): every ordered pair agrees")
    func f1RerootedAllPairs() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        // The oracle: the first vertex of a's chain (a, then its ancestors) on b's chain.
        var chains: [Int: [Int]] = [:]
        for v in rooted.vertices { chains[v] = [v] + Array(rooted.ancestors(of: v)) }
        for a in rooted.vertices {
            for b in rooted.vertices {
                let onChainOfB = Set(chains[b, default: []])
                let expected = try #require(chains[a, default: []].first { onChainOfB.contains($0) })
                #expect(lca.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(rooted.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(hld.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
            }
        }
    }

    @Test("TA-113 LowestCommonAncestors(F1b, root: 0): another preorder, the same answers as F1")
    func f1bAllPairs() throws {
        // U: [0..8] 4-7, 0-2, 1-4, 5-8, 0-1, 4-6, 1-3, 2-5
        let pairs: [(Int, Int)] = [(4, 7), (0, 2), (1, 4), (5, 8), (0, 1), (4, 6), (1, 3), (2, 5)]
        let graph = ReferencePseudograph(vertices: 0 ... 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        // F1, the same edge set in position order.
        let f1Pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let f1 = try #require(RootedTree(ReferencePseudograph(vertices: 0 ... 8, edges: f1Pairs.map { UndirectedEdge($0.0, $0.1) }), root: 0))
        let f1LCA = LowestCommonAncestors(f1)
        // The oracle: the first vertex of a's chain (a, then its ancestors) on b's chain.
        var chains: [Int: [Int]] = [:]
        for v in rooted.vertices { chains[v] = [v] + Array(rooted.ancestors(of: v)) }
        for a in rooted.vertices {
            for b in rooted.vertices {
                let onChainOfB = Set(chains[b, default: []])
                let expected = try #require(chains[a, default: []].first { onChainOfB.contains($0) })
                #expect(lca.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(rooted.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(hld.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(f1LCA.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
            }
        }
    }

    @Test("TA-114 LowestCommonAncestors(Arborescence(NX)): all 49 ordered pairs agree")
    func nxAllPairs() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let lca = LowestCommonAncestors(arborescence)
        let hld = HeavyLightDecomposition(arborescence)
        var checked = 0
        // The oracle: the first vertex of a's chain (a, then its ancestors) on b's chain.
        var chains: [Int: [Int]] = [:]
        for v in arborescence.vertices { chains[v] = [v] + Array(arborescence.ancestors(of: v)) }
        for a in arborescence.vertices {
            for b in arborescence.vertices {
                let onChainOfB = Set(chains[b, default: []])
                let expected = try #require(chains[a, default: []].first { onChainOfB.contains($0) })
                #expect(lca.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(arborescence.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(hld.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                checked += 1
            }
        }
        #expect(checked == 49)
        // NetworkX's TestTreeLCA gold pairs (TA-012 – TA-015).
        #expect(lca.lowestCommonAncestor(of: 3, 4) == 1)
        #expect(lca.lowestCommonAncestor(of: 3, 5) == 0)
        #expect(lca.lowestCommonAncestor(of: 5, 6) == 2)
        #expect(lca.lowestCommonAncestor(of: 2, 6) == 2)
    }

    @Test("TA-115 LowestCommonAncestors(Arborescence(NX)).lowestCommonAncestor(of: 4, 5) is 0")
    func nxFromArborescence() throws {
        // D: [] 0>1, 0>2, 1>3, 1>4, 2>5, 2>6
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = ReferenceDirectedMultigraph(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let lca = LowestCommonAncestors(arborescence)
        #expect(lca.lowestCommonAncestor(of: 4, 5) == 0)
        // From the arborescence or its rooted tree: the same.
        #expect(LowestCommonAncestors(RootedTree(arborescence)).lowestCommonAncestor(of: 4, 5) == 0)
    }

    @Test("TA-116 LowestCommonAncestors(kary(63, 2), root: 0): every ordered pair agrees, across the 64-entry block boundary")
    func completeBinaryAllPairs() throws {
        // U: [] kary(63,2)
        let n = 63
        let pairs = (0 ..< n).flatMap { i in [2 * i + 1, 2 * i + 2].filter { $0 < n }.map { (i, $0) } }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        // The oracle: the first vertex of a's chain (a, then its ancestors) on b's chain.
        var chains: [Int: [Int]] = [:]
        for v in rooted.vertices { chains[v] = [v] + Array(rooted.ancestors(of: v)) }
        for a in rooted.vertices {
            for b in rooted.vertices {
                let onChainOfB = Set(chains[b, default: []])
                let expected = try #require(chains[a, default: []].first { onChainOfB.contains($0) })
                #expect(lca.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(rooted.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(hld.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
            }
        }
        // Computed with ref.py: two leaves, siblings and far apart.
        #expect(lca.lowestCommonAncestor(of: 62, 61) == 30)
        #expect(lca.lowestCommonAncestor(of: 62, 31) == 0)
        #expect(lca.distance(from: 62, to: 31) == 10)
    }

    @Test("TA-117 LowestCommonAncestors(P(0..140), root: 70): every ordered pair agrees over three RMQ blocks")
    func pathAllPairs() throws {
        // U: [] P(0..140)
        let pairs = (0 ..< 140).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 70))
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        // The oracle: the first vertex of a's chain (a, then its ancestors) on b's chain.
        var chains: [Int: [Int]] = [:]
        for v in rooted.vertices { chains[v] = [v] + Array(rooted.ancestors(of: v)) }
        for a in rooted.vertices {
            for b in rooted.vertices {
                let onChainOfB = Set(chains[b, default: []])
                let expected = try #require(chains[a, default: []].first { onChainOfB.contains($0) })
                #expect(lca.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(rooted.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(hld.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
            }
        }
        // Computed with ref.py.
        #expect(lca.lowestCommonAncestor(of: 63, 64) == 64)
        #expect(lca.lowestCommonAncestor(of: 6, 7) == 7)
        #expect(lca.distance(from: 6, to: 134) == 128)
    }

    @Test("TA-118 LowestCommonAncestors(S(0; 1..150), root: 7): a star rooted at a leaf, every ordered pair agrees")
    func starAllPairs() throws {
        // U: [] S(0;1..150)
        let pairs = (1 ... 150).map { (0, $0) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 7))
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        // The oracle: the first vertex of a's chain (a, then its ancestors) on b's chain.
        var chains: [Int: [Int]] = [:]
        for v in rooted.vertices { chains[v] = [v] + Array(rooted.ancestors(of: v)) }
        for a in rooted.vertices {
            for b in rooted.vertices {
                let onChainOfB = Set(chains[b, default: []])
                let expected = try #require(chains[a, default: []].first { onChainOfB.contains($0) })
                #expect(lca.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(rooted.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(hld.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
            }
        }
        // Computed with ref.py.
        #expect(lca.lowestCommonAncestor(of: 150, 64) == 0)
        #expect(lca.distance(from: 150, to: 64) == 2)
    }

    @Test("TA-119 LowestCommonAncestors(P(0..140), root: 70).lowestCommonAncestor(of: 0, 140) is 70: ends across blocks")
    func pathEnds() throws {
        // U: [] P(0..140)
        let pairs = (0 ..< 140).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 70))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: 0, 140) == 70)
        #expect(lca.lowestCommonAncestor(of: 140, 0) == 70)
    }

    @Test("TA-120 LowestCommonAncestors(P(0..140), root: 70).distance(from: 0, to: 140) is 140")
    func pathEndsDistance() throws {
        // U: [] P(0..140)
        let pairs = (0 ..< 140).map { ($0, $0 + 1) }
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 70))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.distance(from: 0, to: 140) == 140)
    }

    @Test("TA-121 LowestCommonAncestors(a-b, b-c, b-d, d-e; root: e): String vertices, every ordered pair agrees")
    func stringAllPairs() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "e"))
        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        // The oracle: the first vertex of a's chain (a, then its ancestors) on b's chain.
        var chains: [String: [String]] = [:]
        for v in rooted.vertices { chains[v] = [v] + Array(rooted.ancestors(of: v)) }
        for a in rooted.vertices {
            for b in rooted.vertices {
                let onChainOfB = Set(chains[b, default: []])
                let expected = try #require(chains[a, default: []].first { onChainOfB.contains($0) })
                #expect(lca.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(rooted.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
                #expect(hld.lowestCommonAncestor(of: a, b) == expected, "(\(a), \(b))")
            }
        }
    }

    @Test("TA-122 LowestCommonAncestors(a-b, b-c, b-d, d-e; root: e).lowestCommonAncestor(of: a, c) is b")
    func stringQuery() throws {
        // U: [] a-b, b-c, b-d, d-e
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d"), ("d", "e")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "e"))
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: "a", "c") == "b")
    }

    @Test("TA-124 LowestCommonAncestors(3-1, 1-2, 1-0; root: 3).lowestCommonAncestor(of: 2, 0) is 1: Int vertices not in value order, and by index")
    func intVerticesNotInValueOrder() throws {
        // U: [] 3-1, 1-2, 1-0
        let pairs: [(Int, Int)] = [(3, 1), (1, 2), (1, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 3))
        #expect(Array(rooted.vertices) == [3, 1, 2, 0])
        let lca = LowestCommonAncestors(rooted)
        #expect(lca.lowestCommonAncestor(of: 2, 0) == 1)
        // Index space is `vertices` order, not the values: the vertex 1 is at index 1 here, but
        // the vertex 0 is at index 3.
        let indexOf2 = rooted.vertexIndex(of: 2)
        let indexOf0 = rooted.vertexIndex(of: 0)
        let answer = lca.lowestCommonAncestor(ofIndex: indexOf2, indexOf0)
        #expect(rooted.vertex(atIndex: answer) == 1)
        // Computed with ref.py.
        #expect(lca.distance(from: 2, to: 0) == 2)
        #expect(lca.distance(fromIndex: indexOf2, toIndex: indexOf0) == 2)
    }

    @Test("Index-space queries agree with vertex queries on every pair of F1 rooted at 4")
    func indexSpaceAgrees() throws {
        // U: [0..8] 0-1, 0-2, 1-3, 1-4, 2-5, 4-6, 4-7, 5-8, listed in another order so that
        // indices are not values.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6), (4, 7), (5, 8)]
        let graph = ReferencePseudograph(vertices: [8, 3, 5, 0, 7, 1, 6, 2, 4], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 4))
        let lca = LowestCommonAncestors(rooted)
        for i in 0 ..< rooted.vertexCount {
            for j in 0 ..< rooted.vertexCount {
                let a = rooted.vertex(atIndex: i)
                let b = rooted.vertex(atIndex: j)
                let byIndex = lca.lowestCommonAncestor(ofIndex: i, j)
                #expect(rooted.vertex(atIndex: byIndex) == lca.lowestCommonAncestor(of: a, b))
                #expect(lca.distance(fromIndex: i, toIndex: j) == lca.distance(from: a, to: b))
            }
        }
    }

    @Test("RMQ block boundaries: paths of 63 … 193 vertices at three roots, and stars, every pair against parent climbing")
    func blockBoundaries() throws {
        // Preorder positions on these shapes put pairs on both sides of every multiple of 64.
        for n in [63, 64, 65, 127, 128, 129, 191, 192, 193] {
            let pathEdges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
            let starEdges = (1 ..< n).map { UndirectedEdge(0, $0) }
            let path = try #require(Tree(vertices: 0 ..< n, edges: pathEdges))
            let star = try #require(Tree(vertices: 0 ..< n, edges: starEdges))
            let shapes = [
                RootedTree(path, root: 0), RootedTree(path, root: n / 2), RootedTree(path, root: n - 1),
                RootedTree(star, root: 0), RootedTree(star, root: n - 1),
            ]
            for rooted in shapes {
                let lca = LowestCommonAncestors(rooted)
                let parent = (0 ..< n).map { rooted.parent(ofIndex: $0) ?? -1 }
                let depth = (0 ..< n).map { rooted.depth(ofIndex: $0) }
                var mismatches: [String] = []
                for i in 0 ..< n {
                    for j in 0 ..< n {
                        var (x, y) = (i, j)
                        while depth[x] > depth[y] { x = parent[x] }
                        while depth[y] > depth[x] { y = parent[y] }
                        while x != y { (x, y) = (parent[x], parent[y]) }
                        let got = lca.lowestCommonAncestor(ofIndex: i, j)
                        let distance = lca.distance(fromIndex: i, toIndex: j)
                        if got != x || distance != depth[i] + depth[j] - 2 * depth[x] {
                            mismatches.append("(\(i), \(j)): \(got), \(distance)")
                        }
                    }
                }
                #expect(mismatches.isEmpty, "n = \(n), root \(rooted.root): \(mismatches.prefix(5))")
            }
        }
    }
}
