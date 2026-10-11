// Kemeny constant (catalog SGT-194 – SGT-204): Σ 1/μᵢ over N's nonzero eigenvalues, a loop counted
// twice in the degree; nil when not connected, 0 for zero or one vertex.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory Kemeny constant")
struct KemenyConstantTests {
    @Test("SGT-194 empty graph: 0")
    func sgt194() {
        // U: · kemenyConstant() → 0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: [] as [Int], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        #expect(value == 0)
    }

    @Test("SGT-195 one vertex: 0")
    func sgt195() {
        // U: [0] · kemenyConstant() → 0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        #expect(value == 0)
    }

    @Test("SGT-196 K2: 1/2")
    func sgt196() throws {
        // U: K(2) · kemenyConstant() → 0.5
        let edges: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        let result = try #require(value)
        #expect(abs(result - 0.5) <= 1e-9 * 1)
    }

    @Test("SGT-197 K5")
    func sgt197() throws {
        // U: K(5) · kemenyConstant() → 3.2
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        let result = try #require(value)
        #expect(abs(result - 3.2) <= 1e-9 * 3.2)
    }

    @Test("SGT-198 path P4")
    func sgt198() throws {
        // U: P(0..3) · kemenyConstant() → 3.166666667
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        let result = try #require(value)
        #expect(abs(result - 3.16666666666667) <= 1e-9 * 3.16666666666667)
    }

    @Test("SGT-199 cycle C6")
    func sgt199() throws {
        // U: C(0..5) · kemenyConstant() → 5.833333333
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        let result = try #require(value)
        #expect(abs(result - 5.8333333333333) <= 1e-9 * 5.8333333333333)
    }

    @Test("SGT-200 star K1,4")
    func sgt200() throws {
        // U: S(0;1..4) · kemenyConstant() → 3.5
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        let result = try #require(value)
        #expect(abs(result - 3.5) <= 1e-9 * 3.5)
    }

    @Test("SGT-201 self-loop counts twice in the degree")
    func sgt201() throws {
        // U: 0-0, P(0,1,2) · kemenyConstant() → 2.333333333
        let edges: [(Int, Int)] = [(0, 0), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        let result = try #require(value)
        #expect(abs(result - 2.33333333333333) <= 1e-9 * 2.33333333333333)
    }

    @Test("SGT-202 weighted")
    func sgt202() throws {
        // U: C(0,1,2) · kemenyConstant(weight:) [1, 2, 3] → 1.363636364
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3]
        let value = graph.kemenyConstant(weight: { weights[$0] })
        let result = try #require(value)
        #expect(abs(result - 1.36363636363636) <= 1e-9 * 1.36363636363636)
    }

    @Test("SGT-203 disconnected: nil")
    func sgt203() {
        // U: C(0,1,2), C(3,4,5) · kemenyConstant() → nil
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.kemenyConstant()
        #expect(value == nil)
    }

    @Test("SGT-204 karate club")
    func sgt204() throws {
        // U: nx(karate_club) · kemenyConstant() → 42.88668274
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
        let value = graph.kemenyConstant()
        let result = try #require(value)
        #expect(abs(result - 42.8866827394) <= 1e-9 * 42.8866827394)
    }
}
