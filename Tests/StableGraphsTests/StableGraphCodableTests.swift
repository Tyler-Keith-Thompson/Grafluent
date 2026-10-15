// Codable (catalog SG-082 – SG-094, SG-108 – SG-116): `{vertices, vertexPositions, vertexEnd, edges, edgePositions,
// edgeEnd}`. Encoding is checked byte for byte (with sorted keys); decoding keeps every position
// and both ends, so the next insertions get the positions they would have got before encoding.
// Far ends decode in O(elements); corrupt payloads, a page span past 16 × count + 64 included, throw
// `DecodingError.dataCorrupted` with the catalog's key and message.
// Generated from cases.md by swiftgen.py; see README.md.

import Foundation
import GrafluentTestSupport
import GraphProtocols
import StableGraphs
import Testing

@Suite("StableGraphs Codable")
struct StableGraphCodableTests {
    @Test("SG-082 encode keeps positions and ends", .tags(.conformance))
    func sg082() throws {
        // V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→0] / remove(1) / insert(3)
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 0)])
        _ = graph.remove(1)
        _ = graph.insert(3)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edgeEnd\":4,\"edgePositions\":[2,3],\"edges\":[1,0,0,0],\"vertexEnd\":4,\"vertexPositions\":[0,2,3],\"vertices\":[0,2,3]}")
        // The payload as the catalog writes it decodes the same way.
        for payload in [data, Data("{\"vertices\":[0,2,3],\"vertexPositions\":[0,2,3],\"vertexEnd\":4,\"edges\":[1,0,0,0],\"edgePositions\":[2,3],\"edgeEnd\":4}".utf8)] {
            var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [0, 2, 3])
            #expect(Array(decoded.vertices.indices) == [0, 2, 3])
            #expect(decoded.vertices.startIndex == 0)
            #expect(decoded.vertices.endIndex == 4)
            #expect(decoded.edges.map { [$0.source, $0.target] } == [[2, 0], [0, 0]])
            #expect(Array(decoded.edges.indices) == [2, 3])
            #expect(decoded.edges.startIndex == 2)
            #expect(decoded.edges.endIndex == 4)
            #expect(decoded.vertexIndexBound == nil)
            #expect(decoded.edgeIndexBound == nil)
            #expect(decoded.vertexCount == 3)
            #expect(decoded.vertices.count == 3)
            #expect(decoded.edgeCount == 2)
            #expect(decoded.edges.count == 2)
            #expect(decoded.edges.indices.map { [decoded.source(ofEdgeAt: $0), decoded.target(ofEdgeAt: $0)] } == [[2, 0], [0, 0]])
            #expect(decoded.edges.indices.map { decoded.edges[$0] } == [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 0)])
            #expect(decoded.vertices.firstIndex(of: 0) == 0)
            #expect(decoded.vertices[0] == 0)
            #expect(Array(decoded.successors(of: 0)) == [0])
            #expect(Array(decoded.outEdges(of: 0)) == [3])
            #expect(Array(decoded.predecessors(of: 0)) == [2, 0])
            #expect(Array(decoded.inEdges(of: 0)) == [2, 3])
            #expect(decoded.outDegree(of: 0) == 1 && decoded.inDegree(of: 0) == 2 && decoded.degree(of: 0) == 3)
            #expect(decoded.vertices.firstIndex(of: 2) == 2)
            #expect(decoded.vertices[2] == 2)
            #expect(Array(decoded.successors(of: 2)) == [0])
            #expect(Array(decoded.outEdges(of: 2)) == [2])
            #expect(Array(decoded.predecessors(of: 2)) == [] as [Int])
            #expect(Array(decoded.inEdges(of: 2)) == [] as [Int])
            #expect(decoded.outDegree(of: 2) == 1 && decoded.inDegree(of: 2) == 0 && decoded.degree(of: 2) == 1)
            #expect(decoded.vertices.firstIndex(of: 3) == 3)
            #expect(decoded.vertices[3] == 3)
            #expect(Array(decoded.successors(of: 3)) == [] as [Int])
            #expect(Array(decoded.outEdges(of: 3)) == [] as [Int])
            #expect(Array(decoded.predecessors(of: 3)) == [] as [Int])
            #expect(Array(decoded.inEdges(of: 3)) == [] as [Int])
            #expect(decoded.outDegree(of: 3) == 0 && decoded.inDegree(of: 3) == 0 && decoded.degree(of: 3) == 0)
            #expect(Array(decoded.edges(from: 2, to: 0)) == [2])
            #expect(decoded.edgeCount(from: 2, to: 0) == 1)
            #expect(decoded.contains(edge: DirectedEdge(from: 2, to: 0)))
            #expect(Array(decoded.edges(from: 0, to: 0)) == [3])
            #expect(decoded.edgeCount(from: 0, to: 0) == 1)
            #expect(decoded.contains(edge: DirectedEdge(from: 0, to: 0)))
            // The next insertions get the fresh positions they would have got before encoding.
            #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 4)
            #expect(decoded.vertices.firstIndex(of: -1) == 4)
        }
    }

    @Test("SG-083 round trip keeps the next fresh positions", .tags(.conformance))
    func sg083() throws {
        // decode(encode(g)) for the graph above / insert(4) / insert(edge: 4→0)
        var graph = StableDirectedGraph<Int>(vertices: [0, 1, 2], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 0)])
        _ = graph.remove(1)
        _ = graph.insert(3)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edgeEnd\":4,\"edgePositions\":[2,3],\"edges\":[1,0,0,0],\"vertexEnd\":4,\"vertexPositions\":[0,2,3],\"vertices\":[0,2,3]}")
        // The payload as the catalog writes it decodes the same way.
        for payload in [data, Data("{\"vertices\":[0,2,3],\"vertexPositions\":[0,2,3],\"vertexEnd\":4,\"edges\":[1,0,0,0],\"edgePositions\":[2,3],\"edgeEnd\":4}".utf8)] {
            var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [0, 2, 3])
            #expect(Array(decoded.vertices.indices) == [0, 2, 3])
            #expect(decoded.vertices.startIndex == 0)
            #expect(decoded.vertices.endIndex == 4)
            #expect(decoded.edges.map { [$0.source, $0.target] } == [[2, 0], [0, 0]])
            #expect(Array(decoded.edges.indices) == [2, 3])
            #expect(decoded.edges.startIndex == 2)
            #expect(decoded.edges.endIndex == 4)
            #expect(decoded.vertexIndexBound == nil)
            #expect(decoded.edgeIndexBound == nil)
            #expect(decoded.vertexCount == 3)
            #expect(decoded.vertices.count == 3)
            #expect(decoded.edgeCount == 2)
            #expect(decoded.edges.count == 2)
            #expect(decoded.edges.indices.map { [decoded.source(ofEdgeAt: $0), decoded.target(ofEdgeAt: $0)] } == [[2, 0], [0, 0]])
            #expect(decoded.edges.indices.map { decoded.edges[$0] } == [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 0)])
            #expect(decoded.vertices.firstIndex(of: 0) == 0)
            #expect(decoded.vertices[0] == 0)
            #expect(Array(decoded.successors(of: 0)) == [0])
            #expect(Array(decoded.outEdges(of: 0)) == [3])
            #expect(Array(decoded.predecessors(of: 0)) == [2, 0])
            #expect(Array(decoded.inEdges(of: 0)) == [2, 3])
            #expect(decoded.outDegree(of: 0) == 1 && decoded.inDegree(of: 0) == 2 && decoded.degree(of: 0) == 3)
            #expect(decoded.vertices.firstIndex(of: 2) == 2)
            #expect(decoded.vertices[2] == 2)
            #expect(Array(decoded.successors(of: 2)) == [0])
            #expect(Array(decoded.outEdges(of: 2)) == [2])
            #expect(Array(decoded.predecessors(of: 2)) == [] as [Int])
            #expect(Array(decoded.inEdges(of: 2)) == [] as [Int])
            #expect(decoded.outDegree(of: 2) == 1 && decoded.inDegree(of: 2) == 0 && decoded.degree(of: 2) == 1)
            #expect(decoded.vertices.firstIndex(of: 3) == 3)
            #expect(decoded.vertices[3] == 3)
            #expect(Array(decoded.successors(of: 3)) == [] as [Int])
            #expect(Array(decoded.outEdges(of: 3)) == [] as [Int])
            #expect(Array(decoded.predecessors(of: 3)) == [] as [Int])
            #expect(Array(decoded.inEdges(of: 3)) == [] as [Int])
            #expect(decoded.outDegree(of: 3) == 0 && decoded.inDegree(of: 3) == 0 && decoded.degree(of: 3) == 0)
            #expect(Array(decoded.edges(from: 2, to: 0)) == [2])
            #expect(decoded.edgeCount(from: 2, to: 0) == 1)
            #expect(decoded.contains(edge: DirectedEdge(from: 2, to: 0)))
            #expect(Array(decoded.edges(from: 0, to: 0)) == [3])
            #expect(decoded.edgeCount(from: 0, to: 0) == 1)
            #expect(decoded.contains(edge: DirectedEdge(from: 0, to: 0)))
            // The next insertions get the fresh positions they would have got before encoding.
            do {
                let result = decoded.insert(4)
                #expect(result.inserted)
                #expect(result.memberAfterInsert == 4)
            }
            #expect(decoded.insert(edge: DirectedEdge(from: 4, to: 0)) == 4)
            #expect(Array(decoded.vertices) == [0, 2, 3, 4])
            #expect(Array(decoded.vertices.indices) == [0, 2, 3, 4])
            #expect(decoded.vertices.startIndex == 0)
            #expect(decoded.vertices.endIndex == 5)
            #expect(decoded.edges.map { [$0.source, $0.target] } == [[2, 0], [0, 0], [4, 0]])
            #expect(Array(decoded.edges.indices) == [2, 3, 4])
            #expect(decoded.edges.startIndex == 2)
            #expect(decoded.edges.endIndex == 5)
            #expect(decoded.vertexIndexBound == nil)
            #expect(decoded.edgeIndexBound == nil)
            #expect(decoded.vertexCount == 4)
            #expect(decoded.vertices.count == 4)
            #expect(decoded.edgeCount == 3)
            #expect(decoded.edges.count == 3)
            #expect(decoded.edges.indices.map { [decoded.source(ofEdgeAt: $0), decoded.target(ofEdgeAt: $0)] } == [[2, 0], [0, 0], [4, 0]])
            #expect(decoded.edges.indices.map { decoded.edges[$0] } == [DirectedEdge(from: 2, to: 0), DirectedEdge(from: 0, to: 0), DirectedEdge(from: 4, to: 0)])
            #expect(decoded.vertices.firstIndex(of: 0) == 0)
            #expect(decoded.vertices[0] == 0)
            #expect(Array(decoded.successors(of: 0)) == [0])
            #expect(Array(decoded.outEdges(of: 0)) == [3])
            #expect(Array(decoded.predecessors(of: 0)) == [2, 0, 4])
            #expect(Array(decoded.inEdges(of: 0)) == [2, 3, 4])
            #expect(decoded.outDegree(of: 0) == 1 && decoded.inDegree(of: 0) == 3 && decoded.degree(of: 0) == 4)
            #expect(decoded.vertices.firstIndex(of: 2) == 2)
            #expect(decoded.vertices[2] == 2)
            #expect(Array(decoded.successors(of: 2)) == [0])
            #expect(Array(decoded.outEdges(of: 2)) == [2])
            #expect(Array(decoded.predecessors(of: 2)) == [] as [Int])
            #expect(Array(decoded.inEdges(of: 2)) == [] as [Int])
            #expect(decoded.outDegree(of: 2) == 1 && decoded.inDegree(of: 2) == 0 && decoded.degree(of: 2) == 1)
            #expect(decoded.vertices.firstIndex(of: 3) == 3)
            #expect(decoded.vertices[3] == 3)
            #expect(Array(decoded.successors(of: 3)) == [] as [Int])
            #expect(Array(decoded.outEdges(of: 3)) == [] as [Int])
            #expect(Array(decoded.predecessors(of: 3)) == [] as [Int])
            #expect(Array(decoded.inEdges(of: 3)) == [] as [Int])
            #expect(decoded.outDegree(of: 3) == 0 && decoded.inDegree(of: 3) == 0 && decoded.degree(of: 3) == 0)
            #expect(decoded.vertices.firstIndex(of: 4) == 4)
            #expect(decoded.vertices[4] == 4)
            #expect(Array(decoded.successors(of: 4)) == [0])
            #expect(Array(decoded.outEdges(of: 4)) == [4])
            #expect(Array(decoded.predecessors(of: 4)) == [] as [Int])
            #expect(Array(decoded.inEdges(of: 4)) == [] as [Int])
            #expect(decoded.outDegree(of: 4) == 1 && decoded.inDegree(of: 4) == 0 && decoded.degree(of: 4) == 1)
            #expect(Array(decoded.edges(from: 2, to: 0)) == [2])
            #expect(decoded.edgeCount(from: 2, to: 0) == 1)
            #expect(decoded.contains(edge: DirectedEdge(from: 2, to: 0)))
            #expect(Array(decoded.edges(from: 0, to: 0)) == [3])
            #expect(decoded.edgeCount(from: 0, to: 0) == 1)
            #expect(decoded.contains(edge: DirectedEdge(from: 0, to: 0)))
            #expect(Array(decoded.edges(from: 4, to: 0)) == [4])
            #expect(decoded.edgeCount(from: 4, to: 0) == 1)
            #expect(decoded.contains(edge: DirectedEdge(from: 4, to: 0)))
        }
    }

    @Test("SG-084 empty", .tags(.conformance))
    func sg084() throws {
        // V []; E []
        let graph = StableDirectedGraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edgeEnd\":0,\"edgePositions\":[],\"edges\":[],\"vertexEnd\":0,\"vertexPositions\":[],\"vertices\":[]}")
        // The payload as the catalog writes it decodes the same way.
        for payload in [data, Data("{\"vertices\":[],\"vertexPositions\":[],\"vertexEnd\":0,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":0}".utf8)] {
            var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [] as [Int])
            #expect(Array(decoded.vertices.indices) == [] as [Int])
            #expect(decoded.vertices.startIndex == 0)
            #expect(decoded.vertices.endIndex == 0)
            #expect(decoded.edges.map { [$0.source, $0.target] } == [] as [[Int]])
            #expect(Array(decoded.edges.indices) == [] as [Int])
            #expect(decoded.edges.startIndex == 0)
            #expect(decoded.edges.endIndex == 0)
            #expect(decoded.vertexIndexBound == 0)
            #expect(decoded.edgeIndexBound == 0)
            #expect(decoded.vertexCount == 0)
            #expect(decoded.vertices.count == 0)
            #expect(decoded.edgeCount == 0)
            #expect(decoded.edges.count == 0)
            #expect(decoded.vertices.map { decoded.vertexIndex(of: $0) } == [] as [Int])
            #expect((0 ..< 0).map { decoded.vertex(atIndex: $0) } == [] as [Int])
            #expect(decoded.edges.indices.map { decoded.edgeIndex(of: $0) } == [] as [Int])
            // The next insertions get the fresh positions they would have got before encoding.
            #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 0)
            #expect(decoded.vertices.firstIndex(of: -1) == 0)
        }
    }

    @Test("SG-085 all holes round trip", .tags(.conformance))
    func sg085() throws {
        // V [0]; E [0→0, 0→0] / remove(edgeAt: 0) / remove(edgeAt: 1) / remove(0)
        var graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0)])
        _ = graph.remove(edgeAt: 0)
        _ = graph.remove(edgeAt: 1)
        _ = graph.remove(0)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edgeEnd\":2,\"edgePositions\":[],\"edges\":[],\"vertexEnd\":1,\"vertexPositions\":[],\"vertices\":[]}")
        // The payload as the catalog writes it decodes the same way.
        for payload in [data, Data("{\"vertices\":[],\"vertexPositions\":[],\"vertexEnd\":1,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":2}".utf8)] {
            var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [] as [Int])
            #expect(Array(decoded.vertices.indices) == [] as [Int])
            #expect(decoded.vertices.startIndex == 1)
            #expect(decoded.vertices.endIndex == 1)
            #expect(decoded.edges.map { [$0.source, $0.target] } == [] as [[Int]])
            #expect(Array(decoded.edges.indices) == [] as [Int])
            #expect(decoded.edges.startIndex == 2)
            #expect(decoded.edges.endIndex == 2)
            #expect(decoded.vertexIndexBound == nil)
            #expect(decoded.edgeIndexBound == nil)
            #expect(decoded.vertexCount == 0)
            #expect(decoded.vertices.count == 0)
            #expect(decoded.edgeCount == 0)
            #expect(decoded.edges.count == 0)
            // The next insertions get the fresh positions they would have got before encoding.
            #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 2)
            #expect(decoded.vertices.firstIndex(of: -1) == 1)
        }
    }

    @Test("SG-086 odd edge list", .tags(.conformance))
    func sg086() {
        // {"vertices":[0,1],"vertexPositions":[0,1],"vertexEnd":2,"edges":[0],"edgePositions":[0],"edgeEnd":1} → dataCorrupted(edges): Edge list has odd length
        let payload = Data("{\"vertices\":[0,1],\"vertexPositions\":[0,1],\"vertexEnd\":2,\"edges\":[0],\"edgePositions\":[0],\"edgeEnd\":1}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Edge list has odd length")
            #expect(context.codingPath.last?.stringValue == "edges")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-087 repeated vertex", .tags(.conformance))
    func sg087() {
        // {"vertices":[0,0],"vertexPositions":[0,1],"vertexEnd":2,"edges":[],"edgePositions":[],"edgeEnd":0} → dataCorrupted(vertices): Repeated vertex
        let payload = Data("{\"vertices\":[0,0],\"vertexPositions\":[0,1],\"vertexEnd\":2,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":0}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Repeated vertex")
            #expect(context.codingPath.last?.stringValue == "vertices")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-088 vertex positions count", .tags(.conformance))
    func sg088() {
        // {"vertices":[0,1],"vertexPositions":[0],"vertexEnd":2,"edges":[],"edgePositions":[],"edgeEnd":0} → dataCorrupted(vertexPositions): Count differs from vertices
        let payload = Data("{\"vertices\":[0,1],\"vertexPositions\":[0],\"vertexEnd\":2,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":0}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Count differs from vertices")
            #expect(context.codingPath.last?.stringValue == "vertexPositions")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-089 vertex positions not increasing", .tags(.conformance))
    func sg089() {
        // {"vertices":[0,1],"vertexPositions":[1,0],"vertexEnd":2,"edges":[],"edgePositions":[],"edgeEnd":0} → dataCorrupted(vertexPositions): Positions not increasing within vertexEnd
        let payload = Data("{\"vertices\":[0,1],\"vertexPositions\":[1,0],\"vertexEnd\":2,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":0}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Positions not increasing within vertexEnd")
            #expect(context.codingPath.last?.stringValue == "vertexPositions")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-090 vertex position past end", .tags(.conformance))
    func sg090() {
        // {"vertices":[0],"vertexPositions":[3],"vertexEnd":3,"edges":[],"edgePositions":[],"edgeEnd":0} → dataCorrupted(vertexPositions): Positions not increasing within vertexEnd
        let payload = Data("{\"vertices\":[0],\"vertexPositions\":[3],\"vertexEnd\":3,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":0}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Positions not increasing within vertexEnd")
            #expect(context.codingPath.last?.stringValue == "vertexPositions")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-091 edge endpoint out of range", .tags(.conformance))
    func sg091() {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,1],"edgePositions":[0],"edgeEnd":1} → dataCorrupted(edges): Edge endpoint out of range
        let payload = Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":1,\"edges\":[0,1],\"edgePositions\":[0],\"edgeEnd\":1}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Edge endpoint out of range")
            #expect(context.codingPath.last?.stringValue == "edges")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-092 edge positions count", .tags(.conformance))
    func sg092() {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0],"edgePositions":[],"edgeEnd":1} → dataCorrupted(edgePositions): Count differs from edges
        let payload = Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":1,\"edges\":[0,0],\"edgePositions\":[],\"edgeEnd\":1}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Count differs from edges")
            #expect(context.codingPath.last?.stringValue == "edgePositions")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-093 edge positions repeated", .tags(.conformance))
    func sg093() {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0,0,0],"edgePositions":[1,1],"edgeEnd":2} → dataCorrupted(edgePositions): Positions not increasing within edgeEnd
        let payload = Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":1,\"edges\":[0,0,0,0],\"edgePositions\":[1,1],\"edgeEnd\":2}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Positions not increasing within edgeEnd")
            #expect(context.codingPath.last?.stringValue == "edgePositions")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-094 edge position past end", .tags(.conformance))
    func sg094() {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0],"edgePositions":[2],"edgeEnd":2} → dataCorrupted(edgePositions): Positions not increasing within edgeEnd
        let payload = Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":1,\"edges\":[0,0],\"edgePositions\":[2],\"edgeEnd\":2}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Positions not increasing within edgeEnd")
            #expect(context.codingPath.last?.stringValue == "edgePositions")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    #if _pointerBitWidth(_64)
    @Test("SG-108 vertexEnd far past the payload: no vertex, so one page", .tags(.conformance))
    func sg108() throws {
        // {"vertices":[],"vertexPositions":[],"vertexEnd":4611686018427387903,"edges":[],"edgePositions":[],"edgeEnd":0} → V [] end 4611686018427387903; E [] end 0; bounds nil/0; out -; in -
        var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data("{\"vertices\":[],\"vertexPositions\":[],\"vertexEnd\":4611686018427387903,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":0}".utf8))
        #expect(Array(decoded.vertices) == [] as [Int])
        #expect(Array(decoded.vertices.indices) == [] as [Int])
        #expect(decoded.vertices.startIndex == 4611686018427387903)
        #expect(decoded.vertices.endIndex == 4611686018427387903)
        #expect(decoded.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(decoded.edges.indices) == [] as [Int])
        #expect(decoded.edges.startIndex == 0)
        #expect(decoded.edges.endIndex == 0)
        #expect(decoded.vertexIndexBound == nil)
        #expect(decoded.edgeIndexBound == 0)
        #expect(decoded.vertexCount == 0)
        #expect(decoded.vertices.count == 0)
        #expect(decoded.edgeCount == 0)
        #expect(decoded.edges.count == 0)
        #expect(decoded.edges.indices.map { decoded.edgeIndex(of: $0) } == [] as [Int])
        #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 0)
        #expect(decoded.vertices.firstIndex(of: -1) == 4611686018427387903)
    }
    #endif

    #if _pointerBitWidth(_64)
    @Test("SG-109 edgeEnd at Int.max with no edge: one page", .tags(.conformance))
    func sg109() throws {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[],"edgePositions":[],"edgeEnd":9223372036854775807} → V [0#0] end 1; E [] end 9223372036854775807; bounds 1/nil; out -; in -
        var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":1,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":9223372036854775807}".utf8))
        #expect(Array(decoded.vertices) == [0])
        #expect(Array(decoded.vertices.indices) == [0])
        #expect(decoded.vertices.startIndex == 0)
        #expect(decoded.vertices.endIndex == 1)
        #expect(decoded.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(decoded.edges.indices) == [] as [Int])
        #expect(decoded.edges.startIndex == 9223372036854775807)
        #expect(decoded.edges.endIndex == 9223372036854775807)
        #expect(decoded.vertexIndexBound == 1)
        #expect(decoded.edgeIndexBound == nil)
        #expect(decoded.vertexCount == 1)
        #expect(decoded.vertices.count == 1)
        #expect(decoded.edgeCount == 0)
        #expect(decoded.edges.count == 0)
        #expect(decoded.vertices.firstIndex(of: 0) == 0)
        #expect(decoded.vertices[0] == 0)
        #expect(Array(decoded.successors(of: 0)) == [] as [Int])
        #expect(Array(decoded.outEdges(of: 0)) == [] as [Int])
        #expect(Array(decoded.predecessors(of: 0)) == [] as [Int])
        #expect(Array(decoded.inEdges(of: 0)) == [] as [Int])
        #expect(decoded.outDegree(of: 0) == 0 && decoded.inDegree(of: 0) == 0 && decoded.degree(of: 0) == 0)
        #expect(decoded.vertices.map { decoded.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { decoded.vertex(atIndex: $0) } == [0])
        // edgeEnd is Int.max: no edge position is left (extra_traps.swift traps on the next insert).
        #expect(decoded.insert(-1).inserted)
        #expect(decoded.vertices.firstIndex(of: -1) == 1)
    }
    #endif

    @Test("SG-110 vertexEnd 65554 with one vertex: 65 pages, within the bound", .tags(.conformance))
    func sg110() throws {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":65554,"edges":[],"edgePositions":[],"edgeEnd":0} → V [0#0] end 65554; E [] end 0; bounds nil/0; out -; in -
        var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":65554,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":0}".utf8))
        #expect(Array(decoded.vertices) == [0])
        #expect(Array(decoded.vertices.indices) == [0])
        #expect(decoded.vertices.startIndex == 0)
        #expect(decoded.vertices.endIndex == 65554)
        #expect(decoded.edges.map { [$0.source, $0.target] } == [] as [[Int]])
        #expect(Array(decoded.edges.indices) == [] as [Int])
        #expect(decoded.edges.startIndex == 0)
        #expect(decoded.edges.endIndex == 0)
        #expect(decoded.vertexIndexBound == nil)
        #expect(decoded.edgeIndexBound == 0)
        #expect(decoded.vertexCount == 1)
        #expect(decoded.vertices.count == 1)
        #expect(decoded.edgeCount == 0)
        #expect(decoded.edges.count == 0)
        #expect(decoded.vertices.firstIndex(of: 0) == 0)
        #expect(decoded.vertices[0] == 0)
        #expect(Array(decoded.successors(of: 0)) == [] as [Int])
        #expect(Array(decoded.outEdges(of: 0)) == [] as [Int])
        #expect(Array(decoded.predecessors(of: 0)) == [] as [Int])
        #expect(Array(decoded.inEdges(of: 0)) == [] as [Int])
        #expect(decoded.outDegree(of: 0) == 0 && decoded.inDegree(of: 0) == 0 && decoded.degree(of: 0) == 0)
        #expect(decoded.edges.indices.map { decoded.edgeIndex(of: $0) } == [] as [Int])
        #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 0)
        #expect(decoded.vertices.firstIndex(of: -1) == 65554)
    }

    @Test("SG-111 edgeEnd 65554 with one edge: 65 pages, within the bound", .tags(.conformance))
    func sg111() throws {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0],"edgePositions":[0],"edgeEnd":65554} → V [0#0] end 1; E [0:0→0] end 65554; bounds 1/nil; out 0:[0@0]; in 0:[0@0]
        var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":1,\"edges\":[0,0],\"edgePositions\":[0],\"edgeEnd\":65554}".utf8))
        #expect(Array(decoded.vertices) == [0])
        #expect(Array(decoded.vertices.indices) == [0])
        #expect(decoded.vertices.startIndex == 0)
        #expect(decoded.vertices.endIndex == 1)
        #expect(decoded.edges.map { [$0.source, $0.target] } == [[0, 0]])
        #expect(Array(decoded.edges.indices) == [0])
        #expect(decoded.edges.startIndex == 0)
        #expect(decoded.edges.endIndex == 65554)
        #expect(decoded.vertexIndexBound == 1)
        #expect(decoded.edgeIndexBound == nil)
        #expect(decoded.vertexCount == 1)
        #expect(decoded.vertices.count == 1)
        #expect(decoded.edgeCount == 1)
        #expect(decoded.edges.count == 1)
        #expect(decoded.edges.indices.map { [decoded.source(ofEdgeAt: $0), decoded.target(ofEdgeAt: $0)] } == [[0, 0]])
        #expect(decoded.edges.indices.map { decoded.edges[$0] } == [DirectedEdge(from: 0, to: 0)])
        #expect(decoded.vertices.firstIndex(of: 0) == 0)
        #expect(decoded.vertices[0] == 0)
        #expect(Array(decoded.successors(of: 0)) == [0])
        #expect(Array(decoded.outEdges(of: 0)) == [0])
        #expect(Array(decoded.predecessors(of: 0)) == [0])
        #expect(Array(decoded.inEdges(of: 0)) == [0])
        #expect(decoded.outDegree(of: 0) == 1 && decoded.inDegree(of: 0) == 1 && decoded.degree(of: 0) == 2)
        #expect(Array(decoded.edges(from: 0, to: 0)) == [0])
        #expect(decoded.edgeCount(from: 0, to: 0) == 1)
        #expect(decoded.contains(edge: DirectedEdge(from: 0, to: 0)))
        #expect(decoded.vertices.map { decoded.vertexIndex(of: $0) } == [0])
        #expect((0 ..< 1).map { decoded.vertex(atIndex: $0) } == [0])
        #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 65554)
        #expect(decoded.vertices.firstIndex(of: -1) == 1)
    }

    @Test("SG-112 ends at 65553 decode", .tags(.conformance))
    func sg112() throws {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":65553,"edges":[0,0],"edgePositions":[0],"edgeEnd":65553} → V [0#0] end 65553; E [0:0→0] end 65553; bounds nil/nil; out 0:[0@0]; in 0:[0@0]
        var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":65553,\"edges\":[0,0],\"edgePositions\":[0],\"edgeEnd\":65553}".utf8))
        #expect(Array(decoded.vertices) == [0])
        #expect(Array(decoded.vertices.indices) == [0])
        #expect(decoded.vertices.startIndex == 0)
        #expect(decoded.vertices.endIndex == 65553)
        #expect(decoded.edges.map { [$0.source, $0.target] } == [[0, 0]])
        #expect(Array(decoded.edges.indices) == [0])
        #expect(decoded.edges.startIndex == 0)
        #expect(decoded.edges.endIndex == 65553)
        #expect(decoded.vertexIndexBound == nil)
        #expect(decoded.edgeIndexBound == nil)
        #expect(decoded.vertexCount == 1)
        #expect(decoded.vertices.count == 1)
        #expect(decoded.edgeCount == 1)
        #expect(decoded.edges.count == 1)
        #expect(decoded.edges.indices.map { [decoded.source(ofEdgeAt: $0), decoded.target(ofEdgeAt: $0)] } == [[0, 0]])
        #expect(decoded.edges.indices.map { decoded.edges[$0] } == [DirectedEdge(from: 0, to: 0)])
        #expect(decoded.vertices.firstIndex(of: 0) == 0)
        #expect(decoded.vertices[0] == 0)
        #expect(Array(decoded.successors(of: 0)) == [0])
        #expect(Array(decoded.outEdges(of: 0)) == [0])
        #expect(Array(decoded.predecessors(of: 0)) == [0])
        #expect(Array(decoded.inEdges(of: 0)) == [0])
        #expect(decoded.outDegree(of: 0) == 1 && decoded.inDegree(of: 0) == 1 && decoded.degree(of: 0) == 2)
        #expect(Array(decoded.edges(from: 0, to: 0)) == [0])
        #expect(decoded.edgeCount(from: 0, to: 0) == 1)
        #expect(decoded.contains(edge: DirectedEdge(from: 0, to: 0)))
        #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 65553)
        #expect(decoded.vertices.firstIndex(of: -1) == 65553)
    }

    @Test("SG-113 vertex page span one past 16 × count + 64", .tags(.conformance))
    func sg113() {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":81920,"edges":[],"edgePositions":[],"edgeEnd":0} → dataCorrupted(vertexEnd): End leaves too many empty pages
        let payload = Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":81920,\"edges\":[],\"edgePositions\":[],\"edgeEnd\":0}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "End leaves too many empty pages")
            #expect(context.codingPath.last?.stringValue == "vertexEnd")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-114 edge page span one past 16 × count + 64", .tags(.conformance))
    func sg114() {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":1,"edges":[0,0],"edgePositions":[0],"edgeEnd":81920} → dataCorrupted(edgeEnd): End leaves too many empty pages
        let payload = Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":1,\"edges\":[0,0],\"edgePositions\":[0],\"edgeEnd\":81920}".utf8)
        do {
            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "End leaves too many empty pages")
            #expect(context.codingPath.last?.stringValue == "edgeEnd")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("SG-115 page spans at the bound decode", .tags(.conformance))
    func sg115() throws {
        // {"vertices":[0],"vertexPositions":[0],"vertexEnd":81919,"edges":[0,0],"edgePositions":[0],"edgeEnd":81919} → V [0#0] end 81919; E [0:0→0] end 81919; bounds nil/nil; out 0:[0@0]; in 0:[0@0]
        var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data("{\"vertices\":[0],\"vertexPositions\":[0],\"vertexEnd\":81919,\"edges\":[0,0],\"edgePositions\":[0],\"edgeEnd\":81919}".utf8))
        #expect(Array(decoded.vertices) == [0])
        #expect(Array(decoded.vertices.indices) == [0])
        #expect(decoded.vertices.startIndex == 0)
        #expect(decoded.vertices.endIndex == 81919)
        #expect(decoded.edges.map { [$0.source, $0.target] } == [[0, 0]])
        #expect(Array(decoded.edges.indices) == [0])
        #expect(decoded.edges.startIndex == 0)
        #expect(decoded.edges.endIndex == 81919)
        #expect(decoded.vertexIndexBound == nil)
        #expect(decoded.edgeIndexBound == nil)
        #expect(decoded.vertexCount == 1)
        #expect(decoded.vertices.count == 1)
        #expect(decoded.edgeCount == 1)
        #expect(decoded.edges.count == 1)
        #expect(decoded.edges.indices.map { [decoded.source(ofEdgeAt: $0), decoded.target(ofEdgeAt: $0)] } == [[0, 0]])
        #expect(decoded.edges.indices.map { decoded.edges[$0] } == [DirectedEdge(from: 0, to: 0)])
        #expect(decoded.vertices.firstIndex(of: 0) == 0)
        #expect(decoded.vertices[0] == 0)
        #expect(Array(decoded.successors(of: 0)) == [0])
        #expect(Array(decoded.outEdges(of: 0)) == [0])
        #expect(Array(decoded.predecessors(of: 0)) == [0])
        #expect(Array(decoded.inEdges(of: 0)) == [0])
        #expect(decoded.outDegree(of: 0) == 1 && decoded.inDegree(of: 0) == 1 && decoded.degree(of: 0) == 2)
        #expect(Array(decoded.edges(from: 0, to: 0)) == [0])
        #expect(decoded.edgeCount(from: 0, to: 0) == 1)
        #expect(decoded.contains(edge: DirectedEdge(from: 0, to: 0)))
        #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 81919)
        #expect(decoded.vertices.firstIndex(of: -1) == 81919)
    }

    #if _pointerBitWidth(_64)
    @Test("SG-116 elements far along: the pages before them cost nothing", .tags(.conformance))
    func sg116() throws {
        // {"vertices":[7,8],"vertexPositions":[4611686018427387000,4611686018427387001],"vertexEnd":4611686018427387904,"edges":[0,1],"edgePositions":[9223372036854775000],"edgeEnd":9223372036854775001} → V [7#4611686018427387000, 8#4611686018427387001] end 4611686018427387904; E [9223372036854775000:7→8] end 9223372036854775001; bounds nil/nil; out 7:[8@9223372036854775000]; in 8:[7@9223372036854775000]
        var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data("{\"vertices\":[7,8],\"vertexPositions\":[4611686018427387000,4611686018427387001],\"vertexEnd\":4611686018427387904,\"edges\":[0,1],\"edgePositions\":[9223372036854775000],\"edgeEnd\":9223372036854775001}".utf8))
        #expect(Array(decoded.vertices) == [7, 8])
        #expect(Array(decoded.vertices.indices) == [4611686018427387000, 4611686018427387001])
        #expect(decoded.vertices.startIndex == 4611686018427387000)
        #expect(decoded.vertices.endIndex == 4611686018427387904)
        #expect(decoded.edges.map { [$0.source, $0.target] } == [[7, 8]])
        #expect(Array(decoded.edges.indices) == [9223372036854775000])
        #expect(decoded.edges.startIndex == 9223372036854775000)
        #expect(decoded.edges.endIndex == 9223372036854775001)
        #expect(decoded.vertexIndexBound == nil)
        #expect(decoded.edgeIndexBound == nil)
        #expect(decoded.vertexCount == 2)
        #expect(decoded.vertices.count == 2)
        #expect(decoded.edgeCount == 1)
        #expect(decoded.edges.count == 1)
        #expect(decoded.edges.indices.map { [decoded.source(ofEdgeAt: $0), decoded.target(ofEdgeAt: $0)] } == [[7, 8]])
        #expect(decoded.edges.indices.map { decoded.edges[$0] } == [DirectedEdge(from: 7, to: 8)])
        #expect(decoded.vertices.firstIndex(of: 7) == 4611686018427387000)
        #expect(decoded.vertices[4611686018427387000] == 7)
        #expect(Array(decoded.successors(of: 7)) == [8])
        #expect(Array(decoded.outEdges(of: 7)) == [9223372036854775000])
        #expect(Array(decoded.predecessors(of: 7)) == [] as [Int])
        #expect(Array(decoded.inEdges(of: 7)) == [] as [Int])
        #expect(decoded.outDegree(of: 7) == 1 && decoded.inDegree(of: 7) == 0 && decoded.degree(of: 7) == 1)
        #expect(decoded.vertices.firstIndex(of: 8) == 4611686018427387001)
        #expect(decoded.vertices[4611686018427387001] == 8)
        #expect(Array(decoded.successors(of: 8)) == [] as [Int])
        #expect(Array(decoded.outEdges(of: 8)) == [] as [Int])
        #expect(Array(decoded.predecessors(of: 8)) == [7])
        #expect(Array(decoded.inEdges(of: 8)) == [9223372036854775000])
        #expect(decoded.outDegree(of: 8) == 0 && decoded.inDegree(of: 8) == 1 && decoded.degree(of: 8) == 1)
        #expect(Array(decoded.edges(from: 7, to: 8)) == [9223372036854775000])
        #expect(decoded.edgeCount(from: 7, to: 8) == 1)
        #expect(decoded.contains(edge: DirectedEdge(from: 7, to: 8)))
        #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == 9223372036854775001)
        #expect(decoded.vertices.firstIndex(of: -1) == 4611686018427387904)
    }
    #endif
}
