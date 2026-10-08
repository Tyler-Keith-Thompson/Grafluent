import CompressedSparseRowModule
import GraphProtocols

/// Tarjan's algorithm over vertex numbers `0..<count`, iterative, roots in increasing number, in
/// Pearce's space-efficient form (as petgraph's): one word per vertex holds its preorder number
/// while it is on the stack, its lowlink as that improves, and finally its component. Returns a
/// component label per vertex, components numbered in the order they complete, and the number of
/// components. With `stopAfterFirst`, returns as soon as one component completes, with a count of
/// 1 and that component's size; the labels are then meaningless.
@inlinable
@inline(__always)
package func _tarjan<Neighbors: IteratorProtocol<Int>>(
    count n: Int,
    stopAfterFirst: Bool = false,
    _ neighbors: (Int) -> Neighbors
) -> (labels: [Int], count: Int, firstSize: Int) {
    // 0 until reached; then the preorder number (from 1), lowered to the least preorder number
    // reachable through vertices not yet in a component; then, once its component completes,
    // Int.max - component, which is greater than every preorder number.
    var rindex = [Int](repeating: 0, count: n)
    var components = 0
    var firstSize = 0
    rindex.withUnsafeMutableBufferPointer { rindex in
        var index = 1
        var component = Int.max
        // Vertices whose component is not complete and that are not roots of one.
        var stack: [Int] = []
        // The search path; a vertex is stored as ~v once it is known not to be a component root.
        var path: [Int] = []
        var iterators: [Neighbors] = []
        search: for start in 0 ..< n where rindex[start] == 0 {
            rindex[start] = index
            index += 1
            path.append(start)
            iterators.append(neighbors(start))
            while let entry = path.last {
                let top = path.count - 1
                let v = entry < 0 ? ~entry : entry
                if let w = iterators[top].next() {
                    if rindex[w] == 0 {
                        rindex[w] = index
                        index += 1
                        path.append(w)
                        iterators.append(neighbors(w))
                    } else if rindex[w] < rindex[v] {
                        rindex[v] = rindex[w]
                        path[top] = ~v
                    }
                    continue
                }
                path.removeLast()
                iterators.removeLast()
                if entry >= 0 {
                    var size = 1
                    while let w = stack.last, rindex[v] <= rindex[w] {
                        stack.removeLast()
                        rindex[w] = component
                        size += 1
                    }
                    rindex[v] = component
                    component -= 1
                    if stopAfterFirst {
                        firstSize = size
                        break search
                    }
                } else {
                    stack.append(v)
                }
                if let u = path.last {
                    let parent = u < 0 ? ~u : u
                    if rindex[v] < rindex[parent] {
                        rindex[parent] = rindex[v]
                        path[path.count - 1] = ~parent
                    }
                }
            }
        }
        components = Int.max - component
        if !stopAfterFirst {
            for v in 0 ..< n { rindex[v] = Int.max - rindex[v] }
        }
    }
    return (rindex, components, firstSize)
}

extension DirectedGraph {
    /// Runs Tarjan's algorithm in index space when the graph has vertex indices, otherwise over
    /// numbers assigned in `vertices` order.
    @inlinable
    @inline(__always)
    func _stronglyConnected(_ vertices: _DenseVertices<Self>, stopAfterFirst: Bool = false) -> (labels: [Int], count: Int, firstSize: Int) {
        if vertices.isIndexed {
            let n = vertices.count
            if let result = _withSuccessorIndexRows({ offsets, targets in
                _tarjan(count: n, stopAfterFirst: stopAfterFirst) { _RowCursor(row: $0, offsets: offsets, targets: targets) }
            }) {
                return result
            }
            return _tarjan(count: n, stopAfterFirst: stopAfterFirst) { successorIndices(ofIndex: $0).makeIterator() }
        }
        return _tarjan(count: vertices.count, stopAfterFirst: stopAfterFirst) { u in
            successors(of: vertices.vertices[u]).lazy.map { vertices.numbers[$0]! }.makeIterator()
        }
    }

    /// The strongly connected components: maximal sets of vertices each reaching every other.
    /// Tarjan's algorithm, iterative, O(V + E).
    ///
    /// Components are in the order Tarjan's algorithm completes them, on a depth-first search
    /// with roots in `vertices` order and successors in `successors(of:)` order (the order of
    /// NetworkX, petgraph and Boost). That is a reverse topological order of the condensation:
    /// every edge between components goes from a later component to an earlier one, so
    /// `reversed()` lists the components with every edge going forward. Each component lists its
    /// vertices in `vertices` order.
    @inlinable
    public func stronglyConnectedComponents() -> Components<Self> {
        let vertices = _DenseVertices(self)
        let (labels, count, _) = _stronglyConnected(vertices)
        return Components(vertices: vertices, labels: labels, count: count)
    }

    /// Whether every vertex reaches every other: one strongly connected component. False for the
    /// empty graph, so this is `stronglyConnectedComponents().count == 1`. O(V + E), stopping
    /// when the first component completes.
    @inlinable
    public var isStronglyConnected: Bool {
        let vertices = _DenseVertices(self)
        guard vertices.count > 0 else { return false }
        return _stronglyConnected(vertices, stopAfterFirst: true).firstSize == vertices.count
    }

    /// The condensation: the strongly connected components, and the acyclic graph with a vertex
    /// per component and an edge from one component to another wherever an edge of this graph
    /// joins them (NetworkX's and petgraph's `condensation`, Boost's
    /// `create_condensation_graph`).
    @inlinable
    public func condensation() -> Condensation<Self> {
        let vertices = _DenseVertices(self)
        let (labels, count, _) = _stronglyConnected(vertices)
        let (offsets, order) = _groups(labels: labels, count: count)
        // One row per component, built a component at a time; `seen` drops repeats.
        var rowOffsets = [Int](repeating: 0, count: count + 1)
        var targets: [Int] = []
        var seen = [Int](repeating: -1, count: count)
        for c in 0 ..< count {
            let rowStart = targets.count
            for u in order[offsets[c] ..< offsets[c + 1]] {
                func visit(_ w: Int) {
                    let d = labels[w]
                    if d != c, seen[d] != c {
                        seen[d] = c
                        targets.append(d)
                    }
                }
                if vertices.isIndexed {
                    for w in successorIndices(ofIndex: u) { visit(w) }
                } else {
                    for w in successors(of: vertices.vertices[u]) { visit(vertices.numbers[w]!) }
                }
            }
            if targets.count - rowStart > 1 { targets[rowStart...].sort() }
            rowOffsets[c + 1] = targets.count
        }
        // Rows are ascending, without repeats or loops, and in range: no validation needed.
        let graph = CompressedSparseRow(_offsets: rowOffsets, _targets: targets)
        let components = Components(vertices: vertices, labels: labels, offsets: offsets, order: order)
        return Condensation(components: components, graph: graph)
    }

    /// The attracting components: the strongly connected components that no edge leaves, in
    /// component order (NetworkX's `attracting_components`). A self-loop does not leave. Each is a
    /// slice of one shared array, as in `Components`, so its indices do not start at 0.
    @inlinable
    public func attractingComponents() -> [ArraySlice<Vertex>] {
        let vertices = _DenseVertices(self)
        let (labels, count, _) = _stronglyConnected(vertices)
        var leaks = [Bool](repeating: false, count: count)
        for u in 0 ..< vertices.count {
            let c = labels[u]
            if leaks[c] { continue }
            if vertices.isIndexed {
                for w in successorIndices(ofIndex: u) where labels[w] != c {
                    leaks[c] = true
                    break
                }
            } else {
                for w in successors(of: vertices.vertices[u]) where labels[vertices.numbers[w]!] != c {
                    leaks[c] = true
                    break
                }
            }
        }
        let components = Components(vertices: vertices, labels: labels, count: count)
        return components.indices.filter { !leaks[$0] }.map { components[$0] }
    }
}

/// A graph's strongly connected components and the acyclic graph between them.
@frozen
public struct Condensation<G: DirectedGraph> {
    /// The strongly connected components, in the order of `stronglyConnectedComponents()`.
    public let components: Components<G>

    /// The graph on `0..<components.count` in which vertex `i` stands for `components[i]`, with
    /// an edge `i → j` when some edge of the original graph goes from `components[i]` to
    /// `components[j]`, `i != j`. No self-loops or repeated edges; each row is ascending; every
    /// edge goes from a higher index to a lower one, so it is acyclic.
    public let graph: CompressedSparseRow

    @inlinable
    init(components: Components<G>, graph: CompressedSparseRow) {
        self.components = components
        self.graph = graph
    }
}

extension Condensation: Sendable where G: Sendable, G.Vertex: Sendable {}
