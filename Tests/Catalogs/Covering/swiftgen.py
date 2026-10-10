"""Writes the catalog-row test files of Tests/CoveringTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 swiftgen.py [OUT_DIR]   # default: Tests/CoveringTests

First runs ref.py's catalog with each case builder instrumented, so every row's inputs are kept
as structured values, and checks that the rendered catalog equals cases.md (the Checked cells that
depend on igraph are normalized, since igraph may be absent). Then re-evaluates each row with
ref.py's model functions, asserts each value matches its catalog cell, and writes one @Test per
row. The representation rows (AdjacencyList and AdjacencyMatrix through `.undirected`) are
recomputed with the same models on those representations' rows and positions: successors then
predecessors, arcs in insertion order (AdjacencyList) or at row-major cells (AdjacencyMatrix).
"""
import copy
import json
import os
import re
import sys
from collections import deque
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "CoveringTests")
os.chdir(HERE)
import ref  # noqa: E402

RECORDS = []


def instrument(kind, fn):
    def wrapper(*args, **kwargs):
        RECORDS.append((kind, args, kwargs))
        return fn(*args, **kwargs)
    return wrapper


KINDS = ["mis", "alpha", "vc", "konig", "approx_vc", "maximal_is", "mds", "approx_ds", "ec", "ec_bip", "check", "trap"]
for kind in KINDS:
    setattr(ref, f"case_{kind}", instrument(kind, getattr(ref, f"case_{kind}")))
ref.build()
assert not ref.FAILS, ref.FAILS
assert len(RECORDS) == len(ref.CASES) == 220

text = ref.HEADER.replace("{last}", f"{len(ref.CASES):03d}").replace("{count}", str(len(ref.CASES)))
for i, (grp, name, inp, call, exp, chk) in enumerate(ref.CASES):
    text += f"| CV-{i+1:03d} | {grp} | {name} | {inp} | `{call}` | {exp} | {chk} |\n"


def normalize(t):
    t = t.replace("; least of igraph largest_independent_vertex_sets", "")
    t = t.replace("igraph independence_number; ", "")
    t = t.replace("; = igraph is_independent_vertex_set", "")
    t = t.replace("; igraph ignores self-loops and says True", "")
    # NetworkX's dominating_set pops a Python set: for string vertices its order follows the hash seed.
    return re.sub(r"; = NetworkX dominating_set\(start_with: [a-z]\)", "", t)


with open(os.path.join(HERE, "cases.md")) as f:
    assert normalize(f.read()) == normalize(text), "cases.md is not ref.py's output"
CELLS = {}
for line in open(os.path.join(HERE, "cases.md")).read().splitlines():
    if line.startswith("| CV-"):
        parts = [p.strip() for p in line.strip().strip("|").split(" | ")]
        CELLS[parts[0]] = parts
assert len(CELLS) == 220

# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------


def lit(x):
    if x is None:
        return "nil"
    if isinstance(x, str):
        return json.dumps(x, ensure_ascii=False)
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, float):
        return repr(x)
    return str(x)


def arr(xs, T=None):
    s = "[" + ", ".join(lit(x) for x in xs) + "]"
    if T and not xs:
        return f"[] as [{T}]"
    return s


def tarr(xs, T):
    return "[" + ", ".join(lit(x) for x in xs) + f"] as [{T}]"


def vtype(g):
    return "String" if any(isinstance(v, str) for v in g.V) else "Int"


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def fname(cid):
    return "cv" + cid[3:]


def title(cid, maxlen=118):
    parts = CELLS[cid]
    name, exp = parts[2], parts[5]
    exp = exp.replace("`", "")
    t = f"{cid} {name}"
    if len(t) + len(exp) + 2 <= maxlen:
        t += ": " + exp
    return esc(t)


def comment_input(cid):
    parts = CELLS[cid]
    s = f"{parts[3]}; {parts[4]}".replace("`", "")
    if len(s) > 180:
        s = s[:177] + "…"
    return "// " + s


def small(g):
    return g.n <= 16


# ---------------------------------------------------------------------------------------------
# Representations
# ---------------------------------------------------------------------------------------------


def adjlist_repr(g):
    """AdjacencyList(arcs as written).undirected: positions are the arcs in order; each row is
    out-arcs then in-arcs, each in insertion order. None if an arc repeats."""
    arcs = list(g.E)
    if len(set(arcs)) != len(arcs):
        return None
    h = copy.copy(g)
    outs = [[] for _ in g.V]
    ins = [[] for _ in g.V]
    for e, (u, v) in enumerate(g.E):
        outs[g.idx[u]].append((g.idx[v], e))
        ins[g.idx[v]].append((g.idx[u], e))
    h.rows = [outs[i] + ins[i] for i in range(g.n)]
    h.posmap = list(range(len(g.E)))
    return h


def matrix_repr(g):
    """AdjacencyMatrix(vertexCount: n, arcs).undirected for vertices 0..<n in order: positions are
    the cells in row-major order; each row is successors ascending, then predecessors ascending."""
    if g.V != list(range(g.n)):
        return None
    arcs = list(g.E)
    if len(set(arcs)) != len(arcs):
        return None
    cells = sorted(arcs)
    pos = {c: k for k, c in enumerate(cells)}
    h = copy.copy(g)
    h.E = cells
    rows = []
    for v in range(g.n):
        succ = sorted(t for (s, t) in cells if s == v)
        pred = sorted(s for (s, t) in cells if t == v)
        rows.append([(t, pos[(v, t)]) for t in succ] + [(s, pos[(s, v)]) for s in pred])
    h.rows = rows
    h.posmap = [pos[a] for a in arcs]
    h.cells = cells
    return h


def canonical_sides(g):
    bp = ref.bipartition_canonical(g)
    return bp


# ---------------------------------------------------------------------------------------------
# Graph construction lines
# ---------------------------------------------------------------------------------------------


def pairs_line(g, T):
    return f"let pairs: [({T}, {T})] = [" + ", ".join(f"({lit(u)}, {lit(v)})" for (u, v) in g.E) + "]"


def build_graph(g, rep, T):
    """Lines that define `graph` (and `pairs`) for a representation."""
    L = [pairs_line(g, T)]
    if rep == "primary":
        rep = {"graph": "ual", "multigraph": "pseudo", "bipartite": "bipartite"}[g.kind]
    if rep == "ual":
        L.append(f"let graph = UndirectedAdjacencyList<{T}>(vertices: {tarr(g.V, T)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
    elif rep == "pseudo":
        L.append(f"let graph = ReferencePseudograph<{T}>(vertices: {tarr(g.V, T)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
    elif rep == "bipartite":
        L.append(f"let graph = try #require(BipartiteGraph<{T}>(left: {tarr(g.left, T)}, right: {tarr(g.right, T)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }}))")
        L.append(f"#expect(Array(graph.left) == {tarr(g.left, T)})")
    elif rep == "unindexed":
        L.append(f"let graph = UnindexedGraph<{T}>(vertices: {tarr(g.V, T)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        L.append("#expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)")
    elif rep == "al":
        L.append(f"let graph = AdjacencyList<{T}>(vertices: {tarr(g.V, T)}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected")
    elif rep == "am":
        L.append(f"let graph = AdjacencyMatrix(vertexCount: {g.n}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected")
    else:
        raise ValueError(rep)
    L.append(f"#expect(graph.edgeCount == {len(g.E)})")
    return L


def prelude(g, T):
    """Common lines after the graph: the vertex list, its order, and edge ends as indices."""
    return [
        "let vertexList = Array(graph.vertices)",
        f"#expect(vertexList == {tarr(g.V, T)})",
        "let n = vertexList.count",
        "// Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).",
        "let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }",
    ]


def order_lines(var):
    return [
        "// In `vertices` order, each vertex once.",
        f"let members = {var}.map {{ vertexList.firstIndex(of: $0)! }}",
        "#expect(members == members.sorted() && Set(members).count == members.count)",
        "let inSet = Set(members)",
    ]


INDEPENDENT_DEF = [
    "// Independent, checked here: no edge, and no self-loop, has both ends in the set.",
    "for (a, b) in ends { #expect(!(inSet.contains(a) && inSet.contains(b)), \"\\(vertexList[a])–\\(vertexList[b]) inside the set\") }",
]

COVER_DEF = [
    "// A vertex cover, checked here: every edge, and every self-loop, has an end in it.",
    "for (a, b) in ends { #expect(inSet.contains(a) || inSet.contains(b), \"\\(vertexList[a])–\\(vertexList[b]) uncovered\") }",
]

DOMINATING_DEF = [
    "// Dominating, checked here: every vertex is in the set or adjacent to a vertex in it.",
    "for v in 0 ..< n {",
    "    #expect(inSet.contains(v) || ends.contains { ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, \"\\(vertexList[v]) undominated\")",
    "}",
]

BRUTE_LEX_MIS = [
    "// Brute force over every subset (bit i is the vertex at index i): of the independent ones the",
    "// largest, and of those the lexicographically least, the one holding the least vertex of the",
    "// symmetric difference.",
    "var best = -1",
    "for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) {",
    "    let least = (mask ^ max(best, 0)).trailingZeroBitCount",
    "    if best < 0 || mask.nonzeroBitCount > best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }",
    "}",
]

MAXIMAL_IS_DEF = [
    "// Maximal, checked here: every vertex outside the set has a self-loop or a neighbour in it.",
    "for v in 0 ..< n where !inSet.contains(v) {",
    "    #expect(ends.contains { $0 == (v, v) || ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }, \"\\(vertexList[v]) could join\")",
    "}",
]


def weights_decl(ws):
    if any(isinstance(w, float) for w in ws):
        return "let weights: [Double] = [" + ", ".join(repr(float(w)) for w in ws) + "]", "Double"
    return "let weights: [Int] = [" + ", ".join(str(w) for w in ws) + "]", "Int"


def wsum_lit(w, W):
    if W == "Double":
        return repr(float(w))
    return str(w)


# ---------------------------------------------------------------------------------------------
# Row bodies (primary representation)
# ---------------------------------------------------------------------------------------------


def body_mis(cid, g, T):
    got = ref.mis_model(g)
    exp = g.names(got)
    assert ref.fmtl(exp) == CELLS[cid][5], (cid, exp)
    L = ["let result = graph.maximumIndependentSet()", f"#expect(result == {tarr(exp, T)})"]
    L += order_lines("result") + INDEPENDENT_DEF
    L += ["#expect(graph.isIndependentSet(result))",
          "// The other entry points agree: α is its size, and the minimum vertex cover is its complement.",
          "#expect(graph.independenceNumber() == result.count)",
          "#expect(graph.minimumVertexCover() == vertexList.filter { !result.contains($0) })"]
    if small(g):
        L += BRUTE_LEX_MIS + ["#expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })"]
    else:
        L += [f"// {g.n} vertices, too many for brute force here (ref.py checked the row against an",
              "// independence-number oracle and igraph): maximal, at least."]
        L += MAXIMAL_IS_DEF
    return L


def body_alpha(cid, g, T):
    a = len(ref.mis_model(g))
    assert str(a) == CELLS[cid][5]
    L = ["let alpha = graph.independenceNumber()", f"#expect(alpha == {a})",
         "#expect(graph.maximumIndependentSet().count == alpha)",
         "#expect(graph.minimumVertexCover().count == n - alpha)"]
    if small(g):
        L += ["// Brute force: the largest independent subset (bit i is the vertex at index i).",
              "var largest = 0",
              "for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) == 0 || mask & (1 << $0.1) == 0 }) { largest = max(largest, mask.nonzeroBitCount) }",
              "#expect(alpha == largest)"]
    else:
        L += [f"// {g.n} vertices, too many for brute force here (ref.py checked α with igraph and an oracle);",
              "// the independent set it counts is independent."]
        L += ["let result = graph.maximumIndependentSet()"] + order_lines("result") + INDEPENDENT_DEF
    return L


def konig_cover(g, L):
    es = ref.hk_model(g, L)
    return ref.konig_model(g, L, es)


def body_vc(cid, g, T):
    mis = ref.mis_model(g)
    cover = set(range(g.n)) - mis
    exp = g.names(cover)
    assert ref.fmtl(exp) == CELLS[cid][5]
    L = ["let cover = graph.minimumVertexCover()", f"#expect(cover == {tarr(exp, T)})"]
    L += order_lines("cover") + COVER_DEF
    L += ["#expect(graph.isVertexCover(cover))",
          "// The complement of maximumIndependentSet(), n − α vertices.",
          "let independent = graph.maximumIndependentSet()",
          "#expect(cover == vertexList.filter { !independent.contains($0) })",
          "#expect(cover.count == n - graph.independenceNumber())"]
    if small(g):
        L += BRUTE_LEX_MIS + ["// So the cover is the complement of that set, and no cover is smaller.",
                              "#expect(members == (0 ..< n).filter { best & (1 << $0) == 0 })",
                              "var fewest = n",
                              "for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) { fewest = min(fewest, mask.nonzeroBitCount) }",
                              "#expect(cover.count == fewest)"]
    else:
        L += [f"// {g.n} vertices, too many for brute force here (ref.py checked the row against an",
              "// independence-number oracle and igraph): minimal, at least: no vertex can leave it.",
              "for v in members {",
              "    #expect(ends.contains { ($0.0 == v && !inSet.contains($0.1)) || ($0.1 == v && !inSet.contains($0.0)) || $0 == (v, v) }, \"\\(vertexList[v]) could leave\")",
              "}"]
    if g.kind == "bipartite":
        es = ref.hk_model(g, g.left)
        L += ["// König: as large as a maximum matching.",
              f"#expect(cover.count == graph.maximumBipartiteMatching().edges.count)",
              f"#expect(cover.count == {len(es)})"]
        kc = ref.konig_model(g, g.left, es)
        if kc != cover:
            bp = canonical_sides(g)
            kc2 = konig_cover(g, bp[0])
            assert kc2 == kc, cid
            L += ["// König's own cover, the minimum cover with the most left vertices, is another one.",
                  "let sides = try #require(graph.bipartition())",
                  f"#expect(graph.minimumVertexCover(bipartition: sides) == {tarr(g.names(kc), T)})"]
    return L


def body_konig(cid, g, T):
    Lv, Rv = canonical_sides(g)
    kc = konig_cover(g, Lv)
    exp = g.names(kc)
    assert ref.fmtl(exp) == CELLS[cid][5]
    L = ["let sides = try #require(graph.bipartition())",
         f"#expect(Array(sides.left) == {tarr(Lv, T)})",
         f"#expect(Array(sides.right) == {tarr(Rv, T)})",
         "let cover = graph.minimumVertexCover(bipartition: sides)",
         f"#expect(cover == {tarr(exp, T)})"]
    L += order_lines("cover") + COVER_DEF
    L += ["#expect(graph.isVertexCover(cover))",
          "// König's theorem: as large as a maximum matching.",
          "#expect(cover.count == graph.maximumBipartiteMatching(bipartition: sides).edges.count)"]
    if small(g):
        L += ["// Brute force: no cover is smaller, and of the minimum covers exactly one has the most left",
              "// vertices: this one (bit i is the vertex at index i).",
              "let leftMask = sides.left.reduce(0) { $0 | (1 << vertexList.firstIndex(of: $1)!) }",
              "var fewest = n + 1",
              "var minimumCovers: [Int] = []",
              "for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {",
              "    if mask.nonzeroBitCount < fewest {",
              "        fewest = mask.nonzeroBitCount",
              "        minimumCovers = []",
              "    }",
              "    if mask.nonzeroBitCount == fewest { minimumCovers.append(mask) }",
              "}",
              "#expect(cover.count == fewest)",
              "let most = minimumCovers.map { ($0 & leftMask).nonzeroBitCount }.max() ?? 0",
              "#expect(minimumCovers.filter { ($0 & leftMask).nonzeroBitCount == most } == [members.reduce(0) { $0 | (1 << $1) }])"]
    lex = set(range(g.n)) - ref.mis_model(g)
    if lex != kc:
        L += ["// minimumVertexCover() is a different minimum cover: the complement of the lexicographically",
              "// least maximum independent set.",
              f"#expect(graph.minimumVertexCover() == {tarr(g.names(lex), T)})"]
    return L


def body_approx_vc(cid, g, T, weighted, h=None):
    """h: a representation (positions reordered); values computed on it."""
    gg = h if h is not None else g
    got = ref.bye_model(gg)
    exp = g.names(got)
    w = sum(g.weight(v) for v in got)
    if h is None:
        cell = ref.fmtl(exp) + (f"; weight {w}" if weighted else "")
        assert cell == CELLS[cid][5], (cid, cell, CELLS[cid][5])
    L = []
    W = "Int"
    if weighted:
        assert g.V == list(range(g.n))
        decl, W = weights_decl(g.wt)
        L.append(decl)
        L.append("let cover = graph.approximateMinimumVertexCover(weight: { weights[$0] })")
    else:
        L.append("let cover = graph.approximateMinimumVertexCover()")
    L.append(f"#expect(cover == {tarr(exp, T)})")
    if h is not None:
        return L + ["#expect(graph.isVertexCover(cover))"]
    L += order_lines("cover") + COVER_DEF + ["#expect(graph.isVertexCover(cover))"]
    if weighted:
        zero = "0.0" if W == "Double" else "0"
        L += [f"let total = members.reduce({zero}) {{ $0 + weights[$1] }}", f"#expect(total == {wsum_lit(w, W)})"]
    else:
        L += ["let total = cover.count"]
    opt = ref.opt_wvc(g)
    if small(g):
        zero = "0.0" if W == "Double" else "0"
        start = f"(0 ..< n).reduce({zero}) {{ $0 + weights[$1] }}" if weighted else "n"
        sub = f"(0 ..< n).reduce({zero}) {{ mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 }}" if weighted else "mask.nonzeroBitCount"
        L += ["// Within twice the least weight of a vertex cover, found by brute force over every subset.",
              f"var least = {start}",
              "for mask in 0 ..< 1 << n where ends.allSatisfy({ mask & (1 << $0.0) != 0 || mask & (1 << $0.1) != 0 }) {",
              f"    least = min(least, {sub})",
              "}",
              f"#expect(least == {wsum_lit(opt, W)})"]
    else:
        L += [f"// Within twice the least weight of a vertex cover, {opt}: {g.n} vertices are too many for brute",
              "// force here; ref.py found it with NetworkX's max_weight_clique on the complement.",
              f"let least = {wsum_lit(opt, W)}"]
    L += ["#expect(total <= 2 * least)"]
    if not weighted and not any(g.loop):
        L += ["// Unweighted on a loop-free graph: inside the ends of maximalMatching().",
              "let matched = Set(graph.maximalMatching().edges.flatMap { [graph.edges[$0].u, graph.edges[$0].v] })",
              "#expect(cover.allSatisfy { matched.contains($0) })"]
    return L


def body_maximal(cid, g, T, seeds):
    got = ref.maximal_is_model(g, seeds or ())
    call = "graph.maximalIndependentSet()" if seeds is None else f"graph.maximalIndependentSet(containing: {tarr(seeds, T)})"
    L = [f"let result = {call}"]
    if got is None:
        assert CELLS[cid][5] == "nil"
        L += ["#expect(result == nil)",
              "// Why, checked here: two seeds are adjacent, or a seed has a self-loop.",
              f"let seedIndices = Set(({tarr(seeds, T)}).map {{ vertexList.firstIndex(of: $0)! }})",
              "#expect(ends.contains { seedIndices.contains($0.0) && seedIndices.contains($0.1) })"]
        return L
    exp = g.names(got)
    assert ref.fmtl(exp) == CELLS[cid][5]
    L += [f"#expect(result == {tarr(exp, T)})", "let set = try #require(result)" if seeds is not None else "let set = result"]
    L += order_lines("set") + INDEPENDENT_DEF + ["#expect(graph.isIndependentSet(set))"] + MAXIMAL_IS_DEF
    if seeds:
        L += ["// The seeds are in it.", f"#expect(({tarr(seeds, T)}).allSatisfy {{ set.contains($0) }})"]
    else:
        L += ["// Greedy in vertex order, written out: each vertex joins when it has no self-loop and no",
              "// neighbour in the set yet.",
              "var greedy: [Int] = []",
              "for v in 0 ..< n where !ends.contains(where: { $0 == (v, v) || ($0.0 == v && greedy.contains($0.1)) || ($0.1 == v && greedy.contains($0.0)) }) { greedy.append(v) }",
              "#expect(members == greedy)"]
    return L


BRUTE_LEX_DS = [
    "// Brute force over every subset (bit i is the vertex at index i): of the dominating ones the",
    "// smallest, and of those the lexicographically least.",
    "var best = -1",
    "for mask in 0 ..< 1 << n {",
    "    var dominated = mask",
    "    for (a, b) in ends {",
    "        if mask & (1 << a) != 0 { dominated |= 1 << b }",
    "        if mask & (1 << b) != 0 { dominated |= 1 << a }",
    "    }",
    "    guard dominated == (1 << n) - 1 else { continue }",
    "    let least = (mask ^ max(best, 0)).trailingZeroBitCount",
    "    if best < 0 || mask.nonzeroBitCount < best.nonzeroBitCount || (mask.nonzeroBitCount == best.nonzeroBitCount && mask & (1 << least) != 0) { best = mask }",
    "}",
]


def body_mds(cid, g, T):
    got = ref.brute_mds(g)
    exp = g.names(got)
    assert ref.fmtl(exp) == CELLS[cid][5]
    L = ["let result = graph.minimumDominatingSet()", f"#expect(result == {tarr(exp, T)})"]
    L += order_lines("result") + DOMINATING_DEF + ["#expect(graph.isDominatingSet(result))"]
    assert small(g)
    L += BRUTE_LEX_DS + ["#expect(members == (0 ..< n).filter { best & (1 << $0) != 0 })"]
    m = re.search(r"greedy gives (\d+)", CELLS[cid][6])
    if m:
        L += ["// The greedy approximation needs more.", f"#expect(graph.approximateMinimumDominatingSet().count == {m.group(1)})"]
    return L


def body_approx_ds(cid, g, T, weighted):
    got = ref.greedy_ds_model(g)
    exp = g.names(got)
    w = sum(g.weight(v) for v in got)
    cell = ref.fmtl(exp) + (f"; weight {w}" if weighted else "")
    assert cell == CELLS[cid][5], (cid, cell)
    L = []
    W = "Int"
    if weighted:
        decl, W = weights_decl(g.wt)
        L += [decl, "let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })"]
    else:
        L += ["let result = graph.approximateMinimumDominatingSet()"]
    L += [f"#expect(result == {tarr(exp, T)})"]
    L += order_lines("result") + DOMINATING_DEF + ["#expect(graph.isDominatingSet(result))"]
    zero = "0.0" if W == "Double" else "0"
    if weighted:
        L += [f"let total = members.reduce({zero}) {{ $0 + weights[$1] }}", f"#expect(total == {wsum_lit(w, W)})"]
    else:
        L += ["let total = result.count"]
    if small(g):
        start = f"(0 ..< n).reduce({zero}) {{ $0 + weights[$1] }}" if weighted else "n"
        sub = f"(0 ..< n).reduce({zero}) {{ mask & (1 << $1) != 0 ? $0 + weights[$1] : $0 }}" if weighted else "mask.nonzeroBitCount"
        opt = ref.brute_wds(g)
        delta = max((len(g.adj[v]) + 1 for v in range(g.n)), default=1)
        L += ["// Within H(Δ + 1) of the least weight (Chvátal), Δ + 1 the largest closed neighbourhood, and the",
              "// least weight by brute force over every subset.",
              "let closedSizes = (0 ..< n).map { v in Set(ends.filter { $0.0 != $0.1 && ($0.0 == v || $0.1 == v) }.map { $0.0 == v ? $0.1 : $0.0 }).count + 1 }",
              "let largestClosed = closedSizes.max() ?? 1",
              f"#expect(largestClosed == {delta})",
              "let harmonic = (1 ... largestClosed).reduce(0.0) { $0 + 1 / Double($1) }",
              f"var least = {start}",
              "for mask in 0 ..< 1 << n {",
              "    var dominated = mask",
              "    for (a, b) in ends {",
              "        if mask & (1 << a) != 0 { dominated |= 1 << b }",
              "        if mask & (1 << b) != 0 { dominated |= 1 << a }",
              "    }",
              "    guard dominated == (1 << n) - 1 else { continue }",
              f"    least = min(least, {sub})",
              "}",
              f"#expect(least == {wsum_lit(opt, W)})",
              "#expect(Double(total) <= harmonic * Double(least) + 1e-9)"]
    return L


def fmt_cover_edges(g, es, T):
    return "[" + ", ".join(f"UndirectedEdge<{T}>({lit(g.E[e][0])}, {lit(g.E[e][1])})" for e in es) + "]"


def body_ec(cid, g, T, bip):
    if bip:
        mm = ref.hk_model(g, g.left)
        call = "graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching())"
    else:
        mm = ref.edmonds_model(g)
        call = "graph.minimumEdgeCover()"
    got = ref.edge_cover_model(g, mm)
    L = [f"let cover = {call}"]
    if got is None:
        assert CELLS[cid][5] == "nil"
        L += ["#expect(cover == nil)", "// Why, checked here: a vertex has no edge.",
              "#expect(vertexList.contains { graph.degree(of: $0) == 0 })"]
        return L
    assert ref.fmt_edges(g, got) == CELLS[cid][5], (cid, ref.fmt_edges(g, got))
    L += [f"#expect(cover == {arr(got) if got else '[]'})",
          "let positions = try #require(cover)",
          f"#expect(positions.map {{ graph.edges[$0] }} == {fmt_cover_edges(g, got, T) if got else f'[] as [UndirectedEdge<{T}>]'})",
          "// Ascending, each once; every vertex is an end of one of them (checked here).",
          "#expect(positions == positions.sorted() && Set(positions).count == positions.count)",
          "var covered = Set<Int>()",
          "for p in positions {",
          "    covered.insert(ends[p].0)",
          "    covered.insert(ends[p].1)",
          "}",
          "#expect(covered.count == n)",
          "#expect(graph.isEdgeCover(positions))",
          "// Gallai: n − ν edges.",
          f"#expect(positions.count == n - graph.maximumMatching().edges.count)",
          f"#expect(positions.count == {g.n} - {len(mm)})"]
    if len(g.E) <= 18:
        L += ["// Brute force over every set of edges (bit k is position k): no edge cover is smaller.",
              "let m = ends.count",
              "var fewest = m + 1",
              "for mask in 0 ..< 1 << m {",
              "    var reached = 0",
              "    for k in 0 ..< m where mask & (1 << k) != 0 { reached |= (1 << ends[k].0) | (1 << ends[k].1) }",
              "    if reached == (1 << n) - 1 { fewest = min(fewest, mask.nonzeroBitCount) }",
              "}",
              "#expect(positions.count == fewest)"]
    return L


def body_check(cid, g, T, kind, argv):
    if kind == "vc":
        got = ref.is_vc(g, [g.idx[x] for x in argv]); fn = "isVertexCover"
    elif kind == "is":
        got = ref.is_is(g, [g.idx[x] for x in argv]); fn = "isIndependentSet"
    elif kind == "ds":
        got = ref.is_ds(g, [g.idx[x] for x in argv]); fn = "isDominatingSet"
    else:
        got = ref.is_ec(g, argv); fn = "isEdgeCover"
    assert str(got).lower() == CELLS[cid][5]
    if kind == "ec":
        given = arr(argv) if argv else "[] as [Int]"
    else:
        given = tarr(argv, T)
    L = [f"let given = {given}", f"#expect(graph.{fn}(given) == {lit(got)})",
         "// Order and repeats do not matter.",
         f"#expect(graph.{fn}(given.reversed()) == {lit(got)})",
         f"#expect(graph.{fn}(given + given) == {lit(got)})",
         "// The definition, checked here."]
    if kind == "ec":
        L += ["var covered = Set<Int>()",
              "for p in given {",
              "    covered.insert(ends[p].0)",
              "    covered.insert(ends[p].1)",
              "}",
              f"#expect((covered.count == n) == {lit(got)})"]
    else:
        L += ["let inSet = Set(given.map { vertexList.firstIndex(of: $0)! })"]
        if kind == "vc":
            L += [f"#expect(ends.allSatisfy {{ inSet.contains($0.0) || inSet.contains($0.1) }} == {lit(got)})"]
        elif kind == "is":
            L += [f"#expect(ends.allSatisfy {{ !(inSet.contains($0.0) && inSet.contains($0.1)) }} == {lit(got)})"]
        else:
            L += [f"#expect((0 ..< n).allSatisfy {{ v in inSet.contains(v) || ends.contains {{ ($0.0 == v && inSet.contains($0.1)) || ($0.1 == v && inSet.contains($0.0)) }} }} == {lit(got)})"]
    return L


# ---------------------------------------------------------------------------------------------
# Representation bodies
# ---------------------------------------------------------------------------------------------


def rep_body(cid, kind, args, kwargs, g, T, rep, h):
    """Lines for one representation: the exact value and a check through the API.
    h: the representation's rows/positions (for AL/AM), or None when rows are in position order."""
    gg = h if h is not None else g
    L = []
    if kind == "mis":
        exp = g.names(ref.mis_model(g))
        L += ["let result = graph.maximumIndependentSet()", f"#expect(result == {tarr(exp, T)})", "#expect(graph.isIndependentSet(result))"]
    elif kind == "alpha":
        L += [f"#expect(graph.independenceNumber() == {len(ref.mis_model(g))})"]
    elif kind == "vc":
        exp = g.names(set(range(g.n)) - ref.mis_model(g))
        L += ["let cover = graph.minimumVertexCover()", f"#expect(cover == {tarr(exp, T)})", "#expect(graph.isVertexCover(cover))"]
    elif kind == "konig":
        Lv, _ = canonical_sides(g)
        kc = konig_cover(gg, Lv)
        L += ["let sides = try #require(graph.bipartition())", f"#expect(Array(sides.left) == {tarr(Lv, T)})",
              "let cover = graph.minimumVertexCover(bipartition: sides)", f"#expect(cover == {tarr(g.names(kc), T)})",
              "#expect(graph.isVertexCover(cover))"]
    elif kind == "approx_vc":
        weighted = kwargs.get("weighted", args[2] if len(args) > 2 else False)
        L += body_approx_vc(cid, g, T, weighted, h=gg)
    elif kind == "maximal_is":
        seeds = args[2] if len(args) > 2 else kwargs.get("seeds")
        got = ref.maximal_is_model(g, seeds or ())
        call = "graph.maximalIndependentSet()" if seeds is None else f"graph.maximalIndependentSet(containing: {tarr(seeds, T)})"
        L += [f"#expect({call} == {'nil' if got is None else tarr(g.names(got), T)})"]
    elif kind == "mds":
        exp = g.names(ref.brute_mds(g))
        L += ["let result = graph.minimumDominatingSet()", f"#expect(result == {tarr(exp, T)})", "#expect(graph.isDominatingSet(result))"]
    elif kind == "approx_ds":
        weighted = kwargs.get("weighted", args[2] if len(args) > 2 else False)
        exp = g.names(ref.greedy_ds_model(g))
        if weighted:
            decl, _ = weights_decl(g.wt)
            L += [decl, "let result = graph.approximateMinimumDominatingSet(weight: { weights[$0] })"]
        else:
            L += ["let result = graph.approximateMinimumDominatingSet()"]
        L += [f"#expect(result == {tarr(exp, T)})", "#expect(graph.isDominatingSet(result))"]
    elif kind in ("ec", "ec_bip"):
        if kind == "ec":
            mm = ref.edmonds_model(gg)
            L += ["let cover = graph.minimumEdgeCover()"]
        else:
            Lv, _ = canonical_sides(g)
            mm = ref.hk_model(gg, Lv)
            L += ["let sides = try #require(graph.bipartition())",
                  f"#expect(Array(sides.left) == {tarr(Lv, T)})",
                  "let cover = graph.minimumEdgeCover(matching: graph.maximumBipartiteMatching(bipartition: sides))"]
        got = ref.edge_cover_model(gg, mm)
        if got is None:
            L += ["#expect(cover == nil)"]
        else:
            if rep == "am":
                L += [f"#expect(cover?.map {{ [$0.source, $0.target] }} == [" + ", ".join(f"[{gg.E[e][0]}, {gg.E[e][1]}]" for e in got) + "])"]
            else:
                L += [f"#expect(cover == {arr(got) if got else '[]'})"]
            L += ["#expect(cover.map { graph.isEdgeCover($0) } == true)",
                  f"#expect(cover?.count == {g.n} - graph.maximumMatching().edges.count)"]
    elif kind == "check":
        ck, argv = args[2], args[3]
        fn = {"vc": "isVertexCover", "is": "isIndependentSet", "ds": "isDominatingSet", "ec": "isEdgeCover"}[ck]
        got = {"vc": ref.is_vc, "is": ref.is_is, "ds": ref.is_ds}.get(ck)
        if ck == "ec":
            res = ref.is_ec(g, argv)
            if rep == "am":
                L += ["let cells = Array(graph.edges.indices)",
                      f"#expect(graph.{fn}([{', '.join(f'cells[{h.posmap[e]}]' for e in argv)}] as [AdjacencyMatrix.Edges.Index]) == {lit(res)})"]
            else:
                L += [f"#expect(graph.{fn}({arr(argv) if argv else '[] as [Int]'}) == {lit(res)})"]
        else:
            res = got(g, [g.idx[x] for x in argv])
            L += [f"#expect(graph.{fn}({tarr(argv, T)}) == {lit(res)})"]
    else:
        raise ValueError(kind)
    return L


# ---------------------------------------------------------------------------------------------
# Emitting
# ---------------------------------------------------------------------------------------------


def indent(lines, n):
    out = []
    for l in lines:
        out.append((" " * n + l) if l else "")
    return out


def emit_test(cid, ttl, body):
    throws = any("try " in l for l in body)
    sig = f"func {fname(cid)}() throws {{" if throws else f"func {fname(cid)}() {{"
    return indent([f'@Test("{ttl}")', sig], 4) + indent(body, 8) + ["    }", ""]


def row_body(cid, kind, args, kwargs):
    g = args[1]
    T = vtype(g)
    L = [comment_input(cid)] + build_graph(g, "primary", T) + prelude(g, T)
    if kind == "mis":
        L += body_mis(cid, g, T)
    elif kind == "alpha":
        L += body_alpha(cid, g, T)
    elif kind == "vc":
        L += body_vc(cid, g, T)
    elif kind == "konig":
        L += body_konig(cid, g, T)
    elif kind == "approx_vc":
        L += body_approx_vc(cid, g, T, kwargs["weighted"])
    elif kind == "maximal_is":
        L += body_maximal(cid, g, T, args[2])
    elif kind == "mds":
        L += body_mds(cid, g, T)
    elif kind == "approx_ds":
        L += body_approx_ds(cid, g, T, kwargs["weighted"])
    elif kind == "ec":
        L += body_ec(cid, g, T, False)
    elif kind == "ec_bip":
        L += body_ec(cid, g, T, True)
    elif kind == "check":
        L += body_check(cid, g, T, args[2], args[3])
    else:
        raise ValueError(kind)
    return L


def unused_cleanup(lines):
    """Drop prelude lines whose names the body never uses (warnings are errors)."""
    code = [l for l in lines if not l.strip().startswith("//")]
    text = "\n".join(code)
    out = []
    for l in lines:
        m = re.match(r"\s*let (\w+) = ", l)
        if m:
            name = m.group(1)
            rest = text.replace(l, "", 1)
            if not re.search(r"\b" + name + r"\b", rest):
                if out and out[-1].strip().startswith("// Edge ends"):
                    out.pop()
                continue
        out.append(l)
    return out


def rep_tests(cid, kind, args, kwargs):
    g = args[1]
    T = vtype(g)
    reps = []
    if g.kind == "graph":
        reps.append(("pseudo", "ReferencePseudograph", None))
    if g.kind == "bipartite":
        reps.append(("ual", "UndirectedAdjacencyList", None))
        reps.append(("pseudo", "ReferencePseudograph", None))
    reps.append(("unindexed", "no indices", None))
    h = adjlist_repr(g)
    if h is not None:
        reps.append(("al", "AdjacencyList.undirected", h))
    h = matrix_repr(g)
    if h is not None:
        reps.append(("am", "AdjacencyMatrix.undirected", h))
    body = [comment_input(cid)]
    for rep, label, hh in reps:
        lines = build_graph(g, rep, T) + rep_body(cid, kind, args, kwargs, g, T, rep, hh)
        lines = unused_cleanup(lines)
        body += [f"do {{ // {label}"] + indent(lines, 4) + ["}"]
    labels = ", ".join(l for (_, l, _) in reps)
    name = CELLS[cid][2]
    return emit_test(cid, esc(f"{cid} {name}, on {labels}"), body)


TRAPS = {
    "CV-213": ("UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
               "let weights = [-1, 2]\n_ = graph.approximateMinimumVertexCover(weight: { weights[$0] })"),
    "CV-214": ("UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
               "let weights = [Double.nan, 1]\n_ = graph.approximateMinimumVertexCover(weight: { weights[$0] })"),
    "CV-215": ("UndirectedAdjacencyList<Int>(vertices: [0], edges: [])",
               "_ = graph.approximateMinimumDominatingSet(weight: { (_: Int) -> Int in -1 })"),
    "CV-216": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "_ = graph.maximalIndependentSet(containing: [9])"),
    "CV-217": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "_ = graph.isVertexCover([9])"),
    "CV-218": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "_ = graph.isEdgeCover([7])"),
    "CV-219": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
               "// P5's maximum matching: positions [0, 2], on five vertices.\nlet other = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })\n_ = graph.minimumEdgeCover(matching: other.maximumMatching())"),
    "CV-220": ("UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])",
               "let other = UndirectedAdjacencyList<Int>(vertices: 0 ..< 5, edges: (0 ..< 4).map { UndirectedEdge($0, $0 + 1) })\n_ = graph.minimumVertexCover(bipartition: other.bipartition()!)"),
}


def trap_test(cid):
    parts = CELLS[cid]
    why = parts[6].replace("precondition: ", "")
    graph, call = TRAPS[cid]
    body = [comment_input(cid), "await #expect(processExitsWith: .failure) {", f"    let graph = {graph}"]
    body += indent(call.split("\n"), 4) + ["}"]
    lines = indent([f'@Test("{esc(cid + " " + parts[2] + " (" + why + ") traps")}")', f"func {fname(cid)}() async {{"], 4)
    return lines + indent(body, 8) + ["    }", ""]


def header(comment, imports, suite, struct, tags=None, conformer=False):
    L = []
    for c in comment:
        L.append("// " + c if c else "//")
    L.append("")
    for i in imports:
        L.append(f"import {i}")
    L.append("")
    if conformer:
        L += ["/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.",
              "/// Rows are in position order, a self-loop's position twice; parallel edges are kept.",
              "private struct UnindexedGraph<Vertex: Hashable>: Graph {",
              "    let vertices: [Vertex]",
              "    let edges: [UndirectedEdge<Vertex>]",
              "",
              "    func incidentEdges(of vertex: Vertex) -> [Int] {",
              "        edges.indices.flatMap { k in [edges[k].u, edges[k].v].filter { $0 == vertex }.map { _ in k } }",
              "    }",
              "    func neighbors(of vertex: Vertex) -> [Vertex] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }",
              "}",
              ""]
    t = f", .tags({tags})" if tags else ""
    L.append(f'@Suite("{suite}"{t})')
    L.append(f"struct {struct} {{")
    return L


def write(name, lines):
    while lines and lines[-1] == "":
        lines.pop()
    lines.append("}")
    with open(os.path.join(OUT, name), "w") as f:
        f.write("\n".join(lines) + "\n")


def wrap(s, width=98):
    words = s.split(" ")
    out, cur = [], ""
    for w in words:
        if cur and len(cur) + 1 + len(w) > width:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w) if cur else w
    if cur:
        out.append(cur)
    return out


ROWS = [(f"CV-{i+1:03d}", kind, args, kwargs) for i, (kind, args, kwargs) in enumerate(RECORDS)]

COMMON = ("Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in "
          "order, so rows are in position order (a self-loop twice); `multigraph` rows are "
          "`ReferencePseudograph`, whose rows are in position order too; `L …; R …` rows are "
          "`BipartiteGraph(left:right:edges:)`. Brute force numbers vertices by their index in `vertices` "
          "(bit i of a mask is the vertex at index i). Generated from cases.md by swiftgen.py, which "
          "re-evaluates each row with ref.py's model; see README.md.")

FILES = [
    ("MaximumIndependentSetTests.swift", ["mis"], "maximumIndependentSet()", "MaximumIndependentSetTests",
     "`maximumIndependentSet()` (catalog §MaximumIS, CV-001 – CV-041): the lexicographically least maximum "
     "independent set by vertex index, exact; in `vertices` order; independent (checked here: no edge and no "
     "self-loop inside); its size is `independenceNumber()` and its complement `minimumVertexCover()`; and on "
     "rows of at most 16 vertices the lexicographically least of the largest independent subsets by brute force."),
    ("IndependenceNumberTests.swift", ["alpha"], "independenceNumber()", "IndependenceNumberTests",
     "`independenceNumber()` (catalog §IndependenceNumber, CV-042 – CV-049): α exactly, the size of "
     "`maximumIndependentSet()`, n − |`minimumVertexCover()`|, and the largest independent subset by brute force "
     "on rows of at most 16 vertices."),
    ("MinimumVertexCoverTests.swift", ["vc"], "minimumVertexCover()", "MinimumVertexCoverTests",
     "`minimumVertexCover()` (catalog §MinimumVC, CV-050 – CV-071): the complement of the lexicographically least "
     "maximum independent set, exact; a cover (checked here: every edge and every self-loop has an end in it); "
     "n − α vertices; by brute force the complement of the lexicographically least maximum independent set and "
     "no cover smaller; on `BipartiteGraph` rows as large as `maximumBipartiteMatching()` (König), and König's own "
     "cover where it differs."),
    ("KoenigVertexCoverTests.swift", ["konig"], "minimumVertexCover(bipartition:)", "KoenigVertexCoverTests",
     "`minimumVertexCover(bipartition: g.bipartition()!)` (catalog §KoenigVC, CV-072 – CV-086): König's cover, "
     "NetworkX `to_vertex_cover`'s, exact, with the canonical sides asserted; a cover as large as "
     "`maximumBipartiteMatching(bipartition:)`; by brute force no cover smaller and the unique minimum cover with "
     "the most left vertices; and `minimumVertexCover()` where it differs."),
    ("ApproximateVertexCoverTests.swift", ["approx_vc"], "approximateMinimumVertexCover", "ApproximateVertexCoverTests",
     "`approximateMinimumVertexCover()` and `approximateMinimumVertexCover(weight:)` (catalog §ApproxVC, CV-087 – "
     "CV-111): Bar-Yehuda–Even in position order, exact; a cover; its weight (the sum of the closure's values) as "
     "the catalog's; within twice the least cover weight, found by brute force on rows of at most 16 vertices "
     "(the catalog's optimum otherwise); unweighted and loop-free, inside the ends of `maximalMatching()`."),
    ("MaximalIndependentSetTests.swift", ["maximal_is"], "maximalIndependentSet", "MaximalIndependentSetTests",
     "`maximalIndependentSet()` and `maximalIndependentSet(containing:)` (catalog §MaximalIS, CV-112 – CV-128): "
     "the greedy set in vertex order, seeds first, exact; independent and maximal (checked here); the greedy pass "
     "written out for the unseeded rows; the seeds in it; nil exactly when two seeds are adjacent or one is looped."),
    ("MinimumDominatingSetTests.swift", ["mds"], "minimumDominatingSet()", "MinimumDominatingSetTests",
     "`minimumDominatingSet()` (catalog §MinimumDS, CV-129 – CV-147): the lexicographically least minimum "
     "dominating set, exact; dominating (checked here); the lexicographically least of the smallest dominating "
     "subsets by brute force; the greedy approximation's size where the catalog notes it."),
    ("ApproximateDominatingSetTests.swift", ["approx_ds"], "approximateMinimumDominatingSet", "ApproximateDominatingSetTests",
     "`approximateMinimumDominatingSet()` and `approximateMinimumDominatingSet(weight:)` (catalog §ApproxDS, "
     "CV-148 – CV-166): Chvátal's greedy set cover, NetworkX `min_weighted_dominating_set`'s output, exact; "
     "dominating (checked here); its weight; within H(Δ + 1) of the least weight, found by brute force."),
    ("MinimumEdgeCoverTests.swift", ["ec", "ec_bip"], "minimumEdgeCover", "MinimumEdgeCoverTests",
     "`minimumEdgeCover()` and `minimumEdgeCover(matching:)` (catalog §MinimumEC, CV-167 – CV-188): the matching's "
     "edges, then each uncovered vertex's first incident edge, exact positions and the edges they name; "
     "ascending; an edge cover (checked here); n − ν edges (Gallai); no edge cover smaller by brute force on rows "
     "of at most 18 edges; nil exactly when a vertex has no edge."),
    ("CoveringCheckTests.swift", ["check"], "Checks: isVertexCover, isIndependentSet, isDominatingSet, isEdgeCover", "CoveringCheckTests",
     "The four checks (catalog §Checks, CV-189 – CV-212) against their definitions, written out here, with the "
     "elements given in order, reversed and twice."),
]


def imports_for(kinds, extra=()):
    base = ["AdjacencyListModule", "BipartiteGraphs", "Covering", "GraphProtocols", "GrafluentTestSupport", "MatchingModule", "Testing"]
    return sorted(set(base) | set(extra), key=lambda s: s.lower())


USED_IMPORTS = {}


def used_imports(lines):
    t = "\n".join(lines)
    out = ["Covering", "GraphProtocols", "Testing"]
    if "UndirectedAdjacencyList" in t or "AdjacencyList<" in t:
        out.append("AdjacencyListModule")
    if "AdjacencyMatrix" in t:
        out.append("AdjacencyMatrixModule")
    if "BipartiteGraph" in t or "bipartition()" in t:
        out.append("BipartiteGraphs")
    if "ReferencePseudograph" in t:
        out.append("GrafluentTestSupport")
    if "maximumMatching()" in t or "maximalMatching()" in t or "maximumBipartiteMatching" in t:
        out.append("MatchingModule")
    return sorted(set(out), key=lambda s: s.lower())


def catalog_file(fname_, kinds, suite, struct, intro):
    body = []
    count = 0
    for cid, kind, args, kwargs in ROWS:
        if kind in kinds:
            lines = unused_cleanup(row_body(cid, kind, args, kwargs))
            body += emit_test(cid, title(cid), lines)
            count += 1
    comment = wrap(intro + " " + COMMON)
    L = header(comment, used_imports(body), suite, struct) + body
    write(fname_, L)
    return count


COUNTS = {}
for f, kinds, suite, struct, intro in FILES:
    COUNTS[f] = catalog_file(f, kinds, suite, struct, intro)

# Traps
body = []
for cid, kind, args, kwargs in ROWS:
    if kind == "trap":
        body += trap_test(cid)
EXTRA_TRAPS = open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n")
body += EXTRA_TRAPS
intro = ("Preconditions, as exit tests (catalog CV-213 – CV-220): a negative or NaN weight, a seed or a checked "
         "vertex that is not a vertex, a position outside `edges`, a matching or a bipartition of another graph. "
         "Then the preconditions the catalog does not list: a non-vertex given to `isIndependentSet` and "
         "`isDominatingSet`, a NaN and a negative `Double` weight to the dominating-set approximation, a negative "
         "`Int` weight to the vertex-cover approximation and to the unindexed path, a seed that is not a vertex "
         "next to valid ones, a bipartition of a graph with the same vertex count but other vertices. Each exit "
         "test builds its inputs inside the closure. Generated from cases.md by swiftgen.py, the tests after "
         "CV-220 written by hand; see README.md.")
L = header(wrap(intro), used_imports(body), "Covering preconditions", "CoveringPreconditionTests", tags=".precondition") + body
write("CoveringPreconditionTests.swift", L)
COUNTS["CoveringPreconditionTests.swift"] = sum(1 for l in body if l.strip().startswith("@Test("))

# Representations
body = []
rep_count = 0
for cid, kind, args, kwargs in ROWS:
    if kind == "trap":
        continue
    body += rep_tests(cid, kind, args, kwargs)
    rep_count += 1
intro = ("The graph rows of the catalog again on other representations. Rows on `UndirectedAdjacencyList` run "
         "again on `ReferencePseudograph`; `BipartiteGraph` rows on an `UndirectedAdjacencyList` and a "
         "`ReferencePseudograph` with the same vertices and edges; every row on a file-private conformer with no "
         "vertex or edge indices; all with the catalog's values, since their rows are in position order too. Then "
         "on `AdjacencyList.undirected` with each edge an arc as written, and on `AdjacencyMatrix.undirected` with "
         "the arcs at their row-major cells (rows on 0..<n with no arc twice). Every vertex-set result is the "
         "catalog's on every representation (they depend on the vertex order and the adjacency only, or, for "
         "`approximateMinimumVertexCover`, on the edge order, which `AdjacencyList` keeps). Through `.undirected` "
         "a row is successors, then predecessors, and matrix positions are cells: the edge covers there, and the "
         "vertex-cover approximation on the matrix, were computed by swiftgen.py with ref.py's models on those "
         "rows and positions. Matrix positions are compared as [source, target]. Matching rows run through "
         "`bipartition()`, the canonical sides. See README.md.")
L = header(wrap(intro), sorted(set(used_imports(body)) | {"AdjacencyMatrixModule", "AdjacencyListModule"}, key=str.lower),
           "Catalog graph rows on every representation", "CoveringRepresentationTests", conformer=True) + body
write("CoveringRepresentationTests.swift", L)
COUNTS["CoveringRepresentationTests.swift"] = rep_count

for k, v in COUNTS.items():
    print(f"{k}: {v}")
print("total", sum(COUNTS.values()))
