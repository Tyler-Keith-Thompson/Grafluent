import GraphProtocols

/// A graph in index space, the input of every engine in this module: vertices `0..<count` in
/// `vertices` order, out-rows (an undirected graph's rows are symmetric, with a self-loop twice in
/// its vertex's row, as `neighbors(of:)` counts it), in-rows for a directed graph, and optional
/// vertex and edge colours as integers. Matching sorts each row by (neighbour, colour) so that the
/// edges between two vertices are one run of a row.
@usableFromInline
struct _IndexGraph {
    @usableFromInline var count: Int
    @usableFromInline var isDirected: Bool
    @usableFromInline var edgeCount: Int
    @usableFromInline var outOffsets: [Int]
    @usableFromInline var outTargets: [Int]
    /// Parallel to `outTargets`; empty without edge colours.
    @usableFromInline var outColors: [Int]
    /// Directed only (empty otherwise): the in-rows, sorted by (neighbour, colour) when the
    /// out-rows are.
    @usableFromInline var inOffsets: [Int]
    @usableFromInline var inTargets: [Int]
    @usableFromInline var inColors: [Int]
    /// Empty without vertex colours.
    @usableFromInline var vertexColors: [Int]

    @inlinable
    init(count: Int, isDirected: Bool, edgeCount: Int, offsets: [Int], targets: [Int], colors: [Int], vertexColors: [Int]) {
        self.count = count
        self.isDirected = isDirected
        self.edgeCount = edgeCount
        self.outOffsets = offsets
        self.outTargets = targets
        self.outColors = colors
        self.inOffsets = []
        self.inTargets = []
        self.inColors = []
        self.vertexColors = vertexColors
    }

    var hasEdgeColors: Bool { !outColors.isEmpty }

    /// Sorts every out-row by (neighbour, colour) and, when directed, builds the in-rows.
    mutating func sortRows() {
        let n = count
        if hasEdgeColors {
            let span = (outColors.max() ?? 0) + 1
            outOffsets.withUnsafeBufferPointer { offsets in
                outTargets.withUnsafeMutableBufferPointer { targets in
                    outColors.withUnsafeMutableBufferPointer { colors in
                        var keys: [Int] = []
                        for v in 0 ..< n {
                            let start = offsets[v], end = offsets[v + 1]
                            if end - start < 2 { continue }
                            keys.removeAll(keepingCapacity: true)
                            for k in start ..< end { keys.append(targets[k] &* span &+ colors[k]) }
                            keys.sort()
                            for (j, key) in keys.enumerated() {
                                targets[start + j] = key / span
                                colors[start + j] = key % span
                            }
                        }
                    }
                }
            }
        } else {
            outOffsets.withUnsafeBufferPointer { offsets in
                outTargets.withUnsafeMutableBufferPointer { targets in
                    for v in 0 ..< n where offsets[v + 1] - offsets[v] > 1 {
                        var row = UnsafeMutableBufferPointer(rebasing: targets[offsets[v] ..< offsets[v + 1]])
                        row.sort()
                    }
                }
            }
        }
        if isDirected { buildInRows() }
    }

    /// The in-rows by transposing the out-rows: sources in increasing order, so each in-row is
    /// sorted by (neighbour, colour) when the out-rows are.
    mutating func buildInRows() {
        let n = count, m = outTargets.count
        var offsets = [Int](repeating: 0, count: n + 1)
        for t in outTargets { offsets[t + 1] += 1 }
        for v in 0 ..< n { offsets[v + 1] += offsets[v] }
        var fill = offsets
        var sources = [Int](repeating: 0, count: m)
        var colors = hasEdgeColors ? [Int](repeating: 0, count: m) : []
        for v in 0 ..< n {
            for k in outOffsets[v] ..< outOffsets[v + 1] {
                let t = outTargets[k]
                sources[fill[t]] = v
                if hasEdgeColors { colors[fill[t]] = outColors[k] }
                fill[t] += 1
            }
        }
        inOffsets = offsets
        inTargets = sources
        inColors = colors
    }

    /// A connected component (weakly, when directed) as a graph of its own, with the original
    /// numbers of its vertices.
    struct Component {
        var graph: _IndexGraph
        /// By vertex of `graph`: its number in the whole graph, increasing.
        var vertices: [Int]
    }

    /// The connected components, each with rows sorted when this graph's are (vertices keep
    /// their relative order). One component (the graph itself, without copying its rows) when
    /// connected.
    func components() -> [Component] {
        let n = count
        var label = [Int](repeating: -1, count: n)
        var stack: [Int] = []
        var parts = 0
        for root in 0 ..< n where label[root] < 0 {
            label[root] = parts
            stack.append(root)
            while let v = stack.popLast() {
                for k in outOffsets[v] ..< outOffsets[v + 1] where label[outTargets[k]] < 0 {
                    label[outTargets[k]] = parts
                    stack.append(outTargets[k])
                }
                if isDirected {
                    for k in inOffsets[v] ..< inOffsets[v + 1] where label[inTargets[k]] < 0 {
                        label[inTargets[k]] = parts
                        stack.append(inTargets[k])
                    }
                }
            }
            parts += 1
        }
        if parts <= 1 { return n == 0 ? [] : [Component(graph: self, vertices: Array(0 ..< n))] }
        var vertices = [[Int]](repeating: [], count: parts)
        var local = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            local[v] = vertices[label[v]].count
            vertices[label[v]].append(v)
        }
        return (0 ..< parts).map { c in
            let members = vertices[c]
            var offsets = [0], targets: [Int] = [], colors: [Int] = []
            for v in members {
                for k in outOffsets[v] ..< outOffsets[v + 1] {
                    targets.append(local[outTargets[k]])
                    if hasEdgeColors { colors.append(outColors[k]) }
                }
                offsets.append(targets.count)
            }
            let edges = isDirected ? targets.count : targets.count / 2
            var graph = _IndexGraph(count: members.count, isDirected: isDirected, edgeCount: edges, offsets: offsets, targets: targets, colors: colors, vertexColors: vertexColors.isEmpty ? [] : members.map { vertexColors[$0] })
            if isDirected { graph.buildInRows() }
            return Component(graph: graph, vertices: members)
        }
    }

    /// No self-loops, no parallel edges and no edge colours (rows must be sorted).
    var isSimple: Bool {
        if hasEdgeColors { return false }
        for v in 0 ..< count {
            var previous = -1
            for k in outOffsets[v] ..< outOffsets[v + 1] {
                let w = outTargets[k]
                if w == v || w == previous { return false }
                previous = w
            }
        }
        return true
    }
}

/// Builds rows from a list of arcs `(sources[k], targets[k])`, grouped by source in arc order.
@inlinable
func _rows(count n: Int, sources: [Int], targets: [Int], colors: [Int]) -> (offsets: [Int], targets: [Int], colors: [Int]) {
    var offsets = [Int](repeating: 0, count: n + 1)
    for s in sources { offsets[s + 1] += 1 }
    for v in 0 ..< n { offsets[v + 1] += offsets[v] }
    var fill = offsets
    var rowTargets = [Int](repeating: 0, count: targets.count)
    var rowColors = colors.isEmpty ? [] : [Int](repeating: 0, count: targets.count)
    for k in 0 ..< sources.count {
        let s = sources[k]
        rowTargets[fill[s]] = targets[k]
        if !colors.isEmpty { rowColors[fill[s]] = colors[k] }
        fill[s] += 1
    }
    return (offsets, rowTargets, rowColors)
}

/// A graph's vertices by number and each one's number, for a graph without vertex indices.
@usableFromInline
final class _VertexNumbers<Vertex: Hashable> {
    @usableFromInline let listed: [Vertex]
    @usableFromInline let numbers: [Vertex: Int]

    @inlinable
    init(_ listed: [Vertex]) {
        self.listed = listed
        numbers = _vertexNumbers(listed)
    }
}

/// Dense ids for colours, shared by the two graphs of one call so that equal colours get equal
/// ids.
@usableFromInline
struct _ColorTable<Color: Hashable> {
    @usableFromInline var ids: [Color: Int] = [:]

    @inlinable
    init() {}

    @inlinable
    mutating func id(_ color: Color) -> Int {
        if let id = ids[color] { return id }
        let id = ids.count
        ids[color] = id
        return id
    }
}

extension Graph {
    /// The numbering of a graph without vertex indices; nil with them.
    @inlinable
    func _isomorphismNumbers() -> _VertexNumbers<Vertex>? {
        vertexIndexBound == nil ? _VertexNumbers(Array(vertices)) : nil
    }

    /// The graph in index space. `edgeColors`, when not empty, holds one colour per edge in
    /// `edges` order; the rows are then read from `edges`, otherwise from the graph's rows.
    @inlinable
    func _indexGraph(_ numbers: _VertexNumbers<Vertex>?, vertexColors: [Int], edgeColors: [Int]) -> _IndexGraph {
        let n = vertexIndexBound ?? numbers!.listed.count
        if edgeColors.isEmpty {
            let rows = _runOnUndirectedRows(_CopyRows(readsEdges: false, dropsLoops: false), vertexNumbering: numbers.map { ($0.listed, $0.numbers) })
            return _IndexGraph(count: n, isDirected: false, edgeCount: rows.targets.count / 2, offsets: rows.offsets, targets: rows.targets, colors: [], vertexColors: vertexColors)
        }
        var sources: [Int] = [], targets: [Int] = [], colors: [Int] = []
        let m = edgeColors.count
        sources.reserveCapacity(2 * m)
        targets.reserveCapacity(2 * m)
        colors.reserveCapacity(2 * m)
        var k = 0
        for position in edges.indices {
            let a: Int, b: Int
            if let numbers {
                let edge = edges[position]
                a = numbers.numbers[edge.u]!
                b = numbers.numbers[edge.v]!
            } else {
                (a, b) = endpointIndices(ofEdgeAt: position)
            }
            precondition(UInt(bitPattern: a) < UInt(bitPattern: n) && UInt(bitPattern: b) < UInt(bitPattern: n), "An endpoint index is out of range")
            sources.append(a); targets.append(b); colors.append(edgeColors[k])
            sources.append(b); targets.append(a); colors.append(edgeColors[k])
            k += 1
        }
        let rows = _rows(count: n, sources: sources, targets: targets, colors: colors)
        return _IndexGraph(count: n, isDirected: false, edgeCount: m, offsets: rows.offsets, targets: rows.targets, colors: rows.colors, vertexColors: vertexColors)
    }
}

extension DirectedGraph {
    /// The numbering of a graph without vertex indices; nil with them.
    @inlinable
    func _isomorphismNumbers() -> _VertexNumbers<Vertex>? {
        vertexIndexBound == nil ? _VertexNumbers(Array(vertices)) : nil
    }

    /// The graph in index space, its out-rows only. `edgeColors`, when not empty, holds one colour
    /// per edge in `edges` order; the arcs are then read from `edges`.
    @inlinable
    func _indexGraph(_ numbers: _VertexNumbers<Vertex>?, vertexColors: [Int], edgeColors: [Int]) -> _IndexGraph {
        let n = vertexIndexBound ?? numbers!.listed.count
        if edgeColors.isEmpty {
            if numbers == nil, let rows = _withSuccessorIndexRows({ offsets, targets -> (offsets: [Int], targets: [Int]) in
                precondition(offsets.count == n + 1 && offsets[n] <= targets.count, "The row offsets do not match vertexIndexBound")
                let all = Array(targets[0 ..< offsets[n]])
                for t in all { precondition(UInt(bitPattern: t) < UInt(bitPattern: n), "A successor index is out of range") }
                return (Array(offsets), all)
            }) {
                return _IndexGraph(count: n, isDirected: true, edgeCount: rows.targets.count, offsets: rows.offsets, targets: rows.targets, colors: [], vertexColors: vertexColors)
            }
            var offsets = [Int](repeating: 0, count: n + 1)
            var targets: [Int] = []
            for v in 0 ..< n {
                if let numbers {
                    for w in successors(of: numbers.listed[v]) { targets.append(numbers.numbers[w]!) }
                } else {
                    for w in successorIndices(ofIndex: v) {
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A successor index is out of range")
                        targets.append(w)
                    }
                }
                offsets[v + 1] = targets.count
            }
            return _IndexGraph(count: n, isDirected: true, edgeCount: targets.count, offsets: offsets, targets: targets, colors: [], vertexColors: vertexColors)
        }
        var sources: [Int] = [], targets: [Int] = []
        sources.reserveCapacity(edgeColors.count)
        targets.reserveCapacity(edgeColors.count)
        for position in edges.indices {
            let a: Int, b: Int
            if let numbers {
                a = numbers.numbers[source(ofEdgeAt: position)]!
                b = numbers.numbers[target(ofEdgeAt: position)]!
            } else {
                a = sourceIndex(ofEdgeAt: position)
                b = targetIndex(ofEdgeAt: position)
            }
            precondition(UInt(bitPattern: a) < UInt(bitPattern: n) && UInt(bitPattern: b) < UInt(bitPattern: n), "An endpoint index is out of range")
            sources.append(a)
            targets.append(b)
        }
        let rows = _rows(count: n, sources: sources, targets: targets, colors: edgeColors)
        return _IndexGraph(count: n, isDirected: true, edgeCount: edgeColors.count, offsets: rows.offsets, targets: rows.targets, colors: rows.colors, vertexColors: vertexColors)
    }
}
