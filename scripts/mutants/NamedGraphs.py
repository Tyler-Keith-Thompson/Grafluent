# Planted bugs for NamedGraphs and the bulk initializers it builds through, in the other modules'
# Construction files (module=...): CompressedSparseRow, AdjacencyMatrix, the adjacency lists'
# sorted rows, the multigraphs' parallel classes, StableDirectedGraph, BipartiteGraph's known sides
# and Tree's dense layout. Run with `just mutate NamedGraphs`; see scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#
# Removed checks that leave a trap at the same call (an exit test passes either way): Swift's
# overflow trap on the arithmetic the check guards, or a later precondition that the bad value fails.
#   productfits, unorderednil, bipartitesum, bipartiteproduct, gridvertexoverflow, gridedgeoverflow,
#   griddirectedoverflow, cubeoverflow, cubelarge, wheeloverflow — the product, sum or doubling right
#   after the check overflows and traps.
#   bipartiteleft, bipartiteright — a negative side fails `_productFits` (a·b against Int.max / a < 0)
#   or overflows Int.max − b.
#   cubenegative — d < 0 makes 1 << d zero, and `_productFits(d, 0)` with d < 0 is false.
#   laddercount — `_bothArcs` and the conformers trap on 2n + 1 < 0 rows.
#   barbellpathcount, balancedr — Int.max − p (p < 0) and Int.max − level (level < 0) overflow.
#   emptycount, completecount, pathcount — the conformers trap on a negative vertex count.
#   orderednil, completeoverflow, completedioverflow — the pair collection's endIndex multiplies
#   n(n − 1) and overflows as soon as anything reads it (the conformers' `_isSortedSimple`
#   assertion does at the first edge).
#   treepathcheck, treestarcheck — `0 ..< n − 1` traps for n = 0; treecheck — Tree's own check is
#   behind those of every caller (path, star, balanced tree, random tree).
#   laddercircmin — circularLadder(rungCount: 2) repeats the edge 0–1, which the conformers'
#   `_isSortedSimple` assertion traps on in the debug builds the tests run.
# Checks no test can reach: the inputs that tell them apart need about 2⁶³ edges allocated.
#   productedge (b == Int.max / a exactly), unorderedhalves (n(n − 1) overflows while n(n − 1)/2 fits).
# Same value by arithmetic.
#   unorderedsmall, orderedsmall, ascendingsmall, distinctend — n = 0 or 1 give 0 without the guard;
#   distinctsmall — the iterator ends at once for n < 2 with either bound; rowpoolstart — offsets[v + 1]
#   − length is offsets[v]; gridwritten — a self-check that the count formula matches the loop.
# The position subscript's corrections: the root estimate is exact for every n the suites reach, so
#   the loops that correct it never run (ascendingroot, ascendingdown, ascendingup).
# Layout and capacity only: stablereserve, treesingle
#   (the one-vertex layout, which the general layout equals).
# The later families.
#   circloop, lcfloop — an offset or shift that is a multiple of n gives the pair (u, u), which the
#   conformers' `_isSortedSimple` assertion traps on in the debug builds the tests run; gpcycle —
#   n = 2 fails the next check, 2k < n; treeraryempty — reserving 2(n − 1) < 0 ends traps, as Tree's
#   own check would; bruijnalphabet — m = 0 divides by m; kautzlength — `0 ..< length − 1` traps.
#   kneserlarger — a subset's rank equals u only for the subset itself, which is not disjoint from
#   itself (k ≥ 1), so `rank >= u` keeps the same neighbors.
#   hexpresent — low(i + 1) is 1 only for the last column of an even n, and row 0 joins column i to
#   i + 1 only for even i, while the last column's left neighbor n − 1 is odd.

TESTS = ["NamedGraphsTests"]

CG = "CompleteGraphs.swift"
EG = "EmptyGraph.swift"
LA = "Lattices.swift"
PC = "PairCollections.swift"
PA = "PathsAndCycles.swift"
PE = "PetersenGraph.swift"
PR = "Preconditions.swift"
LD = "Ladders.swift"
BB = "BarbellAndLollipop.swift"
CM = "CompleteMultipartite.swift"
BT = "BalancedTree.swift"

MUTANTS = [
    # Size checks.
    Mutant("checkcount", PR, "count >= 0", "count >= 1"),
    Mutant("checkcountoff", PR, "count >= 0", "true"),
    Mutant("productfits", PR, "a == 0 || b <= Int.max / a", "true"),
    Mutant("productedge", PR, "b <= Int.max / a", "b < Int.max / a"),
    Mutant("unorderedsmall", PR, "n >= 2", "n >= 0", nth=0),
    Mutant("orderedsmall", PR, "n >= 2", "n >= 0", nth=1),
    Mutant("unorderedhalves", PR, "n.isMultiple(of: 2) ? (n / 2, n - 1) : (n, (n - 1) / 2)", "(n, n - 1)"),
    Mutant("unorderednil", PR, "_productFits(a, b) ? a * b : nil", "Optional(a &* b)"),
    Mutant("orderednil", PR, "_productFits(n, n - 1) ? n * (n - 1) : nil", "Optional(n &* (n - 1))"),

    # Complete graphs and K_{a,b}.
    Mutant("completecount", CG, "_checkCount(n)", "", mode="stmt", nth=0),
    Mutant("completeoverflow", CG, '        precondition(_unorderedPairCount(n) != nil, "edge count overflows Int")', "", mode="stmt"),
    Mutant("completedicount", CG, "_checkCount(n)", "", mode="stmt", nth=1),
    Mutant("completedioverflow", CG, '        precondition(_orderedPairCount(n) != nil, "edge count overflows Int")', "", mode="stmt"),
    Mutant("bipartiteleft", CG, '_checkCount(a, "leftCount")', "", mode="stmt"),
    Mutant("bipartiteright", CG, '_checkCount(b, "rightCount")', "", mode="stmt"),
    Mutant("bipartitesum", CG, "a <= Int.max - b && _productFits(a, b)", "_productFits(a, b)"),
    Mutant("bipartiteproduct", CG, "a <= Int.max - b && _productFits(a, b)", "a <= Int.max - b"),
    Mutant("bipartiteundirected", CG, "_CrossPairs(a, b)", "_CrossPairs(b, a)"),
    Mutant("bipartitesides", CG, "BipartiteGraph(_leftCount: a, graph: UndirectedAdjacencyList<Int>.completeBipartite(leftCount: a, rightCount: b))", "BipartiteGraph(_leftCount: b, graph: UndirectedAdjacencyList<Int>.completeBipartite(leftCount: a, rightCount: b))"),

    # The lazy pair collections.
    Mutant("ascendingsmall", PC, "n < 2 ? 0 : (n.isMultiple(of: 2) ? (n / 2) * (n - 1) : n * ((n - 1) / 2))", "n.isMultiple(of: 2) ? n / 2 * (n - 1) : (n - 1) / 2 * n"),
    Mutant("ascendingend", PC, "n * ((n - 1) / 2)", "n * ((n + 1) / 2)"),
    Mutant("rowstart", PC, "a.isMultiple(of: 2) ? (a / 2) * b : a * (b / 2)", "a * (b / 2)"),
    Mutant("ascendingroot", PC, "u = Swift.max(0, Swift.min(u, n - 2))", "u = Swift.max(0, Swift.min(u + 1, n - 2))", mode="stmt"),
    Mutant("ascendingdown", PC, "while u > 0, rowStart(u) > position { u -= 1 }", "", mode="stmt"),
    Mutant("ascendingup", PC, "while u < n - 2, rowStart(u + 1) <= position { u += 1 }", "", mode="stmt"),
    Mutant("ascendingat", PC, "DirectedEdge(from: u, to: u + 1 + position - rowStart(u))", "DirectedEdge(from: u, to: u + position - rowStart(u))"),
    Mutant("ascendingrowend", PC, "u &+ 2 < n", "u < n &- 1"),
    Mutant("ascendingnext", PC, "                v = u &+ 1", "                v = u", mode="stmt"),
    Mutant("distinctat", PC, "DirectedEdge(from: u, to: r < u ? r : r + 1)", "DirectedEdge(from: u, to: r <= u ? r : r + 1)"),
    Mutant("distinctsmall", PC, "n < 2 ? 0 : n", "n", nth=1),
    Mutant("distinctrow", PC, "u &+ 1 < n", "u < n &- 2"),
    Mutant("distinctskip", PC, "            if v == u { v &+= 1 }", "", mode="stmt"),
    Mutant("distinctlast", PC, "            if v >= n {\n                // u = n − 1 ended its row at v = u.\n                return nil\n            }", "", mode="stmt"),
    Mutant("distinctend", PC, "n < 2 ? 0 : n * (n - 1)", "n * (n - 1)"),
    Mutant("crossat", PC, "DirectedEdge(from: position / b, to: a + position % b)", "DirectedEdge(from: position % a, to: a + position / a)"),
    Mutant("crossempty", PC, "b == 0 ? 0 : a", "a"),
    Mutant("crossrow", PC, "                v = a", "                v = 0", mode="stmt"),
    Mutant("crossend", PC, "u < a", "u <= a"),
    Mutant("undirectedswap", PC, "UndirectedEdge(pair.source, pair.target)", "UndirectedEdge(pair.target, pair.source)"),

    # Grids.
    Mutant("gridempty", LA, 'precondition(!dimensions.isEmpty, "grid needs at least one dimension")', "", mode="stmt"),
    Mutant("gridnegative", LA, "d >= 0", "true", nth=0),
    Mutant("gridvertexoverflow", LA, '        precondition(_productFits(n, d), "vertex count overflows Int")', "", mode="stmt"),
    Mutant("gridnull", LA, "    guard n > 0 else { return (0, []) }", "", mode="stmt"),
    Mutant("gridwrapcount", LA, "(periodic && d >= 3 ? d : d - 1) * (n / d)", "(periodic && d >= 2 ? d : d - 1) * (n / d)"),
    Mutant("gridwrapcountoff", LA, "(periodic && d >= 3 ? d : d - 1) * (n / d)", "(d - 1) * (n / d)"),
    Mutant("gridedgeoverflow", LA, '        precondition(m <= Int.max - term, "edge count overflows Int")', "", mode="stmt"),
    Mutant("griddirectedoverflow", LA, '        precondition(m <= Int.max / 2, "edge count overflows Int")', "", mode="stmt"),
    Mutant("griddirectedcount", LA, "        m *= 2", "", mode="stmt"),
    Mutant("gridstride", LA, "strides[i] = strides[i + 1] * dimensions[i + 1]", "strides[i] = strides[i + 1] * dimensions[i]", mode="stmt"),
    Mutant("gridbackwrap", LA, "x == d - 1", "x == d - 2"),
    Mutant("gridbackwrapto", LA, "DirectedEdge(from: v, to: v - (d - 1) * s)", "DirectedEdge(from: v, to: v - d * s)"),
    Mutant("gridback", LA, "x > 0", "x > 1"),
    Mutant("gridbackto", LA, "DirectedEdge(from: v, to: v - s)", "DirectedEdge(from: v, to: v - 1)"),
    Mutant("gridforward", LA, "x + 1 < d", "x + 2 < d"),
    Mutant("gridforwardto", LA, "DirectedEdge(from: v, to: v + s)", "DirectedEdge(from: v, to: v + 1)"),
    Mutant("gridforwardwrap", LA, "x == 0", "x == 1"),
    Mutant("gridforwardwrapto", LA, "DirectedEdge(from: v, to: v + (d - 1) * s)", "DirectedEdge(from: v, to: v + d * s)"),
    Mutant("gridorder", LA, "stride(from: k - 1, through: 0, by: -1)", "stride(from: 0, through: k - 1, by: 1)"),
    Mutant("gridodometer", LA, "                coordinates[i] = 0", "", mode="stmt"),
    Mutant("gridodometerbreak", LA, "coordinates[i] < dimensions[i]", "coordinates[i] <= dimensions[i]"),
    Mutant("gridwritten", LA, '        precondition(written == m, "grid edge count")', "", mode="stmt"),

    # Hypercubes.
    Mutant("cubenegative", LA, "d >= 0", "true", nth=1),
    Mutant("cubelarge", LA, "d <= Int.bitWidth - 2", "d <= Int.bitWidth - 1"),
    Mutant("cubeoverflow", LA, '    precondition(_productFits(d, directed ? n : n / 2), "edge count overflows Int")', "", mode="stmt"),
    Mutant("cubedown", LA, "                bit -= 1", "                bit -= 2", mode="stmt"),
    Mutant("cubedownset", LA, "v >> bit & 1 == 1", "v >> bit & 1 != 1"),
    Mutant("cubedownto", LA, "DirectedEdge(from: v, to: v ^ (1 << bit))", "DirectedEdge(from: v, to: v)"),
    Mutant("cubeupclear", LA, "v >> bit & 1 == 0", "v >> bit & 1 != 0"),
    Mutant("cubeup", LA, "DirectedEdge(from: v, to: v | (1 << bit))", "DirectedEdge(from: v, to: v | (2 << bit))"),

    # Paths, cycles, stars, wheels.
    Mutant("pathcount", PA, "_checkCount(n)", "", mode="stmt"),
    Mutant("pathsmall", PA, "n >= 2", "n >= 3"),
    Mutant("pathedge", PA, "DirectedEdge(from: $0, to: $0 + 1)", "DirectedEdge(from: $0, to: $0 + 2)"),
    Mutant("cyclesmall", PA, "n >= 3", "n >= 2", nth=1),
    Mutant("cyclearcs", PA, "for i in 0 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", "for i in 1 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", mode="stmt"),
    Mutant("cycleclosearc", PA, "DirectedEdge(from: n - 1, to: 0)", "DirectedEdge(from: 0, to: n - 1)"),
    Mutant("cyclefirst", PA, "        pairs.append(DirectedEdge(from: 0, to: 1))", "", mode="stmt"),
    Mutant("cycleclose", PA, "        pairs.append(DirectedEdge(from: 0, to: n - 1))", "        pairs.append(DirectedEdge(from: 1, to: n - 1))", mode="stmt"),
    Mutant("cyclerest", PA, "for i in 1 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", "for i in 2 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", mode="stmt", nth=1),
    Mutant("starsmall", PA, "n >= 1", "n >= 2", nth=0),
    Mutant("starhub", PA, "(1 ..< n).map { DirectedEdge(from: 0, to: $0) }", "(2 ..< n).map { DirectedEdge(from: 1, to: $0) }"),
    Mutant("wheelsmall", PA, "n >= 4", "n >= 3"),
    Mutant("wheeloverflow", PA, '    precondition(n - 1 <= Int.max / 2, "edge count overflows Int")', "", mode="stmt"),
    Mutant("wheelspokes", PA, "for i in 1 ..< n { pairs.append(DirectedEdge(from: 0, to: i)) }", "for i in 2 ..< n { pairs.append(DirectedEdge(from: 0, to: i)) }", mode="stmt"),
    Mutant("wheelrimarcs", PA, "for i in 1 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", "for i in 2 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", mode="stmt", nth=2),
    Mutant("wheelclosearc", PA, "DirectedEdge(from: n - 1, to: 1)", "DirectedEdge(from: 1, to: n - 1)"),
    Mutant("wheelfirst", PA, "        pairs.append(DirectedEdge(from: 1, to: 2))", "", mode="stmt"),
    Mutant("wheelclose", PA, "        pairs.append(DirectedEdge(from: 1, to: n - 1))", "", mode="stmt", nth=1),
    Mutant("wheelrest", PA, "for i in 2 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", "for i in 3 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", mode="stmt", nth=2),
    Mutant("treepathcheck", PA, 'precondition(n >= 1, "a Tree has at least one vertex")', "", mode="stmt", nth=0),
    Mutant("treepath", PA, "            ends.append(k + 1)", "            ends.append(n - 1 - k)", mode="stmt"),
    Mutant("treestarcheck", PA, 'precondition(n >= 1, "a Tree has at least one vertex")', "", mode="stmt", nth=1),
    Mutant("treestar", PA, "            ends.append(0)", "            ends.append(n - 1)", mode="stmt"),

    # Ladders and circular ladders.
    Mutant("laddercircmin", LD, "n >= 3", "n >= 2"),
    Mutant("laddercount", LD, '_checkCount(n, "rungCount")', "", mode="stmt"),
    Mutant("ladderempty", LD, "    guard n >= 1 else { return [] }", "", mode="stmt"),
    Mutant("ladderrailfirst", LD, "rail * n", "rail * (n - 1)"),
    Mutant("ladderrail", LD, "i < last", "i < last - 1"),
    Mutant("ladderclose", LD, "i == first", "i == last"),
    Mutant("ladderrung", LD, "rail == 0", "rail == 1"),
    Mutant("ladderrungto", LD, "DirectedEdge(from: i, to: i + n)", "DirectedEdge(from: i, to: i + n - 1)"),
    Mutant("laddervertices", LD, "Self(_vertexCount: 2 * n, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())", "Self(_vertexCount: 2 * n + 1, sortedEdges: pairs.lazy.map(_undirected), _ConstructionToken())", nth=0),
    Mutant("ladderarcs", LD, "_bothArcs(vertexCount: 2 * n, pairs)", "pairs", nth=0),
    Mutant("circladderarcs", LD, "_bothArcs(vertexCount: 2 * n, pairs)", "pairs", nth=1),

    # Barbells and lollipops.
    Mutant("barbellmin", BB, "k >= 2", "k >= 1"),
    Mutant("barbellpathcount", BB, '_checkCount(p, "pathVertexCount")', "", mode="stmt"),
    Mutant("barbellcliques", BB, "twoCliques ? 2 : 1", "1"),
    Mutant("barbellvertices", BB, "cliques * k + p", "cliques * k + p + 1"),
    Mutant("barbellclique", BB, "u + 1 ..< k", "u + 1 ..< Swift.max(u + 1, k - 1)"),
    Mutant("barbellpathstart", BB, "pairs.append(DirectedEdge(from: i, to: i + 1))", "if i >= k { pairs.append(DirectedEdge(from: i, to: i + 1)) }", mode="stmt"),
    Mutant("barbellpathend", BB, "twoCliques ? 0 : 1", "0"),
    Mutant("barbellsecond", BB, "first ..< n", "first + 1 ..< n"),
    Mutant("barbellsecondrow", BB, "u + 1 ..< n", "Swift.min(u + 2, n) ..< n"),
    Mutant("barbellarcs", BB, "_bothArcs(vertexCount: n, pairs)", "pairs", nth=0),
    Mutant("lollipoparcs", BB, "_bothArcs(vertexCount: n, pairs)", "pairs", nth=1),

    # Both arcs of each pair, by counting placement.
    Mutant("botharcssource", PC, "        fill[pair.source + 1] += 1", "", mode="stmt"),
    Mutant("botharcstarget", PC, "        fill[pair.target + 1] += 1", "", mode="stmt"),
    Mutant("botharcsprefix", PC, "    for v in 0 ..< n { fill[v + 1] += fill[v] }", "", mode="stmt"),
    Mutant("botharcsback", PC, "DirectedEdge(from: pair.target, to: pair.source)", "DirectedEdge(from: pair.source, to: pair.target)"),
    Mutant("botharcsbackfill", PC, "            fill[pair.target] += 1", "", mode="stmt"),
    Mutant("botharcsforwardfill", PC, "            fill[pair.source] += 1", "", mode="stmt"),

    # Complete multipartite and Turán graphs.
    Mutant("multicheck", CM, '_checkCount(size, "part size")', "", mode="stmt"),
    Mutant("multiskip", CM, "        guard size > 0 else { continue }", "", mode="stmt"),
    Mutant("multicount", CM, "m += size * n", "m += size * n + 1", mode="stmt"),
    Mutant("multiadvance", CM, "        n += size", "", mode="stmt"),
    Mutant("turanrange", CM, "1 <= r && r <= n", "1 <= r"),
    Mutant("turanorder", CM, "[Int](repeating: small, count: r - large) + [Int](repeating: small + 1, count: large)", "[Int](repeating: small + 1, count: large) + [Int](repeating: small, count: r - large)"),
    Mutant("multidirectedbip", CG, "_CrossPartArcs(_multipartitePairs([a, b]))", "_CrossPartArcs(_multipartitePairs([b, a]))"),
    Mutant("multistart", PC, "ends.count < 2 ? endIndex : Index(u: 0, v: ends[0], part: 0)", "Index(u: 0, v: ends.isEmpty ? 0 : ends[0], part: 0)", nth=0),
    Mutant("multinext", PC, "i.v &+ 1 < n", "i.v &+ 2 < n"),
    Mutant("multipart", PC, "u == ends[i.part] ? i.part &+ 1 : i.part", "i.part", nth=0),
    Mutant("multilast", PC, "part < ends.count &- 1", "part < ends.count"),
    Mutant("multirow", PC, "Index(u: u, v: ends[part], part: part)", "Index(u: u, v: ends[part] &+ 1, part: part)"),
    Mutant("crossarcscount", PC, "count = 2 * pairs.count", "count = pairs.count", mode="stmt"),
    Mutant("crossarcsstart", PC, "ends.count < 2 ? endIndex : Index(u: 0, v: ends[0], part: 0)", "Index(u: 0, v: ends.isEmpty ? 0 : ends[0], part: 0)", nth=1),
    Mutant("crossarcsskip", PC, "        if v == (i.part == 0 ? 0 : ends[i.part &- 1]) { v = ends[i.part] }", "", mode="stmt"),
    Mutant("crossarcsskipstart", PC, "i.part == 0 ? 0 : ends[i.part &- 1]", "0"),
    Mutant("crossarcsnext", PC, "if v < n { return Index(u: i.u, v: v, part: i.part) }", "if v < n &- 1 { return Index(u: i.u, v: v, part: i.part) }", mode="stmt"),
    Mutant("crossarcspart", PC, "u == ends[i.part] ? i.part &+ 1 : i.part", "i.part", nth=1),
    Mutant("crossarcsrow", PC, "part == 0 ? ends[0] : 0", "ends[0]"),

    # Balanced trees.
    Mutant("balancedr", BT, '_checkCount(r, "branchingFactor")', "", mode="stmt"),
    Mutant("balancedlevel", BT, "        guard level > 0 else { break }", "", mode="stmt"),
    Mutant("balancedmul", BT, "        level *= r", "        level += r", mode="stmt"),
    Mutant("balancedparent", BT, "DirectedEdge(from: ($0 - 1) / r, to: $0)", "DirectedEdge(from: $0 / r, to: $0)"),
    Mutant("balancedtreeends", BT, "ends.append((c - 1) / r)", "ends.append(c - 1)", mode="stmt"),

    # Petersen and empty.
    Mutant("petersenpair", PE, "DirectedEdge(from: $0.0, to: $0.1)", "DirectedEdge(from: $0.0, to: $0.0 == 5 && $0.1 == 7 ? 6 : $0.1)"),
    Mutant("petersensorted", PE, "(_petersenPairs + _petersenPairs.map { DirectedEdge(from: $0.target, to: $0.source) }).sorted()", "_petersenPairs + _petersenPairs.map { DirectedEdge(from: $0.target, to: $0.source) }"),
    Mutant("petersenarcs", PE, "_petersenPairs.map { DirectedEdge(from: $0.target, to: $0.source) }", "_petersenPairs", nth=1),
    Mutant("emptycount", EG, "_checkCount(n)", "", mode="stmt", nth=0),
    Mutant("emptydicount", EG, "_checkCount(n)", "", mode="stmt", nth=1),

    # CompressedSparseRow's one-pass build.
    Mutant("csrrowend", "CompressedSparseRow+Construction.swift", "offsets[row] = k", "offsets[row] = k &+ 1", mode="stmt", nth=0, module="CompressedSparseRowModule"),
    Mutant("csrtarget", "CompressedSparseRow+Construction.swift", "targets.initializeElement(at: k, to: edge.target)", "targets.initializeElement(at: k, to: edge.source)", mode="stmt", module="CompressedSparseRowModule"),
    Mutant("csrtail", "CompressedSparseRow+Construction.swift", "                while row < n {\n                    row &+= 1\n                    offsets[row] = k\n                }", "", mode="stmt", module="CompressedSparseRowModule"),

    # AdjacencyMatrix's build.
    Mutant("matrixbit", "AdjacencyMatrix+Construction.swift", "Self._mask(target)", "Self._mask(source)", module="AdjacencyMatrixModule"),
    Mutant("matrixout", "AdjacencyMatrix+Construction.swift", "                    degrees[Self._outSlot(source)] &+= 1", "", mode="stmt", module="AdjacencyMatrixModule"),
    Mutant("matrixin", "AdjacencyMatrix+Construction.swift", "                    degrees[inBase &+ target] &+= 1", "", mode="stmt", module="AdjacencyMatrixModule"),
    Mutant("matrixcount", "AdjacencyMatrix+Construction.swift", "_edgeCount = count", "_edgeCount = 0", mode="stmt", module="AdjacencyMatrixModule"),

    # The adjacency lists' sorted rows.
    Mutant("rowpoolcapacity", "SortedConstruction.swift", "_Row(start: offsets[v], count: length, capacity: length)", "_Row(start: offsets[v], count: length, capacity: length + 1)", module="AdjacencyListModule"),
    Mutant("rowpoolstart", "SortedConstruction.swift", "_Row(start: offsets[v], count: length, capacity: length)", "_Row(start: offsets[v + 1] - length, count: length, capacity: length)", module="AdjacencyListModule"),
    Mutant("arcoutdegree", "SortedConstruction.swift", "            outOffsets[edge.source &+ 1] &+= 1", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcindegree", "SortedConstruction.swift", "            inOffsets[edge.target &+ 1] &+= 1", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcoutprefix", "SortedConstruction.swift", "            outOffsets[v &+ 1] &+= outOffsets[v]", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcinprefix", "SortedConstruction.swift", "            inOffsets[v &+ 1] &+= inOffsets[v]", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcinsource", "SortedConstruction.swift", "inStorage.initializeElement(at: slot, to: source)", "inStorage.initializeElement(at: slot, to: target)", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcinedge", "SortedConstruction.swift", "inEdgeStorage.initializeElement(at: slot, to: position)", "inEdgeStorage.initializeElement(at: slot, to: 0)", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcrecordout", "SortedConstruction.swift", "position &- outOffsets[source]", "position", module="AdjacencyListModule"),
    Mutant("arcrecordin", "SortedConstruction.swift", "slot &- inOffsets[target]", "slot", module="AdjacencyListModule"),
    Mutant("arcoutedges", "SortedConstruction.swift", "ContiguousArray(0 ..< m)", "ContiguousArray((0 ..< m).reversed())", module="AdjacencyListModule"),
    Mutant("edgedegree", "SortedConstruction.swift", "            offsets[edge.v &+ 1] &+= 1", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgeprefix", "SortedConstruction.swift", "        for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgeuneighbor", "SortedConstruction.swift", "neighborStorage[uSlot] = v", "neighborStorage[uSlot] = u", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgevincident", "SortedConstruction.swift", "incidentStorage[vSlot] = position", "incidentStorage[vSlot] = 0", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgerecord", "SortedConstruction.swift", "_EdgeRecord(u: u, v: v, uOffset: uSlot &- offsets[u], vOffset: vSlot &- offsets[v])", "_EdgeRecord(u: u, v: v, uOffset: vSlot &- offsets[v], vOffset: uSlot &- offsets[u])", module="AdjacencyListModule"),
    Mutant("listslots", "SortedConstruction.swift", "_VertexSlots(identityCount: n)", "_VertexSlots(identityCount: Swift.max(0, n - 1))", nth=0, module="AdjacencyListModule"),
    Mutant("listpairs", "SortedConstruction.swift", "        _deferredEdges = rows.records.isEmpty ? nil : _DeferredSlotPairTable(records: rows.records)", "        _deferredEdges = nil", mode="stmt", nth=0, module="AdjacencyListModule"),
    Mutant("undirectedslots", "SortedConstruction.swift", "_VertexSlots(identityCount: n)", "_VertexSlots(identityCount: Swift.max(0, n - 1))", nth=1, module="AdjacencyListModule"),
    Mutant("undirectedpairs", "SortedConstruction.swift", "        _positions._insertDistinct(count: records.count) { (_SlotPair(records[$0].u, records[$0].v), $0) }", "", mode="stmt", nth=0, module="AdjacencyListModule"),

    # The multigraphs' single-copy classes.
    Mutant("parallellinks", "SortedConstruction.swift", "ContiguousArray(repeating: _ParallelLinks(previous: -1, next: -1), count: count)", "ContiguousArray(repeating: _ParallelLinks(previous: -1, next: -1), count: 0)", module="Multigraphs"),
    Mutant("parallelclasses", "SortedConstruction.swift", "for position in 0 ..< count { classes.insert(key(position), position) }", "for position in 0 ..< count { classes.insert(key(position), 0) }", mode="stmt", module="Multigraphs"),
    Mutant("pseudoslots", "SortedConstruction.swift", "_VertexSlots(identityCount: n)", "_VertexSlots(identityCount: Swift.max(0, n - 1))", nth=0, module="Multigraphs"),
    Mutant("pseudodirectedkey", "SortedConstruction.swift", "_SlotPair(records[$0].source, records[$0].target)", "_SlotPair(records[$0].target, records[$0].source)", module="Multigraphs"),
    Mutant("pseudoundirectedslots", "SortedConstruction.swift", "_VertexSlots(identityCount: n)", "_VertexSlots(identityCount: Swift.max(0, n - 1))", nth=1, module="Multigraphs"),
    Mutant("pseudoundirectedkey", "SortedConstruction.swift", "_SlotPair(records[$0].u, records[$0].v)", "_SlotPair(records[$0].v, records[$0].u)", module="Multigraphs"),

    # StableDirectedGraph.
    Mutant("stableslots", "StableDirectedGraph+Construction.swift", "for v in 0 ..< n { _appendSlot(for: v) }", "for v in (0 ..< n).reversed() { _appendSlot(for: v) }", mode="stmt", module="StableGraphs"),
    Mutant("stableedge", "StableDirectedGraph+Construction.swift", "            targets.append(edge.target)", "            targets.append(edge.source)", mode="stmt", module="StableGraphs"),
    Mutant("stablereserve", "StableDirectedGraph+Construction.swift", "        reserveCapacity(vertexCount: n, edgeCount: edges.count)", "", mode="stmt", module="StableGraphs"),

    # BipartiteGraph's known sides.
    Mutant("sidesleft", "Construction.swift", "[BipartiteSide](repeating: .left, count: a) + [BipartiteSide](repeating: .right, count: n - a)", "[BipartiteSide](repeating: .right, count: a) + [BipartiteSide](repeating: .left, count: n - a)", module="BipartiteGraphs"),
    Mutant("sidesleftlist", "Construction.swift", "Array(0 ..< a)", "Array((0 ..< a).reversed())", nth=0, module="BipartiteGraphs"),
    Mutant("sidesrightlist", "Construction.swift", "Array(a ..< n)", "Array((a ..< n).reversed())", module="BipartiteGraphs"),
    Mutant("sidesoffset", "Construction.swift", "_sideOffset = Array(0 ..< a) + Array(0 ..< n - a)", "_sideOffset = Array(0 ..< n)", module="BipartiteGraphs"),

    # Tree's dense layout.
    Mutant("treesingle", "Construction.swift", "        if n == 1 {\n            self.init(_layout: .single(0))\n            return\n        }", "", mode="stmt", module="Trees"),
    Mutant("treecheck", "Construction.swift", '        precondition(n >= 1, "A Tree has at least one vertex")', "", mode="stmt", module="Trees"),
    # The counting sort of unordered pairs.
    Mutant("sortedlarger", "SortedPairs.swift", "offsets[Swift.max(pair.source, pair.target) &+ 1] &+= 1", "offsets[Swift.min(pair.source, pair.target) &+ 1] &+= 1"),
    Mutant("sortedorient", "SortedPairs.swift", "sorted.initializeElement(at: slot, to: DirectedEdge(from: u, to: v))", "sorted.initializeElement(at: slot, to: DirectedEdge(from: v, to: u))", mode="stmt"),
    Mutant("sortedreset", "SortedPairs.swift", "    for v in 0 ... n { offsets[v] = 0 }", "", mode="stmt"),
    Mutant("sorteddedupe", "SortedPairs.swift", "kept == 0 || sorted[i] != sorted[kept &- 1]", "true"),

    # Circulant and generalized Petersen graphs.
    Mutant("circresidue", "Circulant.swift", "((o % n) + n) % n", "o % n"),
    Mutant("circloop", "Circulant.swift", "r != 0", "true", nth=0),
    Mutant("circcount", "Circulant.swift", "n >= 1", "n >= 0", nth=0),
    Mutant("gpouter", "Circulant.swift", "        pairs.append(DirectedEdge(from: i, to: (i + 1) % n))", "        pairs.append(DirectedEdge(from: i, to: (i + 2) % n))", mode="stmt"),
    Mutant("gpinner", "Circulant.swift", "DirectedEdge(from: n + i, to: n + (i + k) % n)", "DirectedEdge(from: n + i, to: n + (i + 1) % n)"),
    Mutant("gpstep", "Circulant.swift", "k >= 1 && 2 * k < n", "k >= 1 && 2 * k <= n"),
    Mutant("gpcycle", "Circulant.swift", "n >= 3", "n >= 2", nth=0),

    # Kneser graphs.
    Mutant("binomialsum", "Kneser.swift", "x <= Int.max - y ? x + y : Int.max", "x <= Int.max - y ? x + y : 0"),
    Mutant("binomialrow", "Kneser.swift", "        table[a * (k + 1)] = 1", "        table[a * (k + 1)] = a == 0 ? 1 : 0", mode="stmt"),
    Mutant("kneserrange", "Kneser.swift", "k >= 1 && k <= n", "k >= 0 && k <= n"),
    Mutant("kneserdegree", "Kneser.swift", "n - k >= k ? binomial[(n - k) * stride + k] : 0", "n - k > k ? binomial[(n - k) * stride + k] : 0"),
    Mutant("kneserrank", "Kneser.swift", "binomial[(n - 1 - complement[pick[i]]) * stride + (k - i)]", "binomial[(n - 1 - complement[pick[i]]) * stride + (k - i - 1)]"),
    Mutant("kneserfrom", "Kneser.swift", "            from = i", "            from = Swift.min(i + 1, k - 1)", mode="stmt"),
    Mutant("kneserlarger", "Kneser.swift", "rank > u", "rank >= u"),
    Mutant("knesercomplement", "Kneser.swift", "subset[j] == x", "subset[j] == x && j < k - 1"),
    Mutant("kneserpickend", "Kneser.swift", "pick[i] == n - k - k + i", "pick[i] == n - k - k + i - 1"),
    Mutant("knesernext", "Kneser.swift", "subset[i] == n - k + i", "subset[i] == n - k + i - 1"),

    # Windmills.
    Mutant("windhub", "Windmill.swift", "    for v in 1 ..< n { pairs.append(DirectedEdge(from: 0, to: v)) }", "    for v in 2 ..< n { pairs.append(DirectedEdge(from: 0, to: v)) }", mode="stmt"),
    Mutant("windstart", "Windmill.swift", "1 + j * (k - 1)", "1 + j * k"),
    Mutant("windcliques", "Windmill.swift", "cliques >= 2", "cliques >= 1"),
    Mutant("windsize", "Windmill.swift", "k >= 2", "k >= 1"),

    # Binomial and full r-ary trees.
    Mutant("binomialroot", "BinomialAndRaryTrees.swift", "p == 0 ? k : p.trailingZeroBitCount", "p.trailingZeroBitCount"),
    Mutant("binomiallow", "BinomialAndRaryTrees.swift", "p == 0 ? k : p.trailingZeroBitCount", "p == 0 ? k : p.trailingZeroBitCount + 1"),
    Mutant("binomialnegative", "BinomialAndRaryTrees.swift", "k >= 0", "true", nth=0),
    Mutant("raryparent", "BinomialAndRaryTrees.swift", "DirectedEdge(from: ($0 - 1) / r, to: $0)", "DirectedEdge(from: $0 / (r + 1), to: $0)"),
    Mutant("rarysmall", "BinomialAndRaryTrees.swift", "    guard n >= 2 else { return [] }", "    guard n >= 3 else { return [] }", mode="stmt"),
    Mutant("rarybranching", "BinomialAndRaryTrees.swift", "r >= 1", "r >= 0", nth=0),
    Mutant("treeraryparent", "BinomialAndRaryTrees.swift", "            ends.append((c - 1) / r)", "            ends.append(c / (r + 1))", mode="stmt"),
    Mutant("treeraryempty", "BinomialAndRaryTrees.swift", 'precondition(n >= 1, "a Tree has at least one vertex")', "", mode="stmt"),
    Mutant("treebinomialorder", "BinomialAndRaryTrees.swift", "            ends.append(pair.source)", "            ends.append(0)", mode="stmt"),

    # De Bruijn and Kautz graphs.
    Mutant("bruijntail", "WordGraphs.swift", "(u % tail) * m", "(u / m) * m"),
    Mutant("bruijnletters", "WordGraphs.swift", "        for a in 0 ..< m { arcs.append(DirectedEdge(from: u, to: base + a)) }", "        for a in 0 ..< m - 1 { arcs.append(DirectedEdge(from: u, to: base + a)) }", mode="stmt"),
    Mutant("bruijnalphabet", "WordGraphs.swift", "m >= 1", "m >= 0"),
    Mutant("bruijnlength", "WordGraphs.swift", "n >= 1", "n >= 0"),
    Mutant("power", "WordGraphs.swift", "        p *= m", "        p *= m + 1", mode="stmt"),
    Mutant("kautzsecond", "WordGraphs.swift", "d2 >= first ? d2 + 1 : d2", "d2 > first ? d2 + 1 : d2"),
    Mutant("kautzbase", "WordGraphs.swift", "second * tailCount + (rest % inner) * q", "second * tailCount + (rest / inner) * q"),
    Mutant("kautzsingle", "WordGraphs.swift", "v != u", "v != u + 1"),
    Mutant("kautzalphabet", "WordGraphs.swift", "s >= 2", "s >= 1"),
    Mutant("kautzlength", "WordGraphs.swift", "length >= 1", "length >= 0"),

    # Triangular and hexagonal lattices.
    Mutant("triwidth", "TriangularHexagonalLattices.swift", "short && !j.isMultiple(of: 2) ? columns : columns + 1", "short && j.isMultiple(of: 2) ? columns : columns + 1"),
    Mutant("trirow", "TriangularHexagonalLattices.swift", "        for i in 0 ..< w - 1 { pairs.append(DirectedEdge(from: here + i, to: here + i + 1)) }", "        for i in 0 ..< w - 2 { pairs.append(DirectedEdge(from: here + i, to: here + i + 1)) }", mode="stmt"),
    Mutant("trivertical", "TriangularHexagonalLattices.swift", "Swift.min(w, wa)", "Swift.max(w, wa) - 1"),
    Mutant("tridiagonaleven", "TriangularHexagonalLattices.swift", "                pairs.append(DirectedEdge(from: here + i + 1, to: above + i))", "                pairs.append(DirectedEdge(from: here + i + 1, to: above + i + 1))", mode="stmt"),
    Mutant("tridiagonalodd", "TriangularHexagonalLattices.swift", "                pairs.append(DirectedEdge(from: here + i, to: above + i + 1))", "                pairs.append(DirectedEdge(from: here + i, to: above + i))", mode="stmt"),
    Mutant("tricolumns", "TriangularHexagonalLattices.swift", "(n + 1) / 2", "n / 2 + 1"),
    Mutant("hexlow", "TriangularHexagonalLattices.swift", "i == n && n.isMultiple(of: 2) ? 1 : 0", "i == n && !n.isMultiple(of: 2) ? 1 : 0"),
    Mutant("hexhigh", "TriangularHexagonalLattices.swift", "i == 0 || (i == n && !n.isMultiple(of: 2)) ? rows - 1 : rows", "i == 0 ? rows - 1 : rows"),
    Mutant("hexcolumn", "TriangularHexagonalLattices.swift", "        for j in first ..< last - 1 { pairs.append(DirectedEdge(from: here + j, to: here + j + 1)) }", "        for j in first ..< last - 2 { pairs.append(DirectedEdge(from: here + j, to: here + j + 1)) }", mode="stmt"),
    Mutant("hexparity", "TriangularHexagonalLattices.swift", "i.isMultiple(of: 2) ? 0 : 1", "i.isMultiple(of: 2) ? 1 : 0"),
    Mutant("hexpresent", "TriangularHexagonalLattices.swift", "j >= low(i + 1)", "j >= 0"),

    # LCF notation.
    Mutant("lcfwrap", "LCF.swift", "((u + shift % n) % n + n) % n", "(u + shift + n) % n"),
    Mutant("lcfnode", "LCF.swift", "i % n", "i % (n - 1)"),
    Mutant("lcfshift", "LCF.swift", "shifts[i % shifts.count]", "shifts[(i + 1) % shifts.count]"),
    Mutant("lcfloop", "LCF.swift", "v != u", "true"),
    Mutant("lcfcycle", "LCF.swift", "    for i in 0 ..< n { pairs.append(DirectedEdge(from: i, to: (i + 1) % n)) }", "    for i in 0 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: (i + 1) % n)) }", mode="stmt"),
    Mutant("lcfrepeats", "LCF.swift", "shifts.count * r", "shifts.count * Swift.max(r - 1, 0)", nth=2),
    Mutant("lcfsmall", "LCF.swift", "n >= 3", "n >= 2"),
    Mutant("pappus", "LCF.swift", "_lcfPairs(18, [5, 7, -7, 7, -7, -5], 3)", "_lcfPairs(18, [5, 7, -7, 7, -7, -5], 2)"),
    Mutant("desargues", "LCF.swift", "_lcfPairs(20, [5, -5, 9, -9], 5)", "_lcfPairs(20, [5, -5, 9, -9], 2)"),
    Mutant("frucht", "LCF.swift", "_lcfPairs(12, [-5, -2, -4, 2, 5, -2, 2, 5, -2, -5, 4, 2], 1)", "_lcfPairs(12, [-5, -2, -4, 2, 5, -2, 2, 5, -2, -5, 4, -2], 1)"),

    # The constructions.
    Mutant("icosring", "NamedConstructions.swift", "        pairs.append(DirectedEdge(from: 1 + t, to: 6 + next))", "        pairs.append(DirectedEdge(from: 1 + t, to: 6 + (t + 2) % 5))", mode="stmt"),
    Mutant("tuttecross", "NamedConstructions.swift", "DirectedEdge(from: base + 13, to: next + 6)", "DirectedEdge(from: base + 13, to: next + 7)"),
    Mutant("tuttecentre", "NamedConstructions.swift", "        pairs.append(DirectedEdge(from: 0, to: base))", "        pairs.append(DirectedEdge(from: 0, to: base + 1))", mode="stmt"),
    Mutant("chvatal", "NamedConstructions.swift", "(9, 11)", "(8, 11)"),
    Mutant("hspentagram", "NamedConstructions.swift", "25 + 5 * h + (j + 2) % 5", "25 + 5 * h + (j + 1) % 5"),
    Mutant("hscross", "NamedConstructions.swift", "25 + 5 * i + (h * i + j) % 5", "25 + 5 * i + (h + i + j) % 5"),
]
