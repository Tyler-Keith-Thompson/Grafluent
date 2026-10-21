import GraphProtocols
import ShortestPaths
import Walks

/// Path enumeration and all pairs, answered in the shortestpaths section: from the first source to
/// the target, the first `simpleLimit` simple paths by Yen's algorithm and every shortest path (up
/// to `shortestLimit`), bidirectional Dijkstra, and for n ≤ `allPairsLimit` the all-pairs matrices
/// by Dijkstra and by Johnson. The weighted queries need nonnegative weights (Johnson takes any).
/// `valid` says every returned path is a path of the graph between the right ends that weighs its
/// reported length, and that every shortest path is distinct.
struct PathAnswers: Encodable {
    var simple: [[Int]]?
    var simpleLengths: [Int]?
    var shortestCount: Int?
    var shortestDistance: Int?
    var shortestSample: [[Int]]?
    var bidirectional: Single?
    var contractionHierarchy: Single?
    var allPairs: [[Int?]]?
    var johnson: [[Int?]]?
    var johnsonNil = false
    var valid = true
}

let simpleLimit = 8
let shortestLimit = 5000
let allPairsLimit = 40

func pathAnswers<G: BidirectionalDirectedGraph<Int>>(_ graph: G, _ c: Case, _ weight: (G.Edges.Index) -> Int) -> PathAnswers {
    var a = PathAnswers()
    let s = c.sources[0], t = c.target
    func check(_ path: Path<Int, G.Edges.Index>, _ length: Int) {
        if Path(vertices: path.vertices, edges: path.edges, in: graph) == nil || path.vertices.first != s || path.vertices.last != t
            || path.edges.map(weight).reduce(0, +) != length {
            a.valid = false
        }
    }
    if c.edges.allSatisfy({ $0[2] >= 0 }) {
        var simple: [[Int]] = [], lengths: [Int] = []
        for (path, length) in graph.shortestSimplePaths(from: s, to: t, weight: weight).prefix(simpleLimit) {
            check(path, length)
            simple.append(path.vertices)
            lengths.append(length)
        }
        if lengths != lengths.sorted() { a.valid = false }
        a.simple = simple
        a.simpleLengths = lengths
        let shortest = graph.allShortestPaths(from: s, to: t, weight: weight)
        a.shortestDistance = shortest.distance
        var count = 0, seen = Set<[G.Edges.Index]>(), sample: [[Int]] = []
        // Zero-weight cycles can send the walk down long dead ends; the reference skips them too.
        let positive = c.edges.allSatisfy { $0[2] > 0 } || shortest.distance == nil
        for path in shortest.prefix(positive ? shortestLimit + 1 : 0) {
            count += 1
            check(path, shortest.distance ?? -1)
            if !seen.insert(path.edges).inserted { a.valid = false }
            if sample.count < 50 { sample.append(path.vertices) }
        }
        a.shortestCount = positive && count <= shortestLimit ? count : nil
        a.shortestSample = sample
        let found = graph.bidirectionalDijkstraShortestPath(from: s, to: t, weight: weight)
        if let found { check(found.path, found.distance) }
        a.bidirectional = Single(reached: found != nil, distance: found?.distance, path: found?.path.vertices)
        let hierarchy = graph.contractionHierarchy(witnessLimit: c.n % 3 == 0 ? 2 : 500, weight: weight)
        let hierarchyPath = hierarchy.path(from: s, to: t)
        let hierarchyDistance = hierarchy.distance(from: s, to: t)
        if let hierarchyPath { check(hierarchyPath, hierarchyDistance ?? -1) }
        if (hierarchyPath == nil) != (hierarchyDistance == nil) { a.valid = false }
        a.contractionHierarchy = Single(reached: hierarchyDistance != nil, distance: hierarchyDistance, path: hierarchyPath?.vertices)
        if c.n <= allPairsLimit {
            let matrix = graph.allPairsDijkstraShortestPaths(weight: weight)
            a.allPairs = (0 ..< c.n).map { u in (0 ..< c.n).map { v in matrix.distance(from: u, to: v) } }
            for u in 0 ..< c.n {
                for v in 0 ..< c.n {
                    guard let path = matrix.path(from: u, to: v) else { continue }
                    if Path(vertices: path.vertices, edges: path.edges, in: graph) == nil || path.edges.map(weight).reduce(0, +) != matrix.distance(from: u, to: v) {
                        a.valid = false
                    }
                }
            }
        }
    }
    if c.n <= allPairsLimit {
        if let matrix = graph.johnsonShortestPaths(weight: weight) {
            a.johnson = (0 ..< c.n).map { u in (0 ..< c.n).map { v in matrix.distance(from: u, to: v) } }
            for u in 0 ..< c.n {
                for v in 0 ..< c.n {
                    guard let path = matrix.path(from: u, to: v) else { continue }
                    if Path(vertices: path.vertices, edges: path.edges, in: graph) == nil || path.edges.map(weight).reduce(0, +) != matrix.distance(from: u, to: v) {
                        a.valid = false
                    }
                }
            }
        } else {
            a.johnsonNil = true
        }
    }
    return a
}
