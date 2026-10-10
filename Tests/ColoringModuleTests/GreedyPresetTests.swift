// `greedyColoring(strategy:presetColor:)`: rustworkx `graph_greedy_color(preset_color_fn=)`. Rows
// with `.largestFirst` have rustworkx 0.18.1's colours (`ColoringStrategy.Degree`, which orders by
// whole-graph degree, leaves the preset vertices out and colours them first). The properties check,
// for every strategy on random multigraphs with random proper presets, that preset vertices keep
// their colours, the result is proper, every other vertex sees every colour below its own, and the
// strategy's rule with presets written out: the static orders of the whole graph with preset
// vertices skipped; DSatur with preset colours counted in saturation; the independent set's class k
// without the neighbours of the vertices preset to k; colored neighbours with preset neighbours
// counted and the first vertex from igraph's heap. Without presets the result is
// `greedyColoring(strategy:)`'s. See README.md.

import AdjacencyListModule
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("greedyColoring(strategy:presetColor:)")
struct GreedyPresetTests {
    @Test("P5 with vertex 2 preset to 0, largest first: rustworkx's [0, 1, 0, 1, 0]")
    func path() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let coloring = graph.greedyColoring(strategy: .largestFirst) { $0 == 2 ? 0 : nil }
        #expect(coloring.colors == [0, 1, 0, 1, 0])
        #expect(coloring.colorCount == 2)
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Without the preset, largest first gives [1, 0, 1, 0, 1] (CO-028).
        #expect(graph.greedyColoring(strategy: .largestFirst).colors == [1, 0, 1, 0, 1])
    }

    @Test("Petersen with 0 preset to 2 and 5 to 0, largest first: rustworkx's [2, 0, 1, 0, 1, 0, 1, 2, 2, 0]")
    func petersen() {
        let pairs = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let preset = [0: 2, 5: 0]
        let coloring = graph.greedyColoring(strategy: .largestFirst) { preset[$0] }
        #expect(coloring.colors == [2, 0, 1, 0, 1, 0, 1, 2, 2, 0])
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // Largest first written out: degree descending, the lesser index on ties, preset vertices
        // skipped, first fit against every coloured neighbour, the preset ones included.
        var adjacent = [[Int]](repeating: [], count: 10)
        for (a, b) in pairs {
            adjacent[a].append(b)
            adjacent[b].append(a)
        }
        var expected = (0 ..< 10).map { preset[$0] ?? -1 }
        for v in (0 ..< 10).sorted(by: { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }) where expected[v] < 0 {
            var c = 0
            while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }
            expected[v] = c
        }
        #expect(coloring.colors == expected)
    }

    @Test("A preset colour above the others leaves the colours between unused: a triangle with a pendant preset to 5 is rustworkx's [1, 2, 0, 5], six colours, three classes empty")
    func skippedColours() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(0, 2), UndirectedEdge(2, 3)])
        let coloring = graph.greedyColoring(strategy: .largestFirst) { $0 == 3 ? 5 : nil }
        #expect(coloring.colors == [1, 2, 0, 5])
        #expect(coloring.colorCount == 6)
        #expect(coloring.colorClasses.map { Array($0) } == [[2], [0], [1], [], [], [3]])
        #expect((0 ..< 4).map { coloring.color(ofIndex: $0) } == [1, 2, 0, 5])
    }

    @Test("Every vertex preset: the presets themselves, for every strategy (K4 preset to [3, 2, 1, 0], rustworkx's)")
    func everyVertexPreset() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        for strategy in ColoringStrategy.allCases {
            let coloring = graph.greedyColoring(strategy: strategy) { 3 - $0 }
            #expect(coloring.colors == [3, 2, 1, 0], "\(strategy)")
            #expect(coloring.colorClasses.map { Array($0) } == [[3], [2], [1], [0]], "\(strategy)")
        }
    }

    @Test("The star K1,4 with leaves 1 and 2 preset to 0 and 1, largest first: rustworkx's [2, 0, 1, 0, 0]")
    func star() {
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (1 ..< 5).map { UndirectedEdge(0, $0) })
        let preset = [1: 0, 2: 1]
        let coloring = graph.greedyColoring { preset[$0] }
        #expect(coloring.colors == [2, 0, 1, 0, 0])
    }

    @Test("presetColor is called once per vertex, in vertices order; on a ReferencePseudograph with string vertices the presets follow the vertex, not its position")
    func closureCalls() {
        let graph = ReferencePseudograph<String>(vertices: ["c", "a", "b", "d"], edges: [UndirectedEdge("a", "b"), UndirectedEdge("b", "c"), UndirectedEdge("c", "d"), UndirectedEdge("a", "a")])
        var asked: [String] = []
        let coloring = graph.greedyColoring(strategy: .saturationLargestFirst) { vertex in
            asked.append(vertex)
            return vertex == "b" ? 4 : nil
        }
        #expect(asked == ["c", "a", "b", "d"])
        #expect(coloring.color(of: "b") == 4)
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        // DSatur: c and a see colour 4 (saturation 1), c has the greater degree and takes 0; then a
        // (saturation 1) takes 0, d takes 1.
        #expect(coloring.colors == [0, 0, 4, 1])
    }

    @Test("No presets: the same colouring as greedyColoring(strategy:), for every strategy", .tags(.randomized))
    func nilPresets() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 26)
        await propertyCheck(count: 200, input: edges, Gen.int(in: 1 ... 10)) { raw, n in
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            for strategy in ColoringStrategy.allCases {
                let preset = graph.greedyColoring(strategy: strategy) { _ in nil }
                #expect(preset == graph.greedyColoring(strategy: strategy), "\(strategy) \(pairs)")
            }
        }
    }

    @Test("Every strategy with random proper presets: presets kept, proper, first fit elsewhere, and the strategy's rule written out", .tags(.randomized))
    func againstDefinitions() async {
        let edges = zip(Gen.int(in: 0 ... 9), Gen.int(in: 0 ... 9)).array(of: 0 ... 26)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 10), Gen.int(in: 0 ... 1_000_000)) { raw, n, seed in
            var rng = GrafluentTestSupport.SeededRandomNumberGenerator(seed: UInt(seed))
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let listed = Array(0 ..< n).shuffled(using: &rng)
            let graph = ReferencePseudograph<Int>(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1, $0) })
            var adjacent = [[Int]](repeating: [], count: n)
            for (x, y) in pairs where x != y {
                let a = index[x]!, b = index[y]!
                if !adjacent[a].contains(b) { adjacent[a].append(b) }
                if !adjacent[b].contains(a) { adjacent[b].append(a) }
            }
            // A random proper preset on about a third of the vertices, colours 0 … 5.
            var preset = [Int](repeating: -1, count: n)
            for v in 0 ..< n where Int.random(in: 0 ..< 3, using: &rng) == 0 {
                let c = Int.random(in: 0 ... 5, using: &rng)
                if !adjacent[v].contains(where: { preset[$0] == c }) { preset[v] = c }
            }
            let context = "\(pairs) on \(listed), preset \(preset)"
            func firstFit(_ order: [Int]) -> [Int] {
                var colour = preset
                for v in order where colour[v] < 0 {
                    var c = 0
                    while adjacent[v].contains(where: { colour[$0] == c }) { c += 1 }
                    colour[v] = c
                }
                return colour
            }
            var results: [ColoringStrategy: [Int]] = [:]
            for strategy in ColoringStrategy.allCases {
                let coloring = graph.greedyColoring(strategy: strategy) { preset[index[$0]!] >= 0 ? preset[index[$0]!] : nil }
                let colors = listed.map { coloring.color(of: $0) }
                results[strategy] = colors
                #expect(coloring.colors == colors, "\(strategy) \(context)")
                for v in 0 ..< n where preset[v] >= 0 { #expect(colors[v] == preset[v], "\(strategy) \(context)") }
                for v in 0 ..< n { for w in adjacent[v] { #expect(colors[v] != colors[w], "\(strategy) \(context)") } }
                for v in 0 ..< n where preset[v] < 0 {
                    #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(strategy) \(context)")
                }
                #expect(coloring.colorCount == (colors.max() ?? -1) + 1, "\(strategy) \(context)")
            }
            // Largest first and smallest last: the whole graph's orders, preset vertices skipped.
            let largestFirst = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }
            #expect(results[.largestFirst] == firstFit(largestFirst), "\(context)")
            var degree = adjacent.map(\.count)
            var removed = [Bool](repeating: false, count: n)
            var removal: [Int] = []
            for _ in 0 ..< n {
                let v = (0 ..< n).filter { !removed[$0] }.min { (degree[$0], $0) < (degree[$1], $1) }!
                removed[v] = true
                removal.append(v)
                for w in adjacent[v] where !removed[w] { degree[w] -= 1 }
            }
            #expect(results[.smallestLast] == firstFit(removal.reversed()), "\(context)")
            // Connected sequential, breadth first and depth first, rows in first-appearance order.
            var seen = [Bool](repeating: false, count: n)
            var breadthFirst: [Int] = []
            for root in 0 ..< n where !seen[root] {
                seen[root] = true
                var queue = [root]
                var head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    breadthFirst.append(v)
                    for w in adjacent[v] where !seen[w] {
                        seen[w] = true
                        queue.append(w)
                    }
                }
            }
            #expect(results[.connectedSequentialBreadthFirst] == firstFit(breadthFirst), "\(context)")
            seen = [Bool](repeating: false, count: n)
            var depthFirst: [Int] = []
            for root in 0 ..< n where !seen[root] {
                seen[root] = true
                depthFirst.append(root)
                var stack = [(root, 0)]
                while let (v, i) = stack.last {
                    if i == adjacent[v].count {
                        stack.removeLast()
                        continue
                    }
                    stack[stack.count - 1].1 += 1
                    let w = adjacent[v][i]
                    if !seen[w] {
                        seen[w] = true
                        depthFirst.append(w)
                        stack.append((w, 0))
                    }
                }
            }
            #expect(results[.connectedSequentialDepthFirst] == firstFit(depthFirst), "\(context)")
            // DSatur: preset colours count in saturation; then the most distinct neighbour colours,
            // the greatest whole-graph degree, the lesser index.
            var dsatur = preset
            while dsatur.contains(-1) {
                let key = { (v: Int) in (Set(adjacent[v].map { dsatur[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }
                let v = (0 ..< n).filter { dsatur[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!
                var c = 0
                while adjacent[v].contains(where: { dsatur[$0] == c }) { c += 1 }
                dsatur[v] = c
            }
            #expect(results[.saturationLargestFirst] == dsatur, "\(context)")
            // Independent set: class k from the uncoloured vertices with no neighbour preset to k, the
            // fewest available neighbours first.
            var independent = preset
            var k = 0
            while independent.contains(-1) {
                var available = Set((0 ..< n).filter { v in independent[v] < 0 && !adjacent[v].contains { preset[$0] == k } })
                while true {
                    let left = available
                    guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }
                    independent[v] = k
                    available.remove(v)
                    for w in adjacent[v] { available.remove(w) }
                }
                k += 1
            }
            #expect(results[.independentSet] == independent, "\(context)")
            // Colored neighbours: igraph's heap (written out in GreedyColoredNeighborsTests), the
            // uncoloured vertices pushed in index order with their preset neighbours counted; with
            // no preset the first vertex is the one of greatest degree, otherwise the heap's top.
            var expected = preset
            var data: [Int] = [], item: [Int] = [], place = [Int](repeating: 0, count: n)
            func exchange(_ a: Int, _ b: Int) {
                guard a != b else { return }
                data.swapAt(a, b)
                item.swapAt(a, b)
                place[item[a]] = a + 2
                place[item[b]] = b + 2
            }
            func up(_ start: Int) {
                var e = start
                while e > 0 && data[e] >= data[(e - 1) / 2] {
                    exchange(e, (e - 1) / 2)
                    e = (e - 1) / 2
                }
            }
            func down(_ start: Int) {
                var h = start
                while 2 * h + 1 < data.count {
                    let l = 2 * h + 1, r = l + 1
                    let child = r == data.count || data[l] >= data[r] ? l : r
                    guard data[h] < data[child] else { break }
                    exchange(h, child)
                    h = child
                }
            }
            func popTop() -> Int {
                let top = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[top] = 0
                down(0)
                return top
            }
            var vertex = -1
            if !preset.contains(where: { $0 >= 0 }) {
                let top = adjacent.map(\.count).max()!
                vertex = (0 ..< n).first { adjacent[$0].count == top }!
                for v in 0 ..< n where v != vertex {
                    data.append(0)
                    item.append(v)
                    place[v] = data.count + 1
                    up(data.count - 1)
                }
            } else {
                for v in 0 ..< n where preset[v] < 0 {
                    data.append(adjacent[v].filter { preset[$0] >= 0 }.count)
                    item.append(v)
                    place[v] = data.count + 1
                    up(data.count - 1)
                }
                if !data.isEmpty { vertex = popTop() }
            }
            while vertex >= 0 {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                vertex = data.isEmpty ? -1 : popTop()
            }
            #expect(results[.coloredNeighbors] == expected, "\(context)")
        }
    }
}
