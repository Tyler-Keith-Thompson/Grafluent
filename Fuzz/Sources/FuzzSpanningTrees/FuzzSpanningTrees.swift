// The spanning-forest algorithms against a canonical Kruskal written here, on graphs of at most
// 8 vertices: a simple graph (UndirectedAdjacencyList), a multigraph with self-loops (the
// undirected view of a directed AdjacencyList, where u→v and v→u are parallel edges), and the same
// multigraph through conformers with vertex indices only and with none. Kruskal, the default, the maximum and the
// unweighted forest must be exactly the canonical forests; Borůvka the same edge set; Prim the
// same weight and a spanning forest; Prim from a root a minimum tree of the root's component.
// Every algorithm weighs each non-loop edge exactly once and never a self-loop.

import AdjacencyListModule
import FuzzSupport
import GraphProtocols
import SpanningTrees

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

/// The same multigraph with vertex indices (positions in `vertices`) but no edge indices.
struct VertexIndexedGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] { PlainGraph(vertices: vertices, edges: edges).incidentEdges(of: vertex) }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertices.firstIndex(of: vertex)! }
    func vertex(atIndex index: Int) -> Int { vertices[index] }
}

@main
enum FuzzSpanningTrees {
    static func main() { runFuzzer(fuzz) }

    /// Kruskal over `edges` (u, v, w) in offset order, by `less` on weights, ties by offset.
    static func canonical(_ n: Int, _ edges: [(Int, Int, Int)], _ less: (Int, Int) -> Bool) -> [Int] {
        var parent = Array(0 ..< n)
        func find(_ x: Int) -> Int { var x = x; while parent[x] != x { x = parent[x] }; return x }
        var taken: [Int] = []
        for k in edges.indices.sorted(by: { less(edges[$0].2, edges[$1].2) || (!less(edges[$1].2, edges[$0].2) && $0 < $1) }) {
            let (a, b) = (find(edges[k].0), find(edges[k].1))
            if a != b { parent[a] = b; taken.append(k) }
        }
        return taken
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 8)
        let root = input.int(below: n)
        var raw: [(Int, Int, Int)] = []
        // Up to 48 edges, so even 8 vertices can reach the default's dense path (m ≥ 4n).
        while !input.isEmpty && raw.count < 48 {
            raw.append((input.int(below: n), input.int(below: n), input.int(in: -3 ... 6)))
        }
        let components: (Int, [(Int, Int, Int)]) -> [[Int]] = { n, edges in
            var label = Array(0 ..< n)
            for (u, v, _) in edges { let (a, b) = (label[u], label[v]); for i in label.indices where label[i] == b { label[i] = a } }
            return Dictionary(grouping: 0 ..< n) { label[$0] }.values.map { $0.sorted() }
        }

        func checkAll<G: Graph<Int>>(_ graph: G, _ edges: [(Int, Int, Int)], _ rankOf: (G.Edges.Index) -> Int, _ name: String) {
            let minimum = canonical(n, edges, <)
            let maximum = canonical(n, edges, >)
            let first = canonical(n, edges) { _, _ in false }
            let weightOf: ([Int]) -> Int = { $0.map { edges[$0].2 }.reduce(0, +) }
            let componentCount = components(n, edges).count

            var calls = [Int](repeating: 0, count: edges.count)
            func counted(_ p: G.Edges.Index) -> Int { calls[rankOf(p)] += 1; return edges[rankOf(p)].2 }
            func checkCalls(_ algorithm: String) {
                for k in edges.indices {
                    let expected = edges[k].0 == edges[k].1 ? 0 : 1
                    check(calls[k] == expected, "\(name) \(algorithm): edge \(k) weighed \(calls[k]) times")
                }
                calls = [Int](repeating: 0, count: edges.count)
            }

            let kruskal = graph.kruskalMinimumSpanningTree(weight: counted)
            checkCalls("Kruskal")
            check(kruskal.edges.map(rankOf) == minimum, "\(name) Kruskal \(kruskal.edges.map(rankOf)), canonical \(minimum)")
            check(kruskal.weight == weightOf(minimum), "\(name) Kruskal weight")
            check(graph.minimumSpanningTree(weight: counted) == kruskal, "\(name) the default is Kruskal's forest")
            checkCalls("default")

            let boruvka = graph.boruvkaMinimumSpanningTree(weight: counted)
            checkCalls("Borůvka")
            check(boruvka.edges.map(rankOf).sorted() == minimum.sorted() && boruvka.weight == kruskal.weight, "\(name) Borůvka \(boruvka.edges.map(rankOf))")

            let prim = graph.primMinimumSpanningTree(weight: counted)
            checkCalls("Prim")
            let primEdges = prim.edges.map(rankOf)
            check(prim.weight == kruskal.weight && weightOf(primEdges) == prim.weight, "\(name) Prim weight \(prim.weight), expected \(kruskal.weight)")
            check(primEdges.count == n - componentCount && components(n, primEdges.map { edges[$0] }).count == componentCount, "\(name) Prim is not a spanning forest")

            let rooted = graph.primMinimumSpanningTree(from: root, weight: counted)
            let component = Set(components(n, edges).first { $0.contains(root) }!)
            let inside = edges.enumerated().filter { component.contains($0.element.0) }.map(\.element)
            for k in edges.indices {
                let expected = component.contains(edges[k].0) && edges[k].0 != edges[k].1 ? 1 : 0
                check(calls[k] == expected, "\(name) Prim from \(root): edge \(k) weighed \(calls[k]) times")
            }
            calls = [Int](repeating: 0, count: edges.count)
            check(rooted.edges.count == component.count - 1, "\(name) Prim from \(root): \(rooted.edges.count) edges, component of \(component.count)")
            let insideWeight = canonical(n, inside, <).map { inside[$0].2 }.reduce(0, +)
            check(rooted.weight == insideWeight, "\(name) Prim from \(root): weight \(rooted.weight), expected \(insideWeight)")

            let maximal = graph.maximumSpanningTree(weight: counted)
            checkCalls("maximum")
            check(maximal.edges.map(rankOf) == maximum && maximal.weight == weightOf(maximum), "\(name) maximum \(maximal.edges.map(rankOf)), canonical \(maximum)")

            let unweighted = graph.minimumSpanningTree()
            check(unweighted.edges.map(rankOf) == first && unweighted.weight == first.count, "\(name) unweighted \(unweighted.edges.map(rankOf)), first forest \(first)")
        }

        // Simple: the first copy of each pair (self-loops kept).
        var seen = Set<UndirectedEdge<Int>>()
        let simple = raw.filter { seen.insert(UndirectedEdge($0.0, $0.1)).inserted }
        let list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: simple.map { UndirectedEdge($0.0, $0.1) })
        checkAll(list, simple, { $0 }, "UndirectedAdjacencyList")

        // Multigraph: arcs of a directed list, so u→v and v→u are parallel edges.
        var seenArcs = Set<DirectedEdge<Int>>()
        let arcs = raw.filter { seenArcs.insert(DirectedEdge(from: $0.0, to: $0.1)).inserted }
        let directed = AdjacencyList(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let view = directed.undirected
        // The view's edges are the list's arcs in its position order.
        let viewEdges = view.edges.map { e in arcs.first { $0.0 == e.u && $0.1 == e.v }! }
        let viewRanks = Dictionary(uniqueKeysWithValues: view.edges.indices.enumerated().map { ($1, $0) })
        checkAll(view, viewEdges, { viewRanks[$0]! }, "AdjacencyList.undirected")

        // The same multigraph without vertex indices.
        let plain = PlainGraph(vertices: Array(0 ..< n), edges: raw.map { UndirectedEdge($0.0, $0.1) })
        checkAll(plain, raw, { $0 }, "PlainGraph")
        checkAll(VertexIndexedGraph(vertices: Array(0 ..< n), edges: raw.map { UndirectedEdge($0.0, $0.1) }), raw, { $0 }, "VertexIndexedGraph")
    }
}
