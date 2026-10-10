// Multigraphs against a model of positions: random sequences of vertex and edge insertions,
// removals of the newest copy, of a given position, of every copy of a pair, and of vertices, on
// all four types. The model keeps the edges by position with an insertion stamp, applying the
// documented swap-remove rule (the last edge moves into the hole) and removing the newest stamp;
// after a vertex removal it checks the multiset and re-reads the positions. After every step:
// counts, every edge at its position, `edges(between:)` oldest first with its count, degrees, the
// rows parallel, and equality with a rebuild in shuffled order.

import FuzzSupport
import GraphProtocols
import Multigraphs

@main
enum FuzzMultigraphs {
    static func main() { runFuzzer(fuzz) }

    /// One edge in the model: its ends (stored orientation) and its insertion stamp.
    struct Copy { var u: Int, v: Int, stamp: Int }

    static func undirected(_ input: inout FuzzInput, loops: Bool) {
        var graph = Pseudograph<Int>()
        var model: [Copy] = []
        var vertices = Set<Int>()
        var stamp = 0
        func same(_ c: Copy, _ a: Int, _ b: Int) -> Bool { (c.u == a && c.v == b) || (c.u == b && c.v == a) }
        var steps = 0
        while !input.isEmpty, steps < 80 {
            steps += 1
            let a = input.int(below: 8), b = input.int(below: 8)
            switch input.int(below: 6) {
            case 0:
                graph.insert(a)
                vertices.insert(a)
            case 1, 2:
                if !loops, a == b { continue }
                let p = graph.insert(edge: UndirectedEdge(a, b))
                check(p == model.count, "insert(edge:) position \(p), expected \(model.count)")
                model.append(Copy(u: a, v: b, stamp: stamp))
                stamp += 1
                vertices.insert(a)
                vertices.insert(b)
            case 3:
                let copies = model.indices.filter { same(model[$0], a, b) }
                let removed = graph.remove(edge: UndirectedEdge(a, b))
                check((removed != nil) == !copies.isEmpty, "remove(edge:) result")
                if let p = copies.max(by: { model[$0].stamp < model[$1].stamp }) {
                    model[p] = model[model.count - 1]
                    model.removeLast()
                }
            case 4:
                guard !model.isEmpty else { continue }
                let p = (a * 8 + b) % model.count
                _ = graph.remove(edgeAt: p)
                model[p] = model[model.count - 1]
                model.removeLast()
            default:
                if input.int(below: 2) == 0 {
                    let count = graph.removeAllEdges(between: a, and: b)
                    check(count == model.filter { same($0, a, b) }.count, "removeAllEdges count")
                    // Newest first, each a swap-remove.
                    while let p = model.indices.filter({ same(model[$0], a, b) }).max(by: { model[$0].stamp < model[$1].stamp }) {
                        model[p] = model[model.count - 1]
                        model.removeLast()
                    }
                } else {
                    check((graph.remove(a) != nil) == vertices.contains(a), "remove(vertex) result")
                    vertices.remove(a)
                    let kept = model.filter { $0.u != a && $0.v != a }
                    check(graph.edgeCount == kept.count, "vertex removal edge count")
                    // Positions after a vertex removal are the graph's; stamps follow each pair's
                    // order, oldest first.
                    var next: [Copy] = graph.edges.map { Copy(u: $0.u, v: $0.v, stamp: 0) }
                    var byPair: [String: [Int]] = [:]
                    for c in kept.sorted(by: { $0.stamp < $1.stamp }) { byPair["\(min(c.u, c.v)),\(max(c.u, c.v))", default: []].append(c.stamp) }
                    for (k, list) in byPair {
                        let ends = k.split(separator: ",").map { Int($0)! }
                        let positions = Array(graph.edges(between: ends[0], and: ends[1]))
                        check(positions.count == list.count, "copies of \(k) after vertex removal")
                        for (p, s) in zip(positions, list) { next[p].stamp = s }
                    }
                    model = next
                }
            }
            check(graph.vertexCount == vertices.count && graph.edgeCount == model.count, "counts")
            for (p, c) in model.enumerated() { check(same(c, graph.edges[p].u, graph.edges[p].v), "edge at \(p)") }
            for x in vertices {
                check(graph.degree(of: x) == model.reduce(0) { $0 + ($1.u == x ? 1 : 0) + ($1.v == x ? 1 : 0) }, "degree of \(x)")
                check(zip(graph.neighbors(of: x), graph.incidentEdges(of: x)).allSatisfy { graph.oppositeVertex(to: x, acrossEdgeAt: $0.1) == $0.0 }, "rows not parallel")
                for y in vertices {
                    let expected = model.indices.filter { same(model[$0], x, y) }.sorted { model[$0].stamp < model[$1].stamp }
                    check(Array(graph.edges(between: x, and: y)) == expected && graph.edgeCount(between: x, and: y) == expected.count, "edges(between: \(x), and: \(y))")
                }
            }
        }
        let rebuilt = Pseudograph(vertices: Array(vertices).sorted().reversed(), edges: graph.edges.reversed())
        check(rebuilt == graph && rebuilt.hashValue == graph.hashValue, "equality or hashing depends on order")
        if !loops {
            check(Multigraph(graph) != nil, "a loop-free pseudograph is a multigraph")
        }
    }

    static func directed(_ input: inout FuzzInput) {
        var graph = DirectedPseudograph<Int>()
        var model: [Copy] = []
        var vertices = Set<Int>()
        var stamp = 0
        var steps = 0
        while !input.isEmpty, steps < 80 {
            steps += 1
            let a = input.int(below: 8), b = input.int(below: 8)
            switch input.int(below: 5) {
            case 0:
                graph.insert(a)
                vertices.insert(a)
            case 1, 2:
                let p = graph.insert(edge: DirectedEdge(from: a, to: b))
                check(p == model.count, "directed insert position")
                model.append(Copy(u: a, v: b, stamp: stamp))
                stamp += 1
                vertices.insert(a)
                vertices.insert(b)
            case 3:
                let copies = model.indices.filter { model[$0].u == a && model[$0].v == b }
                check((graph.remove(edge: DirectedEdge(from: a, to: b)) != nil) == !copies.isEmpty, "directed remove(edge:)")
                if let p = copies.max(by: { model[$0].stamp < model[$1].stamp }) {
                    model[p] = model[model.count - 1]
                    model.removeLast()
                }
            default:
                guard !model.isEmpty else { continue }
                let p = (a * 8 + b) % model.count
                _ = graph.remove(edgeAt: p)
                model[p] = model[model.count - 1]
                model.removeLast()
            }
            check(graph.edgeCount == model.count, "directed counts")
            for (p, c) in model.enumerated() { check(graph.source(ofEdgeAt: p) == c.u && graph.target(ofEdgeAt: p) == c.v, "directed edge at \(p)") }
            for x in vertices {
                check(graph.outDegree(of: x) == model.filter { $0.u == x }.count && graph.inDegree(of: x) == model.filter { $0.v == x }.count, "directed degrees")
                for y in vertices {
                    let expected = model.indices.filter { model[$0].u == x && model[$0].v == y }.sorted { model[$0].stamp < model[$1].stamp }
                    check(Array(graph.edges(from: x, to: y)) == expected, "edges(from: \(x), to: \(y))")
                }
            }
        }
        let rebuilt = DirectedPseudograph(vertices: Array(vertices), edges: model.reversed().map { DirectedEdge(from: $0.u, to: $0.v) })
        check(rebuilt == graph && rebuilt.hashValue == graph.hashValue, "directed equality or hashing depends on order")
    }

    static func fuzz(_ input: inout FuzzInput) {
        switch input.int(below: 3) {
        case 0: undirected(&input, loops: true)
        case 1: undirected(&input, loops: false)
        default: directed(&input)
        }
    }
}
