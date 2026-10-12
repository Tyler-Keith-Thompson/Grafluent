// Codable (catalog DAG-112 – DAG-123): `{base, order}` with the order as offsets into `base.vertices`; a
// round trip keeps the order; decoding rejects a cyclic base, an order that is not a permutation and an
// edge going backward, as `DecodingError.dataCorrupted`.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import StableGraphs
import Testing

@Suite("DirectedAcyclicGraph Codable")
struct DirectedAcyclicGraphCodableTests {
    @Test("DAG-112 round trip keeps the order", .tags(.conformance))
    func dag112() throws {
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
        #expect(try graph.topologicalPosition(of: 0) == 2 && graph.topologicalPosition(checked: 0) == 2 && graph.topologicalOrder.firstIndex(of: 0) == 2)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [2] && Array(graph.inEdges(of: 0)) == [0] && graph.inDegree(of: 0) == 1)
        #expect(try Array(graph.successors(checked: 0)) == [] as [Int] && Array(graph.outEdges(checked: 0)) == [] as [Int] && graph.outDegree(checked: 0) == 0)
        #expect(try Array(graph.predecessors(checked: 0)) == [2] && Array(graph.inEdges(checked: 0)) == [0] && graph.inDegree(checked: 0) == 1)
        #expect(try graph.topologicalPosition(of: 1) == 0 && graph.topologicalPosition(checked: 1) == 0 && graph.topologicalOrder.firstIndex(of: 1) == 0)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int] && Array(graph.inEdges(of: 1)) == [] as [Int] && graph.inDegree(of: 1) == 0)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int] && Array(graph.outEdges(checked: 1)) == [] as [Int] && graph.outDegree(checked: 1) == 0)
        #expect(try Array(graph.predecessors(checked: 1)) == [] as [Int] && Array(graph.inEdges(checked: 1)) == [] as [Int] && graph.inDegree(checked: 1) == 0)
        #expect(try graph.topologicalPosition(of: 2) == 1 && graph.topologicalPosition(checked: 2) == 1 && graph.topologicalOrder.firstIndex(of: 2) == 1)
        #expect(Array(graph.successors(of: 2)) == [0] && Array(graph.outEdges(of: 2)) == [0] && graph.outDegree(of: 2) == 1)
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int] && Array(graph.inEdges(of: 2)) == [] as [Int] && graph.inDegree(of: 2) == 0)
        #expect(try Array(graph.successors(checked: 2)) == [0] && Array(graph.outEdges(checked: 2)) == [0] && graph.outDegree(checked: 2) == 1)
        #expect(try Array(graph.predecessors(checked: 2)) == [] as [Int] && Array(graph.inEdges(checked: 2)) == [] as [Int] && graph.inDegree(checked: 2) == 0)
        #expect(!graph.contains(102) && (try? graph.topologicalPosition(checked: 102)) == nil && graph.topologicalOrder.firstIndex(of: 102) == nil)
        #expect((try? graph.successors(checked: 102)) == nil && (try? graph.predecessors(checked: 102)) == nil && (try? graph.outEdges(checked: 102)) == nil)
        #expect((try? graph.inEdges(checked: 102)) == nil && (try? graph.outDegree(checked: 102)) == nil && (try? graph.inDegree(checked: 102)) == nil)
        // Encoding and decoding again keeps the order.
        let again = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: try JSONEncoder().encode(graph))
        #expect(Array(again.topologicalOrder) == [1, 2, 0])
        #expect(Array(again.vertices) == [0, 1, 2])
        #expect(Array(again.edges.indices) == [0])
        #expect(Array(again.edges) == [DirectedEdge(from: 2, to: 0)])
        #expect(again == graph)
    }

    @Test("DAG-113 cyclic base rejected", .tags(.conformance))
    func dag113() throws {
        // DirectedPseudograph; decode {base: V [0, 1]; E [0→1, 1→0], order: [0, 1]} → DecodingError.dataCorrupted (a cycle)
        let base = String(decoding: try JSONEncoder().encode(DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["base"])
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The base itself has a cycle, so no order decodes.
        let valid = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: valid) }
    }

    @Test("DAG-114 order not a permutation rejected", .tags(.conformance))
    func dag114() throws {
        // DirectedPseudograph; decode {base: V [0, 1]; E [], order: [0, 0]} → DecodingError.dataCorrupted (not a permutation)
        let base = String(decoding: try JSONEncoder().encode(DirectedPseudograph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [0, 0]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["order"])
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
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [] as [Int] && Array(graph.outEdges(checked: 0)) == [] as [Int] && graph.outDegree(checked: 0) == 0)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int] && Array(graph.inEdges(of: 1)) == [] as [Int] && graph.inDegree(of: 1) == 0)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int] && Array(graph.outEdges(checked: 1)) == [] as [Int] && graph.outDegree(checked: 1) == 0)
        #expect(try Array(graph.predecessors(checked: 1)) == [] as [Int] && Array(graph.inEdges(checked: 1)) == [] as [Int] && graph.inDegree(checked: 1) == 0)
        #expect(!graph.contains(101) && (try? graph.topologicalPosition(checked: 101)) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect((try? graph.successors(checked: 101)) == nil && (try? graph.predecessors(checked: 101)) == nil && (try? graph.outEdges(checked: 101)) == nil)
        #expect((try? graph.inEdges(checked: 101)) == nil && (try? graph.outDegree(checked: 101)) == nil && (try? graph.inDegree(checked: 101)) == nil)
    }

    @Test("DAG-115 edge going backward in the order rejected", .tags(.conformance))
    func dag115() throws {
        // DirectedPseudograph; decode {base: V [0, 1]; E [0→1], order: [1, 0]} → DecodingError.dataCorrupted (an edge goes backward)
        let base = String(decoding: try JSONEncoder().encode(DirectedPseudograph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [1, 0]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["order"])
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
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1] && Array(graph.outEdges(of: 0)) == [0] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [1] && Array(graph.outEdges(checked: 0)) == [0] && graph.outDegree(checked: 0) == 1)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [0] && Array(graph.inEdges(of: 1)) == [0] && graph.inDegree(of: 1) == 1)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int] && Array(graph.outEdges(checked: 1)) == [] as [Int] && graph.outDegree(checked: 1) == 0)
        #expect(try Array(graph.predecessors(checked: 1)) == [0] && Array(graph.inEdges(checked: 1)) == [0] && graph.inDegree(checked: 1) == 1)
        #expect(!graph.contains(101) && (try? graph.topologicalPosition(checked: 101)) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect((try? graph.successors(checked: 101)) == nil && (try? graph.predecessors(checked: 101)) == nil && (try? graph.outEdges(checked: 101)) == nil)
        #expect((try? graph.inEdges(checked: 101)) == nil && (try? graph.outDegree(checked: 101)) == nil && (try? graph.inDegree(checked: 101)) == nil)
    }

    @Test("DAG-116 AdjacencyList: round trip keeps the order", .tags(.conformance))
    func dag116() throws {
        // AdjacencyList; decode {base: V [0, 1, 2, 3]; E [3→1, 1→0], order: [2, 3, 1, 0]} → order [2, 3, 1, 0]; V [0, 1, 2, 3]; E [0:3→1, 1:1→0]
        let base = String(decoding: try JSONEncoder().encode(AdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 0)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [2, 3, 1, 0]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<AdjacencyList<Int>>.self, from: payload)
        #expect(Array(graph.topologicalOrder) == [2, 3, 1, 0])
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(Array(graph.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 2)
        #expect(graph.topologicalOrder.count == 4 && graph.topologicalOrder.indices == 0 ..< 4)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[3, 1], [1, 0]])
        #expect(Array(graph.base.vertices) == [0, 1, 2, 3] && Array(graph.base.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(try graph.topologicalPosition(of: 0) == 3 && graph.topologicalPosition(checked: 0) == 3 && graph.topologicalOrder.firstIndex(of: 0) == 3)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [1] && Array(graph.inEdges(of: 0)) == [1] && graph.inDegree(of: 0) == 1)
        #expect(try Array(graph.successors(checked: 0)) == [] as [Int] && Array(graph.outEdges(checked: 0)) == [] as [Int] && graph.outDegree(checked: 0) == 0)
        #expect(try Array(graph.predecessors(checked: 0)) == [1] && Array(graph.inEdges(checked: 0)) == [1] && graph.inDegree(checked: 0) == 1)
        #expect(try graph.topologicalPosition(of: 1) == 2 && graph.topologicalPosition(checked: 1) == 2 && graph.topologicalOrder.firstIndex(of: 1) == 2)
        #expect(Array(graph.successors(of: 1)) == [0] && Array(graph.outEdges(of: 1)) == [1] && graph.outDegree(of: 1) == 1)
        #expect(Array(graph.predecessors(of: 1)) == [3] && Array(graph.inEdges(of: 1)) == [0] && graph.inDegree(of: 1) == 1)
        #expect(try Array(graph.successors(checked: 1)) == [0] && Array(graph.outEdges(checked: 1)) == [1] && graph.outDegree(checked: 1) == 1)
        #expect(try Array(graph.predecessors(checked: 1)) == [3] && Array(graph.inEdges(checked: 1)) == [0] && graph.inDegree(checked: 1) == 1)
        #expect(try graph.topologicalPosition(of: 2) == 0 && graph.topologicalPosition(checked: 2) == 0 && graph.topologicalOrder.firstIndex(of: 2) == 0)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int] && Array(graph.inEdges(of: 2)) == [] as [Int] && graph.inDegree(of: 2) == 0)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [] as [Int] && Array(graph.inEdges(checked: 2)) == [] as [Int] && graph.inDegree(checked: 2) == 0)
        #expect(try graph.topologicalPosition(of: 3) == 1 && graph.topologicalPosition(checked: 3) == 1 && graph.topologicalOrder.firstIndex(of: 3) == 1)
        #expect(Array(graph.successors(of: 3)) == [1] && Array(graph.outEdges(of: 3)) == [0] && graph.outDegree(of: 3) == 1)
        #expect(Array(graph.predecessors(of: 3)) == [] as [Int] && Array(graph.inEdges(of: 3)) == [] as [Int] && graph.inDegree(of: 3) == 0)
        #expect(try Array(graph.successors(checked: 3)) == [1] && Array(graph.outEdges(checked: 3)) == [0] && graph.outDegree(checked: 3) == 1)
        #expect(try Array(graph.predecessors(checked: 3)) == [] as [Int] && Array(graph.inEdges(checked: 3)) == [] as [Int] && graph.inDegree(checked: 3) == 0)
        #expect(!graph.contains(103) && (try? graph.topologicalPosition(checked: 103)) == nil && graph.topologicalOrder.firstIndex(of: 103) == nil)
        #expect((try? graph.successors(checked: 103)) == nil && (try? graph.predecessors(checked: 103)) == nil && (try? graph.outEdges(checked: 103)) == nil)
        #expect((try? graph.inEdges(checked: 103)) == nil && (try? graph.outDegree(checked: 103)) == nil && (try? graph.inDegree(checked: 103)) == nil)
        // Encoding and decoding again keeps the order.
        let again = try JSONDecoder().decode(DirectedAcyclicGraph<AdjacencyList<Int>>.self, from: try JSONEncoder().encode(graph))
        #expect(Array(again.topologicalOrder) == [2, 3, 1, 0])
        #expect(Array(again.vertices) == [0, 1, 2, 3])
        #expect(Array(again.edges.indices) == [0, 1])
        #expect(Array(again.edges) == [DirectedEdge(from: 3, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(again == graph)
    }

    @Test("DAG-117 AdjacencyList: edge going backward rejected", .tags(.conformance))
    func dag117() throws {
        // AdjacencyList; decode {base: V [0, 1, 2]; E [1→2], order: [2, 1, 0]} → DecodingError.dataCorrupted (an edge goes backward)
        let base = String(decoding: try JSONEncoder().encode(AdjacencyList<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 1, to: 2)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [2, 1, 0]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<AdjacencyList<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["order"])
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The same base with a valid order decodes.
        let valid = Data(#"{"base": \#(base), "order": [0, 1, 2]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<AdjacencyList<Int>>.self, from: valid)
        #expect(Array(graph.topologicalOrder) == [0, 1, 2])
        #expect(Array(graph.vertices) == [0, 1, 2])
        #expect(Array(graph.edges.indices) == [0])
        #expect(Array(graph.edges) == [DirectedEdge(from: 1, to: 2)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 1)
        #expect(graph.topologicalOrder.count == 3 && graph.topologicalOrder.indices == 0 ..< 3)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[1, 2]])
        #expect(Array(graph.base.vertices) == [0, 1, 2] && Array(graph.base.edges) == [DirectedEdge(from: 1, to: 2)])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [] as [Int] && Array(graph.outEdges(checked: 0)) == [] as [Int] && graph.outDegree(checked: 0) == 0)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [2] && Array(graph.outEdges(of: 1)) == [0] && graph.outDegree(of: 1) == 1)
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int] && Array(graph.inEdges(of: 1)) == [] as [Int] && graph.inDegree(of: 1) == 0)
        #expect(try Array(graph.successors(checked: 1)) == [2] && Array(graph.outEdges(checked: 1)) == [0] && graph.outDegree(checked: 1) == 1)
        #expect(try Array(graph.predecessors(checked: 1)) == [] as [Int] && Array(graph.inEdges(checked: 1)) == [] as [Int] && graph.inDegree(checked: 1) == 0)
        #expect(try graph.topologicalPosition(of: 2) == 2 && graph.topologicalPosition(checked: 2) == 2 && graph.topologicalOrder.firstIndex(of: 2) == 2)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [1] && Array(graph.inEdges(of: 2)) == [0] && graph.inDegree(of: 2) == 1)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [1] && Array(graph.inEdges(checked: 2)) == [0] && graph.inDegree(checked: 2) == 1)
        #expect(!graph.contains(102) && (try? graph.topologicalPosition(checked: 102)) == nil && graph.topologicalOrder.firstIndex(of: 102) == nil)
        #expect((try? graph.successors(checked: 102)) == nil && (try? graph.predecessors(checked: 102)) == nil && (try? graph.outEdges(checked: 102)) == nil)
        #expect((try? graph.inEdges(checked: 102)) == nil && (try? graph.outDegree(checked: 102)) == nil && (try? graph.inDegree(checked: 102)) == nil)
    }

    @Test("DAG-118 StableDirectedGraph with holes: offsets into the live vertices", .tags(.conformance))
    func dag118() throws {
        // StableDirectedGraph; decode {base: V [0, 1, 2, 3, 4]; E [4→0, 0→2] / remove(1) / remove(3), order: [2, 0, 1]} → order [4, 0, 2]; V [0, 2, 4]; E [0:4→0, 1:0→2]
        var baseGraph = StableDirectedGraph<Int>(vertices: [0, 1, 2, 3, 4], edges: [DirectedEdge(from: 4, to: 0), DirectedEdge(from: 0, to: 2)])
        _ = baseGraph.remove(1)
        _ = baseGraph.remove(3)
        let base = String(decoding: try JSONEncoder().encode(baseGraph), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [2, 0, 1]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: payload)
        #expect(Array(graph.topologicalOrder) == [4, 0, 2])
        #expect(Array(graph.vertices) == [0, 2, 4])
        #expect(Array(graph.edges.indices) == [0, 1])
        #expect(Array(graph.edges) == [DirectedEdge(from: 4, to: 0), DirectedEdge(from: 0, to: 2)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(graph.topologicalOrder.count == 3 && graph.topologicalOrder.indices == 0 ..< 3)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[4, 0], [0, 2]])
        #expect(Array(graph.base.vertices) == [0, 2, 4] && Array(graph.base.edges) == [DirectedEdge(from: 4, to: 0), DirectedEdge(from: 0, to: 2)])
        #expect(try graph.topologicalPosition(of: 0) == 1 && graph.topologicalPosition(checked: 0) == 1 && graph.topologicalOrder.firstIndex(of: 0) == 1)
        #expect(Array(graph.successors(of: 0)) == [2] && Array(graph.outEdges(of: 0)) == [1] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [4] && Array(graph.inEdges(of: 0)) == [0] && graph.inDegree(of: 0) == 1)
        #expect(try Array(graph.successors(checked: 0)) == [2] && Array(graph.outEdges(checked: 0)) == [1] && graph.outDegree(checked: 0) == 1)
        #expect(try Array(graph.predecessors(checked: 0)) == [4] && Array(graph.inEdges(checked: 0)) == [0] && graph.inDegree(checked: 0) == 1)
        #expect(try graph.topologicalPosition(of: 2) == 2 && graph.topologicalPosition(checked: 2) == 2 && graph.topologicalOrder.firstIndex(of: 2) == 2)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [0] && Array(graph.inEdges(of: 2)) == [1] && graph.inDegree(of: 2) == 1)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [0] && Array(graph.inEdges(checked: 2)) == [1] && graph.inDegree(checked: 2) == 1)
        #expect(try graph.topologicalPosition(of: 4) == 0 && graph.topologicalPosition(checked: 4) == 0 && graph.topologicalOrder.firstIndex(of: 4) == 0)
        #expect(Array(graph.successors(of: 4)) == [0] && Array(graph.outEdges(of: 4)) == [0] && graph.outDegree(of: 4) == 1)
        #expect(Array(graph.predecessors(of: 4)) == [] as [Int] && Array(graph.inEdges(of: 4)) == [] as [Int] && graph.inDegree(of: 4) == 0)
        #expect(try Array(graph.successors(checked: 4)) == [0] && Array(graph.outEdges(checked: 4)) == [0] && graph.outDegree(checked: 4) == 1)
        #expect(try Array(graph.predecessors(checked: 4)) == [] as [Int] && Array(graph.inEdges(checked: 4)) == [] as [Int] && graph.inDegree(checked: 4) == 0)
        #expect(!graph.contains(104) && (try? graph.topologicalPosition(checked: 104)) == nil && graph.topologicalOrder.firstIndex(of: 104) == nil)
        #expect((try? graph.successors(checked: 104)) == nil && (try? graph.predecessors(checked: 104)) == nil && (try? graph.outEdges(checked: 104)) == nil)
        #expect((try? graph.inEdges(checked: 104)) == nil && (try? graph.outDegree(checked: 104)) == nil && (try? graph.inDegree(checked: 104)) == nil)
        // Encoding and decoding again keeps the order.
        let again = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: try JSONEncoder().encode(graph))
        #expect(Array(again.topologicalOrder) == [4, 0, 2])
        #expect(Array(again.vertices) == [0, 2, 4])
        #expect(Array(again.edges.indices) == [0, 1])
        #expect(Array(again.edges) == [DirectedEdge(from: 4, to: 0), DirectedEdge(from: 0, to: 2)])
        #expect(again == graph)
    }

    @Test("DAG-119 StableDirectedGraph with holes: an offset past the live vertices rejected", .tags(.conformance))
    func dag119() throws {
        // StableDirectedGraph; decode {base: V [0, 1, 2]; E [] / remove(1), order: [0, 2]} → DecodingError.dataCorrupted (not a permutation)
        var baseGraph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [] as [DirectedEdge<Int>])
        _ = baseGraph.remove(1)
        let base = String(decoding: try JSONEncoder().encode(baseGraph), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [0, 2]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["order"])
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The same base with a valid order decodes.
        let valid = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: valid)
        #expect(Array(graph.topologicalOrder) == [0, 2])
        #expect(Array(graph.vertices) == [0, 2])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 2 && graph.topologicalOrder.indices == 0 ..< 2)
        #expect(Array(graph.base.vertices) == [0, 2] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [] as [Int] && Array(graph.outEdges(checked: 0)) == [] as [Int] && graph.outDegree(checked: 0) == 0)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 2) == 1 && graph.topologicalPosition(checked: 2) == 1 && graph.topologicalOrder.firstIndex(of: 2) == 1)
        #expect(Array(graph.successors(of: 2)) == [] as [Int] && Array(graph.outEdges(of: 2)) == [] as [Int] && graph.outDegree(of: 2) == 0)
        #expect(Array(graph.predecessors(of: 2)) == [] as [Int] && Array(graph.inEdges(of: 2)) == [] as [Int] && graph.inDegree(of: 2) == 0)
        #expect(try Array(graph.successors(checked: 2)) == [] as [Int] && Array(graph.outEdges(checked: 2)) == [] as [Int] && graph.outDegree(checked: 2) == 0)
        #expect(try Array(graph.predecessors(checked: 2)) == [] as [Int] && Array(graph.inEdges(checked: 2)) == [] as [Int] && graph.inDegree(checked: 2) == 0)
        #expect(!graph.contains(102) && (try? graph.topologicalPosition(checked: 102)) == nil && graph.topologicalOrder.firstIndex(of: 102) == nil)
        #expect((try? graph.successors(checked: 102)) == nil && (try? graph.predecessors(checked: 102)) == nil && (try? graph.outEdges(checked: 102)) == nil)
        #expect((try? graph.inEdges(checked: 102)) == nil && (try? graph.outDegree(checked: 102)) == nil && (try? graph.inDegree(checked: 102)) == nil)
    }

    @Test("DAG-120 StableDirectedGraph: a vertex at position 2⁵⁰ costs one page, not a table to it", .tags(.conformance))
    func dag120() throws {
        // StableDirectedGraph; decode {"base": {"vertices": [7], "vertexPositions": [1125899906842624], "vertexEnd": 1125899906842625, "edges": [], "edgePositions": [], "edgeEnd": 0}, "order": [0]} → order [7]; V [7]; E []
        // Before the key table started at the first live page, this allocated a table entry for
        // every page below the position: 2⁴⁰ words.
        let payload = Data(#"{"base": {"vertices": [7], "vertexPositions": [1125899906842624], "vertexEnd": 1125899906842625, "edges": [], "edgePositions": [], "edgeEnd": 0}, "order": [0]}"#.utf8)
        var graph = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: payload)
        #expect(Array(graph.topologicalOrder) == [7])
        #expect(Array(graph.vertices) == [7])
        #expect(Array(graph.edges.indices) == [] as [Int])
        #expect(Array(graph.edges) == [] as [DirectedEdge<Int>])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(graph.topologicalOrder.count == 1 && graph.topologicalOrder.indices == 0 ..< 1)
        #expect(Array(graph.base.vertices) == [7] && Array(graph.base.edges) == [] as [DirectedEdge<Int>])
        #expect(try graph.topologicalPosition(of: 7) == 0 && graph.topologicalPosition(checked: 7) == 0 && graph.topologicalOrder.firstIndex(of: 7) == 0)
        #expect(Array(graph.successors(of: 7)) == [] as [Int] && Array(graph.outEdges(of: 7)) == [] as [Int] && graph.outDegree(of: 7) == 0)
        #expect(Array(graph.predecessors(of: 7)) == [] as [Int] && Array(graph.inEdges(of: 7)) == [] as [Int] && graph.inDegree(of: 7) == 0)
        #expect(try Array(graph.successors(checked: 7)) == [] as [Int] && Array(graph.outEdges(checked: 7)) == [] as [Int] && graph.outDegree(checked: 7) == 0)
        #expect(try Array(graph.predecessors(checked: 7)) == [] as [Int] && Array(graph.inEdges(checked: 7)) == [] as [Int] && graph.inDegree(checked: 7) == 0)
        #expect(!graph.contains(107) && (try? graph.topologicalPosition(checked: 107)) == nil && graph.topologicalOrder.firstIndex(of: 107) == nil)
        #expect((try? graph.successors(checked: 107)) == nil && (try? graph.predecessors(checked: 107)) == nil && (try? graph.outEdges(checked: 107)) == nil)
        #expect((try? graph.inEdges(checked: 107)) == nil && (try? graph.outDegree(checked: 107)) == nil && (try? graph.inDegree(checked: 107)) == nil)
        let again = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: try JSONEncoder().encode(graph))
        #expect(again == graph && Array(again.topologicalOrder) == [7])
        // Inserting next to it, before it, and removing it all work from that one page.
        #expect(try graph.insert(edge: DirectedEdge(from: 7, to: 8)) == 0)
        #expect(try graph.insert(edge: DirectedEdge(from: 9, to: 7)) == 1)
        #expect(Array(graph.topologicalOrder) == [9, 7, 8])
        #expect(graph.base.vertexPosition(of: 9) == 1125899906842626)
        #expect(graph.topologicalPosition(of: 8) == 2)
        #expect(throws: AcyclicEdgeError.cycle) { try graph.insert(edge: DirectedEdge(from: 8, to: 9)) }
        #expect(graph.remove(7) == 7)
        #expect(Array(graph.topologicalOrder) == [9, 8] && graph.topologicalPosition(of: 8) == 1)
    }

    @Test("DAG-121 an order shorter than the vertices rejected", .tags(.conformance))
    func dag121() throws {
        // DirectedPseudograph; decode {base: V [0, 1]; E [], order: [0]} → DecodingError.dataCorrupted (not a permutation)
        let base = String(decoding: try JSONEncoder().encode(DirectedPseudograph<Int>(vertices: [0, 1], edges: [] as [DirectedEdge<Int>])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [0]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<DirectedPseudograph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["order"])
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
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [] as [Int] && Array(graph.outEdges(of: 0)) == [] as [Int] && graph.outDegree(of: 0) == 0)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [] as [Int] && Array(graph.outEdges(checked: 0)) == [] as [Int] && graph.outDegree(checked: 0) == 0)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [] as [Int] && Array(graph.inEdges(of: 1)) == [] as [Int] && graph.inDegree(of: 1) == 0)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int] && Array(graph.outEdges(checked: 1)) == [] as [Int] && graph.outDegree(checked: 1) == 0)
        #expect(try Array(graph.predecessors(checked: 1)) == [] as [Int] && Array(graph.inEdges(checked: 1)) == [] as [Int] && graph.inDegree(checked: 1) == 0)
        #expect(!graph.contains(101) && (try? graph.topologicalPosition(checked: 101)) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect((try? graph.successors(checked: 101)) == nil && (try? graph.predecessors(checked: 101)) == nil && (try? graph.outEdges(checked: 101)) == nil)
        #expect((try? graph.inEdges(checked: 101)) == nil && (try? graph.outDegree(checked: 101)) == nil && (try? graph.inDegree(checked: 101)) == nil)
    }

    @Test("DAG-122 an order longer than the vertices rejected", .tags(.conformance))
    func dag122() throws {
        // AdjacencyList; decode {base: V [0, 1]; E [0→1], order: [0, 1, 2]} → DecodingError.dataCorrupted (not a permutation)
        let base = String(decoding: try JSONEncoder().encode(AdjacencyList<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [0, 1, 2]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<AdjacencyList<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["order"])
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The same base with a valid order decodes.
        let valid = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<AdjacencyList<Int>>.self, from: valid)
        #expect(Array(graph.topologicalOrder) == [0, 1])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.edges.indices) == [0])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(graph.topologicalOrder.count == 2 && graph.topologicalOrder.indices == 0 ..< 2)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(Array(graph.base.vertices) == [0, 1] && Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1] && Array(graph.outEdges(of: 0)) == [0] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [1] && Array(graph.outEdges(checked: 0)) == [0] && graph.outDegree(checked: 0) == 1)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [0] && Array(graph.inEdges(of: 1)) == [0] && graph.inDegree(of: 1) == 1)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int] && Array(graph.outEdges(checked: 1)) == [] as [Int] && graph.outDegree(checked: 1) == 0)
        #expect(try Array(graph.predecessors(checked: 1)) == [0] && Array(graph.inEdges(checked: 1)) == [0] && graph.inDegree(checked: 1) == 1)
        #expect(!graph.contains(101) && (try? graph.topologicalPosition(checked: 101)) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect((try? graph.successors(checked: 101)) == nil && (try? graph.predecessors(checked: 101)) == nil && (try? graph.outEdges(checked: 101)) == nil)
        #expect((try? graph.inEdges(checked: 101)) == nil && (try? graph.outDegree(checked: 101)) == nil && (try? graph.inDegree(checked: 101)) == nil)
    }

    @Test("DAG-123 a negative offset rejected", .tags(.conformance))
    func dag123() throws {
        // StableDirectedGraph; decode {base: V [0, 1]; E [0→1], order: [-1, 1]} → DecodingError.dataCorrupted (not a permutation)
        let base = String(decoding: try JSONEncoder().encode(StableDirectedGraph<Int>(vertices: [0, 1], edges: [DirectedEdge(from: 0, to: 1)])), as: UTF8.self)
        let payload = Data(#"{"base": \#(base), "order": [-1, 1]}"#.utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["order"])
        } catch {
            Issue.record("unexpected error \(error)")
        }
        // The same base with a valid order decodes.
        let valid = Data(#"{"base": \#(base), "order": [0, 1]}"#.utf8)
        let graph = try JSONDecoder().decode(DirectedAcyclicGraph<StableDirectedGraph<Int>>.self, from: valid)
        #expect(Array(graph.topologicalOrder) == [0, 1])
        #expect(Array(graph.vertices) == [0, 1])
        #expect(Array(graph.edges.indices) == [0])
        #expect(Array(graph.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(graph.topologicalOrder.count == 2 && graph.topologicalOrder.indices == 0 ..< 2)
        #expect(graph.edges.indices.map { [graph.source(ofEdgeAt: $0), graph.target(ofEdgeAt: $0)] } == [[0, 1]])
        #expect(Array(graph.base.vertices) == [0, 1] && Array(graph.base.edges) == [DirectedEdge(from: 0, to: 1)])
        #expect(try graph.topologicalPosition(of: 0) == 0 && graph.topologicalPosition(checked: 0) == 0 && graph.topologicalOrder.firstIndex(of: 0) == 0)
        #expect(Array(graph.successors(of: 0)) == [1] && Array(graph.outEdges(of: 0)) == [0] && graph.outDegree(of: 0) == 1)
        #expect(Array(graph.predecessors(of: 0)) == [] as [Int] && Array(graph.inEdges(of: 0)) == [] as [Int] && graph.inDegree(of: 0) == 0)
        #expect(try Array(graph.successors(checked: 0)) == [1] && Array(graph.outEdges(checked: 0)) == [0] && graph.outDegree(checked: 0) == 1)
        #expect(try Array(graph.predecessors(checked: 0)) == [] as [Int] && Array(graph.inEdges(checked: 0)) == [] as [Int] && graph.inDegree(checked: 0) == 0)
        #expect(try graph.topologicalPosition(of: 1) == 1 && graph.topologicalPosition(checked: 1) == 1 && graph.topologicalOrder.firstIndex(of: 1) == 1)
        #expect(Array(graph.successors(of: 1)) == [] as [Int] && Array(graph.outEdges(of: 1)) == [] as [Int] && graph.outDegree(of: 1) == 0)
        #expect(Array(graph.predecessors(of: 1)) == [0] && Array(graph.inEdges(of: 1)) == [0] && graph.inDegree(of: 1) == 1)
        #expect(try Array(graph.successors(checked: 1)) == [] as [Int] && Array(graph.outEdges(checked: 1)) == [] as [Int] && graph.outDegree(checked: 1) == 0)
        #expect(try Array(graph.predecessors(checked: 1)) == [0] && Array(graph.inEdges(checked: 1)) == [0] && graph.inDegree(checked: 1) == 1)
        #expect(!graph.contains(101) && (try? graph.topologicalPosition(checked: 101)) == nil && graph.topologicalOrder.firstIndex(of: 101) == nil)
        #expect((try? graph.successors(checked: 101)) == nil && (try? graph.predecessors(checked: 101)) == nil && (try? graph.outEdges(checked: 101)) == nil)
        #expect((try? graph.inEdges(checked: 101)) == nil && (try? graph.outDegree(checked: 101)) == nil && (try? graph.inDegree(checked: 101)) == nil)
    }
}
