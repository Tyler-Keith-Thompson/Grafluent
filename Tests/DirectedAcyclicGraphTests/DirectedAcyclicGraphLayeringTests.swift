// Longest-path layering and distances: hand-worked cases on each base, the empty and edgeless
// graphs, holes, parallel edges, the checked spellings, agreement with `longestPath`, and a
// property test against a naive reference over predecessors. See README.md.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import StableGraphs
import Testing
import Walks

@Suite("DirectedAcyclicGraph longest-path layering and distances")
struct DirectedAcyclicGraphLayeringTests {
    @Test("A build schedule: sources in layer 0, every other vertex one past its deepest predecessor")
    func buildSchedule() throws {
        let graph = try #require(DirectedAcyclicGraph<AdjacencyList<String>>(vertices: ["fetch", "compile", "test", "package", "lint", "docs"], edges: [
            DirectedEdge(from: "fetch", to: "compile"), DirectedEdge(from: "compile", to: "test"),
            DirectedEdge(from: "test", to: "package"), DirectedEdge(from: "compile", to: "package"),
            DirectedEdge(from: "docs", to: "package"),
        ]))
        let layering = graph.longestPathLayering()
        let expectedCount = 4
        #expect(layering.count == expectedCount)
        #expect(layering.layer(of: "fetch") == 0 && layering.layer(of: "lint") == 0 && layering.layer(of: "docs") == 0)
        #expect(layering.layer(of: "compile") == 1 && layering.layer(of: "test") == 2 && layering.layer(of: "package") == 3)
        #expect(layering.vertices(inLayer: 0) == ["fetch", "lint", "docs"] && layering.vertices(inLayer: 3) == ["package"])
        #expect(layering.layers == [["fetch", "lint", "docs"], ["compile"], ["test"], ["package"]])
        #expect(try layering.layer(checked: "test") == 2)
        #expect(throws: VertexNotFound()) { try layering.layer(checked: "deploy") }
        for p in graph.edges.indices {
            #expect(layering.layer(of: graph.target(ofEdgeAt: p)) > layering.layer(of: graph.source(ofEdgeAt: p)))
        }
        #expect(layering.count - 1 == graph.longestPath()?.length)
    }

    @Test("Durations as weights: the distance is the heaviest path in, parallel copies take the heavier, a negative best restarts at zero")
    func durations() throws {
        var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: [0, 1, 2, 3])
        let hours = graph.addEdgeMap(default: 0)
        for (from, to, h) in [(0, 1, 4), (1, 2, 3), (0, 2, 9), (2, 3, -20), (0, 1, 1)] {
            let p = try graph.insert(edge: DirectedEdge(from: from, to: to))
            graph[hours, ofEdgeAt: p] = h
        }
        let w = graph.values(of: hours)
        let distances = graph.longestPathDistances(weight: { w[$0] })
        #expect(distances.distance(to: 0) == 0 && distances.distance(to: 1) == 4 && distances.distance(to: 2) == 9 && distances.distance(to: 3) == 0)
        let expectedMaximum = 9
        #expect(distances.maximum == expectedMaximum)
        #expect(try distances.distance(checkedTo: 2) == 9)
        #expect(throws: VertexNotFound()) { try distances.distance(checkedTo: 7) }
        let longest = try #require(graph.longestPath(weight: { w[$0] }))
        #expect(longest.edges.reduce(0) { $0 + w[$1] } == distances.maximum)
        let halves = graph.longestPathDistances(weight: { Double(w[$0]) / 2 })
        let expectedHalf = 4.5
        #expect(halves.distance(to: 2) == expectedHalf && halves.maximum == expectedHalf)
        // Parallel copies count once in the layering.
        let layering = graph.longestPathLayering()
        #expect(layering.layers == [[0], [1], [2], [3]])
    }

    @Test("Empty and edgeless graphs: no layers, or one layer in topological order")
    func emptyAndEdgeless() {
        let empty = DirectedAcyclicGraph<StableDirectedGraph<Int>>()
        let emptyLayering = empty.longestPathLayering()
        #expect(emptyLayering.count == 0 && emptyLayering.layers.isEmpty)
        let emptyDistances = empty.longestPathDistances(weight: { _ in 1 })
        #expect(emptyDistances.maximum == 0)
        let edgeless = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: [5, 3, 8])
        let layering = edgeless.longestPathLayering()
        #expect(layering.count == 1 && layering.layers == [[5, 3, 8]] && layering.vertices(inLayer: 0) == [5, 3, 8])
        #expect(layering.layer(of: 8) == 0)
        let one = DirectedAcyclicGraph<DirectedPseudograph<String>>(vertices: ["a"])
        #expect(one.longestPathLayering().count == 1 && one.longestPathDistances(weight: { _ in 2.0 }).distance(to: "a") == 0)
    }

    @Test("Holes in a StableDirectedGraph base and a swap-removed AdjacencyList base: removed vertices leave the layering")
    func afterRemovals() throws {
        var stable = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 0, to: 3),
        ]))
        _ = stable.remove(1)
        _ = stable.remove(edgeAt: 3)
        let stableLayering = stable.longestPathLayering()
        #expect(stableLayering.layers == [[0, 2], [3]] && stableLayering.layer(of: 3) == 1)
        #expect(throws: VertexNotFound()) { try stableLayering.layer(checked: 1) }
        let weights = [10, 20, 30, 40]
        let stableDistances = stable.longestPathDistances(weight: { weights[$0] })
        #expect(stableDistances.distance(to: 3) == 30 && stableDistances.maximum == 30)
        var dense = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3),
        ]))
        _ = dense.remove(0)
        let denseLayering = dense.longestPathLayering()
        #expect(denseLayering.layers == [[1], [2], [3]] && denseLayering.layer(of: 3) == 2)
        #expect(throws: VertexNotFound()) { try denseLayering.layer(checked: 0) }
    }

    @Test("The same layering through every base, and it is Sendable")
    func acrossBases() throws {
        let edges = [DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 4, to: 3)]
        let list = try #require(DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 5, edges: edges))
        let pseudo = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< 5, edges: edges))
        let stable = try #require(DirectedAcyclicGraph<StableDirectedGraph<Int>>(vertices: 0 ..< 5, edges: edges))
        let expected = [[0, 1, 4], [2], [3]]
        #expect(list.longestPathLayering().layers == expected && pseudo.longestPathLayering().layers == expected && stable.longestPathLayering().layers == expected)
        let weights = [1, 5, 1, 2]
        #expect(list.longestPathDistances(weight: { weights[$0] }).distance(to: 3) == 6 && stable.longestPathDistances(weight: { weights[$0] }).maximum == 6)
        let sendable: any Sendable = list.longestPathLayering()
        let sendableDistances: any Sendable = list.longestPathDistances(weight: { weights[$0] })
        _ = sendable
        _ = sendableDistances
    }

    @Test("Random DAGs: layers and distances match a naive reference over predecessors", .tags(.randomized))
    func againstNaiveReference() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 24)
        await propertyCheck(count: 200, input: pairs) { pairs in
            var graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< 9)
            for (a, b) in pairs where a != b {
                _ = try? graph.insert(edge: DirectedEdge(from: min(a, b), to: max(a, b)))
            }
            func weight(_ p: Int) -> Int { (p &* 5) % 7 - 2 }
            var layer: [Int: Int] = [:]
            var distance: [Int: Int] = [:]
            func naiveLayer(_ v: Int) -> Int {
                if let known = layer[v] { return known }
                let value = graph.predecessors(of: v).map { naiveLayer($0) + 1 }.max() ?? 0
                layer[v] = value
                return value
            }
            func naiveDistance(_ v: Int) -> Int {
                if let known = distance[v] { return known }
                var value = 0
                for p in graph.inEdges(of: v) { value = max(value, naiveDistance(graph.source(ofEdgeAt: p)) + weight(p)) }
                distance[v] = value
                return value
            }
            let layering = graph.longestPathLayering()
            let distances = graph.longestPathDistances(weight: weight)
            for v in 0 ..< 9 {
                #expect(layering.layer(of: v) == naiveLayer(v))
                #expect(distances.distance(to: v) == naiveDistance(v))
            }
            #expect(layering.count == (0 ..< 9).map(naiveLayer).max()! + 1)
            #expect(distances.maximum == (0 ..< 9).map(naiveDistance).max()!)
            let order = Array(graph.topologicalOrder)
            #expect(layering.layers == (0 ..< layering.count).map { k in order.filter { naiveLayer($0) == k } })
            #expect(layering.count - 1 == graph.longestPath()?.length)
        }
    }
}
