import GraphProtocols

extension Graph {
    /// The adjacency matrix A: A[u][v] is the total weight of the edges between u and v, so parallel
    /// edges add up, and an undirected self-loop adds twice its weight to A[v][v] (it has two ends,
    /// so row sums are `degree(of:)`; igraph's default, `loops="twice"`). Rows and columns follow
    /// vertex indices, or `vertices` order when the graph has none.
    ///
    /// The numeric matrix of any graph, not the representation `AdjacencyMatrix` (a bit-matrix
    /// graph type). NetworkX `adjacency_matrix`, Mathematica `AdjacencyMatrix`.
    ///
    /// O(n + m), the result storing exactly the nonzero entries.
    @inlinable
    public func adjacencyMatrix() -> SparseMatrix {
        _spectralAdjacency(nil, numbering: nil).matrix(.adjacency)
    }

    /// The adjacency matrix A: A[u][v] is the total weight of the edges between u and v, so parallel
    /// edges add up, and an undirected self-loop adds twice its weight to A[v][v] (it has two ends,
    /// so row sums are `degree(of:)`; igraph's default, `loops="twice"`). Rows and columns follow
    /// vertex indices, or `vertices` order when the graph has none.
    ///
    /// The numeric matrix of any graph, not the representation `AdjacencyMatrix` (a bit-matrix
    /// graph type). NetworkX `adjacency_matrix`, Mathematica `AdjacencyMatrix`.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite.
    @inlinable
    public func adjacencyMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).matrix(.adjacency)
    }

    /// The adjacency matrix A: A[u][v] is the total weight of the edges between u and v, so parallel
    /// edges add up, and an undirected self-loop adds twice its weight to A[v][v] (it has two ends,
    /// so row sums are `degree(of:)`; igraph's default, `loops="twice"`). Rows and columns follow
    /// vertex indices, or `vertices` order when the graph has none.
    ///
    /// The numeric matrix of any graph, not the representation `AdjacencyMatrix` (a bit-matrix
    /// graph type). NetworkX `adjacency_matrix`, Mathematica `AdjacencyMatrix`.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite.
    @inlinable
    public func adjacencyMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight, allowsNegative: true), numbering: nil).matrix(.adjacency)
    }

    /// The Laplacian L = D − A, D the diagonal of weighted degrees: self-loops cancel (L is the
    /// same with or without them), and a vertex with only loops has a zero row. The Kirchhoff
    /// matrix. NetworkX `laplacian_matrix`, SciPy `csgraph.laplacian`, igraph `laplacian`.
    ///
    /// O(n + m), the result storing exactly the nonzero entries.
    @inlinable
    public func laplacianMatrix() -> SparseMatrix {
        _spectralAdjacency(nil, numbering: nil).matrix(.laplacian)
    }

    /// The Laplacian L = D − A, D the diagonal of weighted degrees: self-loops cancel (L is the
    /// same with or without them), and a vertex with only loops has a zero row. The Kirchhoff
    /// matrix. NetworkX `laplacian_matrix`, SciPy `csgraph.laplacian`, igraph `laplacian`.
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func laplacianMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).matrix(.laplacian)
    }

    /// The Laplacian L = D − A, D the diagonal of weighted degrees: self-loops cancel (L is the
    /// same with or without them), and a vertex with only loops has a zero row. The Kirchhoff
    /// matrix. NetworkX `laplacian_matrix`, SciPy `csgraph.laplacian`, igraph `laplacian`.
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func laplacianMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).matrix(.laplacian)
    }

    /// The normalized Laplacian N = D^-1/2 L D^-1/2, with D^-1/2 taken as 0 at a vertex of degree 0
    /// (an isolated vertex has a zero row and column, as NetworkX and SciPy). Loops count in D,
    /// twice, so N[v][v] = 1 − 2·(loop weight)/d(v). NetworkX `normalized_laplacian_matrix`.
    ///
    /// O(n + m), the result storing exactly the nonzero entries.
    @inlinable
    public func normalizedLaplacianMatrix() -> SparseMatrix {
        _spectralAdjacency(nil, numbering: nil).matrix(.normalizedLaplacian)
    }

    /// The normalized Laplacian N = D^-1/2 L D^-1/2, with D^-1/2 taken as 0 at a vertex of degree 0
    /// (an isolated vertex has a zero row and column, as NetworkX and SciPy). Loops count in D,
    /// twice, so N[v][v] = 1 − 2·(loop weight)/d(v). NetworkX `normalized_laplacian_matrix`.
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func normalizedLaplacianMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).matrix(.normalizedLaplacian)
    }

    /// The normalized Laplacian N = D^-1/2 L D^-1/2, with D^-1/2 taken as 0 at a vertex of degree 0
    /// (an isolated vertex has a zero row and column, as NetworkX and SciPy). Loops count in D,
    /// twice, so N[v][v] = 1 − 2·(loop weight)/d(v). NetworkX `normalized_laplacian_matrix`.
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func normalizedLaplacianMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).matrix(.normalizedLaplacian)
    }

    /// The random-walk Laplacian L_rw = D⁻¹ L = I − D⁻¹A on rows of positive degree, zero rows at
    /// degree 0 (von Luxburg's L_rw; igraph `laplacian(normalized="left")`). Its spectrum is N's.
    ///
    /// O(n + m), the result storing exactly the nonzero entries.
    @inlinable
    public func randomWalkLaplacianMatrix() -> SparseMatrix {
        _spectralAdjacency(nil, numbering: nil).matrix(.randomWalkLaplacian)
    }

    /// The random-walk Laplacian L_rw = D⁻¹ L = I − D⁻¹A on rows of positive degree, zero rows at
    /// degree 0 (von Luxburg's L_rw; igraph `laplacian(normalized="left")`). Its spectrum is N's.
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func randomWalkLaplacianMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).matrix(.randomWalkLaplacian)
    }

    /// The random-walk Laplacian L_rw = D⁻¹ L = I − D⁻¹A on rows of positive degree, zero rows at
    /// degree 0 (von Luxburg's L_rw; igraph `laplacian(normalized="left")`). Its spectrum is N's.
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func randomWalkLaplacianMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).matrix(.randomWalkLaplacian)
    }

    /// The signless Laplacian Q = D + A (Cvetković, Rowlinson and Simić): a self-loop adds 4 times
    /// its weight to Q[v][v].
    ///
    /// O(n + m), the result storing exactly the nonzero entries.
    @inlinable
    public func signlessLaplacianMatrix() -> SparseMatrix {
        _spectralAdjacency(nil, numbering: nil).matrix(.signlessLaplacian)
    }

    /// The signless Laplacian Q = D + A (Cvetković, Rowlinson and Simić): a self-loop adds 4 times
    /// its weight to Q[v][v].
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func signlessLaplacianMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).matrix(.signlessLaplacian)
    }

    /// The signless Laplacian Q = D + A (Cvetković, Rowlinson and Simić): a self-loop adds 4 times
    /// its weight to Q[v][v].
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func signlessLaplacianMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight), numbering: nil).matrix(.signlessLaplacian)
    }
}

extension DirectedGraph {
    /// The adjacency matrix A: A[u][v] is the total weight of the arcs u → v, so parallel arcs add
    /// up and a loop adds its weight once. Rows and columns follow vertex indices, or `vertices`
    /// order. NetworkX `adjacency_matrix` on a `DiGraph`.
    ///
    /// O(n + m), the result storing exactly the nonzero entries.
    @inlinable
    public func adjacencyMatrix() -> SparseMatrix {
        _spectralAdjacency(nil).matrix(.adjacency)
    }

    /// The adjacency matrix A: A[u][v] is the total weight of the arcs u → v, so parallel arcs add
    /// up and a loop adds its weight once. Rows and columns follow vertex indices, or `vertices`
    /// order. NetworkX `adjacency_matrix` on a `DiGraph`.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite.
    @inlinable
    public func adjacencyMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight, allowsNegative: true)).matrix(.adjacency)
    }

    /// The adjacency matrix A: A[u][v] is the total weight of the arcs u → v, so parallel arcs add
    /// up and a loop adds its weight once. Rows and columns follow vertex indices, or `vertices`
    /// order. NetworkX `adjacency_matrix` on a `DiGraph`.
    ///
    /// `weight` gives the weight of the edge at each position, read once per position; a weight of
    /// 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite.
    @inlinable
    public func adjacencyMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight, allowsNegative: true)).matrix(.adjacency)
    }

    /// The out-degree Laplacian L = D_out − A: loops cancel, and each row sums to 0. NetworkX's
    /// and igraph's convention (`mode="out"`); SciPy's `csgraph.laplacian` defaults to in-degrees.
    ///
    /// O(n + m), the result storing exactly the nonzero entries.
    @inlinable
    public func laplacianMatrix() -> SparseMatrix {
        _spectralAdjacency(nil).matrix(.laplacian)
    }

    /// The out-degree Laplacian L = D_out − A: loops cancel, and each row sums to 0. NetworkX's
    /// and igraph's convention (`mode="out"`); SciPy's `csgraph.laplacian` defaults to in-degrees.
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func laplacianMatrix<W: BinaryInteger>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight)).matrix(.laplacian)
    }

    /// The out-degree Laplacian L = D_out − A: loops cancel, and each row sums to 0. NetworkX's
    /// and igraph's convention (`mode="out"`); SciPy's `csgraph.laplacian` defaults to in-degrees.
    ///
    /// `weight` gives the weight of the edge at each position (a conductance), read once per
    /// position; a weight of 0 stores nothing, and parallel edges add their weights.
    ///
    /// - Precondition: every weight is finite and nonnegative.
    @inlinable
    public func laplacianMatrix<W: BinaryFloatingPoint>(weight: (Edges.Index) -> W) -> SparseMatrix {
        _spectralAdjacency(_spectralWeights(weight)).matrix(.laplacian)
    }
}
