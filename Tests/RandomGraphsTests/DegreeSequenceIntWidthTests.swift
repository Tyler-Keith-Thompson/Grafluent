// Degree-sequence tests at either `Int` width: the Erdős–Gallai and Fulkerson–Chen–Anstee bounds
// grow as n², past 2³¹ at n ≈ 46,000, which a 32-bit `Int` (arm64_32, wasm32) cannot hold.

import RandomGraphs
import Testing

@Suite("Degree sequences at either Int width")
struct DegreeSequenceIntWidthTests {
    @Test("50,000 vertices of degree 2 are graphical, one of degree 3 among them is not: n(n − 1) passes 2³¹")
    func graphicalPastInt32() {
        #expect(isGraphical(Array(repeating: 2, count: 50_000)))
        #expect(!isGraphical([3] + Array(repeating: 2, count: 49_999)))
        // A degree sequence whose Erdős–Gallai sums pass 2³¹: 50,000 vertices of degree 49,999.
        #expect(isGraphical(Array(repeating: 49_999, count: 50_000)))
        // The complete digraph on 50,000 vertices: in- and out-degree sums of 2,499,950,000.
        let complete = Array(repeating: 49_999, count: 50_000)
        #expect(isDigraphical(inDegrees: complete, outDegrees: complete))
        #expect(!isDigraphical(inDegrees: complete, outDegrees: [49_998] + complete.dropFirst()))
    }
}
