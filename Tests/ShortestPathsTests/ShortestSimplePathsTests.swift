// Yen's k shortest simple paths (`shortestSimplePaths`): hand-computed cases from NetworkX and
// Yen's example, the trivial and empty cases, self-loops, parallel edges, undirected graphs, every
// vertex-lookup path (indices, a stable graph with a hole, no indices), laziness and weight calls,
// and a property test against brute-force enumeration. Paths of equal length come in an
// unspecified order, so ties are compared as sets. Case IDs (SP-nn) refer to the catalog; see
// README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Multigraphs
import PropertyBased
import ShortestPaths
import StableGraphs
import Testing

/// A directed multigraph with no vertex indices, so the searches number its vertices themselves.
private struct PlainDigraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Shortest simple paths (Yen)")
struct ShortestSimplePathsTests {
    @Test("SP-160 NetworkX's cycle_graph(7) from 0 to 3: two paths, directions told apart", .tags(.fixture))
    func cycleGraph() {
        let edges = (0 ..< 7).map { UndirectedEdge($0, ($0 + 1) % 7) }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: edges)
        let unweighted = Array(graph.shortestSimplePaths(from: 0, to: 3))
        #expect(unweighted.map(\.path.vertices) == [[0, 1, 2, 3], [0, 6, 5, 4, 3]])
        #expect(unweighted.map(\.distance) == [3, 4])
        let weighted = Array(graph.shortestSimplePaths(from: 0, to: 3) { _ in 1 })
        #expect(weighted.map(\.path.vertices) == [[0, 1, 2, 3], [0, 6, 5, 4, 3]])
        // Each arc says which way the edge was taken.
        let second = weighted[1].path
        #expect(second.edges.map { graph.directedView.source(ofEdgeAt: $0) } == [0, 6, 5, 4])
        let reference = ReferencePseudograph(vertices: 0 ..< 7, edges: edges)
        #expect(Array(reference.shortestSimplePaths(from: 0, to: 3)).map(\.path.vertices) == [[0, 1, 2, 3], [0, 6, 5, 4, 3]])
    }

    @Test("SP-161 Yen's example: every simple C–H path in order of length, on indexed, numbered and unindexed graphs", .tags(.fixture))
    func yensExample() {
        let yen: [(String, String, Int)] = [
            ("C", "D", 3), ("C", "E", 2), ("D", "F", 4), ("E", "D", 1), ("E", "F", 2), ("E", "G", 3),
            ("F", "G", 2), ("F", "H", 1), ("G", "H", 2),
        ]
        let byLength: [Int: Set<[String]>] = [
            5: [["C", "E", "F", "H"]],
            7: [["C", "E", "G", "H"]],
            8: [["C", "D", "F", "H"], ["C", "E", "D", "F", "H"], ["C", "E", "F", "G", "H"]],
            11: [["C", "D", "F", "G", "H"], ["C", "E", "D", "F", "G", "H"]],
        ]
        func check<G: DirectedGraph<String>>(_ g: G, _ weight: (G.Edges.Index) -> Int) {
            let paths = Array(g.shortestSimplePaths(from: "C", to: "H", weight: weight))
            #expect(paths.map(\.distance) == [5, 7, 8, 8, 8, 11, 11])
            var listed: [Int: Set<[String]>] = [:]
            for p in paths { listed[p.distance, default: []].insert(p.path.vertices) }
            #expect(listed == byLength)
            for p in paths {
                #expect(p.path.edges.map(weight).reduce(0, +) == p.distance)
                #expect(zip(p.path.edges, zip(p.path.vertices, p.path.vertices.dropFirst())).allSatisfy { e, step in
                    g.source(ofEdgeAt: e) == step.0 && g.target(ofEdgeAt: e) == step.1
                })
            }
        }
        let edges = yen.map { DirectedEdge(from: $0.0, to: $0.1) }
        let list = AdjacencyList(edges: edges)
        let listWeights = list.edges.map { e in yen.first { $0.0 == e.source && $0.1 == e.target }!.2 }
        check(list) { listWeights[$0] }
        check(ReferenceDirectedMultigraph(edges: edges)) { yen[$0].2 }
        check(PlainDigraph(vertices: ["C", "D", "E", "F", "G", "H"], edges: edges)) { yen[$0].2 }
        var stable = StableDirectedGraph(vertices: ["gone"], edges: edges)
        _ = stable.remove("gone")
        check(stable) { p in yen.first { $0.0 == stable.source(ofEdgeAt: p) && $0.1 == stable.target(ofEdgeAt: p) }!.2 }
        // The prefix is Yen's three shortest.
        #expect(list.shortestSimplePaths(from: "C", to: "H") { listWeights[$0] }.prefix(3).map(\.distance) == [5, 7, 8])
    }

    @Test("SP-162 NetworkX's XG from s to v: the six simple paths in order", .tags(.fixture))
    func networkXXG() {
        let xg: [(String, String, Int)] = [
            ("s", "u", 10), ("s", "x", 5), ("u", "v", 1), ("u", "x", 2), ("v", "y", 1),
            ("x", "u", 3), ("x", "v", 5), ("x", "y", 2), ("y", "s", 7), ("y", "v", 6),
        ]
        let graph = ReferenceDirectedMultigraph(edges: xg.map { DirectedEdge(from: $0.0, to: $0.1) })
        let paths = Array(graph.shortestSimplePaths(from: "s", to: "v") { xg[$0].2 })
        #expect(paths.map(\.path.vertices) == [
            ["s", "x", "u", "v"], ["s", "x", "v"], ["s", "u", "v"], ["s", "x", "y", "v"], ["s", "u", "x", "v"], ["s", "u", "x", "y", "v"],
        ])
        #expect(paths.map(\.distance) == [9, 10, 11, 13, 17, 20])
        #expect(paths[0].path.edges == [1, 5, 2])
    }

    @Test("SP-163 the 3 × 3 grid corner to corner, unweighted: 6 of length 4, 4 of 6, 2 of 8", .tags(.fixture))
    func grid() {
        var edges: [UndirectedEdge<Int>] = []
        for r in 0 ..< 3 {
            for c in 0 ..< 3 {
                if c < 2 { edges.append(UndirectedEdge(r * 3 + c, r * 3 + c + 1)) }
                if r < 2 { edges.append(UndirectedEdge(r * 3 + c, r * 3 + c + 3)) }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: edges)
        let paths = Array(graph.shortestSimplePaths(from: 0, to: 8))
        #expect(paths.map(\.distance) == [4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 8, 8])
        #expect(Set(paths.map(\.path.vertices)).count == 12)
        #expect(Set(paths.filter { $0.distance == 8 }.map(\.path.vertices)) == [[0, 1, 2, 5, 4, 3, 6, 7, 8], [0, 3, 6, 7, 4, 1, 2, 5, 8]])
        // Directed right and down only: the six monotone paths.
        let directed = CompressedSparseRow(vertexCount: 9, edges: edges.map { DirectedEdge(from: $0.u, to: $0.v) })
        #expect(Array(directed.shortestSimplePaths(from: 0, to: 8)).map(\.distance) == [4, 4, 4, 4, 4, 4])
        #expect(Array(directed.shortestSimplePaths(from: 0, to: 8) { _ in 2 }).map(\.distance) == [8, 8, 8, 8, 8, 8])
    }

    @Test("SP-164 the trivial path alone from a vertex to itself, nothing when unreachable", .tags(.selfLoops))
    func trivialAndUnreachable() {
        let graph = AdjacencyList(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1)])
        let itself = Array(graph.shortestSimplePaths(from: 0, to: 0) { _ in 1 })
        #expect(itself.map(\.path.vertices) == [[0]])
        #expect(itself.map(\.distance) == [0])
        #expect(Array(graph.shortestSimplePaths(from: 1, to: 1)).map(\.path.vertices) == [[1]])
        #expect(Array(graph.shortestSimplePaths(from: 0, to: 3) { _ in 1 }).isEmpty)
        #expect(Array(graph.shortestSimplePaths(from: 0, to: 2)).isEmpty)
        // The self-loop is on no simple path.
        #expect(Array(graph.shortestSimplePaths(from: 0, to: 1)).map(\.path.vertices) == [[0, 1]])
        let single = CompressedSparseRow(vertexCount: 1)
        #expect(Array(single.shortestSimplePaths(from: 0, to: 0)).map(\.distance) == [0])
    }

    @Test("SP-165 parallel edges give distinct paths, in order of their weights")
    func parallelEdges() {
        var graph = DirectedPseudograph<Int>(vertices: 0 ..< 3)
        let a = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let b = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let c = graph.insert(edge: DirectedEdge(from: 1, to: 2))
        let d = graph.insert(edge: DirectedEdge(from: 0, to: 2))
        let weights = [a: 3, b: 1, c: 1, d: 5]
        let paths = Array(graph.shortestSimplePaths(from: 0, to: 2) { weights[$0]! })
        #expect(paths.map(\.path.edges) == [[b, c], [a, c], [d]])
        #expect(paths.map(\.distance) == [2, 4, 5])
        // Unweighted: one edge first, then the two two-edge paths.
        let unweighted = Array(graph.shortestSimplePaths(from: 0, to: 2))
        #expect(unweighted.map(\.distance) == [1, 2, 2])
        #expect(Set(unweighted.dropFirst().map(\.path.edges)) == [[a, c], [b, c]])
        // Undirected parallel edges.
        var undirected = Pseudograph<Int>(vertices: 0 ..< 2)
        let e = undirected.insert(edge: UndirectedEdge(0, 1))
        let f = undirected.insert(edge: UndirectedEdge(0, 1))
        let both = Array(undirected.shortestSimplePaths(from: 1, to: 0) { $0 == e ? 2 : 1 })
        #expect(both.map { $0.path.edges.map(\.position) } == [[f], [e]])
        #expect(both.map(\.distance) == [1, 2])
    }

    @Test("SP-166 lazy: weights are read once each when the sequence is made, and each iterator starts over")
    func laziness() {
        // A ladder with 60 rungs has 2^59 simple paths corner to corner; only a prefix is listed.
        var edges: [DirectedEdge<Int>] = []
        for i in 0 ..< 59 {
            edges.append(DirectedEdge(from: 2 * i, to: 2 * i + 2))
            edges.append(DirectedEdge(from: 2 * i + 1, to: 2 * i + 3))
            edges.append(DirectedEdge(from: 2 * i, to: 2 * i + 3))
            edges.append(DirectedEdge(from: 2 * i + 1, to: 2 * i + 2))
        }
        let graph = CompressedSparseRow(vertexCount: 120, edges: edges)
        var calls = 0
        let paths = graph.shortestSimplePaths(from: 0, to: 118) { _ in
            calls += 1
            return 1
        }
        #expect(calls == graph.edgeCount)
        let first = paths.prefix(5).map(\.distance)
        #expect(first == [59, 59, 59, 59, 59])
        #expect(calls == graph.edgeCount)
        var iterator = paths.makeIterator()
        #expect(iterator.next()?.path == paths.first { _ in true }?.path)
    }

    @Test("SP-167 a negative weight traps when the sequence is made", .tags(.precondition))
    func negativeTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 3)])
            _ = graph.shortestSimplePaths(from: 0, to: 1) { $0 == 0 ? 1 : -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.shortestSimplePaths(from: 0, to: 7) { _ in 1 }
        }
    }

    @Test("SP-168 every simple path, in nondecreasing length, against brute force: directed with parallel edges and loops", .tags(.randomized))
    func directedAgainstBruteForce() async {
        // Up to 12 edges on 5 vertices, weights 0...4 (zeros make ties), any source and target.
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)) { raw, s, t in
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Brute force: every simple path as its edge positions, depth first.
            var all: [[Int]: (weighted: Int, hops: Int)] = [:]
            var onPath = [s]
            var steps: [Int] = []
            func extend(_ u: Int) {
                if u == t {
                    all[steps] = (steps.map { raw[$0].2 }.reduce(0, +), steps.count)
                    return
                }
                for (k, e) in raw.enumerated() where e.0 == u && !onPath.contains(e.1) {
                    onPath.append(e.1)
                    steps.append(k)
                    extend(e.1)
                    steps.removeLast()
                    onPath.removeLast()
                }
            }
            extend(s)
            let weighted = Array(graph.shortestSimplePaths(from: s, to: t) { raw[$0].2 })
            #expect(weighted.count == all.count)
            #expect(Set(weighted.map(\.path.edges)) == Set(all.keys))
            #expect(weighted.map(\.distance) == all.values.map(\.weighted).sorted())
            #expect(weighted.allSatisfy { all[$0.path.edges]?.weighted == $0.distance && $0.path.vertices.first == s && $0.path.vertices.last == t })
            let hops = Array(graph.shortestSimplePaths(from: s, to: t))
            #expect(Set(hops.map(\.path.edges)) == Set(all.keys))
            #expect(hops.map(\.distance) == all.values.map(\.hops).sorted())
        }
    }

    @Test("SP-169 every simple path against brute force, undirected", .tags(.randomized))
    func undirectedAgainstBruteForce() async {
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 9)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)) { raw, s, t in
            let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            var all: [[Int]: Int] = [:]
            var onPath = [s]
            var steps: [Int] = []
            func extend(_ u: Int) {
                if u == t {
                    all[steps] = steps.map { raw[$0].2 }.reduce(0, +)
                    return
                }
                for (k, e) in raw.enumerated() where e.0 != e.1 && (e.0 == u || e.1 == u) {
                    let v = e.0 == u ? e.1 : e.0
                    guard !onPath.contains(v) else { continue }
                    onPath.append(v)
                    steps.append(k)
                    extend(v)
                    steps.removeLast()
                    onPath.removeLast()
                }
            }
            extend(s)
            let paths = Array(graph.shortestSimplePaths(from: s, to: t) { raw[$0].2 })
            #expect(paths.count == all.count)
            #expect(Set(paths.map { $0.path.edges.map(\.position) }) == Set(all.keys))
            #expect(paths.map(\.distance) == all.values.sorted())
        }
    }
}
