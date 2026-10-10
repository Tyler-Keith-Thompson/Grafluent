// Properties against oracles written inside each test, with shrinking (swift-property-based): on a
// failure, PropertyBased shrinks the generated input and prints the smallest one that still fails.
// Networks are multigraphs with self-loops, parallel and antiparallel edges on 1 … 9 vertices listed
// in an order shuffled by a seed (so vertex indices are not vertex values), on `DirectedPseudograph`
// and `Pseudograph`. The oracles: the definitions (capacity, conservation, a cut's edges and value);
// brute force over every vertex set (the least s–t cut and the least sink side among the minimum
// cuts, the global cut, κ and λ by Menger's theorem); api.md's procedures written out (Edmonds–Karp,
// Gusfield's tree); a successive-shortest-path minimum-cost oracle; and complementary slackness for the returned potentials. Every oracle
// here is polynomial or bounded by 2⁹ vertex sets. See README.md.
// Conditions with a closure are computed into a constant before `#expect`: inside these closures a
// closure in an `#expect` expansion failed SIL verification with this toolchain (README.md).

import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("Flows properties against oracles, with shrinking", .tags(.randomized))
struct FlowsPropertyTests {
    @Test("Directed: the three maximum flows are feasible, agree on the value and the canonical cut, and their residual networks give it; Edmonds–Karp is the procedure written out; brute force agrees")
    func directedMaximumFlows() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 2 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }
            let m = ends.count
            let s = seed % n, t = (seed % n + 1 + (seed / n) % (n - 1)) % n
            let graph = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
            let context = "\(ends) capacities \(capacities) from \(s) to \(t) on \(listed)"

            // Edmonds–Karp written out (api.md): arc 2k is edge k forward with its capacity, 2k + 1 its
            // reverse with 0; each vertex's arcs in edge-position order; breadth-first search from s,
            // stopped when t is discovered; augment by the bottleneck.
            var head = [Int](repeating: 0, count: 2 * m), residual = [Int](repeating: 0, count: 2 * m)
            var rows = [[Int]](repeating: [], count: n)
            for k in 0 ..< m where ends[k].0 != ends[k].1 {
                head[2 * k] = ends[k].1
                head[2 * k + 1] = ends[k].0
                residual[2 * k] = capacities[k]
                rows[ends[k].0].append(2 * k)
                rows[ends[k].1].append(2 * k + 1)
            }
            var writtenValue = 0
            while true {
                var parent = [Int](repeating: -2, count: n)
                parent[s] = -1
                var queue = [s], qi = 0, found = false
                while qi < queue.count && !found {
                    let x = queue[qi]
                    qi += 1
                    for arc in rows[x] where residual[arc] > 0 && parent[head[arc]] == -2 {
                        parent[head[arc]] = arc
                        if head[arc] == t {
                            found = true
                            break
                        }
                        queue.append(head[arc])
                    }
                }
                if !found { break }
                var delta = Int.max, y = t
                while y != s {
                    delta = min(delta, residual[parent[y]])
                    y = head[parent[y] ^ 1]
                }
                y = t
                while y != s {
                    residual[parent[y]] -= delta
                    residual[parent[y] ^ 1] += delta
                    y = head[parent[y] ^ 1]
                }
                writtenValue += delta
            }
            let writtenFlows = (0 ..< m).map { ends[$0].0 == ends[$0].1 ? 0 : residual[2 * $0 + 1] }

            // Brute force: the least cut and the least sink side among the minimum cuts.
            var best = Int.max
            var leastSink = Set(0 ..< n)
            for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
                var value = 0
                for k in 0 ..< m where mask & (1 << ends[k].0) != 0 && mask & (1 << ends[k].1) == 0 { value += capacities[k] }
                let sink = Set((0 ..< n).filter { mask & (1 << $0) == 0 })
                if value < best {
                    best = value
                    leastSink = sink
                } else if value == best {
                    leastSink.formIntersection(sink)
                }
            }
            #expect(writtenValue == best, "\(context)")

            let cut = graph.minimumCut(from: listed[s], to: listed[t], capacity: { capacities[$0] })
            #expect(cut.value == best, "\(context)")
            let sinkSideIndices = Set(cut.sinkSide.map { listed.firstIndex(of: $0)! }) == leastSink
            #expect(sinkSideIndices, "\(context)")
            let sinkSideInOrder = Array(cut.sinkSide) == (0 ..< n).filter { leastSink.contains($0) }.map { listed[$0] }
            #expect(sinkSideInOrder, "\(context)")
            let sourceSideInOrder = Array(cut.sourceSide) == (0 ..< n).filter { !leastSink.contains($0) }.map { listed[$0] }
            #expect(sourceSideInOrder, "\(context)")
            let cutEdgesCross = cut.edges == (0 ..< m).filter { ends[$0].0 != ends[$0].1 && !leastSink.contains(ends[$0].0) && leastSink.contains(ends[$0].1) }
            #expect(cutEdgesCross, "\(context)")
            let valueAgrees = graph.maximumFlowValue(from: listed[s], to: listed[t], capacity: { capacities[$0] }) == best
            #expect(valueAgrees, "\(context)")

            let flows = [graph.maximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] }),
                         graph.edmondsKarpMaximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] }),
                         graph.dinicMaximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] })]
            let edmondsKarpWrittenOut = (0 ..< m).map { flows[1].flow(ofEdgeAt: $0) } == writtenFlows
            #expect(edmondsKarpWrittenOut, "\(context)")
            for (which, flow) in flows.enumerated() {
                #expect(flow.value == best, "\(which) \(context)")
                #expect(flow.minimumCut == cut, "\(which) \(context)")
                let f = (0 ..< m).map { flow.flow(ofEdgeAt: $0) }
                var excess = [Int](repeating: 0, count: n)
                for k in 0 ..< m {
                    #expect(f[k] >= 0 && f[k] <= capacities[k], "\(which) edge \(k) \(context)")
                    if ends[k].0 == ends[k].1 { #expect(f[k] == 0, "\(which) loop \(k) \(context)") }
                    excess[ends[k].1] += f[k]
                    excess[ends[k].0] -= f[k]
                }
                let conserved = (0 ..< n).allSatisfy { $0 == s || $0 == t || excess[$0] == 0 }
                #expect(conserved, "\(which) \(context)")
                #expect(excess[t] == best && excess[s] == -best, "\(which) \(context)")
                // The vertices that reach t in this flow's residual network are the least sink side.
                var reaches = Set([t]), queue = [t]
                while let y = queue.popLast() {
                    for k in 0 ..< m where ends[k].0 != ends[k].1 {
                        let (a, b) = ends[k]
                        if b == y && !reaches.contains(a) && f[k] < capacities[k] { reaches.insert(a); queue.append(a) }
                        if a == y && !reaches.contains(b) && f[k] > 0 { reaches.insert(b); queue.append(b) }
                    }
                }
                #expect(reaches == leastSink, "\(which) \(context)")
            }
        }
    }

    @Test("Undirected: |flow| ≤ capacity on each edge, one arc used, conservation; Edmonds–Karp written out; the cut is the least sink side by brute force; the same value as the directed view")
    func undirectedMaximumFlows() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 2 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }
            let m = ends.count
            let s = seed % n, t = (seed % n + 1 + (seed / n) % (n - 1)) % n
            let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
            let context = "\(ends) capacities \(capacities) from \(s) to \(t) on \(listed)"

            // Edmonds–Karp written out: one residual pair per edge, capacity c both ways.
            var head = [Int](repeating: 0, count: 2 * m), residual = [Int](repeating: 0, count: 2 * m)
            var rows = [[Int]](repeating: [], count: n)
            for k in 0 ..< m where ends[k].0 != ends[k].1 {
                head[2 * k] = ends[k].1
                head[2 * k + 1] = ends[k].0
                residual[2 * k] = capacities[k]
                residual[2 * k + 1] = capacities[k]
                rows[ends[k].0].append(2 * k)
                rows[ends[k].1].append(2 * k + 1)
            }
            while true {
                var parent = [Int](repeating: -2, count: n)
                parent[s] = -1
                var queue = [s], qi = 0, found = false
                while qi < queue.count && !found {
                    let x = queue[qi]
                    qi += 1
                    for arc in rows[x] where residual[arc] > 0 && parent[head[arc]] == -2 {
                        parent[head[arc]] = arc
                        if head[arc] == t {
                            found = true
                            break
                        }
                        queue.append(head[arc])
                    }
                }
                if !found { break }
                var delta = Int.max, y = t
                while y != s {
                    delta = min(delta, residual[parent[y]])
                    y = head[parent[y] ^ 1]
                }
                y = t
                while y != s {
                    residual[parent[y]] -= delta
                    residual[parent[y] ^ 1] += delta
                    y = head[parent[y] ^ 1]
                }
            }
            let writtenSigned = (0 ..< m).map { ends[$0].0 == ends[$0].1 ? 0 : capacities[$0] - residual[2 * $0] }

            var best = Int.max
            var leastSink = Set(0 ..< n)
            for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
                var value = 0
                for k in 0 ..< m where (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += capacities[k] }
                let sink = Set((0 ..< n).filter { mask & (1 << $0) == 0 })
                if value < best {
                    best = value
                    leastSink = sink
                } else if value == best {
                    leastSink.formIntersection(sink)
                }
            }
            let flows = [graph.maximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] }),
                         graph.edmondsKarpMaximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] }),
                         graph.dinicMaximumFlow(from: listed[s], to: listed[t], capacity: { capacities[$0] })]
            let cut = graph.minimumCut(from: listed[s], to: listed[t], capacity: { capacities[$0] })
            #expect(cut.value == best, "\(context)")
            let sinkSideIndices = Set(cut.sinkSide.map { listed.firstIndex(of: $0)! }) == leastSink
            #expect(sinkSideIndices, "\(context)")
            let crossing = (0 ..< m).filter { ends[$0].0 != ends[$0].1 && leastSink.contains(ends[$0].0) != leastSink.contains(ends[$0].1) }
            let cutEdgesCross = cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { leastSink.contains(ends[$0].1) ? "\($0)" : "\($0)r" }
            #expect(cutEdgesCross, "\(context)")
            let valueAgrees = graph.maximumFlowValue(from: listed[s], to: listed[t], capacity: { capacities[$0] }) == best
            #expect(valueAgrees, "\(context)")
            let directedViewValue = graph.directed.maximumFlowValue(from: listed[s], to: listed[t], capacity: { capacities[$0.position] }) == best
            #expect(directedViewValue, "\(context)")
            for (which, flow) in flows.enumerated() {
                #expect(flow.value == best, "\(which) \(context)")
                #expect(flow.minimumCut == cut, "\(which) \(context)")
                var excess = [Int](repeating: 0, count: n)
                var signed: [Int] = []
                for k in 0 ..< m {
                    let forward = flow.flow(ofEdgeAt: .init(position: k, reversed: false))
                    let backward = flow.flow(ofEdgeAt: .init(position: k, reversed: true))
                    #expect(forward >= 0 && backward >= 0 && (forward == 0 || backward == 0), "\(which) edge \(k) \(context)")
                    #expect(forward <= capacities[k] && backward <= capacities[k], "\(which) edge \(k) \(context)")
                    if ends[k].0 == ends[k].1 { #expect(forward == 0 && backward == 0, "\(which) loop \(k) \(context)") }
                    signed.append(forward - backward)
                    excess[ends[k].1] += forward - backward
                    excess[ends[k].0] -= forward - backward
                }
                let conserved = (0 ..< n).allSatisfy { $0 == s || $0 == t || excess[$0] == 0 }
                #expect(conserved, "\(which) \(context)")
                #expect(excess[t] == best, "\(which) \(context)")
                if which == 1 { #expect(signed == writtenSigned, "\(context)") }
                var reaches = Set([t]), queue = [t]
                while let y = queue.popLast() {
                    for k in 0 ..< m where ends[k].0 != ends[k].1 {
                        let (a, b) = ends[k]
                        if b == y && !reaches.contains(a) && signed[k] < capacities[k] { reaches.insert(a); queue.append(a) }
                        if a == y && !reaches.contains(b) && signed[k] > -capacities[k] { reaches.insert(b); queue.append(b) }
                    }
                }
                #expect(reaches == leastSink, "\(which) \(context)")
            }
        }
    }

    @Test("Floating capacities: multiples of 1/8 give the integer results divided by 8 exactly; integer-valued Doubles give integral flows")
    func floatingCapacities() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 12)).array(of: 0 ... 20)
        await propertyCheck(count: 200, input: edges, Gen.int(in: 2 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }
            let m = ends.count
            let s = seed % n, t = (seed % n + 1 + (seed / n) % (n - 1)) % n
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
            let context = "\(ends) capacities \(capacities) from \(s) to \(t)"
            let integer = graph.edmondsKarpMaximumFlow(from: s, to: t, capacity: { capacities[$0] })
            let eighths = graph.edmondsKarpMaximumFlow(from: s, to: t, capacity: { Double(capacities[$0]) / 8 })
            #expect(eighths.value == Double(integer.value) / 8, "\(context)")
            let flowsScaled = (0 ..< m).map { eighths.flow(ofEdgeAt: $0) } == (0 ..< m).map { Double(integer.flow(ofEdgeAt: $0)) / 8 }
            #expect(flowsScaled, "\(context)")
            #expect(Array(eighths.minimumCut.sinkSide) == Array(integer.minimumCut.sinkSide), "\(context)")
            #expect(eighths.minimumCut.edges == integer.minimumCut.edges, "\(context)")
            let valueScaled = graph.maximumFlowValue(from: s, to: t, capacity: { Double(capacities[$0]) / 8 }) == Double(integer.value) / 8
            #expect(valueScaled, "\(context)")
            // Integrality: integer-valued capacities give integer flows from every algorithm.
            for flow in [graph.maximumFlow(from: s, to: t, capacity: { Double(capacities[$0]) }),
                         graph.dinicMaximumFlow(from: s, to: t, capacity: { Double(capacities[$0]) })] {
                #expect(flow.value == Double(integer.value), "\(context)")
                let integral = (0 ..< m).allSatisfy { flow.flow(ofEdgeAt: $0) == flow.flow(ofEdgeAt: $0).rounded() }
                #expect(integral, "\(context)")
            }
        }
    }

    @Test("Medium networks (layered networks of 50 to 226 vertices, two narrow links per vertex to the next layer and one back, so push–relabel relabels far past its global-relabel threshold and opens gaps): every maximum flow is feasible, its value Edmonds–Karp's, its cut the vertices still reaching the sink in its residual network, the same for all three")
    func mediumNetworks() async {
        await propertyCheck(count: 60, input: Gen.int(in: 6 ... 14), Gen.int(in: 8 ... 16), Gen.int(in: 0 ... 1_000_000)) { layers, width, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // Vertex 0 the source, the last the sink, `layers` layers of `width` vertices between:
            // wide links inside a layer, a few narrow ones to the next layer, and back edges.
            let n = layers * width + 2
            var ends: [(Int, Int)] = [], capacities: [Int] = []
            func vertex(_ layer: Int, _ k: Int) -> Int { 1 + layer * width + k }
            for k in 0 ..< width {
                ends.append((0, vertex(0, k)))
                capacities.append(Int.random(in: 20 ... 60, using: &rng))
                ends.append((vertex(layers - 1, k), n - 1))
                capacities.append(Int.random(in: 1 ... 30, using: &rng))
            }
            for layer in 0 ..< layers {
                for k in 0 ..< width {
                    ends.append((vertex(layer, k), vertex(layer, (k + 1) % width)))
                    capacities.append(Int.random(in: 5 ... 40, using: &rng))
                    if layer + 1 < layers {
                        for _ in 0 ..< 2 {
                            ends.append((vertex(layer, k), vertex(layer + 1, Int.random(in: 0 ..< width, using: &rng))))
                            capacities.append(Int.random(in: 1 ... 10, using: &rng))
                        }
                    }
                    if layer > 0 {
                        ends.append((vertex(layer, k), vertex(layer - 1, Int.random(in: 0 ..< width, using: &rng))))
                        capacities.append(Int.random(in: 1 ... 20, using: &rng))
                    }
                }
            }
            let m = ends.count
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
            let context = "layers \(layers) width \(width) seed \(seed)"
            // Edmonds–Karp's value, written out: breadth-first augmenting paths on a residual matrix of
            // arcs (each edge an arc and its reverse).
            var residual = capacities + [Int](repeating: 0, count: m)
            var rows = [[Int]](repeating: [], count: n)
            for k in 0 ..< m {
                rows[ends[k].0].append(k)
                rows[ends[k].1].append(m + k)
            }
            func arcHead(_ a: Int) -> Int { a < m ? ends[a].1 : ends[a - m].0 }
            func arcMate(_ a: Int) -> Int { a < m ? a + m : a - m }
            var value = 0
            while true {
                var parent = [Int](repeating: -1, count: n)
                var seen = [Bool](repeating: false, count: n)
                seen[0] = true
                var queue = [0], head = 0
                while head < queue.count && !seen[n - 1] {
                    let x = queue[head]
                    head += 1
                    for a in rows[x] where residual[a] > 0 && !seen[arcHead(a)] {
                        seen[arcHead(a)] = true
                        parent[arcHead(a)] = a
                        queue.append(arcHead(a))
                    }
                }
                if !seen[n - 1] { break }
                var delta = Int.max, y = n - 1
                while y != 0 {
                    delta = min(delta, residual[parent[y]])
                    y = arcHead(arcMate(parent[y]))
                }
                y = n - 1
                while y != 0 {
                    residual[parent[y]] -= delta
                    residual[arcMate(parent[y])] += delta
                    y = arcHead(arcMate(parent[y]))
                }
                value += delta
            }
            let flows = [graph.maximumFlow(from: 0, to: n - 1, capacity: { capacities[$0] }),
                         graph.dinicMaximumFlow(from: 0, to: n - 1, capacity: { capacities[$0] }),
                         graph.edmondsKarpMaximumFlow(from: 0, to: n - 1, capacity: { capacities[$0] })]
            for flow in flows {
                #expect(flow.value == value, "\(context)")
                let f = (0 ..< m).map { flow.flow(ofEdgeAt: $0) }
                var excess = [Int](repeating: 0, count: n)
                var feasible = true
                for k in 0 ..< m {
                    feasible = feasible && f[k] >= 0 && f[k] <= capacities[k]
                    excess[ends[k].1] += f[k]
                    excess[ends[k].0] -= f[k]
                }
                feasible = feasible && excess[n - 1] == value && excess[0] == -value && (1 ..< n - 1).allSatisfy { excess[$0] == 0 }
                #expect(feasible, "\(context)")
                // The vertices still reaching the sink in this flow's residual network.
                var reaches = [Bool](repeating: false, count: n)
                reaches[n - 1] = true
                var stack = [n - 1]
                while let y = stack.popLast() {
                    for k in 0 ..< m {
                        if ends[k].1 == y && !reaches[ends[k].0] && f[k] < capacities[k] {
                            reaches[ends[k].0] = true
                            stack.append(ends[k].0)
                        }
                        if ends[k].0 == y && !reaches[ends[k].1] && f[k] > 0 {
                            reaches[ends[k].1] = true
                            stack.append(ends[k].1)
                        }
                    }
                }
                let cutFromResidual = flow.minimumCut.sinkSide == (0 ..< n).filter { reaches[$0] }
                #expect(cutFromResidual && flow.minimumCut.value == value, "\(context)")
                #expect(flow.minimumCut == flows[0].minimumCut, "\(context)")
            }
            #expect(graph.maximumFlowValue(from: 0, to: n - 1, capacity: { capacities[$0] }) == value, "\(context)")
        }
    }

    @Test("Global cuts: a minimum cut by brute force over every vertex set, its edges and value from its sides; on Graph the first vertex on the source side and, when the positive edges leave several components, the first vertex's component; the directed value also the least over the cyclic pairs (Schnorr); the same cut on a second call")
    func globalCuts() async {
        let edges = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 6)).array(of: 0 ... 22)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 9), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }
            let m = ends.count
            let context = "\(ends) capacities \(capacities) on \(listed)"
            let undirected = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
            let directed = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
            let undirectedCut = undirected.minimumCut(capacity: { capacities[$0] })
            let directedCut = directed.minimumCut(capacity: { capacities[$0] })
            if n < 2 {
                #expect(undirectedCut == nil && directedCut == nil, "\(context)")
                return
            }
            // Brute force over every nonempty proper set.
            var undirectedBest = Int.max, directedBest = Int.max
            for mask in 1 ..< (1 << n) - 1 {
                var across = 0, out = 0
                for k in 0 ..< m {
                    let a = mask & (1 << ends[k].0) != 0, b = mask & (1 << ends[k].1) != 0
                    if a != b { across += capacities[k] }
                    if a && !b { out += capacities[k] }
                }
                undirectedBest = min(undirectedBest, across)
                directedBest = min(directedBest, out)
            }
            // Undirected: the cut's sides split the vertices in order, the first vertex on the source
            // side; its edges are the crossing ones (as the arc leaving the source side); its value
            // their capacity and the least.
            let cut = undirectedCut!
            let inSink = (0 ..< n).map { cut.sinkSide.contains(listed[$0]) }
            let sidesInOrder = cut.sourceSide == (0 ..< n).filter { !inSink[$0] }.map { listed[$0] } && cut.sinkSide == (0 ..< n).filter { inSink[$0] }.map { listed[$0] }
            #expect(sidesInOrder, "\(context)")
            #expect(!inSink[0] && cut.sinkSide.count >= 1, "\(context)")
            let crossing = (0 ..< m).filter { ends[$0].0 != ends[$0].1 && inSink[ends[$0].0] != inSink[ends[$0].1] }
            let cutEdgesCross = cut.edges.map { "\($0.position)\($0.reversed ? "r" : "")" } == crossing.map { inSink[ends[$0].1] ? "\($0)" : "\($0)r" }
            #expect(cutEdgesCross, "\(context)")
            let cutCapacityIsValue = cut.value == crossing.reduce(0) { $0 + capacities[$1] }
            #expect(cutCapacityIsValue, "\(context)")
            #expect(cut.value == undirectedBest, "\(context)")
            // When the positive edges leave more than one component: the first vertex's component.
            var component = Array(0 ..< n)
            var changed = true
            while changed {
                changed = false
                for k in 0 ..< m where ends[k].0 != ends[k].1 && capacities[k] > 0 {
                    let low = min(component[ends[k].0], component[ends[k].1])
                    if component[ends[k].0] != low || component[ends[k].1] != low {
                        component[ends[k].0] = low
                        component[ends[k].1] = low
                        changed = true
                    }
                }
            }
            if component.contains(where: { $0 != component[0] }) {
                let firstComponent = (0 ..< n).map { component[$0] != component[0] } == inSink
                #expect(firstComponent, "\(context)")
            }
            #expect(undirected.minimumCut(capacity: { capacities[$0] }) == cut, "\(context)")
            // The same in quarters as Double: the heap rather than the bucket queue, the value exactly
            // the integer one divided by 4, the first vertex on the source side.
            let quarter = undirected.minimumCut(capacity: { Double(capacities[$0]) / 4 })!
            let quarterValue = quarter.value == Double(undirectedBest) / 4 && quarter.sourceSide.first == listed[0]
            #expect(quarterValue, "\(context)")
            // Directed: sides in order, the edges leaving the source side, the least value; the same as
            // the least canonical cut value over the cyclic pairs vᵢ → vᵢ₊₁ (mod n), since every proper
            // set separates some such pair (Schnorr 1979; Esfahanian's Algorithm 8, NetworkX's).
            let dcut = directedCut!
            let dSink = (0 ..< n).map { dcut.sinkSide.contains(listed[$0]) }
            let dSidesInOrder = dcut.sourceSide == (0 ..< n).filter { !dSink[$0] }.map { listed[$0] } && dcut.sinkSide == (0 ..< n).filter { dSink[$0] }.map { listed[$0] }
            #expect(dSidesInOrder && !dcut.sourceSide.isEmpty && !dcut.sinkSide.isEmpty, "\(context)")
            let leaving = (0 ..< m).filter { ends[$0].0 != ends[$0].1 && !dSink[ends[$0].0] && dSink[ends[$0].1] }
            #expect(dcut.edges == leaving, "\(context)")
            let dCapacityIsValue = dcut.value == leaving.reduce(0) { $0 + capacities[$1] }
            #expect(dCapacityIsValue, "\(context)")
            #expect(dcut.value == directedBest, "\(context)")
            let cyclic = (0 ..< n).map { directed.minimumCut(from: listed[$0], to: listed[($0 + 1) % n], capacity: { capacities[$0] }).value }.min()!
            #expect(cyclic == directedBest, "\(context)")
            #expect(directed.minimumCut(capacity: { capacities[$0] }) == dcut, "\(context)")
        }
    }

    @Test("Medium global cuts (20 to 60 vertices, in up to four clusters joined by light edges): the undirected value, in Int, in Double quarters and with capacities up to 10⁶ (heap and bucket queue both), is the least maximum flow from the first vertex; the directed one the least maximum flow either way between the first vertex and another; each cut's value is its edges' capacity")
    func mediumGlobalCuts() async {
        await propertyCheck(count: 40, input: Gen.int(in: 20 ... 60), Gen.int(in: 2 ... 5), Gen.int(in: 0 ... 1_000_000)) { n, degree, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // Clusters (seed mod 4 of them, 1 meaning none): edges inside a cluster heavy, edges between
            // light, so the minimum cut is usually a whole cluster rather than one vertex.
            let clusters = 1 + seed % 4
            var ends: [(Int, Int)] = [], heavy: [Bool] = []
            for _ in 0 ..< n * degree {
                let u = Int.random(in: 0 ..< n, using: &rng)
                let between = Int.random(in: 0 ..< 10, using: &rng) == 0
                var v = Int.random(in: 0 ..< n, using: &rng)
                if !between { v = (v / clusters) * clusters + u % clusters }
                if u != v && v < n {
                    ends.append((u, v))
                    heavy.append(u % clusters == v % clusters)
                }
            }
            let small = heavy.map { Int.random(in: 1 ... 9, using: &rng) * ($0 ? 10 : 1) }
            let large = heavy.map { Int.random(in: 1 ... 100_000, using: &rng) * ($0 ? 10 : 1) }
            let context = "n \(n) degree \(degree) seed \(seed)"
            let undirected = Pseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            let directed = DirectedPseudograph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
            for capacities in [small, large] {
                let fromFirst = (1 ..< n).map { undirected.maximumFlowValue(from: 0, to: $0, capacity: { capacities[$0] }) }.min()!
                let cut = undirected.minimumCut(capacity: { capacities[$0] })!
                let crossing = (0 ..< ends.count).filter { cut.sinkSide.contains(ends[$0].0) != cut.sinkSide.contains(ends[$0].1) }
                let valid = cut.value == fromFirst && cut.value == crossing.reduce(0) { $0 + capacities[$1] } && cut.sourceSide.first == 0
                #expect(valid, "undirected \(context)")
                let quarters = undirected.minimumCut(capacity: { Double(capacities[$0]) / 4 })!
                let quartersValid = quarters.value == Double(fromFirst) / 4 && quarters.sourceSide.first == 0
                #expect(quartersValid, "Double \(context)")
                let eitherWay = (1 ..< n).map { min(directed.maximumFlowValue(from: 0, to: $0, capacity: { capacities[$0] }), directed.maximumFlowValue(from: $0, to: 0, capacity: { capacities[$0] })) }.min()!
                let dcut = directed.minimumCut(capacity: { capacities[$0] })!
                let leaving = (0 ..< ends.count).filter { !dcut.sinkSide.contains(ends[$0].0) && dcut.sinkSide.contains(ends[$0].1) }
                let dValid = dcut.value == eitherWay && dcut.value == leaving.reduce(0) { $0 + capacities[$1] }
                #expect(dValid, "directed \(context)")
            }
        }
    }

    @Test("Gomory–Hu: the tree is Gusfield's written out with the canonical cut; every pair's least path capacity is the brute-force minimum cut; every minimumCut(between:and:) is a minimum cut")
    func gomoryHu() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 5)).array(of: 0 ... 16)
        await propertyCheck(count: 200, input: edges, Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }
            let m = ends.count
            let context = "\(ends) capacities \(capacities) on \(listed)"
            let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
            let tree = graph.gomoryHuTree(capacity: { capacities[$0] })!
            #expect(Array(tree.tree.vertices) == listed, "\(context)")
            // Gusfield written out (api.md): p[v] = 0 for all; for s = 1, 2, …: t = p[s], X the source side
            // of the canonical cut from s to t, fl[s] its value; every other v in X with p[v] = t moves
            // under s; if p[t] is in X (t not 0), s takes t's place and the labels swap.
            var p = [Int](repeating: 0, count: n), fl = [Int](repeating: 0, count: n)
            for s in 1 ..< max(n, 1) {
                let t = p[s]
                let cut = graph.minimumCut(from: listed[s], to: listed[t], capacity: { capacities[$0] })
                let inX = (0 ..< n).map { cut.sourceSide.contains(listed[$0]) }
                fl[s] = cut.value
                for v in 1 ..< n where v != s && inX[v] && p[v] == t { p[v] = s }
                if t != 0 && inX[p[t]] {
                    p[s] = p[t]
                    p[t] = s
                    fl[s] = fl[t]
                    fl[t] = cut.value
                }
            }
            for k in 0 ..< max(n - 1, 0) {
                let edge = tree.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([listed[k + 1], listed[p[k + 1]]]), "tree edge \(k) \(context)")
                #expect(tree.capacity(ofEdgeAt: k) == fl[k + 1], "tree edge \(k) \(context)")
            }
            for u in 0 ..< n {
                for v in 0 ..< n where v != u {
                    var best = Int.max
                    for mask in 0 ..< (1 << n) where mask & (1 << u) != 0 && mask & (1 << v) == 0 {
                        var value = 0
                        for k in 0 ..< m where (mask & (1 << ends[k].0) != 0) != (mask & (1 << ends[k].1) != 0) { value += capacities[k] }
                        best = min(best, value)
                    }
                    #expect(tree.minimumCutValue(between: listed[u], and: listed[v]) == best, "\(u), \(v) \(context)")
                    let cut = tree.minimumCut(between: listed[u], and: listed[v])
                    #expect(cut.value == best && cut.sourceSide.contains(listed[u]) && cut.sinkSide.contains(listed[v]), "\(u), \(v) \(context)")
                    let inS = (0 ..< n).map { cut.sourceSide.contains(listed[$0]) }
                    let cutCapacityIsValue = cut.value == (0 ..< m).filter { ends[$0].0 != ends[$0].1 && inS[ends[$0].0] != inS[ends[$0].1] }.reduce(0) { $0 + capacities[$1] }
                    #expect(cutCapacityIsValue, "\(u), \(v) \(context)")
                }
            }
        }
    }

    @Test("Minimum-cost flow: the least cost of a successive-shortest-path oracle (nil exactly when it finds no flow); feasible; self-loops by the rule; the potentials certify optimality")
    func minimumCostFlow() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 3), Gen.int(in: -3 ... 5)).array(of: 0 ... 9)
        let moves = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 1 ... 3)).array(of: 0 ... 3)
        await propertyCheck(count: 400, input: edges, moves, Gen.int(in: 1 ... 6), Gen.int(in: 0 ... 1_000_000)) { raw, rawMoves, n, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }, costs = raw.map { $0.3 }
            let m = ends.count
            var supplies = [Int](repeating: 0, count: n)
            for (a, b, q) in rawMoves {
                supplies[a % n] += q
                supplies[b % n] -= q
            }
            if seed % 10 == 0 { supplies[0] += 1 }
            let context = "\(ends) capacities \(capacities) costs \(costs) supplies \(supplies)"
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCostFlow(supply: { supplies[$0] }, capacity: { capacities[$0] }, cost: { costs[$0] })

            // The oracle: saturate every negative-cost edge (a self-loop too), then successive shortest
            // paths by Bellman–Ford from a super source to a super sink until the supplies are met.
            var oracleCost: Int? = nil
            if supplies.reduce(0, +) == 0 {
                var f = (0 ..< m).map { costs[$0] < 0 ? capacities[$0] : 0 }
                var b = supplies
                for k in 0 ..< m where ends[k].0 != ends[k].1 {
                    b[ends[k].0] -= f[k]
                    b[ends[k].1] += f[k]
                }
                let need = b.filter { $0 > 0 }.reduce(0, +)
                var shipped = 0
                while shipped < need {
                    // Residual arcs (from, to, room, cost, edge or −1 / −2 for the super arcs, sign).
                    var arcs: [(Int, Int, Int, Int, Int, Int)] = []
                    for k in 0 ..< m where ends[k].0 != ends[k].1 {
                        if f[k] < capacities[k] { arcs.append((ends[k].0, ends[k].1, capacities[k] - f[k], costs[k], k, 1)) }
                        if f[k] > 0 { arcs.append((ends[k].1, ends[k].0, f[k], -costs[k], k, -1)) }
                    }
                    for x in 0 ..< n where b[x] > 0 { arcs.append((n, x, b[x], 0, -1, x)) }
                    for x in 0 ..< n where b[x] < 0 { arcs.append((x, n + 1, -b[x], 0, -2, x)) }
                    var dist = [Int](repeating: Int.max, count: n + 2), via = [Int](repeating: -1, count: n + 2)
                    dist[n] = 0
                    for _ in 0 ..< n + 2 {
                        for (i, arc) in arcs.enumerated() where dist[arc.0] != Int.max && dist[arc.0] + arc.3 < dist[arc.1] {
                            dist[arc.1] = dist[arc.0] + arc.3
                            via[arc.1] = i
                        }
                    }
                    if dist[n + 1] == Int.max { break }
                    var path: [Int] = []
                    var y = n + 1
                    while y != n {
                        path.append(via[y])
                        y = arcs[via[y]].0
                    }
                    let delta = path.map { arcs[$0].2 }.min()!
                    for i in path {
                        let arc = arcs[i]
                        if arc.4 >= 0 { f[arc.4] += delta * arc.5 } else if arc.4 == -1 { b[arc.5] -= delta } else { b[arc.5] += delta }
                    }
                    shipped += delta
                }
                if shipped == need { oracleCost = (0 ..< m).reduce(0) { $0 + f[$1] * costs[$1] } }
            }
            #expect(result?.cost == oracleCost, "\(context)")
            guard let flowResult = result else { return }
            let valueIsSupply = flowResult.value == supplies.filter { $0 > 0 }.reduce(0, +)
            #expect(valueIsSupply, "\(context)")
            let flows = (0 ..< m).map { flowResult.flow(ofEdgeAt: $0) }
            var balance = [Int](repeating: 0, count: n)
            for k in 0 ..< m {
                #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k) \(context)")
                balance[ends[k].0] += flows[k]
                balance[ends[k].1] -= flows[k]
                if ends[k].0 == ends[k].1 { #expect(flows[k] == (costs[k] < 0 ? capacities[k] : 0), "loop \(k) \(context)") }
                let reduced = costs[k] + flowResult.potential(of: ends[k].0) - flowResult.potential(of: ends[k].1)
                if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k) reduced \(reduced) \(context)") }
                if flows[k] > 0 { #expect(reduced <= 0, "edge \(k) reduced \(reduced) \(context)") }
            }
            #expect(balance == supplies, "\(context)")
            let costIsSum = flowResult.cost == (0 ..< m).reduce(0) { $0 + flows[$1] * costs[$1] }
            #expect(costIsSum, "\(context)")
        }
    }

    @Test("Minimum-cost maximum flow: the maximum flow value; the least cost among flows of that value (minimumCostFlow with those supplies); feasible and certified")
    func minimumCostMaximumFlow() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 3), Gen.int(in: -3 ... 5)).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 2 ... 6), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let capacities = raw.map { $0.2 }, costs = raw.map { $0.3 }
            let m = ends.count
            let s = seed % n, t = (seed % n + 1 + (seed / n) % (n - 1)) % n
            let context = "\(ends) capacities \(capacities) costs \(costs) from \(s) to \(t)"
            let graph = DirectedPseudograph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
            let result = graph.minimumCostMaximumFlow(from: s, to: t, capacity: { capacities[$0] }, cost: { costs[$0] })
            let value = graph.maximumFlowValue(from: s, to: t, capacity: { capacities[$0] })
            #expect(result.value == value, "\(context)")
            let alone = graph.minimumCostFlow(supply: { $0 == s ? value : ($0 == t ? -value : 0) }, capacity: { capacities[$0] }, cost: { costs[$0] })
            #expect(alone?.cost == result.cost, "\(context)")
            let flows = (0 ..< m).map { result.flow(ofEdgeAt: $0) }
            var balance = [Int](repeating: 0, count: n)
            for k in 0 ..< m {
                #expect(flows[k] >= 0 && flows[k] <= capacities[k], "edge \(k) \(context)")
                balance[ends[k].0] += flows[k]
                balance[ends[k].1] -= flows[k]
                let reduced = costs[k] + result.potential(of: ends[k].0) - result.potential(of: ends[k].1)
                if flows[k] < capacities[k] { #expect(reduced >= 0, "edge \(k) \(context)") }
                if flows[k] > 0 { #expect(reduced <= 0, "edge \(k) \(context)") }
            }
            let balanced = balance == (0 ..< n).map { $0 == s ? value : ($0 == t ? -value : 0) }
            #expect(balanced, "\(context)")
            let costIsSum = result.cost == (0 ..< m).reduce(0) { $0 + flows[$1] * costs[$1] }
            #expect(costIsSum, "\(context)")
        }
    }

    @Test("Connectivity (Menger): λ(s, t) and κ(s, t) by brute force; that many edge- and vertex-disjoint paths; the s–t vertex cut separates (nil exactly when adjacent); λ(G) and κ(G) by brute force; κ ≤ λ ≤ δ")
    func connectivity() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 22)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 2 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let directed = seed % 2 == 0
            let context = "\(directed ? "directed" : "undirected") \(ends)"
            let digraph = DirectedPseudograph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
            let graph = Pseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            // The simple graph, both ways when undirected.
            var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
            for (a, b) in ends where a != b {
                out[a].insert(b)
                into[b].insert(a)
                if !directed {
                    out[b].insert(a)
                    into[a].insert(b)
                }
            }
            func edgeConnectivity(_ s: Int, _ t: Int) -> Int { directed ? digraph.edgeConnectivity(from: s, to: t) : graph.edgeConnectivity(from: s, to: t) }
            func vertexConnectivity(_ s: Int, _ t: Int) -> Int { directed ? digraph.vertexConnectivity(from: s, to: t) : graph.vertexConnectivity(from: s, to: t) }
            func vertexCut(_ s: Int, _ t: Int) -> [Int]? { directed ? digraph.minimumVertexCut(from: s, to: t) : graph.minimumVertexCut(from: s, to: t) }
            var lambdaBrute = Int.max
            for mask in 1 ..< (1 << n) - 1 {
                var count = 0
                for (a, b) in ends where a != b {
                    let inA = mask & (1 << a) != 0, inB = mask & (1 << b) != 0
                    if directed ? (inA && !inB) : (inA != inB) { count += 1 }
                }
                lambdaBrute = min(lambdaBrute, count)
            }
            for s in 0 ..< n {
                for t in 0 ..< n where t != s {
                    // λ(s, t): the fewest edges from a set holding s but not t; the unit maximum flow.
                    var lambda = Int.max
                    for mask in 0 ..< (1 << n) where mask & (1 << s) != 0 && mask & (1 << t) == 0 {
                        var count = 0
                        for (a, b) in ends where a != b {
                            let inA = mask & (1 << a) != 0, inB = mask & (1 << b) != 0
                            if directed ? (inA && !inB) : (inA != inB) { count += 1 }
                        }
                        lambda = min(lambda, count)
                    }
                    #expect(edgeConnectivity(s, t) == lambda, "λ(\(s), \(t)) \(context)")
                    let unit = directed ? digraph.maximumFlowValue(from: s, to: t, capacity: { _ in 1 }) : graph.maximumFlowValue(from: s, to: t, capacity: { _ in 1 })
                    #expect(unit == lambda, "\(s), \(t) \(context)")
                    // κ(s, t): the fewest other vertices separating s from t without the edges s→t, plus one
                    // for such an edge.
                    let adjacent = out[s].contains(t)
                    var kappa = n
                    for removed in 0 ..< (1 << n) where removed & (1 << s) == 0 && removed & (1 << t) == 0 && removed.nonzeroBitCount < kappa {
                        var seen: Set<Int> = [s], queue = [s]
                        while let x = queue.popLast() {
                            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                                seen.insert(y)
                                queue.append(y)
                            }
                        }
                        if !seen.contains(t) { kappa = removed.nonzeroBitCount }
                    }
                    #expect(vertexConnectivity(s, t) == kappa + (adjacent ? 1 : 0), "κ(\(s), \(t)) \(context)")
                    // Disjoint paths: λ(s, t) edge-disjoint ones and κ(s, t) internally vertex-disjoint ones,
                    // each a path from s to t along its edges (each edge forward, or against its stored
                    // order on an undirected graph), repeating no vertex.
                    for vertexDisjoint in [false, true] {
                        let paths: [(vertices: [Int], edges: [Int], forward: [Bool])]
                        if directed {
                            let found = vertexDisjoint ? digraph.vertexDisjointPaths(from: s, to: t) : digraph.edgeDisjointPaths(from: s, to: t)
                            paths = found.map { ($0.vertices, $0.edges, $0.edges.map { _ in true }) }
                        } else {
                            let found = vertexDisjoint ? graph.vertexDisjointPaths(from: s, to: t) : graph.edgeDisjointPaths(from: s, to: t)
                            paths = found.map { ($0.vertices, $0.edges.map(\.position), $0.edges.map { !$0.reversed }) }
                        }
                        var valid = paths.count == (vertexDisjoint ? kappa + (adjacent ? 1 : 0) : lambda)
                        var usedEdges = Set<Int>(), usedInner = Set<Int>()
                        for path in paths {
                            valid = valid && path.vertices.first == s && path.vertices.last == t && path.vertices.count == path.edges.count + 1
                            valid = valid && Set(path.vertices).count == path.vertices.count
                            for (i, k) in path.edges.enumerated() {
                                let (a, b) = path.forward[i] ? ends[k] : (ends[k].1, ends[k].0)
                                valid = valid && a == path.vertices[i] && b == path.vertices[i + 1] && a != b
                                valid = valid && usedEdges.insert(k).inserted
                            }
                            if vertexDisjoint {
                                for x in path.vertices.dropFirst().dropLast() { valid = valid && usedInner.insert(x).inserted }
                            }
                        }
                        #expect(valid, "\(vertexDisjoint ? "vertex" : "edge")-disjoint paths \(s), \(t) \(paths) \(context)")
                    }
                    let cut = vertexCut(s, t)
                    #expect((cut == nil) == adjacent, "\(s), \(t) \(context)")
                    if let cut {
                        #expect(cut.count == kappa && !cut.contains(s) && !cut.contains(t), "\(s), \(t) \(context)")
                        var seen: Set<Int> = [s], queue = [s]
                        while let x = queue.popLast() {
                            for y in out[x] where !cut.contains(y) && !seen.contains(y) {
                                seen.insert(y)
                                queue.append(y)
                            }
                        }
                        #expect(!seen.contains(t), "\(s), \(t) \(context)")
                    }
                }
            }
            let lambdaG = directed ? digraph.edgeConnectivity() : graph.edgeConnectivity()
            #expect(lambdaG == lambdaBrute, "λ \(context)")
            // κ(G): the fewest vertices whose removal leaves one vertex or a graph not (strongly) connected.
            var kappaBrute = n - 1
            search: for size in 0 ..< n - 1 {
                for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
                    let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
                    var connected = true
                    for rows in [out, into] {
                        var seen: Set<Int> = [kept[0]], queue = [kept[0]]
                        while let x = queue.popLast() {
                            for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                                seen.insert(y)
                                queue.append(y)
                            }
                        }
                        if seen.count != kept.count { connected = false }
                    }
                    if !connected {
                        kappaBrute = size
                        break search
                    }
                }
            }
            let kappaG = directed ? digraph.vertexConnectivity() : graph.vertexConnectivity()
            #expect(kappaG == kappaBrute, "κ \(context)")
            let globalCut = directed ? digraph.minimumVertexCut() : graph.minimumVertexCut()
            #expect(globalCut.count == kappaG, "\(context)")
            if kappaG == n - 1 {
                #expect(globalCut == Array(1 ..< n), "\(context)")
            } else {
                let kept = (0 ..< n).filter { !globalCut.contains($0) }
                var connected = true
                for rows in [out, into] {
                    var seen: Set<Int> = [kept[0]], queue = [kept[0]]
                    while let x = queue.popLast() {
                        for y in rows[x] where !globalCut.contains(y) && !seen.contains(y) {
                            seen.insert(y)
                            queue.append(y)
                        }
                    }
                    if seen.count != kept.count { connected = false }
                }
                #expect(!connected, "\(context)")
            }
            // Whitney: κ ≤ λ ≤ δ (degrees with parallel edges, self-loops never; directed: the least of
            // every in- and out-degree).
            var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
            for (a, b) in ends where a != b {
                outDegree[a] += 1
                inDegree[b] += 1
            }
            let delta = directed ? min(outDegree.min()!, inDegree.min()!) : zip(outDegree, inDegree).map { $0 + $1 }.min()!
            #expect(kappaG <= lambdaG && lambdaG <= delta, "\(context)")
        }
    }
}
