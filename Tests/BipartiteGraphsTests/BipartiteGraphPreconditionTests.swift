// Preconditions, as exit tests (catalog BP-142 – BP-149): `insert(_:on:)` with a vertex already
// on the other side; `insert(edge:)` inside a side, a self-loop, or with an endpoint that is not
// a vertex; `side(of:)` on a non-vertex, also one just removed. Then the same preconditions
// the catalog does not list: `side(of:)` on the empty graph, `insert(edge:)` on the empty
// graph, and `Bipartition.side(of:)` on a non-vertex and `side(ofIndex:)` out of range. Each
// exit test builds its inputs inside the closure. Generated from cases.md by swiftgen.py, the
// last test written by hand; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("BipartiteGraph preconditions", .tags(.precondition))
struct BipartiteGraphPreconditionTests {
    @Test("BP-142 insert a vertex on the other side traps: the vertex is on the other side")
    func bp142() async {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert("a", on: .right)
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) })!
            graph.insert("a", on: .right)
        }
    }

    @Test("BP-143 insert an edge inside left traps: both endpoints are on one side")
    func bp143() async {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: a–b)
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) })!
            graph.insert(edge: UndirectedEdge("a", "b"))
        }
    }

    @Test("BP-144 insert an edge inside right traps: both endpoints are on one side")
    func bp144() async {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: x–y)
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) })!
            graph.insert(edge: UndirectedEdge("x", "y"))
        }
    }

    @Test("BP-145 insert a self-loop traps: both endpoints are on one side")
    func bp145() async {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: a–a)
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) })!
            graph.insert(edge: UndirectedEdge("a", "a"))
        }
    }

    @Test("BP-146 insert an edge with a missing endpoint traps: an endpoint is not a vertex")
    func bp146() async {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: a–z)
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) })!
            graph.insert(edge: UndirectedEdge("a", "z"))
        }
    }

    @Test("BP-147 insert an edge with both endpoints missing traps: an endpoint is not a vertex")
    func bp147() async {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; insert(edge: p–q)
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) })!
            graph.insert(edge: UndirectedEdge("p", "q"))
        }
    }

    @Test("BP-148 side(of:) a non-vertex traps: not a vertex")
    func bp148() async {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; side(of: "z")
        await #expect(processExitsWith: .failure) {
            let graph = BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) })!
            _ = graph.side(of: "z")
        }
    }

    @Test("BP-149 side(of:) a removed vertex traps: not a vertex")
    func bp149() async {
        // left [a, b, c], right [x, y], edges [a–x, b–x, b–y, c–y]; remove("a"); side(of: "a")
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph<String>(left: ["a", "b", "c"] as [String], right: ["x", "y"] as [String], edges: [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")].map { UndirectedEdge<String>($0.0, $0.1) })!
            graph.remove("a")
            _ = graph.side(of: "a")
        }
    }

    @Test("side(of:) and insert(edge:) on the empty graph trap: not a vertex")
    func emptyGraph() async {
        await #expect(processExitsWith: .failure) {
            _ = BipartiteGraph<Int>().side(of: 0)
        }
        await #expect(processExitsWith: .failure) {
            var graph = BipartiteGraph<Int>()
            graph.insert(edge: UndirectedEdge(0, 1))
        }
        await #expect(processExitsWith: .failure) {
            // One endpoint present, on the left; the other missing.
            var graph = BipartiteGraph<Int>()
            graph.insert(0, on: .left)
            graph.insert(edge: UndirectedEdge(0, 1))
        }
    }

    @Test("Bipartition.side(of:) traps on a non-vertex, side(ofIndex:) outside 0..<vertexCount")
    func bipartitionQueries() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.bipartition()!.side(of: 7)
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferencePseudograph(edges: [UndirectedEdge("a", "b")])
            _ = graph.bipartition()!.side(of: "z")
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.bipartition()!.side(ofIndex: 2)
        }
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
            _ = graph.bipartition()!.side(ofIndex: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = UndirectedAdjacencyList<Int>().bipartition()!.side(ofIndex: 0)
        }
    }
}
