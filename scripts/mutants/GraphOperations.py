# Planted bugs for GraphOperations; run with `just mutate GraphOperations`. See scripts/mutate.py.
#
# Scope: the `checked:` lookups on the views: the directed complement's checked endpoint
# reads, and the GraphProtocols defaults (`contains(_:)`, then the trapping read) that the views
# reach; and a subgraph view's attached-map reads, each membership check dropped. The views' own
# rows, edges and indices have no mutants. Then the materialized operations added beside them: the
# sorted rows and their merge, the binary operations' numbering, the relabelings, the power, the
# ego graph's search, the contractions and the closure and reduction over the condensation.
#
# Known equivalent mutants (removed): dropping `relabeled(_:ordering:)`'s directed self-loop
# precondition. The loop then reaches the construction hook, whose debug-build check of its input
# (`_isSortedSimple`) traps on it, so in the debug build the suites run the trap is the same.

TESTS = ["GraphOperationsTests", "GraphProtocolsTests"]

C = "ComplementView+DirectedGraph.swift"
SD = "SubgraphView+DirectedGraph.swift"
SU = "SubgraphView+Graph.swift"
L = "CheckedLookups.swift"
SR = "SortedRows.swift"
SO = "SetOperations.swift"
RL = "Relabeling.swift"
PW = "Power.swift"
EG = "EgoGraph.swift"
CT = "Contraction.swift"
TC = "TransitiveClosure.swift"

MUTANTS = [
    # The directed complement: a cell is an edge when both ends are in range, distinct, and unjoined.
    Mutant("celledgesourcerange", C, "UInt(bitPattern: position.source) < n", "true"),
    Mutant("celledgetargetrange", C, "UInt(bitPattern: position.target) < n", "true"),
    Mutant("celledgediagonal", C, "position.source != position.target", "true"),
    Mutant("celledgejoined", C, "return !base.contains(edge: edge)", "return true", mode="stmt"),
    Mutant("checkedsourcenoguard", C, "guard _isEdge(position) else { throw EdgeNotFound() }", "", mode="stmt", nth=0),
    Mutant("checkedtargetnoguard", C, "guard _isEdge(position) else { throw EdgeNotFound() }", "", mode="stmt", nth=1),
    Mutant("checkedtargetreadssource", C, "return target(ofEdgeAt: position)", "return source(ofEdgeAt: position)", mode="stmt"),
    # The GraphProtocols defaults: each guard dropped (the view then traps or answers for a
    # non-vertex), and each read swapped for its neighbour.
    Mutant("defsuccessors", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("defoutedges", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=1, module="GraphProtocols"),
    Mutant("defoutdegree", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=2, module="GraphProtocols"),
    Mutant("defvertexindex", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=3, module="GraphProtocols"),
    Mutant("defpredecessors", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=4, module="GraphProtocols"),
    Mutant("definedges", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=5, module="GraphProtocols"),
    Mutant("defindegree", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=6, module="GraphProtocols"),
    Mutant("defdegree", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=7, module="GraphProtocols"),
    Mutant("defneighbors", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=8, module="GraphProtocols"),
    Mutant("defincidentedges", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=9, module="GraphProtocols"),
    Mutant("defudegree", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=10, module="GraphProtocols"),
    Mutant("defuvertexindex", L, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=11, module="GraphProtocols"),
    Mutant("defoutdegreeread", L, "return outDegree(of: vertex)", "return outDegree(of: vertex) &+ 1", mode="stmt", module="GraphProtocols"),
    Mutant("definedegreeread", L, "return inDegree(of: vertex)", "return outDegree(of: vertex)", mode="stmt", module="GraphProtocols"),
    Mutant("defdegreeread", L, "return degree(of: vertex)", "return inDegree(of: vertex)", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("defudegreeread", L, "return degree(of: vertex)", "return degree(of: vertex) &+ 1", mode="stmt", nth=1, module="GraphProtocols"),
    # A subgraph view's map reads: each check that the vertex or edge is the view's dropped (the
    # read then answers with the base's value), directed and undirected.
    Mutant("dmapvertex", SD, "if !_new.isEmpty { _ = _viewIndex(base.vertexIndex(of: vertex)) }", "", mode="stmt"),
    Mutant("dmapcheckedvertex", SD, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("dmapedge", SD, "precondition(_keeps(position), \"\\(position) is not an edge of the subgraph\")", "", mode="stmt"),
    Mutant("dmapcheckededge", SD, "guard _keeps(position) else { throw EdgeNotFound() }", "", mode="stmt"),
    Mutant("umapvertex", SU, "if !_new.isEmpty { _ = _viewIndex(base.vertexIndex(of: vertex)) }", "", mode="stmt"),
    Mutant("umapcheckedvertex", SU, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("umapedge", SU, "precondition(_keepsEdge(position), \"\\(position) is not an edge of the subgraph\")", "", mode="stmt"),
    Mutant("umapcheckededge", SU, "guard _keepsEdge(position) else { throw EdgeNotFound() }", "", mode="stmt"),
    # Sorted rows: the per-row sort and deduplication, and the merge's three kinds of entry.
    Mutant("rowsnosort", SR, "if end &- start > 1 { flat[start ..< end].sort() }", "", mode="stmt"),
    Mutant("rowsnodedupe", SR, "w != previous", "true"),
    Mutant("mergefirsttail", SR, "if first { while i < iEnd { out.append(a.targets[i]); i &+= 1 } }", "", mode="stmt"),
    Mutant("mergesecondtail", SR, "if second { while j < jEnd { out.append(b.targets[j]); j &+= 1 } }", "", mode="stmt"),
    Mutant("mergeboth", SR, "if both { out.append(x) }", "", mode="stmt"),
    # The binary operations: h's own vertices, h's shared vertices, undirected rows.
    Mutant("unionhvertices", SO, "mode == .union", "false"),
    Mutant("hmapshared", SO, "hMap[j] = inG[j]", "hMap[j] = -1", mode="stmt"),
    Mutant("undirectedloops", SO, "v <= w", "v < w"),
    Mutant("undirectedmin", SO, "sources.append(Swift.min(a, b))", "sources.append(a)", mode="stmt"),
    Mutant("undirectedmax", SO, "targets.append(Swift.max(a, b))", "targets.append(b)", mode="stmt"),
    # The relabelings.
    Mutant("relabelnomerge", RL, "seen[w]", "nil as Int?", nth=0),
    Mutant("relabelorientation", RL, "us.append(keys[ends.u])", "us.append(keys[ends.v])", mode="stmt"),
    Mutant("ranktwice", RL, "precondition(rank[i] < 0, \"\\(vertex) is listed twice in the ordering\")", "", mode="stmt"),
    Mutant("rankcover", RL, "precondition(old.count == n, \"The ordering does not list every vertex\")", "", mode="stmt"),
    Mutant("uorderingloop", RL, "precondition(w != i, \"The graph has a self-loop, which the construction targets do not take\")", "", mode="stmt", nth=1),
    Mutant("orderingrank", RL, "row.append(rank[w])", "row.append(w)", mode="stmt"),
    Mutant("uorderingupper", RL, "k > r", "true"),
    # The power.
    Mutant("powerdepth", PW, "depth < k", "depth <= k"),
    Mutant("powersource", PW, "row.append(contentsOf: queue[1 ..< count])", "row.append(contentsOf: queue[0 ..< count])", mode="stmt"),
    Mutant("powerk", PW, "precondition(k >= 1, \"The power must be at least 1\")", "", mode="stmt", nth=0),
    Mutant("upowerk", PW, "precondition(k >= 1, \"The power must be at least 1\")", "", mode="stmt", nth=1),
    # The ego graph.
    Mutant("egoradius", EG, "depth < radius", "depth <= radius"),
    Mutant("egonegative", EG, "precondition(radius >= 0, \"The radius must not be negative\")", "", mode="stmt"),
    Mutant("egobackward", EG, "new[w] = 0", "", mode="stmt", nth=1),
    Mutant("egokeepall", EG, "if tail == n { return ([], [], n) }", "", mode="stmt"),
    # The contractions.
    Mutant("contractshift", CT, "i < b ? i : (i == b ? a : i &- 1)", "i < b ? i : (i == b ? a : i)"),
    Mutant("contractold", CT, "r >= merged", "r > merged", nth=0),
    Mutant("ucontractold", CT, "r >= merged", "r > merged", nth=1),
    Mutant("contractinto", CT, "r == into", "false", nth=0),
    Mutant("ucontractinto", CT, "r == into", "false", nth=1),
    Mutant("contractloops", CT, "map[w] != r", "true", nth=0),
    Mutant("contractedge", CT, "graph.targetIndex(ofEdgeAt: position)", "graph.sourceIndex(ofEdgeAt: position)"),
    Mutant("contractsame", CT, "if a == b { return _contracted(graph, count: n, map: Array(0 ..< n), merged: -1, into: -1) }", "", mode="stmt", nth=0),
    # The closure and the reduction.
    Mutant("closureown", TC, "reach.append(contentsOf: components.members[components.offsets[c] ..< components.offsets[c &+ 1]])", "", mode="stmt"),
    Mutant("closurenosort", TC, "reach[start...].sort()", "", mode="stmt"),
    Mutant("descendantsbit", TC, "rows[row &+ d &>> 6] |= UInt64(1) &<< UInt64(d & 63)", "", mode="stmt"),
    Mutant("descendantsprefix", TC, "w <= d &>> 6", "w < d &>> 6"),
    Mutant("reductionopen", TC, "start ..< end", "start ..< end &- 1"),
    Mutant("reductionfar", TC, "for w in 0 ... d &>> 6 { far[w] |= rows[other &+ w] }", "", mode="stmt"),
    Mutant("reductionfarclear", TC, "for w in 0 ..< words { far[w] = 0 }", "", mode="stmt"),
    Mutant("reductionlast", TC, "components.members[components.offsets[d]]", "components.members[components.offsets[d &+ 1] &- 1]"),
]
