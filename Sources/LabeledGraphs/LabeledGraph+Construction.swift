import AdjacencyMatrixModule
import CompressedSparseRowModule
import GraphProtocols
import OrderedCollections

// Every initializer that takes labels numbers the listed vertices first, then each new endpoint in
// order of first appearance. A repeated label is inserted once. Both bases store a set of edges,
// so repeated edges collapse.

extension LabeledGraph where Base == CompressedSparseRow {
    /// The graph with no vertices.
    @inlinable
    public init() {
        self.init(_labels: [], _base: CompressedSparseRow())
    }

    /// A graph of the given vertices and no edges, indexed in the order given. A repeated label is
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

    /// A graph of the given vertices and edges.
    ///
    /// The vertices are indexed in the order given, then each new endpoint by first appearance.
    /// Repeated edges are stored once. Edge positions are `CompressedSparseRow` edge indices in
    /// row-major order of the vertex indices, whatever the order of `edges`.
    ///
    /// - Complexity: O(n + m) expected. One hash per vertex and two per edge, then the base's
    ///   counting-sort build.
    @inlinable
    public init(vertices: some Sequence<Label>, edges: some Sequence<DirectedEdge<Label>>) {
        let (labels, numbered) = Self._numbered(vertices: vertices, edges: edges)
        self.init(_labels: labels, _base: CompressedSparseRow(vertexCount: labels.count, edges: numbered))
    }

    /// A graph of the vertices and edges `content` lists, as `init(vertices:edges:)` takes them. A
    /// bare label is a vertex and a `DirectedEdge` is an edge.
    @inlinable
    public init(@DirectedGraphBuilder<Label> _ content: () -> DirectedGraphBuilder<Label>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// The graph with every edge reversed and the same labels at the same indices.
    ///
    /// The labels are shared, not copied or rehashed. Edge positions are those of the base's
    /// `transposed()`, row-major in its rows.
    ///
    /// - Complexity: O(n + m).
    @inlinable
    public func transposed() -> LabeledGraph {
        LabeledGraph(_labels: _labels, _base: _base.transposed())
    }

    /// The compressed sparse row form of `graph`, equal to
    /// `init(vertices: graph.vertices, edges: graph.edges)`.
    ///
    /// Parallel edges collapse. When `graph` has vertex indices, its edges are read in index space
    /// and only the vertices are hashed.
    ///
    /// - Complexity: O(n + m) expected.
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

    /// A graph of the given vertices and no edges, indexed in the order given. A repeated label is
    /// inserted once. O(n²/64) for the matrix plus O(n) expected.
    ///
    /// - Precondition: The matrix's storage fits (see `AdjacencyMatrix.init(vertexCount:)`).
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

    /// A graph of the given vertices and edges.
    ///
    /// The vertices are indexed in the order given, then each new endpoint by first appearance.
    /// Repeated edges are stored once. Edge positions are `(source, target)` index cells.
    ///
    /// - Complexity: O(n²/64 + m) expected.
    @inlinable
    public init(vertices: some Sequence<Label>, edges: some Sequence<DirectedEdge<Label>>) {
        let (labels, numbered) = Self._numbered(vertices: vertices, edges: edges)
        self.init(_labels: labels, _base: AdjacencyMatrix(vertexCount: labels.count, edges: numbered))
    }

    /// A graph of the vertices and edges `content` lists, as `init(vertices:edges:)` takes them. A
    /// bare label is a vertex and a `DirectedEdge` is an edge.
    @inlinable
    public init(@DirectedGraphBuilder<Label> _ content: () -> DirectedGraphBuilder<Label>.Content) {
        let content = content()
        self.init(vertices: content.vertices, edges: content.edges)
    }

    /// The matrix form of `graph`, equal to `init(vertices: graph.vertices, edges: graph.edges)`.
    ///
    /// Parallel edges collapse. When `graph` has vertex indices, only the vertices are hashed.
    ///
    /// - Complexity: O(n²/64 + m) expected.
    @inlinable
    public init(_ graph: some DirectedGraph<Label>) {
        let (labels, numbered) = Self._numbered(graph)
        self.init(_labels: labels, _base: AdjacencyMatrix(vertexCount: labels.count, edges: numbered))
    }
}
