// planarLayout (de Fraysseix–Pach–Pollack in Chrobak–Payne's form): nil for K5 and K3,3; on
// planar graphs, integer coordinates in [0, 2n − 4] × [0, n − 2], distinct points, and no two edges
// crossing, overlapping, or passing through a vertex (exact orientation tests on the integer
// grid). Small graphs, components, isolated vertices, self-loops and parallel edges, maximal
// planar graphs, trees, String vertices, and directed graphs through undirectedView.

import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import Multigraphs
import Testing

@Suite("planarLayout invariants")
struct PlanarLayoutInvariantTests {
    @Test("K5 and K3,3 have no planar drawing")
    func nonPlanar() {
        var k5: [UndirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { k5.append(UndirectedEdge(u, v)) } }
        #expect(Pseudograph<Int>(vertices: 0 ..< 5, edges: k5).planarLayout() == nil)
        var k33: [UndirectedEdge<Int>] = []
        for u in 0 ..< 3 { for v in 3 ..< 6 { k33.append(UndirectedEdge(u, v)) } }
        #expect(UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: k33).planarLayout() == nil)
        // K5 less one edge is planar.
        #expect(Pseudograph<Int>(vertices: 0 ..< 5, edges: Array(k5.dropLast())).planarLayout() != nil)
    }

    @Test("fewer than four vertices: (0, 0), (2, 0), (1, 1) in order")
    func small() throws {
        #expect(try #require(Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).planarLayout()).isEmpty)
        #expect(try #require(Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)]).planarLayout()).positions == [SIMD2(0, 0)])
        #expect(try #require(Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]).planarLayout()).positions == [SIMD2(0, 0), SIMD2(2, 0)])
        #expect(try #require(Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)]).planarLayout()).positions == [SIMD2(0, 0), SIMD2(2, 0), SIMD2(1, 1)])
        #expect(try #require(Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).planarLayout()).positions == [SIMD2(0, 0), SIMD2(2, 0), SIMD2(1, 1)])
        #expect(try #require(Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(2, 1)]).planarLayout()).positions == [SIMD2(0, 0), SIMD2(2, 0), SIMD2(1, 1)])
        #expect(try #require(Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(2, 0), UndirectedEdge(2, 1), UndirectedEdge(0, 1)]).planarLayout()).positions == [SIMD2(0, 0), SIMD2(2, 0), SIMD2(1, 1)])
    }

    @Test("planar graphs: integer grid points within bounds, distinct, no crossing")
    func drawings() throws {
        func grid(_ r: Int, _ c: Int) -> [(Int, Int)] {
            var pairs: [(Int, Int)] = []
            for i in 0 ..< r {
                for j in 0 ..< c {
                    if j + 1 < c { pairs.append((i * c + j, i * c + j + 1)) }
                    if i + 1 < r { pairs.append((i * c + j, (i + 1) * c + j)) }
                }
            }
            return pairs
        }
        let octahedron = [(0, 1), (0, 2), (0, 3), (0, 4), (5, 1), (5, 2), (5, 3), (5, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
        let dodecahedron = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (0, 5), (1, 6), (2, 7), (3, 8), (4, 9), (5, 10), (10, 6), (6, 11), (11, 7), (7, 12),
                            (12, 8), (8, 13), (13, 9), (9, 14), (14, 5), (10, 15), (11, 16), (12, 17), (13, 18), (14, 19), (15, 16), (16, 17), (17, 18),
                            (18, 19), (19, 15)]
        let cases: [(String, Int, [(Int, Int)])] = [
            ("K4", 4, [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]),
            ("path", 6, (0 ..< 5).map { ($0, $0 + 1) }),
            ("cycle", 7, (0 ..< 7).map { ($0, ($0 + 1) % 7) }),
            ("star", 8, (1 ..< 8).map { (0, $0) }),
            ("no edges", 5, []),
            ("two triangles and an isolated vertex", 7, [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)]),
            ("grid 4 x 5", 20, grid(4, 5)),
            ("wheel", 9, (1 ..< 9).map { (0, $0) } + (1 ..< 9).map { ($0, $0 % 8 + 1) }),
            ("octahedron", 6, octahedron),
            ("dodecahedron", 20, dodecahedron),
            ("K2,6", 8, (2 ..< 8).flatMap { [(0, $0), (1, $0)] }),
            ("a tree with two cut vertices", 9, [(0, 1), (1, 2), (1, 3), (3, 4), (4, 5), (4, 6), (6, 7), (6, 8)]),
            ("loops and parallel edges", 5, [(0, 1), (1, 0), (0, 1), (1, 1), (1, 2), (2, 3), (3, 0), (2, 0), (4, 4), (3, 4), (4, 3)]),
        ]
        for (name, n, pairs) in cases {
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let layout = try #require(graph.planarLayout(), "\(name)")
            let p = layout.positions
            #expect(p.count == n)
            for q in p {
                #expect(q.x == q.x.rounded() && q.y == q.y.rounded(), "\(name): \(q) is not a grid point")
                #expect(q.x >= 0 && q.x <= Double(2 * n - 4) && q.y >= 0 && q.y <= Double(n - 2), "\(name): \(q) out of bounds")
            }
            #expect(Set(p.map { [$0.x, $0.y] }).count == n, "\(name): two vertices share a point")
            func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Double {
                (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
            }
            func onSegment(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Bool {
                orientation(a, b, c) == 0 && min(a.x, b.x) <= c.x && c.x <= max(a.x, b.x) && min(a.y, b.y) <= c.y && c.y <= max(a.y, b.y)
            }
            let segments = Set(pairs.filter { $0.0 != $0.1 }.map { [min($0.0, $0.1), max($0.0, $0.1)] }).map { ($0[0], $0[1]) }
            for (a, b) in segments {
                for v in 0 ..< n where v != a && v != b {
                    #expect(!onSegment(p[a], p[b], p[v]), "\(name): vertex \(v) lies on edge \(a)–\(b)")
                }
            }
            for i in 0 ..< segments.count {
                for j in i + 1 ..< segments.count {
                    let (a, b) = segments[i], (c, d) = segments[j]
                    guard Set([a, b, c, d]).count == 4 else { continue }
                    let o1 = orientation(p[a], p[b], p[c]), o2 = orientation(p[a], p[b], p[d])
                    let o3 = orientation(p[c], p[d], p[a]), o4 = orientation(p[c], p[d], p[b])
                    #expect(!(o1 * o2 < 0 && o3 * o4 < 0), "\(name): \(a)–\(b) crosses \(c)–\(d)")
                }
            }
        }
    }

    @Test("the largest face is the outer face: its vertices bound the drawing")
    func outerFace() throws {
        // The hexagon 0 … 5 with the chord 0–2: faces of length 3, 5 and 6; the hexagon is outer,
        // so no vertex lies strictly inside the convex hull.
        let pairs = (0 ..< 6).map { ($0, ($0 + 1) % 6) } + [(0, 2)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let p = try #require(graph.planarLayout()).positions
        func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Double {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }
        // Andrew's monotone chain, collinear points dropped: the hull counterclockwise.
        let sorted = p.sorted { ($0.x, $0.y) < ($1.x, $1.y) }
        var hull: [SIMD2<Double>] = []
        for q in sorted + sorted.reversed().dropFirst() {
            while hull.count >= 2 && orientation(hull[hull.count - 2], hull[hull.count - 1], q) <= 0 { hull.removeLast() }
            hull.append(q)
        }
        hull.removeLast()
        for (v, q) in p.enumerated() {
            let inside = hull.indices.allSatisfy { orientation(hull[$0], hull[($0 + 1) % hull.count], q) > 0 }
            #expect(!inside, "vertex \(v) at \(q) is inside the hull \(hull)")
        }
    }

    @Test("String vertices and a directed graph's undirected view give the drawing of the same rows")
    func representations() throws {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (4, 0)]
        let reference = try #require(UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) }).planarLayout())
        let names = ["a", "b", "c", "d", "e"]
        let named = UndirectedAdjacencyList<String>(vertices: names, edges: pairs.map { UndirectedEdge(names[$0.0], names[$0.1]) })
        let byName = try #require(named.planarLayout())
        #expect(Array(byName.vertices) == names)
        #expect(byName.positions == reference.positions)
        let digraph = AdjacencyList<Int>(vertices: 0 ..< 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let viaView = try #require(digraph.undirectedView.planarLayout())
        #expect(viaView.count == 5)
        for q in viaView.positions { #expect(q.x >= 0 && q.x <= 6 && q.y >= 0 && q.y <= 3) }
    }
}
