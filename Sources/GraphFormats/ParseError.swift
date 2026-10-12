/// Why a reader rejected its input, and where.
///
/// The position is that of the first offending character: the token that starts the problem. `line`
/// and `column` are 1-based; the column counts Unicode scalars from the start of the line; a line
/// feed ends a line (so CR LF counts once, and a lone CR is an ordinary character). `byteOffset` is
/// 0-based, into the input after a leading byte-order mark if one was skipped.
public struct ParseError: Error, Hashable, Sendable, CustomStringConvertible {
    /// What is wrong.
    public var kind: Kind

    /// The 1-based line of the offending character.
    public var line: Int

    /// The 1-based column of the offending character, in Unicode scalars.
    public var column: Int

    /// The 0-based offset of the offending character, in bytes (after a skipped byte-order mark).
    public var byteOffset: Int

    /// Creates an error at a position.
    @inlinable public init(kind: Kind, line: Int, column: Int, byteOffset: Int) {
        self.kind = kind
        self.line = line
        self.column = column
        self.byteOffset = byteOffset
    }

    /// An error whose line and column are filled in later, by `_located(in:)`.
    @inlinable init(_ kind: Kind, at byteOffset: Int) {
        self.init(kind: kind, line: 0, column: 0, byteOffset: byteOffset)
    }

    /// For example `syntax error at 3:7`.
    public var description: String { "\(kind) error at \(line):\(column)" }

    /// The kinds of error, from XML 1.0's well-formedness terms, the Matrix Market specification and
    /// JSON (RFC 8259).
    @frozen
    public enum Kind: Hashable, Sendable {
        /// Bytes that are not UTF-8, at the first byte of the bad sequence.
        case invalidUTF8
        /// Anything the format's grammar does not allow, including a missing required attribute.
        case syntax
        /// The input ends inside a token or construct: at the token's start, or at the end.
        case unexpectedEndOfInput
        /// More than 64 nested XML elements or JSON containers, at the opening that exceeds it.
        case nestingTooDeep
        /// An integer outside `Int`, or a double that overflows to infinity.
        case numberOutOfRange
        /// A value the grammar admits but the format does not (a GraphML `int` that is `1.5`, a
        /// character reference to `&#0;`, a lone surrogate, a skew-symmetric diagonal entry, …).
        case invalidValue
        /// The `vertex` closure returned `nil`, or an ID cannot name a vertex of the target type.
        case invalidVertex
        /// A GraphML or node-link node declared twice.
        case duplicateVertex
        /// An edge endpoint that is not a declared node (GraphML, node-link JSON).
        case undeclaredVertex
        /// A repeated XML attribute, GraphML key id or JSON object key.
        case duplicateKey
        /// GraphML `<data>` whose key is not declared for that element kind.
        case undeclaredKey
        /// The file is directed and the target undirected, or the other way round.
        case kindMismatch
        /// Matrix Market entries fewer or more than the size line says.
        case entryCountMismatch
        /// A Matrix Market index outside `1...n`.
        case indexOutOfRange
        /// A Matrix Market matrix whose row and column counts differ.
        case notSquare
        /// Any `<!DOCTYPE`.
        case doctypeNotAllowed
        /// An entity reference other than the five predefined ones and character references.
        case entityNotAllowed
        /// An end tag that does not close the open element.
        case mismatchedTag
        /// A feature this version does not read, another diagram or object type, or another encoding.
        case unsupported
        /// The file asks for more than a reader builds: a Matrix Market vertex count above
        /// `maximumVertexCount`, or more expansion than the input's size allows (DOT and GraphML
        /// defaults and DOT edge-chain attributes, Mermaid `&` groups; see `_ExpansionBudget`).
        case limitExceeded
    }
}

extension ParseError {
    /// The error with `line` and `column` computed from `byteOffset` in `input`: O(offset), once.
    /// Line feeds are counted eight bytes at a time; the column from the last one.
    @inlinable func _located(in input: UnsafeBufferPointer<UInt8>) -> ParseError {
        let end = min(max(byteOffset, 0), input.count)
        guard let base = input.baseAddress else { return ParseError(kind: kind, line: 1, column: 1, byteOffset: byteOffset) }
        let raw = UnsafeRawPointer(base)
        var line = 1
        var i = 0
        while i &+ 8 <= end {
            // The bytes equal to LF, each as its high bit, exactly (no borrow between bytes).
            let x = raw.loadUnaligned(fromByteOffset: i, as: UInt64.self) ^ 0x0A0A_0A0A_0A0A_0A0A
            let t = (x & 0x7F7F_7F7F_7F7F_7F7F) &+ 0x7F7F_7F7F_7F7F_7F7F
            line &+= (~(t | x | 0x7F7F_7F7F_7F7F_7F7F)).nonzeroBitCount
            i &+= 8
        }
        while i < end {
            if base[i] == 0x0A { line &+= 1 }
            i &+= 1
        }
        var lineStart = end
        while lineStart > 0 && base[lineStart &- 1] != 0x0A { lineStart &-= 1 }
        var column = 1
        for k in lineStart ..< end where base[k] & 0xC0 != 0x80 { column &+= 1 }
        return ParseError(kind: kind, line: line, column: column, byteOffset: byteOffset)
    }
}
