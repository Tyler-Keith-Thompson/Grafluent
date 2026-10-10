"""Writes the catalog-row test files of Tests/ColoringModuleTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 swiftgen.py [OUT_DIR]   # default: Tests/ColoringModuleTests

First runs ref.py's catalog with each case builder instrumented, so every row's inputs are kept
as structured values, and checks that the rendered catalog equals cases.md byte for byte. Then
re-evaluates each row with ref.py's model functions, asserts each value matches its catalog cell,
and writes one @Test per row. The representation rows (AdjacencyList and AdjacencyMatrix through
`.undirected`) are recomputed with the same models on those representations' rows and positions:
successors then predecessors, arcs in insertion order (AdjacencyList) or at row-major cells
(AdjacencyMatrix).
"""
import copy
import json
import os
import re
import sys

import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "ColoringModuleTests")
os.chdir(HERE)
import ref  # noqa: E402

RECORDS = {}


def instrument(kind, fn):
    def wrapper(*args, **kwargs):
        start = len(ref.CASES)
        r = fn(*args, **kwargs)
        assert len(ref.CASES) == start + 1
        RECORDS[start] = (kind, args, kwargs)
        return r
    return wrapper


KINDS = ["greedy", "order", "chi", "min", "any", "edge", "bip_edge", "is", "is_edge"]
for kind in KINDS:
    setattr(ref, f"case_{kind}", instrument(kind, getattr(ref, f"case_{kind}")))
ref.build()
ref.build_tail()
assert not ref.FAILS, ref.FAILS
TOTAL = len(ref.CASES)
assert TOTAL == 281

text = ref.HEADER.replace("{last}", f"{len(ref.CASES):03d}").replace("{count}", str(len(ref.CASES)))
for i, (grp, name, inp, call, exp, chk) in enumerate(ref.CASES):
    text += f"| CO-{i+1:03d} | {grp} | {name} | {inp} | `{call}` | {exp} | {chk} |\n"
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == text, "cases.md is not ref.py's output"

CELLS = {}
for line in text.splitlines():
    if line.startswith("| CO-"):
        parts = [p.strip() for p in line.strip().strip("|").split(" | ")]
        CELLS[parts[0]] = parts
assert len(CELLS) == TOTAL

ROWS = []
for i in range(TOTAL):
    cid = f"CO-{i+1:03d}"
    if i in RECORDS and CELLS[cid][5] != "trap":
        kind, args, kwargs = RECORDS[i]
        ROWS.append((cid, kind, args, kwargs))
    else:
        ROWS.append((cid, "trap", None, None))

# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------


def lit(x):
    if x is None:
        return "nil"
    if isinstance(x, bool):
        return "true" if x else "false"
    if isinstance(x, str):
        return json.dumps(x, ensure_ascii=False)
    return str(x)


def arr(xs):
    return "[" + ", ".join(lit(x) for x in xs) + "]"


def tarr(xs, T):
    return "[" + ", ".join(lit(x) for x in xs) + f"] as [{T}]"


def vtype(g):
    return "String" if any(isinstance(v, str) for v in g.V) else "Int"


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def fname(cid):
    return "co" + cid[3:]


def title(cid, maxlen=118):
    parts = CELLS[cid]
    name, exp = parts[2], parts[5]
    t = f"{cid} {name}"
    if name.endswith(": " + exp):
        return esc(t)
    if len(t) + len(exp) + 2 <= maxlen:
        t += ": " + exp
    return esc(t)


def comment_input(cid):
    parts = CELLS[cid]
    s = f"{parts[3]}; {parts[4]}".replace("`", "")
    if len(s) > 180:
        s = s[:177] + "…"
    return "// " + s


def labels(g, idxs):
    return [g.V[i] for i in idxs]


# ---------------------------------------------------------------------------------------------
# Representations
# ---------------------------------------------------------------------------------------------


def with_rows(g, ie, rows):
    """A copy of g with edges `ie` (vertex indices, position order) and rows `rows`."""
    h = copy.copy(g)
    h.ie = [list(e) for e in ie]
    h.rows = rows
    h.srows = []
    for a in range(g.n):
        seen, r = set(), []
        for (b, _) in rows[a]:
            if b != a and b not in seen:
                seen.add(b)
                r.append(b)
        h.srows.append(r)
    h.adj = [set(r) for r in h.srows]
    h.deg = [len(r) for r in h.srows]
    assert h.adj == g.adj
    return h


def adjlist_repr(g):
    """AdjacencyList(arcs as written).undirected: positions are the arcs in order; each row is
    out-arcs then in-arcs, each in insertion order. None if an arc repeats."""
    if len(set(g.E)) != len(g.E):
        return None
    outs = [[] for _ in g.V]
    ins = [[] for _ in g.V]
    for e, (a, b) in enumerate(g.ie):
        outs[a].append((b, e))
        ins[b].append((a, e))
    h = with_rows(g, g.ie, [outs[i] + ins[i] for i in range(g.n)])
    h.posmap = list(range(len(g.E)))
    h.cells = None
    return h


def matrix_repr(g):
    """AdjacencyMatrix(vertexCount: n, arcs).undirected for vertices 0..<n in order: positions are
    the cells in row-major order; each row is successors ascending, then predecessors ascending."""
    if g.V != list(range(g.n)) or len(set(g.E)) != len(g.E):
        return None
    cells = sorted(g.E)
    pos = {c: k for k, c in enumerate(cells)}
    rows = []
    for v in range(g.n):
        succ = sorted(t for (s, t) in cells if s == v)
        pred = sorted(s for (s, t) in cells if t == v)
        rows.append([(t, pos[(v, t)]) for t in succ] + [(s, pos[(s, v)]) for s in pred])
    h = with_rows(g, cells, rows)
    h.posmap = [pos[a] for a in g.E]   # catalog position -> cell position
    h.cells = cells
    return h


# ---------------------------------------------------------------------------------------------
# Graph construction lines
# ---------------------------------------------------------------------------------------------


def pairs_line(g, T):
    return f"let pairs: [({T}, {T})] = [" + ", ".join(f"({lit(u)}, {lit(v)})" for (u, v) in g.E) + "]"


def build_graph(g, rep, T):
    L = [pairs_line(g, T)]
    if rep == "primary":
        rep = {"graph": "ual", "multigraph": "pseudo", "bipartite": "bipartite"}[g.kind]
    if rep == "ual":
        L.append(f"let graph = UndirectedAdjacencyList<{T}>(vertices: {tarr(g.V, T)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
    elif rep == "pseudo":
        L.append(f"let graph = ReferencePseudograph<{T}>(vertices: {tarr(g.V, T)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }})")
    elif rep == "bipartite":
        L.append(f"let graph = try #require(BipartiteGraph<{T}>(left: {tarr(g.left, T)}, right: {tarr(g.right, T)}, edges: pairs.map {{ UndirectedEdge($0.0, $0.1) }}))")
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
    return [
        "let vertexList = Array(graph.vertices)",
        f"#expect(vertexList == {tarr(g.V, T)})",
        "let n = vertexList.count",
        "// Edge ends as vertex indices (positions in `vertices`), in position order; a self-loop is (v, v).",
        "let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }",
    ]


ADJ = [
    "// The simple graph, written out: each vertex's distinct other neighbours, in the order their first",
    "// edges come in its row (positions ascending); self-loops dropped, parallel edges once.",
    "var adjacent = [[Int]](repeating: [], count: n)",
    "for (a, b) in ends where a != b {",
    "    if !adjacent[a].contains(b) { adjacent[a].append(b) }",
    "    if !adjacent[b].contains(a) { adjacent[b].append(a) }",
    "}",
]


def vertex_checks(exp, k):
    return [
        "let colors = vertexList.map { coloring.color(of: $0) }",
        f"#expect(colors == {arr(exp)})",
        "#expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)",
        f"#expect(coloring.colorCount == {k})",
        "// Proper, checked here: the ends of every edge but a self-loop have different colours.",
        "for (a, b) in ends where a != b { #expect(colors[a] != colors[b], \"\\(vertexList[a])–\\(vertexList[b]) both \\(colors[a])\") }",
        "#expect(graph.isVertexColoring { coloring.color(of: $0) })",
        "// Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.",
        "#expect(Set(colors) == Set(0 ..< coloring.colorCount))",
        "#expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })",
    ]


GREEDY_BOUNDS = [
    "// At most Δ + 1 colours, Δ the greatest simple degree.",
    "#expect(coloring.colorCount <= (adjacent.map(\\.count).max() ?? 0) + 1)",
    "// First fit, checked here: a vertex of colour c has neighbours of every colour below c.",
    "for v in 0 ..< n { #expect(Set(adjacent[v].map { colors[$0] }).isSuperset(of: 0 ..< colors[v]), \"\\(vertexList[v])\") }",
]


def first_fit(order_var):
    return [
        f"var expected = [Int](repeating: -1, count: n)",
        f"for v in {order_var} {{",
        "    var c = 0",
        "    while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }",
        "    expected[v] = c",
        "}",
    ]


PROC = {
    "largestFirst": [
        "// Largest first written out: simple degree descending, the lesser index on ties; then first fit.",
        "let order = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }",
    ] + first_fit("order"),
    "smallestLast": [
        "// Smallest last written out (Matula–Beck): remove a vertex of least degree in what is left, the",
        "// lesser index on ties; first fit in the reverse removal order. The greatest degree at removal is",
        "// the degeneracy.",
        "var degree = adjacent.map(\\.count)",
        "var removed = [Bool](repeating: false, count: n)",
        "var removal: [Int] = []",
        "var degeneracy = 0",
        "for _ in 0 ..< n {",
        "    let v = (0 ..< n).filter { !removed[$0] }.min { (degree[$0], $0) < (degree[$1], $1) }!",
        "    degeneracy = max(degeneracy, degree[v])",
        "    removed[v] = true",
        "    removal.append(v)",
        "    for w in adjacent[v] where !removed[w] { degree[w] -= 1 }",
        "}",
    ] + first_fit("removal.reversed()") + [
        "#expect(coloring.colorCount <= degeneracy + 1)",
    ],
    "saturationLargestFirst": [
        "// DSatur written out (NetworkX's rule): the uncoloured vertex with the most distinct neighbour",
        "// colours, then the greatest simple degree, then the lesser index, takes the least colour free.",
        "var expected = [Int](repeating: -1, count: n)",
        "for _ in 0 ..< n {",
        "    let key = { (v: Int) in (Set(adjacent[v].map { expected[$0] }.filter { $0 >= 0 }).count, adjacent[v].count) }",
        "    let v = (0 ..< n).filter { expected[$0] < 0 }.max { key($0) < key($1) || (key($0) == key($1) && $0 > $1) }!",
        "    var c = 0",
        "    while adjacent[v].contains(where: { expected[$0] == c }) { c += 1 }",
        "    expected[v] = c",
        "}",
    ],
    "independentSet": [
        "// Independent set written out: colour k is a maximal independent set of the uncoloured vertices,",
        "// built by taking the available vertex with the fewest available neighbours (the lesser index on",
        "// ties) and making it and its neighbours unavailable.",
        "var expected = [Int](repeating: -1, count: n)",
        "var k = 0",
        "while expected.contains(-1) {",
        "    var available = Set((0 ..< n).filter { expected[$0] < 0 })",
        "    while true {",
        "        let left = available",
        "        guard let v = left.min(by: { (adjacent[$0].filter(left.contains).count, $0) < (adjacent[$1].filter(left.contains).count, $1) }) else { break }",
        "        expected[v] = k",
        "        available.remove(v)",
        "        for w in adjacent[v] { available.remove(w) }",
        "    }",
        "    k += 1",
        "}",
    ],
    "connectedSequentialBreadthFirst": [
        "// Connected sequential breadth-first written out: each component from its least vertex, neighbours",
        "// in row order; then first fit.",
        "var seen = [Bool](repeating: false, count: n)",
        "var order: [Int] = []",
        "for root in 0 ..< n where !seen[root] {",
        "    seen[root] = true",
        "    var queue = [root]",
        "    var head = 0",
        "    while head < queue.count {",
        "        let v = queue[head]",
        "        head += 1",
        "        order.append(v)",
        "        for w in adjacent[v] where !seen[w] {",
        "            seen[w] = true",
        "            queue.append(w)",
        "        }",
        "    }",
        "}",
    ] + first_fit("order"),
    "connectedSequentialDepthFirst": [
        "// Connected sequential depth-first written out: each component from its least vertex, preorder,",
        "// neighbours in row order; then first fit.",
        "var seen = [Bool](repeating: false, count: n)",
        "var order: [Int] = []",
        "for root in 0 ..< n where !seen[root] {",
        "    seen[root] = true",
        "    order.append(root)",
        "    var stack = [(root, 0)]",
        "    while let (v, k) = stack.last {",
        "        if k == adjacent[v].count {",
        "            stack.removeLast()",
        "            continue",
        "        }",
        "        stack[stack.count - 1].1 += 1",
        "        let w = adjacent[v][k]",
        "        if !seen[w] {",
        "            seen[w] = true",
        "            order.append(w)",
        "            stack.append((w, 0))",
        "        }",
        "    }",
        "}",
    ] + first_fit("order"),
}


def body_greedy(cid, g, T, swift):
    col = ref.STRATS[swift][1](g)
    assert ref.fmt_col(col) == CELLS[cid][5], (cid, col)
    L = [f"let coloring = graph.greedyColoring(strategy: .{swift})"]
    L += vertex_checks(col, ref.ncolors(col))
    L += ADJ + GREEDY_BOUNDS + PROC[swift] + ["#expect(colors == expected)"]
    L += ["// No colouring uses fewer than χ colours.", "#expect(coloring.colorCount >= graph.chromaticNumber())"]
    if swift == "largestFirst":
        L += ["// The default strategy.", "#expect(graph.greedyColoring() == coloring)"]
    return L


def body_order(cid, g, T, order_labels):
    order = [g.idx[v] for v in order_labels]
    col = ref.first_fit(g, order)
    assert ref.fmt_col(col) == CELLS[cid][5], cid
    L = [f"let order = {tarr(order_labels, T)}", "let coloring = graph.greedyColoring(order: order)"]
    L += vertex_checks(col, ref.ncolors(col))
    L += ADJ + GREEDY_BOUNDS
    L += ["// First fit in the given order, written out."]
    L += ["let orderIndices = order.map { vertexList.firstIndex(of: $0)! }"]
    L += first_fit("orderIndices") + ["#expect(colors == expected)"]
    L += ["// The order as any sequence: a lazy map of indices gives the same colouring.",
          "#expect(graph.greedyColoring(order: order.indices.lazy.map { order[$0] }) == coloring)"]
    return L


CHI_BRUTE = 36      # vertices: chi by exhaustive search
CLIQUE_BRUTE = 16   # vertices: omega by every subset
LEX_BRUTE = 25      # component size: the lexicographic rule by exhaustive search for every k


def clique_lines(g):
    if g.n <= CLIQUE_BRUTE:
        return ["// χ ≥ ω: the largest clique, by brute force over every subset (bit i is the vertex at index i).",
                "let neighbourMask = adjacent.map { $0.reduce(0) { $0 | 1 << $1 } }",
                "var omega = 0",
                "for mask in 0 ..< 1 << n where (0 ..< n).allSatisfy({ mask & 1 << $0 == 0 || mask & ~(1 << $0) & ~neighbourMask[$0] == 0 }) {",
                "    omega = max(omega, mask.nonzeroBitCount)",
                "}",
                "#expect(chi >= omega)"]
    H = nx.Graph()
    H.add_nodes_from(range(g.n))
    H.add_edges_from(g.simple_edges())
    best = max(nx.find_cliques(H), key=lambda c: (len(c), sorted(c)))
    best = sorted(best)
    return [f"// χ ≥ ω: a clique of {len(best)} (found by swiftgen.py with NetworkX's find_cliques), checked here.",
            f"let clique = {arr(best)}",
            "for a in clique { for b in clique where a < b { #expect(adjacent[a].contains(b)) } }",
            "#expect(chi >= clique.count)"]


CHI_SEARCH = [
    "// Brute force: the least k for which an exhaustive search finds a proper colouring with k colours",
    "// (vertices in order of degree, descending; each takes a colour at most one above those used).",
    "let byDegree = (0 ..< n).sorted { (adjacent[$0].count, $1) > (adjacent[$1].count, $0) }",
    "func colorable(_ k: Int) -> Bool {",
    "    var colour = [Int](repeating: -1, count: n)",
    "    func place(_ i: Int, _ used: Int) -> Bool {",
    "        if i == n { return true }",
    "        let v = byDegree[i]",
    "        for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {",
    "            colour[v] = c",
    "            if place(i + 1, max(used, c + 1)) { return true }",
    "        }",
    "        colour[v] = -1",
    "        return false",
    "    }",
    "    return place(0, 0)",
    "}",
    "#expect(chi == (0 ... n).first(where: colorable))",
]


def body_chi(cid, g, T):
    chi = ref.chromatic_number(g)
    assert str(chi) == CELLS[cid][5], cid
    loops = any(g.loop)
    L = ["let chi = graph.chromaticNumber()", f"#expect(chi == {chi})"]
    L += ["// minimumColoring() is a proper colouring with χ colours, checked here; no greedy colouring uses fewer.",
          "let minimum = graph.minimumColoring()",
          "#expect(minimum.colorCount == chi)",
          "let colors = vertexList.map { minimum.color(of: $0) }",
          "for (a, b) in ends where a != b { #expect(colors[a] != colors[b], \"\\(vertexList[a])–\\(vertexList[b])\") }",
          "#expect(Set(colors).count == chi)",
          "for strategy in ColoringStrategy.allCases { #expect(graph.greedyColoring(strategy: strategy).colorCount >= chi, \"\\(strategy)\") }"]
    L += ADJ
    if g.n <= CHI_BRUTE:
        L += CHI_SEARCH
    else:
        if g.token in ref.LITERATURE_CHI:
            L += [f"// {g.n} vertices, too many for the search here: χ = {chi} is the literature value (ref.py)."]
    L += clique_lines(g)
    if not loops:
        L += ["// Bipartite exactly when χ ≤ 2 (no self-loops here).",
              "#expect((graph.bipartition() != nil) == (chi <= 2))"]
    return L


def comps_lines():
    return [
        "// Components, each as its vertex indices ascending.",
        "var componentOf = [Int](repeating: -1, count: n)",
        "var components: [[Int]] = []",
        "for root in 0 ..< n where componentOf[root] < 0 {",
        "    componentOf[root] = components.count",
        "    var members = [root]",
        "    var head = 0",
        "    while head < members.count {",
        "        let v = members[head]",
        "        head += 1",
        "        for w in adjacent[v] where componentOf[w] < 0 {",
        "            componentOf[w] = components.count",
        "            members.append(w)",
        "        }",
        "    }",
        "    components.append(members.sorted())",
        "}",
    ]


def lex_lines(g):
    comps = ref.components(g)
    big = max((len(c) for c in comps), default=0) > LEX_BRUTE
    L = comps_lines()
    if not big:
        L += [
            "// Brute force per component: for k = 1, 2, …, an exhaustive search in index order for the first",
            "// proper colour vector with at most k colours (each vertex a colour at most one above those used,",
            "// tried ascending). The first k with one is the component's χ, and that vector is its",
            "// lexicographically least χ-colouring, which lexicographicallyFirstMinimumColoring() gives it.",
            "for members in components {",
            "    var colour = [Int](repeating: -1, count: n)",
            "    func place(_ i: Int, _ used: Int, _ k: Int) -> Bool {",
            "        if i == members.count { return true }",
            "        let v = members[i]",
            "        for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {",
            "            colour[v] = c",
            "            if place(i + 1, max(used, c + 1), k) { return true }",
            "        }",
            "        colour[v] = -1",
            "        return false",
            "    }",
            "    let k = (1 ... members.count).first { place(0, 0, $0) }!",
            "    #expect(members.map { colors[$0] } == members.map { colour[$0] }, \"\\(members)\")",
            "    #expect(Set(members.map { colors[$0] }).count == k)",
            "}",
        ]
    else:
        assert len(comps) == 1
        chi = ref.chromatic_number(g)
        L += [
            f"// One component of {g.n} vertices, too many to search every k here: with k = χ = {chi}",
            "// (chromaticNumber(), and ref.py), an exhaustive search in index order for the first proper colour",
            "// vector with at most k colours (each vertex a colour at most one above those used, tried",
            "// ascending) finds the lexicographically least χ-colouring.",
            f"let k = {chi}",
            "#expect(graph.chromaticNumber() == k)",
            "var colour = [Int](repeating: -1, count: n)",
            "func place(_ v: Int, _ used: Int) -> Bool {",
            "    if v == n { return true }",
            "    for c in 0 ..< min(k, used + 1) where !adjacent[v].contains(where: { colour[$0] == c }) {",
            "        colour[v] = c",
            "        if place(v + 1, max(used, c + 1)) { return true }",
            "    }",
            "    colour[v] = -1",
            "    return false",
            "}",
            "#expect(place(0, 0))",
            "#expect(colors == colour)",
            "#expect(components.count == 1)",
        ]
    return L


def body_min(cid, g, T):
    col = ref.minimum_coloring_model(g)
    assert ref.fmt_col(col) == CELLS[cid][5], cid
    L = ["let coloring = graph.lexicographicallyFirstMinimumColoring()"]
    L += vertex_checks(col, ref.ncolors(col))
    L += ["#expect(coloring.colorCount == graph.chromaticNumber())",
          "// Classes numbered by least vertex: each class's first vertex comes before the next class's.",
          "let firsts = coloring.colorClasses.map { $0.first.flatMap { vertexList.firstIndex(of: $0) } ?? -1 }",
          "#expect(firsts == firsts.sorted())"]
    L += ADJ + lex_lines(g)
    if not any(g.loop) and nx.is_bipartite(g.nx()):
        L += ["// Bipartite: each component coloured by its bipartition() sides, left 0, right 1.",
              "let sides = try #require(graph.bipartition())",
              "#expect(sides.left.map { coloring.color(of: $0) }.allSatisfy { $0 == 0 })",
              "#expect(sides.right.map { coloring.color(of: $0) }.allSatisfy { $0 == 1 })"]
    return L


FIRST_APPEARANCE = [
    "// Numbered by first appearance: the first vertex has colour 0, and each colour first appears",
    "// after the one below it.",
    "var high = -1",
    "for c in colors {",
    "    #expect(c <= high + 1, \"\\(colors)\")",
    "    high = max(high, c)",
    "}",
]


def any_checks(g, chi):
    return [
        "let colors = vertexList.map { coloring.color(of: $0) }",
        "#expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)",
        f"#expect(coloring.colorCount == {chi})",
        "#expect(coloring.colorCount == graph.chromaticNumber())",
        "// Proper, checked here: the ends of every edge but a self-loop have different colours.",
        "for (a, b) in ends where a != b { #expect(colors[a] != colors[b], \"\\(vertexList[a])–\\(vertexList[b]) both \\(colors[a])\") }",
        "#expect(graph.isVertexColoring { coloring.color(of: $0) })",
        "// Colours 0..<colorCount, each used; class c is the vertices of colour c in `vertices` order.",
        "#expect(Set(colors) == Set(0 ..< coloring.colorCount))",
        "#expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in vertexList.indices.filter { colors[$0] == c }.map { vertexList[$0] } })",
    ] + FIRST_APPEARANCE


def body_any(cid, g, T):
    chi = ref.chromatic_number(g)
    forced, why = ref.forced_minimum(g)
    L = ["let coloring = graph.minimumColoring()"] + any_checks(g, chi)
    if forced is not None:
        assert ref.fmt_col(forced) == CELLS[cid][5], cid
        L += [f"// Forced, ref.py: {why}.", f"#expect(colors == {arr(forced)})"]
        if not any(g.loop) and nx.is_bipartite(g.nx()) and g.simple_edges():
            L += ["// Bipartite: coloured by its bipartition() sides, left 0, right 1.",
                  "let sides = try #require(graph.bipartition())",
                  "#expect(sides.left.map { coloring.color(of: $0) }.allSatisfy { $0 == 0 })",
                  "#expect(sides.right.map { coloring.color(of: $0) }.allSatisfy { $0 == 1 })"]
    else:
        assert CELLS[cid][5] == f"{chi} colors, proper, numbered by first appearance", cid
        L += [f"// χ = {chi} in ref.py ({CELLS[cid][6].split('; ')[-1]}); the colours themselves depend on the search."]
    return L


def edge_checks(exp, k, exact_delta):
    L = [
        "let colors = graph.edges.indices.map { coloring.color(ofEdgeAt: $0) }",
        f"#expect(colors == {arr(exp)})",
        f"#expect(coloring.colorCount == {k})",
        "// Proper, checked here: the edges at each vertex have different colours.",
        "for v in 0 ..< n {",
        "    let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { colors[$0] }",
        "    #expect(Set(at).count == at.count, \"at \\(vertexList[v]): \\(at)\")",
        "}",
        "#expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })",
        "// Colours 0..<colorCount, each used; class c is the positions of colour c, ascending.",
        "#expect(Set(colors) == Set(0 ..< coloring.colorCount))",
        "#expect(coloring.colorClasses.map { Array($0) } == (0 ..< coloring.colorCount).map { c in colors.indices.filter { colors[$0] == c } })",
        "// Δ counts edge ends (parallel edges each).",
        "let maxDegree = (0 ..< n).map { v in ends.reduce(0) { $0 + ($1.0 == v ? 1 : 0) + ($1.1 == v ? 1 : 0) } }.max() ?? 0",
    ]
    if exact_delta:
        L += ["// König: exactly Δ colours.", "#expect(coloring.colorCount == maxDegree)"]
    else:
        L += ["// Vizing: Δ ≤ colours ≤ Δ + 1.", "#expect(coloring.colorCount >= maxDegree && coloring.colorCount <= maxDegree + 1)"]
    return L


def body_edge(cid, g, T):
    col = ref.misra_gries_model(g)
    assert ref.fmt_col(col) == CELLS[cid][5], cid
    L = ["let coloring = graph.edgeColoring()"] + edge_checks(col, ref.ncolors(col), False)
    if g.kind != "multigraph" and not any(g.loop) and nx.is_bipartite(g.nx()) and len(g.E):
        b = ref.bipartite_edge_coloring_model(g)
        L += ["// On a bipartite graph König's colouring has exactly Δ.",
              f"#expect(graph.bipartiteEdgeColoring()?.colorCount == {ref.ncolors(b)})"]
    return L


def body_bip(cid, g, T):
    col = ref.bipartite_edge_coloring_model(g)
    if col is None:
        assert CELLS[cid][5] == "nil"
        return ["#expect(graph.bipartiteEdgeColoring() == nil)",
                "// Not bipartite: an odd cycle (a self-loop is one of length 1).",
                "#expect(graph.bipartition() == nil)",
                "#expect(graph.findOddCycle() != nil)"]
    assert ref.fmt_col(col) == CELLS[cid][5], cid
    L = ["let coloring = try #require(graph.bipartiteEdgeColoring())"] + edge_checks(col, ref.ncolors(col), True)
    L += ["#expect(graph.bipartition() != nil)"]
    return L


def body_is(cid, g, T, colvec):
    got = ref.proper(g, colvec)
    assert lit(got) == CELLS[cid][5]
    return [f"let given = {arr(colvec) if colvec else '[] as [Int]'}",
            "// The definition, written out: no edge but a self-loop has ends of one colour.",
            "let proper = ends.allSatisfy { $0.0 == $0.1 || given[$0.0] != given[$0.1] }",
            f"#expect(proper == {lit(got)})",
            "var calls = 0",
            "let result = graph.isVertexColoring { calls += 1; return given[vertexList.firstIndex(of: $0)!] }",
            "#expect(result == proper)",
            "#expect(calls == n)"]


def body_is_edge(cid, g, T, colvec):
    got = ref.proper_edges(g, colvec)
    assert lit(got) == CELLS[cid][5]
    return [f"let given = {arr(colvec) if colvec else '[] as [Int]'}",
            "// The definition, written out: the edges at each vertex (a self-loop once) have different colours.",
            "let proper = (0 ..< n).allSatisfy { v in",
            "    let at = ends.indices.filter { ends[$0].0 == v || ends[$0].1 == v }.map { given[$0] }",
            "    return Set(at).count == at.count",
            "}",
            f"#expect(proper == {lit(got)})",
            "var calls = 0",
            "let result = graph.isEdgeColoring { calls += 1; return given[$0] }",
            "#expect(result == proper)",
            "#expect(calls == graph.edgeCount)"]


# ---------------------------------------------------------------------------------------------
# Representation bodies: exact values on that representation, and validity
# ---------------------------------------------------------------------------------------------


def rep_body(cid, kind, args, g, T, rep, h):
    gg = h if h is not None else g
    L = ["let vertexList = Array(graph.vertices)", f"#expect(vertexList == {tarr(g.V, T)})"]
    if kind == "any":
        chi = ref.chromatic_number(gg)
        forced, _ = ref.forced_minimum(gg)
        L += ["let n = vertexList.count",
              "let coloring = graph.minimumColoring()",
              "let colors = vertexList.map { coloring.color(of: $0) }",
              f"#expect(coloring.colorCount == {chi})"]
        if rep == "unindexed":
            L += ["#expect((0 ..< n).map { coloring.color(ofIndex: $0) } == colors)"]
        L += ["#expect(graph.isVertexColoring { coloring.color(of: $0) })"] + FIRST_APPEARANCE
        if forced is not None:
            L += [f"#expect(colors == {arr(forced)})"]
        return L
    if kind in ("greedy", "order", "min"):
        if kind == "greedy":
            col = ref.STRATS[args[2]][1](gg)
            L += [f"let coloring = graph.greedyColoring(strategy: .{args[2]})"]
        elif kind == "order":
            col = ref.first_fit(gg, [g.idx[v] for v in args[2]])
            L += [f"let coloring = graph.greedyColoring(order: {tarr(args[2], T)})"]
        else:
            col = ref.minimum_coloring_model(gg)
            L += ["let coloring = graph.lexicographicallyFirstMinimumColoring()"]
        if h is None:
            assert ref.fmt_col(col) == CELLS[cid][5], cid
        L += [f"#expect(vertexList.map {{ coloring.color(of: $0) }} == {arr(col)})",
              f"#expect(coloring.colorCount == {ref.ncolors(col)})"]
        if rep == "unindexed":
            L += [f"#expect((0 ..< {g.n}).map {{ coloring.color(ofIndex: $0) }} == {arr(col)})"]
        L += ["#expect(graph.isVertexColoring { coloring.color(of: $0) })"]
    elif kind == "chi":
        L = [f"#expect(graph.chromaticNumber() == {ref.chromatic_number(gg)})"]
    elif kind in ("edge", "bip_edge"):
        col = ref.misra_gries_model(gg) if kind == "edge" else ref.bipartite_edge_coloring_model(gg)
        call = "graph.edgeColoring()" if kind == "edge" else "graph.bipartiteEdgeColoring()"
        L = []
        if col is None:
            return [f"#expect({call} == nil)"]
        if kind == "edge":
            L += [f"let coloring = {call}"]
        else:
            L += [f"let coloring = try #require({call})"]
        L += [f"#expect(graph.edges.indices.map {{ coloring.color(ofEdgeAt: $0) }} == {arr(col)})",
              f"#expect(coloring.colorCount == {ref.ncolors(col)})"]
        k = ref.ncolors(col)
        classes = [[e for e in range(len(col)) if col[e] == c] for c in range(k)]
        if rep == "am":
            cells = h.cells
            L += ["#expect(coloring.colorClasses.map { $0.map { [$0.source, $0.target] } } == "
                  + ("[" + ", ".join("[" + ", ".join(f"[{cells[e][0]}, {cells[e][1]}]" for e in cl) + "]" for cl in classes) + "]" if classes else "[]") + ")"]
        else:
            L += [f"#expect(coloring.colorClasses.map {{ Array($0) }} == {arr(classes) if classes else '[]'})"]
        L += ["#expect(graph.isEdgeColoring { coloring.color(ofEdgeAt: $0) })"]
    elif kind == "is":
        colvec = args[2]
        got = ref.proper(g, colvec)
        L += [f"let given = {arr(colvec) if colvec else '[] as [Int]'}",
              f"#expect(graph.isVertexColoring {{ given[vertexList.firstIndex(of: $0)!] }} == {lit(got)})"]
    elif kind == "is_edge":
        colvec = args[2]
        got = ref.proper_edges(g, colvec)
        if rep == "am":
            bycell = [None] * len(colvec)
            for e, c in enumerate(colvec):
                bycell[h.posmap[e]] = c
            assert ref.proper_edges(h, bycell) == got
            L = [f"// The catalog's colours moved to the cells' row-major positions.",
                 f"let given = {arr(bycell) if bycell else '[] as [Int]'}",
                 "let cells = Array(graph.edges.indices)",
                 f"#expect(graph.isEdgeColoring {{ given[cells.firstIndex(of: $0)!] }} == {lit(got)})"]
        else:
            L = [f"let given = {arr(colvec) if colvec else '[] as [Int]'}",
                 f"#expect(graph.isEdgeColoring {{ given[$0] }} == {lit(got)})"]
    else:
        raise ValueError(kind)
    return L


# ---------------------------------------------------------------------------------------------
# Emitting
# ---------------------------------------------------------------------------------------------


def indent(lines, n):
    return [(" " * n + l) if l else "" for l in lines]


def emit_test(cid, ttl, body):
    throws = any("try " in l for l in body)
    sig = f"func {fname(cid)}() throws {{" if throws else f"func {fname(cid)}() {{"
    return indent([f'@Test("{ttl}")', sig], 4) + indent(body, 8) + ["    }", ""]


def row_body(cid, kind, args):
    g = args[1]
    T = vtype(g)
    L = [comment_input(cid)] + build_graph(g, "primary", T) + prelude(g, T)
    if kind == "greedy":
        L += body_greedy(cid, g, T, args[2])
    elif kind == "order":
        L += body_order(cid, g, T, args[2])
    elif kind == "chi":
        L += body_chi(cid, g, T)
    elif kind == "min":
        L += body_min(cid, g, T)
    elif kind == "any":
        L += body_any(cid, g, T)
    elif kind == "edge":
        L += body_edge(cid, g, T)
    elif kind == "bip_edge":
        L += body_bip(cid, g, T)
    elif kind == "is":
        L += body_is(cid, g, T, args[2])
    elif kind == "is_edge":
        L += body_is_edge(cid, g, T, args[2])
    else:
        raise ValueError(kind)
    return L


def unused_cleanup(lines):
    """Drop `let` lines whose names nothing else uses (warnings are errors)."""
    changed = True
    while changed:
        changed = False
        code = "\n".join(l for l in lines if not l.strip().startswith("//"))
        out = []
        for l in lines:
            m = re.match(r"\s*let (\w+) = ", l)
            if m:
                name = m.group(1)
                rest = code.replace(l, "", 1)
                if not re.search(r"\b" + name + r"\b", rest):
                    if out and out[-1].strip().startswith("// Edge ends"):
                        out.pop()
                    changed = True
                    continue
            out.append(l)
        lines = out
    return lines


def rep_tests(cid, kind, args):
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
        lines = build_graph(g, rep, T) + rep_body(cid, kind, args, g, T, rep, hh)
        lines = unused_cleanup(lines)
        body += [f"do {{ // {label}"] + indent(lines, 4) + ["}"]
    labels_ = ", ".join(l for (_, l, _) in reps)
    name = CELLS[cid][2]
    return emit_test(cid, esc(f"{cid} {name}, on {labels_}"), body)


P3 = "UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])"
TRAPS = {
    "CO-215": ("UndirectedAdjacencyList<Int>(vertices: [0], edges: [UndirectedEdge(0, 0)])", "_ = graph.edgeColoring()"),
    "CO-216": ("ReferencePseudograph<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 0), UndirectedEdge(1, 2)])", "_ = graph.edgeColoring()"),
    "CO-248": (P3, "_ = graph.greedyColoring(order: [0, 1])"),
    "CO-249": (P3, "_ = graph.greedyColoring(order: [0, 1, 1, 2])"),
    "CO-250": (P3, "_ = graph.greedyColoring(order: [0, 1, 2, 3])"),
    "CO-251": (P3, "_ = graph.greedyColoring().color(of: 9)"),
    "CO-252": (P3, "_ = graph.greedyColoring().color(ofIndex: 3)"),
}


def trap_test(cid):
    parts = CELLS[cid]
    why = re.sub(r"^precondition(: )?", "", parts[6])
    why = why.split(" (")[0]
    graph, call = TRAPS[cid]
    body = [comment_input(cid), "await #expect(processExitsWith: .failure) {", f"    let graph = {graph}"]
    body += indent(call.split("\n"), 4) + ["}"]
    t = f"{cid} {parts[2]}" + (f" ({why})" if why else "") + " traps"
    lines = indent([f'@Test("{esc(t)}")', f"func {fname(cid)}() async {{"], 4)
    return lines + indent(body, 8) + ["    }", ""]


CONFORMER = [
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


def header(comment, imports, suite, struct, tags=None, conformer=False):
    L = [("// " + c) if c else "//" for c in comment]
    L.append("")
    L += [f"import {i}" for i in imports]
    L.append("")
    if conformer:
        L += CONFORMER
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
    out, cur = [], ""
    for w in s.split(" "):
        if cur and len(cur) + 1 + len(w) > width:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w) if cur else w
    if cur:
        out.append(cur)
    return out


def used_imports(lines):
    t = "\n".join(lines)
    out = ["ColoringModule", "GraphProtocols", "Testing"]
    if "UndirectedAdjacencyList" in t or "AdjacencyList<" in t:
        out.append("AdjacencyListModule")
    if "AdjacencyMatrix" in t:
        out.append("AdjacencyMatrixModule")
    if "BipartiteGraph" in t or "bipartition()" in t or "findOddCycle" in t:
        out.append("BipartiteGraphs")
    if "ReferencePseudograph" in t:
        out.append("GrafluentTestSupport")
    return sorted(set(out), key=lambda s: s.lower())


COMMON = ("Graphs are `UndirectedAdjacencyList` built by inserting the row's vertices, then its edges in "
          "order, so rows are in position order (a self-loop twice); `multigraph` rows are "
          "`ReferencePseudograph`, whose rows are in position order too; `L …; R …` and the `Kb`, `crown` and "
          "`lcgb` rows are `BipartiteGraph(left:right:edges:)`. In-test oracles number vertices by their index "
          "in `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's "
          "model; see README.md.")


def greedy_rows(swift):
    return lambda kind, args: kind == "greedy" and args[2] == swift


FILES = [
    ("GreedyLargestFirstTests.swift", greedy_rows("largestFirst"), "greedyColoring(strategy: .largestFirst)", "GreedyLargestFirstTests",
     "`greedyColoring(strategy: .largestFirst)` (catalog §Greedy.largestFirst): Welsh–Powell, first fit in "
     "simple degree descending, the lesser index on ties, NetworkX `largest_first`'s colours; exact; proper, "
     "with every colour used and the classes in `vertices` order (checked here); at most Δ + 1 colours; a "
     "first-fit colouring (a vertex of colour c sees every colour below c); the strategy written out; at least "
     "`chromaticNumber()` colours; the default strategy."),
    ("GreedySmallestLastTests.swift", greedy_rows("smallestLast"), "greedyColoring(strategy: .smallestLast)", "GreedySmallestLastTests",
     "`greedyColoring(strategy: .smallestLast)` (catalog §Greedy.smallestLast): Matula–Beck, first fit in the "
     "reverse of a least-degree removal order, the lesser index on ties; exact; proper (checked here); at most "
     "Δ + 1 and at most degeneracy + 1 colours (the degeneracy computed here); a first-fit colouring; the "
     "strategy written out; at least `chromaticNumber()` colours."),
    ("GreedySaturationLargestFirstTests.swift", greedy_rows("saturationLargestFirst"), "greedyColoring(strategy: .saturationLargestFirst)", "GreedySaturationLargestFirstTests",
     "`greedyColoring(strategy: .saturationLargestFirst)` (catalog §Greedy.saturationLargestFirst): DSatur with "
     "NetworkX's tie rule (saturation, then simple degree in the whole graph, then the lesser index), "
     "NetworkX's colours; exact; proper (checked here); at most Δ + 1 colours; a first-fit colouring; the "
     "strategy written out; at least `chromaticNumber()` colours."),
    ("GreedyIndependentSetTests.swift", greedy_rows("independentSet"), "greedyColoring(strategy: .independentSet)", "GreedyIndependentSetTests",
     "`greedyColoring(strategy: .independentSet)` (catalog §Greedy.independentSet): colour k a maximal "
     "independent set of the uncoloured vertices, least available degree first, the lesser index on ties; "
     "exact; proper (checked here); at most Δ + 1 colours; a first-fit colouring; the strategy written out; "
     "at least `chromaticNumber()` colours."),
    ("GreedyConnectedSequentialTests.swift", lambda kind, args: kind == "greedy" and args[2].startswith("connectedSequential"),
     "greedyColoring(strategy: .connectedSequential…)", "GreedyConnectedSequentialTests",
     "`greedyColoring(strategy: .connectedSequentialBreadthFirst)` and `.connectedSequentialDepthFirst` (catalog "
     "§Greedy.connectedSequential…): first fit in breadth-first or depth-first preorder, components by least "
     "vertex, each from its least vertex, neighbours in row order; exact; proper (checked here); at most Δ + 1 "
     "colours; a first-fit colouring; the search written out; at least `chromaticNumber()` colours."),
    ("GreedyOrderTests.swift", lambda kind, args: kind == "order", "greedyColoring(order:)", "GreedyOrderTests",
     "`greedyColoring(order:)` (catalog §Greedy.order): first fit in the given order (Boost "
     "`sequential_vertex_coloring`, NetworkX with a callable strategy); exact; proper (checked here); at most "
     "Δ + 1 colours; a first-fit colouring; first fit written out; the order as a lazy sequence."),
    ("ChromaticNumberTests.swift", lambda kind, args: kind == "chi", "chromaticNumber()", "ChromaticNumberTests",
     "`chromaticNumber()` (catalog §ChromaticNumber): χ of the simple graph, exact; `minimumColoring()` a proper "
     "colouring with χ colours (checked here) and no greedy strategy below it; the least k with a proper "
     "k-colouring by exhaustive search (vertices by degree, colours at most one above those used); χ ≥ ω, "
     "the clique number by brute force on rows of at most 16 vertices and a clique checked here otherwise; "
     "bipartite exactly when χ ≤ 2 on loop-free rows."),
    ("LexicographicallyFirstMinimumColoringTests.swift", lambda kind, args: kind == "min", "lexicographicallyFirstMinimumColoring()", "LexicographicallyFirstMinimumColoringTests",
     "`lexicographicallyFirstMinimumColoring()` (catalog §LexicographicallyFirstMinimumColoring): on each "
     "component the lexicographically least colour vector with that component's χ colours; exact; proper, "
     "with every colour used and the classes in `vertices` order (checked here); `chromaticNumber()` "
     "colours; classes numbered by least vertex; by exhaustive search per component in index order the "
     "least k and the lexicographically least k-colouring; on bipartite rows the `bipartition()` sides."),
    ("MinimumColoringTests.swift", lambda kind, args: kind == "any", "minimumColoring()", "MinimumColoringTests",
     "`minimumColoring()` (catalog §MinimumColoring, CO-254 – CO-281, the graphs of CO-167 – CO-194): "
     "proper (checked here), χ colours (ref.py's value, and `chromaticNumber()`), every colour used, the "
     "classes in `vertices` order, colours numbered by first appearance; the exact colours where they "
     "are forced (no edges; bipartite, the `bipartition()` sides; the only χ-colouring so numbered)."),
    ("EdgeColoringTests.swift", lambda kind, args: kind == "edge", "edgeColoring()", "EdgeColoringTests",
     "`edgeColoring()` (catalog §EdgeColoring, and CO-253): Misra–Gries in position order as api.md documents "
     "it; exact colours by position; proper (checked here: the edges at each vertex differ); every colour "
     "used; classes ascending; Δ ≤ colours ≤ Δ + 1; and, on bipartite rows, König's Δ beside it."),
    ("BipartiteEdgeColoringTests.swift", lambda kind, args: kind == "bip_edge", "bipartiteEdgeColoring()", "BipartiteEdgeColoringTests",
     "`bipartiteEdgeColoring()` (catalog §BipartiteEdgeColoring): König's alternating-path recolouring in "
     "position order; exact colours by position; proper (checked here), parallel edges included; exactly Δ "
     "colours; nil exactly when the graph has an odd cycle."),
    ("ColoringCheckTests.swift", lambda kind, args: kind in ("is", "is_edge"), "Checks: isVertexColoring, isEdgeColoring", "ColoringCheckTests",
     "`isVertexColoring(_:)` and `isEdgeColoring(_:)` (catalog §Checks) against their definitions, written out here; "
     "the closure called once per vertex, or once per edge."),
]


COUNTS = {}
for fname_, pred, suite, struct, intro in FILES:
    body = []
    count = 0
    for cid, kind, args, kwargs in ROWS:
        if kind != "trap" and pred(kind, args):
            body += emit_test(cid, title(cid), unused_cleanup(row_body(cid, kind, args)))
            count += 1
    if fname_ == "EdgeColoringTests.swift":
        # Written by hand after a planted bug (extra_edge.swift).
        body += open(os.path.join(HERE, "extra_edge.swift")).read().rstrip("\n").split("\n")
    L = header(wrap(intro + " " + COMMON), used_imports(body), suite, struct) + body
    write(fname_, L)
    COUNTS[fname_] = count

# Traps
body = []
for cid, kind, args, kwargs in ROWS:
    if kind == "trap":
        body += trap_test(cid)
EXTRA = open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n")
body += EXTRA
intro = ("Preconditions, as exit tests (catalog CO-215, CO-216, CO-248 – CO-252): `edgeColoring()` on a graph "
         "with a self-loop or parallel edges; an order that misses, repeats or adds a vertex; a colour asked "
         "for a non-vertex or an index out of range. Then the preconditions the catalog does not list: an order "
         "with the right length that repeats one vertex and misses another, or swaps one for a non-vertex; a "
         "negative index; a non-vertex on a graph without vertex indices, to `color(of:)` and in an order; "
         "`minimumColoring().color(of:)`; `edgeColoring()` on parallel arcs through `AdjacencyList.undirected`, "
         "on `graph.directed.undirected`, and on a self-loop away from the first vertex; `color(ofEdgeAt:)` with a "
         "position the graph does not have, with and without edge indices; a negative preset colour and two "
         "adjacent vertices preset alike. Each exit test builds "
         "its inputs inside the closure. Generated from cases.md by swiftgen.py, the tests after CO-252 written "
         "by hand (extra_traps.swift); see README.md.")
L = header(wrap(intro), sorted(set(used_imports(body)) | {"AdjacencyListModule", "GrafluentTestSupport"}, key=str.lower),
           "Coloring preconditions", "ColoringPreconditionTests", tags=".precondition", conformer=True) + body
write("ColoringPreconditionTests.swift", L)
COUNTS["ColoringPreconditionTests.swift"] = sum(1 for l in body if l.strip().startswith("@Test("))

# Representations
body = []
rep_count = 0
for cid, kind, args, kwargs in ROWS:
    if kind == "trap":
        continue
    body += rep_tests(cid, kind, args)
    rep_count += 1
intro = ("The catalog's rows again on other representations. Rows on `UndirectedAdjacencyList` run again on "
         "`ReferencePseudograph`; `BipartiteGraph` rows on an `UndirectedAdjacencyList` and a "
         "`ReferencePseudograph` with the same vertices and edges; every row on a file-private conformer with no "
         "vertex or edge indices; all with the catalog's values, since their rows are in position order too. Then "
         "on `AdjacencyList.undirected` with each edge an arc as written (rows with no arc twice), and on "
         "`AdjacencyMatrix.undirected` with the arcs at their row-major cells (rows on 0..<n with no arc twice). "
         "Through `.undirected` a row is successors, then predecessors, and matrix positions are cells, so the "
         "connected-sequential colourings (which follow rows) and the edge colourings (which follow positions) "
         "there were computed by swiftgen.py with ref.py's models on those rows and positions; the other vertex "
         "colourings depend only on vertex order and adjacency and are the catalog's. Matrix positions are "
         "compared as [source, target]. See README.md.")
L = header(wrap(intro), sorted(set(used_imports(body)) | {"AdjacencyMatrixModule", "AdjacencyListModule"}, key=str.lower),
           "Catalog rows on every representation", "ColoringRepresentationTests", conformer=True) + body
write("ColoringRepresentationTests.swift", L)
COUNTS["ColoringRepresentationTests.swift"] = rep_count

for k, v in COUNTS.items():
    print(f"{k}: {v}")
print("total", sum(COUNTS.values()))
