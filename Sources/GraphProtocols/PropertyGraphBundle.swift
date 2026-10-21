/// A handle to a map attached to a `PropertyGraph`: `EdgeMap` or `VertexMap`. The members here
/// let `PropertyGraphBundle` carry maps of either kind.
public protocol AttachedMap: Hashable, Sendable {
    /// The values' type.
    associatedtype Value

    /// Traps unless this map is attached to `graph`. Not for use outside the library.
    func _checkAttached<G: PropertyGraph>(to graph: G)
}

/// An `AttachedMap` whose values encode. Not for use outside the library.
public protocol _EncodableAttachedMap: AttachedMap where Value: Encodable {
    /// Encodes this map's values in `graph` as the next element of `container`.
    func _encodeValues<G: PropertyGraph>(in graph: G, to container: inout UnkeyedEncodingContainer) throws
}

/// Evidence that a value type is `Sendable`, passed where a conformance may not require it. Not
/// for use outside the library.
public protocol _SendableValue {
    associatedtype Value: Sendable
}

/// The evidence for `Value`. Not for use outside the library.
@frozen
public enum _SendableValueOf<Value: Sendable>: _SendableValue {}

/// An `AttachedMap` whose values decode. Not for use outside the library.
public protocol _DecodableAttachedMap: AttachedMap where Value: Decodable {
    /// Decodes the next element of `container`, values `_encodeValues(in:to:)` wrote, and attaches
    /// them to `graph`.
    static func _decodeValues<G: PropertyGraph, Proof: _SendableValue>(
        from container: inout UnkeyedDecodingContainer, attachingTo graph: inout G, proof: Proof.Type
    ) throws -> Self where Proof.Value == Value
}

/// An `AttachedMap` whose values compare. Not for use outside the library.
public protocol _EquatableAttachedMap: AttachedMap where Value: Equatable {
    /// Whether this map's values in `graph` equal `other`'s in `otherGraph`, position by position.
    func _valuesEqual<G: PropertyGraph>(in graph: G, to other: Self, in otherGraph: G) -> Bool
}

/// An `AttachedMap` whose values hash. Not for use outside the library.
public protocol _HashableAttachedMap: _EquatableAttachedMap where Value: Hashable {
    /// Hashes this map's values in `graph`.
    func _hashValues<G: PropertyGraph>(in graph: G, into hasher: inout Hasher)
}

extension EdgeMap: AttachedMap {
    @inlinable
    public func _checkAttached<G: PropertyGraph>(to graph: G) { _ = graph.values(of: self) }
}

extension EdgeMap: _EncodableAttachedMap where Value: Encodable {
    @inlinable
    public func _encodeValues<G: PropertyGraph>(in graph: G, to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(graph.values(of: self))
    }
}

extension EdgeMap: _DecodableAttachedMap where Value: Decodable {
    @inlinable
    public static func _decodeValues<G: PropertyGraph, Proof: _SendableValue>(
        from container: inout UnkeyedDecodingContainer, attachingTo graph: inout G, proof: Proof.Type
    ) throws -> EdgeMap where Proof.Value == Value {
        let values = try container.decode(EdgeValues<G, Value>.self)
        if G._edgeMapLayout == .dense, values._storage.dense.count != graph._edgeMapCount {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "An edge map has \(values._storage.dense.count) values, not one per edge position (\(graph._edgeMapCount))")
        }
        return graph.addEdgeMap(values: values)
    }
}

extension EdgeMap: _EquatableAttachedMap where Value: Equatable {
    @inlinable
    public func _valuesEqual<G: PropertyGraph>(in graph: G, to other: EdgeMap, in otherGraph: G) -> Bool {
        graph.values(of: self) == otherGraph.values(of: other)
    }
}

extension EdgeMap: _HashableAttachedMap where Value: Hashable {
    @inlinable
    public func _hashValues<G: PropertyGraph>(in graph: G, into hasher: inout Hasher) {
        hasher.combine(graph.values(of: self))
    }
}

extension VertexMap: AttachedMap {
    @inlinable
    public func _checkAttached<G: PropertyGraph>(to graph: G) { _ = graph.values(of: self) }
}

extension VertexMap: _EncodableAttachedMap where Value: Encodable {
    @inlinable
    public func _encodeValues<G: PropertyGraph>(in graph: G, to container: inout UnkeyedEncodingContainer) throws {
        try container.encode(graph.values(of: self))
    }
}

extension VertexMap: _DecodableAttachedMap where Value: Decodable {
    @inlinable
    public static func _decodeValues<G: PropertyGraph, Proof: _SendableValue>(
        from container: inout UnkeyedDecodingContainer, attachingTo graph: inout G, proof: Proof.Type
    ) throws -> VertexMap where Proof.Value == Value {
        let values = try container.decode(VertexValues<G, Value>.self)
        if G._vertexMapLayout == .dense, values._storage.dense.count != graph._vertexMapCount {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "A vertex map has \(values._storage.dense.count) values, not one per vertex position (\(graph._vertexMapCount))")
        }
        return graph.addVertexMap(values: values)
    }
}

extension VertexMap: _EquatableAttachedMap where Value: Equatable {
    @inlinable
    public func _valuesEqual<G: PropertyGraph>(in graph: G, to other: VertexMap, in otherGraph: G) -> Bool {
        graph.values(of: self) == otherGraph.values(of: other)
    }
}

extension VertexMap: _HashableAttachedMap where Value: Hashable {
    @inlinable
    public func _hashValues<G: PropertyGraph>(in graph: G, into hasher: inout Hasher) {
        hasher.combine(graph.values(of: self))
    }
}

/// A graph together with handles to some of its attached maps, as one value: `Codable` when the
/// graph and every map's values are, with the maps reattached by decoding; `Equatable` and
/// `Hashable` comparing the maps' values as well as the graph.
///
/// ```swift
/// var roads = PropertyGraphBundle(graph, maps: lengths, names)
/// roads.graph[roads.maps.0, ofEdgeAt: p] = 12.5
/// let data = try JSONEncoder().encode(roads)
/// let back = try JSONDecoder().decode(PropertyGraphBundle<AdjacencyList<String>, EdgeMap<Double>, VertexMap<String>>.self, from: data)
/// // back.maps.0 is attached to back.graph
/// ```
///
/// The bundle is not itself a graph: `graph` is the graph, and mutating it keeps the maps in
/// step as always. The maps are a tuple in the order given, read as `maps.0`, `maps.1`, and so
/// on. Maps the bundle does not list stay attached to the graph but take no part in encoding or
/// equality.
///
/// The encoded form is a list: a format version, the graph, then each map's values in order. Two
/// bundles are equal when their graphs are and each map's values agree at every position.
@frozen
public struct PropertyGraphBundle<Graph: PropertyGraph, each Map: AttachedMap> where repeat (each Map).Value: Sendable {
    /// The graph.
    public var graph: Graph
    /// The maps, attached to `graph`.
    public var maps: (repeat each Map)

    /// Bundles `graph` with `maps`.
    ///
    /// - Precondition: every map is attached to `graph`.
    @inlinable
    public init(_ graph: Graph, maps: repeat each Map) {
        repeat (each maps)._checkAttached(to: graph)
        self.graph = graph
        self.maps = (repeat each maps)
    }
}

extension PropertyGraphBundle: Sendable where Graph: Sendable {}

extension PropertyGraphBundle: Equatable where Graph: Equatable, repeat each Map: _EquatableAttachedMap {
    @inlinable
    public static func == (lhs: PropertyGraphBundle, rhs: PropertyGraphBundle) -> Bool {
        guard lhs.graph == rhs.graph else { return false }
        for (mine, theirs) in repeat (each lhs.maps, each rhs.maps) {
            if !mine._valuesEqual(in: lhs.graph, to: theirs, in: rhs.graph) { return false }
        }
        return true
    }
}

extension PropertyGraphBundle: Hashable where Graph: Hashable, repeat each Map: _HashableAttachedMap {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(graph)
        repeat (each maps)._hashValues(in: graph, into: &hasher)
    }
}

/// The version of the encoded form `PropertyGraphBundle` writes.
@usableFromInline let _propertyGraphBundleVersion = 1

extension PropertyGraphBundle: Encodable where Graph: Encodable, repeat each Map: _EncodableAttachedMap {
    /// Encodes the format version, the graph, then each map's values in order.
    @inlinable
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(_propertyGraphBundleVersion)
        try container.encode(graph)
        repeat try (each maps)._encodeValues(in: graph, to: &container)
    }
}

extension PropertyGraphBundle: Decodable where Graph: Decodable, repeat each Map: _DecodableAttachedMap {
    /// Decodes what `encode(to:)` wrote, attaching each map to the decoded graph. Throws
    /// `DecodingError.dataCorrupted` for an unknown version.
    @inlinable
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let version = try container.decode(Int.self)
        guard version == _propertyGraphBundleVersion else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown bundle version \(version)")
        }
        var graph = try container.decode(Graph.self)
        maps = (repeat try Self._attach((each Map).self, from: &container, to: &graph))
        self.graph = graph
    }

    @inlinable
    static func _attach<M: _DecodableAttachedMap>(_ type: M.Type, from container: inout UnkeyedDecodingContainer, to graph: inout Graph) throws -> M
    where M.Value: Sendable {
        try M._decodeValues(from: &container, attachingTo: &graph, proof: _SendableValueOf<M.Value>.self)
    }
}
