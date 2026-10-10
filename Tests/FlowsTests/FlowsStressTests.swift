// Large inputs, each inside a Task with a one-minute limit, meant to finish within seconds in a
// debug build; the benchmarks take timings. Expected values are known by construction: a long path's
// least capacity and the last edge holding it (the canonical cut is the bottleneck nearest the sink);
// disjoint unit paths and a complete bipartite matching network (every edge into the sink saturated,
// so the sink is alone on its side); a grid's corner degree; a cycle's 2 and a bridge's 1 for
// the global cut (a directed cycle's 1 and a one-way bridge's 0); a path and a cycle for
// Gomory–Hu; hypercubes, cycles and complete graphs for κ and λ;
// an assignment whose only optimum is the identity, parallel routes taken cheapest first, disjoint
// negative cycles; and on seeded random networks the definitions checked in the test. See README.md.
// Conditions with a closure are computed into a constant before `#expect`: inside these closures a
// closure in an `#expect` expansion failed SIL verification with this toolchain (README.md).

import AdjacencyListModule
import Flows
import GrafluentTestSupport
import GraphProtocols
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
}
