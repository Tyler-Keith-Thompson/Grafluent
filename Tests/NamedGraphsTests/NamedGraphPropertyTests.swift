// Properties with shrinking (swift-property-based). Every family over a range of sizes, checked
// against its definition in api.md, written out in each test: the vertex and edge counts, the
// degree of every vertex, the edges in their pinned order, connectivity where the family is
// connected, and the directed form's orientation rule. Each test also builds the family on every
// conformer of both kinds and requires the same vertices and the same edges in the same order.
// See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import NamedGraphs
import PropertyBased
import StableGraphs
import Testing
import Trees

@Suite("NamedGraphs properties, with shrinking", .tags(.randomized))
struct NamedGraphPropertyTests {
    @Test("complete: every pair once in lexicographic order; directed, every ordered pair in row-major order")
    func complete() async {
        await propertyCheck(count: 60, input: Gen.int(in: 0 ... 40)) { n in
            var pairs: [[Int]] = []
            for u in 0 ..< n { for v in u + 1 ..< max(n, u + 1) { pairs.append([u, v]) } }
            var arcs: [[Int]] = []
            for u in 0 ..< n { for v in 0 ..< n where u != v { arcs.append([u, v]) } }
            let undirected: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.complete(vertexCount: n), Pseudograph<Int>.complete(vertexCount: n),
                                                Multigraph<Int>.complete(vertexCount: n)]
            for graph in undirected {
                #expect(graph.vertexCount == n && graph.edgeCount == n * (n - 1) / 2, "n \(n)")
                #expect(graph.edges.map { [$0.u, $0.v] } == pairs, "n \(n)")
                #expect((0 ..< n).allSatisfy { graph.degree(of: $0) == n - 1 }, "n \(n)")
            }
            let directed: [any DirectedGraph<Int>] = [CompressedSparseRow.complete(vertexCount: n), AdjacencyMatrix.complete(vertexCount: n),
                                                      AdjacencyList<Int>.complete(vertexCount: n), DirectedPseudograph<Int>.complete(vertexCount: n),
                                                      DirectedMultigraph<Int>.complete(vertexCount: n), StableDirectedGraph<Int>.complete(vertexCount: n)]
            for graph in directed {
                #expect(graph.vertexCount == n && graph.edgeCount == n * (n - 1), "n \(n)")
                #expect(graph.edges.map { [$0.source, $0.target] } == arcs, "n \(n)")
                #expect((0 ..< n).allSatisfy { graph.outDegree(of: $0) == max(n - 1, 0) }, "n \(n)")
            }
        }
    }

    @Test("completeBipartite: left 0..<a, right a..<a+b, every left–right pair; directed left → right; BipartiteGraph sides")
    func completeBipartite() async {
        await propertyCheck(count: 80, input: Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)) { a, b in
            var pairs: [[Int]] = []
            for u in 0 ..< a { for v in a ..< a + b { pairs.append([u, v]) } }
            let degrees = (0 ..< a + b).map { $0 < a ? b : a }
            let undirected: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.completeBipartite(leftCount: a, rightCount: b),
                                                Pseudograph<Int>.completeBipartite(leftCount: a, rightCount: b),
                                                Multigraph<Int>.completeBipartite(leftCount: a, rightCount: b),
                                                BipartiteGraph<Int>.completeBipartite(leftCount: a, rightCount: b)]
            for graph in undirected {
                #expect(graph.vertexCount == a + b && graph.edgeCount == a * b, "\(a), \(b)")
                #expect(Array(graph.vertices) == Array(0 ..< a + b), "\(a), \(b)")
                #expect(graph.edges.map { [$0.u, $0.v] } == pairs, "\(a), \(b)")
                #expect((0 ..< a + b).map { graph.degree(of: $0) } == degrees, "\(a), \(b)")
            }
            let bipartite = BipartiteGraph<Int>.completeBipartite(leftCount: a, rightCount: b)
            #expect(Array(bipartite.left) == Array(0 ..< a) && Array(bipartite.right) == Array(a ..< a + b), "\(a), \(b)")
            #expect(bipartite.edges.allSatisfy { bipartite.side(of: $0.u) != bipartite.side(of: $0.v) }, "\(a), \(b)")
            let directed: [any DirectedGraph<Int>] = [CompressedSparseRow.completeBipartite(leftCount: a, rightCount: b),
                                                      AdjacencyMatrix.completeBipartite(leftCount: a, rightCount: b),
                                                      AdjacencyList<Int>.completeBipartite(leftCount: a, rightCount: b),
                                                      DirectedPseudograph<Int>.completeBipartite(leftCount: a, rightCount: b),
                                                      DirectedMultigraph<Int>.completeBipartite(leftCount: a, rightCount: b),
                                                      StableDirectedGraph<Int>.completeBipartite(leftCount: a, rightCount: b)]
            for graph in directed {
                #expect(graph.vertexCount == a + b && graph.edgeCount == a * b, "\(a), \(b)")
                #expect(graph.edges.map { [$0.source, $0.target] } == pairs, "\(a), \(b)")
                #expect((0 ..< a + b).map { graph.outDegree(of: $0) } == (0 ..< a + b).map { $0 < a ? b : 0 }, "\(a), \(b)")
            }
        }
    }

    @Test("path, cycle, star and wheel: their edges, degrees and orientation; connected; Tree.path and Tree.star are trees")
    func pathCycleStarWheel() async {
        await propertyCheck(count: 80, input: Gen.int(in: 0 ... 50)) { n in
            func isConnected(_ graph: some Graph<Int>) -> Bool {
                guard graph.vertexCount > 0 else { return true }
                var seen: Set<Int> = [0], stack = [0]
                while let v = stack.popLast() {
                    for w in graph.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
                }
                return seen.count == graph.vertexCount
            }
            // Path.
            let path = (0 ..< max(n - 1, 0)).map { [$0, $0 + 1] }
            let paths: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.path(vertexCount: n), Pseudograph<Int>.path(vertexCount: n),
                                           Multigraph<Int>.path(vertexCount: n)]
            for graph in paths {
                #expect(graph.vertexCount == n && graph.edges.map { [$0.u, $0.v] } == path && isConnected(graph), "path \(n)")
                #expect((0 ..< n).map { graph.degree(of: $0) } == (0 ..< n).map { n == 1 ? 0 : ($0 == 0 || $0 == n - 1 ? 1 : 2) }, "path \(n)")
            }
            let directedPaths: [any DirectedGraph<Int>] = [CompressedSparseRow.path(vertexCount: n), AdjacencyMatrix.path(vertexCount: n),
                                                           AdjacencyList<Int>.path(vertexCount: n), DirectedPseudograph<Int>.path(vertexCount: n),
                                                           DirectedMultigraph<Int>.path(vertexCount: n), StableDirectedGraph<Int>.path(vertexCount: n)]
            for graph in directedPaths {
                #expect(graph.vertexCount == n && graph.edges.map { [$0.source, $0.target] } == path, "path \(n)")
            }
            if n >= 1 {
                let tree = Tree<Int>.path(vertexCount: n)
                #expect(tree.vertexCount == n && tree.edgeCount == n - 1 && isConnected(tree), "Tree.path \(n)")
                #expect(Set(tree.edges.map { [min($0.u, $0.v), max($0.u, $0.v)] }) == Set(path), "Tree.path \(n)")
                // Star.
                let star = (1 ..< n).map { [0, $0] }
                let stars: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.star(vertexCount: n), Pseudograph<Int>.star(vertexCount: n),
                                               Multigraph<Int>.star(vertexCount: n), Tree<Int>.star(vertexCount: n)]
                for graph in stars {
                    #expect(graph.vertexCount == n && Set(graph.edges.map { [min($0.u, $0.v), max($0.u, $0.v)] }) == Set(star) && isConnected(graph), "star \(n)")
                    #expect((0 ..< n).map { graph.degree(of: $0) } == [n - 1] + Array(repeating: 1, count: n - 1), "star \(n)")
                }
                for graph in stars.prefix(3) {
                    #expect(graph.edges.map { [$0.u, $0.v] } == star, "star \(n)")
                }
                let directedStars: [any DirectedGraph<Int>] = [CompressedSparseRow.star(vertexCount: n), AdjacencyMatrix.star(vertexCount: n),
                                                               AdjacencyList<Int>.star(vertexCount: n), DirectedPseudograph<Int>.star(vertexCount: n),
                                                               DirectedMultigraph<Int>.star(vertexCount: n), StableDirectedGraph<Int>.star(vertexCount: n)]
                for graph in directedStars {
                    #expect(graph.edges.map { [$0.source, $0.target] } == star, "star \(n)")
                }
            }
            if n >= 3 {
                // Cycle: the path plus the closing edge 0 – (n − 1), second in the list.
                let cycle = ([[0, 1], [0, n - 1]] + (1 ..< n - 1).map { [$0, $0 + 1] })
                let cycles: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.cycle(vertexCount: n), Pseudograph<Int>.cycle(vertexCount: n),
                                                Multigraph<Int>.cycle(vertexCount: n)]
                for graph in cycles {
                    #expect(graph.vertexCount == n && graph.edgeCount == n && isConnected(graph), "cycle \(n)")
                    #expect(graph.edges.map { [$0.u, $0.v] } == (n == 3 ? [[0, 1], [0, 2], [1, 2]] : cycle), "cycle \(n)")
                    #expect((0 ..< n).allSatisfy { graph.degree(of: $0) == 2 }, "cycle \(n)")
                }
                let arcs = (0 ..< n).map { [$0, ($0 + 1) % n] }.sorted { $0.lexicographicallyPrecedes($1) }
                let directedCycles: [any DirectedGraph<Int>] = [CompressedSparseRow.cycle(vertexCount: n), AdjacencyMatrix.cycle(vertexCount: n),
                                                                AdjacencyList<Int>.cycle(vertexCount: n), DirectedPseudograph<Int>.cycle(vertexCount: n),
                                                                DirectedMultigraph<Int>.cycle(vertexCount: n), StableDirectedGraph<Int>.cycle(vertexCount: n)]
                for graph in directedCycles {
                    #expect(graph.edges.map { [$0.source, $0.target] } == arcs, "cycle \(n)")
                    #expect((0 ..< n).allSatisfy { graph.outDegree(of: $0) == 1 }, "cycle \(n)")
                }
            }
            if n >= 4 {
                // Wheel: spokes 0 – i, rim 1 – 2 – … – (n − 1) – 1.
                var wheel = Set((1 ..< n).map { [0, $0] })
                for i in 1 ..< n - 1 { wheel.insert([i, i + 1]) }
                wheel.insert([1, n - 1])
                let sorted = wheel.sorted { $0.lexicographicallyPrecedes($1) }
                let wheels: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.wheel(vertexCount: n), Pseudograph<Int>.wheel(vertexCount: n),
                                                Multigraph<Int>.wheel(vertexCount: n)]
                for graph in wheels {
                    #expect(graph.vertexCount == n && graph.edgeCount == 2 * (n - 1) && isConnected(graph), "wheel \(n)")
                    #expect(graph.edges.map { [$0.u, $0.v] } == sorted, "wheel \(n)")
                    #expect((0 ..< n).map { graph.degree(of: $0) } == [n - 1] + Array(repeating: 3, count: n - 1), "wheel \(n)")
                }
                var arcs = (1 ..< n).map { [0, $0] } + (1 ..< n - 1).map { [$0, $0 + 1] }
                arcs.append([n - 1, 1])
                arcs.sort { $0.lexicographicallyPrecedes($1) }
                let directedWheels: [any DirectedGraph<Int>] = [CompressedSparseRow.wheel(vertexCount: n), AdjacencyMatrix.wheel(vertexCount: n),
                                                                AdjacencyList<Int>.wheel(vertexCount: n), DirectedPseudograph<Int>.wheel(vertexCount: n),
                                                                DirectedMultigraph<Int>.wheel(vertexCount: n), StableDirectedGraph<Int>.wheel(vertexCount: n)]
                for graph in directedWheels {
                    #expect(graph.edges.map { [$0.source, $0.target] } == arcs, "wheel \(n)")
                    #expect((0 ..< n).map { graph.outDegree(of: $0) } == [n - 1] + Array(repeating: 1, count: n - 1), "wheel \(n)")
                }
            }
        }
    }

    @Test("grid: row-major numbering, one coordinate changes by 1 (or wraps when periodic and the length is ≥ 3), the count and degree laws, both arcs")
    func grid() async {
        await propertyCheck(count: 200, input: Gen.int(in: 0 ... 5).array(of: 1 ... 3), Gen.bool) { dimensions, periodic in
            let n = dimensions.reduce(1, *)
            func coordinates(_ v: Int) -> [Int] {
                var x = Array(repeating: 0, count: dimensions.count), rest = v
                for i in dimensions.indices.reversed() {
                    x[i] = rest % dimensions[i]
                    rest /= dimensions[i]
                }
                return x
            }
            // The definition: every vertex, every dimension, the next coordinate and, when it wraps, the first.
            var expected: Set<[Int]> = []
            for v in 0 ..< n {
                let x = coordinates(v)
                var stride = 1
                for i in dimensions.indices.reversed() {
                    if x[i] + 1 < dimensions[i] { expected.insert([v, v + stride]) }
                    if periodic && dimensions[i] >= 3 && x[i] == 0 { expected.insert([v, v + (dimensions[i] - 1) * stride]) }
                    stride *= dimensions[i]
                }
            }
            let sorted = expected.sorted { $0.lexicographicallyPrecedes($1) }
            let degrees = (0 ..< n).map { v in
                coordinates(v).indices.reduce(0) { sum, i in
                    let d = dimensions[i], x = coordinates(v)[i]
                    return sum + (periodic && d >= 3 ? 2 : (x > 0 ? 1 : 0) + (x < d - 1 ? 1 : 0))
                }
            }
            let m = n == 0 ? 0 : dimensions.indices.reduce(0) { sum, i in
                sum + (periodic && dimensions[i] >= 3 ? dimensions[i] : dimensions[i] - 1) * (n / dimensions[i])
            }
            #expect(sorted.count == m, "\(dimensions)")
            let undirected: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.grid(dimensions: dimensions, periodic: periodic),
                                                Pseudograph<Int>.grid(dimensions: dimensions, periodic: periodic),
                                                Multigraph<Int>.grid(dimensions: dimensions, periodic: periodic)]
            for graph in undirected {
                #expect(graph.vertexCount == n && graph.edgeCount == m, "\(dimensions) periodic \(periodic)")
                #expect(graph.edges.map { [$0.u, $0.v] } == sorted, "\(dimensions) periodic \(periodic)")
                #expect((0 ..< n).map { graph.degree(of: $0) } == degrees, "\(dimensions) periodic \(periodic)")
            }
            if !periodic {
                #expect(UndirectedAdjacencyList<Int>.grid(dimensions: dimensions) == UndirectedAdjacencyList<Int>.grid(dimensions: dimensions, periodic: false))
            }
            // Connected whenever there is a vertex.
            if n > 0 {
                let graph = UndirectedAdjacencyList<Int>.grid(dimensions: dimensions, periodic: periodic)
                var seen: Set<Int> = [0], stack = [0]
                while let v = stack.popLast() {
                    for w in graph.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
                }
                #expect(seen.count == n, "\(dimensions)")
            }
            let arcs = (sorted + sorted.map { [$0[1], $0[0]] }).sorted { $0.lexicographicallyPrecedes($1) }
            let directed: [any DirectedGraph<Int>] = [CompressedSparseRow.grid(dimensions: dimensions, periodic: periodic),
                                                      AdjacencyMatrix.grid(dimensions: dimensions, periodic: periodic),
                                                      AdjacencyList<Int>.grid(dimensions: dimensions, periodic: periodic),
                                                      DirectedPseudograph<Int>.grid(dimensions: dimensions, periodic: periodic),
                                                      DirectedMultigraph<Int>.grid(dimensions: dimensions, periodic: periodic),
                                                      StableDirectedGraph<Int>.grid(dimensions: dimensions, periodic: periodic)]
            for graph in directed {
                #expect(graph.vertexCount == n && graph.edges.map { [$0.source, $0.target] } == arcs, "\(dimensions) periodic \(periodic)")
                #expect((0 ..< n).map { graph.outDegree(of: $0) } == degrees, "\(dimensions) periodic \(periodic)")
            }
        }
    }

    @Test("hypercube: 2^d vertices, u – u ^ (1 << k), d-regular, d·2^(d−1) edges, connected; both arcs")
    func hypercube() async {
        await propertyCheck(count: 30, input: Gen.int(in: 0 ... 9)) { d in
            let n = 1 << d
            var expected: [[Int]] = []
            for u in 0 ..< n { for k in 0 ..< d where u & (1 << k) == 0 { expected.append([u, u | (1 << k)]) } }
            expected.sort { $0.lexicographicallyPrecedes($1) }
            #expect(expected.count == d * n / 2)
            let undirected: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.hypercube(dimension: d), Pseudograph<Int>.hypercube(dimension: d),
                                                Multigraph<Int>.hypercube(dimension: d)]
            for graph in undirected {
                #expect(graph.vertexCount == n && graph.edges.map { [$0.u, $0.v] } == expected, "Q\(d)")
                #expect((0 ..< n).allSatisfy { graph.degree(of: $0) == d }, "Q\(d)")
            }
            let graph = UndirectedAdjacencyList<Int>.hypercube(dimension: d)
            var seen: Set<Int> = [0], stack = [0]
            while let v = stack.popLast() {
                for w in graph.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
            }
            #expect(seen.count == n, "Q\(d)")
            let arcs = (expected + expected.map { [$0[1], $0[0]] }).sorted { $0.lexicographicallyPrecedes($1) }
            let directed: [any DirectedGraph<Int>] = [CompressedSparseRow.hypercube(dimension: d), AdjacencyMatrix.hypercube(dimension: d),
                                                      AdjacencyList<Int>.hypercube(dimension: d), DirectedPseudograph<Int>.hypercube(dimension: d),
                                                      DirectedMultigraph<Int>.hypercube(dimension: d), StableDirectedGraph<Int>.hypercube(dimension: d)]
            for graph in directed {
                #expect(graph.vertexCount == n && graph.edges.map { [$0.source, $0.target] } == arcs, "Q\(d)")
            }
        }
    }

    @Test("petersen: strongly regular (10, 3, 0, 1): adjacent vertices share no neighbour, non-adjacent ones exactly one")
    func petersen() {
        let undirected: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.petersen(), Pseudograph<Int>.petersen(), Multigraph<Int>.petersen()]
        for graph in undirected {
            #expect(graph.vertexCount == 10 && graph.edgeCount == 15)
            for u in 0 ..< 10 {
                #expect(graph.degree(of: u) == 3)
                for v in u + 1 ..< 10 {
                    let common = Set(graph.neighbors(of: u)).intersection(graph.neighbors(of: v)).count
                    #expect(common == (graph.contains(edge: UndirectedEdge(u, v)) ? 0 : 1), "\(u), \(v)")
                }
            }
            // NetworkX's numbering: outer cycle 0–1–2–3–4, spokes i – i + 5, inner pentagram 5–7–9–6–8.
            for i in 0 ..< 5 {
                #expect(graph.contains(edge: UndirectedEdge(i, (i + 1) % 5)) && graph.contains(edge: UndirectedEdge(i, i + 5)))
                #expect(graph.contains(edge: UndirectedEdge(5 + i, 5 + (i + 2) % 5)))
            }
        }
        let undirectedEdges = UndirectedAdjacencyList<Int>.petersen().edges.map { [$0.u, $0.v] }
        let arcs = (undirectedEdges + undirectedEdges.map { [$0[1], $0[0]] }).sorted { $0.lexicographicallyPrecedes($1) }
        let directed: [any DirectedGraph<Int>] = [CompressedSparseRow.petersen(), AdjacencyMatrix.petersen(), AdjacencyList<Int>.petersen(),
                                                  DirectedPseudograph<Int>.petersen(), DirectedMultigraph<Int>.petersen(), StableDirectedGraph<Int>.petersen()]
        for graph in directed {
            #expect(graph.vertexCount == 10 && graph.edges.map { [$0.source, $0.target] } == arcs)
        }
    }

    @Test("empty: n isolated vertices 0..<n on every conformer")
    func empty() async {
        await propertyCheck(count: 40, input: Gen.int(in: 0 ... 100)) { n in
            let undirected: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.empty(vertexCount: n), Pseudograph<Int>.empty(vertexCount: n),
                                                Multigraph<Int>.empty(vertexCount: n)]
            for graph in undirected {
                #expect(graph.vertexCount == n && graph.edgeCount == 0 && Array(graph.vertices) == Array(0 ..< n), "n \(n)")
            }
            let directed: [any DirectedGraph<Int>] = [CompressedSparseRow.empty(vertexCount: n), AdjacencyMatrix.empty(vertexCount: n),
                                                      AdjacencyList<Int>.empty(vertexCount: n), DirectedPseudograph<Int>.empty(vertexCount: n),
                                                      DirectedMultigraph<Int>.empty(vertexCount: n), StableDirectedGraph<Int>.empty(vertexCount: n)]
            for graph in directed {
                #expect(graph.vertexCount == n && graph.edgeCount == 0 && Array(graph.vertices) == Array(0 ..< n), "n \(n)")
            }
        }
    }

    @Test("A generated graph is an ordinary value: equal to the same graph built edge by edge, and mutable afterwards")
    func ordinaryValues() async {
        await propertyCheck(count: 40, input: Gen.int(in: 3 ... 30)) { n in
            let cycle = UndirectedAdjacencyList<Int>.cycle(vertexCount: n)
            var built = UndirectedAdjacencyList<Int>(vertices: 0 ..< n)
            for i in 0 ..< n { built.insert(edge: UndirectedEdge(i, (i + 1) % n)) }
            #expect(cycle == built && cycle.hashValue == built.hashValue, "n \(n)")
            var grown = cycle
            grown.insert(edge: UndirectedEdge(0, n))
            #expect(grown.vertexCount == n + 1 && grown.edgeCount == n + 1 && cycle.edgeCount == n, "n \(n)")
            let csr = CompressedSparseRow.complete(vertexCount: n)
            #expect(csr == CompressedSparseRow(AdjacencyMatrix.complete(vertexCount: n)), "n \(n)")
            #expect(AdjacencyMatrix(vertexCount: n, repeating: true).edges.filter { $0.source != $0.target }.map { [$0.source, $0.target] }
                    == AdjacencyMatrix.complete(vertexCount: n).edges.map { [$0.source, $0.target] }, "n \(n)")
        }
    }
}
