// Properties against oracles written inside each test, with shrinking (swift-property-based): on a
// failure, PropertyBased shrinks the generated input and prints the smallest one that still fails.
// Graphs are multigraphs with self-loops and parallel edges on 1 … 8 vertices listed in an order
// shuffled by a seed (so vertex indices are not vertex values), on `Pseudograph` and
// `DirectedPseudograph`, whose rows are in position order (a self-loop twice). The oracles: the
// definitions (degrees and the components of the edges); api.md's procedures written out
// (Hierholzer's walk with its start rules, nearest neighbour, JGraphT's 2-opt); brute force over
// every ordering of the vertices (the first Hamiltonian path or cycle in search order, as the least
// key of start and row indices; the shortest tour and the lexicographically least among the
// optimal ones). Every oracle is polynomial or bounded by 8! orderings. Then three larger ones:
// 2-opt on complete graphs of 15 … 40 vertices against JGraphT's loop written out; Christofides
// against its pinned composition written out (Prim, the odd vertices, every minimum perfect matching
// by enumeration, Hierholzer, the first visits); Held–Karp on up to 10 vertices, directed too,
// against JGraphT's memoized recursion written out. See README.md.
// Conditions with a closure are computed into a constant before `#expect`: inside these closures a
// closure in an `#expect` expansion failed SIL verification with this toolchain (README.md).

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing
import Tours
import Walks

@Suite("Tours properties against oracles, with shrinking", .tags(.randomized))
struct ToursPropertyTests {
    @Test("Undirected: isEulerian and hasEulerianTrail are the definitions; every circuit and trail, from every start, is Hierholzer's walk written out, uses every edge once, and starts where api.md says")
    func undirectedEulerian() async {
        let steps = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 40)
        await propertyCheck(count: 300, input: steps, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            // A walk from vertex 0 (a stay is a self-loop), closed back to 0 when the seed is even, so
            // Eulerian by construction; each edge written either way round; every third seed one more
            // edge, which usually breaks it.
            var walk = [0] + raw.map { $0.0 % n }
            if seed % 2 == 0 && walk.last != 0 { walk.append(0) }
            var ends: [(Int, Int)] = []
            for i in 0 ..< walk.count - 1 {
                let flip = i < raw.count && raw[i].1 % 2 == 1
                ends.append(flip ? (walk[i + 1], walk[i]) : (walk[i], walk[i + 1]))
            }
            if seed % 3 == 0, let last = raw.last { ends.append((last.1 % n, (last.0 + last.1) % n)) }
            let m = ends.count
            let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
            let context = "\(ends) on \(listed)"

            // The definitions: degrees (a self-loop adds 2), the vertices with edges in one component.
            var degree = [Int](repeating: 0, count: n)
            var parent = Array(0 ..< n)
            func root(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (a, b) in ends {
                degree[a] += 1
                degree[b] += 1
                if root(a) != root(b) { parent[root(a)] = root(b) }
            }
            let connected = Set(ends.map { root($0.0) }).count <= 1
            let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
            let eulerian = connected && odd.isEmpty
            let hasTrail = connected && (odd.isEmpty || odd.count == 2)
            #expect(graph.isEulerian == eulerian, "\(context)")
            #expect(graph.hasEulerianTrail == hasTrail, "\(context)")

            // Hierholzer written out (api.md): rows in position order, a self-loop twice; take the first
            // unused edge of the top vertex, or pop it onto the output; the output reversed.
            var rows = [[(edge: Int, to: Int)]](repeating: [], count: n)
            for (k, (a, b)) in ends.enumerated() {
                rows[a].append((k, b))
                rows[b].append((k, a))
            }
            func hierholzer(_ start: Int) -> ([Int], [Int]) {
                var used = [Bool](repeating: false, count: m), next = [Int](repeating: 0, count: n)
                var stack = [(start, -1)], out: [(Int, Int)] = []
                while let top = stack.last {
                    let (v, e) = top
                    while next[v] < rows[v].count && used[rows[v][next[v]].edge] { next[v] += 1 }
                    if next[v] < rows[v].count {
                        let (f, w) = rows[v][next[v]]
                        used[f] = true
                        stack.append((w, f))
                    } else {
                        stack.removeLast()
                        out.append((v, e))
                    }
                }
                out.reverse()
                return (out.map(\.0), out.dropFirst().map(\.1))
            }
            let firstWithEdge = (0 ..< n).first { degree[$0] > 0 }
            for start in [nil] + (0 ..< n).map({ Optional($0) }) {
                // The circuit: Eulerian with an edge, from the first vertex with an edge or a given one with an edge.
                var circuit: ([Int], [Int])? = nil
                if eulerian, let s = start ?? firstWithEdge, degree[s] > 0 {
                    let (vs, es) = hierholzer(s)
                    circuit = (Array(vs.dropLast()), es)
                    let usesEveryEdge = es.sorted() == Array(0 ..< m)
                    #expect(usesEveryEdge && vs.first == vs.last, "oracle \(context)")
                }
                let gotCircuit = start == nil ? graph.eulerianCircuit() : graph.eulerianCircuit(from: listed[start!])
                let circuitAgrees = gotCircuit?.vertices == circuit.map { $0.0.map { listed[$0] } } && gotCircuit?.edges == circuit?.1
                #expect(circuitAgrees, "circuit from \(String(describing: start)) \(context)")
                // The trail: the first odd vertex, or Eulerian the first vertex with an edge; from a start,
                // an odd vertex, or Eulerian any vertex with an edge; the trivial trail without edges.
                var trail: ([Int], [Int])? = nil
                if hasTrail && n > 0 {
                    if m == 0 {
                        trail = ([start ?? 0], [])
                    } else if let s = start ?? (eulerian ? firstWithEdge : odd.first), eulerian ? degree[s] > 0 : degree[s] % 2 == 1 {
                        trail = hierholzer(s)
                        let usesEveryEdge = trail!.1.sorted() == Array(0 ..< m)
                        #expect(usesEveryEdge, "oracle \(context)")
                    }
                }
                let gotTrail = start == nil ? graph.eulerianTrail() : graph.eulerianTrail(from: listed[start!])
                let trailAgrees = gotTrail?.vertices == trail.map { $0.0.map { listed[$0] } } && gotTrail?.edges == trail?.1
                #expect(trailAgrees, "trail from \(String(describing: start)) \(context)")
            }
            let circuitExists = graph.eulerianCircuit() != nil
            #expect(eulerian == (circuitExists || m == 0), "\(context)")
        }
    }

    @Test("Directed: isEulerian and hasEulerianTrail are the definitions; every circuit and trail, from every start, is Hierholzer's walk written out over out-edges")
    func directedEulerian() async {
        let steps = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 40)
        await propertyCheck(count: 300, input: steps, Gen.int(in: 1 ... 8), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            // A directed walk from 0, closed when the seed is even; every third seed one more arc; the
            // arcs in an order rotated by raw's first entry (the walk's arcs still balance).
            var walk = [0] + raw.map { $0.0 % n }
            if seed % 2 == 0 && walk.last != 0 { walk.append(0) }
            var ends = (0 ..< walk.count - 1).map { (walk[$0], walk[$0 + 1]) }
            if let first = raw.first, !ends.isEmpty {
                let k = first.1 % ends.count
                ends = Array(ends[k...] + ends[..<k])
            }
            if seed % 3 == 0, let last = raw.last { ends.append((last.1 % n, (last.0 + last.1) % n)) }
            let m = ends.count
            let graph = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
            let context = "\(ends) on \(listed)"

            var outDegree = [Int](repeating: 0, count: n), inDegree = [Int](repeating: 0, count: n)
            var parent = Array(0 ..< n)
            func root(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (a, b) in ends {
                outDegree[a] += 1
                inDegree[b] += 1
                if root(a) != root(b) { parent[root(a)] = root(b) }
            }
            let connected = Set(ends.map { root($0.0) }).count <= 1
            let surplus = (0 ..< n).map { outDegree[$0] - inDegree[$0] }
            let balanced = surplus.allSatisfy { $0 == 0 }
            let source = (0 ..< n).filter { surplus[$0] == 1 }
            let oneEach = source.count == 1 && surplus.filter { $0 == -1 }.count == 1 && surplus.allSatisfy { abs($0) <= 1 }
            let eulerian = connected && balanced
            let hasTrail = connected && (balanced || oneEach)
            #expect(graph.isEulerian == eulerian, "\(context)")
            #expect(graph.hasEulerianTrail == hasTrail, "\(context)")

            var rows = [[(edge: Int, to: Int)]](repeating: [], count: n)
            for (k, (a, b)) in ends.enumerated() { rows[a].append((k, b)) }
            func hierholzer(_ start: Int) -> ([Int], [Int]) {
                var next = [Int](repeating: 0, count: n)
                var stack = [(start, -1)], out: [(Int, Int)] = []
                while let top = stack.last {
                    let (v, e) = top
                    if next[v] < rows[v].count {
                        let (f, w) = rows[v][next[v]]
                        next[v] += 1
                        stack.append((w, f))
                    } else {
                        stack.removeLast()
                        out.append((v, e))
                    }
                }
                out.reverse()
                return (out.map(\.0), out.dropFirst().map(\.1))
            }
            let firstWithEdge = (0 ..< n).first { outDegree[$0] + inDegree[$0] > 0 }
            for start in [nil] + (0 ..< n).map({ Optional($0) }) {
                var circuit: ([Int], [Int])? = nil
                if eulerian, let s = start ?? firstWithEdge, outDegree[s] > 0 {
                    let (vs, es) = hierholzer(s)
                    circuit = (Array(vs.dropLast()), es)
                    let usesEveryEdge = es.sorted() == Array(0 ..< m)
                    #expect(usesEveryEdge, "oracle \(context)")
                }
                let gotCircuit = start == nil ? graph.eulerianCircuit() : graph.eulerianCircuit(from: listed[start!])
                let circuitAgrees = gotCircuit?.vertices == circuit.map { $0.0.map { listed[$0] } } && gotCircuit?.edges == circuit?.1
                #expect(circuitAgrees, "circuit from \(String(describing: start)) \(context)")
                var trail: ([Int], [Int])? = nil
                if hasTrail && n > 0 {
                    if m == 0 {
                        trail = ([start ?? 0], [])
                    } else if let s = start ?? (eulerian ? firstWithEdge : source.first), eulerian ? outDegree[s] > 0 : surplus[s] == 1 {
                        trail = hierholzer(s)
                        let usesEveryEdge = trail!.1.sorted() == Array(0 ..< m)
                        #expect(usesEveryEdge, "oracle \(context)")
                    }
                }
                let gotTrail = start == nil ? graph.eulerianTrail() : graph.eulerianTrail(from: listed[start!])
                let trailAgrees = gotTrail?.vertices == trail.map { $0.0.map { listed[$0] } } && gotTrail?.edges == trail?.1
                #expect(trailAgrees, "trail from \(String(describing: start)) \(context)")
            }
        }
    }

    @Test("Hamiltonian paths and cycles, undirected and directed, are the first in search order: by brute force over every ordering, the least key of start and row indices (api.md)")
    func hamiltonianFirstInSearchOrder() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 6), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { raw, n, directed, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let context = "\(ends) on \(listed), directed \(directed)"
            // Rows in position order: out-edges, or every edge end (a self-loop twice).
            var rows = [[(edge: Int, to: Int)]](repeating: [], count: n)
            for (k, (a, b)) in ends.enumerated() {
                rows[a].append((k, b))
                if !directed { rows[b].append((k, a)) }
            }
            // The key of an ordering (api.md): its start, then for each step the row index of the first
            // edge to the next vertex, then (a cycle) the row index of the first edge back to the start
            // that the steps did not use. Steps between distinct vertices never reuse an edge.
            func key(_ order: [Int], cycle: Bool) -> (key: [Int], edges: [Int])? {
                var key = [order[0]], taken: [Int] = []
                for i in 0 ..< order.count - 1 {
                    guard let k = rows[order[i]].firstIndex(where: { $0.to == order[i + 1] }) else { return nil }
                    key.append(k)
                    taken.append(rows[order[i]][k].edge)
                }
                if cycle {
                    let last = order[order.count - 1]
                    guard let k = rows[last].firstIndex(where: { $0.to == order[0] && !taken.contains($0.edge) }) else { return nil }
                    key.append(k)
                    taken.append(rows[last][k].edge)
                }
                return (key, taken)
            }
            var orders: [[Int]] = []
            var order = Array(0 ..< n)
            while true {
                orders.append(order)
                var i = n - 2
                while i >= 0 && order[i] >= order[i + 1] { i -= 1 }
                if i < 0 { break }
                var j = n - 1
                while order[j] <= order[i] { j -= 1 }
                order.swapAt(i, j)
                order[(i + 1)...].reverse()
            }
            func least(cycle: Bool, _ keep: ([Int]) -> Bool) -> ([Int], [Int])? {
                var best: (key: [Int], order: [Int], edges: [Int])? = nil
                for o in orders where keep(o) {
                    if let r = key(o, cycle: cycle), best == nil || r.key.lexicographicallyPrecedes(best!.key) { best = (r.key, o, r.edges) }
                }
                return best.map { ($0.order.map { listed[$0] }, $0.edges) }
            }
            let target = seed % n
            for start in [nil] + (0 ..< n).map({ Optional($0) }) {
                let expected = least(cycle: false) { start == nil || $0[0] == start! }
                let got: Path<Int, Int>?
                if directed {
                    let graph = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
                    got = start == nil ? graph.hamiltonianPath() : graph.hamiltonianPath(from: listed[start!])
                } else {
                    let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
                    got = start == nil ? graph.hamiltonianPath() : graph.hamiltonianPath(from: listed[start!])
                }
                let agrees = got?.vertices == expected?.0 && got?.edges == expected?.1
                #expect(agrees, "path from \(String(describing: start)) \(context)")
                guard let s = start else { continue }
                // To the target: nil when it is the start, unless the graph has one vertex.
                let toTarget = s == target && n > 1 ? nil : least(cycle: false) { $0[0] == s && $0[n - 1] == target }
                let gotTo: Path<Int, Int>?
                if directed {
                    let graph = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) })
                    gotTo = graph.hamiltonianPath(from: listed[s], to: listed[target])
                } else {
                    let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
                    gotTo = graph.hamiltonianPath(from: listed[s], to: listed[target])
                }
                let toAgrees = gotTo?.vertices == toTarget?.0 && gotTo?.edges == toTarget?.1
                #expect(toAgrees, "path from \(s) to \(target) \(context)")
            }
            let cycle = least(cycle: true) { $0[0] == 0 }
            let gotCycle: Cycle<Int, Int>?
            if directed {
                gotCycle = DirectedPseudograph(vertices: listed, edges: ends.map { DirectedEdge(from: listed[$0.0], to: listed[$0.1]) }).hamiltonianCycle()
            } else {
                gotCycle = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) }).hamiltonianCycle()
            }
            let cycleAgrees = gotCycle?.vertices == cycle?.0 && gotCycle?.edges == cycle?.1
            #expect(cycleAgrees, "cycle \(context)")
        }
    }

    @Test("Tours on complete multigraphs with parallel copies and self-loops: nearest neighbour and 2-opt are the procedures written out, Held–Karp the brute-force optimum and the least optimal order, Christofides a tour no lighter; each through the lightest copies, each weight asked once")
    func toursOnCompleteMultigraphs() async {
        let extras = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: -3 ... 9)).array(of: 0 ... 8)
        let weights = Gen.int(in: -3 ... 9).array(of: 21 ... 21)
        await propertyCheck(count: 200, input: extras, weights, Gen.int(in: 3 ... 7), Gen.int(in: 0 ... 1_000_000)) { extra, base, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let listed = seed == 0 ? Array(0 ..< n) : Array(0 ..< n).shuffled(using: &rng)
            // Extra copies and self-loops first, then K(n) in lexicographic pair order, so a pair's lightest
            // copy is sometimes an extra one and ties between copies are decided by position.
            var ends = extra.map { ($0.0 % n, $0.1 % n) }
            var weight = extra.map(\.2)
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    ends.append((i, j))
                    weight.append(base[ends.count % base.count])
                }
            }
            let m = ends.count
            let graph = Pseudograph(vertices: listed, edges: ends.map { UndirectedEdge(listed[$0.0], listed[$0.1]) })
            let context = "\(ends) weights \(weight) on \(listed)"
            var lightest = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
            for k in 0 ..< m where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if lightest[a][b] >= 0 && weight[lightest[a][b]] <= weight[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            func d(_ a: Int, _ b: Int) -> Int { weight[lightest[a][b]] }
            func total(_ order: [Int]) -> Int { (0 ..< n).reduce(0) { $0 + d(order[$1], order[($1 + 1) % n]) } }
            // Checks a tour: every vertex once, each step through its pair's lightest copy; its order by index.
            func indices(_ tour: Cycle<Int, Int>?, _ what: String) -> [Int]? {
                guard let tour else {
                    Issue.record("\(what) is nil: \(context)")
                    return nil
                }
                let order = tour.vertices.map { listed.firstIndex(of: $0)! }
                let lightestSteps = tour.edges == (0 ..< n).map { lightest[order[$0]][order[($0 + 1) % n]] }
                #expect(order.sorted() == Array(0 ..< n) && lightestSteps, "\(what) \(context)")
                return order
            }
            // Nearest neighbour written out, from every start.
            func nearest(_ s: Int) -> [Int] {
                var order = [s], seen = Set([s])
                while order.count < n {
                    let from = order[order.count - 1]
                    let next = (0 ..< n).filter { !seen.contains($0) }.min { d(from, $0) < d(from, $1) }!
                    order.append(next)
                    seen.insert(next)
                }
                return order
            }
            for s in 0 ..< n {
                let got = indices(graph.nearestNeighborTour(from: listed[s], weight: { weight[$0] }), "nearest from \(s)")
                #expect(got == nearest(s), "nearest from \(s) \(context)")
            }
            let first = indices(graph.nearestNeighborTour(weight: { weight[$0] }), "nearest")
            #expect(first == nearest(0), "nearest \(context)")
            // JGraphT's 2-opt written out: the best move (i, j), the first on ties, until none improves.
            func twoOpt(_ start: [Int]) -> [Int] {
                var t = start + [start[0]]
                while true {
                    var best = 0, bi = -1, bj = -1
                    for i in 0 ..< n - 2 {
                        for j in i + 2 ..< n {
                            let change = d(t[i], t[j]) + d(t[i + 1], t[j + 1]) - d(t[i], t[i + 1]) - d(t[j], t[j + 1])
                            if change < best {
                                best = change
                                bi = i
                                bj = j
                            }
                        }
                    }
                    if bi < 0 { return Array(t.dropLast()) }
                    t[(bi + 1) ... bj].reverse()
                }
            }
            let improved = indices(graph.twoOptTour(weight: { weight[$0] }), "2-opt")
            #expect(improved == twoOpt(nearest(0)), "2-opt \(context)")
            var scrambled = Array(0 ..< n)
            scrambled.shuffle(using: &rng)
            let start = Cycle(vertices: scrambled.map { listed[$0] }, edges: (0 ..< n).map { lightest[scrambled[$0]][scrambled[($0 + 1) % n]] })!
            let fromScrambled = indices(graph.twoOptTour(improving: start, weight: { weight[$0] }), "2-opt improving")
            #expect(fromScrambled == twoOpt(scrambled), "2-opt from \(scrambled) \(context)")
            // Brute force: the optimum, and the first optimal ordering after vertex 0 in lexicographic order.
            var order = Array(0 ..< n), optimum = Int.max, least: [Int] = []
            while true {
                let w = total(order)
                if w < optimum {
                    optimum = w
                    least = order
                }
                var i = n - 2
                while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
                if i < 1 { break }
                var j = n - 1
                while order[j] <= order[i] { j -= 1 }
                order.swapAt(i, j)
                order[(i + 1)...].reverse()
            }
            var asked: [Int] = []
            let shortestTour = graph.shortestTour { position in
                asked.append(position)
                return weight[position]
            }
            let askedOnce = asked == (0 ..< m).filter { ends[$0].0 != ends[$0].1 }
            #expect(askedOnce, "\(context)")
            let shortest = indices(shortestTour, "shortest")
            #expect(shortest == least, "shortest \(context)")
            let christofides = indices(graph.christofidesTour(weight: { weight[$0] }), "christofides")
            if let christofides {
                #expect(christofides[0] == 0 && total(christofides) >= optimum, "christofides \(context)")
            }
            if let improved, let first {
                #expect(total(improved) <= total(first), "2-opt heavier \(context)")
            }
        }
    }

    @Test("Christofides on random Manhattan points, in Int and in Double quarters: within 3/2 of the brute-force optimum, never below it")
    func christofidesBound() async {
        let points = zip(Gen.int(in: 0 ... 20), Gen.int(in: 0 ... 20)).array(of: 3 ... 8)
        await propertyCheck(count: 150, input: points, Gen.bool) { points, quarters in
            let n = points.count
            let pairs = (0 ..< n).flatMap { i in (i + 1 ..< n).map { (i, $0) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let manhattan = pairs.map { abs(points[$0.0].0 - points[$0.1].0) + abs(points[$0.0].1 - points[$0.1].1) }
            var distance = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
            for (k, (a, b)) in pairs.enumerated() {
                distance[a][b] = manhattan[k]
                distance[b][a] = manhattan[k]
            }
            var order = Array(0 ..< n), optimum = Int.max
            while true {
                optimum = min(optimum, (0 ..< n).reduce(0) { $0 + distance[order[$1]][order[($1 + 1) % n]] })
                var i = n - 2
                while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
                if i < 1 { break }
                var j = n - 1
                while order[j] <= order[i] { j -= 1 }
                order.swapAt(i, j)
                order[(i + 1)...].reverse()
            }
            let context = "\(points) quarters \(quarters)"
            if quarters {
                let scaled = manhattan.map { Double($0) / 4 }
                let tour = graph.christofidesTour(weight: { scaled[$0] })
                let w = tour?.weight({ scaled[$0] }) ?? -1
                let everyVertex = Set(tour?.vertices ?? []) == Set(0 ..< n)
                #expect(w >= Double(optimum) / 4 && 2 * w <= 3 * Double(optimum) / 4, "\(w) vs \(optimum) \(context)")
                #expect(everyVertex, "\(context)")
            } else {
                let tour = graph.christofidesTour(weight: { manhattan[$0] })
                let w = tour?.weight({ manhattan[$0] }) ?? -1
                let everyVertex = Set(tour?.vertices ?? []) == Set(0 ..< n)
                #expect(w >= optimum && 2 * w <= 3 * optimum, "\(w) vs \(optimum) \(context)")
                #expect(everyVertex, "\(context)")
                #expect(tour?.vertices.first == 0, "\(context)")
            }
        }
    }

    @Test("shortestTour on graphs that need not be complete: nil exactly when no Hamiltonian cycle exists; otherwise the brute-force optimum and the least optimal order")
    func shortestTourIncomplete() async {
        let edges = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 9)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 3 ... 7)) { raw, n in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            let weight = raw.map(\.2)
            let graph = Pseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
            var lightest = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
            for k in ends.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if lightest[a][b] >= 0 && weight[lightest[a][b]] <= weight[k] { continue }
                lightest[a][b] = k
                lightest[b][a] = k
            }
            var order = Array(0 ..< n), optimum: Int? = nil, least: [Int] = []
            while true {
                if (0 ..< n).allSatisfy({ lightest[order[$0]][order[($0 + 1) % n]] >= 0 }) {
                    let w = (0 ..< n).reduce(0) { $0 + weight[lightest[order[$1]][order[($1 + 1) % n]]] }
                    if optimum == nil || w < optimum! {
                        optimum = w
                        least = order
                    }
                }
                var i = n - 2
                while i >= 1 && order[i] >= order[i + 1] { i -= 1 }
                if i < 1 { break }
                var j = n - 1
                while order[j] <= order[i] { j -= 1 }
                order.swapAt(i, j)
                order[(i + 1)...].reverse()
            }
            let tour = graph.shortestTour(weight: { weight[$0] })
            let context = "\(ends) weights \(weight)"
            #expect(tour?.vertices == (optimum == nil ? nil : least), "\(context)")
            let tourWeight = tour?.weight({ weight[$0] })
            #expect(tourWeight == optimum, "\(context)")
            let hamiltonian = graph.hamiltonianCycle() != nil
            #expect(hamiltonian == (optimum != nil), "\(context)")
        }
    }

    @Test("2-opt on 15 … 40 vertices, from a scrambled tour, Int or Double-quarter weights with many ties: JGraphT's best-improvement loop written out, move for move (the incremental row cache must find the same moves)")
    func twoOptLarge() async {
        await propertyCheck(count: 60, input: Gen.int(in: 15 ... 40), Gen.int(in: 2 ... 1000), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { n, span, quarters, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = (0 ..< n).flatMap { i in (i + 1 ..< n).map { (i, $0) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let raw = pairs.map { _ in Int.random(in: 1 ... span, using: &rng) }
            var position = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
            for (k, (a, b)) in pairs.enumerated() {
                position[a][b] = k
                position[b][a] = k
            }
            var scrambled = Array(0 ..< n)
            scrambled.shuffle(using: &rng)
            let start = Cycle(vertices: scrambled, edges: (0 ..< n).map { position[scrambled[$0]][scrambled[($0 + 1) % n]] })!
            // JGraphT's TwoOptHeuristicTSP.improve written out: t[0 … n] with t[n] = t[0]; each round the move
            // (i, j), 0 ≤ i < n − 2, i + 2 ≤ j < n, with the least change d(tᵢ, tⱼ) + d(tᵢ₊₁, tⱼ₊₁) − d(tᵢ, tᵢ₊₁) −
            // d(tⱼ, tⱼ₊₁) below zero, the first in row-major order on ties, reversing t[i + 1 … j]. The weights
            // are integers here (quarters scaled by 4), so the sums are exact either way.
            func d(_ a: Int, _ b: Int) -> Int { raw[position[a][b]] }
            var t = scrambled + [scrambled[0]]
            var moves = 0
            while true {
                var best = 0, bi = -1, bj = -1
                for i in 0 ..< n - 2 {
                    for j in i + 2 ..< n {
                        let change = d(t[i], t[j]) + d(t[i + 1], t[j + 1]) - d(t[i], t[i + 1]) - d(t[j], t[j + 1])
                        if change < best {
                            best = change
                            bi = i
                            bj = j
                        }
                    }
                }
                if bi < 0 { break }
                t[(bi + 1) ... bj].reverse()
                moves += 1
            }
            let expected = Array(t.dropLast())
            let context = "n \(n) span \(span) quarters \(quarters) seed \(seed), \(moves) moves"
            if quarters {
                let weights = raw.map { Double($0) / 4 }
                let tour = graph.twoOptTour(improving: start, weight: { weights[$0] })
                #expect(tour?.vertices == expected, "\(context)")
            } else {
                let tour = graph.twoOptTour(improving: start, weight: { raw[$0] })
                #expect(tour?.vertices == expected, "\(context)")
                let lightest = tour.map { $0.edges == (0 ..< n).map { position[expected[$0]][expected[($0 + 1) % n]] } }
                #expect(lightest == true, "\(context)")
            }
        }
    }

    @Test("Christofides is the pinned composition written out: dense Prim under (weight, edge number), the odd vertices in order, a minimum-weight perfect matching on them, Hierholzer from vertex 0 on the tree edges by number then the matched pairs, the first visits; the tour is that of one minimum matching (the only one when it is unique)")
    func christofidesComposition() async {
        await propertyCheck(count: 300, input: Gen.int(in: 3 ... 9), Gen.int(in: 1 ... 40), Gen.int(in: 0 ... 1_000_000)) { n, span, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = (0 ..< n).flatMap { i in (i + 1 ..< n).map { (i, $0) } }
            let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let weights = pairs.map { _ in Int.random(in: 1 ... span, using: &rng) }
            var number = [[Int]](repeating: [Int](repeating: 0, count: n), count: n)
            for (k, (a, b)) in pairs.enumerated() {
                number[a][b] = k
                number[b][a] = k
            }
            func w(_ a: Int, _ b: Int) -> Int { weights[number[a][b]] }
            // Dense Prim from vertex 0, each outside vertex keyed by its lightest edge to the tree under the strict
            // order (weight, edge number); the next vertex the least key.
            var inTree = [true] + [Bool](repeating: false, count: n - 1)
            var key = (0 ..< n).map { (w(0, $0), number[0][$0]) }, parent = [Int](repeating: 0, count: n)
            var tree: [(edge: Int, a: Int, b: Int)] = []
            var degree = [Int](repeating: 0, count: n)
            for _ in 1 ..< n {
                let next = (1 ..< n).filter { !inTree[$0] }.min { key[$0] < key[$1] }!
                inTree[next] = true
                tree.append((key[next].1, parent[next], next))
                degree[next] += 1
                degree[parent[next]] += 1
                for v in 1 ..< n where !inTree[v] && (w(next, v), number[next][v]) < key[v] {
                    key[v] = (w(next, v), number[next][v])
                    parent[v] = next
                }
            }
            tree.sort { $0.edge < $1.edge }
            let odd = (0 ..< n).filter { degree[$0] % 2 == 1 }
            // Every perfect matching on the odd vertices, as pairs (a < b) in lexicographic order; the lightest.
            func matchings(_ rest: [Int]) -> [[(Int, Int)]] {
                guard let a = rest.first else { return [[]] }
                return rest.dropFirst().flatMap { b in matchings(rest.filter { $0 != a && $0 != b }).map { [(a, b)] + $0 } }
            }
            let all = matchings(odd)
            let least = all.map { $0.reduce(0) { $0 + w($1.0, $1.1) } }.min()!
            let minimum = all.filter { $0.reduce(0) { $0 + w($1.0, $1.1) } == least }
            // The composition for one matching: the multigraph's rows (each edge appended to both ends' rows in
            // order: tree edges, then matched pairs), Hierholzer's stack from vertex 0 (the first unused edge, or pop
            // onto the output), the output reversed, each vertex kept at its first visit.
            func composition(_ matched: [(Int, Int)]) -> [Int] {
                let ends = tree.map { ($0.a, $0.b) } + matched
                var rows = [[(edge: Int, to: Int)]](repeating: [], count: n)
                for (h, (a, b)) in ends.enumerated() {
                    rows[a].append((h, b))
                    rows[b].append((h, a))
                }
                var used = [Bool](repeating: false, count: ends.count), cursor = [Int](repeating: 0, count: n)
                var stack = [0], out: [Int] = []
                while let v = stack.last {
                    while cursor[v] < rows[v].count && used[rows[v][cursor[v]].edge] { cursor[v] += 1 }
                    if cursor[v] < rows[v].count {
                        used[rows[v][cursor[v]].edge] = true
                        stack.append(rows[v][cursor[v]].to)
                    } else {
                        out.append(stack.removeLast())
                    }
                }
                var seen = Set<Int>(), order: [Int] = []
                for v in out.reversed() where seen.insert(v).inserted { order.append(v) }
                return order
            }
            let candidates = minimum.map(composition)
            let tour = graph.christofidesTour(weight: { weights[$0] })
            let context = "n \(n) weights \(weights): \(minimum.count) minimum matchings"
            let isOne = tour.map { candidates.contains($0.vertices) } ?? false
            #expect(isOne, "\(String(describing: tour?.vertices)) not in \(candidates) \(context)")
            if minimum.count == 1 { #expect(tour?.vertices == candidates[0], "\(context)") }
            let lightest = tour.map { t in t.edges == (0 ..< n).map { number[t.vertices[$0]][t.vertices[($0 + 1) % n]] } }
            #expect(lightest == true, "\(context)")
        }
    }

    @Test("Held–Karp on up to 10 vertices, undirected and directed, complete or not, with parallel copies, loops and ties: JGraphT's memoized recursion and reconstruction written out")
    func heldKarpWrittenOut() async {
        await propertyCheck(count: 150, input: Gen.int(in: 3 ... 10), Gen.int(in: 1 ... 12), Gen.bool, Gen.int(in: 0 ... 1_000_000)) { n, span, directed, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            // Each pair (ordered pair, directed) present with probability 3/4 or 1 (every fourth seed complete),
            // some doubled, a few loops, shuffled into position order.
            var ends: [(Int, Int)] = []
            for i in 0 ..< n {
                for j in 0 ..< n where (directed ? i != j : i < j) && (seed % 4 == 0 || Int.random(in: 0 ..< 4, using: &rng) > 0) {
                    ends.append((i, j))
                    if Int.random(in: 0 ..< 8, using: &rng) == 0 { ends.append((i, j)) }
                }
                if Int.random(in: 0 ..< 6, using: &rng) == 0 { ends.append((i, i)) }
            }
            ends.shuffle(using: &rng)
            let weight = ends.map { _ in Int.random(in: -2 ... span, using: &rng) }
            // The lightest copy of each pair (ordered pair), the earliest on ties; loops ignored.
            var lightest = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
            for k in ends.indices where ends[k].0 != ends[k].1 {
                let (a, b) = ends[k]
                if lightest[a][b] < 0 || weight[k] < weight[lightest[a][b]] {
                    lightest[a][b] = k
                    if !directed { lightest[b][a] = k }
                }
            }
            // JGraphT HeldKarpTSP: memo(prev, state) the least weight from prev through the vertices outside state
            // back to 0, by recursion; then from 0 the lowest next vertex whose cost matches exactly.
            var memo = [Int??](repeating: nil, count: n << n)
            func cost(_ prev: Int, _ state: Int) -> Int? {
                if let known = memo[prev << n | state] { return known }
                var best: Int? = nil
                if state == (1 << n) - 1 {
                    best = lightest[prev][0] >= 0 ? weight[lightest[prev][0]] : nil
                } else {
                    for i in 0 ..< n where state >> i & 1 == 0 && lightest[prev][i] >= 0 {
                        if let rest = cost(i, state | 1 << i), best == nil || weight[lightest[prev][i]] + rest < best! {
                            best = weight[lightest[prev][i]] + rest
                        }
                    }
                }
                memo[prev << n | state] = .some(best)
                return best
            }
            var expected: [Int]? = nil
            if let total = cost(0, 1) {
                var order = [0], state = 1, last = 0, remaining = total
                for _ in 1 ..< n {
                    let next = (1 ..< n).first { i in
                        state >> i & 1 == 0 && lightest[last][i] >= 0 && cost(i, state | 1 << i).map { $0 + weight[lightest[last][i]] == remaining } == true
                    }!
                    remaining = cost(next, state | 1 << next)!
                    order.append(next)
                    state |= 1 << next
                    last = next
                }
                expected = order
            }
            let context = "\(ends) weights \(weight) directed \(directed)"
            let tour: Cycle<Int, Int>?
            if directed {
                tour = DirectedPseudograph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) }).shortestTour(weight: { weight[$0] })
            } else {
                tour = Pseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) }).shortestTour(weight: { weight[$0] })
            }
            #expect(tour?.vertices == expected, "\(context)")
            if let tour, let expected {
                let lightestSteps = tour.edges == (0 ..< n).map { lightest[expected[$0]][expected[($0 + 1) % n]] }
                #expect(lightestSteps, "\(context)")
                let total = tour.weight({ weight[$0] })
                #expect(total == cost(0, 1), "\(context)")
            }
        }
    }
}
