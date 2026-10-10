// `chromaticNumber()` (catalog §ChromaticNumber): χ of the simple graph, exact; `minimumColoring()`
// a proper colouring with χ colours (checked here) and no greedy strategy below it; on rows of at
// most 20 vertices the least k with a proper k-colouring by exhaustive search; χ ≥ ω, the clique
// number by brute force on rows of at most 16 vertices and a clique checked here otherwise;
// bipartite exactly when χ ≤ 2. Graphs are `UndirectedAdjacencyList` built by inserting the row's
// vertices, then its edges in order, so rows are in position order (a self-loop twice); `multigraph`
// rows are `ReferencePseudograph`, whose rows are in position order too; `L …; R …` and the `Kb`,
// `crown` and `lcgb` rows are `BipartiteGraph(left:right:edges:)`. In-test oracles number vertices
// by their index in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row
// with ref.py's model; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("chromaticNumber()")
struct ChromaticNumberTests {
    @Test("CO-129 empty graph: 0")
    func co129() {
        // V []; E []; chromaticNumber()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 0)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-130 one vertex: 1")
    func co130() {
        // V [0]; E []; chromaticNumber()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 1)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-131 self-loop ignored: 1")
    func co131() {
        // V [0]; E [0-0]; chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 1)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
    }

    @Test("CO-132 edgeless: 1")
    func co132() {
        // V [0, 1]; E []; chromaticNumber()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 1)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-133 one edge: 2")
    func co133() {
        // V [0, 1]; E [0-1]; chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 1)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 2)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-134 parallel edges: 2")
    func co134() {
        // multigraph V [0, 1, 2]; E [0-1, 1-0, 1-2]; chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = ReferencePseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 3)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 2)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-135 K(1): 1")
    func co135() {
        // K(1); chromaticNumber()
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: [0] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 0)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 1)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-136 K(4): 4")
    func co136() {
        // K(4); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 4)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-137 K(7): 7")
    func co137() {
        // K(7); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 3), (2, 4), (2, 5), (2, 6), (3, 4), (3, 5), (3, 6), (4, 5), (4, 6), (5, 6)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 21)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 7)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-138 path P(6): 2")
    func co138() {
        // P(6); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 2)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-139 cycle C(4): 2")
    func co139() {
        // C(4); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 4)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 2)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-140 cycle C(5): 3")
    func co140() {
        // C(5); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-141 cycle C(9): 3")
    func co141() {
        // C(9); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 9)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-142 wheel(4): even rim, 3: 3")
    func co142() {
        // wheel(4); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (2, 3), (3, 4), (4, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 8)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-143 wheel(5): odd rim, 4: 4")
    func co143() {
        // wheel(5); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 4)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-144 wheel(8): 3")
    func co144() {
        // wheel(8); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 16)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-145 Petersen: 3")
    func co145() {
        // nx(petersen_graph); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 15)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-146 nx(mycielski_graph,3): C5: 3")
    func co146() {
        // nx(mycielski_graph,3); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (2, 4), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 5)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-147 nx(mycielski_graph,4): Groetzsch, triangle-free, 4: 4")
    func co147() {
        // nx(mycielski_graph,4); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (1, 2), (1, 7), (1, 5), (2, 4), (2, 9), (2, 6), (3, 4), (3, 9), (3, 5), (4, 7), (4, 8), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 4)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-148 nx(mycielski_graph,5): 23 vertices, triangle-free, 5: 5")
    func co148() {
        // nx(mycielski_graph,5); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (0, 6), (0, 8), (0, 12), (0, 14), (0, 17), (0, 19), (1, 2), (1, 7), (1, 5), (1, 13), (1, 18), (1, 16), (1, 11), (2, 4), (2, 9), (2, 6), (2, 15), (2, 20), (2, 17), (2, 12), (3, 4), (3, 9), (3, 5), (3, 15), (3, 20), (3, 16), (3, 11), (4, 7), (4, 8), (4, 18), (4, 19), (4, 13), (4, 14), (5, 10), (5, 21), (5, 12), (5, 14), (6, 10), (6, 21), (6, 11), (6, 13), (7, 10), (7, 21), (7, 12), (7, 15), (8, 10), (8, 21), (8, 11), (8, 15), (9, 10), (9, 21), (9, 13), (9, 14), (10, 16), (10, 17), (10, 18), (10, 19), (10, 20), (11, 22), (12, 22), (13, 22), (14, 22), (15, 22), (16, 22), (17, 22), (18, 22), (19, 22), (20, 22), (21, 22)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 71)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 5)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // 23 vertices, too many for the search here: χ = 5 is the literature value (ref.py).
        // χ ≥ ω: a clique of 2 (found by swiftgen.py with NetworkX's find_cliques), checked here.
        let clique = [21, 22]
        for a in clique { for b in clique where a < b { #expect(adjacent[a].contains(b)) } }
        #expect(chi >= clique.count)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-149 nx(chvatal_graph): 4")
    func co149() {
        // nx(chvatal_graph); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 6), (0, 9), (1, 2), (1, 5), (1, 7), (2, 3), (2, 6), (2, 8), (3, 4), (3, 7), (3, 9), (4, 5), (4, 8), (5, 10), (5, 11), (6, 10), (6, 11), (7, 8), (7, 11), (8, 10), (9, 10), (9, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 4)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-150 crown(5): 2")
    func co150() throws {
        // crown(5); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 6), (0, 7), (0, 8), (0, 9), (1, 5), (1, 7), (1, 8), (1, 9), (2, 5), (2, 6), (2, 8), (2, 9), (3, 5), (3, 6), (3, 7), (3, 9), (4, 5), (4, 6), (4, 7), (4, 8)]
        let graph = try #require(BipartiteGraph<Int>(left: [0, 1, 2, 3, 4] as [Int], right: [5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(graph.edgeCount == 20)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 2)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-151 crownx(6): 2")
    func co151() {
        // crownx(6); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 3), (0, 5), (0, 7), (0, 9), (0, 11), (2, 1), (2, 5), (2, 7), (2, 9), (2, 11), (4, 1), (4, 3), (4, 7), (4, 9), (4, 11), (6, 1), (6, 3), (6, 5), (6, 9), (6, 11), (8, 1), (8, 3), (8, 5), (8, 7), (8, 11), (10, 1), (10, 3), (10, 5), (10, 7), (10, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 2)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-152 queen(4): 5")
    func co152() {
        // queen(4); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 8), (0, 10), (0, 12), (0, 15), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 9), (1, 11), (1, 13), (2, 3), (2, 5), (2, 6), (2, 7), (2, 8), (2, 10), (2, 14), (3, 6), (3, 7), (3, 9), (3, 11), (3, 12), (3, 15), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 12), (4, 14), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 13), (5, 15), (6, 7), (6, 9), (6, 10), (6, 11), (6, 12), (6, 14), (7, 10), (7, 11), (7, 13), (7, 15), (8, 9), (8, 10), (8, 11), (8, 12), (8, 13), (9, 10), (9, 11), (9, 12), (9, 13), (9, 14), (10, 11), (10, 13), (10, 14), (10, 15), (11, 14), (11, 15), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 76)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 5)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-153 queen(5): 5")
    func co153() {
        // queen(5); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 10), (0, 12), (0, 15), (0, 18), (0, 20), (0, 24), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 11), (1, 13), (1, 16), (1, 19), (1, 21), (2, 3), (2, 4), (2, 6), (2, 7), (2, 8), (2, 10), (2, 12), (2, 14), (2, 17), (2, 22), (3, 4), (3, 7), (3, 8), (3, 9), (3, 11), (3, 13), (3, 15), (3, 18), (3, 23), (4, 8), (4, 9), (4, 12), (4, 14), (4, 16), (4, 19), (4, 20), (4, 24), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 16), (6, 18), (6, 21), (6, 24), (7, 8), (7, 9), (7, 11), (7, 12), (7, 13), (7, 15), (7, 17), (7, 19), (7, 22), (8, 9), (8, 12), (8, 13), (8, 14), (8, 16), (8, 18), (8, 20), (8, 23), (9, 13), (9, 14), (9, 17), (9, 19), (9, 21), (9, 24), (10, 11), (10, 12), (10, 13), (10, 14), (10, 15), (10, 16), (10, 20), (10, 22), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 21), (11, 23), (12, 13), (12, 14), (12, 16), (12, 17), (12, 18), (12, 20), (12, 22), (12, 24), (13, 14), (13, 17), (13, 18), (13, 19), (13, 21), (13, 23), (14, 18), (14, 19), (14, 22), (14, 24), (15, 16), (15, 17), (15, 18), (15, 19), (15, 20), (15, 21), (16, 17), (16, 18), (16, 19), (16, 20), (16, 21), (16, 22), (17, 18), (17, 19), (17, 21), (17, 22), (17, 23), (18, 19), (18, 22), (18, 23), (18, 24), (19, 23), (19, 24), (20, 21), (20, 22), (20, 23), (20, 24), (21, 22), (21, 23), (21, 24), (22, 23), (22, 24), (23, 24)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 160)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 5)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // 25 vertices, too many for the search here: χ = 5 is the literature value (ref.py).
        // χ ≥ ω: a clique of 5 (found by swiftgen.py with NetworkX's find_cliques), checked here.
        let clique = [20, 21, 22, 23, 24]
        for a in clique { for b in clique where a < b { #expect(adjacent[a].contains(b)) } }
        #expect(chi >= clique.count)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-154 queen(6): 7")
    func co154() {
        // queen(6); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 12), (0, 14), (0, 18), (0, 21), (0, 24), (0, 28), (0, 30), (0, 35), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 13), (1, 15), (1, 19), (1, 22), (1, 25), (1, 29), (1, 31), (2, 3), (2, 4), (2, 5), (2, 7), (2, 8), (2, 9), (2, 12), (2, 14), (2, 16), (2, 20), (2, 23), (2, 26), (2, 32), (3, 4), (3, 5), (3, 8), (3, 9), (3, 10), (3, 13), (3, 15), (3, 17), (3, 18), (3, 21), (3, 27), (3, 33), (4, 5), (4, 9), (4, 10), (4, 11), (4, 14), (4, 16), (4, 19), (4, 22), (4, 24), (4, 28), (4, 34), (5, 10), (5, 11), (5, 15), (5, 17), (5, 20), (5, 23), (5, 25), (5, 29), (5, 30), (5, 35), (6, 7), (6, 8), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 18), (6, 20), (6, 24), (6, 27), (6, 30), (6, 34), (7, 8), (7, 9), (7, 10), (7, 11), (7, 12), (7, 13), (7, 14), (7, 19), (7, 21), (7, 25), (7, 28), (7, 31), (7, 35), (8, 9), (8, 10), (8, 11), (8, 13), (8, 14), (8, 15), (8, 18), (8, 20), (8, 22), (8, 26), (8, 29), (8, 32), (9, 10), (9, 11), (9, 14), (9, 15), (9, 16), (9, 19), (9, 21), (9, 23), (9, 24), (9, 27), (9, 33), (10, 11), (10, 15), (10, 16), (10, 17), (10, 20), (10, 22), (10, 25), (10, 28), (10, 30), (10, 34), (11, 16), (11, 17), (11, 21), (11, 23), (11, 26), (11, 29), (11, 31), (11, 35), (12, 13), (12, 14), (12, 15), (12, 16), (12, 17), (12, 18), (12, 19), (12, 24), (12, 26), (12, 30), (12, 33), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19), (13, 20), (13, 25), (13, 27), (13, 31), (13, 34), (14, 15), (14, 16), (14, 17), (14, 19), (14, 20), (14, 21), (14, 24), (14, 26), (14, 28), (14, 32), (14, 35), (15, 16), (15, 17), (15, 20), (15, 21), (15, 22), (15, 25), (15, 27), (15, 29), (15, 30), (15, 33), (16, 17), (16, 21), (16, 22), (16, 23), (16, 26), (16, 28), (16, 31), (16, 34), (17, 22), (17, 23), (17, 27), (17, 29), (17, 32), (17, 35), (18, 19), (18, 20), (18, 21), (18, 22), (18, 23), (18, 24), (18, 25), (18, 30), (18, 32), (19, 20), (19, 21), (19, 22), (19, 23), (19, 24), (19, 25), (19, 26), (19, 31), (19, 33), (20, 21), (20, 22), (20, 23), (20, 25), (20, 26), (20, 27), (20, 30), (20, 32), (20, 34), (21, 22), (21, 23), (21, 26), (21, 27), (21, 28), (21, 31), (21, 33), (21, 35), (22, 23), (22, 27), (22, 28), (22, 29), (22, 32), (22, 34), (23, 28), (23, 29), (23, 33), (23, 35), (24, 25), (24, 26), (24, 27), (24, 28), (24, 29), (24, 30), (24, 31), (25, 26), (25, 27), (25, 28), (25, 29), (25, 30), (25, 31), (25, 32), (26, 27), (26, 28), (26, 29), (26, 31), (26, 32), (26, 33), (27, 28), (27, 29), (27, 32), (27, 33), (27, 34), (28, 29), (28, 33), (28, 34), (28, 35), (29, 34), (29, 35), (30, 31), (30, 32), (30, 33), (30, 34), (30, 35), (31, 32), (31, 33), (31, 34), (31, 35), (32, 33), (32, 34), (32, 35), (33, 34), (33, 35), (34, 35)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 290)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 7)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // 36 vertices, too many for the search here: χ = 7 is the literature value (ref.py).
        // χ ≥ ω: a clique of 6 (found by swiftgen.py with NetworkX's find_cliques), checked here.
        let clique = [30, 31, 32, 33, 34, 35]
        for a in clique { for b in clique where a < b { #expect(adjacent[a].contains(b)) } }
        #expect(chi >= clique.count)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-155 grid(4,4): 2")
    func co155() {
        // grid(4,4); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14), (11, 15), (12, 13), (13, 14), (14, 15)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 24)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 2)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-156 nx(dodecahedral_graph): 3")
    func co156() {
        // nx(dodecahedral_graph); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 19), (0, 10), (1, 2), (1, 8), (2, 3), (2, 6), (3, 4), (3, 19), (4, 5), (4, 17), (5, 6), (5, 15), (6, 7), (7, 8), (7, 14), (8, 9), (9, 10), (9, 13), (10, 11), (11, 12), (11, 18), (12, 13), (12, 16), (13, 14), (14, 15), (15, 16), (16, 17), (17, 18), (18, 19)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: a clique of 2 (found by swiftgen.py with NetworkX's find_cliques), checked here.
        let clique = [18, 19]
        for a in clique { for b in clique where a < b { #expect(adjacent[a].contains(b)) } }
        #expect(chi >= clique.count)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-157 nx(icosahedral_graph): 4")
    func co157() {
        // nx(icosahedral_graph); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 5), (0, 7), (0, 8), (0, 11), (1, 2), (1, 5), (1, 6), (1, 8), (2, 3), (2, 6), (2, 8), (2, 9), (3, 4), (3, 6), (3, 9), (3, 10), (4, 5), (4, 6), (4, 10), (4, 11), (5, 6), (5, 11), (7, 8), (7, 9), (7, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 30)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 4)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-158 nx(octahedral_graph): 3")
    func co158() {
        // nx(octahedral_graph); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 12)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-159 nx(heawood_graph): 2")
    func co159() {
        // nx(heawood_graph); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 13), (0, 5), (1, 2), (1, 10), (2, 3), (2, 7), (3, 4), (3, 12), (4, 5), (4, 9), (5, 6), (6, 7), (6, 11), (7, 8), (8, 9), (8, 13), (9, 10), (10, 11), (11, 12), (12, 13)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 21)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 2)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-160 nx(frucht_graph): 3")
    func co160() {
        // nx(frucht_graph); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 6), (0, 7), (1, 2), (1, 7), (2, 3), (2, 8), (3, 4), (3, 9), (4, 5), (4, 9), (5, 6), (5, 10), (6, 10), (7, 11), (8, 11), (8, 9), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 18)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-161 nx(karate_club_graph): 5")
    func co161() {
        // nx(karate_club_graph); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 78)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 5)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // χ ≥ ω: a clique of 5 (found by swiftgen.py with NetworkX's find_cliques), checked here.
        let clique = [0, 1, 2, 3, 13]
        for a in clique { for b in clique where a < b { #expect(adjacent[a].contains(b)) } }
        #expect(chi >= clique.count)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-162 components: max over components: 4")
    func co162() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [0-1, 1-2, 2-0, 3-4, 5-6, 6-7, 7-8, 8-5, 5-7, 6-8]; chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (5, 6), (6, 7), (7, 8), (8, 5), (5, 7), (6, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 10)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 4)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-163 lcg(14,40,5): 4")
    func co163() {
        // lcg(14,40,5); chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 11), (4, 1), (3, 5), (12, 2), (8, 7), (8, 13), (12, 8), (6, 8), (13, 2), (1, 11), (10, 5), (9, 1), (0, 1), (12, 4), (2, 6), (6, 0), (6, 4), (2, 8), (3, 6), (13, 10), (9, 5), (4, 8), (3, 8), (0, 12), (9, 13), (11, 10), (4, 3), (6, 13), (8, 11), (11, 13), (5, 13), (8, 1), (0, 2), (2, 7), (6, 1), (9, 6), (0, 13), (3, 12), (7, 13), (9, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 40)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 4)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-164 lcg(16,60,9): 5")
    func co164() {
        // lcg(16,60,9); chromaticNumber()
        let pairs: [(Int, Int)] = [(11, 1), (8, 4), (12, 3), (11, 5), (11, 3), (12, 6), (9, 14), (14, 15), (15, 2), (3, 2), (13, 11), (15, 12), (1, 5), (10, 13), (8, 0), (9, 0), (13, 8), (1, 0), (9, 4), (8, 2), (7, 0), (3, 15), (14, 13), (8, 15), (12, 2), (0, 3), (7, 12), (4, 12), (4, 6), (7, 6), (14, 5), (0, 5), (14, 11), (14, 0), (12, 10), (6, 9), (12, 5), (10, 4), (13, 12), (15, 13), (13, 9), (8, 14), (13, 2), (8, 9), (6, 10), (14, 10), (7, 9), (1, 8), (2, 0), (15, 6), (10, 5), (5, 6), (8, 7), (2, 11), (10, 8), (11, 9), (6, 13), (1, 13), (12, 14), (5, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 60)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 5)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-165 lcg(18,70,2): 5")
    func co165() {
        // lcg(18,70,2); chromaticNumber()
        let pairs: [(Int, Int)] = [(10, 12), (0, 14), (11, 5), (0, 6), (9, 2), (17, 14), (10, 16), (12, 17), (14, 7), (14, 2), (8, 2), (13, 0), (17, 1), (9, 10), (9, 13), (17, 16), (6, 16), (15, 2), (10, 14), (2, 17), (1, 7), (0, 2), (0, 3), (15, 0), (14, 4), (6, 17), (17, 8), (14, 15), (15, 8), (0, 10), (1, 2), (6, 15), (8, 6), (3, 12), (0, 1), (0, 4), (17, 9), (7, 9), (3, 14), (12, 4), (1, 10), (4, 5), (12, 9), (7, 16), (6, 11), (6, 7), (6, 13), (8, 16), (15, 5), (13, 7), (0, 5), (1, 4), (4, 7), (0, 11), (11, 10), (6, 10), (4, 15), (12, 11), (13, 4), (9, 15), (3, 5), (2, 11), (8, 9), (11, 1), (10, 8), (8, 13), (6, 3), (13, 11), (8, 12), (14, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 70)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 5)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: a clique of 4 (found by swiftgen.py with NetworkX's find_cliques), checked here.
        let clique = [8, 9, 12, 17]
        for a in clique { for b in clique where a < b { #expect(adjacent[a].contains(b)) } }
        #expect(chi >= clique.count)
        // Bipartite exactly when χ ≤ 2 (no self-loops here).
        #expect((graph.bipartition() != nil) == (chi <= 2))
    }

    @Test("CO-166 odd cycle with a self-loop: 3")
    func co166() {
        // V [0, 1, 2, 3, 4]; E [0-1, 1-2, 2-3, 3-4, 4-0, 2-2]; chromaticNumber()
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 2)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(graph.edgeCount == 6)
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        // Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let chi = graph.chromaticNumber()
        #expect(chi == 3)
        // minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.
        let minimum = graph.minimumColoring()
        #expect(minimum.colorCount == chi)
        let colors = vertexList.map { minimum.color(of: $0) }
        for (a, b) in ends where a != b { #expect(colors[a] != colors[b], "\(vertexList[a])–\(vertexList[b])") }
        #expect(Set(colors).count == chi)
        for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, "\(strategy)") }
        // The simple graph, written out: each vertex's distinct other neighbours, in the order their first
        // edges come in its row (positions ascending); self-loops dropped, parallel edges once.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Brute force: the least k for which an exhaustive search finds a proper colouring with k colours
        // (vertices in order of degree, descending; each takes a colour at most one above those used).
        let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
        func colorable(_ k: Int) -> Bool {
            var colour = [Int](repeating: -1, count: n)
            func place(_ i: Int, _ used: Int) -> Bool {
                if i == n { return true }
                let v = byDegree[i]
                for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {
                    colour[v] = c
                    if place(i + 1, max(used, c + 1)) { return true }
                }
                colour[v] = -1
                return false
            }
            return place(0, 0)
        }
        #expect(chi == (0 ... n).first(where: colorable))
        // χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).
        let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }
        var omega = 0
        for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {
            omega = max(omega, mask.nonzeroBitCount)
        }
        #expect(chi >= omega)
    }
}
