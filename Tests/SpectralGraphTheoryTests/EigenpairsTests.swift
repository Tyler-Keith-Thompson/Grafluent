// The k extreme eigenpairs of A, L, N and Q: hand-computed spectra and vectors on small graphs
// (the dense path), closed forms on graphs of 64 vertices or more (the Lanczos paths: σI − M,
// shift-invert, locking past a multiple eigenvalue), agreement with the dense spectra, the weight
// overloads, the lookups and the iteration limits.

import AdjacencyListModule
import Foundation
import GraphProtocols
import Multigraphs
import SpectralGraphTheory
import Testing

/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.
private struct UnindexedGraph<Vertex: Hashable>: Graph {
    let vertices: [Vertex]
    let edges: [UndirectedEdge<Vertex>]

    func incidentEdges(of vertex: Vertex) -> [Int] {
        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }
    }
    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
}

@Suite("Eigenpairs")
struct EigenpairsTests {
    @Test("P3: L's eigenpairs 0, 1, 3 with (1,1,1)/√3, (1,0,−1)/√2, (1,−2,1)/√6")
    func pathOfThree() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let pairs = try graph.laplacianEigenpairs(smallest: 3)
        #expect(pairs.count == 3)
        let expectedValues = [0.0, 1, 3]
        let expectedVectors: [[Double]] = [[1, 1, 1].map { $0 / 3.0.squareRoot() }, [1, 0, -1].map { $0 / 2.0.squareRoot() }, [1, -2, 1].map { $0 / 6.0.squareRoot() }]
        for i in 0 ..< 3 {
            #expect(abs(pairs.eigenvalues[i] - expectedValues[i]) < 1e-12)
            let x = pairs.eigenvector(at: i)
            for v in 0 ..< 3 { #expect(abs(x[v] - expectedVectors[i][v]) < 1e-12, "vector \(i), entry \(v)") }
        }
        let largest = try graph.laplacianEigenpairs(largest: 2)
        #expect(abs(largest.eigenvalues[0] - 3) < 1e-12 && abs(largest.eigenvalues[1] - 1) < 1e-12)
        for v in 0 ..< 3 { #expect(abs(largest.eigenvector(at: 0)[v] - expectedVectors[2][v]) < 1e-12) }
        // The entries of a vertex across the vectors.
        #expect(pairs.eigenvectorEntries(of: 1).enumerated().allSatisfy { abs($0.element - expectedVectors[$0.offset][1]) < 1e-12 })
        #expect(pairs.eigenvectorEntries(ofIndex: 2) == pairs.eigenvectorEntries(of: 2))
    }

    @Test("K4: A's largest is 3 with the uniform vector, then −1; N's smallest 0 then 4/3")
    func completeGraph() throws {
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< 4 { for v in u + 1 ..< 4 { edges.append(UndirectedEdge(u, v)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: edges)
        let pairs = try graph.adjacencyEigenpairs(largest: 2)
        #expect(abs(pairs.eigenvalues[0] - 3) < 1e-12 && abs(pairs.eigenvalues[1] + 1) < 1e-12)
        #expect(pairs.eigenvector(at: 0).allSatisfy { abs($0 - 0.5) < 1e-12 })
        let second = pairs.eigenvector(at: 1)
        #expect(abs(second.reduce(0, +)) < 1e-12)
        #expect(abs(second.map { $0 * $0 }.reduce(0, +) - 1) < 1e-12)
        let smallest = try graph.adjacencyEigenpairs(smallest: 3)
        #expect(smallest.eigenvalues.allSatisfy { abs($0 + 1) < 1e-12 })
        let normalized = try graph.normalizedLaplacianEigenpairs(smallest: 2)
        #expect(abs(normalized.eigenvalues[0]) < 1e-15 && abs(normalized.eigenvalues[1] - 4.0 / 3) < 1e-12)
    }

    @Test("The star K1,3: A's spectrum ±√3, 0, 0, the largest vector (√3, 1, 1, 1)/√6")
    func star() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])
        let largest = try graph.adjacencyEigenpairs(largest: 1)
        #expect(abs(largest.eigenvalues[0] - 3.0.squareRoot()) < 1e-12)
        let x = largest.eigenvector(at: 0)
        #expect(abs(x[0] - 3.0.squareRoot() / 6.0.squareRoot()) < 1e-12)
        for v in 1 ..< 4 { #expect(abs(x[v] - 1 / 6.0.squareRoot()) < 1e-12) }
        let smallest = try graph.adjacencyEigenpairs(smallest: 2)
        #expect(abs(smallest.eigenvalues[0] + 3.0.squareRoot()) < 1e-12 && abs(smallest.eigenvalues[1]) < 1e-12)
        // The most negative eigenvector alternates in sign between the centre and the leaves.
        let y = smallest.eigenvector(at: 0)
        #expect(y[0] > 0 && y[1] < 0 && y[2] < 0 && y[3] < 0)
    }

    @Test("Two triangles: L's smallest are 0 twice, each the indicator of a component, then 3")
    func disconnected() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        let pairs = try graph.laplacianEigenpairs(smallest: 3)
        #expect(pairs.eigenvalues[0] == 0 && pairs.eigenvalues[1] == 0)
        #expect(abs(pairs.eigenvalues[2] - 3) < 1e-12)
        let third = 1 / 3.0.squareRoot()
        #expect(pairs.eigenvector(at: 0) == [third, third, third, 0, 0, 0])
        #expect(pairs.eigenvector(at: 1) == [0, 0, 0, third, third, third])
        // The third lies in the first triangle (ties in component order) and sums to 0 there.
        let x = pairs.eigenvector(at: 2)
        #expect(x[3 ..< 6].allSatisfy { $0 == 0 } && abs(x[0 ..< 3].reduce(0, +)) < 1e-12)
        let normalized = try graph.normalizedLaplacianEigenpairs(smallest: 2)
        #expect(normalized.eigenvalues == [0, 0])
        #expect(normalized.eigenvector(at: 1) == [0, 0, 0, third, third, third])
    }

    @Test("Isolated vertices: each its own component, null vector e_v, on L and on N")
    func isolatedVertices() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(1, 2)])
        for pairs in [try graph.laplacianEigenpairs(smallest: 3), try graph.normalizedLaplacianEigenpairs(smallest: 3)] {
            #expect(pairs.eigenvalues[0] == 0 && pairs.eigenvalues[1] == 0)
            #expect(pairs.eigenvector(at: 0) == [1, 0, 0])
            #expect(abs(pairs.eigenvector(at: 1)[1] - 1 / 2.0.squareRoot()) < 1e-15)
            #expect(abs(pairs.eigenvalues[2] - 2) < 1e-12)
        }
        let single = UndirectedAdjacencyList(vertices: 0 ..< 1, edges: [])
        #expect(try single.laplacianEigenpairs(smallest: 1).eigenvector(at: 0) == [1])
        #expect(try single.adjacencyEigenpairs(largest: 1).eigenvalues == [0])
    }

    @Test("A count of 0 returns no pair, also on the empty graph")
    func countZero() throws {
        let empty = UndirectedAdjacencyList<Int>(vertices: 0 ..< 0, edges: [])
        #expect(try empty.laplacianEigenpairs(smallest: 0).count == 0)
        #expect(try empty.adjacencyEigenpairs(largest: 0).eigenvalues.isEmpty)
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        let none = try graph.signlessLaplacianEigenpairs(largest: 0)
        #expect(none.count == 0 && none.eigenvectorEntries(of: 0).isEmpty)
    }

    @Test("Self-loops: L ignores them; a loop adds 2 to A[v][v] and 4 to Q[v][v]")
    func selfLoops() throws {
        let graph = Pseudograph(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        let laplacian = try graph.laplacianEigenpairs(smallest: 2)
        #expect(abs(laplacian.eigenvalues[0]) < 1e-15 && abs(laplacian.eigenvalues[1] - 2) < 1e-12)
        // A = [[2, 1], [1, 0]]: 1 ± √2.
        let adjacency = try graph.adjacencyEigenpairs(largest: 2)
        #expect(abs(adjacency.eigenvalues[0] - (1 + 2.0.squareRoot())) < 1e-12 && abs(adjacency.eigenvalues[1] - (1 - 2.0.squareRoot())) < 1e-12)
        // Q = D + A = [[5, 1], [1, 1]] (the loop adds 2 to d(0) and 2 to A[0][0]): 3 ± √5.
        let signless = try graph.signlessLaplacianEigenpairs(smallest: 2)
        #expect(abs(signless.eigenvalues[0] - (3 - 5.0.squareRoot())) < 1e-12 && abs(signless.eigenvalues[1] - (3 + 5.0.squareRoot())) < 1e-12)
    }

    @Test("Parallel edges add up: a doubled edge is weight 2")
    func parallelEdges() throws {
        let doubled = Pseudograph(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let weighted = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let a = try doubled.laplacianEigenpairs(smallest: 3)
        let b = try weighted.laplacianEigenpairs(smallest: 3, weight: { [2, 1][$0] })
        for i in 0 ..< 3 {
            #expect(abs(a.eigenvalues[i] - b.eigenvalues[i]) < 1e-12)
            #expect(zip(a.eigenvector(at: i), b.eigenvector(at: i)).allSatisfy { abs($0 - $1) < 1e-12 })
        }
        // 3 ± √3 for L = [[2, −2, 0], [−2, 3, −1], [0, −1, 1]].
        #expect(abs(a.eigenvalues[1] - (3 - 3.0.squareRoot())) < 1e-12 && abs(a.eigenvalues[2] - (3 + 3.0.squareRoot())) < 1e-12)
    }

    @Test("C₁₀₀ by Lanczos: L's smallest are 0 and the double 2 − 2cos(2π/100), both copies found")
    func cycleDoubleEigenvalue() throws {
        let n = 100
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) })
        let pairs = try graph.laplacianEigenpairs(smallest: 5)
        let expected = [0, 1, 1, 2, 2].map { 2 - 2 * cos(2 * Double.pi * Double($0) / Double(n)) }
        for i in 0 ..< 5 { #expect(abs(pairs.eigenvalues[i] - expected[i]) <= 1e-7 * max(expected[i], 1e-3), "λ\(i)") }
        // Orthonormal, and each an eigenvector: ‖Lx − λx‖ small.
        let laplacian = graph.laplacianMatrix()
        for i in 0 ..< 5 {
            let x = pairs.eigenvector(at: i)
            let lx = laplacian * x
            var residual = 0.0
            for v in 0 ..< n { residual += (lx[v] - pairs.eigenvalues[i] * x[v]) * (lx[v] - pairs.eigenvalues[i] * x[v]) }
            #expect(residual.squareRoot() <= 1e-6 * max(pairs.eigenvalues[i], 1e-3), "residual \(i)")
            for j in 0 ... i {
                let dot = zip(x, pairs.eigenvector(at: j)).map(*).reduce(0, +)
                #expect(abs(dot - (i == j ? 1 : 0)) < 1e-9, "x\(i)·x\(j)")
            }
        }
    }

    @Test("P₃₀₀ by shift-invert: L's 4 smallest are 2 − 2cos(πk/300)")
    func pathShiftInvert() throws {
        let n = 300
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        let pairs = try graph.laplacianEigenpairs(smallest: 4)
        for k in 0 ..< 4 {
            let expected = 2 - 2 * cos(Double.pi * Double(k) / Double(n))
            #expect(abs(pairs.eigenvalues[k] - expected) <= 1e-7 * max(expected, 1e-12), "λ\(k)")
        }
        // The k-th vector is cos(πk(v + ½)/n), normalized, with the canonical sign.
        for k in 1 ..< 4 {
            let x = pairs.eigenvector(at: k)
            var y = (0 ..< n).map { cos(Double.pi * Double(k) * (Double($0) + 0.5) / Double(n)) }
            let length = y.map { $0 * $0 }.reduce(0, +).squareRoot()
            y = y.map { $0 / length }
            for v in 0 ..< n { #expect(abs(x[v] - y[v]) < 1e-5, "x\(k)[\(v)]") }
            // ‖Lx − λx‖ relative to λ itself, which the inverse-iteration step after shift-invert
            // gives (a Ritz vector of L⁺ alone carries errors along L's large eigenvalues).
            let lx = graph.laplacianMatrix() * x
            var residual = 0.0
            for v in 0 ..< n { residual += (lx[v] - pairs.eigenvalues[k] * x[v]) * (lx[v] - pairs.eigenvalues[k] * x[v]) }
            #expect(residual.squareRoot() <= 1e-6 * pairs.eigenvalues[k], "residual \(k): \(residual.squareRoot())")
        }
        // A loose tolerance: the inverse-iteration step still brings ‖Lx − λx‖ within it.
        let loose = try graph.laplacianEigenpairs(smallest: 4, tolerance: 1e-4)
        for k in 1 ..< 4 {
            let x = loose.eigenvector(at: k)
            let lx = graph.laplacianMatrix() * x
            var residual = 0.0
            for v in 0 ..< n { residual += (lx[v] - loose.eigenvalues[k] * x[v]) * (lx[v] - loose.eigenvalues[k] * x[v]) }
            #expect(residual.squareRoot() <= 1e-4 * loose.eigenvalues[k], "loose residual \(k): \(residual.squareRoot())")
        }
        let normalized = try graph.normalizedLaplacianEigenpairs(smallest: 3)
        let spectrum = try graph.normalizedLaplacianSpectrum()
        for k in 0 ..< 3 {
            let exact = 1 - cos(Double.pi * Double(k) / Double(n - 1))
            #expect(abs(normalized.eigenvalues[k] - exact) <= 1e-7 * max(exact, 1e-9), "N λ\(k): \(normalized.eigenvalues[k]), exact \(exact), dense \(spectrum[k])")
        }
    }

    @Test("The 10 × 10 grid by Lanczos: A's largest are 2cos(πi/11) + 2cos(πj/11), with multiplicity")
    func gridAdjacency() throws {
        let side = 10
        var edges: [UndirectedEdge<Int>] = []
        for r in 0 ..< side {
            for c in 0 ..< side {
                if c + 1 < side { edges.append(UndirectedEdge(r * side + c, r * side + c + 1)) }
                if r + 1 < side { edges.append(UndirectedEdge(r * side + c, (r + 1) * side + c)) }
            }
        }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< side * side, edges: edges)
        var all: [Double] = []
        for i in 1 ... side { for j in 1 ... side { all.append(2 * cos(Double.pi * Double(i) / 11) + 2 * cos(Double.pi * Double(j) / 11)) } }
        all.sort(by: >)
        let pairs = try graph.adjacencyEigenpairs(largest: 6)
        for i in 0 ..< 6 { #expect(abs(pairs.eigenvalues[i] - all[i]) < 1e-7, "λ\(i)") }
        let smallest = try graph.adjacencyEigenpairs(smallest: 3)
        for i in 0 ..< 3 { #expect(abs(smallest.eigenvalues[i] + all[i]) < 1e-7, "μ\(i)") }
        let laplacian = try graph.laplacianEigenpairs(largest: 3)
        let spectrum = try graph.laplacianSpectrum()
        for i in 0 ..< 3 { #expect(abs(laplacian.eigenvalues[i] - spectrum[spectrum.count - 1 - i]) < 1e-7) }
        let signless = try graph.signlessLaplacianEigenpairs(smallest: 2)
        // The grid is bipartite, so Q and L are similar: Q's smallest is 0, then λ₂ of L.
        #expect(abs(signless.eigenvalues[0]) < 1e-6 && abs(signless.eigenvalues[1] - spectrum[1]) < 1e-6)
    }

    @Test("K₁₀₀: A's 3 largest are 99, −1, −1, though the Krylov space of one vector has dimension 2")
    func completeLocking() throws {
        let n = 100
        var edges: [UndirectedEdge<Int>] = []
        for u in 0 ..< n { for v in u + 1 ..< n { edges.append(UndirectedEdge(u, v)) } }
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        let pairs = try graph.adjacencyEigenpairs(largest: 3)
        #expect(abs(pairs.eigenvalues[0] - 99) < 1e-9 && abs(pairs.eigenvalues[1] + 1) < 1e-9 && abs(pairs.eigenvalues[2] + 1) < 1e-9)
        for i in 0 ..< 3 {
            for j in 0 ..< i { #expect(abs(zip(pairs.eigenvector(at: i), pairs.eigenvector(at: j)).map(*).reduce(0, +)) < 1e-9) }
        }
        let laplacian = try graph.laplacianEigenpairs(smallest: 3)
        #expect(laplacian.eigenvalues[0] == 0 && abs(laplacian.eigenvalues[1] - 100) < 1e-6 && abs(laplacian.eigenvalues[2] - 100) < 1e-6)
    }

    @Test("Seeded random graphs of 70 to 200 vertices: every end of every matrix agrees with the dense spectrum")
    func againstDense() throws {
        for (n, seed) in [(70, 1), (120, 2), (200, 3)] {
            var state = UInt64(seed)
            func next() -> UInt64 {
                state = state &* 6364136223846793005 &+ 1442695040888963407
                return state >> 33
            }
            var edges: [UndirectedEdge<Int>] = []
            for v in 1 ..< n { edges.append(UndirectedEdge(v, Int(next() % UInt64(v)))) }
            for _ in 0 ..< 2 * n { edges.append(UndirectedEdge(Int(next() % UInt64(n)), Int(next() % UInt64(n)))) }
            let weights = edges.indices.map { _ in Double(1 + next() % 9) }
            let graph = Pseudograph(vertices: 0 ..< n, edges: edges)
            let k = 4
            let a = try graph.adjacencySpectrum(weight: { weights[$0] })
            let l = try graph.laplacianSpectrum(weight: { weights[$0] })
            let nl = try graph.normalizedLaplacianSpectrum(weight: { weights[$0] })
            let pairs: [(Eigenpairs<Pseudograph<Int>>, [Double], String)] = [
                (try graph.adjacencyEigenpairs(largest: k, weight: { weights[$0] }), Array(a.reversed().prefix(k)), "A largest"),
                (try graph.adjacencyEigenpairs(smallest: k, weight: { weights[$0] }), Array(a.prefix(k)), "A smallest"),
                (try graph.laplacianEigenpairs(largest: k, weight: { weights[$0] }), Array(l.reversed().prefix(k)), "L largest"),
                (try graph.laplacianEigenpairs(smallest: k, weight: { weights[$0] }), Array(l.prefix(k)), "L smallest"),
                (try graph.normalizedLaplacianEigenpairs(largest: k, weight: { weights[$0] }), Array(nl.reversed().prefix(k)), "N largest"),
                (try graph.normalizedLaplacianEigenpairs(smallest: k, weight: { weights[$0] }), Array(nl.prefix(k)), "N smallest"),
            ]
            for (found, expected, name) in pairs {
                let scale = max(abs(expected[0]), 1)
                for i in 0 ..< k { #expect(abs(found.eigenvalues[i] - expected[i]) <= 1e-6 * scale, "\(name) λ\(i), n \(n)") }
            }
        }
    }

    @Test("Weights near Double's limits: L, A and Q scale with them, N and the vectors do not")
    func extremeWeights() throws {
        for n in [6, 70] {
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) } + [UndirectedEdge(0, n / 2)])
            for c in [1e300, 1e-300] {
                let plain = try graph.laplacianEigenpairs(smallest: 3)
                let scaled = try graph.laplacianEigenpairs(smallest: 3, weight: { _ in c })
                let normalized = try graph.normalizedLaplacianEigenpairs(largest: 2)
                let normalizedScaled = try graph.normalizedLaplacianEigenpairs(largest: 2, weight: { _ in c })
                let adjacency = try graph.adjacencyEigenpairs(largest: 2)
                let adjacencyScaled = try graph.adjacencyEigenpairs(largest: 2, weight: { _ in c })
                let signless = try graph.signlessLaplacianEigenpairs(smallest: 2)
                let signlessScaled = try graph.signlessLaplacianEigenpairs(smallest: 2, weight: { _ in c })
                for i in 0 ..< 3 { #expect(abs(scaled.eigenvalues[i] - c * plain.eigenvalues[i]) <= 1e-9 * c * max(plain.eigenvalues[i], 1e-9), "L λ\(i), n \(n), c \(c)") }
                for i in 0 ..< 2 {
                    #expect(abs(normalizedScaled.eigenvalues[i] - normalized.eigenvalues[i]) <= 1e-9, "N λ\(i), n \(n), c \(c)")
                    #expect(abs(adjacencyScaled.eigenvalues[i] - c * adjacency.eigenvalues[i]) <= 1e-9 * c * adjacency.eigenvalues[0], "A λ\(i), n \(n), c \(c)")
                    #expect(abs(signlessScaled.eigenvalues[i] - c * signless.eigenvalues[i]) <= 1e-7 * c * max(signless.eigenvalues[i], 1e-3), "Q λ\(i), n \(n), c \(c)")
                    #expect(zip(adjacencyScaled.eigenvector(at: i), adjacency.eigenvector(at: i)).allSatisfy { abs($0 - $1) < 1e-6 }, "A x\(i), n \(n), c \(c)")
                }
            }
        }
    }

    @Test("The weight overloads read each position once and agree across BinaryInteger and BinaryFloatingPoint")
    func weightOverloads() throws {
        let n = 80
        let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n).map { UndirectedEdge($0, ($0 * 7 + 3) % n) } + (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        var reads = [Int](repeating: 0, count: graph.edgeCount)
        let integer = try graph.laplacianEigenpairs(smallest: 3, weight: { (p: Int) -> Int in
            reads[p] += 1
            return p % 3 + 1
        })
        #expect(reads.allSatisfy { $0 == 1 })
        let floating = try graph.laplacianEigenpairs(smallest: 3, weight: { Double($0 % 3 + 1) })
        #expect(integer.eigenvalues == floating.eigenvalues)
        let float = try graph.adjacencyEigenpairs(largest: 2, weight: { Float($0 % 3 + 1) })
        let double = try graph.adjacencyEigenpairs(largest: 2, weight: { Double($0 % 3 + 1) })
        #expect(float.eigenvalues == double.eigenvalues)
    }

    @Test("Representations: UndirectedAdjacencyList, Pseudograph, AdjacencyList.undirectedView and a graph without indices agree")
    func representations() throws {
        let pairs = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (3, 4)]
        let list = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let pseudo = Pseudograph(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let directed = AdjacencyList(vertices: 0 ..< 5, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let unindexed = UnindexedGraph(vertices: ["a", "b", "c", "d", "e"], edges: pairs.map { UndirectedEdge(["a", "b", "c", "d", "e"][$0.0], ["a", "b", "c", "d", "e"][$0.1]) })
        let reference = try list.normalizedLaplacianEigenpairs(smallest: 3)
        let others = [try pseudo.normalizedLaplacianEigenpairs(smallest: 3).eigenvalues, try directed.undirectedView.normalizedLaplacianEigenpairs(smallest: 3).eigenvalues, try unindexed.normalizedLaplacianEigenpairs(smallest: 3).eigenvalues]
        for values in others { #expect(zip(values, reference.eigenvalues).allSatisfy { abs($0 - $1) < 1e-12 }) }
        let named = try unindexed.normalizedLaplacianEigenpairs(smallest: 3)
        for (i, name) in ["a", "b", "c", "d", "e"].enumerated() {
            #expect(zip(named.eigenvectorEntries(of: name), reference.eigenvectorEntries(of: i)).allSatisfy { abs($0 - $1) < 1e-12 })
        }
    }

    @Test("eigenvectorEntries(checked:) agrees with the plain lookup and throws off the graph")
    func checkedLookup() throws {
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let pairs = try graph.laplacianEigenpairs(smallest: 2)
        for v in 0 ..< 4 { #expect(try pairs.eigenvectorEntries(checked: v) == pairs.eigenvectorEntries(of: v)) }
        #expect(throws: VertexNotFound.self) { try pairs.eigenvectorEntries(checked: 4) }
        let unindexed = UnindexedGraph(vertices: ["x", "y"], edges: [UndirectedEdge("x", "y")])
        let named = try unindexed.adjacencyEigenpairs(largest: 2)
        #expect(try named.eigenvectorEntries(checked: "y") == named.eigenvectorEntries(of: "y"))
        #expect(throws: VertexNotFound.self) { try named.eigenvectorEntries(checked: "z") }
    }

    @Test("maxIterations: 1 throws NoConvergence on the Lanczos paths; the dense path does not read it")
    func iterationLimits() throws {
        let n = 200
        let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        #expect(throws: NoConvergence.self) { try path.adjacencyEigenpairs(largest: 2, maxIterations: 1) }
        #expect(throws: NoConvergence.self) { try path.laplacianEigenpairs(smallest: 3, maxIterations: 1) }
        #expect(throws: NoConvergence.self) { try path.signlessLaplacianEigenpairs(largest: 2, maxIterations: 1) }
        do throws(NoConvergence) {
            _ = try path.laplacianEigenpairs(largest: 2, maxIterations: 3)
            Issue.record("No NoConvergence")
        } catch {
            #expect(error.iterations >= 3 && error.residual > 1e-8)
        }
        let small = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: (0 ..< 9).map { UndirectedEdge($0, $0 + 1) })
        #expect(try small.laplacianEigenpairs(smallest: 3, maxIterations: 1).count == 3)
        // A larger limit answers as the default does.
        let a = try path.laplacianEigenpairs(smallest: 3)
        let b = try path.laplacianEigenpairs(smallest: 3, maxIterations: 1_000_000)
        #expect(a.eigenvalues == b.eigenvalues)
    }
}
