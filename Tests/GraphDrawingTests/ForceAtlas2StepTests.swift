// forceAtlas2Layout and ForceAtlas2Layout: the first steps computed by hand from the forces
// (repulsion k_r m_u m_v / d, attraction w d or w log(1 + d), gravity g m or g m d, hubs dissuaded
// by the source's mass) and the adaptive speed; determinism, the draws, stepping and Barnes–Hut.
// The quality bounds are catalog rows (ForceAtlas2LayoutTests.swift).

import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif

@Suite("forceAtlas2Layout: forces, speed and stepping")
struct ForceAtlas2StepTests {
    @Test("one step of the edge 0–1 from (0, 0) and (1, 0), by hand")
    func firstStep() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let start = Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)])
        let layout = graph.forceAtlas2Layout(initial: start, iterations: 1)
        // Masses 2 and 2. Repulsion 2 · 2 · 2 / 1 = 8 apart; gravity 1 · 2 on vertex 1 only (vertex 0
        // is at the origin); attraction 1 · 1 together. F₀ = (−7, 0), F₁ = (5, 0).
        let f0 = -7.0, f1 = 5.0
        let swing = 2 * 7.0 + 2 * 5.0, traction = 0.5 * 2 * 7.0 + 0.5 * 2 * 5.0
        let optimal = 0.05 * 2.0.squareRoot()
        let jitter = max(optimal.squareRoot(), min(10, optimal * traction / 4))
        // swing / traction = 2 is not above 2; the swing exceeds jitter · traction, so the
        // efficiency falls to 0.7, but the target uses the efficiency before that.
        let target = jitter * 1 * traction / swing
        let speed = 1 + min(target - 1, 0.5)
        let x0 = 0 + f0 * (speed / (1 + (speed * 2 * 7).squareRoot()))
        let x1 = 1 + f1 * (speed / (1 + (speed * 2 * 5).squareRoot()))
        #expect(abs(layout.positions[0].x - x0) <= 1e-12 && layout.positions[0].y == 0)
        #expect(abs(layout.positions[1].x - x1) <= 1e-12 && layout.positions[1].y == 0)
        var stepper = ForceAtlas2Layout(graph, initial: start, iterations: 1)
        #expect(stepper.speed == 1)
        stepper.step()
        #expect(abs(stepper.speed - speed) <= 1e-15)
        #expect(stepper.drawing == layout)
    }

    @Test("one step with strong gravity, lin-log attraction, dissuaded hubs and a weight, by hand")
    func firstStepModes() {
        // The path 0–1–2 from (1, 0), (0, 2), (−1, −1): masses 2, 3, 2; weight 3 on edge 0–1.
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        let p = [SIMD2(1.0, 0.0), SIMD2(0.0, 2.0), SIMD2(-1.0, -1.0)]
        let start = Drawing(vertices: [0, 1, 2], positions: p)
        let w = [3.0, 1.0, 100.0]
        let m = [2.0, 3.0, 2.0]
        for strong in [false, true] {
            for linLog in [false, true] {
                for hubs in [false, true] {
                    var f = [SIMD2<Double>](repeating: .zero, count: 3)
                    for v in 0 ..< 3 {
                        for u in 0 ..< 3 where u != v {
                            let d = p[v] - p[u]
                            f[v] += d * (1.5 * m[v] * m[u] / (d * d).sum())
                        }
                        let r = (p[v] * p[v]).sum().squareRoot()
                        f[v] -= strong ? p[v] * (0.5 * m[v]) : p[v] * (0.5 * m[v] / r)
                    }
                    for (e, (a, b)) in [(0, 1), (1, 2)].enumerated() {
                        let d = p[a] - p[b]
                        var factor = w[e]
                        if linLog {
                            let length = (d * d).sum().squareRoot()
                            factor *= log(1 + length) / length
                        }
                        if hubs { factor *= (7.0 / 3.0) / m[a] }
                        f[a] -= d * factor
                        f[b] += d * factor
                    }
                    var swing = 0.0, traction = 0.0
                    for v in 0 ..< 3 {
                        swing += m[v] * (f[v] * f[v]).sum().squareRoot()
                        traction += 0.5 * m[v] * (f[v] * f[v]).sum().squareRoot()
                    }
                    let optimal = 0.05 * 3.0.squareRoot()
                    var jitter = 0.5 * max(optimal.squareRoot(), min(10, optimal * traction / 9))
                    var efficiency = 1.0
                    if swing / traction > 2 {
                        efficiency *= 0.5
                        jitter = max(jitter, 0.5)
                    }
                    let target = jitter * efficiency * traction / swing
                    let speed = 1 + min(target - 1, 0.5)
                    let layout = graph.forceAtlas2Layout(
                        initial: start, iterations: 1, scalingRatio: 1.5, gravity: 0.5, strongGravity: strong, linLog: linLog, dissuadeHubs: hubs,
                        jitterTolerance: 0.5, weight: { w[$0] })
                    for v in 0 ..< 3 {
                        let swingV = m[v] * (f[v] * f[v]).sum().squareRoot()
                        let expected = p[v] + f[v] * (speed / (1 + (speed * swingV).squareRoot()))
                        let got = layout.positions[v]
                        #expect(abs(got.x - expected.x) <= 1e-12 && abs(got.y - expected.y) <= 1e-12, "strong \(strong) linLog \(linLog) hubs \(hubs) v \(v): \(got) vs \(expected)")
                    }
                }
            }
        }
    }

    @Test("the second step's swing is the change of force")
    func secondStep() {
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let start = Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)])
        let one = graph.forceAtlas2Layout(initial: start, iterations: 1)
        let two = graph.forceAtlas2Layout(initial: start, iterations: 2)
        // Forces at the first step's drawing, both on the x axis.
        let p = one.positions.map(\.x)
        let old = [-7.0, 5.0]
        var f = [0.0, 0.0]
        let d = p[0] - p[1]
        f[0] = 2 * 2 * 2 / d
        f[1] = -f[0]
        for v in 0 ..< 2 where p[v] != 0 { f[v] -= 2 * (p[v] > 0 ? 1 : -1) }
        f[0] -= d
        f[1] += d
        let swing = 2 * abs(old[0] - f[0]) + 2 * abs(old[1] - f[1])
        let traction = 0.5 * 2 * abs(old[0] + f[0]) + 0.5 * 2 * abs(old[1] + f[1])
        // The first step's speed and efficiency.
        let optimal = 0.05 * 2.0.squareRoot()
        let jitter1 = max(optimal.squareRoot(), min(10, optimal * 12 / 4))
        let speed1 = 1 + min(jitter1 * 12 / 24 - 1, 0.5)
        var efficiency = 0.7
        var jitter = max(optimal.squareRoot(), min(10, optimal * traction / 4))
        if swing / traction > 2 {
            efficiency *= 0.5
            jitter = max(jitter, 1)
        }
        let target = jitter * efficiency * traction / swing
        let speed = speed1 + min(target - speed1, 0.5 * speed1)
        for v in 0 ..< 2 {
            let expected = p[v] + f[v] * (speed / (1 + (speed * 2 * abs(old[v] - f[v])).squareRoot()))
            #expect(abs(two.positions[v].x - expected) <= 1e-12, "\(two.positions[v].x) vs \(expected)")
        }
    }

    @Test("the start: 2n draws, x then y per vertex; iterations 0 returns it; the same seed, the same drawing")
    func determinism() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 8, edges: (0 ..< 7).map { UndirectedEdge($0, $0 + 1) })
        var a = Xoshiro256StarStar(seed: 11)
        let start = graph.forceAtlas2Layout(iterations: 0, using: &a)
        var b = Xoshiro256StarStar(seed: 11)
        #expect(start == graph.randomLayout(using: &b))
        #expect(a.next() == b.next())
        var c = Xoshiro256StarStar(seed: 11)
        let run = graph.forceAtlas2Layout(using: &c)
        var d = Xoshiro256StarStar(seed: 11)
        #expect(graph.forceAtlas2Layout(using: &d) == run)
        var e = Xoshiro256StarStar(seed: 11)
        #expect(graph.forceAtlas2Layout(initial: graph.randomLayout(using: &e)) == run)
        var f = Xoshiro256StarStar(seed: 11)
        var stepper = ForceAtlas2Layout(graph, using: &f)
        #expect(stepper.drawing == start && stepper.iteration == 0 && !stepper.isFinished)
        while !stepper.isFinished { stepper.step() }
        #expect(stepper.iteration == 100 && stepper.drawing == run)
        stepper.step()
        #expect(stepper.iteration == 100)
        for p in run.positions { #expect(p.x.isFinite && p.y.isFinite) }
        #expect(graph.forceAtlas2Layout(iterations: 3).count == 8)
        #expect(ForceAtlas2Layout(graph, iterations: 3).drawing.count == 8)
    }

    @Test("Barnes–Hut: θ = 0 is exact; θ = 1.2 stays close on a grid")
    func barnesHut() {
        var edges: [UndirectedEdge<Int>] = []
        for i in 0 ..< 6 {
            for j in 0 ..< 6 {
                if j + 1 < 6 { edges.append(UndirectedEdge(i * 6 + j, i * 6 + j + 1)) }
                if i + 1 < 6 { edges.append(UndirectedEdge(i * 6 + j, (i + 1) * 6 + j)) }
            }
        }
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 36, edges: edges)
        var a = Xoshiro256StarStar(seed: 5), b = Xoshiro256StarStar(seed: 5), c = Xoshiro256StarStar(seed: 5)
        let exact = graph.forceAtlas2Layout(using: &a)
        #expect(graph.forceAtlas2Layout(barnesHutTheta: 0, using: &b) == exact)
        let approximate = graph.forceAtlas2Layout(iterations: 1, barnesHutTheta: 1e-9, using: &c)
        var d = Xoshiro256StarStar(seed: 5)
        let exactOne = graph.forceAtlas2Layout(iterations: 1, using: &d)
        for (p, q) in zip(approximate.positions, exactOne.positions) { #expect(abs(p.x - q.x) <= 1e-9 && abs(p.y - q.y) <= 1e-9) }
        // Coincident vertices separate under Barnes–Hut as under exact repulsion.
        let same = Drawing(vertices: 0 ..< 36, positions: [SIMD2<Double>](repeating: SIMD2(0.5, 0.5), count: 36))
        let spread = graph.forceAtlas2Layout(initial: same, iterations: 5, barnesHutTheta: 1.2)
        #expect(Set(spread.positions.map { [$0.x, $0.y] }).count == 36)
        let spreadExact = graph.forceAtlas2Layout(initial: same, iterations: 5)
        #expect(Set(spreadExact.positions.map { [$0.x, $0.y] }).count == 36)
    }

    @Test("small graphs: no vertex, one vertex pulled to the origin, isolated vertices, String vertices")
    func small() {
        #expect(Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).forceAtlas2Layout().isEmpty)
        let one = Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        let pulled = one.forceAtlas2Layout(initial: Drawing(vertices: [0], positions: [SIMD2(3.0, 4.0)]), iterations: 1, strongGravity: true)
        // F = −1 · 1 · (3, 4); swing 5, traction 2.5; the speed rises to 1.5 at most.
        let f = SIMD2(-3.0, -4.0)
        let optimal = 0.05
        let jitter = max(optimal.squareRoot(), min(10, optimal * 2.5))
        let target = jitter * 2.5 / 5
        let speed = 1 + min(target - 1, 0.5)
        let expected = SIMD2(3.0, 4.0) + f * (speed / (1 + (speed * 5).squareRoot()))
        #expect(abs(pulled.positions[0].x - expected.x) <= 1e-12 && abs(pulled.positions[0].y - expected.y) <= 1e-12)
        let named = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c"], edges: [UndirectedEdge("a", "b")])
        var g = Xoshiro256StarStar(seed: 2)
        let byName = named.forceAtlas2Layout(using: &g)
        var h = Xoshiro256StarStar(seed: 2)
        let byIndex = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)]).forceAtlas2Layout(using: &h)
        #expect(Array(byName.vertices) == ["a", "b", "c"] && byName.positions == byIndex.positions)
        // A directed graph through its undirected view.
        let csr = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 1, to: 0)])
        var k = Xoshiro256StarStar(seed: 2)
        #expect(csr.undirectedView.forceAtlas2Layout(using: &k).positions == byIndex.positions)
    }

    @Test("Barnes–Hut: a far cluster of unequal masses acts at its centre of mass with its total mass")
    func barnesHutMasses() {
        // Masses 2, 2, 3, 2, 2: the cluster 1, 2, 4 near (100, 0) is one body for vertices 0 and 3.
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(1, 2), UndirectedEdge(2, 4), UndirectedEdge(0, 3)])
        let start = Drawing(vertices: 0 ..< 5, positions: [SIMD2(0.0, 0.0), SIMD2(100.0, 0.0), SIMD2(101.0, 0.0), SIMD2(0.0, 1.0), SIMD2(100.0, 1.0)])
        let exact = graph.forceAtlas2Layout(initial: start, iterations: 1)
        let approximate = graph.forceAtlas2Layout(initial: start, iterations: 1, barnesHutTheta: 1.2)
        for (p, q) in zip(approximate.positions, exact.positions) { #expect(abs(p.x - q.x) <= 1e-6 && abs(p.y - q.y) <= 1e-6, "\(p) vs \(q)") }
    }

    @Test("Barnes–Hut: the cell holding the vertex is opened, even when it is small against its distance")
    func barnesHutOwnCell() {
        // With θ = 2 the root (side 1, centre of mass √½ away) would pass s/D < θ for either vertex.
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let start = Drawing(vertices: 0 ..< 2, positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)])
        let exact = graph.forceAtlas2Layout(initial: start, iterations: 3)
        let approximate = graph.forceAtlas2Layout(initial: start, iterations: 3, barnesHutTheta: 2)
        for (p, q) in zip(approximate.positions, exact.positions) { #expect(abs(p.x - q.x) <= 1e-12 && abs(p.y - q.y) <= 1e-12, "\(p) vs \(q)") }
    }

    @Test("thirty steps equal a direct transcription of the method, every mode")
    func reference() {
        let pairs = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 4), (1, 3)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let w = [1.0, 2.0, 0.5, 1.0, 3.0, 7.0, 1.0]
        let start = [SIMD2(0.3, 0.1), SIMD2(0.9, 0.2), SIMD2(0.5, 0.8), SIMD2(0.1, 0.6), SIMD2(0.7, 0.7)]
        for mode in 0 ..< 8 {
            let strong = mode & 1 != 0, linLog = mode & 2 != 0, hubs = mode & 4 != 0
            var m = [Double](repeating: 1, count: 5)
            for (u, v) in pairs where u != v {
                m[u] += 1
                m[v] += 1
            }
            let compensation = m.reduce(0, +) / 5
            var p = start
            var old = [SIMD2<Double>](repeating: .zero, count: 5)
            var speed = 1.0, efficiency = 1.0
            for _ in 0 ..< 30 {
                var f = [SIMD2<Double>](repeating: .zero, count: 5)
                for v in 0 ..< 5 {
                    for u in 0 ..< 5 where u != v {
                        let d = p[v] - p[u]
                        f[v] += d * (2 * m[v] * m[u] / max((d * d).sum(), 1e-4))
                    }
                    let r = (p[v] * p[v]).sum().squareRoot()
                    if strong { f[v] -= p[v] * m[v] } else if r > 0 { f[v] -= p[v] * (m[v] / r) }
                }
                for (k, (a, b)) in pairs.enumerated() where a != b {
                    let d = p[a] - p[b]
                    var factor = w[k]
                    if linLog {
                        let length = (d * d).sum().squareRoot()
                        factor = length > 0 ? factor * log(1 + length) / length : 0
                    }
                    if hubs { factor *= compensation / m[a] }
                    f[a] -= d * factor
                    f[b] += d * factor
                }
                var swing = 0.0, traction = 0.0
                for v in 0 ..< 5 {
                    let c = old[v] - f[v], s = old[v] + f[v]
                    swing += m[v] * (c * c).sum().squareRoot()
                    traction += 0.5 * m[v] * (s * s).sum().squareRoot()
                }
                let optimal = 0.05 * 5.0.squareRoot()
                var jitter = max(optimal.squareRoot(), min(10, optimal * traction / 25))
                if swing / traction > 2 {
                    if efficiency > 0.05 { efficiency *= 0.5 }
                    jitter = max(jitter, 1)
                }
                let target = jitter * efficiency * traction / swing
                if swing > jitter * traction {
                    if efficiency > 0.05 { efficiency *= 0.7 }
                } else if speed < 1000 {
                    efficiency *= 1.3
                }
                speed += min(target - speed, 0.5 * speed)
                for v in 0 ..< 5 {
                    let c = old[v] - f[v]
                    p[v] += f[v] * (speed / (1 + (speed * m[v] * (c * c).sum().squareRoot()).squareRoot()))
                    old[v] = f[v]
                }
            }
            let layout = graph.forceAtlas2Layout(
                initial: Drawing(vertices: 0 ..< 5, positions: start), iterations: 30, strongGravity: strong, linLog: linLog, dissuadeHubs: hubs,
                weight: { w[$0] })
            for (a, b) in zip(layout.positions, p) {
                #expect(abs(a.x - b.x) <= 1e-9 * max(1, abs(b.x)) && abs(a.y - b.y) <= 1e-9 * max(1, abs(b.y)), "mode \(mode): \(a) vs \(b)")
            }
        }
    }
}
