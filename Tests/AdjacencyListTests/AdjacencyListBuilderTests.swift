// The result builder initializer.

import AdjacencyListModule
import GraphProtocols
import Testing

@Suite("AdjacencyList result builder")
struct AdjacencyListBuilderTests {
    @Test("an empty builder gives the empty graph")
    func emptyBuilder() {
        let graph = AdjacencyList<Int> {}
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
        #expect(graph == AdjacencyList())
    }

    @Test("edges and isolated vertices")
    func edgesAndVertices() {
        let graph = AdjacencyList<Int> {
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 0, to: 2)
            DirectedEdge(from: 0, to: 3)
            DirectedEdge(from: 1, to: 1)
            DirectedEdge(from: 1, to: 2)
            DirectedEdge(from: 1, to: 0)
            4
        }
        #expect(graph.vertexCount == 5)
        #expect(graph.edgeCount == 6)
        #expect(graph.contains(4))
        #expect(graph.degree(of: 4) == 0)
        #expect(graph.contains(edge: DirectedEdge(from: 1, to: 1)))
        #expect(graph == AdjacencyList(adjacency: [0: [1, 2, 3], 1: [1, 2, 0], 4: []]))
    }

    @Test("for loops")
    func forLoop() {
        let graph = AdjacencyList<Int> {
            for i in 0 ..< 10 {
                DirectedEdge(from: i, to: (i + 1) % 10)
            }
        }
        #expect(graph.vertexCount == 10)
        #expect(graph.edgeCount == 10)
        for v in 0 ..< 10 {
            #expect(Array(graph.successors(of: v)) == [(v + 1) % 10])
            #expect(Array(graph.predecessors(of: v)) == [(v + 9) % 10])
        }
    }

    @Test("if, if-else, and optional content", arguments: [false, true])
    func conditionals(_ flag: Bool) {
        let graph = AdjacencyList<Int> {
            DirectedEdge(from: 0, to: 1)
            if flag {
                DirectedEdge(from: 1, to: 2)
            }
            if flag {
                DirectedEdge(from: 2, to: 0)
            } else {
                DirectedEdge(from: 2, to: 1)
            }
        }
        if flag {
            #expect(Set(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        } else {
            #expect(Set(graph.edges) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
        }
        #expect(graph.vertexCount == 3)
    }

    @Test("switch")
    func switchStatement() {
        for shape in 0 ..< 3 {
            let graph = AdjacencyList<Int> {
                switch shape {
                case 0: DirectedEdge(from: 0, to: 0)
                case 1: DirectedEdge(from: 0, to: 1)
                default: 7
                }
            }
            switch shape {
            case 0:
                #expect(graph.vertexCount == 1)
                #expect(graph.edgeCount == 1)
            case 1:
                #expect(graph.vertexCount == 2)
                #expect(graph.edgeCount == 1)
            default:
                #expect(Array(graph.vertices) == [7])
                #expect(graph.edgeCount == 0)
            }
        }
    }

    @Test("duplicates in a builder collapse like any other input")
    func duplicates() {
        let graph = AdjacencyList<Int> {
            DirectedEdge(from: 0, to: 1)
            DirectedEdge(from: 0, to: 1)
            0
            1
        }
        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
    }

    @Test("builder output equals init(vertices:edges:)")
    func matchesInitializer() {
        // The Boost.Graph "house and lollipop" graph, test/test_graph.hpp.
        let edges = [
            DirectedEdge(from: 5, to: 3), DirectedEdge(from: 3, to: 4), DirectedEdge(from: 3, to: 2), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0),
        ]
        let graph = AdjacencyList<Int> {
            for edge in edges { edge }
            9
        }
        #expect(graph == AdjacencyList(vertices: [9], edges: edges))
    }

    @Test("String vertices")
    func stringVertices() {
        // NetworkX test_digraph_historical.py.
        let graph = AdjacencyList<String> {
            DirectedEdge(from: "A", to: "B")
            DirectedEdge(from: "A", to: "C")
            DirectedEdge(from: "B", to: "D")
            DirectedEdge(from: "B", to: "C")
            DirectedEdge(from: "C", to: "D")
            "G"
            "J"
            "K"
        }
        #expect(graph.vertexCount == 7)
        #expect(graph.edgeCount == 5)
        #expect(["A", "B", "C", "D", "G", "J", "K"].map(graph.inDegree(of:)) == [0, 1, 2, 2, 0, 0, 0])
        #expect(["A", "B", "C", "D", "G", "J", "K"].map(graph.outDegree(of:)) == [2, 2, 1, 0, 0, 0, 0])
    }
}
