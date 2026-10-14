// Properties with shrinking (swift-property-based) of the circulant, generalized Petersen, Kneser,
// windmill, binomial and full r-ary tree, de Bruijn, Kautz, triangular and hexagonal lattice and LCF
// families, each over a range of sizes against its definition, written out in the test, and the
// named graphs against their invariants (regularity, girth, strong regularity, bipartiteness).
// Every property builds all the conformers of its kind and requires the same edges in the same
// order. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import Multigraphs
import NamedGraphs
import PropertyBased
import StableGraphs
import Testing
import Trees

@Suite("NamedGraphs lattices, words and named graphs, with shrinking", .tags(.randomized))
struct LatticeFamilyPropertyTests {
    @Test("circulant: i – (i ± o) mod n for each offset, each edge once, sorted; directed both arcs; every conformer alike")
    func circulant() async {
        await propertyCheck(count: 120, input: Gen.int(in: 1 ... 30), Gen.int(in: -40 ... 40).array(of: 0 ... 5)) { n, raw in
            let offsets = raw.filter { (($0 % n) + n) % n != 0 }
            var reference = Set<[Int]>()
            for i in 0 ..< n {
                for o in offsets {
                    let j = ((i + o) % n + n) % n
                    reference.insert([min(i, j), max(i, j)])
                }
            }
            let pairs = reference.sorted { $0.lexicographicallyPrecedes($1) }
            let undirected: [[[Int]]] = [UndirectedAdjacencyList<Int>.circulant(vertexCount: n, offsets: offsets).edges.map { [$0.u, $0.v] },
                                         Pseudograph<Int>.circulant(vertexCount: n, offsets: offsets).edges.map { [$0.u, $0.v] },
                                         Multigraph<Int>.circulant(vertexCount: n, offsets: offsets).edges.map { [$0.u, $0.v] }]
            #expect(undirected.allSatisfy { $0 == pairs }, "n \(n), offsets \(offsets)")
            let arcs = (pairs + pairs.map { [$0[1], $0[0]] }).sorted { $0.lexicographicallyPrecedes($1) }
            let directed: [[[Int]]] = [CompressedSparseRow.circulant(vertexCount: n, offsets: offsets).edges.map { [$0.source, $0.target] },
                                       AdjacencyMatrix.circulant(vertexCount: n, offsets: offsets).edges.map { [$0.source, $0.target] },
                                       StableDirectedGraph<Int>.circulant(vertexCount: n, offsets: offsets).edges.map { [$0.source, $0.target] }]
            #expect(directed.allSatisfy { $0 == arcs }, "n \(n), offsets \(offsets)")
            // Vertex-transitive: every vertex has the same degree.
            let graph = UndirectedAdjacencyList<Int>.circulant(vertexCount: n, offsets: offsets)
            let regular = (0 ..< n).allSatisfy { graph.degree(of: $0) == graph.degree(of: 0) }
            #expect(regular, "n \(n), offsets \(offsets)")
        }
    }

    @Test("generalizedPetersen: outer cycle, spokes, inner star polygon; cubic with 3n edges; GP(n, 1) is the prism, GP(5, 2) Petersen")
    func generalizedPetersen() async {
        await propertyCheck(count: 100, input: Gen.int(in: 3 ... 30), Gen.int(in: 1 ... 14)) { n, rawK in
            let k = (rawK - 1) % ((n - 1) / 2) + 1
            var reference = Set<[Int]>()
            for i in 0 ..< n {
                reference.insert([min(i, (i + 1) % n), max(i, (i + 1) % n)])
                reference.insert([i, n + i])
                let a = n + i, b = n + (i + k) % n
                reference.insert([min(a, b), max(a, b)])
            }
            let graph = UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: n, step: k)
            #expect(graph.edges.map { [$0.u, $0.v] } == reference.sorted { $0.lexicographicallyPrecedes($1) }, "GP(\(n), \(k))")
            let cubic = (0 ..< 2 * n).allSatisfy { graph.degree(of: $0) == 3 }
            #expect(cubic && graph.edgeCount == 3 * n, "GP(\(n), \(k))")
            let directed = CompressedSparseRow.generalizedPetersen(outerCycleLength: n, step: k)
            #expect(directed.edgeCount == 6 * n, "GP(\(n), \(k))")
            #expect(UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: n, step: 1) == .circularLadder(rungCount: n), "GP(\(n), 1)")
        }
        #expect(UndirectedAdjacencyList<Int>.generalizedPetersen(outerCycleLength: 5, step: 2) == .petersen())
        #expect(CompressedSparseRow.generalizedPetersen(outerCycleLength: 5, step: 2) == .petersen())
    }

    @Test("kneser: the k-subsets in lexicographic order, adjacent exactly when disjoint; C(n, k) vertices of degree C(n − k, k)")
    func kneser() async {
        await propertyCheck(count: 80, input: Gen.int(in: 1 ... 9), Gen.int(in: 1 ... 9)) { n, rawK in
            let k = min(rawK, n)
            // The k-subsets of 0..<n in lexicographic order, as bit masks.
            var subsets: [Int] = []
            func extend(_ start: Int, _ mask: Int, _ left: Int) {
                if left == 0 {
                    subsets.append(mask)
                    return
                }
                guard start < n else { return }
                for x in start ..< n { extend(x + 1, mask | 1 << x, left - 1) }
            }
            extend(0, 0, k)
            var pairs: [[Int]] = []
            for a in subsets.indices { for b in a + 1 ..< max(subsets.count, a + 1) where subsets[a] & subsets[b] == 0 { pairs.append([a, b]) } }
            let graphs: [any Graph<Int>] = [UndirectedAdjacencyList<Int>.kneser(setSize: n, subsetSize: k),
                                            Pseudograph<Int>.kneser(setSize: n, subsetSize: k),
                                            Multigraph<Int>.kneser(setSize: n, subsetSize: k)]
            for graph in graphs {
                #expect(graph.vertexCount == subsets.count && graph.edges.map { [$0.u, $0.v] } == pairs, "KG(\(n), \(k))")
            }
            let directed = AdjacencyList<Int>.kneser(setSize: n, subsetSize: k)
            #expect(directed.edgeCount == 2 * pairs.count, "KG(\(n), \(k))")
        }
    }

    @Test("windmill: c copies of K_k sharing hub 0; 1 + c(k − 1) vertices, c·k(k − 1)/2 edges")
    func windmill() async {
        await propertyCheck(count: 60, input: Gen.int(in: 2 ... 7), Gen.int(in: 2 ... 7)) { c, k in
            var pairs: [[Int]] = (1 ..< 1 + c * (k - 1)).map { [0, $0] }
            for j in 0 ..< c {
                let start = 1 + j * (k - 1)
                for u in start ..< start + k - 1 { for v in u + 1 ..< start + k - 1 { pairs.append([u, v]) } }
            }
            let graph = Multigraph<Int>.windmill(cliqueCount: c, cliqueVertexCount: k)
            #expect(graph.vertexCount == 1 + c * (k - 1) && graph.edges.map { [$0.u, $0.v] } == pairs, "Wd(\(k), \(c))")
            let directed = DirectedMultigraph<Int>.windmill(cliqueCount: c, cliqueVertexCount: k)
            #expect(directed.edgeCount == 2 * pairs.count && directed.outDegree(of: 0) == c * (k - 1), "Wd(\(k), \(c))")
        }
    }

    @Test("binomialTree: parent v & (v − 1); C(k, d) vertices at depth d; Tree.binomialTree the same edges")
    func binomialTree() async {
        await propertyCheck(count: 40, input: Gen.int(in: 0 ... 11)) { k in
            let n = 1 << k
            var pairs: [[Int]] = (1 ..< max(n, 1)).map { [$0 & ($0 - 1), $0] }
            pairs.sort { $0.lexicographicallyPrecedes($1) }
            let graph = UndirectedAdjacencyList<Int>.binomialTree(order: k)
            #expect(graph.vertexCount == n && graph.edges.map { [$0.u, $0.v] } == pairs, "B\(k)")
            #expect(graph.degree(of: 0) == k, "B\(k)")
            // Depth of v is its number of set bits: C(k, d) of them.
            var atDepth = [Int](repeating: 0, count: k + 1)
            for v in 0 ..< n { atDepth[v.nonzeroBitCount] += 1 }
            var binomial = [1]
            for d in 0 ..< k { binomial.append(binomial[d] * (k - d) / (d + 1)) }
            #expect(atDepth == binomial, "B\(k)")
            let tree = Tree<Int>.binomialTree(order: k)
            #expect(tree.edges.map { [$0.u, $0.v] } == pairs, "B\(k)")
            let directed = CompressedSparseRow.binomialTree(order: k)
            #expect(directed.edges.map { [$0.source, $0.target] } == pairs, "B\(k)")
        }
    }

    @Test("fullRaryTree: parent (c − 1)/r; with a full last level it is balancedTree; Tree.fullRaryTree the same edges")
    func fullRaryTree() async {
        await propertyCheck(count: 100, input: Gen.int(in: 1 ... 5), Gen.int(in: 0 ... 80)) { r, n in
            let pairs = (1 ..< max(n, 1)).map { [($0 - 1) / r, $0] }
            let graph = UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: r, vertexCount: n)
            #expect(graph.vertexCount == n && graph.edges.map { [$0.u, $0.v] } == pairs, "r \(r), n \(n)")
            let directed = StableDirectedGraph<Int>.fullRaryTree(branchingFactor: r, vertexCount: n)
            #expect(directed.edges.map { [$0.source, $0.target] } == pairs, "r \(r), n \(n)")
            if n >= 1 {
                let tree = Tree<Int>.fullRaryTree(branchingFactor: r, vertexCount: n)
                #expect(tree.edges.map { [$0.u, $0.v] } == pairs, "r \(r), n \(n)")
            }
            // A full last level: 1 + r + … + r^h vertices.
            for h in 0 ... 4 {
                var count = 0, level = 1
                for _ in 0 ... h {
                    count += level
                    level *= r
                }
                #expect(UndirectedAdjacencyList<Int>.fullRaryTree(branchingFactor: r, vertexCount: count)
                    == .balancedTree(branchingFactor: r, height: h), "r \(r), h \(h)")
            }
        }
    }

    @Test("deBruijn and kautz: each word to the words its last letters begin, numbered lexicographically; regular in and out")
    func wordGraphs() async {
        await propertyCheck(count: 60, input: Gen.int(in: 1 ... 4), Gen.int(in: 1 ... 4)) { m, length in
            // Every word of `length` letters over `letters`, in lexicographic order.
            func words(_ letters: Int, distinctNeighbors: Bool) -> [[Int]] {
                var all: [[Int]] = [[]]
                for _ in 0 ..< length {
                    all = all.flatMap { w in (0 ..< letters).compactMap { a in distinctNeighbors && w.last == a ? nil : w + [a] } }
                }
                return all
            }
            let bruijnWords = words(m, distinctNeighbors: false)
            var index: [[Int]: Int] = [:]
            for (i, w) in bruijnWords.enumerated() { index[w] = i }
            var arcs: [[Int]] = []
            for (i, w) in bruijnWords.enumerated() {
                for a in 0 ..< m { arcs.append([i, index[Array(w.dropFirst()) + [a]]!]) }
            }
            arcs.sort { $0.lexicographicallyPrecedes($1) }
            let list = AdjacencyList<Int>.deBruijn(alphabetSize: m, wordLength: length)
            let pseudograph = DirectedPseudograph<Int>.deBruijn(alphabetSize: m, wordLength: length)
            #expect(list.vertexCount == bruijnWords.count && list.edges.map { [$0.source, $0.target] } == arcs, "B(\(m), \(length))")
            #expect(pseudograph.edges.map { [$0.source, $0.target] } == arcs, "B(\(m), \(length))")
            // Built in bulk, the same graph as one insertion per arc: rows, predecessors and positions.
            let inserted = AdjacencyList(vertices: 0 ..< list.vertexCount, edges: list.edges)
            let insertedPseudograph = DirectedPseudograph(vertices: 0 ..< list.vertexCount, edges: list.edges)
            let rowsAgree = (0 ..< list.vertexCount).allSatisfy { v in
                Array(list.successors(of: v)) == Array(inserted.successors(of: v))
                    && Array(list.predecessors(of: v)) == Array(inserted.predecessors(of: v))
                    && Array(pseudograph.inEdges(of: v)) == Array(insertedPseudograph.inEdges(of: v))
                    && Array(pseudograph.outEdges(of: v)) == Array(insertedPseudograph.outEdges(of: v))
            }
            #expect(list == inserted && pseudograph == insertedPseudograph && rowsAgree, "B(\(m), \(length))")
            let loops = list.edges.filter { $0.source == $0.target }.count
            #expect(loops == m && list.contains(edge: DirectedEdge(from: 0, to: 0)), "B(\(m), \(length))")
            let s = m + 1
            let kautzWords = words(s, distinctNeighbors: true)
            index = [:]
            for (i, w) in kautzWords.enumerated() { index[w] = i }
            var kautzArcs: [[Int]] = []
            for (i, w) in kautzWords.enumerated() {
                for a in 0 ..< s where a != w.last { kautzArcs.append([i, index[Array(w.dropFirst()) + [a]]!]) }
            }
            kautzArcs.sort { $0.lexicographicallyPrecedes($1) }
            let kautz: [any DirectedGraph<Int>] = [CompressedSparseRow.kautz(alphabetSize: s, wordLength: length),
                                                   AdjacencyMatrix.kautz(alphabetSize: s, wordLength: length),
                                                   DirectedPseudograph<Int>.kautz(alphabetSize: s, wordLength: length)]
            for graph in kautz {
                #expect(graph.vertexCount == kautzWords.count && graph.edges.map { [$0.source, $0.target] } == kautzArcs, "K(\(s), \(length))")
            }
        }
    }

    @Test("triangular and hexagonal lattices: connected and planar, E = V + faces − 1; degrees ≤ 6 and in 2...3; the honeycomb 2-colourable")
    func lattices() async {
        await propertyCheck(count: 80, input: Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 9)) { m, n in
            func isConnected(_ graph: some Graph<Int>) -> Bool {
                guard graph.vertexCount > 0 else { return true }
                var seen: Set<Int> = [0], stack = [0]
                while let v = stack.popLast() {
                    for w in graph.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
                }
                return seen.count == graph.vertexCount
            }
            let triangular = UndirectedAdjacencyList<Int>.triangularLattice(rowCount: m, columnCount: n)
            let hexagonal = UndirectedAdjacencyList<Int>.hexagonalLattice(rowCount: m, columnCount: n)
            if m == 0 || n == 0 {
                #expect(triangular.vertexCount == 0 && hexagonal.vertexCount == 0)
                return
            }
            let columns = (n + 1) / 2
            let shortRows = n % 2 == 1 ? (m + 1) / 2 : 0
            #expect(triangular.vertexCount == (m + 1) * (columns + 1) - shortRows, "\(m) × \(n)")
            // Euler's formula: V − E + F = 2, with the m·n triangles and the outer face.
            #expect(triangular.edgeCount == triangular.vertexCount + m * n - 1, "\(m) × \(n)")
            let triangularDegrees = (0 ..< triangular.vertexCount).allSatisfy { (2 ... 6).contains(triangular.degree(of: $0)) }
            #expect(triangularDegrees && isConnected(triangular), "\(m) × \(n)")
            #expect(hexagonal.vertexCount == (n + 1) * (2 * m + 2) - 2, "\(m) × \(n)")
            #expect(hexagonal.edgeCount == hexagonal.vertexCount + m * n - 1, "\(m) × \(n)")
            let hexagonalDegrees = (0 ..< hexagonal.vertexCount).allSatisfy { (2 ... 3).contains(hexagonal.degree(of: $0)) }
            #expect(hexagonalDegrees && isConnected(hexagonal), "\(m) × \(n)")
            // Bipartite: a breadth-first 2-colouring never meets an edge within one colour.
            var colour = [Int](repeating: -1, count: hexagonal.vertexCount)
            colour[0] = 0
            var queue = [0], head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in hexagonal.neighbors(of: v) where colour[w] < 0 {
                    colour[w] = 1 - colour[v]
                    queue.append(w)
                }
            }
            let proper = hexagonal.edges.allSatisfy { colour[$0.u] != colour[$0.v] }
            #expect(proper, "\(m) × \(n)")
            for graph in [Pseudograph<Int>.triangularLattice(rowCount: m, columnCount: n).edges.map { [$0.u, $0.v] }] {
                #expect(graph == triangular.edges.map { [$0.u, $0.v] })
            }
            #expect(CompressedSparseRow.hexagonalLattice(rowCount: m, columnCount: n).edgeCount == 2 * hexagonal.edgeCount)
        }
    }

    @Test("lcf: the n-cycle and each chord i mod n – (i + s) mod n, each edge once, sorted")
    func lcf() async {
        await propertyCheck(count: 120, input: Gen.int(in: 3 ... 30), Gen.int(in: -30 ... 30).array(of: 0 ... 6), Gen.int(in: 0 ... 5)) { n, raw, r in
            let shifts = raw.filter { (($0 % n) + n) % n != 0 }
            var reference = Set<[Int]>()
            for i in 0 ..< n { reference.insert([min(i, (i + 1) % n), max(i, (i + 1) % n)]) }
            for i in 0 ..< shifts.count * r {
                let u = i % n, v = ((i + shifts[i % shifts.count]) % n + n) % n
                reference.insert([min(u, v), max(u, v)])
            }
            let pairs = reference.sorted { $0.lexicographicallyPrecedes($1) }
            let graph = UndirectedAdjacencyList<Int>.lcf(vertexCount: n, shifts: shifts, repeatCount: r)
            #expect(graph.edges.map { [$0.u, $0.v] } == pairs, "n \(n), \(shifts)^\(r)")
            let directed = AdjacencyList<Int>.lcf(vertexCount: n, shifts: shifts, repeatCount: r)
            #expect(directed.edgeCount == 2 * pairs.count, "n \(n), \(shifts)^\(r)")
        }
    }

    @Test("The named graphs: their orders, sizes, regularity, girth, bipartiteness, triangles and strong regularity")
    func namedGraphs() {
        func girth(_ graph: some Graph<Int>) -> Int {
            var best = Int.max
            for s in 0 ..< graph.vertexCount {
                var distance = [Int](repeating: -1, count: graph.vertexCount)
                var parent = [Int](repeating: -1, count: graph.vertexCount)
                distance[s] = 0
                var queue = [s], head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    for w in graph.neighbors(of: v) {
                        if distance[w] < 0 {
                            distance[w] = distance[v] + 1
                            parent[w] = v
                            queue.append(w)
                        } else if parent[v] != w {
                            best = min(best, distance[v] + distance[w] + 1)
                        }
                    }
                }
            }
            return best
        }
        func isBipartite(_ graph: some Graph<Int>) -> Bool {
            var colour = [Int](repeating: -1, count: graph.vertexCount)
            for s in 0 ..< graph.vertexCount where colour[s] < 0 {
                colour[s] = 0
                var stack = [s]
                while let v = stack.popLast() {
                    for w in graph.neighbors(of: v) {
                        if colour[w] < 0 {
                            colour[w] = 1 - colour[v]
                            stack.append(w)
                        } else if colour[w] == colour[v] {
                            return false
                        }
                    }
                }
            }
            return true
        }
        func degrees(_ graph: some Graph<Int>) -> Set<Int> { Set((0 ..< graph.vertexCount).map { graph.degree(of: $0) }) }
        typealias G = UndirectedAdjacencyList<Int>
        let cubic: [(String, G, Int, Int, Bool)] = [  // name, graph, n, girth, bipartite
            ("Heawood", .heawood(), 14, 6, true), ("Möbius–Kantor", .moebiusKantor(), 16, 6, true),
            ("Pappus", .pappus(), 18, 6, true), ("Desargues", .desargues(), 20, 6, true),
            ("dodecahedral", .dodecahedral(), 20, 5, false), ("Frucht", .frucht(), 12, 3, false), ("Tutte", .tutte(), 46, 4, false),
        ]
        for (name, graph, n, g, bipartite) in cubic {
            #expect(graph.vertexCount == n && graph.edgeCount == 3 * n / 2 && degrees(graph) == [3], "\(name)")
            #expect(girth(graph) == g && isBipartite(graph) == bipartite, "\(name)")
        }
        // Möbius–Kantor and Desargues are GP(8, 3) and GP(10, 3) up to numbering: same girth, size and
        // bipartiteness, checked above, and the same triangle-free cubic shape.
        let icosahedral = G.icosahedral()
        #expect(icosahedral.vertexCount == 12 && icosahedral.edgeCount == 30 && degrees(icosahedral) == [5] && girth(icosahedral) == 3)
        // Every edge of the icosahedron lies on exactly two triangles.
        let icosahedralTriangles = icosahedral.edges.allSatisfy { e in
            Set(icosahedral.neighbors(of: e.u)).intersection(icosahedral.neighbors(of: e.v)).count == 2
        }
        #expect(icosahedralTriangles)
        let chvatal = G.chvatal()
        #expect(chvatal.vertexCount == 12 && chvatal.edgeCount == 24 && degrees(chvatal) == [4] && girth(chvatal) == 4)
        // Hoffman–Singleton: strongly regular (50, 7, 0, 1), adjacent vertices share no neighbor and
        // non-adjacent ones exactly one.
        let hoffman = G.hoffmanSingleton()
        #expect(hoffman.vertexCount == 50 && hoffman.edgeCount == 175 && degrees(hoffman) == [7])
        var stronglyRegular = true
        for u in 0 ..< 50 {
            let near = Set(hoffman.neighbors(of: u))
            for v in u + 1 ..< 50 {
                let common = near.intersection(hoffman.neighbors(of: v)).count
                if common != (near.contains(v) ? 0 : 1) { stronglyRegular = false }
            }
        }
        #expect(stronglyRegular && girth(hoffman) == 5)
        // Both arcs on every directed conformer.
        let directed: [(String, any DirectedGraph<Int>, Int)] = [
            ("Heawood", CompressedSparseRow.heawood(), 42), ("Möbius–Kantor", AdjacencyMatrix.moebiusKantor(), 48),
            ("Pappus", AdjacencyList<Int>.pappus(), 54), ("Desargues", DirectedPseudograph<Int>.desargues(), 60),
            ("dodecahedral", DirectedMultigraph<Int>.dodecahedral(), 60), ("Frucht", StableDirectedGraph<Int>.frucht(), 36),
            ("icosahedral", CompressedSparseRow.icosahedral(), 60), ("Tutte", AdjacencyList<Int>.tutte(), 138),
            ("Chvátal", AdjacencyMatrix.chvatal(), 48), ("Hoffman–Singleton", StableDirectedGraph<Int>.hoffmanSingleton(), 350),
        ]
        for (name, graph, arcs) in directed {
            let symmetric = graph.edges.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.target, to: $0.source)) }
            #expect(graph.edgeCount == arcs && symmetric, "\(name)")
        }
        // The same edges on the other undirected conformers.
        #expect(Pseudograph<Int>.tutte().edges.map { [$0.u, $0.v] } == G.tutte().edges.map { [$0.u, $0.v] })
        #expect(Multigraph<Int>.hoffmanSingleton().edges.map { [$0.u, $0.v] } == hoffman.edges.map { [$0.u, $0.v] })
    }
}
