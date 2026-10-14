// shellLayout, spiralLayout, bipartiteLayout, multipartiteLayout, bfsLayout and randomLayout
// (catalog DR-211, DR-212, DR-215 – DR-233): positions computed in double precision, within
// 1e-9 where they involve cos and sin, exact otherwise; rescaled rows are NetworkX's layouts.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import Testing

@Suite("Shell, spiral, column and random layouts")
struct ColumnAndShellLayoutTests {
    @Test("DR-211 bfs layout (NetworkX bfs_layout, start 0)")
    func dr211() {
        // U: P(0,1,2), 1-3, 3-4; bfsLayout(start: 0).rescaled() → [(-1.0, 0.0), (-0.375, 0.0), (0.25, -0.3125), (0.25, 0.3125), (0.875, 0.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(3, 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 4)
        let layout = graph.bfsLayout(start: 0).rescaled()
        let expected: [SIMD2<Double>] = [SIMD2(-1.0, 0.0), SIMD2(-0.375, 0.0), SIMD2(0.25, -0.3125), SIMD2(0.25, 0.3125), SIMD2(0.875, 0.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-212 multipartite layout (NetworkX multipartite_layout)")
    func dr212() {
        // U: n=5; 0-2, 1-3, 2-4` layers [0, 0, 1, 1, 2]; multipartiteLayout(layer: { [0, 0, 1, 1, 2][$0] }).rescaled() → [(-0.666666666667, -0.416666666667), (-0.666666666667, 0.416666666667), (0.166666666667, -0.416666666667), (0.166666666667, 0.416666666667), (1.0, 0.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 3)
        let layout = graph.multipartiteLayout(layer: { [0, 0, 1, 1, 2][$0] }).rescaled()
        let expected: [SIMD2<Double>] = [SIMD2(-0.666666666667, -0.416666666667), SIMD2(-0.666666666667, 0.416666666667),
            SIMD2(0.166666666667, -0.416666666667), SIMD2(0.166666666667, 0.416666666667), SIMD2(1.0, 0.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-215 one shell by default, starting at angle pi")
    func dr215() {
        // U: n=4; 0-1; shellLayout() → [(-1.0, 0.0), (0.0, -1.0), (1.0, 0.0), (0.0, 1.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 1)
        let layout = graph.shellLayout()
        let expected: [SIMD2<Double>] = [SIMD2(-1.0, 0.0), SIMD2(0.0, -1.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-216 a first shell of one vertex at the centre")
    func dr216() {
        // U: P(0,1,2,3); shellLayout(shells: [[0], [1, 2, 3]]) → [(0.0, 0.0), (-0.5, 0.0), (0.25, -0.433012701892), (0.25, 0.433012701892)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layout = graph.shellLayout(shells: [[0], [1, 2, 3]])
        let expected: [SIMD2<Double>] = [SIMD2(0.0, 0.0), SIMD2(-0.5, 0.0), SIMD2(0.25, -0.433012701892), SIMD2(0.25, 0.433012701892)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-217 radius 3, centre (10, -1), rotation 0, an empty shell keeps its radius")
    func dr217() {
        // U: n=3;; shellLayout(shells: [[2, 0], [], [1]], rotation: 0, radius: 3, center: (10, -1)) → [(9.0, -1.0), (13.0, -1.0), (11.0, -1.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 0)
        let layout = graph.shellLayout(shells: [[2, 0], [], [1]], rotation: 0, radius: 3, center: SIMD2(10, -1))
        let expected: [SIMD2<Double>] = [SIMD2(9.0, -1.0), SIMD2(13.0, -1.0), SIMD2(11.0, -1.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-218 one vertex at the centre")
    func dr218() {
        // U: n=1; 0-0; shellLayout(center: (2, 3)) → [(2.0, 3.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 1) && graph.edgeCount == 1)
        let layout = graph.shellLayout(center: SIMD2(2, 3))
        let expected: [SIMD2<Double>] = [SIMD2(2.0, 3.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-221 4 vertices")
    func dr221() {
        // U: P(0,1,2,3); spiralLayout() → [(0.0, 0.0), (0.939372712847, 0.342897807455), (1.529684374569, 1.288435374475), (1.492713143675, 2.602269676782)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layout = graph.spiralLayout()
        let expected: [SIMD2<Double>] = [SIMD2(0.0, 0.0), SIMD2(0.939372712847, 0.342897807455), SIMD2(1.529684374569, 1.288435374475),
            SIMD2(1.492713143675, 2.602269676782)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-222 rescaled: NetworkX spiral_layout")
    func dr222() {
        // U: P(0,1,2,3); spiralLayout().rescaled() → [(-0.641532786839, -0.685550872942), (-0.03307913183, -0.46344795108), (0.349279524385, 0.148998824022), (0.325332394284, 1.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 3)
        let layout = graph.spiralLayout().rescaled()
        let expected: [SIMD2<Double>] = [SIMD2(-0.641532786839, -0.685550872942), SIMD2(-0.03307913183, -0.46344795108),
            SIMD2(0.349279524385, 0.148998824022), SIMD2(0.325332394284, 1.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-223 equidistant: 6 vertices")
    func dr223() {
        // U: n=6;; spiralLayout(equidistant: true) → [(3.013516027473, 0.335576307694), (2.914355125446, 1.314388253166), (2.516948064363, 2.21596795282), (1.870573838809, 2.961203483849), (1.039136799099, 3.49404434281), (0.093391837272, 3.781301743443)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 0)
        let layout = graph.spiralLayout(equidistant: true)
        let expected: [SIMD2<Double>] = [SIMD2(3.013516027473, 0.335576307694), SIMD2(2.914355125446, 1.314388253166), SIMD2(2.516948064363, 2.21596795282),
            SIMD2(1.870573838809, 2.961203483849), SIMD2(1.039136799099, 3.49404434281), SIMD2(0.093391837272, 3.781301743443)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-224 equidistant, rescaled: NetworkX spiral_layout")
    func dr224() {
        // U: n=6;; spiralLayout(equidistant: true).rescaled() → [(0.548693950976, -1.0), (0.499478613123, -0.514198039693), (0.30223834628, -0.066727831048), (-0.018568798871, 0.303145956802), (-0.431225944741, 0.567604451625), (-0.900616166767, 0.710175462314)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 0)
        let layout = graph.spiralLayout(equidistant: true).rescaled()
        let expected: [SIMD2<Double>] = [SIMD2(0.548693950976, -1.0), SIMD2(0.499478613123, -0.514198039693), SIMD2(0.30223834628, -0.066727831048),
            SIMD2(-0.018568798871, 0.303145956802), SIMD2(-0.431225944741, 0.567604451625), SIMD2(-0.900616166767, 0.710175462314)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-226 K3,3, the left column as given, the right in vertices order")
    func dr226() {
        // U: 0-3, 0-4, 0-5, 1-3, 1-4, 1-5, 2-3, 2-4, 2-5; bipartiteLayout(left: [5, 3, 4]) → [(0.6666666666666666, -0.5), (0.6666666666666666, 0.0), (0.6666666666666666, 0.5), (-0.6666666666666666, 0.0), (-0.6666666666666666, 0.5), (-0.6666666666666666, -0.5)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 9)
        let layout = graph.bipartiteLayout(left: [5, 3, 4])
        #expect(layout.positions == [SIMD2(0.6666666666666666, -0.5), SIMD2(0.6666666666666666, 0.0), SIMD2(0.6666666666666666, 0.5),
            SIMD2(-0.6666666666666666, 0.0), SIMD2(-0.6666666666666666, 0.5), SIMD2(-0.6666666666666666, -0.5)])
    }

    @Test("DR-227 rescaled: NetworkX bipartite_layout")
    func dr227() {
        // U: 0-3, 0-4, 0-5, 1-3, 1-4, 1-5, 2-3, 2-4, 2-5; bipartiteLayout(left: [3, 4, 5]).rescaled() → [(1.0, -0.75), (1.0, 0.0), (1.0, 0.75), (-1.0, -0.75), (-1.0, 0.0), (-1.0, 0.75)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 9)
        let layout = graph.bipartiteLayout(left: [3, 4, 5]).rescaled()
        let expected: [SIMD2<Double>] = [SIMD2(1.0, -0.75), SIMD2(1.0, 0.0), SIMD2(1.0, 0.75), SIMD2(-1.0, -0.75), SIMD2(-1.0, 0.0), SIMD2(-1.0, 0.75)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12, "\(a) vs \(b)")
        }
    }

    @Test("DR-228 a column of one vertex at y = -1/2, aspect ratio 2")
    func dr228() {
        // U: n=3; 0-1; bipartiteLayout(left: [1], aspectRatio: 2) → [(1.0, -0.5), (-1.0, -0.5), (1.0, 0.5)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 1)
        let layout = graph.bipartiteLayout(left: [1], aspectRatio: 2)
        #expect(layout.positions == [SIMD2(1.0, -0.5), SIMD2(-1.0, -0.5), SIMD2(1.0, 0.5)])
    }

    @Test("DR-230 layers sorted, gaps make no empty column, vertices order within a column")
    func dr230() {
        // U: n=6;` layers [7, -3, 7, 100, 7, -3]; multipartiteLayout(layer: { [7, -3, 7, 100, 7, -3][$0] }) → [(0.0, -1.0), (-1.0, -0.5), (0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (-1.0, 0.5)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 0)
        let layout = graph.multipartiteLayout(layer: { [7, -3, 7, 100, 7, -3][$0] })
        #expect(layout.positions == [SIMD2(0.0, -1.0), SIMD2(-1.0, -0.5), SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0), SIMD2(-1.0, 0.5)])
    }

    @Test("DR-231 discovery order within a column")
    func dr231() {
        // U: n=4; 0-3, 0-2, 0-2, 2-2, 1-2; bfsLayout(start: 0) → [(-1.0, 0.0), (1.0, 0.0), (0.0, 0.5), (0.0, -0.5)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 3), UndirectedEdge(0, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 2),
            UndirectedEdge(1, 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 5)
        let layout = graph.bfsLayout(start: 0)
        #expect(layout.positions == [SIMD2(-1.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 0.5), SIMD2(0.0, -0.5)])
    }

    @Test("DR-233 x then y per vertex, the top 53 bits of each draw")
    func dr233() {
        // U: n=5; 0-1; randomLayout(using: &Xoshiro256StarStar(seed: 7)) → [(0.7005764821796896, 0.2787512294737843), (0.8396274618764198, 0.9810977250149351), (0.9908602788330683, 0.872773938745132), (0.060752079492816136, 0.1044357892428116), (0.40370652610252655, 0.15181610733412043)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 1)
        var generator = Xoshiro256StarStar(seed: 7)
        let layout = graph.randomLayout(using: &generator)
        #expect(layout.positions == [SIMD2(0.7005764821796896, 0.2787512294737843), SIMD2(0.8396274618764198, 0.9810977250149351),
            SIMD2(0.9908602788330683, 0.872773938745132), SIMD2(0.060752079492816136, 0.1044357892428116), SIMD2(0.40370652610252655, 0.15181610733412043)])
        var replay = Xoshiro256StarStar(seed: 7)
        for _ in 0 ..< 10 { _ = replay.next() }
        #expect(generator.next() == replay.next())
    }
}
