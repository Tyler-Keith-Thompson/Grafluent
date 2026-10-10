// Mutation (catalog BP-119 – BP-141): `insert(_:on:)`, `insert(edge:)`, `remove(_:)`,
// `remove(edge:)`, `removeAllEdges()`, `removeAll()`, with each call's result and the final
// `vertices`, `left`, `right` and `edges` (as [u, v], left endpoint first). Removing a vertex
// moves the last slot into its place (as `UndirectedAdjacencyList` does) and the side's last
// vertex into its place in `left` or `right`; removing an edge moves the last edge into its
// position. A vertex keeps its side when its edges go. BP-141 is ref.py's `random_ops(7)`
// written out, with every intermediate result as the model gives it. Generated from cases.md
// by swiftgen.py; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import Testing

@Suite("BipartiteGraph mutation")
struct BipartiteGraphMutationTests {
    @Test("BP-119 insert a left vertex into an empty graph")
    func bp119() throws {
        // left [], right []; insert("a", on: .left)
        var graph = BipartiteGraph<String>()
        do { let result = graph.insert("a", on: .left); #expect(result.inserted); #expect(result.memberAfterInsert == "a") }
        // Final state.
        #expect(Array(graph.vertices) == ["a"] as [String])
        #expect(Array(graph.left) == ["a"] as [String])
        #expect(Array(graph.right) == [] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-120 insert vertices on both sides, then an edge")
    func bp120() throws {
        // left [], right []; insert("a", on: .left); insert("x", on: .right); insert(edge: a–x)
        var graph = BipartiteGraph<String>()
        do { let result = graph.insert("a", on: .left); #expect(result.inserted); #expect(result.memberAfterInsert == "a") }
        do { let result = graph.insert("x", on: .right); #expect(result.inserted); #expect(result.memberAfterInsert == "x") }
        do { let result = graph.insert(edge: UndirectedEdge("a", "x")); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == ["a", "x"]) }
        // Final state.
        #expect(Array(graph.vertices) == ["a", "x"] as [String])
        #expect(Array(graph.left) == ["a"] as [String])
        #expect(Array(graph.right) == ["x"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-121 insert an edge given right endpoint first")
    func bp121() throws {
        // left [], right []; insert("a", on: .left); insert("x", on: .right); insert(edge: x–a)
        var graph = BipartiteGraph<String>()
        do { let result = graph.insert("a", on: .left); #expect(result.inserted); #expect(result.memberAfterInsert == "a") }
        do { let result = graph.insert("x", on: .right); #expect(result.inserted); #expect(result.memberAfterInsert == "x") }
        do { let result = graph.insert(edge: UndirectedEdge("x", "a")); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == ["a", "x"]) }
        // Final state.
        #expect(Array(graph.vertices) == ["a", "x"] as [String])
        #expect(Array(graph.left) == ["a"] as [String])
        #expect(Array(graph.right) == ["x"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-122 insert an existing vertex on its side: not inserted")
    func bp122() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert("a", on: .left)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        do { let result = graph.insert("a", on: .left); #expect(!result.inserted); #expect(result.memberAfterInsert == "a") }
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"], ["b", "y"], ["c", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-123 insert an existing edge, reversed: not inserted")
    func bp123() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: x–a)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        do { let result = graph.insert(edge: UndirectedEdge("x", "a")); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == ["a", "x"]) }
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"], ["b", "y"], ["c", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-124 remove the first edge: the last edge moves into position 0")
    func bp124() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: a–x)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        do { let removed = graph.remove(edge: UndirectedEdge("a", "x")); #expect(removed.map { [$0.u, $0.v] } == ["a", "x"]) }
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["c", "y"], ["b", "x"], ["b", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-125 remove the last edge")
    func bp125() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: c–y)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        do { let removed = graph.remove(edge: UndirectedEdge("c", "y")); #expect(removed.map { [$0.u, $0.v] } == ["c", "y"]) }
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"], ["b", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-126 remove an absent edge across sides")
    func bp126() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: a–y)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove(edge: UndirectedEdge("a", "y")) == nil)
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"], ["b", "y"], ["c", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-127 remove an edge with a non-vertex endpoint")
    func bp127() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: a–zz)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove(edge: UndirectedEdge("a", "zz")) == nil)
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"], ["b", "y"], ["c", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-128 remove a left vertex: last slot moves in, left list swap-removed")
    func bp128() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("a")
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove("a") == "a")
        // Final state.
        #expect(Array(graph.vertices) == ["y", "b", "c", "x"] as [String])
        #expect(Array(graph.left) == ["c", "b"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["c", "y"], ["b", "x"], ["b", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-129 remove the last vertex")
    func bp129() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("y")
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove("y") == "y")
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-130 remove a right vertex of degree 2")
    func bp130() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("x")
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove("x") == "x")
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["b", "y"], ["c", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-131 remove a non-vertex")
    func bp131() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("q")
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove("q") == nil)
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"], ["b", "y"], ["c", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-132 remove then reinsert a vertex on the other side")
    func bp132() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("a"); insert("a", on: .right); insert(edge: a–b)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove("a") == "a")
        do { let result = graph.insert("a", on: .right); #expect(result.inserted); #expect(result.memberAfterInsert == "a") }
        do { let result = graph.insert(edge: UndirectedEdge("a", "b")); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == ["b", "a"]) }
        // Final state.
        #expect(Array(graph.vertices) == ["y", "b", "c", "x", "a"] as [String])
        #expect(Array(graph.left) == ["c", "b"] as [String])
        #expect(Array(graph.right) == ["x", "y", "a"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["c", "y"], ["b", "x"], ["b", "y"], ["b", "a"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-133 remove every edge, keep the vertices")
    func bp133() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; removeAllEdges()
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        graph.removeAllEdges()
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-134 remove everything")
    func bp134() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; removeAll()
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        graph.removeAll()
        // Final state.
        #expect(Array(graph.vertices) == [] as [String])
        #expect(Array(graph.left) == [] as [String])
        #expect(Array(graph.right) == [] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-135 remove every vertex one by one")
    func bp135() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("a"); remove("b"); remove("c"); remove("x"); remove("y")
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove("a") == "a")
        #expect(graph.remove("b") == "b")
        #expect(graph.remove("c") == "c")
        #expect(graph.remove("x") == "x")
        #expect(graph.remove("y") == "y")
        // Final state.
        #expect(Array(graph.vertices) == [] as [String])
        #expect(Array(graph.left) == [] as [String])
        #expect(Array(graph.right) == [] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-136 build K2,2 then remove a perfect matching")
    func bp136() throws {
        // left [0, 1], right [2, 3], edges [0–2, 0–3, 1–2, 1–3]; remove(edge: 0–2); remove(edge: 1–3)
        var graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3] as [Int], edges: [(0, 2), (0, 3), (1, 2), (1, 3)].map { UndirectedEdge<Int>($0.0, $0.1) }))
        do { let removed = graph.remove(edge: UndirectedEdge(0, 2)); #expect(removed.map { [$0.u, $0.v] } == [0, 2]) }
        do { let removed = graph.remove(edge: UndirectedEdge(1, 3)); #expect(removed.map { [$0.u, $0.v] } == [1, 3]) }
        // Final state.
        #expect(Array(graph.vertices) == [0, 1, 2, 3] as [Int])
        #expect(Array(graph.left) == [0, 1] as [Int])
        #expect(Array(graph.right) == [2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[1, 2], [0, 3]] as [[Int]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-137 insert, remove, insert the same edge")
    func bp137() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: b–y); insert(edge: y–b)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        do { let removed = graph.remove(edge: UndirectedEdge("b", "y")); #expect(removed.map { [$0.u, $0.v] } == ["b", "y"]) }
        do { let result = graph.insert(edge: UndirectedEdge("y", "b")); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == ["b", "y"]) }
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"], ["c", "y"], ["b", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-138 isolated vertex stays on its side after its edges go")
    func bp138() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove(edge: c–y); side(of: "c")
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        do { let removed = graph.remove(edge: UndirectedEdge("c", "y")); #expect(removed.map { [$0.u, $0.v] } == ["c", "y"]) }
        #expect(graph.side(of: "c") == .left)
        // Final state.
        #expect(Array(graph.vertices) == ["a", "b", "c", "x", "y"] as [String])
        #expect(Array(graph.left) == ["a", "b", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["b", "x"], ["b", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-139 side(of:) after the slot moved")
    func bp139() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("b"); side(of: "y"); side(of: "c")
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove("b") == "b")
        #expect(graph.side(of: "y") == .right)
        #expect(graph.side(of: "c") == .left)
        // Final state.
        #expect(Array(graph.vertices) == ["a", "y", "c", "x"] as [String])
        #expect(Array(graph.left) == ["a", "c"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["c", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-140 projection still correct after mutation")
    func bp140() throws {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("b"); insert("d", on: .left); insert(edge: d–x); insert(edge: d–y); projectedGraph(onto: .left)
        var graph = try #require(BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) }))
        #expect(graph.remove("b") == "b")
        do { let result = graph.insert("d", on: .left); #expect(result.inserted); #expect(result.memberAfterInsert == "d") }
        do { let result = graph.insert(edge: UndirectedEdge("d", "x")); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == ["d", "x"]) }
        do { let result = graph.insert(edge: UndirectedEdge("d", "y")); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == ["d", "y"]) }
        let projection = graph.projectedGraph(onto: .left)
        #expect(Array(projection.vertices) == ["a", "c", "d"] as [String])
        #expect(projection.edges.map { [$0.u, $0.v] } == [["a", "d"], ["c", "d"]] as [[String]])
        // Final state.
        #expect(Array(graph.vertices) == ["a", "y", "c", "x", "d"] as [String])
        #expect(Array(graph.left) == ["a", "c", "d"] as [String])
        #expect(Array(graph.right) == ["x", "y"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["a", "x"], ["c", "y"], ["d", "x"], ["d", "y"]] as [[String]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }

    @Test("BP-141 long random sequence (seed 7)")
    func bp141() throws {
        // from empty, 37 random operations (ref.py `random_ops(7)`)
        var graph = BipartiteGraph<Int>()
        do { let result = graph.insert(6, on: .left); #expect(result.inserted); #expect(result.memberAfterInsert == 6) }
        do { let result = graph.insert(8, on: .left); #expect(result.inserted); #expect(result.memberAfterInsert == 8) }
        do { let result = graph.insert(8, on: .left); #expect(!result.inserted); #expect(result.memberAfterInsert == 8) }
        do { let result = graph.insert(1, on: .right); #expect(result.inserted); #expect(result.memberAfterInsert == 1) }
        do { let result = graph.insert(edge: UndirectedEdge(6, 1)); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [6, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(1, 6)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [6, 1]) }
        do { let removed = graph.remove(edge: UndirectedEdge(1, 6)); #expect(removed.map { [$0.u, $0.v] } == [6, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(1, 8)); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 1]) }
        do { let result = graph.insert(8, on: .left); #expect(!result.inserted); #expect(result.memberAfterInsert == 8) }
        do { let result = graph.insert(edge: UndirectedEdge(1, 8)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(8, 1)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(6, 1)); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [6, 1]) }
        do { let removed = graph.remove(edge: UndirectedEdge(6, 1)); #expect(removed.map { [$0.u, $0.v] } == [6, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(1, 6)); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [6, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(1, 8)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(8, 1)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 1]) }
        do { let result = graph.insert(11, on: .left); #expect(result.inserted); #expect(result.memberAfterInsert == 11) }
        do { let result = graph.insert(9, on: .right); #expect(result.inserted); #expect(result.memberAfterInsert == 9) }
        do { let result = graph.insert(edge: UndirectedEdge(9, 8)); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 9]) }
        do { let result = graph.insert(edge: UndirectedEdge(11, 1)); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [11, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(6, 9)); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [6, 9]) }
        do { let result = graph.insert(edge: UndirectedEdge(1, 8)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 1]) }
        do { let result = graph.insert(8, on: .left); #expect(!result.inserted); #expect(result.memberAfterInsert == 8) }
        do { let result = graph.insert(edge: UndirectedEdge(9, 11)); #expect(result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [11, 9]) }
        do { let result = graph.insert(edge: UndirectedEdge(1, 8)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(8, 1)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [8, 1]) }
        do { let removed = graph.remove(edge: UndirectedEdge(1, 11)); #expect(removed.map { [$0.u, $0.v] } == [11, 1]) }
        do { let result = graph.insert(edge: UndirectedEdge(9, 11)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [11, 9]) }
        do { let result = graph.insert(edge: UndirectedEdge(6, 9)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [6, 9]) }
        do { let result = graph.insert(edge: UndirectedEdge(6, 9)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [6, 9]) }
        #expect(graph.remove(8) == 8)
        do { let result = graph.insert(edge: UndirectedEdge(11, 9)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [11, 9]) }
        do { let result = graph.insert(edge: UndirectedEdge(9, 11)); #expect(!result.inserted); #expect([result.memberAfterInsert.u, result.memberAfterInsert.v] == [11, 9]) }
        #expect(graph.remove(11) == 11)
        #expect(graph.remove(edge: UndirectedEdge(1, 9)) == nil)
        do { let removed = graph.remove(edge: UndirectedEdge(1, 6)); #expect(removed.map { [$0.u, $0.v] } == [6, 1]) }
        do { let result = graph.insert(1, on: .right); #expect(!result.inserted); #expect(result.memberAfterInsert == 1) }
        // Final state.
        #expect(Array(graph.vertices) == [6, 9, 1] as [Int])
        #expect(Array(graph.left) == [6] as [Int])
        #expect(Array(graph.right) == [1, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[6, 9]] as [[Int]])
        for v in graph.left { #expect(graph.side(of: v) == .left) }
        for v in graph.right { #expect(graph.side(of: v) == .right) }
    }
}
