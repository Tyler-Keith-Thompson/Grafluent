import BipartiteGraphs
import GraphProtocols

/// A proper edge colouring of a graph by the colours `0..<colorCount`, each of which is used: the
/// result of `edgeColoring()` and `bipartiteEdgeColoring()`.
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

    /// The edge colouring given by a colour per edge number, every colour in `0..<k` used.
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
    /// `bipartiteEdgeColoring()`, 0 without edges.
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

/// Edge colouring state in index space: each edge's ends and colour, and per vertex the edge of
/// each colour there (−1 when the colour is free), `width` colours a row, so "is c free at x" is
/// O(1).
@frozen
@usableFromInline
struct _EdgeColorTable {
    @usableFromInline var first: [Int]
    @usableFromInline var second: [Int]
    @usableFromInline var color: [Int]
    @usableFromInline var at: [Int]
    @usableFromInline let width: Int
    @usableFromInline var path: [Int] = []

    @inlinable
    init(first: [Int], second: [Int], vertexCount n: Int, width: Int) {
        self.first = first
        self.second = second
        color = [Int](repeating: -1, count: first.count)
        at = [Int](repeating: -1, count: n * width)
        self.width = width
    }

    @inlinable @inline(__always)
    func other(_ e: Int, _ x: Int) -> Int { first[e] == x ? second[e] : first[e] }

    @inlinable @inline(__always)
    func isFree(_ x: Int, _ c: Int) -> Bool { at[x &* width &+ c] < 0 }

    @inlinable @inline(__always)
    func edge(at x: Int, _ c: Int) -> Int { at[x &* width &+ c] }

    /// The least colour free at `x`.
    @inlinable
    func leastFree(_ x: Int) -> Int {
        var c = 0
        while c < width, at[x &* width &+ c] >= 0 { c += 1 }
        precondition(c < width, "No colour is free at a vertex")
        return c
    }

    @inlinable @inline(__always)
    mutating func set(_ e: Int, _ c: Int) {
        color[e] = c
        at[first[e] &* width &+ c] = e
        at[second[e] &* width &+ c] = e
    }

    @inlinable @inline(__always)
    mutating func unset(_ e: Int) {
        let c = color[e]
        at[first[e] &* width &+ c] = -1
        at[second[e] &* width &+ c] = -1
        color[e] = -1
    }

    /// Swaps `c1` and `c2` on the maximal path from `start` whose first edge has colour `c1` (a
    /// Kempe chain; `c2` is free at `start`, so it is a path).
    @inlinable
    mutating func flip(from start: Int, _ c1: Int, _ c2: Int) {
        path.removeAll(keepingCapacity: true)
        var x = start, c = c1
        while true {
            let e = at[x &* width &+ c]
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
}

/// Reads each edge's two ends from the rows, with the greatest degree counting every edge end.
/// With `simple`, traps on a self-loop or on parallel edges (a stamp per row).
@inlinable
func _edgeEnds<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows, simple: Bool) -> (first: [Int], second: [Int], maximumDegree: Int) {
    var first = [Int](repeating: -1, count: m), second = [Int](repeating: -1, count: m)
    var stamp = simple ? [Int](repeating: -1, count: n) : []
    var top = 0
    for v in 0 ..< n {
        let length = rows.count(v)
        top = max(top, length)
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
                first[e] = v
                second[e] = w
            }
        }
    }
    return (first, second, top)
}

/// Misra and Gries (1992), edges by number. For an edge {u, v}, u the lesser end, c is the least
/// colour free at u. The fan F = [v] grows while c is used at its last vertex: next is the
/// neighbour of u not in F whose edge to u has the least colour free at the last vertex. If c is
/// free at the last fan vertex then d = c; otherwise d is the least colour free there, and the d/c
/// path from u is flipped. Then w is the first fan vertex such that F up to w is still a fan and d
/// is free at w; the fan is rotated up to w and uw gets d. Colours stay in 0...Δ.
@frozen
@usableFromInline
struct _MisraGries: _UndirectedRowsAlgorithm {
    @inlinable
    init() {}

    @inlinable
    func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount m: Int, _ rows: inout Rows) -> [Int] {
        let (first, second, top) = _edgeEnds(count: n, edgeCount: m, &rows, simple: true)
        guard m > 0 else { return [] }
        var table = _EdgeColorTable(first: first, second: second, vertexCount: n, width: top + 1)
        var fan: [Int] = [], fanEdges: [Int] = []
        var inFan = [Int](repeating: -1, count: n)
        var shifted: [Int] = []
        for e in 0 ..< m {
            let u = min(first[e], second[e]), v = max(first[e], second[e])
            let c = table.leastFree(u)
            fan.removeAll(keepingCapacity: true)
            fanEdges.removeAll(keepingCapacity: true)
            fan.append(v)
            fanEdges.append(e)
            inFan[v] = e
            while !table.isFree(fan[fan.count - 1], c) {
                let last = fan[fan.count - 1]
                var found = -1
                for k in 0 ... top {
                    let f = table.edge(at: u, k)
                    guard f >= 0, table.isFree(last, k) else { continue }
                    let x = table.other(f, u)
                    if inFan[x] != e {
                        found = f
                        break
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
            var w = -1
            for i in 0 ..< fan.count {
                if i > 0, !table.isFree(fan[i - 1], table.color[fanEdges[i]]) { break }
                if table.isFree(fan[i], d) {
                    w = i
                    break
                }
            }
            precondition(w >= 0, "Misra–Gries found no vertex to rotate the fan to")
            shifted.removeAll(keepingCapacity: true)
            for j in 0 ..< w { shifted.append(table.color[fanEdges[j + 1]]) }
            for j in stride(from: 1, through: w, by: 1) { table.unset(fanEdges[j]) }
            for j in 0 ..< w { table.set(fanEdges[j], shifted[j]) }
            table.set(fanEdges[w], d)
        }
        return table.color
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
        let (first, second, top) = _edgeEnds(count: n, edgeCount: m, &rows, simple: false)
        guard m > 0 else { return [] }
        var table = _EdgeColorTable(first: first, second: second, vertexCount: n, width: top)
        for e in 0 ..< m {
            let u = min(first[e], second[e]), v = max(first[e], second[e])
            let a = table.leastFree(u), b = table.leastFree(v)
            if !table.isFree(v, a) { table.flip(from: v, a, b) }
            table.set(e, a)
        }
        return table.color
    }
}

extension Graph {
    /// An edge colouring with at most Δ + 1 colours (Vizing's bound), by Misra and Gries's
    /// constructive proof (Boost `edge_coloring`, rustworkx `graph_misra_gries_edge_color`, with
    /// their own choices; Sage `edge_coloring`). Edges in position order, each coloured through a
    /// fan at its end with the lesser vertex index, every choice the least colour or vertex
    /// available. At least Δ colours always, and Δ + 1 on class-2 graphs (odd cycles, odd complete
    /// graphs, Petersen), but sometimes Δ + 1 on class-1 graphs too (K(4)); on a bipartite graph
    /// `bipartiteEdgeColoring()` always gives Δ. O(n · m) time, O(n · Δ) memory.
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
    /// O(n · m) time, O(n · Δ) memory.
    @inlinable
    public func bipartiteEdgeColoring() -> EdgeColoring<Self>? {
        guard let colors = _runOnUndirectedRows(_KonigEdgeColoring()) else { return nil }
        return EdgeColoring(self, colors: colors)
    }
}
