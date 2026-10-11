// Statistical laws (catalog rows with seeds 0..<S): the exact aggregate of the pinned procedure over
// the seeds on every conformer of the row's kind, then the law with api.md's tolerance.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing
import Trees

@Suite("RandomGraphs statistical laws")
struct StatisticalLawTests {
    @Test("RG-026 law: E[m] = p·C(n, 2)")
    func rg026() {
        // G(100, 0.05) undirected → Σ 49295 over seeds 0..<200 (mean 246.4750; expected 247.5000; |z| 0.95 ≤ 4)
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 49295, "UndirectedAdjacencyList<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 49295, "Pseudograph<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 49295, "Multigraph<Int>")
        }
        // The law: |z| ≤ 4 against E[m] = 4950·0.05 per seed.
        let mean = Double(49295) / 200
        let z = (mean - 4950 * 0.05) / (4950 * 0.05 * (1 - 0.05) / 200).squareRoot()
        #expect(abs(z) <= 4)
    }

    @Test("RG-027 law: E[m] = p·n(n − 1)")
    func rg027() {
        // G(100, 0.05) directed → Σ 99021 over seeds 0..<200 (mean 495.1050; expected 495.0000; |z| 0.07 ≤ 4)
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = CompressedSparseRow.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 99021, "CompressedSparseRow")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = AdjacencyMatrix.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 99021, "AdjacencyMatrix")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = AdjacencyList<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 99021, "AdjacencyList<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedPseudograph<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 99021, "DirectedPseudograph<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedMultigraph<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 99021, "DirectedMultigraph<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = StableDirectedGraph<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                total += graph.edgeCount
            }
            #expect(total == 99021, "StableDirectedGraph<Int>")
        }
        // The law: |z| ≤ 4 against E[m] = 9900·0.05 per seed.
        let mean = Double(99021) / 200
        let z = (mean - 9900 * 0.05) / (9900 * 0.05 * (1 - 0.05) / 200).squareRoot()
        #expect(abs(z) <= 4)
    }

    @Test("RG-028 law: degree variance (n − 1)p(1 − p)")
    func rg028() {
        // G(100, 0.05), degrees pooled over seeds 0..<200 → variance 4.6802; expected 4.7025; within 5%
        do {
            var degrees: [Int] = []
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                degrees += (0 ..< 100).map { graph.degree(of: $0) }
            }
            #expect(degrees.reduce(0, +) == 98590, "UndirectedAdjacencyList<Int>")
            let mean = Double(degrees.reduce(0, +)) / Double(degrees.count)
            let variance = degrees.reduce(0.0) { $0 + (Double($1) - mean) * (Double($1) - mean) } / Double(degrees.count - 1)
            #expect(abs(variance - 4.6802) <= 0.00005, "UndirectedAdjacencyList<Int>: \(variance)")
            // The law: within 5 % of (n − 1)p(1 − p).
            #expect(abs(variance - 99 * 0.05 * 0.95) / (99 * 0.05 * 0.95) < 0.05, "UndirectedAdjacencyList<Int>")
        }
        do {
            var degrees: [Int] = []
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                degrees += (0 ..< 100).map { graph.degree(of: $0) }
            }
            #expect(degrees.reduce(0, +) == 98590, "Pseudograph<Int>")
            let mean = Double(degrees.reduce(0, +)) / Double(degrees.count)
            let variance = degrees.reduce(0.0) { $0 + (Double($1) - mean) * (Double($1) - mean) } / Double(degrees.count - 1)
            #expect(abs(variance - 4.6802) <= 0.00005, "Pseudograph<Int>: \(variance)")
            // The law: within 5 % of (n − 1)p(1 − p).
            #expect(abs(variance - 99 * 0.05 * 0.95) / (99 * 0.05 * 0.95) < 0.05, "Pseudograph<Int>")
        }
        do {
            var degrees: [Int] = []
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)
                degrees += (0 ..< 100).map { graph.degree(of: $0) }
            }
            #expect(degrees.reduce(0, +) == 98590, "Multigraph<Int>")
            let mean = Double(degrees.reduce(0, +)) / Double(degrees.count)
            let variance = degrees.reduce(0.0) { $0 + (Double($1) - mean) * (Double($1) - mean) } / Double(degrees.count - 1)
            #expect(abs(variance - 4.6802) <= 0.00005, "Multigraph<Int>: \(variance)")
            // The law: within 5 % of (n − 1)p(1 − p).
            #expect(abs(variance - 99 * 0.05 * 0.95) / (99 * 0.05 * 0.95) < 0.05, "Multigraph<Int>")
        }
    }

    @Test("RG-029 law: each labeled graph on 3 vertices with probability p^m (1 − p)^(3 − m)")
    func rg029() {
        // G(3, 0.3) undirected → 8 outcomes over seeds 0..<4000; χ² 6.85 ≤ 24.322 (df 7, 0.999)
        // Every outcome's count over the seeds, from the model.
        let expected: [[[Int]]: Int] = [[]: 1388, [[0, 1]]: 554, [[0, 1], [0, 2]]: 257, [[0, 1], [0, 2], [1, 2]]: 123, [[0, 1], [1, 2]]: 264, [[0, 2]]: 606, [[0, 2], [1, 2]]: 248, [[1, 2]]: 560]
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(4000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 3, edgeProbability: 0.3, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "UndirectedAdjacencyList<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(4000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.erdosRenyi(vertexCount: 3, edgeProbability: 0.3, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "Pseudograph<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(4000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.erdosRenyi(vertexCount: 3, edgeProbability: 0.3, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "Multigraph<Int>")
        }
        // The law: χ² over the 8 outcomes, each with its probability, below the 0.999 quantile.
        let probabilities: [[[Int]]: Double] = [[]: 0.3429999999999999, [[0, 1]]: 0.14699999999999996, [[0, 1], [0, 2]]: 0.063, [[0, 1], [0, 2], [1, 2]]: 0.026999999999999996, [[0, 1], [1, 2]]: 0.063, [[0, 2]]: 0.14699999999999996, [[0, 2], [1, 2]]: 0.063, [[1, 2]]: 0.14699999999999996]
        let chiSquare = probabilities.reduce(0.0) { sum, outcome in
            let observed = Double(expected[outcome.key] ?? 0), predicted = 4000 * outcome.value
            return sum + (observed - predicted) * (observed - predicted) / predicted
        }
        #expect(abs(chiSquare - 6.85) <= 0.005 && chiSquare <= 24.322, "\(chiSquare)")
    }

    @Test("RG-044 law: uniform over the C(N, m) graphs")
    func rg044() {
        // G(4, 3) undirected → 20 outcomes over seeds 0..<4000; χ² 18.25 ≤ 43.82 (df 19, 0.999)
        // Every outcome's count over the seeds, from the model.
        let expected: [[[Int]]: Int] = [[[0, 1], [0, 2], [0, 3]]: 219, [[0, 1], [0, 2], [1, 2]]: 225, [[0, 1], [0, 2], [1, 3]]: 202, [[0, 1], [0, 2], [2, 3]]: 204, [[0, 1], [0, 3], [1, 2]]: 202, [[0, 1], [0, 3], [1, 3]]: 211, [[0, 1], [0, 3], [2, 3]]: 187, [[0, 1], [1, 2], [1, 3]]: 192, [[0, 1], [1, 2], [2, 3]]: 189, [[0, 1], [1, 3], [2, 3]]: 192, [[0, 2], [0, 3], [1, 2]]: 190, [[0, 2], [0, 3], [1, 3]]: 205, [[0, 2], [0, 3], [2, 3]]: 194, [[0, 2], [1, 2], [1, 3]]: 181, [[0, 2], [1, 2], [2, 3]]: 196, [[0, 2], [1, 3], [2, 3]]: 184, [[0, 3], [1, 2], [1, 3]]: 179, [[0, 3], [1, 2], [2, 3]]: 208, [[0, 3], [1, 3], [2, 3]]: 219, [[1, 2], [1, 3], [2, 3]]: 221]
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(4000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 4, edgeCount: 3, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "UndirectedAdjacencyList<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(4000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.erdosRenyi(vertexCount: 4, edgeCount: 3, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "Pseudograph<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(4000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.erdosRenyi(vertexCount: 4, edgeCount: 3, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "Multigraph<Int>")
        }
        // The law: χ² over the 20 outcomes, each with its probability, below the 0.999 quantile.
        let probabilities: [[[Int]]: Double] = [[[0, 1], [0, 2], [0, 3]]: 0.05, [[0, 1], [0, 2], [1, 2]]: 0.05, [[0, 1], [0, 2], [1, 3]]: 0.05, [[0, 1], [0, 2], [2, 3]]: 0.05, [[0, 1], [0, 3], [1, 2]]: 0.05, [[0, 1], [0, 3], [1, 3]]: 0.05, [[0, 1], [0, 3], [2, 3]]: 0.05, [[0, 1], [1, 2], [1, 3]]: 0.05, [[0, 1], [1, 2], [2, 3]]: 0.05, [[0, 1], [1, 3], [2, 3]]: 0.05, [[0, 2], [0, 3], [1, 2]]: 0.05, [[0, 2], [0, 3], [1, 3]]: 0.05, [[0, 2], [0, 3], [2, 3]]: 0.05, [[0, 2], [1, 2], [1, 3]]: 0.05, [[0, 2], [1, 2], [2, 3]]: 0.05, [[0, 2], [1, 3], [2, 3]]: 0.05, [[0, 3], [1, 2], [1, 3]]: 0.05, [[0, 3], [1, 2], [2, 3]]: 0.05, [[0, 3], [1, 3], [2, 3]]: 0.05, [[1, 2], [1, 3], [2, 3]]: 0.05]
        let chiSquare = probabilities.reduce(0.0) { sum, outcome in
            let observed = Double(expected[outcome.key] ?? 0), predicted = 4000 * outcome.value
            return sum + (observed - predicted) * (observed - predicted) / predicted
        }
        #expect(abs(chiSquare - 18.25) <= 0.005 && chiSquare <= 43.82, "\(chiSquare)")
    }

    @Test("RG-045 law: uniform over the C(N, m) graphs (complement branch)")
    func rg045() {
        // G(4, 5) undirected → 6 outcomes over seeds 0..<1200; χ² 4.98 ≤ 20.515 (df 5, 0.999)
        // Every outcome's count over the seeds, from the model.
        let expected: [[[Int]]: Int] = [[[0, 1], [0, 2], [0, 3], [1, 2], [1, 3]]: 203, [[0, 1], [0, 2], [0, 3], [1, 2], [2, 3]]: 175, [[0, 1], [0, 2], [0, 3], [1, 3], [2, 3]]: 205, [[0, 1], [0, 2], [1, 2], [1, 3], [2, 3]]: 212, [[0, 1], [0, 3], [1, 2], [1, 3], [2, 3]]: 193, [[0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]: 212]
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(1200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 4, edgeCount: 5, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "UndirectedAdjacencyList<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(1200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.erdosRenyi(vertexCount: 4, edgeCount: 5, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "Pseudograph<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(1200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.erdosRenyi(vertexCount: 4, edgeCount: 5, using: &generator)
                let key = graph.edges.map { [$0.u, $0.v] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "Multigraph<Int>")
        }
        // The law: χ² over the 6 outcomes, each with its probability, below the 0.999 quantile.
        let probabilities: [[[Int]]: Double] = [[[0, 1], [0, 2], [0, 3], [1, 2], [1, 3]]: 0.16666666666666666, [[0, 1], [0, 2], [0, 3], [1, 2], [2, 3]]: 0.16666666666666666, [[0, 1], [0, 2], [0, 3], [1, 3], [2, 3]]: 0.16666666666666666, [[0, 1], [0, 2], [1, 2], [1, 3], [2, 3]]: 0.16666666666666666, [[0, 1], [0, 3], [1, 2], [1, 3], [2, 3]]: 0.16666666666666666, [[0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]: 0.16666666666666666]
        let chiSquare = probabilities.reduce(0.0) { sum, outcome in
            let observed = Double(expected[outcome.key] ?? 0), predicted = 1200 * outcome.value
            return sum + (observed - predicted) * (observed - predicted) / predicted
        }
        #expect(abs(chiSquare - 4.98) <= 0.005 && chiSquare <= 20.515, "\(chiSquare)")
    }

    @Test("RG-046 law: uniform over the C(N, m) graphs")
    func rg046() {
        // G(3, 2) directed → 15 outcomes over seeds 0..<3000; χ² 12.76 ≤ 36.123 (df 14, 0.999)
        // Every outcome's count over the seeds, from the model.
        let expected: [[[Int]]: Int] = [[[0, 1], [0, 2]]: 220, [[0, 1], [1, 0]]: 196, [[0, 1], [1, 2]]: 196, [[0, 1], [2, 0]]: 178, [[0, 1], [2, 1]]: 191, [[0, 2], [1, 0]]: 194, [[0, 2], [1, 2]]: 214, [[0, 2], [2, 0]]: 193, [[0, 2], [2, 1]]: 208, [[1, 0], [1, 2]]: 214, [[1, 0], [2, 0]]: 180, [[1, 0], [2, 1]]: 190, [[1, 2], [2, 0]]: 197, [[1, 2], [2, 1]]: 208, [[2, 0], [2, 1]]: 221]
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(3000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = CompressedSparseRow.erdosRenyi(vertexCount: 3, edgeCount: 2, using: &generator)
                let key = graph.edges.map { [$0.source, $0.target] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "CompressedSparseRow")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(3000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = AdjacencyMatrix.erdosRenyi(vertexCount: 3, edgeCount: 2, using: &generator)
                let key = graph.edges.map { [$0.source, $0.target] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "AdjacencyMatrix")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(3000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = AdjacencyList<Int>.erdosRenyi(vertexCount: 3, edgeCount: 2, using: &generator)
                let key = graph.edges.map { [$0.source, $0.target] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "AdjacencyList<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(3000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedPseudograph<Int>.erdosRenyi(vertexCount: 3, edgeCount: 2, using: &generator)
                let key = graph.edges.map { [$0.source, $0.target] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "DirectedPseudograph<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(3000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedMultigraph<Int>.erdosRenyi(vertexCount: 3, edgeCount: 2, using: &generator)
                let key = graph.edges.map { [$0.source, $0.target] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "DirectedMultigraph<Int>")
        }
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(3000) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = StableDirectedGraph<Int>.erdosRenyi(vertexCount: 3, edgeCount: 2, using: &generator)
                let key = graph.edges.map { [$0.source, $0.target] }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "StableDirectedGraph<Int>")
        }
        // The law: χ² over the 15 outcomes, each with its probability, below the 0.999 quantile.
        let probabilities: [[[Int]]: Double] = [[[0, 1], [0, 2]]: 0.06666666666666667, [[0, 1], [1, 0]]: 0.06666666666666667, [[0, 1], [1, 2]]: 0.06666666666666667, [[0, 1], [2, 0]]: 0.06666666666666667, [[0, 1], [2, 1]]: 0.06666666666666667, [[0, 2], [1, 0]]: 0.06666666666666667, [[0, 2], [1, 2]]: 0.06666666666666667, [[0, 2], [2, 0]]: 0.06666666666666667, [[0, 2], [2, 1]]: 0.06666666666666667, [[1, 0], [1, 2]]: 0.06666666666666667, [[1, 0], [2, 0]]: 0.06666666666666667, [[1, 0], [2, 1]]: 0.06666666666666667, [[1, 2], [2, 0]]: 0.06666666666666667, [[1, 2], [2, 1]]: 0.06666666666666667, [[2, 0], [2, 1]]: 0.06666666666666667]
        let chiSquare = probabilities.reduce(0.0) { sum, outcome in
            let observed = Double(expected[outcome.key] ?? 0), predicted = 3000 * outcome.value
            return sum + (observed - predicted) * (observed - predicted) / predicted
        }
        #expect(abs(chiSquare - 12.76) <= 0.005 && chiSquare <= 36.123, "\(chiSquare)")
    }

    @Test("RG-058 laws: m(n − m) edges, degree sum 2m(n − m), every new vertex has degree ≥ m")
    func rg058() {
        // n 1000, m 2, seeds 0..<50 → hold for every seed
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "UndirectedAdjacencyList<Int> seed \(seed)")
                #expect((0 ..< 1000).map { graph.degree(of: $0) }.reduce(0, +) == 3992, "UndirectedAdjacencyList<Int> seed \(seed)")
                #expect((3 ..< 1000).allSatisfy { graph.degree(of: $0) >= 2 }, "UndirectedAdjacencyList<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.u < $0.v }, "UndirectedAdjacencyList<Int> seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "Pseudograph<Int> seed \(seed)")
                #expect((0 ..< 1000).map { graph.degree(of: $0) }.reduce(0, +) == 3992, "Pseudograph<Int> seed \(seed)")
                #expect((3 ..< 1000).allSatisfy { graph.degree(of: $0) >= 2 }, "Pseudograph<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.u < $0.v }, "Pseudograph<Int> seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "Multigraph<Int> seed \(seed)")
                #expect((0 ..< 1000).map { graph.degree(of: $0) }.reduce(0, +) == 3992, "Multigraph<Int> seed \(seed)")
                #expect((3 ..< 1000).allSatisfy { graph.degree(of: $0) >= 2 }, "Multigraph<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.u < $0.v }, "Multigraph<Int> seed \(seed)")
            }
        }
        // Directed (new vertex → older vertex): the hub has no out-arc, 1…m one each, every later vertex m.
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "CompressedSparseRow seed \(seed)")
                #expect((0 ..< 1000).map { graph.outDegree(of: $0) } == [0] + Array(repeating: 1, count: 2) + Array(repeating: 2, count: 997), "CompressedSparseRow seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source > $0.target }, "CompressedSparseRow seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = AdjacencyMatrix.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "AdjacencyMatrix seed \(seed)")
                #expect((0 ..< 1000).map { graph.outDegree(of: $0) } == [0] + Array(repeating: 1, count: 2) + Array(repeating: 2, count: 997), "AdjacencyMatrix seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source > $0.target }, "AdjacencyMatrix seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = AdjacencyList<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "AdjacencyList<Int> seed \(seed)")
                #expect((0 ..< 1000).map { graph.outDegree(of: $0) } == [0] + Array(repeating: 1, count: 2) + Array(repeating: 2, count: 997), "AdjacencyList<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source > $0.target }, "AdjacencyList<Int> seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedPseudograph<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "DirectedPseudograph<Int> seed \(seed)")
                #expect((0 ..< 1000).map { graph.outDegree(of: $0) } == [0] + Array(repeating: 1, count: 2) + Array(repeating: 2, count: 997), "DirectedPseudograph<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source > $0.target }, "DirectedPseudograph<Int> seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedMultigraph<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "DirectedMultigraph<Int> seed \(seed)")
                #expect((0 ..< 1000).map { graph.outDegree(of: $0) } == [0] + Array(repeating: 1, count: 2) + Array(repeating: 2, count: 997), "DirectedMultigraph<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source > $0.target }, "DirectedMultigraph<Int> seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = StableDirectedGraph<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                #expect(graph.edgeCount == 1996, "StableDirectedGraph<Int> seed \(seed)")
                #expect((0 ..< 1000).map { graph.outDegree(of: $0) } == [0] + Array(repeating: 1, count: 2) + Array(repeating: 2, count: 997), "StableDirectedGraph<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source > $0.target }, "StableDirectedGraph<Int> seed \(seed)")
            }
        }
    }

    @Test("RG-059 law: share of degree-m vertices → 2/(m + 2) (Bollobás et al. 2001)")
    func rg059() {
        // n 1000, m 2, pooled over seeds 0..<50 → 24936 of 50000 (0.4987); expected 0.5000 ± 0.02
        do {
            var lowDegree = 0
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                lowDegree += (0 ..< 1000).filter { graph.degree(of: $0) == 2 }.count
            }
            #expect(lowDegree == 24936, "UndirectedAdjacencyList<Int>")
        }
        do {
            var lowDegree = 0
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                lowDegree += (0 ..< 1000).filter { graph.degree(of: $0) == 2 }.count
            }
            #expect(lowDegree == 24936, "Pseudograph<Int>")
        }
        do {
            var lowDegree = 0
            for seed in 0 ..< UInt64(50) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.barabasiAlbert(vertexCount: 1000, edgesPerVertex: 2, using: &generator)
                lowDegree += (0 ..< 1000).filter { graph.degree(of: $0) == 2 }.count
            }
            #expect(lowDegree == 24936, "Multigraph<Int>")
        }
        // The law: the share of degree-m vertices is 2/(m + 2) ± 0.02.
        #expect(abs(Double(24936) / 50000 - 2.0 / 4) < 0.02)
    }

    @Test("RG-072 laws: nk/2 edges for every p, every vertex keeps degree ≥ k/2")
    func rg072() {
        // n 200, k 6, p 0.2, seeds 0..<100 → hold for every seed
        do {
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 200, nearestNeighborCount: 6, rewiringProbability: 0.2, using: &generator)
                #expect(graph.edgeCount == 600, "UndirectedAdjacencyList<Int> seed \(seed)")
                #expect((0 ..< 200).allSatisfy { graph.degree(of: $0) >= 3 }, "UndirectedAdjacencyList<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.u < $0.v }, "UndirectedAdjacencyList<Int> seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 200, nearestNeighborCount: 6, rewiringProbability: 0.2, using: &generator)
                #expect(graph.edgeCount == 600, "Pseudograph<Int> seed \(seed)")
                #expect((0 ..< 200).allSatisfy { graph.degree(of: $0) >= 3 }, "Pseudograph<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.u < $0.v }, "Pseudograph<Int> seed \(seed)")
            }
        }
        do {
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 200, nearestNeighborCount: 6, rewiringProbability: 0.2, using: &generator)
                #expect(graph.edgeCount == 600, "Multigraph<Int> seed \(seed)")
                #expect((0 ..< 200).allSatisfy { graph.degree(of: $0) >= 3 }, "Multigraph<Int> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.u < $0.v }, "Multigraph<Int> seed \(seed)")
            }
        }
    }

    @Test("RG-073 law: share of ring edges gone ≈ p")
    func rg073() {
        // n 200, k 6, p 0.2, pooled over seeds 0..<100 → 12165 of 60000 (0.2028); expected 0.2 ± 0.01
        do {
            var gone = 0
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: 200, nearestNeighborCount: 6, rewiringProbability: 0.2, using: &generator)
                for u in 0 ..< 200 {
                    for j in 1 ... 3 where !graph.contains(edge: UndirectedEdge(u, (u + j) % 200)) { gone += 1 }
                }
            }
            #expect(gone == 12165, "UndirectedAdjacencyList<Int>")
        }
        do {
            var gone = 0
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Pseudograph<Int>.wattsStrogatz(vertexCount: 200, nearestNeighborCount: 6, rewiringProbability: 0.2, using: &generator)
                for u in 0 ..< 200 {
                    for j in 1 ... 3 where !graph.contains(edge: UndirectedEdge(u, (u + j) % 200)) { gone += 1 }
                }
            }
            #expect(gone == 12165, "Pseudograph<Int>")
        }
        do {
            var gone = 0
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Multigraph<Int>.wattsStrogatz(vertexCount: 200, nearestNeighborCount: 6, rewiringProbability: 0.2, using: &generator)
                for u in 0 ..< 200 {
                    for j in 1 ... 3 where !graph.contains(edge: UndirectedEdge(u, (u + j) % 200)) { gone += 1 }
                }
            }
            #expect(gone == 12165, "Multigraph<Int>")
        }
        // The law: the share of ring edges gone is p ± 0.01.
        #expect(abs(Double(12165) / 60000 - 0.2) < 0.01)
    }

    @Test("RG-083 law: E[m] = C(n, 2)(πr² − 8r³/3 + r⁴/2) in the unit square")
    func rg083() {
        // n 100, radius 0.1 → Σ 14142 over seeds 0..<100 (mean 141.4200; expected 142.5563; |z| 0.37 ≤ 4)
        do {
            var total = 0
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                total += UndirectedAdjacencyList<Int>.randomGeometric(vertexCount: 100, radius: 0.1, using: &generator).graph.edgeCount
            }
            #expect(total == 14142, "UndirectedAdjacencyList<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                total += Pseudograph<Int>.randomGeometric(vertexCount: 100, radius: 0.1, using: &generator).graph.edgeCount
            }
            #expect(total == 14142, "Pseudograph<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(100) {
                var generator = Xoshiro256StarStar(seed: seed)
                total += Multigraph<Int>.randomGeometric(vertexCount: 100, radius: 0.1, using: &generator).graph.edgeCount
            }
            #expect(total == 14142, "Multigraph<Int>")
        }
        // The law: |z| ≤ 4 against C(n, 2)(πr² − 8r³/3 + r⁴/2), with the variance bounded by pairs·q·(1 + 2(n − 2)q).
        let q = Double.pi * 0.01 - 8 * 0.001 / 3 + 0.0001 / 2
        let expectedMean = 4950 * q
        let z = (Double(14142) / 100 - expectedMean) / (4950 * q * (1 + 2 * 98 * q) / 100).squareRoot()
        #expect(abs(z) <= 4)
    }

    @Test("RG-093 law: E[m] = Σ pairs(i, j)·p(i, j)")
    func rg093() {
        // sizes [30, 20, 50], P [[0.2, 0.01, 0.02], [0.01, 0.3, 0.005], [0.02, 0.005, 0.1]] → Σ 61462 over seeds 0..<200 (mean 307.3100; expected 307.5000; |z| 0.17 ≤ 4)
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                total += UndirectedAdjacencyList<Int>.stochasticBlockModel(blockSizes: [30, 20, 50], edgeProbabilities: [[0.2, 0.01, 0.02], [0.01, 0.3, 0.005], [0.02, 0.005, 0.1]], using: &generator).edgeCount
            }
            #expect(total == 61462, "UndirectedAdjacencyList<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                total += Pseudograph<Int>.stochasticBlockModel(blockSizes: [30, 20, 50], edgeProbabilities: [[0.2, 0.01, 0.02], [0.01, 0.3, 0.005], [0.02, 0.005, 0.1]], using: &generator).edgeCount
            }
            #expect(total == 61462, "Pseudograph<Int>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                total += Multigraph<Int>.stochasticBlockModel(blockSizes: [30, 20, 50], edgeProbabilities: [[0.2, 0.01, 0.02], [0.01, 0.3, 0.005], [0.02, 0.005, 0.1]], using: &generator).edgeCount
            }
            #expect(total == 61462, "Multigraph<Int>")
        }
        // The law: |z| ≤ 4 against Σ pairs(i, j)·p(i, j).
        let sizes = [30, 20, 50], p = [[0.2, 0.01, 0.02], [0.01, 0.3, 0.005], [0.02, 0.005, 0.1]]
        var mean = 0.0, variance = 0.0
        for a in 0 ..< 3 {
            for b in a ..< 3 {
                let count = Double(a == b ? sizes[a] * (sizes[a] - 1) / 2 : sizes[a] * sizes[b])
                mean += count * p[a][b]
                variance += count * p[a][b] * (1 - p[a][b])
            }
        }
        #expect(abs((Double(61462) / 200 - mean) / (variance / 200).squareRoot()) <= 4)
    }

    @Test("RG-102 law: uniform over the n^(n − 2) labeled trees (Cayley)")
    func rg102() {
        // n 4 → 16 outcomes over seeds 0..<3200; χ² 15.80 ≤ 37.697 (df 15, 0.999)
        // Every outcome's count over the seeds, from the model.
        let expected: [[[Int]]: Int] = [[[0, 1], [0, 2], [0, 3]]: 206, [[0, 1], [0, 2], [1, 3]]: 218, [[0, 1], [0, 2], [2, 3]]: 169, [[0, 1], [0, 3], [1, 2]]: 200, [[0, 1], [0, 3], [2, 3]]: 184, [[0, 1], [1, 2], [1, 3]]: 191, [[0, 1], [1, 2], [2, 3]]: 201, [[0, 1], [1, 3], [2, 3]]: 200, [[0, 2], [0, 3], [1, 2]]: 229, [[0, 2], [0, 3], [1, 3]]: 189, [[0, 2], [1, 2], [1, 3]]: 206, [[0, 2], [1, 2], [2, 3]]: 206, [[0, 2], [1, 3], [2, 3]]: 209, [[0, 3], [1, 2], [1, 3]]: 184, [[0, 3], [1, 2], [2, 3]]: 211, [[0, 3], [1, 3], [2, 3]]: 197]
        do {
            var counts: [[[Int]]: Int] = [:]
            for seed in 0 ..< UInt64(3200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = Tree<Int>.random(vertexCount: 4, using: &generator)
                let key = graph.edges.map { [min($0.u, $0.v), max($0.u, $0.v)] }.sorted { $0.lexicographicallyPrecedes($1) }
                counts[key, default: 0] += 1
            }
            #expect(counts == expected, "Tree<Int>")
        }
        // The law: χ² over the 16 outcomes, each with its probability, below the 0.999 quantile.
        let probabilities: [[[Int]]: Double] = [[[0, 1], [0, 2], [0, 3]]: 0.0625, [[0, 1], [0, 2], [1, 3]]: 0.0625, [[0, 1], [0, 2], [2, 3]]: 0.0625, [[0, 1], [0, 3], [1, 2]]: 0.0625, [[0, 1], [0, 3], [2, 3]]: 0.0625, [[0, 1], [1, 2], [1, 3]]: 0.0625, [[0, 1], [1, 2], [2, 3]]: 0.0625, [[0, 1], [1, 3], [2, 3]]: 0.0625, [[0, 2], [0, 3], [1, 2]]: 0.0625, [[0, 2], [0, 3], [1, 3]]: 0.0625, [[0, 2], [1, 2], [1, 3]]: 0.0625, [[0, 2], [1, 2], [2, 3]]: 0.0625, [[0, 2], [1, 3], [2, 3]]: 0.0625, [[0, 3], [1, 2], [1, 3]]: 0.0625, [[0, 3], [1, 2], [2, 3]]: 0.0625, [[0, 3], [1, 3], [2, 3]]: 0.0625]
        let chiSquare = probabilities.reduce(0.0) { sum, outcome in
            let observed = Double(expected[outcome.key] ?? 0), predicted = 3200 * outcome.value
            return sum + (observed - predicted) * (observed - predicted) / predicted
        }
        #expect(abs(chiSquare - 15.80) <= 0.005 && chiSquare <= 37.697, "\(chiSquare)")
    }

    @Test("RG-103 laws: n − 1 edges, connected, degree(v) = 1 + occurrences of v in the code")
    func rg103() {
        // n 200, seeds 0..<50 → hold for every seed (igraph is_tree)
        for seed in 0 ..< UInt64(50) {
            var generator = Xoshiro256StarStar(seed: seed)
            let tree = Tree<Int>.random(vertexCount: 200, using: &generator)
            #expect(tree.vertexCount == 200 && tree.edgeCount == 199, "seed \(seed)")
            // Connected: a search from 0 reaches every vertex.
            var seen = Set([0]), stack = [0]
            while let v = stack.popLast() {
                for w in tree.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
            }
            #expect(seen.count == 200, "seed \(seed)")
            // The code: n − 2 draws below(n) on the same stream, CPython's rejection on the top bits.
            var replay = Xoshiro256StarStar(seed: seed)
            var code: [Int] = []
            let bits = Int.bitWidth - 200.leadingZeroBitCount
            while code.count < 198 {
                let r = Int(replay.next() >> UInt64(64 - bits))
                if r < 200 { code.append(r) }
            }
            #expect(replay == generator, "seed \(seed)")
            #expect(tree.pruferSequence == code, "seed \(seed)")
            #expect((0 ..< 200).allSatisfy { v in tree.degree(of: v) == 1 + code.filter { $0 == v }.count }, "seed \(seed)")
        }
    }

    @Test("RG-108 law: E[m] = p·C(n, 2); topologicalOrder == 0..<n")
    func rg108() {
        // G(60, 0.1) → Σ 35309 over seeds 0..<200 (mean 176.5450; expected 177.0000; |z| 0.51 ≤ 4)
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 60, edgeProbability: 0.1, using: &generator)
                #expect(Array(graph.topologicalOrder) == Array(0 ..< 60), "DirectedAcyclicGraph<AdjacencyList<Int>> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source < $0.target }, "DirectedAcyclicGraph<AdjacencyList<Int>> seed \(seed)")
                total += graph.edgeCount
            }
            #expect(total == 35309, "DirectedAcyclicGraph<AdjacencyList<Int>>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 60, edgeProbability: 0.1, using: &generator)
                #expect(Array(graph.topologicalOrder) == Array(0 ..< 60), "DirectedAcyclicGraph<StableDirectedGraph<Int>> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source < $0.target }, "DirectedAcyclicGraph<StableDirectedGraph<Int>> seed \(seed)")
                total += graph.edgeCount
            }
            #expect(total == 35309, "DirectedAcyclicGraph<StableDirectedGraph<Int>>")
        }
        do {
            var total = 0
            for seed in 0 ..< UInt64(200) {
                var generator = Xoshiro256StarStar(seed: seed)
                let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 60, edgeProbability: 0.1, using: &generator)
                #expect(Array(graph.topologicalOrder) == Array(0 ..< 60), "DirectedAcyclicGraph<DirectedPseudograph<Int>> seed \(seed)")
                #expect(graph.edges.allSatisfy { $0.source < $0.target }, "DirectedAcyclicGraph<DirectedPseudograph<Int>> seed \(seed)")
                total += graph.edgeCount
            }
            #expect(total == 35309, "DirectedAcyclicGraph<DirectedPseudograph<Int>>")
        }
        // The law: |z| ≤ 4 against E[m] = 1770·0.1 per seed.
        let mean = Double(35309) / 200
        let z = (mean - 1770 * 0.1) / (1770 * 0.1 * (1 - 0.1) / 200).squareRoot()
        #expect(abs(z) <= 4)
    }
}
