// Properties with shrinking (swift-property-based), each against a model written out in the test.
// Random mutation sequences run on both representations beside a model (the vertices in insertion
// order and each hyperedge as its index rows), and after every step the whole state is compared and
// the protocol laws are checked: the incidence law, the handshake law (Σ degree = Σ size; directed,
// Σ outDegree = Σ |sources| and Σ inDegree = Σ |targets|) and the index laws. Then dual(dual) ≅ H,
// reversal as an involution that commutes with the dual, B-Visit and F-Visit against the fixpoint
// of their definition (Gallo et al. 1993), the components, the expansions and the s-line graph
// against direct computations, and equality and hashing under any vertex and hyperedge order.
// See README.md.

import AdjacencyListModule
import Foundation
import GrafluentTestSupport
import GraphProtocols
import Hypergraphs
import PropertyBased
import Testing

@Suite("Hypergraphs properties against a model, with shrinking", .tags(.randomized))
struct HypergraphPropertyTests {
    @Test("Undirected mutation sequences agree with the model after every step, and the laws hold")
    func undirectedMutationAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 7).array(of: 0 ... 4)).array(of: 0 ... 40)
        await propertyCheck(count: 300, input: operations) { operations in
            var hypergraph = UndirectedIncidenceList<String>()
            var names: [String] = []
            var rows: [[Int]] = []
            for (step, (kind, raw)) in operations.enumerated() {
                let members = raw.map { "v\($0)" }
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0, 1:
                    let result = hypergraph.insert(members.first ?? "v0")
                    let v = members.first ?? "v0"
                    #expect(result.inserted == !names.contains(v) && result.memberAfterInsert == v, "\(context)")
                    if !names.contains(v) { names.append(v) }
                case 2, 3, 4, 5:
                    #expect(hypergraph.insert(hyperedge: members) == rows.count, "\(context)")
                    for v in members where !names.contains(v) { names.append(v) }
                    rows.append(Set(members.map { names.firstIndex(of: $0)! }).sorted())
                case 6, 7, 8:
                    let position = hypergraph.insert(safe: members)
                    if members.allSatisfy(names.contains) {
                        #expect(position == rows.count, "\(context)")
                        rows.append(Set(members.map { names.firstIndex(of: $0)! }).sorted())
                    } else {
                        #expect(position == nil, "\(context)")
                    }
                default:
                    if raw.count < 2 {
                        hypergraph.removeAll(keepingCapacity: raw.isEmpty)
                        names.removeAll()
                        rows.removeAll()
                    }
                }
                // The whole state, and the laws.
                let n = names.count, m = rows.count
                #expect(Array(hypergraph.vertices) == names, "\(context)")
                #expect(hypergraph.hyperedges.map { Array($0) } == rows.map { $0.map { names[$0] } }, "\(context)")
                #expect(hypergraph.vertexCount == n && hypergraph.hyperedgeCount == m, "\(context)")
                #expect(hypergraph.vertexIndexBound == n && hypergraph.hyperedgeIndexBound == m, "\(context)")
                var degreeSum = 0
                for (i, v) in names.enumerated() {
                    let incident = rows.indices.filter { rows[$0].contains(i) }
                    #expect(hypergraph.vertexIndex(of: v) == i && hypergraph.vertex(atIndex: i) == v, "\(context)")
                    #expect(Array(hypergraph.incidentHyperedges(of: v)) == incident, "\(context)")
                    #expect(Array(hypergraph.incidentHyperedges(ofIndex: i)) == incident, "\(context)")
                    #expect(hypergraph.degree(of: v) == incident.count && hypergraph.degree(ofIndex: i) == incident.count, "\(context)")
                    degreeSum += hypergraph.degree(ofIndex: i)
                }
                for p in rows.indices {
                    #expect(Array(hypergraph.memberIndices(ofHyperedgeAt: p)) == rows[p], "\(context)")
                    #expect(Array(hypergraph.members(ofHyperedgeAt: p)).map { hypergraph.vertexIndex(of: $0) } == rows[p], "\(context)")
                    #expect(hypergraph.size(ofHyperedgeAt: p) == rows[p].count && hypergraph.hyperedgeIndex(of: p) == p, "\(context)")
                    #expect(hypergraph.contains(hyperedge: rows[p].reversed().map { names[$0] }), "\(context)")
                }
                #expect(degreeSum == rows.reduce(0) { $0 + $1.count }, "handshake, \(context)")
                #expect(hypergraph.contains(hyperedge: [] as [String]) == rows.contains { $0.isEmpty }, "\(context)")
            }
        }
    }

    @Test("Directed mutation sequences agree with the model after every step, and the laws hold")
    func directedMutationAgainstModel() async {
        let operations = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 7).array(of: 0 ... 3), Gen.int(in: 0 ... 7).array(of: 0 ... 3)).array(of: 0 ... 40)
        await propertyCheck(count: 300, input: operations) { operations in
            var hypergraph = IncidenceList<String>()
            var names: [String] = []
            var sources: [[Int]] = [], targets: [[Int]] = []
            for (step, (kind, rawSources, rawTargets)) in operations.enumerated() {
                let s = rawSources.map { "v\($0)" }, t = rawTargets.map { "v\($0)" }
                let context = "step \(step) of \(operations)"
                switch kind {
                case 0, 1:
                    let v = (s + t).first ?? "v0"
                    let result = hypergraph.insert(v)
                    #expect(result.inserted == !names.contains(v) && result.memberAfterInsert == v, "\(context)")
                    if !names.contains(v) { names.append(v) }
                case 2, 3, 4, 5:
                    #expect(hypergraph.insert(sources: s, targets: t) == sources.count, "\(context)")
                    for v in s + t where !names.contains(v) { names.append(v) }
                    sources.append(Set(s.map { names.firstIndex(of: $0)! }).sorted())
                    targets.append(Set(t.map { names.firstIndex(of: $0)! }).sorted())
                case 6, 7, 8:
                    let position = hypergraph.insert(safe: s, targets: t)
                    if (s + t).allSatisfy(names.contains) {
                        #expect(position == sources.count, "\(context)")
                        sources.append(Set(s.map { names.firstIndex(of: $0)! }).sorted())
                        targets.append(Set(t.map { names.firstIndex(of: $0)! }).sorted())
                    } else {
                        #expect(position == nil, "\(context)")
                    }
                default:
                    if rawSources.count < 2 {
                        hypergraph.removeAll(keepingCapacity: rawTargets.isEmpty)
                        names.removeAll()
                        sources.removeAll()
                        targets.removeAll()
                    }
                }
                let n = names.count, m = sources.count
                #expect(Array(hypergraph.vertices) == names, "\(context)")
                #expect(hypergraph.hyperedges.map { [Array($0.sources), Array($0.targets)] } == zip(sources, targets).map { [$0.map { names[$0] }, $1.map { names[$0] }] }, "\(context)")
                #expect(hypergraph.vertexCount == n && hypergraph.hyperedgeCount == m, "\(context)")
                #expect(hypergraph.vertexIndexBound == n && hypergraph.hyperedgeIndexBound == m, "\(context)")
                var outSum = 0, inSum = 0
                for (i, v) in names.enumerated() {
                    let out = sources.indices.filter { sources[$0].contains(i) }
                    let into = targets.indices.filter { targets[$0].contains(i) }
                    #expect(hypergraph.vertexIndex(of: v) == i && hypergraph.vertex(atIndex: i) == v, "\(context)")
                    #expect(Array(hypergraph.outHyperedges(of: v)) == out && Array(hypergraph.outHyperedges(ofIndex: i)) == out, "\(context)")
                    #expect(Array(hypergraph.inHyperedges(of: v)) == into && Array(hypergraph.inHyperedges(ofIndex: i)) == into, "\(context)")
                    #expect(hypergraph.outDegree(of: v) == out.count && hypergraph.inDegree(of: v) == into.count, "\(context)")
                    #expect(hypergraph.degree(of: v) == out.count + into.count, "\(context)")
                    outSum += hypergraph.outDegree(ofIndex: i)
                    inSum += hypergraph.inDegree(ofIndex: i)
                }
                for p in 0 ..< m {
                    #expect(Array(hypergraph.sourceIndices(ofHyperedgeAt: p)) == sources[p], "\(context)")
                    #expect(Array(hypergraph.targetIndices(ofHyperedgeAt: p)) == targets[p], "\(context)")
                    #expect(hypergraph.contains(sources: sources[p].reversed().map { names[$0] }, targets: targets[p].map { names[$0] }), "\(context)")
                }
                #expect(outSum == sources.reduce(0) { $0 + $1.count } && inSum == targets.reduce(0) { $0 + $1.count }, "handshake, \(context)")
            }
        }
    }

    @Test("dual(dual) is the hypergraph relabeled to indices, positions kept; the dual transposes")
    func dualOfDual() async {
        let input = zip(Gen.int(in: 0 ... 9).array(of: 0 ... 5), Gen.int(in: 0 ... 9).array(of: 0 ... 5).array(of: 0 ... 8))
        await propertyCheck(count: 300, input: input) { listed, raw in
            let hypergraph = UndirectedIncidenceList(vertices: listed.map { "v\($0)" }, hyperedges: raw.map { $0.map { "v\($0)" } })
            let n = hypergraph.vertexCount, m = hypergraph.hyperedgeCount
            let dual = hypergraph.dual()
            #expect(Array(dual.vertices) == Array(0 ..< m) && dual.hyperedgeCount == n)
            for i in 0 ..< n { #expect(Array(dual.memberIndices(ofHyperedgeAt: i)) == Array(hypergraph.incidentHyperedges(ofIndex: i))) }
            for p in 0 ..< m { #expect(Array(dual.incidentHyperedges(ofIndex: p)) == Array(hypergraph.memberIndices(ofHyperedgeAt: p))) }
            let twice = dual.dual()
            let relabeled = UndirectedIncidenceList<Int>(vertices: 0 ..< n, hyperedges: (0 ..< m).map { Array(hypergraph.memberIndices(ofHyperedgeAt: $0)) })
            #expect(twice == relabeled)
            #expect(Array(twice.vertices) == Array(0 ..< n) && twice.hyperedges.map { Array($0) } == relabeled.hyperedges.map { Array($0) })
        }
    }

    @Test("Directed: reversed is an involution, dual(dual) relabels, and reversal commutes with the dual")
    func directedDualAndReversal() async {
        let side = Gen.int(in: 0 ... 7).array(of: 0 ... 3)
        let input = zip(Gen.int(in: 0 ... 7).array(of: 0 ... 4), zip(side, side).array(of: 0 ... 8))
        await propertyCheck(count: 300, input: input) { listed, raw in
            let hypergraph = IncidenceList(vertices: listed.map { "v\($0)" }, hyperedges: raw.map { (sources: $0.0.map { "v\($0)" }, targets: $0.1.map { "v\($0)" }) })
            let n = hypergraph.vertexCount, m = hypergraph.hyperedgeCount
            let reversed = hypergraph.reversed
            #expect(reversed.reversed == hypergraph && Array(reversed.vertices) == Array(hypergraph.vertices))
            for p in 0 ..< m {
                #expect(Array(reversed.sourceIndices(ofHyperedgeAt: p)) == Array(hypergraph.targetIndices(ofHyperedgeAt: p)))
                #expect(Array(reversed.targetIndices(ofHyperedgeAt: p)) == Array(hypergraph.sourceIndices(ofHyperedgeAt: p)))
            }
            let dual = hypergraph.dual()
            #expect(Array(dual.vertices) == Array(0 ..< m) && dual.hyperedgeCount == n)
            for i in 0 ..< n {
                #expect(Array(dual.sourceIndices(ofHyperedgeAt: i)) == Array(hypergraph.outHyperedges(ofIndex: i)))
                #expect(Array(dual.targetIndices(ofHyperedgeAt: i)) == Array(hypergraph.inHyperedges(ofIndex: i)))
            }
            let relabeled = IncidenceList<Int>(vertices: 0 ..< n, hyperedges: (0 ..< m).map {
                (sources: Array(hypergraph.sourceIndices(ofHyperedgeAt: $0)), targets: Array(hypergraph.targetIndices(ofHyperedgeAt: $0)))
            })
            #expect(dual.dual() == relabeled)
            #expect(reversed.dual() == dual.reversed)
        }
    }

    @Test("B-Visit and F-Visit equal the fixpoint of their definition; F is B on the reversal")
    func visitsAgainstFixpoint() async {
        let side = Gen.int(in: 0 ... 6).array(of: 0 ... 3)
        let input = zip(side, side).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: input) { raw in
            let hypergraph = IncidenceList(vertices: (0 ... 6).map { "v\($0)" }, hyperedges: raw.map { (sources: $0.0.map { "v\($0)" }, targets: $0.1.map { "v\($0)" }) })
            // The model: a hyperedge with sources fires once every source is reached; repeat to a fixpoint.
            func closure(from start: Int, tails: [[Int]], heads: [[Int]]) -> Set<Int> {
                var reached: Set<Int> = [start]
                var changed = true
                while changed {
                    changed = false
                    for (tail, head) in zip(tails, heads) where !tail.isEmpty && tail.allSatisfy(reached.contains) {
                        for h in head where !reached.contains(h) { reached.insert(h); changed = true }
                    }
                }
                return reached
            }
            let tails = raw.map { Set($0.0).sorted() }, heads = raw.map { Set($0.1).sorted() }
            for s in 0 ... 6 {
                let b = closure(from: s, tails: tails, heads: heads).sorted().map { "v\($0)" }
                let f = closure(from: s, tails: heads, heads: tails).sorted().map { "v\($0)" }
                #expect(hypergraph.bConnectedVertices(from: "v\(s)") == b, "B from v\(s) in \(raw)")
                #expect(hypergraph.fConnectedVertices(to: "v\(s)") == f, "F to v\(s) in \(raw)")
                #expect(hypergraph.reversed.bConnectedVertices(from: "v\(s)") == f)
                for t in 0 ... 6 {
                    #expect(hypergraph.isBConnected(from: "v\(s)", to: "v\(t)") == b.contains("v\(t)"))
                    #expect(hypergraph.isFConnected(from: "v\(t)", to: "v\(s)") == f.contains("v\(t)"))
                }
            }
            #expect(hypergraph.isBHypergraph == heads.allSatisfy { $0.count == 1 })
            #expect(hypergraph.isFHypergraph == tails.allSatisfy { $0.count == 1 })
            #expect(hypergraph.isBFHypergraph == zip(tails, heads).allSatisfy { $0.count == 1 || $1.count == 1 })
        }
    }

    @Test("Directed components and the clique expansion against direct computations")
    func directedComponentsAgainstModel() async {
        let side = Gen.int(in: 0 ... 7).array(of: 0 ... 3)
        let input = zip(side, side).array(of: 0 ... 10)
        await propertyCheck(count: 300, input: input) { raw in
            let hypergraph = IncidenceList(vertices: (0 ... 7).map { "v\($0)" }, hyperedges: raw.map { (sources: $0.0.map { "v\($0)" }, targets: $0.1.map { "v\($0)" }) })
            let tails = raw.map { Set($0.0) }, heads = raw.map { Set($0.1) }
            // Reachability along source → hyperedge → target steps, and weak joins through any side.
            func reach(_ start: Int) -> Set<Int> {
                var seen: Set<Int> = [start], stack = [start]
                while let x = stack.popLast() {
                    for (tail, head) in zip(tails, heads) where tail.contains(x) {
                        for y in head where seen.insert(y).inserted { stack.append(y) }
                    }
                }
                return seen
            }
            let reaches = (0 ... 7).map(reach)
            var strong: [[Int]] = []
            for i in 0 ... 7 where !strong.contains(where: { $0.contains(i) }) {
                strong.append((0 ... 7).filter { reaches[i].contains($0) && reaches[$0].contains(i) })
            }
            #expect(hypergraph.stronglyConnectedComponents() == strong.map { $0.map { "v\($0)" } })
            var weak: [Set<Int>] = (0 ... 7).map { [$0] }
            for (tail, head) in zip(tails, heads) where !tail.union(head).isEmpty {
                let joined = tail.union(head)
                let merged = weak.filter { !$0.isDisjoint(with: joined) }.reduce(joined) { $0.union($1) }
                weak = weak.filter { $0.isDisjoint(with: joined) } + [merged]
            }
            #expect(hypergraph.weaklyConnectedComponents() == weak.map { $0.sorted() }.sorted { $0[0] < $1[0] }.map { $0.map { "v\($0)" } })
            #expect(hypergraph.isStronglyConnected == (strong.count == 1) && hypergraph.isWeaklyConnected == (weak.count == 1))
            var arcs = Set<[Int]>()
            for (tail, head) in zip(tails, heads) { for u in tail { for v in head where u != v { arcs.insert([u, v]) } } }
            let expansion = hypergraph.cliqueExpansion()
            #expect(Array(expansion.vertices) == (0 ... 7).map { "v\($0)" })
            #expect(expansion.edges.map { [$0.source, $0.target] } == arcs.sorted { $0.lexicographicallyPrecedes($1) }.map { $0.map { "v\($0)" } })
        }
    }

    @Test("Undirected components, s-components, the line graph and the clique expansion against direct computations")
    func undirectedAlgorithmsAgainstModel() async {
        let input = zip(Gen.int(in: 0 ... 7).array(of: 0 ... 5).array(of: 0 ... 10), Gen.int(in: 1 ... 3))
        await propertyCheck(count: 300, input: input) { raw, s in
            let names = (0 ... 7).map { "v\($0)" }
            let hypergraph = UndirectedIncidenceList(vertices: names, hyperedges: raw.map { $0.map { "v\($0)" } })
            let sets = raw.map { Set($0) }
            let m = sets.count
            var pairs: [[Int]] = []
            for p in 0 ..< m { for q in p + 1 ..< m where sets[p].intersection(sets[q]).count >= s { pairs.append([p, q]) } }
            let line = hypergraph.lineGraph(s: s)
            #expect(Array(line.vertices) == Array(0 ..< m) && line.edges.map { [$0.u, $0.v] } == pairs)
            // s-components: the components of that graph, by least position, singletons included.
            var components: [[Int]] = []
            for p in 0 ..< m where !components.contains(where: { $0.contains(p) }) {
                var seen: Set<Int> = [p], stack = [p]
                while let x = stack.popLast() {
                    for pair in pairs where pair.contains(x) {
                        let y = pair[0] == x ? pair[1] : pair[0]
                        if seen.insert(y).inserted { stack.append(y) }
                    }
                }
                components.append(seen.sorted())
            }
            #expect(hypergraph.sConnectedComponents(s: s) == components)
            var vertexComponents: [Set<Int>] = (0 ... 7).map { [$0] }
            for e in sets where !e.isEmpty {
                let merged = vertexComponents.filter { !$0.isDisjoint(with: e) }.reduce(e) { $0.union($1) }
                vertexComponents = vertexComponents.filter { $0.isDisjoint(with: e) } + [merged]
            }
            #expect(hypergraph.connectedComponents() == vertexComponents.map { $0.sorted() }.sorted { $0[0] < $1[0] }.map { $0.map { "v\($0)" } })
            var edges = Set<[Int]>()
            for e in sets { for u in e { for v in e where u < v { edges.insert([u, v]) } } }
            let expansion = hypergraph.cliqueExpansion()
            #expect(Array(expansion.vertices) == names)
            #expect(expansion.edges.map { [$0.u, $0.v] } == edges.sorted { $0.lexicographicallyPrecedes($1) }.map { $0.map { "v\($0)" } })
            for (i, v) in names.enumerated() {
                let shared = Set(sets.filter { $0.contains(i) }.flatMap { $0 }).subtracting([i])
                #expect(hypergraph.neighbors(of: v) == shared.sorted().map { "v\($0)" })
            }
            #expect(hypergraph.rank == (sets.map(\.count).max() ?? 0))
            #expect(hypergraph.isUniform(size: s) == sets.allSatisfy { $0.count == s })
        }
    }

    @Test("sConnectedComponents(s: 1) equals the connected components of the dual")
    func oneComponentsAreTheDualsComponents() async {
        let input = Gen.int(in: 0 ... 9).array(of: 0 ... 5).array(of: 0 ... 12)
        await propertyCheck(count: 300, input: input) { raw in
            // Two hyperedges share a member exactly when they meet at a vertex of the dual.
            let hypergraph = UndirectedIncidenceList(vertices: 0 ... 9, hyperedges: raw)
            #expect(hypergraph.sConnectedComponents(s: 1) == hypergraph.dual().connectedComponents())
            #expect(hypergraph.sConnectedComponents(s: 1).flatMap { $0 }.sorted() == Array(0 ..< raw.count))
        }
    }

    @Test("Equality and hashing ignore vertex and hyperedge order; Codable round trips")
    func equalityUnderReordering() async {
        let input = zip(Gen.int(in: 0 ... 7).array(of: 0 ... 4).array(of: 0 ... 8), Gen.int(in: 0 ... 1_000))
        await propertyCheck(count: 300, input: input) { raw, seed in
            var rng = SeededRandomNumberGenerator(seed: UInt(seed))
            let hypergraph = UndirectedIncidenceList(vertices: ["extra"], hyperedges: raw.map { $0.map { "v\($0)" } })
            let shuffled = UndirectedIncidenceList(vertices: Array(hypergraph.vertices).shuffled(using: &rng),
                                                   hyperedges: hypergraph.hyperedges.map { Array($0).shuffled(using: &rng) }.shuffled(using: &rng))
            #expect(shuffled == hypergraph && shuffled.hashValue == hypergraph.hashValue)
            var more = hypergraph
            more.insert(hyperedge: raw.first.map { $0.map { "v\($0)" } } ?? [])
            #expect(more != hypergraph)
            let directed = IncidenceList(vertices: ["extra"], hyperedges: raw.map { (sources: $0.prefix(2).map { "v\($0)" }, targets: $0.dropFirst(2).map { "v\($0)" }) })
            let directedShuffled = IncidenceList(vertices: Array(directed.vertices).shuffled(using: &rng),
                                                 hyperedges: directed.hyperedges.map { (sources: Array($0.sources).shuffled(using: &rng), targets: Array($0.targets).shuffled(using: &rng)) }.shuffled(using: &rng))
            #expect(directedShuffled == directed && directedShuffled.hashValue == directed.hashValue)
            let decoded = try? JSONDecoder().decode(UndirectedIncidenceList<String>.self, from: JSONEncoder().encode(shuffled))
            #expect(decoded == shuffled && decoded.map { Array($0.vertices) } == Array(shuffled.vertices))
            let decodedDirected = try? JSONDecoder().decode(IncidenceList<String>.self, from: JSONEncoder().encode(directedShuffled))
            #expect(decodedDirected == directedShuffled)
        }
    }
}
