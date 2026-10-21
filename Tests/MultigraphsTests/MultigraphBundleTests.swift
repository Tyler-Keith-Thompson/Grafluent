//
//  MultigraphBundleTests.swift
//  Grafluent
//
//  `PropertyGraphBundle` over the pseudographs and the multigraphs, whose maps are the
//  pseudographs' through a delegator.
//

import Foundation
import GraphProtocols
import Multigraphs
import Testing

@Suite struct MultigraphBundleTests {
    @Test("MB-1 parallel edges and a self-loop keep their own values through a round trip")
    func pseudograph() throws {
        var graph = Pseudograph<String>(vertices: ["a", "b"])
        let first = graph.insert(edge: UndirectedEdge("a", "b"))
        let second = graph.insert(edge: UndirectedEdge("a", "b"))
        let loop = graph.insert(edge: UndirectedEdge("b", "b"))
        let weights = graph.addEdgeMap(default: 0)
        graph[weights, ofEdgeAt: first] = 1
        graph[weights, ofEdgeAt: second] = 2
        graph[weights, ofEdgeAt: loop] = 3
        let bundle = PropertyGraphBundle(graph, maps: weights)
        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<Pseudograph<String>, EdgeMap<Int>>.self, from: data)
        let expected = [1, 2, 3]
        #expect(back.graph == graph)
        #expect([first, second, loop].map { back.graph[back.maps, ofEdgeAt: $0] } == expected)
        #expect(back == bundle)
    }

    @Test("MB-2 a multigraph's bundle reattaches through the delegator")
    func multigraph() throws {
        var graph = DirectedMultigraph<Int>(vertices: 0 ..< 3)
        let p = try graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let q = try graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let names = graph.addVertexMap(default: "")
        let weights = graph.addEdgeMap(default: 1.5)
        graph[names, of: 2] = "two"
        graph[weights, ofEdgeAt: q] = 4
        let bundle = PropertyGraphBundle(graph, maps: names, weights)
        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<DirectedMultigraph<Int>, VertexMap<String>, EdgeMap<Double>>.self, from: data)
        let expectedName = "two"
        let expectedP = 1.5
        let expectedQ = 4.0
        #expect(back.graph == graph)
        #expect(back.graph[back.maps.0, of: 2] == expectedName)
        #expect(back.graph[back.maps.1, ofEdgeAt: p] == expectedP)
        #expect(back.graph[back.maps.1, ofEdgeAt: q] == expectedQ)
        #expect(back == bundle)
        #expect(back.hashValue == bundle.hashValue)
    }
}
