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
    Mutant("movelone", "ParallelClasses.swift", "if v >= 0 { value = target; return }", "if v >= 0 { return }", mode="stmt"),
    Mutant("rename", "ParallelClasses.swift", "if let moved = classes.removeValue(forKey: old) { classes[new] = moved }", "", mode="stmt"),
    Mutant("reorderlast", "ParallelClasses.swift", "        multi[c].last = order[order.count - 1]", "", mode="stmt"),
    Mutant("outoforder", "ParallelClasses.swift", "$0 >= $1", "$0 > $1"),

    # Pseudograph
    Mutant("newest", "Pseudograph.swift", "_parallel.last(at: index)", "(_parallel.classes.values[index] >= 0 ? _parallel.classes.values[index] : _parallel.multi[~_parallel.classes.values[index]].first)", nth=0),
    Mutant("renameclass", "Pseudograph.swift", "                _parallel.rename(oldKey, to: record.key)", "", mode="stmt"),
    Mutant("orientedkey", "Pseudograph.swift", "u <= v ? _SlotPair(u, v) : _SlotPair(v, u)", "_SlotPair(u, v)", nth=0),
    Mutant("decodeorder", "Pseudograph.swift", "if !order.isEmpty { try container.encode(order, forKey: .copyOrder) }", "", mode="stmt"),

    # DirectedPseudograph
    Mutant("dnewest", "DirectedPseudograph.swift", "_parallel.last(at: index)", "(_parallel.classes.values[index] >= 0 ? _parallel.classes.values[index] : _parallel.multi[~_parallel.classes.values[index]].first)", nth=0),
    Mutant("drename", "DirectedPseudograph.swift", "                _parallel.rename(oldKey, to: record.pair)", "", mode="stmt"),

    # Multigraph invariant
    Mutant("loopinsert", "Multigraph.swift", "!edge.isSelfLoop", "true", nth=0),
]
