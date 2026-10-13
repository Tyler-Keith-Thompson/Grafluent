// §L: the `checked:` lookups. Each throws `VertexNotFound` (`EdgeNotFound`
// for an `Arborescence` edge position) where its plain spelling traps, and otherwise returns the
// plain spelling's value, a nil included (the root's parent and parent edge, a `Forest` path
// across trees, an `Arborescence` path that is not downward). The rows cover the three vertex
// lookups: dense `Int` vertices (a range check, negatives and `vertexCount` included), at most 8
// vertices (a linear search, no table) and more than 8 (the hash table). Expected values come from
// the catalog's reference (`ref.py`, whose `checked` queries evaluate the plain query and report
// `throws` where it traps). Case IDs (TS-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees
import Walks

@Suite("checked: lookups")
struct TreeCheckedLookupTests {
    @Test("TS-900 Tree(g).neighbors(checked: 1) is [0, 3, 4], as neighbors(of: 1): dense Int vertices: a range check, no table")
    func ts900() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(try tree.neighbors(checked: 1)) == [0, 3, 4])
        #expect(Array(try tree.neighbors(checked: 1)) == Array(tree.neighbors(of: 1)))
    }

    @Test("TS-901 Tree(g).neighbors(checked: 9) throws VertexNotFound")
    func ts901() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(throws: VertexNotFound()) { try tree.neighbors(checked: 9) }
        #expect((try? tree.neighbors(checked: 9)) == nil)
    }

    @Test("TS-902 Tree(g).neighbors(checked: -1) throws VertexNotFound: negative, on the dense path")
    func ts902() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(throws: VertexNotFound()) { try tree.neighbors(checked: -1) }
        #expect((try? tree.neighbors(checked: -1)) == nil)
    }

    @Test("TS-903 Tree(g).incidentEdges(checked: 4) is [3, 5], as incidentEdges(of: 4)")
    func ts903() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(try tree.incidentEdges(checked: 4)) == [3, 5])
        #expect(Array(try tree.incidentEdges(checked: 4)) == Array(tree.incidentEdges(of: 4)))
    }

    @Test("TS-904 Tree(g).degree(checked: 4) is 2, as degree(of: 4)")
    func ts904() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(try tree.degree(checked: 4) == 2)
        #expect(try tree.degree(checked: 4) == tree.degree(of: 4))
    }

    @Test("TS-905 Tree(g).degree(checked: 7) throws VertexNotFound: vertexCount itself")
    func ts905() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(throws: VertexNotFound()) { try tree.degree(checked: 7) }
        #expect((try? tree.degree(checked: 7)) == nil)
    }

    @Test("TS-906 Tree(g).vertexIndex(checked: 6) is 6, as vertexIndex(of: 6)")
    func ts906() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(try tree.vertexIndex(checked: 6) == 6)
        #expect(try tree.vertexIndex(checked: 6) == tree.vertexIndex(of: 6))
    }

    @Test("TS-907 Tree(g).path(checkedFrom: 3, to: 5) is [3, 1, 0, 2, 5]/[2, 0, 1, 4], as path(from: 3, to: 5)")
    func ts907() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        let path = try tree.path(checkedFrom: 3, to: 5)
        let plain = tree.path(from: 3, to: 5)
        #expect(path.vertices == [3, 1, 0, 2, 5])
        #expect(path.edges == [2, 0, 1, 4])
        #expect(path.vertices == plain.vertices)
        #expect(path.edges == plain.edges)
    }

    @Test("TS-908 Tree(g).path(checkedFrom: 3, to: 9) throws VertexNotFound: either end checked")
    func ts908() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(throws: VertexNotFound()) { try tree.path(checkedFrom: 3, to: 9) }
        #expect((try? tree.path(checkedFrom: 3, to: 9)) == nil)
    }

    @Test("TS-909 Tree(g).path(checkedFrom: 9, to: 3) throws VertexNotFound")
    func ts909() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(throws: VertexNotFound()) { try tree.path(checkedFrom: 9, to: 3) }
        #expect((try? tree.path(checkedFrom: 9, to: 3)) == nil)
    }

    @Test("TS-910 Tree(g).neighbors(checked: b) is [a, c, d], as neighbors(of: b): at most 8 vertices: no table, a linear search")
    func ts910() throws {
        // U: a-b, b-c, b-d
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(try tree.neighbors(checked: "b")) == ["a", "c", "d"])
        #expect(Array(try tree.neighbors(checked: "b")) == Array(tree.neighbors(of: "b")))
    }

    @Test("TS-911 Tree(g).degree(checked: z) throws VertexNotFound")
    func ts911() throws {
        // U: a-b, b-c, b-d
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(throws: VertexNotFound()) { try tree.degree(checked: "z") }
        #expect((try? tree.degree(checked: "z")) == nil)
    }

    @Test("TS-912 Tree(g).vertexIndex(checked: d) is 3, as vertexIndex(of: d)")
    func ts912() throws {
        // U: a-b, b-c, b-d
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(try tree.vertexIndex(checked: "d") == 3)
        #expect(try tree.vertexIndex(checked: "d") == tree.vertexIndex(of: "d"))
    }

    @Test("TS-913 Tree(g).vertexIndex(checked: j) is 9, as vertexIndex(of: j): more than 8 vertices: the hash table")
    func ts913() throws {
        // U: P(a,b,c,d,e,f,g,h,i,j)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e"), ("e", "f"), ("f", "g"), ("g", "h"), ("h", "i"), ("i", "j")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(try tree.vertexIndex(checked: "j") == 9)
        #expect(try tree.vertexIndex(checked: "j") == tree.vertexIndex(of: "j"))
    }

    @Test("TS-914 Tree(g).incidentEdges(checked: z) throws VertexNotFound")
    func ts914() throws {
        // U: P(a,b,c,d,e,f,g,h,i,j)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e"), ("e", "f"), ("f", "g"), ("g", "h"), ("h", "i"), ("i", "j")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(throws: VertexNotFound()) { try tree.incidentEdges(checked: "z") }
        #expect((try? tree.incidentEdges(checked: "z")) == nil)
    }

    @Test("TS-915 RootedTree(g, root: 0).parent(checked: 6) is 4, as parent(of: 6)")
    func ts915() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(try rooted.parent(checked: 6) == 4)
        #expect(try rooted.parent(checked: 6) == rooted.parent(of: 6))
    }

    @Test("TS-916 RootedTree(g, root: 0).parent(checked: 0) is nil, as parent(of: 0): nil still means the root")
    func ts916() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(try rooted.parent(checked: 0) == nil)
        #expect(try rooted.parent(checked: 0) == rooted.parent(of: 0))
    }

    @Test("TS-917 RootedTree(g, root: 0).parent(checked: 9) throws VertexNotFound")
    func ts917() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.parent(checked: 9) }
        #expect((try? rooted.parent(checked: 9)) == nil)
    }

    @Test("TS-918 RootedTree(g, root: 0).parentEdge(checked: 6) is 5, as parentEdge(of: 6)")
    func ts918() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(try rooted.parentEdge(checked: 6) == 5)
        #expect(try rooted.parentEdge(checked: 6) == rooted.parentEdge(of: 6))
    }

    @Test("TS-919 RootedTree(g, root: 0).parentEdge(checked: 0) is nil, as parentEdge(of: 0)")
    func ts919() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(try rooted.parentEdge(checked: 0) == nil)
        #expect(try rooted.parentEdge(checked: 0) == rooted.parentEdge(of: 0))
    }

    @Test("TS-920 RootedTree(g, root: 0).parentEdge(checked: -1) throws VertexNotFound")
    func ts920() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.parentEdge(checked: -1) }
        #expect((try? rooted.parentEdge(checked: -1)) == nil)
    }

    @Test("TS-921 RootedTree(g, root: 0).children(checked: 1) is [3, 4], as children(of: 1)")
    func ts921() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(try rooted.children(checked: 1)) == [3, 4])
        #expect(Array(try rooted.children(checked: 1)) == Array(rooted.children(of: 1)))
    }

    @Test("TS-922 RootedTree(g, root: 0).children(checked: 7) throws VertexNotFound")
    func ts922() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.children(checked: 7) }
        #expect((try? rooted.children(checked: 7)) == nil)
    }

    @Test("TS-923 RootedTree(g, root: 0).depth(checked: 6) is 3, as depth(of: 6)")
    func ts923() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(try rooted.depth(checked: 6) == 3)
        #expect(try rooted.depth(checked: 6) == rooted.depth(of: 6))
    }

    @Test("TS-924 RootedTree(g, root: 0).depth(checked: 9) throws VertexNotFound")
    func ts924() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.depth(checked: 9) }
        #expect((try? rooted.depth(checked: 9)) == nil)
    }

    @Test("TS-925 RootedTree(g, root: 0).descendants(checked: 1) is [3, 4, 6], as descendants(of: 1)")
    func ts925() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(try rooted.descendants(checked: 1)) == [3, 4, 6])
        #expect(Array(try rooted.descendants(checked: 1)) == Array(rooted.descendants(of: 1)))
    }

    @Test("TS-926 RootedTree(g, root: 0).descendants(checked: 9) throws VertexNotFound")
    func ts926() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.descendants(checked: 9) }
        #expect((try? rooted.descendants(checked: 9)) == nil)
    }

    @Test("TS-927 RootedTree(g, root: 0).ancestors(checked: 6) is [4, 1, 0], as ancestors(of: 6)")
    func ts927() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(try rooted.ancestors(checked: 6)) == [4, 1, 0])
        #expect(Array(try rooted.ancestors(checked: 6)) == Array(rooted.ancestors(of: 6)))
    }

    @Test("TS-928 RootedTree(g, root: 0).ancestors(checked: 9) throws VertexNotFound")
    func ts928() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.ancestors(checked: 9) }
        #expect((try? rooted.ancestors(checked: 9)) == nil)
    }

    @Test("TS-929 RootedTree(g, root: 0).isAncestor(checked: 1, of: 6) is T, as isAncestor(1, of: 6)")
    func ts929() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(try rooted.isAncestor(checked: 1, of: 6) == true)
        #expect(try rooted.isAncestor(checked: 1, of: 6) == rooted.isAncestor(1, of: 6))
    }

    @Test("TS-930 RootedTree(g, root: 0).isAncestor(checked: 9, of: 6) throws VertexNotFound: either vertex checked")
    func ts930() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.isAncestor(checked: 9, of: 6) }
        #expect((try? rooted.isAncestor(checked: 9, of: 6)) == nil)
    }

    @Test("TS-931 RootedTree(g, root: 0).isAncestor(checked: 1, of: 9) throws VertexNotFound")
    func ts931() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.isAncestor(checked: 1, of: 9) }
        #expect((try? rooted.isAncestor(checked: 1, of: 9)) == nil)
    }

    @Test("TS-932 RootedTree(g, root: 0).path(checkedFrom: 6, to: 5) is [6, 4, 1, 0, 2, 5]/[5, 3, 0, 1, 4], as path(from: 6, to: 5)")
    func ts932() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        let path = try rooted.path(checkedFrom: 6, to: 5)
        let plain = rooted.path(from: 6, to: 5)
        #expect(path.vertices == [6, 4, 1, 0, 2, 5])
        #expect(path.edges == [5, 3, 0, 1, 4])
        #expect(path.vertices == plain.vertices)
        #expect(path.edges == plain.edges)
    }

    @Test("TS-933 RootedTree(g, root: 0).path(checkedFrom: 6, to: 9) throws VertexNotFound")
    func ts933() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.path(checkedFrom: 6, to: 9) }
        #expect((try? rooted.path(checkedFrom: 6, to: 9)) == nil)
    }

    @Test("TS-934 RootedTree(g, root: 0).neighbors(checked: 4) is [1, 6], as neighbors(of: 4)")
    func ts934() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(try rooted.neighbors(checked: 4)) == [1, 6])
        #expect(Array(try rooted.neighbors(checked: 4)) == Array(rooted.neighbors(of: 4)))
    }

    @Test("TS-935 RootedTree(g, root: 0).incidentEdges(checked: 4) is [3, 5], as incidentEdges(of: 4)")
    func ts935() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(Array(try rooted.incidentEdges(checked: 4)) == [3, 5])
        #expect(Array(try rooted.incidentEdges(checked: 4)) == Array(rooted.incidentEdges(of: 4)))
    }

    @Test("TS-936 RootedTree(g, root: 0).degree(checked: 1) is 3, as degree(of: 1)")
    func ts936() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(try rooted.degree(checked: 1) == 3)
        #expect(try rooted.degree(checked: 1) == rooted.degree(of: 1))
    }

    @Test("TS-937 RootedTree(g, root: 0).vertexIndex(checked: 5) is 5, as vertexIndex(of: 5)")
    func ts937() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(try rooted.vertexIndex(checked: 5) == 5)
        #expect(try rooted.vertexIndex(checked: 5) == rooted.vertexIndex(of: 5))
    }

    @Test("TS-938 RootedTree(g, root: 0).degree(checked: 9) throws VertexNotFound")
    func ts938() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: 0))
        #expect(throws: VertexNotFound()) { try rooted.degree(checked: 9) }
        #expect((try? rooted.degree(checked: 9)) == nil)
    }

    @Test("TS-939 RootedTree(g, root: e).depth(checked: a) is 4, as depth(of: a): the hash table")
    func ts939() throws {
        // U: P(a,b,c,d,e,f,g,h,i,j)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e"), ("e", "f"), ("f", "g"), ("g", "h"), ("h", "i"), ("i", "j")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "e"))
        #expect(try rooted.depth(checked: "a") == 4)
        #expect(try rooted.depth(checked: "a") == rooted.depth(of: "a"))
    }

    @Test("TS-940 RootedTree(g, root: e).parent(checked: z) throws VertexNotFound")
    func ts940() throws {
        // U: P(a,b,c,d,e,f,g,h,i,j)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e"), ("e", "f"), ("f", "g"), ("g", "h"), ("h", "i"), ("i", "j")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let rooted = try #require(RootedTree(graph, root: "e"))
        #expect(throws: VertexNotFound()) { try rooted.parent(checked: "z") }
        #expect((try? rooted.parent(checked: "z")) == nil)
    }

    @Test("TS-941 Arborescence(g).parent(checked: 6) is 4, as parent(of: 6)")
    func ts941() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.parent(checked: 6) == 4)
        #expect(try arborescence.parent(checked: 6) == arborescence.parent(of: 6))
    }

    @Test("TS-942 Arborescence(g).parent(checked: 0) is nil, as parent(of: 0): nil still means the root")
    func ts942() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.parent(checked: 0) == nil)
        #expect(try arborescence.parent(checked: 0) == arborescence.parent(of: 0))
    }

    @Test("TS-943 Arborescence(g).parent(checked: 9) throws VertexNotFound")
    func ts943() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.parent(checked: 9) }
        #expect((try? arborescence.parent(checked: 9)) == nil)
    }

    @Test("TS-944 Arborescence(g).parentEdge(checked: 6) is 5, as parentEdge(of: 6)")
    func ts944() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.parentEdge(checked: 6) == 5)
        #expect(try arborescence.parentEdge(checked: 6) == arborescence.parentEdge(of: 6))
    }

    @Test("TS-945 Arborescence(g).parentEdge(checked: 9) throws VertexNotFound")
    func ts945() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.parentEdge(checked: 9) }
        #expect((try? arborescence.parentEdge(checked: 9)) == nil)
    }

    @Test("TS-946 Arborescence(g).children(checked: 1) is [3, 4], as children(of: 1)")
    func ts946() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.children(checked: 1)) == [3, 4])
        #expect(Array(try arborescence.children(checked: 1)) == Array(arborescence.children(of: 1)))
    }

    @Test("TS-947 Arborescence(g).depth(checked: 6) is 3, as depth(of: 6)")
    func ts947() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.depth(checked: 6) == 3)
        #expect(try arborescence.depth(checked: 6) == arborescence.depth(of: 6))
    }

    @Test("TS-948 Arborescence(g).descendants(checked: 1) is [3, 4, 6], as descendants(of: 1): the preorder slice, not Traversal's Set")
    func ts948() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.descendants(checked: 1)) == [3, 4, 6])
        #expect(Array(try arborescence.descendants(checked: 1)) == Array(arborescence.descendants(of: 1)))
    }

    @Test("TS-949 Arborescence(g).descendants(checked: -1) throws VertexNotFound")
    func ts949() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.descendants(checked: -1) }
        #expect((try? arborescence.descendants(checked: -1)) == nil)
    }

    @Test("TS-950 Arborescence(g).ancestors(checked: 6) is [4, 1, 0], as ancestors(of: 6)")
    func ts950() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.ancestors(checked: 6)) == [4, 1, 0])
        #expect(Array(try arborescence.ancestors(checked: 6)) == Array(arborescence.ancestors(of: 6)))
    }

    @Test("TS-951 Arborescence(g).ancestors(checked: 7) throws VertexNotFound")
    func ts951() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.ancestors(checked: 7) }
        #expect((try? arborescence.ancestors(checked: 7)) == nil)
    }

    @Test("TS-952 Arborescence(g).isAncestor(checked: 6, of: 1) is F, as isAncestor(6, of: 1)")
    func ts952() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.isAncestor(checked: 6, of: 1) == false)
        #expect(try arborescence.isAncestor(checked: 6, of: 1) == arborescence.isAncestor(6, of: 1))
    }

    @Test("TS-953 Arborescence(g).isAncestor(checked: 9, of: 1) throws VertexNotFound")
    func ts953() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.isAncestor(checked: 9, of: 1) }
        #expect((try? arborescence.isAncestor(checked: 9, of: 1)) == nil)
    }

    @Test("TS-954 Arborescence(g).path(checkedFrom: 1, to: 6) is [1, 4, 6]/[3, 5], as path(from: 1, to: 6)")
    func ts954() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let path = try #require(try arborescence.path(checkedFrom: 1, to: 6))
        let plain = try #require(arborescence.path(from: 1, to: 6))
        #expect(path.vertices == [1, 4, 6])
        #expect(path.edges == [3, 5])
        #expect(path.vertices == plain.vertices)
        #expect(path.edges == plain.edges)
    }

    @Test("TS-955 Arborescence(g).path(checkedFrom: 6, to: 1) is nil, as path(from: 6, to: 1): nil still means not downward")
    func ts955() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.path(checkedFrom: 6, to: 1) == nil)
        #expect(arborescence.path(from: 6, to: 1) == nil)
    }

    @Test("TS-956 Arborescence(g).path(checkedFrom: 1, to: 9) throws VertexNotFound")
    func ts956() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.path(checkedFrom: 1, to: 9) }
        #expect((try? arborescence.path(checkedFrom: 1, to: 9)) == nil)
    }

    @Test("TS-957 Arborescence(g).successors(checked: 1) is [3, 4], as successors(of: 1)")
    func ts957() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.successors(checked: 1)) == [3, 4])
        #expect(Array(try arborescence.successors(checked: 1)) == Array(arborescence.successors(of: 1)))
    }

    @Test("TS-958 Arborescence(g).successors(checked: 9) throws VertexNotFound")
    func ts958() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.successors(checked: 9) }
        #expect((try? arborescence.successors(checked: 9)) == nil)
    }

    @Test("TS-959 Arborescence(g).predecessors(checked: 6) is [4], as predecessors(of: 6)")
    func ts959() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.predecessors(checked: 6)) == [4])
        #expect(Array(try arborescence.predecessors(checked: 6)) == Array(arborescence.predecessors(of: 6)))
    }

    @Test("TS-960 Arborescence(g).predecessors(checked: 0) is [], as predecessors(of: 0)")
    func ts960() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.predecessors(checked: 0)) == [])
        #expect(Array(try arborescence.predecessors(checked: 0)) == Array(arborescence.predecessors(of: 0)))
    }

    @Test("TS-961 Arborescence(g).predecessors(checked: 9) throws VertexNotFound")
    func ts961() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.predecessors(checked: 9) }
        #expect((try? arborescence.predecessors(checked: 9)) == nil)
    }

    @Test("TS-962 Arborescence(g).outEdges(checked: 1) is [2, 3], as outEdges(of: 1)")
    func ts962() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.outEdges(checked: 1)) == [2, 3])
        #expect(Array(try arborescence.outEdges(checked: 1)) == Array(arborescence.outEdges(of: 1)))
    }

    @Test("TS-963 Arborescence(g).outEdges(checked: 9) throws VertexNotFound")
    func ts963() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.outEdges(checked: 9) }
        #expect((try? arborescence.outEdges(checked: 9)) == nil)
    }

    @Test("TS-964 Arborescence(g).inEdges(checked: 6) is [5], as inEdges(of: 6)")
    func ts964() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.inEdges(checked: 6)) == [5])
        #expect(Array(try arborescence.inEdges(checked: 6)) == Array(arborescence.inEdges(of: 6)))
    }

    @Test("TS-965 Arborescence(g).inEdges(checked: 0) is [], as inEdges(of: 0)")
    func ts965() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(Array(try arborescence.inEdges(checked: 0)) == [])
        #expect(Array(try arborescence.inEdges(checked: 0)) == Array(arborescence.inEdges(of: 0)))
    }

    @Test("TS-966 Arborescence(g).inEdges(checked: 9) throws VertexNotFound")
    func ts966() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.inEdges(checked: 9) }
        #expect((try? arborescence.inEdges(checked: 9)) == nil)
    }

    @Test("TS-967 Arborescence(g).outDegree(checked: 1) is 2, as outDegree(of: 1)")
    func ts967() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.outDegree(checked: 1) == 2)
        #expect(try arborescence.outDegree(checked: 1) == arborescence.outDegree(of: 1))
    }

    @Test("TS-968 Arborescence(g).outDegree(checked: 9) throws VertexNotFound")
    func ts968() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.outDegree(checked: 9) }
        #expect((try? arborescence.outDegree(checked: 9)) == nil)
    }

    @Test("TS-969 Arborescence(g).inDegree(checked: 0) is 0, as inDegree(of: 0)")
    func ts969() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.inDegree(checked: 0) == 0)
        #expect(try arborescence.inDegree(checked: 0) == arborescence.inDegree(of: 0))
    }

    @Test("TS-970 Arborescence(g).inDegree(checked: 6) is 1, as inDegree(of: 6)")
    func ts970() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.inDegree(checked: 6) == 1)
        #expect(try arborescence.inDegree(checked: 6) == arborescence.inDegree(of: 6))
    }

    @Test("TS-971 Arborescence(g).inDegree(checked: 9) throws VertexNotFound")
    func ts971() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.inDegree(checked: 9) }
        #expect((try? arborescence.inDegree(checked: 9)) == nil)
    }

    @Test("TS-972 Arborescence(g).degree(checked: 1) is 3, as degree(of: 1): one lookup, where degree(of:) makes two")
    func ts972() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.degree(checked: 1) == 3)
        #expect(try arborescence.degree(checked: 1) == arborescence.degree(of: 1))
    }

    @Test("TS-973 Arborescence(g).degree(checked: 0) is 2, as degree(of: 0)")
    func ts973() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.degree(checked: 0) == 2)
        #expect(try arborescence.degree(checked: 0) == arborescence.degree(of: 0))
    }

    @Test("TS-974 Arborescence(g).degree(checked: 9) throws VertexNotFound")
    func ts974() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.degree(checked: 9) }
        #expect((try? arborescence.degree(checked: 9)) == nil)
    }

    @Test("TS-975 Arborescence(g).vertexIndex(checked: 4) is 4, as vertexIndex(of: 4)")
    func ts975() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.vertexIndex(checked: 4) == 4)
        #expect(try arborescence.vertexIndex(checked: 4) == arborescence.vertexIndex(of: 4))
    }

    @Test("TS-976 Arborescence(g).vertexIndex(checked: 7) throws VertexNotFound")
    func ts976() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.vertexIndex(checked: 7) }
        #expect((try? arborescence.vertexIndex(checked: 7)) == nil)
    }

    @Test("TS-977 Arborescence(g).source(checkedEdgeAt: 5) is 4, as source(ofEdgeAt: 5): source(checkedEdgeAt:)")
    func ts977() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.source(checkedEdgeAt: 5) == 4)
        #expect(try arborescence.source(checkedEdgeAt: 5) == arborescence.source(ofEdgeAt: 5))
    }

    @Test("TS-978 Arborescence(g).target(checkedEdgeAt: 5) is 6, as target(ofEdgeAt: 5)")
    func ts978() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.target(checkedEdgeAt: 5) == 6)
        #expect(try arborescence.target(checkedEdgeAt: 5) == arborescence.target(ofEdgeAt: 5))
    }

    @Test("TS-979 Arborescence(g).source(checkedEdgeAt: 6) throws EdgeNotFound: edgeCount: EdgeNotFound")
    func ts979() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: EdgeNotFound()) { try arborescence.source(checkedEdgeAt: 6) }
        #expect((try? arborescence.source(checkedEdgeAt: 6)) == nil)
    }

    @Test("TS-980 Arborescence(g).target(checkedEdgeAt: -1) throws EdgeNotFound")
    func ts980() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: EdgeNotFound()) { try arborescence.target(checkedEdgeAt: -1) }
        #expect((try? arborescence.target(checkedEdgeAt: -1)) == nil)
    }

    @Test("TS-981 Arborescence(g).depth(checked: j) is 9, as depth(of: j): the hash table")
    func ts981() throws {
        // D: P(a,b,c,d,e,f,g,h,i,j)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e"), ("e", "f"), ("f", "g"), ("g", "h"), ("h", "i"), ("i", "j")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(try arborescence.depth(checked: "j") == 9)
        #expect(try arborescence.depth(checked: "j") == arborescence.depth(of: "j"))
    }

    @Test("TS-982 Arborescence(g).depth(checked: z) throws VertexNotFound")
    func ts982() throws {
        // D: P(a,b,c,d,e,f,g,h,i,j)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e"), ("e", "f"), ("f", "g"), ("g", "h"), ("h", "i"), ("i", "j")]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        #expect(throws: VertexNotFound()) { try arborescence.depth(checked: "z") }
        #expect((try? arborescence.depth(checked: "z")) == nil)
    }

    @Test("TS-983 Forest(g).component(checked: 3) is 1, as component(of: 3)")
    func ts983() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(try forest.component(checked: 3) == 1)
        #expect(try forest.component(checked: 3) == forest.component(of: 3))
    }

    @Test("TS-984 Forest(g).component(checked: 9) throws VertexNotFound")
    func ts984() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(throws: VertexNotFound()) { try forest.component(checked: 9) }
        #expect((try? forest.component(checked: 9)) == nil)
    }

    @Test("TS-985 Forest(g).path(checkedFrom: 2, to: 4) is [2, 3, 4]/[1, 2], as path(from: 2, to: 4)")
    func ts985() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        let path = try #require(try forest.path(checkedFrom: 2, to: 4))
        let plain = try #require(forest.path(from: 2, to: 4))
        #expect(path.vertices == [2, 3, 4])
        #expect(path.edges == [1, 2])
        #expect(path.vertices == plain.vertices)
        #expect(path.edges == plain.edges)
    }

    @Test("TS-986 Forest(g).path(checkedFrom: 0, to: 4) is nil, as path(from: 0, to: 4): nil still means different trees")
    func ts986() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(try forest.path(checkedFrom: 0, to: 4) == nil)
        #expect(forest.path(from: 0, to: 4) == nil)
    }

    @Test("TS-987 Forest(g).path(checkedFrom: 0, to: 9) throws VertexNotFound")
    func ts987() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(throws: VertexNotFound()) { try forest.path(checkedFrom: 0, to: 9) }
        #expect((try? forest.path(checkedFrom: 0, to: 9)) == nil)
    }

    @Test("TS-988 Forest(g).path(checkedFrom: 9, to: 0) throws VertexNotFound")
    func ts988() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(throws: VertexNotFound()) { try forest.path(checkedFrom: 9, to: 0) }
        #expect((try? forest.path(checkedFrom: 9, to: 0)) == nil)
    }

    @Test("TS-989 Forest(g).neighbors(checked: 3) is [2, 4], as neighbors(of: 3)")
    func ts989() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(Array(try forest.neighbors(checked: 3)) == [2, 4])
        #expect(Array(try forest.neighbors(checked: 3)) == Array(forest.neighbors(of: 3)))
    }

    @Test("TS-990 Forest(g).incidentEdges(checked: 3) is [1, 2], as incidentEdges(of: 3)")
    func ts990() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(Array(try forest.incidentEdges(checked: 3)) == [1, 2])
        #expect(Array(try forest.incidentEdges(checked: 3)) == Array(forest.incidentEdges(of: 3)))
    }

    @Test("TS-991 Forest(g).degree(checked: 3) is 2, as degree(of: 3)")
    func ts991() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(try forest.degree(checked: 3) == 2)
        #expect(try forest.degree(checked: 3) == forest.degree(of: 3))
    }

    @Test("TS-992 Forest(g).vertexIndex(checked: 4) is 4, as vertexIndex(of: 4)")
    func ts992() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(try forest.vertexIndex(checked: 4) == 4)
        #expect(try forest.vertexIndex(checked: 4) == forest.vertexIndex(of: 4))
    }

    @Test("TS-993 Forest(g).degree(checked: -1) throws VertexNotFound")
    func ts993() throws {
        // U: 0-1, 2-3, 3-4
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(throws: VertexNotFound()) { try forest.degree(checked: -1) }
        #expect((try? forest.degree(checked: -1)) == nil)
    }

    @Test("TS-994 Forest(g).component(checked: k) is 0, as component(of: k): the hash table")
    func ts994() throws {
        // U: [k] P(a,b,c,d,e,f,g,h,i,j)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e"), ("e", "f"), ("f", "g"), ("g", "h"), ("h", "i"), ("i", "j")]
        let graph = ReferencePseudograph(vertices: ["k"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(try forest.component(checked: "k") == 0)
        #expect(try forest.component(checked: "k") == forest.component(of: "k"))
    }

    @Test("TS-995 Forest(g).component(checked: z) throws VertexNotFound")
    func ts995() throws {
        // U: [k] P(a,b,c,d,e,f,g,h,i,j)
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e"), ("e", "f"), ("f", "g"), ("g", "h"), ("h", "i"), ("i", "j")]
        let graph = ReferencePseudograph(vertices: ["k"], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try #require(Forest(graph))
        #expect(throws: VertexNotFound()) { try forest.component(checked: "z") }
        #expect((try? forest.component(checked: "z")) == nil)
    }

    @Test("Every checked: lookup on Tree, RootedTree and Forest equals its plain spelling at every vertex, by each lookup")
    func undirectedSweep() throws {
        // Dense Int 0..<20 (kary(20, 2)), Int 100..<120 (more than 8, not dense: the hash table),
        // and String trees of 6 (no table) and 20 (the hash table) vertices on a path.
        let kary: [(Int, Int)] = (1 ..< 20).map { (($0 - 1) / 2, $0) }
        let sparse: [(Int, Int)] = (101 ..< 120).map { ($0 - 1, $0) }
        let names = (0 ..< 20).map { "v\($0)" }
        let short: [(String, String)] = (1 ..< 6).map { (names[$0 - 1], names[$0]) }
        let long: [(String, String)] = (1 ..< 20).map { (names[$0 - 1], names[$0]) }
        let intTrees = [kary, sparse].map { pairs in Tree(ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })) }
        let stringTrees = [short, long].map { pairs in Tree(ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })) }
        for case let tree? in intTrees {
            let forest = Forest(tree)
            let rooted = RootedTree(tree, root: tree.vertices[tree.vertexCount / 2])
            for v in tree.vertices {
                #expect(Array(try tree.neighbors(checked: v)) == Array(tree.neighbors(of: v)))
                #expect(Array(try tree.incidentEdges(checked: v)) == Array(tree.incidentEdges(of: v)))
                #expect(try tree.degree(checked: v) == tree.degree(of: v))
                #expect(try tree.vertexIndex(checked: v) == tree.vertexIndex(of: v))
                #expect(try forest.degree(checked: v) == forest.degree(of: v))
                #expect(try forest.vertexIndex(checked: v) == forest.vertexIndex(of: v))
                #expect(try forest.component(checked: v) == forest.component(of: v))
                #expect(try rooted.parent(checked: v) == rooted.parent(of: v))
                #expect(try rooted.parentEdge(checked: v) == rooted.parentEdge(of: v))
                #expect(try rooted.depth(checked: v) == rooted.depth(of: v))
                #expect(Array(try rooted.children(checked: v)) == Array(rooted.children(of: v)))
                #expect(Array(try rooted.descendants(checked: v)) == Array(rooted.descendants(of: v)))
                #expect(Array(try rooted.ancestors(checked: v)) == Array(rooted.ancestors(of: v)))
                #expect(try rooted.isAncestor(checked: rooted.root, of: v) == rooted.isAncestor(rooted.root, of: v))
                #expect(try tree.path(checkedFrom: tree.vertices[0], to: v).vertices == tree.path(from: tree.vertices[0], to: v).vertices)
            }
            for missing in [-1, 20, 99, 120, Int.min, Int.max] {
                #expect(throws: VertexNotFound()) { try tree.degree(checked: missing) }
                #expect(throws: VertexNotFound()) { try forest.component(checked: missing) }
                #expect(throws: VertexNotFound()) { try rooted.depth(checked: missing) }
                #expect(throws: VertexNotFound()) { try rooted.isAncestor(checked: rooted.root, of: missing) }
                #expect(throws: VertexNotFound()) { try forest.path(checkedFrom: missing, to: forest.vertices[0]) }
            }
        }
        for case let tree? in stringTrees {
            let forest = Forest(tree)
            let rooted = RootedTree(tree, root: tree.vertices[tree.vertexCount / 2])
            for v in tree.vertices {
                #expect(Array(try tree.neighbors(checked: v)) == Array(tree.neighbors(of: v)))
                #expect(try tree.vertexIndex(checked: v) == tree.vertexIndex(of: v))
                #expect(Array(try forest.incidentEdges(checked: v)) == Array(forest.incidentEdges(of: v)))
                #expect(try rooted.parent(checked: v) == rooted.parent(of: v))
                #expect(try rooted.depth(checked: v) == rooted.depth(of: v))
                #expect(Array(try rooted.neighbors(checked: v)) == Array(rooted.neighbors(of: v)))
            }
            for missing in ["", "v20", "V0", "w"] {
                #expect(throws: VertexNotFound()) { try tree.vertexIndex(checked: missing) }
                #expect(throws: VertexNotFound()) { try rooted.parent(checked: missing) }
                #expect(throws: VertexNotFound()) { try forest.neighbors(checked: missing) }
            }
        }
    }

    @Test("Every checked: lookup on Arborescence equals its plain spelling at every vertex and position, by each lookup")
    func arborescenceSweep() throws {
        // Dense Int 0..<20 (kary(20, 2)), Int 100..<120 rooted at 110 (the hash table), and String
        // arborescences of 6 (no table) and 20 (the hash table) vertices.
        let kary: [(Int, Int)] = (1 ..< 20).map { (($0 - 1) / 2, $0) }
        let sparse: [(Int, Int)] = (101 ..< 120).map { $0 <= 110 ? ($0, $0 - 1) : ($0 - 1, $0) }
        let names = (0 ..< 20).map { "v\($0)" }
        let short: [(String, String)] = (1 ..< 6).map { (names[$0 - 1], names[$0]) }
        let long: [(String, String)] = (1 ..< 20).map { (names[$0 - 1], names[$0]) }
        let ints = [kary, sparse].map { pairs in Arborescence(ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })) }
        let strings = [short, long].map { pairs in Arborescence(ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })) }
        #expect(ints.allSatisfy { $0 != nil } && strings.allSatisfy { $0 != nil })
        for case let a? in ints {
            for v in a.vertices {
                #expect(Array(try a.successors(checked: v)) == Array(a.successors(of: v)))
                #expect(Array(try a.predecessors(checked: v)) == Array(a.predecessors(of: v)))
                #expect(Array(try a.outEdges(checked: v)) == Array(a.outEdges(of: v)))
                #expect(Array(try a.inEdges(checked: v)) == Array(a.inEdges(of: v)))
                #expect(try a.outDegree(checked: v) == a.outDegree(of: v))
                #expect(try a.inDegree(checked: v) == a.inDegree(of: v))
                #expect(try a.degree(checked: v) == a.degree(of: v))
                #expect(try a.vertexIndex(checked: v) == a.vertexIndex(of: v))
                #expect(try a.parent(checked: v) == a.parent(of: v))
                #expect(try a.parentEdge(checked: v) == a.parentEdge(of: v))
                #expect(Array(try a.children(checked: v)) == Array(a.children(of: v)))
                #expect(try a.depth(checked: v) == a.depth(of: v))
                #expect(Array(try a.descendants(checked: v)) == Array(a.descendants(of: v)))
                #expect(Array(try a.ancestors(checked: v)) == Array(a.ancestors(of: v)))
                #expect(try a.isAncestor(checked: a.root, of: v) == a.isAncestor(a.root, of: v))
                #expect(try a.path(checkedFrom: a.root, to: v)?.edges == a.path(from: a.root, to: v)?.edges)
                #expect(try a.path(checkedFrom: v, to: a.root)?.edges == a.path(from: v, to: a.root)?.edges)
            }
            for p in a.edges.indices {
                #expect(try a.source(checkedEdgeAt: p) == a.source(ofEdgeAt: p))
                #expect(try a.target(checkedEdgeAt: p) == a.target(ofEdgeAt: p))
            }
            for p in [-1, a.edgeCount, Int.min, Int.max] {
                #expect(throws: EdgeNotFound()) { try a.source(checkedEdgeAt: p) }
                #expect(throws: EdgeNotFound()) { try a.target(checkedEdgeAt: p) }
            }
            for missing in [-1, 20, 99, 120, Int.min, Int.max] {
                #expect(throws: VertexNotFound()) { try a.successors(checked: missing) }
                #expect(throws: VertexNotFound()) { try a.inDegree(checked: missing) }
                #expect(throws: VertexNotFound()) { try a.degree(checked: missing) }
                #expect(throws: VertexNotFound()) { try a.isAncestor(checked: missing, of: a.root) }
                #expect(throws: VertexNotFound()) { try a.path(checkedFrom: a.root, to: missing) }
            }
        }
        for case let a? in strings {
            for v in a.vertices {
                #expect(try a.vertexIndex(checked: v) == a.vertexIndex(of: v))
                #expect(try a.parent(checked: v) == a.parent(of: v))
                #expect(Array(try a.outEdges(checked: v)) == Array(a.outEdges(of: v)))
            }
            for missing in ["", "v20", "V0", "w"] {
                #expect(throws: VertexNotFound()) { try a.vertexIndex(checked: missing) }
                #expect(throws: VertexNotFound()) { try a.predecessors(checked: missing) }
            }
        }
    }

    @Test("Arborescence's descendants(checked:) and ancestors(checked:) are its own, not Traversal's Set-returning ones")
    func ownDescendants() throws {
        // D: 0>1, 0>2, 1>3, 1>4, 2>5, 4>6. The preorder slice is ordered; a Set is not.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try #require(Arborescence(graph))
        let descendants: RootedTree<Int>.Preorder.SubSequence = try arborescence.descendants(checked: 0)
        let ancestors: RootedTree<Int>.Ancestors = try arborescence.ancestors(checked: 6)
        #expect(Array(descendants) == [1, 3, 4, 6, 2, 5])
        #expect(Array(ancestors) == [4, 1, 0])
    }
}
