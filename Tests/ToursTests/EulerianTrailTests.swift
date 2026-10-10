// `eulerianTrail()` and `eulerianTrail(from:)` (catalog §EulerianTrail, §EulerianTrailDirected,
// §EulerianTrailFrom, §EulerianTrailFromDirected): Hierholzer's walk exactly, checked here as
// genuine (every edge exactly once, consecutive edges, `Trail(vertices:edges:in:)` accepting it) and
// starting where api.md says (the first odd vertex, the vertex with out − in = 1, or, Eulerian, the
// first vertex with an edge; the trivial trail at the first vertex without edges); nil with no
// vertex or no trail. Directed rows are `AdjacencyList`, or `DirectedPseudograph` with a self-loop
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

@Suite("eulerianTrail")
struct EulerianTrailTests {
    @Test("TO-004 empty graph: nil")
    func to004() {
        // V []; E []; eulerianTrail()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-008 one vertex: trail [0]; edges []")
    func to008() throws {
        // V [0]; E []; eulerianTrail()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0] as [Int])
        #expect(trail.edges == [] as [Int])
        // No edges: the trivial trail at the first vertex.
        #expect(trail.edges.isEmpty && trail.vertices == [0])
    }

    @Test("TO-012 two isolated vertices (isolated vertices ignored): trail [0]; edges []")
    func to012() throws {
        // V [0, 1]; E []; eulerianTrail()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0] as [Int])
        #expect(trail.edges == [] as [Int])
        // No edges: the trivial trail at the first vertex.
        #expect(trail.edges.isEmpty && trail.vertices == [0])
    }

    @Test("TO-016 one self-loop: trail [0, 0]; edges [0]")
    func to016() throws {
        // multigraph V [0]; E [0-0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 0] as [Int])
        #expect(trail.edges == [0] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-020 two self-loops at one vertex: trail [0, 0, 0]; edges [0, 1]")
    func to020() throws {
        // multigraph V [0]; E [0-0, 0-0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 0, 0] as [Int])
        #expect(trail.edges == [0, 1] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-024 self-loop beside an isolated vertex: trail [1, 1]; edges [0]")
    func to024() throws {
        // multigraph V [0, 1]; E [1-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [1, 1] as [Int])
        #expect(trail.edges == [0] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 1)
    }

    @Test("TO-028 self-loops at two vertices: two components with edges: nil")
    func to028() {
        // multigraph V [0, 1]; E [0-0, 1-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-032 one edge: a trail, no circuit: trail [0, 1]; edges [0]")
    func to032() throws {
        // V [0, 1]; E [0-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1] as [Int])
        #expect(trail.edges == [0] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 0)
    }

    @Test("TO-036 two parallel edges: a circuit of length 2: trail [0, 1, 0]; edges [0, 1]")
    func to036() throws {
        // multigraph V [0, 1]; E [0-1, 0-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 0] as [Int])
        #expect(trail.edges == [0, 1] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-040 three parallel edges: odd at both ends: trail [0, 1, 0, 1]; edges [0, 1, 2]")
    func to040() throws {
        // multigraph V [0, 1]; E [0-1, 1-0, 0-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 0, 1] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 0)
    }

    @Test("TO-044 path P(3): trail [0, 1, 2]; edges [0, 1]")
    func to044() throws {
        // P(3); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2] as [Int])
        #expect(trail.edges == [0, 1] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 0)
    }

    @Test("TO-048 path P(4): trail [0, 1, 2, 3]; edges [0, 1, 2]")
    func to048() throws {
        // P(4); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 3] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 0)
    }

    @Test("TO-052 triangle C(3): trail [0, 1, 2, 0]; edges [0, 1, 2]")
    func to052() throws {
        // C(3); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-056 cycle C(5): trail [0, 1, 2, 3, 4, 0]; edges [0, 1, 2, 3, 4]")
    func to056() throws {
        // C(5); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 3, 4, 0] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-060 triangle beside an isolated vertex: trail [0, 1, 2, 0]; edges [0, 1, 2]")
    func to060() throws {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-064 isolated first vertex: the circuit starts at the first vertex with an edge: trail [1, 2, 3, 1]; edges [0, 1, 2]")
    func to064() throws {
        // V [0, 1, 2, 3]; E [1-2, 2-3, 3-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [1, 2, 3, 1] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 1)
    }

    @Test("TO-068 two triangles apart: nil")
    func to068() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-072 bowtie: two triangles at a shared vertex: trail [0, 1, 2, 3, 4, 2, 0]; edges [0, 1, 3, 4, 5, 2]")
    func to072() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 3, 4, 2, 0] as [Int])
        #expect(trail.edges == [0, 1, 3, 4, 5, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-076 triangle with a loop: loops add 2: trail [0, 1, 2, 0, 0]; edges [0, 2, 3, 1]")
    func to076() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-0, 1-2, 2-0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0, 0] as [Int])
        #expect(trail.edges == [0, 2, 3, 1] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-080 edge with a loop at the end: odd 0 and 1: trail [0, 1, 1]; edges [0, 1]")
    func to080() throws {
        // multigraph V [0, 1]; E [0-1, 1-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 1] as [Int])
        #expect(trail.edges == [0, 1] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 0)
    }

    @Test("TO-084 loop at a vertex, an edge elsewhere: two components: nil")
    func to084() {
        // multigraph V [0, 1, 2]; E [0-0, 1-2]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-088 star(3): four odd vertices: nil")
    func to088() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-092 K(4): every degree 3: nil")
    func to092() {
        // K(4); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-096 K(5): every degree 4: trail [0, 1, 2, 0, 3, 1, 4, 2, 3, 4, 0]; edges [0, 4, 1, 2, 5, 6, 8, 7, 9, 3]")
    func to096() throws {
        // K(5); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0, 3, 1, 4, 2, 3, 4, 0] as [Int])
        #expect(trail.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 3] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-100 Königsberg: seven bridges, four odd land masses: nil")
    func to100() {
        // multigraph V [A, B, C, D]; E [A-B, A-B, A-C, A-C, A-D, B-D, C-D]; eulerianTrail()
        let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-104 Königsberg less one A–B bridge: a trail: trail [C, A, B, D, A, C, D]; edges [1, 0, 4, 3, 2, 5]")
    func to104() throws {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; eulerianTrail()
        let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == ["C", "A", "B", "D", "A", "C", "D"] as [String])
        #expect(trail.edges == [1, 0, 4, 3, 2, 5] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 2)
    }

    @Test("TO-108 house: odd at the base: trail [2, 1, 0, 3, 2, 4, 3]; edges [1, 0, 3, 2, 4, 5]")
    func to108() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-0, 2-4, 4-3]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [2, 1, 0, 3, 2, 4, 3] as [Int])
        #expect(trail.edges == [1, 0, 3, 2, 4, 5] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 2)
    }

    @Test("TO-112 vertex order, not label order: trail [a, c, b, a, d, c]; edges [0, 1, 2, 3, 4]")
    func to112() throws {
        // V [d, a, c, b]; E [a-c, c-b, b-a, d-a, d-c]; eulerianTrail()
        let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == ["a", "c", "b", "a", "d", "c"] as [String])
        #expect(trail.edges == [0, 1, 2, 3, 4] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 1)
    }

    @Test("TO-116 odd vertices last in the order: trail [1, 0, 3, 4, 0, 2, 1, 4]; edges [2, 1, 0, 5, 4, 3, 6]")
    func to116() throws {
        // V [0, 1, 2, 3, 4]; E [4-3, 3-0, 0-1, 1-2, 2-0, 0-4, 4-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [1, 0, 3, 4, 0, 2, 1, 4] as [Int])
        #expect(trail.edges == [2, 1, 0, 5, 4, 3, 6] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 1)
    }

    @Test("TO-120 grid(3,3): four odd corners' neighbours: nil")
    func to120() {
        // grid(3,3); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-124 Petersen: every degree 3: nil")
    func to124() {
        // nx(petersen_graph); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-128 octahedral: every degree 4")
    func to128() throws {
        // nx(octahedral_graph); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0, 3, 1, 5, 2, 4, 3, 5, 4, 0] as [Int])
        #expect(trail.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 10, 11, 3] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-132 wheel(4): rim odd: nil")
    func to132() {
        // wheel(4); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-136 K(3,3) less nothing: degree 3: nil")
    func to136() {
        // Kb(3,3); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-140 Kb(2,4): even sides: trail [0, 2, 1, 3, 0, 4, 1, 5, 0]; edges [0, 4, 5, 1, 2, 6, 7, 3]")
    func to140() throws {
        // Kb(2,4); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 2, 1, 3, 0, 4, 1, 5, 0] as [Int])
        #expect(trail.edges == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-144 rows decide: the first edge out of 0 is the second chord: trail [0, 3, 4, 0, 1, 2, 0]; edges [0, 4, 5, 1, 2, 3]")
    func to144() throws {
        // V [0, 1, 2, 3, 4]; E [0-3, 0-1, 1-2, 2-0, 3-4, 4-0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 3, 4, 0, 1, 2, 0] as [Int])
        #expect(trail.edges == [0, 4, 5, 1, 2, 3] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-148 parallel edges inside a longer circuit: trail [0, 1, 2, 1, 1, 2, 0]; edges [0, 1, 2, 5, 3, 4]")
    func to148() throws {
        // multigraph V [0, 1, 2]; E [0-1, 1-2, 1-2, 1-2, 2-0, 1-1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 1, 1, 2, 0] as [Int])
        #expect(trail.edges == [0, 1, 2, 5, 3, 4] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-152 lcgwalk(6,14,1)")
    func to152() throws {
        // lcgwalk(6,14,1); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0, 0] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-156 lcgwalk(8,30,2)")
    func to156() throws {
        // lcgwalk(8,30,2); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3, 0] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-160 lcgwalk(5,20,3,open)")
    func to160() throws {
        // lcgwalk(5,20,3,open); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 4, 3, 0, 3, 4, 3, 0, 0, 4, 4, 3, 2, 1, 4, 3, 0, 4, 4, 2, 1] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 0)
    }

    @Test("TO-164 lcgwalk(10,40,4,open)")
    func to164() throws {
        // lcgwalk(10,40,4,open); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 6, 2, 4, 1, 5, 7, 1, 3, 4, 6, 5, 4, 6, 4, 1, 7, 4, 7, 8, 8, 8, 5, 0, 8, 7, 6, 6, 3, 7, 0, 9, 8, 9, 0, 0, 5, 3, 2, 8, 4] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the first odd vertex.
        #expect(at.first == 0)
    }

    @Test("TO-168 empty digraph: nil")
    func to168() {
        // V []; E []; eulerianTrail()
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-172 one vertex: trail [0]; edges []")
    func to172() throws {
        // V [0]; E []; eulerianTrail()
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0] as [Int])
        #expect(trail.edges == [] as [Int])
        // No edges: the trivial trail at the first vertex.
        #expect(trail.edges.isEmpty && trail.vertices == [0])
    }

    @Test("TO-176 one self-loop: in 1, out 1: trail [0, 0]; edges [0]")
    func to176() throws {
        // multigraph V [0]; E [0→0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 0] as [Int])
        #expect(trail.edges == [0] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-180 one edge 0→1: trail [0, 1]; edges [0]")
    func to180() throws {
        // V [0, 1]; E [0→1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1] as [Int])
        #expect(trail.edges == [0] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the vertex with out − in = 1.
        #expect(at.first == 0)
    }

    @Test("TO-184 antiparallel pair: trail [0, 1, 0]; edges [0, 1]")
    func to184() throws {
        // V [0, 1]; E [0→1, 1→0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 0] as [Int])
        #expect(trail.edges == [0, 1] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-188 parallel pair 0→1 twice: unbalanced by 2: nil")
    func to188() {
        // multigraph V [0, 1]; E [0→1, 0→1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-192 directed cycle Cd(3): trail [0, 1, 2, 0]; edges [0, 1, 2]")
    func to192() throws {
        // Cd(3); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-196 directed path Pd(4): trail [0, 1, 2, 3]; edges [0, 1, 2]")
    func to196() throws {
        // Pd(4); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 3] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the vertex with out − in = 1.
        #expect(at.first == 0)
    }

    @Test("TO-200 two sources: no trail: nil")
    func to200() {
        // V [0, 1, 2]; E [0→2, 1→2]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-204 balanced but two components: nil")
    func to204() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→3, 3→2]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-208 Cd(3) beside an isolated vertex: trail [0, 1, 2, 0]; edges [0, 1, 2]")
    func to208() throws {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-212 isolated first vertex: trail [1, 2, 3, 1]; edges [0, 1, 2]")
    func to212() throws {
        // V [0, 1, 2, 3]; E [1→2, 2→3, 3→1]; eulerianTrail()
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [1, 2, 3, 1] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 1)
    }

    @Test("TO-216 start is the vertex with out − in = 1, not the first: trail [2, 0, 1, 2, 3, 1, 3]; edges [1, 2, 0, 3, 4, 5]")
    func to216() throws {
        // V [0, 1, 2, 3]; E [1→2, 2→0, 0→1, 2→3, 3→1, 1→3]; eulerianTrail()
        let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [2, 0, 1, 2, 3, 1, 3] as [Int])
        #expect(trail.edges == [1, 2, 0, 3, 4, 5] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the vertex with out − in = 1.
        #expect(at.first == 2)
    }

    @Test("TO-220 two directed cycles at a shared vertex: trail [0, 1, 2, 0, 3, 4, 0]; edges [0, 1, 2, 3, 4, 5]")
    func to220() throws {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0, 3, 4, 0] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-224 loop on a directed cycle: trail [0, 1, 1, 2, 0]; edges [0, 1, 2, 3]")
    func to224() throws {
        // multigraph V [0, 1, 2]; E [0→1, 1→1, 1→2, 2→0]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 1, 2, 0] as [Int])
        #expect(trail.edges == [0, 1, 2, 3] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-228 Cd(3) with a chord: a trail from 0: trail [0, 1, 2, 0, 2]; edges [0, 1, 2, 3]")
    func to228() throws {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 2, 0, 2] as [Int])
        #expect(trail.edges == [0, 1, 2, 3] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the vertex with out − in = 1.
        #expect(at.first == 0)
    }

    @Test("TO-232 in − out = 2 at one vertex: nil")
    func to232() {
        // multigraph V [0, 1, 2]; E [0→2, 1→2, 2→1, 1→0, 0→2]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-236 Kd(3): every in = out = 2: trail [0, 1, 0, 2, 1, 2, 0]; edges [0, 2, 1, 5, 3, 4]")
    func to236() throws {
        // Kd(3); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 0, 2, 1, 2, 0] as [Int])
        #expect(trail.edges == [0, 2, 1, 5, 3, 4] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-240 Kd(4): trail [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3, 0]; edges [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9]")
    func to240() throws {
        // Kd(4); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3, 0] as [Int])
        #expect(trail.edges == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-244 self-loop and an edge elsewhere: nil")
    func to244() {
        // multigraph V [0, 1, 2]; E [0→0, 1→2]; eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail() == nil)
    }

    @Test("TO-248 lcgwalkd(6,14,1)")
    func to248() throws {
        // lcgwalkd(6,14,1); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0, 0] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-252 lcgwalkd(8,30,2)")
    func to252() throws {
        // lcgwalkd(8,30,2); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3, 0] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: Eulerian, so the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-256 lcgwalkd(5,20,3,open)")
    func to256() throws {
        // lcgwalkd(5,20,3,open); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 4, 3, 0, 3, 4, 3, 0, 0, 4, 4, 3, 2, 1, 4, 3, 0, 4, 4, 2, 1] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the vertex with out − in = 1.
        #expect(at.first == 0)
    }

    @Test("TO-260 lcgwalkd(9,40,5,open)")
    func to260() throws {
        // lcgwalkd(9,40,5,open); eulerianTrail()
        let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail())
        #expect(trail.vertices == [0, 7, 8, 7, 1, 4, 5, 8, 7, 5, 6, 3, 6, 6, 2, 3, 5, 2, 3, 1, 3, 4, 1, 3, 3, 0, 5, 1, 0, 5, 4, 5, 4, 8, 3, 4, 2, 6, 6, 8, 5] as [Int])
        #expect(trail.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the vertex with out − in = 1.
        #expect(at.first == 0)
    }

    @Test("TO-272 P(4) from 0: trail [0, 1, 2, 3]; edges [0, 1, 2]")
    func to272() throws {
        // P(4); eulerianTrail(from: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail(from: 0))
        #expect(trail.vertices == [0, 1, 2, 3] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 0)
    }

    @Test("TO-273 P(4) from 3: the other odd end: trail [3, 2, 1, 0]; edges [2, 1, 0]")
    func to273() throws {
        // P(4); eulerianTrail(from: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail(from: 3))
        #expect(trail.vertices == [3, 2, 1, 0] as [Int])
        #expect(trail.edges == [2, 1, 0] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 3)
    }

    @Test("TO-274 P(4) from an even vertex: nil: nil")
    func to274() {
        // P(4); eulerianTrail(from: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail(from: 1) == nil)
    }

    @Test("TO-275 Eulerian: a closed trail from any vertex with an edge: trail [2, 1, 0, 3, 2]; edges [1, 0, 3, 2]")
    func to275() throws {
        // C(4); eulerianTrail(from: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail(from: 2))
        #expect(trail.vertices == [2, 1, 0, 3, 2] as [Int])
        #expect(trail.edges == [1, 0, 3, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 2)
    }

    @Test("TO-276 Eulerian, isolated start: nil: nil")
    func to276() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; eulerianTrail(from: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail(from: 3) == nil)
    }

    @Test("TO-277 edgeless: the trivial trail at the start: trail [1]; edges []")
    func to277() throws {
        // V [0, 1]; E []; eulerianTrail(from: 1)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let trail = try #require(graph.eulerianTrail(from: 1))
        #expect(trail.vertices == [1] as [Int])
        #expect(trail.edges == [] as [Int])
        // No edges: the trivial trail at the given vertex.
        #expect(trail.edges.isEmpty && trail.vertices == [1])
    }

    @Test("TO-278 no trail: nil: nil")
    func to278() {
        // K(4); eulerianTrail(from: 0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail(from: 0) == nil)
    }

    @Test("TO-279 Königsberg less one bridge, from D: trail [D, A, B, D, C, A, C]; edges [3, 0, 4, 5, 1, 2]")
    func to279() throws {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; eulerianTrail(from: D)
        let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail(from: "D"))
        #expect(trail.vertices == ["D", "A", "B", "D", "C", "A", "C"] as [String])
        #expect(trail.edges == [3, 0, 4, 5, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 3)
    }

    @Test("TO-280 loop at the end vertex: trail [1, 1, 0]; edges [1, 0]")
    func to280() throws {
        // multigraph V [0, 1]; E [0-1, 1-1]; eulerianTrail(from: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail(from: 1))
        #expect(trail.vertices == [1, 1, 0] as [Int])
        #expect(trail.edges == [1, 0] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 1)
    }

    @Test("TO-281 Pd(4) from 0: trail [0, 1, 2, 3]; edges [0, 1, 2]")
    func to281() throws {
        // Pd(4); eulerianTrail(from: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail(from: 0))
        #expect(trail.vertices == [0, 1, 2, 3] as [Int])
        #expect(trail.edges == [0, 1, 2] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 0)
    }

    @Test("TO-282 Pd(4) from the end: nil: nil")
    func to282() {
        // Pd(4); eulerianTrail(from: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail(from: 3) == nil)
    }

    @Test("TO-283 Cd(3) from 1: trail [1, 2, 0, 1]; edges [1, 2, 0]")
    func to283() throws {
        // Cd(3); eulerianTrail(from: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let trail = try #require(graph.eulerianTrail(from: 1))
        #expect(trail.vertices == [1, 2, 0, 1] as [Int])
        #expect(trail.edges == [1, 2, 0] as [Int])
        let walked = trail.edges
        let at = trail.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next.
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count + 1)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[i + 1]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Trail(vertices: trail.vertices, edges: trail.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 1)
    }

    @Test("TO-284 chord: from 0 only: nil")
    func to284() {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; eulerianTrail(from: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianTrail(from: 2) == nil)
    }
}
