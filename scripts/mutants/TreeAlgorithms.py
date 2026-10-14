# Planted bugs for TreeAlgorithms; run with `just mutate TreeAlgorithms`. See scripts/mutate.py.
#
# Known equivalent mutants:
#   nancheck  NaN >= .zero is already false, so `w == w` never decides on its own.

TESTS = ["TreeAlgorithmsTests"]

MUTANTS = [
    # One-shot lowest common ancestor
    Mutant("climbdepth", "LowestCommonAncestor.swift", "while nodes[x].depth > nodes[y].depth { x = nodes[x].parent }", "while nodes[x].depth > nodes[y].depth + 1 { x = nodes[x].parent }", mode="stmt"),

    # The range-minimum structure
    Mutant("rangestart", "LowestCommonAncestor.swift", "_rangeMinimum(p + 1, q)", "_rangeMinimum(p, q)"),
    Mutant("samevertex", "LowestCommonAncestor.swift", "        if a == b { return a }", "", mode="stmt"),
    Mutant("stackpop", "LowestCommonAncestor.swift", "minima[start + top] >= value", "minima[start + top] > value + 1"),
    Mutant("inblockshift", "LowestCommonAncestor.swift", "_masks[r] >> UInt64(l - start)", "_masks[r]"),
    Mutant("blockedge", "LowestCommonAncestor.swift", "_inBlock(l, (bl << 6) + 63)", "_inBlock(l, (bl << 6) + 62)"),
    Mutant("tablelevel", "LowestCommonAncestor.swift", "_table[level + hi - (1 << k) + 1]", "_table[level + lo]"),
    Mutant("middleblocks", "LowestCommonAncestor.swift", "bl + 1 <= br - 1", "false"),
    Mutant("distance", "LowestCommonAncestor.swift", "Int(_depth[a]) + Int(_depth[b]) - 2 * Int(_depth[c])", "Int(_depth[a]) + Int(_depth[b]) - Int(_depth[c])"),

    # Euler tour
    Mutant("tourclimb", "EulerTour.swift", "current != root", "false"),

    # Heavy–light decomposition
    Mutant("heavytie", "HeavyLightDecomposition.swift", "layout.nodes[w].size > bestSize", "layout.nodes[w].size >= bestSize"),
    Mutant("heavyhead", "HeavyLightDecomposition.swift", "head[heavy[v]] = head[v]", "head[heavy[v]] = heavy[v]"),
    Mutant("lightorder", "HeavyLightDecomposition.swift", "layout.rowOffsets[v + 1] - 1", "layout.rowOffsets[v + 1] - 1 - (layout.rowOffsets[v + 1] - layout.rowOffsets[v] > 2 ? 1 : 0)"),
    Mutant("heavynext", "HeavyLightDecomposition.swift", "_head[_order[next]] == _head[index]", "true"),
    Mutant("liftside", "HeavyLightDecomposition.swift", "_layout.nodes[_head[x]].depth >= _layout.nodes[_head[y]].depth", "_layout.nodes[_head[x]].depth > _layout.nodes[_head[y]].depth + 1", nth=1),
    Mutant("upreversed", "HeavyLightDecomposition.swift", "range.count > 1", "range.count > 0"),
    Mutant("shareddir", "HeavyLightDecomposition.swift", "goingUp && shared.count > 1", "goingUp"),
    Mutant("dropancestor", "HeavyLightDecomposition.swift", "includingCommonAncestor ? low : low + 1", "low"),
    Mutant("tailmove", "HeavyLightDecomposition.swift", "initialized = front + tail", "initialized = front + (tail > 1 ? tail - 1 : tail)"),
    Mutant("hldlca", "HeavyLightDecomposition.swift", "_layout.nodes[x].depth <= _layout.nodes[y].depth ? x : y", "x"),
    Mutant("subtree", "HeavyLightDecomposition.swift", "_position[index] ..< _position[index] + _layout.nodes[index].size", "_position[index] ..< _position[index] + _layout.nodes[index].size - 1"),

    # Eccentricities
    Mutant("secondchain", "CenterAndDiameter.swift", "                down2[p] = down1[p]", "", mode="stmt"),
    Mutant("sideways", "CenterAndDiameter.swift", "through[p] == v ? down2[p] : down1[p]", "down1[p]"),
    Mutant("upchain", "CenterAndDiameter.swift", "max(up[p], sideways)", "sideways"),
    Mutant("weightcheck", "CenterAndDiameter.swift", "w >= .zero && w == w", "w == w"),
    Mutant("nancheck", "CenterAndDiameter.swift", "w >= .zero && w == w", "w >= .zero"),
    Mutant("diameterend", "CenterAndDiameter.swift", "distance[x] > distance[v]", "distance[x] >= distance[v]"),
    Mutant("diameterstart", "CenterAndDiameter.swift", "eccentricity.firstIndex(of: greatest)!", "eccentricity.lastIndex(of: greatest)!"),

    # Centroid
    Mutant("centroidabove", "Centroid.swift", "            part[v] = max(part[v], n - size)", "", mode="stmt"),
    Mutant("centroidhalf", "Centroid.swift", "2 * part[$0] <= n", "2 * part[$0] < n"),
    Mutant("decompfirst", "Centroid.swift", "centroid < 0 || x < centroid", "true"),
    Mutant("decomphalf", "Centroid.swift", "2 * largest <= m", "2 * largest <= m + 2"),
    Mutant("decomprest", "Centroid.swift", "m - size[x]", "0"),

    # The checked: spellings: each one's own reading after the lookup (Trees' `checkednumber`
    # covers the lookup).
    Mutant("checkedclimbrooted", "LowestCommonAncestor.swift", "_climbingLowestCommonAncestor(_layout, x, y)", "_climbingLowestCommonAncestor(_layout, x, x)", nth=0),
    Mutant("checkedclimbarb", "LowestCommonAncestor.swift", "_climbingLowestCommonAncestor(_layout, x, y)", "_climbingLowestCommonAncestor(_layout, y, y)", nth=1),
    Mutant("checkedlcas", "LowestCommonAncestor.swift", "lowestCommonAncestor(ofIndex: x, y)", "lowestCommonAncestor(ofIndex: x, x)"),
    Mutant("checkedlcasdistance", "LowestCommonAncestor.swift", "distance(fromIndex: x, toIndex: y)", "distance(fromIndex: x, toIndex: x)"),
    Mutant("checkedheavy", "HeavyLightDecomposition.swift", "_layout.vertices[$0]", "_layout.vertices[0]", nth=1),
    Mutant("checkedhead", "HeavyLightDecomposition.swift", "        _layout.vertices[_head[try _layout.checkedNumber(of: vertex)]]", "        _layout.vertices[try _layout.checkedNumber(of: vertex)]", mode="stmt"),
    Mutant("checkedposition", "HeavyLightDecomposition.swift", "        _position[try _layout.checkedNumber(of: vertex)]", "        _head[try _layout.checkedNumber(of: vertex)]", mode="stmt"),
    Mutant("checkedsubtree", "HeavyLightDecomposition.swift", "        subtree(ofIndex: try _layout.checkedNumber(of: vertex))", "        subtree(ofIndex: 0)", mode="stmt"),
    Mutant("checkedhldlca", "HeavyLightDecomposition.swift", "lowestCommonAncestor(ofIndex: x, y)", "lowestCommonAncestor(ofIndex: y, y)"),
    Mutant("checkedsegments", "HeavyLightDecomposition.swift", "        return segments(fromIndex: x, toIndex: y, includingCommonAncestor: includingCommonAncestor)", "        return segments(fromIndex: x, toIndex: y, includingCommonAncestor: true)", mode="stmt"),
    # Tree edit distance (Zhang–Shasha)
    Mutant("tedkeyroots", "TreeEditDistance.swift", "parent < 0 || leftmost[position[parent]] != leftmost[p]", "parent < 0"),
    Mutant("tedleftmost", "TreeEditDistance.swift", "leftmost[p] = p - node.size + 1", "leftmost[p] = p - node.size + (node.size > 2 ? 2 : 1)", mode="stmt"),
    Mutant("tedwhole", "TreeEditDistance.swift", "wholeA && lb[q] == lj", "lb[q] == lj"),
    Mutant("tedinsert", "TreeEditDistance.swift", "if inserted < best { best = inserted }", "", mode="stmt"),
    Mutant("tedsubstitute", "TreeEditDistance.swift", "if substituted < best { best = substituted }", "", mode="stmt"),
    Mutant("tedmatched", "TreeEditDistance.swift", "fd[(la[p] - li) * stride + lb[q] - lj]", "fd[(la[p] - li) * stride]"),
    Mutant("tedmatchedmin", "TreeEditDistance.swift", "if matched < best { best = matched }", "best = matched", mode="stmt"),
    Mutant("tedfirstcolumn", "TreeEditDistance.swift", "deletion[li + x - 1]", "deletion[li]"),
    Mutant("tedfirstrow", "TreeEditDistance.swift", "insertion[lj + y - 1]", "insertion[lj]"),
    Mutant("tedresult", "TreeEditDistance.swift", "treeDistance[n * m - 1]", "treeDistance[n * m - 1 - (n * m > 1 ? 1 : 0)]"),
]
