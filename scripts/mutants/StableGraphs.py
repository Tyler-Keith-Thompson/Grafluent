# Planted bugs for StableGraphs and the numbered mode it wires into GraphProtocols, Traversal and
# Connectivity; run with `just mutate StableGraphs`. See scripts/mutate.py. The shared files'
# mutants (module=...) run StableGraphsTests first, then those modules' own suites.
#
# Known equivalent mutants (they survive by design):
#   selfloopin        also killing a self-loop's entry in the vertex's own in-row: that row is
#                     cleared right after, and the second loop skips dead entries.
#   trailingdrop      no dropping of trailing dead entries: they stay dead and count as dead, so
#                     degrees and every walk agree; compaction picks them up. Memory only.
#   nevercompact      never compacting: rows only grow, dead entries are skipped. Memory and time
#   compactthreshold  only (a row may exceed twice its degree), not observable through the API.
#   idexisting        `existingIdentifier` without the membership test: its only caller traps on
#                     a non-vertex either way.
#   iddense           a numbered graph reported not dense: the searches then hand out the same
#                     numbers lazily (through `_number`), in the same order; presizing only.

TESTS = ["StableGraphsTests", "TraversalTests", "ConnectivityTests"]

S = "StableDirectedGraph.swift"
C = "StableDirectedGraph+Conformances.swift"
V = "StableDirectedGraph+Views.swift"

MUTANTS = [
    # Positions: never reused, the ends, and the resets.
    Mutant("reuseedge", S, "_records.count", "_edgeCount", nth=2),
    Mutant("reuseslot", S, "_vertices.count", "_vertexCount", nth=1),
    Mutant("firstvertex", S, "            _firstVertex = first", "", mode="stmt"),
    Mutant("firstvertexscan", S, "_vertices[first] == nil", "false"),
    Mutant("firstedge", S, "            _firstEdge = first", "", mode="stmt"),
    Mutant("firstedgescan", S, "_records[first].source < 0", "false"),
    Mutant("resetfirstvertex", S, "        _firstVertex = 0", "", mode="stmt", nth=1),
    Mutant("resetfirstedge", S, "        _firstEdge = 0", "", mode="stmt", nth=1),
    Mutant("edgesresetfirst", S, "        _firstEdge = 0", "", mode="stmt", nth=2),
    Mutant("edgesresetrecords", S, "        _records.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt", nth=1),
    Mutant("edgesrevive", S, "if _outDead[slot] > 0 { _outDead[slot] = 0 }", "_outDead[slot] = 0", mode="stmt"),
    Mutant("edgesindead", S, "            _inDead[slot] = 0", "", mode="stmt"),

    # Vertex removal.
    Mutant("holemark", S, "        _outDead[slot] = -1", "        _outDead[slot] = 0", mode="stmt"),
    Mutant("holevertex", S, "        _vertices[slot] = nil", "", mode="stmt"),
    Mutant("holecount", S, "        _vertexCount &-= 1", "", mode="stmt"),
    Mutant("removein", S, "Self._kill(_records[position].in, inRow: target, &_in, &_inEdges, &_inDead, &_records, outward: false)", "", mode="stmt"),
    Mutant("removeout", S, "Self._kill(_records[position].out, inRow: source, &_out, &_outEdges, &_outDead, &_records, outward: true)", "", mode="stmt"),
    Mutant("selfloopin", S, "target != slot", "true"),
    Mutant("selfloopout", S, "source < 0 || source == slot", "source < 0"),

    # Lazy deletion: dead marks, trailing drops, compaction, offsets in the records.
    Mutant("swapoffsets", S, "_EdgeRecord(source: source, target: target, out: out, in: into)", "_EdgeRecord(source: source, target: target, out: into, in: out)"),
    Mutant("unlinkin", S, "        Self._kill(r.in, inRow: r.target, &_in, &_inEdges, &_inDead, &_records, outward: false)", "", mode="stmt"),
    Mutant("trailingdrop", S, "ends[endStart &+ count &- 1] < 0", "false"),
    Mutant("trailingdead", S, "                deadCount &-= 1", "", mode="stmt"),
    Mutant("nevercompact", S, "deadCount &* 2 > count", "false"),
    Mutant("compactthreshold", S, "deadCount &* 2 > count", "deadCount &* 2 >= count &* 2 &+ 1"),
    Mutant("compactin", S, "if outward { records[position].out = kept } else { records[position].in = kept }", "if outward { records[position].out = kept }", mode="stmt"),
    Mutant("compactout", S, "if outward { records[position].out = kept } else { records[position].in = kept }", "if !outward { records[position].in = kept }", mode="stmt"),
    Mutant("compactcount", S, "                        count = kept", "", mode="stmt"),
    Mutant("compactdead", S, "            deadCount = 0", "", mode="stmt"),
    Mutant("deadstore", S, "        dead[row] = deadCount", "", mode="stmt"),

    # Newest-copy removal.
    Mutant("oldest", S, "_newestEdge(from: source, to: target)", "(Array(edges(from: edge.source, to: edge.target)).first ?? -1)", nth=1),
    Mutant("lastoffset", S, "block.count - 1", "block.count - 2"),
    Mutant("lastvalue", S, "storage[block.start + k] != value", "storage[block.start + k] < 0"),

    # Dense bounds nil exactly while holes exist; positions.
    Mutant("vertexbound", C, "_vertexCount == _vertices.count ? _vertexCount : nil", "_vertices.count"),
    Mutant("vertexboundnil", C, "_vertexCount == _vertices.count ? _vertexCount : nil", "nil"),
    Mutant("edgebound", C, "_edgeCount == _records.count ? _edgeCount : nil", "_records.count"),
    Mutant("edgeboundnil", C, "_edgeCount == _records.count ? _edgeCount : nil", "nil"),
    Mutant("containsvertex", C, "_outDead[position] >= 0", "true"),
    Mutant("containsedge", C, "_records[position].source >= 0", "true"),

    # _numberedRows.
    Mutant("numberholes", C, "outDead[slot] >= 0", "true"),
    Mutant("numberbyslot", C, "                    numbers[slot] = n", "                    numbers[slot] = slot", mode="stmt"),
    Mutant("numberedslots", C, "                                    neighbors[k] = numbers[end]", "                                    neighbors[k] = end", mode="stmt"),
    Mutant("numberedoffsets", C, "                                    edges[k] = positionStorage[positionStart &+ j]", "                                    edges[k] = j", mode="stmt"),
    Mutant("numberedinward", C, "outward ? _out : _in", "_out"),
    Mutant("numberedpositions", C, "outward ? _outEdges : _inEdges", "_outEdges"),

    # Equality.
    Mutant("eqnosort", C, "                left.sort()", "", mode="stmt"),
    Mutant("eqslots", C, "left.append(map[target])", "left.append(target)"),

    # Codable.
    Mutant("encodeslot", C, "ends.append(offsets[r.source])", "ends.append(r.source)"),
    Mutant("vertexend", C, "try container.encode(_vertices.count, forKey: .vertexEnd)", "try container.encode(_vertexCount, forKey: .vertexEnd)", mode="stmt"),
    Mutant("edgeend", C, "try container.encode(_records.count, forKey: .edgeEnd)", "try container.encode(_edgeCount, forKey: .edgeEnd)", mode="stmt"),
    Mutant("repeatedvertex", C, "slots.updateValue(positions[k], forKey: v) == nil", "(slots.updateValue(positions[k], forKey: v) == nil || true)"),
    Mutant("oddedges", C, "ends.count.isMultiple(of: 2)", "true"),
    Mutant("endpointrange", C, "$0 < listed.count", "true"),
    Mutant("decodeincreasing", C, "p > previous", "p >= previous"),
    Mutant("decodelive", C, "            _outDead[positions[k]] = 0", "", mode="stmt"),
    Mutant("decodefirstvertex", C, "positions.first ?? vertexEnd", "0"),
    Mutant("decodefirstedge", C, "edgePositions.first ?? edgeEnd", "0"),

    # Views.
    Mutant("vafter", V, "_vertices[j] == nil", "false", nth=0),
    Mutant("vbefore", V, "_vertices[j] == nil", "false", nth=1),
    Mutant("eafter", V, "_records[j].source < 0", "false", nth=0),
    Mutant("ebefore", V, "_records[j].source < 0", "false", nth=1),
    Mutant("vindicescontains", V, "_base._vertices[position] != nil", "true"),
    Mutant("eindicescontains", V, "_base._records[position].source >= 0", "true"),
    Mutant("rowstart", V, "_end(k) < 0", "false", nth=0),
    Mutant("rowafter", V, "_end(k) < 0", "false", nth=1),
    Mutant("rowbefore", V, "_end(k) < 0", "false", nth=2),
    Mutant("rowpositions", V, "_ends[_ends.startIndex &+ k] >= 0", "true"),
    Mutant("rowends", V, "slot >= 0", "true"),
    Mutant("connecting", V, "_ends[_ends.startIndex &+ k] == _other", "_ends[_ends.startIndex &+ k] >= 0"),

    # GraphProtocols: the numbered mode of _VertexIdentifiers.
    Mutant("idnumber", "VertexIdentifiers.swift", "rows.numbers[sparse.vertexPosition(of: vertex)]", "sparse.vertexPosition(of: vertex)", module="GraphProtocols"),
    Mutant("idexisting", "VertexIdentifiers.swift", "graph.contains(vertex) ? _number(of: vertex, rows) : nil", "_number(of: vertex, rows)", module="GraphProtocols"),
    Mutant("idsuccessors", "VertexIdentifiers.swift", "rows.offsets[id + 1]", "rows.offsets[id + 1] - 1", nth=0, module="GraphProtocols"),
    Mutant("idpredecessors", "VertexIdentifiers.swift", "rows.offsets[id + 1]", "rows.offsets[id + 1] - 1", nth=1, module="GraphProtocols"),
    Mutant("idpredoutward", "VertexIdentifiers.swift", "false", "true", module="GraphProtocols"),
    Mutant("iddense", "VertexIdentifiers.swift", "isIndexed || rows != nil", "isIndexed", module="GraphProtocols"),

    # Traversal and Connectivity on numbered rows.
    Mutant("bfsnumbered", "BreadthFirstSearch.swift", "rows.offsets[u] ..< rows.offsets[u + 1]", "rows.offsets[u] ..< rows.offsets[u]", module="Traversal"),
    Mutant("dfsnumbered", "DepthFirstSearch.swift", "rows.offsets[id] ..< rows.offsets[id + 1]", "rows.offsets[id] ..< rows.offsets[id]", module="Traversal"),
    Mutant("reachbackward", "Reachability.swift", "forward ? rows : ids.numberedPredecessorRows()", "rows", module="Traversal"),
    Mutant("densenumber", "DenseVertices.swift", "rows.numbers[sparse.vertexPosition(of: vertex)]", "sparse.vertexPosition(of: vertex)", module="Connectivity"),
    Mutant("sccnumbered", "StronglyConnectedComponents.swift", "for k in rows.offsets[u] ..< rows.offsets[u + 1] { visit(rows.neighbors[k]) }", "", mode="stmt", module="Connectivity"),
    Mutant("wccnumbered", "WeaklyConnectedComponents.swift", "for k in offsets[u] ..< offsets[u + 1] { union(u, targets[k]) }", "", mode="stmt", nth=1, module="Connectivity"),
]
