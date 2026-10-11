// The canonical sign (api.md, "Determinism and degenerate eigenspaces"): the first entry in index
// order whose magnitude is at least 1e-4 of the largest is positive. Not a catalog section. The
// rule is relative so that an entry that is 0 in exact arithmetic but carries rounding noise (of
// order tolerance · σ on the Lanczos path) never picks the sign; an absolute threshold such as
// GraphDrawing's 1e-9 would. Each graph lists such an entry first. See README.md.

import GrafluentTestSupport
import GraphProtocols
import SpectralGraphTheory
import Testing

@Suite("SpectralGraphTheory canonical sign")
struct CanonicalSignTests {
    @Test("A real but insignificant first entry (3e-6 of the largest) does not pick the sign")
    func smallFirstEntry() throws {
        // P₅ with the third edge 1.00001: the middle entry is −1.9e-6 when vertex 0's is +0.6. The
        // middle vertex is listed first, vertex 0 second, so the relative rule makes vertex 0
        // positive, where an absolute 1e-9 threshold would make the middle positive instead.
        let graph = ReferencePseudograph(vertices: [2, 0, 1, 3, 4], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let weights: [Double] = [1, 1, 1.00001, 1]
        let fiedler = try #require(graph.fiedlerVector(weight: { weights[$0] }))
        #expect(abs(fiedler.algebraicConnectivity - 0.3819673932056512) <= 1e-6 * 4)
        #expect(abs(fiedler.value(of: 0) - 0.601501901) <= 1e-5)
        #expect(abs(fiedler.value(of: 4) + 0.601500752) <= 1e-5)
        #expect(fiedler.value(of: 2) < 0 && fiedler.value(of: 2) > -1e-5)
        #expect(fiedler.value(ofIndex: 1) > 0)
    }

    @Test("Dense path: P₅ with its middle vertex (entry 0) listed first is signed by the next entry")
    func zeroFirstEntryDense() throws {
        let graph = ReferencePseudograph(vertices: [2, 0, 1, 3, 4], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let fiedler = try #require(graph.fiedlerVector())
        #expect(abs(fiedler.value(of: 2)) <= 1e-6)
        #expect(abs(fiedler.value(of: 0) - 0.601500955) <= 1e-5)
        #expect(abs(fiedler.value(of: 4) + 0.601500955) <= 1e-5)
    }

    @Test("Lanczos path: P₆₅ with its middle vertex listed first, on L and on N", arguments: [false, true])
    func zeroFirstEntrySparse(normalized: Bool) throws {
        let n = 65
        let listed = [32] + Array(0 ..< 32) + Array(33 ..< n)
        let graph = ReferencePseudograph(vertices: listed, edges: (0 ..< n - 1).map { UndirectedEdge($0, $0 + 1) })
        let fiedler = try #require(graph.fiedlerVector(normalized: normalized))
        // The middle entry is 0 up to the iteration's noise; the vector is odd about the middle.
        #expect(abs(fiedler.value(of: 32)) <= 1e-5)
        #expect(fiedler.value(of: 0) > 0.1)
        #expect(fiedler.value(of: n - 1) < -0.1)
        for k in 0 ..< n {
            #expect(abs(fiedler.value(of: k) + fiedler.value(of: n - 1 - k)) <= 1e-5, "vertex \(k)")
        }
        // The ordering follows the vector: on L it ascends from the far end. (N's vector is not
        // monotone along a path: its end entries are scaled by √1 against √2 inside.)
        let order = graph.spectralOrdering(normalized: normalized)
        if normalized {
            #expect(order.sorted() == Array(0 ..< n))
            for (a, b) in zip(order, order.dropFirst()) {
                #expect(fiedler.value(of: a) <= fiedler.value(of: b) + 1e-6, "\(a) before \(b)")
            }
        } else {
            #expect(order == Array((0 ..< n).reversed()))
        }
    }
}
