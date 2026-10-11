// feedbackArcSet() and feedbackArcSet(weight:): Eades, Lin and Smyth's greedy feedback arc set,
// with every self-loop in it (igraph's feedback_arc_set(method="eades") includes loops). Expected
// sets were checked against python-igraph 1.0 on each graph here; on other graphs igraph's bucket
// order can break ties differently. Removing the returned edges leaves an acyclic graph, checked
// by Kahn's algorithm inside each test.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

@Suite("feedbackArcSet")
struct FeedbackArcSetTests {
    @Test("Self-loops are in the set, as in igraph: 0 → 0, 0 → 1, 1 → 0 gives [0, 2]")
    func selfLoops() {
        let graph = ReferenceDirectedMultigraph(edges: [(0, 0), (0, 1), (1, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.feedbackArcSet() == [0, 2])
        // Weights do not keep a loop out; here they move the other arc (igraph: [0, 1]).
        #expect(graph.feedbackArcSet(weight: { [5.0, 1, 2][$0] }) == [0, 1])
        // A graph whose only cycles are loops.
        let loops = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 1), (1, 2), (2, 2), (2, 2)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(loops.feedbackArcSet() == [1, 3, 4])
        #expect(loops.feedbackArcSet(weight: { _ in 0.25 }) == [1, 3, 4])
    }

    @Test("Weights steer the set toward light arcs (igraph's weights)")
    func weightsSteer() {
        // A triangle 0 → 1 → 2 → 0 with a second 0 → 1: unweighted the heuristic takes 2 → 0;
        // with 2 → 0 heavy it takes 1 → 2 instead (igraph: [2], then [1]).
        let triangle = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 0), (0, 1)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(triangle.feedbackArcSet() == [2])
        #expect(triangle.feedbackArcSet(weight: { [1.0, 1, 5, 1][$0] }) == [1])
        // A 4-cycle 0 → 1 → 2 → 3 → 0 with the chord 1 → 3 (igraph: [0], then [2, 4]).
        let square = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0), (1, 3)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(square.feedbackArcSet() == [0])
        #expect(square.feedbackArcSet(weight: { [1.0, 1, 1, 10, 1][$0] }) == [2, 4])
    }

    @Test("On random multigraphs: ascending, every loop in, the rest acyclic; equal weights give the unweighted set")
    func randomMultigraphs() async {
        let arcs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 24)
        let weights = Gen.int(in: 0 ... 4).array(of: 24 ... 24)
        await propertyCheck(count: 300, input: arcs, weights) { arcs, weights in
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let context = "arcs \(arcs), weights \(weights)"
            let unweighted = graph.feedbackArcSet()
            let weighted = graph.feedbackArcSet(weight: { Double(weights[$0]) / 2 })
            #expect(graph.feedbackArcSet(weight: { _ in 3 }) == unweighted, "\(context)")
            for set in [unweighted, weighted] {
                #expect(set == set.sorted() && Set(set).count == set.count, "\(context)")
                #expect(arcs.indices.filter { arcs[$0].0 == arcs[$0].1 }.allSatisfy(set.contains), "\(context)")
                // Kahn's algorithm on the arcs left: every vertex is removed.
                let kept = arcs.indices.filter { !set.contains($0) }.map { arcs[$0] }
                var indegree = [Int](repeating: 0, count: 8)
                for (_, b) in kept { indegree[b] += 1 }
                var ready = (0 ..< 8).filter { indegree[$0] == 0 }
                var removed = 0
                while let v = ready.popLast() {
                    removed += 1
                    for (a, b) in kept where a == v {
                        indegree[b] -= 1
                        if indegree[b] == 0 { ready.append(b) }
                    }
                }
                #expect(removed == 8, "\(context): \(set)")
            }
            // An acyclic orientation has an empty set, weighted or not.
            let forward = ReferenceDirectedMultigraph(vertices: 0 ..< 8, edges: arcs.filter { $0.0 != $0.1 }.map { DirectedEdge(from: min($0.0, $0.1), to: max($0.0, $0.1)) })
            #expect(forward.feedbackArcSet().isEmpty && forward.feedbackArcSet(weight: { Double(weights[$0]) }).isEmpty, "\(context)")
        }
    }

    @Test("A non-finite weight, or weights whose magnitudes sum past the largest Double, trap", .tags(.precondition))
    func nonFiniteWeights() async {
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.feedbackArcSet(weight: { $0 == 0 ? .nan : 1 })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.feedbackArcSet(weight: { _ in .infinity })
        }
        await #expect(processExitsWith: .failure) {
            let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
            _ = graph.feedbackArcSet(weight: { _ in .greatestFiniteMagnitude })
        }
        // Without the traps: negative and zero weights are allowed (igraph allows them).
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        #expect(graph.feedbackArcSet(weight: { $0 == 0 ? -1 : 0 }).count == 1)
    }
}
