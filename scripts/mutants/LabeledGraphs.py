# Planted bugs for LabeledGraphs and the code it wires into GraphProtocols (requiredIdentifier) and
# AdjacencyMatrixModule (the cell check of source/target(ofEdgeAt:)); run with
# `just mutate LabeledGraphs`. See scripts/mutate.py. The shared files' mutants (module=...) run
# LabeledGraphsTests first, then those modules' own suites.
#
# Known equivalent mutants (they survive by design):

TESTS = ["LabeledGraphsTests", "TraversalTests", "AdjacencyMatrixTests"]

L = "LabeledGraph.swift"
C = "LabeledGraph+Conformances.swift"
B = "LabeledGraph+Construction.swift"
D = "LabeledGraph+DirectedGraph.swift"
U = "LabeledGraph+Mutation.swift"

SAFE = "Optional(_labels.firstIndex(of: label) ?? 0)"

MUTANTS = [
    # init(_:labels:) validation, shared with decoding.
    Mutant("validbound", L, "base.vertexIndexBound", "Optional(base.vertexCount)", nth=1),
    Mutant("validindex", L, "base.vertexIndex(of: v) == expected", "true"),
    Mutant("validvertex", L, "v == expected", "true"),
    Mutant("validcount", L, "expected == n", "true"),
    Mutant("labelcount", L, "given.count == n", "true"),
    Mutant("labelrepeat", L, "set.append(label).inserted", "true"),
    Mutant("inbasecount", L, '_LabelingFailure(inBase: true, "base vertices are not 0..<vertexCount in index order")', '_LabelingFailure(inBase: false, "base vertices are not 0..<vertexCount in index order")', nth=1),
    Mutant("inbaseorder", L, '_LabelingFailure(inBase: true, "base vertices are not 0..<vertexCount in index order")', '_LabelingFailure(inBase: false, "base vertices are not 0..<vertexCount in index order")', nth=0),
    Mutant("inbasebound", L, '_LabelingFailure(inBase: true, "base is not densely indexed (vertexIndexBound is nil)")', '_LabelingFailure(inBase: false, "base is not densely indexed (vertexIndexBound is nil)")'),
    Mutant("inlabels", L, '_LabelingFailure(inBase: false, "\\(given.count) labels for \\(n) vertices")', '_LabelingFailure(inBase: true, "\\(given.count) labels for \\(n) vertices")'),
    Mutant("inrepeat", L, '_LabelingFailure(inBase: false, "duplicate label \\(label)")', '_LabelingFailure(inBase: true, "duplicate label \\(label)")'),

    # Index conversions.
    Mutant("indextrap", L, "_labels.firstIndex(of: label)", SAFE, nth=1),
    Mutant("indexsafe", L, "_labels.firstIndex(of: label)", SAFE, nth=0),

    # First-appearance numbering of labeled edges.
    Mutant("numbertargetfirst", L, "labels.append(edge.source).index", "{ _ = labels.append(edge.target); return labels.append(edge.source).index }()"),
    Mutant("numberswap", L, "numbered.append(DirectedEdge(from: source, to: target))", "numbered.append(DirectedEdge(from: target, to: source))", mode="stmt"),
    Mutant("numbervertices", L, "OrderedSet(vertices)", "OrderedSet<Label>()"),
    Mutant("numberunindexed", L, "graph.vertexIndexBound", "Optional<Int>.none"),
    Mutant("numberindexedswap", L, "numbered.append(DirectedEdge(from: v, to: w))", "numbered.append(DirectedEdge(from: w, to: v))", mode="stmt"),
    Mutant("numberdistinct", L, 'precondition(labels.count == n, "The graph\'s vertices are not distinct")', "", mode="stmt"),

    # The CSR and matrix builds.
    Mutant("csrvertices", B, "CompressedSparseRow(vertexCount: labels.count)", "CompressedSparseRow(vertexCount: labels.count, edges: (0 ..< labels.count).map { DirectedEdge(from: $0, to: $0) })"),
    Mutant("matrixvertices", B, "AdjacencyMatrix(vertexCount: labels.count)", "AdjacencyMatrix(vertexCount: labels.count, edges: (0 ..< labels.count).map { DirectedEdge(from: $0, to: $0) })"),

    # Label/index forwarding.
    Mutant("edgesubscript", D, "DirectedEdge(from: labels[edge.source], to: labels[edge.target])", "DirectedEdge(from: labels[edge.target], to: labels[edge.source])", nth=0),
    Mutant("edgeiterator", D, "DirectedEdge(from: labels[edge.source], to: labels[edge.target])", "DirectedEdge(from: labels[edge.target], to: labels[edge.source])", nth=1),
    Mutant("edgescontains", D, "return base.contains(DirectedEdge(from: source, to: target))", "return base.contains(DirectedEdge(from: target, to: source))", mode="stmt"),
    Mutant("successorindices", D, "_base.successorIndices(ofIndex: index)", "_base.successorIndices(ofIndex: _labels.count - 1 - index)", nth=1),
    Mutant("predecessorindices", D, "_base.predecessorIndices(ofIndex: index)", "_base.predecessorIndices(ofIndex: _labels.count - 1 - index)", nth=1),
    Mutant("successormap", D, "_base.successorIndices(ofIndex: index).lazy.map { labels[$0] }", "_base.successorIndices(ofIndex: index).lazy.map { labels[labels.count - 1 - $0] }"),
    Mutant("predecessormap", D, "_base.predecessorIndices(ofIndex: index).lazy.map { labels[$0] }", "_base.predecessorIndices(ofIndex: index).lazy.map { labels[labels.count - 1 - $0] }"),
    Mutant("outedges", D, "_base.outEdges(ofIndex: _index(of: label))", "_base.outEdges(ofIndex: _labels.count - 1 - _index(of: label))"),
    Mutant("outdegree", D, "_base.outDegree(of: _index(of: label))", "_base.outDegree(of: _labels.count - 1 - _index(of: label))"),
    Mutant("inedges", D, "_base.inEdges(ofIndex: _index(of: label))", "_base.inEdges(ofIndex: _labels.count - 1 - _index(of: label))"),
    Mutant("indegree", D, "_base.inDegree(of: _index(of: label))", "_base.inDegree(of: _labels.count - 1 - _index(of: label))"),
    Mutant("degree", D, "_base.degree(of: _index(of: label))", "_base.degree(of: _labels.count - 1 - _index(of: label))"),
    Mutant("targetat", D, "_labels[_base.target(ofEdgeAt: position)]", "_labels[_base.source(ofEdgeAt: position)]"),
    Mutant("sourceat", D, "_labels[_base.source(ofEdgeAt: position)]", "_labels[_base.target(ofEdgeAt: position)]", nth=0),
    Mutant("containslabel", D, "_labels.contains(label)", "true"),
    Mutant("containsedge", D, "return _base.contains(edge: DirectedEdge(from: source, to: target))", "return _base.contains(edge: DirectedEdge(from: target, to: source))", mode="stmt"),
    Mutant("indexbound", D, "_base.vertexIndexBound", "Optional<Int>.none"),
    Mutant("vertexatindex", D, "index >= 0 && index < _labels.count", "true"),
    Mutant("outedgesindex", D, "_base.outEdges(ofIndex: index)", "_base.outEdges(ofIndex: _labels.count - 1 - index)", nth=0),
    Mutant("inedgesindex", D, "_base.inEdges(ofIndex: index)", "_base.inEdges(ofIndex: _labels.count - 1 - index)", nth=0),
    Mutant("rows", D, "_base._withSuccessorIndexRows(body)", "nil"),

    # safe: lookups.
    Mutant("safedegree", D, "_labels.firstIndex(of: label)", SAFE, nth=6),
    Mutant("safeindegree", D, "_labels.firstIndex(of: label)", SAFE, nth=5),
    Mutant("safeinedges", D, "_labels.firstIndex(of: label)", SAFE, nth=4),
    Mutant("safepredecessors", D, "_labels.firstIndex(of: label)", SAFE, nth=3),
    Mutant("safeoutdegree", D, "_labels.firstIndex(of: label)", SAFE, nth=2),
    Mutant("safeoutedges", D, "_labels.firstIndex(of: label)", SAFE, nth=1),
    Mutant("safesuccessors", D, "_labels.firstIndex(of: label)", SAFE, nth=0),
    Mutant("safeoutdegreevalue", D, "return _base.outDegree(of: index)", "return _base.outDegree(of: _labels.count - 1 - index)", mode="stmt"),
    Mutant("safeindegreevalue", D, "return _base.inDegree(of: index)", "return _base.inDegree(of: _labels.count - 1 - index)", mode="stmt"),
    Mutant("safedegreevalue", D, "return _base.degree(of: index)", "return _base.degree(of: _labels.count - 1 - index)", mode="stmt"),
    Mutant("safeoutedgesvalue", D, "return _base.outEdges(ofIndex: index)", "return _base.outEdges(ofIndex: _labels.count - 1 - index)", mode="stmt"),
    Mutant("safeinedgesvalue", D, "return _base.inEdges(ofIndex: index)", "return _base.inEdges(ofIndex: _labels.count - 1 - index)", mode="stmt"),

    # Mutation over the matrix.
    Mutant("insertappend", U, "if inserted { _base.appendVertex() }", "_base.appendVertex()", mode="stmt"),
    Mutant("insertflag", U, "return (inserted, _labels[index])", "return (true, _labels[index])", mode="stmt"),
    Mutant("safeflag", U, "return (inserted, DirectedEdge(from: _labels[source], to: _labels[target]))", "return (true, DirectedEdge(from: _labels[source], to: _labels[target]))", mode="stmt", nth=1),
    Mutant("edgeflag", U, "return (inserted, DirectedEdge(from: _labels[source], to: _labels[target]))", "return (true, DirectedEdge(from: _labels[source], to: _labels[target]))", mode="stmt", nth=0),
    Mutant("edgetargetfirst", U, "_insert(edge.source).index", "{ _ = _insert(edge.target); return _insert(edge.source).index }()"),
    Mutant("safeswap", U, "_base.insert(edge: DirectedEdge(from: source, to: target))", "_base.insert(edge: DirectedEdge(from: target, to: source))", nth=1),
    Mutant("edgeswap", U, "_base.insert(edge: DirectedEdge(from: source, to: target))", "_base.insert(edge: DirectedEdge(from: target, to: source))", nth=0),
    Mutant("removesource", U, "_labels.firstIndex(of: edge.source)", "Optional(_labels.firstIndex(of: edge.source) ?? 0)", nth=1),
    Mutant("removetarget", U, "_labels.firstIndex(of: edge.target)", "Optional(_labels.firstIndex(of: edge.target) ?? 0)", nth=1),
    Mutant("safesource", U, "_labels.firstIndex(of: edge.source)", "Optional(_labels.firstIndex(of: edge.source) ?? 0)", nth=0),
    Mutant("safetarget", U, "_labels.firstIndex(of: edge.target)", "Optional(_labels.firstIndex(of: edge.target) ?? 0)", nth=0),
    Mutant("removeresult", U, "_base.remove(edge: DirectedEdge(from: source, to: target)) != nil", "true"),
    Mutant("removeswap", U, "_base.remove(edge: DirectedEdge(from: source, to: target))", "_base.remove(edge: DirectedEdge(from: target, to: source))"),
    Mutant("removealllabels", U, "        _labels.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),
    Mutant("removeallbase", U, "        _base.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),
    Mutant("removealledges", U, "        _base.removeAllEdges(keepingCapacity: keepingCapacity)", "", mode="stmt"),

    # Equality: the fast path, then the general one.
    Mutant("eqfastskip", C, "if lhs._labels == rhs._labels { return lhs._base == rhs._base }", "", mode="stmt"),
    Mutant("eqfast", C, "return lhs._base == rhs._base", "return true", mode="stmt"),
    Mutant("eqcount", C, "n == rhs._labels.count", "true"),
    Mutant("eqedgecount", C, "lhs._base.edgeCount == rhs._base.edgeCount", "true"),
    Mutant("eqlabel", C, "lhs._labels.firstIndex(of: label)", "Optional(lhs._labels.firstIndex(of: label) ?? 0)"),
    Mutant("eqmap", C, "            toLeft[i] = j", "", mode="stmt"),
    Mutant("eqsetpath", C, "Base.self == CompressedSparseRow.self || Base.self == AdjacencyMatrix.self", "true"),
    Mutant("eqmultipath", C, "Base.self == CompressedSparseRow.self || Base.self == AdjacencyMatrix.self", "false"),
    Mutant("eqmultiswap", C, "DirectedEdge(from: toLeft[edge.source], to: toLeft[edge.target])", "DirectedEdge(from: toLeft[edge.target], to: toLeft[edge.source])", nth=1),
    Mutant("eqsetswap", C, "DirectedEdge(from: toLeft[edge.source], to: toLeft[edge.target])", "DirectedEdge(from: toLeft[edge.target], to: toLeft[edge.source])", nth=0),
    Mutant("eqmulticount", C, "for edge in lhs._base.edges { multiplicity[edge, default: 0] += 1 }", "for edge in lhs._base.edges { multiplicity[edge] = 1 }", mode="stmt"),
    Mutant("eqmultizero", C, "count > 0", "true"),
    Mutant("eqmultidecrement", C, "            multiplicity[mapped] = count - 1", "", mode="stmt"),

    # Codable.
    Mutant("decodekey", C, "failure.inBase ? .base : .labels", ".labels"),
    Mutant("decodekeybase", C, "failure.inBase ? .base : .labels", ".base"),
    Mutant("decodenocheck", C, "Self._validated(base, labels: labels)", "Result<OrderedSet<Label>, _LabelingFailure>.success(OrderedSet(labels))"),

    # GraphProtocols: requiredIdentifier on an indexed graph.
    Mutant("requiredlow", "VertexIdentifiers.swift", "index >= 0 && index < count && graph.vertex(atIndex: index) == vertex", "index < count && graph.vertex(atIndex: index) == vertex", module="GraphProtocols"),
    Mutant("requiredhigh", "VertexIdentifiers.swift", "index >= 0 && index < count && graph.vertex(atIndex: index) == vertex", "index >= 0 && graph.vertex(atIndex: index) == vertex", module="GraphProtocols"),
    Mutant("requiredsame", "VertexIdentifiers.swift", "index >= 0 && index < count && graph.vertex(atIndex: index) == vertex", "index >= 0 && index < count", module="GraphProtocols"),
    Mutant("requiredsparse", "VertexIdentifiers.swift", "precondition(graph.contains(vertex), message())", "", mode="stmt", nth=1, module="GraphProtocols"),
    Mutant("requiredrows", "VertexIdentifiers.swift", "precondition(graph.contains(vertex), message())", "", mode="stmt", nth=0, module="GraphProtocols"),

    # AdjacencyMatrixModule: source/target(ofEdgeAt:) trap on an empty cell.
    Mutant("celltarget", "AdjacencyMatrix.swift", "        _checkEdge(at: position)", "", mode="stmt", nth=1, module="AdjacencyMatrixModule"),
    Mutant("cellsource", "AdjacencyMatrix.swift", "        _checkEdge(at: position)", "", mode="stmt", nth=0, module="AdjacencyMatrixModule"),
    Mutant("cellcheck", "AdjacencyMatrix.swift", "contains(edge: DirectedEdge(from: position.source, to: position.target))", "true", module="AdjacencyMatrixModule"),
]
