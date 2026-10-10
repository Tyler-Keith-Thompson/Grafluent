import BipartiteGraphs
import GraphProtocols

/// A proper edge colouring of a graph by the colours `0..<colorCount`, each of which is used: the
/// result of `edgeColoring()`, `bipartiteEdgeColoring()` and `greedyEdgeColoring()`.
///
/// It keeps a copy of the graph to look positions up (copy-on-write, O(1) to make), as `Coloring`
/// does. A colour class's slice keeps the indices of the flat storage it is cut from: use
/// `first`, iteration or `Array(_:)`, not `[0]`.
@frozen
public struct EdgeColoring<G: Graph> {
    @usableFromInline let _graph: G
    /// Every edge position in `edges` order, for graphs without edge indices; empty with them.
    @usableFromInline let _positions: [G.Edges.Index]
    /// The colour of each edge, by edge number.
    @usableFromInline let _colors: [Int]
    /// Every edge position, colour by colour, ascending within a colour; colour `c` is
    /// `_members[_offsets[c] ..< _offsets[c + 1]]`.
    @usableFromInline let _members: [G.Edges.Index]
    @usableFromInline let _offsets: [Int]

    /// The edge colouring given by a colour per edge number, every colour in `0..<k` used. Edge
    /// number e is the e-th position of `edges`: its offset there, or, with edge indices, its
    /// edge index, which `Graph`'s laws put in `edges` order.
    @inlinable
    init(_ graph: G, colors: [Int]) {
        let m = colors.count
        let positions = Array(graph.edges.indices)
        var k = 0
        for c in colors where c >= k { k = c + 1 }
        var offsets = [Int](repeating: 0, count: k + 1)
        for c in colors { offsets[c + 1] += 1 }
        for c in 0 ..< k { offsets[c + 1] += offsets[c] }
        var fill = offsets
        var members = positions
        for e in 0 ..< m {
            members[fill[colors[e]]] = positions[e]
            fill[colors[e]] += 1
        }
        _graph = graph
        _positions = graph.edgeIndexBound == nil ? positions : []
        _colors = colors
        _members = members
        _offsets = offsets
    }

    /// The number of colours: between Δ and Δ + 1 for `edgeColoring()`, Δ for
    /// `bipartiteEdgeColoring()`, at most 2Δ − 1 for `greedyEdgeColoring()`, 0 without edges.
    @inlinable
    public var colorCount: Int { _offsets.count - 1 }

    /// The colour of the edge at `position`: O(1) with edge indices, O(log m) without (a binary
    /// search over the positions).
    ///
    /// - Precondition: `position` is a position in the graph's `edges`.
    @inlinable
    public func color(ofEdgeAt position: G.Edges.Index) -> Int {
        if _graph.edgeIndexBound != nil {
            let e = _graph.edgeIndex(of: position)
            precondition(e >= 0 && e < _colors.count, "\(position) is not an edge position of the graph")
            return _colors[e]
        }
        var low = 0, high = _positions.count
        while low < high {
            let mid = (low + high) >> 1
            if _positions[mid] < position { low = mid + 1 } else { high = mid }
        }
        precondition(low < _positions.count && _positions[low] == position, "\(position) is not an edge position of the graph")
        return _colors[low]
    }

    /// The edge positions of each colour, by colour, ascending: slices of one flat array. Each is
    /// a matching.
    @inlinable
    public var colorClasses: [ArraySlice<G.Edges.Index>] {
        (0 ..< colorCount).map { _members[_offsets[$0] ..< _offsets[$0 + 1]] }
    }
}

extension EdgeColoring: Equatable {
    /// Whether every edge has the same colour in both. The graphs are not compared.
    @inlinable
    public static func == (lhs: EdgeColoring, rhs: EdgeColoring) -> Bool { lhs._colors == rhs._colors }
}

extension EdgeColoring: Sendable where G: Sendable, G.Edges.Index: Sendable {}

extension EdgeColoring: CustomStringConvertible {
    /// `[[0, 2], [1]]`: the edge positions of each colour, by colour.
    public var description: String {
        "[" + colorClasses.map { "[" + $0.map { "\($0)" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
    }
}

/// Edge colouring state in index space: each edge's ends and colour, and per vertex a map from
/// colour to the edge of that colour there, so "is c free at x" is O(1) (expected). A vertex's
/// map is a row of `width` slots indexed by colour when that is at most twice the open-addressing
/// table it would otherwise get (linear probing, a power of two at least twice its degree), so
/// the maps take O(n + m) memory however large Δ is. Each vertex also keeps a colour below which
/// every colour is used there, where the search for its least free colour starts. Edges, colours
/// and slots are `Int32`.
@frozen
@usableFromInline
struct _EdgeColorTable {
    @usableFromInline var first: [Int32]
    @usableFromInline var second: [Int32]
    @usableFromInline var color: [Int32]
    /// Per vertex, its slots' start (high 32 bits) and its table's mask (low 32 bits, all ones
    /// for a row indexed by colour), packed so a lookup reads one word.
    @usableFromInline var place: [UInt64]
    @usableFromInline var low: [Int32]
    /// Per slot, the colour held (tables only; −1 when empty) and the edge (−1 when free).
    @usableFromInline var keys: [Int32]
    @usableFromInline var slots: [Int32]
    @usableFromInline let width: Int
    @usableFromInline var path: [Int] = []

    /// `degree[x]` bounds the edges coloured at x at any time.
    @inlinable
    init(first: [Int32], second: [Int32], degree: [Int], width: Int) {
        let n = degree.count
        self.first = first
        self.second = second
        color = [Int32](repeating: -1, count: first.count)
        place = [UInt64](repeating: 0, count: n)
        low = [Int32](repeating: 0, count: n)
        var total = 0
        for x in 0 ..< n {
            var capacity = 2
            while capacity < 2 * degree[x] { capacity <<= 1 }
            if width <= 2 * capacity {
                place[x] = UInt64(total) << 32 | 0xFFFF_FFFF
                total += width
            } else {
                place[x] = UInt64(total) << 32 | UInt64(capacity - 1)
                total += capacity
            }
        }
        precondition(total < 1 << 32, "Edge colouring needs fewer than 2³² table slots")
        keys = [Int32](repeating: -1, count: total)
        slots = [Int32](repeating: -1, count: total)
        self.width = width
    }

    @inlinable @inline(__always)
    func other(_ e: Int, _ x: Int) -> Int { Int(first[e] ^ second[e]) ^ x }

    /// The slot of colour `c` at `x`: its own in a row; in a table, the one holding it or the
    /// empty one where probing stops.
    @inlinable @inline(__always)
    func slot(_ x: Int, _ c: Int) -> Int {
        let word = place[x]
        let base = Int(word >> 32), m = Int(word & 0xFFFF_FFFF)
        if m == 0xFFFF_FFFF { return base &+ c }
        var h = c & m
        while true {
            let key = keys[base &+ h]
            if key == Int32(truncatingIfNeeded: c) || key < 0 { return base &+ h }
            h = (h &+ 1) & m
        }
    }

    /// Whether `x` keeps a row indexed by colour, and its slots.
    @inlinable @inline(__always)
    func isRow(_ x: Int) -> Bool { place[x] & 0xFFFF_FFFF == 0xFFFF_FFFF }

    @inlinable @inline(__always)
    func slots(of x: Int) -> Range<Int> {
        let word = place[x]
        let base = Int(word >> 32), m = Int(word & 0xFFFF_FFFF)
        return base ..< base + (m == 0xFFFF_FFFF ? width : m + 1)
    }

    /// The edge of colour `c` at `x`, or −1.
    @inlinable @inline(__always)
    func edge(at x: Int, _ c: Int) -> Int { Int(slots[slot(x, c)]) }

    @inlinable @inline(__always)
    func isFree(_ x: Int, _ c: Int) -> Bool { slots[slot(x, c)] < 0 }

    /// The least colour free at `x`.
    @inlinable @inline(__always)
    mutating func leastFree(_ x: Int) -> Int {
        let from = Int(low[x])
        var c = from
        while c < width, !isFree(x, c) { c += 1 }
        precondition(c < width, "No colour is free at a vertex")
        if c != from { low[x] = Int32(truncatingIfNeeded: c) }
        return c
    }

    @inlinable @inline(__always)
    mutating func insert(_ x: Int, _ c: Int, _ e: Int) {
        let i = slot(x, c)
        if !isRow(x) { keys[i] = Int32(truncatingIfNeeded: c) }
        slots[i] = Int32(truncatingIfNeeded: e)
    }

    /// Frees colour `c` at `x`; in a table, the entries after it in its probe run move back.
    @inlinable @inline(__always)
    mutating func remove(_ x: Int, _ c: Int) {
        var i = slot(x, c)
        slots[i] = -1
        if c < low[x] { low[x] = Int32(truncatingIfNeeded: c) }
        let word = place[x]
        let base = Int(word >> 32), size = Int(word & 0xFFFF_FFFF)
        guard size != 0xFFFF_FFFF else { return }
        var j = i - base
        var hole = j
        while true {
            j = (j &+ 1) & size
            let key = keys[base &+ j]
            if key < 0 { break }
            let home = Int(key) & size
            // Stays when its home lies cyclically in (hole, j].
            let stays = hole <= j ? (hole < home && home <= j) : (hole < home || home <= j)
            if stays { continue }
            keys[base &+ hole] = key
            slots[base &+ hole] = slots[base &+ j]
            hole = j
        }
        i = base &+ hole
        keys[i] = -1
        slots[i] = -1
    }

    @inlinable @inline(__always)
    mutating func set(_ e: Int, _ c: Int) {
        color[e] = Int32(truncatingIfNeeded: c)
        insert(Int(first[e]), c, e)
        if second[e] != first[e] { insert(Int(second[e]), c, e) }
    }

    @inlinable @inline(__always)
    mutating func unset(_ e: Int) {
        let c = Int(color[e])
        remove(Int(first[e]), c)
        if second[e] != first[e] { remove(Int(second[e]), c) }
        color[e] = -1
    }

    /// Swaps `c1` and `c2` on the maximal path from `start` whose first edge has colour `c1` (a
    /// Kempe chain; `c2` is free at `start`, so it is a path).
    @inlinable
    mutating func flip(from start: Int, _ c1: Int, _ c2: Int) {
        path.removeAll(keepingCapacity: true)
        var x = start, c = c1
        while true {
            let e = edge(at: x, c)
            if e < 0 { break }
            path.append(e)
            precondition(path.count <= color.count, "A Kempe chain closed into a cycle")
            x = other(e, x)
            c = c == c1 ? c2 : c1
        }
        for e in path { unset(e) }
        // Colours alternate along the path, starting at c1.
        var next = c2
        for e in path {
            set(e, next)
            next = next == c1 ? c2 : c1
        }
    }

    /// Every colour as an `Int`, by edge number.
    @inlinable
    var colors: [Int] { color.map { Int($0) } }
}

/// Reads each edge's two ends from the rows, with each vertex's edge ends (Δ is their maximum).
/// With `simple`, traps on a self-loop or on parallel edges (a stamp per row).
@inlinable
func _edgeEnds<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows, simple: Bool) -> (first: [Int32], second: [Int32], degree: [Int]) {
    precondition(m < Int(Int32.max) && n < Int(Int32.max), "Edge colouring numbers vertices and edges in Int32")
    var first = [Int32](repeating: -1, count: m), second = [Int32](repeating: -1, count: m)
    var degree = [Int](repeating: 0, count: n)
    var stamp = simple ? [Int](repeating: -1, count: n) : []
    for v in 0 ..< n {
        let length = rows.count(v)
        degree[v] = length
        for k in 0 ..< length {
            let w = rows.neighbor(v, k), e = rows.edge(v, k)
            precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
            precondition(UInt(bitPattern: e) < UInt(bitPattern: m), "An edge index is out of range")
            if simple {
                precondition(w != v, "edgeColoring() requires a simple graph: the graph has a self-loop")
                precondition(stamp[w] != v, "edgeColoring() requires a simple graph: the graph has parallel edges")
                stamp[w] = v
            }
            if first[e] < 0 {
                first[e] = Int32(truncatingIfNeeded: v)
                second[e] = Int32(truncatingIfNeeded: w)
            }
        }
    }
    return (first, second, degree)
}

/// Misra and Gries (1992), edges by number. For an edge {u, v}, u the lesser end, c is the least
/// colour free at u. The fan F = [v] grows while c is used at its last vertex: next is the
/// neighbour of u not in F whose edge to u has the least colour free at the last vertex (found
/// among u's coloured edges, O(deg u)). If c is free at the last fan vertex then d = c; otherwise
/// d is the least colour free there, and the d/c path from u is flipped. Then w is the first fan
/// vertex at which d is free (Misra and Gries show F up to w is still a fan); the fan is rotated
/// up to w and uw gets d. Colours stay in 0...Δ.
@frozen
@usableFromInline
struct _MisraGries: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> [Int] {
        let (first, second, degree) = _edgeEnds(count: n, edgeCount: m, &rows, simple: true)
        guard m > 0 else { return [] }
        let top = degree.max()!
        var table = _EdgeColorTable(first: first, second: second, degree: degree, width: top + 1)
        var fan: [Int] = [], fanEdges: [Int] = []
        var inFan = [Int](repeating: -1, count: n)
        var shifted: [Int] = []
        for e in 0 ..< m {
            let u = Int(min(first[e], second[e])), v = Int(max(first[e], second[e]))
            let c = table.leastFree(u)
            fan.removeAll(keepingCapacity: true)
            fanEdges.removeAll(keepingCapacity: true)
            fan.append(v)
            fanEdges.append(e)
            inFan[v] = e
            while !table.isFree(fan[fan.count - 1], c) {
                let last = fan[fan.count - 1]
                var found = -1, least = Int.max
                if table.isRow(u) {
                    let base = table.slots(of: u).lowerBound
                    for k in 0 ... top {
                        let f = Int(table.slots[base &+ k])
                        guard f >= 0, table.isFree(last, k) else { continue }
                        if inFan[table.other(f, u)] != e {
                            found = f
                            break
                        }
                    }
                } else {
                    for i in table.slots(of: u) {
                        let k = Int(table.keys[i]), f = Int(table.slots[i])
                        guard f >= 0, k < least, table.isFree(last, k) else { continue }
                        if inFan[table.other(f, u)] != e {
                            found = f
                            least = k
                        }
                    }
                }
                if found < 0 { break }
                let x = table.other(found, u)
                fan.append(x)
                fanEdges.append(found)
                inFan[x] = e
            }
            let d: Int
            if table.isFree(fan[fan.count - 1], c) {
                d = c
            } else {
                d = table.leastFree(fan[fan.count - 1])
                table.flip(from: u, d, c)
            }
            var w = 0
            while !table.isFree(fan[w], d) { w += 1 }
            shifted.removeAll(keepingCapacity: true)
            for j in 0 ..< w { shifted.append(Int(table.color[fanEdges[j + 1]])) }
            for j in stride(from: 1, through: w, by: 1) { table.unset(fanEdges[j]) }
            for j in 0 ..< w { table.set(fanEdges[j], shifted[j]) }
            table.set(fanEdges[w], d)
        }
        return table.colors
    }
}

/// König's theorem made constructive, edges by number. For an edge {u, v}, u the lesser end, a is
/// the least colour free at u and b the least free at v. If a is used at v, the a/b path from v is
/// flipped; in a bipartite graph it never reaches u, so a is then free at both and the edge takes
/// it. Exactly Δ colours, parallel edges included. Nil when BipartiteGraphs' two-colouring finds
/// an odd cycle (a self-loop is one).
@frozen
@usableFromInline
struct _KonigEdgeColoring: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> [Int]? {
        guard _TwoColoring(witness: false).run(count: n, edgeCount: m, &rows).sides != nil else { return nil }
        let (first, second, degree) = _edgeEnds(count: n, edgeCount: m, &rows, simple: false)
        guard m > 0 else { return [] }
        var table = _EdgeColorTable(first: first, second: second, degree: degree, width: degree.max()!)
        for e in 0 ..< m {
            let u = Int(min(first[e], second[e])), v = Int(max(first[e], second[e]))
            let a = table.leastFree(u), b = table.leastFree(v)
            if !table.isFree(v, a) { table.flip(from: v, a, b) }
            table.set(e, a)
        }
        return table.colors
    }
}

/// rustworkx's greedy edge colouring, its line graph's largest-first colouring: edges by the
/// number of edges they meet, counted at each end (a parallel copy at both, a self-loop once at
/// its vertex), most first, ties by number; each takes the least colour on no edge it meets
/// coloured so far. The search for that colour starts at the greater of its ends' bounds below
/// which every colour is used.
@frozen
@usableFromInline
struct _GreedyEdgeColoring: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> [Int] {
        var (first, second, degree) = _edgeEnds(count: n, edgeCount: m, &rows, simple: false)
        guard m > 0 else { return [] }
        // Edges at each vertex, a self-loop once.
        for e in 0 ..< m where first[e] == second[e] { degree[Int(first[e])] -= 1 }
        var met = [Int](repeating: 0, count: m)
        var top = 0
        for e in 0 ..< m {
            let u = Int(first[e]), v = Int(second[e])
            met[e] = u == v ? degree[u] - 1 : degree[u] + degree[v] - 2
            top = max(top, met[e])
        }
        // Counting sort, most met first, stable by number.
        var starts = [Int](repeating: 0, count: top + 2)
        for e in 0 ..< m { starts[top - met[e] + 1] += 1 }
        for d in 0 ... top { starts[d + 1] += starts[d] }
        var order = [Int](repeating: 0, count: m)
        for e in 0 ..< m {
            order[starts[top - met[e]]] = e
            starts[top - met[e]] += 1
        }
        var table = _EdgeColorTable(first: first, second: second, degree: degree, width: top + 1)
        for e in order {
            let u = Int(first[e]), v = Int(second[e])
            var c = Int(max(table.low[u], table.low[v]))
            while !table.isFree(u, c) || !table.isFree(v, c) { c += 1 }
            table.set(e, c)
            if c == table.low[u] { table.low[u] += 1 }
            if c == table.low[v] { table.low[v] += 1 }
        }
        return table.colors
    }
}

extension Graph {
    /// An edge colouring with at most Δ + 1 colours (Vizing's bound), by Misra and Gries's
    /// constructive proof (Boost `edge_coloring`, rustworkx `graph_misra_gries_edge_color`, with
    /// their own choices; Sage `edge_coloring`). Edges in position order, each coloured through a
    /// fan at its end with the lesser vertex index, every choice the least colour or vertex
    /// available. At least Δ colours always, and Δ + 1 on class-2 graphs (odd cycles, odd complete
    /// graphs, Petersen), but sometimes Δ + 1 on class-1 graphs too (K(4)); on a bipartite graph
    /// `bipartiteEdgeColoring()` always gives Δ. O(m · (Δ² + n)) time: a fan has at most Δ
    /// vertices, each found among the edges at u, and a path at most n edges. O(n + m) memory.
    /// For a multigraph (`digraph.undirected` with an antiparallel pair is one), use
    /// `greedyEdgeColoring()`.
    ///
    /// - Precondition: the graph is simple: no self-loops, no parallel edges.
    @inlinable
    public func edgeColoring() -> EdgeColoring<Self> {
        EdgeColoring(self, colors: _runOnUndirectedRows(_MisraGries()))
    }

    /// An edge colouring with exactly Δ colours, Δ counting parallel edges, on a bipartite graph
    /// (König's theorem; rustworkx `graph_bipartite_edge_color`), or nil when the graph is not
    /// bipartite (`findOddCycle()` gives the witness; a self-loop makes it not bipartite).
    /// Parallel edges are fine. Edges in position order: each takes the least colour free at its
    /// end with the lesser vertex index, after the alternating path of that colour and the least
    /// colour free at the other end is flipped from the other end, when the two differ there.
    /// O(m · (n + Δ)) time, O(n + m) memory.
    @inlinable
    public func bipartiteEdgeColoring() -> EdgeColoring<Self>? {
        guard let colors = _runOnUndirectedRows(_KonigEdgeColoring()) else { return nil }
        return EdgeColoring(self, colors: colors)
    }

    /// A greedy edge colouring of any graph, parallel edges and self-loops included, with at most
    /// 2Δ − 1 colours: rustworkx `graph_greedy_edge_color`, the largest-first colouring of the
    /// line graph, with the same colours. Edges by the number of other edges they share an end
    /// with, most first (a parallel copy counts at both ends, a self-loop meets each other edge at
    /// its vertex once), ties in position order; each takes the least colour of no edge it shares
    /// an end with that is already coloured. A self-loop is one edge at its vertex, as for
    /// `isEdgeColoring(_:)`. O(n + m · Δ) time, O(n + m) memory, without building the line graph.
    @inlinable
    public func greedyEdgeColoring() -> EdgeColoring<Self> {
        EdgeColoring(self, colors: _runOnUndirectedRows(_GreedyEdgeColoring()))
    }
}
