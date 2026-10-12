// `UndirectedAdjacencyList` through `MutableGraph`, the undirected counterpart of
// `MutableDirectedGraph`: every requirement, called generically, does what the concrete member
// does, and the key hooks agree with `vertices`. See README.md.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("UndirectedAdjacencyList as MutableGraph")
struct UndirectedAdjacencyListMutableGraphTests {
    @Test("Removal, clearing, reserving and keys through the protocol")
    func protocolMembers() {
        func exercise<G: MutableGraph>(_ graph: G) -> [String] where G.Vertex == String {
            var g = graph
            var log: [String] = []
            g.reserveCapacity(vertexCount: 10, edgeCount: 20)
            for k in 0 ..< g.vertexCount { log.append("key \(k) \(g._vertex(atKey: k)) \(g._key(of: g._vertex(atKey: k))!)") }
            log.append("remove edge \(String(describing: g.remove(edge: UndirectedEdge("c", "b"))))")
            log.append("remove missing edge \(String(describing: g.remove(edge: UndirectedEdge("a", "d"))))")
            log.append("remove vertex \(String(describing: g.remove("a")))")
            log.append("remove missing vertex \(String(describing: g.remove("z")))")
            log.append("after \(Array(g.vertices)) \(g.edges.map { "\($0.u)-\($0.v)" })")
            for k in 0 ..< g.vertexCount { log.append("key \(k) \(g._vertex(atKey: k))") }
            var edgeless = g
            edgeless.removeAllEdges(keepingCapacity: true)
            log.append("edgeless \(Array(edgeless.vertices)) \(edgeless.edgeCount)")
            g.removeAll(keepingCapacity: false)
            log.append("empty \(g.vertexCount) \(g.edgeCount)")
            return log
        }
        let graph = UndirectedAdjacencyList<String>(vertices: ["a", "b", "c", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d")])
        // The same steps on the concrete type.
        var expected = graph
        var log: [String] = []
        for (k, v) in graph.vertices.enumerated() { log.append("key \(k) \(v) \(k)") }
        log.append("remove edge \(String(describing: expected.remove(edge: UndirectedEdge("c", "b"))))")
        log.append("remove missing edge \(String(describing: expected.remove(edge: UndirectedEdge("a", "d"))))")
        log.append("remove vertex \(String(describing: expected.remove("a")))")
        log.append("remove missing vertex \(String(describing: expected.remove("z")))")
        log.append("after \(Array(expected.vertices)) \(expected.edges.map { "\($0.u)-\($0.v)" })")
        for (k, v) in expected.vertices.enumerated() { log.append("key \(k) \(v)") }
        log.append("edgeless \(Array(expected.vertices)) 0")
        log.append("empty 0 0")
        #expect(exercise(graph) == log)
        #expect(log.contains("remove missing edge nil") && log.contains("remove vertex Optional(\"a\")"))
        #expect(!log.contains("remove edge nil"))
    }
}
