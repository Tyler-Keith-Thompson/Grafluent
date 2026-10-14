import CompressedSparseRowModule
import Connectivity
import GraphProtocols

/// A graph's strongly connected components in index space: each vertex index's component, and
/// each component's members ascending, from Connectivity's condensation.
@frozen
@usableFromInline
struct _IndexedComponents {
    /// The condensation graph: vertex `c` is component `c`, every arc from a higher component to
    /// a lower one.
    @usableFromInline let dag: CompressedSparseRow
    /// The members of component `c`: `members[offsets[c] ..< offsets[c + 1]]`, ascending.
    @usableFromInline let offsets: [Int]
    @usableFromInline let members: [Int]
    /// Each vertex index's component.
    @usableFromInline let component: [Int]

    @inlinable
    init<G: DirectedGraph>(_ graph: G, count n: Int) {
        let condensation = graph.condensation()
        let k = condensation.graph.vertexCount
        var component = [Int](repeating: 0, count: n)
        var offsets = [Int](repeating: 0, count: k &+ 1)
        for v in 0 ..< n {
            let c = condensation.components.component(ofIndex: v)
            component[v] = c
            offsets[c &+ 1] &+= 1
        }
        for c in 0 ..< k { offsets[c &+ 1] &+= offsets[c] }
        var next = offsets
        var members = [Int](repeating: 0, count: n)
        for v in 0 ..< n {
            let c = component[v]
            members[next[c]] = v
            next[c] &+= 1
        }
        dag = condensation.graph
        self.offsets = offsets
        self.members = members
        self.component = component
    }

    @inlinable
    var count: Int { offsets.count &- 1 }

    /// The components reachable from each component by at least one arc, as bit rows of `words`
    /// words: computed in increasing component order, since every arc goes to a lower component.
    /// O(k · e / 64) time and k² / 8 bytes for k components and e condensation arcs.
    @inlinable
    func descendants() -> (rows: [UInt64], words: Int) {
        let k = count
        let words = (k &+ 63) &>> 6
        var rows = [UInt64](repeating: 0, count: k &* words)
        rows.withUnsafeMutableBufferPointer { rows in
            for c in 0 ..< k {
                let row = c &* words
                for d in dag.successorIndices(ofIndex: c) {
                    rows[row &+ d &>> 6] |= UInt64(1) &<< UInt64(d & 63)
                    let other = d &* words
                    var w = 0
                    // Component d is lower than c, so its row is final.
                    while w <= d &>> 6 {
                        rows[row &+ w] |= rows[other &+ w]
                        w &+= 1
                    }
                }
            }
        }
        return (rows, words)
    }
}

extension _DirectedGraphConstruction {
    /// The transitive closure of `graph`, which may have cycles: an arc u → v for every pair of
    /// distinct vertices with a directed path from u to v. Not reflexive: a vertex on a cycle
    /// gets no self-loop (the construction targets take none). Vertex `i` is the graph's vertex
    /// at index `i`.
    ///
    /// Computed on the condensation: the components reachable from each component, as bit rows,
    /// then each vertex's row as the members of those components and of its own.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The closure on `0..<n`.
    /// - Complexity: O(n + m + k · e / 64 + the output and its row sorts) time and k² / 8 bytes
    ///   of scratch, for k strongly connected components and e arcs between them.
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public static func transitiveClosure<G: DirectedGraph>(of graph: G) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "transitiveClosure(of:)")
        let components = _IndexedComponents(graph, count: n)
        let k = components.count
        let (rows, words) = components.descendants()
        // Each component's reach, own members included: the sorted vertex list every member's row
        // is drawn from.
        var reachOffsets = [Int](repeating: 0, count: k &+ 1)
        var reach: [Int] = []
        for c in 0 ..< k {
            let start = reach.count
            reach.append(contentsOf: components.members[components.offsets[c] ..< components.offsets[c &+ 1]])
            let row = c &* words
            for w in 0 ..< words {
                var bits = rows[row &+ w]
                while bits != 0 {
                    let d = w &<< 6 | bits.trailingZeroBitCount
                    reach.append(contentsOf: components.members[components.offsets[d] ..< components.offsets[d &+ 1]])
                    bits &= bits &- 1
                }
            }
            reach[start...].sort()
            reachOffsets[c &+ 1] = reach.count
        }
        var edges: [DirectedEdge<Int>] = []
        for v in 0 ..< n {
            let c = components.component[v]
            for e in reachOffsets[c] ..< reachOffsets[c &+ 1] {
                let w = reach[e]
                if w != v { edges.append(DirectedEdge(from: v, to: w)) }
            }
        }
        return Self(_vertexCount: n, sortedEdges: edges, _ConstructionToken())
    }

    /// A transitive reduction of `graph`, which may have cycles: a graph with the fewest arcs that
    /// has the same reachability, by Aho, Garey and Ullman's construction. Each strongly connected
    /// component of two or more vertices becomes a cycle through its members in index order,
    /// and each arc of the condensation's transitive reduction becomes one arc between the two
    /// components' first members (by index). On an acyclic graph it is the unique transitive
    /// reduction, a subgraph; otherwise it need not be one. Vertex `i` is the graph's vertex at
    /// index `i`.
    ///
    /// - Parameter graph: The graph.
    /// - Returns: The reduction on `0..<n`.
    /// - Complexity: O(n + m + k · e / 64) time and k² / 8 bytes of scratch, for k strongly
    ///   connected components and e arcs between them.
    /// - Precondition: the graph has vertex indices.
    @inlinable
    public static func transitiveReduction<G: DirectedGraph>(of graph: G) -> Self {
        let n = _requireIndices(graph.vertexIndexBound, "transitiveReduction(of:)")
        let components = _IndexedComponents(graph, count: n)
        let k = components.count
        let (rows, words) = components.descendants()
        var sources: [Int] = [], targets: [Int] = []
        // The cycle through each nontrivial component.
        for c in 0 ..< k {
            let start = components.offsets[c], end = components.offsets[c &+ 1]
            if end &- start < 2 { continue }
            for p in start ..< end {
                sources.append(components.members[p])
                targets.append(components.members[p &+ 1 < end ? p &+ 1 : start])
            }
        }
        // An arc c → d of the condensation is redundant when d is a descendant of another
        // successor of c.
        var far = [UInt64](repeating: 0, count: words)
        for c in 0 ..< k {
            for d in components.dag.successorIndices(ofIndex: c) {
                let other = d &* words
                for w in 0 ... d &>> 6 { far[w] |= rows[other &+ w] }
            }
            for d in components.dag.successorIndices(ofIndex: c) where far[d &>> 6] & (UInt64(1) &<< UInt64(d & 63)) == 0 {
                sources.append(components.members[components.offsets[c]])
                targets.append(components.members[components.offsets[d]])
            }
            for w in 0 ..< words { far[w] = 0 }
        }
        let sorted = _SortedRows(count: n, sources: sources, targets: targets)
        return Self(_vertexCount: n, sortedEdges: sorted.directedEdges(), _ConstructionToken())
    }
}
