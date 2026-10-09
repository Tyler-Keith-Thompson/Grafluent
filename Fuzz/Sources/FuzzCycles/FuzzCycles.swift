// Cycles against brute force, on multigraphs of at most 7 vertices with self-loops and parallel
// edges, directed and undirected: every simple cycle by edge identity (a loop once, k parallel
// undirected edges C(k, 2) 2-cycles, a lone undirected edge none), in canonical form and in the
// documented order (least vertex, then each edge's offset in its vertex's row); the bounded
// sequence is the unbounded one filtered; girth is the shortest; isAcyclic and findCycle agree
// with it; the cycle basis has m − n + c independent cycles. Undirected graphs are checked on
// UndirectedAdjacencyList after removals (rows out of position order) and on a conformer without
// vertex indices; directed on AdjacencyList and the directed view of the undirected
// graph.

import AdjacencyListModule
import Cycles
import FuzzSupport
import GraphProtocols
import Walks

/// An undirected multigraph with no vertex indices; rows in position order.
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
enum FuzzCycles {
    static func main() { runFuzzer(fuzz) }

    /// Every simple cycle as (vertex numbers, edge numbers), canonical, from arcs (from, to, edge).
    static func brute(_ n: Int, _ arcs: [(Int, Int, Int)], undirected: Bool) -> Set<[Int]> {
        var found = Set<[Int]>()
        for s in 0 ..< n {
            var path = [s], edges: [Int] = []
            func extend(_ v: Int) {
                for (a, b, e) in arcs where a == v && !edges.contains(e) {
                    if b == s {
                        let cycle = edges + [e]
                        // Undirected: each cycle once, leaving s by its lesser edge.
                        if !undirected || cycle.count == 1 || cycle[0] < cycle[cycle.count - 1] {
                            found.insert(path + [-1] + cycle)
                        }
                    } else if b > s, !path.contains(b) {
                        path.append(b)
                        edges.append(e)
                        extend(b)
                        path.removeLast()
                        edges.removeLast()
                    }
                }
            }
            extend(s)
        }
        return found
    }

    static func key(_ vertices: [Int], _ edges: [Int]) -> [Int] { vertices + [-1] + edges }

    static func rank(_ cycles: [[Int]]) -> Int {
        var pivots: [Int: [UInt64]] = [:]
        var rank = 0
        for edges in cycles {
            var x = [UInt64](repeating: 0, count: 4)
            for e in edges { x[e / 64] ^= 1 << UInt64(e % 64) }
            func top(_ x: [UInt64]) -> Int? {
                for w in stride(from: 3, through: 0, by: -1) where x[w] != 0 { return w * 64 + (63 - x[w].leadingZeroBitCount) }
                return nil
            }
            while let t = top(x), let p = pivots[t] { for w in 0 ..< 4 { x[w] ^= p[w] } }
            if let t = top(x) {
                pivots[t] = x
                rank += 1
            }
        }
        return rank
    }

    static func checkUndirected<G: Graph>(_ graph: G, _ name: String, maxLength: Int) where G.Vertex == Int {
        let listed = Array(graph.vertices)
        var number: [Int: Int] = [:]
        for (i, v) in listed.enumerated() { number[v] = i }
        let positions = Array(graph.edges.indices)
        var edgeNumber: [G.Edges.Index: Int] = [:]
        for (k, p) in positions.enumerated() { edgeNumber[p] = k }
        let n = listed.count
        var arcs: [(Int, Int, Int)] = []
        for (k, e) in graph.edges.enumerated() {
            let a = number[e.u]!, b = number[e.v]!
            arcs.append((a, b, k))
            if a != b { arcs.append((b, a, k)) }
        }
        let expected = brute(n, arcs, undirected: true)
        func numbers(_ c: Cycle<Int, G.Edges.Index>) -> (vertices: [Int], edges: [Int]) {
            (c.vertices.map { number[$0]! }, c.edges.map { edgeNumber[$0]! })
        }
        func canonical(_ vs: [Int], _ es: [Int]) -> Bool { vs[0] == vs.min()! && (vs.count < 2 || es[0] < es[es.count - 1]) }
        // Each edge end's offset in its row, for the order.
        func offset(_ v: Int, _ e: Int) -> Int { Array(graph.incidentEdges(of: listed[v])).firstIndex(of: positions[e])! }

        let all = Array(graph.simpleCycles())
        var keys: [[Int]] = []
        var previous: [Int]?
        for c in all {
            let (vs, es) = numbers(c)
            check(Cycle(vertices: c.vertices, edges: c.edges, in: graph) != nil, "\(name): \(c) is not a cycle of the graph")
            check(canonical(vs, es), "\(name): \(vs) \(es) is not canonical")
            keys.append(key(vs, es))
            let order = [vs[0]] + zip(vs, es).map { offset($0, $1) }
            if let previous { check(previous.lexicographicallyPrecedes(order), "\(name): \(vs) \(es) is out of order") }
            previous = order
        }
        check(Set(keys).count == keys.count, "\(name): a cycle is listed twice")
        check(Set(keys) == expected, "\(name): simpleCycles \(Set(keys).subtracting(expected).sorted { $0.lexicographicallyPrecedes($1) }.prefix(3)) extra, \(expected.subtracting(keys).sorted { $0.lexicographicallyPrecedes($1) }.prefix(3)) missing")
        let bounded = Array(graph.simpleCycles(maxLength: maxLength))
        check(bounded == all.filter { $0.length <= maxLength } && bounded.map(\.edges) == all.filter { $0.length <= maxLength }.map(\.edges), "\(name): simpleCycles(maxLength: \(maxLength)) is not the filter")

        let girth = all.map(\.length).min()
        check(graph.girth() == girth, "\(name): girth \(String(describing: graph.girth())), expected \(String(describing: girth))")
        check(graph.isAcyclic == all.isEmpty, "\(name): isAcyclic")
        let found = graph.findCycle()
        check((found == nil) == all.isEmpty, "\(name): findCycle \(String(describing: found))")
        if let found {
            let (vs, es) = numbers(found)
            check(expected.contains(key(vs, es)), "\(name): findCycle \(vs) \(es) is not a canonical simple cycle")
        }
        if n > 0 {
            let root = listed[n / 2]
            let rooted = graph.findCycle(from: [root])
            if let rooted {
                let (vs, es) = numbers(rooted)
                check(expected.contains(key(vs, es)), "\(name): findCycle(from:) \(vs) \(es) is not a canonical simple cycle")
            }
        }

        // Components, for m − n + c.
        var label = [Int](repeating: -1, count: n)
        var components = 0
        for s in 0 ..< n where label[s] < 0 {
            label[s] = components
            var stack = [s]
            while let x = stack.popLast() {
                for (a, b, _) in arcs where a == x && label[b] < 0 {
                    label[b] = components
                    stack.append(b)
                }
            }
            components += 1
        }
        let basis = graph.cycleBasis()
        check(basis.count == positions.count - n + components, "\(name): cycleBasis has \(basis.count) cycles, expected \(positions.count - n + components)")
        var basisEdges: [[Int]] = []
        for c in basis {
            let (vs, es) = numbers(c)
            check(expected.contains(key(vs, es)), "\(name): basis cycle \(vs) \(es) is not a canonical simple cycle")
            basisEdges.append(es)
        }
        check(rank(basisEdges) == basis.count, "\(name): cycleBasis is not independent")
    }

    static func checkDirected<G: DirectedGraph>(_ graph: G, _ name: String, maxLength: Int) where G.Vertex == Int {
        let listed = Array(graph.vertices)
        var number: [Int: Int] = [:]
        for (i, v) in listed.enumerated() { number[v] = i }
        let positions = Array(graph.edges.indices)
        var edgeNumber: [G.Edges.Index: Int] = [:]
        for (k, p) in positions.enumerated() { edgeNumber[p] = k }
        let arcs = graph.edges.enumerated().map { (number[$0.element.source]!, number[$0.element.target]!, $0.offset) }
        let expected = brute(listed.count, arcs, undirected: false)
        let all = Array(graph.simpleCycles())
        var keys: [[Int]] = []
        var previous: [Int]?
        for c in all {
            let vs = c.vertices.map { number[$0]! }, es = c.edges.map { edgeNumber[$0]! }
            check(Cycle(vertices: c.vertices, edges: c.edges, in: graph) != nil, "\(name): \(c) is not a cycle of the graph")
            check(vs[0] == vs.min()!, "\(name): \(vs) does not start at its least vertex")
            keys.append(key(vs, es))
            let order = [vs[0]] + zip(c.vertices, c.edges).map { Array(graph.outEdges(of: $0)).firstIndex(of: $1)! }
            if let previous { check(previous.lexicographicallyPrecedes(order), "\(name): \(vs) \(es) is out of order") }
            previous = order
        }
        check(Set(keys).count == keys.count, "\(name): a cycle is listed twice")
        check(Set(keys) == expected, "\(name): simpleCycles \(Set(keys).subtracting(expected).count) extra, \(expected.subtracting(keys).count) missing")
        let bounded = Array(graph.simpleCycles(maxLength: maxLength))
        check(bounded.map(\.vertices) == all.filter { $0.length <= maxLength }.map(\.vertices) && bounded.map(\.edges) == all.filter { $0.length <= maxLength }.map(\.edges), "\(name): simpleCycles(maxLength: \(maxLength)) is not the filter")
        let girth = all.map(\.length).min()
        check(graph.girth() == girth, "\(name): girth \(String(describing: graph.girth())), expected \(String(describing: girth))")
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 7)
        let maxLength = input.int(in: 0 ... 7)
        let removals = input.int(below: 4)
        var pairs: [(Int, Int)] = []
        while !input.isEmpty, pairs.count < 16 { pairs.append((input.int(below: n), input.int(below: n))) }

        // Undirected, then edges removed so rows are no longer in position order.
        var list = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        for k in 0 ..< removals where list.edgeCount > 0 { _ = list.remove(edge: Array(list.edges)[k % list.edgeCount]) }
        if removals == 3, n > 1 { _ = list.remove(0) }
        checkUndirected(list, "UndirectedAdjacencyList", maxLength: maxLength)
        checkUndirected(PlainGraph(vertices: Array((0 ..< n).reversed()), edges: Array(list.edges)), "PlainGraph", maxLength: maxLength)
        checkDirected(list.directed, "directed view", maxLength: maxLength)

        let directed = AdjacencyList(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        checkDirected(directed, "AdjacencyList", maxLength: maxLength)
    }
}
