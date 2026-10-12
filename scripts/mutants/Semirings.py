# Planted bugs for Semirings and the semiring shortest paths in ShortestPaths (Dijkstra,
# Bellman–Ford, DAG paths and distances, Floyd–Warshall, DistanceMatrix and the undirected
# overloads); run with `just mutate Semirings`. See scripts/mutate.py. The ShortestPaths mutants
# (module=...) run SemiringsTests first, then ShortestPathsTests.
#
# Known equivalent mutants (they survive by design):
#   djstop            Dijkstra's single-target search not stopping at the target: the target's
#                     distance and parent are final once popped; time only.
#   bfqueueonce       queuing an index more than once per round, in the main rounds or in the
#   hqueueonce        hidden-cycle rounds: a repeat relaxes nothing new; time only.
#   hemptyh           no early return when nothing is saturated: every loop over H is empty.
#   saturatedsigned   _isSaturated without `−∞ < .zero`: only the unsigned scalars differ (their −∞
#                     is 0, the tropical one), and no unsigned tropical distance is ever below one,
#                     so Bellman–Ford never asks.
#   dagorderzero      skipping an index at .zero in DAG paths and distances: zero annihilates, so
#   daglive           its candidates are .zero, never better and ⊕'s identity; time only.
#   fwloopskip        a loop no better than one falling through to the arc table: it cannot beat
#                     the diagonal's .one.
#   fwik              the row i == k: its candidates are .one ⊗ d[k][j], never strictly better.
#   fwzeroskip        a row at .zero through k: its candidates are .zero; time only.
#   fwempty           no early return for an empty graph: the k loop does not run, and an empty
#                     array's buffer has a base address on Darwin.
#   unindexed         an indexed undirected graph searched through the view: same answers; time.
#   unbetter          the undirected O(V + E) check for an edge better than one: without it the
#                     directed Bellman–Ford finds the 2-cycle such an edge makes (w ⊗ w ⊑ w < 1̄).
#   unnativetarget    the native undirected search not stopping at the target: as djstop.
#   dagtoindex        ShortestDistances.distance(toIndex:)'s range check: the array read traps out
#                     of range anyway; only the message differs.
#   dmsourcelow       DistanceMatrix.distance(fromIndex:toIndex:)'s source range check: with the
#   dmsourcehigh      target in range, a source out of range puts the flat index out of range,
#                     and the array read traps; only the message differs.
#   dmpathbound       DistanceMatrix.path(from:to:)'s guard against a path that does not end: only
#                     strict improvements are kept and nothing is better than .one, so the
#                     last-edge pointers never cycle.
#   unemptysources    the undirected Bellman–Ford pre-pass's checks: an empty source list or a
#   unvertex          non-vertex source traps in the directed Bellman–Ford it calls next.
#   The range checks, the path guard and the pre-pass checks stay: removing them was declined as
#   removing safety checks.
#
# Removed as dead code after planting: Bellman–Ford's `queuedIn[s] = 0` (rounds start at 1), its
# `< .one` tests before `_isSaturated` (which implies them), and the undirected single-target
# search's clearing of parents when the target is not reached (the target then has no parent).

TESTS = ["SemiringsTests", "ShortestPathsTests"]

SP = "ShortestPaths"

T = "TropicalSemiring.swift"
B = "BottleneckSemiring.swift"
O = "BooleanSemiring.swift"
C = "CountingSemiring.swift"
S = "Semiring.swift"
X = "SemiringScalar.swift"

DJ = "SemiringDijkstra.swift"
BF = "SemiringBellmanFord.swift"
DAG = "SemiringDAGShortestPaths.swift"
FW = "FloydWarshall.swift"
DM = "DistanceMatrix.swift"
UN = "SemiringUndirected.swift"

MUTANTS = [
    # The tropical semiring (min, +).
    Mutant("tropplus", T, "other.value < value ? other : self", "value < other.value ? other : self"),
    Mutant("tropzero", T, "Self(Value._semiringInfinity)", "Self(Value._semiringNegativeInfinity)"),
    Mutant("tropone", T, "Self(.zero)", "Self(Value._semiringInfinity)"),
    Mutant("troptimes", T, "Value._tropicalProduct(value, other.value)", "Value._tropicalProduct(value, value)"),
    Mutant("troplt", T, "lhs.value < rhs.value", "lhs.value <= rhs.value"),
    Mutant("troplt2", T, "lhs.value < rhs.value", "rhs.value < lhs.value"),
    Mutant("saturatedsigned", T, "Value._semiringNegativeInfinity < .zero && value == Value._semiringNegativeInfinity", "value == Value._semiringNegativeInfinity", module=None),
    Mutant("saturatedvalue", T, "Value._semiringNegativeInfinity < .zero && value == Value._semiringNegativeInfinity", "Value._semiringNegativeInfinity < .zero", module=None),
    Mutant("tropdesc", T, '"\\(value)"', '"T\\(value)"'),

    # The bottleneck semiring (max, min).
    Mutant("bplus", B, "value < other.value ? other : self", "self"),
    Mutant("btimes", B, "other.value < value ? other : self", "other"),
    Mutant("bzero", B, "Self(Value._semiringNegativeInfinity)", "Self(.zero)"),
    Mutant("bone", B, "Self(Value._semiringInfinity)", "Self(.zero)"),
    Mutant("blt", B, "rhs.value < lhs.value", "lhs.value < rhs.value"),
    Mutant("bltties", B, "rhs.value < lhs.value", "rhs.value <= lhs.value"),
    Mutant("bdesc", B, '"\\(value)"', '"B\\(value)"'),

    # The Boolean semiring (∨, ∧).
    Mutant("boolplus", O, "Self(value || other.value)", "Self(value != other.value)"),
    Mutant("booltimes", O, "Self(value && other.value)", "Self(other.value)"),
    Mutant("boolzero", O, "Self(false)", "Self(!false)"),
    Mutant("boolone", O, "Self(true)", "Self(!true)"),
    Mutant("boollt", O, "lhs.value && !rhs.value", "!lhs.value && rhs.value"),
    Mutant("booldesc", O, '"\\(value)"', '"O\\(value)"'),

    # The counting semiring (+, ×).
    Mutant("cplus", C, "Self(value + other.value)", "Self(value + value)"),
    Mutant("ctimes", C, "Self(value * other.value)", "Self(value * value)"),
    Mutant("czero", C, "Self(.zero)", "Self(1)"),
    Mutant("cone", C, "Self(1)", "Self(.zero)", nth=1),
    Mutant("cdesc", C, '"\\(value)"', '"C\\(value)"'),

    # The operators.
    Mutant("oplus", S, "lhs.plus(rhs)", "lhs.times(rhs)", nth=1),
    Mutant("otimes", S, "lhs.times(rhs)", "lhs.plus(rhs)", nth=2),

    # The scalar sentinels and the tropical product: the zero absorbs first, then -∞; other sums
    # trap on overflow.
    Mutant("floatinfinity", X, ".infinity", ".greatestFiniteMagnitude", nth=16),
    Mutant("intinfinity", X, ".max", ".max - 1", nth=3),
    Mutant("intneginfinity", X, ".min", "-Self.max", nth=3),
    Mutant("uintneginfinity", X, ".min", "1", nth=6),
    Mutant("floatneginfinity", X, "-.infinity", "-.greatestFiniteMagnitude", nth=1),
    Mutant("intabsorb", X, "        if a == .infinity || b == .infinity { return .infinity }", "", mode="stmt", nth=0),
    Mutant("uintabsorb", X, "        if a == .infinity || b == .infinity { return .infinity }", "", mode="stmt", nth=1),
    Mutant("intneg", X, "        if a == .negativeInfinity || b == .negativeInfinity { return .negativeInfinity }", "", mode="stmt"),
    Mutant("intnegfirst", X, "        if a == .infinity || b == .infinity { return .infinity }",
           "        if a == .negativeInfinity || b == .negativeInfinity { return .negativeInfinity }\n        if a == .infinity || b == .infinity { return .infinity }",
           mode="stmt", nth=0),
    Mutant("intabsorbleft", X, "a == .infinity || b == .infinity", "b == .infinity", nth=1),
    Mutant("intabsorbright", X, "a == .infinity || b == .infinity", "a == .infinity", nth=1),
    Mutant("intnegleft", X, "a == .negativeInfinity || b == .negativeInfinity", "b == .negativeInfinity", nth=1),
    Mutant("intnegright", X, "a == .negativeInfinity || b == .negativeInfinity", "a == .negativeInfinity", nth=1),
    Mutant("intwrap", X, "return a + b", "return a &+ b", mode="stmt", nth=0),
    Mutant("uintwrap", X, "return a + b", "return a &+ b", mode="stmt", nth=1),

    # Dijkstra.
    Mutant("djcutoffnan", DJ, "cutoff.map { $0 == $0 } ?? true", "true", module=SP),
    Mutant("djsourceone", DJ, "distance[s] = .one", "distance[s] = .zero", mode="stmt", module=SP),
    Mutant("djsources", DJ, "queue.insert(s, priority: .one)", "if s == sources[0] { queue.insert(s, priority: .one) }", mode="stmt", module=SP),
    Mutant("djstrict", DJ, "guard candidate < distance[v] else { continue }", "guard !(distance[v] < candidate) else { continue }", mode="stmt", module=SP),
    Mutant("djprecondition", DJ, "!(w < .one)", "true", module=SP),
    Mutant("djpreconditionone", DJ, "!(w < .one)", "w > .one", module=SP),
    Mutant("djnan", DJ, "w == w", "true", nth=0, module=SP),
    Mutant("djcutoff", DJ, "cutoff < candidate", "candidate < cutoff", module=SP),
    Mutant("djcutoffties", DJ, "cutoff < candidate", "!(candidate < cutoff)", module=SP),
    Mutant("djpriority", DJ, "queue.insertOrDecreasePriority(of: v, to: candidate)", "queue.insertOrDecreasePriority(of: v, to: du)", mode="stmt", module=SP),
    Mutant("djparentedge", DJ, "parentEdge[v] = e", "", mode="stmt", module=SP),
    Mutant("djunreached", DJ, "guard result.reachedTarget else { return nil }", "", mode="stmt", module=SP),
    Mutant("djpathreverse", DJ, "path.reverse()", "", mode="stmt", module=SP),
    Mutant("djedgesreverse", DJ, "pathEdges.reverse()", "", mode="stmt", module=SP),
    Mutant("djtargetdistance", DJ, "result.distance[t]", "result.distance[s]", module=SP),
    Mutant("djstop", DJ, "                            break", "", mode="stmt", module=SP),

    # Bellman–Ford.
    Mutant("bfsourceone", BF, "distance[s] = .one", "distance[s] = .zero", mode="stmt", module=SP),
    Mutant("bfrounds", BF, "round < n", "round < n - 1", module=SP),
    Mutant("bfstrict", BF, "guard candidate < distance[v] else { continue }", "guard !(distance[v] < candidate) else { continue }", mode="stmt", module=SP),
    Mutant("bfparentedge", BF, "parentEdge[v] = e", "", mode="stmt", module=SP),
    Mutant("bfqueueonce", BF, "queuedIn[v] != round", "true", nth=0, module=SP),
    Mutant("bfnil", BF, "guard !result.improvingCycle else { return nil }", "", mode="stmt", module=SP),
    Mutant("bfnan", BF, 'precondition(w == w, "A weight is NaN")', "", mode="stmt", module=SP),
    # Bellman–Ford's check for an improving cycle hidden behind −∞ (saturated) distances.
    Mutant("hsatguard", BF, "guard W.self is any _SaturatingSemiring.Type else { return false }", "return false", mode="stmt", module=SP),
    Mutant("hemptyh", BF, "guard k > 0 else { return false }", "", mode="stmt", module=SP),
    Mutant("hzeroarc", BF, "guard w != .zero else { continue }", "", mode="stmt", module=SP),
    Mutant("habsorbing", BF, "(w as! any _SaturatingSemiring)._isSaturated", "false", module=SP),
    Mutant("hcomponent", BF, "component[targets[a]] == component[u]", "true", module=SP),
    Mutant("hlowback", BF, "low[v] = min(low[v], order[w])", "", mode="stmt", module=SP),
    Mutant("hlowup", BF, "low[parentCall.vertex] = min(low[parentCall.vertex], low[v])", "", mode="stmt", module=SP),
    Mutant("hfinite", BF, "!absorbing[a]", "true", module=SP),
    Mutant("hstart", BF, "[W](repeating: .one, count: k)", "[W](repeating: .zero, count: k)", module=SP),
    Mutant("hrounds", BF, "round < k", "round < k - 1", module=SP),
    Mutant("hqueueonce", BF, "queuedIn[v] != round", "true", nth=1, module=SP),

    # DAG paths and distances.
    Mutant("dagties", DAG, "candidate < distance", "!(distance < candidate)", module=SP),
    Mutant("dagoverwrite", DAG, "distance = distance.plus(candidate)", "distance = candidate", mode="stmt", module=SP),
    Mutant("dagkeepparents", DAG, "        return true", "        return false", mode="stmt", module=SP),
    Mutant("dagnan", DAG, 'precondition(w == w, "A weight is NaN")', "", mode="stmt", module=SP),
    Mutant("dagsourceone", DAG, "distance[s] = .one", "distance[s] = .zero", mode="stmt", module=SP),
    Mutant("dagsourceparent", DAG, "if paths { parent[s] = -1 }", "", mode="stmt", module=SP),
    Mutant("dagorderzero", DAG, "if du == .zero { continue }", "", mode="stmt", module=SP),
    Mutant("daglive", DAG, "du != .zero", "true", module=SP),
    Mutant("dagindegree", DAG, "indegree[v] += 1", "", mode="stmt", module=SP),
    Mutant("dagreached", DAG, "!reached[v]", "true", module=SP),
    Mutant("dagkahnsources", DAG, "for s in sources where indegree[s] == 0 { queue.append(s) }", "for s in sources { queue.append(s) }", mode="stmt", module=SP),
    Mutant("dagacyclic", DAG, "queue.count == reachable", "true", module=SP),
    Mutant("dagdistinct", "ShortestPathTree.swift", "seen.insert(i).inserted", "true", module=SP),
    Mutant("dagtoindex", DAG, 'precondition(index >= 0 && index < _distance.count, "Index \\(index) is out of range 0..<\\(_distance.count)")', "", mode="stmt", module=SP),
    Mutant("dagrows", DAG, "keys.map { rows.numbers[$0] }", "Array(keys)", module=SP),
    Mutant("dagorderpaths", DAG, "_semiringOrder(ids)", "Array((0 ..< ids.count).reversed())", nth=0, module=SP),
    Mutant("dagorderdistances", DAG, "_semiringOrder(ids)", "Array((0 ..< ids.count).reversed())", nth=1, module=SP),

    # Floyd–Warshall over a selective semiring (the first engine in the file).
    Mutant("fwnan", FW, 'precondition(w == w, "A weight is NaN")', "", mode="stmt", nth=0, module=SP),
    Mutant("fwfloatvalues", FW, "result.distance.map(\\.value)", "result.distance.map { $0.value.nextUp }", module=SP),
    Mutant("fwdiagonal", FW, "for i in 0 ..< n { distance[i * n + i] = .one }", "", mode="stmt", nth=0, module=SP),
    Mutant("fwloop", FW, "if w < .one { return nil }", "", mode="stmt", module=SP),
    Mutant("fwloopskip", FW, "                    continue", "", mode="stmt", nth=0, module=SP),
    Mutant("fwparallel", FW, "w < distance[u * n + v]", "!(distance[u * n + v] < w)", nth=0, module=SP),
    Mutant("fwedge", FW, "lastEdge[u * n + v] = e", "", mode="stmt", nth=0, module=SP),
    Mutant("fwempty", FW, "guard n > 0 else { return (distance, lastEdge) }", "", mode="stmt", nth=0, module=SP),
    Mutant("fwrowk", FW, "dBase + k * n", "dBase + (k * n + n) % (n * n)", nth=0, module=SP),
    Mutant("fwlastk", FW, "lastBase + k * n", "lastBase + (k * n + n) % (n * n)", nth=0, module=SP),
    Mutant("fwrowi", FW, "dBase + i * n", "dBase + ((i + 1) % n) * n", nth=0, module=SP),
    Mutant("fwlasti", FW, "lastBase + i * n", "lastBase + ((i + 1) % n) * n", nth=0, module=SP),
    Mutant("fwik", FW, "i != k", "true", nth=0, module=SP),
    Mutant("fwdik", FW, "rowI[k]", "rowK[i]", nth=0, module=SP),
    Mutant("fwzeroskip", FW, "if dik == .zero { continue }", "", mode="stmt", module=SP),
    Mutant("fwcandidate", FW, "dik.times(rowK[j])", "dik.times(rowI[j])", module=SP),
    Mutant("fwstrict", FW, "candidate < rowI[j]", "!(rowI[j] < candidate)", nth=0, module=SP),
    Mutant("fwpredecessor", FW, "lastI[j] = lastK[j]", "", mode="stmt", nth=0, module=SP),
    Mutant("fwcycle", FW, "if rowI[i] < .one { return true }", "", mode="stmt", module=SP),

    # DistanceMatrix.
    Mutant("dmsourcelow", DM, "sourceIndex >= 0 && sourceIndex < _count", "sourceIndex < _count", module=SP),
    Mutant("dmsourcehigh", DM, "sourceIndex >= 0 && sourceIndex < _count", "sourceIndex >= 0", module=SP),
    Mutant("dmtargetlow", DM, "targetIndex >= 0 && targetIndex < _count", "targetIndex < _count", module=SP),
    Mutant("dmtargethigh", DM, "targetIndex >= 0 && targetIndex < _count", "targetIndex >= 0", module=SP),
    Mutant("dmdiagonal", DM, "sourceIndex == targetIndex || _lastEdge[k] != _placeholder", "_lastEdge[k] != _placeholder", module=SP),
    Mutant("dmunreached", DM, "sourceIndex == targetIndex || _lastEdge[k] != _placeholder", "true", module=SP),
    Mutant("dmhaspathdiagonal", DM, "i == j || _lastEdge[i * _count + j] != _placeholder", "_lastEdge[i * _count + j] != _placeholder", module=SP),
    Mutant("dmhaspathunreached", DM, "i == j || _lastEdge[i * _count + j] != _placeholder", "true", module=SP),
    Mutant("dmpathdiagonal", DM, "i == j || _lastEdge[row + j] != _placeholder", "_lastEdge[row + j] != _placeholder", module=SP),
    Mutant("dmpathunreached", DM, "i == j || _lastEdge[row + j] != _placeholder", "true", module=SP),
    Mutant("dmpathbound", DM, 'precondition(edges.count < _count, "A Floyd–Warshall path does not end")', "", mode="stmt", module=SP),
    Mutant("dmpathverticesreverse", DM, "vertices.reverse()", "", mode="stmt", module=SP),
    Mutant("dmpathedgesreverse", DM, "edges.reverse()", "", mode="stmt", module=SP),

    # The undirected overloads.
    Mutant("uncutoffnan", UN, "cutoff.map { $0 == $0 } ?? true", "true", module=SP),
    Mutant("unindexed", UN, "guard vertexIndexBound != nil else { return nil }", "return nil", mode="stmt", module=SP),
    Mutant("unorient", UN, "_orientParentEdges(result.parent, &result.parentEdge)", "", mode="stmt", module=SP),
    Mutant("unbetter", UN, "if weight(e) < .one { return true }", "", mode="stmt", module=SP),
    Mutant("unbetterties", UN, "weight(e) < .one", "weight(e) <= .one", module=SP),
    Mutant("unemptysources", UN, 'precondition(!sources.isEmpty, "A shortest-path search needs at least one source")', "", mode="stmt", module=SP),
    Mutant("unvertex", UN, 'precondition(contains(s), "\\(s) is not a vertex")', "", mode="stmt", module=SP),
    Mutant("unnativetarget", UN, "target.map { view._index(of: $0, ids) } ?? -1", "-1", module=SP),
]
