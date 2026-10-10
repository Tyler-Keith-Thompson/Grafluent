// `minimumVertexCut()` and `minimumVertexCut(from:to:)` (catalog §MinimumVertexCut): the documented
// cut exactly (Even's pairs for the global one, the cut nearest the target for the local one); its
// size the connectivity; removing it disconnects, or separates s from t; nil when an edge goes from
// s to t. Directed rows are `AdjacencyList`, or `DirectedPseudograph` when an edge repeats;
// undirected rows `UndirectedAdjacencyList`, or `Pseudograph` with parallel edges; each built by
// inserting the row's vertices, then its edges in order, so positions are the catalog's. In-test
// checks number vertices by their index in `vertices`. Generated from cases.md by swiftgen.py, which
// re-evaluates each row with ref.py's models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("minimumVertexCut")
struct MinimumVertexCutTests {
    @Test("FL-321 empty graph: []")
    func fl321() {
        // undirected V []; E []; minimumVertexCut()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-324 one vertex: []")
    func fl324() {
        // undirected V [0]; E []; minimumVertexCut()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-327 two isolated vertices: []")
    func fl327() {
        // undirected V [0, 1]; E []; minimumVertexCut()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-330 two isolated vertices: []")
    func fl330() {
        // undirected V [0, 1]; E []; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        #expect(cut == [] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 1))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-333 K(2): κ = n − 1: all but the first vertex: [1]")
    func fl333() {
        // K(2); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-336 K(2): κ = n − 1: all but the first vertex: nil")
    func fl336() {
        // K(2); minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-339 K(2) with parallel edges: λ counts copies, κ does not: [1]")
    func fl339() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-342 K(2) with parallel edges: λ counts copies, κ does not: nil")
    func fl342() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-345 self-loops ignored: [1]")
    func fl345() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-348 self-loops ignored: [1]")
    func fl348() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; minimumVertexCut(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 2)
        #expect(cut == [1] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 2))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-351 path P(4): [1]")
    func fl351() {
        // P(4); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-354 path P(4): [2]")
    func fl354() {
        // P(4); minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 3)
        #expect(cut == [2] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 3))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-357 path P(4): nil")
    func fl357() {
        // P(4); minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-360 cycle C(5): [1, 3]")
    func fl360() {
        // C(5); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1, 3] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-363 cycle C(5): [1, 3]")
    func fl363() {
        // C(5); minimumVertexCut(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 2)
        #expect(cut == [1, 3] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 2))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-366 K(5): [1, 2, 3, 4]")
    func fl366() {
        // K(5); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1, 2, 3, 4] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-369 K(5): nil")
    func fl369() {
        // K(5); minimumVertexCut(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 4)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 4)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-372 Kb(3,3): [3, 4, 5]")
    func fl372() {
        // Kb(3,3); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [3, 4, 5] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-375 Kb(3,3): [3, 4, 5]")
    func fl375() {
        // Kb(3,3); minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        #expect(cut == [3, 4, 5] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 1))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-378 Kb(3,3): nil")
    func fl378() {
        // Kb(3,3); minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 3)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-381 wheel(5): [0, 2, 4]")
    func fl381() {
        // wheel(5); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [0, 2, 4] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-384 wheel(5): [0, 2, 4]")
    func fl384() {
        // wheel(5); minimumVertexCut(from: 1, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 3)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 1, to: 3)
        #expect(cut == [0, 2, 4] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 1, to: 3))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-387 two triangles sharing a vertex: κ 1, λ 2: [2]")
    func fl387() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [2] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-390 two triangles sharing a vertex: κ 1, λ 2: [2]")
    func fl390() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; minimumVertexCut(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 4)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 4)
        #expect(cut == [2] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 4))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-393 two K(4) joined by two edges: [1, 4]")
    func fl393() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1, 4] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-396 two K(4) joined by two edges: [4, 5]")
    func fl396() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; minimumVertexCut(from: 2, to: 6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 2)!
        let t = vertexList.firstIndex(of: 6)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 2, to: 6)
        #expect(cut == [4, 5] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 2, to: 6))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-399 disconnected: []")
    func fl399() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-402 disconnected: []")
    func fl402() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 3)
        #expect(cut == [] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 3))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-405 Petersen: [1, 3, 7]")
    func fl405() {
        // nx(petersen_graph); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1, 3, 7] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-408 Petersen: [2, 5, 9]")
    func fl408() {
        // nx(petersen_graph); minimumVertexCut(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 7)
        #expect(cut == [2, 5, 9] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 7))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-411 hypercube Q(3): [1, 2, 7]")
    func fl411() {
        // Q(3); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1, 2, 7] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-414 hypercube Q(3): [3, 5, 6]")
    func fl414() {
        // Q(3); minimumVertexCut(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 7)
        #expect(cut == [3, 5, 6] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 7))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-417 grid(3,4): [1, 4]")
    func fl417() {
        // grid(3,4); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1, 4] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-420 grid(3,4): [7, 10]")
    func fl420() {
        // grid(3,4); minimumVertexCut(from: 0, to: 11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 11)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 11)
        #expect(cut == [7, 10] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 11))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-423 karate club: [0]")
    func fl423() {
        // nx(karate_club_graph); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [0] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-426 karate club: [2, 8, 13, 19, 30, 31]")
    func fl426() {
        // nx(karate_club_graph); minimumVertexCut(from: 0, to: 33)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 33)!
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 33)
        #expect(cut == [2, 8, 13, 19, 30, 31] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 33))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-429 directed: one edge: []")
    func fl429() {
        // V [0, 1]; E [0→1]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-432 directed: one edge: nil")
    func fl432() {
        // V [0, 1]; E [0→1]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-435 directed: one edge: []")
    func fl435() {
        // V [0, 1]; E [0→1]; minimumVertexCut(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 0)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 1, to: 0)
        #expect(cut == [] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 1, to: 0))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-438 directed: two-cycle: [1]")
    func fl438() {
        // V [0, 1]; E [0→1, 1→0]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-441 directed: two-cycle: nil")
    func fl441() {
        // V [0, 1]; E [0→1, 1→0]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-444 directed: cycle Cd(4): [3]")
    func fl444() {
        // Cd(4); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [3] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-447 directed: cycle Cd(4): [1]")
    func fl447() {
        // Cd(4); minimumVertexCut(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 2)
        #expect(cut == [1] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 2))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-450 directed: complete Kd(4): [1, 2, 3]")
    func fl450() {
        // Kd(4); minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1, 2, 3] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-453 directed: complete Kd(4): nil")
    func fl453() {
        // Kd(4); minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 3)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-456 directed: adjacent pair counts the edge: []")
    func fl456() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-459 directed: adjacent pair counts the edge: nil")
    func fl459() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }

    @Test("FL-462 directed: adjacent pair counts the edge: []")
    func fl462() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; minimumVertexCut(from: 1, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 1)!
        let t = vertexList.firstIndex(of: 0)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 1, to: 0)
        #expect(cut == [] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 1, to: 0))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-465 directed: weakly but not strongly connected: []")
    func fl465() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-468 directed: weakly but not strongly connected: []")
    func fl468() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; minimumVertexCut(from: 3, to: 0)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 3)!
        let t = vertexList.firstIndex(of: 0)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 3, to: 0)
        #expect(cut == [] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 3, to: 0))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-471 directed: weakly but not strongly connected: [2]")
    func fl471() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; minimumVertexCut(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 3)
        #expect(cut == [2] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 3))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-474 directed: bidirected C(5): [1, 3]")
    func fl474() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [1, 3] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-477 directed: bidirected C(5): [1, 3]")
    func fl477() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; minimumVertexCut(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 2)
        #expect(cut == [1, 3] as [Int])
        #expect(!adjacent)
        #expect(cut?.count == graph.vertexConnectivity(from: 0, to: 2))
        // Removing it separates s from t.
        let removed = vertexList.indices.reduce(0) { (cut ?? []).contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        var seen: Set<Int> = [s]
        var queue = [s]
        while let x = queue.popLast() {
            for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                seen.insert(y)
                queue.append(y)
            }
        }
        let separated = !seen.contains(t)
        #expect(separated)
    }

    @Test("FL-480 directed: parallel arcs: [2]")
    func fl480() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; minimumVertexCut()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let cut = graph.minimumVertexCut()
        #expect(cut == [2] as [Int])
        #expect(cut.count == graph.vertexConnectivity())
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        let removed = vertexList.indices.reduce(0) { cut.contains(vertexList[$1]) ? $0 | (1 << $1) : $0 }
        // Removing it leaves one vertex or a graph that is not (strongly) connected; when κ = n − 1 the cut
        // is every vertex after the first.
        let kept = (0 ..< n).filter { removed & (1 << $0) == 0 }
        var connected = kept.count >= 2
        if connected {
            for rows in [out, into] {
                var seen: Set<Int> = [kept[0]]
                var queue = [kept[0]]
                while let x = queue.popLast() {
                    for y in rows[x] where removed & (1 << y) == 0 && !seen.contains(y) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                if seen.count != kept.count { connected = false }
            }
        }
        #expect(!connected || n < 2)
        if n >= 2 && cut.count == n - 1 { #expect(cut == Array(vertexList.dropFirst())) }
    }

    @Test("FL-483 directed: parallel arcs: nil")
    func fl483() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; minimumVertexCut(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Whether an edge goes from s to t: it counts as one path, and no vertex set separates them.
        let adjacent = out[s].contains(t)
        // Whether t is reachable from s avoiding the vertices in `removed`, without the edges from s to t.
        let cut = graph.minimumVertexCut(from: 0, to: 1)
        // An edge from s to t: no vertex set separates them.
        #expect(adjacent)
        #expect(cut == nil)
    }
}
