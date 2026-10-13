// Attached maps on copies: two copies of a pseudograph share every array and map table until one
// mutates, and a pseudograph's map upkeep then relies on the stamp of its identity array to know
// its tables are its own. Every mutation on one copy, then every mutation on the other, in both
// orders: each copy's values must be what its own mutation alone gives a fresh graph, and so must
// a further insertion on each. Hand-written; see README.md.

import GraphProtocols
import Multigraphs
import Testing

@Suite("Multigraphs attached maps on copies")
struct MultigraphMapCopyTests {
    @Test("DirectedPseudograph: two copies keep their own values whichever mutates first")
    func directedCopies() {
        func fresh() -> (DirectedPseudograph<Int>, EdgeMap<Int>, VertexMap<Double>) {
            var graph = DirectedPseudograph<Int>(vertices: 0 ..< 4)
            let weights = graph.addEdgeMap(default: -1)
            let ranks = graph.addVertexMap(default: 0.5)
            for (s, t) in [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (0, 1)] { graph.insert(edge: DirectedEdge(from: s, to: t)) }
            for p in 0 ..< graph.edgeCount { graph[weights, ofEdgeAt: p] = 100 * graph.edges[p].source + graph.edges[p].target }
            for v in graph.vertices { graph[ranks, of: v] = Double(v) }
            return (graph, weights, ranks)
        }
        let steps: [(String, (inout DirectedPseudograph<Int>, EdgeMap<Int>, VertexMap<Double>) -> Void)] = [
            ("insert(_:)", { g, _, _ in g.insert(9) }),
            ("insert(edge:)", { g, _, _ in g.insert(edge: DirectedEdge(from: 1, to: 3)) }),
            ("insert(edge:) of a new vertex", { g, _, _ in g.insert(edge: DirectedEdge(from: 3, to: 8)) }),
            ("insert(edge:) 0→3", { g, _, _ in g.insert(edge: DirectedEdge(from: 0, to: 3)) }),
            ("remove(edge:)", { g, _, _ in g.remove(edge: DirectedEdge(from: 0, to: 1)) }),
            ("remove(edgeAt: 1)", { g, _, _ in g.remove(edgeAt: 1) }),
            ("remove(edgeAt:) of the last", { g, _, _ in g.remove(edgeAt: 5) }),
            ("removeAllEdges(from:to:)", { g, _, _ in g.removeAllEdges(from: 0, to: 1) }),
            ("remove(_:)", { g, _, _ in g.remove(2) }),
            ("reserveCapacity", { g, _, _ in g.reserveCapacity(vertexCount: 64, edgeCount: 64) }),
            ("removeAllEdges", { g, _, _ in g.removeAllEdges(keepingCapacity: true) }),
            ("removeAll", { g, _, _ in g.removeAll() }),
            ("an edge value written", { g, w, _ in g[w, ofEdgeAt: 1] = -7 }),
            ("a vertex value written", { g, _, r in g[r, of: 0] = -7 }),
        ]
        // Every value is its element's own (set by `fresh()`), the default (an element inserted
        // since) or the written -7; and each map holds one value per element.
        func state(_ g: DirectedPseudograph<Int>, _ w: EdgeMap<Int>, _ r: VertexMap<Double>) -> [String] {
            let values = (0 ..< g.edgeCount).map { "\(g.edges[$0])=\(g[w, ofEdgeAt: $0])" } + g.vertices.map { "\($0)=\(g[r, of: $0])" }
            let own = (0 ..< g.edgeCount).allSatisfy { [100 * g.edges[$0].source + g.edges[$0].target, -1, -7].contains(g[w, ofEdgeAt: $0]) }
                && g.vertices.allSatisfy { [Double($0), 0.5, -7].contains(g[r, of: $0]) }
            let counts = g.values(of: w)._storage.dense.count == g.edgeCount && g.values(of: r)._storage.dense.count == g.vertexCount
            return values + ["own values: \(own)", "one value per element: \(counts)"]
        }
        func replay(_ names: [String]) -> [String] {
            var (g, w, r) = fresh()
            for name in names { steps.first { $0.0 == name }!.1(&g, w, r) }
            return state(g, w, r)
        }
        for (first, a) in steps {
            for (second, b) in steps {
                for firstOnCopy in [true, false] {
                    var (original, w, r) = fresh()
                    var copy = original
                    if firstOnCopy { a(&copy, w, r); b(&original, w, r) } else { a(&original, w, r); b(&copy, w, r) }
                    let label = "\(first) on the \(firstOnCopy ? "copy" : "original"), then \(second) on the other"
                    #expect(state(firstOnCopy ? copy : original, w, r) == replay([first]), "\(label): the first")
                    #expect(state(original, w, r).suffix(2) == ["own values: true", "one value per element: true"] && state(copy, w, r).suffix(2) == ["own values: true", "one value per element: true"], "\(label): own values")
                    #expect(state(firstOnCopy ? original : copy, w, r) == replay([second]), "\(label): the second")
                    original.insert(edge: DirectedEdge(from: 0, to: 3))
                    copy.insert(edge: DirectedEdge(from: 0, to: 3))
                    let originalSteps = firstOnCopy ? [second] : [first], copySteps = firstOnCopy ? [first] : [second]
                    #expect(state(original, w, r) == replay(originalSteps + ["insert(edge:) 0→3"]), "\(label): then an insertion on the original")
                    #expect(state(copy, w, r) == replay(copySteps + ["insert(edge:) 0→3"]), "\(label): then an insertion on the copy")
                }
            }
        }
    }

    @Test("Pseudograph: two copies keep their own values whichever mutates first")
    func undirectedCopies() {
        func fresh() -> (Pseudograph<Int>, EdgeMap<Int>, VertexMap<Double>) {
            var graph = Pseudograph<Int>(vertices: 0 ..< 4)
            let weights = graph.addEdgeMap(default: -1)
            let ranks = graph.addVertexMap(default: 0.5)
            for (u, v) in [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (1, 0)] { graph.insert(edge: UndirectedEdge(u, v)) }
            for p in 0 ..< graph.edgeCount { graph[weights, ofEdgeAt: p] = 100 * graph.edges[p].u + graph.edges[p].v }
            for v in graph.vertices { graph[ranks, of: v] = Double(v) }
            return (graph, weights, ranks)
        }
        let steps: [(String, (inout Pseudograph<Int>, EdgeMap<Int>, VertexMap<Double>) -> Void)] = [
            ("insert(_:)", { g, _, _ in g.insert(9) }),
            ("insert(edge:)", { g, _, _ in g.insert(edge: UndirectedEdge(1, 3)) }),
            ("insert(edge:) of a new vertex", { g, _, _ in g.insert(edge: UndirectedEdge(3, 8)) }),
            ("insert(edge:) 0–3", { g, _, _ in g.insert(edge: UndirectedEdge(0, 3)) }),
            ("remove(edge:)", { g, _, _ in g.remove(edge: UndirectedEdge(0, 1)) }),
            ("remove(edgeAt: 1)", { g, _, _ in g.remove(edgeAt: 1) }),
            ("remove(edgeAt:) of the last", { g, _, _ in g.remove(edgeAt: 5) }),
            ("removeAllEdges(between:and:)", { g, _, _ in g.removeAllEdges(between: 0, and: 1) }),
            ("remove(_:)", { g, _, _ in g.remove(2) }),
            ("reserveCapacity", { g, _, _ in g.reserveCapacity(vertexCount: 64, edgeCount: 64) }),
            ("removeAllEdges", { g, _, _ in g.removeAllEdges(keepingCapacity: true) }),
            ("removeAll", { g, _, _ in g.removeAll() }),
            ("an edge value written", { g, w, _ in g[w, ofEdgeAt: 1] = -7 }),
            ("a vertex value written", { g, _, r in g[r, of: 0] = -7 }),
        ]
        func state(_ g: Pseudograph<Int>, _ w: EdgeMap<Int>, _ r: VertexMap<Double>) -> [String] {
            let values = (0 ..< g.edgeCount).map { "\(g.edges[$0])=\(g[w, ofEdgeAt: $0])" } + g.vertices.map { "\($0)=\(g[r, of: $0])" }
            let own = (0 ..< g.edgeCount).allSatisfy { [100 * g.edges[$0].u + g.edges[$0].v, -1, -7].contains(g[w, ofEdgeAt: $0]) }
                && g.vertices.allSatisfy { [Double($0), 0.5, -7].contains(g[r, of: $0]) }
            let counts = g.values(of: w)._storage.dense.count == g.edgeCount && g.values(of: r)._storage.dense.count == g.vertexCount
            return values + ["own values: \(own)", "one value per element: \(counts)"]
        }
        func replay(_ names: [String]) -> [String] {
            var (g, w, r) = fresh()
            for name in names { steps.first { $0.0 == name }!.1(&g, w, r) }
            return state(g, w, r)
        }
        for (first, a) in steps {
            for (second, b) in steps {
                for firstOnCopy in [true, false] {
                    var (original, w, r) = fresh()
                    var copy = original
                    if firstOnCopy { a(&copy, w, r); b(&original, w, r) } else { a(&original, w, r); b(&copy, w, r) }
                    let label = "\(first) on the \(firstOnCopy ? "copy" : "original"), then \(second) on the other"
                    #expect(state(firstOnCopy ? copy : original, w, r) == replay([first]), "\(label): the first")
                    #expect(state(original, w, r).suffix(2) == ["own values: true", "one value per element: true"] && state(copy, w, r).suffix(2) == ["own values: true", "one value per element: true"], "\(label): own values")
                    #expect(state(firstOnCopy ? original : copy, w, r) == replay([second]), "\(label): the second")
                    original.insert(edge: UndirectedEdge(0, 3))
                    copy.insert(edge: UndirectedEdge(0, 3))
                    let originalSteps = firstOnCopy ? [second] : [first], copySteps = firstOnCopy ? [first] : [second]
                    #expect(state(original, w, r) == replay(originalSteps + ["insert(edge:) 0–3"]), "\(label): then an insertion on the original")
                    #expect(state(copy, w, r) == replay(copySteps + ["insert(edge:) 0–3"]), "\(label): then an insertion on the copy")
                }
            }
        }
    }
}
