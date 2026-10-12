// Tests written against the planted bugs of scripts/mutants/GraphDrawing.py that the rest of the
// suite let through. They pin `Drawing`'s setters, lookup, equality and description; the start
// temperature of Fruchterman–Reingold and its default optimal distance; Barnes–Hut cells (the
// centre of mass, the cell containing the vertex, the leaf distance floor, θ = 0 being exact); two
// coincident vertices separating; the stopping rules of both steppers; self-loops being ignored;
// graphs without vertex indices; stress majorization's target distances along weighted shortest
// paths; caller layers' reversed bends; and one whole layered drawing with long edges, which
// fixes crossing reduction and every step of Brandes and Köpf's coordinates. See README.md.

import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing

@Suite("GraphDrawing planted bugs")
struct GraphDrawingPlantedBugTests {
    // MARK: Drawing

    @Test("Drawing.positions: setting or growing it to another count traps")
    func positionsCountTraps() async {
        await #expect(processExitsWith: .failure) {
            var drawing = Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)])
            drawing.positions = [SIMD2(0.0, 0.0)]
        }
        await #expect(processExitsWith: .failure) {
            var drawing = Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)])
            drawing.positions.append(SIMD2(2.0, 2.0))
        }
        // Without the calls: the same count is accepted, both ways.
        var drawing = Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)])
        drawing.positions = [SIMD2(5.0, 5.0), SIMD2(6.0, 6.0)]
        drawing.positions[0].x = 7
        #expect(drawing.positions == [SIMD2(7.0, 5.0), SIMD2(6.0, 6.0)])
    }

    @Test("Drawing of 0..<n: position(checked:) of n and of −1 throws")
    func denseLookupBounds() throws {
        let drawing = Drawing(vertices: 0 ..< 3, positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(2.0, 0.0)])
        #expect(throws: VertexNotFound.self) { try drawing.position(checked: 3) }
        #expect(throws: VertexNotFound.self) { try drawing.position(checked: -1) }
        #expect(try drawing.position(checked: 2) == SIMD2(2.0, 0.0))
    }

    @Test("Drawing equality compares the vertices too, and the description lists x before y")
    func equalityAndDescription() {
        let p = SIMD2(1.0, 2.0)
        #expect(Drawing(vertices: [0, 1], positions: [p, p]) != Drawing(vertices: [1, 0], positions: [p, p]))
        #expect(Drawing(vertices: [0, 1], positions: [p, p]) == Drawing(vertices: [0, 1], positions: [p, p]))
        #expect(Drawing(vertices: [7], positions: [SIMD2(1.5, -2.0)]).description == "Drawing([7: (1.5, -2.0)])")
    }

    // MARK: Fruchterman–Reingold

    @Test("Fruchterman–Reingold's start temperature is a tenth of the larger side, k/10 from one point")
    func startTemperature() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let tall = Drawing(vertices: 0 ..< 4, positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 4.0), SIMD2(1.0, 1.0)])
        #expect(FruchtermanReingoldLayout(graph, initial: tall).temperature == 0.1 * 4)
        let wide = Drawing(vertices: 0 ..< 4, positions: [SIMD2(0.0, 0.0), SIMD2(3.0, 0.0), SIMD2(0.0, 2.0), SIMD2(1.0, 1.0)])
        #expect(FruchtermanReingoldLayout(graph, initial: wide).temperature == 0.1 * 3)
        // Every vertex at one point: k/10 with the default k = √(1/n) = 1/2.
        let point = Drawing(vertices: 0 ..< 4, positions: Array(repeating: SIMD2(2.0, 2.0), count: 4))
        #expect(FruchtermanReingoldLayout(graph, initial: point).temperature == 0.1 * 0.5)
        #expect(FruchtermanReingoldLayout(graph, initial: point, optimalDistance: 3).temperature == 0.1 * 3)
    }

    @Test("Fruchterman–Reingold: two coincident vertices separate symmetrically", arguments: [nil, 1.2] as [Double?])
    func twoCoincidentVertices(theta: Double?) {
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [] as [UndirectedEdge<Int>])
        let start = Drawing(vertices: 0 ..< 2, positions: [SIMD2(0.0, 0.0), SIMD2(0.0, 0.0)])
        let p = graph.fruchtermanReingoldLayout(initial: start, iterations: 1, barnesHutTheta: theta).positions
        let d = p[0] - p[1]
        #expect((d * d).sum() > 1e-6, "\(p)")
        // Opposite moves from the common point.
        #expect(p[0] == -p[1], "\(p)")
    }

    @Test("Barnes–Hut where every cell is opened equals exact repulsion")
    func barnesHutOpenedCells() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        // The root holds the three points, one per quadrant; with θ = 2 the root alone would pass
        // s/D < θ from the corner (1, 1) or from the origin, but it contains them, so it is opened.
        let start = Drawing(vertices: 0 ..< 3, positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(1.0, 1.0)])
        let exact = graph.fruchtermanReingoldLayout(initial: start, iterations: 1)
        #expect(graph.fruchtermanReingoldLayout(initial: start, iterations: 1, barnesHutTheta: 2) == exact)
        // Two vertices 0.05 apart in two leaves: the leaf uses the exact force's distance floor.
        // With k = 0.01 the moves stay under the temperature, so the force's size shows.
        let pair = Pseudograph<Int>(vertices: 0 ..< 2, edges: [] as [UndirectedEdge<Int>])
        let close = Drawing(vertices: 0 ..< 2, positions: [SIMD2(0.0, 0.0), SIMD2(0.05, 0.0)])
        let exactPair = pair.fruchtermanReingoldLayout(initial: close, iterations: 1, optimalDistance: 0.01)
        #expect(pair.fruchtermanReingoldLayout(initial: close, iterations: 1, optimalDistance: 0.01, barnesHutTheta: 1) == exactPair)
        // Displacement k²/d along the pair: 10⁻⁴ / 0.05.
        #expect(abs(exactPair.positions[1].x - 0.05 - 1e-4 / 0.05) <= 1e-15)
    }

    @Test("Barnes–Hut: a far cell of two bodies acts as one body at their centre of mass")
    func barnesHutFarCell() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        let start = Drawing(vertices: 0 ..< 3, positions: [SIMD2(0.0, 0.0), SIMD2(10.0, 0.0), SIMD2(10.0, 4.0)])
        let p = graph.fruchtermanReingoldLayout(initial: start, iterations: 1, optimalDistance: 1, barnesHutTheta: 1).positions
        // Vertices 1 and 2 share the root's quadrant of side 5 at distance √104 from vertex 0, so
        // vertex 0 feels mass 2 at (10, 2): displacement 2 k² / D² · (0 − (10, 2)), under the
        // temperature 10/10.
        let delta = SIMD2(0.0, 0.0) - SIMD2(10.0, 2.0)
        #expect(p[0] == delta * (2 * 1 / 104), "\(p)")
        // Exact repulsion differs.
        let exact = graph.fruchtermanReingoldLayout(initial: start, iterations: 1, optimalDistance: 1).positions
        #expect(((exact[0] - p[0]) * (exact[0] - p[0])).sum() > 1e-6)
    }

    @Test("Barnes–Hut with θ = 0 is exactly the exact repulsion")
    func barnesHutThetaZero() {
        var rng = Xoshiro256StarStar(seed: 7)
        var pairs: [UndirectedEdge<Int>] = []
        for _ in 0 ..< 60 { pairs.append(UndirectedEdge(Int(rng.next() % 30), Int(rng.next() % 30))) }
        let graph = Pseudograph<Int>(vertices: 0 ..< 30, edges: pairs)
        var g1 = Xoshiro256StarStar(seed: 3), g2 = g1
        #expect(graph.fruchtermanReingoldLayout(barnesHutTheta: 0, using: &g1) == graph.fruchtermanReingoldLayout(using: &g2))
    }

    @Test("Steppers on one vertex are finished before any step")
    func singleVertex() {
        let graph = Pseudograph<Int>(vertices: [9], edges: [] as [UndirectedEdge<Int>])
        var generator = Xoshiro256StarStar(seed: 1)
        var fr = FruchtermanReingoldLayout(graph, using: &generator)
        #expect(fr.isFinished && fr.iteration == 0)
        fr.run()
        #expect(fr.iteration == 0)
        var stress = StressMajorizationLayout(graph)
        #expect(stress.isFinished && stress.iteration == 0)
        stress.run()
        #expect(stress.iteration == 0 && stress.drawing.positions == [SIMD2(0.0, 0.0)])
    }

    @Test("Fruchterman–Reingold stops once a step moves less than the threshold, not at it")
    func frThreshold() {
        let path = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var generator = Xoshiro256StarStar(seed: 5)
        var loose = FruchtermanReingoldLayout(path, threshold: 1e9, using: &generator)
        loose.run()
        #expect(loose.iteration == 1)
        // An edge of length k exactly: repulsion and attraction cancel, so nothing moves, and a
        // move of 0 is not below threshold 0.
        let edge = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let start = Drawing(vertices: 0 ..< 2, positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)])
        var balanced = FruchtermanReingoldLayout(edge, initial: start, iterations: 5, optimalDistance: 1, threshold: 0)
        balanced.run()
        #expect(balanced.iteration == 5 && balanced.drawing == start)
    }

    @Test("Fruchterman–Reingold traps on a negative weight, a zero optimal distance or a negative threshold")
    func frParameterTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = Xoshiro256StarStar(seed: 1)
            _ = graph.fruchtermanReingoldLayout(weight: { _ in -1 }, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = Xoshiro256StarStar(seed: 1)
            _ = graph.fruchtermanReingoldLayout(optimalDistance: 0, using: &generator)
        }
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            var generator = Xoshiro256StarStar(seed: 1)
            _ = graph.fruchtermanReingoldLayout(threshold: -1, using: &generator)
        }
        // Without the calls: weight 0, a small optimal distance and threshold 0 are accepted.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        var generator = Xoshiro256StarStar(seed: 1)
        #expect(graph.fruchtermanReingoldLayout(optimalDistance: 1e-3, threshold: 0, weight: { _ in 0 }, using: &generator).count == 3)
    }

    @Test("stressMajorizationLayout and sugiyamaLayout trap on maxIterations −1")
    func iterationTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
            _ = graph.stressMajorizationLayout(maxIterations: -1)
        }
        await #expect(processExitsWith: .failure) {
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
            _ = graph.sugiyamaLayout(maxIterations: -1)
        }
        // Without the calls: 0 is accepted.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(graph.stressMajorizationLayout(maxIterations: 0) == graph.circularLayout())
        let directed = DirectedPseudograph<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1)])
        #expect(directed.sugiyamaLayout(maxIterations: 0).layerCount == 2)
    }

    // MARK: Self-loops and graphs without vertex indices

    @Test("Self-loops are ignored, their weights and lengths unread, with and without vertex indices")
    func selfLoopsIgnored() {
        let pairs = [(0, 1), (1, 3), (3, 4), (4, 0), (1, 4)]
        let plain = Pseudograph<Int>(vertices: [0, 1, 3, 4], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let looped = Pseudograph<Int>(vertices: [0, 1, 3, 4], edges: (pairs + [(3, 3), (0, 0)]).map { UndirectedEdge($0.0, $0.1) })
        // A stable graph with a removed vertex has no vertex indices.
        var stable = StableDirectedGraph<Int>(vertices: 0 ..< 5, edges: (pairs + [(3, 3), (0, 0), (2, 1)]).map { DirectedEdge(from: $0.0, to: $0.1) })
        _ = stable.remove(2)
        let view = stable.undirected
        #expect(view.vertexIndexBound == nil && Array(view.vertices) == [0, 1, 3, 4])

        let length: (UndirectedEdge<Int>) -> Double = { $0.u == $0.v ? 1000 : Double(($0.u + $0.v) % 3) + 0.5 }
        let expected = plain.stressMajorizationLayout(edgeLength: { length(plain.edges[$0]) })
        for drawing in [looped.stressMajorizationLayout(edgeLength: { length(looped.edges[$0]) }), view.stressMajorizationLayout(edgeLength: { length(view.edges[$0]) })] {
            #expect(drawing.vertices == expected.vertices)
            for (a, b) in zip(drawing.positions, expected.positions) {
                #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(drawing) vs \(expected)")
            }
        }

        let weight: (UndirectedEdge<Int>) -> Double = { $0.u == $0.v ? .nan : Double(($0.u * $0.v) % 3) }
        var g1 = Xoshiro256StarStar(seed: 11), g2 = g1, g3 = g1
        let force = plain.fruchtermanReingoldLayout(weight: { weight(plain.edges[$0]) }, using: &g1)
        #expect(looped.fruchtermanReingoldLayout(weight: { weight(looped.edges[$0]) }, using: &g2) == force)
        let viewed = view.fruchtermanReingoldLayout(weight: { weight(view.edges[$0]) }, using: &g3)
        #expect(viewed.vertices == force.vertices)
        for (a, b) in zip(viewed.positions, force.positions) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(viewed) vs \(force)")
        }
    }

    // MARK: Stress majorization

    @Test("Stress majorization's targets are weighted shortest-path distances (Floyd–Warshall)")
    func weightedTargets() {
        // Dense enough that Dijkstra's heap holds many entries at once.
        let n = 40
        var edges: [(Int, Int, Double)] = []
        for i in 0 ..< n {
            for j in i + 1 ..< n where (i * 7 + j * 3) % 5 == 0 { edges.append((i, j, Double((i * 37 + j * 91) % 23) * 0.25 + 0.1)) }
        }
        let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let start = Drawing(vertices: 0 ..< n, positions: (0 ..< n).map { SIMD2(Double($0), Double($0 * $0 % 5)) })
        let layout = StressMajorizationLayout(graph, initial: start, edgeLength: { edges[$0].2 }, maxIterations: 0)
        // Floyd–Warshall, then components apart by 1 + L̄√n.
        var d = [[Double]](repeating: [Double](repeating: .infinity, count: n), count: n)
        for i in 0 ..< n { d[i][i] = 0 }
        for (u, v, w) in edges {
            d[u][v] = min(d[u][v], w)
            d[v][u] = min(d[v][u], w)
        }
        for k in 0 ..< n {
            for i in 0 ..< n {
                for j in 0 ..< n where d[i][k] + d[k][j] < d[i][j] { d[i][j] = d[i][k] + d[k][j] }
            }
        }
        let mean = edges.map(\.2).reduce(0, +) / Double(edges.count)
        var stress = 0.0
        for i in 0 ..< n {
            for j in i + 1 ..< n {
                let target = d[i][j].isFinite ? d[i][j] : 1 + mean * Double(n).squareRoot()
                let delta = start.positions[i] - start.positions[j]
                let r = (delta * delta).sum().squareRoot() / target - 1
                stress += r * r
            }
        }
        #expect(abs(layout.stress - stress) <= 1e-5 * stress, "\(layout.stress) vs \(stress)")
    }

    @Test("Stress majorization stops one step after a step that lowered the stress by at most tolerance × stress")
    func stressStopsAtZeroDecrease() {
        // Already at zero stress: each step lowers it by 0, which is at most 0 × 0.
        let edge = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let start = Drawing(vertices: 0 ..< 2, positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)])
        var layout = StressMajorizationLayout(edge, initial: start, tolerance: 0, maxIterations: 10)
        layout.run()
        #expect(layout.iteration == 2 && layout.drawing == start && layout.stress == 0)
    }

    // MARK: Sugiyama

    @Test("Caller layers: a reversed edge's bends run from its source up to its target")
    func callerLayersReversedBends() {
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 4, edges: [DirectedEdge(from: 3, to: 0), DirectedEdge(from: 1, to: 2)])
        let layered = graph.sugiyamaLayout(layers: { $0 })
        #expect(layered.reversedEdges == [0])
        #expect(layered.bends(ofEdgeAt: 0).map(\.y) == [2, 1])
        #expect(layered.bends(ofEdgeAt: 1).isEmpty)
    }

    @Test("A whole layered drawing with long edges: crossing reduction and Brandes–Köpf, pinned")
    func pinnedLayeredDrawing() {
        // Found by comparing the planted bugs' drawings with the unmutated one on random digraphs;
        // this one tells apart a change to the crossing reduction's stopping and best-order rules,
        // to the type-1 conflict marking, and to the alignment, the shifts and the averaging of
        // Brandes and Köpf's four drawings. The layering is passed in, since ties in the optimal
        // one are not specified (it is the optimal one network simplex finds).
        let arcs = [
            (1, 7), (3, 7), (5, 7), (1, 3), (2, 7), (1, 2), (4, 5), (1, 3), (0, 2), (3, 6), (2, 3), (0, 1), (0, 3), (2, 4), (0, 4), (2, 6), (2, 7),
            (1, 4), (5, 7), (4, 5),
        ]
        let graph = DirectedPseudograph<Int>(vertices: 0 ..< 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let layers = [0, 1, 2, 3, 3, 4, 4, 5]
        let layered = graph.sugiyamaLayout(layers: { layers[$0] }, maxIterations: 5)
        #expect(
            layered.drawing.positions == [
                SIMD2(4.0, 0.0), SIMD2(3.5, 1.0), SIMD2(6.5, 2.0), SIMD2(4.0, 3.0), SIMD2(2.0, 3.0), SIMD2(3.5, 4.0), SIMD2(8.0, 4.0), SIMD2(3.5, 5.0),
            ])
        #expect(layered.crossingCount == 10 && layered.reversedEdges.isEmpty)
        let bends: [[SIMD2<Double>]] = [
            [SIMD2(0.0, 2.0), SIMD2(0.0, 3.0), SIMD2(0.0, 4.0)], [SIMD2(2.5, 4.0)], [], [SIMD2(3.0, 2.0)], [SIMD2(6.0, 3.0), SIMD2(6.0, 4.0)], [], [],
            [SIMD2(4.0, 2.0)], [SIMD2(6.5, 1.0)], [], [], [], [SIMD2(5.0, 1.0), SIMD2(5.0, 2.0)], [], [SIMD2(2.0, 1.0), SIMD2(2.0, 2.0)],
            [SIMD2(8.0, 3.0)], [SIMD2(7.0, 3.0), SIMD2(7.0, 4.0)], [SIMD2(1.0, 2.0)], [], [],
        ]
        for e in graph.edges.indices { #expect(Array(layered.bends(ofEdgeAt: e)) == bends[e], "edge \(e)") }
        // The optimal layering is these layers' total span.
        let optimal = graph.sugiyamaLayout(maxIterations: 5)
        let span = arcs.map { optimal.layer(of: $0.1) - optimal.layer(of: $0.0) }.reduce(0, +)
        #expect(span == arcs.map { layers[$0.1] - layers[$0.0] }.reduce(0, +))
    }
}
