// Attached maps against a model, with shrinking (swift-property-based): a random sequence of vertex
// insertions on either side, edge insertions (plain and `checked:`, across, inside a side or with a
// missing endpoint), removals (by edge, by vertex), clears and value writes runs on a BipartiteGraph
// with an edge map, an Optional edge map and a vertex map, and on a model that keys each value by its
// edge (the graph is simple, so its left and right ends name it) or by its vertex (Dictionaries),
// with each vertex's side. A mutation that throws `BipartitionError` must change nothing. After every
// step, the value at every position and every vertex must be the model's, through the subscripts and
// `values(of:)`, the sides must be the model's, every edge must be stored left end first, and the
// position past the last must throw. On a failure, PropertyBased prints the smallest failing
// sequence.

import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

@Suite("BipartiteGraph attached maps against a model", .tags(.randomized))
struct BipartiteGraphMapPropertyTests {
    @Test("every value follows its edge or vertex, and the sides hold, through random mutations")
    func model() async {
        // (operation, a, b, c): a and b name vertices 0...6, c a side, a position or a value.
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 99)).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = BipartiteGraph<Int>()
            let weights = graph.addEdgeMap(default: -1)
            let labels = graph.addEdgeMap(of: String.self)
            let ranks = graph.addVertexMap(default: 0.5)
            var sides: [Int: BipartiteSide] = [:]
            // Live edges, keyed by left end * 10 + right end; an absent value is the default.
            var edges: Set<Int> = []
            var weightModel: [Int: Int] = [:]
            var labelModel: [Int: String] = [:]
            var rankModel: [Int: Double] = [:]
            func key(_ e: UndirectedEdge<Int>) -> Int { sides[e.u] == .left ? e.u * 10 + e.v : e.v * 10 + e.u }
            func forget(_ keys: [Int]) {
                for k in keys {
                    edges.remove(k)
                    weightModel[k] = nil
                    labelModel[k] = nil
                }
            }
            for (step, (operation, a, b, c)) in operations.enumerated() {
                let edge = UndirectedEdge(a, b)
                let before = graph
                switch operation {
                case 0:
                    let side: BipartiteSide = c.isMultiple(of: 2) ? .left : .right
                    if let existing = sides[a], existing != side {
                        #expect(throws: BipartitionError.onOtherSide(existing)) { try graph.insert(a, on: side) }
                        #expect(graph == before, "step \(step)")
                    } else {
                        #expect(try graph.insert(a, on: side).inserted == (sides[a] == nil), "step \(step)")
                        sides[a] = side
                    }
                case 1, 2:
                    guard let su = sides[a], let sv = sides[b] else {
                        if operation == 2 {
                            #expect(throws: BipartitionError.missingEndpoint) { try graph.insert(checked: edge) }
                        }
                        break
                    }
                    if su == sv {
                        #expect(throws: BipartitionError.sameSide(su)) {
                            if operation == 1 { try graph.insert(edge: edge) } else { try graph.insert(checked: edge) }
                        }
                        #expect(graph == before, "step \(step)")
                    } else {
                        let result = operation == 1 ? try graph.insert(edge: edge) : try graph.insert(checked: edge)
                        #expect(result.inserted == !edges.contains(key(edge)), "step \(step)")
                        #expect(sides[result.memberAfterInsert.u] == .left, "step \(step)")
                        edges.insert(key(edge))
                    }
                case 3:
                    let present = sides[a] != nil && sides[b] != nil && sides[a] != sides[b] && edges.contains(key(edge))
                    #expect((graph.remove(edge: edge) != nil) == present, "step \(step)")
                    if present { forget([key(edge)]) }
                case 4:
                    #expect((graph.remove(a) != nil) == (sides[a] != nil), "step \(step)")
                    if sides[a] != nil {
                        forget(edges.filter { $0 / 10 == a || $0 % 10 == a })
                        sides[a] = nil
                        rankModel[a] = nil
                    }
                case 5, 6:
                    if graph.edgeCount > 0 {
                        let p = c % graph.edgeCount
                        let k = key(graph.edges[p])
                        graph[weights, ofEdgeAt: p] = c
                        weightModel[k] = c
                        graph[labels, ofEdgeAt: p] = operation == 5 ? "s\(c)" : nil
                        labelModel[k] = operation == 5 ? "s\(c)" : nil
                    }
                case 7:
                    if sides[a] != nil {
                        graph[ranks, of: a] = Double(c)
                        rankModel[a] = Double(c)
                    }
                case 8:
                    if graph.vertexCount > 0 {
                        let slot = c % graph.vertexCount
                        graph[ranks, ofVertexAt: slot] = Double(-c)
                        rankModel[graph.vertex(atIndex: slot)] = Double(-c)
                    }
                default:
                    if c < 10 {
                        graph.removeAll(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(edges))
                        sides = [:]
                        rankModel = [:]
                    } else if c < 30 {
                        graph.removeAllEdges(keepingCapacity: c.isMultiple(of: 2))
                        forget(Array(edges))
                    } else if c < 50 {
                        graph.reserveCapacity(vertexCount: a * 4, edgeCount: b * 4)
                    } else {
                        // A copy mutated in place of the graph leaves the graph's values alone.
                        var copy = graph
                        if copy.edgeCount > 0 { copy[weights, ofEdgeAt: 0] = -99 }
                        if copy.vertexCount > 0 { copy[ranks, ofVertexAt: 0] = -99 }
                        copy.remove(a)
                        _ = try? copy.insert(b, on: .right)
                    }
                }

                #expect(graph.edgeCount == edges.count, "step \(step)")
                #expect(Set(graph.left) == Set(sides.filter { $0.value == .left }.keys), "step \(step): left")
                #expect(Set(graph.right) == Set(sides.filter { $0.value == .right }.keys), "step \(step): right")
                let weightValues = graph.values(of: weights)
                let labelValues = graph.values(of: labels)
                for p in 0 ..< graph.edgeCount {
                    let e = graph.edges[p]
                    #expect(graph.side(of: e.u) == .left && graph.side(of: e.v) == .right, "step \(step): edge \(p) left end first")
                    let k = key(e)
                    #expect(edges.contains(k), "step \(step): edge \(p)")
                    #expect(graph[weights, ofEdgeAt: p] == weightModel[k] ?? -1, "step \(step): weight at \(p)")
                    #expect(weightValues[p] == weightModel[k] ?? -1, "step \(step): values(of:) weight at \(p)")
                    #expect(graph[labels, ofEdgeAt: p] == labelModel[k], "step \(step): label at \(p)")
                    #expect(labelValues[p] == labelModel[k], "step \(step): values(of:) label at \(p)")
                }
                let rankValues = graph.values(of: ranks)
                for v in graph.vertices {
                    let slot = graph.vertexIndex(of: v)
                    #expect(graph[ranks, of: v] == rankModel[v] ?? 0.5, "step \(step): rank of \(v)")
                    #expect(graph[ranks, ofVertexAt: slot] == rankModel[v] ?? 0.5, "step \(step): rank at \(v)'s slot")
                    #expect(rankValues[slot] == rankModel[v] ?? 0.5, "step \(step): values(of:) rank of \(v)")
                }
                #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: graph.edgeCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checkedVertexAt: graph.vertexCount] }
                #expect(throws: VertexNotFound.self) { try graph[ranks, checked: 7] }
            }
        }
    }
}
