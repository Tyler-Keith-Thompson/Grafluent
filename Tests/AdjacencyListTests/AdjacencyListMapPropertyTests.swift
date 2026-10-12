// Attached maps against a model, with shrinking (swift-property-based; catalog AM-12): a random
// sequence of insertions, removals, clears and value writes runs on a graph with an edge map, an
// Optional edge map and a vertex map, and on a model that keys each value by the edge or vertex
// itself (a Dictionary). After every step, the value at every position must be the model's value
// of the element there, through the subscripts and `values(of:)`, and the position just past the
// last must throw. On a failure, PropertyBased prints the smallest failing sequence. Each test
// writes its own model.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

@Suite("AdjacencyList attached maps against a model", .tags(.randomized))
struct AdjacencyListMapPropertyTests {
    @Test("AM-12 AdjacencyList: every value follows its element through random mutations")
    func directed() async {
        // (operation, a, b): a and b name vertices 0...5.
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = AdjacencyList<Int>()
            let weights = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            var weightModel: [DirectedEdge<Int>: Int] = [:]
            var labelModel: [DirectedEdge<Int>: String] = [:]
            var rankModel: [Int: Double] = [:]
            var stamp = 0
            for (step, (operation, a, b)) in operations.enumerated() {
                let edge = DirectedEdge(from: a, to: b)
                stamp += 1
                switch operation {
                case 0:
                    if graph.insert(a).inserted { rankModel[a] = 0.5 }
                case 1, 2:
                    if graph.insert(edge: edge).inserted {
                        weightModel[edge] = -1
                        for v in [a, b] where rankModel[v] == nil { rankModel[v] = 0.5 }
                    }
                case 3:
                    if graph.remove(edge: edge) != nil {
                        weightModel[edge] = nil
                        labelModel[edge] = nil
                    }
                case 4:
                    if graph.remove(a) != nil {
                        rankModel[a] = nil
                        for e in weightModel.keys where e.source == a || e.target == a {
                            weightModel[e] = nil
                            labelModel[e] = nil
                        }
                    }
                case 5, 6:
                    if graph.edgeCount > 0 {
                        let p = (a * 6 + b) % graph.edgeCount
                        let e = graph.edges[p]
                        graph[weights, ofEdgeAt: p] = stamp
                        weightModel[e] = stamp
                        if operation == 6 {
                            graph[labels, ofEdgeAt: p] = "s\(stamp)"
                            labelModel[e] = "s\(stamp)"
                        } else {
                            graph[labels, ofEdgeAt: p] = nil
                            labelModel[e] = nil
                        }
                    }
                case 7:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(stamp)
                        rankModel[a] = Double(stamp)
                    }
                case 8:
                    if a == 0 {
                        graph.removeAllEdges(keepingCapacity: b.isMultiple(of: 2))
                        weightModel = [:]
                        labelModel = [:]
                    } else if a == 1, b == 0 {
                        graph.removeAll(keepingCapacity: true)
                        weightModel = [:]
                        labelModel = [:]
                        rankModel = [:]
                    } else {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    }
                default:
                    // A copy mutated in place of the graph must leave the graph's values alone.
                    var copy = graph
                    if copy.edgeCount > 0 { copy[weights, ofEdgeAt: 0] = -99 }
                    copy.remove(a)
                    copy.insert(edge: edge)
                }

                #expect(graph.edgeCount == weightModel.count, "step \(step)")
                #expect(graph.vertexCount == rankModel.count, "step \(step)")
                let weightValues = graph.values(of: weights)
                let labelValues = graph.values(of: labels)
                for p in 0 ..< graph.edgeCount {
                    let e = graph.edges[p]
                    #expect(graph[weights, ofEdgeAt: p] == weightModel[e], "step \(step): weight of \(e)")
                    #expect(weightValues[p] == weightModel[e], "step \(step): values(of:) weight of \(e)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[e], "step \(step): label of \(e)")
                    #expect(labelValues[p] == labelModel[e], "step \(step): values(of:) label of \(e)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    #expect(graph[ranks, of: v] == rankModel[v], "step \(step): rank of \(v)")
                    #expect(rankValues[graph.vertexIndex(of: v)] == rankModel[v], "step \(step): values(of:) rank of \(v)")
                }
                #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
            }
        }
    }

    @Test("AM-12 UndirectedAdjacencyList: every value follows its element through random mutations")
    func undirected() async {
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = UndirectedAdjacencyList<Int>()
            let weights = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            // UndirectedEdge hashes and compares without orientation.
            var weightModel: [UndirectedEdge<Int>: Int] = [:]
            var labelModel: [UndirectedEdge<Int>: String] = [:]
            var rankModel: [Int: Double] = [:]
            var stamp = 0
            for (step, (operation, a, b)) in operations.enumerated() {
                let edge = UndirectedEdge(a, b)
                stamp += 1
                switch operation {
                case 0:
                    if graph.insert(a).inserted { rankModel[a] = 0.5 }
                case 1, 2:
                    if graph.insert(edge: edge).inserted {
                        weightModel[edge] = -1
                        for v in [a, b] where rankModel[v] == nil { rankModel[v] = 0.5 }
                    }
                case 3:
                    if graph.remove(edge: edge) != nil {
                        weightModel[edge] = nil
                        labelModel[edge] = nil
                    }
                case 4:
                    if graph.remove(a) != nil {
                        rankModel[a] = nil
                        for e in weightModel.keys where e.u == a || e.v == a {
                            weightModel[e] = nil
                            labelModel[e] = nil
                        }
                    }
                case 5, 6:
                    if graph.edgeCount > 0 {
                        let p = (a * 6 + b) % graph.edgeCount
                        let e = graph.edges[p]
                        graph[weights, ofEdgeAt: p] = stamp
                        weightModel[e] = stamp
                        if operation == 6 {
                            graph[labels, ofEdgeAt: p] = "s\(stamp)"
                            labelModel[e] = "s\(stamp)"
                        } else {
                            graph[labels, ofEdgeAt: p] = nil
                            labelModel[e] = nil
                        }
                    }
                case 7:
                    if graph.contains(a) {
                        graph[ranks, of: a] = Double(stamp)
                        rankModel[a] = Double(stamp)
                    }
                case 8:
                    if a == 0 {
                        graph.removeAllEdges(keepingCapacity: b.isMultiple(of: 2))
                        weightModel = [:]
                        labelModel = [:]
                    } else if a == 1, b == 0 {
                        graph.removeAll(keepingCapacity: true)
                        weightModel = [:]
                        labelModel = [:]
                        rankModel = [:]
                    } else {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    }
                default:
                    var copy = graph
                    if copy.edgeCount > 0 { copy[weights, ofEdgeAt: 0] = -99 }
                    copy.remove(a)
                    copy.insert(edge: edge)
                }

                #expect(graph.edgeCount == weightModel.count, "step \(step)")
                #expect(graph.vertexCount == rankModel.count, "step \(step)")
                let weightValues = graph.values(of: weights)
                let labelValues = graph.values(of: labels)
                for p in 0 ..< graph.edgeCount {
                    let e = graph.edges[p]
                    #expect(graph[weights, ofEdgeAt: p] == weightModel[e], "step \(step): weight of \(e)")
                    #expect(weightValues[p] == weightModel[e], "step \(step): values(of:) weight of \(e)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[e], "step \(step): label of \(e)")
                    #expect(labelValues[p] == labelModel[e], "step \(step): values(of:) label of \(e)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    #expect(graph[ranks, of: v] == rankModel[v], "step \(step): rank of \(v)")
                    #expect(rankValues[graph.vertexIndex(of: v)] == rankModel[v], "step \(step): values(of:) rank of \(v)")
                }
                #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
            }
        }
    }
}
