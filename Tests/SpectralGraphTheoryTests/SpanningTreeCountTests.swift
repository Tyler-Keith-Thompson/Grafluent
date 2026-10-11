// Spanning tree counts (catalog SGT-148 – SGT-168): Kirchhoff's theorem, loops never on a tree,
// parallel edges each counted, weights multiplied; 0 when not connected or empty, 1 for one vertex.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory spanning tree counts")
struct SpanningTreeCountTests {
    @Test("SGT-148 empty graph: 0")
    func sgt148() {
        // U: · numberOfSpanningTrees() → 0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: [] as [Int], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        #expect(count == 0)
    }

    @Test("SGT-149 one vertex: 1")
    func sgt149() {
        // U: [0] · numberOfSpanningTrees() → 1
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 1) <= 1e-9 * 1)
    }

    @Test("SGT-150 two isolated vertices: 0")
    func sgt150() {
        // U: E(2) · numberOfSpanningTrees() → 0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        #expect(count == 0)
    }

    @Test("SGT-151 K2")
    func sgt151() {
        // U: K(2) · numberOfSpanningTrees() → 1
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 1) <= 1e-9 * 1)
    }

    @Test("SGT-152 K5: 5³")
    func sgt152() {
        // U: K(5) · numberOfSpanningTrees() → 125
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 125) <= 1e-9 * 125)
    }

    @Test("SGT-153 K10: 10⁸")
    func sgt153() {
        // U: K(10) · numberOfSpanningTrees() → 100000000
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (1, 2), (1, 3), (1, 4),
            (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9),
            (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (5, 6),
            (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 100000000) <= 1e-9 * 100000000)
    }

    @Test("SGT-154 K25: 25²³, past 2⁵³")
    func sgt154() {
        // U: K(25) · numberOfSpanningTrees() → 142108547152020037174224853515625 (≈ 1.421085472e+32)
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11), (0, 12),
            (0, 13), (0, 14), (0, 15), (0, 16), (0, 17), (0, 18), (0, 19), (0, 20), (0, 21), (0, 22), (0, 23), (0, 24),
            (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12), (1, 13),
            (1, 14), (1, 15), (1, 16), (1, 17), (1, 18), (1, 19), (1, 20), (1, 21), (1, 22), (1, 23), (1, 24), (2, 3),
            (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14), (2, 15),
            (2, 16), (2, 17), (2, 18), (2, 19), (2, 20), (2, 21), (2, 22), (2, 23), (2, 24), (3, 4), (3, 5), (3, 6),
            (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (3, 12), (3, 13), (3, 14), (3, 15), (3, 16), (3, 17), (3, 18),
            (3, 19), (3, 20), (3, 21), (3, 22), (3, 23), (3, 24), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10),
            (4, 11), (4, 12), (4, 13), (4, 14), (4, 15), (4, 16), (4, 17), (4, 18), (4, 19), (4, 20), (4, 21), (4, 22),
            (4, 23), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 12), (5, 13), (5, 14), (5, 15),
            (5, 16), (5, 17), (5, 18), (5, 19), (5, 20), (5, 21), (5, 22), (5, 23), (5, 24), (6, 7), (6, 8), (6, 9),
            (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (6, 15), (6, 16), (6, 17), (6, 18), (6, 19), (6, 20), (6, 21),
            (6, 22), (6, 23), (6, 24), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 15), (7, 16),
            (7, 17), (7, 18), (7, 19), (7, 20), (7, 21), (7, 22), (7, 23), (7, 24), (8, 9), (8, 10), (8, 11), (8, 12),
            (8, 13), (8, 14), (8, 15), (8, 16), (8, 17), (8, 18), (8, 19), (8, 20), (8, 21), (8, 22), (8, 23), (8, 24),
            (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (9, 15), (9, 16), (9, 17), (9, 18), (9, 19), (9, 20), (9, 21),
            (9, 22), (9, 23), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 17), (10, 18), (10, 19),
            (10, 20), (10, 21), (10, 22), (10, 23), (10, 24), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 18),
            (11, 19), (11, 20), (11, 21), (11, 22), (11, 23), (11, 24), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18),
            (12, 19), (12, 20), (12, 21), (12, 22), (12, 23), (12, 24), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19),
            (13, 20), (13, 21), (13, 22), (13, 23), (13, 24), (14, 15), (14, 16), (14, 17), (14, 18), (14, 19), (14, 20), (14, 21),
            (14, 22), (14, 23), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (15, 22), (15, 23), (15, 24),
            (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (16, 23), (16, 24), (17, 18), (17, 19), (17, 20), (17, 21),
            (17, 22), (17, 23), (17, 24), (18, 19), (18, 20), (18, 21), (18, 22), (18, 23), (18, 24), (19, 20), (19, 21), (19, 22),
            (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 25), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Exactly 142108547152020037174224853515625.
        #expect(abs(count - 1.4210854715202e+32) <= 1e-9 * 1.4210854715202e+32)
    }

    @Test("SGT-155 cycle C6")
    func sgt155() {
        // U: C(0..5) · numberOfSpanningTrees() → 6
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 6) <= 1e-9 * 6)
    }

    @Test("SGT-156 path P6")
    func sgt156() {
        // U: P(0..5) · numberOfSpanningTrees() → 1
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 1) <= 1e-9 * 1)
    }

    @Test("SGT-157 K3,3: 3²·3²")
    func sgt157() {
        // U: KB(0..2;3..5) · numberOfSpanningTrees() → 81
        let edges: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = ReferencePseudograph(vertices: [0, 3, 4, 5, 1, 2], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 81) <= 1e-9 * 81)
    }

    @Test("SGT-158 Petersen: 2000")
    func sgt158() {
        // U: nx(petersen) · numberOfSpanningTrees() → 2000
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 2000) <= 1e-9 * 2000)
    }

    @Test("SGT-159 hypercube Q3: 384")
    func sgt159() {
        // U: Q(3) · numberOfSpanningTrees() → 384
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 8), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 384) <= 1e-9 * 384)
    }

    @Test("SGT-160 hypercube Q4")
    func sgt160() {
        // U: Q(4) · numberOfSpanningTrees() → 42467328
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 4), (0, 8), (1, 3), (1, 5), (1, 9), (2, 3), (2, 6), (2, 10), (3, 7), (3, 11),
            (4, 5), (4, 6), (4, 12), (5, 7), (5, 13), (6, 7), (6, 14), (7, 15), (8, 9), (8, 10), (8, 12), (9, 11),
            (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (12, 14), (13, 15), (14, 15),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 16), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 42467328) <= 1e-9 * 42467328)
    }

    @Test("SGT-161 grid 3×3: 192")
    func sgt161() {
        // U: grid(3,3) · numberOfSpanningTrees() → 192
        let edges: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 9), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 192) <= 1e-9 * 192)
    }

    @Test("SGT-162 grid 8×8")
    func sgt162() {
        // U: grid(8,8) · numberOfSpanningTrees() → 126231322912498539682594816 (≈ 1.262313229e+26)
        let edges: [(Int, Int)] = [
            (0, 1), (0, 8), (1, 2), (1, 9), (2, 3), (2, 10), (3, 4), (3, 11), (4, 5), (4, 12), (5, 6), (5, 13),
            (6, 7), (6, 14), (7, 15), (8, 9), (8, 16), (9, 10), (9, 17), (10, 11), (10, 18), (11, 12), (11, 19), (12, 13),
            (12, 20), (13, 14), (13, 21), (14, 15), (14, 22), (15, 23), (16, 17), (16, 24), (17, 18), (17, 25), (18, 19), (18, 26),
            (19, 20), (19, 27), (20, 21), (20, 28), (21, 22), (21, 29), (22, 23), (22, 30), (23, 31), (24, 25), (24, 32), (25, 26),
            (25, 33), (26, 27), (26, 34), (27, 28), (27, 35), (28, 29), (28, 36), (29, 30), (29, 37), (30, 31), (30, 38), (31, 39),
            (32, 33), (32, 40), (33, 34), (33, 41), (34, 35), (34, 42), (35, 36), (35, 43), (36, 37), (36, 44), (37, 38), (37, 45),
            (38, 39), (38, 46), (39, 47), (40, 41), (40, 48), (41, 42), (41, 49), (42, 43), (42, 50), (43, 44), (43, 51), (44, 45),
            (44, 52), (45, 46), (45, 53), (46, 47), (46, 54), (47, 55), (48, 49), (48, 56), (49, 50), (49, 57), (50, 51), (50, 58),
            (51, 52), (51, 59), (52, 53), (52, 60), (53, 54), (53, 61), (54, 55), (54, 62), (55, 63), (56, 57), (57, 58), (58, 59),
            (59, 60), (60, 61), (61, 62), (62, 63),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 64), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Exactly 126231322912498539682594816.
        #expect(abs(count - 1.26231322912499e+26) <= 1e-9 * 1.26231322912499e+26)
    }

    @Test("SGT-163 doubled edge and pendant: 2")
    func sgt163() {
        // U: 0=1, 1-2 · numberOfSpanningTrees() → 2
        let edges: [(Int, Int)] = [(0, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 2) <= 1e-9 * 2)
    }

    @Test("SGT-164 loop ignored")
    func sgt164() {
        // U: 0-0, C(0,1,2) · numberOfSpanningTrees() → 3
        let edges: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 3) <= 1e-9 * 3)
    }

    @Test("SGT-165 weighted triangle: 1·2 + 2·3 + 1·3")
    func sgt165() {
        // U: C(0,1,2) · numberOfSpanningTrees(weight:) [1, 2, 3] → 11
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3]
        let count = graph.numberOfSpanningTrees(weight: { weights[$0] })
        #expect(abs(count - 11) <= 1e-9 * 11)
    }

    @Test("SGT-166 weighted, fractional")
    func sgt166() {
        // U: K(4) · numberOfSpanningTrees(weight:) [0.5, 1, 2, 1, 0.25, 3] → 185/8 (23.125)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Double] = [0.5, 1, 2, 1, 0.25, 3]
        let count = graph.numberOfSpanningTrees(weight: { weights[$0] })
        #expect(abs(count - 23.125) <= 1e-9 * 23.125)
    }

    @Test("SGT-167 disconnected: 0")
    func sgt167() {
        // U: C(0,1,2), C(3,4,5) · numberOfSpanningTrees() → 0
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        #expect(count == 0)
    }

    @Test("SGT-168 karate club")
    func sgt168() {
        // U: nx(karate_club) · numberOfSpanningTrees() → 5090996323019136
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13),
            (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30),
            (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6),
            (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33),
            (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29),
            (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32),
            (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 34), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let count = graph.numberOfSpanningTrees()
        // Unweighted below 2⁵³: rounded to an integer.
        #expect(count == count.rounded())
        #expect(abs(count - 5090996323019100.0) <= 1e-9 * 5090996323019100.0)
    }
}
