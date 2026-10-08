// Properties on seeded random graphs: n ∈ {0, 1, 2, 5, 10, 40}, p ∈ {0.05, 0.2, 0.5}, self-loops
// allowed, five graphs per cell per seed (fifty per cell over the ten seeds), each built as an
// adjacency list, a matrix, CSR, a Multigraph with random repeated edges, and a conformer without
// vertex indices. Every oracle (reachability, Kosaraju, union–find, brute-force dominators,
// Cooper–Harvey–Kennedy, Cytron's frontier definition) is written inside its test. Case IDs
// (CN-nn) refer to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

/// Supplies only what DirectedGraph requires: no vertex indices, so algorithms use dictionaries.
private struct DictionaryGraph<Vertex: Hashable>: DirectedGraph {
    let vertices: [Vertex]
    let edges: [DirectedEdge<Vertex>]
    func successors(of vertex: Vertex) -> [Vertex] { edges.filter { $0.source == vertex }.map(\.target) }
    func outEdges(of vertex: Vertex) -> [Int] { edges.indices.filter { edges[$0].source == vertex } }
    func contains(_ vertex: Vertex) -> Bool { vertices.contains(vertex) }
}

@Suite("Connectivity properties on random graphs", .tags(.randomized))
struct ConnectivityPropertyTests {
    @Test("CN-114 – CN-118 / CN-48 strong components partition the vertices, match mutual reachability, are reverse topological, survive reversal and agree with Kosaraju", arguments: 1 ... 10)
    func strongComponents(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        for n in [0, 1, 2, 5, 10, 40] {
            for p in [0.05, 0.2, 0.5] {
                for _ in 0 ..< 5 {
                    var edges: [DirectedEdge<Int>] = []
                    for u in 0 ..< n {
                        for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < p { edges.append(DirectedEdge(from: u, to: v)) }
                    }
                    var successors = [[Int]](repeating: [], count: n)
                    var predecessors = [[Int]](repeating: [], count: n)
                    for e in edges {
                        successors[e.source].append(e.target)
                        predecessors[e.target].append(e.source)
                    }
                    // Oracle: reachability by a search from every vertex.
                    var reaches = [Set<Int>](repeating: [], count: n)
                    for s in 0 ..< n {
                        var seen: Set<Int> = [s]
                        var stack = [s]
                        while let u = stack.popLast() {
                            for w in successors[u] where seen.insert(w).inserted { stack.append(w) }
                        }
                        reaches[s] = seen
                    }
                    // Oracle: Kosaraju–Sharir, recursive (n ≤ 40).
                    var visited = Set<Int>()
                    var finished: [Int] = []
                    func forward(_ v: Int) {
                        guard visited.insert(v).inserted else { return }
                        for w in successors[v] { forward(w) }
                        finished.append(v)
                    }
                    for v in 0 ..< n { forward(v) }
                    var assigned = Set<Int>()
                    var kosaraju = Set<Set<Int>>()
                    for root in finished.reversed() where !assigned.contains(root) {
                        var component: Set<Int> = [root]
                        var stack = [root]
                        assigned.insert(root)
                        while let v = stack.popLast() {
                            for u in predecessors[v] where assigned.insert(u).inserted {
                                component.insert(u)
                                stack.append(u)
                            }
                        }
                        kosaraju.insert(component)
                    }
                    let repeats = edges.filter { _ in Bool.random(using: &generator) }
                    func check<G: DirectedGraph<Int>>(_ g: G) {
                        let scc = g.stronglyConnectedComponents()
                        // CN-114
                        #expect(scc.allSatisfy { !$0.isEmpty })
                        #expect(scc.map(\.count).reduce(0, +) == n)
                        #expect(Set(scc.joined()) == Set(0 ..< n))
                        // CN-115
                        for u in 0 ..< n {
                            for v in 0 ..< n {
                                let same = scc.component(of: u) == scc.component(of: v)
                                #expect(same == (reaches[u].contains(v) && reaches[v].contains(u)), "n \(n): \(u), \(v)")
                            }
                        }
                        // CN-116
                        let topological = Array(scc.reversed().joined())
                        var position = [Int](repeating: 0, count: n)
                        for (i, v) in topological.enumerated() { position[v] = i }
                        for e in edges {
                            #expect(scc.component(of: e.source) >= scc.component(of: e.target))
                            if scc.component(of: e.source) != scc.component(of: e.target) { #expect(position[e.source] < position[e.target]) }
                        }
                        // CN-118
                        #expect(Set(scc.map(Set.init)) == kosaraju)
                        // CN-48
                        #expect(g.isStronglyConnected == (scc.count == 1))
                    }
                    check(AdjacencyList(vertices: 0 ..< n, edges: edges))
                    check(AdjacencyMatrix(vertexCount: n, edges: edges))
                    check(CompressedSparseRow(vertexCount: n, edges: edges))
                    check(Multigraph(vertices: 0 ..< n, edges: (edges + repeats).sorted()))
                    check(DictionaryGraph(vertices: Array(0 ..< n), edges: edges))
                    // CN-117: the reversed graph has the same partition.
                    let reversed = Multigraph(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0.target, to: $0.source) })
                    #expect(Set(reversed.stronglyConnectedComponents().map(Set.init)) == kosaraju)
                }
            }
        }
    }

    @Test("CN-119 a graph is acyclic iff every strong component is a singleton and there are no self-loops", arguments: 1 ... 10)
    func acyclicity(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 100)
        for n in [0, 1, 2, 5, 10, 40] {
            for p in [0.05, 0.2, 0.5] {
                for _ in 0 ..< 5 {
                    var edges: [DirectedEdge<Int>] = []
                    for u in 0 ..< n {
                        for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < p { edges.append(DirectedEdge(from: u, to: v)) }
                    }
                    // Sparse graphs are mostly cyclic at n = 40; also try them with only forward edges.
                    for candidate in [edges, edges.filter { $0.source < $0.target }] {
                        let sparse = CompressedSparseRow(vertexCount: n, edges: candidate)
                        let list = AdjacencyList(vertices: 0 ..< n, edges: candidate)
                        let singletons = sparse.stronglyConnectedComponents().allSatisfy { $0.count == 1 }
                        let loops = candidate.contains { $0.isSelfLoop }
                        #expect(sparse.isAcyclic == (singletons && !loops))
                        #expect(list.isAcyclic == (list.stronglyConnectedComponents().allSatisfy { $0.count == 1 } && !loops))
                    }
                }
            }
        }
    }

    @Test("CN-120 weak components equal a union–find in the documented order, and strong components refine them", arguments: 1 ... 10)
    func weakComponents(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 200)
        for n in [0, 1, 2, 5, 10, 40] {
            for p in [0.05, 0.2, 0.5] {
                for _ in 0 ..< 5 {
                    var edges: [DirectedEdge<Int>] = []
                    for u in 0 ..< n {
                        // Sparser than the others, so there are several weak components.
                        for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < p / 8 { edges.append(DirectedEdge(from: u, to: v)) }
                    }
                    // Oracle: union–find, then components ordered by first vertex, members ascending.
                    var parent = Array(0 ..< n)
                    func find(_ v: Int) -> Int {
                        var v = v
                        while parent[v] != v { v = parent[v] }
                        return v
                    }
                    for e in edges { parent[find(e.source)] = find(e.target) }
                    var order: [Int] = []
                    var members: [Int: [Int]] = [:]
                    for v in 0 ..< n {
                        let r = find(v)
                        if members[r] == nil { order.append(r) }
                        members[r, default: []].append(v)
                    }
                    let expected = order.map { members[$0]! }
                    let repeats = edges.filter { _ in Bool.random(using: &generator) }
                    func check<G: DirectedGraph<Int>>(_ g: G, exact: Bool) {
                        let weak = g.weaklyConnectedComponents()
                        if exact {
                            #expect(weak.map(Array.init) == expected)
                        } else {
                            #expect(Set(weak.map(Set.init)) == Set(expected.map(Set.init)))
                        }
                        for (position, component) in weak.enumerated() {
                            for v in component { #expect(weak.component(of: v) == position) }
                        }
                        #expect(g.isWeaklyConnected == (expected.count == 1))
                        let strong = g.stronglyConnectedComponents()
                        for component in strong { #expect(Set(component.map { weak.component(of: $0) }).count == 1) }
                    }
                    check(AdjacencyList(vertices: 0 ..< n, edges: edges), exact: false)
                    check(AdjacencyMatrix(vertexCount: n, edges: edges), exact: true)
                    check(CompressedSparseRow(vertexCount: n, edges: edges), exact: true)
                    check(Multigraph(vertices: 0 ..< n, edges: edges + repeats), exact: true)
                    check(DictionaryGraph(vertices: Array(0 ..< n), edges: edges), exact: true)
                }
            }
        }
    }

    @Test("CN-121 condensation and attracting-component laws", arguments: 1 ... 10)
    func condensation(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 300)
        for n in [0, 1, 2, 5, 10, 40] {
            for p in [0.05, 0.2, 0.5] {
                for _ in 0 ..< 5 {
                    var edges: [DirectedEdge<Int>] = []
                    for u in 0 ..< n {
                        for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < p { edges.append(DirectedEdge(from: u, to: v)) }
                    }
                    let repeats = edges.filter { _ in Bool.random(using: &generator) }
                    func check<G: DirectedGraph<Int>>(_ g: G) {
                        let condensation = g.condensation()
                        let components = condensation.components
                        let graph = condensation.graph
                        #expect(components == g.stronglyConnectedComponents())
                        #expect(graph.vertexCount == components.count)
                        var expected = Set<DirectedEdge<Int>>()
                        for e in edges where components.component(of: e.source) != components.component(of: e.target) {
                            expected.insert(DirectedEdge(from: components.component(of: e.source), to: components.component(of: e.target)))
                        }
                        #expect(Set(graph.edges) == expected)
                        #expect(graph.edgeCount == expected.count)
                        for i in 0 ..< graph.vertexCount {
                            let row = Array(graph.successors(of: i))
                            #expect(zip(row, row.dropFirst()).allSatisfy { $0 < $1 })
                            #expect(row.allSatisfy { $0 < i })
                        }
                        #expect(graph.isAcyclic)
                        let attracting = components.indices.filter { graph.outDegree(of: $0) == 0 }.map { Array(components[$0]) }
                        #expect(g.attractingComponents().map(Array.init) == attracting)
                    }
                    check(AdjacencyList(vertices: 0 ..< n, edges: edges))
                    check(AdjacencyMatrix(vertexCount: n, edges: edges))
                    check(CompressedSparseRow(vertexCount: n, edges: edges))
                    check(Multigraph(vertices: 0 ..< n, edges: edges + repeats))
                    check(DictionaryGraph(vertices: Array(0 ..< n), edges: edges))
                }
            }
        }
    }

    @Test("CN-122 / CN-123 dominators equal brute force and Cooper–Harvey–Kennedy, and frontiers equal Cytron's definition", arguments: 1 ... 10)
    func dominators(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 400)
        for n in [1, 2, 5, 10, 40] {
            for p in [0.05, 0.2, 0.5] {
                for _ in 0 ..< 5 {
                    var edges: [DirectedEdge<Int>] = []
                    for u in 0 ..< n {
                        for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < p { edges.append(DirectedEdge(from: u, to: v)) }
                    }
                    var successors = [[Int]](repeating: [], count: n)
                    var predecessors = [[Int]](repeating: [], count: n)
                    for e in edges {
                        successors[e.source].append(e.target)
                        predecessors[e.target].append(e.source)
                    }
                    func reach(from root: Int, without removed: Int?) -> Set<Int> {
                        guard root != removed else { return [] }
                        var seen: Set<Int> = [root]
                        var stack = [root]
                        while let u = stack.popLast() {
                            for w in successors[u] where w != removed && seen.insert(w).inserted { stack.append(w) }
                        }
                        return seen
                    }
                    let roots = n <= 10 ? Array(0 ..< n) : (0 ..< 4).map { _ in Int.random(in: 0 ..< n, using: &generator) }
                    let repeats = edges.filter { _ in Bool.random(using: &generator) }
                    let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
                    let matrix = AdjacencyMatrix(vertexCount: n, edges: edges)
                    let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
                    let multigraph = Multigraph(vertices: 0 ..< n, edges: (edges + repeats).sorted())
                    for root in roots {
                        // Oracle: u dominates v iff removing u cuts v off from the root.
                        let reachable = reach(from: root, without: nil)
                        var dominators = [Set<Int>](repeating: [], count: n)
                        for v in reachable { dominators[v] = [v, root] }
                        for u in 0 ..< n where u != root {
                            let rest = reach(from: root, without: u)
                            for v in reachable where v != u && !rest.contains(v) { dominators[v].insert(u) }
                        }
                        // Oracle: Cooper, Harvey and Kennedy, over a reverse postorder.
                        var postorder: [Int] = []
                        var discovered: Set<Int> = [root]
                        var stack = [(root, 0)]
                        while let top = stack.popLast() {
                            let (u, next) = top
                            if next < successors[u].count {
                                stack.append((u, next + 1))
                                let w = successors[u][next]
                                if discovered.insert(w).inserted { stack.append((w, 0)) }
                            } else {
                                postorder.append(u)
                            }
                        }
                        var number: [Int: Int] = [:]
                        for (i, v) in postorder.enumerated() { number[v] = i }
                        var chk: [Int: Int] = [root: root]
                        var changed = true
                        while changed {
                            changed = false
                            for v in postorder.reversed() where v != root {
                                var candidate: Int? = nil
                                for p in predecessors[v] where chk[p] != nil {
                                    guard var a = candidate else { candidate = p; continue }
                                    var b = p
                                    while a != b {
                                        while number[a]! < number[b]! { a = chk[a]! }
                                        while number[b]! < number[a]! { b = chk[b]! }
                                    }
                                    candidate = a
                                }
                                if chk[v] != candidate {
                                    chk[v] = candidate
                                    changed = true
                                }
                            }
                        }
                        chk[root] = nil
                        // Oracle: DF(x) = {y : x dominates a reachable predecessor of y and does not strictly dominate y}.
                        var frontier = [Set<Int>](repeating: [], count: n)
                        for y in reachable {
                            for p in predecessors[y] where reachable.contains(p) {
                                for x in dominators[p] where !(dominators[y].contains(x) && x != y) { frontier[x].insert(y) }
                            }
                        }
                        func check<G: DirectedGraph<Int>>(_ g: G, exact: Bool) {
                            let tree = g.dominatorTree(root: root)
                            let frontiers = g.dominanceFrontiers(root: root)
                            #expect(tree.root == root)
                            for v in 0 ..< n {
                                let chain = tree.dominators(of: v)
                                if reachable.contains(v) {
                                    #expect(chain.map { Set($0) } == dominators[v], "n \(n) root \(root): \(v)")
                                    #expect(chain?.count == dominators[v].count)
                                    #expect(tree.immediateDominator(of: v) == chk[v], "n \(n) root \(root): \(v)")
                                    if let idom = tree.immediateDominator(of: v) {
                                        #expect(dominators[v].contains(idom) && idom != v)
                                        #expect(tree.dominates(idom, v))
                                    }
                                    if exact {
                                        #expect(frontiers[v].map { Array($0) } == frontier[v].sorted(), "n \(n) root \(root): \(v)")
                                    } else {
                                        #expect(frontiers[v].map { Set($0) } == frontier[v], "n \(n) root \(root): \(v)")
                                    }
                                } else {
                                    #expect(chain == nil)
                                    #expect(tree.immediateDominator(of: v) == nil)
                                    #expect(frontiers[v] == nil)
                                }
                            }
                            // The tree spans exactly the vertices reachable from the root.
                            var spanned: Set<Int> = [root]
                            var queue = [root]
                            while let u = queue.popLast() {
                                for c in tree.children(of: u) where spanned.insert(c).inserted { queue.append(c) }
                            }
                            #expect(spanned == reachable)
                        }
                        check(list, exact: false)
                        check(matrix, exact: true)
                        check(sparse, exact: true)
                        check(multigraph, exact: true)
                    }
                }
            }
        }
    }

    @Test("CN-124 relabeling maps components to components and immediate dominators to immediate dominators", arguments: 1 ... 10)
    func relabeling(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 500)
        for n in [1, 2, 5, 10, 40] {
            for p in [0.05, 0.2, 0.5] {
                for _ in 0 ..< 5 {
                    var edges: [DirectedEdge<Int>] = []
                    for u in 0 ..< n {
                        for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < p { edges.append(DirectedEdge(from: u, to: v)) }
                    }
                    // A random permutation onto spread-out values.
                    let permutation = Array(0 ..< n).shuffled(using: &generator)
                    let relabel = { (v: Int) in permutation[v] * 7 + 3 }
                    let original = CompressedSparseRow(vertexCount: n, edges: edges)
                    let relabeledEdges = edges.map { DirectedEdge(from: relabel($0.source), to: relabel($0.target)) }
                    let relabeled = AdjacencyList(vertices: (0 ..< n).map(relabel).shuffled(using: &generator), edges: relabeledEdges.shuffled(using: &generator))
                    let relabeledMultigraph = Multigraph(vertices: (0 ..< n).map(relabel), edges: relabeledEdges)
                    let expected = Set(original.stronglyConnectedComponents().map { Set($0.map(relabel)) })
                    #expect(Set(relabeled.stronglyConnectedComponents().map(Set.init)) == expected)
                    #expect(Set(relabeledMultigraph.stronglyConnectedComponents().map(Set.init)) == expected)
                    #expect(Set(relabeled.weaklyConnectedComponents().map(Set.init)) == Set(original.weaklyConnectedComponents().map { Set($0.map(relabel)) }))
                    let root = Int.random(in: 0 ..< n, using: &generator)
                    let tree = original.dominatorTree(root: root)
                    let relabeledTree = relabeled.dominatorTree(root: relabel(root))
                    for v in 0 ..< n {
                        #expect(relabeledTree.immediateDominator(of: relabel(v)) == tree.immediateDominator(of: v).map(relabel))
                    }
                }
            }
        }
    }

    @Test("CN-125 representations agree: matrix and CSR exactly, the Multigraph and the unindexed conformer in the same order, adjacency lists as partitions", arguments: 1 ... 10)
    func representationsAgree(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 600)
        for n in [0, 1, 2, 5, 10, 40] {
            for p in [0.05, 0.2, 0.5] {
                for _ in 0 ..< 5 {
                    var edges: [DirectedEdge<Int>] = []
                    for u in 0 ..< n {
                        for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < p { edges.append(DirectedEdge(from: u, to: v)) }
                    }
                    let repeats = edges.filter { _ in Bool.random(using: &generator) }
                    let matrix = AdjacencyMatrix(vertexCount: n, edges: edges)
                    let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
                    // Edges written ascending, so successors come in the same order as the matrix's.
                    let multigraph = Multigraph(vertices: 0 ..< n, edges: (edges + repeats).sorted())
                    let unindexed = DictionaryGraph(vertices: Array(0 ..< n), edges: edges)
                    let list = AdjacencyList(vertices: 0 ..< n, edges: edges.shuffled(using: &generator))
                    let strong = matrix.stronglyConnectedComponents().map(Array.init)
                    #expect(sparse.stronglyConnectedComponents().map(Array.init) == strong)
                    #expect(multigraph.stronglyConnectedComponents().map(Array.init) == strong)
                    #expect(unindexed.stronglyConnectedComponents().map(Array.init) == strong)
                    #expect(Set(list.stronglyConnectedComponents().map(Set.init)) == Set(strong.map(Set.init)))
                    let weak = matrix.weaklyConnectedComponents().map(Array.init)
                    #expect(sparse.weaklyConnectedComponents().map(Array.init) == weak)
                    #expect(multigraph.weaklyConnectedComponents().map(Array.init) == weak)
                    #expect(unindexed.weaklyConnectedComponents().map(Array.init) == weak)
                    #expect(Set(list.weaklyConnectedComponents().map(Set.init)) == Set(weak.map(Set.init)))
                    let condensation = matrix.condensation().graph
                    #expect(sparse.condensation().graph == condensation)
                    #expect(multigraph.condensation().graph == condensation)
                    #expect(unindexed.condensation().graph == condensation)
                    #expect(sparse.attractingComponents() == matrix.attractingComponents())
                    #expect(unindexed.attractingComponents() == matrix.attractingComponents())
                    #expect(Set(list.attractingComponents().map(Set.init)) == Set(matrix.attractingComponents().map(Set.init)))
                    for root in (n <= 10 ? Array(0 ..< n) : [0, n / 2, n - 1]) {
                        let matrixTree = matrix.dominatorTree(root: root)
                        let sparseTree = sparse.dominatorTree(root: root)
                        let multigraphTree = multigraph.dominatorTree(root: root)
                        let unindexedTree = unindexed.dominatorTree(root: root)
                        let listTree = list.dominatorTree(root: root)
                        let matrixFrontiers = matrix.dominanceFrontiers(root: root)
                        let sparseFrontiers = sparse.dominanceFrontiers(root: root)
                        let unindexedFrontiers = unindexed.dominanceFrontiers(root: root)
                        for v in 0 ..< n {
                            let idom = matrixTree.immediateDominator(of: v)
                            #expect(sparseTree.immediateDominator(of: v) == idom)
                            #expect(multigraphTree.immediateDominator(of: v) == idom)
                            #expect(unindexedTree.immediateDominator(of: v) == idom)
                            #expect(listTree.immediateDominator(of: v) == idom)
                            let children = Array(matrixTree.children(of: v))
                            #expect(Array(sparseTree.children(of: v)) == children)
                            #expect(Array(multigraphTree.children(of: v)) == children)
                            #expect(Array(unindexedTree.children(of: v)) == children)
                            #expect(Set(listTree.children(of: v)) == Set(children))
                            #expect(sparseFrontiers[v].map { Array($0) } == matrixFrontiers[v].map { Array($0) })
                            #expect(unindexedFrontiers[v].map { Array($0) } == matrixFrontiers[v].map { Array($0) })
                        }
                    }
                }
            }
        }
    }

    @Test("CN-126 computing twice gives equal results", arguments: 1 ... 10)
    func determinism(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 700)
        for n in [0, 1, 2, 5, 10, 40] {
            for p in [0.05, 0.2, 0.5] {
                for _ in 0 ..< 5 {
                    var edges: [DirectedEdge<Int>] = []
                    for u in 0 ..< n {
                        for v in 0 ..< n where Double.random(in: 0 ..< 1, using: &generator) < p { edges.append(DirectedEdge(from: u, to: v)) }
                    }
                    let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
                    let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
                    #expect(list.stronglyConnectedComponents() == list.stronglyConnectedComponents())
                    #expect(list.weaklyConnectedComponents() == list.weaklyConnectedComponents())
                    #expect(sparse.stronglyConnectedComponents() == sparse.stronglyConnectedComponents())
                    #expect(sparse.condensation().components == sparse.condensation().components)
                    #expect(sparse.condensation().graph == sparse.condensation().graph)
                    #expect(list.attractingComponents() == list.attractingComponents())
                    if n > 0 {
                        let first = list.dominatorTree(root: 0)
                        let second = list.dominatorTree(root: 0)
                        for v in 0 ..< n {
                            #expect(first.dominators(of: v) == second.dominators(of: v))
                            #expect(Array(first.children(of: v)) == Array(second.children(of: v)))
                        }
                    }
                }
            }
        }
    }
}
