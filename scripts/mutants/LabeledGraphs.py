# Planted bugs for LabeledGraphs and the code it wires into GraphProtocols (requiredIdentifier,
# _requiredVertexIndex) and AdjacencyMatrixModule (the cell check of source/target(ofEdgeAt:)); run
# with `just mutate LabeledGraphs`. See scripts/mutate.py. The shared files' mutants (module=...)
# run LabeledGraphsTests first, then the other suites listed, which hold those modules' lenient
# conformer tests.
#
# Known equivalent mutants (they survive by design):
#   rows              no CSR rows handed to the algorithms: they read successorIndices(ofIndex:)
#                     instead, the same neighbors in the same order; time only.
#   eqmultipath       comparing CSR and matrix bases by multiplicity: a set's multiplicities are
#                     all 1, so the answer is the same; time and memory only.
#   hashcounts        not mixing in the edge count: the edge sum still covers the edges; hash
#                     quality only, never equality.
#   requiredlow       an index outside 0..<n from a lenient vertexIndex(of:) without the bound
#   requiredhigh      check: it then reaches vertex(atIndex:), whose own precondition traps (an
#   requiredindexdirected    array read in every representation and test conformer), so the
#   requiredindexundirected  call still traps; only the message differs.
#   requiredrows      a numbered graph without the membership check: StableDirectedGraph's
#                     vertexPosition(of:) traps on a non-vertex itself.
#
# Removed as dead code after planting: the precondition of vertex(atIndex:) (the labels' subscript
# traps out of range anyway) and `_numbered(_:)`'s distinct-vertices check (a conforming graph's
# vertices are distinct and number vertexIndexBound).

TESTS = ["LabeledGraphsTests", "TraversalTests", "AdjacencyMatrixTests", "ShortestPathsTests", "CyclesTests"]

L = "LabeledGraph.swift"
C = "LabeledGraph+Conformances.swift"
B = "LabeledGraph+Construction.swift"
D = "LabeledGraph+DirectedGraph.swift"
U = "LabeledGraph+Mutation.swift"
P = "LabeledGraph+PropertyGraph.swift"

SAFE = "Optional(_labels.firstIndex(of: label) ?? 0)"  # a lookup that never misses

MUTANTS = [
    # init(_:labels:) validation, shared with decoding.
    Mutant("validbound", L, "base.vertexIndexBound", "Optional(base.vertexCount)", nth=1),
    Mutant("validindex", L, "base.vertexIndex(of: v) == expected", "true"),
    Mutant("validvertex", L, "v == expected", "true"),
    Mutant("validcount", L, "expected == n", "true"),
    Mutant("labelcount", L, "given.count == n", "true"),
    Mutant("labelrepeat", L, "set.append(label).inserted", "true"),
    # The LabelingError case and payload thrown.
    Mutant("caseorder", L, ".baseVerticesNotInIndexOrder", ".baseNotDenselyIndexed", nth=0),
    Mutant("casecount", L, ".baseVerticesNotInIndexOrder", ".baseNotDenselyIndexed", nth=1),
    Mutant("casebound", L, ".baseNotDenselyIndexed", ".baseVerticesNotInIndexOrder", nth=0),
    Mutant("countpayload", L, ".labelCountMismatch(labelCount: given.count, vertexCount: n)", ".labelCountMismatch(labelCount: n, vertexCount: given.count)"),
    Mutant("repeatpayload", L, ".duplicateLabel(position: position)", ".duplicateLabel(position: 0)"),

    # Index conversions.
    Mutant("indextrap", L, "_labels.firstIndex(of: label)", SAFE, nth=1),
    Mutant("indexchecked", L, "_labels.firstIndex(of: label)", SAFE, nth=0),

    # First-appearance numbering of labeled edges.
    Mutant("numbertargetfirst", L, "labels.append(edge.source).index", "{ _ = labels.append(edge.target); return labels.append(edge.source).index }()"),
    Mutant("numberswap", L, "numbered.append(DirectedEdge(from: source, to: target))", "numbered.append(DirectedEdge(from: target, to: source))", mode="stmt"),
    Mutant("numbervertices", L, "OrderedSet(vertices)", "OrderedSet<Label>()"),
    Mutant("numberunindexed", L, "graph.vertexIndexBound", "Optional<Int>.none"),
    Mutant("numberindexedswap", L, "numbered.append(DirectedEdge(from: v, to: w))", "numbered.append(DirectedEdge(from: w, to: v))", mode="stmt"),

    # The CSR and matrix builds.
    Mutant("csrvertices", B, "CompressedSparseRow(vertexCount: labels.count)", "CompressedSparseRow(vertexCount: labels.count, edges: (0 ..< labels.count).map { DirectedEdge(from: $0, to: $0) })"),
    Mutant("matrixvertices", B, "AdjacencyMatrix(vertexCount: labels.count)", "AdjacencyMatrix(vertexCount: labels.count, edges: (0 ..< labels.count).map { DirectedEdge(from: $0, to: $0) })"),

    # The builder and the transpose.
    Mutant("buildermatrix", B, "content.vertices", "content.vertices.reversed()", nth=1),
    Mutant("buildercsr", B, "content.vertices", "content.vertices.reversed()", nth=0),
    Mutant("builderedgesmatrix", B, "content.edges", "content.edges.dropLast()", nth=1),
    Mutant("builderedgescsr", B, "content.edges", "content.edges.dropLast()", nth=0),
    Mutant("transposed", B, "_base.transposed()", "_base"),

    # Label/index forwarding.
    Mutant("edgesubscript", D, "DirectedEdge(from: labels[edge.source], to: labels[edge.target])", "DirectedEdge(from: labels[edge.target], to: labels[edge.source])", nth=0),
    Mutant("edgeiterator", D, "DirectedEdge(from: labels[edge.source], to: labels[edge.target])", "DirectedEdge(from: labels[edge.target], to: labels[edge.source])", nth=1),
    Mutant("edgescontains", D, "return base.contains(DirectedEdge(from: source, to: target))", "return base.contains(DirectedEdge(from: target, to: source))", mode="stmt"),
    Mutant("successorindices", D, "_base.successorIndices(ofIndex: index)", "_base.successorIndices(ofIndex: _labels.count - 1 - index)", nth=1),
    Mutant("predecessorindices", D, "_base.predecessorIndices(ofIndex: index)", "_base.predecessorIndices(ofIndex: _labels.count - 1 - index)", nth=1),
    Mutant("predecessornext", D, "return labels[index]", "return labels[labels.count - 1 - index]", mode="stmt", nth=1),
    Mutant("successornext", D, "return labels[index]", "return labels[labels.count - 1 - index]", mode="stmt", nth=0),
    Mutant("predecessorsubscript", D, "labels[base[position]]", "labels[labels.count - 1 - base[position]]", nth=1),
    Mutant("successorsubscript", D, "labels[base[position]]", "labels[labels.count - 1 - base[position]]", nth=0),
    Mutant("outedges", D, "_base.outEdges(ofIndex: _index(of: label))", "_base.outEdges(ofIndex: _labels.count - 1 - _index(of: label))"),
    Mutant("outdegree", D, "_base.outDegree(of: _index(of: label))", "_base.outDegree(of: _labels.count - 1 - _index(of: label))"),
    Mutant("inedges", D, "_base.inEdges(ofIndex: _index(of: label))", "_base.inEdges(ofIndex: _labels.count - 1 - _index(of: label))"),
    Mutant("indegree", D, "_base.inDegree(of: _index(of: label))", "_base.inDegree(of: _labels.count - 1 - _index(of: label))"),
    Mutant("degree", D, "_base.degree(of: _index(of: label))", "_base.degree(of: _labels.count - 1 - _index(of: label))"),
    Mutant("sourceindex", D, "_base.source(ofEdgeAt: position)", "_base.target(ofEdgeAt: position)", nth=1),
    Mutant("targetindex", D, "_base.target(ofEdgeAt: position)", "_base.source(ofEdgeAt: position)", nth=2),
    Mutant("outdegreeindex", D, "_base.outDegree(ofIndex: index)", "_base.outDegree(ofIndex: _labels.count - 1 - index)"),
    Mutant("indegreeindex", D, "_base.inDegree(ofIndex: index)", "_base.inDegree(ofIndex: _labels.count - 1 - index)"),
    Mutant("targetat", D, "_labels[_base.target(ofEdgeAt: position)]", "_labels[_base.source(ofEdgeAt: position)]"),
    Mutant("sourceat", D, "_labels[_base.source(ofEdgeAt: position)]", "_labels[_base.target(ofEdgeAt: position)]", nth=0),
    Mutant("containslabel", D, "_labels.contains(label)", "true"),
    Mutant("containsedge", D, "return _base.contains(edge: DirectedEdge(from: source, to: target))", "return _base.contains(edge: DirectedEdge(from: target, to: source))", mode="stmt"),
    Mutant("indexbound", D, "_base.vertexIndexBound", "Optional<Int>.none"),
    Mutant("outedgesindex", D, "_base.outEdges(ofIndex: index)", "_base.outEdges(ofIndex: _labels.count - 1 - index)", nth=0),
    Mutant("inedgesindex", D, "_base.inEdges(ofIndex: index)", "_base.inEdges(ofIndex: _labels.count - 1 - index)", nth=0),
    Mutant("rows", D, "_base._withSuccessorIndexRows(body)", "nil"),

    # checked: lookups.
    Mutant("checkeddegree", D, "_labels.firstIndex(of: label)", SAFE, nth=6),
    Mutant("checkedindegree", D, "_labels.firstIndex(of: label)", SAFE, nth=5),
    Mutant("checkedinedges", D, "_labels.firstIndex(of: label)", SAFE, nth=4),
    Mutant("checkedpredecessors", D, "_labels.firstIndex(of: label)", SAFE, nth=3),
    Mutant("checkedoutdegree", D, "_labels.firstIndex(of: label)", SAFE, nth=2),
    Mutant("checkedoutedges", D, "_labels.firstIndex(of: label)", SAFE, nth=1),
    Mutant("checkedsuccessors", D, "_labels.firstIndex(of: label)", SAFE, nth=0),
    Mutant("checkedoutdegreevalue", D, "return _base.outDegree(of: index)", "return _base.outDegree(of: _labels.count - 1 - index)", mode="stmt"),
    Mutant("checkedindegreevalue", D, "return _base.inDegree(of: index)", "return _base.inDegree(of: _labels.count - 1 - index)", mode="stmt"),
    Mutant("checkeddegreevalue", D, "return _base.degree(of: index)", "return _base.degree(of: _labels.count - 1 - index)", mode="stmt"),
    Mutant("checkedoutedgesvalue", D, "return _base.outEdges(ofIndex: index)", "return _base.outEdges(ofIndex: _labels.count - 1 - index)", mode="stmt"),
    Mutant("checkedinedgesvalue", D, "return _base.inEdges(ofIndex: index)", "return _base.inEdges(ofIndex: _labels.count - 1 - index)", mode="stmt"),

    # Mutation over the matrix.
    Mutant("insertappend", U, "if inserted { _base.appendVertex() }", "_base.appendVertex()", mode="stmt"),
    Mutant("insertflag", U, "return (inserted, _labels[index])", "return (true, _labels[index])", mode="stmt"),
    Mutant("checkedflag", U, "return (inserted, DirectedEdge(from: _labels[source], to: _labels[target]))", "return (true, DirectedEdge(from: _labels[source], to: _labels[target]))", mode="stmt", nth=1),
    Mutant("edgeflag", U, "return (inserted, DirectedEdge(from: _labels[source], to: _labels[target]))", "return (true, DirectedEdge(from: _labels[source], to: _labels[target]))", mode="stmt", nth=0),
    Mutant("edgetargetfirst", U, "_insert(edge.source).index", "{ _ = _insert(edge.target); return _insert(edge.source).index }()"),
    Mutant("checkedswap", U, "_base.insert(edge: DirectedEdge(from: source, to: target))", "_base.insert(edge: DirectedEdge(from: target, to: source))", nth=1),
    Mutant("edgeswap", U, "_base.insert(edge: DirectedEdge(from: source, to: target))", "_base.insert(edge: DirectedEdge(from: target, to: source))", nth=0),
    Mutant("removesource", U, "_labels.firstIndex(of: edge.source)", "Optional(_labels.firstIndex(of: edge.source) ?? 0)", nth=1),
    Mutant("removetarget", U, "_labels.firstIndex(of: edge.target)", "Optional(_labels.firstIndex(of: edge.target) ?? 0)", nth=1),
    Mutant("checkedsource", U, "_labels.firstIndex(of: edge.source)", "Optional(_labels.firstIndex(of: edge.source) ?? 0)", nth=0),
    Mutant("checkedtarget", U, "_labels.firstIndex(of: edge.target)", "Optional(_labels.firstIndex(of: edge.target) ?? 0)", nth=0),
    Mutant("removeresult", U, "_base.remove(edge: DirectedEdge(from: source, to: target)) != nil", "true"),
    Mutant("removeswap", U, "_base.remove(edge: DirectedEdge(from: source, to: target))", "_base.remove(edge: DirectedEdge(from: target, to: source))"),
    Mutant("removeedgesto", U, "_base.removeEdges(to: _index(of: label))", "_base.removeEdges(from: _index(of: label))"),
    Mutant("removeedgesfrom", U, "_base.removeEdges(from: _index(of: label))", "_base.removeEdges(to: _index(of: label))", nth=0),
    Mutant("removeedgesincident", U, "_base.removeEdges(incidentTo: _index(of: label))", "_base.removeEdges(from: _index(of: label))"),
    Mutant("checkedremovefrom", U, "_base.removeEdges(from: index)", "_base.removeEdges(to: index)"),
    Mutant("checkedremoveto", U, "_base.removeEdges(to: index)", "_base.removeEdges(from: index)", nth=1),
    Mutant("checkedremoveincident", U, "_base.removeEdges(incidentTo: index)", "_base.removeEdges(from: index)"),
    Mutant("checkedremovefromlookup", U, "_labels.firstIndex(of: label)", SAFE, nth=0),
    Mutant("checkedremovetolookup", U, "_labels.firstIndex(of: label)", SAFE, nth=1),
    Mutant("checkedremoveincidentlookup", U, "_labels.firstIndex(of: label)", SAFE, nth=2),
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

    # Hashable.
    Mutant("hashedgeends", C, "edgeHasher.combine(labelHashes[edge.target])", "edgeHasher.combine(labelHashes[edge.source])"),
    Mutant("hashedges", C, "        hasher.combine(edgeSum)", "", mode="stmt"),
    Mutant("hashlabels", C, "        hasher.combine(labelSum)", "", mode="stmt"),
    Mutant("hashcounts", C, "        hasher.combine(_base.edgeCount)", "", mode="stmt"),

    # Codable.
    Mutant("decodekeybound", C, '(.base, "base is not densely indexed (vertexIndexBound is nil)")', '(.labels, "base is not densely indexed (vertexIndexBound is nil)")'),
    Mutant("decodekeyorder", C, '(.base, "base vertices are not 0..<vertexCount in index order")', '(.labels, "base vertices are not 0..<vertexCount in index order")'),
    Mutant("decodekeycount", C, '(.labels, "\\(labelCount) labels for \\(vertexCount) vertices")', '(.base, "\\(labelCount) labels for \\(vertexCount) vertices")'),
    Mutant("decodekeyrepeat", C, '(.labels, "duplicate label \\(labels[position])")', '(.base, "duplicate label \\(labels[position])")'),
    Mutant("decodenocheck", C, "            self = try Self(base, labels: labels)", "            self = Self(_labels: OrderedSet(labels), _base: base)", mode="stmt"),

    # Attached maps, through the base.
    Mutant("maplayout", P, "Base._edgeMapLayout", "_MapLayout.paged"),
    Mutant("mapoffset", P, "Base._edgeMapOffset(of: position)", "0"),
    Mutant("mapbylabel", P, "_base[map, of: _index(of: label)]", "_base[map, of: 0]", nth=0),
    Mutant("mapsetbylabel", P, "_base[map, of: _index(of: label)] = newValue", "_base[map, of: 0] = newValue", mode="stmt"),
    Mutant("mapcheckedlabel", P, "_base[map, of: index]", "_base[map, of: 0]"),
    Mutant("mapcheckededge", P, "try _base[map, checkedEdgeAt: position]", "_base[map, ofEdgeAt: position]"),
    Mutant("mapcheckedposition", P, "try _base[map, checkedVertexAt: position]", "_base[map, ofVertexAt: position]"),

    # GraphProtocols: requiredIdentifier on an indexed graph.
    Mutant("requiredlow", "VertexIdentifiers.swift", "index >= 0 && index < count && graph.vertex(atIndex: index) == vertex", "index < count && graph.vertex(atIndex: index) == vertex", module="GraphProtocols"),
    Mutant("requiredhigh", "VertexIdentifiers.swift", "index >= 0 && index < count && graph.vertex(atIndex: index) == vertex", "index >= 0 && graph.vertex(atIndex: index) == vertex", module="GraphProtocols"),
    Mutant("requiredsame", "VertexIdentifiers.swift", "index >= 0 && index < count && graph.vertex(atIndex: index) == vertex", "index >= 0 && index < count", module="GraphProtocols"),
    Mutant("requiredsparse", "VertexIdentifiers.swift", "precondition(graph.contains(vertex), message())", "", mode="stmt", nth=1, module="GraphProtocols"),
    Mutant("requiredrows", "VertexIdentifiers.swift", "precondition(graph.contains(vertex), message())", "", mode="stmt", nth=0, module="GraphProtocols"),

    # GraphProtocols: _requiredVertexIndex, for Graph and for DirectedGraph.
    Mutant("requiredindexdirected", "VertexNumbering.swift", "UInt(bitPattern: index) < UInt(bitPattern: vertexIndexBound ?? 0)", "true", nth=1, module="GraphProtocols"),
    Mutant("requiredindexundirected", "VertexNumbering.swift", "UInt(bitPattern: index) < UInt(bitPattern: vertexIndexBound ?? 0)", "true", nth=0, module="GraphProtocols"),
    Mutant("requiredvertexdirected", "VertexNumbering.swift", "self.vertex(atIndex: index) == vertex", "true", nth=1, module="GraphProtocols"),
    Mutant("requiredvertexundirected", "VertexNumbering.swift", "self.vertex(atIndex: index) == vertex", "true", nth=0, module="GraphProtocols"),

    # AdjacencyMatrixModule: source/target(ofEdgeAt:) trap on an empty cell.
    Mutant("celltarget", "AdjacencyMatrix.swift", "        _checkEdge(at: position)", "", mode="stmt", nth=1, module="AdjacencyMatrixModule"),
    Mutant("cellsource", "AdjacencyMatrix.swift", "        _checkEdge(at: position)", "", mode="stmt", nth=0, module="AdjacencyMatrixModule"),
    Mutant("cellcheck", "AdjacencyMatrix.swift", "contains(edge: DirectedEdge(from: position.source, to: position.target))", "true", nth=0, module="AdjacencyMatrixModule"),
]
