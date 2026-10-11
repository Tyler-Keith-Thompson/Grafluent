// Codable (catalog DAG-087 – DAG-090): `{base, order}` with the order as offsets into `base.vertices`; a
// round trip keeps the order; decoding rejects a cyclic base, an order that is not a permutation and an
// edge going backward, as `DecodingError.dataCorrupted`.
// Generated from cases.md by swiftgen.py; see README.md.

import DirectedAcyclicGraphModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("DirectedAcyclicGraph Codable")
struct DirectedAcyclicGraphCodableTests {
    @Test("DAG-087 round trip keeps the order", .tags(.conformance))
    func dag087() throws {
        // DirectedPseudograph; decode {base: V [0, 1, 2]; E [2→0], order: [1, 2, 0]} → order [1, 2, 0]; V [0, 1, 2]; E [0:2→0]
        let base = String(decoding: try JSONEncoder().encode(DirectedPseudograph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 2, to: 0)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [1, 2, 0]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: payload)
        #expect(Array(graph.topologicalOrder) == [1, 2, 0])
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(Array(graph.edges.indices) == [0])
        #expect(Array(graph.edges) == [DirectedEdge(from: 2, to: 0)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 1)
        #expect(graph.topologicalOrder.count == 3 && graph.topologicalOrder.indices == 0 ..< 3)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[2, 0]])
        #expect(Array(graph.base.vertices) == [0, 1, 2] && Array(graph.base.edges) == [DirectedEdge(from: 2, to: 0)])
        #expect(graph.topologicalPosition(of: 0) == 2 && graph.topologicalPosition(safe: 0) == 2 && graph.topologicalOrder.firstIndex(of: 0) == 2)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [2] && Array(graph.inEdges(of: 0)) == [0] && graph.inDegree(of: 0) == 1)
        #expect(graph.successors(safe: 0).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 0) == 0)
        #expect(graph.predecessors(safe: 0).map { Array($0) } == [2] && graph.inEdges(safe: 0).map { Array($0) } == [0] && graph.inDegree(safe: 0) == 1)
        #expect(graph.topologicalPosition(of: 1) == 0 && graph.topologicalPosition(safe: 1) == 0 && graph.topologicalOrder.firstIndex(of: 1) == 0)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int] && Array(graph.inEdges(of: 1)) == [] as [Int] && graph.inDegree(of: 1) == 0)
        #expect(graph.successors(safe: 1).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 1).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 1) == 0)
        #expect(graph.predecessors(safe: 1).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 1).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 1) == 0)
        #expect(graph.topologicalPosition(of: 2) == 1 && graph.topologicalPosition(safe: 2) == 1 && graph.topologicalOrder.firstIndex(of: 2) == 1)
        #expect(Array(graph.successors(of: 2)) == [0] && Array(graph.outEdges(of: 2)) == [0] && graph.outDegree(of: 2) == 1)
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int] && Array(graph.inEdges(of: 2)) == [] as [Int] && graph.inDegree(of: 2) == 0)
        #expect(graph.successors(safe: 2).map { Array($0) } == [0] && graph.outEdges(safe: 2).map { Array($0) } == [0] && graph.outDegree(safe: 2) == 1)
        #expect(graph.predecessors(safe: 2).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 2).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 2) == 0)
        #expect(!graph.contains(102) && graph.topologicalPosition(safe: 102) == nil && graph.topologicalOrder.firstIndex(of: 102) == nil)
        #expect(graph.successors(safe: 102) == nil && graph.predecessors(safe: 102) == nil && graph.outEdges(safe: 102) == nil)
        #expect(graph.inEdges(safe: 102) == nil && graph.outDegree(safe: 102) == nil && graph.inDegree(safe: 102) == nil)
        // Encoding and decoding again keeps the order.
        let again = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: try JSONEncoder().encode(graph))
        #expect(Array(again.topologicalOrder) == [1, 2, 0])
        #expect(Array(again.vertices) == [0, 1, 2])
        #expect(Array(again.edges.indices) == [0])
        #expect(Array(again.edges) == [DirectedEdge(from: 2, to: 0)])
        #expect(again == graph)
    }

    @Test("DAG-088 cyclic base rejected", .tags(.conformance))
    func dag088() throws {
        // DirectedPseudograph; decode {base: V [0, 1]; E [0→1, 1→0], order: [0, 1]} → DecodingError.dataCorrupted (a cycle)
        let base = String(decoding: try JSONEncoder().encode(DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The same base with a valid order decodes.
        let valid = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        // The base itself has a cycle, so no order decodes.
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: valid) }
    }

    @Test("DAG-089 order not a permutation rejected", .tags(.conformance))
    func dag089() throws {
        // DirectedPseudograph; decode {base: V [0, 1]; E [], order: [0, 0]} → DecodingError.dataCorrupted (not a permutation)
        let base = String(decoding: try JSONEncoder().encode(DirectedPseudograph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [0, 0]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The same base with a valid order decodes.
        let valid = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: valid)
        #expect(Array(graph.topologicalOrder) == [0, 1])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 2 && graph.topologicalOrder.indices == 0 ..< 2)
        #expect(Array(graph.base.vertices) == [0, 1] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(safe: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(graph.successors(safe: 0).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 0) == 0)
        #expect(graph.predecessors(safe: 0).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 0) == 0)
        #expect(graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(safe: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int] && Array(graph.inEdges(of: 1)) == [] as [Int] && graph.inDegree(of: 1) == 0)
        #expect(graph.successors(safe: 1).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 1).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 1) == 0)
        #expect(graph.predecessors(safe: 1).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 1).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 1) == 0)
        #expect(!graph.contains(101) && graph.topologicalPosition(safe: 101) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect(graph.successors(safe: 101) == nil && graph.predecessors(safe: 101) == nil && graph.outEdges(safe: 101) == nil)
        #expect(graph.inEdges(safe: 101) == nil && graph.outDegree(safe: 101) == nil && graph.inDegree(safe: 101) == nil)
    }

    @Test("DAG-090 edge going backward in the order rejected", .tags(.conformance))
    func dag090() throws {
        // DirectedPseudograph; decode {base: V [0, 1]; E [0→1], order: [1, 0]} → DecodingError.dataCorrupted (an edge goes backward)
        let base = String(decoding: try JSONEncoder().encode(DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [1, 0]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted {
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The same base with a valid order decodes.
        let valid = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: valid)
        #expect(Array(graph.topologicalOrder) == [0, 1])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.edges.indices) == [0])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(graph.topologicalOrder.count == 2 && graph.topologicalOrder.indices == 0 ..< 2)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(Array(graph.base.vertices) == [0, 1] && Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(safe: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1] && Array(graph.outEdges(of: 0)) == [0] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(graph.successors(safe: 0).map { Array($0) } == [1] && graph.outEdges(safe: 0).map { Array($0) } == [0] && graph.outDegree(safe: 0) == 1)
        #expect(graph.predecessors(safe: 0).map { Array($0) } == [] as [Int] && graph.inEdges(safe: 0).map { Array($0) } == [] as [Int] && graph.inDegree(safe: 0) == 0)
        #expect(graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(safe: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [0] && Array(graph.inEdges(of: 1)) == [0] && graph.inDegree(of: 1) == 1)
        #expect(graph.successors(safe: 1).map { Array($0) } == [] as [Int] && graph.outEdges(safe: 1).map { Array($0) } == [] as [Int] && graph.outDegree(safe: 1) == 0)
        #expect(graph.predecessors(safe: 1).map { Array($0) } == [0] && graph.inEdges(safe: 1).map { Array($0) } == [0] && graph.inDegree(safe: 1) == 1)
        #expect(!graph.contains(101) && graph.topologicalPosition(safe: 101) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect(graph.successors(safe: 101) == nil && graph.predecessors(safe: 101) == nil && graph.outEdges(safe: 101) == nil)
        #expect(graph.inEdges(safe: 101) == nil && graph.outDegree(safe: 101) == nil && graph.inDegree(safe: 101) == nil)
    }
}
