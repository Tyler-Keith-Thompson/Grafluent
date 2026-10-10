// `eulerianCircuit()` and `eulerianCircuit(from:)` (catalog §EulerianCircuit,
// §EulerianCircuitDirected, §EulerianCircuitFrom, §EulerianCircuitFromDirected): Hierholzer's walk
// exactly (its vertices, the start not repeated, and its edge positions), pinned by the documented
// rows; checked here as genuine (every edge exactly once, edge i joining vertex i and the next, the
// last back to the first, `Circuit(vertices:edges:in:)` accepting it) and starting where api.md says
// (the first vertex with an edge, or the given one); nil without edges, when not Eulerian, or from a
// vertex without edges. Directed rows are `AdjacencyList`, or `DirectedPseudograph` with a self-loop
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

@Suite("eulerianCircuit")
struct EulerianCircuitTests {
    @Test("TO-003 empty graph: nil")
    func to003() {
        // V []; E []; eulerianCircuit()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-007 one vertex: nil")
    func to007() {
        // V [0]; E []; eulerianCircuit()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-011 two isolated vertices (isolated vertices ignored): nil")
    func to011() {
        // V [0, 1]; E []; eulerianCircuit()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-015 one self-loop: circuit [0]; edges [0]")
    func to015() throws {
        // multigraph V [0]; E [0-0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0] as [Int])
        #expect(circuit.edges == [0] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-019 two self-loops at one vertex: circuit [0, 0]; edges [0, 1]")
    func to019() throws {
        // multigraph V [0]; E [0-0, 0-0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 0), (0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 0] as [Int])
        #expect(circuit.edges == [0, 1] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-023 self-loop beside an isolated vertex: circuit [1]; edges [0]")
    func to023() throws {
        // multigraph V [0, 1]; E [1-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [1] as [Int])
        #expect(circuit.edges == [0] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 1)
    }

    @Test("TO-027 self-loops at two vertices: two components with edges: nil")
    func to027() {
        // multigraph V [0, 1]; E [0-0, 1-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-031 one edge: a trail, no circuit: nil")
    func to031() {
        // V [0, 1]; E [0-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-035 two parallel edges: a circuit of length 2: circuit [0, 1]; edges [0, 1]")
    func to035() throws {
        // multigraph V [0, 1]; E [0-1, 0-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1] as [Int])
        #expect(circuit.edges == [0, 1] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-039 three parallel edges: odd at both ends: nil")
    func to039() {
        // multigraph V [0, 1]; E [0-1, 1-0, 0-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (0, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-043 path P(3): nil")
    func to043() {
        // P(3); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-047 path P(4): nil")
    func to047() {
        // P(4); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-051 triangle C(3): circuit [0, 1, 2]; edges [0, 1, 2]")
    func to051() throws {
        // C(3); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2] as [Int])
        #expect(circuit.edges == [0, 1, 2] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-055 cycle C(5): circuit [0, 1, 2, 3, 4]; edges [0, 1, 2, 3, 4]")
    func to055() throws {
        // C(5); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2, 3, 4] as [Int])
        #expect(circuit.edges == [0, 1, 2, 3, 4] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-059 triangle beside an isolated vertex: circuit [0, 1, 2]; edges [0, 1, 2]")
    func to059() throws {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2] as [Int])
        #expect(circuit.edges == [0, 1, 2] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-063 isolated first vertex: the circuit starts at the first vertex with an edge: circuit [1, 2, 3]; edges [0, 1, 2]")
    func to063() throws {
        // V [0, 1, 2, 3]; E [1-2, 2-3, 3-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [1, 2, 3] as [Int])
        #expect(circuit.edges == [0, 1, 2] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 1)
    }

    @Test("TO-067 two triangles apart: nil")
    func to067() {
        // V [0, 1, 2, 3, 4, 5]; E [0-1, 1-2, 2-0, 3-4, 4-5, 5-3]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-071 bowtie: two triangles at a shared vertex: circuit [0, 1, 2, 3, 4, 2]; edges [0, 1, 3, 4, 5, 2]")
    func to071() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2, 3, 4, 2] as [Int])
        #expect(circuit.edges == [0, 1, 3, 4, 5, 2] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-075 triangle with a loop: loops add 2: circuit [0, 1, 2, 0]; edges [0, 2, 3, 1]")
    func to075() throws {
        // multigraph V [0, 1, 2]; E [0-1, 0-0, 1-2, 2-0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 0), (1, 2), (2, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2, 0] as [Int])
        #expect(circuit.edges == [0, 2, 3, 1] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-079 edge with a loop at the end: odd 0 and 1: nil")
    func to079() {
        // multigraph V [0, 1]; E [0-1, 1-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-083 loop at a vertex, an edge elsewhere: two components: nil")
    func to083() {
        // multigraph V [0, 1, 2]; E [0-0, 1-2]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-087 star(3): four odd vertices: nil")
    func to087() {
        // V [0, 1, 2, 3]; E [0-1, 0-2, 0-3]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-091 K(4): every degree 3: nil")
    func to091() {
        // K(4); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-095 K(5): every degree 4: circuit [0, 1, 2, 0, 3, 1, 4, 2, 3, 4]; edges [0, 4, 1, 2, 5, 6, 8, 7, 9, 3]")
    func to095() throws {
        // K(5); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2, 0, 3, 1, 4, 2, 3, 4] as [Int])
        #expect(circuit.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 3] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-099 Königsberg: seven bridges, four odd land masses: nil")
    func to099() {
        // multigraph V [A, B, C, D]; E [A-B, A-B, A-C, A-C, A-D, B-D, C-D]; eulerianCircuit()
        let pairs: [(String, String)] = [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-103 Königsberg less one A–B bridge: a trail: nil")
    func to103() {
        // multigraph V [A, B, C, D]; E [A-B, A-C, A-C, A-D, B-D, C-D]; eulerianCircuit()
        let pairs: [(String, String)] = [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")]
        let graph = Pseudograph<String>(vertices: ["A", "B", "C", "D"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["A", "B", "C", "D"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-107 house: odd at the base: nil")
    func to107() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-0, 2-4, 4-3]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-111 vertex order, not label order: nil")
    func to111() {
        // V [d, a, c, b]; E [a-c, c-b, b-a, d-a, d-c]; eulerianCircuit()
        let pairs: [(String, String)] = [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")]
        let graph = UndirectedAdjacencyList<String>(vertices: ["d", "a", "c", "b"] as [String], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["d", "a", "c", "b"] as [String])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-115 odd vertices last in the order: nil")
    func to115() {
        // V [0, 1, 2, 3, 4]; E [4-3, 3-0, 0-1, 1-2, 2-0, 0-4, 4-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-119 grid(3,3): four odd corners' neighbours: nil")
    func to119() {
        // grid(3,3); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-123 Petersen: every degree 3: nil")
    func to123() {
        // nx(petersen_graph); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-127 octahedral: every degree 4")
    func to127() throws {
        // nx(octahedral_graph); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2, 0, 3, 1, 5, 2, 4, 3, 5, 4] as [Int])
        #expect(circuit.edges == [0, 4, 1, 2, 5, 6, 8, 7, 9, 10, 11, 3] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-131 wheel(4): rim odd: nil")
    func to131() {
        // wheel(4); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-135 K(3,3) less nothing: degree 3: nil")
    func to135() {
        // Kb(3,3); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-139 Kb(2,4): even sides: circuit [0, 2, 1, 3, 0, 4, 1, 5]; edges [0, 4, 5, 1, 2, 6, 7, 3]")
    func to139() throws {
        // Kb(2,4); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (1, 3), (1, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 2, 1, 3, 0, 4, 1, 5] as [Int])
        #expect(circuit.edges == [0, 4, 5, 1, 2, 6, 7, 3] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-143 rows decide: the first edge out of 0 is the second chord: circuit [0, 3, 4, 0, 1, 2]; edges [0, 4, 5, 1, 2, 3]")
    func to143() throws {
        // V [0, 1, 2, 3, 4]; E [0-3, 0-1, 1-2, 2-0, 3-4, 4-0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 3, 4, 0, 1, 2] as [Int])
        #expect(circuit.edges == [0, 4, 5, 1, 2, 3] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-147 parallel edges inside a longer circuit: circuit [0, 1, 2, 1, 1, 2]; edges [0, 1, 2, 5, 3, 4]")
    func to147() throws {
        // multigraph V [0, 1, 2]; E [0-1, 1-2, 1-2, 1-2, 2-0, 1-1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2, 1, 1, 2] as [Int])
        #expect(circuit.edges == [0, 1, 2, 5, 3, 4] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-151 lcgwalk(6,14,1)")
    func to151() throws {
        // lcgwalk(6,14,1); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0] as [Int])
        #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-155 lcgwalk(8,30,2)")
    func to155() throws {
        // lcgwalk(8,30,2); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3] as [Int])
        #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-159 lcgwalk(5,20,3,open): nil")
    func to159() {
        // lcgwalk(5,20,3,open); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-163 lcgwalk(10,40,4,open): nil")
    func to163() {
        // lcgwalk(10,40,4,open); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 6), (6, 2), (2, 4), (4, 1), (1, 5), (5, 7), (7, 1), (1, 3), (3, 4), (4, 6), (6, 5), (5, 4), (4, 6), (6, 4), (4, 1), (1, 7), (7, 4), (4, 7), (7, 8), (8, 8), (8, 8), (8, 5), (5, 0), (0, 8), (8, 7), (7, 6), (6, 6), (6, 3), (3, 7), (7, 0), (0, 9), (9, 8), (8, 9), (9, 0), (0, 0), (0, 5), (5, 3), (3, 2), (2, 8), (8, 4)]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-167 empty digraph: nil")
    func to167() {
        // V []; E []; eulerianCircuit()
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-171 one vertex: nil")
    func to171() {
        // V [0]; E []; eulerianCircuit()
        let pairs: [(Int, Int)] = []
        let graph = AdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-175 one self-loop: in 1, out 1: circuit [0]; edges [0]")
    func to175() throws {
        // multigraph V [0]; E [0→0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0] as [Int])
        #expect(circuit.edges == [0] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-179 one edge 0→1: nil")
    func to179() {
        // V [0, 1]; E [0→1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-183 antiparallel pair: circuit [0, 1]; edges [0, 1]")
    func to183() throws {
        // V [0, 1]; E [0→1, 1→0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1] as [Int])
        #expect(circuit.edges == [0, 1] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-187 parallel pair 0→1 twice: unbalanced by 2: nil")
    func to187() {
        // multigraph V [0, 1]; E [0→1, 0→1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-191 directed cycle Cd(3): circuit [0, 1, 2]; edges [0, 1, 2]")
    func to191() throws {
        // Cd(3); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2] as [Int])
        #expect(circuit.edges == [0, 1, 2] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-195 directed path Pd(4): nil")
    func to195() {
        // Pd(4); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-199 two sources: no trail: nil")
    func to199() {
        // V [0, 1, 2]; E [0→2, 1→2]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 2), (1, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-203 balanced but two components: nil")
    func to203() {
        // V [0, 1, 2, 3]; E [0→1, 1→0, 2→3, 3→2]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (2, 3), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-207 Cd(3) beside an isolated vertex: circuit [0, 1, 2]; edges [0, 1, 2]")
    func to207() throws {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2] as [Int])
        #expect(circuit.edges == [0, 1, 2] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-211 isolated first vertex: circuit [1, 2, 3]; edges [0, 1, 2]")
    func to211() throws {
        // V [0, 1, 2, 3]; E [1→2, 2→3, 3→1]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(1, 2), (2, 3), (3, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [1, 2, 3] as [Int])
        #expect(circuit.edges == [0, 1, 2] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 1)
    }

    @Test("TO-215 start is the vertex with out − in = 1, not the first: nil")
    func to215() {
        // V [0, 1, 2, 3]; E [1→2, 2→0, 0→1, 2→3, 3→1, 1→3]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-219 two directed cycles at a shared vertex: circuit [0, 1, 2, 0, 3, 4]; edges [0, 1, 2, 3, 4, 5]")
    func to219() throws {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 2, 0, 3, 4] as [Int])
        #expect(circuit.edges == [0, 1, 2, 3, 4, 5] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-223 loop on a directed cycle: circuit [0, 1, 1, 2]; edges [0, 1, 2, 3]")
    func to223() throws {
        // multigraph V [0, 1, 2]; E [0→1, 1→1, 1→2, 2→0]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 1), (1, 2), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 1, 2] as [Int])
        #expect(circuit.edges == [0, 1, 2, 3] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-227 Cd(3) with a chord: a trail from 0: nil")
    func to227() {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→2]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-231 in − out = 2 at one vertex: nil")
    func to231() {
        // multigraph V [0, 1, 2]; E [0→2, 1→2, 2→1, 1→0, 0→2]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-235 Kd(3): every in = out = 2: circuit [0, 1, 0, 2, 1, 2]; edges [0, 2, 1, 5, 3, 4]")
    func to235() throws {
        // Kd(3); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 0, 2, 1, 2] as [Int])
        #expect(circuit.edges == [0, 2, 1, 5, 3, 4] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-239 Kd(4): circuit [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3]; edges [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9]")
    func to239() throws {
        // Kd(4); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 1, 0, 2, 0, 3, 1, 2, 1, 3, 2, 3] as [Int])
        #expect(circuit.edges == [0, 3, 1, 6, 2, 10, 4, 7, 5, 11, 8, 9] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-243 self-loop and an edge elsewhere: nil")
    func to243() {
        // multigraph V [0, 1, 2]; E [0→0, 1→2]; eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 0), (1, 2)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-247 lcgwalkd(6,14,1)")
    func to247() throws {
        // lcgwalkd(6,14,1); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 2), (2, 3), (3, 0), (0, 0), (0, 0), (0, 5), (5, 2), (2, 4), (4, 3), (3, 4), (4, 3), (3, 4), (4, 0), (0, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 2, 3, 0, 0, 0, 5, 2, 4, 3, 4, 3, 4, 0] as [Int])
        #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-251 lcgwalkd(8,30,2)")
    func to251() throws {
        // lcgwalkd(8,30,2); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 4), (4, 2), (2, 0), (0, 0), (0, 7), (7, 3), (3, 4), (4, 6), (6, 1), (1, 2), (2, 7), (7, 2), (2, 2), (2, 2), (2, 0), (0, 2), (2, 2), (2, 5), (5, 6), (6, 7), (7, 0), (0, 6), (6, 4), (4, 2), (2, 5), (5, 6), (6, 7), (7, 2), (2, 7), (7, 3), (3, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit())
        #expect(circuit.vertices == [0, 4, 2, 0, 0, 7, 3, 4, 6, 1, 2, 7, 2, 2, 2, 0, 2, 2, 5, 6, 7, 0, 6, 4, 2, 5, 6, 7, 2, 7, 3] as [Int])
        #expect(circuit.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the first vertex with an edge.
        #expect(at.first == 0)
    }

    @Test("TO-255 lcgwalkd(5,20,3,open): nil")
    func to255() {
        // lcgwalkd(5,20,3,open); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 4), (4, 3), (3, 0), (0, 3), (3, 4), (4, 3), (3, 0), (0, 0), (0, 4), (4, 4), (4, 3), (3, 2), (2, 1), (1, 4), (4, 3), (3, 0), (0, 4), (4, 4), (4, 2), (2, 1)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-259 lcgwalkd(9,40,5,open): nil")
    func to259() {
        // lcgwalkd(9,40,5,open); eulerianCircuit()
        let pairs: [(Int, Int)] = [(0, 7), (7, 8), (8, 7), (7, 1), (1, 4), (4, 5), (5, 8), (8, 7), (7, 5), (5, 6), (6, 3), (3, 6), (6, 6), (6, 2), (2, 3), (3, 5), (5, 2), (2, 3), (3, 1), (1, 3), (3, 4), (4, 1), (1, 3), (3, 3), (3, 0), (0, 5), (5, 1), (1, 0), (0, 5), (5, 4), (4, 5), (5, 4), (4, 8), (8, 3), (3, 4), (4, 2), (2, 6), (6, 6), (6, 8), (8, 5)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit() == nil)
    }

    @Test("TO-261 C(4) from 0: circuit [0, 1, 2, 3]; edges [0, 1, 2, 3]")
    func to261() throws {
        // C(4); eulerianCircuit(from: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit(from: 0))
        #expect(circuit.vertices == [0, 1, 2, 3] as [Int])
        #expect(circuit.edges == [0, 1, 2, 3] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 0)
    }

    @Test("TO-262 C(4) from 1: circuit [1, 0, 3, 2]; edges [0, 3, 2, 1]")
    func to262() throws {
        // C(4); eulerianCircuit(from: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit(from: 1))
        #expect(circuit.vertices == [1, 0, 3, 2] as [Int])
        #expect(circuit.edges == [0, 3, 2, 1] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 1)
    }

    @Test("TO-263 bowtie from the shared vertex: circuit [2, 1, 0, 2, 3, 4]; edges [1, 0, 2, 3, 4, 5]")
    func to263() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; eulerianCircuit(from: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit(from: 2))
        #expect(circuit.vertices == [2, 1, 0, 2, 3, 4] as [Int])
        #expect(circuit.edges == [1, 0, 2, 3, 4, 5] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 2)
    }

    @Test("TO-264 bowtie from a wing: circuit [4, 3, 2, 1, 0, 2]; edges [4, 3, 1, 0, 2, 5]")
    func to264() throws {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-0, 2-3, 3-4, 4-2]; eulerianCircuit(from: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit(from: 4))
        #expect(circuit.vertices == [4, 3, 2, 1, 0, 2] as [Int])
        #expect(circuit.edges == [4, 3, 1, 0, 2, 5] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 4)
    }

    @Test("TO-265 isolated start: nil: nil")
    func to265() {
        // V [0, 1, 2, 3]; E [0-1, 1-2, 2-0]; eulerianCircuit(from: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit(from: 3) == nil)
    }

    @Test("TO-266 not Eulerian: nil: nil")
    func to266() {
        // P(3); eulerianCircuit(from: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit(from: 1) == nil)
    }

    @Test("TO-267 edgeless: nil (a circuit has an edge): nil")
    func to267() {
        // V [0, 1]; E []; eulerianCircuit(from: 0)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit(from: 0) == nil)
    }

    @Test("TO-268 one self-loop: circuit [0]; edges [0]")
    func to268() throws {
        // multigraph V [0]; E [0-0]; eulerianCircuit(from: 0)
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = Pseudograph<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit(from: 0))
        #expect(circuit.vertices == [0] as [Int])
        #expect(circuit.edges == [0] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect((a == x && b == y) || (a == y && b == x), "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 0)
    }

    @Test("TO-269 two directed cycles from 3: circuit [3, 4, 0, 1, 2, 0]; edges [4, 5, 0, 1, 2, 3]")
    func to269() throws {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→0, 0→3, 3→4, 4→0]; eulerianCircuit(from: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit(from: 3))
        #expect(circuit.vertices == [3, 4, 0, 1, 2, 0] as [Int])
        #expect(circuit.edges == [4, 5, 0, 1, 2, 3] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 3)
    }

    @Test("TO-270 Kd(3) from 2: circuit [2, 0, 1, 0, 2, 1]; edges [4, 0, 2, 1, 5, 3]")
    func to270() throws {
        // Kd(3); eulerianCircuit(from: 2)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let circuit = try #require(graph.eulerianCircuit(from: 2))
        #expect(circuit.vertices == [2, 0, 1, 0, 2, 1] as [Int])
        #expect(circuit.edges == [4, 0, 2, 1, 5, 3] as [Int])
        let walked = circuit.edges
        let at = circuit.vertices.map { vertexList.firstIndex(of: $0)! }
        // Genuine, checked here: every edge exactly once, edge i joining vertex i and the next (the last back to the first).
        #expect(walked.sorted() == Array(pairs.indices))
        #expect(at.count == walked.count)
        for (i, k) in walked.enumerated() {
            let x = at[i], y = at[(i + 1) % at.count]
            let (a, b) = ends[k]
            #expect(a == x && b == y, "step \(i)")
        }
        #expect(Circuit(vertices: circuit.vertices, edges: circuit.edges, in: graph) != nil)
        // The documented start: the given vertex.
        #expect(at.first == 2)
    }

    @Test("TO-271 unbalanced: nil: nil")
    func to271() {
        // Pd(3); eulerianCircuit(from: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Each edge's ends as vertex indices (positions in `vertices`), by catalog edge.
        #expect(graph.eulerianCircuit(from: 0) == nil)
    }
}
