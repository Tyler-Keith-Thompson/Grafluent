import GraphProtocols

extension DirectedAcyclicGraph {
    /// The places of `vertices` in `places`, marking each in `marks` (by place) with `true`;
    /// nil at the first that is not a vertex.
    @inlinable
    internal func _mark(_ vertices: some Sequence<Vertex>, _ places: _Places, _ marks: inout [Bool]) -> [Int]? {
        var listed: [Int] = []
        for vertex in vertices {
            guard let key = _base._key(of: vertex) else { return nil }
            let place = places.place(ofKey: key)
            if !marks[place] {
                marks[place] = true
                listed.append(place)
            }
        }
        return listed
    }

    /// Marks in `marks` every ancestor of the places in `from`, and those places, by a search over
    /// predecessors. O(n + m).
    @inlinable
    internal func _markAncestors(of from: [Int], _ places: _Places, _ marks: inout [Bool]) {
        for p in from { marks[p] = true }
        var stack = from
        while let p = stack.popLast() {
            for key in _base._predecessorKeys(ofKey: places.key(atPlace: p)) {
                let q = places.place(ofKey: key)
                if !marks[q] {
                    marks[q] = true
                    stack.append(q)
                }
            }
        }
    }

    /// Whether `z` d-separates `x` from `y` (Pearl): every trail between a vertex of `x` and one of
    /// `y` is blocked by `z`, at a chain or fork in `z` or at a collider with neither itself nor a
    /// descendant in `z`. True when `x` or `y` is empty. Shachter's Bayes-ball: a search over
    /// (vertex, direction) states from `x`, in which a ball coming down into a vertex of `z`
    /// bounces back up to its parents, so an open collider is found through its descendant.
    ///
    /// - Precondition: every element is a vertex, and `x`, `y` and `z` are pairwise disjoint.
    /// - Complexity: O(n + m).
    @inlinable
    public func isDSeparator(_ z: some Sequence<Vertex>, between x: some Sequence<Vertex>, and y: some Sequence<Vertex>) -> Bool {
        let places = _places()
        let n = _order.count
        var inX = [Bool](repeating: false, count: n), inY = inX, inZ = inX
        guard let xs = _mark(x, places, &inX), let ys = _mark(y, places, &inY), let zs = _mark(z, places, &inZ) else {
            preconditionFailure("An element of x, y or z is not a vertex of the graph")
        }
        precondition(!ys.contains { inX[$0] } && !zs.contains { inX[$0] || inY[$0] }, "x, y and z must be disjoint")
        // States: reached from a child (going up) or from a parent (going down).
        var up = [Bool](repeating: false, count: n), down = up
        var stack: [(place: Int, fromChild: Bool)] = []
        for p in xs {
            up[p] = true
            stack.append((p, true))
        }
        while let (p, fromChild) = stack.popLast() {
            if inY[p] { return false }
            let key = places.key(atPlace: p)
            if fromChild {
                guard !inZ[p] else { continue }
                for next in _base._predecessorKeys(ofKey: key) {
                    let q = places.place(ofKey: next)
                    if !up[q] {
                        up[q] = true
                        stack.append((q, true))
                    }
                }
                for next in _base._successorKeys(ofKey: key) {
                    let q = places.place(ofKey: next)
                    if !down[q] {
                        down[q] = true
                        stack.append((q, false))
                    }
                }
            } else {
                if !inZ[p] {
                    for next in _base._successorKeys(ofKey: key) {
                        let q = places.place(ofKey: next)
                        if !down[q] {
                            down[q] = true
                            stack.append((q, false))
                        }
                    }
                }
                if inZ[p] {
                    for next in _base._predecessorKeys(ofKey: key) {
                        let q = places.place(ofKey: next)
                        if !up[q] {
                            up[q] = true
                            stack.append((q, true))
                        }
                    }
                }
            }
        }
        return true
    }

    /// Whether `z` d-separates `x` from `y`, throwing instead of trapping when an element of `x`,
    /// `y` or `z` is not a vertex.
    ///
    /// - Precondition: `x`, `y` and `z` are pairwise disjoint.
    /// - Throws: `VertexNotFound` when an element is not a vertex of the graph.
    @inlinable
    public func isDSeparator(checked z: some Sequence<Vertex>, between x: some Sequence<Vertex>, and y: some Sequence<Vertex>) throws(VertexNotFound) -> Bool {
        let z = Array(z), x = Array(x), y = Array(y)
        for v in x where !contains(v) { throw VertexNotFound() }
        for v in y where !contains(v) { throw VertexNotFound() }
        for v in z where !contains(v) { throw VertexNotFound() }
        return isDSeparator(z, between: x, and: y)
    }

    /// The places reachable from `from` by van der Zander and Liśkiewicz's ball passing within
    /// `allowed` given `z`: a ball at v, having come in along an edge into v (`intoV`) or out of
    /// it, moves to each neighbor n in `allowed` when v is not in `z`, or when it came in along an
    /// edge into v and leaves to a parent. The vertices of `from` are reached. `allowed` is
    /// closed under parents (a set of ancestors), so only children are checked against it.
    @inlinable
    internal func _ballReach(_ from: [Int], _ places: _Places, allowed: [Bool], z: [Bool]) -> [Bool] {
        let n = _order.count
        var reached = [Bool](repeating: false, count: n)
        // processed[2p] for (into, p), processed[2p + 1] for (out of, p).
        var processed = [Bool](repeating: false, count: 2 * n)
        var stack: [(place: Int, intoV: Bool)] = []
        for p in from {
            reached[p] = true
            let key = places.key(atPlace: p)
            if _base._predecessorKeys(ofKey: key).contains(where: { _ in true }), !processed[2 * p] {
                processed[2 * p] = true
                stack.append((p, true))
            }
            if _base._successorKeys(ofKey: key).contains(where: { _ in true }), !processed[2 * p + 1] {
                processed[2 * p + 1] = true
                stack.append((p, false))
            }
        }
        while let (p, intoV) = stack.popLast() {
            let key = places.key(atPlace: p)
            // To a parent: the edge points away from it (state "out of"), allowed even at a
            // member of z when the ball came in along an edge into p.
            if !z[p] || intoV {
                for next in _base._predecessorKeys(ofKey: key) {
                    let q = places.place(ofKey: next)
                    if !processed[2 * q + 1] {
                        processed[2 * q + 1] = true
                        reached[q] = true
                        stack.append((q, false))
                    }
                }
            }
            if !z[p] {
                for next in _base._successorKeys(ofKey: key) {
                    let q = places.place(ofKey: next)
                    if allowed[q], !processed[2 * q] {
                        processed[2 * q] = true
                        reached[q] = true
                        stack.append((q, true))
                    }
                }
            }
        }
        return reached
    }

    /// A minimal d-separator of `x` and `y` with `including ⊆ z ⊆ restrictedTo` (van der Zander
    /// and Liśkiewicz): no proper subset of it holding `including` d-separates them. In
    /// `vertices` order, or nil when no such set d-separates them. `restrictedTo` nil allows every
    /// vertex. The ancestors of `x`, `y` and `including`, then two ball-passing searches.
    ///
    /// - Precondition: every element is a vertex; `x`, `y` and `including` are pairwise disjoint;
    ///   `including` is inside `restrictedTo`.
    /// - Complexity: O(n + m).
    @inlinable
    public func minimalDSeparator(between x: some Sequence<Vertex>, and y: some Sequence<Vertex>, including: [Vertex] = [], restrictedTo restricted: [Vertex]? = nil) -> [Vertex]? {
        let places = _places()
        let n = _order.count
        var inX = [Bool](repeating: false, count: n), inY = inX, inI = inX
        guard let xs = _mark(x, places, &inX), let ys = _mark(y, places, &inY), let included = _mark(including, places, &inI) else {
            preconditionFailure("An element of x, y or including is not a vertex of the graph")
        }
        var allowed = [Bool](repeating: restricted == nil, count: n)
        if let restricted {
            guard _mark(restricted, places, &allowed) != nil else { preconditionFailure("An element of restrictedTo is not a vertex of the graph") }
        }
        precondition(!ys.contains { inX[$0] } && !included.contains { inX[$0] || inY[$0] }, "x, y and including must be disjoint")
        precondition(!included.contains { !allowed[$0] }, "including must be inside restrictedTo")
        var ancestral = [Bool](repeating: false, count: n)
        _markAncestors(of: xs + ys + included, places, &ancestral)
        // Candidates outside the ancestors are never reached, so they drop out at the first
        // update: only the restriction and x and y are excluded here.
        var z = (0 ..< n).map { allowed[$0] && !inX[$0] && !inY[$0] }
        let fromX = _ballReach(xs, places, allowed: ancestral, z: z)
        if ys.contains(where: { fromX[$0] }) { return nil }
        for p in 0 ..< n where z[p] && !fromX[p] && !inI[p] { z[p] = false }
        let fromY = _ballReach(ys, places, allowed: ancestral, z: z)
        var keys: [Int] = []
        for p in 0 ..< n where z[p] && (fromY[p] || inI[p]) { keys.append(places.key(atPlace: p)) }
        // Keys are the base's vertex indices, which follow `vertices` order.
        keys.sort()
        return keys.map { _base._vertex(atKey: $0) }
    }

    /// `minimalDSeparator(between:and:including:restrictedTo:)`, throwing instead of trapping
    /// when an element is not a vertex.
    ///
    /// - Precondition: `x`, `y` and `including` are pairwise disjoint; `including` is inside
    ///   `restrictedTo`.
    /// - Throws: `VertexNotFound` when an element is not a vertex of the graph.
    @inlinable
    public func minimalDSeparator(checkedBetween x: some Sequence<Vertex>, and y: some Sequence<Vertex>, including: [Vertex] = [], restrictedTo restricted: [Vertex]? = nil) throws(VertexNotFound) -> [Vertex]? {
        let x = Array(x), y = Array(y)
        for v in x where !contains(v) { throw VertexNotFound() }
        for v in y where !contains(v) { throw VertexNotFound() }
        for v in including where !contains(v) { throw VertexNotFound() }
        for v in restricted ?? [] where !contains(v) { throw VertexNotFound() }
        return minimalDSeparator(between: x, and: y, including: including, restrictedTo: restricted)
    }
}

extension _GraphConstruction {
    /// The moral graph of a directed acyclic graph: every edge without its direction, and an edge
    /// between every two parents of a vertex (they are "married"). Vertex `k` is the `k`th vertex
    /// of `graph.vertices`; parallel edges are joined once. O(n + Σᵥ indeg(v)² + the sort).
    @inlinable
    public static func moralGraph<Base>(of graph: DirectedAcyclicGraph<Base>) -> Self {
        let base = graph.base
        let keys = Array(base.vertices.indices)
        var number = [Int](repeating: -1, count: (keys.last ?? -1) + 1)
        for (i, key) in keys.enumerated() { number[key] = i }
        var pairs: [UndirectedEdge<Int>] = []
        var parents: [Int] = []
        for (v, key) in keys.enumerated() {
            parents.removeAll(keepingCapacity: true)
            for p in base._predecessorKeys(ofKey: key) { parents.append(number[p]) }
            parents.sort()
            var distinct = 0
            for i in parents.indices where i == 0 || parents[i] != parents[i - 1] {
                parents[distinct] = parents[i]
                distinct += 1
            }
            for i in 0 ..< distinct {
                let u = parents[i]
                pairs.append(u < v ? UndirectedEdge(u, v) : UndirectedEdge(v, u))
                for j in i + 1 ..< distinct { pairs.append(UndirectedEdge(u, parents[j])) }
            }
        }
        pairs.sort { ($0.u, $0.v) < ($1.u, $1.v) }
        var edges: [UndirectedEdge<Int>] = []
        edges.reserveCapacity(pairs.count)
        for edge in pairs where edges.last != edge { edges.append(edge) }
        return Self(_vertexCount: keys.count, sortedEdges: edges, _ConstructionToken())
    }
}
