// `Bipartition` as a value and recognition through conversions and views the catalog does not
// list: equality (sides compared by vertex), the description, the copy of the graph it holds,
// generic code over `some Graph`; `CompressedSparseRow`, which has no `.undirected`, read through
// `AdjacencyList(csr).undirected` (each arc an edge); an undirected graph read as directed and back
// (`graph.directed.undirected`: each edge becomes a parallel pair, a loop two loops), which keeps
// bipartiteness and the canonical sides; and `isBipartite`, `bipartition()`, `findOddCycle()`
// agreeing on graphs whose answer is known in closed form. Expected values are the catalog's
// (where a row is reused) or derived in each test. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Bipartition values, conversions and views")
struct BipartitionTests {
    @Test("Bipartitions of the same graph are equal; different sides are not; the description is not empty")
    func equality() throws {
        // BP-015's path and a star on the same vertices.
        let path = UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let star = UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2)])
        let a = try #require(path.bipartition())
        let b = try #require(path.bipartition())
        let c = try #require(star.bipartition())
        #expect(a == b)
        #expect(a != c)
        #expect(Array(c.left) == [0])
        #expect(Array(c.right) == [1, 2])
        #expect(!a.description.isEmpty)
        // The same edges in another order: the same sides.
        let reordered = UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(2, 1), UndirectedEdge(1, 0)])
        let d = try #require(reordered.bipartition())
        #expect(d == a)
    }

    @Test("A bipartition holds a copy of the graph: later changes to the graph do not reach it")
    func holdsACopy() throws {
        var graph = UndirectedAdjacencyList(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let bipartition = try #require(graph.bipartition())
        graph.remove(0)
        graph.insert(edge: UndirectedEdge(1, 3))
        #expect(!graph.isBipartite)
        #expect(Array(bipartition.left) == [0, 2])
        #expect(Array(bipartition.right) == [1, 3])
        #expect(bipartition.side(of: 0) == .left)
        #expect(bipartition.side(of: 3) == .right)
        #expect(bipartition.side(ofIndex: 0) == .left)
    }

    @Test("Generic code over some Graph gets the same answers as the concrete call")
    func genericCode() throws {
        func answers<G: Graph>(_ graph: G) -> (Bool, [G.Vertex]?, Int?) {
            (graph.isBipartite, graph.bipartition().map { Array($0.left) }, graph.findOddCycle()?.length)
        }
        // BP-033's K2,3 and BP-019's triangle.
        let k23 = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [(0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4)].map { UndirectedEdge($0.0, $0.1) })
        let triangle = ReferencePseudograph(vertices: 0 ..< 3, edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        let a = answers(k23)
        #expect(a.0 && a.1 == [0, 1] && a.2 == nil)
        let b = answers(triangle)
        #expect(!b.0 && b.1 == nil && b.2 == 3)
        let bipartite: BipartiteGraph<Int> = try #require(BipartiteGraph(k23))
        let c = answers(bipartite)
        #expect(c.0 && c.1 == [0, 1] && c.2 == nil)
    }

    @Test("CompressedSparseRow through AdjacencyList(csr).undirected: BP-034's K3,3 and BP-071's directed triangle")
    func compressedSparseRow() throws {
        let k33 = CompressedSparseRow(vertexCount: 6, edges: [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let graph = AdjacencyList(k33).undirected
        #expect(graph.isBipartite)
        let bipartition = try #require(graph.bipartition())
        #expect(Array(bipartition.left) == [0, 1, 2])
        #expect(Array(bipartition.right) == [3, 4, 5])
        #expect(graph.findOddCycle() == nil)
        let triangleCSR = CompressedSparseRow(vertexCount: 3, edges: [(0, 1), (1, 2), (2, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        let triangle = AdjacencyList(triangleCSR).undirected
        #expect(!triangle.isBipartite)
        #expect(triangle.bipartition() == nil)
        let cycle = try #require(triangle.findOddCycle())
        #expect(cycle.vertices == [0, 1, 2])
        #expect(cycle.length == 3)
        let k = cycle.vertices.count
        for i in 0 ..< k {
            let edge = triangle.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: triangle) != nil)
    }

    @Test("graph.directed.undirected doubles every edge into a parallel pair: the same bipartiteness and sides; an odd cycle uses one copy of each edge")
    func directedThenUndirected() throws {
        // BP-053 (disconnected, bipartite) and BP-022 (C5).
        let disconnected = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [(1, 2), (3, 4), (4, 5)].map { UndirectedEdge($0.0, $0.1) })
        let doubled = disconnected.directed.undirected
        #expect(doubled.edgeCount == 6)
        #expect(doubled.isBipartite)
        let bipartition = try #require(doubled.bipartition())
        #expect(Array(bipartition.left) == [0, 1, 3, 5])
        #expect(Array(bipartition.right) == [2, 4])
        let bipartite = try #require(BipartiteGraph(doubled))
        // Each parallel pair collapses to one edge.
        #expect(bipartite.edgeCount == 3)
        #expect(Array(bipartite.left) == [0, 1, 3, 5])

        let pentagon = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)].map { UndirectedEdge($0.0, $0.1) })
        let doubledPentagon = pentagon.directed.undirected
        #expect(!doubledPentagon.isBipartite)
        #expect(BipartiteGraph(doubledPentagon) == nil)
        let cycle = try #require(doubledPentagon.findOddCycle())
        #expect(cycle.length == 5)
        #expect(Set(cycle.vertices) == [0, 1, 2, 3, 4])
        #expect(cycle.vertices[0] == 0)
        let k = cycle.vertices.count
        #expect(Set(cycle.edges).count == k)
        #expect(Set(cycle.edges.map(\.position)).count == k)
        for i in 0 ..< k {
            let edge = doubledPentagon.edges[cycle.edges[i]]
            #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]))
        }
        #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: doubledPentagon) != nil)
    }

    @Test("Closed forms: paths, even and odd cycles, complete graphs and complete bipartite graphs, on 1 … 9 vertices")
    func closedForms() throws {
        for n in 1 ... 9 {
            let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let pathSides = try #require(path.bipartition())
            #expect(Array(pathSides.left) == Array(stride(from: 0, to: n, by: 2)))
            #expect(Array(pathSides.right) == Array(stride(from: 1, to: n, by: 2)))
            if n >= 3 {
                let cycle = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
                #expect(cycle.isBipartite == n.isMultiple(of: 2), "C\(n)")
                if let odd = cycle.findOddCycle() {
                    // The only cycle: 0, 1, …, n − 1 through edges 0, 1, …, n − 1.
                    #expect(odd.vertices == Array(0 ..< n))
                    #expect(odd.edges == Array(0 ..< n))
                }
                var complete = UndirectedAdjacencyList(vertices: 0 ..< n)
                for a in 0 ..< n { for b in a + 1 ..< n { complete.insert(edge: UndirectedEdge(a, b)) } }
                #expect(!complete.isBipartite, "K\(n)")
                #expect(complete.findOddCycle()?.vertices == [0, 1, 2])
            }
            for a in 0 ... n {
                var kab = UndirectedAdjacencyList(vertices: 0 ..< n)
                for u in 0 ..< a { for w in a ..< n { kab.insert(edge: UndirectedEdge(u, w)) } }
                let sides = try #require(kab.bipartition(), "K\(a),\(n - a)")
                if a == 0 || a == n {
                    // No edges: every vertex is isolated, so left.
                    #expect(Array(sides.left) == Array(0 ..< n))
                } else {
                    #expect(Array(sides.left) == Array(0 ..< a))
                    #expect(Array(sides.right) == Array(a ..< n))
                }
            }
        }
    }
}
