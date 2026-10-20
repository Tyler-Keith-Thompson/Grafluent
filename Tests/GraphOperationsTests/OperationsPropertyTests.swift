// Properties with shrinking (swift-property-based) for the relabelings, the binary operations
// (union, intersection, difference, symmetric difference), the power, the ego graph, the
// contractions and the transitive closure and reduction. Random pseudographs, directed and
// undirected, with parallel edges and self-loops, against models written out beside them: label
// lists and edge sets, distances by Floyd–Warshall, reachability by Warshall. See README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphOperations
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("GraphOperations relabelings, binary operations, powers, ego graphs, contractions and closures against models", .tags(.randomized))
struct OperationsPropertyTests {
    @Test("relabeled(_:by:): distinct names at their first occurrence, every edge renamed in edges order, merged names joined")
    func relabeledByLaws() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: input, Gen.int(in: 0 ... 4).array(of: 7 ... 7)) { raw, image in
            let names = (0 ..< 7).map { "r\($0)" }
            let rename: (String) -> String = { "n\(image[Int($0.dropFirst())!])" }
            var vertices: [String] = []
            for name in names where !vertices.contains(rename(name)) { vertices.append(rename(name)) }
            let renamed = raw.map { [rename(names[$0.0]), rename(names[$0.1])] }
            var firsts: [[String]] = []
            for e in renamed where !firsts.contains(e) { firsts.append(e) }

            let directed = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let pseudo = DirectedPseudograph<String>.relabeled(directed, by: rename)
            #expect(Array(pseudo.vertices) == vertices, "\(raw) \(image)")
            #expect(pseudo.edges.map { [$0.source, $0.target] } == renamed, "\(raw) \(image)")
            let simple = AdjacencyList<String>.relabeled(directed, by: rename)
            #expect(Array(simple.vertices) == vertices, "\(raw) \(image)")
            #expect(simple.edges.map { [$0.source, $0.target] } == firsts, "\(raw) \(image)")

            let undirected = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            let upseudo = Pseudograph<String>.relabeled(undirected, by: rename)
            #expect(Array(upseudo.vertices) == vertices, "\(raw) \(image)")
            #expect(upseudo.edges.map { [$0.u, $0.v] } == renamed, "\(raw) \(image)")
            var ufirsts: [[String]] = []
            for e in renamed where !ufirsts.contains(e) && !ufirsts.contains([e[1], e[0]]) { ufirsts.append(e) }
            let usimple = UndirectedAdjacencyList<String>.relabeled(undirected, by: rename)
            #expect(Array(usimple.vertices) == vertices, "\(raw) \(image)")
            #expect(usimple.edges.map { [$0.u, $0.v] } == ufirsts, "\(raw) \(image)")
        }
    }

    @Test("relabeled(_:ordering:): ordering[i] becomes vertex i, rows ascending, parallel edges merged")
    func relabeledOrderingLaws() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: input, Gen.int(in: 0 ... 1000).array(of: 7 ... 7)) { raw, keys in
            let names = (0 ..< 7).map { "o\($0)" }
            let order = (0 ..< 7).sorted { (keys[$0], $0) < (keys[$1], $1) }
            var rank = [Int](repeating: 0, count: 7)
            for (r, i) in order.enumerated() { rank[i] = r }
            let loopless = raw.filter { $0.0 != $0.1 }
            let directed = DirectedPseudograph<String>(vertices: names, edges: loopless.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let arcs = Set(loopless.map { [rank[$0.0], rank[$0.1]] }).sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
            let result = CompressedSparseRow.relabeled(directed, ordering: order.map { names[$0] })
            #expect(result.vertexCount == 7 && result.edges.map { [$0.source, $0.target] } == arcs, "\(raw) \(keys)")
            let undirected = Pseudograph<String>(vertices: names, edges: loopless.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            let pairs = Set(loopless.map { [Swift.min(rank[$0.0], rank[$0.1]), Swift.max(rank[$0.0], rank[$0.1])] }).sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
            let renumbered = UndirectedAdjacencyList<Int>.relabeled(undirected, ordering: order.map { names[$0] })
            #expect(renumbered.vertexCount == 7 && renumbered.edges.map { [$0.u, $0.v] } == pairs, "\(raw) \(keys)")
        }
    }

    @Test("union, intersection, difference and symmetricDifference: vertex lists and edge sets, rows in result order")
    func binaryOperationLaws() async {
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: pairs, pairs, Gen.int(in: 0 ... 1).array(of: 6 ... 6), Gen.int(in: 0 ... 1).array(of: 6 ... 6)) { rawG, rawH, inG, inH in
            let names = (0 ..< 6).map { "b\($0)" }
            // h lists its vertices in reverse, so its order differs from g's.
            let gNames = names.indices.filter { inG[$0] == 1 }.map { names[$0] }
            let hNames = names.indices.filter { inH[$0] == 1 }.reversed().map { names[$0] }
            let gArcs = rawG.map { [names[$0.0], names[$0.1]] }.filter { gNames.contains($0[0]) && gNames.contains($0[1]) }
            let hArcs = rawH.map { [names[$0.0], names[$0.1]] }.filter { hNames.contains($0[0]) && hNames.contains($0[1]) }
            let g = DirectedPseudograph<String>(vertices: gNames, edges: gArcs.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let h = DirectedPseudograph<String>(vertices: hNames, edges: hArcs.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let both = gNames + hNames.filter { !gNames.contains($0) }
            let shared = gNames.filter { hNames.contains($0) }
            let gSet = Set(gArcs), hSet = Set(hArcs)
            func ordered(_ edges: Set<[String]>, _ vertices: [String]) -> [[String]] {
                edges.sorted { (vertices.firstIndex(of: $0[0])!, vertices.firstIndex(of: $0[1])!) < (vertices.firstIndex(of: $1[0])!, vertices.firstIndex(of: $1[1])!) }
            }
            let union = AdjacencyList<String>.union(g, h)
            #expect(Array(union.vertices) == both && union.edges.map { [$0.source, $0.target] } == ordered(gSet.union(hSet), both), "\(rawG) \(rawH) \(inG) \(inH)")
            let intersection = DirectedPseudograph<String>.intersection(g, h)
            #expect(Array(intersection.vertices) == shared && intersection.edges.map { [$0.source, $0.target] } == ordered(gSet.intersection(hSet), shared), "\(rawG) \(rawH) \(inG) \(inH)")
            let difference = AdjacencyList<String>.difference(g, h)
            #expect(Array(difference.vertices) == gNames && difference.edges.map { [$0.source, $0.target] } == ordered(gSet.subtracting(hSet), gNames), "\(rawG) \(rawH) \(inG) \(inH)")
            let symmetric = AdjacencyList<String>.symmetricDifference(g, h)
            #expect(Array(symmetric.vertices) == both && symmetric.edges.map { [$0.source, $0.target] } == ordered(gSet.symmetricDifference(hSet), both), "\(rawG) \(rawH) \(inG) \(inH)")

            // Undirected: an edge is an unordered pair, inserted earlier end first.
            let gu = Pseudograph<String>(vertices: gNames, edges: gArcs.map { UndirectedEdge($0[0], $0[1]) })
            let hu = Pseudograph<String>(vertices: hNames, edges: hArcs.map { UndirectedEdge($0[0], $0[1]) })
            func unordered(_ arcs: [[String]]) -> Set<Set<String>> { Set(arcs.map { Set($0) }) }
            func pairs(_ edges: Set<Set<String>>, _ vertices: [String]) -> [[String]] {
                edges.map { $0.sorted { vertices.firstIndex(of: $0)! < vertices.firstIndex(of: $1)! } }
                    .map { $0.count == 1 ? [$0[0], $0[0]] : $0 }
                    .sorted { (vertices.firstIndex(of: $0[0])!, vertices.firstIndex(of: $0[1])!) < (vertices.firstIndex(of: $1[0])!, vertices.firstIndex(of: $1[1])!) }
            }
            let gu2 = unordered(gArcs), hu2 = unordered(hArcs)
            let uunion = UndirectedAdjacencyList<String>.union(gu, hu)
            #expect(Array(uunion.vertices) == both && uunion.edges.map { [$0.u, $0.v] } == pairs(gu2.union(hu2), both), "\(rawG) \(rawH) \(inG) \(inH)")
            let uintersection = Pseudograph<String>.intersection(gu, hu)
            #expect(Array(uintersection.vertices) == shared && uintersection.edges.map { [$0.u, $0.v] } == pairs(gu2.intersection(hu2), shared), "\(rawG) \(rawH) \(inG) \(inH)")
            let udifference = UndirectedAdjacencyList<String>.difference(gu, hu)
            #expect(Array(udifference.vertices) == gNames && udifference.edges.map { [$0.u, $0.v] } == pairs(gu2.subtracting(hu2), gNames), "\(rawG) \(rawH) \(inG) \(inH)")
            let usymmetric = UndirectedAdjacencyList<String>.symmetricDifference(gu, hu)
            #expect(Array(usymmetric.vertices) == both && usymmetric.edges.map { [$0.u, $0.v] } == pairs(gu2.symmetricDifference(hu2), both), "\(rawG) \(rawH) \(inG) \(inH)")
        }
    }

    @Test("power(of:_:): an edge between distinct vertices at distance at most k, by Floyd–Warshall")
    func powerLaws() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: input, Gen.int(in: 1 ... 7)) { raw, k in
            let names = (0 ..< 7).map { "p\($0)" }
            let unreachable = 100
            for directed in [true, false] {
                var d = [[Int]](repeating: [Int](repeating: unreachable, count: 7), count: 7)
                for i in 0 ..< 7 { d[i][i] = 0 }
                for (a, b) in raw where a != b {
                    d[a][b] = 1
                    if !directed { d[b][a] = 1 }
                }
                for m in 0 ..< 7 { for i in 0 ..< 7 { for j in 0 ..< 7 where d[i][m] + d[m][j] < d[i][j] { d[i][j] = d[i][m] + d[m][j] } } }
                var expected: [[Int]] = []
                for i in 0 ..< 7 { for j in 0 ..< 7 where i != j && d[i][j] <= k && (directed || i < j) { expected.append([i, j]) } }
                if directed {
                    let graph = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
                    let power = CompressedSparseRow.power(of: graph, k)
                    #expect(power.vertexCount == 7 && power.edges.map { [$0.source, $0.target] } == expected, "\(raw) \(k)")
                } else {
                    let graph = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
                    let power = UndirectedAdjacencyList<Int>.power(of: graph, k)
                    #expect(power.vertexCount == 7 && power.edges.map { [$0.u, $0.v] } == expected, "\(raw) \(k)")
                }
            }
        }
    }

    @Test("egoGraphView(of:radius:): the induced subgraph on the vertices within the radius, by Floyd–Warshall")
    func egoGraphLaws() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: input, Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 4)) { raw, center, radius in
            let names = (0 ..< 7).map { "e\($0)" }
            let unreachable = 100
            func distances(_ forward: Bool, _ backward: Bool) -> [Int] {
                var d = [[Int]](repeating: [Int](repeating: unreachable, count: 7), count: 7)
                for i in 0 ..< 7 { d[i][i] = 0 }
                for (a, b) in raw {
                    if forward { d[a][b] = Swift.min(d[a][b], 1) }
                    if backward { d[b][a] = Swift.min(d[b][a], 1) }
                }
                for m in 0 ..< 7 { for i in 0 ..< 7 { for j in 0 ..< 7 where d[i][m] + d[m][j] < d[i][j] { d[i][j] = d[i][m] + d[m][j] } } }
                return d[center]
            }
            let directed = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            for (view, d) in [(directed.egoGraphView(of: names[center], radius: radius), distances(true, false)),
                              (directed.egoGraphView(of: names[center], radius: radius, undirected: false), distances(true, false)),
                              (directed.egoGraphView(of: names[center], radius: radius, undirected: true), distances(true, true))] {
                let kept = names.indices.filter { d[$0] <= radius }.map { names[$0] }
                let induced = directed.inducedSubgraphView(on: kept)
                #expect(Array(view.vertices) == kept, "\(raw) \(center) \(radius)")
                #expect(Array(view.edges.indices) == Array(induced.edges.indices), "\(raw) \(center) \(radius)")
                for i in kept.indices {
                    #expect(Array(view.successorIndices(ofIndex: i)) == Array(induced.successorIndices(ofIndex: i)), "\(raw) \(center) \(radius)")
                    #expect(Array(view.predecessorIndices(ofIndex: i)) == Array(induced.predecessorIndices(ofIndex: i)), "\(raw) \(center) \(radius)")
                }
            }
            let undirected = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            let d = distances(true, true)
            let kept = names.indices.filter { d[$0] <= radius }.map { names[$0] }
            let view = undirected.egoGraphView(of: names[center], radius: radius)
            let induced = undirected.inducedSubgraphView(on: kept)
            #expect(Array(view.vertices) == kept, "\(raw) \(center) \(radius)")
            #expect(Array(view.edges.indices) == Array(induced.edges.indices), "\(raw) \(center) \(radius)")
            for i in kept.indices {
                #expect(Array(view.neighborIndices(ofIndex: i)) == Array(induced.neighborIndices(ofIndex: i)), "\(raw) \(center) \(radius)")
            }
        }
    }

    @Test("egoGraphView(of:radius:maximumVertexCount:priority:) with several centers: the union of the ego graphs by Floyd–Warshall, and the budget cuts the overflowing layer by priority then index")
    func egoGraphCentersLaws() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 14)
        let centers = Gen.int(in: 0 ... 6).array(of: 0 ... 3)
        let priorities = Gen.int(in: 0 ... 2).array(of: 7 ... 7)
        await propertyCheck(count: 300, input: input, centers, Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 8), priorities) { raw, rawCenters, radius, cap, rawPriority in
            let names = (0 ..< 7).map { "e\($0)" }
            let unreachable = 100
            func distances(_ forward: Bool, _ backward: Bool) -> [[Int]] {
                var d = [[Int]](repeating: [Int](repeating: unreachable, count: 7), count: 7)
                for i in 0 ..< 7 { d[i][i] = 0 }
                for (a, b) in raw {
                    if forward { d[a][b] = Swift.min(d[a][b], 1) }
                    if backward { d[b][a] = Swift.min(d[b][a], 1) }
                }
                for m in 0 ..< 7 { for i in 0 ..< 7 { for j in 0 ..< 7 where d[i][m] + d[m][j] < d[i][j] { d[i][j] = d[i][m] + d[m][j] } } }
                return d
            }
            // The oracle: layers by least distance to any center, kept whole while they fit; the
            // overflowing layer cut to the greatest priorities, ties to the lower index.
            func kept(_ d: [[Int]], limit: Int?) -> [Int] {
                guard !rawCenters.isEmpty else { return [] }
                var out: [Int] = []
                for layer in 0 ... radius {
                    let members = (0 ..< 7).filter { v in rawCenters.map { d[$0][v] }.min()! == layer }
                    if let limit, out.count + members.count > limit {
                        let ranked = members.sorted { rawPriority[$0] > rawPriority[$1] || (rawPriority[$0] == rawPriority[$1] && $0 < $1) }
                        out += ranked.prefix(limit - out.count)
                        break
                    }
                    out += members
                }
                return out.sorted()
            }
            let centerNames = rawCenters.map { names[$0] }
            let priority = { (v: String) -> Int in rawPriority[names.firstIndex(of: v)!] }
            let context = "\(raw) centers \(rawCenters) radius \(radius) cap \(cap) priorities \(rawPriority)"
            let directed = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let forward = distances(true, false), both = distances(true, true)
            for (view, want) in [(directed.egoGraphView(of: centerNames, radius: radius), kept(forward, limit: nil)),
                                 (directed.egoGraphView(of: centerNames, radius: radius, undirected: true), kept(both, limit: nil)),
                                 (directed.egoGraphView(of: centerNames, radius: radius, maximumVertexCount: cap, priority: priority), kept(forward, limit: cap)),
                                 (directed.egoGraphView(of: centerNames, radius: radius, undirected: true, maximumVertexCount: cap, priority: priority), kept(both, limit: cap))] {
                let induced = directed.inducedSubgraphView(on: want.map { names[$0] })
                #expect(Array(view.vertices) == want.map { names[$0] }, "\(context)")
                #expect(Array(view.edges.indices) == Array(induced.edges.indices), "\(context)")
                for i in want.indices {
                    #expect(Array(view.successorIndices(ofIndex: i)) == Array(induced.successorIndices(ofIndex: i)), "\(context)")
                    #expect(Array(view.predecessorIndices(ofIndex: i)) == Array(induced.predecessorIndices(ofIndex: i)), "\(context)")
                }
            }
            let undirected = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            for (view, want) in [(undirected.egoGraphView(of: centerNames, radius: radius), kept(both, limit: nil)),
                                 (undirected.egoGraphView(of: centerNames, radius: radius, maximumVertexCount: cap, priority: priority), kept(both, limit: cap))] {
                let induced = undirected.inducedSubgraphView(on: want.map { names[$0] })
                #expect(Array(view.vertices) == want.map { names[$0] }, "\(context)")
                #expect(Array(view.edges.indices) == Array(induced.edges.indices), "\(context)")
                for i in want.indices {
                    #expect(Array(view.neighborIndices(ofIndex: i)) == Array(induced.neighborIndices(ofIndex: i)), "\(context)")
                }
            }
            // One center is the single-center spelling, and a cap of 7 changes nothing.
            if let first = rawCenters.first {
                #expect(Array(directed.egoGraphView(of: [names[first]], radius: radius).vertices) == Array(directed.egoGraphView(of: names[first], radius: radius).vertices), "\(context)")
                #expect(Array(undirected.egoGraphView(of: centerNames, radius: radius, maximumVertexCount: 7, priority: priority).vertices) == Array(undirected.egoGraphView(of: centerNames, radius: radius).vertices), "\(context)")
            }
        }
    }

    @Test("rootedProduct and coronaProduct: the edge sets of their definitions, numbered a·|V(h)| + b and |V(g)| + a·|V(h)| + b")
    func productLaws() async {
        let gEdges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 8)
        let hEdges = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 3)).array(of: 0 ... 6)
        await propertyCheck(count: 300, input: gEdges, Gen.int(in: 0 ... 5), hEdges, Gen.int(in: 1 ... 4), Gen.int(in: 0 ... 3)) { rawG, ng, rawH, nh, rawRoot in
            let gPairs = ng == 0 ? [] : rawG.map { ($0.0 % ng, $0.1 % ng) }.filter { $0.0 != $0.1 }
            let hPairs = rawH.map { ($0.0 % nh, $0.1 % nh) }.filter { $0.0 != $0.1 }
            let root = rawRoot % nh
            let context = "g \(ng) \(gPairs), h \(nh) \(hPairs), root \(root)"
            // Directed: the arcs of the definitions, as sets.
            var rooted = Set<[Int]>(), corona = Set<[Int]>()
            for a in 0 ..< ng {
                for (b, c) in hPairs {
                    rooted.insert([a * nh + b, a * nh + c])
                    corona.insert([ng + a * nh + b, ng + a * nh + c])
                }
                for b in 0 ..< nh { corona.insert([a, ng + a * nh + b]) }
            }
            for (a, a2) in gPairs {
                rooted.insert([a * nh + root, a2 * nh + root])
                corona.insert([a, a2])
            }
            let g = DirectedPseudograph(vertices: 0 ..< ng, edges: gPairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let h = DirectedPseudograph(vertices: 0 ..< nh, edges: hPairs.map { DirectedEdge(from: $0.0, to: $0.1) })
            let r = CompressedSparseRow.rootedProduct(g, h, root: root)
            #expect(r.vertexCount == ng * nh, "\(context)")
            #expect(Set(r.edges.map { [$0.source, $0.target] }) == rooted, "\(context)")
            #expect(r.edges.map { [$0.source, $0.target] } == r.edges.map { [$0.source, $0.target] }.sorted { $0.lexicographicallyPrecedes($1) }, "row-major; \(context)")
            #expect((try? CompressedSparseRow.rootedProduct(g, h, checkedRoot: root)) == r, "\(context)")
            let c = AdjacencyList<Int>.coronaProduct(g, h)
            #expect(c.vertexCount == ng + ng * nh, "\(context)")
            #expect(Set(c.edges.map { [$0.source, $0.target] }) == corona, "\(context)")
            // Undirected: the same with orientations dropped.
            let ug = Pseudograph(vertices: 0 ..< ng, edges: gPairs.map { UndirectedEdge($0.0, $0.1) })
            let uh = Pseudograph(vertices: 0 ..< nh, edges: hPairs.map { UndirectedEdge($0.0, $0.1) })
            let ur = UndirectedAdjacencyList<Int>.rootedProduct(ug, uh, root: root)
            #expect(ur.vertexCount == ng * nh, "\(context)")
            #expect(Set(ur.edges.map { [Swift.min($0.u, $0.v), Swift.max($0.u, $0.v)] }) == Set(rooted.map { [Swift.min($0[0], $0[1]), Swift.max($0[0], $0[1])] }), "\(context)")
            #expect((try? UndirectedAdjacencyList<Int>.rootedProduct(ug, uh, checkedRoot: root)) == ur, "\(context)")
            let uc = UndirectedAdjacencyList<Int>.coronaProduct(ug, uh)
            #expect(uc.vertexCount == ng + ng * nh, "\(context)")
            #expect(Set(uc.edges.map { [Swift.min($0.u, $0.v), Swift.max($0.u, $0.v)] }) == Set(corona.map { [Swift.min($0[0], $0[1]), Swift.max($0[0], $0[1])] }), "\(context)")
            #expect(throws: VertexNotFound.self) { try CompressedSparseRow.rootedProduct(g, h, checkedRoot: nh) }
            #expect(throws: VertexNotFound.self) { try UndirectedAdjacencyList<Int>.rootedProduct(ug, uh, checkedRoot: -1) }
        }
    }

    @Test("contraction(of:_:_:) and contraction(of:edgeAt:): the ends merged at the smaller index, later vertices moved down, loops dropped")
    func contractionLaws() async {
        let input = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 1 ... 14)
        await propertyCheck(count: 300, input: input, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)) { raw, u, v in
            let names = (0 ..< 6).map { "c\($0)" }
            func model(_ u: Int, _ v: Int, directed: Bool) -> (count: Int, edges: [[Int]]) {
                let a = Swift.min(u, v), b = Swift.max(u, v)
                let map = (0 ..< 6).map { a == b ? $0 : ($0 < b ? $0 : ($0 == b ? a : $0 - 1)) }
                let edges = Set(raw.map { [map[$0.0], map[$0.1]] }.filter { $0[0] != $0[1] }.map { directed ? $0 : [$0.min()!, $0.max()!] })
                return (a == b ? 6 : 5, edges.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) })
            }
            let directed = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let want = model(u, v, directed: true)
            let byVertices = CompressedSparseRow.contraction(of: directed, names[u], names[v])
            #expect(byVertices.vertexCount == want.count && byVertices.edges.map { [$0.source, $0.target] } == want.edges, "\(raw) \(u) \(v)")
            let alongEdge = CompressedSparseRow.contraction(of: directed, edgeAt: 0)
            let edgeWant = model(raw[0].0, raw[0].1, directed: true)
            #expect(alongEdge.vertexCount == edgeWant.count && alongEdge.edges.map { [$0.source, $0.target] } == edgeWant.edges, "\(raw)")

            let undirected = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            let uwant = model(u, v, directed: false)
            let ubyVertices = UndirectedAdjacencyList<Int>.contraction(of: undirected, names[u], names[v])
            #expect(ubyVertices.vertexCount == uwant.count && ubyVertices.edges.map { [$0.u, $0.v] } == uwant.edges, "\(raw) \(u) \(v)")
            let ualongEdge = UndirectedAdjacencyList<Int>.contraction(of: undirected, edgeAt: 0)
            let uedgeWant = model(raw[0].0, raw[0].1, directed: false)
            #expect(ualongEdge.vertexCount == uedgeWant.count && ualongEdge.edges.map { [$0.u, $0.v] } == uedgeWant.edges, "\(raw)")
        }
    }

    @Test("transitiveClosure(of:) and transitiveReduction(of:) on graphs with cycles, by Warshall and Aho–Garey–Ullman")
    func closureAndReductionLaws() async {
        let input = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: input) { raw in
            let names = (0 ..< 8).map { "t\($0)" }
            var reach = [[Bool]](repeating: [Bool](repeating: false, count: 8), count: 8)
            for (a, b) in raw { reach[a][b] = true }
            for m in 0 ..< 8 { for i in 0 ..< 8 where reach[i][m] { for j in 0 ..< 8 where reach[m][j] { reach[i][j] = true } } }
            var closure: [[Int]] = []
            for i in 0 ..< 8 { for j in 0 ..< 8 where i != j && reach[i][j] { closure.append([i, j]) } }
            let graph = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let result = CompressedSparseRow.transitiveClosure(of: graph)
            #expect(result.vertexCount == 8 && result.edges.map { [$0.source, $0.target] } == closure, "\(raw)")

            // Aho–Garey–Ullman: a cycle through each component of two or more in index order, and an
            // arc between the first members of C and D when C reaches D through no third component.
            let same: (Int, Int) -> Bool = { $0 == $1 || (reach[$0][$1] && reach[$1][$0]) }
            let first = (0 ..< 8).map { i in (0 ..< 8).first { same(i, $0) }! }
            var arcs: Set<[Int]> = []
            for leader in Set(first) {
                let members = (0 ..< 8).filter { first[$0] == leader }
                if members.count > 1 {
                    for (k, m) in members.enumerated() { arcs.insert([m, members[(k + 1) % members.count]]) }
                }
            }
            let leaders = Set(first)
            for c in leaders {
                for d in leaders where c != d && reach[c][d] {
                    if !leaders.contains(where: { e in e != c && e != d && reach[c][e] && reach[e][d] }) { arcs.insert([c, d]) }
                }
            }
            let reduction = CompressedSparseRow.transitiveReduction(of: graph)
            #expect(reduction.vertexCount == 8 && reduction.edges.map { [$0.source, $0.target] } == arcs.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }, "\(raw)")
            // Same reachability: the closure of the reduction is the closure.
            #expect(CompressedSparseRow.transitiveClosure(of: reduction).edges.map { [$0.source, $0.target] } == closure, "\(raw)")

            // Acyclic input: the unique reduction, the DAG module's own.
            let forward = raw.filter { $0.0 < $0.1 }
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< 8, edges: forward.map { DirectedEdge(from: $0.0, to: $0.1) })!
            let reduced = dag.transitiveReduction()
            let ours = CompressedSparseRow.transitiveReduction(of: dag)
            #expect(Set(ours.edges.map { [$0.source, $0.target] }) == Set(reduced.edges.map { [$0.source, $0.target] }), "\(forward)")
            let closed = dag.transitiveClosure()
            #expect(Set(CompressedSparseRow.transitiveClosure(of: dag).edges.map { [$0.source, $0.target] }) == Set(closed.edges.map { [$0.source, $0.target] }), "\(forward)")
        }
    }
}
