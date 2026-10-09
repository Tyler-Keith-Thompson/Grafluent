// §I: seeded random multigraphs with self-loops and parallel edges (n ≤ 10, m ≤ 16, a reversed
// copy of an edge with probability 0.15), on the ReferencePseudograph and on an
// UndirectedAdjacencyList of the same edges (where repeats collapse), against oracles written in
// each test: union–find component counts with a vertex or an edge removed, brute-force blocks
// from far-end connectivity, and 2-edge-connected labels from every single-edge removal. CN-351
// adds Boost's G(100, 500) and sparser G(100, 100), G(100, 120), G(300, 320); CN-350 has a
// PropertyBased version that shrinks a failure to a small edge list. Case IDs (CN-nnn) refer to the
// catalog; see README.md.

import AdjacencyListModule
import Connectivity
import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing

/// A pseudograph with vertex and edge indices that counts every row it is asked for, so a test can
/// see how much of the graph an early-exiting algorithm reads.
private final class RowCounter: @unchecked Sendable {
    var rows = 0
}

private struct RowCountingGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    let incident: [[Int]]
    let counter: RowCounter

    init(vertexCount: Int, edges: [UndirectedEdge<Int>], counter: RowCounter) {
        var incident = [[Int]](repeating: [], count: vertexCount)
        for (k, edge) in edges.enumerated() {
            incident[edge.u].append(k)
            incident[edge.v].append(k)
        }
        self.vertices = Array(0 ..< vertexCount)
        self.edges = edges
        self.incident = incident
        self.counter = counter
    }

    func incidentEdges(of vertex: Int) -> [Int] {
        counter.rows += 1
        return incident[vertex]
    }
    func neighbors(of vertex: Int) -> [Int] {
        counter.rows += 1
        return incident[vertex].map { edges[$0].oppositeVertex(to: vertex) }
    }
    func contains(_ vertex: Int) -> Bool { vertex >= 0 && vertex < vertices.count }
    var vertexIndexBound: Int? { vertices.count }
    func vertexIndex(of vertex: Int) -> Int { vertex }
    func vertex(atIndex index: Int) -> Int { index }
    func neighborIndices(ofIndex index: Int) -> [Int] {
        counter.rows += 1
        return incident[index].map { edges[$0].oppositeVertex(to: index) }
    }
    func incidentEdges(ofIndex index: Int) -> [Int] {
        counter.rows += 1
        return incident[index]
    }
    var edgeIndexBound: Int? { edges.count }
    func edgeIndex(of position: Int) -> Int { position }
    func incidentEdgeIndices(ofIndex index: Int) -> [Int] {
        counter.rows += 1
        return incident[index]
    }
}

@Suite("Undirected connectivity properties on random multigraphs", .tags(.randomized))
struct UndirectedConnectivityPropertyTests {
    @Test("CN-350 bridges() is exactly the non-loop edges whose removal adds a component, in position order")
    func bridgesLaw() {
        var rng = SeededRandomNumberGenerator(seed: 350)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
                let pairs = g.edges.map { ($0.u, $0.v) }
                func componentCount(droppingEdge dropped: Int?) -> Int {
                    var parent = Array(0 ..< n)
                    func find(_ x: Int) -> Int {
                        var x = x
                        while parent[x] != x { x = parent[x] }
                        return x
                    }
                    for (k, pair) in pairs.enumerated() where k != dropped {
                        let (ru, rv) = (find(pair.0), find(pair.1))
                        if ru != rv { parent[ru] = rv }
                    }
                    return (0 ..< n).filter { find($0) == $0 }.count
                }
                let c = componentCount(droppingEdge: nil)
                let expected = pairs.indices.filter { pairs[$0].0 != pairs[$0].1 && componentCount(droppingEdge: $0) > c }
                #expect(g.bridges() == expected, "\(raw)")
                #expect(g.hasBridges == !expected.isEmpty, "\(raw)")
            }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
        }
    }

    @Test("CN-350 CN-351 bridges and articulation points by removal: a failure shrinks to a small edge list")
    func removalLawsWithShrinking() async {
        // Up to 16 edges on vertices 0..<8, repeats and self-loops allowed. On a failure,
        // PropertyBased shrinks the edge list and prints the smallest one that still fails.
        let edges = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 16)
        await propertyCheck(count: 300, input: edges) { raw in
            let n = 8
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            func componentCount(droppingVertex vertex: Int?, droppingEdge dropped: Int?) -> Int {
                var parent = Array(0 ..< n)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                for (k, pair) in raw.enumerated() where k != dropped && pair.0 != vertex && pair.1 != vertex {
                    let (ru, rv) = (find(pair.0), find(pair.1))
                    if ru != rv { parent[ru] = rv }
                }
                return (0 ..< n).filter { $0 != vertex && find($0) == $0 }.count
            }
            let c = componentCount(droppingVertex: nil, droppingEdge: nil)
            let bridges = raw.indices.filter { raw[$0].0 != raw[$0].1 && componentCount(droppingVertex: nil, droppingEdge: $0) > c }
            let points = (0 ..< n).filter { componentCount(droppingVertex: $0, droppingEdge: nil) > c }
            #expect(graph.bridges() == bridges)
            #expect(graph.articulationPoints() == points)
            // A one-edge block is a bridge, and every non-loop edge is in exactly one block.
            let blocks = graph.biconnectedComponents()
            #expect(blocks.filter { $0.count == 1 }.map { $0.first! } == bridges)
            #expect(blocks.flatMap { $0 }.sorted() == raw.indices.filter { raw[$0].0 != raw[$0].1 })
        }
    }

    @Test("CN-351 articulationPoints() is exactly the vertices whose removal adds a component, in vertices order, also on Boost's G(100, 500)")
    func articulationPointsLaw() {
        var rng = SeededRandomNumberGenerator(seed: 351)
        var graphs: [(Int, [(Int, Int)])] = []
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            graphs.append((n, raw))
        }
        // Boost's biconnected_components_test: G(100, 500) with parallel edges and no loops,
        // checked by vertex removal; and sparser graphs, which have articulation points to find.
        for (n, m) in [(100, 500), (100, 100), (100, 120), (300, 320)] {
            var raw: [(Int, Int)] = []
            while raw.count < m {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                if u != v { raw.append((u, v)) }
            }
            graphs.append((n, raw))
        }
        for (n, raw) in graphs {
            func check<G: Graph<Int>>(_ g: G) {
                let pairs = g.edges.map { ($0.u, $0.v) }
                func componentCount(droppingVertex vertex: Int?) -> Int {
                    var parent = Array(0 ..< n)
                    func find(_ x: Int) -> Int {
                        var x = x
                        while parent[x] != x { x = parent[x] }
                        return x
                    }
                    for pair in pairs where pair.0 != vertex && pair.1 != vertex {
                        let (ru, rv) = (find(pair.0), find(pair.1))
                        if ru != rv { parent[ru] = rv }
                    }
                    return (0 ..< n).filter { $0 != vertex && find($0) == $0 }.count
                }
                let c = componentCount(droppingVertex: nil)
                let expected = (0 ..< n).filter { componentCount(droppingVertex: $0) > c }
                #expect(g.articulationPoints() == expected, "n = \(n): \(raw)")
                #expect(g.blockCutTree().articulationPoints == expected, "n = \(n): \(raw)")
            }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
        }
    }

    @Test("CN-352 blocks: non-loop edges at w share a block iff their far ends are joined in G − w, closed transitively; ordered by smallest position")
    func blocksLaw() {
        var rng = SeededRandomNumberGenerator(seed: 352)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
                let pairs = g.edges.map { ($0.u, $0.v) }
                // The component label of every vertex of G − w.
                func labels(without w: Int) -> [Int] {
                    var parent = Array(0 ..< n)
                    func find(_ x: Int) -> Int {
                        var x = x
                        while parent[x] != x { x = parent[x] }
                        return x
                    }
                    for pair in pairs where pair.0 != w && pair.1 != w {
                        let (ru, rv) = (find(pair.0), find(pair.1))
                        if ru != rv { parent[ru] = rv }
                    }
                    return (0 ..< n).map { find($0) }
                }
                var blockParent = Array(pairs.indices)
                func findBlock(_ x: Int) -> Int {
                    var x = x
                    while blockParent[x] != x { x = blockParent[x] }
                    return x
                }
                for w in 0 ..< n {
                    let label = labels(without: w)
                    let ends = pairs.indices.filter { pairs[$0].0 != pairs[$0].1 && (pairs[$0].0 == w || pairs[$0].1 == w) }
                    for i in ends.indices {
                        for j in ends.indices where j > i {
                            let a = pairs[ends[i]].0 == w ? pairs[ends[i]].1 : pairs[ends[i]].0
                            let b = pairs[ends[j]].0 == w ? pairs[ends[j]].1 : pairs[ends[j]].0
                            if a == b || label[a] == label[b] {
                                let (ra, rb) = (findBlock(ends[i]), findBlock(ends[j]))
                                if ra != rb { blockParent[ra] = rb }
                            }
                        }
                    }
                }
                // Grouped in position order, so blocks come by smallest position, edges ascending.
                var groups: [Int: Int] = [:]
                var expected: [[Int]] = []
                for k in pairs.indices where pairs[k].0 != pairs[k].1 {
                    let root = findBlock(k)
                    if let b = groups[root] {
                        expected[b].append(k)
                    } else {
                        groups[root] = expected.count
                        expected.append([k])
                    }
                }
                let expectedVertices = expected.map { block in (0 ..< n).filter { v in block.contains { pairs[$0].0 == v || pairs[$0].1 == v } } }
                let blocks = g.biconnectedComponents()
                #expect(blocks.map(Array.init) == expected, "\(raw)")
                #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == expectedVertices, "\(raw)")
            }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
        }
    }

    @Test("CN-353 CN-354 the blocks partition the non-loop edges, component(ofEdgeAt:) is nil exactly for loops, and the one-edge blocks are the bridges")
    func partitionAndBridges() {
        var rng = SeededRandomNumberGenerator(seed: 353)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
                let blocks = g.biconnectedComponents()
                let loops = g.edges.indices.filter { g.edges[$0].u == g.edges[$0].v }
                #expect(blocks.flatMap { $0 }.sorted() == g.edges.indices.filter { !loops.contains($0) }, "\(raw)")
                #expect(blocks.allSatisfy { !$0.isEmpty && $0.elementsEqual($0.sorted()) }, "\(raw)")
                // Ordered by smallest position.
                #expect(blocks.map { $0.first! }.elementsEqual(blocks.map { $0.first! }.sorted()), "\(raw)")
                for k in g.edges.indices {
                    let block = blocks.component(ofEdgeAt: k)
                    if loops.contains(k) {
                        #expect(block == nil, "\(raw): loop \(k)")
                    } else {
                        #expect(block.map { blocks[$0].contains(k) } == true, "\(raw): edge \(k)")
                    }
                }
                #expect(blocks.filter { $0.count == 1 }.map { $0.first! } == g.bridges(), "\(raw)")
            }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
        }
    }

    @Test("CN-355 CN-356 articulation points are the vertices in two or more blocks; v is in c(G − v) − c(G) + 1 blocks; Σ (|V(B)| − 1) = n − c")
    func blockMembership() {
        var rng = SeededRandomNumberGenerator(seed: 355)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
                let pairs = g.edges.map { ($0.u, $0.v) }
                func componentCount(droppingVertex vertex: Int?) -> Int {
                    var parent = Array(0 ..< n)
                    func find(_ x: Int) -> Int {
                        var x = x
                        while parent[x] != x { x = parent[x] }
                        return x
                    }
                    for pair in pairs where pair.0 != vertex && pair.1 != vertex {
                        let (ru, rv) = (find(pair.0), find(pair.1))
                        if ru != rv { parent[ru] = rv }
                    }
                    return (0 ..< n).filter { $0 != vertex && find($0) == $0 }.count
                }
                let c = componentCount(droppingVertex: nil)
                let blocks = g.biconnectedComponents()
                let points = g.articulationPoints()
                let tree = g.blockCutTree()
                #expect((0 ..< n).filter { blocks.components(containing: $0).count >= 2 } == points, "\(raw)")
                for v in 0 ..< n {
                    let containing = Array(blocks.components(containing: v))
                    #expect(containing == blocks.indices.filter { blocks.vertices(ofComponentAt: $0).contains(v) }, "\(raw): \(v)")
                    let hasNonLoopEdge = pairs.contains { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }
                    #expect(containing.count == (hasNonLoopEdge ? componentCount(droppingVertex: v) - c + 1 : 0), "\(raw): \(v)")
                    if let point = points.firstIndex(of: v) {
                        #expect(tree.node(of: v) == .articulationPoint(point), "\(raw): \(v)")
                    } else if let only = containing.first {
                        #expect(tree.node(of: v) == .block(only), "\(raw): \(v)")
                    } else {
                        #expect(tree.node(of: v) == nil, "\(raw): \(v)")
                    }
                }
                #expect(blocks.indices.map { blocks.vertices(ofComponentAt: $0).count - 1 }.reduce(0, +) == n - c, "\(raw)")
            }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
        }
    }

    @Test("CN-357 2-edge-connected components: u and v together iff joined in G − e for every edge e; c(G) + bridges in all")
    func biEdgeConnectedLaw() {
        var rng = SeededRandomNumberGenerator(seed: 357)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
                let pairs = g.edges.map { ($0.u, $0.v) }
                func labels(droppingEdge dropped: Int?) -> [Int] {
                    var parent = Array(0 ..< n)
                    func find(_ x: Int) -> Int {
                        var x = x
                        while parent[x] != x { x = parent[x] }
                        return x
                    }
                    for (k, pair) in pairs.enumerated() where k != dropped {
                        let (ru, rv) = (find(pair.0), find(pair.1))
                        if ru != rv { parent[ru] = rv }
                    }
                    return (0 ..< n).map { find($0) }
                }
                // Each vertex's labels in G and in G − e for every edge: equal keys, one component.
                let all = [labels(droppingEdge: nil)] + pairs.indices.map { labels(droppingEdge: $0) }
                let keys = (0 ..< n).map { v in all.map { $0[v] } }
                var expected: [[Int]] = []
                var seen: [[Int]: Int] = [:]
                for v in 0 ..< n {
                    if let c = seen[keys[v]] {
                        expected[c].append(v)
                    } else {
                        seen[keys[v]] = expected.count
                        expected.append([v])
                    }
                }
                let components = g.biEdgeConnectedComponents()
                #expect(components.map(Array.init) == expected, "\(raw)")
                #expect(components.count == g.connectedComponents().count + g.bridges().count, "\(raw)")
                for v in 0 ..< n { #expect(components[components.component(of: v)].contains(v), "\(raw): \(v)") }
            }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
        }
    }

    @Test("CN-358 the block–cut tree is a forest between blocks and articulation points, one tree per component with a non-loop edge")
    func blockCutForest() {
        var rng = SeededRandomNumberGenerator(seed: 358)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            func check<G: Graph<Int>>(_ g: G) where G.Edges.Index == Int {
                let tree = g.blockCutTree()
                let blocks = g.biconnectedComponents()
                #expect(tree.blocks == blocks, "\(raw)")
                #expect(tree.articulationPoints == g.articulationPoints(), "\(raw)")
                // Each block lists the articulation points among its vertices, ascending; each
                // point lists the blocks that list it, ascending.
                var listed = 0
                for b in blocks.indices {
                    let points = Array(tree.articulationPoints(ofBlock: b))
                    #expect(points.map { tree.articulationPoints[$0] } == blocks.vertices(ofComponentAt: b).filter { tree.articulationPoints.contains($0) }, "\(raw): block \(b)")
                    #expect(points == points.sorted(), "\(raw): block \(b)")
                    listed += points.count
                }
                for p in tree.articulationPoints.indices {
                    let around = Array(tree.blocks(ofArticulationPoint: p))
                    #expect(around == blocks.indices.filter { tree.articulationPoints(ofBlock: $0).contains(p) }, "\(raw): point \(p)")
                    #expect(around.count >= 2, "\(raw): point \(p)")
                }
                #expect(tree.edgeCount == listed, "\(raw)")
                // Acyclic: union–find over the nodes, blocks first, then points.
                var parent = Array(0 ..< blocks.count + tree.articulationPoints.count)
                func find(_ x: Int) -> Int {
                    var x = x
                    while parent[x] != x { x = parent[x] }
                    return x
                }
                for b in blocks.indices {
                    for p in tree.articulationPoints(ofBlock: b) {
                        let (rb, rp) = (find(b), find(blocks.count + p))
                        #expect(rb != rp, "\(raw): a cycle through block \(b)")
                        parent[rb] = rp
                    }
                }
                let components = g.connectedComponents()
                let withEdges = components.filter { component in g.edges.contains { $0.u != $0.v && component.contains($0.u) } }.count
                #expect(blocks.count + tree.articulationPoints.count - tree.edgeCount == withEdges, "\(raw)")
            }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
        }
    }

    @Test("CN-359 CN-360 CN-369 the predicates agree with the collections, and connected components are the directed view's weak components")
    func predicates() {
        var rng = SeededRandomNumberGenerator(seed: 359)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 0 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            if n > 0 {
                for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                    let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                    raw.append((u, v))
                    if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
                }
            }
            func check<G: Graph<Int>>(_ g: G) {
                let components = g.connectedComponents()
                #expect(g.isConnected == (components.count == 1), "\(raw)")
                #expect(g.isBiconnected == (n >= 2 && g.isConnected && g.articulationPoints().isEmpty), "\(raw)")
                #expect(g.isBiEdgeConnected == (n >= 2 && g.isConnected && !g.hasBridges), "\(raw)")
                #expect(g.hasBridges == !g.bridges().isEmpty, "\(raw)")
                // CN-360.
                #expect(components == g.directed.weaklyConnectedComponents(), "\(raw)")
                #expect(g.isConnected == g.directed.isStronglyConnected, "\(raw)")
                // CN-369: bi-edge-connected implies connected; biconnected with no K₂ component
                // (two vertices and one edge between them) implies bi-edge-connected.
                if g.isBiEdgeConnected { #expect(g.isConnected, "\(raw)") }
                let isK2 = n == 2 && g.edges.filter { $0.u != $0.v }.count == 1
                if g.isBiconnected && !isK2 { #expect(g.isBiEdgeConnected, "\(raw)") }
            }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            check(ReferencePseudograph(vertices: 0 ..< n, edges: edges))
            check(UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges))
        }
    }

    @Test("CN-361 doubling every edge: no bridges, the same articulation points and block vertex sets, 2-edge-connected components are the components")
    func doubling() {
        var rng = SeededRandomNumberGenerator(seed: 361)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            let raw = (0 ..< Int.random(in: 0 ... 16, using: &rng)).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            let doubled = ReferencePseudograph(vertices: 0 ..< n, edges: edges + edges)
            #expect(doubled.bridges().isEmpty, "\(raw)")
            #expect(!doubled.hasBridges, "\(raw)")
            #expect(doubled.articulationPoints() == graph.articulationPoints(), "\(raw)")
            let blocks = graph.biconnectedComponents()
            let doubledBlocks = doubled.biconnectedComponents()
            #expect(doubledBlocks.map(Array.init) == blocks.map { Array($0) + $0.map { $0 + raw.count } }, "\(raw)")
            #expect(doubledBlocks.indices.map { Array(doubledBlocks.vertices(ofComponentAt: $0)) } == blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) }, "\(raw)")
            #expect(doubled.biEdgeConnectedComponents().map(Array.init) == graph.connectedComponents().map(Array.init), "\(raw)")
        }
    }

    @Test("CN-362 appending a self-loop anywhere changes nothing but the edge count", .tags(.selfLoops))
    func appendingLoop() {
        var rng = SeededRandomNumberGenerator(seed: 362)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            let raw = (0 ..< Int.random(in: 0 ... 16, using: &rng)).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let at = Int.random(in: 0 ..< n, using: &rng)
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let looped = ReferencePseudograph(vertices: 0 ..< n, edges: (raw + [(at, at)]).map { UndirectedEdge($0.0, $0.1) })
            #expect(looped.edgeCount == graph.edgeCount + 1)
            #expect(looped.connectedComponents() == graph.connectedComponents(), "\(raw) + loop at \(at)")
            #expect(looped.isConnected == graph.isConnected, "\(raw) + loop at \(at)")
            #expect(looped.bridges() == graph.bridges(), "\(raw) + loop at \(at)")
            #expect(looped.articulationPoints() == graph.articulationPoints(), "\(raw) + loop at \(at)")
            let blocks = looped.biconnectedComponents()
            #expect(blocks == graph.biconnectedComponents(), "\(raw) + loop at \(at)")
            #expect(blocks.component(ofEdgeAt: raw.count) == nil, "\(raw) + loop at \(at)")
            #expect(looped.isBiconnected == graph.isBiconnected, "\(raw) + loop at \(at)")
            #expect(looped.biEdgeConnectedComponents() == graph.biEdgeConnectedComponents(), "\(raw) + loop at \(at)")
            #expect(looped.isBiEdgeConnected == graph.isBiEdgeConnected, "\(raw) + loop at \(at)")
            #expect(looped.blockCutTree() == graph.blockCutTree(), "\(raw) + loop at \(at)")
        }
    }

    @Test("CN-363 permuting vertices: the same sets; bridges and blocks by position unchanged; components reorder by first vertex")
    func permutingVertices() {
        var rng = SeededRandomNumberGenerator(seed: 363)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            let raw = (0 ..< Int.random(in: 0 ... 16, using: &rng)).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            let order = Array(0 ..< n).shuffled(using: &rng)
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: edges)
            let permuted = ReferencePseudograph(vertices: order, edges: edges)
            #expect(permuted.vertices == order)
            let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
            // Each component's members in the new order, components by their first member's rank.
            func reordered(_ parts: [[Int]]) -> [[Int]] {
                parts.map { $0.sorted { rank[$0]! < rank[$1]! } }.sorted { rank[$0[0]]! < rank[$1[0]]! }
            }
            #expect(permuted.connectedComponents().map(Array.init) == reordered(graph.connectedComponents().map(Array.init)), "\(raw) in \(order)")
            #expect(permuted.biEdgeConnectedComponents().map(Array.init) == reordered(graph.biEdgeConnectedComponents().map(Array.init)), "\(raw) in \(order)")
            #expect(permuted.bridges() == graph.bridges(), "\(raw) in \(order)")
            let points = Set(graph.articulationPoints())
            #expect(permuted.articulationPoints() == order.filter { points.contains($0) }, "\(raw) in \(order)")
            let blocks = permuted.biconnectedComponents()
            let original = graph.biconnectedComponents()
            #expect(blocks.map(Array.init) == original.map(Array.init), "\(raw) in \(order)")
            #expect(blocks.indices.map { Array(blocks.vertices(ofComponentAt: $0)) } == original.indices.map { b in order.filter { original.vertices(ofComponentAt: b).contains($0) } }, "\(raw) in \(order)")
            #expect(permuted.isBiconnected == graph.isBiconnected && permuted.isBiEdgeConnected == graph.isBiEdgeConnected, "\(raw) in \(order)")
        }
    }

    @Test("CN-364 permuting edge positions: the same edge sets through the permutation, blocks by their new smallest positions")
    func permutingEdges() {
        var rng = SeededRandomNumberGenerator(seed: 364)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            let raw = (0 ..< Int.random(in: 0 ... 16, using: &rng)).map { _ in (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng)) }
            // New position i holds old edge from[i].
            let from = Array(raw.indices).shuffled(using: &rng)
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let permuted = ReferencePseudograph(vertices: 0 ..< n, edges: from.map { UndirectedEdge(raw[$0].0, raw[$0].1) })
            #expect(permuted.bridges().map { from[$0] }.sorted() == graph.bridges(), "\(raw) by \(from)")
            #expect(permuted.articulationPoints() == graph.articulationPoints(), "\(raw) by \(from)")
            let blocks = permuted.biconnectedComponents()
            #expect(Set(blocks.map { Set($0.map { from[$0] }) }) == Set(graph.biconnectedComponents().map { Set($0) }), "\(raw) by \(from)")
            #expect(blocks.allSatisfy { $0.elementsEqual($0.sorted()) }, "\(raw) by \(from)")
            #expect(blocks.map { $0.first! }.elementsEqual(blocks.map { $0.first! }.sorted()), "\(raw) by \(from)")
            #expect(permuted.connectedComponents() == graph.connectedComponents(), "\(raw) by \(from)")
            #expect(permuted.biEdgeConnectedComponents() == graph.biEdgeConnectedComponents(), "\(raw) by \(from)")
        }
    }

    @Test("CN-365 every block, as a graph of its own edges, is one biconnected block; on two vertices it is one edge or a bundle")
    func blocksAreBiconnected() {
        var rng = SeededRandomNumberGenerator(seed: 365)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let blocks = graph.biconnectedComponents()
            for b in blocks.indices {
                let vertices = Array(blocks.vertices(ofComponentAt: b))
                let block = ReferencePseudograph(vertices: vertices, edges: blocks[b].map { graph.edges[$0] })
                #expect(block.isBiconnected, "\(raw): block \(b)")
                #expect(block.biconnectedComponents().map(Array.init) == [Array(0 ..< blocks[b].count)], "\(raw): block \(b)")
                #expect(block.articulationPoints().isEmpty, "\(raw): block \(b)")
                if vertices.count == 2 {
                    #expect(blocks[b].allSatisfy { Set([graph.edges[$0].u, graph.edges[$0].v]) == Set(vertices) }, "\(raw): block \(b)")
                }
            }
        }
    }

    @Test("CN-366 hasBridges is !bridges().isEmpty, and stops at the first bridge: a pendant edge at the first vertex of a 100 000-cycle")
    func hasBridgesEarlyExit() {
        // The pendant edge 0–n is written first, so the search's first tree edge finishes at once
        // and is a bridge; finding every bridge would need the whole cycle.
        let n = 100_000
        let edges = [UndirectedEdge(0, n)] + (0 ..< n).map { UndirectedEdge($0, ($0 + 1) % n) }
        let counter = RowCounter()
        let graph = RowCountingGraph(vertexCount: n + 1, edges: edges, counter: counter)
        counter.rows = 0
        #expect(graph.hasBridges)
        #expect(counter.rows < 10, "\(counter.rows) rows read")
        counter.rows = 0
        #expect(graph.bridges() == [0])
        #expect(counter.rows >= n)
    }

    @Test("CN-366 isBiconnected and isBiEdgeConnected search only the first component: a triangle, then a 100 000-cycle")
    func predicatesStopAfterFirstComponent() {
        // The triangle 0–1–2 is biconnected and bi-edge-connected on its own; the graph is not
        // connected, which the first search tree already shows, so the cycle is never read.
        let n = 100_000
        let edges = [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0)]
            + (0 ..< n).map { UndirectedEdge(3 + $0, 3 + ($0 + 1) % n) }
        let counter = RowCounter()
        let graph = RowCountingGraph(vertexCount: n + 3, edges: edges, counter: counter)
        counter.rows = 0
        #expect(!graph.isBiconnected)
        #expect(counter.rows < 20, "\(counter.rows) rows read")
        counter.rows = 0
        #expect(!graph.isBiEdgeConnected)
        #expect(counter.rows < 20, "\(counter.rows) rows read")
        counter.rows = 0
        #expect(graph.biconnectedComponents().count == 2)
        #expect(counter.rows >= n)
    }

    @Test("CN-368 each 2-edge-connected component has no bridge, and contracting them leaves a forest whose edges are the bridges")
    func contraction() {
        var rng = SeededRandomNumberGenerator(seed: 368)
        for _ in 0 ..< 300 {
            let n = Int.random(in: 1 ... 10, using: &rng)
            var raw: [(Int, Int)] = []
            for _ in 0 ..< Int.random(in: 0 ... 16, using: &rng) {
                let (u, v) = (Int.random(in: 0 ..< n, using: &rng), Int.random(in: 0 ..< n, using: &rng))
                raw.append((u, v))
                if Double.random(in: 0 ..< 1, using: &rng) < 0.15 { raw.append((v, u)) }
            }
            let graph = ReferencePseudograph(vertices: 0 ..< n, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let components = graph.biEdgeConnectedComponents()
            for component in components {
                let members = Set(component)
                let induced = ReferencePseudograph(vertices: Array(component), edges: graph.edges.filter { members.contains($0.u) && members.contains($0.v) })
                #expect(induced.bridges().isEmpty, "\(raw): \(Array(component))")
                #expect(induced.isConnected, "\(raw): \(Array(component))")
            }
            let bridges = Set(graph.bridges())
            var parent = Array(components.indices)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] != x { x = parent[x] }
                return x
            }
            for (k, edge) in graph.edges.enumerated() {
                let (a, b) = (components.component(of: edge.u), components.component(of: edge.v))
                if bridges.contains(k) {
                    let (ra, rb) = (find(a), find(b))
                    #expect(ra != rb, "\(raw): bridge \(k) closes a cycle")
                    parent[ra] = rb
                } else {
                    #expect(a == b, "\(raw): edge \(k) leaves its component")
                }
            }
        }
    }
}
