// isOuterplanar (catalog PL-152 – PL-168): planar with every vertex on one face.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("isOuterplanar")
struct OuterplanarTests {
    @Test("PL-152 empty: isOuterplanar")
    func pl152() {
        // U:; isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-153 one vertex: isOuterplanar")
    func pl153() {
        // U: [0]; isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [0])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-154 triangle: isOuterplanar")
    func pl154() {
        // U: K(3); isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(1, 2)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-155 K4: isOuterplanar")
    func pl155() {
        // U: K(4); isOuterplanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.isOuterplanar == false)
        #expect(graph.isOuterplanar == false)  // asking again
    }

    @Test("PL-156 K2,3: isOuterplanar")
    func pl156() {
        // U: KB(0..1;2..4); isOuterplanar → false
        let graph = Pseudograph<Int>(vertices: [0, 2, 3, 4, 1], edges: [UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 2, 3, 4, 1])
        #expect(graph.isOuterplanar == false)
        #expect(graph.isOuterplanar == false)  // asking again
    }

    @Test("PL-157 cycle: isOuterplanar")
    func pl157() {
        // U: C(0..5); isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-158 tree: isOuterplanar")
    func pl158() {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5; isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(2, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-159 fan: maximal outerplanar: isOuterplanar")
    func pl159() {
        // U: P(1..5), S(0;1..5); isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: [1, 2, 3, 4, 5, 0], edges: [UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(0, 1),
            UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [1, 2, 3, 4, 5, 0])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-160 wheel W5: isOuterplanar")
    func pl160() {
        // U: nx(wheel,5); isOuterplanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 4),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.isOuterplanar == false)
        #expect(graph.isOuterplanar == false)  // asking again
    }

    @Test("PL-161 diamond: isOuterplanar")
    func pl161() {
        // U: nx(diamond); isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-162 ladder 2 × 5: isOuterplanar")
    func pl162() {
        // U: grid(2,5); isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5),
            UndirectedEdge(1, 2), UndirectedEdge(1, 6), UndirectedEdge(2, 3), UndirectedEdge(2, 7),
            UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(6, 7), UndirectedEdge(7, 8), UndirectedEdge(8, 9)])
        #expect(graph.vertexCount == 10 && graph.edgeCount == 13)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-163 grid 3 × 3: isOuterplanar")
    func pl163() {
        // U: grid(3,3); isOuterplanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 9, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 3),
            UndirectedEdge(1, 2), UndirectedEdge(1, 4), UndirectedEdge(2, 5), UndirectedEdge(3, 4),
            UndirectedEdge(3, 6), UndirectedEdge(4, 5), UndirectedEdge(4, 7), UndirectedEdge(5, 8),
            UndirectedEdge(6, 7), UndirectedEdge(7, 8)])
        #expect(graph.vertexCount == 9 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(graph.isOuterplanar == false)
        #expect(graph.isOuterplanar == false)  // asking again
    }

    @Test("PL-164 triangle and a disjoint K4: isOuterplanar")
    func pl164() {
        // U: K(3), K(3..6); isOuterplanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(1, 2), UndirectedEdge(3, 4), UndirectedEdge(3, 5), UndirectedEdge(3, 6),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(5, 6)])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(graph.isOuterplanar == false)
        #expect(graph.isOuterplanar == false)  // asking again
    }

    @Test("PL-165 K5: not planar either: isOuterplanar")
    func pl165() {
        // U: K(5); isOuterplanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.isOuterplanar == false)
        #expect(graph.isOuterplanar == false)  // asking again
    }

    @Test("PL-166 loops and parallel edges: isOuterplanar")
    func pl166() {
        // U: 0=1, 1-2, 2-0, 0-0; isOuterplanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1),
            UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(0, 0)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(graph.isOuterplanar == true)
        #expect(graph.isPlanar)  // outerplanar graphs are planar
        #expect(graph.isOuterplanar == true)  // asking again
    }

    @Test("PL-167 K2,3 subdivided: isOuterplanar")
    func pl167() {
        // U: sd(KB(0..1;2..4)); isOuterplanar → false
        let graph = Pseudograph<Int>(vertices: [0, 2, 3, 4, 1, 5, 6, 7, 8, 9, 10], edges: [UndirectedEdge(0, 5),
            UndirectedEdge(5, 2), UndirectedEdge(0, 6), UndirectedEdge(6, 3), UndirectedEdge(0, 7),
            UndirectedEdge(7, 4), UndirectedEdge(1, 8), UndirectedEdge(8, 2), UndirectedEdge(1, 9),
            UndirectedEdge(9, 3), UndirectedEdge(1, 10), UndirectedEdge(10, 4)])
        #expect(graph.vertexCount == 11 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 2, 3, 4, 1, 5, 6, 7, 8, 9, 10])
        #expect(graph.isOuterplanar == false)
        #expect(graph.isOuterplanar == false)  // asking again
    }

    @Test("PL-168 directed K4: undirected.isOuterplanar")
    func pl168() {
        // D: tt(4); undirected.isOuterplanar → false
        let graph = AdjacencyList<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 1, to: 2),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3)]).undirected
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.isOuterplanar == false)
        #expect(graph.isOuterplanar == false)  // asking again
    }
}
