// Properties with shrinking (swift-property-based). Reingold–Tilford on random rooted trees: no two
// vertices at one depth closer than 1, every parent centred over its first and last child, children
// left to right, y = depth, the root at x = 0, the mirrored tree drawn as the reflection, and the
// circular form at radius = depth with equal x on one ray. Sugiyama on random digraphs with loops,
// parallel arcs and cycles: `reversedEdges` is `feedbackArcSet()` less its self-loops, every edge points down once the
// reversed ones are turned, the bends of an edge lie on the layers it crosses, one per layer, no two
// points of a layer closer than 1, and `crossingCount` equals a brute-force count over the drawn
// segments. Caller layers (bends only on the non-empty layers between). Then `step()` by step equals `run()` for both steppers, and `rescaled`
// and `circularLayout` on random inputs. See README.md.

import Cycles
import GraphDrawing
import GraphProtocols
import Multigraphs
import PropertyBased
import RandomGraphs
import Testing
import Trees

@Suite("GraphDrawing properties, with shrinking")
struct GraphDrawingPropertyTests {
    @Test("Reingold–Tilford: separation, centred parents, ordered children, depth, mirror symmetry")
    func treeLayoutInvariants() async {
        let choices = Gen.int(in: 0 ... 1_000).array(of: 0 ... 40)
        await propertyCheck(count: 300, input: choices) { choices in
            let n = choices.count + 1
            let parents: [Int?] = [nil] + choices.indices.map { choices[$0] % ($0 + 1) }
            guard let tree = RootedTree(parents: parents) else {
                Issue.record("not a tree: \(parents)")
                return
            }
            let layout = tree.reingoldTilfordLayout()
            let p = layout.positions
            #expect(Array(layout.vertices) == Array(0 ..< n))
            #expect(p[0] == SIMD2(0, 0), "\(parents)")
            var byDepth: [Int: [Double]] = [:]
            for v in 0 ..< n {
                #expect(p[v].y == Double(tree.depth(of: v)), "\(parents)")
                byDepth[tree.depth(of: v), default: []].append(p[v].x)
                let children = Array(tree.children(of: v))
                guard let first = children.first, let last = children.last else { continue }
                #expect(abs(p[v].x - (p[first].x + p[last].x) / 2) <= 1e-9, "vertex \(v) not centred: \(parents)")
                #expect(zip(children, children.dropFirst()).allSatisfy { p[$0].x < p[$1].x }, "children of \(v) out of order: \(parents)")
            }
            for (depth, xs) in byDepth {
                let sorted = xs.sorted()
                #expect(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 >= 1 - 1e-9 }, "overlap at depth \(depth): \(parents)")
            }
            // The mirror image: children in reverse order, renumbered in preorder so that
            // RootedTree(parents:) lists them by ascending vertex again.
            var order: [Int] = []
            var stack = [0]
            while let v = stack.popLast() {
                order.append(v)
                stack.append(contentsOf: Array(tree.children(of: v)))
            }
            var renumber = [Int](repeating: 0, count: n)
            for (i, v) in order.enumerated() { renumber[v] = i }
            var mirroredParents = [Int?](repeating: nil, count: n)
            for v in 0 ..< n { mirroredParents[renumber[v]] = parents[v].map { renumber[$0] } }
            guard let mirrored = RootedTree(parents: mirroredParents) else {
                Issue.record("mirror not a tree: \(mirroredParents)")
                return
            }
            let q = mirrored.reingoldTilfordLayout().positions
            for v in 0 ..< n {
                #expect(abs(q[renumber[v]].x + p[v].x) <= 1e-9 && q[renumber[v]].y == p[v].y, "mirror of \(parents) at \(v)")
            }
            // The circular form: radius = depth, and vertices with one x lie on one ray.
            let circular = tree.reingoldTilfordCircularLayout().positions
            for v in 0 ..< n {
                #expect(abs((circular[v] * circular[v]).sum().squareRoot() - p[v].y) <= 1e-9, "\(parents)")
            }
            for u in 0 ..< n where p[u].y > 0 {
                for v in u + 1 ..< n where p[v].y > 0 && p[v].x == p[u].x {
                    let a = circular[u] / p[u].y, b = circular[v] / p[v].y
                    #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(parents): \(u) and \(v)")
                }
            }
        }
    }

    @Test("Sugiyama on random digraphs: feedback arcs, downward edges, bends on the layers, separation, crossingCount by brute force")
    func sugiyamaInvariants() async {
        let arcs = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: arcs, Gen.int(in: 1 ... 10)) { arcs, size in
            let n = max(size, (arcs.map { max($0.0, $0.1) }.max() ?? -1) + 1)
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let layered = graph.sugiyamaLayout()
            let context = "n = \(n), arcs \(arcs)"
            let reversed = Set(layered.reversedEdges)
            // reversedEdges is feedbackArcSet() without its self-loops.
            #expect(layered.reversedEdges == graph.feedbackArcSet().filter { graph.source(ofEdgeAt: $0) != graph.target(ofEdgeAt: $0) }, "\(context)")
            #expect(graph.feedbackArcSet().filter { graph.source(ofEdgeAt: $0) == graph.target(ofEdgeAt: $0) } == graph.edges.indices.filter { graph.source(ofEdgeAt: $0) == graph.target(ofEdgeAt: $0) }, "\(context)")
            #expect(layered.reversedEdges == layered.reversedEdges.sorted(), "\(context)")
            #expect(layered.reversedEdges.allSatisfy { graph.source(ofEdgeAt: $0) != graph.target(ofEdgeAt: $0) }, "\(context)")
            let layer = graph.vertices.map { layered.layer(of: $0) }
            #expect(layer.min() == 0 && layered.layerCount == layer.max()! + 1, "\(context)")
            let p = layered.drawing.positions
            #expect(Array(layered.drawing.vertices) == Array(0 ..< n), "\(context)")
            #expect((0 ..< n).allSatisfy { p[$0].y == Double(layer[$0]) }, "\(context)")
            // The drawing is translated so that its least x, over vertices and bends, is 0.
            let allX = p.map(\.x) + graph.edges.indices.flatMap { layered.bends(ofEdgeAt: $0).map(\.x) }
            #expect(allX.min() == 0, "\(context)")
            // Points per layer (vertices and bends) and segments between adjacent layers.
            var rows = [[Double]](repeating: [], count: layered.layerCount)
            for v in 0 ..< n { rows[layer[v]].append(p[v].x) }
            var segments: [(upper: Double, lower: Double, layer: Int)] = []
            for e in graph.edges.indices {
                let s = graph.source(ofEdgeAt: e), t = graph.target(ofEdgeAt: e)
                let bends = Array(layered.bends(ofEdgeAt: e))
                guard s != t else {
                    #expect(bends.isEmpty && !reversed.contains(e), "\(context): loop \(e)")
                    continue
                }
                let (top, bottom) = reversed.contains(e) ? (t, s) : (s, t)
                #expect(layer[top] < layer[bottom], "\(context): edge \(e) does not point down")
                #expect(bends.count == layer[bottom] - layer[top] - 1, "\(context): edge \(e)")
                // From source to target in the edge's own direction: a reversed edge's bends go up.
                let downward = reversed.contains(e) ? Array(bends.reversed()) : bends
                #expect(downward.map(\.y) == (0 ..< bends.count).map { Double(layer[top] + 1 + $0) }, "\(context): edge \(e)")
                for b in bends { rows[Int(b.y)].append(b.x) }
                let chain = [p[top]] + downward + [p[bottom]]
                for k in 0 ..< chain.count - 1 { segments.append((chain[k].x, chain[k + 1].x, Int(chain[k].y))) }
            }
            for (l, xs) in rows.enumerated() {
                let sorted = xs.sorted()
                #expect(zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 >= 1 - 1e-9 }, "\(context): layer \(l) \(sorted)")
            }
            var count = 0
            for i in 0 ..< segments.count {
                for j in i + 1 ..< segments.count where segments[i].layer == segments[j].layer {
                    if (segments[i].upper - segments[j].upper) * (segments[i].lower - segments[j].lower) < 0 { count += 1 }
                }
            }
            #expect(layered.crossingCount == count, "\(context)")
            let forward = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: min($0.0, $0.1), to: max($0.0, $0.1)) })
            // An acyclic graph reverses nothing; its feedback arc set is its self-loops.
            let loops = forward.edges.indices.filter { forward.source(ofEdgeAt: $0) == forward.target(ofEdgeAt: $0) }
            #expect(forward.feedbackArcSet() == loops && forward.sugiyamaLayout().reversedEdges.isEmpty, "\(context)")
        }
    }

    @Test("Sugiyama with caller layers: upward edges reversed, flat edges without segments, layers as given")
    func callerLayers() async {
        let arcs = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 16)
        await propertyCheck(count: 200, input: arcs, Gen.int(in: 0 ... 3).array(of: 8 ... 8)) { arcs, given in
            let graph = DirectedPseudograph<Int>(vertices: 0 ..< 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let layerOf: (Int) -> Int = { given[$0] }
            let layered = graph.sugiyamaLayout(layers: layerOf)
            let context = "arcs \(arcs), layers \(given)"
            let drawnLayers = graph.vertices.map { layered.layer(of: $0) }
            #expect(drawnLayers == given && layered.layerCount == given.max()! + 1, "\(context)")
            #expect(layered.reversedEdges == graph.edges.indices.filter { given[graph.source(ofEdgeAt: $0)] > given[graph.target(ofEdgeAt: $0)] }, "\(context)")
            // A bend on each layer strictly between the ends that has a vertex; none on an empty one.
            for e in graph.edges.indices {
                let a = given[graph.source(ofEdgeAt: e)], b = given[graph.target(ofEdgeAt: e)]
                let between = Set(given.filter { min(a, b) < $0 && $0 < max(a, b) })
                let bends = layered.bends(ofEdgeAt: e).map { Int($0.y) }
                #expect(bends.count == between.count && Set(bends) == between, "\(context): edge \(e)")
            }
            #expect(layered.drawing.positions.map(\.y) == given.map(Double.init), "\(context)")
        }
    }

    @Test("Stepping one step() at a time equals run() and the function, for both steppers")
    func stepByStep() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 20)
        await propertyCheck(count: 60, input: edges, Gen.int(in: 0 ... 1_000)) { edges, seed in
            let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: edges.map { UndirectedEdge($0.0, $0.1) })
            let context = "edges \(edges), seed \(seed)"
            var g1 = Xoshiro256StarStar(seed: UInt64(seed)), g2 = g1, g3 = g1
            var stepped = FruchtermanReingoldLayout(graph, iterations: 30, using: &g1)
            var steps = 0
            while !stepped.isFinished {
                let before = stepped.iteration
                stepped.step()
                steps += 1
                #expect(stepped.iteration == before + 1, "\(context)")
            }
            var ran = FruchtermanReingoldLayout(graph, iterations: 30, using: &g2)
            ran.run()
            #expect(stepped.drawing == ran.drawing && stepped.iteration == ran.iteration && steps == ran.iteration, "\(context)")
            #expect(graph.fruchtermanReingoldLayout(iterations: 30, using: &g3) == ran.drawing, "\(context)")
            #expect(steps <= 30, "\(context)")

            var stress = StressMajorizationLayout(graph, maxIterations: 40)
            var stressSteps = 0
            while !stress.isFinished {
                stress.step()
                stressSteps += 1
            }
            var stressRan = StressMajorizationLayout(graph, maxIterations: 40)
            stressRan.run()
            #expect(stress.drawing == stressRan.drawing && stress.stress == stressRan.stress && stressSteps == stressRan.iteration, "\(context)")
            #expect(graph.stressMajorizationLayout(maxIterations: 40) == stressRan.drawing, "\(context)")
            #expect(stressSteps <= 40, "\(context)")
        }
    }

    @Test("rescaled: the mean goes to the centre, the largest |coordinate| to the scale, shape kept")
    func rescaledProperties() async {
        let points = zip(Gen.int(in: -50 ... 50), Gen.int(in: -50 ... 50)).array(of: 1 ... 12)
        await propertyCheck(count: 300, input: points, Gen.int(in: 1 ... 5)) { points, scale in
            let drawing = Drawing(vertices: points.indices, positions: points.map { SIMD2(Double($0.0), Double($0.1)) })
            let center = SIMD2(3.0, -2.0)
            let r = drawing.rescaled(scale: Double(scale), center: center)
            var mean = SIMD2<Double>.zero
            for q in r.positions { mean += q }
            mean /= Double(points.count)
            #expect(abs(mean.x - center.x) <= 1e-9 && abs(mean.y - center.y) <= 1e-9, "\(points)")
            let spread = r.positions.map { max(abs($0.x - center.x), abs($0.y - center.y)) }.max()!
            let allEqual = points.allSatisfy { $0 == points[0] }
            #expect(abs(spread - (allEqual ? 0 : Double(scale))) <= 1e-9, "\(points)")
            // Differences scale by one factor on both axes.
            if !allEqual {
                let factor = Double(scale) / drawing.positions.map { q -> Double in
                    let m = drawing.positions.reduce(SIMD2<Double>.zero, +) / Double(points.count)
                    return max(abs(q.x - m.x), abs(q.y - m.y))
                }.max()!
                for i in points.indices {
                    let a = (r.positions[i] - r.positions[0]), b = (drawing.positions[i] - drawing.positions[0]) * factor
                    #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(points)")
                }
            }
        }
    }

    @Test("circularLayout: every vertex at the radius, consecutive vertices at equal angles")
    func circularProperties() async {
        await propertyCheck(count: 200, input: Gen.int(in: 2 ... 60), Gen.int(in: 0 ... 10)) { n, radius in
            let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: [] as [UndirectedEdge<Int>])
            let center = SIMD2(-1.5, 4.0)
            let p = graph.circularLayout(radius: Double(radius), center: center).positions
            #expect(p.count == n && p[0] == center + SIMD2(Double(radius), 0))
            for q in p {
                let d = q - center
                #expect(abs((d * d).sum().squareRoot() - Double(radius)) <= 1e-9, "n = \(n)")
            }
            let chords = (0 ..< n).map { i -> Double in
                let d = p[(i + 1) % n] - p[i]
                return (d * d).sum().squareRoot()
            }
            #expect(chords.allSatisfy { abs($0 - chords[0]) <= 1e-9 }, "n = \(n)")
        }
    }
}
