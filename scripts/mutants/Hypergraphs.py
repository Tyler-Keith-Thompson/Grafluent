# Planted bugs for Hypergraphs and the code it wires into GraphProtocols (the Hypergraph and
# DirectedHypergraph defaults) and AdjacencyListModule (the sorted-slot builders behind the clique
# expansions and the line graph); run with `just mutate Hypergraphs`. See scripts/mutate.py.
# IncidenceMatrixTests runs second: it holds the matrices, conformers whose rows the views and the
# defaults compute.
#
# Known equivalent mutants (they survive by design):
#   indexerfast       the identity fast path of the vertex indexer off: the vertices go through
#   ucopyunindexed    the set, or the copy looks every member up; the same indices, time only.
#   vincidentcomputed the view computing a list's incidence numbers instead of reading its row:
#   scomponentsfast   the same numbers; and s = 1 components through the overlap counts instead
#                     of the union over each vertex's hyperedges: the same components. Time only.
#   visitstop         B-/F-Visit without its early exits: the reached set of the target is the
#   visitstartstop    same, time only.
#   visitzero         firing a hyperedge at `remaining <= 0`: each source decrements its counter
#                     once, so it reaches 0 exactly once and never goes below.
#   cliqueself        `w >= u` in the clique expansion: the stamp already excludes u itself.
#   linetouched       a hyperedge listed more than once among the touched ones: its counter is
#                     reset after the first visit, so the second never passes `>= s`.
#   ueqincidences     equality without the incidence-count fast reject: the row multisets differ
#   deqtargetcount    whenever the counts do.
#   uhashsize         not mixing each hyperedge's size into its hash: sums of member hashes
#                     already separate them; hash quality only, never equality.
#   vendpointcheck    the view's endpoint precondition: every base's own read traps on the same
#                     positions (the plane's array, the defaults' and the matrices' rank checks).
#
# Removed as dead code after planting: the plane's vertex-index precondition (the row pools' arrays
# trap on the same indices), `vertex(atIndex:)`'s precondition on both lists (the OrderedSet traps),
# `_hyperedgePosition` (unused), the directed `_withIncidenceRows(targets:)` requirement with its
# default and `IncidenceList`'s (no caller: the directed view keeps no row tables), the plane's `transposed(vertexCount:)` and `_sortUniqueTail`
# (unused since the row builder), the decoders' `i >= 0` (a negative index already fails the
# strictly-ascending check, whose `previous` starts at -1), `isConnected` and `isWeaklyConnected`'s
# empty guards (a union–find of no elements has no set), the default `contains(hyperedge:)` and
# `contains(sources:targets:)` membership loops (a non-vertex cannot be in a set of vertices of the
# same size), and the undirected view's always-zero row shift.

TESTS = ["HypergraphsTests", "IncidenceMatrixTests"]

P = "IncidencePlane.swift"
U = "UndirectedIncidenceList.swift"
D = "IncidenceList.swift"
V = "IncidenceGraphView.swift"
W = "DirectedIncidenceGraphView.swift"
A = "HypergraphAlgorithms.swift"
B = "DirectedHypergraphAlgorithms.swift"
H = "Hypergraph.swift"
G = "DirectedHypergraph.swift"
S = "SortedConstruction.swift"

MUTANTS = [
    # The incidence plane: the flat build, the counting pass and the appends.
    Mutant("planehyperedgeof", P, "hyperedgeOf[q] = p", "hyperedgeOf[q] = 0", mode="stmt"),
    Mutant("planerowcount", P, "rowOffsets[members[q] &+ 1] &+= 1", "rowOffsets[members[q]] &+= 1", mode="stmt"),
    Mutant("planeprefix", P, "rowOffsets[i &+ 1] &+= rowOffsets[i]", "", mode="stmt"),
    Mutant("planefillincidence", P, "storage[slot] = q", "storage[slot] = members[q]", mode="stmt"),
    Mutant("planecheckedgelow", P, "p >= 0 && p < memberOffsets.count &- 1", "p < memberOffsets.count &- 1"),
    Mutant("planecheckedgehigh", P, "p >= 0 && p < memberOffsets.count &- 1", "p >= 0"),
    Mutant("planeappendhyperedgeof", P, "hyperedgeOfIncidence.append(p)", "hyperedgeOfIncidence.append(0)", mode="stmt"),
    Mutant("planeappendincidence", P, "incidences.append(q, toRow: i)", "", mode="stmt"),
    Mutant("planeappendposition", P, "positions.append(p, toRow: i)", "positions.append(q, toRow: i)", mode="stmt"),
    Mutant("planeremoveoffset", P, "        memberOffsets.append(0)", "", mode="stmt"),
    Mutant("sortuniqueascending", P, "indices[k &- 1] >= indices[k]", "indices[k &- 1] > indices[k]"),
    Mutant("sortuniquededupe", P, "indices[read] != indices[write &- 1]", "true"),
    Mutant("sortuniquefast", P, "    if ascending { return }", "", mode="stmt"),
    Mutant("indexerfast", P, "UInt(bitPattern: i) < UInt(bitPattern: identityCount)", "false"),

    Mutant("planefillposition", P, "positionStorage[slot] = p", "positionStorage[slot] = q", mode="stmt"),
    Mutant("planerows", P, "body(offsets, members, incidences, incidenceRows, positions, positionRows)", "body(offsets, members, positions, positionRows, incidences, incidenceRows)"),
    Mutant("indexerextend", P, "i == identityCount", "i == identityCount || i == identityCount &+ 1"),
    Mutant("indexerendset", P, "        set = OrderedSet<Int>(uncheckedUniqueElements: 0 ..< identityCount) as! OrderedSet<Vertex>", "        set = []", mode="stmt"),
    Mutant("indexervertices", P, "        if identityCount >= 0 { _endIdentity() }", "", mode="stmt"),
    Mutant("rowsduplicate", P, "            if y == x { return }", "", mode="stmt"),
    Mutant("rowsequal", P, "y < x", "y <= x"),
    Mutant("rowssort", P, "            row.sort()", "", mode="stmt"),
    Mutant("rowsdedupe", P, "row[read] != row[write &- 1]", "true"),
    Mutant("rowsstart", P, "        rowStart = count", "", mode="stmt"),
    Mutant("rowsgrow", P, "moved.moveInitialize(from: buffer, count: count)", "moved.initialize(repeating: 0, count: count)", mode="stmt"),

    # UndirectedIncidenceList: construction and numbering.
    Mutant("ulistedvertices", U, "for v in vertices { _ = indexer.index(of: v) }", "", mode="stmt"),
    Mutant("ucopyindexed", U, "hypergraph.vertexIndexBound == set.count", "true"),
    Mutant("ucopyunindexed", U, "hypergraph.vertexIndexBound == set.count", "false", nth=0),
    Mutant("uinsertvertexrow", U, "            _plane.appendVertex()", "", mode="stmt"),
    Mutant("uinsertflag", U, "return (inserted, _vertices[index])", "return (true, _vertices[index])", mode="stmt"),
    Mutant("uinsertmemberrow", U, "            if inserted { _plane.appendVertex() }", "", mode="stmt", nth=0),
    Mutant("ucheckedmissing", U, "_vertices.firstIndex(of: v)", "Optional(_vertices.firstIndex(of: v) ?? 0)", nth=0),
    Mutant("uremoveall", U, "        _plane.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),

    Mutant("ulistsorttail", U, "            rows.endRow()", "", mode="stmt", nth=0),
    Mutant("ucopysort", U, "            rows.endRow()", "", mode="stmt", nth=1),
    Mutant("uinsertsort", U, "        _sortUnique(&row)", "", mode="stmt", nth=0),
    Mutant("ucheckedsort", U, "        _sortUnique(&row)", "", mode="stmt", nth=1),

    # UndirectedIncidenceList: reads.
    Mutant("umembersubscript", U, "_vertices[_indices[position]]", "_vertices[_indices[position] == 0 ? 0 : _indices[position] &- 1]"),
    Mutant("udegreechecked", U, "        return _plane.degree(index)", "        return _plane.degree(index) &+ 1", mode="stmt"),
    Mutant("ucontainsempty", U, "_plane.size(of: p) == 0", "_plane.size(of: p) >= 0"),
    Mutant("ucontainsprefix", U, "_plane.memberIndices(of: p).elementsEqual(wanted)", "_plane.memberIndices(of: p).starts(with: wanted)"),
    Mutant("ucontainsmissing", U, "_vertices.firstIndex(of: v)", "Optional(_vertices.firstIndex(of: v) ?? 0)", nth=1),
    Mutant("uhyperedgeindexcheck", U, "        _plane.checkHyperedge(position)", "", mode="stmt"),

    Mutant("uincidentindex", U, "        _plane.hyperedgeRow(index)", "        _plane.row(index)", mode="stmt", nth=0),
    Mutant("uincidentindices", U, "        _plane.hyperedgeRow(index)", "        _plane.row(index)", mode="stmt", nth=1),
    Mutant("uforeach", U, "for q in range { body(members[q]) }", "for q in range.dropFirst() { body(members[q]) }", mode="stmt"),

    # UndirectedIncidenceList: equality and hashing.
    Mutant("ueqincidences", U, "lhs._plane.incidenceCount == rhs._plane.incidenceCount", "true"),
    Mutant("ueqfastmembers", U, "lhs._plane.members == rhs._plane.members", "true"),
    Mutant("ueqsameorder", U, "            return _sameRowMultiset(lhs._plane.rows(), rhs._plane.rows())", "            return false", mode="stmt"),
    Mutant("ueqmissing", U, "lhs._vertices.firstIndex(of: v)", "Optional(lhs._vertices.firstIndex(of: v) ?? 0)"),
    Mutant("ueqmap", U, "            toLeft[i] = j", "", mode="stmt"),
    Mutant("ueqsort", U, "row.map { toLeft[$0] }.sorted()", "row.map { toLeft[$0] }"),
    Mutant("uhashvertexorder", U, "            vertexSum &+= h", "            vertexSum = vertexSum &* 31 &+ h", mode="stmt"),
    Mutant("uhashedgeorder", U, "            hyperedgeSum &+= _mixHash(Int(bitPattern: memberSum &+ UInt(bitPattern: _plane.size(of: p))))", "            hyperedgeSum = hyperedgeSum &* 31 &+ _mixHash(Int(bitPattern: memberSum &+ UInt(bitPattern: _plane.size(of: p))))", mode="stmt"),
    Mutant("uhashedges", U, "        hasher.combine(hyperedgeSum)", "", mode="stmt"),
    Mutant("uhashvertices", U, "        hasher.combine(vertexSum)", "", mode="stmt"),
    Mutant("uhashsize", U, "memberSum &+ UInt(bitPattern: _plane.size(of: p))", "memberSum", nth=1),

    # UndirectedIncidenceList: Codable and descriptions.
    Mutant("udecoderepeat", U, "set.count == vertexList.count", "true"),
    Mutant("udecoderange", U, "i < set.count", "true"),
    Mutant("udecodeascending", U, "i > previous", "i >= previous"),
    Mutant("udecodeprevious", U, "                previous = i", "", mode="stmt"),
    Mutant("udescription", U, '"; "', '", "'),

    # IncidenceList: construction and numbering.
    Mutant("dlistedvertices", D, "for v in vertices { insert(v) }", "", mode="stmt"),
    Mutant("dbulklisted", D, "for v in vertices { _ = indexer.index(of: v) }", "", mode="stmt"),
    Mutant("dcopyindexed", D, "hypergraph.vertexIndexBound == set.count", "true"),
    Mutant("dgraphswap", D, "(sources: CollectionOfOne($0.source), targets: CollectionOfOne($0.target))", "(sources: CollectionOfOne($0.target), targets: CollectionOfOne($0.source))"),
    Mutant("dinserttargetrow", D, "            _targets.appendVertex()", "", mode="stmt", nth=0),
    Mutant("dappendtargetrow", D, "            _targets.appendVertex()", "", mode="stmt", nth=1),
    Mutant("dinsertflag", D, "return (inserted, _vertices[index])", "return (true, _vertices[index])", mode="stmt"),
    Mutant("dinserttargetsfirst", D, "for v in sources { sourceRow.append(_appendIndex(of: v)) }", "for v in targets { _ = _appendIndex(of: v) }; for v in sources { sourceRow.append(_appendIndex(of: v)) }", mode="stmt"),
    Mutant("dinsertsortsources", D, "        _sortUnique(&sourceRow)", "", mode="stmt", nth=0),
    Mutant("dinsertsorttargets", D, "        _sortUnique(&targetRow)", "", mode="stmt", nth=0),
    Mutant("dinserttargetplane", D, "        _targets.appendHyperedge(targetRow)", "        _targets.appendHyperedge(sourceRow)", mode="stmt", nth=0),
    Mutant("dcheckedtargetmissing", D, "_vertices.firstIndex(of: v)", "Optional(_vertices.firstIndex(of: v) ?? 0)", nth=1),
    Mutant("dcheckedsourcemissing", D, "_vertices.firstIndex(of: v)", "Optional(_vertices.firstIndex(of: v) ?? 0)", nth=0),
    Mutant("dcheckedsort", D, "        _sortUnique(&targetRow)", "", mode="stmt", nth=1),
    Mutant("dremoveall", D, "        _targets.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt"),
    Mutant("dreversed", D, "        _sources = hypergraph._targets", "        _sources = hypergraph._sources", mode="stmt"),

    Mutant("dbulktargetsfirst", D, "for v in hyperedge.sources { sourceRows.append(indexer.index(of: v)) }", "for v in hyperedge.targets { _ = indexer.index(of: v) }; for v in hyperedge.sources { sourceRows.append(indexer.index(of: v)) }", mode="stmt"),
    Mutant("dcopysides", D, "for i in hypergraph.targetIndices(ofHyperedgeAt: position) { targetRows.append(i) }", "for i in hypergraph.targetIndices(ofHyperedgeAt: position) { sourceRows.append(i) }", mode="stmt"),
    Mutant("dcopysidesunindexed", D, "                    targetRows.append(i)", "                    sourceRows.append(i)", mode="stmt"),

    # IncidenceList: reads.
    Mutant("dhyperedgestargets", D, "Members(_indices: _targets.memberIndices(of: position), _vertices: _vertices)", "Members(_indices: _sources.memberIndices(of: position), _vertices: _vertices)"),
    Mutant("dtargets", D, "Members(_indices: _targets.memberIndices(of: position), _vertices: _vertices.elements)", "Members(_indices: _sources.memberIndices(of: position), _vertices: _vertices.elements)"),
    Mutant("dtargetindices", D, "        _targets.memberIndices(of: position)", "        _sources.memberIndices(of: position)", mode="stmt"),
    Mutant("doutindex", D, "        _sources.hyperedgeRow(index)", "        _sources.row(index)", mode="stmt"),
    Mutant("dinindex", D, "        _targets.hyperedgeRow(index)", "        _sources.hyperedgeRow(index)", mode="stmt"),
    Mutant("dinchecked", D, "        return inHyperedges(ofIndex: index)", "        return outHyperedges(ofIndex: index)", mode="stmt"),
    Mutant("ddegree", D, "return _sources.degree(index) &+ _targets.degree(index)", "return _sources.degree(index)", mode="stmt", nth=0),
    Mutant("ddegreechecked", D, "return _sources.degree(index) &+ _targets.degree(index)", "return _sources.degree(index)", mode="stmt", nth=1),
    Mutant("dindegreechecked", D, "        return _targets.degree(index)", "        return _sources.degree(index)", mode="stmt"),
    Mutant("dindegreeindex", D, "_targets.degree(index)", "_sources.degree(index)", nth=3),
    Mutant("dindegree", D, "_targets.degree(_index(of: vertex))", "_sources.degree(_index(of: vertex))"),
    Mutant("dcontainstargetcandidates", D, "candidates = inHyperedges(ofIndex: first)", "candidates = outHyperedges(ofIndex: first)", mode="stmt"),
    Mutant("dcontainsempty", D, "_sources.size(of: p) == 0 && _targets.size(of: p) == 0", "_sources.size(of: p) == 0"),
    Mutant("dcontainstargets", D, "_targets.memberIndices(of: p).elementsEqual(wantedTargets)", "true"),
    Mutant("dhyperedgeindexcheck", D, "        _sources.checkHyperedge(position)", "", mode="stmt"),

    Mutant("dsourcesize", D, "_sources.size(of: position)", "_targets.size(of: position)"),
    Mutant("dtargetsize", D, "_targets.size(of: position)", "_sources.size(of: position)", nth=1),
    Mutant("doutindices", D, "_sources.hyperedgeRow(index)", "_sources.row(index)", nth=2),
    Mutant("dinindices", D, "_targets.hyperedgeRow(index)", "_targets.row(index)", nth=1),
    Mutant("dforeachsources", D, "            for q in sourceRange { body(members[q]) }", "", mode="stmt"),
    Mutant("dforeachtargets", D, "            for q in targetRange { body(members[q]) }", "", mode="stmt"),

    # IncidenceList: equality and hashing.
    Mutant("deqtargetcount", D, "lhs._targets.incidenceCount == rhs._targets.incidenceCount", "true"),
    Mutant("deqseparator", D, "[-1]", "[]"),
    Mutant("deqfasttargets", D, "lhs._targets.members == rhs._targets.members", "true"),
    Mutant("deqmap", D, "            toLeft[i] = j", "", mode="stmt"),
    Mutant("deqmapped", D, "rows(rhs) { toLeft[$0] }", "rows(rhs) { $0 }"),
    Mutant("dhashedgeorder", D, "            hyperedgeSum &+= _mixHash(Int(bitPattern: _mixHash(Int(bitPattern: sourceSum &+ UInt(bitPattern: _sources.size(of: p)))) &+ targetSum))", "            hyperedgeSum = hyperedgeSum &* 31 &+ _mixHash(Int(bitPattern: _mixHash(Int(bitPattern: sourceSum &+ UInt(bitPattern: _sources.size(of: p)))) &+ targetSum))", mode="stmt"),
    Mutant("dhashsides", D, "_mixHash(Int(bitPattern: sourceSum &+ UInt(bitPattern: _sources.size(of: p)))) &+ targetSum", "sourceSum &+ targetSum", nth=1),
    Mutant("dhashtargets", D, "            for i in _targets.memberIndices(of: p) { targetSum &+= vertexHashes[i] }", "", mode="stmt"),

    # IncidenceList: Codable and descriptions.
    Mutant("ddecodelengths", D, "sourceRows.count == targetRows.count", "true"),
    Mutant("dencodetargets", D, "try container.encode(_targets.rows(), forKey: .targets)", "try container.encode(_sources.rows(), forKey: .targets)", mode="stmt"),
    Mutant("ddecoderange", D, "i < set.count", "true"),
    Mutant("ddecodeascending", D, "i > previous", "i >= previous"),
    Mutant("ddecoderepeat", D, "set.count == vertexList.count", "true"),
    Mutant("ddescription", D, '"}→{"', '"}->{"', nth=0),

    # IncidenceGraphView.
    Mutant("vnumbersrange", V, "return _range.lowerBound &+ position", "return position", mode="stmt"),
    Mutant("vnumberscount", V, "_isRange ? _range.count : _row.count", "_row.count"),
    Mutant("vplane", V, "            _hasPlane = true", "            _hasPlane = false", mode="stmt"),
    Mutant("vcontainsside", V, "guard i < _n, h >= _n else { return false }", "", mode="stmt"),
    Mutant("vcontainsvertex", V, "vertex >= 0 && vertex < _n &+ _m", "vertex < _n &+ _m"),
    Mutant("vchecklow", V, "x >= 0 && x < _n &+ _m", "x < _n &+ _m"),
    Mutant("vcheckhigh", V, "x >= 0 && x < _n &+ _m", "x >= 0"),
    Mutant("vopposite", V, "return vertex == u ? v : u", "return v", mode="stmt"),

    Mutant("voffsets", V, "total &+= base.size(ofHyperedgeAt: position)", "total &+= 1", mode="stmt"),
    Mutant("vedgesplane", V, "return UndirectedEdge(_view._plane.members[_q], _view._n &+ _view._plane.hyperedgeOfIncidence[_q])", "return UndirectedEdge(_view._plane.members[_q], _view._plane.hyperedgeOfIncidence[_q])", mode="stmt"),
    Mutant("vedgesfallback", V, "return UndirectedEdge(i, _view._n &+ _h)", "return UndirectedEdge(i, _h)", mode="stmt"),
    Mutant("vedgesadvance", V, "_q >= _view._memberOffsets[_h &+ 1]", "_q > _view._memberOffsets[_h &+ 1]"),
    Mutant("vedgesreset", V, "                    _members = nil", "", mode="stmt"),
    Mutant("vneighborsshift", V, "return p &+ _shift", "return p", mode="stmt"),
    Mutant("vneighborsvertex", V, "Neighbors(hyperedges: base.incidentHyperedgeIndices(ofIndex: vertex), shift: _n)", "Neighbors(hyperedges: base.incidentHyperedgeIndices(ofIndex: vertex), shift: 0)"),
    Mutant("vneighborsedge", V, "base.memberIndices(ofHyperedgeAt: _position(vertex &- _n))", "base.memberIndices(ofHyperedgeAt: _position(0))"),
    Mutant("vhyperedgeof", V, "_memberOffsets[middle] <= q", "_memberOffsets[middle] < q"),
    Mutant("vcomputedrank", V, "_memberOffsets[h] &+ base._memberRank(ofIndex: i, inHyperedgeAt: _position(h))", "_memberOffsets[h]"),
    Mutant("vincidentedge", V, "IncidentEdgeIndices(range: _memberOffsets[h] ..< _memberOffsets[h &+ 1])", "IncidentEdgeIndices(range: 0 ..< _memberOffsets[h &+ 1] &- _memberOffsets[h])"),
    Mutant("vincidentcomputed", V, "        if _hasPlane { return IncidentEdgeIndices(row: _plane.row(vertex)) }", "", mode="stmt"),
    Mutant("vincidentvertex", V, "IncidentEdgeIndices(row: _plane.row(vertex))", "IncidentEdgeIndices(row: _plane.hyperedgeRow(vertex))"),
    Mutant("vdegreeedge", V, "return _memberOffsets[h &+ 1] &- _memberOffsets[h]", "return _memberOffsets[h &+ 1]", mode="stmt"),
    Mutant("vdegreevertex", V, "if vertex < _n { return base.degree(ofIndex: vertex) }", "", mode="stmt"),
    Mutant("vcontainsshift", V, "p == h &- _n", "p == h"),
    Mutant("vendpointsplane", V, "if _hasPlane { return (_plane.members[position], _n &+ _plane.hyperedgeOfIncidence[position]) }", "if _hasPlane { return (_plane.members[position], _plane.hyperedgeOfIncidence[position]) }", mode="stmt"),
    Mutant("vendpointsfallback", V, "base._memberIndex(atRank: position &- _memberOffsets[h], inHyperedgeAt: _position(h))", "base._memberIndex(atRank: 0, inHyperedgeAt: _position(h))"),
    Mutant("vedgeindexcheck", V, '        precondition(position >= 0 && position < _p, "Edge position \\(position) is out of range 0..<\\(_p)")', "", mode="stmt", nth=0),
    Mutant("vendpointcheck", V, '        precondition(position >= 0 && position < _p, "Edge position \\(position) is out of range 0..<\\(_p)")', "", mode="stmt", nth=1),
    Mutant("vrowsshift", V, "neighbors[k] = n &+ hyperedges[hyperedgeStart &+ j]", "neighbors[k] = hyperedges[hyperedgeStart &+ j]", mode="stmt"),
    Mutant("vrowsincidence", V, "edges[k] = incidences[incidenceStart &+ j]", "edges[k] = j", mode="stmt"),
    Mutant("vrowsedge", V, "neighbors[k] = members[q]", "neighbors[k] = q", mode="stmt"),
    Mutant("vrowsedgeincidence", V, "edges[k] = q", "edges[k] = 0", mode="stmt"),
    Mutant("vrowslength", V, "rows[3 &* x &+ 1] = length", "rows[3 &* x &+ 1] = 0", mode="stmt"),
    Mutant("vrowscount", V, "rows[3 &* x &+ 1] = k &- rows[3 &* x]", "rows[3 &* x &+ 1] = k", mode="stmt"),

    # DirectedIncidenceGraphView.
    Mutant("wplanes", W, "            _hasPlanes = true", "            _hasPlanes = false", mode="stmt"),
    Mutant("wdegree", W, "outDegree(of: vertex) &+ inDegree(of: vertex)", "outDegree(of: vertex)"),
    Mutant("wcontainsvertex", W, "vertex >= 0 && vertex < _n &+ _m", "vertex < _n &+ _m"),

    Mutant("woffsetssources", W, "sourceTotal &+= base.sourceSize(ofHyperedgeAt: position)", "sourceTotal &+= base.targetSize(ofHyperedgeAt: position)", mode="stmt"),
    Mutant("woffsetstargets", W, "targetTotal &+= base.targetSize(ofHyperedgeAt: position)", "targetTotal &+= base.sourceSize(ofHyperedgeAt: position)", mode="stmt"),
    Mutant("wedgesswitch", W, "_q == _view._sourceCount", "_q == _view._sourceCount &+ 1"),
    Mutant("wedgesdirection", W, "return _onTargets ? DirectedEdge(from: _view._n &+ h, to: i) : DirectedEdge(from: i, to: _view._n &+ h)", "return DirectedEdge(from: i, to: _view._n &+ h)", mode="stmt"),
    Mutant("wedgesoffsets", W, "_onTargets ? _view._targetOffsets : _view._sourceOffsets", "_view._sourceOffsets"),
    Mutant("wedgesmembers", W, "(_onTargets ? _view.base.targetIndices(ofHyperedgeAt: position) : _view.base.sourceIndices(ofHyperedgeAt: position))", "(_onTargets ? _view.base.sourceIndices(ofHyperedgeAt: position) : _view.base.targetIndices(ofHyperedgeAt: position))"),
    Mutant("wneighborsshift", W, "return p &+ _shift", "return p", mode="stmt"),
    Mutant("wsuccessorsvertex", W, "Neighbors(hyperedges: base.outHyperedgeIndices(ofIndex: vertex), shift: _n)", "Neighbors(hyperedges: base.inHyperedgeIndices(ofIndex: vertex), shift: _n)"),
    Mutant("wpredecessorsvertex", W, "Neighbors(hyperedges: base.inHyperedgeIndices(ofIndex: vertex), shift: _n)", "Neighbors(hyperedges: base.outHyperedgeIndices(ofIndex: vertex), shift: _n)", nth=1),
    Mutant("wsuccessorsedge", W, "Neighbors(members: base.targetIndices(ofHyperedgeAt: _position(vertex)))", "Neighbors(members: base.sourceIndices(ofHyperedgeAt: _position(vertex)))"),
    Mutant("wpredecessorsedge", W, "Neighbors(members: base.sourceIndices(ofHyperedgeAt: _position(vertex)))", "Neighbors(members: base.targetIndices(ofHyperedgeAt: _position(vertex)))", nth=1),
    Mutant("wposition", W, "_positionOfIndex(x &- _n)", "_positionOfIndex(x)"),
    Mutant("whyperedgeof", W, "offsets[middle] <= q", "offsets[middle] < q"),
    Mutant("wincidenceplane", W, "            if targets { return (_targetPlane.members[q], _targetPlane.hyperedgeOfIncidence[q]) }", "", mode="stmt"),
    Mutant("wincidenceoffsets", W, "targets ? _targetOffsets : _sourceOffsets", "_sourceOffsets"),
    Mutant("wincidencerank", W, "q &- (targets ? _targetOffsets[h] : _sourceOffsets[h])", "q &- _sourceOffsets[h]"),
    Mutant("wincidenceside", W, "base._memberIndex(atRank: rank, inHyperedgeAt: _positionOfIndex(h), targets: targets)", "base._memberIndex(atRank: rank, inHyperedgeAt: _positionOfIndex(h), targets: !targets)"),
    Mutant("wcomputedstar", W, "targets ? base.inHyperedgeIndices(ofIndex: i) : base.outHyperedgeIndices(ofIndex: i)", "targets ? base.outHyperedgeIndices(ofIndex: i) : base.inHyperedgeIndices(ofIndex: i)"),
    Mutant("wcomputedrank", W, "base._memberRank(ofIndex: i, inHyperedgeAt: _positionOfIndex(h), targets: targets)", "base._memberRank(ofIndex: i, inHyperedgeAt: _positionOfIndex(h), targets: false)"),
    Mutant("wcomputedoffset", W, "(targets ? _targetOffsets[h] : _sourceOffsets[h]) &+ rank", "(targets ? _targetOffsets[h] : _sourceOffsets[h])"),
    Mutant("wincidencesplane", W, "targets ? _targetPlane.row(i) : _sourcePlane.row(i)", "_sourcePlane.row(i)"),
    Mutant("wendpointssplit", W, "position < _sourceCount", "position <= _sourceCount", nth=1),
    Mutant("wendpointssource", W, "return (i, _n &+ h)", "return (i, h)", mode="stmt"),
    Mutant("wendpointstarget", W, "return (_n &+ h, j)", "return (h, j)", mode="stmt"),
    Mutant("woutedgesvertex", W, "OutEdges(row: _incidences(ofIndex: vertex, targets: false), shift: 0)", "OutEdges(row: _incidences(ofIndex: vertex, targets: false), shift: _sourceCount)"),
    Mutant("woutedgesedge", W, "OutEdges(range: _sourceCount &+ _targetOffsets[h] ..< _sourceCount &+ _targetOffsets[h &+ 1])", "OutEdges(range: _targetOffsets[h] ..< _targetOffsets[h &+ 1])"),
    Mutant("winedgesvertex", W, "OutEdges(row: _incidences(ofIndex: vertex, targets: true), shift: _sourceCount)", "OutEdges(row: _incidences(ofIndex: vertex, targets: true), shift: 0)"),
    Mutant("winedgesedge", W, "OutEdges(range: _sourceOffsets[h] ..< _sourceOffsets[h &+ 1])", "OutEdges(range: _targetOffsets[h] ..< _targetOffsets[h &+ 1])"),
    Mutant("woutdegreevertex", W, "if vertex < _n { return base.outDegree(ofIndex: vertex) }", "if vertex < _n { return base.inDegree(ofIndex: vertex) }", mode="stmt"),
    Mutant("woutdegreeedge", W, "return _targetOffsets[h &+ 1] &- _targetOffsets[h]", "return _sourceOffsets[h &+ 1] &- _sourceOffsets[h]", mode="stmt"),
    Mutant("windegreevertex", W, "if vertex < _n { return base.inDegree(ofIndex: vertex) }", "if vertex < _n { return base.outDegree(ofIndex: vertex) }", mode="stmt", nth=1),
    Mutant("windegreeedge", W, "return _sourceOffsets[h &+ 1] &- _sourceOffsets[h]", "return _targetOffsets[h &+ 1] &- _targetOffsets[h]", mode="stmt", nth=1),
    Mutant("wcontainsshift", W, "p == edge.target &- _n", "p == edge.target"),
    Mutant("wcontainsin", W, "base.inHyperedgeIndices(ofIndex: edge.target)", "base.outHyperedgeIndices(ofIndex: edge.target)"),
    # The directed view's checked endpoint reads: the range guard dropped or off by one.
    Mutant("wcheckedsourceguard", W, "guard UInt(bitPattern: position) < UInt(bitPattern: _sourceCount &+ _targetCount) else { throw EdgeNotFound() }", "", mode="stmt", nth=0),
    Mutant("wcheckedtargetguard", W, "guard UInt(bitPattern: position) < UInt(bitPattern: _sourceCount &+ _targetCount) else { throw EdgeNotFound() }", "", mode="stmt", nth=1),
    Mutant("wcheckedsourcebound", W, "UInt(bitPattern: position) < UInt(bitPattern: _sourceCount &+ _targetCount)", "UInt(bitPattern: position) <= UInt(bitPattern: _sourceCount &+ _targetCount)", nth=0),
    Mutant("wcheckedtargetbound", W, "UInt(bitPattern: position) < UInt(bitPattern: _sourceCount &+ _targetCount)", "UInt(bitPattern: position) < UInt(bitPattern: _sourceCount)", nth=1),

    # Undirected algorithms.
    Mutant("neighborssort", A, "        found.sort()", "", mode="stmt", nth=0),
    Mutant("rank", A, "Swift.max(greatest, size(ofHyperedgeAt: position))", "size(ofHyperedgeAt: position)"),
    Mutant("uniform", A, "self.size(ofHyperedgeAt: position) != size", "self.size(ofHyperedgeAt: position) > size"),
    Mutant("degreehistogram", A, "degree(ofIndex: i)", "Swift.min(degree(ofIndex: i), 2)"),
    Mutant("sizehistogram", A, "size(ofHyperedgeAt: position)", "Swift.min(size(ofHyperedgeAt: position), 2)", nth=4),
    Mutant("dualvertices", A, "OrderedSet(uncheckedUniqueElements: _positions())", "OrderedSet(uncheckedUniqueElements: _positions().reversed())"),
    Mutant("cliquerepeat", A, "w > u && stamp[w] != u", "w > u"),
    Mutant("cliqueself", A, "w > u && stamp[w] != u", "w >= u && stamp[w] != u"),
    Mutant("cliquesort", A, "            found.sort()", "", mode="stmt", nth=0),
    Mutant("cliquevertices", A, "for i in 0 ..< n { vertices.append(vertex(atIndex: i)) }", "for i in 0 ..< n { vertices.append(vertex(atIndex: n &- 1 &- i)) }", mode="stmt"),
    Mutant("linethreshold", A, "counts[q] >= s", "counts[q] > s"),
    Mutant("linereset", A, "                counts[q] = 0", "", mode="stmt"),
    Mutant("linetouched", A, "if counts[q] == 0 { touched.append(q) }", "touched.append(q)", mode="stmt"),
    Mutant("linevertices", A, "ContiguousArray(_positions())", "ContiguousArray(_positions().reversed())"),
    Mutant("components", A, "sets.union(first, v)", "", mode="stmt"),
    Mutant("connectedcount", A, "return sets.setCount == 1", "return sets.setCount <= 1", mode="stmt"),
    Mutant("scomponents", A, "sets.union(p, q)", "", mode="stmt"),
    Mutant("scomponentspositions", A, "return sets.sets().map { $0.map { positions[$0] } }", "return sets.sets().map { $0.map { positions[positions.count &- 1 &- $0] } }", mode="stmt"),

    Mutant("neighborsself", A, "w != v", "true"),
    Mutant("neighborsrepeat", A, "w != previous", "true"),
    Mutant("neighborsposition", A, "hyperedges.index(hyperedges.startIndex, offsetBy: h)", "hyperedges.index(hyperedges.startIndex, offsetBy: 0)"),
    Mutant("dualrows", A, "for h in incidentHyperedgeIndices(ofIndex: i) { flat.append(h) }", "for h in incidentHyperedgeIndices(ofIndex: i) { flat.append(m &- 1 &- h) }", mode="stmt"),
    Mutant("cliquepositions", A, "memberIndices(ofHyperedgeAt: positions[h])", "memberIndices(ofHyperedgeAt: positions[0])"),
    Mutant("lineself", A, "q > p", "q >= p"),
    Mutant("lineordered", A, "            if ordered { touched.sort() }", "", mode="stmt"),
    Mutant("scomponentsone", A, "if first < 0 { first = h } else { sets.union(first, h) }", "if first < 0 { first = h }", mode="stmt"),
    Mutant("scomponentsfast", A, "s == 1", "false", nth=1),

    # Directed algorithms: the dual, classes, histograms and the clique expansion.
    Mutant("ddualsources", B, "_transposedPlane(vertexCount: n, hyperedgeCount: m, targets: false)", "_transposedPlane(vertexCount: n, hyperedgeCount: m, targets: true)"),
    Mutant("outhistogram", B, "_histogram(count: _indexBounds().n) { outDegree(ofIndex: $0) }", "_histogram(count: _indexBounds().n) { inDegree(ofIndex: $0) }"),
    Mutant("inhistogram", B, "_histogram(count: _indexBounds().n) { inDegree(ofIndex: $0) }", "_histogram(count: _indexBounds().n) { outDegree(ofIndex: $0) }", nth=1),
    Mutant("histogramgrow", B, "if d >= histogram.count { histogram.append(contentsOf: repeatElement(0, count: d - histogram.count + 1)) }", "if d >= histogram.count { histogram.append(contentsOf: repeatElement(0, count: d - histogram.count + 2)) }", mode="stmt"),
    Mutant("dcliqueself", B, "            stamp[u] = u", "", mode="stmt"),
    Mutant("dcliquerepeat", B, "stamp[w] != u", "true"),
    Mutant("dcliquesort", B, "            found.sort()", "", mode="stmt"),

    Mutant("ddualstars", B, "targets ? inHyperedgeIndices(ofIndex: i) : outHyperedgeIndices(ofIndex: i)", "targets ? outHyperedgeIndices(ofIndex: i) : inHyperedgeIndices(ofIndex: i)"),
    Mutant("bclass", B, "targetSize(ofHyperedgeAt: $0) == 1", "targetSize(ofHyperedgeAt: $0) >= 1", nth=0),
    Mutant("fclass", B, "sourceSize(ofHyperedgeAt: $0) == 1", "sourceSize(ofHyperedgeAt: $0) >= 1", nth=0),
    Mutant("bfclass", B, "targetSize(ofHyperedgeAt: $0) == 1 || sourceSize(ofHyperedgeAt: $0) == 1", "targetSize(ofHyperedgeAt: $0) == 1 && sourceSize(ofHyperedgeAt: $0) == 1"),
    Mutant("sourcehistogram", B, "sourceSize(ofHyperedgeAt: positions[$0])", "targetSize(ofHyperedgeAt: positions[$0])"),
    Mutant("targethistogram", B, "targetSize(ofHyperedgeAt: positions[$0])", "sourceSize(ofHyperedgeAt: positions[$0])", nth=1),
    Mutant("dcliquetargets", B, "targetIndices(ofHyperedgeAt: positions[h])", "sourceIndices(ofHyperedgeAt: positions[h])"),
    Mutant("dcliquestar", B, "outHyperedgeIndices(ofIndex: u)", "inHyperedgeIndices(ofIndex: u)", nth=0),

    # Directed algorithms: components.
    Mutant("strongheads", B, "for j in targetIndices(ofHyperedgeAt: position) { targets.append(j) }", "for j in sourceIndices(ofHyperedgeAt: position) { targets.append(j) }", mode="stmt"),
    Mutant("strongtest", B, "for i in 1 ..< n where component[i] != first { return false }", "", mode="stmt"),
    Mutant("strongempty", B, "        guard n > 0 else { return false }", "", mode="stmt"),
    Mutant("stronggroups", B, "groups[label[c]].append(vertex(atIndex: i))", "groups[0].append(vertex(atIndex: i))", mode="stmt"),

    Mutant("weak", B, "if first < 0 { first = v } else { sets.union(first, v) }", "if first < 0 { first = v }", mode="stmt"),
    Mutant("strongarcs", B, "for h in outHyperedgeIndices(ofIndex: i) { targets.append(n &+ h) }", "for h in outHyperedgeIndices(ofIndex: i) { targets.append(h) }", mode="stmt"),

    # B-Visit and F-Visit.
    Mutant("visitdecrement", B, "                remaining[p] &-= 1", "", mode="stmt"),
    Mutant("visitany", B, "guard remaining[p] == 0 else { continue }", "", mode="stmt"),
    Mutant("visitzero", B, "guard remaining[p] == 0 else { continue }", "guard remaining[p] <= 0 else { continue }", mode="stmt"),
    Mutant("visitreach", B, "backward ? sourceIndices(ofHyperedgeAt: position) : targetIndices(ofHyperedgeAt: position)", "backward ? targetIndices(ofHyperedgeAt: position) : sourceIndices(ofHyperedgeAt: position)"),
    Mutant("visitrepeat", B, "!reached[w]", "true"),
    Mutant("visitstop", B, "                    if w == stop { return reached }", "", mode="stmt"),
    Mutant("visitstartstop", B, "        if start == stop { return reached }", "", mode="stmt"),
    Mutant("visitstart", B, "        reached[start] = true", "", mode="stmt"),
    Mutant("isbconnected", B, "_visit(from: s, backward: false, stop: t)[t]", "_visit(from: s, backward: true, stop: t)[t]"),
    Mutant("isfconnected", B, "_visit(from: t, backward: true, stop: s)[s]", "_visit(from: s, backward: true, stop: t)[t]"),
    Mutant("fconnected", B, "_reachedVertices(_visit(from: vertexIndex(of: target), backward: true))", "_reachedVertices(_visit(from: vertexIndex(of: target), backward: false))"),

    Mutant("visitcounter", B, "remaining[h] = backward ? targetSize(ofHyperedgeAt: positions[h]) : sourceSize(ofHyperedgeAt: positions[h])", "remaining[h] = backward ? sourceSize(ofHyperedgeAt: positions[h]) : targetSize(ofHyperedgeAt: positions[h])", mode="stmt"),
    Mutant("visitstar", B, "backward ? inHyperedgeIndices(ofIndex: u) : outHyperedgeIndices(ofIndex: u)", "backward ? outHyperedgeIndices(ofIndex: u) : inHyperedgeIndices(ofIndex: u)"),

    # Attached maps and generations: every map follows its element, the checked reads throw
    # exactly outside the elements, and every structural mutation starts a generation.
    Mutant("ugenbuilt", U, "        _generation.stamp()", "", mode="stmt", nth=0),
    Mutant("umapvertex", U, "            if !_vertexMaps.isEmpty { _vertexMaps.appendDefaults(count: 1) }", "", mode="stmt"),
    Mutant("ugenvertex", U, "            _generation.advance(owning: &_plane.memberOffsets)", "", mode="stmt"),
    Mutant("ugenvertexwriting", U, "_generation.advance(owning: &_plane.memberOffsets)", "_generation.advance(writing: _plane.memberOffsets)", mode="stmt", nth=0),
    Mutant("umapmembers", U, "        if !_vertexMaps.isEmpty, _vertices.count != vertexCount { _vertexMaps.appendDefaults(count: _vertices.count &- vertexCount) }", "", mode="stmt"),
    Mutant("umapedge", U, "        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaults(count: 1) }", "", mode="stmt", nth=0),
    Mutant("ugenedge", U, "        _generation.advance(owning: &_plane.memberOffsets)", "", mode="stmt", nth=0),
    Mutant("umapcheckededge", U, "        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaults(count: 1) }", "", mode="stmt", nth=1),
    Mutant("ugencheckededge", U, "        _generation.advance(owning: &_plane.memberOffsets)", "", mode="stmt", nth=1),
    Mutant("umapremoveallvertices", U, "        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("umapremovealledges", U, "        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("ugenremoveall", U, "        _generation.advance(owning: &_plane.memberOffsets)", "", mode="stmt", nth=2),
    Mutant("ugeneration", U, "_generation.generation", "GraphGeneration.untracked"),
    Mutant("umapedgecount", U, "_plane.hyperedgeCount", "0", nth=6),
    Mutant("umapvertexcount", U, "_vertices.count", "0", nth=5),
    Mutant("umapsetedge", U, "            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)", "            _edgeMaps.setValue(newValue, at: 0, in: k, layout: .dense)", mode="stmt"),
    Mutant("umapsetvertexindex", U, "            _vertexMaps.setValue(newValue, at: index, in: k, layout: .dense)", "            _vertexMaps.setValue(newValue, at: 0, in: k, layout: .dense)", mode="stmt"),
    Mutant("umapvertexbyvertex", U, "            return _vertexMaps.value(Value.self, at: _index(of: vertex), in: k, layout: .dense)", "            return _vertexMaps.value(Value.self, at: 0, in: k, layout: .dense)", mode="stmt"),
    Mutant("umapcheckededgelow", U, "UInt(bitPattern: position) < UInt(bitPattern: _plane.hyperedgeCount)", "position < _plane.hyperedgeCount"),
    Mutant("umapcheckededgehigh", U, "UInt(bitPattern: position) < UInt(bitPattern: _plane.hyperedgeCount)", "position >= 0"),
    Mutant("umapcheckedindexlow", U, "UInt(bitPattern: index) < UInt(bitPattern: _vertices.count)", "index < _vertices.count"),
    Mutant("umapcheckedindexhigh", U, "UInt(bitPattern: index) < UInt(bitPattern: _vertices.count)", "index >= 0"),
    Mutant("umapcheckedvertex", U, "_vertices.firstIndex(of: vertex)", "Optional(_vertices.firstIndex(of: vertex) ?? 0)", nth=4),
    Mutant("dgenbuilt", D, "        _generation.stamp()", "", mode="stmt", nth=0),
    Mutant("dgenlisted", D, "        _generation.stamp()", "", mode="stmt", nth=1),
    Mutant("dmapvertex", D, "            if !_vertexMaps.isEmpty { _vertexMaps.appendDefaults(count: 1) }", "", mode="stmt"),
    Mutant("dgenvertex", D, "            _generation.advance(owning: &_sources.memberOffsets)", "", mode="stmt"),
    Mutant("dgenvertexwriting", D, "_generation.advance(owning: &_sources.memberOffsets)", "_generation.advance(writing: _sources.memberOffsets)", mode="stmt", nth=0),
    Mutant("dmapmembers", D, "        if !_vertexMaps.isEmpty, _vertices.count != vertexCount { _vertexMaps.appendDefaults(count: _vertices.count &- vertexCount) }", "", mode="stmt"),
    Mutant("dmapedge", D, "        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaults(count: 1) }", "", mode="stmt", nth=0),
    Mutant("dgenedge", D, "        _generation.advance(owning: &_sources.memberOffsets)", "", mode="stmt", nth=0),
    Mutant("dmapcheckededge", D, "        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaults(count: 1) }", "", mode="stmt", nth=1),
    Mutant("dgencheckededge", D, "        _generation.advance(owning: &_sources.memberOffsets)", "", mode="stmt", nth=1),
    Mutant("dmapremoveallvertices", D, "        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("dmapremovealledges", D, "        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("dgenremoveall", D, "        _generation.advance(owning: &_sources.memberOffsets)", "", mode="stmt", nth=2),
    Mutant("dreversedvertexmaps", D, "        _vertexMaps = hypergraph._vertexMaps", "        _vertexMaps = _AttachedMaps()", mode="stmt"),
    Mutant("dreversededgemaps", D, "        _edgeMaps = hypergraph._edgeMaps", "        _edgeMaps = _AttachedMaps()", mode="stmt"),
    Mutant("dreversedgeneration", D, "        _generation = _GenerationStamp()", "        _generation = hypergraph._generation", mode="stmt", nth=2),
    Mutant("dgeneration", D, "_generation.generation", "GraphGeneration.untracked"),
    Mutant("dmapedgecount", D, "_sources.hyperedgeCount", "0", nth=6),
    Mutant("dmapvertexcount", D, "_vertices.count", "0", nth=5),
    Mutant("dmapsetedge", D, "            _edgeMaps.setValue(newValue, at: position, in: k, layout: .dense)", "            _edgeMaps.setValue(newValue, at: 0, in: k, layout: .dense)", mode="stmt"),
    Mutant("dmapsetvertexindex", D, "            _vertexMaps.setValue(newValue, at: index, in: k, layout: .dense)", "            _vertexMaps.setValue(newValue, at: 0, in: k, layout: .dense)", mode="stmt"),
    Mutant("dmapvertexbyvertex", D, "            _vertexMaps.setValue(newValue, at: _index(of: vertex), in: k, layout: .dense)", "            _vertexMaps.setValue(newValue, at: 0, in: k, layout: .dense)", mode="stmt"),
    Mutant("dmapcheckededgelow", D, "UInt(bitPattern: position) < UInt(bitPattern: _sources.hyperedgeCount)", "position < _sources.hyperedgeCount"),
    Mutant("dmapcheckededgehigh", D, "UInt(bitPattern: position) < UInt(bitPattern: _sources.hyperedgeCount)", "position >= 0"),
    Mutant("dmapcheckedindexlow", D, "UInt(bitPattern: index) < UInt(bitPattern: _vertices.count)", "index < _vertices.count"),
    Mutant("dmapcheckedindexhigh", D, "UInt(bitPattern: index) < UInt(bitPattern: _vertices.count)", "index >= 0"),
    Mutant("dmapcheckedvertex", D, "_vertices.firstIndex(of: vertex)", "Optional(_vertices.firstIndex(of: vertex) ?? 0)", nth=7),

    # GraphProtocols: the Hypergraph defaults.
    Mutant("hdegree", H, "for _ in incidentHyperedges(of: vertex) { count &+= 1 }", "for _ in incidentHyperedges(of: vertex) { count &+= 2 }", mode="stmt", module="GraphProtocols"),
    Mutant("hcontainssize", H, "hyperedge.count == wanted.count", "true", module="GraphProtocols"),

    Mutant("hincidentindices", H, "incidentHyperedges(ofIndex: index).lazy.map { hyperedgeIndex(of: $0) }", "incidentHyperedges(ofIndex: index).lazy.map { hyperedgeIndex(of: $0) &+ 1 }", module="GraphProtocols"),
    Mutant("hforeach", H, "for i in memberIndices(ofHyperedgeAt: position) { body(i) }", "for i in memberIndices(ofHyperedgeAt: position).dropFirst() { body(i) }", mode="stmt", module="GraphProtocols"),
    Mutant("hmemberindex", H, "if remaining == 0 { return member }", "if remaining == 1 { return member }", mode="stmt", module="GraphProtocols"),
    Mutant("hmemberrank", H, "if member == index { return rank }", "if member != index { return rank }", mode="stmt", module="GraphProtocols"),
    Mutant("hrowsmembers", H, "for i in memberIndices(ofHyperedgeAt: position) { members.append(i) }", "for i in memberIndices(ofHyperedgeAt: position).dropFirst() { members.append(i) }", mode="stmt", module="GraphProtocols"),
    Mutant("transposecount", H, "rows[3 &* i &+ 1] &+= 1", "", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("transposestart", H, "start &+= rows[3 &* i &+ 1]", "", mode="stmt", module="GraphProtocols"),
    Mutant("transposereset", H, "rows[3 &* i &+ 1] = 0", "", mode="stmt", module="GraphProtocols"),
    Mutant("transposeincidence", H, "incidences[slot] = q", "incidences[slot] = 0", mode="stmt", module="GraphProtocols"),
    Mutant("transposehyperedge", H, "rowHyperedges[slot] = h", "rowHyperedges[slot] = q", mode="stmt", module="GraphProtocols"),
    Mutant("transposebody", H, "body(offsets, members, incidences, rows, rowHyperedges, rows)", "body(offsets, members, rowHyperedges, rows, incidences, rows)", module="GraphProtocols"),

    # GraphProtocols: the DirectedHypergraph defaults.
    Mutant("gindegree", G, "for _ in inHyperedges(of: vertex) { count &+= 1 }", "for _ in outHyperedges(of: vertex) { count &+= 1 }", mode="stmt", module="GraphProtocols"),
    Mutant("gdegree", G, "        outDegree(of: vertex) &+ inDegree(of: vertex)", "        outDegree(of: vertex)", mode="stmt", module="GraphProtocols"),
    Mutant("gincidencesside", G, "targets ? targetIndices(ofHyperedgeAt: position) : sourceIndices(ofHyperedgeAt: position)", "sourceIndices(ofHyperedgeAt: position)", nth=0, module="GraphProtocols"),
    Mutant("gincidenceside", G, "targets ? targetIndices(ofHyperedgeAt: position) : sourceIndices(ofHyperedgeAt: position)", "sourceIndices(ofHyperedgeAt: position)", nth=1, module="GraphProtocols"),

    Mutant("gsourcesize", G, "sources(ofHyperedgeAt: position).count", "targets(ofHyperedgeAt: position).count", nth=1, module="GraphProtocols"),
    Mutant("goutindices", G, "outHyperedges(ofIndex: index).lazy.map { hyperedgeIndex(of: $0) }", "inHyperedges(ofIndex: index).lazy.map { hyperedgeIndex(of: $0) }", module="GraphProtocols"),
    Mutant("gforeachtargets", G, "        for i in targetIndices(ofHyperedgeAt: position) { body(i) }", "", mode="stmt", module="GraphProtocols"),
    Mutant("gmemberrank", G, "if member == index { return rank }", "if member != index { return rank }", mode="stmt", module="GraphProtocols"),
    Mutant("gcontainstargets", G, "self.targets(ofHyperedgeAt: position).allSatisfy({ wantedTargets.contains($0) })", "true", module="GraphProtocols"),
    Mutant("gcontainscount", G, "targetSize(ofHyperedgeAt: position) == wantedTargets.count", "true", module="GraphProtocols"),

    # AdjacencyListModule: the sorted-slot builders.
    Mutant("slotsdirected", S, "for (slot, vertex) in vertices.enumerated() { _slots[vertex] = slot }", "for (slot, vertex) in vertices.enumerated() { _slots[vertex] = slot == 0 ? 0 : slot &- 1 }", mode="stmt", nth=0, module="AdjacencyListModule"),
    Mutant("slotsundirected", S, "for (slot, vertex) in vertices.enumerated() { _slots[vertex] = slot }", "for (slot, vertex) in vertices.enumerated() { _slots[vertex] = slot == 0 ? 0 : slot &- 1 }", mode="stmt", nth=1, module="AdjacencyListModule"),
    Mutant("pairsdirected", S, "        _deferredEdges = rows.records.isEmpty ? nil : _DeferredSlotPairTable(records: rows.records)", "        _deferredEdges = nil", mode="stmt", nth=1, module="AdjacencyListModule"),
    Mutant("pairsundirected", S, "        _positions._insertDistinct(count: records.count) { (_SlotPair(records[$0].u, records[$0].v), $0) }", "", mode="stmt", nth=1, module="AdjacencyListModule"),
    Mutant("indirected", S, "        _in = rows.in", "        _in = rows.out", mode="stmt", nth=1, module="AdjacencyListModule"),
]
