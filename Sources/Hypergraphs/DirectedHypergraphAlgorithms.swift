import AdjacencyListModule
import DisjointSetModule
import GraphProtocols
import OrderedCollections

// Algorithms written once on `DirectedHypergraph`, in index space (see HypergraphAlgorithms.swift).
// The definitions follow G. Gallo, G. Longo, S. Pallottino, S. Nguyen, "Directed hypergraphs and
// applications", Discrete Applied Mathematics 42(2–3):177–201, 1993, doi:10.1016/0166-218X(93)90045-P.

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
    /// The dual: the transpose of each plane (SimpleDirectedHypergraphs.jl's convention, and
    /// `OrientedIncidenceMatrix.transposed()`). Its vertices are this hypergraph's positions, in
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

    /// Whether every hyperedge has exactly one target: a B-graph (Gallo et al.'s backward
    /// hypergraph; halp's `is_B_hypergraph`). Vacuously true with no hyperedges. O(m).
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

    /// Element `k` counts the hyperedges with `k` sources (XGI's `tail_size`); `[]` with no
    /// hyperedges. O(m).
    @inlinable
    public func sourceSizeHistogram() -> [Int] {
        let positions = _positions()
        return _histogram(count: positions.count) { sourceSize(ofHyperedgeAt: positions[$0]) }
    }

    /// Element `k` counts the hyperedges with `k` targets (XGI's `head_size`); `[]` with no
    /// hyperedges. O(m).
    @inlinable
    public func targetSizeHistogram() -> [Int] {
        let positions = _positions()
        return _histogram(count: positions.count) { targetSize(ofHyperedgeAt: positions[$0]) }
    }
}

// MARK: - Clique expansion

extension DirectedHypergraph {
    /// The directed clique expansion (SimpleDirectedHypergraphs.jl's `TwoSectionView`): every
    /// vertex, isolated ones included, in vertex-index order, and an arc `u → v` when some
    /// hyperedge has `u` among its sources and `v` among its targets, `u ≠ v`, once per pair.
    /// Arcs ascend by (index of u, index of v). A hyperedge with an empty side adds none.
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
    /// incidence graph). They are the strong components of `incidenceGraph` restricted to the
    /// vertices, ordered by least vertex index, each in index order. Mutual B-connection
    /// (SimpleDirectedHypergraphs.jl's `get_strongly_connected_components`) is a different,
    /// finer relation.
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
    /// number of its strong component, by Tarjan's algorithm.
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
        var component = [Int](repeating: -1, count: count)
        var order = [Int](repeating: -1, count: count)
        var low = [Int](repeating: 0, count: count)
        // The Tarjan stack, and the depth-first path as (node, next successor slot) pairs.
        var stack = [Int](repeating: 0, count: count)
        var pathNodes = [Int](repeating: 0, count: count)
        var pathCursors = [Int](repeating: 0, count: count)
        offsets.withUnsafeBufferPointer { offsets in
            targets.withUnsafeBufferPointer { targets in
                component.withUnsafeMutableBufferPointer { component in
                    order.withUnsafeMutableBufferPointer { order in
                        low.withUnsafeMutableBufferPointer { low in
                            stack.withUnsafeMutableBufferPointer { stack in
                                pathNodes.withUnsafeMutableBufferPointer { pathNodes in
                                    pathCursors.withUnsafeMutableBufferPointer { pathCursors in
                                        var counter = 0, components = 0, stackTop = 0
                                        for root in 0 ..< count where order[root] < 0 {
                                            order[root] = counter
                                            low[root] = counter
                                            counter &+= 1
                                            stack[stackTop] = root
                                            stackTop &+= 1
                                            pathNodes[0] = root
                                            pathCursors[0] = offsets[root]
                                            var depth = 1
                                            while depth > 0 {
                                                let node = pathNodes[depth &- 1]
                                                let cursor = pathCursors[depth &- 1]
                                                if cursor < offsets[node &+ 1] {
                                                    pathCursors[depth &- 1] = cursor &+ 1
                                                    let next = targets[cursor]
                                                    if order[next] < 0 {
                                                        order[next] = counter
                                                        low[next] = counter
                                                        counter &+= 1
                                                        stack[stackTop] = next
                                                        stackTop &+= 1
                                                        pathNodes[depth] = next
                                                        pathCursors[depth] = offsets[next]
                                                        depth &+= 1
                                                    } else if component[next] < 0, order[next] < low[node] {
                                                        low[node] = order[next]
                                                    }
                                                    continue
                                                }
                                                depth &-= 1
                                                if depth > 0 {
                                                    let parent = pathNodes[depth &- 1]
                                                    if low[node] < low[parent] { low[parent] = low[node] }
                                                }
                                                if low[node] == order[node] {
                                                    while true {
                                                        stackTop &-= 1
                                                        let w = stack[stackTop]
                                                        component[w] = components
                                                        if w == node { break }
                                                    }
                                                    components &+= 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return component
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
    /// al.'s B-Visit (halp's `b_visit`). A hyperedge fires once every one of its sources has been
    /// reached, and then reaches all its targets. On a directed graph read as a hypergraph this is
    /// reachability.
    ///
    /// B-connection here is path-based, as B-Visit computes it: `v` is B-connected to `source`
    /// when `v` is `source`, or some hyperedge with `v` among its targets is entered along a path
    /// from `source` (it has a source, and all its sources are B-connected). So **a hyperedge with
    /// no sources never fires**: no path enters it, and B-Visit scans only the forward stars of
    /// reached vertices. The recursive reading ("every source is B-connected") would fire it
    /// vacuously from any start; Gallo et al.'s visit and halp do not.
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
    /// vertex-index order. Gallo et al.: "the F-Visit must start from the destination of the
    /// F-paths to retain a linear time complexity"; it is B-Visit on the symmetric image, so it
    /// equals `reversed.bConnectedVertices(from: target)` (halp's `f_visit`), and a hyperedge with
    /// no targets never fires.
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
