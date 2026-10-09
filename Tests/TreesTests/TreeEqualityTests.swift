// §J: equality and hashing. The README's rule for representations: equal vertex sets and equal edge
// sets, regardless of order and (undirected) orientation (TS-700, TS-701, TS-706, TS-707);
// `RootedTree` also compares the root (TS-702, TS-703); `Arborescence` compares arcs as ordered
// pairs (TS-704, TS-705). Equal values hash equal. Sources are written on the reference conformers
// as the catalog writes them. Expected values come from the catalog's reference (`ref.py`). Case
// IDs (TS-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Tree equality and hashing", .tags(.conformance))
struct TreeEqualityTests {
    @Test("TS-700 Tree(0-1, 1-2) == Tree(2-1, 1-0): vertex and edge sets, not order or orientation")
    func orderAndOrientationIgnored() throws {
        // U: 0-1, 1-2 against U: 2-1, 1-0
        let left: [(Int, Int)] = [(0, 1), (1, 2)]
        let right: [(Int, Int)] = [(2, 1), (1, 0)]
        let a = try #require(Tree(ReferencePseudograph(edges: left.map { UndirectedEdge($0.0, $0.1) })))
        let b = try #require(Tree(ReferencePseudograph(edges: right.map { UndirectedEdge($0.0, $0.1) })))
        #expect(a == b)
        #expect(b == a)
        #expect(a.hashValue == b.hashValue)
        // Equal values can differ in vertex order and edge positions.
        #expect(Array(a.vertices) != Array(b.vertices))
    }

    @Test("TS-701 Tree(0-1, 1-2) != Tree(0-1, 0-2)")
    func differentEdgesUnequal() throws {
        // U: 0-1, 1-2 against U: 0-1, 0-2
        let left: [(Int, Int)] = [(0, 1), (1, 2)]
        let right: [(Int, Int)] = [(0, 1), (0, 2)]
        let a = try #require(Tree(ReferencePseudograph(edges: left.map { UndirectedEdge($0.0, $0.1) })))
        let b = try #require(Tree(ReferencePseudograph(edges: right.map { UndirectedEdge($0.0, $0.1) })))
        #expect(a != b)
    }

    @Test("TS-702 RootedTree(0-1, 1-2, root: 0) == RootedTree(1-2, 0-1, root: 0)")
    func rootedEqual() throws {
        // U: 0-1, 1-2 against U: 1-2, 0-1, both rooted at 0
        let left: [(Int, Int)] = [(0, 1), (1, 2)]
        let right: [(Int, Int)] = [(1, 2), (0, 1)]
        let a = try #require(RootedTree(ReferencePseudograph(edges: left.map { UndirectedEdge($0.0, $0.1) }), root: 0))
        let b = try #require(RootedTree(ReferencePseudograph(edges: right.map { UndirectedEdge($0.0, $0.1) }), root: 0))
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("TS-703 RootedTree(0-1, 1-2, root: 0) != RootedTree(0-1, 1-2, root: 2): the root is part of the value")
    func rootDiffers() throws {
        // U: 0-1, 1-2 rooted at 0 and at 2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let a = try #require(RootedTree(ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) }), root: 0))
        let b = try #require(RootedTree(ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) }), root: 2))
        #expect(a != b)
        // Forgetting the root makes them equal.
        #expect(Tree(a) == Tree(b))
    }

    @Test("TS-704 Arborescence(0>1, 1>2) == Arborescence(parents: [nil, 0, 1])")
    func arborescenceEqualsParents() throws {
        // D: 0>1, 1>2 against parents: [_,0,1]
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let a = try #require(Arborescence(ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })))
        let b = try #require(Arborescence(parents: [nil, 0, 1]))
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("TS-705 Arborescence(0>1, 1>2) != Arborescence(2>1, 1>0): arcs are ordered pairs")
    func arcsAreOrdered() throws {
        // D: 0>1, 1>2 against D: 2>1, 1>0
        let left: [(Int, Int)] = [(0, 1), (1, 2)]
        let right: [(Int, Int)] = [(2, 1), (1, 0)]
        let a = try #require(Arborescence(ReferenceDirectedMultigraph(edges: left.map { DirectedEdge(from: $0.0, to: $0.1) })))
        let b = try #require(Arborescence(ReferenceDirectedMultigraph(edges: right.map { DirectedEdge(from: $0.0, to: $0.1) })))
        #expect(a != b)
        // As rooted trees they differ by the root, as trees not at all.
        #expect(RootedTree(a) != RootedTree(b))
        #expect(Tree(RootedTree(a)) == Tree(RootedTree(b)))
    }

    @Test("TS-706 Forest([0, 1]) == Forest([1, 0])")
    func forestVertexOrderIgnored() throws {
        // U: [0,1] against U: [1,0]
        let a = try #require(Forest(ReferencePseudograph<Int>(vertices: [0, 1], edges: [])))
        let b = try #require(Forest(ReferencePseudograph<Int>(vertices: [1, 0], edges: [])))
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("TS-707 Forest([0, 1, 2], 0-1) != Forest(0-1): the isolated vertex counts")
    func isolatedVertexCounts() throws {
        // U: [0,1,2] 0-1 against U: 0-1
        let a = try #require(Forest(ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])))
        let b = try #require(Forest(ReferencePseudograph(edges: [UndirectedEdge(0, 1)])))
        #expect(a != b)
    }

    @Test("Equal values in a Set collapse; reflexive, symmetric, and the conversions preserve equality")
    func setsAndConversions() throws {
        // E1 written three ways: in order, reversed, and every edge flipped.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let a = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let b = try #require(Tree(edges: pairs.reversed().map { UndirectedEdge($0.0, $0.1) }))
        let c = try #require(Tree(edges: pairs.map { UndirectedEdge($0.1, $0.0) }))
        #expect(Set([a, b, c]).count == 1)
        #expect(a == a)
        #expect(Forest(a) == Forest(c))
        #expect(Forest(a).hashValue == Forest(c).hashValue)
        let rootedA = RootedTree(a, root: 4)
        let rootedC = RootedTree(c, root: 4)
        #expect(rootedA == rootedC)
        #expect(rootedA.hashValue == rootedC.hashValue)
        #expect(Arborescence(rootedA) == Arborescence(rootedC))
        #expect(Arborescence(rootedA).hashValue == Arborescence(rootedC).hashValue)
        #expect(Set((0 ... 6).map { RootedTree(a, root: $0) }).count == 7)
        #expect(Set((0 ... 6).map { Arborescence(RootedTree(a, root: $0)) }).count == 7)
        // RootedTree(arborescence) and back is the same value.
        let arborescence = Arborescence(rootedA)
        #expect(Arborescence(RootedTree(arborescence)) == arborescence)
        #expect(RootedTree(Arborescence(rootedA)) == rootedA)
    }

    @Test("Same edge set, different vertex set: unequal (a tree's vertices are its edges' endpoints, so only forests differ this way)")
    func vertexSetMatters() throws {
        let a = try #require(Forest(vertices: [7], edges: [UndirectedEdge(0, 1)]))
        let b = try #require(Forest(vertices: [8], edges: [UndirectedEdge(0, 1)]))
        #expect(a != b)
        let k1 = try #require(Tree<Int>(vertices: [0], edges: []))
        let other = try #require(Tree<Int>(vertices: [1], edges: []))
        #expect(k1 != other)
    }
}
