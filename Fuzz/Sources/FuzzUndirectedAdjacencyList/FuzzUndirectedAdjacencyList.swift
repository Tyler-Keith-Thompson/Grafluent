// UndirectedAdjacencyList against a set of vertices and a set of unordered pairs, on vertices
// 0..<10, self-loops included (listed twice in neighbors, degree 2). After each operation every
// query must agree with the model and edge positions must be dense and name the same edge from
// both ends; a copy taken earlier must still equal the graph it was.

import AdjacencyListModule
import FuzzSupport
import GraphProtocols

@main
enum FuzzUndirectedAdjacencyList {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        var graph = UndirectedAdjacencyList<Int>()
        var vertices: Set<Int> = []
        var edges: Set<UndirectedEdge<Int>> = []
        var snapshot: (UndirectedAdjacencyList<Int>, Set<Int>, Set<UndirectedEdge<Int>>)?

        while !input.isEmpty {
            let op = input.int(below: 8)
            let (u, v) = (input.int(below: 10), input.int(below: 10))
            let edge = UndirectedEdge(u, v)
            switch op {
            case 0:
                check(graph.insert(u).inserted == vertices.insert(u).inserted, "insert(\(u))")
            case 1, 2, 3:
                check(graph.insert(edge: edge).inserted == !edges.contains(edge), "insert(edge: \(edge))")
                edges.insert(edge)
                vertices.formUnion([u, v])
            case 4:
                check(graph.remove(u) == vertices.remove(u), "remove(\(u))")
                edges = edges.filter { $0.u != u && $0.v != u }
            case 5, 6:
                check(graph.remove(edge: edge) == edges.remove(edge), "remove(edge: \(edge))")
            default:
                snapshot = (graph, vertices, edges)
            }
            verify(graph, vertices, edges)
        }
        if let (copy, vertices, edges) = snapshot { verify(copy, vertices, edges) }
    }

    static func verify(_ graph: UndirectedAdjacencyList<Int>, _ vertices: Set<Int>, _ edges: Set<UndirectedEdge<Int>>) {
        check(graph.vertexCount == vertices.count && Set(graph.vertices) == vertices, "vertices \(Array(graph.vertices)), model \(vertices.sorted())")
        check(graph.edgeCount == edges.count && Set(graph.edges) == edges, "edges \(Array(graph.edges)), model \(edges)")
        check(graph == UndirectedAdjacencyList(vertices: vertices, edges: edges), "== a graph built from the model")
        // Same edges, each written the other way round.
        let flipped = UndirectedAdjacencyList(vertices: vertices.sorted(), edges: edges.map { UndirectedEdge($0.v, $0.u) })
        check(graph == flipped && graph.hashValue == flipped.hashValue, "orientation is not part of the value")
        check(graph.edgeIndexBound == edges.count, "edgeIndexBound")

        var ends: [Int] = []
        for x in 0 ..< 10 {
            check(graph.contains(x) == vertices.contains(x), "contains(\(x))")
            for y in 0 ..< 10 {
                check(graph.contains(edge: UndirectedEdge(x, y)) == edges.contains(UndirectedEdge(x, y)), "contains(edge: \(x)–\(y))")
            }
            guard vertices.contains(x) else { continue }
            // A self-loop is listed twice.
            let neighbors = edges.flatMap { e -> [Int] in e.u == x && e.v == x ? [x, x] : e.u == x ? [e.v] : e.v == x ? [e.u] : [] }.sorted()
            check(graph.neighbors(of: x).sorted() == neighbors, "neighbors(of: \(x)): \(Array(graph.neighbors(of: x))), model \(neighbors)")
            check(graph.degree(of: x) == neighbors.count, "degree(of: \(x))")

            let incident = Array(graph.incidentEdges(of: x))
            check(incident.map { graph.oppositeVertex(to: x, acrossEdgeAt: $0) } == Array(graph.neighbors(of: x)), "incidentEdges(of: \(x)) follow neighbors")
            check(incident.allSatisfy { let e = graph.edges[$0]; return e.u == x || e.v == x }, "incidentEdges(of: \(x)) touch \(x)")
            ends += incident

            let i = graph.vertexIndex(of: x)
            check(graph.vertex(atIndex: i) == x && Array(graph.vertices)[i] == x, "vertexIndex(of: \(x))")
            check(Array(graph.neighborIndices(ofIndex: i)) == graph.neighbors(of: x).map { graph.vertexIndex(of: $0) }, "neighborIndices(ofIndex:)")
            check(Array(graph.incidentEdges(ofIndex: i)) == incident && Array(graph.incidentEdgeIndices(ofIndex: i)) == incident, "incidentEdges(ofIndex:)")
        }
        // Every edge is incident twice: at both ends, or twice at a self-loop's one vertex.
        check(ends.sorted() == (0 ..< edges.count).flatMap { [$0, $0] }, "each position appears at both ends")
    }
}
