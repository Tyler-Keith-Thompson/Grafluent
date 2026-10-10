// `maximalMatching()` (catalog §Maximal: MA-001, MA-003, …, MA-013, MA-024 – MA-034): the greedy
// matching in position order, exact edges, every vertex's mate, `weight == edges.count`,
// `isPerfect`; validity and maximality checked here, and at least half a maximum matching found by
// brute force. Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its
// edges in order, so rows are in position order; `multigraph` rows are `ReferencePseudograph`, whose
// rows are in position order too (a self-loop twice, parallel edges kept); `L …; R …` rows are
// `BipartiteGraph(left:right:edges:)`. Generated from cases.md by swiftgen.py, which re-evaluates
// each row with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("maximalMatching(): greedy in position order")
struct MaximalMatchingTests {
    @Test("MA-001 empty graph: edges [] {}; perfect")
    func ma001() {
        // V []; E []; maximalMatching()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let matching = graph.maximalMatching()
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 0)
    }

    @Test("MA-003 one vertex: edges [] {}")
    func ma003() {
        // V [0]; E []; maximalMatching()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let matching = graph.maximalMatching()
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 0)
    }

    @Test("MA-005 one self-loop: edges [] {}")
    func ma005() {
        // V [0]; E [0-0]; maximalMatching()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let matching = graph.maximalMatching()
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 0)
    }

    @Test("MA-007 one edge: edges [0] {0–1}; perfect")
    func ma007() {
        // V [0, 1]; E [0-1]; maximalMatching()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 1)
    }

    @Test("MA-009 parallel pair: edges [0] {0–1}; perfect")
    func ma009() {
        // multigraph V [0, 1]; E [0-1, 1-0]; maximalMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 1)
    }

    @Test("MA-011 loops at both ends of an edge: edges [1] {0–1}; perfect")
    func ma011() {
        // V [0, 1]; E [0-0, 0-1, 1-1]; maximalMatching()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [1])
        #expect(matching.weight == 1)
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 1)
    }

    @Test("MA-013 two isolated vertices: edges [] {}")
    func ma013() {
        // V [0, 1]; E []; maximalMatching()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let matching = graph.maximalMatching()
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 0)
    }

    @Test("MA-024 NetworkX docstring graph: edges [0, 4] {1–2, 3–5}")
    func ma024() {
        // V [1, 2, 3, 4, 5]; E [1-2, 1-3, 2-3, 2-4, 3-5, 4-5]; maximalMatching()
        let pairs: [(Int, Int)] = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0, 4])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [2, 1, 5, nil, 3]
        let mateIndices: [Int?] = [1, 0, 4, nil, 2]
        let matchedEdges: [Int?] = [0, 0, 4, nil, 4]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 2)
    }

    @Test("MA-025 path P4: greedy takes the middle edge first (maximal, not maximum: size 1 where 2 exists)")
    func ma025() {
        // V [0, 1, 2, 3]; E [1-2, 0-1, 2-3]; maximalMatching()
        let pairs: [(Int, Int)] = [(1, 2), (0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [nil, 2, 1, nil]
        let mateIndices: [Int?] = [nil, 2, 1, nil]
        let matchedEdges: [Int?] = [nil, 0, 0, nil]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 2)
    }

    @Test("MA-026 path P4 in path order: edges [0, 2] {0–1, 2–3}; perfect")
    func ma026() {
        // P(4); maximalMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let matching = graph.maximalMatching()
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 2)
    }

    @Test("MA-027 star S4: edges [0] {0–1}")
    func ma027() {
        // V [0, 1, 2, 3, 4]; E [0-1, 0-2, 0-3, 0-4]; maximalMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let mates: [Int?] = [1, 0, nil, nil, nil]
        let mateIndices: [Int?] = [1, 0, nil, nil, nil]
        let matchedEdges: [Int?] = [0, 0, nil, nil, nil]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 1)
    }

    @Test("MA-028 triangle: edges [0] {0–1}")
    func ma028() {
        // K(3); maximalMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let mates: [Int?] = [1, 0, nil]
        let mateIndices: [Int?] = [1, 0, nil]
        let matchedEdges: [Int?] = [0, 0, nil]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 1)
    }

    @Test("MA-029 K5: edges [0, 7] {0–1, 2–3}")
    func ma029() {
        // K(5); maximalMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0, 7])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, nil]
        let mateIndices: [Int?] = [1, 0, 3, 2, nil]
        let matchedEdges: [Int?] = [0, 0, 7, 7, nil]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 2)
    }

    @Test("MA-030 loop first, then edges: edges [1] {0–1}")
    func ma030() {
        // V [0, 1, 2]; E [0-0, 0-1, 1-2]; maximalMatching()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [1])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let mates: [Int?] = [1, 0, nil]
        let mateIndices: [Int?] = [1, 0, nil]
        let matchedEdges: [Int?] = [1, 1, nil]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 1)
    }

    @Test("MA-031 multigraph: parallel copies after a taken edge skipped: edges [0] {0–1}")
    func ma031() {
        // multigraph V [0, 1, 2]; E [0-1, 0-1, 1-2, 2-0]; maximalMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let mates: [Int?] = [1, 0, nil]
        let mateIndices: [Int?] = [1, 0, nil]
        let matchedEdges: [Int?] = [0, 0, nil]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 1)
    }

    @Test("MA-032 string vertices, edge stored v–u: edges [0] {a–b}")
    func ma032() {
        // V [b, a, c]; E [a-b, c-b]; maximalMatching()
        let pairs: [(String, String)] = [("a", "b"), ("c", "b")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["b", "a", "c"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["b", "a", "c"] as [String])
        let mates: [String?] = ["a", "b", nil]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
        // Brute force over every matching (each edge in or out, in position order).
        let positions = Array(graph.edges.indices)
        var used = Set<String>()
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 1)
    }

    @Test("MA-033 grid 3×3: edges [0, 4, 5, 10] {0–1, 2–5, 3–4, 6–7}")
    func ma033() {
        // grid(3,3); maximalMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0, 4, 5, 10])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let mates: [Int?] = [1, 0, 5, 4, 3, 2, 7, 6, nil]
        let mateIndices: [Int?] = [1, 0, 5, 4, 3, 2, 7, 6, nil]
        let matchedEdges: [Int?] = [0, 0, 4, 5, 5, 4, 10, 10, nil]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 4)
    }

    @Test("MA-034 random lcg(12,20,1): edges [0, 1, 5, 9, 16] {2–9, 0–6, 3–10, 7–1, 11–4}")
    func ma034() {
        // lcg(12,20,1); maximalMatching()
        let pairs: [(Int, Int)] = [(2, 9), (0, 6), (6, 11), (2, 10), (9, 10), (3, 10), (2, 4), (10, 11), (4, 9), (7, 1), (2, 6), (9, 8), (0, 8), (0, 5), (6, 10), (4, 1), (11, 4), (0, 9), (6, 4), (8, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let matching = graph.maximalMatching()
        #expect(matching.edges == [0, 1, 5, 9, 16])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let mates: [Int?] = [6, 7, 9, 10, 11, nil, 0, 1, nil, 2, 3, 4]
        let mateIndices: [Int?] = [6, 7, 9, 10, 11, nil, 0, 1, nil, 2, 3, 4]
        let matchedEdges: [Int?] = [1, 9, 0, 5, 16, nil, 1, 9, nil, 0, 5, 16]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMaximalMatching(matching.edges))
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
        #expect(2 * matching.edges.count >= largest, "a maximal matching is at least half a maximum one")
        #expect(largest == 6)
    }
}
