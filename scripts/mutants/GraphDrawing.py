# Planted bugs for GraphDrawing: Drawing, the circular layout, Fruchterman–Reingold (exact and
# Barnes–Hut), stress majorization, Reingold–Tilford (Walker / Buchheim–Jünger–Leipert) and the
# Sugiyama pipeline (network simplex layering, barycenter crossing reduction, Brandes–Köpf); run
# with `just mutate GraphDrawing`. See scripts/mutate.py.
#
# The survivors of the first run were closed by GraphDrawingPlantedBugTests. The Sugiyama ones were
# found by a scratch harness that builds against the mutation workspace and compares, for each
# mutant (GRAFLUENT_MUTANT), the layered drawings of 20 000 – 30 000 random digraphs with the
# unmutated ones; a graph that tells several apart is pinned there.
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
#                   them, and which optimal layering is chosen is not specified (README.md). They
#                   give up Cunningham's strongly feasible tree, which is what rules out cycling;
#                   no input that cycles was found.
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
    Mutant("qtmass", F, "mass.append(Double(h - l))", "mass.append(1)", mode="stmt"),
    Mutant("qtcentre", F, "centre.append(sum / Double(h - l))", "centre.append(c + s / 2)", mode="stmt"),
    Mutant("qtinside", F, "!inside && s * s < theta * theta * d2", "s * s < theta * theta * d2"),
    Mutant("qttheta", F, "s * s < theta * theta * d2", "s < theta * d2", nth=1),
    Mutant("qtcoincident", F, "if u != v { sum += _coincidentOffset(v, u) * (k2 / 1e-4) }", "", mode="stmt", nth=0),
    Mutant("qtchildren", F, "for child in first ..< first + childCount[cell] { stack.append(child) }", "for child in first ..< first + childCount[cell] - 1 { stack.append(child) }", mode="stmt"),
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
    Mutant("smuniform", S, "lengths.allSatisfy { $0 == lengths[0] }", "true"),
    Mutant("smbfs", S, "hops[v] + 1", "hops[v] + 2"),
    Mutant("smunit", S, "Double(hops[v]) * unit", "Double(hops[v])"),
    Mutant("smrelax", S, "d + length[slot]", "length[slot]"),
    Mutant("smpush", S, "heap[i].0 < heap[(i - 1) / 2].0", "heap[i].0 > heap[(i - 1) / 2].0"),
    Mutant("smpopleft", S, "if l < heap.count, heap[l].0 < heap[m].0 { m = l }", "", mode="stmt"),
    Mutant("smpopright", S, "if r < heap.count, heap[r].0 < heap[m].0 { m = r }", "", mode="stmt"),
    Mutant("smadjreverse", S, "neighbor[fill[vs[e]]] = us[e]", "neighbor[fill[vs[e]]] = vs[e]", mode="stmt"),
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
    Mutant("sgbendsearch", SG, "_positions[mid] < position", "_positions[mid] <= position"),
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
]
