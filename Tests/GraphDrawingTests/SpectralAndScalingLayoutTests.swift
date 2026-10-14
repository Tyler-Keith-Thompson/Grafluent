// spectralLayout and multidimensionalScalingLayout beyond the catalog rows (SpectralLayoutTests.swift):
// weights and parallel edges, the axes' properties and signs, the small cases, components, huge
// weights and lengths, the iteration limit, and representations.

import AdjacencyListModule
import GraphDrawing
import GraphProtocols
import Multigraphs
import SpectralGraphTheory
import Testing

@Suite("spectralLayout, multidimensionalScalingLayout")
struct SpectralAndScalingLayoutTests {
    @Test("spectral: parallel edges add their weights; a weight of 0 is no edge")
    func spectralWeights() throws {
        let pairs = [(11, 9), (7, 11), (8, 7), (3, 1), (0, 10), (5, 10), (2, 11), (11, 2), (2, 6), (7, 6), (1, 3), (11, 8), (1, 5), (5, 9), (2, 9), (8, 4), (9, 0), (0, 6), (9, 4), (1, 0)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let layout = try graph.spectralLayout()
        // Positions 6 and 7 join 2 and 11, 3 and 10 join 1 and 3: weight 2 on one copy, 0 on the other.
        let weighted = try graph.spectralLayout(weight: { [6, 10].contains($0) ? 0 : ($0 == 7 || $0 == 3 ? 2 : 1) })
        for (a, b) in zip(weighted.positions, layout.positions) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12) }
        // Doubling every weight halves nothing: the axes are unit eigenvectors.
        let doubled = try graph.spectralLayout(weight: { _ in 2 })
        for (a, b) in zip(doubled.positions, layout.positions) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12) }
    }

    @Test("spectral: unit, orthogonal to each other and to the constant vector; loops ignored; weights scale-free")
    func spectralProperties() throws {
        // Eigenvalues 0, 1, 1.59, 3, 4, 4.41: distinct, so each axis is determined up to its sign.
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 3),
                                                              UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 1), UndirectedEdge(4, 4)])
        let layout = try graph.spectralLayout()
        var xx = 0.0, yy = 0.0, xy = 0.0, sx = 0.0, sy = 0.0
        for p in layout.positions {
            xx += p.x * p.x
            yy += p.y * p.y
            xy += p.x * p.y
            sx += p.x
            sy += p.y
        }
        #expect(abs(xx - 1) <= 1e-12 && abs(yy - 1) <= 1e-12 && abs(xy) <= 1e-12 && abs(sx) <= 1e-12 && abs(sy) <= 1e-12)
        // The loop's weight is never read into the matrix.
        let noLoop = try graph.spectralLayout(weight: { $0 == 7 ? 1e300 : 1 })
        for (a, b) in zip(noLoop.positions, layout.positions) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12) }
        // Huge equal weights do not overflow (a degree of 3 · 10³⁰⁸ would) and give the same axes.
        let huge = try graph.spectralLayout(weight: { _ in 1e308 })
        for (a, b) in zip(huge.positions, layout.positions) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12) }
        // The first entry above 1e-4 of the largest is positive on each axis.
        #expect(layout.positions.first { abs($0.x) >= 1e-4 }!.x > 0)
    }

    @Test("spectral: the sign skips an entry below 1e-4 of the largest")
    func spectralSign() throws {
        // The path 1–2–0–3–4: vertex 0 is the middle, its Fiedler entry 0 up to rounding.
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(0, 3), UndirectedEdge(3, 4)])
        let layout = try graph.spectralLayout()
        #expect(abs(layout.positions[0].x) <= 1e-12)
        #expect(abs(layout.positions[1].x - 0.601500955) <= 1e-8 && abs(layout.positions[4].x + 0.601500955) <= 1e-8)
        // The third eigenvector's first entry, vertex 0's, is large: it is made positive.
        #expect(abs(layout.positions[0].y - 0.632455532) <= 1e-8 && abs(layout.positions[1].y + 0.511667274) <= 1e-8)
    }

    @Test("spectral: no vertex, one vertex at the origin, two vertices on the x axis, isolated vertices")
    func spectralSmall() throws {
        #expect(try Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).spectralLayout().isEmpty)
        #expect(try Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)]).spectralLayout().positions == [.zero])
        let two = try Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)]).spectralLayout().positions
        let h = 0.5.squareRoot()
        #expect(abs(two[0].x - h) <= 1e-15 && abs(two[1].x + h) <= 1e-15 && two[0].y == 0 && two[1].y == 0)
        // Three isolated vertices: L = 0, every axis an eigenvector of 0.
        let empty = try Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>]).spectralLayout()
        for p in empty.positions { #expect(p.x.isFinite && p.y.isFinite) }
    }

    @Test("spectral: maxIterations 1 throws NoConvergence; representations agree")
    func spectralLimitAndRepresentations() throws {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 3)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(throws: NoConvergence.self) { try graph.spectralLayout(maxIterations: 1) }
        let reference = try graph.spectralLayout()
        let list = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(try list.spectralLayout() == reference)
        let csr = AdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let viaView = try csr.undirectedView.spectralLayout()
        for (a, b) in zip(viaView.positions, reference.positions) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12) }
        let named = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d", "e", "f"], edges: pairs.map { UndirectedEdge(["a", "b", "c", "d", "e", "f"][$0.0], ["a", "b", "c", "d", "e", "f"][$0.1]) })
        let byName = try named.spectralLayout()
        for (a, b) in zip(byName.positions, reference.positions) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12) }
    }

    @Test("scaling: a path is drawn on a line at its hop distances")
    func scalingPath() throws {
        let three = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let p = try three.multidimensionalScalingLayout().positions
        #expect(abs(p[0].x - 1) <= 1e-12 && abs(p[1].x) <= 1e-12 && abs(p[2].x + 1) <= 1e-12)
        for q in p { #expect(abs(q.y) <= 1e-7) }
        let six = Pseudograph<Int>(vertices: 0 ..< 6, edges: (0 ..< 5).map { UndirectedEdge($0, $0 + 1) })
        let line = try six.multidimensionalScalingLayout().positions
        for i in 0 ..< 6 {
            for j in 0 ..< 6 {
                let d = line[i] - line[j]
                #expect(abs((d * d).sum().squareRoot() - Double(abs(i - j))) <= 1e-9)
            }
        }
    }

    @Test("scaling: a 3–4–5 triangle by edge length is reproduced exactly")
    func scalingTriangle() throws {
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let lengths = [3.0, 4.0, 5.0]
        let p = try graph.multidimensionalScalingLayout(edgeLength: { lengths[$0] }).positions
        for (k, (u, v)) in [(0, 1), (1, 2), (2, 0)].enumerated() {
            let d = p[u] - p[v]
            #expect(abs((d * d).sum().squareRoot() - lengths[k]) <= 1e-9)
        }
        let mean = (p[0] + p[1] + p[2]) / 3
        #expect(abs(mean.x) <= 1e-12 && abs(mean.y) <= 1e-12)
        // Scaling every length scales the drawing; huge lengths do not overflow.
        let big = try graph.multidimensionalScalingLayout(edgeLength: { lengths[$0] * 1e200 }).positions
        for i in 0 ..< 3 { #expect(abs(big[i].x / 1e200 - p[i].x) <= 1e-9 && abs(big[i].y / 1e200 - p[i].y) <= 1e-9) }
    }

    @Test("scaling: components are 1 + L̄√n apart; parallel edges and loops; small graphs")
    func scalingComponents() throws {
        let apart = 1 + 2.0.squareRoot()
        let two = try Pseudograph<Int>(vertices: 0 ..< 2, edges: [] as [UndirectedEdge<Int>]).multidimensionalScalingLayout().positions
        #expect(abs(two[0].x - apart / 2) <= 1e-12 && abs(two[1].x + apart / 2) <= 1e-12 && two[0].y == 0 && two[1].y == 0)
        // A doubled edge and a loop: the loop is ignored, the shorter copy counts.
        let multi = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let m = try multi.multidimensionalScalingLayout(edgeLength: { [5, 2, 7][$0] }).positions
        #expect(abs((m[0] - m[1]).x.magnitude - 2) <= 1e-12)
        // An edge of two copies, lengths 2 and 4, and an isolated vertex: L̄ = 3, so the isolated
        // vertex is 1 + 3√3 from both ends, an isosceles triangle reproduced exactly.
        let lonely = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)])
        let t = try lonely.multidimensionalScalingLayout(edgeLength: { [2, 4][$0] }).positions
        let far = 1 + 3 * 3.0.squareRoot()
        #expect(abs(((t[0] - t[1]) * (t[0] - t[1])).sum().squareRoot() - 2) <= 1e-9)
        #expect(abs(((t[0] - t[2]) * (t[0] - t[2])).sum().squareRoot() - far) <= 1e-9)
        #expect(abs(((t[1] - t[2]) * (t[1] - t[2])).sum().squareRoot() - far) <= 1e-9)
        #expect(try Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>]).multidimensionalScalingLayout().isEmpty)
        #expect(try Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>]).multidimensionalScalingLayout().positions == [.zero])
        let six = Pseudograph<Int>(vertices: 0 ..< 6, edges: (0 ..< 5).map { UndirectedEdge($0, $0 + 1) })
        #expect(throws: NoConvergence.self) { try six.multidimensionalScalingLayout(maxIterations: 1) }
    }

    @Test("scaling: representations agree")
    func scalingRepresentations() throws {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (3, 4)]
        let reference = try Pseudograph<Int>(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) }).multidimensionalScalingLayout()
        let list = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(try list.multidimensionalScalingLayout() == reference)
        let csr = AdjacencyList<Int>(vertices: 0 ..< 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let viaView = try csr.undirectedView.multidimensionalScalingLayout()
        for (a, b) in zip(viaView.positions, reference.positions) { #expect(abs(a.x - b.x) <= 1e-12 && abs(a.y - b.y) <= 1e-12) }
    }
}
