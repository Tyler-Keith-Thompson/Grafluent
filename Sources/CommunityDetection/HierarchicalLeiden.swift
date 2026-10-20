import GraphProtocols

/// Communities at several levels: Leiden on the whole graph, then Leiden again inside every
/// community larger than a size cap, until each community is within the cap or does not split.
///
/// Communities are numbered `0 ..< count`, level by level: level 0 holds the whole graph's
/// communities by their least vertex (in `vertices` order), and each later level holds the
/// communities Leiden split the oversized ones into, by parent and then by least vertex. So
/// `communities(atLevel:)` and `children(of:)` are ranges. A community with no children is final
/// (`leaves`): the final communities partition the vertices, and each is within the cap or could
/// not be split further. Each community's vertices are in `vertices` order.
///
/// It keeps a copy of the graph to look vertices up through the graph's own vertex indices. The
/// copy shares storage (copy-on-write), so making it is O(1); while the result is alive, the next
/// mutation of the original copies the whole graph.
///
/// A community's slice keeps the indices of the flat storage it is cut from: use `first`,
/// iteration or `Array(_:)`, not `[0]`.
@frozen
public struct CommunityHierarchy<G: DirectedGraph>: RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = ArraySlice<G.Vertex>
    public typealias Indices = Range<Int>

    @usableFromInline let _graph: G
    /// Vertex numbers when the graph has no vertex indices.
    @usableFromInline let _numbers: [G.Vertex: Int]?
    /// The final community of each vertex, by vertex number.
    @usableFromInline let _leaf: [Int]
    /// Every community's vertices; community `c` is `_members[_offsets[c] ..< _offsets[c + 1]]`.
    @usableFromInline let _members: [G.Vertex]
    @usableFromInline let _offsets: [Int]
    /// Level `l` is the communities `_levelStarts[l] ..< _levelStarts[l + 1]`.
    @usableFromInline let _levelStarts: [Int]
    @usableFromInline let _level: [Int]
    /// Each community's parent, −1 on level 0.
    @usableFromInline let _parent: [Int]
    /// Each community's children: `_firstChild[c] ..< _firstChild[c] + _childCount[c]`.
    @usableFromInline let _firstChild: [Int]
    @usableFromInline let _childCount: [Int]

    @inlinable
    init(_ graph: G, numbers: [G.Vertex: Int]?, listed: [G.Vertex]?, _ hierarchy: _CommunityHierarchy) {
        _graph = graph
        _numbers = numbers
        _leaf = hierarchy.leaf
        _members = hierarchy.members.map { listed?[$0] ?? graph.vertex(atIndex: $0) }
        _offsets = hierarchy.offsets
        _levelStarts = hierarchy.levelStarts
        _parent = hierarchy.parent
        let count = hierarchy.parent.count
        var level = [Int](repeating: 0, count: count)
        for l in 0 ..< hierarchy.levelStarts.count - 1 {
            for c in hierarchy.levelStarts[l] ..< hierarchy.levelStarts[l + 1] { level[c] = l }
        }
        _level = level
        var firstChild = [Int](repeating: 0, count: count), childCount = [Int](repeating: 0, count: count)
        for c in 0 ..< count where hierarchy.parent[c] >= 0 {
            let p = hierarchy.parent[c]
            if childCount[p] == 0 { firstChild[p] = c }
            childCount[p] += 1
        }
        _firstChild = firstChild
        _childCount = childCount
    }

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { _offsets.count - 1 }

    /// The vertices of the community numbered `position`, in `vertices` order.
    @inlinable
    public subscript(position: Int) -> ArraySlice<G.Vertex> {
        precondition(position >= 0 && position < endIndex, "Community position out of range")
        return _members[_offsets[position] ..< _offsets[position + 1]]
    }

    /// How many levels there are: 0 for a graph without vertices, otherwise at least 1.
    @inlinable
    public var levelCount: Int { _levelStarts.count - 1 }

    /// The communities on `level`, a range of community numbers.
    ///
    /// - Precondition: `level` is in `0..<levelCount`.
    @inlinable
    public func communities(atLevel level: Int) -> Range<Int> {
        precondition(level >= 0 && level < levelCount, "Level \(level) out of range")
        return _levelStarts[level] ..< _levelStarts[level + 1]
    }

    /// The level of `community`: 0 for a community of the whole graph, one more than its parent's
    /// otherwise.
    ///
    /// - Precondition: `community` is in `0..<count`.
    @inlinable
    public func level(of community: Int) -> Int {
        precondition(community >= 0 && community < endIndex, "Community position out of range")
        return _level[community]
    }

    /// The community `community` was split from, or nil on level 0.
    ///
    /// - Precondition: `community` is in `0..<count`.
    @inlinable
    public func parent(of community: Int) -> Int? {
        precondition(community >= 0 && community < endIndex, "Community position out of range")
        let p = _parent[community]
        return p < 0 ? nil : p
    }

    /// The communities `community` was split into, on the next level; empty when it is final.
    ///
    /// - Precondition: `community` is in `0..<count`.
    @inlinable
    public func children(of community: Int) -> Range<Int> {
        precondition(community >= 0 && community < endIndex, "Community position out of range")
        return _firstChild[community] ..< _firstChild[community] + _childCount[community]
    }

    /// The final communities, those with no children, in increasing number: together they list
    /// every vertex exactly once. O(count).
    @inlinable
    public var leaves: [Int] {
        var leaves: [Int] = []
        for c in 0 ..< endIndex where _childCount[c] == 0 { leaves.append(c) }
        return leaves
    }

    /// The final community containing `vertex`: O(1) after the graph's `vertexIndex(of:)` (one hash
    /// for a graph without vertex indices). Its ancestors are its `parent(of:)` chain.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func community(of vertex: G.Vertex) -> Int {
        if let _numbers {
            guard let v = _numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return _leaf[v]
        }
        return _leaf[_graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph")]
    }

    /// `community(of: vertex)`, throwing instead of trapping when `vertex` is not a vertex of the
    /// graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func community(checked vertex: G.Vertex) throws(VertexNotFound) -> Int {
        if let _numbers {
            guard let v = _numbers[vertex] else { throw VertexNotFound() }
            return _leaf[v]
        }
        guard _graph.contains(vertex) else { throw VertexNotFound() }
        return community(of: vertex)
    }

    /// The final community containing the vertex at `index`: its vertex index, or its position in
    /// `vertices` when the graph has no vertex indices.
    ///
    /// - Precondition: `index` is in `0..<vertexCount`.
    @inlinable
    public func community(ofIndex index: Int) -> Int {
        precondition(index >= 0 && index < _leaf.count, "Vertex index \(index) out of range")
        return _leaf[index]
    }
}

extension CommunityHierarchy: Equatable {
    /// Whether both hierarchies have the same communities, numbered the same way, with the same
    /// parents. The graphs they were computed from are not compared.
    @inlinable
    public static func == (lhs: CommunityHierarchy, rhs: CommunityHierarchy) -> Bool {
        lhs._offsets == rhs._offsets && lhs._members == rhs._members && lhs._parent == rhs._parent && lhs._levelStarts == rhs._levelStarts
    }
}

extension CommunityHierarchy: Sendable where G: Sendable, G.Vertex: Sendable {}

extension CommunityHierarchy: CustomStringConvertible {
    public var description: String {
        (0 ..< levelCount).map { level in
            "[" + communities(atLevel: level).map { "[" + self[$0].map { "\($0)" }.joined(separator: ", ") + "]" }.joined(separator: ", ") + "]"
        }.joined(separator: " / ")
    }
}

/// A hierarchy in index space: every community's vertex numbers flat (`members[offsets[c] ..<
/// offsets[c + 1]]`), the levels' community ranges, each community's parent (−1 on level 0) and
/// each vertex's final community.
@frozen
@usableFromInline
struct _CommunityHierarchy {
    @usableFromInline var members: [Int] = []
    @usableFromInline var offsets: [Int] = [0]
    @usableFromInline var levelStarts: [Int] = [0]
    @usableFromInline var parent: [Int] = []
    @usableFromInline var leaf: [Int]

    @inlinable
    init(count: Int) {
        leaf = [Int](repeating: -1, count: count)
    }

    /// Adds the communities of `labels` (any label per vertex of `vertices`, which are increasing)
    /// as children of `parent`, numbered by least vertex, and returns the number of the first; its
    /// members are appended in vertex order.
    @inlinable
    mutating func addCommunities(of vertices: [Int], labels: [Int], parent p: Int) -> Int {
        let first = parent.count
        var renumber = [Int](repeating: -1, count: labels.count)
        var canonical = [Int](repeating: 0, count: labels.count)
        var count = 0
        for i in 0 ..< labels.count {
            let label = labels[i]
            if renumber[label] < 0 {
                renumber[label] = count
                count += 1
            }
            canonical[i] = renumber[label]
        }
        let (groupOffsets, order) = _countingSort(labels: canonical, count: count)
        let base = members.count
        members.reserveCapacity(base + vertices.count)
        for i in order {
            let v = vertices[i]
            members.append(v)
            leaf[v] = first + canonical[i]
        }
        for c in 0 ..< count {
            offsets.append(base + groupOffsets[c + 1])
            parent.append(p)
        }
        return first
    }
}

/// Hierarchical Leiden in index space (graspologic's `hierarchical_leiden`): `_leiden` on the whole
/// graph, then on the subgraph induced by every community of more than `maximumCommunitySize`
/// vertices, level by level, until every community of the last level is within the cap or Leiden
/// left it in one piece (which makes it final, however large). Each level's communities are made
/// by parent and then by least vertex. O(n + m) per level besides Leiden's own work on each piece.
@inlinable
func _hierarchicalLeiden<R: RandomNumberGenerator>(_ graph: _CommunityGraph, _ weights: [Double]?, maximumCommunitySize: Int, quality: QualityFunction, resolution: Double, randomness: Double, iterations: Int?, using generator: inout R) -> _CommunityHierarchy {
    let n = graph.count
    var hierarchy = _CommunityHierarchy(count: n)
    guard n > 0 else { return hierarchy }
    let labels = _leiden(graph, weights, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    _ = hierarchy.addCommunities(of: Array(0 ..< n), labels: labels, parent: -1)
    hierarchy.levelStarts.append(hierarchy.parent.count)
    // The communities of the last level that are over the cap, in number order.
    var oversized: [Int] = []
    for c in 0 ..< hierarchy.parent.count where hierarchy.offsets[c + 1] - hierarchy.offsets[c] > maximumCommunitySize { oversized.append(c) }
    while !oversized.isEmpty {
        // Each oversized community's rank, each vertex's position inside its community, and the
        // edges inside each oversized community, bucketed in one pass over the edges.
        var rank = [Int](repeating: -1, count: hierarchy.parent.count)
        for (r, c) in oversized.enumerated() { rank[c] = r }
        var local = [Int](repeating: 0, count: n)
        for c in oversized {
            var i = 0
            for slot in hierarchy.offsets[c] ..< hierarchy.offsets[c + 1] {
                local[hierarchy.members[slot]] = i
                i += 1
            }
        }
        var edgeRank = [Int](repeating: 0, count: graph.edgeCount)
        var inside: [Int] = []
        for e in 0 ..< graph.edgeCount {
            let r = rank[hierarchy.leaf[graph.from[e]]]
            if r >= 0, hierarchy.leaf[graph.to[e]] == hierarchy.leaf[graph.from[e]] {
                edgeRank[inside.count] = r
                inside.append(e)
            }
        }
        edgeRank.removeLast(edgeRank.count - inside.count)
        let (edgeOffsets, edgeOrder) = _countingSort(labels: edgeRank, count: oversized.count)
        let levelStart = hierarchy.parent.count
        var next: [Int] = []
        for (r, c) in oversized.enumerated() {
            let vertices = Array(hierarchy.members[hierarchy.offsets[c] ..< hierarchy.offsets[c + 1]])
            let edges = edgeOrder[edgeOffsets[r] ..< edgeOffsets[r + 1]].map { inside[$0] }
            let piece = _CommunityGraph(count: vertices.count, directed: graph.directed,
                                        from: edges.map { local[graph.from[$0]] }, to: edges.map { local[graph.to[$0]] })
            let pieceWeights = weights.map { weights in edges.map { weights[$0] } }
            let labels = _leiden(piece, pieceWeights, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
            // One community is the whole piece again: it stays final.
            var split = false
            for label in labels where label != labels[0] {
                split = true
                break
            }
            guard split else { continue }
            let first = hierarchy.addCommunities(of: vertices, labels: labels, parent: c)
            for d in first ..< hierarchy.parent.count where hierarchy.offsets[d + 1] - hierarchy.offsets[d] > maximumCommunitySize { next.append(d) }
        }
        guard hierarchy.parent.count > levelStart else { break }
        hierarchy.levelStarts.append(hierarchy.parent.count)
        oversized = next
    }
    return hierarchy
}

@inlinable
func _checkHierarchicalLeiden(maximumCommunitySize: Int, resolution: Double, randomness: Double, iterations: Int?) {
    precondition(maximumCommunitySize >= 1, "The maximum community size must be at least 1")
    _checkLeiden(resolution: resolution, randomness: randomness, iterations: iterations)
}

extension Graph {
    @inlinable
    func _hierarchicalLeidenCommunities<R: RandomNumberGenerator>(_ weights: [Double]?, maximumCommunitySize: Int, quality: QualityFunction, resolution: Double, randomness: Double, iterations: Int?, using generator: inout R) -> CommunityHierarchy<DirectedView<Self>> {
        _checkHierarchicalLeiden(maximumCommunitySize: maximumCommunitySize, resolution: resolution, randomness: randomness, iterations: iterations)
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let hierarchy = _hierarchicalLeiden(_communityGraph(), weights, maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
        return CommunityHierarchy(directedView, numbers: numbers, listed: listed, hierarchy)
    }

    /// Hierarchical Leiden communities: `leidenCommunities` on the whole graph, then, level by level,
    /// on the subgraph each community of more than `maximumCommunitySize` vertices induces, until
    /// every final community is within the cap or Leiden keeps it in one piece. Each piece is
    /// clustered on its own, so modularity is measured within it. The arguments after the cap are
    /// Leiden's.
    ///
    /// - Parameters:
    ///   - maximumCommunitySize: the cap; a larger community is clustered again.
    ///   - quality: what to maximize; modularity by default.
    ///   - resolution: γ; larger values give smaller communities.
    ///   - randomness: θ, how far the refinement's merges stray from the greatest gain.
    ///   - iterations: at most this many iterations per run; nil runs them until one changes nothing.
    ///   - generator: the source of the shuffles and the refinement's draws.
    /// - Returns: the communities of every level, with their parents.
    /// - Complexity: Leiden's on the whole graph and on each piece, plus O(n + m) per level.
    /// - Precondition: `maximumCommunitySize` is at least 1; `resolution` is finite and at least
    ///   zero; `randomness` is finite and greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func hierarchicalLeidenCommunities(maximumCommunitySize: Int, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil, using generator: inout some RandomNumberGenerator) -> CommunityHierarchy<DirectedView<Self>> {
        _hierarchicalLeidenCommunities(nil, maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Hierarchical Leiden communities drawing from the system's random number generator.
    ///
    /// - Precondition: `maximumCommunitySize` is at least 1; `resolution` is finite and at least
    ///   zero; `randomness` is finite and greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func hierarchicalLeidenCommunities(maximumCommunitySize: Int, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil) -> CommunityHierarchy<DirectedView<Self>> {
        var generator = SystemRandomNumberGenerator()
        return _hierarchicalLeidenCommunities(nil, maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Weighted hierarchical Leiden communities; `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `maximumCommunitySize` is at least
    ///   1; `resolution` is finite and at least zero; `randomness` is finite and greater than zero;
    ///   `iterations`, when given, is at least 1.
    @inlinable
    public func hierarchicalLeidenCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, maximumCommunitySize: Int, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil, using generator: inout some RandomNumberGenerator) -> CommunityHierarchy<DirectedView<Self>> {
        _hierarchicalLeidenCommunities(_communityWeights(weight), maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Weighted hierarchical Leiden communities drawing from the system's random number generator.
    ///
    /// - Precondition: every weight is finite and at least zero; `maximumCommunitySize` is at least
    ///   1; `resolution` is finite and at least zero; `randomness` is finite and greater than zero;
    ///   `iterations`, when given, is at least 1.
    @inlinable
    public func hierarchicalLeidenCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, maximumCommunitySize: Int, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil) -> CommunityHierarchy<DirectedView<Self>> {
        var generator = SystemRandomNumberGenerator()
        return _hierarchicalLeidenCommunities(_communityWeights(weight), maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }
}

extension DirectedGraph {
    @inlinable
    func _hierarchicalLeidenCommunities<R: RandomNumberGenerator>(_ weights: [Double]?, maximumCommunitySize: Int, quality: QualityFunction, resolution: Double, randomness: Double, iterations: Int?, using generator: inout R) -> CommunityHierarchy<Self> {
        _checkHierarchicalLeiden(maximumCommunitySize: maximumCommunitySize, resolution: resolution, randomness: randomness, iterations: iterations)
        let listed = _listedVertices()
        let numbers = listed.map(_vertexNumbers)
        let hierarchy = _hierarchicalLeiden(_communityGraph(numbers), weights, maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
        return CommunityHierarchy(self, numbers: numbers, listed: listed, hierarchy)
    }

    /// Hierarchical Leiden communities: `leidenCommunities` on the whole graph, then, level by level,
    /// on the subgraph each community of more than `maximumCommunitySize` vertices induces, until
    /// every final community is within the cap or Leiden keeps it in one piece. Each piece is
    /// clustered on its own, so modularity is measured within it. The arguments after the cap are
    /// Leiden's.
    ///
    /// - Parameters:
    ///   - maximumCommunitySize: the cap; a larger community is clustered again.
    ///   - quality: what to maximize; modularity by default.
    ///   - resolution: γ; larger values give smaller communities.
    ///   - randomness: θ, how far the refinement's merges stray from the greatest gain.
    ///   - iterations: at most this many iterations per run; nil runs them until one changes nothing.
    ///   - generator: the source of the shuffles and the refinement's draws.
    /// - Returns: the communities of every level, with their parents.
    /// - Complexity: Leiden's on the whole graph and on each piece, plus O(n + m) per level.
    /// - Precondition: `maximumCommunitySize` is at least 1; `resolution` is finite and at least
    ///   zero; `randomness` is finite and greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func hierarchicalLeidenCommunities(maximumCommunitySize: Int, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil, using generator: inout some RandomNumberGenerator) -> CommunityHierarchy<Self> {
        _hierarchicalLeidenCommunities(nil, maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Hierarchical Leiden communities drawing from the system's random number generator.
    ///
    /// - Precondition: `maximumCommunitySize` is at least 1; `resolution` is finite and at least
    ///   zero; `randomness` is finite and greater than zero; `iterations`, when given, is at least 1.
    @inlinable
    public func hierarchicalLeidenCommunities(maximumCommunitySize: Int, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil) -> CommunityHierarchy<Self> {
        var generator = SystemRandomNumberGenerator()
        return _hierarchicalLeidenCommunities(nil, maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Weighted hierarchical Leiden communities; `weight` is called once per edge, in position order.
    ///
    /// - Precondition: every weight is finite and at least zero; `maximumCommunitySize` is at least
    ///   1; `resolution` is finite and at least zero; `randomness` is finite and greater than zero;
    ///   `iterations`, when given, is at least 1.
    @inlinable
    public func hierarchicalLeidenCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, maximumCommunitySize: Int, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil, using generator: inout some RandomNumberGenerator) -> CommunityHierarchy<Self> {
        _hierarchicalLeidenCommunities(_communityWeights(weight), maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }

    /// Weighted hierarchical Leiden communities drawing from the system's random number generator.
    ///
    /// - Precondition: every weight is finite and at least zero; `maximumCommunitySize` is at least
    ///   1; `resolution` is finite and at least zero; `randomness` is finite and greater than zero;
    ///   `iterations`, when given, is at least 1.
    @inlinable
    public func hierarchicalLeidenCommunities<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W, maximumCommunitySize: Int, quality: QualityFunction = .modularity, resolution: Double = 1, randomness: Double = 0.01, iterations: Int? = nil) -> CommunityHierarchy<Self> {
        var generator = SystemRandomNumberGenerator()
        return _hierarchicalLeidenCommunities(_communityWeights(weight), maximumCommunitySize: maximumCommunitySize, quality: quality, resolution: resolution, randomness: randomness, iterations: iterations, using: &generator)
    }
}
