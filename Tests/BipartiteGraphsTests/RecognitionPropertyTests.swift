// Recognition properties against oracles written inside each test, with shrinking
// (swift-property-based): on a failure, PropertyBased shrinks the generated input and prints the
// smallest one that still fails. Graphs are multigraphs with self-loops on 1 … 7 vertices, listed
// in an order shuffled by a seed (so vertex numbers are not vertex values), on
// `ReferencePseudograph` and, with parallel edges collapsed, on `UndirectedAdjacencyList`. The
// oracles: every two-colouring of the vertices (at most 2⁷) for bipartiteness and, with union–find
// components, for the canonical sides (each component's least-numbered vertex left); edge-by-edge
// checks for `BipartiteGraph(g, left:)`; and api.md's breadth-first search, written out from its
// Semantics section over the graph's public rows, for the exact odd cycle. api.md's equivalences
// (`isBipartite ⇔ bipartition() != nil ⇔ findOddCycle() == nil ⇔ BipartiteGraph(g) != nil`) are
// checked on every input. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Walks

@Suite("Recognition properties against oracles, with shrinking", .tags(.randomized))
struct RecognitionPropertyTests {
    @Test("isBipartite, bipartition(), findOddCycle() and BipartiteGraph(g) agree with brute force over every two-colouring")
    func againstBruteForce() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 10)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let simple = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // Union–find components; each one's least-numbered vertex is the first of it in `listed`.
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (a, b) in pairs {
                let (ra, rb) = (find(a), find(b))
                if ra != rb { parent[ra] = rb }
            }
            var leastOfComponent: [Int: Int] = [:]
            for v in listed where leastOfComponent[find(v)] == nil { leastOfComponent[find(v)] = v }
            // Every two-colouring by vertex value; colour 0 is left.
            var bipartite = false
            var canonical: [Int]?
            for mask in 0 ..< (1 << n) {
                let colour = (0 ..< n).map { (mask >> $0) & 1 }
                guard pairs.allSatisfy({ colour[$0.0] != colour[$0.1] }) else { continue }
                bipartite = true
                if leastOfComponent.values.allSatisfy({ colour[$0] == 0 }) { canonical = colour }
            }
            let context = "\(pairs) on \(listed)"
            #expect(graph.isBipartite == bipartite, "\(context)")
            #expect((graph.bipartition() != nil) == bipartite, "\(context)")
            #expect((graph.findOddCycle() == nil) == bipartite, "\(context)")
            #expect((BipartiteGraph(graph) != nil) == bipartite, "\(context)")
            #expect(simple.isBipartite == bipartite, "\(context)")
            #expect((simple.findOddCycle() == nil) == bipartite, "\(context)")

            // BipartiteGraph(g, left:) for a random subset, and with a non-vertex added.
            let subsetMask = Int.random(in: 0 ..< (1 << n), using: &rng)
            let subset = listed.filter { (subsetMask >> $0) & 1 == 1 }
            let crosses = pairs.allSatisfy { ((subsetMask >> $0.0) & 1) != ((subsetMask >> $0.1) & 1) }
            #expect((BipartiteGraph(graph, left: subset) != nil) == crosses, "left \(subset) in \(context)")
            #expect(BipartiteGraph(graph, left: subset + [n]) == nil)

            if bipartite {
                guard let canonical, let bipartition = graph.bipartition(), let simpleSides = simple.bipartition() else {
                    Issue.record("no canonical colouring or no bipartition: \(context)")
                    return
                }
                let left = listed.filter { canonical[$0] == 0 }
                let right = listed.filter { canonical[$0] == 1 }
                #expect(Array(bipartition.left) == left, "\(context)")
                #expect(Array(bipartition.right) == right, "\(context)")
                #expect(Array(simpleSides.left) == left, "\(context)")
                #expect(Array(simpleSides.right) == right, "\(context)")
                for (i, v) in listed.enumerated() {
                    #expect(bipartition.side(of: v) == (canonical[v] == 0 ? .left : .right))
                    #expect(bipartition.side(ofIndex: i) == bipartition.side(of: v))
                    #expect(simpleSides.side(of: v) == bipartition.side(of: v))
                }
                // BipartiteGraph(g): the vertex order, the first copy of each edge in position order,
                // stored left endpoint first, the canonical sides.
                guard let copy = BipartiteGraph(graph) else { return }
                var seen: Set<UndirectedEdge<Int>> = []
                var expectedEdges: [[Int]] = []
                for (a, b) in pairs where seen.insert(UndirectedEdge(a, b)).inserted {
                    expectedEdges.append(canonical[a] == 0 ? [a, b] : [b, a])
                }
                #expect(Array(copy.vertices) == listed)
                #expect(Array(copy.left) == left)
                #expect(Array(copy.right) == right)
                #expect(copy.edges.map { [$0.u, $0.v] } == expectedEdges, "\(context)")
                #expect(BipartiteGraph(simple) == copy)
                // The canonical left side, and the swapped one, are both accepted by left:.
                #expect(BipartiteGraph(graph, left: left) == copy)
                let swapped = BipartiteGraph(graph, left: right)
                #expect(swapped.map { Set($0.left) } == Set(right))
                #expect(swapped.map { Set($0.right) } == Set(left))
            } else {
                for (name, found, edgeList) in [("pseudograph", graph.findOddCycle(), graph.edges), ("adjacency list", simple.findOddCycle(), Array(simple.edges))] {
                    guard let cycle = found else {
                        Issue.record("no odd cycle on the \(name): \(context)")
                        continue
                    }
                    let k = cycle.vertices.count
                    #expect(k % 2 == 1, "\(name): \(cycle.vertices) in \(context)")
                    #expect(Set(cycle.vertices).count == k)
                    #expect(Set(cycle.edges).count == k)
                    for i in 0 ..< k {
                        let edge = edgeList[cycle.edges[i]]
                        #expect(Set([edge.u, edge.v]) == Set([cycle.vertices[i], cycle.vertices[(i + 1) % k]]), "\(name): \(cycle.vertices) via \(cycle.edges) in \(context)")
                    }
                    // Cycles' canonical form: the least-numbered vertex first, left through the lesser edge.
                    let numbers = cycle.vertices.map { listed.firstIndex(of: $0)! }
                    #expect(numbers[0] == numbers.min(), "\(name): \(cycle.vertices) in \(context)")
                    if k > 1 { #expect(cycle.edges[0] < cycle.edges[k - 1], "\(name): \(cycle.edges) in \(context)") }
                }
                if let cycle = graph.findOddCycle() { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil) }
                if let cycle = simple.findOddCycle() { #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: simple) != nil) }
            }
        }
    }

    @Test("findOddCycle() is the first conflict of api.md's breadth-first search, closed through the lowest common ancestor, in canonical form")
    func exactCycle() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 14)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let simple = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // api.md, Semantics: roots in vertex-number order, rows in incidentEdges order, the first
            // row entry whose far end is on the near end's side is the conflict; the cycle runs from
            // the lowest common ancestor down to v, across the edge, and up from w; then it is
            // rotated to its least vertex number and turned to leave through the lesser edge.
            func oracle(_ rows: [[(Int, Int)]]) -> (vertices: [Int], edges: [Int])? {
                let count = rows.count
                var side = [Int](repeating: -1, count: count)
                var parent = [(Int, Int)](repeating: (-1, -1), count: count)
                var depth = [Int](repeating: 0, count: count)
                for root in 0 ..< count where side[root] == -1 {
                    side[root] = 0
                    var queue = [root]
                    var head = 0
                    while head < queue.count {
                        let v = queue[head]
                        head += 1
                        for (w, e) in rows[v] {
                            if side[w] == -1 {
                                side[w] = 1 - side[v]
                                parent[w] = (v, e)
                                depth[w] = depth[v] + 1
                                queue.append(w)
                            } else if side[w] == side[v] {
                                if w == v { return ([v], [e]) }
                                var (a, b) = (v, w)
                                var upA: [(Int, Int)] = [], upB: [(Int, Int)] = []
                                while depth[a] > depth[b] { upA.append((a, parent[a].1)); a = parent[a].0 }
                                while depth[b] > depth[a] { upB.append((b, parent[b].1)); b = parent[b].0 }
                                while a != b {
                                    upA.append((a, parent[a].1)); a = parent[a].0
                                    upB.append((b, parent[b].1)); b = parent[b].0
                                }
                                let down = Array(upA.reversed())
                                var vs = [a] + down.map(\.0) + upB.map(\.0)
                                var es = down.map(\.1) + [e] + upB.map(\.1)
                                let start = vs.firstIndex(of: vs.min()!)!
                                vs = Array(vs[start...] + vs[..<start])
                                es = Array(es[start...] + es[..<start])
                                if es.count > 1 && es[es.count - 1] < es[0] {
                                    vs = [vs[0]] + vs[1...].reversed()
                                    es = es.reversed()
                                }
                                return (vs, es)
                            }
                        }
                    }
                }
                return nil
            }
            let pseudoRows = (0 ..< graph.vertexCount).map { i in Array(zip(graph.neighborIndices(ofIndex: i), graph.incidentEdges(ofIndex: i))) }
            let simpleRows = (0 ..< simple.vertexCount).map { i in Array(zip(simple.neighborIndices(ofIndex: i), simple.incidentEdges(ofIndex: i))) }
            let expected = oracle(pseudoRows)
            let found = graph.findOddCycle()
            #expect(found?.vertices == expected.map { $0.vertices.map { listed[$0] } }, "\(pairs) on \(listed)")
            #expect(found?.edges == expected?.edges, "\(pairs) on \(listed)")
            let expectedSimple = oracle(simpleRows)
            let foundSimple = simple.findOddCycle()
            #expect(foundSimple?.vertices == expectedSimple.map { $0.vertices.map { simple.vertex(atIndex: $0) } }, "\(pairs) on \(listed)")
            #expect(foundSimple?.edges == expectedSimple?.edges, "\(pairs) on \(listed)")
        }
    }
}
