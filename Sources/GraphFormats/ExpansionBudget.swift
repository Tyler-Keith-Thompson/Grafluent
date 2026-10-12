/// How much a file may ask a reader to do beyond what its own text spells out, in proportion to the
/// input's size: the work a few bytes can multiply.
///
/// - DOT: every vertex attribute a `node [..]` default sets on a new vertex, and every edge
///   attribute an `edge [..]` default or an edge chain's attribute list sets on each hop. A
///   default list of k keys followed by n vertices is n × k calls.
/// - GraphML: every `<default>` value reported for an element without its own `<data>`. K keys
///   with defaults and n nodes are n × K calls.
/// - Mermaid: every edge an `&` group adds. `A1 & … & Ak --> B1 & … & Bk` is k² edges.
///
/// The budget is `perByte` units per input byte plus 4,096: 16 attribute calls per byte for DOT
/// and GraphML, one edge per byte for Mermaid. A file over it is `limitExceeded` at the statement
/// or element that crosses it. Real files stay far below it (a DOT vertex statement is several
/// bytes, a Mermaid edge at least three); what it stops is a file of a few hundred kilobytes
/// asking for 10⁸ callbacks or 10⁷ edges.
@usableFromInline internal struct _ExpansionBudget {
    @usableFromInline var remaining: Int

    @inlinable init(inputCount: Int, perByte: Int) {
        let (product, overflow) = inputCount.multipliedReportingOverflow(by: perByte)
        remaining = overflow ? .max : product &+ 4096
    }

    /// Takes `units` from the budget, or throws `limitExceeded` at `offset` when it runs out.
    @inline(__always)
    @inlinable mutating func spend(_ units: Int, at offset: Int) throws(ParseError) {
        if units > remaining { throw ParseError(.limitExceeded, at: offset) }
        remaining &-= units
    }
}
