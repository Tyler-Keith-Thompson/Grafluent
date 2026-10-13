import GraphProtocols
import Walks

/// Which side of a bipartite graph a vertex is on.
@frozen
public enum BipartiteSide: Hashable, Sendable, CaseIterable, Codable, CustomStringConvertible {
    case left
    case right

    /// The other side.
    @inlinable
    public var opposite: BipartiteSide { self == .left ? .right : .left }

    public var description: String { self == .left ? "left" : "right" }
}

/// Whether every row entry's far end is on the other side from its near end, given a side per
/// vertex number (0 left, 1 right). A self-loop's far end is its near end, so it fails.
@frozen
@usableFromInline
package struct _SidesCheck: _UndirectedRowsAlgorithm {
    @usableFromInline let sides: [Int8]

    @inlinable
    package init(sides: [Int8]) { self.sides = sides }

    @inlinable
    package var readsEdges: Bool { false }

    @inlinable
    package func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> Bool {
        precondition(sides.count == n, "The sides do not number the graph's vertices")
        return sides.withUnsafeBufferPointer { side in
            for v in 0 ..< n {
                let near = side[v]
                for k in 0 ..< rows.count(v) {
                    let w = rows.neighbor(v, k)
                    precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                    if side[w] == near { return false }
                }
            }
            return true
        }
    }
}

/// A breadth-first two-colouring in index space: components rooted at their least vertex number,
/// rows in `incidentEdges` order, each new vertex on the side opposite the one it was reached
/// from. Stops at the first row entry whose far end is on the near end's side; with `witness`,
/// returns the odd cycle it closes, in Cycles' canonical form (vertex and edge numbers).
@frozen
@usableFromInline
package struct _TwoColoring: _UndirectedRowsAlgorithm {
    @usableFromInline let witness: Bool

    @inlinable
    package init(witness: Bool) { self.witness = witness }

    @inlinable
    package var readsEdges: Bool { witness }

    /// The side per vertex number (0 left, 1 right), or the odd cycle.
    @inlinable
    package func run<Rows: _IncidenceRowSource>(count n: Int, edgeCount: Int, _ rows: inout Rows) -> (sides: [Int8]?, cycle: (vertices: [Int], edges: [Int])?) {
        var side = [Int8](repeating: -1, count: n)
        var parent = witness ? [Int](repeating: -1, count: n) : []
        var parentEdge = witness ? [Int](repeating: -1, count: n) : []
        // The conflict's two ends and edge, when there is one.
        var conflict: (v: Int, w: Int, e: Int)?
        let queue = UnsafeMutableBufferPointer<Int>.allocate(capacity: n)
        defer { queue.deallocate() }
        side.withUnsafeMutableBufferPointer { side in
            var tail = 0
            for root in 0 ..< n where side[root] < 0 {
                side[root] = 0
                var head = tail
                queue[tail] = root
                tail += 1
                while head < tail {
                    let v = queue[head]
                    head += 1
                    let near = side[v]
                    for k in 0 ..< rows.count(v) {
                        let w = rows.neighbor(v, k)
                        precondition(UInt(bitPattern: w) < UInt(bitPattern: n), "A neighbor index is out of range")
                        let far = side[w]
                        if far < 0 {
                            side[w] = 1 - near
                            if witness {
                                parent[w] = v
                                parentEdge[w] = rows.edge(v, k)
                            }
                            queue[tail] = w
                            tail += 1
                        } else if far == near {
                            conflict = (v, w, witness ? rows.edge(v, k) : -1)
                            return
                        }
                    }
                }
            }
        }
        if let (v, w, e) = conflict {
            guard witness else { return (nil, nil) }
            precondition(UInt(bitPattern: e) < UInt(bitPattern: edgeCount), "An edge index is out of range")
            let (vs, es) = _closeCycle(v, w, e, parent, parentEdge)
            return (nil, _canonicalCycle(vs, es, undirected: true))
        }
        return (side, nil)
    }
}

/// The cycle a conflicting edge e = {v, w} closes in the search tree: from their lowest common
/// ancestor down to v, across e, and up from w. In a breadth-first search adjacent vertices differ
/// in depth by at most 1, and a conflict joins two of equal parity, so v and w are at one depth and
/// climbing both a step at a time meets at the ancestor.
@inlinable
func _closeCycle(_ v: Int, _ w: Int, _ e: Int, _ parent: [Int], _ parentEdge: [Int]) -> (vertices: [Int], edges: [Int]) {
    guard v != w else { return ([v], [e]) }
    var a = v, b = w
    var up: [Int] = [v], upEdges: [Int] = []
    var down: [Int] = [w], downEdges: [Int] = []
    while a != b {
        upEdges.append(parentEdge[a])
        a = parent[a]
        up.append(a)
        downEdges.append(parentEdge[b])
        b = parent[b]
        down.append(b)
    }
    // up = v … lca, down = w … lca.
    let vertices = Array(up.reversed()) + down.dropLast()
    let edges = Array(upEdges.reversed()) + [e] + downEdges
    return (vertices, edges)
}

/// A bipartition of a graph's vertices: the result of `bipartition()`, where in each connected
/// component the least vertex (in `vertices` order) is left, so isolated vertices are left, or of
/// `bipartition(left:)`, where the caller picks the left side. Each side lists its vertices in
/// `vertices` order.
///
/// It keeps a copy of the graph to look vertices up (copy-on-write, so O(1) to make; while the
/// result is alive, the next mutation of the original copies the whole graph). A side's slice
/// keeps the indices of the flat storage it is cut from: use `first`, iteration or `Array(_:)`.
@frozen
public struct Bipartition<G: Graph> {
    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    /// The side of each vertex, by vertex number.
    @usableFromInline let _sides: [BipartiteSide]
    /// The left vertices, then the right ones.
    @usableFromInline let _members: [G.Vertex]
    @usableFromInline let _split: Int

    @inlinable
    init(_ graph: G, listed: [G.Vertex]?, sides: [Int8]) {
        var members: [G.Vertex] = []
        members.reserveCapacity(sides.count)
        for v in sides.indices where sides[v] == 0 { members.append(listed?[v] ?? graph.vertex(atIndex: v)) }
        let split = members.count
        for v in sides.indices where sides[v] != 0 { members.append(listed?[v] ?? graph.vertex(atIndex: v)) }
        _graph = graph
        if let listed {
            var numbers: [G.Vertex: Int] = [:]
            numbers.reserveCapacity(listed.count)
            for (i, v) in listed.enumerated() { numbers[v] = i }
            _numbers = numbers
        } else {
            _numbers = nil
        }
        _sides = sides.map { $0 == 0 ? .left : .right }
        _members = members
        _split = split
    }

    /// The left vertices, in `vertices` order.
    @inlinable
    public var left: ArraySlice<G.Vertex> { _members[..<_split] }

    /// The right vertices, in `vertices` order. A slice of the flat storage after the left ones, so
    /// its indices start at `left.count`: use `first`, iteration or `Array(_:)`, not `[0]`.
    @inlinable
    public var right: ArraySlice<G.Vertex> { _members[_split...] }

    /// The side of `vertex`. O(1) after the graph's `vertexIndex(of:)` (one hash for a graph
    /// without vertex indices).
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func side(of vertex: G.Vertex) -> BipartiteSide {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return _sides[v]
        }
        return _sides[_graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph")]
    }

    /// `side(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex of the
    /// graph: one lookup in the vertex numbers for a graph without vertex indices, otherwise one
    /// `contains(_:)` on the graph's copy before the trapping spelling.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func side(checked vertex: G.Vertex) throws(VertexNotFound) -> BipartiteSide {
        if let _numbers {
            guard let v = _numbers[vertex] else { throw VertexNotFound() }
            return _sides[v]
        }
        guard _graph.contains(vertex) else { throw VertexNotFound() }
        return side(of: vertex)
    }

    /// The side of the vertex at `index`: its vertex index, or its position in `vertices` when the
    /// graph has no vertex indices.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func side(ofIndex index: Int) -> BipartiteSide {
        precondition(index >= 0 && index < _sides.count, "Vertex index \(index) out of range")
        return _sides[index]
    }
}

extension Bipartition: Equatable {
    /// Whether both have the same left and right vertices in the same order. The graphs are not
    /// compared.
    @inlinable
    public static func == (lhs: Bipartition, rhs: Bipartition) -> Bool {
        lhs._split == rhs._split && lhs._members == rhs._members
    }
}

extension Bipartition: Sendable where G: Sendable, G.Vertex: Sendable {}

extension Bipartition: CustomStringConvertible {
    /// `[a, b] | [x, y]`: the left vertices, then the right ones.
    public var description: String {
        "[" + left.map { "\($0)" }.joined(separator: ", ") + "] | [" + right.map { "\($0)" }.joined(separator: ", ") + "]"
    }
}

extension Graph {
    /// Whether the vertices split into two sides with every edge across.
    ///
    /// A bipartite graph has no odd cycle and so no self-loop. Parallel edges do not matter.
    ///
    /// - Complexity: One breadth-first search, O(n + m).
    @inlinable
    public var isBipartite: Bool { _runOnUndirectedRows(_TwoColoring(witness: false)).sides != nil }

    /// The two sides, or `nil` when the graph is not bipartite.
    ///
    /// In each connected component the least vertex (in `vertices` order) is left and the rest
    /// alternate, so isolated vertices are left. Each side lists its vertices in `vertices` order.
    /// When the graph is not bipartite, `findOddCycle()` gives a witness.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func bipartition() -> Bipartition<Self>? {
        guard let sides = _runOnUndirectedRows(_TwoColoring(witness: false)).sides else { return nil }
        return Bipartition(self, listed: _listedVertices(), sides: sides)
    }

    /// The bipartition with `left` as the left side and every other vertex on the right, or `nil`
    /// when an edge has both ends on one side (a self-loop always does) or `left` names a
    /// non-vertex.
    ///
    /// Repeats in `left` are one vertex. Each side lists its vertices in `vertices` order.
    ///
    /// - Parameter left: The vertices to put on the left.
    /// - Returns: The bipartition, or `nil`.
    /// - Complexity: O(n + m + k) for k elements of `left`, plus one hash per vertex for a graph
    ///   without vertex indices.
    @inlinable
    public func bipartition(left: some Sequence<Vertex>) -> Bipartition<Self>? {
        let numbering = _vertexNumbering()
        var sides = [Int8](repeating: 1, count: vertexIndexBound ?? vertexCount)
        if let numbers = numbering?.numbers {
            for vertex in left {
                guard let v = numbers[vertex] else { return nil }
                sides[v] = 0
            }
        } else {
            for vertex in left {
                guard contains(vertex) else { return nil }
                sides[vertexIndex(of: vertex)] = 0
            }
        }
        guard _runOnUndirectedRows(_SidesCheck(sides: sides), vertexNumbering: numbering) else { return nil }
        return Bipartition(self, listed: numbering?.listed, sides: sides)
    }

    /// An odd cycle, or `nil` when the graph is bipartite.
    ///
    /// The cycle is the first one a breadth-first two-colouring meets (roots in `vertices` order,
    /// rows in `incidentEdges` order), closed through the lowest common ancestor of the
    /// conflicting edge's ends in the search tree. It is not necessarily a shortest odd cycle. A
    /// self-loop is an odd cycle of length 1. The cycle is in Cycles' canonical form: it starts at
    /// its least vertex and leaves through the lesser of its two edges.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func findOddCycle() -> Cycle<Vertex, Edges.Index>? {
        guard let (vs, es) = _runOnUndirectedRows(_TwoColoring(witness: true)).cycle else { return nil }
        let listed = _listedVertices()
        let vertices = vs.map { _vertex(number: $0, listed) }
        return Cycle(_uncheckedVertices: vertices, edges: _positions(ofEdgeNumbers: es))
    }
}
