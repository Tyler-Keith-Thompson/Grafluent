import GraphProtocols

/// The storage every tree type shares: vertices by number (`vertices` order), each edge's two
/// ends, incidence rows in position order, and a rooting (a root per tree, each vertex's parent,
/// parent edge, depth, and the preorder with each subtree's size, so a subtree is an interval of
/// it). About eighteen `Int`s per vertex (plus the vertex table when the vertices are not the
/// `Int`s `0..<n`), in a constant number of arrays. A vertex's rooting is one 56-byte record, so
/// building or reading it touches one or two cache lines rather than seven arrays.
@frozen
@usableFromInline
package struct _TreeNode: Sendable {
    /// −1 at a root.
    @usableFromInline package var parent: Int
    @usableFromInline package var parentEdge: Int
    /// The offset of the parent edge in the vertex's row; −1 at a root.
    @usableFromInline package var parentOffset: Int
    @usableFromInline package var depth: Int
    @usableFromInline package var preorderPosition: Int
    @usableFromInline package var size: Int
    /// The vertex's tree, as an offset in `roots`.
    @usableFromInline package var component: Int

    @inlinable
    init() {
        parent = -1
        parentEdge = -1
        parentOffset = -1
        depth = -1
        preorderPosition = 0
        size = 1
        component = -1
    }
}

@frozen
@usableFromInline
package struct _TreeLayout<Vertex: Hashable> {
    @usableFromInline package var vertices: ContiguousArray<Vertex>
    /// Each vertex's number; empty when `dense` (the vertices are the `Int`s `0..<n` in order).
    @usableFromInline package var slots: [Vertex: Int]
    @usableFromInline package var dense: Bool
    /// Each edge's ends as given: (u, v), or (parent, child) for an arborescence.
    @usableFromInline package var ends: [Int]
    @usableFromInline package var rowOffsets: [Int]
    @usableFromInline package var rowNeighbors: [Int]
    @usableFromInline package var rowEdges: [Int]
    /// For each slot of the rows, the offset of the same edge's other end in its row.
    @usableFromInline package var twin: [Int]

    // The rooting.
    @usableFromInline package var roots: [Int]
    @usableFromInline package var nodes: [_TreeNode]
    @usableFromInline package var preorder: [Int]
    @usableFromInline package var height: Int

    /// Unrooted: the rooting is set by `root(at:)`.
    @inlinable
    init(vertices: ContiguousArray<Vertex>, slots: [Vertex: Int], dense: Bool, ends: [Int], rowOffsets: [Int], rowNeighbors: [Int], rowEdges: [Int], twin: [Int]) {
        self.vertices = vertices
        self.slots = slots
        self.dense = dense
        self.ends = ends
        self.rowOffsets = rowOffsets
        self.rowNeighbors = rowNeighbors
        self.rowEdges = rowEdges
        self.twin = twin
        roots = []
        nodes = []
        preorder = []
        height = 0
    }

    @inlinable
    package var count: Int { vertices.count }

    @inlinable
    package var edgeCount: Int { ends.count / 2 }

    /// The number of `vertex`. Precondition: it is a vertex.
    @inlinable @inline(__always)
    package func number(of vertex: Vertex) -> Int {
        guard let v = Self.lookup(vertex, vertices, slots, dense) else { preconditionFailure("The vertex is not in the tree") }
        return v
    }

    @inlinable
    func contains(_ vertex: Vertex) -> Bool { Self.lookup(vertex, vertices, slots, dense) != nil }

    /// Whether `a` is a proper ancestor of `b`, by numbers.
    @inlinable @inline(__always)
    func isAncestor(_ a: Int, of b: Int) -> Bool {
        let pa = nodes[a].preorderPosition, pb = nodes[b].preorderPosition
        return pa < pb && pb < pa + nodes[a].size
    }

    /// The child end of edge `e` in this rooting.
    @inlinable @inline(__always)
    func child(ofEdge e: Int) -> Int {
        let a = ends[2 * e], b = ends[2 * e + 1]
        return nodes[a].parentEdge == e ? a : b
    }

    /// The path between `a` and `b` in their tree, as vertex and edge numbers; nil when they are
    /// in different trees.
    @inlinable
    package func path(_ a: Int, _ b: Int) -> (vertices: [Int], edges: [Int])? {
        guard nodes[a].component == nodes[b].component else { return nil }
        var up: [Int] = [a], upEdges: [Int] = []
        var down: [Int] = [b], downEdges: [Int] = []
        var x = a, y = b
        while nodes[x].depth > nodes[y].depth {
            upEdges.append(nodes[x].parentEdge)
            x = nodes[x].parent
            up.append(x)
        }
        while nodes[y].depth > nodes[x].depth {
            downEdges.append(nodes[y].parentEdge)
            y = nodes[y].parent
            down.append(y)
        }
        while x != y {
            upEdges.append(nodes[x].parentEdge)
            x = nodes[x].parent
            up.append(x)
            downEdges.append(nodes[y].parentEdge)
            y = nodes[y].parent
            down.append(y)
        }
        up.append(contentsOf: down.dropLast().reversed())
        upEdges.append(contentsOf: downEdges.reversed())
        return (up, upEdges)
    }
}

extension _TreeLayout: Sendable where Vertex: Sendable {}

// MARK: - Building

extension _TreeLayout {
    /// Whether the vertices are the `Int`s `0..<n` in order. Allocates nothing.
    @inlinable
    static func isDense(_ vertices: ContiguousArray<Vertex>) -> Bool {
        guard Vertex.self == Int.self else { return false }
        for (i, v) in vertices.enumerated() where unsafeBitCast(v, to: Int.self) != i { return false }
        return true
    }

    /// Trees this small find a vertex's number by a linear scan instead of a table.
    @inlinable
    static var smallCount: Int { 8 }

    /// The numbering of a list of distinct vertices: `dense` when they are the `Int`s `0..<n` in
    /// order, so no table is needed; no table either for a tree of at most `smallCount` vertices.
    /// `table`, when given, is the vertex → number table the caller already built.
    @inlinable
    static func numbering(_ vertices: ContiguousArray<Vertex>, table: [Vertex: Int]? = nil) -> (slots: [Vertex: Int], dense: Bool) {
        if isDense(vertices) { return ([:], true) }
        if vertices.count <= smallCount { return ([:], false) }
        if let table { return (table, false) }
        var slots: [Vertex: Int] = [:]
        slots.reserveCapacity(vertices.count)
        for (i, v) in vertices.enumerated() { slots[v] = i }
        return (slots, false)
    }

    /// The number of `vertex` in a numbering, or nil.
    @inlinable
    static func lookup(_ vertex: Vertex, _ vertices: ContiguousArray<Vertex>, _ slots: [Vertex: Int], _ dense: Bool) -> Int? {
        if dense, Vertex.self == Int.self {
            let v = unsafeBitCast(vertex, to: Int.self)
            return UInt(bitPattern: v) < UInt(bitPattern: vertices.count) ? v : nil
        }
        if slots.isEmpty { return vertices.firstIndex(of: vertex) }
        return slots[vertex]
    }

    /// Distinct vertices from a list (duplicates dropped) and then the edges' endpoints by first
    /// appearance, with the edges' ends as numbers: `UndirectedAdjacencyList(vertices:edges:)`'s
    /// order. A repeated edge stays repeated. When the `Int` vertices come out as `0..<n` in order
    /// (each new endpoint the next `Int`), nothing is hashed (`dense`).
    @inlinable
    static func gather<Edges: Sequence>(
        vertices listed: some Sequence<Vertex>, edges: Edges, ends endpoints: (Edges.Element) -> (Vertex, Vertex)
    ) -> (vertices: ContiguousArray<Vertex>, slots: [Vertex: Int], dense: Bool, ends: [Int]) {
        let list = ContiguousArray(listed)
        guard Vertex.self == Int.self, isDense(list) else { return gatherHashing(list, edges, endpoints) }
        // First appearance keeps the numbering dense while each endpoint is a vertex already
        // seen or the next `Int`.
        var count = list.count
        var ends: [Int] = []
        ends.reserveCapacity(2 * max(count - 1, 0))
        let edgeList = Array(edges)
        for edge in edgeList {
            let (u, v) = endpoints(edge)
            let a = unsafeBitCast(u, to: Int.self)
            if a == count {
                count += 1
            } else if UInt(bitPattern: a) >= UInt(bitPattern: count) {
                return gatherHashing(list, edgeList, endpoints)
            }
            let b = unsafeBitCast(v, to: Int.self)
            if b == count {
                count += 1
            } else if UInt(bitPattern: b) >= UInt(bitPattern: count) {
                return gatherHashing(list, edgeList, endpoints)
            }
            ends.append(a)
            ends.append(b)
        }
        var vertices = list
        for x in list.count ..< count { vertices.append(unsafeBitCast(x, to: Vertex.self)) }
        return (vertices, [:], true, ends)
    }

    @inlinable
    static func gatherHashing<Edges: Sequence>(
        _ listed: ContiguousArray<Vertex>, _ edges: Edges, _ endpoints: (Edges.Element) -> (Vertex, Vertex)
    ) -> (vertices: ContiguousArray<Vertex>, slots: [Vertex: Int], dense: Bool, ends: [Int]) {
        var vertices = ContiguousArray<Vertex>()
        var slots: [Vertex: Int] = [:]
        slots.reserveCapacity(listed.count)
        func number(_ v: Vertex) -> Int {
            if let k = slots[v] { return k }
            slots[v] = vertices.count
            vertices.append(v)
            return vertices.count - 1
        }
        for v in listed { _ = number(v) }
        var ends: [Int] = []
        for edge in edges {
            let (u, v) = endpoints(edge)
            ends.append(number(u))
            ends.append(number(v))
        }
        let (table, dense) = numbering(vertices, table: slots)
        return (vertices, table, dense, ends)
    }

    /// A one-vertex tree, without building rows.
    @inlinable
    static func single(_ vertex: Vertex) -> Self {
        let vertices: ContiguousArray<Vertex> = [vertex]
        var layout = Self(vertices: vertices, slots: [:], dense: isDense(vertices), ends: [], rowOffsets: [0, 0], rowNeighbors: [], rowEdges: [], twin: [])
        var node = _TreeNode()
        node.depth = 0
        node.component = 0
        layout.nodes = [node]
        layout.preorder = [0]
        layout.roots = [0]
        return layout
    }

    /// Builds the rows and roots the graph: from `root` (one tree, which must reach every
    /// vertex), or from each vertex not yet reached, in order (a forest). Nil when the edges hold
    /// a cycle (a loop and a parallel pair included), when one root does not reach every vertex,
    /// or, with `oriented`, when an edge does not point away from the root.
    @inlinable
    static func build(
        vertices: ContiguousArray<Vertex>, slots: [Vertex: Int], dense: Bool, ends: [Int], root: Int?, oriented: Bool = false
    ) -> Self? {
        let n = vertices.count, m = ends.count / 2
        if let root {
            guard m == n - 1, root >= 0, root < n else { return nil }
        } else {
            guard m <= max(n - 1, 0) else { return nil }
        }
        var degree = [Int](repeating: 0, count: n + 1)
        for x in ends {
            guard UInt(bitPattern: x) < UInt(bitPattern: n) else { return nil }
            degree[x + 1] += 1
        }
        for v in 0 ..< n { degree[v + 1] += degree[v] }
        let rowOffsets = degree
        var fill = degree
        var rowNeighbors = [Int](repeating: 0, count: 2 * m)
        var rowEdges = [Int](repeating: 0, count: 2 * m)
        // Each slot's twin: the offset of the edge's other end in its row.
        var twin = [Int](repeating: 0, count: 2 * m)
        for e in 0 ..< m {
            let a = ends[2 * e], b = ends[2 * e + 1]
            let sa = fill[a]
            fill[a] += 1
            let sb = fill[b]
            fill[b] += 1
            rowNeighbors[sa] = b
            rowEdges[sa] = e
            rowNeighbors[sb] = a
            rowEdges[sb] = e
            twin[sa] = sb - rowOffsets[b]
            twin[sb] = sa - rowOffsets[a]
        }
        var layout = Self(vertices: vertices, slots: slots, dense: dense, ends: ends, rowOffsets: rowOffsets, rowNeighbors: rowNeighbors, rowEdges: rowEdges, twin: twin)
        guard layout.root(at: root, oriented: oriented) else { return nil }
        return layout
    }

    /// See `build`.
    @inlinable
    init?(vertices: ContiguousArray<Vertex>, slots: [Vertex: Int], dense: Bool, ends: [Int], root: Int?, oriented: Bool = false) {
        guard let layout = Self.build(vertices: vertices, slots: slots, dense: dense, ends: ends, root: root, oriented: oriented) else { return nil }
        self = layout
    }

    /// Roots the rows (see `build`); false on a cycle, an unreached vertex or a misoriented edge.
    /// One iterative depth-first walk writes each vertex's record when it is reached (its
    /// preorder position then) and adds its subtree's size to its parent's when it is left.
    @inlinable
    mutating func root(at root: Int?, oriented: Bool = false) -> Bool {
        let n = vertices.count
        var nodes = [_TreeNode](repeating: _TreeNode(), count: n)
        var preorder: [Int] = []
        preorder.reserveCapacity(n)
        var roots: [Int] = []
        var height = 0
        var stack: [(v: Int, k: Int, end: Int)] = []
        var next = 0
        while true {
            let r: Int
            if let root {
                guard roots.isEmpty else { break }
                r = root
            } else {
                while next < n, nodes[next].depth >= 0 { next += 1 }
                guard next < n else { break }
                r = next
            }
            let tree = roots.count
            roots.append(r)
            nodes[r].depth = 0
            nodes[r].component = tree
            nodes[r].preorderPosition = preorder.count
            preorder.append(r)
            stack.append((r, rowOffsets[r], rowOffsets[r + 1]))
            while let (v, k, end) = stack.last {
                guard k < end else {
                    stack.removeLast()
                    let p = nodes[v].parent
                    if p >= 0 { nodes[p].size += nodes[v].size }
                    continue
                }
                stack[stack.count - 1].k = k + 1
                let e = rowEdges[k]
                let node = nodes[v]
                if e == node.parentEdge { continue }
                let w = rowNeighbors[k]
                // Reaching a vertex already reached, by any edge but the one we came by: a cycle.
                guard nodes[w].depth < 0 else { return false }
                if oriented, ends[2 * e] != v { return false }
                let depth = node.depth + 1
                if depth > height { height = depth }
                nodes[w].parent = v
                nodes[w].parentEdge = e
                nodes[w].parentOffset = twin[k]
                nodes[w].depth = depth
                nodes[w].component = tree
                nodes[w].preorderPosition = preorder.count
                preorder.append(w)
                stack.append((w, rowOffsets[w], rowOffsets[w + 1]))
            }
        }
        guard preorder.count == n else { return false }
        self.nodes = nodes
        self.preorder = preorder
        self.roots = roots
        self.height = height
        return true
    }

    /// The same rows rooted at `root` (one tree). O(n).
    @inlinable
    func rerooted(at root: Int) -> Self {
        if roots.count == 1, roots[0] == root { return self }
        var copy = self
        let rooted = copy.root(at: root)
        precondition(rooted, "A tree reroots")
        return copy
    }
}

// MARK: - Reading graphs

extension Graph {
    /// The graph's vertices and each edge's ends as vertex numbers, in `edges` order. With vertex
    /// and edge indices the ends come from the index rows, so no vertex is hashed; otherwise from
    /// `edges` through a vertex table.
    @inlinable
    func _treeInput() -> (vertices: ContiguousArray<Vertex>, ends: [Int], table: [Vertex: Int]?)? {
        let vertices = ContiguousArray(self.vertices)
        let m = edgeCount
        var ends = [Int](repeating: -1, count: 2 * m)
        if let n = vertexIndexBound, edgeIndexBound != nil {
            for v in 0 ..< n {
                var neighbors = neighborIndices(ofIndex: v).makeIterator()
                for position in incidentEdges(ofIndex: v) {
                    guard let w = neighbors.next() else { preconditionFailure("neighborIndices and incidentEdges differ in length") }
                    let e = edgeIndex(of: position)
                    guard UInt(bitPattern: e) < UInt(bitPattern: m), UInt(bitPattern: w) < UInt(bitPattern: n) else { return nil }
                    if ends[2 * e] < 0 {
                        ends[2 * e] = v
                        ends[2 * e + 1] = w
                    }
                }
                precondition(neighbors.next() == nil, "neighborIndices and incidentEdges differ in length")
            }
            // Orientation as the graph has it: `edges[e].u` first.
            for (e, edge) in edges.enumerated() {
                guard ends[2 * e] >= 0 else { return nil }
                if edge.u != vertices[ends[2 * e]] { ends.swapAt(2 * e, 2 * e + 1) }
            }
            return (vertices, ends, nil)
        }
        var numbers: [Vertex: Int] = [:]
        numbers.reserveCapacity(vertices.count)
        for (i, v) in vertices.enumerated() { numbers[v] = i }
        for (e, edge) in edges.enumerated() {
            guard let a = numbers[edge.u], let b = numbers[edge.v] else { return nil }
            ends[2 * e] = a
            ends[2 * e + 1] = b
        }
        return (vertices, ends, numbers)
    }
}

extension DirectedGraph {
    /// The graph's vertices and each edge's (source, target) as vertex numbers, in `edges` order;
    /// from the index rows when the graph has vertex and edge indices.
    @inlinable
    func _treeInput() -> (vertices: ContiguousArray<Vertex>, ends: [Int], table: [Vertex: Int]?)? {
        let vertices = ContiguousArray(self.vertices)
        let m = edgeCount
        var ends = [Int](repeating: -1, count: 2 * m)
        if let n = vertexIndexBound, edgeIndexBound != nil {
            for v in 0 ..< n {
                var targets = successorIndices(ofIndex: v).makeIterator()
                for position in outEdges(ofIndex: v) {
                    guard let w = targets.next() else { preconditionFailure("successorIndices and outEdges differ in length") }
                    let e = edgeIndex(of: position)
                    guard UInt(bitPattern: e) < UInt(bitPattern: m), UInt(bitPattern: w) < UInt(bitPattern: n), ends[2 * e] < 0 else { return nil }
                    ends[2 * e] = v
                    ends[2 * e + 1] = w
                }
                precondition(targets.next() == nil, "successorIndices and outEdges differ in length")
            }
            guard !ends.contains(-1) else { return nil }
            return (vertices, ends, nil)
        }
        var numbers: [Vertex: Int] = [:]
        numbers.reserveCapacity(vertices.count)
        for (i, v) in vertices.enumerated() { numbers[v] = i }
        for (e, edge) in edges.enumerated() {
            guard let a = numbers[edge.source], let b = numbers[edge.target] else { return nil }
            ends[2 * e] = a
            ends[2 * e + 1] = b
        }
        return (vertices, ends, numbers)
    }
}
