// BipartiteGraphs: recognition against brute force on multigraphs of at most 10 vertices with
// self-loops (bipartite iff some assignment of sides puts every edge across; every returned odd
// cycle valid and canonical; sides canonical: each component's least vertex left), and random
// mutation sequences on BipartiteGraph against a model (a side per vertex and a set of edges),
// checking the invariant, the Graph laws that matter (counts, degrees, rows parallel), `left` and
// `right` against the model, equality, hashing and the `init(_:left:)` round trip (Codable is the test suite's: the fuzzing
// toolchain has no JSON coders).

import AdjacencyListModule
import BipartiteGraphs
import FuzzSupport
import GraphProtocols
import Walks

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
enum FuzzBipartiteGraphs {
    static func main() { runFuzzer(fuzz) }

    static func recognition(_ n: Int, _ ends: [(Int, Int)]) {
        let graph = PlainGraph(vertices: Array(0 ..< n), edges: ends.map { UndirectedEdge($0.0, $0.1) })
        var bipartite = false
        for mask in 0 ..< (1 << n) where ends.allSatisfy({ (mask >> $0.0) & 1 != (mask >> $0.1) & 1 }) {
            bipartite = true
            break
        }
        check(graph.isBipartite == bipartite, "isBipartite \(graph.isBipartite), expected \(bipartite) on \(ends)")
        if let partition = graph.bipartition() {
            check(bipartite, "a bipartition of a non-bipartite graph")
            // Canonical: by distance parity from each component's least vertex.
            var side = [Int](repeating: -1, count: n)
            for root in 0 ..< n where side[root] < 0 {
                side[root] = 0
                var queue = [root]
                while let v = queue.popLast() {
                    for (a, b) in ends where a == v || b == v {
                        let w = a == v ? b : a
                        if side[w] < 0 { side[w] = 1 - side[v]; queue.append(w) }
                    }
                }
            }
            check((0 ..< n).allSatisfy { (partition.side(of: $0) == .left) == (side[$0] == 0) }, "sides are not canonical on \(ends)")
            check(Array(partition.left) == (0 ..< n).filter { side[$0] == 0 }, "left is not in vertices order")
            check(BipartiteGraph(graph) != nil, "BipartiteGraph(graph) is nil on a bipartite graph")
        } else {
            check(!bipartite, "no bipartition of a bipartite graph")
            check(BipartiteGraph(graph) == nil, "BipartiteGraph(graph) on a non-bipartite graph")
        }
        if let cycle = graph.findOddCycle() {
            let vs = cycle.vertices, es = cycle.edges
            check(vs.count % 2 == 1 && Set(vs).count == vs.count && es.count == vs.count && Set(es).count == es.count, "odd cycle \(vs) \(es) is not simple and odd")
            for i in vs.indices {
                let e = ends[es[i]], x = vs[i], y = vs[(i + 1) % vs.count]
                check((e.0 == x && e.1 == y) || (e.0 == y && e.1 == x), "odd cycle edge \(es[i]) does not join \(x) and \(y)")
            }
            check(vs[0] == vs.min()!, "odd cycle does not start at its least vertex")
            if vs.count >= 2 { check(es[0] < es[es.count - 1], "odd cycle is not turned to its lesser edge") }
        } else {
            check(bipartite, "no odd cycle in a non-bipartite graph")
        }
    }

    static func mutations(_ input: inout FuzzInput) {
        var graph = BipartiteGraph<Int>()
        var side: [Int: BipartiteSide] = [:]
        var edges = Set<UndirectedEdge<Int>>()
        var steps = 0
        while !input.isEmpty, steps < 60 {
            steps += 1
            let v = input.int(below: 12), w = input.int(below: 12)
            switch input.int(below: 5) {
            case 0, 1:
                let s: BipartiteSide = v % 2 == 0 ? .left : .right
                if side[v] == nil || side[v] == s {
                    let inserted = graph.insert(v, on: s).inserted
                    check(inserted == (side[v] == nil), "insert vertex result")
                    side[v] = s
                }
            case 2:
                if let a = side[v], let b = side[w], a != b {
                    let edge = UndirectedEdge(v, w)
                    let (inserted, member) = graph.insert(edge: edge)
                    check(inserted == !edges.contains(edge), "insert edge result")
                    check(graph.side(of: member.u) == .left, "edge not stored left endpoint first")
                    edges.insert(edge)
                }
            case 3:
                check((graph.remove(v) != nil) == (side[v] != nil), "remove vertex result")
                side[v] = nil
                edges = edges.filter { $0.u != v && $0.v != v }
            default:
                let edge = UndirectedEdge(v, w)
                check((graph.remove(edge: edge) != nil) == edges.contains(edge), "remove edge result")
                edges.remove(edge)
            }
            check(graph.vertexCount == side.count && graph.edgeCount == edges.count, "counts")
            check(Set(graph.left) == Set(side.filter { $0.value == .left }.keys) && Set(graph.right) == Set(side.filter { $0.value == .right }.keys), "sides")
            check(graph.left.count + graph.right.count == graph.vertexCount, "side counts")
            check(Set(graph.edges) == edges, "edges")
            for v in graph.vertices {
                check(graph.side(of: v) == side[v], "side(of:)")
                check(graph.degree(of: v) == edges.filter { $0.u == v || $0.v == v }.count, "degree")
                check(zip(graph.neighbors(of: v), graph.incidentEdges(of: v)).allSatisfy { graph.oppositeVertex(to: v, acrossEdgeAt: $0.1) == $0.0 }, "rows not parallel")
            }
            for e in graph.edges { check(graph.side(of: e.u) == .left && graph.side(of: e.v) == .right, "edge orientation") }
        }
        let rebuilt = BipartiteGraph(left: graph.left.shuffled(), right: graph.right.shuffled(), edges: graph.edges.shuffled())!
        check(rebuilt == graph && rebuilt.hashValue == graph.hashValue, "equality or hashing depends on order")
        check(BipartiteGraph(graph, left: graph.left) == graph, "init(_:left:) round trip")
    }

    static func fuzz(_ input: inout FuzzInput) {
        if input.int(below: 2) == 0 {
            let n = input.int(in: 1 ... 10)
            var ends: [(Int, Int)] = []
            while !input.isEmpty, ends.count < 20 { ends.append((input.int(below: n), input.int(below: n))) }
            recognition(n, ends)
        } else {
            mutations(&input)
        }
    }
}
