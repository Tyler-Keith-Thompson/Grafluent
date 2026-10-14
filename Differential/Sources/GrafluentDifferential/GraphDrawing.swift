import GraphDrawing
import GraphProtocols
import Multigraphs

/// GraphDrawing on the case's edges as an undirected multigraph (a directed case's arcs as edges,
/// loops kept), vertices 0..<n: the shell layout with one shell and with the shells [[0], the
/// rest], the spiral (both modes) and the bipartite layout of the even vertices on the left, each
/// rescaled to NetworkX's frame; the spectral layout's raw axes and the classical scaling's; and
/// whether the planar layout exists and draws every edge without a crossing on its grid.
struct DrawingAnswers: Encodable {
    var shell: [[Double]] = []
    var shellCentred: [[Double]] = []
    var spiral: [[Double]] = []
    var spiralEquidistant: [[Double]] = []
    var bipartite: [[Double]] = []
    var spectral: [[Double]]?
    var scaling: [[Double]]?
    var planar = false
    var planarValid = true
}

func drawingAnswers(n: Int, edges: [[Int]]) -> DrawingAnswers {
    let pairs = edges.map { ($0[0], $0[1]) }
    let graph = Pseudograph<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
    func rows(_ d: Drawing<Int>) -> [[Double]] { d.positions.map { [$0.x, $0.y] } }
    var a = DrawingAnswers()
    a.shell = rows(graph.shellLayout())
    if n > 0 { a.shellCentred = rows(graph.shellLayout(shells: [[0], Array(1 ..< n)])) }
    a.spiral = rows(graph.spiralLayout().rescaled())
    a.spiralEquidistant = rows(graph.spiralLayout(equidistant: true).rescaled())
    a.bipartite = rows(graph.bipartiteLayout(left: stride(from: 0, to: n, by: 2)).rescaled())
    a.spectral = (try? graph.spectralLayout()).map(rows)
    a.scaling = (try? graph.multidimensionalScalingLayout()).map(rows)
    if let planar = graph.planarLayout() {
        a.planar = true
        let p = planar.positions
        func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Double {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }
        for q in p where q.x != q.x.rounded() || q.y != q.y.rounded() || q.x < 0 || q.y < 0 || (n >= 4 && (q.x > Double(2 * n - 4) || q.y > Double(n - 2))) {
            a.planarValid = false
        }
        if Set(p.map { [$0.x, $0.y] }).count != n { a.planarValid = false }
        let segments = Array(Set(pairs.filter { $0.0 != $0.1 }.map { [min($0.0, $0.1), max($0.0, $0.1)] }))
        for s in segments {
            for w in 0 ..< n where w != s[0] && w != s[1] {
                let u = p[s[0]], v = p[s[1]], c = p[w]
                if orientation(u, v, c) == 0 && min(u.x, v.x) <= c.x && c.x <= max(u.x, v.x) && min(u.y, v.y) <= c.y && c.y <= max(u.y, v.y) {
                    a.planarValid = false
                }
            }
        }
        for i in 0 ..< segments.count {
            for j in i + 1 ..< segments.count {
                let s = segments[i], t = segments[j]
                guard Set(s + t).count == 4 else { continue }
                if orientation(p[s[0]], p[s[1]], p[t[0]]) * orientation(p[s[0]], p[s[1]], p[t[1]]) < 0
                    && orientation(p[t[0]], p[t[1]], p[s[0]]) * orientation(p[t[0]], p[t[1]], p[s[1]]) < 0 {
                    a.planarValid = false
                }
            }
        }
    }
    return a
}
