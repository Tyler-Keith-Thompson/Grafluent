import GraphProtocols

/// An algorithm over an undirected graph's rows in index space: vertex numbers `0..<count` in
/// `vertices` order, and edge numbers `0..<edgeCount` in `edges` order. `arcs(v)` gives
/// `(w, e)` for every edge end at `v`, in `incidentEdges` order: the neighbor's number and the
/// edge's number, a self-loop twice with `w == v`.
@usableFromInline
protocol _UndirectedRowsAlgorithm {
    associatedtype Output
    func run<Arcs: IteratorProtocol>(count: Int, edgeCount: Int, _ arcs: (Int) -> Arcs) -> Output where Arcs.Element == (Int, Int)
}

extension Graph {
    /// Runs `algorithm` over the cheapest rows the graph offers. With vertex and edge indices,
    /// `neighborIndices` beside `incidentEdgeIndices`, so nothing is hashed (the edge-order law
    /// makes an edge's index its number). With vertex indices only, `incidentEdges(ofIndex:)` and
    /// one dictionary lookup per edge end. Without vertex indices, `incidentEdges(of:)` and two.
    @inlinable
    func _runOnUndirectedRows<A: _UndirectedRowsAlgorithm>(_ algorithm: A) -> A.Output {
        let m = edgeCount
        if let n = vertexIndexBound {
            if edgeIndexBound != nil {
                return algorithm.run(count: n, edgeCount: m) { v in
                    zip(neighborIndices(ofIndex: v), incidentEdgeIndices(ofIndex: v)).makeIterator()
                }
            }
            let numbers = _edgeNumbers()
            return algorithm.run(count: n, edgeCount: m) { v in
                zip(neighborIndices(ofIndex: v), incidentEdges(ofIndex: v)).lazy.map { ($0.0, numbers[$0.1]!) }.makeIterator()
            }
        }
        let listed = Array(vertices)
        var numbers: [Vertex: Int] = [:]
        numbers.reserveCapacity(listed.count)
        for (i, v) in listed.enumerated() { numbers[v] = i }
        let edgeNumbers = edgeIndexBound != nil ? [:] : _edgeNumbers()
        let indexed = edgeIndexBound != nil
        return algorithm.run(count: listed.count, edgeCount: m) { v in
            let vertex = listed[v]
            return incidentEdges(of: vertex).lazy.map { position in
                (numbers[oppositeVertex(to: vertex, acrossEdgeAt: position)]!, indexed ? edgeIndex(of: position) : edgeNumbers[position]!)
            }.makeIterator()
        }
    }

    /// Each edge position's offset in `edges`.
    @inlinable
    func _edgeNumbers() -> [Edges.Index: Int] {
        var numbers: [Edges.Index: Int] = [:]
        numbers.reserveCapacity(edgeCount)
        for (k, position) in edges.indices.enumerated() { numbers[position] = k }
        return numbers
    }

    /// The number of the edge at `position`: its edge index, or its offset in `edges`.
    @inlinable
    func _edgeNumber(of position: Edges.Index, _ numbers: [Edges.Index: Int]) -> Int {
        edgeIndexBound != nil ? edgeIndex(of: position) : numbers[position]!
    }
}

/// Connected components by union–find over the rows, each non-loop edge once (at its lower end),
/// labelled by first vertex: the labels and their count.
@frozen
@usableFromInline
struct _UndirectedComponents: _UndirectedRowsAlgorithm {
    /// Stop once this many joins have succeeded (n − 1 means connected).
    @usableFromInline let limit: Int

    @inlinable
    init(limit: Int = .max) { self.limit = limit }

    @inlinable
    func run<Arcs: IteratorProtocol>(count n: Int, edgeCount: Int, _ arcs: (Int) -> Arcs) -> (labels: [Int], count: Int, joins: Int) where Arcs.Element == (Int, Int) {
        var parent = [Int](repeating: -1, count: n)
        var labels = [Int](repeating: -1, count: n)
        var joins = 0
        let count = parent.withUnsafeMutableBufferPointer { parent in
            @inline(__always)
            func find(_ x: Int) -> Int {
                var x = x
                while parent[x] >= 0 {
                    let up = parent[x]
                    if parent[up] >= 0 { parent[x] = parent[up] }
                    x = up
                }
                return x
            }
            var v = 0
            while v < n, joins < limit {
                var out = arcs(v)
                while let (w, _) = out.next() {
                    guard v < w else { continue }
                    var a = find(v), b = find(w)
                    if a == b { continue }
                    if parent[a] > parent[b] { swap(&a, &b) }
                    parent[a] += parent[b]
                    parent[b] = a
                    joins += 1
                }
                v += 1
            }
            return labels.withUnsafeMutableBufferPointer { labels in
                var count = 0
                for v in 0 ..< n {
                    let r = find(v)
                    if labels[r] < 0 {
                        labels[r] = count
                        count += 1
                    }
                    labels[v] = labels[r]
                }
                return count
            }
        }
        return (labels, count, joins)
    }
}
