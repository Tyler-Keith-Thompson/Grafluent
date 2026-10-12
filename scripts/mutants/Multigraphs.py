# Planted bugs for Multigraphs; run with `just mutate Multigraphs`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   outoforder  `>` for `>=` between positions of one class: positions are distinct, so they agree.

TESTS = ["MultigraphsTests"]

MUTANTS = [
    # Parallel classes
    Mutant("appendlink", "ParallelClasses.swift", "            links[previous].next = position", "", mode="stmt"),
    Mutant("appendlast", "ParallelClasses.swift", "            multi[c].last = position", "", mode="stmt", nth=0),
    Mutant("unlinkfirst", "ParallelClasses.swift", "if link.previous != -1 { links[link.previous].next = link.next } else { multi[c].first = link.next }", "if link.previous != -1 { links[link.previous].next = link.next }", nth=0, mode="stmt"),
    Mutant("unlinklone", "ParallelClasses.swift", "multi[c].count == 1", "multi[c].count == 0", nth=0),
    Mutant("movelink", "ParallelClasses.swift", "if link.next != -1 { links[link.next].previous = target } else { multi[c].last = target }", "if link.next != -1 { links[link.next].previous = target }", mode="stmt"),
    Mutant("movelone", "ParallelClasses.swift", "            classes.setValue(target, at: index)", "", mode="stmt"),
    Mutant("rename", "ParallelClasses.swift", "if let moved = classes.removeValue(forKey: old) { classes.insert(new, moved) }", "", mode="stmt"),
    Mutant("reorderlast", "ParallelClasses.swift", "        multi[c].last = order[order.count - 1]", "", mode="stmt"),
    Mutant("outoforder", "ParallelClasses.swift", "$0 >= $1", "$0 > $1"),

    # Pseudograph
    Mutant("newest", "Pseudograph.swift", "_parallel.last(at: index)", "(_parallel.classes.value(at: index) >= 0 ? _parallel.classes.value(at: index) : _parallel.multi[~_parallel.classes.value(at: index)].first)", nth=0),
    Mutant("renameclass", "Pseudograph.swift", "                _parallel.rename(oldKey, to: record.key)", "", mode="stmt"),
    Mutant("orientedkey", "Pseudograph.swift", "u <= v ? _SlotPair(u, v) : _SlotPair(v, u)", "_SlotPair(u, v)", nth=0),
    Mutant("decodeorder", "Pseudograph.swift", "if !order.isEmpty { try container.encode(order, forKey: .copyOrder) }", "", mode="stmt"),

    # DirectedPseudograph
    Mutant("dnewest", "DirectedPseudograph.swift", "_parallel.last(at: index)", "(_parallel.classes.value(at: index) >= 0 ? _parallel.classes.value(at: index) : _parallel.multi[~_parallel.classes.value(at: index)].first)", nth=0),
    Mutant("drename", "DirectedPseudograph.swift", "                _parallel.rename(oldKey, to: record.pair)", "", mode="stmt"),

    # Multigraph invariant
    Mutant("loopinsert", "Multigraph.swift", "!edge.isSelfLoop", "true", nth=0),
    Mutant("loopthrow", "Multigraph.swift", "        if edge.isSelfLoop { throw .selfLoop }", "", mode="stmt"),
    Mutant("dloopthrow", "DirectedMultigraph.swift", "        if edge.isSelfLoop { throw .selfLoop }", "", mode="stmt"),

    # The `checked:` spellings
    Mutant("pcheckedinsert", "Pseudograph.swift", "_slots[edge.v]", "Optional(_slots[edge.v] ?? 0)", nth=1),
    Mutant("pcheckeddegree", "Pseudograph.swift", "        return _neighbors.count(ofRow: slot)", "        return _neighbors.count(ofRow: slot) &- 1", mode="stmt"),
    Mutant("pcheckedincident", "Pseudograph.swift", "        return _incident[row: slot]", "        return _neighbors[row: slot]", mode="stmt"),
    Mutant("pcheckedindex", "Pseudograph.swift", "        return slot\n", "        return slot &+ 1\n", mode="stmt", nth=0),
    Mutant("dpcheckedinsert", "DirectedPseudograph.swift", "_slots[edge.target]", "Optional(_slots[edge.target] ?? 0)", nth=1),
    Mutant("dpcheckedsourcebound", "DirectedPseudograph.swift", "UInt(bitPattern: position) < UInt(bitPattern: _records.count)", "position <= _records.count", nth=0),
    Mutant("dpcheckedtargetbound", "DirectedPseudograph.swift", "UInt(bitPattern: position) < UInt(bitPattern: _records.count)", "position < _records.count", nth=1),
    Mutant("dpcheckedsourceend", "DirectedPseudograph.swift", "        return _vertices[_records[position].source]", "        return _vertices[_records[position].target]", mode="stmt"),
    Mutant("dpcheckeddegree", "DirectedPseudograph.swift", "        return _out.count(ofRow: slot) + _in.count(ofRow: slot)", "        return _out.count(ofRow: slot)", mode="stmt", nth=1),
    Mutant("dpcheckedpredecessors", "DirectedPseudograph.swift", "_in[row: slot]", "_out[row: slot]"),
    Mutant("dpcheckedinedges", "DirectedPseudograph.swift", "_inEdges[row: slot]", "_outEdges[row: slot]"),
    Mutant("dpcheckedindex", "DirectedPseudograph.swift", "        return slot\n", "        return slot &+ 1\n", mode="stmt", nth=0),
    Mutant("mcheckedmissing", "Multigraph.swift", "_base._slots[edge.v]", "Optional(_base._slots[edge.v] ?? 0)"),
    Mutant("mcheckedloop", "Multigraph.swift", "        if u == v { throw .selfLoop }", "", mode="stmt"),
    Mutant("dmcheckedmissing", "DirectedMultigraph.swift", "_base._slots[edge.target]", "Optional(_base._slots[edge.target] ?? 0)"),
    Mutant("dmcheckedloop", "DirectedMultigraph.swift", "        if source == target { throw .selfLoop }", "", mode="stmt"),
]
