"""Writes the catalog-row test files of Tests/MatchingModuleTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with scipy==1.18.1 python3 swiftgen.py [OUT_DIR]   # default: Tests/MatchingModuleTests

First runs ref.py's catalog with each case builder instrumented, so every row's inputs are kept
as structured values, and checks that the rendered catalog equals cases.md byte for byte. Then
re-evaluates each row with ref.py's model functions, asserts each value matches its catalog cell,
and writes one @Test per row. The representation rows (AdjacencyList and AdjacencyMatrix through
`.undirected`) are recomputed with the same models on those representations' rows: successors then
predecessors, arcs in insertion order (AdjacencyList) or at row-major cells (AdjacencyMatrix); the
weighted rows with NetworkX itself, given that adjacency order.
"""
import copy
import json
import math
import os
import sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "MatchingModuleTests")
os.chdir(HERE)
import ref  # noqa: E402
import networkx as nx  # noqa: E402

# ---------------------------------------------------------------------------------------------
# Record every case's inputs while ref.build() runs
# ---------------------------------------------------------------------------------------------
RECORDS = []
DISCREPANCIES = []


def instrument(kind, fn):
    def wrapper(*args, **kwargs):
        RECORDS.append((kind, args, kwargs))
        return fn(*args, **kwargs)
    return wrapper


for kind in ["maximal", "check", "hk", "edmonds", "mwm", "minwm", "mwfm", "lsa", "stable", "trap"]:
    setattr(ref, f"case_{kind}", instrument(kind, getattr(ref, f"case_{kind}")))
ref.build()
assert not ref.FAILS, ref.FAILS
assert len(RECORDS) == len(ref.CASES) == 238

text = ref.HEADER.replace("{last}", f"{len(ref.CASES):03d}").replace("{count}", str(len(ref.CASES)))
for i, (grp, name, inp, call, exp, chk, notes) in enumerate(ref.CASES):
    nm = name + (f" ({notes})" if notes else "")
    text += f"| MA-{i+1:03d} | {grp} | {nm} | {inp} | {call} | {exp} | {chk} |\n"


def normalize(t):
    # ref.py compares NetworkX's Hopcroft–Karp with ours only when NetworkX iterates its left set
    # (a Python set) in `left` order; for string vertices that depends on PYTHONHASHSEED, so the
    # Checked cell of those rows varies between runs. Everything else must match byte for byte.
    t = t.replace("size = NetworkX hopcroft_karp_matching (its left-set order differs)", "HK-NX")
    return t.replace("= NetworkX hopcroft_karp_matching; cover = NetworkX to_vertex_cover", "HK-NX")


with open(os.path.join(HERE, "cases.md")) as f:
    assert normalize(f.read()) == normalize(text), "cases.md is not ref.py's output"
CELLS = {}
for line in text.splitlines():
    if line.startswith("| MA-"):
        parts = [p.strip() for p in line.strip().strip("|").split(" | ")]
        CELLS[parts[0]] = parts
assert len(CELLS) == 238

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
        r = repr(x)
        return r
    return str(x)


def arr(xs):
    return "[" + ", ".join(lit(x) for x in xs) + "]"


def vtype(g):
    return "String" if any(isinstance(v, str) for v in g.V) else "Int"


def wtype(ws):
    return "Double" if any(isinstance(w, float) for w in ws) else "Int"


def wlit(w, ty):
    if ty == "Double":
        return repr(float(w))
    return str(w)


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def fn(cid):
    return "ma" + cid[3:]


def title(cid, maxlen=110):
    parts = CELLS[cid]
    name, exp = parts[2], parts[5]
    for d in DISCREPANCIES:
        if d[0] == cid:
            exp = "edges " + ref.fmtl(d[2]) + " (api.md; the catalog cell says " + ref.fmtl(d[1]) + ", see README.md)"
    t = f"{cid} {name}"
    if len(t) + len(exp) + 2 <= maxlen:
        t += ": " + exp
    return esc(t)


def comment_input(cid):
    parts = CELLS[cid]
    s = f"{parts[3]}; {parts[4]}"
    if len(s) > 200:
        s = s[:197] + "…"
    return "// " + s


# ---------------------------------------------------------------------------------------------
# Representations
# ---------------------------------------------------------------------------------------------


def adjlist_repr(g):
    """The graph as AdjacencyList(arcs as written).undirected: positions are the arcs in order;
    each row is out-arcs then in-arcs, each in insertion order. None if an arc repeats."""
    arcs = [(u, v) for (u, v, _) in g.E]
    if len(set(arcs)) != len(arcs):
        return None
    h = copy.copy(g)
    h.E = list(g.E)
    h.rows = [[] for _ in g.V]
    outs = [[] for _ in g.V]
    ins = [[] for _ in g.V]
    for e, (u, v, _) in enumerate(g.E):
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
    arcs = [(u, v) for (u, v, _) in g.E]
    if len(set(arcs)) != len(arcs):
        return None
    cells = sorted(arcs)
    pos = {c: k for k, c in enumerate(cells)}
    h = copy.copy(g)
    byarc = {(u, v): w for (u, v, w) in g.E}
    h.E = [(u, v, byarc[(u, v)]) for (u, v) in cells]
    h.rows = [[] for _ in g.V]
    for v in range(g.n):
        succ = sorted(t for (s, t) in cells if s == v)
        pred = sorted(s for (s, t) in cells if t == v)
        h.rows[v] = [(t, pos[(v, t)]) for t in succ] + [(s, pos[(s, v)]) for s in pred]
    h.posmap = [pos[a] for a in arcs]   # catalog position -> cell number
    h.cells = cells
    return h


def ref_rows_equal_positions(g):
    return True


def canonical_left(g):
    side = {}
    for s in g.V:
        if s in side:
            continue
        side[s] = 0
        q = deque([s])
        while q:
            x = q.popleft()
            for (y, _) in g.rows[g.idx[x]]:
                yv = g.V[y]
                if yv not in side:
                    side[yv] = 1 - side[x]
                    q.append(yv)
    return [v for v in g.V if side[v] == 0]


def nx_custom(g):
    """NetworkX graph whose adjacency order is g's rows (parallel copies collapsed at first
    appearance, the heaviest copy's weight, earliest position on ties); returns (H, chosen)."""
    best = {}
    for e, (u, v, _) in enumerate(g.E):
        if u == v:
            continue
        k = frozenset((u, v))
        if k not in best or g.w(e) > g.w(best[k]):
            best[k] = e
    H = nx.Graph()
    H.add_nodes_from(g.V)
    data = {k: {"weight": g.w(e)} for k, e in best.items()}
    for v in g.V:
        adj = {}
        for (wi, _) in g.rows[g.idx[v]]:
            w = g.V[wi]
            if w == v or w in adj:
                continue
            adj[w] = data[frozenset((v, w))]
        H._adj[v] = adj
    return H, best


def mwm_rows(g, maxcard):
    H, chosen = nx_custom(g)
    pairs = nx.max_weight_matching(H, maxcardinality=maxcard)
    return sorted(chosen[frozenset(p)] for p in pairs)


def minwm_rows(g):
    """maximumWeightMatching on (1 + max) - w, maximumCardinality, on g's rows; parallel copies
    collapse after the transform (the lightest original copy, earliest on ties)."""
    ws = [g.w(e) for e, (u, v, _) in enumerate(g.E) if u != v]
    if not ws:
        return []
    one = 1.0 if any(isinstance(x, float) for x in ws) else 1
    c = one + max(ws)
    h = copy.copy(g)
    h.E = [(u, v, (None if u == v else c - g.w(e))) for e, (u, v, _) in enumerate(g.E)]
    return mwm_rows(h, True)


# ---------------------------------------------------------------------------------------------
# Brute force (sizes of the search, to decide whether a test can enumerate in seconds)
# ---------------------------------------------------------------------------------------------


def count_matchings(g, cap=400000):
    ends = [(g.idx[u], g.idx[v]) for (u, v, _) in g.E]
    used = [False] * g.n
    count = [0]

    def rec(k):
        if count[0] > cap:
            return
        if k == len(ends):
            count[0] += 1
            return
        rec(k + 1)
        a, b = ends[k]
        if a != b and not used[a] and not used[b]:
            used[a] = used[b] = True
            rec(k + 1)
            used[a] = used[b] = False
    rec(0)
    return count[0]


def brute_ok(g):
    return count_matchings(g) <= 60000


# ---------------------------------------------------------------------------------------------
# Swift fragments
# ---------------------------------------------------------------------------------------------


def pairs_lines(g, T, arcs=False):
    items = ", ".join(f"({lit(u)}, {lit(v)})" for (u, v, _) in g.E)
    return [f"let pairs: [({T}, {T})] = [{items}]"]


def build_graph(g, rep, T):
    """Lines that declare `graph` on representation rep."""
    L = pairs_lines(g, T)
    if rep == "ual":
        L.append(f"let graph = UndirectedAdjacencyList<{T}>(vertices: {arr(g.V)} as [{T}], edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        L.append(f"#expect(graph.edgeCount == {len(g.E)})")
    elif rep == "pseudo":
        L.append(f"let graph = ReferencePseudograph<{T}>(vertices: {arr(g.V)} as [{T}], edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
    elif rep == "unindexed":
        L.append(f"let graph = UnindexedGraph<{T}>(vertices: {arr(g.V)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
        L.append("#expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)")
    elif rep == "adjlist":
        L.append(f"let graph = AdjacencyList<{T}>(vertices: {arr(g.V)} as [{T}], edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected")
        L.append(f"#expect(graph.edgeCount == {len(g.E)})")
    elif rep == "matrix":
        L.append(f"let graph = AdjacencyMatrix(vertexCount: {g.n}, edges: pairs.map {{ DirectedEdge(from: $0.0, to: $0.1) }}).undirected")
        L.append(f"#expect(graph.edgeCount == {len(g.E)})")
    elif rep == "bipartite":
        L.append(f"let graph = try #require(BipartiteGraph<{T}>(left: {arr(g.left)} as [{T}], right: {arr(g.right)} as [{T}], edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }}))")
        L.append(f"#expect(graph.edgeCount == {len(g.E)})")
    else:
        raise ValueError(rep)
    return L


def primary_rep(g):
    if g.kind == "multigraph":
        return "pseudo"
    if g.kind == "bipartite":
        return "bipartite"
    return "ual"


def positions_expr(rep):
    return "matching.edges.map { [$0.source, $0.target] }" if rep == "matrix" else "matching.edges"


def positions_lit(h, rep, es):
    if rep == "matrix":
        return "[" + ", ".join(f"[{h.cells[e][0]}, {h.cells[e][1]}]" for e in es) + "]"
    return arr(es)


def mates_of(g, es):
    mate = {}
    medge = {}
    for e in es:
        a, b = g.idx[g.E[e][0]], g.idx[g.E[e][1]]
        mate[a], mate[b] = b, a
        medge[a] = medge[b] = e
    return mate, medge


def mates_block(g, rep, es, T, h=None):
    """Exact mates, mate indices and matched edges for every vertex, in `vertices` order."""
    h = h or g
    mate, medge = mates_of(h, es)
    mates = [g.V[mate[i]] if i in mate else None for i in range(g.n)]
    idxs = [mate.get(i) for i in range(g.n)]
    L = []
    L.append("// Every vertex's mate, its index and the matched edge, in `vertices` order.")
    L.append("let vertexList = Array(graph.vertices)")
    L.append(f"#expect(vertexList == {arr(g.V)} as [{T}])")
    L.append(f"let mates: [{T}?] = {arr(mates)}")
    L.append(f"let mateIndices: [Int?] = {arr(idxs)}")
    if rep == "matrix":
        me = ["nil" if i not in medge else f"[{h.cells[medge[i]][0]}, {h.cells[medge[i]][1]}]" for i in range(g.n)]
        L.append(f"let matchedEdges: [[Int]?] = [{', '.join(me)}]")
        L.append("for (i, v) in vertexList.enumerated() {")
        L.append("    #expect(matching.mate(of: v) == mates[i], \"mate of \\(v)\")")
        L.append("    #expect(matching.mate(ofIndex: i) == mateIndices[i], \"mate of index \\(i)\")")
        L.append("    #expect(matching.matchedEdge(of: v).map { [$0.source, $0.target] } == matchedEdges[i], \"matched edge of \\(v)\")")
        L.append("}")
    else:
        me = [medge.get(i) for i in range(g.n)]
        L.append(f"let matchedEdges: [Int?] = {arr(me)}")
        L.append("for (i, v) in vertexList.enumerated() {")
        L.append("    #expect(matching.mate(of: v) == mates[i], \"mate of \\(v)\")")
        L.append("    #expect(matching.mate(ofIndex: i) == mateIndices[i], \"mate of index \\(i)\")")
        L.append("    #expect(matching.matchedEdge(of: v) == matchedEdges[i], \"matched edge of \\(v)\")")
        L.append("}")
    return L


def validity_block(T):
    return [
        "// Valid, checked here: no position twice, no self-loop, no endpoint shared.",
        "#expect(Set(matching.edges).count == matching.edges.count)",
        f"var covered = Set<{T}>()",
        "for e in matching.edges {",
        "    let edge = graph.edges[e]",
        "    #expect(edge.u != edge.v, \"self-loop \\(edge) matched\")",
        "    #expect(covered.insert(edge.u).inserted, \"\\(edge.u) matched twice\")",
        "    #expect(covered.insert(edge.v).inserted, \"\\(edge.v) matched twice\")",
        "}",
    ]


def maximal_check_block():
    return [
        "// Maximal, checked here: every edge other than a self-loop has a matched end.",
        "for edge in graph.edges where edge.u != edge.v {",
        "    #expect(covered.contains(edge.u) || covered.contains(edge.v), \"\\(edge) could be added\")",
        "}",
    ]


def brute_card_block(T):
    """Defines `largest`: the size of a maximum matching, by enumerating every matching."""
    return [
        "// Brute force over every matching (each edge in or out, in position order).",
        "let positions = Array(graph.edges.indices)",
        f"var used = Set<{T}>()",
        "var largest = 0",
        "func extend(_ k: Int, _ size: Int) {",
        "    guard k < positions.count else {",
        "        largest = max(largest, size)",
        "        return",
        "    }",
        "    extend(k + 1, size)",
        "    let edge = graph.edges[positions[k]]",
        "    if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {",
        "        used.insert(edge.u)",
        "        used.insert(edge.v)",
        "        extend(k + 1, size + 1)",
        "        used.remove(edge.u)",
        "        used.remove(edge.v)",
        "    }",
        "}",
        "extend(0, 0)",
    ]


def brute_weight_block(T, W, mode, exact_card=None):
    """Defines `best`: the optimal (size, weight) over every matching, by mode: 'max' (greatest
    weight), 'maxcard' (greatest size, then greatest weight), 'mincard' (greatest size, then least
    weight), 'full' (size exact_card, least weight; nil when there is none)."""
    L = [
        "// Brute force over every matching (each edge in or out, in position order).",
        "let positions = Array(graph.edges.indices)",
        f"var used = Set<{T}>()",
        f"var best: (size: Int, weight: {W})?",
        f"func extend(_ k: Int, _ size: Int, _ total: {W}) {{",
        "    guard k < positions.count else {",
    ]
    if mode == "max":
        L.append("        if best == nil || total > best!.weight { best = (size, total) }")
    elif mode == "maxcard":
        L.append("        if best == nil || size > best!.size || (size == best!.size && total > best!.weight) { best = (size, total) }")
    elif mode == "mincard":
        L.append("        if best == nil || size > best!.size || (size == best!.size && total < best!.weight) { best = (size, total) }")
    elif mode == "full":
        L.append(f"        if size == {exact_card} && (best == nil || total < best!.weight) {{ best = (size, total) }}")
    L += [
        "        return",
        "    }",
        "    extend(k + 1, size, total)",
        "    let edge = graph.edges[positions[k]]",
        "    if edge.u != edge.v, !used.contains(edge.u), !used.contains(edge.v) {",
        "        used.insert(edge.u)",
        "        used.insert(edge.v)",
        "        extend(k + 1, size + 1, total + weightOf(positions[k]))",
        "        used.remove(edge.u)",
        "        used.remove(edge.v)",
        "    }",
        "}",
        "extend(0, 0, 0)",
    ]
    return L


def close_expr(a, b, W):
    if W == "Double":
        return f"abs({a} - {b}) <= 1e-9 * max(1, abs({b}))"
    return f"{a} == {b}"


def weights_decl(h, rep, W, g):
    """Lines declaring `weightOf: (position) -> W` from the row's weights (self-loops have none)."""
    if rep == "matrix":
        items = ", ".join(f"[{u}, {v}]: {wlit(h.w(e), W)}" for e, (u, v, _) in enumerate(h.E) if u != v)
        return [f"let weightTable: [[Int]: {W}] = [{items or ':'}]",
                f"func weightOf(_ e: AdjacencyMatrix.Edges.Index) -> {W} {{ weightTable[[e.source, e.target]]! }}"]
    ws = ", ".join("nil" if u == v else wlit(h.w(e), W) for e, (u, v, _) in enumerate(h.E))
    return [f"let weights: [{W}?] = [{ws}]",
            f"func weightOf(_ e: Int) -> {W} {{ weights[e]! }}"]


def loop_guard(h):
    return any(u == v for (u, v, _) in h.E)


def weighed_call(rep, h):
    """The closure passed as `weight:`: records whether a self-loop was weighed."""
    if loop_guard(h):
        return "{ e in\n    if graph.edges[e].u == graph.edges[e].v { loopWeighed = true }\n    return weightOf(e)\n}"
    return "{ weightOf($0) }"


def indent(lines, n=8):
    pad = " " * n
    out = []
    for l in lines:
        for sub in l.split("\n"):
            out.append(pad + sub if sub else sub)
    return out


# ---------------------------------------------------------------------------------------------
# Row values (re-evaluated, then checked against the catalog cell)
# ---------------------------------------------------------------------------------------------


def fmt_expected(g, es, weight=None, show=False):
    return ref.fmt_matching(g, es, weight, show)


def hk_left(g, rec_kwargs, via):
    left = rec_kwargs.get("left")
    if left is None:
        left = g.left if g.kind == "bipartite" else canonical_left(g)
    return left


IDS = [f"MA-{i:03d}" for i in range(1, 239)]
ROWS = []   # (cid, kind, args, kwargs)
for cid, (kind, args, kwargs) in zip(IDS, RECORDS):
    ROWS.append((cid, kind, args, kwargs))


def matching_test_body(cid, g, rep, es, T, *, h=None, weight=None, W=None, call, brute=None,
                       maximal=False, perfect=None, size_note=None, extra_before=None, extra_after=None,
                       weights=None):
    """The body shared by every Matching-returning row."""
    h = h or g
    L = []
    L += build_graph(h if rep in ("adjlist", "matrix") else g, rep, T)
    if extra_before:
        L += extra_before
    if weights:
        L += weights
        if loop_guard(h):
            L.append("var loopWeighed = false")
    L.append(f"let matching = {call}")
    if weights and loop_guard(h):
        L.append("#expect(!loopWeighed, \"a self-loop was weighed\")")
    L.append(f"#expect({positions_expr(rep)} == {positions_lit(h, rep, es)})")
    if weight is None:
        L.append(f"#expect(matching.weight == {len(es)})")
    else:
        L.append(f"#expect(matching.weight == {wlit(weight, W)})")
    L.append(f"#expect(matching.isPerfect == {lit(2 * len(es) == g.n)})")
    L += mates_block(g, rep, es, T, h)
    L += validity_block(T)
    if weight is not None:
        L.append(f"var sum: {W} = 0")
        L.append("for e in matching.edges { sum += weightOf(e) }")
        L.append("#expect(matching.weight == sum, \"the weight is the sum in `edges` order\")")
    if maximal:
        L += maximal_check_block()
    if extra_after:
        L += extra_after
    return L


def emit_test(cid, ttl, body, throws=True, extra_attrs=""):
    L = [f"    @Test(\"{ttl}\"{extra_attrs})", f"    func {fn(cid)}(){' throws' if throws else ''} {{"]
    L.append(f"        {comment_input(cid)}")
    for d in DISCREPANCIES:
        if d[0] == cid:
            L.append(f"        // The catalog cell lists edges {ref.fmtl(d[1])}: ref.py rebuilds the transformed graph in")
            L.append("        // NetworkX's G.edges() order. api.md keeps the graph (the transform is applied to the same")
            L.append(f"        // rows), which gives {ref.fmtl(d[2])}: the same size and weight. See README.md.")
    L += indent(body)
    L.append("    }")
    L.append("")
    return L


def needs_throw(body):
    return any("try " in l for l in body)


def row_tests(cid, kind, args, kwargs, rep="primary"):
    """Returns (body lines) for one row on one representation; None when not representable."""
    if kind == "maximal":
        name, g = args[0], args[1]
        h = g
        r = primary_rep(g) if rep == "primary" else rep
        if r in ("adjlist", "matrix"):
            h = adjlist_repr(g) if r == "adjlist" else matrix_repr(g)
            if h is None:
                return None
        es = ref.maximal_model(h)
        if rep == "primary":
            assert fmt_expected(g, es) == CELLS[cid][5], (cid, fmt_expected(g, es), CELLS[cid][5])
        T = vtype(g)
        after = []
        if rep == "primary":
            after.append(f"#expect(graph.isMaximalMatching(matching.edges))")
            if brute_ok(g):
                after += brute_card_block(T)
                after.append("#expect(2 * matching.edges.count >= largest, \"a maximal matching is at least half a maximum one\")")
                card, _ = ref.brute(g, lambda c, w: c)
                after.append(f"#expect(largest == {card})")
        return matching_test_body(cid, g, r, es, T, h=h, call="graph.maximalMatching()", maximal=True, extra_after=after)

    if kind == "edmonds":
        name, g = args[0], args[1]
        h = g
        r = primary_rep(g) if rep == "primary" else rep
        if r in ("adjlist", "matrix"):
            h = adjlist_repr(g) if r == "adjlist" else matrix_repr(g)
            if h is None:
                return None
        es = ref.edmonds_model(h)
        if rep == "primary":
            assert fmt_expected(g, es) == CELLS[cid][5], (cid,)
        T = vtype(g)
        after = ["#expect(graph.isMatching(matching.edges))"]
        if rep == "primary":
            Hs, _ = g.nx_simple(weighted=False)
            k = len(nx.max_weight_matching(Hs, maxcardinality=True))
            assert k == len(es)
            if brute_ok(g):
                after += brute_card_block(T)
                after.append("#expect(matching.edges.count == largest, \"maximum, by brute force\")")
            else:
                after.append(f"#expect(matching.edges.count == {k}, \"NetworkX max_weight_matching(maxcardinality=True) has {k} edges\")")
        else:
            after.append(f"#expect(matching.edges.count == {len(es)})")
        return matching_test_body(cid, g, r, es, T, h=h, call="graph.maximumMatching()", maximal=True, extra_after=after)

    if kind == "check":
        name, g, es = args[0], args[1], args[2]
        r = primary_rep(g) if rep == "primary" else rep
        h = g
        if r in ("adjlist", "matrix"):
            h = adjlist_repr(g) if r == "adjlist" else matrix_repr(g)
            if h is None:
                return None
        a, b, c = ref.is_matching(g, es), ref.is_maximal(g, es), ref.is_perfect(g, es)
        assert CELLS[cid][5] == f"{lit(a)} / {lit(b)} / {lit(c)}"
        T = vtype(g)
        L = build_graph(h if r in ("adjlist", "matrix") else g, r, T)
        if r == "matrix":
            if es:
                L.append("let cell = Dictionary(uniqueKeysWithValues: graph.edges.indices.map { ([$0.source, $0.target], $0) })")
            items = ", ".join(f"cell[[{h.cells[h.posmap[e]][0]}, {h.cells[h.posmap[e]][1]}]]!" for e in es)
            L.append(f"let candidate: [AdjacencyMatrix.Edges.Index] = [{items}]")
        else:
            L.append(f"let candidate: [Int] = {arr(es)}")
        L.append(f"#expect(graph.isMatching(candidate) == {lit(a)})")
        L.append(f"#expect(graph.isMaximalMatching(candidate) == {lit(b)})")
        L.append(f"#expect(graph.isPerfectMatching(candidate) == {lit(c)})")
        if rep == "primary":
            L.append("// The definitions, checked here.")
            L.append(f"var ends: [{T}] = []")
            L.append("for e in candidate { ends += [graph.edges[e].u, graph.edges[e].v] }")
            L.append("let isMatching = Set(candidate).count == candidate.count && candidate.allSatisfy { graph.edges[$0].u != graph.edges[$0].v } && Set(ends).count == ends.count")
            L.append("let isMaximal = isMatching && graph.edges.allSatisfy { $0.u == $0.v || ends.contains($0.u) || ends.contains($0.v) }")
            L.append("let isPerfect = isMatching && ends.count == graph.vertexCount")
            L.append(f"#expect(isMatching == {lit(a)} && isMaximal == {lit(b)} && isPerfect == {lit(c)})")
            L.append("// Order does not matter: the same positions reversed.")
            L.append(f"#expect(graph.isMatching(candidate.reversed()) == {lit(a)})")
            L.append(f"#expect(graph.isMaximalMatching(candidate.reversed()) == {lit(b)})")
            L.append(f"#expect(graph.isPerfectMatching(candidate.reversed()) == {lit(c)})")
        return L

    if kind == "hk":
        name, g = args[0], args[1]
        via = kwargs.get("via", "bipartite")
        left = hk_left(g, kwargs, via)
        r = primary_rep(g) if rep == "primary" else rep
        if g.kind == "bipartite" and rep != "primary":
            # BipartiteGraph rows: through bipartition() (canonical sides) on the BipartiteGraph and
            # on an UndirectedAdjacencyList with the same vertices and edges.
            if r not in ("bipartite", "ual"):
                return None
            h = g
            cleft = canonical_left(g)
            es = ref.hk_model(g, cleft)[0]
            T = vtype(g)
            cover = ref.konig_cover(g, cleft, es)
            before = ["let bipartition = try #require(graph.bipartition())",
                      f"#expect(Array(bipartition.left) == {arr(cleft)} as [{T}])"]
            if r == "ual":
                gg = copy.copy(g)
                gg.kind = "graph"
                body = matching_test_body(cid, gg, "ual", es, T, call="graph.maximumBipartiteMatching(bipartition: bipartition)",
                                          extra_before=before, extra_after=konig_block(T, "bipartition.left", cover))
            else:
                body = matching_test_body(cid, g, "bipartite", es, T, call="graph.maximumBipartiteMatching(bipartition: bipartition)",
                                          extra_before=before, extra_after=konig_block(T, "bipartition.left", cover))
            return body
        h = g
        if r in ("adjlist", "matrix"):
            h = adjlist_repr(g) if r == "adjlist" else matrix_repr(g)
            if h is None:
                return None
        es, phases = ref.hk_model(h, left)
        cover = ref.konig_cover(h, left, es)
        if rep == "primary":
            exp = fmt_expected(g, es) + f"; König cover {ref.fmtl(cover)}; {phases} phase" + ("s" if phases != 1 else "")
            if via != "bipartite":
                exp = f"left {ref.fmtl(left)}; " + exp
            assert exp == CELLS[cid][5], (cid, exp, CELLS[cid][5])
        T = vtype(g)
        after = konig_block(T, "graph.left" if via == "bipartite" else "bipartition.left", cover)
        if rep == "primary" and brute_ok(g):
            after += brute_card_block(T)
            after.append("#expect(matching.edges.count == largest, \"maximum, by brute force\")")
        if via == "bipartite":
            call = "graph.maximumBipartiteMatching()"
            before = [f"#expect(Array(graph.left) == {arr(g.left)} as [{T}])"]
        else:
            call = "graph.maximumBipartiteMatching(bipartition: bipartition)"
            before = ["let bipartition = try #require(graph.bipartition())",
                      f"#expect(Array(bipartition.left) == {arr(left)} as [{T}])"]
        return matching_test_body(cid, g, r, es, T, h=h, call=call, extra_before=before, extra_after=after)

    if kind in ("mwm", "minwm"):
        name, g = args[0], args[1]
        maxcard = (args[2] if len(args) > 2 else kwargs.get("maxcard", False)) if kind == "mwm" else True
        r = primary_rep(g) if rep == "primary" else rep
        h = g
        if r in ("adjlist", "matrix"):
            if g.kind == "multigraph":
                return None   # the tie between copies would depend on row order (README)
            h = adjlist_repr(g) if r == "adjlist" else matrix_repr(g)
            if h is None:
                return None
        if kind == "mwm":
            es = ref.mwm_model(g, maxcard) if rep == "primary" else mwm_rows(h, maxcard)
        else:
            es = ref.minwm_model(g) if rep == "primary" else minwm_rows(h)
        if rep == "primary":
            # The model on rows equals the catalog's (rows are position order here), except where
            # ref.py's minimum-weight model rebuilds the transformed graph in NetworkX's
            # G.edges() order (DISCREPANCIES): api.md keeps the graph, so its rows decide.
            alt = mwm_rows(g, maxcard) if kind == "mwm" else minwm_rows(g)
            if alt != es:
                assert kind == "minwm" and g.kind != "multigraph", (cid, alt, es)
                assert len(alt) == len(es) and ref.close(ref.weight_of(g, alt), ref.weight_of(g, es))
                DISCREPANCIES.append((cid, es, alt))
                es = alt
        wt = ref.weight_of(h, es)
        if rep == "primary" and not any(d[0] == cid for d in DISCREPANCIES):
            assert fmt_expected(g, es, wt, True) == CELLS[cid][5], (cid, fmt_expected(g, es, wt, True), CELLS[cid][5])
        T = vtype(g)
        W = wtype([h.w(e) for e, (u, v, _) in enumerate(h.E) if u != v] or [0])
        wdecl = weights_decl(h, r, W, g)
        if kind == "mwm":
            call = "graph.maximumWeightMatching(weight: " + weighed_call(r, h) + (", maximumCardinality: true)" if maxcard else ")")
        else:
            call = "graph.minimumWeightMatching(weight: " + weighed_call(r, h) + ")"
        after = []
        if rep == "primary" and ref.small(g) and brute_ok(g):
            mode = ("maxcard" if maxcard else "max") if kind == "mwm" else "mincard"
            after += brute_weight_block(T, W, mode)
            after.append("let optimum = try #require(best)")
            if mode != "max":
                after.append("#expect(matching.edges.count == optimum.size, \"maximum cardinality, by brute force\")")
            after.append(f"#expect({close_expr('matching.weight', 'optimum.weight', W)}, \"optimal weight, by brute force: \\(optimum.weight)\")")
        return matching_test_body(cid, g, r, es, T, h=h, weight=wt, W=W, call=call, weights=wdecl, extra_after=after)

    if kind == "mwfm":
        name, g = args[0], args[1]
        via = kwargs.get("via", "bipartite")
        left = kwargs.get("left") or g.left
        right = kwargs.get("right") or g.right
        r = primary_rep(g) if rep == "primary" else rep
        T = vtype(g)
        if g.kind == "bipartite" and rep != "primary":
            if r != "ual":
                return None
            cleft = canonical_left(g)
            cright = [v for v in g.V if v not in cleft]
            gg = copy.copy(g)
            gg.kind = "graph"
            res, port, pos = ref.mwfm_model(gg, cleft, cright)
            W = wtype([g.w(e) for e in range(len(g.E))] or [0])
            before = ["let bipartition = try #require(graph.bipartition())",
                      f"#expect(Array(bipartition.left) == {arr(cleft)} as [{T}])"]
            wdecl = weights_decl(gg, "ual", W, gg)
            call = "graph.minimumWeightFullMatching(bipartition: bipartition, weight: { weightOf($0) })"
            if port is None:
                L = build_graph(gg, "ual", T) + before + wdecl
                L.append(f"#expect({call} == nil)")
                return L
            es = sorted(pos[a][b] for a, b in zip(*port))
            wt = ref.weight_of(gg, es)
            return matching_test_body(cid, gg, "ual", es, T, weight=wt, W=W, call="try #require(" + call + ")",
                                      weights=wdecl, extra_before=before)
        h = g
        if r in ("adjlist", "matrix"):
            h = adjlist_repr(g) if r == "adjlist" else matrix_repr(g)
            if h is None:
                return None
        res, port, pos = ref.mwfm_model(h, left, right)
        W = wtype([h.w(e) for e in range(len(h.E))] or [0])
        wdecl = weights_decl(h, r, W, g)
        if via == "bipartite":
            call = "graph.minimumWeightFullMatching(weight: { weightOf($0) })"
            before = [f"#expect(Array(graph.left) == {arr(g.left)} as [{T}])"]
        else:
            call = "graph.minimumWeightFullMatching(bipartition: bipartition, weight: { weightOf($0) })"
            before = ["let bipartition = try #require(graph.bipartition())",
                      f"#expect(Array(bipartition.left) == {arr(left)} as [{T}])"]
        k = min(len(left), len(right))
        if port is None:
            assert rep != "primary" or CELLS[cid][5] == "nil (no full matching)"
            L = build_graph(h if r in ("adjlist", "matrix") else g, r, T) + before + wdecl
            L.append(f"#expect({call} == nil)")
            if rep == "primary":
                L += brute_card_block(T)
                L.append(f"#expect(largest < {k}, \"no matching covers the smaller side, by brute force\")")
            return L
        es = sorted(pos[a][b] for a, b in zip(*port))
        wt = ref.weight_of(h, es)
        if rep == "primary":
            assert fmt_expected(g, es, wt, True) == CELLS[cid][5], (cid, fmt_expected(g, es, wt, True), CELLS[cid][5])
        after = [f"#expect(matching.edges.count == {k}, \"full: covers the smaller side\")"]
        if rep == "primary" and brute_ok(g):
            after += brute_weight_block(T, W, "full", k)
            after.append("let optimum = try #require(best)")
            after.append(f"#expect({close_expr('matching.weight', 'optimum.weight', W)}, \"least weight, by brute force: \\(optimum.weight)\")")
        return matching_test_body(cid, g, r, es, T, h=h, weight=wt, W=W, call="try #require(" + call + ")",
                                  weights=wdecl, extra_before=before, extra_after=after)
    raise ValueError(kind)


def konig_block(T, left_expr, cover):
    return [
        "// König: Z is every vertex reached from a free left vertex by an alternating path (an",
        "// unmatched edge left to right, the matched edge right to left); (L − Z) ∪ (R ∩ Z) is a",
        "// vertex cover as large as the matching, which certifies that the matching is maximum.",
        f"let leftSide = Set({left_expr})",
        f"var reached = Set(leftSide.filter {{ matching.mate(of: $0) == nil }})",
        "var frontier = Array(reached)",
        "while let x = frontier.popLast() {",
        "    if leftSide.contains(x) {",
        "        for y in graph.neighbors(of: x) where matching.mate(of: x) != y && reached.insert(y).inserted { frontier.append(y) }",
        "    } else if let y = matching.mate(of: x), reached.insert(y).inserted {",
        "        frontier.append(y)",
        "    }",
        "}",
        "let cover = Array(graph.vertices).filter { leftSide.contains($0) != reached.contains($0) }",
        f"#expect(cover == {arr(cover)} as [{T}])",
        "#expect(cover.count == matching.edges.count)",
        "for edge in graph.edges { #expect(cover.contains(edge.u) || cover.contains(edge.v), \"\\(edge) uncovered\") }",
    ]


# ---------------------------------------------------------------------------------------------
# Assignment and stable rows
# ---------------------------------------------------------------------------------------------


def lsa_body(cid, args, kwargs):
    name, M = args[0], args[1]
    maximize = kwargs.get("maximize", False)
    cols = kwargs.get("cols")
    nr = len(M)
    nc = cols if cols is not None else (len(M[0]) if nr else 0)
    port = ref.lsap_port(M, maximize) if nr and nc else ([], [])
    W = "Double" if any(isinstance(x, float) for row in M for x in row) else "Int"
    rows_lit = "[" + ", ".join("[" + ", ".join("nil" if x is None else wlit(x, W) for x in row) + "]" for row in M) + "]"
    L = [f"let matrix: [[{W}?]] = {rows_lit}"]
    call = f"linearSumAssignment(rowCount: {nr}, columnCount: {nc}" + (", maximize: true" if maximize else "") + ") { matrix[$0][$1] }"
    better = ">" if maximize else "<"
    brute = [
        "// Brute force over every assignment of the shorter dimension into the longer one.",
        (f"func entry(_ a: Int, _ b: Int) -> {W}? {{ matrix[a][b] }}" if nr <= nc else f"func entry(_ a: Int, _ b: Int) -> {W}? {{ matrix[b][a] }}"),
        f"let (shorter, longer) = ({min(nr, nc)}, {max(nr, nc)})",
        "var taken = [Bool](repeating: false, count: longer)",
        f"var best: {W}?",
        f"func place(_ a: Int, _ total: {W}) {{",
        "    guard a < shorter else {",
        f"        if best == nil || total {better} best! {{ best = total }}",
        "        return",
        "    }",
        "    for b in 0 ..< longer where !taken[b] {",
        "        guard let c = entry(a, b) else { continue }",
        "        taken[b] = true",
        "        place(a + 1, total + c)",
        "        taken[b] = false",
        "    }",
        "}",
        "place(0, 0)",
    ]
    if port is None:
        assert CELLS[cid][5] == "nil (infeasible)"
        L.append(f"#expect({call} == nil)")
        L += brute
        L.append("#expect(best == nil, \"no assignment avoids the forbidden pairs, by brute force\")")
        return L
    r, c = port
    cost = 0
    for a, b in zip(r, c):
        cost = cost + M[a][b]
    assert CELLS[cid][5] == f"rows {ref.fmtl(r)}; columns {ref.fmtl(c)}; cost {ref.fmtw(cost)}", (cid,)
    L.append(f"let assignment = try #require({call})")
    L.append(f"#expect(assignment.rows == {arr(r)})")
    L.append(f"#expect(assignment.columns == {arr(c)})")
    L.append(f"#expect(assignment.cost == {wlit(cost, W)})")
    L += [
        "// Valid, checked here: min(rowCount, columnCount) pairs by ascending row, no row or column",
        "// twice, no forbidden pair, and the cost is the sum in `rows` order.",
        f"#expect(assignment.rows.count == {min(nr, nc)} && assignment.columns.count == {min(nr, nc)})",
        "#expect(assignment.rows == assignment.rows.sorted() && Set(assignment.rows).count == assignment.rows.count)",
        "#expect(Set(assignment.columns).count == assignment.columns.count)",
        f"var sum: {W} = 0",
        "for (i, j) in zip(assignment.rows, assignment.columns) { sum += try #require(matrix[i][j]) }",
        "#expect(sum == assignment.cost)",
    ]
    if nr and nc:
        L += brute
        L.append(f"#expect({close_expr('assignment.cost', 'best!', W)}, \"optimal, by brute force: \\(String(describing: best))\")")
    return L


def stable_body(cid, args, kwargs):
    name, pp, rp = args[0], args[1], args[2]
    mate = ref.stable_model(pp, rp)
    assert CELLS[cid][5] == "mates " + ref.fmtl(["nil" if m is None else m for m in mate])
    P, R = len(pp), len(rp)
    rmate = [None] * R
    for p, r in enumerate(mate):
        if r is not None:
            rmate[r] = p
    chk = CELLS[cid][6]
    nstable = int(chk.split("among ")[1].split(" ")[0])
    L = [
        f"let proposers: [[Int]] = {json.dumps(pp)}",
        f"let reviewers: [[Int]] = {json.dumps(rp)}",
        "let result = stableMatching(proposerPreferences: proposers, reviewerPreferences: reviewers)",
        f"let expectedProposerMates: [Int?] = {arr(mate)}",
        f"let expectedReviewerMates: [Int?] = {arr(rmate)}",
        f"for p in 0 ..< {P} {{ #expect(result.mate(ofProposer: p) == expectedProposerMates[p], \"proposer \\(p)\") }}",
        f"for r in 0 ..< {R} {{ #expect(result.mate(ofReviewer: r) == expectedReviewerMates[r], \"reviewer \\(r)\") }}",
        "// Every matching over acceptable pairs, by brute force; the stable ones.",
        "func acceptable(_ p: Int, _ r: Int) -> Bool { proposers[p].contains(r) && reviewers[r].contains(p) }",
        "func isStable(_ m: [Int?]) -> Bool {",
        f"    var held = [Int?](repeating: nil, count: {R})",
        "    for (p, r) in m.enumerated() { if let r { held[r] = p } }",
        f"    for p in 0 ..< {P} {{",
        "        for r in proposers[p] where acceptable(p, r) && m[p] != r {",
        "            let proposerPrefers = m[p] == nil || proposers[p].firstIndex(of: r)! < proposers[p].firstIndex(of: m[p]!)!",
        "            let reviewerPrefers = held[r] == nil || reviewers[r].firstIndex(of: p)! < reviewers[r].firstIndex(of: held[r]!)!",
        "            if proposerPrefers && reviewerPrefers { return false }",
        "        }",
        "    }",
        "    return true",
        "}",
        "var stable: [[Int?]] = []",
        "var current: [Int?] = []",
        "var taken = Set<Int>()",
        "func choose(_ p: Int) {",
        f"    guard p < {P} else {{",
        "        if isStable(current) { stable.append(current) }",
        "        return",
        "    }",
        "    current.append(nil)",
        "    choose(p + 1)",
        "    current.removeLast()",
        "    for r in proposers[p] where acceptable(p, r) && !taken.contains(r) {",
        "        taken.insert(r)",
        "        current.append(r)",
        "        choose(p + 1)",
        "        current.removeLast()",
        "        taken.remove(r)",
        "    }",
        "}",
        "choose(0)",
        f"#expect(stable.count == {nstable})",
        f"let found = (0 ..< {P}).map {{ result.mate(ofProposer: $0) }}",
        f"for p in 0 ..< {P} {{ if let r = found[p] {{ #expect(acceptable(p, r) && result.mate(ofReviewer: r) == p) }} }}",
        "#expect(isStable(found), \"stable\")",
        "#expect(stable.contains { $0 == found })",
        "for other in stable {",
        "    // Proposer-optimal: no stable matching gives a proposer a reviewer it ranks higher.",
        f"    for p in 0 ..< {P} {{",
        "        if let r = other[p] { #expect(found[p] != nil && proposers[p].firstIndex(of: found[p]!)! <= proposers[p].firstIndex(of: r)!, \"proposer \\(p) does better in \\(other)\") }",
        "    }",
        "    // Rural hospitals: every stable matching matches the same agents on both sides.",
        "    #expect(other.map { $0 != nil } == found.map { $0 != nil })",
        "    #expect(Set(other.compactMap { $0 }) == Set(found.compactMap { $0 }))",
        "}",
    ]
    return L


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------


def header(comment, imports, suite, struct, tags=None, conformer=False):
    out = []
    for c in comment:
        out.append("// " + c if c else "//")
    out.append("")
    for i in imports:
        out.append(f"import {i}")
    out.append("")
    if conformer:
        out += [
            "/// An undirected graph with no vertex or edge indices: only the protocol's vertex-level members.",
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
            "",
        ]
    t = f", .tags({', '.join(tags)})" if tags else ""
    out.append(f"@Suite(\"{suite}\"{t})")
    out.append(f"struct {struct} {{")
    return out


def write(name, lines):
    while lines and lines[-1] == "":
        lines.pop()
    lines.append("}")
    with open(os.path.join(OUT, name), "w") as f:
        f.write("\n".join(lines) + "\n")
    count = sum(1 for l in lines if l.strip().startswith("@Test("))
    print(f"{name}: {count} tests")
    return count


GROUPS = {}
for cid, kind, args, kwargs in ROWS:
    GROUPS.setdefault(kind, []).append((cid, args, kwargs))


def catalog_file(fname, kinds, comment, imports, suite, struct):
    L = header(comment, imports, suite, struct)
    for kind in kinds:
        for cid, args, kwargs in GROUPS[kind]:
            if kind == "lsa":
                body = lsa_body(cid, args, kwargs)
            elif kind == "stable":
                body = stable_body(cid, args, kwargs)
            else:
                body = row_tests(cid, kind, args, kwargs)
            L += emit_test(cid, title(cid), body, throws=needs_throw(body))
    return L


def ordered(kinds):
    rows = [(cid, kind, args, kwargs) for cid, kind, args, kwargs in ROWS if kind in kinds]
    return rows


def catalog_file_ordered(fname, kinds, comment, imports, suite, struct):
    L = header(comment, imports, suite, struct)
    for cid, kind, args, kwargs in ordered(kinds):
        if kind == "lsa":
            body = lsa_body(cid, args, kwargs)
        elif kind == "stable":
            body = stable_body(cid, args, kwargs)
        else:
            body = row_tests(cid, kind, args, kwargs)
        L += emit_test(cid, title(cid), body, throws=needs_throw(body))
    return L


GEN = "Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's model; see README.md."
ROWS_NOTE = ("Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in "
             "order, so rows are in position order; `multigraph` rows are `ReferencePseudograph`, whose rows "
             "are in position order too (a self-loop twice, parallel edges kept); `L …; R …` rows are "
             "`BipartiteGraph(left:right:edges:)`.")


def wrap(s, width=98):
    words = s.split()
    out, cur = [], ""
    for w in words:
        if len(cur) + 1 + len(w) > width:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    if cur:
        out.append(cur)
    return out


total = 0
IMPORTS_G = ["AdjacencyListModule", "BipartiteGraphs", "GraphProtocols", "GrafluentTestSupport", "MatchingModule", "Testing"]

total += write("MaximalMatchingTests.swift", catalog_file_ordered(
    "MaximalMatchingTests.swift", {"maximal"},
    wrap("`maximalMatching()` (catalog §Maximal: MA-001, MA-003, …, MA-013, MA-024 – MA-034): the greedy "
         "matching in position order, exact edges, every vertex's mate, `weight == edges.count`, "
         "`isPerfect`; validity and maximality checked here, and at least half a maximum matching found "
         "by brute force. " + ROWS_NOTE + " " + GEN),
    IMPORTS_G, "maximalMatching(): greedy in position order", "MaximalMatchingTests"))

total += write("MaximumMatchingTests.swift", catalog_file_ordered(
    "MaximumMatchingTests.swift", {"edmonds"},
    wrap("`maximumMatching()`, Edmonds' blossom algorithm (catalog §Edmonds: MA-002, MA-004, …, MA-014, "
         "MA-079 – MA-114): the exact edges api.md's procedure gives (roots in vertex order, breadth-first, "
         "rows in `incidentEdges` order), every vertex's mate, validity and maximality checked here, and the "
         "size against brute force over every matching (against NetworkX's size for MA-106 and MA-107). "
         "MA-108 – MA-113 need blossom contraction. " + ROWS_NOTE + " " + GEN),
    IMPORTS_G, "maximumMatching(): Edmonds' blossom algorithm", "MaximumMatchingTests"))

total += write("MatchingCheckTests.swift", catalog_file_ordered(
    "MatchingCheckTests.swift", {"check"},
    wrap("`isMatching`, `isMaximalMatching` and `isPerfectMatching` (catalog §Checks, MA-035 – MA-051) on "
         "the row's positions, against the definitions written out here, in the given order and reversed. "
         + ROWS_NOTE + " " + GEN),
    IMPORTS_G, "isMatching, isMaximalMatching, isPerfectMatching", "MatchingCheckTests"))

total += write("HopcroftKarpTests.swift", catalog_file_ordered(
    "HopcroftKarpTests.swift", {"hk"},
    wrap("`maximumBipartiteMatching()` on `BipartiteGraph` and `maximumBipartiteMatching(bipartition:)` "
         "on a `Graph` (catalog §Hopcroft–Karp, MA-052 – MA-078): NetworkX's Hopcroft–Karp output with "
         "left vertices in `left` order, exact edges and mates, validity, the König cover built here from "
         "`mate(of:)` (equal to the catalog's, as large as the matching, covering every edge: the "
         "certificate of maximality), and the size against brute force on small rows. " + ROWS_NOTE + " " + GEN),
    IMPORTS_G, "Hopcroft–Karp: maximumBipartiteMatching", "HopcroftKarpTests"))

total += write("MaximumWeightMatchingTests.swift", catalog_file_ordered(
    "MaximumWeightMatchingTests.swift", {"mwm"},
    wrap("`maximumWeightMatching(weight:maximumCardinality:)` (catalog §Maximum weight: MA-015 – MA-021, "
         "MA-115 – MA-156): NetworkX 3.7's `max_weight_matching` output, exact edges and mates, the weight "
         "(the sum in `edges` order, at full precision), validity, self-loops never weighed, and the weight "
         "(and with `maximumCardinality` the size) against brute force over every matching. Integer rows "
         "use the `SignedInteger` overload, rows with a fractional weight the `FloatingPoint` one. "
         + ROWS_NOTE + " " + GEN),
    IMPORTS_G, "maximumWeightMatching: Galil's blossom algorithm, NetworkX's output", "MaximumWeightMatchingTests"))

total += write("MinimumWeightMatchingTests.swift", catalog_file_ordered(
    "MinimumWeightMatchingTests.swift", {"minwm"},
    wrap("`minimumWeightMatching(weight:)` (catalog §Minimum weight: MA-022, MA-023, MA-157 – MA-165): "
         "`maximumWeightMatching` on (1 + max) − w with `maximumCardinality`, exact edges and mates, the "
         "weight in the original weights, validity, and the least weight among maximum-cardinality "
         "matchings by brute force. " + ROWS_NOTE + " " + GEN),
    IMPORTS_G, "minimumWeightMatching: least weight among maximum-cardinality matchings", "MinimumWeightMatchingTests"))

total += write("FullMatchingTests.swift", catalog_file_ordered(
    "FullMatchingTests.swift", {"mwfm"},
    wrap("`minimumWeightFullMatching(weight:)` on `BipartiteGraph` and "
         "`minimumWeightFullMatching(bipartition:weight:)` on a `Graph` (catalog §Full matching, MA-166 – "
         "MA-181): scipy's `linear_sum_assignment` on the biadjacency matrix (rows `left`, columns "
         "`right`, missing edges forbidden), exact edges, mates and weight; validity; the matching covers "
         "the smaller side; the least weight, or that no full matching exists, by brute force. "
         + ROWS_NOTE + " " + GEN),
    IMPORTS_G, "minimumWeightFullMatching: the Hungarian method in scipy's form", "FullMatchingTests"))

total += write("LinearSumAssignmentTests.swift", catalog_file_ordered(
    "LinearSumAssignmentTests.swift", {"lsa"},
    wrap("`linearSumAssignment(rowCount:columnCount:maximize:cost:)` (catalog §Assignment, MA-182 – "
         "MA-212): scipy 1.18.1's `(row_ind, col_ind)` exactly, and the cost; validity (pairs by ascending "
         "row, no row or column twice, no forbidden pair, the cost the sum) and the optimum by brute force "
         "over every assignment. `nil` entries are forbidden pairs (scipy's +inf). MA-212 is exact in "
         "`Int` where scipy's float64 rounds. " + GEN),
    ["MatchingModule", "Testing"], "linearSumAssignment: scipy's shortest augmenting path", "LinearSumAssignmentTests"))

total += write("StableMatchingTests.swift", catalog_file_ordered(
    "StableMatchingTests.swift", {"stable"},
    wrap("`stableMatching(proposerPreferences:reviewerPreferences:)` (catalog §Stable, MA-213 – MA-228): "
         "the proposer-optimal stable matching, exact mates from both sides, and against every stable "
         "matching enumerated here by brute force: the result is one of them, no proposer does better in "
         "another (proposer-optimal), and all of them match the same agents (the rural hospitals "
         "theorem). " + GEN),
    ["MatchingModule", "Testing"], "stableMatching: Gale–Shapley deferred acceptance", "StableMatchingTests"))

# ---------------------------------------------------------------------------------------------
# Representation file
# ---------------------------------------------------------------------------------------------
REP_NAMES = {"pseudo": "ReferencePseudograph", "ual": "UndirectedAdjacencyList", "unindexed": "no indices",
             "adjlist": "AdjacencyList.undirected", "matrix": "AdjacencyMatrix.undirected", "bipartite": "BipartiteGraph"}

L = header(wrap(
    "The graph rows of the catalog again on other representations. Rows on `UndirectedAdjacencyList` "
    "run again on `ReferencePseudograph`; every graph row runs on a file-private conformer with no "
    "vertex or edge indices (rows from `incidentEdges(of:)`, `mate(ofIndex:)` by position in "
    "`vertices`); all with the catalog's values, since their rows are in position order too. Then on "
    "`AdjacencyList.undirected` with each edge an arc as written, and on `AdjacencyMatrix.undirected` "
    "with the arcs at their row-major cells (rows on 0..<n with no arc twice). Through `.undirected` a "
    "row is successors, then predecessors, so the exact outputs of the row-order-dependent algorithms "
    "differ from the catalog's: swiftgen.py computed each with ref.py's model on that "
    "representation's rows, and the weighted rows with NetworkX 3.7 given that adjacency order. Matrix "
    "positions are cells, compared as [source, target]. The `BipartiteGraph` rows run through "
    "`bipartition()` (canonical sides) on the `BipartiteGraph` and on an `UndirectedAdjacencyList` with "
    "the same vertices and edges. Weighted rows with parallel edges stay off the two views (the tie "
    "between copies would follow their row order). See README.md."),
    ["AdjacencyListModule", "AdjacencyMatrixModule", "BipartiteGraphs", "GraphProtocols", "GrafluentTestSupport", "MatchingModule", "Testing"],
    "Catalog graph rows on every representation", "MatchingRepresentationTests", conformer=True)
rep_count = 0
for cid, kind, args, kwargs in ROWS:
    if kind in ("lsa", "stable", "trap"):
        continue
    g = args[1]
    reps = []
    if g.kind == "bipartite":
        if kind in ("hk", "mwfm"):
            reps = ["bipartite", "ual"]
        else:
            reps = ["unindexed"]   # MA-100: maximumMatching() on a BipartiteGraph; again with no indices
    else:
        reps = (["pseudo"] if g.kind != "multigraph" else []) + ["unindexed", "adjlist", "matrix"]
    blocks = []
    names = []
    for rep in reps:
        if g.kind == "bipartite" and kind == "edmonds":
            gg = copy.copy(g)
            gg.kind = "graph"
            body = row_tests(cid, kind, (args[0], gg), kwargs, rep=rep)
        else:
            body = row_tests(cid, kind, args, kwargs, rep=rep)
        if body is None:
            continue
        names.append(REP_NAMES[rep] + (" via bipartition()" if g.kind == "bipartite" and kind in ("hk", "mwfm") else ""))
        blocks.append((rep, body))
    if not blocks:
        continue
    ttl = esc(f"{cid} {CELLS[cid][2]}, on " + ", ".join(names))
    body = []
    for rep, b in blocks:
        body.append(f"do {{ // {REP_NAMES[rep]}")
        body += ["    " + l if l else l for l in sum((x.split("\n") for x in b), [])]
        body.append("}")
    L += emit_test(cid, ttl, body, throws=needs_throw(body))
total += write("MatchingRepresentationTests.swift", L)

# ---------------------------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------------------------
TRAPS = {
    "MA-229": ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
               "_ = graph.isMatching([1])"],
    "MA-230": ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])",
               "// A bipartition of the path 0–1–2–3 (three edges): four vertices, not three.",
               "let other = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])",
               "_ = graph.maximumBipartiteMatching(bipartition: other.bipartition()!)"],
    "MA-231": ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1)])",
               "// The sides of 0–2, 1–3: left [0, 1], right [2, 3], so the edge 0–1 is inside the left side.",
               "let other = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3)])",
               "_ = graph.maximumBipartiteMatching(bipartition: other.bipartition()!)"],
    "MA-232": ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
               "_ = graph.maximumWeightMatching(weight: { _ in Double.nan })"],
    "MA-233": ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
               "_ = graph.maximumWeightMatching(weight: { _ in Double.infinity })"],
    "MA-234": ["_ = linearSumAssignment(rowCount: -1, columnCount: 2) { (_: Int, _: Int) -> Int? in 0 }"],
    "MA-235": ["_ = linearSumAssignment(rowCount: 1, columnCount: 1) { (_: Int, _: Int) -> Double? in .nan }"],
    "MA-236": ["let graph = BipartiteGraph<Int>(left: [0], right: [1], edges: [UndirectedEdge(0, 1)])!",
               "_ = graph.minimumWeightFullMatching(weight: { _ in Double.nan })"],
    "MA-237": ["_ = stableMatching(proposerPreferences: [[1]], reviewerPreferences: [[0]])"],
    "MA-238": ["_ = stableMatching(proposerPreferences: [[0, 0]], reviewerPreferences: [[0]])"],
}
L = header(wrap(
    "Preconditions, as exit tests (catalog MA-229 – MA-238): a position outside `edges`, a bipartition "
    "of another graph, an edge inside a side, a NaN or infinite weight, a negative count or NaN cost, a "
    "NaN weight in a full matching, an index out of range or repeated in a preference list. Then the "
    "preconditions the catalog does not list: `mate(of:)` on a non-vertex, `mate(ofIndex:)` out of "
    "range, `mate(ofProposer:)` and `mate(ofReviewer:)` out of range, a reviewer list naming a proposer "
    "out of range or one twice, a position outside `edges` given to the other two checks, a NaN weight "
    "to `minimumWeightMatching`, a negative column count, a NaN cost under `maximize`. Each exit test "
    "builds its inputs inside the closure. Generated from cases.md by swiftgen.py, the tests after "
    "MA-238 written by hand; see README.md."),
    ["AdjacencyListModule", "BipartiteGraphs", "GraphProtocols", "GrafluentTestSupport", "MatchingModule", "Testing"],
    "Matching preconditions", "MatchingPreconditionTests", tags=[".precondition"])
for cid, kind, args, kwargs in ROWS:
    if kind != "trap":
        continue
    group, name, inp, call, why = args
    ttl = esc(f"{cid} {CELLS[cid][2]} traps")
    body = ["await #expect(processExitsWith: .failure) {"] + ["    " + l for l in TRAPS[cid]] + ["}"]
    T = [f"    @Test(\"{ttl}\")", f"    func {fn(cid)}() async {{", f"        // {inp}; {call}" if inp else f"        // {call}"]
    T += indent(body)
    T += ["    }", ""]
    L += T
EXTRA = [
    ("mate(of:) on a vertex that is not in the graph traps", "mateOfNonVertex",
     ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
      "_ = graph.maximumMatching().mate(of: 7)"]),
    ("matchedEdge(of:) on a vertex that is not in the graph traps", "matchedEdgeOfNonVertex",
     ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
      "_ = graph.maximalMatching().matchedEdge(of: 7)"]),
    ("mate(ofIndex:) past the last index traps", "mateOfIndexPastEnd",
     ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
      "_ = graph.maximumMatching().mate(ofIndex: 2)"]),
    ("mate(ofIndex:) with a negative index traps", "mateOfNegativeIndex",
     ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
      "_ = graph.maximumMatching().mate(ofIndex: -1)"]),
    ("mate(ofProposer:) out of range traps", "mateOfProposerOutOfRange",
     ["_ = stableMatching(proposerPreferences: [[0]], reviewerPreferences: [[0]]).mate(ofProposer: 1)"]),
    ("mate(ofReviewer:) out of range traps", "mateOfReviewerOutOfRange",
     ["_ = stableMatching(proposerPreferences: [[0]], reviewerPreferences: [[0]]).mate(ofReviewer: 1)"]),
    ("a reviewer list naming a proposer out of range traps", "proposerIndexOutOfRange",
     ["_ = stableMatching(proposerPreferences: [[0]], reviewerPreferences: [[1]])"]),
    ("a reviewer list naming a proposer twice traps", "repeatInReviewerList",
     ["_ = stableMatching(proposerPreferences: [[0], [0]], reviewerPreferences: [[1, 0, 1]])"]),
    ("a negative reviewer index traps", "negativeReviewerIndex",
     ["_ = stableMatching(proposerPreferences: [[-1]], reviewerPreferences: [[0]])"]),
    ("isMaximalMatching with a position outside edges traps", "isMaximalOutOfRange",
     ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
      "_ = graph.isMaximalMatching([1])"]),
    ("isPerfectMatching with a position outside edges traps", "isPerfectOutOfRange",
     ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])",
      "_ = graph.isPerfectMatching([0, 5])"]),
    ("minimumWeightMatching with a NaN weight traps", "minimumWeightNaN",
     ["let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])",
      "_ = graph.minimumWeightMatching(weight: { $0 == 1 ? Double.nan : 1 })"]),
    ("linearSumAssignment with a negative column count traps", "negativeColumnCount",
     ["_ = linearSumAssignment(rowCount: 2, columnCount: -1) { (_: Int, _: Int) -> Int? in 0 }"]),
    ("linearSumAssignment with a NaN cost under maximize traps", "nanCostMaximize",
     ["_ = linearSumAssignment(rowCount: 2, columnCount: 2, maximize: true) { (i: Int, j: Int) -> Double? in i == 1 && j == 0 ? .nan : 1 }"]),
]
for ttl, fname, body in EXTRA:
    L += [f"    @Test(\"{esc(ttl)}\")", f"    func {fname}() async {{",
          "        await #expect(processExitsWith: .failure) {"] + ["            " + l for l in body] + ["        }", "    }", ""]
total += write("MatchingPreconditionTests.swift", L)
print("generated tests:", total)
print("discrepancies (catalog edges, api.md edges):", DISCREPANCIES)
