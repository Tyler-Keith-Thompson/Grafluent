// Large inputs, each inside a Task with a one-minute limit, meant to finish within seconds in a
// debug build; the benchmarks take timings. Expected values are known by construction: a long path's
// least capacity and the last edge holding it (the canonical cut is the bottleneck nearest the sink);
// disjoint unit paths and a complete bipartite matching network (every edge into the sink saturated,
// so the sink is alone on its side); a grid's corner degree; a cycle's 2 and a bridge's 1 for
// the global cut (a directed cycle's 1 and a one-way bridge's 0); a path and a cycle for
// Gomory–Hu; hypercubes, cycles and complete graphs for κ and λ;
// an assignment whose only optimum is the identity, parallel routes taken cheapest first, disjoint
// negative cycles; and on seeded random networks the definitions checked in the test (for minimum-cost
// flows: feasibility against a super-source maximum flow and the potentials' optimality certificate,
// some capacities Int.max). See README.md.
// Conditions with a closure are computed into a constant before `#expect`: inside these closures a
// closure in an `#expect` expansion failed SIL verification with this toolchain (README.md).

import AdjacencyListModule
import Flows
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import Testing

@Suite("Flows on large inputs")
struct FlowsStressTests {
    @Test("A path of 5 · 10⁴ edges with capacities (i mod 7) + 1: value 1, the cut the last edge of capacity 1; every maximum flow, directed and undirected", .timeLimit(.minutes(1)))
    func longPath() async {
        await Task {
            let n = 50_001
            let directed = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
            let capacities = (0 ..< n - 1).map { $0 % 7 + 1 }
            // Edges 0, 7, 14, … have capacity 1; the last of them below n − 1 is the bottleneck nearest t.
            let last = (n - 2) / 7 * 7
            for flow in [directed.maximumFlow(from: 0, to: n - 1, capacity: { capacities[$0] }),
                         directed.edmondsKarpMaximumFlow(from: 0, to: n - 1, capacity: { capacities[$0] }),
                         directed.dinicMaximumFlow(from: 0, to: n - 1, capacity: { capacities[$0] })] {
                #expect(flow.value == 1)
                #expect(flow.minimumCut.edges == [last])
                #expect(flow.minimumCut.sinkSide.count == n - 1 - last)
                let everyEdgeCarriesOne = (0 ..< n - 1).allSatisfy { flow.flow(ofEdgeAt: $0) == 1 }
                #expect(everyEdgeCarriesOne)
            }
            let valueIsOne = directed.maximumFlowValue(from: 0, to: n - 1, capacity: { capacities[$0] }) == 1
            #expect(valueIsOne)
            let undirected = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let cut = undirected.minimumCut(from: 0, to: n - 1, capacity: { capacities[$0] })
            #expect(cut.value == 1)
            let cutIsBottleneck = cut.edges.map(\.position) == [last] && cut.edges.allSatisfy { !$0.reversed }
            #expect(cutIsBottleneck)
            // Against the stored order: from the last vertex to the first, the bottleneck nearest 0.
            let back = undirected.dinicMaximumFlow(from: n - 1, to: 0, capacity: { capacities[$0] })
            #expect(back.value == 1)
            #expect(back.minimumCut.edges.map(\.position) == [0] && back.minimumCut.edges.allSatisfy(\.reversed))
            #expect(back.flow(ofEdgeAt: .init(position: 0, reversed: true)) == 1)
        }.value
    }

    @Test("300 disjoint unit paths of 20 edges, and the matching network of K(150, 150): the value is the number of paths (of left vertices); the sink alone on its side", .timeLimit(.minutes(1)))
    func unitNetworks() async {
        await Task {
            // Vertex 0 the source, 1 the sink, then path p's inner vertices 2 + 19p … 20 + 19p.
            var edges: [DirectedEdge<Int>] = []
            for p in 0 ..< 300 {
                let first = 2 + 19 * p
                edges.append(DirectedEdge(from: 0, to: first))
                for i in 0 ..< 18 { edges.append(DirectedEdge(from: first + i, to: first + i + 1)) }
                edges.append(DirectedEdge(from: first + 18, to: 1))
            }
            let paths = AdjacencyList(vertices: 0 ..< 2 + 19 * 300, edges: edges)
            let intoSink = (0 ..< 300).map { 20 * $0 + 19 }
            for flow in [paths.maximumFlow(from: 0, to: 1, capacity: { _ in 1 }),
                         paths.edmondsKarpMaximumFlow(from: 0, to: 1, capacity: { _ in 1 }),
                         paths.dinicMaximumFlow(from: 0, to: 1, capacity: { _ in 1 })] {
                #expect(flow.value == 300)
                #expect(Array(flow.minimumCut.sinkSide) == [1])
                #expect(flow.minimumCut.edges == intoSink)
            }
            #expect(paths.edgeConnectivity(from: 0, to: 1) == 300)
            #expect(paths.vertexConnectivity(from: 0, to: 1) == 300)

            // s = 0, left 1 … 150, right 151 … 300, t = 301; every left–right pair.
            var matching: [DirectedEdge<Int>] = (1 ... 150).map { DirectedEdge(from: 0, to: $0) }
            for l in 1 ... 150 { for r in 151 ... 300 { matching.append(DirectedEdge(from: l, to: r)) } }
            matching += (151 ... 300).map { DirectedEdge(from: $0, to: 301) }
            let network = AdjacencyList(vertices: 0 ... 301, edges: matching)
            let flow = network.dinicMaximumFlow(from: 0, to: 301, capacity: { _ in 1 })
            #expect(flow.value == 150)
            #expect(Array(flow.minimumCut.sinkSide) == [301])
            let preflowValue = network.maximumFlowValue(from: 0, to: 301, capacity: { _ in 1 }) == 150
            #expect(preflowValue)
            let edmondsKarpValue = network.edmondsKarpMaximumFlow(from: 0, to: 301, capacity: { _ in 1 }).value == 150
            #expect(edmondsKarpValue)
            // Each left vertex sends its unit to exactly one right vertex.
            let matched = (150 ..< 150 + 22_500).filter { flow.flow(ofEdgeAt: $0) == 1 }
            #expect(matched.count == 150)
            let perfectMatching = Set(matched.map { network.source(ofEdgeAt: $0) }).count == 150 && Set(matched.map { network.target(ofEdgeAt: $0) }).count == 150
            #expect(perfectMatching)
        }.value
    }

    @Test("grid(150, 150), unit, corner to corner: value 2, the far corner alone on its side, its two edges the cut", .timeLimit(.minutes(1)))
    func grid() async {
        await Task {
            let r = 150, c = 150
            var edges: [UndirectedEdge<Int>] = []
            for i in 0 ..< r {
                for j in 0 ..< c {
                    if j + 1 < c { edges.append(UndirectedEdge(i * c + j, i * c + j + 1)) }
                    if i + 1 < r { edges.append(UndirectedEdge(i * c + j, (i + 1) * c + j)) }
                }
            }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< r * c, edges: edges)
            let t = r * c - 1
            let atCorner = graph.edges.indices.filter { graph.edges[$0].u == t || graph.edges[$0].v == t }
            for flow in [graph.maximumFlow(from: 0, to: t, capacity: { _ in 1 }), graph.dinicMaximumFlow(from: 0, to: t, capacity: { _ in 1 }),
                         graph.edmondsKarpMaximumFlow(from: 0, to: t, capacity: { _ in 1 })] {
                #expect(flow.value == 2)
                #expect(Array(flow.minimumCut.sinkSide) == [t])
                #expect(flow.minimumCut.edges.map(\.position) == atCorner)
            }
            let cornerValue = graph.maximumFlowValue(from: 0, to: t, capacity: { _ in 1 }) == 2
            #expect(cornerValue)
            #expect(graph.edgeConnectivity(from: 0, to: t) == 2)
        }.value
    }

    @Test("A seeded random network of 2,000 vertices and 10,000 edges: the three maximum flows agree, are feasible, and give their cut from their residual networks", .timeLimit(.minutes(1)))
    func randomNetwork() async {
        await Task {
            let n = 2_000
            var rng = SeededRandomNumberGenerator(seed: 26)
            var ends: [(Int, Int)] = []
            var capacities: [Int] = []
            for _ in 0 ..< 10_000 {
                ends.append((Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)))
                capacities.append(Int.random(in: 1 ... 100, using: &rng))
            }
            // AdjacencyList keeps one copy of a repeated arc: read the ends and capacities back by position.
            var seen = Set<[Int]>()
            var kept: [Int] = []
            for k in ends.indices where seen.insert([ends[k].0, ends[k].1]).inserted { kept.append(k) }
            let graph = AdjacencyList(vertices: 0 ..< n, edges: kept.map { DirectedEdge(from: ends[$0].0, to: ends[$0].1) })
            let edgeEnds = kept.map { ends[$0] }, edgeCapacities = kept.map { capacities[$0] }
            let m = kept.count
            let s = 0, t = n - 1
            let flows = [graph.maximumFlow(from: s, to: t, capacity: { edgeCapacities[$0] }),
                         graph.edmondsKarpMaximumFlow(from: s, to: t, capacity: { edgeCapacities[$0] }),
                         graph.dinicMaximumFlow(from: s, to: t, capacity: { edgeCapacities[$0] })]
            let value = flows[0].value
            #expect(value > 0)
            let valueAgrees = graph.maximumFlowValue(from: s, to: t, capacity: { edgeCapacities[$0] }) == value
            #expect(valueAgrees)
            for flow in flows {
                #expect(flow.value == value)
                #expect(flow.minimumCut == flows[0].minimumCut)
                var excess = [Int](repeating: 0, count: n)
                var feasible = true
                for k in 0 ..< m {
                    let f = flow.flow(ofEdgeAt: k)
                    if f < 0 || f > edgeCapacities[k] || (edgeEnds[k].0 == edgeEnds[k].1 && f != 0) { feasible = false }
                    excess[edgeEnds[k].1] += f
                    excess[edgeEnds[k].0] -= f
                }
                #expect(feasible)
                let conserved = (0 ..< n).allSatisfy { $0 == s || $0 == t || excess[$0] == 0 } && excess[t] == value
                #expect(conserved)
                // Reverse search from t over residual arcs, with rows built once.
                var into = [[Int]](repeating: [], count: n), from = [[Int]](repeating: [], count: n)
                for k in 0 ..< m where edgeEnds[k].0 != edgeEnds[k].1 {
                    into[edgeEnds[k].1].append(k)
                    from[edgeEnds[k].0].append(k)
                }
                var reaches = [Bool](repeating: false, count: n)
                reaches[t] = true
                var queue = [t]
                while let y = queue.popLast() {
                    for k in into[y] where !reaches[edgeEnds[k].0] && flow.flow(ofEdgeAt: k) < edgeCapacities[k] {
                        reaches[edgeEnds[k].0] = true
                        queue.append(edgeEnds[k].0)
                    }
                    for k in from[y] where !reaches[edgeEnds[k].1] && flow.flow(ofEdgeAt: k) > 0 {
                        reaches[edgeEnds[k].1] = true
                        queue.append(edgeEnds[k].1)
                    }
                }
                let sinkSideFromResidual = Array(flow.minimumCut.sinkSide) == (0 ..< n).filter { reaches[$0] }
                #expect(sinkSideFromResidual)
                #expect(flow.minimumCut.value == value)
                let cutCapacityIsValue = flow.minimumCut.edges.reduce(0) { $0 + edgeCapacities[$1] } == value
                #expect(cutCapacityIsValue)
            }
        }.value
    }

    @Test("Global cuts: C(600) unit has value 2; two K(30) joined by one edge has value 1 with the first clique as the source side; λ(K(60)) = 59; directed, Cd(600) has value 1 and two Kd(25) joined one way have value 0 with the first, which nothing leaves, as the source side", .timeLimit(.minutes(1)))
    func globalCuts() async {
        await Task {
            let cycle = UndirectedAdjacencyList(vertices: 0 ..< 600, edges: (0 ..< 600).map { UndirectedEdge($0, ($0 + 1) % 600) })
            let cycleCut = cycle.minimumCut(capacity: { _ in 1 })
            #expect(cycleCut?.value == 2)
            #expect(cycleCut?.edges.count == 2)
            let firstOnSourceSide = cycleCut.map { $0.sourceSide.contains(0) } == true
            #expect(firstOnSourceSide)
            var edges: [UndirectedEdge<Int>] = []
            for base in [0, 30] {
                for i in base ..< base + 30 { for j in i + 1 ..< base + 30 { edges.append(UndirectedEdge(i, j)) } }
            }
            edges.append(UndirectedEdge(29, 30))
            let barbell = UndirectedAdjacencyList(vertices: 0 ..< 60, edges: edges)
            let bridge = barbell.minimumCut(capacity: { _ in 1 })
            #expect(bridge?.value == 1)
            let firstCliqueIsSourceSide = bridge.map { Array($0.sourceSide) } == Array(0 ..< 30)
            #expect(firstCliqueIsSourceSide)
            let bridgeIsCut = bridge.map { $0.edges.map(\.position) } == [edges.count - 1]
            #expect(bridgeIsCut)
            #expect(barbell.edgeConnectivity() == 1)
            #expect(barbell.vertexConnectivity() == 1)
            var complete: [UndirectedEdge<Int>] = []
            for i in 0 ..< 60 { for j in i + 1 ..< 60 { complete.append(UndirectedEdge(i, j)) } }
            let k60 = UndirectedAdjacencyList(vertices: 0 ..< 60, edges: complete)
            #expect(k60.edgeConnectivity() == 59)
            let completeCutValue = k60.minimumCut(capacity: { _ in 1 })?.value == 59
            #expect(completeCutValue)
            let directedCycle = AdjacencyList(vertices: 0 ..< 600, edges: (0 ..< 600).map { DirectedEdge(from: $0, to: ($0 + 1) % 600) })
            let directedCycleCut = directedCycle.minimumCut(capacity: { _ in 1 })
            #expect(directedCycleCut?.value == 1 && directedCycleCut?.edges.count == 1)
            #expect(directedCycle.edgeConnectivity() == 1)
            var arcs: [DirectedEdge<Int>] = []
            for base in [0, 25] {
                for i in base ..< base + 25 { for j in base ..< base + 25 where i != j { arcs.append(DirectedEdge(from: i, to: j)) } }
            }
            arcs.append(DirectedEdge(from: 30, to: 3))
            let oneWay = AdjacencyList(vertices: 0 ..< 50, edges: arcs)
            let oneWayCut = oneWay.minimumCut(capacity: { _ in 2 })
            #expect(oneWayCut?.value == 0)
            let sourceCliqueIsSourceSide = oneWayCut.map { $0.sourceSide } == Array(0 ..< 25)
            #expect(sourceCliqueIsSourceSide)
            #expect(oneWay.edgeConnectivity() == 0)
        }.value
    }

    @Test("Gomory–Hu: on a path of 300 vertices the tree is the path with its capacities; on C(200) unit every tree edge and every pair is 2", .timeLimit(.minutes(1)))
    func gomoryHu() async {
        await Task {
            let n = 300
            let path = UndirectedAdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
            let capacities = (0 ..< n - 1).map { ($0 * 37) % 50 + 1 }
            let tree = path.gomoryHuTree(capacity: { capacities[$0] })!
            // Gusfield: the cut from k + 1 to its parent k is the path edge between them, so p[k + 1] = k.
            for k in 0 ..< n - 1 {
                let edge = tree.tree.edges[k]
                #expect(Set([edge.u, edge.v]) == Set([k, k + 1]))
                #expect(tree.capacity(ofEdgeAt: k) == capacities[k])
            }
            #expect(tree.minimumCutValue(between: 0, and: n - 1) == capacities.min()!)
            #expect(tree.minimumCutValue(between: 100, and: 101) == capacities[100])
            let cycle = UndirectedAdjacencyList(vertices: 0 ..< 200, edges: (0 ..< 200).map { UndirectedEdge($0, ($0 + 1) % 200) })
            let ring = cycle.gomoryHuTree(capacity: { _ in 1 })!
            let everyTreeEdgeTwo = (0 ..< 199).allSatisfy { ring.capacity(ofEdgeAt: $0) == 2 }
            #expect(everyTreeEdgeTwo)
            var rng = SeededRandomNumberGenerator(seed: 5)
            for _ in 0 ..< 200 {
                let u = Int.random(in: 0 ..< 200, using: &rng), v = Int.random(in: 0 ..< 200, using: &rng)
                if u != v {
                    #expect(ring.minimumCutValue(between: u, and: v) == 2)
                    #expect(ring.minimumCut(between: u, and: v).edges.count == 2)
                }
            }
        }.value
    }

    @Test("Connectivity: κ = λ = 6 on the hypercube Q(6); κ = λ = 2 on C(300); κ = 1, λ = 1 on Cd(600) and 2 on the bidirected C(200); K(40) all but the first vertex", .timeLimit(.minutes(1)))
    func connectivity() async {
        await Task {
            let d = 6
            var cubeEdges: [UndirectedEdge<Int>] = []
            for i in 0 ..< 1 << d { for b in 0 ..< d where i < i ^ (1 << b) { cubeEdges.append(UndirectedEdge(i, i ^ (1 << b))) } }
            let cube = UndirectedAdjacencyList(vertices: 0 ..< 1 << d, edges: cubeEdges)
            #expect(cube.vertexConnectivity() == 6)
            #expect(cube.edgeConnectivity() == 6)
            #expect(cube.minimumVertexCut().count == 6)
            #expect(cube.vertexConnectivity(from: 0, to: 63) == 6)
            let cycle = UndirectedAdjacencyList(vertices: 0 ..< 300, edges: (0 ..< 300).map { UndirectedEdge($0, ($0 + 1) % 300) })
            #expect(cycle.vertexConnectivity() == 2)
            #expect(cycle.edgeConnectivity() == 2)
            let directedCycle = AdjacencyList(vertices: 0 ..< 600, edges: (0 ..< 600).map { DirectedEdge(from: $0, to: ($0 + 1) % 600) })
            #expect(directedCycle.edgeConnectivity() == 1)
            #expect(directedCycle.vertexConnectivity() == 1)
            let both = AdjacencyList(vertices: 0 ..< 200, edges: (0 ..< 200).flatMap { [DirectedEdge(from: $0, to: ($0 + 1) % 200), DirectedEdge(from: ($0 + 1) % 200, to: $0)] })
            #expect(both.edgeConnectivity() == 2)
            #expect(both.vertexConnectivity() == 2)
            var complete: [UndirectedEdge<Int>] = []
            for i in 0 ..< 40 { for j in i + 1 ..< 40 { complete.append(UndirectedEdge(i, j)) } }
            let k40 = UndirectedAdjacencyList(vertices: 0 ..< 40, edges: complete)
            #expect(k40.vertexConnectivity() == 39)
            #expect(k40.minimumVertexCut() == Array(1 ..< 40))
            #expect(k40.minimumVertexCut(from: 0, to: 39) == nil)
        }.value
    }

    @Test("Minimum-cost flow: a 100 × 100 assignment with costs (i − j)², the identity at cost 0; 200 parallel routes of costs 0 … 199 for 100 units, the cheapest 100; 500 disjoint negative 3-cycles saturated; a chain of 2,000", .timeLimit(.minutes(1)))
    func minimumCost() async {
        await Task {
            let k = 100
            // Rows 0 ..< k, columns k ..< 2k; the edge for (i, j) at position i · k + j.
            var assignment: [DirectedEdge<Int>] = []
            for i in 0 ..< k { for j in 0 ..< k { assignment.append(DirectedEdge(from: i, to: k + j)) } }
            let bipartite = AdjacencyList(vertices: 0 ..< 2 * k, edges: assignment)
            let identity = bipartite.minimumCostFlow(supply: { $0 < k ? 1 : -1 }, capacity: { _ in 1 }, cost: { ($0 / k - $0 % k) * ($0 / k - $0 % k) })
            #expect(identity?.cost == 0)
            let identityFlow = identity.map { flow in (0 ..< k * k).allSatisfy { flow.flow(ofEdgeAt: $0) == ($0 / k == $0 % k ? 1 : 0) } } == true
            #expect(identityFlow)

            // s = 0, t = 1, route i through vertex 2 + i: s→(2 + i) at cost i, then (2 + i)→t at 0.
            var routes: [DirectedEdge<Int>] = []
            for i in 0 ..< 200 { routes += [DirectedEdge(from: 0, to: 2 + i), DirectedEdge(from: 2 + i, to: 1)] }
            let fan = AdjacencyList(vertices: 0 ..< 202, edges: routes)
            let cheapest = fan.minimumCostFlow(supply: { $0 == 0 ? 100 : ($0 == 1 ? -100 : 0) }, capacity: { _ in 1 }, cost: { $0 % 2 == 0 ? $0 / 2 : 0 })
            #expect(cheapest?.cost == (0 ..< 100).reduce(0, +))
            let cheapestRoutes = cheapest.map { flow in (0 ..< 200).allSatisfy { flow.flow(ofEdgeAt: 2 * $0) == ($0 < 100 ? 1 : 0) } } == true
            #expect(cheapestRoutes)
            let maximum = fan.minimumCostMaximumFlow(from: 0, to: 1, capacity: { _ in 1 }, cost: { $0 % 2 == 0 ? $0 / 2 : 0 })
            #expect(maximum.value == 200 && maximum.cost == (0 ..< 200).reduce(0, +))

            var cycles: [DirectedEdge<Int>] = []
            for c in 0 ..< 500 { cycles += [DirectedEdge(from: 3 * c, to: 3 * c + 1), DirectedEdge(from: 3 * c + 1, to: 3 * c + 2), DirectedEdge(from: 3 * c + 2, to: 3 * c)] }
            let negative = AdjacencyList(vertices: 0 ..< 1_500, edges: cycles)
            let saturated = negative.minimumCostFlow(supply: { _ in 0 }, capacity: { _ in 2 }, cost: { _ in -1 })
            #expect(saturated?.cost == -3_000)

            let n = 2_000
            let chain = AdjacencyList(vertices: 0 ..< n, edges: (0 ..< n - 1).map { DirectedEdge(from: $0, to: $0 + 1) })
            let sent = chain.minimumCostFlow(supply: { $0 == 0 ? 5 : ($0 == n - 1 ? -5 : 0) }, capacity: { _ in 10 }, cost: { $0 % 3 })
            let chainCost = sent?.cost == 5 * (0 ..< n - 1).reduce(0) { $0 + $1 % 3 }
            #expect(chainCost)
            let chainFlow = sent.map { flow in (0 ..< n - 1).allSatisfy { flow.flow(ofEdgeAt: $0) == 5 } } == true
            #expect(chainFlow)
        }.value
    }

    @Test("Minimum-cost flow on 60 seeded random networks of 20 – 60 vertices, some capacities Int.max: nil exactly when a super-source maximum flow falls short of the supplies; otherwise within capacity, every supply met, the cost Σ flow × cost, and the potentials certify optimality", .timeLimit(.minutes(1)))
    func randomMinimumCost() async {
        await Task {
            for seed in 1 ... 60 {
                var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
                let n = Int.random(in: 20 ... 60, using: &rng)
                let m = 4 * n
                var ends: [(Int, Int)] = [], capacities: [Int] = [], costs: [Int] = []
                for _ in 0 ..< m {
                    ends.append((Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)))
                    // One edge in ten unbounded (Int.max) at cost zero, so Σ capacity × |cost| fits.
                    if Int.random(in: 0 ..< 10, using: &rng) == 0 {
                        capacities.append(Int.max)
                        costs.append(0)
                    } else {
                        capacities.append(Int.random(in: 0 ... 9, using: &rng))
                        costs.append(Int.random(in: -5 ... 10, using: &rng))
                    }
                }
                var supply = [Int](repeating: 0, count: n)
                for _ in 0 ..< n / 2 {
                    let u = Int.random(in: 0 ..< n, using: &rng), v = Int.random(in: 0 ..< n, using: &rng), amount = Int.random(in: 0 ... 9, using: &rng)
                    supply[u] += amount
                    supply[v] -= amount
                }
                let graph = DirectedPseudograph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                let result = graph.minimumCostFlow(supply: { supply[$0] }, capacity: { capacities[$0] }, cost: { costs[$0] })

                // Feasible exactly when a maximum flow from a super source n (an edge of capacity b
                // to each supply b > 0) to a super sink n + 1 (from each demand) carries every supply.
                var superEnds = ends, superCapacities = capacities
                for v in 0 ..< n where supply[v] != 0 {
                    superEnds.append(supply[v] > 0 ? (n, v) : (v, n + 1))
                    superCapacities.append(abs(supply[v]))
                }
                let network = DirectedPseudograph(vertices: 0 ..< n + 2, edges: superEnds.map { DirectedEdge(from: $0.0, to: $0.1) })
                let total = supply.filter { $0 > 0 }.reduce(0, +)
                let feasible = network.maximumFlowValue(from: n, to: n + 1, capacity: { superCapacities[$0] }) == total
                #expect((result != nil) == feasible, "seed \(seed)")
                guard let result else { continue }

                var balance = [Int](repeating: 0, count: n)
                var cost = 0
                var withinCapacity = true, certified = true
                for k in 0 ..< m {
                    let f = result.flow(ofEdgeAt: k), (u, v) = ends[k]
                    withinCapacity = withinCapacity && f >= 0 && f <= capacities[k]
                    cost &+= f &* costs[k]
                    if u == v {
                        certified = certified && f == (costs[k] < 0 ? capacities[k] : 0)
                        continue
                    }
                    balance[u] &+= f
                    balance[v] &-= f
                    let reduced = costs[k] + result.potential(of: u) - result.potential(of: v)
                    certified = certified && (f == capacities[k] || reduced >= 0) && (f == 0 || reduced <= 0)
                }
                #expect(withinCapacity, "seed \(seed)")
                #expect(balance == supply, "seed \(seed)")
                #expect(result.cost == cost && result.value == total, "seed \(seed)")
                #expect(certified, "seed \(seed)")
            }

            // Two supplies summing to Int.max, both shipped through the cheaper route: 0 sends
            // Int.max − 5 to 1 at cost −1, and 1 passes everything on to the demand at 2.
            let triangle = AdjacencyList<Int>(vertices: 0 ..< 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)])
            let supplies = [Int.max - 5, 5, -Int.max], costs = [-1, 0, 0]
            let shipped = triangle.minimumCostFlow(supply: { supplies[$0] }, capacity: { _ in Int.max }, cost: { costs[$0] })
            #expect(shipped?.cost == -(Int.max - 5))
            #expect(shipped.map { Array($0.flowMap) } == [Int.max - 5, Int.max, 0])
        }.value
    }

    @Test("Global minimum cut on 1,500 seeded dense graphs of 5 – 12 vertices with Double capacities 1 … 20 (so the heap orders every phase, five or more groups in it): the value is the least maximum flow from the first vertex, and the cut's edges carry it", .timeLimit(.minutes(1)))
    func denseDoubleGlobalCuts() async {
        await Task {
            for seed in 1 ... 1_500 {
                var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
                let n = Int.random(in: 5 ... 12, using: &rng)
                var pairs: [(Int, Int)] = []
                for u in 0 ..< n { for v in (u + 1) ..< n where Int.random(in: 0 ..< 10, using: &rng) < 7 { pairs.append((u, v)) } }
                let capacities = pairs.map { _ in Double(Int.random(in: 1 ... 20, using: &rng)) }
                let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
                guard let cut = graph.minimumCut(capacity: { capacities[$0] }) else { continue }
                let least = (1 ..< n).map { graph.maximumFlowValue(from: 0, to: $0, capacity: { capacities[$0] }) }.min()!
                #expect(cut.value == least, "seed \(seed)")
                var crossing = 0.0
                let sink = Set(cut.sinkSide)
                for (k, (u, v)) in pairs.enumerated() where sink.contains(u) != sink.contains(v) { crossing += capacities[k] }
                #expect(crossing == cut.value && !sink.contains(0), "seed \(seed)")
            }
        }.value
    }

    @Test("Global minimum cut on clustered graphs whose capacities up to 10⁶ need the heap, six fixed (n, degree, seed) inputs: the value is the least maximum flow from the first vertex, in Int and in Double quarters", .timeLimit(.minutes(1)))
    func clusteredHeapGlobalCuts() async {
        await Task {
            // Inputs where a maximum adjacency order that loses track of a heap entry contracts an
            // edge across the minimum cut.
            for (n, degree, seed) in [(27, 3, 93_401), (20, 5, 383_889), (20, 4, 417_141), (20, 5, 93_757), (24, 4, 351_297), (27, 4, 355_005)] {
                var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
                // Clusters (seed mod 4 of them, 1 meaning none): edges inside a cluster heavy, edges
                // between light, so the minimum cut is usually a whole cluster.
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
                _ = heavy.map { _ in Int.random(in: 1 ... 9, using: &rng) }  // the property test's small capacities, drawn first
                let capacities = heavy.map { Int.random(in: 1 ... 100_000, using: &rng) * ($0 ? 10 : 1) }
                // Pseudograph: a pair drawn twice is two edges, as the capacities count them.
                let graph = Pseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                let fromFirst = (1 ..< n).map { graph.maximumFlowValue(from: 0, to: $0, capacity: { capacities[$0] }) }.min()!
                let cut = graph.minimumCut(capacity: { capacities[$0] })
                #expect(cut?.value == fromFirst, "n \(n) degree \(degree) seed \(seed)")
                let quarters = graph.minimumCut(capacity: { Double(capacities[$0]) / 4 })
                #expect(quarters?.value == Double(fromFirst) / 4, "n \(n) degree \(degree) seed \(seed)")
            }
        }.value
    }
}
