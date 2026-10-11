// Weisfeiler–Leman (catalog IS-147 – IS-175): graph hashes compared within the process (their
// values are not pinned), and the partitions of the per-vertex hashes after each round.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Weisfeiler–Leman hashes")
struct WeisfeilerLehmanTests {
    @Test("IS-147 C6 against 2C3: never distinguished")
    func is147() {
        // `U: C(0,1,2,3,4,5)` → `U: C(0,1,2), C(3,4,5)`; `weisfeilerLehmanGraphHash(iterations: 3)` ⇒ equal
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 3)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 3)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 3) == patternHash)
        // iterations defaults to 3.
        #expect(pattern.weisfeilerLehmanGraphHash() == patternHash && target.weisfeilerLehmanGraphHash() == targetHash)
    }

    @Test("IS-148 Shrikhande against rook(4): never distinguished")
    func is148() {
        // `U: shrikhande` → `U: rook(4)`; `weisfeilerLehmanGraphHash(iterations: 3)` ⇒ equal
        let patternEdges: [[Int]] = [
            [0, 1], [0, 3], [0, 4], [0, 5], [0, 12], [0, 15], [1, 2], [1, 5], [1, 6], [1, 12], [1, 13], [2, 3],
            [2, 6], [2, 7], [2, 13], [2, 14], [3, 4], [3, 7], [3, 14], [3, 15], [4, 5], [4, 7], [4, 8], [4, 9],
            [5, 6], [5, 9], [5, 10], [6, 7], [6, 10], [6, 11], [7, 8], [7, 11], [8, 9], [8, 11], [8, 12], [8, 13],
            [9, 10], [9, 13], [9, 14], [10, 11], [10, 14], [10, 15], [11, 12], [11, 15], [12, 13], [12, 15], [13, 14], [14, 15]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 8], [0, 12], [1, 2], [1, 3], [1, 5], [1, 9], [1, 13], [2, 3],
            [2, 6], [2, 10], [2, 14], [3, 7], [3, 11], [3, 15], [4, 5], [4, 6], [4, 7], [4, 8], [4, 12], [5, 6],
            [5, 7], [5, 9], [5, 13], [6, 7], [6, 10], [6, 14], [7, 11], [7, 15], [8, 9], [8, 10], [8, 11], [8, 12],
            [9, 10], [9, 11], [9, 13], [10, 11], [10, 14], [11, 15], [12, 13], [12, 14], [12, 15], [13, 14], [13, 15], [14, 15]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 3)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 3)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 3) == patternHash)
        // iterations defaults to 3.
        #expect(pattern.weisfeilerLehmanGraphHash() == patternHash && target.weisfeilerLehmanGraphHash() == targetHash)
    }

    @Test("IS-149 CFI against twisted CFI: never distinguished")
    func is149() {
        // `U: cfi(K(4))` → `U: cfi~(K(4))`; `weisfeilerLehmanGraphHash(iterations: 5)` ⇒ equal
        let patternEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 14], [5, 15], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 15], [5, 14], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 5)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 5)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 5) == patternHash)
    }

    @Test("IS-150 isomorphic graphs: equal")
    func is150() {
        // `U: nx(petersen)` → `U: nx(petersen) ~map(3,4)`; `weisfeilerLehmanGraphHash(iterations: 3)` ⇒ equal
        let patternEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [4, 7], [4, 6], [4, 9], [7, 0], [7, 2], [0, 3], [0, 5], [3, 6], [3, 8], [6, 1], [9, 5], [9, 8],
            [2, 8], [2, 1], [5, 1]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 3)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 3)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 3) == patternHash)
        // iterations defaults to 3.
        #expect(pattern.weisfeilerLehmanGraphHash() == patternHash && target.weisfeilerLehmanGraphHash() == targetHash)
    }

    @Test("IS-151 P4 against the star: degrees differ in round 1")
    func is151() {
        // `U: P(0,1,2,3)` → `U: S(0;1..3)`; `weisfeilerLehmanGraphHash(iterations: 1)` ⇒ different
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 1)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 1)
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 1) == patternHash)
    }

    @Test("IS-152 zero rounds: only the vertex count")
    func is152() {
        // `U: P(0,1,2,3)` → `U: S(0;1..3)`; `weisfeilerLehmanGraphHash(iterations: 0)` ⇒ equal
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 0)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 0)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 0) == patternHash)
    }

    @Test("IS-153 zero rounds, different vertex counts")
    func is153() {
        // `U: E(3)` → `U: E(4)`; `weisfeilerLehmanGraphHash(iterations: 0)` ⇒ different
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3))
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4))
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 0)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 0)
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 0) == patternHash)
    }

    @Test("IS-154 two trees, one degree sequence: equal after 1 round")
    func is154() {
        // `U: P(0,1,2,3,4), 1-5` → `U: P(0,1,2,3,4), 2-5`; `weisfeilerLehmanGraphHash(iterations: 1)` ⇒ equal
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(1, 5)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(2, 5)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 1)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 1)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 1) == patternHash)
    }

    @Test("IS-155 two trees, one degree sequence: different after 2")
    func is155() {
        // `U: P(0,1,2,3,4), 1-5` → `U: P(0,1,2,3,4), 2-5`; `weisfeilerLehmanGraphHash(iterations: 2)` ⇒ different
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(1, 5)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(2, 5)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 2)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 2)
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 2) == patternHash)
    }

    @Test("IS-156 decalin against bicyclopentyl (NetworkX docstring)")
    func is156() {
        // `U: P(0,1,2,3,4,5,6,7,8,9), 0-5, 4-9` → `U: C(0,1,2,3,4), C(5,6,7,8,9), 0-5`; `weisfeilerLehmanGraphHash(iterations: 3)` ⇒ equal
        let patternEdges: [[Int]] = [
            [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9], [0, 5], [4, 9]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [5, 6], [6, 7], [7, 8], [8, 9], [9, 5], [0, 5]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 3)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 3)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 3) == patternHash)
        // iterations defaults to 3.
        #expect(pattern.weisfeilerLehmanGraphHash() == patternHash && target.weisfeilerLehmanGraphHash() == targetHash)
    }

    @Test("IS-157 decalin against bicyclopentyl with element colours")
    func is157() {
        // `U: P(0,1,2,3,4,5,6,7,8,9), 0-5, 4-9` → `U: C(0,1,2,3,4), C(5,6,7,8,9), 0-5`; `weisfeilerLehmanGraphHash(iterations: 3) edgeColor: G [s,s,s,s,s,s,s,s,s,d,s] H [s,s,s,s,s,s,s,s,s,s,d]` ⇒ different
        let patternEdges: [[Int]] = [
            [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9], [0, 5], [4, 9]
        ]
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: patternEdges.map { UndirectedEdge($0[0], $0[1]) })
        let targetEdges: [[Int]] = [
            [0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [5, 6], [6, 7], [7, 8], [8, 9], [9, 5], [0, 5]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        let patternEdgeColor = ["s", "s", "s", "s", "s", "s", "s", "s", "s", "d", "s"]
        let targetEdgeColor = ["s", "s", "s", "s", "s", "s", "s", "s", "s", "s", "d"]
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 3, vertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] })
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 3, vertexColor: { _ in 0 }, edgeColor: { targetEdgeColor[$0] })
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 3, vertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }) == patternHash)
    }

    @Test("IS-158 vertex colours separate C4 colourings")
    func is158() {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `weisfeilerLehmanGraphHash(iterations: 2) vertexColor: G [r,r,b,b] H [r,b,r,b]` ⇒ different
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternColor: [Int: String] = [0: "r", 1: "r", 2: "b", 3: "b"]
        let targetColor: [Int: String] = [0: "r", 1: "b", 2: "r", 3: "b"]
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 2, vertexColor: { patternColor[$0]! })
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 2, vertexColor: { targetColor[$0]! })
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 2, vertexColor: { patternColor[$0]! }) == patternHash)
    }

    @Test("IS-159 edge colours separate C4 colourings")
    func is159() {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `weisfeilerLehmanGraphHash(iterations: 2) edgeColor: G [a,a,b,b] H [a,b,a,b]` ⇒ different
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternEdgeColor = ["a", "a", "b", "b"]
        let targetEdgeColor = ["a", "b", "a", "b"]
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 2, vertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] })
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 2, vertexColor: { _ in 0 }, edgeColor: { targetEdgeColor[$0] })
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 2, vertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] }) == patternHash)
    }

    @Test("IS-160 parallel pair against P4: degrees equal, neighbours not")
    func is160() {
        // `U: 0=1, 2-3` → `U: P(0,1,2,3)`; `weisfeilerLehmanGraphHash(iterations: 2)` ⇒ different
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 2)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 2)
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 2) == patternHash)
    }

    @Test("IS-161 a loop counts as two edge ends")
    func is161() {
        // `U: 0-0, 1-2` → `U: P(0,1,2)`; `weisfeilerLehmanGraphHash(iterations: 1)` ⇒ equal
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 1)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 1)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 1) == patternHash)
    }

    @Test("IS-162 a loop: degrees equal, neighbours not")
    func is162() {
        // `U: 0-0, 1-2` → `U: P(0,1,2)`; `weisfeilerLehmanGraphHash(iterations: 2)` ⇒ different
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 0), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 2)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 2)
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 2) == patternHash)
    }

    @Test("IS-163 directed: out-path against in-star")
    func is163() {
        // `D: 0>1, 1>2` → `D: 0>1, 2>1`; `weisfeilerLehmanGraphHash(iterations: 1)` ⇒ different
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 1)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 1)
        #expect(patternHash != targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 1) == patternHash)
    }

    @Test("IS-164 directed: C3 against its reverse")
    func is164() {
        // `D: C(0,1,2)` → `D: C(2,1,0)`; `weisfeilerLehmanGraphHash(iterations: 3)` ⇒ equal
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: [2, 1, 0], edges: [DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 2)])
        let patternHash = pattern.weisfeilerLehmanGraphHash(iterations: 3)
        let targetHash = target.weisfeilerLehmanGraphHash(iterations: 3)
        #expect(patternHash == targetHash)
        // Equal inputs hash alike within the process.
        #expect(pattern.weisfeilerLehmanGraphHash(iterations: 3) == patternHash)
        // iterations defaults to 3.
        #expect(pattern.weisfeilerLehmanGraphHash() == patternHash && target.weisfeilerLehmanGraphHash() == targetHash)
    }

    @Test("IS-166 P5 partitions")
    func is166() {
        // `U: P(0,1,2,3,4)`; `weisfeilerLehmanSubgraphHashes(iterations: 3)` ⇒ r1: {0,4} {1,2,3}; r2: {0,4} {1,3} {2}; r3: {0,4} {1,3} {2}
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 3)
        #expect(hashes.iterations == 3)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 3 })
        #expect((0 ..< 5).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 3 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0, 4], [1, 2, 3]], [[0, 4], [1, 3], [2]], [[0, 4], [1, 3], [2]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 3)
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-167 tree partitions")
    func is167() {
        // `U: P(0,1,2,3,4), 1-5`; `weisfeilerLehmanSubgraphHashes(iterations: 3)` ⇒ r1: {0,4,5} {1} {2,3}; r2: {0,5} {1} {2} {3} {4}; r3: {0,5} {1} {2} {3} {4}
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(1, 5)])
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 3)
        #expect(hashes.iterations == 3)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 3 })
        #expect((0 ..< 6).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 3 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0, 4, 5], [1], [2, 3]], [[0, 5], [1], [2], [3], [4]], [[0, 5], [1], [2], [3], [4]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 3)
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-168 Petersen: one class from round 1 on")
    func is168() {
        // `U: nx(petersen)`; `weisfeilerLehmanSubgraphHashes(iterations: 2)` ⇒ r1: {0,1,2,3,4,5,6,7,8,9}; r2: {0,1,2,3,4,5,6,7,8,9}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 2)
        #expect(hashes.iterations == 2)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 2 })
        #expect((0 ..< 10).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 2 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]], [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 2)
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-169 Frucht: refinement stops short of the orbits")
    func is169() {
        // `U: nx(frucht)`; `weisfeilerLehmanSubgraphHashes(iterations: 4)` ⇒ r1: {0,1,2,3,4,5,6,7,8,9,10,11}; r2: {0,1,2,3,4,5,6,7,8,9,10,11}; r3: {0,1,2,3,4,5,6,7,8,9,10,11}; r4: {0,1,2,3,4,5,6,7,8,9,10,11}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 6], [0, 7], [1, 2], [1, 7], [2, 3], [2, 8], [3, 4], [3, 9], [4, 5], [4, 9], [5, 6],
            [5, 10], [6, 10], [7, 11], [8, 11], [8, 9], [10, 11]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 4)
        #expect(hashes.iterations == 4)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 4 })
        #expect((0 ..< 12).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 4 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]], [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]], [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]], [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 4)
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-170 karate club, three rounds")
    func is170() {
        // `U: nx(karate_club)`; `weisfeilerLehmanSubgraphHashes(iterations: 3)` ⇒ r1: {0} {1} {2} {3,31} {4,10,19,24,25,28} {5,6,7,27,29,30} {8,13,23} {9,12,14,15,16,17,18,20,21,22,26} {11} {32} {33}; r2: {0} {1} {2} {3} {4,10} {5,6} {7} {8} {9} {11} {12} {13} {14,15,18,20,22} {16} {17,21} {19} {23} {24} {25} {26} {27} {28} {29} {30} {31} {32} {33}; r3: {0} {1} {2} {3} {4,10} {5,6} {7} {8} {9} {11} {12} {13} {14,15,18,20,22} {16} {17,21} {19} {23} {24} {25} {26} {27} {28} {29} {30} {31} {32} {33}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 10], [0, 11], [0, 12], [0, 13],
            [0, 17], [0, 19], [0, 21], [0, 31], [1, 2], [1, 3], [1, 7], [1, 13], [1, 17], [1, 19], [1, 21], [1, 30],
            [2, 3], [2, 7], [2, 8], [2, 9], [2, 13], [2, 27], [2, 28], [2, 32], [3, 7], [3, 12], [3, 13], [4, 6],
            [4, 10], [5, 6], [5, 10], [5, 16], [6, 16], [8, 30], [8, 32], [8, 33], [9, 33], [13, 33], [14, 32], [14, 33],
            [15, 32], [15, 33], [18, 32], [18, 33], [19, 33], [20, 32], [20, 33], [22, 32], [22, 33], [23, 25], [23, 27], [23, 29],
            [23, 32], [23, 33], [24, 25], [24, 27], [24, 31], [25, 31], [26, 29], [26, 33], [27, 33], [28, 31], [28, 33], [29, 32],
            [29, 33], [30, 32], [30, 33], [31, 32], [31, 33], [32, 33]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 34), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 3)
        #expect(hashes.iterations == 3)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 3 })
        #expect((0 ..< 34).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 3 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0], [1], [2], [3, 31], [4, 10, 19, 24, 25, 28], [5, 6, 7, 27, 29, 30], [8, 13, 23], [9, 12, 14, 15, 16, 17, 18, 20, 21, 22, 26], [11], [32], [33]], [[0], [1], [2], [3], [4, 10], [5, 6], [7], [8], [9], [11], [12], [13], [14, 15, 18, 20, 22], [16], [17, 21], [19], [23], [24], [25], [26], [27], [28], [29], [30], [31], [32], [33]], [[0], [1], [2], [3], [4, 10], [5, 6], [7], [8], [9], [11], [12], [13], [14, 15, 18, 20, 22], [16], [17, 21], [19], [23], [24], [25], [26], [27], [28], [29], [30], [31], [32], [33]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 3)
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-171 vertex colours start the refinement")
    func is171() {
        // `U: P(0,1,2,3,4)`; `weisfeilerLehmanSubgraphHashes(iterations: 2) vertexColor: G [a,b,a,a,a]` ⇒ r1: {0} {1} {2} {3} {4}; r2: {0} {1} {2} {3} {4}
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let patternColor: [Int: String] = [0: "a", 1: "b", 2: "a", 3: "a", 4: "a"]
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 2, vertexColor: { patternColor[$0]! })
        #expect(hashes.iterations == 2)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 2 })
        #expect((0 ..< 5).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 2 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0], [1], [2], [3], [4]], [[0], [1], [2], [3], [4]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 2, vertexColor: { patternColor[$0]! })
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-172 edge colours")
    func is172() {
        // `U: C(0,1,2,3)`; `weisfeilerLehmanSubgraphHashes(iterations: 2) edgeColor: G [a,a,b,b]` ⇒ r1: {0,2} {1} {3}; r2: {0,2} {1} {3}
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternEdgeColor = ["a", "a", "b", "b"]
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 2, vertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] })
        #expect(hashes.iterations == 2)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 2 })
        #expect((0 ..< 4).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 2 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0, 2], [1], [3]], [[0, 2], [1], [3]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 2, vertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] })
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-173 directed: in- and out-neighbours both count")
    func is173() {
        // `D: 0>1, 2>1, 1>3`; `weisfeilerLehmanSubgraphHashes(iterations: 2)` ⇒ r1: {0,2} {1} {3}; r2: {0,2} {1} {3}
        let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 2, to: 1), DirectedEdge(from: 1, to: 3)])
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 2)
        #expect(hashes.iterations == 2)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 2 })
        #expect((0 ..< 4).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 2 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0, 2], [1], [3]], [[0, 2], [1], [3]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 2)
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-174 loops and parallel edges")
    func is174() {
        // `U: 0-0, 0-1, 1=2, 2-3`; `weisfeilerLehmanSubgraphHashes(iterations: 2)` ⇒ r1: {0,1,2} {3}; r2: {0,1} {2} {3}
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 2)
        #expect(hashes.iterations == 2)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 2 })
        #expect((0 ..< 4).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
        // Each round's classes of equal hashes, each class in `vertices` order, classes by first vertex.
        let rounds = graph.vertices.map { Array(hashes.hashes(of: $0)) }
        var partitions: [[[Int]]] = []
        for round in 0 ..< 2 {
            var classes: [Int: [Int]] = [:]
            var order: [Int] = []
            for (vertex, hash) in zip(graph.vertices, rounds.map { $0[round] }) {
                if classes[hash] == nil { order.append(hash) }
                classes[hash, default: []].append(vertex)
            }
            partitions.append(order.map { classes[$0]! })
        }
        #expect(partitions == [[[0, 1, 2], [3]], [[0, 1], [2], [3]]])
        // Equal inputs hash alike within the process.
        let again = graph.weisfeilerLehmanSubgraphHashes(iterations: 2)
        #expect(graph.vertices.allSatisfy { Array(again.hashes(of: $0)) == Array(hashes.hashes(of: $0)) })
    }

    @Test("IS-175 zero rounds: no hashes")
    func is175() {
        // `U: P(0,1,2)`; `weisfeilerLehmanSubgraphHashes(iterations: 0)` ⇒ (no rounds)
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let hashes = graph.weisfeilerLehmanSubgraphHashes(iterations: 0)
        #expect(hashes.iterations == 0)
        #expect(graph.vertices.allSatisfy { hashes.hashes(of: $0).count == 0 })
        #expect((0 ..< 3).allSatisfy { Array(hashes.hashes(ofIndex: $0)) == Array(hashes.hashes(of: graph.vertex(atIndex: $0))) })
    }
}
