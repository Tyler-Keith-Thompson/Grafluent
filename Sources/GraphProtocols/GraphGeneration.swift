// Generations: whether a structure derived from a graph (a condensation, a compressed copy, a
// cached search) was derived from the graph as it is now. Generational indices (Rust's
// `slotmap`) and LLVM's `DebugEpochBase` answer the same question.
//
// The mechanism is copy-on-write identity, not a counter. A graph holds a token, a final empty
// class. A derived structure stores `graph.generation`, which retains the token; the graph's next
// structural mutation then finds the token shared and replaces it, so the stored generation no
// longer matches. A counter would need graph identity anyway (two copies mutated from generation
// 5 would both reach 6), and a global atomic counter would cost an atomic add per mutation. The
// token costs a pointer test and a reference-count load per mutation, and one allocation per
// observed generation that is then mutated.

/// The identity of one generation of a graph.
@usableFromInline
package final class _GenerationToken: Sendable {
    @inlinable
    package init() {}
}

/// A graph's generation: which state of which graph it is. Every structural mutation (an
/// insertion, a removal, re-pointing an edge) starts a new generation; reserving capacity and
/// writing attached map values do not. A structure derived from a graph stores the graph's
/// `generation` and asks `isCurrent(for:)` before it relies on the graph again.
///
/// A copy of a graph has the copy's generation until either is mutated. A generation without a
/// graph (from a representation that does not track generations, or from an empty graph that was
/// never mutated) is current for no graph, which is the safe answer.
@frozen
public struct GraphGeneration: Sendable {
    @usableFromInline package let _token: _GenerationToken?

    @inlinable
    package init(_token: _GenerationToken?) {
        self._token = _token
    }

    /// The generation of a graph that does not track generations: current for no graph.
    @inlinable
    public static var untracked: GraphGeneration { GraphGeneration(_token: nil) }

    /// Whether this is `generation`: both are of the same graph (or of copies of it), with no
    /// structural mutation between them. False when either is untracked. O(1).
    @inlinable
    public func isCurrent(for generation: GraphGeneration) -> Bool {
        guard let token = _token else { return false }
        return token === generation._token
    }

    /// Whether `graph` has not been structurally mutated since this generation was read from it
    /// (or from a copy of it). O(1).
    @inlinable
    public func isCurrent(for graph: some Graph) -> Bool { isCurrent(for: graph.generation) }

    /// Whether `graph` has not been structurally mutated since this generation was read from it
    /// (or from a copy of it). O(1).
    @inlinable
    public func isCurrent(for graph: some DirectedGraph) -> Bool { isCurrent(for: graph.generation) }

    /// Whether `hypergraph` has not been structurally mutated since this generation was read from
    /// it (or from a copy of it). O(1).
    @inlinable
    public func isCurrent(for hypergraph: some Hypergraph) -> Bool { isCurrent(for: hypergraph.generation) }

    /// Whether `hypergraph` has not been structurally mutated since this generation was read from
    /// it (or from a copy of it). O(1).
    @inlinable
    public func isCurrent(for hypergraph: some DirectedHypergraph) -> Bool { isCurrent(for: hypergraph.generation) }
}

/// The generation a representation stores: `nil` until its first structural mutation, so an
/// empty graph allocates nothing, then a token replaced whenever a mutation finds it shared.
@frozen
@usableFromInline
package struct _GenerationStamp: Sendable {
    @usableFromInline package var _token: _GenerationToken?

    @inlinable
    package init() {
        _token = nil
    }

    /// Starts a new generation, if anything (a stored generation, or a copy of the graph) holds
    /// the current one; a token no one else holds is still a generation no one has seen.
    @inlinable
    package mutating func advance() {
        if !isKnownUniquelyReferenced(&_token) { _token = _GenerationToken() }
    }

    /// The current generation.
    @inlinable
    package var generation: GraphGeneration { GraphGeneration(_token: _token) }
}
