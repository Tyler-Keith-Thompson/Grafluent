// LinkCutTree: hand-built forests, rerooting, path minimum and addition, preconditions as exit
// tests, and random operation sequences against a forest kept as a parent array.

import GrafluentTestSupport
import LinkCutTreeModule
import PropertyBased
import Testing

@Suite("LinkCutTree")
struct LinkCutTreeTests {
    @Test("An empty forest has no vertices")
    func empty() {
        let forest = LinkCutTree<Int>(count: 0, cost: 0)
        #expect(forest.count == 0)
    }

    @Test("Singletons are their own roots, with no parent and the initial cost")
    func singletons() {
        var forest = LinkCutTree<Int>(count: 3, cost: 7)
        #expect(forest.count == 3)
        for v in 0 ..< 3 {
            #expect(forest.root(of: v) == v)
            #expect(forest.parent(of: v) == nil)
            #expect(forest.cost(of: v) == 7)
            #expect(forest.pathMinimum(from: v) == (v, 7))
        }
        let zeroAndOne = forest.inSameTree(0, 1)
        #expect(!zeroAndOne)
        let twoAndTwo = forest.inSameTree(2, 2)
        #expect(twoAndTwo)
    }

    @Test("Linking a path and a branch: roots, parents and path minima")
    func linkAndQuery() {
        // 0 ← 1 ← 2 ← 3, and 4 ← 2: the root is 0.
        var forest = LinkCutTree<Int>(count: 6, cost: 0)
        for (v, c) in [5, 3, 8, 1, 4, 9].enumerated() { forest.setCost(of: v, to: c) }
        forest.link(1, to: 0)
        forest.link(2, to: 1)
        forest.link(3, to: 2)
        forest.link(4, to: 2)
        #expect((0 ..< 5).map { forest.root(of: $0) } == [0, 0, 0, 0, 0])
        #expect(forest.root(of: 5) == 5)
        #expect(forest.parent(of: 0) == nil)
        #expect(forest.parent(of: 1) == 0)
        #expect(forest.parent(of: 2) == 1)
        #expect(forest.parent(of: 3) == 2)
        #expect(forest.parent(of: 4) == 2)
        let threeAndFour = forest.inSameTree(3, 4)
        #expect(threeAndFour)
        let threeAndFive = forest.inSameTree(3, 5)
        #expect(!threeAndFive)
        #expect(forest.pathMinimum(from: 3) == (3, 1))
        #expect(forest.pathMinimum(from: 4) == (1, 3))
        #expect(forest.pathMinimum(from: 2) == (1, 3))
        #expect(forest.pathMinimum(from: 0) == (0, 5))
    }

    @Test("Adding along a path changes only that path's costs")
    func addCost() {
        var forest = LinkCutTree<Int>(count: 5, cost: 10)
        forest.link(1, to: 0)
        forest.link(2, to: 1)
        forest.link(3, to: 1)
        forest.addCost(-4, toPathFrom: 2)
        #expect((0 ..< 5).map { forest.cost(of: $0) } == [6, 6, 6, 10, 10])
        #expect(forest.pathMinimum(from: 3).cost == 6)
        forest.addCost(-1, toPathFrom: 3)
        #expect((0 ..< 5).map { forest.cost(of: $0) } == [5, 5, 6, 9, 10])
        #expect(forest.pathMinimum(from: 2).cost == 5)
        #expect([0, 1].contains(forest.pathMinimum(from: 2).vertex))
        #expect(forest.pathMinimum(from: 3).cost == 5)
        forest.setCost(of: 2, to: 1)
        #expect(forest.pathMinimum(from: 2) == (2, 1))
        #expect(forest.pathMinimum(from: 3).cost == 5)
    }

    @Test("Subtracting along a path works for unsigned costs down to zero")
    func subtractUnsigned() {
        var forest = LinkCutTree<UInt8>(count: 4, cost: 200)
        forest.link(1, to: 0)
        forest.link(2, to: 1)
        forest.setCost(of: 2, to: 30)
        forest.subtractCost(30, fromPathFrom: 2)
        #expect((0 ..< 4).map { forest.cost(of: $0) } == [170, 170, 0, 200])
        #expect(forest.pathMinimum(from: 2) == (2, 0))
        forest.addCost(50, toPathFrom: 1)
        #expect((0 ..< 4).map { forest.cost(of: $0) } == [220, 220, 0, 200])
        forest.setCost(of: 2, to: 5)
        forest.subtractCost(5, fromPathFrom: 2)
        #expect((0 ..< 4).map { forest.cost(of: $0) } == [215, 215, 0, 200])
        #expect(forest.pathMinimum(from: 1).cost == 215)
    }

    @Test("Cutting splits a tree; the cut-off part keeps its costs and shape")
    func cut() {
        var forest = LinkCutTree<Int>(count: 5, cost: 0)
        for (v, c) in [4, 2, 9, 1, 6].enumerated() { forest.setCost(of: v, to: c) }
        forest.link(1, to: 0)
        forest.link(2, to: 1)
        forest.link(3, to: 2)
        forest.link(4, to: 3)
        forest.cut(2)
        #expect(forest.parent(of: 2) == nil)
        #expect(forest.root(of: 4) == 2)
        #expect(forest.root(of: 1) == 0)
        let oneAndThree = forest.inSameTree(1, 3)
        #expect(!oneAndThree)
        #expect(forest.pathMinimum(from: 4) == (3, 1))
        #expect(forest.pathMinimum(from: 1) == (1, 2))
        forest.link(2, to: 0)
        #expect(forest.parent(of: 2) == 0)
        #expect(forest.root(of: 4) == 0)
        #expect(forest.pathMinimum(from: 4) == (3, 1))
    }

    @Test("makeRoot reverses the path to the old root and keeps the tree")
    func makeRoot() {
        // 0 ← 1 ← 2 ← 3, with 4 ← 1.
        var forest = LinkCutTree<Int>(count: 5, cost: 0)
        forest.link(1, to: 0)
        forest.link(2, to: 1)
        forest.link(3, to: 2)
        forest.link(4, to: 1)
        forest.makeRoot(3)
        #expect(forest.root(of: 0) == 3)
        #expect(forest.parent(of: 3) == nil)
        #expect(forest.parent(of: 2) == 3)
        #expect(forest.parent(of: 1) == 2)
        #expect(forest.parent(of: 0) == 1)
        #expect(forest.parent(of: 4) == 1)
        forest.makeRoot(3)
        #expect(forest.parent(of: 2) == 3)
        forest.makeRoot(4)
        #expect(forest.parent(of: 1) == 4)
        #expect(forest.parent(of: 2) == 1)
        #expect(forest.parent(of: 3) == 2)
        #expect(forest.parent(of: 0) == 1)
        // Unrooted use: makeRoot then link joins at any vertex.
        var other = LinkCutTree<Int>(count: 4, cost: 0)
        other.link(1, to: 0)
        other.link(3, to: 2)
        other.makeRoot(1)
        other.link(1, to: 3)
        #expect(other.root(of: 0) == 2)
        #expect(other.parent(of: 0) == 1)
        #expect(other.parent(of: 1) == 3)
    }

    @Test("Double costs; ties report a vertex of least cost on the path")
    func doubleCostsAndTies() {
        var forest = LinkCutTree<Double>(count: 4, cost: 0.5)
        forest.link(1, to: 0)
        forest.link(2, to: 1)
        forest.link(3, to: 2)
        let (vertex, cost) = forest.pathMinimum(from: 3)
        #expect(cost == 0.5)
        #expect((0 ..< 4).contains(vertex))
        forest.addCost(0.25, toPathFrom: 1)
        #expect(forest.pathMinimum(from: 3).cost == 0.5)
        #expect([2, 3].contains(forest.pathMinimum(from: 3).vertex))
        let top = forest.pathMinimum(from: 1)
        #expect(top.cost == 0.75 && [0, 1].contains(top.vertex))
    }

    @Test("A copy is independent of the original")
    func copyOnWrite() {
        var original = LinkCutTree<Int>(count: 3, cost: 1)
        original.link(1, to: 0)
        var copy = original
        copy.link(2, to: 1)
        copy.addCost(5, toPathFrom: 2)
        #expect(original.root(of: 2) == 2)
        #expect(original.cost(of: 0) == 1)
        #expect(copy.root(of: 2) == 0)
        #expect(copy.cost(of: 0) == 6)
    }

    @Test("A path of 10⁵ vertices linked one by one, queried from the deep end")
    func longPath() {
        let n = 100_000
        var forest = LinkCutTree<Int>(count: n, cost: 0)
        for v in 1 ..< n {
            forest.setCost(of: v, to: n - v)
            forest.link(v, to: v - 1)
        }
        #expect(forest.root(of: n - 1) == 0)
        #expect(forest.pathMinimum(from: n - 1) == (0, 0))
        forest.setCost(of: 0, to: n)
        #expect(forest.pathMinimum(from: n - 1) == (n - 1, 1))
        #expect(forest.pathMinimum(from: n / 2) == (n / 2, n - n / 2))
        forest.cut(n / 2)
        #expect(forest.root(of: n - 1) == n / 2)
        #expect(forest.root(of: n / 2 - 1) == 0)
    }

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

    @Test("Random operations agree with a forest kept as a parent array", .tags(.randomized))
    func againstParentArray() async {
        // Each step is an operation code and two vertex choices on 0..<10, plus a small cost.
        let steps = zip(Gen.int(in: 0 ... 7), Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9), Gen.int(in: -5 ... 5)).array(of: 0 ... 120)
        await propertyCheck(count: 300, input: steps) { steps in
            let n = 10
            var forest = LinkCutTree<Int>(count: n, cost: 0)
            var parent = [Int](repeating: -1, count: n)
            var cost = [Int](repeating: 0, count: n)
            func rootPath(_ v: Int) -> [Int] {
                var path = [v]
                while parent[path.last!] >= 0 { path.append(parent[path.last!]) }
                return path
            }
            for (k, (op, a, b, c)) in steps.enumerated() {
                switch op {
                case 0:
                    // Link a's root under b when they are in different trees.
                    let r = rootPath(a).last!
                    guard rootPath(b).last! != r else { break }
                    forest.link(r, to: b)
                    parent[r] = b
                case 1:
                    guard parent[a] >= 0 else { break }
                    forest.cut(a)
                    parent[a] = -1
                case 2:
                    forest.makeRoot(a)
                    let path = rootPath(a)
                    for i in stride(from: path.count - 1, to: 0, by: -1) { parent[path[i]] = path[i - 1] }
                    parent[a] = -1
                case 3:
                    forest.addCost(c, toPathFrom: a)
                    for v in rootPath(a) { cost[v] += c }
                case 4:
                    forest.setCost(of: a, to: c)
                    cost[a] = c
                case 7:
                    forest.subtractCost(c, fromPathFrom: a)
                    for v in rootPath(a) { cost[v] -= c }
                case 5:
                    let path = rootPath(a)
                    let least = path.map { cost[$0] }.min()!
                    let (vertex, value) = forest.pathMinimum(from: a)
                    #expect(value == least, "step \(k)")
                    #expect(path.contains(vertex) && cost[vertex] == least, "step \(k)")
                default:
                    let together = forest.inSameTree(a, b)
                    #expect(together == (rootPath(a).last! == rootPath(b).last!), "step \(k)")
                }
                let probe = (a + k) % n
                #expect(forest.root(of: probe) == rootPath(probe).last!, "step \(k)")
                #expect(forest.parent(of: probe) == (parent[probe] < 0 ? nil : parent[probe]), "step \(k)")
                #expect(forest.cost(of: probe) == cost[probe], "step \(k)")
            }
            for v in 0 ..< n {
                #expect(forest.root(of: v) == rootPath(v).last!)
                #expect(forest.parent(of: v) == (parent[v] < 0 ? nil : parent[v]))
                #expect(forest.cost(of: v) == cost[v])
                #expect(forest.pathMinimum(from: v).cost == rootPath(v).map { cost[$0] }.min()!)
            }
        }
    }
}
