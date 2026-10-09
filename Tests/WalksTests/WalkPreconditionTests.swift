// §13: preconditions, as exit tests. The wrong count shape is a programmer error and traps (with a
// graph it is a nil instead, WK-108); so do appending a walk that does not start where the
// receiver ends, an edge position outside the graph, and subscripting past the end. Each exit
// test builds its inputs inside the closure. Case IDs (WK-nnn) refer to the catalog; see
// README.md.

import GraphProtocols
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk preconditions", .tags(.precondition))
struct WalkPreconditionTests {
    @Test("WK-1301 an open walk with one vertex too many for its edges traps")
    func tooManyVertices() async {
        await #expect(processExitsWith: .failure) {
            _ = Walk<Int, Int>(vertices: [0, 1], edges: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = Path<Int, Int>(vertices: [0, 1, 2], edges: [0])
        }
        await #expect(processExitsWith: .failure) {
            _ = Trail<Int, Int>(vertices: [0, 1], edges: [0, 1])
        }
    }

    @Test("WK-1302 an open walk with no vertices traps")
    func noVertices() async {
        await #expect(processExitsWith: .failure) {
            _ = Walk<Int, Int>(vertices: [], edges: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = Path<Int, Int>(vertices: [], edges: [])
        }
        await #expect(processExitsWith: .failure) {
            _ = Trail<Int, Int>(vertices: [], edges: [])
        }
    }

    @Test("WK-1303 a circuit or cycle needs as many edges as vertices")
    func closedCounts() async {
        await #expect(processExitsWith: .failure) {
            _ = Cycle<Int, Int>(vertices: [0, 1], edges: [0])
        }
        await #expect(processExitsWith: .failure) {
            _ = Circuit<Int, Int>(vertices: [0, 1], edges: [0, 1, 2])
        }
    }

    @Test("WK-1304 appending a walk that does not start at the target traps (JGraphT testIllegalConcatPath2)")
    func appendMismatch() async {
        await #expect(processExitsWith: .failure) {
            _ = Walk<Int, Int>(vertex: 0).appending(Walk(vertex: 1))
        }
        await #expect(processExitsWith: .failure) {
            var walk = Walk(vertices: [0, 1], edges: [5])
            walk.append(Walk(vertices: [0, 2], edges: [6]))
        }
    }

    @Test("WK-1305 an edge position outside the graph's edges is no walk of it: nil, not a trap (what decoded data needs)")
    func positionOutOfRange() {
        let d4 = ReferenceDirectedMultigraph(edges: [(0, 1), (1, 2), (2, 3), (3, 0)].map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Walk(vertices: [0, 1], edges: [99], in: d4) == nil)
        #expect(Walk(vertices: [0, 1], edges: [-1], in: d4) == nil)
        #expect(Walk(vertices: [0, 1], edges: [0], in: d4) != nil)
        let u = ReferencePseudograph(edges: [(0, 1), (1, 2), (2, 0)].map { UndirectedEdge($0.0, $0.1) })
        #expect(Cycle(vertices: [0, 1, 2], edges: [0, 1, 99], in: u) == nil)
        #expect(Cycle(vertices: [0, 1, 2], edges: [0, 1, 2], in: u) != nil)
    }

    @Test("WK-1306 subscripting past the end traps")
    func subscriptPastEnd() async {
        await #expect(processExitsWith: .failure) {
            let w = Walk(vertices: [0, 1, 2], edges: [5, 6])
            _ = w[w.count]
        }
        await #expect(processExitsWith: .failure) {
            let c = Cycle(vertices: [0, 1, 2], edges: [5, 6, 7])!
            _ = c[c.count]
        }
        await #expect(processExitsWith: .failure) {
            _ = Walk<Int, Int>(vertex: 0)[-1]
        }
    }
}
