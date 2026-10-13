// The edge-position searches: edgeBreadthFirstSearch and edgeDepthFirstSearch, directed and
// undirected. Directed, the transcript read back through each position's endpoints is the
// endpoint search's own, on every representation. Undirected, every transcript matches an oracle
// written in the test, which marks each edge the first time a row reaches it. Parallel edges,
// self-loops, pruning, depth limits and preconditions are pinned by hand. Case IDs (TR-nn) refer
// to the catalog; see README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import GraphOperations
import Hypergraphs
import Multigraphs
import PropertyBased
import StableGraphs
import Testing
import Traversal

/// A directed multigraph without vertex indices, so the searches hand out identifiers as vertices
/// are first seen.
private struct UnindexedDirectedGraph: DirectedGraph {
    let base: ReferenceDirectedMultigraph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [DirectedEdge<Int>] { base.edges }
    func successors(of vertex: Int) -> [Int] { base.successors(of: vertex) }
    func outEdges(of vertex: Int) -> [Int] { base.outEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

/// An undirected pseudograph without vertex indices.
private struct UnindexedGraph: Graph {
    let base: ReferencePseudograph<Int>
    var vertices: [Int] { base.vertices }
    var edges: [UndirectedEdge<Int>] { base.edges }
    func neighbors(of vertex: Int) -> [Int] { base.neighbors(of: vertex) }
    func incidentEdges(of vertex: Int) -> [Int] { base.incidentEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
}

/// A directed multigraph that lends pooled rows, as `AdjacencyList` does, with the position rows
/// laid out apart from the target rows: in reverse vertex order, after two unused entries. A
/// search must shift each row's slots to reach its positions.
private struct PooledDirectedGraph: DirectedGraph {
    let base: ReferenceDirectedMultigraph<Int>
    let targets: [Int]
    let targetRows: [Int]
    let positions: [Int]
    let positionRows: [Int]

    init(_ base: ReferenceDirectedMultigraph<Int>) {
        self.base = base
        let n = base.vertexCount
        var targets: [Int] = [], targetRows = [Int](repeating: 0, count: 3 * n)
        var positions = [-1, -1], positionRows = [Int](repeating: 0, count: 3 * n)
        for v in 0 ..< n {
            targetRows[3 * v] = targets.count
            targetRows[3 * v + 1] = base.outDegree(ofIndex: v)
            targets += base.successorIndices(ofIndex: v)
        }
        for v in (0 ..< n).reversed() {
            positionRows[3 * v] = positions.count
            positionRows[3 * v + 1] = base.outDegree(ofIndex: v)
            positions += base.outEdges(ofIndex: v)
        }
        (self.targets, self.targetRows, self.positions, self.positionRows) = (targets, targetRows, positions, positionRows)
    }

    var vertices: [Int] { base.vertices }
    var edges: [DirectedEdge<Int>] { base.edges }
    func successors(of vertex: Int) -> [Int] { base.successors(of: vertex) }
    func outEdges(of vertex: Int) -> [Int] { base.outEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
    var vertexIndexBound: Int? { base.vertexIndexBound }
    func vertexIndex(of vertex: Int) -> Int { base.vertexIndex(of: vertex) }
    func vertex(atIndex index: Int) -> Int { base.vertex(atIndex: index) }
    func _withOutIndexRows<Result>(
        _ body: (_ targets: UnsafeBufferPointer<Int>, _ targetRows: UnsafeBufferPointer<Int>, _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        targets.withUnsafeBufferPointer { t in
            targetRows.withUnsafeBufferPointer { tr in
                positions.withUnsafeBufferPointer { e in positionRows.withUnsafeBufferPointer { er in body(t, tr, e, er) } }
            }
        }
    }
}

/// An undirected pseudograph that lends pooled incident rows, as `UndirectedAdjacencyList` does,
/// with the edge rows laid out apart from the neighbor rows.
private struct PooledGraph: Graph {
    let base: ReferencePseudograph<Int>
    let neighbors: [Int]
    let neighborRows: [Int]
    let incident: [Int]
    let incidentRows: [Int]

    init(_ base: ReferencePseudograph<Int>) {
        self.base = base
        let n = base.vertexCount
        var neighbors: [Int] = [], neighborRows = [Int](repeating: 0, count: 3 * n)
        var incident = [-1], incidentRows = [Int](repeating: 0, count: 3 * n)
        for v in 0 ..< n {
            neighborRows[3 * v] = neighbors.count
            neighborRows[3 * v + 1] = base.degree(ofIndex: v)
            neighbors += base.neighborIndices(ofIndex: v)
        }
        for v in (0 ..< n).reversed() {
            incidentRows[3 * v] = incident.count
            incidentRows[3 * v + 1] = base.degree(ofIndex: v)
            incident += base.incidentEdges(ofIndex: v)
        }
        (self.neighbors, self.neighborRows, self.incident, self.incidentRows) = (neighbors, neighborRows, incident, incidentRows)
    }

    var vertices: [Int] { base.vertices }
    var edges: [UndirectedEdge<Int>] { base.edges }
    func neighbors(of vertex: Int) -> [Int] { base.neighbors(of: vertex) }
    func incidentEdges(of vertex: Int) -> [Int] { base.incidentEdges(of: vertex) }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
    var vertexIndexBound: Int? { base.vertexIndexBound }
    func vertexIndex(of vertex: Int) -> Int { base.vertexIndex(of: vertex) }
    func vertex(atIndex index: Int) -> Int { base.vertex(atIndex: index) }
    var edgeIndexBound: Int? { base.edgeIndexBound }
    func edgeIndex(of position: Int) -> Int { position }
    static var _lendsIncidentRowsInConstantTime: Bool { true }
    func _withIncidentIndexRows<Result>(
        _ body: (_ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>, _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        neighbors.withUnsafeBufferPointer { t in
            neighborRows.withUnsafeBufferPointer { tr in
                incident.withUnsafeBufferPointer { e in incidentRows.withUnsafeBufferPointer { er in body(t, tr, e, er) } }
            }
        }
    }
}

/// An undirected pseudograph whose positions are not its edge indices, lending incident rows of
/// edge indices in constant time: the edge at offset `k` is at position `100 + k`, or, gapped, at
/// `-1` for the first and `k` for the rest (so `edges` still ends at `edgeCount`). A search must
/// not read those indices as positions.
private struct OffsetPositionsGraph: Graph {
    struct Edges: Collection {
        let base: [UndirectedEdge<Int>]
        let gapped: Bool
        func position(_ k: Int) -> Int { gapped ? (k == 0 ? -1 : k) : 100 + k }
        func offset(_ p: Int) -> Int { gapped ? (p == -1 ? 0 : p) : p - 100 }
        var startIndex: Int { base.isEmpty ? endIndex : position(0) }
        var endIndex: Int { gapped ? base.count : 100 + base.count }
        func index(after i: Int) -> Int { gapped && i == -1 ? 1 : i + 1 }
        subscript(position: Int) -> UndirectedEdge<Int> { base[offset(position)] }
    }

    let base: PooledGraph
    let gapped: Bool

    var vertices: [Int] { base.vertices }
    var edges: Edges { Edges(base: base.edges, gapped: gapped) }
    func neighbors(of vertex: Int) -> [Int] { base.neighbors(of: vertex) }
    func incidentEdges(of vertex: Int) -> [Int] { base.incidentEdges(of: vertex).map { edges.position($0) } }
    func contains(_ vertex: Int) -> Bool { base.contains(vertex) }
    var vertexIndexBound: Int? { base.vertexIndexBound }
    func vertexIndex(of vertex: Int) -> Int { base.vertexIndex(of: vertex) }
    func vertex(atIndex index: Int) -> Int { base.vertex(atIndex: index) }
    var edgeIndexBound: Int? { base.edgeIndexBound }
    func edgeIndex(of position: Int) -> Int { edges.offset(position) }
    static var _lendsIncidentRowsInConstantTime: Bool { true }
    func _withIncidentIndexRows<Result>(
        _ body: (_ neighbors: UnsafeBufferPointer<Int>, _ neighborRows: UnsafeBufferPointer<Int>, _ edges: UnsafeBufferPointer<Int>, _ edgeRows: UnsafeBufferPointer<Int>) -> Result
    ) -> Result? {
        base._withIncidentIndexRows(body)
    }
}

@Suite("Edge-position searches")
struct EdgeSearchTests {
    @Test("TR-212 directed: each position's endpoints give the endpoint search's transcript, on every representation")
    func directedMatchesEndpointSearch() async {
        // Up to 14 edges on 0..<6, repeats and self-loops allowed, a source, and a depth limit
        // (0 for none).
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 3)) { raw, source, limit in
            let edges = raw.map { DirectedEdge(from: $0.0, to: $0.1) }
            let depthLimit = limit == 0 ? nil : limit
            func check<G: DirectedGraph<Int>>(_ g: G, _ name: String) {
                func endpoints(_ e: G.Edges.Index) -> DirectedEdge<Int> {
                    DirectedEdge(from: g.source(ofEdgeAt: e), to: g.target(ofEdgeAt: e))
                }
                var breadth: [BreadthFirstSearchEvent<Int>] = []
                var positions: [G.Edges.Index] = []
                for event in g.edgeBreadthFirstSearch(from: source, depthLimit: depthLimit) {
                    switch event {
                    case .discover(let v): breadth.append(.discover(v))
                    case .treeEdge(let e): breadth.append(.treeEdge(endpoints(e))); positions.append(e)
                    case .nonTreeEdge(let e): breadth.append(.nonTreeEdge(endpoints(e))); positions.append(e)
                    case .finish(let v): breadth.append(.finish(v))
                    }
                }
                #expect(breadth == Array(g.breadthFirstSearch(from: source, depthLimit: depthLimit)), "\(name) \(raw)")
                #expect(Set(positions).count == positions.count, "\(name): a position reported twice")
                var depth: [DepthFirstSearchEvent<Int>] = []
                positions = []
                for event in g.edgeDepthFirstSearch(depthLimit: depthLimit) {
                    switch event {
                    case .discover(let v): depth.append(.discover(v))
                    case .treeEdge(let e): depth.append(.treeEdge(endpoints(e))); positions.append(e)
                    case .backEdge(let e): depth.append(.backEdge(endpoints(e))); positions.append(e)
                    case .forwardEdge(let e): depth.append(.forwardEdge(endpoints(e))); positions.append(e)
                    case .crossEdge(let e): depth.append(.crossEdge(endpoints(e))); positions.append(e)
                    case .finish(let v): depth.append(.finish(v))
                    }
                }
                #expect(depth == Array(g.depthFirstSearch(depthLimit: depthLimit)), "\(name) \(raw)")
                #expect(Set(positions).count == positions.count, "\(name): a position reported twice")
                if depthLimit == nil {
                    #expect(positions.count == g.edgeCount, "\(name): every edge once")
                }
                // From a list of roots, a repeated one skipped.
                let roots = [source, (source + 1) % 6, source]
                let fromRoots = g.edgeDepthFirstSearch(from: roots, depthLimit: depthLimit).map { event -> DepthFirstSearchEvent<Int> in
                    switch event {
                    case .discover(let v): .discover(v)
                    case .treeEdge(let e): .treeEdge(endpoints(e))
                    case .backEdge(let e): .backEdge(endpoints(e))
                    case .forwardEdge(let e): .forwardEdge(endpoints(e))
                    case .crossEdge(let e): .crossEdge(endpoints(e))
                    case .finish(let v): .finish(v)
                    }
                }
                #expect(fromRoots == Array(g.depthFirstSearch(from: roots, depthLimit: depthLimit)), "\(name) \(raw)")
                // prune(): the same vertex pruned in both searches.
                let pruned = (source + 2) % 6
                var prunedDepth: [DepthFirstSearchEvent<Int>] = []
                var edgeDepth = g.edgeDepthFirstSearch(depthLimit: depthLimit).makeIterator()
                while let event = edgeDepth.next() {
                    switch event {
                    case .discover(let v): prunedDepth.append(.discover(v)); if v == pruned { edgeDepth.prune() }
                    case .treeEdge(let e): prunedDepth.append(.treeEdge(endpoints(e)))
                    case .backEdge(let e): prunedDepth.append(.backEdge(endpoints(e)))
                    case .forwardEdge(let e): prunedDepth.append(.forwardEdge(endpoints(e)))
                    case .crossEdge(let e): prunedDepth.append(.crossEdge(endpoints(e)))
                    case .finish(let v): prunedDepth.append(.finish(v))
                    }
                }
                var endpointDepth: [DepthFirstSearchEvent<Int>] = []
                var depthSearch = g.depthFirstSearch(depthLimit: depthLimit).makeIterator()
                while let event = depthSearch.next() {
                    endpointDepth.append(event)
                    if event == .discover(pruned) { depthSearch.prune() }
                }
                #expect(prunedDepth == endpointDepth, "\(name) pruned \(raw)")
                var prunedBreadth: [BreadthFirstSearchEvent<Int>] = []
                var edgeBreadth = g.edgeBreadthFirstSearch(from: source, depthLimit: depthLimit).makeIterator()
                while let event = edgeBreadth.next() {
                    switch event {
                    case .discover(let v): prunedBreadth.append(.discover(v)); if v == pruned { edgeBreadth.prune() }
                    case .treeEdge(let e): prunedBreadth.append(.treeEdge(endpoints(e)))
                    case .nonTreeEdge(let e): prunedBreadth.append(.nonTreeEdge(endpoints(e)))
                    case .finish(let v): prunedBreadth.append(.finish(v))
                    }
                }
                var endpointBreadth: [BreadthFirstSearchEvent<Int>] = []
                var breadthIterator = g.breadthFirstSearch(from: source, depthLimit: depthLimit).makeIterator()
                while let event = breadthIterator.next() {
                    endpointBreadth.append(event)
                    if event == .discover(pruned) { breadthIterator.prune() }
                }
                #expect(prunedBreadth == endpointBreadth, "\(name) pruned \(raw)")
                // forEach, which reads lent rows with integer cursors, reports the iterator's events.
                var pushedBreadth: [EdgeBreadthFirstSearchEvent<Int, G.Edges.Index>] = []
                func pushBreadth(_ event: EdgeBreadthFirstSearchEvent<Int, G.Edges.Index>) { pushedBreadth.append(event) }
                let breadthSearch = g.edgeBreadthFirstSearch(from: [source, (source + 1) % 6, source], depthLimit: depthLimit)
                breadthSearch.forEach(pushBreadth)
                #expect(pushedBreadth == Array(breadthSearch), "\(name) forEach \(raw)")
                var pushedDepth: [EdgeDepthFirstSearchEvent<Int, G.Edges.Index>] = []
                func pushDepth(_ event: EdgeDepthFirstSearchEvent<Int, G.Edges.Index>) { pushedDepth.append(event) }
                for search in [g.edgeDepthFirstSearch(depthLimit: depthLimit), g.edgeDepthFirstSearch(from: roots, depthLimit: depthLimit)] {
                    pushedDepth = []
                    search.forEach(pushDepth)
                    #expect(pushedDepth == Array(search), "\(name) forEach \(raw)")
                }
            }
            check(CompressedSparseRow(vertexCount: 6, edges: edges), "CompressedSparseRow")
            check(AdjacencyMatrix(vertexCount: 6, edges: edges), "AdjacencyMatrix")
            check(AdjacencyList(vertices: 0 ..< 6, edges: edges), "AdjacencyList")
            check(DirectedPseudograph(vertices: 0 ..< 6, edges: edges), "DirectedPseudograph")
            check(ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: edges), "ReferenceDirectedMultigraph")
            check(UnindexedDirectedGraph(base: ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: edges)), "unindexed")
            check(PooledDirectedGraph(ReferenceDirectedMultigraph(vertices: 0 ..< 6, edges: edges)), "pooled rows")
            // Holes in the vertex and edge positions: the searches number the live vertices.
            var stable = StableDirectedGraph(vertices: 0 ..< 7, edges: [DirectedEdge(from: 6, to: 6)] + edges)
            _ = stable.remove(6)
            #expect(stable.vertexIndexBound == nil)
            check(stable, "StableDirectedGraph with holes")
        }
    }

    @Test("TR-213 undirected: each edge once, at the first row that reaches it, on every representation")
    func undirectedMatchesOracle() async {
        // Up to 14 edges on 0..<6, repeats and self-loops allowed, a source, a depth limit (0 for
        // none), and a vertex to prune (6 for none).
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 14)
        await propertyCheck(count: 200, input: pairs, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 3), Gen.int(in: 0 ... 6)) { raw, source, limit, prunedVertex in
            let edges = raw.map { UndirectedEdge($0.0, $0.1) }
            let depthLimit = limit == 0 ? nil : limit
            func check<G: Graph<Int>>(_ g: G, _ name: String) {
                // Oracle: each vertex's incident row walked in order, an edge reported only the
                // first time a row reaches it (Boost's undirected_dfs edge colours).
                func expectedDepthFirst(_ roots: [Int]) -> [String] {
                    var discovery: [Int: Int] = [:]
                    var finished: Set<Int> = []
                    var reached: Set<G.Edges.Index> = []
                    var events: [String] = []
                    for root in roots where discovery[root] == nil {
                        discovery[root] = discovery.count
                        events.append("discover(\(root))")
                        let explore = root != prunedVertex && depthLimit != 0
                        var stack: [(vertex: Int, row: [G.Edges.Index], next: Int)] = [(root, explore ? Array(g.incidentEdges(of: root)) : [], 0)]
                        while let top = stack.last {
                            if top.next == top.row.count {
                                stack.removeLast()
                                finished.insert(top.vertex)
                                events.append("finish(\(top.vertex))")
                                continue
                            }
                            let e = top.row[top.next]
                            stack[stack.count - 1].next += 1
                            guard reached.insert(e).inserted else { continue }
                            let w = g.oppositeVertex(to: top.vertex, acrossEdgeAt: e)
                            if discovery[w] == nil {
                                events.append("treeEdge(\(e))")
                                discovery[w] = discovery.count
                                events.append("discover(\(w))")
                                let deep = depthLimit.map { stack.count >= $0 } ?? false
                                stack.append((w, w == prunedVertex || deep ? [] : Array(g.incidentEdges(of: w)), 0))
                            } else if !finished.contains(w) {
                                events.append("backEdge(\(e))")
                            } else {
                                events.append(discovery[w]! > discovery[top.vertex]! ? "forwardEdge(\(e))" : "crossEdge(\(e))")
                            }
                        }
                    }
                    return events
                }
                func expectedBreadthFirst() -> [String] {
                    var depth: [Int: Int] = [source: 0]
                    var reached: Set<G.Edges.Index> = []
                    var events = ["discover(\(source))"]
                    var queue = [source]
                    var head = 0
                    while head < queue.count {
                        let u = queue[head]
                        head += 1
                        if u != prunedVertex, depthLimit.map({ depth[u]! < $0 }) ?? true {
                            for e in g.incidentEdges(of: u) where reached.insert(e).inserted {
                                let w = g.oppositeVertex(to: u, acrossEdgeAt: e)
                                if depth[w] == nil {
                                    depth[w] = depth[u]! + 1
                                    queue.append(w)
                                    events += ["treeEdge(\(e))", "discover(\(w))"]
                                } else {
                                    events.append("nonTreeEdge(\(e))")
                                }
                            }
                        }
                        events.append("finish(\(u))")
                    }
                    return events
                }
                var breadth: [String] = []
                var bfs = g.edgeBreadthFirstSearch(from: source, depthLimit: depthLimit).makeIterator()
                while let event = bfs.next() {
                    breadth.append(event.description)
                    if event == .discover(prunedVertex) { bfs.prune() }
                }
                #expect(breadth == expectedBreadthFirst(), "\(name) \(raw)")
                var depthFirst: [String] = []
                var dfs = g.edgeDepthFirstSearch(depthLimit: depthLimit).makeIterator()
                while let event = dfs.next() {
                    depthFirst.append(event.description)
                    if event == .discover(prunedVertex) { dfs.prune() }
                }
                #expect(depthFirst == expectedDepthFirst(Array(g.vertices)), "\(name) \(raw)")
                let roots = [source, (source + 3) % 6, source]
                var rooted: [String] = []
                var fromRoots = g.edgeDepthFirstSearch(from: roots, depthLimit: depthLimit).makeIterator()
                while let event = fromRoots.next() {
                    rooted.append(event.description)
                    if event == .discover(prunedVertex) { fromRoots.prune() }
                }
                #expect(rooted == expectedDepthFirst(roots), "\(name) \(raw)")
                // forEach, which reads lent rows with integer cursors, reports the iterator's events.
                var pushedBreadth: [EdgeBreadthFirstSearchEvent<Int, G.Edges.Index>] = []
                func pushBreadth(_ event: EdgeBreadthFirstSearchEvent<Int, G.Edges.Index>) { pushedBreadth.append(event) }
                let breadthSearch = g.edgeBreadthFirstSearch(from: [source, (source + 2) % 6], depthLimit: depthLimit)
                breadthSearch.forEach(pushBreadth)
                #expect(pushedBreadth == Array(breadthSearch), "\(name) forEach \(raw)")
                var pushedDepth: [EdgeDepthFirstSearchEvent<Int, G.Edges.Index>] = []
                func pushDepth(_ event: EdgeDepthFirstSearchEvent<Int, G.Edges.Index>) { pushedDepth.append(event) }
                for search in [g.edgeDepthFirstSearch(depthLimit: depthLimit), g.edgeDepthFirstSearch(from: roots, depthLimit: depthLimit)] {
                    pushedDepth = []
                    search.forEach(pushDepth)
                    #expect(pushedDepth == Array(search), "\(name) forEach \(raw)")
                }
                // Unpruned and unlimited: every edge once, tree and back edges only, and the
                // vertices in the order the endpoint search on `directedView` visits them.
                let whole = Array(g.edgeDepthFirstSearch())
                var classes: [String: Int] = [:]
                var positions: [G.Edges.Index] = []
                for event in whole {
                    switch event {
                    case .treeEdge(let e): classes["tree", default: 0] += 1; positions.append(e)
                    case .backEdge(let e): classes["back", default: 0] += 1; positions.append(e)
                    case .forwardEdge(let e), .crossEdge(let e): classes["other", default: 0] += 1; positions.append(e)
                    case .discover, .finish: break
                    }
                }
                #expect(positions.count == g.edgeCount && Set(positions).count == g.edgeCount, "\(name) \(raw)")
                #expect(classes["other"] == nil, "\(name) \(raw)")
                let vertexEvents = whole.compactMap { event -> String? in
                    switch event {
                    case .discover(let v): "D\(v)"
                    case .finish(let v): "X\(v)"
                    default: nil
                    }
                }
                let viewVertexEvents = g.directedView.depthFirstSearch().compactMap { event -> String? in
                    switch event {
                    case .discover(let v): "D\(v)"
                    case .finish(let v): "X\(v)"
                    default: nil
                    }
                }
                #expect(vertexEvents == viewVertexEvents, "\(name) \(raw)")
            }
            check(ReferencePseudograph(vertices: 0 ..< 6, edges: edges), "ReferencePseudograph")
            check(Pseudograph(vertices: 0 ..< 6, edges: edges), "Pseudograph")
            check(UndirectedAdjacencyList(vertices: 0 ..< 6, edges: edges), "UndirectedAdjacencyList")
            check(UnindexedGraph(base: ReferencePseudograph(vertices: 0 ..< 6, edges: edges)), "unindexed")
            check(PooledGraph(ReferencePseudograph(vertices: 0 ..< 6, edges: edges)), "pooled rows")
            check(OffsetPositionsGraph(base: PooledGraph(ReferencePseudograph(vertices: 0 ..< 6, edges: edges)), gapped: false), "edge indices that are not positions")
            check(OffsetPositionsGraph(base: PooledGraph(ReferencePseudograph(vertices: 0 ..< 6, edges: edges)), gapped: true), "edge indices that are not positions, gapped")
        }
    }

    @Test("TR-214 parallel edges in a DirectedPseudograph: each copy at the position insert returned")
    func directedPseudographCopies() {
        var graph = DirectedPseudograph(vertices: [0, 1, 2])
        let first = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let second = graph.insert(edge: DirectedEdge(from: 0, to: 1))
        let back = graph.insert(edge: DirectedEdge(from: 1, to: 0))
        let loop = graph.insert(edge: DirectedEdge(from: 1, to: 1))
        let onward = graph.insert(edge: DirectedEdge(from: 1, to: 2))
        #expect(Array(graph.edgeDepthFirstSearch(from: 0)) == [
            .discover(0), .treeEdge(first), .discover(1), .backEdge(back), .backEdge(loop), .treeEdge(onward),
            .discover(2), .finish(2), .finish(1), .forwardEdge(second), .finish(0),
        ])
        #expect(Array(graph.edgeBreadthFirstSearch(from: 0)) == [
            .discover(0), .treeEdge(first), .discover(1), .nonTreeEdge(second), .finish(0),
            .nonTreeEdge(back), .nonTreeEdge(loop), .treeEdge(onward), .discover(2), .finish(1), .finish(2),
        ])
        // A weight per copy, read at the reported positions: the cheaper copy is the forward edge.
        let weight = [first: 5, second: 2, back: 1, loop: 1, onward: 1]
        let forward = graph.edgeDepthFirstSearch(from: 0).compactMap { if case .forwardEdge(let e) = $0 { weight[e] } else { nil } }
        #expect(forward == [2])
    }

    @Test("TR-215 a parallel edge to the parent in a Pseudograph is a back edge; the tree edge is not reported twice")
    func pseudographParent() {
        var graph = Pseudograph(vertices: [0, 1, 2])
        let tree = graph.insert(edge: UndirectedEdge(0, 1))
        let parallel = graph.insert(edge: UndirectedEdge(1, 0))
        let loop = graph.insert(edge: UndirectedEdge(1, 1))
        let onward = graph.insert(edge: UndirectedEdge(2, 1))
        let events = Array(graph.edgeDepthFirstSearch(from: 0))
        #expect(events.filter { $0 == .treeEdge(tree) }.count == 1)
        #expect(events.filter { $0 == .backEdge(parallel) }.count == 1)
        #expect(events.filter { $0 == .backEdge(loop) }.count == 1)
        #expect(events.contains(.treeEdge(onward)))
        #expect(events.count == 2 * 3 + 4)
        let breadth = Array(graph.edgeBreadthFirstSearch(from: 0))
        #expect(breadth.filter { $0 == .treeEdge(tree) }.count == 1)
        #expect(breadth.filter { $0 == .nonTreeEdge(parallel) }.count == 1)
        #expect(breadth.filter { $0 == .nonTreeEdge(loop) }.count == 1)
        #expect(breadth.count == 2 * 3 + 4)
        // The endpoint search on the directed view reports both arcs of every edge.
        #expect(graph.directedView.depthFirstSearch(from: 0).filter { if case .discover = $0 { false } else if case .finish = $0 { false } else { true } }.count == 8)
    }

    @Test("TR-216 prune: a directed vertex's out-edges are skipped and it is still finished")
    func directedPrune() {
        // petgraph's dfs_visit graph (TR-81), with positions in written order.
        let graph = ReferenceDirectedMultigraph(edges: [
            DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3), DirectedEdge(from: 0, to: 5),
            DirectedEdge(from: 1, to: 3), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 2, to: 4), DirectedEdge(from: 4, to: 0),
            DirectedEdge(from: 4, to: 5),
        ])
        var depthFirst = graph.edgeDepthFirstSearch(from: 0).makeIterator()
        var events: [EdgeDepthFirstSearchEvent<Int, Int>] = []
        while let event = depthFirst.next() {
            events.append(event)
            if event == .discover(2) { depthFirst.prune() }
        }
        #expect(events == [
            .discover(0), .treeEdge(0), .discover(1), .treeEdge(4), .discover(3), .finish(3), .finish(1),
            .treeEdge(1), .discover(2), .finish(2), .forwardEdge(2), .treeEdge(3), .discover(5), .finish(5), .finish(0),
        ])
        var breadthFirst = graph.edgeBreadthFirstSearch(from: 0).makeIterator()
        var breadth: [EdgeBreadthFirstSearchEvent<Int, Int>] = []
        while let event = breadthFirst.next() {
            breadth.append(event)
            if event == .discover(2) { breadthFirst.prune() }
        }
        #expect(breadth == [
            .discover(0), .treeEdge(0), .discover(1), .treeEdge(1), .discover(2), .treeEdge(2), .discover(3), .treeEdge(3), .discover(5),
            .finish(0), .nonTreeEdge(4), .finish(1), .finish(2), .finish(3), .finish(5),
        ])
        // Pruning the root.
        var root = graph.edgeDepthFirstSearch(from: 0).makeIterator()
        #expect(root.next() == .discover(0))
        root.prune()
        #expect(root.next() == .finish(0))
        #expect(root.next() == nil)
    }

    @Test("TR-217 several sources, a repeated one ignored, and String vertices")
    func sourcesAndLabels() {
        let graph = ReferenceDirectedMultigraph(edges: [DirectedEdge(from: "a", to: "b"), DirectedEdge(from: "c", to: "b"), DirectedEdge(from: "b", to: "a")])
        #expect(graph.edgeBreadthFirstSearch(from: ["c", "a", "c"]).map(\.description) == [
            "discover(c)", "discover(a)", "treeEdge(1)", "discover(b)", "finish(c)", "nonTreeEdge(0)", "finish(a)", "nonTreeEdge(2)", "finish(b)",
        ])
        #expect(Array(graph.edgeBreadthFirstSearch(from: ["a", "a"])) == Array(graph.edgeBreadthFirstSearch(from: "a")))
        #expect(Array(graph.edgeDepthFirstSearch(from: ["a"])) == Array(graph.edgeDepthFirstSearch(from: "a")))
        let undirected = ReferencePseudograph(edges: [UndirectedEdge("a", "b"), UndirectedEdge("c", "b")])
        #expect(undirected.edgeBreadthFirstSearch(from: ["c", "a"]).map(\.description) == [
            "discover(c)", "discover(a)", "treeEdge(1)", "discover(b)", "finish(c)", "nonTreeEdge(0)", "finish(a)", "finish(b)",
        ])
        #expect(Array(undirected.edgeDepthFirstSearch(from: ["a"])) == Array(undirected.edgeDepthFirstSearch(from: "a")))
    }

    @Test("TR-218 the search holds a copy, iterates again, and its events are Hashable, Sendable and readable")
    func valueSemantics() async {
        var graph = DirectedPseudograph(edges: [DirectedEdge(from: 0, to: 1)])
        let search = graph.edgeDepthFirstSearch(from: 0)
        _ = graph.insert(edge: DirectedEdge(from: 1, to: 0))
        #expect(Array(search) == [.discover(0), .treeEdge(0), .discover(1), .finish(1), .finish(0)])
        #expect(Array(search) == Array(search))
        #expect(Array(graph.edgeDepthFirstSearch(from: 0)).contains(.backEdge(1)))
        let undirected = Pseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let events = await Task { Array(undirected.edgeBreadthFirstSearch(from: 0)) }.value
        #expect(Set(events).count == events.count)
        #expect(EdgeDepthFirstSearchEvent<Int, Int>.crossEdge(7).description == "crossEdge(7)")
        #expect(EdgeBreadthFirstSearchEvent<Int, Int>.nonTreeEdge(3).description == "nonTreeEdge(3)")
    }

    @Test("TR-220 forEach stops at the first error and rethrows it, over lent rows and without them")
    func forEachThrows() {
        struct Stop: Error {}
        let edges = [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)]
        func check<G: DirectedGraph<Int>>(_ g: G) {
            var seen = 0
            func depthBody(_ event: EdgeDepthFirstSearchEvent<Int, G.Edges.Index>) throws(Stop) {
                seen += 1
                if case .treeEdge = event { throw Stop() }
            }
            #expect(throws: Stop.self) { try g.edgeDepthFirstSearch(from: 0).forEach(depthBody) }
            #expect(seen == 2)
            seen = 0
            func breadthBody(_ event: EdgeBreadthFirstSearchEvent<Int, G.Edges.Index>) throws(Stop) {
                seen += 1
                if case .discover(1) = event { throw Stop() }
            }
            #expect(throws: Stop.self) { try g.edgeBreadthFirstSearch(from: 0).forEach(breadthBody) }
            #expect(seen == 3)
        }
        check(CompressedSparseRow(vertexCount: 3, edges: edges))
        check(AdjacencyList(edges: edges))
        check(ReferenceDirectedMultigraph(edges: edges))
        func checkUndirected<G: Graph<Int>>(_ g: G) {
            var seen = 0
            func depthBody(_ event: EdgeDepthFirstSearchEvent<Int, G.Edges.Index>) throws(Stop) {
                seen += 1
                if case .backEdge = event { throw Stop() }
            }
            #expect(throws: Stop.self) { try g.edgeDepthFirstSearch(from: 0).forEach(depthBody) }
            #expect(seen == 6)
            seen = 0
            func breadthBody(_ event: EdgeBreadthFirstSearchEvent<Int, G.Edges.Index>) throws(Stop) {
                seen += 1
                if case .nonTreeEdge = event { throw Stop() }
            }
            #expect(throws: Stop.self) { try g.edgeBreadthFirstSearch(from: 0).forEach(breadthBody) }
            #expect(seen == 7)
        }
        let undirected = edges.map { UndirectedEdge($0.source, $0.target) }
        checkUndirected(UndirectedAdjacencyList(edges: undirected))
        checkUndirected(ReferencePseudograph(edges: undirected))
    }

    @Test("TR-221 views whose edge indices are not their positions, or whose rows are built per call: forEach, the iterator and the endpoint search agree")
    func viewsAgree() async {
        // Up to 14 edges on 0..<6, repeats and self-loops allowed, a source, and a vertex to drop.
        let pairs = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 14)
        let members = Gen.int(in: 0 ... 5).array(of: 0 ... 3).array(of: 0 ... 6)
        await propertyCheck(count: 150, input: pairs, members, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)) { raw, hyperedges, source, dropped in
            func check<G: Graph<Int>>(_ g: G, from start: Int, _ name: String) {
                // The iterator, pushed and pulled, and the endpoint search on `directedView`.
                func vertexEvents(_ events: [EdgeDepthFirstSearchEvent<Int, G.Edges.Index>]) -> [String] {
                    events.compactMap { if case .discover(let v) = $0 { "D\(v)" } else if case .finish(let v) = $0 { "X\(v)" } else { nil } }
                }
                func treeEdges(_ events: [EdgeDepthFirstSearchEvent<Int, G.Edges.Index>]) -> [UndirectedEdge<Int>] {
                    events.compactMap { if case .treeEdge(let e) = $0 { g.edges[e] } else { nil } }
                }
                let depthSearch = g.edgeDepthFirstSearch()
                var pushedDepth: [EdgeDepthFirstSearchEvent<Int, G.Edges.Index>] = []
                func pushDepth(_ event: EdgeDepthFirstSearchEvent<Int, G.Edges.Index>) { pushedDepth.append(event) }
                depthSearch.forEach(pushDepth)
                let pulledDepth = Array(depthSearch)
                #expect(pushedDepth == pulledDepth, "\(name) \(raw) \(hyperedges)")
                let endpoint = Array(g.directedView.depthFirstSearch())
                let endpointVertices = endpoint.compactMap { if case .discover(let v) = $0 { "D\(v)" } else if case .finish(let v) = $0 { "X\(v)" } else { nil } }
                let endpointTree = endpoint.compactMap { if case .treeEdge(let e) = $0 { UndirectedEdge(e.source, e.target) } else { nil } }
                #expect(vertexEvents(pulledDepth) == endpointVertices, "\(name) \(raw) \(hyperedges)")
                #expect(treeEdges(pulledDepth) == endpointTree, "\(name) \(raw) \(hyperedges)")
                let positions = pulledDepth.compactMap { event -> G.Edges.Index? in
                    switch event {
                    case .treeEdge(let e), .backEdge(let e), .forwardEdge(let e), .crossEdge(let e): e
                    case .discover, .finish: nil
                    }
                }
                #expect(positions.count == g.edgeCount && Set(positions) == Set(g.edges.indices), "\(name) \(raw) \(hyperedges)")
                let breadthSearch = g.edgeBreadthFirstSearch(from: start)
                var pushedBreadth: [EdgeBreadthFirstSearchEvent<Int, G.Edges.Index>] = []
                func pushBreadth(_ event: EdgeBreadthFirstSearchEvent<Int, G.Edges.Index>) { pushedBreadth.append(event) }
                breadthSearch.forEach(pushBreadth)
                let pulledBreadth = Array(breadthSearch)
                #expect(pushedBreadth == pulledBreadth, "\(name) \(raw) \(hyperedges)")
                let endpointBreadth = Array(g.directedView.breadthFirstSearch(from: start))
                #expect(pulledBreadth.compactMap { if case .discover(let v) = $0 { v } else { nil } } == endpointBreadth.compactMap { if case .discover(let v) = $0 { v } else { nil } }, "\(name) \(raw) \(hyperedges)")
                #expect(pulledBreadth.compactMap { if case .treeEdge(let e) = $0 { g.edges[e] } else { nil } } == endpointBreadth.compactMap { if case .treeEdge(let e) = $0 { UndirectedEdge(e.source, e.target) } else { nil } }, "\(name) \(raw) \(hyperedges)")
            }
            let base = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            let pseudo = Pseudograph(vertices: 0 ..< 6, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            // Every other edge kept: positions are the base's, edge indices their ranks.
            let kept = pseudo.edges.indices.filter { $0 % 2 == 0 }
            check(pseudo.spanningSubgraphView(edges: kept), from: source, "spanning subgraph")
            check(base.spanningSubgraphView(edges: base.edges.indices.filter { $0 % 2 == 1 }), from: source, "spanning subgraph of a simple graph")
            // A vertex dropped: vertex indices renumbered, edges filtered with it.
            let others = (0 ..< 6).filter { $0 != dropped }
            check(pseudo.inducedSubgraphView(on: others), from: dropped == source ? (source + 1) % 6 : source, "induced subgraph")
            check(pseudo.subgraphView(vertices: others, edges: kept), from: dropped == source ? (source + 1) % 6 : source, "subgraph")
            // Every vertex and edge kept: the view lends the base's rows.
            check(pseudo.spanningSubgraphView(edges: pseudo.edges.indices), from: source, "whole subgraph")
            // An incidence graph builds its rows on each call.
            let hypergraph = UndirectedIncidenceList(vertices: 0 ..< 6, hyperedges: hyperedges)
            check(hypergraph.incidenceGraphView, from: source, "incidence graph")
        }
    }

    @Test("TR-219 a source that is not a vertex, a negative depth limit, and a misplaced prune trap")
    func preconditions() async {
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).edgeBreadthFirstSearch(from: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).edgeDepthFirstSearch(from: [0, 9])
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph(vertices: [0]).edgeDepthFirstSearch(from: 9)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph(vertices: [0]).edgeBreadthFirstSearch(from: [9])
        }
        await #expect(processExitsWith: .failure) {
            _ = CompressedSparseRow(vertexCount: 2).edgeDepthFirstSearch(depthLimit: -1)
        }
        await #expect(processExitsWith: .failure) {
            _ = Pseudograph(vertices: [0]).edgeBreadthFirstSearch(from: 0, depthLimit: -1)
        }
        await #expect(processExitsWith: .failure) {
            var search = CompressedSparseRow(vertexCount: 2, edges: [DirectedEdge(from: 0, to: 1)]).edgeDepthFirstSearch().makeIterator()
            _ = search.next()
            _ = search.next()
            // The last event was a tree edge.
            search.prune()
        }
        await #expect(processExitsWith: .failure) {
            var search = Pseudograph(vertices: [0]).edgeBreadthFirstSearch(from: 0).makeIterator()
            search.prune()
        }
    }
}
