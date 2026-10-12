// Every entry point on the package's representations against the `ReferencePseudograph` and
// `ReferenceDirectedMultigraph`: `Pseudograph`, `UndirectedAdjacencyList`, `AdjacencyList` through
// `.undirectedView`, and a file-private conformer with String vertices and no indices (rows in
// `vertices` order); directed matrices on `AdjacencyList`, `CompressedSparseRow` and
// `AdjacencyMatrix`; `graph.directedView` and `digraph.undirectedView`. Random graphs come from a seeded
// generator; weights are functions of an edge's endpoints in quarters, so every sum is exact and
// matrices compare with ==. Then SparseMatrix's Equatable and Hashable, determinism, `tolerance:`,
// Sendable, and how often each weighted entry point reads the weight closure. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import SpectralGraphTheory
import Testing

/// An undirected multigraph with String vertices and no vertex or edge indices: algorithms number
/// the vertices in `vertices` order themselves.
private struct UnindexedGraph: Graph {
    let vertices: [String]
    let edges: [UndirectedEdge<String>]

    func neighbors(of vertex: String) -> [String] {
        incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) }
    }

    func incidentEdges(of vertex: String) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return (e.u == vertex ? [k] : []) + (e.v == vertex ? [k] : [])
        }
    }

    func contains(_ vertex: String) -> Bool { vertices.contains(vertex) }
}

@Suite("SpectralGraphTheory on every representation", .tags(.conformance))
struct SpectralConformanceTests {
    @Test("Undirected: Pseudograph, UndirectedAdjacencyList, AdjacencyList.undirectedView and String vertices without indices agree with the reference", arguments: 0 ..< 40)
    func undirectedRepresentations(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 1 ... 12, using: &rng)
        // Simple graphs with loops (every representation here holds them), vertices in a shuffled order.
        var pairs = Set<[Int]>()
        for _ in 0 ..< Int.random(in: 0 ... 2 * n, using: &rng) {
            let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
            pairs.insert([min(u, v), max(u, v)])
        }
        let edgeList = pairs.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }.map { UndirectedEdge($0[0], $0[1]) }
        let listed = Array(0 ..< n).shuffled(using: &rng)
        func conductance(_ e: UndirectedEdge<Int>) -> Double {
            let mixed: Int = e.u * 7 + e.v * 7 + e.u * e.v
            return Double(mixed % 5 + 1) / 4
        }
        let reference = ReferencePseudograph(vertices: listed, edges: edgeList)
        let pseudograph = Pseudograph(vertices: listed, edges: edgeList)
        let adjacencyList = UndirectedAdjacencyList(vertices: listed, edges: edgeList)
        let arcs = AdjacencyList(vertices: listed, edges: edgeList.map { DirectedEdge(from: $0.u, to: $0.v) }).undirectedView
        let strings = UnindexedGraph(vertices: listed.map { "v\($0)" }, edges: edgeList.map { UndirectedEdge("v\($0.u)", "v\($0.v)") })
        #expect(Array(pseudograph.vertices) == listed && Array(adjacencyList.vertices) == listed && Array(arcs.vertices) == listed)
        #expect(reference.vertexIndexBound == n && strings.vertexIndexBound == nil)

        let a = reference.adjacencyMatrix(), l = reference.laplacianMatrix()
        let nm = reference.normalizedLaplacianMatrix(), rw = reference.randomWalkLaplacianMatrix(), q = reference.signlessLaplacianMatrix()
        let wl = reference.laplacianMatrix(weight: { conductance(reference.edges[$0]) })
        let wn = reference.normalizedLaplacianMatrix(weight: { conductance(reference.edges[$0]) })
        let ls = try reference.laplacianSpectrum(), ns = try reference.normalizedLaplacianSpectrum(), asp = try reference.adjacencySpectrum()
        let scale = max(1, ls.last ?? 0)
        let radius = try reference.spectralRadius()
        let trees = reference.numberOfSpanningTrees(weight: { conductance(reference.edges[$0]) })
        let effective = reference.effectiveGraphResistance(weight: { conductance(reference.edges[$0]) })
        let kemeny = reference.kemenyConstant()
        let resistance = try listed.map { u in try listed.map { v in try reference.resistanceDistance(from: u, to: v, weight: { conductance(reference.edges[$0]) }) } }
        let lambda = try n >= 2 ? reference.algebraicConnectivity() : 0
        let fiedler = try n >= 2 ? reference.fiedlerVector() : nil
        let simple = n > 2 && ls[2] - ls[1] > 1e-3 * scale
        let order = try reference.spectralOrdering()
        let context = "seed \(seed), n \(n), edges \(edgeList.map { [$0.u, $0.v] }), listed \(listed)"

        func check<G: Graph>(_ graph: G, _ name: String, vertex: (Int) -> G.Vertex) throws {
            let context = "\(name), \(context)"
            #expect(graph.adjacencyMatrix() == a, "\(context)")
            #expect(graph.laplacianMatrix() == l, "\(context)")
            #expect(graph.normalizedLaplacianMatrix() == nm, "\(context)")
            #expect(graph.randomWalkLaplacianMatrix() == rw, "\(context)")
            #expect(graph.signlessLaplacianMatrix() == q, "\(context)")
            for (mine, theirs) in try [(graph.laplacianSpectrum(), ls), (graph.normalizedLaplacianSpectrum(), ns), (graph.adjacencySpectrum(), asp)] {
                #expect(mine.count == theirs.count && zip(mine, theirs).allSatisfy { abs($0 - $1) <= 1e-9 * scale }, "\(context)")
            }
            #expect(abs(try graph.spectralRadius() - radius) <= 1e-6 * max(1, radius), "\(context)")
            let mineKemeny = graph.kemenyConstant()
            #expect((mineKemeny == nil) == (kemeny == nil), "\(context)")
            if let mineKemeny, let kemeny { #expect(abs(mineKemeny - kemeny) <= 1e-9 * max(1, kemeny), "\(context)") }
            if n >= 2 {
                #expect(abs(try graph.algebraicConnectivity() - lambda) <= 1e-6 * scale, "\(context)")
                let mine = try graph.fiedlerVector()
                #expect((mine == nil) == (fiedler == nil), "\(context)")
                if let mine, let fiedler {
                    #expect(abs(mine.algebraicConnectivity - fiedler.algebraicConnectivity) <= 1e-6 * scale, "\(context)")
                    if simple {
                        for (i, v) in listed.enumerated() {
                            #expect(abs(mine.value(of: vertex(v)) - fiedler.values[i]) <= 1e-5, "vertex \(v), \(context)")
                            #expect(mine.value(ofIndex: i) == mine.value(of: vertex(v)), "\(context)")
                        }
                    }
                }
            }
            if simple || n <= 2 || fiedler == nil {
                #expect(try graph.spectralOrdering() == order.map(vertex), "\(context)")
            } else {
                #expect(Set(try graph.spectralOrdering()) == Set(order.map(vertex)), "\(context)")
            }
        }
        try check(pseudograph, "Pseudograph") { $0 }
        try check(adjacencyList, "UndirectedAdjacencyList") { $0 }
        try check(arcs, "AdjacencyList.undirectedView") { $0 }
        try check(strings, "String vertices without indices") { "v\($0)" }

        // The weighted electrical quantities on each representation, by endpoint.
        let p = pseudograph, u = adjacencyList
        #expect(abs(p.numberOfSpanningTrees(weight: { conductance(p.edges[$0]) }) - trees) <= 1e-9 * max(1, trees), "\(context)")
        #expect(abs(u.numberOfSpanningTrees(weight: { conductance(u.edges[$0]) }) - trees) <= 1e-9 * max(1, trees), "\(context)")
        #expect(abs(arcs.numberOfSpanningTrees(weight: { conductance(arcs.edges[$0]) }) - trees) <= 1e-9 * max(1, trees), "\(context)")
        #expect(p.laplacianMatrix(weight: { conductance(p.edges[$0]) }) == wl, "\(context)")
        #expect(u.normalizedLaplacianMatrix(weight: { conductance(u.edges[$0]) }) == wn, "\(context)")
        #expect(arcs.laplacianMatrix(weight: { conductance(arcs.edges[$0]) }) == wl, "\(context)")
        let pe = p.effectiveGraphResistance(weight: { conductance(p.edges[$0]) })
        #expect((pe == nil) == (effective == nil), "\(context)")
        if let pe, let effective { #expect(abs(pe - effective) <= 1e-9 * max(1, effective), "\(context)") }
        for (i, x) in listed.enumerated() {
            for (j, y) in listed.enumerated() {
                let mine = try u.resistanceDistance(from: x, to: y, weight: { conductance(u.edges[$0]) })
                #expect((mine == nil) == (resistance[i][j] == nil), "R(\(x), \(y)), \(context)")
                if let mine, let theirs = resistance[i][j] {
                    #expect(abs(mine - theirs) <= 1e-6 * max(1, theirs), "R(\(x), \(y)), \(context)")
                }
            }
        }
        // String vertices: weighted by the same endpoints.
        let sw = strings.laplacianMatrix(weight: { k -> Double in
            let e = strings.edges[k]
            return conductance(UndirectedEdge(Int(e.u.dropFirst())!, Int(e.v.dropFirst())!))
        })
        #expect(sw == wl, "\(context)")
    }

    @Test("Directed matrices: AdjacencyList, CompressedSparseRow and AdjacencyMatrix agree with the reference", arguments: 0 ..< 40)
    func directedRepresentations(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed) &+ 1_000)
        let n = Int.random(in: 1 ... 10, using: &rng)
        var arcs = Set<[Int]>()
        for _ in 0 ..< Int.random(in: 0 ... 3 * n, using: &rng) {
            arcs.insert([Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)])
        }
        // Row-major order: the order CompressedSparseRow and AdjacencyMatrix keep.
        let edgeList = arcs.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }.map { DirectedEdge(from: $0[0], to: $0[1]) }
        func weight(_ e: DirectedEdge<Int>) -> Double { Double((e.source * 5 + e.target * 3) % 7 + 1) / 4 }
        let reference = ReferenceDirectedMultigraph(vertices: Array(0 ..< n), edges: edgeList)
        let list = AdjacencyList(vertices: Array(0 ..< n), edges: edgeList)
        let csr = CompressedSparseRow(vertexCount: n, edges: edgeList)
        let matrix = AdjacencyMatrix(vertexCount: n, edges: edgeList)
        let a = reference.adjacencyMatrix(), l = reference.laplacianMatrix()
        let wa = reference.adjacencyMatrix(weight: { weight(reference.edges[$0]) })
        let wl = reference.laplacianMatrix(weight: { weight(reference.edges[$0]) })
        let context = "seed \(seed), n \(n), arcs \(edgeList.map { [$0.source, $0.target] })"
        #expect(list.adjacencyMatrix() == a && csr.adjacencyMatrix() == a && matrix.adjacencyMatrix() == a, "\(context)")
        #expect(list.laplacianMatrix() == l && csr.laplacianMatrix() == l && matrix.laplacianMatrix() == l, "\(context)")
        #expect(list.adjacencyMatrix(weight: { weight(list.edges[$0]) }) == wa, "\(context)")
        #expect(csr.adjacencyMatrix(weight: { weight(csr.edges[$0]) }) == wa, "\(context)")
        #expect(matrix.laplacianMatrix(weight: { weight(matrix.edges[$0]) }) == wl, "\(context)")
        #expect(csr.laplacianMatrix(weight: { weight(csr.edges[$0]) }) == wl, "\(context)")
        // Out-degrees: L's row sums are 0 and its diagonal is the out-degree without loops.
        #expect(l * [Double](repeating: 1, count: n) == [Double](repeating: 0, count: n), "\(context)")
        for v in 0 ..< n {
            let out = edgeList.filter { $0.source == v && $0.target != v }.count
            #expect(l[v, v] == Double(out), "vertex \(v), \(context)")
        }
    }

    @Test("graph.directedView has the same A and L as the graph, loops and parallel edges included", arguments: 0 ..< 30)
    func directedView(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed) &+ 2_000)
        let n = Int.random(in: 1 ... 8, using: &rng)
        let edges = (0 ..< Int.random(in: 0 ... 14, using: &rng)).map { _ in
            UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
        }
        let graph = ReferencePseudograph(vertices: Array(0 ..< n).shuffled(using: &rng), edges: edges)
        let context = "seed \(seed), edges \(edges.map { [$0.u, $0.v] })"
        #expect(graph.directedView.adjacencyMatrix() == graph.adjacencyMatrix(), "\(context)")
        #expect(graph.directedView.laplacianMatrix() == graph.laplacianMatrix(), "\(context)")
    }

    @Test("digraph.undirectedView: the spectral quantities of the symmetrization, as an undirected multigraph of the arcs", arguments: 0 ..< 30)
    func undirectedView(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed) &+ 3_000)
        let n = Int.random(in: 2 ... 9, using: &rng)
        var arcs = Set<[Int]>()
        for _ in 0 ..< Int.random(in: n ... 3 * n, using: &rng) {
            let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng)
            if u != v { arcs.insert([u, v]) }
        }
        let edgeList = arcs.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
        let digraph = AdjacencyList(vertices: Array(0 ..< n), edges: edgeList.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let reference = ReferencePseudograph(vertices: Array(0 ..< n), edges: edgeList.map { UndirectedEdge($0[0], $0[1]) })
        let view = digraph.undirectedView
        let context = "seed \(seed), arcs \(edgeList)"
        // Both arcs of a pair are two parallel edges.
        #expect(view.laplacianMatrix() == reference.laplacianMatrix(), "\(context)")
        #expect(view.numberOfSpanningTrees() == reference.numberOfSpanningTrees(), "\(context)")
        let scale = max(1, try reference.laplacianSpectrum().last ?? 0)
        #expect(abs(try view.algebraicConnectivity() - reference.algebraicConnectivity()) <= 1e-6 * scale, "\(context)")
        let mine = view.kemenyConstant(), theirs = reference.kemenyConstant()
        #expect((mine == nil) == (theirs == nil), "\(context)")
        if let mine, let theirs { #expect(abs(mine - theirs) <= 1e-9 * max(1, theirs), "\(context)") }
    }

    @Test("SparseMatrix: equal matrices are == and hash alike; one entry apart, they differ")
    func sparseMatrixEquality() {
        let path = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let reversed = UndirectedAdjacencyList(vertices: [0, 1, 2], edges: [UndirectedEdge(2, 1), UndirectedEdge(1, 0)])
        let weighted = path.laplacianMatrix(weight: { [1, 2][$0] })
        #expect(path.laplacianMatrix() == reversed.laplacianMatrix())
        #expect(path.laplacianMatrix().hashValue == reversed.laplacianMatrix().hashValue)
        #expect(Set([path.laplacianMatrix(), reversed.laplacianMatrix(), weighted]).count == 2)
        #expect(path.laplacianMatrix() != weighted)
        #expect(path.laplacianMatrix() != path.signlessLaplacianMatrix())
        // The same pattern with other values, and other patterns, are different matrices.
        #expect(path.adjacencyMatrix() != path.adjacencyMatrix(weight: { [1, 1.5][$0] }))
        #expect(path.adjacencyMatrix().pattern == path.adjacencyMatrix(weight: { [1, 1.5][$0] }).pattern)
        let empty = ReferencePseudograph(vertices: [] as [Int], edges: [])
        let one = ReferencePseudograph(vertices: [0], edges: [])
        #expect(empty.laplacianMatrix() != one.laplacianMatrix())
        #expect(empty.laplacianMatrix() == UndirectedAdjacencyList<Int>().laplacianMatrix())
        #expect(!path.laplacianMatrix().description.isEmpty)
    }

    @Test("Results are deterministic: two calls give the same bits, also on the Lanczos path (n ≥ 64)")
    func determinism() throws {
        var rng = SeededRandomNumberGenerator(seed: 11)
        for n in [10, 200] {
            var edges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
            for _ in 0 ..< 2 * n { edges.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            #expect(try graph.algebraicConnectivity() == graph.algebraicConnectivity(), "n \(n)")
            #expect(try graph.fiedlerVector()?.values == graph.fiedlerVector()?.values, "n \(n)")
            #expect(try graph.fiedlerVector(normalized: true)?.values == graph.fiedlerVector(normalized: true)?.values, "n \(n)")
            #expect(try graph.spectralOrdering() == graph.spectralOrdering(), "n \(n)")
            #expect(try graph.spectralRadius() == graph.spectralRadius(), "n \(n)")
            #expect(try graph.resistanceDistance(from: 0, to: n - 1) == graph.resistanceDistance(from: 0, to: n - 1), "n \(n)")
        }
    }

    @Test("tolerance: λ₂ and ρ stay within it relative to themselves, the Fiedler residual within tolerance · λ₂")
    func toleranceParameter() throws {
        var rng = SeededRandomNumberGenerator(seed: 5)
        let n = 300
        var edges = (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) }
        for _ in 0 ..< 600 { edges.append(UndirectedEdge(Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))) }
        let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
        let exact = try graph.laplacianSpectrum()
        for tolerance in [1e-3, 1e-6, 1e-8, 1e-10] {
            let value = try graph.algebraicConnectivity(tolerance: tolerance)
            #expect(abs(value - exact[1]) <= tolerance * exact[1], "tolerance \(tolerance)")
            if let fiedler = try graph.fiedlerVector(tolerance: tolerance) {
                let x = fiedler.values
                let lx = graph.laplacianMatrix() * x
                let residual = zip(lx, x).reduce(0) { $0 + ($1.0 - fiedler.algebraicConnectivity * $1.1) * ($1.0 - fiedler.algebraicConnectivity * $1.1) }
                #expect(residual.squareRoot() <= 10 * tolerance * exact[1] + 1e-12 * exact[n - 1], "tolerance \(tolerance)")
            } else {
                Issue.record("nil on a connected graph")
            }
        }
        let largest = try graph.adjacencySpectrum().map { abs($0) }.max()!
        #expect(abs(try graph.spectralRadius(tolerance: 1e-4) - largest) <= 1e-4 * largest)
        #expect(abs(try graph.spectralRadius() - largest) <= 1e-8 * largest)
        // resistanceDistance's tolerance: a loose one is still within 10 %.
        let r = try graph.resistanceDistance(from: 0, to: n - 1)
        let loose = try graph.resistanceDistance(from: 0, to: n - 1, tolerance: 1e-4)
        if let r, let loose { #expect(abs(r - loose) <= 1e-1 * max(1, r)) } else { Issue.record("nil on a connected graph") }
    }

    @Test("SparseMatrix is Sendable: a matrix built in a task is read in another")
    func sendable() async {
        let graph = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let matrix = await Task { graph.laplacianMatrix() }.value
        let entry = await Task { matrix[1, 1] }.value
        #expect(entry == 2)
    }

    @Test("Each weighted entry point reads the weight of the edge at each position exactly once")
    func weightReading() throws {
        final class Reads {
            var count: [Int]
            init(_ m: Int) { count = [Int](repeating: 0, count: m) }
        }
        // A connected multigraph with a loop and a parallel pair, on 70 vertices (the sparse path).
        var edges = (0 ..< 69).map { UndirectedEdge($0, $0 + 1) }
        edges += [UndirectedEdge(3, 3), UndirectedEdge(0, 1), UndirectedEdge(0, 69), UndirectedEdge(10, 40)]
        let graph = ReferencePseudograph(vertices: Array(0 ..< 70), edges: edges)
        let m = edges.count
        func reads(_ call: (_ weight: @escaping (Int) -> Double) throws -> Void) rethrows -> [Int] {
            let r = Reads(m)
            try call { p in r.count[p] += 1; return Double(p % 3 + 1) }
            return r.count
        }
        let once = [Int](repeating: 1, count: m)
        #expect(reads { _ = graph.adjacencyMatrix(weight: $0) } == once, "adjacencyMatrix")
        #expect(reads { _ = graph.laplacianMatrix(weight: $0) } == once, "laplacianMatrix")
        #expect(reads { _ = graph.normalizedLaplacianMatrix(weight: $0) } == once, "normalizedLaplacianMatrix")
        #expect(reads { _ = graph.randomWalkLaplacianMatrix(weight: $0) } == once, "randomWalkLaplacianMatrix")
        #expect(reads { _ = graph.signlessLaplacianMatrix(weight: $0) } == once, "signlessLaplacianMatrix")
        #expect(try reads { _ = try graph.adjacencySpectrum(weight: $0) } == once, "adjacencySpectrum")
        #expect(try reads { _ = try graph.laplacianSpectrum(weight: $0) } == once, "laplacianSpectrum")
        #expect(try reads { _ = try graph.normalizedLaplacianSpectrum(weight: $0) } == once, "normalizedLaplacianSpectrum")
        #expect(try reads { _ = try graph.algebraicConnectivity(weight: $0) } == once, "algebraicConnectivity")
        #expect(try reads { _ = try graph.algebraicConnectivity(weight: $0, normalized: true) } == once, "algebraicConnectivity(normalized:)")
        #expect(try reads { _ = try graph.fiedlerVector(weight: $0) } == once, "fiedlerVector")
        #expect(try reads { _ = try graph.spectralOrdering(weight: $0) } == once, "spectralOrdering")
        #expect(try reads { _ = try graph.spectralRadius(weight: $0) } == once, "spectralRadius")
        #expect(reads { _ = graph.numberOfSpanningTrees(weight: $0) } == once, "numberOfSpanningTrees")
        #expect(try reads { _ = try graph.resistanceDistance(from: 0, to: 50, weight: $0) } == once, "resistanceDistance")
        #expect(reads { _ = graph.effectiveGraphResistance(weight: $0) } == once, "effectiveGraphResistance")
        #expect(reads { _ = graph.kemenyConstant(weight: $0) } == once, "kemenyConstant")
        let digraph = ReferenceDirectedMultigraph(vertices: Array(0 ..< 70), edges: edges.map { DirectedEdge(from: $0.u, to: $0.v) })
        #expect(reads { _ = digraph.adjacencyMatrix(weight: $0) } == once, "directed adjacencyMatrix")
        #expect(reads { _ = digraph.laplacianMatrix(weight: $0) } == once, "directed laplacianMatrix")
    }
}
