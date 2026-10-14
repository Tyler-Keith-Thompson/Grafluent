// GraphOperations' materialized operations against written-out models, on multigraphs of at most 9
// vertices with self-loops and parallel edges, directed and undirected: the power against
// Floyd–Warshall distances; the ego graph (directed, with arcs followed backwards, undirected) as
// the induced subgraph on the vertices within the radius; the contraction of two vertices and of an
// edge as the renumbered edge set without loops; the transitive closure against Warshall and the
// reduction against Aho, Garey and Ullman's construction, with the same closure; the relabelings by
// a name map (merging) and by an ordering; the union, intersection, difference and symmetric
// difference against sets, on vertex sets that overlap in any way.

import AdjacencyListModule
import CompressedSparseRowModule
import FuzzSupport
import GraphOperations
import GraphProtocols
import Multigraphs

@main
enum FuzzGraphOperations {
    static func main() { runFuzzer(fuzz) }

    static func sorted(_ pairs: Set<[Int]>) -> [[Int]] { pairs.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) } }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 9)
        var raw: [(Int, Int)] = []
        let m = input.int(in: 0 ... 20)
        for _ in 0 ..< m { raw.append((input.int(below: n), input.int(below: n))) }
        let names = (0 ..< n).map { "v\($0)" }
        let directed = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
        let undirected = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })

        // Distances, both kinds, by Floyd–Warshall.
        let far = 1000
        func distances(forward: Bool, backward: Bool) -> [[Int]] {
            var d = [[Int]](repeating: [Int](repeating: far, count: n), count: n)
            for i in 0 ..< n { d[i][i] = 0 }
            for (a, b) in raw {
                if forward { d[a][b] = min(d[a][b], 1) }
                if backward { d[b][a] = min(d[b][a], 1) }
            }
            for k in 0 ..< n { for i in 0 ..< n { for j in 0 ..< n where d[i][k] + d[k][j] < d[i][j] { d[i][j] = d[i][k] + d[k][j] } } }
            return d
        }
        let dOut = distances(forward: true, backward: false), dBoth = distances(forward: true, backward: true)

        // Power.
        let k = input.int(in: 1 ... 9)
        var arcs: Set<[Int]> = [], pairs: Set<[Int]> = []
        for i in 0 ..< n {
            for j in 0 ..< n where i != j {
                if dOut[i][j] <= k { arcs.insert([i, j]) }
                if dBoth[i][j] <= k && i < j { pairs.insert([i, j]) }
            }
        }
        check(CompressedSparseRow.power(of: directed, k).edges.map { [$0.source, $0.target] } == sorted(arcs), "power \(raw) \(k)")
        check(UndirectedAdjacencyList<Int>.power(of: undirected, k).edges.map { [$0.u, $0.v] } == sorted(pairs), "undirected power \(raw) \(k)")

        // Ego graphs.
        let center = input.int(below: n), radius = input.int(in: 0 ... 4)
        for (view, d) in [(directed.egoGraphView(of: names[center], radius: radius), dOut),
                          (directed.egoGraphView(of: names[center], radius: radius, undirected: true), dBoth)] {
            let kept = (0 ..< n).filter { d[center][$0] <= radius }
            let induced = directed.inducedSubgraphView(on: kept.map { names[$0] })
            check(Array(view.vertices) == kept.map { names[$0] }, "ego vertices \(raw) \(center) \(radius)")
            check(Array(view.edges.indices) == Array(induced.edges.indices), "ego edges \(raw) \(center) \(radius)")
            for i in kept.indices {
                check(Array(view.successorIndices(ofIndex: i)) == Array(induced.successorIndices(ofIndex: i)), "ego rows \(raw)")
            }
        }
        let uview = undirected.egoGraphView(of: names[center], radius: radius)
        check(Array(uview.vertices) == (0 ..< n).filter { dBoth[center][$0] <= radius }.map { names[$0] }, "undirected ego \(raw) \(center) \(radius)")

        // Contractions.
        let u = input.int(below: n), v = input.int(below: n)
        func contracted(_ i: Int, _ j: Int, directed: Bool) -> (Int, [[Int]]) {
            let a = min(i, j), b = max(i, j)
            let map = (0 ..< n).map { a == b || $0 < b ? $0 : ($0 == b ? a : $0 - 1) }
            var out: Set<[Int]> = []
            for (s, t) in raw where map[s] != map[t] { out.insert(directed ? [map[s], map[t]] : [min(map[s], map[t]), max(map[s], map[t])]) }
            return (a == b ? n : n - 1, sorted(out))
        }
        let c = CompressedSparseRow.contraction(of: directed, names[u], names[v])
        check((c.vertexCount, c.edges.map { [$0.source, $0.target] }) == contracted(u, v, directed: true), "contraction \(raw) \(u) \(v)")
        let uc = UndirectedAdjacencyList<Int>.contraction(of: undirected, names[u], names[v])
        check((uc.vertexCount, uc.edges.map { [$0.u, $0.v] }) == contracted(u, v, directed: false), "undirected contraction \(raw) \(u) \(v)")
        if !raw.isEmpty {
            let p = input.int(below: raw.count)
            let e = CompressedSparseRow.contraction(of: directed, edgeAt: p)
            check((e.vertexCount, e.edges.map { [$0.source, $0.target] }) == contracted(raw[p].0, raw[p].1, directed: true), "edge contraction \(raw) \(p)")
            let ue = UndirectedAdjacencyList<Int>.contraction(of: undirected, edgeAt: p)
            check((ue.vertexCount, ue.edges.map { [$0.u, $0.v] }) == contracted(raw[p].0, raw[p].1, directed: false), "undirected edge contraction \(raw) \(p)")
        }

        // Closure and reduction.
        let reach = (0 ..< n).map { i in (0 ..< n).map { dOut[i][$0] < far } }
        var closure: Set<[Int]> = []
        for i in 0 ..< n { for j in 0 ..< n where i != j && reach[i][j] { closure.insert([i, j]) } }
        check(CompressedSparseRow.transitiveClosure(of: directed).edges.map { [$0.source, $0.target] } == sorted(closure), "closure \(raw)")
        let first = (0 ..< n).map { i in (0 ..< n).first { $0 == i || (reach[i][$0] && reach[$0][i]) }! }
        let leaders = Set(first)
        var reduction: Set<[Int]> = []
        for leader in leaders {
            let members = (0 ..< n).filter { first[$0] == leader }
            if members.count > 1 { for (x, member) in members.enumerated() { reduction.insert([member, members[(x + 1) % members.count]]) } }
        }
        for a in leaders {
            for b in leaders where a != b && reach[a][b] && !leaders.contains(where: { $0 != a && $0 != b && reach[a][$0] && reach[$0][b] }) {
                reduction.insert([a, b])
            }
        }
        let reduced = CompressedSparseRow.transitiveReduction(of: directed)
        check(reduced.edges.map { [$0.source, $0.target] } == sorted(reduction), "reduction \(raw)")
        check(CompressedSparseRow.transitiveClosure(of: reduced).edges.map { [$0.source, $0.target] } == sorted(closure), "reduction's closure \(raw)")

        // Relabelings.
        let image = (0 ..< n).map { _ in input.int(below: 4) }
        let rename: (String) -> String = { "w\(image[Int($0.dropFirst())!])" }
        var vertices: [String] = []
        for name in names where !vertices.contains(rename(name)) { vertices.append(rename(name)) }
        let renamed = raw.map { [rename(names[$0.0]), rename(names[$0.1])] }
        let pseudo = DirectedPseudograph<String>.relabeled(directed, by: rename)
        check(Array(pseudo.vertices) == vertices && pseudo.edges.map { [$0.source, $0.target] } == renamed, "relabeled \(raw) \(image)")
        var firsts: [[String]] = []
        for e in renamed where !firsts.contains(e) { firsts.append(e) }
        check(AdjacencyList<String>.relabeled(directed, by: rename).edges.map { [$0.source, $0.target] } == firsts, "relabeled simple \(raw) \(image)")
        let upseudo = Pseudograph<String>.relabeled(undirected, by: rename)
        check(Array(upseudo.vertices) == vertices && upseudo.edges.map { [$0.u, $0.v] } == renamed, "undirected relabeled \(raw) \(image)")
        var order = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { order.swapAt(i, input.int(below: i + 1)) }
        var rank = [Int](repeating: 0, count: n)
        for (r, i) in order.enumerated() { rank[i] = r }
        let loopless = raw.filter { $0.0 != $0.1 }
        let simple = DirectedPseudograph<String>(vertices: names, edges: loopless.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
        check(CompressedSparseRow.relabeled(simple, ordering: order.map { names[$0] }).edges.map { [$0.source, $0.target] } == sorted(Set(loopless.map { [rank[$0.0], rank[$0.1]] })),
              "relabeled ordering \(raw) \(order)")

        // Binary operations, against a second graph on a subset of the names in another order.
        let hNames = names.filter { _ in input.int(below: 3) != 0 }.reversed().map { $0 }
        var hRaw: [[String]] = []
        if !hNames.isEmpty { for _ in 0 ..< input.int(in: 0 ... 12) { hRaw.append([hNames[input.int(below: hNames.count)], hNames[input.int(below: hNames.count)]]) } }
        let h = AdjacencyList<String>(vertices: hNames, edges: hRaw.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let gSet = Set(raw.map { [names[$0.0], names[$0.1]] }), hSet = Set(hRaw)
        let both = names + hNames.filter { !names.contains($0) }, shared = names.filter { hNames.contains($0) }
        func ordered(_ edges: Set<[String]>, _ vertices: [String]) -> [[String]] {
            edges.sorted { (vertices.firstIndex(of: $0[0])!, vertices.firstIndex(of: $0[1])!) < (vertices.firstIndex(of: $1[0])!, vertices.firstIndex(of: $1[1])!) }
        }
        let union = AdjacencyList<String>.union(directed, h)
        check(Array(union.vertices) == both && union.edges.map { [$0.source, $0.target] } == ordered(gSet.union(hSet), both), "union \(raw) \(hRaw)")
        let intersection = AdjacencyList<String>.intersection(directed, h)
        check(Array(intersection.vertices) == shared && intersection.edges.map { [$0.source, $0.target] } == ordered(gSet.intersection(hSet), shared), "intersection \(raw) \(hRaw)")
        let difference = AdjacencyList<String>.difference(directed, h)
        check(Array(difference.vertices) == names && difference.edges.map { [$0.source, $0.target] } == ordered(gSet.subtracting(hSet), names), "difference \(raw) \(hRaw)")
        let symmetric = AdjacencyList<String>.symmetricDifference(directed, h)
        check(Array(symmetric.vertices) == both && symmetric.edges.map { [$0.source, $0.target] } == ordered(gSet.symmetricDifference(hSet), both), "symmetric difference \(raw) \(hRaw)")
        let uh = Pseudograph<String>(vertices: hNames, edges: hRaw.map { UndirectedEdge($0[0], $0[1]) })
        let gu = Set(raw.map { Set([names[$0.0], names[$0.1]]) }), hu = Set(hRaw.map { Set($0) })
        let uunion = UndirectedAdjacencyList<String>.union(undirected, uh)
        check(uunion.edgeCount == gu.union(hu).count && Set(uunion.edges.map { Set([$0.u, $0.v]) }) == gu.union(hu), "undirected union \(raw) \(hRaw)")
        for edge in uunion.edges { check(both.firstIndex(of: edge.u)! <= both.firstIndex(of: edge.v)!, "undirected union orientation \(raw) \(hRaw)") }
        check(Set(UndirectedAdjacencyList<String>.symmetricDifference(undirected, uh).edges.map { Set([$0.u, $0.v]) }) == gu.symmetricDifference(hu), "undirected symmetric difference \(raw) \(hRaw)")
    }
}
