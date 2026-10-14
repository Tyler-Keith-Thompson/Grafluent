# Planted bugs for GraphDrawing: Drawing, the circular layout, Fruchterman–Reingold (exact and
# Barnes–Hut), stress majorization, Reingold–Tilford (Walker / Buchheim–Jünger–Leipert) and the
# Sugiyama pipeline (network simplex layering, barycenter crossing reduction, Brandes–Köpf); run
# with `just mutate GraphDrawing`. See scripts/mutate.py.
#
# GraphDrawingPlantedBugTests pins inputs that catch the Sugiyama mutants: graphs found by comparing,
# for each mutant (GRAFLUENT_MUTANT), the layered drawings of 20 000 – 30 000 random digraphs with
# the unmutated ones.
#
# Known equivalent mutants (they survive by design):
#   fetreeorder     Barnes–Hut repulsion computed for vertex i instead of the tree's i-th vertex:
#                   each vertex's sum is computed alone, so only the visiting order (cache use)
#                   changes.
#   echangedbreak   no stop when a sweep changes nothing: a sweep is a function of the order, so
#                   an unchanged order is a fixed point and later sweeps change nothing; time only.
#   ekeytie         the barycenter sort without its index tie-break: Swift's sort is stable, and
#                   the index is the order before the sort, so ties keep it either way.
#   bknarrow        the last narrowest alignment instead of the first: with equal widths, moving
#                   from one to the other moves every left alignment's shift by Δlow and every
#                   right one's by Δhigh = Δlow, so all four move together and the final
#                   translation to least x 0 removes it.
#   bkconflictinner marking inner segments (dummy to dummy) as type-1 conflicts too: inner
#                   segments never cross. The first order lists each layer's dummies by arc, and
#                   every sweep ends with the upward pass, which sorts each layer's dummies by
#                   their one lower neighbour; the best order kept is one of these. 0 differences
#                   in 50 000 random digraphs.
#   nslongest       the warm start's ranks by the last predecessor instead of the longest path:
#   nsleavefirst    the warm start and the leaving-arc ties choose the tree and the pivots, not
#   nsleavesecond   the optimum: the total span equalled the unmutated one on all 50 000 random
#   nsstronglyroot  digraphs. The three tie mutants pick another optimal layering in 20 – 186 of
#                   them, and which optimal layering is chosen is not specified. They
#                   give up Cunningham's strongly feasible tree, which is what rules out cycling;
#                   no input that cycles was found.
#   Removed as equivalent: a BFS layer of distance + 2 instead of + 1 (columns depend only on the
#   order of the layers, and the queue lists them in order); bfsLayout's reachability check
#   (without it an unreachable vertex still traps, on an index past the queue).
#   Also removed as equivalent: not marking the far side of a face chord visited (the cut-off
#   triangle is then walked again as a face of length 3, which triangulation leaves alone and which
#   is never longer than the first longest face); the outer contour's first neighbour test
#   (with no counterclockwise neighbour the general test reduces to the clockwise one).
#   plready     the first vertex left ready: it is pushed first, so it lies at the bottom of the
#               stack of candidates and the n − 2 picks end before reaching it.
#   Under load (other runs at once) these can show as caught by the stress suite's wall-clock
#   bounds; run alone (`--jobs 1`) they survive.

TESTS = ["GraphDrawingTests"]

D = "Drawing.swift"
C = "CircularLayout.swift"
E = "GraphEdges.swift"
F = "ForceEngine.swift"
FR = "FruchtermanReingoldLayout.swift"
S = "StressMajorizationLayout.swift"
RT = "ReingoldTilfordLayout.swift"
SG = "SugiyamaLayout.swift"
L = "LayeredDrawingEngine.swift"
NS = "NetworkSimplexLayering.swift"
DR = "DistanceRows.swift"
SH = "ShellLayout.swift"
SP = "SpectralLayout.swift"
EG = "SymmetricEigensolver.swift"  # SpectralGraphTheory's dense solver, which the spectral and MDS layouts call
FA = "ForceAtlas2Layout.swift"
PL = "PlanarLayout.swift"
MP = "MultipartiteLayout.swift"

MUTANTS = [
    # Drawing.
    Mutant("dinitcount", D, "listed.count == points.count", "true"),
    Mutant("ddense", D, "unsafeBitCast(v, to: Int.self) != i", "false"),
    Mutant("drepeat", D, "table.updateValue(i, forKey: v) == nil", "true"),
    Mutant("dpositionsset", D, "precondition(newValue.count == _vertices.count, \"A drawing needs one position per vertex\")", "", mode="stmt"),
    Mutant("dpositionsmodify", D, "precondition(_positions.count == _vertices.count, \"A drawing needs one position per vertex\")", "", mode="stmt"),
    Mutant("doffsetdense", D, "UInt(bitPattern: i) < UInt(bitPattern: _vertices.count)", "UInt(bitPattern: i) <= UInt(bitPattern: _vertices.count)"),
    Mutant("dboxhigh", D, "high = pointwiseMax(high, p)", "high = pointwiseMin(high, p)", mode="stmt"),
    Mutant("dboxlow", D, "low = pointwiseMin(low, p)", "low = pointwiseMax(low, p)", mode="stmt"),
    Mutant("drescalemean", D, "sum / Double(n)", "sum / Double(n + 1)"),
    Mutant("drescaleaxis", D, "Swift.max(Swift.abs(q.x), Swift.abs(q.y))", "Swift.abs(q.x)"),
    Mutant("drescalecenter", D, "(_positions[i] - mean) * scale / limit + center", "(_positions[i] - mean) * scale / limit"),
    Mutant("drescalecoincident", D, "limit > 0", "limit >= 0"),
    Mutant("deqvertices", D, "lhs._vertices == rhs._vertices && lhs._positions == rhs._positions", "lhs._positions == rhs._positions"),
    Mutant("deqpositions", D, "lhs._vertices == rhs._vertices && lhs._positions == rhs._positions", "lhs._vertices == rhs._vertices", nth=0),
    Mutant("ddescription", D, '"\\($0.0): (\\($0.1.x), \\($0.1.y))"', '"\\($0.0): (\\($0.1.y), \\($0.1.x))"'),

    # The circular layout.
    Mutant("cradius", C, "radius.isFinite && radius >= 0", "radius.isFinite && radius > 0"),
    Mutant("ccenter", C, "center.x.isFinite && center.y.isFinite", "true"),
    Mutant("cone", C, "    if n == 1 { return [center] }", "", mode="stmt"),
    Mutant("cstep", C, "2 * Double.pi / Double(n)", "2 * Double.pi / Double(n + 1)"),
    Mutant("cangle", C, "step * Double(i)", "step * Double(i + 1)"),
    Mutant("ccentre", C, "center + radius * SIMD2(cos(angle), sin(angle))", "radius * SIMD2(cos(angle), sin(angle))"),
    Mutant("cswap", C, "SIMD2(cos(angle), sin(angle))", "SIMD2(sin(angle), cos(angle))", nth=1),

    # Edges in index space and the start positions.
    Mutant("eloopindexed", E, "                guard u != v else { continue }", "", mode="stmt", nth=0),
    Mutant("eloopunindexed", E, "            guard u != v else { continue }", "", mode="stmt", nth=1),
    Mutant("eendindexed", E, "us.append(u)", "us.append(v)", mode="stmt", nth=0),
    Mutant("eendunindexed", E, "us.append(u)", "us.append(v)", mode="stmt", nth=1),
    Mutant("evalueindexed", E, "values.append(x)", "values.append(1)", mode="stmt", nth=0),
    Mutant("evalueunindexed", E, "values.append(x)", "values.append(1)", mode="stmt", nth=1),
    Mutant("estartfast", E, "drawing._vertices == vertices", "true"),
    Mutant("estartfinite", E, "p.x.isFinite && p.y.isFinite", "true"),

    # Fruchterman–Reingold: the engine.
    Mutant("fetemp", F, "0.1 * Swift.max(side.x, side.y)", "0.1 * side.x"),
    Mutant("fetempzero", F, "        if temperature == 0 { temperature = 0.1 * k }", "", mode="stmt"),
    Mutant("fecool", F, "temperature / Double(iterations + 1)", "temperature / Double(iterations)"),
    Mutant("fecooling", F, "        temperature -= cooling", "", mode="stmt"),
    Mutant("ferepulsion", F, "sum += delta * (k2 / Swift.max(d2, 1e-4))", "sum += delta * (k / Swift.max(d2, 1e-4))", mode="stmt", nth=0),
    Mutant("ferepulsionfloor", F, "sum += delta * (k2 / Swift.max(d2, 1e-4))", "sum += delta * (k2 / Swift.max(d2, 1e-2))", mode="stmt", nth=1),
    Mutant("fecoincident", F, "if u != v { sum += _coincidentOffset(v, u) * (k2 / 1e-4) }", "", mode="stmt", nth=0),
    Mutant("fecoincidentself", F, "u != v", "true", nth=0),
    Mutant("feattract", F, "delta * (w[e] * d / k)", "delta * (w[e] * d * d / k)"),
    Mutant("feattracta", F, "disp[a] -= pull", "disp[a] += pull", mode="stmt"),
    Mutant("feattractb", F, "disp[b] += pull", "", mode="stmt"),
    Mutant("femovecap", F, "Swift.min(length, t)", "length"),
    Mutant("femoved", F, "moved += (move * move).sum()", "", mode="stmt"),
    Mutant("fereturn", F, "moved.squareRoot() / Double(n)", "moved / Double(n)"),
    Mutant("fetreeorder", F, "tree.order[i]", "i"),

    # Fruchterman–Reingold: the Barnes–Hut quadtree.
    Mutant("qtpad", F, "extent > 0 ? extent * (1 + 1e-9) : 1", "extent > 0 ? extent : 1"),
    Mutant("qtquadrant", F, "(p.x >= mid.x ? 1 : 0) + (p.y >= mid.y ? 2 : 0)", "(p.y >= mid.y ? 1 : 0) + (p.x >= mid.x ? 2 : 0)"),
    Mutant("qtchildcorner", F, "SIMD2(q & 1 == 1 ? half : 0, q & 2 == 2 ? half : 0)", "SIMD2(q & 2 == 2 ? half : 0, q & 1 == 1 ? half : 0)"),
    Mutant("qtmass", F, "total = Double(h - l)", "total = 1", mode="stmt"),
    Mutant("qtcentre", F, "centre.append(sum / total)", "centre.append(c + s / 2)", mode="stmt"),
    Mutant("qtinside", F, "!inside && s * s < theta * theta * d2", "s * s < theta * theta * d2", nth=0),
    Mutant("qttheta", F, "s * s < theta * theta * d2", "s < theta * d2", nth=1),
    Mutant("qtcoincident", F, "if u != v { sum += _coincidentOffset(v, u) * (k2 / 1e-4) }", "", mode="stmt", nth=0),
    Mutant("qtchildren", F, "for child in first ..< first + childCount[cell] { stack.append(child) }", "for child in first ..< first + childCount[cell] - 1 { stack.append(child) }", mode="stmt", nth=0),
    Mutant("qtsplitcount", F, "count > 1", "count > 2"),
    Mutant("qtoffsetsign", F, "    return v > u ? unit : -unit", "    return unit", mode="stmt"),

    # Fruchterman–Reingold: the layout.
    Mutant("frstartx", FR, "Double(generator.next() >> 11) * 0x1p-53", "Double(generator.next() >> 12) * 0x1p-53", nth=0),
    Mutant("frk", FR, "(1 / Double(n)).squareRoot()", "1 / Double(n)"),
    Mutant("frtheta", FR, "barnesHutTheta.flatMap { $0 > 0 ? $0 : nil }", "barnesHutTheta"),
    Mutant("frsingle", FR, "_converged = n <= 1", "_converged = n == 0", mode="stmt"),
    Mutant("frfinished", FR, "_converged || _iteration >= _iterations", "_iteration >= _iterations"),
    Mutant("frthreshold", FR, "moved < _engine.threshold", "moved <= _engine.threshold"),
    Mutant("frweight", FR, "w.isFinite && w >= 0", "w.isFinite"),
    Mutant("friterations", FR, "iterations >= 0", "true"),
    Mutant("froptimal", FR, "optimalDistance.isFinite && optimalDistance > 0", "optimalDistance.isFinite && optimalDistance >= 0"),
    Mutant("frthresholdcheck", FR, "threshold >= 0", "true"),
    Mutant("frthetacheck", FR, "barnesHutTheta.isFinite && barnesHutTheta >= 0", "barnesHutTheta.isFinite"),

    # Stress majorization.
    Mutant("smtolerance", S, "tolerance >= 0", "true"),
    Mutant("smmaxiterations", S, "maxIterations >= 0", "true"),
    Mutant("smstart", S, "engine.meanEdgeLength", "1"),
    Mutant("smsingle", S, "_converged = edges.vertexCount <= 1", "_converged = edges.vertexCount == 0", mode="stmt"),
    Mutant("smstop", S, "previous - before <= _tolerance * previous", "previous - before < _tolerance * previous"),
    Mutant("smprevious", S, "        _previousStress = before", "", mode="stmt"),
    Mutant("smlengthcheck", S, "x.isFinite && x > 0", "x.isFinite && x >= 0"),
    Mutant("smmean", S, "lengths.reduce(0, +) / Double(lengths.count)", "lengths.reduce(0, +)"),
    Mutant("smapart", S, "1 + meanEdgeLength * Double(n).squareRoot()", "1 + meanEdgeLength * Double(n)"),
    Mutant("smuniform", DR, "lengths.allSatisfy({ $0 == lengths[0] })", "true"),
    Mutant("smbfs", DR, "hops[v] + 1", "hops[v] + 2"),
    Mutant("smunit", DR, "Double(hops[v]) * unit", "Double(hops[v])"),
    Mutant("smrelax", DR, "d + length[slot]", "length[slot]"),
    Mutant("smpush", DR, "heap[i].0 < heap[(i - 1) / 2].0", "heap[i].0 > heap[(i - 1) / 2].0"),
    Mutant("smpopleft", DR, "if l < heap.count, heap[l].0 < heap[m].0 { m = l }", "", mode="stmt"),
    Mutant("smpopright", DR, "if r < heap.count, heap[r].0 < heap[m].0 { m = r }", "", mode="stmt"),
    Mutant("smadjreverse", DR, "neighbor[fill[vs[e]]] = us[e]", "neighbor[fill[vs[e]]] = vs[e]", mode="stmt"),
    Mutant("smweightsum", S, "weightSums[j] += a * a", "", mode="stmt"),
    Mutant("smnx", S, "(tx[i] + sx.sum() + rx) / weights[i]", "(sx.sum() + rx) / weights[i]"),
    Mutant("smny", S, "(ty[i] + sy.sum() + ry) / weights[i]", "(ty[i] + sx.sum() + ry) / weights[i]"),
    Mutant("smtail", S, "txj[k] += w * nx + dx * q", "", mode="stmt"),
    Mutant("smtailsimd", S, "Self.store4(Self.load4(txj + k) + w * nx + dx * q, txj + k)", "", mode="stmt"),
    Mutant("smsimdq", S, "sx += w * xk + dx * q", "sx += w * xk", mode="stmt"),
    Mutant("smrestq", S, "rx += w * xj[k] + dx * q", "rx += w * xj[k]", mode="stmt"),
    Mutant("smbefore", S, "before += r2.sum() + rest", "before += r2.sum()", mode="stmt"),
    Mutant("smstress", S, "(delta * delta).sum().squareRoot() * Double(a[row + j]) - 1", "(delta * delta).sum().squareRoot() * Double(a[row + j])"),
    Mutant("smwriteback", S, "positions[i] = SIMD2(xs[i], ys[i])", "positions[i] = SIMD2(ys[i], xs[i])", mode="stmt"),

    # Reingold–Tilford: the first walk.
    Mutant("rtleaf", RT, "prelim[w] + 1", "prelim[w] + 2", nth=0),
    Mutant("rtinternal", RT, "prelim[w] + 1", "prelim[w] + 2", nth=1),
    Mutant("rtmid", RT, "(prelim[children[childStart[v]]] + prelim[children[childStart[v + 1] - 1]]) / 2", "prelim[children[childStart[v]]]"),
    Mutant("rtmod", RT, "mod[v] = prelim[v] - mid", "", mode="stmt"),
    Mutant("rtexecshift", RT, "s += shift[x] + c", "s += shift[x]", mode="stmt"),
    Mutant("rtexecchange", RT, "c += change[x]", "", mode="stmt"),
    Mutant("rtexecmod", RT, "                mod[x] += s", "", mode="stmt"),
    Mutant("rtgap", RT, "(prelim[vim] + sim) - (prelim[vip] + sip) + 1", "(prelim[vim] + sim) - (prelim[vip] + sip)"),
    Mutant("rtancestor", RT, "parent[ancestor[vim]] == p ? ancestor[vim] : defaultV", "defaultV"),
    Mutant("rtspread", RT, "Double(number[v] - number[a])", "Double(number[v] - number[a] + 1)"),
    Mutant("rtchangev", RT, "change[v] -= gap / k", "", mode="stmt"),
    Mutant("rtchangea", RT, "change[a] += gap / k", "", mode="stmt"),
    Mutant("rtshiftv", RT, "shift[v] += gap", "", mode="stmt"),
    Mutant("rtsip", RT, "sip += gap", "", mode="stmt"),
    Mutant("rtsim", RT, "sim += mod[vim]", "", mode="stmt"),
    Mutant("rtsom", RT, "som += mod[vom]", "", mode="stmt"),
    Mutant("rtancestorset", RT, "ancestor[vop] = v", "", mode="stmt"),
    Mutant("rtthreadright", RT, "mod[vop] += sim - sop", "", mode="stmt"),
    Mutant("rtthreadleft", RT, "mod[vom] += sip - som", "", mode="stmt"),
    Mutant("rtdefault", RT, "defaultV = v\n", "\n", mode="stmt"),
    Mutant("rtdefaultstore", RT, "defaultAncestor[p] = defaultV", "", mode="stmt"),
    Mutant("rtfirstchild", RT, "if slot == childStart[v] { defaultAncestor[v] = c }", "", mode="stmt"),
    Mutant("rtnextleft", RT, "childStart[v] < childStart[v + 1] ? children[childStart[v]] : thread[v]", "childStart[v] < childStart[v + 1] ? children[childStart[v + 1] - 1] : thread[v]"),
    Mutant("rtleftsibling", RT, "children[childStart[p] + number[v] - 1]", "children[childStart[p]]"),
    Mutant("rtnumber", RT, "number[children[slot]] = i", "number[children[slot]] = 0", mode="stmt"),

    # Reingold–Tilford: the second walk and the polar map.
    Mutant("rtsecondwalk", RT, "offset[v] = offset[p] + mod[p]", "offset[v] = offset[p]", mode="stmt"),
    Mutant("rtroot", RT, "offset[root] = -prelim[root]", "", mode="stmt"),
    Mutant("rtdepth", RT, "Double(depth[v])", "Double(depth[v] + 1)"),
    Mutant("rtpolarspan", RT, "2 * Double.pi * (Double(n) - 1) / Double(n)", "2 * Double.pi"),
    Mutant("rtpolardivide", RT, "    if high > low { ratio /= high - low }", "", mode="stmt"),
    Mutant("rtpolarlow", RT, "(p.x - low) * ratio", "p.x * ratio"),
    Mutant("rtpolarswap", RT, "SIMD2(p.y * cos(angle), p.y * sin(angle))", "SIMD2(p.y * sin(angle), p.y * cos(angle))"),

    # Sugiyama: the public layer.
    Mutant("sgbendsearch", SG, "_positions[mid] < position", "_positions[mid] <= position", nth=0),
    Mutant("sglayercheck", SG, "l >= 0", "true"),
    Mutant("sgiterations", SG, "maxIterations >= 0", "true", nth=0),

    # Sugiyama: caller layers, dummies and segments.
    Mutant("egivenrank", L, "layerValue[mid] < given[v]", "layerValue[mid] <= given[v]"),
    Mutant("egivendistinct", L, "for l in distinct where layerValue.last != l { layerValue.append(l) }", "for l in distinct { layerValue.append(l) }", mode="stmt"),
    Mutant("egivenreversed", L, "                reversed.append(k)", "", mode="stmt"),
    Mutant("egivenflag", L, "                isReversed[k] = true", "", mode="stmt"),
    Mutant("egivencount", L, "(layerValue.last ?? -1) + 1", "layerValue.count"),
    Mutant("egiveny", L, "SIMD2(x[v], Double(layerValue[layer[v]]))", "SIMD2(x[v], Double(layer[v]))"),
    Mutant("elayercount", L, "Swift.max(layerCount, l + 1)", "Swift.max(layerCount, l)"),
    Mutant("einner", L, "layer[lower[k]] - layer[upper[k]] - 1", "Swift.max(layer[lower[k]] - layer[upper[k]] - 2, 0)"),
    Mutant("edummylayer", L, "layer[upper[k]] + 1 + i", "layer[upper[k]] + 2 + i"),
    Mutant("echainlast", L, "        body(a, lower[k])", "", mode="stmt"),
    Mutant("echainnext", L, "            a = d", "", mode="stmt"),
    Mutant("einitposition", L, "position[x] = fill[l] - layerStart[l]", "position[x] = 0", mode="stmt"),
    Mutant("ebendreversed", L, "for d in range.reversed() { bends.append(SIMD2(x[d], Double(layerValue[nodeLayer[d]]))) }", "for d in range { bends.append(SIMD2(x[d], Double(layerValue[nodeLayer[d]]))) }", mode="stmt"),

    # Sugiyama: crossing reduction.
    Mutant("edownsweep", L, "if sortLayer(l, &order, &position, start: upStart, neighbors: up) { changed = true }", "", mode="stmt"),
    Mutant("eupsweep", L, "if sortLayer(l, &order, &position, start: downStart, neighbors: down) { changed = true }", "", mode="stmt"),
    Mutant("ebest", L, "c < best", "c <= best"),
    Mutant("ebestorder", L, "                bestOrder = order", "", mode="stmt"),
    Mutant("echangedbreak", L, "            if !changed { break }", "", mode="stmt"),
    Mutant("emaxiter", L, "iteration < maxIterations", "true"),
    Mutant("ekeyown", L, "keys.append((Double(i - s), i - s))", "keys.append((0, i - s))", mode="stmt"),
    Mutant("ekeymean", L, "Double(sum) / Double(b - a)", "Double(sum)"),
    Mutant("ekeytie", L, "$0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1)", "$0.0 < $1.0"),
    Mutant("echangedflag", L, "if key.1 != i { changed = true }", "", mode="stmt"),
    Mutant("ecrossend", L, "position[down[slot]] + 1", "position[down[slot]]", nth=0),
    Mutant("ecrossseen", L, "seen += downStart[x + 1] - downStart[x]", "", mode="stmt"),
    Mutant("ecrosslayers", L, "stride(from: 0, to: layerCount - 1, by: 1)", "stride(from: 1, to: layerCount - 1, by: 1)"),
    Mutant("ecrossclear", L, "for i in 0 ... width { tree[i] = 0 }", "", mode="stmt"),

    # Sugiyama: Brandes–Köpf.
    Mutant("bkmiddleab", L, "if a > b { swap(&a, &b) }", "", mode="stmt"),
    Mutant("bkmiddlecd", L, "if c > d { swap(&c, &d) }", "", mode="stmt"),
    Mutant("bkaverage", L, "Double(second + third) / 2", "Double(a + b + c + d) / 4"),
    Mutant("bknarrow", L, "widths[i] < widths[narrowest]", "widths[i] <= widths[narrowest]"),
    Mutant("bkshift", L, "i % 2 == 0 ? lows[narrowest] - lows[i] : highs[narrowest] - highs[i]", "lows[narrowest] - lows[i]"),
    Mutant("bkleast", L, "for v in 0 ..< nodeCount { x[v] -= least }", "", mode="stmt"),
    Mutant("bkconflictinner", L, "!(u >= vertexCount && w >= vertexCount)", "true"),
    Mutant("bkconflictright", L, "k < k0 || k > k1", "k < k0"),
    Mutant("bkconflictleft", L, "k < k0 || k > k1", "k > k1", nth=0),
    Mutant("bkk0", L, "                k0 = k1", "", mode="stmt"),
    Mutant("bkinnerupper", L, "up[slot] >= vertexCount", "true"),
    Mutant("bkinnerlower", L, "v >= vertexCount", "true", nth=0),
    Mutant("bklastnode", L, "i == e - 1 || innerUpper >= 0", "innerUpper >= 0"),
    Mutant("bkalignguard", L, "guard align[v] == v else { break }", "", mode="stmt"),
    Mutant("bkmedians", L, "(d - 1) / 2", "d / 2"),
    Mutant("bkmarked", L, "!marked.contains(key) && r < pu", "r < pu"),
    Mutant("bkr", L, "r < pu", "r <= pu", nth=1),
    Mutant("bkkey", L, "upward ? u * nodeCount + v : v * nodeCount + u", "u * nodeCount + v"),
    Mutant("bkroot", L, "root[v] = root[u]", "", mode="stmt"),
    Mutant("bkalign", L, "align[v] = root[v]", "", mode="stmt"),
    Mutant("bkrupdate", L, "                        r = pu", "", mode="stmt"),
    Mutant("bkcompact", L, "Swift.max(place[c], place[block] + 1)", "Swift.max(place[c], place[block])"),
    Mutant("bkright", L, "leftward ? place[root[x]] : -place[root[x]]", "place[root[x]]"),
    Mutant("bkmirror", L, "leftward ? x : width - 1 - x", "x"),
    Mutant("bkneighborend", L, "neighbors[leftward ? a + mi : b - 1 - mi]", "neighbors[a + mi]"),
    Mutant("bkadjacent", L, "upward ? l - 1 : l + 1", "l - 1"),
    Mutant("bklayerorder", L, "upward ? step : layers - 1 - step", "step"),
    Mutant("bksortedup", L, "sortedUp[upFill[v]] = u", "sortedUp[upFill[v]] = down[slot]", mode="stmt"),

    # Network simplex layering.
    Mutant("nsartificial", NS, "2 * (n + 1)", "1"),
    Mutant("nsentering", NS, "c < least", "c <= least"),
    Mutant("nspotential", NS, "potential[v] - cost[pred[w]]", "potential[v] + cost[pred[w]]"),
    Mutant("nssigma", NS, "potential[vIn] - potential[uIn] - (up[uIn] ? cost[entering] : -cost[entering])", "potential[vIn] - potential[uIn]"),
    Mutant("nsleavefirst", NS, "flow[pred[u]] < delta", "flow[pred[u]] <= delta"),
    Mutant("nsleavesecond", NS, "flow[pred[u]] <= delta", "flow[pred[u]] < delta", nth=1),
    Mutant("nsflowfirst", NS, "flow[pred[u]] += up[u] ? -delta : delta", "flow[pred[u]] += up[u] ? delta : -delta", mode="stmt"),
    Mutant("nsflowentering", NS, "            flow[entering] += delta", "", mode="stmt"),
    Mutant("nspotentialupdate", NS, "potential[x] += sigma", "potential[x] -= sigma", mode="stmt"),
    Mutant("nsranks", NS, "rank[v] = -potential[v]", "rank[v] = potential[v]", mode="stmt"),
    Mutant("nsunion", NS, "if a != b { set[a] = b }", "", mode="stmt"),
    Mutant("nsnormalize", NS, "for v in 0 ..< n { rank[v] -= least[_find(v, &set)] }", "", mode="stmt"),
    Mutant("nslongest", NS, "Swift.max(rank[w], rank[v] + 1)", "rank[v] + 1"),
    Mutant("nstreeflowsign", NS, "upward ? net[v] >= 0 : net[v] < 0", "true"),
    Mutant("nstreeflow", NS, "flow[e] = upward ? net[v] : -net[v]", "flow[e] = net[v]", mode="stmt"),
    Mutant("nsnetup", NS, "net[p] += net[v]", "", mode="stmt"),
    Mutant("nssuccnum", NS, "succNum[parent[preorder[i]]] += succNum[preorder[i]]", "", mode="stmt"),
    Mutant("nsupin", NS, "up[uIn] = uIn == source[inArc]", "up[uIn] = uIn != source[inArc]", mode="stmt", nth=0),
    Mutant("nsupstem", NS, "up[x] = !up[p]", "up[x] = up[p]", mode="stmt"),
    Mutant("nssuccadd", NS, "succNum[x] += oldSuccNum", "", mode="stmt"),
    Mutant("nssuccsub", NS, "succNum[x] -= oldSuccNum", "", mode="stmt"),
    Mutant("nsthreadstem", NS, "thread[vIn] = uIn", "", mode="stmt"),
    Mutant("nsjoin", NS, "succNum[a] < succNum[b]", "succNum[a] > succNum[b]"),
    Mutant("nsstronglyroot", NS, "net[v] >= 0", "net[v] > 0", nth=1),

    # The checked: lookups.
    Mutant("layerchecked", "SugiyamaLayout.swift", "_drawing._offset(of: vertex)", "Optional(_drawing._offset(of: vertex) ?? 0)", nth=1),
    Mutant("layercheckedvalue", "SugiyamaLayout.swift", "        return _layers[i]", "        return 0", mode="stmt", nth=1),
    Mutant("bendscheckedrange", "SugiyamaLayout.swift", "lo < _positions.count", "true", nth=1),
    Mutant("bendscheckedmatch", "SugiyamaLayout.swift", "_positions[lo] == position", "true", nth=1),
    Mutant("bendscheckedsearch", "SugiyamaLayout.swift", "_positions[mid] < position", "_positions[mid] <= position", nth=1),
    Mutant("bendscheckedvalue", "SugiyamaLayout.swift", "        return _bends[_bendStart[lo] ..< _bendStart[lo + 1]]", "        return _bends[_bendStart[lo] ..< _bendStart[lo]]", mode="stmt", nth=1),

    # Barnes–Hut with masses (ForceAtlas2).
    Mutant("qtmasssum", F, "sum += m * positions[order[i]]", "sum += positions[order[i]]", mode="stmt"),
    Mutant("qtmasstotal", F, "total += m", "total += 1", mode="stmt"),
    Mutant("qtmassleaf", F, "sum += delta * (masses[u] / Swift.max(d2, 1e-4))", "sum += delta / Swift.max(d2, 1e-4)", mode="stmt"),
    Mutant("qtmasscell", F, "sum += delta * (mass[cell] / Swift.max(d2, 1e-4))", "sum += delta / Swift.max(d2, 1e-4)", mode="stmt"),
    Mutant("qtmassinside", F, "!inside && s * s < theta * theta * d2", "s * s < theta * theta * d2", nth=0),
    Mutant("qtmasscoincident", F, "if u != v { sum += _coincidentOffset(v, u) * (masses[u] / 1e-4) }", "", mode="stmt"),

    # The shell, spiral, bipartite and random layouts.
    Mutant("shradius", SH, "radius.isFinite && radius >= 0", "radius.isFinite && radius > 0"),
    Mutant("shcenter", SH, "center.x.isFinite && center.y.isFinite", "true"),
    Mutant("shrotation", SH, "rotation.isFinite", "true"),
    Mutant("shdefaultfirst", SH, "rotation ?? Double.pi", "rotation ?? 0", nth=0),
    Mutant("shdefaultstep", SH, "2 * Double.pi / Double(n)", "2 * Double.pi / Double(n + 1)"),
    Mutant("shdefaultangle", SH, "Double(i) * step + first", "Double(i) * step"),
    Mutant("shdefaultone", SH, "n > 1", "n > 0", nth=0),
    Mutant("shbump", SH, "radius / Double(Swift.max(shells.count, 1))", "radius / Double(Swift.max(shells.count, 2))"),
    Mutant("shturn", SH, "rotation ?? Double.pi / Double(Swift.max(shells.count, 1))", "rotation ?? Double.pi"),
    Mutant("shfirstsingle", SH, "shells.first?.count == 1 ? 0 : bump", "bump"),
    Mutant("shrepeat", SH, "precondition(!placed[i], \"\\(v) is in more than one shell\")", "", mode="stmt"),
    Mutant("shcount", SH, "count == n", "true"),
    Mutant("shbumpstep", SH, "            r += bump", "", mode="stmt"),
    Mutant("shturnstep", SH, "            first += turn", "", mode="stmt"),
    Mutant("shangle", SH, "Double(j) * step + first", "Double(j) * step"),
    Mutant("shshellone", SH, "if n > 1 { positions[i] = center + r * SIMD2(cos(angle), sin(angle)) }", "positions[i] = center + r * SIMD2(cos(angle), sin(angle))", mode="stmt"),
    Mutant("spres", SH, "resolution.isFinite && (!equidistant || resolution > 0)", "resolution.isFinite"),
    Mutant("spone", SH, "    if n == 1 { return [.zero] }", "", mode="stmt"),
    Mutant("spstart", SH, "        theta += 1 / (0.5 * theta)", "", mode="stmt"),
    Mutant("sprho", SH, "0.5 * theta", "theta", nth=1),
    Mutant("spstep", SH, "            theta += 1 / rho", "", mode="stmt"),
    Mutant("spangle", SH, "resolution * distance", "resolution"),
    Mutant("spswap", SH, "SIMD2(distance * cos(angle), distance * sin(angle))", "SIMD2(distance * sin(angle), distance * cos(angle))"),
    Mutant("bpaspect", MP, "aspectRatio.isFinite && aspectRatio > 0", "aspectRatio.isFinite"),
    Mutant("bprepeat", MP, "precondition(!isLeft[i], \"\\(v) is listed twice in the left column\")", "", mode="stmt"),
    Mutant("bpstep", MP, "k > 1 ? 1 / Double(k - 1) : 0", "1 / Double(k)"),
    Mutant("bpoffset", MP, "                positions[i] = SIMD2(x, (j == k - 1 && k > 1 ? 1 : Double(j) * step) - 0.5)", "                positions[i] = SIMD2(x, j == k - 1 && k > 1 ? 1 : Double(j) * step)", mode="stmt"),
    Mutant("bplast", MP, "j == k - 1 && k > 1 ? 1 : Double(j) * step", "Double(j) * step", nth=1),
    Mutant("bpright", MP, "(rightOffsets, aspectRatio / 2)", "(rightOffsets, -aspectRatio / 2)"),
    Mutant("mpshift", MP, "Double(columns - 1) / 2", "Double(columns) / 2"),
    Mutant("mplift", MP, "Double(end - k - 1) / 2", "Double(end - k) / 2"),
    Mutant("mpcolumn", MP, "        column += 1", "", mode="stmt"),
    Mutant("mprank", MP, "for (r, l) in rank.keys.sorted().enumerated() { rank[l] = r }", "for (r, l) in rank.keys.enumerated() { rank[l] = r }", mode="stmt"),
    Mutant("mpcount", MP, "for r in 0 ..< rank.count { start[r + 1] += start[r] }", "", mode="stmt"),
    Mutant("mpsame", MP, "layer[sequence[end]] == layer[sequence[k]]", "false", nth=1),
    Mutant("bfsqueue", MP, "_columnPositions(layer, sequence: queue)", "_columnPositions(layer, sequence: _byLayer(layer))"),
    Mutant("rdbits", SH, "Double(generator.next() >> 11) * 0x1p-53", "Double(generator.next() >> 12) * 0x1p-53", nth=0),
    Mutant("rdorder", SH, "positions.append(SIMD2(x, y))", "positions.append(SIMD2(y, x))", mode="stmt"),

    # The spectral and scaling layouts, and their eigensystem.
    Mutant("spweight", SP, "w.isFinite && w >= 0", "w.isFinite"),
    Mutant("spsmall", SP, "    if n <= 1 { return [SIMD2<Double>](repeating: .zero, count: n) }", "", mode="stmt", nth=0),
    Mutant("spscale", SP, "weights[e] * scale", "weights[e]"),
    Mutant("spdiag", SP, "laplacian[v * n + v] += w", "", mode="stmt"),
    Mutant("spoff", SP, "laplacian[u * n + v] -= w", "", mode="stmt"),
    Mutant("spcolumns", SP, "n >= 3 ? 2 : 1", "1"),
    Mutant("spsign", SP, "for c in 1 ... columns { _fixEigenvectorSign(UnsafeMutableBufferPointer(rebasing: vectors[c * n ..< c * n + n])) }", "", mode="stmt"),
    Mutant("spx", SP, "vectors[n + i]", "vectors[i]"),
    Mutant("mdlength", SP, "x.isFinite && x > 0", "x.isFinite && x >= 0"),
    Mutant("mdsmall", SP, "    if n <= 1 { return [SIMD2<Double>](repeating: .zero, count: n) }", "", mode="stmt", nth=1),
    Mutant("mdmean", SP, "lengths.reduce(0, +) / Double(lengths.count)", "lengths.reduce(0, +)"),
    Mutant("mdapart", SP, "1 + mean * Double(n).squareRoot()", "1 + mean * Double(n)"),
    Mutant("mdsquare", SP, "b[s * n + v] = d * d", "b[s * n + v] = d", mode="stmt"),
    Mutant("mdhalf", SP, "        for v in 0 ..< n { b[s * n + v] = -0.5 * (b[s * n + v] - rowMeans[s] - rowMeans[v] + grandMean) }", "        for v in 0 ..< n { b[s * n + v] = -(b[s * n + v] - rowMeans[s] - rowMeans[v] + grandMean) }", mode="stmt"),
    Mutant("mdcentre", SP, "b[s * n + v] - rowMeans[s] - rowMeans[v] + grandMean", "b[s * n + v] - rowMeans[s] - rowMeans[v]", nth=1),
    Mutant("mdunscale", SP, "Swift.max(values[n - 1], 0).squareRoot() / scale", "Swift.max(values[n - 1], 0).squareRoot()"),
    Mutant("mdaxis", SP, "Swift.max(values[n - 2], 0)", "Swift.max(values[n - 1], 0)"),
    Mutant("mdsign", SP, "n - 2 ..< n", "n - 1 ..< n"),
    Mutant("egsortswap", EG, "ck[r] = t", "", mode="stmt", module="SpectralGraphTheory"),
    Mutant("egsort", EG, "d[j] < p", "d[j] > p", module="SpectralGraphTheory"),
    Mutant("egscale", EG, "e[i] = scale * g", "e[i] = g", mode="stmt", module="SpectralGraphTheory"),
    Mutant("eghh", EG, "f / (h + h)", "f / h", module="SpectralGraphTheory"),
    Mutant("egshift", EG, "        d[l] += f", "", mode="stmt", module="SpectralGraphTheory"),
    Mutant("eglimit", EG, "total < maxIterations", "true", module="SpectralGraphTheory"),
    Mutant("egdeflate", EG, "abs(e[m]) <= eps * tst1", "false", module="SpectralGraphTheory"),
    Mutant("egsign", SP, "if x < 0 { for k in column.indices { column[k] = -column[k] } }", "", mode="stmt"),
    Mutant("egsignthreshold", SP, "Swift.abs(x) >= 1e-4 * largest", "Swift.abs(x) > 0"),
    Mutant("eglimitcheck", SP, "maxIterations >= 1", "true"),
    Mutant("egaccumulate", EG, "for k in 0 ... i { column[k] -= g * d[k] }", "", mode="stmt", module="SpectralGraphTheory"),

    # ForceAtlas2.
    Mutant("faiterations", FA, "iterations >= 0", "true"),
    Mutant("fascaling", FA, "scalingRatio.isFinite && scalingRatio > 0", "scalingRatio.isFinite && scalingRatio >= 0"),
    Mutant("fagravity", FA, "gravity.isFinite && gravity >= 0", "true"),
    Mutant("fajittercheck", FA, "jitterTolerance.isFinite && jitterTolerance >= 0", "true"),
    Mutant("fathetacheck", FA, "barnesHutTheta.isFinite && barnesHutTheta >= 0", "barnesHutTheta.isFinite"),
    Mutant("faweight", FA, "w.isFinite && w >= 0", "w.isFinite"),
    Mutant("fathetazero", FA, "barnesHutTheta.flatMap { $0 > 0 ? $0 : nil }", "barnesHutTheta"),
    Mutant("fafinished", FA, "_iteration >= _iterations", "_iteration > _iterations"),
    Mutant("fastartbits", FA, "Double(generator.next() >> 11) * 0x1p-53", "Double(generator.next() >> 12) * 0x1p-53", nth=0),
    Mutant("famass", FA, "masses[vs[e]] += 1", "", mode="stmt"),
    Mutant("facompensation", FA, "masses.reduce(0, +) / Double(n)", "1"),
    Mutant("fabhmass", FA, "tree.massRepulsion(on: v, p, theta: theta) * (kr * masses[v])", "tree.massRepulsion(on: v, p, theta: theta) * kr"),
    Mutant("farepcoincident", FA, "if u != v { sum += _coincidentOffset(v, u) * (m[u] / 1e-4) }", "", mode="stmt"),
    Mutant("farepfloor", FA, "sum += delta * (m[u] / Swift.max(d2, 1e-4))", "sum += delta * (m[u] / Swift.max(d2, 1e-2))", mode="stmt"),
    Mutant("farepmass", FA, "f[v] = sum * (kr * m[v])", "f[v] = sum * kr", mode="stmt"),
    Mutant("fastrong", FA, "f[v] -= pv * (gravity * m[v])", "f[v] -= pv * gravity", mode="stmt"),
    Mutant("faweak", FA, "if d > 0 { f[v] -= pv * (gravity * m[v] / d) }", "if d > 0 { f[v] -= pv * (gravity * m[v]) }", mode="stmt"),
    Mutant("falinlog", FA, "factor * log1p(d) / d", "factor * log1p(d)"),
    Mutant("fahubs", FA, "if let compensation { factor *= compensation / m[a] }", "if let compensation { factor *= compensation / m[b] }", mode="stmt"),
    Mutant("faattract", FA, "f[b] += pull", "", mode="stmt"),
    Mutant("faswing", FA, "totalSwing += masses[v] * (change * change).sum().squareRoot()", "totalSwing += (change * change).sum().squareRoot()", mode="stmt"),
    Mutant("fatraction", FA, "totalTraction += 0.5 * masses[v] * (sum * sum).sum().squareRoot()", "totalTraction += masses[v] * (sum * sum).sum().squareRoot()", mode="stmt"),
    Mutant("fajitteropt", FA, "0.05 * Double(n).squareRoot()", "0.05 * Double(n)"),
    Mutant("fajittermin", FA, "Swift.max(minimumJitter, Swift.min(10, optimalJitter * totalTraction / Double(n * n)))", "Swift.min(10, optimalJitter * totalTraction / Double(n * n))"),
    Mutant("faratio", FA, "totalSwing > 2 * totalTraction", "totalSwing >= 2 * totalTraction"),
    Mutant("fahalf", FA, "if speedEfficiency > minimumEfficiency { speedEfficiency *= 0.5 }", "", mode="stmt"),
    Mutant("fajitterfloor", FA, "jitter = Swift.max(jitter, jitterTolerance)", "", mode="stmt"),
    Mutant("fatarget", FA, "jitter * speedEfficiency * totalTraction / totalSwing", "jitter * totalTraction / totalSwing"),
    Mutant("faeffdown", FA, "if speedEfficiency > minimumEfficiency { speedEfficiency *= 0.7 }", "", mode="stmt"),
    Mutant("faeffup", FA, "speedEfficiency *= 1.3", "", mode="stmt"),
    Mutant("farise", FA, "Swift.min(target - speed, 0.5 * speed)", "target - speed"),
    Mutant("famove", FA, "s / (1 + (s * swing).squareRoot())", "s"),
    Mutant("faprevious", FA, "old[v] = f[v]", "", mode="stmt"),

    # The planar straight-line layout.
    Mutant("plloop", PL, "w != v && (rows.count == first || rows[rows.count - 1] != w)", "rows.count == first || rows[rows.count - 1] != w"),
    Mutant("pldedupe", PL, "rows[rows.count - 1] != w", "true", nth=1),
    Mutant("plwrap", PL, "if rows.count - first > 1 && rows[rows.count - 1] == rows[first] { rows.removeLast() }", "", mode="stmt"),
    Mutant("plsmall", PL, "n < 4", "n < 3"),
    Mutant("plconnect", PL, "if previousRoot >= 0 { _ = g.join(previousRoot, clockwiseOf: -1, root, counterclockwiseOf: -1) }", "", mode="stmt"),
    Mutant("plouter", PL, "face.count > outerFace.count", "face.count < outerFace.count"),
    Mutant("pltriangulate", PL, "for (k, start) in faceStarts.enumerated() where k != outer { _triangulateFace(&g, from: start) }", "", mode="stmt"),
    Mutant("pljoined", PL, "g.isJoined(v1, v3)", "false"),
    Mutant("plchord", PL, "stamp[v2] == mark", "false"),
    Mutant("plchords", PL, "chords[v] += 1", "", mode="stmt", nth=0),
    Mutant("plready", PL, "    ready[v1] = false", "", mode="stmt"),
    Mutant("plcontourtwo", PL, "contourEnd[k] - contourStart[k] == 2", "contourEnd[k] - contourStart[k] == 3"),
    Mutant("plchordsdown", PL, "chords[x] -= 1", "", mode="stmt"),
    Mutant("plnewface", PL, "newOnFace[y] != k", "true"),
    Mutant("plwp", PL, "outer.clockwise[w] == v", "outer.counterclockwise[w] == v"),
    Mutant("plcontourcw", PL, "outer.clockwise[w] = following", "", mode="stmt"),
    Mutant("plshiftp", PL, "deltaX[wp1] += 1", "", mode="stmt"),
    Mutant("plshiftq", PL, "deltaX[wq] += 1", "", mode="stmt"),
    Mutant("pldx", PL, "(-y[wp] + span + y[wq]) / 2", "(span + y[wq]) / 2"),
    Mutant("ply", PL, "(y[wp] + span + y[wq]) / 2", "(span + y[wq]) / 2"),
    Mutant("pldxq", PL, "deltaX[wq] = span - deltaX[vk]", "", mode="stmt"),
    Mutant("pldxp", PL, "if addsTriangles { deltaX[wp1] -= deltaX[vk] }", "", mode="stmt"),
    Mutant("plcut", PL, "rightChild[wq1] = -1", "", mode="stmt"),
    Mutant("plx", PL, "x[right] = x[parent] + deltaX[right]", "x[right] = deltaX[right]", mode="stmt"),
]
