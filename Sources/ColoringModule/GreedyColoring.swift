import GraphProtocols

// MARK: - First fit and the strategies' orders (index space)

/// First fit in `order`: each vertex takes the least colour none of its coloured neighbours has,
/// found with a stamp per colour (`used[c] == v` while v is being coloured). Colours stay at most
/// Δ, so the stamp array has Δ + 1 entries. With `preset`, those vertices start coloured and are
/// skipped in `order` (and their colours above Δ need no stamp). O(n + m).
@inlinable
func _firstFit(_ rows: _ColoringRows, order: [Int], preset: [Int]? = nil) -> [Int] {
    let n = rows.count
    var colors = preset ?? [Int](repeating: -1, count: n)
    var used = [Int](repeating: -1, count: rows.maximumDegree + 1)
    for v in order where colors[v] < 0 {
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let c = colors[rows.neighbors[k]]
            if c >= 0 && c < used.count { used[c] = v }
        }
        var c = 0
        while used[c] == v { c += 1 }
        colors[v] = c
    }
    return colors
}

/// Degree descending, index ascending: a counting sort, stable in index order. O(n + Δ).
@inlinable
func _largestFirstOrder(_ rows: _ColoringRows) -> [Int] {
    let n = rows.count
    let top = rows.maximumDegree
    // starts[top - d] is where degree d begins.
    var starts = [Int](repeating: 0, count: top + 2)
    for v in 0 ..< n { starts[top - rows.degree(v) + 1] += 1 }
    for d in 0 ..< top + 1 { starts[d + 1] += starts[d] }
    var order = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        let slot = top - rows.degree(v)
        order[starts[slot]] = v
        starts[slot] += 1
    }
    return order
}

/// Matula–Beck's smallest-last order: the removal order (least degree in what is left, least
/// index on ties, through an indexed heap keyed by degree), reversed. O((n + m) log n).
@inlinable
func _smallestLastOrder(_ rows: _ColoringRows) -> [Int] {
    let n = rows.count
    var heap = _ColoringHeap(count: n)
    for v in 0 ..< n { heap.insert(v, UInt64(rows.degree(v))) }
    var order = [Int](repeating: 0, count: n)
    var slot = n
    while !heap.isEmpty {
        let v = heap.pop()
        slot -= 1
        order[slot] = v
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[k]
            if heap.contains(w) { heap.lower(w, heap.key[w] - 1) }
        }
    }
    return order
}

/// DSatur as NetworkX runs it: the uncoloured vertex with the most distinct neighbour colours,
/// then the greatest degree, then the least index, through an indexed heap keyed by the
/// complement of (saturation, degree), lowered when the saturation rises (it only rises). Each
/// vertex keeps a bitset of the colours 0...degree among its neighbours, which holds its own
/// least free colour; a neighbour colour above its degree goes in one shared hash set instead, at
/// most once per edge end. With `preset`, those vertices start coloured, their colours counted in
/// their neighbours' saturation. O((n + m) log n).
@inlinable
func _saturationColoring(_ rows: _ColoringRows, preset: [Int]? = nil) -> [Int] {
    let n = rows.count
    var colors = preset ?? [Int](repeating: -1, count: n)
    guard n > 0 else { return colors }
    var wordStart = [Int](repeating: 0, count: n + 1)
    for v in 0 ..< n { wordStart[v + 1] = wordStart[v] + (rows.degree(v) + 64) >> 6 }
    var seen = [UInt64](repeating: 0, count: wordStart[n])
    var saturation = [Int](repeating: 0, count: n)
    var high = Set<_VertexColor>()
    var heap = _ColoringHeap(count: n)
    // Colours vertices in `pending` (the presets first), then the heap's.
    var pending: [Int] = []
    if preset != nil { for v in 0 ..< n where colors[v] >= 0 { pending.append(v) } }
    for v in 0 ..< n where colors[v] < 0 { heap.insert(v, ~UInt64(rows.degree(v))) }
    var next = 0
    while next < pending.count || !heap.isEmpty {
        let v: Int, c: Int
        if next < pending.count {
            v = pending[next]
            next += 1
            c = colors[v]
        } else {
            v = heap.pop()
            // The least colour missing from v's bitset: at most its degree.
            var free = 0
            var word = wordStart[v]
            while ~seen[word] == 0 {
                word += 1
                free += 64
            }
            c = free + (~seen[word]).trailingZeroBitCount
            colors[v] = c
        }
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[k]
            if colors[w] >= 0 { continue }
            let dw = rows.degree(w)
            var fresh: Bool
            if c <= dw {
                let i = wordStart[w] + c >> 6, bit = UInt64(1) << UInt64(c & 63)
                fresh = seen[i] & bit == 0
                seen[i] |= bit
            } else {
                fresh = high.insert(_VertexColor(vertex: w, color: c)).inserted
            }
            if fresh {
                saturation[w] += 1
                heap.lower(w, ~(UInt64(saturation[w]) << 32 | UInt64(dw)))
            }
        }
    }
    return colors
}

/// NetworkX's independent-set strategy, with the least index on ties: class after class, each a
/// maximal independent set of the uncoloured vertices grown by least degree among the available
/// ones (an indexed heap keyed by that degree), the vertex taken and its neighbours made
/// unavailable, lowering their neighbours' degrees. With `preset`, those vertices start coloured,
/// and class k starts with the neighbours of the ones preset to k unavailable (rustworkx). After
/// each class the rows are cut down to the uncoloured vertices. Returns the colours directly:
/// each class's vertices get its number, which is what first fit in that order gives them.
@inlinable
func _independentSetColoring(_ rows: _ColoringRows, preset: [Int]? = nil) -> [Int] {
    let n = rows.count
    var colors = preset ?? [Int](repeating: -1, count: n)
    var available = [Bool](repeating: false, count: n)
    var remaining: [Int] = []
    for v in 0 ..< n where colors[v] < 0 { remaining.append(v) }
    // The preset vertices by colour.
    var presets: [Int] = []
    if preset != nil {
        for v in 0 ..< n where colors[v] >= 0 { presets.append(v) }
        presets.sort { colors[$0] < colors[$1] }
    }
    var nextPreset = 0
    // Rows of the uncoloured vertices among themselves: v's are adjacency[start[v] ..< end[v]].
    var start = [Int](repeating: 0, count: n), end = [Int](repeating: 0, count: n)
    var adjacency: [Int] = []
    var spare: [Int] = []
    for v in remaining {
        start[v] = adjacency.count
        for k in rows.offsets[v] ..< rows.offsets[v + 1] where colors[rows.neighbors[k]] < 0 { adjacency.append(rows.neighbors[k]) }
        end[v] = adjacency.count
    }
    var dropped: [Int] = []
    var heap = _ColoringHeap(count: n)
    var color = 0
    while !remaining.isEmpty {
        for v in remaining { available[v] = true }
        while nextPreset < presets.count && colors[presets[nextPreset]] <= color {
            let x = presets[nextPreset]
            if colors[x] == color {
                for k in rows.offsets[x] ..< rows.offsets[x + 1] { available[rows.neighbors[k]] = false }
            }
            nextPreset += 1
        }
        // The heap is empty again: the last class popped every vertex it held.
        for v in remaining where available[v] {
            var d = 0
            for k in start[v] ..< end[v] where available[adjacency[k]] { d += 1 }
            heap.insert(v, UInt64(d))
        }
        while !heap.isEmpty {
            let v = heap.pop()
            if !available[v] { continue }
            available[v] = false
            colors[v] = color
            dropped.removeAll(keepingCapacity: true)
            for k in start[v] ..< end[v] {
                let w = adjacency[k]
                if available[w] {
                    available[w] = false
                    dropped.append(w)
                }
            }
            for x in dropped {
                for k in start[x] ..< end[x] {
                    let y = adjacency[k]
                    if available[y] { heap.lower(y, heap.key[y] - 1) }
                }
            }
        }
        // Every vertex left was taken or made unavailable, so `available` is all false again.
        var kept = 0
        spare.removeAll(keepingCapacity: true)
        for v in remaining where colors[v] < 0 {
            remaining[kept] = v
            kept += 1
            let first = spare.count
            for k in start[v] ..< end[v] where colors[adjacency[k]] < 0 { spare.append(adjacency[k]) }
            start[v] = first
            end[v] = spare.count
        }
        swap(&adjacency, &spare)
        remaining.removeLast(remaining.count - kept)
        color += 1
    }
    return colors
}

/// igraph's colored-neighbours colouring, step for step: first the vertex of greatest degree
/// (the least index on ties), then repeatedly the one at the top of igraph's two-way indexed
/// max-heap (`igraph_2wheap_t`) of the uncoloured vertices keyed by their coloured neighbours,
/// pushed in index order and raised neighbour by neighbour in ascending order, each coloured by
/// first fit. That heap moves an entry above an equal parent on the way up and prefers the left
/// child on equal children on the way down, so its ties follow neither index nor age. With
/// `preset`, those vertices start coloured, the others are pushed with their counts of preset
/// neighbours, and the first vertex comes from the heap too.
@inlinable
func _coloredNeighborsColoring(_ rows: _ColoringRows, preset: [Int]? = nil) -> [Int] {
    let n = rows.count
    var colors = preset ?? [Int](repeating: -1, count: n)
    guard n > 0 else { return colors }
    // Rows in ascending order, as igraph_neighbors lists them.
    var sorted = [Int](repeating: 0, count: rows.neighbors.count)
    var fill = Array(rows.offsets.dropLast())
    for v in 0 ..< n {
        for k in rows.offsets[v] ..< rows.offsets[v + 1] {
            let w = rows.neighbors[k]
            sorted[fill[w]] = v
            fill[w] += 1
        }
    }
    var heap = _TwoWayHeap(count: n)
    var vertex = -1
    if preset == nil || !colors.contains(where: { $0 >= 0 }) {
        var best = 0
        for v in 1 ..< n where rows.degree(v) > rows.degree(best) { best = v }
        vertex = best
        for v in 0 ..< n where v != vertex { heap.push(v, 0) }
    } else {
        for v in 0 ..< n where colors[v] < 0 {
            var count = 0
            for k in rows.offsets[v] ..< rows.offsets[v + 1] where colors[rows.neighbors[k]] >= 0 { count += 1 }
            heap.push(v, count)
        }
        guard !heap.isEmpty else { return colors }
        vertex = heap.popMax()
    }
    var used = [Int](repeating: -1, count: rows.maximumDegree + 1)
    while true {
        for k in rows.offsets[vertex] ..< rows.offsets[vertex + 1] {
            let c = colors[rows.neighbors[k]]
            if c >= 0 && c < used.count { used[c] = vertex }
        }
        var c = 0
        while used[c] == vertex { c += 1 }
        colors[vertex] = c
        for k in rows.offsets[vertex] ..< rows.offsets[vertex + 1] {
            let w = sorted[k]
            if heap.contains(w) { heap.modify(w, heap.value(w) + 1) }
        }
        if heap.isEmpty { break }
        vertex = heap.popMax()
    }
    return colors
}

/// Components by least vertex, each searched from it in row order: breadth first, or depth first
/// in preorder (a stack of row cursors).
@inlinable
func _connectedSequentialOrder(_ rows: _ColoringRows, depthFirst: Bool) -> [Int] {
    let n = rows.count
    var seen = [Bool](repeating: false, count: n)
    var order: [Int] = []
    order.reserveCapacity(n)
    var stack: [Int] = [], cursor: [Int] = []
    for root in 0 ..< n where !seen[root] {
        seen[root] = true
        order.append(root)
        if depthFirst {
            stack.append(root)
            cursor.append(rows.offsets[root])
            while let v = stack.last {
                var k = cursor[cursor.count - 1]
                let end = rows.offsets[v + 1]
                while k < end, seen[rows.neighbors[k]] { k += 1 }
                if k == end {
                    stack.removeLast()
                    cursor.removeLast()
                    continue
                }
                cursor[cursor.count - 1] = k + 1
                let w = rows.neighbors[k]
                seen[w] = true
                order.append(w)
                stack.append(w)
                cursor.append(rows.offsets[w])
            }
        } else {
            var head = order.count - 1
            while head < order.count {
                let v = order[head]
                head += 1
                for k in rows.offsets[v] ..< rows.offsets[v + 1] where !seen[rows.neighbors[k]] {
                    seen[rows.neighbors[k]] = true
                    order.append(rows.neighbors[k])
                }
            }
        }
    }
    return order
}

/// The colours a strategy gives, by vertex number, from `preset` colours when given.
@inlinable
func _greedyColors(_ rows: _ColoringRows, _ strategy: ColoringStrategy, preset: [Int]? = nil) -> [Int] {
    switch strategy {
    case .largestFirst: return _firstFit(rows, order: _largestFirstOrder(rows), preset: preset)
    case .smallestLast: return _firstFit(rows, order: _smallestLastOrder(rows), preset: preset)
    case .saturationLargestFirst: return _saturationColoring(rows, preset: preset)
    case .independentSet: return _independentSetColoring(rows, preset: preset)
    case .connectedSequentialBreadthFirst: return _firstFit(rows, order: _connectedSequentialOrder(rows, depthFirst: false), preset: preset)
    case .connectedSequentialDepthFirst: return _firstFit(rows, order: _connectedSequentialOrder(rows, depthFirst: true), preset: preset)
    case .coloredNeighbors: return _coloredNeighborsColoring(rows, preset: preset)
    }
}

/// First fit in `order` straight over the graph's rows, uncopied: a self-loop or a parallel copy
/// only marks a colour again, so the rows need not be simple. Colours stay below the degree, so
/// the stamp array has n + 1 entries. O(n + m).
@frozen
@usableFromInline
struct _FirstFitRows: _UndirectedRowsAlgorithm {
    @usableFromInline let order: [Int]

    @inlinable
    init(order: [Int]) { self.order = order }

    @inlinable
    var readsEdges: Bool { false }

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> [Int] {
        var colors = [Int](repeating: -1, count: n)
        var used = [Int](repeating: -1, count: n + 1)
        for v in order {
            // `colors[w]` is checked, so a neighbour index out of range traps there.
            for k in 0 ..< rows.count(v) {
                let c = colors[rows.neighbor(v, k)]
                if c >= 0 { used[c] = v }
            }
            var c = 0
            while used[c] == v { c += 1 }
            colors[v] = c
        }
        return colors
    }
}

// MARK: - Entry points

extension Graph {
    /// A greedy colouring of the simple graph (self-loops ignored, parallel edges once): each
    /// vertex in the strategy's order takes the least colour none of its already coloured
    /// neighbours has. NetworkX `greedy_color(G, strategy)`, the same colours on simple graphs for
    /// `.largestFirst` and `.saturationLargestFirst`, and for the others wherever NetworkX's set
    /// iteration is ascending (NetworkX counts a self-loop in degrees, and its smallest last
    /// raises on one); igraph `vertex_coloring_greedy` for `.coloredNeighbors`; Boost
    /// `sequential_vertex_coloring` in the strategy's order; rustworkx `graph_greedy_color`.
    /// Colours are first-fit numbers, not renumbered: colour 0 goes to the first vertex coloured.
    /// At most Δ + 1 colours (`.smallestLast`: degeneracy + 1). O(n + m) for largest first and
    /// connected sequential, O((n + m) log n) for smallest last, DSatur and colored neighbours,
    /// O(χ (n + m) log n) for independent set.
    @inlinable
    public func greedyColoring(strategy: ColoringStrategy = .largestFirst) -> Coloring<Self> {
        let numbering = _vertexNumbering()
        let rows = _runOnUndirectedRows(_CopyColoringRows(), vertexNumbering: numbering)
        return Coloring(self, numbering: numbering, colors: _greedyColors(rows, strategy))
    }

    /// The greedy colouring with some colours fixed in advance (rustworkx
    /// `graph_greedy_color(preset_color_fn=)`): `presetColor` gives a vertex's colour, or nil to
    /// leave it to the strategy. Preset vertices keep their colours and count as coloured from the
    /// start; the others are coloured as by `greedyColoring(strategy:)`, each taking the least
    /// colour no coloured neighbour has. The orders of `.largestFirst`, `.smallestLast` and the
    /// connected sequential strategies are those of the whole graph with the preset vertices
    /// skipped (rustworkx's largest first: whole-graph degrees, preset vertices left out);
    /// DSatur counts preset colours in saturation from the start (rustworkx's saturation);
    /// `.independentSet`'s class k starts without the neighbours of the vertices preset to k
    /// (rustworkx's independent set); `.coloredNeighbors` counts preset neighbours as coloured and
    /// takes its first vertex from its heap. `colorCount` is one more than the greatest colour,
    /// so preset colours may leave some colours unused. `presetColor` is called once per vertex,
    /// in `vertices` order. The strategy's time, plus O(n + m) to check the presets.
    ///
    /// - Precondition: every preset colour is non-negative, and no two adjacent vertices have the
    ///   same preset colour.
    @inlinable
    public func greedyColoring(strategy: ColoringStrategy = .largestFirst, presetColor: (Vertex) -> Int?) -> Coloring<Self> {
        let numbering = _vertexNumbering()
        let rows = _runOnUndirectedRows(_CopyColoringRows(), vertexNumbering: numbering)
        var preset: [Int] = []
        preset.reserveCapacity(rows.count)
        for vertex in vertices {
            if let c = presetColor(vertex) {
                precondition(c >= 0, "The preset colour of \(vertex) is negative")
                preset.append(c)
            } else {
                preset.append(-1)
            }
        }
        for v in 0 ..< rows.count where preset[v] >= 0 {
            for k in rows.offsets[v] ..< rows.offsets[v + 1] {
                precondition(preset[rows.neighbors[k]] != preset[v], "Two adjacent vertices have the same preset colour")
            }
        }
        return Coloring(self, numbering: numbering, colors: _greedyColors(rows, strategy, preset: preset))
    }

    /// First fit in `order` on the simple graph: each vertex in turn takes the least colour none of
    /// its already coloured neighbours has (Boost `sequential_vertex_coloring(g, order, color)`,
    /// JGraphT `GreedyColoring`, NetworkX `greedy_color` with a callable strategy). A shuffled
    /// `vertices` is NetworkX's `random_sequential`. At most Δ + 1 colours. O(n + m) after one
    /// lookup per vertex.
    ///
    /// - Precondition: `order` lists every vertex of the graph exactly once.
    @inlinable
    public func greedyColoring(order: some Sequence<Vertex>) -> Coloring<Self> {
        let numbering = _vertexNumbering()
        let n = vertexIndexBound ?? vertexCount
        var seen = [Bool](repeating: false, count: n)
        var sequence: [Int] = []
        sequence.reserveCapacity(n)
        for vertex in order {
            let v: Int
            if let numbers = numbering?.numbers {
                guard let number = numbers[vertex] else { preconditionFailure("\(vertex) in the order is not a vertex of the graph") }
                v = number
            } else {
                // One hash: a non-vertex either traps in vertexIndex(of:) or gets another vertex's index.
                v = vertexIndex(of: vertex)
                precondition(v >= 0 && v < n && self.vertex(atIndex: v) == vertex, "\(vertex) in the order is not a vertex of the graph")
            }
            precondition(!seen[v], "\(vertex) appears twice in the order")
            seen[v] = true
            sequence.append(v)
        }
        precondition(sequence.count == n, "The order misses \(n - sequence.count) vertices")
        return Coloring(self, numbering: numbering, colors: _runOnUndirectedRows(_FirstFitRows(order: sequence), vertexNumbering: numbering))
    }
}
