// `independenceNumber()` (catalog §IndependenceNumber, CV-042 – CV-049): α exactly, the size of
// `maximumIndependentSet()`, n − |`minimumVertexCover()`|, and the largest independent subset by
// brute force on rows of at most 16 vertices. Graphs are `UndirectedAdjacencyList` built by
// inserting the row's vertices, then its edges in order, so rows are in position order (a self-loop
// twice); `multigraph` rows are `ReferencePseudograph`, whose rows are in position order too; `L …;
// R …` rows are `BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by their index in
// `vertices` (bit i of a mask is the vertex at index i). Generated from cases.md by swiftgen.py,
// which re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import Covering
import GraphProtocols
import Testing

@Suite("independenceNumber()")
struct IndependenceNumberTests {
    @Test("CV-042 empty graph: 0")
    func cv042() {
        // V []; E []; independenceNumber()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let alpha = graph.independenceNumber()
        #expect(alpha == 0)
        #expect(graph.maximumIndependentSet().count == alpha)
        #expect(graph.minimumVertexCover().count == n - alpha)
        // Brute force: the largest independent subset (bit i is the vertex at index i).
        var largest = 0
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) { largest = max(largest, mask.nonzeroBitCount) }
        #expect(alpha == largest)
    }

    @Test("CV-043 one vertex with a self-loop: 0")
    func cv043() {
        // V [0]; E [0-0]; independenceNumber()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let alpha = graph.independenceNumber()
        #expect(alpha == 0)
        #expect(graph.maximumIndependentSet().count == alpha)
        #expect(graph.minimumVertexCover().count == n - alpha)
        // Brute force: the largest independent subset (bit i is the vertex at index i).
        var largest = 0
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) { largest = max(largest, mask.nonzeroBitCount) }
        #expect(alpha == largest)
    }

    @Test("CV-044 C(7): 3")
    func cv044() {
        // C(7); independenceNumber()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let alpha = graph.independenceNumber()
        #expect(alpha == 3)
        #expect(graph.maximumIndependentSet().count == alpha)
        #expect(graph.minimumVertexCover().count == n - alpha)
        // Brute force: the largest independent subset (bit i is the vertex at index i).
        var largest = 0
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) { largest = max(largest, mask.nonzeroBitCount) }
        #expect(alpha == largest)
    }

    @Test("CV-045 Petersen: 4: 4")
    func cv045() {
        // nx(petersen_graph); independenceNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let alpha = graph.independenceNumber()
        #expect(alpha == 4)
        #expect(graph.maximumIndependentSet().count == alpha)
        #expect(graph.minimumVertexCover().count == n - alpha)
        // Brute force: the largest independent subset (bit i is the vertex at index i).
        var largest = 0
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) { largest = max(largest, mask.nonzeroBitCount) }
        #expect(alpha == largest)
    }

    @Test("CV-046 K(6): 1: 1")
    func cv046() {
        // K(6); independenceNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let alpha = graph.independenceNumber()
        #expect(alpha == 1)
        #expect(graph.maximumIndependentSet().count == alpha)
        #expect(graph.minimumVertexCover().count == n - alpha)
        // Brute force: the largest independent subset (bit i is the vertex at index i).
        var largest = 0
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) { largest = max(largest, mask.nonzeroBitCount) }
        #expect(alpha == largest)
    }

    @Test("CV-047 grid(4,4): 8: 8")
    func cv047() {
        // grid(4,4); independenceNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let alpha = graph.independenceNumber()
        #expect(alpha == 8)
        #expect(graph.maximumIndependentSet().count == alpha)
        #expect(graph.minimumVertexCover().count == n - alpha)
        // Brute force: the largest independent subset (bit i is the vertex at index i).
        var largest = 0
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) { largest = max(largest, mask.nonzeroBitCount) }
        #expect(alpha == largest)
    }

    @Test("CV-048 nx(dodecahedral_graph): 8")
    func cv048() {
        // nx(dodecahedral_graph); independenceNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let alpha = graph.independenceNumber()
        #expect(alpha == 8)
        #expect(graph.maximumIndependentSet().count == alpha)
        #expect(graph.minimumVertexCover().count == n - alpha)
        // 20 vertices, too many for brute force here (ref.py checked α with igraph and an oracle);
        // the independent set it counts is independent.
        let result = graph.maximumIndependentSet()
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
    }

    @Test("CV-049 lcg(20,45,6): 8")
    func cv049() {
        // lcg(20,45,6); independenceNumber()
        let pairs: [(Int, Int)] = [(11, 2), (13, 19), (4, 15), (6, 16), (14, 19), (15, 14), (10, 6), (15, 0), (3, 1), (3, 4), (17, 19), (5, 16), (11, 6), (12, 14), (8, 0), (17, 8), (0, 17), (14, 11), (3, 7), (0, 2), (15, 10), (7, 2), (6, 1), (6, 2), (16, 15), (19, 1), (14, 4), (10, 9), (8, 4), (17, 11), (0, 6), (5, 2), (13, 8), (8, 11), (7, 9), (1, 13), (16, 10), (13, 5), (17, 2), (10, 5), (19, 3), (9, 14), (9, 13), (5, 14), (17, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 45)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let alpha = graph.independenceNumber()
        #expect(alpha == 8)
        #expect(graph.maximumIndependentSet().count == alpha)
        #expect(graph.minimumVertexCover().count == n - alpha)
        // 20 vertices, too many for brute force here (ref.py checked α with igraph and an oracle);
        // the independent set it counts is independent.
        let result = graph.maximumIndependentSet()
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
    }
}
