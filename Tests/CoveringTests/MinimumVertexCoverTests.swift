// `lexicographicallyFirstMinimumVertexCover()` and `minimumVertexCover()` (catalog §MinimumVC,
// CV-050 – CV-071): the lexicographically least minimum vertex cover by vertex index, exact; in
// `vertices` order; a cover (checked here: every edge and every self-loop has an end in it);
// `minimumVertexCover()` a cover as small, the complement of `maximumIndependentSet()`, of n − α
// vertices; the complement of `lexicographicallyFirstMaximumIndependentSet()` a cover as small too;
// on rows of at most 16 vertices the lexicographically least of the smallest covers by brute force,
// and the complement of the lexicographically least maximum independent set; on `BipartiteGraph`
// rows as large as `maximumBipartiteMatching()` (König), and König's own cover where it differs.
// Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in
// order, so rows are in position order (a self-loop twice); `multigraph` rows are
// `ReferencePseudograph`, whose rows are in position order too; `L …; R …` rows are
// `BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by their index in `vertices`
// (bit i of a mask is the vertex at index i). Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import Covering
import GrafluentTestSupport
import GraphProtocols
import MatchingModule
import Testing

@Suite("lexicographicallyFirstMinimumVertexCover() and minimumVertexCover()")
struct MinimumVertexCoverTests {
    @Test("CV-050 empty graph: []")
    func cv050() {
        // V []; E []; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 0)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-051 one vertex: []")
    func cv051() {
        // V [0]; E []; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 0)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-052 self-loop: its vertex: [0]")
    func cv052() {
        // V [0]; E [0-0]; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 1)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [0] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-053 one edge: the lesser end: [0]")
    func cv053() {
        // V [0, 1]; E [0-1]; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 1)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-054 loop and edge: [0]")
    func cv054() {
        // V [0, 1]; E [0-0, 0-1]; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 1)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [0] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-055 parallel edges: [1]")
    func cv055() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 1)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-056 triangle: [0, 1]")
    func cv056() {
        // K(3); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 2)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1, 2] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-057 K(4): [0, 1, 2]")
    func cv057() {
        // K(4); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 3)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1, 2, 3] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-058 P(4): [0, 2]")
    func cv058() {
        // P(4); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 2)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1, 3] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-059 C(5): [0, 1, 3]")
    func cv059() {
        // C(5); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 3)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1, 3, 4] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-060 star(5): the hub: [0]")
    func cv060() {
        // star(5); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 1)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [0] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-061 Petersen: 6: [0, 1, 3, 7, 8, 9]")
    func cv061() {
        // nx(petersen_graph); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1, 3, 7, 8, 9] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 6)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-062 Kb(2,3): the left side: [0, 1]")
    func cv062() throws {
        // Kb(2,3); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1] as [Int])
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 2)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [0, 1] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
        // König: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching().edges.count)
        #expect(cover.count == 2)
    }

    @Test("CV-063 Kb(3,2): the right side: [3, 4]")
    func cv063() throws {
        // Kb(3,2); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (1, 3), (1, 4), (2, 3), (2, 4)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [3, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 2)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [3, 4] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
        // König: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching().edges.count)
        #expect(cover.count == 2)
    }

    @Test("CV-064 L [0,1,2]; R [3,4,5]: lex vs Koenig: [0, 1, 2]")
    func cv064() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5]; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 3)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [3, 4, 5] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
        // König: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching().edges.count)
        #expect(cover.count == 3)
        // König's own cover, the minimum cover with the most left vertices, is a different one.
        let sides = try #require(graph.bipartition())
        #expect(graph.minimumVertexCover(bipartition: sides) == [0, 1, 2] as [Int])
    }

    @Test("CV-065 BipartiteGraph with an isolated right vertex: [0, 1]")
    func cv065() throws {
        // L [0, 1]; R [2, 3, 4]; E [0-2, 1-2, 1-3]; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 2), (1, 2), (1, 3)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1] as [Int])
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 2)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [2, 3] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
        // König: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching().edges.count)
        #expect(cover.count == 2)
        // König's own cover, the minimum cover with the most left vertices, is a different one.
        let sides = try #require(graph.bipartition())
        #expect(graph.minimumVertexCover(bipartition: sides) == [0, 1] as [Int])
    }

    @Test("CV-066 lcgb(8,6,18,7): [0, 1, 3, 4, 5, 6]")
    func cv066() throws {
        // lcgb(8,6,18,7); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(6, 13), (1, 13), (0, 8), (3, 12), (3, 11), (0, 10), (5, 12), (5, 11), (4, 13), (0, 9), (6, 8), (5, 8), (0, 13), (6, 9), (5, 13), (1, 9), (4, 8), (4, 10)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], right: [8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edgeCount == 18)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1, 3, 4, 5, 6] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 6)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [8, 9, 10, 11, 12, 13] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
        // König: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching().edges.count)
        #expect(cover.count == 6)
        // König's own cover, the minimum cover with the most left vertices, is a different one.
        let sides = try #require(graph.bipartition())
        #expect(graph.minimumVertexCover(bipartition: sides) == [0, 1, 3, 4, 5, 6] as [Int])
    }

    @Test("CV-067 grid(4,5): [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]")
    func cv067() {
        // grid(4,5); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (5, 10), (6, 7), (6, 11), (7, 8), (7, 12), (8, 9), (8, 13), (9, 14), (10, 11), (10, 15), (11, 12), (11, 16), (12, 13), (12, 17), (13, 14), (13, 18), (14, 19), (15, 16), (16, 17), (17, 18), (18, 19)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 31)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 2, 4, 6, 8, 10, 12, 14, 16, 18] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 10)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1, 3, 5, 7, 9, 11, 13, 15, 17, 19] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // 20 vertices, too many for brute force here (ref.py checked the row against an
        // independence-number oracle and igraph): minimal, at least: no vertex can leave it.
        for v in members {
            #expect(ends.contains { ($0.0 == v && !inSet.contains($0.1)) || ($0.1 == v && !inSet.contains($0.0)) || $0 == (v, v) }, "\(vertexList[v]) could leave")
        }
    }

    @Test("CV-068 mixed components: [0, 1, 4, 6]")
    func cv068() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7]; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1, 4, 6] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 4)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [1, 2, 4, 6] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-069 letters: [d, c]")
    func cv069() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; lexicographicallyFirstMinimumVertexCover()
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == ["d", "c"] as [String])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 2)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == ["a", "b"] as [String])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }

    @Test("CV-070 lcg(18,35,8): [0, 1, 2, 4, 5, 6, 10, 11, 14, 15]")
    func cv070() {
        // lcg(18,35,8); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(4, 6), (14, 7), (14, 5), (16, 5), (1, 11), (9, 1), (2, 7), (13, 14), (12, 5), (6, 0), (11, 15), (16, 4), (3, 10), (4, 7), (11, 9), (16, 15), (6, 16), (0, 12), (15, 13), (12, 15), (17, 0), (2, 5), (1, 17), (15, 10), (11, 6), (15, 3), (10, 4), (8, 14), (5, 1), (4, 11), (11, 7), (15, 9), (10, 9), (5, 4), (13, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 35)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1, 2, 4, 5, 6, 10, 11, 14, 15] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 10)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [0, 1, 5, 6, 7, 10, 11, 14, 15, 16] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // 18 vertices, too many for brute force here (ref.py checked the row against an
        // independence-number oracle and igraph): minimal, at least: no vertex can leave it.
        for v in members {
            #expect(ends.contains { ($0.0 == v && !inSet.contains($0.1)) || ($0.1 == v && !inSet.contains($0.0)) || $0 == (v, v) }, "\(vertexList[v]) could leave")
        }
    }

    @Test("CV-071 wheel(7): [0, 1, 2, 4, 6]")
    func cv071() {
        // wheel(7); lexicographicallyFirstMinimumVertexCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 14)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.lexicographicallyFirstMinimumVertexCover()
        #expect(result == [0, 1, 2, 4, 6] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(result))
        // minimumVertexCover(): the complement of maximumIndependentSet(), as small, n − α vertices.
        let cover = graph.minimumVertexCover()
        #expect(cover.count == 5)
        #expect(graph.isVertexCover(cover))
        let independent = graph.maximumIndependentSet()
        #expect(cover == vertexList.filter { !independent.contains($0) })
        #expect(cover.count == n - graph.independenceNumber())
        #expect(result.count == cover.count)
        // The complement of the lexicographically first maximum independent set is a minimum cover too.
        let leastSet = graph.lexicographicallyFirstMaximumIndependentSet()
        let leastCover = vertexList.filter { !leastSet.contains($0) }
        #expect(leastCover == [0, 2, 4, 6, 7] as [Int])
        #expect(graph.isVertexCover(leastCover))
        // Brute force over every subset (bit i is the vertex at index i): of the covers the smallest,
        // and of those the lexicographically least, the one holding the least vertex of the symmetric
        // difference.
        var first = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            let least = (mask ^ max(first, 0)).trailingZeroBitCount
            if first < 0 || mask.nonzeroBitCount < first.nonzeroBitCount || (mask.nonzeroBitCount == first.nonzeroBitCount && mask & (1 << least) != 0) { first = mask }
        }
        #expect(members == (0 ..< n).filter { first & (1 << $0) != 0 })
        // Brute force over every subset (bit i is the vertex at index i): of the independent ones the
        // largest, and of those the lexicographically least, the one holding the least vertex of the
        // symmetric difference.
        var best = -1
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        // That least set's complement is a cover as small as any.
        #expect(leastCover == (0 ..< n).filter { best & (1 << $0) == 0 }.map { vertexList[$0] })
        #expect(leastCover.count == first.nonzeroBitCount)
    }
}
