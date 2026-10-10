// `vertexConnectivity()` and `vertexConnectivity(from:to:)` (catalog §VertexConnectivity): exact, on
// the simple graph; by brute force the fewest vertices whose removal disconnects (κ(G)), or
// separates s from t plus one for an edge from s to t (κ(s, t)); κ ≤ λ. Directed rows are
// `AdjacencyList`, or `DirectedPseudograph` when an edge repeats; undirected rows
// `UndirectedAdjacencyList`, or `Pseudograph` with parallel edges; each built by inserting the row's
// vertices, then its edges in order, so positions are the catalog's. In-test checks number vertices
// by their index in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row
// with ref.py's models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("vertexConnectivity")
struct VertexConnectivityTests {
    @Test("FL-320 empty graph: 0")
    func fl320() {
        // undirected V []; E []; vertexConnectivity()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 0)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-323 one vertex: 0")
    func fl323() {
        // undirected V [0]; E []; vertexConnectivity()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 0)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-326 two isolated vertices: 0")
    func fl326() {
        // undirected V [0, 1]; E []; vertexConnectivity()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 0)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-329 two isolated vertices: 0")
    func fl329() {
        // undirected V [0, 1]; E []; vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 0)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-332 K(2): κ = n − 1: all but the first vertex: 1")
    func fl332() {
        // K(2); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-335 K(2): κ = n − 1: all but the first vertex: 1")
    func fl335() {
        // K(2); vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-338 K(2) with parallel edges: λ counts copies, κ does not: 1")
    func fl338() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-341 K(2) with parallel edges: λ counts copies, κ does not: 1")
    func fl341() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-344 self-loops ignored: 1")
    func fl344() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-347 self-loops ignored: 1")
    func fl347() {
        // undirected V [0, 1, 2]; E [0–0, 0–1, 1–2, 2–2]; vertexConnectivity(from: 0, to: 2)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 2)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-350 path P(4): 1")
    func fl350() {
        // P(4); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-353 path P(4): 1")
    func fl353() {
        // P(4); vertexConnectivity(from: 0, to: 3)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 3)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-356 path P(4): 1")
    func fl356() {
        // P(4); vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-359 cycle C(5): 2")
    func fl359() {
        // C(5); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 2)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-362 cycle C(5): 2")
    func fl362() {
        // C(5); vertexConnectivity(from: 0, to: 2)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 2)
        #expect(kappa == 2)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-365 K(5): 4")
    func fl365() {
        // K(5); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 4)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-368 K(5): 4")
    func fl368() {
        // K(5); vertexConnectivity(from: 0, to: 4)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 4)
        #expect(kappa == 4)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-371 Kb(3,3): 3")
    func fl371() {
        // Kb(3,3); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 3), (0, 4), (0, 5), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 3)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-374 Kb(3,3): 3")
    func fl374() {
        // Kb(3,3); vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 3)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-377 Kb(3,3): 3")
    func fl377() {
        // Kb(3,3); vertexConnectivity(from: 0, to: 3)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 3)
        #expect(kappa == 3)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-380 wheel(5): 3")
    func fl380() {
        // wheel(5); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 3)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-383 wheel(5): 3")
    func fl383() {
        // wheel(5); vertexConnectivity(from: 1, to: 3)
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
        let kappa = graph.vertexConnectivity(from: 1, to: 3)
        #expect(kappa == 3)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-386 two triangles sharing a vertex: κ 1, λ 2: 1")
    func fl386() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-389 two triangles sharing a vertex: κ 1, λ 2: 1")
    func fl389() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; vertexConnectivity(from: 0, to: 4)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 4)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-392 two K(4) joined by two edges: 2")
    func fl392() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7), (5, 6), (5, 7), (6, 7), (0, 4), (1, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 2)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-395 two K(4) joined by two edges: 2")
    func fl395() {
        // undirected V [0, 1, 2, 3, 4, 5, 6, 7]; E [0–1, 0–2, 0–3, 1–2, 1–3, 2–3, 4–5, 4–6, 4–7, 5–6, 5–7, 6–7, 0–4, 1–5]; vertexConnectivity(from: 2, to: 6)
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
        let kappa = graph.vertexConnectivity(from: 2, to: 6)
        #expect(kappa == 2)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-398 disconnected: 0")
    func fl398() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 0)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-401 disconnected: 0")
    func fl401() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; vertexConnectivity(from: 0, to: 3)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 3)
        #expect(kappa == 0)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-404 Petersen: 3")
    func fl404() {
        // nx(petersen_graph); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 3)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-407 Petersen: 3")
    func fl407() {
        // nx(petersen_graph); vertexConnectivity(from: 0, to: 7)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 7)
        #expect(kappa == 3)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-410 hypercube Q(3): 3")
    func fl410() {
        // Q(3); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 4), (1, 3), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 6), (5, 7), (6, 7)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 3)
        // The simple graph, written out: neighbours both ways (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            out[b].insert(a)
        }
        let into = out
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-413 hypercube Q(3): 3")
    func fl413() {
        // Q(3); vertexConnectivity(from: 0, to: 7)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 7)
        #expect(kappa == 3)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-416 grid(3,4): 2")
    func fl416() {
        // grid(3,4); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 2)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-419 grid(3,4): 2")
    func fl419() {
        // grid(3,4); vertexConnectivity(from: 0, to: 11)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 11)
        #expect(kappa == 2)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-422 karate club: 1")
    func fl422() {
        // nx(karate_club_graph); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-425 karate club: 6")
    func fl425() {
        // nx(karate_club_graph); vertexConnectivity(from: 0, to: 33)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 33)
        #expect(kappa == 6)
        _ = adjacent
    }

    @Test("FL-428 directed: one edge: 0")
    func fl428() {
        // V [0, 1]; E [0→1]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 0)
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-431 directed: one edge: 1")
    func fl431() {
        // V [0, 1]; E [0→1]; vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-434 directed: one edge: 0")
    func fl434() {
        // V [0, 1]; E [0→1]; vertexConnectivity(from: 1, to: 0)
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
        let kappa = graph.vertexConnectivity(from: 1, to: 0)
        #expect(kappa == 0)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-437 directed: two-cycle: 1")
    func fl437() {
        // V [0, 1]; E [0→1, 1→0]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-440 directed: two-cycle: 1")
    func fl440() {
        // V [0, 1]; E [0→1, 1→0]; vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-443 directed: cycle Cd(4): 1")
    func fl443() {
        // Cd(4); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-446 directed: cycle Cd(4): 1")
    func fl446() {
        // Cd(4); vertexConnectivity(from: 0, to: 2)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 2)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-449 directed: complete Kd(4): 3")
    func fl449() {
        // Kd(4); vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3), (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 3)
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-452 directed: complete Kd(4): 3")
    func fl452() {
        // Kd(4); vertexConnectivity(from: 0, to: 3)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 3)
        #expect(kappa == 3)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-455 directed: adjacent pair counts the edge: 0")
    func fl455() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 0)
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-458 directed: adjacent pair counts the edge: 2")
    func fl458() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 2)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-461 directed: adjacent pair counts the edge: 0")
    func fl461() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; vertexConnectivity(from: 1, to: 0)
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
        let kappa = graph.vertexConnectivity(from: 1, to: 0)
        #expect(kappa == 0)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-464 directed: weakly but not strongly connected: 0")
    func fl464() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 0)
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-467 directed: weakly but not strongly connected: 0")
    func fl467() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; vertexConnectivity(from: 3, to: 0)
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
        let kappa = graph.vertexConnectivity(from: 3, to: 0)
        #expect(kappa == 0)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-470 directed: weakly but not strongly connected: 1")
    func fl470() {
        // V [0, 1, 2, 3]; E [0→1, 1→2, 2→0, 2→3]; vertexConnectivity(from: 0, to: 3)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 3)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-473 directed: bidirected C(5): 2")
    func fl473() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 2)
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-476 directed: bidirected C(5): 2")
    func fl476() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; vertexConnectivity(from: 0, to: 2)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 2)
        #expect(kappa == 2)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }

    @Test("FL-479 directed: parallel arcs: 1")
    func fl479() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; vertexConnectivity()
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let kappa = graph.vertexConnectivity()
        #expect(kappa == 1)
        // The simple graph, written out: out- and in-neighbours (self-loops dropped, parallel edges once).
        var out = [Set<Int>](repeating: [], count: n), into = [Set<Int>](repeating: [], count: n)
        for (a, b) in ends where a != b {
            out[a].insert(b)
            into[b].insert(a)
        }
        // Brute force: the fewest vertices whose removal leaves one vertex or a graph that is not (strongly)
        // connected; n − 1 when no smaller set does, and 0 below two vertices.
        var least = max(n - 1, 0)
        search: for size in 0 ..< max(n - 1, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size {
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
                if !connected {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least)
        // At most the edge connectivity (Whitney).
        #expect(kappa <= graph.edgeConnectivity())
    }

    @Test("FL-482 directed: parallel arcs: 1")
    func fl482() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; vertexConnectivity(from: 0, to: 1)
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
        let kappa = graph.vertexConnectivity(from: 0, to: 1)
        #expect(kappa == 1)
        // Brute force (Menger): the fewest other vertices whose removal separates s from t, plus one for
        // an edge from s to t.
        var least = -1
        search: for size in 0 ... max(n - 2, 0) {
            for removed in 0 ..< (1 << n) where removed.nonzeroBitCount == size && removed & (1 << s) == 0 && removed & (1 << t) == 0 {
                var seen: Set<Int> = [s]
                var queue = [s]
                while let x = queue.popLast() {
                    for y in out[x] where removed & (1 << y) == 0 && !seen.contains(y) && !(x == s && y == t) {
                        seen.insert(y)
                        queue.append(y)
                    }
                }
                let separated = !seen.contains(t)
                if separated {
                    least = size
                    break search
                }
            }
        }
        #expect(kappa == least + (adjacent ? 1 : 0))
    }
}
