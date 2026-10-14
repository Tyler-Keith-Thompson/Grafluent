// The degree sequences and the later families at 10⁵ – 10⁶: each call must finish well within its
// one-minute limit (well under a second in a release build), and its result must satisfy the
// family's laws. See README.md.

import AdjacencyListModule
import CompressedSparseRowModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import Testing

@Suite("RandomGraphs degree sequences and later families at 10⁵ – 10⁶")
struct LaterFamilyLargeTests {
    @Test("isGraphical on 10⁶ degrees: a regular sequence, the same with one degree too large, and Barabási–Albert's", .timeLimit(.minutes(1)))
    func graphicalLarge() {
        var degrees = [Int](repeating: 10, count: 1_000_000)
        #expect(isGraphical(degrees))
        degrees[0] = 1_000_000
        #expect(!isGraphical(degrees))
        var generator = Xoshiro256StarStar(seed: 1)
        let graph = CompressedSparseRow.barabasiAlbert(vertexCount: 1_000_000, edgesPerVertex: 3, using: &generator)
        var skewed = (0 ..< 1_000_000).map { graph.outDegree(of: $0) }
        for edge in graph.edges { skewed[edge.target] += 1 }
        #expect(isGraphical(skewed))
        #expect(isDigraphical(inDegrees: skewed.map { _ in 3 }, outDegrees: skewed.map { _ in 3 }))
    }

    @Test("Havel–Hakimi and Kleitman–Wang realize 10⁵ degrees exactly", .timeLimit(.minutes(1)))
    func havelHakimiLarge() {
        let degrees = (0 ..< 100_000).map { 2 + $0 % 9 }
        let graph = UndirectedAdjacencyList<Int>.havelHakimi(degreeSequence: degrees)
        let built = (0 ..< 100_000).map { graph.degree(of: $0) }
        #expect(built == degrees && graph.edgeCount == degrees.reduce(0, +) / 2)
        let directed = CompressedSparseRow.havelHakimi(inDegrees: degrees, outDegrees: degrees.reversed())
        var ins = [Int](repeating: 0, count: 100_000)
        for edge in directed.edges { ins[edge.target] += 1 }
        let outs = (0 ..< 100_000).map { directed.outDegree(of: $0) }
        #expect(ins == degrees && outs == Array(degrees.reversed()))
    }

    @Test("The configuration models at 10⁵ vertices of degree 10: every degree exact", .timeLimit(.minutes(1)))
    func configurationModelLarge() {
        let degrees = [Int](repeating: 10, count: 100_000)
        var generator = Xoshiro256StarStar(seed: 2)
        let graph = Pseudograph<Int>.configurationModel(degreeSequence: degrees, using: &generator)
        let regular = (0 ..< 100_000).allSatisfy { graph.degree(of: $0) == 10 }
        #expect(graph.edgeCount == 500_000 && regular)
        let directed = DirectedPseudograph<Int>.configurationModel(inDegrees: degrees, outDegrees: degrees, using: &generator)
        let balanced = (0 ..< 100_000).allSatisfy { directed.outDegree(of: $0) == 10 && directed.inDegree(of: $0) == 10 }
        #expect(directed.edgeCount == 1_000_000 && balanced)
    }

    @Test("Holme–Kim, Chung–Lu and random k-out at 10⁵ vertices", .timeLimit(.minutes(1)))
    func randomFamiliesLarge() {
        var generator = Xoshiro256StarStar(seed: 3)
        let holmeKim = UndirectedAdjacencyList<Int>.holmeKim(vertexCount: 100_000, edgesPerVertex: 5, triangleProbability: 0.5, using: &generator)
        #expect(holmeKim.edgeCount == 5 * (100_000 - 5))
        let weights = (0 ..< 100_000).map { 2 + Double($0 % 17) }
        let chungLu = CompressedSparseRow.chungLu(expectedDegrees: weights, using: &generator)
        // E[m] is about Σw/2 = 5·10⁵ arcs per direction; far more than 1 % off would be a defect.
        let expected = weights.reduce(0, +)
        #expect(abs(Double(chungLu.edgeCount) - expected) < 0.01 * expected)
        let kOut = CompressedSparseRow.randomKOut(vertexCount: 100_000, outDegree: 10, using: &generator)
        #expect(kOut.edgeCount == 1_000_000)
    }
}
