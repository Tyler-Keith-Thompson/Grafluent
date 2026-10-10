// `BipartiteGraph` properties against oracles written inside each test, with shrinking
// (swift-property-based). Random operation sequences run against a model kept beside the graph (a
// side per vertex and a set of edges), with each call's result, the vertex and edge sets, the sides,
// left-endpoint-first storage, the index-space rows and equality with a graph rebuilt from the model
// checked after every step, then Codable and the initializers from a graph at the end. Projections
// of random bipartite graphs, after random removals, are checked against the definition (two side
// vertices joined iff they share a neighbour) and against api.md's discovery order written out
// over the graph's public rows. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import Foundation
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

@Suite("BipartiteGraph properties against a model, with shrinking", .tags(.randomized))
struct BipartiteGraphPropertyTests {
    @Test("Random operation sequences agree with a model: a side per vertex and a set of edges")
    func mutationAgainstModel() async {
        // (kind, a, b, on the left)
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.bool).array(of: 0 ... 60)
        await propertyCheck(count: 300, input: operations) { operations in
            var graph = BipartiteGraph<Int>()
            var sides: [Int: BipartiteSide] = [:]
            var edges: Set<UndirectedEdge<Int>> = []
            for (step, (kind, a, b, onLeft)) in operations.enumerated() {
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0, 1, 2:
                    // Insert a vertex, on its own side when it already has one (the other side traps).
                    let side: BipartiteSide = sides[a] ?? (onLeft ? .left : .right)
                    let result = graph.insert(a, on: side)
                    #expect(result.inserted == (sides[a] == nil), "\(context)")
                    #expect(result.memberAfterInsert == a)
                    sides[a] = side
                case 3, 4, 5:
                    // Insert an edge when it is legal; otherwise ask for it.
                    if let sa = sides[a], let sb = sides[b], sa != sb {
                        let result = graph.insert(edge: UndirectedEdge(a, b))
                        #expect(result.inserted == !edges.contains(UndirectedEdge(a, b)), "\(context)")
                        let leftEnd = sa == .left ? a : b
                        #expect(result.memberAfterInsert.u == leftEnd, "\(context)")
                        #expect(result.memberAfterInsert == UndirectedEdge(a, b))
                        edges.insert(UndirectedEdge(a, b))
                    } else {
                        #expect(graph.contains(edge: UndirectedEdge(a, b)) == false)
                    }
                case 6, 7:
                    let removed = graph.remove(edge: UndirectedEdge(a, b))
                    if edges.remove(UndirectedEdge(a, b)) != nil {
                        #expect(removed == UndirectedEdge(a, b), "\(context)")
                        #expect(removed.map { graph.side(of: $0.u) } == .left)
                    } else {
                        #expect(removed == nil, "\(context)")
                    }
                case 8:
                    let removed = graph.remove(a)
                    #expect(removed == (sides[a] == nil ? nil : a), "\(context)")
                    sides[a] = nil
                    edges = edges.filter { $0.u != a && $0.v != a }
                default:
                    if a == 0 && b == 0 {
                        graph.removeAllEdges(keepingCapacity: onLeft)
                        edges = []
                    } else if a == 0 && b == 1 && !onLeft {
                        graph.removeAll()
                        sides = [:]
                        edges = []
                    } else if let side = sides[a] {
                        #expect(graph.side(of: a) == side, "\(context)")
                    }
                }

                // The state, after every step.
                let vertices = Array(graph.vertices)
                #expect(Set(vertices) == Set(sides.keys), "\(context)")
                #expect(vertices.count == sides.count)
                #expect(Set(graph.left) == Set(sides.filter { $0.value == .left }.keys), "\(context)")
                #expect(Set(graph.right) == Set(sides.filter { $0.value == .right }.keys), "\(context)")
                #expect(graph.left.count + graph.right.count == graph.vertexCount)
                #expect(Set(graph.edges) == edges, "\(context)")
                #expect(graph.edgeCount == edges.count)
                for (v, side) in sides { #expect(graph.side(of: v) == side, "\(v) at \(context)") }
                for edge in graph.edges {
                    #expect(graph.side(of: edge.u) == .left && graph.side(of: edge.v) == .right, "\(edge) at \(context)")
                }
                var degreeSum = 0
                for (i, v) in vertices.enumerated() {
                    #expect(graph.vertexIndex(of: v) == i)
                    let row = Array(graph.incidentEdges(ofIndex: i))
                    #expect(row.allSatisfy { graph.edges[$0].u == v || graph.edges[$0].v == v })
                    #expect(Array(graph.neighborIndices(ofIndex: i)) == row.map { graph.vertexIndex(of: graph.edges[$0].oppositeVertex(to: v)) })
                    #expect(Set(graph.neighbors(of: v)) == Set(edges.filter { $0.u == v || $0.v == v }.map { $0.oppositeVertex(to: v) }))
                    degreeSum += row.count
                }
                #expect(degreeSum == 2 * graph.edgeCount)
                let rebuilt = BipartiteGraph(left: sides.filter { $0.value == .left }.keys, right: sides.filter { $0.value == .right }.keys, edges: edges)
                #expect(rebuilt == graph, "\(context)")
                #expect(rebuilt?.hashValue == graph.hashValue)
            }

            // At the end: Codable, and back through the initializers from a graph.
            do {
                let decoded = try JSONDecoder().decode(BipartiteGraph<Int>.self, from: JSONEncoder().encode(graph))
                #expect(decoded == graph)
                #expect(Array(decoded.left) == Array(graph.left))
                #expect(Array(decoded.right) == Array(graph.right))
                #expect(decoded.edges.map { [$0.u, $0.v] } == graph.edges.map { [$0.u, $0.v] })
            } catch {
                Issue.record("round trip: \(error)")
            }
            let list = UndirectedAdjacencyList(graph)
            #expect(BipartiteGraph(list, left: Array(graph.left)) == graph)
            #expect(BipartiteGraph(graph, left: graph.left) == graph)
            let canonical = BipartiteGraph(list)
            #expect(canonical != nil)
            #expect(canonical.map { Array($0.vertices) } == Array(graph.vertices))
            #expect(canonical.map { Array($0.edges) } == Array(graph.edges))
            #expect(graph.isBipartite)
        }
    }

    @Test("projectedGraph(onto:) agrees with the definition and with api.md's discovery order, after random removals")
    func projectionAgainstDefinition() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 1_000_000)) { raw, leftCount, rightCount, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // Left vertices 0..<leftCount, right ones 100..<100 + rightCount.
            let left = Array(0 ..< leftCount)
            let right = Array(100 ..< 100 + rightCount)
            let pairs = leftCount == 0 || rightCount == 0 ? [] : raw.map { (left[$0.0 % leftCount], right[$0.1 % rightCount]) }
            guard var graph = BipartiteGraph(left: left, right: right, edges: pairs.map { Bool.random(using: &rng) ? UndirectedEdge($0.0, $0.1) : UndirectedEdge($0.1, $0.0) }) else {
                Issue.record("not built: \(pairs)")
                return
            }
            // A few removals, so rows, slots and side orders are no longer the insertion orders.
            for _ in 0 ..< Int.random(in: 0 ... 3, using: &rng) {
                if Bool.random(using: &rng), let v = Array(graph.vertices).randomElement(using: &rng) {
                    graph.remove(v)
                } else if let e = Array(graph.edges).randomElement(using: &rng) {
                    graph.remove(edge: e)
                }
            }
            for side in BipartiteSide.allCases {
                let members = side == .left ? Array(graph.left) : Array(graph.right)
                let projection = graph.projectedGraph(onto: side)
                #expect(Array(projection.vertices) == members, "\(side) of \(graph)")
                // The definition: u ≠ x on the side, joined iff they share a neighbour.
                var expected: Set<UndirectedEdge<Int>> = []
                for (i, u) in members.enumerated() {
                    for x in members[(i + 1)...] where !Set(graph.neighbors(of: u)).isDisjoint(with: graph.neighbors(of: x)) {
                        expected.insert(UndirectedEdge(u, x))
                    }
                }
                #expect(Set(projection.edges) == expected, "\(side) of \(graph)")
                #expect(projection.edgeCount == expected.count)
                // The documented order: for each u in side order, each neighbour w in u's row, each x ≠ u
                // in w's row, {u, x} the first time it is met.
                var order: [[Int]] = []
                var met: Set<UndirectedEdge<Int>> = []
                for u in members {
                    for w in graph.neighbors(of: u) {
                        for x in graph.neighbors(of: w) where x != u && met.insert(UndirectedEdge(u, x)).inserted {
                            order.append([u, x])
                        }
                    }
                }
                #expect(projection.edges.map { [$0.u, $0.v] } == order, "\(side) of \(graph)")
            }
        }
    }
}
