# Planted bugs for ImplicitGraphs (the range checks, edge positions and stepping, the one-pass
# copies) and for the closure Dijkstra and A* of decision D19 in ShortestPaths
# (SuccessorFunctionSearch.swift: the lazy-deletion heap, the goal tested when settled, A*
# reopening, the weight and heuristic traps), which ImplicitGraphsTests covers. Run with
# `just mutate ImplicitGraphs`. See scripts/mutate.py.
#
# Known equivalent mutants (they survive by design): none.
#
# The tie-break mutants (heaptie, heaptiereverse, heapprecedes) change no distance; the review
# tests catch them by the expansions A* makes when equal priorities meet.

TESTS = ["ImplicitGraphsTests", "ShortestPathsTests"]

I = "ImplicitDirectedGraph.swift"
D = "ImplicitDirectedGraph+DirectedGraph.swift"
E = "ImplicitDirectedGraph+Edges.swift"
S = "SuccessorFunctionSearch.swift"
SP = "ShortestPaths"

MUTANTS = [
    # Construction and the vertex check.
    Mutant("initcount", I, "precondition(vertexCount >= 0, \"negative vertex count \\(vertexCount)\")", "", mode="stmt"),
    Mutant("check", I, "UInt(bitPattern: vertex) < UInt(bitPattern: _vertexCount)", "true"),

    # The range check of each target, as it is read.
    Mutant("rangenegative", I, "UInt(bitPattern: target) < UInt(bitPattern: _vertexCount)", "target < _vertexCount"),
    Mutant("rangehigh", I, "UInt(bitPattern: target) < UInt(bitPattern: _vertexCount)", "UInt(bitPattern: target) <= UInt(bitPattern: _vertexCount)"),

    # Out-edge positions.
    Mutant("rank", I, "Edges.Index(source: _source, rank: _rank, target: target)", "Edges.Index(source: _source, rank: 0, target: target)"),
    Mutant("ranksource", I, "Iterator(_row: _row.makeIterator(), _source: _row._source)", "Iterator(_row: _row.makeIterator(), _source: 0)"),

    # DirectedGraph reads.
    Mutant("contains", D, "UInt(bitPattern: vertex) < UInt(bitPattern: _vertexCount)", "vertex < _vertexCount"),
    Mutant("containsedgesource", D, "guard contains(edge.source), contains(edge.target) else { return false }", "guard contains(edge.target) else { return false }", mode="stmt"),
    Mutant("containsedgetarget", D, "guard contains(edge.source), contains(edge.target) else { return false }", "guard contains(edge.source) else { return false }", mode="stmt"),
    Mutant("outdegree", D, "for _ in successors(of: vertex) { count &+= 1 }", "for _ in successors(of: vertex).dropFirst() { count &+= 1 }", mode="stmt"),
    Mutant("sourceat", D, "position.source", "position.target", nth=1),
    Mutant("targetindex", D, "position.target", "position.source", nth=4),

    # Edge positions: equality and order.
    Mutant("indexeq", E, "lhs.source == rhs.source && lhs.rank == rhs.rank", "lhs.source == rhs.source"),
    Mutant("indexlt", E, "(lhs.source, lhs.rank) < (rhs.source, rhs.rank)", "lhs.source < rhs.source"),

    # Edge stepping.
    Mutant("firstskip", E, "if let target = row.next() { return Index(source: v, rank: 0, target: target) }", "if let target = row.next(), v > 0 || _vertexCount == 1 { return Index(source: v, rank: 0, target: target) }", mode="stmt"),
    Mutant("afterrank", E, "rank == i.rank &+ 1", "rank == i.rank &+ 2"),
    Mutant("afterrow", E, "_firstEdge(from: i.source &+ 1)", "_firstEdge(from: i.source &+ 2)"),
    Mutant("afterend", E, "precondition(i.source >= 0 && i.source < _vertexCount, \"Cannot advance past endIndex\")", "", mode="stmt"),
    Mutant("subscriptcheck", E, "precondition(position.source >= 0 && position.source < _vertexCount, \"Edge position out of range\")", "", mode="stmt"),
    Mutant("count", E, "            for v in 0 ..< _vertexCount {\n                for _ in _row(v) { total &+= 1 }\n            }", "            for v in 1 ..< Swift.max(_vertexCount, 1) {\n                for _ in _row(v) { total &+= 1 }\n            }", mode="stmt"),
    Mutant("iteratorsource", E, "DirectedEdge(from: _source &- 1, to: target)", "DirectedEdge(from: Swift.max(_source &- 2, 0), to: target)"),

    # _copyToContiguousArray and map: one pass, one call per vertex.
    Mutant("copyorder", E, "for edge in self { result.append(edge) }", "for edge in self { result.insert(edge, at: 0) }", mode="stmt"),
    Mutant("copybyindex", E, "for edge in self { result.append(edge) }", "for i in indices { result.append(self[i]) }", mode="stmt"),
    Mutant("mapbyindex", E, "for edge in self { result.append(try transform(edge)) }", "for i in indices { result.append(try transform(self[i])) }", mode="stmt"),

    # D19: the heap.
    Mutant("heapsift", S, "guard entry.precedes(entries[up]) else { break }", "", mode="stmt", module=SP),
    Mutant("heapparent", S, "(child - 1) / 2", "child / 2", module=SP),
    Mutant("heapchild", S, "if child + 1 < count, entries[child + 1].precedes(entries[child]) { child += 1 }", "", mode="stmt", module=SP),
    Mutant("heapsink", S, "entries[child].precedes(last)", "true", module=SP),
    Mutant("heapprecedes", S, "priority < other.priority", "priority <= other.priority", module=SP),
    Mutant("heaptie", S, "(priority == other.priority && other.distance < distance)", "false", module=SP),
    Mutant("heaptiereverse", S, "other.distance < distance", "distance < other.distance", module=SP),

    # D19: lazy deletion, goal on settle, relaxation.
    Mutant("stale", S, "guard entry.distance == distance[u] else { continue }", "", mode="stmt", module=SP),
    Mutant("goalqueued", S, "heap.push(_SearchEntry(state: v, priority: priority, distance: candidate))",
           "if success(next) {\n                var path: [V] = [next]\n                var i = u\n                while i >= 0 { path.append(states[i]); i = parent[i] }\n                return (Array(path.reversed()), candidate)\n            }\n            heap.push(_SearchEntry(state: v, priority: priority, distance: candidate))",
           mode="stmt", module=SP),
    Mutant("pathreverse", S, "path.reverse()", "", mode="stmt", module=SP),
    Mutant("relaxties", S, "candidate < distance[known]", "candidate <= distance[known]", module=SP),
    Mutant("relaxparent", S, "                parent[v] = u", "", mode="stmt", module=SP),
    Mutant("noreopen", S, "candidate < distance[known]",
           "candidate < distance[known] && (heuristic == nil || heap.entries.contains { $0.state == known && $0.distance == distance[known] })",
           module=SP),
    Mutant("noheuristic", S, "candidate + heuristic(next)", "candidate", module=SP),

    # D19: the traps.
    Mutant("weightnegative", S, "weight >= .zero", "true", module=SP),
    Mutant("weightnan", S, "weight >= .zero", "!(weight < .zero)", module=SP),
    Mutant("heuristicnanstart", S, "first == first", "true", module=SP),
    Mutant("heuristicnan", S, "priority == priority", "true", module=SP),
    Mutant("cutoffnan", S, "cutoff.map { $0 == $0 } ?? true", "true", module=SP),

    # D19: the cutoff (inclusive, on the distance alone, before the state is numbered).
    Mutant("cutoffskip", S, "if let cutoff, cutoff < candidate { continue }", "", mode="stmt", module=SP),
    Mutant("cutoffexclusive", S, "cutoff < candidate", "cutoff <= candidate", module=SP),
    Mutant("cutoffsum", S, "cutoff < candidate", "cutoff < candidate + (heuristic?(next) ?? .zero)", module=SP),


    # The checked: spellings (README Principle 6): each guard removed lets the plain spelling trap.
    Mutant("cksuccessors", D, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=0),
    Mutant("ckoutedges", D, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=1),
    Mutant("ckoutdegree", D, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=2),
    Mutant("ckvertexindex", D, "guard contains(vertex) else { throw VertexNotFound() }", "", mode="stmt", nth=3),
]
