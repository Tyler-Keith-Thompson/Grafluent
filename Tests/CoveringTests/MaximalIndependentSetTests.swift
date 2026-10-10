// `maximalIndependentSet()` and `maximalIndependentSet(containing:)` (catalog §MaximalIS, CV-112 –
// CV-128): the greedy set in vertex order, seeds first, exact; independent and maximal (checked
// here); the greedy pass written out for the unseeded rows; the seeds in it; nil exactly when two
// seeds are adjacent or one is looped. Graphs are `UndirectedAdjacencyList` built by inserting the
// row's vertices, then its edges in order, so rows are in position order (a self-loop twice);
// `multigraph` rows are `ReferencePseudograph`, whose rows are in position order too; `L …; R …`
// rows are `BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by their index in
// `vertices` (bit i of a mask is the vertex at index i). Generated from cases.md by swiftgen.py,
// which re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import Covering
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("maximalIndependentSet")
struct MaximalIndependentSetTests {
    @Test("CV-112 empty graph: []")
    func cv112() {
        // V []; E []; maximalIndependentSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-113 one vertex: [0]")
    func cv113() {
        // V [0]; E []; maximalIndependentSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [0] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-114 self-loop: empty: []")
    func cv114() {
        // V [0]; E [0-0]; maximalIndependentSet()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-115 P(5): [0, 2, 4]")
    func cv115() {
        // P(5); maximalIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [0, 2, 4] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-116 star(3): hub first: [0]")
    func cv116() {
        // star(3); maximalIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [0] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-117 star(3), seeded with a leaf: [1, 2, 3]")
    func cv117() throws {
        // star(3); maximalIndependentSet(containing: [1])
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet(containing: [1] as [Int])
        #expect(result == [1, 2, 3] as [Int])
        let set = try #require(result)
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // The seeds are in it.
        #expect(([1] as [Int]).allSatisfy { set.contains($0) })
    }

    @Test("CV-118 C(6): [0, 2, 4]")
    func cv118() {
        // C(6); maximalIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [0, 2, 4] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-119 C(6) seeded {1, 4}: [1, 4]")
    func cv119() throws {
        // C(6); maximalIndependentSet(containing: [1, 4])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet(containing: [1, 4] as [Int])
        #expect(result == [1, 4] as [Int])
        let set = try #require(result)
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // The seeds are in it.
        #expect(([1, 4] as [Int]).allSatisfy { set.contains($0) })
    }

    @Test("CV-120 seeds adjacent: nil: nil")
    func cv120() {
        // C(6); maximalIndependentSet(containing: [1, 2])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet(containing: [1, 2] as [Int])
        #expect(result == nil)
        // Why, checked here: two seeds are adjacent, or a seed has a self-loop.
        let seedIndices = Set(([1, 2] as [Int]).map { vertexList.firstIndex(of: $0)! })
        #expect(ends.contains { seedIndices.contains($0.0) && seedIndices.contains($0.1) })
    }

    @Test("CV-121 seed with a self-loop: nil: nil")
    func cv121() {
        // V [0, 1]; E [0-0, 0-1]; maximalIndependentSet(containing: [0])
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet(containing: [0] as [Int])
        #expect(result == nil)
        // Why, checked here: two seeds are adjacent, or a seed has a self-loop.
        let seedIndices = Set(([0] as [Int]).map { vertexList.firstIndex(of: $0)! })
        #expect(ends.contains { seedIndices.contains($0.0) && seedIndices.contains($0.1) })
    }

    @Test("CV-122 loop skipped: [1]")
    func cv122() {
        // V [0, 1]; E [0-0, 0-1]; maximalIndependentSet()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [1] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-123 Petersen: [0, 2, 6]")
    func cv123() {
        // nx(petersen_graph); maximalIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [0, 2, 6] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-124 letters: [d, c]")
    func cv124() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; maximalIndependentSet()
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == ["d", "c"] as [String])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-125 repeated seed: [0, 2]")
    func cv125() throws {
        // P(3); maximalIndependentSet(containing: [2, 2])
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet(containing: [2, 2] as [Int])
        #expect(result == [0, 2] as [Int])
        let set = try #require(result)
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // The seeds are in it.
        #expect(([2, 2] as [Int]).allSatisfy { set.contains($0) })
    }

    @Test("CV-126 parallel edges: [0, 2]")
    func cv126() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; maximalIndependentSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [0, 2] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-127 lcg(16,30,2): [0, 2, 3, 6, 9]")
    func cv127() {
        // lcg(16,30,2); maximalIndependentSet()
        let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet()
        #expect(result == [0, 2, 3, 6, 9] as [Int])
        let set = result
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // Greedy in vertex order, written out: each vertex joins when it has no self-loop and no
        // neighbour in the set yet.
        var greedy: [Int] = []
        for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }
        #expect(members == greedy)
    }

    @Test("CV-128 lcg(16,30,2) seeded: [0, 3, 5, 6, 7, 9]")
    func cv128() throws {
        // lcg(16,30,2); maximalIndependentSet(containing: [5, 9])
        let pairs: [(Int, Int)] = [(12, 10), (7, 11), (12, 6), (1, 10), (7, 2), (0, 10), (10, 13), (14, 7), (8, 6), (13, 6), (7, 10), (15, 3), (6, 4), (11, 9), (1, 12), (8, 4), (15, 12), (12, 4), (0, 15), (10, 14), (11, 1), (14, 12), (8, 9), (2, 11), (2, 14), (2, 5), (5, 1), (3, 12), (0, 1), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.maximalIndependentSet(containing: [5, 9] as [Int])
        #expect(result == [0, 3, 5, 6, 7, 9] as [Int])
        let set = try #require(result)
        // In `vertices` order, each vertex once.
        let members = set.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Independent, checked here: no edge, and no self-loop, has both ends in the set.
        for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), "\(vertexList[a])–\(vertexList[b]) inside the set") }
        #expect(graph.isIndependentSet(set))
        // Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.
        for v in 0 ..< n where !inSet.contains(v) {
            #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) could join")
        }
        // The seeds are in it.
        #expect(([5, 9] as [Int]).allSatisfy { set.contains($0) })
    }
}
