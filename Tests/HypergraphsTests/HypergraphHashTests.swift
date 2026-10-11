// The hash law, through the public API: a vertex type local to each test counts its own
// `hash(into:)` and `==` calls. Index-space members and whole-hypergraph algorithms touch no vertex
// (no hash, no comparison), and so do the graph algorithms run on `incidenceGraph`; every
// vertex-space member hashes exactly once, safe spellings included, hit or miss; an algorithm that
// takes vertices looks each up once; `contains(hyperedge:)` hashes each member once; hashing a
// hypergraph hashes each vertex once; building is amortized O(1) hashes per incidence. Every
// hypergraph here has at least 16 vertices: an OrderedSet scans linearly up to 15 elements and
// hashes only from 16. See README.md.

import Connectivity
import GraphProtocols
import Hypergraphs
import Testing
import Traversal

@Suite("Hypergraphs hash law")
struct HypergraphHashTests {
    @Test("Undirected: index-space reads and whole-hypergraph algorithms touch no vertex")
    func undirectedIndexSpace() {
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
        let rows = (0 ..< 30).map { p in (0 ..< p % 5).map { Counted(name: (p * 7 + $0 * 3) % n, tally: tally) } }
        let hypergraph = UndirectedIncidenceList(vertices: (0 ..< n).map { Counted(name: $0, tally: tally) }, hyperedges: rows)
        tally.hashes = 0
        tally.comparisons = 0
        var sink = 0
        for i in 0 ..< n {
            sink &+= hypergraph.vertex(atIndex: i).name &+ hypergraph.degree(ofIndex: i)
            sink &+= hypergraph.incidentHyperedges(ofIndex: i).reduce(0, &+)
        }
        for p in hypergraph.hyperedges.indices {
            sink &+= hypergraph.memberIndices(ofHyperedgeAt: p).reduce(0, &+) &+ hypergraph.size(ofHyperedgeAt: p)
            sink &+= hypergraph.members(ofHyperedgeAt: p).reduce(0) { $0 &+ $1.name } &+ hypergraph.hyperedgeIndex(of: p)
        }
        for e in hypergraph.hyperedges { sink &+= e.count }
        for v in hypergraph.vertices { sink &+= v.name }
        sink &+= hypergraph.vertexCount &+ hypergraph.hyperedgeCount &+ hypergraph.vertexIndexBound! &+ hypergraph.hyperedgeIndexBound!
        sink &+= hypergraph.rank &+ hypergraph.degreeHistogram().count &+ hypergraph.hyperedgeSizeHistogram().count
        sink &+= hypergraph.isUniform(size: 2) ? 1 : 0
        sink &+= hypergraph.dual().hyperedgeCount
        sink &+= hypergraph.connectedComponents().count &+ (hypergraph.isConnected ? 1 : 0)
        sink &+= hypergraph.lineGraph(s: 1).edgeCount &+ hypergraph.lineGraph(s: 2).edgeCount
        sink &+= hypergraph.sConnectedComponents(s: 1).count &+ hypergraph.dual().sConnectedComponents(s: 1).count
        let view = hypergraph.incidenceGraph
        for x in view.vertices { sink &+= view.neighborIndices(ofIndex: x).reduce(0, &+) &+ view.incidentEdgeIndices(ofIndex: x).count }
        for q in view.edges.indices { sink &+= view.endpointIndices(ofEdgeAt: q).u &+ view.edges[q].v }
        sink &+= view.connectedComponents().count &+ view.directed.breadthFirstSearch(from: 0).reduce(0) { n, _ in n + 1 }
        sink &+= view.bridges().count &+ view.articulationPoints().count
        #expect(tally.hashes == 0)
        #expect(tally.comparisons == 0)
        #expect(sink != 0)
    }

    @Test("Directed: index-space reads and whole-hypergraph algorithms touch no vertex")
    func directedIndexSpace() {
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
        let arcs = (0 ..< 30).map { p in
            (sources: (0 ..< p % 3).map { Counted(name: (p * 7 + $0) % n, tally: tally) },
             targets: (0 ..< (p + 1) % 4).map { Counted(name: (p * 11 + $0 * 5) % n, tally: tally) })
        }
        let hypergraph = IncidenceList(vertices: (0 ..< n).map { Counted(name: $0, tally: tally) }, hyperedges: arcs)
        tally.hashes = 0
        tally.comparisons = 0
        var sink = 0
        for i in 0 ..< n {
            sink &+= hypergraph.vertex(atIndex: i).name &+ hypergraph.outDegree(ofIndex: i) &+ hypergraph.inDegree(ofIndex: i)
            sink &+= hypergraph.outHyperedges(ofIndex: i).reduce(0, &+) &+ hypergraph.inHyperedges(ofIndex: i).reduce(0, &+)
        }
        for p in hypergraph.hyperedges.indices {
            sink &+= hypergraph.sourceIndices(ofHyperedgeAt: p).reduce(0, &+) &+ hypergraph.targetIndices(ofHyperedgeAt: p).reduce(0, &+)
            sink &+= hypergraph.sources(ofHyperedgeAt: p).count &+ hypergraph.targets(ofHyperedgeAt: p).reduce(0) { $0 &+ $1.name }
        }
        for e in hypergraph.hyperedges { sink &+= e.sources.count &+ e.targets.count }
        sink &+= hypergraph.reversed.hyperedgeCount &+ hypergraph.dual().hyperedgeCount
        sink &+= hypergraph.weaklyConnectedComponents().count &+ hypergraph.stronglyConnectedComponents().count
        sink &+= (hypergraph.isWeaklyConnected ? 1 : 0) &+ (hypergraph.isStronglyConnected ? 1 : 0)
        sink &+= (hypergraph.isBHypergraph ? 1 : 0) &+ (hypergraph.isFHypergraph ? 1 : 0) &+ (hypergraph.isBFHypergraph ? 1 : 0)
        sink &+= hypergraph.outDegreeHistogram().count &+ hypergraph.inDegreeHistogram().count
        sink &+= hypergraph.sourceSizeHistogram().count &+ hypergraph.targetSizeHistogram().count
        let view = hypergraph.incidenceGraph
        for x in view.vertices { sink &+= view.successorIndices(ofIndex: x).reduce(0, &+) &+ view.predecessorIndices(ofIndex: x).reduce(0, &+) }
        for q in view.edges.indices { sink &+= view.sourceIndex(ofEdgeAt: q) &+ view.targetIndex(ofEdgeAt: q) }
        sink &+= view.stronglyConnectedComponents().count &+ view.descendants(of: 0).count &+ (view.topologicalSort()?.count ?? 1)
        #expect(tally.hashes == 0)
        #expect(tally.comparisons == 0)
        #expect(sink != 0)
    }

    @Test("Every vertex-space member hashes once, safe spellings hit or miss; algorithms look each argument up once")
    func vertexSpaceReadsHashOnce() {
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
        let n = 32
        func label(_ k: Int) -> Counted { Counted(name: k, tally: tally) }
        let undirected = UndirectedIncidenceList(vertices: (0 ..< n).map(label), hyperedges: (0 ..< n).map { [label($0), label(($0 + 1) % n), label(($0 * 5) % n)] })
        let directed = IncidenceList(vertices: (0 ..< n).map(label),
                                     hyperedges: (0 ..< n).map { (sources: [label($0), label(($0 + 3) % n)], targets: [label(($0 + 1) % n)]) })
        func hashes(_ body: () -> Void) -> Int {
            tally.hashes = 0
            body()
            return tally.hashes
        }
        let v = label(5), absent = label(n + 7)
        #expect(hashes { _ = undirected.incidentHyperedges(of: v) } == 1)
        #expect(hashes { _ = undirected.degree(of: v) } == 1)
        #expect(hashes { _ = undirected.vertexIndex(of: v) } == 1)
        #expect(hashes { _ = undirected.contains(v) } == 1)
        #expect(hashes { _ = undirected.contains(absent) } == 1)
        #expect(hashes { _ = undirected.incidentHyperedges(safe: v) } == 1)
        #expect(hashes { _ = undirected.incidentHyperedges(safe: absent) } == 1)
        #expect(hashes { _ = undirected.degree(safe: absent) } == 1)
        #expect(hashes { _ = undirected.vertexIndex(safe: absent) } == 1)
        #expect(hashes { _ = undirected.neighbors(of: v) } == 1)
        #expect(hashes { _ = undirected.contains(hyperedge: [label(1), label(2), label(5)]) } == 3)
        #expect(hashes { _ = directed.outHyperedges(of: v) } == 1)
        #expect(hashes { _ = directed.inHyperedges(of: v) } == 1)
        #expect(hashes { _ = directed.outDegree(of: v) } == 1)
        #expect(hashes { _ = directed.inDegree(of: v) } == 1)
        #expect(hashes { _ = directed.degree(of: v) } == 1)
        #expect(hashes { _ = directed.outHyperedges(safe: absent) } == 1)
        #expect(hashes { _ = directed.inHyperedges(safe: v) } == 1)
        #expect(hashes { _ = directed.outDegree(safe: v) } == 1)
        #expect(hashes { _ = directed.inDegree(safe: absent) } == 1)
        #expect(hashes { _ = directed.bConnectedVertices(from: v) } == 1)
        #expect(hashes { _ = directed.fConnectedVertices(to: v) } == 1)
        #expect(hashes { _ = directed.isBConnected(from: v, to: label(9)) } == 2)
        #expect(hashes { _ = directed.isFConnected(from: v, to: label(9)) } == 2)
        #expect(hashes { _ = directed.contains(sources: [label(1), label(4)], targets: [label(2)]) } == 3)
    }

    @Test("B- and F-visits hash only their argument, however many hyperedges fire")
    func visitsHashOnlyTheirArgument() {
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
        func label(_ k: Int) -> Counted { Counted(name: k, tally: tally) }
        for n in [20, 400] {
            // A chain 0 → 1 → … → n − 1 with a second, already reached source on every step.
            let arcs = (1 ..< n).map { (sources: [label($0 - 1), label(0)], targets: [label($0)]) }
            let hypergraph = IncidenceList(vertices: (0 ..< n).map(label), hyperedges: arcs)
            tally.hashes = 0
            let reached = hypergraph.bConnectedVertices(from: label(0))
            #expect(tally.hashes == 1)
            tally.hashes = 0
            let back = hypergraph.fConnectedVertices(to: label(n - 1))
            #expect(tally.hashes == 1)
            #expect(reached.count == n && back.count == n)
        }
    }

    @Test("Hashing a hypergraph hashes each vertex once and nothing per incidence")
    func hashingHashesEachVertexOnce() {
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
        let n = 50
        func label(_ k: Int) -> Counted { Counted(name: k, tally: tally) }
        let undirected = UndirectedIncidenceList(vertices: (0 ..< n).map(label), hyperedges: (0 ..< 3 * n).map { p in (0 ..< 6).map { label((p + $0 * 7) % n) } })
        let directed = IncidenceList(vertices: (0 ..< n).map(label),
                                     hyperedges: (0 ..< 3 * n).map { p in (sources: (0 ..< 3).map { label((p + $0) % n) }, targets: (0 ..< 4).map { label((p * 3 + $0) % n) }) })
        tally.hashes = 0
        _ = undirected.hashValue
        #expect(tally.hashes == n)
        tally.hashes = 0
        _ = directed.hashValue
        #expect(tally.hashes == n)
    }

    @Test("Building and equality hash each vertex or member a constant number of times, amortized")
    func buildingIsAmortized() {
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
        let rows = (0 ..< n).map { p in (0 ..< 4).map { label((p * 13 + $0 * 101) % n) } }
        tally.hashes = 0
        var grown = UndirectedIncidenceList<Counted>()
        for row in rows { grown.insert(hyperedge: row) }
        // An OrderedSet that grows rehashes geometrically: amortized O(1) per member.
        #expect(tally.hashes <= 8 * 4 * n)
        tally.hashes = 0
        let built = UndirectedIncidenceList(vertices: (0 ..< n).map(label), hyperedges: rows)
        #expect(tally.hashes <= 8 * (n + 4 * n))
        tally.hashes = 0
        #expect(built == grown)
        #expect(tally.hashes <= 8 * n)
        tally.hashes = 0
        var directed = IncidenceList<Counted>()
        for row in rows { directed.insert(sources: row.prefix(2), targets: row.suffix(2)) }
        #expect(tally.hashes <= 8 * 4 * n)
    }
}
