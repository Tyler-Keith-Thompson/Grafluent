// §D: parent functions. `init?(parents: [Int?])` (vertex i has parent parents[i], exactly one nil)
// and `init?(vertices:parent:)` (the closure gives each vertex's parent, nil for the root), on both
// `Arborescence` and `RootedTree`. The listed vertices with duplicates dropped are the vertices; one
// edge per non-root vertex, in vertex order, `(parent, child)` (igraph's
// `tree_from_parent_vector`), so children come in vertex order. Nil for no root or several, a
// parent outside the vertices, a self-parent, a negative entry, a cycle, or no vertices. A throwing
// closure's error propagates. Expected values come from the catalog's reference (`ref.py`). Case
// IDs (TS-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Trees from parent functions")
struct ParentFunctionTests {
    @Test("TS-150 Arborescence(parents: [nil]).root is 0")
    func singleRoot() throws {
        // parents: [_]
        let arborescence = try #require(Arborescence(parents: [nil]))
        #expect(arborescence.root == 0)
        #expect(arborescence.edgeCount == 0)
        let rooted = try #require(RootedTree(parents: [nil]))
        #expect(rooted.root == 0)
    }

    @Test("TS-151 Arborescence(parents: [nil, 0, 0, 1]).edges is [0>1, 0>2, 1>3]: one edge per non-root, in vertex order")
    func edgesInVertexOrder() throws {
        // parents: [_,0,0,1]
        let arborescence = try #require(Arborescence(parents: [nil, 0, 0, 1]))
        let expected: [(Int, Int)] = [(0, 1), (0, 2), (1, 3)]
        #expect(Array(arborescence.edges) == expected.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(arborescence.vertices) == [0, 1, 2, 3])
        let rooted = try #require(RootedTree(parents: [nil, 0, 0, 1]))
        #expect(Array(rooted.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-152 Arborescence(parents: [1, nil]).root is 1")
    func rootNotFirst() throws {
        // parents: [1,_]
        let arborescence = try #require(Arborescence(parents: [1, nil]))
        #expect(arborescence.root == 1)
        let rooted = try #require(RootedTree(parents: [1, nil]))
        #expect(rooted.root == 1)
    }

    @Test("TS-153 Arborescence(parents: [nil, nil]) is nil: two roots")
    func twoRoots() {
        // parents: [_,_]
        #expect(Arborescence(parents: [nil, nil]) == nil)
        #expect(RootedTree(parents: [nil, nil]) == nil)
    }

    @Test("TS-154 Arborescence(parents: [1, 0]) is nil: no root")
    func noRoot() {
        // parents: [1,0]
        #expect(Arborescence(parents: [1, 0]) == nil)
        #expect(RootedTree(parents: [1, 0]) == nil)
    }

    @Test("TS-155 Arborescence(parents: [0]) is nil: a self-parent is not a root marker")
    func selfParent() {
        // parents: [0]. Boost marks the root with p[r] == r; igraph rejects it, and so do we.
        #expect(Arborescence(parents: [0]) == nil)
        #expect(RootedTree(parents: [0]) == nil)
        #expect(Arborescence(parents: [nil, 1]) == nil)
    }

    @Test("TS-156 Arborescence(parents: [nil, 5]) is nil: a parent that is not a vertex")
    func parentOutOfRange() {
        // parents: [_,5]
        #expect(Arborescence(parents: [nil, 5]) == nil)
        #expect(RootedTree(parents: [nil, 5]) == nil)
        #expect(Arborescence(parents: [nil, 2]) == nil)
    }

    @Test("TS-157 Arborescence(parents: [nil, 2, 1]) is nil: a root and a 2-cycle beside it")
    func rootBesideACycle() {
        // parents: [_,2,1]
        #expect(Arborescence(parents: [nil, 2, 1]) == nil)
        #expect(RootedTree(parents: [nil, 2, 1]) == nil)
    }

    @Test("TS-158 Arborescence(parents: [nil, -1]) is nil: a negative entry is out of range, not a root")
    func negativeIsNotARoot() {
        // parents: [_,-1]. igraph uses negatives for roots; Swift has Optional.
        #expect(Arborescence(parents: [nil, -1]) == nil)
        #expect(RootedTree(parents: [nil, -1]) == nil)
        #expect(Arborescence(parents: [-1]) == nil)
    }

    @Test("TS-159 Arborescence(parents: []) is nil: no vertices")
    func empty() {
        // parents: []
        #expect(Arborescence(parents: []) == nil)
        #expect(RootedTree(parents: []) == nil)
        let none: [String: String] = [:]
        #expect(Arborescence<String>(vertices: [], parent: { none[$0] }) == nil)
    }

    @Test("TS-160 Arborescence(parents: [3, 3, 1, nil, 1]).children(of: 1) is [2, 4]: children in vertex order")
    func childrenInVertexOrder() throws {
        // parents: [3,3,1,_,1]
        let arborescence = try #require(Arborescence(parents: [3, 3, 1, nil, 1]))
        #expect(Array(arborescence.children(of: 1)) == [2, 4])
        #expect(arborescence.root == 3)
        let rooted = try #require(RootedTree(parents: [3, 3, 1, nil, 1]))
        #expect(Array(rooted.children(of: 1)) == [2, 4])
    }

    @Test("TS-161 RootedTree(parents: [3, 3, 1, nil, 1]).preorder is [3, 0, 1, 2, 4]")
    func preorderFromParents() throws {
        // parents: [3,3,1,_,1]
        let rooted = try #require(RootedTree(parents: [3, 3, 1, nil, 1]))
        #expect(Array(rooted.preorder) == [3, 0, 1, 2, 4])
        let arborescence = try #require(Arborescence(parents: [3, 3, 1, nil, 1]))
        #expect(Array(arborescence.preorder) == [3, 0, 1, 2, 4])
    }

    @Test("TS-162 Arborescence(vertices: [a, b, c, d], parent:).edges is [a>b, a>c, c>d]")
    func closureEdges() throws {
        // closure: [a,b,c,d] {b:a, c:a, d:c}
        let parents: [String: String] = ["b": "a", "c": "a", "d": "c"]
        let arborescence = try #require(Arborescence(vertices: ["a", "b", "c", "d"], parent: { parents[$0] }))
        let expected: [(String, String)] = [("a", "b"), ("a", "c"), ("c", "d")]
        #expect(Array(arborescence.edges) == expected.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(arborescence.root == "a")
    }

    @Test("TS-163 Arborescence(vertices: [d, c, b, a], parent:).edges is [c>d, a>c, a>b]: vertex order decides positions")
    func closureVertexOrderDecidesPositions() throws {
        // closure: [d,c,b,a] {b:a, c:a, d:c}
        let parents: [String: String] = ["b": "a", "c": "a", "d": "c"]
        let arborescence = try #require(Arborescence(vertices: ["d", "c", "b", "a"], parent: { parents[$0] }))
        let expected: [(String, String)] = [("c", "d"), ("a", "c"), ("a", "b")]
        #expect(Array(arborescence.edges) == expected.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(arborescence.vertices) == ["d", "c", "b", "a"])
        let rooted = try #require(RootedTree(vertices: ["d", "c", "b", "a"], parent: { parents[$0] }))
        #expect(Array(rooted.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-164 Arborescence(vertices: [a, b, c], parent:) is nil: a parent outside the vertices")
    func closureParentOutside() {
        // closure: [a,b,c] {b:a, c:z}
        let parents: [String: String] = ["b": "a", "c": "z"]
        #expect(Arborescence(vertices: ["a", "b", "c"], parent: { parents[$0] }) == nil)
        #expect(RootedTree(vertices: ["a", "b", "c"], parent: { parents[$0] }) == nil)
    }

    @Test("TS-165 Arborescence(vertices: [a, b, b, c], parent:).vertices is [a, b, c]: a duplicate is dropped")
    func closureDuplicateDropped() throws {
        // closure: [a,b,b,c] {b:a, c:b}
        let parents: [String: String] = ["b": "a", "c": "b"]
        let arborescence = try #require(Arborescence(vertices: ["a", "b", "b", "c"], parent: { parents[$0] }))
        #expect(Array(arborescence.vertices) == ["a", "b", "c"])
        #expect(arborescence.edgeCount == 2)
    }

    @Test("TS-166 RootedTree(vertices: [a, b, c], parent:) is nil: a 3-cycle of parents")
    func closureCycle() {
        // closure: [a,b,c] {a:b, b:c, c:a}
        let parents: [String: String] = ["a": "b", "b": "c", "c": "a"]
        #expect(RootedTree(vertices: ["a", "b", "c"], parent: { parents[$0] }) == nil)
        #expect(Arborescence(vertices: ["a", "b", "c"], parent: { parents[$0] }) == nil)
    }

    @Test("TS-167 RootedTree(vertices: [r], parent:).root is r")
    func closureSingleVertex() throws {
        // closure: [r] {}
        let parents: [String: String] = [:]
        let rooted = try #require(RootedTree(vertices: ["r"], parent: { parents[$0] }))
        #expect(rooted.root == "r")
        #expect(rooted.edgeCount == 0)
    }

    @Test("TS-168 Arborescence(parents: [nil, 0, 1, …, 8]).depth(of: 9) is 9")
    func deepFromParents() throws {
        // parents: [_,0,1,2,3,4,5,6,7,8]
        let arborescence = try #require(Arborescence(parents: [nil, 0, 1, 2, 3, 4, 5, 6, 7, 8]))
        #expect(arborescence.depth(of: 9) == 9)
        #expect(arborescence.height == 9)
    }

    @Test("TS-169 Arborescence(vertices:parent:) == Arborescence(D: a>b, b>c, c>d): same vertices and arcs")
    func closureEqualsGraph() throws {
        // closure: [a,b,c,d] {b:a, c:b, d:c}
        let parents: [String: String] = ["b": "a", "c": "b", "d": "c"]
        let fromParents = try #require(Arborescence(vertices: ["a", "b", "c", "d"], parent: { parents[$0] }))
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let fromGraph = try #require(Arborescence(graph))
        #expect(fromParents == fromGraph)
        #expect(fromParents.hashValue == fromGraph.hashValue)
    }

    @Test("A throwing parent function's error propagates out of the initializer")
    func errorPropagates() {
        struct Unknown: Error, Equatable { let vertex: String }
        let parents: [String: String] = ["b": "a"]
        #expect(throws: Unknown(vertex: "c")) {
            _ = try Arborescence(vertices: ["a", "b", "c"]) { (v: String) throws(Unknown) -> String? in
                guard v != "c" else { throw Unknown(vertex: v) }
                return parents[v]
            }
        }
        #expect(throws: Unknown(vertex: "c")) {
            _ = try RootedTree(vertices: ["a", "b", "c"]) { (v: String) throws(Unknown) -> String? in
                guard v != "c" else { throw Unknown(vertex: v) }
                return parents[v]
            }
        }
        // Not throwing, the same closure shape builds the tree.
        let built = try? Arborescence(vertices: ["a", "b"]) { (v: String) throws(Unknown) -> String? in parents[v] }
        #expect(built?.root == "a")
    }

    @Test("A parent function's children come in vertex order, as DominatorTree's do")
    func dominatorTreeOrder() throws {
        // TS-160's rule with String vertices: 'r' has children listed in vertex order, whatever
        // the closure's order of discovery.
        let parents: [String: String] = ["z": "r", "y": "r", "x": "y", "w": "r"]
        let rooted = try #require(RootedTree(vertices: ["r", "z", "x", "y", "w"], parent: { parents[$0] }))
        #expect(Array(rooted.children(of: "r")) == ["z", "y", "w"])
        #expect(Array(rooted.children(of: "y")) == ["x"])
        #expect(Array(rooted.preorder) == ["r", "z", "y", "x", "w"])
    }
}
