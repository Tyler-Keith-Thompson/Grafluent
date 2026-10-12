// Properties with shrinking (swift-property-based). Random pseudographs, directed and undirected,
// with parallel edges and self-loops, against models written out beside them: the subgraph views
// (kept vertices in base order, kept positions in base order, rows as the base rows filtered and
// renumbered, edge indices by rank), the reverse view (every edge flipped, rows the base's in-rows),
// the complement (every missing pair of distinct vertices, rows ascending), the line graph
// (e → f where e's target is f's source; undirected, distinct edges sharing an end), the quotient
// (an edge between the blocks of every edge's ends, merged), the disjoint union and the join, and
// the condensation as a DAG. Then the boundary law: index-space members of every view hash nothing.
// See README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import Connectivity
import DirectedAcyclicGraphModule
import GrafluentTestSupport
import GraphOperations
import GraphProtocols
import Multigraphs
import PropertyBased
import Testing

@Suite("GraphOperations properties against written-out models", .tags(.randomized))
struct GraphOperationsPropertyTests {
    @Test("Directed subgraph views agree with the model: kept vertices and positions, rows, edge indices, membership")
    func directedSubgraphViews() async {
        let input = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: input, Gen.int(in: 0 ... 1).array(of: 8 ... 8), Gen.int(in: 0 ... 30).array(of: 0 ... 12)) { raw, keepBits, listed in
            let names = (0 ..< 8).map { "v\($0)" }
            let arcs = raw.map { [names[$0.0], names[$0.1]] }
            let base = DirectedPseudograph<String>(vertices: names, edges: arcs.map { DirectedEdge(from: $0[0], to: $0[1]) })
            let keep = names.indices.filter { keepBits[$0] == 1 }.map { names[$0] }
            let positions = listed.filter { $0 < arcs.count }
            let context = "arcs \(arcs), keep \(keep), positions \(positions)"
            // (view, kept vertices, kept positions, edge indices?)
            let cases: [(SubgraphView<DirectedPseudograph<String>>, [String], [Int], Bool)] = [
                (base.inducedSubgraph(on: keep.reversed() + keep.prefix(2)), keep, arcs.indices.filter { keep.contains(arcs[$0][0]) && keep.contains(arcs[$0][1]) }, false),
                (base.spanningSubgraph(edges: positions + positions.prefix(1)), names, arcs.indices.filter { positions.contains($0) }, true),
                (base.subgraph(vertices: keep, edges: positions), keep, arcs.indices.filter { positions.contains($0) && keep.contains(arcs[$0][0]) && keep.contains(arcs[$0][1]) }, true),
            ]
            for (view, vertices, kept, indexed) in cases {
                #expect(Array(view.vertices) == vertices, "\(context)")
                #expect(view.vertexCount == vertices.count && view.vertexIndexBound == vertices.count, "\(context)")
                #expect(vertices.map { view.vertexIndex(of: $0) } == Array(vertices.indices), "\(context)")
                #expect(vertices.indices.map { view.vertex(atIndex: $0) } == vertices, "\(context)")
                #expect(Array(view.edges.indices) == kept, "\(context)")
                #expect(view.edges.map { [$0.source, $0.target] } == kept.map { arcs[$0] }, "\(context)")
                #expect(view.edgeCount == kept.count, "\(context)")
                #expect(view.edgeIndexBound == (indexed || vertices.count == names.count ? kept.count : nil), "\(context)")
                if indexed || vertices.count == names.count { #expect(kept.map { view.edgeIndex(of: $0) } == Array(kept.indices), "\(context)") }
                #expect(kept.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] }
                    == kept.map { [vertices.firstIndex(of: arcs[$0][0])!, vertices.firstIndex(of: arcs[$0][1])!] }, "\(context)")
                for (k, v) in vertices.enumerated() {
                    let out = kept.filter { arcs[$0][0] == v }
                    let into = kept.filter { arcs[$0][1] == v }
                    #expect(Array(view.outEdges(ofIndex: k)) == out && Array(view.outEdges(of: v)) == out, "\(context) \(v)")
                    #expect(Array(view.inEdges(ofIndex: k)) == into && Array(view.inEdges(of: v)) == into, "\(context) \(v)")
                    #expect(Array(view.successorIndices(ofIndex: k)) == out.map { vertices.firstIndex(of: arcs[$0][1])! }, "\(context) \(v)")
                    #expect(Array(view.predecessorIndices(ofIndex: k)) == into.map { vertices.firstIndex(of: arcs[$0][0])! }, "\(context) \(v)")
                    #expect(Array(view.successors(of: v)) == out.map { arcs[$0][1] } && Array(view.predecessors(of: v)) == into.map { arcs[$0][0] }, "\(context) \(v)")
                    #expect(view.outDegree(ofIndex: k) == out.count && view.inDegree(ofIndex: k) == into.count && view.degree(of: v) == out.count + into.count, "\(context) \(v)")
                }
                for a in names {
                    #expect(view.contains(a) == vertices.contains(a), "\(context) \(a)")
                    for b in names {
                        let present = kept.contains { arcs[$0] == [a, b] }
                        #expect(view.contains(edge: DirectedEdge(from: a, to: b)) == present, "\(context) \(a)→\(b)")
                    }
                }
            }
        }
    }

    @Test("Undirected subgraph views agree with the model: a self-loop twice in its row, edge indices by rank")
    func undirectedSubgraphViews() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: input, Gen.int(in: 0 ... 1).array(of: 7 ... 7), Gen.int(in: 0 ... 25).array(of: 0 ... 10)) { raw, keepBits, listed in
            let names = (0 ..< 7).map { "u\($0)" }
            let ends = raw.map { [names[$0.0], names[$0.1]] }
            let base = Pseudograph<String>(vertices: names, edges: ends.map { UndirectedEdge($0[0], $0[1]) })
            let keep = names.indices.filter { keepBits[$0] == 1 }.map { names[$0] }
            let positions = listed.filter { $0 < ends.count }
            let context = "edges \(ends), keep \(keep), positions \(positions)"
            let cases: [(SubgraphView<Pseudograph<String>>, [String], [Int], Bool)] = [
                (base.inducedSubgraph(on: keep), keep, ends.indices.filter { keep.contains(ends[$0][0]) && keep.contains(ends[$0][1]) }, false),
                (base.spanningSubgraph(edges: positions), names, ends.indices.filter { positions.contains($0) }, true),
                (base.subgraph(vertices: keep, edges: positions), keep, ends.indices.filter { positions.contains($0) && keep.contains(ends[$0][0]) && keep.contains(ends[$0][1]) }, true),
            ]
            for (view, vertices, kept, indexed) in cases {
                #expect(Array(view.vertices) == vertices, "\(context)")
                #expect(Array(view.edges.indices) == kept && view.edgeCount == kept.count, "\(context)")
                #expect(view.edges.map { [$0.u, $0.v] } == kept.map { ends[$0] }, "\(context)")
                #expect(view.edgeIndexBound == (indexed || vertices.count == names.count ? kept.count : nil), "\(context)")
                for (k, v) in vertices.enumerated() {
                    var row: [Int] = []
                    for p in kept {
                        if ends[p][0] == v { row.append(p) }
                        if ends[p][1] == v { row.append(p) }
                    }
                    let neighbors = row.map { ends[$0][0] == v ? ends[$0][1] : ends[$0][0] }
                    #expect(Array(view.incidentEdges(ofIndex: k)) == row && Array(view.incidentEdges(of: v)) == row, "\(context) \(v)")
                    #expect(Array(view.neighbors(of: v)) == neighbors, "\(context) \(v)")
                    #expect(Array(view.neighborIndices(ofIndex: k)) == neighbors.map { vertices.firstIndex(of: $0)! }, "\(context) \(v)")
                    #expect(view.degree(of: v) == row.count && view.degree(ofIndex: k) == row.count, "\(context) \(v)")
                    if indexed || vertices.count == names.count { #expect(Array(view.incidentEdgeIndices(ofIndex: k)) == row.map { kept.firstIndex(of: $0)! }, "\(context) \(v)") }
                }
                for a in names {
                    for b in names {
                        let present = kept.contains { Set(ends[$0]) == Set([a, b]) }
                        #expect(view.contains(edge: UndirectedEdge(a, b)) == present, "\(context) \(a)–\(b)")
                    }
                }
            }
        }
    }

    @Test("reverseView flips every edge in place: rows are the base's in-rows, and reversing twice gives the base")
    func reverseViewLaws() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: input) { raw in
            let names = (0 ..< 7).map { "r\($0)" }
            let base = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let view = base.reverseView
            #expect(view.base == base && view.reverseView == base, "\(raw)")
            #expect(Array(view.edges.indices) == Array(base.edges.indices), "\(raw)")
            #expect(view.edges.map { $0 } == base.edges.map { DirectedEdge(from: $0.target, to: $0.source) }, "\(raw)")
            #expect(view.edgeIndexBound == base.edgeIndexBound && view.vertexIndexBound == base.vertexIndexBound, "\(raw)")
            for p in base.edges.indices {
                #expect(view.sourceIndex(ofEdgeAt: p) == base.targetIndex(ofEdgeAt: p) && view.targetIndex(ofEdgeAt: p) == base.sourceIndex(ofEdgeAt: p), "\(raw)")
                #expect(view.source(ofEdgeAt: p) == base.target(ofEdgeAt: p) && view.edgeIndex(of: p) == base.edgeIndex(of: p), "\(raw)")
            }
            for (i, v) in names.enumerated() {
                #expect(Array(view.outEdges(of: v)) == Array(base.inEdges(of: v)) && Array(view.inEdges(ofIndex: i)) == Array(base.outEdges(ofIndex: i)), "\(raw) \(v)")
                #expect(Array(view.successors(of: v)) == Array(base.predecessors(of: v)) && Array(view.predecessorIndices(ofIndex: i)) == Array(base.successorIndices(ofIndex: i)), "\(raw) \(v)")
                #expect(view.outDegree(of: v) == base.inDegree(of: v) && view.inDegree(ofIndex: i) == base.outDegree(ofIndex: i), "\(raw) \(v)")
                for w in names {
                    #expect(view.contains(edge: DirectedEdge(from: v, to: w)) == base.contains(edge: DirectedEdge(from: w, to: v)), "\(raw) \(v)→\(w)")
                }
            }
        }
    }

    @Test("complement is every missing pair of distinct vertices, rows ascending; twice it is the simple loopless base")
    func complementLaws() async {
        let input = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: input) { raw in
            let names = (0 ..< 6).map { "c\($0)" }
            let n = names.count
            // Directed.
            let directed = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let present = Set(raw.map { [$0.0, $0.1] })
            let missing = (0 ..< n).flatMap { i in (0 ..< n).filter { j in i != j && !present.contains([i, j]) }.map { [i, $0] } }
            let view = directed.complement
            #expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == missing, "\(raw)")
            #expect(view.edges.map { [$0.source, $0.target] } == missing.map { [names[$0[0]], names[$0[1]]] }, "\(raw)")
            #expect(view.edgeCount == missing.count && view.edgeIndexBound == nil && view.vertexIndexBound == n, "\(raw)")
            #expect(view.edges.indices.sorted() == Array(view.edges.indices), "\(raw)")
            for i in 0 ..< n {
                #expect(Array(view.successorIndices(ofIndex: i)) == missing.filter { $0[0] == i }.map { $0[1] }, "\(raw) \(i)")
                #expect(Array(view.predecessorIndices(ofIndex: i)) == missing.filter { $0[1] == i }.map { $0[0] }, "\(raw) \(i)")
                #expect(view.outEdges(ofIndex: i).map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == missing.filter { $0[0] == i }, "\(raw) \(i)")
                #expect(view.inEdges(of: names[i]).map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == missing.filter { $0[1] == i }, "\(raw) \(i)")
                for j in 0 ..< n {
                    #expect(view.contains(edge: DirectedEdge(from: names[i], to: names[j])) == missing.contains([i, j]), "\(raw) \(i)→\(j)")
                }
            }
            let twice = directed.complement.complement
            let simple = present.filter { $0[0] != $0[1] }.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
            #expect(twice.edges.map { [names.firstIndex(of: $0.source)!, names.firstIndex(of: $0.target)!] } == simple, "\(raw)")
            // Undirected.
            let undirected = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            let joined = Set(raw.map { Set([$0.0, $0.1]) })
            let pairs = (0 ..< n).flatMap { i in (i + 1 ..< n).filter { j in !joined.contains(Set([i, j])) }.map { [i, $0] } }
            let complement = undirected.complement
            #expect(complement.edges.indices.map { [complement.endpointIndices(ofEdgeAt: $0).u, complement.endpointIndices(ofEdgeAt: $0).v] } == pairs, "\(raw)")
            #expect(complement.edges.map { [$0.u, $0.v] } == pairs.map { [names[$0[0]], names[$0[1]]] }, "\(raw)")
            #expect(complement.edgeCount == pairs.count && complement.edgeIndexBound == nil, "\(raw)")
            for i in 0 ..< n {
                let row = pairs.filter { $0.contains(i) }
                #expect(Array(complement.neighborIndices(ofIndex: i)) == row.map { $0[0] == i ? $0[1] : $0[0] }, "\(raw) \(i)")
                #expect(complement.incidentEdges(ofIndex: i).map { [complement.endpointIndices(ofEdgeAt: $0).u, complement.endpointIndices(ofEdgeAt: $0).v] } == row, "\(raw) \(i)")
                #expect(complement.degree(of: names[i]) == row.count, "\(raw) \(i)")
            }
        }
    }

    @Test("lineGraph(of:): directed e → f where e's target is f's source; undirected, distinct edges sharing an end")
    func lineGraphLaws() async {
        let input = zip(Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)).array(of: 0 ... 14)
        await propertyCheck(count: 300, input: input) { raw in
            let names = (0 ..< 6).map { "l\($0)" }
            // Directed, without self-loops (a directed self-loop traps in phase 1).
            let arcs = raw.filter { $0.0 != $0.1 }
            let directed = DirectedPseudograph<String>(vertices: names, edges: arcs.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            var expected: [[Int]] = []
            for e in arcs.indices { for f in arcs.indices where arcs[e].1 == arcs[f].0 { expected.append([e, f]) } }
            let line = CompressedSparseRow.lineGraph(of: directed)
            #expect(line.vertexCount == arcs.count, "\(raw)")
            #expect(line.edges.map { [$0.source, $0.target] } == expected, "\(raw)")
            // Over a view without edge indices: vertex k is the k-th position of `edges`.
            let complementLine = AdjacencyList<Int>.lineGraph(of: directed.complement)
            let complementArcs = directed.complement.edges.map { [$0.source, $0.target] }
            var complementExpected: [[Int]] = []
            for e in complementArcs.indices { for f in complementArcs.indices where complementArcs[e][1] == complementArcs[f][0] { complementExpected.append([e, f]) } }
            #expect(complementLine.edges.map { [$0.source, $0.target] } == complementExpected, "\(raw)")
            // Undirected, self-loops included.
            let undirected = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            var pairs: [[Int]] = []
            for e in raw.indices {
                for f in raw.indices where e < f && !Set([raw[e].0, raw[e].1]).isDisjoint(with: [raw[f].0, raw[f].1]) { pairs.append([e, f]) }
            }
            let undirectedLine = UndirectedAdjacencyList<Int>.lineGraph(of: undirected)
            #expect(undirectedLine.vertexCount == raw.count, "\(raw)")
            #expect(undirectedLine.edges.map { [$0.u, $0.v] } == pairs, "\(raw)")
        }
    }

    @Test("quotient(of:by:): an edge between the blocks of every edge's ends, merged, none inside a block")
    func quotientLaws() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 20)
        await propertyCheck(count: 300, input: input, Gen.int(in: 0 ... 3).array(of: 7 ... 7)) { raw, owner in
            let names = (0 ..< 7).map { "q\($0)" }
            var blocks: [[String]] = [[], [], [], []]
            for (i, b) in owner.enumerated() { blocks[b].append(names[i]) }
            let directed = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let arcs = Set(raw.filter { owner[$0.0] != owner[$0.1] }.map { [owner[$0.0], owner[$0.1]] }).sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
            let result = CompressedSparseRow.quotient(of: directed, by: blocks)
            #expect(result.vertexCount == 4 && result.edges.map { [$0.source, $0.target] } == arcs, "\(raw) \(owner)")
            let undirected = Pseudograph<String>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            let pairs = Set(raw.filter { owner[$0.0] != owner[$0.1] }.map { [Swift.min(owner[$0.0], owner[$0.1]), Swift.max(owner[$0.0], owner[$0.1])] }).sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
            let merged = UndirectedAdjacencyList<Int>.quotient(of: undirected, by: blocks)
            #expect(merged.vertexCount == 4 && merged.edges.map { [$0.u, $0.v] } == pairs, "\(raw) \(owner)")
            // Singleton blocks in vertex order: the simple, loopless copy on Int vertices.
            let singletons = CompressedSparseRow.quotient(of: directed, by: names.map { [$0] })
            #expect(singletons.edges.map { [$0.source, $0.target] } == Set(raw.filter { $0.0 != $0.1 }.map { [$0.0, $0.1] }).sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }, "\(raw)")
        }
    }

    @Test("disjointUnion and join: g's vertices, then h's offset by |V(g)|; the join adds every edge across")
    func unionAndJoinLaws() async {
        let pairs = zip(Gen.int(in: 0 ... 4), Gen.int(in: 0 ... 4)).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: pairs, pairs, Gen.int(in: 0 ... 5), Gen.int(in: 0 ... 5)) { rawG, rawH, ng, nh in
            let gNames = (0 ..< ng).map { "g\($0)" }, hNames = (0 ..< nh).map { "h\($0)" }
            let gArcs = rawG.filter { $0.0 < ng && $0.1 < ng && $0.0 != $0.1 }, hArcs = rawH.filter { $0.0 < nh && $0.1 < nh && $0.0 != $0.1 }
            let g = DirectedPseudograph<String>(vertices: gNames, edges: gArcs.map { DirectedEdge(from: gNames[$0.0], to: gNames[$0.1]) })
            let h = DirectedPseudograph<String>(vertices: hNames, edges: hArcs.map { DirectedEdge(from: hNames[$0.0], to: hNames[$0.1]) })
            let within = Set(gArcs.map { [$0.0, $0.1] } + hArcs.map { [ng + $0.0, ng + $0.1] })
            let sorted: (Set<[Int]>) -> [[Int]] = { $0.sorted { ($0[0], $0[1]) < ($1[0], $1[1]) } }
            let union = CompressedSparseRow.disjointUnion(g, h)
            #expect(union.vertexCount == ng + nh && union.edges.map { [$0.source, $0.target] } == sorted(within), "\(rawG) \(rawH)")
            var across = within
            for i in 0 ..< ng { for j in ng ..< ng + nh { across.insert([i, j]); across.insert([j, i]) } }
            let join = CompressedSparseRow.join(g, h)
            #expect(join.vertexCount == ng + nh && join.edges.map { [$0.source, $0.target] } == sorted(across), "\(rawG) \(rawH)")
            // Undirected.
            let gu = Pseudograph<String>(vertices: gNames, edges: gArcs.map { UndirectedEdge(gNames[$0.0], gNames[$0.1]) })
            let hu = Pseudograph<String>(vertices: hNames, edges: hArcs.map { UndirectedEdge(hNames[$0.0], hNames[$0.1]) })
            let edges = Set(gArcs.map { [Swift.min($0.0, $0.1), Swift.max($0.0, $0.1)] } + hArcs.map { [ng + Swift.min($0.0, $0.1), ng + Swift.max($0.0, $0.1)] })
            #expect(UndirectedAdjacencyList<Int>.disjointUnion(gu, hu).edges.map { [$0.u, $0.v] } == sorted(edges), "\(rawG) \(rawH)")
            var joined = edges
            for i in 0 ..< ng { for j in ng ..< ng + nh { joined.insert([i, j]) } }
            #expect(UndirectedAdjacencyList<Int>.join(gu, hu).edges.map { [$0.u, $0.v] } == sorted(joined), "\(rawG) \(rawH)")
        }
    }

    @Test("The condensation as a DAG: vertex i is component i, an edge between components wherever the graph has one, order n−1, …, 0")
    func condensationLaws() async {
        let input = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 7)).array(of: 0 ... 24)
        await propertyCheck(count: 300, input: input) { raw in
            let names = (0 ..< 8).map { "s\($0)" }
            let graph = DirectedPseudograph<String>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let condensation = graph.condensation()
            let components = condensation.components.map { Array($0) }
            var component: [String: Int] = [:]
            for (c, members) in components.enumerated() { for v in members { component[v] = c } }
            let expected = Set(raw.map { [component[names[$0.0]]!, component[names[$0.1]]!] }.filter { $0[0] != $0[1] }).sorted { ($0[0], $0[1]) < ($1[0], $1[1]) }
            let dag = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)
            #expect(dag.vertexCount == components.count && Array(dag.vertices) == Array(0 ..< components.count), "\(raw)")
            #expect(dag.edges.map { [$0.source, $0.target] } == expected, "\(raw)")
            #expect(Array(dag.topologicalOrder) == Array((0 ..< components.count).reversed()), "\(raw)")
            for (place, v) in dag.topologicalOrder.enumerated() { #expect(dag.topologicalPosition(of: v) == place, "\(raw)") }
        }
    }

    @Test("Boundary law: index-space members of every view hash no vertex")
    func indexSpaceHashesNothing() async {
        let input = zip(Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 6)).array(of: 0 ... 20)
        await propertyCheck(count: 150, input: input) { raw in
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
            let names = (0 ..< 7).map { Counted(name: $0, tally: tally) }
            let directed = DirectedPseudograph<Counted>(vertices: names, edges: raw.map { DirectedEdge(from: names[$0.0], to: names[$0.1]) })
            let undirected = Pseudograph<Counted>(vertices: names, edges: raw.map { UndirectedEdge(names[$0.0], names[$0.1]) })
            let keep = names.filter { $0.name % 3 != 0 }
            let reverse = directed.reverseView
            let induced = directed.inducedSubgraph(on: keep)
            let spanning = directed.spanningSubgraph(edges: directed.edges.indices.filter { $0 % 2 == 0 })
            let both = directed.subgraph(vertices: keep, edges: directed.edges.indices.filter { $0 % 3 != 1 })
            let complement = directed.complement
            let undirectedInduced = undirected.inducedSubgraph(on: keep)
            let undirectedComplement = undirected.complement
            // The reverse view forwards its degrees by index to the base, whose own read the stored rows.
            tally.hashes = 0
            var total = 0
            for i in 0 ..< reverse.vertexIndexBound! {
                total += Array(reverse.successorIndices(ofIndex: i)).count + Array(reverse.predecessorIndices(ofIndex: i)).count
                total += Array(reverse.outEdges(ofIndex: i)).count + Array(reverse.inEdges(ofIndex: i)).count
                total += reverse.outDegree(ofIndex: i) + reverse.inDegree(ofIndex: i)
            }
            for p in directed.edges.indices { total += reverse.sourceIndex(ofEdgeAt: p) + reverse.targetIndex(ofEdgeAt: p) }
            for view in [induced, spanning, both] {
                for i in 0 ..< view.vertexIndexBound! {
                    total += Array(view.successorIndices(ofIndex: i)).count + Array(view.predecessorIndices(ofIndex: i)).count
                    total += Array(view.outEdges(ofIndex: i)).count + Array(view.inEdges(ofIndex: i)).count + view.outDegree(ofIndex: i)
                }
                total += (view.edgeIndexBound ?? 0)
            }
            for i in 0 ..< complement.vertexIndexBound! {
                total += Array(complement.successorIndices(ofIndex: i)).count + Array(complement.predecessorIndices(ofIndex: i)).count
                total += Array(complement.outEdges(ofIndex: i)).count + Array(complement.inEdges(ofIndex: i)).count
            }
            for i in 0 ..< undirectedInduced.vertexIndexBound! {
                total += Array(undirectedInduced.neighborIndices(ofIndex: i)).count + Array(undirectedInduced.incidentEdges(ofIndex: i)).count
                total += undirectedInduced.degree(ofIndex: i)
            }
            for i in 0 ..< undirectedComplement.vertexIndexBound! {
                total += Array(undirectedComplement.neighborIndices(ofIndex: i)).count + Array(undirectedComplement.incidentEdges(ofIndex: i)).count
            }
            #expect(tally.hashes == 0, "\(raw)")
            #expect(total >= 0)
        }
    }
}
