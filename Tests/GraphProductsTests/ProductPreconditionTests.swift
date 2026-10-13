// Preconditions (catalog trap rows GP-069 – GP-071): each trapping call runs in a child process (an exit
// test). The same setup then runs in this process without the fault. Then the preconditions the
// catalog does not list (extra_traps.swift).
// Generated from cases.md by Tests/Catalogs/GraphProducts/swiftgen.py; see README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProducts
import GraphProtocols
import StableGraphs
import Testing

@Suite("GraphProducts preconditions", .tags(.precondition))
struct ProductPreconditionTests {
    @Test("GP-069 factor without vertex indices traps")
    func gp069() async {
        // G = Stable (with holes) V [a]; E []; H = AL V [x]; E [] / cartesianProductView(G, H) → **trap** (a factor has no vertex indices (vertexIndexBound is nil))
        await #expect(processExitsWith: .failure) {
            var g = StableDirectedGraph<String>(vertices: ["a", "removed"])
            _ = g.remove("removed")
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = cartesianProductView(g, h)
        }
        // The factor has a hole, so no vertex indices.
        var holed = StableDirectedGraph<String>(vertices: ["a", "removed"])
        _ = holed.remove("removed")
        #expect(holed.vertexIndexBound == nil)
        // Without the removal: dense, and accepted.
        let g = StableDirectedGraph<String>(vertices: ["a"])
        let h = AdjacencyList<String>(vertices: ["x"])
        let product = cartesianProductView(g, h)
        #expect(Array(product.vertices) == [Pair("a", "x")])
        #expect(product.vertexIndexBound == 1 && product.edgeCount == 0)
    }

    @Test("GP-070 vertex count overflow traps")
    func gp070() async {
        // G = a factor with 2^32 vertices; H = a factor with 2^32 vertices / cartesianProductView(G, H) → **trap** (the vertex count |V(G)|·|V(H)| overflows Int)
        await #expect(processExitsWith: .failure) {
            // An edgeless graph on 0..<count, stored as its count.
            struct Huge: Graph {
                let count: Int
                var vertices: Range<Int> { 0 ..< count }
                var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
                func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                var vertexIndexBound: Int? { count }
                func vertexIndex(of vertex: Int) -> Int { vertex }
                func vertex(atIndex index: Int) -> Int { index }
            }
            _ = cartesianProductView(Huge(count: 1 << 32), Huge(count: 1 << 32))
        }
        // 2^32 · 2^30 = 2^62 fits: accepted, and the last vertex is found by one division.
        struct Huge: Graph {
            let count: Int
            var vertices: Range<Int> { 0 ..< count }
            var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
            func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
            func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
            var vertexIndexBound: Int? { count }
            func vertexIndex(of vertex: Int) -> Int { vertex }
            func vertex(atIndex index: Int) -> Int { index }
        }
        let product = cartesianProductView(Huge(count: 1 << 32), Huge(count: 1 << 30))
        #expect(product.vertexIndexBound == 1 << 62 && product.edgeCount == 0)
        #expect(product.vertex(atIndex: (1 << 62) - 1) == Pair((1 << 32) - 1, (1 << 30) - 1))
        #expect(product.vertexIndex(of: Pair(5, 7)) == (5 << 30) + 7)
    }

    @Test("GP-071 a pair with a vertex not in its factor traps")
    func gp071() async {
        // G = UL V [a, b]; E [a–b]; H = UL V [x]; E [] / cartesianProductView(G, H).vertexIndex(of: Pair(a, q)) → **trap** (q is not a vertex of the factor)
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = cartesianProductView(g, h).vertexIndex(of: Pair("a", "q"))
        }
        // Without the call: the pair is not a vertex, and contains(_:) says so without trapping.
        let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
        let product = cartesianProductView(g, h)
        #expect(!product.contains(Pair("a", "q")) && !product.contains(Pair("q", "x")))
        #expect(product.contains(Pair("a", "x")) && product.vertexIndex(of: Pair("b", "x")) == 1)
    }

    @Test("A second factor without vertex indices traps, for all four products")
    func secondFactorWithHoles() async {
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a"])
            var h = StableDirectedGraph<String>(vertices: ["x", "removed"])
            _ = h.remove("removed")
            _ = cartesianProductView(g, h)
        }
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a"])
            var h = StableDirectedGraph<String>(vertices: ["x", "removed"])
            _ = h.remove("removed")
            _ = tensorProductView(g, h)
        }
        await #expect(processExitsWith: .failure) {
            var g = StableDirectedGraph<String>(vertices: ["a", "removed"])
            _ = g.remove("removed")
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = strongProductView(g, h)
        }
        await #expect(processExitsWith: .failure) {
            var g = StableDirectedGraph<String>(vertices: ["a", "removed"])
            _ = g.remove("removed")
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = lexicographicProductView(g, h)
        }
        // Without the removals: all four accepted.
        let g = StableDirectedGraph<String>(vertices: ["a"])
        let h = AdjacencyList<String>(vertices: ["x"])
        #expect(cartesianProductView(g, h).vertexIndexBound == 1 && tensorProductView(h, g).vertexIndexBound == 1)
        #expect(strongProductView(g, h).vertexIndexBound == 1 && lexicographicProductView(g, h).vertexIndexBound == 1)
    }

    @Test("Vertex count overflow traps for every kind, in either order")
    func overflowEveryKind() async {
        await #expect(processExitsWith: .failure) {
            struct Huge: Graph {
                let count: Int
                var vertices: Range<Int> { 0 ..< count }
                var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
                func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                var vertexIndexBound: Int? { count }
                func vertexIndex(of vertex: Int) -> Int { vertex }
                func vertex(atIndex index: Int) -> Int { index }
            }
            _ = tensorProductView(Huge(count: 3), Huge(count: Int.max / 2))
        }
        await #expect(processExitsWith: .failure) {
            struct Huge: Graph {
                let count: Int
                var vertices: Range<Int> { 0 ..< count }
                var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
                func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                var vertexIndexBound: Int? { count }
                func vertexIndex(of vertex: Int) -> Int { vertex }
                func vertex(atIndex index: Int) -> Int { index }
            }
            _ = strongProductView(Huge(count: Int.max / 2), Huge(count: 3))
        }
        await #expect(processExitsWith: .failure) {
            struct Huge: Graph {
                let count: Int
                var vertices: Range<Int> { 0 ..< count }
                var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
                func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
                var vertexIndexBound: Int? { count }
                func vertexIndex(of vertex: Int) -> Int { vertex }
                func vertex(atIndex index: Int) -> Int { index }
            }
            _ = lexicographicProductView(Huge(count: 1 << 40), Huge(count: 1 << 40))
        }
        // At the boundary: Int.max / 2 · 2 fits, and an empty factor never overflows.
        struct Huge: Graph {
            let count: Int
            var vertices: Range<Int> { 0 ..< count }
            var edges: EmptyCollection<UndirectedEdge<Int>> { EmptyCollection() }
            func neighbors(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
            func incidentEdges(of vertex: Int) -> EmptyCollection<Int> { EmptyCollection() }
            var vertexIndexBound: Int? { count }
            func vertexIndex(of vertex: Int) -> Int { vertex }
            func vertex(atIndex index: Int) -> Int { index }
        }
        #expect(tensorProductView(Huge(count: 2), Huge(count: Int.max / 2)).vertexIndexBound == Int.max - 1)
        #expect(strongProductView(Huge(count: 0), Huge(count: Int.max)).vertexIndexBound == 0)
        #expect(lexicographicProductView(Huge(count: Int.max), Huge(count: 0)).vertexIndexBound == 0)
    }

    @Test("Index-space reads trap outside 0..<vertexIndexBound")
    func indicesOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = cartesianProductView(g, h).vertex(atIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = tensorProductView(g, h).vertex(atIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = strongProductView(g, h).vertex(atIndex: 2)
        }
        // Without the calls: the last index answers.
        let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
        #expect(cartesianProductView(g, h).vertex(atIndex: 1) == Pair("b", "x"))
        #expect(tensorProductView(g, h).vertex(atIndex: 0) == Pair("a", "x"))
    }

    @Test("Label-space reads of a pair that is not a vertex trap, directed and undirected")
    func rowsOfNonVertices() async {
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = Array(cartesianProductView(g, h).successors(of: Pair("q", "x")))
        }
        await #expect(processExitsWith: .failure) {
            let g = AdjacencyList<String>(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
            let h = AdjacencyList<String>(vertices: ["x"])
            _ = Array(lexicographicProductView(g, h).predecessors(of: Pair("a", "q")))
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = Array(strongProductView(g, h).neighbors(of: Pair("a", "q")))
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
            _ = tensorProductView(g, h).degree(of: Pair("q", "x"))
        }
        // Without the calls: contains(_:) and contains(edge:) answer false without trapping.
        let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        let h = UndirectedAdjacencyList<String>(vertices: ["x"], edges: [] as [UndirectedEdge<String>])
        let product = strongProductView(g, h)
        #expect(!product.contains(Pair("a", "q")) && !product.contains(edge: UndirectedEdge(Pair("a", "x"), Pair("q", "x"))))
        #expect(Array(product.neighbors(of: Pair("a", "x"))) == [Pair("b", "x")])
    }

    @Test("edgeIndex(of:) traps on an undirected tensor, strong or lexicographic product")
    func noEdgeIndices() async {
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let product = tensorProductView(g, g)
            _ = product.edgeIndex(of: product.edges.startIndex)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let product = strongProductView(g, g)
            _ = product.edgeIndex(of: product.edges.startIndex)
        }
        await #expect(processExitsWith: .failure) {
            let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
            let product = lexicographicProductView(g, g)
            _ = product.edgeIndex(of: product.edges.startIndex)
        }
        // Without the calls: the bounds say so, and the Cartesian product has them.
        let g = UndirectedAdjacencyList<String>(vertices: ["a", "b"], edges: [UndirectedEdge("a", "b")])
        #expect(tensorProductView(g, g).edgeIndexBound == nil && strongProductView(g, g).edgeIndexBound == nil)
        #expect(lexicographicProductView(g, g).edgeIndexBound == nil)
        let cartesian = cartesianProductView(g, g)
        #expect(cartesian.edgeIndexBound == 4 && cartesian.edgeIndex(of: cartesian.edges.startIndex) == 0)
    }
}
