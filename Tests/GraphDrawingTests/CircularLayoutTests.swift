// circularLayout (catalog DR-022 – DR-030): vertex i of n at center + radius (cos 2πi/n, sin 2πi/n),
// one vertex at the centre, edges not read. Compared within 1e-9 (cos and sin).
// Generated from cases.md by swiftgen.py; see README.md.

import GraphDrawing
import GraphProtocols
import Multigraphs
import Testing

@Suite("circularLayout")
struct CircularLayoutTests {
    @Test("DR-022 0 vertices")
    func dr022() {
        // U: n=0;; circularLayout() → []
        let graph = Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 0) && graph.edgeCount == 0)
        let layout = graph.circularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 0))
        let expected: [SIMD2<Double>] = []
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
    }

    @Test("DR-023 1 vertices: the centre")
    func dr023() {
        // U: n=1;; circularLayout() → [(0.0, 0.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 1) && graph.edgeCount == 0)
        let layout = graph.circularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 1))
        let expected: [SIMD2<Double>] = [SIMD2(0.0, 0.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).
        for p in layout.positions {
            let r = ((p - SIMD2(0.0, 0.0)) * (p - SIMD2(0.0, 0.0))).sum().squareRoot()
            #expect(abs(r - 0.0) <= 1e-9)
        }
    }

    @Test("DR-024 2 vertices")
    func dr024() {
        // U: n=2;; circularLayout() → [(1.0, 0.0), (-1.0, 0.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 0)
        let layout = graph.circularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 2))
        let expected: [SIMD2<Double>] = [SIMD2(1.0, 0.0), SIMD2(-1.0, 1.2246467991473532e-16)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).
        for p in layout.positions {
            let r = ((p - SIMD2(0.0, 0.0)) * (p - SIMD2(0.0, 0.0))).sum().squareRoot()
            #expect(abs(r - 1.0) <= 1e-9)
        }
    }

    @Test("DR-025 3 vertices")
    func dr025() {
        // U: n=3; C(0,1,2); circularLayout() → [(1.0, 0.0), (-0.5, 0.866025403784), (-0.5, -0.866025403784)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 3)
        let layout = graph.circularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 3))
        let expected: [SIMD2<Double>] = [SIMD2(1.0, 0.0), SIMD2(-0.49999999999999983, 0.8660254037844387), SIMD2(-0.5000000000000004, -0.8660254037844384)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).
        for p in layout.positions {
            let r = ((p - SIMD2(0.0, 0.0)) * (p - SIMD2(0.0, 0.0))).sum().squareRoot()
            #expect(abs(r - 1.0) <= 1e-9)
        }
    }

    @Test("DR-026 4 vertices")
    func dr026() {
        // U: n=4; C(0,1,2,3); circularLayout() → [(1.0, 0.0), (0.0, 1.0), (-1.0, 0.0), (0.0, -1.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 4)
        let layout = graph.circularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 4))
        let expected: [SIMD2<Double>] = [SIMD2(1.0, 0.0), SIMD2(6.123233995736766e-17, 1.0), SIMD2(-1.0, 1.2246467991473532e-16),
            SIMD2(-1.8369701987210297e-16, -1.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).
        for p in layout.positions {
            let r = ((p - SIMD2(0.0, 0.0)) * (p - SIMD2(0.0, 0.0))).sum().squareRoot()
            #expect(abs(r - 1.0) <= 1e-9)
        }
    }

    @Test("DR-027 6 vertices")
    func dr027() {
        // U: n=6; C(0,1,2,3,4,5); circularLayout() → [(1.0, 0.0), (0.5, 0.866025403784), (-0.5, 0.866025403784), (-1.0, 0.0), (-0.5, -0.866025403784), (0.5, -0.866025403784)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 6)
        let layout = graph.circularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 6))
        let expected: [SIMD2<Double>] = [SIMD2(1.0, 0.0), SIMD2(0.5000000000000001, 0.8660254037844386), SIMD2(-0.49999999999999983, 0.8660254037844387),
            SIMD2(-1.0, 1.2246467991473532e-16), SIMD2(-0.5000000000000004, -0.8660254037844384), SIMD2(0.5000000000000001, -0.8660254037844386)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).
        for p in layout.positions {
            let r = ((p - SIMD2(0.0, 0.0)) * (p - SIMD2(0.0, 0.0))).sum().squareRoot()
            #expect(abs(r - 1.0) <= 1e-9)
        }
    }

    @Test("DR-028 radius 2, centre (1, -1)")
    func dr028() {
        // U: n=4;; circularLayout(radius: 2, center: (1, -1)) → [(3.0, -1.0), (1.0, 1.0), (-1.0, -1.0), (1.0, -3.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 0)
        let layout = graph.circularLayout(radius: 2.0, center: SIMD2(1.0, -1.0))
        #expect(Array(layout.vertices) == Array(0 ..< 4))
        let expected: [SIMD2<Double>] = [SIMD2(3.0, -1.0), SIMD2(1.0000000000000002, 1.0), SIMD2(-1.0, -0.9999999999999998), SIMD2(0.9999999999999997, -3.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).
        for p in layout.positions {
            let r = ((p - SIMD2(1.0, -1.0)) * (p - SIMD2(1.0, -1.0))).sum().squareRoot()
            #expect(abs(r - 2.0) <= 1e-9)
        }
    }

    @Test("DR-029 edges do not matter: vertices order only")
    func dr029() {
        // U: n=3; 0-2, 2-1; circularLayout(center: (5, 5)) → [(6.0, 5.0), (4.5, 5.866025403784), (4.5, 4.133974596216)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 2), UndirectedEdge(2, 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 2)
        let layout = graph.circularLayout(center: SIMD2(5.0, 5.0))
        #expect(Array(layout.vertices) == Array(0 ..< 3))
        let expected: [SIMD2<Double>] = [SIMD2(6.0, 5.0), SIMD2(4.5, 5.866025403784438), SIMD2(4.5, 4.133974596215562)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).
        for p in layout.positions {
            let r = ((p - SIMD2(5.0, 5.0)) * (p - SIMD2(5.0, 5.0))).sum().squareRoot()
            #expect(abs(r - 1.0) <= 1e-9)
        }
    }

    @Test("DR-030 directed graph through its undirected view")
    func dr030() {
        // D: n=3; 0>1; undirected.circularLayout() → [(1.0, 0.0), (-0.5, 0.866025403784), (-0.5, -0.866025403784)]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 1)
        let layout = graph.undirected.circularLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 3))
        let expected: [SIMD2<Double>] = [SIMD2(1.0, 0.0), SIMD2(-0.49999999999999983, 0.8660254037844387), SIMD2(-0.5000000000000004, -0.8660254037844384)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        // Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).
        for p in layout.positions {
            let r = ((p - SIMD2(0.0, 0.0)) * (p - SIMD2(0.0, 0.0))).sum().squareRoot()
            #expect(abs(r - 1.0) <= 1e-9)
        }
    }
}
