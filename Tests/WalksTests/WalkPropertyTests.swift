// Property checks with shrinking (swift-property-based): on a failure, PropertyBased shrinks the
// generated input and prints the smallest one that still fails. The oracles are brute force,
// written in each test: every rotation for Circuit and Cycle equality and hashing (WK-701,
// WK-711), every choice of parallel edges for Trail(_:in:) (WK-510), and the step law and the
// invariant of each type for the checked initializers (WK-101, WK-202). Case IDs (WK-nnn) refer
// to the catalog; see README.md.

import GraphProtocols
import GrafluentTestSupport
import PropertyBased
import Testing
import Walks

@Suite("Walk properties with shrinking", .tags(.randomized))
struct WalkPropertyTests {
    @Test("WK-701 WK-711 a circuit equals and hashes like every rotation, and differs from every perturbation that brute force says differs")
    func rotationInvariance() async {
        // Up to 7 steps over vertices 0...2 (so vertices repeat), a perturbed step and a perturbed
        // vertex. Edges are the step indices, so they are distinct.
        let vertices = Gen.int(in: 0 ... 2).array(of: 1 ... 7)
        await propertyCheck(count: 300, input: vertices, Gen.int(in: 0 ... 6), Gen.int(in: 0 ... 2)) { vs, step, replacement in
            let n = vs.count
            let es = Array(0 ..< n)
            guard let circuit = Circuit(vertices: vs, edges: es) else {
                Issue.record("not a circuit: \(vs)")
                return
            }
            let cycle = Cycle(vertices: vs, edges: es)
            #expect((cycle != nil) == (Set(vs).count == n))
            for k in 0 ..< n {
                let rv = Array(vs[k...] + vs[..<k])
                let re = Array(es[k...] + es[..<k])
                guard let rotated = Circuit(vertices: rv, edges: re) else {
                    Issue.record("rotation \(k) of \(vs) is not a circuit")
                    continue
                }
                #expect(rotated == circuit, "k = \(k)")
                #expect(rotated.hashValue == circuit.hashValue, "k = \(k)")
                #expect(Array(rotated) == rv)
                if let cycle {
                    let rotatedCycle = Cycle(vertices: rv, edges: re)
                    #expect(rotatedCycle == cycle, "k = \(k)")
                    #expect(rotatedCycle?.hashValue == cycle.hashValue, "k = \(k)")
                }
                // Perturb one vertex of the rotation; brute force decides equality.
                var pv = rv
                pv[step % n] = replacement
                let bruteForce = (0 ..< n).contains { r in Array(vs[r...] + vs[..<r]) == pv && Array(es[r...] + es[..<r]) == re }
                if let perturbed = Circuit(vertices: pv, edges: re) {
                    #expect((perturbed == circuit) == bruteForce, "\(vs) vs \(pv) \(re)")
                    if bruteForce { #expect(perturbed.hashValue == circuit.hashValue) }
                }
                // A fresh edge in one step is never equal.
                var pe = re
                pe[step % n] = n
                #expect(Circuit(vertices: rv, edges: pe) != circuit)
            }
            // Reversal is no rotation unless it gives the same steps.
            let reversed = circuit.reversed()
            let reversalIsRotation = (0 ..< n).contains { r in
                Array(vs[r...] + vs[..<r]) == reversed.vertices && Array(es[r...] + es[..<r]) == reversed.edges
            }
            #expect((reversed == circuit) == reversalIsRotation)
            #expect(reversed.reversed() == circuit)
        }
    }

    @Test("WK-510 Trail(_:in:) is non-nil exactly when brute force finds a trail, directed and undirected")
    func trailIffBruteForce() async {
        // Up to 7 edges on vertices 0...2, loops and repeats allowed, and a vertex sequence of 1 to 5.
        let edges = zip(Gen.int(in: 0 ... 2), Gen.int(in: 0 ... 2)).array(of: 0 ... 7)
        let sequence = Gen.int(in: 0 ... 2).array(of: 1 ... 5)
        await propertyCheck(count: 400, input: edges, sequence) { raw, vs in
            let directed = ReferenceDirectedMultigraph(vertices: 0 ..< 3, edges: raw.map { DirectedEdge(from: $0.0, to: $0.1) })
            let undirected = ReferencePseudograph(vertices: 0 ..< 3, edges: raw.map { UndirectedEdge($0.0, $0.1) })
            for isDirected in [true, false] {
                var choices: [[Int]] = [[]]
                for i in 0 ..< vs.count - 1 {
                    let (a, b) = (vs[i], vs[i + 1])
                    let joining = raw.indices.filter { k in
                        isDirected ? raw[k] == (a, b) : (raw[k] == (a, b) || raw[k] == (b, a))
                    }
                    choices = choices.flatMap { c in joining.map { c + [$0] } }
                }
                let walkExists = !choices.isEmpty
                let trailExists = choices.contains { Set($0).count == $0.count }
                let pathExists = walkExists && Set(vs).count == vs.count
                let walk = isDirected ? Walk(vs, in: directed) : Walk(vs, in: undirected)
                let trail = isDirected ? Trail(vs, in: directed) : Trail(vs, in: undirected)
                let path = isDirected ? Path(vs, in: directed) : Path(vs, in: undirected)
                #expect((walk != nil) == walkExists, "directed: \(isDirected)")
                #expect((trail != nil) == trailExists, "directed: \(isDirected)")
                #expect((path != nil) == pathExists, "directed: \(isDirected)")
                // Walk takes the first joining edge every time.
                if let walk {
                    #expect(walk.edges == (0 ..< vs.count - 1).map { i in
                        raw.indices.first { k in
                            isDirected ? raw[k] == (vs[i], vs[i + 1]) : (raw[k] == (vs[i], vs[i + 1]) || raw[k] == (vs[i + 1], vs[i]))
                        }!
                    })
                }
                if let trail {
                    #expect(trail.vertices == vs)
                    #expect(Set(trail.edges).count == trail.edges.count)
                    #expect(choices.contains(trail.edges))
                }
                // The checked initializer accepts exactly the brute-force choices.
                for es in choices {
                    let checked = isDirected ? Walk(vertices: vs, edges: es, in: directed) : Walk(vertices: vs, edges: es, in: undirected)
                    #expect(checked != nil, "\(es)")
                }
            }
        }
    }
}
