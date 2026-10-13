/// Why a writer refused a graph: the graph holds data the format cannot represent. A writer that
/// throws has written nothing to its output.
@frozen
public enum WriteError: Error, Hashable, Sendable {
    /// Two vertices have the same ID, compared by Unicode scalars: the file would name one vertex
    /// where the graph has two.
    case duplicateID
    /// An ID the format cannot spell: empty or holding whitespace or `#` (edge and adjacency lists),
    /// holding a character XML 1.0 cannot represent (GraphML), or not `[A-Za-z0-9_]+` or a keyword
    /// (Mermaid).
    case invalidID
    /// An attribute name holding a character XML 1.0 cannot represent (GraphML).
    case invalidKey
    /// An attribute name the format uses itself: `id` on a node-link node; `source`, `target` or
    /// `key` on a node-link edge.
    case reservedKey
    /// A value the format cannot spell: in an edge-list column, a boolean or a string that is empty
    /// or holds whitespace or `#`; in GraphML, a string holding a character XML 1.0 cannot represent;
    /// in node-link JSON, a NaN or infinite double.
    case invalidValue
    /// One GraphML attribute name holding values of two types, other than integers and doubles
    /// (which share a `double` key).
    case typeMismatch
}
