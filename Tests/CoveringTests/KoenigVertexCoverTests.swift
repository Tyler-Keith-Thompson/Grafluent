// `minimumVertexCover(bipartition: g.bipartition()!)` (catalog §KoenigVC, CV-072 – CV-086): König's
// cover, NetworkX `to_vertex_cover`'s, exact, with the canonical sides asserted; a cover as large as
// `maximumBipartiteMatching(bipartition:)`; by brute force no cover smaller and the unique minimum
// cover with the most left vertices; and `minimumVertexCover()` where it differs. Graphs are
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

@Suite("minimumVertexCover(bipartition:)")
struct KoenigVertexCoverTests {
    @Test("CV-072 empty graph: []")
    func cv072() throws {
        // V []; E []; left [], right []; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [] as [Int])
        #expect(Array(sides.right) == [] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }

    @Test("CV-073 one edge: [0]")
    func cv073() throws {
        // V [0, 1]; E [0-1]; left [0], right [1]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0] as [Int])
        #expect(Array(sides.right) == [1] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
        // minimumVertexCover() is a different minimum cover: the complement of the lexicographically
        // least maximum independent set.
        #expect(graph.minimumVertexCover() == [1] as [Int])
    }

    @Test("CV-074 P(4): [0, 2]")
    func cv074() throws {
        // P(4); left [0, 2], right [1, 3]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 2] as [Int])
        #expect(Array(sides.right) == [1, 3] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
        // minimumVertexCover() is a different minimum cover: the complement of the lexicographically
        // least maximum independent set.
        #expect(graph.minimumVertexCover() == [1, 3] as [Int])
    }

    @Test("CV-075 P(5): [1, 3]")
    func cv075() throws {
        // P(5); left [0, 2, 4], right [1, 3]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 2, 4] as [Int])
        #expect(Array(sides.right) == [1, 3] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [1, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }

    @Test("CV-076 C(6): [0, 2, 4]")
    func cv076() throws {
        // C(6); left [0, 2, 4], right [1, 3, 5]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 2, 4] as [Int])
        #expect(Array(sides.right) == [1, 3, 5] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [0, 2, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
        // minimumVertexCover() is a different minimum cover: the complement of the lexicographically
        // least maximum independent set.
        #expect(graph.minimumVertexCover() == [1, 3, 5] as [Int])
    }

    @Test("CV-077 star(3): [0]")
    func cv077() throws {
        // star(3); left [0], right [1, 2, 3]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0] as [Int])
        #expect(Array(sides.right) == [1, 2, 3] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }

    @Test("CV-078 Kb(2,3): [0, 1]")
    func cv078() throws {
        // Kb(2,3); left [0, 1], right [2, 3, 4]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1] as [Int])
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 1] as [Int])
        #expect(Array(sides.right) == [2, 3, 4] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }

    @Test("CV-079 L [0,1,2]; R [3,4,5]: [0, 1, 2]")
    func cv079() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4, 2-4, 2-5]; left [0, 1, 2], right [3, 4, 5]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 1, 2] as [Int])
        #expect(Array(sides.right) == [3, 4, 5] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [0, 1, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
        // minimumVertexCover() is a different minimum cover: the complement of the lexicographically
        // least maximum independent set.
        #expect(graph.minimumVertexCover() == [3, 4, 5] as [Int])
    }

    @Test("CV-080 grid(3,3): [1, 3, 5, 7]")
    func cv080() throws {
        // grid(3,3); left [0, 2, 4, 6, 8], right [1, 3, 5, 7]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 2, 4, 6, 8] as [Int])
        #expect(Array(sides.right) == [1, 3, 5, 7] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [1, 3, 5, 7] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }

    @Test("CV-081 grid(4,4): [0, 2, 5, 7, 8, 10, 13, 15]")
    func cv081() throws {
        // grid(4,4); left [0, 2, 5, 7, 8, 10, 13, 15], right [1, 3, 4, 6, 9, 11, 12, 14]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
        #expect(Array(sides.right) == [1, 3, 4, 6, 9, 11, 12, 14] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [0, 2, 5, 7, 8, 10, 13, 15] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
        // minimumVertexCover() is a different minimum cover: the complement of the lexicographically
        // least maximum independent set.
        #expect(graph.minimumVertexCover() == [1, 3, 4, 6, 9, 11, 12, 14] as [Int])
    }

    @Test("CV-082 tree: [1, 2]")
    func cv082() throws {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 1-3, 1-4, 2-5, 2-6]; left [0, 3, 4, 5, 6], right [1, 2]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 3, 4, 5, 6] as [Int])
        #expect(Array(sides.right) == [1, 2] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [1, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }

    @Test("CV-083 two components: [1, 4]")
    func cv083() throws {
        // V [0, 1, 2, 3, 4, 5]; E [1-0, 1-2, 3-4, 5-4]; left [0, 2, 3, 5], right [1, 4]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(1, 0), (1, 2), (3, 4), (5, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 2, 3, 5] as [Int])
        #expect(Array(sides.right) == [1, 4] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [1, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }

    @Test("CV-084 parallel edges: [1]")
    func cv084() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-1, 1-2]; left [0, 2], right [1]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 2] as [Int])
        #expect(Array(sides.right) == [1] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [1] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }

    @Test("CV-085 lcgb(6,7,15,4): [0, 1, 2, 3, 4, 5]")
    func cv085() throws {
        // lcgb(6,7,15,4); left [0, 1, 2, 3, 4, 5], right [6, 7, 8, 9, 10, 11, 12]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(2, 12), (4, 7), (5, 10), (1, 11), (1, 7), (5, 12), (0, 12), (0, 9), (0, 11), (3, 7), (2, 11), (3, 6), (1, 8), (0, 6), (3, 11)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5] as [Int], right: [6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(Array(sides.right) == [6, 7, 8, 9, 10, 11, 12] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [0, 1, 2, 3, 4, 5] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
        // minimumVertexCover() is a different minimum cover: the complement of the lexicographically
        // least maximum independent set.
        #expect(graph.minimumVertexCover() == [0, 1, 2, 3, 5, 7] as [Int])
    }

    @Test("CV-086 lcgb(9,5,20,9): [9, 10, 11, 12, 13]")
    func cv086() throws {
        // lcgb(9,5,20,9); left [0, 1, 2, 3, 4, 5, 6, 7, 8], right [9, 10, 11, 12, 13]; minimumVertexCover(bipartition: g.bipartition()!)
        let pairs: [(Int, Int)] = [(8, 10), (2, 9), (7, 11), (2, 11), (0, 10), (5, 9), (0, 11), (2, 13), (5, 12), (5, 13), (8, 9), (1, 13), (4, 11), (8, 12), (6, 11), (3, 11), (4, 12), (3, 13), (8, 13), (7, 10)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], right: [9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let sides = try #require(graph.bipartition())
        #expect(Array(sides.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(Array(sides.right) == [9, 10, 11, 12, 13] as [Int])
        let cover = graph.minimumVertexCover(bipartition: sides)
        #expect(cover == [9, 10, 11, 12, 13] as [Int])
        // In `vertices` order, each vertex once.
        let members = cover.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // A vertex cover, checked here: every edge, and every self-loop, has an end in it.
        for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), "\(vertexList[a])–\(vertexList[b]) uncovered") }
        #expect(graph.isVertexCover(cover))
        // König's theorem: as large as a maximum matching.
        #expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)
        // Brute force: no cover is smaller, and of the minimum covers exactly one has the most left
        // vertices: this one (bit i is the vertex at index i).
        let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }
        var fewest = n + 1
        var minimumCovers: [Int] = []
        for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {
            if mask.nonzeroBitCount < fewest {
                fewest = mask.nonzeroBitCount
                minimumCovers = []
            }
            if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }
        }
        #expect(cover.count == fewest)
        let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0
        #expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])
    }
}
