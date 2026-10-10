// `christofidesTour(weight:)` (catalog §ChristofidesTour): the pinned composition's tour exactly;
// `weight` called once per non-loop edge; checked here as a Hamiltonian cycle through the lightest
// copies from the first vertex, and on up to 9 vertices against the brute-force optimum, within 3/2
// of it where the weights are a metric; nil below three vertices. Directed rows are `AdjacencyList`,
// or `DirectedPseudograph` with a self-loop or a repeated edge; undirected rows
// `UndirectedAdjacencyList`, or `Pseudograph` with a self-loop or parallel edges; each built by
// inserting the row's vertices, then its edges in order, so positions are the catalog's. In-test
// checks number vertices by their index in `vertices`. Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's models; see README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

@Suite("christofidesTour")
struct ChristofidesTourTests {
    @Test("TO-422 square: the perimeter: cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]; weight 4")
    func to422() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-423 square listed crosswise: cycle [0, 2, 1, 3]; edges [1, 3, 4, 2]; weight 4")
    func to423() throws {
        // pts[(0,0),(1,1),(0,1),(1,0)]; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-424 five points on a line: cycle [0, 2, 4, 1, 3]; edges [1, 8, 6, 5, 2]; weight 8")
    func to424() throws {
        // pts[(0,0),(3,0),(1,0),(4,0),(2,0)]; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 4, 1, 3] as [Int])
        #expect(tour.edges == [1, 8, 6, 5, 2] as [Int])
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-425 all weights equal: K(5) weight 1: cycle [0, 1, 4, 2, 3]; edges [0, 6, 8, 7, 2]; weight 5")
    func to425() throws {
        // K(5) weight 1; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 4, 2, 3] as [Int])
        #expect(tour.edges == [0, 6, 8, 7, 2] as [Int])
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-426 K(4) with weights 1..6: cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]; weight 14")
    func to426() throws {
        // K(4) weights 1, 2, 3, 4, 5, 6 in edge order; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
    }

    @Test("TO-427 lcgpts(6,1,10): cycle [0, 1, 4, 2, 5, 3]; edges [0, 7, 10, 11, 13, 2]; weight 32")
    func to427() throws {
        // lcgpts(6,1,10); christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 4, 2, 5, 3] as [Int])
        #expect(tour.edges == [0, 7, 10, 11, 13, 2] as [Int])
        #expect(tour.weight({ weights[$0] }) == 32)
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-428 lcgpts(8,2,20): cycle [0, 5, 4, 1, 7, 6, 2, 3]; edges [4, 22, 9, 12, 27, 16, 13, 2]; weight 68")
    func to428() throws {
        // lcgpts(8,2,20); christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 5, 4, 1, 7, 6, 2, 3] as [Int])
        #expect(tour.edges == [4, 22, 9, 12, 27, 16, 13, 2] as [Int])
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-429 lcgpts(9,3,30): cycle [0, 2, 1, 8, 5, 6, 3, 7, 4]; edges [1, 8, 14, 32, 30, 23, 24, 28, 3]; weight 96")
    func to429() throws {
        // lcgpts(9,3,30); christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-430 lcgK(7,4,9): not metric: cycle [0, 2, 1, 5, 4, 3, 6]; edges [1, 6, 9, 18, 15, 17, 5]; weight 29")
    func to430() throws {
        // lcgK(7,4,9); christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 1, 5, 4, 3, 6] as [Int])
        #expect(tour.edges == [1, 6, 9, 18, 15, 17, 5] as [Int])
        #expect(tour.weight({ weights[$0] }) == 29)
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
    }

    @Test("TO-431 lcgK(8,5,20): not metric: cycle [0, 4, 6, 2, 7, 5, 3, 1]; edges [3, 23, 16, 17, 26, 19, 8, 0]; weight 49")
    func to431() throws {
        // lcgK(8,5,20); christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 4, 6, 2, 7, 5, 3, 1] as [Int])
        #expect(tour.edges == [3, 23, 16, 17, 26, 19, 8, 0] as [Int])
        #expect(tour.weight({ weights[$0] }) == 49)
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
    }

    @Test("TO-432 lcgK(6,6,9,/4): Double weights: cycle [0, 1, 2, 5, 4, 3]; edges [0, 5, 11, 14, 12, 2]; weight 5.5")
    func to432() throws {
        // lcgK(6,6,9,/4); christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Double? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Double = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
    }

    @Test("TO-433 negative weights: cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]; weight -2")
    func to433() throws {
        // K(4) weights -1, 2, -3, 4, 0, -2; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
    }

    @Test("TO-434 parallel copies: the lightest: cycle [0, 1, 2]; edges [1, 2, 3]; weight 6")
    func to434() throws {
        // multigraph V [0, 1, 2]; E [0-1 5, 0-1 2, 1-2 1, 2-0 3, 2-0 3]; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-435 self-loops ignored: cycle [0, 1, 2]; edges [1, 2, 4]; weight 6")
    func to435() throws {
        // multigraph V [0, 1, 2]; E [0-0 -9, 0-1 1, 1-2 2, 1-1 -9, 2-0 3]; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
        // The weights are a metric, so Christofides' bound holds: at most 3/2 × the optimum.
        #expect(2 * weight <= 3 * optimum!)
    }

    @Test("TO-436 vertex order, not label order: cycle [d, a, c, b]; edges [0, 3, 5, 2]; weight 6")
    func to436() throws {
        // V [d, a, c, b]; E [d-a 1, d-c 4, d-b 2, a-c 2, a-b 5, c-b 1]; christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
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
        // Brute force, checked here: every ordering of the other vertices after the first; the least weight.
        var order = Array(0 ..< n)
        var optimum: Int? = nil
        while true {
            if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] != nil }) {
                var total: Int = 0
                for i in 0 ..< n { total += d(order[i], order[(i + 1) % n]) }
                if optimum == nil || total < optimum! {
                    optimum = total
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
        #expect(weight >= optimum!)
    }

    @Test("TO-437 one vertex: nil: nil")
    func to437() {
        // V [0]; E []; christofidesTour(weight:)
        let pairs: [(Int, Int)] = []
        let weights: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.christofidesTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-438 two vertices: nil: nil")
    func to438() {
        // V [0, 1]; E [0-1 3]; christofidesTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let weights: [Int] = [3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.christofidesTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-439 two vertices, parallel edges: nil (tours read the simple graph): nil")
    func to439() {
        // multigraph V [0, 1]; E [0-1 3, 0-1 4]; christofidesTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let weights: [Int] = [3, 4]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.christofidesTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-440 empty graph: nil: nil")
    func to440() {
        // V []; E []; christofidesTour(weight:)
        let pairs: [(Int, Int)] = []
        let weights: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.christofidesTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-441 lcgpts(12,7,50)")
    func to441() throws {
        // lcgpts(12,7,50); christofidesTour(weight:)
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
        let result = graph.christofidesTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 3, 1, 11, 8, 10, 4, 5, 2, 7, 9, 6] as [Int])
        #expect(tour.edges == [2, 12, 20, 62, 61, 43, 38, 23, 25, 57, 53, 5] as [Int])
        #expect(tour.weight({ weights[$0] }) == 222)
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

    @Test("TO-442 lcgpts(16,8,100)")
    func to442() throws {
        // lcgpts(16,8,100); christofidesTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (0, 12), (0, 13), (0, 14), (0, 15), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (1, 13), (1, 14), (1, 15), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14), (2, 15), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (3, 12), (3, 13), (3, 14), (3, 15), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (4, 12), (4, 13), (4, 14), (4, 15), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 12), (5, 13), (5, 14), (5, 15), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (6, 15), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 15), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (8, 14), (8, 15), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (9, 15), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (11, 12), (11, 13), (11, 14), (11, 15), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let weights: [Int] = [37, 21, 113, 110, 112, 65, 47, 59, 74, 106, 106, 45, 95, 58, 69, 58, 86, 89, 91, 38, 84, 96, 111, 143, 143, 8, 68, 95, 102, 112, 109, 111, 64, 32, 46, 53, 85, 85, 66, 94, 37, 68, 7, 9, 64, 80, 66, 147, 81, 103, 90, 30, 77, 44, 2, 71, 77, 63, 144, 78, 100, 97, 37, 74, 41, 73, 79, 65, 146, 80, 102, 99, 39, 76, 43, 66, 78, 99, 125, 125, 40, 34, 77, 84, 14, 67, 59, 59, 92, 62, 11, 36, 81, 47, 47, 104, 48, 11, 22, 66, 44, 119, 129, 70, 103, 22, 151, 91, 48, 41, 151, 91, 48, 59, 70, 103, 110, 59, 50, 33]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [Int] = []
        let result = graph.christofidesTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 12, 6, 13, 3, 4, 5, 9, 11, 10, 15, 8, 14, 7, 2] as [Int])
        #expect(tour.edges == [0, 25, 80, 81, 51, 42, 54, 68, 100, 105, 109, 98, 97, 90, 33, 1] as [Int])
        #expect(tour.weight({ weights[$0] }) == 508)
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
}
