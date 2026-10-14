// spectralLayout and multidimensionalScalingLayout (catalog DR-207 – DR-210, DR-234 – DR-236): the
// Laplacian's second and third eigenvectors, and classical scaling of the shortest-path
// distances, each axis signed by its first entry of magnitude at least 1e-4 of the largest.
// Within 1e-8.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphDrawing
import GraphProtocols
import Multigraphs
import SpectralGraphTheory
import Testing

@Suite("spectralLayout, multidimensionalScalingLayout")
struct SpectralLayoutTests {
    @Test("DR-207 spectral: path of 5 (Fiedler vector, then the third)")
    func dr207() throws {
        // U: P(0,1,2,3,4); spectralLayout() → [(0.601500955, 0.511667274), (0.371748034, -0.195439508), (0.0, -0.632455532), (-0.371748034, -0.195439508), (-0.601500955, 0.511667274)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 4)
        let layout = try graph.spectralLayout()
        let expected: [SIMD2<Double>] = [SIMD2(0.6015009550075457, 0.511667273601693), SIMD2(0.3717480344601847, -0.1954395075848546),
            SIMD2(1.7008385658262672e-16, -0.6324555320336762), SIMD2(-0.37174803446018445, -0.1954395075848549),
            SIMD2(-0.6015009550075457, 0.5116672736016931)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-8 && abs(a.y - b.y) <= 1e-8, "\(a) vs \(b)")
        }
    }

    @Test("DR-208 spectral: grid 3 x 4 (Fiedler vector, then the third)")
    func dr208() throws {
        // U: grid(3,4); spectralLayout() → [(0.37717224, 0.353553391), (0.156229857, 0.353553391), (-0.156229857, 0.353553391), (-0.37717224, 0.353553391), (0.37717224, 0.0), (0.156229857, 0.0), (-0.156229857, 0.0), (-0.37717224, 0.0), (0.37717224, -0.353553391), (0.156229857, -0.353553391), (-0.156229857, -0.353553391), (-0.37717224, -0.353553391)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 5),
            UndirectedEdge(2, 3), UndirectedEdge(2, 6), UndirectedEdge(3, 7), UndirectedEdge(4, 5), UndirectedEdge(4, 8), UndirectedEdge(5, 6),
            UndirectedEdge(5, 9), UndirectedEdge(6, 7), UndirectedEdge(6, 10), UndirectedEdge(7, 11), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 17)
        let layout = try graph.spectralLayout()
        let expected: [SIMD2<Double>] = [SIMD2(0.3771722397422859, 0.35355339059327356), SIMD2(0.15622985705189163, 0.35355339059327406),
            SIMD2(-0.15622985705189107, 0.3535533905932741), SIMD2(-0.37717223974228564, 0.35355339059327423),
            SIMD2(0.3771722397422858, -1.9738976946211769e-16), SIMD2(0.1562298570518914, 1.359524993133519e-16),
            SIMD2(-0.15622985705189096, 4.6016210886797196e-17), SIMD2(-0.37717223974228575, 1.9604085700959098e-16),
            SIMD2(0.37717223974228586, -0.3535533905932743), SIMD2(0.15622985705189107, -0.35355339059327384),
            SIMD2(-0.15622985705189144, -0.3535533905932738), SIMD2(-0.3771722397422859, -0.35355339059327334)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-8 && abs(a.y - b.y) <= 1e-8, "\(a) vs \(b)")
        }
    }

    @Test("DR-209 spectral: random graph, 12 vertices, 20 edges (Fiedler vector, then the third)")
    func dr209() throws {
        // U: lcggraph(12,20,9); spectralLayout() → [(0.119991788, 0.208651719), (0.419905181, -0.207746264), (-0.206606006, -0.00394076), (0.560565123, -0.541758472), (-0.269412496, -0.157327642), (0.227769069, 0.300045203), (-0.149251974, 0.047165543), (-0.286239529, -0.121372597), (-0.320589267, -0.195278678), (-0.083030931, 0.074618896), (0.232126938, 0.663287182), (-0.245227896, -0.06634413)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(11, 9), UndirectedEdge(7, 11), UndirectedEdge(8, 7), UndirectedEdge(3, 1),
            UndirectedEdge(0, 10), UndirectedEdge(5, 10), UndirectedEdge(2, 11), UndirectedEdge(11, 2), UndirectedEdge(2, 6), UndirectedEdge(7, 6),
            UndirectedEdge(1, 3), UndirectedEdge(11, 8), UndirectedEdge(1, 5), UndirectedEdge(5, 9), UndirectedEdge(2, 9), UndirectedEdge(8, 4),
            UndirectedEdge(9, 0), UndirectedEdge(0, 6), UndirectedEdge(9, 4), UndirectedEdge(1, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 20)
        let layout = try graph.spectralLayout()
        let expected: [SIMD2<Double>] = [SIMD2(0.11999178784961327, 0.20865171927924867), SIMD2(0.41990518116503517, -0.20774626375476513),
            SIMD2(-0.20660600554412434, -0.003940760256378286), SIMD2(0.5605651227367549, -0.5417584724437584),
            SIMD2(-0.269412496036185, -0.1573276419599728), SIMD2(0.2277690692014884, 0.3000452032858349), SIMD2(-0.1492519744370277, 0.04716554341957735),
            SIMD2(-0.2862395286802624, -0.12137259719149557), SIMD2(-0.32058926740783705, -0.19527867835803198),
            SIMD2(-0.08303093073754148, 0.07461889557660095), SIMD2(0.23212693753267988, 0.6632871819803753),
            SIMD2(-0.24522789564259287, -0.0663441295772348)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-8 && abs(a.y - b.y) <= 1e-8, "\(a) vs \(b)")
        }
    }

    @Test("DR-210 spectral: path of 5 has x = the Fiedler vector, y = the next eigenvector")
    func dr210() throws {
        // U: P(0,1,2,3,4); spectralLayout() vs fiedlerVector() → x equal
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let layout = try graph.spectralLayout()
        let fiedler = try #require(try graph.fiedlerVector()).values
        #expect(fiedler.count == 5)
        #expect(zip(layout.positions.map(\.x), fiedler).allSatisfy { abs($0 - $1) <= 1e-7 })
    }

    @Test("DR-234 a 3-4-5 triangle by edge length")
    func dr234() throws {
        // U: C(0,1,2); multidimensionalScalingLayout(edgeLength: { [3, 4, 5][$0] }) → [(2.15231099, 1.070203337), (0.65812881, -1.531223121), (-2.8104398, 0.461019785)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 3)
        let layout = try graph.multidimensionalScalingLayout(edgeLength: { [3, 4, 5][$0] })
        let expected: [SIMD2<Double>] = [SIMD2(2.152310989670858, 1.0702033365299461), SIMD2(0.658128810302622, -1.5312231211771306),
            SIMD2(-2.8104397999734787, 0.46101978464718474)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-8 && abs(a.y - b.y) <= 1e-8, "\(a) vs \(b)")
        }
    }

    @Test("DR-235 random graph, 12 vertices, 20 edges")
    func dr235() throws {
        // U: lcggraph(12,20,9); multidimensionalScalingLayout() → [(0.687990279, 0.428326719), (1.713338953, 0.11303063), (-0.976712677, 0.088331646), (2.664205146, 0.160804465), (-1.025072356, -1.183316197), (0.864970241, -1.282301596), (-0.170454309, 1.615027754), (-1.229913615, 0.880772961), (-2.3399563, -0.084934221), (-0.198587828, -0.622868154), (1.211277766, -0.013995596), (-1.201085299, -0.098878411)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(11, 9), UndirectedEdge(7, 11), UndirectedEdge(8, 7), UndirectedEdge(3, 1),
            UndirectedEdge(0, 10), UndirectedEdge(5, 10), UndirectedEdge(2, 11), UndirectedEdge(11, 2), UndirectedEdge(2, 6), UndirectedEdge(7, 6),
            UndirectedEdge(1, 3), UndirectedEdge(11, 8), UndirectedEdge(1, 5), UndirectedEdge(5, 9), UndirectedEdge(2, 9), UndirectedEdge(8, 4),
            UndirectedEdge(9, 0), UndirectedEdge(0, 6), UndirectedEdge(9, 4), UndirectedEdge(1, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 20)
        let layout = try graph.multidimensionalScalingLayout()
        let expected: [SIMD2<Double>] = [SIMD2(0.6879902792469099, 0.4283267192280083), SIMD2(1.7133389533441528, 0.11303062982458754),
            SIMD2(-0.9767126771311927, 0.08833164648632873), SIMD2(2.664205145575809, 0.16080446518418975), SIMD2(-1.02507235577395, -1.183316197226276),
            SIMD2(0.8649702407644898, -1.282301596391545), SIMD2(-0.17045430948204798, 1.6150277537208986), SIMD2(-1.229913614606794, 0.8807729613972758),
            SIMD2(-2.3399563002862402, -0.08493422106106421), SIMD2(-0.1985878284881542, -0.6228681539877124),
            SIMD2(1.2112777659123457, -0.013995596268230735), SIMD2(-1.2010852990753274, -0.09887841090645949)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-8 && abs(a.y - b.y) <= 1e-8, "\(a) vs \(b)")
        }
    }

    @Test("DR-236 an isolated vertex 1 + 3 sqrt 3 from both ends")
    func dr236() throws {
        // U: n=3; 0-1, 1-0; multidimensionalScalingLayout(edgeLength: { [2, 4][$0] }) → [(2.038308254, 1.0), (2.038308254, -1.0), (-4.076616508, 0.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 2)
        let layout = try graph.multidimensionalScalingLayout(edgeLength: { [2, 4][$0] })
        let expected: [SIMD2<Double>] = [SIMD2(2.0383082540134234, 1.0000000000000002), SIMD2(2.038308254013426, -1.0000000000000022),
            SIMD2(-4.076616508026849, -1.2347388919482756e-15)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-8 && abs(a.y - b.y) <= 1e-8, "\(a) vs \(b)")
        }
    }
}
