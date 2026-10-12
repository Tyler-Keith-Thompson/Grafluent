// cycleDecomposition() builds into arrays it never fills first. Building many decompositions in a
// row, with freed memory full of large values in between, checks that every value it reads was
// written by this build: a count that starts from whatever the allocator hands back would show up
// as a wrong depth. Hand-written; see README.md.

import FunctionalGraphs
import Testing

@Suite("FunctionalGraph decompositions built over reused memory")
struct FunctionalGraphRebuildTests {
    @Test("Repeated builds over dirtied memory give the same tails, roots and steps")
    func repeatedBuilds() {
        let n = 3000
        // A broom: a path 0 ← 1 ← … ← 1999 into the fixed point 0, then 1000 leaves on vertex 1000.
        let successors = (0 ..< n).map { v in v == 0 ? 0 : v < 2000 ? v - 1 : 1000 }
        for round in 0 ..< 40 {
            // Freed buffers of the sizes the build allocates, full of large values.
            for count in [n, n + 1, 2 * n, 3 * n, 4 * n] {
                let dirty = [Int32](repeating: Int32.max - Int32(round), count: count)
                #expect(dirty.count == count)
                let wide = [Int](repeating: Int.max - round, count: count)
                #expect(wide.count == count)
            }
            let decomposition = FunctionalGraph(successors: successors).cycleDecomposition()
            #expect(decomposition.cycles.map { Array($0) } == [[0]])
            for v in [1, 2, 999, 1000, 1001, 1999, 2000, 2500, 2999] {
                let tail = v < 2000 ? v : 1001
                #expect(decomposition.tailLength(of: v) == tail, "round \(round), vertex \(v)")
                #expect(decomposition.root(of: v) == 0)
                #expect(decomposition.successor(of: v, steps: 1) == successors[v], "round \(round), vertex \(v)")
                #expect(decomposition.successor(of: v, steps: tail - 1) == 1, "round \(round), vertex \(v)")
            }
            #expect(decomposition.successor(of: 2999, steps: 2) == 999)
            #expect(decomposition.successor(of: 1999, steps: 1000) == 999)
        }
    }
}
