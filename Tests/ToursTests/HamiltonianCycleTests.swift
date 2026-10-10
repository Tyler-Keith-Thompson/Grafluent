// `hamiltonianCycle()` (catalog §HamiltonianCycle, §HamiltonianCycleDirected): the first cycle of
// the documented search from the first vertex exactly, a self-loop the cycle of one vertex and two
// parallel (antiparallel) edges that of two; checked here as genuine (every vertex once, no edge
// twice, `Cycle(vertices:edges:in:)` accepting it); on up to 8 vertices, brute force over every
// ordering for existence. Directed rows are `AdjacencyList`, or `DirectedPseudograph` with a
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

@Suite("hamiltonianCycle")
struct HamiltonianCycleTests {
    @Test("TO-291 empty graph: nil")
    func to291() {
        // V []; E []; hamiltonianCycle()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-293 one vertex: nil")
    func to293() {
        // V [0]; E []; hamiltonianCycle()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-295 one vertex with a self-loop: a cycle of length 1: cycle [0]; edges [0]")
    func to295() throws {
        // multigraph V [0]; E [0-0]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0] as [Int])
        #expect(cycle.edges == [0] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-297 two vertices, one edge: a path, no cycle: nil")
    func to297() {
        // V [0, 1]; E [0-1]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-299 two parallel edges: a cycle of length 2: cycle [0, 1]; edges [0, 1]")
    func to299() throws {
        // multigraph V [0, 1]; E [0-1, 1-0]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1] as [Int])
        #expect(cycle.edges == [0, 1] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-301 two isolated vertices: nil")
    func to301() {
        // V [0, 1]; E []; hamiltonianCycle()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-303 self-loops never help: nil")
    func to303() {
        // multigraph V [0, 1, 2]; E [0-0, 0-1, 1-1, 1-2, 2-2]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-305 triangle: cycle [0, 1, 2]; edges [0, 1, 2]")
    func to305() throws {
        // C(3); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2] as [Int])
        #expect(cycle.edges == [0, 1, 2] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-307 path P(5): nil")
    func to307() {
        // P(5); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-309 cycle C(6): cycle [0, 1, 2, 3, 4, 5]; edges [0, 1, 2, 3, 4, 5]")
    func to309() throws {
        // C(6); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(cycle.edges == [0, 1, 2, 3, 4, 5] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-311 star(3): no path: nil")
    func to311() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-313 K(4): cycle [0, 1, 2, 3]; edges [0, 3, 5, 2]")
    func to313() throws {
        // K(4); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3] as [Int])
        #expect(cycle.edges == [0, 3, 5, 2] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-315 K(5): cycle [0, 1, 2, 3, 4]; edges [0, 4, 7, 9, 3]")
    func to315() throws {
        // K(5); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4] as [Int])
        #expect(cycle.edges == [0, 4, 7, 9, 3] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-317 Kb(2,3): a path, no cycle: nil")
    func to317() {
        // Kb(2,3); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-319 Kb(3,3): cycle [0, 3, 1, 4, 2, 5]; edges [0, 3, 4, 7, 8, 2]")
    func to319() throws {
        // Kb(3,3); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 3, 1, 4, 2, 5] as [Int])
        #expect(cycle.edges == [0, 3, 4, 7, 8, 2] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-321 Kb(2,4): no path: nil")
    func to321() {
        // Kb(2,4); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-323 triangle with a pendant: a path, no cycle: nil")
    func to323() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0, 2-3]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-325 two triangles apart: none: nil")
    func to325() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-327 bowtie: a path, no cycle: nil")
    func to327() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-329 vertex order, not label order: cycle [d, b, c, a]; edges [2, 1, 0, 3]")
    func to329() throws {
        // V [d, a, c, b]; E [a-c, c-b, b-d, d-a, a-b]; hamiltonianCycle()
        let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "d"), ("d", "a"), ("a", "b")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == ["d", "b", "c", "a"] as [String])
        #expect(cycle.edges == [2, 1, 0, 3] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-331 parallel copies: the first in the row: cycle [0, 2, 1]; edges [0, 3, 1]")
    func to331() throws {
        // multigraph V [0, 1, 2]; E [0-2, 0-1, 0-1, 1-2, 2-0]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 2), (0, 1), (0, 1), (1, 2), (2, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 2, 1] as [Int])
        #expect(cycle.edges == [0, 3, 1] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-333 rows decide: the first edge of 0 leads to the dead end: cycle [0, 3, 2, 1]; edges [0, 3, 2, 1]")
    func to333() throws {
        // V [0, 1, 2, 3]; E [0-3, 0-1, 1-2, 2-3]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 3, 2, 1] as [Int])
        #expect(cycle.edges == [0, 3, 2, 1] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-335 wheel(5): cycle [0, 1, 2, 3, 4, 5]; edges [0, 5, 6, 7, 8, 4]")
    func to335() throws {
        // wheel(5); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(cycle.edges == [0, 5, 6, 7, 8, 4] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
                joins[b][a] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : n == 2 ? joins[0][1] >= 2 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-337 grid(3,3): a path, no cycle (odd bipartite): nil")
    func to337() {
        // grid(3,3); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-339 grid(3,4): cycle [0, 1, 2, 3, 7, 11, 10, 6, 5, 9, 8, 4]; edges [0, 2, 4, 6, 13, 16, 12, 9, 10, 14, 8, 1]")
    func to339() throws {
        // grid(3,4); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 7, 11, 10, 6, 5, 9, 8, 4] as [Int])
        #expect(cycle.edges == [0, 2, 4, 6, 13, 16, 12, 9, 10, 14, 8, 1] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
    }

    @Test("TO-341 Petersen: a path, no cycle: nil")
    func to341() {
        // nx(petersen_graph); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-343 dodecahedral")
    func to343() throws {
        // nx(dodecahedral_graph); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        #expect(cycle.edges == [0, 3, 5, 7, 9, 11, 13, 14, 16, 17, 19, 20, 22, 24, 25, 26, 27, 28, 29, 1] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
    }

    @Test("TO-345 knight(3,4): open tour: nil")
    func to345() {
        // knight(3,4); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (5, 11), (6, 8), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-347 knight(4,4): no tour at all: nil")
    func to347() {
        // knight(4,4); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (4, 13), (5, 11), (5, 14), (5, 12), (6, 15), (6, 13), (6, 8), (7, 14), (7, 9), (8, 14), (9, 15), (10, 12), (11, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-349 lcg(10,20,1): cycle [0, 2, 5, 1, 4, 3, 6, 9, 8, 7]; edges [3, 8, 18, 14, 0, 19, 4, 9, 11, 17]")
    func to349() throws {
        // lcg(10,20,1); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(4, 3), (6, 0), (4, 5), (0, 2), (9, 6), (3, 2), (4, 2), (0, 5), (2, 5), (9, 8), (1, 8), (7, 8), (8, 5), (6, 8), (1, 4), (6, 4), (1, 0), (7, 0), (1, 5), (3, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 2, 5, 1, 4, 3, 6, 9, 8, 7] as [Int])
        #expect(cycle.edges == [3, 8, 18, 14, 0, 19, 4, 9, 11, 17] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
    }

    @Test("TO-351 lcg(12,30,2): cycle [0, 8, 2, 11, 7, 1, 3, 6, 10, 9, 5, 4]; edges [1, 7, 4, 10, 19, 12, 22, 27, 11, 28, 13, 14]")
    func to351() throws {
        // lcg(12,30,2); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(4, 6), (0, 8), (0, 6), (9, 2), (11, 2), (6, 5), (2, 7), (8, 2), (1, 6), (11, 6), (11, 7), (9, 10), (3, 1), (5, 4), (0, 4), (3, 8), (4, 8), (8, 11), (10, 2), (7, 1), (6, 8), (8, 9), (6, 3), (2, 5), (1, 8), (6, 9), (2, 6), (6, 10), (5, 9), (7, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 8, 2, 11, 7, 1, 3, 6, 10, 9, 5, 4] as [Int])
        #expect(cycle.edges == [1, 7, 4, 10, 19, 12, 22, 27, 11, 28, 13, 14] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
    }

    @Test("TO-353 lcg(14,22,3): sparse: nil")
    func to353() {
        // lcg(14,22,3); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(3, 13), (13, 2), (8, 3), (1, 11), (5, 0), (12, 3), (8, 11), (13, 1), (11, 4), (1, 4), (9, 7), (9, 5), (11, 2), (9, 0), (3, 9), (5, 8), (7, 11), (4, 9), (10, 7), (5, 2), (5, 11), (5, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-355 empty digraph: nil")
    func to355() {
        // V []; E []; hamiltonianCycle()
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-357 one vertex with a self-loop: cycle [0]; edges [0]")
    func to357() throws {
        // multigraph V [0]; E [0→0]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0] as [Int])
        #expect(cycle.edges == [0] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-359 one edge 0→1: a path, no cycle: nil")
    func to359() {
        // V [0, 1]; E [0→1]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-361 antiparallel pair: a cycle of length 2: cycle [0, 1]; edges [0, 1]")
    func to361() throws {
        // V [0, 1]; E [0→1, 1→0]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1] as [Int])
        #expect(cycle.edges == [0, 1] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-363 edge 1→0 only: the path starts at 1: nil")
    func to363() {
        // V [0, 1]; E [1→0]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-365 directed cycle Cd(4): cycle [0, 1, 2, 3]; edges [0, 1, 2, 3]")
    func to365() throws {
        // Cd(4); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3] as [Int])
        #expect(cycle.edges == [0, 1, 2, 3] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-367 directed path Pd(4): nil")
    func to367() {
        // Pd(4); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-369 two sinks: no path: nil")
    func to369() {
        // V [0, 1, 2]; E [0→1, 0→2]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-371 Kd(4): cycle [0, 1, 2, 3]; edges [0, 4, 8, 9]")
    func to371() throws {
        // Kd(4); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3] as [Int])
        #expect(cycle.edges == [0, 4, 8, 9] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-373 transitive tournament: one path, no cycle: nil")
    func to373() {
        // V [0, 1, 2, 3]; E [0→1, 0→2, 0→3, 1→2, 1→3, 2→3]; hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianCycle() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(!exists)
    }

    @Test("TO-375 tournament(6,1): cycle [0, 3, 5, 1, 4, 2]; edges [2, 13, 8, 7, 10, 1]")
    func to375() throws {
        // tournament(6,1); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 3, 5, 1, 4, 2] as [Int])
        #expect(cycle.edges == [2, 13, 8, 7, 10, 1] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-377 tournament(8,2): cycle [0, 1, 2, 3, 4, 6, 7, 5]; edges [0, 7, 13, 18, 23, 27, 26, 4]")
    func to377() throws {
        // tournament(8,2); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (5, 0), (6, 0), (0, 7), (1, 2), (3, 1), (1, 4), (5, 1), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (7, 2), (3, 4), (5, 3), (3, 6), (3, 7), (4, 5), (4, 6), (7, 4), (5, 6), (7, 5), (6, 7)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 1, 2, 3, 4, 6, 7, 5] as [Int])
        #expect(cycle.edges == [0, 7, 13, 18, 23, 27, 26, 4] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next (and back to the first; a self-loop is the cycle of one vertex, two edges that of two).
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        var loops = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            if a == b {
                loops[a] += 1
            } else {
                joins[a][b] += 1
            }
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if n == 1 ? loops[0] > 0 : (0 ..< n).allSatisfy({ joins[order[$0]][order[($0 + 1) % n]] > 0 }) {
                exists = true
                break
            }
            // The next permutation, in lexicographic order.
            var i = n - 2
            while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
            if i < 0 { break }
            var j = n - 1
            while order[j] <= order[i] { j -= 1 }
            order.swapAt(i, j)
            order[(i + 1)...].reverse()
        }
        #expect(exists)
    }

    @Test("TO-379 lcgd(9,25,1): nil")
    func to379() {
        // lcgd(9,25,1); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(5, 3), (0, 8), (5, 7), (3, 4), (3, 7), (5, 4), (1, 8), (7, 6), (1, 4), (8, 0), (3, 2), (6, 2), (2, 1), (3, 8), (0, 7), (4, 7), (2, 4), (6, 4), (3, 6), (2, 7), (8, 7), (7, 5), (5, 1), (7, 4), (3, 5)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianCycle() == nil)
    }

    @Test("TO-381 lcgd(10,40,2): cycle [0, 2, 8, 3, 6, 5, 9, 7, 4, 1]; edges [0, 7, 29, 12, 6, 2, 23, 13, 25, 20]")
    func to381() throws {
        // lcgd(10,40,2); hamiltonianCycle()
        let pairs: [(Int, Int)] = [(0, 2), (6, 4), (5, 9), (5, 2), (3, 2), (4, 3), (6, 5), (2, 8), (5, 6), (9, 2), (3, 7), (8, 2), (3, 6), (7, 4), (5, 3), (0, 6), (7, 5), (6, 0), (0, 7), (6, 1), (1, 0), (2, 6), (2, 9), (9, 7), (0, 3), (4, 1), (0, 4), (7, 6), (4, 8), (8, 3), (0, 8), (1, 3), (9, 5), (9, 8), (3, 8), (2, 7), (6, 7), (7, 8), (8, 6), (6, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cycle = try #require(graph.hamiltonianCycle())
        #expect(cycle.vertices == [0, 2, 8, 3, 6, 5, 9, 7, 4, 1] as [Int])
        #expect(cycle.edges == [0, 7, 29, 12, 6, 2, 23, 13, 25, 20] as [Int])
        let walked = cycle.edges
        let at = cycle.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next (the last back to the first), no edge twice.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % n]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
        // The search starts at the first vertex.
        #expect(at[0] == 0)
    }
}
