// shellLayout, spiralLayout, bipartiteLayout and randomLayout: hand-computed positions (within
// 1e-12, as cos and sin differ in the last bits across libm builds), the edge cases (no vertex,
// one vertex, a single-vertex first shell, empty shells), every representation that lists its
// vertices in index order, and graphs without vertex indices.

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif
import AdjacencyListModule
import AdjacencyMatrixModule
import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("shellLayout, spiralLayout, bipartiteLayout, randomLayout")
struct ShellSpiralBipartiteRandomLayoutTests {
    @Test("shellLayout: one shell by default, starting at angle π")
    func shellDefault() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1)])
        let layout = graph.shellLayout()
        #expect(Array(layout.vertices) == [0, 1, 2, 3])
        let expected = [SIMD2(-1.0, 0.0), SIMD2(0.0, -1.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0)]
        for (a, b) in zip(layout.positions, expected) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12, "\(a) vs \(b)") }
    }

    @Test("shellLayout: a first shell of one vertex sits at the centre; the next at radius 1/2, rotated by π/2 more")
    func shellCentre() {
        // The path 0–1–2–3 with shells [[0], [1, 2, 3]]: bump 1/2, rotation π/2, the outer shell
        // starting at π.
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let layout = graph.shellLayout(shells: [[0], [1, 2, 3]])
        let s = 3.0.squareRoot() / 4
        let expected = [SIMD2(0.0, 0.0), SIMD2(-0.5, 0.0), SIMD2(0.25, -s), SIMD2(0.25, s)]
        for (a, b) in zip(layout.positions, expected) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12, "\(a) vs \(b)") }
    }

    @Test("shellLayout: radius, centre, rotation, and an empty shell still takes its radius")
    func shellParameters() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: [])
        // Shells [[2, 0], [], [1]] with radius 3: radii 1, (2), 3; rotation 0.
        let layout = graph.shellLayout(shells: [[2, 0], [], [1]], rotation: 0, radius: 3, center: SIMD2(10, -1))
        let expected = [SIMD2(9.0, -1.0), SIMD2(13.0, -1.0), SIMD2(11.0, -1.0)]
        for (a, b) in zip(layout.positions, expected) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12, "\(a) vs \(b)") }
        // Vertex 0 is second in the inner shell: angle π.
        #expect(abs(layout.position(of: 0).x - 9) <= 1e-12)
    }

    @Test("shellLayout: one explicit shell lies on the full radius, as the default")
    func shellOne() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.shellLayout(shells: [[0, 1, 2, 3]], radius: 2) == graph.shellLayout(radius: 2))
        for p in graph.shellLayout(shells: [[3, 1, 0, 2]], radius: 2).positions { #expect(abs((p * p).sum().squareRoot() - 2) <= 1e-12) }
    }

    @Test("shellLayout: no vertex, and one vertex at the centre")
    func shellSmall() {
        #expect(Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).shellLayout().isEmpty)
        let one = Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        #expect(one.shellLayout(center: SIMD2(2, 3)).positions == [SIMD2(2, 3)])
        #expect(one.shellLayout(shells: [[], [0]], center: SIMD2(2, 3)).positions == [SIMD2(2, 3)])
    }

    @Test("shellLayout on graphs without vertex indices and on every representation")
    func shellRepresentations() {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let shells = [[3], [0, 1, 2]]
        let reference = Pseudograph<Int>(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) }).shellLayout(shells: shells)
        let list = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(list.shellLayout(shells: shells) == reference)
        let digraph = AdjacencyList<Int>(vertices: 0 ..< 4, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(digraph.undirectedView.shellLayout(shells: shells) == reference)
        var matrix = AdjacencyMatrix(vertexCount: 4)
        for (u, v) in pairs { _ = matrix.insert(edge: DirectedEdge(from: u, to: v)) }
        #expect(matrix.undirectedView.shellLayout(shells: shells) == reference)
        // String vertices (no vertex indices): the same positions in the same order.
        let named = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b")])
        let byName = named.shellLayout(shells: [["d"], ["a", "b", "c"]])
        #expect(Array(byName.vertices) == ["a", "b", "c", "d"])
        #expect(byName.positions == reference.positions)
        #expect(byName.position(of: "d") == SIMD2(0, 0))
    }

    @Test("spiralLayout: vertex i at i (cos ri, sin ri)")
    func spiral() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(2, 2)])
        let layout = graph.spiralLayout()
        for (i, p) in layout.positions.enumerated() {
            let r = Double(i), angle = 0.35 * Double(i)
            #expect(abs(p.x - r * cos(angle)) <= 1e-12 && abs(p.y - r * sin(angle)) <= 1e-12)
        }
        // Rescaled, the four-vertex spiral (NetworkX spiral_layout(path_graph(4)) prints these).
        let rescaled = layout.rescaled()
        let expected = [SIMD2(-0.64153279, -0.68555087), SIMD2(-0.03307913, -0.46344795), SIMD2(0.34927952, 0.14899882), SIMD2(0.32533239, 1.0)]
        for (a, b) in zip(rescaled.positions, expected) { #expect(abs(a.x - b.x) <= 1e-8 && abs(a.y - b.y) <= 1e-8, "\(a) vs \(b)") }
    }

    @Test("spiralLayout(equidistant:): consecutive vertices an arc of about 1 apart along ρ = θ/2")
    func spiralEquidistant() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 30, edges: [])
        let layout = graph.spiralLayout(resolution: 0.35, equidistant: true)
        // θ₀ = r + 2/r; each vertex at ρ = θ/2 of the θ before its step, at the θ after.
        var theta = 0.35 + 2 / 0.35
        for p in layout.positions {
            let rho = theta / 2
            theta += 1 / rho
            #expect(abs(p.x - rho * cos(theta)) <= 1e-12 && abs(p.y - rho * sin(theta)) <= 1e-12)
        }
        for i in 10 ..< 29 {
            let d = layout.positions[i + 1] - layout.positions[i]
            #expect(abs((d * d).sum().squareRoot() - 1) < 0.02)
        }
    }

    @Test("spiralLayout: no vertex, one vertex at the origin")
    func spiralSmall() {
        #expect(Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).spiralLayout().isEmpty)
        #expect(Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>]).spiralLayout(equidistant: true).positions == [.zero])
    }

    @Test("bipartiteLayout: K3,3, the left column in the order given, the right in vertices order")
    func bipartite() {
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< 3 { for v in 3 ..< 6 { edges.append(UndirectedEdge(u, v)) } }
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: edges)
        let layout = graph.bipartiteLayout(left: [5, 3, 4])
        let w = 2.0 / 3.0
        #expect(layout.position(of: 5) == SIMD2(-w, -0.5))
        #expect(layout.position(of: 3) == SIMD2(-w, 0))
        #expect(layout.position(of: 4) == SIMD2(-w, 0.5))
        #expect(layout.position(of: 0) == SIMD2(w, -0.5))
        #expect(layout.position(of: 1) == SIMD2(w, 0))
        #expect(layout.position(of: 2) == SIMD2(w, 0.5))
        // Rescaled with the left column ascending: x = ±1, y = ±0.75 (NetworkX's example).
        let rescaled = graph.bipartiteLayout(left: [3, 4, 5]).rescaled()
        #expect(rescaled.positions == [SIMD2(1, -0.75), SIMD2(1, 0), SIMD2(1, 0.75), SIMD2(-1, -0.75), SIMD2(-1, 0), SIMD2(-1, 0.75)])
    }

    @Test("bipartiteLayout: a column of one vertex at y = −½, an empty column, the aspect ratio, a column of 50 ending at ½ exactly")
    func bipartiteEdges() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        #expect(graph.bipartiteLayout(left: [1], aspectRatio: 2).positions == [SIMD2(1, -0.5), SIMD2(-1, -0.5), SIMD2(1, 0.5)])
        #expect(graph.bipartiteLayout(left: [] as [Int], aspectRatio: 2).positions == [SIMD2(1, -0.5), SIMD2(1, 0), SIMD2(1, 0.5)])
        #expect(graph.bipartiteLayout(left: [0, 1, 2], aspectRatio: 2).positions == [SIMD2(-1, -0.5), SIMD2(-1, 0), SIMD2(-1, 0.5)])
        // 49 · (1/49) rounds below 1; the last of a column is ½ exactly.
        let fifty = UndirectedAdjacencyList<Int>(vertices: 0 ..< 50, edges: [])
        let ys = fifty.bipartiteLayout(left: 0 ..< 50).positions.map(\.y)
        #expect(ys.first == -0.5 && ys.last == 0.5)
        for j in 0 ..< 49 { #expect(ys[j] == Double(j) * (1 / 49.0) - 0.5) }
        #expect(Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).bipartiteLayout(left: [] as [Int]).isEmpty)
    }

    @Test("bipartiteLayout on String vertices")
    func bipartiteNamed() {
        let graph = UndirectedAdjacencyList<String>(vertices: ["x", "y", "z"], edges: [UndirectedEdge("x", "y")])
        let layout = graph.bipartiteLayout(left: ["z"])
        #expect(Array(layout.vertices) == ["x", "y", "z"])
        #expect(layout.positions == [SIMD2(2.0 / 3.0, -0.5), SIMD2(2.0 / 3.0, 0.5), SIMD2(-2.0 / 3.0, -0.5)])
    }

    @Test("randomLayout: x then y per vertex, the top 53 bits of each draw, 2n draws")
    func random() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1)])
        var generator = Xoshiro256StarStar(seed: 7)
        let layout = graph.randomLayout(using: &generator)
        var replay = Xoshiro256StarStar(seed: 7)
        for p in layout.positions {
            let x = Double(replay.next() >> 11) * 0x1p-53, y = Double(replay.next() >> 11) * 0x1p-53
            #expect(p == SIMD2(x, y))
            #expect(p.x >= 0 && p.x < 1 && p.y >= 0 && p.y < 1)
        }
        #expect(generator.next() == replay.next())
        #expect(graph.randomLayout().count == 5)
        #expect(Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).randomLayout().isEmpty)
    }

    @Test("randomLayout on a stable graph and on String vertices keeps vertices order")
    func randomRepresentations() {
        var stable = StableUndirectedGraph<Int>()
        for v in 0 ..< 4 { _ = stable.insert(v) }
        var generator = Xoshiro256StarStar(seed: 3)
        let a = stable.randomLayout(using: &generator)
        #expect(Array(a.vertices) == Array(stable.vertices))
        let named = UndirectedAdjacencyList<String>(vertices: ["p", "q"], edges: [])
        var g2 = Xoshiro256StarStar(seed: 3)
        let b = named.randomLayout(using: &g2)
        #expect(b.positions == Array(a.positions.prefix(2)))
    }
}

@Suite("multipartiteLayout, bfsLayout")
struct MultipartiteLayoutTests {
    @Test("multipartite: layers sorted, gaps and negative numbers make no empty column, vertices order within a column")
    func layers() {
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d", "e", "f"], edges: [])
        let layer = ["a": 7, "b": -3, "c": 7, "d": 100, "e": 7, "f": -3]
        let layout = graph.multipartiteLayout(layer: { layer[$0]! })
        #expect(Array(layout.vertices) == ["a", "b", "c", "d", "e", "f"])
        #expect(layout.positions == [SIMD2(0, -1), SIMD2(-1, -0.5), SIMD2(0, 0), SIMD2(1, 0), SIMD2(0, 1), SIMD2(-1, 0.5)])
        #expect(Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).multipartiteLayout(layer: { $0 }).isEmpty)
        #expect(Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>]).multipartiteLayout(layer: { $0 }).positions == [.zero])
    }

    @Test("bfs layout: discovery order within a column, loops and parallel edges, a directed graph's view")
    func bfsOrder() {
        // 0's neighbours in edge order are 3, then 2: 3 is discovered first.
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 3), UndirectedEdge(0, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 2), UndirectedEdge(1, 2)])
        let layout = graph.bfsLayout(start: 0)
        #expect(layout.positions == [SIMD2(-1, 0), SIMD2(1, 0), SIMD2(0, 0.5), SIMD2(0, -0.5)])
        let digraph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 1, to: 2)])
        #expect(digraph.undirectedView.bfsLayout(start: 0).positions == [SIMD2(-1, 0), SIMD2(1, 0), SIMD2(0, 0)])
        #expect(Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>]).bfsLayout(start: 0).positions == [.zero])
    }
}
