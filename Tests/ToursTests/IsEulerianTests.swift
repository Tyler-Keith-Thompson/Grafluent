// `isEulerian` (catalog §IsEulerian, §IsEulerianDirected): exact; the definition checked in each
// test (degrees, a self-loop counting 2 or one in and one out, and the vertices with edges in one
// component by union–find; isolated vertices ignored; every edgeless graph Eulerian); `isEulerian`
// exactly when `eulerianCircuit()` is not nil or there are no edges, `hasEulerianTrail` exactly when
// `eulerianTrail()` is not nil or there is no vertex. Directed rows are `AdjacencyList`, or
// `DirectedPseudograph` with a self-loop or a repeated edge; undirected rows
// `UndirectedAdjacencyList`, or `Pseudograph` with a self-loop or parallel edges; each built by
// inserting the row's vertices, then its edges in order, so positions are the catalog's. In-test
// checks number vertices by their index in `vertices`. Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's models; see README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Testing
import Tours

@Suite("isEulerian")
struct IsEulerianTests {
    @Test("TO-001 empty graph: true")
    func to001() {
        // V []; E []; isEulerian
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-005 one vertex: true")
    func to005() {
        // V [0]; E []; isEulerian
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-009 two isolated vertices (isolated vertices ignored): true")
    func to009() {
        // V [0, 1]; E []; isEulerian
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-013 one self-loop: true")
    func to013() {
        // multigraph V [0]; E [0-0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-017 two self-loops at one vertex: true")
    func to017() {
        // multigraph V [0]; E [0-0, 0-0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-021 self-loop beside an isolated vertex: true")
    func to021() {
        // multigraph V [0, 1]; E [1-1]; isEulerian
        let pairs: [(Int, Int)] = [(1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-025 self-loops at two vertices: two components with edges: false")
    func to025() {
        // multigraph V [0, 1]; E [0-0, 1-1]; isEulerian
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-029 one edge: a trail, no circuit: false")
    func to029() {
        // V [0, 1]; E [0-1]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-033 two parallel edges: a circuit of length 2: true")
    func to033() {
        // multigraph V [0, 1]; E [0-1, 0-1]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-037 three parallel edges: odd at both ends: false")
    func to037() {
        // multigraph V [0, 1]; E [0-1, 1-0, 0-1]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-041 path P(3): false")
    func to041() {
        // P(3); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-045 path P(4): false")
    func to045() {
        // P(4); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-049 triangle C(3): true")
    func to049() {
        // C(3); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-053 cycle C(5): true")
    func to053() {
        // C(5); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-057 triangle beside an isolated vertex: true")
    func to057() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-061 isolated first vertex: the circuit starts at the first vertex with an edge: true")
    func to061() {
        // V [0, 1, 2, 3]; E [1-2, 2-3, 3-1]; isEulerian
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-065 two triangles apart: false")
    func to065() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-069 bowtie: two triangles at a shared vertex: true")
    func to069() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-073 triangle with a loop: loops add 2: true")
    func to073() {
        // multigraph V [0, 1, 2]; E [0-1, 0-0, 1-2, 2-0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-077 edge with a loop at the end: odd 0 and 1: false")
    func to077() {
        // multigraph V [0, 1]; E [0-1, 1-1]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-081 loop at a vertex, an edge elsewhere: two components: false")
    func to081() {
        // multigraph V [0, 1, 2]; E [0-0, 1-2]; isEulerian
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-085 star(3): four odd vertices: false")
    func to085() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-089 K(4): every degree 3: false")
    func to089() {
        // K(4); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-093 K(5): every degree 4: true")
    func to093() {
        // K(5); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-097 Königsberg: seven bridges, four odd land masses: false")
    func to097() {
        // multigraph V [A, B, C, D]; E [A-B, A-B, A-C, A-C, A-D, B-D, C-D]; isEulerian
        let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-101 Königsberg less one A–B bridge: a trail: false")
    func to101() {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; isEulerian
        let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-105 house: odd at the base: false")
    func to105() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-0, 2-4, 4-3]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-109 vertex order, not label order: false")
    func to109() {
        // V [d, a, c, b]; E [a-c, c-b, b-a, d-a, d-c]; isEulerian
        let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-113 odd vertices last in the order: false")
    func to113() {
        // V [0, 1, 2, 3, 4]; E [4-3, 3-0, 0-1, 1-2, 2-0, 0-4, 4-1]; isEulerian
        let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-117 grid(3,3): four odd corners' neighbours: false")
    func to117() {
        // grid(3,3); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-121 Petersen: every degree 3: false")
    func to121() {
        // nx(petersen_graph); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-125 octahedral: every degree 4: true")
    func to125() {
        // nx(octahedral_graph); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-129 wheel(4): rim odd: false")
    func to129() {
        // wheel(4); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-133 K(3,3) less nothing: degree 3: false")
    func to133() {
        // Kb(3,3); isEulerian
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-137 Kb(2,4): even sides: true")
    func to137() {
        // Kb(2,4); isEulerian
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-141 rows decide: the first edge out of 0 is the second chord: true")
    func to141() {
        // V [0, 1, 2, 3, 4]; E [0-3, 0-1, 1-2, 2-0, 3-4, 4-0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-145 parallel edges inside a longer circuit: true")
    func to145() {
        // multigraph V [0, 1, 2]; E [0-1, 1-2, 1-2, 1-2, 2-0, 1-1]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-149 lcgwalk(6,14,1): true")
    func to149() {
        // lcgwalk(6,14,1); isEulerian
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-153 lcgwalk(8,30,2): true")
    func to153() {
        // lcgwalk(8,30,2); isEulerian
        let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-157 lcgwalk(5,20,3,open): false")
    func to157() {
        // lcgwalk(5,20,3,open); isEulerian
        let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-161 lcgwalk(10,40,4,open): false")
    func to161() {
        // lcgwalk(10,40,4,open); isEulerian
        let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-165 empty digraph: true")
    func to165() {
        // V []; E []; isEulerian
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-169 one vertex: true")
    func to169() {
        // V [0]; E []; isEulerian
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-173 one self-loop: in 1, out 1: true")
    func to173() {
        // multigraph V [0]; E [0→0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-177 one edge 0→1: false")
    func to177() {
        // V [0, 1]; E [0→1]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-181 antiparallel pair: true")
    func to181() {
        // V [0, 1]; E [0→1, 1→0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-185 parallel pair 0→1 twice: unbalanced by 2: false")
    func to185() {
        // multigraph V [0, 1]; E [0→1, 0→1]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-189 directed cycle Cd(3): true")
    func to189() {
        // Cd(3); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-193 directed path Pd(4): false")
    func to193() {
        // Pd(4); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-197 two sources: no trail: false")
    func to197() {
        // V [0, 1, 2]; E [0→2, 1→2]; isEulerian
        let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-201 balanced but two components: false")
    func to201() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→3, 3→2]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-205 Cd(3) beside an isolated vertex: true")
    func to205() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-209 isolated first vertex: true")
    func to209() {
        // V [0, 1, 2, 3]; E [1→2, 2→3, 3→1]; isEulerian
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-213 start is the vertex with out − in = 1, not the first: false")
    func to213() {
        // V [0, 1, 2, 3]; E [1→2, 2→0, 0→1, 2→3, 3→1, 1→3]; isEulerian
        let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-217 two directed cycles at a shared vertex: true")
    func to217() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-221 loop on a directed cycle: true")
    func to221() {
        // multigraph V [0, 1, 2]; E [0→1, 1→1, 1→2, 2→0]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-225 Cd(3) with a chord: a trail from 0: false")
    func to225() {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-229 in − out = 2 at one vertex: false")
    func to229() {
        // multigraph V [0, 1, 2]; E [0→2, 1→2, 2→1, 1→0, 0→2]; isEulerian
        let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-233 Kd(3): every in = out = 2: true")
    func to233() {
        // Kd(3); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-237 Kd(4): true")
    func to237() {
        // Kd(4); isEulerian
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-241 self-loop and an edge elsewhere: false")
    func to241() {
        // multigraph V [0, 1, 2]; E [0→0, 1→2]; isEulerian
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-245 lcgwalkd(6,14,1): true")
    func to245() {
        // lcgwalkd(6,14,1); isEulerian
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-249 lcgwalkd(8,30,2): true")
    func to249() {
        // lcgwalkd(8,30,2); isEulerian
        let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == true)
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

    @Test("TO-253 lcgwalkd(5,20,3,open): false")
    func to253() {
        // lcgwalkd(5,20,3,open); isEulerian
        let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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

    @Test("TO-257 lcgwalkd(9,40,5,open): false")
    func to257() {
        // lcgwalkd(9,40,5,open); isEulerian
        let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        #expect(graph.isEulerian == false)
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
