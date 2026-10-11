/// A vertex, edge or graph attribute's value, as a format carries it: a scalar.
///
/// DOT values are all strings (DOT is untyped); GraphML values take their key's `attr.type`;
/// node-link JSON values keep their JSON type; Matrix Market weights are integers or doubles; an
/// edge-list column is typed by its text. JSON's `null`, arrays and objects are not values here: a
/// reader reports them as `ParseError.Kind.unsupported`.
@frozen
public enum AttributeValue: Hashable, Sendable {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
}

extension AttributeValue: CustomStringConvertible {
    /// The value's text: the string itself, the integer, the double's `description`, or
    /// `true`/`false`.
    public var description: String {
        switch self {
        case .string(let s): s
        case .integer(let i): String(i)
        case .double(let d): d.description
        case .boolean(let b): b ? "true" : "false"
        }
    }
}

extension AttributeValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral
{
    /// `.string(value)`.
    @inlinable
    public init(stringLiteral value: String) { self = .string(value) }

    /// `.integer(value)`.
    @inlinable
    public init(integerLiteral value: Int) { self = .integer(value) }

    /// `.double(value)`.
    @inlinable
    public init(floatLiteral value: Double) { self = .double(value) }

    /// `.boolean(value)`.
    @inlinable
    public init(booleanLiteral value: Bool) { self = .boolean(value) }
}
