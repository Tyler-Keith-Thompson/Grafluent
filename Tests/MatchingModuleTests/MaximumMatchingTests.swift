// `maximumMatching()`, Edmonds' blossom algorithm (catalog §Edmonds: MA-002, MA-004, …, MA-014,
// MA-079 – MA-114): the exact edges api.md's procedure gives (roots in vertex order, breadth-first,
// rows in `incidentEdges` order), every vertex's mate, validity and maximality checked here, and the
// size against brute force over every matching (against NetworkX's size for MA-106 and MA-107).
// MA-108 – MA-113 need blossom contraction. Graphs are `UndirectedAdjacencyList` built by inserting
// the row's vertices, then its edges in order, so rows are in position order; `multigraph` rows are
// `ReferencePseudograph`, whose rows are in position order too (a self-loop twice, parallel edges
// kept); `L …; R …` rows are `BipartiteGraph(left:right:edges:)`. Generated from cases.md by
// swiftgen.py, which re-evaluates each row with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("maximumMatching(): Edmonds' blossom algorithm")
struct MaximumMatchingTests {
    @Test("MA-002 empty graph: edges [] {}; perfect")
    func ma002() {
        // V []; E []; maximumMatching()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-004 one vertex: edges [] {}")
    func ma004() {
        // V [0]; E []; maximumMatching()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-006 one self-loop: edges [] {}")
    func ma006() {
        // V [0]; E [0-0]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-008 one edge: edges [0] {0–1}; perfect")
    func ma008() {
        // V [0, 1]; E [0-1]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-010 parallel pair: edges [0] {0–1}; perfect")
    func ma010() {
        // multigraph V [0, 1]; E [0-1, 1-0]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-012 loops at both ends of an edge: edges [1] {0–1}; perfect")
    func ma012() {
        // V [0, 1]; E [0-0, 0-1, 1-1]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-014 two isolated vertices: edges [] {}")
    func ma014() {
        // V [0, 1]; E []; maximumMatching()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-079 triangle: edges [0] {0–1}")
    func ma079() {
        // K(3); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-080 C5: edges [0, 2] {0–1, 2–3}")
    func ma080() {
        // C(5); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, nil]
        let mateIndices: [Int?] = [1, 0, 3, 2, nil]
        let matchedEdges: [Int?] = [0, 0, 2, 2, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-081 C7: edges [0, 2, 4] {0–1, 2–3, 4–5}")
    func ma081() {
        // C(7); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 2, 4])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4, nil]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4, nil]
        let matchedEdges: [Int?] = [0, 0, 2, 2, 4, 4, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-082 K4: edges [0, 5] {0–1, 2–3}; perfect")
    func ma082() {
        // K(4); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 5])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, 3, 2]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [0, 0, 5, 5]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-083 K5: edges [0, 7] {0–1, 2–3}")
    func ma083() {
        // K(5); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-084 K6: edges [0, 9, 14] {0–1, 2–3, 4–5}; perfect")
    func ma084() {
        // K(6); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 9, 14])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4]
        let matchedEdges: [Int?] = [0, 0, 9, 9, 14, 14]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-085 P5: edges [0, 2] {0–1, 2–3}")
    func ma085() {
        // P(5); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, nil]
        let mateIndices: [Int?] = [1, 0, 3, 2, nil]
        let matchedEdges: [Int?] = [0, 0, 2, 2, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-086 star S5: edges [0] {0–1}")
    func ma086() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 0-2, 0-3, 0-4, 0-5]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [1, 0, nil, nil, nil, nil]
        let mateIndices: [Int?] = [1, 0, nil, nil, nil, nil]
        let matchedEdges: [Int?] = [0, 0, nil, nil, nil, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-087 Petersen: edges [0, 5, 9, 10, 12] {0–1, 2–3, 4–9, 5–7, 6–8}; perfect")
    func ma087() {
        // nx(petersen); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 5, 9, 10, 12])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 9, 7, 8, 5, 6, 4]
        let mateIndices: [Int?] = [1, 0, 3, 2, 9, 7, 8, 5, 6, 4]
        let matchedEdges: [Int?] = [0, 0, 5, 5, 9, 10, 12, 10, 12, 9]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-088 triangle with a pendant: augmenting path through a blossom: edges [0, 3] {0–1, 2–3}; perfect")
    func ma088() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0, 2-3]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 3])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, 3, 2]
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-089 blossom then stem: 0 free root, path enters C5 at its base: edges [0, 2, 4] {0–1, 2–3, 4–5}")
    func ma089() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 1-2, 2-3, 3-4, 4-5, 5-1, 4-6]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1), (4, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 2, 4])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4, nil]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4, nil]
        let matchedEdges: [Int?] = [0, 0, 2, 2, 4, 4, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-090 flower: C5 with stem and an exit at the far side: edges [1, 4, 6, 7] {0–1, 3–4, 2–7, 5–6}; perfect")
    func ma090() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [6-0, 0-1, 1-2, 2-3, 3-4, 4-0, 2-7, 5-6]; maximumMatching()
        let pairs: [(Int, Int)] = [(6, 0), (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 7), (5, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [1, 4, 6, 7])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let mates: [Int?] = [1, 0, 7, 4, 3, 6, 5, 2]
        let mateIndices: [Int?] = [1, 0, 7, 4, 3, 6, 5, 2]
        let matchedEdges: [Int?] = [1, 1, 6, 4, 4, 7, 7, 6]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-091 nested blossoms (triangle inside C5): edges [0, 3, 5, 8] {0–1, 2–3, 4–5, 6–7}")
    func ma091() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-5, 5-0, 5-6, 6-7, 7-8, 4-8]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 0), (5, 6), (6, 7), (7, 8), (4, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 11)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 3, 5, 8])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6, nil]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6, nil]
        let matchedEdges: [Int?] = [0, 0, 3, 3, 5, 5, 8, 8, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-092 two triangles joined by an edge: edges [0, 4, 6] {0–1, 4–5, 2–3}; perfect")
    func ma092() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3, 2-3]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 4, 6])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4]
        let matchedEdges: [Int?] = [0, 0, 6, 6, 4, 4]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-093 barbell K4–K4: edges [0, 5, 6, 11] {0–1, 2–3, 4–5, 6–7}; perfect")
    func ma093() {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 0-2, 0-3, 1-2, 1-3, 2-3, 4-5, 4-6, 4-7, 5-6, 5-7, 6-7, 3-4]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 13)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 5, 6, 11])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6]
        let matchedEdges: [Int?] = [0, 0, 5, 5, 6, 6, 11, 11]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-094 odd wheel W5: edges [0, 6, 8] {0–1, 2–3, 4–5}; perfect")
    func ma094() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 0-2, 0-3, 0-4, 0-5, 1-2, 2-3, 3-4, 4-5, 5-1]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 6, 8])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4]
        let matchedEdges: [Int?] = [0, 0, 6, 6, 8, 8]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-095 vertex order matters: P3 numbered from the middle: edges [0] {0–1}")
    func ma095() {
        // V [1, 0, 2]; E [0-1, 1-2]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [1, 0, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 2)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [1, 0, 2] as [Int])
        let mates: [Int?] = [0, 1, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-096 multigraph: triangle with a doubled edge: edges [0] {0–1}")
    func ma096() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2, 2-0]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-097 loops everywhere on a P4: edges [1, 4] {0–1, 2–3}; perfect")
    func ma097() {
        // V [0, 1, 2, 3]; E [0-0, 0-1, 1-1, 1-2, 2-3, 3-3]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 3), (3, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [1, 4])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, 3, 2]
        let mateIndices: [Int?] = [1, 0, 3, 2]
        let matchedEdges: [Int?] = [1, 1, 4, 4]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-098 grid 3×3 (odd: one vertex free): edges [0, 4, 5, 10] {0–1, 2–5, 3–4, 6–7}")
    func ma098() {
        // grid(3,3); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let matching = graph.maximumMatching()
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-099 grid 4×4: edges [0, 4, 7, 11, 14, 18, 21, 23] {0–1, 2–3, 4–5, 6–7, 8–9, 10–11, 12–13, 14–15}; perfect")
    func ma099() {
        // grid(4,4); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 4, 7, 11, 14, 18, 21, 23])
        #expect(matching.weight == 8)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14]
        let matchedEdges: [Int?] = [0, 0, 4, 4, 7, 7, 11, 11, 14, 14, 18, 18, 21, 21, 23, 23]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-100 bipartite input K3,3: edges [0, 4, 8] {0–3, 1–4, 2–5}; perfect")
    func ma100() throws {
        // Kb(3,3); maximumMatching()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 9)
        let matching = graph.maximumMatching()
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
        // Maximal, checked here: every edge other than a self-loop has a matched end.
        for edge in graph.edges where edge.u != edge.v {
            #expect(covered.contains(edge.u) || covered.contains(edge.v), "\(edge) could be added")
        }
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-101 Tutte's example: no perfect matching (K1,3 of triangles): edges [0, 4, 6, 9] {0–1, 2–3, 4–5, 7–8}")
    func ma101() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; E [0-1, 0-4, 0-7, 1-2, 2-3, 3-1, 4-5, 5-6, 6-4, 7-8, 8-9, 9-7]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 7), (1, 2), (2, 3), (3, 1), (4, 5), (5, 6), (6, 4), (7, 8), (8, 9), (9, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 4, 6, 9])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4, nil, 8, 7, nil]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4, nil, 8, 7, nil]
        let matchedEdges: [Int?] = [0, 0, 4, 4, 6, 6, nil, 9, 9, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-102 lcg(10,15,1): edges [4, 5, 7, 11, 14] {9–6, 3–2, 0–5, 7–8, 1–4}; perfect")
    func ma102() {
        // lcg(10,15,1); maximumMatching()
        let pairs: [(Int, Int)] = [(4, 3), (6, 0), (4, 5), (0, 2), (9, 6), (3, 2), (4, 2), (0, 5), (2, 5), (9, 8), (1, 8), (7, 8), (8, 5), (6, 8), (1, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [4, 5, 7, 11, 14])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [5, 4, 3, 2, 1, 0, 9, 8, 7, 6]
        let mateIndices: [Int?] = [5, 4, 3, 2, 1, 0, 9, 8, 7, 6]
        let matchedEdges: [Int?] = [7, 14, 5, 5, 14, 7, 4, 11, 11, 4]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-103 lcg(12,18,7): edges [2, 3, 7, 10, 12, 14] {1–11, 4–0, 9–3, 10–6, 8–5, 2–7}; perfect")
    func ma103() {
        // lcg(12,18,7); maximumMatching()
        let pairs: [(Int, Int)] = [(2, 11), (9, 5), (1, 11), (4, 0), (7, 10), (7, 3), (9, 10), (9, 3), (0, 11), (4, 1), (10, 6), (5, 0), (8, 5), (9, 4), (2, 7), (5, 11), (9, 7), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 18)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [2, 3, 7, 10, 12, 14])
        #expect(matching.weight == 6)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let mates: [Int?] = [4, 11, 7, 9, 0, 8, 10, 2, 5, 3, 6, 1]
        let mateIndices: [Int?] = [4, 11, 7, 9, 0, 8, 10, 2, 5, 3, 6, 1]
        let matchedEdges: [Int?] = [3, 2, 14, 7, 3, 12, 10, 14, 12, 7, 10, 2]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-104 lcg(14,21,3): edges [1, 2, 3, 4, 17, 18] {13–2, 8–3, 1–11, 5–0, 4–9, 10–7}")
    func ma104() {
        // lcg(14,21,3); maximumMatching()
        let pairs: [(Int, Int)] = [(3, 13), (13, 2), (8, 3), (1, 11), (5, 0), (12, 3), (8, 11), (13, 1), (11, 4), (1, 4), (9, 7), (9, 5), (11, 2), (9, 0), (3, 9), (5, 8), (7, 11), (4, 9), (10, 7), (5, 2), (5, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 21)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [1, 2, 3, 4, 17, 18])
        #expect(matching.weight == 6)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let mates: [Int?] = [5, 11, 13, 8, 9, 0, nil, 10, 3, 4, 7, 1, nil, 2]
        let mateIndices: [Int?] = [5, 11, 13, 8, 9, 0, nil, 10, 3, 4, 7, 1, nil, 2]
        let matchedEdges: [Int?] = [4, 3, 1, 2, 17, 4, nil, 18, 2, 17, 18, 3, nil, 1]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-105 lcg(15,30,9): edges [1, 4, 8, 19, 20, 27, 29] {2–5, 9–1, 14–0, 7–3, 6–12, 11–8, 4–13}")
    func ma105() {
        // lcg(15,30,9); maximumMatching()
        let pairs: [(Int, Int)] = [(8, 6), (2, 5), (10, 2), (8, 7), (9, 1), (9, 7), (8, 4), (14, 8), (14, 0), (4, 9), (10, 12), (2, 8), (7, 2), (8, 3), (14, 9), (14, 4), (3, 12), (9, 12), (0, 7), (7, 3), (6, 12), (3, 4), (1, 6), (13, 1), (2, 12), (9, 6), (13, 9), (11, 8), (0, 8), (4, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [1, 4, 8, 19, 20, 27, 29])
        #expect(matching.weight == 7)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14] as [Int])
        let mates: [Int?] = [14, 9, 5, 7, 13, 2, 12, 3, 11, 1, nil, 8, 6, 4, 0]
        let mateIndices: [Int?] = [14, 9, 5, 7, 13, 2, 12, 3, 11, 1, nil, 8, 6, 4, 0]
        let matchedEdges: [Int?] = [8, 4, 1, 19, 29, 1, 20, 19, 27, 4, nil, 27, 20, 29, 8]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-106 lcg(40,80,4) (size against NetworkX only)")
    func ma106() {
        // lcg(40,80,4); maximumMatching()
        let pairs: [(Int, Int)] = [(26, 12), (14, 11), (25, 27), (1, 13), (34, 16), (15, 34), (6, 24), (11, 7), (4, 17), (8, 18), (18, 15), (10, 18), (37, 16), (6, 13), (27, 0), (19, 8), (9, 0), (30, 15), (33, 2), (8, 34), (5, 21), (20, 39), (26, 3), (8, 6), (7, 19), (36, 31), (4, 26), (3, 2), (37, 1), (12, 13), (39, 21), (33, 4), (11, 13), (37, 13), (6, 9), (4, 15), (8, 16), (23, 22), (16, 30), (4, 9), (26, 32), (29, 19), (10, 28), (22, 4), (29, 4), (12, 16), (12, 15), (17, 19), (25, 12), (35, 5), (26, 1), (37, 2), (36, 8), (15, 11), (38, 32), (39, 24), (15, 5), (1, 24), (27, 15), (33, 1), (19, 18), (39, 5), (17, 2), (16, 22), (35, 7), (32, 20), (3, 28), (31, 21), (38, 20), (8, 9), (35, 1), (20, 3), (16, 3), (16, 32), (5, 3), (33, 36), (29, 11), (25, 22), (8, 4), (29, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 80)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [1, 2, 5, 6, 8, 9, 16, 18, 20, 21, 22, 25, 28, 29, 37, 38, 41, 42, 54, 64])
        #expect(matching.weight == 20)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int])
        let mates: [Int?] = [9, 37, 33, 26, 17, 21, 24, 35, 18, 0, 28, 14, 13, 12, 11, 34, 30, 4, 8, 29, 39, 5, 23, 22, 6, 27, 3, 25, 10, 19, 16, 36, 38, 2, 15, 7, 31, 1, 32, 20]
        let mateIndices: [Int?] = [9, 37, 33, 26, 17, 21, 24, 35, 18, 0, 28, 14, 13, 12, 11, 34, 30, 4, 8, 29, 39, 5, 23, 22, 6, 27, 3, 25, 10, 19, 16, 36, 38, 2, 15, 7, 31, 1, 32, 20]
        let matchedEdges: [Int?] = [16, 28, 18, 22, 8, 20, 6, 64, 9, 16, 42, 1, 29, 29, 1, 5, 38, 8, 9, 41, 21, 20, 37, 37, 6, 2, 22, 2, 42, 41, 38, 25, 54, 18, 5, 64, 25, 28, 54, 21]
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
        #expect(graph.isMatching(matching.edges))
        #expect(matching.edges.count == 20, "NetworkX max_weight_matching(maxcardinality=True) has 20 edges")
    }

    @Test("MA-107 lcg(60,90,8) (size against NetworkX only)")
    func ma107() {
        // lcg(60,90,8); maximumMatching()
        let pairs: [(Int, Int)] = [(4, 12), (32, 7), (14, 23), (10, 11), (55, 53), (15, 55), (2, 55), (31, 32), (30, 5), (18, 12), (41, 21), (52, 10), (9, 22), (4, 7), (35, 39), (22, 39), (36, 28), (18, 6), (21, 13), (12, 27), (5, 48), (32, 53), (31, 5), (33, 58), (5, 6), (57, 15), (28, 53), (40, 16), (56, 32), (59, 55), (40, 17), (17, 55), (33, 39), (40, 27), (18, 24), (6, 0), (35, 16), (31, 41), (47, 41), (20, 45), (6, 29), (51, 44), (19, 8), (36, 30), (14, 4), (29, 35), (8, 57), (48, 54), (18, 43), (4, 50), (17, 31), (54, 41), (33, 12), (36, 21), (40, 22), (21, 48), (52, 32), (33, 21), (55, 3), (42, 39), (58, 26), (11, 24), (49, 3), (44, 46), (54, 40), (56, 59), (57, 23), (54, 21), (58, 27), (47, 16), (46, 37), (45, 56), (42, 34), (57, 40), (4, 52), (36, 2), (4, 21), (12, 45), (50, 1), (29, 55), (18, 56), (35, 13), (16, 48), (11, 55), (32, 48), (26, 21), (9, 28), (36, 25), (35, 42), (44, 25)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 90)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [2, 6, 8, 11, 12, 13, 18, 19, 25, 26, 27, 28, 32, 35, 38, 39, 41, 42, 45, 47, 48, 50, 60, 61, 62, 70, 72, 78, 87])
        #expect(matching.weight == 29)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59] as [Int])
        let mates: [Int?] = [6, 50, 55, 49, 7, 30, 0, 4, 19, 22, 52, 24, 27, 21, 23, 57, 40, 31, 43, 8, 45, 13, 9, 14, 11, 36, 58, 12, 53, 35, 5, 17, 56, 39, 42, 29, 25, 46, nil, 33, 16, 47, 34, 18, 51, 20, 37, 41, 54, 3, 1, 44, 10, 28, 48, 2, 32, 15, 26, nil]
        let mateIndices: [Int?] = [6, 50, 55, 49, 7, 30, 0, 4, 19, 22, 52, 24, 27, 21, 23, 57, 40, 31, 43, 8, 45, 13, 9, 14, 11, 36, 58, 12, 53, 35, 5, 17, 56, 39, 42, 29, 25, 46, nil, 33, 16, 47, 34, 18, 51, 20, 37, 41, 54, 3, 1, 44, 10, 28, 48, 2, 32, 15, 26, nil]
        let matchedEdges: [Int?] = [35, 78, 6, 62, 13, 8, 35, 13, 42, 12, 11, 61, 19, 18, 2, 25, 27, 50, 48, 42, 39, 18, 12, 2, 61, 87, 60, 19, 26, 45, 8, 50, 28, 32, 72, 45, 87, 70, nil, 32, 27, 38, 72, 48, 41, 39, 70, 38, 47, 62, 78, 41, 11, 26, 47, 6, 28, 25, 60, nil]
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
        #expect(graph.isMatching(matching.edges))
        #expect(matching.edges.count == 29, "NetworkX max_weight_matching(maxcardinality=True) has 29 edges")
    }

    @Test("MA-108 stem into a blossom: the first free root augments only through the blossom (without contraction the search from r fails and f's search finds the other path: different edges, same size)")
    func ma108() {
        // V [s, t, a, b, c, d, r, f]; E [s-t, a-b, c-d, t-a, b-c, d-t, r-s, a-f]; maximumMatching()
        let pairs: [(String, String)] = [("s", "t"), ("a", "b"), ("c", "d"), ("t", "a"), ("b", "c"), ("d", "t"), ("r", "s"), ("a", "f")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["s", "t", "a", "b", "c", "d", "r", "f"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [4, 5, 6, 7])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "t", "a", "b", "c", "d", "r", "f"] as [String])
        let mates: [String?] = ["r", "d", "f", "c", "b", "t", "s", "a"]
        let mateIndices: [Int?] = [6, 5, 7, 4, 3, 1, 0, 2]
        let matchedEdges: [Int?] = [6, 5, 7, 4, 4, 5, 6, 7]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-109 lcg(10,13,6): needs a blossom (a search without blossom contraction returns a smaller matching)")
    func ma109() {
        // lcg(10,13,6); maximumMatching()
        let pairs: [(Int, Int)] = [(1, 2), (3, 9), (4, 5), (4, 9), (0, 6), (5, 0), (3, 1), (3, 4), (7, 9), (5, 6), (1, 6), (2, 4), (8, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 13)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 7, 8, 9, 12])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [8, 2, 1, 4, 3, 6, 5, 9, 0, 7]
        let mateIndices: [Int?] = [8, 2, 1, 4, 3, 6, 5, 9, 0, 7]
        let matchedEdges: [Int?] = [12, 0, 0, 7, 7, 9, 9, 8, 12, 8]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-110 lcg(10,14,0): needs a blossom (a search without blossom contraction returns a smaller matching)")
    func ma110() {
        // lcg(10,14,0); maximumMatching()
        let pairs: [(Int, Int)] = [(7, 4), (7, 6), (5, 1), (4, 5), (4, 9), (3, 2), (2, 5), (0, 2), (5, 8), (1, 3), (7, 8), (1, 2), (0, 4), (9, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 14)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [1, 4, 7, 8, 9])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [2, 3, 0, 1, 9, 8, 7, 6, 5, 4]
        let mateIndices: [Int?] = [2, 3, 0, 1, 9, 8, 7, 6, 5, 4]
        let matchedEdges: [Int?] = [7, 9, 7, 9, 4, 8, 1, 1, 8, 4]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-111 lcg(13,20,1): needs a blossom (a search without blossom contraction returns a smaller matching)")
    func ma111() {
        // lcg(13,20,1); maximumMatching()
        let pairs: [(Int, Int)] = [(12, 5), (10, 3), (11, 10), (8, 12), (8, 5), (4, 1), (12, 0), (3, 8), (4, 10), (1, 6), (4, 11), (2, 6), (1, 2), (8, 11), (3, 5), (5, 4), (6, 12), (10, 5), (10, 1), (10, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [5, 6, 11, 13, 14, 19])
        #expect(matching.weight == 6)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int])
        let mates: [Int?] = [12, 4, 6, 5, 1, 3, 2, nil, 11, 10, 9, 8, 0]
        let mateIndices: [Int?] = [12, 4, 6, 5, 1, 3, 2, nil, 11, 10, 9, 8, 0]
        let matchedEdges: [Int?] = [6, 5, 11, 14, 5, 14, 11, nil, 13, 19, 19, 13, 6]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-112 lcg(14,18,6): needs a blossom (a search without blossom contraction returns a smaller matching)")
    func ma112() {
        // lcg(14,18,6); maximumMatching()
        let pairs: [(Int, Int)] = [(11, 4), (13, 1), (4, 13), (10, 2), (7, 0), (12, 10), (5, 6), (1, 11), (3, 5), (11, 0), (1, 12), (7, 9), (3, 0), (3, 10), (11, 7), (8, 4), (4, 2), (3, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 18)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [1, 5, 6, 9, 11, 15, 17])
        #expect(matching.weight == 7)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let mates: [Int?] = [11, 13, 3, 2, 8, 6, 5, 9, 4, 7, 12, 0, 10, 1]
        let mateIndices: [Int?] = [11, 13, 3, 2, 8, 6, 5, 9, 4, 7, 12, 0, 10, 1]
        let matchedEdges: [Int?] = [9, 1, 17, 17, 15, 6, 6, 11, 15, 11, 5, 9, 5, 1]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-113 lcg(14,23,2): needs a blossom (a search without blossom contraction returns a smaller matching)")
    func ma113() {
        // lcg(14,23,2); maximumMatching()
        let pairs: [(Int, Int)] = [(6, 8), (4, 2), (0, 10), (9, 2), (13, 4), (8, 0), (8, 1), (12, 1), (6, 10), (4, 10), (1, 6), (5, 8), (9, 3), (8, 10), (11, 12), (5, 11), (1, 10), (0, 12), (3, 12), (13, 3), (12, 4), (0, 4), (1, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 23)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [0, 2, 3, 15, 19, 20, 22])
        #expect(matching.weight == 7)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let mates: [Int?] = [10, 7, 9, 13, 12, 11, 8, 1, 6, 2, 0, 5, 4, 3]
        let mateIndices: [Int?] = [10, 7, 9, 13, 12, 11, 8, 1, 6, 2, 0, 5, 4, 3]
        let matchedEdges: [Int?] = [2, 22, 3, 19, 20, 15, 0, 22, 0, 3, 2, 15, 20, 19]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }

    @Test("MA-114 blossom expansion on augmentation (C5 + two pendants): edges [2, 4, 5] {2–3, 4–0, 1–5}")
    func ma114() {
        // V [0, 1, 2, 3, 4, 5, 6]; E [0-1, 1-2, 2-3, 3-4, 4-0, 1-5, 3-6]; maximumMatching()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 5), (3, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 7)
        let matching = graph.maximumMatching()
        #expect(matching.edges == [2, 4, 5])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let mates: [Int?] = [4, 5, 3, 2, 0, 1, nil]
        let mateIndices: [Int?] = [4, 5, 3, 2, 0, 1, nil]
        let matchedEdges: [Int?] = [4, 5, 2, 2, 4, 5, nil]
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
        #expect(graph.isMatching(matching.edges))
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
        #expect(matching.edges.count == largest, "maximum, by brute force")
    }
}
