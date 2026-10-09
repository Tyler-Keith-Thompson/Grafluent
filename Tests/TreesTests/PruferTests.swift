// §H: Prüfer codes. `Tree.pruferSequence` removes the leaf with the least vertex index (the
// `vertices` order, not the value) n − 2 times, recording its neighbour; nil for fewer than 2
// vertices. `Tree<Int>(pruferSequence:)` builds the tree on 0..<count+2: edge k joins the k-th
// removed leaf to the k-th code element, the last edge the two remaining vertices; nil when an
// element is outside that range. Decoded edges are compared as undirected edges (orientation is not
// part of an edge's value). Expected values come from the catalog's reference (`ref.py`,
// cross-checked against NetworkX's `to_prufer_sequence` / `from_prufer_sequence` and the textbook
// least-leaf loop). Case IDs (TS-nnn) refer to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Prüfer codes")
struct PruferTests {
    @Test("TS-500 Tree(g).pruferSequence is [3, 3, 3, 4]: NetworkX's known tree")
    func knownTree() throws {
        // U: 0-3, 1-3, 2-3, 3-4, 4-5
        let pairs: [(Int, Int)] = [(0, 3), (1, 3), (2, 3), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.pruferSequence == [3, 3, 3, 4])
    }

    @Test("TS-501 Tree(pruferSequence: [3, 3, 3, 4]).edges is [0-3, 1-3, 2-3, 3-4, 4-5]: decoding order")
    func decodeKnownTree() throws {
        // prufer: [3,3,3,4]
        let tree = try #require(Tree(pruferSequence: [3, 3, 3, 4]))
        let expected: [(Int, Int)] = [(0, 3), (1, 3), (2, 3), (3, 4), (4, 5)]
        #expect(Array(tree.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(tree.vertices) == [0, 1, 2, 3, 4, 5])
    }

    @Test("TS-502 Tree(pruferSequence: []).edges is [0-1]: the empty code is K₂")
    func emptyCode() throws {
        // prufer: []
        let tree = try #require(Tree(pruferSequence: []))
        #expect(Array(tree.edges) == [UndirectedEdge(0, 1)])
        #expect(Array(tree.vertices) == [0, 1])
    }

    @Test("TS-503 Tree(K₂).pruferSequence is []")
    func codeOfK2() throws {
        // U: 0-1
        let graph = ReferencePseudograph(edges: [UndirectedEdge(0, 1)])
        let tree = try #require(Tree(graph))
        #expect(tree.pruferSequence == [])
    }

    @Test("TS-504 Tree(K₁).pruferSequence is nil: undefined for n < 2")
    func codeOfK1() throws {
        // U: [0]. NetworkX raises NetworkXPointlessConcept, igraph IGRAPH_EINVAL.
        let graph = ReferencePseudograph<Int>(vertices: [0], edges: [])
        let tree = try #require(Tree(graph))
        #expect(tree.pruferSequence == nil)
    }

    @Test("TS-505 Tree(pruferSequence: [2]).edges is [0-2, 1-2]")
    func decodeSingle() throws {
        // prufer: [2]
        let tree = try #require(Tree(pruferSequence: [2]))
        let expected: [(Int, Int)] = [(0, 2), (1, 2)]
        #expect(Array(tree.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-506 Tree(pruferSequence: [3]) is nil: out of range for n = 3")
    func outOfRange() {
        // prufer: [3]
        #expect(Tree(pruferSequence: [3]) == nil)
    }

    @Test("TS-507 Tree(pruferSequence: [-1]) is nil")
    func negativeElement() {
        // prufer: [-1]
        #expect(Tree(pruferSequence: [-1]) == nil)
    }

    @Test("TS-508 Tree(P(0..9)).pruferSequence is [1, 2, …, 8]")
    func codeOfPath() throws {
        // U: P(0..9)
        let graph = ReferencePseudograph(edges: (0 ..< 9).map { UndirectedEdge($0, $0 + 1) })
        let tree = try #require(Tree(graph))
        #expect(tree.pruferSequence == [1, 2, 3, 4, 5, 6, 7, 8])
    }

    @Test("TS-509 Tree(S(0;1..9)).pruferSequence is [0, 0, 0, 0, 0, 0, 0, 0]: the center n − 2 times")
    func codeOfStar() throws {
        // U: S(0;1..9)
        let graph = ReferencePseudograph(edges: (1 ... 9).map { UndirectedEdge(0, $0) })
        let tree = try #require(Tree(graph))
        #expect(tree.pruferSequence == [0, 0, 0, 0, 0, 0, 0, 0])
    }

    @Test("TS-510 Tree(pruferSequence: [0, …, 0]).edges is [1-0, 2-0, …, 8-0, 0-9]")
    func decodeStar() throws {
        // prufer: [0,0,0,0,0,0,0,0]
        let tree = try #require(Tree(pruferSequence: [0, 0, 0, 0, 0, 0, 0, 0]))
        let expected: [(Int, Int)] = [(1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0), (0, 9)]
        #expect(Array(tree.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-511 Tree(pruferSequence: [4, 4, 0, 2, 6, 6]).edges is [1-4, 3-4, 4-0, 0-2, 2-6, 5-6, 6-7]")
    func decodeMixed() throws {
        // prufer: [4,4,0,2,6,6]
        let tree = try #require(Tree(pruferSequence: [4, 4, 0, 2, 6, 6]))
        let expected: [(Int, Int)] = [(1, 4), (3, 4), (4, 0), (0, 2), (2, 6), (5, 6), (6, 7)]
        #expect(Array(tree.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("TS-512 Tree(E1).pruferSequence is [1, 2, 0, 1, 4]")
    func codeOfE1() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 4-6
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.pruferSequence == [1, 2, 0, 1, 4])
    }

    @Test("TS-513 Tree(pruferSequence: [1, 0, 0, 4, 2]).pruferSequence is [1, 0, 0, 4, 2]: round trip")
    func roundTrip() throws {
        // prufer: [1,0,0,4,2]
        let tree = try #require(Tree(pruferSequence: [1, 0, 0, 4, 2]))
        #expect(tree.pruferSequence == [1, 0, 0, 4, 2])
    }

    @Test("TS-514 Tree(g).pruferSequence is [b, b]: generic vertices, ranked by index")
    func stringCode() throws {
        // U: a-b, b-c, b-d
        let pairs: [(String, String)] = [("a", "b"), ("b", "c"), ("b", "d")]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(tree.pruferSequence == ["b", "b"])
    }

    @Test("TS-515 Tree(g).pruferSequence is [2, 1]: Int vertices out of order are ranked by index, not value")
    func indexOrderNotValueOrder() throws {
        // U: [3,0,1,2] 0-1, 1-2, 2-3. By value it would be [1, 2].
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: [3, 0, 1, 2], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try #require(Tree(graph))
        #expect(Array(tree.vertices) == [3, 0, 1, 2])
        #expect(tree.pruferSequence == [2, 1])
    }

    @Test("TS-516 Tree(pruferSequence: [6, 2, 6, 0, 3]).pruferSequence round-trips: igraph from_prufer")
    func igraphRoundTrip() throws {
        // prufer: [6,2,6,0,3]
        let tree = try #require(Tree(pruferSequence: [6, 2, 6, 0, 3]))
        #expect(tree.pruferSequence == [6, 2, 6, 0, 3])
        #expect(tree.vertexCount == 7)
    }

    @Test("TS-517 Tree(pruferSequence: [2, 4, 5, 1, 1, 4]).edges is [0-2, 2-4, 3-5, 5-1, 6-1, 1-4, 4-7]")
    func decodeLonger() throws {
        // prufer: [2,4,5,1,1,4]
        let tree = try #require(Tree(pruferSequence: [2, 4, 5, 1, 1, 4]))
        let expected: [(Int, Int)] = [(0, 2), (2, 4), (3, 5), (5, 1), (6, 1), (1, 4), (4, 7)]
        #expect(Array(tree.edges) == expected.map { UndirectedEdge($0.0, $0.1) })
    }

    @Test("Every code of length 3 decodes to a distinct tree on 5 vertices and encodes back (Cayley: 125)")
    func everyCodeOfLengthThree() throws {
        var seen = Set<Tree<Int>>()
        for a in 0 ..< 5 {
            for b in 0 ..< 5 {
                for c in 0 ..< 5 {
                    let tree = try #require(Tree(pruferSequence: [a, b, c]))
                    #expect(tree.vertexCount == 5)
                    #expect(tree.pruferSequence == [a, b, c], "\([a, b, c])")
                    // A vertex appears in the code degree − 1 times.
                    for v in 0 ..< 5 {
                        let occurrences = [a, b, c].filter { $0 == v }.count
                        #expect(tree.degree(of: v) == occurrences + 1, "\([a, b, c]) at \(v)")
                    }
                    seen.insert(tree)
                }
            }
        }
        #expect(seen.count == 125)
    }

    @Test("Decoding takes any sequence of Int, a single-pass one included")
    func decodeFromSequence() throws {
        // TS-501's code.
        let fromRange = try #require(Tree(pruferSequence: MinimalSequence(elements: [3, 3, 3, 4])))
        #expect(fromRange.pruferSequence == [3, 3, 3, 4])
        let fromRepeat = try #require(Tree(pruferSequence: repeatElement(0, count: 8)))
        #expect(fromRepeat.pruferSequence == [0, 0, 0, 0, 0, 0, 0, 0])
    }
}
