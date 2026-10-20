// minimumCycleBasis() and minimumCycleBasis(weight:): de Pina's minimum cycle basis. Hand-computed
// cases where the fundamental basis is not minimum (a triangle sharing an edge with a square, K₄,
// a wheel, a grid, a theta graph), degenerate graphs (empty, forests, loops, parallel copies,
// several components), weights that pick a heavier but shorter cycle away, several
// representations, and a property test against the greedy oracle: every simple cycle sorted by
// weight, each kept when independent over GF(2) of those kept before, which is a minimum basis by
// the matroid greedy rule; its total weight must be the library's, and the library's cycles must
// be simple cycles of the graph, independent, and m − n + c in number.

import AdjacencyListModule
import AdjacencyMatrixModule
import Cycles
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Walks

@Suite("Minimum cycle basis")
struct MinimumCycleBasisTests {
    @Test("A triangle sharing an edge with a square: the triangle and the square, not the fundamental pentagon")
    func triangleAndSquare() {
        // 0-1-2 is the triangle; 1-2-3-4 is the square, sharing 1-2 (position 1).
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 1),
        ])
        let basis = graph.minimumCycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [1, 2, 3, 4]])
        #expect(basis.map(\.edges) == [[0, 1, 2], [1, 3, 4, 5]])
        #expect(basis.reduce(0) { $0 + $1.edges.count } == 7)
        // Rooted at 4, the breadth-first fundamental basis is {4-1-0-2-3 … } heavier than 7 in total
        // when the shared edge is the tree edge missed; the minimum basis does not depend on roots.
        let rotated = ReferencePseudograph(vertices: [4, 3, 2, 1, 0], edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 1),
        ])
        #expect(rotated.minimumCycleBasis().reduce(0) { $0 + $1.edges.count } == 7)
        #expect(Set(rotated.minimumCycleBasis().map { Set($0.vertices) }) == [[0, 1, 2], [1, 2, 3, 4]])
    }

    @Test("K₄: three triangles (9 edges in total), as many as the fundamental basis of the star tree")
    func completeFour() {
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< 4 { for j in i + 1 ..< 4 { edges.append(UndirectedEdge(i, j)) } }
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: edges)
        let basis = graph.minimumCycleBasis()
        #expect(basis.count == 3)
        #expect(basis.allSatisfy { $0.edges.count == 3 })
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1, 3], [0, 2, 3]])
        #expect(graph.cycleBasis().reduce(0) { $0 + $1.edges.count } == 9)
        // Every cycle of the basis is a cycle of the graph.
        for cycle in basis { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil) }
    }

    @Test("A wheel W₅: the five triangles of the hub, never the rim")
    func wheel() {
        var edges: [UndirectedEdge<Int>] = []
        for i in 1 ... 5 { edges.append(UndirectedEdge(i, i % 5 + 1)) }
        for i in 1 ... 5 { edges.append(UndirectedEdge(0, i)) }
        let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: edges)
        let basis = graph.minimumCycleBasis()
        #expect(basis.count == 5)
        #expect(basis.allSatisfy { $0.edges.count == 3 && $0.vertices.contains(0) })
        #expect(Set(basis.map { Set($0.vertices) }) == [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 1]])
    }

    @Test("A 3 × 3 grid: the four squares; a theta graph: its two shortest cycles")
    func gridAndTheta() {
        var edges: [UndirectedEdge<Int>] = []
        for r in 0 ..< 3 {
            for c in 0 ..< 3 {
                if c + 1 < 3 { edges.append(UndirectedEdge(3 * r + c, 3 * r + c + 1)) }
                if r + 1 < 3 { edges.append(UndirectedEdge(3 * r + c, 3 * r + c + 3)) }
            }
        }
        let grid = ReferencePseudograph(vertices: 0 ..< 9, edges: edges)
        let squares = grid.minimumCycleBasis()
        #expect(squares.count == 4)
        #expect(squares.allSatisfy { $0.edges.count == 4 })
        #expect(Set(squares.map { Set($0.vertices) }) == [[0, 1, 3, 4], [1, 2, 4, 5], [3, 4, 6, 7], [4, 5, 7, 8]])
        // Theta: paths of lengths 1, 2 and 3 between 0 and 1: cycles of lengths 3, 4 and 5.
        let theta = ReferencePseudograph(vertices: 0 ..< 5, edges: [
            UndirectedEdge(0, 1),
            UndirectedEdge(0, 2), UndirectedEdge(2, 1),
            UndirectedEdge(0, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 1),
        ])
        let basis = theta.minimumCycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1, 4, 3]])
        #expect(basis.map(\.edges) == [[0, 2, 1], [0, 5, 4, 3]])
    }

    @Test("Degenerate graphs: no vertices, a forest, a loop and a parallel pair, two components, a graph without vertex indices")
    func degenerate() {
        #expect(ReferencePseudograph(vertices: 0 ..< 0, edges: []).minimumCycleBasis().isEmpty)
        #expect(ReferencePseudograph(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)]).minimumCycleBasis().isEmpty)
        // A loop at 1, two copies of 0-1 and a triangle 1-2-3: the loop, the 2-cycle, the triangle.
        let multi = ReferencePseudograph(vertices: 0 ..< 4, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 0),
        ])
        let basis = multi.minimumCycleBasis()
        #expect(basis.map(\.vertices) == [[1], [0, 1], [1, 2, 3]])
        #expect(basis.map(\.edges) == [[4], [0, 5], [1, 2, 3]])
        for cycle in basis { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: multi) != nil) }
        // Two triangles in separate components.
        let two = ReferencePseudograph(vertices: 0 ..< 6, edges: [
            UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0),
        ])
        // Equal weight and length: the cycle with the lesser edge positions comes first.
        #expect(two.minimumCycleBasis().map(\.vertices) == [[3, 4, 5], [0, 1, 2]])
        #expect(two.minimumCycleBasis(weight: { _ in 2.5 }).map(\.vertices) == [[3, 4, 5], [0, 1, 2]])
    }

    @Test("Weights: a heavy chord makes the two triangles dearer than the square and one triangle; Float weights")
    func weighted() {
        // Square 0-1-2-3 with the chord 0-2 (position 4).
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: [
            UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(0, 2),
        ])
        #expect(graph.minimumCycleBasis().map(\.vertices) == [[0, 1, 2], [0, 3, 2]])
        // Chord weight 10: triangles weigh 12 each; the square weighs 4, so {square, a triangle} = 16 < 24.
        let weights: [Float] = [1, 1, 1, 1, 10]
        let basis = graph.minimumCycleBasis(weight: { weights[$0] })
        #expect(basis.count == 2)
        #expect(basis[0].vertices == [0, 1, 2, 3])
        #expect(basis[1].edges.count == 3 && basis[1].edges.contains(4))
        // Unequal side weights: the lighter triangle (12, like the square) is the one kept, and at
        // equal weight the shorter cycle comes first.
        let sides: [Double] = [1, 1, 5, 5, 10]
        #expect(graph.minimumCycleBasis(weight: { sides[$0] }).map(\.vertices) == [[0, 1, 2], [0, 1, 2, 3]])
    }

    @Test("K₄ on UndirectedAdjacencyList, and as a symmetric digraph's undirectedView on AdjacencyList and AdjacencyMatrix")
    func representations() {
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< 4 { for j in i + 1 ..< 4 { edges.append(UndirectedEdge(i, j)) } }
        let list = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: edges)
        let basis = list.minimumCycleBasis()
        #expect(basis.map(\.vertices) == [[0, 1, 2], [0, 1, 3], [0, 2, 3]])
        for cycle in basis { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: list) != nil) }
        // Unit weights search by Dijkstra, which may break ties among the four triangles differently.
        let weighted = list.minimumCycleBasis(weight: { _ in 1.0 })
        #expect(weighted.count == 3 && weighted.allSatisfy { $0.edges.count == 3 })
        // Each undirected edge as two arcs: the undirected view has parallel pairs, so the minimum
        // basis is the six 2-cycles (m − n + c = 12 − 4 + 1 = 9: six 2-cycles plus three triangles).
        let arcs = edges.flatMap { [DirectedEdge(from: $0.u, to: $0.v), DirectedEdge(from: $0.v, to: $0.u)] }
        func check<G: Graph<Int>>(_ graph: G, _ name: String) {
            let basis = graph.minimumCycleBasis()
            #expect(basis.count == 9, "\(name)")
            #expect(basis.prefix(6).allSatisfy { $0.edges.count == 2 }, "\(name)")
            #expect(basis.dropFirst(6).allSatisfy { $0.edges.count == 3 }, "\(name)")
            for cycle in basis { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil, "\(name)") }
        }
        check(AdjacencyList(vertices: 0 ..< 4, edges: arcs).undirectedView, "AdjacencyList")
        check(AdjacencyMatrix(vertexCount: 4, edges: arcs).undirectedView, "AdjacencyMatrix")
    }

    @Test("A multigraph whose later supports must take the symmetric difference only on an odd overlap: six independent cycles of total length 16")
    func supportUpdates() {
        // Found by a search over small multigraphs: updating a support on any positive overlap
        // with the chosen cycle leaves a dependent set here.
        let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: [
            UndirectedEdge(1, 3), UndirectedEdge(1, 3), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(1, 2),
            UndirectedEdge(0, 4), UndirectedEdge(3, 4), UndirectedEdge(1, 4), UndirectedEdge(0, 3), UndirectedEdge(0, 3),
        ])
        let basis = graph.minimumCycleBasis()
        #expect(basis.count == 6)
        #expect(basis.reduce(0) { $0 + $1.edges.count } == 16)
        #expect(basis.map(\.edges.count) == [2, 2, 3, 3, 3, 3])
        var pivots: [Int: Int] = [:]
        var rank = 0
        for cycle in basis {
            var x = cycle.edges.reduce(0) { $0 | (1 << $1) }
            while x != 0, let p = pivots[x.bitWidth - x.leadingZeroBitCount] { x ^= p }
            if x != 0 {
                pivots[x.bitWidth - x.leadingZeroBitCount] = x
                rank += 1
            }
        }
        #expect(rank == 6)
        for cycle in basis { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil) }
        let weighted = graph.minimumCycleBasis(weight: { Double($0 % 3 + 1) })
        #expect(weighted.count == 6)
    }

    @Test("Against the greedy oracle over every simple cycle: the same total weight, m − n + c independent simple cycles of the graph, unweighted and weighted", .tags(.randomized))
    func greedyOracle() async {
        let pairs = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 10)
        let weightDraws = Gen.int(in: 1 ... 4).array(of: 10 ... 10)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 1 ... 7), weightDraws, Gen.bool) { raw, n, draws, weighted in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            let w: [Double] = draws.prefix(ends.count).map { Double($0) }
            let context = "\(ends) weights \(weighted ? w : []) "
            func weight(_ edges: [Int]) -> Double { edges.reduce(0.0) { $0 + (weighted ? w[$1] : 1) } }
            // Independence over GF(2) by Gaussian elimination on edge bit masks.
            func rank(_ sets: [[Int]]) -> Int {
                var pivots: [Int: Int] = [:]
                var rank = 0
                for edges in sets {
                    var x = edges.reduce(0) { $0 | (1 << $1) }
                    while x != 0, let p = pivots[x.bitWidth - x.leadingZeroBitCount] { x ^= p }
                    if x != 0 {
                        pivots[x.bitWidth - x.leadingZeroBitCount] = x
                        rank += 1
                    }
                }
                return rank
            }
            // The greedy oracle: cycles by weight, each kept when independent of the kept ones.
            let all = graph.simpleCycles().map(\.edges).sorted { weight($0) < weight($1) }
            var kept: [[Int]] = []
            for cycle in all where rank(kept + [cycle]) == kept.count + 1 { kept.append(cycle) }
            var parent = Array(0 ..< n)
            func root(_ x: Int) -> Int { parent[x] == x ? x : root(parent[x]) }
            for (a, b) in ends where root(a) != root(b) { parent[root(a)] = root(b) }
            let components = Set((0 ..< n).map(root)).count
            #expect(kept.count == ends.count - n + components, "oracle dimension; \(context)")
            let basis = weighted ? graph.minimumCycleBasis(weight: { w[$0] }) : graph.minimumCycleBasis()
            #expect(basis.count == kept.count, "dimension; \(context)")
            #expect(rank(basis.map(\.edges)) == basis.count, "independent; \(context)")
            let total = basis.reduce(0.0) { $0 + weight($1.edges) }
            #expect(abs(total - kept.reduce(0.0) { $0 + weight($1) }) <= 1e-9, "total weight \(total); \(context)")
            for cycle in basis {
                #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil, "a cycle of the graph; \(context)")
                #expect(cycle.vertices.first == cycle.vertices.min(), "canonical; \(context)")
            }
            let weights = basis.map { weight($0.edges) }
            #expect(weights == weights.sorted(), "nondecreasing; \(context)")
        }
    }
}
