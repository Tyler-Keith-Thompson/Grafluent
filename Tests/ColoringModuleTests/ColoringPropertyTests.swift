// Properties against oracles written inside each test, with shrinking (swift-property-based): on
// a failure, PropertyBased shrinks the generated input and prints the smallest one that still
// fails. Graphs are multigraphs with self-loops on 1 … 10 vertices listed in an order shuffled by a
// seed (so vertex indices are not vertex values), on `ReferencePseudograph` and, with parallel edges
// collapsed, on `UndirectedAdjacencyList`; simple graphs for Misra–Gries; bipartite multigraphs
// with their sides interleaved in the vertex order, and `BipartiteGraph`s. The oracles: the
// definitions of a colouring and an edge colouring; api.md's procedures written out (first fit, the
// six strategies' orders, Welsh–Powell's class-by-class form, Misra–Gries, König's path flips);
// exhaustive searches for χ, for ω and for each component's lexicographically least χ-colouring;
// and `bipartition()`. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("Coloring properties against oracles, with shrinking", .tags(.randomized))
struct ColoringPropertyTests {
    @Test("Every strategy: proper, every colour used, at most Δ + 1 colours, first fit, at least χ; parallel edges and self-loops change nothing")
    func everyStrategy() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            let context = "\(pairs) on \(listed)"
            var adjacent = [[Int]](repeating: [], count: n)
            for (a, b) in ends where a != b {
                if !adjacent[a].contains(b) { adjacent[a].append(b) }
                if !adjacent[b].contains(a) { adjacent[b].append(a) }
            }
            let maxDegree = adjacent.map(\.count).max() ?? 0
            let chi = graph.chromaticNumber()
            // The same graph with parallel edges collapsed (UndirectedAdjacencyList keeps the first
            // copy, so rows keep their first-appearance order) and with self-loops dropped too.
            let collapsed = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let loopless = UndirectedAdjacencyList(vertices: listed, edges: pairs.filter { $0.0 != $0.1 }.map { UndirectedEdge($0.0, $0.1) })
            for strategy in ColoringStrategy.allCases {
                let coloring = graph.greedyColoring(strategy: strategy)
                let colors = listed.map { coloring.color(of: $0) }
                let byIndex = (0 ..< n).map { coloring.color(ofIndex: $0) }
                #expect(byIndex == colors, "\(strategy) \(context)")
                for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(strategy) \(context)") }
                let checked = graph.isColoring { coloring.color(of: $0) }
                #expect(checked, "\(strategy) \(context)")
                #expect(Set(colors) == Set(0 ..< coloring.colorCount), "\(strategy) \(context)")
                let classes = coloring.colorClasses.map { Array($0) }
                let expectedClasses = (0 ..< coloring.colorCount).map { c in listed.indices.filter { colors[$0] == c }.map { listed[$0] } }
                #expect(classes == expectedClasses, "\(strategy) \(context)")
                #expect(coloring.colorCount <= maxDegree + 1, "\(strategy) \(context)")
                #expect(coloring.colorCount >= chi, "\(strategy) \(context)")
                // First fit: a vertex of colour c sees every colour below c.
                let firstFit = (0 ..< n).allSatisfy { v in Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]) }
                #expect(firstFit, "\(strategy) \(context)")
                let onCollapsed = collapsed.greedyColoring(strategy: strategy)
                let onLoopless = loopless.greedyColoring(strategy: strategy)
                let collapsedColors = listed.map { onCollapsed.color(of: $0) }, looplessColors = listed.map { onLoopless.color(of: $0) }
                #expect(collapsedColors == colors, "\(strategy) \(context)")
                #expect(looplessColors == colors, "\(strategy) \(context)")
            }
            #expect(collapsed.chromaticNumber() == chi && loopless.chromaticNumber() == chi, "\(context)")
            let minimum = graph.minimumColoring()
            let collapsedMinimum = collapsed.minimumColoring(), looplessMinimum = loopless.minimumColoring()
            let minimumColors = listed.map { minimum.color(of: $0) }
            let collapsedMinimumColors = listed.map { collapsedMinimum.color(of: $0) }, looplessMinimumColors = listed.map { looplessMinimum.color(of: $0) }
            #expect(collapsedMinimumColors == minimumColors, "\(context)")
            #expect(looplessMinimumColors == minimumColors, "\(context)")
            // bipartiteEdgeColoring() is nil exactly when there is an odd cycle (a self-loop is one).
            #expect((graph.bipartiteEdgeColoring() == nil) == (graph.bipartition() == nil), "\(context)")
        }
    }

    @Test("Each strategy equals api.md's procedure written out (largest first also as Welsh–Powell's class by class); smallest last within degeneracy + 1")
    func strategiesWrittenOut() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 26)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            let context = "\(pairs) on \(listed)"
            // The simple graph: distinct other neighbours in first-appearance order along each row.
            var adjacent = [[Int]](repeating: [], count: n)
            for (a, b) in ends where a != b {
                if !adjacent[a].contains(b) { adjacent[a].append(b) }
                if !adjacent[b].contains(a) { adjacent[b].append(a) }
            }
            func firstFit(_ order: [Int]) -> [Int] {
                var colour = [Int](repeating: -1, count: n)
                for v in order {
                    var c = 0
                    while adjacent[v].contains(where: { colour[$0] == c }) { c += 1 }
                    colour[v] = c
                }
                return colour
            }
            func colors(_ strategy: ColoringStrategy) -> [Int] {
                let coloring = graph.greedyColoring(strategy: strategy)
                return listed.map { coloring.color(of: $0) }
            }

            // Largest first: degree descending, the lesser index on ties.
            let largestFirst = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
            #expect(colors(.largestFirst) == firstFit(largestFirst), "\(context)")
            // Welsh–Powell: colour c to every vertex, in that order, with no neighbour holding c yet.
            var welshPowell = [Int](repeating: -1, count: n)
            var c = 0
            while welshPowell.contains(-1) {
                for v in largestFirst where welshPowell[v] < 0 && !adjacent[v].contains(where: { welshPowell[$0] == c }) { welshPowell[v] = c }
                c += 1
            }
            #expect(colors(.largestFirst) == welshPowell, "\(context)")

            // Smallest last: remove a least-degree vertex (the lesser index on ties), colour in reverse.
            var degree = adjacent.map(\.count)
            var removed = [Bool](repeating: false, count: n)
            var removal: [Int] = []
            var degeneracy = 0
            for _ in 0 ..< n {
                let v = (0 ..< n).filter { !removed[$0] }.min { (degree[$0], $0) < (degree[$1], $1) }!
                degeneracy = max(degeneracy, degree[v])
                removed[v] = true
                removal.append(v)
                for w in adjacent[v] where !removed[w] { degree[w] -= 1 }
            }
            #expect(colors(.smallestLast) == firstFit(removal.reversed()), "\(context)")
            #expect(graph.greedyColoring(strategy: .smallestLast).colorCount <= degeneracy + 1, "\(context)")

            // DSatur: most distinct neighbour colours, then greatest degree, then the lesser index.
            var dsatur = [Int](repeating: -1, count: n)
            for _ in 0 ..< n {
                let key = { (v: Int) in (Set(adjacent[v].map { dsatur[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
                let v = (0 ..< n).filter { dsatur[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
                var c = 0
                while adjacent[v].contains(where: { dsatur[$0] == c }) { c += 1 }
                dsatur[v] = c
            }
            #expect(colors(.saturationLargestFirst) == dsatur, "\(context)")

            // Independent set: class k from the uncoloured vertices, fewest available neighbours first.
            var independent = [Int](repeating: -1, count: n)
            var k = 0
            while independent.contains(-1) {
                var available = Set((0 ..< n).filter { independent[$0] < 0 })
                while true {
                    let left = available
                    guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                    independent[v] = k
                    available.remove(v)
                    for w in adjacent[v] { available.remove(w) }
                }
                k += 1
            }
            #expect(colors(.independentSet) == independent, "\(context)")

            // Connected sequential: components by least vertex, each from its least vertex, rows in order.
            var seen = [Bool](repeating: false, count: n)
            var breadthFirst: [Int] = []
            for root in 0 ..< n where !seen[root] {
                seen[root] = true
                var queue = [root]
                var head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    breadthFirst.append(v)
                    for w in adjacent[v] where !seen[w] {
                        seen[w] = true
                        queue.append(w)
                    }
                }
            }
            #expect(colors(.connectedSequentialBreadthFirst) == firstFit(breadthFirst), "\(context)")
            seen = [Bool](repeating: false, count: n)
            var depthFirst: [Int] = []
            for root in 0 ..< n where !seen[root] {
                seen[root] = true
                depthFirst.append(root)
                var stack = [(root, 0)]
                while let (v, i) = stack.last {
                    if i == adjacent[v].count {
                        stack.removeLast()
                        continue
                    }
                    stack[stack.count - 1].1 += 1
                    let w = adjacent[v][i]
                    if !seen[w] {
                        seen[w] = true
                        depthFirst.append(w)
                        stack.append((w, 0))
                    }
                }
            }
            #expect(colors(.connectedSequentialDepthFirst) == firstFit(depthFirst), "\(context)")
            // The strategies are orders: greedyColoring(order:) in each one's order gives its colouring.
            for (strategy, order) in [(ColoringStrategy.largestFirst, largestFirst), (.smallestLast, Array(removal.reversed())), (.connectedSequentialBreadthFirst, breadthFirst), (.connectedSequentialDepthFirst, depthFirst)] {
                let inOrder = graph.greedyColoring(order: order.map { listed[$0] })
                #expect(inOrder == graph.greedyColoring(strategy: strategy), "\(strategy) \(context)")
            }
        }
    }

    @Test("greedyColoring(order:) in a shuffled order is first fit in that order")
    func shuffledOrder() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let order = listed.shuffled(using: &rng)
            var expected = [Int](repeating: -1, count: n)
            for x in order {
                let v = index[x]!
                let seen = Set(pairs.filter { $0.0 != $0.1 && ($0.0 == x || $0.1 == x) }.map { expected[index[$0.0 == x ? $0.1 : $0.0]!] })
                var c = 0
                while seen.contains(c) { c += 1 }
                expected[v] = c
            }
            let coloring = graph.greedyColoring(order: order)
            let colors = listed.map { coloring.color(of: $0) }
            #expect(colors == expected, "\(pairs) on \(listed) in \(order)")
        }
    }

    @Test("chromaticNumber() is the least k with a proper k-colouring (exhaustive search); ω ≤ χ ≤ every greedy count; minimumColoring() has χ colours")
    func chromaticNumber() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 30)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let context = "\(pairs) on \(listed)"
            var adjacent = [[Int]](repeating: [], count: n)
            for (x, y) in pairs where x != y {
                let (a, b) = (index[x]!, index[y]!)
                if !adjacent[a].contains(b) { adjacent[a].append(b) }
                if !adjacent[b].contains(a) { adjacent[b].append(a) }
            }
            func colorable(_ k: Int) -> Bool {
                var colour = [Int](repeating: -1, count: n)
                func place(_ v: Int, _ used: Int) -> Bool {
                    if v == n { return true }
                    for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                        colour[v] = c
                        if place(v + 1, max(used, c + 1)) { return true }
                    }
                    colour[v] = -1
                    return false
                }
                return place(0, 0)
            }
            let chi = graph.chromaticNumber()
            #expect(chi == (0 ... n).first(where: colorable), "\(context)")
            // ω by every subset.
            let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
            var omega = 0
            for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
                omega = max(omega, mask.nonzeroBitCount)
            }
            #expect(chi >= omega, "\(context)")
            for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy) \(context)") }
            let minimum = graph.minimumColoring()
            #expect(minimum.colorCount == chi, "\(context)")
            let checked = graph.isColoring { minimum.color(of: $0) }
            #expect(checked, "\(context)")
            // 0 only for the empty graph, 1 without edges between distinct vertices, 2 when bipartite with one.
            let hasEdge = adjacent.contains { !$0.isEmpty }
            let looped = pairs.contains { $0.0 == $0.1 }
            if !hasEdge { #expect(chi == 1, "\(context)") }
            if hasEdge && !looped { #expect((chi == 2) == (graph.bipartition() != nil), "\(context)") }
        }
    }

    @Test("minimumColoring(): per component the lexicographically least χ-colouring (exhaustive search), the component's own minimumColoring(), classes numbered by least vertex")
    func minimumColoringRule() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 22)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let context = "\(pairs) on \(listed)"
            var adjacent = [[Int]](repeating: [], count: n)
            for (x, y) in pairs where x != y {
                let (a, b) = (index[x]!, index[y]!)
                if !adjacent[a].contains(b) { adjacent[a].append(b) }
                if !adjacent[b].contains(a) { adjacent[b].append(a) }
            }
            let coloring = graph.minimumColoring()
            let colors = listed.map { coloring.color(of: $0) }
            // Components as vertex indices ascending.
            var componentOf = [Int](repeating: -1, count: n)
            var components: [[Int]] = []
            for root in 0 ..< n where componentOf[root] < 0 {
                componentOf[root] = components.count
                var members = [root]
                var head = 0
                while head < members.count {
                    let v = members[head]
                    head += 1
                    for w in adjacent[v] where componentOf[w] < 0 {
                        componentOf[w] = components.count
                        members.append(w)
                    }
                }
                components.append(members.sorted())
            }
            for members in components {
                // The first k with a proper colour vector of at most k colours, searched in index order
                // with each vertex at most one above the colours used: χ of the component and its
                // lexicographically least χ-colouring.
                var colour = [Int](repeating: -1, count: n)
                func place(_ i: Int, _ used: Int, _ k: Int) -> Bool {
                    if i == members.count { return true }
                    let v = members[i]
                    for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                        colour[v] = c
                        if place(i + 1, max(used, c + 1), k) { return true }
                    }
                    colour[v] = -1
                    return false
                }
                let k = (1 ... members.count).first { place(0, 0, $0) }!
                let given = members.map { colors[$0] }, least = members.map { colour[$0] }
                #expect(given == least, "\(members) \(context)")
                // The component as a graph of its own, vertices in the same relative order.
                let inside = Set(members.map { listed[$0] })
                let component = UndirectedAdjacencyList(vertices: members.map { listed[$0] }, edges: pairs.filter { inside.contains($0.0) }.map { UndirectedEdge($0.0, $0.1) })
                let own = component.minimumColoring()
                let ownColors = members.map { own.color(of: listed[$0]) }
                #expect(ownColors == given, "\(members) \(context)")
                #expect(own.colorCount == k && component.chromaticNumber() == k, "\(members) \(context)")
            }
            // Over the whole graph each class's least vertex precedes the next class's.
            let firsts = coloring.colorClasses.map { $0.first.flatMap { index[$0] } ?? -1 }
            #expect(firsts == firsts.sorted(), "\(context)")
            #expect(coloring.colorCount == graph.chromaticNumber(), "\(context)")
        }
    }

    @Test("Bipartite multigraphs, sides interleaved in the vertex order: minimumColoring() is bipartition()'s sides, DSatur is exact, König uses exactly Δ and is api.md's procedure written out")
    func bipartiteGraphs() async throws {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 18)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 6), Gen.int(in: 1 ... 6), Gen.int(in: 0 ... 1_000_000)) { raw, l, r, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let n = l + r
            // Left 0..<l, right l..<n, all listed in one shuffled order; parallel edges kept.
            let pairs = raw.map { ($0.0 % l, l + $0.1 % r) }.map { seed % 2 == 0 ? $0 : ($0.1, $0.0) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            let context = "\(pairs) on \(listed)"
            guard let sides = graph.bipartition() else {
                Issue.record("not bipartite: \(context)")
                return
            }
            let minimum = graph.minimumColoring()
            let bySides = sides.left.allSatisfy { minimum.color(of: $0) == 0 } && sides.right.allSatisfy { minimum.color(of: $0) == 1 }
            #expect(bySides, "\(context)")
            let chi = pairs.isEmpty ? 1 : 2
            #expect(graph.chromaticNumber() == chi, "\(context)")
            #expect(graph.greedyColoring(strategy: .saturationLargestFirst).colorCount == chi, "\(context)")
            // The same on a BipartiteGraph whose sides are inserted in shuffled orders.
            guard let bipartite = BipartiteGraph(left: (0 ..< l).shuffled(using: &rng), right: (l ..< n).shuffled(using: &rng), edges: pairs.map { UndirectedEdge($0.0, $0.1) }),
                  let bipartiteSides = bipartite.bipartition() else {
                Issue.record("no BipartiteGraph: \(context)")
                return
            }
            let bipartiteMinimum = bipartite.minimumColoring()
            let bipartiteBySides = bipartiteSides.left.allSatisfy { bipartiteMinimum.color(of: $0) == 0 } && bipartiteSides.right.allSatisfy { bipartiteMinimum.color(of: $0) == 1 }
            #expect(bipartiteBySides, "\(context)")
            #expect(bipartite.greedyColoring(strategy: .saturationLargestFirst).colorCount == chi, "\(context)")

            // König, exactly Δ (parallel edges each counted), proper.
            guard let coloring = graph.bipartiteEdgeColoring() else {
                Issue.record("nil on a bipartite graph: \(context)")
                return
            }
            let m = ends.count
            let colors = (0 ..< m).map { coloring.color(ofEdgeAt: $0) }
            let maxDegree = (0 ..< n).map { v in ends.filter { $0.0 == v || $0.1 == v }.count }.max() ?? 0
            #expect(coloring.colorCount == maxDegree, "\(context)")
            for v in 0 ..< n {
                let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
                #expect(Set(at).count == at.count, "\(context)")
            }
            let checked = graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) }
            #expect(checked, "\(context)")
            // Written out: edges in position order, u the end with the lesser index; a is the least colour
            // free at u, b at v; if a is used at v, flip the a/b path from v; then the edge takes a.
            var colour = [Int](repeating: -1, count: m)
            var at = [[Int]](repeating: [Int](repeating: -1, count: maxDegree + 2), count: n)
            func other(_ e: Int, _ x: Int) -> Int { ends[e].0 == x ? ends[e].1 : ends[e].0 }
            func leastFree(_ x: Int) -> Int {
                var c = 0
                while at[x][c] >= 0 { c += 1 }
                return c
            }
            func paint(_ e: Int, _ c: Int) {
                colour[e] = c
                at[ends[e].0][c] = e
                at[ends[e].1][c] = e
            }
            func flip(_ start: Int, _ c1: Int, _ c2: Int) {
                var path: [Int] = []
                var x = start, c = c1
                while at[x][c] >= 0 {
                    let e = at[x][c]
                    path.append(e)
                    x = other(e, x)
                    c = c == c1 ? c2 : c1
                }
                let old = path.map { colour[$0] }
                for e in path {
                    at[ends[e].0][colour[e]] = -1
                    at[ends[e].1][colour[e]] = -1
                }
                for (e, o) in zip(path, old) { paint(e, o == c1 ? c2 : c1) }
            }
            for e in 0 ..< m {
                let (u, v) = ends[e].0 < ends[e].1 ? ends[e] : (ends[e].1, ends[e].0)
                let a = leastFree(u), b = leastFree(v)
                if at[v][a] >= 0 { flip(v, a, b) }
                paint(e, a)
            }
            #expect(colors == colour, "\(context)")
        }
    }

    @Test("edgeColoring() on simple graphs: proper, Δ ≤ colours ≤ Δ + 1, classes matchings, and Misra–Gries as api.md writes it")
    func misraGries() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 34)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // A simple graph: self-loops dropped, each pair kept at its first occurrence, as written.
            var kept = Set<[Int]>()
            var pairs: [(Int, Int)] = []
            for (a, b) in raw.map({ ($0.0 % n, $0.1 % n) }) where a != b && kept.insert([min(a, b), max(a, b)]).inserted { pairs.append((a, b)) }
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let graph = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            let ends = pairs.map { (index[$0.0]!, index[$0.1]!) }
            let context = "\(pairs) on \(listed)"
            let m = ends.count
            let coloring = graph.edgeColoring()
            let colors = (0 ..< m).map { coloring.color(ofEdgeAt: $0) }
            let maxDegree = (0 ..< n).map { v in ends.filter { $0.0 == v || $0.1 == v }.count }.max() ?? 0
            for v in 0 ..< n {
                let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }
                #expect(Set(at).count == at.count, "\(context)")
            }
            let checked = graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) }
            #expect(checked, "\(context)")
            #expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1, "\(context)")
            #expect(Set(colors) == Set(0 ..< coloring.colorCount), "\(context)")
            let classes = coloring.colorClasses.map { Array($0) }
            let expectedClasses = (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } }
            #expect(classes == expectedClasses, "\(context)")

            // Misra–Gries written out (api.md): edges in position order; u the end with the lesser index,
            // c the least colour free at u; the fan [v] grows, while c is not free at its last vertex, by
            // the neighbour x of u not in it whose edge ux has the least colour free at the last vertex. If c
            // is free at the last fan vertex, d = c; otherwise d is the least colour free there and the d/c
            // path from u is flipped. w is the first fan vertex such that the fan up to w is still a fan and
            // d is free at w; the fan is rotated up to w and uw takes d.
            var colour = [Int](repeating: -1, count: m)
            var at = [[Int]](repeating: [Int](repeating: -1, count: maxDegree + 2), count: n)
            func other(_ e: Int, _ x: Int) -> Int { ends[e].0 == x ? ends[e].1 : ends[e].0 }
            func isFree(_ x: Int, _ c: Int) -> Bool { c < 0 || at[x][c] < 0 }
            func leastFree(_ x: Int) -> Int {
                var c = 0
                while at[x][c] >= 0 { c += 1 }
                return c
            }
            func paint(_ e: Int, _ c: Int) {
                colour[e] = c
                at[ends[e].0][c] = e
                at[ends[e].1][c] = e
            }
            func clear(_ e: Int) {
                at[ends[e].0][colour[e]] = -1
                at[ends[e].1][colour[e]] = -1
                colour[e] = -1
            }
            for e in 0 ..< m {
                let (u, v) = ends[e].0 < ends[e].1 ? ends[e] : (ends[e].1, ends[e].0)
                let c = leastFree(u)
                var fan = [v], fanEdges = [e]
                while !isFree(fan.last!, c) {
                    let last = fan.last!
                    var next: (Int, Int)?
                    for k in 0 ... maxDegree where at[u][k] >= 0 && isFree(last, k) && !fan.contains(other(at[u][k], u)) {
                        next = (other(at[u][k], u), at[u][k])
                        break
                    }
                    guard let (x, edge) = next else { break }
                    fan.append(x)
                    fanEdges.append(edge)
                }
                var d = c
                if !isFree(fan.last!, c) {
                    d = leastFree(fan.last!)
                    var path: [Int] = []
                    var x = u, current = d
                    while at[x][current] >= 0 {
                        let f = at[x][current]
                        path.append(f)
                        x = other(f, x)
                        current = current == d ? c : d
                    }
                    let old = path.map { colour[$0] }
                    for f in path { clear(f) }
                    for (f, o) in zip(path, old) { paint(f, o == d ? c : d) }
                }
                var w = -1
                for i in fan.indices {
                    if i > 0 && !isFree(fan[i - 1], colour[fanEdges[i]]) { break }
                    if isFree(fan[i], d) {
                        w = i
                        break
                    }
                }
                guard w >= 0 else {
                    Issue.record("no w: \(context)")
                    return
                }
                let shifted = (0 ..< w).map { colour[fanEdges[$0 + 1]] }
                for j in stride(from: 1, through: w, by: 1) { clear(fanEdges[j]) }
                for j in 0 ..< w { paint(fanEdges[j], shifted[j]) }
                paint(fanEdges[w], d)
            }
            #expect(colors == colour, "\(context)")
        }
    }

    @Test("isColoring and isEdgeColoring agree with their definitions on random colours, the closure called once per vertex or edge")
    func checksAgainstDefinitions() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 14)
        await propertyCheck(count: 400, input: edges, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let context = "\(pairs) on \(listed)"
            // Few colours, so both answers come up; negative and gapped values too.
            let vertexColour = Dictionary(uniqueKeysWithValues: listed.map { ($0, [-3, 0, 2][Int.random(in: 0 ..< 3, using: &rng)]) })
            let edgeColour = pairs.indices.map { _ in Int.random(in: -1 ... 2, using: &rng) }
            let proper = pairs.allSatisfy { $0.0 == $0.1 || vertexColour[$0.0]! != vertexColour[$0.1]! }
            var vertexCalls = 0
            let isColoring = graph.isColoring { vertexCalls += 1; return vertexColour[$0]! }
            #expect(isColoring == proper && vertexCalls == n, "\(context) \(vertexColour)")
            // Each vertex's edges (a self-loop once) have distinct colours.
            let properEdges = listed.allSatisfy { x in
                let at = pairs.indices.filter { pairs[$0].0 == x || pairs[$0].1 == x }.map { edgeColour[$0] }
                return Set(at).count == at.count
            }
            var edgeCalls = 0
            let isEdgeColoring = graph.isEdgeColoring { edgeCalls += 1; return edgeColour[$0] }
            #expect(isEdgeColoring == properEdges && edgeCalls == pairs.count, "\(context) \(edgeColour)")
        }
    }
}
