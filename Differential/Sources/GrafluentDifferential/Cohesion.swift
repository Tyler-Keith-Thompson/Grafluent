// Cohesive subgraphs and d-separation. Undirected cases (cliques section): truss numbers and
// k-trusses, onion layers, k-crusts and k-coronas, every clique (small cases), the triangles,
// the maximal cliques through the target, each vertex's clique number and a maximum-weight clique
// with weights (7v mod 11) − 3. Undirected cases (connectivity section): k-edge-connected
// components and subgraphs for k = 1 … 4. Directed cases (dag section): the case's edges inserted
// into a DirectedAcyclicGraph as the dag section does, then d-separation queries, minimal
// d-separators and the moral graph. scripts/differential_cohesion.py compares them with NetworkX.

import AdjacencyListModule
import Cliques
import Connectivity
import DirectedAcyclicGraphModule
import GraphProtocols

/// The library lists every clique only on cases of at most this many vertices.
let allCliquesLimit = 40

struct CliqueExtraAnswers: Encodable {
    /// Each case edge's truss number, nil for a self-loop.
    var truss: [Int?] = []
    /// kTruss(k) for k = 0 … the largest truss number + 1, each as [u, v] pairs.
    var kTrusses: [[[Int]]] = []
    var onion: [Int] = []
    var layerCount = 0
    /// kCrust(k) and kCorona(k) for k = 0 … degeneracy + 1.
    var crusts: [[Int]] = []
    var coronas: [[Int]] = []
    var allCliques: [[Int]]?
    var triangles: [[Int]] = []
    var containingTarget: [[Int]] = []
    var vertexCliqueNumbers: [Int] = []
    var weightedClique: [Int] = []
}

func cliqueExtraAnswers(n: Int, edges: [[Int]], target: Int) -> CliqueExtraAnswers {
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
    var a = CliqueExtraAnswers()
    let trusses = graph.trussNumbers()
    a.truss = graph.edges.indices.map { trusses.trussNumber(ofEdgeAt: $0) }
    let largest = a.truss.compactMap { $0 }.max() ?? 2
    a.kTrusses = (0 ... largest + 1).map { k in trusses.kTruss(k).map { [graph.edges[$0].u, graph.edges[$0].v] } }
    let onion = graph.onionLayers()
    a.onion = (0 ..< n).map { onion.layer(of: $0) }
    a.layerCount = onion.layerCount
    let cores = graph.coreNumbers()
    a.crusts = (0 ... cores.degeneracy + 1).map { cores.kCrust($0) }
    a.coronas = (0 ... cores.degeneracy + 1).map { cores.kCorona($0) }
    if n <= allCliquesLimit { a.allCliques = Array(graph.allCliques(sizes: 1...)) }
    a.triangles = Array(graph.allCliques(sizes: 3 ... 3))
    a.containingTarget = Array(graph.maximalCliques(containing: target))
    a.vertexCliqueNumbers = (0 ..< n).map { graph.cliqueNumber(of: $0) }
    a.weightedClique = graph.maximumWeightClique { (7 * $0) % 11 - 3 }
    return a
}

struct EdgeConnectivityAnswers: Encodable {
    /// For k = 1 … 4.
    var components: [[[Int]]] = []
    var subgraphs: [[[Int]]] = []
    /// kComponents(), level k at k − 1.
    var kComponents: [[[Int]]] = []
}

func edgeConnectivityAnswers(n: Int, edges: [[Int]]) -> EdgeConnectivityAnswers {
    let graph = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
    var a = EdgeConnectivityAnswers()
    for k in 1 ... 4 {
        a.components.append(graph.kEdgeConnectedComponents(k).map(Array.init))
        a.subgraphs.append(graph.kEdgeConnectedSubgraphs(k).map(Array.init))
    }
    let components = graph.kComponents()
    a.kComponents = (0 ..< components.maximumK).map { components[$0 + 1].map(Array.init) }
    return a
}

struct DSeparationAnswers: Encodable {
    /// Each query: [x, y, z] and the answer.
    var queries: [[[Int]]] = []
    var separated: [Bool] = []
    /// Each minimal-separator query: [x, y, including, restricted (empty for nil)] and the answer.
    var minimalQueries: [[[Int]]] = []
    var restrictedIsNil: [Bool] = []
    var minimal: [[Int]?] = []
    var moralEdges: [[Int]] = []
}

func dSeparationAnswers(n: Int, edges: [[Int]], sources: [Int], target: Int) -> DSeparationAnswers {
    var dag = DirectedAcyclicGraph<AdjacencyList<Int>>(vertices: 0 ..< n)
    for e in edges { _ = try? dag.insert(edge: DirectedEdge(from: e[0], to: e[1])) }
    var a = DSeparationAnswers()
    a.moralEdges = UndirectedAdjacencyList<Int>.moralGraph(of: dag).edges.map { [$0.u, $0.v] }
    let x = [sources[0]]
    var ys = [target]
    for s in sources.dropFirst() where !x.contains(s) && !ys.contains(s) { ys.append(s) }
    ys.removeAll { x.contains($0) }
    guard !ys.isEmpty else { return a }
    let others = (0 ..< n).filter { !x.contains($0) && !ys.contains($0) }
    let zs: [[Int]] = [[], others.filter { $0 % 3 == 0 }, others.filter { $0 % 2 == 1 }, others]
    for z in zs {
        a.queries.append([x, ys, z])
        a.separated.append(dag.isDSeparator(z, between: x, and: ys))
    }
    for (including, restricted) in [([Int](), [Int]?.none), (Array(others.prefix(1)), [Int]?.none), ([], others.filter { $0 % 2 == 0 })] {
        a.minimalQueries.append([x, ys, including, restricted ?? []])
        a.restrictedIsNil.append(restricted == nil)
        let z = dag.minimalDSeparator(between: x, and: ys, including: including, restrictedTo: restricted)
        a.minimal.append(z)
        if let z {
            // The library's own check agrees.
            a.queries.append([x, ys, z])
            a.separated.append(dag.isDSeparator(z, between: x, and: ys))
        }
    }
    return a
}
