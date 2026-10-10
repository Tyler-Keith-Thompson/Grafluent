// `minimumEdgeCover()` and `minimumEdgeCover(matching:)` (catalog §MinimumEC, CV-167 – CV-188): the
// matching's edges, then each uncovered vertex's first incident edge, exact positions and the edges
// they name; ascending; an edge cover (checked here); n − ν edges (Gallai); no edge cover smaller by
// brute force on rows of at most 18 edges; nil exactly when a vertex has no edge. Graphs are
// `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in order, so rows
// are in position order (a self-loop twice); `multigraph` rows are `ReferencePseudograph`, whose
// rows are in position order too; `L …; R …` rows are `BipartiteGraph(left:right:edges:)`. Brute
// force numbers vertices by their index in `vertices` (bit i of a mask is the vertex at index i).
// Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's model; see
// README.md.

import AdjacencyListModule
import BipartiteGraphs
import Covering
import GrafluentTestSupport
import GraphProtocols
import MatchingModule
import Testing

@Suite("minimumEdgeCover")
struct MinimumEdgeCoverTests {
    @Test("CV-167 empty graph: [] {}")
    func cv167() throws {
        // V []; E []; minimumEdgeCover()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [] as [UndirectedEdge<Int>])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 0 - 0)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-168 isolated vertex: nil: nil")
    func cv168() {
        // V [0]; E []; minimumEdgeCover()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let cover = graph.minimumEdgeCover()
        #expect(cover == nil)
        // Why, checked here: a vertex has no edge.
        #expect(vertexList.contains { graph.degree(of: $0) == 0 })
    }

    @Test("CV-169 self-loop covers its vertex: [0] {0–0}")
    func cv169() throws {
        // V [0]; E [0-0]; minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 0)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 1 - 0)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-170 one edge: [0] {0–1}")
    func cv170() throws {
        // V [0, 1]; E [0-1]; minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 2 - 1)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-171 edge and isolated vertex: nil: nil")
    func cv171() {
        // V [0, 1, 2]; E [0-1]; minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let cover = graph.minimumEdgeCover()
        #expect(cover == nil)
        // Why, checked here: a vertex has no edge.
        #expect(vertexList.contains { graph.degree(of: $0) == 0 })
    }

    @Test("CV-172 loop and edge: the matched edge covers both: [1] {0–1}")
    func cv172() throws {
        // V [0, 1]; E [0-0, 0-1]; minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [1])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 2 - 1)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-173 uncovered vertex takes its first edge, a loop: [0, 1] {0–1, 2–2}")
    func cv173() throws {
        // V [0, 1, 2]; E [0-1, 2-2, 1-2]; minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (2, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 1])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(2, 2)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 3 - 1)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-174 uncovered vertex takes its first edge: [0, 1] {0–1, 1–2}")
    func cv174() throws {
        // V [0, 1, 2]; E [0-1, 1-2, 2-2]; minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 1])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(1, 2)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 3 - 1)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-175 parallel edges: [0, 2] {0–1, 1–2}")
    func cv175() throws {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 2])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(1, 2)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 3 - 1)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-176 P(3): [0, 1] {0–1, 1–2}")
    func cv176() throws {
        // P(3); minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 1])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(1, 2)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 3 - 1)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-177 P(4): [0, 2] {0–1, 2–3}")
    func cv177() throws {
        // P(4); minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 2])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(2, 3)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 4 - 2)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-178 triangle: [0, 1] {0–1, 0–2}")
    func cv178() throws {
        // K(3); minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 1])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(0, 2)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 3 - 1)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-179 star(4): [0, 1, 2, 3] {0–1, 0–2, 0–3, 0–4}")
    func cv179() throws {
        // star(4); minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 1, 2, 3])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(0, 2), UndirectedEdge<Int>(0, 3), UndirectedEdge<Int>(0, 4)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 5 - 1)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-180 C(5): [0, 2, 3] {0–1, 2–3, 3–4}")
    func cv180() throws {
        // C(5); minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 2, 3])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(2, 3), UndirectedEdge<Int>(3, 4)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 5 - 2)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-181 K(4): [0, 5] {0–1, 2–3}")
    func cv181() throws {
        // K(4); minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 5])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(2, 3)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 4 - 2)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-182 Petersen: [0, 5, 9, 10, 12] {0–1, 2–3, 4–9, 5–7, 6–8}")
    func cv182() throws {
        // nx(petersen_graph); minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 5, 9, 10, 12])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(2, 3), UndirectedEdge<Int>(4, 9), UndirectedEdge<Int>(5, 7), UndirectedEdge<Int>(6, 8)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 10 - 5)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-183 blossom: [0, 3, 5] {0–1, 2–3, 4–5}")
    func cv183() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-5]; minimumEdgeCover()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [0, 3, 5])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 1), UndirectedEdge<Int>(2, 3), UndirectedEdge<Int>(4, 5)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 6 - 3)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-184 lcg(12,20,1): [5, 9, 10, 11, 13, 16] {3–10, 7–1, 2–6, 9–8, 0–5, 11–4}")
    func cv184() throws {
        // lcg(12,20,1); minimumEdgeCover()
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover()
        #expect(cover == [5, 9, 10, 11, 13, 16])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(3, 10), UndirectedEdge<Int>(7, 1), UndirectedEdge<Int>(2, 6), UndirectedEdge<Int>(9, 8), UndirectedEdge<Int>(0, 5), UndirectedEdge<Int>(11, 4)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 12 - 6)
    }

    @Test("CV-185 Kb(2,3): [0, 2, 4] {0–2, 0–4, 1–3}")
    func cv185() throws {
        // Kb(2,3); minimumEdgeCover(matching: g.maximumBipartiteMatching())
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1] as [Int])
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching())
        #expect(cover == [0, 2, 4])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 2), UndirectedEdge<Int>(0, 4), UndirectedEdge<Int>(1, 3)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 5 - 2)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-186 L [0,1,2]; R [3,4,5]: [0, 2, 4] {0–3, 1–4, 2–5}")
    func cv186() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5]; minimumEdgeCover(matching: g.maximumBipartiteMatching())
        let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching())
        #expect(cover == [0, 2, 4])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(0, 3), UndirectedEdge<Int>(1, 4), UndirectedEdge<Int>(2, 5)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 6 - 3)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }

    @Test("CV-187 isolated right vertex: nil: nil")
    func cv187() throws {
        // L [0]; R [1, 2]; E [0-1]; minimumEdgeCover(matching: g.maximumBipartiteMatching())
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = try #require(BipartiteGraph<Int>(left: [0] as [Int], right: [1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0] as [Int])
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching())
        #expect(cover == nil)
        // Why, checked here: a vertex has no edge.
        #expect(vertexList.contains { graph.degree(of: $0) == 0 })
    }

    @Test("CV-188 lcgb(6,7,15,4): [0, 1, 2, 3, 7, 11, 12] {2–12, 4–7, 5–10, 1–11, 0–9, 3–6, 1–8}")
    func cv188() throws {
        // lcgb(6,7,15,4); minimumEdgeCover(matching: g.maximumBipartiteMatching())
        let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5] as [Int], right: [6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching())
        #expect(cover == [0, 1, 2, 3, 7, 11, 12])
        let positions = try #require(cover)
        #expect(positions.map { graph.edges[$0] } == [UndirectedEdge<Int>(2, 12), UndirectedEdge<Int>(4, 7), UndirectedEdge<Int>(5, 10), UndirectedEdge<Int>(1, 11), UndirectedEdge<Int>(0, 9), UndirectedEdge<Int>(3, 6), UndirectedEdge<Int>(1, 8)])
        // Ascending, each once; every vertex is an end of one of them (checked here).
        #expect(positions == positions.sorted() && Set(positions).count == positions.count)
        var covered = Set<Int>()
        for p in positions {
            covered.insert(ends[p].0)
            covered.insert(ends[p].1)
        }
        #expect(covered.count == n)
        #expect(graph.isEdgeCover(positions))
        // Gallai: n − ν edges.
        #expect(positions.count == n - graph.maximumMatching().edges.count)
        #expect(positions.count == 13 - 6)
        // Brute force over every set of edges (bit k is position k): no edge cover is smaller.
        let m = ends.count
        var fewest = m + 1
        for mask in 0 ..< 1 << m {
            var reached = 0
            for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }
            if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }
        }
        #expect(positions.count == fewest)
    }
}
