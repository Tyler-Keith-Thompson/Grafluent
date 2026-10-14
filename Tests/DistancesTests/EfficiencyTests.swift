// Latora and Marchiori's global and local efficiency. Global: the mean of 1/d over ordered pairs
// of distinct vertices, 0 for a pair not connected. Local: the mean over every vertex of the
// global efficiency of the subgraph its distinct other neighbors induce. Self-loops and parallel
// edges change nothing. Hand values in the comments; karate and Petersen agree with NetworkX 3.7
// within 1e-12. The property test's oracle is breadth-first search over the edge list.

import AdjacencyListModule
import Distances
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

/// An undirected multigraph on `0..<vertexCount` with its vertices listed in a seeded order and
/// its incidence rows shuffled by the same seed, unless the seed is 0.
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

@Suite("Efficiency")
struct EfficiencyTests {
    @Test("A triangle with a pendant: global 10/12, local (1 + 1 + 1/3 + 0)/4")
    func trianglePendant() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(abs(graph.globalEfficiency() - 10.0 / 12.0) <= 1e-15)
        #expect(abs(graph.localEfficiency() - 7.0 / 12.0) <= 1e-15)
    }

    @Test("Complete graphs are 1 and 1; a path's local efficiency is 0")
    func shapes() {
        var pairs: [UndirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { pairs.append(UndirectedEdge(u, v)) } }
        let complete = UndirectedAdjacencyList(edges: pairs)
        #expect(complete.globalEfficiency() == 1)
        #expect(complete.localEfficiency() == 1)
        // P4: unordered pairs at distances 1, 1, 1, 2, 2, 3.
        let path = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        #expect(abs(path.globalEfficiency() - 2 * (3 + 1 + 1.0 / 3) / 12) <= 1e-15)
        #expect(path.localEfficiency() == 0)
    }

    @Test("Degenerate graphs: empty, one vertex, edgeless: 0")
    func degenerate() {
        #expect(UndirectedAdjacencyList<Int>().globalEfficiency() == 0)
        #expect(UndirectedAdjacencyList<Int>().localEfficiency() == 0)
        let one = UndirectedAdjacencyList(vertices: [7], edges: [])
        #expect(one.globalEfficiency() == 0 && one.localEfficiency() == 0)
        let edgeless = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: [])
        #expect(edgeless.globalEfficiency() == 0 && edgeless.localEfficiency() == 0)
    }

    @Test("Disconnected pairs add 0: two disjoint edges give 4/12")
    func disconnected() {
        let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        #expect(abs(graph.globalEfficiency() - 4.0 / 12.0) <= 1e-15)
        // A star's center sees leaves with no edge between them; leaves see one neighbor.
        let star = UndirectedAdjacencyList(edges: (1 ..< 5).map { UndirectedEdge(0, $0) })
        #expect(star.localEfficiency() == 0)
    }

    @Test("Self-loops and parallel edges change nothing")
    func multigraph() {
        let simple = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let multi = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 3)])
        #expect(multi.globalEfficiency() == simple.globalEfficiency())
        #expect(multi.localEfficiency() == simple.localEfficiency())
    }

    @Test("Karate and Petersen, as NetworkX gives")
    func fixtures() {
        let karate = UndirectedAdjacencyList(vertices: UndirectedFixture<Int>.karate.vertices, edges: UndirectedFixture<Int>.karate.edges)
        #expect(abs(karate.globalEfficiency() - 0.4920083184789052) <= 1e-12)
        #expect(abs(karate.localEfficiency() - 0.6451265102000396) <= 1e-12)
        let petersen = UndirectedAdjacencyList(vertices: UndirectedFixture<Int>.petersen.vertices, edges: UndirectedFixture<Int>.petersen.edges)
        #expect(abs(petersen.globalEfficiency() - 2.0 / 3.0) <= 1e-12)
        #expect(petersen.localEfficiency() == 0)
    }

    @Test("Global and local efficiency equal breadth-first search over the edge list", .tags(.randomized))
    func property() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: pairs, Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ShuffledPseudograph(vertexCount: n, edges: ends.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
            for (a, b) in ends where a != b {
                adjacent[a][b] = true
                adjacent[b][a] = true
            }
            func efficiency(_ members: [Int]) -> Double {
                let k = members.count
                guard k > 1 else { return 0 }
                var sum = 0.0
                for s in members {
                    var distance: [Int: Int] = [s: 0]
                    var queue = [s], head = 0
                    while head < queue.count {
                        let x = queue[head]
                        head += 1
                        for y in members where adjacent[x][y] && distance[y] == nil {
                            distance[y] = distance[x]! + 1
                            queue.append(y)
                        }
                    }
                    for (t, d) in distance where t != s { sum += 1 / Double(d) }
                }
                return sum / Double(k * (k - 1))
            }
            let global = efficiency(Array(0 ..< n))
            #expect(abs(graph.globalEfficiency() - global) <= 1e-12, "\(ends)")
            let local = n == 0 ? 0 : (0 ..< n).map { v in efficiency((0 ..< n).filter { adjacent[v][$0] }) }.reduce(0, +) / Double(n)
            #expect(abs(graph.localEfficiency() - local) <= 1e-12, "\(ends)")
        }
    }
}
