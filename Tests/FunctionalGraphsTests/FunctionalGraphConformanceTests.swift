// Conformance: the generic algorithms on a FunctionalGraph equal the same algorithms on the same
// edges stored in a DirectedPseudograph<Int> (vertices 0..<n in order, edge v → f(v) inserted in
// vertex order), on seeded random mappings, permutations and long tails. Traversal (BFS and DFS
// events, layers, descendants, hasPath, topological order, findCycle), Connectivity (weak, strong
// and attracting components) and ShortestPaths (hop counts and Dijkstra, the weight read from the
// edge's source, which is the position on both graphs). Then the decomposition against those
// results, LabeledGraph over a FunctionalGraph, Codable round trips and Sendable. See README.md.

import Connectivity
import Foundation
import FunctionalGraphs
import GrafluentTestSupport
import GraphProtocols
import LabeledGraphs
import Multigraphs
import ShortestPaths
import Testing
import Traversal

@Suite("FunctionalGraphs conformance with DirectedPseudograph", .tags(.randomized))
struct FunctionalGraphConformanceTests {
    @Test("Traversal on a FunctionalGraph equals Traversal on the pseudograph of the same edges", arguments: 0 ..< 40)
    func traversalAgrees(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 0 ... 30, using: &rng)
        let successors: [Int]
        switch seed % 3 {
        case 0: successors = (0 ..< n).map { _ in Int.random(in: 0 ..< n, using: &rng) }
        case 1: successors = Array((0 ..< n).shuffled(using: &rng))
        default: successors = (0 ..< n).map { $0 == 0 ? 0 : Int.random(in: max(0, $0 - 3) ..< $0, using: &rng) }
        }
        let graph = FunctionalGraph(successors: successors)
        let pseudograph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: successors[$0]) })
        #expect(Array(pseudograph.vertices) == Array(graph.vertices))
        #expect(graph.topologicalSort() == pseudograph.topologicalSort())
        // Every non-empty functional graph has a cycle.
        #expect(n == 0 ? graph.topologicalSort() == [] : graph.topologicalSort() == nil)
        #expect(graph.findCycle()?.vertices == pseudograph.findCycle()?.vertices)
        #expect(graph.findCycle()?.edges.map { graph.source(ofEdgeAt: $0) } == pseudograph.findCycle()?.edges.map { pseudograph.source(ofEdgeAt: $0) })
        for s in 0 ..< n {
            #expect(graph.breadthFirstLayers(from: s) == pseudograph.breadthFirstLayers(from: s), "seed \(seed), source \(s)")
            #expect(graph.lazy.breadthFirstSearch(from: s).map { "\($0)" } == pseudograph.lazy.breadthFirstSearch(from: s).map { "\($0)" }, "seed \(seed), source \(s)")
            #expect(graph.lazy.depthFirstSearch(from: s).map { "\($0)" } == pseudograph.lazy.depthFirstSearch(from: s).map { "\($0)" }, "seed \(seed), source \(s)")
            #expect(graph.descendants(of: s) == pseudograph.descendants(of: s), "seed \(seed), source \(s)")
            for t in 0 ..< n where (s + t) % 5 == 0 {
                #expect(graph.hasPath(from: s, to: t) == pseudograph.hasPath(from: s, to: t), "seed \(seed), \(s) → \(t)")
            }
        }
        #expect(graph.lazy.depthFirstSearch().map { "\($0)" } == pseudograph.lazy.depthFirstSearch().map { "\($0)" })
    }

    @Test("Connectivity and the decomposition agree with the pseudograph", arguments: 0 ..< 40)
    func connectivityAgrees(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(1_000 + seed))
        let n = Int.random(in: 0 ... 40, using: &rng)
        let successors = (0 ..< n).map { _ in Int.random(in: 0 ..< n, using: &rng) }
        let graph = FunctionalGraph(successors: successors)
        let pseudograph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: successors[$0]) })
        let weak = graph.weaklyConnectedComponents()
        let strong = graph.stronglyConnectedComponents()
        #expect(weak.map { Array($0) } == pseudograph.weaklyConnectedComponents().map { Array($0) })
        #expect(strong.map { Array($0) } == pseudograph.stronglyConnectedComponents().map { Array($0) })
        #expect(graph.attractingComponents().map { Array($0) } == pseudograph.attractingComponents().map { Array($0) })
        // In a functional graph the attracting components are exactly the cycles, and each weak
        // component holds exactly one cycle, which the decomposition numbers.
        let whole = graph.cycleDecomposition()
        #expect(Set(graph.attractingComponents().map { Set($0) }) == Set(whole.cycles.map { Set($0) }))
        #expect(weak.count == whole.cycles.count)
        for v in 0 ..< n {
            for u in 0 ..< n where (u * 31 + v) % 7 == 0 {
                #expect((weak.component(of: u) == weak.component(of: v)) == (whole.component(of: u) == whole.component(of: v)), "seed \(seed): \(u), \(v)")
            }
            // The strong component of v is its cycle when v is on one, and {v} otherwise.
            let mine = Set(strong[strong.component(of: v)])
            #expect(mine == (whole.tailLength(of: v) == 0 ? Set(whole.cycles[whole.component(of: v)]) : [v]), "seed \(seed): \(v)")
        }
    }

    @Test("Shortest paths agree with the pseudograph; the tail length is the distance to the root", arguments: 0 ..< 30)
    func shortestPathsAgree(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: UInt(2_000 + seed))
        let n = Int.random(in: 1 ... 40, using: &rng)
        let successors = (0 ..< n).map { _ in Int.random(in: 0 ..< n, using: &rng) }
        let weights = (0 ..< n).map { _ in Int.random(in: 0 ... 9, using: &rng) }
        let graph = FunctionalGraph(successors: successors)
        let pseudograph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: (0 ..< n).map { DirectedEdge(from: $0, to: successors[$0]) })
        let whole = graph.cycleDecomposition()
        for s in 0 ..< n {
            let hops = graph.shortestPaths(from: s)
            let pseudoHops = pseudograph.shortestPaths(from: s)
            let weighted = graph.dijkstraShortestPaths(from: s) { weights[$0] }
            let pseudoWeighted = pseudograph.dijkstraShortestPaths(from: s) { weights[pseudograph.source(ofEdgeAt: $0)] }
            #expect((0 ..< n).map { hops.distance(to: $0) } == (0 ..< n).map { pseudoHops.distance(to: $0) }, "seed \(seed), source \(s)")
            #expect((0 ..< n).map { weighted.distance(to: $0) } == (0 ..< n).map { pseudoWeighted.distance(to: $0) }, "seed \(seed), source \(s)")
            #expect(hops.distance(to: whole.root(of: s)) == whole.tailLength(of: s), "seed \(seed), source \(s)")
            // The vertices at hop distance k are f^k(s), for k below the tail plus the cycle.
            for t in 0 ..< n {
                if let k = hops.distance(to: t) {
                    #expect(graph.successor(of: s, steps: k) == t && whole.successor(of: s, steps: k) == t, "seed \(seed): \(s) → \(t)")
                }
            }
            #expect((0 ..< n).filter { hops.distance(to: $0) != nil }.count == whole.tailLength(of: s) + whole.cycleLength(of: s))
        }
    }

    @Test("A LabeledGraph over a FunctionalGraph forwards to it")
    func labeled() throws {
        let graph = FunctionalGraph(successors: [3, 0, 1, 5, 3, 6, 3, 7, 9, 10, 9, 8])
        let names = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"]
        let labeled = try LabeledGraph(graph, labels: names)
        #expect(labeled.base == graph)
        #expect(labeled.vertices.map { Array(labeled.successors(of: $0)) } == (0 ..< 12).map { [names[graph.successor(of: $0)]] })
        #expect(labeled.edges.map { [$0.source, $0.target] } == (0 ..< 12).map { [names[$0], names[graph.successor(of: $0)]] })
        #expect(Set(labeled.weaklyConnectedComponents().map { Set($0) }) == [["a", "b", "c", "d", "e", "f", "g"], ["h"], ["i", "j", "k", "l"]])
        #expect(labeled.base.cycleDecomposition().cycles.map { $0.map { names[$0] } } == [["d", "f", "g"], ["h"], ["j", "k"]])
    }

    @Test("Codable round trips random graphs as the bare successor array", .tags(.conformance), arguments: 0 ..< 20)
    func codableRoundTrip(seed: Int) throws {
        var rng = SeededRandomNumberGenerator(seed: UInt(3_000 + seed))
        let n = Int.random(in: 0 ... 25, using: &rng)
        let successors = (0 ..< n).map { _ in Int.random(in: 0 ..< n, using: &rng) }
        let graph = FunctionalGraph(successors: successors)
        let data = try JSONEncoder().encode(graph)
        #expect(try JSONDecoder().decode([Int].self, from: data) == successors)
        let decoded = try JSONDecoder().decode(FunctionalGraph.self, from: data)
        #expect(decoded == graph && decoded.hashValue == graph.hashValue)
        #expect(decoded.description == "FunctionalGraph(\(successors))")
        // One successor out of range, anywhere, is rejected.
        if n > 0 {
            var corrupt = successors
            corrupt[Int.random(in: 0 ..< n, using: &rng)] = seed.isMultiple(of: 2) ? n : -1
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(FunctionalGraph.self, from: JSONEncoder().encode(corrupt)) }
        }
    }

    @Test("Equality and hashing follow the successor arrays", .tags(.conformance))
    func equalityFollowsArrays() {
        var graphs: [[Int]] = [[]]
        for n in 1 ... 3 {
            var all: [[Int]] = [[]]
            for _ in 0 ..< n { all = all.flatMap { prefix in (0 ..< n).map { prefix + [$0] } } }
            graphs += all
        }
        for a in graphs {
            for b in graphs {
                let lhs = FunctionalGraph(successors: a), rhs = FunctionalGraph(successors: b)
                #expect((lhs == rhs) == (a == b), "\(a) vs \(b)")
                if a == b { #expect(lhs.hashValue == rhs.hashValue) }
            }
        }
        #expect(Set(graphs.map { FunctionalGraph(successors: $0) }).count == graphs.count)
    }

    @Test("FunctionalGraph and its decomposition are Sendable values")
    func sendable() async {
        let graph = FunctionalGraph(successors: [1, 2, 0, 0])
        let whole = graph.cycleDecomposition()
        let fromTask = await Task { (graph.successor(of: 3, steps: 7), whole.tailLength(of: 3), Array(whole.preimages(of: 0))) }.value
        #expect(fromTask.0 == 0 && fromTask.1 == 1 && fromTask.2 == [2, 3])
    }
}
