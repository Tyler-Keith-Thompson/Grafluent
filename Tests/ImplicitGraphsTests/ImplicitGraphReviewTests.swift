// Cases the catalog does not list, each pinning behavior a planted bug changed while every catalog
// row still passed: index ends and traps at endIndex, the one-pass `map`, the closure search's
// heap order, its tie between equal priorities, the NaN check on the start's estimate, and the
// cutoff on the distance alone. Hand-written; see README.md.

import GraphProtocols
import ImplicitGraphs
import ShortestPaths
import Testing

@Suite("ImplicitGraphs review cases")
struct ImplicitGraphReviewTests {
    @Test("targetIndex(ofEdgeAt:) and sourceIndex(ofEdgeAt:) read the position's two ends")
    func indexEnds() {
        let rows = [[1, 2], [2], [0, 0]]
        let graph = ImplicitDirectedGraph(vertexCount: 3, successors: { rows[$0] })
        var ends: [[Int]] = []
        for position in graph.edges.indices {
            ends.append([graph.sourceIndex(ofEdgeAt: position), graph.targetIndex(ofEdgeAt: position)])
        }
        #expect(ends == [[0, 1], [0, 2], [1, 2], [2, 0], [2, 0]])
    }

    @Test("edges.map calls the closure once per vertex, not once per index step")
    func mapIsOnePass() {
        var calls = 0
        let graph = ImplicitDirectedGraph(vertexCount: 4, successors: { (v: Int) -> [Int] in
            calls += 1
            return [(v + 1) % 4, (v + 2) % 4]
        })
        let sources = graph.edges.map(\.source)
        #expect(sources == [0, 0, 1, 1, 2, 2, 3, 3])
        #expect(calls == 4)
    }

    @Test("index(after:) traps at endIndex, even when the closure accepts any Int")
    func indexAfterEndTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = ImplicitDirectedGraph(vertexCount: 3, successors: { (_: Int) -> [Int] in [0] })
            _ = graph.edges.index(after: graph.edges.endIndex)
        }
        let graph = ImplicitDirectedGraph(vertexCount: 3, successors: { (_: Int) -> [Int] in [0] })
        let last = graph.edges.index(graph.edges.startIndex, offsetBy: 2)
        #expect(graph.edges.index(after: last) == graph.edges.endIndex)
    }

    @Test("edges[endIndex] traps")
    func subscriptAtEndTraps() async {
        await #expect(processExitsWith: .failure) {
            let graph = ImplicitDirectedGraph(vertexCount: 3, successors: { (_: Int) -> [Int] in [0] })
            _ = graph.edges[graph.edges.endIndex]
        }
        let graph = ImplicitDirectedGraph(vertexCount: 3, successors: { (_: Int) -> [Int] in [0] })
        #expect(graph.edges[graph.edges.startIndex] == DirectedEdge(from: 0, to: 0))
    }

    @Test("Closure Dijkstra settles states in distance order once its queue holds several entries")
    func heapOrder() throws {
        // Ten steps out of five states, so the queue is deep enough for a misplaced entry to come
        // out early: the shortest route is 0 → 2 → 7 → 6 → 8 at cost 2, the direct step costs 3.
        let steps: [(Int, Int, Int)] = [
            (2, 7, 1), (7, 6, 1), (6, 8, 0), (0, 2, 0), (0, 8, 3),
            (3, 1, 3), (2, 3, 2), (0, 5, 3), (2, 3, 1), (7, 4, 2),
        ]
        let result = try #require(dijkstraShortestPath(
            from: 0,
            successors: { (v: Int) -> [(Int, Int)] in steps.filter { $0.0 == v }.map { ($0.1, $0.2) } },
            success: { $0 == 8 }
        ))
        #expect(result.distance == 2)
        #expect(result.path == [0, 2, 7, 6, 8])
    }

    @Test("A* with an exact estimate on an open grid expands only one shortest path")
    func equalPrioritiesPreferTheFartherState() throws {
        // Every cell of the 5 × 5 square from (0, 0) to (4, 4) has the same priority, 8, under the
        // Manhattan estimate; preferring the farther of equal priorities walks straight to the
        // goal, expanding the 8 cells before it.
        struct Cell: Hashable { let x: Int, y: Int }
        var expanded = 0
        let result = try #require(aStarShortestPath(
            from: Cell(x: 0, y: 0),
            successors: { (c: Cell) -> [(Cell, Int)] in
                expanded += 1
                return [Cell(x: c.x + 1, y: c.y), Cell(x: c.x, y: c.y + 1), Cell(x: c.x - 1, y: c.y), Cell(x: c.x, y: c.y - 1)].map { ($0, 1) }
            },
            heuristic: { abs(4 - $0.x) + abs(4 - $0.y) },
            success: { $0 == Cell(x: 4, y: 4) }
        ))
        #expect(result.distance == 8 && result.path.count == 9)
        #expect(expanded == 8)
    }

    @Test("Of two equal priorities, A* takes the farther state even when the nearer one was queued later")
    func equalPrioritiesQueuedFartherFirst() throws {
        // From 0: the goal 1 at cost 2 (estimate 0), then 2 at cost 1 (estimate 1, one step from
        // the goal). Both have priority 2; the goal is farther, so it is settled first and only 0
        // is expanded.
        var expanded: [Int] = []
        let result = try #require(aStarShortestPath(
            from: 0,
            successors: { (v: Int) -> [(Int, Int)] in
                expanded.append(v)
                return [0: [(1, 2), (2, 1)], 2: [(1, 1)]][v] ?? []
            },
            heuristic: { [0: 2, 1: 0, 2: 1][$0]! },
            success: { $0 == 1 }
        ))
        #expect(result.distance == 2 && result.path == [0, 1])
        #expect(expanded == [0])
    }

    @Test("A* traps on a NaN estimate of the start")
    func nanStartEstimateTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = aStarShortestPath(from: 0, successors: { (v: Int) -> [(Int, Double)] in v == 0 ? [(1, 1.0)] : [] },
                                  heuristic: { $0 == 0 ? .nan : 0 }, success: { $0 == 1 })
        }
        let result = aStarShortestPath(from: 0, successors: { (v: Int) -> [(Int, Double)] in v == 0 ? [(1, 1.0)] : [] },
                                       heuristic: { _ in 0 }, success: { $0 == 1 })
        #expect(result?.distance == 1)
    }

    @Test("The cutoff bounds the distance alone: an estimate above it does not hide a goal within it")
    func cutoffIgnoresTheEstimate() throws {
        // 0 → 1 → 2 at cost 1 each, cutoff 5; the estimate of 1 (100) is not admissible, but the
        // cutoff is on the distance from the start, so the goal at distance 2 is found.
        let result = try #require(aStarShortestPath(
            from: 0, cutoff: 5,
            successors: { (v: Int) -> [(Int, Int)] in v < 2 ? [(v + 1, 1)] : [] },
            heuristic: { $0 == 1 ? 100 : 0 },
            success: { $0 == 2 }
        ))
        #expect(result.distance == 2 && result.path == [0, 1, 2])
    }
}
