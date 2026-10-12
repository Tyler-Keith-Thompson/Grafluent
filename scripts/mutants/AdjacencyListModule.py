# Planted bugs for AdjacencyListModule's hashing: `_SlotPairTable` (open addressing with linear
# probing, growth at three-quarters full, backward-shift deletion) and `_VertexSlots` (the identity
# mode for vertices 0..<n and its switch to a dictionary). The sorted bulk rows are planted from
# NamedGraphs. Run with `just mutate AdjacencyListModule`; see scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   slotsappend      `v >= _identityCount` for `v == _identityCount` when a slot is set: the identity
#                    also needs `newValue == v`, and every caller (`_appendSlot`) sets the next slot,
#                    `_identityCount`, so a vertex above the count fails that test either way.
#   slotsremovelast  `v < _identityCount` for `v == _identityCount &- 1` when a slot is cleared: the
#                    lists clear a slot only after moving the last vertex into the hole, and that
#                    move (`_slots[moved] = slot`, slot ≠ last) already ends the identity, so while
#                    it holds the only present vertex ever cleared is the last.

TESTS = ["AdjacencyListTests", "UndirectedAdjacencyListTests", "MultigraphsTests"]

ST = "SlotPairTable.swift"
VS = "VertexSlots.swift"
AL = "AdjacencyList.swift"
UAL = "UndirectedAdjacencyList.swift"

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
]
