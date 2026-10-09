// AdjacencyList against a set of vertices and a set of (source, target) pairs, on vertices
// 0..<10 so removals keep moving the last slot and the last edge into holes. After each
// operation every query must agree with the model and the dense indices must stay dense; a copy
// taken earlier must still equal the graph it was.

import AdjacencyListModule
import FuzzSupport
import GraphProtocols

@main
enum FuzzAdjacencyList {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        var graph = AdjacencyList<Int>()
        var vertices: Set<Int> = []
        var edges: Set<DirectedEdge<Int>> = []
        var snapshot: (AdjacencyList<Int>, Set<Int>, Set<DirectedEdge<Int>>)?

        while !input.isEmpty {
            let op = input.int(below: 8)
            let (u, v) = (input.int(below: 10), input.int(below: 10))
            let edge = DirectedEdge(from: u, to: v)
            switch op {
            case 0:
                check(graph.insert(u).inserted == vertices.insert(u).inserted, "insert(\(u))")
            case 1, 2, 3:
                check(graph.insert(edge: edge).inserted == !edges.contains(edge), "insert(edge: \(edge))")
                edges.insert(edge)
                vertices.formUnion([u, v])
            case 4:
                check(graph.remove(u) == vertices.remove(u), "remove(\(u))")
                edges = edges.filter { $0.source != u && $0.target != u }
            case 5, 6:
                check(graph.remove(edge: edge) == edges.remove(edge), "remove(edge: \(edge))")
            default:
                snapshot = (graph, vertices, edges)
            }
            verify(graph, vertices, edges)
        }
        if let (copy, vertices, edges) = snapshot { verify(copy, vertices, edges) }
    }

    static func verify(_ graph: AdjacencyList<Int>, _ vertices: Set<Int>, _ edges: Set<DirectedEdge<Int>>) {
        check(graph.vertexCount == vertices.count && Set(graph.vertices) == vertices, "vertices \(Array(graph.vertices)), model \(vertices.sorted())")
        check(graph.edgeCount == edges.count && Set(graph.edges) == edges, "edges \(Array(graph.edges)), model \(edges)")
        check(graph == AdjacencyList(vertices: vertices, edges: edges), "== a graph built from the model")
        check(graph.hashValue == AdjacencyList(vertices: vertices.sorted(), edges: edges.sorted { ($0.source, $0.target) < ($1.source, $1.target) }).hashValue, "hash is order-free")
        check(graph.edgeIndexBound == edges.count, "edgeIndexBound")

        var positions: [Int] = []
        for x in 0 ..< 10 {
            check(graph.contains(x) == vertices.contains(x), "contains(\(x))")
            for y in 0 ..< 10 {
                check(graph.contains(edge: DirectedEdge(from: x, to: y)) == edges.contains(DirectedEdge(from: x, to: y)), "contains(edge: \(x)→\(y))")
            }
            guard vertices.contains(x) else { continue }
            let successors = edges.filter { $0.source == x }.map(\.target).sorted()
            let predecessors = edges.filter { $0.target == x }.map(\.source).sorted()
            check(graph.successors(of: x).sorted() == successors, "successors(of: \(x))")
            check(graph.predecessors(of: x).sorted() == predecessors, "predecessors(of: \(x))")
            check(graph.outDegree(of: x) == successors.count && graph.inDegree(of: x) == predecessors.count, "degrees of \(x)")

            // Out-edge positions name this vertex's edges, in successors order.
            let out = Array(graph.outEdges(of: x))
            check(out.map { graph.target(ofEdgeAt: $0) } == Array(graph.successors(of: x)), "outEdges(of: \(x)) follow successors")
            check(out.allSatisfy { graph.source(ofEdgeAt: $0) == x && graph.edgeIndex(of: $0) == $0 }, "outEdges(of: \(x)) sources")
            check(graph.inEdges(of: x).map { graph.source(ofEdgeAt: $0) }.sorted() == predecessors, "inEdges(of: \(x))")
            positions += out

            let i = graph.vertexIndex(of: x)
            check(graph.vertex(atIndex: i) == x && Array(graph.vertices)[i] == x, "vertexIndex(of: \(x))")
            check(Array(graph.outEdges(ofIndex: i)) == out, "outEdges(ofIndex:)")
            check(Array(graph.inEdges(ofIndex: i)) == Array(graph.inEdges(of: x)), "inEdges(ofIndex:)")
            check(graph.inEdges(of: x).allSatisfy { graph.target(ofEdgeAt: $0) == x }, "inEdges(of: \(x)) targets")
            check(graph.inEdges(of: x).map { graph.source(ofEdgeAt: $0) } == Array(graph.predecessors(of: x)), "inEdges(of: \(x)) follow predecessors")
        }
        check(positions.sorted() == Array(0 ..< edges.count), "edge positions are dense")
        for (k, edge) in graph.edges.enumerated() {
            check(graph.source(ofEdgeAt: k) == edge.source && graph.target(ofEdgeAt: k) == edge.target, "edge \(k)")
        }
    }
}
