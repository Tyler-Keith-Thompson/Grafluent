// `hasEulerianTrail` (catalog §HasEulerianTrail, §HasEulerianTrailDirected): exact; the definition
// checked in each test (no odd vertex or exactly two; balanced, or one vertex with out − in = 1 and
// one with in − out = 1), with the same component rule and the same relations to the walks. Directed
// rows are `AdjacencyList`, or `DirectedPseudograph` with a self-loop or a repeated edge; undirected
// rows `UndirectedAdjacencyList`, or `Pseudograph` with a self-loop or parallel edges; each built by
// inserting the row's vertices, then its edges in order, so positions are the catalog's. In-test
// checks number vertices by their index in `vertices`. Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's models; see README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Testing
import Tours

@Suite("hasEulerianTrail")
struct HasEulerianTrailTests {
    @Test("TO-002 empty graph: true")
    func to002() {
        // V []; E []; hasEulerianTrail
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-006 one vertex: true")
    func to006() {
        // V [0]; E []; hasEulerianTrail
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-010 two isolated vertices (isolated vertices ignored): true")
    func to010() {
        // V [0, 1]; E []; hasEulerianTrail
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-014 one self-loop: true")
    func to014() {
        // multigraph V [0]; E [0-0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-018 two self-loops at one vertex: true")
    func to018() {
        // multigraph V [0]; E [0-0, 0-0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-022 self-loop beside an isolated vertex: true")
    func to022() {
        // multigraph V [0, 1]; E [1-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-026 self-loops at two vertices: two components with edges: false")
    func to026() {
        // multigraph V [0, 1]; E [0-0, 1-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-030 one edge: a trail, no circuit: true")
    func to030() {
        // V [0, 1]; E [0-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-034 two parallel edges: a circuit of length 2: true")
    func to034() {
        // multigraph V [0, 1]; E [0-1, 0-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-038 three parallel edges: odd at both ends: true")
    func to038() {
        // multigraph V [0, 1]; E [0-1, 1-0, 0-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-042 path P(3): true")
    func to042() {
        // P(3); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-046 path P(4): true")
    func to046() {
        // P(4); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-050 triangle C(3): true")
    func to050() {
        // C(3); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-054 cycle C(5): true")
    func to054() {
        // C(5); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-058 triangle beside an isolated vertex: true")
    func to058() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-062 isolated first vertex: the circuit starts at the first vertex with an edge: true")
    func to062() {
        // V [0, 1, 2, 3]; E [1-2, 2-3, 3-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-066 two triangles apart: false")
    func to066() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-070 bowtie: two triangles at a shared vertex: true")
    func to070() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-074 triangle with a loop: loops add 2: true")
    func to074() {
        // multigraph V [0, 1, 2]; E [0-1, 0-0, 1-2, 2-0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-078 edge with a loop at the end: odd 0 and 1: true")
    func to078() {
        // multigraph V [0, 1]; E [0-1, 1-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-082 loop at a vertex, an edge elsewhere: two components: false")
    func to082() {
        // multigraph V [0, 1, 2]; E [0-0, 1-2]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-086 star(3): four odd vertices: false")
    func to086() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-090 K(4): every degree 3: false")
    func to090() {
        // K(4); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-094 K(5): every degree 4: true")
    func to094() {
        // K(5); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-098 Königsberg: seven bridges, four odd land masses: false")
    func to098() {
        // multigraph V [A, B, C, D]; E [A-B, A-B, A-C, A-C, A-D, B-D, C-D]; hasEulerianTrail
        let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-102 Königsberg less one A–B bridge: a trail: true")
    func to102() {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; hasEulerianTrail
        let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-106 house: odd at the base: true")
    func to106() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-0, 2-4, 4-3]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-110 vertex order, not label order: true")
    func to110() {
        // V [d, a, c, b]; E [a-c, c-b, b-a, d-a, d-c]; hasEulerianTrail
        let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-114 odd vertices last in the order: true")
    func to114() {
        // V [0, 1, 2, 3, 4]; E [4-3, 3-0, 0-1, 1-2, 2-0, 0-4, 4-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-118 grid(3,3): four odd corners' neighbours: false")
    func to118() {
        // grid(3,3); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-122 Petersen: every degree 3: false")
    func to122() {
        // nx(petersen_graph); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-126 octahedral: every degree 4: true")
    func to126() {
        // nx(octahedral_graph); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-130 wheel(4): rim odd: false")
    func to130() {
        // wheel(4); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-134 K(3,3) less nothing: degree 3: false")
    func to134() {
        // Kb(3,3); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-138 Kb(2,4): even sides: true")
    func to138() {
        // Kb(2,4); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-142 rows decide: the first edge out of 0 is the second chord: true")
    func to142() {
        // V [0, 1, 2, 3, 4]; E [0-3, 0-1, 1-2, 2-0, 3-4, 4-0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-146 parallel edges inside a longer circuit: true")
    func to146() {
        // multigraph V [0, 1, 2]; E [0-1, 1-2, 1-2, 1-2, 2-0, 1-1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-150 lcgwalk(6,14,1): true")
    func to150() {
        // lcgwalk(6,14,1); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-154 lcgwalk(8,30,2): true")
    func to154() {
        // lcgwalk(8,30,2); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-158 lcgwalk(5,20,3,open): true")
    func to158() {
        // lcgwalk(5,20,3,open); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-162 lcgwalk(10,40,4,open): true")
    func to162() {
        // lcgwalk(10,40,4,open); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop adds 2.
        var degree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            degree[a] += 1
            degree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
        // The definitions (api.md): no odd vertex, or exactly two; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && odd.isEmpty))
        #expect(graph.hasEulerianTrail == (components <= 1 && (odd.isEmpty || odd.count == 2)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-166 empty digraph: true")
    func to166() {
        // V []; E []; hasEulerianTrail
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-170 one vertex: true")
    func to170() {
        // V [0]; E []; hasEulerianTrail
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-174 one self-loop: in 1, out 1: true")
    func to174() {
        // multigraph V [0]; E [0→0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-178 one edge 0→1: true")
    func to178() {
        // V [0, 1]; E [0→1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-182 antiparallel pair: true")
    func to182() {
        // V [0, 1]; E [0→1, 1→0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-186 parallel pair 0→1 twice: unbalanced by 2: false")
    func to186() {
        // multigraph V [0, 1]; E [0→1, 0→1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-190 directed cycle Cd(3): true")
    func to190() {
        // Cd(3); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-194 directed path Pd(4): true")
    func to194() {
        // Pd(4); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-198 two sources: no trail: false")
    func to198() {
        // V [0, 1, 2]; E [0→2, 1→2]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-202 balanced but two components: false")
    func to202() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→3, 3→2]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-206 Cd(3) beside an isolated vertex: true")
    func to206() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-210 isolated first vertex: true")
    func to210() {
        // V [0, 1, 2, 3]; E [1→2, 2→3, 3→1]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-214 start is the vertex with out − in = 1, not the first: true")
    func to214() {
        // V [0, 1, 2, 3]; E [1→2, 2→0, 0→1, 2→3, 3→1, 1→3]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-218 two directed cycles at a shared vertex: true")
    func to218() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-222 loop on a directed cycle: true")
    func to222() {
        // multigraph V [0, 1, 2]; E [0→1, 1→1, 1→2, 2→0]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-226 Cd(3) with a chord: a trail from 0: true")
    func to226() {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-230 in − out = 2 at one vertex: false")
    func to230() {
        // multigraph V [0, 1, 2]; E [0→2, 1→2, 2→1, 1→0, 0→2]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-234 Kd(3): every in = out = 2: true")
    func to234() {
        // Kd(3); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-238 Kd(4): true")
    func to238() {
        // Kd(4); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-242 self-loop and an edge elsewhere: false")
    func to242() {
        // multigraph V [0, 1, 2]; E [0→0, 1→2]; hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == false)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-246 lcgwalkd(6,14,1): true")
    func to246() {
        // lcgwalkd(6,14,1); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-250 lcgwalkd(8,30,2): true")
    func to250() {
        // lcgwalkd(8,30,2); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-254 lcgwalkd(5,20,3,open): true")
    func to254() {
        // lcgwalkd(5,20,3,open); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }

    @Test("TO-258 lcgwalkd(9,40,5,open): true")
    func to258() {
        // lcgwalkd(9,40,5,open); hasEulerianTrail
        let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.hasEulerianTrail == true)
        // Degrees, counted here: a self-loop is one edge out and one in.
        var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
        for (a, b) in ends {
            outDegree[a] += 1
            inDegree[b] += 1
        }
        // The vertices with edges in one (weakly) connected component: union–find over the edges.
        var parent = Array(0 ..< n)
        func root(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { x = parent[x] }
            return x
        }
        for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
        let components = Set(ends.map { root($0.0) }).count
        let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
        let balanced = surplus.allSatisfy { $0 == 0 }
        let oneEach = surplus.filter { $0 == 1 }.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
        // The definitions (api.md): balanced, or one vertex out − in = 1 and one in − out = 1; isolated vertices ignored.
        #expect(graph.isEulerian == (components <= 1 && balanced))
        #expect(graph.hasEulerianTrail == (components <= 1 && (balanced || oneEach)))
        // And as api.md relates them to the walks.
        #expect(graph.isEulerian == (graph.eulerianCircuit() != nil || pairs.isEmpty))
        #expect(graph.hasEulerianTrail == (graph.eulerianTrail() != nil || n == 0))
    }
}
