// `minimumDominatingSet()` (catalog §MinimumDS, CV-129 – CV-147): the lexicographically least
// minimum dominating set, exact; dominating (checked here); the lexicographically least of the
// smallest dominating subsets by brute force; the greedy approximation's size where the catalog
// notes it. Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its
// edges in order, so rows are in position order (a self-loop twice); `multigraph` rows are
// `ReferencePseudograph`, whose rows are in position order too; `L …; R …` rows are
// `BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by their index in `vertices`
// (bit i of a mask is the vertex at index i). Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import Covering
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("minimumDominatingSet()")
struct MinimumDominatingSetTests {
    @Test("CV-129 empty graph: []")
    func cv129() {
        // V []; E []; minimumDominatingSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-130 one vertex: [0]")
    func cv130() {
        // V [0]; E []; minimumDominatingSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-131 self-loop: [0]")
    func cv131() {
        // V [0]; E [0-0]; minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-132 two isolated: [0, 1]")
    func cv132() {
        // V [0, 1]; E []; minimumDominatingSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0, 1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-133 one edge: [0]")
    func cv133() {
        // V [0, 1]; E [0-1]; minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-134 parallel edges: [1]")
    func cv134() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-135 P(3): the middle: [1]")
    func cv135() {
        // P(3); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [1] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-136 P(4): [0, 2]")
    func cv136() {
        // P(4); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0, 2] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-137 P(7): [0, 2, 5]")
    func cv137() {
        // P(7); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0, 2, 5] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-138 C(6): [0, 3]")
    func cv138() {
        // C(6); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-139 star(5): the hub: [0]")
    func cv139() {
        // star(5); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-140 K(4): [0]")
    func cv140() {
        // K(4); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-141 Petersen: 3: [0, 2, 6]")
    func cv141() {
        // nx(petersen_graph); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0, 2, 6] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-142 grid(3,3): [0, 2, 7]")
    func cv142() {
        // grid(3,3); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0, 2, 7] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-143 grid(4,4): [1, 7, 8, 14]")
    func cv143() {
        // grid(4,4); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [1, 7, 8, 14] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
        // The greedy approximation needs more.
        #expect(graph.approximateMinimumDominatingSet().count == 6)
    }

    @Test("CV-144 mixed components: [0, 4, 6]")
    func cv144() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 1-2, 2-0, 3-4, 4-5, 6-6, 6-7]; minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (6, 6), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [0, 4, 6] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-145 letters: [d, c]")
    func cv145() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; minimumDominatingSet()
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == ["d", "c"] as [String])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-146 three branches: [1, 2, 3]")
    func cv146() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 0-3, 1-4, 2-5, 3-6, 1-2, 2-3]; minimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [1, 2, 3] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
    }

    @Test("CV-147 lcg(14,20,10): [1, 2, 3, 12]")
    func cv147() {
        // lcg(14,20,10); minimumDominatingSet()
        let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.minimumDominatingSet()
        #expect(result == [1, 2, 3, 12] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        // Brute force over every subset (bit i is the vertex at index i): of the dominating ones the
        // smallest, and of those the lexicographically least.
        var best = -1
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            let least = (mask ^ max(best, 0)).trailingZeroBitCount
            if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }
        }
        #expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })
        // The greedy approximation needs more.
        #expect(graph.approximateMinimumDominatingSet().count == 5)
    }
}
