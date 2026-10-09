// Properties against brute force, with shrinking (swift-property-based): on a failure, PropertyBased
// shrinks the generated edge list (and the row-shuffling seed, towards 0, which keeps rows in
// position order) and prints the smallest input that still fails. Graphs are multigraphs with
// self-loops on the vertices 0..<n, so every op must read the simple graph underneath. Every oracle
// is written inside its test: every vertex subset as a bitmask for the maximal cliques and the
// maximum clique, repeated deletion of low-degree vertices (peeling) for core numbers, api.md's
// Batagelj–Zaversnik steps replayed on the simple rows for the degeneracy ordering, and every vertex
// triple for triangles, from which clustering, transitivity and the average follow by api.md's
// formulas (compared exactly: each is the same rational, correctly rounded, or the same plain sum).
// The maximal cliques are compared as a set; their order is api.md's algorithm's, which these
// oracles do not replay.

import AdjacencyListModule
import Cliques
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

/// An undirected multigraph on 0..<vertexCount whose incidence rows (built in position order, a
/// self-loop twice) are shuffled by a seeded generator, unless the seed is 0. Vertex and edge
/// indices are the vertices and positions themselves.
private struct ShuffledPseudograph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            rows[edge.u].append(k)
            rows[edge.v].append(k)
        }
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
        }
        self.vertices = Array(0 ..< vertexCount)
        self.edges = edges
        self.rows = rows
    }

    func incidentEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func neighbors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

@Suite("Clique, core and triangle properties against brute force, with shrinking", .tags(.randomized))
struct CliquePropertyTests {
    @Test("maximalCliques() is every vertex subset that is a clique and that no outside vertex extends, each once, in vertices order; loops and parallel edges ignored")
    func maximalCliquesAgainstSubsets() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 8), edges, Gen.int(in: 0 ... 1_000_000)) { n, raw, seed in
            let pairs = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            // Neighbour bitmasks of the simple graph.
            var neighbours = [Int](repeating: 0, count: n)
            for (a, b) in pairs where a != b {
                neighbours[a] |= 1 << b
                neighbours[b] |= 1 << a
            }
            var expected = Set<[Int]>()
            for mask in 1 ..< max(1, 1 << n) {
                let members = (0 ..< n).filter { mask & (1 << $0) != 0 }
                let isClique = members.allSatisfy { (mask & ~(1 << $0)) & ~neighbours[$0] == 0 }
                let isMaximal = (0 ..< n).allSatisfy { w in mask & (1 << w) != 0 || mask & ~neighbours[w] != 0 }
                if isClique && isMaximal { expected.insert(members) }
            }
            let cliques = Array(graph.maximalCliques())
            #expect(Set(cliques) == expected)
            #expect(cliques.count == expected.count)
            // Iterating again gives the same sequence.
            let again = Array(graph.maximalCliques())
            #expect(again == cliques)
        }
    }

    @Test("maximumClique() is the lexicographically least largest clique by index, cliqueNumber() its size, at most degeneracy + 1")
    func maximumCliqueAgainstSubsets() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 8), edges, Gen.int(in: 0 ... 1_000_000)) { n, raw, seed in
            let pairs = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var neighbours = [Int](repeating: 0, count: n)
            for (a, b) in pairs where a != b {
                neighbours[a] |= 1 << b
                neighbours[b] |= 1 << a
            }
            // Every clique, then the largest, then the lexicographically least of those.
            var best: [Int] = []
            for mask in 1 ..< max(1, 1 << n) {
                let members = (0 ..< n).filter { mask & (1 << $0) != 0 }
                guard members.allSatisfy({ (mask & ~(1 << $0)) & ~neighbours[$0] == 0 }) else { continue }
                if members.count > best.count || (members.count == best.count && members.lexicographicallyPrecedes(best)) {
                    best = members
                }
            }
            #expect(graph.maximumClique() == best)
            #expect(graph.cliqueNumber() == best.count)
            let degeneracy = graph.coreNumbers().degeneracy
            #expect(graph.cliqueNumber() <= degeneracy + 1)
        }
    }

    @Test("coreNumbers() is peeling: core(v) is the largest k for which v survives deleting vertices of fewer than k distinct neighbours; degeneracy, kCore and kShell follow")
    func coreNumbersAgainstPeeling() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 9), edges, Gen.int(in: 0 ... 1_000_000)) { n, raw, seed in
            let pairs = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var adjacent = [Set<Int>](repeating: [], count: n)
            for (a, b) in pairs where a != b {
                adjacent[a].insert(b)
                adjacent[b].insert(a)
            }
            var expected = [Int](repeating: 0, count: n)
            var k = 0
            while true {
                var alive = Set(0 ..< n)
                var changed = true
                while changed {
                    changed = false
                    for v in alive where adjacent[v].intersection(alive).count < k {
                        alive.remove(v)
                        changed = true
                    }
                }
                if alive.isEmpty { break }
                for v in alive { expected[v] = k }
                k += 1
            }
            let cores = graph.coreNumbers()
            let byIndex = (0 ..< n).map { cores.coreNumber(ofIndex: $0) }
            #expect(byIndex == expected)
            let byVertex = graph.vertices.map { cores.coreNumber(of: $0) }
            #expect(byVertex == expected)
            let degeneracy = expected.max() ?? 0
            #expect(cores.degeneracy == degeneracy)
            for k in 0 ... degeneracy + 1 {
                let core = (0 ..< n).filter { expected[$0] >= k }
                #expect(cores.kCore(k) == core, "k = \(k)")
                let shell = (0 ..< n).filter { expected[$0] == k }
                #expect(cores.kShell(k) == shell, "k = \(k)")
            }
            // The degeneracy ordering: every vertex once, at most core(v) neighbours after each v,
            // core numbers nondecreasing along it.
            let ordering = cores.degeneracyOrdering
            #expect(ordering.sorted() == Array(0 ..< n))
            for (i, v) in ordering.enumerated() {
                let later = ordering[(i + 1)...].filter { adjacent[v].contains($0) }
                #expect(later.count <= expected[v], "\(v) in \(ordering)")
            }
            let coresInOrder = ordering.map { expected[$0] }
            #expect(coresInOrder == coresInOrder.sorted())
        }
    }

    @Test("degeneracyOrdering is api.md's Batagelj–Zaversnik replayed on the simple rows: a stable counting sort by degree, then each vertex's neighbours in row order")
    func degeneracyOrderingAgainstReplay() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 9), edges, Gen.int(in: 0 ... 1_000_000)) { n, raw, seed in
            let pairs = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            // The simple rows: each row in incidentEdges order, first appearance, loops dropped.
            let rows: [[Int]] = (0 ..< n).map { v in
                var seen = Set<Int>()
                return graph.neighbors(of: v).filter { $0 != v && seen.insert($0).inserted }
            }
            var degree = rows.map(\.count)
            let maxDegree = degree.max() ?? 0
            var binStart = [Int](repeating: 0, count: maxDegree + 1)
            for d in degree { binStart[d] += 1 }
            var start = 0
            for d in 0 ... maxDegree {
                let size = binStart[d]
                binStart[d] = start
                start += size
            }
            var position = [Int](repeating: 0, count: n)
            var vert = [Int](repeating: 0, count: n)
            var next = binStart
            for v in 0 ..< n {
                position[v] = next[degree[v]]
                vert[position[v]] = v
                next[degree[v]] += 1
            }
            for i in 0 ..< n {
                let v = vert[i]
                for u in rows[v] where degree[u] > degree[v] {
                    let du = degree[u]
                    let pu = position[u]
                    let pw = binStart[du]
                    let w = vert[pw]
                    if u != w {
                        position[u] = pw
                        position[w] = pu
                        vert[pu] = w
                        vert[pw] = u
                    }
                    binStart[du] += 1
                    degree[u] -= 1
                }
            }
            let cores = graph.coreNumbers()
            #expect(cores.degeneracyOrdering == vert)
            let byIndex = (0 ..< n).map { cores.coreNumber(ofIndex: $0) }
            #expect(byIndex == degree)
        }
    }

    @Test("triangles by every vertex triple; clustering 2T/(d(d−1)), 0 when d < 2; transitivity ΣT / Σ d(d−1)/2, 0 without triangles; the average a plain sum in vertices order")
    func trianglesAgainstTriples() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 9), edges, Gen.int(in: 0 ... 1_000_000)) { n, raw, seed in
            let pairs = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
            for (a, b) in pairs where a != b {
                adjacent[a][b] = true
                adjacent[b][a] = true
            }
            var perVertex = [Int](repeating: 0, count: n)
            var total = 0
            for a in 0 ..< n {
                for b in a + 1 ..< max(a + 1, n) where adjacent[a][b] {
                    for c in b + 1 ..< max(b + 1, n) where adjacent[a][c] && adjacent[b][c] {
                        total += 1
                        perVertex[a] += 1
                        perVertex[b] += 1
                        perVertex[c] += 1
                    }
                }
            }
            let degree = (0 ..< n).map { v in adjacent[v].filter { $0 }.count }
            let clustering: [Double] = (0 ..< n).map { v in
                degree[v] < 2 ? 0 : Double(2 * perVertex[v]) / Double(degree[v] * (degree[v] - 1))
            }
            let triples = degree.reduce(0) { $0 + $1 * ($1 - 1) / 2 }
            let transitivity = total == 0 ? 0 : Double(3 * total) / Double(triples)
            var sum = 0.0
            for c in clustering { sum += c }
            let average = n == 0 ? 0 : sum / Double(n)

            let values = graph.clusteringCoefficients()
            let trianglesByIndex = (0 ..< n).map { values.triangleCount(ofIndex: $0) }
            #expect(trianglesByIndex == perVertex)
            let trianglesOneByOne = graph.vertices.map { graph.triangleCount(of: $0) }
            #expect(trianglesOneByOne == perVertex)
            let clusteringByIndex = (0 ..< n).map { values.clusteringCoefficient(ofIndex: $0) }
            #expect(clusteringByIndex == clustering)
            let clusteringOneByOne = graph.vertices.map { graph.clusteringCoefficient(of: $0) }
            #expect(clusteringOneByOne == clustering)
            #expect(values.triangleCount == total)
            #expect(graph.triangleCount() == total)
            #expect(values.transitivity == transitivity)
            #expect(graph.transitivity() == transitivity)
            #expect(values.averageClustering == average)
            #expect(graph.averageClustering() == average)
        }
    }

    @Test("graph.directed.undirected (every edge as two arcs, read back as a parallel pair) gives the same answers, the degeneracy ordering included")
    func directedThenUndirected() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 20)
        await propertyCheck(count: 200, input: Gen.int(in: 0 ... 8), edges, Gen.int(in: 0 ... 1_000_000)) { n, raw, seed in
            let pairs = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            let view = graph.directed.undirected
            let cliques = Array(graph.maximalCliques())
            let viewCliques = Array(view.maximalCliques())
            #expect(Set(viewCliques) == Set(cliques))
            #expect(viewCliques.count == cliques.count)
            #expect(view.maximumClique() == graph.maximumClique())
            #expect(view.cliqueNumber() == graph.cliqueNumber())
            let cores = graph.coreNumbers()
            let viewCores = view.coreNumbers()
            let byIndex = (0 ..< n).map { cores.coreNumber(ofIndex: $0) }
            let viewByIndex = (0 ..< n).map { viewCores.coreNumber(ofIndex: $0) }
            #expect(viewByIndex == byIndex)
            #expect(viewCores.degeneracyOrdering == cores.degeneracyOrdering)
            let values = graph.clusteringCoefficients()
            let viewValues = view.clusteringCoefficients()
            let triangles = (0 ..< n).map { values.triangleCount(ofIndex: $0) }
            let viewTriangles = (0 ..< n).map { viewValues.triangleCount(ofIndex: $0) }
            #expect(viewTriangles == triangles)
            let clustering = (0 ..< n).map { values.clusteringCoefficient(ofIndex: $0) }
            let viewClustering = (0 ..< n).map { viewValues.clusteringCoefficient(ofIndex: $0) }
            #expect(viewClustering == clustering)
            #expect(viewValues.transitivity == values.transitivity)
            #expect(viewValues.averageClustering == values.averageClustering)
        }
    }

    @Test("on UndirectedAdjacencyList, simple graphs of up to 14 vertices: maximal cliques against every vertex subset, core numbers against peeling, triangles against triples")
    func largerSimpleGraphs() async {
        let edges = zip(Gen.int(in: 0 ... 13), Gen.int(in: 0 ... 13)).array(of: 0 ... 60)
        await propertyCheck(count: 100, input: edges) { raw in
            let n = 14
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            var neighbours = [Int](repeating: 0, count: n)
            for (a, b) in raw where a != b {
                neighbours[a] |= 1 << b
                neighbours[b] |= 1 << a
            }
            var expected = Set<[Int]>()
            for mask in 1 ..< 1 << n {
                var isClique = true
                var rest = mask
                while rest != 0 && isClique {
                    let v = rest.trailingZeroBitCount
                    rest &= rest - 1
                    isClique = (mask & ~(1 << v)) & ~neighbours[v] == 0
                }
                guard isClique else { continue }
                let isMaximal = (0 ..< n).allSatisfy { w in mask & (1 << w) != 0 || mask & ~neighbours[w] != 0 }
                if isMaximal { expected.insert((0 ..< n).filter { mask & (1 << $0) != 0 }) }
            }
            let cliques = Array(graph.maximalCliques())
            #expect(Set(cliques) == expected)
            #expect(cliques.count == expected.count)
            let largest = expected.map(\.count).max() ?? 0
            let least = expected.filter { $0.count == largest }.min { $0.lexicographicallyPrecedes($1) }
            #expect(graph.maximumClique() == least)
            #expect(graph.cliqueNumber() == largest)

            // Peeling.
            var core = [Int](repeating: 0, count: n)
            var k = 0
            while true {
                var alive = (1 << n) - 1
                var changed = true
                while changed {
                    changed = false
                    for v in 0 ..< n where alive & (1 << v) != 0 && (neighbours[v] & alive).nonzeroBitCount < k {
                        alive &= ~(1 << v)
                        changed = true
                    }
                }
                if alive == 0 { break }
                for v in 0 ..< n where alive & (1 << v) != 0 { core[v] = k }
                k += 1
            }
            let cores = graph.coreNumbers()
            let byIndex = (0 ..< n).map { cores.coreNumber(ofIndex: $0) }
            #expect(byIndex == core)
            #expect(cores.degeneracy == (core.max() ?? 0))

            // Triples.
            var perVertex = [Int](repeating: 0, count: n)
            for a in 0 ..< n {
                for b in a + 1 ..< n where neighbours[a] & (1 << b) != 0 {
                    for c in b + 1 ..< max(b + 1, n) where neighbours[a] & (1 << c) != 0 && neighbours[b] & (1 << c) != 0 {
                        perVertex[a] += 1
                        perVertex[b] += 1
                        perVertex[c] += 1
                    }
                }
            }
            let values = graph.clusteringCoefficients()
            let triangles = (0 ..< n).map { values.triangleCount(ofIndex: $0) }
            #expect(triangles == perVertex)
            #expect(graph.triangleCount() * 3 == perVertex.reduce(0, +))
        }
    }
}
