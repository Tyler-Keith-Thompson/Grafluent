// Searches over successor closures on unbounded spaces (catalog IG-023 – IG-031): Traversal's
// breadthFirstSearch(from:depthLimit:successors:), and ShortestPaths D19's
// dijkstraShortestPath(from:successors:success:) and aStarShortestPath(from:successors:heuristic:
// success:), pinning distances and, with unit costs, path vertex counts; each path is checked
// step by step against the closure, since ties between equal paths are not pinned.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import ImplicitGraphs
import ShortestPaths
import Testing
import Traversal

@Suite("ImplicitGraphs closure searches")
struct ImplicitGraphClosureSearchTests {
    @Test("IG-023 Traversal (exists): breadthFirstSearch over an unbounded grid, depth limit 2")
    func ig023() {
        // breadthFirstSearch(from: [P(0, 0)], depthLimit: 2, successors: grid4) / discovered vertices → 13
        struct P: Hashable {
            var x, y: Int
        }
        let grid4 = { (p: P) -> [P] in [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)] }
        var discovered: [P] = []
        for event in breadthFirstSearch(from: [P(x: 0, y: 0)], depthLimit: 2, successors: grid4) {
            if case .discover(let p) = event { discovered.append(p) }
        }
        #expect(discovered.count == 13)
        #expect(Set(discovered) == Set((-2 ... 2).flatMap { x in (-2 ... 2).map { y in P(x: x, y: y) } }.filter { abs($0.x) + abs($0.y) <= 2 }))
        #expect(discovered.first == P(x: 0, y: 0))
    }

    @Test("IG-024 D19 Dijkstra: knight from (0, 0) to (7, 7) on an unbounded board")
    func ig024() {
        // dijkstraShortestPath(from: P(0, 0), successors: knight1, success: { $0 == P(7, 7) }) / (distance, path.count) → (6, 7)
        struct P: Hashable {
            var x, y: Int
        }
        let knight1 = { (p: P) -> [(P, Int)] in
            [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)].map { (P(x: p.x + $0.0, y: p.y + $0.1), 1) }
        }
        let result = dijkstraShortestPath(from: P(x: 0, y: 0), successors: knight1, success: { $0 == P(x: 7, y: 7) })
        #expect(result?.distance == 6)
        #expect(result?.path.count == 7)
        let path = result!.path
        #expect(path.first == P(x: 0, y: 0) && path.last == P(x: 7, y: 7))
        var cost = 0
        for (a, b) in zip(path, path.dropFirst()) {
            let step = knight1(a).first { $0.0 == b }
            #expect(step != nil)
            cost += step?.1 ?? 0
        }
        #expect(cost == 6)
    }

    @Test("IG-025 D19 A*: the same, with the admissible knight bound")
    func ig025() {
        // aStarShortestPath(from: P(0, 0), successors: knight1, heuristic: knightBound, success: { $0 == P(7, 7) }) / (distance, path.count) → (6, 7)
        struct P: Hashable {
            var x, y: Int
        }
        let knight1 = { (p: P) -> [(P, Int)] in
            [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)].map { (P(x: p.x + $0.0, y: p.y + $0.1), 1) }
        }
        // Admissible: a knight move changes one coordinate by at most 2 and the sum by at most 3.
        let knightBound = { (p: P) -> Int in
            max((abs(7 - p.x) + 1) / 2, (abs(7 - p.y) + 1) / 2, (abs(7 - p.x) + abs(7 - p.y) + 2) / 3)
        }
        let result = aStarShortestPath(from: P(x: 0, y: 0), successors: knight1, heuristic: knightBound, success: { $0 == P(x: 7, y: 7) })
        #expect(result?.distance == 6)
        #expect(result?.path.count == 7)
        let path = result!.path
        #expect(path.first == P(x: 0, y: 0) && path.last == P(x: 7, y: 7))
        var cost = 0
        for (a, b) in zip(path, path.dropFirst()) {
            let step = knight1(a).first { $0.0 == b }
            #expect(step != nil)
            cost += step?.1 ?? 0
        }
        #expect(cost == 6)
    }

    @Test("IG-026 D19 Dijkstra: unbounded grid, entering (x, y) costs 1 + (x² + y) mod 3")
    func ig026() {
        // dijkstraShortestPath(from: P(0, 0), successors: costly, success: { $0 == P(4, -3) }) / distance → 12
        struct P: Hashable {
            var x, y: Int
        }
        // Entering (x, y) costs 1 + (x² + y) mod 3, the mod taken non-negative.
        let costly = { (p: P) -> [(P, Int)] in
            [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)].map { q in
                (q, 1 + ((q.x * q.x + q.y) % 3 + 3) % 3)
            }
        }
        let result = dijkstraShortestPath(from: P(x: 0, y: 0), successors: costly, success: { $0 == P(x: 4, y: -3) })
        #expect(result?.distance == 12)
        let path = result!.path
        #expect(path.first == P(x: 0, y: 0) && path.last == P(x: 4, y: -3))
        var cost = 0
        for (a, b) in zip(path, path.dropFirst()) {
            let step = costly(a).first { $0.0 == b }
            #expect(step != nil)
            cost += step?.1 ?? 0
        }
        #expect(cost == 12)
    }

    @Test("IG-027 D19 A*: the same with Manhattan distance (admissible: every step costs ≥ 1)")
    func ig027() {
        // aStarShortestPath(from: P(0, 0), successors: costly, heuristic: manhattan(to: P(4, -3)), success: { $0 == P(4, -3) }) / distance → 12
        struct P: Hashable {
            var x, y: Int
        }
        // Entering (x, y) costs 1 + (x² + y) mod 3, the mod taken non-negative.
        let costly = { (p: P) -> [(P, Int)] in
            [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)].map { q in
                (q, 1 + ((q.x * q.x + q.y) % 3 + 3) % 3)
            }
        }
        let manhattan = { (p: P) -> Int in abs(4 - p.x) + abs(-3 - p.y) }
        let result = aStarShortestPath(from: P(x: 0, y: 0), successors: costly, heuristic: manhattan, success: { $0 == P(x: 4, y: -3) })
        #expect(result?.distance == 12)
        let path = result!.path
        #expect(path.first == P(x: 0, y: 0) && path.last == P(x: 4, y: -3))
        var cost = 0
        for (a, b) in zip(path, path.dropFirst()) {
            let step = costly(a).first { $0.0 == b }
            #expect(step != nil)
            cost += step?.1 ?? 0
        }
        #expect(cost == 12)
    }

    @Test("IG-028 D19: the start satisfies success")
    func ig028() {
        // dijkstraShortestPath(from: 3, successors: { [($0 + 1, 1)] }, success: { $0 == 3 }) / (distance, path.count) → (0, 1)
        var calls = 0
        let result = dijkstraShortestPath(from: 3, successors: { (v: Int) -> [(Int, Int)] in
            calls += 1
            return [(v + 1, 1)]
        }, success: { $0 == 3 })
        #expect(result?.distance == 0 && result?.path == [3])
        // The start is tested before it is expanded.
        #expect(calls == 0)
    }

    @Test("IG-029 D19: a finite space with no goal returns nil")
    func ig029() {
        // dijkstraShortestPath(from: 0, successors: { $0 < 10 ? [($0 + 1, 1)] : [] }, success: { $0 == 20 }) / (distance, path.count) → nil
        var expanded: [Int] = []
        let result = dijkstraShortestPath(from: 0, successors: { (v: Int) -> [(Int, Int)] in
            expanded.append(v)
            return v < 10 ? [(v + 1, 1)] : []
        }, success: { $0 == 20 })
        #expect(result == nil)
        // Every reachable state is expanded once, nearest first.
        #expect(expanded == Array(0 ... 10))
    }

    @Test("IG-030 D19 Dijkstra: a step from p to q costs 1 + (p.x · q.y) mod 3, so the goal's first push is not its distance")
    func ig030() {
        // dijkstraShortestPath(from: P(0, 0), successors: twoEnded, success: { $0 == P(-4, 4) }) / distance → 8
        struct P: Hashable {
            var x, y: Int
        }
        // A step from p to q costs 1 + (p.x · q.y) mod 3, the mod taken non-negative: the cost
        // depends on both ends, so the goal's first push is not its distance.
        let twoEnded = { (p: P) -> [(P, Int)] in
            [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)].map { q in
                (q, 1 + ((p.x * q.y) % 3 + 3) % 3)
            }
        }
        let result = dijkstraShortestPath(from: P(x: 0, y: 0), successors: twoEnded, success: { $0 == P(x: -4, y: 4) })
        #expect(result?.distance == 8)
        let path = result!.path
        #expect(path.first == P(x: 0, y: 0) && path.last == P(x: -4, y: 4))
        var cost = 0
        for (a, b) in zip(path, path.dropFirst()) {
            let step = twoEnded(a).first { $0.0 == b }
            #expect(step != nil)
            cost += step?.1 ?? 0
        }
        #expect(cost == 8)
    }

    @Test("IG-031 D19 A*: the same with Manhattan distance")
    func ig031() {
        // aStarShortestPath(from: P(0, 0), successors: twoEnded, heuristic: manhattan(to: P(-4, 4)), success: { $0 == P(-4, 4) }) / distance → 8
        struct P: Hashable {
            var x, y: Int
        }
        // A step from p to q costs 1 + (p.x · q.y) mod 3, the mod taken non-negative: the cost
        // depends on both ends, so the goal's first push is not its distance.
        let twoEnded = { (p: P) -> [(P, Int)] in
            [P(x: p.x, y: p.y - 1), P(x: p.x - 1, y: p.y), P(x: p.x + 1, y: p.y), P(x: p.x, y: p.y + 1)].map { q in
                (q, 1 + ((p.x * q.y) % 3 + 3) % 3)
            }
        }
        let manhattan = { (p: P) -> Int in abs(-4 - p.x) + abs(4 - p.y) }
        let result = aStarShortestPath(from: P(x: 0, y: 0), successors: twoEnded, heuristic: manhattan, success: { $0 == P(x: -4, y: 4) })
        #expect(result?.distance == 8)
        let path = result!.path
        #expect(path.first == P(x: 0, y: 0) && path.last == P(x: -4, y: 4))
        var cost = 0
        for (a, b) in zip(path, path.dropFirst()) {
            let step = twoEnded(a).first { $0.0 == b }
            #expect(step != nil)
            cost += step?.1 ?? 0
        }
        #expect(cost == 8)
    }
}
