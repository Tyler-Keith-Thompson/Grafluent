import GraphProtocols

/// An edit path from one graph to another, as returned by `optimalEditPath(to:)`: each vertex and
/// edge of this graph (the pattern) is substituted by one of `other` (the target) or deleted, and
/// every vertex and edge of the target that is no substitute is inserted.
///
/// It holds both graphs, the image of each pattern vertex and edge, the path's total cost and
/// whether the search proved it optimal. Members exist when both graphs are `Graph`s or both are
/// `DirectedGraph`s.
@frozen
public struct EditPath<Pattern, Target, Cost> {
    @usableFromInline let pattern: Pattern
    @usableFromInline let target: Target
    /// `_VertexNumbers<Pattern.Vertex>` for a pattern without vertex indices, else nil.
    @usableFromInline let patternNumbers: AnyObject?
    /// `_VertexNumbers<Target.Vertex>` for a target without vertex indices, else nil.
    @usableFromInline let targetNumbers: AnyObject?
    /// `_EditPositions<Pattern.Edges.Index, Target.Edges.Index>`: both graphs' edge positions.
    @usableFromInline let positions: AnyObject
    /// By pattern vertex number: the target vertex's number, or −1 when the vertex is deleted.
    @usableFromInline let vertexImages: [Int]
    /// By pattern edge ordinal (offset in `edges`): the target edge's ordinal, or −1.
    @usableFromInline let edgeImages: [Int]

    /// The total cost of the path's operations.
    public let cost: Cost

    /// Whether the path is proven to cost the least: false when the search spent its expansion
    /// limit first, and the path is the cheapest one found.
    public let isOptimal: Bool

    @inlinable
    init(pattern: Pattern, target: Target, patternNumbers: AnyObject?, targetNumbers: AnyObject?, positions: AnyObject,
         vertexImages: [Int], edgeImages: [Int], cost: Cost, isOptimal: Bool) {
        self.pattern = pattern
        self.target = target
        self.patternNumbers = patternNumbers
        self.targetNumbers = targetNumbers
        self.positions = positions
        self.vertexImages = vertexImages
        self.edgeImages = edgeImages
        self.cost = cost
        self.isOptimal = isOptimal
    }

    /// The index of the image of the pattern vertex with index `index`, or nil when the vertex is
    /// deleted, in index space (a graph without vertex indices numbers its vertices by position
    /// in `vertices`). O(1).
    ///
    /// - Precondition: `index` is in `0..<pattern.vertexCount`.
    @inlinable
    public func imageIndex(ofIndex index: Int) -> Int? {
        precondition(index >= 0 && index < vertexImages.count, "\(index) is not a vertex index of the pattern")
        let x = vertexImages[index]
        return x < 0 ? nil : x
    }
}

// The boxes are immutable once built.
extension EditPath: @unchecked Sendable where Pattern: Sendable, Target: Sendable, Cost: Sendable {}

/// Both graphs' edge positions, by ordinal.
@usableFromInline
final class _EditPositions<P: Comparable, T: Comparable> {
    @usableFromInline let pattern: [P]
    @usableFromInline let target: [T]

    @inlinable
    init(pattern: [P], target: [T]) {
        self.pattern = pattern
        self.target = target
    }
}

/// The ordinal of `position` in the ascending `positions`, or nil when it is not one of them.
@inlinable
func _editOrdinal<P: Comparable>(of position: P, in positions: [P]) -> Int? {
    var lo = 0, hi = positions.count
    while lo < hi {
        let mid = (lo + hi) / 2
        if positions[mid] < position { lo = mid + 1 } else { hi = mid }
    }
    return lo < positions.count && positions[lo] == position ? lo : nil
}

/// The search behind every `optimalEditPath` entry point, from the graphs' vertices and edges in
/// index space: reads each cost once per vertex, edge or pair (every one checked), then runs
/// `_EditDistanceSearch`.
@inlinable
func _optimalEditPath<PV, TV, PE, TE, C: SignedNumeric & Comparable>(
    patternVertices: [PV], targetVertices: [TV], patternEdges: [PE], targetEdges: [TE],
    patternEnds: [Int], targetEnds: [Int], isDirected: Bool,
    _ vertexSubstitutionCost: (PV, TV) -> C, _ vertexDeletionCost: (PV) -> C, _ vertexInsertionCost: (TV) -> C,
    _ edgeSubstitutionCost: (PE, TE) -> C, _ edgeDeletionCost: (PE) -> C, _ edgeInsertionCost: (TE) -> C,
    upperBound: C?, expansionLimit: Int?
) -> (vertexImages: [Int], edgeImages: [Int], cost: C, isOptimal: Bool)? {
    precondition(expansionLimit.map { $0 >= 0 } ?? true, "The expansion limit is negative")
    func read(_ c: C) -> C {
        _checkEditCost(c)
        return c
    }
    var vertexSubstitution: [C] = []
    vertexSubstitution.reserveCapacity(patternVertices.count * targetVertices.count)
    for v in patternVertices { for w in targetVertices { vertexSubstitution.append(read(vertexSubstitutionCost(v, w))) } }
    let vertexDeletion = patternVertices.map { read(vertexDeletionCost($0)) }
    let vertexInsertion = targetVertices.map { read(vertexInsertionCost($0)) }
    var edgeSubstitution: [C] = []
    edgeSubstitution.reserveCapacity(patternEdges.count * targetEdges.count)
    for e in patternEdges { for f in targetEdges { edgeSubstitution.append(read(edgeSubstitutionCost(e, f))) } }
    let edgeDeletion = patternEdges.map { read(edgeDeletionCost($0)) }
    let edgeInsertion = targetEdges.map { read(edgeInsertionCost($0)) }
    var search = _EditDistanceSearch(
        _EditGraph(count: patternVertices.count, isDirected: isDirected, ends: patternEnds),
        _EditGraph(count: targetVertices.count, isDirected: isDirected, ends: targetEnds),
        vertexSubstitution: vertexSubstitution, vertexDeletion: vertexDeletion, vertexInsertion: vertexInsertion,
        edgeSubstitution: edgeSubstitution, edgeDeletion: edgeDeletion, edgeInsertion: edgeInsertion,
        bound: upperBound, expansionLimit: expansionLimit)
    return search.run()
}

// MARK: - Undirected

extension Graph {
    /// The vertices by number, the edge positions by ordinal, and each edge's two ends.
    @inlinable
    func _editInput(_ numbers: _VertexNumbers<Vertex>?) -> (vertices: [Vertex], positions: [Edges.Index], ends: [Int]) {
        let n = vertexIndexBound ?? numbers!.listed.count
        let listed = numbers?.listed ?? (0 ..< n).map { vertex(atIndex: $0) }
        let positions = Array(edges.indices)
        var ends: [Int] = []
        ends.reserveCapacity(2 * positions.count)
        for position in positions {
            let a: Int, b: Int
            if let numbers {
                let edge = edges[position]
                a = numbers.numbers[edge.u]!
                b = numbers.numbers[edge.v]!
            } else {
                (a, b) = endpointIndices(ofEdgeAt: position)
            }
            precondition(UInt(bitPattern: a) < UInt(bitPattern: n) && UInt(bitPattern: b) < UInt(bitPattern: n), "An endpoint index is out of range")
            ends.append(a)
            ends.append(b)
        }
        return (listed, positions, ends)
    }

    /// A least-cost edit path from this graph to `other`, each vertex and edge substituted,
    /// deleted or inserted at the given costs; the graph edit distance is its `cost`.
    ///
    /// An edit path substitutes each vertex of this graph by a distinct vertex of `other` or
    /// deletes it, and inserts the rest of `other`'s vertices; the edges between two vertices (or
    /// a vertex's self-loops) are then substituted by edges between their images, one for one, or
    /// deleted, and `other`'s remaining edges inserted. Parallel edges are matched as a group at
    /// the least cost. Found exactly by depth-first branch and bound (Abu-Aisheh et al. 2015)
    /// from the bipartite upper bound (Riesen and Bunke 2009), with a lower bound from an edit
    /// assignment of the undecided vertices.
    ///
    /// Each closure is called once per vertex, edge, or pair of vertices or of edges, at the call
    /// (so O(m · m′) edge substitution costs). A substitution may cost more than a deletion and an
    /// insertion; the path then takes the cheaper.
    ///
    /// - Parameters:
    ///   - other: The graph to reach.
    ///   - vertexSubstitutionCost: The cost of substituting a vertex of this graph by one of
    ///     `other`.
    ///   - vertexDeletionCost: The cost of deleting a vertex of this graph.
    ///   - vertexInsertionCost: The cost of inserting a vertex of `other`.
    ///   - edgeSubstitutionCost: The cost of substituting an edge of this graph by one of `other`,
    ///     by position.
    ///   - edgeDeletionCost: The cost of deleting an edge of this graph.
    ///   - edgeInsertionCost: The cost of inserting an edge of `other`.
    ///   - upperBound: When set, only paths costing at most this are considered.
    ///   - expansionLimit: When set, the search expands at most this many nodes and returns the
    ///     cheapest path found, with `isOptimal` false when it stopped early.
    /// - Returns: The path, or nil when every path costs more than `upperBound`.
    /// - Precondition: every cost is finite and not negative; twice the sum of all costs fits in
    ///   `Cost`; `expansionLimit` is not negative.
    /// - Complexity: Exponential in the worst case (the problem is NP-hard); each node costs
    ///   O((n + n′)³ + n · n′ · n) for its lower bound.
    @inlinable
    public func optimalEditPath<Other: Graph, Cost: SignedNumeric & Comparable>(
        to other: Other,
        vertexSubstitutionCost: (Vertex, Other.Vertex) -> Cost, vertexDeletionCost: (Vertex) -> Cost, vertexInsertionCost: (Other.Vertex) -> Cost,
        edgeSubstitutionCost: (Edges.Index, Other.Edges.Index) -> Cost, edgeDeletionCost: (Edges.Index) -> Cost, edgeInsertionCost: (Other.Edges.Index) -> Cost,
        upperBound: Cost? = nil, expansionLimit: Int? = nil
    ) -> EditPath<Self, Other, Cost>? {
        let patternNumbers = _isomorphismNumbers(), targetNumbers = other._isomorphismNumbers()
        let a = _editInput(patternNumbers), b = other._editInput(targetNumbers)
        guard let found = _optimalEditPath(
            patternVertices: a.vertices, targetVertices: b.vertices, patternEdges: a.positions, targetEdges: b.positions,
            patternEnds: a.ends, targetEnds: b.ends, isDirected: false,
            vertexSubstitutionCost, vertexDeletionCost, vertexInsertionCost, edgeSubstitutionCost, edgeDeletionCost, edgeInsertionCost,
            upperBound: upperBound, expansionLimit: expansionLimit)
        else { return nil }
        return EditPath(pattern: self, target: other, patternNumbers: patternNumbers, targetNumbers: targetNumbers,
                        positions: _EditPositions(pattern: a.positions, target: b.positions),
                        vertexImages: found.vertexImages, edgeImages: found.edgeImages, cost: found.cost, isOptimal: found.isOptimal)
    }

    /// `optimalEditPath(to:vertexSubstitutionCost:...)` at unit costs: substituting a vertex or
    /// an edge is free, deleting or inserting one costs 1 (NetworkX's defaults).
    ///
    /// - Returns: The path, or nil when every path costs more than `upperBound`.
    /// - Precondition: `expansionLimit` is not negative.
    /// - Complexity: As the general form.
    @inlinable
    public func optimalEditPath<Other: Graph>(to other: Other, upperBound: Int? = nil, expansionLimit: Int? = nil) -> EditPath<Self, Other, Int>? {
        optimalEditPath(to: other, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                        edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 },
                        upperBound: upperBound, expansionLimit: expansionLimit)
    }

    /// The graph edit distance to `other` at the given costs: the cost of
    /// `optimalEditPath(to:vertexSubstitutionCost:...)`.
    ///
    /// - Precondition: every cost is finite and not negative; twice the sum of all costs fits in
    ///   `Cost`.
    /// - Complexity: As `optimalEditPath(to:vertexSubstitutionCost:...)`.
    @inlinable
    public func graphEditDistance<Other: Graph, Cost: SignedNumeric & Comparable>(
        to other: Other,
        vertexSubstitutionCost: (Vertex, Other.Vertex) -> Cost, vertexDeletionCost: (Vertex) -> Cost, vertexInsertionCost: (Other.Vertex) -> Cost,
        edgeSubstitutionCost: (Edges.Index, Other.Edges.Index) -> Cost, edgeDeletionCost: (Edges.Index) -> Cost, edgeInsertionCost: (Other.Edges.Index) -> Cost
    ) -> Cost {
        optimalEditPath(to: other, vertexSubstitutionCost: vertexSubstitutionCost, vertexDeletionCost: vertexDeletionCost, vertexInsertionCost: vertexInsertionCost,
                        edgeSubstitutionCost: edgeSubstitutionCost, edgeDeletionCost: edgeDeletionCost, edgeInsertionCost: edgeInsertionCost)!.cost
    }

    /// The graph edit distance to `other` at unit costs: the fewest vertex and edge deletions and
    /// insertions that turn this graph into one isomorphic to `other` (zero exactly when they are
    /// isomorphic).
    ///
    /// - Complexity: As `optimalEditPath(to:vertexSubstitutionCost:...)`.
    @inlinable
    public func graphEditDistance<Other: Graph>(to other: Other) -> Int {
        optimalEditPath(to: other)!.cost
    }
}

extension EditPath where Pattern: Graph, Target: Graph {
    @inlinable
    var _positions: _EditPositions<Pattern.Edges.Index, Target.Edges.Index> {
        unsafeDowncast(positions, to: _EditPositions<Pattern.Edges.Index, Target.Edges.Index>.self)
    }

    /// The image of `vertex`, or nil when the path deletes it.
    ///
    /// - Precondition: `vertex` is a vertex of the pattern.
    @inlinable
    public func image(of vertex: Pattern.Vertex) -> Target.Vertex? {
        let number: Int
        if let numbers = _numbers(patternNumbers, Pattern.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the pattern") }
            number = i
        } else {
            number = pattern._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the pattern")
        }
        let x = vertexImages[number]
        return x < 0 ? nil : target._vertex(number: x, _numbers(targetNumbers, Target.Vertex.self)?.listed)
    }

    /// The image of `vertex`, or nil when the path deletes it, throwing instead of trapping when
    /// `vertex` is not a vertex of the pattern.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the pattern.
    @inlinable
    public func image(checked vertex: Pattern.Vertex) throws(VertexNotFound) -> Target.Vertex? {
        guard pattern.contains(vertex) else { throw VertexNotFound() }
        return image(of: vertex)
    }

    /// The pattern vertex substituted by `vertex`, or nil when the path inserts it. O(n).
    ///
    /// - Precondition: `vertex` is a vertex of the target.
    @inlinable
    public func preimage(of vertex: Target.Vertex) -> Pattern.Vertex? {
        let t: Int
        if let numbers = _numbers(targetNumbers, Target.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the target") }
            t = i
        } else {
            t = target._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the target")
        }
        guard let u = vertexImages.firstIndex(of: t) else { return nil }
        return pattern._vertex(number: u, _numbers(patternNumbers, Pattern.Vertex.self)?.listed)
    }

    /// The pattern vertex substituted by `vertex`, or nil when the path inserts it, throwing
    /// instead of trapping when `vertex` is not a vertex of the target. O(n).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the target.
    @inlinable
    public func preimage(checked vertex: Target.Vertex) throws(VertexNotFound) -> Pattern.Vertex? {
        guard target.contains(vertex) else { throw VertexNotFound() }
        return preimage(of: vertex)
    }

    /// The position of the target edge substituted for the pattern edge at `position`, or nil
    /// when the path deletes it. O(log m).
    ///
    /// - Precondition: `position` is an edge position of the pattern.
    @inlinable
    public func edgeImage(ofEdgeAt position: Pattern.Edges.Index) -> Target.Edges.Index? {
        let boxes = _positions
        guard let e = _editOrdinal(of: position, in: boxes.pattern) else { preconditionFailure("\(position) is not an edge position of the pattern") }
        let f = edgeImages[e]
        return f < 0 ? nil : boxes.target[f]
    }

    /// The position of the target edge substituted for the pattern edge at `position`, or nil
    /// when the path deletes it, throwing instead of trapping when `position` is not an edge
    /// position of the pattern. O(log m).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not an edge position of the pattern.
    @inlinable
    public func edgeImage(checkedEdgeAt position: Pattern.Edges.Index) throws(EdgeNotFound) -> Target.Edges.Index? {
        guard _editOrdinal(of: position, in: _positions.pattern) != nil else { throw EdgeNotFound() }
        return edgeImage(ofEdgeAt: position)
    }

    /// The position of the pattern edge substituted by the target edge at `position`, or nil when
    /// the path inserts it. O(m).
    ///
    /// - Precondition: `position` is an edge position of the target.
    @inlinable
    public func edgePreimage(ofEdgeAt position: Target.Edges.Index) -> Pattern.Edges.Index? {
        let boxes = _positions
        guard let f = _editOrdinal(of: position, in: boxes.target) else { preconditionFailure("\(position) is not an edge position of the target") }
        return edgeImages.firstIndex(of: f).map { boxes.pattern[$0] }
    }

    /// The position of the pattern edge substituted by the target edge at `position`, or nil when
    /// the path inserts it, throwing instead of trapping when `position` is not an edge position
    /// of the target. O(m).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not an edge position of the target.
    @inlinable
    public func edgePreimage(checkedEdgeAt position: Target.Edges.Index) throws(EdgeNotFound) -> Pattern.Edges.Index? {
        guard _editOrdinal(of: position, in: _positions.target) != nil else { throw EdgeNotFound() }
        return edgePreimage(ofEdgeAt: position)
    }

    /// The pattern vertices the path deletes, in `vertices` order.
    @inlinable
    public var deletedVertices: [Pattern.Vertex] {
        let listed = _numbers(patternNumbers, Pattern.Vertex.self)?.listed
        return vertexImages.indices.filter { vertexImages[$0] < 0 }.map { pattern._vertex(number: $0, listed) }
    }

    /// The target vertices the path inserts, in `vertices` order.
    @inlinable
    public var insertedVertices: [Target.Vertex] {
        var used = [Bool](repeating: false, count: target.vertexCount)
        for x in vertexImages where x >= 0 { used[x] = true }
        let listed = _numbers(targetNumbers, Target.Vertex.self)?.listed
        return used.indices.filter { !used[$0] }.map { target._vertex(number: $0, listed) }
    }

    /// The positions of the pattern edges the path deletes, in `edges` order.
    @inlinable
    public var deletedEdges: [Pattern.Edges.Index] {
        let boxes = _positions
        return edgeImages.indices.filter { edgeImages[$0] < 0 }.map { boxes.pattern[$0] }
    }

    /// The positions of the target edges the path inserts, in `edges` order.
    @inlinable
    public var insertedEdges: [Target.Edges.Index] {
        let boxes = _positions
        var used = [Bool](repeating: false, count: boxes.target.count)
        for f in edgeImages where f >= 0 { used[f] = true }
        return used.indices.filter { !used[$0] }.map { boxes.target[$0] }
    }
}

// MARK: - Directed

extension DirectedGraph {
    /// The vertices by number, the edge positions by ordinal, and each arc's source and target.
    @inlinable
    func _editInput(_ numbers: _VertexNumbers<Vertex>?) -> (vertices: [Vertex], positions: [Edges.Index], ends: [Int]) {
        let n = vertexIndexBound ?? numbers!.listed.count
        let listed = numbers?.listed ?? (0 ..< n).map { vertex(atIndex: $0) }
        let positions = Array(edges.indices)
        var ends: [Int] = []
        ends.reserveCapacity(2 * positions.count)
        for position in positions {
            let a: Int, b: Int
            if let numbers {
                a = numbers.numbers[source(ofEdgeAt: position)]!
                b = numbers.numbers[target(ofEdgeAt: position)]!
            } else {
                a = sourceIndex(ofEdgeAt: position)
                b = targetIndex(ofEdgeAt: position)
            }
            precondition(UInt(bitPattern: a) < UInt(bitPattern: n) && UInt(bitPattern: b) < UInt(bitPattern: n), "An endpoint index is out of range")
            ends.append(a)
            ends.append(b)
        }
        return (listed, positions, ends)
    }

    /// A least-cost edit path from this graph to `other`, as the undirected form: an arc is
    /// substituted only by an arc between the images in the same direction.
    ///
    /// - Parameters:
    ///   - other: The graph to reach.
    ///   - vertexSubstitutionCost: The cost of substituting a vertex of this graph by one of
    ///     `other`.
    ///   - vertexDeletionCost: The cost of deleting a vertex of this graph.
    ///   - vertexInsertionCost: The cost of inserting a vertex of `other`.
    ///   - edgeSubstitutionCost: The cost of substituting an arc of this graph by one of `other`,
    ///     by position.
    ///   - edgeDeletionCost: The cost of deleting an arc of this graph.
    ///   - edgeInsertionCost: The cost of inserting an arc of `other`.
    ///   - upperBound: When set, only paths costing at most this are considered.
    ///   - expansionLimit: When set, the search expands at most this many nodes and returns the
    ///     cheapest path found, with `isOptimal` false when it stopped early.
    /// - Returns: The path, or nil when every path costs more than `upperBound`.
    /// - Precondition: every cost is finite and not negative; twice the sum of all costs fits in
    ///   `Cost`; `expansionLimit` is not negative.
    /// - Complexity: Exponential in the worst case; each node costs O((n + n′)³ + n · n′ · n).
    @inlinable
    public func optimalEditPath<Other: DirectedGraph, Cost: SignedNumeric & Comparable>(
        to other: Other,
        vertexSubstitutionCost: (Vertex, Other.Vertex) -> Cost, vertexDeletionCost: (Vertex) -> Cost, vertexInsertionCost: (Other.Vertex) -> Cost,
        edgeSubstitutionCost: (Edges.Index, Other.Edges.Index) -> Cost, edgeDeletionCost: (Edges.Index) -> Cost, edgeInsertionCost: (Other.Edges.Index) -> Cost,
        upperBound: Cost? = nil, expansionLimit: Int? = nil
    ) -> EditPath<Self, Other, Cost>? {
        let patternNumbers = _isomorphismNumbers(), targetNumbers = other._isomorphismNumbers()
        let a = _editInput(patternNumbers), b = other._editInput(targetNumbers)
        guard let found = _optimalEditPath(
            patternVertices: a.vertices, targetVertices: b.vertices, patternEdges: a.positions, targetEdges: b.positions,
            patternEnds: a.ends, targetEnds: b.ends, isDirected: true,
            vertexSubstitutionCost, vertexDeletionCost, vertexInsertionCost, edgeSubstitutionCost, edgeDeletionCost, edgeInsertionCost,
            upperBound: upperBound, expansionLimit: expansionLimit)
        else { return nil }
        return EditPath(pattern: self, target: other, patternNumbers: patternNumbers, targetNumbers: targetNumbers,
                        positions: _EditPositions(pattern: a.positions, target: b.positions),
                        vertexImages: found.vertexImages, edgeImages: found.edgeImages, cost: found.cost, isOptimal: found.isOptimal)
    }

    /// `optimalEditPath(to:vertexSubstitutionCost:...)` at unit costs: substituting a vertex or
    /// an arc is free, deleting or inserting one costs 1.
    ///
    /// - Returns: The path, or nil when every path costs more than `upperBound`.
    /// - Precondition: `expansionLimit` is not negative.
    /// - Complexity: As the general form.
    @inlinable
    public func optimalEditPath<Other: DirectedGraph>(to other: Other, upperBound: Int? = nil, expansionLimit: Int? = nil) -> EditPath<Self, Other, Int>? {
        optimalEditPath(to: other, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 },
                        edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 },
                        upperBound: upperBound, expansionLimit: expansionLimit)
    }

    /// The graph edit distance to `other` at the given costs: the cost of
    /// `optimalEditPath(to:vertexSubstitutionCost:...)`.
    ///
    /// - Precondition: every cost is finite and not negative; twice the sum of all costs fits in
    ///   `Cost`.
    /// - Complexity: As `optimalEditPath(to:vertexSubstitutionCost:...)`.
    @inlinable
    public func graphEditDistance<Other: DirectedGraph, Cost: SignedNumeric & Comparable>(
        to other: Other,
        vertexSubstitutionCost: (Vertex, Other.Vertex) -> Cost, vertexDeletionCost: (Vertex) -> Cost, vertexInsertionCost: (Other.Vertex) -> Cost,
        edgeSubstitutionCost: (Edges.Index, Other.Edges.Index) -> Cost, edgeDeletionCost: (Edges.Index) -> Cost, edgeInsertionCost: (Other.Edges.Index) -> Cost
    ) -> Cost {
        optimalEditPath(to: other, vertexSubstitutionCost: vertexSubstitutionCost, vertexDeletionCost: vertexDeletionCost, vertexInsertionCost: vertexInsertionCost,
                        edgeSubstitutionCost: edgeSubstitutionCost, edgeDeletionCost: edgeDeletionCost, edgeInsertionCost: edgeInsertionCost)!.cost
    }

    /// The graph edit distance to `other` at unit costs: the fewest vertex and arc deletions and
    /// insertions that turn this graph into one isomorphic to `other`.
    ///
    /// - Complexity: As `optimalEditPath(to:vertexSubstitutionCost:...)`.
    @inlinable
    public func graphEditDistance<Other: DirectedGraph>(to other: Other) -> Int {
        optimalEditPath(to: other)!.cost
    }
}

extension EditPath where Pattern: DirectedGraph, Target: DirectedGraph {
    @inlinable
    var _positions: _EditPositions<Pattern.Edges.Index, Target.Edges.Index> {
        unsafeDowncast(positions, to: _EditPositions<Pattern.Edges.Index, Target.Edges.Index>.self)
    }

    /// The image of `vertex`, or nil when the path deletes it.
    ///
    /// - Precondition: `vertex` is a vertex of the pattern.
    @inlinable
    public func image(of vertex: Pattern.Vertex) -> Target.Vertex? {
        let number: Int
        if let numbers = _numbers(patternNumbers, Pattern.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the pattern") }
            number = i
        } else {
            number = pattern._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the pattern")
        }
        let x = vertexImages[number]
        return x < 0 ? nil : target._vertex(number: x, _numbers(targetNumbers, Target.Vertex.self)?.listed)
    }

    /// The image of `vertex`, or nil when the path deletes it, throwing instead of trapping when
    /// `vertex` is not a vertex of the pattern.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the pattern.
    @inlinable
    public func image(checked vertex: Pattern.Vertex) throws(VertexNotFound) -> Target.Vertex? {
        guard pattern.contains(vertex) else { throw VertexNotFound() }
        return image(of: vertex)
    }

    /// The pattern vertex substituted by `vertex`, or nil when the path inserts it. O(n).
    ///
    /// - Precondition: `vertex` is a vertex of the target.
    @inlinable
    public func preimage(of vertex: Target.Vertex) -> Pattern.Vertex? {
        let t: Int
        if let numbers = _numbers(targetNumbers, Target.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the target") }
            t = i
        } else {
            t = target._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the target")
        }
        guard let u = vertexImages.firstIndex(of: t) else { return nil }
        return pattern._vertex(number: u, _numbers(patternNumbers, Pattern.Vertex.self)?.listed)
    }

    /// The pattern vertex substituted by `vertex`, or nil when the path inserts it, throwing
    /// instead of trapping when `vertex` is not a vertex of the target. O(n).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the target.
    @inlinable
    public func preimage(checked vertex: Target.Vertex) throws(VertexNotFound) -> Pattern.Vertex? {
        guard target.contains(vertex) else { throw VertexNotFound() }
        return preimage(of: vertex)
    }

    /// The position of the target arc substituted for the pattern arc at `position`, or nil when
    /// the path deletes it. O(log m).
    ///
    /// - Precondition: `position` is an edge position of the pattern.
    @inlinable
    public func edgeImage(ofEdgeAt position: Pattern.Edges.Index) -> Target.Edges.Index? {
        let boxes = _positions
        guard let e = _editOrdinal(of: position, in: boxes.pattern) else { preconditionFailure("\(position) is not an edge position of the pattern") }
        let f = edgeImages[e]
        return f < 0 ? nil : boxes.target[f]
    }

    /// The position of the target arc substituted for the pattern arc at `position`, or nil when
    /// the path deletes it, throwing instead of trapping when `position` is not an edge position
    /// of the pattern. O(log m).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not an edge position of the pattern.
    @inlinable
    public func edgeImage(checkedEdgeAt position: Pattern.Edges.Index) throws(EdgeNotFound) -> Target.Edges.Index? {
        guard _editOrdinal(of: position, in: _positions.pattern) != nil else { throw EdgeNotFound() }
        return edgeImage(ofEdgeAt: position)
    }

    /// The position of the pattern arc substituted by the target arc at `position`, or nil when
    /// the path inserts it. O(m).
    ///
    /// - Precondition: `position` is an edge position of the target.
    @inlinable
    public func edgePreimage(ofEdgeAt position: Target.Edges.Index) -> Pattern.Edges.Index? {
        let boxes = _positions
        guard let f = _editOrdinal(of: position, in: boxes.target) else { preconditionFailure("\(position) is not an edge position of the target") }
        return edgeImages.firstIndex(of: f).map { boxes.pattern[$0] }
    }

    /// The position of the pattern arc substituted by the target arc at `position`, or nil when
    /// the path inserts it, throwing instead of trapping when `position` is not an edge position
    /// of the target. O(m).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not an edge position of the target.
    @inlinable
    public func edgePreimage(checkedEdgeAt position: Target.Edges.Index) throws(EdgeNotFound) -> Pattern.Edges.Index? {
        guard _editOrdinal(of: position, in: _positions.target) != nil else { throw EdgeNotFound() }
        return edgePreimage(ofEdgeAt: position)
    }

    /// The pattern vertices the path deletes, in `vertices` order.
    @inlinable
    public var deletedVertices: [Pattern.Vertex] {
        let listed = _numbers(patternNumbers, Pattern.Vertex.self)?.listed
        return vertexImages.indices.filter { vertexImages[$0] < 0 }.map { pattern._vertex(number: $0, listed) }
    }

    /// The target vertices the path inserts, in `vertices` order.
    @inlinable
    public var insertedVertices: [Target.Vertex] {
        var used = [Bool](repeating: false, count: target.vertexCount)
        for x in vertexImages where x >= 0 { used[x] = true }
        let listed = _numbers(targetNumbers, Target.Vertex.self)?.listed
        return used.indices.filter { !used[$0] }.map { target._vertex(number: $0, listed) }
    }

    /// The positions of the pattern arcs the path deletes, in `edges` order.
    @inlinable
    public var deletedEdges: [Pattern.Edges.Index] {
        let boxes = _positions
        return edgeImages.indices.filter { edgeImages[$0] < 0 }.map { boxes.pattern[$0] }
    }

    /// The positions of the target arcs the path inserts, in `edges` order.
    @inlinable
    public var insertedEdges: [Target.Edges.Index] {
        let boxes = _positions
        var used = [Bool](repeating: false, count: boxes.target.count)
        for f in edgeImages where f >= 0 { used[f] = true }
        return used.indices.filter { !used[$0] }.map { boxes.target[$0] }
    }
}
