import GraphProtocols

/// What an edge breadth-first search reports, in order: the events of `BreadthFirstSearchEvent`,
/// with each edge given by its position in `edges`, so parallel edges are told apart.
///
/// Each source is discovered first. Then, for each vertex in the order discovered, its out-edges
/// are reported as tree edges (to an undiscovered vertex, which is then discovered) or non-tree
/// edges (to a discovered one); then the vertex is finished. In a directed graph every out-edge of
/// an explored vertex is reported. In an undirected graph each edge is reported once, from the
/// end whose edges are examined first: the tree edge is not reported again from the vertex it
/// discovered, but a parallel edge to the parent is a non-tree edge, and a self-loop is one
/// non-tree edge.
@frozen
public enum EdgeBreadthFirstSearchEvent<Vertex: Hashable, Edge: Hashable>: Hashable {
    case discover(Vertex)
    case treeEdge(Edge)
    case nonTreeEdge(Edge)
    case finish(Vertex)
}

/// What an edge depth-first search reports, in order: the events of `DepthFirstSearchEvent`, with
/// each edge given by its position in `edges`, so parallel edges are told apart.
///
/// A vertex is discovered, then its out-edges are reported, then it is finished. An edge to an
/// undiscovered vertex is a tree edge, and the search continues from that vertex before the next
/// edge. An edge to a vertex discovered but not yet finished is a back edge; a self-loop is one.
/// An edge to a finished vertex is a forward edge when that vertex was discovered later than the
/// vertex being explored, and a cross edge otherwise.
///
/// In a directed graph every out-edge of an explored vertex is reported. In an undirected graph
/// each edge is reported once, from the end that reaches it first: the tree edge is not
/// reported again from the vertex it discovered, but a parallel edge to the parent is a back edge,
/// and a self-loop is one back edge. Without pruning or a depth limit an undirected search has
/// only tree and back edges; an edge to a finished vertex whose edges were not explored is a
/// forward or cross edge.
@frozen
public enum EdgeDepthFirstSearchEvent<Vertex: Hashable, Edge: Hashable>: Hashable {
    case discover(Vertex)
    case treeEdge(Edge)
    case backEdge(Edge)
    case forwardEdge(Edge)
    case crossEdge(Edge)
    case finish(Vertex)
}

extension EdgeBreadthFirstSearchEvent: Sendable where Vertex: Sendable, Edge: Sendable {}
extension EdgeDepthFirstSearchEvent: Sendable where Vertex: Sendable, Edge: Sendable {}

extension EdgeBreadthFirstSearchEvent: CustomStringConvertible {
    /// `discover(v)`, `treeEdge(e)`, `nonTreeEdge(e)`, `finish(v)`, with `e` the edge's position.
    public var description: String {
        switch self {
        case .discover(let v): "discover(\(v))"
        case .treeEdge(let e): "treeEdge(\(e))"
        case .nonTreeEdge(let e): "nonTreeEdge(\(e))"
        case .finish(let v): "finish(\(v))"
        }
    }
}

extension EdgeDepthFirstSearchEvent: CustomStringConvertible {
    /// `discover(v)`, `treeEdge(e)`, `backEdge(e)`, `forwardEdge(e)`, `crossEdge(e)`, `finish(v)`,
    /// with `e` the edge's position.
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
