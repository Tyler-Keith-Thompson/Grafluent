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

TESTS = ["StableGraphsTests", "TraversalTests", "ConnectivityTests", "GraphProtocolsTests"]

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
    Mutant("checkeddead", S, "_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd)", "true", nth=2),
    Mutant("checkedsourcedead", S, "_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd)", "true", nth=3),
    Mutant("checkedmissingtarget", S, "_slots[newTarget]", "Optional(_slots[newTarget] ?? 0)"),
    Mutant("checkedmissingsource", S, "_slots[newSource]", "Optional(_slots[newSource] ?? 0)"),
    Mutant("checkederrororder", S, "_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd)", "_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd) || _slots[newSource] == nil", nth=3),

    # The checked: lookups and insert.
    Mutant("checkedpositionsource", S, "_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd)", "position >= 0 && position < _edgeEnd", nth=0),
    Mutant("checkedpositiontarget", S, "_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd)", "position >= 0 && position < _edgeEnd", nth=1),
    Mutant("checkeddegree", S, "        return _outDegree(slot) + _inDegree(slot)", "        return _outDegree(slot)", mode="stmt", nth=1),
    Mutant("checkedindexholes", C, 'precondition(_vertexCount == _vertexEnd, "The graph has vertex holes, so no vertex indices; check vertexIndexBound first")', "", mode="stmt", nth=1),
    Mutant("checkedinsert", S, "_slots[edge.target]", "Optional(_slots[edge.target] ?? 0)", nth=2),

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

    # Maps: liveness, release, page freeing, resets, and the checked reads.
    Mutant("mapgetlive", M, 'precondition(_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd), "No edge at position \\(position): it was removed")', "", mode="stmt"),
    Mutant("mapsetlive", M, 'precondition(_isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd), "No edge at position \\(position) to hold a value")', "", mode="stmt"),
    Mutant("vmapgetlive", M, 'precondition(containsVertex(atPosition: position), "No vertex at position \\(position): it was removed")', "", mode="stmt"),
    Mutant("vmapsetlive", M, 'precondition(containsVertex(atPosition: position), "No vertex at position \\(position) to hold a value")', "", mode="stmt"),
    Mutant("mapchecked", M, "guard _isLiveEdge(position, _edgePages, base: _edgeBase, end: _edgeEnd) else { throw EdgeNotFound() }", "", mode="stmt"),
    Mutant("vmapchecked", M, "guard containsVertex(atPosition: position) else { throw VertexNotFound() }", "", mode="stmt"),
    Mutant("vmapcheckedof", M, "_slots[vertex]", "Optional(0)"),
    Mutant("maplayout", M, ".paged", "_MapLayout.dense", nth=1),
    Mutant("unlinkrelease", S, "            _edgeMaps.release(at: position)", "", mode="stmt", nth=0),
    Mutant("unlinkfreepage", S, "            if freed { _edgeMaps.freePage(position &>> _PositionPage.shift) }", "", mode="stmt", nth=0),
    Mutant("holerelease", S, "            _edgeMaps.release(at: position)", "", mode="stmt", nth=1),
    Mutant("holefreepage", S, "            if freed { _edgeMaps.freePage(position &>> _PositionPage.shift) }", "", mode="stmt", nth=1),
    Mutant("killrelease", S, "                    maps.release(at: position)", "", mode="stmt"),
    Mutant("killfreepage", S, "                    if freed { maps.freePage(position &>> _PositionPage.shift) }", "", mode="stmt"),
    Mutant("vertexrelease", S, "if !_vertexMaps.isEmpty { _vertexMaps.release(at: slot) }", "", mode="stmt"),
    Mutant("vertexfreepage", S, "if !_vertexMaps.isEmpty { _vertexMaps.freePage(_vertexBase &+ k) }", "", mode="stmt"),
    Mutant("resetedgemaps", S, "if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt", nth=0),
    Mutant("resetvertexmaps", S, "if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("edgesresetmaps", S, "if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt", nth=1),

    # Generations: each structural mutation's stamp, in file order, and one that would stamp a no-op.
    Mutant("geninsertedge", S, "        _generation.advanceVersion()", "", mode="stmt", nth=0),
    Mutant("genappendslot", S, "        _generation.advance()", "", mode="stmt", nth=0),
    Mutant("genremoveslot", S, "        _generation.advance()", "", mode="stmt", nth=1),
    Mutant("genchangetarget", S, "        _generation.advanceVersion()", "", mode="stmt", nth=1),
    Mutant("genchangesource", S, "        _generation.advanceVersion()", "", mode="stmt", nth=2),
    Mutant("genkillall", S, "        _generation.advanceVersion(storageIsEmpty: _edgePages.isEmpty)", "", mode="stmt", nth=0),
    Mutant("genunlink", S, "        _generation.advanceVersion(storageIsEmpty: _edgePages.isEmpty)", "", mode="stmt", nth=1),
    Mutant("genremoveall", S, "        _generation.advance()", "", mode="stmt", nth=2),
    Mutant("genremovealledges", S, "        _generation.advance()", "", mode="stmt", nth=3),
    Mutant("genkillallalways", S, "removed > 0", "true"),

    # GraphProtocols: the shared map storage and generations.
    Mutant("pagedempty", "AttachedMaps.swift", "$0.isEmpty ? defaultValue : $0[offset & _PositionPage.mask]", "$0[offset & _PositionPage.mask]", module="GraphProtocols"),
    Mutant("pagednegative", "AttachedMaps.swift", "k >= 0", "true", nth=0, module="GraphProtocols"),
    Mutant("pagedfront", "AttachedMaps.swift", "            pages.insert(contentsOf: repeatElement([], count: firstPage &- page), at: 0)\n            firstPage = page", "            firstPage = page", mode="stmt", module="GraphProtocols"),
    Mutant("pagedresetnoop", "AttachedMaps.swift", "        pages[k][offset & _PositionPage.mask] = defaultValue", "", mode="stmt", module="GraphProtocols"),
    Mutant("freepagetrimback", "AttachedMaps.swift", "        while let last = pages.last, last.isEmpty { pages.removeLast() }", "", mode="stmt", module="GraphProtocols"),
    Mutant("freepagetrimfront", "AttachedMaps.swift", "front &* 2 >= pages.count", "front &* 2 > pages.count", module="GraphProtocols"),
    Mutant("freepagenoop", "AttachedMaps.swift", "        pages[k] = []", "", mode="stmt", module="GraphProtocols"),
    Mutant("swapremovelast", "AttachedMaps.swift", "        if offset != count { _copyValue(to: base + offset &* stride, from: base + count &* stride) }", "", mode="stmt", module="GraphProtocols"),
    Mutant("swapremovetyped", "AttachedMaps.swift", "        if offset != count { elements[offset] = last }", "", mode="stmt", module="GraphProtocols"),
    Mutant("densetypedreset", "AttachedMaps.swift", "        elements[offset] = defaultValue", "", mode="stmt", module="GraphProtocols"),
    Mutant("appenddefault", "AttachedMaps.swift", "            _copyValue(to: target, from: defaultAddress)", "", mode="stmt", module="GraphProtocols"),
    Mutant("appendtyped", "AttachedMaps.swift", "        (elements + count).initialize(repeating: defaultValue, count: n)", "        (elements + count).initialize(repeating: defaultValue, count: n)\n        if n > 0 { elements[count] = elements[0] }", mode="stmt", module="GraphProtocols"),
    Mutant("fastappendcount", "AttachedMaps.swift", "            buffer.count = c &+ 1", "            buffer.count = c", mode="stmt", module="GraphProtocols"),
    Mutant("fastappendvalue", "AttachedMaps.swift", "buffer.defaultAddress", "UnsafeRawPointer(buffer.base)", nth=0, module="GraphProtocols"),
    Mutant("fastremovecount", "AttachedMaps.swift", "            buffer.count = last", "            buffer.count = last &+ 1", mode="stmt", module="GraphProtocols"),
    Mutant("fastremovemove", "AttachedMaps.swift", "offset != last", "false", module="GraphProtocols"),
    Mutant("fastresetvalue", "AttachedMaps.swift", "buffer.defaultAddress", "UnsafeRawPointer(target)", nth=1, module="GraphProtocols"),
    Mutant("fastappendshared", "AttachedMaps.swift", "_allTrivialDense && count == 1 && !_someMayBeShared.load(ordering: .relaxed)", "_allTrivialDense && count == 1", module="GraphProtocols"),
    Mutant("fastremoveshared", "AttachedMaps.swift", "_allTrivialDense && !_someMayBeShared.load(ordering: .relaxed)", "_allTrivialDense", module="GraphProtocols"),
    Mutant("fastresetshared", "AttachedMaps.swift", "table._allTrivialDense && !table._someMayBeShared.load(ordering: .relaxed)", "table._allTrivialDense", module="GraphProtocols"),
    Mutant("tableflaginit", "AttachedMaps.swift", "            someMayBeShared = someMayBeShared || source[j].buffer._mayBeShared.load(ordering: .relaxed)", "", mode="stmt", module="GraphProtocols"),
    Mutant("snapshotmarktable", "AttachedMaps.swift", "            _table.unsafelyUnwrapped._someMayBeShared.store(true, ordering: .relaxed)", "", mode="stmt", module="GraphProtocols"),
    Mutant("alltrivialappend", "AttachedMaps.swift", "            allTrivialDense = allTrivialDense && appending.buffer._isTrivialDense", "", mode="stmt", module="GraphProtocols"),
    Mutant("attachcount", "AttachedMaps.swift", "_DenseMapBufferOf(repeating: value, count: count, witnesses: witnesses)", "_DenseMapBufferOf(repeating: value, count: 0, witnesses: witnesses)", module="GraphProtocols"),
    Mutant("releasesall", "AttachedMaps.swift", "!_isPOD(Value.self)", "true", module="GraphProtocols"),
    Mutant("releasesnone", "AttachedMaps.swift", "!_isPOD(Value.self)", "false", module="GraphProtocols"),
    Mutant("hintwrong", "AttachedMaps.swift", "if hint >= 0, hint < entries.count, entries[hint].token === token { return hint }", "if hint >= 0, hint < entries.count { return hint }", mode="stmt", module="GraphProtocols"),
    Mutant("tableshared", "AttachedMaps.swift", "_slowPath(!isKnownUniquelyReferenced(&_table))", "_slowPath(_table == nil)", module="GraphProtocols"),
    Mutant("tablemark", "AttachedMaps.swift", "_MapTable(UnsafeBufferPointer(entries), removing: nil, appending: nil, markingShared: true)", "_MapTable(UnsafeBufferPointer(entries), removing: nil, appending: nil, markingShared: false)", module="GraphProtocols"),
    Mutant("replacemark", "AttachedMaps.swift", "!isKnownUniquelyReferenced(&_table)", "false", nth=0, module="GraphProtocols"),
    Mutant("bufferflag", "AttachedMaps.swift", "        if _slowPath(entries[k].buffer._mayBeShared.load(ordering: .relaxed)) { _copyIfShared(k) }", "", mode="stmt", module="GraphProtocols"),
    Mutant("bufferunique", "AttachedMaps.swift", "isKnownUniquelyReferenced(&entries[k].buffer)", "true", module="GraphProtocols"),
    Mutant("snapshotmark", "AttachedMaps.swift", "            dense._markShared()", "", mode="stmt", module="GraphProtocols"),
    Mutant("valueslayout", "PropertyGraph.swift", "if Base._edgeMapLayout == .dense { return _storage.denseValue(at: k) }", "", mode="stmt", module="GraphProtocols"),
    Mutant("gencurrentversion", "GraphGeneration.swift", "        guard _version == generation._version, _lineage == generation._lineage else { return false }", "        guard _lineage == generation._lineage else { return false }", mode="stmt", module="GraphProtocols"),
    Mutant("gencurrentlineage", "GraphGeneration.swift", "        guard _version == generation._version, _lineage == generation._lineage else { return false }", "        guard _version == generation._version else { return false }", mode="stmt", module="GraphProtocols"),
    Mutant("gencurrentuntracked", "GraphGeneration.swift", "        guard _lineage != 0 || (_version != 0 && storage != nil) else { return false }", "", mode="stmt", module="GraphProtocols"),
    Mutant("gencurrentneverversion", "GraphGeneration.swift", "(_version != 0 && storage != nil)", "storage != nil", module="GraphProtocols"),
    Mutant("gencurrentstorage", "GraphGeneration.swift", "        return storage === generation._storage", "        return true", mode="stmt", module="GraphProtocols"),
    Mutant("gennevermint", "GraphGeneration.swift", "_fastPath(isKnownUniquelyReferenced(&_token))", "_fastPath(_token != nil)", module="GraphProtocols"),
    Mutant("genadvanceversion", "GraphGeneration.swift", "        _version &+= 1", "", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("genemptystorage", "GraphGeneration.swift", "        if _slowPath(storageIsEmpty) { advance() } else { _version &+= 1 }", "        _version &+= 1", mode="stmt", module="GraphProtocols"),
    Mutant("genstorageof", "GraphGeneration.swift", "array.isEmpty ? nil : unsafeBitCast(array, to: AnyObject.self)", "nil", module="GraphProtocols"),
    Mutant("genstamp", "GraphGeneration.swift", "        _lineage = Self._newLineage()", "", mode="stmt", nth=0, module="GraphProtocols"),
    Mutant("genviewuntracked", "GraphAdaptor.swift", "base.generation", "GraphGeneration.untracked", nth=3, module="GraphProtocols"),

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
