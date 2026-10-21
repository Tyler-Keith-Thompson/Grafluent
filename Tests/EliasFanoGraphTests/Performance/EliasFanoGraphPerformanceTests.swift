//
//  EliasFanoGraphPerformanceTests.swift
//  Grafluent
//
//  Decoding must keep pace with reading a compressed sparse row: a walk over every successor of
//  every vertex is bounded against the same walk over `CompressedSparseRow`, and the coded rows
//  take far fewer bits than the 64 of a stored target.
//

import CompressedSparseRowModule
import EliasFanoGraphModule
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite struct EliasFanoGraphPerformanceTests {
    @Test("A walk over every row decodes within four times a compressed sparse row's walk, and codes under 20 bits an edge", .timeLimit(.minutes(2)))
    func decodingKeepsPace() {
        #if DEBUG
        let n = 2_000, m = 20_000
        #else
        let n = 200_000, m = 2_000_000
        #endif
        var generator = SeededRandomNumberGenerator(seed: 5)
        var edges: [DirectedEdge<Int>] = []
        edges.reserveCapacity(m)
        for _ in 0 ..< m { edges.append(DirectedEdge(from: Int.random(in: 0 ..< n, using: &generator), to: Int.random(in: 0 ..< n, using: &generator))) }
        let rows = CompressedSparseRow(vertexCount: n, edges: edges)
        let coded = EliasFanoGraph(rows)
        #expect(coded.bitsPerEdge < 20)

        func walkRows() -> Int {
            var sum = 0
            for v in 0 ..< n { for w in rows.successors(of: v) { sum &+= w } }
            return sum
        }
        func walkCoded() -> Int {
            var sum = 0
            for v in 0 ..< n { coded._forEachSuccessorIndex(ofIndex: v) { sum &+= $0 } }
            return sum
        }
        let clock = ContinuousClock()
        _ = walkRows()
        _ = walkCoded()
        var rowsTime = Duration.seconds(1_000), codedTime = Duration.seconds(1_000)
        for _ in 0 ..< 3 {
            rowsTime = min(rowsTime, clock.measure { _ = walkRows() })
            codedTime = min(codedTime, clock.measure { _ = walkCoded() })
        }
        #expect(walkRows() == walkCoded())
        #expect(codedTime <= rowsTime * 4, "coded \(codedTime), rows \(rowsTime)")
    }
}
