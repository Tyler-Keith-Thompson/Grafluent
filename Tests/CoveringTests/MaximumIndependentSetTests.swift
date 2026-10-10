// `maximumIndependentSet()` (catalog §MaximumIS, CV-001 – CV-041): the lexicographically least
// maximum independent set by vertex index, exact; in `vertices` order; independent (checked here: no
// edge and no self-loop inside); its size is `independenceNumber()` and its complement
// `minimumVertexCover()`; and on rows of at most 16 vertices the lexicographically least of the
// largest independent subsets by brute force. Graphs are `UndirectedAdjacencyList` built by
// inserting the row's vertices, then its edges in order, so rows are in position order (a self-loop
// twice); `multigraph` rows are `ReferencePseudograph`, whose rows are in position order too; `L …;
// R …` rows are `BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by their index in
// `vertices` (bit i of a mask is the vertex at index i). Generated from cases.md by swiftgen.py,
// which re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import Covering
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("maximumIndependentSet()")
struct MaximumIndependentSetTests {
    @Test("CV-001 empty graph: []")
    func cv001() throws {
        // V []; E []; maximumIndependentSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-002 one vertex: [0]")
    func cv002() throws {
        // V [0]; E []; maximumIndependentSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-003 one vertex with a self-loop: []")
    func cv003() throws {
        // V [0]; E [0-0]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-004 two isolated vertices: [0, 1]")
    func cv004() throws {
        // V [0, 1]; E []; maximumIndependentSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-005 one edge: the lesser end: [0]")
    func cv005() throws {
        // V [0, 1]; E [0-1]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-006 self-loop excludes its vertex: [1]")
    func cv006() throws {
        // V [0, 1]; E [0-0, 0-1]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-007 parallel edges count once: [0, 2]")
    func cv007() throws {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-008 triangle: [0]")
    func cv008() throws {
        // K(3); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-009 K(5): [0]")
    func cv009() throws {
        // K(5); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-010 path P(2): [0]")
    func cv010() throws {
        // P(2); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-011 path P(4): {0,2} beats {0,3}, {1,3}: [0, 2]")
    func cv011() throws {
        // P(4); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-012 path P(5): [0, 2, 4]")
    func cv012() throws {
        // P(5); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-013 path P(6): [0, 2, 4]")
    func cv013() throws {
        // P(6); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-014 cycle C(4): [0, 2]")
    func cv014() throws {
        // C(4); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-015 cycle C(5): [0, 2]")
    func cv015() throws {
        // C(5); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-016 cycle C(6): [0, 2, 4]")
    func cv016() throws {
        // C(6); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-017 cycle C(7): [0, 2, 4]")
    func cv017() throws {
        // C(7); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-018 star(4): the leaves: [1, 2, 3, 4]")
    func cv018() throws {
        // star(4); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [1, 2, 3, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-019 wheel(5): [1, 3]")
    func cv019() throws {
        // wheel(5); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [1, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-020 wheel(6): [1, 3, 5]")
    func cv020() throws {
        // wheel(6); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [1, 3, 5] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-021 Petersen: [0, 2, 8, 9]")
    func cv021() throws {
        // nx(petersen_graph); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 8, 9] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-022 grid(3,4): [0, 2, 5, 7, 8, 10]")
    func cv022() throws {
        // grid(3,4); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 17)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 5, 7, 8, 10] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-023 grid(5,5): [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24]")
    func cv023() throws {
        // grid(5,5); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (15, 20), (16, 17), (16, 21), (17, 18), (17, 22), (18, 19), (18, 23), (19, 24), (20, 21), (21, 22), (22, 23), (23, 24)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 40)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // 25 vertices, too many for brute force here (ref.py checked the row against an
        // independence-number oracle and igraph): maximal, at least.
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
    }

    @Test("CV-024 Kb(2,3) as BipartiteGraph: [2, 3, 4]")
    func cv024() throws {
        // Kb(2,3); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1] as [Int])
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [2, 3, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-025 Kb(3,3): [0, 1, 2]")
    func cv025() throws {
        // Kb(3,3); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        #expect(graph.edgeCount == 9)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 1, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-026 mixed components: triangle, path, looped pendant: [0, 3, 5, 7]")
    func cv026() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 3, 5, 7] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-027 vertex order, not label order: [d, c]")
    func cv027() throws {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; maximumIndependentSet()
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == ["d", "c"] as [String])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-028 bipartite, interleaved vertex order: [0, 1, 2]")
    func cv028() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0-3, 3-1, 1-4, 4-2, 2-5]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 3), (3, 1), (1, 4), (4, 2), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 1, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-029 bipartite core: perfect matching, lattice choice: [0, 2, 4]")
    func cv029() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-3, 3-0, 0-5, 4-5]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-030 odd cycle with pendant: [0, 3, 5]")
    func cv030() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-3, 3-4, 4-0, 2-5]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 3, 5] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-031 all vertices looped: []")
    func cv031() throws {
        // V [0, 1, 2]; E [0-0, 1-1, 2-2, 0-1]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 0), (1, 1), (2, 2), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-032 loop in a bipartite piece splits it: [0, 3]")
    func cv032() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-4, 2-2]; maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-033 nx(bull_graph): [0, 3, 4]")
    func cv033() throws {
        // nx(bull_graph); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 3, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-034 nx(house_graph): [0, 3]")
    func cv034() throws {
        // nx(house_graph); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-035 nx(krackhardt_kite_graph): [0, 4, 7, 9]")
    func cv035() throws {
        // nx(krackhardt_kite_graph); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 5), (1, 3), (1, 4), (1, 6), (2, 3), (2, 5), (3, 4), (3, 5), (3, 6), (4, 6), (5, 6), (5, 7), (6, 7), (7, 8), (8, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 18)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 4, 7, 9] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-036 nx(frucht_graph): [0, 2, 5, 9, 11]")
    func cv036() throws {
        // nx(frucht_graph); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 18)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 2, 5, 9, 11] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-037 lcg(12,20,1): [1, 2, 3, 5, 8, 11]")
    func cv037() throws {
        // lcg(12,20,1); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [1, 2, 3, 5, 8, 11] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-038 lcg(16,30,2): [0, 3, 5, 8, 11, 13, 14]")
    func cv038() throws {
        // lcg(16,30,2); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 3, 5, 8, 11, 13, 14] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-039 lcg(24,40,3): [0, 1, 2, 3, 4, 6, 7, 9, 10, 16, 18, 20, 22]")
    func cv039() throws {
        // lcg(24,40,3); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(11, 19), (11, 10), (12, 11), (7, 5), (17, 9), (19, 18), (8, 21), (22, 17), (3, 19), (7, 8), (5, 22), (11, 18), (5, 11), (13, 6), (23, 7), (17, 0), (9, 15), (12, 19), (7, 21), (12, 22), (12, 17), (5, 1), (13, 2), (5, 10), (10, 17), (23, 10), (8, 5), (19, 14), (1, 13), (11, 3), (11, 1), (23, 3), (12, 18), (11, 14), (21, 12), (2, 14), (12, 15), (21, 1), (21, 3), (12, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 40)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [0, 1, 2, 3, 4, 6, 7, 9, 10, 16, 18, 20, 22] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // 24 vertices, too many for brute force here (ref.py checked the row against an
        // independence-number oracle and igraph): maximal, at least.
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
    }

    @Test("CV-040 lcgb(6,7,15,4) as BipartiteGraph: [4, 6, 8, 9, 10, 11, 12]")
    func cv040() throws {
        // lcgb(6,7,15,4); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5] as [Int], right: [6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [4, 6, 8, 9, 10, 11, 12] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-041 lcgb(10,10,25,5): [3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18]")
    func cv041() throws {
        // lcgb(10,10,25,5); maximumIndependentSet()
        let pairs: [(Int, Int)] = [(2, 13), (4, 15), (5, 11), (9, 19), (0, 14), (5, 14), (8, 11), (3, 17), (8, 13), (2, 10), (8, 12), (1, 14), (0, 19), (5, 13), (5, 19), (0, 11), (4, 18), (0, 10), (4, 16), (8, 14), (7, 16), (1, 17), (1, 12), (1, 15), (1, 18)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], right: [10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edgeCount == 25)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximumIndependentSet()
        #expect(result == [3, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(result))
        // The other entry points agree: α is its size, and the minimum vertex cover is its complement.
        #expect(graph.independenceNumber() == result.count)
        #expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })
        // 20 vertices, too many for brute force here (ref.py checked the row against an
        // independence-number oracle and igraph): maximal, at least.
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
    }
}
