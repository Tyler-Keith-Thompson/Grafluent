# Planted bugs for Planarity; run with `just mutate Planarity`. See scripts/mutate.py.
#
# Coverage: the reading of the underlying simple graph; the left-right test's three searches
# (orientation and lowpoints, the nesting order, the conflict pairs, the side resolution and the
# embedding search); the embedding layout (rows, twins, parallel copies, loops) and the face
# tracing; the public accessors; Boyer–Myrvold's set-up, Walkup and Walkdown; and the Kuratowski
# isolation: choosing the minor and the marking of each of A, B, C, D, E and E1–E4. A caught
# marking mutant proves its case is reached, since the witness then fails the subgraph checks.
#
# Known equivalent mutants (they survive by design):
#   checkedfacerange, checkedfaceedge
#                 the range checks in `_checkedSlot`: every representation tested maps an
#                 out-of-range Int position to an out-of-range edge number without trapping, and
#                 `_EmbeddingLayout.slot(at:ofEdge:)` finds no slot for one, so `.edge` is thrown
#                 either way. Kept as guards against `edgeIndex(of:)` trapping on a foreign position.
#   countingsort  always the two counting sorts instead of insertion sort on short rows: both
#                 order each row by nesting depth, stable in edge number; time only.
#   rightorder    `side > 0` as `>= 0` for the right edges: a resolved side is ±1, never 0.
#   highestleft   the lower of the top conflict pair's two highest return edges as the reference
#                 of the tree edge: on 600,000 random near-triangulations under the mutant (where
#                 the two differ at about half the visits, by an instrumented count) every
#                 embedding still met Euler's formula, which the layout checks, and the rows whose
#                 embedding is unique (3-connected) are pinned; it only picks among planar
#                 embeddings.
#   walkupstop    stopping the Walkup when both, not either, of its two walkers meet a visited
#   walkupmark    vertex, or not marking the second walker's vertex: the walk then goes on to a
#                 root that is already recorded and stops there; time only (the Walkup's
#                 shorter-side bound).

TESTS = ["PlanarityTests"]

R = "UnderlyingSimpleGraph.swift"
P = "Planarity.swift"
LR = "LeftRightPlanarity.swift"
EL = "EmbeddingLayout.swift"
PE = "PlanarEmbedding.swift"
BM = "BoyerMyrvold.swift"
KI = "KuratowskiIsolation.swift"
KS = "KuratowskiSubgraph.swift"

MUTANTS = [
    # Reading the simple graph and the shortcuts.
    Mutant("readloops", R, "if w < v { continue }", "if w <= v { continue }", mode="stmt"),
    Mutant("readcopies", R, "stamp[w] == v", "false"),
    Mutant("readlimit", R, "count == limit", "count == limit + 1"),
    Mutant("planarlimit", P, "n >= 3 ? 3 * n - 6 : .max", "n >= 3 ? 3 * n - 7 : .max"),
    Mutant("kuratowskilimit", P, "n >= 3 ? 3 * n - 5 : Int.max", "n >= 3 ? 3 * n - 6 : Int.max"),
    Mutant("outerlimit", P, "n >= 2 ? 2 * n - 3 : .max", "n >= 2 ? 2 * n - 4 : .max"),
    Mutant("outernoapex", P, "simple.addingApex().leftRightIsPlanar()", "simple.leftRightIsPlanar()"),
    Mutant("apexedge", R, "withApex.append(Int32(n))", "withApex.append(Int32((v + 1) % n))", mode="stmt"),

    # Left-right: orientation and lowpoints.
    Mutant("lowptback", LR, "lowpt[k] = height[w]", "lowpt[k] = height[v]", mode="stmt"),
    Mutant("chordal", LR, "(lowpt2[k] < height[v] ? 1 : 0)", "0"),
    Mutant("lowptmin", LR, "lowpt2[e] = Swift.min(lowpt[e], lowpt2[k])", "lowpt2[e] = lowpt2[k]", mode="stmt"),
    Mutant("lowpt2high", LR, "lowpt2[e] = Swift.min(lowpt2[e], lowpt[k])", "lowpt2[e] = lowpt[k]", mode="stmt"),
    Mutant("lowpt2equal", LR, "lowpt2[e] = Swift.min(lowpt2[e], lowpt2[k])", "lowpt2[e] = lowpt2[e]", mode="stmt"),
    Mutant("orientresume", LR, "resuming[v] != 0", "false", nth=1),
    Mutant("testresume", LR, "resuming[v] != 0", "false", nth=2),

    # Left-right: the nesting order.
    Mutant("shortsort", LR, "nesting[ordered[j]] > key", "nesting[ordered[j]] < key"),
    Mutant("countingsort", LR, "longest <= 24", "longest <= 0"),
    Mutant("insertionsort", LR, "longest <= 24", "true"),
    Mutant("countingstable", LR, "scratch[keyCounts[slot]] = k", "scratch[keyCounts[slot]] = s - 1 - k", mode="stmt"),

    # Left-right: the conflict pairs.
    Mutant("conflictskip", LR, "!addConstraints(k, e)", "(!addConstraints(k, e) && false)"),
    Mutant("lowptedgefirst", LR, "lowptEdge[e] = lowptEdge[k]", "lowptEdge[e] = k", mode="stmt"),
    Mutant("mergeright", LR, "if !isEmpty(qLeftLow, qLeftHigh) { return false }", "if !isEmpty(qLeftLow, qLeftHigh) { return true }", mode="stmt"),
    Mutant("mergerightlow", LR, "lowpt[qRightLow] > lowpt[e]", "lowpt[qRightLow] >= lowpt[e]"),
    Mutant("conflictleft", LR, "if conflicting(qRightLow, qRightHigh, ei) { return false }", "if conflicting(qRightLow, qRightHigh, ei) { return true }", mode="stmt"),
    Mutant("conflictstrict", LR, "!isEmpty(low, high) && lowpt[high] > lowpt[b]", "!isEmpty(low, high) && lowpt[high] >= lowpt[b]"),
    Mutant("refright", LR, "if rightLow != -1 { ref[rightLow] = qRightHigh }", "if rightLow != -1 { ref[rightLow] = -1 }", mode="stmt"),
    Mutant("refleft", LR, "ref[leftLow] = qLeftHigh", "ref[leftLow] = -1", mode="stmt"),
    Mutant("pushempty", LR, "!(isEmpty(leftLow, leftHigh) && isEmpty(rightLow, rightHigh))", "true"),
    Mutant("dropside", LR, "if leftLow != -1 { side[leftLow] = -1 }", "if leftLow != -1 { side[leftLow] = 1 }", mode="stmt"),
    Mutant("trimleft", LR, "while leftHigh != -1 && target(leftHigh) == u { leftHigh = ref[leftHigh] }", "if leftHigh != -1 && target(leftHigh) == u { leftHigh = ref[leftHigh] }", mode="stmt"),
    Mutant("trimright", LR, "while rightHigh != -1 && target(rightHigh) == u { rightHigh = ref[rightHigh] }", "if rightHigh != -1 && target(rightHigh) == u { rightHigh = ref[rightHigh] }", mode="stmt"),
    Mutant("trimleftside", LR, "                ref[leftLow] = rightLow\n                side[leftLow] = -1", "                ref[leftLow] = rightLow", mode="stmt"),
    Mutant("trimrightside", LR, "                ref[rightLow] = leftLow\n                side[rightLow] = -1", "                ref[rightLow] = leftLow", mode="stmt"),
    Mutant("highestleft", LR, "lowpt[highLeft] > lowpt[highRight]", "lowpt[highLeft] < lowpt[highRight]"),

    # Left-right: the sides and the embedding search.
    Mutant("sideproduct", LR, "side[y] *= side[ref[y]]", "side[y] = side[ref[y]]", mode="stmt"),
    Mutant("sideunresolved", LR, "resolvedSide(k) < 0", "side[k] < 0"),
    Mutant("rightorder", LR, "side[ordered[i]] > 0", "side[ordered[i]] >= 0"),
    Mutant("backright", LR, "side[k] == 1", "side[k] != 1"),
    Mutant("leftrefupdate", LR, "                        leftRef[w] = atW", "", mode="stmt"),
    Mutant("treefirst", LR, "insertFirst(atW, at: w)", "insert(atW, after: firstHalf[w] == -1 ? atW : firstHalf[w])", mode="stmt"),
    Mutant("rightrefreset", LR, "                        rightRef[v] = atV", "", mode="stmt"),
    Mutant("components", LR, "components += 1", "components += 2", mode="stmt"),

    # The layout: rows, twins, copies, loops, faces.
    Mutant("rowstart", EL, "Int(ends[2 * k0]) == v ? 2 * k0 : 2 * k0 + 1", "Int(ends[2 * k0]) == v ? 2 * k0 + 1 : 2 * k0"),
    Mutant("twinpair", EL, "                        twin[q] = p", "", mode="stmt"),
    Mutant("copiesorder", EL, "copies[h & 1 == 0 ? base + i : last - i]", "copies[base + i]"),
    Mutant("loopsfirst", EL, "            putLoops(v)\n            putGroup(h0, from: 0, to: j0)", "            putGroup(h0, from: 0, to: j0)\n            putLoops(v)", mode="stmt"),
    Mutant("firstcopy", EL, "while copies[h0 & 1 == 0 ? base + j0 : last - j0] != fe { j0 += 1 }", "j0 = 0", mode="stmt"),
    Mutant("loopcomponent", EL, "if graph.rowStart[v] == graph.rowStart[v + 1] { components += 1 }", "", mode="stmt"),
    Mutant("facenext", EL, "q = t == Int(rowOffsets[y]) ? Int(rowOffsets[y + 1]) - 1 : t - 1", "q = t + 1 == Int(rowOffsets[y + 1]) ? Int(rowOffsets[y]) : t + 1", mode="stmt"),
    Mutant("facewrap", EL, "return t == Int(rowOffsets[y]) ? Int(rowOffsets[y + 1]) - 1 : t - 1", "return t == Int(rowOffsets[y]) ? Int(rowOffsets[y]) : t - 1", mode="stmt"),
    Mutant("facetail", EL, "vertices.append(Int(rowNeighbors[Int(twin[q])]))", "vertices.append(Int(rowNeighbors[q]))", mode="stmt"),
    Mutant("faceslotlast", EL, "for q in Int(rowOffsets[v]) ..< Int(rowOffsets[v + 1]) where rowEdges[q] == edge { return q }", "for q in (Int(rowOffsets[v]) ..< Int(rowOffsets[v + 1])).reversed() where rowEdges[q] == edge { return q }", mode="stmt"),

    # Public accessors.
    Mutant("positions", PE, "_positions.isEmpty ? unsafeBitCast(k, to: G.Edges.Index.self) : _positions[k]", "_positions.isEmpty ? unsafeBitCast(k, to: G.Edges.Index.self) : _positions[_positions.count - 1 - k]"),
    Mutant("neighborindices", PE, "return Int(_numbers[_numbers.startIndex + position])", "return Int(_numbers[_numbers.endIndex - 1 - position])", mode="stmt"),
    Mutant("rightface", PE, "Int(_layout.faceOfSlot[_slot(from: vertex, alongEdgeAt: position)])", "Int(_layout.faceOfSlot[Int(_layout.twin[_slot(from: vertex, alongEdgeAt: position)])])"),
    Mutant("faceorder", PE, "_embedding._layout.face(fromSlot: Int(_embedding._layout.faceStart[position]))", "_embedding._layout.face(fromSlot: Int(_embedding._layout.faceStart[_embedding.faceCount - 1 - position]))"),

    # Boyer–Myrvold: set-up.
    Mutant("bmleastancestor", BM, "if a < leastAncestor[d] { leastAncestor[d] = a }", "if a > leastAncestor[d] { leastAncestor[d] = a }", mode="stmt"),
    Mutant("bmlowpoint", BM, "if lowpoint[c] < low { low = lowpoint[c] }", "if lowpoint[c] > low { low = lowpoint[c] }", mode="stmt"),

    # Boyer–Myrvold: Walkup.
    Mutant("walkupstop", BM, "if visitedIndex[zig] == v || visitedIndex[zag] == v { break }", "if visitedIndex[zig] == v && visitedIndex[zag] == v { break }", mode="stmt"),
    Mutant("walkuproots", BM, "lowpoint[c] < v", "lowpoint[c] >= v", nth=1),
    Mutant("walkupmark", BM, "            visitedIndex[zag] = v", "", mode="stmt"),

    # Boyer–Myrvold: Walkdown.
    Mutant("walkdownorder", BM, "isPertinent(x) && !isFuturePertinent(x, v)", "isPertinent(x)"),
    Mutant("walkdowny", BM, "isPertinent(y) && !isFuturePertinent(y, v)", "false"),
    Mutant("walkdownbeside", BM, "ext[2 * root + (1 ^ rootSide)] == w", "false"),
    Mutant("walkdownshortcut", BM, "w != root", "false", nth=1),
    Mutant("walkdowninactive", BM, "wPrevious = ext[2 * x] == w ? 0 : 1\n                    w = x", "wPrevious = ext[2 * x] == w ? 1 : 0\n                    w = x", mode="stmt"),
    Mutant("walkdownblocked", BM, "following == -1 || following > neighbor[e]", "following == -1"),
    Mutant("mergeflip", BM, "zPrevious == rOut", "zPrevious != rOut"),
    Mutant("mergesign", BM, "inverted[e] ^= 1", "inverted[e] ^= 0", mode="stmt"),
    Mutant("futurechild", BM, "lowpoint[c] >= v || !isSeparated(c)", "lowpoint[c] >= v"),
    Mutant("futureleast", BM, "if leastAncestor[w] < v { return true }", "if leastAncestor[w] < v { return false }", mode="stmt"),

    # Kuratowski isolation: choosing the minor.
    Mutant("minora", KI, "vertex(ofRoot: r) != v", "vertex(ofRoot: r) == v"),
    Mutant("minorb", KI, "lowpoint[rootPrevious[pertinentRoots[w]]] < v", "lowpoint[rootPrevious[pertinentRoots[w]]] > v"),
    Mutant("minorc", KI, "mark[context.px] == _FaceMark.highRXW || mark[context.py] == _FaceMark.highRYW", "mark[context.px] == _FaceMark.highRXW && mark[context.py] == _FaceMark.highRYW"),
    Mutant("minord", KI, "context.z != -1", "false"),
    Mutant("activex", KI, "isInactive(x, v)", "false"),
    Mutant("pertinentw", KI, "if isPertinent(w) { return w }", "if isPertinent(w) && w == -2 { return w }", mode="stmt"),
    Mutant("facemarklow", KI, "if z == context.x { type = _FaceMark.lowRXW }", "if z == context.w { type = _FaceMark.lowRXW }", mode="stmt"),
    Mutant("xypathpx", KI, "                    context.px = z\n                    popAndUnmark(-1, bottom2)", "                    context.px = z", mode="stmt"),
    Mutant("xypathloop", KI, "                popAndUnmark(z, bottom2)", "                _ = z", mode="stmt"),
    Mutant("ztorpath", KI, "        if z == py { return }", "        if z != py { return }", mode="stmt"),
    Mutant("futurebelow", KI, "if isFuturePertinent(z, v) { return z }", "if isFuturePertinent(z, v) && z == -2 { return z }", mode="stmt"),
    Mutant("ancestorchild", KI, "isSeparated(c) && ancestor > lowpoint[c]", "isSeparated(c) && ancestor < lowpoint[c]"),
    Mutant("subtreeleast", KI, "if d >= subtree && (descendant == -1 || d < descendant) { descendant = d }", "if d >= subtree && (descendant == -1 || d > descendant) { descendant = d }", mode="stmt"),

    # Kuratowski isolation: the marking of each minor.
    Mutant("marka", KI, "        markPathAlongExternalFace(c.r, c.r)\n        markTreePath(Swift.min(c.ux, c.uy), c.r)\n        markTreePathsToDescendants()", "        markPathAlongExternalFace(c.r, c.r)\n        markTreePathsToDescendants()", mode="stmt"),
    Mutant("markb", KI, "markTreePath(Swift.min(c.ux, c.uy, c.uz), Swift.max(c.ux, c.uy, c.uz))", "markTreePath(Swift.min(c.ux, c.uy), Swift.max(c.ux, c.uy))", nth=0, mode="stmt"),
    Mutant("markchigh", KI, "            markPathAlongExternalFace(c.r, highY)", "            markPathAlongExternalFace(c.r, c.y)", mode="stmt"),
    Mutant("marcclow", KI, "            markPathAlongExternalFace(c.x, c.r)", "            markPathAlongExternalFace(c.y, c.r)", mode="stmt"),
    Mutant("markd", KI, "        markPathAlongExternalFace(c.x, c.y)", "", mode="stmt"),
    Mutant("marke1x", KI, "                mark[c.px] = _FaceMark.highRXW", "", mode="stmt"),
    Mutant("marke2", KI, "            context.dw = c.dz", "", mode="stmt"),
    Mutant("marke3", KI, "                markPathAlongExternalFace(c.r, c.px)\n                markPathAlongExternalFace(c.w, c.y)", "                markPathAlongExternalFace(c.r, c.px)", mode="stmt"),
    Mutant("marke3other", KI, "                markPathAlongExternalFace(c.x, c.w)\n                markPathAlongExternalFace(c.py, c.r)", "                markPathAlongExternalFace(c.x, c.w)", mode="stmt"),
    Mutant("marke4", KI, "                markPathAlongExternalFace(c.r, c.w)\n                markPathAlongExternalFace(c.py, c.r)", "                markPathAlongExternalFace(c.r, c.w)", mode="stmt"),
    Mutant("marke4other", KI, "                markPathAlongExternalFace(c.r, c.px)\n                markPathAlongExternalFace(c.w, c.r)", "                markPathAlongExternalFace(c.r, c.px)", mode="stmt"),
    Mutant("markk5", KI, "        // K₅.\n        markPathAlongExternalFace(c.r, c.r)\n        markTreePath(Swift.min(c.ux, c.uy, c.uz), c.r)", "        // K₅.\n        markPathAlongExternalFace(c.r, c.r)", mode="stmt"),
    Mutant("markunembedded", KI, "        if c.dz != -1 { markUnembeddedEdge(c.uz, c.dz) }", "        _ = c", mode="stmt"),
    Mutant("marktreew", KI, "        if c.dw != -1 { markTreePath(c.w, c.dw) }", "        _ = c", mode="stmt"),

    # The witness's presentation.
    Mutant("k33sides", KS, "order = [first] + branch.filter { $0 != first && !across.contains($0) } + branch.filter { across.contains($0) }", "order = [first] + branch.filter { across.contains($0) } + branch.filter { $0 != first && !across.contains($0) }", mode="stmt"),
    Mutant("witnessorder", KS, "witness.map { simple.representative[$0] }.sorted()", "witness.map { simple.representative[$0] }"),

    # The checked: face spellings.
    Mutant("checkedfacevertex", "PlanarEmbedding.swift", "try? _vertices.number(checked: vertex)", "Optional((try? _vertices.number(checked: vertex)) ?? 0)"),
    Mutant("checkedfacerange", "PlanarEmbedding.swift", "edges.startIndex <= position && position < edges.endIndex", "true"),
    Mutant("checkedfacenumber", "PlanarEmbedding.swift", "_edgeNumbers[position]", "Optional(_edgeNumbers[position] ?? 0)", nth=1),
    Mutant("checkedfaceedge", "PlanarEmbedding.swift", "e >= 0 && e < _layout.edgeCount", "true", nth=1),
    Mutant("checkedfaceslot", "PlanarEmbedding.swift", "_layout.face(fromSlot: try _checkedSlot(from: vertex, alongEdgeAt: position))", "_layout.face(fromSlot: try _checkedSlot(from: vertex, alongEdgeAt: position) ^ 1)"),
    Mutant("checkedrightface", "PlanarEmbedding.swift", "Int(_layout.faceOfSlot[try _checkedSlot(from: vertex, alongEdgeAt: position)])", "Int(_layout.faceOfSlot[0])"),
    # The dual graph
    Mutant("dual_first_slot", "DualGraph.swift", "                    if firstSlot[e] < 0 { firstSlot[e] = q }", "                    firstSlot[e] = q", mode="stmt"),
    Mutant("dual_left", "DualGraph.swift", "UndirectedEdge(Int(_layout.faceOfSlot[q]), Int(_layout.faceOfSlot[Int(_layout.twin[q])]))", "UndirectedEdge(Int(_layout.faceOfSlot[Int(_layout.twin[q])]), Int(_layout.faceOfSlot[q]))"),
    Mutant("dual_twin", "DualGraph.swift", "Int(_layout.faceOfSlot[Int(_layout.twin[q])])", "Int(_layout.faceOfSlot[q])", nth=1),
    Mutant("dual_vertices", "DualGraph.swift", "0 ..< faceCount", "0 ..< Swift.max(faceCount, 1)"),
]
