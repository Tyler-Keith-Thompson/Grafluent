# Planted bugs for RandomGraphs and the known-order DirectedAcyclicGraph initializer the random DAGs
# build through (module=...). Run with `just mutate RandomGraphs`; see scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   (filled in after the run)

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

MUTANTS = [
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
    Mutant("belowbits", D, "n.leadingZeroBitCount", "(n - 1).leadingZeroBitCount", nth=1),
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

    # The pair set.
    Mutant("pairsetsize", PS, "(1 << bits) < 2 * capacity", "(1 << bits) < capacity"),
    Mutant("pairsetshift", PS, "UInt64(64 - bits)", "UInt64(65 - bits)"),
    Mutant("pairsetcontains", PS, "if k == key { return true }", "if k == key { return false }", mode="stmt"),
    Mutant("pairsetinsert", PS, "if k == key { return false }", "if k == key { return true }", mode="stmt", nth=1),
    Mutant("pairsetreach", PS, "hole < h && h <= j", "hole <= h && h <= j"),
    Mutant("pairsetreachwrap", PS, "hole < h || h <= j", "hole < h || h < j"),
    Mutant("pairsetshiftback", PS, "!reachable", "reachable"),
    Mutant("pairsethole", PS, "                    hole = j", "", mode="stmt"),
    Mutant("pairsetclear", PS, "            keys[hole] = 0", "", mode="stmt"),

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
    Mutant("gnmtotal", ER, "directed ? _orderedPairCount(n) : _unorderedPairCount(n)", "directed ? _unorderedPairCount(n) : _orderedPairCount(n)"),
    Mutant("gnmlow", ER, "m >= 0 && m <= total", "m <= total"),
    Mutant("gnmhigh", ER, "m >= 0 && m <= total", "m >= 0"),
    Mutant("gnmcomplement", ER, "m <= total - m ? m : total - m", "m"),
    Mutant("gnmhalf", ER, "m <= total - m ? m : total - m", "m < total - m ? m : total - m"),
    Mutant("gnmself", ER, "        if u == v { continue }", "", mode="stmt"),
    Mutant("gnmorient", ER, "directed || u < v ? (u, v) : (v, u)", "(u, v)"),
    Mutant("gnmkey", ER, "UInt64(a) &* width &+ UInt64(b) &+ 1", "UInt64(a) &* width &+ UInt64(b)"),
    Mutant("gnmsort", ER, "_sortedRowMajor(n, drawn)", "drawn"),
    Mutant("gnmrest", ER, "(directed ? 0 : u + 1)", "0"),
    Mutant("gnmrestself", ER, "v != u", "true"),
    Mutant("gnmrestout", ER, "!chosen.contains(UInt64(u) &* width &+ UInt64(v) &+ 1)", "chosen.contains(UInt64(u) &* width &+ UInt64(v) &+ 1)"),

    # The public G(n, p) entries and the random DAG.
    Mutant("gnpcount", ER, "_checkCount(n)", "", mode="stmt", nth=1),
    Mutant("gnpdicount", ER, "_checkCount(n)", "", mode="stmt", nth=2),
    Mutant("dagcount", ER, "_checkCount(n)", "", mode="stmt", nth=3),
    Mutant("gnpcheck", ER, '_checkProbability(p, "edgeProbability")', "", mode="stmt", nth=0),
    Mutant("gnpdicheck", ER, '_checkProbability(p, "edgeProbability")', "", mode="stmt", nth=1),
    Mutant("dagcheck", ER, '_checkProbability(p, "edgeProbability")', "", mode="stmt", nth=2),
    Mutant("gnpone", ER, "        if p >= 1 { return complete(vertexCount: n) }", "", mode="stmt", nth=0),
    Mutant("gnpdione", ER, "        if p >= 1 { return complete(vertexCount: n) }", "", mode="stmt", nth=1),
    Mutant("dagone", ER, "        if p >= 1 {\n            precondition(_unorderedPairCount(n) != nil, \"edge count overflows Int\")\n            return Self(_vertexOrderedBase: Base(_vertexCount: n, sortedEdges: _AscendingPairs(n)))\n        }", "", mode="stmt"),
    Mutant("dagoverflow", ER, "            precondition(_unorderedPairCount(n) != nil, \"edge count overflows Int\")", "", mode="stmt"),
    Mutant("dagorient", ER, "_gnpPairs(n, p, directed: false, &generator)))", "_gnpPairs(n, p, directed: true, &generator)))"),
    Mutant("daggnmorient", ER, "_gnmPairs(n, m, directed: false, &generator)))", "_gnmPairs(n, m, directed: true, &generator)))"),

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
    Mutant("wsnegative", WS, "k >= 0 && k.isMultiple(of: 2)", "k.isMultiple(of: 2)"),
    Mutant("wsodd", WS, "k >= 0 && k.isMultiple(of: 2)", "k >= 0"),
    Mutant("wslarge", WS, "k <= n", "true"),
    Mutant("wsprob", WS, '    _checkProbability(p, "rewiringProbability")', "", mode="stmt"),
    Mutant("wscomplete", WS, "    if k == n { return nil }", "", mode="stmt"),
    Mutant("wsring", WS, "            _ = edges.insert(UInt64(Swift.min(u, v)) &* width &+ UInt64(Swift.max(u, v)) &+ 1)", "", mode="stmt"),
    Mutant("wsringfar", WS, "            far[(j - 1) * n + u] = v", "            far[(j - 1) * n + u] = (u + 1) % n", mode="stmt"),
    Mutant("wscoin", WS, "_uniform01(&g) < p", "_uniform01(&g) > p"),
    Mutant("wsself", WS, "w == u", "false"),
    Mutant("wsredraw", WS, "                w = _below(n, &g)", "", mode="stmt"),
    Mutant("wsfull", WS, "degree[u] >= n - 1", "degree[u] >= n"),
    Mutant("wsrewiredpair", WS, "(u + j) % n", "(u + j + 1) % n", nth=1),
    Mutant("wsremove", WS, "            edges.remove(UInt64(Swift.min(u, v)) &* width &+ UInt64(Swift.max(u, v)) &+ 1)", "", mode="stmt"),
    Mutant("wsinsert", WS, "            _ = edges.insert(UInt64(Swift.min(u, w)) &* width &+ UInt64(Swift.max(u, w)) &+ 1)", "", mode="stmt"),
    Mutant("wsdegreeold", WS, "            degree[v] -= 1", "", mode="stmt"),
    Mutant("wsdegreenew", WS, "            degree[w] += 1", "", mode="stmt"),
    Mutant("wsfar", WS, "            far[(j - 1) * n + u] = w", "", mode="stmt"),
    Mutant("wsorient", WS, "u < w ? DirectedEdge(from: u, to: w) : DirectedEdge(from: w, to: u)", "DirectedEdge(from: u, to: w)"),
    Mutant("wssort", WS, "_sortedRowMajor(n, pairs)", "pairs"),

    # Random geometric graphs: checks, the brute pass, the cell walk.
    Mutant("rgradius", RG, "r >= 0", "true"),
    Mutant("rgdimension", RG, "dimension >= 1", "dimension >= 0"),
    Mutant("rgoverflow", RG, "_productFits(n, dimension)", "true"),
    Mutant("rgmargin", RG, "Swift.min(1 / r, Double(n)) * (1 - 0x1p-30)", "Swift.min(1 / r, Double(n))"),
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
    Mutant("sbmcolumnnext", SB, "                    column += 1\n", "", mode="stmt"),
    Mutant("sbmrowend", SB, "column >= a", "column > a"),
    Mutant("sbmdirectedrow", SB, "                    x = t / (a - 1)", "                    x = t / a", mode="stmt"),
    Mutant("sbmdirectedcolumn", SB, "r < x ? r : r + 1", "r <= x ? r : r + 1"),
    Mutant("sbmbetweenrow", SB, "                    x = t / b", "                    x = t % b", mode="stmt"),
    Mutant("sbmbetweencolumn", SB, "                    y = t % b", "                    y = t / b", mode="stmt"),
    Mutant("sbmsort", SB, "_sortedBySource(n, pairs, [])", "pairs"),
]
