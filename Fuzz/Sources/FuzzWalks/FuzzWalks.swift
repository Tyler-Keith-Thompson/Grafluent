// The walk types against brute force on small multigraphs, directed and undirected, with
// self-loops and parallel edges. For a random vertex sequence and random edge positions, each
// checked initializer accepts exactly when brute force says the sequence is a walk, trail, path,
// circuit or cycle of the graph; picking edges by vertices succeeds exactly when some choice of
// edges exists (tried exhaustively); every rotation of a circuit is equal and hashes alike;
// reversal and conversions keep the rules. (Codable is the unit tests' job: Foundation's coders
// are not available to this toolchain against the SDK.)

import FuzzSupport
import GraphProtocols
import Walks

struct PlainDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    func successors(of vertex: Int) -> [Int] { outEdges(of: vertex).map { edges[$0].target } }
    func outEdges(of vertex: Int) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

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
enum FuzzWalks {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 5)
        let directed = input.int(below: 2) == 0
        // At least one edge, so every edge position drawn is the graph's (any other is a
        // precondition violation, not a case to check).
        let m = input.int(in: 1 ... 10)
        let raw = (0 ..< m).map { _ in (input.int(below: n + 1), input.int(below: n)) }  // n: not a vertex
            .map { ($0.0 % n, $0.1) }
        let k = input.int(in: 1 ... 6)
        let vs = (0 ..< k).map { _ in input.int(below: n + 1) }  // n is never a vertex
        let es = (0 ..< k).map { _ in input.int(below: m) }

        // joins(e, a, b): edge e goes from a to b (either way when undirected).
        let joins: (Int, Int, Int) -> Bool = { e, a, b in
            let (u, v) = raw[e]
            return directed ? (u == a && v == b) : ((u == a && v == b) || (u == b && v == a))
        }
        let isVertex: (Int) -> Bool = { $0 < n }

        func expect(open: Bool, distinctEdges: Bool, distinctVertices: Bool, _ vertices: [Int], _ edges: [Int]) -> Bool {
            guard open ? vertices.count == edges.count + 1 : (vertices.count == edges.count && vertices.count >= 1) else { return false }
            guard vertices.allSatisfy(isVertex) else { return false }
            for (i, e) in edges.enumerated() where !joins(e, vertices[i], vertices[(i + 1) % vertices.count]) { return false }
            if distinctEdges && Set(edges).count != edges.count { return false }
            if distinctVertices && Set(vertices).count != vertices.count { return false }
            return true
        }

        // A choice of edges for consecutive pairs, distinct when asked: exhaustive search.
        func choiceExists(open: Bool, distinct: Bool, _ vertices: [Int]) -> Bool {
            guard !vertices.isEmpty, vertices.allSatisfy(isVertex) else { return false }
            let steps = open ? vertices.count - 1 : vertices.count
            var used = Set<Int>()
            func go(_ i: Int) -> Bool {
                if i == steps { return true }
                for e in 0 ..< m where joins(e, vertices[i], vertices[(i + 1) % vertices.count]) && (!distinct || !used.contains(e)) {
                    used.insert(e)
                    if go(i + 1) { return true }
                    used.remove(e)
                }
                return false
            }
            return go(0)
        }

        let openVertices = vs, openEdges = Array(es.dropLast())
        let closedVertices = vs, closedEdges = es

        func checkAll<G>(_ graph: G, _ name: String,
                         walk: ([Int], [Int]) -> Walk<Int, Int>?, trail: ([Int], [Int]) -> Trail<Int, Int>?, path: ([Int], [Int]) -> Path<Int, Int>?,
                         circuit: ([Int], [Int]) -> Circuit<Int, Int>?, cycle: ([Int], [Int]) -> Cycle<Int, Int>?,
                         pickTrail: ([Int]) -> Trail<Int, Int>?, pickCircuit: ([Int]) -> Circuit<Int, Int>?, pickWalk: ([Int]) -> Walk<Int, Int>?) {
            check((walk(openVertices, openEdges) != nil) == expect(open: true, distinctEdges: false, distinctVertices: false, openVertices, openEdges), "\(name) Walk \(openVertices) \(openEdges)")
            check((trail(openVertices, openEdges) != nil) == expect(open: true, distinctEdges: true, distinctVertices: false, openVertices, openEdges), "\(name) Trail")
            check((path(openVertices, openEdges) != nil) == expect(open: true, distinctEdges: true, distinctVertices: true, openVertices, openEdges), "\(name) Path")
            check((circuit(closedVertices, closedEdges) != nil) == expect(open: false, distinctEdges: true, distinctVertices: false, closedVertices, closedEdges), "\(name) Circuit")
            check((cycle(closedVertices, closedEdges) != nil) == expect(open: false, distinctEdges: true, distinctVertices: true, closedVertices, closedEdges), "\(name) Cycle")
            check((pickWalk(vs) != nil) == choiceExists(open: true, distinct: false, vs), "\(name) Walk(vertices, in:) \(vs)")
            check((pickTrail(vs) != nil) == choiceExists(open: true, distinct: true, vs), "\(name) Trail(vertices, in:) \(vs)")
            check((pickCircuit(vs) != nil) == choiceExists(open: false, distinct: true, vs), "\(name) Circuit(vertices, in:) \(vs)")

            if let found = pickCircuit(vs) {
                // Its own edges are valid, every rotation is the same circuit, reversal keeps the rules.
                check(circuit(found.vertices, found.edges) != nil, "\(name) a picked circuit is not a circuit of the graph")
                var hashes = Set<Int>()
                for r in 0 ..< found.count {
                    let rotated = Circuit(vertices: Array(found.vertices[r...] + found.vertices[..<r]), edges: Array(found.edges[r...] + found.edges[..<r]))!
                    check(rotated == found, "\(name) rotation \(r) of \(found) differs")
                    hashes.insert(rotated.hashValue)
                }
                check(hashes.count == 1, "\(name) rotations of \(found) hash differently")
                check(Circuit(vertices: found.reversed().vertices, edges: found.reversed().edges) != nil, "\(name) reversed circuit breaks the rules")
                if !directed { check(circuit(found.reversed().vertices, found.reversed().edges) != nil, "\(name) a reversed undirected circuit is not a circuit of the graph") }
                let opened = Walk(found)
                check(opened.isClosed && Circuit(opened) == found, "\(name) Circuit → Walk → Circuit")
            }
            if let found = pickTrail(vs) {
                check(trail(found.vertices, found.edges) != nil, "\(name) a picked trail is not a trail of the graph")
                check(Walk(found).reversed().reversed() == Walk(found), "\(name) reversing twice")
                if let p = Path(found) { check(Trail(p) == found, "\(name) Path → Trail") }
            }
        }

        if directed {
            let graph = PlainDigraph(vertices: Array(0 ..< n), edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            checkAll(graph, "directed",
                     walk: { Walk(vertices: $0, edges: $1, in: graph) }, trail: { Trail(vertices: $0, edges: $1, in: graph) },
                     path: { Path(vertices: $0, edges: $1, in: graph) }, circuit: { Circuit(vertices: $0, edges: $1, in: graph) },
                     cycle: { Cycle(vertices: $0, edges: $1, in: graph) },
                     pickTrail: { Trail($0, in: graph) }, pickCircuit: { Circuit($0, in: graph) }, pickWalk: { Walk($0, in: graph) })
        } else {
            let graph = PlainGraph(vertices: Array(0 ..< n), edges: raw.map { UndirectedEdge($0.0, $0.1) })
            checkAll(graph, "undirected",
                     walk: { Walk(vertices: $0, edges: $1, in: graph) }, trail: { Trail(vertices: $0, edges: $1, in: graph) },
                     path: { Path(vertices: $0, edges: $1, in: graph) }, circuit: { Circuit(vertices: $0, edges: $1, in: graph) },
                     cycle: { Cycle(vertices: $0, edges: $1, in: graph) },
                     pickTrail: { Trail($0, in: graph) }, pickCircuit: { Circuit($0, in: graph) }, pickWalk: { Walk($0, in: graph) })
        }
    }
}
