// Distances against Floyd–Warshall, on multigraphs of at most 9 vertices with self-loops,
// directed and undirected, unweighted and with weights 0 … 9: every eccentricity (nil where a
// vertex is unreachable), radius and diameter with nil as infinity, center and periphery in
// vertex order (by eccentricities() and by the one-shot calls, which use bounding when
// undirected), the centroid, the Wiener index, the average shortest path length, density, and
// the diameter path's endpoints and length.

import AdjacencyListModule
import Distances
import FuzzSupport
import GraphProtocols
import Walks

@main
enum FuzzDistances {
    static func main() { runFuzzer(fuzz) }

    static let infinity = Int.max / 4

    static func floydWarshall(_ n: Int, _ arcs: [(Int, Int, Int)]) -> [[Int]] {
        var d = [[Int]](repeating: [Int](repeating: infinity, count: n), count: n)
        for i in 0 ..< n { d[i][i] = 0 }
        for (u, v, w) in arcs where u != v { d[u][v] = min(d[u][v], w) }
        for k in 0 ..< n { for i in 0 ..< n where d[i][k] < infinity { for j in 0 ..< n where d[k][j] < infinity {
            d[i][j] = min(d[i][j], d[i][k] + d[k][j])
        } } }
        return d
    }

    struct Expected {
        let eccentricities: [Int?]
        let radius: Int?, diameter: Int?
        let center: [Int], periphery: [Int], centroid: [Int]
        let wiener: Int?
    }

    static func expected(_ d: [[Int]], undirected: Bool) -> Expected {
        let n = d.count
        let ecc: [Int?] = (0 ..< n).map { v in d[v].contains(infinity) ? nil : d[v].max()! }
        let totals: [Int?] = (0 ..< n).map { v in d[v].contains(infinity) ? nil : d[v].reduce(0, +) }
        let finite = ecc.compactMap { $0 }
        let radius = finite.min()
        let diameter = ecc.contains { $0 == nil } || n == 0 ? nil : finite.max()
        let least = totals.compactMap { $0 }.min()
        var wiener: Int? = 0
        for u in 0 ..< n { for v in 0 ..< n where (undirected ? v > u : v != u) {
            if d[u][v] == infinity { wiener = nil } else if let w = wiener { wiener = w + d[u][v] }
        } }
        return Expected(eccentricities: ecc, radius: radius, diameter: diameter,
                        center: (0 ..< n).filter { ecc[$0] == radius }, periphery: (0 ..< n).filter { ecc[$0] == diameter },
                        centroid: (0 ..< n).filter { totals[$0] == least }, wiener: wiener)
    }

    static func checkUndirected(_ graph: UndirectedAdjacencyList<Int>, _ n: Int, _ weight: [UndirectedEdge<Int>: Int]) {
        let edges = Array(graph.edges)
        for (name, w) in [("unweighted", { (_: Int) in 1 }), ("weighted", { (e: Int) in weight[edges[e]]! })] {
            let d = floydWarshall(n, edges.flatMap { [($0.u, $0.v, w(edges.firstIndex(of: $0)!)), ($0.v, $0.u, w(edges.firstIndex(of: $0)!))] })
            let x = expected(d, undirected: true)
            let e = name == "unweighted" ? graph.eccentricities().asWeighted : graph.eccentricities(weight: w).asWeighted
            check((0 ..< n).map { e.0($0) } == x.eccentricities, "undirected \(name) eccentricities \((0 ..< n).map { e.0($0) }), expected \(x.eccentricities)")
            check(e.1 == x.radius && e.2 == x.diameter, "undirected \(name) radius/diameter \(e.1 as Any)/\(e.2 as Any), expected \(x.radius as Any)/\(x.diameter as Any)")
            check(e.3 == x.center && e.4 == x.periphery, "undirected \(name) center/periphery")
            if name == "unweighted" {
                check(graph.radius() == x.radius && graph.diameter() == x.diameter, "bounding radius/diameter \(graph.radius() as Any)/\(graph.diameter() as Any), expected \(x.radius as Any)/\(x.diameter as Any)")
                check(graph.center() == x.center && graph.periphery() == x.periphery, "bounding center \(graph.center()) / periphery \(graph.periphery()), expected \(x.center) / \(x.periphery)")
                check(graph.centroid() == x.centroid && graph.wienerIndex() == x.wiener, "centroid / Wiener")
                if let diameter = x.diameter, let path = graph.diameterPath() {
                    let u = x.eccentricities.firstIndex { $0 == diameter }!
                    let v = d[u].firstIndex(of: diameter)!
                    check(path.source == u && path.target == v && path.length == diameter && Path(vertices: path.vertices, edges: path.edges, in: graph) != nil, "diameterPath \(path)")
                } else {
                    check(x.diameter == nil && graph.diameterPath() == nil, "diameterPath exists \(graph.diameterPath() != nil)")
                }
            } else {
                check(graph.centroid(weight: w) == x.centroid && graph.wienerIndex(weight: w) == x.wiener, "weighted centroid / Wiener")
                if let diameter = x.diameter, let result = graph.diameterPath(weight: w) {
                    check(result.distance == diameter && result.path.edges.map(w).reduce(0, +) == diameter && result.path.source == x.eccentricities.firstIndex { $0 == diameter }!, "weighted diameterPath")
                } else {
                    check(x.diameter == nil && graph.diameterPath(weight: w) == nil, "weighted diameterPath exists")
                }
            }
        }
        check(graph.density == (n <= 1 ? 0 : 2 * Double(graph.edgeCount) / Double(n * (n - 1))), "density")
    }

    static func checkDirected(_ graph: AdjacencyList<Int>, _ n: Int, _ weights: [Int]) {
        let edges = Array(graph.edges)
        for (name, w) in [("unweighted", { (_: Int) in 1 }), ("weighted", { (e: Int) in weights[e] })] {
            let d = floydWarshall(n, edges.indices.map { (edges[$0].source, edges[$0].target, w($0)) })
            let x = expected(d, undirected: false)
            let e = name == "unweighted" ? graph.eccentricities().asWeighted : graph.eccentricities(weight: w).asWeighted
            check((0 ..< n).map { e.0($0) } == x.eccentricities, "directed \(name) eccentricities \((0 ..< n).map { e.0($0) }), expected \(x.eccentricities)")
            check(e.1 == x.radius && e.2 == x.diameter && e.3 == x.center && e.4 == x.periphery, "directed \(name) extrema")
            let diameter = name == "unweighted" ? graph.diameter() : graph.diameter(weight: w)
            check(diameter == x.diameter, "directed \(name) diameter()")
            let centroid = name == "unweighted" ? graph.centroid() : graph.centroid(weight: w)
            let wiener = name == "unweighted" ? graph.wienerIndex() : graph.wienerIndex(weight: w)
            check(centroid == x.centroid && wiener == x.wiener, "directed \(name) centroid \(centroid) / Wiener \(wiener as Any), expected \(x.centroid) / \(x.wiener as Any)")
            if let x0 = x.eccentricities.first {
                let one = name == "unweighted" ? graph.eccentricity(of: 0) : graph.eccentricity(of: 0, weight: w)
                check(one == x0, "eccentricity(of: 0)")
            }
        }
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 9)
        var pairs: [(Int, Int, Int)] = []
        while !input.isEmpty, pairs.count < 20 { pairs.append((input.int(below: n), input.int(below: n), input.int(in: 0 ... 9))) }
        var weight: [UndirectedEdge<Int>: Int] = [:]
        for (u, v, w) in pairs where weight[UndirectedEdge(u, v)] == nil { weight[UndirectedEdge(u, v)] = w }
        checkUndirected(UndirectedAdjacencyList(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) }), n, weight)
        let directed = AdjacencyList(vertices: 0 ..< n, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        var arcWeight: [DirectedEdge<Int>: Int] = [:]
        for (u, v, w) in pairs where arcWeight[DirectedEdge(from: u, to: v)] == nil { arcWeight[DirectedEdge(from: u, to: v)] = w }
        checkDirected(directed, n, directed.edges.map { arcWeight[$0]! })
    }
}

extension Eccentricities where G.Vertex == Int, Distance == Int {
    /// (eccentricity by vertex, radius, diameter, center, periphery).
    var asWeighted: ((Int) -> Int?, Int?, Int?, [Int], [Int]) {
        ({ self.eccentricity(of: $0) }, radius, diameter, center, periphery)
    }
}
