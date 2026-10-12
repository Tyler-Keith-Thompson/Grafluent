// Laziness, split from IsomorphismConformanceTests.swift because it relies on speed: the first
// mappings of a graph with 40! of them come at once, under a one-minute limit. See README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CompressedSparseRowModule
import GrafluentTestSupport
import GraphProtocols
import IsomorphismModule
import LabeledGraphs
import Multigraphs
import Testing

@Suite("Isomorphism laziness")
struct IsomorphismLazinessTests {
    @Test("The sequence is lazy: the first mappings of E(40) onto itself (40! of them) and of K₁₂ come at once", .timeLimit(.minutes(1)))
    func laziness() async {
        await Task {
            let empty = Pseudograph(vertices: 0 ..< 40)
            let some = Array(empty.isomorphisms(to: empty).prefix(5))
            #expect(some.count == 5 && Set(some).count == 5)
            #expect(some.allSatisfy { Set($0.images) == Set(0 ..< 40) })
            #expect(empty.isIsomorphic(to: empty) && empty.isomorphism(to: empty) != nil)
            var edges: [UndirectedEdge<Int>] = []
            for u in 0 ..< 12 { for v in u + 1 ..< 12 { edges.append(UndirectedEdge(u, v)) } }
            let complete = Pseudograph(vertices: 0 ..< 12, edges: edges)
            var iterator = complete.isomorphisms(to: complete).makeIterator()
            var seen = Set<[Int]>()
            for _ in 0 ..< 100 {
                guard let mapping = iterator.next() else { break }
                seen.insert(Array(mapping.images))
            }
            #expect(seen.count == 100)
            let digraph = DirectedPseudograph(vertices: 0 ..< 40)
            #expect(Array(digraph.monomorphisms(to: digraph).prefix(3)).count == 3)
            #expect(Array(Pseudograph(vertices: 0 ..< 3).monomorphisms(to: empty).prefix(4)).count == 4)
        }.value
    }
}
