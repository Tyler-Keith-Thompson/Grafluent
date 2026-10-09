// §J: properties against brute force, with shrinking (swift-property-based): on a failure,
// PropertyBased shrinks the generated edge list (and the row-shuffling seed, towards 0, which keeps
// rows in position order) and prints the smallest input that still fails. Graphs are multigraphs
// with self-loops on the vertices 0..<6 (0..<4 for the exhaustive oracle), directed and undirected,
// with rows in position order or shuffled. Every oracle is written inside its test: a naive
// backtracking enumeration with api.md's order key computed per cycle, every ordered vertex subset
// times every choice of parallel edges, union–find components, a breadth-first forest built by
// hand, and Gaussian elimination over GF(2). Case IDs (CY-nnn) refer to the catalog; see README.md.

import Cycles
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Traversal
import Walks

/// An undirected multigraph on 0..<vertexCount whose incidence rows (built in position order, a
/// self-loop twice) are shuffled by a seeded generator, unless the seed is 0. Vertex and edge
/// indices are the vertices and positions themselves.
private struct ShuffledPseudograph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            rows[edge.u].append(k)
            rows[edge.v].append(k)
        }
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
        }
        self.vertices = Array(0 ..< vertexCount)
        self.edges = edges
        self.rows = rows
    }

    func incidentEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func neighbors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
}

/// A directed multigraph on 0..<vertexCount whose out-edge rows (built in position order) are
/// shuffled by a seeded generator, unless the seed is 0. Vertex indices are the vertices.
private struct ShuffledDigraph: DirectedGraph {
    let vertices: [Int]
    let edges: [DirectedEdge<Int>]
    private let rows: [[Int]]

    init(vertexCount: Int, edges: [DirectedEdge<Int>], seed: Int) {
        var rows = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() { rows[edge.source].append(k) }
        if seed != 0 {
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            rows = rows.map { $0.shuffled(using: &rng) }
        }
        self.vertices = Array(0 ..< vertexCount)
        self.edges = edges
        self.rows = rows
    }

    func outEdges(of vertex: Int) -> [Int] { rows[vertex] }
    func successors(of vertex: Int) -> [Int] { rows[vertex].map { edges[$0].target } }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
}

@Suite("Cycle properties against brute force, with shrinking", .tags(.randomized))
struct CyclePropertyTests {
    @Test("CY-750 CY-751 undirected simpleCycles() is a naive backtracking enumeration in content and order; each value a canonical Cycle of the graph, no two equal")
    func undirectedAgainstBacktracking() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = 6
            let graph = ShuffledPseudograph(vertexCount: n, edges: raw.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            let rows = (0 ..< n).map { graph.incidentEdges(of: $0) }
            // Every closed path from s through vertices above s, leaving s by its lesser edge,
            // keyed by (s, then each edge's offset in its vertex's row).
            var found: [[Int]: (key: [Int], vertices: [Int], edges: [Int])] = [:]
            for s in 0 ..< n {
                var pathVertices = [s]
                var pathEdges: [Int] = []
                func extend() {
                    let v = pathVertices[pathVertices.count - 1]
                    for e in rows[v] where !pathEdges.contains(e) {
                        let w = raw[e].0 == v ? raw[e].1 : raw[e].0
                        if w == s {
                            var cv = pathVertices
                            var ce = pathEdges + [e]
                            if ce.count >= 2 && ce[ce.count - 1] < ce[0] {
                                cv = [cv[0]] + cv[1...].reversed()
                                ce.reverse()
                            }
                            let key = [s] + zip(cv, ce).map { rows[$0.0].firstIndex(of: $0.1)! }
                            found[cv + [-1] + ce] = (key, cv, ce)
                        } else if w > s && !pathVertices.contains(w) {
                            pathVertices.append(w)
                            pathEdges.append(e)
                            extend()
                            pathVertices.removeLast()
                            pathEdges.removeLast()
                        }
                    }
                }
                extend()
            }
            let expected = found.values.sorted { $0.key.lexicographicallyPrecedes($1.key) }
            let cycles = Array(graph.simpleCycles())
            #expect(cycles.map(\.vertices) == expected.map(\.vertices))
            #expect(cycles.map(\.edges) == expected.map(\.edges))
            for cycle in cycles {
                #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil, "\(cycle.vertices) \(cycle.edges)")
                #expect(cycle.vertices[0] == cycle.vertices.min())
                if cycle.length >= 2 { #expect(cycle.edges[0] < cycle.edges[cycle.length - 1]) }
            }
            #expect(Set(cycles).count == cycles.count)
        }
    }

    @Test("CY-750 CY-751 directed simpleCycles() is a naive backtracking enumeration in content and order; each value a Cycle of the graph starting at its least vertex")
    func directedAgainstBacktracking() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = 6
            let graph = ShuffledDigraph(vertexCount: n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
            let rows = (0 ..< n).map { graph.outEdges(of: $0) }
            var found: [(key: [Int], vertices: [Int], edges: [Int])] = []
            for s in 0 ..< n {
                var pathVertices = [s]
                var pathEdges: [Int] = []
                func extend() {
                    let v = pathVertices[pathVertices.count - 1]
                    for e in rows[v] {
                        let w = raw[e].1
                        if w == s {
                            let ce = pathEdges + [e]
                            found.append(([s] + zip(pathVertices, ce).map { rows[$0.0].firstIndex(of: $0.1)! }, pathVertices, ce))
                        } else if w > s && !pathVertices.contains(w) {
                            pathVertices.append(w)
                            pathEdges.append(e)
                            extend()
                            pathVertices.removeLast()
                            pathEdges.removeLast()
                        }
                    }
                }
                extend()
            }
            let expected = found.sorted { $0.key.lexicographicallyPrecedes($1.key) }
            let cycles = Array(graph.simpleCycles())
            #expect(cycles.map(\.vertices) == expected.map(\.vertices))
            #expect(cycles.map(\.edges) == expected.map(\.edges))
            for cycle in cycles {
                #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil, "\(cycle.vertices) \(cycle.edges)")
                #expect(cycle.vertices[0] == cycle.vertices.min())
            }
            #expect(Set(cycles).count == cycles.count)
        }
    }

    @Test("CY-752 on 4 vertices the cycles are exactly every ordered vertex subset times every choice of parallel edges, canonicalized, directed and undirected")
    func everyOrderedSubset() async {
        let edges = zip(Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 3)).array(of: 0 ... 8)
        await propertyCheck(count: 300, input: edges) { raw in
            let n = 4
            for isDirected in [false, true] {
                // Every sequence of distinct vertices, every choice of an edge for each step
                // (closing step included), the edges distinct; rotated to the least vertex and,
                // undirected, oriented to leave it by the lesser edge.
                var expected = Set<[Int]>()
                func joining(_ a: Int, _ b: Int) -> [Int] {
                    raw.indices.filter { isDirected ? raw[$0] == (a, b) : (raw[$0] == (a, b) || raw[$0] == (b, a)) }
                }
                func sequences(_ prefix: [Int]) {
                    if !prefix.isEmpty {
                        var choices: [[Int]] = [[]]
                        for i in prefix.indices {
                            let options = joining(prefix[i], prefix[(i + 1) % prefix.count])
                            choices = choices.flatMap { c in options.map { c + [$0] } }
                        }
                        for es in choices where Set(es).count == es.count {
                            let r = prefix.firstIndex(of: prefix.min()!)!
                            var cv = Array(prefix[r...] + prefix[..<r])
                            var ce = Array(es[r...] + es[..<r])
                            if !isDirected && ce.count >= 2 && ce[ce.count - 1] < ce[0] {
                                cv = [cv[0]] + cv[1...].reversed()
                                ce.reverse()
                            }
                            expected.insert(cv + [-1] + ce)
                        }
                    }
                    for v in 0 ..< n where !prefix.contains(v) { sequences(prefix + [v]) }
                }
                sequences([])
                let emitted: [[Int]]
                if isDirected {
                    let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
                    emitted = graph.simpleCycles().map { $0.vertices + [-1] + $0.edges }
                } else {
                    let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
                    emitted = graph.simpleCycles().map { $0.vertices + [-1] + $0.edges }
                }
                #expect(Set(emitted) == expected, "directed: \(isDirected)")
                #expect(emitted.count == expected.count, "directed: \(isDirected)")
            }
        }
    }

    @Test("CY-753 simpleCycles(maxLength: k) is the unbounded sequence filtered to length <= k, in the same order, for every k in 0 ... n + 1")
    func boundIsAFilter() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 11)
        await propertyCheck(count: 200, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = 6
            let graph = ShuffledPseudograph(vertexCount: n, edges: raw.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            let digraph = ShuffledDigraph(vertexCount: n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
            let all = Array(graph.simpleCycles())
            let allDirected = Array(digraph.simpleCycles())
            for k in 0 ... n + 1 {
                let bounded = graph.simpleCycles(maxLength: k)
                #expect(bounded.maxLength == k)
                #expect(Array(bounded).map(\.edges) == all.filter { $0.length <= k }.map(\.edges), "k = \(k)")
                #expect(Array(bounded).map(\.vertices) == all.filter { $0.length <= k }.map(\.vertices), "k = \(k)")
                let boundedDirected = digraph.simpleCycles(maxLength: k)
                #expect(boundedDirected.maxLength == k)
                #expect(Array(boundedDirected).map(\.edges) == allDirected.filter { $0.length <= k }.map(\.edges), "k = \(k)")
                #expect(Array(boundedDirected).map(\.vertices) == allDirected.filter { $0.length <= k }.map(\.vertices), "k = \(k)")
            }
            #expect(graph.simpleCycles().maxLength == .max)
            #expect(digraph.simpleCycles().maxLength == .max)
        }
    }

    @Test("CY-754 collapsing edge identity gives NetworkX's cycles: vertex sequences up to rotation, and reversal when undirected")
    func collapsedToVertexSequences() async {
        // NetworkX's simple_cycles on a Multi(Di)Graph lists each vertex cycle once: a loop, a pair of
        // vertices joined twice (undirected) or both ways (directed), or a longer sequence of
        // adjacent distinct vertices. Brute force over every sequence of distinct vertices.
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: edges) { raw in
            let n = 5
            for isDirected in [false, true] {
                func normal(_ vs: [Int]) -> [Int] {
                    var candidates = [vs]
                    if !isDirected { candidates.append(vs.reversed()) }
                    var best: [Int]?
                    for c in candidates {
                        for r in c.indices {
                            let rotated = Array(c[r...] + c[..<r])
                            if best == nil || rotated.lexicographicallyPrecedes(best!) { best = rotated }
                        }
                    }
                    return best!
                }
                func count(_ a: Int, _ b: Int) -> Int {
                    raw.filter { isDirected ? $0 == (a, b) : ($0 == (a, b) || $0 == (b, a)) }.count
                }
                var expected = Set<[Int]>()
                func sequences(_ prefix: [Int]) {
                    let k = prefix.count
                    if k == 1 && count(prefix[0], prefix[0]) >= 1 { expected.insert(prefix) }
                    if k == 2 && (isDirected ? count(prefix[0], prefix[1]) >= 1 && count(prefix[1], prefix[0]) >= 1 : count(prefix[0], prefix[1]) >= 2) {
                        expected.insert(normal(prefix))
                    }
                    if k >= 3 && (0 ..< k).allSatisfy({ count(prefix[$0], prefix[($0 + 1) % k]) >= 1 }) {
                        expected.insert(normal(prefix))
                    }
                    for v in 0 ..< n where !prefix.contains(v) { sequences(prefix + [v]) }
                }
                sequences([])
                let emitted: [[Int]]
                if isDirected {
                    emitted = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) }).simpleCycles().map(\.vertices)
                } else {
                    emitted = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) }).simpleCycles().map(\.vertices)
                }
                #expect(Set(emitted.map { normal($0) }) == expected, "directed: \(isDirected)")
            }
        }
    }

    @Test("CY-756 isAcyclic, findCycle() == nil, cycleBasis().isEmpty, an empty simpleCycles() and m == n − c agree; findCycle() is a canonical Cycle of the graph")
    func acyclicityAgrees() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 8)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = 6
            let graph = ShuffledPseudograph(vertexCount: n, edges: raw.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (u, v) in raw {
                let (ru, rv) = (find(u), find(v))
                if ru != rv { parent[ru] = rv }
            }
            let components = (0 ..< n).filter { find($0) == $0 }.count
            let forest = raw.count == n - components
            #expect(graph.isAcyclic == forest)
            #expect((graph.findCycle() == nil) == forest)
            #expect(graph.cycleBasis().isEmpty == forest)
            var iterator = graph.simpleCycles().makeIterator()
            #expect((iterator.next() == nil) == forest)
            #expect((graph.girth() == nil) == forest)
            if let cycle = graph.findCycle() {
                #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
                #expect(cycle.vertices[0] == cycle.vertices.min())
                if cycle.length >= 2 { #expect(cycle.edges[0] < cycle.edges[cycle.length - 1]) }
                #expect(Array(graph.simpleCycles()).contains(cycle))
            }
        }
    }

    @Test("CY-756 directed: Traversal's findCycle() and isAcyclic agree with simpleCycles(), and its cycle is one of them up to rotation")
    func directedAcyclicityAgrees() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let graph = ShuffledDigraph(vertexCount: 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
            let cycles = Array(graph.simpleCycles())
            #expect(graph.isAcyclic == cycles.isEmpty)
            #expect((graph.findCycle() == nil) == cycles.isEmpty)
            #expect((graph.girth() == nil) == cycles.isEmpty)
            if let cycle = graph.findCycle() {
                // Traversal starts at the back edge's target; Cycle's == is up to rotation.
                #expect(cycles.contains(cycle), "\(cycle.vertices) \(cycle.edges)")
            }
        }
    }

    @Test("CY-757 cycleBasis() is the fundamental basis of the breadth-first forest: m − n + c cycles, each its non-tree edge plus the tree path, independent over GF(2), spanning every simple cycle")
    func fundamentalBasis() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let n = 6
            let graph = ShuffledPseudograph(vertexCount: n, edges: raw.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            // The breadth-first forest: roots in vertices order, rows in incidence order, each
            // vertex's tree edge the one that discovered it.
            var parentEdge = [Int?](repeating: nil, count: n)
            var parentVertex = [Int?](repeating: nil, count: n)
            var discovered = [Bool](repeating: false, count: n)
            var components = 0
            for root in 0 ..< n where !discovered[root] {
                components += 1
                discovered[root] = true
                var queue = [root]
                var head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    for e in graph.incidentEdges(of: v) {
                        let w = raw[e].0 == v ? raw[e].1 : raw[e].0
                        if !discovered[w] {
                            discovered[w] = true
                            parentEdge[w] = e
                            parentVertex[w] = v
                            queue.append(w)
                        }
                    }
                }
            }
            let treeEdges = Set(parentEdge.compactMap { $0 })
            let nonTree = raw.indices.filter { !treeEdges.contains($0) }
            func pathToRoot(_ v: Int) -> [Int] {
                var edges: [Int] = []
                var x = v
                while let e = parentEdge[x] {
                    edges.append(e)
                    x = parentVertex[x]!
                }
                return edges
            }
            let basis = graph.cycleBasis()
            #expect(basis.count == raw.count - n + components)
            #expect(basis.count == nonTree.count)
            for (cycle, e) in zip(basis, nonTree) {
                // The tree path between the ends is the symmetric difference of their root paths.
                let path = Set(pathToRoot(raw[e].0)).symmetricDifference(Set(pathToRoot(raw[e].1)))
                #expect(Set(cycle.edges) == path.union([e]), "edge \(e)")
                #expect(cycle.edges.count == path.count + 1)
                #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
                #expect(cycle.vertices[0] == cycle.vertices.min())
                if cycle.length >= 2 { #expect(cycle.edges[0] < cycle.edges[cycle.length - 1]) }
            }
            // GF(2): edge sets as bit masks, reduced against a basis kept by leading bit.
            func mask(_ edges: [Int]) -> UInt64 { edges.reduce(0) { $0 | (1 << UInt64($1)) } }
            var pivots: [Int: UInt64] = [:]
            func reduce(_ x: UInt64) -> UInt64 {
                var x = x
                while x != 0, let p = pivots[63 - x.leadingZeroBitCount] { x ^= p }
                return x
            }
            for cycle in basis {
                let r = reduce(mask(cycle.edges))
                #expect(r != 0, "dependent: \(cycle.edges)")
                if r != 0 { pivots[63 - r.leadingZeroBitCount] = r }
            }
            for cycle in graph.simpleCycles() {
                #expect(reduce(mask(cycle.edges)) == 0, "not spanned: \(cycle.edges)")
            }
        }
    }

    @Test("CY-758 girth() is the least length of a simple cycle, nil when there is none, directed and undirected")
    func girthIsTheShortestCycle() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 0 ... 1_000_000)) { raw, seed in
            let graph = ShuffledPseudograph(vertexCount: 6, edges: raw.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            #expect(graph.girth() == graph.simpleCycles().map(\.length).min())
            let digraph = ShuffledDigraph(vertexCount: 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
            #expect(digraph.girth() == digraph.simpleCycles().map(\.length).min())
        }
    }

    @Test("CY-759 g.directed has 2 cycles per undirected cycle of length >= 2, a digon per non-loop edge and two loops per loop")
    func directedViewCount() async {
        let edges = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 9)
        await propertyCheck(count: 300, input: edges) { raw in
            let graph = ReferencePseudograph(vertices: 0 ..< 5, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let cycles = Array(graph.simpleCycles())
            let longer = cycles.filter { $0.length >= 3 }.count
            let digons = cycles.filter { $0.length == 2 }.count
            let loops = raw.filter { $0.0 == $0.1 }.count
            let ones = cycles.filter { $0.length == 1 }.count
            #expect(ones == loops, "\(raw)")
            let expected = 2 * longer + 2 * digons + (raw.count - loops) + 2 * loops
            #expect(Array(graph.directed.simpleCycles()).count == expected)
        }
    }

    @Test("CY-760 the converse digraph's cycles are the reversed cycles: the same edge sets, the other direction")
    func converse() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges) { raw in
            let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            // Every arc flipped, at the same position.
            let converse = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: raw.map { DirectedEdge(from: $0.1, to: $0.0) })
            let cycles = Array(graph.simpleCycles())
            let conversed = Array(converse.simpleCycles())
            #expect(Set(conversed) == Set(cycles.map { $0.reversed() }))
            #expect(conversed.count == cycles.count)
            #expect(converse.girth() == graph.girth())
        }
    }

    @Test("CY-761 shuffling rows changes only the order: the same canonical cycles, girth, basis size and acyclicity")
    func shuffledRows() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 1_000_000)) { raw, seed in
            let inOrder = ReferencePseudograph(vertices: 0 ..< 6, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let shuffled = ShuffledPseudograph(vertexCount: 6, edges: raw.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            let a = Array(inOrder.simpleCycles())
            let b = Array(shuffled.simpleCycles())
            #expect(Set(a.map { $0.vertices + [-1] + $0.edges }) == Set(b.map { $0.vertices + [-1] + $0.edges }))
            #expect(a.count == b.count)
            #expect(inOrder.girth() == shuffled.girth())
            #expect(inOrder.cycleBasis().count == shuffled.cycleBasis().count)
            #expect(inOrder.isAcyclic == shuffled.isAcyclic)

            let directedInOrder = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let directedShuffled = ShuffledDigraph(vertexCount: 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) }, seed: seed)
            let c = Array(directedInOrder.simpleCycles())
            let d = Array(directedShuffled.simpleCycles())
            #expect(Set(c.map { $0.vertices + [-1] + $0.edges }) == Set(d.map { $0.vertices + [-1] + $0.edges }))
            #expect(c.count == d.count)
            #expect(directedInOrder.girth() == directedShuffled.girth())
        }
    }

    @Test("CY-762 relabelling maps cycles to cycles: new values keep everything, a new vertices order keeps the edge sets and moves only starts and order")
    func relabelling() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: edges, Gen.shuffled(Array(0 ..< 6))) { raw, permutation in
            let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let cycles = Array(graph.simpleCycles())
            // New values, same vertices order: the same cycles, mapped, in the same order.
            let renamed = ReferencePseudograph(vertices: (0 ..< 6).map { permutation[$0] + 10 }, edges: raw.map { UndirectedEdge(permutation[$0.0] + 10, permutation[$0.1] + 10) })
            let renamedCycles = Array(renamed.simpleCycles())
            #expect(renamedCycles.map(\.vertices) == cycles.map { $0.vertices.map { permutation[$0] + 10 } })
            #expect(renamedCycles.map(\.edges) == cycles.map(\.edges))
            #expect(renamed.girth() == graph.girth())
            #expect(renamed.cycleBasis().map(\.edges) == graph.cycleBasis().map(\.edges))
            // Same values, vertices listed in another order: a cycle is its edge set; each is
            // canonical for the new order.
            let reordered = ReferencePseudograph(vertices: permutation, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let reorderedCycles = Array(reordered.simpleCycles())
            #expect(Set(reorderedCycles.map { Set($0.edges) }) == Set(cycles.map { Set($0.edges) }))
            #expect(reorderedCycles.count == cycles.count)
            for cycle in reorderedCycles {
                let places = cycle.vertices.map { permutation.firstIndex(of: $0)! }
                #expect(places[0] == places.min())
                if cycle.length >= 2 { #expect(cycle.edges[0] < cycle.edges[cycle.length - 1]) }
            }
            #expect(reordered.girth() == graph.girth())
            #expect(reordered.cycleBasis().count == graph.cycleBasis().count)
        }
    }

    @Test("CY-763 iterating a sequence twice, or two iterators in turn, gives the same cycles: each makeIterator() starts over")
    func reiteration() async {
        let edges = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 12)
        await propertyCheck(count: 200, input: edges) { raw in
            let graph = ReferencePseudograph(vertices: 0 ..< 6, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let sequence = graph.simpleCycles()
            let first = Array(sequence)
            let second = Array(sequence)
            #expect(first.map(\.vertices) == second.map(\.vertices))
            #expect(first.map(\.edges) == second.map(\.edges))
            var a = sequence.makeIterator()
            var b = sequence.makeIterator()
            var interleaved: [(Cycle<Int, Int>?, Cycle<Int, Int>?)] = []
            for _ in 0 ... first.count { interleaved.append((a.next(), b.next())) }
            #expect(interleaved.map { $0.0?.edges } == first.map(\.edges) + [nil])
            #expect(interleaved.map { $0.1?.edges } == first.map(\.edges) + [nil])

            let digraph = ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let directed = digraph.simpleCycles(maxLength: 4)
            #expect(Array(directed).map(\.edges) == Array(directed).map(\.edges))
            #expect(Array(directed).map(\.vertices) == Array(directed).map(\.vertices))
        }
    }

    @Test("CY-764 findCycle(from:) is nil exactly when no component of a root has a cycle, and otherwise a cycle in those components")
    func findCycleFromRoots() async {
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 10)
        let roots = Gen.int(in: 0 ... 7).array(of: 0 ... 3)
        await propertyCheck(count: 300, input: edges, roots, Gen.int(in: 0 ... 1_000_000)) { raw, roots, seed in
            let n = 8
            let graph = ShuffledPseudograph(vertexCount: n, edges: raw.map { UndirectedEdge($0.0, $0.1) }, seed: seed)
            var parent = Array(0 ..< n)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (u, v) in raw {
                let (ru, rv) = (find(u), find(v))
                if ru != rv { parent[ru] = rv }
            }
            // A component holds a cycle exactly when it has at least as many edges as vertices.
            let searched = Set(roots.map { find($0) })
            let cyclic = searched.contains { c in
                raw.filter { find($0.0) == c }.count >= (0 ..< n).filter { find($0) == c }.count
            }
            let cycle = graph.findCycle(from: roots)
            #expect((cycle != nil) == cyclic)
            if let cycle {
                #expect(cycle.vertices.allSatisfy { searched.contains(find($0)) })
                #expect(Cycle(vertices: cycle.vertices, edges: cycle.edges, in: graph) != nil)
                #expect(cycle.vertices[0] == cycle.vertices.min())
                if cycle.length >= 2 { #expect(cycle.edges[0] < cycle.edges[cycle.length - 1]) }
            }
            #expect(graph.findCycle(from: []) == nil)
            #expect((graph.findCycle(from: 0 ..< n) == nil) == (graph.findCycle() == nil))
        }
    }
}
