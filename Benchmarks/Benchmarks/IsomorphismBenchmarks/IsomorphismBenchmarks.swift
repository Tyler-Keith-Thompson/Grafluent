import AdjacencyListModule
import Benchmark
import BenchmarkSupport
import Foundation
import GraphProtocols
import IsomorphismModule
import RandomGraphs

// The pairs are the ones `ref.py --bench` times, exported by
// `ref.py --export Benchmarks/Data/Isomorphism` (raw deflate of the vertex count and one edge per
// line), so both sides time the same edge lists.
//
// Two kinds of rows, not to be compared with each other: `isIsomorphic(to:)` is a decision on a
// pair; `canonicalLabeling()` and `automorphismGroup()` work on one graph.

/// A bench pair from Benchmarks/Data/Isomorphism.
func benchPair(_ name: String) -> (UndirectedAdjacencyList<Int>, UndirectedAdjacencyList<Int>) {
    let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Data/Isomorphism")
    func load(_ side: String) -> UndirectedAdjacencyList<Int> {
        let url = directory.appendingPathComponent("\(name).\(side).deflate")
        guard let packed = try? Data(contentsOf: url), let text = try? (packed as NSData).decompressed(using: .zlib) as Data else {
            fatalError("Missing \(url.path): run ref.py --export Benchmarks/Data/Isomorphism")
        }
        let lines = String(decoding: text, as: UTF8.self).split(separator: "\n")
        let n = Int(lines[0])!
        let edges = lines.dropFirst().map { line -> UndirectedEdge<Int> in
            let ends = line.split(separator: " ")
            return UndirectedEdge(Int(ends[0])!, Int(ends[1])!)
        }
        return UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
    }
    return (load("g"), load("h"))
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // (case, isomorphic?) as in ref.py's BENCH_CASES.
    let cases: [(String, Bool)] = [
        ("rrg3-1000", true), ("rrg3-10000", true), ("rrg10-1000", true), ("grid100", true),
        ("paley101", true), ("paley401", true), ("srg16", false),
        ("cfi10", true), ("cfi10t", false), ("cfi20", true), ("cfi20t", false), ("cfi40", true), ("cfi40t", false),
        ("lsg16", true), ("lsg16t", false), ("lsg24", true), ("lsg24t", false),
        ("unionc6", false), ("unionk33", false),
    ]
    for (name, isomorphic) in cases {
        let (g, h) = benchPair(name)
        precondition(g.isIsomorphic(to: h) == isomorphic, "\(name)")
        Benchmark("Isomorphism: isIsomorphic(to:) (decision), \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(g.isIsomorphic(to: h)) }
        }
        Benchmark("Isomorphism: canonicalLabeling() (canonical labeling of G), \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(g.canonicalLabeling()) }
        }
        Benchmark("Isomorphism: automorphismGroup() (of G), \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(g.automorphismGroup().order) }
        }
    }

    // Pattern counts in a random graph with 10⁴ edges: C4, C5, P4.
    var seen = Set<UndirectedEdge<Int>>()
    let sparse = UndirectedAdjacencyList(vertices: 0 ..< 2000, edges: Inputs.randomEdges(vertexCount: 2000, edgeCount: 10_000, seed: 12)
        .map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && seen.insert($0).inserted })
    let c4 = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
    let c5 = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
    let p4 = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
    for (name, pattern) in [("C4", c4), ("C5", c5), ("P4", p4)] {
        Benchmark("Isomorphism: monomorphisms(to:).count, \(name) in G(2000, 10⁴)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(pattern.monomorphisms(to: sparse).reduce(0) { n, _ in n + 1 }) }
        }
        Benchmark("Isomorphism: subgraphIsomorphisms(to:).count, \(name) in G(2000, 10⁴)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(pattern.subgraphIsomorphisms(to: sparse).reduce(0) { n, _ in n + 1 }) }
        }
    }

    // Weisfeiler–Leman on 10⁶ edges.
    var wlSeen = Set<UndirectedEdge<Int>>()
    let large = UndirectedAdjacencyList(vertices: 0 ..< 200_000, edges: Inputs.randomEdges(vertexCount: 200_000, edgeCount: 1_000_000, seed: 13)
        .map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && wlSeen.insert($0).inserted })
    Benchmark("Isomorphism: weisfeilerLehmanGraphHash(iterations: 3), 2·10⁵ vertices, 10⁶ edges") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(large.weisfeilerLehmanGraphHash(iterations: 3)) }
    }

    // Allocations per extra element: the 120 automorphisms of K5 (one [Int] each, plus set-up).
    var k5Edges: [UndirectedEdge<Int>] = []
    for u in 0 ..< 5 { for v in u + 1 ..< 5 { k5Edges.append(UndirectedEdge(u, v)) } }
    let k5 = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: k5Edges)
    Benchmark("Isomorphism: isomorphisms(to:), all 120 of K5 onto itself") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(k5.isomorphisms(to: k5).reduce(0) { n, _ in n + 1 }) }
    }

    // Graph edit distance at unit costs: the Petersen graph against the 5-prism, and G(n, 0.3)
    // pairs on 8 and 10 vertices from the benchmark generator's edges.
    let outer = (0 ..< 5).map { UndirectedEdge($0, ($0 + 1) % 5) }, spokes = (0 ..< 5).map { UndirectedEdge($0, $0 + 5) }
    let petersen = UndirectedAdjacencyList<Int>(vertices: 0 ..< 10, edges: outer + spokes + (0 ..< 5).map { UndirectedEdge($0 + 5, ($0 + 2) % 5 + 5) })
    let prism = UndirectedAdjacencyList<Int>(vertices: 0 ..< 10, edges: outer + spokes + (0 ..< 5).map { UndirectedEdge($0 + 5, ($0 + 1) % 5 + 5) })
    Benchmark("Isomorphism: graphEditDistance(to:), Petersen against the 5-prism") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(petersen.graphEditDistance(to: prism)) }
    }
    for n in [8, 10] {
        func random(_ seed: UInt) -> UndirectedAdjacencyList<Int> {
            var edgeSeen = Set<UndirectedEdge<Int>>()
            let edges = Inputs.randomEdges(vertexCount: n, edgeCount: n * (n - 1) * 3 / 20, seed: seed)
                .map { UndirectedEdge($0.source, $0.target) }.filter { !$0.isSelfLoop && edgeSeen.insert($0).inserted }
            return UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges)
        }
        let g = random(41), h = random(42)
        Benchmark("Isomorphism: graphEditDistance(to:), random pair on \(n) vertices") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(g.graphEditDistance(to: h)) }
        }
    }
}
