// The exact spanning-tree count against closed forms over whole families, up to and past the point
// where the count stops fitting in `UInt128`: Cayley's n^(n−2) for K_n, Scoins' m^(n−1) n^(m−1)
// for K_{m,n}, n for the cycle C_n, the ladder P₂ × P_n (a(n) = 4a(n−1) − a(n−2)), the wheel W_n
// (L(2n) − 2, Lucas numbers) and the product of the weights on a weighted path.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory exact spanning tree counts against closed forms")
struct ExactSpanningTreeFormulaTests {
    @Test("K_n has n^(n−2) spanning trees, exactly through K₂₈, nil from K₂₉")
    func cayley() {
        for n in 1 ... 40 {
            var edges: [UndirectedEdge<Int>] = []
            for u in 0 ..< n {
                for v in u + 1 ..< n { edges.append(UndirectedEdge(u, v)) }
            }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            var expected: UInt128? = 1
            for _ in 0 ..< max(n - 2, 0) {
                guard let e = expected else { break }
                let (product, overflow) = e.multipliedReportingOverflow(by: UInt128(n))
                expected = overflow ? nil : product
            }
            #expect(graph.numberOfSpanningTrees(as: UInt128.self) == expected, "K\(n)")
            #expect((expected == nil) == (n >= 29), "K\(n)")
        }
    }

    @Test("K_{m,n} has m^(n−1) n^(m−1) spanning trees, nil exactly when that is 2¹²⁸ or more")
    func completeBipartite() {
        var fitting = 0, overflowing = 0
        for (m, n) in [(1, 1), (1, 7), (2, 2), (2, 118), (2, 119), (2, 120), (2, 121), (2, 122), (2, 123), (3, 70), (3, 73), (3, 74), (4, 56), (4, 57),
                       (5, 5), (6, 40), (6, 41), (8, 31), (8, 32), (8, 33), (9, 29), (12, 23), (14, 20)] {
            var edges: [UndirectedEdge<Int>] = []
            for u in 0 ..< m {
                for v in m ..< m + n { edges.append(UndirectedEdge(u, v)) }
            }
            let graph = ReferencePseudograph(vertices: Array(0 ..< m + n), edges: edges)
            var expected: UInt128? = 1
            for (base, power) in [(m, n - 1), (n, m - 1)] {
                for _ in 0 ..< power {
                    guard let e = expected else { break }
                    let (product, overflow) = e.multipliedReportingOverflow(by: UInt128(base))
                    expected = overflow ? nil : product
                }
            }
            if expected == nil { overflowing += 1 } else { fitting += 1 }
            #expect(graph.numberOfSpanningTrees(as: UInt128.self) == expected, "K\(m),\(n)")
        }
        #expect(fitting > 0 && overflowing > 0)
    }

    @Test("C_n has n spanning trees, and doubling every edge of C_n gives n 2^(n−1)")
    func cycles() {
        for n in 3 ... 120 {
            let edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) }
            let graph = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges)
            #expect(graph.numberOfSpanningTrees(as: UInt128.self) == UInt128(n), "C\(n)")
            let doubled = ReferencePseudograph(vertices: Array(0 ..< n), edges: edges + edges)
            var expected: UInt128? = nil
            if n - 1 < 128 {
                let (product, overflow) = UInt128(n).multipliedReportingOverflow(by: UInt128(1) << (n - 1))
                if !overflow { expected = product }
            }
            #expect(doubled.numberOfSpanningTrees(as: UInt128.self) == expected, "doubled C\(n)")
        }
    }

    @Test("The ladder P₂ × P_n follows a(n) = 4 a(n − 1) − a(n − 2), from a(1) = 1, a(2) = 4, until 2¹²⁸")
    func ladders() {
        var previous: UInt128 = 0, current: UInt128 = 1
        var n = 1
        var reachedNil = false
        while n <= 70 {
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< n {
                edges.append(UndirectedEdge(2 * i, 2 * i + 1))
                if i + 1 < n {
                    edges.append(UndirectedEdge(2 * i, 2 * i + 2))
                    edges.append(UndirectedEdge(2 * i + 1, 2 * i + 3))
                }
            }
            let graph = ReferencePseudograph(vertices: Array(0 ..< 2 * n), edges: edges)
            let count = graph.numberOfSpanningTrees(as: UInt128.self)
            if reachedNil {
                #expect(count == nil, "ladder \(n)")
            } else {
                #expect(count == current, "ladder \(n)")
            }
            let (times4, overflow) = current.multipliedReportingOverflow(by: 4)
            if overflow || reachedNil {
                reachedNil = true
            } else {
                (previous, current) = (current, times4 - previous)
            }
            n += 1
        }
        #expect(reachedNil)
    }

    @Test("The wheel W_n (a hub and C_n) has L(2n) − 2 spanning trees, Lucas numbers")
    func wheels() {
        // Lucas numbers L(k) for k up to 2 · 90.
        var lucas: [UInt128] = [2, 1]
        while lucas.count <= 180 { lucas.append(lucas[lucas.count - 1] + lucas[lucas.count - 2]) }
        for n in 3 ... 90 {
            var edges = (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) }
            for v in 0 ..< n { edges.append(UndirectedEdge(n, v)) }
            let graph = ReferencePseudograph(vertices: Array(0 ... n), edges: edges)
            #expect(graph.numberOfSpanningTrees(as: UInt128.self) == lucas[2 * n] - 2, "W\(n)")
        }
    }

    @Test("Weights wider than 64 bits are reduced exactly: UInt128 weights on a path and a triangle")
    func wideWeights() {
        let big = (UInt128(1) << 100) + 7, other = (UInt128(1) << 64) + 1
        let edge = ReferencePseudograph(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
        #expect(edge.numberOfSpanningTrees(as: UInt128.self, weight: { _ in big }) == big)
        let path = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let pathWeights = [other, (UInt128(1) << 63) - 1]
        #expect(path.numberOfSpanningTrees(as: UInt128.self, weight: { pathWeights[$0] }) == other * ((UInt128(1) << 63) - 1))
        // A triangle: ab + bc + ca.
        let triangle = ReferencePseudograph(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)])
        let weights: [Int128] = [Int128(1) << 70, (Int128(1) << 40) + 3, 5]
        let expected = UInt128(weights[0] * weights[1] + weights[1] * weights[2] + weights[2] * weights[0])
        #expect(triangle.numberOfSpanningTrees(as: UInt128.self, weight: { weights[$0] }) == expected)
        // 2⁶⁴ · 2⁶⁴ = 2¹²⁸: nil.
        let square = [Int128(1) << 64, Int128(1) << 64]
        #expect(path.numberOfSpanningTrees(as: UInt128.self, weight: { square[$0] }) == nil)
    }

    @Test("A path's count is the product of its weights, nil once it reaches 2¹²⁸")
    func weightedPaths() {
        for weight in [UInt64(1) << 31, (UInt64(1) << 32) - 1, UInt64(1) << 32, (UInt64(1) << 32) + 1, UInt64.max] {
            for length in 1 ... 5 {
                let edges = (0 ..< length).map { UndirectedEdge($0, $0 + 1) }
                let graph = ReferencePseudograph(vertices: Array(0 ... length), edges: edges)
                var expected: UInt128? = 1
                for _ in 0 ..< length {
                    guard let e = expected else { break }
                    let (product, overflow) = e.multipliedReportingOverflow(by: UInt128(weight))
                    expected = overflow ? nil : product
                }
                #expect(graph.numberOfSpanningTrees(as: UInt128.self, weight: { _ in weight }) == expected, "\(length) edges of weight \(weight)")
            }
        }
    }
}
