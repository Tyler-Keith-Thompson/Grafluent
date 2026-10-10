// `approximateMinimumDominatingSet()` and `approximateMinimumDominatingSet(weight:)` (catalog
// §ApproxDS, CV-148 – CV-166): Chvátal's greedy set cover, NetworkX `min_weighted_dominating_set`'s
// output, exact; dominating (checked here); its weight; within H(Δ + 1) of the least weight, found
// by brute force. Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then
// its edges in order, so rows are in position order (a self-loop twice); `multigraph` rows are
// `ReferencePseudograph`, whose rows are in position order too; `L …; R …` rows are
// `BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by their index in `vertices`
// (bit i of a mask is the vertex at index i). Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import Covering
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("approximateMinimumDominatingSet")
struct ApproximateDominatingSetTests {
    @Test("CV-148 empty graph: []")
    func cv148() {
        // V []; E []; approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 1)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 0)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-149 one vertex: [0]")
    func cv149() {
        // V [0]; E []; approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 1)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-150 self-loop: [0]")
    func cv150() {
        // V [0]; E [0-0]; approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 1)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-151 P(3): [1]")
    func cv151() {
        // P(3); approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 3)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-152 P(6): [1, 4]")
    func cv152() {
        // P(6); approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
        #expect(result == [1, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 3)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 2)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-153 C(6): [0, 3]")
    func cv153() {
        // C(6); approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 3)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 2)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-154 star(4): [0]")
    func cv154() {
        // star(4); approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 5)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-155 Petersen: [0, 2, 6]")
    func cv155() {
        // nx(petersen_graph); approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 4)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 3)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-156 parallel edges: [1]")
    func cv156() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 3)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 1)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-157 grid(4,4): [1, 2, 5, 10, 11, 12]")
    func cv157() {
        // grid(4,4); approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
        #expect(result == [1, 2, 5, 10, 11, 12] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 5)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 4)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-158 letters: [a, c]")
    func cv158() {
        // V [d, a, c, b]; E [d-a, a-c, c-b]; approximateMinimumDominatingSet()
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "b")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
        #expect(result == ["a", "c"] as [String])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 3)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 2)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-159 three branches: [1, 2, 3]")
    func cv159() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 0-2, 0-3, 1-4, 2-5, 3-6, 1-2, 2-3]; approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 4), (2, 5), (3, 6), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
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
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 5)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 3)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-160 lcg(14,20,10): [1, 2, 3, 5, 12]")
    func cv160() {
        // lcg(14,20,10); approximateMinimumDominatingSet()
        let pairs: [(Int, Int)] = [(3, 0), (7, 0), (10, 5), (3, 9), (12, 10), (3, 11), (2, 5), (1, 5), (5, 7), (6, 12), (1, 4), (11, 13), (12, 8), (13, 2), (0, 5), (5, 12), (1, 7), (6, 9), (12, 1), (10, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let result = graph.approximateMinimumDominatingSet()
        #expect(result == [1, 2, 3, 5, 12] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        let total = result.count
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 7)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = n
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, mask.nonzeroBitCount)
        }
        #expect(least == 4)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-161 star, heavy hub: [1, 2, 3, 4]; weight 4")
    func cv161() {
        // star(4); w [10, 1, 1, 1, 1]; approximateMinimumDominatingSet(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [10, 1, 1, 1, 1]
        let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
        #expect(result == [1, 2, 3, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 4)
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 5)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 4)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-162 star, cheap hub: [0]; weight 2")
    func cv162() {
        // star(4); w [2, 1, 1, 1, 1]; approximateMinimumDominatingSet(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [2, 1, 1, 1, 1]
        let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
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
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 2)
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 5)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 2)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-163 ratio tie: least index: [0, 3]; weight 4")
    func cv163() {
        // V [0, 1, 2, 3]; E [0-1, 2-3, 1-2]; w [2, 4, 4, 2]; approximateMinimumDominatingSet(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [2, 4, 4, 2]
        let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
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
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 4)
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 3)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 4)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-164 zero weight vertex first: [0, 2]; weight 1")
    func cv164() {
        // P(4); w [1, 1, 0, 1]; approximateMinimumDominatingSet(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [1, 1, 0, 1]
        let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
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
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 1)
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 3)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 1)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-165 float weights: [0, 2, 4]; weight 0.8999999999999999")
    func cv165() {
        // P(5); w [0.3, 0.9, 0.3, 0.9, 0.3]; approximateMinimumDominatingSet(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Double] = [0.3, 0.9, 0.3, 0.9, 0.3]
        let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
        #expect(result == [0, 2, 4] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        let total = members.reduce(0.0) { $0 + weights[$1] }
        #expect(total == 0.8999999999999999)
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 3)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = (0 ..< n).reduce(0.0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, (0 ..< n).reduce(0.0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 0.8999999999999999)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }

    @Test("CV-166 lcgv(12,20,3,9): [2, 4, 9, 11]; weight 19")
    func cv166() {
        // lcgv(12,20,3,9); w [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]; approximateMinimumDominatingSet(weight:)
        let pairs: [(Int, Int)] = [(11, 7), (11, 10), (0, 11), (7, 5), (5, 9), (7, 6), (8, 9), (10, 5), (3, 7), (7, 8), (11, 6), (5, 11), (1, 6), (5, 0), (9, 3), (0, 7), (7, 9), (0, 10), (5, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let weights: [Int] = [3, 8, 5, 6, 8, 6, 6, 5, 9, 3, 8, 3]
        let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })
        #expect(result == [2, 4, 9, 11] as [Int])
        // In `vertices` order, each vertex once.
        let members = result.map { vertexList.firstIndex(of: $0)! }
        #expect(members == members.sorted() && Set(members).count == members.count)
        let inSet = Set(members)
        // Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.
        for v in 0 ..< n {
            #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, "\(vertexList[v]) undominated")
        }
        #expect(graph.isDominatingSet(result))
        let total = members.reduce(0) { $0 + weights[$1] }
        #expect(total == 19)
        // Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the
        // least weight by brute force over every subset.
        let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }
        let largestClosed = closedSizes.max() ?? 1
        #expect(largestClosed == 8)
        let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }
        var least = (0 ..< n).reduce(0) { $0 + weights[$1] }
        for mask in 0 ..< 1 << n {
            var dominated = mask
            for (a, b) in ends {
                if mask & (1 << a) != 0 { dominated |= 1 << b }
                if mask & (1 << b) != 0 { dominated |= 1 << a }
            }
            guard dominated == (1 << n) - 1 else { continue }
            least = min(least, (0 ..< n).reduce(0) { mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 })
        }
        #expect(least == 19)
        #expect(Double(total) <= harmonic * Double(least) + 1e-9)
    }
}
