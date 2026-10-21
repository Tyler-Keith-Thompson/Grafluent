//
//  PropertyGraphBundleTests.swift
//  Grafluent
//
//  `PropertyGraphBundle`: a graph with some of its attached maps as one Codable, Equatable and
//  Hashable value, the maps reattached by decoding; and the snapshots behind it, `EdgeValues` and
//  `VertexValues`, as values that round-trip and reattach with `addEdgeMap(values:)`.
//

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Foundation
import GraphProtocols
import PropertyBased
import Testing

@Suite struct PropertyGraphBundleTests {
    @Test("PB-1 two maps round-trip through JSON with their handles attached to the decoded graph")
    func roundTripsTwoMapsThroughJSON() throws {
        var graph = AdjacencyList<String>(vertices: ["a", "b", "c"], edges: [.init(from: "a", to: "b"), .init(from: "b", to: "c")])
        let lengths = graph.addEdgeMap(default: 1.0)
        let names = graph.addVertexMap(default: "")
        let ab = graph.edges(from: "a", to: "b").first!
        graph[lengths, ofEdgeAt: ab] = 2.5
        graph[names, of: "c"] = "sea"
        let bundle = PropertyGraphBundle(graph, maps: lengths, names)

        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<AdjacencyList<String>, EdgeMap<Double>, VertexMap<String>>.self, from: data)

        let expectedLength = 2.5
        let expectedName = "sea"
        let expectedDefault = 1.0
        let bc = back.graph.edges(from: "b", to: "c").first!
        #expect(back.graph == graph)
        #expect(back.graph[back.maps.0, ofEdgeAt: ab] == expectedLength)
        #expect(back.graph[back.maps.0, ofEdgeAt: bc] == expectedDefault)
        #expect(back.graph[back.maps.1, of: "c"] == expectedName)
        #expect(back.graph.values(of: back.maps.0).defaultValue == expectedDefault)
        #expect(back == bundle)
        #expect(back.hashValue == bundle.hashValue)
    }

    @Test("PB-2 the encoded form is a list: the version, the graph, then each map's default and values")
    func encodedForm() throws {
        var graph = AdjacencyList<String>(vertices: ["a", "b"], edges: [.init(from: "a", to: "b")])
        let lengths = graph.addEdgeMap(default: 1)
        let names = graph.addVertexMap(default: "")
        graph[names, of: "b"] = "bee"
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let text = String(decoding: try encoder.encode(PropertyGraphBundle(graph, maps: lengths, names)), as: UTF8.self)
        let expected = #"[1,{"edges":[0,1],"vertices":["a","b"]},{"default":1,"values":[1]},{"default":"","values":["","bee"]}]"#
        #expect(text == expected)
    }

    @Test("PB-3 values take part in equality and hashing; the graphs alone stay equal")
    func valuesTakePartInEquality() {
        var graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [.init(from: 0, to: 1)])
        let weights = graph.addEdgeMap(default: 0)
        var other = graph
        other[weights, ofEdgeAt: 0] = 7
        let same = PropertyGraphBundle(graph, maps: weights)
        let changed = PropertyGraphBundle(other, maps: weights)
        var copy = other
        copy[weights, ofEdgeAt: 0] = 7
        let alike = PropertyGraphBundle(copy, maps: weights)
        #expect(same != changed)
        #expect(same.hashValue != changed.hashValue)
        #expect(changed == alike)
        #expect(changed.hashValue == alike.hashValue)
        #expect(graph == other)
        // Different graphs with the same values differ.
        var reversed = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [.init(from: 1, to: 0)])
        let reversedWeights = reversed.addEdgeMap(default: 0)
        reversed[reversedWeights, ofEdgeAt: 0] = 7
        #expect(PropertyGraphBundle(reversed, maps: reversedWeights) != changed)
    }

    @Test("PB-4 a bundle of one map reads the map as maps itself; mutating the graph keeps it in step")
    func singleMapAndMutation() {
        var graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [.init(from: 0, to: 1)])
        let weights = graph.addEdgeMap(default: 0)
        var bundle = PropertyGraphBundle(graph, maps: weights)
        bundle.graph.insert(2)
        bundle.graph.insert(edge: .init(from: 1, to: 2))
        let p = bundle.graph.edges(from: 1, to: 2).first!
        bundle.graph[bundle.maps, ofEdgeAt: p] = 3
        let expected = 3
        #expect(bundle.graph[bundle.maps, ofEdgeAt: p] == expected)
        #expect(bundle.maps == weights)
    }

    @Test("PB-5 a map the bundle does not list stays attached but is neither encoded nor compared")
    func unlistedMap() throws {
        var graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [.init(from: 0, to: 1)])
        let listed = graph.addEdgeMap(default: 0)
        let unlisted = graph.addEdgeMap(default: 0)
        var other = graph
        other[unlisted, ofEdgeAt: 0] = 5
        #expect(PropertyGraphBundle(graph, maps: listed) == PropertyGraphBundle(other, maps: listed))
        let data = try JSONEncoder().encode(PropertyGraphBundle(other, maps: listed))
        let back = try JSONDecoder().decode(PropertyGraphBundle<AdjacencyList<Int>, EdgeMap<Int>>.self, from: data)
        let expectedUnlisted = 5
        #expect(other[unlisted, ofEdgeAt: 0] == expectedUnlisted)
        #expect(back.graph[back.maps, ofEdgeAt: 0] == 0)
    }

    @Test("PB-6 decoding rejects another version, and a dense map of the wrong length, with a DecodingError")
    func decodingErrors() throws {
        var graph = AdjacencyList<Int>(vertices: 0 ..< 2, edges: [.init(from: 0, to: 1)])
        let weights = graph.addEdgeMap(default: 0)
        let names = graph.addVertexMap(default: "")
        typealias Bundle = PropertyGraphBundle<AdjacencyList<Int>, EdgeMap<Int>, VertexMap<String>>
        let good = String(decoding: try JSONEncoder().encode(PropertyGraphBundle(graph, maps: weights, names)), as: UTF8.self)
        #expect(throws: Never.self) { try JSONDecoder().decode(Bundle.self, from: Data(good.utf8)) }

        let otherVersion = good.replacingOccurrences(of: "[1,", with: "[2,")
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Bundle.self, from: Data(otherVersion.utf8)) }

        let shortEdgeMap = good.replacingOccurrences(of: #""values":[0]"#, with: #""values":[]"#)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Bundle.self, from: Data(shortEdgeMap.utf8)) }

        let longVertexMap = good.replacingOccurrences(of: #""values":["",""]"#, with: #""values":["","",""]"#)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Bundle.self, from: Data(longVertexMap.utf8)) }

        let missingMap = good.dropLast(String(#",{"default":"","values":["",""]}]"#).count) + "]"
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Bundle.self, from: Data(missingMap.utf8)) }
    }

    @Test("PB-7 a snapshot round-trips as a value and reattaches with addEdgeMap(values:)")
    func snapshotRoundTripsAndReattaches() throws {
        var graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [.init(from: 0, to: 1), .init(from: 1, to: 2)])
        let weights = graph.addEdgeMap(default: 0)
        graph[weights, ofEdgeAt: 1] = 9
        let data = try JSONEncoder().encode(graph.values(of: weights))
        let decoded = try JSONDecoder().decode(EdgeValues<AdjacencyList<Int>, Int>.self, from: data)
        #expect(decoded == graph.values(of: weights))
        #expect(decoded.hashValue == graph.values(of: weights).hashValue)
        let again = graph.addEdgeMap(values: decoded)
        let expected = 9
        #expect(graph[again, ofEdgeAt: 1] == expected)
        #expect(graph[again, ofEdgeAt: 0] == 0)
        #expect(again != weights)
        // The reattached map is independent of the original.
        graph[again, ofEdgeAt: 0] = 4
        #expect(graph[weights, ofEdgeAt: 0] == 0)
    }

    @Test("PB-8 attaching a dense snapshot of the wrong length traps", .tags(.precondition))
    func wrongLengthTraps() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [.init(from: 0, to: 1), .init(from: 1, to: 2)])
            let weights = graph.addEdgeMap(default: 0)
            let values = graph.values(of: weights)
            graph.insert(edge: .init(from: 2, to: 0))
            _ = graph.addEdgeMap(values: values)
        }
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList<Int>(vertices: 0 ..< 3)
            let names = graph.addVertexMap(default: "")
            let values = graph.values(of: names)
            graph.insert(3)
            _ = graph.addVertexMap(values: values)
        }
    }

    @Test("PB-9 bundling a map of another graph traps", .tags(.precondition))
    func foreignMapTraps() async {
        await #expect(processExitsWith: .failure) {
            var graph = AdjacencyList<Int>(vertices: 0 ..< 2)
            var other = AdjacencyList<Int>(vertices: 0 ..< 2)
            _ = graph.addVertexMap(default: 0)
            let foreign = other.addVertexMap(default: 0)
            _ = PropertyGraphBundle(graph, maps: foreign)
        }
    }

    @Test("PB-10 an adjacency matrix's edge map, one value per cell, round-trips by cell")
    func adjacencyMatrix() throws {
        var graph = AdjacencyMatrix(vertexCount: 3, edges: [.init(from: 0, to: 2), .init(from: 2, to: 1)])
        let weights = graph.addEdgeMap(default: 0.5)
        let names = graph.addVertexMap(default: "v")
        let cell = graph.outEdges(of: 2).first!
        graph[weights, ofEdgeAt: cell] = 8
        graph[names, of: 1] = "one"
        let bundle = PropertyGraphBundle(graph, maps: weights, names)
        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<AdjacencyMatrix, EdgeMap<Double>, VertexMap<String>>.self, from: data)
        let expectedWeight = 8.0
        let expectedName = "one"
        #expect(back.graph == graph)
        #expect(back.graph[back.maps.0, ofEdgeAt: cell] == expectedWeight)
        #expect(back.graph[back.maps.1, of: 1] == expectedName)
        #expect(back == bundle)
    }

    @Test("PB-11 a compressed sparse row graph's maps round-trip by edge index")
    func compressedSparseRow() throws {
        var graph = CompressedSparseRow(vertexCount: 3, edges: [.init(from: 0, to: 1), .init(from: 0, to: 2), .init(from: 2, to: 0)])
        let weights = graph.addEdgeMap(default: 1)
        graph[weights, ofEdgeAt: 2] = -3
        let bundle = PropertyGraphBundle(graph, maps: weights)
        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<CompressedSparseRow, EdgeMap<Int>>.self, from: data)
        let expected = -3
        #expect(back.graph == graph)
        #expect(back.graph[back.maps, ofEdgeAt: 2] == expected)
        #expect(back.graph.values(of: back.maps) == graph.values(of: weights))
        #expect(back == bundle)
    }

    @Test("PB-12 random graphs and values round-trip, and the decoded bundle equals the original")
    func randomRoundTrips() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        let values = Gen.int(in: -3 ... 3).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: edges, values) { raw, raw2 in
            var graph = AdjacencyList<Int>(vertices: 0 ..< 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let weights = graph.addEdgeMap(default: 0)
            let tags = graph.addVertexMap(default: -1)
            for (k, p) in graph.edges.indices.enumerated() where k < raw2.count { graph[weights, ofEdgeAt: p] = raw2[k] }
            for (k, v) in raw2.enumerated() where k < 6 { graph[tags, of: k] = v }
            let bundle = PropertyGraphBundle(graph, maps: weights, tags)
            guard let data = try? JSONEncoder().encode(bundle),
                let back = try? JSONDecoder().decode(PropertyGraphBundle<AdjacencyList<Int>, EdgeMap<Int>, VertexMap<Int>>.self, from: data)
            else {
                Issue.record("Round trip failed for \(raw) \(raw2)")
                return
            }
            #expect(back == bundle)
            #expect(back.hashValue == bundle.hashValue)
            for p in graph.edges.indices {
                #expect(back.graph[back.maps.0, ofEdgeAt: p] == graph[weights, ofEdgeAt: p])
            }
            for v in 0 ..< 6 {
                #expect(back.graph[back.maps.1, of: v] == graph[tags, of: v])
            }
        }
    }
}
