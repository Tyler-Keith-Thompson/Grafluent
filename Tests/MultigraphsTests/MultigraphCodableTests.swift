// Codable (catalog MG-129 – MG-153): `{"vertices": […], "edges": [u0, v0, u1, v1, …]}`, the simple
// lists' format. Encoding is checked byte for byte (with sorted keys); decoding keeps vertex order
// and positions and rebuilds rows in position order. Corrupt payloads throw `DecodingError` with
// the catalog's case and message.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs Codable")
struct MultigraphCodableTests {
    @Test("MG-129 round trip keeps vertex order and positions", .tags(.conformance))
    func mg129() throws {
        // Pseudograph V [] E [0–1, 0–1, 1–1]
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edges\":[0,1,0,1,1,1],\"vertices\":[0,1]}")
        // The payload as the catalog writes it (vertices first) decodes the same way.
        for payload in [data, Data("{\"vertices\":[0,1],\"edges\":[0,1,0,1,1,1]}".utf8)] {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [0, 1])
            #expect(decoded.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1], [1, 1]])
            #expect(decoded.vertexCount == 2)
            #expect(decoded.edgeCount == 3)
            #expect(Array(decoded.neighbors(of: 0)) == [1, 1])
            #expect(Array(decoded.incidentEdges(of: 0)) == [0, 1])
            #expect(Array(decoded.neighbors(of: 1)) == [0, 0, 1, 1])
            #expect(Array(decoded.incidentEdges(of: 1)) == [0, 1, 2, 2])
            #expect(Array(decoded.edges(between: 0, and: 1)) == [0, 1])
            #expect(decoded.edgeCount(between: 0, and: 1) == 2)
            #expect(Array(decoded.edges(between: 1, and: 1)) == [2])
            #expect(decoded.edgeCount(between: 1, and: 1) == 1)
        }
    }

    @Test("MG-130 round trip keeps vertex order and positions", .tags(.conformance))
    func mg130() throws {
        // Pseudograph V [3] E [0–1]
        let graph = Pseudograph<Int>(vertices: [3], edges: [UndirectedEdge(0, 1)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edges\":[1,2],\"vertices\":[3,0,1]}")
        // The payload as the catalog writes it (vertices first) decodes the same way.
        for payload in [data, Data("{\"vertices\":[3,0,1],\"edges\":[1,2]}".utf8)] {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [3, 0, 1])
            #expect(decoded.edges.map { [$0.u, $0.v] } == [[0, 1]])
            #expect(decoded.vertexCount == 3)
            #expect(decoded.edgeCount == 1)
            #expect(Array(decoded.neighbors(of: 3)) == [] as [Int])
            #expect(Array(decoded.incidentEdges(of: 3)) == [] as [Int])
            #expect(Array(decoded.neighbors(of: 0)) == [1])
            #expect(Array(decoded.incidentEdges(of: 0)) == [0])
            #expect(Array(decoded.neighbors(of: 1)) == [0])
            #expect(Array(decoded.incidentEdges(of: 1)) == [0])
            #expect(Array(decoded.edges(between: 0, and: 1)) == [0])
            #expect(decoded.edgeCount(between: 0, and: 1) == 1)
        }
    }

    @Test("MG-131 round trip keeps vertex order and positions", .tags(.conformance))
    func mg131() throws {
        // Pseudograph V [] E [0–1, 1–2, 0–1, 2–2] then remove(edgeAt: 0)
        var graph = Pseudograph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 1), UndirectedEdge(2, 2)])
        graph.remove(edgeAt: 0)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edges\":[2,2,1,2,0,1],\"vertices\":[0,1,2]}")
        // The payload as the catalog writes it (vertices first) decodes the same way.
        for payload in [data, Data("{\"vertices\":[0,1,2],\"edges\":[2,2,1,2,0,1]}".utf8)] {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [0, 1, 2])
            #expect(decoded.edges.map { [$0.u, $0.v] } == [[2, 2], [1, 2], [0, 1]])
            #expect(decoded.vertexCount == 3)
            #expect(decoded.edgeCount == 3)
            #expect(Array(decoded.neighbors(of: 0)) == [1])
            #expect(Array(decoded.incidentEdges(of: 0)) == [2])
            #expect(Array(decoded.neighbors(of: 1)) == [2, 0])
            #expect(Array(decoded.incidentEdges(of: 1)) == [1, 2])
            #expect(Array(decoded.neighbors(of: 2)) == [2, 2, 1])
            #expect(Array(decoded.incidentEdges(of: 2)) == [0, 0, 1])
            #expect(Array(decoded.edges(between: 2, and: 2)) == [0])
            #expect(decoded.edgeCount(between: 2, and: 2) == 1)
            #expect(Array(decoded.edges(between: 1, and: 2)) == [1])
            #expect(decoded.edgeCount(between: 1, and: 2) == 1)
            #expect(Array(decoded.edges(between: 0, and: 1)) == [2])
            #expect(decoded.edgeCount(between: 0, and: 1) == 1)
        }
    }

    @Test("MG-132 round trip keeps vertex order and positions", .tags(.conformance))
    func mg132() throws {
        // Pseudograph V ["a", "b"] E ["b"–"a", "a"–"b"]
        let graph = Pseudograph<String>(vertices: ["a", "b"], edges: [UndirectedEdge("b", "a"), UndirectedEdge("a", "b")])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edges\":[1,0,0,1],\"vertices\":[\"a\",\"b\"]}")
        // The payload as the catalog writes it (vertices first) decodes the same way.
        for payload in [data, Data("{\"vertices\":[\"a\",\"b\"],\"edges\":[1,0,0,1]}".utf8)] {
            let decoded = try JSONDecoder().decode(Pseudograph<String>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == ["a", "b"])
            #expect(decoded.edges.map { [$0.u, $0.v] } == [["b", "a"], ["a", "b"]])
            #expect(decoded.vertexCount == 2)
            #expect(decoded.edgeCount == 2)
            #expect(Array(decoded.neighbors(of: "a")) == ["b", "b"])
            #expect(Array(decoded.incidentEdges(of: "a")) == [0, 1])
            #expect(Array(decoded.neighbors(of: "b")) == ["a", "a"])
            #expect(Array(decoded.incidentEdges(of: "b")) == [0, 1])
            #expect(Array(decoded.edges(between: "b", and: "a")) == [0, 1])
            #expect(decoded.edgeCount(between: "b", and: "a") == 2)
        }
    }

    @Test("MG-133 round trip keeps vertex order and positions", .tags(.conformance))
    func mg133() throws {
        // Multigraph V [] E [0–1, 1–0]
        let graph = try #require(Multigraph<Int>(vertices: [] as [Int], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0)]))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edges\":[0,1,1,0],\"vertices\":[0,1]}")
        // The payload as the catalog writes it (vertices first) decodes the same way.
        for payload in [data, Data("{\"vertices\":[0,1],\"edges\":[0,1,1,0]}".utf8)] {
            let decoded = try JSONDecoder().decode(Multigraph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [0, 1])
            #expect(decoded.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 0]])
            #expect(decoded.vertexCount == 2)
            #expect(decoded.edgeCount == 2)
            #expect(Array(decoded.neighbors(of: 0)) == [1, 1])
            #expect(Array(decoded.incidentEdges(of: 0)) == [0, 1])
            #expect(Array(decoded.neighbors(of: 1)) == [0, 0])
            #expect(Array(decoded.incidentEdges(of: 1)) == [0, 1])
            #expect(Array(decoded.edges(between: 0, and: 1)) == [0, 1])
            #expect(decoded.edgeCount(between: 0, and: 1) == 2)
        }
    }

    @Test("MG-134 round trip keeps vertex order and positions", .tags(.conformance))
    func mg134() throws {
        // DirectedPseudograph V [] E [0→1, 0→1, 1→0, 1→1]
        let graph = DirectedPseudograph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 1)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edges\":[0,1,0,1,1,0,1,1],\"vertices\":[0,1]}")
        // The payload as the catalog writes it (vertices first) decodes the same way.
        for payload in [data, Data("{\"vertices\":[0,1],\"edges\":[0,1,0,1,1,0,1,1]}".utf8)] {
            let decoded = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [0, 1])
            #expect(decoded.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 1], [1, 0], [1, 1]])
            #expect(decoded.vertexCount == 2)
            #expect(decoded.edgeCount == 4)
            #expect(Array(decoded.successors(of: 0)) == [1, 1])
            #expect(Array(decoded.outEdges(of: 0)) == [0, 1])
            #expect(Array(decoded.predecessors(of: 0)) == [1])
            #expect(Array(decoded.inEdges(of: 0)) == [2])
            #expect(Array(decoded.successors(of: 1)) == [0, 1])
            #expect(Array(decoded.outEdges(of: 1)) == [2, 3])
            #expect(Array(decoded.predecessors(of: 1)) == [0, 0, 1])
            #expect(Array(decoded.inEdges(of: 1)) == [0, 1, 3])
            #expect(Array(decoded.edges(from: 0, to: 1)) == [0, 1])
            #expect(decoded.edgeCount(from: 0, to: 1) == 2)
            #expect(Array(decoded.edges(from: 1, to: 0)) == [2])
            #expect(decoded.edgeCount(from: 1, to: 0) == 1)
            #expect(Array(decoded.edges(from: 1, to: 1)) == [3])
            #expect(decoded.edgeCount(from: 1, to: 1) == 1)
        }
    }

    @Test("MG-135 round trip keeps vertex order and positions", .tags(.conformance))
    func mg135() throws {
        // DirectedMultigraph V [] E [0→1, 0→1]
        let graph = try #require(DirectedMultigraph<Int>(vertices: [] as [Int], edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)]))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edges\":[0,1,0,1],\"vertices\":[0,1]}")
        // The payload as the catalog writes it (vertices first) decodes the same way.
        for payload in [data, Data("{\"vertices\":[0,1],\"edges\":[0,1,0,1]}".utf8)] {
            let decoded = try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [0, 1])
            #expect(decoded.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 1]])
            #expect(decoded.vertexCount == 2)
            #expect(decoded.edgeCount == 2)
            #expect(Array(decoded.successors(of: 0)) == [1, 1])
            #expect(Array(decoded.outEdges(of: 0)) == [0, 1])
            #expect(Array(decoded.predecessors(of: 0)) == [] as [Int])
            #expect(Array(decoded.inEdges(of: 0)) == [] as [Int])
            #expect(Array(decoded.successors(of: 1)) == [] as [Int])
            #expect(Array(decoded.outEdges(of: 1)) == [] as [Int])
            #expect(Array(decoded.predecessors(of: 1)) == [0, 0])
            #expect(Array(decoded.inEdges(of: 1)) == [0, 1])
            #expect(Array(decoded.edges(from: 0, to: 1)) == [0, 1])
            #expect(decoded.edgeCount(from: 0, to: 1) == 2)
        }
    }

    @Test("MG-136 round trip keeps vertex order and positions", .tags(.conformance))
    func mg136() throws {
        // Pseudograph V [] E []
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(graph)
        #expect(String(decoding: data, as: UTF8.self) == "{\"edges\":[],\"vertices\":[]}")
        // The payload as the catalog writes it (vertices first) decodes the same way.
        for payload in [data, Data("{\"vertices\":[],\"edges\":[]}".utf8)] {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            #expect(decoded == graph)
            #expect(Array(decoded.vertices) == [] as [Int])
            #expect(decoded.edges.map { [$0.u, $0.v] } == [] as [[Int]])
            #expect(decoded.vertexCount == 0)
            #expect(decoded.edgeCount == 0)
        }
    }

    @Test("MG-137 copies accepted", .tags(.conformance))
    func mg137() throws {
        // Pseudograph decode {"vertices":[0,1],"edges":[0,1,0,1]} → V [0, 1]; E [0–1, 0–1]; rows 0:[1@0, 1@1] 1:[0@0, 0@1]
        let payload = Data("{\"vertices\":[0,1],\"edges\":[0,1,0,1]}".utf8)
        let graph = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [0, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1, 1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 1])
        #expect(Array(graph.neighbors(of: 1)) == [0, 0])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 1) == 2)
    }

    @Test("MG-138 loops accepted", .tags(.conformance))
    func mg138() throws {
        // Pseudograph decode {"vertices":[0],"edges":[0,0,0,0]} → V [0]; E [0–0, 0–0]; rows 0:[0@0, 0@0, 0@1, 0@1]
        let payload = Data("{\"vertices\":[0],\"edges\":[0,0,0,0]}".utf8)
        let graph = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 0], [0, 0]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [0, 0, 0, 0])
        #expect(Array(graph.incidentEdges(of: 0)) == [0, 0, 1, 1])
        #expect(Array(graph.edges(between: 0, and: 0)) == [0, 1])
        #expect(graph.edgeCount(between: 0, and: 0) == 2)
    }

    @Test("MG-139 loop rejected", .tags(.conformance))
    func mg139() throws {
        // Multigraph decode {"vertices":[0],"edges":[0,0]} → dataCorrupted(Self-loop)
        let payload = Data("{\"vertices\":[0],\"edges\":[0,0]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(Multigraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Self-loop")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-140 directed loop rejected", .tags(.conformance))
    func mg140() throws {
        // DirectedMultigraph decode {"vertices":[0,1],"edges":[0,1,1,1]} → dataCorrupted(Self-loop)
        let payload = Data("{\"vertices\":[0,1],\"edges\":[0,1,1,1]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Self-loop")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-141 directed loop accepted", .tags(.conformance))
    func mg141() throws {
        // DirectedPseudograph decode {"vertices":[0],"edges":[0,0]} → V [0]; E [0→0]; out 0:[0@0]; in 0:[0@0]
        let payload = Data("{\"vertices\":[0],\"edges\":[0,0]}".utf8)
        let graph = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: payload)
        #expect(Array(graph.vertices) == [0])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 0]])
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 1)
        #expect(Array(graph.successors(of: 0)) == [0])
        #expect(Array(graph.outEdges(of: 0)) == [0])
        #expect(Array(graph.predecessors(of: 0)) == [0])
        #expect(Array(graph.inEdges(of: 0)) == [0])
        #expect(Array(graph.edges(from: 0, to: 0)) == [0])
        #expect(graph.edgeCount(from: 0, to: 0) == 1)
    }

    @Test("MG-142 odd length", .tags(.conformance))
    func mg142() throws {
        // Pseudograph decode {"vertices":[0,1],"edges":[0]} → dataCorrupted(Edge list has odd length)
        let payload = Data("{\"vertices\":[0,1],\"edges\":[0]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Edge list has odd length")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-143 repeated vertex", .tags(.conformance))
    func mg143() throws {
        // Pseudograph decode {"vertices":[0,0],"edges":[]} → dataCorrupted(Repeated vertex)
        let payload = Data("{\"vertices\":[0,0],\"edges\":[]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Repeated vertex")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-144 endpoint out of range", .tags(.conformance))
    func mg144() throws {
        // Pseudograph decode {"vertices":[0,1],"edges":[0,2]} → dataCorrupted(Edge endpoint out of range)
        let payload = Data("{\"vertices\":[0,1],\"edges\":[0,2]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Edge endpoint out of range")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-145 negative endpoint", .tags(.conformance))
    func mg145() throws {
        // Pseudograph decode {"vertices":[0,1],"edges":[-1,0]} → dataCorrupted(Edge endpoint out of range)
        let payload = Data("{\"vertices\":[0,1],\"edges\":[-1,0]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Edge endpoint out of range")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-146 endpoint with no vertices", .tags(.conformance))
    func mg146() throws {
        // DirectedPseudograph decode {"vertices":[],"edges":[0,0]} → dataCorrupted(Edge endpoint out of range)
        let payload = Data("{\"vertices\":[],\"edges\":[0,0]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Edge endpoint out of range")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-147 missing vertices", .tags(.conformance))
    func mg147() throws {
        // Pseudograph decode {"edges":[]} → keyNotFound(vertices)
        let payload = Data("{\"edges\":[]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.keyNotFound(key, _) {
            #expect(key.stringValue == "vertices")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-148 missing edges", .tags(.conformance))
    func mg148() throws {
        // DirectedPseudograph decode {"vertices":[]} → keyNotFound(edges)
        let payload = Data("{\"vertices\":[]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedPseudograph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.keyNotFound(key, _) {
            #expect(key.stringValue == "edges")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-149 string vertices", .tags(.conformance))
    func mg149() throws {
        // Pseudograph decode {"vertices":["a","b"],"edges":[1,0,0,1]} → V ["a", "b"]; E ["b"–"a", "a"–"b"]; rows "a":["b"@0, "b"@1] "b":["a"@0, "a"@1]
        let payload = Data("{\"vertices\":[\"a\",\"b\"],\"edges\":[1,0,0,1]}".utf8)
        let graph = try JSONDecoder().decode(Pseudograph<String>.self, from: payload)
        #expect(Array(graph.vertices) == ["a", "b"])
        #expect(graph.edges.map { [$0.u, $0.v] } == [["b", "a"], ["a", "b"]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: "a")) == ["b", "b"])
        #expect(Array(graph.incidentEdges(of: "a")) == [0, 1])
        #expect(Array(graph.neighbors(of: "b")) == ["a", "a"])
        #expect(Array(graph.incidentEdges(of: "b")) == [0, 1])
        #expect(Array(graph.edges(between: "b", and: "a")) == [0, 1])
        #expect(graph.edgeCount(between: "b", and: "a") == 2)
    }

    @Test("MG-150 directed copies accepted", .tags(.conformance))
    func mg150() throws {
        // DirectedMultigraph decode {"vertices":[0,1],"edges":[0,1,0,1,1,0]} → V [0, 1]; E [0→1, 0→1, 1→0]; out 0:[1@0, 1@1] 1:[0@2]; in 0:[1@2] 1:[0@0, 0@1]
        let payload = Data("{\"vertices\":[0,1],\"edges\":[0,1,0,1,1,0]}".utf8)
        let graph = try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: payload)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 1], [0, 1], [1, 0]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 3)
        #expect(Array(graph.successors(of: 0)) == [1, 1])
        #expect(Array(graph.outEdges(of: 0)) == [0, 1])
        #expect(Array(graph.predecessors(of: 0)) == [1])
        #expect(Array(graph.inEdges(of: 0)) == [2])
        #expect(Array(graph.successors(of: 1)) == [0])
        #expect(Array(graph.outEdges(of: 1)) == [2])
        #expect(Array(graph.predecessors(of: 1)) == [0, 0])
        #expect(Array(graph.inEdges(of: 1)) == [0, 1])
        #expect(Array(graph.edges(from: 0, to: 1)) == [0, 1])
        #expect(graph.edgeCount(from: 0, to: 1) == 2)
        #expect(Array(graph.edges(from: 1, to: 0)) == [2])
        #expect(graph.edgeCount(from: 1, to: 0) == 1)
    }

    @Test("MG-151 UndirectedAdjacencyList payload decodes as Pseudograph", .tags(.conformance))
    func mg151() throws {
        // Pseudograph decode {"vertices":[0,1],"edges":[0,1,1,1]} → V [0, 1]; E [0–1, 1–1]; rows 0:[1@0] 1:[0@0, 1@1, 1@1]
        let payload = Data("{\"vertices\":[0,1],\"edges\":[0,1,1,1]}".utf8)
        let graph = try JSONDecoder().decode(Pseudograph<Int>.self, from: payload)
        #expect(Array(graph.vertices) == [0, 1])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [1, 1]])
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 2)
        #expect(Array(graph.neighbors(of: 0)) == [1])
        #expect(Array(graph.incidentEdges(of: 0)) == [0])
        #expect(Array(graph.neighbors(of: 1)) == [0, 1, 1])
        #expect(Array(graph.incidentEdges(of: 1)) == [0, 1, 1])
        #expect(Array(graph.edges(between: 0, and: 1)) == [0])
        #expect(graph.edgeCount(between: 0, and: 1) == 1)
        #expect(Array(graph.edges(between: 1, and: 1)) == [1])
        #expect(graph.edgeCount(between: 1, and: 1) == 1)
    }

    @Test("MG-152 Pseudograph payload with copies fails as UndirectedAdjacencyList", .tags(.conformance))
    func mg152() throws {
        // UndirectedAdjacencyList decode {"vertices":[0,1],"edges":[0,1,1,0]} → dataCorrupted(Repeated edge)
        let payload = Data("{\"vertices\":[0,1],\"edges\":[0,1,1,0]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Repeated edge")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test("MG-153 AdjacencyList payload with a loop fails as DirectedMultigraph", .tags(.conformance))
    func mg153() throws {
        // DirectedMultigraph decode {"vertices":[0],"edges":[0,0]} → dataCorrupted(Self-loop)
        let payload = Data("{\"vertices\":[0],\"edges\":[0,0]}".utf8)
        do {
            let decoded = try JSONDecoder().decode(DirectedMultigraph<Int>.self, from: payload)
            Issue.record("decoded \(decoded)")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(context.debugDescription == "Self-loop")
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
