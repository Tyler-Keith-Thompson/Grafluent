// Resistance distance and effective graph resistance (catalog SGT-169 – SGT-193): weights are
// conductances; 0 from a vertex to itself; nil across components.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory resistance")
struct ResistanceTests {
    @Test("SGT-169 path: series")
    func sgt169() throws {
        // U: P(0..3) · resistanceDistance(from: 0, to: 3) → 3
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 3)
        let resistance = try #require(value)
        // 3
        #expect(abs(resistance - 3) <= 1e-6 * 3)
    }

    @Test("SGT-170 cycle C4: two paths of 2 in parallel")
    func sgt170() throws {
        // U: C(0..3) · resistanceDistance(from: 0, to: 2) → 1
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 2)
        let resistance = try #require(value)
        // 1
        #expect(abs(resistance - 1) <= 1e-6 * 1)
    }

    @Test("SGT-171 K4: 2/n")
    func sgt171() throws {
        // U: K(4) · resistanceDistance(from: 1, to: 2) → 1/2 (0.5)
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 1, to: 2)
        let resistance = try #require(value)
        // 1/2 (0.5)
        #expect(abs(resistance - 0.5) <= 1e-6 * 1)
    }

    @Test("SGT-172 same vertex: 0")
    func sgt172() {
        // U: K(4) · resistanceDistance(from: 2, to: 2) → 0
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 2, to: 2)
        #expect(value == 0)
    }

    @Test("SGT-173 different components: nil")
    func sgt173() {
        // U: C(0,1,2), C(3,4,5) · resistanceDistance(from: 0, to: 4) → nil
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 4)
        #expect(value == nil)
    }

    @Test("SGT-174 isolated vertex to itself: 0")
    func sgt174() {
        // U: [0,1]  · resistanceDistance(from: 1, to: 1) → 0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 1, to: 1)
        #expect(value == 0)
    }

    @Test("SGT-175 doubled edge: 1/2")
    func sgt175() throws {
        // U: 0=1 · resistanceDistance(from: 0, to: 1) → 1/2 (0.5)
        let edges: [(Int, Int)] = [(0, 1), (0, 1)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 2), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 1)
        let resistance = try #require(value)
        // 1/2 (0.5)
        #expect(abs(resistance - 0.5) <= 1e-6 * 1)
    }

    @Test("SGT-176 weights are conductances")
    func sgt176() throws {
        // U: P(0..2) · resistanceDistance(from: 0, to: 2) weight: [2, 4] → 3/4 (0.75)
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [2, 4]
        let value = graph.resistanceDistance(from: 0, to: 2, weight: { weights[$0] })
        let resistance = try #require(value)
        // 3/4 (0.75)
        #expect(abs(resistance - 0.75) <= 1e-6 * 1)
    }

    @Test("SGT-177 Wheatstone bridge")
    func sgt177() throws {
        // U: 0-1, 0-2, 1-2, 1-3, 2-3 · resistanceDistance(from: 0, to: 3) → 1
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 3)
        let resistance = try #require(value)
        // 1
        #expect(abs(resistance - 1) <= 1e-6 * 1)
    }

    @Test("SGT-178 Petersen, adjacent")
    func sgt178() throws {
        // U: nx(petersen) · resistanceDistance(from: 0, to: 1) → 3/5 (0.6)
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 1)
        let resistance = try #require(value)
        // 3/5 (0.6)
        #expect(abs(resistance - 0.6) <= 1e-6 * 1)
    }

    @Test("SGT-179 Petersen, at distance 2")
    func sgt179() throws {
        // U: nx(petersen) · resistanceDistance(from: 0, to: 2) → 4/5 (0.8)
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 2)
        let resistance = try #require(value)
        // 4/5 (0.8)
        #expect(abs(resistance - 0.8) <= 1e-6 * 1)
    }

    @Test("SGT-180 grid 3×3 corners")
    func sgt180() throws {
        // U: grid(3,3) · resistanceDistance(from: 0, to: 8) → 3/2 (1.5)
        let edges: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 9), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 8)
        let resistance = try #require(value)
        // 3/2 (1.5)
        #expect(abs(resistance - 1.5) <= 1e-6 * 1.5)
    }

    @Test("SGT-181 loop ignored")
    func sgt181() throws {
        // U: 1-1, P(0..2) · resistanceDistance(from: 0, to: 2) → 2
        let edges: [(Int, Int)] = [(1, 1), (0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: [1, 0, 2], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.resistanceDistance(from: 0, to: 2)
        let resistance = try #require(value)
        // 2
        #expect(abs(resistance - 2) <= 1e-6 * 2)
    }

    @Test("SGT-182 weight 0 disconnects: nil")
    func sgt182() {
        // U: P(0..2) · resistanceDistance(from: 0, to: 2) weight: [1, 0] → nil
        let edges: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 0]
        let value = graph.resistanceDistance(from: 0, to: 2, weight: { weights[$0] })
        #expect(value == nil)
    }

    @Test("SGT-185 empty graph: 0")
    func sgt185() {
        // U: · effectiveGraphResistance() → 0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: [] as [Int], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.effectiveGraphResistance()
        #expect(value == 0)
    }

    @Test("SGT-186 one vertex: 0")
    func sgt186() {
        // U: [0] · effectiveGraphResistance() → 0
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.effectiveGraphResistance()
        #expect(value == 0)
    }

    @Test("SGT-187 K5: n − 1")
    func sgt187() throws {
        // U: K(5) · effectiveGraphResistance() → 4
        let edges: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.effectiveGraphResistance()
        let result = try #require(value)
        // 4
        #expect(abs(result - 4) <= 1e-9 * 4)
    }

    @Test("SGT-188 path P4: the Wiener index")
    func sgt188() throws {
        // U: P(0..3) · effectiveGraphResistance() → 10
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 4), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.effectiveGraphResistance()
        let result = try #require(value)
        // 10
        #expect(abs(result - 10) <= 1e-9 * 10)
    }

    @Test("SGT-189 cycle C6")
    func sgt189() throws {
        // U: C(0..5) · effectiveGraphResistance() → 35/2 (17.5)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.effectiveGraphResistance()
        let result = try #require(value)
        // 35/2 (17.5)
        #expect(abs(result - 17.5) <= 1e-9 * 17.5)
    }

    @Test("SGT-190 Petersen")
    func sgt190() throws {
        // U: nx(petersen) · effectiveGraphResistance() → 33
        let edges: [(Int, Int)] = [
            (0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8),
            (6, 8), (6, 9), (7, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.effectiveGraphResistance()
        let result = try #require(value)
        // 33
        #expect(abs(result - 33) <= 1e-9 * 33)
    }

    @Test("SGT-191 weighted")
    func sgt191() throws {
        // U: C(0,1,2) · effectiveGraphResistance(weight:) [1, 2, 3] → 12/11 (1.090909091)
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 3), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 2, 3]
        let value = graph.effectiveGraphResistance(weight: { weights[$0] })
        let result = try #require(value)
        // 12/11 (1.090909091)
        #expect(abs(result - 1.0909090909091) <= 1e-9 * 1.0909090909091)
    }

    @Test("SGT-192 disconnected: nil")
    func sgt192() {
        // U: C(0,1,2), C(3,4,5) · effectiveGraphResistance() → nil
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 6), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let value = graph.effectiveGraphResistance()
        #expect(value == nil)
    }

    @Test("SGT-193 karate club")
    func sgt193() throws {
        // U: nx(karate_club) · effectiveGraphResistance() → 37408337509227643/79546817547174 (470.268185)
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
        let value = graph.effectiveGraphResistance()
        let result = try #require(value)
        // 37408337509227643/79546817547174 (470.268185)
        #expect(abs(result - 470.26818498481) <= 1e-9 * 470.26818498481)
    }
}
