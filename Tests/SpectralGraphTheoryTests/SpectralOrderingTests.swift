// Spectral ordering (catalog SGT-127 – SGT-134): components by least vertex index, components of at
// most two vertices in index order, larger ones by their Fiedler vector with ties in index order.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory spectral ordering")
struct SpectralOrderingTests {
    @Test("SGT-127 path in shuffled order")
    func sgt127() throws {
        // U: P(2,0,4,1,3) · spectralOrdering() → [3, 1, 4, 0, 2]
        let edges: [(Int, Int)] = [(2, 0), (0, 4), (4, 1), (1, 3)]
        let graph = ReferencePseudograph(vertices: [2, 0, 4, 1, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(try graph.spectralOrdering() == [3, 1, 4, 0, 2])
    }

    @Test("SGT-128 barbell")
    func sgt128() throws {
        // U: K(0..3), K(4..7), 3-4 · spectralOrdering() → [5, 6, 7, 4, 3, 0, 1, 2] (ties: index order within tolerance)
        let edges: [(Int, Int)] = [
            (0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7),
            (3, 4),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 8), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let order = try graph.spectralOrdering()
        // Ties: the order relies on the tie rule, so it is checked against the returned
        // Fiedler vector, and against the catalog list wherever the model's entries differ by
        // more than 1e-4.
        let catalog = [5, 6, 7, 4, 3, 0, 1, 2]
        #expect(order.sorted() == catalog.sorted())
        let fiedler = try #require(try graph.fiedlerVector())
        for (a, b) in zip(order, order.dropFirst()) {
            #expect(fiedler.value(of: a) <= fiedler.value(of: b) + 1e-6, "\(a) before \(b)")
        }
        let model: [Double] = [-0.38252766196473, -0.38252766196473, -0.38252766196473, -0.2470177392322, 0.2470177392322, 0.38252766196473, 0.38252766196473, 0.38252766196473]
        let position = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        for i in catalog.indices {
            for j in catalog.indices where j > i && model[j] - model[i] > 1e-4 {
                #expect(position[catalog[i]]! < position[catalog[j]]!, "\(catalog[i]) before \(catalog[j])")
            }
        }
    }

    @Test("SGT-129 components by least vertex; small ones in index order")
    func sgt129() throws {
        // U: [0,1,2,3,4,5,6,7] P(5,1,6), 3-4, P(0,7,2) · spectralOrdering() → [2, 7, 0, 6, 1, 5, 3, 4]
        let edges: [(Int, Int)] = [(5, 1), (1, 6), (3, 4), (0, 7), (7, 2)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 8), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(try graph.spectralOrdering() == [2, 7, 0, 6, 1, 5, 3, 4])
    }

    @Test("SGT-130 grid 2×5: tied entries in index order")
    func sgt130() throws {
        // U: grid(2,5) · spectralOrdering() → [4, 9, 3, 8, 2, 7, 1, 6, 0, 5] (ties: index order within tolerance)
        let edges: [(Int, Int)] = [
            (0, 1), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 6), (6, 7), (7, 8),
            (8, 9),
        ]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 10), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let order = try graph.spectralOrdering()
        // Ties: the order relies on the tie rule, so it is checked against the returned
        // Fiedler vector, and against the catalog list wherever the model's entries differ by
        // more than 1e-4.
        let catalog = [4, 9, 3, 8, 2, 7, 1, 6, 0, 5]
        #expect(order.sorted() == catalog.sorted())
        let fiedler = try #require(try graph.fiedlerVector())
        for (a, b) in zip(order, order.dropFirst()) {
            #expect(fiedler.value(of: a) <= fiedler.value(of: b) + 1e-6, "\(a) before \(b)")
        }
        let model: [Double] = [
            -0.42532540417602, -0.42532540417602, -0.26286555605957, -0.26286555605957, -6e-16, -6e-16, 0.26286555605957, 0.26286555605957,
            0.42532540417602, 0.42532540417602,
        ]
        let position = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        for i in catalog.indices {
            for j in catalog.indices where j > i && model[j] - model[i] > 1e-4 {
                #expect(position[catalog[i]]! < position[catalog[j]]!, "\(catalog[i]) before \(catalog[j])")
            }
        }
    }

    @Test("SGT-131 weighted path")
    func sgt131() throws {
        // U: P(0..4) · spectralOrdering(weight:) [1, 3, 1, 3] → [4, 3, 2, 1, 0]
        let edges: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 5), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let weights: [Int] = [1, 3, 1, 3]
        #expect(try graph.spectralOrdering(weight: { weights[$0] }) == [4, 3, 2, 1, 0])
    }

    @Test("SGT-132 karate club")
    func sgt132() throws {
        // U: nx(karate_club) · spectralOrdering() → [26, 29, 14, 15, 18, 20, 22, 25, 23, 24, 32, 27, 33, 31, 28, 9, 30, 8, 2, 19, 13, 1, 7, 3, 17, 21, 12, 0, 11, 4, 10, 5, 6, 16] (ties: index order within tole…
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
        let order = try graph.spectralOrdering()
        // Ties: the order relies on the tie rule, so it is checked against the returned
        // Fiedler vector, and against the catalog list wherever the model's entries differ by
        // more than 1e-4.
        let catalog = [
            26, 29, 14, 15, 18, 20, 22, 25, 23, 24, 32, 27, 33, 31, 28, 9, 30, 8, 2, 19, 13, 1, 7, 3,
            17, 21, 12, 0, 11, 4, 10, 5, 6, 16,
        ]
        #expect(order.sorted() == catalog.sorted())
        let fiedler = try #require(try graph.fiedlerVector())
        for (a, b) in zip(order, order.dropFirst()) {
            #expect(fiedler.value(of: a) <= fiedler.value(of: b) + 1e-6, "\(a) before \(b)")
        }
        let model: [Double] = [
            -0.18710956349329, -0.16765031326034, -0.16275078473568, -0.16275078473568, -0.16275078473568, -0.16275078473568, -0.16275078473568, -0.16096292141292,
            -0.15569456736395, -0.1530255806008, -0.1303454580847, -0.1276640485189, -0.11890326307255, -0.0987534270285, -0.09515229952361, -0.09280088795114,
            -0.07349963560436, -0.05160127594533, -0.02321895576433, 0.0136371326787, 0.01474197382708, 0.04128788811914, 0.05258600372364, 0.05549978091414,
            0.10018142192335, 0.10018142192335, 0.10946129583494, 0.11213743230966, 0.21099295383989, 0.28460452516293, 0.28460452516293, 0.323727218344,
            0.323727218344, 0.42276532919537,
        ]
        let position = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        for i in catalog.indices {
            for j in catalog.indices where j > i && model[j] - model[i] > 1e-4 {
                #expect(position[catalog[i]]! < position[catalog[j]]!, "\(catalog[i]) before \(catalog[j])")
            }
        }
    }

    @Test("SGT-133 one vertex")
    func sgt133() throws {
        // U: [0] · spectralOrdering() → [0]
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: Array(0 ..< 1), edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(try graph.spectralOrdering() == [0])
    }

    @Test("SGT-134 empty graph")
    func sgt134() throws {
        // U: · spectralOrdering() → []
        let edges: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: [] as [Int], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        #expect(try graph.spectralOrdering() == [] as [Int])
    }
}
