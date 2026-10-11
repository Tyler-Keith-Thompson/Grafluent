// Searches over successor closures on unbounded spaces (catalog IG-023 – IG-038): Traversal's
// breadthFirstSearch(from:depthLimit:successors:), and ShortestPaths D19's
// dijkstraShortestPath(from:cutoff:successors:success:) and aStarShortestPath(from:cutoff:
// successors:heuristic:success:), pinning distances and, with unit costs, path vertex counts;
// each path is checked step by step against the closure, since ties between equal paths are not
// pinned. Then the cutoff, reopening under an inconsistent heuristic, the closures' call counts,
// Double costs, zero costs and several goals, where paths are unique.
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

    @Test("IG-032 D19 cutoff, inclusive: each step costs 2, so the goal 3 (distance 6) is found under cutoff 6 and not under 5, and the search ends on the infinite line")
    func ig032() {
        // dijkstraShortestPath(from: 0, cutoff: 6, successors: line2, success: { $0 == 3 }) / (distance, path.count) / the same with cutoff: 5 / states expanded under cutoff 5 → (6, 4); nil; [0, 1, 2]
        let line2 = { (v: Int) -> [(Int, Int)] in [(v + 1, 2)] }
        let result = dijkstraShortestPath(from: 0, cutoff: 6, successors: line2, success: { $0 == 3 })
        // Inclusive: the goal at exactly the cutoff is found.
        #expect(result?.distance == 6 && result?.path == [0, 1, 2, 3])
        var expanded: [Int] = []
        let beyond = dijkstraShortestPath(from: 0, cutoff: 5, successors: { (v: Int) -> [(Int, Int)] in
            expanded.append(v)
            return line2(v)
        }, success: { $0 == 3 })
        #expect(beyond == nil)
        // The infinite line ends at the cutoff: 3, at 6, is dropped when 2 is expanded.
        #expect(expanded == [0, 1, 2])
    }

    @Test("IG-033 D19 cutoff below zero: only the start is reached, and it is still expanded")
    func ig033() {
        // dijkstraShortestPath(from: 0, cutoff: -1, successors: line2, success: { $0 == 0 }) / (distance, path.count) / the same with success: { $0 == 1 } / successors calls → (0, 1); nil; 1
        let line2 = { (v: Int) -> [(Int, Int)] in [(v + 1, 2)] }
        let atStart = dijkstraShortestPath(from: 0, cutoff: -1, successors: line2, success: { $0 == 0 })
        #expect(atStart?.distance == 0 && atStart?.path == [0])
        var calls = 0
        let result = dijkstraShortestPath(from: 0, cutoff: -1, successors: { (v: Int) -> [(Int, Int)] in
            calls += 1
            return line2(v)
        }, success: { $0 == 1 })
        #expect(result == nil)
        // The start is reached at zero and expanded; every step is beyond the cutoff.
        #expect(calls == 1)
    }

    @Test("IG-034 D19 cutoff under A*: it bounds the distance, so the costly grid's goal (12) is found under cutoff 12, not under 11, by A* and Dijkstra alike")
    func ig034() {
        // aStarShortestPath(from: P(0, 0), cutoff: 12, successors: costly, heuristic: manhattan(to: P(4, -3)), success: { $0 == P(4, -3) }) / distance / the same with cutoff: 11 / dijkstraShortestPath with cutoff: 11 → 12; nil; nil
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
        let result = aStarShortestPath(from: P(x: 0, y: 0), cutoff: 12, successors: costly, heuristic: manhattan, success: { $0 == P(x: 4, y: -3) })
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
        // The cutoff bounds the distance, not the distance plus the estimate: A* and Dijkstra agree.
        #expect(aStarShortestPath(from: P(x: 0, y: 0), cutoff: 11, successors: costly, heuristic: manhattan, success: { $0 == P(x: 4, y: -3) }) == nil)
        #expect(dijkstraShortestPath(from: P(x: 0, y: 0), cutoff: 11, successors: costly, success: { $0 == P(x: 4, y: -3) }) == nil)
    }

    @Test("IG-035 D19 A* with an admissible, inconsistent heuristic reopens C (3) and still answers 6; successors is called once per expansion and heuristic once per push")
    func ig035() {
        // aStarShortestPath(from: 0, successors: reopen, heuristic: { [0, 0, 4, 0, 0][$0] }, success: { $0 == 4 }) / (distance, path) / states expanded / heuristic calls / dijkstraShortestPath: states expanded → (6, [0, 2, 3, 4]); [0, 1, 3, 2, 3]; [0, 1, 2, 3, 4, 3, 4]; [0, 1, 2, 3]
        // S→A 1, S→B 2, A→C 3, B→C 1, C→G 3 on states 0…4 (S, A, B, C, G).
        let reopen = { (v: Int) -> [(Int, Int)] in [[(1, 1), (2, 2)], [(3, 3)], [(3, 1)], [(4, 3)], []][v] }
        var expanded: [Int] = []
        var estimated: [Int] = []
        let result = aStarShortestPath(from: 0, successors: { (v: Int) -> [(Int, Int)] in
            expanded.append(v)
            return reopen(v)
        }, heuristic: { (v: Int) -> Int in
            estimated.append(v)
            return [0, 0, 4, 0, 0][v]
        }, success: { $0 == 4 })
        #expect(result?.distance == 6 && result?.path == [0, 2, 3, 4])
        // h(B) = 4 is more than cost(B, C) + h(C) = 1, so C is expanded at 4 (through A) before B,
        // then again at 3 (through B): one successors call per expansion.
        #expect(expanded == [0, 1, 3, 2, 3])
        // One estimate per push: the start, A, B, C, G, then C and G again, shorter.
        #expect(estimated == [0, 1, 2, 3, 4, 3, 4])
        var settled: [Int] = []
        let plain = dijkstraShortestPath(from: 0, successors: { (v: Int) -> [(Int, Int)] in
            settled.append(v)
            return reopen(v)
        }, success: { $0 == 4 })
        #expect(plain?.distance == 6 && plain?.path == [0, 2, 3, 4])
        #expect(settled == [0, 1, 2, 3])
    }

    @Test("IG-036 D19 with Double costs")
    func ig036() {
        // dijkstraShortestPath(from: 0, successors: { $0 < 3 ? [($0 + 1, 0.5), ($0 + 2, 1.25)] : [] }, success: { $0 == 3 }) / (distance, path.count) / aStarShortestPath with heuristic: { Double(3 - $0) * 0.5 } → (1.5, 4); (1.5, 4)
        let halves = { (v: Int) -> [(Int, Double)] in v < 3 ? [(v + 1, 0.5), (v + 2, 1.25)] : [] }
        let result = dijkstraShortestPath(from: 0, successors: halves, success: { $0 == 3 })
        #expect(result?.distance == 1.5 && result?.path == [0, 1, 2, 3])
        let guided = aStarShortestPath(from: 0, successors: halves, heuristic: { Double(3 - $0) * 0.5 }, success: { $0 == 3 })
        #expect(guided?.distance == 1.5 && guided?.path == [0, 1, 2, 3])
    }

    @Test("IG-037 D19 zero-cost steps and a zero-cost cycle: each state is expanded once")
    func ig037() {
        // dijkstraShortestPath(from: 0, successors: zeroCycle, success: { $0 == 9 }) / (distance, path) / states expanded → (1, [0, 1, 2, 3, 9]); [0, 1, 2, 3]
        // 0→1→2→3→0 at cost 0, with 0→9 at 2 and 3→9 at 1.
        let zeroCycle = { (v: Int) -> [(Int, Int)] in [0: [(1, 0), (9, 2)], 1: [(2, 0)], 2: [(3, 0)], 3: [(0, 0), (9, 1)], 9: []][v]! }
        var expanded: [Int] = []
        let result = dijkstraShortestPath(from: 0, successors: { (v: Int) -> [(Int, Int)] in
            expanded.append(v)
            return zeroCycle(v)
        }, success: { $0 == 9 })
        #expect(result?.distance == 1 && result?.path == [0, 1, 2, 3, 9])
        // Coming back to 0 at cost 0 is no improvement, so nothing is expanded twice.
        #expect(expanded == [0, 1, 2, 3])
    }

    @Test("IG-038 D19 several goals: the nearest by cost (5, five steps), not by steps (-3, three steps costing 6)")
    func ig038() {
        // dijkstraShortestPath(from: 0, successors: { [($0 + 1, 1), ($0 - 1, 2)] }, success: { $0 == 5 || $0 == -3 }) / (distance, path) / aStarShortestPath with heuristic: { min(abs(5 - $0), abs(-3 - $0)) } → (5, [0, 1, 2, 3, 4, 5]); (5, [0, 1, 2, 3, 4, 5])
        let both = { (v: Int) -> [(Int, Int)] in [(v + 1, 1), (v - 1, 2)] }
        let result = dijkstraShortestPath(from: 0, successors: both, success: { $0 == 5 || $0 == -3 })
        #expect(result?.distance == 5 && result?.path == [0, 1, 2, 3, 4, 5])
        let guided = aStarShortestPath(from: 0, successors: both, heuristic: { min(abs(5 - $0), abs(-3 - $0)) }, success: { $0 == 5 || $0 == -3 })
        #expect(guided?.distance == 5 && guided?.path == [0, 1, 2, 3, 4, 5])
    }
}
