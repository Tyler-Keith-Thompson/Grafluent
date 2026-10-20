# Planted bugs for RandomGraphs and the known-order DirectedAcyclicGraph initializer the random DAGs
# build through (module=...). Run with `just mutate RandomGraphs`; see scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#
# Removed checks that leave a trap at the same call (an exit test passes either way):
#   gnmcount, gnpcount, gnpdicount, dagcount — a negative n reaches `0 ..< n` in the sort, or
#   complete(vertexCount:)'s check; bacount, wscount — the next precondition (m < n, k ≤ n) fails;
#   balow (m = 0 makes `1 ... 0`), bahigh (m = n makes `n + 1 ..< n`); wsnegative — [Int] of
#   negative count; treecheck — Tree's own check; sbmsize — Int.max − size overflows for a negative
#   size in the running block starts; dagoverflow, baoverflow, rgoverflow,
#   sbmoverflow, sbmbetweenoverflow — the guarded product or sum overflows and traps.
# Shortcuts the next step makes anyway:
#   gnpzero, sbmzero — p = 0 gives log(1 − p) = 0, and the `lp != 0` guard returns before a draw;
#   sbmlogzero — log(0) / lp is +∞, which fails `skip < total − t` and ends the block pair;
#   gnpend — a skip is at most 36.8 / |log(1 − p)| < 2⁵⁹ once lp ≠ 0, so `Int(skip)` never traps,
#   and the wrap loop passes the rest of the sweep in O(n);
#   gnmhalf — at 2m = N both branches pick k = m, and `k == m` returns the drawn pairs;
#   sbmrowend — with column = a the row walk's loop moves to the next row on its first pass
#   (rest ≥ 0 = a − column), which is what the original does;
#   bainsertion — the full sort and the insertion sort give the same order.
# The degree sequences and the later families:
#   rrrange — d = n takes the complement branch, whose recursive call with d = −1 traps;
#   egbound — a sum past n(n − 1) needs a degree past n − 1, which the first run's inequality
#   rejects (its left side is taken·d > k(n − 1), at least the right side); egdurfee — at d = k
#   the run takes nothing, the check repeats the last one, and the next d returns; hhlowered —
#   pushing degree-0 vertices to bucket 0 only adds rounds with no partners, since a graphical
#   sequence's partners are always found above it; bipmside — r < 2ab, so r % ab is r − ab past ab.
#   Removed checks that leave a trap at the same call: stubnegative (`repeatElement` with a
#   negative count), cmodd and dcmsums (`_built`'s unpaired
#   keys), clinfinite (the sum is infinite, which the next precondition rejects), cwstries
#   (`0 ..< tries` with tries < 0), sfsmall (n = 2 leaves vertex 2 of the cycle out of range for
#   `_built`).
#   nwsorder — a shortcut leaves the visited edge's smaller end u whatever the other end, so the
#   order of u's two edges at one offset does not change the draws' meaning;
#   clzero — all weights 0 make ρ infinite and every p NaN, so `p > 0` ends each sweep with no
#   draw, as the guard does.
# Grid sizing only (the pairs found are the same; memory and time differ):
#   rgcells (c^d may exceed n), rgbrute (the grid when 3^d > n), rgpowerend (c^d = n exactly), and
#   rgmargin — the 2⁻²⁰ margin matters only for a pair whose rounded distance lands within 2⁻²⁰ of
#   a cell side, which uniform points do not reach.

# Duplication–divergence mutants left out as equivalent: ddcount (n = 1 traps on neighbors[1] with or
# without the check), ddkeep (`<` against `<=` differs only when a draw equals p exactly, probability
# 2⁻⁵³). Stochastic Kronecker likewise: skiterations (a negative k traps on its range anyway),
# skhalf (starting the inner range at u adds only the loop, skipped before any draw), skdraw (as ddkeep).

TESTS = ["RandomGraphsTests"]

X = "Xoshiro256StarStar.swift"
D = "Draws.swift"
EO = "EdgeOrder.swift"
PS = "PairSet.swift"
ER = "ErdosRenyi.swift"
BA = "BarabasiAlbert.swift"
WS = "WattsStrogatz.swift"
RG = "RandomGeometric.swift"
RT = "RandomTree.swift"
SB = "StochasticBlockModel.swift"
RR = "RandomRegular.swift"
RB = "RandomBipartite.swift"
DS = "DegreeSequences.swift"
CM = "ConfigurationModel.swift"
CL = "ChungLu.swift"
HK = "HolmeKim.swift"
DD = "DuplicationDivergence.swift"
SK = "StochasticKronecker.swift"
NWS = "NewmanWattsStrogatz.swift"
KO = "RandomKOut.swift"
SF = "ScaleFree.swift"

RM = "RMAT.swift"

MUTANTS = [
    # R-MAT: the quadrant choice, the loop and repeat rejection, the checks.
    Mutant("rmatsum", RM, "a + b + c <= 1 + 1e-12", "true"),
    Mutant("rmatnegative", RM, "a >= 0 && b >= 0 && c >= 0", "true"),
    Mutant("rmatscale", RM, "scale >= 0 && scale < Int.bitWidth - 2", "scale < Int.bitWidth - 2"),
    Mutant("rmatlow", RM, "m >= 0 && m <= total", "m <= total"),
    Mutant("rmathigh", RM, "m >= 0 && m <= total", "m >= 0"),
    Mutant("rmattotal", RM, "directed ? _orderedPairCount(n) : _unorderedPairCount(n)", "directed ? _unorderedPairCount(n) : _orderedPairCount(n)"),
    Mutant("rmatloop", RM, "if u == v { continue }", "", mode="stmt"),
    Mutant("rmatrepeat", RM, "chosen.insert(s, t)", "true"),
    Mutant("rmatcanonical", RM, "directed || u < v ? (u, v) : (v, u)", "(u, v)"),
    Mutant("rmatbottomleft", RM, "u |= bit", "v |= bit", nth=0),
    Mutant("rmattopright", RM, "v |= bit", "u |= bit", nth=0),
    Mutant("rmatlevel", RM, "1 << level", "1 << (scale - 1 - level)"),
    Mutant("rmatorder", RM, "return _sortedRowMajor(n, drawn)", "return drawn", mode="stmt"),
    Mutant("rmatdirected", RM, "_rmatPairs(scale: scale, m, a, b, c, directed: true, &generator)", "_rmatPairs(scale: scale, m, a, b, c, directed: false, &generator)"),
    # xoshiro256**: the scrambler, the linear step, the rotation.
    Mutant("nextmul5", X, "Self._rotateLeft(s1 &* 5, 7) &* 9", "Self._rotateLeft(s1 &* 3, 7) &* 9"),
    Mutant("nextrot7", X, "Self._rotateLeft(s1 &* 5, 7) &* 9", "Self._rotateLeft(s1 &* 5, 8) &* 9"),
    Mutant("nextmul9", X, "Self._rotateLeft(s1 &* 5, 7) &* 9", "Self._rotateLeft(s1 &* 5, 7) &* 7"),
    Mutant("nextt", X, "s1 << 17", "s1 << 16"),
    Mutant("step1", X, "        s2 ^= s0", "", mode="stmt"),
    Mutant("step2", X, "        s3 ^= s1", "", mode="stmt"),
    Mutant("step3", X, "        s1 ^= s2", "", mode="stmt"),
    Mutant("step4", X, "        s0 ^= s3", "", mode="stmt"),
    Mutant("step5", X, "        s2 ^= t", "", mode="stmt"),
    Mutant("step6", X, "        s3 = Self._rotateLeft(s3, 45)", "        s3 = Self._rotateLeft(s3, 44)", mode="stmt"),
    Mutant("rotl", X, "(x << k) | (x >> (64 - k))", "(x << k) | (x >> (63 - k))"),

    # SplitMix64 seeding.
    Mutant("splitgamma", X, "        x &+= 0x9E37_79B9_7F4A_7C15", "        x &+= 0x9E37_79B9_7F4A_7C17", mode="stmt"),
    Mutant("split30", X, "(z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9", "(z ^ (z >> 29)) &* 0xBF58_476D_1CE4_E5B9"),
    Mutant("split27", X, "(z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB", "(z ^ (z >> 26)) &* 0x94D0_49BB_1331_11EB"),
    Mutant("split31", X, "z ^ (z >> 31)", "z ^ (z >> 32)"),
    Mutant("seedfirst", X, "        s0 = Self._splitMix64(&x)", "        s0 = seed", mode="stmt"),
    Mutant("seedlast", X, "        s3 = Self._splitMix64(&x)", "        s3 = Self._splitMix64(&x) ^ 1", mode="stmt"),
    Mutant("statezero", X, "state.0 | state.1 | state.2 | state.3 != 0", "state.0 | state.1 | state.2 != 0"),
    Mutant("stateorder", X, "        (s0, s1, s2, s3) = state", "        (s0, s1, s2, s3) = (state.1, state.0, state.2, state.3)", mode="stmt"),

    # The two draws and the probability check.
    Mutant("uniformscale", D, "Double(g.next() >> 11) * 0x1p-53", "Double(g.next() >> 11) * 0x1p-52"),
    Mutant("uniformbits", D, "Double(g.next() >> 11) * 0x1p-53", "Double(g.next() & 0x1F_FFFF_FFFF_FFFF) * 0x1p-53"),
    Mutant("belowbits", D, "n.leadingZeroBitCount", "(n - 1).leadingZeroBitCount", nth=0),
    Mutant("belowshift", D, "Int(truncatingIfNeeded: g.next() >> shift)", "Int(truncatingIfNeeded: g.next() >> (shift + 1))"),
    Mutant("belowaccept", D, "r < n", "r <= n"),
    Mutant("problow", D, "p >= 0 && p <= 1", "p <= 1"),
    Mutant("probhigh", D, "p >= 0 && p <= 1", "p >= 0"),
    Mutant("probnan", D, "p >= 0 && p <= 1", "!(p < 0 || p > 1)"),

    # Counting sorts.
    Mutant("bysourcefirst", EO, "    for pair in first { offsets[pair.source &+ 1] &+= 1 }", "", mode="stmt"),
    Mutant("bysourcesecond", EO, "    for pair in second { offsets[pair.source &+ 1] &+= 1 }", "", mode="stmt"),
    Mutant("bysourceprefix", EO, "    for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }", "", mode="stmt", nth=0),
    Mutant("bysourceplace", EO, "            for pair in second {\n                let slot = offsets[pair.source]\n                offsets[pair.source] = slot &+ 1\n                sorted.initializeElement(at: slot, to: pair)\n            }", "", mode="stmt"),
    Mutant("bytargetcount", EO, "    for pair in pairs { offsets[pair.target &+ 1] &+= 1 }", "", mode="stmt"),
    Mutant("bytargetprefix", EO, "    for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }", "", mode="stmt", nth=1),
    Mutant("rowmajor", EO, "_sortedBySource(n, byTarget, [])", "_sortedBySource(n, pairs, [])"),

    # The pair set: a wrapper over AdjacencyListModule's _SlotPairTable (whose probing that spec plants).
    Mutant("pairsetcontains", PS, "table.contains(_SlotPair(u, v))", "false"),
    Mutant("pairsetinsert", PS, "table.insert(_SlotPair(u, v), ()).inserted", "true"),
    Mutant("pairsetremove", PS, "        table.remove(at: i)", "", mode="stmt"),

    # G(n, p): the Batagelj–Brandes sweep.
    Mutant("gnplimit", ER, "Double(n) * Double(n)", "Double(n)"),
    Mutant("gnplog", ER, "_log(1 - _uniform01(&g)) / lp", "_log(_uniform01(&g)) / lp"),
    Mutant("gnpend", ER, "skip < limit", "true"),
    Mutant("gnpstep", ER, "        w = w &+ 1 &+ Int(skip)", "        w = w &+ Int(skip)", mode="stmt"),
    Mutant("gnpwrap", ER, "w >= v", "w > v"),
    Mutant("gnpwrapby", ER, "            w &-= v", "            w &-= v &+ 1", mode="stmt"),
    Mutant("gnplarger", ER, "largerFirst ? DirectedEdge(from: v, to: w) : DirectedEdge(from: w, to: v)", "DirectedEdge(from: w, to: v)"),
    Mutant("gnpzero", ER, "    guard p > 0 else { return [] }", "", mode="stmt"),
    Mutant("gnpround", ER, "    guard lp != 0 else { return [] }", "", mode="stmt"),
    Mutant("gnpsort", ER, "_sortedBySource(n, first, [])", "first"),
    Mutant("gnpsweeps", ER, "_sortedBySource(n, second, first)", "_sortedBySource(n, first, second)"),

    # G(n, m): the rejection loop and the complement.
    Mutant("gnmcount", ER, "_checkCount(n)", "", mode="stmt", nth=0),
    Mutant("orderedcount", "Preconditions.swift", "_productFits(n, n - 1) ? n * (n - 1) : nil", "_productFits(n, n - 1) ? n * (n - 1) / 2 : nil", module="NamedGraphs"),
    Mutant("gnmtotal", ER, "directed ? _orderedPairCount(n) : _unorderedPairCount(n)", "directed ? _unorderedPairCount(n) : _orderedPairCount(n)"),
    Mutant("gnmlow", ER, "m >= 0 && m <= total", "m <= total"),
    Mutant("gnmhigh", ER, "m >= 0 && m <= total", "m >= 0"),
    Mutant("gnmcomplement", ER, "m <= total - m ? m : total - m", "m"),
    Mutant("gnmhalf", ER, "m <= total - m ? m : total - m", "m < total - m ? m : total - m"),
    Mutant("gnmself", ER, "        if u == v { continue }", "", mode="stmt"),
    Mutant("gnmorient", ER, "directed || u < v ? (u, v) : (v, u)", "(u, v)"),
    Mutant("gnmsort", ER, "_sortedRowMajor(n, drawn)", "drawn"),
    Mutant("gnmrest", ER, "(directed ? 0 : u + 1)", "0"),
    Mutant("gnmrestself", ER, "v != u", "true"),
    Mutant("gnmrestout", ER, "!chosen.contains(u, v)", "chosen.contains(u, v)"),

    # The public G(n, p) entries and the random DAG.
    Mutant("gnpcount", ER, "_checkCount(n)", "", mode="stmt", nth=1),
    Mutant("gnpdicount", ER, "_checkCount(n)", "", mode="stmt", nth=2),
    Mutant("dagcount", ER, "_checkCount(n)", "", mode="stmt", nth=3),
    Mutant("gnpcheck", ER, '_checkProbability(p, "edgeProbability")', "", mode="stmt", nth=0),
    Mutant("gnpdicheck", ER, '_checkProbability(p, "edgeProbability")', "", mode="stmt", nth=1),
    Mutant("dagcheck", ER, '_checkProbability(p, "edgeProbability")', "", mode="stmt", nth=2),
    Mutant("gnpone", ER, "        if p >= 1 { return complete(vertexCount: n) }", "", mode="stmt", nth=0),
    Mutant("gnpdione", ER, "        if p >= 1 { return complete(vertexCount: n) }", "", mode="stmt", nth=1),
    Mutant("dagone", ER, "        if p >= 1 {\n            precondition(_unorderedPairCount(n) != nil, \"edge count overflows Int\")\n            return Self(_vertexOrderedBase: Base(_vertexCount: n, sortedEdges: _AscendingPairs(n), _ConstructionToken()))\n        }", "", mode="stmt"),
    Mutant("dagoverflow", ER, "            precondition(_unorderedPairCount(n) != nil, \"edge count overflows Int\")", "", mode="stmt"),
    Mutant("dagorient", ER, "_gnpPairs(n, p, directed: false, &generator)", "_gnpPairs(n, p, directed: true, &generator)", nth=1),
    Mutant("daggnmorient", ER, "_gnmPairs(n, m, directed: false, &generator)", "_gnmPairs(n, m, directed: true, &generator)", nth=1),

    # The known-order DAG.
    Mutant("dagorderlabel", "DirectedAcyclicGraph+KnownOrder.swift", "            table.insert(key, label: order.count)", "            table.insert(key, label: 0)", mode="stmt", module="DirectedAcyclicGraphModule"),
    Mutant("dagorder", "DirectedAcyclicGraph+KnownOrder.swift", "            order.append(key)", "            order.insert(key, at: 0)", mode="stmt", module="DirectedAcyclicGraphModule"),

    # Barabási–Albert.
    Mutant("bacount", BA, "    _checkCount(n)", "", mode="stmt"),
    Mutant("balow", BA, "m >= 1 && m < n", "m >= 0 && m < n"),
    Mutant("bahigh", BA, "m >= 1 && m < n", "m >= 1 && m <= n"),
    Mutant("baoverflow", BA, "_productFits(m, n - m) && m * (n - m) <= Int.max / 2", "true"),
    Mutant("bastar", BA, "directed ? DirectedEdge(from: i, to: 0) : DirectedEdge(from: 0, to: i)", "DirectedEdge(from: 0, to: i)"),
    Mutant("bahub", BA, "    repeated.append(contentsOf: repeatElement(0, count: m))", "    repeated.append(contentsOf: repeatElement(0, count: 1))", mode="stmt"),
    Mutant("baleaves", BA, "    repeated.append(contentsOf: 1 ... m)", "", mode="stmt"),
    Mutant("barepeat", BA, "chosen[t] != s", "true"),
    Mutant("bamark", BA, "                chosen[t] = s", "", mode="stmt"),
    Mutant("badraw", BA, "repeated[_below(count, &g)]", "repeated[_below(count - 1, &g)]"),
    Mutant("bainsertion", BA, "m <= 16", "false"),
    Mutant("bainsertless", BA, "targets[b - 1] > value", "targets[b - 1] < value"),
    Mutant("bainsertshift", BA, "                    targets[b] = targets[b - 1]", "", mode="stmt"),
    Mutant("bainsertplace", BA, "                targets[b] = value", "", mode="stmt"),
    Mutant("basort", BA, "            targets.sort()", "", mode="stmt"),
    Mutant("baedge", BA, "directed ? DirectedEdge(from: s, to: t) : DirectedEdge(from: t, to: s)", "DirectedEdge(from: t, to: s)"),
    Mutant("batargets", BA, "        repeated.append(contentsOf: targets)", "", mode="stmt"),
    Mutant("banew", BA, "repeatElement(s, count: m)", "repeatElement(s, count: 1)"),
    Mutant("basorted", BA, "directed ? pairs : _sortedBySource(n, pairs, [])", "pairs"),

    # Watts–Strogatz.
    Mutant("wscount", WS, "    _checkCount(n)", "", mode="stmt"),
    Mutant("wsnegative", WS, "k >= 0 && k.isMultiple(of: 2)", "k.isMultiple(of: 2)", nth=0),
    Mutant("wsodd", WS, "k >= 0 && k.isMultiple(of: 2)", "k >= 0", nth=0),
    Mutant("wslarge", WS, "k <= n", "true", nth=0),
    Mutant("wsprob", WS, '    _checkProbability(p, "rewiringProbability")', "", mode="stmt", nth=0),
    Mutant("wscomplete", WS, "    if k == n { return nil }", "", mode="stmt"),
    Mutant("wsring", WS, "            _ = edges.insert(Swift.min(u, v), Swift.max(u, v))", "", mode="stmt"),
    Mutant("wsringfar", WS, "            far[(j - 1) * n + u] = v", "            far[(j - 1) * n + u] = (u + 1) % n", mode="stmt"),
    Mutant("wscoin", WS, "_uniform01(&g) < p", "_uniform01(&g) > p"),
    Mutant("wsself", WS, "w == u", "false"),
    Mutant("wsredraw", WS, "                w = _below(n, &g)", "", mode="stmt"),
    Mutant("wsfull", WS, "degree[u] >= n - 1", "degree[u] >= n"),
    Mutant("wsrewiredpair", WS, "(u + j) % n", "(u + j + 1) % n", nth=1),
    Mutant("wsremove", WS, "            edges.remove(Swift.min(u, v), Swift.max(u, v))", "", mode="stmt"),
    Mutant("wsinsert", WS, "            _ = edges.insert(Swift.min(u, w), Swift.max(u, w))", "", mode="stmt"),
    Mutant("wsdegreeold", WS, "            degree[v] -= 1", "", mode="stmt"),
    Mutant("wsdegreenew", WS, "            degree[w] += 1", "", mode="stmt"),
    Mutant("wsfar", WS, "            far[(j - 1) * n + u] = w", "", mode="stmt"),
    Mutant("wsorient", WS, "u < w ? DirectedEdge(from: u, to: w) : DirectedEdge(from: w, to: u)", "DirectedEdge(from: u, to: w)"),
    Mutant("wssort", WS, "_sortedRowMajor(n, pairs)", "pairs"),

    # Random geometric graphs: checks, the brute pass, the cell walk.
    Mutant("rgradius", RG, "r >= 0", "true"),
    Mutant("rgdimension", RG, "dimension >= 1", "dimension >= 0"),
    Mutant("rgoverflow", RG, "_productFits(n, dimension)", "true"),
    Mutant("rgmargin", RG, "(1 - 0x1p-20) / (r + 0x1p-50)", "1 / (r + 0x1p-50)"),
    Mutant("rgcells", RG, "        while c > 1, !_powerAtMost(c, d, n) { c -= 1 }", "", mode="stmt"),
    Mutant("rgbrute", RG, "_powerAtMost(3, d, n)", "true"),
    Mutant("rgbrutefrom", RG, "u + 1 ..< n", "u ..< n"),
    Mutant("rgbruteclose", RG, "s <= r2", "s < r2", nth=0),
    Mutant("rgcellcount", RG, "            cellStart[cell + 1] += 1", "", mode="stmt"),
    Mutant("rgcellprefix", RG, "    for k in 0 ..< cellCount { cellStart[k + 1] += cellStart[k] }", "", mode="stmt"),
    Mutant("rgcellfill", RG, "            fill[cellOf[v]] = k + 1", "", mode="stmt"),
    Mutant("rgcellcopy", RG, "            for i in 0 ..< d { sorted[k * d + i] = position[v * d + i] }", "", mode="stmt"),
    Mutant("rgoffsetsall", RG, "        if odometer.allSatisfy({ $0 == 0 }) { passedZero = true }", "        passedZero = true", mode="stmt"),
    Mutant("rgoffsetlinear", RG, "            for i in 0 ..< d { delta = delta * c + odometer[i] }", "            for i in 0 ..< d { delta = delta * c - odometer[i] }", mode="stmt"),
    Mutant("rglargest", RG, "    for cell in 0 ..< cellCount { largest = Swift.max(largest, cellStart[cell + 1] - cellStart[cell]) }", "", mode="stmt"),
    Mutant("rginterior", RG, "                                    if coordinates[i] == 0 || coordinates[i] == c - 1 { interior = false }", "", mode="stmt"),
    Mutant("rginside", RG, "x < 0 || x >= c", "x < 0"),
    Mutant("rgwithinfrom", RG, "a + 1 ..< end", "a ..< end"),
    Mutant("rgwithinclose", RG, "s <= r2", "s < r2", nth=1),
    Mutant("rgwithinpair", RG, "scratch[kept] = DirectedEdge(from: u, to: bucketed[b])", "scratch[kept] = DirectedEdge(from: bucketed[b], to: u)", mode="stmt"),
    Mutant("rgneighborclose", RG, "s <= r2", "s < r2", nth=2),
    Mutant("rgneighborpair", RG, "DirectedEdge(from: Swift.min(u, v), to: Swift.max(u, v))", "DirectedEdge(from: u, to: v)"),
    Mutant("rgneighbor", RG, "cell + linear[o]", "cell - linear[o]"),
    Mutant("rgsort", RG, "_sortedRowMajor(n, pairs)", "pairs"),
    Mutant("rgpowerstep", RG, "power <= limit / base", "true"),
    Mutant("rgpowerend", RG, "return power <= limit", "return power < limit", mode="stmt"),

    # Both arcs of each pair (the directed symmetric families).
    Mutant("botharcsorder", EO, "_sortedBySource(n, pairs.map { DirectedEdge(from: $0.target, to: $0.source) }, pairs)", "_sortedBySource(n, pairs, pairs.map { DirectedEdge(from: $0.target, to: $0.source) })"),
    Mutant("wsdirected", WS, "_bothArcs(n, pairs)", "pairs", nth=0),
    Mutant("wsdirectedcomplete", WS, "complete(vertexCount: n)", "Self(_vertexCount: n, sortedEdges: EmptyCollection(), _ConstructionToken())", nth=1),
    Mutant("rgdirected", RG, "_bothArcs(n, pairs)", "pairs"),

    # Random regular graphs.
    Mutant("rrrange", RR, "d >= 0 && d < n", "d >= 0 && d <= n"),
    Mutant("rrodd", RR, "(n * d).isMultiple(of: 2)", "true"),
    Mutant("rrshuffle", RR, "stubs.swapAt(i, _below(i + 1, &g))", "stubs.swapAt(i, _below(i, &g))", mode="stmt"),
    Mutant("rrshuffleend", RR, "i >= 1", "i >= 2"),
    Mutant("rrorient", RR, "a < b ? (a, b) : (b, a)", "(a, b)"),
    Mutant("rrself", RR, "u != v", "true"),
    Mutant("rrstep", RR, "                k += 2", "                k += 1", mode="stmt"),
    Mutant("rrkeptorder", RR, "if kept[u] == 0 { order.append(u) }", "", mode="stmt"),
    Mutant("rrkeptcount", RR, "                    kept[v] += 1", "", mode="stmt"),
    Mutant("rrsuitable", RR, "order.isEmpty", "true"),
    Mutant("rrquirk", RR, "                    s1 = a", "", mode="stmt"),
    Mutant("rrquirkstop", RR, "                    if s1 == y { break }", "", mode="stmt"),
    Mutant("rrcontains", RR, "!chosen.contains(a, b)", "chosen.contains(a, b)"),
    Mutant("rrrestart", RR, "                failed = true", "                failed = false", mode="stmt"),
    Mutant("rrkeptreset", RR, "                kept[v] = 0", "", mode="stmt"),
    Mutant("rrarcs", RR, "_bothArcs(n, _randomRegularPairs(n, d, &generator))", "_randomRegularPairs(n, d, &generator)"),

    # Random bipartite graphs.
    Mutant("rblimit", RB, "Double(a) * Double(b)", "Double(a)", nth=0),
    Mutant("rbstep", RB, "        w = w &+ 1 &+ Int(skip)", "        w = w &+ Int(skip)", mode="stmt"),
    Mutant("rbwrap", RB, "w >= b", "w > b"),
    Mutant("rbwrapby", RB, "            w &-= b", "            w &-= b &+ 1", mode="stmt"),
    Mutant("rbright", RB, "rightFirst ? DirectedEdge(from: a + w, to: v) : DirectedEdge(from: v, to: a + w)", "DirectedEdge(from: v, to: a + w)"),
    Mutant("rbround", RB, "    guard lp != 0 else { return [] }", "", mode="stmt"),
    Mutant("rbbacksort", RB, "_sortedBySource(a + b, back, [])", "back"),
    Mutant("rbprob", RB, '    _checkProbability(p, "edgeProbability")', "", mode="stmt"),
    Mutant("rbone", RB, "        if p >= 1 { return completeBipartite(leftCount: a, rightCount: b) }", "", mode="stmt"),
    Mutant("rbdirectedone", RB, "forward.append(DirectedEdge(from: v, to: w))", "if w > a { forward.append(DirectedEdge(from: v, to: w)) }", mode="stmt"),
    Mutant("rbdirectedarcs", RB, "_bothArcs(a + b, forward)", "forward"),
    Mutant("rbsides", RB, "BipartiteGraph(_leftCount: a, graph: UndirectedAdjacencyList<Int>.randomBipartite(\n            leftCount: a, rightCount: b, edgeProbability: p, using: &generator))", "BipartiteGraph(_leftCount: b, graph: UndirectedAdjacencyList<Int>.randomBipartite(\n            leftCount: a, rightCount: b, edgeProbability: p, using: &generator))"),

    # Random trees.
    Mutant("treecheck", RT, "n >= 1", "n >= 0"),
    Mutant("treesingle", RT, "        if n == 1 { return Tree(_vertexCount: 1, treeEnds: []) }", "", mode="stmt"),
    Mutant("treedraw", RT, "_below(n, &generator)", "_below(n - 1, &generator)"),

    # The stochastic block model.
    Mutant("sbmsize", SB, "size >= 0", "true"),
    Mutant("sbmrows", SB, "probabilities.count == blocks && probabilities.allSatisfy { $0.count == blocks }", "probabilities.allSatisfy { $0.count == blocks }"),
    Mutant("sbmcolumns", SB, "probabilities.count == blocks && probabilities.allSatisfy { $0.count == blocks }", "probabilities.count == blocks"),
    Mutant("sbmprob", SB, '        for p in row { _checkProbability(p, "edge probability") }', "", mode="stmt"),
    Mutant("sbmsymmetric", SB, "probabilities[i][j] == probabilities[j][i]", "true"),
    Mutant("sbmoverflow", SB, "starts[starts.count - 1] <= Int.max - size", "true"),
    Mutant("sbmblockpairs", SB, "(directed ? 0 : i)", "0"),
    Mutant("sbmblockpairsdirected", SB, "(directed ? 0 : i)", "i"),
    Mutant("sbmzero", SB, "            guard p > 0 else { continue }", "", mode="stmt"),
    Mutant("sbmwithin", SB, "directed ? _orderedPairCount(a) : _unorderedPairCount(a)", "directed ? _unorderedPairCount(a) : _orderedPairCount(a)"),
    Mutant("sbmbetweenoverflow", SB, '                precondition(_productFits(a, b), "edge count overflows Int")', "", mode="stmt"),
    Mutant("sbmbetween", SB, "                total = a * b", "                total = a * b - 1", mode="stmt"),
    Mutant("sbmfullfrom", SB, "(within && !directed ? x + 1 : 0)", "0"),
    Mutant("sbmfullself", SB, "!(within && x == y)", "true"),
    Mutant("sbmlp", SB, "_log(1 - p)", "_log(p)"),
    Mutant("sbmround", SB, "            guard lp != 0 else { continue }", "", mode="stmt"),
    Mutant("sbmlogzero", SB, "                if u == 0 { break }", "", mode="stmt"),
    Mutant("sbmskip", SB, "(_log(u) / lp).rounded(.down)", "(_log(1 - u) / lp).rounded(.down)"),
    Mutant("sbmend", SB, "skip < Double(total - t)", "skip <= Double(total - t)"),
    Mutant("sbmadvance", SB, "                t += s", "", mode="stmt"),
    Mutant("sbmnext", SB, "                t += 1", "", mode="stmt"),
    Mutant("sbmrow", SB, "rest >= a - column", "rest > a - column"),
    Mutant("sbmrowskip", SB, "                        rest -= a - column", "", mode="stmt"),
    Mutant("sbmcolumn", SB, "                    column += rest", "", mode="stmt"),
    Mutant("sbmpair", SB, "                    (x, y) = (row, column)", "                    (x, y) = (column, row)", mode="stmt"),
    Mutant("sbmcolumnnext", SB, "                    column += 1", "", mode="stmt"),
    Mutant("sbmrowend", SB, "column >= a", "column > a"),
    Mutant("sbmdirectedrow", SB, "                    x = t / (a - 1)", "                    x = t / a", mode="stmt"),
    Mutant("sbmdirectedcolumn", SB, "r < x ? r : r + 1", "r <= x ? r : r + 1"),
    Mutant("sbmbetweenrow", SB, "                    x = t / b", "                    x = t % b", mode="stmt"),
    Mutant("sbmbetweencolumn", SB, "                    y = t % b", "                    y = t / b", mode="stmt"),
    Mutant("sbmsort", SB, "_sortedBySource(n, pairs, [])", "pairs"),
    # Erdős–Gallai (Zverovich–Zverovich form).
    Mutant("egrange", DS, "d < 0 || d >= p", "d < 0 || d > p"),
    Mutant("egnegative", DS, "d < 0 || d >= p", "d >= p"),
    Mutant("egparity", DS, "!sum.isMultiple(of: 2) || sum > n64 * (n64 - 1)", "sum > n64 * (n64 - 1)"),
    Mutant("egbound", DS, "!sum.isMultiple(of: 2) || sum > n64 * (n64 - 1)", "!sum.isMultiple(of: 2)"),
    Mutant("egaccept", DS, "Int64(largest + smallest + 1)", "Int64(largest + smallest)"),
    Mutant("egdurfee", DS, "        if d < k + 1 { return true }", "        if d < k { return true }", mode="stmt"),
    Mutant("egrun", DS, "d < k + run ? d - k : run", "run"),
    Mutant("egleading", DS, "            leading += Int64(taken) * Int64(d)", "            leading += Int64(taken) * Int64(d - 1)", mode="stmt"),
    Mutant("egbelow", DS, "                below += counts[k + v]", "", mode="stmt"),
    Mutant("egweighted", DS, "                weighted += Int64(k + v) * Int64(counts[k + v])", "                weighted += Int64(k + v + 1) * Int64(counts[k + v])", mode="stmt"),
    Mutant("egcheck", DS, "leading > Int64(k) * Int64(n - 1) - Int64(k) * Int64(below) + weighted", "leading > Int64(k) * Int64(n) - Int64(k) * Int64(below) + weighted"),
    Mutant("egcount", DS, "            counts[d] += 1", "", mode="stmt"),

    # Fulkerson–Chen–Anstee.
    Mutant("fcarangein", DS, "d < 0 || d >= n", "d < 0 || d > n", nth=0),
    Mutant("fcarangeout", DS, "d < 0 || d >= n", "d < 0 || d > n", nth=1),
    Mutant("fcasums", DS, "sumIn != sumOut", "false"),
    Mutant("fcabyout", DS, "        let slot = offsets[n - 1 - a[v]]\n        offsets[n - 1 - a[v]] = slot + 1\n        order[slot] = v", "        let slot = offsets[n - 1 - a[v]]\n        offsets[n - 1 - a[v]] = slot + 1\n        order[n - 1 - slot] = v", mode="stmt"),
    Mutant("fcacount", DS, "    for d in a { offsets[n - 1 - d + 1] += 1 }", "    for d in a { offsets[d + 1] += 1 }", mode="stmt"),
    Mutant("nwsorder", NWS, "(side == 0 ? up : down) > u", "(side == 0 ? down : up) > u"),
    Mutant("fcaatleast", DS, "    for d in stride(from: n - 1, through: 0, by: -1) { atLeast[d] += atLeast[d + 1] }", "", mode="stmt"),
    Mutant("fcacoveredout", DS, "        covered -= prefixCounts[k - 1]", "", mode="stmt"),
    Mutant("fcacoveredin", DS, "b[v] >= k", "b[v] > k"),
    Mutant("fcacheck", DS, "left > minimumSum - Int64(covered)", "left > minimumSum"),
    Mutant("fcacounts", DS, 'precondition(outDegrees.count == n, "inDegrees.count \\(n) != outDegrees.count \\(outDegrees.count)")', "", mode="stmt", nth=0),

    # Havel–Hakimi on stacks, Kleitman–Wang on heaps.
    Mutant("hhgraphical", DS, 'precondition(isGraphical(degrees), "degreeSequence is not graphical")', "", mode="stmt"),
    Mutant("hhstackpush", DS, "        next[v] = head[d]\n        head[d] = v", "        if head[d] < 0 { head[d] = v }", mode="stmt", nth=0),
    Mutant("hhlowered", DS, "if k > 1 { lowered.append((k - 1, target)) }", "if k > 0 { lowered.append((k - 1, target)) }", mode="stmt"),
    Mutant("hhorient", DS, "source < target ? DirectedEdge(from: source, to: target) : DirectedEdge(from: target, to: source)", "DirectedEdge(from: source, to: target)"),
    Mutant("keyorder", DS, "(a.negatedOut, a.negatedIn, a.vertex) < (b.negatedOut, b.negatedIn, b.vertex)", "(a.negatedIn, a.negatedOut, a.vertex) < (b.negatedIn, b.negatedOut, b.vertex)"),
    Mutant("keyvertex", DS, "(a.negatedOut, a.negatedIn, a.vertex) < (b.negatedOut, b.negatedIn, b.vertex)", "(a.negatedOut, a.negatedIn, -a.vertex) < (b.negatedOut, b.negatedIn, -b.vertex)"),
    Mutant("heapsift", DS, "            if r < count, keys[r] < keys[smallest] { smallest = r }", "", mode="stmt"),
    Mutant("heapup", DS, "            guard keys[i] < keys[parent] else { break }", "            guard keys[i] < keys[0] else { break }", mode="stmt"),
    Mutant("kwtie", DS, "withIn.top.negatedOut > outOnly.top.negatedOut", "withIn.top.negatedOut >= outOnly.top.negatedOut"),
    Mutant("kwlowered", DS, "source.negatedOut + 1 < 0 || source.negatedIn < 0", "source.negatedOut + 1 < 0"),
    Mutant("kwtargetout", DS, "        if target.negatedOut < 0 { outOnly.push(_DegreeKey(negatedOut: target.negatedOut, negatedIn: 0, vertex: target.vertex)) }", "", mode="stmt"),
    Mutant("kwsplit", DS, "            if key.negatedIn < 0 { withIn.push(key) } else { outOnly.push(key) }", "            withIn.push(key)", mode="stmt"),
    Mutant("kwdigraphical", DS, 'precondition(isDigraphical(inDegrees: inDegrees, outDegrees: outDegrees), "the degree sequences are not digraphical")', "", mode="stmt"),

    # The configuration models.
    Mutant("stubnegative", CM, "d >= 0", "true"),
    Mutant("stubvertex", CM, "        v += 1", "        v += 2", mode="stmt"),
    Mutant("shufflebound", CM, "_below(i + 1, &g)", "_below(i, &g)"),
    Mutant("shuffleend", CM, "i >= 1", "i >= 2"),
    Mutant("cmodd", CM, "stubs.count.isMultiple(of: 2)", "true"),
    Mutant("cmhalves", CM, "Array(stubs[half...])", "Array(stubs[..<half])"),
    Mutant("dcmorder", CM, "        _shuffle(&sources, &generator)\n        _shuffle(&targets, &generator)", "        _shuffle(&targets, &generator)\n        _shuffle(&sources, &generator)", mode="stmt"),
    Mutant("dcmsums", CM, "sources.count == targets.count", "true"),
    Mutant("dcmcounts", CM, "outDegrees.count == n", "true"),

    # Chung–Lu by Miller–Hagberg.
    Mutant("clorder", CL, "weights[$0] > weights[$1] || (weights[$0] == weights[$1] && $0 < $1)", "weights[$0] > weights[$1] || (weights[$0] == weights[$1] && $0 > $1)"),
    Mutant("clstart", CL, "u + 1", "u + 2"),
    Mutant("clcap", CL, "Swift.min(sorted[v] * factor, 1)", "sorted[v] * factor", nth=0),
    Mutant("clunit", CL, "p != 1", "p > 1"),
    Mutant("clskip", CL, "                v += Int(skip)", "                v += Int(skip) + 1", mode="stmt"),
    Mutant("clratio", CL, "_uniform01(&g) < q / p", "_uniform01(&g) < q"),
    Mutant("clnext", CL, "                p = q", "", mode="stmt"),
    Mutant("clnegative", CL, "w >= 0 && w.isFinite", "w.isFinite"),
    Mutant("clinfinite", CL, "w >= 0 && w.isFinite", "w >= 0"),
    Mutant("clzero", CL, "    guard n > 0, largest > 0 else { return [] }", "    guard n > 0 else { return [] }", mode="stmt"),
    Mutant("clends", CL, "order[u]", "u"),

    # Holme–Kim.
    Mutant("ddpositive", DD, "p > 0", "true"),
    Mutant("sksquare", SK, "base >= 1 && initiator.allSatisfy { $0.count == base }", "base >= 1"),
    Mutant("skentry", SK, "p.isFinite && p >= 0 && p <= 1", "p.isFinite && p >= 0"),
    Mutant("skloop", SK, "v != u", "true"),
    Mutant("skdigit", SK, "initiator[a % base][b % base]", "initiator[b % base][a % base]"),
    Mutant("skshift", SK, "                a /= base", "", mode="stmt"),
    Mutant("ddretry", DD, "        if kept { s += 1 }", "        s += 1", mode="stmt"),
    Mutant("ddseed", DD, "directed ? DirectedEdge(from: 1, to: 0) : DirectedEdge(from: 0, to: 1)", "DirectedEdge(from: 0, to: 1)"),
    Mutant("ddmodel", DD, "_below(s, &g)", "_below(s - 1, &g)"),
    Mutant("dddirection", DD, "directed ? DirectedEdge(from: s, to: w) : DirectedEdge(from: w, to: s)", "DirectedEdge(from: w, to: s)"),
    Mutant("hkrange", HK, "m >= 1 && m <= n", "m >= 1 && m < n"),
    Mutant("hkstart", HK, "Array(0 ..< m)", "[Int](repeating: 0, count: m)"),
    Mutant("hkdistinct", HK, "chosen[t] != s", "true"),
    Mutant("hkascending", HK, "candidates[b - 1] > value", "candidates[b - 1] < value"),
    Mutant("hkfirst", HK, "step > 0", "step >= 0"),
    Mutant("hkexcludeself", HK, "                excluded.append(neighbors[target].count - 1)", "", mode="stmt"),
    Mutant("hkexcludejoined", HK, "                    if let i = position[_SlotPair(target, x)] { excluded.append(i) }", "", mode="stmt"),
    Mutant("hkexcludedorder", HK, "excluded[b - 1] > value", "excluded[b - 1] < value"),
    Mutant("hkexcludedskip", HK, "                        guard e <= i else { break }", "                        guard e < i else { break }", mode="stmt"),
    Mutant("hkposition", HK, "                position.insert(_SlotPair(w, s), neighbors[w].count)", "                position.insert(_SlotPair(w, s), neighbors[w].count + 1)", mode="stmt"),
    Mutant("hkneighbors", HK, "            neighbors[w].append(s)", "", mode="stmt"),
    Mutant("hkskip", HK, "                while joined[candidates[cursor]] == s { cursor += 1 }", "", mode="stmt"),
    Mutant("hktarget", HK, "                target = w", "", mode="stmt"),
    Mutant("hkrepeat", HK, "        repeated.append(contentsOf: repeatElement(s, count: m))", "        repeated.append(s)", mode="stmt"),
    Mutant("hkdirected", HK, "directed ? DirectedEdge(from: s, to: w) : DirectedEdge(from: w, to: s)", "DirectedEdge(from: w, to: s)"),

    # Newman–Watts–Strogatz and connected Watts–Strogatz.
    Mutant("nwslarger", NWS, "(side == 0 ? up : down) > u", "(side == 0 ? up : down) >= 0"),
    Mutant("nwsredraw", NWS, "w == u || edges.contains(Swift.min(u, w), Swift.max(u, w))", "w == u"),
    Mutant("nwsfull", NWS, "degree[u] >= n - 1", "degree[u] >= n"),
    Mutant("nwsinsert", NWS, "                _ = edges.insert(Swift.min(u, w), Swift.max(u, w))", "", mode="stmt"),
    Mutant("nwsdegree", NWS, "                degree[u] += 1", "", mode="stmt"),
    Mutant("nwscomplete", NWS, "    if k == n { return nil }", "", mode="stmt"),
    Mutant("cwsconnected", WS, "    return components <= 1", "    return components <= 2", mode="stmt"),
    Mutant("cwsunion", WS, "        parent[b] = a", "        parent[a] = a", mode="stmt"),
    Mutant("cwsfind", WS, "        while parent[b] != b {\n            parent[b] = parent[parent[b]]\n            b = parent[b]\n        }", "", mode="stmt"),
    Mutant("cwsvertex", WS, "n >= 1", "n >= 0"),
    Mutant("cwstries", WS, "tries >= 0", "true"),
    Mutant("cwsupfront", WS, "    precondition(k >= 0 && k.isMultiple(of: 2), \"nearestNeighborCount \\(k) is not even\")\n    precondition(k <= n, \"nearestNeighborCount \\(k) > vertexCount \\(n)\")\n    _checkProbability(p, \"rewiringProbability\")", "", mode="stmt"),

    # Random k-out.
    Mutant("koutrange", KO, "k >= 0 && k <= Swift.max(n - 1, 0)", "k >= 0 && k <= n"),
    Mutant("koutpool", KO, "others <= poolLimit", "true"),
    Mutant("koutreject", KO, "others <= poolLimit", "false"),
    Mutant("koutpower", KO, "while power < 3 * k { power *= 4 }", "while power < 3 * k { power *= 2 }", mode="stmt"),
    Mutant("koutskip", KO, "x < u ? x : x + 1", "x <= u ? x : x + 1"),
    Mutant("koutmove", KO, "                pool[j] = pool[others - i - 1]", "", mode="stmt"),
    Mutant("koutdrawn", KO, "                drawn[j] = u", "", mode="stmt"),
    Mutant("koutmap", KO, "j < u ? j : j + 1", "j"),
    Mutant("koutextra", KO, "        poolLimit += power", "        poolLimit += power / 2", mode="stmt"),
    Mutant("koutsort", KO, "row[b - 1] > value", "row[b - 1] < value"),
    Mutant("koutdedupe", KO, "pairs.last != pair", "true"),

    # Directed scale-free graphs.
    Mutant("sfbias", SF, "bias / (bias + Double(ends.count))", "bias / Double(ends.count)"),
    Mutant("sfdelta", SF, "delta > 0", "delta >= 0"),
    Mutant("sfalphanew", SF, "                v = count\n                count += 1\n                w = _scaleFreeChoice(targets, count, deltaIn, &generator)", "                w = _scaleFreeChoice(targets, count, deltaIn, &generator)\n                v = count\n                count += 1", mode="stmt"),
    Mutant("sfbetasource", SF, "                v = _scaleFreeChoice(sources, count, deltaOut, &generator)\n                w = _scaleFreeChoice(targets, count, deltaIn, &generator)", "                v = _scaleFreeChoice(targets, count, deltaOut, &generator)\n                w = _scaleFreeChoice(targets, count, deltaIn, &generator)", mode="stmt"),
    Mutant("sfbranch", SF, "r < alpha + beta", "r < beta"),
    Mutant("sfends", SF, "[0, 1, 2]", "[1, 2, 0]", nth=1),
    Mutant("sfsum", SF, "abs(alpha + beta + gamma - 1) < 1e-9", "true"),
    Mutant("sfsmall", SF, "n >= 3", "n >= 2"),
    Mutant("sfdeltain", SF, "deltaIn >= 0 && deltaIn.isFinite", "deltaIn.isFinite"),

    # G(a, b, m).
    Mutant("bipmrange", RB, "m >= 0 && m <= total", "m >= 0 && m <= cross"),
    Mutant("bipmhalf", RB, "m <= total - m ? m : total - m", "m"),
    Mutant("bipmside", RB, "r < cross ? r : r - cross", "r % cross"),
    Mutant("bipmright", RB, "DirectedEdge(from: u, to: a + v)", "DirectedEdge(from: u, to: a + b - 1 - v)"),
    Mutant("bipmswap", RB, "DirectedEdge(from: a + s % b, to: s / b)", "DirectedEdge(from: s / b, to: a + s % b)"),
    Mutant("bipmcomplement", RB, "        for v in a ..< a + b where !chosen.contains(u, v) { pairs.append(DirectedEdge(from: u, to: v)) }", "        for v in a ..< a + b { pairs.append(DirectedEdge(from: u, to: v)) }", mode="stmt"),
    Mutant("bipmback", RB, "            for u in 0 ..< a where !chosen.contains(v, u) { pairs.append(DirectedEdge(from: v, to: u)) }", "", mode="stmt"),
]
