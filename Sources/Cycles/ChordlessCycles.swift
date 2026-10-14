import GraphProtocols
import Walks

/// The chordless cycles of `_CycleRows`, resumable after each: for each least vertex `s` in turn,
/// a depth-first search over the vertices above `s` that extends only induced paths, so it never
/// enters a vertex joined to the path by any edge but the one it arrives along.
///
/// A vertex with a self-loop is on no longer chordless cycle (the loop would be a chord), and is
/// a cycle of length 1 when it has exactly one loop. Two vertices joined by exactly two edges,
/// in opposite directions when directed, and by nothing else make a cycle of length 2. Undirected,
/// a longer cycle is met in both orientations and emitted in the one whose first edge is the
/// lesser.
@frozen
@usableFromInline
struct _ChordlessCycleSearch: Sendable {
    @usableFromInline let rows: _CycleRows
    @usableFromInline let maxLength: Int
    /// Directed: the in-rows, as slots of `rows` grouped by target.
    @usableFromInline let inOffsets: [Int]
    @usableFromInline let inSlots: [Int]
    @usableFromInline let sources: [Int]
    /// The number of self-loops at each vertex.
    @usableFromInline let loops: [Int]
    /// The number of edges between each vertex and the path's vertices other than `s`.
    @usableFromInline var joined: [Int]
    /// The number of edges from `s` to each vertex (undirected: between them), and from it to
    /// `s`; with the edge number of the one edge in each direction when there is one.
    @usableFromInline var fromRoot: [Int]
    @usableFromInline var toRoot: [Int]
    @usableFromInline var fromRootEdge: [Int]
    @usableFromInline var toRootEdge: [Int]
    @usableFromInline var onPath: [Bool]

    @usableFromInline var s = -1
    @usableFromInline var scanningRoot = false
    @usableFromInline var rootCursor = 0
    /// The path from `s` (`path[0]`), the edge into each later vertex, and per vertex after `s`
    /// the next slot of its row.
    @usableFromInline var path: [Int] = []
    @usableFromInline var pathEdges: [Int] = []
    @usableFromInline var cursors: [Int] = []
    /// The cycle last emitted.
    @usableFromInline var cycleVertices: [Int] = []
    @usableFromInline var cycleEdges: [Int] = []

    @inlinable
    init(_ rows: _CycleRows, maxLength: Int) {
        let n = rows.count
        self.rows = rows
        self.maxLength = maxLength
        sources = rows.undirected ? [] : rows.slotSources()
        var loops = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            for slot in rows.offsets[v] ..< rows.offsets[v + 1] where rows.targets[slot] == v { loops[v] += 1 }
            // An undirected loop is in its row twice.
            if rows.undirected { loops[v] /= 2 }
        }
        self.loops = loops
        if rows.undirected {
            inOffsets = []
            inSlots = []
        } else {
            var offsets = [Int](repeating: 0, count: n + 1)
            for w in rows.targets { offsets[w + 1] += 1 }
            for v in 0 ..< n { offsets[v + 1] += offsets[v] }
            var fill = offsets
            var slots = [Int](repeating: 0, count: rows.targets.count)
            for slot in rows.targets.indices {
                let w = rows.targets[slot]
                slots[fill[w]] = slot
                fill[w] += 1
            }
            inOffsets = offsets
            inSlots = slots
        }
        joined = [Int](repeating: 0, count: n)
        fromRoot = [Int](repeating: 0, count: n)
        toRoot = [Int](repeating: 0, count: rows.undirected ? 0 : n)
        fromRootEdge = [Int](repeating: -1, count: n)
        toRootEdge = [Int](repeating: -1, count: rows.undirected ? 0 : n)
        onPath = [Bool](repeating: false, count: n)
    }

    /// Advances to the next cycle, left in `cycleVertices` and `cycleEdges`; false when there is
    /// none.
    @inlinable
    mutating func next() -> Bool {
        guard maxLength > 0 else { return false }
        while true {
            if path.count >= 2 {
                if step() { return true }
                continue
            }
            if scanningRoot {
                if scanRoot() { return true }
                continue
            }
            s += 1
            if s >= rows.count { return false }
            if loops[s] > 0 {
                guard loops[s] == 1 else { continue }
                // The loop alone: every longer cycle through `s` has it as a chord.
                let slot = (rows.offsets[s] ..< rows.offsets[s + 1]).first { rows.targets[$0] == s }!
                cycleVertices = [s]
                cycleEdges = [rows.edges[slot]]
                return true
            }
            startRoot()
        }
    }

    /// Counts the edges between `s` and each vertex, and starts scanning its row.
    @inlinable
    mutating func startRoot() {
        for slot in rows.offsets[s] ..< rows.offsets[s + 1] {
            let w = rows.targets[slot]
            fromRoot[w] += 1
            fromRootEdge[w] = rows.edges[slot]
        }
        if !rows.undirected {
            for k in inOffsets[s] ..< inOffsets[s + 1] {
                let slot = inSlots[k]
                let u = sources[slot]
                toRoot[u] += 1
                toRootEdge[u] = slot
            }
        }
        path = [s]
        rootCursor = rows.offsets[s]
        scanningRoot = true
    }

    /// The edges from `w` back to `s`, and the one edge's number when there is one.
    @inlinable
    @inline(__always)
    func back(_ w: Int) -> (count: Int, edge: Int) {
        rows.undirected ? (fromRoot[w], fromRootEdge[w]) : (toRoot[w], toRootEdge[w])
    }

    /// Scans the next edges out of `s` until it emits a cycle of length 2 (true) or enters a
    /// vertex (false, with the search to run from it); at the end of the row, ends the round.
    @inlinable
    mutating func scanRoot() -> Bool {
        while rootCursor < rows.offsets[s + 1] {
            let slot = rootCursor
            rootCursor += 1
            let w = rows.targets[slot], e = rows.edges[slot]
            guard w > s, loops[w] == 0 else { continue }
            let (backCount, backEdge) = back(w)
            if rows.undirected {
                if fromRoot[w] == 2 {
                    // Two parallel edges, met at both; emitted from the lesser.
                    guard maxLength >= 2 else { continue }
                    let other = (rows.offsets[s] ..< rows.offsets[s + 1]).first { rows.targets[$0] == w && rows.edges[$0] != e }!
                    guard e < rows.edges[other] else { continue }
                    cycleVertices = [s, w]
                    cycleEdges = [e, rows.edges[other]]
                    return true
                }
                if fromRoot[w] == 1 && maxLength >= 3 {
                    push(w, edge: e)
                    return false
                }
                continue
            }
            guard fromRoot[w] == 1 else { continue }
            if backCount == 1 {
                guard maxLength >= 2 else { continue }
                cycleVertices = [s, w]
                cycleEdges = [e, backEdge]
                return true
            }
            if backCount == 0 && maxLength >= 3 {
                push(w, edge: e)
                return false
            }
        }
        endRoot()
        return false
    }

    /// Clears the counts of `s`.
    @inlinable
    mutating func endRoot() {
        for slot in rows.offsets[s] ..< rows.offsets[s + 1] {
            let w = rows.targets[slot]
            fromRoot[w] = 0
            fromRootEdge[w] = -1
        }
        if !rows.undirected {
            for k in inOffsets[s] ..< inOffsets[s + 1] {
                let u = sources[inSlots[k]]
                toRoot[u] = 0
                toRootEdge[u] = -1
            }
        }
        path.removeAll(keepingCapacity: true)
        scanningRoot = false
    }

    /// One step of the search below `s`. True when a cycle is emitted.
    @inlinable
    mutating func step() -> Bool {
        let top = path.count - 1
        let u = path[top]
        let slot = cursors[top - 1]
        guard slot < rows.offsets[u + 1] else {
            pop()
            return false
        }
        cursors[top - 1] = slot + 1
        let w = rows.targets[slot]
        // Joined to the path only by this edge, and not by an edge from `s`.
        guard w > s, !onPath[w], loops[w] == 0, joined[w] == 1 else { return false }
        if !rows.undirected && fromRoot[w] != 0 { return false }
        let (backCount, backEdge) = back(w)
        let length = path.count + 1
        if backCount == 1 {
            guard length <= maxLength else { return false }
            if rows.undirected && pathEdges[0] > backEdge { return false }
            cycleVertices = path
            cycleVertices.append(w)
            cycleEdges = pathEdges
            cycleEdges.append(rows.edges[slot])
            cycleEdges.append(backEdge)
            return true
        }
        if backCount == 0 && length + 1 <= maxLength { push(w, edge: rows.edges[slot]) }
        return false
    }

    @inlinable
    mutating func push(_ w: Int, edge e: Int) {
        path.append(w)
        pathEdges.append(e)
        cursors.append(rows.offsets[w])
        onPath[w] = true
        adjust(w, by: 1)
    }

    @inlinable
    mutating func pop() {
        let w = path.removeLast()
        pathEdges.removeLast()
        cursors.removeLast()
        onPath[w] = false
        adjust(w, by: -1)
    }

    /// Adds `delta` to `joined` for every edge at `w`.
    @inlinable
    mutating func adjust(_ w: Int, by delta: Int) {
        for slot in rows.offsets[w] ..< rows.offsets[w + 1] { joined[rows.targets[slot]] += delta }
        if !rows.undirected {
            for k in inOffsets[w] ..< inOffsets[w + 1] { joined[sources[inSlots[k]]] += delta }
        }
    }
}

/// Every chordless cycle of a directed graph once, lazily: the simple cycles whose vertices
/// induce no edge but the cycle's own. By least vertex (in `vertices` order), and among the
/// cycles with one least vertex in the order a depth-first search from it, taking out-edges in
/// `outEdges` order, meets them.
///
/// A self-loop is a chordless cycle when it is its vertex's only one, and its vertex is on no
/// other; two opposite edges are one when nothing else joins their ends. A parallel edge is a
/// chord of every cycle through its ends.
///
/// The sequence holds the graph (a value), so iterating again gives the same cycles. The first
/// `next()` copies the graph's rows, O(n + m). The search extends only induced paths, each step
/// O(d) for the degree d of the vertex entered or left.
@frozen
public struct DirectedChordlessCycles<G: DirectedGraph>: Sequence {
    public typealias Element = Cycle<G.Vertex, G.Edges.Index>

    @usableFromInline let graph: G
    /// The longest cycle, in edges, that the sequence includes.
    public let maxLength: Int

    @inlinable
    init(_ graph: G, maxLength: Int) {
        self.graph = graph
        self.maxLength = maxLength
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(graph, maxLength: maxLength)
    }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let graph: G
        @usableFromInline let maxLength: Int
        @usableFromInline var search: _ChordlessCycleSearch?
        @usableFromInline var positions: [G.Edges.Index] = []
        @usableFromInline var listed: [G.Vertex]?

        @inlinable
        init(_ graph: G, maxLength: Int) {
            self.graph = graph
            self.maxLength = maxLength
        }

        @inlinable
        public mutating func next() -> Element? {
            if search == nil {
                let (rows, positions, listed) = graph._cycleRows()
                self.positions = positions
                self.listed = listed
                search = _ChordlessCycleSearch(rows, maxLength: maxLength)
            }
            guard search!.next() else { return nil }
            var vertices: [G.Vertex] = [], edges: [G.Edges.Index] = []
            vertices.reserveCapacity(search!.cycleVertices.count)
            edges.reserveCapacity(search!.cycleEdges.count)
            for v in search!.cycleVertices { vertices.append(graph._vertex(number: v, listed)) }
            for e in search!.cycleEdges { edges.append(positions[e]) }
            return Cycle(_uncheckedVertices: vertices, edges: edges)
        }
    }
}

/// Every chordless cycle of an undirected graph once, lazily, each starting at its least vertex
/// (in `vertices` order) and leaving it through the lesser of its two edges there: by least
/// vertex, and among the cycles with one least vertex in the order a depth-first search from it,
/// taking edges in `incidentEdges` order, meets them in that orientation.
///
/// A self-loop is a chordless cycle when it is its vertex's only one, and its vertex is on no
/// other; two parallel edges are one when they are their ends' only edges between them. A third
/// parallel edge is a chord. Otherwise as `DirectedChordlessCycles`.
@frozen
public struct UndirectedChordlessCycles<G: Graph>: Sequence {
    public typealias Element = Cycle<G.Vertex, G.Edges.Index>

    @usableFromInline let graph: G
    /// The longest cycle, in edges, that the sequence includes.
    public let maxLength: Int

    @inlinable
    init(_ graph: G, maxLength: Int) {
        self.graph = graph
        self.maxLength = maxLength
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(graph, maxLength: maxLength)
    }

    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline let graph: G
        @usableFromInline let maxLength: Int
        @usableFromInline var search: _ChordlessCycleSearch?
        @usableFromInline var positions: [G.Edges.Index] = []
        @usableFromInline var listed: [G.Vertex]?

        @inlinable
        init(_ graph: G, maxLength: Int) {
            self.graph = graph
            self.maxLength = maxLength
        }

        @inlinable
        public mutating func next() -> Element? {
            if search == nil {
                let (rows, positions) = graph._cycleRows()
                self.positions = positions
                listed = graph._listedVertices()
                search = _ChordlessCycleSearch(rows, maxLength: maxLength)
            }
            guard search!.next() else { return nil }
            var vertices: [G.Vertex] = [], edges: [G.Edges.Index] = []
            vertices.reserveCapacity(search!.cycleVertices.count)
            edges.reserveCapacity(search!.cycleEdges.count)
            for v in search!.cycleVertices { vertices.append(graph._vertex(number: v, listed)) }
            for e in search!.cycleEdges { edges.append(positions[e]) }
            return Cycle(_uncheckedVertices: vertices, edges: edges)
        }
    }
}

extension DirectedChordlessCycles: Sendable where G: Sendable {}
extension DirectedChordlessCycles.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}
extension UndirectedChordlessCycles: Sendable where G: Sendable {}
extension UndirectedChordlessCycles.Iterator: Sendable where G: Sendable, G.Vertex: Sendable, G.Edges.Index: Sendable {}

extension DirectedGraph {
    /// Every chordless (induced) cycle of the graph once, lazily: a simple cycle whose vertices
    /// induce no edge but its own. Each starts at its least vertex in `vertices` order; see
    /// `DirectedChordlessCycles` for the order, loops and parallel edges.
    ///
    /// - Parameter maxLength: The longest cycle to include, in edges.
    /// - Complexity: O(n + m) before the first cycle; see `DirectedChordlessCycles`.
    /// - Precondition: `maxLength >= 0`.
    @inlinable
    public func chordlessCycles(maxLength: Int = .max) -> DirectedChordlessCycles<Self> {
        precondition(maxLength >= 0, "maxLength must be nonnegative")
        return DirectedChordlessCycles(self, maxLength: maxLength)
    }
}

extension Graph {
    /// Every chordless (induced) cycle of the graph once, lazily: a simple cycle whose vertices
    /// induce no edge but its own. Each starts at its least vertex in `vertices` order and leaves
    /// it through the lesser of its two edges there, as `simpleCycles()` lists it; see
    /// `UndirectedChordlessCycles` for the order, loops and parallel edges.
    ///
    /// - Parameter maxLength: The longest cycle to include, in edges.
    /// - Complexity: O(n + m) before the first cycle; see `DirectedChordlessCycles`.
    /// - Precondition: `maxLength >= 0`.
    @inlinable
    public func chordlessCycles(maxLength: Int = .max) -> UndirectedChordlessCycles<Self> {
        precondition(maxLength >= 0, "maxLength must be nonnegative")
        return UndirectedChordlessCycles(self, maxLength: maxLength)
    }
}
