# Planted bugs for GraphProtocols' self-loop queries; run with `just mutate GraphProtocols`. See
# scripts/mutate.py.
#
# Known equivalent mutants are not planted: dropping `continue rows` (no representation with stored
# rows keeps a repeated edge, so a row has at most one self-loop), dropping an early stop (only the
# work after the answer changes), and choosing `outEdges(of:)` over `outEdges(ofIndex:)` (the same
# row).

TESTS = ["GraphProtocolsTests", "StableGraphsTests", "MultigraphsTests", "BipartiteGraphsTests"]

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

# PropertyGraphBundle and the snapshots as values (PropertyGraph.swift, PropertyGraphBundle.swift,
# AttachedMaps.swift). Not planted: dropping the `owner` of a decoded dense storage (the buffer
# would be freed and the values read garbage; undefined behaviour, not a wrong answer).
PB = "PropertyGraphBundle.swift"
PG = "PropertyGraph.swift"
AM = "AttachedMaps.swift"
MUTANTS += [
    # The bundle's encoded form and its checks.
    Mutant("pbversion", PB, "version == _propertyGraphBundleVersion", "version >= _propertyGraphBundleVersion"),
    Mutant("pbedgecount", PB, "values._storage.dense.count != graph._edgeMapCount", "false"),
    Mutant("pbvertexcount", PB, "values._storage.dense.count != graph._vertexMapCount", "false"),
    Mutant("pbcheck", PB, "        repeat (each maps)._checkAttached(to: graph)", "", mode="stmt"),
    Mutant("pbequalgraph", PB, "lhs.graph == rhs.graph", "true"),
    Mutant("pbequalmaps", PB, "if !mine._valuesEqual(in: lhs.graph, to: theirs, in: rhs.graph) { return false }", "", mode="stmt"),
    Mutant("pbhashmaps", PB, "        repeat (each maps)._hashValues(in: graph, into: &hasher)", "", mode="stmt"),
    Mutant("pbencodemaps", PB, "        repeat try (each maps)._encodeValues(in: graph, to: &container)", "", mode="stmt"),
    # Snapshot encoding and decoding.
    Mutant("pgencodedefault", PG, "try container.encode(defaultValue, forKey: .defaultValue)", "try container.encode(dense.first ?? defaultValue, forKey: .defaultValue)"),
    Mutant("pgencodelayout", PG, "layout == .dense", "layout != .dense", nth=0),
    Mutant("pgdecodepagesize", PG, "!page.isEmpty && page.count != _PositionPage.size", "page.count > _PositionPage.size"),
    Mutant("pgdecodefirst", PG, "firstPage >= 0", "true"),
    # Equality and hashing of snapshots.
    Mutant("pgequaldefault", PG, "guard defaultValue == other.defaultValue else { return false }", "", mode="stmt"),
    Mutant("pgequaldense", PG, "dense.elementsEqual(other.dense)", "dense.count == other.dense.count"),
    Mutant("pgequalmine", PG, "if theirs.contains(where: { $0 != defaultValue }) { return false }", "", mode="stmt"),
    Mutant("pgequaltheirs", PG, "if mine.contains(where: { $0 != defaultValue }) { return false }", "", mode="stmt"),
    Mutant("pgequalpages", PG, "!mine.elementsEqual(theirs)", "false"),
    Mutant("pgequalspan", PG, "Swift.max(firstPage &+ pages.count, other.firstPage &+ other.pages.count)", "Swift.min(firstPage &+ pages.count, other.firstPage &+ other.pages.count)"),
    Mutant("pghashdefault", PG, "        hasher.combine(defaultValue)", "", mode="stmt"),
    Mutant("pghashpaged", PG, "value != defaultValue", "value == defaultValue"),
    # Attaching from storage.
    Mutant("amaddcount", AM, "precondition(storage.dense.count == count, \"The values do not match the graph: one per position is needed\")", "", mode="stmt"),
    Mutant("amaddcopy", AM, "buffer = _DenseMapBufferOf(copying: storage.dense, default: storage.defaultValue, capacity: capacity, witnesses: witnesses)", "buffer = _DenseMapBufferOf(repeating: storage.defaultValue, count: count, capacity: capacity, witnesses: witnesses)"),
    Mutant("amadddefault", AM, "if let start = values.baseAddress { elements.initialize(from: start, count: values.count) }", "elements.initialize(repeating: value, count: values.count)", mode="stmt"),
    Mutant("amaddpaged", AM, "buffer = _PagedMapBuffer(paged, witnesses: witnesses)", "buffer = _PagedMapBuffer(_MapStorage(default: storage.defaultValue), witnesses: witnesses)"),
]
