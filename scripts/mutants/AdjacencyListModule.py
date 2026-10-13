# Planted bugs for AdjacencyListModule's hashing: `_SlotPairTable` (open addressing with linear
# probing, growth at three-quarters full, backward-shift deletion) and `_VertexSlots` (the identity
# mode for vertices 0..<n and its switch to a dictionary), and the attached maps and generations of
# both lists (`PropertyGraph`). The sorted bulk rows are planted from NamedGraphs. Run with
# `just mutate AdjacencyListModule`; see scripts/mutate.py.
#
# Not planted, being equivalent: the bounds preconditions of the plain map subscripts (a dense map
# holds exactly `edgeCount` / `vertexCount` values, so its own array bounds check traps at the same
# positions) and the maps' `reserveCapacity` (capacity only).
#
# Known equivalent mutants (they survive by design):
#   slotsappend      `v >= _identityCount` for `v == _identityCount` when a slot is set: the identity
#                    also needs `newValue == v`, and every caller (`_appendSlot`) sets the next slot,
#                    `_identityCount`, so a vertex above the count fails that test either way.
#   slotsremovelast  `v < _identityCount` for `v == _identityCount &- 1` when a slot is cleared: the
#                    lists clear a slot only after moving the last vertex into the hole, and that
#                    move (`_slots[moved] = slot`, slot ≠ last) already ends the identity, so while
#                    it holds the only present vertex ever cleared is the last.
#
# Not planted, being equivalent: the plain `storageMayHaveMoved` for the maps spelling in
# `reserveCapacity`: it reserves in each attached map first, which makes that map's table the
# graph's own, so the tables are its own before the identity array moves.

TESTS = ["AdjacencyListTests", "UndirectedAdjacencyListTests", "MultigraphsTests"]

ST = "SlotPairTable.swift"
VS = "VertexSlots.swift"
AL = "AdjacencyList.swift"
UAL = "UndirectedAdjacencyList.swift"
SC = "SortedConstruction.swift"
FO = "FileOrderConstruction.swift"

MUTANTS = [
    # Packing and hashing.
    Mutant("tablepack", ST, "UInt64(truncatingIfNeeded: pair.source) << 32 | UInt64(truncatingIfNeeded: pair.target) & 0xFFFF_FFFF", "UInt64(truncatingIfNeeded: pair.source) &+ UInt64(truncatingIfNeeded: pair.target)"),
    Mutant("tableunpack", ST, "Int(truncatingIfNeeded: key >> 32)", "Int(truncatingIfNeeded: key >> 31)"),
    Mutant("tablehome", ST, "Int(truncatingIfNeeded: ((key ^ _seed) &* 0x9E37_79B9_7F4A_7C15) &>> _shift)", "0"),

    # Lookup.
    Mutant("lookupempty", ST, "        guard _count > 0 else { return nil }", "", mode="stmt"),
    Mutant("lookupmatch", ST, "if k == key { return i }", "if k == key { return nil }", mode="stmt"),
    Mutant("lookupstop", ST, "if k == Self._empty { return nil }", "", mode="stmt"),
    Mutant("lookupstep", ST, "i = (i &+ 1) & mask", "i = (i &+ 2) & mask", mode="stmt", nth=0),

    # Insertion and growth.
    Mutant("insertgrow", ST, "(_count &+ 1) &* 4 > _buckets.count &* 3", "(_count &+ 1) &* 4 > _buckets.count &* 4"),
    Mutant("insertfound", ST, "if k == key { return false }", "if k == key { return true }", mode="stmt"),
    Mutant("insertplace", ST, "                    buckets[i] = _Bucket(key: key, value: value)", "", mode="stmt", nth=0),
    Mutant("insertcount", ST, "        if inserted { _count &+= 1 }", "", mode="stmt"),
    Mutant("insertstep", ST, "i = (i &+ 1) & mask", "i = (i &+ 2) & mask", mode="stmt", nth=1),
    Mutant("updatevalue", ST, "        if !inserted { _buckets[i].value = value }", "", mode="stmt"),
    Mutant("resizesize", ST, "(1 << bits) &* 3 < Swift.max(minimumCapacity, _count) &* 4", "(1 << bits) &* 4 < Swift.max(minimumCapacity, _count) &* 4"),
    Mutant("resizeclear", ST, "            for i in 0 ..< size { raw.storeBytes(of: Self._empty, toByteOffset: i &* stride, as: UInt64.self) }", "", mode="stmt"),
    Mutant("resizeshift", ST, "UInt64(64 &- bits)", "UInt64(63 &- bits)"),
    Mutant("resizeprobe", ST, "                    while buckets[i].key != Self._empty { i = (i &+ 1) & mask }", "", mode="stmt", nth=2),

    # Backward-shift deletion.
    Mutant("removestop", ST, "                if k == Self._empty { break }", "", mode="stmt"),
    Mutant("removehome", ST, "((k ^ seed) &* 0x9E37_79B9_7F4A_7C15) &>> shift", "((k ^ seed) &* 0x9E37_79B9_7F4A_7C15) &>> (shift &+ 1)"),
    Mutant("removereach", ST, "hole < h && h <= j", "hole <= h && h <= j"),
    Mutant("removereachend", ST, "hole < h && h <= j", "hole < h && h < j"),
    Mutant("removereachwrap", ST, "hole < h || h <= j", "hole < h || h < j"),
    Mutant("removereachwrapstart", ST, "hole < h || h <= j", "hole <= h || h <= j"),
    Mutant("removeshift", ST, "!reachable", "reachable"),
    Mutant("removemove", ST, "                    buckets[hole] = buckets[j]", "", mode="stmt"),
    Mutant("removehole", ST, "                    hole = j", "", mode="stmt"),
    Mutant("removeclear", ST, "            buckets[hole].key = Self._empty", "", mode="stmt"),
    Mutant("removecount", ST, "        _count &-= 1", "", mode="stmt"),
    Mutant("removevalue", ST, "        remove(at: i)", "", mode="stmt"),
    Mutant("removeallkeys", ST, "            for i in buckets.indices { buckets[i].key = Self._empty }", "", mode="stmt"),
    Mutant("removeallcount", ST, "        _count = 0", "", mode="stmt", nth=1),

    # Iteration.
    Mutant("iteratorskip", ST, "bucket.key != _SlotPairTable._empty", "true"),

    # Vertex slots: the identity and its end.
    Mutant("slotsgetnegative", VS, "UInt(bitPattern: v) < UInt(bitPattern: _identityCount) ? v : nil", "v < _identityCount ? v : nil"),
    Mutant("slotsgetbound", VS, "UInt(bitPattern: v) < UInt(bitPattern: _identityCount) ? v : nil", "UInt(bitPattern: v) <= UInt(bitPattern: _identityCount) ? v : nil"),
    Mutant("slotsappend", VS, "v == _identityCount", "v >= _identityCount", nth=0),
    Mutant("slotsremovelast", VS, "v == _identityCount &- 1", "v < _identityCount"),
    Mutant("slotswrite", VS, "                _writeTable()", "", mode="stmt"),
    Mutant("slotswriteloop", VS, "        for v in 0 ..< count { _table[unsafeBitCast(v, to: Vertex.self)] = v }", "", mode="stmt"),
    Mutant("slotswriteend", VS, "        _identityCount = -1", "", mode="stmt"),
    Mutant("slotsremoveall", VS, "Vertex.self == Int.self ? 0 : -1", "_identityCount", nth=1),

    # The `checked:` spellings.
    Mutant("checkedsourcebound", AL, "UInt(bitPattern: position) < UInt(bitPattern: _records.count)", "position <= _records.count", nth=0),
    Mutant("checkedtargetbound", AL, "UInt(bitPattern: position) < UInt(bitPattern: _records.count)", "position < _records.count", nth=1),
    Mutant("checkedsourceend", AL, "        return _vertices[_records[position].source]", "        return _vertices[_records[position].target]", mode="stmt"),
    Mutant("checkeddegree", AL, "        return _out.count(ofRow: slot) + _in.count(ofRow: slot)", "        return _out.count(ofRow: slot)", mode="stmt", nth=1),
    Mutant("checkedpredecessors", AL, "_in[row: slot]", "_out[row: slot]"),
    Mutant("checkedinedges", AL, "_inEdges[row: slot]", "_outEdges[row: slot]"),
    Mutant("checkedindex", AL, "        return slot\n", "        return slot &+ 1\n", mode="stmt", nth=0),
    Mutant("checkedinsert", AL, "_slots[edge.target]", "Optional(_slots[edge.target] ?? 0)", nth=2),
    Mutant("ucheckeddegree", UAL, "        return _neighbors.count(ofRow: slot)", "        return _neighbors.count(ofRow: slot) &- 1", mode="stmt"),
    Mutant("ucheckedincident", UAL, "        return _incident[row: slot]", "        return _neighbors[row: slot]", mode="stmt"),
    Mutant("ucheckedindex", UAL, "        return slot\n", "        return slot &+ 1\n", mode="stmt", nth=0),
    Mutant("ucheckedinsert", UAL, "_slots[edge.v]", "Optional(_slots[edge.v] ?? 0)", nth=2),

    # Attached maps (PropertyGraph) and generations.
    Mutant("mapsinsertedge", AL, "        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaultsToOwnTable(count: 1) }", "", mode="stmt"),
    Mutant("mapsdetach", AL, "        if !_edgeMaps.isEmpty { _edgeMaps.swapRemove(at: position) }", "", mode="stmt"),
    Mutant("mapsremoveedge", AL, "        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }", "", mode="stmt", nth=0),
    Mutant("mapsremoveedgeat", AL, "        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }", "", mode="stmt", nth=1),
    Mutant("mapsremoveslot", AL, "        if !_vertexMaps.isEmpty { _vertexMaps.swapRemove(at: slot) }", "", mode="stmt"),
    Mutant("mapsappendslot", AL, "        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaultsToOwnTable(count: 1) }", "", mode="stmt"),
    Mutant("mapsremoveallvertex", AL, "        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("mapsremovealledge", AL, "        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt", nth=0),
    Mutant("mapsremovealledges", AL, "        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt", nth=1),
    Mutant("umapsinsertedge", UAL, "        if !_edgeMaps.isEmpty { _edgeMaps.appendDefaultToOwnTableInline() }", "", mode="stmt"),
    Mutant("umapsdetach", UAL, "        if !_edgeMaps.isEmpty { _edgeMaps.swapRemove(at: position) }", "", mode="stmt"),
    Mutant("umapsremoveedge", UAL, "        if !_edgeMaps.isEmpty { _edgeMaps.swapRemoveInOwnTable(at: position) }", "", mode="stmt"),
    Mutant("umapsremoveslot", UAL, "        if !_vertexMaps.isEmpty { _vertexMaps.swapRemove(at: slot) }", "", mode="stmt"),
    Mutant("umapsappendslot", UAL, "        if !_vertexMaps.isEmpty { _vertexMaps.appendDefaultsToOwnTable(count: 1) }", "", mode="stmt"),
    Mutant("umapsremoveallvertex", UAL, "        if !_vertexMaps.isEmpty { _vertexMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt"),
    Mutant("umapsremovealledge", UAL, "        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt", nth=0),
    Mutant("umapsremovealledges", UAL, "        if !_edgeMaps.isEmpty { _edgeMaps.removeAll(keepingCapacity: keepingCapacity) }", "", mode="stmt", nth=1),
    Mutant("geninsertedge", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=0),
    Mutant("genremoveslot", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=1),
    Mutant("genremoveedge", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=2),
    Mutant("genremovealledges", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=3),
    Mutant("genappendslot", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=4),
    Mutant("genremoveedgeat", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=5),
    Mutant("genremoveall", AL, "        if changes { _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps) } else { _generation.storageMayHaveMoved(_out.rows, maps: &_vertexMaps, &_edgeMaps) }", "        _generation.storageMayHaveMoved(_out.rows, maps: &_vertexMaps, &_edgeMaps)", mode="stmt"),
    Mutant("genremoveallempty", AL, "!_vertices.isEmpty", "true"),
    Mutant("ugenremove", UAL, "        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=0),
    Mutant("ugenremoveedge", UAL, "        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=1),
    Mutant("ugenremovealledges", UAL, "        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=2),
    Mutant("ugenappendslot", UAL, "        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=3),
    Mutant("ugeninsertedge", UAL, "        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt", nth=4),
    Mutant("ugenreverse", UAL, "        _generation.advance(owning: &_neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "", mode="stmt"),
    Mutant("ugenreversewriting", UAL, "_generation.advance(owning: &_neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "_generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", mode="stmt"),
    Mutant("ugenremoveall", UAL, "        if changes { _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps) } else { _generation.storageMayHaveMoved(_neighbors.rows, maps: &_vertexMaps, &_edgeMaps) }", "        _generation.storageMayHaveMoved(_neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", mode="stmt"),
    Mutant("ugenremoveallempty", UAL, "!_vertices.isEmpty", "true"),
    # A graph that leaves its identity array owns both tables (the maps spellings): each mutation
    # whose map upkeep follows its advance, owned, and the reservation.
    Mutant("ownsinsertedge", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "        _generation.advance(writing: _out.rows)", mode="stmt", nth=0),
    Mutant("ownsremoveedge", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "        _generation.advance(writing: _out.rows)", mode="stmt", nth=2),
    Mutant("ownsappendslot", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "        _generation.advance(writing: _out.rows)", mode="stmt", nth=4),
    Mutant("ownsremoveedgeat", AL, "        _generation.advance(writing: _out.rows, maps: &_vertexMaps, &_edgeMaps)", "        _generation.advance(writing: _out.rows)", mode="stmt", nth=5),
    Mutant("uownsremoveedge", UAL, "        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "        _generation.advance(writing: _neighbors.rows)", mode="stmt", nth=1),
    Mutant("uownsappendslot", UAL, "        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "        _generation.advance(writing: _neighbors.rows)", mode="stmt", nth=3),
    Mutant("uownsinsertedge", UAL, "        _generation.advance(writing: _neighbors.rows, maps: &_vertexMaps, &_edgeMaps)", "        _generation.advance(writing: _neighbors.rows)", mode="stmt", nth=4),
    # The detach's record writes, in one access.
    Mutant("detachmovedout", AL, "            if let movedOut { records[movedOut].out = record.out }", "", mode="stmt"),
    Mutant("detachmovedin", AL, "            if let movedIn { records[movedIn].in = record.in }", "", mode="stmt"),
    Mutant("detachlast", AL, "            records[position] = records[last]", "", mode="stmt"),
    Mutant("gensorted", SC, "        _generation.stamp()", "", mode="stmt", nth=0),
    Mutant("ugensorted", SC, "        _generation.stamp()", "", mode="stmt", nth=1),
    Mutant("genslotted", SC, "        _generation.stamp()", "", mode="stmt", nth=2),
    Mutant("ugenslotted", SC, "        _generation.stamp()", "", mode="stmt", nth=3),
    Mutant("genbuilt", FO, "        graph._generation.stamp()", "", mode="stmt", nth=0),
    Mutant("ugenbuilt", FO, "        graph._generation.stamp()", "", mode="stmt", nth=1),
] + [
    m
    for tag, path in (("", "AdjacencyList+PropertyGraph.swift"), ("u", "UndirectedAdjacencyList+PropertyGraph.swift"))
    for m in (
        Mutant(f"{tag}mapaddedgecount", path, "_records.count", "0", nth=0),
        Mutant(f"{tag}mapaddvertexcount", path, "_vertices.count", "0", nth=0),
        Mutant(f"{tag}mapremoveedge", path, "        _edgeMaps.remove(map._token, hint: map._hint)", "", mode="stmt"),
        Mutant(f"{tag}mapremovevertex", path, "        _vertexMaps.remove(map._token, hint: map._hint)", "", mode="stmt"),
        Mutant(f"{tag}mapcheckededge", path, "UInt(bitPattern: position) < UInt(bitPattern: _records.count)", "position <= _records.count", nth=2),
        Mutant(f"{tag}mapcheckedvertexat", path, "UInt(bitPattern: position) < UInt(bitPattern: _vertices.count)", "position <= _vertices.count", nth=2),
        Mutant(f"{tag}mapcheckedvertex", path, "_slots[vertex]", "Optional(_slots[vertex] ?? 0)"),
        Mutant(f"{tag}mapofvertex", path, "_slot(of: vertex)", "0", nth=0),
    )
] + [
    # reuse pass (C): the pooled out-rows lent to algorithms, and their copy into compressed rows.
    Mutant("outrowsedges", AL, "            _outEdges.withUnsafeRows { edges, edgeRows in body(targets, targetRows, edges, edgeRows) }", "            _out.withUnsafeRows { edges, edgeRows in body(targets, targetRows, edges, edgeRows) }", mode="stmt"),
    Mutant("pooledloops", "CompressedRows.swift", "k &+= w == v ? 0 : 1", "k &+= 1", module="GraphProtocols"),
    Mutant("pooledbulkedges", "CompressedRows.swift", "edges.append(edgeIndex(of: unsafeBitCast(pooledEdges[edgeStart + k], to: Edges.Index.self)))", "edges.append(k)", module="GraphProtocols"),
    Mutant("pooledloopedges", "CompressedRows.swift", "!dropsLoops || pooled[start + k] != v", "true", module="GraphProtocols"),
]
