// isPlanar (catalog PL-001 – PL-048): small named graphs, Kuratowski's two graphs and their
// subdivisions, Platonic solids, cubic graphs, grids, stacked triangulations with and without one
// more edge, disjoint unions and blocks. Each row also checks that exactly one witness exists.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("isPlanar")
struct IsPlanarTests {
    @Test("PL-001 empty graph: isPlanar")
    func pl001() {
        // U:; isPlanar → true
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-002 one vertex: isPlanar")
    func pl002() {
        // U: [0]; isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [0])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-003 isolated vertices: isPlanar")
    func pl003() {
        // U: E(5); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-004 one edge: isPlanar")
    func pl004() {
        // U: 0-1; isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-005 K4: isPlanar")
    func pl005() {
        // U: K(4); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-006 K5: isPlanar")
    func pl006() {
        // U: K(5); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-007 K5 minus an edge: isPlanar")
    func pl007() {
        // U: [0..4] 0-1, 0-2, 0-3, 0-4, 1-2, 1-3, 1-4, 2-3, 2-4; isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-008 K3,3: isPlanar")
    func pl008() {
        // U: KB(0..2;3..5); isPlanar → false
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: [UndirectedEdge(0, 3),
            UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-009 K3,3 minus an edge: isPlanar")
    func pl009() {
        // U: 0-3, 0-4, 0-5, 1-3, 1-4, 1-5, 2-3, 2-4; isPlanar → true
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: [UndirectedEdge(0, 3),
            UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(2, 4)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-010 K2,5: isPlanar")
    func pl010() {
        // U: KB(0..1;2..6); isPlanar → true
        let graph = Pseudograph<Int>(vertices: [0, 2, 3, 4, 5, 6, 1], edges: [UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(0, 6),
            UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(1, 5),
            UndirectedEdge(1, 6)])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 2, 3, 4, 5, 6, 1])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-011 K3,5 contains K3,3: isPlanar")
    func pl011() {
        // U: KB(0..2;3..7); isPlanar → false
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 6, 7, 1, 2], edges: [UndirectedEdge(0, 3),
            UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(0, 6), UndirectedEdge(0, 7),
            UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(1, 6),
            UndirectedEdge(1, 7), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 5),
            UndirectedEdge(2, 6), UndirectedEdge(2, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 6, 7, 1, 2])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-012 K6: isPlanar")
    func pl012() {
        // U: K(6); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 2),
            UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(2, 3),
            UndirectedEdge(2, 4), UndirectedEdge(2, 5), UndirectedEdge(3, 4), UndirectedEdge(3, 5),
            UndirectedEdge(4, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-013 K8: more than 3n - 6 edges: isPlanar")
    func pl013() {
        // U: K(8); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(0, 6),
            UndirectedEdge(0, 7), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(1, 5), UndirectedEdge(1, 6), UndirectedEdge(1, 7), UndirectedEdge(2, 3),
            UndirectedEdge(2, 4), UndirectedEdge(2, 5), UndirectedEdge(2, 6), UndirectedEdge(2, 7),
            UndirectedEdge(3, 4), UndirectedEdge(3, 5), UndirectedEdge(3, 6), UndirectedEdge(3, 7),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 7), UndirectedEdge(5, 6),
            UndirectedEdge(5, 7), UndirectedEdge(6, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 28)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-014 K4,4: isPlanar")
    func pl014() {
        // U: KB(0..3;4..7); isPlanar → false
        let graph = Pseudograph<Int>(vertices: [0, 4, 5, 6, 7, 1, 2, 3], edges: [UndirectedEdge(0, 4),
            UndirectedEdge(0, 5), UndirectedEdge(0, 6), UndirectedEdge(0, 7), UndirectedEdge(1, 4),
            UndirectedEdge(1, 5), UndirectedEdge(1, 6), UndirectedEdge(1, 7), UndirectedEdge(2, 4),
            UndirectedEdge(2, 5), UndirectedEdge(2, 6), UndirectedEdge(2, 7), UndirectedEdge(3, 4),
            UndirectedEdge(3, 5), UndirectedEdge(3, 6), UndirectedEdge(3, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 16)
        #expect(Array(graph.vertices) == [0, 4, 5, 6, 7, 1, 2, 3])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-015 Petersen graph: isPlanar")
    func pl015() {
        // U: nx(petersen); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 4),
            UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6), UndirectedEdge(2, 3),
            UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9),
            UndirectedEdge(5, 7), UndirectedEdge(5, 8), UndirectedEdge(6, 8), UndirectedEdge(6, 9),
            UndirectedEdge(7, 9)])
        #expect(graph.vertexCount == 10 && graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-016 dodecahedron: isPlanar")
    func pl016() {
        // U: nx(dodecahedral); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 20, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 19),
            UndirectedEdge(0, 10), UndirectedEdge(1, 2), UndirectedEdge(1, 8), UndirectedEdge(2, 3),
            UndirectedEdge(2, 6), UndirectedEdge(3, 4), UndirectedEdge(3, 19), UndirectedEdge(4, 5),
            UndirectedEdge(4, 17), UndirectedEdge(5, 6), UndirectedEdge(5, 15), UndirectedEdge(6, 7),
            UndirectedEdge(7, 8), UndirectedEdge(7, 14), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(9, 13), UndirectedEdge(10, 11), UndirectedEdge(11, 12), UndirectedEdge(11, 18),
            UndirectedEdge(12, 13), UndirectedEdge(12, 16), UndirectedEdge(13, 14), UndirectedEdge(14, 15),
            UndirectedEdge(15, 16), UndirectedEdge(16, 17), UndirectedEdge(17, 18), UndirectedEdge(18, 19)])
        #expect(graph.vertexCount == 20 && graph.edgeCount == 30)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-017 icosahedron: isPlanar")
    func pl017() {
        // U: nx(icosahedral); isPlanar → true
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6], edges: [UndirectedEdge(0, 1),
            UndirectedEdge(0, 5), UndirectedEdge(0, 7), UndirectedEdge(0, 8), UndirectedEdge(0, 11),
            UndirectedEdge(1, 2), UndirectedEdge(1, 5), UndirectedEdge(1, 6), UndirectedEdge(1, 8),
            UndirectedEdge(2, 3), UndirectedEdge(2, 6), UndirectedEdge(2, 8), UndirectedEdge(2, 9),
            UndirectedEdge(3, 4), UndirectedEdge(3, 6), UndirectedEdge(3, 9), UndirectedEdge(3, 10),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 10), UndirectedEdge(4, 11),
            UndirectedEdge(5, 6), UndirectedEdge(5, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 9),
            UndirectedEdge(7, 10), UndirectedEdge(7, 11), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11)])
        #expect(graph.vertexCount == 12 && graph.edgeCount == 30)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-018 octahedron: isPlanar")
    func pl018() {
        // U: nx(octahedral); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 5), UndirectedEdge(2, 4), UndirectedEdge(2, 5), UndirectedEdge(3, 4),
            UndirectedEdge(3, 5), UndirectedEdge(4, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-019 cube Q3: isPlanar")
    func pl019() {
        // U: Q(3); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 4), UndirectedEdge(1, 3), UndirectedEdge(1, 5), UndirectedEdge(2, 3),
            UndirectedEdge(2, 6), UndirectedEdge(3, 7), UndirectedEdge(4, 5), UndirectedEdge(4, 6),
            UndirectedEdge(5, 7), UndirectedEdge(6, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-020 hypercube Q4: isPlanar")
    func pl020() {
        // U: Q(4); isPlanar → false
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 2, 0, 4, 0, 8, 1, 3, 1, 5, 1, 9, 2, 3, 2, 6, 2, 10, 3, 7, 3, 11, 4, 5,
            4, 6, 4, 12, 5, 7, 5, 13, 6, 7, 6, 14, 7, 15, 8, 9, 8, 10, 8, 12, 9, 11, 9, 13, 10, 11, 10, 14,
            11, 15, 12, 13, 12, 14, 13, 15, 14, 15]
        let graph = Pseudograph<Int>(vertices: 0 ..< 16, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 16 && graph.edgeCount == 32)
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-021 Heawood graph: isPlanar")
    func pl021() {
        // U: nx(heawood); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 14, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 13),
            UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 10), UndirectedEdge(2, 3),
            UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 12), UndirectedEdge(4, 5),
            UndirectedEdge(4, 9), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(6, 11),
            UndirectedEdge(7, 8), UndirectedEdge(8, 9), UndirectedEdge(8, 13), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11), UndirectedEdge(11, 12), UndirectedEdge(12, 13)])
        #expect(graph.vertexCount == 14 && graph.edgeCount == 21)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-022 Desargues graph: isPlanar")
    func pl022() {
        // U: nx(desargues); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 20, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 19),
            UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 16), UndirectedEdge(2, 3),
            UndirectedEdge(2, 11), UndirectedEdge(3, 4), UndirectedEdge(3, 14), UndirectedEdge(4, 5),
            UndirectedEdge(4, 9), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(6, 15),
            UndirectedEdge(7, 8), UndirectedEdge(7, 18), UndirectedEdge(8, 9), UndirectedEdge(8, 13),
            UndirectedEdge(9, 10), UndirectedEdge(10, 11), UndirectedEdge(10, 19), UndirectedEdge(11, 12),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(14, 15),
            UndirectedEdge(15, 16), UndirectedEdge(16, 17), UndirectedEdge(17, 18), UndirectedEdge(18, 19)])
        #expect(graph.vertexCount == 20 && graph.edgeCount == 30)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-023 Möbius–Kantor graph: isPlanar")
    func pl023() {
        // U: nx(moebius_kantor); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 16, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 15),
            UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 12), UndirectedEdge(2, 3),
            UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 14), UndirectedEdge(4, 5),
            UndirectedEdge(4, 9), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(6, 11),
            UndirectedEdge(7, 8), UndirectedEdge(8, 9), UndirectedEdge(8, 13), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(12, 13),
            UndirectedEdge(13, 14), UndirectedEdge(14, 15)])
        #expect(graph.vertexCount == 16 && graph.edgeCount == 24)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-024 Pappus graph: isPlanar")
    func pl024() {
        // U: nx(pappus); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 18, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 17),
            UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 8), UndirectedEdge(2, 3),
            UndirectedEdge(2, 13), UndirectedEdge(3, 4), UndirectedEdge(3, 10), UndirectedEdge(4, 5),
            UndirectedEdge(4, 15), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(6, 11),
            UndirectedEdge(7, 8), UndirectedEdge(7, 14), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(9, 16), UndirectedEdge(10, 11), UndirectedEdge(11, 12), UndirectedEdge(12, 13),
            UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(14, 15), UndirectedEdge(15, 16),
            UndirectedEdge(16, 17)])
        #expect(graph.vertexCount == 18 && graph.edgeCount == 27)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-025 Frucht graph: isPlanar")
    func pl025() {
        // U: nx(frucht); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 6),
            UndirectedEdge(0, 7), UndirectedEdge(1, 2), UndirectedEdge(1, 7), UndirectedEdge(2, 3),
            UndirectedEdge(2, 8), UndirectedEdge(3, 4), UndirectedEdge(3, 9), UndirectedEdge(4, 5),
            UndirectedEdge(4, 9), UndirectedEdge(5, 6), UndirectedEdge(5, 10), UndirectedEdge(6, 10),
            UndirectedEdge(7, 11), UndirectedEdge(8, 11), UndirectedEdge(8, 9), UndirectedEdge(10, 11)])
        #expect(graph.vertexCount == 12 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-026 Tutte graph: isPlanar")
    func pl026() {
        // U: nx(tutte); isPlanar → true
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 2, 0, 3, 1, 4, 1, 26, 2, 10, 2, 11, 3, 18, 3, 19, 4, 5, 4, 33, 5, 6,
            5, 29, 6, 7, 6, 27, 7, 8, 7, 14, 8, 9, 8, 38, 9, 10, 9, 37, 10, 39, 11, 12, 11, 39, 12, 13,
            12, 35, 13, 14, 13, 15, 14, 34, 15, 16, 15, 22, 16, 17, 16, 44, 17, 18, 17, 43, 18, 45, 19, 20,
            19, 45, 20, 21, 20, 41, 21, 22, 21, 23, 22, 40, 23, 24, 23, 27, 24, 25, 24, 32, 25, 26, 25, 31,
            26, 33, 27, 28, 28, 29, 28, 32, 29, 30, 30, 31, 30, 33, 31, 32, 34, 35, 34, 38, 35, 36, 36, 37,
            36, 39, 37, 38, 40, 41, 40, 44, 41, 42, 42, 43, 42, 45, 43, 44]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 34, 35, 36, 37, 40, 41, 42, 43, 33, 38, 39, 44, 45, 32], edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 46 && graph.edgeCount == 69)
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-027 truncated tetrahedron: isPlanar")
    func pl027() {
        // U: nx(truncated_tetrahedron); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 9), UndirectedEdge(1, 2), UndirectedEdge(1, 6), UndirectedEdge(2, 3),
            UndirectedEdge(3, 4), UndirectedEdge(3, 11), UndirectedEdge(4, 5), UndirectedEdge(4, 11),
            UndirectedEdge(5, 6), UndirectedEdge(5, 7), UndirectedEdge(6, 7), UndirectedEdge(7, 8),
            UndirectedEdge(8, 9), UndirectedEdge(8, 10), UndirectedEdge(9, 10), UndirectedEdge(10, 11)])
        #expect(graph.vertexCount == 12 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-028 truncated cube: isPlanar")
    func pl028() {
        // U: nx(truncated_cube); isPlanar → true
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 2, 0, 4, 1, 11, 1, 14, 2, 3, 2, 4, 3, 6, 3, 8, 4, 5, 5, 16, 5, 18, 6, 7,
            6, 8, 7, 10, 7, 12, 8, 9, 9, 17, 9, 20, 10, 11, 10, 12, 11, 14, 12, 13, 13, 21, 13, 22, 14, 15,
            15, 19, 15, 23, 16, 17, 16, 18, 17, 20, 18, 19, 19, 23, 20, 21, 21, 22, 22, 23]
        let graph = Pseudograph<Int>(vertices: 0 ..< 24, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 24 && graph.edgeCount == 36)
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-029 Chvátal graph: isPlanar")
    func pl029() {
        // U: nx(chvatal); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 4),
            UndirectedEdge(0, 6), UndirectedEdge(0, 9), UndirectedEdge(1, 2), UndirectedEdge(1, 5),
            UndirectedEdge(1, 7), UndirectedEdge(2, 3), UndirectedEdge(2, 6), UndirectedEdge(2, 8),
            UndirectedEdge(3, 4), UndirectedEdge(3, 7), UndirectedEdge(3, 9), UndirectedEdge(4, 5),
            UndirectedEdge(4, 8), UndirectedEdge(5, 10), UndirectedEdge(5, 11), UndirectedEdge(6, 10),
            UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 11), UndirectedEdge(8, 10),
            UndirectedEdge(9, 10), UndirectedEdge(9, 11)])
        #expect(graph.vertexCount == 12 && graph.edgeCount == 24)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-030 house with a cross: isPlanar")
    func pl030() {
        // U: nx(house_x); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 3), UndirectedEdge(1, 2), UndirectedEdge(2, 3),
            UndirectedEdge(2, 4), UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-031 Wagner graph (Möbius ladder M8): isPlanar")
    func pl031() {
        // U: C(0..7), 0-4, 1-5, 2-6, 3-7; isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 6),
            UndirectedEdge(6, 7), UndirectedEdge(7, 0), UndirectedEdge(0, 4), UndirectedEdge(1, 5),
            UndirectedEdge(2, 6), UndirectedEdge(3, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-032 wheel W7: isPlanar")
    func pl032() {
        // U: nx(wheel,7); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(0, 6),
            UndirectedEdge(1, 2), UndirectedEdge(1, 6), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 6)])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-033 prism C5 × K2: isPlanar")
    func pl033() {
        // U: nx(circular_ladder,5); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5),
            UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 6), UndirectedEdge(2, 3),
            UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9),
            UndirectedEdge(5, 6), UndirectedEdge(5, 9), UndirectedEdge(6, 7), UndirectedEdge(7, 8),
            UndirectedEdge(8, 9)])
        #expect(graph.vertexCount == 10 && graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-034 grid 4 × 5: isPlanar")
    func pl034() {
        // U: grid(4,5); isPlanar → true
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 5, 1, 2, 1, 6, 2, 3, 2, 7, 3, 4, 3, 8, 4, 9, 5, 6, 5, 10, 6, 7, 6, 11,
            7, 8, 7, 12, 8, 9, 8, 13, 9, 14, 10, 11, 10, 15, 11, 12, 11, 16, 12, 13, 12, 17, 13, 14, 13, 18,
            14, 19, 15, 16, 16, 17, 17, 18, 18, 19]
        let graph = Pseudograph<Int>(vertices: 0 ..< 20, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 20 && graph.edgeCount == 31)
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-035 K5 with every edge subdivided: isPlanar")
    func pl035() {
        // U: sd(K(5)); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 15, edges: [UndirectedEdge(0, 5), UndirectedEdge(5, 1),
            UndirectedEdge(0, 6), UndirectedEdge(6, 2), UndirectedEdge(0, 7), UndirectedEdge(7, 3),
            UndirectedEdge(0, 8), UndirectedEdge(8, 4), UndirectedEdge(1, 9), UndirectedEdge(9, 2),
            UndirectedEdge(1, 10), UndirectedEdge(10, 3), UndirectedEdge(1, 11), UndirectedEdge(11, 4),
            UndirectedEdge(2, 12), UndirectedEdge(12, 3), UndirectedEdge(2, 13), UndirectedEdge(13, 4),
            UndirectedEdge(3, 14), UndirectedEdge(14, 4)])
        #expect(graph.vertexCount == 15 && graph.edgeCount == 20)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-036 K3,3 with every edge subdivided: isPlanar")
    func pl036() {
        // U: sd(KB(0..2;3..5)); isPlanar → false
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14], edges: [UndirectedEdge(0, 6),
            UndirectedEdge(6, 3), UndirectedEdge(0, 7), UndirectedEdge(7, 4), UndirectedEdge(0, 8),
            UndirectedEdge(8, 5), UndirectedEdge(1, 9), UndirectedEdge(9, 3), UndirectedEdge(1, 10),
            UndirectedEdge(10, 4), UndirectedEdge(1, 11), UndirectedEdge(11, 5), UndirectedEdge(2, 12),
            UndirectedEdge(12, 3), UndirectedEdge(2, 13), UndirectedEdge(13, 4), UndirectedEdge(2, 14),
            UndirectedEdge(14, 5)])
        #expect(graph.vertexCount == 15 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-037 path: isPlanar")
    func pl037() {
        // U: P(0..9); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 6),
            UndirectedEdge(6, 7), UndirectedEdge(7, 8), UndirectedEdge(8, 9)])
        #expect(graph.vertexCount == 10 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-038 cycle: isPlanar")
    func pl038() {
        // U: C(0..9); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 6),
            UndirectedEdge(6, 7), UndirectedEdge(7, 8), UndirectedEdge(8, 9), UndirectedEdge(9, 0)])
        #expect(graph.vertexCount == 10 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-039 star: isPlanar")
    func pl039() {
        // U: S(0;1..20); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 21, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(0, 6),
            UndirectedEdge(0, 7), UndirectedEdge(0, 8), UndirectedEdge(0, 9), UndirectedEdge(0, 10),
            UndirectedEdge(0, 11), UndirectedEdge(0, 12), UndirectedEdge(0, 13), UndirectedEdge(0, 14),
            UndirectedEdge(0, 15), UndirectedEdge(0, 16), UndirectedEdge(0, 17), UndirectedEdge(0, 18),
            UndirectedEdge(0, 19), UndirectedEdge(0, 20)])
        #expect(graph.vertexCount == 21 && graph.edgeCount == 20)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-040 stacked triangulation (maximal planar): isPlanar")
    func pl040() {
        // U: tri(30,1); isPlanar → true
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 2, 1, 2, 0, 3, 1, 3, 2, 3, 0, 4, 1, 4, 2, 4, 0, 5, 1, 5, 3, 5, 1, 6,
            3, 6, 5, 6, 1, 7, 2, 7, 4, 7, 1, 8, 4, 8, 7, 8, 2, 9, 4, 9, 7, 9, 1, 10, 3, 10, 6, 10, 0, 11,
            2, 11, 3, 11, 1, 12, 3, 12, 10, 12, 0, 13, 2, 13, 4, 13, 2, 14, 4, 14, 9, 14, 1, 15, 2, 15,
            7, 15, 4, 16, 7, 16, 8, 16, 4, 17, 7, 17, 9, 17, 4, 18, 7, 18, 16, 18, 3, 19, 6, 19, 10, 19,
            3, 20, 10, 20, 19, 20, 4, 21, 9, 21, 14, 21, 0, 22, 2, 22, 13, 22, 4, 23, 9, 23, 17, 23, 0, 24,
            1, 24, 4, 24, 7, 25, 16, 25, 18, 25, 2, 26, 3, 26, 11, 26, 0, 27, 3, 27, 11, 27, 3, 28, 10, 28,
            12, 28, 1, 29, 3, 29, 12, 29]
        let graph = Pseudograph<Int>(vertices: 0 ..< 30, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 30 && graph.edgeCount == 84)
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-041 maximal planar plus one edge: isPlanar")
    func pl041() {
        // U: tri(30,1), 3-4; isPlanar → false
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 2, 1, 2, 0, 3, 1, 3, 2, 3, 0, 4, 1, 4, 2, 4, 0, 5, 1, 5, 3, 5, 1, 6,
            3, 6, 5, 6, 1, 7, 2, 7, 4, 7, 1, 8, 4, 8, 7, 8, 2, 9, 4, 9, 7, 9, 1, 10, 3, 10, 6, 10, 0, 11,
            2, 11, 3, 11, 1, 12, 3, 12, 10, 12, 0, 13, 2, 13, 4, 13, 2, 14, 4, 14, 9, 14, 1, 15, 2, 15,
            7, 15, 4, 16, 7, 16, 8, 16, 4, 17, 7, 17, 9, 17, 4, 18, 7, 18, 16, 18, 3, 19, 6, 19, 10, 19,
            3, 20, 10, 20, 19, 20, 4, 21, 9, 21, 14, 21, 0, 22, 2, 22, 13, 22, 4, 23, 9, 23, 17, 23, 0, 24,
            1, 24, 4, 24, 7, 25, 16, 25, 18, 25, 2, 26, 3, 26, 11, 26, 0, 27, 3, 27, 11, 27, 3, 28, 10, 28,
            12, 28, 1, 29, 3, 29, 12, 29, 3, 4]
        let graph = Pseudograph<Int>(vertices: 0 ..< 30, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 30 && graph.edgeCount == 85)
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-042 K4 and a disjoint K4: isPlanar")
    func pl042() {
        // U: K(4), K(4..7); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 7), UndirectedEdge(5, 6),
            UndirectedEdge(5, 7), UndirectedEdge(6, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-043 K4 and a disjoint K5: isPlanar")
    func pl043() {
        // U: K(4), K(4..8); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 9, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 7), UndirectedEdge(4, 8),
            UndirectedEdge(5, 6), UndirectedEdge(5, 7), UndirectedEdge(5, 8), UndirectedEdge(6, 7),
            UndirectedEdge(6, 8), UndirectedEdge(7, 8)])
        #expect(graph.vertexCount == 9 && graph.edgeCount == 16)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-044 K5 with a pendant path: isPlanar")
    func pl044() {
        // U: K(5), 4-5, 5-6; isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 6)])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-045 two K5s sharing a vertex: isPlanar")
    func pl045() {
        // U: K(5), K(4..8); isPlanar → false
        let graph = Pseudograph<Int>(vertices: 0 ..< 9, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 7), UndirectedEdge(4, 8),
            UndirectedEdge(5, 6), UndirectedEdge(5, 7), UndirectedEdge(5, 8), UndirectedEdge(6, 7),
            UndirectedEdge(6, 8), UndirectedEdge(7, 8)])
        #expect(graph.vertexCount == 9 && graph.edgeCount == 20)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-046 chain of K4 blocks: isPlanar")
    func pl046() {
        // U: K(4), K(3..6), K(6..9); isPlanar → true
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
            UndirectedEdge(3, 4), UndirectedEdge(3, 5), UndirectedEdge(3, 6), UndirectedEdge(4, 5),
            UndirectedEdge(4, 6), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(6, 8),
            UndirectedEdge(6, 9), UndirectedEdge(7, 8), UndirectedEdge(7, 9), UndirectedEdge(8, 9)])
        #expect(graph.vertexCount == 10 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(graph.isPlanar == true)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == true)
        #expect((graph.findKuratowskiSubgraph() == nil) == true)
    }

    @Test("PL-047 random sparse graph: isPlanar")
    func pl047() {
        // U: lcg(30,45,3); isPlanar → false
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [29, 13, 5, 28, 24, 23, 25, 5, 29, 9, 13, 12, 26, 9, 28, 5, 9, 19, 7, 26, 5, 16,
            11, 6, 25, 24, 19, 24, 11, 19, 5, 18, 21, 3, 18, 19, 25, 9, 0, 16, 0, 17, 5, 19, 19, 8, 11, 16,
            25, 5, 16, 11, 5, 16, 14, 11, 1, 20, 7, 25, 5, 21, 11, 7, 29, 9, 12, 6, 29, 14, 3, 0, 7, 9,
            18, 15, 9, 19, 24, 6, 15, 13, 19, 1, 10, 16, 19, 15, 29, 15]
        let graph = Pseudograph<Int>(vertices: 0 ..< 30, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 30 && graph.edgeCount == 45)
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }

    @Test("PL-048 random graph, average degree 4: isPlanar")
    func pl048() {
        // U: lcg(30,60,7); isPlanar → false
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [8, 11, 3, 23, 25, 29, 4, 24, 19, 16, 25, 15, 2, 20, 9, 22, 15, 9, 6, 11, 16, 13,
            4, 18, 23, 24, 20, 5, 3, 22, 22, 7, 20, 25, 23, 29, 9, 7, 22, 12, 25, 5, 28, 20, 20, 14, 24, 14,
            26, 0, 2, 24, 17, 8, 14, 1, 28, 6, 6, 13, 19, 13, 23, 0, 0, 23, 2, 18, 21, 8, 20, 13, 28, 15,
            18, 1, 20, 24, 12, 5, 26, 12, 7, 29, 8, 7, 29, 19, 15, 21, 7, 4, 5, 6, 15, 23, 15, 2, 15, 24,
            14, 11, 11, 13, 18, 20, 25, 24, 2, 11, 20, 17, 17, 26, 28, 0, 20, 18, 2, 14]
        let graph = Pseudograph<Int>(vertices: 0 ..< 30, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 30 && graph.edgeCount == 60)
        #expect(graph.isPlanar == false)
        // The witnesses agree with the answer.
        #expect((graph.planarEmbedding() != nil) == false)
        #expect((graph.findKuratowskiSubgraph() == nil) == false)
    }
}
