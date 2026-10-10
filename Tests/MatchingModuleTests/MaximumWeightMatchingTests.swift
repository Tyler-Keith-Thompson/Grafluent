// `maximumWeightMatching(weight:maximumCardinality:)` (catalog §Maximum weight: MA-015 – MA-021,
// MA-115 – MA-156): NetworkX 3.7's `max_weight_matching` output, exact edges and mates, the weight
// (the sum in `edges` order, at full precision), validity, self-loops never weighed, and the weight
// (and with `maximumCardinality` the size) against brute force over every matching. Integer rows use
// the `SignedInteger` overload, rows with a fractional weight the `FloatingPoint` one. Graphs are
// `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in order, so rows
// are in position order; `multigraph` rows are `ReferencePseudograph`, whose rows are in position
// order too (a self-loop twice, parallel edges kept); `L …; R …` rows are
// `BipartiteGraph(left:right:edges:)`. Generated from cases.md by swiftgen.py, which re-evaluates
// each row with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("maximumWeightMatching: Galil's blossom algorithm, NetworkX's output")
struct MaximumWeightMatchingTests {
    @Test("MA-015 empty graph: edges [] {}; weight 0; perfect")
    func ma015() throws {
        // V []; E []; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let weights: [Int?] = []
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [])
        #expect(matching.weight == 0)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let mates: [Int?] = []
        let mateIndices: [Int?] = []
        let matchedEdges: [Int?] = []
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-016 one self-loop, weight 5 (never weighed): edges [] {}; weight 0")
    func ma016() throws {
        // V [0]; E [0-0:5]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let weights: [Int?] = [nil]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        var loopWeighed = false
        let matching = graph.maximumWeightMatching(weight: { e in
            if graph.edges[e].u == graph.edges[e].v { loopWeighed = true }
            return weightOf(e)
        })
        #expect(!loopWeighed, "a self-loop was weighed")
        #expect(matching.edges == [])
        #expect(matching.weight == 0)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let mates: [Int?] = [nil]
        let mateIndices: [Int?] = [nil]
        let matchedEdges: [Int?] = [nil]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-017 one edge, negative weight: edges [] {}; weight 0")
    func ma017() throws {
        // V [0, 1]; E [0-1:-3]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let weights: [Int?] = [-3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [])
        #expect(matching.weight == 0)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let mates: [Int?] = [nil, nil]
        let mateIndices: [Int?] = [nil, nil]
        let matchedEdges: [Int?] = [nil, nil]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-018 one edge, negative weight, maximumCardinality: edges [0] {0–1}; weight -3; perfect")
    func ma018() throws {
        // V [0, 1]; E [0-1:-3]; maximumWeightMatching(weight:, maximumCardinality: true)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let weights: [Int?] = [-3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) }, maximumCardinality: true)
        #expect(matching.edges == [0])
        #expect(matching.weight == -3)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let mates: [Int?] = [1, 0]
        let mateIndices: [Int?] = [1, 0]
        let matchedEdges: [Int?] = [0, 0]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.edges.count == optimum.size, "maximum cardinality, by brute force")
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-019 one edge, zero weight (a zero-weight edge is taken: its slack is 0 from the start (NetworkX agrees))")
    func ma019() throws {
        // V [0, 1]; E [0-1:0]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let weights: [Int?] = [0]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0])
        #expect(matching.weight == 0)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let mates: [Int?] = [1, 0]
        let mateIndices: [Int?] = [1, 0]
        let matchedEdges: [Int?] = [0, 0]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-020 parallel pair, the later copy heavier: edges [1] {1–0}; weight 7; perfect")
    func ma020() throws {
        // multigraph V [0, 1]; E [0-1:2, 1-0:7]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int?] = [2, 7]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1])
        #expect(matching.weight == 7)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let mates: [Int?] = [1, 0]
        let mateIndices: [Int?] = [1, 0]
        let matchedEdges: [Int?] = [1, 1]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-021 parallel pair, equal weights (earlier copy): edges [0] {0–1}; weight 4; perfect")
    func ma021() throws {
        // multigraph V [0, 1]; E [0-1:4, 1-0:4]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int?] = [4, 4]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let mates: [Int?] = [1, 0]
        let mateIndices: [Int?] = [1, 0]
        let matchedEdges: [Int?] = [0, 0]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-115 NetworkX two_path: edges [1] {two–three}; weight 11")
    func ma115() throws {
        // V [one, two, three]; E [one-two:10, two-three:11]; maximumWeightMatching(weight:)
        let pairs: [(String, String)] = [("one", "two"), ("two", "three")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["one", "two", "three"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let weights: [Int?] = [10, 11]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1])
        #expect(matching.weight == 11)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["one", "two", "three"] as [String])
        let mates: [String?] = [nil, "three", "two"]
        let mateIndices: [Int?] = [nil, 2, 1]
        let matchedEdges: [Int?] = [nil, 1, 1]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<String>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<String>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-116 NetworkX path: edges [1] {2–3}; weight 11")
    func ma116() throws {
        // V [1, 2, 3, 4]; E [1-2:5, 2-3:11, 3-4:5]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [5, 11, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1])
        #expect(matching.weight == 11)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4] as [Int])
        let mates: [Int?] = [nil, 3, 2, nil]
        let mateIndices: [Int?] = [nil, 2, 1, nil]
        let matchedEdges: [Int?] = [nil, 1, 1, nil]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-117 NetworkX path, maximumCardinality: edges [0, 2] {1–2, 3–4}; weight 10; perfect")
    func ma117() throws {
        // V [1, 2, 3, 4]; E [1-2:5, 2-3:11, 3-4:5]; maximumWeightMatching(weight:, maximumCardinality: true)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [5, 11, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) }, maximumCardinality: true)
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 10)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4] as [Int])
        let mates: [Int?] = [2, 1, 4, 3]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 2, 2]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.edges.count == optimum.size, "maximum cardinality, by brute force")
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-118 NetworkX square: edges [2, 3] {1–2, 3–4}; weight 5; perfect")
    func ma118() throws {
        // V [1, 4, 2, 3]; E [1-4:2, 2-3:2, 1-2:1, 3-4:4]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 4), (2, 3), (1, 2), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 4, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Int?] = [2, 2, 1, 4]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 3])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 4, 2, 3] as [Int])
        let mates: [Int?] = [2, 3, 1, 4]
        let mateIndices: [Int?] = [2, 3, 0, 1]
        let matchedEdges: [Int?] = [2, 3, 2, 3]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-119 NetworkX floating-point weights: edges [1, 3] {2–3, 1–4}; weight 4.1324953908321405; perfect")
    func ma119() throws {
        // V [1, 2, 3, 4]; E [1-2:3.141592653589793, 2-3:2.718281828459045, 1-3:3.0, 1-4:1.4142135623730951]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (1, 3), (1, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Double?] = [3.141592653589793, 2.718281828459045, 3.0, 1.4142135623730951]
        func weightOf(_ e: Int) -> Double { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1, 3])
        #expect(matching.weight == 4.1324953908321405)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4] as [Int])
        let mates: [Int?] = [4, 3, 2, 1]
        let mateIndices: [Int?] = [3, 2, 1, 0]
        let matchedEdges: [Int?] = [3, 1, 1, 3]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Double = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Double)?
        func extend(_ k: Int, _ size: Int, _ total: Double) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(abs(matching.weight - optimum.weight) <= 1e-9 * max(1, abs(optimum.weight)), "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-120 NetworkX negative weights: edges [0] {1–2}; weight 2")
    func ma120() throws {
        // V [1, 2, 3, 4]; E [1-2:2, 1-3:-2, 2-3:1, 2-4:-1, 3-4:-6]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let weights: [Int?] = [2, -2, 1, -1, -6]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4] as [Int])
        let mates: [Int?] = [2, 1, nil, nil]
        let mateIndices: [Int?] = [1, 0, nil, nil]
        let matchedEdges: [Int?] = [0, 0, nil, nil]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-121 NetworkX negative weights, maximumCardinality: edges [1, 3] {1–3, 2–4}; weight -3; perfect")
    func ma121() throws {
        // V [1, 2, 3, 4]; E [1-2:2, 1-3:-2, 2-3:1, 2-4:-1, 3-4:-6]; maximumWeightMatching(weight:, maximumCardinality: true)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let weights: [Int?] = [2, -2, 1, -1, -6]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) }, maximumCardinality: true)
        #expect(matching.edges == [1, 3])
        #expect(matching.weight == -3)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4] as [Int])
        let mates: [Int?] = [3, 4, 1, 2]
        let mateIndices: [Int?] = [2, 3, 0, 1]
        let matchedEdges: [Int?] = [1, 3, 1, 3]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.edges.count == optimum.size, "maximum cardinality, by brute force")
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-122 NetworkX s_blossom: edges [0, 3] {1–2, 3–4}; weight 15; perfect")
    func ma122() throws {
        // V [1, 2, 3, 4]; E [1-2:8, 1-3:9, 2-3:10, 3-4:7]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Int?] = [8, 9, 10, 7]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 3])
        #expect(matching.weight == 15)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4] as [Int])
        let mates: [Int?] = [2, 1, 4, 3]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 3, 3]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-123 NetworkX s_blossom extended: edges [2, 4, 5] {2–3, 1–6, 4–5}; weight 21; perfect")
    func ma123() throws {
        // V [1, 2, 3, 4, 6, 5]; E [1-2:8, 1-3:9, 2-3:10, 3-4:7, 1-6:5, 4-5:6]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (3, 4), (1, 6), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 6, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let weights: [Int?] = [8, 9, 10, 7, 5, 6]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 4, 5])
        #expect(matching.weight == 21)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 6, 5] as [Int])
        let mates: [Int?] = [6, 3, 2, 5, 1, 4]
        let mateIndices: [Int?] = [4, 2, 1, 5, 0, 3]
        let matchedEdges: [Int?] = [4, 2, 2, 5, 4, 5]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-124 NetworkX s_t_blossom: edges [2, 4, 5] {2–3, 4–5, 1–6}; weight 17; perfect")
    func ma124() throws {
        // V [1, 2, 3, 4, 5, 6]; E [1-2:9, 1-3:8, 2-3:10, 1-4:5, 4-5:4, 1-6:3]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (1, 4), (4, 5), (1, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let weights: [Int?] = [9, 8, 10, 5, 4, 3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 4, 5])
        #expect(matching.weight == 17)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [6, 3, 2, 5, 4, 1]
        let mateIndices: [Int?] = [5, 2, 1, 4, 3, 0]
        let matchedEdges: [Int?] = [5, 2, 2, 4, 4, 5]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-125 NetworkX s_t_blossom reweighted: edges [2, 4, 5] {2–3, 4–5, 1–6}; weight 17; perfect")
    func ma125() throws {
        // V [1, 2, 3, 4, 5, 6]; E [1-2:9, 1-3:8, 2-3:10, 1-4:5, 4-5:3, 1-6:4]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (1, 4), (4, 5), (1, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let weights: [Int?] = [9, 8, 10, 5, 3, 4]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 4, 5])
        #expect(matching.weight == 17)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [6, 3, 2, 5, 4, 1]
        let mateIndices: [Int?] = [5, 2, 1, 4, 3, 0]
        let matchedEdges: [Int?] = [5, 2, 2, 4, 4, 5]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-126 NetworkX s_t_blossom, 1–6 replaced by 3–6: edges [0, 4, 5] {1–2, 4–5, 3–6}; weight 16; perfect")
    func ma126() throws {
        // V [1, 2, 3, 4, 5, 6]; E [1-2:9, 1-3:8, 2-3:10, 1-4:5, 4-5:3, 3-6:4]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (1, 4), (4, 5), (3, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let weights: [Int?] = [9, 8, 10, 5, 3, 4]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 4, 5])
        #expect(matching.weight == 16)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [2, 1, 6, 5, 4, 3]
        let mateIndices: [Int?] = [1, 0, 5, 4, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 5, 4, 4, 5]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-127 NetworkX nested_s_blossom: edges [1, 3, 6] {1–3, 2–4, 5–6}; weight 23; perfect")
    func ma127() throws {
        // V [1, 2, 3, 4, 5, 6]; E [1-2:9, 1-3:9, 2-3:10, 2-4:8, 3-5:8, 4-5:10, 5-6:6]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 5), (4, 5), (5, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let weights: [Int?] = [9, 9, 10, 8, 8, 10, 6]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1, 3, 6])
        #expect(matching.weight == 23)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [3, 4, 1, 2, 6, 5]
        let mateIndices: [Int?] = [2, 3, 0, 1, 5, 4]
        let matchedEdges: [Int?] = [1, 3, 1, 3, 6, 6]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-128 NetworkX nested_s_blossom_relabel: edges [0, 3, 6, 8] {1–2, 3–4, 5–6, 7–8}; weight 48; perfect")
    func ma128() throws {
        // V [1, 2, 7, 3, 4, 5, 6, 8]; E [1-2:10, 1-7:10, 2-3:12, 3-4:20, 3-5:20, 4-5:25, 5-6:10, 6-7:10, 7-8:8]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 7), (2, 3), (3, 4), (3, 5), (4, 5), (5, 6), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 7, 3, 4, 5, 6, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 9)
        let weights: [Int?] = [10, 10, 12, 20, 20, 25, 10, 10, 8]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 3, 6, 8])
        #expect(matching.weight == 48)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 7, 3, 4, 5, 6, 8] as [Int])
        let mates: [Int?] = [2, 1, 8, 4, 3, 6, 5, 7]
        let mateIndices: [Int?] = [1, 0, 7, 4, 3, 6, 5, 2]
        let matchedEdges: [Int?] = [0, 0, 8, 3, 3, 6, 6, 8]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-129 NetworkX nested_s_blossom_expand: edges [0, 4, 6, 9] {1–2, 3–5, 4–6, 7–8}; weight 44; perfect")
    func ma129() throws {
        // V [1, 2, 3, 4, 5, 6, 7, 8]; E [1-2:8, 1-3:8, 2-3:10, 2-4:12, 3-5:12, 4-5:14, 4-6:12, 5-7:12, 6-7:14, 7-8:12]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 5), (4, 5), (4, 6), (5, 7), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let weights: [Int?] = [8, 8, 10, 12, 12, 14, 12, 12, 14, 12]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 4, 6, 9])
        #expect(matching.weight == 44)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let mates: [Int?] = [2, 1, 5, 6, 3, 4, 8, 7]
        let mateIndices: [Int?] = [1, 0, 4, 5, 2, 3, 7, 6]
        let matchedEdges: [Int?] = [0, 0, 4, 6, 4, 6, 9, 9]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-130 NetworkX s_blossom_relabel_expand: edges [2, 3, 6, 7] {1–6, 2–3, 4–8, 5–7}; weight 67; perfect")
    func ma130() throws {
        // V [1, 2, 5, 6, 3, 4, 8, 7]; E [1-2:23, 1-5:22, 1-6:15, 2-3:25, 3-4:22, 4-5:25, 4-8:14, 5-7:13]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (1, 6), (2, 3), (3, 4), (4, 5), (4, 8), (5, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 5, 6, 3, 4, 8, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let weights: [Int?] = [23, 22, 15, 25, 22, 25, 14, 13]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 3, 6, 7])
        #expect(matching.weight == 67)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 5, 6, 3, 4, 8, 7] as [Int])
        let mates: [Int?] = [6, 3, 7, 1, 2, 8, 4, 5]
        let mateIndices: [Int?] = [3, 4, 7, 0, 1, 6, 5, 2]
        let matchedEdges: [Int?] = [2, 3, 7, 2, 3, 6, 6, 7]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-131 NetworkX nested_s_blossom_relabel_expand: edges [2, 3, 7, 8] {1–8, 2–3, 4–7, 5–6}; weight 47; perfect")
    func ma131() throws {
        // V [1, 2, 3, 8, 4, 5, 7, 6]; E [1-2:19, 1-3:20, 1-8:8, 2-3:25, 2-4:18, 3-5:18, 4-5:13, 4-7:7, 5-6:7]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (1, 8), (2, 3), (2, 4), (3, 5), (4, 5), (4, 7), (5, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 8, 4, 5, 7, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 9)
        let weights: [Int?] = [19, 20, 8, 25, 18, 18, 13, 7, 7]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 3, 7, 8])
        #expect(matching.weight == 47)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 8, 4, 5, 7, 6] as [Int])
        let mates: [Int?] = [8, 3, 2, 1, 7, 6, 4, 5]
        let mateIndices: [Int?] = [3, 2, 1, 0, 6, 7, 4, 5]
        let matchedEdges: [Int?] = [2, 3, 3, 2, 7, 8, 7, 8]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-132 NetworkX nasty_blossom1: edges [2, 5, 7, 8, 9] {2–3, 1–6, 4–8, 5–7, 9–10}; weight 146; perfect")
    func ma132() throws {
        // V [1, 2, 5, 3, 4, 6, 9, 8, 7, 10]; E [1-2:45, 1-5:45, 2-3:50, 3-4:45, 4-5:50, 1-6:30, 3-9:35, 4-8:35, 5-7:26, 9-10:5]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (3, 4), (4, 5), (1, 6), (3, 9), (4, 8), (5, 7), (9, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 5, 3, 4, 6, 9, 8, 7, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let weights: [Int?] = [45, 45, 50, 45, 50, 30, 35, 35, 26, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 5, 7, 8, 9])
        #expect(matching.weight == 146)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 5, 3, 4, 6, 9, 8, 7, 10] as [Int])
        let mates: [Int?] = [6, 3, 7, 2, 8, 1, 10, 4, 5, 9]
        let mateIndices: [Int?] = [5, 3, 8, 1, 7, 0, 9, 4, 2, 6]
        let matchedEdges: [Int?] = [5, 2, 8, 2, 7, 5, 9, 7, 8, 9]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-133 NetworkX nasty_blossom2: edges [2, 5, 7, 8, 9] {2–3, 1–6, 4–8, 5–7, 9–10}; weight 151; perfect")
    func ma133() throws {
        // V [1, 2, 5, 3, 4, 6, 9, 8, 7, 10]; E [1-2:45, 1-5:45, 2-3:50, 3-4:45, 4-5:50, 1-6:30, 3-9:35, 4-8:26, 5-7:40, 9-10:5]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (3, 4), (4, 5), (1, 6), (3, 9), (4, 8), (5, 7), (9, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 5, 3, 4, 6, 9, 8, 7, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let weights: [Int?] = [45, 45, 50, 45, 50, 30, 35, 26, 40, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 5, 7, 8, 9])
        #expect(matching.weight == 151)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 5, 3, 4, 6, 9, 8, 7, 10] as [Int])
        let mates: [Int?] = [6, 3, 7, 2, 8, 1, 10, 4, 5, 9]
        let mateIndices: [Int?] = [5, 3, 8, 1, 7, 0, 9, 4, 2, 6]
        let matchedEdges: [Int?] = [5, 2, 8, 2, 7, 5, 9, 7, 8, 9]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-134 NetworkX nasty_blossom_least_slack")
    func ma134() throws {
        // V [1, 2, 5, 3, 4, 6, 9, 8, 7, 10]; E [1-2:45, 1-5:45, 2-3:50, 3-4:45, 4-5:50, 1-6:30, 3-9:35, 4-8:28, 5-7:26, 9-10:5]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 5), (2, 3), (3, 4), (4, 5), (1, 6), (3, 9), (4, 8), (5, 7), (9, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 5, 3, 4, 6, 9, 8, 7, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let weights: [Int?] = [45, 45, 50, 45, 50, 30, 35, 28, 26, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 5, 7, 8, 9])
        #expect(matching.weight == 139)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 5, 3, 4, 6, 9, 8, 7, 10] as [Int])
        let mates: [Int?] = [6, 3, 7, 2, 8, 1, 10, 4, 5, 9]
        let mateIndices: [Int?] = [5, 3, 8, 1, 7, 0, 9, 4, 2, 6]
        let matchedEdges: [Int?] = [5, 2, 8, 2, 7, 5, 9, 7, 8, 9]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-135 NetworkX nasty_blossom_augmenting")
    func ma135() throws {
        // V [1, 2, 7, 3, 4, 5, 6, 8, 11, 9, 10, 12]; E [1-2:45, 1-7:45, 2-3:50, 3-4:45, 4-5:95, 4-6:94, 5-6:94, 6-7:50, 1-8:30, 3-11:35, 5-9:36, 7-10:26, 11-12:5]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 7), (2, 3), (3, 4), (4, 5), (4, 6), (5, 6), (6, 7), (1, 8), (3, 11), (5, 9), (7, 10), (11, 12)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 7, 3, 4, 5, 6, 8, 11, 9, 10, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 13)
        let weights: [Int?] = [45, 45, 50, 45, 95, 94, 94, 50, 30, 35, 36, 26, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 5, 8, 10, 11, 12])
        #expect(matching.weight == 241)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 7, 3, 4, 5, 6, 8, 11, 9, 10, 12] as [Int])
        let mates: [Int?] = [8, 3, 10, 2, 6, 9, 4, 1, 12, 5, 7, 11]
        let mateIndices: [Int?] = [7, 3, 10, 1, 6, 9, 4, 0, 11, 5, 2, 8]
        let matchedEdges: [Int?] = [8, 2, 11, 2, 5, 10, 5, 8, 12, 10, 11, 12]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-136 NetworkX nasty_blossom_expand_recursively")
    func ma136() throws {
        // V [1, 2, 3, 4, 5, 8, 7, 6, 10, 9]; E [1-2:40, 1-3:40, 2-3:60, 2-4:55, 3-5:55, 4-5:50, 1-8:15, 5-7:30, 7-6:10, 8-10:10, 4-9:30]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 5), (4, 5), (1, 8), (5, 7), (7, 6), (8, 10), (4, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5, 8, 7, 6, 10, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 11)
        let weights: [Int?] = [40, 40, 60, 55, 55, 50, 15, 30, 10, 10, 30]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 4, 8, 9, 10])
        #expect(matching.weight == 145)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5, 8, 7, 6, 10, 9] as [Int])
        let mates: [Int?] = [2, 1, 5, 9, 3, 10, 6, 7, 8, 4]
        let mateIndices: [Int?] = [1, 0, 4, 9, 2, 8, 7, 6, 5, 3]
        let matchedEdges: [Int?] = [0, 0, 4, 10, 4, 9, 8, 8, 9, 10]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-137 ties: unit-weight triangle: edges [1] {1–2}; weight 1")
    func ma137() throws {
        // V [0, 1, 2]; E [0-1:1, 1-2:1, 2-0:1]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [1, 1, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let mates: [Int?] = [nil, 2, 1]
        let mateIndices: [Int?] = [nil, 2, 1]
        let matchedEdges: [Int?] = [nil, 1, 1]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-138 ties: unit-weight C4 (two optimal matchings): edges [0, 2] {0–1, 2–3}; weight 2; perfect")
    func ma138() throws {
        // V [0, 1, 2, 3]; E [0-1:1, 1-2:1, 2-3:1, 3-0:1]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Int?] = [1, 1, 1, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, 3, 2]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 2, 2]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-139 ties: C4 listed from a different start: edges [1, 3] {2–3, 0–1}; weight 2; perfect")
    func ma139() throws {
        // V [0, 1, 2, 3]; E [1-2:1, 2-3:1, 3-0:1, 0-1:1]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 0), (0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Int?] = [1, 1, 1, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1, 3])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, 3, 2]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [3, 3, 1, 1]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-140 ties: K4 all weights 2: edges [2, 3] {0–3, 1–2}; weight 4; perfect")
    func ma140() throws {
        // V [0, 1, 2, 3]; E [0-1:2, 0-2:2, 0-3:2, 1-2:2, 1-3:2, 2-3:2]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let weights: [Int?] = [2, 2, 2, 2, 2, 2]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2, 3])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [3, 2, 1, 0]
        let mateIndices: [Int?] = [3, 2, 1, 0]
        let matchedEdges: [Int?] = [2, 3, 3, 2]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-141 one heavy edge beats two light: edges [1] {1–2}; weight 3")
    func ma141() throws {
        // V [0, 1, 2, 3]; E [0-1:1, 1-2:3, 2-3:1]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [1, 3, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [nil, 2, 1, nil]
        let mateIndices: [Int?] = [nil, 2, 1, nil]
        let matchedEdges: [Int?] = [nil, 1, 1, nil]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-142 one heavy edge vs two light, maximumCardinality: edges [0, 2] {0–1, 2–3}; weight 2; perfect")
    func ma142() throws {
        // V [0, 1, 2, 3]; E [0-1:1, 1-2:3, 2-3:1]; maximumWeightMatching(weight:, maximumCardinality: true)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [1, 3, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) }, maximumCardinality: true)
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, 3, 2]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 2, 2]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.edges.count == optimum.size, "maximum cardinality, by brute force")
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-143 all weights negative: edges [] {}; weight 0")
    func ma143() throws {
        // V [0, 1, 2, 3]; E [0-1:-1, 1-2:-2, 2-3:-1]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [-1, -2, -1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [])
        #expect(matching.weight == 0)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [nil, nil, nil, nil]
        let mateIndices: [Int?] = [nil, nil, nil, nil]
        let matchedEdges: [Int?] = [nil, nil, nil, nil]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-144 all weights negative, maximumCardinality: edges [0, 2] {0–1, 2–3}; weight -2; perfect")
    func ma144() throws {
        // V [0, 1, 2, 3]; E [0-1:-1, 1-2:-2, 2-3:-1]; maximumWeightMatching(weight:, maximumCardinality: true)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [-1, -2, -1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) }, maximumCardinality: true)
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == -2)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, 3, 2]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 2, 2]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.edges.count == optimum.size, "maximum cardinality, by brute force")
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-145 zero weights, maximumCardinality: edges [0, 2] {0–1, 2–3}; weight 0; perfect")
    func ma145() throws {
        // V [0, 1, 2, 3]; E [0-1:0, 1-2:0, 2-3:0]; maximumWeightMatching(weight:, maximumCardinality: true)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [0, 0, 0]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) }, maximumCardinality: true)
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 0)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, 3, 2]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 2, 2]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.edges.count == optimum.size, "maximum cardinality, by brute force")
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-146 float halves (Double path, delta3 = slack/2): edges [1, 3] {1–2, 3–0}; weight 2.75; perfect")
    func ma146() throws {
        // V [0, 1, 2, 3]; E [0-1:0.5, 1-2:1.5, 2-3:0.5, 3-0:1.25]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Double?] = [0.5, 1.5, 0.5, 1.25]
        func weightOf(_ e: Int) -> Double { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1, 3])
        #expect(matching.weight == 2.75)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [3, 2, 1, 0]
        let mateIndices: [Int?] = [3, 2, 1, 0]
        let matchedEdges: [Int?] = [3, 1, 1, 3]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Double = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Double)?
        func extend(_ k: Int, _ size: Int, _ total: Double) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(abs(matching.weight - optimum.weight) <= 1e-9 * max(1, abs(optimum.weight)), "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-147 odd integer weights on a triangle plus pendant: edges [2] {2–0}; weight 7")
    func ma147() throws {
        // V [0, 1, 2, 3]; E [0-1:3, 1-2:5, 2-0:7, 2-3:1]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Int?] = [3, 5, 7, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [2])
        #expect(matching.weight == 7)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [2, nil, 0, nil]
        let mateIndices: [Int?] = [2, nil, 0, nil]
        let matchedEdges: [Int?] = [2, nil, 2, nil]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-148 loop heavier than every edge (never weighed): edges [2] {1–2}; weight 3")
    func ma148() throws {
        // V [0, 1, 2]; E [0-0:100, 0-1:2, 1-2:3]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [nil, 2, 3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        var loopWeighed = false
        let matching = graph.maximumWeightMatching(weight: { e in
            if graph.edges[e].u == graph.edges[e].v { loopWeighed = true }
            return weightOf(e)
        })
        #expect(!loopWeighed, "a self-loop was weighed")
        #expect(matching.edges == [2])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let mates: [Int?] = [nil, 2, 1]
        let mateIndices: [Int?] = [nil, 2, 1]
        let matchedEdges: [Int?] = [nil, 2, 2]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-149 multigraph: heaviest parallel copy chosen: edges [3] {1–2}; weight 5")
    func ma149() throws {
        // multigraph V [0, 1, 2]; E [0-1:1, 1-2:2, 0-1:5, 1-2:5]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 1), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int?] = [1, 2, 5, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [3])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let mates: [Int?] = [nil, 2, 1]
        let mateIndices: [Int?] = [nil, 2, 1]
        let matchedEdges: [Int?] = [nil, 3, 3]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-150 lcgw(10,20,1,9): edges [1, 3, 17, 18] {0–4, 6–3, 2–8, 1–5}; weight 31")
    func ma150() throws {
        // lcgw(10,20,1,9); maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(4, 3), (0, 4), (0, 2), (6, 3), (4, 2), (5, 2), (6, 0), (8, 4), (1, 8), (5, 4), (6, 8), (9, 5), (1, 4), (1, 3), (6, 4), (0, 8), (7, 0), (2, 8), (1, 5), (6, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let weights: [Int?] = [4, 9, 4, 8, 2, 7, 4, 3, 3, 1, 5, 5, 4, 8, 8, 2, 4, 6, 8, 8]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1, 3, 17, 18])
        #expect(matching.weight == 31)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [4, 5, 8, 6, 0, 1, 3, nil, 2, nil]
        let mateIndices: [Int?] = [4, 5, 8, 6, 0, 1, 3, nil, 2, nil]
        let matchedEdges: [Int?] = [1, 18, 17, 3, 1, 18, 3, nil, 17, nil]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-151 lcgw(12,25,2,5): edges [7, 11, 20, 21, 23, 24] {6–11, 4–0, 1–8, 9–2, 10–5, 7–3}; weight 26; perfect")
    func ma151() throws {
        // lcgw(12,25,2,5); maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(4, 6), (8, 11), (0, 6), (2, 11), (6, 5), (7, 8), (8, 2), (6, 11), (11, 7), (4, 9), (3, 1), (4, 0), (3, 8), (7, 4), (10, 2), (1, 6), (8, 9), (6, 2), (2, 5), (4, 10), (1, 8), (9, 2), (3, 6), (10, 5), (7, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 25)
        let weights: [Int?] = [2, 5, 1, 3, 2, 4, 1, 3, 4, 2, 3, 5, 1, 2, 3, 1, 2, 2, 1, 5, 5, 4, 4, 4, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [7, 11, 20, 21, 23, 24])
        #expect(matching.weight == 26)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let mates: [Int?] = [4, 8, 9, 7, 0, 10, 11, 3, 1, 2, 5, 6]
        let mateIndices: [Int?] = [4, 8, 9, 7, 0, 10, 11, 3, 1, 2, 5, 6]
        let matchedEdges: [Int?] = [11, 20, 21, 24, 11, 23, 7, 24, 20, 21, 23, 7]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-152 lcgw(12,25,2,5), maximumCardinality")
    func ma152() throws {
        // lcgw(12,25,2,5); maximumWeightMatching(weight:, maximumCardinality: true)
        let pairs: [(Int, Int)] = [(4, 6), (8, 11), (0, 6), (2, 11), (6, 5), (7, 8), (8, 2), (6, 11), (11, 7), (4, 9), (3, 1), (4, 0), (3, 8), (7, 4), (10, 2), (1, 6), (8, 9), (6, 2), (2, 5), (4, 10), (1, 8), (9, 2), (3, 6), (10, 5), (7, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 25)
        let weights: [Int?] = [2, 5, 1, 3, 2, 4, 1, 3, 4, 2, 3, 5, 1, 2, 3, 1, 2, 2, 1, 5, 5, 4, 4, 4, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) }, maximumCardinality: true)
        #expect(matching.edges == [7, 11, 20, 21, 23, 24])
        #expect(matching.weight == 26)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let mates: [Int?] = [4, 8, 9, 7, 0, 10, 11, 3, 1, 2, 5, 6]
        let mateIndices: [Int?] = [4, 8, 9, 7, 0, 10, 11, 3, 1, 2, 5, 6]
        let matchedEdges: [Int?] = [11, 20, 21, 24, 11, 23, 7, 24, 20, 21, 23, 7]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.edges.count == optimum.size, "maximum cardinality, by brute force")
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-153 lcgw(14,30,6,3) many ties: edges [1, 3, 4, 11, 16, 27] {1–4, 13–7, 12–10, 2–3, 0–9, 8–5}; weight 15")
    func ma153() throws {
        // lcgw(14,30,6,3); maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(11, 4), (1, 4), (10, 2), (13, 7), (12, 10), (6, 1), (3, 5), (0, 1), (7, 9), (0, 3), (11, 7), (2, 3), (6, 13), (3, 4), (7, 4), (4, 6), (0, 9), (6, 5), (8, 6), (8, 12), (7, 6), (2, 1), (7, 3), (12, 7), (5, 10), (8, 0), (6, 3), (8, 5), (10, 7), (4, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let weights: [Int?] = [1, 3, 2, 2, 2, 1, 2, 2, 1, 1, 1, 3, 1, 2, 1, 2, 2, 2, 1, 1, 1, 1, 2, 1, 2, 1, 2, 3, 2, 3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [1, 3, 4, 11, 16, 27])
        #expect(matching.weight == 15)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let mates: [Int?] = [9, 4, 3, 2, 1, 8, nil, 13, 5, 0, 12, nil, 10, 7]
        let mateIndices: [Int?] = [9, 4, 3, 2, 1, 8, nil, 13, 5, 0, 12, nil, 10, 7]
        let matchedEdges: [Int?] = [16, 1, 11, 11, 1, 27, nil, 3, 27, 16, 4, nil, 4, 3]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-154 lcgw(40,100,3,50) (against NetworkX only)")
    func ma154() {
        // lcgw(40,100,3,50); maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(19, 3), (18, 4), (15, 5), (9, 3), (16, 29), (25, 19), (7, 16), (6, 11), (21, 11), (3, 5), (29, 14), (39, 25), (1, 23), (19, 15), (20, 6), (17, 5), (29, 18), (26, 25), (26, 1), (26, 24), (11, 30), (5, 35), (11, 17), (19, 12), (19, 14), (20, 34), (27, 19), (15, 29), (4, 16), (23, 19), (30, 16), (25, 38), (25, 7), (8, 2), (25, 36), (5, 33), (36, 6), (37, 8), (6, 7), (35, 11), (33, 19), (16, 6), (26, 32), (38, 31), (0, 13), (1, 36), (28, 37), (38, 2), (38, 28), (24, 31), (23, 29), (37, 2), (36, 8), (37, 1), (3, 26), (20, 35), (26, 38), (17, 13), (27, 13), (27, 14), (34, 38), (6, 23), (12, 32), (14, 36), (26, 39), (12, 2), (20, 12), (9, 12), (34, 24), (8, 28), (35, 15), (33, 27), (10, 26), (15, 38), (19, 6), (18, 7), (32, 6), (33, 30), (24, 18), (17, 21), (14, 3), (39, 14), (32, 30), (31, 29), (6, 28), (4, 37), (20, 29), (32, 25), (11, 27), (18, 15), (18, 9), (29, 30), (30, 9), (31, 7), (13, 6), (35, 9), (32, 13), (8, 17), (23, 18), (32, 27)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 100)
        let weights: [Int?] = [16, 4, 40, 43, 39, 30, 16, 7, 34, 25, 22, 19, 19, 10, 1, 20, 22, 36, 16, 22, 38, 32, 50, 27, 4, 25, 19, 30, 46, 12, 20, 38, 6, 25, 38, 35, 39, 30, 48, 26, 36, 9, 27, 48, 39, 4, 16, 16, 4, 1, 1, 23, 3, 35, 43, 27, 50, 35, 7, 6, 10, 9, 42, 7, 17, 23, 1, 18, 9, 18, 33, 30, 18, 40, 24, 20, 6, 33, 43, 2, 36, 48, 14, 34, 40, 12, 20, 17, 50, 31, 25, 32, 47, 2, 15, 1, 37, 8, 42, 50]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [21, 22, 25, 27, 28, 34, 38, 40, 43, 44, 53, 54, 65, 69, 78, 81, 92, 99])
        #expect(matching.weight == 699)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int])
        let mates: [Int?] = [13, 37, 12, 26, 16, 35, 7, 6, 28, 30, nil, 17, 2, 0, 39, 29, 4, 11, 24, 33, 34, nil, nil, nil, 18, 36, 3, 32, 8, 15, 9, 38, 27, 19, 20, 5, 25, 1, 31, 14]
        let mateIndices: [Int?] = [13, 37, 12, 26, 16, 35, 7, 6, 28, 30, nil, 17, 2, 0, 39, 29, 4, 11, 24, 33, 34, nil, nil, nil, 18, 36, 3, 32, 8, 15, 9, 38, 27, 19, 20, 5, 25, 1, 31, 14]
        let matchedEdges: [Int?] = [44, 53, 65, 54, 28, 21, 38, 38, 69, 92, nil, 22, 65, 44, 81, 27, 28, 22, 78, 40, 25, nil, nil, nil, 78, 34, 54, 99, 69, 27, 92, 43, 99, 40, 25, 21, 34, 53, 43, 81]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
    }

    @Test("MA-155 bipartite K3,3 weights i·j: edges [0, 4, 8] {0–3, 1–4, 2–5}; weight 14; perfect")
    func ma155() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0-3:1, 0-4:2, 0-5:3, 1-3:2, 1-4:4, 1-5:6, 2-3:3, 2-4:6, 2-5:9]; maximumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 9)
        let weights: [Int?] = [1, 2, 3, 2, 4, 6, 3, 6, 9]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 4, 8])
        #expect(matching.weight == 14)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [3, 4, 5, 0, 1, 2]
        let mateIndices: [Int?] = [3, 4, 5, 0, 1, 2]
        let matchedEdges: [Int?] = [0, 4, 8, 0, 4, 8]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || total > best!.weight { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-156 Petersen unit weights, maximumCardinality")
    func ma156() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0-1:1, 0-4:1, 0-5:1, 1-2:1, 1-6:1, 2-3:1, 2-7:1, 3-4:1, 3-8:1, 4-9:1, 5-7:1, 5-8:1, 6-8:1, 6-9:1, 7-9:1]; maximumWeightMatching(weight:, maximumCardinality: true)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let weights: [Int?] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.maximumWeightMatching(weight: { weightOf($0) }, maximumCardinality: true)
        #expect(matching.edges == [2, 4, 6, 8, 9])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [5, 6, 7, 8, 9, 0, 1, 2, 3, 4]
        let mateIndices: [Int?] = [5, 6, 7, 8, 9, 0, 1, 2, 3, 4]
        let matchedEdges: [Int?] = [2, 4, 6, 8, 9, 2, 4, 6, 8, 9]
        for (i, v) in vertexList.enumerated() {
            #expect(matching.mate(of: v) == mates[i], "mate of \(v)")
            #expect(matching.mate(ofIndex: i) == mateIndices[i], "mate of index \(i)")
            #expect(matching.matchedEdge(of: v) == matchedEdges[i], "matched edge of \(v)")
        }
        // Valid, checked here: no position twice, no self-loop, no endpoint shared.
        #expect(Set(matching.edges).count == matching.edges.count)
        var covered = Set<Int>()
        for e in matching.edges {
            let edge = graph.edges[e]
            #expect(edge.u != edge.v, "self-loop \(edge) matched")
            #expect(covered.insert(edge.u).inserted, "\(edge.u) matched twice")
            #expect(covered.insert(edge.v).inserted, "\(edge.v) matched twice")
        }
        var sum: Int = 0
        for e in matching.edges { sum += weightOf(e) }
        #expect(matching.weight == sum, "the weight is the sum in `edges` order")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }
                return
            }
            extend(k + 1, size, total)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1, total + weightOf(positions[k]))
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0, 0)
        let optimum = try #require(best)
        #expect(matching.edges.count == optimum.size, "maximum cardinality, by brute force")
        #expect(matching.weight == optimum.weight, "optimal weight, by brute force: \(optimum.weight)")
    }
}
