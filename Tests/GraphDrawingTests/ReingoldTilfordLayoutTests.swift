// reingoldTilfordLayout and its circular form (catalog DR-033 – DR-063): Walker's algorithm in
// Buchheim, Jünger and Leipert's linear form, separation 1, y = depth, root at x = 0, exact; the
// circular form is igraph's polar map, compared within 1e-9.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphDrawing
import GraphProtocols
import Testing
import Trees

@Suite("reingoldTilfordLayout")
struct ReingoldTilfordLayoutTests {
    @Test("DR-033 one vertex")
    func dr033() throws {
        // T: [nil]; reingoldTilfordLayout() → [(0.0, 0.0)]
        let tree = try #require(RootedTree(parents: [nil]))
        #expect(Array(tree.vertices) == Array(0 ..< 1))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 1))
        #expect(layout.positions == [SIMD2(0.0, 0.0)])
    }

    @Test("DR-034 two vertices")
    func dr034() throws {
        // T: [nil, 0]; reingoldTilfordLayout() → [(0.0, 0.0), (0.0, 1.0)]
        let tree = try #require(RootedTree(parents: [nil, 0]))
        #expect(Array(tree.vertices) == Array(0 ..< 2))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 2))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0)])
    }

    @Test("DR-035 path of 4")
    func dr035() throws {
        // T: [nil, 0, 1, 2]; reingoldTilfordLayout() → [(0.0, 0.0), (0.0, 1.0), (0.0, 2.0), (0.0, 3.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 2]))
        #expect(Array(tree.vertices) == Array(0 ..< 4))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 4))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(0.0, 3.0)])
    }

    @Test("DR-036 star K1,3: root over the middle child")
    func dr036() throws {
        // T: [nil, 0, 0, 0]; reingoldTilfordLayout() → [(0.0, 0.0), (-1.0, 1.0), (0.0, 1.0), (1.0, 1.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0]))
        #expect(Array(tree.vertices) == Array(0 ..< 4))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 4))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.0, 1.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0)])
    }

    @Test("DR-037 star K1,4: even fan, root over the gap")
    func dr037() throws {
        // T: [nil, 0, 0, 0, 0]; reingoldTilfordLayout() → [(0.0, 0.0), (-1.5, 1.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 0]))
        #expect(Array(tree.vertices) == Array(0 ..< 5))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 5))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.5, 1.0), SIMD2(-0.5, 1.0), SIMD2(0.5, 1.0), SIMD2(1.5, 1.0)])
    }

    @Test("DR-038 binary tree of height 2")
    func dr038() throws {
        // T: bal(2,2); reingoldTilfordLayout() → [(0.0, 0.0), (-1.0, 1.0), (1.0, 1.0), (-1.5, 2.0), (-0.5, 2.0), (0.5, 2.0), (1.5, 2.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 1, 1, 2, 2]))
        #expect(Array(tree.vertices) == Array(0 ..< 7))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 7))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.0, 1.0), SIMD2(1.0, 1.0), SIMD2(-1.5, 2.0), SIMD2(-0.5, 2.0), SIMD2(0.5, 2.0),
            SIMD2(1.5, 2.0)])
    }

    @Test("DR-039 ternary tree of height 2")
    func dr039() throws {
        // T: bal(3,2); reingoldTilfordLayout() → [(0.0, 0.0), (-3.0, 1.0), (0.0, 1.0), (3.0, 1.0), (-4.0, 2.0), (-3.0, 2.0), (-2.0, 2.0), (-1.0, 2.0), (0.0, 2.0), (1.0, 2.0), (2.0, 2.0), (3.0, 2.0), (4.0, 2.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3]))
        #expect(Array(tree.vertices) == Array(0 ..< 13))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 13))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-3.0, 1.0), SIMD2(0.0, 1.0), SIMD2(3.0, 1.0), SIMD2(-4.0, 2.0), SIMD2(-3.0, 2.0),
            SIMD2(-2.0, 2.0), SIMD2(-1.0, 2.0), SIMD2(0.0, 2.0), SIMD2(1.0, 2.0), SIMD2(2.0, 2.0), SIMD2(3.0, 2.0), SIMD2(4.0, 2.0)])
    }

    @Test("DR-040 binary tree of height 4")
    func dr040() throws {
        // T: bal(2,4); reingoldTilfordLayout() → [(0.0, 0.0), (-4.0, 1.0), (4.0, 1.0), (-6.0, 2.0), (-2.0, 2.0), (2.0, 2.0), (6.0, 2.0), (-7.0, 3.0), (-5.0, 3.0), (-3.0, 3.0), (-1.0, 3.0), (1.0, 3.0), (3.0, 3.0), (5.0, 3.0), (7.0, 3.0), (-7.5, 4.0), (-6.5, 4.0), (-5.5, 4.0), (-4.5, 4.0), (-3.5, 4.0), (-2.5, 4.0), (-1.5, 4.0), (-0.5, 4.0), (0.5, 4.0), (1.5, 4.0), (2.5, 4.0), (3.5, 4.0), (4.5, 4.0), (5.5, 4.0), (6.5, 4.0), (7.5, 4.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14,
            14]))
        #expect(Array(tree.vertices) == Array(0 ..< 31))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 31))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-4.0, 1.0), SIMD2(4.0, 1.0), SIMD2(-6.0, 2.0), SIMD2(-2.0, 2.0), SIMD2(2.0, 2.0),
            SIMD2(6.0, 2.0), SIMD2(-7.0, 3.0), SIMD2(-5.0, 3.0), SIMD2(-3.0, 3.0), SIMD2(-1.0, 3.0), SIMD2(1.0, 3.0), SIMD2(3.0, 3.0), SIMD2(5.0, 3.0),
            SIMD2(7.0, 3.0), SIMD2(-7.5, 4.0), SIMD2(-6.5, 4.0), SIMD2(-5.5, 4.0), SIMD2(-4.5, 4.0), SIMD2(-3.5, 4.0), SIMD2(-2.5, 4.0), SIMD2(-1.5, 4.0),
            SIMD2(-0.5, 4.0), SIMD2(0.5, 4.0), SIMD2(1.5, 4.0), SIMD2(2.5, 4.0), SIMD2(3.5, 4.0), SIMD2(4.5, 4.0), SIMD2(5.5, 4.0), SIMD2(6.5, 4.0),
            SIMD2(7.5, 4.0)])
    }

    @Test("DR-041 left child has two leaves, right is a leaf")
    func dr041() throws {
        // T: [nil, 0, 0, 1, 1]; reingoldTilfordLayout() → [(0.0, 0.0), (-0.5, 1.0), (0.5, 1.0), (-1.0, 2.0), (0.0, 2.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 1, 1]))
        #expect(Array(tree.vertices) == Array(0 ..< 5))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 5))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-0.5, 1.0), SIMD2(0.5, 1.0), SIMD2(-1.0, 2.0), SIMD2(0.0, 2.0)])
    }

    @Test("DR-042 left leaf, right child has two leaves")
    func dr042() throws {
        // T: [nil, 0, 0, 2, 2]; reingoldTilfordLayout() → [(0.0, 0.0), (-0.5, 1.0), (0.5, 1.0), (0.0, 2.0), (1.0, 2.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 2, 2]))
        #expect(Array(tree.vertices) == Array(0 ..< 5))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 5))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-0.5, 1.0), SIMD2(0.5, 1.0), SIMD2(0.0, 2.0), SIMD2(1.0, 2.0)])
    }

    @Test("DR-043 igraph's example shape: one deep child among leaves")
    func dr043() throws {
        // T: [nil, 0, 0, 0, 1, 1]; reingoldTilfordLayout() → [(0.0, 0.0), (-1.0, 1.0), (0.0, 1.0), (1.0, 1.0), (-1.5, 2.0), (-0.5, 2.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 1, 1]))
        #expect(Array(tree.vertices) == Array(0 ..< 6))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 6))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.0, 1.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(-1.5, 2.0), SIMD2(-0.5, 2.0)])
    }

    @Test("DR-044 two chains under a three-way root")
    func dr044() throws {
        // T: [nil, 0, 0, 0, 1, 4, 3, 6]; reingoldTilfordLayout() → [(0.0, 0.0), (-1.0, 1.0), (0.0, 1.0), (1.0, 1.0), (-1.0, 2.0), (-1.0, 3.0), (1.0, 2.0), (1.0, 3.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 1, 4, 3, 6]))
        #expect(Array(tree.vertices) == Array(0 ..< 8))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 8))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.0, 1.0), SIMD2(0.0, 1.0), SIMD2(1.0, 1.0), SIMD2(-1.0, 2.0), SIMD2(-1.0, 3.0),
            SIMD2(1.0, 2.0), SIMD2(1.0, 3.0)])
    }

    @Test("DR-045 Walker's spreading: leaves between two wide subtrees are spaced evenly")
    func dr045() throws {
        // T: [nil, 0, 0, 0, 0, 1, 1, 1, 4, 4, 4]; reingoldTilfordLayout() → [(0.0, 0.0), (-1.5, 1.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0), (-2.5, 2.0), (-1.5, 2.0), (-0.5, 2.0), (0.5, 2.0), (1.5, 2.0), (2.5, 2.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 0, 1, 1, 1, 4, 4, 4]))
        #expect(Array(tree.vertices) == Array(0 ..< 11))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 11))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.5, 1.0), SIMD2(-0.5, 1.0), SIMD2(0.5, 1.0), SIMD2(1.5, 1.0), SIMD2(-2.5, 2.0),
            SIMD2(-1.5, 2.0), SIMD2(-0.5, 2.0), SIMD2(0.5, 2.0), SIMD2(1.5, 2.0), SIMD2(2.5, 2.0)])
    }

    @Test("DR-046 Walker's spreading, deep: wide subtrees meet two levels down")
    func dr046() throws {
        // T: [nil, 0, 0, 0, 0, 1, 4, 5, 5, 5, 6, 6, 6]; reingoldTilfordLayout() → [(0.0, 0.0), (-1.5, 1.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0), (-1.5, 2.0), (1.5, 2.0), (-2.5, 3.0), (-1.5, 3.0), (-0.5, 3.0), (0.5, 3.0), (1.5, 3.0), (2.5, 3.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 0, 1, 4, 5, 5, 5, 6, 6, 6]))
        #expect(Array(tree.vertices) == Array(0 ..< 13))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 13))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.5, 1.0), SIMD2(-0.5, 1.0), SIMD2(0.5, 1.0), SIMD2(1.5, 1.0), SIMD2(-1.5, 2.0),
            SIMD2(1.5, 2.0), SIMD2(-2.5, 3.0), SIMD2(-1.5, 3.0), SIMD2(-0.5, 3.0), SIMD2(0.5, 3.0), SIMD2(1.5, 3.0), SIMD2(2.5, 3.0)])
    }

    @Test("DR-047 a small subtree between two large ones moves to the middle")
    func dr047() throws {
        // T: [nil, 0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 7, 7, 8, 8]; reingoldTilfordLayout() → [(0.0, 0.0), (-2.0, 1.0), (0.0, 1.0), (2.0, 1.0), (-3.0, 2.0), (-1.0, 2.0), (0.0, 2.0), (1.0, 2.0), (3.0, 2.0), (-3.5, 3.0), (-2.5, 3.0), (-1.5, 3.0), (-0.5, 3.0), (0.5, 3.0), (1.5, 3.0), (2.5, 3.0), (3.5, 3.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 7, 7, 8, 8]))
        #expect(Array(tree.vertices) == Array(0 ..< 17))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 17))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-2.0, 1.0), SIMD2(0.0, 1.0), SIMD2(2.0, 1.0), SIMD2(-3.0, 2.0), SIMD2(-1.0, 2.0),
            SIMD2(0.0, 2.0), SIMD2(1.0, 2.0), SIMD2(3.0, 2.0), SIMD2(-3.5, 3.0), SIMD2(-2.5, 3.0), SIMD2(-1.5, 3.0), SIMD2(-0.5, 3.0), SIMD2(0.5, 3.0),
            SIMD2(1.5, 3.0), SIMD2(2.5, 3.0), SIMD2(3.5, 3.0)])
    }

    @Test("DR-048 caterpillar")
    func dr048() throws {
        // T: [nil, 0, 1, 2, 0, 1, 2, 3]; reingoldTilfordLayout() → [(0.0, 0.0), (-0.5, 1.0), (-1.0, 2.0), (-1.5, 3.0), (0.5, 1.0), (0.0, 2.0), (-0.5, 3.0), (-1.5, 4.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 2, 0, 1, 2, 3]))
        #expect(Array(tree.vertices) == Array(0 ..< 8))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 8))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-0.5, 1.0), SIMD2(-1.0, 2.0), SIMD2(-1.5, 3.0), SIMD2(0.5, 1.0), SIMD2(0.0, 2.0),
            SIMD2(-0.5, 3.0), SIMD2(-1.5, 4.0)])
    }

    @Test("DR-049 broom: a path then a fan")
    func dr049() throws {
        // T: [nil, 0, 1, 2, 2, 2, 2]; reingoldTilfordLayout() → [(0.0, 0.0), (0.0, 1.0), (0.0, 2.0), (-1.5, 3.0), (-0.5, 3.0), (0.5, 3.0), (1.5, 3.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 2, 2, 2, 2]))
        #expect(Array(tree.vertices) == Array(0 ..< 7))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 7))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(-1.5, 3.0), SIMD2(-0.5, 3.0), SIMD2(0.5, 3.0), SIMD2(1.5, 3.0)])
    }

    @Test("DR-050 root is not vertex 0")
    func dr050() throws {
        // T: [2, 2, nil, 1]; reingoldTilfordLayout() → [(-0.5, 1.0), (0.5, 1.0), (0.0, 0.0), (0.5, 2.0)]
        let tree = try #require(RootedTree(parents: [2, 2, nil, 1]))
        #expect(Array(tree.vertices) == Array(0 ..< 4))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 4))
        #expect(layout.positions == [SIMD2(-0.5, 1.0), SIMD2(0.5, 1.0), SIMD2(0.0, 0.0), SIMD2(0.5, 2.0)])
    }

    @Test("DR-051 random tree, 20 vertices")
    func dr051() throws {
        // T: lcgtree(20,1); reingoldTilfordLayout() → [(0.0, 0.0), (-0.75, 1.0), (-0.75, 2.0), (0.75, 1.0), (-0.75, 3.0), (-1.25, 4.0), (-2.25, 5.0), (0.25, 2.0), (-2.75, 6.0), (1.25, 2.0), (-1.75, 6.0), (-1.25, 5.0), (-1.75, 7.0), (-0.25, 4.0), (-2.25, 8.0), (-2.25, 9.0), (-1.25, 8.0), (-1.25, 9.0), (-1.25, 10.0), (-0.25, 5.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 0, 2, 4, 5, 3, 6, 3, 6, 5, 10, 4, 12, 14, 12, 16, 17, 5]))
        #expect(Array(tree.vertices) == Array(0 ..< 20))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 20))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-0.75, 1.0), SIMD2(-0.75, 2.0), SIMD2(0.75, 1.0), SIMD2(-0.75, 3.0), SIMD2(-1.25, 4.0),
            SIMD2(-2.25, 5.0), SIMD2(0.25, 2.0), SIMD2(-2.75, 6.0), SIMD2(1.25, 2.0), SIMD2(-1.75, 6.0), SIMD2(-1.25, 5.0), SIMD2(-1.75, 7.0),
            SIMD2(-0.25, 4.0), SIMD2(-2.25, 8.0), SIMD2(-2.25, 9.0), SIMD2(-1.25, 8.0), SIMD2(-1.25, 9.0), SIMD2(-1.25, 10.0), SIMD2(-0.25, 5.0)])
    }

    @Test("DR-052 random tree, 40 vertices")
    func dr052() throws {
        // T: lcgtree(40,7); reingoldTilfordLayout() → [(0.0, 0.0), (-6.0, 1.0), (-8.5, 2.0), (0.5, 1.0), (-4.5, 2.0), (4.0, 1.0), (3.0, 2.0), (6.0, 1.0), (-7.0, 3.0), (-3.0, 3.0), (3.0, 3.0), (6.0, 2.0), (-1.0, 2.0), (-4.5, 4.0), (-1.0, 3.0), (-2.5, 4.0) …
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 0, 1, 0, 5, 0, 4, 4, 6, 7, 3, 9, 12, 9, 2, 13, 3, 1, 11, 16, 15, 9, 18, 3, 8, 26, 13, 13, 22,
            5, 29, 8, 33, 3, 35, 28, 5, 4]))
        #expect(Array(tree.vertices) == Array(0 ..< 40))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 40))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-6.0, 1.0), SIMD2(-8.5, 2.0), SIMD2(0.5, 1.0), SIMD2(-4.5, 2.0), SIMD2(4.0, 1.0),
            SIMD2(3.0, 2.0), SIMD2(6.0, 1.0), SIMD2(-7.0, 3.0), SIMD2(-3.0, 3.0), SIMD2(3.0, 3.0), SIMD2(6.0, 2.0), SIMD2(-1.0, 2.0), SIMD2(-4.5, 4.0),
            SIMD2(-1.0, 3.0), SIMD2(-2.5, 4.0), SIMD2(-8.5, 3.0), SIMD2(-5.5, 5.0), SIMD2(0.0, 2.0), SIMD2(-3.5, 2.0), SIMD2(6.0, 3.0), SIMD2(-8.5, 4.0),
            SIMD2(-2.5, 5.0), SIMD2(-1.5, 4.0), SIMD2(0.0, 3.0), SIMD2(1.0, 2.0), SIMD2(-7.5, 4.0), SIMD2(-7.5, 5.0), SIMD2(-4.5, 5.0), SIMD2(-3.5, 5.0),
            SIMD2(-2.5, 6.0), SIMD2(4.0, 2.0), SIMD2(-3.5, 6.0), SIMD2(-6.5, 4.0), SIMD2(-6.5, 5.0), SIMD2(2.0, 2.0), SIMD2(2.0, 3.0), SIMD2(-4.5, 6.0),
            SIMD2(5.0, 2.0), SIMD2(-2.0, 3.0)])
    }

    @Test("DR-053 random tree, 60 vertices")
    func dr053() throws {
        // T: lcgtree(60,3); reingoldTilfordLayout() → [(0.0, 0.0), (-0.5, 1.0), (-5.03125, 2.0), (-11.59375, 3.0), (-3.125, 3.0), (-6.78125, 4.0), (-10.09375, 5.0), (0.5, 1.0), (-5.46875, 5.0), (-6.84375, 6.0), (-8.09375, 7.0), (-9.09375, 8.0), (-11.0937 …
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 2, 2, 4, 5, 0, 5, 8, 9, 10, 6, 2, 3, 13, 9, 12, 1, 4, 16, 11, 12, 3, 18, 6, 17, 4, 19, 14,
            24, 21, 22, 26, 31, 5, 24, 8, 29, 18, 19, 32, 39, 19, 26, 15, 39, 4, 25, 47, 8, 50, 50, 10, 5, 16, 33, 56, 26, 10]))
        #expect(Array(tree.vertices) == Array(0 ..< 60))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 60))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-0.5, 1.0), SIMD2(-5.03125, 2.0), SIMD2(-11.59375, 3.0), SIMD2(-3.125, 3.0),
            SIMD2(-6.78125, 4.0), SIMD2(-10.09375, 5.0), SIMD2(0.5, 1.0), SIMD2(-5.46875, 5.0), SIMD2(-6.84375, 6.0), SIMD2(-8.09375, 7.0),
            SIMD2(-9.09375, 8.0), SIMD2(-11.09375, 6.0), SIMD2(1.53125, 3.0), SIMD2(-12.09375, 4.0), SIMD2(1.53125, 4.0), SIMD2(-5.59375, 7.0),
            SIMD2(-12.09375, 7.0), SIMD2(4.03125, 2.0), SIMD2(-1.46875, 4.0), SIMD2(-6.09375, 8.0), SIMD2(-9.09375, 9.0), SIMD2(-10.09375, 7.0),
            SIMD2(-11.09375, 4.0), SIMD2(3.03125, 3.0), SIMD2(-9.09375, 6.0), SIMD2(-12.09375, 8.0), SIMD2(-0.46875, 4.0), SIMD2(-2.46875, 5.0),
            SIMD2(-12.09375, 5.0), SIMD2(2.53125, 4.0), SIMD2(-9.09375, 10.0), SIMD2(-10.09375, 8.0), SIMD2(-13.09375, 9.0), SIMD2(-9.09375, 11.0),
            SIMD2(-4.46875, 5.0), SIMD2(3.53125, 4.0), SIMD2(-5.46875, 6.0), SIMD2(-12.09375, 6.0), SIMD2(5.03125, 3.0), SIMD2(-1.46875, 5.0),
            SIMD2(-10.09375, 9.0), SIMD2(4.53125, 4.0), SIMD2(-0.46875, 5.0), SIMD2(-12.09375, 9.0), SIMD2(1.53125, 5.0), SIMD2(5.53125, 4.0),
            SIMD2(0.53125, 4.0), SIMD2(-9.09375, 7.0), SIMD2(0.53125, 5.0), SIMD2(-4.09375, 6.0), SIMD2(-4.59375, 7.0), SIMD2(-3.59375, 7.0),
            SIMD2(-8.09375, 8.0), SIMD2(-3.46875, 5.0), SIMD2(-5.09375, 8.0), SIMD2(-13.09375, 10.0), SIMD2(-13.09375, 11.0), SIMD2(-11.09375, 9.0),
            SIMD2(-7.09375, 8.0)])
    }

    @Test("DR-054 mirror image draws as the reflection: Walker's spreading: leaves between two wide subtrees are spaced evenly")
    func dr054() throws {
        // T: [nil, 0, 1, 1, 1, 0, 0, 0, 7, 7, 7]; reingoldTilfordLayout() → [(0.0, 0.0), (-1.5, 1.0), (-2.5, 2.0), (-1.5, 2.0), (-0.5, 2.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0), (0.5, 2.0), (1.5, 2.0), (2.5, 2.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 1, 1, 0, 0, 0, 7, 7, 7]))
        #expect(Array(tree.vertices) == Array(0 ..< 11))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 11))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.5, 1.0), SIMD2(-2.5, 2.0), SIMD2(-1.5, 2.0), SIMD2(-0.5, 2.0), SIMD2(-0.5, 1.0),
            SIMD2(0.5, 1.0), SIMD2(1.5, 1.0), SIMD2(0.5, 2.0), SIMD2(1.5, 2.0), SIMD2(2.5, 2.0)])
    }

    @Test("DR-055 mirror image draws as the reflection: Walker's spreading, deep: wide subtrees meet two levels down")
    func dr055() throws {
        // T: [nil, 0, 1, 2, 2, 2, 0, 0, 0, 8, 9, 9, 9]; reingoldTilfordLayout() → [(0.0, 0.0), (-1.5, 1.0), (-1.5, 2.0), (-2.5, 3.0), (-1.5, 3.0), (-0.5, 3.0), (-0.5, 1.0), (0.5, 1.0), (1.5, 1.0), (1.5, 2.0), (0.5, 3.0), (1.5, 3.0), (2.5, 3.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 2, 2, 2, 0, 0, 0, 8, 9, 9, 9]))
        #expect(Array(tree.vertices) == Array(0 ..< 13))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 13))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-1.5, 1.0), SIMD2(-1.5, 2.0), SIMD2(-2.5, 3.0), SIMD2(-1.5, 3.0), SIMD2(-0.5, 3.0),
            SIMD2(-0.5, 1.0), SIMD2(0.5, 1.0), SIMD2(1.5, 1.0), SIMD2(1.5, 2.0), SIMD2(0.5, 3.0), SIMD2(1.5, 3.0), SIMD2(2.5, 3.0)])
    }

    @Test("DR-056 mirror image draws as the reflection: a small subtree between two large ones moves to the middle")
    func dr056() throws {
        // T: [nil, 0, 1, 2, 2, 1, 5, 5, 0, 8, 0, 10, 11, 11, 10, 14, 14]; reingoldTilfordLayout() → [(0.0, 0.0), (-2.0, 1.0), (-3.0, 2.0), (-3.5, 3.0), (-2.5, 3.0), (-1.0, 2.0), (-1.5, 3.0), (-0.5, 3.0), (0.0, 1.0), (0.0, 2.0), (2.0, 1.0), (1.0, 2.0), (0.5, 3.0), (1.5, 3.0), (3.0, 2.0), (2.5, 3.0), (3.5, 3.0)]
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 2, 2, 1, 5, 5, 0, 8, 0, 10, 11, 11, 10, 14, 14]))
        #expect(Array(tree.vertices) == Array(0 ..< 17))
        let layout = tree.reingoldTilfordLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 17))
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(-2.0, 1.0), SIMD2(-3.0, 2.0), SIMD2(-3.5, 3.0), SIMD2(-2.5, 3.0), SIMD2(-1.0, 2.0),
            SIMD2(-1.5, 3.0), SIMD2(-0.5, 3.0), SIMD2(0.0, 1.0), SIMD2(0.0, 2.0), SIMD2(2.0, 1.0), SIMD2(1.0, 2.0), SIMD2(0.5, 3.0), SIMD2(1.5, 3.0),
            SIMD2(3.0, 2.0), SIMD2(2.5, 3.0), SIMD2(3.5, 3.0)])
    }

    @Test("DR-057 isomorphic subtrees are drawn identically (translated)")
    func dr057() throws {
        // T: bal(2,3); x(subtree of 1) − x(1) == x(subtree of 2) − x(2) → true
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]))
        #expect(Array(tree.vertices) == Array(0 ..< 15))
        let layout = tree.reingoldTilfordLayout()
        // The subtrees of 1 and 2, each with its root.
        let left = [1, 3, 4, 7, 8, 9, 10], right = [2, 5, 6, 11, 12, 13, 14]
        #expect(left.allSatisfy { $0 == 1 || tree.isAncestor(1, of: $0) } && right.allSatisfy { $0 == 2 || tree.isAncestor(2, of: $0) })
        let p1 = layout.position(of: 1), p2 = layout.position(of: 2)
        // As point sets: the order of `descendants(of:)` is not what is pinned.
        let leftOffsets = try left.map { try layout.position(checked: $0) - p1 }.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        let rightOffsets = try right.map { try layout.position(checked: $0) - p2 }.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        #expect(leftOffsets == rightOffsets && leftOffsets.count == 7)
        // The two subtrees do not overlap: every x of the left one is left of every x of the right one at its depth.
        #expect(try left.map { try layout.position(checked: $0).x }.max()! < right.map { try layout.position(checked: $0).x }.min()!)
    }

    @Test("DR-058 circular: one vertex")
    func dr058() throws {
        // T: [nil]; reingoldTilfordCircularLayout() → [(0.0, 0.0)]
        let tree = try #require(RootedTree(parents: [nil]))
        #expect(Array(tree.vertices) == Array(0 ..< 1))
        let layout = tree.reingoldTilfordCircularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 1))
        let expected: [SIMD2<Double>] = [SIMD2(0.0, 0.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // The radius of each vertex is its depth.
        for v in tree.vertices {
            let p = try layout.position(checked: v)
            #expect(abs((p * p).sum().squareRoot() - Double(tree.depth(of: v))) <= 1e-9)
        }
    }

    @Test("DR-059 circular: star K1,4")
    func dr059() throws {
        // T: [nil, 0, 0, 0, 0]; reingoldTilfordCircularLayout() → [(0.0, 0.0), (1.0, 0.0), (-0.104528463268, 0.994521895368), (-0.978147600734, -0.207911690818), (0.309016994375, -0.951056516295)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 0]))
        #expect(Array(tree.vertices) == Array(0 ..< 5))
        let layout = tree.reingoldTilfordCircularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 5))
        let expected: [SIMD2<Double>] = [SIMD2(-0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(-0.10452846326765333, 0.9945218953682734),
            SIMD2(-0.9781476007338057, -0.20791169081775907), SIMD2(0.30901699437494723, -0.9510565162951536)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // The radius of each vertex is its depth.
        for v in tree.vertices {
            let p = try layout.position(checked: v)
            #expect(abs((p * p).sum().squareRoot() - Double(tree.depth(of: v))) <= 1e-9)
        }
    }

    @Test("DR-060 circular: igraph's example shape")
    func dr060() throws {
        // T: [nil, 0, 0, 0, 1, 1]; reingoldTilfordCircularLayout() → [(0.0, 0.0), (0.5, 0.866025403784), (-1.0, 0.0), (0.5, -0.866025403784), (2.0, 0.0), (-1.0, 1.732050807569)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 1, 1]))
        #expect(Array(tree.vertices) == Array(0 ..< 6))
        let layout = tree.reingoldTilfordCircularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 6))
        let expected: [SIMD2<Double>] = [SIMD2(-0.0, -0.0), SIMD2(0.4999999999999999, 0.8660254037844387), SIMD2(-1.0, -3.216245299353273e-16),
            SIMD2(0.5000000000000009, -0.8660254037844382), SIMD2(2.0, 0.0), SIMD2(-1.0000000000000004, 1.7320508075688772)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // The radius of each vertex is its depth.
        for v in tree.vertices {
            let p = try layout.position(checked: v)
            #expect(abs((p * p).sum().squareRoot() - Double(tree.depth(of: v))) <= 1e-9)
        }
    }

    @Test("DR-061 circular: binary tree of height 3")
    func dr061() throws {
        // T: bal(2,3); reingoldTilfordCircularLayout() → [(0.0, 0.0), (0.309016994375, 0.951056516295), (-0.104528463268, -0.994521895368), (1.827090915285, 0.813473286152), (-1.0, 1.732050807569), (-1.61803398875, -1.175570504585), (1.338261212718, -1.4862 …
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6]))
        #expect(Array(tree.vertices) == Array(0 ..< 15))
        let layout = tree.reingoldTilfordCircularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 15))
        let expected: [SIMD2<Double>] = [SIMD2(-0.0, 0.0), SIMD2(0.30901699437494745, 0.9510565162951535), SIMD2(-0.10452846326765336, -0.9945218953682734),
            SIMD2(1.8270909152852017, 0.8134732861516004), SIMD2(-1.0000000000000004, 1.7320508075688772), SIMD2(-1.6180339887498945, -1.1755705045849467),
            SIMD2(1.338261212717717, -1.486289650954788), SIMD2(3.0, 0.0), SIMD2(2.0073918190765747, 2.229434476432183),
            SIMD2(-0.3135853898029607, 2.9835656861048196), SIMD2(-2.427050983124842, 1.7633557568774196), SIMD2(-2.9344428022014166, -0.6237350724532785),
            SIMD2(-1.499999999999999, -2.5980762113533165), SIMD2(0.9270509831248417, -2.853169548885461), SIMD2(2.7406363729278027, -1.2202099292274005)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // The radius of each vertex is its depth.
        for v in tree.vertices {
            let p = try layout.position(checked: v)
            #expect(abs((p * p).sum().squareRoot() - Double(tree.depth(of: v))) <= 1e-9)
        }
    }

    @Test("DR-062 circular: two chains under a three-way root")
    func dr062() throws {
        // T: [nil, 0, 0, 0, 1, 4, 3, 6]; reingoldTilfordCircularLayout() → [(0.0, 0.0), (1.0, 0.0), (-0.923879532511, 0.382683432365), (0.707106781187, -0.707106781187), (2.0, 0.0), (3.0, 0.0), (1.414213562373, -1.414213562373), (2.12132034356, -2.12132034356)]
        let tree = try #require(RootedTree(parents: [nil, 0, 0, 0, 1, 4, 3, 6]))
        #expect(Array(tree.vertices) == Array(0 ..< 8))
        let layout = tree.reingoldTilfordCircularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 8))
        let expected: [SIMD2<Double>] = [SIMD2(-0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(-0.9238795325112867, 0.3826834323650899),
            SIMD2(0.7071067811865474, -0.7071067811865477), SIMD2(2.0, 0.0), SIMD2(3.0, 0.0), SIMD2(1.4142135623730947, -1.4142135623730954),
            SIMD2(2.121320343559642, -2.121320343559643)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // The radius of each vertex is its depth.
        for v in tree.vertices {
            let p = try layout.position(checked: v)
            #expect(abs((p * p).sum().squareRoot() - Double(tree.depth(of: v))) <= 1e-9)
        }
    }

    @Test("DR-063 circular: random tree, 20 vertices")
    func dr063() throws {
        // T: lcgtree(20,1); reingoldTilfordCircularLayout() → [(0.0, 0.0), (-0.987688340595, 0.15643446504), (-1.97537668119, 0.31286893008), (0.488621241497, -0.872496007073), (-2.963065021785, 0.469303395121), (-2.476375797239, 3.141267723523), (3.671612547178 …
        let tree = try #require(RootedTree(parents: [nil, 0, 1, 0, 2, 4, 5, 3, 6, 3, 6, 5, 10, 4, 12, 14, 12, 16, 17, 5]))
        #expect(Array(tree.vertices) == Array(0 ..< 20))
        let layout = tree.reingoldTilfordCircularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 20))
        let expected: [SIMD2<Double>] = [SIMD2(-0.0, -0.0), SIMD2(-0.9876883405951377, 0.15643446504023098), SIMD2(-1.9753766811902753, 0.31286893008046196),
            SIMD2(0.48862124149695496, -0.8724960070727971), SIMD2(-2.963065021785413, 0.46930339512069297), SIMD2(-2.4763757972393363, 3.1412677235229793),
            SIMD2(3.6716125471784276, 3.394003727664709), SIMD2(-0.4668907277118103, -1.9447398407953533), SIMD2(6.0, 0.0),
            SIMD2(1.902113032590307, -0.6180339887498953), SIMD2(0.47075457436707, 5.981504002398768), SIMD2(-3.0954697465491705, 3.926584654403724),
            SIMD2(0.549213670094915, 6.978421336131896), SIMD2(-3.325878449210182, -2.222280932078408), SIMD2(5.874580075485484, 5.430405964263534),
            SIMD2(6.60890258492117, 6.109206709796476), SIMD2(-4.952751594478673, 6.282535447045959), SIMD2(-5.571845543788506, 7.0678523779267035),
            SIMD2(-6.190939493098341, 7.853169308807448), SIMD2(-4.157348061512727, -2.77785116509801)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // The radius of each vertex is its depth.
        for v in tree.vertices {
            let p = try layout.position(checked: v)
            #expect(abs((p * p).sum().squareRoot() - Double(tree.depth(of: v))) <= 1e-9)
        }
    }
}
