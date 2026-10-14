import Benchmark
import BenchmarkSupport
import LinkCutTreeModule

/// LC-B01: 10⁶ random operations on 10⁵ vertices: links of a random root under a random vertex of
/// another tree, cuts, path minima, path subtractions and rerootings, in a fixed mix.
/// LC-B02: a path of 10⁵ vertices linked in order, then 10⁶ path minima from random vertices.
let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let n = 100_000
    var generator = SeededRandomNumberGenerator(seed: 3)
    let script = (0 ..< 1_000_000).map { _ in (Int.random(in: 0 ..< 5, using: &generator), Int.random(in: 0 ..< n, using: &generator), Int.random(in: 0 ..< n, using: &generator)) }
    Benchmark("LinkCutTree: 10⁶ mixed operations on 10⁵ vertices") { benchmark in
        for _ in benchmark.scaledIterations {
            var forest = LinkCutTree<Int>(count: n, cost: 1_000_000)
            var sum = 0
            for (op, a, b) in script {
                switch op {
                case 0, 1:
                    let r = forest.root(of: a)
                    if forest.root(of: b) != r { forest.link(r, to: b) }
                case 2:
                    if forest.parent(of: a) != nil { forest.cut(a) }
                case 3:
                    sum &+= forest.pathMinimum(from: a).cost
                    forest.subtractCost(1, fromPathFrom: a)
                default:
                    forest.makeRoot(a)
                }
            }
            blackHole(sum)
        }
    }
    let queries = (0 ..< 1_000_000).map { _ in Int.random(in: 0 ..< n, using: &generator) }
    Benchmark("LinkCutTree: path of 10⁵ linked in order, 10⁶ path minima") { benchmark in
        for _ in benchmark.scaledIterations {
            var forest = LinkCutTree<Int>(count: n, cost: 0)
            for v in 1 ..< n {
                forest.setCost(of: v, to: (v &* 7919) % n)
                forest.link(v, to: v - 1)
            }
            var sum = 0
            for v in queries { sum &+= forest.pathMinimum(from: v).vertex }
            blackHole(sum)
        }
    }
}
