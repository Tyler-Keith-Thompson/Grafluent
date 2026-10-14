import AdjacencyListModule
import GraphProtocols
import IsomorphismModule

/// Graph edit distance on small cases (n ≤ 6, at most 10 edges), between the case's graph and its
/// partner (`editPartner`), at unit costs and with vertex colours v mod 2 (a substitution between
/// colours costs 1); `consistent` says each returned path costs what its operations add up to and
/// substitutes edges only between the images of their ends.
struct IsomorphismAnswers: Encodable {
    var editDistance: Int?
    var coloredEditDistance: Int?
    var consistent = true
}

/// The partner of a case: vertices 0..<n′ with n′ = max(n − 1, 1); the case's edges at offsets k
/// with k mod 3 ≠ 2, each end taken mod n′, repeats dropped (an undirected pair in either order);
/// then 0–(n′ − 1) when n′ ≥ 2 and not already there.
func editPartner(directed: Bool, n: Int, edges: [[Int]]) -> (n: Int, edges: [[Int]]) {
    let m = max(n - 1, 1)
    var kept: [[Int]] = []
    func has(_ a: Int, _ b: Int) -> Bool { kept.contains { $0 == [a, b] || (!directed && $0 == [b, a]) } }
    for (k, e) in edges.enumerated() where k % 3 != 2 {
        let a = e[0] % m, b = e[1] % m
        if !has(a, b) { kept.append([a, b]) }
    }
    if m >= 2 && !has(0, m - 1) { kept.append([0, m - 1]) }
    return (m, kept)
}

func isomorphismAnswers(directed: Bool, n: Int, edges: [[Int]]) -> IsomorphismAnswers {
    var a = IsomorphismAnswers()
    guard n <= 6 && edges.count <= 10 else { return a }
    let partner = editPartner(directed: directed, n: n, edges: edges)
    if directed {
        let g = AdjacencyList(vertices: 0 ..< n, edges: edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let h = AdjacencyList(vertices: 0 ..< partner.n, edges: partner.edges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let plain = g.optimalEditPath(to: h)!
        let colored = g.optimalEditPath(to: h, vertexSubstitutionCost: { $0 % 2 == $1 % 2 ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                                        edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })!
        a.editDistance = plain.cost
        a.coloredEditDistance = colored.cost
        for (path, colors) in [(plain, false), (colored, true)] {
            var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
            for v in g.vertices {
                if let x = path.image(of: v) { total += colors && v % 2 != x % 2 ? 1 : 0 } else { total += 1 }
            }
            for p in g.edges.indices {
                guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
                if path.image(of: g.source(ofEdgeAt: p)) != h.source(ofEdgeAt: q) || path.image(of: g.target(ofEdgeAt: p)) != h.target(ofEdgeAt: q) { a.consistent = false }
            }
            if total != path.cost || !path.isOptimal { a.consistent = false }
        }
    } else {
        let g = UndirectedAdjacencyList(vertices: 0 ..< n, edges: edges.map { UndirectedEdge($0[0], $0[1]) })
        let h = UndirectedAdjacencyList(vertices: 0 ..< partner.n, edges: partner.edges.map { UndirectedEdge($0[0], $0[1]) })
        let plain = g.optimalEditPath(to: h)!
        let colored = g.optimalEditPath(to: h, vertexSubstitutionCost: { $0 % 2 == $1 % 2 ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                                        edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })!
        a.editDistance = plain.cost
        a.coloredEditDistance = colored.cost
        for (path, colors) in [(plain, false), (colored, true)] {
            var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
            for v in g.vertices {
                if let x = path.image(of: v) { total += colors && v % 2 != x % 2 ? 1 : 0 } else { total += 1 }
            }
            for p in g.edges.indices {
                guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
                let e = g.edges[p], f = h.edges[q]
                let ends = [path.image(of: e.u), path.image(of: e.v)]
                if ends != [f.u, f.v] && ends != [f.v, f.u] { a.consistent = false }
            }
            if total != path.cost || !path.isOptimal { a.consistent = false }
        }
    }
    return a
}
