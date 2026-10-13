// Attached maps (catalog AM-01 – AM-09): maps attached to an AdjacencyList or an
// UndirectedAdjacencyList (`PropertyGraph`): defaults for existing and new elements, values moved
// with the swap-remove of an edge or a vertex, `removeAll` and `removeAllEdges` emptying them,
// handles and copies, equality and coding ignoring them, and `values(of:)` snapshots. A removed
// element has no value: the checked reads throw. Each test is self-contained.

import AdjacencyListModule
import Foundation
import GraphProtocols
import Testing

@Suite("AdjacencyList attached maps")
struct AdjacencyListMapTests {
    @Test("AM-01 a map gives every existing and every new element its default")
    func defaults() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let weights = graph.addEdgeMap(default: 1.5)
        let ranks = graph.addVertexMap(default: -1)
        #expect((0 ..< graph.edgeCount).map { graph[weights, ofEdgeAt: $0] } == [1.5, 1.5])
        #expect(graph.vertices.map { graph[ranks, of: $0] } == [-1, -1, -1])
        graph[weights, ofEdgeAt: 1] = 4
        graph[ranks, of: 2] = 7
        #expect(graph.insert(edge: DirectedEdge(from: 2, to: 3)).inserted)
        #expect(graph[weights, ofEdgeAt: 2] == 1.5)
        #expect(graph[ranks, of: 3] == -1)
        #expect(graph[weights, ofEdgeAt: 1] == 4)
        #expect(graph[ranks, of: 2] == 7)
        // An edge already present inserts nothing, and so appends no value.
        #expect(!graph.insert(edge: DirectedEdge(from: 0, to: 1)).inserted)
        #expect(graph.values(of: weights)[2] == 1.5)
        #expect(throws: EdgeNotFound.self) { try graph[weights, checkedEdgeAt: 3] }
        // Bulk construction has no maps; one attached after reaches every edge.
        var built = AdjacencyList<Int>(edges: [DirectedEdge(from: 0, to: 1)])
        built.reserveCapacity(vertexCount: 10, edgeCount: 10)
        let late = built.addEdgeMap(default: "x")
        #expect(built[late, ofEdgeAt: 0] == "x")
        #expect(built.values(of: late).defaultValue == "x")
    }

    @Test("AM-02 addEdgeMap(of:) and addVertexMap(of:) are Optional maps whose default is nil")
    func optionalMaps() throws {
        var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let labels = graph.addEdgeMap(of: String.self)
        let names = graph.addVertexMap(of: String.self)
        #expect(graph[labels, ofEdgeAt: 0] == nil)
        graph[labels, ofEdgeAt: 0] = "a"
        graph[names, of: 1] = "one"
        #expect(graph[labels, ofEdgeAt: 0] == "a")
        #expect(try graph[labels, checkedEdgeAt: 0] == "a")
        #expect(try graph[names, checked: 1] == "one")
        #expect(try graph[names, checkedVertexAt: graph.vertexIndex(of: 1)] == "one")
        graph[labels, ofEdgeAt: 0] = nil
        #expect(graph[labels, ofEdgeAt: 0] == nil)
        #expect(graph.values(of: names).defaultValue == nil)
    }

    @Test("AM-03 removing an edge moves the last edge's value into its position")
    func edgeRemovalMovesValues() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 2, to: 2)])
        let w = graph.addEdgeMap(default: 0)
        for p in 0 ..< graph.edgeCount { graph[w, ofEdgeAt: p] = 10 * graph.source(ofEdgeAt: p) + graph.target(ofEdgeAt: p) }
        #expect(graph.remove(edge: DirectedEdge(from: 0, to: 1)) != nil)
        #expect(graph.edgeCount == 3)
        for p in 0 ..< graph.edgeCount {
            #expect(graph[w, ofEdgeAt: p] == 10 * graph.source(ofEdgeAt: p) + graph.target(ofEdgeAt: p))
        }
        // The last edge goes without moving anything.
        let last = graph.edges[graph.edgeCount - 1]
        #expect(graph.remove(edge: last) == last)
        #expect(graph.edges.indices.map { graph[w, ofEdgeAt: $0] } == graph.edges.map { 10 * $0.source + $0.target })

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 2), UndirectedEdge(0, 2)])
        let uw = undirected.addEdgeMap(default: 0)
        for p in 0 ..< undirected.edgeCount {
            let e = undirected.edges[p]
            undirected[uw, ofEdgeAt: p] = 10 * min(e.u, e.v) + max(e.u, e.v)
        }
        #expect(undirected.remove(edge: UndirectedEdge(1, 0)) != nil)
        #expect(undirected.remove(edge: UndirectedEdge(2, 2)) != nil)
        #expect(undirected.edges.indices.map { undirected[uw, ofEdgeAt: $0] } == undirected.edges.map { 10 * min($0.u, $0.v) + max($0.u, $0.v) })
    }

    @Test("AM-04 removing a vertex removes its edges' values and moves the last vertex's value into its slot")
    func vertexRemovalMovesValues() throws {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 1), DirectedEdge(from: 3, to: 3)])
        let w = graph.addEdgeMap(default: 0)
        let name = graph.addVertexMap(default: "")
        for p in 0 ..< graph.edgeCount { graph[w, ofEdgeAt: p] = 10 * graph.source(ofEdgeAt: p) + graph.target(ofEdgeAt: p) }
        for v in graph.vertices { graph[name, of: v] = "v\(v)" }
        #expect(graph.remove(1) == 1)
        #expect(graph.vertexCount == 3)
        for v in graph.vertices {
            #expect(graph[name, of: v] == "v\(v)")
            #expect(graph[name, ofVertexAt: graph.vertexIndex(of: v)] == "v\(v)")
        }
        #expect(graph.edges.indices.map { graph[w, ofEdgeAt: $0] }.sorted() == [23, 33])
        #expect(graph.edges.indices.allSatisfy { graph[w, ofEdgeAt: $0] == 10 * graph.edges[$0].source + graph.edges[$0].target })
        #expect(throws: VertexNotFound.self) { try graph[name, checked: 1] }
        #expect(throws: VertexNotFound.self) { try graph[name, checkedVertexAt: 3] }
        #expect(throws: VertexNotFound.self) { try graph[name, checkedVertexAt: -1] }
        // Removing the vertex in the last slot moves nothing.
        let lastVertex = graph.vertices[graph.vertexCount - 1]
        #expect(graph.remove(lastVertex) == lastVertex)
        #expect(graph.vertices.allSatisfy { graph[name, of: $0] == "v\($0)" })
        #expect(graph.values(of: name)[0] == "v\(graph.vertices[0])")

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(3, 3)])
        let uw = undirected.addEdgeMap(default: 0)
        let un = undirected.addVertexMap(default: 0)
        for p in 0 ..< undirected.edgeCount {
            let e = undirected.edges[p]
            undirected[uw, ofEdgeAt: p] = 10 * min(e.u, e.v) + max(e.u, e.v)
        }
        for v in undirected.vertices { undirected[un, of: v] = v * v }
        #expect(undirected.remove(0) == 0)
        #expect(undirected.vertices.allSatisfy { undirected[un, of: $0] == $0 * $0 })
        #expect(undirected.edges.indices.map { undirected[uw, ofEdgeAt: $0] } == undirected.edges.map { 10 * min($0.u, $0.v) + max($0.u, $0.v) })
        #expect(undirected.edges.indices.map { undirected[uw, ofEdgeAt: $0] }.sorted() == [12, 23, 33])
    }

    @Test("AM-05 removeAll and removeAllEdges empty the maps and keep them attached")
    func removeAllKeepsMaps() throws {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let w = graph.addEdgeMap(default: 1)
        let r = graph.addVertexMap(default: 2)
        graph[w, ofEdgeAt: 0] = 5
        graph[r, of: 0] = 6
        graph.removeAllEdges()
        #expect(throws: EdgeNotFound.self) { try graph[w, checkedEdgeAt: 0] }
        #expect(graph[r, of: 0] == 6)
        graph.insert(edge: DirectedEdge(from: 1, to: 0))
        #expect(graph[w, ofEdgeAt: 0] == 1)
        graph.removeAll(keepingCapacity: true)
        #expect(throws: VertexNotFound.self) { try graph[r, checked: 0] }
        graph.insert(edge: DirectedEdge(from: 0, to: 1))
        #expect(graph[w, ofEdgeAt: 0] == 1)
        #expect(graph[r, of: 0] == 2 && graph[r, of: 1] == 2)

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        let uw = undirected.addEdgeMap(default: 1)
        let ur = undirected.addVertexMap(default: 2)
        undirected[uw, ofEdgeAt: 0] = 5
        undirected[ur, of: 1] = 6
        undirected.removeAllEdges(keepingCapacity: true)
        #expect(throws: EdgeNotFound.self) { try undirected[uw, checkedEdgeAt: 0] }
        #expect(undirected[ur, of: 1] == 6)
        undirected.removeAll()
        undirected.insert(edge: UndirectedEdge(1, 0))
        #expect(undirected[uw, ofEdgeAt: 0] == 1 && undirected[ur, of: 1] == 2)
    }

    @Test("AM-06 handles: several maps, removeEdgeMap, and a copy that shares then diverges")
    func handlesAndCopies() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let a = graph.addEdgeMap(default: 0)
        let b = graph.addEdgeMap(default: "")
        let c = graph.addVertexMap(default: 0.0)
        #expect(a != graph.addEdgeMap(default: 0))
        graph[a, ofEdgeAt: 0] = 1
        graph[b, ofEdgeAt: 1] = "b"
        graph.removeEdgeMap(a)
        // A later handle still finds its map after an earlier one was removed (its hint is stale).
        #expect(graph[b, ofEdgeAt: 1] == "b")
        graph[c, of: 2] = 2.5
        graph.removeVertexMap(c)
        let d = graph.addVertexMap(default: 9)
        #expect(graph[d, of: 2] == 9)

        var copy = graph
        copy[b, ofEdgeAt: 1] = "changed"
        copy.remove(edge: DirectedEdge(from: 0, to: 1))
        #expect(graph[b, ofEdgeAt: 1] == "b")
        #expect(graph.edgeCount == 2)
        #expect(copy[b, ofEdgeAt: 0] == "changed")
        // Equality ignores the maps.
        var bare = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        #expect(bare == graph && bare.hashValue == graph.hashValue)
        _ = bare.addEdgeMap(default: 3)
        #expect(bare == graph)

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        let u = undirected.addEdgeMap(default: 0)
        var undirectedCopy = undirected
        undirectedCopy[u, ofEdgeAt: 0] = 4
        #expect(undirected[u, ofEdgeAt: 0] == 0 && undirectedCopy[u, ofEdgeAt: 0] == 4)
        #expect(undirected == undirectedCopy)
    }

    @Test("AM-06 a copy that attaches or removes a map, or writes one, leaves the original's later mutations to the original")
    func copyReplacesTable() {
        let triggers: [(String, (inout AdjacencyList<Int>, EdgeMap<Double>) -> Void)] = [
            ("addEdgeMap", { graph, _ in _ = graph.addEdgeMap(default: 0) }),
            ("addVertexMap", { graph, _ in _ = graph.addVertexMap(default: 0) }),
            ("removeEdgeMap", { graph, weights in graph.removeEdgeMap(weights) }),
            ("a map write", { graph, weights in graph[weights, ofEdgeAt: 2] = 9 }),
        ]
        let mutations: [(String, (inout AdjacencyList<Int>) -> Void)] = [
            ("remove(edge:)", { _ = $0.remove(edge: DirectedEdge(from: 0, to: 1)) }),
            ("_removeEdge(at:)", { _ = $0._removeEdge(at: 1) }),
            ("insert(edge:)", { _ = $0.insert(edge: DirectedEdge(from: 3, to: 0)) }),
            ("remove(_:)", { _ = $0.remove(1) }),
            ("removeAllEdges", { $0.removeAllEdges(keepingCapacity: true) }),
        ]
        for (trigger, replace) in triggers {
            for (name, mutate) in mutations {
                var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
                graph.reserveCapacity(vertexCount: 8, edgeCount: 8)
                let weights = graph.addEdgeMap(default: 0.0)
                for p in 0 ..< 3 { graph[weights, ofEdgeAt: p] = Double(p) + 1.5 }
                var copy = graph
                replace(&copy, weights)
                let expected: [Double] = trigger == "removeEdgeMap" ? [] : [1.5, 2.5, trigger == "a map write" ? 9 : 3.5]
                let snapshot = expected.isEmpty ? nil : copy.values(of: weights)
                mutate(&graph)
                if !expected.isEmpty {
                    #expect((0 ..< 3).map { copy[weights, ofEdgeAt: $0] } == expected, "\(trigger) on the copy, then \(name)")
                    #expect(snapshot.map { s in (0 ..< 3).map { s[$0] } } == expected, "\(trigger) on the copy, then \(name)")
                }
                #expect(copy.edgeCount == 3, "\(trigger) on the copy, then \(name)")
            }
        }

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let w = undirected.addEdgeMap(default: 0.0)
        for p in 0 ..< 3 { undirected[w, ofEdgeAt: p] = Double(p) + 1.5 }
        var copy = undirected
        _ = copy.addEdgeMap(default: 0)
        _ = undirected.remove(edge: UndirectedEdge(0, 1))
        _ = undirected.remove(2)
        #expect((0 ..< 3).map { copy[w, ofEdgeAt: $0] } == [1.5, 2.5, 3.5])
        #expect(undirected.edgeCount == 0 && copy.edgeCount == 3)
    }

    @Test("AM-06 two copies keep their own values whichever mutates first: every mutation on one, then every mutation on the other, both lists")
    func copiesMutatedInTurn() {
        // One edge map of Ints (the one-map fast paths of the upkeep) and a vertex map. The copies
        // share every array and table; the first mutation of either copies what it writes, and
        // the other then mutates storage only it holds. Each copy's values must be what its own
        // mutation alone gives a fresh graph.
        func directed() -> (AdjacencyList<Int>, EdgeMap<Int>, VertexMap<Double>) {
            var graph = AdjacencyList<Int>(vertices: 0 ..< 4)
            let weights = graph.addEdgeMap(default: -1)
            let ranks = graph.addVertexMap(default: 0.5)
            for (s, t) in [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)] { graph.insert(edge: DirectedEdge(from: s, to: t)) }
            for p in 0 ..< graph.edgeCount { graph[weights, ofEdgeAt: p] = 100 * graph.edges[p].source + graph.edges[p].target }
            for v in graph.vertices { graph[ranks, of: v] = Double(v) }
            return (graph, weights, ranks)
        }
        let directedSteps: [(String, (inout AdjacencyList<Int>, EdgeMap<Int>, VertexMap<Double>) -> Void)] = [
            ("insert(_:)", { g, _, _ in g.insert(9) }),
            ("insert(edge:)", { g, _, _ in g.insert(edge: DirectedEdge(from: 1, to: 3)) }),
            ("insert(edge:) of a new vertex", { g, _, _ in g.insert(edge: DirectedEdge(from: 3, to: 8)) }),
            ("insert(edge:) 0→3", { g, _, _ in g.insert(edge: DirectedEdge(from: 0, to: 3)) }),
            ("remove(edge:)", { g, _, _ in g.remove(edge: DirectedEdge(from: 1, to: 2)) }),
            ("remove(edge:) of the last", { g, _, _ in g.remove(edge: DirectedEdge(from: 0, to: 2)) }),
            ("_removeEdge(at:)", { g, _, _ in _ = g._removeEdge(at: 0) }),
            ("remove(_:)", { g, _, _ in g.remove(2) }),
            ("reserveCapacity", { g, _, _ in g.reserveCapacity(vertexCount: 64, edgeCount: 64) }),
            ("removeAllEdges", { g, _, _ in g.removeAllEdges(keepingCapacity: true) }),
            ("removeAll", { g, _, _ in g.removeAll() }),
            ("an edge value written", { g, w, _ in g[w, ofEdgeAt: 1] = -7 }),
            ("a vertex value written", { g, _, r in g[r, of: 0] = -7 }),
        ]
        // Every value is its element's own (set by `directed()`), the default (an element inserted
        // since) or the written -7; and each map holds one value per element.
        func state(_ g: AdjacencyList<Int>, _ w: EdgeMap<Int>, _ r: VertexMap<Double>) -> [String] {
            let values = (0 ..< g.edgeCount).map { "\(g.edges[$0])=\(g[w, ofEdgeAt: $0])" } + g.vertices.map { "\($0)=\(g[r, of: $0])" }
            let own = (0 ..< g.edgeCount).allSatisfy { [100 * g.edges[$0].source + g.edges[$0].target, -1, -7].contains(g[w, ofEdgeAt: $0]) }
                && g.vertices.allSatisfy { [Double($0), 0.5, -7].contains(g[r, of: $0]) }
            let counts = g.values(of: w)._storage.dense.count == g.edgeCount && g.values(of: r)._storage.dense.count == g.vertexCount
            return values + ["own values: \(own)", "one value per element: \(counts)"]
        }
        func directedReplay(_ names: [String]) -> [String] {
            var (g, w, r) = directed()
            for name in names { directedSteps.first { $0.0 == name }!.1(&g, w, r) }
            return state(g, w, r)
        }
        for (first, a) in directedSteps {
            for (second, b) in directedSteps {
                for firstOnCopy in [true, false] {
                    var (original, w, r) = directed()
                    var copy = original
                    if firstOnCopy { a(&copy, w, r); b(&original, w, r) } else { a(&original, w, r); b(&copy, w, r) }
                    let label = "\(first) on the \(firstOnCopy ? "copy" : "original"), then \(second) on the other"
                    #expect(state(firstOnCopy ? copy : original, w, r) == directedReplay([first]), "AdjacencyList: \(label): the first")
                    #expect(state(original, w, r).suffix(2) == ["own values: true", "one value per element: true"] && state(copy, w, r).suffix(2) == ["own values: true", "one value per element: true"], "AdjacencyList: \(label): own values")
                    #expect(state(firstOnCopy ? original : copy, w, r) == directedReplay([second]), "AdjacencyList: \(label): the second")
                    // Each then goes on alone.
                    original.insert(edge: DirectedEdge(from: 0, to: 3))
                    copy.insert(edge: DirectedEdge(from: 0, to: 3))
                    let originalSteps = firstOnCopy ? [second] : [first], copySteps = firstOnCopy ? [first] : [second]
                    #expect(state(original, w, r) == directedReplay(originalSteps + ["insert(edge:) 0→3"]), "AdjacencyList: \(label): then an insertion on the original")
                    #expect(state(copy, w, r) == directedReplay(copySteps + ["insert(edge:) 0→3"]), "AdjacencyList: \(label): then an insertion on the copy")
                }
            }
        }

        func undirected() -> (UndirectedAdjacencyList<Int>, EdgeMap<Int>, VertexMap<Double>) {
            var graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4)
            let weights = graph.addEdgeMap(default: -1)
            let ranks = graph.addVertexMap(default: 0.5)
            for (u, v) in [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)] { graph.insert(edge: UndirectedEdge(u, v)) }
            for p in 0 ..< graph.edgeCount { graph[weights, ofEdgeAt: p] = 100 * graph.edges[p].u + graph.edges[p].v }
            for v in graph.vertices { graph[ranks, of: v] = Double(v) }
            return (graph, weights, ranks)
        }
        let undirectedSteps: [(String, (inout UndirectedAdjacencyList<Int>, EdgeMap<Int>, VertexMap<Double>) -> Void)] = [
            ("insert(_:)", { g, _, _ in g.insert(9) }),
            ("insert(edge:)", { g, _, _ in g.insert(edge: UndirectedEdge(1, 3)) }),
            ("insert(edge:) of a new vertex", { g, _, _ in g.insert(edge: UndirectedEdge(3, 8)) }),
            ("insert(edge:) 0–3", { g, _, _ in g.insert(edge: UndirectedEdge(0, 3)) }),
            ("remove(edge:)", { g, _, _ in g.remove(edge: UndirectedEdge(2, 1)) }),
            ("remove(edge:) of the last", { g, _, _ in g.remove(edge: UndirectedEdge(0, 2)) }),
            ("remove(_:)", { g, _, _ in g.remove(2) }),
            ("reserveCapacity", { g, _, _ in g.reserveCapacity(vertexCount: 64, edgeCount: 64) }),
            ("removeAllEdges", { g, _, _ in g.removeAllEdges(keepingCapacity: true) }),
            ("removeAll", { g, _, _ in g.removeAll() }),
            ("an edge value written", { g, w, _ in g[w, ofEdgeAt: 1] = -7 }),
            ("a vertex value written", { g, _, r in g[r, of: 0] = -7 }),
        ]
        func undirectedState(_ g: UndirectedAdjacencyList<Int>, _ w: EdgeMap<Int>, _ r: VertexMap<Double>) -> [String] {
            let values = (0 ..< g.edgeCount).map { "\(g.edges[$0])=\(g[w, ofEdgeAt: $0])" } + g.vertices.map { "\($0)=\(g[r, of: $0])" }
            let own = (0 ..< g.edgeCount).allSatisfy { [100 * g.edges[$0].u + g.edges[$0].v, -1, -7].contains(g[w, ofEdgeAt: $0]) }
                && g.vertices.allSatisfy { [Double($0), 0.5, -7].contains(g[r, of: $0]) }
            let counts = g.values(of: w)._storage.dense.count == g.edgeCount && g.values(of: r)._storage.dense.count == g.vertexCount
            return values + ["own values: \(own)", "one value per element: \(counts)"]
        }
        func undirectedReplay(_ names: [String]) -> [String] {
            var (g, w, r) = undirected()
            for name in names { undirectedSteps.first { $0.0 == name }!.1(&g, w, r) }
            return undirectedState(g, w, r)
        }
        for (first, a) in undirectedSteps {
            for (second, b) in undirectedSteps {
                for firstOnCopy in [true, false] {
                    var (original, w, r) = undirected()
                    var copy = original
                    if firstOnCopy { a(&copy, w, r); b(&original, w, r) } else { a(&original, w, r); b(&copy, w, r) }
                    let label = "\(first) on the \(firstOnCopy ? "copy" : "original"), then \(second) on the other"
                    #expect(undirectedState(firstOnCopy ? copy : original, w, r) == undirectedReplay([first]), "UndirectedAdjacencyList: \(label): the first")
                    #expect(undirectedState(original, w, r).suffix(2) == ["own values: true", "one value per element: true"] && undirectedState(copy, w, r).suffix(2) == ["own values: true", "one value per element: true"], "UndirectedAdjacencyList: \(label): own values")
                    #expect(undirectedState(firstOnCopy ? original : copy, w, r) == undirectedReplay([second]), "UndirectedAdjacencyList: \(label): the second")
                    original.insert(edge: UndirectedEdge(0, 3))
                    copy.insert(edge: UndirectedEdge(0, 3))
                    let originalSteps = firstOnCopy ? [second] : [first], copySteps = firstOnCopy ? [first] : [second]
                    #expect(undirectedState(original, w, r) == undirectedReplay(originalSteps + ["insert(edge:) 0–3"]), "UndirectedAdjacencyList: \(label): then an insertion on the original")
                    #expect(undirectedState(copy, w, r) == undirectedReplay(copySteps + ["insert(edge:) 0–3"]), "UndirectedAdjacencyList: \(label): then an insertion on the copy")
                }
            }
        }
    }

    @Test("AM-07 Codable and conversions carry no maps; the identity conversion keeps them")
    func codingAndConversion() throws {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1)])
        let w = graph.addEdgeMap(default: 1)
        graph[w, ofEdgeAt: 0] = 2
        var decoded = try JSONDecoder().decode(AdjacencyList<Int>.self, from: JSONEncoder().encode(graph))
        #expect(decoded == graph)
        let fresh = decoded.addEdgeMap(default: 7)
        #expect(decoded[fresh, ofEdgeAt: 0] == 7)
        let same = AdjacencyList(graph)
        #expect(same[w, ofEdgeAt: 0] == 2)

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        let uw = undirected.addEdgeMap(default: 1)
        undirected[uw, ofEdgeAt: 0] = 2
        let undirectedDecoded = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(undirected))
        #expect(undirectedDecoded == undirected)
        #expect(UndirectedAdjacencyList(undirected)[uw, ofEdgeAt: 0] == 2)
    }

    @Test("AM-08 values(of:) is a snapshot read by position, like an array")
    func valuesSnapshot() {
        var graph = AdjacencyList(edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let w = graph.addEdgeMap(default: 0.0)
        let r = graph.addVertexMap(default: 0)
        for p in 0 ..< graph.edgeCount { graph[w, ofEdgeAt: p] = Double(p) + 0.5 }
        for v in graph.vertices { graph[r, of: v] = v + 100 }
        let values = graph.values(of: w)
        let ranks = graph.values(of: r)
        #expect((0 ..< 3).map { values[$0] } == [0.5, 1.5, 2.5])
        #expect(graph.vertices.map { ranks[graph.vertexIndex(of: $0)] } == [100, 101, 102])
        graph[w, ofEdgeAt: 0] = 9
        graph.remove(edge: DirectedEdge(from: 1, to: 2))
        // The snapshot keeps what it saw.
        #expect((0 ..< 3).map { values[$0] } == [0.5, 1.5, 2.5])
        let now = graph.values(of: w)
        #expect((0 ..< graph.edgeCount).map { now[$0] } == [9, 2.5])
        // An algorithm's weight closure.
        let total = graph.edges.indices.reduce(0.0) { $0 + now[$1] }
        #expect(total == 11.5)

        var undirected = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let uw = undirected.addEdgeMap(default: 2)
        let uv = undirected.addVertexMap(default: 3)
        #expect(undirected.values(of: uw)[1] == 2)
        #expect(undirected.values(of: uv)[2] == 3)
    }

    @Test("AM-09 views read the base's values by vertex; the undirected graph's directed view too")
    func throughViews() throws {
        var graph = UndirectedAdjacencyList(edges: [UndirectedEdge(0, 1)])
        let r = graph.addVertexMap(default: 0)
        graph[r, of: 1] = 5
        let directed = graph.directedView
        #expect(directed[r, of: 1] == 5)
        #expect(directed[r, of: 0] == 0)
        #expect(throws: VertexNotFound.self) { try directed[r, checked: 2] }
    }
}
