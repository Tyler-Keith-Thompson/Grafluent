// LinkCutTree against a forest kept as a parent array, with costs in a plain array. Each input is
// a vertex count and a sequence of operations: link (a root under a vertex of another tree), cut,
// makeRoot, add or subtract a cost along a root path, set a cost, and the queries. After each one
// every vertex's root, parent and cost, and the path minimum from one vertex, must match the
// model; a copy taken earlier must still match the model as it was.

import FuzzSupport
import LinkCutTreeModule

@main
enum FuzzLinkCutTree {
    static func main() { runFuzzer(fuzz) }

    static func rootPath(_ parent: [Int], _ v: Int) -> [Int] {
        var path = [v]
        while parent[path.last!] >= 0 { path.append(parent[path.last!]) }
        return path
    }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 24)
        var forest = LinkCutTree<Int>(count: n, cost: 0)
        var parent = [Int](repeating: -1, count: n)
        var cost = [Int](repeating: 0, count: n)
        var snapshot: (forest: LinkCutTree<Int>, parent: [Int], cost: [Int])?

        while !input.isEmpty {
            let op = input.int(below: 8)
            let a = input.int(below: n), b = input.int(below: n)
            let c = input.int(in: -8 ... 8)
            switch op {
            case 0, 1:
                let r = rootPath(parent, a).last!
                guard rootPath(parent, b).last! != r else { break }
                forest.link(r, to: b)
                parent[r] = b
            case 2:
                guard parent[a] >= 0 else { break }
                forest.cut(a)
                parent[a] = -1
            case 3:
                forest.makeRoot(a)
                let path = rootPath(parent, a)
                for i in stride(from: path.count - 1, to: 0, by: -1) { parent[path[i]] = path[i - 1] }
                parent[a] = -1
            case 4:
                forest.addCost(c, toPathFrom: a)
                for v in rootPath(parent, a) { cost[v] += c }
            case 5:
                forest.subtractCost(c, fromPathFrom: a)
                for v in rootPath(parent, a) { cost[v] -= c }
            case 6:
                forest.setCost(of: a, to: c)
                cost[a] = c
            default:
                snapshot = (forest, parent, cost)
            }
            let path = rootPath(parent, a)
            let least = path.map { cost[$0] }.min()!
            let (vertex, value) = forest.pathMinimum(from: a)
            check(value == least && path.contains(vertex) && cost[vertex] == least, "pathMinimum(from: \(a)) gave \((vertex, value)), model \(parent) \(cost)")
            check(forest.inSameTree(a, b) == (path.last! == rootPath(parent, b).last!), "inSameTree(\(a), \(b))")
            for v in 0 ..< n {
                check(forest.root(of: v) == rootPath(parent, v).last!, "root(of: \(v)), model \(parent)")
                check(forest.parent(of: v) == (parent[v] < 0 ? nil : parent[v]), "parent(of: \(v)), model \(parent)")
                check(forest.cost(of: v) == cost[v], "cost(of: \(v)), model \(cost)")
            }
        }

        // Value semantics: the copy saw none of the later operations.
        if let (forest, parent, cost) = snapshot {
            var copy = forest
            for v in 0 ..< n {
                check(copy.root(of: v) == rootPath(parent, v).last!, "the snapshot's root(of: \(v))")
                check(copy.parent(of: v) == (parent[v] < 0 ? nil : parent[v]), "the snapshot's parent(of: \(v))")
                check(copy.cost(of: v) == cost[v], "the snapshot's cost(of: \(v))")
            }
        }
    }
}
