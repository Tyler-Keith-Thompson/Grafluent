import AdjacencyListModule
import Connectivity
import DisjointSetModule
import GraphProtocols
import OrderedCollections

// Algorithms written once on `DirectedHypergraph`, in index space (see HypergraphAlgorithms.swift).
// The definitions follow Gallo, Longo, Pallottino and Nguyen, "Directed hypergraphs and
// applications" (1993).

extension DirectedHypergraph {
    /// Both index bounds, trapping with a message when a conformer lacks one.
    @inlinable
    package func _indexBounds() -> (n: Int, m: Int) {
        guard let n = vertexIndexBound, let m = hyperedgeIndexBound else {
            preconditionFailure("\(Self.self) has no vertex or hyperedge indices, which the hypergraph algorithms need")
        }
        return (n, m)
    }

    /// The positions in index order: `hyperedges` is in index order.
    @inlinable
    package func _positions() -> [Hyperedges.Index] {
        Array(hyperedges.indices)
    }

    /// One side of each hyperedge, by index, as its vertex indices: the transpose of the plane.
    @inlinable
    internal func _transposedPlane(vertexCount n: Int, hyperedgeCount m: Int, targets: Bool) -> _IncidencePlane {
        var offsets = ContiguousArray<Int>()
        offsets.reserveCapacity(n + 1)
        offsets.append(0)
        var flat = ContiguousArray<Int>()
        for i in 0 ..< n {
            for h in targets ? inHyperedgeIndices(ofIndex: i) : outHyperedgeIndices(ofIndex: i) { flat.append(h) }
            offsets.append(flat.count)
        }
        return _IncidencePlane(vertexCount: m, offsets: offsets, members: flat)
    }
}

// MARK: - Dual, classes, histograms

extension DirectedHypergraph {
    /// The dual: the transpose of each plane. Its vertices are this hypergraph's positions, in
    /// order, and its hyperedge `i` has sources `outHyperedges(ofIndex: i)` and targets
    /// `inHyperedges(ofIndex: i)`. An isolated vertex becomes the empty hyperedge `{} → {}`, and
    /// back.
    ///
    /// - Complexity: O(n + m + p) expected: m position hashes, no vertex hashed.
    @inlinable
    public func dual() -> IncidenceList<Hyperedges.Index> {
        let (n, m) = _indexBounds()
        return IncidenceList(_uncheckedVertices: OrderedSet(uncheckedUniqueElements: _positions()),
                             sources: _transposedPlane(vertexCount: n, hyperedgeCount: m, targets: false),
                             targets: _transposedPlane(vertexCount: n, hyperedgeCount: m, targets: true))
    }

    /// Whether every hyperedge has exactly one target: a B-graph (backward hypergraph). Vacuously
    /// true with no hyperedges. O(m).
    @inlinable
    public var isBHypergraph: Bool {
        hyperedges.indices.allSatisfy { targetSize(ofHyperedgeAt: $0) == 1 }
    }

    /// Whether every hyperedge has exactly one source: an F-graph (forward hypergraph). Vacuously
    /// true with no hyperedges. O(m).
    @inlinable
    public var isFHypergraph: Bool {
        hyperedges.indices.allSatisfy { sourceSize(ofHyperedgeAt: $0) == 1 }
    }

    /// Whether every hyperedge has exactly one target or exactly one source: a BF-graph. Vacuously
    /// true with no hyperedges. O(m).
    @inlinable
    public var isBFHypergraph: Bool {
        hyperedges.indices.allSatisfy { targetSize(ofHyperedgeAt: $0) == 1 || sourceSize(ofHyperedgeAt: $0) == 1 }
    }

    @inlinable
    internal func _histogram(count: Int, _ value: (Int) -> Int) -> [Int] {
        var histogram: [Int] = []
        for k in 0 ..< count {
            let d = value(k)
            if d >= histogram.count { histogram.append(contentsOf: repeatElement(0, count: d - histogram.count + 1)) }
            histogram[d] += 1
        }
        return histogram
    }

    /// Element `d` counts the vertices with `d` out-hyperedges; `[]` with no vertices. O(n).
    @inlinable
    public func outDegreeHistogram() -> [Int] {
        _histogram(count: _indexBounds().n) { outDegree(ofIndex: $0) }
    }

    /// Element `d` counts the vertices with `d` in-hyperedges; `[]` with no vertices. O(n).
    @inlinable
    public func inDegreeHistogram() -> [Int] {
        _histogram(count: _indexBounds().n) { inDegree(ofIndex: $0) }
    }

    /// Element `k` counts the hyperedges with `k` sources; `[]` with no hyperedges. O(m).
    @inlinable
    public func sourceSizeHistogram() -> [Int] {
        let positions = _positions()
        return _histogram(count: positions.count) { sourceSize(ofHyperedgeAt: positions[$0]) }
    }

    /// Element `k` counts the hyperedges with `k` targets; `[]` with no hyperedges. O(m).
    @inlinable
    public func targetSizeHistogram() -> [Int] {
        let positions = _positions()
        return _histogram(count: positions.count) { targetSize(ofHyperedgeAt: positions[$0]) }
    }
}

// MARK: - Clique expansion

extension DirectedHypergraph {
    /// The directed clique expansion: every vertex, isolated ones included, in vertex-index order,
    /// and an arc `u → v` when some hyperedge has `u` among its sources and `v` among its targets,
    /// `u ≠ v`, once per pair. Arcs ascend by (index of u, index of v). A hyperedge with an empty
    /// side adds none.
    ///
    /// - Complexity: O(n + Σ |S|·|T| + e log d) for e arcs. Building the result hashes each vertex
    ///   once (none for the vertices `0..<n` in order) and no vertex per arc.
    @inlinable
    public func cliqueExpansion() -> AdjacencyList<Vertex> {
        let (n, _) = _indexBounds()
        let positions = _positions()
        var stamp = [Int](repeating: -1, count: n)
        var edges: [DirectedEdge<Int>] = []
        var found: [Int] = []
        for u in 0 ..< n {
            found.removeAll(keepingCapacity: true)
            stamp[u] = u
            for h in outHyperedgeIndices(ofIndex: u) {
                for w in targetIndices(ofHyperedgeAt: positions[h]) where stamp[w] != u {
                    stamp[w] = u
                    found.append(w)
                }
            }
            found.sort()
            for w in found { edges.append(DirectedEdge(from: u, to: w)) }
        }
        var vertices = ContiguousArray<Vertex>()
        vertices.reserveCapacity(n)
        for i in 0 ..< n { vertices.append(vertex(atIndex: i)) }
        return AdjacencyList(_uncheckedVertices: vertices, sortedSlotEdges: edges)
    }
}

// MARK: - Components

extension DirectedHypergraph {
    /// The weakly connected components: vertices joined through either side of a chain of
    /// hyperedges. Ordered by least vertex index, each in index order; an isolated vertex is alone.
    ///
    /// - Complexity: O(n + p α(n)), union–find over both sides.
    @inlinable
    public func weaklyConnectedComponents() -> [[Vertex]] {
        let (n, _) = _indexBounds()
        var sets = DisjointSet(count: n)
        _unionSides(&sets)
        return sets.sets().map { $0.map { self.vertex(atIndex: $0) } }
    }

    /// Whether there is exactly one weakly connected component; false with no vertices.
    @inlinable
    public var isWeaklyConnected: Bool {
        let (n, _) = _indexBounds()
        var sets = DisjointSet(count: n)
        _unionSides(&sets)
        return sets.setCount == 1
    }

    @inlinable
    internal func _unionSides(_ sets: inout DisjointSet) {
        for position in hyperedges.indices {
            var first = -1
            _forEachMemberIndex(ofHyperedgeAt: position) { v in
                if first < 0 { first = v } else { sets.union(first, v) }
            }
        }
    }

    /// The strongly connected components: `u` and `v` are together when each reaches the other
    /// along source → hyperedge → target steps (Gallo et al.'s "connected": a path in the
    /// incidence graph). They are the strong components of `incidenceGraphView` restricted to the
    /// vertices, ordered by least vertex index, each in index order. Mutual B-connection is a
    /// different, finer relation.
    ///
    /// - Complexity: O(n + m + p): the incidence graph's rows copied into flat arrays, then
    ///   Tarjan's algorithm, iteratively.
    @inlinable
    public func stronglyConnectedComponents() -> [[Vertex]] {
        let (n, _) = _indexBounds()
        let component = _strongComponentLabels()
        var groups: [[Vertex]] = []
        var label = [Int](repeating: -1, count: component.count)
        for i in 0 ..< n {
            let c = component[i]
            if label[c] < 0 {
                label[c] = groups.count
                groups.append([])
            }
            groups[label[c]].append(vertex(atIndex: i))
        }
        return groups
    }

    /// Whether there is exactly one strongly connected component; false with no vertices.
    @inlinable
    public var isStronglyConnected: Bool {
        let (n, _) = _indexBounds()
        guard n > 0 else { return false }
        let component = _strongComponentLabels()
        let first = component[0]
        for i in 1 ..< n where component[i] != first { return false }
        return true
    }

    /// For each node of the incidence graph (vertex indices, then `n +` hyperedge index), the
    /// number of its strong component, by Connectivity's Tarjan.
    @inlinable
    internal func _strongComponentLabels() -> [Int] {
        let (n, m) = _indexBounds()
        let count = n + m
        // The incidence graph's successor rows, flat.
        var offsets = [Int](repeating: 0, count: count + 1)
        var total = 0
        for i in 0 ..< n { total &+= outDegree(ofIndex: i) }
        for position in hyperedges.indices { total &+= targetSize(ofHyperedgeAt: position) }
        var targets: [Int] = []
        targets.reserveCapacity(total)
        for i in 0 ..< n {
            for h in outHyperedgeIndices(ofIndex: i) { targets.append(n &+ h) }
            offsets[i + 1] = targets.count
        }
        var p = n
        for position in hyperedges.indices {
            for j in targetIndices(ofHyperedgeAt: position) { targets.append(j) }
            p &+= 1
            offsets[p] = targets.count
        }
        return offsets.withUnsafeBufferPointer { offsets in
            targets.withUnsafeBufferPointer { targets in
                _tarjan(count: count) { _RowCursor(row: $0, offsets: offsets, targets: targets) }.labels
            }
        }
    }
}

// MARK: - B- and F-connection

extension DirectedHypergraph {
    /// Gallo et al.'s B-Visit from vertex index `start`, or F-Visit (B-Visit on the symmetric
    /// image) when `backward`: a counter per hyperedge of its sources not yet reached (targets,
    /// backward); a hyperedge fires when it reaches 0 and then reaches all its targets (sources).
    /// Stops early once `stop` is reached. Returns whether each vertex index was reached.
    @inlinable
    internal func _visit(from start: Int, backward: Bool, stop: Int = -1) -> [Bool] {
        let (n, m) = _indexBounds()
        let positions = _positions()
        var remaining = [Int](repeating: 0, count: m)
        for h in 0 ..< m {
            remaining[h] = backward ? targetSize(ofHyperedgeAt: positions[h]) : sourceSize(ofHyperedgeAt: positions[h])
        }
        var reached = [Bool](repeating: false, count: n)
        reached[start] = true
        if start == stop { return reached }
        var queue = [start]
        var head = 0
        while head < queue.count {
            let u = queue[head]
            head &+= 1
            for p in backward ? inHyperedgeIndices(ofIndex: u) : outHyperedgeIndices(ofIndex: u) {
                remaining[p] &-= 1
                guard remaining[p] == 0 else { continue }
                let position = positions[p]
                for w in backward ? sourceIndices(ofHyperedgeAt: position) : targetIndices(ofHyperedgeAt: position) where !reached[w] {
                    reached[w] = true
                    if w == stop { return reached }
                    queue.append(w)
                }
            }
        }
        return reached
    }

    @inlinable
    internal func _reachedVertices(_ reached: [Bool]) -> [Vertex] {
        var result: [Vertex] = []
        for (i, isReached) in reached.enumerated() where isReached { result.append(vertex(atIndex: i)) }
        return result
    }

    /// Every vertex B-connected to `source`, `source` included, in vertex-index order: Gallo et
    /// al.'s B-Visit. A hyperedge fires once every one of its sources has been reached, and then
    /// reaches all its targets. On a directed graph read as a hypergraph this is reachability.
    ///
    /// B-connection is path-based, as B-Visit computes it: `v` is B-connected to `source` when `v`
    /// is `source`, or some hyperedge with `v` among its targets is entered along a path from
    /// `source` (it has a source, and all its sources are B-connected). A hyperedge with no
    /// sources therefore never fires.
    ///
    /// - Precondition: `source` is a vertex.
    /// - Complexity: O(n + m + p): one counter per hyperedge and one queue; one hash.
    @inlinable
    public func bConnectedVertices(from source: Vertex) -> [Vertex] {
        _reachedVertices(_visit(from: vertexIndex(of: source), backward: false))
    }

    /// Whether `target` is B-connected to `source`: B-Visit from `source`, stopping at `target`.
    ///
    /// - Precondition: both are vertices.
    /// - Complexity: O(n + m + p); two hashes.
    @inlinable
    public func isBConnected(from source: Vertex, to target: Vertex) -> Bool {
        let s = vertexIndex(of: source), t = vertexIndex(of: target)
        return _visit(from: s, backward: false, stop: t)[t]
    }

    /// Every vertex `s` such that `target` is F-connected to `s`, `target` included, in
    /// vertex-index order: Gallo et al.'s F-Visit, which is B-Visit on the symmetric image. It
    /// equals `reversed.bConnectedVertices(from: target)`, and a hyperedge with no targets never
    /// fires.
    ///
    /// - Precondition: `target` is a vertex.
    /// - Complexity: O(n + m + p); one hash.
    @inlinable
    public func fConnectedVertices(to target: Vertex) -> [Vertex] {
        _reachedVertices(_visit(from: vertexIndex(of: target), backward: true))
    }

    /// Whether there is an F-path from `source` to `target`: one whose symmetric image is a B-path
    /// from `target` to `source`, so every target of a hyperedge it uses must lead on to `target`.
    /// F-Visit from `target`, stopping at `source`.
    ///
    /// - Precondition: both are vertices.
    /// - Complexity: O(n + m + p); two hashes.
    @inlinable
    public func isFConnected(from source: Vertex, to target: Vertex) -> Bool {
        let s = vertexIndex(of: source), t = vertexIndex(of: target)
        return _visit(from: t, backward: true, stop: s)[s]
    }
}
