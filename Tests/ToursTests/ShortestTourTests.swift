// `shortestTour(weight:)` on `Graph` and `DirectedGraph` (catalog §ShortestTour,
// §ShortestTourDirected): Held–Karp's tour exactly; on up to 9 vertices the brute-force optimum and
// the lexicographically least optimal tour from the first vertex, checked in the test; graphs need
// not be complete (nil exactly when there is no Hamiltonian cycle, also checked with
// `hamiltonianCycle()`); directed tours step along arcs and read each ordered pair's lightest arc;
// nil below three vertices. Directed rows are `AdjacencyList`, or `DirectedPseudograph` with a
// self-loop or a repeated edge; undirected rows `UndirectedAdjacencyList`, or `Pseudograph` with a
// self-loop or parallel edges; each built by inserting the row's vertices, then its edges in order,
// so positions are the catalog's. In-test checks number vertices by their index in `vertices`.
// Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's models; see
// README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

@Suite("shortestTour")
struct ShortestTourTests {
    @Test("TO-469 square: the perimeter: cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]; weight 4")
    func to469() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let weights: [Int] = [1, 2, 1, 1, 2, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3] as [Int])
        #expect(tour.edges == [0, 3, 5, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == 4)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-470 square listed crosswise: cycle [0, 2, 1, 3]; edges [1, 3, 4, 2]; weight 4")
    func to470() throws {
        // pts[(0,0),(1,1),(0,1),(1,0)]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let weights: [Int] = [2, 1, 1, 1, 1, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 1, 3] as [Int])
        #expect(tour.edges == [1, 3, 4, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == 4)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-471 five points on a line: cycle [0, 1, 3, 4, 2]; edges [0, 5, 9, 8, 1]; weight 8")
    func to471() throws {
        // pts[(0,0),(3,0),(1,0),(4,0),(2,0)]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let weights: [Int] = [3, 1, 4, 2, 2, 1, 1, 3, 1, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 3, 4, 2] as [Int])
        #expect(tour.edges == [0, 5, 9, 8, 1] as [Int])
        #expect(tour.weight({ weights[$0] }) == 8)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-472 all weights equal: K(5) weight 1: cycle [0, 1, 2, 3, 4]; edges [0, 4, 7, 9, 3]; weight 5")
    func to472() throws {
        // K(5) weight 1; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
        #expect(tour.edges == [0, 4, 7, 9, 3] as [Int])
        #expect(tour.weight({ weights[$0] }) == 5)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-473 K(4) with weights 1..6: cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]; weight 14")
    func to473() throws {
        // K(4) weights 1, 2, 3, 4, 5, 6 in edge order; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let weights: [Int] = [1, 2, 3, 4, 5, 6]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3] as [Int])
        #expect(tour.edges == [0, 3, 5, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == 14)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-474 lcgpts(6,1,10): cycle [0, 2, 4, 1, 3, 5]; edges [1, 10, 7, 6, 13, 4]; weight 30")
    func to474() throws {
        // lcgpts(6,1,10); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let weights: [Int] = [5, 2, 5, 8, 2, 7, 8, 9, 5, 7, 6, 4, 13, 3, 10]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 4, 1, 3, 5] as [Int])
        #expect(tour.edges == [1, 10, 7, 6, 13, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 30)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-475 lcgpts(8,2,20): cycle [0, 1, 7, 6, 2, 3, 4, 5]; edges [0, 12, 27, 16, 13, 18, 22, 4]; weight 68")
    func to475() throws {
        // lcgpts(8,2,20); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
        let weights: [Int] = [18, 32, 24, 5, 3, 26, 28, 16, 22, 13, 15, 12, 10, 8, 27, 29, 6, 6, 19, 21, 10, 12, 2, 21, 23, 23, 25, 2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 7, 6, 2, 3, 4, 5] as [Int])
        #expect(tour.edges == [0, 12, 27, 16, 13, 18, 22, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 68)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-476 lcgpts(9,3,30): cycle [0, 2, 1, 8, 5, 6, 3, 7, 4]; edges [1, 8, 14, 32, 30, 23, 24, 28, 3]; weight 96")
    func to476() throws {
        // lcgpts(9,3,30); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 5), (4, 6), (4, 7), (4, 8), (5, 6), (5, 7), (5, 8), (6, 7), (6, 8), (7, 8)]
        let weights: [Int] = [39, 15, 12, 4, 17, 7, 9, 26, 24, 43, 43, 24, 40, 46, 13, 19, 19, 22, 16, 22, 19, 8, 19, 5, 3, 30, 19, 3, 5, 30, 16, 22, 11, 6, 27, 33]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 1, 8, 5, 6, 3, 7, 4] as [Int])
        #expect(tour.edges == [1, 8, 14, 32, 30, 23, 24, 28, 3] as [Int])
        #expect(tour.weight({ weights[$0] }) == 96)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-477 lcgK(7,4,9): not metric: cycle [0, 2, 1, 5, 4, 6, 3]; edges [1, 6, 9, 18, 19, 17, 2]; weight 22")
    func to477() throws {
        // lcgK(7,4,9); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
        let weights: [Int] = [3, 2, 2, 9, 9, 9, 5, 9, 9, 2, 8, 9, 9, 9, 6, 5, 1, 2, 4, 5, 9]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 1, 5, 4, 6, 3] as [Int])
        #expect(tour.edges == [1, 6, 9, 18, 19, 17, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == 22)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-478 lcgK(8,5,20): not metric: cycle [0, 1, 2, 7, 5, 3, 4, 6]; edges [0, 7, 17, 26, 19, 18, 23, 5]; weight 48")
    func to478() throws {
        // lcgK(8,5,20); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 4), (3, 5), (3, 6), (3, 7), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7)]
        let weights: [Int] = [13, 14, 15, 6, 16, 12, 20, 10, 11, 5, 16, 15, 9, 12, 14, 18, 9, 4, 3, 1, 11, 5, 9, 3, 2, 15, 2, 15]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 7, 5, 3, 4, 6] as [Int])
        #expect(tour.edges == [0, 7, 17, 26, 19, 18, 23, 5] as [Int])
        #expect(tour.weight({ weights[$0] }) == 48)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-479 lcgK(6,6,9,/4): Double weights: cycle [0, 1, 2, 5, 4, 3]; edges [0, 5, 11, 14, 12, 2]; weight 5.5")
    func to479() throws {
        // lcgK(6,6,9,/4); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 5, 4, 3] as [Int])
        #expect(tour.edges == [0, 5, 11, 14, 12, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == 5.5)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Double = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Double? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Double = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-480 negative weights: cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]; weight -2")
    func to480() throws {
        // K(4) weights -1, 2, -3, 4, 0, -2; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let weights: [Int] = [-1, 2, -3, 4, 0, -2]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3] as [Int])
        #expect(tour.edges == [0, 3, 5, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == -2)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-481 parallel copies: the lightest: cycle [0, 1, 2]; edges [1, 2, 3]; weight 6")
    func to481() throws {
        // multigraph V [0, 1, 2]; E [0-1 5, 0-1 2, 1-2 1, 2-0 3, 2-0 3]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let weights: [Int] = [5, 2, 1, 3, 3]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2] as [Int])
        #expect(tour.edges == [1, 2, 3] as [Int])
        #expect(tour.weight({ weights[$0] }) == 6)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-482 self-loops ignored: cycle [0, 1, 2]; edges [1, 2, 4]; weight 6")
    func to482() throws {
        // multigraph V [0, 1, 2]; E [0-0 -9, 0-1 1, 1-2 2, 1-1 -9, 2-0 3]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
        let weights: [Int] = [-9, 1, 2, -9, 3]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2] as [Int])
        #expect(tour.edges == [1, 2, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 6)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-483 vertex order, not label order: cycle [d, a, c, b]; edges [0, 3, 5, 2]; weight 6")
    func to483() throws {
        // V [d, a, c, b]; E [d-a 1, d-c 4, d-b 2, a-c 2, a-b 5, c-b 1]; shortestTour(weight:)
        let pairs: [(String, String)] = [("d", "a"), ("d", "c"), ("d", "b"), ("a", "c"), ("a", "b"), ("c", "b")]
        let weights: [Int] = [1, 4, 2, 2, 5, 1]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == ["d", "a", "c", "b"] as [String])
        #expect(tour.edges == [0, 3, 5, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == 6)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-484 one vertex: nil: nil")
    func to484() {
        // V [0]; E []; shortestTour(weight:)
        let pairs: [(Int, Int)] = []
        let weights: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-485 two vertices: nil: nil")
    func to485() {
        // V [0, 1]; E [0-1 3]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let weights: [Int] = [3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-486 two vertices, parallel edges: nil (tours read the simple graph): nil")
    func to486() {
        // multigraph V [0, 1]; E [0-1 3, 0-1 4]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let weights: [Int] = [3, 4]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-487 empty graph: nil: nil")
    func to487() {
        // V []; E []; shortestTour(weight:)
        let pairs: [(Int, Int)] = []
        let weights: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-488 not complete: C(5) is its only tour: cycle [0, 1, 2, 3, 4]; edges [0, 1, 2, 3, 4]; weight 15")
    func to488() throws {
        // C(5) weights 1, 2, 3, 4, 5; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let weights: [Int] = [1, 2, 3, 4, 5]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
        #expect(tour.edges == [0, 1, 2, 3, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 15)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-489 not complete, no Hamiltonian cycle: nil: nil")
    func to489() {
        // V [0, 1, 2, 3]; E [0-1 1, 0-2 1, 0-3 1, 1-2 1]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2)]
        let weights: [Int] = [1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        // No Hamiltonian cycle at all.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-490 Petersen weight 1: nil: nil")
    func to490() {
        // nx(petersen_graph) weight 1; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        // No Hamiltonian cycle at all.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-491 lcgpts(12,7,50)")
    func to491() throws {
        // lcgpts(12,7,50); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
        let weights: [Int] = [33, 29, 31, 16, 23, 5, 40, 41, 48, 20, 41, 46, 20, 49, 44, 36, 57, 28, 65, 53, 26, 36, 23, 6, 24, 11, 70, 19, 33, 70, 47, 42, 34, 37, 44, 45, 51, 44, 17, 13, 34, 47, 42, 10, 47, 18, 17, 64, 25, 27, 64, 35, 46, 43, 17, 46, 81, 14, 44, 81, 89, 37, 2, 52, 89, 37]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 4, 10, 8, 11, 1, 3, 7, 9, 2, 5, 6] as [Int])
        #expect(tour.edges == [3, 43, 61, 62, 20, 12, 33, 57, 27, 23, 45, 5] as [Int])
        #expect(tour.weight({ weights[$0] }) == 210)
        // The simple graph, built here: each pair's lightest edge (the earliest position on ties); self-loops
        // ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
            lightest[b][a] = k
        }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
    }

    @Test("TO-507 asymmetric triangle: the lighter direction: cycle [0, 1, 2]; edges [0, 1, 2]; weight 3")
    func to507() throws {
        // V [0, 1, 2]; E [0→1 1, 1→2 1, 2→0 1, 0→2 2, 2→1 2, 1→0 2]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
        let weights: [Int] = [1, 1, 1, 2, 2, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2] as [Int])
        #expect(tour.edges == [0, 1, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == 3)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-508 asymmetric triangle, the other way: cycle [0, 2, 1]; edges [3, 4, 5]; weight 4")
    func to508() throws {
        // V [0, 1, 2]; E [0→1 3, 1→2 3, 2→0 3, 0→2 1, 2→1 2, 1→0 1]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2), (2, 1), (1, 0)]
        let weights: [Int] = [3, 3, 3, 1, 2, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 1] as [Int])
        #expect(tour.edges == [3, 4, 5] as [Int])
        #expect(tour.weight({ weights[$0] }) == 4)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-509 Kd(4) with weights 1..12: cycle [0, 1, 2, 3]; edges [0, 4, 8, 9]; weight 25")
    func to509() throws {
        // Kd(4) weights 1, 2, …, 12 in edge order; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let weights: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3] as [Int])
        #expect(tour.edges == [0, 4, 8, 9] as [Int])
        #expect(tour.weight({ weights[$0] }) == 25)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-510 all weights equal: Kd(4) weight 1: cycle [0, 1, 2, 3]; edges [0, 4, 8, 9]; weight 4")
    func to510() throws {
        // Kd(4) weight 1; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3] as [Int])
        #expect(tour.edges == [0, 4, 8, 9] as [Int])
        #expect(tour.weight({ weights[$0] }) == 4)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-511 lcgKd(5,1,9): cycle [0, 4, 2, 3, 1]; edges [3, 18, 10, 13, 4]; weight 21")
    func to511() throws {
        // lcgKd(5,1,9); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3)]
        let weights: [Int] = [6, 4, 4, 4, 1, 9, 6, 8, 4, 5, 4, 8, 4, 4, 6, 5, 2, 9, 8, 7]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 4, 2, 3, 1] as [Int])
        #expect(tour.edges == [3, 18, 10, 13, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 21)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-512 lcgKd(6,2,20): cycle [0, 1, 5, 3, 4, 2]; edges [0, 9, 28, 18, 22, 10]; weight 24")
    func to512() throws {
        // lcgKd(6,2,20); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
        let weights: [Int] = [1, 3, 17, 5, 16, 20, 9, 19, 6, 3, 4, 3, 15, 15, 17, 15, 15, 14, 7, 16, 13, 19, 5, 15, 6, 7, 20, 3, 4, 8]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 5, 3, 4, 2] as [Int])
        #expect(tour.edges == [0, 9, 28, 18, 22, 10] as [Int])
        #expect(tour.weight({ weights[$0] }) == 24)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-513 lcgKd(7,3,9): cycle [0, 2, 1, 6, 4, 3, 5]; edges [1, 13, 11, 40, 27, 22, 30]; weight 22")
    func to513() throws {
        // lcgKd(7,3,9); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5)]
        let weights: [Int] = [6, 2, 6, 8, 7, 3, 8, 3, 9, 7, 5, 4, 9, 4, 2, 6, 7, 2, 5, 6, 3, 2, 3, 7, 6, 9, 5, 2, 5, 1, 5, 4, 6, 2, 3, 7, 7, 7, 7, 8, 2, 4]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 1, 6, 4, 3, 5] as [Int])
        #expect(tour.edges == [1, 13, 11, 40, 27, 22, 30] as [Int])
        #expect(tour.weight({ weights[$0] }) == 22)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-514 lcgKd(8,4,30): cycle [0, 7, 3, 1, 5, 2, 4, 6]; edges [6, 52, 22, 11, 37, 17, 33, 42]; weight 43")
    func to514() throws {
        // lcgKd(8,4,30); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6)]
        let weights: [Int] = [27, 23, 5, 12, 6, 18, 2, 24, 15, 17, 26, 15, 27, 15, 12, 8, 25, 8, 19, 29, 9, 26, 1, 29, 28, 17, 27, 24, 28, 11, 20, 19, 20, 1, 1, 26, 4, 3, 9, 5, 5, 15, 6, 12, 21, 10, 7, 4, 29, 7, 8, 30, 7, 22, 5, 27]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 7, 3, 1, 5, 2, 4, 6] as [Int])
        #expect(tour.edges == [6, 52, 22, 11, 37, 17, 33, 42] as [Int])
        #expect(tour.weight({ weights[$0] }) == 43)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-515 lcgKd(9,5,50): cycle [0, 6, 8, 1, 3, 4, 2, 5, 7]; edges [5, 55, 65, 10, 27, 34, 20, 46, 56]; weight 67")
    func to515() throws {
        // lcgKd(9,5,50); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7)]
        let weights: [Int] = [43, 24, 35, 6, 26, 12, 20, 10, 41, 25, 6, 35, 39, 22, 44, 28, 19, 14, 43, 41, 1, 15, 29, 3, 42, 15, 12, 5, 20, 30, 21, 40, 36, 44, 16, 4, 36, 40, 21, 32, 15, 49, 31, 35, 41, 41, 5, 37, 19, 25, 23, 1, 18, 27, 21, 1, 12, 8, 42, 13, 42, 26, 25, 37, 22, 9, 13, 41, 26, 20, 12, 13]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 6, 8, 1, 3, 4, 2, 5, 7] as [Int])
        #expect(tour.edges == [5, 55, 65, 10, 27, 34, 20, 46, 56] as [Int])
        #expect(tour.weight({ weights[$0] }) == 67)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-516 lcgKd(6,6,9,/4): Double weights: cycle [0, 1, 2, 5, 3, 4]; edges [0, 6, 14, 28, 18, 20]; weight 4.25")
    func to516() throws {
        // lcgKd(6,6,9,/4); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]
        let weights: [Double] = [0.75, 2.25, 1.0, 1.0, 2.25, 0.75, 1.75, 1.0, 1.25, 1.0, 2.25, 1.25, 1.25, 2.0, 0.5, 1.5, 2.0, 1.0, 0.25, 0.5, 0.5, 2.0, 1.75, 2.0, 0.5, 1.25, 1.75, 2.25, 0.5, 1.0]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 5, 3, 4] as [Int])
        #expect(tour.edges == [0, 6, 14, 28, 18, 20] as [Int])
        #expect(tour.weight({ weights[$0] }) == 4.25)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Double = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Double? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Double = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-517 negative weights: cycle [0, 1, 2]; edges [0, 3, 4]; weight 0")
    func to517() throws {
        // Kd(3) weights -1, 2, 3, -4, 5, 0; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
        let weights: [Int] = [-1, 2, 3, -4, 5, 0]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2] as [Int])
        #expect(tour.edges == [0, 3, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 0)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-518 parallel arcs: the lightest: cycle [0, 1, 2]; edges [1, 2, 3]; weight 6")
    func to518() throws {
        // multigraph V [0, 1, 2]; E [0→1 5, 0→1 2, 1→2 1, 2→0 3, 2→0 3]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let weights: [Int] = [5, 2, 1, 3, 3]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2] as [Int])
        #expect(tour.edges == [1, 2, 3] as [Int])
        #expect(tour.weight({ weights[$0] }) == 6)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-519 self-loops ignored: cycle [0, 1, 2]; edges [1, 2, 4]; weight 6")
    func to519() throws {
        // multigraph V [0, 1, 2]; E [0→0 -9, 0→1 1, 1→2 2, 1→1 -9, 2→0 3]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)]
        let weights: [Int] = [-9, 1, 2, -9, 3]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2] as [Int])
        #expect(tour.edges == [1, 2, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 6)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-520 vertex order, not label order: cycle [d, c, a]; edges [3, 4, 5]; weight 3")
    func to520() throws {
        // V [d, a, c]; E [d→a 4, a→c 4, c→d 4, d→c 1, c→a 1, a→d 1]; shortestTour(weight:)
        let pairs: [(String, String)] = [("d", "a"), ("a", "c"), ("c", "d"), ("d", "c"), ("c", "a"), ("a", "d")]
        let weights: [Int] = [4, 4, 4, 1, 1, 1]
        let graph = AdjacencyList<String>(vertices: ["d", "a", "c"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == ["d", "c", "a"] as [String])
        #expect(tour.edges == [3, 4, 5] as [Int])
        #expect(tour.weight({ weights[$0] }) == 3)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-521 not complete: Cd(5) is its only tour: cycle [0, 1, 2, 3, 4]; edges [0, 1, 2, 3, 4]; weight 15")
    func to521() throws {
        // Cd(5) weights 1, 2, 3, 4, 5; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let weights: [Int] = [1, 2, 3, 4, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3, 4] as [Int])
        #expect(tour.edges == [0, 1, 2, 3, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 15)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-522 not complete, one way only: Pd(4) has no tour: nil")
    func to522() {
        // Pd(4) weight 1; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let weights: [Int] = [1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        // No Hamiltonian cycle at all.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-523 tournament(6,1) weight 1: cycle [0, 3, 5, 1, 4, 2]; edges [2, 13, 8, 7, 10, 1]; weight 6")
    func to523() throws {
        // tournament(6,1) weight 1; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
        let weights: [Int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 3, 5, 1, 4, 2] as [Int])
        #expect(tour.edges == [2, 13, 8, 7, 10, 1] as [Int])
        #expect(tour.weight({ weights[$0] }) == 6)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let d: (Int, Int) -> Int = { weights[lightest[$0][$1]!] }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
        let weight = tour.weight({ weights[$0] })
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight,
        // and the first such ordering in lexicographic order.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        var best: [Int] = []
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
                    best = order
                }
            }
            var i = n - 2
            while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
            if i < 1 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(weight == optimum)
        #expect(at == best)
    }

    @Test("TO-524 transitive tournament: nil: nil")
    func to524() {
        // V [0, 1, 2, 3]; E [0→1 1, 0→2 1, 0→3 1, 1→2 1, 1→3 1, 2→3 1]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let weights: [Int] = [1, 1, 1, 1, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
        // No Hamiltonian cycle at all.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-525 one vertex: nil: nil")
    func to525() {
        // V [0]; E []; shortestTour(weight:)
        let pairs: [(Int, Int)] = []
        let weights: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-526 antiparallel pair: nil (tours need three vertices): nil")
    func to526() {
        // V [0, 1]; E [0→1 1, 1→0 2]; shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let weights: [Int] = [1, 2]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-527 empty digraph: nil: nil")
    func to527() {
        // V []; E []; shortestTour(weight:)
        let pairs: [(Int, Int)] = []
        let weights: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.shortestTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-528 lcgKd(12,7,100)")
    func to528() throws {
        // lcgKd(12,7,100); shortestTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (1, 0), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (2, 0), (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 8), (7, 9), (7, 10), (7, 11), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (8, 7), (8, 9), (8, 10), (8, 11), (9, 0), (9, 1), (9, 2), (9, 3), (9, 4), (9, 5), (9, 6), (9, 7), (9, 8), (9, 10), (9, 11), (10, 0), (10, 1), (10, 2), (10, 3), (10, 4), (10, 5), (10, 6), (10, 7), (10, 8), (10, 9), (10, 11), (11, 0), (11, 1), (11, 2), (11, 3), (11, 4), (11, 5), (11, 6), (11, 7), (11, 8), (11, 9), (11, 10)]
        let weights: [Int] = [79, 32, 54, 74, 46, 20, 65, 65, 40, 87, 96, 76, 33, 81, 50, 63, 6, 100, 97, 52, 37, 94, 55, 99, 54, 5, 41, 46, 94, 33, 53, 18, 51, 76, 74, 40, 10, 8, 73, 53, 46, 36, 89, 11, 81, 45, 5, 5, 47, 91, 73, 55, 58, 69, 75, 52, 9, 57, 7, 4, 60, 34, 64, 61, 56, 86, 1, 84, 53, 39, 22, 99, 11, 24, 9, 66, 19, 82, 51, 35, 33, 36, 77, 33, 78, 100, 79, 68, 40, 80, 26, 22, 18, 55, 49, 59, 16, 77, 26, 84, 17, 7, 86, 73, 32, 52, 56, 5, 95, 72, 82, 4, 29, 1, 6, 55, 83, 22, 11, 8, 28, 47, 99, 51, 71, 89, 13, 15, 86, 74, 11, 10]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.shortestTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 9, 8, 11, 10, 7, 2, 4, 3, 5, 1, 6] as [Int])
        #expect(tour.edges == [8, 107, 98, 131, 117, 79, 25, 47, 37, 56, 16, 66] as [Int])
        #expect(tour.weight({ weights[$0] }) == 172)
        // The simple digraph, built here: each ordered pair's lightest arc (the earliest position on ties);
        // self-loops ignored. `d` is its weight.
        var lightest = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
        for k in pairs.indices where ends[k].0 != ends[k].1 {
            let (a, b) = ends[k]
            if let e = lightest[a][b], weights[e] <= weights[k] { continue }
            lightest[a][b] = k
        }
        let walked = tour.edges
        let at = tour.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: tour.vertices, edges: tour.edges, in: graph) != nil)
        // Each step through its pair's lightest edge.
        for i in 0 ..< n { #expect(walked[i] == lightest[at[i]][at[(i + 1) % n]], "step \(i)") }
        // It starts at the first vertex.
        #expect(at[0] == 0)
    }
}
