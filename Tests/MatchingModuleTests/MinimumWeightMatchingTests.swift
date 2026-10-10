// `minimumWeightMatching(weight:)` (catalog §Minimum weight: MA-022, MA-023, MA-157 – MA-165):
// `maximumWeightMatching` on (1 + max) − w with `maximumCardinality`, exact edges and mates, the
// weight in the original weights, validity, and the least weight among maximum-cardinality matchings
// by brute force. Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then
// its edges in order, so rows are in position order; `multigraph` rows are `ReferencePseudograph`,
// whose rows are in position order too (a self-loop twice, parallel edges kept); `L …; R …` rows are
// `BipartiteGraph(left:right:edges:)`. Generated from cases.md by swiftgen.py, which re-evaluates
// each row with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("minimumWeightMatching: least weight among maximum-cardinality matchings")
struct MinimumWeightMatchingTests {
    @Test("MA-022 empty graph: edges [] {}; weight 0; perfect")
    func ma022() throws {
        // V []; E []; minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let weights: [Int?] = []
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-023 one edge: edges [0] {0–1}; weight 9; perfect")
    func ma023() throws {
        // V [0, 1]; E [0-1:9]; minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let weights: [Int?] = [9]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0])
        #expect(matching.weight == 9)
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-157 NetworkX two_path: edges [0] {one–two}; weight 10")
    func ma157() throws {
        // V [one, two, three]; E [one-two:10, two-three:11]; minimumWeightMatching(weight:)
        let pairs: [(String, String)] = [("one", "two"), ("two", "three")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["one", "two", "three"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let weights: [Int?] = [10, 11]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0])
        #expect(matching.weight == 10)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["one", "two", "three"] as [String])
        let mates: [String?] = ["two", "one", nil]
        let mateIndices: [Int?] = [1, 0, nil]
        let matchedEdges: [Int?] = [0, 0, nil]
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-158 NetworkX path: edges [0, 2] {1–2, 3–4}; weight 10; perfect")
    func ma158() throws {
        // V [1, 2, 3, 4]; E [1-2:5, 2-3:11, 3-4:5]; minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [5, 11, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-159 NetworkX square: edges [0, 1] {1–4, 2–3}; weight 4; perfect")
    func ma159() throws {
        // V [1, 4, 2, 3]; E [1-4:2, 2-3:2, 1-2:1, 3-4:4]; minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 4), (2, 3), (1, 2), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 4, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Int?] = [2, 2, 1, 4]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 1])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 4, 2, 3] as [Int])
        let mates: [Int?] = [4, 1, 3, 2]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 1, 1]
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-160 NetworkX negative weights: edges [0, 4] {1–2, 3–4}; weight -4; perfect")
    func ma160() throws {
        // V [1, 2, 3, 4]; E [1-2:2, 1-3:-2, 2-3:1, 2-4:-1, 3-4:-6]; minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let weights: [Int?] = [2, -2, 1, -1, -6]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 4])
        #expect(matching.weight == -4)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4] as [Int])
        let mates: [Int?] = [2, 1, 4, 3]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 4, 4]
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-161 NetworkX s_blossom: edges [0, 3] {1–2, 3–4}; weight 15; perfect")
    func ma161() throws {
        // V [1, 2, 3, 4]; E [1-2:8, 1-3:9, 2-3:10, 3-4:7]; minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Int?] = [8, 9, 10, 7]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-162 NetworkX min_weight_matching_max_cardinality: edges [0, 2] {1–2, 3–4}; weight 4000; perfect")
    func ma162() throws {
        // V [1, 2, 3, 4]; E [1-2:1000, 2-3:2, 3-4:3000]; minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let weights: [Int?] = [1000, 2, 3000]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 4000)
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-163 NetworkX floating-point weights: edges [1, 3] {2–3, 1–4}; weight 4.1324953908321405; perfect")
    func ma163() throws {
        // V [1, 2, 3, 4]; E [1-2:3.141592653589793, 2-3:2.718281828459045, 1-3:3.0, 1-4:1.4142135623730951]; minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (1, 3), (1, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Double?] = [3.141592653589793, 2.718281828459045, 3.0, 1.4142135623730951]
        func weightOf(_ e: Int) -> Double { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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
        #expect(abs(matching.weight - optimum.weight) <= 1e-9 * max(1, abs(optimum.weight)), "optimal weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-164 isolated vertex first (NetworkX reorders vertices) (NetworkX builds a new graph from the edges, dropping isolated vertices and reordering)")
    func ma164() throws {
        // V [9, 1, 2, 3, 4]; E [1-2:1, 2-3:1, 3-4:1, 4-1:1]; minimumWeightMatching(weight:)
        // The catalog cell lists edges [1, 3]: ref.py rebuilds the transformed graph in
        // NetworkX's G.edges() order. api.md keeps the graph (the transform is applied to the same
        // rows), which gives [0, 2]: the same size and weight. See README.md.
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [9, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let weights: [Int?] = [1, 1, 1, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [9, 1, 2, 3, 4] as [Int])
        let mates: [Int?] = [nil, 2, 1, 4, 3]
        let mateIndices: [Int?] = [nil, 2, 1, 4, 3]
        let matchedEdges: [Int?] = [nil, 0, 0, 2, 2]
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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

    @Test("MA-165 lcgw(10,20,4,7): edges [7, 10, 13, 14, 17] {8–7, 0–5, 9–6, 3–2, 4–1}; weight 15; perfect")
    func ma165() throws {
        // lcgw(10,20,4,7); minimumWeightMatching(weight:)
        let pairs: [(Int, Int)] = [(6, 2), (1, 5), (1, 3), (6, 5), (6, 4), (7, 4), (8, 5), (8, 7), (6, 3), (0, 9), (0, 5), (2, 8), (8, 6), (9, 6), (3, 2), (1, 2), (9, 1), (4, 1), (7, 3), (9, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let weights: [Int?] = [2, 5, 2, 2, 6, 7, 4, 2, 7, 3, 2, 7, 7, 3, 4, 7, 4, 4, 4, 7]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = graph.minimumWeightMatching(weight: { weightOf($0) })
        #expect(matching.edges == [7, 10, 13, 14, 17])
        #expect(matching.weight == 15)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [5, 4, 3, 2, 1, 0, 9, 8, 7, 6]
        let mateIndices: [Int?] = [5, 4, 3, 2, 1, 0, 9, 8, 7, 6]
        let matchedEdges: [Int?] = [10, 17, 14, 14, 17, 10, 13, 7, 7, 13]
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
                if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }
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
