// The Flows section: maximum flows, cuts, Gomory–Hu trees, minimum-cost flows and connectivity on
// a multigraph built from the case (scripts/differential.py's flow_case: the case's edges, then a
// parallel copy of every fourth), and a catalog mode that answers the rows of
// Tests/Catalogs/Flows/cases.md one request at a time.

import Flows
import Foundation
import GraphProtocols
import Multigraphs

/// The case's flow network: edges as [u, v, capacity, cost] in position order, supplies, and a
/// source and sink (equal when the case has one vertex).
struct FlowCase: Decodable {
    let edges: [[Int]]
    let supply: [Int]
    let source: Int
    let sink: Int
}

struct CutAnswer: Encodable {
    var value: String
    var sink: [Int]
    var edges: [String]
}

struct FlowAnswer: Encodable {
    var value: String
    /// Per edge; on an undirected graph the signed flow along the stored order.
    var flows: [String]
    var cut: CutAnswer
}

struct CostAnswer: Encodable {
    var cost: Int
    var value: Int
    var flows: [Int]
    var potentials: [Int]
}

struct FlowAnswers: Encodable {
    var maximum: FlowAnswer?
    var edmondsKarp: FlowAnswer?
    var dinic: FlowAnswer?
    var value: String?
    var cut: CutAnswer?
    /// The same queries on `directed` of an undirected case (each edge two independent arcs).
    var viewValue: String?
    var viewCut: CutAnswer?
    var global: CutAnswer?
    /// [child, parent, capacity] per tree edge.
    var gomoryHu: [[Int]]?
    /// [u, v, minimumCutValue, minimumCut(between:).value] and the cut's sink side.
    var gomoryHuPairs: [[Int]]?
    var gomoryHuPairSinks: [[Int]]?
    var minimumCostFeasible: Bool?
    var minimumCost: CostAnswer?
    var minimumCostMaximum: CostAnswer?
    var edgeConnectivity: Int?
    var vertexConnectivity: Int?
    var vertexCut: [Int]?
    var localEdge: Int?
    var localVertex: Int?
    var localVertexCut: [Int]?
    var localAdjacent: Bool?
    /// The edge- and vertex-disjoint paths, each as its vertices and its edges (`"3"`, or `"3r"`
    /// for an undirected edge crossed against its stored order).
    var edgePaths: [PathAnswer]?
    var vertexPaths: [PathAnswer]?
    /// Swift-side agreements: lookups through `flow(ofEdgeAt:)` match the edge list, and the
    /// equal-by-definition answers agree.
    var consistent = true
}

struct PathAnswer: Encodable {
    var vertices: [Int]
    var edges: [String]
}

func cutAnswer<G: DirectedGraph<Int>, C>(_ cut: Cut<G, C>, _ name: (G.Edges.Index) -> String) -> CutAnswer {
    CutAnswer(value: "\(cut.value)", sink: Array(cut.sinkSide), edges: cut.edges.map(name))
}

func directedFlowAnswer<G: DirectedGraph<Int>>(_ flow: Flow<G, Int>, _ graph: G) -> FlowAnswer where G.Edges.Index == Int {
    FlowAnswer(value: "\(flow.value)", flows: graph.edges.indices.map { "\(flow.flow(ofEdgeAt: $0))" }, cut: cutAnswer(flow.minimumCut) { "\($0)" })
}

/// Whether `flowMap` lists `flow(ofEdgeAt:)` for every position, in `edges` order.
func flowMapAgrees<G: DirectedGraph>(_ flow: Flow<G, Int>, _ graph: G) -> Bool {
    Array(flow.flowMap) == graph.edges.indices.map { flow.flow(ofEdgeAt: $0) } && Array(flow.flowMap.indices) == Array(graph.edges.indices)
}

func undirectedFlowAnswer<G: Graph<Int>>(_ flow: Flow<DirectedView<G>, Int>, _ graph: G) -> FlowAnswer where G.Edges.Index == Int {
    // The signed accessor by undirected position, the forward arc's flow less the reversed arc's.
    let flows = graph.edges.indices.map { e -> String in "\(flow.flow(ofEdgeAt: e))" }
    return FlowAnswer(value: "\(flow.value)", flows: flows, cut: cutAnswer(flow.minimumCut) { "\($0.position)\($0.reversed ? "r" : "")" })
}

func costAnswer<G: DirectedGraph>(_ result: MinimumCostFlow<G, Int, Int>, _ graph: G, _ n: Int) -> CostAnswer where G.Vertex == Int {
    CostAnswer(cost: result.cost, value: result.value, flows: graph.edges.indices.map { result.flow(ofEdgeAt: $0) }, potentials: (0 ..< n).map { result.potential(of: $0) })
}

/// Pairs for the Gomory–Hu queries: all of them up to 12 vertices, else 40 spread ones.
func gomoryHuQueryPairs(_ n: Int) -> [(Int, Int)] {
    if n <= 12 { return (0 ..< n).flatMap { u in ((u + 1) ..< n).map { (u, $0) } } }
    return (0 ..< 40).compactMap { i in
        let u = (i * 7) % n, v = (i * 13 + 1) % n
        return u == v ? nil : (u, v)
    }
}

func flowAnswers(directed: Bool, n: Int, _ f: FlowCase) -> FlowAnswers {
    var a = FlowAnswers()
    let capacities = f.edges.map { $0[2] }, costs = f.edges.map { $0[3] }
    let s = f.source, t = f.sink
    if directed {
        let graph = DirectedPseudograph(vertices: 0 ..< n, edges: f.edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let capacity: (Int) -> Int = { capacities[$0] }
        if s != t {
            let maximum = graph.maximumFlow(from: s, to: t, capacity: capacity)
            a.maximum = directedFlowAnswer(maximum, graph)
            a.edmondsKarp = directedFlowAnswer(graph.edmondsKarpMaximumFlow(from: s, to: t, capacity: capacity), graph)
            a.dinic = directedFlowAnswer(graph.dinicMaximumFlow(from: s, to: t, capacity: capacity), graph)
            a.value = "\(graph.maximumFlowValue(from: s, to: t, capacity: capacity))"
            let cut = graph.minimumCut(from: s, to: t, capacity: capacity)
            a.cut = cutAnswer(cut) { "\($0)" }
            a.consistent = a.consistent && cut == maximum.minimumCut
            a.localEdge = graph.edgeConnectivity(from: s, to: t)
            a.localVertex = graph.vertexConnectivity(from: s, to: t)
            let local = graph.minimumVertexCut(from: s, to: t)
            a.localVertexCut = local
            a.localAdjacent = local == nil
            a.minimumCostMaximum = costAnswer(graph.minimumCostMaximumFlow(from: s, to: t, capacity: capacity, cost: { costs[$0] }), graph, n)
            a.consistent = a.consistent && flowMapAgrees(maximum, graph)
            a.edgePaths = graph.edgeDisjointPaths(from: s, to: t).map { PathAnswer(vertices: $0.vertices, edges: $0.edges.map { "\($0)" }) }
            a.vertexPaths = graph.vertexDisjointPaths(from: s, to: t).map { PathAnswer(vertices: $0.vertices, edges: $0.edges.map { "\($0)" }) }
        }
        a.global = graph.minimumCut(capacity: capacity).map { cutAnswer($0) { "\($0)" } }
        let result = graph.minimumCostFlow(supply: { f.supply[$0] }, capacity: capacity, cost: { costs[$0] })
        a.minimumCostFeasible = result != nil
        a.minimumCost = result.map { costAnswer($0, graph, n) }
        a.edgeConnectivity = graph.edgeConnectivity()
        a.vertexConnectivity = graph.vertexConnectivity()
        a.vertexCut = graph.minimumVertexCut()
    } else {
        let graph = Pseudograph(vertices: 0 ..< n, edges: f.edges.map { UndirectedEdge($0[0], $0[1]) })
        let capacity: (Int) -> Int = { capacities[$0] }
        let name: (DirectedView<Pseudograph<Int>>.Edges.Index) -> String = { "\($0.position)\($0.reversed ? "r" : "")" }
        let view = graph.directed
        if s != t {
            let maximum = graph.maximumFlow(from: s, to: t, capacity: capacity)
            a.maximum = undirectedFlowAnswer(maximum, graph)
            a.edmondsKarp = undirectedFlowAnswer(graph.edmondsKarpMaximumFlow(from: s, to: t, capacity: capacity), graph)
            a.dinic = undirectedFlowAnswer(graph.dinicMaximumFlow(from: s, to: t, capacity: capacity), graph)
            a.value = "\(graph.maximumFlowValue(from: s, to: t, capacity: capacity))"
            let cut = graph.minimumCut(from: s, to: t, capacity: capacity)
            a.cut = cutAnswer(cut, name)
            a.consistent = a.consistent && cut == maximum.minimumCut
            a.viewValue = "\(view.maximumFlowValue(from: s, to: t) { capacities[$0.position] })"
            a.viewCut = cutAnswer(view.minimumCut(from: s, to: t) { capacities[$0.position] }, name)
            a.localEdge = graph.edgeConnectivity(from: s, to: t)
            a.localVertex = graph.vertexConnectivity(from: s, to: t)
            let local = graph.minimumVertexCut(from: s, to: t)
            a.localVertexCut = local
            a.localAdjacent = local == nil
            let mcmf = view.minimumCostMaximumFlow(from: s, to: t, capacity: { capacities[$0.position] }, cost: { costs[$0.position] })
            a.minimumCostMaximum = costAnswer(mcmf, view, n)
            a.consistent = a.consistent && flowMapAgrees(maximum, view)
            a.edgePaths = graph.edgeDisjointPaths(from: s, to: t).map { PathAnswer(vertices: $0.vertices, edges: $0.edges.map(name)) }
            a.vertexPaths = graph.vertexDisjointPaths(from: s, to: t).map { PathAnswer(vertices: $0.vertices, edges: $0.edges.map(name)) }
        }
        a.global = graph.minimumCut(capacity: capacity).map { cutAnswer($0, name) }
        if let tree = graph.gomoryHuTree(capacity: capacity) {
            a.gomoryHu = tree.tree.edges.indices.map { k in
                let e = tree.tree.edges[k]
                return [e.u, e.v, tree.capacity(ofEdgeAt: k)]
            }
            var pairs: [[Int]] = [], sinks: [[Int]] = []
            for (u, v) in gomoryHuQueryPairs(n) {
                let cut = tree.minimumCut(between: u, and: v)
                pairs.append([u, v, tree.minimumCutValue(between: u, and: v), cut.value])
                sinks.append(Array(cut.sinkSide))
            }
            a.gomoryHuPairs = pairs
            a.gomoryHuPairSinks = sinks
        }
        let result = view.minimumCostFlow(supply: { f.supply[$0] }, capacity: { capacities[$0.position] }, cost: { costs[$0.position] })
        a.minimumCostFeasible = result != nil
        a.minimumCost = result.map { costAnswer($0, view, n) }
        a.edgeConnectivity = graph.edgeConnectivity()
        a.vertexConnectivity = graph.vertexConnectivity()
        a.vertexCut = graph.minimumVertexCut()
    }
    return a
}

// MARK: - Catalog mode

/// One catalog row as a request: the network (capacities as text, parsed in `ctype`), the call,
/// and its terminals.
struct CatalogRequest: Decodable {
    let ctype: String
    let directed: Bool
    let n: Int
    let edges: [[Int]]
    let capacities: [String]
    let costs: [Int]?
    let supply: [Int]?
    let call: String
    let from: Int?
    let to: Int?
}

struct CatalogAnswer: Encodable {
    var value: String?
    var flows: [String]?
    var sink: [Int]?
    var cutEdges: [String]?
    var isNil = false
    var tree: [[String]]?
    var cost: Int?
    var integer: Int?
    var vertices: [Int]?
    var paths: [PathAnswer]?
}

protocol CatalogCapacity: Comparable & AdditiveArithmetic & CustomStringConvertible {
    init?(_ text: String)
}

extension Int: CatalogCapacity {}
extension Int8: CatalogCapacity {}
extension UInt8: CatalogCapacity {}
extension Double: CatalogCapacity {}

func answerCatalog(_ r: CatalogRequest) -> CatalogAnswer {
    switch r.ctype {
    case "Int8": return answerCatalog(r, Int8.self)
    case "UInt8": return answerCatalog(r, UInt8.self)
    case "Double": return answerCatalog(r, Double.self)
    default: return answerCatalog(r, Int.self)
    }
}

func answerCatalog<C: CatalogCapacity>(_ r: CatalogRequest, _: C.Type) -> CatalogAnswer {
    let capacities = r.capacities.map { C($0)! }
    var a = CatalogAnswer()
    let s = r.from ?? 0, t = r.to ?? 0
    func cut<G: DirectedGraph<Int>>(_ c: Cut<G, C>, _ name: (G.Edges.Index) -> String) {
        a.value = "\(c.value)"
        a.sink = Array(c.sinkSide)
        a.cutEdges = c.edges.map(name)
    }
    if r.directed {
        let graph = DirectedPseudograph(vertices: 0 ..< r.n, edges: r.edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let capacity: (Int) -> C = { capacities[$0] }
        let name: (Int) -> String = { "\($0)" }
        switch r.call {
        case "maximumFlow", "dinicMaximumFlow", "edmondsKarpMaximumFlow":
            let flow = r.call == "maximumFlow" ? graph.maximumFlow(from: s, to: t, capacity: capacity)
                : r.call == "dinicMaximumFlow" ? graph.dinicMaximumFlow(from: s, to: t, capacity: capacity)
                : graph.edmondsKarpMaximumFlow(from: s, to: t, capacity: capacity)
            cut(flow.minimumCut, name)
            a.value = "\(flow.value)"
            a.flows = graph.edges.indices.map { "\(flow.flow(ofEdgeAt: $0))" }
        case "maximumFlowValue":
            a.value = "\(graph.maximumFlowValue(from: s, to: t, capacity: capacity))"
        case "minimumCut" where r.from != nil:
            cut(graph.minimumCut(from: s, to: t, capacity: capacity), name)
        case "minimumCut":
            if let c = graph.minimumCut(capacity: capacity) { cut(c, name) } else { a.isNil = true }
        case "minimumCostFlow", "minimumCostMaximumFlow":
            if r.ctype == "Int8" { costCatalog(r, graph, Int8.self, &a) } else { costCatalog(r, graph, Int.self, &a) }
        case "edgeConnectivity":
            a.integer = r.from != nil ? graph.edgeConnectivity(from: s, to: t) : graph.edgeConnectivity()
        case "vertexConnectivity":
            a.integer = r.from != nil ? graph.vertexConnectivity(from: s, to: t) : graph.vertexConnectivity()
        case "minimumVertexCut":
            if r.from != nil {
                if let c = graph.minimumVertexCut(from: s, to: t) { a.vertices = c } else { a.isNil = true }
            } else {
                a.vertices = graph.minimumVertexCut()
            }
        case "edgeDisjointPaths", "vertexDisjointPaths":
            let paths = r.call == "edgeDisjointPaths" ? graph.edgeDisjointPaths(from: s, to: t) : graph.vertexDisjointPaths(from: s, to: t)
            a.integer = paths.count
            a.paths = paths.map { PathAnswer(vertices: $0.vertices, edges: $0.edges.map(name)) }
        default:
            fatalError("unknown call \(r.call)")
        }
    } else {
        let graph = Pseudograph(vertices: 0 ..< r.n, edges: r.edges.map { UndirectedEdge($0[0], $0[1]) })
        let capacity: (Int) -> C = { capacities[$0] }
        let name: (DirectedView<Pseudograph<Int>>.Edges.Index) -> String = { "\($0.position)\($0.reversed ? "r" : "")" }
        switch r.call {
        case "maximumFlow", "dinicMaximumFlow", "edmondsKarpMaximumFlow":
            let flow = r.call == "maximumFlow" ? graph.maximumFlow(from: s, to: t, capacity: capacity)
                : r.call == "dinicMaximumFlow" ? graph.dinicMaximumFlow(from: s, to: t, capacity: capacity)
                : graph.edmondsKarpMaximumFlow(from: s, to: t, capacity: capacity)
            cut(flow.minimumCut, name)
            a.value = "\(flow.value)"
            a.flows = graph.edges.indices.map { e in
                let along = flow.flow(ofEdgeAt: .init(position: e, reversed: false))
                let against = flow.flow(ofEdgeAt: .init(position: e, reversed: true))
                return against == .zero ? "\(along)" : "-\(against)"
            }
        case "maximumFlowValue":
            a.value = "\(graph.maximumFlowValue(from: s, to: t, capacity: capacity))"
        case "minimumCut" where r.from != nil:
            cut(graph.minimumCut(from: s, to: t, capacity: capacity), name)
        case "minimumCut":
            if let c = graph.minimumCut(capacity: capacity) { cut(c, name) } else { a.isNil = true }
        case "gomoryHuTree":
            if let tree = graph.gomoryHuTree(capacity: capacity) {
                a.tree = tree.tree.edges.indices.map { k in
                    let e = tree.tree.edges[k]
                    return ["\(e.u)", "\(e.v)", "\(tree.capacity(ofEdgeAt: k))"]
                }
            } else {
                a.isNil = true
            }
        case "edgeConnectivity":
            a.integer = r.from != nil ? graph.edgeConnectivity(from: s, to: t) : graph.edgeConnectivity()
        case "vertexConnectivity":
            a.integer = r.from != nil ? graph.vertexConnectivity(from: s, to: t) : graph.vertexConnectivity()
        case "minimumVertexCut":
            if r.from != nil {
                if let c = graph.minimumVertexCut(from: s, to: t) { a.vertices = c } else { a.isNil = true }
            } else {
                a.vertices = graph.minimumVertexCut()
            }
        case "edgeDisjointPaths", "vertexDisjointPaths":
            let paths = r.call == "edgeDisjointPaths" ? graph.edgeDisjointPaths(from: s, to: t) : graph.vertexDisjointPaths(from: s, to: t)
            a.integer = paths.count
            a.paths = paths.map { PathAnswer(vertices: $0.vertices, edges: $0.edges.map(name)) }
        default:
            fatalError("unknown call \(r.call)")
        }
    }
    return a
}

/// A minimum-cost row with capacities and costs both of type `K`.
func costCatalog<K: SignedInteger & CatalogCapacity>(_ r: CatalogRequest, _ graph: DirectedPseudograph<Int>, _: K.Type, _ a: inout CatalogAnswer) {
    let capacities = r.capacities.map { K($0)! }
    let costs = (r.costs ?? []).map { K($0) }
    let s = r.from ?? 0, t = r.to ?? 0
    let result = r.call == "minimumCostFlow"
        ? graph.minimumCostFlow(supply: { K(r.supply?[$0] ?? 0) }, capacity: { capacities[$0] }, cost: { costs[$0] })
        : graph.minimumCostMaximumFlow(from: s, to: t, capacity: { capacities[$0] }, cost: { costs[$0] })
    guard let result else {
        a.isNil = true
        return
    }
    a.cost = Int(result.cost)
    a.value = "\(result.value)"
    a.flows = graph.edges.indices.map { "\(result.flow(ofEdgeAt: $0))" }
    // The certificate, checked here: no residual arc with negative reduced cost.
    var valid = true
    for e in graph.edges.indices {
        let u = graph.source(ofEdgeAt: e), v = graph.target(ofEdgeAt: e)
        if u == v { continue }
        let reduced = Int(costs[e]) + Int(result.potential(of: u)) - Int(result.potential(of: v))
        let f = result.flow(ofEdgeAt: e)
        if (f < capacities[e] && reduced < 0) || (f > 0 && reduced > 0) { valid = false }
    }
    a.integer = valid ? 1 : 0
}
