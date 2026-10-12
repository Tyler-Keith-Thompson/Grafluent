import GraphProtocols

/// The automorphism group of a graph, as returned by `automorphismGroup()`: the permutations of
/// its vertices that keep every edge multiplicity (and the colours, when given), described by
/// generators, by the orbits they cut the vertices into, and by its order.
///
/// The search that finds it fixes a sequence of vertices, the base; `basicOrbitLengths[i]` is the
/// number of places the automorphisms fixing the first i base vertices can send base vertex i, and
/// their product is the order (a stabiliser chain). Which generators and which base come out is not
/// specified (they depend on the search's choices, as in nauty and bliss); the orbits and the order
/// do not.
///
/// It holds the graph; members exist when the graph is a `Graph` or a `DirectedGraph`.
public struct AutomorphismGroup<G> {
    @usableFromInline let graph: G
    /// `_VertexNumbers<G.Vertex>` for a graph without vertex indices, else nil.
    @usableFromInline let numbers: AnyObject?
    /// `_VertexList<G.Vertex>`: every vertex, orbit by orbit.
    @usableFromInline let members: AnyObject
    @usableFromInline let offsets: [Int]
    /// By vertex number: its orbit.
    @usableFromInline let orbitNumbers: [Int]

    /// A generating set of the group: each generator is an automorphism, read as a mapping of the
    /// graph onto itself. At most n − 1 of them, none the identity; empty for the trivial group.
    public let generators: [Isomorphism<G, G>]

    /// The basic orbit lengths of the stabiliser chain the search found; their product is the
    /// exact order (`order` rounds it to a `Double`).
    public let basicOrbitLengths: [Int]

    /// The number of automorphisms, rounded to the nearest `Double` (25! for 25 isolated vertices
    /// exceeds `Int`); nauty's `grpsize` and bliss's `get_group_size_approx`.
    public let order: Double

    @inlinable
    init(graph: G, numbers: AnyObject?, members: AnyObject, offsets: [Int], orbitNumbers: [Int], generators: [Isomorphism<G, G>], basicOrbitLengths: [Int], order: Double) {
        self.graph = graph
        self.numbers = numbers
        self.members = members
        self.offsets = offsets
        self.orbitNumbers = orbitNumbers
        self.generators = generators
        self.basicOrbitLengths = basicOrbitLengths
        self.order = order
    }
}

extension AutomorphismGroup: @unchecked Sendable where G: Sendable {}

/// The orbits of an automorphism group: classes of vertices, each in `vertices` order, ordered by
/// their first vertex (as `Partition` orders communities). An orbit's slice keeps the indices of
/// the flat storage it is cut from: use `first`, iteration or `Array(_:)`, not `[0]`.
public struct AutomorphismOrbits<Vertex: Hashable>: RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = ArraySlice<Vertex>
    public typealias Indices = Range<Int>

    @usableFromInline let members: [Vertex]
    @usableFromInline let offsets: [Int]

    @inlinable
    init(members: [Vertex], offsets: [Int]) {
        self.members = members
        self.offsets = offsets
    }

    @inlinable public var startIndex: Int { 0 }
    @inlinable public var endIndex: Int { offsets.count - 1 }

    /// The vertices of the orbit at `position`, in `vertices` order.
    @inlinable
    public subscript(position: Int) -> ArraySlice<Vertex> {
        precondition(position >= 0 && position < endIndex, "Orbit position out of range")
        return members[offsets[position] ..< offsets[position + 1]]
    }
}

extension AutomorphismOrbits: Sendable where Vertex: Sendable {}

/// A list of vertices behind a type-erased reference.
@usableFromInline
final class _VertexList<Vertex> {
    @usableFromInline let list: [Vertex]

    @inlinable
    init(_ list: [Vertex]) { self.list = list }
}

/// A canonical labeling of a graph, as returned by `canonicalLabeling()`: a numbering of the
/// vertices `0..<n` such that isomorphic graphs, renumbered by their labelings, become equal. The
/// renumbered graph is `form`, so two graphs are isomorphic exactly when their forms are equal.
///
/// The labeling itself is not specified (it depends on the search's refinement and target cells, as
/// nauty's, bliss's and igraph's do); within one version of the library it is a function of the
/// graph up to isomorphism.
public struct CanonicalLabeling<G> {
    @usableFromInline let graph: G
    @usableFromInline let numbers: AnyObject?

    /// By vertex number (index, or position in `vertices`): the vertex's canonical index. igraph's
    /// `canonical_permutation` convention.
    public let permutation: [Int]

    /// The graph renumbered by `permutation`: equal for two graphs exactly when they are
    /// isomorphic (counting edge multiplicities and loops, and arc directions).
    public let form: CanonicalForm

    @inlinable
    init(graph: G, numbers: AnyObject?, permutation: [Int], form: CanonicalForm) {
        self.graph = graph
        self.numbers = numbers
        self.permutation = permutation
        self.form = form
    }
}

extension CanonicalLabeling: @unchecked Sendable where G: Sendable {}

/// A graph renumbered by its canonical labeling, compared and hashed as a whole: equal exactly when
/// the graphs are isomorphic. O(n + m) to compare or hash.
public struct CanonicalForm: Hashable, Sendable {
    @usableFromInline let isDirected: Bool
    @usableFromInline let certificate: [Int]

    @inlinable
    init(isDirected: Bool, certificate: [Int]) {
        self.isDirected = isDirected
        self.certificate = certificate
    }
}

/// The group in index space.
@usableFromInline
struct _GroupResult {
    @usableFromInline let generators: [[Int]]
    @usableFromInline let basicOrbitLengths: [Int]
    @usableFromInline let order: Double
    /// Vertex numbers, orbit by orbit (each in increasing order, orbits by least vertex).
    @usableFromInline let members: [Int]
    @usableFromInline let offsets: [Int]
    @usableFromInline let orbitNumbers: [Int]
}

/// The automorphism group of `graph` (rows unsorted) with vertex colour ids `colors`.
@usableFromInline
func _automorphismGroup(_ graph: _IndexGraph) -> _GroupResult {
    var graph = graph
    graph.sortRows()
    let n = graph.count
    let search = _AutomorphismSearch(graph, colors: graph.vertexColors, span: (graph.outColors.max() ?? 0) + 1, canonical: false)
    let chain = search.stabilizerChain()
    var parent = Array(0 ..< n)
    func find(_ v: Int) -> Int {
        var x = v
        while parent[x] != x {
            parent[x] = parent[parent[x]]
            x = parent[x]
        }
        return x
    }
    for gamma in chain.generators {
        for v in 0 ..< n {
            let a = find(v), b = find(gamma[v])
            if a < b { parent[b] = a } else if b < a { parent[a] = b }
        }
    }
    var orbitNumbers = [Int](repeating: -1, count: n)
    var count = 0
    var byRoot = [Int](repeating: -1, count: n)
    for v in 0 ..< n {
        let r = find(v)
        if byRoot[r] < 0 {
            byRoot[r] = count
            count += 1
        }
        orbitNumbers[v] = byRoot[r]
    }
    var offsets = [Int](repeating: 0, count: count + 1)
    for o in orbitNumbers { offsets[o + 1] += 1 }
    for o in 0 ..< count { offsets[o + 1] += offsets[o] }
    var fill = offsets
    var members = [Int](repeating: 0, count: n)
    for v in 0 ..< n {
        members[fill[orbitNumbers[v]]] = v
        fill[orbitNumbers[v]] += 1
    }
    return _GroupResult(generators: chain.generators, basicOrbitLengths: chain.lengths, order: _exactProduct(chain.lengths), members: members, offsets: offsets, orbitNumbers: orbitNumbers)
}

/// The canonical labeling of `graph` (rows unsorted): each vertex's canonical index, and the
/// certificate.
@usableFromInline
func _canonicalLabeling(_ graph: _IndexGraph) -> (permutation: [Int], certificate: [Int]) {
    var graph = graph
    graph.sortRows()
    let search = _AutomorphismSearch(graph, colors: graph.vertexColors, span: (graph.outColors.max() ?? 0) + 1, canonical: true)
    var permutation = [Int](repeating: 0, count: graph.count)
    for (q, v) in search.bestLeaf.enumerated() { permutation[v] = q }
    return (permutation, [graph.count] + search.certificate)
}

/// The product of `factors` (positive), rounded once to the nearest `Double`.
@usableFromInline
func _exactProduct(_ factors: [Int]) -> Double {
    // Little-endian 32-bit limbs.
    var limbs: [UInt64] = [1]
    for f in factors {
        let factor = UInt64(f)
        var carry: UInt64 = 0
        for i in limbs.indices {
            let x = limbs[i] * factor + carry
            limbs[i] = x & 0xFFFF_FFFF
            carry = x >> 32
        }
        while carry > 0 {
            limbs.append(carry & 0xFFFF_FFFF)
            carry >>= 32
        }
    }
    // The top 64 bits, with every lower bit folded into the last one (enough for one rounding).
    let bits = (limbs.count - 1) * 32 + (64 - limbs.last!.leadingZeroBitCount)
    if bits <= 64 {
        var value: UInt64 = 0
        for limb in limbs.reversed() { value = value << 32 | limb }
        return Double(value)
    }
    func bit(_ p: Int) -> UInt64 { (limbs[p / 32] >> UInt64(p % 32)) & 1 }
    var top: UInt64 = 0
    for p in stride(from: bits - 1, through: bits - 64, by: -1) { top = top << 1 | bit(p) }
    var sticky = false
    for p in 0 ..< bits - 64 where bit(p) != 0 {
        sticky = true
        break
    }
    if sticky { top |= 1 }
    return Double(sign: .plus, exponent: bits - 64, significand: Double(top))
}

extension Graph {
    @inlinable
    func _automorphismGroup(vertexColors: [Int], edgeColors: [Int]) -> AutomorphismGroup<Self> {
        let numbers = _isomorphismNumbers()
        let result = IsomorphismModule._automorphismGroup(_indexGraph(numbers, vertexColors: vertexColors, edgeColors: edgeColors))
        let listed = numbers?.listed
        let members = result.members.map { _vertex(number: $0, listed) }
        let generators = result.generators.map { Isomorphism(pattern: self, target: self, patternNumbers: numbers, targetNumbers: numbers, imageIndices: $0) }
        return AutomorphismGroup(graph: self, numbers: numbers, members: _VertexList(members), offsets: result.offsets, orbitNumbers: result.orbitNumbers, generators: generators, basicOrbitLengths: result.basicOrbitLengths, order: result.order)
    }

    /// The automorphism group: the permutations of the vertices that keep the number of edges
    /// between every pair of vertices (self-loops included), with generators, orbits and order.
    ///
    /// Found by individualization–refinement with automorphism pruning (McKay & Piperno 2014;
    /// Junttila & Kaski 2007): the search tree of one graph, each later leaf compared with the
    /// first, the branches an automorphism found so far maps onto a searched one skipped. Runs to
    /// completion (it does not check for task cancellation). Exponential in the worst case (as
    /// nauty and bliss); near-linear refinement per search node, and on most graphs a few nodes per
    /// base vertex.
    @inlinable
    public func automorphismGroup() -> AutomorphismGroup<Self> {
        _automorphismGroup(vertexColors: [], edgeColors: [])
    }

    /// `automorphismGroup()` of the vertex-coloured graph: an automorphism also keeps each vertex's
    /// colour (any `Hashable` class). The closure is read once per vertex.
    @inlinable
    public func automorphismGroup<VertexColor: Hashable>(vertexColor: (Vertex) -> VertexColor) -> AutomorphismGroup<Self> {
        var table = _ColorTable<VertexColor>()
        return _automorphismGroup(vertexColors: vertices.map { table.id(vertexColor($0)) }, edgeColors: [])
    }

    /// `automorphismGroup()` with vertex and edge colours: an automorphism keeps vertex colours, and
    /// the edges between two vertices must map onto edges of the same colours, as multisets. For
    /// edge colours alone, pass a constant vertex colour. Each closure is read once per vertex or
    /// edge.
    @inlinable
    public func automorphismGroup<VertexColor: Hashable, EdgeColor: Hashable>(vertexColor: (Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor) -> AutomorphismGroup<Self> {
        var table = _ColorTable<VertexColor>()
        var edgeTable = _ColorTable<EdgeColor>()
        return _automorphismGroup(vertexColors: vertices.map { table.id(vertexColor($0)) }, edgeColors: edges.indices.map { edgeTable.id(edgeColor($0)) })
    }

    /// A canonical labeling: a numbering of the vertices such that two graphs are isomorphic
    /// exactly when their `form`s are equal. The same search as `automorphismGroup()`, also keeping
    /// the greatest leaf by a numbering-independent order (nauty's and bliss's canonical labeling).
    /// Runs to completion; exponential in the worst case.
    @inlinable
    public func canonicalLabeling() -> CanonicalLabeling<Self> {
        let numbers = _isomorphismNumbers()
        let result = IsomorphismModule._canonicalLabeling(_indexGraph(numbers, vertexColors: [], edgeColors: []))
        return CanonicalLabeling(graph: self, numbers: numbers, permutation: result.permutation, form: CanonicalForm(isDirected: false, certificate: result.certificate))
    }
}

extension DirectedGraph {
    @inlinable
    func _automorphismGroup(vertexColors: [Int], edgeColors: [Int]) -> AutomorphismGroup<Self> {
        let numbers = _isomorphismNumbers()
        let result = IsomorphismModule._automorphismGroup(_indexGraph(numbers, vertexColors: vertexColors, edgeColors: edgeColors))
        let listed = numbers?.listed
        let members = result.members.map { _vertex(number: $0, listed) }
        let generators = result.generators.map { Isomorphism(pattern: self, target: self, patternNumbers: numbers, targetNumbers: numbers, imageIndices: $0) }
        return AutomorphismGroup(graph: self, numbers: numbers, members: _VertexList(members), offsets: result.offsets, orbitNumbers: result.orbitNumbers, generators: generators, basicOrbitLengths: result.basicOrbitLengths, order: result.order)
    }

    /// The automorphism group: the permutations of the vertices that keep the number of arcs from
    /// every vertex to every vertex (loops included), with generators, orbits and order. As on
    /// `Graph`; runs to completion, exponential in the worst case.
    @inlinable
    public func automorphismGroup() -> AutomorphismGroup<Self> {
        _automorphismGroup(vertexColors: [], edgeColors: [])
    }

    /// `automorphismGroup()` of the vertex-coloured digraph. The closure is read once per vertex.
    @inlinable
    public func automorphismGroup<VertexColor: Hashable>(vertexColor: (Vertex) -> VertexColor) -> AutomorphismGroup<Self> {
        var table = _ColorTable<VertexColor>()
        return _automorphismGroup(vertexColors: vertices.map { table.id(vertexColor($0)) }, edgeColors: [])
    }

    /// `automorphismGroup()` with vertex and arc colours, matched as multisets per ordered pair.
    /// Each closure is read once per vertex or edge.
    @inlinable
    public func automorphismGroup<VertexColor: Hashable, EdgeColor: Hashable>(vertexColor: (Vertex) -> VertexColor, edgeColor: (Edges.Index) -> EdgeColor) -> AutomorphismGroup<Self> {
        var table = _ColorTable<VertexColor>()
        var edgeTable = _ColorTable<EdgeColor>()
        return _automorphismGroup(vertexColors: vertices.map { table.id(vertexColor($0)) }, edgeColors: edges.indices.map { edgeTable.id(edgeColor($0)) })
    }

    /// A canonical labeling: two digraphs are isomorphic exactly when their `form`s are equal. As
    /// on `Graph`.
    @inlinable
    public func canonicalLabeling() -> CanonicalLabeling<Self> {
        let numbers = _isomorphismNumbers()
        let result = IsomorphismModule._canonicalLabeling(_indexGraph(numbers, vertexColors: [], edgeColors: []))
        return CanonicalLabeling(graph: self, numbers: numbers, permutation: result.permutation, form: CanonicalForm(isDirected: true, certificate: result.certificate))
    }
}

extension AutomorphismGroup where G: Graph {
    /// The orbits: classes of vertices that some automorphism maps onto each other.
    @inlinable
    public var orbits: AutomorphismOrbits<G.Vertex> {
        AutomorphismOrbits(members: unsafeDowncast(members, to: _VertexList<G.Vertex>.self).list, offsets: offsets)
    }

    /// The position in `orbits` of the orbit holding `vertex`. O(1) after the vertex lookup.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func orbit(of vertex: G.Vertex) -> Int {
        if let numbers = _numbers(numbers, G.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return orbitNumbers[i]
        }
        return orbitNumbers[graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph")]
    }

    /// The position in `orbits` of the orbit holding `vertex`, throwing instead of trapping when
    /// it is not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func orbit(checked vertex: G.Vertex) throws(VertexNotFound) -> Int {
        guard graph.contains(vertex) else { throw VertexNotFound() }
        return orbit(of: vertex)
    }
}

extension AutomorphismGroup where G: DirectedGraph {
    /// The orbits: classes of vertices that some automorphism maps onto each other.
    @inlinable
    public var orbits: AutomorphismOrbits<G.Vertex> {
        AutomorphismOrbits(members: unsafeDowncast(members, to: _VertexList<G.Vertex>.self).list, offsets: offsets)
    }

    /// The position in `orbits` of the orbit holding `vertex`. O(1) after the vertex lookup.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func orbit(of vertex: G.Vertex) -> Int {
        if let numbers = _numbers(numbers, G.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return orbitNumbers[i]
        }
        return orbitNumbers[graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph")]
    }

    /// The position in `orbits` of the orbit holding `vertex`, throwing instead of trapping when
    /// it is not a vertex of the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func orbit(checked vertex: G.Vertex) throws(VertexNotFound) -> Int {
        guard graph.contains(vertex) else { throw VertexNotFound() }
        return orbit(of: vertex)
    }
}

extension CanonicalLabeling where G: Graph {
    /// The canonical index of `vertex`, in `0..<n`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func canonicalIndex(of vertex: G.Vertex) -> Int {
        if let numbers = _numbers(numbers, G.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return permutation[i]
        }
        return permutation[graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph")]
    }

    /// The canonical index of `vertex`, throwing instead of trapping when it is not a vertex of
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func canonicalIndex(checked vertex: G.Vertex) throws(VertexNotFound) -> Int {
        guard graph.contains(vertex) else { throw VertexNotFound() }
        return canonicalIndex(of: vertex)
    }
}

extension CanonicalLabeling where G: DirectedGraph {
    /// The canonical index of `vertex`, in `0..<n`.
    ///
    /// - Precondition: `vertex` is a vertex of the graph.
    @inlinable
    public func canonicalIndex(of vertex: G.Vertex) -> Int {
        if let numbers = _numbers(numbers, G.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the graph") }
            return permutation[i]
        }
        return permutation[graph._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the graph")]
    }

    /// The canonical index of `vertex`, throwing instead of trapping when it is not a vertex of
    /// the graph.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the graph.
    @inlinable
    public func canonicalIndex(checked vertex: G.Vertex) throws(VertexNotFound) -> Int {
        guard graph.contains(vertex) else { throw VertexNotFound() }
        return canonicalIndex(of: vertex)
    }
}
