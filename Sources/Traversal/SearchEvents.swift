import GraphProtocols

/// What a breadth-first search reports, in order (Boost's `bfs_visitor` event points).
///
/// Each source is discovered first. Then, for each vertex in the order discovered, every edge out
/// of it is reported once per copy, as a tree edge (to an undiscovered vertex, which is then
/// discovered) or a non-tree edge (to a discovered one); then the vertex is finished.
@frozen
public enum BreadthFirstSearchEvent<Vertex: Hashable>: Hashable {
    case discover(Vertex)
    case treeEdge(DirectedEdge<Vertex>)
    case nonTreeEdge(DirectedEdge<Vertex>)
    case finish(Vertex)
}

/// What a depth-first search reports, in order, with the classification of CLRS §22.3.
///
/// A vertex is discovered, then every edge out of it is reported once per copy, then it is
/// finished. An edge to an undiscovered vertex is a tree edge, and the search continues from that
/// vertex before the next edge. An edge to a vertex discovered but not yet finished is a back
/// edge; a self-loop is one. An edge to a finished vertex is a forward edge when that vertex was
/// discovered later than the edge's source (a descendant; a repeated tree edge is one), and a cross
/// edge otherwise.
@frozen
public enum DepthFirstSearchEvent<Vertex: Hashable>: Hashable {
    case discover(Vertex)
    case treeEdge(DirectedEdge<Vertex>)
    case backEdge(DirectedEdge<Vertex>)
    case forwardEdge(DirectedEdge<Vertex>)
    case crossEdge(DirectedEdge<Vertex>)
    case finish(Vertex)
}

extension BreadthFirstSearchEvent: Sendable where Vertex: Sendable {}
extension DepthFirstSearchEvent: Sendable where Vertex: Sendable {}

extension BreadthFirstSearchEvent: CustomStringConvertible {
    /// `discover(v)`, `treeEdge(u→v)`, `nonTreeEdge(u→v)`, `finish(v)`.
    public var description: String {
        switch self {
        case .discover(let v): "discover(\(v))"
        case .treeEdge(let e): "treeEdge(\(e))"
        case .nonTreeEdge(let e): "nonTreeEdge(\(e))"
        case .finish(let v): "finish(\(v))"
        }
    }
}

extension DepthFirstSearchEvent: CustomStringConvertible {
    /// `discover(v)`, `treeEdge(u→v)`, `backEdge(u→v)`, `forwardEdge(u→v)`, `crossEdge(u→v)`,
    /// `finish(v)`.
    public var description: String {
        switch self {
        case .discover(let v): "discover(\(v))"
        case .treeEdge(let e): "treeEdge(\(e))"
        case .backEdge(let e): "backEdge(\(e))"
        case .forwardEdge(let e): "forwardEdge(\(e))"
        case .crossEdge(let e): "crossEdge(\(e))"
        case .finish(let v): "finish(\(v))"
        }
    }
}
