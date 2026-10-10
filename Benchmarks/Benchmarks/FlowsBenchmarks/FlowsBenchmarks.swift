import Benchmark
import CompressedSparseRowModule
import Flows
import GraphProtocols
import Multigraphs

// Instances from the catalog's 64-bit LCG (Tests/Catalogs/Flows/cases.md, Notation), so the same
// networks can be rebuilt outside Swift to time NetworkX, igraph, OR-Tools, LEMON and Boost on
// them: random digraphs (lcgnet), the DIMACS families genrmf (Goldfarb–Grigoriadis) and Washington
// random level graphs, and a 4-connected vision grid with terminal arcs.

struct LCG {
    var x: UInt64
    mutating func next() -> Int {
        x = x &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(x >> 33)
    }
}

struct Network {
    var n: Int
    var edges: [DirectedEdge<Int>] = []
    var capacities: [Int] = []
    var costs: [Int] = []
    var source = 0, sink = 0

    mutating func add(_ u: Int, _ v: Int, _ c: Int) {
        edges.append(DirectedEdge(from: u, to: v))
        capacities.append(c)
    }
}

func lcgnet(_ n: Int, _ m: Int, _ seed: UInt64, _ cmax: Int, costs: ClosedRange<Int>? = nil) -> Network {
    var g = LCG(x: seed)
    var net = Network(n: n)
    while net.edges.count < m {
        let u = g.next() % n, v = g.next() % n
        if u == v { continue }
        net.add(u, v, 1 + g.next() % cmax)
        if let costs { net.costs.append(costs.lowerBound + g.next() % (costs.count)) }
    }
    return net
}

func genrmf(_ a: Int, _ b: Int, _ seed: UInt64, c1: Int = 1, c2: Int = 100) -> Network {
    var g = LCG(x: seed)
    var net = Network(n: a * a * b)
    let big = c2 * a * a
    for k in 0 ..< b {
        let base = k * a * a
        for i in 0 ..< a {
            for j in 0 ..< a {
                let v = base + i * a + j
                if j + 1 < a {
                    net.add(v, v + 1, big)
                    net.add(v + 1, v, big)
                }
                if i + 1 < a {
                    net.add(v, v + a, big)
                    net.add(v + a, v, big)
                }
            }
        }
        if k + 1 < b {
            var perm = Array(0 ..< a * a)
            for x in stride(from: a * a - 1, to: 0, by: -1) {
                let y = g.next() % (x + 1)
                perm.swapAt(x, y)
            }
            for x in 0 ..< a * a { net.add(base + x, base + a * a + perm[x], c1 + g.next() % (c2 - c1 + 1)) }
        }
    }
    net.sink = net.n - 1
    return net
}

func rlg(levels: Int, width: Int, _ seed: UInt64, degree: Int = 3, cmax: Int = 10000) -> Network {
    var g = LCG(x: seed)
    var net = Network(n: levels * width + 2)
    net.sink = net.n - 1
    for w in 0 ..< width { net.add(0, 1 + w, cmax * degree) }
    for l in 0 ..< levels - 1 {
        for w in 0 ..< width {
            let u = 1 + l * width + w
            for _ in 0 ..< degree {
                let v = 1 + (l + 1) * width + g.next() % width
                net.add(u, v, 1 + g.next() % cmax)
            }
        }
    }
    for w in 0 ..< width { net.add(1 + (levels - 1) * width + w, net.sink, cmax * degree) }
    return net
}

func vision(rows: Int, cols: Int, _ seed: UInt64) -> Network {
    var g = LCG(x: seed)
    let p = rows * cols
    var net = Network(n: p + 2)
    net.source = p
    net.sink = p + 1
    for i in 0 ..< rows {
        for j in 0 ..< cols {
            let v = i * cols + j
            net.add(p, v, g.next() % 100)
            net.add(v, p + 1, g.next() % 100)
            if j + 1 < cols {
                net.add(v, v + 1, 1 + g.next() % 20)
                net.add(v + 1, v, 1 + g.next() % 20)
            }
            if i + 1 < rows {
                net.add(v, v + cols, 1 + g.next() % 20)
                net.add(v + cols, v, 1 + g.next() % 20)
            }
        }
    }
    return net
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)
    Benchmark.defaultConfiguration.maxIterations = 20

    var random = lcgnet(5000, 50000, 11, 1000)
    random.sink = 4999
    let families: [(String, Network)] = [
        ("random G(5000, 50000)", random),
        ("genrmf long a=8 b=256", genrmf(8, 256, 12)),
        ("genrmf wide a=32 b=16", genrmf(32, 16, 13)),
        ("RLG long 512×16", rlg(levels: 512, width: 16, 14)),
        ("RLG wide 16×1024", rlg(levels: 16, width: 1024, 15)),
        ("vision 256×256", vision(rows: 256, cols: 256, 16)),
    ]
    for (name, net) in families {
        let graph = DirectedPseudograph(vertices: 0 ..< net.n, edges: net.edges)
        let capacities = net.capacities
        let (s, t) = (net.source, net.sink)
        let value = graph.maximumFlowValue(from: s, to: t) { capacities[$0] }
        precondition(graph.dinicMaximumFlow(from: s, to: t) { capacities[$0] }.value == value)
        Benchmark("Flows: maximumFlowValue, \(name) (value \(value))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.maximumFlowValue(from: s, to: t) { capacities[$0] }) }
        }
        Benchmark("Flows: maximumFlow, \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.maximumFlow(from: s, to: t) { capacities[$0] }) }
        }
        Benchmark("Flows: minimumCut(from:to:), \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.minimumCut(from: s, to: t) { capacities[$0] }) }
        }
        Benchmark("Flows: dinicMaximumFlow, \(name)") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.dinicMaximumFlow(from: s, to: t) { capacities[$0] }) }
        }
        Benchmark("Flows: edmondsKarpMaximumFlow, \(name)", configuration: .init(maxDuration: .seconds(5), maxIterations: 3)) { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.edmondsKarpMaximumFlow(from: s, to: t) { capacities[$0] }) }
        }
    }
    // The random network as a compressed sparse row graph (its own rows, parallel edges merged).
    var indices: [Int] = []
    let csr = CompressedSparseRow(vertexCount: random.n, edges: random.edges, edgeIndices: &indices)
    var merged = [Int](repeating: 0, count: csr.edgeCount)
    for (k, e) in indices.enumerated() { merged[e] += random.capacities[k] }
    Benchmark("Flows: maximumFlowValue, random G(5000, 50000) on CompressedSparseRow") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(csr.maximumFlowValue(from: 0, to: 4999) { merged[$0] }) }
    }

    // Undirected: the global cut (Nagamochi–Ibaraki), Gomory–Hu, connectivity.
    let sw = lcgnet(1000, 10000, 31, 100)
    let swGraph = Pseudograph(vertices: 0 ..< 1000, edges: sw.edges.map { UndirectedEdge($0.source, $0.target) })
    let swCapacities = sw.capacities
    Benchmark("Flows: minimumCut(capacity:) undirected, lcgund(1000, 10000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(swGraph.minimumCut { swCapacities[$0] }) }
    }
    for (n, m, seed) in [(200, 1000, 32 as UInt64), (2000, 10000, 33)] {
        let net = lcgnet(n, m, seed, 100)
        let graph = Pseudograph(vertices: 0 ..< n, edges: net.edges.map { UndirectedEdge($0.source, $0.target) })
        let capacities = net.capacities
        Benchmark("Flows: gomoryHuTree, lcgund(\(n), \(m))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.gomoryHuTree { capacities[$0] }) }
        }
    }
    // The directed global cut (and λ of a digraph): random digraphs with capacities, and unit.
    let directedCut = lcgnet(1000, 10000, 41, 100)
    let directedCutGraph = DirectedPseudograph(vertices: 0 ..< 1000, edges: directedCut.edges)
    let directedCutCapacities = directedCut.capacities
    Benchmark("Flows: minimumCut(capacity:) directed, lcgnet(1000, 10000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedCutGraph.minimumCut { directedCutCapacities[$0] }) }
    }
    let directedUnit = lcgnet(1000, 20000, 42, 1)
    let directedUnitGraph = DirectedPseudograph(vertices: 0 ..< 1000, edges: directedUnit.edges)
    Benchmark("Flows: edgeConnectivity() directed, lcgnet(1000, 20000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directedUnitGraph.edgeConnectivity()) }
    }
    let conn = lcgnet(1000, 8000, 34, 1)
    let connGraph = Pseudograph(vertices: 0 ..< 1000, edges: conn.edges.map { UndirectedEdge($0.source, $0.target) })
    Benchmark("Flows: edgeConnectivity(), lcgund(1000, 8000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(connGraph.edgeConnectivity()) }
    }
    Benchmark("Flows: vertexConnectivity(), lcgund(1000, 8000)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(connGraph.vertexConnectivity()) }
    }

    // Minimum-cost flow: random networks with ten (a hundred) supplies of 20 and as many demands.
    for (n, m, seed, k) in [(1000, 10941, 21 as UInt64, 10), (10000, 100_000, 22, 100)] {
        let net = lcgnet(n, m, seed, 100, costs: 1 ... 100)
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: net.edges)
        let capacities = net.capacities, costs = net.costs
        var supply = [Int](repeating: 0, count: n)
        for i in 0 ..< k {
            supply[i] = 20
            supply[n - k + i] = -20
        }
        let result = graph.minimumCostFlow(supply: { supply[$0] }, capacity: { capacities[$0] }, cost: { costs[$0] })
        Benchmark("Flows: minimumCostFlow, lcgcost(\(n), \(m)) (cost \(result.map { "\($0.cost)" } ?? "infeasible"))") { benchmark in
            for _ in benchmark.scaledIterations { blackHole(graph.minimumCostFlow(supply: { supply[$0] }, capacity: { capacities[$0] }, cost: { costs[$0] })) }
        }
    }
}
