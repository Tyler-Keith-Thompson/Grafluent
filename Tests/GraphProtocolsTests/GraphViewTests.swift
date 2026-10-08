// The views between the two protocols, `directed` (each edge as two opposite arcs) and
// `undirected` (each arc as an edge), and conversions through them. Expected values come from
// NetworkX `to_directed` / `to_undirected` and JGraphT `AsUndirectedGraph`. Case IDs (UG-Cnn)
// refer to the catalog in README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Views between Graph and DirectedGraph")
struct GraphViewTests {
    @Test("UG-C01 the directed view satisfies the DirectedGraph laws, with every edge as two arcs", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func directedViewLaws(_ fixture: UndirectedFixture<Int>) {
        func check<B: Graph>(_ base: B) {
            func laws<D: DirectedGraph<B.Vertex>>(_ g: D) {
                #expect(g.vertexCount == base.vertexCount)
                #expect(g.edgeCount == 2 * base.edgeCount)
                #expect(Array(g.edges).count == g.edgeCount)
                // Collection: indices strictly increase, so an edge and its reverse are ordered.
                let indices = Array(g.edges.indices)
                #expect(zip(indices, indices.dropFirst()).allSatisfy { $0 < $1 })
                var seen = Set<D.Edges.Index>()
                var outSum = 0
                for v in g.vertices {
                    let outEdges = Array(g.outEdges(of: v))
                    #expect(g.outDegree(of: v) == base.degree(of: v))
                    #expect(Array(g.successors(of: v)) == Array(base.neighbors(of: v)))
                    // DG-L19 – L21: out-edges leave v, their targets are the successors, every arc once.
                    #expect(outEdges.map { g.target(ofEdgeAt: $0) } == Array(g.successors(of: v)))
                    for e in outEdges {
                        #expect(g.source(ofEdgeAt: e) == v)
                        #expect(g.edges[e].source == v)
                        #expect(seen.insert(e).inserted)
                    }
                    outSum += g.outDegree(of: v)
                    for w in g.vertices {
                        let forward = g.contains(edge: DirectedEdge(from: v, to: w))
                        #expect(forward == g.contains(edge: DirectedEdge(from: w, to: v)))
                        #expect(forward == base.contains(edge: UndirectedEdge(v, w)))
                    }
                }
                #expect(outSum == g.edgeCount)
                #expect(seen == Set(g.edges.indices))
                if let n = g.vertexIndexBound {
                    #expect(n == base.vertexIndexBound)
                    for i in 0 ..< n {
                        #expect(Array(g.successorIndices(ofIndex: i)) == Array(base.neighborIndices(ofIndex: i)))
                    }
                }
            }
            laws(base.directed)
            // Every arc is its base edge or that edge reversed, and each base edge gives both.
            var arcs: [UndirectedEdge<B.Vertex>: [DirectedEdge<B.Vertex>]] = [:]
            for arc in base.directed.edges { arcs[UndirectedEdge(arc.source, arc.target), default: []].append(arc) }
            var expected: [UndirectedEdge<B.Vertex>: [DirectedEdge<B.Vertex>]] = [:]
            for e in base.edges {
                expected[e, default: []] += [DirectedEdge(from: e.u, to: e.v), DirectedEdge(from: e.v, to: e.u)]
            }
            #expect(arcs.mapValues { $0.count } == expected.mapValues { $0.count })
            for (key, list) in arcs {
                #expect(Set(list) == Set(expected[key]!))
            }
        }
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-C02 the directed view of a loop and a path, exactly", .tags(.selfLoops))
    func directedViewExact() {
        let graph = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.loopAndPath.edges)
        func arcs<D: DirectedGraph<Int>>(_ g: D) -> [DirectedEdge<Int>] { Array(g.edges) }
        func count<D: DirectedGraph<Int>>(_ g: D) -> Int { g.edgeCount }
        #expect(arcs(graph.directed) == [
            DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1),
            DirectedEdge(from: 1, to: 0), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1),
        ])
        #expect(count(graph.directed) == 6)
        // Materialized, the two loop arcs collapse: NetworkX to_directed() has 5 arcs.
        let collapsed = AdjacencyList(graph.directed)
        #expect(collapsed.edgeCount == 5)
        #expect(Set(collapsed.edges) == [
            DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0),
            DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 1),
        ])
    }

    @Test("UG-C03 the directed view is bidirectional, and its strong components are the connected components", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func directedViewIsBidirectional(_ fixture: UndirectedFixture<Int>) {
        func check<B: Graph>(_ base: B) {
            func bidirectional<D: BidirectionalDirectedGraph<B.Vertex>>(_ g: D) {
                var seen = Set<D.Edges.Index>()
                for v in g.vertices {
                    #expect(Array(g.predecessors(of: v)) == Array(base.neighbors(of: v)))
                    #expect(g.inDegree(of: v) == base.degree(of: v))
                    #expect(g.degree(of: v) == 2 * base.degree(of: v))
                    let inEdges = Array(g.inEdges(of: v))
                    #expect(inEdges.map { g.source(ofEdgeAt: $0) } == Array(g.predecessors(of: v)))
                    for e in inEdges {
                        #expect(g.target(ofEdgeAt: e) == v)
                        #expect(seen.insert(e).inserted)
                    }
                }
                #expect(seen == Set(g.edges.indices))
            }
            bidirectional(base.directed)
        }
        check(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges))
        check(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("UG-C03 Kosaraju's algorithm on the directed view finds the connected components")
    func kosarajuThroughView() {
        func strongComponents<G: BidirectionalDirectedGraph>(_ g: G) -> Set<Set<G.Vertex>> {
            var seen = Set<G.Vertex>()
            var finished: [G.Vertex] = []
            func forward(_ v: G.Vertex) {
                seen.insert(v)
                for w in g.successors(of: v) where !seen.contains(w) { forward(w) }
                finished.append(v)
            }
            for v in g.vertices where !seen.contains(v) { forward(v) }
            var assigned = Set<G.Vertex>()
            var result = Set<Set<G.Vertex>>()
            for v in finished.reversed() where !assigned.contains(v) {
                var component: Set = [v]
                assigned.insert(v)
                var stack = [v]
                while let x = stack.popLast() {
                    for w in g.predecessors(of: x) where assigned.insert(w).inserted {
                        component.insert(w)
                        stack.append(w)
                    }
                }
                result.insert(component)
            }
            return result
        }
        let seven = UndirectedFixture<Int>.components7
        #expect(strongComponents(UndirectedAdjacencyList(vertices: seven.vertices, edges: seven.edges).directed) == [[0, 1, 2], [3, 4], [5], [6]])
        #expect(strongComponents(ReferencePseudograph(vertices: seven.vertices, edges: seven.edges).directed) == [[0, 1, 2], [3, 4], [5], [6]])
        #expect(strongComponents(UndirectedAdjacencyList(edges: UndirectedFixture<Int>.petersen.edges).directed).count == 1)
        #expect(strongComponents(UndirectedAdjacencyList(edges: UndirectedFixture<Int>.karate.edges).directed).count == 1)
    }

    @Test("UG-C04 Traversal's breadth-first search runs on an undirected graph through the directed view")
    func traversalThroughView() {
        var distance: [Int: Int] = [0: 0]
        for case .treeEdge(let arc) in UndirectedAdjacencyList(edges: UndirectedFixture<Int>.petersen.edges).directed.breadthFirstSearch(from: 0) {
            distance[arc.target] = distance[arc.source]! + 1
        }
        #expect(distance == [0: 0, 1: 1, 4: 1, 5: 1, 2: 2, 3: 2, 6: 2, 7: 2, 8: 2, 9: 2])
        let layers = UndirectedAdjacencyList(edges: UndirectedFixture<Int>.cube.edges).directed.breadthFirstLayers(from: 0)
        #expect(layers.map { Set($0) } == [[0], [1, 2, 4], [3, 5, 6], [7]])
    }

    @Test("UG-C05 the undirected view of a directed graph")
    func undirectedView() {
        let view = AdjacencyList(edges: DirectedFixture<Int>.house.edges).undirected
        func degrees<G: Graph<Int>>(_ g: G) -> [Int: Int] {
            Dictionary(uniqueKeysWithValues: g.vertices.map { ($0, g.degree(of: $0)) })
        }
        func distances<G: Graph<Int>>(_ g: G, from source: Int) -> [Int: Int] {
            var distance = [source: 0]
            var queue = [source]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in g.neighbors(of: v) where distance[w] == nil {
                    distance[w] = distance[v]! + 1
                    queue.append(w)
                }
            }
            return distance
        }
        // NetworkX DiGraph(house).to_undirected().
        #expect(degrees(view) == [0: 2, 1: 3, 2: 2, 3: 3, 4: 3, 5: 1])
        #expect(distances(view, from: 5) == [5: 0, 3: 1, 2: 2, 4: 2, 0: 3, 1: 3])
        #expect(distances(view, from: 5).count == view.vertexCount)
        // The view satisfies the Graph laws: neighbors are the opposite ends of the incident edges.
        func laws<G: Graph>(_ g: G) {
            var degreeSum = 0
            var positionCounts: [G.Edges.Index: Int] = [:]
            for v in g.vertices {
                #expect(g.incidentEdges(of: v).map { g.oppositeVertex(to: v, acrossEdgeAt: $0) } == Array(g.neighbors(of: v)))
                #expect(g.degree(of: v) == Array(g.neighbors(of: v)).count)
                for e in g.incidentEdges(of: v) { positionCounts[e, default: 0] += 1 }
                degreeSum += g.degree(of: v)
                if let n = g.vertexIndexBound {
                    #expect(g.vertexIndex(of: v) < n)
                    #expect(Array(g.neighborIndices(ofIndex: g.vertexIndex(of: v))) == g.neighbors(of: v).map { g.vertexIndex(of: $0) })
                }
            }
            #expect(degreeSum == 2 * g.edgeCount)
            #expect(Set(positionCounts.keys) == Set(g.edges.indices))
            #expect(positionCounts.values.allSatisfy { $0 == 2 })
        }
        laws(view)
        #expect(view.contains(edge: UndirectedEdge(3, 5)))
        #expect(view.contains(edge: UndirectedEdge(5, 3)))
        #expect(!view.contains(edge: UndirectedEdge(5, 0)))
        #expect(!view.contains(edge: UndirectedEdge(5, -1)))
    }

    @Test("UG-C06 reciprocal arcs stay parallel edges in the view, and collapse when converted")
    func reciprocalArcs() {
        func summary<G: Graph<Int>>(_ g: G) -> (edges: Int, degree: [Int: Int]) {
            (g.edgeCount, Dictionary(uniqueKeysWithValues: g.vertices.map { ($0, g.degree(of: $0)) }))
        }
        let view = AdjacencyList(edges: DirectedFixture<Int>.triangleWithReciprocalEdge.edges).undirected
        // JGraphT AsUndirectedGraph: a multigraph.
        #expect(summary(view).edges == 4)
        #expect(summary(view).degree == [1: 3, 2: 3, 3: 2])
        #expect(Array(view.neighbors(of: 1)).filter { $0 == 2 }.count == 2)
        // NetworkX to_undirected: a simple graph.
        let collapsed = UndirectedAdjacencyList(view)
        #expect(summary(collapsed).edges == 3)
        #expect(summary(collapsed).degree == [1: 2, 2: 2, 3: 2])
    }

    @Test("UG-C07 a directed loop is a loop of degree 2 in the view", .tags(.selfLoops))
    func directedLoops() {
        let base = AdjacencyList(edges: DirectedFixture<Int>.selfLoopsAndDuplicates.edges)
        let view = base.undirected
        func degrees<G: Graph<Int>>(_ g: G) -> [Int: Int] {
            Dictionary(uniqueKeysWithValues: g.vertices.map { ($0, g.degree(of: $0)) })
        }
        #expect(degrees(view) == [1: 1, 2: 4, 3: 1, 4: 3, 5: 3])
        for v in base.vertices { #expect(view.degree(of: v) == base.degree(of: v)) }
        #expect(Array(view.neighbors(of: 4)).filter { $0 == 4 }.count == 2)
        #expect(degrees(view).values.reduce(0, +) == 12)
        #expect(view.edgeCount == 6)
    }

    @Test("UG-C08 the undirected view keeps the base's edge positions, so a weight reads the same from both ends")
    func viewPositions() {
        func positionType<G: Graph>(_: G) -> Any.Type { G.Edges.Index.self }
        let base = AdjacencyList(edges: DirectedFixture<Int>.house.edges)
        let view = base.undirected
        #expect(ObjectIdentifier(positionType(view)) == ObjectIdentifier(AdjacencyList<Int>.Edges.Index.self))
        var weight: [AdjacencyList<Int>.Edges.Index: Int] = [:]
        for (k, e) in base.edges.indices.enumerated() { weight[e] = 10 * (k + 1) }
        func weights<G: Graph>(_ g: G, at v: G.Vertex, keyedBy key: (G.Edges.Index) -> Int) -> [G.Vertex: Int] {
            var result: [G.Vertex: Int] = [:]
            for e in g.incidentEdges(of: v) { result[g.oppositeVertex(to: v, acrossEdgeAt: e)] = key(e) }
            return result
        }
        for arc in base.edges.indices {
            let edge = base.edges[arc]
            #expect(weights(view, at: edge.source) { weight[$0]! }[edge.target] == weight[arc])
            #expect(weights(view, at: edge.target) { weight[$0]! }[edge.source] == weight[arc])
        }
    }

    @Test("UG-C09 round trips through both views give back the graph", .tags(.fixture), arguments: UndirectedFixture<Int>.all)
    func roundTrips(_ fixture: UndirectedFixture<Int>) {
        let graph = UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)
        #expect(UndirectedAdjacencyList(AdjacencyList(graph.directed).undirected) == graph)
        #expect(UndirectedAdjacencyList(graph) == graph)
        #expect(UndirectedAdjacencyList(graph.directed.undirected) == graph)
        #expect(AdjacencyList(graph.directed).edgeCount == 2 * graph.edgeCount - graph.edges.filter(\.isSelfLoop).count)
    }

    @Test("UG-C10 converting a pseudograph collapses parallel edges and keeps loops")
    func fromPseudograph() {
        let fixture = UndirectedFixture<Int>.petgraphUndirected
        let converted = UndirectedAdjacencyList(ReferencePseudograph(edges: fixture.edges))
        #expect(converted.edgeCount == 5)
        #expect(converted.contains(edge: UndirectedEdge(0, 0)))
        #expect(converted == UndirectedAdjacencyList(edges: fixture.edges))
        let strings = UndirectedFixture<String>.networkXABCD
        #expect(UndirectedAdjacencyList(ReferencePseudograph(vertices: strings.vertices, edges: strings.edges)).vertexCount == 7)
        #expect(UndirectedAdjacencyList(ReferencePseudograph(edges: strings.edges)).vertexCount == 4)
    }

    @Test("UG-C11 a compressed sparse row graph becomes undirected by mapping its edges")
    func fromCompressedSparseRow() {
        let house = DirectedFixture<Int>.house
        let sparse = CompressedSparseRow(vertexCount: house.vertexCount, edges: house.edges)
        let mapped = UndirectedAdjacencyList(vertices: sparse.vertices, edges: sparse.edges.map { UndirectedEdge($0.source, $0.target) })
        #expect(mapped == UndirectedAdjacencyList(AdjacencyList(edges: house.edges).undirected))
        #expect(mapped.edgeCount == 7)
        #expect(Set(mapped.neighbors(of: 2)) == [1, 3])
    }
}
