// The `checked:` lookups on the four product views: for every vertex (g, h) of the product they
// return what the trapping spellings return, and they throw `VertexNotFound` for a pair with either
// component missing from its factor.

import AdjacencyListModule
import GraphProducts
import GraphProtocols
import Testing

@Suite("Checked lookups on the product views")
struct ProductCheckedLookupTests {
    @Test("directed products: the checked reads agree with the trapping ones and throw for a non-vertex")
    func directed() throws {
        func check<P: BidirectionalDirectedGraph<Pair<String, Int>>>(_ product: P, _ name: String) throws {
            for v in product.vertices {
                #expect(try Array(product.successors(checked: v)) == Array(product.successors(of: v)), "\(name)")
                #expect(try Array(product.predecessors(checked: v)) == Array(product.predecessors(of: v)), "\(name)")
                #expect(try Array(product.outEdges(checked: v)) == Array(product.outEdges(of: v)), "\(name)")
                #expect(try Array(product.inEdges(checked: v)) == Array(product.inEdges(of: v)), "\(name)")
                #expect(try product.outDegree(checked: v) == product.outDegree(of: v), "\(name)")
                #expect(try product.inDegree(checked: v) == product.inDegree(of: v), "\(name)")
                #expect(try product.degree(checked: v) == product.degree(of: v), "\(name)")
                #expect(try product.vertexIndex(checked: v) == product.vertexIndex(of: v), "\(name)")
            }
            for bad in [Pair("z", 0), Pair("a", 9), Pair("z", 9)] {
                #expect(throws: VertexNotFound.self, "\(name)") { try product.successors(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.predecessors(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.outEdges(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.inEdges(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.outDegree(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.inDegree(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.degree(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.vertexIndex(checked: bad) }
            }
        }
        let g = AdjacencyList(vertices: ["a", "b"], edges: [DirectedEdge(from: "a", to: "b")])
        let h = AdjacencyList(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 2)])
        try check(cartesianProductView(g, h), "cartesian")
        try check(tensorProductView(g, h), "tensor")
        try check(strongProductView(g, h), "strong")
        try check(lexicographicProductView(g, h), "lexicographic")
        #expect(try cartesianProductView(g, h).outDegree(checked: Pair("a", 1)) == 2)
        #expect(try tensorProductView(g, h).outDegree(checked: Pair("a", 1)) == 1)
        #expect(try strongProductView(g, h).outDegree(checked: Pair("a", 1)) == 3)
        #expect(try lexicographicProductView(g, h).outDegree(checked: Pair("a", 1)) == 4)
    }

    @Test("undirected products: the checked reads agree with the trapping ones and throw for a non-vertex")
    func undirected() throws {
        func check<P: Graph<Pair<String, Int>>>(_ product: P, _ name: String) throws {
            for v in product.vertices {
                #expect(try Array(product.neighbors(checked: v)) == Array(product.neighbors(of: v)), "\(name)")
                #expect(try Array(product.incidentEdges(checked: v)) == Array(product.incidentEdges(of: v)), "\(name)")
                #expect(try product.degree(checked: v) == product.degree(of: v), "\(name)")
                #expect(try product.vertexIndex(checked: v) == product.vertexIndex(of: v), "\(name)")
            }
            for bad in [Pair("z", 0), Pair("a", 9)] {
                #expect(throws: VertexNotFound.self, "\(name)") { try product.neighbors(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.incidentEdges(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.degree(checked: bad) }
                #expect(throws: VertexNotFound.self, "\(name)") { try product.vertexIndex(checked: bad) }
            }
        }
        let g = UndirectedAdjacencyList(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c")])
        let h = UndirectedAdjacencyList(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        try check(cartesianProductView(g, h), "cartesian")
        try check(tensorProductView(g, h), "tensor")
        try check(strongProductView(g, h), "strong")
        try check(lexicographicProductView(g, h), "lexicographic")
        #expect(try cartesianProductView(g, h).degree(checked: Pair("b", 0)) == 3)
        #expect(try tensorProductView(g, h).degree(checked: Pair("b", 0)) == 2)
        #expect(try strongProductView(g, h).degree(checked: Pair("b", 0)) == 5)
        #expect(try lexicographicProductView(g, h).degree(checked: Pair("b", 0)) == 5)
    }
}
