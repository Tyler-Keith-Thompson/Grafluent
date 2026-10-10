// `BipartiteGraph(graph)` and `BipartiteGraph(graph, left:)` (catalog BP-085 – BP-104): the
// graph's vertex order, its edges in position order stored left endpoint first (so, without
// parallel edges, at the graph's positions), the canonical sides of `bipartition()` or the given
// left side with every other vertex right; nil on an odd cycle, on an edge with both ends on one
// side, or when `left:` names a non-vertex. Each row runs on `ReferencePseudograph` (rows in
// position order, parallel edges kept) and, when it has no parallel edges, again on
// `UndirectedAdjacencyList`. Edges are compared as [u, v] to see the stored orientation.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("BipartiteGraph(graph) and BipartiteGraph(graph, left:)")
struct BipartiteGraphFromGraphTests {
    @Test("BP-085 path P4, canonical sides: L [0, 2], R [1, 3]")
    func bp085() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [0, 2] as [Int])
            #expect(Array(bipartite.right) == [1, 3] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [0, 2] as [Int])
            #expect(Array(bipartite.right) == [1, 3] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
    }

    @Test("BP-086 path P4 with edges written right to left: L [0, 2], R [1, 3]")
    func bp086() throws {
        // V [0, 1, 2, 3]; E [1–0, 2–1, 3–2]; BipartiteGraph(g)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(1, 0), (2, 1), (3, 2)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [0, 2] as [Int])
            #expect(Array(bipartite.right) == [1, 3] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(1, 0), (2, 1), (3, 2)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [0, 2] as [Int])
            #expect(Array(bipartite.right) == [1, 3] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
    }

    @Test("BP-087 triangle: nil")
    func bp087() throws {
        // V [0, 1, 2]; E [0–1, 1–2, 2–0]; BipartiteGraph(g)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph) == nil)
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph) == nil)
        }
    }

    @Test("BP-088 self-loop: nil")
    func bp088() throws {
        // V [0, 1]; E [0–1, 1–1]; BipartiteGraph(g)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = ReferencePseudograph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph) == nil)
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph) == nil)
        }
    }

    @Test("BP-089 parallel pair collapses; positions of first copies: L [0, 2], R [1]")
    func bp089() throws {
        // multigraph V [0, 1, 2]; E [0–1, 1–2, 1–0, 2–1]; BipartiteGraph(g)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 0), (2, 1)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.left) == [0, 2] as [Int])
            #expect(Array(bipartite.right) == [1] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
    }

    @Test("BP-090 empty graph: L [], R []")
    func bp090() throws {
        // V []; E []; BipartiteGraph(g)
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [] as [Int])
            #expect(Array(bipartite.left) == [] as [Int])
            #expect(Array(bipartite.right) == [] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
        do { // UndirectedAdjacencyList
            let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int])
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [] as [Int])
            #expect(Array(bipartite.left) == [] as [Int])
            #expect(Array(bipartite.right) == [] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
    }

    @Test("BP-091 isolated vertices only: all left: L [3, 1, 2], R []")
    func bp091() throws {
        // V [3, 1, 2]; E []; BipartiteGraph(g)
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [3, 1, 2], edges: [])
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [3, 1, 2] as [Int])
            #expect(Array(bipartite.left) == [3, 1, 2] as [Int])
            #expect(Array(bipartite.right) == [] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
        do { // UndirectedAdjacencyList
            let graph = UndirectedAdjacencyList<Int>(vertices: [3, 1, 2] as [Int])
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [3, 1, 2] as [Int])
            #expect(Array(bipartite.left) == [3, 1, 2] as [Int])
            #expect(Array(bipartite.right) == [] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
    }

    @Test("BP-092 disconnected: each component's least vertex left: L [0, 1, 2], R [3, 4]")
    func bp092() throws {
        // V [0, 1, 2, 3, 4]; E [4–1, 2–3]; BipartiteGraph(g)
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(4, 1), (2, 3)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3, 4] as [Int])
            #expect(Array(bipartite.left) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.right) == [3, 4] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[1, 4], [2, 3]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(4, 1), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3, 4] as [Int])
            #expect(Array(bipartite.left) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.right) == [3, 4] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[1, 4], [2, 3]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
            let bipartition = try #require(graph.bipartition())
            #expect(Array(bipartite.left) == Array(bipartition.left))
            #expect(Array(bipartite.right) == Array(bipartition.right))
        }
    }

    @Test("BP-093 left: [1, 3] on P4: L [1, 3], R [0, 2]")
    func bp093() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [1, 3])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [1, 3] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [1, 3] as [Int])
            #expect(Array(bipartite.right) == [0, 2] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[1, 0], [1, 2], [3, 2]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [1, 3] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [1, 3] as [Int])
            #expect(Array(bipartite.right) == [0, 2] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[1, 0], [1, 2], [3, 2]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
    }

    @Test("BP-094 left: [0, 2] on P4: L [0, 2], R [1, 3]")
    func bp094() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [0, 2])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [0, 2] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [0, 2] as [Int])
            #expect(Array(bipartite.right) == [1, 3] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [0, 2] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [0, 2] as [Int])
            #expect(Array(bipartite.right) == [1, 3] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
    }

    @Test("BP-095 left: [0, 1] on P4: nil (edge 0–1 inside left)")
    func bp095() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [0, 1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [0, 1] as [Int]) == nil)
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [0, 1] as [Int]) == nil)
        }
    }

    @Test("BP-096 left: [] on P4: nil (every edge inside right)")
    func bp096() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [] as [Int]) == nil)
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [] as [Int]) == nil)
        }
    }

    @Test("BP-097 left: [] on an edgeless graph: every vertex right: L [], R [0, 1, 2]")
    func bp097() throws {
        // V [0, 1, 2]; E []; BipartiteGraph(g, left: [])
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [])
            let bipartite = try #require(BipartiteGraph(graph, left: [] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.left) == [] as [Int])
            #expect(Array(bipartite.right) == [0, 1, 2] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
        do { // UndirectedAdjacencyList
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int])
            let bipartite = try #require(BipartiteGraph(graph, left: [] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.left) == [] as [Int])
            #expect(Array(bipartite.right) == [0, 1, 2] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
    }

    @Test("BP-098 left: every vertex on an edgeless graph: L [0, 1, 2], R []")
    func bp098() throws {
        // V [0, 1, 2]; E []; BipartiteGraph(g, left: [0, 1, 2])
        do { // ReferencePseudograph
            let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [])
            let bipartite = try #require(BipartiteGraph(graph, left: [0, 1, 2] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.left) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.right) == [] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
        do { // UndirectedAdjacencyList
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int])
            let bipartite = try #require(BipartiteGraph(graph, left: [0, 1, 2] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.left) == [0, 1, 2] as [Int])
            #expect(Array(bipartite.right) == [] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
    }

    @Test("BP-099 left: listed twice is the same set: L [1, 3], R [0, 2]")
    func bp099() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [1, 3, 1])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [1, 3, 1] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [1, 3] as [Int])
            #expect(Array(bipartite.right) == [0, 2] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[1, 0], [1, 2], [3, 2]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [1, 3, 1] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3] as [Int])
            #expect(Array(bipartite.left) == [1, 3] as [Int])
            #expect(Array(bipartite.right) == [0, 2] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[1, 0], [1, 2], [3, 2]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
    }

    @Test("BP-100 left: a non-vertex: nil")
    func bp100() throws {
        // V [0, 1, 2, 3]; E [0–1, 1–2, 2–3]; BipartiteGraph(g, left: [1, 3, 9])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [1, 3, 9] as [Int]) == nil)
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [1, 3, 9] as [Int]) == nil)
        }
    }

    @Test("BP-101 left: per component, either side: L [1, 2, 5], R [0, 3, 4]")
    func bp101() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–1, 2–3, 4–5]; BipartiteGraph(g, left: [1, 2, 5])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (4, 5)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [1, 2, 5] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(Array(bipartite.left) == [1, 2, 5] as [Int])
            #expect(Array(bipartite.right) == [0, 3, 4] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[1, 0], [2, 3], [5, 4]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (2, 3), (4, 5)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [1, 2, 5] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(Array(bipartite.left) == [1, 2, 5] as [Int])
            #expect(Array(bipartite.right) == [0, 3, 4] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[1, 0], [2, 3], [5, 4]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
    }

    @Test("BP-102 left: on a self-loop vertex: nil")
    func bp102() throws {
        // V [0, 1]; E [0–1, 1–1]; BipartiteGraph(g, left: [0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = ReferencePseudograph(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [0] as [Int]) == nil)
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 1)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [0] as [Int]) == nil)
        }
    }

    @Test("BP-103 left: on K3,3 with sides swapped: L [3, 4, 5], R [0, 1, 2]")
    func bp103() throws {
        // V [0, 1, 2, 3, 4, 5]; E [0–3, 0–4, 0–5, 1–3, 1–4, 1–5, 2–3, 2–4, 2–5]; BipartiteGraph(g, left: [3, 4, 5])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [3, 4, 5] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(Array(bipartite.left) == [3, 4, 5] as [Int])
            #expect(Array(bipartite.right) == [0, 1, 2] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[3, 0], [4, 0], [5, 0], [3, 1], [4, 1], [5, 1], [3, 2], [4, 2], [5, 2]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let bipartite = try #require(BipartiteGraph(graph, left: [3, 4, 5] as [Int]))
            #expect(Array(bipartite.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
            #expect(Array(bipartite.left) == [3, 4, 5] as [Int])
            #expect(Array(bipartite.right) == [0, 1, 2] as [Int])
            #expect(bipartite.edges.map { [$0.u, $0.v] } == [[3, 0], [4, 0], [5, 0], [3, 1], [4, 1], [5, 1], [3, 2], [4, 2], [5, 2]] as [[Int]])
            for v in bipartite.left { #expect(bipartite.side(of: v) == .left) }
            for v in bipartite.right { #expect(bipartite.side(of: v) == .right) }
            // No parallel edges: the graph's positions.
            #expect(Array(bipartite.edges) == Array(graph.edges))
        }
    }

    @Test("BP-104 left: triangle, any set: nil")
    func bp104() throws {
        // V [0, 1, 2]; E [0–1, 1–2, 2–0]; BipartiteGraph(g, left: [0])
        do { // ReferencePseudograph
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = ReferencePseudograph(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [0] as [Int]) == nil)
        }
        do { // UndirectedAdjacencyList
            let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
            let graph = UndirectedAdjacencyList(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(BipartiteGraph(graph, left: [0] as [Int]) == nil)
        }
    }
}
