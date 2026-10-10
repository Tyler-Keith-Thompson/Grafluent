// Properties against oracles written inside each test, with shrinking (swift-property-based): on
// a failure, PropertyBased shrinks the generated input and prints the smallest one that still
// fails. Graphs are multigraphs with self-loops on 1 … 8 vertices listed in an order shuffled by a
// seed (so vertex numbers are not vertex values), on `ReferencePseudograph` and, with parallel
// edges collapsed, on `UndirectedAdjacencyList`; bipartite graphs are `BipartiteGraph`s with both
// sides inserted in shuffled orders. The oracles: every matching enumerated (each edge in or out),
// for the greatest size, the greatest or least weight, and the full matchings; every injective
// assignment for `linearSumAssignment`; every matching over acceptable pairs for `stableMatching`;
// the definitions for the three checks; the greedy scan for `maximalMatching()`; and api.md's
// Hopcroft–Karp and Edmonds procedures, written out from its Semantics section over the graph's
// public rows, for their exact outputs. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import PropertyBased
import Testing

@Suite("Matching properties against oracles, with shrinking", .tags(.randomized))
struct MatchingPropertyTests {
    @Test("maximumMatching() has the size of a maximum matching found by brute force; maximalMatching() is the greedy scan in position order")
    func maximumAgainstBruteForce() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 14)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let context = "\(pairs) on \(listed)"
            // Brute force: the greatest size over every matching.
            var used = Set<Int>()
            var largest = 0
            func extend(_ k: Int, _ size: Int) {
                guard k < pairs.count else {
                    largest = max(largest, size)
                    return
                }
                extend(k + 1, size)
                let (a, b) = pairs[k]
                if a != b, !used.contains(a), !used.contains(b) {
                    used.insert(a)
                    used.insert(b)
                    extend(k + 1, size + 1)
                    used.remove(a)
                    used.remove(b)
                }
            }
            extend(0, 0)
            let maximum = graph.maximumMatching()
            let maximal = graph.maximalMatching()
            for (name, matching) in [("maximumMatching", maximum), ("maximalMatching", maximal)] {
                // Valid: ascending positions, no self-loop, no endpoint shared.
                #expect(matching.edges == matching.edges.sorted() && Set(matching.edges).count == matching.edges.count, "\(name): \(matching.edges) in \(context)")
                var ends: [Int] = []
                for e in matching.edges { ends += [pairs[e].0, pairs[e].1] }
                #expect(Set(ends).count == ends.count && matching.edges.allSatisfy { pairs[$0].0 != pairs[$0].1 }, "\(name): \(matching.edges) in \(context)")
                // Maximal: every edge other than a self-loop has a matched end.
                #expect(pairs.allSatisfy { $0.0 == $0.1 || ends.contains($0.0) || ends.contains($0.1) }, "\(name) not maximal: \(matching.edges) in \(context)")
                #expect(matching.weight == matching.edges.count)
                #expect(matching.isPerfect == (2 * matching.edges.count == n))
                // Mates: symmetric, the matched edge joins the two, and by index as by vertex.
                for (i, v) in listed.enumerated() {
                    if let m = matching.mate(of: v) {
                        #expect(matching.mate(of: m) == v)
                        let e = matching.matchedEdge(of: v)
                        #expect(e.map { Set([pairs[$0].0, pairs[$0].1]) } == Set([v, m]))
                        #expect(e.map { matching.edges.contains($0) } == true)
                        #expect(matching.mate(ofIndex: i) == listed.firstIndex(of: m))
                    } else {
                        #expect(matching.matchedEdge(of: v) == nil)
                        #expect(matching.mate(ofIndex: i) == nil)
                        #expect(!ends.contains(v))
                    }
                }
                #expect(graph.isMatching(matching.edges) && graph.isMaximalMatching(matching.edges), "\(name) in \(context)")
            }
            #expect(maximum.edges.count == largest, "maximum \(maximum.edges), brute force \(largest), in \(context)")
            #expect(2 * maximal.edges.count >= largest)
            #expect(graph.isPerfectMatching(maximum.edges) == (2 * largest == n))
            // maximalMatching(): each edge in position order joins when neither end is matched.
            var covered = Set<Int>()
            var greedy: [Int] = []
            for (k, (a, b)) in pairs.enumerated() where a != b && !covered.contains(a) && !covered.contains(b) {
                greedy.append(k)
                covered.insert(a)
                covered.insert(b)
            }
            #expect(maximal.edges == greedy, "\(context)")
            // The same graph with parallel edges collapsed, and the unit-weight maximum-cardinality matching.
            let simple = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            #expect(simple.maximumMatching().edges.count == largest, "\(context)")
            #expect(graph.maximumWeightMatching(weight: { (_: Int) -> Int in 1 }, maximumCardinality: true).edges.count == largest, "\(context)")
        }
    }

    @Test("maximumMatching() is api.md's Edmonds procedure, written out: roots in vertex order, breadth-first, union–find bases")
    func edmondsExact() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 22)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            // Index-space rows from the public protocol: (far end's index, position), in incidentEdges order.
            let rows: [[(w: Int, e: Int)]] = (0 ..< n).map { i in
                graph.incidentEdges(ofIndex: i).map { e in (graph.vertexIndex(of: graph.oppositeVertex(to: graph.vertex(atIndex: i), acrossEdgeAt: e)), e) }
            }
            var mate = [Int](repeating: -1, count: n)
            var mateEdge = [Int](repeating: -1, count: n)
            for r in 0 ..< n where mate[r] == -1 {
                var label = [Int](repeating: 0, count: n)   // 0 unlabeled, 1 even, 2 odd
                var link = [Int](repeating: -1, count: n)
                var linkEdge = [Int](repeating: -1, count: n)
                var base = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while base[x] != x {
                        base[x] = base[base[x]]
                        x = base[x]
                    }
                    return x
                }
                func lowestCommonBase(_ x0: Int, _ y0: Int) -> Int {
                    var marked = Set<Int>()
                    var (x, y) = (x0, y0)
                    while true {
                        if x != -1 {
                            x = find(x)
                            if marked.contains(x) { return x }
                            marked.insert(x)
                            x = mate[x] == -1 ? -1 : link[mate[x]]
                        }
                        swap(&x, &y)
                    }
                }
                var queue = [r]
                var head = 0
                label[r] = 1
                func contract(_ x0: Int, _ y0: Int, _ a: Int, _ e0: Int) {
                    var (x, y, e) = (x0, y0, e0)
                    while find(x) != a {
                        link[x] = y
                        linkEdge[x] = e
                        y = mate[x]
                        if label[y] == 2 {
                            label[y] = 1
                            queue.append(y)
                        }
                        if find(x) == x { base[x] = a }
                        if find(y) == y { base[y] = a }
                        e = linkEdge[y]
                        x = link[y]
                    }
                }
                var found = false
                while head < queue.count && !found {
                    let v = queue[head]
                    head += 1
                    for (w, e) in rows[v] {
                        if find(v) == find(w) || label[w] == 2 { continue }
                        if label[w] == 0 {
                            link[w] = v
                            linkEdge[w] = e
                            if mate[w] == -1 {
                                var t = w
                                while t != -1 {
                                    let p = link[t]
                                    let next = mate[p]
                                    mate[t] = p
                                    mate[p] = t
                                    mateEdge[t] = linkEdge[t]
                                    mateEdge[p] = linkEdge[t]
                                    t = next
                                }
                                found = true
                                break
                            }
                            label[w] = 2
                            label[mate[w]] = 1
                            queue.append(mate[w])
                        } else {
                            let a = lowestCommonBase(v, w)
                            contract(v, w, a, e)
                            contract(w, v, a, e)
                        }
                    }
                }
            }
            let expected = Set((0 ..< n).filter { mate[$0] != -1 }.map { mateEdge[$0] }).sorted()
            let matching = graph.maximumMatching()
            #expect(matching.edges == expected, "\(pairs) on \(listed)")
            for i in 0 ..< n { #expect(matching.mate(ofIndex: i) == (mate[i] == -1 ? nil : mate[i]), "index \(i) in \(pairs) on \(listed)") }
        }
    }

    @Test("Hopcroft–Karp: the size of maximumMatching() and of the unit-weight maximum-cardinality matching, with a König cover as large; api.md's procedure written out")
    func hopcroftKarp() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 18)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 7), Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, l, r, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let leftOrder = seed == 0 ? Array(0 ..< l) : Array(0 ..< l).shuffled(using: &rng)
            let rightOrder = seed == 0 ? Array(l ..< l + r) : Array(l ..< l + r).shuffled(using: &rng)
            let given = raw.map { (u: $0.0 % l, v: l + $0.1 % r) }
            guard let graph = BipartiteGraph(left: leftOrder, right: rightOrder, edges: given.map { UndirectedEdge($0.u, $0.v) }) else {
                Issue.record("not a bipartite graph: \(given)")
                return
            }
            let context = "\(given) with left \(leftOrder), right \(rightOrder)"
            let hk = graph.maximumBipartiteMatching()
            let edmonds = graph.maximumMatching()
            let unit = graph.maximumWeightMatching(weight: { (_: Int) -> Int in 1 }, maximumCardinality: true)
            #expect(hk.edges.count == edmonds.edges.count && hk.edges.count == unit.edges.count, "\(context)")
            #expect(graph.isMatching(hk.edges) && graph.isMaximalMatching(hk.edges))
            #expect(hk.weight == hk.edges.count)
            // König: an alternating search from the free left vertices; (L − Z) ∪ (R ∩ Z) covers every edge.
            let leftSide = Set(leftOrder)
            var reached = Set(leftOrder.filter { hk.mate(of: $0) == nil })
            var frontier = Array(reached)
            while let x = frontier.popLast() {
                if leftSide.contains(x) {
                    for y in graph.neighbors(of: x) where hk.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }
                } else if let y = hk.mate(of: x), reached.insert(y).inserted {
                    frontier.append(y)
                }
            }
            let cover = Set(graph.vertices.filter { leftSide.contains($0) != reached.contains($0) })
            #expect(cover.count == hk.edges.count, "\(context)")
            #expect(graph.edges.allSatisfy { cover.contains($0.u) || cover.contains($0.v) }, "\(context)")
            // api.md's procedure: layers by breadth-first search from the free left vertices (in
            // `left` order), stopping at the first layer that reaches a free right vertex; then a
            // depth-first search from each free left vertex in `left` order, rows in incidentEdges order.
            let inf = Int.max
            var pairLeft: [Int: Int] = [:]
            var pairRight: [Int: Int] = [:]
            var edgeOf: [Int: Int] = [:]
            var layer: [Int: Int] = [:]
            var freeLayer = inf
            func layered() -> Bool {
                var queue: [Int] = []
                for v in leftOrder {
                    layer[v] = pairLeft[v] == nil ? 0 : inf
                    if pairLeft[v] == nil { queue.append(v) }
                }
                freeLayer = inf
                var head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    guard layer[v]! < freeLayer else { continue }
                    for u in graph.neighbors(of: v) {
                        if let w = pairRight[u] {
                            if layer[w]! == inf {
                                layer[w] = layer[v]! + 1
                                queue.append(w)
                            }
                        } else if freeLayer == inf {
                            freeLayer = layer[v]! + 1
                        }
                    }
                }
                return freeLayer != inf
            }
            func search(_ v: Int) -> Bool {
                for e in graph.incidentEdges(of: v) {
                    let u = graph.oppositeVertex(to: v, acrossEdgeAt: e)
                    let next = pairRight[u].map { layer[$0]! } ?? freeLayer
                    if next == layer[v]! + 1, pairRight[u].map(search) ?? true {
                        pairRight[u] = v
                        pairLeft[v] = u
                        edgeOf[v] = e
                        return true
                    }
                }
                layer[v] = inf
                return false
            }
            while layered() {
                for v in leftOrder where pairLeft[v] == nil { _ = search(v) }
            }
            #expect(hk.edges == edgeOf.values.sorted(), "\(context)")
            for v in leftOrder { #expect(hk.mate(of: v) == pairLeft[v], "\(v) in \(context)") }
            // The same graph as a plain graph, through its canonical bipartition: the same size.
            let plain = UndirectedAdjacencyList(vertices: Array(graph.vertices), edges: Array(graph.edges))
            if let sides = plain.bipartition() {
                #expect(plain.maximumBipartiteMatching(bipartition: sides).edges.count == hk.edges.count, "\(context)")
            } else {
                Issue.record("a bipartite graph has no bipartition: \(context)")
            }
            // Each edge doubled, on ReferencePseudograph: parallel copies do not change the size.
            let doubled = ReferencePseudograph(vertices: Array(graph.vertices), edges: Array(graph.edges) + Array(graph.edges))
            if let sides = doubled.bipartition() {
                let m = doubled.maximumBipartiteMatching(bipartition: sides)
                #expect(m.edges.count == hk.edges.count && doubled.isMatching(m.edges), "\(context)")
            }
        }
    }

    @Test("maximumWeightMatching and minimumWeightMatching against brute force, Int and Double weights, on multigraphs with loops")
    func weightedAgainstBruteForce() async {
        let triples = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7), Gen.int(in: -4 ... 9)).array(of: 0 ... 13)
        await propertyCheck(count: 400, input: triples, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let weights = raw.map { $0.2 }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let context = "\(pairs) weights \(weights) on \(listed)"
            // Brute force: every matching's (size, weight).
            var used = Set<Int>()
            var outcomes: [(size: Int, weight: Int)] = []
            func extend(_ k: Int, _ size: Int, _ total: Int) {
                guard k < pairs.count else {
                    outcomes.append((size, total))
                    return
                }
                extend(k + 1, size, total)
                let (a, b) = pairs[k]
                if a != b, !used.contains(a), !used.contains(b) {
                    used.insert(a)
                    used.insert(b)
                    extend(k + 1, size + 1, total + weights[k])
                    used.remove(a)
                    used.remove(b)
                }
            }
            extend(0, 0, 0)
            let heaviest = outcomes.map(\.weight).max()!
            let largest = outcomes.map(\.size).max()!
            let heaviestLargest = outcomes.filter { $0.size == largest }.map(\.weight).max()!
            let lightestLargest = outcomes.filter { $0.size == largest }.map(\.weight).min()!
            func valid(_ es: [Int]) -> Bool {
                var ends: [Int] = []
                for e in es { ends += [pairs[e].0, pairs[e].1] }
                return es == es.sorted() && Set(es).count == es.count && es.allSatisfy { pairs[$0].0 != pairs[$0].1 } && Set(ends).count == ends.count
            }
            var loopWeighed = false
            func weightOf(_ e: Int) -> Int {
                if pairs[e].0 == pairs[e].1 { loopWeighed = true }
                return weights[e]
            }
            let free = graph.maximumWeightMatching(weight: weightOf)
            #expect(valid(free.edges) && free.weight == heaviest, "free: \(free.edges) weight \(free.weight), brute force \(heaviest), in \(context)")
            #expect(free.weight == free.edges.reduce(0) { $0 + weights[$1] })
            #expect(free.edges.allSatisfy { weights[$0] >= 0 }, "a negative edge taken without maximumCardinality: \(context)")
            let full = graph.maximumWeightMatching(weight: weightOf, maximumCardinality: true)
            #expect(valid(full.edges) && full.edges.count == largest && full.weight == heaviestLargest, "maximumCardinality: \(full.edges) weight \(full.weight), brute force (\(largest), \(heaviestLargest)), in \(context)")
            let least = graph.minimumWeightMatching(weight: weightOf)
            #expect(valid(least.edges) && least.edges.count == largest && least.weight == lightestLargest, "minimum: \(least.edges) weight \(least.weight), brute force (\(largest), \(lightestLargest)), in \(context)")
            #expect(!loopWeighed, "a self-loop was weighed: \(context)")
            // The same weights halved, as Double (the FloatingPoint overload): the same optima, halved.
            let halves = weights.map { Double($0) / 2 }
            let freeDouble = graph.maximumWeightMatching(weight: { halves[$0] })
            #expect(freeDouble.weight == Double(heaviest) / 2, "Double: \(freeDouble.edges) weight \(freeDouble.weight) in \(context)")
            let fullDouble = graph.maximumWeightMatching(weight: { halves[$0] }, maximumCardinality: true)
            #expect(fullDouble.edges.count == largest && fullDouble.weight == Double(heaviestLargest) / 2, "\(context)")
            let leastDouble = graph.minimumWeightMatching(weight: { halves[$0] })
            #expect(leastDouble.edges.count == largest && leastDouble.weight == Double(lightestLargest) / 2, "\(context)")
            #expect(valid(freeDouble.edges) && valid(fullDouble.edges) && valid(leastDouble.edges))
            // Int32 weights (another SignedInteger): the same result as Int.
            let narrow = graph.maximumWeightMatching(weight: { Int32(weights[$0]) })
            #expect(narrow.edges == free.edges && Int(narrow.weight) == free.weight, "\(context)")
        }
    }

    @Test("linearSumAssignment against brute force over every assignment, with forbidden pairs, maximize and transposition")
    func assignmentAgainstBruteForce() async {
        await propertyCheck(count: 500, input: Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1_000_000)) { rowCount, columnCount, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // Tie-heavy entries in -3 ... 3, a fifth of them forbidden.
            let matrix: [[Int?]] = (0 ..< rowCount).map { _ in
                (0 ..< columnCount).map { _ in Int.random(in: 0 ..< 5, using: &rng) == 0 ? nil : Int.random(in: -3 ... 3, using: &rng) }
            }
            let maximize = Bool.random(using: &rng)
            let context = "\(matrix), maximize \(maximize)"
            // Brute force: every injective map of the shorter dimension into the longer one.
            let (shorter, longer) = (min(rowCount, columnCount), max(rowCount, columnCount))
            func entry(_ a: Int, _ b: Int) -> Int? { rowCount <= columnCount ? matrix[a][b] : matrix[b][a] }
            var taken = [Bool](repeating: false, count: longer)
            var best: Int?
            func place(_ a: Int, _ total: Int) {
                guard a < shorter else {
                    if best == nil || (maximize ? total > best! : total < best!) { best = total }
                    return
                }
                for b in 0 ..< longer where !taken[b] {
                    guard let c = entry(a, b) else { continue }
                    taken[b] = true
                    place(a + 1, total + c)
                    taken[b] = false
                }
            }
            place(0, 0)
            let result = linearSumAssignment(rowCount: rowCount, columnCount: columnCount, maximize: maximize) { matrix[$0][$1] }
            guard let best else {
                #expect(result == nil, "\(context)")
                return
            }
            guard let result else {
                Issue.record("nil, but brute force found \(best): \(context)")
                return
            }
            #expect(result.cost == best, "\(result) against brute force \(best): \(context)")
            #expect(result.rows.count == shorter && result.columns.count == shorter)
            #expect(result.rows == result.rows.sorted() && Set(result.rows).count == shorter && Set(result.columns).count == shorter)
            var sum = 0
            for (i, j) in zip(result.rows, result.columns) {
                guard let c = matrix[i][j] else {
                    Issue.record("forbidden pair (\(i), \(j)): \(context)")
                    continue
                }
                sum += c
            }
            #expect(sum == result.cost)
            // The transposed matrix has an assignment of the same cost.
            let transposed = linearSumAssignment(rowCount: columnCount, columnCount: rowCount, maximize: maximize) { matrix[$1][$0] }
            #expect(transposed?.cost == best, "transposed: \(context)")
            // The same matrix as Double: the same cost.
            let doubles = linearSumAssignment(rowCount: rowCount, columnCount: columnCount, maximize: maximize) { matrix[$0][$1].map(Double.init) }
            #expect(doubles?.cost == Double(best), "Double: \(context)")
        }
    }

    @Test("minimumWeightFullMatching against brute force over every matching, and equal to linearSumAssignment on the biadjacency matrix")
    func fullMatchingAgainstBruteForce() async {
        let triples = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: -3 ... 6)).array(of: 0 ... 16)
        await propertyCheck(count: 400, input: triples, Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 1_000_000)) { raw, l, r, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let leftOrder = seed == 0 ? Array(0 ..< l) : Array(0 ..< l).shuffled(using: &rng)
            let rightOrder = seed == 0 ? Array(l ..< l + r) : Array(l ..< l + r).shuffled(using: &rng)
            // Repeats of a pair are dropped by BipartiteGraph; the first one's weight is kept.
            var seen = Set<[Int]>()
            var given: [(u: Int, v: Int, w: Int)] = []
            if l > 0 && r > 0 {
                for t in raw where seen.insert([t.0 % l, l + t.1 % r]).inserted { given.append((t.0 % l, l + t.1 % r, t.2)) }
            }
            guard let graph = BipartiteGraph(left: leftOrder, right: rightOrder, edges: given.map { UndirectedEdge($0.u, $0.v) }) else {
                Issue.record("not a bipartite graph: \(given)")
                return
            }
            let weights = given.map(\.w)
            let context = "\(given) with left \(leftOrder), right \(rightOrder)"
            let k = min(l, r)
            // Brute force: the least weight among matchings of size k.
            var used = Set<Int>()
            var least: Int?
            func extend(_ e: Int, _ size: Int, _ total: Int) {
                guard e < given.count else {
                    if size == k && (least == nil || total < least!) { least = total }
                    return
                }
                extend(e + 1, size, total)
                if !used.contains(given[e].u), !used.contains(given[e].v) {
                    used.insert(given[e].u)
                    used.insert(given[e].v)
                    extend(e + 1, size + 1, total + weights[e])
                    used.remove(given[e].u)
                    used.remove(given[e].v)
                }
            }
            extend(0, 0, 0)
            var calls = 0
            let result = graph.minimumWeightFullMatching(weight: { (e: Int) -> Int in
                calls += 1
                return weights[e]
            })
            // api.md: `weight` is called once per edge.
            #expect(calls == given.count || (k == 0 && calls <= given.count), "weight called \(calls) times for \(given.count) edges")
            // linearSumAssignment on the biadjacency matrix: rows `left`, columns `right`.
            let matrix: [[Int?]] = leftOrder.map { a in rightOrder.map { b in given.firstIndex { $0.u == a && $0.v == b }.map { weights[$0] } } }
            let assignment = linearSumAssignment(rowCount: l, columnCount: r) { matrix[$0][$1] }
            guard let least else {
                #expect(result == nil, "\(context)")
                #expect(assignment == nil || k == 0)
                return
            }
            guard let result else {
                Issue.record("nil, but brute force found \(least): \(context)")
                return
            }
            #expect(result.edges.count == k && result.weight == least, "\(result.edges) weight \(result.weight), brute force \(least): \(context)")
            #expect(graph.isMatching(result.edges))
            if let assignment {
                let positions = zip(assignment.rows, assignment.columns).map { i, j in given.firstIndex { $0.u == leftOrder[i] && $0.v == rightOrder[j] }! }
                #expect(result.edges == positions.sorted(), "the assignment's edges: \(context)")
                #expect(assignment.cost == result.weight)
            } else {
                Issue.record("linearSumAssignment found nothing: \(context)")
            }
            // The same graph on UndirectedAdjacencyList through bipartition(): with no isolated right
            // vertex the canonical sides are `left` and `right` in the same orders, so the same edges.
            let plain = UndirectedAdjacencyList(vertices: Array(graph.vertices), edges: Array(graph.edges))
            if rightOrder.allSatisfy({ graph.degree(of: $0) > 0 }), let sides = plain.bipartition() {
                #expect(Array(sides.left) == leftOrder && Array(sides.right) == rightOrder)
                let other = plain.minimumWeightFullMatching(bipartition: sides, weight: { weights[$0] })
                #expect(other?.edges == result.edges && other?.weight == least, "through bipartition(): \(context)")
            }
        }
    }

    @Test("stableMatching is stable, proposer-optimal and matches the agents every stable matching matches, by brute force; swapped, reviewer-optimal")
    func stableAgainstBruteForce() async {
        await propertyCheck(count: 500, input: Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 1_000_000)) { P, R, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // Each list a random subset in random order; acceptability needs both lists.
            let proposers: [[Int]] = (0 ..< P).map { _ in Array((0 ..< R).shuffled(using: &rng).prefix(Int.random(in: 0 ... R, using: &rng))) }
            let reviewers: [[Int]] = (0 ..< R).map { _ in Array((0 ..< P).shuffled(using: &rng).prefix(Int.random(in: 0 ... P, using: &rng))) }
            let context = "proposers \(proposers), reviewers \(reviewers)"
            func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }
            func isStable(_ m: [Int?]) -> Bool {
                var held = [Int?](repeating: nil, count: R)
                for (p, r) in m.enumerated() { if let r { held[r] = p } }
                for p in 0 ..< P {
                    for r in proposers[p] where acceptable(p, r) && m[p] != r {
                        let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!
                        let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!
                        if proposerPrefers && reviewerPrefers { return false }
                    }
                }
                return true
            }
            var stable: [[Int?]] = []
            var current: [Int?] = []
            var taken = Set<Int>()
            func choose(_ p: Int) {
                guard p < P else {
                    if isStable(current) { stable.append(current) }
                    return
                }
                current.append(nil)
                choose(p + 1)
                current.removeLast()
                for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {
                    taken.insert(r)
                    current.append(r)
                    choose(p + 1)
                    current.removeLast()
                    taken.remove(r)
                }
            }
            choose(0)
            let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)
            let found = (0 ..< P).map { result.mate(ofProposer: $0) }
            #expect(isStable(found), "not stable: \(found) for \(context)")
            #expect(stable.contains { $0 == found }, "\(found) for \(context)")
            for p in 0 ..< P { if let r = found[p] { #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p, "\(context)") } }
            for r in 0 ..< R { if let p = result.mate(ofReviewer: r) { #expect(found[p] == r, "\(context)") } }
            // Swapping the roles gives the reviewer-optimal stable matching of the same instance.
            let swapped = stableMatching(proposerPreferences: reviewers, reviewerPreferences: proposers)
            let reviewerOptimal = (0 ..< P).map { swapped.mate(ofReviewer: $0) }
            #expect(isStable(reviewerOptimal), "swapped: \(reviewerOptimal) for \(context)")
            for other in stable {
                for p in 0 ..< P {
                    if let r = other[p] {
                        #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, "proposer \(p) does better in \(other): \(context)")
                    }
                }
                var heldByOther = [Int?](repeating: nil, count: R)
                for (p, r) in other.enumerated() { if let r { heldByOther[r] = p } }
                for r in 0 ..< R {
                    if let p = heldByOther[r] {
                        let mine = swapped.mate(ofProposer: r)
                        #expect(mine != nil && reviewers[r].firstIndex(of: mine!)! <= reviewers[r].firstIndex(of: p)!, "reviewer \(r) does better in \(other): \(context)")
                    }
                }
                // Rural hospitals: the same agents matched in every stable matching.
                #expect(other.map { $0 != nil } == found.map { $0 != nil }, "\(context)")
                #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }), "\(context)")
            }
        }
    }

    @Test("isMatching, isMaximalMatching and isPerfectMatching against their definitions, on random position lists with repeats")
    func checksAgainstDefinitions() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 12)
        let picks = Gen.int(in: 0 ... 20).array(of: 0 ... 6)
        await propertyCheck(count: 500, input: edges, picks, Gen.int(in: 1 ... 7), Gen.int(in: 0 ... 1_000_000)) { raw, rawPicks, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            guard !pairs.isEmpty else { return }
            let candidate = rawPicks.map { $0 % pairs.count }
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            var ends: [Int] = []
            for e in candidate { ends += [pairs[e].0, pairs[e].1] }
            let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { pairs[$0].0 != pairs[$0].1 } && Set(ends).count == ends.count
            let isMaximal = isMatching && pairs.allSatisfy { $0.0 == $0.1 || ends.contains($0.0) || ends.contains($0.1) }
            let isPerfect = isMatching && ends.count == n
            let context = "\(candidate) in \(pairs) on \(listed)"
            #expect(graph.isMatching(candidate) == isMatching, "\(context)")
            #expect(graph.isMaximalMatching(candidate) == isMaximal, "\(context)")
            #expect(graph.isPerfectMatching(candidate) == isPerfect, "\(context)")
            #expect(graph.isMatching(candidate.shuffled(using: &rng)) == isMatching, "\(context)")
        }
    }
}
