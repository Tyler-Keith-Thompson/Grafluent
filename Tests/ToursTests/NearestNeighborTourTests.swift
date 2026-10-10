// `nearestNeighborTour(weight:)` and `(from:weight:)` (catalog §NearestNeighborTour): the tour
// exactly, its edges each pair's lightest copy and its weight; `weight` called once per non-loop
// edge in position order; checked here as a Hamiltonian cycle through the lightest copies, against
// the definition step by step (the nearest unvisited vertex, the first on ties), and on up to 9
// vertices against the brute-force optimum; nil below three vertices. Directed rows are
// `AdjacencyList`, or `DirectedPseudograph` with a self-loop or a repeated edge; undirected rows
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

@Suite("nearestNeighborTour")
struct NearestNeighborTourTests {
    @Test("TO-400 square: the perimeter: cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]; weight 4")
    func to400() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-401 square listed crosswise: cycle [0, 2, 1, 3]; edges [1, 3, 4, 2]; weight 4")
    func to401() throws {
        // pts[(0,0),(1,1),(0,1),(1,0)]; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-402 five points on a line: cycle [0, 2, 4, 1, 3]; edges [1, 8, 6, 5, 2]; weight 8")
    func to402() throws {
        // pts[(0,0),(3,0),(1,0),(4,0),(2,0)]; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-403 all weights equal: K(5) weight 1: cycle [0, 1, 2, 3, 4]; edges [0, 4, 7, 9, 3]; weight 5")
    func to403() throws {
        // K(5) weight 1; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-404 K(4) with weights 1..6: cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]; weight 14")
    func to404() throws {
        // K(4) weights 1, 2, 3, 4, 5, 6 in edge order; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-405 lcgpts(6,1,10): cycle [0, 2, 5, 3, 1, 4]; edges [1, 11, 13, 6, 7, 3]; weight 34")
    func to405() throws {
        // lcgpts(6,1,10); nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 5, 3, 1, 4] as [Int])
        #expect(tour.edges == [1, 11, 13, 6, 7, 3] as [Int])
        #expect(tour.weight({ weights[$0] }) == 34)
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-406 lcgpts(8,2,20): cycle [0, 5, 4, 1, 7, 6, 2, 3]; edges [4, 22, 9, 12, 27, 16, 13, 2]; weight 68")
    func to406() throws {
        // lcgpts(8,2,20); nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-407 lcgpts(9,3,30): cycle [0, 4, 6, 3, 7, 2, 8, 5, 1]; edges [3, 27, 23, 24, 19, 20, 32, 11, 0]; weight 130")
    func to407() throws {
        // lcgpts(9,3,30); nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 4, 6, 3, 7, 2, 8, 5, 1] as [Int])
        #expect(tour.edges == [3, 27, 23, 24, 19, 20, 32, 11, 0] as [Int])
        #expect(tour.weight({ weights[$0] }) == 130)
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-408 lcgK(7,4,9): not metric: cycle [0, 2, 1, 5, 3, 6, 4]; edges [1, 6, 9, 16, 17, 19, 3]; weight 26")
    func to408() throws {
        // lcgK(7,4,9); nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 2, 1, 5, 3, 6, 4] as [Int])
        #expect(tour.edges == [1, 6, 9, 16, 17, 19, 3] as [Int])
        #expect(tour.weight({ weights[$0] }) == 26)
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-409 lcgK(8,5,20): not metric: cycle [0, 4, 7, 5, 3, 1, 2, 6]; edges [3, 24, 26, 19, 8, 7, 16, 5]; weight 53")
    func to409() throws {
        // lcgK(8,5,20); nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 4, 7, 5, 3, 1, 2, 6] as [Int])
        #expect(tour.edges == [3, 24, 26, 19, 8, 7, 16, 5] as [Int])
        #expect(tour.weight({ weights[$0] }) == 53)
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-410 lcgK(6,6,9,/4): Double weights: cycle [0, 1, 2, 3, 4, 5]; edges [0, 5, 9, 12, 14, 4]; weight 6.5")
    func to410() throws {
        // lcgK(6,6,9,/4); nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(tour.edges == [0, 5, 9, 12, 14, 4] as [Int])
        #expect(tour.weight({ weights[$0] }) == 6.5)
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-411 negative weights: cycle [0, 3, 2, 1]; edges [2, 5, 3, 0]; weight -2")
    func to411() throws {
        // K(4) weights -1, 2, -3, 4, 0, -2; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [0, 3, 2, 1] as [Int])
        #expect(tour.edges == [2, 5, 3, 0] as [Int])
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-412 parallel copies: the lightest: cycle [0, 1, 2]; edges [1, 2, 3]; weight 6")
    func to412() throws {
        // multigraph V [0, 1, 2]; E [0-1 5, 0-1 2, 1-2 1, 2-0 3, 2-0 3]; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-413 self-loops ignored: cycle [0, 1, 2]; edges [1, 2, 4]; weight 6")
    func to413() throws {
        // multigraph V [0, 1, 2]; E [0-0 -9, 0-1 1, 1-2 2, 1-1 -9, 2-0 3]; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-414 vertex order, not label order: cycle [d, a, c, b]; edges [0, 3, 5, 2]; weight 6")
    func to414() throws {
        // V [d, a, c, b]; E [d-a 1, d-c 4, d-b 2, a-c 2, a-b 5, c-b 1]; nearestNeighborTour(weight:)
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
        let result = graph.nearestNeighborTour { position in
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
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-415 one vertex: nil: nil")
    func to415() {
        // V [0]; E []; nearestNeighborTour(weight:)
        let pairs: [(Int, Int)] = []
        let weights: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-416 two vertices: nil: nil")
    func to416() {
        // V [0, 1]; E [0-1 3]; nearestNeighborTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let weights: [Int] = [3]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-417 two vertices, parallel edges: nil (tours read the simple graph): nil")
    func to417() {
        // multigraph V [0, 1]; E [0-1 3, 0-1 4]; nearestNeighborTour(weight:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let weights: [Int] = [3, 4]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-418 empty graph: nil: nil")
    func to418() {
        // V []; E []; nearestNeighborTour(weight:)
        let pairs: [(Int, Int)] = []
        let weights: [Int] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.nearestNeighborTour(weight: { weights[$0] }) == nil)
    }

    @Test("TO-419 square from 2: cycle [2, 1, 0, 3]; edges [3, 0, 2, 5]; weight 4")
    func to419() throws {
        // pts[(0,0),(0,1),(1,1),(1,0)]; nearestNeighborTour(from: 2, weight:)
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
        let result = graph.nearestNeighborTour(from: 2) { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [2, 1, 0, 3] as [Int])
        #expect(tour.edges == [3, 0, 2, 5] as [Int])
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
        // It starts at the given vertex.
        #expect(at[0] == 2)
        let weight = tour.weight({ weights[$0] })
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-420 lcgpts(8,2,20) from 5: cycle [5, 4, 0, 1, 7, 6, 2, 3]; edges [22, 3, 0, 12, 27, 16, 13, 19]; weight 72")
    func to420() throws {
        // lcgpts(8,2,20); nearestNeighborTour(from: 5, weight:)
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
        let result = graph.nearestNeighborTour(from: 5) { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [5, 4, 0, 1, 7, 6, 2, 3] as [Int])
        #expect(tour.edges == [22, 3, 0, 12, 27, 16, 13, 19] as [Int])
        #expect(tour.weight({ weights[$0] }) == 72)
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
        // It starts at the given vertex.
        #expect(at[0] == 5)
        let weight = tour.weight({ weights[$0] })
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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

    @Test("TO-421 lcgK(7,4,9) from 3: cycle [3, 5, 1, 0, 2, 6, 4]; edges [16, 9, 0, 1, 14, 19, 15]; weight 24")
    func to421() throws {
        // lcgK(7,4,9); nearestNeighborTour(from: 3, weight:)
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
        let result = graph.nearestNeighborTour(from: 3) { position in
            asked.append(position)
            return weights[position]
        }
        // `weight` is called once per non-loop edge, in position order.
        #expect(asked == pairs.indices.filter { ends[$0].0 != ends[$0].1 })
        let tour = try #require(result)
        #expect(tour.vertices == [3, 5, 1, 0, 2, 6, 4] as [Int])
        #expect(tour.edges == [16, 9, 0, 1, 14, 19, 15] as [Int])
        #expect(tour.weight({ weights[$0] }) == 24)
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
        // It starts at the given vertex.
        #expect(at[0] == 3)
        let weight = tour.weight({ weights[$0] })
        // The definition, checked here: each step to the nearest unvisited vertex, the first in `vertices`
        // order on ties.
        var visited = [Bool](repeating: false, count: n)
        visited[at[0]] = true
        for i in 1 ..< n {
            let from = at[i - 1]
            let nearest = (0 ..< n).filter { !visited[$0] }.min { d(from, $0) < d(from, $1) }!
            #expect(at[i] == nearest, "step \(i)")
            visited[at[i]] = true
        }
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
}
