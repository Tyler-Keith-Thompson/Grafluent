// BipartiteGraphs: recognition against brute force on multigraphs of at most 10 vertices with
// self-loops (bipartite iff some assignment of sides puts every edge across; every returned odd
// cycle valid and canonical; sides canonical: each component's least vertex left), and random
// mutation sequences on BipartiteGraph against a model (a side per vertex and a set of edges),
// including rejected ones (`BipartitionError`, from `insert(_:on:)`, `insert(edge:)` and
// `insert(checked:)`, which then change nothing), checking the invariant, the Graph laws that matter (counts, degrees, rows parallel), the
// `checked:` lookups (the trapping answer for a vertex, `VertexNotFound` otherwise), `left` and
// `right` against the model, equality, hashing and the `init(_:left:)` round trip (Codable is the test suite's: the fuzzing
// toolchain has no JSON coders); then the plain and weighted projections onto each side against
// their definitions.

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
                let result = Result { () throws(BipartitionError) in try graph.insert(v, on: s).inserted }
                if let existing = side[v], existing != s {
                    check(result == .failure(.onOtherSide(existing)), "insert vertex on the other side: \(result)")
                } else {
                    check(result == .success(side[v] == nil), "insert vertex result")
                    side[v] = s
                }
            case 2:
                let edge = UndirectedEdge(v, w)
                let checked = input.int(below: 2) == 0
                if let a = side[v], let b = side[w], a != b {
                    let result = Result { () throws(BipartitionError) in try checked ? graph.insert(checked: edge) : graph.insert(edge: edge) }
                    guard case .success(let (inserted, member)) = result else {
                        check(false, "a legal edge was rejected: \(result)")
                        break
                    }
                    check(inserted == !edges.contains(edge), "insert edge result")
                    check(graph.side(of: member.u) == .left, "edge not stored left endpoint first")
                    edges.insert(edge)
                } else if let a = side[v], side[w] != nil {
                    let result = Result { () throws(BipartitionError) in try checked ? graph.insert(checked: edge) : graph.insert(edge: edge) }.map(\.inserted)
                    check(result == .failure(.sameSide(a)), "an edge inside a side: \(result)")
                } else {
                    // A missing endpoint: insert(edge:) traps, insert(checked:) throws.
                    let result = Result { () throws(BipartitionError) in try graph.insert(checked: edge) }.map(\.inserted)
                    check(result == .failure(.missingEndpoint), "an edge with a missing endpoint: \(result)")
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
            // The checked: lookups over every candidate vertex: the trapping answer, or VertexNotFound.
            for u in 0 ..< 12 {
                if side[u] != nil {
                    check((try? graph.side(checked: u)) == graph.side(of: u), "side(checked:)")
                    check((try? graph.degree(checked: u)) == graph.degree(of: u), "degree(checked:)")
                    check((try? graph.incidentEdges(checked: u)) == graph.incidentEdges(of: u), "incidentEdges(checked:)")
                    check((try? graph.neighbors(checked: u)).map(Array.init) == Array(graph.neighbors(of: u)), "neighbors(checked:)")
                    check((try? graph.vertexIndex(checked: u)) == graph.vertexIndex(of: u), "vertexIndex(checked:)")
                } else {
                    check(Result { () throws(VertexNotFound) in try graph.side(checked: u) } == .failure(VertexNotFound()), "side(checked:) of a non-vertex")
                    check(Result { () throws(VertexNotFound) in try graph.degree(checked: u) } == .failure(VertexNotFound()), "degree(checked:) of a non-vertex")
                    check((try? graph.incidentEdges(checked: u)) == nil, "incidentEdges(checked:) of a non-vertex")
                    check((try? graph.neighbors(checked: u)) == nil, "neighbors(checked:) of a non-vertex")
                    check((try? graph.vertexIndex(checked: u)) == nil, "vertexIndex(checked:) of a non-vertex")
                }
            }
        }
        projections(graph)
        let rebuilt = BipartiteGraph(left: graph.left.shuffled(), right: graph.right.shuffled(), edges: graph.edges.shuffled())!
        check(rebuilt == graph && rebuilt.hashValue == graph.hashValue, "equality or hashing depends on order")
        check(BipartiteGraph(graph, left: graph.left) == graph, "init(_:left:) round trip")
    }

    /// The four projections onto each side, after the mutations: the weighted ones are the plain
    /// one's graph at the same positions, with the shared-neighbour count, both overlaps and the
    /// collaboration sum of each edge's ends by their definitions.
    static func projections(_ graph: BipartiteGraph<Int>) {
        for side in [BipartiteSide.left, .right] {
            let plain = graph.projectedGraph(onto: side)
            let count = graph.weightedProjectedGraph(onto: side)
            let jaccard = graph.overlapWeightedProjectedGraph(onto: side)
            let lesser = graph.overlapWeightedProjectedGraph(onto: side, jaccard: false)
            let collaboration = graph.collaborationWeightedProjectedGraph(onto: side)
            let edges = plain.edges.map { [$0.u, $0.v] }
            for g in [count.graph, jaccard.graph, lesser.graph, collaboration.graph] {
                check(Array(g.vertices) == Array(plain.vertices) && g.edges.map { [$0.u, $0.v] } == edges, "weighted projection's graph")
            }
            for (p, e) in plain.edges.enumerated() {
                let a = Set(graph.neighbors(of: e.u)), b = Set(graph.neighbors(of: e.v))
                let shared = a.intersection(b)
                check(!shared.isEmpty && count.graph[count.weights, ofEdgeAt: p] == shared.count, "shared count \(e)")
                let j = Double(shared.count) / Double(a.union(b).count), l = Double(shared.count) / Double(min(a.count, b.count))
                check(abs(jaccard.graph[jaccard.weights, ofEdgeAt: p] - j) <= 1e-12, "jaccard \(e)")
                check(abs(lesser.graph[lesser.weights, ofEdgeAt: p] - l) <= 1e-12, "lesser overlap \(e)")
                let sum = shared.reduce(0.0) { $0 + 1 / Double(graph.degree(of: $1) - 1) }
                check(abs(collaboration.graph[collaboration.weights, ofEdgeAt: p] - sum) <= 1e-12, "collaboration \(e)")
            }
        }
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
