import GraphProtocols

/// Prim's algorithm with an array of keys in place of a heap (Prim's original form, and the dense
/// case in Cormen et al.): each step scans the keys of the vertices outside the tree for the
/// least, takes it, and relaxes that vertex's arcs. O(n² + m), which beats the heap's O(m log n)
/// once m is near n². Keys are compared under the strict order (weight, rank), so with distinct
/// ranks the forest is the unique minimum spanning forest under that order, whichever vertex each
/// tree starts from.
///
/// `arcs(u)` gives `(v, position)` for every edge end at `u`; `weight` and `rank` read an edge
/// once, from the end spanned first, and never for a self-loop. With no keyed vertex left
/// outside the tree a new tree starts, so every component is spanned. Returns each taken edge
/// with its weight, rank and ends, in the order taken; `placeholder` fills storage no edge has
/// reached and is never returned.
///
/// The keys of the vertices outside the tree are packed at the front of `keyWeight` and
/// `keyRank`, so each scan reads contiguous memory that shrinks by one a step.
///
/// - Precondition: no weight is NaN.
@inlinable
package func _densePrim<W: Comparable & AdditiveArithmetic, Position, Arcs: IteratorProtocol>(
    count n: Int, placeholder: Position,
    weight: (Position) -> W, rank: (Position) -> Int, arcs: (Int) -> Arcs
) -> [(position: Position, weight: W, rank: Int, parent: Int, child: Int)] where Arcs.Element == (Int, Position) {
    // `outside[s]` is the vertex at slot s; `slot[v]` is v's slot, or -1 once v is in the tree.
    var outside = [Int](0 ..< n)
    var slot = [Int](0 ..< n)
    // A slot's key: the lightest edge from the tree, -1 rank when none yet.
    var keyWeight = [W](repeating: .zero, count: n)
    var keyRank = [Int](repeating: -1, count: n)
    // Each vertex's key edge and the tree vertex it leads from.
    var keyPosition = [Position](repeating: placeholder, count: n)
    var keyParent = [Int](repeating: -1, count: n)
    var taken: [(position: Position, weight: W, rank: Int, parent: Int, child: Int)] = []
    taken.reserveCapacity(Swift.max(0, n - 1))
    outside.withUnsafeMutableBufferPointer { outside in
        slot.withUnsafeMutableBufferPointer { slot in
            keyWeight.withUnsafeMutableBufferPointer { keyWeight in
                keyRank.withUnsafeMutableBufferPointer { keyRank in
                    var remaining = n
                    while remaining > 0 {
                        var best = -1
                        for s in 0 ..< remaining where keyRank[s] >= 0 {
                            if best < 0 || keyWeight[s] < keyWeight[best]
                                || (!(keyWeight[best] < keyWeight[s]) && keyRank[s] < keyRank[best]) {
                                best = s
                            }
                        }
                        // No edge leaves the tree: start the next one at any vertex outside.
                        let s = best < 0 ? 0 : best
                        let u = outside[s]
                        if best >= 0 { taken.append((keyPosition[u], keyWeight[s], keyRank[s], keyParent[u], u)) }
                        // Move the last slot into u's.
                        remaining -= 1
                        let last = outside[remaining]
                        outside[s] = last
                        slot[last] = s
                        keyWeight[s] = keyWeight[remaining]
                        keyRank[s] = keyRank[remaining]
                        slot[u] = -1
                        var out = arcs(u)
                        while let (v, position) = out.next() {
                            precondition(UInt(bitPattern: v) < UInt(bitPattern: n), "A neighbor index is out of range")
                            let t = slot[v]
                            guard t >= 0 else { continue }
                            let w = weight(position)
                            precondition(w == w, "An edge weight is NaN")
                            let r = rank(position)
                            if keyRank[t] < 0 || w < keyWeight[t] || (!(keyWeight[t] < w) && r < keyRank[t]) {
                                keyWeight[t] = w
                                keyRank[t] = r
                                keyPosition[v] = position
                                keyParent[v] = u
                            }
                        }
                    }
                }
            }
        }
    }
    return taken
}

extension Graph {
    /// Whether the canonical Prim should scan an array of keys rather than use a heap: vertex
    /// indices, and at least n²/4 edges.
    @inlinable
    var _prefersDensePrim: Bool {
        guard let n = vertexIndexBound, n > 0 else { return false }
        let (square, overflow) = n.multipliedReportingOverflow(by: n)
        return !overflow && edgeCount >= square / 4
    }

    /// The canonical forest's edges by dense Prim, in the order taken, with weights and ranks.
    ///
    /// - Precondition: `vertexIndexBound != nil`.
    @inlinable
    func _densePrim<W: Comparable & AdditiveArithmetic>(_ weight: (Edges.Index) -> W) -> [(position: Edges.Index, weight: W, rank: Int)] {
        let n = vertexIndexBound!
        let placeholder = edges.startIndex
        let taken: [(position: Edges.Index, weight: W, rank: Int, parent: Int, child: Int)]
        if edgeIndexBound != nil {
            taken = SpanningTrees._densePrim(count: n, placeholder: placeholder, weight: weight, rank: { edgeIndex(of: $0) }) { u in
                zip(neighborIndices(ofIndex: u), incidentEdges(ofIndex: u)).makeIterator()
            }
        } else {
            let ranks = Dictionary(uniqueKeysWithValues: edges.indices.enumerated().map { ($1, $0) })
            taken = SpanningTrees._densePrim(count: n, placeholder: placeholder, weight: weight, rank: { ranks[$0]! }) { u in
                zip(neighborIndices(ofIndex: u), incidentEdges(ofIndex: u)).makeIterator()
            }
        }
        return taken.map { ($0.position, $0.weight, $0.rank) }
    }
}
