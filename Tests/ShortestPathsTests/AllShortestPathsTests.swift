// Every shortest path from a source to a target (`allShortestPaths`), weighted and unweighted:
// NetworkX's cases, a grid, zero-weight edges into the target and zero-weight cycles, parallel
// edges, the trivial and empty cases, every vertex-lookup path, and a property test against
// brute force. The listing order is unspecified, so paths are compared as sets. Case IDs (SP-nn)
// refer to the catalog; see README.md.

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

@Suite("All shortest paths")
struct AllShortestPathsTests {
    @Test("SP-170 NetworkX's two routes from 0 to 3, undirected", .tags(.fixture))
    func twoRoutes() {
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(0, 10), UndirectedEdge(10, 20), UndirectedEdge(20, 3)]
        let graph = UndirectedAdjacencyList(edges: edges)
        let paths = graph.allShortestPaths(from: 0, to: 3)
        #expect(paths.distance == 3)
        #expect(Set(paths.map(\.vertices)) == [[0, 1, 2, 3], [0, 10, 20, 3]])
        let weighted = graph.allShortestPaths(from: 0, to: 3) { _ in 2 }
        #expect(weighted.distance == 6)
        #expect(Set(weighted.map(\.vertices)) == [[0, 1, 2, 3], [0, 10, 20, 3]])
        #expect(Set(ReferencePseudograph(edges: edges).allShortestPaths(from: 3, to: 0).map(\.vertices)) == [[3, 2, 1, 0], [3, 20, 10, 0]])
    }

    @Test("SP-171 the 3 × 3 grid corner to corner: the six monotone paths, each listed once", .tags(.fixture))
    func grid() {
        var edges: [UndirectedEdge<Int>] = []
        for r in 0 ..< 3 {
            for c in 0 ..< 3 {
                if c < 2 { edges.append(UndirectedEdge(r * 3 + c, r * 3 + c + 1)) }
                if r < 2 { edges.append(UndirectedEdge(r * 3 + c, r * 3 + c + 3)) }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 9, edges: edges)
        let paths = Array(graph.allShortestPaths(from: 0, to: 8))
        #expect(paths.count == 6)
        #expect(Set(paths.map(\.vertices)) == [[0, 1, 2, 5, 8], [0, 1, 4, 5, 8], [0, 1, 4, 7, 8], [0, 3, 4, 5, 8], [0, 3, 4, 7, 8], [0, 3, 6, 7, 8]])
        // Each arc is the edge it crosses, oriented.
        let view = graph.directedView
        for p in paths {
            #expect(zip(p.edges, p.vertices).allSatisfy { view.source(ofEdgeAt: $0) == $1 })
        }
        let directed = CompressedSparseRow(vertexCount: 9, edges: edges.map { DirectedEdge(from: $0.u, to: $0.v) })
        #expect(Array(directed.allShortestPaths(from: 0, to: 8) { _ in 1 }).count == 6)
        #expect(Array(directed.allShortestPaths(from: 8, to: 0)).isEmpty)
    }

    @Test("SP-172 Yen's example: one weighted shortest path, three unweighted, on indexed, numbered and unindexed graphs", .tags(.fixture))
    func yensExample() {
        let yen: [(String, String, Int)] = [
            ("C", "D", 3), ("C", "E", 2), ("D", "F", 4), ("E", "D", 1), ("E", "F", 2), ("E", "G", 3),
            ("F", "G", 2), ("F", "H", 1), ("G", "H", 2),
        ]
        let edges = yen.map { DirectedEdge(from: $0.0, to: $0.1) }
        func check<G: DirectedGraph<String>>(_ g: G, _ weight: (G.Edges.Index) -> Int) {
            let weighted = g.allShortestPaths(from: "C", to: "H", weight: weight)
            #expect(weighted.distance == 5)
            #expect(weighted.map(\.vertices) == [["C", "E", "F", "H"]])
            let hops = g.allShortestPaths(from: "C", to: "H")
            #expect(hops.distance == 3)
            #expect(Set(hops.map(\.vertices)) == [["C", "D", "F", "H"], ["C", "E", "F", "H"], ["C", "E", "G", "H"]])
            for p in hops {
                #expect(zip(p.edges, zip(p.vertices, p.vertices.dropFirst())).allSatisfy { g.source(ofEdgeAt: $0) == $1.0 && g.target(ofEdgeAt: $0) == $1.1 })
            }
        }
        let list = AdjacencyList(edges: edges)
        check(list) { p in yen.first { $0.0 == list.source(ofEdgeAt: p) && $0.1 == list.target(ofEdgeAt: p) }!.2 }
        check(ReferenceDirectedMultigraph(edges: edges)) { yen[$0].2 }
        check(PlainDigraph(vertices: ["C", "D", "E", "F", "G", "H"], edges: edges)) { yen[$0].2 }
        var stable = StableDirectedGraph(vertices: ["gone"], edges: edges)
        _ = stable.remove("gone")
        check(stable) { p in yen.first { $0.0 == stable.source(ofEdgeAt: p) && $0.1 == stable.target(ofEdgeAt: p) }!.2 }
    }

    @Test("SP-173 trivial, unreachable and single-path cases", .tags(.selfLoops))
    func edgeCases() {
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 1)])
        let itself = graph.allShortestPaths(from: 0, to: 0) { _ in 1 }
        #expect(itself.distance == 0)
        #expect(itself.map(\.vertices) == [[0]])
        #expect(graph.allShortestPaths(from: 1, to: 1).map(\.vertices) == [[1]])
        let none = graph.allShortestPaths(from: 0, to: 2) { _ in 1 }
        #expect(none.distance == nil)
        #expect(Array(none).isEmpty)
        #expect(graph.allShortestPaths(from: 1, to: 0).distance == nil)
        #expect(Array(graph.allShortestPaths(from: 1, to: 0)).isEmpty)
        // A zero-weight self-loop is on no path.
        #expect(graph.allShortestPaths(from: 0, to: 1) { _ in 0 }.map(\.vertices) == [[0, 1]])
        let single = CompressedSparseRow(vertexCount: 1)
        #expect(single.allShortestPaths(from: 0, to: 0).map(\.vertices) == [[0]])
        // A new iterator starts over.
        let twice = graph.allShortestPaths(from: 0, to: 1)
        #expect(Array(twice).count == 1 && Array(twice).count == 1)
    }

    @Test("SP-174 zero weights: edges into the target from its own distance, and zero-weight cycles", .tags(.selfLoops))
    func zeroWeights() {
        // 0→1 (1), 0→2 (1), 1→2 (0), 2→1 (0), 1→3 (1), 2→3 (1): d(3) = 2, through 1 or 2, each
        // reached directly or across the zero-weight 2-cycle.
        let edges = [(0, 1, 1), (0, 2, 1), (1, 2, 0), (2, 1, 0), (1, 3, 1), (2, 3, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 4, edges: edges.map { DirectedEdge(from: $0.0, to: $0.1) })
        let paths = graph.allShortestPaths(from: 0, to: 3) { edges[$0].2 }
        #expect(paths.distance == 2)
        #expect(Set(paths.map(\.vertices)) == [[0, 1, 3], [0, 2, 3], [0, 1, 2, 3], [0, 2, 1, 3]])
        // The target's distance is shared by a vertex with a zero-weight edge into it.
        let late = [(0, 1, 1), (0, 2, 1), (2, 1, 0)]
        let lateGraph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: late.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Set(lateGraph.allShortestPaths(from: 0, to: 1) { late[$0].2 }.map(\.vertices)) == [[0, 1], [0, 2, 1]])
        // A zero-weight cycle through the source.
        let back = [(0, 1, 0), (1, 0, 0), (1, 2, 1)]
        let backGraph = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: back.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(backGraph.allShortestPaths(from: 0, to: 2) { back[$0].2 }.map(\.vertices) == [[0, 1, 2]])
    }

    @Test("SP-175 parallel edges of equal weight give distinct paths; a heavier copy gives none")
    func parallelEdges() {
        var graph = DirectedPseudograph<Int>(vertices: 0 ..< 3)
        let a = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let b = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let c = graph.insert(edge: DirectedEdge(from: 1, to: 2))
        let d = graph.insert(edge: DirectedEdge(from: 1, to: 2))
        let weights = [a: 1, b: 1, c: 1, d: 2]
        #expect(Set(graph.allShortestPaths(from: 0, to: 2) { weights[$0]! }.map(\.edges)) == [[a, c], [b, c]])
        #expect(Set(graph.allShortestPaths(from: 0, to: 2).map(\.edges)) == [[a, c], [a, d], [b, c], [b, d]])
    }

    @Test("SP-176 a negative examined weight traps", .tags(.precondition))
    func negativeTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.allShortestPaths(from: 0, to: 1) { _ in -1 }
        }
        await #expect(processExitsWith: .failure) {
            let graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.allShortestPaths(from: 0, to: 9)
        }
    }

    @Test("SP-177 every shortest path against brute force, weighted and unweighted, directed and undirected", .tags(.randomized))
    func againstBruteForce() async {
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 3)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)) { raw, s, t in
            // Brute force: every simple path as its edge positions, directed and undirected.
            func simplePaths(undirected: Bool) -> [[Int]] {
                var found: [[Int]] = []
                var onPath = [s]
                var steps: [Int] = []
                func extend(_ u: Int) {
                    if u == t {
                        found.append(steps)
                        return
                    }
                    for (k, e) in raw.enumerated() {
                        let v: Int
                        if e.0 == u { v = e.1 } else if undirected && e.1 == u { v = e.0 } else { continue }
                        guard !onPath.contains(v) else { continue }
                        onPath.append(v)
                        steps.append(k)
                        extend(v)
                        steps.removeLast()
                        onPath.removeLast()
                    }
                }
                extend(s)
                return found
            }
            func shortest(_ paths: [[Int]], _ length: ([Int]) -> Int) -> (Int?, Set<[Int]>) {
                guard let best = paths.map(length).min() else { return (nil, []) }
                return (best, Set(paths.filter { length($0) == best }))
            }
            let weight = { (path: [Int]) in path.map { raw[$0].2 }.reduce(0, +) }
            let directed = ReferenceDirectedMultigraph(vertices: 0 ..< 5, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let directedPaths = simplePaths(undirected: false)
            let (d, expected) = shortest(directedPaths, weight)
            let found = directed.allShortestPaths(from: s, to: t) { raw[$0].2 }
            #expect(found.distance == d)
            #expect(Array(found).count == expected.count)
            #expect(Set(found.map(\.edges)) == expected)
            let (h, hops) = shortest(directedPaths, \.count)
            let foundHops = directed.allShortestPaths(from: s, to: t)
            #expect(foundHops.distance == h)
            #expect(Array(foundHops).count == hops.count)
            #expect(Set(foundHops.map(\.edges)) == hops)
            let undirected = ReferencePseudograph(vertices: 0 ..< 5, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let (u, both) = shortest(simplePaths(undirected: true), weight)
            let foundBoth = undirected.allShortestPaths(from: s, to: t) { raw[$0].2 }
            #expect(foundBoth.distance == u)
            #expect(Array(foundBoth).count == both.count)
            #expect(Set(foundBoth.map { $0.edges.map(\.position) }) == both)
        }
    }
}
