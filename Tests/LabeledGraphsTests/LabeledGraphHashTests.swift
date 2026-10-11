// The hash law, through the public API: a label type local to each test counts its own
// `hash(into:)` and `==` calls. Index-space and whole-graph reads touch no label (no hash, no
// comparison); every label-space member hashes exactly once (`contains(edge:)` twice, once per
// endpoint), safe spellings included, hit or miss; algorithms hash only at their inputs, so the
// count does not grow with the number of edges. Every graph here has at least 16 labels: an
// OrderedSet scans linearly up to 15 elements and hashes only from 16. See README.md.

import AdjacencyMatrixModule
import CompressedSparseRowModule
import Connectivity
import GraphProtocols
import LabeledGraphs
import ShortestPaths
import Testing
import Traversal

@Suite("LabeledGraphs hash law")
struct LabeledGraphHashTests {
    @Test("Index-space and whole-graph reads touch no label, on both bases")
    func indexSpaceReadsTouchNoLabel() {
        final class Tally {
            var hashes = 0
            var comparisons = 0
        }
        struct Counted: Hashable {
            let name: Int
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool {
                lhs.tally.comparisons += 1
                return lhs.name == rhs.name
            }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        let n = 40
        let edges = (0 ..< n).flatMap { i in [1, 3, 7].map { DirectedEdge(from: Counted(name: i, tally: tally), to: Counted(name: (i * 5 + $0) % n, tally: tally)) } }
        let csr = LabeledGraph<Counted, CompressedSparseRow>(vertices: (0 ..< n).map { Counted(name: $0, tally: tally) }, edges: edges)
        let matrix = LabeledGraph<Counted, AdjacencyMatrix>(vertices: (0 ..< n).map { Counted(name: $0, tally: tally) }, edges: edges)
        tally.hashes = 0
        tally.comparisons = 0
        var sink = 0
        for i in 0 ..< n {
            sink &+= csr.vertex(atIndex: i).name &+ matrix.vertex(atIndex: i).name
            sink &+= csr.successorIndices(ofIndex: i).reduce(0, &+) &+ csr.outEdges(ofIndex: i).reduce(0, &+)
            sink &+= matrix.successorIndices(ofIndex: i).reduce(0, &+) &+ matrix.predecessorIndices(ofIndex: i).reduce(0, &+)
            sink &+= matrix.outEdges(ofIndex: i).count &+ matrix.inEdges(ofIndex: i).count
        }
        for p in csr.edges.indices {
            sink &+= csr.edges[p].source.name &+ csr.source(ofEdgeAt: p).name &+ csr.target(ofEdgeAt: p).name &+ csr.edgeIndex(of: p)
        }
        for p in matrix.edges.indices {
            sink &+= matrix.edges[p].target.name &+ matrix.source(ofEdgeAt: p).name &+ matrix.target(ofEdgeAt: p).name
        }
        for e in csr.edges { sink &+= e.target.name }
        for e in matrix.edges { sink &+= e.source.name }
        for v in csr.vertices { sink &+= v.name }
        sink &+= csr.vertexCount &+ csr.edgeCount &+ (csr.vertexIndexBound ?? 0) &+ (csr.edgeIndexBound ?? 0)
        sink &+= matrix.vertexCount &+ matrix.edgeCount &+ (matrix.vertexIndexBound ?? 0)
        let view = matrix.undirected
        for i in 0 ..< n { sink &+= view.neighborIndices(ofIndex: i).reduce(0, &+) &+ view.incidentEdges(ofIndex: i).count }
        #expect(tally.hashes == 0)
        #expect(tally.comparisons == 0)
        #expect(sink != 0)
    }

    @Test("Every label-space member hashes once (contains(edge:) once per endpoint), safe spellings hit or miss")
    func labelSpaceMembersHashOnce() {
        final class Tally {
            var hashes = 0
        }
        struct Counted: Hashable {
            let name: Int
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        let n = 30
        func label(_ k: Int) -> Counted { Counted(name: k, tally: tally) }
        // Vertex 0 has n - 1 successors and n - 1 predecessors: a per-row cost would show.
        let edges = (1 ..< n).flatMap { [DirectedEdge(from: label(0), to: label($0)), DirectedEdge(from: label($0), to: label(0))] }
        let csr = LabeledGraph<Counted, CompressedSparseRow>(edges: edges)
        let matrix = LabeledGraph<Counted, AdjacencyMatrix>(edges: edges)
        func hashes(_ body: () -> Void) -> Int {
            tally.hashes = 0
            body()
            return tally.hashes
        }
        let hub = label(0), absent = label(-1)
        #expect(hashes { _ = Array(csr.successors(of: hub)) } == 1)
        #expect(hashes { _ = Array(csr.outEdges(of: hub)) } == 1)
        #expect(hashes { _ = csr.outDegree(of: hub) } == 1)
        #expect(hashes { _ = csr.contains(hub) } == 1)
        #expect(hashes { _ = csr.contains(absent) } == 1)
        #expect(hashes { _ = csr.vertexIndex(of: hub) } == 1)
        #expect(hashes { _ = csr.vertexIndex(safe: absent) } == 1)
        #expect(hashes { _ = csr.successors(safe: hub).map { Array($0) } } == 1)
        #expect(hashes { _ = csr.successors(safe: absent) } == 1)
        #expect(hashes { _ = csr.outEdges(safe: hub).map { Array($0) } } == 1)
        #expect(hashes { _ = csr.outDegree(safe: absent) } == 1)
        #expect(hashes { _ = csr.contains(edge: DirectedEdge(from: hub, to: label(5))) } == 2)
        #expect(hashes { _ = Array(matrix.successors(of: hub)) } == 1)
        #expect(hashes { _ = Array(matrix.predecessors(of: hub)) } == 1)
        #expect(hashes { _ = Array(matrix.outEdges(of: hub)) } == 1)
        #expect(hashes { _ = Array(matrix.inEdges(of: hub)) } == 1)
        #expect(hashes { _ = matrix.inDegree(of: hub) } == 1)
        #expect(hashes { _ = matrix.degree(of: hub) } == 1)
        #expect(hashes { _ = matrix.predecessors(safe: hub).map { Array($0) } } == 1)
        #expect(hashes { _ = matrix.predecessors(safe: absent) } == 1)
        #expect(hashes { _ = matrix.inEdges(safe: absent) } == 1)
        #expect(hashes { _ = matrix.inDegree(safe: hub) } == 1)
        #expect(hashes { _ = matrix.degree(safe: hub) } == 1)
        #expect(hashes { _ = matrix.degree(safe: absent) } == 1)
        #expect(hashes { _ = matrix.contains(edge: DirectedEdge(from: label(3), to: hub)) } == 2)
        // The undirected view calls successors(of:) and predecessors(of:): two.
        #expect(hashes { _ = Array(matrix.undirected.neighbors(of: hub)) } == 2)
        #expect(hashes { _ = Array(matrix.undirected.incidentEdges(of: hub)) } == 2)
        // The values are the full rows.
        #expect(csr.outDegree(of: hub) == n - 1 && matrix.inDegree(of: hub) == n - 1)
    }

    @Test("Algorithms hash only at their inputs: the count does not grow with the edges")
    func algorithmsHashAtTheBoundary() {
        final class Tally {
            var hashes = 0
        }
        struct Counted: Hashable {
            let name: Int
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        let n = 64
        func label(_ k: Int) -> Counted { Counted(name: k, tally: tally) }
        // The same vertices and the same reachability (a path 0 → 1 → … → n-1), sparse and dense.
        let path = (0 ..< n - 1).map { DirectedEdge(from: label($0), to: label($0 + 1)) }
        let dense = path + (0 ..< n).flatMap { i in stride(from: i + 2, to: min(n, i + 12), by: 1).map { DirectedEdge(from: label(i), to: label($0)) } }
        let sparse = LabeledGraph<Counted, CompressedSparseRow>(edges: path)
        let full = LabeledGraph<Counted, CompressedSparseRow>(edges: dense)
        let matrix = LabeledGraph<Counted, AdjacencyMatrix>(edges: dense)
        #expect(full.edgeCount > 8 * sparse.edgeCount)
        func hashes(_ body: () -> Void) -> Int {
            tally.hashes = 0
            body()
            return tally.hashes
        }
        let source = label(0)
        // No label input: nothing at all.
        for graph in [sparse, full] {
            #expect(hashes { _ = graph.topologicalSort() } == 0)
            #expect(hashes { _ = graph.weaklyConnectedComponents() } == 0)
            #expect(hashes { _ = graph.stronglyConnectedComponents() } == 0)
        }
        // The whole-graph depth-first search numbers its roots through vertexIndex(of:): per vertex,
        // never per edge.
        #expect(hashes { _ = Array(sparse.depthFirstSearch()) } == hashes { _ = Array(full.depthFirstSearch()) })
        #expect(hashes { _ = Array(full.depthFirstSearch()) } <= 2 * n)
        #expect(hashes { _ = matrix.topologicalSort() } == 0)
        #expect(hashes { _ = matrix.stronglyConnectedComponents() } == 0)
        // One source: a constant number of lookups, the same on the sparse and the dense graph.
        let searches: [(LabeledGraph<Counted, CompressedSparseRow>) -> Void] = [
            { _ = Array($0.breadthFirstSearch(from: source)) },
            { _ = $0.breadthFirstLayers(from: source) },
            { _ = $0.shortestPaths(from: source).distance(toIndex: n - 1) },
            { _ = $0.dijkstraShortestPaths(from: source) { _ in 1 }.distance(toIndex: n - 1) },
            { _ = $0.hasPath(from: source, to: label(n - 1)) },
        ]
        for search in searches {
            let few = hashes { search(sparse) }, many = hashes { search(full) }
            #expect(few == many)
            #expect(few >= 1 && few <= 4)
        }
        #expect(hashes { _ = matrix.dijkstraShortestPaths(from: source) { _ in 1 }.distance(toIndex: n - 1) } <= 4)
        // A Set result hashes once per vertex it holds (and its own growth): again, the same on both.
        let few = hashes { _ = sparse.descendants(of: source) }, many = hashes { _ = full.descendants(of: source) }
        #expect(few == many)
        #expect(full.descendants(of: source).count == n - 1)
    }

    @Test("Building and growing hash each label a constant number of times, amortized")
    func buildingAndGrowing() {
        final class Tally {
            var hashes = 0
        }
        struct Counted: Hashable {
            let name: Int
            let tally: Tally
            static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }
            func hash(into hasher: inout Hasher) {
                tally.hashes += 1
                hasher.combine(name)
            }
        }
        let tally = Tally()
        let n = 2_000
        func label(_ k: Int) -> Counted { Counted(name: k, tally: tally) }
        var graph = LabeledGraph<Counted, AdjacencyMatrix>()
        tally.hashes = 0
        for k in 0 ..< n { graph.insert(label(k)) }
        // An OrderedSet that grows rehashes geometrically: amortized O(1) per label.
        #expect(tally.hashes <= 8 * n)
        tally.hashes = 0
        for k in 0 ..< n { graph.insert(edge: DirectedEdge(from: label(k), to: label((k + 1) % n))) }
        #expect(tally.hashes <= 8 * n)
        #expect(graph.vertexCount == n && graph.edgeCount == n)
        tally.hashes = 0
        let built = LabeledGraph<Counted, CompressedSparseRow>(edges: graph.edges)
        #expect(tally.hashes <= 8 * (n + 2 * n))
        // Equality in the same order compares the bases and hashes nothing; in another order it
        // hashes O(n).
        let copy = LabeledGraph<Counted, CompressedSparseRow>(graph)
        let shuffled = LabeledGraph<Counted, CompressedSparseRow>(vertices: (0 ..< n).reversed().map(label), edges: graph.edges)
        tally.hashes = 0
        #expect(copy == built)
        #expect(tally.hashes == 0)
        tally.hashes = 0
        #expect(shuffled == built && built == shuffled)
        #expect(tally.hashes <= 8 * n)
    }
}
