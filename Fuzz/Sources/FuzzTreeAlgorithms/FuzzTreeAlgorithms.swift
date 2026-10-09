// TreeAlgorithms against brute force, on random trees of up to 200 vertices (so the range-minimum
// blocks of 64 are crossed), from a parent array, rooted at a chosen vertex: the precomputed
// lowest common ancestors, distances and the heavy–light decomposition's ancestors agree with
// climbing for every pair; the segments expand to the path; the Euler tour is a closed walk
// crossing each edge twice in preorder; center, centroid and diameter agree with a search from
// every vertex; the centroid decomposition has the centroid of each part at its top and height at
// most ⌊log₂ n⌋.

import FuzzSupport
import GraphProtocols
import TreeAlgorithms
import Trees
import Walks

@main
enum FuzzTreeAlgorithms {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 200)
        // Vertex i > 0 hangs from a vertex below it, chosen by the input (a path when it runs out).
        let parents: [Int?] = (0 ..< n).map { i in i == 0 ? nil : (input.isEmpty ? i - 1 : input.int(below: i)) }
        guard let base = RootedTree(parents: parents) else { check(false, "parents"); return }
        let tree = Tree(base)
        let root = input.isEmpty ? 0 : input.int(below: n)
        let rooted = RootedTree(tree, root: root)

        // Brute-force distances from every vertex, over the tree's own rows.
        var distance = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            distance[s][s] = 0
            var queue = [s], head = 0
            while head < queue.count {
                let x = queue[head]
                head += 1
                for y in tree.neighbors(of: x) where distance[s][y] < 0 {
                    distance[s][y] = distance[s][x] + 1
                    queue.append(y)
                }
            }
        }

        let lca = LowestCommonAncestors(rooted)
        let hld = HeavyLightDecomposition(rooted)
        for a in 0 ..< n {
            for b in 0 ..< n {
                let climbed = rooted.lowestCommonAncestor(of: a, b)
                // The deepest vertex on the root path of both.
                let up = [a] + Array(rooted.ancestors(of: a))
                let expected = up.first { $0 == b || rooted.isAncestor($0, of: b) }!
                check(climbed == expected, "lowestCommonAncestor(\(a), \(b)) = \(climbed), expected \(expected)")
                check(lca.lowestCommonAncestor(of: a, b) == expected, "LowestCommonAncestors(\(a), \(b))")
                check(hld.lowestCommonAncestor(of: a, b) == expected, "HLD lowestCommonAncestor(\(a), \(b))")
                check(lca.distance(from: a, to: b) == distance[a][b], "distance(\(a), \(b))")
                let path = rooted.path(from: a, to: b).vertices
                for including in [true, false] {
                    let segments = hld.segments(from: a, to: b, includingCommonAncestor: including)
                    var expanded: [Int] = []
                    for segment in segments {
                        check(!segment.positions.isEmpty && (segment.positions.count > 1 || !segment.isReversed), "segment \(segment)")
                        let range = Array(segment.positions)
                        expanded += segment.isReversed ? range.reversed() : range
                    }
                    let want = including ? path : path.filter { $0 != expected }
                    check(expanded.map { hld.preorder[$0] } == want, "segments(\(a), \(b), including: \(including))")
                    check(segments.count <= 2 * (Int.bitWidth - 1 - n.leadingZeroBitCount) + 1, "too many segments")
                }
            }
            // Heavy child: a largest child, the first on a tie; positions and subtrees.
            let children = Array(rooted.children(of: a))
            let sizes = children.map { rooted.descendants(of: $0).count + 1 }
            let heavy = sizes.indices.max { sizes[$0] < sizes[$1] || (sizes[$0] == sizes[$1] && $0 > $1) }.map { children[$0] }
            check(hld.heavyChild(of: a) == heavy, "heavyChild(of: \(a))")
            let subtree = hld.subtree(of: a)
            check(Set(subtree.map { hld.preorder[$0] }) == Set([a] + Array(rooted.descendants(of: a))), "subtree(of: \(a))")
            check(hld.position(of: a) == subtree.lowerBound && hld.preorder[hld.position(of: a)] == a, "position(of: \(a))")
        }

        let tour = rooted.eulerTour
        check(tour.count == 2 * n - 1 && tour.source == root && tour.target == root, "Euler tour length")
        check(Walk(vertices: tour.vertices, edges: tour.edges, in: rooted) != nil, "Euler tour is not a walk")
        var firstSeen: [Int] = []
        var seen = Set<Int>()
        for v in tour where seen.insert(v).inserted { firstSeen.append(v) }
        check(firstSeen == Array(rooted.preorder), "Euler tour order")
        check(Dictionary(grouping: tour.edges, by: { $0 }).values.allSatisfy { $0.count == 2 }, "each edge twice")

        let eccentricity = (0 ..< n).map { distance[$0].max()! }
        let least = eccentricity.min()!, greatest = eccentricity.max()!
        check(tree.center() == (0 ..< n).filter { eccentricity[$0] == least }, "center \(tree.center())")
        check(tree.diameter() == greatest, "diameter")
        let u = eccentricity.firstIndex(of: greatest)!
        let v = distance[u].firstIndex(of: greatest)!
        let diameterPath = tree.diameterPath()
        check(diameterPath.source == u && diameterPath.target == v && diameterPath.length == greatest, "diameterPath \(diameterPath)")
        // Weighted with weight 2 per edge: everything doubles, the center is the same.
        check(tree.diameter { _ in 2 } == 2 * greatest && tree.center { _ in 2 } == tree.center(), "weighted")

        // Centroid: the largest component left by removing c.
        func largestPart(_ c: Int, in members: Set<Int>) -> Int {
            var best = 0
            var left = members.subtracting([c])
            while let s = left.first {
                var stack = [s], size = 0
                left.remove(s)
                while let x = stack.popLast() {
                    size += 1
                    for y in tree.neighbors(of: x) where left.contains(y) {
                        left.remove(y)
                        stack.append(y)
                    }
                }
                best = max(best, size)
            }
            return best
        }
        let all = Set(0 ..< n)
        check(tree.centroid() == (0 ..< n).filter { 2 * largestPart($0, in: all) <= n }, "centroid \(tree.centroid())")
        let decomposition = tree.centroidDecomposition()
        check(decomposition.height <= Int.bitWidth - 1 - n.leadingZeroBitCount, "decomposition height \(decomposition.height)")
        for c in 0 ..< n {
            let part = Set([c] + Array(decomposition.descendants(of: c)))
            let centroids = part.sorted().filter { 2 * largestPart($0, in: part) <= part.count }
            check(centroids.first == c, "the top of \(part.sorted()) is \(c), its first centroid is \(String(describing: centroids.first))")
        }
    }
}
