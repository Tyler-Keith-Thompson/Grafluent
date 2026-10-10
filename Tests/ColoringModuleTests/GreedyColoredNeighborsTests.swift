// `greedyColoring(strategy: .coloredNeighbors)`: igraph's `IGRAPH_COLORING_GREEDY_COLORED_NEIGHBORS`
// (python-igraph `vertex_coloring_greedy(method="colored_neighbors")`). Each row's colours are
// python-igraph 1.0's; each test also checks properness, the classes, at most Δ + 1 colours, the
// first-fit property, at least `chromaticNumber()` colours, and igraph's procedure written out:
// the vertex of greatest degree first (the least index on ties), then the top of igraph's two-way
// indexed max-heap (`igraph_2wheap_t`) of the uncoloured vertices keyed by coloured neighbours,
// pushed in index order and raised neighbour by neighbour in ascending order, each vertex coloured
// by first fit. That heap moves an entry above an equal parent going up and to the left child
// unless the right one is strictly greater going down, so its ties are not by index. A multigraph
// means its simple graph (igraph would count each parallel edge). See README.md.

import AdjacencyListModule
import ColoringModule
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing

@Suite("greedyColoring(strategy: .coloredNeighbors)")
struct GreedyColoredNeighborsTests {
    @Test("the empty graph: python-igraph's colours []")
    func theEmptyGraph() {
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 0, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("one vertex: python-igraph's colours [0]")
    func oneVertex() {
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("three isolated vertices: python-igraph's colours [0, 0, 0]")
    func threeIsolatedVertices() {
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0, 0, 0])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("a triangle with a pendant: python-igraph's colours [1, 2, 0, 1]")
    func aTriangleWithAPendant() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [1, 2, 0, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("the path P5: python-igraph's colours [1, 0, 1, 0, 1]")
    func thePathP5() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [1, 0, 1, 0, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("K4: python-igraph's colours [0, 3, 2, 1]")
    func K4() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0, 3, 2, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("the star K1,4: python-igraph's colours [0, 1, 1, 1, 1]")
    func theStarK14() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 1, 1, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("the cycle C6: python-igraph's colours [0, 1, 0, 1, 0, 1]")
    func theCycleC6() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("the wheel W6 (hub 0): python-igraph's colours [0, 3, 2, 1, 2, 1]")
    func theWheelW6Hub0() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0, 3, 2, 1, 2, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("the 3 × 3 grid: python-igraph's colours [0, 1, 0, 1, 0, 1, 0, 1, 0]")
    func the33Grid() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 3), (1, 2), (1, 4), (2, 5), (3, 4), (3, 6), (4, 5), (4, 7), (5, 8), (6, 7), (7, 8)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 9, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0, 1, 0, 1, 0, 1, 0, 1, 0])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("a triangle beside a path: python-igraph's colours [0, 2, 1, 1, 0, 1]")
    func aTriangleBesideAPath() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0, 2, 1, 1, 0, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("Petersen (NetworkX's numbering): python-igraph's colours [0, 2, 0, 2, 1, 1, 1, 2, 0, 0]")
    func PetersenNetworkxSNumbering() {
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [0, 2, 0, 2, 1, 1, 1, 2, 0, 0])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("ties that igraph's heap breaks away from the least index: python-igraph's colours [2, 1, 0, 0, 0, 1]")
    func tiesThatIgraphSHeapBreaksAwayFromTheLeas() {
        let pairs: [(Int, Int)] = [(0, 4), (0, 5), (1, 3), (1, 4), (2, 5), (4, 5)]
        let graph = UndirectedAdjacencyList<Int>(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [2, 1, 0, 0, 0, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("a triangle with a pendant, a doubled edge and a self-loop (multigraph): the simple graph's colours: python-igraph's colours [1, 2, 0, 1]")
    func aTriangleWithAPendantADoubledEdgeAndASel() {
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (1, 0), (2, 2)]
        let graph = ReferencePseudograph<Int>(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let n = graph.vertexCount
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        let colors = (0 ..< n).map { coloring.color(of: $0) }
        #expect(colors == [1, 2, 0, 1])
        #expect(coloring.colors == colors)
        #expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)
        // The simple graph: each vertex's distinct other neighbours.
        var adjacent = [[Int]](repeating: [], count: n)
        for (a, b) in pairs where a != b {
            if !adjacent[a].contains(b) { adjacent[a].append(b) }
            if !adjacent[b].contains(a) { adjacent[b].append(a) }
        }
        // Proper, every colour used, classes in `vertices` order, at most Δ + 1, first fit, at least χ.
        for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(a)–\(b)") }
        #expect(graph.isVertexColoring { coloring.color(of: $0) })
        #expect(Set(colors) == Set(0 ..< coloring.colorCount))
        #expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in (0 ..< n).filter { colors[$0] == c } })
        #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1)
        for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(v)") }
        #expect(coloring.colorCount >= graph.chromaticNumber())
        // igraph's procedure written out, with its heap: data, the item at each place, each item's
        // place + 2 (0 when out).
        var expected = [Int](repeating: -1, count: n)
        if n > 0 {
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
        }
        #expect(colors == expected)
    }

    @Test("Vertices numbered by position in `vertices`: Petersen with vertex v labelled \"p\\(v)\" on ReferencePseudograph gets python-igraph's colours by position")
    func labels() {
        let pairs = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = ReferencePseudograph<String>(vertices: (0 ..< 10).map { "p\($0)" }, edges: pairs.map { UndirectedEdge("p\($0.0)", "p\($0.1)") })
        let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
        #expect((0 ..< 10).map { coloring.color(of: "p\($0)") } == [0, 2, 0, 2, 1, 1, 1, 2, 0, 0])
        #expect(coloring.colors == [0, 2, 0, 2, 1, 1, 1, 2, 0, 0])
    }

    @Test("On random simple graphs: igraph's procedure written out, proper, first fit, at most Δ + 1", .tags(.randomized))
    func againstProcedure() async {
        let edges = zip(Gen.int(in: 0 ... 11), Gen.int(in: 0 ... 11)).array(of: 0 ... 40)
        await propertyCheck(count: 300, input: edges, Gen.int(in: 1 ... 12)) { raw, n in
            let pairs = raw.map { ($0.0 % n, $0.1 % n) }
            let graph = ReferencePseudograph<Int>(vertices: 0 ..< n, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
            let coloring = graph.greedyColoring(strategy: .coloredNeighbors)
            let colors = (0 ..< n).map { coloring.color(of: $0) }
            var adjacent = [[Int]](repeating: [], count: n)
            for (a, b) in pairs where a != b {
                if !adjacent[a].contains(b) { adjacent[a].append(b) }
                if !adjacent[b].contains(a) { adjacent[b].append(a) }
            }
            for (a, b) in pairs where a != b { #expect(colors[a] != colors[b], "\(pairs)") }
            #expect(coloring.colorCount <= (adjacent.map(\.count).max() ?? 0) + 1, "\(pairs)")
            for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), "\(pairs)") }
            var expected = [Int](repeating: -1, count: n)
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
            let top = adjacent.map(\.count).max()!
            var vertex = (0 ..< n).first { adjacent[$0].count == top }!
            for v in 0 ..< n where v != vertex {
                data.append(0)
                item.append(v)
                place[v] = data.count + 1
                up(data.count - 1)
            }
            while true {
                var c = 0
                while adjacent[vertex].contains(where: { expected[$0] == c }) { c += 1 }
                expected[vertex] = c
                for w in adjacent[vertex].sorted() where place[w] != 0 {
                    let p = place[w] - 2
                    data[p] += 1
                    down(p)
                    up(p)
                }
                if data.isEmpty { break }
                vertex = item[0]
                exchange(0, data.count - 1)
                data.removeLast()
                item.removeLast()
                place[vertex] = 0
                down(0)
            }
            #expect(colors == expected, "\(pairs)")
        }
    }
}
