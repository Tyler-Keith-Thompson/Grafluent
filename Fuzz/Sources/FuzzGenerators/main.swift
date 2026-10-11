// The NamedGraphs and RandomGraphs families on every conformer: the three undirected ones
// (UndirectedAdjacencyList, Pseudograph, Multigraph) and the six directed ones (CompressedSparseRow,
// AdjacencyMatrix, AdjacencyList, DirectedPseudograph, DirectedMultigraph, StableDirectedGraph),
// Watts–Strogatz and the geometric graph directed as both arcs of the undirected graph's edges,
// plus the random DAG on its three bases, Tree's path, star and random tree, and
// BipartiteGraph.completeBipartite. Sizes and parameters are small and drawn so that some fall
// outside the documented ranges; such a call is never made (a trap would end the run), but every
// call the documentation allows is, so a trap there is a crash.
//
// Each graph is checked for the representation contract (vertices 0..<n in order, edges strictly
// increasing — lexicographic with u < v undirected, row-major without loops directed — every
// degree and neighbor or successor row matching the edges) and for its family: the deterministic families
// against a written-out model, G(n, p) at p = 0 and 1 and G(n, m), Barabási–Albert,
// Watts–Strogatz and the block model by their counts and structure, the geometric graph against
// the returned positions, the random DAG against the undirected G(n, p) or G(n, m) on the same
// seed with 0..<n as its order. Every conformer must give the same edges and leave the generator
// in the same state, and a second run with the same seed must give the same edges again.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import FuzzSupport
import GraphProtocols
import Multigraphs
import NamedGraphs
import RandomGraphs
import StableGraphs
import Trees

enum Spec {
    case complete(Int), completeBipartite(Int, Int), path(Int), cycle(Int), star(Int), wheel(Int)
    case grid([Int], Bool), hypercube(Int), petersen, empty(Int)
    case gnp(Int, Double), gnm(Int, Int), barabasiAlbert(Int, Int), wattsStrogatz(Int, Int, Double)
    case geometric(Int, Double, Int), blockModel([Int], [[Double]])

    var isRandom: Bool {
        switch self {
        case .gnp, .gnm, .barabasiAlbert, .wattsStrogatz, .geometric, .blockModel: true
        default: false
        }
    }
}

func inUnit(_ p: Double) -> Bool { p >= 0 && p <= 1 }

func pairCount(_ n: Int, directed: Bool) -> Int { n < 2 ? 0 : (directed ? n * (n - 1) : n * (n - 1) / 2) }

/// Whether the documentation allows the call (sizes here are far from any overflow).
func valid(_ spec: Spec, directed: Bool) -> Bool {
    switch spec {
    case .complete(let n), .path(let n), .empty(let n): n >= 0
    case .completeBipartite(let a, let b): a >= 0 && b >= 0
    case .cycle(let n): n >= 3
    case .star(let n): n >= 1
    case .wheel(let n): n >= 4
    case .grid(let dimensions, _): !dimensions.isEmpty && dimensions.allSatisfy { $0 >= 0 }
    case .hypercube(let d): d >= 0 && d <= 62
    case .petersen: true
    case .gnp(let n, let p): n >= 0 && inUnit(p)
    case .gnm(let n, let m): n >= 0 && m >= 0 && m <= pairCount(n, directed: directed)
    case .barabasiAlbert(let n, let m): m >= 1 && m < n
    case .wattsStrogatz(let n, let k, let p): n >= 0 && k >= 0 && k % 2 == 0 && k <= n && inUnit(p)
    case .geometric(let n, let r, let d): n >= 0 && r >= 0 && d >= 1
    case .blockModel(let sizes, let p):
        sizes.allSatisfy { $0 >= 0 } && p.count == sizes.count && p.allSatisfy { $0.count == sizes.count }
            && p.allSatisfy { $0.allSatisfy(inUnit) }
            && (directed || (0 ..< sizes.count).allSatisfy { i in (0 ..< sizes.count).allSatisfy { p[i][$0] == p[$0][i] } })
    }
}

// MARK: Decoding

func probability(_ input: inout FuzzInput) -> Double {
    switch input.int(below: 12) {
    case 0: return 0
    case 1: return 1
    case 2: return 1e-17  // 1 − p rounds to 1
    case 3: return 0.5
    case 4: return -0.25
    case 5: return 1.5
    case 6: return .nan
    case 7: return 1 - 0x1p-53
    default: return Double(input.byte()) / 255
    }
}

func size(_ input: inout FuzzInput, _ range: ClosedRange<Int>) -> Int { input.int(in: range) }

func spec(_ input: inout FuzzInput) -> Spec {
    switch input.int(below: 16) {
    case 0: return .complete(size(&input, -1 ... 12))
    case 1: return .completeBipartite(size(&input, -1 ... 6), size(&input, -1 ... 6))
    case 2: return .path(size(&input, -1 ... 12))
    case 3: return .cycle(size(&input, -1 ... 12))
    case 4: return .star(size(&input, -1 ... 12))
    case 5: return .wheel(size(&input, -1 ... 12))
    case 6: return .grid((0 ..< size(&input, 0 ... 3)).map { _ in size(&input, -1 ... 4) }, input.byte() & 1 == 1)
    case 7: return .hypercube(size(&input, -1 ... 5))
    case 8: return .petersen
    case 9: return .empty(size(&input, -1 ... 12))
    case 10: return .gnp(size(&input, -1 ... 14), probability(&input))
    case 11: return .gnm(size(&input, -1 ... 10), size(&input, -1 ... 92))
    case 12: return .barabasiAlbert(size(&input, -1 ... 14), size(&input, -1 ... 8))
    case 13: return .wattsStrogatz(size(&input, -1 ... 14), size(&input, -1 ... 14), probability(&input))
    case 14:
        let radii: [Double] = [0, 0.05, 0.1, 0.2, 0.3, 0.45, 0.6, 1, 2, -0.1, .nan]
        return .geometric(size(&input, -1 ... 60), radii[input.int(below: radii.count)], size(&input, 0 ... 4))
    default:
        let sizes = (0 ..< size(&input, 0 ... 3)).map { _ in size(&input, -1 ... 5) }
        let b = sizes.count
        let square = input.byte() % 8 != 0
        var p = (0 ..< (square ? b : b + 1)).map { _ in (0 ..< b).map { _ in 0.0 } }
        for i in 0 ..< p.count {
            for j in 0 ..< b { p[i][j] = probability(&input) }
        }
        if input.byte() % 4 != 0 {  // usually symmetric
            for i in 0 ..< Swift.min(b, p.count) {
                for j in 0 ..< i { p[i][j] = p[j][i] }
            }
        }
        return .blockModel(sizes, p)
    }
}

// MARK: Models of the deterministic families

func undirectedModel(_ spec: Spec) -> [[Int]]? {
    switch spec {
    case .complete(let n): return (0 ..< n).flatMap { u in (u + 1 ..< n).map { [u, $0] } }
    case .completeBipartite(let a, let b): return (0 ..< a).flatMap { u in (a ..< a + b).map { [u, $0] } }
    case .path(let n): return n < 2 ? [] : (0 ..< n - 1).map { [$0, $0 + 1] }
    case .cycle(let n): return ((0 ..< n).map { [Swift.min($0, ($0 + 1) % n), Swift.max($0, ($0 + 1) % n)] }).sorted { $0.lexicographicallyPrecedes($1) }
    case .star(let n): return (1 ..< n).map { [0, $0] }
    case .wheel(let n):
        let rim = (1 ..< n).map { i -> [Int] in let j = i == n - 1 ? 1 : i + 1; return [Swift.min(i, j), Swift.max(i, j)] }
        return ((1 ..< n).map { [0, $0] } + rim).sorted { $0.lexicographicallyPrecedes($1) }
    case .grid(let dimensions, let periodic):
        let n = dimensions.reduce(1, *)
        var pairs = Set<[Int]>()
        var listed = 0
        for v in 0 ..< n {
            var rest = v
            var coordinates = [Int](repeating: 0, count: dimensions.count)
            for i in (0 ..< dimensions.count).reversed() {
                coordinates[i] = rest % dimensions[i]
                rest /= dimensions[i]
            }
            for i in 0 ..< dimensions.count {
                var stride = 1
                for j in i + 1 ..< dimensions.count { stride *= dimensions[j] }
                let x = coordinates[i], d = dimensions[i]
                if x + 1 < d { pairs.insert([v, v + stride]); listed += 1 }
                if periodic, d >= 3, x == d - 1 { pairs.insert([v - (d - 1) * stride, v]); listed += 1 }
            }
        }
        check(listed == pairs.count, "grid model repeats an edge")
        return pairs.sorted { $0.lexicographicallyPrecedes($1) }
    case .hypercube(let d):
        return (0 ..< 1 << d).flatMap { v in (0 ..< d).filter { v >> $0 & 1 == 0 }.map { [v, v | 1 << $0] } }
            .sorted { $0.lexicographicallyPrecedes($1) }
    case .petersen:
        var pairs: [[Int]] = []
        for i in 0 ..< 5 {
            pairs.append([i, (i + 1) % 5].sorted())
            pairs.append([i, i + 5])
            pairs.append([5 + i, 5 + (i + 2) % 5].sorted())
        }
        return pairs.sorted { $0.lexicographicallyPrecedes($1) }
    case .empty: return []
    default: return nil
    }
}

func directedModel(_ spec: Spec) -> [[Int]]? {
    let rowMajor: ([[Int]]) -> [[Int]] = { $0.sorted { $0.lexicographicallyPrecedes($1) } }
    switch spec {
    case .complete, .completeBipartite, .grid, .hypercube, .petersen:
        return rowMajor(undirectedModel(spec)!.flatMap { [$0, [$0[1], $0[0]]] })
    case .path, .star, .empty:
        return undirectedModel(spec)
    case .cycle(let n): return rowMajor((0 ..< n).map { [$0, ($0 + 1) % n] })
    case .wheel(let n): return rowMajor((1 ..< n).map { [0, $0] } + (1 ..< n).map { [$0, $0 == n - 1 ? 1 : $0 + 1] })
    default: return nil
    }
}

/// The families whose directed form is the undirected graph with both arcs of every edge, on the
/// same draws.
func bothArcsOfUndirected(_ spec: Spec) -> Bool {
    switch spec {
    case .wattsStrogatz, .geometric: true
    default: false
    }
}

// MARK: Building

/// A fresh generator per seed: the conformers and the repeat each start from the same state.
struct Built {
    var edges: [[Int]]
    var generator: Xoshiro256StarStar
    var positions: [Double]?
}

func buildUndirected<G: _GraphConstruction>(_: G.Type, _ spec: Spec, _ seed: UInt64) -> Built {
    var g = Xoshiro256StarStar(seed: seed)
    var positions: [Double]?
    let graph: G
    switch spec {
    case .complete(let n): graph = .complete(vertexCount: n)
    case .completeBipartite(let a, let b): graph = .completeBipartite(leftCount: a, rightCount: b)
    case .path(let n): graph = .path(vertexCount: n)
    case .cycle(let n): graph = .cycle(vertexCount: n)
    case .star(let n): graph = .star(vertexCount: n)
    case .wheel(let n): graph = .wheel(vertexCount: n)
    case .grid(let dimensions, let periodic): graph = .grid(dimensions: dimensions, periodic: periodic)
    case .hypercube(let d): graph = .hypercube(dimension: d)
    case .petersen: graph = .petersen()
    case .empty(let n): graph = .empty(vertexCount: n)
    case .gnp(let n, let p): graph = .erdosRenyi(vertexCount: n, edgeProbability: p, using: &g)
    case .gnm(let n, let m): graph = .erdosRenyi(vertexCount: n, edgeCount: m, using: &g)
    case .barabasiAlbert(let n, let m): graph = .barabasiAlbert(vertexCount: n, edgesPerVertex: m, using: &g)
    case .wattsStrogatz(let n, let k, let p): graph = .wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &g)
    case .geometric(let n, let r, let d):
        let result = G.randomGeometric(vertexCount: n, radius: r, dimension: d, using: &g)
        graph = result.graph
        positions = result.positions
    case .blockModel(let sizes, let p): graph = .stochasticBlockModel(blockSizes: sizes, edgeProbabilities: p, using: &g)
    }
    return Built(edges: checkedUndirected(graph, "\(G.self)"), generator: g, positions: positions)
}

func buildDirected<G: _DirectedGraphConstruction>(_: G.Type, _ spec: Spec, _ seed: UInt64) -> Built {
    var g = Xoshiro256StarStar(seed: seed)
    var positions: [Double]?
    let graph: G
    switch spec {
    case .complete(let n): graph = .complete(vertexCount: n)
    case .completeBipartite(let a, let b): graph = .completeBipartite(leftCount: a, rightCount: b)
    case .path(let n): graph = .path(vertexCount: n)
    case .cycle(let n): graph = .cycle(vertexCount: n)
    case .star(let n): graph = .star(vertexCount: n)
    case .wheel(let n): graph = .wheel(vertexCount: n)
    case .grid(let dimensions, let periodic): graph = .grid(dimensions: dimensions, periodic: periodic)
    case .hypercube(let d): graph = .hypercube(dimension: d)
    case .petersen: graph = .petersen()
    case .empty(let n): graph = .empty(vertexCount: n)
    case .gnp(let n, let p): graph = .erdosRenyi(vertexCount: n, edgeProbability: p, using: &g)
    case .gnm(let n, let m): graph = .erdosRenyi(vertexCount: n, edgeCount: m, using: &g)
    case .barabasiAlbert(let n, let m): graph = .barabasiAlbert(vertexCount: n, edgesPerVertex: m, using: &g)
    case .blockModel(let sizes, let p): graph = .stochasticBlockModel(blockSizes: sizes, edgeProbabilities: p, using: &g)
    case .wattsStrogatz(let n, let k, let p): graph = .wattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, using: &g)
    case .geometric(let n, let r, let d):
        let result = G.randomGeometric(vertexCount: n, radius: r, dimension: d, using: &g)
        graph = result.graph
        positions = result.positions
    }
    return Built(edges: checkedDirected(graph, "\(G.self)"), generator: g, positions: positions)
}

// MARK: The representation contract

func checkedUndirected<G: Graph>(_ graph: G, _ type: String) -> [[Int]] where G.Vertex == Int {
    let n = graph.vertexCount
    check(Array(graph.vertices) == Array(0 ..< n), "\(type): vertices are not 0..<\(n)")
    let edges = graph.edges.map { [$0.u, $0.v] }
    check(graph.edgeCount == edges.count, "\(type): edgeCount \(graph.edgeCount) for \(edges.count) edges")
    var rows = [[Int]](repeating: [], count: n)
    for (k, e) in edges.enumerated() {
        check(e[0] >= 0 && e[0] < e[1] && e[1] < n, "\(type): edge \(e) is not u < v in 0..<\(n)")
        if k > 0 { check(edges[k - 1].lexicographicallyPrecedes(e), "\(type): edges out of order at \(k)") }
        rows[e[0]].append(e[1])
        rows[e[1]].append(e[0])
    }
    for v in 0 ..< n {
        check(graph.degree(of: v) == rows[v].count, "\(type): degree(of: \(v))")
        check(Array(graph.neighbors(of: v)) == rows[v].sorted(), "\(type): neighbors(of: \(v)) \(Array(graph.neighbors(of: v))) for \(rows[v].sorted())")
    }
    return edges
}

func checkedDirected<G: DirectedGraph>(_ graph: G, _ type: String) -> [[Int]] where G.Vertex == Int {
    let n = graph.vertexCount
    check(Array(graph.vertices) == Array(0 ..< n), "\(type): vertices are not 0..<\(n)")
    let edges = graph.edges.map { [$0.source, $0.target] }
    check(graph.edgeCount == edges.count, "\(type): edgeCount \(graph.edgeCount) for \(edges.count) edges")
    var out = [[Int]](repeating: [], count: n)
    for (k, e) in edges.enumerated() {
        check(e[0] >= 0 && e[0] < n && e[1] >= 0 && e[1] < n && e[0] != e[1], "\(type): arc \(e) is a loop or out of 0..<\(n)")
        if k > 0 { check(edges[k - 1].lexicographicallyPrecedes(e), "\(type): arcs out of row-major order at \(k)") }
        out[e[0]].append(e[1])
    }
    for v in 0 ..< n {
        check(graph.outDegree(of: v) == out[v].count, "\(type): outDegree(of: \(v))")
        check(Array(graph.successors(of: v)) == out[v], "\(type): successors(of: \(v))")
    }
    return edges
}

// MARK: Family checks for the random procedures

func blockOf(_ sizes: [Int]) -> [Int] { sizes.enumerated().flatMap { repeatElement($0.offset, count: $0.element) } }

func checkRandom(_ spec: Spec, _ built: Built, directed: Bool, seed: UInt64) {
    let edges = built.edges
    let fresh = Xoshiro256StarStar(seed: seed)
    let pairs: (Int) -> [[Int]] = { n in
        directed ? (0 ..< n).flatMap { u in (0 ..< n).filter { $0 != u }.map { [u, $0] } }
            : (0 ..< n).flatMap { u in (u + 1 ..< n).map { [u, $0] } }
    }
    switch spec {
    case .gnp(let n, let p):
        if p == 0 || 1 - p == 1 {
            check(edges.isEmpty && built.generator == fresh, "G(n, p) with p \(p): \(edges.count) edges or draws")
        } else if p == 1 {
            check(edges == pairs(n) && built.generator == fresh, "G(n, 1) is not complete without draws")
        }
    case .gnm(_, let m):
        check(edges.count == m, "G(n, m): \(edges.count) edges for m \(m)")
    case .barabasiAlbert(let n, let m):
        check(edges.count == m * (n - m), "Barabási–Albert: \(edges.count) edges")
        var older = [Int](repeating: 0, count: n)
        for e in edges {
            let (new, old) = directed ? (e[0], e[1]) : (e[1], e[0])
            check(old < new, "Barabási–Albert: edge \(e) not from new to old")
            older[new] += 1
        }
        for s in 1 ..< n { check(older[s] == (s <= m ? 1 : m), "Barabási–Albert: vertex \(s) joins \(older[s]) older vertices") }
        for i in 1 ... m { check(edges.contains(directed ? [i, 0] : [0, i]), "Barabási–Albert: star edge to \(i) missing") }
    case .wattsStrogatz(let n, let k, let p):
        if k == n {
            check(edges == pairs(n) && built.generator == fresh, "Watts–Strogatz k = n is not complete without draws")
        } else {
            check(edges.count == n * k / 2, "Watts–Strogatz: \(edges.count) edges for n \(n), k \(k)")
            if p == 0 || k == 0 {
                let ring = Set((0 ..< k / 2).flatMap { j in (0 ..< n).map { [Swift.min($0, ($0 + j + 1) % n), Swift.max($0, ($0 + j + 1) % n)] } })
                check(Set(edges) == ring, "Watts–Strogatz with p \(p): not the ring lattice")
            }
            if k == 0 { check(built.generator == fresh, "Watts–Strogatz k = 0 drew") }
        }
    case .geometric(let n, let r, let d):
        let x = built.positions!
        check(x.count == n * d && x.allSatisfy { $0 >= 0 && $0 < 1 }, "geometric: positions")
        var expected: [[Int]] = []
        for u in 0 ..< n {
            for v in u + 1 ..< n {
                var s = 0.0
                for i in 0 ..< d {
                    let difference = x[u * d + i] - x[v * d + i]
                    s += difference * difference
                }
                if s <= r * r { expected.append([u, v]) }
            }
        }
        check(edges == expected, "geometric: \(edges.count) edges for \(expected.count) within \(r)")
    case .blockModel(let sizes, let p):
        let block = blockOf(sizes)
        let n = block.count
        var count = [[Int]](repeating: [Int](repeating: 0, count: sizes.count), count: sizes.count)
        for e in edges { count[block[e[0]]][block[e[1]]] += 1 }
        for i in 0 ..< sizes.count {
            for j in 0 ..< sizes.count where directed || i <= j {
                let full = i == j ? (directed ? sizes[i] * (sizes[i] - 1) : sizes[i] * (sizes[i] - 1) / 2) : sizes[i] * sizes[j]
                if p[i][j] == 0 || 1 - p[i][j] == 1 { check(count[i][j] == 0, "block model: \(count[i][j]) edges in blocks \(i), \(j) with p \(p[i][j])") }
                if p[i][j] == 1 { check(count[i][j] == full, "block model: \(count[i][j]) of \(full) pairs in blocks \(i), \(j) with p 1") }
            }
        }
        check(edges.allSatisfy { $0[1] < n }, "block model: vertex count")
    default:
        break
    }
}

// MARK: The run

func runFamily(_ spec: Spec, seed: UInt64) {
    if valid(spec, directed: false) {
        let reference = buildUndirected(UndirectedAdjacencyList<Int>.self, spec, seed)
        for other in [buildUndirected(Pseudograph<Int>.self, spec, seed), buildUndirected(Multigraph<Int>.self, spec, seed)] {
            check(other.edges == reference.edges, "undirected conformers disagree on \(spec)")
            check(other.generator == reference.generator, "undirected conformers drew differently on \(spec)")
            check(other.positions == reference.positions, "undirected conformers placed points differently on \(spec)")
        }
        if spec.isRandom {
            let again = buildUndirected(UndirectedAdjacencyList<Int>.self, spec, seed)
            check(again.edges == reference.edges && again.generator == reference.generator, "seed \(seed) does not reproduce \(spec)")
            checkRandom(spec, reference, directed: false, seed: seed)
        } else {
            check(reference.edges == undirectedModel(spec)!, "\(spec): \(reference.edges) is not the model \(undirectedModel(spec)!)")
        }
        // The directed Barabási–Albert graph makes the same draws, new vertex to old.
        if case .barabasiAlbert = spec, valid(spec, directed: true) {
            let directed = buildDirected(AdjacencyList<Int>.self, spec, seed)
            check(Set(directed.edges.map { [$0[1], $0[0]] }) == Set(reference.edges) && directed.generator == reference.generator,
                  "directed Barabási–Albert is not the undirected one reversed")
        }
        checkSpecialTypes(spec, reference, seed: seed)
    }
    if valid(spec, directed: true) {
        let reference = buildDirected(CompressedSparseRow.self, spec, seed)
        let others = [
            buildDirected(AdjacencyMatrix.self, spec, seed), buildDirected(AdjacencyList<Int>.self, spec, seed),
            buildDirected(DirectedPseudograph<Int>.self, spec, seed), buildDirected(DirectedMultigraph<Int>.self, spec, seed),
            buildDirected(StableDirectedGraph<Int>.self, spec, seed),
        ]
        for other in others {
            check(other.edges == reference.edges, "directed conformers disagree on \(spec)")
            check(other.generator == reference.generator, "directed conformers drew differently on \(spec)")
            check(other.positions == reference.positions, "directed conformers placed points differently on \(spec)")
        }
        if bothArcsOfUndirected(spec) {
            // The undirected form's draws, positions and edges, with both arcs of every edge.
            let undirected = buildUndirected(UndirectedAdjacencyList<Int>.self, spec, seed)
            let arcs = undirected.edges.flatMap { [$0, [$0[1], $0[0]]] }.sorted { $0.lexicographicallyPrecedes($1) }
            check(reference.edges == arcs, "directed \(spec) is not both arcs of the undirected graph")
            check(reference.generator == undirected.generator && reference.positions == undirected.positions,
                  "directed \(spec) drew differently from the undirected form")
        } else if spec.isRandom {
            let again = buildDirected(CompressedSparseRow.self, spec, seed)
            check(again.edges == reference.edges && again.generator == reference.generator, "seed \(seed) does not reproduce directed \(spec)")
            checkRandom(spec, reference, directed: true, seed: seed)
        } else {
            check(reference.edges == directedModel(spec)!, "directed \(spec): \(reference.edges) is not the model")
        }
    }
}

/// The random DAG on each base against the undirected G(n, p) or G(n, m) on the same seed, Tree's
/// path and star, and BipartiteGraph's K_{a,b}.
func checkSpecialTypes(_ spec: Spec, _ undirected: Built, seed: UInt64) {
    func dag<B: _DirectedGraphConstruction & MutableDirectedGraph>(_: B.Type) {
        var g = Xoshiro256StarStar(seed: seed)
        let graph: DirectedAcyclicGraph<B>
        switch spec {
        case .gnp(let n, let p): graph = .erdosRenyi(vertexCount: n, edgeProbability: p, using: &g)
        case .gnm(let n, let m): graph = .erdosRenyi(vertexCount: n, edgeCount: m, using: &g)
        default: return
        }
        let edges = checkedDirected(graph, "DirectedAcyclicGraph<\(B.self)>")
        check(edges == undirected.edges && g == undirected.generator, "random DAG on \(B.self) is not the undirected \(spec) oriented up")
        check(Array(graph.topologicalOrder) == Array(0 ..< graph.vertexCount), "random DAG on \(B.self): order is not 0..<n")
    }
    dag(AdjacencyList<Int>.self)
    dag(DirectedPseudograph<Int>.self)
    dag(StableDirectedGraph<Int>.self)
    switch spec {
    case .path(let n) where n >= 1:
        check(checkedUndirected(Tree<Int>.path(vertexCount: n), "Tree path") == undirected.edges, "Tree.path(vertexCount: \(n))")
    case .star(let n):
        check(checkedUndirected(Tree<Int>.star(vertexCount: n), "Tree star") == undirected.edges, "Tree.star(vertexCount: \(n))")
    case .completeBipartite(let a, let b):
        let graph = BipartiteGraph<Int>.completeBipartite(leftCount: a, rightCount: b)
        check(checkedUndirected(graph, "BipartiteGraph") == undirected.edges, "BipartiteGraph.completeBipartite edges")
        check(Array(graph.left) == Array(0 ..< a) && Array(graph.right) == Array(a ..< a + b), "BipartiteGraph.completeBipartite sides")
        for v in 0 ..< a + b { check(graph.side(of: v) == (v < a ? .left : .right), "side(of: \(v))") }
    default:
        break
    }
}

/// A uniformly random tree: n − 1 edges, connected, reproducible.
func checkRandomTree(_ n: Int, seed: UInt64) {
    guard n >= 1 else { return }
    var g = Xoshiro256StarStar(seed: seed)
    let edges = checkedUndirectedTree(Tree<Int>.random(vertexCount: n, using: &g))
    var h = Xoshiro256StarStar(seed: seed)
    check(checkedUndirectedTree(Tree<Int>.random(vertexCount: n, using: &h)) == edges && g == h, "random tree does not reproduce")
    check(edges.count == n - 1, "random tree: \(edges.count) edges on \(n) vertices")
    var parent = Array(0 ..< n)
    func find(_ x: Int) -> Int { var x = x; while parent[x] != x { x = parent[x] }; return x }
    for e in edges {
        let a = find(e[0]), b = find(e[1])
        check(a != b, "random tree has a cycle through \(e)")
        parent[a] = b
    }
}

/// Tree edges keep the Prüfer decoding's orientation, so only the vertex range and degrees are
/// checked here; the edges come back normalized for comparison.
func checkedUndirectedTree(_ tree: Tree<Int>) -> [[Int]] {
    let n = tree.vertexCount
    check(Array(tree.vertices) == Array(0 ..< n), "random tree: vertices")
    var degree = [Int](repeating: 0, count: n)
    let edges = tree.edges.map { e -> [Int] in
        check(e.u >= 0 && e.u < n && e.v >= 0 && e.v < n && e.u != e.v, "random tree: edge \(e.u)–\(e.v)")
        degree[e.u] += 1
        degree[e.v] += 1
        return [Swift.min(e.u, e.v), Swift.max(e.u, e.v)]
    }
    for v in 0 ..< n { check(tree.degree(of: v) == degree[v], "random tree: degree(of: \(v))") }
    return edges
}

runFuzzer { input in
    let seed = UInt64(input.byte()) | UInt64(input.byte()) << 8
    if input.byte() % 8 == 0 {
        checkRandomTree(input.int(in: 0 ... 40), seed: seed)
        return
    }
    runFamily(spec(&input), seed: seed)
}
