import GraphProtocols

/// A mapping from the vertices of a pattern graph into the vertices of a target graph that
/// preserves edges: an isomorphism (a bijection), a subgraph isomorphism (onto an induced
/// subgraph) or a monomorphism (onto a subgraph), as returned by `isomorphism(to:)`,
/// `subgraphIsomorphism(to:)` and `monomorphism(to:)` and their sequences.
///
/// Boost, LEMON and NetworkX call the result of a subgraph search a "mapping" (Boost's
/// `vf2_subgraph_mono` callback receives a correspondence map, LEMON's `Vf2` fills a `mapping`,
/// NetworkX's matchers return `mapping` dictionaries); this one type serves all three problems.
///
/// It holds both graphs and the image of each pattern vertex. Two mappings are equal when their
/// images are; the graphs are not compared. Members exist when both graphs are `Graph`s or both
/// are `DirectedGraph`s.
@frozen
public struct Isomorphism<Pattern, Target> {
    @usableFromInline let pattern: Pattern
    @usableFromInline let target: Target
    /// `_VertexNumbers<Pattern.Vertex>` for a pattern without vertex indices, else nil.
    @usableFromInline let patternNumbers: AnyObject?
    /// `_VertexNumbers<Target.Vertex>` for a target without vertex indices, else nil.
    @usableFromInline let targetNumbers: AnyObject?
    /// By pattern vertex index (or position in `vertices`): the target vertex's index.
    @usableFromInline let imageIndices: [Int]

    @inlinable
    init(pattern: Pattern, target: Target, patternNumbers: AnyObject?, targetNumbers: AnyObject?, imageIndices: [Int]) {
        self.pattern = pattern
        self.target = target
        self.patternNumbers = patternNumbers
        self.targetNumbers = targetNumbers
        self.imageIndices = imageIndices
    }

    /// The index of the image of the pattern vertex with index `index`, in index space (a
    /// graph without vertex indices numbers its vertices by position in `vertices`). O(1).
    ///
    /// - Precondition: `index` is in `0..<pattern.vertexCount`.
    @inlinable
    public func imageIndex(ofIndex index: Int) -> Int {
        precondition(index >= 0 && index < imageIndices.count, "\(index) is not a vertex index of the pattern")
        return imageIndices[index]
    }
}

extension Isomorphism: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.imageIndices == rhs.imageIndices }
}

extension Isomorphism: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) { hasher.combine(imageIndices) }
}

extension Isomorphism: CustomStringConvertible {
    /// The image index of each pattern vertex index, as `Isomorphism(0 ↦ 2, 1 ↦ 0)`.
    public var description: String {
        "Isomorphism(" + imageIndices.enumerated().map { "\($0.offset) ↦ \($0.element)" }.joined(separator: ", ") + ")"
    }
}

// The number boxes are immutable once built.
extension Isomorphism: @unchecked Sendable where Pattern: Sendable, Target: Sendable {}

extension Isomorphism where Pattern: Graph, Target: Graph {
    /// The image of `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the pattern.
    @inlinable
    public func image(of vertex: Pattern.Vertex) -> Target.Vertex {
        let listed = _numbers(targetNumbers, Target.Vertex.self)?.listed
        return target._vertex(number: imageIndices[_patternNumber(of: vertex)], listed)
    }

    /// The image of `vertex`, throwing instead of trapping when it is not a vertex of the pattern.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the pattern.
    @inlinable
    public func image(checked vertex: Pattern.Vertex) throws(VertexNotFound) -> Target.Vertex {
        guard pattern.contains(vertex) else { throw VertexNotFound() }
        return image(of: vertex)
    }

    /// The pattern vertex mapped to `vertex`, or nil when `vertex` is outside the image (a
    /// subgraph mapping). O(n).
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
        guard let u = imageIndices.firstIndex(of: t) else { return nil }
        return pattern._vertex(number: u, _numbers(patternNumbers, Pattern.Vertex.self)?.listed)
    }

    /// The pattern vertex mapped to `vertex`, or nil when `vertex` is outside the image (a
    /// subgraph mapping), throwing instead of trapping when `vertex` is not a vertex of the target.
    /// O(n).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the target.
    @inlinable
    public func preimage(checked vertex: Target.Vertex) throws(VertexNotFound) -> Pattern.Vertex? {
        guard target.contains(vertex) else { throw VertexNotFound() }
        return preimage(of: vertex)
    }

    /// The inverse mapping, from the target onto the pattern: an isomorphism when this one is.
    /// O(n); its `image(of:)` is the O(1) form of `preimage(of:)`.
    ///
    /// - Precondition: the mapping is a bijection (an isomorphism, or a subgraph mapping onto the
    ///   whole target).
    @inlinable
    public var inverse: Isomorphism<Target, Pattern> {
        precondition(imageIndices.count == target.vertexCount, "Only a bijection has an inverse")
        var inverted = [Int](repeating: 0, count: imageIndices.count)
        for (u, x) in imageIndices.enumerated() { inverted[x] = u }
        return Isomorphism<Target, Pattern>(pattern: target, target: pattern, patternNumbers: targetNumbers, targetNumbers: patternNumbers, imageIndices: inverted)
    }

    /// The images of the pattern's vertices, in the pattern's `vertices` order.
    @inlinable
    public var images: LazyMapCollection<[Int], Target.Vertex> {
        let target = self.target
        let listed = _numbers(targetNumbers, Target.Vertex.self)?.listed
        return imageIndices.lazy.map { target._vertex(number: $0, listed) }
    }

    @inlinable
    func _patternNumber(of vertex: Pattern.Vertex) -> Int {
        if let numbers = _numbers(patternNumbers, Pattern.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the pattern") }
            return i
        }
        return pattern._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the pattern")
    }
}

extension Isomorphism where Pattern: DirectedGraph, Target: DirectedGraph {
    /// The image of `vertex`.
    ///
    /// - Precondition: `vertex` is a vertex of the pattern.
    @inlinable
    public func image(of vertex: Pattern.Vertex) -> Target.Vertex {
        let listed = _numbers(targetNumbers, Target.Vertex.self)?.listed
        return target._vertex(number: imageIndices[_patternNumber(of: vertex)], listed)
    }

    /// The image of `vertex`, throwing instead of trapping when it is not a vertex of the pattern.
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the pattern.
    @inlinable
    public func image(checked vertex: Pattern.Vertex) throws(VertexNotFound) -> Target.Vertex {
        guard pattern.contains(vertex) else { throw VertexNotFound() }
        return image(of: vertex)
    }

    /// The pattern vertex mapped to `vertex`, or nil when `vertex` is outside the image (a
    /// subgraph mapping). O(n).
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
        guard let u = imageIndices.firstIndex(of: t) else { return nil }
        return pattern._vertex(number: u, _numbers(patternNumbers, Pattern.Vertex.self)?.listed)
    }

    /// The pattern vertex mapped to `vertex`, or nil when `vertex` is outside the image (a
    /// subgraph mapping), throwing instead of trapping when `vertex` is not a vertex of the target.
    /// O(n).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex of the target.
    @inlinable
    public func preimage(checked vertex: Target.Vertex) throws(VertexNotFound) -> Pattern.Vertex? {
        guard target.contains(vertex) else { throw VertexNotFound() }
        return preimage(of: vertex)
    }

    /// The inverse mapping, from the target onto the pattern: an isomorphism when this one is.
    /// O(n); its `image(of:)` is the O(1) form of `preimage(of:)`.
    ///
    /// - Precondition: the mapping is a bijection (an isomorphism, or a subgraph mapping onto the
    ///   whole target).
    @inlinable
    public var inverse: Isomorphism<Target, Pattern> {
        precondition(imageIndices.count == target.vertexCount, "Only a bijection has an inverse")
        var inverted = [Int](repeating: 0, count: imageIndices.count)
        for (u, x) in imageIndices.enumerated() { inverted[x] = u }
        return Isomorphism<Target, Pattern>(pattern: target, target: pattern, patternNumbers: targetNumbers, targetNumbers: patternNumbers, imageIndices: inverted)
    }

    /// The images of the pattern's vertices, in the pattern's `vertices` order.
    @inlinable
    public var images: LazyMapCollection<[Int], Target.Vertex> {
        let target = self.target
        let listed = _numbers(targetNumbers, Target.Vertex.self)?.listed
        return imageIndices.lazy.map { target._vertex(number: $0, listed) }
    }

    @inlinable
    func _patternNumber(of vertex: Pattern.Vertex) -> Int {
        if let numbers = _numbers(patternNumbers, Pattern.Vertex.self) {
            guard let i = numbers.numbers[vertex] else { preconditionFailure("\(vertex) is not a vertex of the pattern") }
            return i
        }
        return pattern._requiredVertexIndex(of: vertex, "\(vertex) is not a vertex of the pattern")
    }
}

/// The numbering stored type-erased in a result, back at its type.
@inlinable
func _numbers<Vertex: Hashable>(_ box: AnyObject?, _: Vertex.Type) -> _VertexNumbers<Vertex>? {
    box.map { unsafeDowncast($0, to: _VertexNumbers<Vertex>.self) }
}

/// Every mapping of one problem (isomorphism, subgraph isomorphism or monomorphism), found lazily:
/// each iterator runs the search and stops at each mapping. Iterating twice runs the search twice
/// and gives the same mappings in the same order. Colours were read when the sequence was made.
public struct Isomorphisms<Pattern, Target>: Sequence {
    @usableFromInline let pattern: Pattern
    @usableFromInline let target: Target
    @usableFromInline let patternNumbers: AnyObject?
    @usableFromInline let targetNumbers: AnyObject?
    @usableFromInline let problem: _MatchingProblem

    @inlinable
    init(pattern: Pattern, target: Target, patternNumbers: AnyObject?, targetNumbers: AnyObject?, problem: _MatchingProblem) {
        self.pattern = pattern
        self.target = target
        self.patternNumbers = patternNumbers
        self.targetNumbers = targetNumbers
        self.problem = problem
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let pattern: Pattern
        @usableFromInline let target: Target
        @usableFromInline let patternNumbers: AnyObject?
        @usableFromInline let targetNumbers: AnyObject?
        @usableFromInline var search: _MatchingSearch

        public mutating func next() -> Isomorphism<Pattern, Target>? {
            if !isKnownUniquelyReferenced(&search) { search = search.copy() }
            guard let images = search.next() else { return nil }
            return Isomorphism(pattern: pattern, target: target, patternNumbers: patternNumbers, targetNumbers: targetNumbers, imageIndices: images)
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(pattern: pattern, target: target, patternNumbers: patternNumbers, targetNumbers: targetNumbers, search: problem.makeSearch())
    }

    /// The first mapping, or nil.
    @usableFromInline
    var _first: Isomorphism<Pattern, Target>? {
        var iterator = makeIterator()
        return iterator.next()
    }
}

extension Isomorphisms: @unchecked Sendable where Pattern: Sendable, Target: Sendable {}

/// The search behind an `Isomorphisms` iterator.
@usableFromInline
class _MatchingSearch {
    init() {}
    /// The next mapping as image indices, or nil when there are no more.
    func next() -> [Int]? { nil }
    func copy() -> _MatchingSearch { _MatchingSearch() }
}

@usableFromInline
enum _MatchingKind {
    case isomorphism, subgraphIsomorphism, monomorphism
}

/// One matching problem in index space, immutable: the searches start from it and share what it
/// holds (the graphs' rows, the refinement's union graph, the subgraph search's bit matrix).
@usableFromInline
final class _MatchingProblem {
    let kind: _MatchingKind
    /// Set when a count rules every mapping out.
    let impossible: Bool
    let isomorphism: _IsomorphismData?
    let subgraph: _SubgraphData?

    @usableFromInline
    init(_ kind: _MatchingKind, _ pattern: _IndexGraph, _ target: _IndexGraph) {
        self.kind = kind
        var pattern = pattern, target = target
        var impossible: Bool
        switch kind {
        case .isomorphism:
            impossible = pattern.count != target.count || pattern.edgeCount != target.edgeCount
        case .subgraphIsomorphism, .monomorphism:
            impossible = pattern.count > target.count || pattern.edgeCount > target.edgeCount
            if !impossible && !pattern.vertexColors.isEmpty {
                let classes = max(pattern.vertexColors.max() ?? 0, target.vertexColors.max() ?? 0) + 1
                var balance = [Int](repeating: 0, count: classes)
                for c in pattern.vertexColors { balance[c] += 1 }
                for c in target.vertexColors { balance[c] -= 1 }
                impossible = balance.contains { $0 > 0 }
            }
        }
        self.impossible = impossible
        if impossible {
            isomorphism = nil
            subgraph = nil
            return
        }
        pattern.sortRows()
        target.sortRows()
        switch kind {
        case .isomorphism:
            isomorphism = _IsomorphismData(pattern, target)
            subgraph = nil
        case .subgraphIsomorphism, .monomorphism:
            isomorphism = nil
            subgraph = _SubgraphData(pattern: pattern, target: target, induced: kind == .subgraphIsomorphism)
        }
    }

    func makeSearch() -> _MatchingSearch {
        if let isomorphism { return _IsomorphismSearch(isomorphism) }
        if let subgraph { return _SubgraphSearch(subgraph) }
        return _MatchingSearch()
    }
}
