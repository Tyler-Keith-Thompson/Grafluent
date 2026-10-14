// planarLayout (catalog DR-238 – DR-244): nil when the graph is not planar; otherwise integer points
// in [0, 2n − 4] × [0, n − 2], distinct, no two edges crossing and no vertex on an edge, counted
// inline from `positions`.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphDrawing
import GraphProtocols
import Multigraphs
import Testing

@Suite("planarLayout")
struct PlanarLayoutTests {
    @Test("DR-238 K4: integer points in [0, 2n - 4] x [0, n - 2], no crossing")
    func dr238() {
        // U: K(4); planarLayout() → #0 crossings
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2),
            UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        guard let layout = graph.planarLayout() else {
            Issue.record("no drawing")
            return
        }
        let p = layout.positions
        #expect(p.count == 4)
        for q in p {
            #expect(q.x == q.x.rounded() && q.y == q.y.rounded() && q.x >= 0 && q.y >= 0 && q.x <= 4 && q.y <= 2, "\(q)")
        }
        #expect(Set(p.map { [$0.x, $0.y] }).count == 4)
        func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Double {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }
        let segments = Array(Set(graph.edges.filter { $0.u != $0.v }.map { [min($0.u, $0.v), max($0.u, $0.v)] }))
        var bad = 0
        for s in segments {
            for v in 0 ..< 4 where v != s[0] && v != s[1] {
                let a = p[s[0]], b = p[s[1]], c = p[v]
                if orientation(a, b, c) == 0 && min(a.x, b.x) <= c.x && c.x <= max(a.x, b.x) && min(a.y, b.y) <= c.y && c.y <= max(a.y, b.y) { bad += 1 }
            }
        }
        for i in 0 ..< segments.count {
            for j in i + 1 ..< segments.count where Set(segments[i] + segments[j]).count == 4 {
                let s = segments[i], t = segments[j]
                if orientation(p[s[0]], p[s[1]], p[t[0]]) * orientation(p[s[0]], p[s[1]], p[t[1]]) < 0
                    && orientation(p[t[0]], p[t[1]], p[s[0]]) * orientation(p[t[0]], p[t[1]], p[s[1]]) < 0 { bad += 1 }
            }
        }
        #expect(bad == 0)
    }

    @Test("DR-239 grid 4 x 5: integer points in [0, 2n - 4] x [0, n - 2], no crossing")
    func dr239() {
        // U: grid(4,5); planarLayout() → #0 crossings
        let graph = Pseudograph<Int>(vertices: 0 ..< 20, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(16, 17), UndirectedEdge(17, 18), UndirectedEdge(18, 19)])
        #expect(Array(graph.vertices) == Array(0 ..< 20) && graph.edgeCount == 31)
        guard let layout = graph.planarLayout() else {
            Issue.record("no drawing")
            return
        }
        let p = layout.positions
        #expect(p.count == 20)
        for q in p {
            #expect(q.x == q.x.rounded() && q.y == q.y.rounded() && q.x >= 0 && q.y >= 0 && q.x <= 36 && q.y <= 18, "\(q)")
        }
        #expect(Set(p.map { [$0.x, $0.y] }).count == 20)
        func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Double {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }
        let segments = Array(Set(graph.edges.filter { $0.u != $0.v }.map { [min($0.u, $0.v), max($0.u, $0.v)] }))
        var bad = 0
        for s in segments {
            for v in 0 ..< 20 where v != s[0] && v != s[1] {
                let a = p[s[0]], b = p[s[1]], c = p[v]
                if orientation(a, b, c) == 0 && min(a.x, b.x) <= c.x && c.x <= max(a.x, b.x) && min(a.y, b.y) <= c.y && c.y <= max(a.y, b.y) { bad += 1 }
            }
        }
        for i in 0 ..< segments.count {
            for j in i + 1 ..< segments.count where Set(segments[i] + segments[j]).count == 4 {
                let s = segments[i], t = segments[j]
                if orientation(p[s[0]], p[s[1]], p[t[0]]) * orientation(p[s[0]], p[s[1]], p[t[1]]) < 0
                    && orientation(p[t[0]], p[t[1]], p[s[0]]) * orientation(p[t[0]], p[t[1]], p[s[1]]) < 0 { bad += 1 }
            }
        }
        #expect(bad == 0)
    }

    @Test("DR-240 Petersen: not planar")
    func dr240() {
        // U: petersen; planarLayout() → nil
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 0), UndirectedEdge(0, 5), UndirectedEdge(1, 6), UndirectedEdge(2, 7), UndirectedEdge(3, 8), UndirectedEdge(4, 9),
            UndirectedEdge(5, 7), UndirectedEdge(6, 8), UndirectedEdge(7, 9), UndirectedEdge(8, 5), UndirectedEdge(9, 6)])
        #expect(Array(graph.vertices) == Array(0 ..< 10) && graph.edgeCount == 15)
        #expect(graph.planarLayout() == nil)
    }

    @Test("DR-241 K5: not planar")
    func dr241() {
        // U: K(5); planarLayout() → nil
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(0, 4),
            UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 10)
        #expect(graph.planarLayout() == nil)
    }

    @Test("DR-242 K3,3: not planar")
    func dr242() {
        // U: 0-3, 0-4, 0-5, 1-3, 1-4, 1-5, 2-3, 2-4, 2-5; planarLayout() → nil
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 5)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 9)
        #expect(graph.planarLayout() == nil)
    }

    @Test("DR-243 two triangles and an isolated vertex, loops and parallel edges")
    func dr243() {
        // U: n=7; C(0,1,2), C(3,4,5), 0-1, 4-4; planarLayout() → #0 crossings
        let graph = Pseudograph<Int>(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 3), UndirectedEdge(0, 1), UndirectedEdge(4, 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 7) && graph.edgeCount == 8)
        guard let layout = graph.planarLayout() else {
            Issue.record("no drawing")
            return
        }
        let p = layout.positions
        #expect(p.count == 7)
        for q in p {
            #expect(q.x == q.x.rounded() && q.y == q.y.rounded() && q.x >= 0 && q.y >= 0 && q.x <= 10 && q.y <= 5, "\(q)")
        }
        #expect(Set(p.map { [$0.x, $0.y] }).count == 7)
        func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Double {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }
        let segments = Array(Set(graph.edges.filter { $0.u != $0.v }.map { [min($0.u, $0.v), max($0.u, $0.v)] }))
        var bad = 0
        for s in segments {
            for v in 0 ..< 7 where v != s[0] && v != s[1] {
                let a = p[s[0]], b = p[s[1]], c = p[v]
                if orientation(a, b, c) == 0 && min(a.x, b.x) <= c.x && c.x <= max(a.x, b.x) && min(a.y, b.y) <= c.y && c.y <= max(a.y, b.y) { bad += 1 }
            }
        }
        for i in 0 ..< segments.count {
            for j in i + 1 ..< segments.count where Set(segments[i] + segments[j]).count == 4 {
                let s = segments[i], t = segments[j]
                if orientation(p[s[0]], p[s[1]], p[t[0]]) * orientation(p[s[0]], p[s[1]], p[t[1]]) < 0
                    && orientation(p[t[0]], p[t[1]], p[s[0]]) * orientation(p[t[0]], p[t[1]], p[s[1]]) < 0 { bad += 1 }
            }
        }
        #expect(bad == 0)
    }

    @Test("DR-244 fewer than four vertices: (0, 0), (2, 0), (1, 1)")
    func dr244() throws {
        // U: P(0,1,2); planarLayout() → [(0.0, 0.0), (2.0, 0.0), (1.0, 1.0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 2)
        let layout = try #require(graph.planarLayout())
        #expect(layout.positions == [SIMD2(0.0, 0.0), SIMD2(2.0, 0.0), SIMD2(1.0, 1.0)])
    }
}
