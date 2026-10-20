// The degree-sequence tests and constructions, the later random families and the later named
// families. Graphicality is checked against Erdős–Gallai and Fulkerson–Chen–Anstee written out at
// every k, and a graphical sequence must be realized exactly by Havel–Hakimi (Kleitman–Wang). The
// random families are checked by their counts and structure (degrees of the configuration models,
// m(n − m) edges of Holme–Kim, the ring under Newman–Watts–Strogatz's shortcuts, connectivity,
// out-degree k), on every conformer of their kind with the same draws; the named families against
// models written out here. Parameters stray outside the documented ranges, and such calls are not
// made.

import AdjacencyListModule
import AdjacencyMatrixModule
import BipartiteGraphs
import CompressedSparseRowModule
import FuzzSupport
import GraphProtocols
import Multigraphs
import NamedGraphs
import RandomGraphs
import StableGraphs
import Trees

func erdosGallai(_ degrees: [Int]) -> Bool {
    let n = degrees.count
    guard degrees.allSatisfy({ $0 >= 0 && $0 < n }), degrees.reduce(0, +) % 2 == 0 else { return false }
    let d = degrees.sorted(by: >)
    for k in 1 ... max(n, 1) where k <= n {
        let left = d[..<k].reduce(0, +)
        let right = k * (k - 1) + d[k...].reduce(0) { $0 + min($1, k) }
        if left > right { return false }
    }
    return true
}

func fulkersonChenAnstee(_ ins: [Int], _ outs: [Int]) -> Bool {
    let n = ins.count
    guard (ins + outs).allSatisfy({ $0 >= 0 && $0 < n }), ins.reduce(0, +) == outs.reduce(0, +) else { return false }
    let pairs = zip(outs, ins).sorted { $0.0 != $1.0 ? $0.0 > $1.0 : $0.1 > $1.1 }
    for k in 1 ... max(n, 1) where k <= n {
        let left = pairs[..<k].reduce(0) { $0 + $1.0 }
        let right = pairs[..<k].reduce(0) { $0 + min($1.1, k - 1) } + pairs[k...].reduce(0) { $0 + min($1.1, k) }
        if left > right { return false }
    }
    return true
}

func undirectedDegrees(_ edges: [[Int]], _ n: Int) -> [Int] {
    var d = [Int](repeating: 0, count: n)
    for e in edges {
        d[e[0]] += 1
        d[e[1]] += 1
    }
    return d
}

func degreeSequences(_ input: inout FuzzInput) {
    let n = input.int(in: 0 ... 12)
    let degrees = (0 ..< n).map { _ in input.int(in: -1 ... 12) }
    let graphical = isGraphical(degrees)
    check(graphical == erdosGallai(degrees), "isGraphical(\(degrees)) is \(graphical)")
    if graphical {
        let reference = checkedUndirected(UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: degrees), "havelHakimi")
        check(undirectedDegrees(reference, n) == degrees, "havelHakimi(\(degrees)) has other degrees")
        check(checkedUndirected(Pseudograph<Int>.havelHakimi(degreeSequence: degrees), "Pseudograph") == reference
            && checkedUndirected(Multigraph<Int>.havelHakimi(degreeSequence: degrees), "Multigraph") == reference,
              "havelHakimi conformers disagree on \(degrees)")
    }
    let ins = (0 ..< n).map { _ in input.int(in: -1 ... 12) }
    let outs = (0 ..< n).map { _ in input.int(in: -1 ... 12) }
    let digraphical = isDigraphical(inDegrees: ins, outDegrees: outs)
    check(digraphical == fulkersonChenAnstee(ins, outs), "isDigraphical(\(ins), \(outs)) is \(digraphical)")
    if digraphical {
        let reference = checkedDirected(CompressedSparseRow.havelHakimi(inDegrees: ins, outDegrees: outs), "Kleitman–Wang")
        var builtIns = [Int](repeating: 0, count: n), builtOuts = [Int](repeating: 0, count: n)
        for e in reference {
            builtOuts[e[0]] += 1
            builtIns[e[1]] += 1
        }
        check(builtIns == ins && builtOuts == outs, "Kleitman–Wang(\(ins), \(outs)) has other degrees")
        for other in [checkedDirected(AdjacencyMatrix.havelHakimi(inDegrees: ins, outDegrees: outs), "AdjacencyMatrix"),
                      checkedDirected(StableDirectedGraph<Int>.havelHakimi(inDegrees: ins, outDegrees: outs), "StableDirectedGraph")] {
            check(other == reference, "Kleitman–Wang conformers disagree on \(ins), \(outs)")
        }
    }
}

func randomFamilies(_ input: inout FuzzInput, seed: UInt64) {
    let fresh = Xoshiro256StarStar(seed: seed)
    switch input.int(below: 10) {
    case 9:
        // Stochastic Kronecker: the same draws replayed by hand, undirected and directed.
        let base = input.int(in: 1 ... 3), k = input.int(in: 0 ... 3)
        let initiator = (0 ..< base).map { _ in (0 ..< base).map { _ in Double(input.int(in: 0 ... 4)) / 4 } }
        var g = fresh
        let edges = checkedUndirected(UndirectedAdjacencyList<Int>.stochasticKronecker(initiator: initiator, iterations: k, using: &g), "stochasticKronecker")
        var replay = fresh
        var n = 1
        for _ in 0 ..< k { n *= base }
        var expected: [[Int]] = []
        for u in 0 ..< n {
            for v in u + 1 ..< n {
                var p = 1.0, a = u, b = v
                for _ in 0 ..< k { p *= initiator[a % base][b % base]; a /= base; b /= base }
                if Double(replay.next() >> 11) * 0x1p-53 < p { expected.append([u, v]) }
            }
        }
        check(edges == expected && g == replay, "stochasticKronecker \(initiator) \(k)")
        var h = fresh
        let arcs = checkedDirected(CompressedSparseRow.stochasticKronecker(initiator: initiator, iterations: k, using: &h), "stochasticKronecker")
        check(arcs.allSatisfy { $0[0] != $0[1] } && arcs == arcs.sorted { $0.lexicographicallyPrecedes($1) }, "stochasticKronecker directed")
    case 8:
        // Duplication–divergence: the seed edge, an older neighbor for every later vertex, no loops,
        // the directed form with the same draws.
        let n = input.int(in: 2 ... 40), p = Double(input.int(in: 1 ... 10)) / 10
        var g = fresh
        let edges = checkedUndirected(UndirectedAdjacencyList<Int>.duplicationDivergence(vertexCount: n, retentionProbability: p, using: &g), "duplicationDivergence")
        check(edges.first == [0, 1] && edges.allSatisfy { $0[0] != $0[1] }, "duplicationDivergence start \(edges.prefix(2))")
        check((2 ..< n).allSatisfy { v in edges.contains { $0[1] == v && $0[0] < v } }, "duplicationDivergence: a vertex without an older neighbor")
        var h = fresh
        let arcs = checkedDirected(CompressedSparseRow.duplicationDivergence(vertexCount: n, retentionProbability: p, using: &h), "duplicationDivergence")
        check(arcs == edges.map { [$0[1], $0[0]] }.sorted { $0.lexicographicallyPrecedes($1) } && g == h, "duplicationDivergence directed")
    case 0:
        // The configuration models: every degree exactly.
        let degrees = (0 ..< input.int(in: 0 ... 12)).map { _ in input.int(in: 0 ... 5) }
        guard degrees.reduce(0, +) % 2 == 0 else { return }
        var g = fresh
        let graph = Pseudograph<Int>.configurationModel(degreeSequence: degrees, using: &g)
        check((0 ..< degrees.count).map { graph.degree(of: $0) } == degrees, "configurationModel degrees \(degrees)")
        let outs = (0 ..< degrees.count).map { _ in input.int(in: 0 ... 3) }
        var ins = [Int](repeating: 0, count: outs.count)
        for (k, d) in outs.enumerated() where !ins.isEmpty { ins[(k * 7 + d) % ins.count] += d }
        var h = fresh
        let directed = DirectedPseudograph<Int>.configurationModel(inDegrees: ins, outDegrees: outs, using: &h)
        var builtIns = [Int](repeating: 0, count: ins.count)
        for e in directed.edges { builtIns[e.target] += 1 }
        check(builtIns == ins && (0 ..< outs.count).map { directed.outDegree(of: $0) } == outs, "directed configurationModel degrees")
    case 1:
        // Chung–Lu: simple, the same on every conformer; directed, both arcs.
        let weights = (0 ..< input.int(in: 0 ... 14)).map { _ in Double(input.int(in: 0 ... 16)) / 2 }
        var g = fresh, h = fresh
        let edges = checkedUndirected(UndirectedAdjacencyList<Int>.chungLu(expectedDegrees: weights, using: &g), "chungLu")
        check(checkedUndirected(Multigraph<Int>.chungLu(expectedDegrees: weights, using: &h), "Multigraph") == edges && g == h, "chungLu conformers")
        var d = fresh
        let arcs = checkedDirected(CompressedSparseRow.chungLu(expectedDegrees: weights, using: &d), "chungLu directed")
        check(arcs == edges.flatMap { [$0, [$0[1], $0[0]]] }.sorted { $0.lexicographicallyPrecedes($1) } && d == g, "chungLu directed")
    case 2:
        // Holme–Kim: m(n − m) edges, m older neighbors for each later vertex.
        let n = input.int(in: 0 ... 20), m = input.int(in: 0 ... 5), p = probability(&input)
        guard m >= 1, m <= n, p >= 0, p <= 1 else { return }
        var g = fresh
        let edges = checkedUndirected(UndirectedAdjacencyList<Int>.holmeKim(vertexCount: n, edgesPerVertex: m, triangleProbability: p, using: &g), "holmeKim")
        check(edges.count == m * (n - m), "holmeKim: \(edges.count) edges")
        var older = [Int](repeating: 0, count: n)
        for e in edges { older[e[1]] += 1 }
        check((0 ..< n).allSatisfy { older[$0] == ($0 < m ? 0 : m) }, "holmeKim older neighbors")
        var h = fresh
        let arcs = checkedDirected(AdjacencyList<Int>.holmeKim(vertexCount: n, edgesPerVertex: m, triangleProbability: p, using: &h), "holmeKim directed")
        check(Set(arcs) == Set(edges.map { [$0[1], $0[0]] }) && g == h, "holmeKim directed is not newer → older")
    case 3:
        // Newman–Watts–Strogatz: the ring kept; connected Watts–Strogatz: connected or nil.
        let n = input.int(in: 0 ... 16), k = input.int(in: 0 ... 8), p = probability(&input), tries = input.int(in: 0 ... 3)
        guard k % 2 == 0, k <= n, p >= 0, p <= 1 else { return }
        var g = fresh
        let edges = Set(checkedUndirected(UndirectedAdjacencyList<Int>.newmanWattsStrogatz(
            vertexCount: n, nearestNeighborCount: k, shortcutProbability: p, using: &g), "newmanWattsStrogatz"))
        if k < n {
            for u in 0 ..< n {
                for j in 1 ..< max(k / 2 + 1, 1) where k > 0 {
                    let v = (u + j) % n
                    check(edges.contains([min(u, v), max(u, v)]), "newmanWattsStrogatz lost ring edge \(u)–\(v)")
                }
            }
        }
        guard n >= 1 else { return }
        var h = fresh
        if let graph = UndirectedAdjacencyList<Int>.connectedWattsStrogatz(vertexCount: n, nearestNeighborCount: k, rewiringProbability: p, tries: tries, using: &h) {
            var seen: Set<Int> = [0], stack = [0]
            while let v = stack.popLast() {
                for w in graph.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
            }
            check(seen.count == n, "connectedWattsStrogatz is not connected")
        }
    case 4:
        // Random k-out: out-degree k; undirected, the arcs' pairs.
        let n = input.int(in: 0 ... 40), k = input.int(in: -1 ... 8)
        guard k >= 0, k <= max(n - 1, 0) else { return }
        var g = fresh, h = fresh
        let arcs = checkedDirected(CompressedSparseRow.randomKOut(vertexCount: n, outDegree: k, using: &g), "randomKOut")
        check(arcs.count == n * k, "randomKOut arc count")
        let pairs = checkedUndirected(UndirectedAdjacencyList<Int>.randomKOut(vertexCount: n, outDegree: k, using: &h), "randomKOut undirected")
        check(Set(pairs) == Set(arcs.map { [min($0[0], $0[1]), max($0[0], $0[1])] }) && g == h, "randomKOut undirected")
    case 5:
        // Directed scale-free: n vertices from the 3-cycle.
        let n = input.int(in: 3 ... 40)
        let weights = (0 ..< 3).map { _ in Double(input.int(in: 1 ... 8)) }
        let total = weights.reduce(0, +)
        var g = fresh
        let graph = DirectedPseudograph<Int>.scaleFree(
            vertexCount: n, alpha: weights[0] / total, beta: weights[1] / total, gamma: 1 - weights[0] / total - weights[1] / total,
            deltaIn: Double(input.int(in: 0 ... 4)) / 4, deltaOut: Double(input.int(in: 0 ... 4)) / 4, using: &g)
        check(graph.vertexCount == n && Array(graph.edges.prefix(3)) == [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)],
              "scaleFree start")
    default:
        // G(a, b, m): m edges across the sides, the same with the sides.
        let a = input.int(in: 0 ... 7), b = input.int(in: 0 ... 7), m = input.int(in: 0 ... 50)
        guard m <= a * b else { return }
        var g = fresh, h = fresh
        let edges = checkedUndirected(UndirectedAdjacencyList<Int>.randomBipartite(leftCount: a, rightCount: b, edgeCount: m, using: &g), "G(a, b, m)")
        check(edges.count == m && edges.allSatisfy { $0[0] < a && $0[1] >= a }, "G(a, b, m) edges")
        let sided = BipartiteGraph<Int>.randomBipartite(leftCount: a, rightCount: b, edgeCount: m, using: &h)
        check(checkedUndirected(sided, "BipartiteGraph") == edges && g == h, "G(a, b, m) with sides")
        var d = fresh
        let arcs = checkedDirected(CompressedSparseRow.randomBipartite(leftCount: a, rightCount: b, edgeCount: m, using: &d), "G(a, b, m) directed")
        check(arcs.count == m && arcs.allSatisfy { ($0[0] < a) != ($0[1] < a) }, "G(a, b, m) directed arcs")
    }
}

func namedFamilies(_ input: inout FuzzInput) {
    let sortedPairs: ([[Int]]) -> [[Int]] = { Array(Set($0.map { [min($0[0], $0[1]), max($0[0], $0[1])] })).sorted { $0.lexicographicallyPrecedes($1) } }
    func both(_ name: String, _ model: [[Int]], _ u: UndirectedAdjacencyList<Int>, _ d: CompressedSparseRow) {
        check(checkedUndirected(u, name) == model, "\(name): \(u.edges.map { [$0.u, $0.v] }) is not the model \(model)")
        let arcs = model.flatMap { [$0, [$0[1], $0[0]]] }.sorted { $0.lexicographicallyPrecedes($1) }
        check(checkedDirected(d, name) == arcs, "\(name) directed is not both arcs")
    }
    switch input.int(below: 8) {
    case 0:
        let n = input.int(in: 0 ... 14)
        let offsets = (0 ..< input.int(in: 0 ... 3)).map { _ in input.int(in: -14 ... 14) }
        guard n >= 1, offsets.allSatisfy({ ($0 % n + n) % n != 0 }) else { return }
        let model = sortedPairs((0 ..< n).flatMap { i in offsets.map { [i, (($0 + i) % n + n) % n] } })
        both("circulant", model, .circulant(vertexCount: n, offsets: offsets), .circulant(vertexCount: n, offsets: offsets))
    case 1:
        let n = input.int(in: 1 ... 14), k = input.int(in: 0 ... 7)
        guard n >= 3, k >= 1, 2 * k < n else { return }
        let model = sortedPairs((0 ..< n).flatMap { i in [[i, (i + 1) % n], [i, n + i], [n + i, n + (i + k) % n]] })
        both("generalizedPetersen", model, .generalizedPetersen(outerCycleLength: n, step: k), .generalizedPetersen(outerCycleLength: n, step: k))
    case 2:
        let n = input.int(in: 0 ... 8), k = input.int(in: 0 ... 8)
        guard k >= 1, k <= n else { return }
        var subsets: [Int] = []
        for mask in 0 ..< 1 << n where mask.nonzeroBitCount == k { subsets.append(mask) }
        // Lexicographic order of the subsets as sorted lists.
        subsets.sort { a, b in
            let x = (0 ..< n).filter { a >> $0 & 1 == 1 }, y = (0 ..< n).filter { b >> $0 & 1 == 1 }
            return x.lexicographicallyPrecedes(y)
        }
        var model: [[Int]] = []
        for i in subsets.indices { for j in i + 1 ..< max(subsets.count, i + 1) where subsets[i] & subsets[j] == 0 { model.append([i, j]) } }
        both("kneser", model, .kneser(setSize: n, subsetSize: k), .kneser(setSize: n, subsetSize: k))
    case 3:
        let c = input.int(in: 1 ... 5), k = input.int(in: 1 ... 5)
        guard c >= 2, k >= 2 else { return }
        var model = (1 ..< 1 + c * (k - 1)).map { [0, $0] }
        for j in 0 ..< c {
            let s = 1 + j * (k - 1)
            for u in s ..< s + k - 1 { for v in u + 1 ..< s + k - 1 { model.append([u, v]) } }
        }
        both("windmill", model, .windmill(cliqueCount: c, cliqueVertexCount: k), .windmill(cliqueCount: c, cliqueVertexCount: k))
    case 4:
        let k = input.int(in: 0 ... 7), r = input.int(in: 1 ... 4), n = input.int(in: 0 ... 40)
        let binomial = sortedPairs((1 ..< max(1 << k, 1)).map { [$0 & ($0 - 1), $0] })
        check(checkedUndirected(UndirectedAdjacencyList<Int>.binomialTree(order: k), "binomialTree") == binomial, "binomialTree \(k)")
        check(checkedDirected(CompressedSparseRow.binomialTree(order: k), "binomialTree") == binomial, "binomialTree directed \(k)")
        check(checkedUndirected(Tree<Int>.binomialTree(order: k), "Tree.binomialTree") == binomial, "Tree.binomialTree \(k)")
        let rary = (1 ..< max(n, 1)).map { [($0 - 1) / r, $0] }
        check(checkedUndirected(UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: r, vertexCount: n), "fullRaryTree") == rary, "fullRaryTree")
        check(checkedDirected(StableDirectedGraph<Int>.fullRaryTree(branchingFactor: r, vertexCount: n), "fullRaryTree") == rary, "fullRaryTree directed")
    case 5:
        // Lattices by Euler's formula and their degree bounds; LCF against its definition.
        let rows = input.int(in: 0 ... 6), columns = input.int(in: 0 ... 8)
        let triangular = checkedUndirected(UndirectedAdjacencyList<Int>.triangularLattice(rowCount: rows, columnCount: columns), "triangularLattice")
        let hexagonal = checkedUndirected(UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: rows, columnCount: columns), "hexagonalLattice")
        if rows > 0, columns > 0 {
            let tn = UndirectedAdjacencyList<Int>.triangularLattice(rowCount: rows, columnCount: columns).vertexCount
            let hn = (columns + 1) * (2 * rows + 2) - 2
            check(triangular.count == tn + rows * columns - 1, "triangularLattice: Euler")
            check(hexagonal.count == hn + rows * columns - 1 && undirectedDegrees(hexagonal, hn).allSatisfy { (2 ... 3).contains($0) }, "hexagonalLattice")
        } else {
            check(triangular.isEmpty && hexagonal.isEmpty, "lattice with no rows or columns")
        }
        let n = input.int(in: 1 ... 16), r = input.int(in: 0 ... 3)
        let shifts = (0 ..< input.int(in: 0 ... 4)).map { _ in input.int(in: -16 ... 16) }
        guard n >= 3, shifts.allSatisfy({ ($0 % n + n) % n != 0 }) else { return }
        var model = (0 ..< n).map { [$0, ($0 + 1) % n] }
        for i in 0 ..< shifts.count * r { model.append([i % n, ((i + shifts[i % shifts.count]) % n + n) % n]) }
        both("lcf", sortedPairs(model), .lcf(vertexCount: n, shifts: shifts, repeatCount: r), .lcf(vertexCount: n, shifts: shifts, repeatCount: r))
    case 6:
        // Expanders: Margulis–Gabber–Galil against its four steps, the chordal cycle against the
        // inverses, Paley against the squares and the tournament's one arc per pair.
        let n = input.int(in: 1 ... 9)
        var model: [[Int]] = []
        for x in 0 ..< n {
            for y in 0 ..< n {
                let v = x * n + y
                for (a, b) in [((x + 2 * y) % n, y), ((x + 2 * y + 1) % n, y), (x, (y + 2 * x) % n), (x, (y + 2 * x + 1) % n)] where a * n + b != v {
                    model.append([v, a * n + b])
                }
            }
        }
        both("margulisGabberGalil", sortedPairs(model), .margulisGabberGalil(side: n), .margulisGabberGalil(side: n))
        let primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
        let p = primes[input.int(below: primes.count)]
        model = (0 ..< p).filter { (($0 + 1) % p) != $0 }.map { [$0, ($0 + 1) % p] }
        for x in 1 ..< p {
            let inverse = (1 ..< p).first { x * $0 % p == 1 }!
            if inverse != x { model.append([x, inverse]) }
        }
        both("chordalCycle", sortedPairs(model), .chordalCycle(prime: p), .chordalCycle(prime: p))
        var square = [Bool](repeating: false, count: p)
        for x in 1 ..< p { square[x * x % p] = true }
        let arcs = (0 ..< p).flatMap { x in (0 ..< p).filter { square[(($0 - x) % p + p) % p] }.map { [x, $0] } }
        check(checkedDirected(CompressedSparseRow.paley(prime: p), "paley") == arcs, "paley(\(p)) directed")
        if p % 4 == 1 {
            both("paley", arcs.filter { $0[0] < $0[1] }, .paley(prime: p), .paley(prime: p))
        } else if p > 2 {
            check(arcs.count == p * (p - 1) / 2 && arcs.allSatisfy { !square[(($0[0] - $0[1]) % p + p) % p] }, "paley(\(p)) tournament")
        }
    default:
        // De Bruijn and Kautz graphs against their words.
        let m = input.int(in: 1 ... 3), length = input.int(in: 1 ... 4), s = input.int(in: 2 ... 4)
        var words: [[Int]] = [[]]
        for _ in 0 ..< length { words = words.flatMap { w in (0 ..< m).map { w + [$0] } } }
        var index: [[Int]: Int] = [:]
        for (i, w) in words.enumerated() { index[w] = i }
        let arcs = words.enumerated().flatMap { i, w in (0 ..< m).map { [i, index[Array(w.dropFirst()) + [$0]]!] } }.sorted { $0.lexicographicallyPrecedes($1) }
        let list = AdjacencyList<Int>.deBruijn(alphabetSize: m, wordLength: length)
        check(list.edges.map { [$0.source, $0.target] } == arcs, "deBruijn(\(m), \(length))")
        check(DirectedPseudograph<Int>.deBruijn(alphabetSize: m, wordLength: length).edges.map { [$0.source, $0.target] } == arcs, "deBruijn pseudograph")
        var kautzWords: [[Int]] = [[]]
        for _ in 0 ..< length { kautzWords = kautzWords.flatMap { w in (0 ..< s).compactMap { w.last == $0 ? nil : w + [$0] } } }
        index = [:]
        for (i, w) in kautzWords.enumerated() { index[w] = i }
        let kautzArcs = kautzWords.enumerated().flatMap { i, w in (0 ..< s).filter { $0 != w.last }.map { [i, index[Array(w.dropFirst()) + [$0]]!] } }
            .sorted { $0.lexicographicallyPrecedes($1) }
        check(checkedDirected(CompressedSparseRow.kautz(alphabetSize: s, wordLength: length), "kautz") == kautzArcs, "kautz(\(s), \(length))")
    }
}

func laterFamilies(_ input: inout FuzzInput, seed: UInt64) {
    switch input.int(below: 3) {
    case 0: degreeSequences(&input)
    case 1: randomFamilies(&input, seed: seed)
    default: namedFamilies(&input)
    }
}
