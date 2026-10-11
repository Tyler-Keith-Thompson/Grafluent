// Graph algorithms reach a hypergraph through its incidence graph. On seeded random hypergraphs,
// with empty and repeated hyperedges, every algorithm run on `incidenceGraph` must equal the same
// algorithm on the view copied into an adjacency list (`UndirectedAdjacencyList<Int>` or
// `AdjacencyList<Int>`, built from the view's own vertices and edges in order, so positions and
// row orders agree). The hypergraph algorithms are checked against the components of that view.
// Then the protocols' defaults through a minimal test-local conformer, Codable round trips,
// copy-on-write, the resets, `init(_:)` across conformers and from a directed graph, and Sendable.
// See README.md.

import AdjacencyListModule
import BipartiteGraphs
import Connectivity
import Cycles
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Hypergraphs
import ShortestPaths
import SpanningTrees
import Testing
import Traversal

@Suite("Hypergraphs conformances and algorithms on the incidence graph", .tags(.conformance))
struct HypergraphConformanceTests {
    @Test("Undirected: algorithms on incidenceGraph equal the same on an UndirectedAdjacencyList copy", arguments: 1 ... 8)
    func undirectedViewAgainstCopy(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let names = (0 ..< 6 + seed * 2).map { "v\($0)" }
        var hypergraph = UndirectedIncidenceList<String>(vertices: names.shuffled(using: &rng).prefix(seed))
        for _ in 0 ..< 4 + seed * 2 {
            let size = [0, 1, 2, 2, 3, 3, 4, 5].randomElement(using: &rng)!
            hypergraph.insert(hyperedge: (0 ..< size).map { _ in names.randomElement(using: &rng)! })
        }
        if seed.isMultiple(of: 2) { hypergraph.insert(hyperedge: Array(hypergraph.members(ofHyperedgeAt: 0))) }
        let view = hypergraph.incidenceGraph
        let n = hypergraph.vertexCount, m = hypergraph.hyperedgeCount
        let copy = UndirectedAdjacencyList<Int>(vertices: view.vertices, edges: view.edges)
        #expect(view.vertexCount == n + m && copy.vertexCount == n + m)
        #expect(Array(view.edges) == Array(copy.edges) && view.edgeCount == (0 ..< m).reduce(0) { $0 + hypergraph.size(ofHyperedgeAt: $1) })
        for x in view.vertices {
            #expect(Array(view.neighbors(of: x)) == Array(copy.neighbors(of: x)))
            #expect(Array(view.incidentEdges(of: x)) == Array(copy.incidentEdges(of: x)))
            #expect(view.degree(of: x) == copy.degree(of: x))
            #expect(Array(view.neighborIndices(ofIndex: x)) == Array(copy.neighborIndices(ofIndex: x)))
            #expect(Array(view.incidentEdgeIndices(ofIndex: x)) == Array(copy.incidentEdgeIndices(ofIndex: x)))
        }
        // The two sides of the view are the hypergraph's rows.
        for i in 0 ..< n { #expect(Array(view.neighbors(of: i)) == hypergraph.incidentHyperedges(ofIndex: i).map { n + $0 }) }
        for p in 0 ..< m { #expect(Array(view.neighbors(of: n + p)) == Array(hypergraph.memberIndices(ofHyperedgeAt: p))) }
        // Connectivity.
        #expect(view.connectedComponents().map { Array($0) } == copy.connectedComponents().map { Array($0) })
        #expect(view.isConnected == copy.isConnected)
        #expect(view.bridges() == copy.bridges())
        #expect(view.articulationPoints() == copy.articulationPoints())
        // Traversal, through the directed reading.
        for source in view.vertices {
            #expect(Array(view.directed.breadthFirstSearch(from: source)) == Array(copy.directed.breadthFirstSearch(from: source)))
            #expect(Array(view.directed.depthFirstSearch(from: source)) == Array(copy.directed.depthFirstSearch(from: source)))
            #expect(view.directed.descendants(of: source) == copy.directed.descendants(of: source))
        }
        // ShortestPaths, with a weight per incidence (an edge position of the view).
        let weight = (0 ..< view.edgeCount).map { ($0 &* 7 + seed) % 5 + 1 }
        for source in view.vertices {
            let tree = view.dijkstraShortestPaths(from: source) { weight[$0] }
            let copyTree = copy.dijkstraShortestPaths(from: source) { weight[$0] }
            let hops = view.shortestPaths(from: source), copyHops = copy.shortestPaths(from: source)
            for target in view.vertices {
                #expect(tree.distance(to: target) == copyTree.distance(to: target))
                #expect(tree.parent(of: target) == copyTree.parent(of: target))
                #expect(tree.parentEdge(of: target)?.position == copyTree.parentEdge(of: target)?.position)
                #expect(hops.distance(to: target) == copyHops.distance(to: target))
            }
        }
        // SpanningTrees, BipartiteGraphs and Cycles.
        #expect(view.minimumSpanningTree { weight[$0] }.edges == copy.minimumSpanningTree { weight[$0] }.edges)
        #expect(view.isBipartite && copy.isBipartite)
        #expect(BipartiteGraph(view, left: 0 ..< n) != nil)
        #expect(view.girth() == copy.girth())
        #expect(view.findCycle()?.vertices == copy.findCycle()?.vertices)
        // The hypergraph's components are the view's, restricted to the vertex side.
        let viewComponents = view.connectedComponents().map { $0.filter { $0 < n } }.filter { !$0.isEmpty }
        #expect(hypergraph.connectedComponents().map { $0.map { hypergraph.vertexIndex(of: $0) } } == viewComponents.map { $0.sorted() }.sorted { $0[0] < $1[0] })
        #expect(hypergraph.isConnected == (n > 0 && viewComponents.count == 1))
    }

    @Test("Directed: algorithms on incidenceGraph equal the same on an AdjacencyList copy", arguments: 1 ... 8)
    func directedViewAgainstCopy(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(50 + seed))
        let names = (0 ..< 5 + seed * 2).map { "v\($0)" }
        var hypergraph = IncidenceList<String>(vertices: names.shuffled(using: &rng).prefix(seed))
        for _ in 0 ..< 4 + seed * 2 {
            let sources = (0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in names.randomElement(using: &rng)! }
            let targets = (0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in names.randomElement(using: &rng)! }
            hypergraph.insert(sources: sources, targets: targets)
        }
        let view = hypergraph.incidenceGraph
        let n = hypergraph.vertexCount, m = hypergraph.hyperedgeCount
        let copy = AdjacencyList<Int>(vertices: view.vertices, edges: view.edges)
        #expect(view.vertexCount == n + m && Array(view.edges) == Array(copy.edges))
        for x in view.vertices {
            #expect(Array(view.successors(of: x)) == Array(copy.successors(of: x)))
            #expect(Array(view.predecessors(of: x)) == Array(copy.predecessors(of: x)))
            #expect(Array(view.outEdges(of: x)) == Array(copy.outEdges(of: x)))
            #expect(Array(view.inEdges(of: x)) == Array(copy.inEdges(of: x)))
            #expect(view.outDegree(of: x) == copy.outDegree(of: x) && view.inDegree(of: x) == copy.inDegree(of: x))
        }
        for i in 0 ..< n {
            #expect(Array(view.successors(of: i)) == hypergraph.outHyperedges(ofIndex: i).map { n + $0 })
            #expect(Array(view.predecessors(of: i)) == hypergraph.inHyperedges(ofIndex: i).map { n + $0 })
        }
        for p in 0 ..< m {
            #expect(Array(view.successors(of: n + p)) == Array(hypergraph.targetIndices(ofHyperedgeAt: p)))
            #expect(Array(view.predecessors(of: n + p)) == Array(hypergraph.sourceIndices(ofHyperedgeAt: p)))
        }
        #expect(view.stronglyConnectedComponents().map { Array($0) } == copy.stronglyConnectedComponents().map { Array($0) })
        #expect(view.weaklyConnectedComponents().map { Array($0) } == copy.weaklyConnectedComponents().map { Array($0) })
        #expect(view.condensation().components.map { Array($0) } == copy.condensation().components.map { Array($0) })
        #expect(view.topologicalSort() == copy.topologicalSort())
        let weight = (0 ..< view.edgeCount).map { ($0 &* 5 + seed) % 7 + 1 }
        for source in view.vertices {
            #expect(Array(view.breadthFirstSearch(from: source)) == Array(copy.breadthFirstSearch(from: source)))
            #expect(Array(view.depthFirstSearch(from: source)) == Array(copy.depthFirstSearch(from: source)))
            #expect(view.descendants(of: source) == copy.descendants(of: source))
            #expect(view.ancestors(of: source) == copy.ancestors(of: source))
            let tree = view.dijkstraShortestPaths(from: source) { weight[$0] }
            let copyTree = copy.dijkstraShortestPaths(from: source) { weight[$0] }
            for target in view.vertices {
                #expect(tree.distance(to: target) == copyTree.distance(to: target))
                #expect(tree.parentEdge(of: target) == copyTree.parentEdge(of: target))
            }
        }
        // The hypergraph's components are the view's, restricted to the vertex side.
        func restricted(_ components: [[Int]]) -> [[Int]] {
            components.map { $0.filter { $0 < n }.sorted() }.filter { !$0.isEmpty }.sorted { $0[0] < $1[0] }
        }
        #expect(hypergraph.stronglyConnectedComponents().map { $0.map { hypergraph.vertexIndex(of: $0) } } == restricted(view.stronglyConnectedComponents().map { Array($0) }))
        #expect(hypergraph.weaklyConnectedComponents().map { $0.map { hypergraph.vertexIndex(of: $0) } } == restricted(view.weaklyConnectedComponents().map { Array($0) }))
        // Plain reachability ("connected" in Gallo et al.) contains B-connection.
        for (i, v) in hypergraph.vertices.enumerated() {
            let reachable = Set(view.descendants(of: i).filter { $0 < n }).union([i])
            #expect(Set(hypergraph.bConnectedVertices(from: v).map { hypergraph.vertexIndex(of: $0) }).isSubset(of: reachable))
        }
    }

    @Test("The Hypergraph defaults and the algorithms work for any conformer with indices")
    func minimalConformer() {
        // Only the requirements without defaults, and the index members the algorithms need.
        struct Rows: Hypergraph {
            let names: [String]
            let rows: [[String]]
            var vertices: [String] { names }
            var hyperedges: [[String]] { rows }
            func incidentHyperedges(of vertex: String) -> [Int] { rows.indices.filter { rows[$0].contains(vertex) } }
            var vertexIndexBound: Int? { names.count }
            func vertexIndex(of vertex: String) -> Int { names.firstIndex(of: vertex)! }
            func vertex(atIndex index: Int) -> String { names[index] }
            var hyperedgeIndexBound: Int? { rows.count }
            func hyperedgeIndex(of position: Int) -> Int { position }
        }
        var rng = SeededRandomNumberGenerator(seed: 11)
        for _ in 0 ..< 40 {
            let names = (0 ..< Int.random(in: 0 ... 7, using: &rng)).map { "v\($0)" }
            let rows = names.isEmpty ? [] : (0 ..< Int.random(in: 0 ... 6, using: &rng)).map { _ in
                Array(Set((0 ..< Int.random(in: 0 ... 4, using: &rng)).map { _ in names.randomElement(using: &rng)! })).sorted { names.firstIndex(of: $0)! < names.firstIndex(of: $1)! }
            }
            let minimal = Rows(names: names, rows: rows)
            let list = UndirectedIncidenceList(minimal)
            #expect(Array(list.vertices) == names && list.hyperedges.map { Array($0) } == rows)
            #expect(minimal.vertexCount == names.count && minimal.hyperedgeCount == rows.count)
            for p in rows.indices {
                #expect(minimal.size(ofHyperedgeAt: p) == rows[p].count && Array(minimal.members(ofHyperedgeAt: p)) == rows[p])
                #expect(Array(minimal.memberIndices(ofHyperedgeAt: p)) == Array(list.memberIndices(ofHyperedgeAt: p)))
                #expect(minimal.contains(hyperedge: rows[p].reversed()))
            }
            #expect(minimal.contains(hyperedge: [] as [String]) == rows.contains { $0.isEmpty })
            #expect(!minimal.contains(hyperedge: ["absent"]) && !minimal.contains("absent"))
            for (i, v) in names.enumerated() {
                #expect(minimal.degree(of: v) == list.degree(of: v) && minimal.degree(ofIndex: i) == list.degree(ofIndex: i))
                #expect(Array(minimal.incidentHyperedges(ofIndex: i)) == Array(list.incidentHyperedges(ofIndex: i)))
                #expect(minimal.neighbors(of: v) == list.neighbors(of: v))
            }
            #expect(minimal.rank == list.rank && minimal.degreeHistogram() == list.degreeHistogram())
            #expect(minimal.hyperedgeSizeHistogram() == list.hyperedgeSizeHistogram())
            #expect(minimal.dual() == list.dual() && minimal.connectedComponents() == list.connectedComponents())
            #expect(minimal.isConnected == list.isConnected && minimal.isUniform(size: 2) == list.isUniform(size: 2))
            #expect(minimal.cliqueExpansion() == list.cliqueExpansion() && minimal.lineGraph(s: 1) == list.lineGraph(s: 1))
            #expect(minimal.sConnectedComponents(s: 2) == list.sConnectedComponents(s: 2))
            #expect(Array(minimal.incidenceGraph.edges) == Array(list.incidenceGraph.edges))
        }
    }

    @Test("The DirectedHypergraph defaults and the algorithms work for any conformer with indices")
    func minimalDirectedConformer() {
        struct Arcs: DirectedHypergraph {
            typealias Members = [String]
            let names: [String]
            let arcs: [(sources: [String], targets: [String])]
            var vertices: [String] { names }
            var hyperedges: [(sources: [String], targets: [String])] { arcs }
            func outHyperedges(of vertex: String) -> [Int] { arcs.indices.filter { arcs[$0].sources.contains(vertex) } }
            func inHyperedges(of vertex: String) -> [Int] { arcs.indices.filter { arcs[$0].targets.contains(vertex) } }
            var vertexIndexBound: Int? { names.count }
            func vertexIndex(of vertex: String) -> Int { names.firstIndex(of: vertex)! }
            func vertex(atIndex index: Int) -> String { names[index] }
            var hyperedgeIndexBound: Int? { arcs.count }
            func hyperedgeIndex(of position: Int) -> Int { position }
        }
        var rng = SeededRandomNumberGenerator(seed: 12)
        for _ in 0 ..< 40 {
            let names = (0 ..< Int.random(in: 1 ... 7, using: &rng)).map { "v\($0)" }
            func side() -> [String] {
                Array(Set((0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in names.randomElement(using: &rng)! })).sorted { names.firstIndex(of: $0)! < names.firstIndex(of: $1)! }
            }
            var arcs: [(sources: [String], targets: [String])] = []
            for _ in 0 ..< Int.random(in: 0 ... 6, using: &rng) { arcs.append((sources: side(), targets: side())) }
            let minimal = Arcs(names: names, arcs: arcs)
            let list = IncidenceList(minimal)
            #expect(Array(list.vertices) == names)
            #expect(list.hyperedges.map { [Array($0.sources), Array($0.targets)] } == arcs.map { [$0.sources, $0.targets] })
            for p in arcs.indices {
                #expect(Array(minimal.sources(ofHyperedgeAt: p)) == arcs[p].sources && Array(minimal.targets(ofHyperedgeAt: p)) == arcs[p].targets)
                #expect(Array(minimal.sourceIndices(ofHyperedgeAt: p)) == Array(list.sourceIndices(ofHyperedgeAt: p)))
                #expect(Array(minimal.targetIndices(ofHyperedgeAt: p)) == Array(list.targetIndices(ofHyperedgeAt: p)))
                #expect(minimal.contains(sources: arcs[p].sources.reversed(), targets: arcs[p].targets))
            }
            for (i, v) in names.enumerated() {
                #expect(minimal.outDegree(of: v) == list.outDegree(of: v) && minimal.inDegree(ofIndex: i) == list.inDegree(ofIndex: i))
                #expect(minimal.degree(of: v) == list.degree(of: v))
                #expect(minimal.bConnectedVertices(from: v) == list.bConnectedVertices(from: v))
                #expect(minimal.fConnectedVertices(to: v) == list.fConnectedVertices(to: v))
            }
            #expect(minimal.dual() == list.dual())
            #expect(minimal.stronglyConnectedComponents() == list.stronglyConnectedComponents())
            #expect(minimal.weaklyConnectedComponents() == list.weaklyConnectedComponents())
            #expect(minimal.cliqueExpansion() == list.cliqueExpansion())
            #expect(minimal.isBHypergraph == list.isBHypergraph && minimal.isFHypergraph == list.isFHypergraph && minimal.isBFHypergraph == list.isBFHypergraph)
            #expect(minimal.outDegreeHistogram() == list.outDegreeHistogram() && minimal.targetSizeHistogram() == list.targetSizeHistogram())
            #expect(Array(minimal.incidenceGraph.edges) == Array(list.incidenceGraph.edges))
        }
    }

    @Test("IncidenceList(_:) from a directed graph: each edge as ({source}, {target}), in edges order")
    func directedFromGraph() {
        let graph = AdjacencyList<String>(vertices: ["z"], edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "b", to: "b"), DirectedEdge(from: "b", to: "a")])
        let hypergraph = IncidenceList(graph)
        #expect(Array(hypergraph.vertices) == Array(graph.vertices))
        #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == graph.edges.map { [[$0.source], [$0.target]] })
        #expect(hypergraph.isBHypergraph && hypergraph.isFHypergraph && hypergraph.isBFHypergraph)
        // On a graph, B-connection and F-connection are reachability.
        for v in graph.vertices {
            #expect(Set(hypergraph.bConnectedVertices(from: v)) == graph.descendants(of: v).union([v]))
            #expect(Set(hypergraph.fConnectedVertices(to: v)) == graph.ancestors(of: v).union([v]))
        }
        #expect(hypergraph.cliqueExpansion() == AdjacencyList(vertices: graph.vertices, edges: graph.edges.filter { $0.source != $0.target }))
    }

    @Test("Codable round trips keep vertex order and positions, both kinds", arguments: 1 ... 6)
    func codableRoundTrips(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(200 + seed))
        var undirected = UndirectedIncidenceList<Int>(vertices: (0 ..< seed).map { $0 * 3 })
        var directed = IncidenceList<Int>(vertices: (0 ..< seed).map { $0 * 5 })
        for _ in 0 ..< seed * 3 {
            undirected.insert(hyperedge: (0 ..< Int.random(in: 0 ... 4, using: &rng)).map { _ in Int.random(in: 0 ... 20, using: &rng) })
            directed.insert(sources: (0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in Int.random(in: 0 ... 20, using: &rng) },
                            targets: (0 ..< Int.random(in: 0 ... 3, using: &rng)).map { _ in Int.random(in: 0 ... 20, using: &rng) })
        }
        let u = try JSONDecoder().decode(UndirectedIncidenceList<Int>.self, from: JSONEncoder().encode(undirected))
        #expect(u == undirected && Array(u.vertices) == Array(undirected.vertices))
        #expect(u.hyperedges.map { Array($0) } == undirected.hyperedges.map { Array($0) })
        let d = try JSONDecoder().decode(IncidenceList<Int>.self, from: JSONEncoder().encode(directed))
        #expect(d == directed && Array(d.vertices) == Array(directed.vertices))
        #expect(d.hyperedges.map { [Array($0.sources), Array($0.targets)] } == directed.hyperedges.map { [Array($0.sources), Array($0.targets)] })
    }

    @Test("Copy-on-write: mutating a copy leaves the original alone", .tags(.copyOnWrite))
    func copyOnWrite() {
        let original = UndirectedIncidenceList<String>(vertices: ["a"], hyperedges: [["a", "b"], []])
        var copy = original
        copy.insert(hyperedge: ["b", "c"])
        copy.insert("d")
        #expect(Array(original.vertices) == ["a", "b"] && original.hyperedges.map { Array($0) } == [["a", "b"], []])
        #expect(Array(original.incidentHyperedges(of: "b")) == [0] && copy.vertexCount == 4)
        var cleared = original
        cleared.removeAll(keepingCapacity: true)
        #expect(cleared.vertexCount == 0 && cleared.hyperedgeCount == 0 && original.hyperedgeCount == 2)
        let directed = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
        var directedCopy = directed
        directedCopy.insert(sources: ["b"], targets: ["c"])
        #expect(directed.hyperedgeCount == 1 && Array(directed.outHyperedges(of: "b")) == [] && directedCopy.hyperedgeCount == 2)
        var reversed = directed.reversed
        reversed.insert(sources: ["x"], targets: [] as [String])
        #expect(directed.vertexCount == 2 && Array(directed.sources(ofHyperedgeAt: 0)) == ["a"])
    }

    @Test("removeAll and reserveCapacity: the empty state, and no change to the contents")
    func resetsAndCapacity() {
        for keep in [false, true] {
            var undirected = UndirectedIncidenceList<String>(hyperedges: [["a", "b"], ["c"]])
            undirected.reserveCapacity(vertexCount: 100, hyperedgeCount: 100, incidenceCount: 400)
            #expect(undirected == UndirectedIncidenceList(hyperedges: [["a", "b"], ["c"]]) && Array(undirected.vertices) == ["a", "b", "c"])
            undirected.removeAll(keepingCapacity: keep)
            #expect(undirected == UndirectedIncidenceList() && undirected.vertexIndexBound == 0 && undirected.hyperedgeIndexBound == 0)
            #expect(undirected.insert(hyperedge: ["z"]) == 0 && undirected.vertexIndex(of: "z") == 0)
            var directed = IncidenceList<String>(hyperedges: [(sources: ["a"], targets: ["b"])])
            directed.reserveCapacity(vertexCount: 50, hyperedgeCount: 50, sourceCount: 100, targetCount: 100)
            #expect(Array(directed.vertices) == ["a", "b"] && directed.hyperedgeCount == 1)
            directed.removeAll(keepingCapacity: keep)
            #expect(directed == IncidenceList() && directed.vertexIndexBound == 0 && directed.hyperedgeIndexBound == 0)
            #expect(directed.insert(sources: ["z"], targets: ["y"]) == 0 && directed.vertexIndex(of: "y") == 1)
        }
    }

    @Test("init(_:) copies any conformer, vertices and positions in order; the duals convert back")
    func initFromConformers() {
        let undirected = UndirectedIncidenceList<String>(vertices: ["q"], hyperedges: [["b", "a"], [], ["a"]])
        let copied = UndirectedIncidenceList(undirected)
        #expect(Array(copied.vertices) == ["q", "b", "a"] && copied.hyperedges.map { Array($0) } == [["b", "a"], [], ["a"]])
        let dual = undirected.dual()
        #expect(UndirectedIncidenceList(dual).hyperedges.map { Array($0) } == dual.hyperedges.map { Array($0) })
        let directed = IncidenceList<String>(vertices: ["q"], hyperedges: [(sources: ["b"], targets: ["a", "b"]), (sources: [], targets: [])])
        let directedCopy = IncidenceList(directed)
        #expect(Array(directedCopy.vertices) == ["q", "b", "a"] && directedCopy == directed)
        #expect(IncidenceList(directed.reversed) == directed.reversed)
    }

    @Test("Sendable when the vertex is", .tags(.conformance))
    func sendable() async {
        let undirected = UndirectedIncidenceList<Int>(hyperedges: [[1, 2], [2, 3]])
        let directed = IncidenceList<Int>(hyperedges: [(sources: [1], targets: [2, 3])])
        let counts = await Task.detached { (undirected.hyperedgeCount, directed.vertexCount) }.value
        #expect(counts == (2, 3))
    }
}
