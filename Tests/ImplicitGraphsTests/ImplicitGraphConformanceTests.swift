// Conformance: the generic algorithms on an ImplicitDirectedGraph equal the same algorithms on the
// same rows stored in a DirectedPseudograph<Int> (vertices 0..<n in order, each row's edges inserted
// in row order, parallel edges and self-loops kept), on seeded random closures. Traversal (BFS and
// DFS events, layers, descendants, hasPath, topological order, findCycle), Connectivity (weak,
// strong and attracting components) and ShortestPaths (hop counts and Dijkstra, the weight read from
// the edge's target, which the implicit position carries). Then the calls the searches make, a
// LabeledGraph over an implicit grid, and an implicit graph whose rows are not Arrays. See README.md.

import Connectivity
import GrafluentTestSupport
import GraphProtocols
import ImplicitGraphs
import LabeledGraphs
import Multigraphs
import ShortestPaths
import Testing
import Traversal

@Suite("ImplicitGraphs conformance with DirectedPseudograph", .tags(.randomized))
struct ImplicitGraphConformanceTests {
    @Test("Traversal on an implicit graph equals Traversal on the pseudograph of the same rows", arguments: 0 ..< 40)
    func traversalAgrees(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 0 ... 25, using: &rng)
        let rows = (0 ..< n).map { _ in (0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) } }
        let graph = ImplicitDirectedGraph(vertexCount: n, successors: { rows[$0] })
        let pseudograph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n).flatMap { v in rows[v].map { DirectedEdge(from: v, to: $0) } })
        #expect(graph.topologicalSort() == pseudograph.topologicalSort(), "seed \(seed)")
        #expect(graph.findCycle()?.vertices == pseudograph.findCycle()?.vertices, "seed \(seed)")
        #expect(graph.lazy.depthFirstSearch().map { "\($0)" } == pseudograph.lazy.depthFirstSearch().map { "\($0)" }, "seed \(seed)")
        for s in 0 ..< n {
            #expect(graph.breadthFirstLayers(from: s) == pseudograph.breadthFirstLayers(from: s), "seed \(seed), source \(s)")
            #expect(graph.lazy.breadthFirstSearch(from: s).map { "\($0)" } == pseudograph.lazy.breadthFirstSearch(from: s).map { "\($0)" }, "seed \(seed), source \(s)")
            #expect(graph.lazy.depthFirstSearch(from: s).map { "\($0)" } == pseudograph.lazy.depthFirstSearch(from: s).map { "\($0)" }, "seed \(seed), source \(s)")
            #expect(graph.descendants(of: s) == pseudograph.descendants(of: s), "seed \(seed), source \(s)")
            for t in 0 ..< n where (s + 2 * t) % 7 == 0 {
                #expect(graph.hasPath(from: s, to: t) == pseudograph.hasPath(from: s, to: t), "seed \(seed), \(s) → \(t)")
            }
        }
    }

    @Test("Connectivity and shortest paths agree with the pseudograph", arguments: 0 ..< 40)
    func connectivityAndShortestPathsAgree(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(1_000 + seed))
        let n = Int.random(in: 1 ... 30, using: &rng)
        let rows = (0 ..< n).map { _ in (0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in Int.random(in: 0 ..< n, using: &rng) } }
        let cost = (0 ..< n).map { _ in Int.random(in: 0 ... 9, using: &rng) }
        let graph = ImplicitDirectedGraph(vertexCount: n, successors: { rows[$0] })
        let pseudograph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n).flatMap { v in rows[v].map { DirectedEdge(from: v, to: $0) } })
        #expect(graph.weaklyConnectedComponents().map { Array($0) } == pseudograph.weaklyConnectedComponents().map { Array($0) }, "seed \(seed)")
        #expect(graph.stronglyConnectedComponents().map { Array($0) } == pseudograph.stronglyConnectedComponents().map { Array($0) }, "seed \(seed)")
        #expect(graph.attractingComponents().map { Array($0) } == pseudograph.attractingComponents().map { Array($0) }, "seed \(seed)")
        for s in 0 ..< n {
            let hops = graph.shortestPaths(from: s), pseudoHops = pseudograph.shortestPaths(from: s)
            #expect((0 ..< n).map { hops.distance(to: $0) } == (0 ..< n).map { pseudoHops.distance(to: $0) }, "seed \(seed), source \(s)")
            // Entering v costs cost[v]: the implicit position carries the target.
            let tree = graph.dijkstraShortestPaths(from: s) { cost[$0.target] }
            let pseudoTree = pseudograph.dijkstraShortestPaths(from: s) { cost[pseudograph.target(ofEdgeAt: $0)] }
            #expect((0 ..< n).map { tree.distance(to: $0) } == (0 ..< n).map { pseudoTree.distance(to: $0) }, "seed \(seed), source \(s)")
            for v in 0 ..< n {
                guard let path = tree.path(to: v) else { continue }
                #expect(path.vertices.dropFirst().reduce(0) { $0 + cost[$1] } == tree.distance(to: v), "seed \(seed), \(s) → \(v)")
                #expect(path.edges.map { [$0.source, $0.target] } == zip(path.vertices, path.vertices.dropFirst()).map { [$0, $1] })
                #expect(path.edges.allSatisfy { rows[$0.source][$0.rank] == $0.target })
            }
        }
    }

    @Test("Breadth-first search calls the closure once per discovered vertex; Dijkstra at most twice per settled vertex")
    func searchCalls() {
        var calls = 0
        let n = 200
        let graph = ImplicitDirectedGraph(vertexCount: n, successors: { (v: Int) -> [Int] in
            calls += 1
            return v % 10 == 9 ? [] : [(v * 3 + 1) % n, (v + 1) % n, (v * 3 + 1) % n]
        })
        for source in [0, 9, 57] {
            calls = 0
            let discovered = graph.breadthFirstLayers(from: source).joined().count
            #expect(calls == discovered)
            calls = 0
            let descendants = graph.descendants(of: source)
            #expect(calls == discovered && descendants.union([source]).count == discovered)
            calls = 0
            let tree = graph.dijkstraShortestPaths(from: source) { $0.target % 3 + 1 }
            let settled = (0 ..< n).filter { tree.distance(to: $0) != nil }.count
            #expect(settled == discovered && calls <= 2 * settled)
        }
    }

    @Test("A LabeledGraph over an implicit grid names its cells")
    func labeledGrid() throws {
        struct Cell: Hashable {
            var row, column: Int
        }
        let width = 5, height = 4
        let cells = (0 ..< width * height).map { Cell(row: $0 / width, column: $0 % width) }
        // 4-neighbor grid, row-major numbering: the user writes the bijection.
        let grid = ImplicitDirectedGraph(vertexCount: width * height, successors: { (v: Int) -> [Int] in
            let (r, c) = (v / width, v % width)
            return [r > 0 ? v - width : -1, c > 0 ? v - 1 : -1, c < width - 1 ? v + 1 : -1, r < height - 1 ? v + width : -1].filter { $0 >= 0 }
        })
        let labeled = try LabeledGraph(grid, labels: cells)
        #expect(Array(labeled.vertices) == cells)
        #expect(Array(labeled.successors(of: Cell(row: 0, column: 0))) == [Cell(row: 0, column: 1), Cell(row: 1, column: 0)])
        #expect(labeled.outDegree(of: Cell(row: 2, column: 2)) == 4)
        #expect(labeled.edgeCount == 2 * (width - 1) * height + 2 * width * (height - 1))
        let layers = labeled.breadthFirstLayers(from: Cell(row: 0, column: 0))
        #expect(layers.count == width + height - 1)
        #expect(layers.enumerated().allSatisfy { k, layer in layer.allSatisfy { $0.row + $0.column == k } })
        #expect(labeled.stronglyConnectedComponents().count == 1)
    }

    @Test("Rows of any sequence type: a lazy filter and an Array give the same graph")
    func rowTypes() {
        let n = 30
        let lazy = ImplicitDirectedGraph(vertexCount: n, successors: { v in (0 ..< n).lazy.filter { ($0 * v + 3) % 7 == 0 } })
        let stored = ImplicitDirectedGraph(vertexCount: n, successors: { v in (0 ..< n).filter { ($0 * v + 3) % 7 == 0 } })
        let strided = ImplicitDirectedGraph(vertexCount: n, successors: { v in stride(from: v % 3, to: n, by: 7) })
        #expect(lazy.edges.map { [$0.source, $0.target] } == stored.edges.map { [$0.source, $0.target] })
        #expect(lazy.vertices.map { Array(lazy.successors(of: $0)) } == stored.vertices.map { Array(stored.successors(of: $0)) })
        #expect(lazy.stronglyConnectedComponents().map { Array($0) } == stored.stronglyConnectedComponents().map { Array($0) })
        #expect(lazy.breadthFirstLayers(from: 4) == stored.breadthFirstLayers(from: 4))
        #expect(Array(strided.successors(of: 4)) == [1, 8, 15, 22, 29] && strided.edgeCount == (0 ..< n).reduce(0) { $0 + Array(stride(from: $1 % 3, to: n, by: 7)).count })
        #expect(Array(strided.outEdges(of: 4)).map(\.rank) == [0, 1, 2, 3, 4])
    }
}
