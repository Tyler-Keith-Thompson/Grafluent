// Properties against oracles written inside each test, with shrinking (swift-property-based): on a
// failure, PropertyBased shrinks the generated input and prints the smallest one that still fails.
// Graphs are multigraphs with self-loops on 0 … 8 vertices, listed in an order chosen by a seed
// (seed 0 keeps 0, 1, 2, …), with incidence or out-edge rows shuffled by the same seed, and an
// optional spanning path so that connected and disconnected graphs both occur. The oracles use
// only the definitions: breadth-first search from every vertex over the graph's own rows (with
// ShortestPaths' parent rule, the first discoverer through its first edge in row order, for the
// unweighted `diameterPath`), Floyd–Warshall over the edge list for weights (the lightest parallel
// copy, loops ignored), and nil as infinity for eccentricities and totals. Weights are `Int` in
// 0 … 4 and `Double` quarters in 0 … 2 (zeros included; quarters keep every sum exact, so ties and
// averages do not depend on summation order). The bounding shapes (paths, cycles, complete and
// complete bipartite graphs, grids, stars, wheels) run on `UndirectedAdjacencyList`, whose index
// rows the algorithms borrow. Trees compare with TreeAlgorithms' `Tree` members. See README.md.

import AdjacencyListModule
import Distances
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import TreeAlgorithms
import Trees
import Walks

/// An undirected multigraph on `0..<vertexCount`, its vertices listed in a seeded order and its
/// incidence rows (built in position order, a self-loop twice) shuffled by the same seed, unless
/// the seed is 0. Vertex indices are positions in `vertices`; edge indices are positions.
private struct ShuffledPseudograph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    private let index: [Int]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            rows[edge.u].append(k)
            rows[edge.v].append(k)
        }
        var listed = Array(0 ..< vertexCount)
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
            listed.shuffle(using: &rng)
        }
        var index = [Int](repeating: 0, count: vertexCount)
        for (i, v) in listed.enumerated() { index[v] = i }
        self.vertices = listed
        self.edges = edges
        self.index = index
        self.rows = rows
    }

    func incidentEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func neighbors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { index[vertex] }
    func vertex(atIndex i: Int) -> Int { vertices[i] }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// A directed multigraph on `0..<vertexCount`, its vertices listed in a seeded order and its
/// out-edge rows (built in position order) shuffled by the same seed, unless the seed is 0.
private struct ShuffledDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    private let index: [Int]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [DirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() { rows[edge.source].append(k) }
        var listed = Array(0 ..< vertexCount)
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
            listed.shuffle(using: &rng)
        }
        var index = [Int](repeating: 0, count: vertexCount)
        for (i, v) in listed.enumerated() { index[v] = i }
        self.vertices = listed
        self.edges = edges
        self.index = index
        self.rows = rows
    }

    func outEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func successors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].target } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { index[vertex] }
    func vertex(atIndex i: Int) -> Int { vertices[i] }
}

@Suite("Distances properties against oracles, with shrinking", .tags(.randomized))
struct DistancePropertyTests {
    @Test("§A – §D every unweighted undirected measure equals breadth-first search from every vertex, on random multigraphs with loops, shuffled rows and vertex orders, connected or not")
    func undirectedUnweighted() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 0 ... 9), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, size, spanning, seed in
            let n = size
            var edges = spanning && n > 1 ? (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) } : []
            if n > 0 { edges += raw.map { UndirectedEdge($0.0 % n, $0.1 % n) } }
            let graph = ShuffledPseudograph(vertexCount: n, edges: edges, seed: seed)
            let listed = graph.vertices
            // Oracle: BFS from every vertex over the graph's rows, distances by vertex index.
            func search(_ s: Int) -> (depth: [Int?], parent: [Int?], parentEdge: [Int?]) {
                var depth = [Int?](repeating: nil, count: n)
                var parent = [Int?](repeating: nil, count: n)
                var parentEdge = [Int?](repeating: nil, count: n)
                depth[s] = 0
                var queue = [s]
                var head = 0
                while head < queue.count {
                    let x = queue[head]
                    head += 1
                    for e in graph.incidentEdges(of: listed[x]) {
                        let y = graph.vertexIndex(of: edges[e].oppositeVertex(to: listed[x]))
                        if depth[y] == nil {
                            depth[y] = depth[x]! + 1
                            parent[y] = x
                            parentEdge[y] = e
                            queue.append(y)
                        }
                    }
                }
                return (depth, parent, parentEdge)
            }
            let all = (0 ..< n).map { search($0).depth }
            let ecc: [Int?] = all.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.max() }
            let totals: [Int?] = all.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.reduce(0, +) }
            let radius = ecc.compactMap { $0 }.min()
            let diameter = n == 0 || ecc.contains(nil) ? nil : ecc.compactMap { $0 }.max()
            let center = (0 ..< n).filter { ecc[$0] == radius }.map { listed[$0] }
            let periphery = (0 ..< n).filter { ecc[$0] == diameter }.map { listed[$0] }
            let leastTotal = totals.compactMap { $0 }.min()
            let centroid = (0 ..< n).filter { totals[$0] == leastTotal }.map { listed[$0] }
            var wiener: Int? = 0
            for u in 0 ..< n {
                for v in u + 1 ..< n {
                    if let d = all[u][v], let w = wiener { wiener = w + d } else { wiener = nil }
                }
            }
            let average: Double? = n == 0 ? nil : n == 1 ? 0 : wiener.map { Double($0) / Double(n * (n - 1) / 2) }
            let density = n <= 1 ? 0 : Double(2 * edges.count) / Double(n * (n - 1))

            let eccentricities = graph.eccentricities()
            let byIndex = (0 ..< n).map { eccentricities.eccentricity(ofIndex: $0) }
            #expect(byIndex == ecc, "\(n) vertices, \(edges), seed \(seed)")
            let oneByOne = listed.map { graph.eccentricity(of: $0) }
            #expect(oneByOne == ecc)
            #expect(eccentricities.radius == radius)
            #expect(eccentricities.diameter == diameter)
            #expect(eccentricities.center == center)
            #expect(eccentricities.periphery == periphery)
            #expect(graph.radius() == radius)
            #expect(graph.diameter() == diameter)
            #expect(graph.center() == center)
            #expect(graph.periphery() == periphery)
            #expect(graph.centroid() == centroid)
            #expect(graph.wienerIndex() == wiener)
            #expect(graph.averageShortestPathLength() == average)
            #expect(graph.density == density)
            let arcs = graph.directed.eccentricities()
            let viaArcs = (0 ..< n).map { arcs.eccentricity(ofIndex: $0) }
            #expect(viaArcs == ecc)
            #expect(graph.directed.wienerIndex() == wiener.map { 2 * $0 })
            #expect(graph.directed.density == density)
            // diameterPath: from the first vertex of greatest eccentricity to the first vertex
            // farthest from it, along the breadth-first parents.
            if let diameter {
                let u = ecc.firstIndex(of: diameter)!
                let tree = search(u)
                let v = tree.depth.firstIndex(of: diameter)!
                var vertices = [v]
                var path: [Int] = []
                while let p = tree.parent[vertices.last!], let e = tree.parentEdge[vertices.last!] {
                    path.append(e)
                    vertices.append(p)
                }
                let found = graph.diameterPath()
                #expect(found?.vertices == vertices.reversed().map { listed[$0] })
                #expect(found?.edges == Array(path.reversed()))
            } else {
                #expect(graph.diameterPath() == nil)
            }
        }
    }

    @Test("§E every unweighted directed measure equals breadth-first search over out-edges from every vertex, on random multigraphs with loops, shuffled rows and vertex orders")
    func directedUnweighted() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 0 ... 9), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, size, cycle, seed in
            let n = size
            // Optionally a directed Hamiltonian cycle first, so strongly connected digraphs occur.
            var arcs = cycle && n > 1 ? (0 ..< n).map { DirectedEdge(from: $0, to: ($0 + 1) % n) } : []
            if n > 0 { arcs += raw.map { DirectedEdge(from: $0.0 % n, to: $0.1 % n) } }
            let graph = ShuffledDigraph(vertexCount: n, edges: arcs, seed: seed)
            let listed = graph.vertices
            func search(_ s: Int) -> (depth: [Int?], parent: [Int?], parentEdge: [Int?]) {
                var depth = [Int?](repeating: nil, count: n)
                var parent = [Int?](repeating: nil, count: n)
                var parentEdge = [Int?](repeating: nil, count: n)
                depth[s] = 0
                var queue = [s]
                var head = 0
                while head < queue.count {
                    let x = queue[head]
                    head += 1
                    for e in graph.outEdges(of: listed[x]) {
                        let y = graph.vertexIndex(of: arcs[e].target)
                        if depth[y] == nil {
                            depth[y] = depth[x]! + 1
                            parent[y] = x
                            parentEdge[y] = e
                            queue.append(y)
                        }
                    }
                }
                return (depth, parent, parentEdge)
            }
            let all = (0 ..< n).map { search($0).depth }
            let ecc: [Int?] = all.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.max() }
            let totals: [Int?] = all.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.reduce(0, +) }
            let radius = ecc.compactMap { $0 }.min()
            let diameter = n == 0 || ecc.contains(nil) ? nil : ecc.compactMap { $0 }.max()
            let center = (0 ..< n).filter { ecc[$0] == radius }.map { listed[$0] }
            let periphery = (0 ..< n).filter { ecc[$0] == diameter }.map { listed[$0] }
            let leastTotal = totals.compactMap { $0 }.min()
            let centroid = (0 ..< n).filter { totals[$0] == leastTotal }.map { listed[$0] }
            var wiener: Int? = 0
            for u in 0 ..< n {
                for v in 0 ..< n where v != u {
                    if let d = all[u][v], let w = wiener { wiener = w + d } else { wiener = nil }
                }
            }
            let average: Double? = n == 0 ? nil : n == 1 ? 0 : wiener.map { Double($0) / Double(n * (n - 1)) }
            let density = n <= 1 ? 0 : Double(arcs.count) / Double(n * (n - 1))

            let eccentricities = graph.eccentricities()
            let byIndex = (0 ..< n).map { eccentricities.eccentricity(ofIndex: $0) }
            #expect(byIndex == ecc, "\(n) vertices, \(arcs), seed \(seed)")
            let byVertex = listed.map { eccentricities.eccentricity(of: $0) }
            #expect(byVertex == ecc)
            let oneByOne = listed.map { graph.eccentricity(of: $0) }
            #expect(oneByOne == ecc)
            #expect(eccentricities.radius == radius)
            #expect(eccentricities.diameter == diameter)
            #expect(eccentricities.center == center)
            #expect(eccentricities.periphery == periphery)
            #expect(graph.radius() == radius)
            #expect(graph.diameter() == diameter)
            #expect(graph.center() == center)
            #expect(graph.periphery() == periphery)
            #expect(graph.centroid() == centroid)
            #expect(graph.wienerIndex() == wiener)
            #expect(graph.averageShortestPathLength() == average)
            #expect(graph.density == density)
            if let diameter {
                let u = ecc.firstIndex(of: diameter)!
                let tree = search(u)
                let v = tree.depth.firstIndex(of: diameter)!
                var vertices = [v]
                var path: [Int] = []
                while let p = tree.parent[vertices.last!], let e = tree.parentEdge[vertices.last!] {
                    path.append(e)
                    vertices.append(p)
                }
                let found = graph.diameterPath()
                #expect(found?.vertices == vertices.reversed().map { listed[$0] })
                #expect(found?.edges == Array(path.reversed()))
            } else {
                #expect(graph.diameterPath() == nil)
            }
        }
    }

    @Test("§G every Int-weighted measure equals Floyd–Warshall, undirected and directed, zeros, loops and parallel copies included; diameterPath(weight:) joins the least diametral pair with a path of that weight; the closure is called once per edge in position order")
    func weightedInt() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 4)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 8), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, size, isDirected, seed in
            let n = size
            var ends: [(Int, Int)] = n > 1 ? (0 ..< n - 1).map { ($0, $0 + 1) } : []
            var w: [Int] = Array(repeating: 1, count: ends.count)
            if n > 0 {
                ends += raw.map { ($0.0 % n, $0.1 % n) }
                w += raw.map(\.2)
            }
            // Floyd–Warshall over the edge list, by vertex value (0..<n); nil is infinity.
            var d = [[Int?]](repeating: [Int?](repeating: nil, count: n), count: n)
            for i in 0 ..< n { d[i][i] = 0 }
            for (k, (a, b)) in ends.enumerated() where a != b {
                if d[a][b] == nil || w[k] < d[a][b]! { d[a][b] = w[k] }
                if !isDirected, d[b][a] == nil || w[k] < d[b][a]! { d[b][a] = w[k] }
            }
            for k in 0 ..< n {
                for i in 0 ..< n {
                    for j in 0 ..< n {
                        if let x = d[i][k], let y = d[k][j], d[i][j] == nil || x + y < d[i][j]! { d[i][j] = x + y }
                    }
                }
            }
            var calls: [Int] = []
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                let listed = graph.vertices
                let byIndex = listed.map { u in listed.map { v in d[u][v] } }
                let ecc: [Int?] = byIndex.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.max() }
                let totals: [Int?] = byIndex.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.reduce(0, +) }
                let radius = ecc.compactMap { $0 }.min()
                let diameter = n == 0 || ecc.contains(nil) ? nil : ecc.compactMap { $0 }.max()
                let leastTotal = totals.compactMap { $0 }.min()
                var wiener: Int? = 0
                for i in 0 ..< n {
                    for j in 0 ..< n where j != i {
                        if let x = byIndex[i][j], let t = wiener { wiener = t + x } else { wiener = nil }
                    }
                }
                let eccentricities = graph.eccentricities(weight: { calls.append($0); return w[$0] })
                #expect(calls == Array(0 ..< ends.count), "the closure once per edge, in position order")
                let got = (0 ..< n).map { eccentricities.eccentricity(ofIndex: $0) }
                #expect(got == ecc, "directed \(ends) weights \(w) seed \(seed)")
                #expect(eccentricities.radius == radius)
                #expect(eccentricities.diameter == diameter)
                #expect(graph.radius(weight: { w[$0] }) == radius)
                #expect(graph.diameter(weight: { w[$0] }) == diameter)
                #expect(graph.center(weight: { w[$0] }) == (0 ..< n).filter { ecc[$0] == radius }.map { listed[$0] })
                #expect(graph.periphery(weight: { w[$0] }) == (0 ..< n).filter { ecc[$0] == diameter }.map { listed[$0] })
                #expect(graph.centroid(weight: { w[$0] }) == (0 ..< n).filter { totals[$0] == leastTotal }.map { listed[$0] })
                #expect(graph.wienerIndex(weight: { w[$0] }) == wiener)
                let one = listed.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
                #expect(one == ecc)
                if let diameter {
                    let result = graph.diameterPath(weight: { w[$0] })
                    #expect(result?.distance == diameter)
                    let u = ecc.firstIndex(of: diameter)!
                    let v = byIndex[u].firstIndex(of: diameter)!
                    #expect(result?.path.vertices.first == listed[u])
                    #expect(result?.path.vertices.last == listed[v])
                    if let result {
                        var total = 0
                        for (k, e) in result.path.edges.enumerated() {
                            #expect(ends[e].0 == result.path.vertices[k] && ends[e].1 == result.path.vertices[k + 1])
                            total += w[e]
                        }
                        #expect(total == diameter)
                    }
                } else {
                    #expect(graph.diameterPath(weight: { w[$0] }) == nil)
                }
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let listed = graph.vertices
                let byIndex = listed.map { u in listed.map { v in d[u][v] } }
                let ecc: [Int?] = byIndex.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.max() }
                let totals: [Int?] = byIndex.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.reduce(0, +) }
                let radius = ecc.compactMap { $0 }.min()
                let diameter = n == 0 || ecc.contains(nil) ? nil : ecc.compactMap { $0 }.max()
                let leastTotal = totals.compactMap { $0 }.min()
                var wiener: Int? = 0
                for i in 0 ..< n {
                    for j in i + 1 ..< n {
                        if let x = byIndex[i][j], let t = wiener { wiener = t + x } else { wiener = nil }
                    }
                }
                let eccentricities = graph.eccentricities(weight: { calls.append($0); return w[$0] })
                #expect(calls == Array(0 ..< ends.count), "the closure once per edge, in position order")
                let got = (0 ..< n).map { eccentricities.eccentricity(ofIndex: $0) }
                #expect(got == ecc, "undirected \(ends) weights \(w) seed \(seed)")
                #expect(eccentricities.radius == radius)
                #expect(eccentricities.diameter == diameter)
                #expect(graph.radius(weight: { w[$0] }) == radius)
                #expect(graph.diameter(weight: { w[$0] }) == diameter)
                #expect(graph.center(weight: { w[$0] }) == (0 ..< n).filter { ecc[$0] == radius }.map { listed[$0] })
                #expect(graph.periphery(weight: { w[$0] }) == (0 ..< n).filter { ecc[$0] == diameter }.map { listed[$0] })
                #expect(graph.centroid(weight: { w[$0] }) == (0 ..< n).filter { totals[$0] == leastTotal }.map { listed[$0] })
                #expect(graph.wienerIndex(weight: { w[$0] }) == wiener)
                let one = listed.map { graph.eccentricity(of: $0, weight: { w[$0] }) }
                #expect(one == ecc)
                let arcs = graph.directed.eccentricities(weight: { w[$0.position] })
                let viaArcs = (0 ..< n).map { arcs.eccentricity(ofIndex: $0) }
                #expect(viaArcs == ecc)
                if let diameter {
                    let result = graph.diameterPath(weight: { w[$0] })
                    #expect(result?.distance == diameter)
                    let u = ecc.firstIndex(of: diameter)!
                    let v = byIndex[u].firstIndex(of: diameter)!
                    #expect(result?.path.vertices.first == listed[u])
                    #expect(result?.path.vertices.last == listed[v])
                    if let result {
                        var total = 0
                        for (k, e) in result.path.edges.enumerated() {
                            let (a, b) = ends[e]
                            let (x, y) = (result.path.vertices[k], result.path.vertices[k + 1])
                            #expect((a == x && b == y) || (a == y && b == x))
                            total += w[e]
                        }
                        #expect(total == diameter)
                    }
                } else {
                    #expect(graph.diameterPath(weight: { w[$0] }) == nil)
                }
            }
        }
    }

    @Test("§G Double-weighted (quarters, zeros included) eccentricities, extrema, centroid, Wiener index and average equal Floyd–Warshall, undirected and directed")
    func weightedDouble() async {
        let triples = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 8)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 7), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, size, isDirected, seed in
            let n = size
            var ends: [(Int, Int)] = n > 1 ? (0 ..< n - 1).map { ($0, $0 + 1) } : []
            var w: [Double] = Array(repeating: 0.5, count: ends.count)
            if n > 0 {
                ends += raw.map { ($0.0 % n, $0.1 % n) }
                w += raw.map { Double($0.2) / 4 }
            }
            var d = [[Double?]](repeating: [Double?](repeating: nil, count: n), count: n)
            for i in 0 ..< n { d[i][i] = 0 }
            for (k, (a, b)) in ends.enumerated() where a != b {
                if d[a][b] == nil || w[k] < d[a][b]! { d[a][b] = w[k] }
                if !isDirected, d[b][a] == nil || w[k] < d[b][a]! { d[b][a] = w[k] }
            }
            for k in 0 ..< n {
                for i in 0 ..< n {
                    for j in 0 ..< n {
                        if let x = d[i][k], let y = d[k][j], d[i][j] == nil || x + y < d[i][j]! { d[i][j] = x + y }
                    }
                }
            }
            let listed: [Int]
            let ecc: [Double?]
            let got: [Double?]
            let center: [Int]
            let periphery: [Int]
            let centroid: [Int]
            let wiener: Double?
            let average: Double?
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                listed = graph.vertices
                let e = graph.eccentricities(weight: { w[$0] })
                got = (0 ..< n).map { e.eccentricity(ofIndex: $0) }
                center = graph.center(weight: { w[$0] })
                periphery = graph.periphery(weight: { w[$0] })
                centroid = graph.centroid(weight: { w[$0] })
                wiener = graph.wienerIndex(weight: { w[$0] })
                average = graph.averageShortestPathLength(weight: { w[$0] })
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                listed = graph.vertices
                let e = graph.eccentricities(weight: { w[$0] })
                got = (0 ..< n).map { e.eccentricity(ofIndex: $0) }
                center = graph.center(weight: { w[$0] })
                periphery = graph.periphery(weight: { w[$0] })
                centroid = graph.centroid(weight: { w[$0] })
                wiener = graph.wienerIndex(weight: { w[$0] })
                average = graph.averageShortestPathLength(weight: { w[$0] })
            }
            let byIndex = listed.map { u in listed.map { v in d[u][v] } }
            ecc = byIndex.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.max() }
            let totals: [Double?] = byIndex.map { row in row.contains(nil) ? nil : row.compactMap { $0 }.reduce(0, +) }
            let radius = ecc.compactMap { $0 }.min()
            let diameter = n == 0 || ecc.contains(nil) ? nil : ecc.compactMap { $0 }.max()
            let leastTotal = totals.compactMap { $0 }.min()
            var sum: Double? = 0
            for i in 0 ..< n {
                for j in 0 ..< n where j != i && (isDirected || j > i) {
                    if let x = byIndex[i][j], let t = sum { sum = t + x } else { sum = nil }
                }
            }
            let pairs = isDirected ? n * (n - 1) : n * (n - 1) / 2
            let expectedAverage: Double? = n == 0 ? nil : n == 1 ? 0 : sum.map { $0 / Double(pairs) }
            #expect(got == ecc, "\(isDirected ? "directed" : "undirected") \(ends) weights \(w) seed \(seed)")
            #expect(center == (0 ..< n).filter { ecc[$0] == radius }.map { listed[$0] })
            #expect(periphery == (0 ..< n).filter { ecc[$0] == diameter }.map { listed[$0] })
            #expect(centroid == (0 ..< n).filter { totals[$0] == leastTotal }.map { listed[$0] })
            #expect(wiener == sum)
            #expect(average == expectedAverage)
        }
    }

    @Test("DI-910 the bounding algorithm's shapes (paths, cycles, complete and complete bipartite graphs, grids, stars, wheels) of random sizes, shuffled, on UndirectedAdjacencyList: one-shot extrema and eccentricities equal BFS from every vertex")
    func boundingShapes() async {
        await propertyCheck(count: 200, input: Gen.int(in: 0 ... 6), Gen.int(in: 1 ... 24), Gen.int(in: 1 ... 6), Gen.int(in: 0 ... 1_000_000)) { shape, a, b, seed in
            var pairs: [(Int, Int)]
            var count: Int
            switch shape {
            case 0:
                count = a
                pairs = (0 ..< a - 1).map { ($0, $0 + 1) }
            case 1:
                count = a + 2
                pairs = (0 ..< a + 1).map { ($0, $0 + 1) } + [(a + 1, 0)]
            case 2:
                count = min(a, 12)
                pairs = (0 ..< count).flatMap { i in (i + 1 ..< count).map { (i, $0) } }
            case 3:
                count = a + b
                pairs = (0 ..< b).flatMap { i in (b ..< a + b).map { (i, $0) } }
            case 4:
                let columns = min(a, 8)
                count = columns * b
                pairs = (0 ..< count).flatMap { v -> [(Int, Int)] in
                    (v % columns + 1 < columns ? [(v, v + 1)] : []) + (v / columns + 1 < b ? [(v, v + columns)] : [])
                }
            case 5:
                count = a + 1
                pairs = (1 ... a).map { (0, $0) }
            default:
                count = a + 3
                pairs = (1 ... a + 2).map { (0, $0) } + (1 ..< a + 2).map { ($0, $0 + 1) } + [(a + 2, 1)]
            }
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< count) : Array(0 ..< count).shuffled(using: &rng)
            let graph = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let order = Array(graph.vertices)
            var adjacency = [Int: [Int]]()
            for (u, v) in pairs {
                adjacency[u, default: []].append(v)
                adjacency[v, default: []].append(u)
            }
            let ecc: [Int?] = order.map { s in
                var depth = [s: 0]
                var queue = [s]
                var head = 0
                while head < queue.count {
                    let x = queue[head]
                    head += 1
                    for y in adjacency[x, default: []] where depth[y] == nil {
                        depth[y] = depth[x]! + 1
                        queue.append(y)
                    }
                }
                return depth.count == count ? depth.values.max() : nil
            }
            let radius = ecc.compactMap { $0 }.min()
            let diameter = ecc.contains(nil) ? nil : ecc.compactMap { $0 }.max()
            let center = order.indices.filter { ecc[$0] == radius }.map { order[$0] }
            let periphery = order.indices.filter { ecc[$0] == diameter }.map { order[$0] }
            #expect(graph.diameter() == diameter, "shape \(shape), \(a), \(b), seed \(seed)")
            #expect(graph.radius() == radius)
            #expect(graph.center() == center)
            #expect(graph.periphery() == periphery)
            let eccentricities = graph.eccentricities()
            let got = order.indices.map { eccentricities.eccentricity(ofIndex: $0) }
            #expect(got == ecc)
            #expect(eccentricities.center == center)
            #expect(eccentricities.periphery == periphery)
            #expect(graph.diameterPath()?.length == diameter)
        }
    }

    @Test("§C on random trees Distances equals TreeAlgorithms: center, centroid, diameter and diameterPath, unweighted and with Int weights (zeros included), on the ReferencePseudograph and on the Tree read as a Graph")
    func treeAgreement() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 14)
        let weights = Gen.int(in: 0 ... 3).array(of: 14)
        await propertyCheck(count: 200, input: choices, weights, Gen.int(in: 0 ... 1_000_000)) { choice, w, seed in
            let n = choice.count + 1
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            var pairs = (0 ..< choice.count).map { (choice[$0] % ($0 + 1), $0 + 1) }
            if seed != 0 {
                pairs.shuffle(using: &rng)
                pairs = pairs.map { Bool.random(using: &rng) ? ($0.1, $0.0) : $0 }
            }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            guard let tree = Tree(graph) else {
                Issue.record("not a tree: \(pairs)")
                return
            }
            func onGraphCenter<G: Graph>(_ g: G) -> [G.Vertex] { g.center() }
            func onGraphCentroid<G: Graph>(_ g: G) -> [G.Vertex] { g.centroid() }
            func onGraphDiameter<G: Graph>(_ g: G) -> Int? { g.diameter() }
            func onGraphPath<G: Graph>(_ g: G) -> Path<G.Vertex, G.Edges.Index>? { g.diameterPath() }
            #expect(graph.center() == tree.center(), "\(pairs), listed \(listed)")
            #expect(onGraphCenter(tree) == tree.center())
            #expect(graph.centroid() == tree.centroid())
            #expect(onGraphCentroid(tree) == tree.centroid())
            #expect(graph.diameter() == tree.diameter())
            #expect(onGraphDiameter(tree) == tree.diameter())
            #expect(graph.diameterPath() == tree.diameterPath())
            #expect(onGraphPath(tree) == tree.diameterPath())
            #expect(graph.center(weight: { w[$0] }) == tree.center(weight: { w[$0] }))
            #expect(graph.diameter(weight: { w[$0] }) == tree.diameter(weight: { w[$0] }))
            let ours = graph.diameterPath(weight: { w[$0] })
            let theirs = tree.diameterPath(weight: { w[$0] })
            #expect(ours?.distance == theirs.distance)
            #expect(ours?.path == theirs.path)
        }
    }

    @Test("§E views: digraph.undirected has the eccentricities, Wiener index and density of the same arcs as edges; graph.directed has the eccentricities, average and density of graph and twice its Wiener index")
    func views() async {
        let pairs = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 1 ... 7)) { raw, n in
            let arcs = raw.map { DirectedEdge(from: $0.0 % n, to: $0.1 % n) }
            let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: arcs)
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: arcs.map { UndirectedEdge($0.source, $0.target) })
            let viaView = digraph.undirected.eccentricities()
            let direct = graph.eccentricities()
            let a = (0 ..< n).map { viaView.eccentricity(ofIndex: $0) }
            let b = (0 ..< n).map { direct.eccentricity(ofIndex: $0) }
            #expect(a == b, "\(arcs)")
            #expect(digraph.undirected.wienerIndex() == graph.wienerIndex())
            #expect(digraph.undirected.density == graph.density)
            #expect(digraph.undirected.density == 2 * digraph.density)
            let arcsView = graph.directed.eccentricities()
            let c = (0 ..< n).map { arcsView.eccentricity(ofIndex: $0) }
            #expect(c == b)
            #expect(graph.directed.wienerIndex() == graph.wienerIndex().map { 2 * $0 })
            #expect(graph.directed.averageShortestPathLength() == graph.averageShortestPathLength())
            #expect(graph.directed.density == graph.density)
            #expect(graph.directed.center() == graph.center())
            #expect(graph.directed.periphery() == graph.periphery())
            #expect(graph.directed.centroid() == graph.centroid())
        }
    }
}
