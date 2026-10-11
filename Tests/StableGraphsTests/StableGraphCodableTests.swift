// Codable (catalog SG-082 – SG-094): `{vertices, vertexPositions, vertexEnd, edges, edgePositions,
// edgeEnd}`. Encoding is checked byte for byte (with sorted keys); decoding keeps every position
// and both ends, so the next insertions get the positions they would have got before encoding.
// Corrupt payloads throw `DecodingError.dataCorrupted` with the catalog's key and message.
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
}
