// GraphDrawing's layouts on random graphs, against their invariants. Vertices are a permutation of
// `0..<n` drawn from the input, or labels far from their offsets, listed in a random order.
//
// - Circular: one finite point per vertex in `vertices` order, at the radius from the centre.
// - Fruchterman–Reingold (exact and Barnes–Hut, random weights, a random or a given start with
//   coincident points, small and large scales): finite, one point per vertex in `vertices` order,
//   exactly 2n draws, the same drawing from the same generator state, `step()` by step equal to
//   `run()` and to the function, at most `iterations` steps, the temperature never negative.
// - Stress majorization (random edge lengths, several components): finite, deterministic, the
//   stress never increasing from step to step, stepping equal to the function.
// - Sugiyama (loops, parallel arcs, cycles): `reversedEdges` is `feedbackArcSet()` less its
//   self-loops; every edge points down once turned; one bend per inner layer, on that layer, from
//   source to target; least x 0; no two points of a layer closer than 1; `crossingCount` equal
//   to a count over the drawn segments; the total span at most that of longest-path layers on the
//   same acyclic orientation; each weakly connected component starting at layer 0; a second call
//   equal. With caller layers (up to huge numbers): layers and y as given, upward arcs reversed,
//   bends on exactly the non-empty layers between.
// - Reingold–Tilford: the root at (0, 0), y = depth, separation 1 per depth, parents centred over
//   their first and last child, children left to right; the circular form at radius = depth.
// - Drawing: `rescaled` finite with the mean at the centre.

import Cycles
import FuzzSupport
import GraphDrawing
import GraphProtocols
import Multigraphs
import Trees

/// SplitMix64, counting its draws.
struct Counting: RandomNumberGenerator {
    var state: UInt64
    var draws = 0
    mutating func next() -> UInt64 {
        draws += 1
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@main
enum FuzzGraphDrawing {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        switch input.int(below: 4) {
        case 0: undirected(&input)
        case 1: layered(&input)
        case 2: callerLayers(&input)
        default: tree(&input)
        }
    }

    static func finite(_ p: SIMD2<Double>) -> Bool { p.x.isFinite && p.y.isFinite }

    /// `n` vertex labels in a random order: a permutation of `0..<n`, or labels far from it.
    static func labels(_ n: Int, _ input: inout FuzzInput) -> [Int] {
        let far = input.int(below: 2) == 1
        var listed = Array(0 ..< n).map { far ? 1000 + 37 * $0 : $0 }
        for i in stride(from: n - 1, to: 0, by: -1) { listed.swapAt(i, input.int(below: i + 1)) }
        return listed
    }

    // MARK: - Undirected: circular, Fruchterman–Reingold, stress majorization

    static func undirected(_ input: inout FuzzInput) {
        let n = input.int(in: 0 ... 24)
        let listed = labels(n, &input)
        var pairs: [(Int, Int)] = []
        let edgeCount = n == 0 ? 0 : input.int(in: 0 ... 48)
        for _ in 0 ..< edgeCount { pairs.append((input.int(below: n), input.int(below: n))) }
        let graph = Pseudograph<Int>(vertices: listed, edges: pairs.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
        let context = "n = \(n), labels \(listed), edges \(pairs)"
        let order = Array(graph.vertices)

        // Circular.
        let radius = [0, 1, 2.5, 1e6][input.int(below: 4)]
        let circle = graph.circularLayout(radius: radius, center: SIMD2(1, -2))
        check(Array(circle.vertices) == order && circle.count == n, "circular: vertices \(context)")
        for (v, p) in circle {
            check(finite(p), "circular: \(v) at \(p), \(context)")
            let d = p - SIMD2(1, -2)
            let r = (d * d).sum().squareRoot()
            check(abs(r - (n == 1 ? 0 : radius)) <= 1e-9 * Swift.max(1, radius), "circular: \(v) at radius \(r), \(context)")
            check(circle.position(of: v) == p, "circular: position(of:) \(context)")
        }

        // Fruchterman–Reingold.
        let iterations = input.int(in: 0 ... 30)
        let theta: Double? = [nil, 0, 0.5, 1.2, 3][input.int(below: 5)]
        let weightTable = [1.0, 0, 0.5, 3]
        let weights = graph.edges.indices.map { _ in weightTable[input.int(below: 4)] }
        let weight: (Int) -> Double = { weights[$0] }
        let optimal: Double? = [nil, 1, 0.01, 50][input.int(below: 4)]
        let threshold = [1e-4, 0, 1][input.int(below: 3)]
        let seed = UInt64(input.byte()) << 8 | UInt64(input.byte())
        var g1 = Counting(state: seed), g2 = g1, g3 = g1
        let fr = graph.fruchtermanReingoldLayout(
            iterations: iterations, optimalDistance: optimal, threshold: threshold, barnesHutTheta: theta, weight: weight, using: &g1)
        check(g1.draws == 2 * n, "FR: \(g1.draws) draws, \(context)")
        check(Array(fr.vertices) == order, "FR: vertices \(context)")
        for (v, p) in fr { check(finite(p), "FR: \(v) at \(p), θ \(String(describing: theta)), \(context)") }
        var stepper = FruchtermanReingoldLayout(
            graph, iterations: iterations, optimalDistance: optimal, threshold: threshold, barnesHutTheta: theta, weight: weight, using: &g2)
        var steps = 0
        while !stepper.isFinished {
            check(stepper.temperature >= -1e-12, "FR: temperature \(stepper.temperature), \(context)")
            stepper.step()
            steps += 1
            check(stepper.iteration == steps && steps <= iterations, "FR: step count \(steps), \(context)")
        }
        stepper.step()
        check(stepper.iteration == steps, "FR: a finished layout stepped, \(context)")
        check(stepper.drawing == fr, "FR: stepped drawing differs, \(context)")
        let again = graph.fruchtermanReingoldLayout(
            iterations: iterations, optimalDistance: optimal, threshold: threshold, barnesHutTheta: theta, weight: weight, using: &g3)
        check(again == fr, "FR: not deterministic, \(context)")

        // From a given start: coincident points, small and large scales, labels in another order.
        let scale = [1.0, 1e-9, 1e6, 0][input.int(below: 4)]
        let start = Drawing(vertices: order.reversed(), positions: order.map { _ in SIMD2(Double(input.int(below: 3)), Double(input.int(below: 3))) * scale })
        let fromStart = graph.fruchtermanReingoldLayout(
            initial: start, iterations: iterations, optimalDistance: optimal, threshold: threshold, barnesHutTheta: theta, weight: weight)
        check(Array(fromStart.vertices) == order, "FR from a start: vertices \(context)")
        for (v, p) in fromStart { check(finite(p), "FR from a start: \(v) at \(p), scale \(scale), \(context)") }
        if iterations == 0 {
            for v in order { check(fromStart.position(of: v) == start.position(of: v), "FR with no iterations moved \(v), \(context)") }
        }
        check(
            fromStart == graph.fruchtermanReingoldLayout(
                initial: start, iterations: iterations, optimalDistance: optimal, threshold: threshold, barnesHutTheta: theta, weight: weight),
            "FR from a start: not deterministic, \(context)")

        // Stress majorization.
        let lengthTable = [1.0, 0.001, 0.5, 2, 7, 1000]
        let uniform = input.int(below: 2) == 0
        let lengths = graph.edges.indices.map { _ in uniform ? 1 : lengthTable[input.int(below: lengthTable.count)] }
        let length: (Int) -> Double = { lengths[$0] }
        let maxIterations = input.int(in: 0 ... 40)
        let tolerance = [1e-4, 0, 0.5][input.int(below: 3)]
        let useStart = input.int(below: 2) == 0
        var stress = StressMajorizationLayout(graph, initial: useStart ? start : nil, edgeLength: length, tolerance: tolerance, maxIterations: maxIterations)
        var previous = stress.stress
        check(previous.isFinite, "stress: start stress \(previous), \(context)")
        while !stress.isFinished {
            stress.step()
            let now = stress.stress
            check(now.isFinite && now <= previous * (1 + 1e-9) + 1e-9, "stress: rose from \(previous) to \(now) at step \(stress.iteration), \(context)")
            previous = now
        }
        check(stress.iteration <= maxIterations, "stress: \(stress.iteration) steps, \(context)")
        for (v, p) in stress.drawing { check(finite(p), "stress: \(v) at \(p), \(context)") }
        check(Array(stress.drawing.vertices) == order, "stress: vertices \(context)")
        let direct = graph.stressMajorizationLayout(initial: useStart ? start : nil, edgeLength: length, tolerance: tolerance, maxIterations: maxIterations)
        check(direct == stress.drawing, "stress: stepped drawing differs, \(context)")

        // Rescaling.
        let rescaled = fr.rescaled(scale: 3, center: SIMD2(5, 5))
        var mean = SIMD2<Double>.zero
        for p in rescaled.positions {
            check(finite(p), "rescaled: \(p), \(context)")
            mean += p
        }
        if n > 0 {
            mean /= Double(n)
            check(abs(mean.x - 5) <= 1e-6 && abs(mean.y - 5) <= 1e-6, "rescaled: mean \(mean), \(context)")
        }
    }

    // MARK: - Sugiyama

    static func layered(_ input: inout FuzzInput) {
        let n = input.int(in: 0 ... 16)
        let listed = labels(n, &input)
        var arcs: [(Int, Int)] = []
        let arcCount = n == 0 ? 0 : input.int(in: 0 ... 40)
        for _ in 0 ..< arcCount { arcs.append((input.int(below: n), input.int(below: n))) }
        let graph = DirectedPseudograph<Int>(vertices: listed, edges: arcs.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
        let maxIterations = input.int(in: 0 ... 12)
        let drawn = graph.sugiyamaLayout(maxIterations: maxIterations)
        let context = "labels \(listed), arcs \(arcs), maxIterations \(maxIterations)"
        let order = Array(graph.vertices)
        let offset = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        let s = graph.edges.indices.map { offset[graph.source(ofEdgeAt: $0)]! }
        let t = graph.edges.indices.map { offset[graph.target(ofEdgeAt: $0)]! }

        check(drawn.reversedEdges == graph.feedbackArcSet().filter { s[$0] != t[$0] }, "reversedEdges is not feedbackArcSet() less its loops: \(context)")
        let reversed = Set(drawn.reversedEdges)
        let layer = order.map { drawn.layer(of: $0) }
        check(layer.allSatisfy { $0 >= 0 }, "a negative layer: \(context)")
        check(drawn.layerCount == (layer.max() ?? -1) + 1, "layerCount \(drawn.layerCount): \(context)")
        let p = drawn.drawing.positions
        check(Array(drawn.drawing.vertices) == order, "vertices \(context)")
        check((0 ..< n).allSatisfy { finite(p[$0]) && p[$0].y == Double(layer[$0]) }, "y is not the layer: \(context)")
        // Each weakly connected component starts at layer 0.
        var component = Array(0 ..< n)
        func find(_ x: Int) -> Int {
            var x = x
            while component[x] != x { x = component[x] }
            return x
        }
        for e in graph.edges.indices {
            let a = find(s[e]), b = find(t[e])
            if a != b { component[max(a, b)] = min(a, b) }
        }
        var least: [Int: Int] = [:]
        for v in 0 ..< n { least[find(v), default: Int.max] = min(least[find(v), default: Int.max], layer[v]) }
        check(least.values.allSatisfy { $0 == 0 }, "a component does not start at layer 0: \(least), \(context)")

        var allX = p.map(\.x)
        var rows = [[Double]](repeating: [], count: drawn.layerCount)
        for v in 0 ..< n { rows[layer[v]].append(p[v].x) }
        var segments: [(upper: Double, lower: Double, layer: Int)] = []
        var span = 0
        var tails: [Int] = [], heads: [Int] = []
        for e in graph.edges.indices {
            let bends = Array(drawn.bends(ofEdgeAt: e))
            guard s[e] != t[e] else {
                check(bends.isEmpty && !reversed.contains(e), "loop \(e) has bends or is reversed: \(context)")
                continue
            }
            let (top, bottom) = reversed.contains(e) ? (t[e], s[e]) : (s[e], t[e])
            tails.append(top)
            heads.append(bottom)
            check(layer[top] < layer[bottom], "edge \(e) does not point down: \(context)")
            span += layer[bottom] - layer[top]
            check(bends.count == layer[bottom] - layer[top] - 1, "edge \(e): \(bends.count) bends: \(context)")
            let downward = reversed.contains(e) ? Array(bends.reversed()) : bends
            check(downward.map(\.y) == (0 ..< bends.count).map { Double(layer[top] + 1 + $0) }, "edge \(e): bends off their layers: \(context)")
            for b in bends {
                check(finite(b), "edge \(e): bend \(b): \(context)")
                rows[Int(b.y)].append(b.x)
                allX.append(b.x)
            }
            let chain = [p[top]] + downward + [p[bottom]]
            for k in 0 ..< chain.count - 1 { segments.append((chain[k].x, chain[k + 1].x, Int(chain[k].y))) }
        }
        check(n == 0 || allX.min() == 0, "least x \(allX.min()!): \(context)")
        for (l, xs) in rows.enumerated() {
            let sorted = xs.sorted()
            check(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 >= 1 - 1e-9 }, "layer \(l) closer than 1: \(sorted), \(context)")
        }
        var crossings = 0
        for i in 0 ..< segments.count {
            for j in i + 1 ..< segments.count where segments[i].layer == segments[j].layer {
                if (segments[i].upper - segments[j].upper) * (segments[i].lower - segments[j].lower) < 0 { crossings += 1 }
            }
        }
        check(drawn.crossingCount == crossings, "crossingCount \(drawn.crossingCount), counted \(crossings): \(context)")

        // Longest-path layers on the same orientation are feasible, so the optimum is no longer.
        var longest = [Int](repeating: 0, count: n)
        for _ in 0 ..< n {
            for k in tails.indices { longest[heads[k]] = max(longest[heads[k]], longest[tails[k]] + 1) }
        }
        let longestSpan = tails.indices.reduce(0) { $0 + longest[heads[$1]] - longest[tails[$1]] }
        check(span <= longestSpan, "total span \(span) above longest path's \(longestSpan): \(context)")

        let second = graph.sugiyamaLayout(maxIterations: maxIterations)
        check(
            second.drawing == drawn.drawing && second.crossingCount == drawn.crossingCount && second.reversedEdges == drawn.reversedEdges
                && graph.edges.indices.allSatisfy { Array(second.bends(ofEdgeAt: $0)) == Array(drawn.bends(ofEdgeAt: $0)) },
            "not deterministic: \(context)")
    }

    static func callerLayers(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 12)
        let listed = labels(n, &input)
        let big = [1, 3, 1 << 40, Int.max / 4][input.int(below: 4)]
        let given = (0 ..< n).map { _ in input.int(below: 5) * big / 4 }
        var arcs: [(Int, Int)] = []
        for _ in 0 ..< input.int(in: 0 ... 30) { arcs.append((input.int(below: n), input.int(below: n))) }
        let graph = DirectedPseudograph<Int>(vertices: listed, edges: arcs.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
        let order = Array(graph.vertices)
        let offset = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        let layerOf = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, given[$0]) })
        let maxIterations = input.int(in: 0 ... 8)
        let drawn = graph.sugiyamaLayout(layers: { layerOf[$0]! }, maxIterations: maxIterations)
        let context = "labels \(listed), layers \(given), arcs \(arcs)"
        let want = order.map { layerOf[$0]! }
        check(order.map { drawn.layer(of: $0) } == want, "layers not as given: \(context)")
        check(drawn.layerCount == want.max()! + 1, "layerCount \(drawn.layerCount): \(context)")
        check(drawn.drawing.positions.map(\.y) == want.map(Double.init), "y not the layer: \(context)")
        check(drawn.drawing.positions.allSatisfy(finite), "a vertex not finite: \(context)")
        let upward = graph.edges.indices.filter { layerOf[graph.source(ofEdgeAt: $0)]! > layerOf[graph.target(ofEdgeAt: $0)]! }
        check(drawn.reversedEdges == upward, "reversedEdges \(drawn.reversedEdges), want \(upward): \(context)")
        let present = Set(want)
        // Keyed by y: a layer past 2^53 is rounded to a Double, for vertices and bends alike.
        var rows: [Double: [Double]] = [:]
        for v in 0 ..< n { rows[Double(want[v]), default: []].append(drawn.drawing.positions[v].x) }
        for e in graph.edges.indices {
            let a = want[offset[graph.source(ofEdgeAt: e)]!], b = want[offset[graph.target(ofEdgeAt: e)]!]
            let between = present.filter { min(a, b) < $0 && $0 < max(a, b) }.sorted()
            let bends = Array(drawn.bends(ofEdgeAt: e))
            let ys = bends.map(\.y)
            check(ys == (a < b ? between : between.reversed()).map(Double.init), "edge \(e): bends on \(ys), want \(between): \(context)")
            for q in bends {
                check(q.x.isFinite, "edge \(e): bend \(q): \(context)")
                rows[q.y, default: []].append(q.x)
            }
        }
        for (l, xs) in rows {
            let sorted = xs.sorted()
            check(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 >= 1 - 1e-9 }, "layer \(l) closer than 1: \(sorted), \(context)")
        }
    }

    // MARK: - Reingold–Tilford

    static func tree(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 60)
        // Filled in place: appending to a constant `[nil]` literal reads past it under ASan (the
        // static literal holds 9 bytes of its 16-byte stride), a toolchain artefact.
        var parents = [Int?](repeating: nil, count: n)
        for v in 1 ..< n { parents[v] = input.int(below: v) }
        guard let tree = RootedTree(parents: parents) else {
            check(false, "not a tree: \(parents)")
            return
        }
        let p = tree.reingoldTilfordLayout().positions
        check(p.count == n && p[0] == SIMD2(0, 0), "root not at the origin: \(parents)")
        var byDepth: [Int: [Double]] = [:]
        for v in 0 ..< n {
            check(finite(p[v]) && p[v].y == Double(tree.depth(of: v)), "vertex \(v) at \(p[v]): \(parents)")
            byDepth[tree.depth(of: v), default: []].append(p[v].x)
            let children = Array(tree.children(of: v))
            guard let first = children.first, let last = children.last else { continue }
            check(abs(p[v].x - (p[first].x + p[last].x) / 2) <= 1e-9, "vertex \(v) not centred: \(parents)")
            check(zip(children, children.dropFirst()).allSatisfy { p[$0].x < p[$1].x }, "children of \(v) out of order: \(parents)")
        }
        for (depth, xs) in byDepth {
            let sorted = xs.sorted()
            check(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 >= 1 - 1e-9 }, "overlap at depth \(depth): \(parents)")
        }
        let circular = tree.reingoldTilfordCircularLayout().positions
        for v in 0 ..< n {
            check(finite(circular[v]) && abs((circular[v] * circular[v]).sum().squareRoot() - p[v].y) <= 1e-9, "circular: \(v) at \(circular[v]): \(parents)")
        }
    }
}
