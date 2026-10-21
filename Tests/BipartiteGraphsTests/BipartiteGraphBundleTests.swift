//
//  BipartiteGraphBundleTests.swift
//  Grafluent
//
//  `PropertyGraphBundle` over a `BipartiteGraph`, whose maps are its base's through a delegator.
//

import BipartiteGraphs
import Foundation
import GraphProtocols
import Testing

@Suite struct BipartiteGraphBundleTests {
    @Test("BB-1 a bipartite graph's maps round-trip with the sides")
    func roundTrip() throws {
        var graph = BipartiteGraph(left: ["l1", "l2"], right: ["r1"], edges: [UndirectedEdge("l1", "r1"), UndirectedEdge("l2", "r1")])!
        let weights = graph.addEdgeMap(default: 0)
        let sides = graph.addVertexMap(default: "")
        let p = graph.incidentEdges(of: "l2").first { graph.oppositeVertex(to: "l2", acrossEdgeAt: $0) == "r1" }!
        graph[weights, ofEdgeAt: p] = 9
        graph[sides, of: "r1"] = "right"
        let bundle = PropertyGraphBundle(graph, maps: weights, sides)
        let data = try JSONEncoder().encode(bundle)
        let back = try JSONDecoder().decode(PropertyGraphBundle<BipartiteGraph<String>, EdgeMap<Int>, VertexMap<String>>.self, from: data)
        let expectedWeight = 9
        let expectedSide = "right"
        #expect(back.graph == graph)
        #expect(back.graph.left.sorted() == ["l1", "l2"])
        #expect(back.graph[back.maps.0, ofEdgeAt: p] == expectedWeight)
        #expect(back.graph[back.maps.1, of: "r1"] == expectedSide)
        #expect(back == bundle)
    }
}
