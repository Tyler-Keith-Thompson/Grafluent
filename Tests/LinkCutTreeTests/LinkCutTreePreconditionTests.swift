// LinkCutTree preconditions, as exit tests: counts must not be negative, vertices must be in
// 0..<count, links must join a root to another tree, and only a non-root can be cut.

import GrafluentTestSupport
import LinkCutTreeModule
import Testing

@Suite("LinkCutTree preconditions")
struct LinkCutTreePreconditionTests {
    @Test("A negative count traps", .tags(.precondition))
    func negativeCount() async {
        await #expect(processExitsWith: .failure) {
            _ = LinkCutTree<Int>(count: -1, cost: 0)
        }
    }

    @Test("A vertex out of range traps", .tags(.precondition))
    func outOfRange() async {
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 2, cost: 0)
            _ = forest.root(of: 2)
        }
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 2, cost: 0)
            forest.link(0, to: -1)
        }
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 2, cost: 0)
            _ = forest.root(of: -1)
        }
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 2, cost: 0)
            forest.setCost(of: -1, to: 5)
        }
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 2, cost: 0)
            _ = forest.pathMinimum(from: Int.min)
        }
    }

    @Test("Linking a vertex that has a parent traps", .tags(.precondition))
    func linkNonRoot() async {
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 3, cost: 0)
            forest.link(1, to: 0)
            forest.link(1, to: 2)
        }
    }

    @Test("Linking within one tree traps", .tags(.precondition))
    func linkSameTree() async {
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 3, cost: 0)
            forest.link(1, to: 0)
            forest.link(0, to: 1)
        }
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 1, cost: 0)
            forest.link(0, to: 0)
        }
    }

    @Test("Cutting a root traps", .tags(.precondition))
    func cutRoot() async {
        await #expect(processExitsWith: .failure) {
            var forest = LinkCutTree<Int>(count: 3, cost: 0)
            forest.link(1, to: 0)
            forest.cut(0)
        }
    }
}
