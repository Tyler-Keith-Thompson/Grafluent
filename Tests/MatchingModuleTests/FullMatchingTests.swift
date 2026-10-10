// `minimumWeightFullMatching(weight:)` on `BipartiteGraph` and
// `minimumWeightFullMatching(bipartition:weight:)` on a `Graph` (catalog §Full matching, MA-166 –
// MA-181): scipy's `linear_sum_assignment` on the biadjacency matrix (rows `left`, columns `right`,
// missing edges forbidden), exact edges, mates and weight; validity; the matching covers the smaller
// side; the least weight, or that no full matching exists, by brute force. Graphs are
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

@Suite("minimumWeightFullMatching: the Hungarian method in scipy's form")
struct FullMatchingTests {
    @Test("MA-166 NetworkX incomplete graph: edges [0, 1] {1–4, 2–3}; weight 200; perfect")
    func ma166() throws {
        // L [1, 2]; R [3, 4]; E [1-4:100, 2-3:100, 2-4:50]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 4), (2, 3), (2, 4)]
        let graph = try #require(BipartiteGraph<Int>(left: [1, 2] as [Int], right: [3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.left) == [1, 2] as [Int])
        let weights: [Int?] = [100, 100, 50]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [0, 1])
        #expect(matching.weight == 200)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4] as [Int])
        let mates: [Int?] = [4, 3, 2, 1]
        let mateIndices: [Int?] = [3, 2, 1, 0]
        let matchedEdges: [Int?] = [0, 1, 1, 0]
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
        #expect(matching.edges.count == 2, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 2 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-167 NetworkX no full matching: nil (no full matching)")
    func ma167() throws {
        // L [1, 2, 3]; R [4, 5, 6]; E [1-4:100, 2-4:100, 3-4:50, 3-5:50, 3-6:50]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(1, 4), (2, 4), (3, 4), (3, 5), (3, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [1, 2, 3] as [Int], right: [4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 5)
        #expect(Array(graph.left) == [1, 2, 3] as [Int])
        let weights: [Int?] = [100, 100, 50, 50, 50]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        #expect(graph.minimumWeightFullMatching(weight: { weightOf($0) }) == nil)
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var largest = 0
        func extend(_ k: Int, _ size: Int) {
            guard k < positions.count else {
                largest = max(largest, size)
                return
            }
            extend(k + 1, size)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1)
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0)
        #expect(largest < 3, "no matching covers the smaller side, by brute force")
    }

    @Test("MA-168 NetworkX square: edges [1, 3, 8] {0–4, 1–3, 2–5}; weight 850; perfect")
    func ma168() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3:400, 0-4:150, 0-5:400, 1-3:400, 1-4:450, 1-5:600, 2-3:300, 2-4:225, 2-5:300]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 9)
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        let weights: [Int?] = [400, 150, 400, 400, 450, 600, 300, 225, 300]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [1, 3, 8])
        #expect(matching.weight == 850)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [4, 3, 5, 1, 0, 2]
        let mateIndices: [Int?] = [4, 3, 5, 1, 0, 2]
        let matchedEdges: [Int?] = [1, 3, 8, 3, 1, 8]
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
        #expect(matching.edges.count == 3, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 3 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-169 NetworkX smaller left: edges [1, 7, 10] {0–4, 1–6, 2–5}; weight 442")
    func ma169() throws {
        // L [0, 1, 2]; R [3, 4, 5, 6]; E [0-3:400, 0-4:150, 0-5:400, 0-6:1, 1-3:400, 1-4:450, 1-5:600, 1-6:2, 2-3:300, 2-4:225, 2-5:290, 2-6:3]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (0, 6), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 12)
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        let weights: [Int?] = [400, 150, 400, 1, 400, 450, 600, 2, 300, 225, 290, 3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [1, 7, 10])
        #expect(matching.weight == 442)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [4, 6, 5, nil, 0, 2, 1]
        let mateIndices: [Int?] = [4, 6, 5, nil, 0, 2, 1]
        let matchedEdges: [Int?] = [1, 7, 10, nil, 1, 10, 7]
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
        #expect(matching.edges.count == 3, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 3 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-170 NetworkX smaller left, sides swapped (top = right) (the larger side as left: scipy transposes)")
    func ma170() throws {
        // L [3, 4, 5, 6]; R [0, 1, 2]; E [0-3:400, 0-4:150, 0-5:400, 0-6:1, 1-3:400, 1-4:450, 1-5:600, 1-6:2, 2-3:300, 2-4:225, 2-5:290, 2-6:3]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (0, 6), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [3, 4, 5, 6] as [Int], right: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 12)
        #expect(Array(graph.left) == [3, 4, 5, 6] as [Int])
        let weights: [Int?] = [400, 150, 400, 1, 400, 450, 600, 2, 300, 225, 290, 3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [1, 7, 10])
        #expect(matching.weight == 442)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [3, 4, 5, 6, 0, 1, 2] as [Int])
        let mates: [Int?] = [nil, 0, 2, 1, 4, 6, 5]
        let mateIndices: [Int?] = [nil, 4, 6, 5, 1, 3, 2]
        let matchedEdges: [Int?] = [nil, 1, 10, 7, 1, 7, 10]
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
        #expect(matching.edges.count == 3, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 3 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-171 NetworkX smaller right: edges [3, 8, 10] {1–4, 2–6, 3–5}; weight 442")
    func ma171() throws {
        // L [0, 1, 2, 3]; R [4, 5, 6]; E [0-4:400, 0-5:400, 0-6:300, 1-4:150, 1-5:450, 1-6:225, 2-4:400, 2-5:600, 2-6:290, 3-4:1, 3-5:2, 3-6:3]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 4), (0, 5), (0, 6), (1, 4), (1, 5), (1, 6), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3] as [Int], right: [4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 12)
        #expect(Array(graph.left) == [0, 1, 2, 3] as [Int])
        let weights: [Int?] = [400, 400, 300, 150, 450, 225, 400, 600, 290, 1, 2, 3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [3, 8, 10])
        #expect(matching.weight == 442)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [nil, 4, 6, 5, 1, 3, 2]
        let mateIndices: [Int?] = [nil, 4, 6, 5, 1, 3, 2]
        let matchedEdges: [Int?] = [nil, 3, 8, 10, 3, 10, 8]
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
        #expect(matching.edges.count == 3, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 3 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-172 NetworkX negative weights: edges [1, 2] {0–3, 1–2}; weight -1.8; perfect")
    func ma172() throws {
        // L [0, 1]; R [2, 3]; E [0-2:-2, 0-3:0.2, 1-2:-2, 1-3:0.3]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 3)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.left) == [0, 1] as [Int])
        let weights: [Double?] = [-2.0, 0.2, -2.0, 0.3]
        func weightOf(_ e: Int) -> Double { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [1, 2])
        #expect(matching.weight == -1.8)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [3, 2, 1, 0]
        let mateIndices: [Int?] = [3, 2, 1, 0]
        let matchedEdges: [Int?] = [1, 2, 2, 1]
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
        #expect(matching.edges.count == 2, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Double)?
        func extend(_ k: Int, _ size: Int, _ total: Double) {
            guard k < positions.count else {
                if size == 2 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(abs(matching.weight - optimum.weight) <= 1e-9 * max(1, abs(optimum.weight)), "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-173 empty bipartite graph: edges [] {}; weight 0; perfect")
    func ma173() throws {
        // L []; R []; E []; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = []
        let graph = try #require(BipartiteGraph<Int>(left: [] as [Int], right: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.left) == [] as [Int])
        let weights: [Int?] = []
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
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
        #expect(matching.edges.count == 0, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 0 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-174 left only, no right vertices (min(|L|, |R|) = 0: the empty matching is full): edges [] {}; weight 0")
    func ma174() throws {
        // L [0, 1]; R []; E []; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = []
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.left) == [0, 1] as [Int])
        let weights: [Int?] = []
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
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
        #expect(matching.edges.count == 0, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 0 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-175 ties: K2,2 all zero (scipy's reversed column order gives the identity)")
    func ma175() throws {
        // L [0, 1]; R [2, 3]; E [0-2:0, 0-3:0, 1-2:0, 1-3:0]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 3)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.left) == [0, 1] as [Int])
        let weights: [Int?] = [0, 0, 0, 0]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [0, 3])
        #expect(matching.weight == 0)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [2, 3, 0, 1]
        let mateIndices: [Int?] = [2, 3, 0, 1]
        let matchedEdges: [Int?] = [0, 3, 0, 3]
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
        #expect(matching.edges.count == 2, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 2 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-176 ties: K3,3 all ones: edges [0, 4, 8] {0–3, 1–4, 2–5}; weight 3; perfect")
    func ma176() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3:1, 0-4:1, 0-5:1, 1-3:1, 1-4:1, 1-5:1, 2-3:1, 2-4:1, 2-5:1]; minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 9)
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        let weights: [Int?] = [1, 1, 1, 1, 1, 1, 1, 1, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [0, 4, 8])
        #expect(matching.weight == 3)
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
        #expect(matching.edges.count == 3, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 3 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-177 Graph: path P4 via bipartition: edges [0, 2] {0–1, 2–3}; weight 10; perfect")
    func ma177() throws {
        // V [0, 1, 2, 3]; E [0-1:5, 1-2:1, 2-3:5]; minimumWeightFullMatching(bipartition: bipartition()!, weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0, 2] as [Int])
        let weights: [Int?] = [5, 1, 5]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(bipartition: bipartition, weight: { weightOf($0) }))
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 10)
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
        #expect(matching.edges.count == 2, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 2 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-178 Graph: C6 weights by position: edges [0, 2, 4] {0–1, 2–3, 4–5}; weight 9; perfect")
    func ma178() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0-1:1, 1-2:2, 2-3:3, 3-4:4, 4-5:5, 5-0:6]; minimumWeightFullMatching(bipartition: bipartition()!, weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0, 2, 4] as [Int])
        let weights: [Int?] = [1, 2, 3, 4, 5, 6]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(bipartition: bipartition, weight: { weightOf($0) }))
        #expect(matching.edges == [0, 2, 4])
        #expect(matching.weight == 9)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4]
        let matchedEdges: [Int?] = [0, 0, 2, 2, 4, 4]
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
        #expect(matching.edges.count == 3, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 3 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-179 lcgbw(5,5,15,1,9): edges [0, 1, 5, 7, 12] {4–8, 0–9, 2–6, 3–7, 1–5}; weight 22; perfect")
    func ma179() throws {
        // lcgbw(5,5,15,1,9); minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(4, 8), (0, 9), (0, 7), (1, 8), (2, 5), (2, 6), (4, 7), (3, 7), (3, 5), (3, 6), (0, 5), (4, 6), (1, 5), (0, 8), (2, 9)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4] as [Int], right: [5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 15)
        #expect(Array(graph.left) == [0, 1, 2, 3, 4] as [Int])
        let weights: [Int?] = [4, 9, 4, 8, 6, 1, 4, 2, 9, 8, 7, 8, 6, 7, 1]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [0, 1, 5, 7, 12])
        #expect(matching.weight == 22)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [9, 5, 6, 7, 8, 1, 2, 3, 4, 0]
        let mateIndices: [Int?] = [9, 5, 6, 7, 8, 1, 2, 3, 4, 0]
        let matchedEdges: [Int?] = [1, 12, 5, 7, 0, 12, 5, 7, 0, 1]
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
        #expect(matching.edges.count == 5, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 5 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-180 lcgbw(4,7,20,2,20): edges [2, 3, 13, 16] {0–7, 2–10, 3–4, 1–9}; weight 16")
    func ma180() throws {
        // lcgbw(4,7,20,2,20); minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(0, 5), (0, 6), (0, 7), (2, 10), (2, 4), (2, 5), (1, 10), (2, 6), (2, 7), (2, 9), (1, 7), (0, 10), (0, 8), (3, 4), (0, 9), (3, 9), (1, 9), (1, 5), (1, 6), (1, 8)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3] as [Int], right: [4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 20)
        #expect(Array(graph.left) == [0, 1, 2, 3] as [Int])
        let weights: [Int?] = [17, 20, 6, 3, 17, 14, 20, 8, 14, 10, 17, 4, 17, 3, 7, 11, 4, 5, 15, 19]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        let matching = try #require(graph.minimumWeightFullMatching(weight: { weightOf($0) }))
        #expect(matching.edges == [2, 3, 13, 16])
        #expect(matching.weight == 16)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
        let mates: [Int?] = [7, 9, 10, 4, 3, nil, nil, 0, nil, 1, 2]
        let mateIndices: [Int?] = [7, 9, 10, 4, 3, nil, nil, 0, nil, 1, 2]
        let matchedEdges: [Int?] = [2, 16, 3, 13, 13, nil, nil, 2, nil, 16, 3]
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
        #expect(matching.edges.count == 4, "full: covers the smaller side")
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var best: (size: Int, weight: Int)?
        func extend(_ k: Int, _ size: Int, _ total: Int) {
            guard k < positions.count else {
                if size == 4 && (best == nil || total < best!.weight) { best = (size, total) }
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
        #expect(matching.weight == optimum.weight, "least weight, by brute force: \(optimum.weight)")
    }

    @Test("MA-181 lcgbw(6,6,12,9,4) sparse, maybe infeasible: nil (no full matching)")
    func ma181() throws {
        // lcgbw(6,6,12,9,4); minimumWeightFullMatching(weight:)
        let pairs: [(Int, Int)] = [(5, 9), (2, 7), (3, 7), (5, 6), (5, 10), (5, 11), (2, 6), (0, 7), (5, 8), (3, 8), (2, 10), (0, 6)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5] as [Int], right: [6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 12)
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5] as [Int])
        let weights: [Int?] = [1, 4, 4, 3, 3, 3, 4, 4, 2, 2, 2, 3]
        func weightOf(_ e: Int) -> Int { weights[e]! }
        #expect(graph.minimumWeightFullMatching(weight: { weightOf($0) }) == nil)
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<Int>()
        var largest = 0
        func extend(_ k: Int, _ size: Int) {
            guard k < positions.count else {
                largest = max(largest, size)
                return
            }
            extend(k + 1, size)
            let edge = graph.edges[positions[k]]
            if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {
                used.insert(edge.u)
                used.insert(edge.v)
                extend(k + 1, size + 1)
                used.remove(edge.u)
                used.remove(edge.v)
            }
        }
        extend(0, 0)
        #expect(largest < 6, "no matching covers the smaller side, by brute force")
    }
}
