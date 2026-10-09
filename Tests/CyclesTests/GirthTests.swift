// §G: `girth()` on `Graph` and `DirectedGraph`: the least length of a cycle, so 1 with a loop and
// 2 with a parallel pair (undirected) or opposite arcs (directed); `nil` when acyclic, where
// NetworkX and igraph return inf, JGraphT Integer.MAX_VALUE and Boost 0. Named graphs from
// NetworkX (edges in NetworkX's order), JGraphT's GraphMetricsTest, igraph and Boost. Expected
// values come from the catalog's reference (`ref.py`), two independent computations. Case IDs
// (CY-nnn) refer to the catalog; see README.md.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("Girth")
struct GirthTests {
    @Test("CY-500 girth() is 4: NetworkX TestGirth (nxg=4)")
    func girth500() {
        // nx(chvatal)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4),
            (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11),
            (8, 10), (9, 10), (9, 11)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 11, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-501 girth() is 4: NetworkX (nxg=4)")
    func girth501() {
        // nx(tutte)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 4), (1, 26), (2, 10), (2, 11), (3, 18), (3, 19), (4, 5),
            (4, 33), (5, 6), (5, 29), (6, 7), (6, 27), (7, 8), (7, 14), (8, 9), (8, 38), (9, 10),
            (9, 37), (10, 39), (11, 12), (11, 39), (12, 13), (12, 35), (13, 14), (13, 15), (14, 34),
            (15, 16), (15, 22), (16, 17), (16, 44), (17, 18), (17, 43), (18, 45), (19, 20), (19, 45),
            (20, 21), (20, 41), (21, 22), (21, 23), (22, 40), (23, 24), (23, 27), (24, 25), (24, 32),
            (25, 26), (25, 31), (26, 33), (27, 28), (28, 29), (28, 32), (29, 30), (30, 31), (30, 33),
            (31, 32), (34, 35), (34, 38), (35, 36), (36, 37), (36, 39), (37, 38), (40, 41), (40, 44),
            (41, 42), (42, 43), (42, 45), (43, 44)
        ]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 34, 35, 36, 37, 40, 41, 42, 43, 33, 38, 39, 44, 45, 32], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-502 girth() is 5: NetworkX (nxg=5)")
    func girth502() {
        // nx(petersen)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7),
            (5, 8), (6, 8), (6, 9), (7, 9)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 5)
    }

    @Test("CY-503 girth() is 6: NetworkX (nxg=6)")
    func girth503() {
        // nx(heawood)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9),
            (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 13, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 6)
    }

    @Test("CY-504 girth() is 6: NetworkX (nxg=6)")
    func girth504() {
        // nx(pappus)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 17), (0, 5), (1, 2), (1, 8), (2, 3), (2, 13), (3, 4), (3, 10), (4, 5), (4, 15),
            (5, 6), (6, 7), (6, 11), (7, 8), (7, 14), (8, 9), (9, 10), (9, 16), (10, 11), (11, 12),
            (12, 13), (12, 17), (13, 14), (14, 15), (15, 16), (16, 17)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 17, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 6)
    }

    @Test("CY-505 girth() is nil: NetworkX random tree (nxg=inf)")
    func girth505() {
        // NetworkX inf, JGraphT Integer.MAX_VALUE, igraph inf: ours nil
        // [0..9] 0-6 0-4 1-5 1-2 1-8 2-3 3-4 3-7 8-9
        let pairs: [(Int, Int)] = [(0, 6), (0, 4), (1, 5), (1, 2), (1, 8), (2, 3), (3, 4), (3, 7), (8, 9)]
        let graph = ReferencePseudograph(vertices: 0 ... 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == nil)
    }

    @Test("CY-506 girth() is nil: NetworkX empty_graph(10)")
    func girth506() {
        // [0..9]
        let graph = ReferencePseudograph<Int>(vertices: 0 ... 9, edges: [])
        #expect(graph.girth() == nil)
    }

    @Test("CY-507 girth() is 4: NetworkX two disjoint cycles (nxg=4)")
    func girth507() {
        // [0,1,2,3,4,6,7,8,9] 0-1 0-4 1-2 2-3 3-4 6-7 6-9 7-8 8-9
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (2, 3), (3, 4), (6, 7), (6, 9), (7, 8), (8, 9)]
        let graph = ReferencePseudograph(vertices: [0, 1, 2, 3, 4, 6, 7, 8, 9], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-508 girth() is 3: NetworkX 11-edge graph (nxg=3)")
    func girth508() {
        // [0,6,8,9,1,2,4,5,7] 0-6 0-8 0-9 6-8 6-9 8-1 8-2 8-7 9-2 9-4 9-5
        let pairs: [(Int, Int)] = [
            (0, 6), (0, 8), (0, 9), (6, 8), (6, 9), (8, 1), (8, 2), (8, 7), (9, 2), (9, 4), (9, 5)
        ]
        let graph = ReferencePseudograph(vertices: [0, 6, 8, 9, 1, 2, 4, 5, 7], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 3)
    }

    @Test("CY-509 girth() is nil: JGraphT testGraphGirthAcyclic")
    func girth509() {
        // [0..5] 0-1 0-4 0-5 1-2 1-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 3)]
        let graph = ReferencePseudograph(vertices: 0 ... 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == nil)
    }

    @Test("CY-510 girth() is nil: JGraphT testGraphDirectedAcyclic")
    func girth510() {
        // D: [0..3] 0>1 0>2 1>3 2>3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == nil)
    }

    @Test("CY-511 girth() is 4: JGraphT testGraphDirectedCyclic (jgg=4)")
    func girth511() {
        // D: [0..3] 0>1 1>2 2>3 3>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-512 girth() is 2: JGraphT testGraphDirectedCyclic2 (jgg=2)")
    func girth512() {
        // D: [0,1] 0>1 1>0
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 2)
    }

    @Test("CY-513 girth() is 4: JGraphT grid 3 × 4 (jgg=4)")
    func girth513() {
        // grid(3,4)
        let pairs: [(Int, Int)] = [
            (0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9),
            (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 11, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-514 girth() is 10: JGraphT ring 10 (jgg=10)")
    func girth514() {
        // C(0..9)
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 0)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 10)
    }

    @Test("CY-515 girth() is 9: JGraphT ring 9 (jgg=9)")
    func girth515() {
        // C(0..8)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 9)
    }

    @Test("CY-516 girth() is 3: JGraphT wheel of 5 (jgg=3)")
    func girth516() {
        // W(0;1..4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 3)
    }

    @Test("CY-517 girth() is 2: JGraphT testGraphDirected1 (jgg=2)")
    func girth517() {
        // D: [0..3] 1>0 3>0 1>2 2>3 3>2
        let pairs: [(Int, Int)] = [(1, 0), (3, 0), (1, 2), (2, 3), (3, 2)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 2)
    }

    @Test("CY-518 girth() is 1: JGraphT testPseudoGraphUndirected (jgg=1 igg=4)")
    func girth518() {
        // igraph ignores loops and multi-edges
        // [0..3] 0-1 0-1 1-2 2-2 2-3 3-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 1)
    }

    @Test("CY-519 girth() is 1: JGraphT testPseudoGraphDirected (jgg=1)")
    func girth519() {
        // D: [0..3] 0>1 0>1 1>2 2>2 2>3 3>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 1)
    }

    @Test("CY-520 girth() is 2: JGraphT testMultiGraphUndirected (jgg=2 igg=4)")
    func girth520() {
        // [0..3] 0-1 0-1 1-2 2-3 3-0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 2)
    }

    @Test("CY-521 girth() is 4: JGraphT testMultiGraphDirected (jgg=4)")
    func girth521() {
        // Parallel arcs in one direction make no 2-cycle
        // D: [0..3] 0>1 0>1 1>2 2>3 3>0
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-522 girth() is 51: igraph igraph_girth.c (igg=51)")
    func girth522() {
        // C(0..99) 0-50
        let pairs: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9), (9, 10), (10, 11),
            (11, 12), (12, 13), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19), (19, 20),
            (20, 21), (21, 22), (22, 23), (23, 24), (24, 25), (25, 26), (26, 27), (27, 28), (28, 29),
            (29, 30), (30, 31), (31, 32), (32, 33), (33, 34), (34, 35), (35, 36), (36, 37), (37, 38),
            (38, 39), (39, 40), (40, 41), (41, 42), (42, 43), (43, 44), (44, 45), (45, 46), (46, 47),
            (47, 48), (48, 49), (49, 50), (50, 51), (51, 52), (52, 53), (53, 54), (54, 55), (55, 56),
            (56, 57), (57, 58), (58, 59), (59, 60), (60, 61), (61, 62), (62, 63), (63, 64), (64, 65),
            (65, 66), (66, 67), (67, 68), (68, 69), (69, 70), (70, 71), (71, 72), (72, 73), (73, 74),
            (74, 75), (75, 76), (76, 77), (77, 78), (78, 79), (79, 80), (80, 81), (81, 82), (82, 83),
            (83, 84), (84, 85), (85, 86), (86, 87), (87, 88), (88, 89), (89, 90), (90, 91), (91, 92),
            (92, 93), (93, 94), (94, 95), (95, 96), (96, 97), (97, 98), (98, 99), (99, 0), (0, 50)
        ]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 51)
    }

    @Test("CY-523 girth() is nil: igraph null graph")
    func girth523() {
        // []
        let graph = ReferencePseudograph<Int>(edges: [])
        #expect(graph.girth() == nil)
    }

    @Test("CY-524 girth() is 2: Boost tiernan_girth_and_circumference on the undirected ER graph (btg=3)")
    func girth524() {
        // Boost ignores the parallel pair 1–11
        // [0..19] 0-1 12-17 19-3 10-7 5-14 1-11 11-16 11-10 17-19 14-19 5-8 17-13 18-19 3-17 18-5 18-8 6-10 7-15 13-10 11-1
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 19, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 2)
    }

    @Test("CY-525 girth() is 2: Boost, directed ER (btg=2)")
    func girth525() {
        // D: [0..19] 0>1 12>17 19>3 10>7 5>14 1>11 11>16 11>10 17>19 14>19 5>8 17>13 18>19 3>17 18>5 18>8 6>10 7>15 13>10 11>1 12>8 11>16 9>15 1>3 4>15 1>3 12>11 14>6 8>18 19>11 3>13 6>9 1>2 3>8 0>10 9>11 13>1 1>16 7>3 3>19
        let pairs: [(Int, Int)] = [
            (0, 1), (12, 17), (19, 3), (10, 7), (5, 14), (1, 11), (11, 16), (11, 10), (17, 19),
            (14, 19), (5, 8), (17, 13), (18, 19), (3, 17), (18, 5), (18, 8), (6, 10), (7, 15),
            (13, 10), (11, 1), (12, 8), (11, 16), (9, 15), (1, 3), (4, 15), (1, 3), (12, 11), (14, 6),
            (8, 18), (19, 11), (3, 13), (6, 9), (1, 2), (3, 8), (0, 10), (9, 11), (13, 1), (1, 16),
            (7, 3), (3, 19)
        ]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ... 19, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 2)
    }

    @Test("CY-526 girth() is 2: Boost, undirected seed 42 (btg=4)")
    func girth526() {
        // [0..19] 0-11 5-8 13-19 12-14 0-4 15-10 9-0 17-9 16-15 10-11 9-17 15-8 17-7 18-0 1-6 6-8 19-12 12-3 18-17 17-18
        let pairs: [(Int, Int)] = [
            (0, 11), (5, 8), (13, 19), (12, 14), (0, 4), (15, 10), (9, 0), (17, 9), (16, 15), (10, 11),
            (9, 17), (15, 8), (17, 7), (18, 0), (1, 6), (6, 8), (19, 12), (12, 3), (18, 17), (17, 18)
        ]
        let graph = ReferencePseudograph(vertices: 0 ... 19, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 2)
    }

    @Test("CY-527 girth() is 3: K₃")
    func girth527() {
        // K(3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 3)
    }

    @Test("CY-528 girth() is nil: K₂")
    func girth528() {
        // K(2)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == nil)
    }

    @Test("CY-529 girth() is 1: self-loop")
    func girth529() {
        // 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 1)
    }

    @Test("CY-530 girth() is 2: parallel pair")
    func girth530() {
        // 0-1 0-1
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 2)
    }

    @Test("CY-531 girth() is 1: directed loop")
    func girth531() {
        // D: 0>0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 1)
    }

    @Test("CY-532 girth() is 4: K₃,₃")
    func girth532() {
        // KB(0..2;3..5)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 4)
    }

    @Test("CY-533 girth() is 1: loop far from the start vertex")
    func girth533() {
        // P(0..5) C(5,6,7) 7-7
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 5), (7, 7)]
        let graph = ReferencePseudograph(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.girth() == 1)
    }

    @Test("CY-534 girth() is 3: directed: shortest cycle not through vertex 0")
    func girth534() {
        // D: C(0..5) 3>1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (3, 1)]
        let graph = ReferenceDirectedMultigraph(edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.girth() == 3)
    }
}
