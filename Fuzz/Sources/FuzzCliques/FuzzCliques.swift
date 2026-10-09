// Cliques against brute force, on multigraphs of at most 11 vertices with self-loops and parallel
// edges (read as their simple graph): maximal cliques as a set, each in vertex order, every one
// maximal; the clique number and the lexicographically least maximum clique by checking every
// vertex subset; core numbers by peeling, and the degeneracy ordering's property; triangles,
// clustering and transitivity by counting triples. On UndirectedAdjacencyList and on a conformer
// without vertex indices that keeps loops and parallel edges.

import AdjacencyListModule
import Cliques
import FuzzSupport
import GraphProtocols

/// An undirected multigraph with no vertex indices.
struct PlainGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

@main
enum FuzzCliques {
    static func main() { runFuzzer(fuzz) }

    static func check<G: Graph>(_ graph: G, _ n: Int, _ adjacent: [[Bool]], _ name: String) where G.Vertex == Int {
        func isClique(_ set: [Int]) -> Bool {
            for i in set.indices { for j in set.indices where j > i && !adjacent[set[i]][set[j]] { return false } }
            return true
        }
        // Every clique by brute force over subsets.
        var cliques: [[Int]] = []
        for mask in 1 ..< (1 << n) {
            let set = (0 ..< n).filter { mask & (1 << $0) != 0 }
            if isClique(set) { cliques.append(set) }
        }
        let maximal = Set(cliques.filter { c in !(0 ..< n).contains { v in !c.contains(v) && c.allSatisfy { adjacent[$0][v] } } })
        let found = Array(graph.maximalCliques())
        FuzzSupport.check(found.allSatisfy { $0 == $0.sorted() }, "\(name): a clique is not in vertex order")
        FuzzSupport.check(Set(found) == maximal && found.count == maximal.count, "\(name): maximalCliques \(found), expected \(maximal.sorted { $0.lexicographicallyPrecedes($1) })")
        let omega = cliques.map(\.count).max() ?? 0
        FuzzSupport.check(graph.cliqueNumber() == omega, "\(name): cliqueNumber \(graph.cliqueNumber()), expected \(omega)")
        let least = cliques.filter { $0.count == omega }.min { $0.lexicographicallyPrecedes($1) } ?? []
        FuzzSupport.check(graph.maximumClique() == least, "\(name): maximumClique \(graph.maximumClique()), expected \(least)")

        // Cores by peeling the least-degree vertex.
        var core = [Int](repeating: 0, count: n)
        var alive = Set(0 ..< n)
        var k = 0
        while !alive.isEmpty {
            let degree = { (v: Int) in alive.filter { adjacent[v][$0] }.count }
            let v = alive.min { degree($0) < degree($1) }!
            k = max(k, degree(v))
            core[v] = k
            alive.remove(v)
        }
        let cores = graph.coreNumbers()
        FuzzSupport.check((0 ..< n).map { cores.coreNumber(of: $0) } == core, "\(name): core numbers")
        FuzzSupport.check(cores.degeneracy == (core.max() ?? 0), "\(name): degeneracy")
        let ordering = cores.degeneracyOrdering
        FuzzSupport.check(ordering.sorted() == Array(0 ..< n), "\(name): degeneracyOrdering is not a permutation")
        for (i, v) in ordering.enumerated() {
            let later = ordering[(i + 1)...].filter { adjacent[v][$0] }.count
            FuzzSupport.check(later <= core[v], "\(name): \(v) has \(later) later neighbors, core \(core[v])")
        }
        for k in 0 ... (core.max() ?? 0) + 1 {
            FuzzSupport.check(cores.kCore(k) == (0 ..< n).filter { core[$0] >= k } && cores.kShell(k) == (0 ..< n).filter { core[$0] == k }, "\(name): kCore/kShell(\(k))")
        }

        // Triangles and clustering by triples.
        var triangles = [Int](repeating: 0, count: n)
        for a in 0 ..< n { for b in a + 1 ..< max(n, a + 1) where adjacent[a][b] { for c in b + 1 ..< max(n, b + 1) where adjacent[a][c] && adjacent[b][c] {
            triangles[a] += 1; triangles[b] += 1; triangles[c] += 1
        } } }
        let degrees = (0 ..< n).map { v in (0 ..< n).filter { adjacent[v][$0] }.count }
        let clustering = graph.clusteringCoefficients()
        for v in 0 ..< n {
            let expected = degrees[v] < 2 ? 0 : Double(2 * triangles[v]) / Double(degrees[v] * (degrees[v] - 1))
            FuzzSupport.check(clustering.triangleCount(of: v) == triangles[v] && graph.triangleCount(of: v) == triangles[v], "\(name): triangles of \(v)")
            FuzzSupport.check(clustering.clusteringCoefficient(of: v) == expected && graph.clusteringCoefficient(of: v) == expected, "\(name): clustering of \(v)")
        }
        let corners = triangles.reduce(0, +), triples = degrees.reduce(0) { $0 + $1 * ($1 - 1) / 2 }
        FuzzSupport.check(clustering.triangleCount == corners / 3 && graph.triangleCount() == corners / 3, "\(name): triangle count")
        FuzzSupport.check(clustering.transitivity == (corners == 0 ? 0 : Double(corners) / Double(triples)), "\(name): transitivity")
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 11)
        var pairs: [(Int, Int)] = []
        while !input.isEmpty, pairs.count < 30 { pairs.append((input.int(below: n), input.int(below: n))) }
        var adjacent = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
        for (u, v) in pairs where u != v {
            adjacent[u][v] = true
            adjacent[v][u] = true
        }
        let edges = pairs.map { UndirectedEdge($0.0, $0.1) }
        check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges), n, adjacent, "UndirectedAdjacencyList")
        check(PlainGraph(vertices: Array(0 ..< n), edges: edges), n, adjacent, "multigraph without indices")
    }
}
