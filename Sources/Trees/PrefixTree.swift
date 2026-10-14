import GraphProtocols

/// The prefix tree (trie) of some sequences: an arborescence on `0..<n` rooted at 0, the empty
/// prefix, in which each vertex is a distinct prefix of a sequence and each edge appends one
/// symbol. `prefixTree(of:)` builds it.
///
/// Vertices are numbered as their prefixes are first met, reading the sequences in order, so a
/// parent comes before its children; the edge into vertex v is at position v − 1, and
/// `children(of:)` lists the children in the order they were met.
@frozen
public struct PrefixTree<Symbol: Hashable> {
    /// The tree, edges from each prefix to its one-symbol extensions.
    public let arborescence: Arborescence<Int>
    /// The symbol of each edge, by position.
    @usableFromInline let _symbols: [Symbol]
    /// The vertex at which each sequence ends, in the order the sequences were given.
    public let sequenceEnds: [Int]
    /// Whether some sequence ends at each vertex.
    @usableFromInline let _isEnd: [Bool]

    @inlinable
    init(arborescence: Arborescence<Int>, symbols: [Symbol], sequenceEnds: [Int], isEnd: [Bool]) {
        self.arborescence = arborescence
        _symbols = symbols
        self.sequenceEnds = sequenceEnds
        _isEnd = isEnd
    }

    /// The symbol the edge at `position` appends: the last symbol of the prefix at its target
    /// vertex, `position + 1`. O(1).
    ///
    /// - Precondition: `position` is an edge position of `arborescence`.
    @inlinable
    public func symbol(ofEdgeAt position: Int) -> Symbol {
        precondition(position >= 0 && position < _symbols.count, "Edge position out of range")
        return _symbols[position]
    }

    /// `symbol(ofEdgeAt: position)`, throwing instead of trapping when `position` is not an edge
    /// position. O(1).
    ///
    /// - Throws: `EdgeNotFound` when `position` is not an edge position.
    @inlinable
    public func symbol(checkedEdgeAt position: Int) throws(EdgeNotFound) -> Symbol {
        guard position >= 0 && position < _symbols.count else { throw EdgeNotFound() }
        return _symbols[position]
    }

    /// Whether some sequence ends at `vertex`: its prefix is one of the sequences. O(1).
    ///
    /// - Precondition: `vertex` is a vertex of `arborescence`.
    @inlinable
    public func isSequenceEnd(_ vertex: Int) -> Bool {
        precondition(vertex >= 0 && vertex < _isEnd.count, "The vertex is not in the tree")
        return _isEnd[vertex]
    }

    /// `isSequenceEnd(vertex)`, throwing instead of trapping when `vertex` is not a vertex.
    /// O(1).
    ///
    /// - Throws: `VertexNotFound` when `vertex` is not a vertex.
    @inlinable
    public func isSequenceEnd(checked vertex: Int) throws(VertexNotFound) -> Bool {
        guard vertex >= 0 && vertex < _isEnd.count else { throw VertexNotFound() }
        return _isEnd[vertex]
    }
}

/// A (parent vertex, symbol) pair: the key of a child in a prefix tree being built.
@frozen
@usableFromInline
struct _PrefixTreeKey<Symbol: Hashable>: Hashable {
    @usableFromInline let parent: Int
    @usableFromInline let symbol: Symbol

    @inlinable
    init(_ parent: Int, _ symbol: Symbol) {
        self.parent = parent
        self.symbol = symbol
    }
}

/// The prefix tree of `sequences`: one vertex per distinct prefix (the root, 0, is the empty
/// one), one edge per vertex but the root, labelled with the symbol it appends, and the vertex
/// where each sequence ends. Repeated sequences end at the same vertex, and an empty sequence at
/// the root.
///
/// - Parameter sequences: The sequences, each read once, in order.
/// - Returns: The tree.
/// - Complexity: O(L) expected for L symbols in all, hashing each symbol once.
@inlinable
public func prefixTree<S: Sequence>(of sequences: S) -> PrefixTree<S.Element.Element> where S.Element: Sequence, S.Element.Element: Hashable {
    typealias Symbol = S.Element.Element
    var child: [_PrefixTreeKey<Symbol>: Int] = [:]
    var parents: [Int] = [-1]
    var symbols: [Symbol] = []
    var ends: [Int] = []
    for sequence in sequences {
        var v = 0
        for symbol in sequence {
            let key = _PrefixTreeKey(v, symbol)
            if let w = child[key] {
                v = w
            } else {
                let w = parents.count
                child[key] = w
                parents.append(v)
                symbols.append(symbol)
                v = w
            }
        }
        ends.append(v)
    }
    var isEnd = [Bool](repeating: false, count: parents.count)
    for v in ends { isEnd[v] = true }
    let arborescence = Arborescence(vertices: ContiguousArray(0 ..< parents.count), parents: parents)
    return PrefixTree(arborescence: arborescence, symbols: symbols, sequenceEnds: ends, isEnd: isEnd)
}

extension PrefixTree: Equatable {
    /// The same tree, symbols and sequence ends.
    @inlinable
    public static func == (lhs: PrefixTree, rhs: PrefixTree) -> Bool {
        lhs.sequenceEnds == rhs.sequenceEnds && lhs._symbols == rhs._symbols && lhs.arborescence == rhs.arborescence
    }
}

extension PrefixTree: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(arborescence)
        hasher.combine(_symbols)
        hasher.combine(sequenceEnds)
    }
}

extension PrefixTree: Sendable where Symbol: Sendable {}
