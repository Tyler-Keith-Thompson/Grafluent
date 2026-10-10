// `approximateMinimumVertexCover()` and `approximateMinimumVertexCover(weight:)` (catalog §ApproxVC,
// CV-087 – CV-111): Bar-Yehuda–Even in position order, exact; a cover; its weight (the sum of the
// closure's values) as the catalog's; within twice the least cover weight, found by brute force on
// rows of at most 16 vertices (the catalog's optimum otherwise); unweighted and loop-free, inside
// the ends of `maximalMatching()`. Graphs are `UndirectedAdjacencyList` built by inserting the row's
// vertices, then its edges in order, so rows are in position order (a self-loop twice); `multigraph`
// rows are `ReferencePseudograph`, whose rows are in position order too; `L …; R …` rows are
// `BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by their index in `vertices`
// (bit i of a mask is the vertex at index i). Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import Covering
import GrafluentTestSupport
import GraphProtocols
import MatchingModule
import Testing

@Suite("approximateMinimumVertexCover")
struct ApproximateVertexCoverTests {
    @Test("CV-087 empty graph: []")
    func cv087() {
        // V []; E []; approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 0)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-088 one edge: [0]")
    func cv088() {
        // V [0, 1]; E [0-1]; approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-089 self-loop: [0]")
    func cv089() {
        // V [0]; E [0-0]; approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(total <= 2 * least)
    }

    @Test("CV-090 loop and edge: [0]")
    func cv090() {
        // V [0, 1]; E [0-0, 0-1]; approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(total <= 2 * least)
    }

    @Test("CV-091 parallel edges: [0, 1]")
    func cv091() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-092 triangle: [0, 1]")
    func cv092() {
        // K(3); approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 2)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-093 P(5): [0, 1, 2, 3]")
    func cv093() {
        // P(5); approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0, 1, 2, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 2)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-094 C(6): [0, 1, 2, 3, 4]")
    func cv094() {
        // C(6); approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0, 1, 2, 3, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 3)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-095 star(4): hub first: [0]")
    func cv095() {
        // star(4); approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-096 star(4) leaves first: [0]")
    func cv096() {
        // V [0, 1, 2, 3, 4]; E [1-0, 2-0, 3-0, 4-0]; approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(1, 0), (2, 0), (3, 0), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-097 K(5): [0, 1, 2, 3]")
    func cv097() {
        // K(5); approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0, 1, 2, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 4)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-098 Petersen: [0, 1, 2, 3, 4, 5, 6, 7]")
    func cv098() {
        // nx(petersen_graph); approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 6)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-099 positions not in NetworkX order: [0, 2]")
    func cv099() {
        // V [0, 1, 2, 3]; E [2-3, 0-1, 1-2]; approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(2, 3), (0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 2)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-100 lcg(16,30,2): [1, 2, 3, 6, 7, 8, 10, 11, 12, 15]")
    func cv100() {
        // lcg(16,30,2); approximateMinimumVertexCover()
        let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.approximateMinimumVertexCover()
        #expect(cover == [1, 2, 3, 6, 7, 8, 10, 11, 12, 15] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = cover.count
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = n
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 9)
        #expect(total <= 2 * least)
        // Unweighted on a loop-free graph: inside the ends of maximalMatching().
        let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })
        #expect(cover.allSatisfy { matched.contains($0) })
    }

    @Test("CV-101 one edge, heavier first end: [1]; weight 1")
    func cv101() {
        // V [0, 1]; E [0-1]; w [3, 1]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [3, 1]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [1] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 1)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 1)
        #expect(total <= 2 * least)
    }

    @Test("CV-102 equal weights: lesser index: [0]; weight 2")
    func cv102() {
        // V [0, 1]; E [0-1]; w [2, 2]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [2, 2]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 2)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 2)
        #expect(total <= 2 * least)
    }

    @Test("CV-103 star, heavy hub: [1, 2, 3, 4]; weight 4")
    func cv103() {
        // star(4); w [10, 1, 1, 1, 1]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [10, 1, 1, 1, 1]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [1, 2, 3, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 4)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 4)
        #expect(total <= 2 * least)
    }

    @Test("CV-104 star, light hub: [0]; weight 1")
    func cv104() {
        // star(4); w [1, 5, 5, 5, 5]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [1, 5, 5, 5, 5]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 1)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 1)
        #expect(total <= 2 * least)
    }

    @Test("CV-105 path, residual costs carry: [0, 1, 2]; weight 7")
    func cv105() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-3]; w [2, 3, 2, 3]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [2, 3, 2, 3]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0, 1, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 7)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 4)
        #expect(total <= 2 * least)
    }

    @Test("CV-106 zero weights: [0, 2]; weight 0")
    func cv106() {
        // C(4); w [0, 1, 0, 1]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [0, 1, 0, 1]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 0)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 0)
        #expect(total <= 2 * least)
    }

    @Test("CV-107 triangle weighted: [0, 1]; weight 3")
    func cv107() {
        // K(3); w [1, 2, 3]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [1, 2, 3]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 3)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 3)
        #expect(total <= 2 * least)
    }

    @Test("CV-108 self-loop weighted: [0]; weight 5")
    func cv108() {
        // V [0, 1]; E [0-0, 0-1]; w [5, 1]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [5, 1]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 5)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 5)
        #expect(total <= 2 * least)
    }

    @Test("CV-109 float weights: [0, 1]; weight 1.25")
    func cv109() {
        // V [0, 1, 2]; E [0-1, 1-2]; w [0.5, 0.75, 0.25]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Double] = [0.5, 0.75, 0.25]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0.0) { $0 + weights[$1] }
        #expect(total == 1.25)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0.0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0.0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 0.75)
        #expect(total <= 2 * least)
    }

    @Test("CV-110 lcgv(12,20,3,9): [0, 1, 5, 6, 7, 9, 11]; weight 34")
    func cv110() {
        // lcgv(12,20,3,9); w [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0, 1, 5, 6, 7, 9, 11] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 34)
        // Within twice the least weight of a vertex cover, found by brute force over every subset.
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 28)
        #expect(total <= 2 * least)
    }

    @Test("CV-111 lcgv(20,40,5,5): [0, 1, 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 15, 16]; weight 42")
    func cv111() {
        // lcgv(20,40,5,5); w [4, 4, 2, 1, 5, 1, 4, 4, 4, 3, 5, 4, 1, 3, 4, 4, 2, 5, 5, 3]; approximateMinimumVertexCover(weight:)
        let pairs: [(Int, Int)] = [(12, 13), (14, 5), (15, 11), (19, 9), (10, 4), (15, 14), (8, 11), (13, 17), (8, 3), (2, 0), (8, 2), (1, 14), (10, 9), (15, 13), (5, 9), (0, 1), (14, 18), (14, 16), (8, 14), (12, 0), (7, 16), (11, 17), (1, 12), (1, 5), (11, 18), (12, 10), (15, 19), (11, 12), (8, 9), (18, 0), (7, 1), (7, 2), (2, 17), (8, 6), (17, 14), (6, 15), (1, 3), (7, 3), (15, 18), (13, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 40)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [4, 4, 2, 1, 5, 1, 4, 4, 4, 3, 5, 4, 1, 3, 4, 4, 2, 5, 5, 3]
        let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })
        #expect(cover == [0, 1, 2, 3, 4, 5, 8, 9, 11, 12, 13, 14, 15, 16] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 42)
        // Within twice the least weight of a vertex cover, 40: 20 vertices are too many for brute
        // force here; ref.py found it with NetworkX's max_weight_clique on the complement.
        let least = 40
        #expect(total <= 2 * least)
    }
}
