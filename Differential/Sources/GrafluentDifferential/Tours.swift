// The Tours section: Eulerian, Hamiltonian and tour answers on graphs derived from each random
// case (scripts/differential_tours.py's tours_case: the case's own graph, an Eulerian multigraph
// from a walk, and a weighted complete multigraph), and a catalog mode that answers the rows of
// Tests/Catalogs/Tours/cases.md.

import AdjacencyListModule
import CompressedSparseRowModule
import Foundation
import GraphProtocols
import Multigraphs
import Tours
import Walks

/// A walk as vertex numbers (labels in catalog mode) and edge positions.
struct WalkAnswer: Encodable {
    var vertices: [String]
    var edges: [Int]
}

/// Every Eulerian answer for one graph.
struct EulerianAnswers: Encodable {
    var isEulerian = false
    var hasTrail = false
    var circuit: WalkAnswer?
    var trail: WalkAnswer?
    var circuitFrom: WalkAnswer?
    var trailFrom: WalkAnswer?
}

/// The Tours inputs of a random case: the walk multigraph, the weighted complete multigraph (its
/// weights as text in `wtype`), and the queries' parameters.
struct ToursCase: Decodable {
    let walk: [[Int]]
    let complete: [[Int]]
    let completeN: Int
    let weights: [String]
    let wtype: String
    let start: Int
    let improving: [Int]
    let hamiltonian: Bool
    let shortestOnCase: Bool
    let caseWeights: [String]
    /// A larger complete graph (0 vertices for none), integer weights.
    let largeN: Int
    let large: [[Int]]
    let largeWeights: [String]
    /// A complete digraph on `completeN` vertices less some arcs, asymmetric integer weights.
    let directedComplete: [[Int]]
    let directedWeights: [String]
}

struct ToursAnswers: Encodable {
    var graph = EulerianAnswers()
    /// The directed case on a compressed sparse row (its rows sorted), with the edges in position
    /// order.
    var csr: EulerianAnswers?
    var csrEdges: [[Int]]?
    var walk = EulerianAnswers()
    var hamiltonianPath: WalkAnswer?
    var hamiltonianCycle: WalkAnswer?
    var hamiltonianPathFrom: WalkAnswer?
    var hamiltonianPathFromTo: WalkAnswer?
    var csrHamiltonianPath: WalkAnswer?
    var csrHamiltonianCycle: WalkAnswer?
    var nearestNeighbor: WalkAnswer?
    var nearestNeighborFrom: WalkAnswer?
    var twoOpt: WalkAnswer?
    var twoOptImproving: WalkAnswer?
    var christofides: WalkAnswer?
    var shortest: WalkAnswer?
    var shortestOnCase: WalkAnswer?
    var shortestDirected: WalkAnswer?
    var largeNearestNeighbor: WalkAnswer?
    var largeTwoOpt: WalkAnswer?
    var largeChristofides: WalkAnswer?
    /// `chinesePostmanTour` on the case's graph (weights |w|) and on the walk multigraph (weight
    /// position mod 4).
    var postman: PostmanAnswer?
    var postmanWalk: PostmanAnswer?
    /// `simulatedAnnealingTour` and `thresholdAcceptingTour` on the complete multigraph, both moves,
    /// from a SplitMix64 generator seeded with the case's start.
    var annealing: [WalkAnswer?] = []
    var thresholdAccepting: [WalkAnswer?] = []
    /// Whether `edges` lists the graphs' edges in input order (the models assume it).
    var positionsInOrder = true
}

/// A postman tour: its walk, duplicated edge positions and weight as text.
struct PostmanAnswer: Encodable {
    var walk: WalkAnswer
    var duplicated: [Int]
    var weight: String
}

/// SplitMix64, for the metaheuristics' draws.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

func postmanAnswer<V, E, W>(_ tour: PostmanTour<V, E, W>?, _ position: (E) -> Int) -> PostmanAnswer? {
    tour.map { PostmanAnswer(walk: walkAnswer($0.walk.vertices, $0.walk.edges, position), duplicated: $0.duplicatedEdges.map(position), weight: "\($0.weight)") }
}

func walkAnswer<V, E>(_ vertices: [V], _ edges: [E], _ position: (E) -> Int) -> WalkAnswer {
    WalkAnswer(vertices: vertices.map { "\($0)" }, edges: edges.map(position))
}

func eulerianAnswers<G: DirectedGraph>(_ g: G, start: G.Vertex?, _ position: (G.Edges.Index) -> Int) -> EulerianAnswers {
    var a = EulerianAnswers()
    a.isEulerian = g.isEulerian
    a.hasTrail = g.hasEulerianTrail
    a.circuit = g.eulerianCircuit().map { walkAnswer($0.vertices, $0.edges, position) }
    a.trail = g.eulerianTrail().map { walkAnswer($0.vertices, $0.edges, position) }
    if let start {
        a.circuitFrom = g.eulerianCircuit(from: start).map { walkAnswer($0.vertices, $0.edges, position) }
        a.trailFrom = g.eulerianTrail(from: start).map { walkAnswer($0.vertices, $0.edges, position) }
    }
    return a
}

func eulerianAnswers<G: Graph>(_ g: G, start: G.Vertex?, _ position: (G.Edges.Index) -> Int) -> EulerianAnswers {
    var a = EulerianAnswers()
    a.isEulerian = g.isEulerian
    a.hasTrail = g.hasEulerianTrail
    a.circuit = g.eulerianCircuit().map { walkAnswer($0.vertices, $0.edges, position) }
    a.trail = g.eulerianTrail().map { walkAnswer($0.vertices, $0.edges, position) }
    if let start {
        a.circuitFrom = g.eulerianCircuit(from: start).map { walkAnswer($0.vertices, $0.edges, position) }
        a.trailFrom = g.eulerianTrail(from: start).map { walkAnswer($0.vertices, $0.edges, position) }
    }
    return a
}

/// A weight type the tour entry points accept, parsed from the harness's text.
protocol TourWeight: Comparable & SignedNumeric & CustomStringConvertible {
    init?(_ text: String)
    /// `christofidesTour`, whose two overloads need the concrete kind of weight.
    static func christofides<G: Graph>(_ g: G, _ w: (G.Edges.Index) -> Self) -> Cycle<G.Vertex, G.Edges.Index>?
    /// The metaheuristics, whose overloads need the concrete kind of weight too.
    static func annealing<G: Graph>(_ g: G, _ move: TourMove, _ w: (G.Edges.Index) -> Self, _ generator: inout SplitMix64) -> Cycle<G.Vertex, G.Edges.Index>?
    static func thresholdAccepting<G: Graph>(_ g: G, _ move: TourMove, _ w: (G.Edges.Index) -> Self, _ generator: inout SplitMix64) -> Cycle<G.Vertex, G.Edges.Index>?
}

extension Int: TourWeight {
    static func christofides<G: Graph>(_ g: G, _ w: (G.Edges.Index) -> Int) -> Cycle<G.Vertex, G.Edges.Index>? { g.christofidesTour(weight: w) }
    static func annealing<G: Graph>(_ g: G, _ move: TourMove, _ w: (G.Edges.Index) -> Int, _ generator: inout SplitMix64) -> Cycle<G.Vertex, G.Edges.Index>? {
        g.simulatedAnnealingTour(move: move, innerIterations: 30, weight: w, using: &generator)
    }
    static func thresholdAccepting<G: Graph>(_ g: G, _ move: TourMove, _ w: (G.Edges.Index) -> Int, _ generator: inout SplitMix64) -> Cycle<G.Vertex, G.Edges.Index>? {
        g.thresholdAcceptingTour(move: move, innerIterations: 30, weight: w, using: &generator)
    }
}

extension Double: TourWeight {
    static func christofides<G: Graph>(_ g: G, _ w: (G.Edges.Index) -> Double) -> Cycle<G.Vertex, G.Edges.Index>? { g.christofidesTour(weight: w) }
    static func annealing<G: Graph>(_ g: G, _ move: TourMove, _ w: (G.Edges.Index) -> Double, _ generator: inout SplitMix64) -> Cycle<G.Vertex, G.Edges.Index>? {
        g.simulatedAnnealingTour(move: move, innerIterations: 30, weight: w, using: &generator)
    }
    static func thresholdAccepting<G: Graph>(_ g: G, _ move: TourMove, _ w: (G.Edges.Index) -> Double, _ generator: inout SplitMix64) -> Cycle<G.Vertex, G.Edges.Index>? {
        g.thresholdAcceptingTour(move: move, innerIterations: 30, weight: w, using: &generator)
    }
}

func tourAnswers<W: TourWeight>(_ t: ToursCase, _: W.Type, _ a: inout ToursAnswers) {
    let weights = t.weights.map { W($0)! }
    let g = Pseudograph(vertices: 0 ..< t.completeN, edges: t.complete.map { UndirectedEdge($0[0], $0[1]) })
    if Array(g.edges) != t.complete.map({ UndirectedEdge($0[0], $0[1]) }) { a.positionsInOrder = false }
    let w: (Int) -> W = { weights[$0] }
    let answer = { (c: Cycle<Int, Int>?) in c.map { walkAnswer($0.vertices, $0.edges) { $0 } } }
    a.nearestNeighbor = answer(g.nearestNeighborTour(weight: w))
    a.nearestNeighborFrom = answer(g.nearestNeighborTour(from: t.start % t.completeN, weight: w))
    a.twoOpt = answer(g.twoOptTour(weight: w))
    if let start = Cycle(t.improving, in: g) { a.twoOptImproving = answer(g.twoOptTour(improving: start, weight: w)) }
    a.christofides = answer(W.christofides(g, w))
    a.shortest = answer(g.shortestTour(weight: w))
    for move in TourMove.allCases {
        var generator = SplitMix64(state: UInt64(t.start))
        a.annealing.append(answer(W.annealing(g, move, w, &generator)))
        a.thresholdAccepting.append(answer(W.thresholdAccepting(g, move, w, &generator)))
    }
}

func toursAnswers(directed: Bool, n: Int, edges: [[Int]], sources: [Int], target: Int, _ t: ToursCase) -> ToursAnswers {
    var a = ToursAnswers()
    let start = n > 0 ? sources[0] : nil
    let id: (Int) -> Int = { $0 }
    if directed {
        let g = AdjacencyList(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        if Array(g.edges) != edges.map({ DirectedEdge(from: $0[0], to: $0[1]) }) { a.positionsInOrder = false }
        a.graph = eulerianAnswers(g, start: start, id)
        let csr = CompressedSparseRow(vertexCount: n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        a.csr = eulerianAnswers(csr, start: start, id)
        a.csrEdges = csr.edges.map { [$0.source, $0.target] }
        let walk = DirectedPseudograph(vertices: 0 ..< n, edges: t.walk.map { DirectedEdge(from: $0[0], to: $0[1]) })
        if Array(walk.edges) != t.walk.map({ DirectedEdge(from: $0[0], to: $0[1]) }) { a.positionsInOrder = false }
        a.walk = eulerianAnswers(walk, start: start, id)
        let cw = t.caseWeights.map { abs(Int($0)!) }
        a.postman = postmanAnswer(g.chinesePostmanTour { cw[$0] }, id)
        a.postmanWalk = postmanAnswer(walk.chinesePostmanTour { $0 % 4 }, id)
        if t.hamiltonian {
            a.hamiltonianPath = g.hamiltonianPath().map { walkAnswer($0.vertices, $0.edges, id) }
            a.hamiltonianCycle = g.hamiltonianCycle().map { walkAnswer($0.vertices, $0.edges, id) }
            a.csrHamiltonianPath = csr.hamiltonianPath().map { walkAnswer($0.vertices, $0.edges, id) }
            a.csrHamiltonianCycle = csr.hamiltonianCycle().map { walkAnswer($0.vertices, $0.edges, id) }
            if let start {
                a.hamiltonianPathFrom = g.hamiltonianPath(from: start).map { walkAnswer($0.vertices, $0.edges, id) }
                a.hamiltonianPathFromTo = g.hamiltonianPath(from: start, to: target).map { walkAnswer($0.vertices, $0.edges, id) }
            }
        }
        if t.shortestOnCase {
            let w = t.caseWeights.map { Int($0)! }
            a.shortestOnCase = g.shortestTour(weight: { w[$0] }).map { walkAnswer($0.vertices, $0.edges, id) }
        }
    } else {
        let g = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
        if Array(g.edges) != edges.map({ UndirectedEdge($0[0], $0[1]) }) { a.positionsInOrder = false }
        a.graph = eulerianAnswers(g, start: start, id)
        let walk = Pseudograph(vertices: 0 ..< n, edges: t.walk.map { UndirectedEdge($0[0], $0[1]) })
        if Array(walk.edges) != t.walk.map({ UndirectedEdge($0[0], $0[1]) }) { a.positionsInOrder = false }
        a.walk = eulerianAnswers(walk, start: start, id)
        let cw = t.caseWeights.map { abs(Int($0)!) }
        a.postman = postmanAnswer(g.chinesePostmanTour { cw[$0] }, id)
        a.postmanWalk = postmanAnswer(walk.chinesePostmanTour { $0 % 4 }, id)
        if t.hamiltonian {
            a.hamiltonianPath = g.hamiltonianPath().map { walkAnswer($0.vertices, $0.edges, id) }
            a.hamiltonianCycle = g.hamiltonianCycle().map { walkAnswer($0.vertices, $0.edges, id) }
            if let start {
                a.hamiltonianPathFrom = g.hamiltonianPath(from: start).map { walkAnswer($0.vertices, $0.edges, id) }
                a.hamiltonianPathFromTo = g.hamiltonianPath(from: start, to: target).map { walkAnswer($0.vertices, $0.edges, id) }
            }
        }
        if t.shortestOnCase {
            let w = t.caseWeights.map { Int($0)! }
            a.shortestOnCase = g.shortestTour(weight: { w[$0] }).map { walkAnswer($0.vertices, $0.edges, id) }
        }
    }
    if t.wtype == "Double" { tourAnswers(t, Double.self, &a) } else { tourAnswers(t, Int.self, &a) }
    let arcs = t.directedComplete.map { DirectedEdge(from: $0[0], to: $0[1]) }
    let digraph = AdjacencyList(vertices: 0 ..< t.completeN, edges: arcs)
    if Array(digraph.edges) != arcs { a.positionsInOrder = false }
    let dw = t.directedWeights.map { Int($0)! }
    a.shortestDirected = digraph.shortestTour(weight: { dw[$0] }).map { walkAnswer($0.vertices, $0.edges, id) }
    if t.largeN > 0 {
        let g = UndirectedAdjacencyList(vertices: 0 ..< t.largeN, edges: t.large.map { UndirectedEdge($0[0], $0[1]) })
        let w = t.largeWeights.map { Int($0)! }
        let answer = { (c: Cycle<Int, Int>?) in c.map { walkAnswer($0.vertices, $0.edges) { $0 } } }
        a.largeNearestNeighbor = answer(g.nearestNeighborTour { w[$0] })
        a.largeTwoOpt = answer(g.twoOptTour { w[$0] })
        a.largeChristofides = answer(g.christofidesTour { w[$0] })
    }
    return a
}

// MARK: - Catalog mode

/// One catalog row: the graph (vertices by label, in order; edges by label number), weights as
/// text, the call and its arguments as vertex numbers.
struct ToursRequest: Decodable {
    let directed: Bool
    let multi: Bool
    let labels: [String]
    let edges: [[Int]]
    let weights: [String]?
    let wtype: String
    let call: String
    let from: Int?
    let to: Int?
    let tour: [Int]?
}

struct ToursCatalogAnswer: Encodable {
    var flag: Bool?
    var walk: WalkAnswer?
}

func answerTours<G: DirectedGraph<String>>(_ g: G, _ r: ToursRequest, _ position: @escaping (G.Edges.Index) -> Int) -> ToursCatalogAnswer {
    var a = ToursCatalogAnswer()
    let from = r.from.map { r.labels.indices.contains($0) ? r.labels[$0] : "\($0)" }
    let to = r.to.map { r.labels.indices.contains($0) ? r.labels[$0] : "\($0)" }
    let walk = { (vs: [String], es: [G.Edges.Index]) in walkAnswer(vs, es, position) }
    switch r.call {
    case "isEulerian": a.flag = g.isEulerian
    case "hasEulerianTrail": a.flag = g.hasEulerianTrail
    case "eulerianCircuit": a.walk = (from.map { g.eulerianCircuit(from: $0) } ?? g.eulerianCircuit()).map { walk($0.vertices, $0.edges) }
    case "eulerianTrail": a.walk = (from.map { g.eulerianTrail(from: $0) } ?? g.eulerianTrail()).map { walk($0.vertices, $0.edges) }
    case "hamiltonianPath":
        let p = from.map { s in to.map { g.hamiltonianPath(from: s, to: $0) } ?? g.hamiltonianPath(from: s) } ?? g.hamiltonianPath()
        a.walk = p.map { walk($0.vertices, $0.edges) }
    case "hamiltonianCycle": a.walk = g.hamiltonianCycle().map { walk($0.vertices, $0.edges) }
    case "shortestTour":
        if r.wtype == "Double" {
            let weights = (r.weights ?? []).map { Double($0)! }
            a.walk = g.shortestTour(weight: { weights[position($0)] }).map { walk($0.vertices, $0.edges) }
        } else {
            let weights = (r.weights ?? []).map { Int($0)! }
            a.walk = g.shortestTour(weight: { weights[position($0)] }).map { walk($0.vertices, $0.edges) }
        }
    default: fatalError("unknown call \(r.call)")
    }
    return a
}

func answerTours<G: Graph<String>>(_ g: G, _ r: ToursRequest, _ position: @escaping (G.Edges.Index) -> Int) -> ToursCatalogAnswer {
    var a = ToursCatalogAnswer()
    let from = r.from.map { r.labels.indices.contains($0) ? r.labels[$0] : "\($0)" }
    let to = r.to.map { r.labels.indices.contains($0) ? r.labels[$0] : "\($0)" }
    let walk = { (vs: [String], es: [G.Edges.Index]) in walkAnswer(vs, es, position) }
    switch r.call {
    case "isEulerian": a.flag = g.isEulerian
    case "hasEulerianTrail": a.flag = g.hasEulerianTrail
    case "eulerianCircuit": a.walk = (from.map { g.eulerianCircuit(from: $0) } ?? g.eulerianCircuit()).map { walk($0.vertices, $0.edges) }
    case "eulerianTrail": a.walk = (from.map { g.eulerianTrail(from: $0) } ?? g.eulerianTrail()).map { walk($0.vertices, $0.edges) }
    case "hamiltonianPath":
        let p = from.map { s in to.map { g.hamiltonianPath(from: s, to: $0) } ?? g.hamiltonianPath(from: s) } ?? g.hamiltonianPath()
        a.walk = p.map { walk($0.vertices, $0.edges) }
    case "hamiltonianCycle": a.walk = g.hamiltonianCycle().map { walk($0.vertices, $0.edges) }
    default:
        if r.wtype == "Double" {
            let weights = (r.weights ?? []).map { Double($0)! }
            a.walk = catalogTour(g, r, from, { weights[position($0)] }).map { walk($0.vertices, $0.edges) }
        } else {
            let weights = (r.weights ?? []).map { Int($0)! }
            a.walk = catalogTour(g, r, from, { weights[position($0)] }).map { walk($0.vertices, $0.edges) }
        }
    }
    return a
}

func catalogTour<G: Graph<String>, W: TourWeight>(_ g: G, _ r: ToursRequest, _ from: String?, _ w: (G.Edges.Index) -> W) -> Cycle<String, G.Edges.Index>? {
    switch r.call {
    case "nearestNeighborTour": return from.map { g.nearestNeighborTour(from: $0, weight: w) } ?? g.nearestNeighborTour(weight: w)
    case "christofidesTour": return W.christofides(g, w)
    case "twoOptTour":
        guard let tour = r.tour else { return g.twoOptTour(weight: w) }
        let vertices = tour.map { r.labels.indices.contains($0) ? r.labels[$0] : "\($0)" }
        // A tour that misses a vertex is still a cycle of the graph, and reaches the precondition.
        guard let start = Cycle(vertices, in: g) else { fatalError("\(vertices) is not a cycle of the graph") }
        return g.twoOptTour(improving: start, weight: w)
    case "shortestTour": return g.shortestTour(weight: w)
    default: fatalError("unknown call \(r.call)")
    }
}

func answerToursCatalog(_ r: ToursRequest) -> ToursCatalogAnswer {
    let labels = r.labels
    if r.directed {
        let edges = r.edges.map { DirectedEdge(from: labels[$0[0]], to: labels[$0[1]]) }
        if r.multi {
            return answerTours(DirectedPseudograph(vertices: labels, edges: edges), r) { $0 }
        }
        return answerTours(AdjacencyList(vertices: labels, edges: edges), r) { $0 }
    }
    let edges = r.edges.map { UndirectedEdge(labels[$0[0]], labels[$0[1]]) }
    if r.multi {
        return answerTours(Pseudograph(vertices: labels, edges: edges), r) { $0 }
    }
    return answerTours(UndirectedAdjacencyList(vertices: labels, edges: edges), r) { $0 }
}
