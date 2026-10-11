// Properties with shrinking (swift-property-based): the implicit graph laws on random closures
// (rows with parallel edges and self-loops), each against a model written out in the test, the
// rows themselves:
// - every read against the rows, with the closure calls it makes: none to build, to test a vertex
//   or to read a position's ends; one per row read; one per vertex to iterate or count the edges;
// - index(after:) stepping equals iteration, with the calls the model predicts (the row re-read,
//   then each later row up to the first non-empty one);
// - positions are unique, ordered by (source, rank), and equal and hash alike when read twice;
// - contains(edge:) scans one row, and none for an endpoint off 0..<n;
// - breadth-first layers against a breadth-first search written out over the rows, one call per
//   discovered vertex;
// - D19's Dijkstra and A* over closures against each other and against Dijkstra on an implicit
//   graph over a box with slack.
// See README.md.

import GrafluentTestSupport
import GraphProtocols
import ImplicitGraphs
import PropertyBased
import ShortestPaths
import Testing
import Traversal

@Suite("ImplicitGraphs laws against a model, with shrinking", .tags(.randomized))
struct ImplicitGraphPropertyTests {
    @Test("Every read agrees with the rows and makes the calls the laws give")
    func readsAgainstRows() async {
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 1_000).array(of: 0 ... 3).array(of: 0 ... 15)) { raw in
            let n = raw.count
            let rows = raw.map { row in row.map { $0 % max(n, 1) } }
            var calls = 0
            let graph = ImplicitDirectedGraph(vertexCount: n, successors: { (v: Int) -> [Int] in
                calls += 1
                return rows[v]
            })
            let context = "\(rows)"
            let edgeCount = rows.reduce(0) { $0 + $1.count }
            #expect(calls == 0, "\(context)")
            #expect(graph.vertexCount == n && graph.vertexIndexBound == n && graph.edgeIndexBound == nil, "\(context)")
            #expect((-1 ... n).map { graph.contains($0) } == [false] + Array(repeating: true, count: n) + [false], "\(context)")
            #expect(calls == 0, "\(context)")
            #expect(graph.edgeCount == edgeCount && calls == n, "\(context)")
            calls = 0
            var iterated: [[Int]] = []
            for edge in graph.edges { iterated.append([edge.source, edge.target]) }
            #expect(iterated == (0 ..< n).flatMap { v in rows[v].map { [v, $0] } } && calls == n, "\(context)")
            for v in 0 ..< n {
                calls = 0
                #expect(Array(graph.successors(of: v)) == rows[v] && calls == 1, "\(context): \(v)")
                calls = 0
                let positions = Array(graph.outEdges(of: v))
                #expect(calls == 1, "\(context): \(v)")
                #expect(positions.map { [$0.source, $0.rank, $0.target] } == rows[v].enumerated().map { [v, $0, $1] }, "\(context): \(v)")
                calls = 0
                #expect(positions.map { graph.source(ofEdgeAt: $0) } == Array(repeating: v, count: rows[v].count) && positions.map { graph.target(ofEdgeAt: $0) } == rows[v], "\(context): \(v)")
                #expect(calls == 0, "\(context): \(v)")
                // Read twice, the positions are equal and hash alike.
                let again = Array(graph.outEdges(ofIndex: v))
                #expect(again == positions && again.map(\.hashValue) == positions.map(\.hashValue), "\(context): \(v)")
                calls = 0
                #expect(graph.outDegree(of: v) == rows[v].count && calls == 1, "\(context): \(v)")
                for w in -1 ... n {
                    calls = 0
                    #expect(graph.contains(edge: DirectedEdge(from: v, to: w)) == rows[v].contains(w), "\(context): \(v) → \(w)")
                    #expect(calls == (w >= 0 && w < n ? 1 : 0), "\(context): \(v) → \(w)")
                }
                calls = 0
                #expect(!graph.contains(edge: DirectedEdge(from: n, to: v)) && !graph.contains(edge: DirectedEdge(from: -1, to: v)) && calls == 0, "\(context)")
            }
        }
    }

    @Test("index(after:) stepping equals iteration, with the calls the model predicts")
    func steppingAgainstModel() async {
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 1_000).array(of: 0 ... 3).array(of: 0 ... 15)) { raw in
            let n = raw.count
            let rows = raw.map { row in row.map { $0 % max(n, 1) } }
            var calls = 0
            let graph = ImplicitDirectedGraph(vertexCount: n, successors: { (v: Int) -> [Int] in
                calls += 1
                return rows[v]
            })
            let context = "\(rows)"
            // The model: positions in row order; startIndex reads rows up to the first non-empty one;
            // index(after: (s, r)) re-reads row s, then reads rows up to the next non-empty one.
            let model = (0 ..< n).flatMap { v in rows[v].indices.map { (v, $0) } }
            func rowsRead(from v: Int) -> Int {
                var count = 0
                var s = v
                while s < n {
                    count += 1
                    if !rows[s].isEmpty { break }
                    s += 1
                }
                return count
            }
            calls = 0
            var position = graph.edges.startIndex
            #expect(calls == rowsRead(from: 0), "\(context)")
            var stepped: [[Int]] = []
            while position != graph.edges.endIndex {
                stepped.append([position.source, position.rank, position.target])
                calls = 0
                let (s, r) = (position.source, position.rank)
                position = graph.edges.index(after: position)
                #expect(calls == (r + 1 < rows[s].count ? 1 : 1 + rowsRead(from: s + 1)), "\(context): after \(s).\(r)")
            }
            #expect(stepped == model.map { [$0.0, $0.1, rows[$0.0][$0.1]] }, "\(context)")
            #expect(graph.edges.isEmpty == model.isEmpty, "\(context)")
            // Ordered by (source, rank), and all distinct.
            let positions = graph.vertices.flatMap { Array(graph.outEdges(of: $0)) }
            #expect(positions == positions.sorted() && Set(positions).count == positions.count, "\(context)")
            #expect(zip(positions, positions.dropFirst()).allSatisfy { $0 < $1 && $0 != $1 }, "\(context)")
        }
    }

    @Test("Breadth-first layers equal a search written out over the rows, one call per discovered vertex")
    func layersAgainstModel() async {
        await propertyCheck(count: 300, input: Gen.int(in: 0 ... 1_000).array(of: 0 ... 3).array(of: 1 ... 20), Gen.int(in: 0 ... 1_000)) { raw, seed in
            let n = raw.count
            let rows = raw.map { row in row.map { $0 % n } }
            var calls = 0
            let graph = ImplicitDirectedGraph(vertexCount: n, successors: { (v: Int) -> [Int] in
                calls += 1
                return rows[v]
            })
            let source = seed % n
            var seen: Set<Int> = [source]
            var layers = [[source]]
            while true {
                var next: [Int] = []
                for u in layers.last! {
                    for w in rows[u] where seen.insert(w).inserted { next.append(w) }
                }
                if next.isEmpty { break }
                layers.append(next)
            }
            calls = 0
            #expect(graph.breadthFirstLayers(from: source) == layers, "\(rows) from \(source)")
            #expect(calls == seen.count, "\(rows) from \(source)")
            calls = 0
            let hops = graph.shortestPaths(from: source)
            #expect((0 ..< n).map { hops.distance(to: $0) } == (0 ..< n).map { v in layers.firstIndex { $0.contains(v) } }, "\(rows) from \(source)")
        }
    }

    @Test("D19: Dijkstra and A* over an unbounded grid agree with Dijkstra on an implicit box")
    func closureSearchesAgainstBox() async {
        await propertyCheck(count: 40, input: Gen.int(in: 2 ... 5), Gen.int(in: -5 ... 5), Gen.int(in: -5 ... 5)) { m, gx, gy in
            struct P: Hashable {
                var x, y: Int
            }
            // A step p → q costs 1 + (7·p.x + 13·q.y + 3·p.y·q.x) mod m, the mod taken non-negative: it
            // depends on both ends, so the goal's first discovery need not be its shortest path.
            let cost = { (p: P, q: P) -> Int in 1 + ((p.x * 7 + q.y * 13 + p.y * q.x * 3) % m + m) % m }
            let neighbors = { (p: P) -> [(P, Int)] in
                [P(x: p.x + 1, y: p.y), P(x: p.x - 1, y: p.y), P(x: p.x, y: p.y + 1), P(x: p.x, y: p.y - 1)].map { ($0, cost(p, $0)) }
            }
            let goal = P(x: gx, y: gy)
            var expanded = 0
            let dijkstra = dijkstraShortestPath(from: P(x: 0, y: 0), successors: { (p: P) -> [(P, Int)] in
                expanded += 1
                return neighbors(p)
            }, success: { $0 == goal })
            let aStar = aStarShortestPath(from: P(x: 0, y: 0), successors: neighbors, heuristic: { abs(goal.x - $0.x) + abs(goal.y - $0.y) }, success: { $0 == goal })
            // The same costs on an implicit 41 × 41 box centred on the start: slack enough, since a
            // path leaving it is longer than going round inside.
            let side = 41, half = 20
            let box = ImplicitDirectedGraph(vertexCount: side * side, successors: { (v: Int) -> [Int] in
                let (x, y) = (v % side - half, v / side - half)
                return [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)].filter { abs($0.0) <= half && abs($0.1) <= half }.map { ($0.1 + half) * side + $0.0 + half }
            })
            let tree = box.dijkstraShortestPaths(from: half * side + half) { cost(P(x: $0.source % side - half, y: $0.source / side - half), P(x: $0.target % side - half, y: $0.target / side - half)) }
            let want = tree.distance(to: (gy + half) * side + gx + half)
            #expect(dijkstra?.distance == want && aStar?.distance == want, "m \(m), goal \(goal)")
            for result in [dijkstra, aStar] {
                let path = result!.path
                #expect(path.first == P(x: 0, y: 0) && path.last == goal, "m \(m), goal \(goal)")
                #expect(zip(path, path.dropFirst()).reduce(0) { total, step in total + (abs(step.0.x - step.1.x) + abs(step.0.y - step.1.y) == 1 ? cost(step.0, step.1) : 1_000_000) } == want, "m \(m), goal \(goal)")
            }
            #expect(expanded > 0 || goal == P(x: 0, y: 0))
        }
    }
}
