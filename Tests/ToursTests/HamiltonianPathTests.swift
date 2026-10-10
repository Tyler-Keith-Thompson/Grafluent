// `hamiltonianPath()`, `hamiltonianPath(from:)` and `hamiltonianPath(from:to:)` (catalog
// §HamiltonianPath, §HamiltonianPathDirected, §HamiltonianPathFrom, §HamiltonianPathFromDirected):
// the first path of the documented depth-first search exactly; checked here as genuine (every vertex
// once, consecutive edges, `Path(vertices:edges:in:)` accepting it) with its ends; on up to 8
// vertices, brute force over every ordering of the vertices for existence and for the first vertex
// any path starts from. Directed rows are `AdjacencyList`, or `DirectedPseudograph` with a self-loop
// or a repeated edge; undirected rows `UndirectedAdjacencyList`, or `Pseudograph` with a self-loop
// or parallel edges; each built by inserting the row's vertices, then its edges in order, so
// positions are the catalog's. In-test checks number vertices by their index in `vertices`.
// Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's models; see
// README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Testing
import Tours
import Walks

@Suite("hamiltonianPath")
struct HamiltonianPathTests {
    @Test("TO-290 empty graph: nil")
    func to290() {
        // V []; E []; hamiltonianPath()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianPath() == nil)
    }

    @Test("TO-292 one vertex: path [0]; edges []")
    func to292() throws {
        // V [0]; E []; hamiltonianPath()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0] as [Int])
        #expect(path.edges == [] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-294 one vertex with a self-loop: a cycle of length 1: path [0]; edges []")
    func to294() throws {
        // multigraph V [0]; E [0-0]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0] as [Int])
        #expect(path.edges == [] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-296 two vertices, one edge: a path, no cycle: path [0, 1]; edges [0]")
    func to296() throws {
        // V [0, 1]; E [0-1]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1] as [Int])
        #expect(path.edges == [0] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-298 two parallel edges: a cycle of length 2: path [0, 1]; edges [0]")
    func to298() throws {
        // multigraph V [0, 1]; E [0-1, 1-0]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1] as [Int])
        #expect(path.edges == [0] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-300 two isolated vertices: nil")
    func to300() {
        // V [0, 1]; E []; hamiltonianPath()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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

    @Test("TO-302 self-loops never help: path [0, 1, 2]; edges [1, 3]")
    func to302() throws {
        // multigraph V [0, 1, 2]; E [0-0, 0-1, 1-1, 1-2, 2-2]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2] as [Int])
        #expect(path.edges == [1, 3] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-304 triangle: path [0, 1, 2]; edges [0, 1]")
    func to304() throws {
        // C(3); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2] as [Int])
        #expect(path.edges == [0, 1] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-306 path P(5): path [0, 1, 2, 3, 4]; edges [0, 1, 2, 3]")
    func to306() throws {
        // P(5); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
        #expect(path.edges == [0, 1, 2, 3] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-308 cycle C(6): path [0, 1, 2, 3, 4, 5]; edges [0, 1, 2, 3, 4]")
    func to308() throws {
        // C(6); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(path.edges == [0, 1, 2, 3, 4] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-310 star(3): no path: nil")
    func to310() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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

    @Test("TO-312 K(4): path [0, 1, 2, 3]; edges [0, 3, 5]")
    func to312() throws {
        // K(4); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3] as [Int])
        #expect(path.edges == [0, 3, 5] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-314 K(5): path [0, 1, 2, 3, 4]; edges [0, 4, 7, 9]")
    func to314() throws {
        // K(5); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
        #expect(path.edges == [0, 4, 7, 9] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-316 Kb(2,3): a path, no cycle: path [2, 0, 3, 1, 4]; edges [0, 1, 4, 5]")
    func to316() throws {
        // Kb(2,3); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [2, 0, 3, 1, 4] as [Int])
        #expect(path.edges == [0, 1, 4, 5] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 2)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-318 Kb(3,3): path [0, 3, 1, 4, 2, 5]; edges [0, 3, 4, 7, 8]")
    func to318() throws {
        // Kb(3,3); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 3, 1, 4, 2, 5] as [Int])
        #expect(path.edges == [0, 3, 4, 7, 8] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-320 Kb(2,4): no path: nil")
    func to320() {
        // Kb(2,4); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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

    @Test("TO-322 triangle with a pendant: a path, no cycle: path [0, 1, 2, 3]; edges [0, 1, 3]")
    func to322() throws {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0, 2-3]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3] as [Int])
        #expect(path.edges == [0, 1, 3] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-324 two triangles apart: none: nil")
    func to324() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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

    @Test("TO-326 bowtie: a path, no cycle: path [0, 1, 2, 3, 4]; edges [0, 1, 3, 4]")
    func to326() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 4] as [Int])
        #expect(path.edges == [0, 1, 3, 4] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-328 vertex order, not label order: path [d, b, c, a]; edges [2, 1, 0]")
    func to328() throws {
        // V [d, a, c, b]; E [a-c, c-b, b-d, d-a, a-b]; hamiltonianPath()
        let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "d"), ("d", "a"), ("a", "b")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == ["d", "b", "c", "a"] as [String])
        #expect(path.edges == [2, 1, 0] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-330 parallel copies: the first in the row: path [0, 2, 1]; edges [0, 3]")
    func to330() throws {
        // multigraph V [0, 1, 2]; E [0-2, 0-1, 0-1, 1-2, 2-0]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 2), (0, 1), (0, 1), (1, 2), (2, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 2, 1] as [Int])
        #expect(path.edges == [0, 3] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-332 rows decide: the first edge of 0 leads to the dead end: path [0, 3, 2, 1]; edges [0, 3, 2]")
    func to332() throws {
        // V [0, 1, 2, 3]; E [0-3, 0-1, 1-2, 2-3]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 3, 2, 1] as [Int])
        #expect(path.edges == [0, 3, 2] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-334 wheel(5): path [0, 1, 2, 3, 4, 5]; edges [0, 5, 6, 7, 8]")
    func to334() throws {
        // wheel(5); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(path.edges == [0, 5, 6, 7, 8] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-336 grid(3,3): a path, no cycle (odd bipartite): path [0, 1, 2, 5, 4, 3, 6, 7, 8]; edges [0, 2, 4, 7, 5, 6, 10, 11]")
    func to336() throws {
        // grid(3,3); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 5, 4, 3, 6, 7, 8] as [Int])
        #expect(path.edges == [0, 2, 4, 7, 5, 6, 10, 11] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-338 grid(3,4): path [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11]; edges [0, 2, 4, 6, 11, 9, 7, 8, 14, 15, 16]")
    func to338() throws {
        // grid(3,4); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11] as [Int])
        #expect(path.edges == [0, 2, 4, 6, 11, 9, 7, 8, 14, 15, 16] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-340 Petersen: a path, no cycle: path [0, 1, 2, 3, 4, 9, 6, 8, 5, 7]; edges [0, 3, 5, 7, 9, 13, 12, 11, 10]")
    func to340() throws {
        // nx(petersen_graph); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 4, 9, 6, 8, 5, 7] as [Int])
        #expect(path.edges == [0, 3, 5, 7, 9, 13, 12, 11, 10] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-342 dodecahedral")
    func to342() throws {
        // nx(dodecahedral_graph); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        #expect(path.edges == [0, 3, 5, 7, 9, 11, 13, 14, 16, 17, 19, 20, 22, 24, 25, 26, 27, 28, 29] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-344 knight(3,4): open tour")
    func to344() throws {
        // knight(3,4); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (5, 11), (6, 8), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 6, 8, 1, 7, 9, 2, 11, 5, 3, 10, 4] as [Int])
        #expect(path.edges == [0, 12, 4, 2, 13, 6, 5, 11, 9, 8, 10] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-346 knight(4,4): no tour at all: nil")
    func to346() {
        // knight(4,4); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 6), (0, 9), (1, 7), (1, 10), (1, 8), (2, 11), (2, 9), (2, 4), (3, 10), (3, 5), (4, 10), (4, 13), (5, 11), (5, 14), (5, 12), (6, 15), (6, 13), (6, 8), (7, 14), (7, 9), (8, 14), (9, 15), (10, 12), (11, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianPath() == nil)
    }

    @Test("TO-348 lcg(10,20,1): path [0, 2, 5, 1, 4, 3, 6, 9, 8, 7]; edges [3, 8, 18, 14, 0, 19, 4, 9, 11]")
    func to348() throws {
        // lcg(10,20,1); hamiltonianPath()
        let pairs: [(Int, Int)] = [(4, 3), (6, 0), (4, 5), (0, 2), (9, 6), (3, 2), (4, 2), (0, 5), (2, 5), (9, 8), (1, 8), (7, 8), (8, 5), (6, 8), (1, 4), (6, 4), (1, 0), (7, 0), (1, 5), (3, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 2, 5, 1, 4, 3, 6, 9, 8, 7] as [Int])
        #expect(path.edges == [3, 8, 18, 14, 0, 19, 4, 9, 11] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-350 lcg(12,30,2): path [0, 8, 2, 11, 7, 1, 3, 6, 4, 5, 9, 10]; edges [1, 7, 4, 10, 19, 12, 22, 0, 13, 28, 11]")
    func to350() throws {
        // lcg(12,30,2); hamiltonianPath()
        let pairs: [(Int, Int)] = [(4, 6), (0, 8), (0, 6), (9, 2), (11, 2), (6, 5), (2, 7), (8, 2), (1, 6), (11, 6), (11, 7), (9, 10), (3, 1), (5, 4), (0, 4), (3, 8), (4, 8), (8, 11), (10, 2), (7, 1), (6, 8), (8, 9), (6, 3), (2, 5), (1, 8), (6, 9), (2, 6), (6, 10), (5, 9), (7, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 8, 2, 11, 7, 1, 3, 6, 4, 5, 9, 10] as [Int])
        #expect(path.edges == [1, 7, 4, 10, 19, 12, 22, 0, 13, 28, 11] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-352 lcg(14,22,3): sparse: nil")
    func to352() {
        // lcg(14,22,3); hamiltonianPath()
        let pairs: [(Int, Int)] = [(3, 13), (13, 2), (8, 3), (1, 11), (5, 0), (12, 3), (8, 11), (13, 1), (11, 4), (1, 4), (9, 7), (9, 5), (11, 2), (9, 0), (3, 9), (5, 8), (7, 11), (4, 9), (10, 7), (5, 2), (5, 11), (5, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianPath() == nil)
    }

    @Test("TO-354 empty digraph: nil")
    func to354() {
        // V []; E []; hamiltonianPath()
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianPath() == nil)
    }

    @Test("TO-356 one vertex with a self-loop: path [0]; edges []")
    func to356() throws {
        // multigraph V [0]; E [0→0]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0] as [Int])
        #expect(path.edges == [] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-358 one edge 0→1: a path, no cycle: path [0, 1]; edges [0]")
    func to358() throws {
        // V [0, 1]; E [0→1]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1] as [Int])
        #expect(path.edges == [0] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-360 antiparallel pair: a cycle of length 2: path [0, 1]; edges [0]")
    func to360() throws {
        // V [0, 1]; E [0→1, 1→0]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1] as [Int])
        #expect(path.edges == [0] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-362 edge 1→0 only: the path starts at 1: path [1, 0]; edges [0]")
    func to362() throws {
        // V [0, 1]; E [1→0]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [1, 0] as [Int])
        #expect(path.edges == [0] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 1)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-364 directed cycle Cd(4): path [0, 1, 2, 3]; edges [0, 1, 2]")
    func to364() throws {
        // Cd(4); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3] as [Int])
        #expect(path.edges == [0, 1, 2] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-366 directed path Pd(4): path [0, 1, 2, 3]; edges [0, 1, 2]")
    func to366() throws {
        // Pd(4); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3] as [Int])
        #expect(path.edges == [0, 1, 2] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-368 two sinks: no path: nil")
    func to368() {
        // V [0, 1, 2]; E [0→1, 0→2]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath() == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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

    @Test("TO-370 Kd(4): path [0, 1, 2, 3]; edges [0, 4, 8]")
    func to370() throws {
        // Kd(4); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3] as [Int])
        #expect(path.edges == [0, 4, 8] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-372 transitive tournament: one path, no cycle: path [0, 1, 2, 3]; edges [0, 3, 5]")
    func to372() throws {
        // V [0, 1, 2, 3]; E [0→1, 0→2, 0→3, 1→2, 1→3, 2→3]; hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3] as [Int])
        #expect(path.edges == [0, 3, 5] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-374 tournament(6,1): path [0, 1, 3, 4, 2, 5]; edges [0, 6, 12, 10, 11]")
    func to374() throws {
        // tournament(6,1); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (2, 0), (0, 3), (0, 4), (0, 5), (2, 1), (1, 3), (1, 4), (5, 1), (2, 3), (4, 2), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 3, 4, 2, 5] as [Int])
        #expect(path.edges == [0, 6, 12, 10, 11] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-376 tournament(8,2): path [0, 1, 2, 3, 4, 5, 6, 7]; edges [0, 7, 13, 18, 22, 25, 27]")
    func to376() throws {
        // tournament(8,2); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (5, 0), (6, 0), (0, 7), (1, 2), (3, 1), (1, 4), (5, 1), (1, 6), (1, 7), (2, 3), (2, 4), (2, 5), (2, 6), (7, 2), (3, 4), (5, 3), (3, 6), (3, 7), (4, 5), (4, 6), (7, 4), (5, 6), (7, 5), (6, 7)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(path.edges == [0, 7, 13, 18, 22, 25, 27] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        var firstStart = n
        while true {
            if (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
                exists = true
                firstStart = min(firstStart, order[0])
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
        #expect(at[0] == firstStart)
    }

    @Test("TO-378 lcgd(9,25,1): path [0, 8, 7, 5, 3, 6, 2, 1, 4]; edges [1, 20, 21, 0, 18, 11, 12, 8]")
    func to378() throws {
        // lcgd(9,25,1); hamiltonianPath()
        let pairs: [(Int, Int)] = [(5, 3), (0, 8), (5, 7), (3, 4), (3, 7), (5, 4), (1, 8), (7, 6), (1, 4), (8, 0), (3, 2), (6, 2), (2, 1), (3, 8), (0, 7), (4, 7), (2, 4), (6, 4), (3, 6), (2, 7), (8, 7), (7, 5), (5, 1), (7, 4), (3, 5)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 8, 7, 5, 3, 6, 2, 1, 4] as [Int])
        #expect(path.edges == [1, 20, 21, 0, 18, 11, 12, 8] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-380 lcgd(10,40,2): path [0, 2, 8, 3, 6, 5, 9, 7, 4, 1]; edges [0, 7, 29, 12, 6, 2, 23, 13, 25]")
    func to380() throws {
        // lcgd(10,40,2); hamiltonianPath()
        let pairs: [(Int, Int)] = [(0, 2), (6, 4), (5, 9), (5, 2), (3, 2), (4, 3), (6, 5), (2, 8), (5, 6), (9, 2), (3, 7), (8, 2), (3, 6), (7, 4), (5, 3), (0, 6), (7, 5), (6, 0), (0, 7), (6, 1), (1, 0), (2, 6), (2, 9), (9, 7), (0, 3), (4, 1), (0, 4), (7, 6), (4, 8), (8, 3), (0, 8), (1, 3), (9, 5), (9, 8), (3, 8), (2, 7), (6, 7), (7, 8), (8, 6), (6, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath())
        #expect(path.vertices == [0, 2, 8, 3, 6, 5, 9, 7, 4, 1] as [Int])
        #expect(path.edges == [0, 7, 29, 12, 6, 2, 23, 13, 25] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // The first vertex from which some Hamiltonian path starts.
        #expect(at[0] == 0)
    }

    @Test("TO-382 P(3) from 0: path [0, 1, 2]; edges [0, 1]")
    func to382() throws {
        // P(3); hamiltonianPath(from: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 0))
        #expect(path.vertices == [0, 1, 2] as [Int])
        #expect(path.edges == [0, 1] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[0] == 0 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-383 P(3) from 1: nil")
    func to383() {
        // P(3); hamiltonianPath(from: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath(from: 1) == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[0] == 1 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-384 P(3) from 2: path [2, 1, 0]; edges [1, 0]")
    func to384() throws {
        // P(3); hamiltonianPath(from: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 2))
        #expect(path.vertices == [2, 1, 0] as [Int])
        #expect(path.edges == [1, 0] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 2)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[0] == 2 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-385 C(5) from 2: path [2, 1, 0, 4, 3]; edges [1, 0, 4, 3]")
    func to385() throws {
        // C(5); hamiltonianPath(from: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 2))
        #expect(path.vertices == [2, 1, 0, 4, 3] as [Int])
        #expect(path.edges == [1, 0, 4, 3] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 2)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[0] == 2 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-386 Petersen from 4: path [4, 0, 1, 2, 3, 8, 5, 7, 9, 6]; edges [1, 0, 3, 5, 8, 11, 10, 14, 13]")
    func to386() throws {
        // nx(petersen_graph); hamiltonianPath(from: 4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 4))
        #expect(path.vertices == [4, 0, 1, 2, 3, 8, 5, 7, 9, 6] as [Int])
        #expect(path.edges == [1, 0, 3, 5, 8, 11, 10, 14, 13] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 4)
    }

    @Test("TO-387 P(4) from 0 to 3: path [0, 1, 2, 3]; edges [0, 1, 2]")
    func to387() throws {
        // P(4); hamiltonianPath(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 0, to: 3))
        #expect(path.vertices == [0, 1, 2, 3] as [Int])
        #expect(path.edges == [0, 1, 2] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 0)
        // To the given end.
        #expect(at[n - 1] == 3)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[n - 1] == 3 && order[0] == 0 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-388 P(4) from 0 to 2: nil: nil")
    func to388() {
        // P(4); hamiltonianPath(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath(from: 0, to: 2) == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[n - 1] == 2 && order[0] == 0 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-389 K(4) from 1 to 0: path [1, 2, 3, 0]; edges [3, 5, 2]")
    func to389() throws {
        // K(4); hamiltonianPath(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 1, to: 0))
        #expect(path.vertices == [1, 2, 3, 0] as [Int])
        #expect(path.edges == [3, 5, 2] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 1)
        // To the given end.
        #expect(at[n - 1] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[n - 1] == 0 && order[0] == 1 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-390 one vertex from 0 to 0: the trivial path: path [0]; edges []")
    func to390() throws {
        // V [0]; E []; hamiltonianPath(from: 0, to: 0)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 0, to: 0))
        #expect(path.vertices == [0] as [Int])
        #expect(path.edges == [] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 0)
        // To the given end.
        #expect(at[n - 1] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[n - 1] == 0 && order[0] == 0 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-391 same ends, two vertices: nil: nil")
    func to391() {
        // P(2); hamiltonianPath(from: 0, to: 0)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath(from: 0, to: 0) == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
            joins[b][a] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[n - 1] == 0 && order[0] == 0 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-392 grid(3,3) from corner to corner: path [0, 1, 2, 5, 4, 3, 6, 7, 8]; edges [0, 2, 4, 7, 5, 6, 10, 11]")
    func to392() throws {
        // grid(3,3); hamiltonianPath(from: 0, to: 8)
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 0, to: 8))
        #expect(path.vertices == [0, 1, 2, 5, 4, 3, 6, 7, 8] as [Int])
        #expect(path.edges == [0, 2, 4, 7, 5, 6, 10, 11] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 0)
        // To the given end.
        #expect(at[n - 1] == 8)
    }

    @Test("TO-393 grid(3,3) from corner to an edge midpoint: nil (parity): nil")
    func to393() {
        // grid(3,3); hamiltonianPath(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.hamiltonianPath(from: 0, to: 1) == nil)
    }

    @Test("TO-394 Pd(3) from 0: path [0, 1, 2]; edges [0, 1]")
    func to394() throws {
        // Pd(3); hamiltonianPath(from: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 0))
        #expect(path.vertices == [0, 1, 2] as [Int])
        #expect(path.edges == [0, 1] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 0)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[0] == 0 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-395 Pd(3) from 1: nil: nil")
    func to395() {
        // Pd(3); hamiltonianPath(from: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hamiltonianPath(from: 1) == nil)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[0] == 1 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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

    @Test("TO-396 Kd(4) from 3 to 2: path [3, 0, 1, 2]; edges [9, 0, 4]")
    func to396() throws {
        // Kd(4); hamiltonianPath(from: 3, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let path = try #require(graph.hamiltonianPath(from: 3, to: 2))
        #expect(path.vertices == [3, 0, 1, 2] as [Int])
        #expect(path.edges == [9, 0, 4] as [Int])
        let walked = path.edges
        let at = path.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every vertex exactly once, edge i joining vertex i and the next.
        #expect(at.sorted() == Array(0 ..< n))
        #expect(walked.count == n - 1 && Set(walked).count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Path(vertices: path.vertices, edges: path.edges, in: graph) != nil)
        // From the given start.
        #expect(at[0] == 3)
        // To the given end.
        #expect(at[n - 1] == 2)
        // Brute force, checked here: some ordering of the vertices with an edge from each to the next.
        var joins = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
        for (a, b) in ends where a != b {
            joins[a][b] += 1
        }
        var order = Array(0 ..< n)
        var exists = false
        while true {
            if order[n - 1] == 2 && order[0] == 3 && (0 ..< n - 1).allSatisfy({ joins[order[$0]][order[$0 + 1]] > 0 }) {
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
}
