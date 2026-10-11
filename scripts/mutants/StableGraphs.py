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
#   vertexlivecount   vertex pages never freed: memory only.
#   changesame        changing an edge to its own endpoint without the early exit: the entry is
#                     killed and revived in place, the same row; time only.
#   iddense           a numbered graph reported not dense: the searches then hand out the same
#                     numbers lazily (through `_number`), in the same order; presizing only.

TESTS = ["StableGraphsTests", "TraversalTests", "ConnectivityTests"]

S = "StableDirectedGraph.swift"
C = "StableDirectedGraph+Conformances.swift"
V = "StableDirectedGraph+Views.swift"
P = "Pages.swift"
M = "PositionMaps.swift"

MUTANTS = [
    # Positions: never reused, the ends, and the resets.
    Mutant("reuseedge", S, "        _edgeEnd = position &+ 1", "        _edgeEnd = _edgeCount &+ 1", mode="stmt"),
    Mutant("reuseslot", S, "        _vertexEnd = slot &+ 1", "        _vertexEnd = _vertexCount &+ 1", mode="stmt"),
    Mutant("firstvertex", S, "if slot == _firstVertex { _firstVertex = _nextLiveVertex(after: slot, _vertexPages, base: _vertexBase, end: _vertexEnd) }", "", mode="stmt"),
    Mutant("firstedge", S, "if position == _firstEdge { _firstEdge = _nextLiveEdge(after: position, _edgePages, base: _edgeBase, end: _edgeEnd) }", "", mode="stmt", nth=1),
    Mutant("firstedgeunlink", S, "if position == _firstEdge { _firstEdge = _nextLiveEdge(after: position, _edgePages, base: _edgeBase, end: _edgeEnd) }", "", mode="stmt", nth=0),
    Mutant("firstedgekill", S, "if lowest == _firstEdge { _firstEdge = _nextLiveEdge(after: lowest, _edgePages, base: _edgeBase, end: _edgeEnd) }", "", mode="stmt"),
    Mutant("nextedgescan", P, "if pages[k].records[l].source >= 0 { return p }", "return p", mode="stmt", nth=0),
    Mutant("nextvertexscan", P, "if pages[k].vertices[l] != nil { return p }", "return p", mode="stmt", nth=0),
    Mutant("resetfirstvertex", S, "        _firstVertex = 0", "", mode="stmt", nth=1),
    Mutant("resetfirstedge", S, "        _firstEdge = 0", "", mode="stmt", nth=1),
    Mutant("edgesresetfirst", S, "        _firstEdge = 0", "", mode="stmt", nth=2),
    Mutant("edgesresetend", S, "        _edgeEnd = 0", "", mode="stmt", nth=2),
    Mutant("edgesresetpages", S, "        _edgePages.removeAll(keepingCapacity: keepingCapacity)", "", mode="stmt", nth=1),
    Mutant("edgesrevive", P, "if rows[row].dead > 0 { rows[row].dead = 0 }", "rows[row].dead = 0", mode="stmt"),
    Mutant("edgesresetin", S, "            _inPages[k].removeAllEntries(keepingCapacity: keepingCapacity)", "", mode="stmt"),

    # Vertex removal.
    Mutant("holemark", S, "        _outPages[k].clearRow(l, dead: -1)", "        _outPages[k].clearRow(l, dead: 0)", mode="stmt"),
    Mutant("holevertex", S, "        _vertexPages[k].vertices[l] = nil", "", mode="stmt"),
    Mutant("holecount", S, "        _vertexCount &-= 1", "", mode="stmt"),
    Mutant("removein", S, "                _kill(_record(position).in, slot: target, outward: false)", "", mode="stmt"),
    Mutant("removeout", S, "            _kill(_record(position).out, slot: source, outward: true)", "", mode="stmt"),
    Mutant("selfloopin", S, "target != slot", "true"),
    Mutant("selfloopout", S, "source < 0 || source == slot", "source < 0"),

    # Edge rows: lazy deletion and compaction.
    Mutant("swapoffsets", S, "_EdgeRecord(source: source, target: target, out: out, in: into)", "_EdgeRecord(source: source, target: target, out: into, in: out)"),
    Mutant("unlinkin", S, "                pages[targetPage].kill(r.in, inRow: r.target & _PositionPage.mask, table, edgeBase: base, outward: false)", "", mode="stmt"),
    Mutant("trailingdrop", P, "ends[start &+ count &- 1] < 0", "false"),
    Mutant("trailingdead", P, "                deadCount &-= 1", "", mode="stmt"),
    Mutant("nevercompact", P, "deadCount &* 2 > count", "false"),
    Mutant("compactthreshold", P, "deadCount &* 2 > count", "deadCount &* 2 >= count &* 2 &+ 1"),
    Mutant("compactin", P, "if outward { table[page].records[slot].out = kept } else { table[page].records[slot].in = kept }", "if outward { table[page].records[slot].out = kept }", mode="stmt"),
    Mutant("compactout", P, "if outward { table[page].records[slot].out = kept } else { table[page].records[slot].in = kept }", "if !outward { table[page].records[slot].in = kept }", mode="stmt"),
    Mutant("compactcount", P, "                    count = kept", "", mode="stmt"),
    Mutant("compactdead", P, "            deadCount = 0", "", mode="stmt"),
    Mutant("deadstore", P, "            rows[row].dead = deadCount", "", mode="stmt"),
    Mutant("growcopy", P, "            positions[start &+ k] = positions[block.start &+ k]", "", mode="stmt"),
    Mutant("packstart", P, "            rows[row].start = packedEnds.count", "", mode="stmt"),

    # Pages: freeing and dropping.
    Mutant("freeedgeearly", P, "        guard live == 0, records.count == _PositionPage.size else { return false }", "        guard live == 0 else { return false }", mode="stmt"),
    Mutant("freevertexearly", S, "if _vertexPages[k].live == 0, _vertexPages[k].vertices.count == _PositionPage.size { _freeVertexPage(k) }", "if _vertexPages[k].live == 0 { _freeVertexPage(k) }", mode="stmt"),
    Mutant("vertexlivecount", S, "        _vertexPages[k].live &-= 1", "", mode="stmt"),
    Mutant("dropvertexbase", S, "            _vertexBase &+= _vertexFront", "", mode="stmt"),
    Mutant("dropedgebase", S, "            _edgeBase &+= _edgeFront", "", mode="stmt"),
    Mutant("dropedgeall", S, "            _edgeBase = _edgeEnd &>> _PositionPage.shift", "", mode="stmt"),
    Mutant("dropvertexall", S, "            _vertexBase = _vertexEnd &>> _PositionPage.shift", "", mode="stmt"),

    # Finding copies.
    Mutant("oldest", S, "_newestEdge(from: source, to: target)", "(Array(edges(from: edge.source, to: edge.target)).first ?? -1)", nth=1),
    Mutant("lastoffset", P, "block.count &- 1", "block.count &- 2"),
    Mutant("lastvalue", P, "ends[block.start &+ k] != value", "ends[block.start &+ k] < 0"),

    # Re-pointing an edge.
    Mutant("changesame", S, "        guard target != record.target else { return }", "", mode="stmt"),
    Mutant("changeoldrow", S, "        _kill(record.in, slot: record.target, outward: false)", "", mode="stmt"),
    Mutant("changefarend", S, "_outPages[sourcePage].ends[_outPages[sourcePage].rows[record.source & _PositionPage.mask].start &+ record.out] = target", "", mode="stmt"),
    Mutant("changeoffset", S, "        _edgePages[ek].records[el].in = into", "", mode="stmt"),
    Mutant("changesourcetarget", S, "        _edgePages[ek].records[el].source = source", "", mode="stmt"),
    Mutant("insertorder", P, "                if positions[start &+ middle] < position { low = middle &+ 1 } else { high = middle }", "                high = middle", mode="stmt"),
    Mutant("insertshiftoffset", P, "                        if outward { table[page].records[slot].out = k } else { table[page].records[slot].in = k }", "", mode="stmt"),
    Mutant("insertrevive", P, "            rows[row].dead &-= 1", "", mode="stmt"),
    Mutant("safedead", S, "_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd)", "true", nth=0),

    # Indices and liveness.
    Mutant("vertexbound", C, "_vertexCount == _vertexEnd ? _vertexCount : nil", "_vertexEnd"),
    Mutant("vertexboundnil", C, "_vertexCount == _vertexEnd ? _vertexCount : nil", "nil"),
    Mutant("edgebound", C, "_edgeCount == _edgeEnd ? _edgeCount : nil", "_edgeEnd"),
    Mutant("edgeboundnil", C, "_edgeCount == _edgeEnd ? _edgeCount : nil", "nil"),
    Mutant("containsvertex", C, "pages[k].rows[l].dead >= 0", "true"),
    Mutant("containsedge", P, "l < pages[k].records.count && pages[k].records[l].source >= 0", "l < pages[k].records.count"),

    # Numbered rows.
    Mutant("numberholes", C, "rows[l].dead >= 0", "true", nth=1),
    Mutant("numberbyslot", C, "                        numbers[offset &+ l] = v", "                        numbers[offset &+ l] = l", mode="stmt"),
    Mutant("numberedslots", C, "numbers[pageOffsets[(end &>> shift) &- base] &+ (end & mask)]", "end"),
    Mutant("numberedpositions", C, "                                            edges[i] = positionStorage[j]", "                                            edges[i] = j", mode="stmt"),
    Mutant("numberedinward", C, "outward ? _outPages : _inPages", "_outPages"),
    Mutant("numberedbase", C, "_PositionNumbers(firstPage: base, pageOffsets: pageOffsets, numbers: numbers)", "_PositionNumbers(firstPage: 0, pageOffsets: pageOffsets, numbers: numbers)"),

    # Equality.
    Mutant("eqnosort", C, "                left.sort()", "", mode="stmt"),
    Mutant("eqslots", C, "left.append(map[target])", "left.append(target)"),

    # Codable.
    Mutant("encodeslot", C, "ends.append(offsets[r.source])", "ends.append(r.source)"),
    Mutant("vertexend", C, "try container.encode(_vertexEnd, forKey: .vertexEnd)", "try container.encode(_vertexCount, forKey: .vertexEnd)", mode="stmt"),
    Mutant("edgeend", C, "try container.encode(_edgeEnd, forKey: .edgeEnd)", "try container.encode(_edgeCount, forKey: .edgeEnd)", mode="stmt"),
    Mutant("repeatedvertex", C, "seen.insert(v).inserted", "true"),
    Mutant("oddedges", C, "ends.count.isMultiple(of: 2)", "true"),
    Mutant("endpointrange", C, "$0 < listed.count", "true"),
    Mutant("decodeincreasing", C, "p > previous", "p >= previous"),
    Mutant("decodefirstvertex", C, "positions.first ?? vertexEnd", "0"),
    Mutant("decodefirstedge", C, "edgePositions.first ?? edgeEnd", "0"),
    Mutant("plausiblespan", C, "span <= 16 * count + 64", "span <= 16 * count + 65"),
    Mutant("plausiblefirst", C, "Swift.max(first ?? end, 0) >> _PositionPage.shift", "0"),
    Mutant("skipjump", C, "                    _vertexEnd = end & ~_PositionPage.mask", "                    _vertexEnd = end", mode="stmt"),
    Mutant("skiphole", C, "            _outPages[k].appendRow(dead: -1)", "            _outPages[k].appendRow(dead: 0)", mode="stmt"),

    # Views.
    Mutant("vindicescontains", V, "l < pages[k].vertices.count && pages[k].vertices[l] != nil", "l < pages[k].vertices.count"),
    Mutant("eindicescontains", V, "_isLiveEdge(position, _base._pages, base: _base._base, end: _base._end)", "true"),
    Mutant("edgeiterholes", V, "record.source >= 0", "true", nth=1),
    Mutant("rowstart", V, "_end(k) < 0", "false", nth=0),
    Mutant("rowafter", V, "_end(k) < 0", "false", nth=1),
    Mutant("rowbefore", V, "_end(k) < 0", "false", nth=2),
    Mutant("rowpositions", V, "_ends[_ends.startIndex &+ k] >= 0", "true"),
    Mutant("rowends", V, "slot >= 0", "true"),
    Mutant("connecting", V, "_ends[_ends.startIndex &+ k] == _other", "_ends[_ends.startIndex &+ k] >= 0"),

    # Maps.

    # GraphProtocols: the numbered mode of _VertexIdentifiers.
    Mutant("idnumber", "VertexIdentifiers.swift", "rows.numbers[sparse.vertexPosition(of: vertex)]", "sparse.vertexPosition(of: vertex)", module="GraphProtocols"),
    Mutant("positionpage", "PositionNumbers.swift", "numbers[offset &+ (position & _PositionPage.mask)]", "numbers[offset]", module="GraphProtocols"),
    Mutant("builderskip", "PositionNumbers.swift", "if k > pageOffsets.count { pageOffsets.append(contentsOf: repeatElement(-1, count: k &- pageOffsets.count)) }", "", mode="stmt", module="GraphProtocols"),
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
