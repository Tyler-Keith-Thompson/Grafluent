//
//  StableGraphBundleTests.swift
//  Grafluent
//
//  `PropertyGraphBundle` over the stable graphs: paged maps round-trip with their holes, and a
//  decoded map answers at the surviving positions.
//

import Foundation
import GraphProtocols
import StableGraphs
import Testing

@Suite struct StableGraphBundleTests {
    @Test("SB-1 a directed graph with holes round-trips its paged maps, holes included")
    func directedWithHoles() throws {
        var graph = StableDirectedGraph<String>(vertices: ["a", "b", "c", "d"])
        let ab = graph.insert(edge: DirectedEdge(from: "a", to: "b"))
        let bc = graph.insert(edge: DirectedEdge(from: "b", to: "c"))
        let cd = graph.insert(edge: DirectedEdge(from: "c", to: "d"))
        let lengths = graph.addEdgeMap(default: 1.0)
        let names = graph.addVertexMap(of: String.self)
        graph[lengths, ofEdgeAt: ab] = 2
        graph[lengths, ofEdgeAt: bc] = 3
        graph[lengths, ofEdgeAt: cd] = 4
        graph[names, of: "a"] = "ay"
        graph[names, of: "d"] = "dee"
        graph.remove(edgeAt: bc)
        graph.remove("b")
        let bundle = PropertyGraphBundle(graph, maps: lengths, names)

        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<StableDirectedGraph<String>, EdgeMap<Double>, VertexMap<String?>>.self, from: data)

        let expectedCD = 4.0
        let expectedD = "dee"
        #expect(back.graph == graph)
        #expect(back.graph.edges.indices.elementsEqual(graph.edges.indices))
        #expect(back.graph[back.maps.0, ofEdgeAt: cd] == expectedCD)
        #expect(back.graph[back.maps.1, of: "d"] == expectedD)
        #expect(back.graph[back.maps.1, of: "c"] == nil)
        #expect(back == bundle)
        #expect(back.hashValue == bundle.hashValue)
        #expect(throws: EdgeNotFound.self) { try back.graph[back.maps.0, checkedEdgeAt: bc] }
    }

    @Test("SB-2 the next insert after decoding takes the same position and the map's default")
    func insertAfterDecoding() throws {
        var graph = StableDirectedGraph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let weights = graph.addEdgeMap(default: 7)
        graph[weights, ofEdgeAt: 0] = 1
        let data = try JSONEncoder().encode(PropertyGraphBundle(graph, maps: weights))
        var back = try JSONDecoder().decode(PropertyGraphBundle<StableDirectedGraph<Int>, EdgeMap<Int>>.self, from: data)
        let p = back.graph.insert(edge: DirectedEdge(from: 2, to: 0))
        let expectedPosition = 2
        let expectedDefault = 7
        #expect(p == expectedPosition)
        #expect(back.graph[back.maps, ofEdgeAt: p] == expectedDefault)
        #expect(back.graph[back.maps, ofEdgeAt: 0] == 1)
    }

    @Test("SB-3 an undirected graph's bundle round-trips through the same pages")
    func undirected() throws {
        var graph = StableUndirectedGraph<Int>(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        let weights = graph.addEdgeMap(default: 0)
        let marks = graph.addVertexMap(default: false)
        graph[weights, ofEdgeAt: 2] = 5
        graph[marks, of: 1] = true
        graph.remove(edgeAt: 0)
        let bundle = PropertyGraphBundle(graph, maps: weights, marks)
        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<StableUndirectedGraph<Int>, EdgeMap<Int>, VertexMap<Bool>>.self, from: data)
        let expected = 5
        #expect(back.graph == graph)
        #expect(back.graph[back.maps.0, ofEdgeAt: 2] == expected)
        #expect(back.graph[back.maps.1, of: 1] == true)
        #expect(back.graph[back.maps.1, of: 0] == false)
        #expect(back == bundle)
    }

    @Test("SB-4 a map whose every page is unallocated encodes as no pages and decodes as all defaults")
    func emptyPages() throws {
        var graph = StableDirectedGraph<Int>(edges: [DirectedEdge(from: 0, to: 1)])
        let weights = graph.addEdgeMap(default: 3)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let text = String(decoding: try encoder.encode(graph.values(of: weights)), as: UTF8.self)
        let expected = #"{"default":3,"firstPage":0,"pages":[]}"#
        #expect(text == expected)
        let back = try JSONDecoder().decode(EdgeValues<StableDirectedGraph<Int>, Int>.self, from: Data(text.utf8))
        let again = graph.addEdgeMap(values: back)
        let expectedDefault = 3
        #expect(graph[again, ofEdgeAt: 0] == expectedDefault)
        #expect(back == graph.values(of: weights))
    }

    @Test("SB-5 a page that is neither empty nor full is a decoding error")
    func malformedPage() throws {
        let text = #"{"default":3,"firstPage":0,"pages":[[1,2,3]]}"#
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(EdgeValues<StableDirectedGraph<Int>, Int>.self, from: Data(text.utf8)) }
        let negativeFirst = #"{"default":3,"firstPage":-1,"pages":[]}"#
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(EdgeValues<StableDirectedGraph<Int>, Int>.self, from: Data(negativeFirst.utf8)) }
    }

    @Test("SB-6 paged snapshots compare by value: a set default equals an unallocated page")
    func pagedEquality() {
        var graph = StableDirectedGraph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let a = graph.addEdgeMap(default: 0)
        let b = graph.addEdgeMap(default: 0)
        graph[b, ofEdgeAt: 1] = 0
        #expect(graph.values(of: a) == graph.values(of: b))
        #expect(graph.values(of: a).hashValue == graph.values(of: b).hashValue)
        graph[b, ofEdgeAt: 1] = 1
        #expect(graph.values(of: a) != graph.values(of: b))
        #expect(graph.values(of: b) != graph.values(of: a))
        #expect(graph.values(of: a).hashValue != graph.values(of: b).hashValue)
        // Different defaults differ, even with no value set: the next insert would read differently.
        let c = graph.addEdgeMap(default: 1)
        #expect(graph.values(of: a) != graph.values(of: c))
        #expect(graph.values(of: a).hashValue != graph.values(of: c).hashValue)
        // Both pages allocated, one value apart.
        let e = graph.addEdgeMap(default: 0)
        graph[e, ofEdgeAt: 0] = 5
        graph[e, ofEdgeAt: 1] = 1
        graph[b, ofEdgeAt: 0] = 5
        #expect(graph.values(of: e) == graph.values(of: b))
        graph[e, ofEdgeAt: 0] = 6
        #expect(graph.values(of: e) != graph.values(of: b))
        var other = StableDirectedGraph<Int>(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let d = other.addEdgeMap(default: 1)
        other[d, ofEdgeAt: 1] = 0
        #expect(other.values(of: d) != graph.values(of: b))
    }
}
