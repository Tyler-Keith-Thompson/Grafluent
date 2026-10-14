# Planted bugs for IsomorphismModule; run with `just mutate IsomorphismModule`. See
# scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   Shortcuts and fallbacks that only save time; the search that follows gives the same answer.
#     problemedges, problemsubcount, problemsubedges, problemcoloroff  the counting shortcuts of
#                       a problem (unequal counts never match anyway); directedrowsfast reads the
#                       same rows the slow way; budgetzero, budgetnone, budgetfailures,
#                       componentsskip, componentscount, componentssizes, canonicalreuse: the
#                       joint search, the component split and the canonical labelings each decide
#                       every pair, so giving up sooner, later or never, or skipping a pre-check,
#                       changes only the time.
#   Pruning and search order (VF2++ and the refinement searches find the same mappings, in an
#   order the API does not pin).
#     branchu, branchsort, searchcandidates (memory only), orderroot, orderfrequency,
#     orderparentnone, bitsoff, feasoutdegree, feasindegree, cutfree, cutcoloroff,
#     cutcolortargetrepeat and cutcolorresett (they prune less), skipfirst (Hopcroft's rule may
#     skip any one fragment), smallestbreak, smallestlargest, largestsmallest, smallestany,
#     autotarget (any target cell chosen by a label-invariant rule), autoabsorbroot (an orbit's
#     root need not be its least vertex: every orbit still has its root searched),
#     autoabsorbonce, autojumpback, autojumpbackbest, autosimpleoff.
#     skiplargestall (queueing the largest fragment too: Hopcroft's skip bounds the work, not
#     the result).
#   Checks that cannot fail.
#     startbalance       the two halves of the union have equal size, so the one-class start is
#                        always balanced.
#     startabandon, splitstop   after a failed start or split the queue is dropped anyway.
#     enqueuetwice       enqueue is only called on a cell that is not queued (a new cell, or a
#                        fragment of a split whose cell was not queued).
#     indivsidecount     u is in G and x in H, so the new pair always holds one G vertex.
#     splitkeptbalance   the cell was balanced, so balanced groups leave a balanced kept part.
#     splitgroupbalance  (not proven) an unbalanced group goes on as a splitter that touches more
#                        of one graph than the other, so some touched cell's untouched part is
#                        unbalanced and fails; or as a target cell with no H vertex, which has no
#                        candidates. No input found where it changes an answer.
#     countsingleton, splitnothing   a cell that does not split stays as it is.
#     imageindex         the array subscript traps on the same indices.
#     segmentmonocount   a run of the target too short for the pattern's colours fails the
#                        sub-multiset walk that follows.
#     sortspan           any span above every colour id keeps the (neighbour, colour) keys unique.
#     simpleloops        an undirected loop is listed twice in its row, so the graph is not
#                        simple anyway; a directed loop has multiplicity one, as the bit matrix
#                        records it.
#     unionin            refining by out-arcs alone still makes a discrete leaf preserve every
#                        arc; the in-arcs only prune sooner.
#     searchcheck, leafrowlength, leafcolor, leafplain, autocolors   the leaf and automorphism
#                        checks: an equitable discrete partition (and two leaves with equal
#                        traces) already give an isomorphism, unless two different multisets of
#                        64-bit colour weights or traces collide; the checks guard against that.
#     autobestgamma      the automorphism between two equal canonical leaves is also found as
#                        an automorphism to the first leaf on the same path.
#   The canonical choice: any label-invariant rule picks a canonical leaf.
#     checkbestorder (the least instead of the greatest), checkbestlonger, checkendbest,
#     checkendfirst, checkstartbest, checkstartcanonical (each also follows from the next event's
#     comparison), autobestorder, canonicalcount (the certificate's length already fixes n),
#     traceindividualize, tracesplitter, tracecellcount, tracesplitcell, tracesplitkey,
#     tracegroup (a weaker trace is still label-invariant; the certificate decides).
#     certlength         (not proven) without each row's length, two certificates could be equal
#                        only if two graphs' canonical leaves interleaved the colour entries and
#                        rows exactly; no such pair found.
#   Hash quality, never equality.
#     wlmixa, wlmixb, wlmixboth, wlmultisetboth, wlmix, wldegree, wlcount, wlinitial, wlround,
#     wledgecolorplain.
#   Graph edit distance.
#     lsapedeletion      every deletion column open to every row: a row deleted in another row's
#                        column costs the same, and rowMate reads any deletion column as -1.
#     childprune         descending into a child whose bound reaches the best cost only spends
#                        time: no leaf below it can be recorded (the leaf rechecks the bound).
#   The result.
#     chainkeep          redundant generators leave every basic orbit, and the order, as it is.
#     grouporbitroot     orbits are numbered by their first vertex whatever the root.
#     productsticky      the sticky bit only matters at an exact rounding tie.

TESTS = ["IsomorphismTests"]

P = "PartitionRefinement.swift"
R = "RefinementSearch.swift"
S = "SubgraphSearch.swift"
G = "IndexGraph.swift"
W = "WeisfeilerLehman.swift"
I = "Isomorphism.swift"
MG = "Matching+Graph.swift"
MD = "Matching+DirectedGraph.swift"
A = "AutomorphismSearch.swift"
AG = "AutomorphismGroup.swift"
ES = "EditDistanceSearch.swift"
EP = "EditPath.swift"

MUTANTS = [
    # The union of G and H, and edge-colour weights.

    # start(colors:): the colour classes and their balance.
    Mutant("startside", P, "sideCount[0] = graph.half < n ? graph.half : n", "sideCount[0] = n"),
    Mutant("startbalance", P, "!graph.balanced || 2 * sideCount[0] == n", "true"),
    Mutant("startclassside", P, "for p in s ..< s + length where elements[p] < graph.half { side += 1 }", "for p in s ..< s + length where elements[p] <= graph.half { side += 1 }", mode="stmt"),
    Mutant("startclassbalance", P, "if graph.balanced && 2 * side != length { ok = false }", "", mode="stmt"),
    Mutant("startabandon", P, "if !ok { abandonQueue() }", "", mode="stmt"),
    Mutant("startqueue", P, "            enqueue(s)", "", mode="stmt"),

    # The queue.
    Mutant("enqueuetwice", P, "if inQueue[cell] { return }", "", mode="stmt"),
    Mutant("abandonflag", P, "            inQueue[queue[queueHead]] = false", "", mode="stmt"),
    Mutant("refineflag", P, "            inQueue[s] = false", "", mode="stmt"),
    Mutant("refineabandon", P, "                    abandonQueue()\n                    return false", "                    return false", mode="stmt"),

    # individualize(_:_:).
    Mutant("indivqueue", P, "        cellCount += 1\n        enqueue(s)", "        cellCount += 1", mode="stmt", nth=0),
    Mutant("indivtrail", P, "        trail[trailCount] = s\n        trailCount += 1", "", mode="stmt", nth=0),
    Mutant("indivside", P, "        sideCount[c] -= side", "", mode="stmt", nth=0),
    Mutant("indivsidecount", P, "(u < graph.half ? 1 : 0) + (x < graph.half ? 1 : 0)", "1"),

    # The undo trail.
    Mutant("undoside", P, "            sideCount[previous] += sideCount[s]", "", mode="stmt"),
    Mutant("undocount", P, "            cellCount -= 1", "", mode="stmt"),
    Mutant("undoprevious", P, "cellOf[elements[s - 1]]", "cellOf[elements[s]]"),

    # Counting (unweighted, then weighted).
    Mutant("countmulti", P, "counts[v] &+= 1", "counts[v] &+= 0"),
    Mutant("countsingleton", P, "if cellEnd - c == 1 { continue }", "", mode="stmt", nth=0),
    Mutant("countweightfirst", P, "counts[v] = weight", "counts[v] = 1"),
    Mutant("countweight", P, "counts[v] &+= weight", "counts[v] &+= 1"),
    Mutant("countmark", P, "markCount[c] = marked + 1", "markCount[c] = marked", nth=0),

    # splitTouched and splitCell: the splitter, skip-largest, the per-graph cell balance check.
    Mutant("splitreset", P, "            markCount[c] = 0", "", mode="stmt"),
    Mutant("splitstop", P, "if ok && !splitCell(c, marked) { ok = false }", "if !splitCell(c, marked) { ok = false }", mode="stmt"),
    Mutant("splitnothing", P, "if marked == length && low == high { return true }", "", mode="stmt"),
    Mutant("splitnosort", P, "if low != high { sortByCount(first, end) }", "", mode="stmt"),
    Mutant("splitkeptgroup", P, "while keptEnd < end && counts[elements[keptEnd]] == low { keptEnd += 1 }", "", mode="stmt"),
    Mutant("splitgroupside", P, "                if v < half { side += 1 }", "                if v <= half { side += 1 }", mode="stmt"),
    Mutant("splitgroupbalance", P, "if 2 * side != groupLength { balanced = false }", "", mode="stmt"),
    Mutant("splitkeptbalance", P, "if 2 * keptSide != keptEnd - c { balanced = false }", "", mode="stmt"),
    Mutant("splitkeptside", P, "            keptSide -= side", "", mode="stmt"),
    Mutant("splitqueued", P, "                enqueue(groupStart)", "", mode="stmt"),
    Mutant("skiplargestall", P, "if s != largest { enqueue(s) }", "enqueue(s)", mode="stmt"),
    Mutant("skiptwo", P, "if s != largest { enqueue(s) }", "if s != largest && s != c { enqueue(s) }", mode="stmt"),
    Mutant("skipfirst", P, "groupLength > largestLength", "false"),
    Mutant("splitbalanced", P, "balanced || !graph.balanced", "true"),
    Mutant("sortpositions", P, "for p in from ..< to { position[elements[p]] = p }", "", mode="stmt"),
    Mutant("sortinsertion", P, "counts[elements[j - 1]] > key", "counts[elements[j - 1]] < key"),

    # The search: branching on the smallest cell, the leaf.
    Mutant("searchcolors", R, "g.vertexColors.isEmpty ? [] : g.vertexColors + h.vertexColors", "[]"),
    Mutant("searchundo", R, "            partition.undo(to: levels[d].mark)", "", mode="stmt"),
    Mutant("searchprune", R, "if !partition.refine() { continue }", "_ = partition.refine()", mode="stmt"),
    Mutant("searchcandidates", R, "                candidates.removeLast(levels[d].end - levels[d].start)", "", mode="stmt"),
    Mutant("branchu", R, "if v < u { u = v }", "u = v", mode="stmt"),
    Mutant("branchside", R, "v < n", "v <= n"),
    Mutant("branchsort", R, "            slice.sort()", "", mode="stmt"),
    Mutant("leafpair", R, "(a == g ? b : a) - n", "(a == g ? a : b) - n"),

    # VF2++ order.
    Mutant("orderroot", S, "fv < fr || (fv == fr && degree[v] > degree[root])", "false"),
    Mutant("orderfrequency", S, "                    frequency[color(v)] -= 1", "", mode="stmt"),
    Mutant("orderparentself", S, "if depthOf[w] < d && (best < 0 || depthOf[w] < depthOf[best]) { best = w; inward = false }", "if depthOf[w] <= d && (best < 0 || depthOf[w] < depthOf[best]) { best = w; inward = false }", mode="stmt"),
    Mutant("orderinward", S, "best = w; inward = true", "best = w; inward = false", mode="stmt"),
    Mutant("orderparentnone", S, "            parent[d] = best", "            parent[d] = -1", mode="stmt"),

    # VF2++ bit-matrix adjacency.
    Mutant("bitsset", S, "b[x * words + y >> 6] |= 1 << UInt64(y & 63)", "b[x * words + y >> 6] |= 1 << UInt64((y + 1) & 63)", mode="stmt"),
    Mutant("bitsoff", S, "simple && nt > 0 && nt <= 4096", "false"),
    Mutant("bitsdirection", S, "outward ? (x, y) : (y, x)", "(x, y)"),
    Mutant("bitsword", S, "bits[a * words + b >> 6]", "bits[a * words]"),
    Mutant("simpleloops", G, "if w == v || w == previous { return false }", "if w == previous { return false }", mode="stmt"),
    Mutant("simpleparallel", G, "if w == v || w == previous { return false }", "if w == v { return false }", mode="stmt"),
    Mutant("simplecolors", G, "        if hasEdgeColors { return false }", "", mode="stmt"),

    # VF2++ candidates and the search loop.
    Mutant("candrepeat", S, "if k > offsets[y] && targets[k - 1] == x { return -1 }", "", mode="stmt"),
    Mutant("candmapped", S, "return core2[x] < 0 ? x : -1", "return x", mode="stmt"),
    Mutant("candinward", S, "parentInward[d] ? t.inOffsets : t.outOffsets", "t.outOffsets", nth=0),
    Mutant("resumeunmap", S, "            unmap(order[depth])", "", mode="stmt", nth=0),

    # VF2++ feasibility.
    Mutant("feascolor", S, "if let pc = p.vertexColors, pc[u] != t.vertexColors![x] { return false }", "", mode="stmt"),
    Mutant("feasoutdegree", S, "if t.outOffsets[x + 1] - t.outOffsets[x] < p.outOffsets[u + 1] - p.outOffsets[u] { return false }", "", mode="stmt"),
    Mutant("feasindegree", S, "if p.isDirected && t.inOffsets[x + 1] - t.inOffsets[x] < p.inOffsets[u + 1] - p.inOffsets[u] { return false }", "", mode="stmt"),
    Mutant("feasinrows", S, "if p.isDirected && !relationHolds(u, x, p.inOffsets, p.inTargets, p.inColors, t.inOffsets, t.inTargets, t.inColors, outward: false) { return false }", "", mode="stmt"),
    Mutant("feasloop", S, "if !segmentHolds(k, ke, pc, x, x, to, tt, tc, outward) { return false }", "", mode="stmt"),
    Mutant("feasmapped", S, "if !segmentHolds(k, ke, pc, x, y, to, tt, tc, outward) { return false }", "", mode="stmt"),
    Mutant("feaspatternmapped", S, "patternMapped += ke - k", "patternMapped += 1"),
    Mutant("feastargetmapped", S, "targetMapped += ke - k", "targetMapped += 1"),
    Mutant("inducedoff", S, "induced && (targetMapped != patternMapped || (targetLoop && !patternLoop))", "false"),
    Mutant("inducedmapped", S, "targetMapped != patternMapped || (targetLoop && !patternLoop)", "targetLoop && !patternLoop"),
    Mutant("inducedloop", S, "targetMapped != patternMapped || (targetLoop && !patternLoop)", "targetMapped != patternMapped"),

    # VF2++ cutting rules.
    Mutant("cutfree", S, "if patternFree > targetFree { return false }", "", mode="stmt"),
    Mutant("cutfreestrict", S, "if patternFree > targetFree { return false }", "if patternFree >= targetFree && patternFree > 0 { return false }", mode="stmt"),
    Mutant("cutcoloroff", S, "w != u && core1[w] < 0 && balance[pv[w]] > 0", "false"),
    Mutant("cutcolortarget", S, "if y != x && core2[y] < 0 && (k == ts || tt[k - 1] != y) { balance[tv[y]] -= 1 }", "", mode="stmt"),
    Mutant("cutcolorfreeonly", S, "if w != u && core1[w] < 0 && (k == ps || pt[k - 1] != w) { balance[pv[w]] += 1 }", "if w != u && (k == ps || pt[k - 1] != w) { balance[pv[w]] += 1 }", mode="stmt"),
    Mutant("cutcolorrepeat", S, "w != u && core1[w] < 0 && (k == ps || pt[k - 1] != w)", "w != u && core1[w] < 0"),
    Mutant("cutcolortargetrepeat", S, "y != x && core2[y] < 0 && (k == ts || tt[k - 1] != y)", "y != x && core2[y] < 0"),
    Mutant("cutcolorresetp", S, "if w != u && core1[w] < 0 { balance[pv[w]] = 0 }", "", mode="stmt"),
    Mutant("cutcolorresett", S, "if y != x && core2[y] < 0 { balance[tv[y]] = 0 }", "", mode="stmt"),

    # Induced versus monomorphism comparisons on runs of parallel edges.
    Mutant("segmentsearch", S, "if tt[mid] < y { low = mid + 1 } else { high = mid }", "if tt[mid] <= y { low = mid + 1 } else { high = mid }", mode="stmt"),
    Mutant("segmentinduced", S, "induced ? needed == available : needed <= available", "needed <= available"),
    Mutant("segmentmono", S, "induced ? needed == available : needed <= available", "needed == available"),
    Mutant("segmentcolorcount", S, "            if needed != available { return false }", "", mode="stmt"),
    Mutant("segmentcolorequal", S, "for j in 0 ..< needed where pc[k + j] != tc[low + j] { return false }", "", mode="stmt"),
    Mutant("segmentmonocount", S, "        if needed > available { return false }", "", mode="stmt"),
    Mutant("segmentsubreuse", S, "            i += 1\n            j += 1", "            i += 1", mode="stmt"),
    Mutant("segmentsubskip", S, "while j < segmentEnd && tc[j] < pc[i] { j += 1 }", "while j < segmentEnd && tc[j] <= pc[i] { j += 1 }", mode="stmt"),

    # Index graphs.
    Mutant("sortspan", G, "(outColors.max() ?? 0) + 1", "(outColors.max() ?? 0) + 2"),
    Mutant("sortcolorless", G, "                        row.sort()", "", mode="stmt"),
    Mutant("sortcolored", G, "                            keys.sort()", "", mode="stmt"),
    Mutant("inrowcolors", G, "if hasEdgeColors { colors[fill[t]] = outColors[k] }", "", mode="stmt"),
    Mutant("undirectedback", G, "sources.append(b); targets.append(a); colors.append(edgeColors[k])", "sources.append(a); targets.append(b); colors.append(edgeColors[k])", mode="stmt"),
    Mutant("directedrowsfast", G, "numbers == nil", "false"),

    # Problems: the counting shortcuts, the kind.
    Mutant("problemcount", I, "pattern.count != target.count || pattern.edgeCount != target.edgeCount", "pattern.edgeCount != target.edgeCount"),
    Mutant("problemedges", I, "pattern.count != target.count || pattern.edgeCount != target.edgeCount", "pattern.count != target.count"),
    Mutant("problemsubcount", I, "pattern.count > target.count || pattern.edgeCount > target.edgeCount", "pattern.edgeCount > target.edgeCount"),
    Mutant("problemsubedges", I, "pattern.count > target.count || pattern.edgeCount > target.edgeCount", "pattern.count > target.count"),
    Mutant("problemcolorbalance", I, "                for c in target.vertexColors { balance[c] -= 1 }", "", mode="stmt"),
    Mutant("problemcoloroff", I, "impossible = balance.contains { $0 > 0 }", "impossible = false", mode="stmt"),
    Mutant("probleminduced", I, "kind == .subgraphIsomorphism", "kind != .subgraphIsomorphism"),
    Mutant("iteratorcopy", I, "if !isKnownUniquelyReferenced(&search) { search = search.copy() }", "", mode="stmt"),
    Mutant("preimage", I, "imageIndices.firstIndex(of: t)", "imageIndices.firstIndex(of: t).map { _ in 0 }", nth=0),
    Mutant("imageindex", I, "precondition(index >= 0 && index < imageIndices.count, \"\\(index) is not a vertex index of the pattern\")", "", mode="stmt"),
    Mutant("equality", I, "lhs.imageIndices == rhs.imageIndices", "lhs.imageIndices.count == rhs.imageIndices.count"),

    # Weisfeiler–Leman.
    Mutant("wlinrows", W, "if g.isDirected { g.buildInRows() }", "", mode="stmt"),
    Mutant("wledgecolors", W, "if colored { key = _mix(key ^ _mix(UInt64(bitPattern: Int64(edgeColors[k])) &+ seed)) }", "", mode="stmt"),
    Mutant("wledgecolorplain", W, "key = _mix(key ^ _mix(UInt64(bitPattern: Int64(edgeColors[k])) &+ seed))", "key = key ^ UInt64(bitPattern: Int64(edgeColors[k]))", mode="stmt"),
    Mutant("wlmixboth", W, "                                        a &+= _mix(key ^ seed)\n                                        b &+= _mix(key &+ 0x9E37_79B9_7F4A_7C15 ^ seed)", "                                        a &+= key\n                                        b &+= key &* key", mode="stmt"),
    Mutant("wlmultisetboth", W, "        a &+= _mix(key ^ seed)\n        b &+= _mix(key &+ 0x9E37_79B9_7F4A_7C15 ^ seed)", "        a &+= key\n        b &+= key &* key", mode="stmt"),
    Mutant("wlmixa", W, "a &+= _mix(key ^ seed)", "a &+= key", nth=0, mode="stmt"),
    Mutant("wlmixb", W, "b &+= _mix(key &+ 0x9E37_79B9_7F4A_7C15 ^ seed)", "b &+= key", nth=0, mode="stmt"),
    Mutant("wlmix", W, "    return z ^ (z >> 31)", "    return z", mode="stmt"),
    Mutant("wldirection", W, "                                        hasher.combine(next[v])", "                                        hasher.combine(colors[v])", mode="stmt"),
    Mutant("wldegree", W, "hasher.combine(offsets[v + 1] - offsets[v])", "", mode="stmt"),
    Mutant("wlown", W, "                                        hasher.combine(colors[v])", "                                        hasher.combine(0)", mode="stmt", nth=0),
    Mutant("wlswap", W, "        swap(&colors, &next)", "", mode="stmt"),
    Mutant("wlrounds", W, "for v in 0 ..< n { rounds[v * iterations + round] = colors[v] }", "for v in 0 ..< n { rounds[v * iterations + round] = next[v] }", mode="stmt"),
    Mutant("wlcount", W, "    graphHasher.combine(n)", "", mode="stmt"),
    Mutant("wlinitial", W, "    graphHasher.combine(initial.0)\n    graphHasher.combine(initial.1)", "", mode="stmt"),
    Mutant("wlround", W, "        graphHasher.combine(round)", "", mode="stmt"),
    Mutant("wlroundmultiset", W, "        graphHasher.combine(multiset.0)\n        graphHasher.combine(multiset.1)", "", mode="stmt"),
    Mutant("wlslice", W, "storage[index * iterations ..< (index + 1) * iterations]", "storage[index ..< index + iterations]"),
    Mutant("wlgraphedges", W, "return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: colors, edgeColors: edgeColors).0, iterations: iterations, keepRounds: false).hash", "return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: colors, edgeColors: []).0, iterations: iterations, keepRounds: false).hash", mode="stmt", nth=1),
    Mutant("wlsubvertexcolors", W, "_weisfeilerLehmanGraph(vertexColors: vertices.map { vertexColor($0).hashValue }, edgeColors: [])", "_weisfeilerLehmanGraph(vertexColors: [], edgeColors: [])", nth=0),
    Mutant("wlgraphvertexcolorsdirected", W, "return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: colors, edgeColors: []).0, iterations: iterations, keepRounds: false).hash", "return _weisfeilerLehman(_weisfeilerLehmanGraph(vertexColors: [], edgeColors: []).0, iterations: iterations, keepRounds: false).hash", mode="stmt", nth=1),

    # The overloads' plumbing (spot checks).
    Mutant("gvertexcolortable", MG, "table.id(otherVertexColor($0))", "{ (c: VertexColor) -> Int in var fresh = _ColorTable<VertexColor>(); return fresh.id(c) }(otherVertexColor($0))"),
    Mutant("gedgecolortable", MG, "table.id(otherEdgeColor($0))", "{ (c: EdgeColor) -> Int in var fresh = _ColorTable<EdgeColor>(); return fresh.id(c) }(otherEdgeColor($0))"),
    Mutant("gisoedges", MG, "_matchings(to: other, .isomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: _edgeColorIDs(other, edgeColor, otherEdgeColor))", "_matchings(to: other, .isomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: ([], []))"),
    Mutant("gsubkind", MG, "_matchings(to: other, .subgraphIsomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: ([], []))", "_matchings(to: other, .monomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: ([], []))"),
    Mutant("gmonofirst", MG, "monomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor)._first", "subgraphIsomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor)._first"),
    Mutant("gissub", MG, "subgraphIsomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor) != nil", "monomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor) != nil"),
    Mutant("gpatterncolors", MG, "edgeColors.0", "[Int]()"),
    Mutant("dvertexcolortable", MD, "table.id(otherVertexColor($0))", "{ (c: VertexColor) -> Int in var fresh = _ColorTable<VertexColor>(); return fresh.id(c) }(otherVertexColor($0))"),
    Mutant("disoedges", MD, "_matchings(to: other, .isomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: _edgeColorIDs(other, edgeColor, otherEdgeColor))", "_matchings(to: other, .isomorphism, vertexColors: _vertexColorIDs(other, vertexColor, otherVertexColor), edgeColors: ([], []))"),
    Mutant("dmonokind", MD, "_matchings(to: other, .monomorphism, vertexColors: ([], []), edgeColors: ([], []))", "_matchings(to: other, .subgraphIsomorphism, vertexColors: ([], []), edgeColors: ([], []))"),
    Mutant("dsubfirst", MD, "subgraphIsomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor)._first", "monomorphisms(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor)._first"),
    Mutant("disiso", MD, "isomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor, edgeColor: edgeColor, otherEdgeColor: otherEdgeColor) != nil", "isomorphism(to: other, vertexColor: vertexColor, otherVertexColor: otherVertexColor) != nil"),
    Mutant("dtargetcolors", MD, "edgeColors.1", "[Int]()"),

    # The refinement graph: the union of G and H, or one graph.
    Mutant("unionoffsets", P, "base + row.offsets[v + 1]", "row.offsets[v + 1]"),
    Mutant("uniontargets", P, "row.targets[k] + shift", "row.targets[k]"),
    Mutant("unionhweights", P, "_colorWeight(row.colors[k])", "_colorWeight(row.colors[k] &+ part)"),
    Mutant("unionin", P, "relations.append(relation(parts.map { ($0.inOffsets, $0.inTargets, $0.inColors) }))", "", mode="stmt"),

    # The list of cells longer than `unit` (dancing links).
    Mutant("listundorelink", P, "if merged > unit && !listed[previous] { relink(previous) }", "", mode="stmt"),
    Mutant("listundounlink", P, "if listed[s] { unlink(s) }", "", mode="stmt"),
    Mutant("undolength", P, "cellLength[previous] = merged", "cellLength[previous] = length", mode="stmt"),
    Mutant("listsplitlink", P, "if end - f > unit { link(f, after: x) }", "", mode="stmt"),
    Mutant("listsplitunlink", P, "if f - x <= unit && listed[x] { unlink(x) }", "", mode="stmt"),
    Mutant("liststart", P, "if n > unit { link(0, after: n) }", "", mode="stmt"),
    Mutant("liststartclass", P, "                link(s, after: last)", "", mode="stmt"),
    Mutant("smallestbreak", P, "if length == unit + 1 { break }", "", mode="stmt"),
    Mutant("smallestlargest", P, "length < bestLength", "(best < 0 || length > cellLength[best])"),
    Mutant("largestsmallest", P, "cellLength[c] > bestLength", "(best < 0 || cellLength[c] < cellLength[best])"),

    # The trace (node invariant) and the early abort.
    Mutant("traceindividualize", P, "            mix(c)\n            mix(length)", "", mode="stmt"),
    Mutant("tracesplitter", P, "                mix(s)\n                mix(length)", "", mode="stmt"),
    Mutant("tracecellcount", P, "            mix(cellCount)", "", mode="stmt"),
    Mutant("tracesplitcell", P, "            mix(c)\n            mix(keptEnd - c)", "", mode="stmt"),
    Mutant("tracesplitkey", P, "if marked == length { mix(Int(truncatingIfNeeded: low)) }", "", mode="stmt"),
    Mutant("tracegroup", P, "                mix(groupLength)\n                mix(Int(truncatingIfNeeded: key))", "", mode="stmt"),
    Mutant("traceorder", P, "            region.sort()", "", mode="stmt"),
    Mutant("checkfirst", P, "if equalsFirst && (i >= firstReference.count || firstReference[i] != z) { equalsFirst = false }", "", mode="stmt"),
    Mutant("checkbestorder", P, "z < bestReference[i] ? -1 : 1", "z < bestReference[i] ? 1 : -1"),
    Mutant("checkbestlonger", P, "                comparedToBest = 1", "                comparedToBest = -1", mode="stmt"),
    Mutant("checkdiverge", P, "        if !equalsFirst && (!canonical || comparedToBest < 0) { diverged = true }", "", mode="stmt", nth=0),
    Mutant("checkendfirst", P, "if equalsFirst && eventIndex != firstReference.count { equalsFirst = false }", "", mode="stmt"),
    Mutant("checkendbest", P, "if comparedToBest == 0 && eventIndex < bestReference.count { comparedToBest = -1 }", "", mode="stmt"),
    Mutant("checkstartbest", P, "if comparedToBest == 0 && best == nil { self.comparedToBest = 1 }", "", mode="stmt"),
    Mutant("checkstartcanonical", P, "if !canonical { self.comparedToBest = -1 }", "", mode="stmt"),
    Mutant("refinediverged", P, "!ok || diverged", "!ok"),

    # The isomorphism search: the joint search, then components, then canonical labelings.
    Mutant("budgetzero", R, "joint.first(budget: 64 + 2 * n)", "joint.first(budget: 0)"),
    Mutant("budgetnone", R, "joint.first(budget: 64 + 2 * n)", "joint.first(budget: Int.max)"),
    Mutant("budgetfailures", R, "if failures > 1 { return .overBudget }", "", mode="stmt"),
    Mutant("componentsskip", R, "if gParts.count > 1 || hParts.count > 1 { return decideByComponents(gParts, hParts) }", "", mode="stmt"),
    Mutant("componentscount", R, "guard gParts.count == hParts.count else { return nil }", "", mode="stmt"),
    Mutant("componentssizes", R, "guard sizes(gParts) == sizes(hParts) else { return nil }", "", mode="stmt"),
    Mutant("componentscertificate", R, "guard x.certificate == y.certificate else { return nil }", "", mode="stmt"),
    Mutant("componentsimages", R, "images[x.vertices[x.leaf[q]]] = y.vertices[y.leaf[q]]", "images[x.vertices[x.leaf[q]]] = y.vertices[y.leaf[(q + 1) % y.leaf.count]]", mode="stmt"),
    Mutant("canonicalcompare", R, "h.cancelled || g.certificate != h.certificate", "h.cancelled"),
    Mutant("canonicalimages", R, "images[g.bestLeaf[q]] = h.bestLeaf[q]", "images[h.bestLeaf[q]] = g.bestLeaf[q]", mode="stmt"),
    Mutant("canonicalreuse", R, "canonicalG ?? _AutomorphismSearch(data.g, colors: data.g.vertexColors, span: data.span, canonical: false, checkCancellation: true)", "_AutomorphismSearch(data.g, colors: data.g.vertexColors, span: data.span, canonical: false, checkCancellation: true)"),
    Mutant("enumerationidentity", R, "            _ = e.next()", "", mode="stmt"),
    Mutant("enumerationcompose", R, "element.map { first[$0] }", "first.map { element[$0] }"),
    Mutant("searchrootleaf", R, "if partition.isDiscrete { return leaf() ? .found(images) : .none }", "", mode="stmt"),
    Mutant("searchcheck", R, "if data.g.hasEdgeColors { return _preservesRows(images, data.g, data.h, data.span, &scratch) }", "", mode="stmt"),
    Mutant("smallestany", R, "p.firstSmallestCell()", "p.firstLargestCell()"),

    # Components of an index graph.
    Mutant("componentsdirected", G, "inOffsets[v] ..< inOffsets[v + 1]", "inOffsets[v] ..< inOffsets[v]"),
    Mutant("componentscolors", G, "if hasEdgeColors { colors.append(outColors[k]) }", "", mode="stmt"),
    Mutant("componentsvertexcolors", G, "vertexColors.isEmpty ? [] : members.map { vertexColors[$0] }", "[Int]()"),
    Mutant("componentsinrows", G, "            if isDirected { graph.buildInRows() }", "", mode="stmt"),

    # Rows preserved (leaves of the joint search, automorphism checks with colours or multi-edges).
    Mutant("leafrowlength", A, "guard h.outOffsets[x + 1] - hs == end - start else { return false }", "", mode="stmt"),
    Mutant("leafcolor", A, "keys[j] != h.outTargets[hs + j] &* span &+ h.outColors[hs + j]", "keys[j] / span != h.outTargets[hs + j]"),
    Mutant("leafplain", A, "for j in 0 ..< keys.count where keys[j] != h.outTargets[hs + j] { return false }", "", mode="stmt"),

    # The automorphism search.
    Mutant("autotarget", A, "p.firstLargestCell()", "p.firstSmallestCell()"),
    Mutant("autoorbitprune", A, "if find(d, v) == v { return v }", "return v", mode="stmt"),
    Mutant("autoabsorbfixes", A, "gamma[path[i]] != path[i]", "false"),
    Mutant("autoabsorbroot", A, "if a < b { orbitParent[d][b] = a } else if b < a { orbitParent[d][a] = b }", "if a != b { orbitParent[d][a] = b }", mode="stmt"),
    Mutant("autoabsorbonce", A, "if nodes[d].absorbed < generators.count { absorb(d) }", "if nodes[d].absorbed < 0 { absorb(d) }", mode="stmt"),
    Mutant("autojumpback", A, "                    jumpBack(depth, to: base)", "", mode="stmt"),
    Mutant("autobestgamma", A, "                    generators.append(gamma)\n                    jumpBack(depth, to: bestPath)", "                    jumpBack(depth, to: bestPath)", mode="stmt"),
    Mutant("autojumpbackbest", A, "                    jumpBack(depth, to: bestPath)", "", mode="stmt", nth=1),
    Mutant("autojumpbacktoo", A, "while k < depth && k < other.count && path[k] == other[k] { k += 1 }", "", mode="stmt"),
    Mutant("autocheckgamma", A, "isAutomorphism(gamma)", "true"),
    Mutant("autocolors", A, "for v in 0 ..< n where colors[gamma[v]] != colors[v] { return false }", "", mode="stmt"),
    Mutant("autosimplerow", A, "for k in xs ..< xs + (end - start) where marks[g.outTargets[k]] != stamp { return false }", "", mode="stmt"),
    Mutant("autosimpleoff", A, "graph.isSimple", "false"),
    Mutant("autobestgreater", A, "compared > 0", "false"),
    Mutant("autobestorder", A, "order > 0", "order < 0"),
    Mutant("autobestreset", A, "for i in nodes.indices { nodes[i].comparedToBest = 0 }", "", mode="stmt"),
    Mutant("autorecord", A, "canonical || !haveFirst", "!haveFirst"),
    Mutant("autochecking", A, "canonical && parent.comparedToBest == 0 && d + 1 < bestEvents.count ? bestEvents[d + 1] : nil", "Optional<[UInt64]>.none"),
    Mutant("certcolor", A, "out.append(colors.isEmpty ? 0 : colors[v])", "out.append(0)", mode="stmt"),
    Mutant("certlength", A, "            out.append(end - start)", "", mode="stmt"),
    Mutant("certedgecolor", A, "row.append(inverse[g.outTargets[k]] &* span &+ g.outColors[k])", "row.append(inverse[g.outTargets[k]] &* span)", mode="stmt"),
    Mutant("certsort", A, "            row.sort()\n            out.append(contentsOf: row)", "            out.append(contentsOf: row)", mode="stmt"),
    Mutant("chainkeep", A, "if joined { kept.append(index) }", "kept.append(index)", mode="stmt"),
    Mutant("chainlength", A, "            lengths[i] = size", "", mode="stmt"),
    Mutant("chainlevel", A, "while i < k && gamma[base[i]] == base[i] { i += 1 }", "", mode="stmt"),
    Mutant("groupfixing", A, "(0 ..< i).allSatisfy { generators[g][base[$0]] == base[$0] }", "true"),
    Mutant("groupcompose", A, "for g in chain.reversed() { x = generators[g][x] }", "for g in chain { x = generators[g][x] }", mode="stmt"),
    Mutant("enumdigits", A, "            digits[i] = 0", "", mode="stmt"),
    Mutant("enumproducts", A, "i ..< k", "i ..< i + 1"),

    # The automorphism group and canonical labeling results.
    Mutant("grouporbitroot", AG, "if a < b { parent[b] = a } else if b < a { parent[a] = b }", "if a != b { parent[a] = b }", mode="stmt", nth=0),
    Mutant("groupmembers", AG, "        fill[orbitNumbers[v]] += 1", "", mode="stmt"),
    Mutant("productcarry", AG, "            carry = x >> 32", "            carry = 0", mode="stmt"),
    Mutant("productsticky", AG, "if sticky { top |= 1 }", "", mode="stmt"),
    Mutant("productsmall", AG, "bits <= 64", "bits <= 32"),
    Mutant("canonicalpermutation", AG, "for (q, v) in search.bestLeaf.enumerated() { permutation[v] = q }", "for (q, v) in search.bestLeaf.enumerated() { permutation[q] = v }", mode="stmt"),
    Mutant("canonicalcount", AG, "return (permutation, [graph.count] + search.certificate)", "return (permutation, search.certificate)", mode="stmt"),
    Mutant("canonicaldirected", AG, "CanonicalForm(isDirected: false, certificate: result.certificate)", "CanonicalForm(isDirected: true, certificate: result.certificate)"),
    Mutant("groupedgecolors", AG, "edges.indices.map { edgeTable.id(edgeColor($0)) }", "[Int]()", nth=0),
    Mutant("groupvertexcolors", AG, "return _automorphismGroup(vertexColors: vertices.map { table.id(vertexColor($0)) }, edgeColors: [])", "return _automorphismGroup(vertexColors: [], edgeColors: [])", mode="stmt", nth=1),

    # The inverse and preimage(checked:).
    Mutant("inverse", I, "for (u, x) in imageIndices.enumerated() { inverted[x] = u }", "for (u, x) in imageIndices.enumerated() { inverted[u] = x }", mode="stmt", nth=0),
    Mutant("preimagechecked", I, "guard target.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=1),

    # The subgraph search's copy.
    Mutant("subcopy", S, "        cursor.update(from: other.cursor, count: np)", "", mode="stmt"),

    # The checked: lookups.
    Mutant("orbitchecked", "AutomorphismGroup.swift", "guard graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=0),
    Mutant("orbitcheckeddirected", "AutomorphismGroup.swift", "guard graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=1),
    Mutant("canonicalchecked", "AutomorphismGroup.swift", "guard graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=2),
    Mutant("canonicalcheckeddirected", "AutomorphismGroup.swift", "guard graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=3),
    Mutant("orbitcheckedvalue", "AutomorphismGroup.swift", "        return orbit(of: vertex)", "        return 0", mode="stmt", nth=0),
    Mutant("orbitcheckedvaluedirected", "AutomorphismGroup.swift", "        return orbit(of: vertex)", "        return 0", mode="stmt", nth=1),
    Mutant("canonicalcheckedvalue", "AutomorphismGroup.swift", "        return canonicalIndex(of: vertex)", "        return 0", mode="stmt", nth=0),
    Mutant("canonicalcheckedvaluedirected", "AutomorphismGroup.swift", "        return canonicalIndex(of: vertex)", "        return 0", mode="stmt", nth=1),
    Mutant("hasheschecked", "WeisfeilerLehman.swift", "guard graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=0),
    Mutant("hashescheckeddirected", "WeisfeilerLehman.swift", "guard graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=1),
    Mutant("hashescheckedvalue", "WeisfeilerLehman.swift", "        return hashes(of: vertex)", "        return hashes(ofIndex: 0)", mode="stmt", nth=0),
    Mutant("hashescheckedvaluedirected", "WeisfeilerLehman.swift", "        return hashes(of: vertex)", "        return hashes(ofIndex: 0)", mode="stmt", nth=1),
    # Graph edit distance: the index graph's cells.
    Mutant("editcellsymmetric", ES, "if !isDirected { cellOffsets[t * n + s + 1] += 1 }", "", mode="stmt"),
    Mutant("editcellfill", ES, "cellFill[s * n + t] += 1", "cellFill[s * n + t] += 0"),
    Mutant("editincidence", ES, "incidenceOffsets[t + 1] += 1", "incidenceOffsets[t + 1] += 0"),
    # The edit assignment (Hungarian method).
    Mutant("lsapeslack", ES, "!hasSlack[j] || reduced < slack[j]", "!hasSlack[j] || reduced > slack[j]"),
    Mutant("lsapedelta", ES, "hasSlack[j] && (!hasDelta || slack[j] < delta)", "hasSlack[j] && !hasDelta"),
    Mutant("lsapepotential", ES, "rowPotential[columnRow[j]] += delta", "rowPotential[columnRow[j]] -= delta", mode="stmt"),
    Mutant("lsapeslackupdate", ES, "slack[j] -= delta", "slack[j] += delta", mode="stmt"),
    Mutant("lsapemate", ES, "if i < k1 { rowMate[i] = j - 1 < k2 ? j - 1 : -1 }", "if i < k1 { rowMate[i] = -1 }", mode="stmt"),
    Mutant("lsapedeletion", ES, "return j &- k2 == i ? deletion[i] : nil", "return deletion[i]", mode="stmt"),
    # Group costs.
    Mutant("groupinsert", ES, "for k in b { c += edgeInsertion[g2.cellEdges[k]] }", "", mode="stmt", nth=0),
    Mutant("groupdelete", ES, "for k in a { c += edgeDeletion[g1.cellEdges[k]] }", "", mode="stmt"),
    Mutant("groupone", ES, "return substitute <= replace ? substitute : replace", "return substitute", mode="stmt"),
    Mutant("groupassignone", ES, "if assign { edgeImage[e] = substitute <= replace ? f : -1 }", "if assign { edgeImage[e] = f }", mode="stmt"),
    Mutant("groupassign", ES, "edgeImage[g1.cellEdges[ka]] = j < 0 ? -1 : g2.cellEdges[b.lowerBound + j]", "edgeImage[g1.cellEdges[ka]] = -1", mode="stmt"),
    # Settled edges and the lower bound.
    Mutant("settledloops", ES, "groupCost(g1.cell(u, u), x >= 0 ? g2.cell(x, x) : empty, &none)", "C.zero"),
    Mutant("settleddirected", ES, "if g1.isDirected { c += groupCost(g1.cell(w, u), mapped ? g2.cell(y, x) : empty, &none) }", "", mode="stmt"),
    Mutant("settledmapped", ES, "y >= 0 && x >= 0", "x >= 0"),
    Mutant("surplusdouble", ES, "if a > b { return C(exactly: a - b)! * deletion }", "if a > b { return C(exactly: a - b)! * (deletion + deletion) }", mode="stmt"),
    Mutant("boundbranch", ES, "outer.substitution[i * k2 + j] = settled + settled + branch", "outer.substitution[i * k2 + j] = settled + settled + branch + branch", mode="stmt"),
    Mutant("bounddeletion", ES, "outer.deletion[i] = settled + settled + branchCost1[u]", "outer.deletion[i] = settled + settled + branchCost1[u] + branchCost1[u]", mode="stmt"),
    Mutant("boundinsertion", ES, "outer.insertion[j] = settled + settled + branchCost2[x]", "outer.insertion[j] = settled + settled + branchCost2[x] + branchCost2[x]", mode="stmt"),
    Mutant("boundsettled", ES, "vertexSubstitution[u * n2 + x] + settledCost(u, x)", "vertexSubstitution[u * n2 + x] + settledCost(u, x) + settledCost(u, x)", nth=0),
    # Pruning, the search and the path.
    Mutant("prunebound", ES, "if let bound { return lower > bound }", "if let bound { return lower >= bound }", mode="stmt"),
    Mutant("leafinsertion", ES, "for v in 0 ..< n2 where preimage[v] < 0 { total += vertexInsertion[v] + vertexInsertion[v] }", "for v in 0 ..< n2 where preimage[v] < 0 { total += vertexInsertion[v] }", mode="stmt"),
    Mutant("leafedges", ES, "preimage[g2.ends[2 * f]] < 0 || preimage[g2.ends[2 * f + 1]] < 0", "preimage[g2.ends[2 * f]] < 0 && preimage[g2.ends[2 * f + 1]] < 0"),
    Mutant("limitcount", ES, "expansions >= expansionLimit", "expansions > expansionLimit"),
    Mutant("limitflag", ES, "            exhausted = true", "", mode="stmt"),
    Mutant("childorder", ES, "childBound[previous] > lower || (childBound[previous] == lower && key > mine)", "childBound[previous] < lower"),
    Mutant("childprune", ES, "if isPruned(childBound[start + k]) { break }", "", mode="stmt"),
    Mutant("heuristic", ES, "        if !isPruned(heuristicCost + heuristicCost) {\n            bestCost = heuristicCost + heuristicCost\n            bestImage = heuristic\n        }", "", mode="stmt"),
    Mutant("pathdirected", ES, "(g1.isDirected ? 0 : a)", "a"),
    Mutant("pathinserted", ES, "for f in 0 ..< g2.edgeCount where !used[g2.ends[2 * f]] || !used[g2.ends[2 * f + 1]] { c += edgeInsertion[f] }", "", mode="stmt"),
    Mutant("pathoptimal", ES, "return (bestImage, edgeImages, cost, !exhausted)", "return (bestImage, edgeImages, cost, true)", mode="stmt"),
    Mutant("costcheck", ES, "c >= .zero && c - c == .zero", "c - c == .zero"),
    # The path's accessors and checked spellings.
    Mutant("editlimitcheck", EP, "precondition(expansionLimit.map { $0 >= 0 } ?? true, \"The expansion limit is negative\")", "", mode="stmt"),
    Mutant("editordinal", EP, "if positions[mid] < position { lo = mid + 1 } else { hi = mid }", "if positions[mid] <= position { lo = mid + 1 } else { hi = mid }", mode="stmt"),
    Mutant("editimageindex", EP, "return x < 0 ? nil : x", "return x", mode="stmt"),
    Mutant("editimagechecked", EP, "guard pattern.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=0),
    Mutant("editimagecheckeddirected", EP, "guard pattern.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=1),
    Mutant("editpreimagechecked", EP, "guard target.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=0),
    Mutant("editpreimagecheckeddirected", EP, "guard target.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt", nth=1),
    Mutant("editedgechecked", EP, "guard _editOrdinal(of: position, in: _positions.pattern) != nil else { throw EdgeNotFound() }", "guard true else { throw EdgeNotFound() }", mode="stmt", nth=0),
    Mutant("editedgecheckeddirected", EP, "guard _editOrdinal(of: position, in: _positions.pattern) != nil else { throw EdgeNotFound() }", "guard true else { throw EdgeNotFound() }", mode="stmt", nth=1),
    Mutant("editedgepreimagechecked", EP, "guard _editOrdinal(of: position, in: _positions.target) != nil else { throw EdgeNotFound() }", "guard true else { throw EdgeNotFound() }", mode="stmt", nth=0),
    Mutant("editedgepreimagecheckeddirected", EP, "guard _editOrdinal(of: position, in: _positions.target) != nil else { throw EdgeNotFound() }", "guard true else { throw EdgeNotFound() }", mode="stmt", nth=1),
    Mutant("editinsertedvertices", EP, "for x in vertexImages where x >= 0 { used[x] = true }", "", mode="stmt", nth=0),
    Mutant("editinsertedverticesdirected", EP, "for x in vertexImages where x >= 0 { used[x] = true }", "", mode="stmt", nth=1),
    Mutant("editinsertededges", EP, "for f in edgeImages where f >= 0 { used[f] = true }", "", mode="stmt", nth=0),
    Mutant("editinsertededgesdirected", EP, "for f in edgeImages where f >= 0 { used[f] = true }", "", mode="stmt", nth=1),
]
