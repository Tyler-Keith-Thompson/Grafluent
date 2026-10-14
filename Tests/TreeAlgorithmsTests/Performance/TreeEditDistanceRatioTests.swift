// Zhang–Shasha on OrderedTree, through its generic cost closures, against the same dynamic
// program written by hand over Int arrays at unit costs. In a release build the library must stay
// within 1.3× of the hand-written loop; a debug build checks only that the answers agree.

import GrafluentTestSupport
import Testing
import TreeAlgorithms
import Trees

@Suite("Tree edit distance against a hand-written loop")
struct TreeEditDistanceRatioTests {
    @Test("treeEditDistance(to:) on two random 400-vertex ordered trees runs within 1.3× of hand-written Zhang–Shasha", .timeLimit(.minutes(1)))
    func againstHandWritten() async {
        await Task {
            let n = 400
            var rng = SeededRandomNumberGenerator(seed: 11)
            // Random recursive trees: vertex i > 0 hangs from a vertex below it; children in
            // increasing order.
            var parents: [[Int]] = []
            for _ in 0 ..< 2 { parents.append((0 ..< n).map { $0 == 0 ? -1 : Int.random(in: 0 ..< $0, using: &rng) }) }
            var children = [[[Int]]](repeating: [[Int]](repeating: [], count: n), count: 2)
            for t in 0 ..< 2 { for v in 1 ..< n { children[t][parents[t][v]].append(v) } }
            let a = OrderedTree(root: 0) { children[0][$0] }!
            let b = OrderedTree(root: 0) { children[1][$0] }!

            // Postorder, leftmost leaves and keyroots by hand.
            var leftmost = [[Int]](repeating: [], count: 2), keyroots = [[Int]](repeating: [], count: 2)
            for t in 0 ..< 2 {
                var post = [Int](repeating: 0, count: n), size = [Int](repeating: 1, count: n)
                for v in stride(from: n - 1, through: 1, by: -1) { size[parents[t][v]] += size[v] }
                var order: [Int] = [], stack: [(Int, Int)] = [(0, 0)]
                while let (v, k) = stack.last {
                    if k < children[t][v].count {
                        stack[stack.count - 1].1 += 1
                        stack.append((children[t][v][k], 0))
                    } else {
                        post[v] = order.count
                        order.append(v)
                        stack.removeLast()
                    }
                }
                var left = [Int](repeating: 0, count: n)
                for v in 0 ..< n { left[post[v]] = post[v] - size[v] + 1 }
                leftmost[t] = left
                keyroots[t] = (0 ..< n).filter { p in
                    let v = order[p]
                    return v == 0 || left[post[parents[t][v]]] != left[p]
                }
            }
            let la = leftmost[0], lb = leftmost[1], ka = keyroots[0], kb = keyroots[1]
            func handWritten() -> Int {
                let stride = n + 1
                var td = [Int](repeating: 0, count: n * n), fd = [Int](repeating: 0, count: (n + 1) * stride)
                for i in ka {
                    let li = la[i], rows = i - li + 1
                    for j in kb {
                        let lj = lb[j], columns = j - lj + 1
                        fd[0] = 0
                        for x in 1 ... rows { fd[x * stride] = x }
                        for y in 1 ... columns { fd[y] = y }
                        for x in 1 ... rows {
                            let p = li + x - 1, row = x * stride
                            for y in 1 ... columns {
                                let q = lj + y - 1
                                var best = min(fd[row - stride + y], fd[row + y - 1]) + 1
                                if la[p] == li && lb[q] == lj {
                                    best = min(best, fd[row - stride + y - 1])
                                    td[p * n + q] = best
                                } else {
                                    best = min(best, fd[(la[p] - li) * stride + lb[q] - lj] + td[p * n + q])
                                }
                                fd[row + y] = best
                            }
                        }
                    }
                }
                return td[n * n - 1]
            }
            let expected = handWritten()
            #expect(a.treeEditDistance(to: b) == expected)
            #expect(a.treeEditDistance(to: a) == 0)

            #if !DEBUG
            // The two sides alternate, so a burst of other work slows both; each keeps its fastest round.
            let clock = ContinuousClock()
            var result = Double.infinity
            var sink = 0
            for _ in 0 ..< 3 where result > 1.1 {
                var library = Duration.seconds(1_000), baseline = Duration.seconds(1_000)
                for _ in 0 ..< 5 {
                    library = min(library, clock.measure { sink &+= a.treeEditDistance(to: b) })
                    baseline = min(baseline, clock.measure { sink &+= handWritten() })
                }
                result = min(result, library / baseline)
            }
            #expect(sink != 1)
            #expect(result < 1.3, "treeEditDistance took \(result)× the hand-written loop")
            #endif
        }.value
    }
}
