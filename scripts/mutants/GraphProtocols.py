# Planted bugs for GraphProtocols' self-loop queries; run with `just mutate GraphProtocols`. See
# scripts/mutate.py.
#
# Known equivalent mutants are not planted: dropping `continue rows` (no representation with stored
# rows keeps a repeated edge, so a row has at most one self-loop), dropping an early stop (only the
# work after the answer changes), and choosing `outEdges(of:)` over `outEdges(ofIndex:)` (the same
# row).

TESTS = ["GraphProtocolsTests"]

MUTANTS = [
    # Directed: each path that finds the vertices with a self-loop.
    Mutant("slnonindexed", "SelfLoops.swift", "successors(of: vertex).contains(vertex)", "false"),
    Mutant("slrows", "SelfLoops.swift", "targets[k] == v", "targets[k] != v", nth=0),
    Mutant("slpooled", "SelfLoops.swift", "targets[k] == v", "targets[k] != v", nth=1),
    Mutant("slpooledlength", "SelfLoops.swift", "start ..< start &+ targetRows[3 &* v &+ 1]", "start ..< start &+ targetRows[3 &* v]"),
    Mutant("slindexed", "SelfLoops.swift", "successorIndices(ofIndex: v).contains(v)", "false"),
    Mutant("slfound", "SelfLoops.swift", "            found = true", "", mode="stmt", nth=0),
    Mutant("slappend", "SelfLoops.swift", "            result.append(vertex)", "", mode="stmt", nth=0),
    Mutant("sledgetarget", "SelfLoops.swift", "target(ofEdgeAt: position) == vertex", "true"),
    # Undirected.
    Mutant("slunonindexed", "SelfLoops.swift", "neighbors(of: vertex).contains(vertex)", "false"),
    Mutant("sluindexed", "SelfLoops.swift", "neighborIndices(ofIndex: v).contains(v)", "false"),
    Mutant("slufound", "SelfLoops.swift", "            found = true", "", mode="stmt", nth=1),
    Mutant("sluappend", "SelfLoops.swift", "            result.append(vertex)", "", mode="stmt", nth=1),
    Mutant("sluopposite", "SelfLoops.swift", "oppositeVertex(to: vertex, acrossEdgeAt: position) == vertex", "true"),
    Mutant("sluonce", "SelfLoops.swift", "seen.insert(position).inserted", "true"),
]
