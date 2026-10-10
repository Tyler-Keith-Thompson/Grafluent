// Colouring against definitions and brute force, on multigraphs of at most 9 vertices with
// self-loops and parallel edges, with vertex labels in a shuffled order, with and without vertex
// indices: every greedy strategy equals first fit in its order with least-index ties (each order
// computed here from its definition), is proper and within Δ + 1 colours (smallest last within
// degeneracy + 1); first fit in a given order equals the model; the chromatic number is the least k
// with a proper k-colouring, at most every greedy count; the minimum colouring is, per component,
// the first restricted-growth vector in `vertices` order with that component's χ colours;
// Misra–Gries on the simple graph is proper with Δ or Δ + 1 colours; König's colouring exists
// exactly on bipartite graphs and uses exactly Δ colours, parallel edges counted; and
// `isColoring` and `isEdgeColoring` agree with the definitions on arbitrary colourings.

import AdjacencyListModule
import ColoringModule
import FuzzSupport
import GraphProtocols

/// An undirected multigraph with no vertex indices.
struct PlainGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

@main
enum FuzzColoring {
    static func main() { runFuzzer(fuzz) }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 0 ... 9)
        // Labels 0..<n listed in a shuffled order: vertex index i is labels[i].
        var labels = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { labels.swapAt(i, input.int(below: i + 1)) }
        let m = n == 0 ? 0 : input.int(below: 25)
        // Ends as indices; a few choices give self-loops and repeats.
        let ends = (0 ..< m).map { _ in (input.int(below: max(n, 1)), input.int(below: max(n, 1))) }
        let edges = ends.map { UndirectedEdge(labels[$0.0], labels[$0.1]) }
        let given = (0 ..< n).map { _ in input.int(below: 4) }
        let givenEdges = (0 ..< m).map { _ in input.int(below: 5) - 1 }
        var order = Array(0 ..< n)
        for i in stride(from: n - 1, to: 0, by: -1) { order.swapAt(i, input.int(below: i + 1)) }

        // The simple graph by index, each row in first-appearance order of the edges at a vertex
        // (incidentEdges order, both representations).
        var rows = [[Int]](repeating: [], count: n)
        for (a, b) in ends where a != b {
            if !rows[a].contains(b) { rows[a].append(b) }
            if !rows[b].contains(a) { rows[b].append(a) }
        }
        let adjacency = rows.map(Set.init)
        let degree = rows.map(\.count)
        let delta = degree.max() ?? 0
        func proper(_ colors: [Int]) -> Bool { ends.allSatisfy { $0.0 == $0.1 || colors[$0.0] != colors[$0.1] } }
        func firstFit(_ order: [Int]) -> [Int] {
            var colors = [Int](repeating: -1, count: n)
            for v in order {
                var c = 0
                while rows[v].contains(where: { colors[$0] == c }) { c += 1 }
                colors[v] = c
            }
            return colors
        }
        func count(_ colors: [Int]) -> Int { (colors.max() ?? -1) + 1 }

        // The orders, from their definitions with least-index ties.
        let largestFirst = (0 ..< n).sorted { (-degree[$0], $0) < (-degree[$1], $1) }
        var removal: [Int] = [], left = Set(0 ..< n)
        var degeneracy = 0
        while let v = left.min(by: { (adjacency[$0].intersection(left).count, $0) < (adjacency[$1].intersection(left).count, $1) }) {
            degeneracy = max(degeneracy, adjacency[v].intersection(left).count)
            removal.append(v)
            left.remove(v)
        }
        var dsatur = [Int](repeating: -1, count: n)
        for _ in 0 ..< n {
            let v = (0 ..< n).filter { dsatur[$0] < 0 }.max { a, b in
                let sa = Set(rows[a].map { dsatur[$0] }.filter { $0 >= 0 }).count, sb = Set(rows[b].map { dsatur[$0] }.filter { $0 >= 0 }).count
                return (sa, degree[a], -a) < (sb, degree[b], -b)
            }!
            var c = 0
            while rows[v].contains(where: { dsatur[$0] == c }) { c += 1 }
            dsatur[v] = c
        }
        var independentSet: [Int] = [], remaining = Set(0 ..< n)
        while !remaining.isEmpty {
            var available = remaining
            while let v = available.min(by: { (adjacency[$0].intersection(available).count, $0) < (adjacency[$1].intersection(available).count, $1) }) {
                independentSet.append(v)
                remaining.remove(v)
                available.subtract(adjacency[v].union([v]))
            }
        }
        func connected(depthFirst: Bool) -> [Int] {
            var seen = [Bool](repeating: false, count: n), out: [Int] = []
            func visit(_ v: Int) {
                seen[v] = true
                out.append(v)
                for w in rows[v] where !seen[w] { visit(w) }
            }
            for root in 0 ..< n where !seen[root] {
                if depthFirst {
                    visit(root)
                } else {
                    seen[root] = true
                    var queue = [root], head = 0
                    while head < queue.count {
                        let v = queue[head]
                        head += 1
                        out.append(v)
                        for w in rows[v] where !seen[w] {
                            seen[w] = true
                            queue.append(w)
                        }
                    }
                }
            }
            return out
        }
        let expected: [ColoringStrategy: [Int]] = [
            .largestFirst: firstFit(largestFirst), .smallestLast: firstFit(removal.reversed()),
            .saturationLargestFirst: dsatur, .independentSet: firstFit(independentSet),
            .connectedSequentialBreadthFirst: firstFit(connected(depthFirst: false)),
            .connectedSequentialDepthFirst: firstFit(connected(depthFirst: true)),
        ]

        // χ and the least optimal colouring per component, by restricted-growth backtracking.
        var component = [Int](repeating: -1, count: n)
        for root in 0 ..< n where component[root] < 0 {
            var stack = [root]
            component[root] = root
            while let v = stack.popLast() {
                for w in rows[v] where component[w] < 0 {
                    component[w] = root
                    stack.append(w)
                }
            }
        }
        var least = [Int](repeating: 0, count: n), chi = 0
        for root in Set(component) {
            let members = (0 ..< n).filter { component[$0] == root }
            var colors = [Int](repeating: -1, count: n)
            func search(_ i: Int, _ k: Int, _ high: Int) -> Bool {
                if i == members.count { return true }
                let v = members[i]
                for c in 0 ..< min(k, high + 2) where !rows[v].contains(where: { colors[$0] == c }) {
                    colors[v] = c
                    if search(i + 1, k, max(high, c)) { return true }
                    colors[v] = -1
                }
                return false
            }
            var k = 1
            while !search(0, k, -1) { k += 1 }
            chi = max(chi, k)
            for v in members { least[v] = colors[v] }
        }

        // Bipartiteness of the multigraph (a self-loop makes it not bipartite).
        let bipartite = (0 ..< (1 << n)).contains { mask in ends.allSatisfy { (mask >> $0.0 & 1) != (mask >> $0.1 & 1) } }
        func properEdges(_ colors: [Int], _ ends: [(Int, Int)]) -> Bool {
            for i in ends.indices {
                for j in ends.indices where j > i && colors[i] == colors[j] {
                    let (a, b) = ends[i], (c, d) = ends[j]
                    if a == c || a == d || b == c || b == d { return false }
                }
            }
            return true
        }
        // The simple graph by index: first appearance, loops dropped.
        var simpleEnds: [(Int, Int)] = []
        for (a, b) in ends where a != b && !simpleEnds.contains(where: { ($0 == a && $1 == b) || ($0 == b && $1 == a) }) { simpleEnds.append((a, b)) }

        func run<G: Graph<Int>>(_ graph: G, _ name: String) {
            let by: (Int) -> Int = { labels[$0] }
            func colors(_ coloring: Coloring<G>) -> [Int] {
                let colors = (0 ..< n).map { coloring.color(of: labels[$0]) }
                let classes = coloring.colorClasses
                check((0 ..< n).allSatisfy { coloring.color(ofIndex: $0) == colors[$0] }, "\(name): color(ofIndex:) disagrees with color(of:)")
                check(classes.count == coloring.colorCount && classes.allSatisfy { !$0.isEmpty }
                      && classes.enumerated().allSatisfy { c, members in members.allSatisfy { coloring.color(of: $0) == c } }
                      && classes.flatMap { $0 } .count == n
                      && classes.allSatisfy { $0.elementsEqual($0.sorted { labels.firstIndex(of: $0)! < labels.firstIndex(of: $1)! }) },
                      "\(name): colour classes \(classes) disagree with the colours")
                check(graph.isColoring { coloring.color(of: $0) }, "\(name): isColoring rejects a result")
                return colors
            }
            for strategy in ColoringStrategy.allCases {
                let got = colors(graph.greedyColoring(strategy: strategy))
                check(got == expected[strategy]!, "\(name) \(strategy): \(got), expected \(expected[strategy]!) on \(ends)")
                check(proper(got) && count(got) <= delta + 1, "\(name) \(strategy): \(got) is not proper within Δ + 1")
                check(count(got) >= chi, "\(name) \(strategy): \(count(got)) colours, below χ = \(chi)")
            }
            check(count(expected[.smallestLast]!) <= degeneracy + 1, "smallest last above degeneracy + 1")
            check(graph.greedyColoring() == graph.greedyColoring(strategy: .largestFirst), "\(name): the default is not largest first")
            let ordered = colors(graph.greedyColoring(order: order.map(by)))
            check(ordered == firstFit(order), "\(name) greedyColoring(order: \(order)): \(ordered), expected \(firstFit(order))")
            check(graph.chromaticNumber() == chi, "\(name): chromaticNumber \(graph.chromaticNumber()), expected \(chi) on \(ends)")
            let minimum = graph.minimumColoring()
            check(minimum.colorCount == chi, "\(name): minimumColoring has \(minimum.colorCount) colours, χ = \(chi)")
            let got = colors(minimum)
            check(got == least, "\(name): minimumColoring \(got), expected \(least) on \(ends)")

            // isColoring and isEdgeColoring on arbitrary colourings.
            check(graph.isColoring { given[labels.firstIndex(of: $0)!] } == proper(given), "\(name): isColoring of \(given) on \(ends)")
            let positions = Array(graph.edges.indices)
            let positionEnds = positions.map { p in (labels.firstIndex(of: graph.edges[p].u)!, labels.firstIndex(of: graph.edges[p].v)!) }
            var givenAt: [G.Edges.Index: Int] = [:]
            for (i, p) in positions.enumerated() { givenAt[p] = givenEdges[i] }
            check(graph.isEdgeColoring { givenAt[$0]! } == properEdges(givenEdges, positionEnds), "\(name): isEdgeColoring of \(givenEdges) on \(positionEnds)")

            // UndirectedAdjacencyList keeps one copy of a repeated pair.
            let multiDelta = (0 ..< n).map { v in positionEnds.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0
            let konig = graph.bipartiteEdgeColoring()
            check((konig != nil) == bipartite, "\(name): bipartiteEdgeColoring is \(konig == nil ? "nil" : "a colouring"), bipartite \(bipartite) on \(ends)")
            if let konig {
                let colors = positions.map { konig.color(ofEdgeAt: $0) }
                check(konig.colorCount == multiDelta && properEdges(colors, positionEnds) && Set(colors) == Set(0 ..< multiDelta),
                      "\(name): König \(colors) with \(konig.colorCount) colours, Δ = \(multiDelta), on \(positionEnds)")
                check(graph.isEdgeColoring { konig.color(ofEdgeAt: $0) }, "\(name): isEdgeColoring rejects König's colouring")
                check(konig.colorClasses.enumerated().allSatisfy { c, members in members.allSatisfy { konig.color(ofEdgeAt: $0) == c } }
                      && konig.colorClasses.reduce(0) { $0 + $1.count } == positions.count, "\(name): König's colour classes disagree")
            }
        }

        let simpleEdges = simpleEnds.map { UndirectedEdge(labels[$0.0], labels[$0.1]) }
        func runEdges<G: Graph<Int>>(_ graph: G, _ name: String) {
            let coloring = graph.edgeColoring()
            let positions = Array(graph.edges.indices)
            let positionEnds = positions.map { p in (labels.firstIndex(of: graph.edges[p].u)!, labels.firstIndex(of: graph.edges[p].v)!) }
            let colors = positions.map { coloring.color(ofEdgeAt: $0) }
            let k = coloring.colorCount
            check(properEdges(colors, positionEnds) && Set(colors) == Set(0 ..< k), "\(name): Misra–Gries \(colors) is not proper on \(positionEnds)")
            check(simpleEnds.isEmpty ? k == 0 : (delta ... delta + 1).contains(k), "\(name): Misra–Gries uses \(k) colours, Δ = \(delta)")
            check(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) }, "\(name): isEdgeColoring rejects Misra–Gries")
            check(coloring.colorClasses.enumerated().allSatisfy { c, members in members.allSatisfy { coloring.color(ofEdgeAt: $0) == c } }
                  && coloring.colorClasses.reduce(0) { $0 + $1.count } == simpleEnds.count, "\(name): Misra–Gries's colour classes disagree")
        }

        run(PlainGraph(vertices: labels, edges: edges), "plain")
        run(UndirectedAdjacencyList(vertices: labels, edges: edges), "adjacency list")
        runEdges(PlainGraph(vertices: labels, edges: simpleEdges), "plain")
        runEdges(UndirectedAdjacencyList(vertices: labels, edges: simpleEdges), "adjacency list")
    }
}
