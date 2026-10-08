// The protocol's laws on a multigraph (the test conformer in Multigraph.swift), where parallel
// edges must count once per copy, and on seeded random graphs through every representation.
// Case IDs (DG-Lnn, DG-Rnn, DG-Pnn) refer to the catalog in README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("DirectedGraph laws on a multigraph and on random graphs")
struct DirectedGraphLawTests {
    @Test("DG-L01 – L14, L19 – L27 the laws with repeated edges", .tags(.fixture), arguments: DirectedFixture<Int>.all + DirectedFixture<Int>.realWorld)
    func multigraphLaws(_ fixture: DirectedFixture<Int>) {
        func check<G: BidirectionalDirectedGraph>(_ g: G) {
            let edges = Array(g.edges)
            #expect(g.edgeCount == edges.count)
            var outSum = 0
            var inSum = 0
            var outSeen = Set<G.Edges.Index>()
            var inSeen = Set<G.Edges.Index>()
            for v in g.vertices {
                let successors = Array(g.successors(of: v))
                let predecessors = Array(g.predecessors(of: v))
                // Once per edge, repeats included, in edge order for this conformer.
                #expect(successors == edges.filter { $0.source == v }.map(\.target))
                #expect(predecessors == edges.filter { $0.target == v }.map(\.source))
                #expect(g.outDegree(of: v) == successors.count)
                #expect(g.inDegree(of: v) == predecessors.count)
                #expect(g.degree(of: v) == successors.count + predecessors.count)
                #expect(g.outEdges(of: v).map { g.target(ofEdgeAt: $0) } == successors)
                #expect(g.inEdges(of: v).map { g.source(ofEdgeAt: $0) } == predecessors)
                for e in g.outEdges(of: v) { #expect(outSeen.insert(e).inserted) }
                for e in g.inEdges(of: v) { #expect(inSeen.insert(e).inserted) }
                outSum += g.outDegree(of: v)
                inSum += g.inDegree(of: v)
            }
            #expect(outSum == g.edgeCount)
            #expect(inSum == g.edgeCount)
            #expect(outSeen == Set(g.edges.indices))
            #expect(inSeen == Set(g.edges.indices))
            for e in edges {
                #expect(g.contains(edge: e))
            }
            // L27: vertices are in index order.
            if let n = g.vertexIndexBound {
                #expect(g.vertices.map { g.vertexIndex(of: $0) } == Array(0 ..< n))
            }
        }
        check(Multigraph(vertices: fixture.vertices, edges: fixture.edges))
    }

    @Test("DG-R10 / DG-R11 repeated edges through the protocol")
    func repeatedEdges() {
        func check(_ g: some BidirectionalDirectedGraph<Int>, out: [Int: [Int]], in into: [Int: [Int]], degree: [Int: Int]) {
            for (v, successors) in out { #expect(Array(g.successors(of: v)) == successors, "successors(of: \(v))") }
            for (v, predecessors) in into { #expect(Array(g.predecessors(of: v)) == predecessors, "predecessors(of: \(v))") }
            for (v, d) in degree { #expect(g.degree(of: v) == d, "degree(of: \(v))") }
        }
        let chord = Multigraph(edges: DirectedFixture<Int>.pathWithChord.edges)
        #expect(chord.edgeCount == 7)
        check(chord, out: [1: [2, 3, 3]], in: [3: [2, 1, 1]], degree: [1: 4])
        let sparse = Multigraph(edges: DirectedFixture<Int>.jgraphtSparseDirected.edges)
        #expect(sparse.edgeCount == 13)
        check(sparse, out: [2: [4, 4, 4]], in: [4: [1, 2, 2, 2, 3]], degree: [7: 3])
        // The three copies of 2→4 are three positions.
        #expect(Array(sparse.outEdges(of: 2)) == [5, 6, 7])
    }

    @Test("DG-P01 the laws on seeded random graphs, the same through every representation", .tags(.randomized), arguments: [1, 2, 3, 4, 5, 6, 7, 8])
    func randomGraphs(_ seed: Int) {
        var generator = SeededRandomNumberGenerator(seed: UInt(seed))
        let n = Int.random(in: 1 ... 30, using: &generator)
        var edges: [DirectedEdge<Int>] = []
        for _ in 0 ..< Int.random(in: 0 ... 3 * n, using: &generator) {
            edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator)))
        }
        // Everything a generic algorithm can observe, as plain values.
        func observe<G: DirectedGraph<Int>>(_ g: G) -> [[Int]] {
            var rows: [[Int]] = [[g.vertexCount, g.edgeCount]]
            for v in 0 ..< n {
                rows.append(Array(g.successors(of: v)).sorted())
                rows.append([g.outDegree(of: v), g.outEdges(of: v).map { g.target(ofEdgeAt: $0) }.count])
                rows.append((0 ..< n).map { g.contains(edge: DirectedEdge(from: v, to: $0)) ? 1 : 0 })
            }
            return rows
        }
        let distinct = Array(Set(edges))
        let list = AdjacencyList(vertices: 0 ..< n, edges: edges)
        let expected = observe(Multigraph(vertices: 0 ..< n, edges: distinct))
        #expect(observe(list) == expected)
        #expect(observe(AdjacencyMatrix(vertexCount: n, edges: edges)) == expected)
        #expect(observe(CompressedSparseRow(vertexCount: n, edges: edges)) == expected)
        #expect(observe(AdjacencyList(CompressedSparseRow(list))) == expected)
    }

    @Test("DG-P02 strongly connected components come out in reverse topological order", .tags(.randomized), arguments: [1, 2, 3, 4, 5, 6])
    func componentOrder(_ seed: Int) {
        // Tarjan emits a component only after every component it reaches.
        func components<G: DirectedGraph>(_ g: G) -> [Set<G.Vertex>] {
            var index: [G.Vertex: Int] = [:]
            var lowLink: [G.Vertex: Int] = [:]
            var onStack = Set<G.Vertex>()
            var stack: [G.Vertex] = []
            var result: [Set<G.Vertex>] = []
            var counter = 0
            func connect(_ v: G.Vertex) {
                index[v] = counter
                lowLink[v] = counter
                counter += 1
                stack.append(v)
                onStack.insert(v)
                for w in g.successors(of: v) {
                    if index[w] == nil {
                        connect(w)
                        lowLink[v] = min(lowLink[v]!, lowLink[w]!)
                    } else if onStack.contains(w) {
                        lowLink[v] = min(lowLink[v]!, index[w]!)
                    }
                }
                if lowLink[v] == index[v] {
                    var component = Set<G.Vertex>()
                    while true {
                        let w = stack.removeLast()
                        onStack.remove(w)
                        component.insert(w)
                        if w == v { break }
                    }
                    result.append(component)
                }
            }
            for v in g.vertices where index[v] == nil { connect(v) }
            return result
        }
        var generator = SeededRandomNumberGenerator(seed: UInt(seed) &+ 100)
        let n = 25
        var edges: [DirectedEdge<Int>] = []
        for _ in 0 ..< 40 {
            edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator)))
        }
        let sparse = CompressedSparseRow(vertexCount: n, edges: edges)
        let ordered = components(sparse)
        var position: [Int: Int] = [:]
        for (k, component) in ordered.enumerated() {
            for v in component { position[v] = k }
        }
        #expect(position.count == n)
        // Every edge between components goes from a later component to an earlier one.
        for e in edges where position[e.source] != position[e.target] {
            #expect(position[e.source]! > position[e.target]!, "\(e)")
        }
        #expect(Set(components(AdjacencyList(vertices: 0 ..< n, edges: edges))) == Set(ordered))
        #expect(Set(components(AdjacencyMatrix(vertexCount: n, edges: edges))) == Set(ordered))
    }
}
