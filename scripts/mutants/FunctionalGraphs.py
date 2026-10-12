# Planted bugs for FunctionalGraphs: the decomposition's build passes and queries (the cycle
# rotation and the level-ancestor search), successor(of:steps:) on the graph, Floyd's and Brent's
# cycle detection (results and exact call counts), construction and decoding checks. Run with
# `just mutate FunctionalGraphs`. See scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   dcheck   the decomposition's vertex check: every query then reads _records[vertex] or
#            _preimageStarts[vertex + 1] first, an array read that traps on a non-vertex anyway;
#            only the message differs.
#   gsteps   the graph's negative-steps check: a negative count takes the walking branch, whose
#            range 0 ..< steps traps on its own; only the message differs.
#
# p4countreset (a depth count not reset before counting) reads memory the build never wrote, so
# it is caught only when the allocator hands back dirty memory; FunctionalGraphRebuildTests
# dirties it on purpose, and it was caught in every run since.
#
# Removed after planting: returning the hare rather than the tortoise from Floyd's third lap (the
# lap ends when they are equal).

TESTS = ["FunctionalGraphsTests"]

D = "CycleDecomposition.swift"
C = "CycleDetection.swift"
F = "FunctionalGraph.swift"
G = "FunctionalGraph+DirectedGraph.swift"
K = "FunctionalGraph+Conformances.swift"

MUTANTS = [
    # Decomposition queries.
    Mutant("dcheck", D, "UInt(bitPattern: vertex) < UInt(bitPattern: _records.count)", "true"),
    Mutant("dcomponent", D, "record.tail == 0 ? record.root : _records[record.root].root", "record.root"),
    Mutant("droot", D, "record.tail == 0 ? vertex : record.root", "record.root"),
    Mutant("dcyclelength", D, "_cycleStarts[c + 1] - _cycleStarts[c]", "_cycleStarts[c + 1] - _cycleStarts[0]"),
    Mutant("dindegree", D, "_preimageStarts[vertex + 1] - _preimageStarts[vertex]", "Swift.max(_preimageStarts[vertex + 1] - _preimageStarts[vertex], 1)"),
    Mutant("dpreimages", D, "_preimages[_preimageStarts[vertex] ..< _preimageStarts[vertex + 1]]", "_preimages[_preimageStarts[vertex] ..< Swift.max(_preimageStarts[vertex], _preimageStarts[vertex + 1] - 1)]"),
    Mutant("dsteps", D, "precondition(steps >= 0, \"negative step count \\(steps)\")", "", mode="stmt"),

    # The level-ancestor search (steps below the tail length).
    Mutant("lacutoff", D, "steps < tail", "steps < tail - 1"),
    Mutant("lacutoffhigh", D, "steps < tail", "steps <= tail && tail > 0", nth=1),
    Mutant("lakey", D, "keys[middle] <= key", "keys[middle] < key"),
    Mutant("lawidth", D, "high &- low > 1", "high &- low > 2"),
    Mutant("lahigh", D, "_depthStarts[depth + 1]", "_depthStarts[depth + 1] - 1"),
    Mutant("ladepth", D, "tail - steps", "Swift.max(tail - steps - 1, 1)"),

    # The cycle rotation (steps at or past the tail length).
    Mutant("rotroot", D, "tail == 0 ? record : _records[record.root]", "record"),
    Mutant("rotouter", D, "(root.key - start + (steps - tail) % length) % length", "(root.key + (steps - tail) % length) % length"),
    Mutant("rotnomod", D, "(root.key - start + (steps - tail) % length) % length", "Swift.min(root.key - start + (steps - tail) % length, length - 1)"),
    Mutant("rotinner", D, "(steps - tail) % length", "steps % length", nth=2),

    # Pass 1: in-degrees, peeling states, leaves, preimage rows.
    Mutant("p1size", D, "Node(remaining: Int32(truncatingIfNeeded: degree), size: 1, successor: successor)", "Node(remaining: Int32(truncatingIfNeeded: degree), size: 2, successor: successor)"),
    Mutant("p1leafsize", D, "Entry(vertex: Int32(truncatingIfNeeded: w), successor: successor, size: 1)", "Entry(vertex: Int32(truncatingIfNeeded: w), successor: successor, size: 2)"),
    Mutant("p1leaf", D, "degree == 0 ? 1 : 0", "degree <= 1 ? 1 : 0"),
    Mutant("p1prefix", D, "starts[w] = sum", "starts[w] = sum &- degree", mode="stmt"),
    Mutant("p1end", D, "starts[n] = n", "starts[n] = Swift.max(n - 1, 0)", mode="stmt"),
    Mutant("p1order", D, "rows[starts[w]] = v", "rows[starts[w]] = n &- 1 &- v", mode="stmt"),

    # Pass 2: the branchless peel, subtree sizes.
    Mutant("p2size", D, "state.size &+= entry.size", "", mode="stmt"),
    Mutant("p2enqueue", D, "state.remaining &- 1", "state.remaining &- 2"),
    Mutant("p2entrysize", D, "Entry(vertex: entry.successor, successor: state.successor, size: state.size)", "Entry(vertex: entry.successor, successor: state.successor, size: entry.size)"),

    # Pass 3: the cycles, and each root's run of preorder numbers.
    Mutant("p3least", D, "node[w].remaining > 0", "node[w].remaining > 0 && w != 0"),
    Mutant("p3clear", D, "node[x].remaining = 0", "", mode="stmt"),
    Mutant("p3key", D, "Record(_tail: 0, _root: component, _key: Int32(truncatingIfNeeded: placed))", "Record(_tail: 0, _root: component, _key: 0)"),
    Mutant("p3last", D, "keysByDepth[placed] = base &+ state.size &- 2", "keysByDepth[placed] = base &+ state.size &- 1", mode="stmt"),
    Mutant("p3base", D, "base &+= state.size &- 1", "base &+= state.size", mode="stmt"),

    # Pass 4: depth, root and preorder number, parents first, numbers from the end of each run.
    Mutant("p4cyclicnext", D, "keysByDepth[Int(parent._key)] = last &- entry.size", "keysByDepth[Int(parent._key)] = last &- 1", mode="stmt"),
    Mutant("p4treenext", D, "records[p]._key = last &- entry.size", "", mode="stmt"),
    Mutant("p4treeroot", D, "root = parent._root", "root = entry.successor", mode="stmt"),
    Mutant("p4root", D, "root = entry.successor", "root = parent._root", mode="stmt", nth=0),
    Mutant("p4depth", D, "parent._tail &+ 1", "Swift.max(parent._tail, 1)"),
    Mutant("p4number", D, "last &- entry.size &+ 1", "last &- entry.size"),
    Mutant("p4key", D, "Record(_tail: depth, _root: root, _key: last)", "Record(_tail: depth, _root: root, _key: number)"),
    Mutant("p4count", D, "keysByDepth[cyclic &+ Int(depth) &- 1] &+= 1", "keysByDepth[cyclic] &+= 1", mode="stmt"),
    Mutant("p4countreset", D, "keysByDepth[cyclic &+ Int(deepest)] = 0", "", mode="stmt"),

    # Pass 5: the counting sort by depth.
    Mutant("p5prefix", D, "depthStarts[d] &+= depthStarts[d &- 1]", "if d > 2 { depthStarts[d] &+= depthStarts[d &- 1] }", mode="stmt"),
    Mutant("p5keys", D, "keysByDepth[cursor[depth]] = Int32(truncatingIfNeeded: number)", "keysByDepth[cursor[depth]] = vertex.vertex", mode="stmt"),

    # successor(of:steps:) on the graph.
    Mutant("gcheck", F, "UInt(bitPattern: vertex) < UInt(bitPattern: _successors.count)", "true"),
    Mutant("gsteps", F, "precondition(steps >= 0, \"negative step count \\(steps)\")", "", mode="stmt"),
    Mutant("gwalk", F, "steps <= f.count", "steps <= 0"),
    Mutant("gbrentreset", F, "cycleLength = 0", "cycleLength = 1", mode="stmt"),
    Mutant("gbrentlead", F, "for _ in 0 ..< cycleLength { hare = f[hare] }", "for _ in 1 ..< cycleLength { hare = f[hare] }", mode="stmt"),
    Mutant("gbrenttail", F, "tailLength &+= 1", "", mode="stmt"),
    Mutant("gbrentrest", F, "(steps - tailLength) % cycleLength", "steps % cycleLength"),

    # Construction checks.
    Mutant("initrange", F, "precondition(UInt(bitPattern: w) < UInt(bitPattern: n), \"successor \\(w) of \\(v) is not a vertex (0..<\\(n))\")", "", mode="stmt"),
    Mutant("initclosure", F, "precondition(UInt(bitPattern: w) < UInt(bitPattern: vertexCount), \"successor \\(w) of \\(v) is not a vertex (0..<\\(vertexCount))\")", "", mode="stmt"),
    Mutant("initindexed", F, "row.next() == nil", "true", nth=0),
    Mutant("initunindexed", F, "row.next() == nil", "true", nth=1),
    Mutant("initorder", F, "for (i, v) in graph.vertices.enumerated() { number[v] = i }", "for (i, v) in graph.vertices.reversed().enumerated() { number[v] = i }", mode="stmt"),
    Mutant("decoderange", K, "UInt(bitPattern: w) >= UInt(bitPattern: n)", "false"),

    # DirectedGraph reads.
    Mutant("edgesubscript", G, "DirectedEdge(from: position, to: _successors[position])", "DirectedEdge(from: _successors[position], to: position)"),
    Mutant("containsedge", G, "contains(edge.source) && _successors[edge.source] == edge.target", "_successors[edge.source] == edge.target"),
    Mutant("sourcecheck", G, "        _check(position)\n        return position", "        return position", mode="stmt"),

    # Floyd: results and call counts.
    Mutant("floydstart", C, "f(f(start))", "f(start)"),
    Mutant("floydextra", C, "        tortoise = f(tortoise)\n        hare = f(f(hare))", "        _ = f(tortoise)\n        tortoise = f(tortoise)\n        hare = f(f(hare))", mode="stmt"),
    Mutant("floydrewind", C, "        tortoise = f(tortoise)\n        hare = f(hare)\n        tailLength += 1", "        tortoise = f(tortoise)\n        hare = f(f(hare))\n        tailLength += 1", mode="stmt", nth=0),
    Mutant("floydtail", C, "tailLength += 1", "", mode="stmt", nth=1),
    Mutant("floydlap", C, "hare = f(tortoise)", "hare = f(f(tortoise))", mode="stmt"),
    Mutant("floydlapcalls", C, "hare = f(tortoise)", "hare = { _ = f(tortoise); return f(tortoise) }()", mode="stmt"),

    # Brent: results and call counts.
    Mutant("brentpower", C, "power *= 2", "power *= 3", mode="stmt"),
    Mutant("brentreset", C, "            cycleLength = 0", "            cycleLength = 1", mode="stmt"),
    Mutant("brentteleport", C, "            tortoise = hare", "", mode="stmt"),
    Mutant("brentlead", C, "for _ in 0 ..< cycleLength { hare = f(hare) }", "for _ in 0 ..< cycleLength + 1 { hare = f(hare) }", mode="stmt"),
    Mutant("brenttail", C, "tailLength += 1", "", mode="stmt", nth=2),
    Mutant("brentextra", C, "        hare = f(hare)\n        cycleLength += 1", "        _ = f(hare)\n        hare = f(hare)\n        cycleLength += 1", mode="stmt", nth=1),


    # The checked: spellings (README Principle 6): each guard removed lets the plain spelling trap.
    Mutant("cksuccessor", F, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=0),
    Mutant("cksteps", F, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=1),
    Mutant("cksuccessors", G, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=0),
    Mutant("ckoutedges", G, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=1),
    Mutant("ckoutdegree", G, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=2),
    Mutant("ckvertexindex", G, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=3),
    Mutant("cksource", G, "guard contains(position) else { throw EdgeNotFound() }", "", mode="stmt", nth=0),
    Mutant("cktarget", G, "guard contains(position) else { throw EdgeNotFound() }", "", mode="stmt", nth=1),
]
