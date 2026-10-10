// `maximumBipartiteMatching()` on `BipartiteGraph` and `maximumBipartiteMatching(bipartition:)` on a
// `Graph` (catalog §Hopcroft–Karp, MA-052 – MA-078): NetworkX's Hopcroft–Karp output with left
// vertices in `left` order, exact edges and mates, validity, the König cover built here from
// `mate(of:)` (equal to the catalog's, as large as the matching, covering every edge: the
// certificate of maximality), and the size against brute force on small rows. Graphs are
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

@Suite("Hopcroft–Karp: maximumBipartiteMatching")
struct HopcroftKarpTests {
    @Test("MA-052 empty bipartite graph: edges [] {}; perfect; König cover []; 0 phases")
    func ma052() throws {
        // L []; R []; E []; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = []
        let graph = try #require(BipartiteGraph<Int>(left: [] as [Int], right: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.left) == [] as [Int])
        let matching = graph.maximumBipartiteMatching()
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-053 left only: edges [] {}; König cover []; 0 phases")
    func ma053() throws {
        // L [0, 1]; R []; E []; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = []
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 0)
        #expect(Array(graph.left) == [0, 1] as [Int])
        let matching = graph.maximumBipartiteMatching()
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-054 one edge: edges [0] {0–1}; perfect; König cover [0]; 1 phase")
    func ma054() throws {
        // L [0]; R [1]; E [0-1]; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = try #require(BipartiteGraph<Int>(left: [0] as [Int], right: [1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.left) == [0] as [Int])
        let matching = graph.maximumBipartiteMatching()
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-055 edge given right endpoint first (stored left first): edges [0] {x–a}; perfect; König cover [a]; 1 phase")
    func ma055() throws {
        // L [a]; R [x]; E [x-a]; maximumBipartiteMatching()
        let pairs: [(String, String)] = [("x", "a")]
        let graph = try #require(BipartiteGraph<String>(left: ["a"] as [String], right: ["x"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.left) == ["a"] as [String])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["a", "x"] as [String])
        let mates: [String?] = ["x", "a"]
        let mateIndices: [Int?] = [1, 0]
        let matchedEdges: [Int?] = [0, 0]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == ["a"] as [String])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-056 K2,2: edges [0, 3] {0–2, 1–3}; perfect; König cover [0, 1]; 1 phase")
    func ma056() throws {
        // Kb(2,2); maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 2), (1, 3)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 4)
        #expect(Array(graph.left) == [0, 1] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0, 3])
        #expect(matching.weight == 2)
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 1] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-057 K3,3: edges [0, 4, 8] {0–3, 1–4, 2–5}; perfect; König cover [0, 1, 2]; 1 phase")
    func ma057() throws {
        // Kb(3,3); maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 9)
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        let matching = graph.maximumBipartiteMatching()
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 1, 2] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-058 K2,4 (left smaller): edges [0, 5] {0–2, 1–3}; König cover [0, 1]; 1 phase")
    func ma058() throws {
        // Kb(2,4); maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1] as [Int], right: [2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 8)
        #expect(Array(graph.left) == [0, 1] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0, 5])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [2, 3, 0, 1, nil, nil]
        let mateIndices: [Int?] = [2, 3, 0, 1, nil, nil]
        let matchedEdges: [Int?] = [0, 5, 0, 5, nil, nil]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 1] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-059 K4,2 (right smaller): edges [0, 3] {0–4, 1–5}; König cover [4, 5]; 1 phase")
    func ma059() throws {
        // Kb(4,2); maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 4), (0, 5), (1, 4), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3] as [Int], right: [4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 8)
        #expect(Array(graph.left) == [0, 1, 2, 3] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0, 3])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [4, 5, nil, nil, 0, 1]
        let mateIndices: [Int?] = [4, 5, nil, nil, 0, 1]
        let matchedEdges: [Int?] = [0, 3, nil, nil, 0, 3]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [4, 5] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-060 star, one left centre: edges [0] {0–1}; König cover [0]; 1 phase")
    func ma060() throws {
        // L [0]; R [1, 2, 3]; E [0-1, 0-2, 0-3]; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = try #require(BipartiteGraph<Int>(left: [0] as [Int], right: [1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.left) == [0] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [1, 0, nil, nil]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-061 star, one right centre: edges [0] {0–3}; König cover [3]; 1 phase")
    func ma061() throws {
        // L [0, 1, 2]; R [3]; E [0-3, 1-3, 2-3]; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 3), (1, 3), (2, 3)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let mates: [Int?] = [3, nil, nil, 0]
        let mateIndices: [Int?] = [3, nil, nil, 0]
        let matchedEdges: [Int?] = [0, nil, nil, 0]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [3] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-062 path a–x–b–y needs an augmenting path (greedy phase 1 takes a–x; phase 2 augments b–x–a–y)")
    func ma062() throws {
        // L [a, b]; R [x, y]; E [a-x, b-x, a-y]; maximumBipartiteMatching()
        let pairs: [(String, String)] = [("a", "x"), ("b", "x"), ("a", "y")]
        let graph = try #require(BipartiteGraph<String>(left: ["a", "b"] as [String], right: ["x", "y"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.left) == ["a", "b"] as [String])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [1, 2])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["a", "b", "x", "y"] as [String])
        let mates: [String?] = ["y", "x", "b", "a"]
        let mateIndices: [Int?] = [3, 2, 1, 0]
        let matchedEdges: [Int?] = [2, 1, 1, 2]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == ["a", "b"] as [String])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-063 ladder listed in reverse: the greedy first phase suffices")
    func ma063() throws {
        // L [0, 1, 2, 3, 4]; R [5, 6, 7, 8, 9]; E [4-5, 3-9, 3-8, 2-8, 2-7, 1-7, 1-6, 0-6, 0-5]; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(4, 5), (3, 9), (3, 8), (2, 8), (2, 7), (1, 7), (1, 6), (0, 6), (0, 5)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4] as [Int], right: [5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 9)
        #expect(Array(graph.left) == [0, 1, 2, 3, 4] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0, 1, 3, 5, 7])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let mates: [Int?] = [6, 7, 8, 9, 5, 4, 0, 1, 2, 3]
        let mateIndices: [Int?] = [6, 7, 8, 9, 5, 4, 0, 1, 2, 3]
        let matchedEdges: [Int?] = [7, 5, 3, 1, 0, 0, 7, 5, 3, 1]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 1, 2, 3, 4] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-064 NetworkX test graph (12 vertices, top 0..5)")
    func ma064() throws {
        // L [0, 1, 2, 3, 4, 5]; R [6, 7, 8, 9, 10, 11]; E [0-7, 0-8, 2-6, 2-9, 3-8, 4-8, 4-9, 5-11]; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 7), (0, 8), (2, 6), (2, 9), (3, 8), (4, 8), (4, 9), (5, 11)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5] as [Int], right: [6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 8)
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0, 2, 4, 6, 7])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let mates: [Int?] = [7, nil, 6, 8, 9, 11, 2, 0, 3, 4, nil, 5]
        let mateIndices: [Int?] = [7, nil, 6, 8, 9, 11, 2, 0, 3, 4, nil, 5]
        let matchedEdges: [Int?] = [0, nil, 2, 4, 6, 7, 2, 0, 4, 6, nil, 7]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 2, 3, 4, 5] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-065 NetworkX disconnected graph: edges [0, 2] {0–3, 1–4}; König cover [0, 1]; 1 phase")
    func ma065() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-3, 1-3, 1-4]; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 3), (1, 3), (1, 4)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [3, 4, nil, 0, 1, nil]
        let mateIndices: [Int?] = [3, 4, nil, 0, 1, nil]
        let matchedEdges: [Int?] = [0, 2, nil, 0, 2, nil]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 1] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-066 isolated vertices on both sides: edges [0] {1–4}; König cover [1]; 1 phase")
    func ma066() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [1-4]; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(1, 4)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0])
        #expect(matching.weight == 1)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [nil, 4, nil, nil, 1, nil]
        let mateIndices: [Int?] = [nil, 4, nil, nil, 1, nil]
        let matchedEdges: [Int?] = [nil, 0, nil, nil, 0, nil]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [1] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-067 lcgb(6,6,14,3)")
    func ma067() throws {
        // lcgb(6,6,14,3); maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(5, 7), (5, 10), (0, 11), (1, 11), (5, 9), (1, 6), (2, 9), (4, 11), (3, 7), (1, 8), (5, 6), (5, 11), (1, 7), (3, 9)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5] as [Int], right: [6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 14)
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [1, 2, 5, 6, 8])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let mates: [Int?] = [11, 6, 9, 7, nil, 10, 1, 3, nil, 2, 5, 0]
        let mateIndices: [Int?] = [11, 6, 9, 7, nil, 10, 1, 3, nil, 2, 5, 0]
        let matchedEdges: [Int?] = [2, 5, 6, 8, nil, 1, 5, 8, nil, 6, 1, 2]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [1, 2, 3, 5, 11] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-068 lcgb(8,5,20,11)")
    func ma068() throws {
        // lcgb(8,5,20,11); maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 9), (7, 11), (6, 11), (1, 10), (4, 11), (3, 10), (5, 10), (0, 10), (3, 12), (0, 11), (6, 8), (6, 12), (4, 9), (2, 12), (5, 11), (2, 8), (4, 12), (3, 8), (0, 8), (1, 9)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], right: [8, 9, 10, 11, 12] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 20)
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0, 3, 4, 13, 17])
        #expect(matching.weight == 5)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as [Int])
        let mates: [Int?] = [9, 10, 12, 8, 11, nil, nil, nil, 3, 0, 1, 4, 2]
        let mateIndices: [Int?] = [9, 10, 12, 8, 11, nil, nil, nil, 3, 0, 1, 4, 2]
        let matchedEdges: [Int?] = [0, 3, 13, 17, 4, nil, nil, nil, 17, 0, 3, 4, 13]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [8, 9, 10, 11, 12] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-069 lcgb(10,10,25,5)")
    func ma069() throws {
        // lcgb(10,10,25,5); maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(2, 13), (4, 15), (5, 11), (9, 19), (0, 14), (5, 14), (8, 11), (3, 17), (8, 13), (2, 10), (8, 12), (1, 14), (0, 19), (5, 13), (5, 19), (0, 11), (4, 18), (0, 10), (4, 16), (8, 14), (7, 16), (1, 17), (1, 12), (1, 15), (1, 18)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], right: [10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 25)
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [0, 1, 2, 3, 4, 7, 10, 20, 24])
        #expect(matching.weight == 9)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let mates: [Int?] = [14, 18, 13, 17, 15, 11, nil, 16, 12, 19, nil, 5, 8, 2, 0, 4, 7, 3, 1, 9]
        let mateIndices: [Int?] = [14, 18, 13, 17, 15, 11, nil, 16, 12, 19, nil, 5, 8, 2, 0, 4, 7, 3, 1, 9]
        let matchedEdges: [Int?] = [4, 24, 0, 7, 1, 2, nil, 20, 10, 3, nil, 2, 10, 0, 4, 1, 20, 7, 24, 3]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 1, 2, 3, 4, 5, 7, 8, 9] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-070 lcgb(30,30,90,2) (several phases)")
    func ma070() throws {
        // lcgb(30,30,90,2); maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(10, 42), (6, 44), (5, 59), (18, 48), (15, 32), (23, 32), (4, 34), (6, 54), (24, 53), (26, 55), (2, 38), (14, 44), (25, 36), (29, 42), (23, 37), (18, 52), (3, 46), (9, 49), (17, 34), (6, 34), (15, 56), (25, 43), (10, 56), (26, 35), (10, 32), (7, 55), (6, 50), (20, 57), (6, 51), (21, 30), (2, 46), (12, 59), (29, 47), (20, 33), (27, 44), (14, 41), (0, 34), (16, 34), (7, 56), (24, 51), (14, 48), (3, 36), (18, 43), (0, 58), (11, 33), (19, 45), (9, 38), (24, 34), (13, 58), (17, 55), (22, 47), (10, 54), (6, 57), (7, 58), (8, 56), (26, 53), (12, 53), (6, 37), (12, 55), (20, 39), (14, 46), (3, 47), (14, 50), (3, 48), (25, 34), (24, 59), (25, 46), (10, 55), (13, 32), (24, 35), (13, 36), (24, 46), (10, 57), (18, 53), (13, 52), (9, 42), (27, 57), (27, 53), (20, 35), (8, 45), (3, 38), (28, 50), (20, 37), (6, 33), (23, 39), (1, 35), (26, 52), (10, 38), (2, 54), (6, 52)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int], right: [30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 90)
        #expect(Array(graph.left) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [2, 3, 4, 6, 7, 10, 13, 14, 16, 17, 21, 25, 29, 34, 35, 39, 43, 44, 45, 50, 54, 56, 59, 70, 72, 81, 85, 86])
        #expect(matching.weight == 28)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59] as [Int])
        let mates: [Int?] = [58, 35, 38, 46, 34, 59, 54, 55, 56, 49, 57, 33, 53, 36, 41, 32, nil, nil, 48, 45, 39, 30, 47, 37, 51, 43, 52, 44, 50, 42, 21, nil, 15, 11, 4, 1, 13, 23, 2, 20, nil, 14, 29, 25, 27, 19, 3, 22, 18, 9, 28, 24, 26, 12, 6, 7, 8, 10, 0, 5]
        let mateIndices: [Int?] = [58, 35, 38, 46, 34, 59, 54, 55, 56, 49, 57, 33, 53, 36, 41, 32, nil, nil, 48, 45, 39, 30, 47, 37, 51, 43, 52, 44, 50, 42, 21, nil, 15, 11, 4, 1, 13, 23, 2, 20, nil, 14, 29, 25, 27, 19, 3, 22, 18, 9, 28, 24, 26, 12, 6, 7, 8, 10, 0, 5]
        let matchedEdges: [Int?] = [43, 85, 10, 16, 6, 2, 7, 25, 54, 17, 72, 44, 56, 70, 35, 4, nil, nil, 3, 45, 59, 29, 50, 14, 39, 21, 86, 34, 81, 13, 29, nil, 4, 44, 6, 85, 70, 14, 10, 59, nil, 35, 13, 21, 34, 45, 16, 50, 3, 17, 81, 39, 86, 56, 7, 25, 54, 72, 43, 2]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [1, 2, 3, 5, 6, 9, 10, 11, 12, 13, 14, 15, 18, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 34, 45, 55, 56, 58] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
    }

    @Test("MA-071 Graph: path P6 via canonical bipartition")
    func ma071() throws {
        // P(6); maximumBipartiteMatching(bipartition: bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0, 2, 4] as [Int])
        let matching = graph.maximumBipartiteMatching(bipartition: bipartition)
        #expect(matching.edges == [0, 2, 4])
        #expect(matching.weight == 3)
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(bipartition.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 2, 4] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-072 Graph: C6: left [0, 2, 4]; edges [0, 2, 4] {0–1, 2–3, 4–5}; perfect; König cover [0, 2, 4]; 1 phase")
    func ma072() throws {
        // C(6); maximumBipartiteMatching(bipartition: bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0, 2, 4] as [Int])
        let matching = graph.maximumBipartiteMatching(bipartition: bipartition)
        #expect(matching.edges == [0, 2, 4])
        #expect(matching.weight == 3)
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(bipartition.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 2, 4] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-073 Graph: grid 3×4")
    func ma073() throws {
        // grid(3,4); maximumBipartiteMatching(bipartition: bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 17)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0, 2, 5, 7, 8, 10] as [Int])
        let matching = graph.maximumBipartiteMatching(bipartition: bipartition)
        #expect(matching.edges == [0, 4, 7, 11, 14, 16])
        #expect(matching.weight == 6)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10]
        let matchedEdges: [Int?] = [0, 0, 4, 4, 7, 7, 11, 11, 14, 14, 16, 16]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(bipartition.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 2, 5, 7, 8, 10] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-074 Graph: two components, left = least vertex (vertices out of numeric order: left is [5, 0, 2])")
    func ma074() throws {
        // V [5, 0, 1, 2, 3]; E [0-1, 2-3, 5-3]; maximumBipartiteMatching(bipartition: bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (5, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [5, 0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [5, 0, 2] as [Int])
        let matching = graph.maximumBipartiteMatching(bipartition: bipartition)
        #expect(matching.edges == [0, 2])
        #expect(matching.weight == 2)
        #expect(matching.isPerfect == false)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [5, 0, 1, 2, 3] as [Int])
        let mates: [Int?] = [3, 1, 0, nil, 5]
        let mateIndices: [Int?] = [4, 2, 1, nil, 0]
        let matchedEdges: [Int?] = [2, 0, 0, nil, 2]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(bipartition.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 3] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-075 Graph: multigraph, parallel copies (the first copy in 0's row is matched)")
    func ma075() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-1, 0-2]; maximumBipartiteMatching(bipartition: bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (0, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0] as [Int])
        let matching = graph.maximumBipartiteMatching(bipartition: bipartition)
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(bipartition.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-076 Graph: even cycle with chords (K3,3 as a plain graph)")
    func ma076() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0-3, 0-4, 0-5, 1-3, 1-4, 1-5, 2-3, 2-4, 2-5]; maximumBipartiteMatching(bipartition: bipartition()!)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 9)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0, 1, 2] as [Int])
        let matching = graph.maximumBipartiteMatching(bipartition: bipartition)
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(bipartition.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 1, 2] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-077 Hypercube Q3")
    func ma077() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [0-1, 0-2, 0-4, 1-3, 1-5, 2-3, 2-6, 3-7, 4-5, 4-6, 5-7, 6-7]; maximumBipartiteMatching(bipartition: bipartition()!)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0, 3, 5, 6] as [Int])
        let matching = graph.maximumBipartiteMatching(bipartition: bipartition)
        #expect(matching.edges == [0, 5, 8, 11])
        #expect(matching.weight == 4)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let mates: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6]
        let mateIndices: [Int?] = [1, 0, 3, 2, 5, 4, 7, 6]
        let matchedEdges: [Int?] = [0, 0, 5, 5, 8, 8, 11, 11]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(bipartition.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 3, 5, 6] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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

    @Test("MA-078 C6 as a bipartite graph, edges listed in reverse")
    func ma078() throws {
        // L [0, 1, 2]; R [3, 4, 5]; E [0-5, 2-5, 2-4, 1-4, 1-3, 0-3]; maximumBipartiteMatching()
        let pairs: [(Int, Int)] = [(0, 5), (2, 5), (2, 4), (1, 4), (1, 3), (0, 3)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2] as [Int], right: [3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 6)
        #expect(Array(graph.left) == [0, 1, 2] as [Int])
        let matching = graph.maximumBipartiteMatching()
        #expect(matching.edges == [1, 3, 5])
        #expect(matching.weight == 3)
        #expect(matching.isPerfect == true)
        // Every vertex's mate, its index and the matched edge, in `vertices` order.
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let mates: [Int?] = [3, 4, 5, 0, 1, 2]
        let mateIndices: [Int?] = [3, 4, 5, 0, 1, 2]
        let matchedEdges: [Int?] = [5, 3, 1, 5, 3, 1]
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
        // König: Z is every vertex reached from a free left vertex by an alternating path (an
        // unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a
        // vertex cover as large as the matching, which certifies that the matching is maximum.
        let leftSide = Set(graph.left)
        var reached = Set(leftSide.filter { matching.mate(of: $0) == nil })
        var frontier = Array(reached)
        while let x = frontier.popLast() {
            if leftSide.contains(x) {
                for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
            } else if let y = matching.mate(of: x), reached.insert(y).inserted {
                frontier.append(y)
            }
        }
        let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }
        #expect(cover == [0, 1, 2] as [Int])
        #expect(cover.count == matching.edges.count)
        for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), "\(edge) uncovered") }
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
