// Properties against oracles written inside each test, with shrinking (swift-property-based).
// Graphs are multigraphs with self-loops on up to 9 vertices, listed in a seeded order (seed 0
// keeps 0, 1, 2, …) with incidence or out-edge rows shuffled by the same seed, so lookups by index
// and by value differ. The oracles read only the edge list, by vertex value: the pairs at the ends
// of every edge (both directions undirected, a self-loop twice; every arc once directed) for the
// coefficients, sums over the same ends for the neighbor degrees, sets of ordered pairs for
// reciprocity, and every vertex triple classified by its least code under the six relabelings for
// the triadic census. Doubles are compared within 1e-9.

import Assortativity
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

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
/// out- and in-edge rows (built in position order) shuffled by the same seed, unless the seed is 0.
private struct ShuffledDigraph: BidirectionalDirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    private let index: [Int]
    private let rows: [[Int]]
    private let inRows: [[Int]]

    init(vertexCount: Int, edges: [DirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount), inRows = rows
        for (k, edge) in edges.enumerated() {
            rows[edge.source].append(k)
            inRows[edge.target].append(k)
        }
        var listed = Array(0 ..< vertexCount)
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
            inRows = inRows.map { $0.shuffled(using: &rng) }
            listed.shuffle(using: &rng)
        }
        var index = [Int](repeating: 0, count: vertexCount)
        for (i, v) in listed.enumerated() { index[v] = i }
        self.vertices = listed
        self.edges = edges
        self.index = index
        self.rows = rows
        self.inRows = inRows
    }

    func outEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func inEdges(of vertex: Int) -> [Int] { inRows[vertex] }
    func successors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].target } }
    func predecessors(of vertex: Int) -> [Int] { inRows[vertex].map { edges[$0].source } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { index[vertex] }
    func vertex(atIndex i: Int) -> Int { vertices[i] }
}

@Suite("Assortativity properties against oracles, with shrinking", .tags(.randomized))
struct AssortativityPropertyTests {
    @Test("Degree, attribute and numeric coefficients equal Pearson's r and Newman's r over the oracle's edge-end pairs")
    func coefficients() async {
        let triples = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 4)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 9), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = n == 0 ? [] : raw.map { Double($0.2) / 4 }
            let value: [Double] = (0 ..< n).map { Double(($0 * 7 + 3) % 5) }
            let classOf: [Int] = (0 ..< n).map { ($0 * 5 + seed) % 3 }
            // Pairs (tail vertex, head vertex, edge) as the oracle reads them.
            var pairs: [(Int, Int, Int)] = []
            for (k, (a, b)) in ends.enumerated() {
                pairs.append((a, b, k))
                if !isDirected { pairs.append((b, a, k)) }
            }
            var outDegree = [Double](repeating: 0, count: n), inDegree = outDegree
            var outStrength = outDegree, inStrength = outDegree
            for (k, (a, b)) in ends.enumerated() {
                outDegree[a] += 1
                inDegree[b] += 1
                outStrength[a] += w[k]
                inStrength[b] += w[k]
            }
            func pearson(_ xs: [Double], _ ys: [Double]) -> Double? {
                guard let x0 = xs.first, let y0 = ys.first, xs.contains(where: { $0 != x0 }), ys.contains(where: { $0 != y0 }) else { return nil }
                let mx = xs.reduce(0, +) / Double(xs.count), my = ys.reduce(0, +) / Double(ys.count)
                var c = 0.0, vx = 0.0, vy = 0.0
                for i in xs.indices {
                    c += (xs[i] - mx) * (ys[i] - my)
                    vx += (xs[i] - mx) * (xs[i] - mx)
                    vy += (ys[i] - my) * (ys[i] - my)
                }
                return c / (vx * vy).squareRoot()
            }
            func newman() -> Double? {
                guard !pairs.isEmpty else { return nil }
                let m = Double(pairs.count)
                var trace = 0.0
                var first = [Double](repeating: 0, count: 3), second = first
                for (a, b, _) in pairs {
                    if classOf[a] == classOf[b] { trace += 1 / m }
                    first[classOf[a]] += 1 / m
                    second[classOf[b]] += 1 / m
                }
                let s = (0 ..< 3).map { first[$0] * second[$0] }.reduce(0, +)
                guard abs(1 - s) > 1e-12 else { return nil }
                return (trace - s) / (1 - s)
            }
            func agree(_ mine: Double?, _ theirs: Double?) -> Bool {
                switch (mine, theirs) {
                case (nil, nil): true
                case let (a?, b?): abs(a - b) <= 1e-9
                default: false
                }
            }
            func degrees(_ type: DegreeType, _ outs: [Double], _ ins: [Double]) -> [Double] {
                switch type {
                case .in: ins
                case .out: outs
                case .total: zip(outs, ins).map { $0 + $1 }
                }
            }
            let numeric = pearson(pairs.map { value[$0.0] }, pairs.map { value[$0.1] })
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                for source in DegreeType.allCases {
                    for target in DegreeType.allCases {
                        let xs = degrees(source, outDegree, inDegree), ys = degrees(target, outDegree, inDegree)
                        let expected = pearson(pairs.map { xs[$0.0] }, pairs.map { ys[$0.1] })
                        let mine = graph.degreeAssortativityCoefficient(source: source, target: target)
                        #expect(agree(mine, expected), "\(ends) \(source) \(target): \(String(describing: mine)) vs \(String(describing: expected))")
                        let sx = degrees(source, outStrength, inStrength), sy = degrees(target, outStrength, inStrength)
                        let weighted = pearson(pairs.map { sx[$0.0] }, pairs.map { sy[$0.1] })
                        let mineWeighted = graph.degreeAssortativityCoefficient(source: source, target: target, weight: { w[$0] })
                        #expect(agree(mineWeighted, weighted), "\(ends) weighted \(source) \(target)")
                    }
                }
                let mineNumeric = graph.numericAssortativityCoefficient(attribute: { value[$0] })
                #expect(agree(mineNumeric, numeric), "\(ends) numeric")
                let mineClasses = graph.attributeAssortativityCoefficient(attribute: { classOf[$0] })
                #expect(agree(mineClasses, newman()), "\(ends) attribute")
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let d = zip(outDegree, inDegree).map { $0 + $1 }, s = zip(outStrength, inStrength).map { $0 + $1 }
                let expected = pearson(pairs.map { d[$0.0] }, pairs.map { d[$0.1] })
                #expect(agree(graph.degreeAssortativityCoefficient(), expected), "\(ends)")
                let weighted = pearson(pairs.map { s[$0.0] }, pairs.map { s[$0.1] })
                let mineWeighted = graph.degreeAssortativityCoefficient(weight: { w[$0] })
                #expect(agree(mineWeighted, weighted), "\(ends) weighted")
                let mineNumeric = graph.numericAssortativityCoefficient(attribute: { value[$0] })
                #expect(agree(mineNumeric, numeric), "\(ends) numeric")
                let mineClasses = graph.attributeAssortativityCoefficient(attribute: { classOf[$0] })
                #expect(agree(mineClasses, newman()), "\(ends) attribute")
                // The directed view reads every edge both ways, a loop twice: the same pairs.
                let view = graph.directedView
                #expect(agree(view.degreeAssortativityCoefficient(source: .out, target: .out), expected), "\(ends) view")
            }
        }
    }

    @Test("Average neighbor degrees and k_nn equal sums over the oracle's edge ends")
    func neighborDegrees() async {
        let triples = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 4)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 9), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = n == 0 ? [] : raw.map { Double($0.2) / 4 }
            var outDegree = [Double](repeating: 0, count: n), inDegree = outDegree
            for (a, b) in ends {
                outDegree[a] += 1
                inDegree[b] += 1
            }
            // Each vertex's (neighbor, edge) list for a source type.
            func incident(_ type: DegreeType, directed: Bool) -> [[(Int, Int)]] {
                var lists = [[(Int, Int)]](repeating: [], count: n)
                for (k, (a, b)) in ends.enumerated() {
                    if !directed || type != .in { lists[a].append((b, k)) }
                    if !directed || type != .out { lists[b].append((a, k)) }
                }
                return lists
            }
            func degrees(_ type: DegreeType) -> [Double] {
                switch type {
                case .in: inDegree
                case .out: outDegree
                case .total: zip(outDegree, inDegree).map { $0 + $1 }
                }
            }
            func expected(_ lists: [[(Int, Int)]], _ k: [Double], weighted: Bool) -> (averages: [Double], connectivity: [Int: Double]) {
                var averages: [Double] = [], sum: [Int: Double] = [:], norm: [Int: Double] = [:]
                for v in 0 ..< n {
                    let s = lists[v].map { weighted ? w[$0.1] : 1 }.reduce(0, +)
                    let total = lists[v].map { (weighted ? w[$0.1] : 1) * k[$0.0] }.reduce(0, +)
                    averages.append(s == 0 ? 0 : total / s)
                    sum[lists[v].count, default: 0] += total
                    norm[lists[v].count, default: 0] += s
                }
                var connectivity: [Int: Double] = [:]
                for (key, total) in sum { connectivity[key] = norm[key]! == 0 ? total : total / norm[key]! }
                return (averages, connectivity)
            }
            func close(_ a: [Double], _ b: [Double]) -> Bool { a.count == b.count && zip(a, b).allSatisfy { abs($0 - $1) <= 1e-9 } }
            func close(_ a: [Int: Double], _ b: [Int: Double]) -> Bool { Set(a.keys) == Set(b.keys) && a.keys.allSatisfy { abs(a[$0]! - b[$0]!) <= 1e-9 } }
            if isDirected {
                let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
                for source in DegreeType.allCases {
                    for target in DegreeType.allCases {
                        let lists = incident(source, directed: true)
                        let plain = expected(lists, degrees(target), weighted: false)
                        let averages = graph.averageNeighborDegrees(source: source, target: target)
                        let byValue = (0 ..< n).map { averages.averageNeighborDegree(of: $0) }
                        #expect(close(byValue, plain.averages), "\(ends) \(source) \(target)")
                        let byIndex = graph.vertices.map { plain.averages[$0] }
                        #expect(close(averages.values, byIndex), "\(ends) \(source) \(target) by index")
                        #expect(close(graph.averageDegreeConnectivity(source: source, target: target), plain.connectivity), "\(ends) knn \(source) \(target)")
                        let weighted = expected(lists, degrees(target), weighted: true)
                        let weightedAverages = graph.averageNeighborDegrees(source: source, target: target, weight: { w[$0] })
                        let weightedByValue = (0 ..< n).map { weightedAverages.averageNeighborDegree(of: $0) }
                        #expect(close(weightedByValue, weighted.averages), "\(ends) weighted \(source) \(target)")
                        let weightedConnectivity = graph.averageDegreeConnectivity(source: source, target: target, weight: { w[$0] })
                        #expect(close(weightedConnectivity, weighted.connectivity), "\(ends) weighted knn")
                    }
                }
            } else {
                let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
                let lists = incident(.total, directed: false)
                let total = degrees(.total)
                let plain = expected(lists, total, weighted: false)
                let averages = graph.averageNeighborDegrees()
                let byValue = (0 ..< n).map { averages.averageNeighborDegree(of: $0) }
                #expect(close(byValue, plain.averages), "\(ends)")
                #expect(close(graph.averageDegreeConnectivity(), plain.connectivity), "\(ends) knn")
                let weighted = expected(lists, total, weighted: true)
                let weightedAverages = graph.averageNeighborDegrees(weight: { w[$0] })
                let weightedByValue = (0 ..< n).map { weightedAverages.averageNeighborDegree(of: $0) }
                #expect(close(weightedByValue, weighted.averages), "\(ends) weighted")
                let weightedConnectivity = graph.averageDegreeConnectivity(weight: { w[$0] })
                #expect(close(weightedConnectivity, weighted.connectivity), "\(ends) weighted knn")
            }
        }
    }

    @Test("Reciprocity, the triadic census, histograms and regularity against the oracle's simple digraph")
    func directedCounts() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledDigraph(vertexCount: n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
            var arc = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
            for (a, b) in ends where a != b { arc[a][b] = true }
            // Reciprocity.
            var arcs = 0, reciprocated = 0
            for a in 0 ..< n { for b in 0 ..< n where arc[a][b] {
                arcs += 1
                if arc[b][a] { reciprocated += 1 }
            } }
            let overall = graph.reciprocity()
            #expect(overall == (arcs == 0 ? nil : Double(reciprocated) / Double(arcs)), "\(ends)")
            for v in 0 ..< n {
                let out = (0 ..< n).filter { arc[v][$0] }, into = (0 ..< n).filter { arc[$0][v] }
                let shared = out.filter { arc[$0][v] }.count
                let expected: Double? = out.count + into.count == 0 ? nil : Double(2 * shared) / Double(out.count + into.count)
                #expect(graph.reciprocity(of: v) == expected, "\(ends) vertex \(v)")
            }
            // The census: each triple's least 6-bit code under the relabelings, named by the
            // least code of each type's realization.
            func code(_ a: Int, _ b: Int, _ c: Int, _ adjacent: (Int, Int) -> Bool) -> Int {
                (adjacent(a, b) ? 1 : 0) + (adjacent(b, a) ? 2 : 0) + (adjacent(a, c) ? 4 : 0) + (adjacent(c, a) ? 8 : 0) + (adjacent(b, c) ? 16 : 0) + (adjacent(c, b) ? 32 : 0)
            }
            func least(_ a: Int, _ b: Int, _ c: Int, _ adjacent: (Int, Int) -> Bool) -> Int {
                [code(a, b, c, adjacent), code(a, c, b, adjacent), code(b, a, c, adjacent), code(b, c, a, adjacent), code(c, a, b, adjacent), code(c, b, a, adjacent)].min()!
            }
            let realizations: [[(Int, Int)]] = [
                [], [(0, 1)], [(0, 1), (1, 0)], [(0, 1), (0, 2)], [(1, 0), (2, 0)], [(0, 1), (1, 2)],
                [(0, 1), (1, 0), (2, 1)], [(0, 1), (1, 0), (1, 2)], [(0, 1), (1, 2), (0, 2)], [(0, 1), (1, 2), (2, 0)],
                [(0, 1), (1, 0), (0, 2), (2, 0)], [(0, 1), (0, 2), (1, 2), (2, 1)], [(1, 0), (2, 0), (1, 2), (2, 1)],
                [(0, 1), (1, 2), (0, 2), (2, 0)], [(0, 1), (1, 0), (0, 2), (2, 0), (1, 2)], [(0, 1), (1, 0), (0, 2), (2, 0), (1, 2), (2, 1)],
            ]
            var typeOfCode: [Int: Int] = [:]
            for (t, realization) in realizations.enumerated() {
                func adjacent(_ x: Int, _ y: Int) -> Bool { realization.contains { $0 == (x, y) } }
                typeOfCode[least(0, 1, 2, adjacent)] = t
            }
            func inGraph(_ x: Int, _ y: Int) -> Bool { arc[x][y] }
            var counts = [Int](repeating: 0, count: 16)
            for a in 0 ..< n { for b in a + 1 ..< max(n, a + 1) { for c in b + 1 ..< max(n, b + 1) {
                counts[typeOfCode[least(a, b, c, inGraph)]!] += 1
            } } }
            let census = graph.triadicCensus()
            #expect(census.counts == counts, "\(ends)")
            // Histograms and regularity over every arc.
            var outCount = [Int](repeating: 0, count: n), inCount = outCount
            for (a, b) in ends {
                outCount[a] += 1
                inCount[b] += 1
            }
            func histogram(_ values: [Int]) -> [Int] {
                guard let top = values.max() else { return [] }
                return (0 ... top).map { d in values.filter { $0 == d }.count }
            }
            #expect(graph.outDegreeHistogram() == histogram(outCount), "\(ends)")
            #expect(graph.inDegreeHistogram() == histogram(inCount), "\(ends)")
            let regular = Set(outCount).count <= 1 && Set(inCount).count <= 1
            #expect(graph.isRegular == regular, "\(ends)")
        }
    }

    @Test("Histograms, regularity, the s-metric and the rich club against the oracle's degrees")
    func undirectedCounts() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var degree = [Int](repeating: 0, count: n)
            for (a, b) in ends {
                degree[a] += 1
                degree[b] += 1
            }
            let histogram: [Int] = degree.max().map { top in (0 ... top).map { d in degree.filter { $0 == d }.count } } ?? []
            #expect(graph.degreeHistogram() == histogram, "\(ends)")
            #expect(graph.isRegular == (Set(degree).count <= 1), "\(ends)")
            for k in 0 ... 4 {
                let expected = degree.allSatisfy { $0 == k }
                #expect(graph.isRegular(degree: k) == expected, "\(ends) k = \(k)")
            }
            let s = ends.map { degree[$0.0] * degree[$0.1] }.reduce(0, +)
            #expect(graph.sMetric() == s, "\(ends)")
            // Rich club on the simple graph.
            var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
            for (a, b) in ends where a != b {
                adjacent[a][b] = true
                adjacent[b][a] = true
            }
            let simple = (0 ..< n).map { v in (0 ..< n).filter { adjacent[v][$0] }.count }
            var rich: [Double] = []
            let hasEdge = simple.contains { $0 > 0 }
            var k = 0
            while hasEdge {
                let members = (0 ..< n).filter { simple[$0] > k }
                guard members.count > 1 else { break }
                var edges = 0
                for i in members.indices { for j in members.indices where j > i && adjacent[members[i]][members[j]] { edges += 1 } }
                rich.append(Double(2 * edges) / (Double(members.count) * Double(members.count - 1)))
                k += 1
            }
            #expect(graph.richClubCoefficients() == rich, "\(ends)")
        }
    }
}
