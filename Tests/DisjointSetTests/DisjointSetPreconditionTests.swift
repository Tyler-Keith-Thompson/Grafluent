// Preconditions, as exit tests: every element argument must be in 0..<count, `union(x, x)`
// included, and counts and capacities must not be negative.
// Case IDs (DS-nn) refer to the catalog; see README.md.

import DisjointSetModule
import GrafluentTestSupport
import Testing

@Suite("DisjointSet preconditions", .tags(.precondition))
struct DisjointSetPreconditionTests {
    @Test("DS-37 find of an element out of range traps")
    func find() async {
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet(count: 8)
            _ = d.find(-1)
        }
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet(count: 8)
            _ = d.find(8)
        }
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet()
            _ = d.find(0)
        }
    }

    @Test("DS-37 union with an element out of range traps, even union(x, x)")
    func union() async {
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet(count: 8)
            d.union(0, 8)
        }
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet(count: 8)
            d.union(8, 0)
        }
        await #expect(processExitsWith: .failure) {
            // petgraph returns false here before checking the range.
            var d = DisjointSet(count: 8)
            d.union(8, 8)
        }
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet()
            d.union(0, 0)
        }
    }

    @Test("DS-37 inSameSet and setSize(of:) with an element out of range trap")
    func queries() async {
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet(count: 8)
            _ = d.inSameSet(0, 8)
        }
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet(count: 8)
            _ = d.inSameSet(-1, 0)
        }
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet(count: 8)
            _ = d.setSize(of: 8)
        }
    }

    @Test("DS-38 a negative count or capacity traps")
    func negativeCounts() async {
        await #expect(processExitsWith: .failure) {
            _ = DisjointSet(count: -1)
        }
        await #expect(processExitsWith: .failure) {
            var d = DisjointSet()
            d.reserveCapacity(-1)
        }
    }
}
