# Planted bugs for Assortativity; run with `just mutate Assortativity`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   anindex   the index precondition of `averageNeighborDegree(ofIndex:)` only names the trap; the
#             array read behind it traps on the same indices.
#   flatrow   summing the heads' raw values instead of their deviations in `_flatPearson` adds
#             μ_y Σ_v d(v)(x_v − μ_x), which is 0: the same r up to rounding. The deviations keep the
#             sums small. Not listed below.
#
# `censusidentityrank` and `censusdegree` rank the census's vertices by index or by out-degree
# instead of by distinct neighbors: the counts are the same, and only the performance tests' stars
# with their hubs last (10¹⁰ steps) tell them apart.

TESTS = ["AssortativityTests"]

MUTANTS = [
    # Rows and degrees
    Mutant("keeploopsout", "DegreeType.swift", "_CopyRows(readsEdges: readsEdges, dropsLoops: false)", "_CopyRows(readsEdges: readsEdges, dropsLoops: true)"),
    Mutant("rowstrength", "DegreeType.swift", "            for slot in rows.offsets[v] ..< rows.offsets[v + 1] { sum += weights[rows.edges[slot]] }", "", mode="stmt"),
    Mutant("arcweightin", "DegreeType.swift", "            inDegree[rows.targets[slot]] += w", "", mode="stmt"),
    Mutant("unweightedin", "DegreeType.swift", "        for w in rows.targets { inDegree[w] += 1 }", "", mode="stmt"),
    Mutant("totaldegree", "DegreeType.swift", "zip(degrees.in, degrees.out).map { $0 + $1 }", "degrees.out"),
    Mutant("degreetypein", "DegreeType.swift", "degrees.in", "degrees.out", nth=0),
    Mutant("finiteundirected", "DegreeType.swift", "$0.isFinite", "true", nth=0),
    Mutant("finitedirected", "DegreeType.swift", "$0.isFinite", "true", nth=1),

    # Pearson's r
    Mutant("pearsony", "AssortativityCoefficients.swift", "leastY < greatestY", "true"),
    Mutant("pearsonx", "AssortativityCoefficients.swift", "leastX < greatestX", "true"),
    Mutant("meanx", "AssortativityCoefficients.swift", "sumX / Double(m)", "sumX / Double(n)"),
    Mutant("crossrow", "AssortativityCoefficients.swift", "                        cross += dx * row", "                        cross += dx * rowSquares", mode="stmt"),
    Mutant("squaresx", "AssortativityCoefficients.swift", "                        squaresX += Double(end - start) * dx * dx", "                        squaresX += dx * dx", mode="stmt"),
    Mutant("pairsfromrow", "AssortativityCoefficients.swift", "sumX += Double(count) * value", "sumX += value"),

    # Pearson's r read from the undirected rows

    # Newman's r for classes
    Mutant("classsame", "AssortativityCoefficients.swift", "            if c == d { same += 1 }", "", mode="stmt"),
    Mutant("classnil", "AssortativityCoefficients.swift", "        if first[c] == m && second[c] == m { return nil }", "", mode="stmt"),
    Mutant("classfirst", "AssortativityCoefficients.swift", "        first[c] += rows.degree(v)", "        first[c] += 1", mode="stmt"),
    Mutant("classproducts", "AssortativityCoefficients.swift", "Double(first[c]) * Double(second[c])", "Double(first[c]) * Double(first[c])"),
    Mutant("classnumbers", "AssortativityCoefficients.swift", "            classes.append(c)", "            classes.append(0)", mode="stmt", nth=0),

    # The directed entry points
    Mutant("directedswap", "AssortativityCoefficients.swift", "_pearson(rows, _degrees(source, degrees), _degrees(target, degrees))", "_pearson(rows, _degrees(target, degrees), _degrees(source, degrees))"),
    Mutant("numericfinite", "AssortativityCoefficients.swift", "            precondition(value.isFinite, \"Vertex values must be finite\")", "", mode="stmt", nth=0),
    Mutant("numericfinitedirected", "AssortativityCoefficients.swift", "            precondition(value.isFinite, \"Vertex values must be finite\")", "", mode="stmt", nth=1),

    # Neighbor degrees
    Mutant("outgoing", "NeighborDegrees.swift", "source != .in", "source == .out"),
    Mutant("incoming", "NeighborDegrees.swift", "source != .out", "source == .in"),
    Mutant("strengthout", "NeighborDegrees.swift", "                                        strength += weight", "", mode="stmt"),
    Mutant("strengthin", "NeighborDegrees.swift", "                                        strengths[w] += weight", "", mode="stmt"),
    Mutant("neighborweight", "NeighborDegrees.swift", "weights[edges[slot]]", "1"),
    Mutant("averagezero", "NeighborDegrees.swift", "$1 == 0 ? 0 : $0 / $1", "$0 / $1"),
    Mutant("connectivitybare", "NeighborDegrees.swift", "z == 0 ? sum : sum / z", "z == 0 ? 0 : sum / z"),
    Mutant("connectivitykey", "NeighborDegrees.swift", "_degrees(source, degrees).map { Int($0) }", "_degrees(target, degrees).map { Int($0) }"),
    Mutant("anchecked", "NeighborDegrees.swift", "guard _graph.contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt"),
    Mutant("ancheckedvalue", "NeighborDegrees.swift", "        return averageNeighborDegree(of: vertex)", "        return averageNeighborDegree(ofIndex: 0)", mode="stmt"),

    # Reciprocity
    Mutant("dedupe", "Reciprocity.swift", "            guard stamp[w] != v else { continue }", "", mode="stmt"),
    Mutant("reciprocated", "Reciprocity.swift", "stamp[simple.in.targets[slot]] == v", "true"),
    Mutant("dropsloops", "Reciprocity.swift", "_compressedRows(readsEdges: false, dropsLoops: true)", "_compressedRows(readsEdges: false, dropsLoops: false)"),
    Mutant("vertexexcludeout", "Reciprocity.swift", "w != excluded", "true", nth=0),
    Mutant("vertexexcludein", "Reciprocity.swift", "w != excluded", "true", nth=1),
    Mutant("vertexdistinct", "Reciprocity.swift", "into.insert(w).inserted && out.contains(w)", "out.contains(w)"),
    Mutant("vertexnil", "Reciprocity.swift", "counts.total == 0", "false"),
    Mutant("recipchecked", "Reciprocity.swift", "guard contains(vertex) else { throw VertexNotFound() }", "guard true else { throw VertexNotFound() }", mode="stmt"),
    Mutant("recipcheckedvalue", "Reciprocity.swift", "        return reciprocity(of: vertex)", "        return nil", mode="stmt"),
    Mutant("recipmember", "Reciprocity.swift", "            precondition(contains(vertex), \"The vertex is not in the graph\")", "", mode="stmt"),

    # Degree statistics
    Mutant("histogramcount", "DegreeStatistics.swift", "    for d in values { histogram[d] += 1 }", "", mode="stmt"),
    Mutant("regularall", "DegreeStatistics.swift", "degrees.allSatisfy { $0 == first }", "true"),
    Mutant("regulardegree", "DegreeStatistics.swift", "_degreeList().allSatisfy { $0 == degree }", "true"),
    Mutant("regularnegative", "DegreeStatistics.swift", "        precondition(degree >= 0, \"A degree cannot be negative\")", "", mode="stmt"),
    Mutant("smetrichalf", "DegreeStatistics.swift", "total / 2", "total"),
    Mutant("smetricproduct", "DegreeStatistics.swift", "degrees[v] * sums[v]", "sums[v]"),
    Mutant("richmin", "DegreeStatistics.swift", "min(degrees[v], degrees[rows.targets[slot]])", "degrees[v]"),
    Mutant("richstop", "DegreeStatistics.swift", "vertices > 1", "vertices > 0"),
    Mutant("richedges", "DegreeStatistics.swift", "            edges -= edgeCount[k]", "", mode="stmt"),
    Mutant("richvertices", "DegreeStatistics.swift", "            vertices -= vertexCount[k]", "", mode="stmt"),
    Mutant("directedregularin", "DegreeStatistics.swift", "        return ins.allSatisfy { $0 == ins[0] }", "        return true", mode="stmt"),
    Mutant("directedregularout", "DegreeStatistics.swift", "outs.allSatisfy({ $0 == first })", "true"),
    Mutant("indegreeunindexed", "DegreeStatistics.swift", "            for position in edges.indices { counts[numbering.numbers[target(ofEdgeAt: position)]!] += 1 }", "", mode="stmt"),
    Mutant("indegreerows", "DegreeStatistics.swift", "for w in targets { counts[w] += 1 }", "", mode="stmt"),
    Mutant("indegreefallback", "DegreeStatistics.swift", "            for v in 0 ..< n { for w in successorIndices(ofIndex: v) { counts[w] += 1 } }", "", mode="stmt"),

    # Triadic census
    Mutant("censusdyad", "TriadicCensus.swift", "n - union - 2", "n - union - 1"),
    Mutant("censuscommon", "TriadicCensus.swift", "                        common += 1", "", mode="stmt"),
    Mutant("censusabove", "TriadicCensus.swift", "                        guard w > u else { continue }", "", mode="stmt"),
    Mutant("censusonlyu", "TriadicCensus.swift", "w > v", "true"),
    Mutant("censusbulk", "TriadicCensus.swift", "above[type] - commonAbove[type]", "above[type]"),
    Mutant("censusabovedecrement", "TriadicCensus.swift", "                above[dyad] -= 1", "", mode="stmt"),
    Mutant("censuscommonabove", "TriadicCensus.swift", "                        commonAbove[linkV[w]] += 1", "", mode="stmt"),
    Mutant("censusmutual", "TriadicCensus.swift", "                    link[w] = 3", "                    link[w] = 2", mode="stmt"),
    Mutant("censussort", "TriadicCensus.swift", "            row.sort { rank[$0] < rank[$1] }", "", mode="stmt"),
    Mutant("censusuw", "TriadicCensus.swift", "(fromU & 2) * 16", "(fromU & 2) * 8"),
    Mutant("censusvw", "TriadicCensus.swift", "(linkV[w] & 2) * 4", "(linkV[w] & 2) * 2"),
    Mutant("censusbulkcode", "TriadicCensus.swift", "(type & 2) * 4", "(type & 2) * 2"),
    Mutant("censusnull", "TriadicCensus.swift", "triples - counts[1...].reduce(0, +)", "triples"),
    Mutant("censusidentityrank", "TriadicCensus.swift", "            rank[v] = start[greatest - degree[v]]", "            rank[v] = v", mode="stmt"),
    Mutant("censusdegree", "TriadicCensus.swift", "            for slot in simple.in.offsets[v] ..< simple.in.offsets[v + 1] where linked[simple.in.targets[slot]] != v { degree[v] += 1 }", "", mode="stmt"),

    # The flat-row kernels (lent rows, pooled out-rows, compressed sparse rows)
    Mutant("flatrangex", "RowTables.swift", "leastX < greatestX", "true"),
    Mutant("flatrangey", "RowTables.swift", "leastY < greatestY", "true"),
    Mutant("flatheadsum", "RowTables.swift", "sumY += Double(count) * value", "sumY += value"),
    Mutant("flattailsum", "RowTables.swift", "sumX += Double(count) * value", "sumX += value"),
    Mutant("flatsquaresx", "RowTables.swift", "                squaresX += Double(end &- start) * dx * dx", "                squaresX += dx * dx", mode="stmt"),
    Mutant("flatsquaresy", "RowTables.swift", "                squaresY += Double(heads[w]) * dy * dy", "                squaresY += dy * dy", mode="stmt"),
    Mutant("flatindegrees", "RowTables.swift", "                degree[w] &+= 1", "", mode="stmt"),
    Mutant("flatswap", "RowTables.swift", "degrees(source)", "degrees(target)"),
    Mutant("flattotal", "RowTables.swift", "outs[$0] + Double(ins[$0])", "outs[$0]"),
    Mutant("degreesumoutgoing", "RowTables.swift", "undirected || source != .in", "undirected"),
    Mutant("degreesumincoming", "RowTables.swift", "!undirected && source != .out", "!undirected"),
    Mutant("degreesumk", "RowTables.swift", "                        if outgoing { sum &+= k[w] }", "                        if outgoing { sum &+= 1 }", mode="stmt"),
    Mutant("degreesumin", "RowTables.swift", "                        if incoming { sums[w] &+= kv }", "", mode="stmt"),
    Mutant("degreesumtarget", "RowTables.swift", "k = ins", "k = outs", mode="stmt"),
    Mutant("degreesumtargettotal", "RowTables.swift", "zip(outs, ins).map { $0 &+ $1 }", "outs", nth=0),
    Mutant("degreesumcounttotal", "RowTables.swift", "zip(outs, ins).map { $0 &+ $1 }", "outs", nth=1),
    Mutant("degreesumcountin", "RowTables.swift", "counts = ins", "counts = outs", mode="stmt"),
    Mutant("flataverageszero", "RowTables.swift", "$1 == 0 ? 0 : Double($0) / Double($1)", "Double($0) / Double($1)"),
    Mutant("flatconnectivitynorm", "RowTables.swift", "norm[sums.counts[v], default: 0] &+= sums.counts[v]", "norm[sums.counts[v], default: 0] &+= 1", mode="stmt"),
]
