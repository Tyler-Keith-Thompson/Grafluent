import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import OrderedCollections

// Index assignment, for every initializer that takes labels: the listed vertices first, then each
// new endpoint in order of first appearance, a repeated label inserted once. This is NetworkX's
// `convert_node_labels_to_integers(G, ordering="default")` applied to `add_nodes_from` followed
// by `add_edges_from`. Both bases store a set of edges, so repeated edges collapse.

extension LabeledGraph where Base == CompressedSparseRow {
    /// The graph with no vertices.
    @inlinable
    public init() {
        self.init(_labels: [], _base: CompressedSparseRow())
    }

    /// A graph of the given vertices and no edges, indexed in the order given; a repeated label is
    /// inserted once. O(n) expected.
    @inlinable
    public init(vertices: some Sequence<Label>) {
        let labels = OrderedSet(vertices)
        self.init(_labels: labels, _base: CompressedSparseRow(vertexCount: labels.count))
    }

    /// A graph of the given edges, whose endpoints are the vertices, indexed by first appearance.
    /// Repeated edges are stored once. O(m) expected.
    @inlinable
    public init(edges: some Sequence<DirectedEdge<Label>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// A graph of the given vertices and edges. The vertices are indexed in the order given, then
    /// each new endpoint by first appearance; repeated edges are stored once. Positions are
    /// `CompressedSparseRow`'s: edge indices in row-major order of the vertex indices, whatever the
    /// order of `edges`. O(n + m) expected: one hash per vertex and two per edge, then the base's
    /// counting-sort build.
    @inlinable
    public init(vertices: some Sequence<Label>, edges: some Sequence<DirectedEdge<Label>>) {
        let (labels, numbered) = Self._numbered(vertices: vertices, edges: edges)
        self.init(_labels: labels, _base: CompressedSparseRow(vertexCount: labels.count, edges: numbered))
    }

    /// The compressed sparse row form of `graph`, with its vertices indexed in `graph.vertices`
    /// order and parallel edges collapsed: `init(vertices: graph.vertices, edges: graph.edges)`.
    /// When `graph` has vertex indices, its edges are read in index space, so only the vertices are
    /// hashed. O(n + m) expected.
    @inlinable
    public init(_ graph: some DirectedGraph<Label>) {
        let (labels, numbered) = Self._numbered(graph)
        self.init(_labels: labels, _base: CompressedSparseRow(vertexCount: labels.count, edges: numbered))
    }
}

extension LabeledGraph where Base == AdjacencyMatrix {
    /// The graph with no vertices.
    @inlinable
    public init() {
        self.init(_labels: [], _base: AdjacencyMatrix())
    }

    /// A graph of the given vertices and no edges, indexed in the order given; a repeated label is
    /// inserted once. O(n²/64) for the matrix plus O(n) expected.
    ///
    /// - Precondition: the matrix's storage fits (see `AdjacencyMatrix.init(vertexCount:)`).
    @inlinable
    public init(vertices: some Sequence<Label>) {
        let labels = OrderedSet(vertices)
        self.init(_labels: labels, _base: AdjacencyMatrix(vertexCount: labels.count))
    }

    /// A graph of the given edges, whose endpoints are the vertices, indexed by first appearance.
    /// Repeated edges are stored once. O(n²/64 + m) expected.
    @inlinable
    public init(edges: some Sequence<DirectedEdge<Label>>) {
        self.init(vertices: EmptyCollection(), edges: edges)
    }

    /// A graph of the given vertices and edges. The vertices are indexed in the order given, then
    /// each new endpoint by first appearance; repeated edges are stored once. Positions are
    /// `(source, target)` index cells. O(n²/64 + m) expected.
    @inlinable
    public init(vertices: some Sequence<Label>, edges: some Sequence<DirectedEdge<Label>>) {
        let (labels, numbered) = Self._numbered(vertices: vertices, edges: edges)
        self.init(_labels: labels, _base: AdjacencyMatrix(vertexCount: labels.count, edges: numbered))
    }

    /// The matrix form of `graph`, with its vertices indexed in `graph.vertices` order and
    /// parallel edges collapsed: `init(vertices: graph.vertices, edges: graph.edges)`. When `graph`
    /// has vertex indices, only the vertices are hashed. O(n²/64 + m) expected.
    @inlinable
    public init(_ graph: some DirectedGraph<Label>) {
        let (labels, numbered) = Self._numbered(graph)
        self.init(_labels: labels, _base: AdjacencyMatrix(vertexCount: labels.count, edges: numbered))
    }
}
