// Hierarchical Leiden against an oracle written inside the test, with shrinking
// (swift-property-based). Graphs are multigraphs with self-loops on up to 9 vertices with integer
// weights 0 … 3, undirected and directed, with a cap of 1 … 4. The oracle replays the definition
// with the same seed: `leidenCommunities` on the whole graph, then, level by level and in community
// order, on a reference graph of each community over the cap (its vertices renumbered in order, its
// inside edges in position order), one generator throughout; a piece Leiden keeps whole is final.
// The hierarchy's levels, members, parents and leaves must be the oracle's, and the leaves a
// partition whose `community(of:)` agrees; the same seed gives the same hierarchy.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("Hierarchical Leiden against an oracle, with shrinking", .tags(.randomized))
struct HierarchicalLeidenPropertyTests {
    @Test("The hierarchy is Leiden replayed on the induced pieces in level order, from the same seed; both kinds, both quality functions, caps 1 … 4")
    func replay() async {
        let triples = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 3)).array(of: 0 ... 18)
        await propertyCheck(count: 300, input: triples, Gen.int(in: 0 ... 9), Gen.bool, Gen.bool, Gen.int(in: 1 ... 4), Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, potts, cap, seed in
            let ends: [(Int, Int)] = n == 0 ? [] : raw.map { ($0.0 % n, $0.1 % n) }
            let w: [Double] = n == 0 ? [] : raw.map { Double($0.2) }
            let quality: QualityFunction = potts ? .constantPottsModel : .modularity
            let gamma = potts ? 0.4 : 1.0
            let context = "\(ends), weights \(w), directed \(isDirected), \(quality), cap \(cap), seed \(seed)"
            // The oracle: every community as (level, parent, members), in the library's numbering.
            struct Community: Equatable {
                var level: Int
                var parent: Int?
                var members: [Int]
            }
            func partition(_ vertices: [Int], _ edges: [Int], _ generator: inout GrafluentTestSupport.SeededRandomNumberGenerator) -> [[Int]] {
                var local = [Int](repeating: -1, count: n)
                for (i, v) in vertices.enumerated() { local[v] = i }
                let localWeights = edges.map { w[$0] }
                if isDirected {
                    let piece = ReferenceDirectedMultigraph(vertices: 0 ..< vertices.count, edges: edges.map { DirectedEdge(from: local[ends[$0].0], to: local[ends[$0].1]) })
                    return piece.leidenCommunities(weight: { localWeights[$0] }, quality: quality, resolution: gamma, using: &generator).map { $0.map { vertices[$0] } }
                }
                let piece = ReferencePseudograph(vertices: 0 ..< vertices.count, edges: edges.map { UndirectedEdge(local[ends[$0].0], local[ends[$0].1]) })
                return piece.leidenCommunities(weight: { localWeights[$0] }, quality: quality, resolution: gamma, using: &generator).map { $0.map { vertices[$0] } }
            }
            func oracle(_ generator: inout GrafluentTestSupport.SeededRandomNumberGenerator) -> [Community] {
                guard n > 0 else { return [] }
                var communities = partition(Array(0 ..< n), Array(ends.indices), &generator).map { Community(level: 0, parent: nil, members: $0) }
                var oversized = communities.indices.filter { communities[$0].members.count > cap }
                var level = 1
                while !oversized.isEmpty {
                    var next: [Int] = []
                    for c in oversized {
                        let members = communities[c].members
                        let inside = ends.indices.filter { members.contains(ends[$0].0) && members.contains(ends[$0].1) }
                        let pieces = partition(members, inside, &generator)
                        guard pieces.count > 1 else { continue }
                        for piece in pieces {
                            communities.append(Community(level: level, parent: c, members: piece))
                            if piece.count > cap { next.append(communities.count - 1) }
                        }
                    }
                    oversized = next
                    level += 1
                }
                return communities
            }
            var a = SeededRandomNumberGenerator(seed: UInt(seed)), b = a, c = a
            let expected = oracle(&a)
            func check<G: DirectedGraph>(_ result: CommunityHierarchy<G>) where G.Vertex == Int {
                let actual = (0 ..< result.count).map { Community(level: result.level(of: $0), parent: result.parent(of: $0), members: Array(result[$0])) }
                #expect(actual == expected, "hierarchy; \(context)")
                #expect(result.levelCount == ((expected.map(\.level).max() ?? -1) + 1), "levels; \(context)")
                for level in 0 ..< result.levelCount {
                    #expect(Array(result.communities(atLevel: level)) == expected.indices.filter { expected[$0].level == level }, "level \(level); \(context)")
                }
                for c in 0 ..< result.count {
                    #expect(Array(result.children(of: c)) == expected.indices.filter { expected[$0].parent == c }, "children of \(c); \(context)")
                }
                let leaves = result.leaves
                #expect(leaves == expected.indices.filter { c in !expected.contains { $0.parent == c } }, "leaves; \(context)")
                #expect(leaves.flatMap { Array(result[$0]) }.sorted() == Array(0 ..< n), "leaves partition; \(context)")
                for leaf in leaves {
                    for v in result[leaf] {
                        #expect(result.community(of: v) == leaf, "community of \(v); \(context)")
                        #expect(result.community(ofIndex: v) == leaf, "community of index \(v); \(context)")
                    }
                }
                for c in 0 ..< result.count where result.parent(of: c) != nil {
                    #expect(Set(result[result.parent(of: c)!]).isSuperset(of: result[c]), "nested in parent; \(context)")
                }
            }
            if isDirected {
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                let result = graph.hierarchicalLeidenCommunities(weight: { w[$0] }, maximumCommunitySize: cap, quality: quality, resolution: gamma, using: &b)
                check(result)
                #expect(graph.hierarchicalLeidenCommunities(weight: { w[$0] }, maximumCommunitySize: cap, quality: quality, resolution: gamma, using: &c) == result, "same seed; \(context)")
            } else {
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                let result = graph.hierarchicalLeidenCommunities(weight: { w[$0] }, maximumCommunitySize: cap, quality: quality, resolution: gamma, using: &b)
                check(result)
                #expect(graph.hierarchicalLeidenCommunities(weight: { w[$0] }, maximumCommunitySize: cap, quality: quality, resolution: gamma, using: &c) == result, "same seed; \(context)")
            }
        }
    }

    @Test("Unweighted hierarchical Leiden is the weighted one with every weight 1, for the same seed")
    func unweighted() async {
        let pairs = zip(Gen.int(in: 0 ... 8), Gen.int(in: 0 ... 8)).array(of: 0 ... 18)
        await propertyCheck(count: 150, input: pairs, Gen.int(in: 1 ... 9), Gen.bool, Gen.int(in: 1 ... 3), Gen.int(in: 0 ... 1_000_000)) { raw, n, isDirected, cap, seed in
            let ends = raw.map { ($0.0 % n, $0.1 % n) }
            var a = SeededRandomNumberGenerator(seed: UInt(seed)), b = a
            if isDirected {
                let graph = ReferenceDirectedMultigraph(vertices: 0 ..< n, edges: ends.map { DirectedEdge(from: $0.0, to: $0.1) })
                #expect(graph.hierarchicalLeidenCommunities(maximumCommunitySize: cap, using: &a) == graph.hierarchicalLeidenCommunities(weight: { _ in 1.0 }, maximumCommunitySize: cap, using: &b), "\(ends)")
            } else {
                let graph = ReferencePseudograph(vertices: 0 ..< n, edges: ends.map { UndirectedEdge($0.0, $0.1) })
                #expect(graph.hierarchicalLeidenCommunities(maximumCommunitySize: cap, using: &a) == graph.hierarchicalLeidenCommunities(weight: { _ in 1.0 }, maximumCommunitySize: cap, using: &b), "\(ends)")
            }
        }
    }
}
