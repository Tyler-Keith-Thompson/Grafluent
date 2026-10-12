// The families that defeat a matcher without automorphism pruning, each inside a Task with a
// one-minute limit and meant to finish in well under a second even in a debug build (the
// benchmarks take timings): disjoint unions of equal components against unions with one component
// changed, Latin-square graphs of two groups of one order (strongly regular with equal parameters),
// twisted CFI pairs over a cubic base of 40, and pairs of random regular graphs. Then the
// automorphism group and canonical labeling on the same families, an iterator copied in the middle
// of a sequence, cancellation, and the inverse mapping. The families themselves rely on speed and
// are in Performance/IsomorphismHardFamiliesScaleTests.swift. See README.md.

import AdjacencyListModule
import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import Multigraphs
import RandomGraphs
import Testing

@Suite("Isomorphism on hard families")
struct IsomorphismHardFamiliesTests {
    @Test("An iterator copied in the middle of a sequence goes on with the same mappings as the original")
    func iteratorCopiedMidSequence() {
        var k5: [UndirectedEdge<Int>] = []
        for u in 0 ..< 5 { for v in u + 1 ..< 5 { k5.append(UndirectedEdge(u, v)) } }
        let complete = UndirectedAdjacencyList(vertices: 0 ..< 5, edges: k5)
        let path = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        for sequence in [complete.isomorphisms(to: complete), path.monomorphisms(to: complete), path.subgraphIsomorphisms(to: path)] {
            let all = Array(sequence)
            for cut in [0, 1, 7, all.count - 1] where cut < all.count {
                var original = sequence.makeIterator()
                for _ in 0 ..< cut { _ = original.next() }
                var copy = original
                var fromOriginal: [Isomorphism<UndirectedAdjacencyList<Int>, UndirectedAdjacencyList<Int>>] = []
                var fromCopy = fromOriginal
                while let m = original.next() { fromOriginal.append(m) }
                while let m = copy.next() { fromCopy.append(m) }
                #expect(fromOriginal == Array(all[cut...]))
                #expect(fromCopy == Array(all[cut...]))
            }
        }
        #expect(Array(complete.isomorphisms(to: complete)).count == 120)
    }

    @Test("In a cancelled task the isomorphism sequence ends after its first mapping and the monomorphism search stops early")
    func cancellation() async {
        let empty = UndirectedAdjacencyList<Int>(vertices: 0 ..< 8, edges: [])
        var complete: [UndirectedEdge<Int>] = []
        for u in 0 ..< 60 { for v in u + 1 ..< 60 { complete.append(UndirectedEdge(u, v)) } }
        let target = UndirectedAdjacencyList(vertices: 0 ..< 60, edges: complete)
        let path = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return (Array(empty.isomorphisms(to: empty)).count, path.monomorphisms(to: target).reduce(0) { n, _ in n + 1 })
        }
        let (isomorphisms, monomorphisms) = await task.value
        #expect(isomorphisms == 1)
        #expect(monomorphisms < 60 * 59 * 58)
        // Without cancellation: 8! and 60 · 59 · 58.
        #expect(Array(empty.isomorphisms(to: empty)).count == 40320)
        let monomorphismCount: Int = path.monomorphisms(to: target).reduce(0) { n, _ in n + 1 }
        #expect(monomorphismCount == 60 * 59 * 58)
    }

    @Test("The inverse of an isomorphism maps each image back; preimage(checked:) throws off the target and is nil outside the image")
    func inverseAndCheckedPreimage() throws {
        let g = UndirectedAdjacencyList(vertices: [1, 2, 3, 4], edges: [UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let h = UndirectedAdjacencyList(vertices: [10, 20, 30, 40], edges: [UndirectedEdge(30, 10), UndirectedEdge(10, 40), UndirectedEdge(40, 20)])
        for mapping in g.isomorphisms(to: h) {
            let inverse = mapping.inverse
            #expect(g.vertices.allSatisfy { inverse.image(of: mapping.image(of: $0)) == $0 })
            #expect(h.vertices.allSatisfy { inverse.image(of: $0) == mapping.preimage(of: $0) })
            #expect(h.edges.allSatisfy { g.contains(edge: UndirectedEdge(inverse.image(of: $0.u), inverse.image(of: $0.v))) })
            #expect(throws: VertexNotFound.self) { try mapping.preimage(checked: 99) }
            #expect(try mapping.preimage(checked: 20) == mapping.preimage(of: 20))
        }
        let pattern = UndirectedAdjacencyList(vertices: [1, 2], edges: [UndirectedEdge(1, 2)])
        let mapping = try #require(pattern.subgraphIsomorphism(to: h))
        let outside = try #require(h.vertices.first { !mapping.images.contains($0) })
        #expect(try mapping.preimage(checked: outside) == nil)
    }

    @Test("Canonical labelings: relabelled copies get equal forms, a permutation and matching indices; directed C3 and its two orientations")
    func canonicalLabelings() {
        let petersen: [[Int]] = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [0, 5], [1, 6], [2, 7], [3, 8], [4, 9], [5, 7], [7, 9], [9, 6], [6, 8], [8, 5]]
        var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: 24)
        let permutation = Array(0 ..< 10).shuffled(using: &rng)
        let g = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: petersen.map { UndirectedEdge($0[0], $0[1]) })
        let h = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: petersen.shuffled(using: &rng).map { UndirectedEdge(permutation[$0[0]], permutation[$0[1]]) })
        let a = g.canonicalLabeling(), b = h.canonicalLabeling()
        #expect(a.form == b.form && a.form.hashValue == b.form.hashValue)
        #expect(Set(a.permutation) == Set(0 ..< 10))
        #expect(g.vertices.allSatisfy { a.canonicalIndex(of: $0) == a.permutation[$0] })
        // Renumbering both by their labelings gives the same edge set.
        let left = Set(g.edges.map { Set([a.canonicalIndex(of: $0.u), a.canonicalIndex(of: $0.v)]) })
        let right = Set(h.edges.map { Set([b.canonicalIndex(of: $0.u), b.canonicalIndex(of: $0.v)]) })
        #expect(left == right)
        // A parallel edge or a loop changes the form.
        let doubled = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let looped = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1), UndirectedEdge(1, 2)])
        let shifted = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(2, 1), UndirectedEdge(2, 1), UndirectedEdge(1, 0)])
        #expect(doubled.canonicalLabeling().form != looped.canonicalLabeling().form)
        #expect(doubled.canonicalLabeling().form == shifted.canonicalLabeling().form)
        let forward = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let backward = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 0, to: 2)])
        let transitive = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 0, to: 2)])
        #expect(forward.canonicalLabeling().form == backward.canonicalLabeling().form)
        #expect(forward.canonicalLabeling().form != transitive.canonicalLabeling().form)
    }
}
