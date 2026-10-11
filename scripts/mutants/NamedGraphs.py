# Planted bugs for NamedGraphs and the bulk initializers it builds through, in the other modules'
# Construction files (module=...): CompressedSparseRow, AdjacencyMatrix, the adjacency lists'
# sorted rows, the multigraphs' parallel classes, StableDirectedGraph, BipartiteGraph's known sides
# and Tree's dense layout. Run with `just mutate NamedGraphs`; see scripts/mutate.py.
#
# Known equivalent mutants (they survive by design):
#   (filled in after the run)

TESTS = ["NamedGraphsTests"]

CG = "CompleteGraphs.swift"
EG = "EmptyGraph.swift"
LA = "Lattices.swift"
PC = "PairCollections.swift"
PA = "PathsAndCycles.swift"
PE = "PetersenGraph.swift"
PR = "Preconditions.swift"

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
    Mutant("orderedcount", PR, "_productFits(n, n - 1) ? n * (n - 1) : nil", "_productFits(n, n - 1) ? n * (n - 1) / 2 : nil"),

    # Complete graphs and K_{a,b}.
    Mutant("completecount", CG, "_checkCount(n)", "", mode="stmt", nth=0),
    Mutant("completeoverflow", CG, '        precondition(_unorderedPairCount(n) != nil, "edge count overflows Int")', "", mode="stmt"),
    Mutant("completedicount", CG, "_checkCount(n)", "", mode="stmt", nth=1),
    Mutant("completedioverflow", CG, '        precondition(_orderedPairCount(n) != nil, "edge count overflows Int")', "", mode="stmt"),
    Mutant("bipartiteleft", CG, '_checkCount(a, "leftCount")', "", mode="stmt"),
    Mutant("bipartiteright", CG, '_checkCount(b, "rightCount")', "", mode="stmt"),
    Mutant("bipartitesum", CG, "a <= Int.max - b && _productFits(a, b)", "_productFits(a, b)"),
    Mutant("bipartiteproduct", CG, "a <= Int.max - b && _productFits(a, b)", "a <= Int.max - b"),
    Mutant("bipartiteundirected", CG, "_CrossPairs(a, b)", "_CrossPairs(b, a)", nth=0),
    Mutant("bipartitedirected", CG, "_CrossPairs(a, b)", "_CrossPairs(b, a)", nth=1),
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
    Mutant("ascendingnext", PC, "                v = u &+ 1\n", "                v = u\n", mode="stmt"),
    Mutant("distinctat", PC, "DirectedEdge(from: u, to: r < u ? r : r + 1)", "DirectedEdge(from: u, to: r <= u ? r : r + 1)"),
    Mutant("distinctsmall", PC, "n < 2 ? 0 : n", "n", nth=1),
    Mutant("distinctrow", PC, "u &+ 1 < n", "u < n &- 2"),
    Mutant("distinctskip", PC, "            if v == u { v &+= 1 }", "", mode="stmt"),
    Mutant("distinctlast", PC, "            if v >= n {\n                // u = n − 1 ended its row at v = u.\n                return nil\n            }", "", mode="stmt"),
    Mutant("distinctend", PC, "n < 2 ? 0 : n * (n - 1)", "n * (n - 1)"),
    Mutant("crossat", PC, "DirectedEdge(from: position / b, to: a + position % b)", "DirectedEdge(from: position % a, to: a + position / a)"),
    Mutant("crossempty", PC, "b == 0 ? 0 : a", "a"),
    Mutant("crossrow", PC, "                v = a\n", "                v = 0\n", mode="stmt"),
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
    Mutant("gridodometer", LA, "                coordinates[i] = 0\n", "", mode="stmt"),
    Mutant("gridodometerbreak", LA, "coordinates[i] < dimensions[i]", "coordinates[i] <= dimensions[i]"),
    Mutant("gridwritten", LA, '        precondition(written == m, "grid edge count")', "", mode="stmt"),

    # Hypercubes.
    Mutant("cubenegative", LA, "d >= 0", "true", nth=1),
    Mutant("cubelarge", LA, "d <= 62", "d <= 63"),
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
    Mutant("cyclefirst", PA, "        pairs.append(DirectedEdge(from: 0, to: 1))\n", "", mode="stmt"),
    Mutant("cycleclose", PA, "        pairs.append(DirectedEdge(from: 0, to: n - 1))", "        pairs.append(DirectedEdge(from: 1, to: n - 1))", mode="stmt"),
    Mutant("cyclerest", PA, "for i in 1 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", "for i in 2 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", mode="stmt", nth=1),
    Mutant("starsmall", PA, "n >= 1", "n >= 2", nth=0),
    Mutant("starhub", PA, "(1 ..< n).map { DirectedEdge(from: 0, to: $0) }", "(2 ..< n).map { DirectedEdge(from: 1, to: $0) }"),
    Mutant("wheelsmall", PA, "n >= 4", "n >= 3"),
    Mutant("wheeloverflow", PA, '    precondition(n - 1 <= Int.max / 2, "edge count overflows Int")', "", mode="stmt"),
    Mutant("wheelspokes", PA, "for i in 1 ..< n { pairs.append(DirectedEdge(from: 0, to: i)) }", "for i in 2 ..< n { pairs.append(DirectedEdge(from: 0, to: i)) }", mode="stmt"),
    Mutant("wheelrimarcs", PA, "for i in 1 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", "for i in 2 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", mode="stmt", nth=2),
    Mutant("wheelclosearc", PA, "DirectedEdge(from: n - 1, to: 1)", "DirectedEdge(from: 1, to: n - 1)"),
    Mutant("wheelfirst", PA, "        pairs.append(DirectedEdge(from: 1, to: 2))\n", "", mode="stmt"),
    Mutant("wheelclose", PA, "        pairs.append(DirectedEdge(from: 1, to: n - 1))\n", "", mode="stmt", nth=1),
    Mutant("wheelrest", PA, "for i in 2 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", "for i in 3 ..< n - 1 { pairs.append(DirectedEdge(from: i, to: i + 1)) }", mode="stmt", nth=2),
    Mutant("treepathcheck", PA, 'precondition(n >= 1, "a Tree has at least one vertex")', "", mode="stmt", nth=0),
    Mutant("treepath", PA, "            ends.append(k + 1)", "            ends.append(n - 1 - k)", mode="stmt"),
    Mutant("treestarcheck", PA, 'precondition(n >= 1, "a Tree has at least one vertex")', "", mode="stmt", nth=1),
    Mutant("treestar", PA, "            ends.append(0)", "            ends.append(n - 1)", mode="stmt"),

    # Petersen and empty.
    Mutant("petersenpair", PE, "DirectedEdge(from: $0.0, to: $0.1)", "DirectedEdge(from: $0.0, to: $0.0 == 5 && $0.1 == 7 ? 6 : $0.1)"),
    Mutant("petersensorted", PE, "(_petersenPairs + _petersenPairs.map { DirectedEdge(from: $0.target, to: $0.source) }).sorted()", "_petersenPairs + _petersenPairs.map { DirectedEdge(from: $0.target, to: $0.source) }"),
    Mutant("petersenarcs", PE, "_petersenPairs.map { DirectedEdge(from: $0.target, to: $0.source) }", "_petersenPairs", nth=1),
    Mutant("emptycount", EG, "_checkCount(n)", "", mode="stmt", nth=0),
    Mutant("emptydicount", EG, "_checkCount(n)", "", mode="stmt", nth=1),

    # CompressedSparseRow's one-pass build.
    Mutant("csrempty", "CompressedSparseRow+Construction.swift", "        guard n > 0 else {\n            self.init()\n            return\n        }", "", mode="stmt", module="CompressedSparseRowModule"),
    Mutant("csrrowend", "CompressedSparseRow+Construction.swift", "offsets[row] = k", "offsets[row] = k &+ 1", mode="stmt", nth=0, module="CompressedSparseRowModule"),
    Mutant("csrtarget", "CompressedSparseRow+Construction.swift", "targets.initializeElement(at: k, to: edge.target)", "targets.initializeElement(at: k, to: edge.source)", mode="stmt", module="CompressedSparseRowModule"),
    Mutant("csrtail", "CompressedSparseRow+Construction.swift", "                while row < n {\n                    row &+= 1\n                    offsets[row] = k\n                }", "", mode="stmt", module="CompressedSparseRowModule"),

    # AdjacencyMatrix's build.
    Mutant("matrixbit", "AdjacencyMatrix+Construction.swift", "Self._mask(target)", "Self._mask(source)", module="AdjacencyMatrixModule"),
    Mutant("matrixout", "AdjacencyMatrix+Construction.swift", "                        outDegrees[source] &+= 1", "", mode="stmt", module="AdjacencyMatrixModule"),
    Mutant("matrixin", "AdjacencyMatrix+Construction.swift", "                        inDegrees[target] &+= 1", "", mode="stmt", module="AdjacencyMatrixModule"),
    Mutant("matrixcount", "AdjacencyMatrix+Construction.swift", "_edgeCount = count", "_edgeCount = 0", mode="stmt", module="AdjacencyMatrixModule"),

    # The adjacency lists' sorted rows.
    Mutant("rowpoolcapacity", "SortedConstruction.swift", "_Row(start: offsets[v], count: length, capacity: length)", "_Row(start: offsets[v], count: length, capacity: length + 1)", module="AdjacencyListModule"),
    Mutant("rowpoolstart", "SortedConstruction.swift", "_Row(start: offsets[v], count: length, capacity: length)", "_Row(start: offsets[v + 1] - length, count: length, capacity: length)", module="AdjacencyListModule"),
    Mutant("arcoutdegree", "SortedConstruction.swift", "            outOffsets[edge.source &+ 1] &+= 1", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcindegree", "SortedConstruction.swift", "            inOffsets[edge.target &+ 1] &+= 1", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcoutprefix", "SortedConstruction.swift", "            outOffsets[v &+ 1] &+= outOffsets[v]", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcinprefix", "SortedConstruction.swift", "            inOffsets[v &+ 1] &+= inOffsets[v]", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcinsource", "SortedConstruction.swift", "inStorage[slot] = source", "inStorage[slot] = target", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcinedge", "SortedConstruction.swift", "inEdgeStorage[slot] = position", "inEdgeStorage[slot] = 0", mode="stmt", module="AdjacencyListModule"),
    Mutant("arcrecordout", "SortedConstruction.swift", "out: position &- outOffsets[source]", "out: position", module="AdjacencyListModule"),
    Mutant("arcrecordin", "SortedConstruction.swift", "in: slot &- inOffsets[target]", "in: slot", module="AdjacencyListModule"),
    Mutant("arcoutedges", "SortedConstruction.swift", "ContiguousArray(0 ..< m)", "ContiguousArray((0 ..< m).reversed())", module="AdjacencyListModule"),
    Mutant("edgedegree", "SortedConstruction.swift", "            offsets[edge.v &+ 1] &+= 1", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgeprefix", "SortedConstruction.swift", "        for v in 0 ..< n { offsets[v &+ 1] &+= offsets[v] }", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgeuneighbor", "SortedConstruction.swift", "neighborStorage[uSlot] = v", "neighborStorage[uSlot] = u", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgevincident", "SortedConstruction.swift", "incidentStorage[vSlot] = position", "incidentStorage[vSlot] = 0", mode="stmt", module="AdjacencyListModule"),
    Mutant("edgerecord", "SortedConstruction.swift", "uOffset: uSlot &- offsets[u], vOffset: vSlot &- offsets[v]", "uOffset: vSlot &- offsets[v], vOffset: uSlot &- offsets[u]", module="AdjacencyListModule"),
    Mutant("listslots", "SortedConstruction.swift", "for v in 0 ..< n { _slots[v] = v }", "for v in 0 ..< n { _slots[v] = n - 1 - v }", nth=0, mode="stmt", module="AdjacencyListModule"),
    Mutant("listpairs", "SortedConstruction.swift", "            _edges[_SlotPair(record.source, record.target)] = position", "", mode="stmt", module="AdjacencyListModule"),
    Mutant("undirectedslots", "SortedConstruction.swift", "for v in 0 ..< n { _slots[v] = v }", "for v in 0 ..< n { _slots[v] = n - 1 - v }", nth=1, mode="stmt", module="AdjacencyListModule"),
    Mutant("undirectedpairs", "SortedConstruction.swift", "            _positions[_SlotPair(record.u, record.v)] = position", "", mode="stmt", module="AdjacencyListModule"),

    # The multigraphs' single-copy classes.
    Mutant("parallellinks", "SortedConstruction.swift", "_ParallelLinks(previous: -1, next: -1), count: count)", "_ParallelLinks(previous: -1, next: -1), count: 0)", module="Multigraphs"),
    Mutant("parallelclasses", "SortedConstruction.swift", "for position in 0 ..< count { classes[key(position)] = position }", "for position in 0 ..< count { classes[key(position)] = 0 }", mode="stmt", module="Multigraphs"),
    Mutant("pseudoslots", "SortedConstruction.swift", "for v in 0 ..< n { _slots[v] = v }", "for v in 0 ..< n { _slots[v] = n - 1 - v }", nth=0, mode="stmt", module="Multigraphs"),
    Mutant("pseudodirectedkey", "SortedConstruction.swift", "_SlotPair(records[$0].source, records[$0].target)", "_SlotPair(records[$0].target, records[$0].source)", module="Multigraphs"),
    Mutant("pseudoundirectedslots", "SortedConstruction.swift", "for v in 0 ..< n { _slots[v] = v }", "for v in 0 ..< n { _slots[v] = n - 1 - v }", nth=1, mode="stmt", module="Multigraphs"),
    Mutant("pseudoundirectedkey", "SortedConstruction.swift", "_SlotPair(records[$0].u, records[$0].v)", "_SlotPair(records[$0].v, records[$0].u)", module="Multigraphs"),

    # StableDirectedGraph.
    Mutant("stableslots", "StableDirectedGraph+Construction.swift", "for v in 0 ..< n { _appendSlot(for: v) }", "for v in (0 ..< n).reversed() { _appendSlot(for: v) }", mode="stmt", module="StableGraphs"),
    Mutant("stableedge", "StableDirectedGraph+Construction.swift", "_insertEdge(slots: edge.source, edge.target)", "_insertEdge(slots: edge.target, edge.source)", mode="stmt", module="StableGraphs"),
    Mutant("stablepack", "StableDirectedGraph+Construction.swift", "        _packRows()", "", mode="stmt", module="StableGraphs"),
    Mutant("stablereserve", "StableDirectedGraph+Construction.swift", "        reserveCapacity(vertexCount: n, edgeCount: edges.count)", "", mode="stmt", module="StableGraphs"),

    # BipartiteGraph's known sides.
    Mutant("sidesleft", "Construction.swift", "[BipartiteSide](repeating: .left, count: a) + [BipartiteSide](repeating: .right, count: n - a)", "[BipartiteSide](repeating: .right, count: a) + [BipartiteSide](repeating: .left, count: n - a)", module="BipartiteGraphs"),
    Mutant("sidesleftlist", "Construction.swift", "Array(0 ..< a)", "Array((0 ..< a).reversed())", nth=0, module="BipartiteGraphs"),
    Mutant("sidesrightlist", "Construction.swift", "Array(a ..< n)", "Array((a ..< n).reversed())", module="BipartiteGraphs"),
    Mutant("sidesoffset", "Construction.swift", "_sideOffset = Array(0 ..< a) + Array(0 ..< n - a)", "_sideOffset = Array(0 ..< n)", module="BipartiteGraphs"),

    # Tree's dense layout.
    Mutant("treesingle", "Construction.swift", "        if n == 1 {\n            self.init(_layout: .single(0))\n            return\n        }", "", mode="stmt", module="Trees"),
    Mutant("treecheck", "Construction.swift", '        precondition(n >= 1, "A Tree has at least one vertex")', "", mode="stmt", module="Trees"),
]
