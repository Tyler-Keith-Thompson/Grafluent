// fruchtermanReingoldLayout (catalog DR-166 – DR-188): the start (x then y per vertex, top 53 bits of
// one draw each, exactly 2n draws) exactly; the stepper; the two-vertex equilibrium; and quality as
// the median over seeds 1…20 of Xoshiro256StarStar of normalized stress or crossings, computed
// inline from `positions`, against the catalog's bound.
// Generated from cases.md by swiftgen.py; see README.md.

import GrafluentTestSupport
import GraphDrawing
import GraphProtocols
import Multigraphs
import RandomGraphs
import Testing

@Suite("fruchtermanReingoldLayout")
struct FruchtermanReingoldLayoutTests {
    @Test("DR-166 initial positions: x then y per vertex, uniform in [0, 1), seed 1")
    func dr166() {
        // U: n=3;; fruchtermanReingoldLayout(iterations: 0, using: &Xoshiro256StarStar(seed: 1)) → [(0.7029218331588505, 0.5204366199388569), (0.5741057000197225, 0.39132860204190445), (0.6971784165599615, 0.1435720367444362)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 0)
        var generator = Xoshiro256StarStar(seed: 1)
        let layout = graph.fruchtermanReingoldLayout(iterations: 0, using: &generator)
        #expect(Array(layout.vertices) == Array(0 ..< 3))
        #expect(layout.positions == [SIMD2(0.7029218331588505, 0.5204366199388569), SIMD2(0.5741057000197225, 0.39132860204190445),
            SIMD2(0.6971784165599615, 0.1435720367444362)])
        // Exactly 2n draws: the generator is where a fresh one is after 6 draws.
        var fresh = Xoshiro256StarStar(seed: 1)
        for _ in 0 ..< 6 { _ = fresh.next() }
        #expect(generator == fresh)
        // The same start through the stepper, and through `initial:` with no iterations.
        var again = Xoshiro256StarStar(seed: 1)
        let stepper = FruchtermanReingoldLayout(graph, iterations: 0, using: &again)
        #expect(stepper.drawing.positions == layout.positions && stepper.isFinished && stepper.iteration == 0)
        #expect(graph.fruchtermanReingoldLayout(initial: stepper.drawing, iterations: 0) == stepper.drawing)
    }

    @Test("DR-167 initial positions: exactly 2n draws, seed 1")
    func dr167() {
        // U: n=3;; draws by fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: 1)) → #6
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 0)
        struct Counting: RandomNumberGenerator {
            var base: Xoshiro256StarStar
            var draws = 0
            mutating func next() -> UInt64 {
                draws += 1
                return base.next()
            }
        }
        var generator = Counting(base: Xoshiro256StarStar(seed: 1))
        _ = graph.fruchtermanReingoldLayout(using: &generator)
        #expect(generator.draws == 6)
        var stepperGenerator = Counting(base: Xoshiro256StarStar(seed: 1))
        var stepper = FruchtermanReingoldLayout(graph, using: &stepperGenerator)
        #expect(stepperGenerator.draws == 6)
        stepper.run()
        #expect(stepperGenerator.draws == 6)
    }

    @Test("DR-168 initial positions: x then y per vertex, uniform in [0, 1), seed 42")
    func dr168() {
        // U: n=5;; fruchtermanReingoldLayout(iterations: 0, using: &Xoshiro256StarStar(seed: 42)) → [(0.08386297105988216, 0.3789802506626686), (0.6800434110281394, 0.9246929453253876), (0.9918039142821028, 0.7697394604342425), (0.7192585778779156, 0.8500084439109727), (0.7613743810057634, 0.5833493097373993)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 0)
        var generator = Xoshiro256StarStar(seed: 42)
        let layout = graph.fruchtermanReingoldLayout(iterations: 0, using: &generator)
        #expect(Array(layout.vertices) == Array(0 ..< 5))
        #expect(layout.positions == [SIMD2(0.08386297105988216, 0.3789802506626686), SIMD2(0.6800434110281394, 0.9246929453253876),
            SIMD2(0.9918039142821028, 0.7697394604342425), SIMD2(0.7192585778779156, 0.8500084439109727), SIMD2(0.7613743810057634, 0.5833493097373993)])
        // Exactly 2n draws: the generator is where a fresh one is after 10 draws.
        var fresh = Xoshiro256StarStar(seed: 42)
        for _ in 0 ..< 10 { _ = fresh.next() }
        #expect(generator == fresh)
        // The same start through the stepper, and through `initial:` with no iterations.
        var again = Xoshiro256StarStar(seed: 42)
        let stepper = FruchtermanReingoldLayout(graph, iterations: 0, using: &again)
        #expect(stepper.drawing.positions == layout.positions && stepper.isFinished && stepper.iteration == 0)
        #expect(graph.fruchtermanReingoldLayout(initial: stepper.drawing, iterations: 0) == stepper.drawing)
    }

    @Test("DR-169 initial positions: exactly 2n draws, seed 42")
    func dr169() {
        // U: n=5;; draws by fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: 42)) → #10
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 0)
        struct Counting: RandomNumberGenerator {
            var base: Xoshiro256StarStar
            var draws = 0
            mutating func next() -> UInt64 {
                draws += 1
                return base.next()
            }
        }
        var generator = Counting(base: Xoshiro256StarStar(seed: 42))
        _ = graph.fruchtermanReingoldLayout(using: &generator)
        #expect(generator.draws == 10)
        var stepperGenerator = Counting(base: Xoshiro256StarStar(seed: 42))
        var stepper = FruchtermanReingoldLayout(graph, using: &stepperGenerator)
        #expect(stepperGenerator.draws == 10)
        stepper.run()
        #expect(stepperGenerator.draws == 10)
    }

    @Test("DR-170 empty graph: empty drawing, no draws")
    func dr170() {
        // U: n=0;; fruchtermanReingoldLayout(using: &g) → [] (#0 draws)
        let graph = Pseudograph<Int>(vertices: 0 ..< 0, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 0) && graph.edgeCount == 0)
        struct Counting: RandomNumberGenerator {
            var base: Xoshiro256StarStar
            var draws = 0
            mutating func next() -> UInt64 {
                draws += 1
                return base.next()
            }
        }
        var generator = Counting(base: Xoshiro256StarStar(seed: 1))
        let layout = graph.fruchtermanReingoldLayout(using: &generator)
        #expect(layout.isEmpty && layout == Drawing<Int>() && generator.draws == 0)
        var stepper = FruchtermanReingoldLayout(graph, using: &generator)
        stepper.run()
        #expect(stepper.drawing.isEmpty && stepper.isFinished && generator.draws == 0)
    }

    @Test("DR-171 one vertex: stays at its initial position")
    func dr171() {
        // U: n=1;; fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: 1)) → [(0.7029218331588505, 0.5204366199388569)]
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 1) && graph.edgeCount == 0)
        var generator = Xoshiro256StarStar(seed: 1)
        let layout = graph.fruchtermanReingoldLayout(using: &generator)
        #expect(Array(layout.vertices) == Array(0 ..< 1))
        #expect(layout.positions == [SIMD2(0.7029218331588505, 0.5204366199388569)])
        // Exactly 2n draws: the generator is where a fresh one is after 2 draws.
        var fresh = Xoshiro256StarStar(seed: 1)
        for _ in 0 ..< 2 { _ = fresh.next() }
        #expect(generator == fresh)
        // The same start through the stepper, and through `initial:` with no iterations.
        var again = Xoshiro256StarStar(seed: 1)
        let stepper = FruchtermanReingoldLayout(graph, iterations: 0, using: &again)
        #expect(stepper.drawing.positions == [SIMD2(0.7029218331588505, 0.5204366199388569)] && stepper.isFinished && stepper.iteration == 0)
        #expect(graph.fruchtermanReingoldLayout(initial: stepper.drawing, iterations: 0) == stepper.drawing)
    }

    @Test("DR-172 same seed, same drawing", .tags(.randomized))
    func dr172() {
        // U: grid(5,5); two calls with Xoshiro256StarStar(seed: 9) → equal
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        var first = Xoshiro256StarStar(seed: 9), second = Xoshiro256StarStar(seed: 9)
        let a = graph.fruchtermanReingoldLayout(using: &first)
        let b = graph.fruchtermanReingoldLayout(using: &second)
        #expect(a == b && first == second)
        #expect(a.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite })
        var third = Xoshiro256StarStar(seed: 9)
        var stepper = FruchtermanReingoldLayout(graph, using: &third)
        stepper.run()
        #expect(stepper.drawing == a)
    }

    @Test("DR-174 step() after the last iteration changes nothing")
    func dr174() {
        // U: P(0,1,2); FruchtermanReingoldLayout(iterations: 2): step() x 3 → isFinished; drawing equal after steps 2 and 3
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 2)
        var generator = Xoshiro256StarStar(seed: 1)
        var layout = FruchtermanReingoldLayout(graph, iterations: 2, using: &generator)
        #expect(!layout.isFinished && layout.iteration == 0)
        layout.step()
        let afterOne = layout.drawing
        layout.step()
        #expect(layout.isFinished && layout.iteration == 2)
        let afterTwo = layout.drawing
        #expect(afterOne != afterTwo)
        let temperature = layout.temperature
        layout.step()
        #expect(layout.drawing == afterTwo && layout.iteration == 2 && layout.temperature == temperature)
        layout.run()
        #expect(layout.drawing == afterTwo && layout.isFinished)
    }

    @Test("DR-175 step() count: iterations steps, or fewer when converged", .tags(.randomized))
    func dr175() {
        // U: grid(5,5); FruchtermanReingoldLayout(iterations: 50).iteration after run → ≤ 50
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        var generator = Xoshiro256StarStar(seed: 1)
        var layout = FruchtermanReingoldLayout(graph, iterations: 50, using: &generator)
        var temperatures = [layout.temperature]
        var steps = 0
        while !layout.isFinished {
            layout.step()
            steps += 1
            temperatures.append(layout.temperature)
        }
        #expect(layout.iteration <= 50 && layout.iteration == steps && layout.iteration >= 1)
        // The temperature falls by the same amount each step (t₀ / (iterations + 1)).
        let drop = temperatures[0] - temperatures[1]
        #expect(drop > 0 && zip(temperatures, temperatures.dropFirst()).allSatisfy { abs(($0 - $1) - drop) <= 1e-12 })
        #expect(abs(drop - temperatures[0] / 51) <= 1e-12)
        var again = Xoshiro256StarStar(seed: 1)
        #expect(graph.fruchtermanReingoldLayout(iterations: 50, using: &again) == layout.drawing)
    }

    @Test("DR-177 two vertices joined by an edge end at distance k (the optimal distance)")
    func dr177() {
        // U: 0-1; fruchtermanReingoldLayout(iterations: 500, optimalDistance: 1, using: &Xoshiro256StarStar(seed: 1)) distance → 1.0 ± 1e-3
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 1)
        var generator = Xoshiro256StarStar(seed: 1)
        let layout = graph.fruchtermanReingoldLayout(iterations: 500, optimalDistance: 1, using: &generator)
        let delta = layout.positions[0] - layout.positions[1]
        #expect(abs((delta * delta).sum().squareRoot() - 1) <= 1e-3)
    }

    @Test("DR-178 Fruchterman–Reingold quality, cycle C12 (median normalized stress over seeds 1…20; NetworkX 0.0171, model 0.0173)", .tags(.randomized))
    func dr178() {
        // U: C(0,1,2,3,4,5,6,7,8,9,10,11); fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s)) → ≤ 0.019
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(7, 8), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11), UndirectedEdge(11, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 12)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            let layout = graph.fruchtermanReingoldLayout(using: &generator)
            values.append(normalizedStress(layout.positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.019, "median normalized stress \(median)")
    }

    @Test("DR-179 Fruchterman–Reingold quality, grid 5 x 5 (median normalized stress over seeds 1…20; NetworkX 0.0243, model 0.0251)", .tags(.randomized))
    func dr179() {
        // U: grid(5,5); fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s)) → ≤ 0.027
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            let layout = graph.fruchtermanReingoldLayout(using: &generator)
            values.append(normalizedStress(layout.positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.027, "median normalized stress \(median)")
    }

    @Test("DR-180 Fruchterman–Reingold quality, binary tree of height 4 (as a graph) (median normalized stress over seeds 1…20; NetworkX 0.0848, model 0.0830)", .tags(.randomized))
    func dr180() {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 2-6, 3-7, 3-8, 4-9, 4-10, 5-11, 5-12, 6-13, 6-14, 7-15, 7-16, 8-17, 8-18, 9-19, 9-20, 10-21, 10-22, 11-23, 11-24, 12-25, 12-26, 13-27, 13-28, 14-29, 14-30; fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s)) → ≤ 0.094
        let graph = Pseudograph<Int>(vertices: 0 ..< 31, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(2, 5), UndirectedEdge(2, 6), UndirectedEdge(3, 7), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(4, 10),
            UndirectedEdge(5, 11), UndirectedEdge(5, 12), UndirectedEdge(6, 13), UndirectedEdge(6, 14), UndirectedEdge(7, 15), UndirectedEdge(7, 16),
            UndirectedEdge(8, 17), UndirectedEdge(8, 18), UndirectedEdge(9, 19), UndirectedEdge(9, 20), UndirectedEdge(10, 21), UndirectedEdge(10, 22),
            UndirectedEdge(11, 23), UndirectedEdge(11, 24), UndirectedEdge(12, 25), UndirectedEdge(12, 26), UndirectedEdge(13, 27), UndirectedEdge(13, 28),
            UndirectedEdge(14, 29), UndirectedEdge(14, 30)])
        #expect(Array(graph.vertices) == Array(0 ..< 31) && graph.edgeCount == 30)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            let layout = graph.fruchtermanReingoldLayout(using: &generator)
            values.append(normalizedStress(layout.positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.094, "median normalized stress \(median)")
    }

    @Test("DR-181 Fruchterman–Reingold quality, cube Q4 (median normalized stress over seeds 1…20; NetworkX 0.1289, model 0.1286)", .tags(.randomized))
    func dr181() {
        // U: Q(4); fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s)) → ≤ 0.142
        let graph = Pseudograph<Int>(vertices: 0 ..< 16, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 4), UndirectedEdge(0, 8),
            UndirectedEdge(1, 3), UndirectedEdge(1, 5), UndirectedEdge(1, 9), UndirectedEdge(2, 3), UndirectedEdge(2, 6), UndirectedEdge(2, 10),
            UndirectedEdge(3, 7), UndirectedEdge(3, 11), UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 12), UndirectedEdge(5, 7),
            UndirectedEdge(5, 13), UndirectedEdge(6, 7), UndirectedEdge(6, 14), UndirectedEdge(7, 15), UndirectedEdge(8, 9), UndirectedEdge(8, 10),
            UndirectedEdge(8, 12), UndirectedEdge(9, 11), UndirectedEdge(9, 13), UndirectedEdge(10, 11), UndirectedEdge(10, 14), UndirectedEdge(11, 15),
            UndirectedEdge(12, 13), UndirectedEdge(12, 14), UndirectedEdge(13, 15), UndirectedEdge(14, 15)])
        #expect(Array(graph.vertices) == Array(0 ..< 16) && graph.edgeCount == 32)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            let layout = graph.fruchtermanReingoldLayout(using: &generator)
            values.append(normalizedStress(layout.positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.142, "median normalized stress \(median)")
    }

    @Test("DR-182 Fruchterman–Reingold quality, Petersen (median normalized stress over seeds 1…20; NetworkX 0.1212, model 0.1213)", .tags(.randomized))
    func dr182() {
        // U: petersen; fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s)) → ≤ 0.134
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 0), UndirectedEdge(0, 5), UndirectedEdge(1, 6), UndirectedEdge(2, 7), UndirectedEdge(3, 8), UndirectedEdge(4, 9),
            UndirectedEdge(5, 7), UndirectedEdge(6, 8), UndirectedEdge(7, 9), UndirectedEdge(8, 5), UndirectedEdge(9, 6)])
        #expect(Array(graph.vertices) == Array(0 ..< 10) && graph.edgeCount == 15)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            let layout = graph.fruchtermanReingoldLayout(using: &generator)
            values.append(normalizedStress(layout.positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.134, "median normalized stress \(median)")
    }

    @Test("DR-183 Fruchterman–Reingold quality, random graph, 40 vertices, 60 edges (median normalized stress over seeds 1…20; NetworkX 0.1022, model 0.1029)", .tags(.randomized))
    func dr183() {
        // U: lcggraph(40,60,5); fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s)) → ≤ 0.113
        let graph = Pseudograph<Int>(vertices: 0 ..< 40, edges: [UndirectedEdge(32, 13), UndirectedEdge(34, 5), UndirectedEdge(15, 11),
            UndirectedEdge(19, 29), UndirectedEdge(10, 24), UndirectedEdge(35, 34), UndirectedEdge(28, 11), UndirectedEdge(33, 37), UndirectedEdge(28, 23),
            UndirectedEdge(2, 20), UndirectedEdge(30, 24), UndirectedEdge(8, 2), UndirectedEdge(21, 14), UndirectedEdge(1, 14), UndirectedEdge(9, 19),
            UndirectedEdge(10, 9), UndirectedEdge(35, 33), UndirectedEdge(35, 13), UndirectedEdge(25, 29), UndirectedEdge(20, 1), UndirectedEdge(14, 38),
            UndirectedEdge(30, 4), UndirectedEdge(14, 36), UndirectedEdge(28, 34), UndirectedEdge(32, 20), UndirectedEdge(7, 16), UndirectedEdge(30, 10),
            UndirectedEdge(31, 17), UndirectedEdge(1, 12), UndirectedEdge(21, 5), UndirectedEdge(14, 36), UndirectedEdge(31, 38), UndirectedEdge(12, 10),
            UndirectedEdge(35, 39), UndirectedEdge(31, 32), UndirectedEdge(28, 9), UndirectedEdge(11, 12), UndirectedEdge(12, 21), UndirectedEdge(38, 0),
            UndirectedEdge(14, 35), UndirectedEdge(27, 1), UndirectedEdge(7, 21), UndirectedEdge(7, 22), UndirectedEdge(2, 17), UndirectedEdge(8, 6),
            UndirectedEdge(14, 25), UndirectedEdge(8, 31), UndirectedEdge(17, 14), UndirectedEdge(26, 15), UndirectedEdge(1, 23), UndirectedEdge(29, 30),
            UndirectedEdge(7, 23), UndirectedEdge(35, 38), UndirectedEdge(33, 7), UndirectedEdge(28, 3), UndirectedEdge(11, 25), UndirectedEdge(29, 15),
            UndirectedEdge(23, 18), UndirectedEdge(23, 2), UndirectedEdge(4, 13)])
        #expect(Array(graph.vertices) == Array(0 ..< 40) && graph.edgeCount == 60)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            let layout = graph.fruchtermanReingoldLayout(using: &generator)
            values.append(normalizedStress(layout.positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.113, "median normalized stress \(median)")
    }

    @Test("DR-184 Fruchterman–Reingold crossings, cycle C12 (median over seeds 1…20; NetworkX 0, model 0)", .tags(.randomized))
    func dr184() {
        // U: C(0,1,2,3,4,5,6,7,8,9,10,11); fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s)) → ≤ 0
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(7, 8), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11), UndirectedEdge(11, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 12)
        // Pairs of non-loop edges with four distinct endpoints whose segments cross properly.
        func crossings(_ p: [SIMD2<Double>]) -> Int {
            let segments = graph.edges.filter { $0.u != $0.v }.map { ($0.u, $0.v) }
            func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Int {
                let v = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
                return abs(v) < 1e-12 ? 0 : (v > 0 ? 1 : -1)
            }
            var total = 0
            for i in 0 ..< segments.count {
                for j in i + 1 ..< segments.count {
                    let (a, b) = segments[i], (c, e) = segments[j]
                    if Set([a, b, c, e]).count < 4 { continue }
                    if orientation(p[a], p[b], p[c]) * orientation(p[a], p[b], p[e]) < 0
                        && orientation(p[c], p[e], p[a]) * orientation(p[c], p[e], p[b]) < 0 {
                        total += 1
                    }
                }
            }
            return total
        }
        var values: [Int] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            values.append(crossings(graph.fruchtermanReingoldLayout(using: &generator).positions))
        }
        let sorted = values.sorted()
        let median = Double(sorted[9] + sorted[10]) / 2
        #expect(median <= 0, "median crossings \(median)")
    }

    @Test("DR-185 Fruchterman–Reingold crossings, binary tree of height 4 (median over seeds 1…20; NetworkX 1, model 1)", .tags(.randomized))
    func dr185() {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 2-6, 3-7, 3-8, 4-9, 4-10, 5-11, 5-12, 6-13, 6-14, 7-15, 7-16, 8-17, 8-18, 9-19, 9-20, 10-21, 10-22, 11-23, 11-24, 12-25, 12-26, 13-27, 13-28, 14-29, 14-30; fruchtermanReingoldLayout(using: &Xoshiro256StarStar(seed: s)) → ≤ 1
        let graph = Pseudograph<Int>(vertices: 0 ..< 31, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(2, 5), UndirectedEdge(2, 6), UndirectedEdge(3, 7), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(4, 10),
            UndirectedEdge(5, 11), UndirectedEdge(5, 12), UndirectedEdge(6, 13), UndirectedEdge(6, 14), UndirectedEdge(7, 15), UndirectedEdge(7, 16),
            UndirectedEdge(8, 17), UndirectedEdge(8, 18), UndirectedEdge(9, 19), UndirectedEdge(9, 20), UndirectedEdge(10, 21), UndirectedEdge(10, 22),
            UndirectedEdge(11, 23), UndirectedEdge(11, 24), UndirectedEdge(12, 25), UndirectedEdge(12, 26), UndirectedEdge(13, 27), UndirectedEdge(13, 28),
            UndirectedEdge(14, 29), UndirectedEdge(14, 30)])
        #expect(Array(graph.vertices) == Array(0 ..< 31) && graph.edgeCount == 30)
        // Pairs of non-loop edges with four distinct endpoints whose segments cross properly.
        func crossings(_ p: [SIMD2<Double>]) -> Int {
            let segments = graph.edges.filter { $0.u != $0.v }.map { ($0.u, $0.v) }
            func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Int {
                let v = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
                return abs(v) < 1e-12 ? 0 : (v > 0 ? 1 : -1)
            }
            var total = 0
            for i in 0 ..< segments.count {
                for j in i + 1 ..< segments.count {
                    let (a, b) = segments[i], (c, e) = segments[j]
                    if Set([a, b, c, e]).count < 4 { continue }
                    if orientation(p[a], p[b], p[c]) * orientation(p[a], p[b], p[e]) < 0
                        && orientation(p[c], p[e], p[a]) * orientation(p[c], p[e], p[b]) < 0 {
                        total += 1
                    }
                }
            }
            return total
        }
        var values: [Int] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            values.append(crossings(graph.fruchtermanReingoldLayout(using: &generator).positions))
        }
        let sorted = values.sorted()
        let median = Double(sorted[9] + sorted[10]) / 2
        #expect(median <= 1, "median crossings \(median)")
    }

    @Test("DR-186 Barnes–Hut (θ = 1.2) within 15% of exact repulsion, grid 5 x 5 (exact model 0.0251)", .tags(.randomized))
    func dr186() {
        // U: grid(5,5); fruchtermanReingoldLayout(barnesHutTheta: 1.2, using: &Xoshiro256StarStar(seed: s)), median → ≤ 0.029
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            let layout = graph.fruchtermanReingoldLayout(barnesHutTheta: 1.2, using: &generator)
            values.append(normalizedStress(layout.positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.029, "median normalized stress \(median)")
    }

    @Test("DR-187 Barnes–Hut (θ = 1.2) within 15% of exact repulsion, random graph, 40 vertices, 60 edges (exact model 0.1029)", .tags(.randomized))
    func dr187() {
        // U: lcggraph(40,60,5); fruchtermanReingoldLayout(barnesHutTheta: 1.2, using: &Xoshiro256StarStar(seed: s)), median → ≤ 0.119
        let graph = Pseudograph<Int>(vertices: 0 ..< 40, edges: [UndirectedEdge(32, 13), UndirectedEdge(34, 5), UndirectedEdge(15, 11),
            UndirectedEdge(19, 29), UndirectedEdge(10, 24), UndirectedEdge(35, 34), UndirectedEdge(28, 11), UndirectedEdge(33, 37), UndirectedEdge(28, 23),
            UndirectedEdge(2, 20), UndirectedEdge(30, 24), UndirectedEdge(8, 2), UndirectedEdge(21, 14), UndirectedEdge(1, 14), UndirectedEdge(9, 19),
            UndirectedEdge(10, 9), UndirectedEdge(35, 33), UndirectedEdge(35, 13), UndirectedEdge(25, 29), UndirectedEdge(20, 1), UndirectedEdge(14, 38),
            UndirectedEdge(30, 4), UndirectedEdge(14, 36), UndirectedEdge(28, 34), UndirectedEdge(32, 20), UndirectedEdge(7, 16), UndirectedEdge(30, 10),
            UndirectedEdge(31, 17), UndirectedEdge(1, 12), UndirectedEdge(21, 5), UndirectedEdge(14, 36), UndirectedEdge(31, 38), UndirectedEdge(12, 10),
            UndirectedEdge(35, 39), UndirectedEdge(31, 32), UndirectedEdge(28, 9), UndirectedEdge(11, 12), UndirectedEdge(12, 21), UndirectedEdge(38, 0),
            UndirectedEdge(14, 35), UndirectedEdge(27, 1), UndirectedEdge(7, 21), UndirectedEdge(7, 22), UndirectedEdge(2, 17), UndirectedEdge(8, 6),
            UndirectedEdge(14, 25), UndirectedEdge(8, 31), UndirectedEdge(17, 14), UndirectedEdge(26, 15), UndirectedEdge(1, 23), UndirectedEdge(29, 30),
            UndirectedEdge(7, 23), UndirectedEdge(35, 38), UndirectedEdge(33, 7), UndirectedEdge(28, 3), UndirectedEdge(11, 25), UndirectedEdge(29, 15),
            UndirectedEdge(23, 18), UndirectedEdge(23, 2), UndirectedEdge(4, 13)])
        #expect(Array(graph.vertices) == Array(0 ..< 40) && graph.edgeCount == 60)
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        var values: [Double] = []
        for seed in UInt64(1) ... 20 {
            var generator = Xoshiro256StarStar(seed: seed)
            let layout = graph.fruchtermanReingoldLayout(barnesHutTheta: 1.2, using: &generator)
            values.append(normalizedStress(layout.positions))
        }
        let sorted = values.sorted()
        let median = (sorted[9] + sorted[10]) / 2
        #expect(median <= 0.119, "median normalized stress \(median)")
    }

    @Test("DR-188 Barnes–Hut θ = 0 is exact repulsion", .tags(.randomized))
    func dr188() {
        // U: grid(5,5); fruchtermanReingoldLayout(barnesHutTheta: 0, …) == fruchtermanReingoldLayout(…) → equal up to 1e-9
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        for seed in UInt64(1) ... 3 {
            var first = Xoshiro256StarStar(seed: seed), second = Xoshiro256StarStar(seed: seed)
            let exact = graph.fruchtermanReingoldLayout(using: &first)
            let tree = graph.fruchtermanReingoldLayout(barnesHutTheta: 0, using: &second)
            #expect(first == second && exact.vertices == tree.vertices)
            for (a, b) in zip(exact.positions, tree.positions) {
                #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
            }
        }
    }
}
