// Weights at the edges of what is allowed: negative weights, infinities (ordinary weights, so a
// +∞ bridge is in the tree), a NaN total from +∞ and −∞ (traps), NaN weights (trap on every read,
// but a self-loop is never read), sums at the Int limit and overflow (traps), unsigned weights,
// other weight types, and what the weight closure is asked. Case IDs (ST-nn) refer to the catalog;
// see README.md.

import GraphProtocols
import GrafluentTestSupport
import SpanningTrees
import Testing

/// A weight type of the user's own: only `Comparable` and `AdditiveArithmetic`.
private struct Cost: Comparable, AdditiveArithmetic {
    var cents: Int
    static var zero: Cost { Cost(cents: 0) }
    static func + (lhs: Cost, rhs: Cost) -> Cost { Cost(cents: lhs.cents + rhs.cents) }
    static func - (lhs: Cost, rhs: Cost) -> Cost { Cost(cents: lhs.cents - rhs.cents) }
    static func < (lhs: Cost, rhs: Cost) -> Bool { lhs.cents < rhs.cents }
}

@Suite("Weight edge cases")
struct WeightEdgeCaseTests {
    @Test("ST-50 negative weights are ordinary: min −5, max −3")
    func negativeWeights() {
        let edges: [(Int, Int, Int)] = [(0, 1, -1), (1, 2, -2), (0, 2, -3)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [2, 1])
        #expect(tree.weight == -5)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == [2, 1])
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(Set(prim.edges) == [2, 1])
        #expect(prim.weight == -5)
        #expect(Set(graph.primMinimumSpanningTree(from: 1) { edges[$0].2 }.edges) == [2, 1])
        let maximum = graph.maximumSpanningTree { edges[$0].2 }
        #expect(maximum.edges == [0, 1])
        #expect(maximum.weight == -3)
    }

    @Test("ST-51 NetworkX's negative-weight graph: −3")
    func networkXNegative() {
        let edges: [(Int, Int, Int)] = [(1, 2, 1), (1, 3, -1), (2, 3, -2)]
        let graph = ReferencePseudograph(vertices: [1, 2, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [2, 1])
        #expect(tree.weight == -3)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == [2, 1])
        #expect(Set(graph.primMinimumSpanningTree { edges[$0].2 }.edges) == [2, 1])
        #expect(graph.primMinimumSpanningTree { edges[$0].2 }.weight == -3)
    }

    @Test("ST-52 a +∞ bridge is in the tree, in every algorithm (unlike NetworkX's Borůvka)")
    func infiniteBridge() {
        let edges: [(Int, Int, Double)] = [(0, 1, 1), (1, 2, .infinity)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == .infinity)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        let boruvka = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        #expect(Set(boruvka.edges) == [0, 1])
        #expect(boruvka.weight == .infinity)
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(Set(prim.edges) == [0, 1])
        #expect(prim.weight == .infinity)
        for root in 0 ..< 3 {
            #expect(Set(graph.primMinimumSpanningTree(from: root) { edges[$0].2 }.edges) == [0, 1], "from \(root)")
        }
        // The maximum takes the bridges too: there is nothing else.
        #expect(graph.maximumSpanningTree { edges[$0].2 }.edges == [1, 0])
    }

    @Test("ST-53 a +∞ edge on a cycle is left out")
    func infiniteChord() {
        let edges: [(Int, Int, Double)] = [(0, 1, 1), (1, 2, 2), (0, 2, .infinity)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == 3)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == [0, 1])
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(Set(prim.edges) == [0, 1])
        #expect(prim.weight == 3)
    }

    @Test("ST-54 a −∞ edge is taken first; the order still decides between the others")
    func negativeInfinity() {
        let edges: [(Int, Int, Double)] = [(0, 1, -.infinity), (1, 2, 1), (0, 2, 2)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0, 1])
        #expect(tree.weight == -.infinity)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == [0, 1])
        // Both forests sum to −∞, but by comparison 1 < 2 decides, so Prim takes 1–2 as well.
        let prim = graph.primMinimumSpanningTree { edges[$0].2 }
        #expect(Set(prim.edges) == [0, 1])
        #expect(prim.weight == -.infinity)
    }

    @Test("ST-55 +∞ and −∞ both in the forest: the total is NaN and traps", .tags(.precondition))
    func nanTotal() async {
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(0, 1, .infinity), (1, 2, -.infinity)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.minimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(0, 1, .infinity), (1, 2, -.infinity)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.kruskalMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(0, 1, .infinity), (1, 2, -.infinity)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.primMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(0, 1, .infinity), (1, 2, -.infinity)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.primMinimumSpanningTree(from: 2) { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(0, 1, .infinity), (1, 2, -.infinity)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(0, 1, .infinity), (1, 2, -.infinity)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.maximumSpanningTree { edges[$0].2 }
        }
    }

    @Test("ST-56 a NaN weight traps in every algorithm (NetworkX test_nan_weights)", .tags(.precondition))
    func nanWeightTraps() async {
        await #expect(processExitsWith: .failure) {
            let wiki: [(Int, Int, Double)] = [
                (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
            ]
            let edges: [(Int, Int, Double)] = wiki + [(0, 12, .nan)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 7) + [12], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.minimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let wiki: [(Int, Int, Double)] = [
                (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
            ]
            let edges: [(Int, Int, Double)] = wiki + [(0, 12, .nan)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 7) + [12], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.kruskalMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let wiki: [(Int, Int, Double)] = [
                (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
            ]
            let edges: [(Int, Int, Double)] = wiki + [(0, 12, .nan)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 7) + [12], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.primMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let wiki: [(Int, Int, Double)] = [
                (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
            ]
            let edges: [(Int, Int, Double)] = wiki + [(0, 12, .nan)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 7) + [12], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.primMinimumSpanningTree(from: 6) { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let wiki: [(Int, Int, Double)] = [
                (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
            ]
            let edges: [(Int, Int, Double)] = wiki + [(0, 12, .nan)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 7) + [12], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let wiki: [(Int, Int, Double)] = [
                (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
            ]
            let edges: [(Int, Int, Double)] = wiki + [(0, 12, .nan)]
            let graph = ReferencePseudograph(vertices: Array(0 ..< 7) + [12], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.maximumSpanningTree { edges[$0].2 }
        }
    }

    @Test("ST-56 with the NaN edge filtered out (NetworkX ignore_nan): 39, and 12 is isolated")
    func nanFilteredOut() {
        let wiki: [(Int, Int, Double)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let withNaN: [(Int, Int, Double)] = wiki + [(0, 12, .nan)]
        let edges = withNaN.filter { $0.2 == $0.2 }
        let graph = ReferencePseudograph(vertices: Array(0 ..< 7) + [12], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [1, 5, 7, 0, 4, 9])
        #expect(tree.weight == 39)
        #expect(graph.primMinimumSpanningTree { edges[$0].2 }.weight == 39)
        #expect(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.weight == 39)
        #expect(graph.primMinimumSpanningTree(from: 12) { edges[$0].2 }.edges == [])
    }

    @Test("ST-57 a NaN self-loop is never weighed, so nothing traps (NetworkX's Kruskal raises here)", .tags(.selfLoops))
    func nanSelfLoop() {
        let edges: [(Int, Int, Double)] = [(0, 1, 1), (1, 1, .nan)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [0])
        #expect(tree.weight == 1)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.boruvkaMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.primMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.primMinimumSpanningTree(from: 0) { edges[$0].2 } == tree)
        #expect(graph.primMinimumSpanningTree(from: 1) { edges[$0].2 } == tree)
        #expect(graph.maximumSpanningTree { edges[$0].2 } == tree)
    }

    @Test("ST-58 a NaN copy of a parallel edge traps (NetworkX test_ignore_nan)", .tags(.precondition))
    func nanParallelCopy() async {
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(1, 2, .nan), (1, 2, 3), (3, 2, 2), (3, 1, 4)]
            let graph = ReferencePseudograph(vertices: [1, 2, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.minimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(1, 2, .nan), (1, 2, 3), (3, 2, 2), (3, 1, 4)]
            let graph = ReferencePseudograph(vertices: [1, 2, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.primMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Double)] = [(1, 2, .nan), (1, 2, 3), (3, 2, 2), (3, 1, 4)]
            let graph = ReferencePseudograph(vertices: [1, 2, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        }
    }

    @Test("ST-58 with the NaN copy filtered out: 5, {1–2 at 3, 3–2 at 2}")
    func nanParallelCopyFiltered() {
        let edges: [(Int, Int, Double)] = [(1, 2, 3), (3, 2, 2), (3, 1, 4)]
        let graph = ReferencePseudograph(vertices: [1, 2, 3], edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [1, 0])
        #expect(tree.weight == 5)
        #expect(Set(graph.primMinimumSpanningTree { edges[$0].2 }.edges) == [1, 0])
    }

    @Test("ST-59 a total of exactly Int.max: no sentinel is ever added to")
    func sumAtTheLimit() {
        let edges: [(Int, Int, Int)] = [(0, 1, Int.max - 1), (1, 2, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [1, 0])
        #expect(tree.weight == Int.max)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.weight == Int.max)
        #expect(graph.primMinimumSpanningTree { edges[$0].2 }.weight == Int.max)
        #expect(graph.primMinimumSpanningTree(from: 2) { edges[$0].2 }.weight == Int.max)
        #expect(graph.maximumSpanningTree { edges[$0].2 }.weight == Int.max)
    }

    @Test("ST-60 overflow in the total traps, in every algorithm", .tags(.precondition))
    func overflowTraps() async {
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Int)] = [(0, 1, Int.max), (1, 2, 1)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.minimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Int)] = [(0, 1, Int.max), (1, 2, 1)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.kruskalMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Int)] = [(0, 1, Int.max), (1, 2, 1)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.primMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Int)] = [(0, 1, Int.max), (1, 2, 1)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.primMinimumSpanningTree(from: 1) { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Int)] = [(0, 1, Int.max), (1, 2, 1)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.boruvkaMinimumSpanningTree { edges[$0].2 }
        }
        await #expect(processExitsWith: .failure) {
            let edges: [(Int, Int, Int)] = [(0, 1, Int.max), (1, 2, 1)]
            let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            _ = graph.maximumSpanningTree { edges[$0].2 }
        }
    }

    @Test("ST-61 UInt8 weights: min 150, max 220; the maximum never negates")
    func unsignedWeights() {
        let edges: [(Int, Int, UInt8)] = [(0, 1, 120), (1, 2, 100), (0, 2, 50)]
        let graph = ReferencePseudograph(vertices: 0 ..< 3, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        let tree = graph.minimumSpanningTree { edges[$0].2 }
        #expect(tree.edges == [2, 1])
        #expect(tree.weight == 150)
        #expect(graph.kruskalMinimumSpanningTree { edges[$0].2 } == tree)
        #expect(Set(graph.boruvkaMinimumSpanningTree { edges[$0].2 }.edges) == [2, 1])
        #expect(graph.primMinimumSpanningTree { edges[$0].2 }.weight == 150)
        let maximum = graph.maximumSpanningTree { edges[$0].2 }
        #expect(maximum.edges == [0, 1])
        #expect(maximum.weight == 220)
    }

    @Test("ST-62 other weight types: Double, Float, Duration and a user type, on Wikipedia's graph")
    func otherWeightTypes() {
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: wiki.map { UndirectedEdge($0.0, $0.1) })
        let canonical = [1, 5, 7, 0, 4, 9]

        let doubles = wiki.map { Double($0.2) }
        #expect(graph.minimumSpanningTree { doubles[$0] }.edges == canonical)
        #expect(graph.minimumSpanningTree { doubles[$0] }.weight == 39)
        #expect(graph.primMinimumSpanningTree { doubles[$0] }.weight == 39)
        #expect(Set(graph.boruvkaMinimumSpanningTree { doubles[$0] }.edges) == Set(canonical))

        let floats = wiki.map { Float($0.2) }
        #expect(graph.kruskalMinimumSpanningTree { floats[$0] }.edges == canonical)
        #expect(graph.kruskalMinimumSpanningTree { floats[$0] }.weight == 39)
        #expect(graph.primMinimumSpanningTree { floats[$0] }.weight == 39)

        let durations = wiki.map { Duration.seconds($0.2) }
        #expect(graph.minimumSpanningTree { durations[$0] }.edges == canonical)
        #expect(graph.minimumSpanningTree { durations[$0] }.weight == .seconds(39))
        #expect(graph.primMinimumSpanningTree(from: 3) { durations[$0] }.weight == .seconds(39))
        #expect(graph.boruvkaMinimumSpanningTree { durations[$0] }.weight == .seconds(39))
        #expect(graph.maximumSpanningTree { durations[$0] }.weight == .seconds(59))

        let costs = wiki.map { Cost(cents: $0.2) }
        #expect(graph.minimumSpanningTree { costs[$0] }.edges == canonical)
        #expect(graph.minimumSpanningTree { costs[$0] }.weight == Cost(cents: 39))
        #expect(Set(graph.primMinimumSpanningTree { costs[$0] }.edges) == Set(canonical))
        #expect(graph.boruvkaMinimumSpanningTree { costs[$0] }.weight == Cost(cents: 39))
        #expect(graph.maximumSpanningTree { costs[$0] }.edges == [6, 10, 3, 9, 2, 0])
    }

    @Test("ST-63 each non-loop edge is weighed exactly once, a self-loop never, in every algorithm", .tags(.selfLoops))
    func weightCalls() {
        let wiki: [(Int, Int, Int)] = [
            (0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6), (4, 5, 8), (4, 6, 9), (5, 6, 11),
        ]
        // Self-loops at 2 and 6, positions 11 and 12.
        let edges: [(Int, Int, Int)] = wiki + [(2, 2, 1), (6, 6, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 7, edges: edges.map { UndirectedEdge($0.0, $0.1) })
        var asked: [Int] = []
        let weight: (Int) -> Int = { position in
            asked.append(position)
            return edges[position].2
        }
        #expect(graph.minimumSpanningTree(weight: weight).weight == 39)
        #expect(asked.sorted() == Array(0 ..< 11))
        asked = []
        #expect(graph.kruskalMinimumSpanningTree(weight: weight).weight == 39)
        #expect(asked.sorted() == Array(0 ..< 11))
        asked = []
        #expect(graph.primMinimumSpanningTree(weight: weight).weight == 39)
        #expect(asked.sorted() == Array(0 ..< 11))
        asked = []
        #expect(graph.primMinimumSpanningTree(from: 6, weight: weight).weight == 39)
        #expect(asked.sorted() == Array(0 ..< 11))
        asked = []
        #expect(graph.boruvkaMinimumSpanningTree(weight: weight).weight == 39)
        #expect(asked.sorted() == Array(0 ..< 11))
        asked = []
        #expect(graph.maximumSpanningTree(weight: weight).weight == 59)
        #expect(asked.sorted() == Array(0 ..< 11))

        // from: weighs only the root's component (ST-47 from 3: just position 3).
        let forest: [(Int, Int, Int)] = [(0, 1, 1), (1, 2, 2), (0, 2, 3), (3, 4, 5)]
        let disconnected = ReferencePseudograph(vertices: 0 ..< 6, edges: forest.map { UndirectedEdge($0.0, $0.1) })
        var component: [Int] = []
        let rooted = disconnected.primMinimumSpanningTree(from: 3) { position in
            component.append(position)
            return forest[position].2
        }
        #expect(rooted.edges == [3])
        #expect(component == [3])
        var none: [Int] = []
        _ = disconnected.primMinimumSpanningTree(from: 5) { position in
            none.append(position)
            return forest[position].2
        }
        #expect(none.isEmpty)
        // A NaN weight outside the root's component is never read, so it does not trap.
        let nan: [Double] = [1, 2, 3, .nan]
        #expect(disconnected.primMinimumSpanningTree(from: 0) { nan[$0] }.weight == 3)
    }
}
