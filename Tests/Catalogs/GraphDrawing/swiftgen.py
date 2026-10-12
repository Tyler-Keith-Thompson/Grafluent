"""Writes the catalog-row test files of Tests/GraphDrawingTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with numpy==2.3.4 \
        --with scipy==1.18.1 python3 Tests/Catalogs/GraphDrawing/swiftgen.py [--phase2] [OUT_DIR]
    # default OUT_DIR: Tests/GraphDrawingTests

First checks that ref.py's model reproduces cases.md byte for byte. Then re-runs every phase-1 row
on the model, asserts that the value it computes formats to the catalog cell, and writes one @Test
per row. Exact rows compare whole point lists with ==; rows printed to 12 decimals (cos and sin)
compare within 1e-9; quality rows take the median over seeds 1…20 and compare it with the bound,
computing normalized stress and straight-line crossings inline from `positions`. A Sugiyama row
whose optimal layering is unique checks the model's whole layered drawing (layers, layer count,
crossing count, positions, the bends of every edge, reversed edges, and `feedbackArcSet()`), not
only its own cell. `--phase2` also writes GraphDrawingPhase2Tests.swift (DR-207 – DR-214), which
needs `spectralLayout()`, `bfsLayout(start:)`, `multipartiteLayout(layer:)`, `forceAtlas2Layout`
and SpectralGraphTheory's `fiedlerVector()`. Hand-written exit tests spliced into the precondition
file: extra_traps.swift.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

PHASE2 = "--phase2" in sys.argv
ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
OUT = os.path.abspath(ARGS[0]) if ARGS else os.path.join(HERE, "..", "..", "GraphDrawingTests")

# ---------------------------------------------------------------------------------------------
# Catalog check
# ---------------------------------------------------------------------------------------------
ref.drawing_rows()
ref.circular_rows()
ref.tree_rows()
ref.sugiyama_rows()
ref.fr_rows()
ref.stress_rows()
ref.phase2_rows()
ref.number_rows()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| DR-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 214
PHASE1 = range(1, 207)
assert all(CELLS[n][1] == "Phase 2" for n in range(207, 215))
assert all(CELLS[n][1] != "Phase 2" for n in PHASE1)


def group(n): return CELLS[n][1]
def title(n): return CELLS[n][2]
def inp(n): return CELLS[n][3].strip("`")
def op(n): return CELLS[n][4].strip("`")
def cell(n): return CELLS[n][5]
def is_trap(n): return cell(n) == "**trap**"


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def d(x):
    """A Swift Double literal that parses to exactly x."""
    x = float(x)
    if x == 0:
        return "0.0" if math.copysign(1, x) > 0 else "-0.0"
    r = repr(x)
    return r if ("." in r or "e" in r or "inf" in r or "nan" in r) else r + ".0"


def pt(p): return "SIMD2(%s, %s)" % (d(p[0]), d(p[1]))
def pts(ps): return "[" + ", ".join(pt(p) for p in ps) + "]" if ps else "[] as [SIMD2<Double>]"
def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "]" if xs else "[] as [Int]"


def opt_ints(xs): return "[" + ", ".join("nil" if x is None else str(x) for x in xs) + "]"


def wrap(prefix, items, ind, close="]"):
    """prefix + items joined, wrapped at about 150 columns."""
    out, line = [], ind + prefix
    for i, it in enumerate(items):
        piece = it + (", " if i < len(items) - 1 else close)
        if len(line) + len(piece) > 150 and line.strip() != prefix.strip():
            out.append(line.rstrip())
            line = ind + "    "
        line += piece
    if not items:
        line += close
    out.append(line)
    return out


def undirected_graph(g, ind, var="graph"):
    if not g.edges:
        return [ind + "let %s = Pseudograph<Int>(vertices: 0 ..< %d, edges: [] as [UndirectedEdge<Int>])" % (var, g.n)]
    return wrap("let %s = Pseudograph<Int>(vertices: 0 ..< %d, edges: [" % (var, g.n),
                ["UndirectedEdge(%d, %d)" % e for e in g.edges], ind, "])")


def directed_edges(g):
    return ["DirectedEdge(from: %d, to: %d)" % e for e in g.edges]


def directed_graph(g, ind, var="graph"):
    if not g.edges:
        return [ind + "let %s = DirectedPseudograph<Int>(vertices: 0 ..< %d, edges: [] as [DirectedEdge<Int>])" % (var, g.n)]
    return wrap("let %s = DirectedPseudograph<Int>(vertices: 0 ..< %d, edges: [" % (var, g.n), directed_edges(g), ind, "])")


def graph_shape(g, ind, var="graph"):
    return [ind + "#expect(Array(%s.vertices) == Array(0 ..< %d) && %s.edgeCount == %d)" % (var, g.n, var, len(g.edges))]


def tree_lines(par, ind):
    return wrap("let tree = try #require(RootedTree(parents: [", [("nil" if p is None else str(p)) for p in par], ind, "]))") + [
        ind + "#expect(Array(tree.vertices) == Array(0 ..< %d))" % len(par)]


def close_lines(expr, ps, ind, tol="1e-9"):
    out = wrap("let expected: [SIMD2<Double>] = [", [pt(p) for p in ps], ind, "]") if ps else [ind + "let expected: [SIMD2<Double>] = []"]
    out.append(ind + "let got = %s" % expr)
    out.append(ind + "#expect(got.count == expected.count)")
    out.append(ind + "for (a, b) in zip(got, expected) {")
    out.append(ind + "    #expect(abs(a.x - b.x) <= %s && abs(a.y - b.y) <= %s, \"\\(a) vs \\(b)\")" % (tol, tol))
    out.append(ind + "}")
    return out


def exact_lines(expr, ps, ind):
    return wrap("#expect(%s == [" % expr, [pt(p) for p in ps], ind, "])") if ps else [ind + "#expect(%s == [] as [SIMD2<Double>])" % expr]


def header(n, extra=""):
    return ['    @Test("DR-%03d %s"%s)' % (n, title(n).replace('"', '\\"'), extra)]


def fmt_pts(ps, digits=None): return ref.pts(ps, digits)


# ---------------------------------------------------------------------------------------------
# Drawing (DR-001 – DR-021)
# ---------------------------------------------------------------------------------------------
TWO = "var drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])"
TWO_LET = TWO.replace("var ", "let ", 1)


def drawing_test(n):
    L = header(n) + ["    func dr%03d() {" % n, "        // %s → %s" % (inp(n) + "; " + op(n), cell(n))]
    b = []
    o = op(n)
    if n == 1:
        b += ["let drawing = Drawing<Int>()", "#expect(drawing.count == 0 && drawing.isEmpty)",
              "#expect(drawing.vertices.isEmpty && drawing.positions.isEmpty)", "#expect(drawing.startIndex == drawing.endIndex)"]
    elif n == 2:
        b += ["let drawing = Drawing<Int>()", "#expect(drawing.boundingBox == nil)"]
    elif n == 3:
        b += ["let drawing = Drawing<Int>()", "let rescaled = drawing.rescaled()",
              "#expect(rescaled.isEmpty && rescaled == drawing)", "var copy = drawing", "copy.rescale()", "#expect(copy == drawing)"]
    elif n == 4:
        b += [TWO_LET, "#expect(drawing.positions == [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])",
              "#expect(Array(drawing.vertices) == [5, 3] && drawing.count == 2)"]
    elif n == 5:
        b += [TWO_LET, "let position = drawing.position(of: 3)", "#expect(position == SIMD2(2.0, 1.0))",
              "let other = drawing.position(of: 5)", "#expect(other == SIMD2(0.0, 0.0))"]
    elif n == 6:
        b += [TWO, "drawing.setPosition(SIMD2(7.0, -1.0), of: 5)", "#expect(drawing.positions == [SIMD2(7.0, -1.0), SIMD2(2.0, 1.0)])",
              "#expect(Array(drawing.vertices) == [5, 3])", "let written = drawing.position(of: 5)", "#expect(written == SIMD2(7.0, -1.0))"]
    elif n == 8:
        b += [TWO_LET, "#expect(throws: VertexNotFound.self) { try drawing.position(checked: 4) }",
              "#expect(throws: VertexNotFound.self) { try drawing.position(checked: 0) }",
              "#expect(throws: VertexNotFound.self) { try drawing.position(checked: 1) }"]
    elif n == 9:
        b += [TWO_LET, "#expect(try drawing.position(checked: 5) == SIMD2(0.0, 0.0))", "#expect(try drawing.position(checked: 3) == SIMD2(2.0, 1.0))"]
    elif n == 12:
        b += [TWO_LET, "let elements = Array(drawing)", "#expect(elements.map(\\.vertex) == [5, 3])",
              "#expect(elements.map(\\.position) == [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])",
              "var visited: [Int] = []", "for (vertex, position) in drawing {", "    visited.append(vertex)",
              "    #expect(try drawing.position(checked: vertex) == position)", "}", "#expect(visited == [5, 3])"]
    elif n == 13:
        b += [TWO_LET, "let reordered = Drawing(vertices: [3, 5], positions: [SIMD2(2.0, 1.0), SIMD2(0.0, 0.0)])",
              "#expect(drawing != reordered)", "#expect(try drawing.position(checked: 3) == reordered.position(checked: 3) && drawing.position(checked: 5) == reordered.position(checked: 5))",
              "let same = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])",
              "#expect(drawing == same && drawing.hashValue == same.hashValue)"]
    elif n == 14:
        b += [TWO_LET, "let box = try #require(drawing.boundingBox)", "#expect(box.min == SIMD2(0.0, 0.0) && box.max == SIMD2(2.0, 1.0))"]
    elif 15 <= n <= 21:
        import re
        m = re.match(r"Drawing\(vertices: (\[[^\]]*\]), positions: (\[.*\])\)$", inp(n))
        vs = eval(m.group(1))
        ps = eval(m.group(2))
        m2 = re.match(r"rescaled\(scale: ([-0-9.]+), center: \(([-0-9.]+), ([-0-9.]+)\)\)$", o)
        scale, cx, cy = float(m2.group(1)), float(m2.group(2)), float(m2.group(3))
        got = ref.rescaled(ps, scale, (cx, cy))
        assert fmt_pts(got) == cell(n), n
        b += wrap("let drawing = Drawing(vertices: %s, positions: [" % ints(vs), [pt(p) for p in ps], "", "])")
        b += ["let rescaled = drawing.rescaled(scale: %s, center: SIMD2(%s, %s))" % (d(scale), d(cx), d(cy))]
        b += exact_lines("rescaled.positions", got, "")
        b += ["#expect(rescaled.vertices == drawing.vertices)",
              "var copy = drawing", "copy.rescale(scale: %s, center: SIMD2(%s, %s))" % (d(scale), d(cx), d(cy)),
              "#expect(copy == rescaled)"]
    else:
        raise AssertionError(n)
    throws = any("try " in x and not x.startswith("#expect(throws:") for x in b)
    if throws:
        L[1] = L[1].replace("() {", "() throws {")
    return L + ["        " + x if x else "" for x in b] + ["    }"]


# ---------------------------------------------------------------------------------------------
# Circular (DR-022 – DR-030)
# ---------------------------------------------------------------------------------------------

def circular_test(n):
    import re
    spec = inp(n)
    g = ref.parse(spec)
    o = op(n)
    radius, center = 1.0, (0.0, 0.0)
    m = re.search(r"radius: ([-0-9.]+)", o)
    if m:
        radius = float(m.group(1))
    m = re.search(r"center: \(([-0-9.]+), ([-0-9.]+)\)", o)
    if m:
        center = (float(m.group(1)), float(m.group(2)))
    got = ref.circular(g.n, radius, center)
    assert fmt_pts(got, 12) == cell(n), n
    L = header(n) + ["    func dr%03d() {" % n, "        // %s; %s → %s" % (spec, o, cell(n))]
    b = []
    args = []
    if radius != 1.0:
        args.append("radius: %s" % d(radius))
    if center != (0.0, 0.0):
        args.append("center: SIMD2(%s, %s)" % (d(center[0]), d(center[1])))
    call = "circularLayout(%s)" % ", ".join(args)
    if g.directed:
        b += directed_graph(g, "") + graph_shape(g, "")
        b += ["let layout = graph.undirected.%s" % call]
    else:
        b += undirected_graph(g, "") + graph_shape(g, "")
        b += ["let layout = graph.%s" % call]
    b += ["#expect(Array(layout.vertices) == Array(0 ..< %d))" % g.n]
    b += close_lines("layout.positions", got, "")
    if g.n >= 1:
        b += ["// Every vertex at distance radius from the centre (the one vertex of n = 1 at the centre).",
              "for p in layout.positions {",
              "    let r = ((p - SIMD2(%s, %s)) * (p - SIMD2(%s, %s))).sum().squareRoot()" % (d(center[0]), d(center[1]), d(center[0]), d(center[1])),
              "    #expect(abs(r - %s) <= 1e-9)" % (d(0.0) if g.n == 1 else d(radius)), "}"]
    return L + ["        " + x if x else "" for x in b] + ["    }"]


# ---------------------------------------------------------------------------------------------
# Trees (DR-033 – DR-063)
# ---------------------------------------------------------------------------------------------

def tree_test(n):
    spec = inp(n)
    par = ref.parse_tree(spec)
    L = header(n) + ["    func dr%03d() throws {" % n, "        // %s; %s → %s" % (spec, op(n), cell(n) if len(cell(n)) < 400 else cell(n)[:200] + " …")]
    b = tree_lines(par, "")
    if n == 57:
        pos = ref.reingold_tilford(par)
        root, ch = ref.tree_children(par)

        def pre(v):
            out = [v]
            for c in ch[v]:
                out += pre(c)
            return out
        a, c2 = pre(1), pre(2)
        assert [pos[x][0] - pos[1][0] for x in a] == [pos[x][0] - pos[2][0] for x in c2]
        b += ["let layout = tree.reingoldTilfordLayout()",
              "// The subtrees of 1 and 2, each with its root.",
              "let left = %s, right = %s" % (ints(sorted(a)), ints(sorted(c2))),
              "#expect(left.allSatisfy { $0 == 1 || tree.isAncestor(1, of: $0) } && right.allSatisfy { $0 == 2 || tree.isAncestor(2, of: $0) })",
              "let p1 = layout.position(of: 1), p2 = layout.position(of: 2)",
              "// As point sets: the order of `descendants(of:)` is not what is pinned.",
              "let leftOffsets = try left.map { try layout.position(checked: $0) - p1 }.sorted { ($0.y, $0.x) < ($1.y, $1.x) }",
              "let rightOffsets = try right.map { try layout.position(checked: $0) - p2 }.sorted { ($0.y, $0.x) < ($1.y, $1.x) }",
              "#expect(leftOffsets == rightOffsets && leftOffsets.count == 7)",
              "// The two subtrees do not overlap: every x of the left one is left of every x of the right one at its depth.",
              "#expect(try left.map { try layout.position(checked: $0).x }.max()! < right.map { try layout.position(checked: $0).x }.min()!)"]
        return L + ["        " + x if x else "" for x in b] + ["    }"]
    circular = "Circular" in op(n)
    if circular:
        got = ref.rt_circular(par)
        assert fmt_pts(got, 12) == cell(n), n
        b += ["let layout = tree.reingoldTilfordCircularLayout()", "#expect(Array(layout.vertices) == Array(0 ..< %d))" % len(par)]
        b += close_lines("layout.positions", got, "")
        b += ["// The radius of each vertex is its depth.", "for v in tree.vertices {",
              "    let p = try layout.position(checked: v)",
              "    #expect(abs((p * p).sum().squareRoot() - Double(tree.depth(of: v))) <= 1e-9)", "}"]
    else:
        got = ref.reingold_tilford(par)
        assert fmt_pts(got) == cell(n), n
        b += ["let layout = tree.reingoldTilfordLayout()", "#expect(Array(layout.vertices) == Array(0 ..< %d))" % len(par)]
        b += exact_lines("layout.positions", got, "")
    return L + ["        " + x if x else "" for x in b] + ["    }"]


# ---------------------------------------------------------------------------------------------
# Layered (DR-064 – DR-163)
# ---------------------------------------------------------------------------------------------

def layered_state(g, res, ind, var="layered"):
    out = []
    n = g.n
    out.append(ind + "#expect(Array(%s.drawing.vertices) == Array(0 ..< %d))" % (var, n))
    out.append(ind + "#expect(graph.vertices.map { %s.layer(of: $0) } == %s)" % (var, ints(res["layer"])))
    out.append(ind + "#expect(%s.layerCount == %d)" % (var, res["layers"]))
    out.append(ind + "#expect(%s.crossingCount == %d)" % (var, res["crossings"]))
    out += exact_lines("%s.drawing.positions" % var, res["pos"], ind)
    out.append(ind + "#expect(%s.reversedEdges == %s)" % (var, ints(res["reversed"])))
    if g.edges:
        bends = res["bends"]
        out += wrap("let bends: [[SIMD2<Double>]] = [", [pts(bs) for bs in bends], ind, "]")
        out.append(ind + "#expect(graph.edges.indices.map { Array(%s.bends(ofEdgeAt: $0)) } == bends)" % var)
    return out


def span_of(g, layer):
    return sum(abs(layer[v] - layer[u]) for u, v in g.edges if u != v)


def fas(g, reversed_edges):
    """feedbackArcSet(): the reversed edges and every self-loop, by position (igraph includes loops)."""
    return sorted(set(reversed_edges) | {e for e, (u, v) in enumerate(g.edges) if u == v})


def layered_test(n):
    import re
    spec, o = inp(n), op(n)
    L = header(n)
    b = []
    if n == 163:
        g = ref.parse("D: lcgdag(15,25,2)")
        res = ref.sugiyama(g.n, g.edges)
        assert res["layer"] is None and res["reversed"] == [] and cell(n) == "[]"
        L += ["    func dr%03d() throws {" % n, "        // %s; %s → %s" % (spec, o, cell(n))]
        b += wrap("let graph = try #require(DirectedAcyclicGraph<DirectedPseudograph<Int>>(vertices: 0 ..< %d, edges: [" % g.n,
                  directed_edges(g), "", "]))")
        b += graph_shape(g, "")
        b += ["let layered = graph.sugiyamaLayout()", "#expect(layered.reversedEdges == [] as [Int])",
              "#expect(graph.feedbackArcSet() == [] as [Int])",
              "// The same layering as on the plain pseudograph: the total span is the catalog's optimum (DR-152).",
              "#expect(graph.edges.indices.map { layered.layer(of: graph.target(ofEdgeAt: $0)) - layered.layer(of: graph.source(ofEdgeAt: $0)) }.reduce(0, +) == %d)" % res["span"],
              "#expect(graph.edges.indices.allSatisfy { layered.layer(of: graph.target(ofEdgeAt: $0)) > layered.layer(of: graph.source(ofEdgeAt: $0)) })"]
        return L + ["        " + x if x else "" for x in b] + ["    }"]
    g = ref.parse(spec)
    layers, maxit = None, 100
    m = re.search(r"layers: (\[[^\]]*\])", o)
    if m:
        layers = eval(m.group(1))
    m = re.search(r"maxIterations: (\d+)", o)
    if m:
        maxit = int(m.group(1))
    res = ref.sugiyama(g.n, g.edges, layers=layers, max_iterations=maxit)
    L += ["    func dr%03d() {" % n, "        // %s; %s → %s" % (spec, o, cell(n))]
    b += directed_graph(g, "") + graph_shape(g, "")
    args = []
    if layers is not None:
        args.append("layers: { %s[$0] }" % ints(layers))
    if maxit != 100:
        args.append("maxIterations: %d" % maxit)
    b.append("let layered = graph.sugiyamaLayout(%s)" % ", ".join(args))
    ex = cell(n)
    if res["layer"] is None:
        # DR-152: only the total span is pinned.
        assert ex == "#%d" % res["span"]
        b += ["// The optimal layering is not unique: the total span is pinned, and the layered drawing's invariants.",
              "let spans = graph.edges.indices.map { layered.layer(of: graph.target(ofEdgeAt: $0)) - layered.layer(of: graph.source(ofEdgeAt: $0)) }",
              "#expect(spans.reduce(0, +) == %d)" % res["span"],
              "#expect(spans.allSatisfy { $0 >= 1 })",
              "#expect(layered.reversedEdges == [] as [Int] && graph.feedbackArcSet() == %s)" % ints(fas(g, [])),
              "#expect(graph.vertices.map { layered.layer(of: $0) }.min() == 0)",
              "#expect(layered.layerCount == graph.vertices.map { layered.layer(of: $0) }.max()! + 1)",
              "for p in graph.edges.indices {",
              "    let bends = Array(layered.bends(ofEdgeAt: p))",
              "    let from = layered.layer(of: graph.source(ofEdgeAt: p))",
              "    #expect(bends.map(\\.y) == (0 ..< bends.count).map { Double(from + 1 + $0) })",
              "    #expect(bends.count == spans[p] - 1)",
              "}"]
        return L + ["        " + x if x else "" for x in b] + ["    }"]
    # Check the cell against the model, then write out the whole state.
    if "reversedEdges" in o:
        assert ex == str(res["reversed"]), n
        if layers is None:
            b.append("#expect(graph.feedbackArcSet() == %s)" % ints(fas(g, res["reversed"])))
    elif "layer(of:)" in o:
        assert ex == str(res["layer"]), n
    elif "crossingCount" in o:
        assert ex == "#%d" % res["crossings"], n
    elif "bends(ofEdgeAt: 0)" in o:
        assert ex == fmt_pts(res["bends"][0]), n
    elif "bends" in o:
        assert ex == "; ".join(f"{e}: {fmt_pts(bs)}" for e, bs in enumerate(res["bends"]) if bs), n
    elif "positions" in o:
        assert ex == fmt_pts(res["pos"]), n
    else:
        raise AssertionError(n)
    if layers is None and "reversedEdges" not in o:
        b.append("#expect(graph.feedbackArcSet() == %s)" % ints(fas(g, res["reversed"])))
    b += layered_state(g, res, "")
    return L + ["        " + x if x else "" for x in b] + ["    }"]


# ---------------------------------------------------------------------------------------------
# Quality measures, written inline into each quality test
# ---------------------------------------------------------------------------------------------

def hop_lines(ind):
    return [ind + x for x in [
        "// Hop distances by breadth-first search (loops ignored); -1 between components.",
        "let n = graph.vertexCount",
        "var adjacency = [[Int]](repeating: [], count: n)",
        "for edge in graph.edges where edge.u != edge.v {",
        "    adjacency[edge.u].append(edge.v)",
        "    adjacency[edge.v].append(edge.u)",
        "}",
        "var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)",
        "for s in 0 ..< n {",
        "    hops[s][s] = 0",
        "    var queue = [s]",
        "    var head = 0",
        "    while head < queue.count {",
        "        let v = queue[head]",
        "        head += 1",
        "        for w in adjacency[v] where hops[s][w] < 0 {",
        "            hops[s][w] = hops[s][v] + 1",
        "            queue.append(w)",
        "        }",
        "    }",
        "}",
    ]]


def normalized_lines(ind):
    return [ind + x for x in [
        "// Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).",
        "func normalizedStress(_ p: [SIMD2<Double>]) -> Double {",
        "    var a = 0.0, b = 0.0, c = 0.0",
        "    for i in 0 ..< n {",
        "        for j in i + 1 ..< n where hops[i][j] > 0 {",
        "            let dij = Double(hops[i][j])",
        "            let w = 1 / (dij * dij)",
        "            let delta = p[i] - p[j]",
        "            let e = (delta * delta).sum().squareRoot()",
        "            a += w * dij * e",
        "            b += w * dij * dij",
        "            c += w * e * e",
        "        }",
        "    }",
        "    return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)",
        "}",
    ]]


def crossing_lines(ind):
    return [ind + x for x in [
        "// Pairs of non-loop edges with four distinct endpoints whose segments cross properly.",
        "func crossings(_ p: [SIMD2<Double>]) -> Int {",
        "    let segments = graph.edges.filter { $0.u != $0.v }.map { ($0.u, $0.v) }",
        "    func orientation(_ a: SIMD2<Double>, _ b: SIMD2<Double>, _ c: SIMD2<Double>) -> Int {",
        "        let v = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)",
        "        return abs(v) < 1e-12 ? 0 : (v > 0 ? 1 : -1)",
        "    }",
        "    var total = 0",
        "    for i in 0 ..< segments.count {",
        "        for j in i + 1 ..< segments.count {",
        "            let (a, b) = segments[i], (c, e) = segments[j]",
        "            if Set([a, b, c, e]).count < 4 { continue }",
        "            if orientation(p[a], p[b], p[c]) * orientation(p[a], p[b], p[e]) < 0",
        "                && orientation(p[c], p[e], p[a]) * orientation(p[c], p[e], p[b]) < 0 {",
        "                total += 1",
        "            }",
        "        }",
        "    }",
        "    return total",
        "}",
    ]]


# ---------------------------------------------------------------------------------------------
# Fruchterman–Reingold (DR-166 – DR-188)
# ---------------------------------------------------------------------------------------------

def fr_test(n):
    import re
    spec, o, ex = inp(n), op(n), cell(n)
    g = ref.parse(spec)
    L = header(n, ", .tags(.randomized)" if "≤" in ex or n in (172, 186, 187, 188) else "")
    L += ["    func dr%03d() {" % n, "        // %s; %s → %s" % (spec, o, ex)]
    b = undirected_graph(g, "") + graph_shape(g, "")
    if n in (166, 168, 171):
        seed = int(re.search(r"seed: (\d+)", o).group(1))
        p, draws = ref.initial_random(g.n, seed)
        assert ex == fmt_pts(p)
        if n == 171:
            b += ["var generator = Xoshiro256StarStar(seed: %d)" % seed, "let layout = graph.fruchtermanReingoldLayout(using: &generator)"]
        else:
            b += ["var generator = Xoshiro256StarStar(seed: %d)" % seed,
                  "let layout = graph.fruchtermanReingoldLayout(iterations: 0, using: &generator)"]
        b += ["#expect(Array(layout.vertices) == Array(0 ..< %d))" % g.n]
        b += exact_lines("layout.positions", p, "")
        b += ["// Exactly 2n draws: the generator is where a fresh one is after %d draws." % draws,
              "var fresh = Xoshiro256StarStar(seed: %d)" % seed, "for _ in 0 ..< %d { _ = fresh.next() }" % draws,
              "#expect(generator == fresh)",
              "// The same start through the stepper, and through `initial:` with no iterations.",
              "var again = Xoshiro256StarStar(seed: %d)" % seed,
              "let stepper = FruchtermanReingoldLayout(graph, iterations: 0, using: &again)",
              "#expect(stepper.drawing.positions == %s && stepper.isFinished && stepper.iteration == 0)" % ("layout.positions" if n != 171 else pts(p)),
              "#expect(graph.fruchtermanReingoldLayout(initial: stepper.drawing, iterations: 0) == stepper.drawing)"]
    elif n in (167, 169):
        seed = int(re.search(r"seed: (\d+)", o).group(1))
        _, draws = ref.initial_random(g.n, seed)
        assert ex == "#%d" % draws
        b += ["struct Counting: RandomNumberGenerator {", "    var base: Xoshiro256StarStar", "    var draws = 0",
              "    mutating func next() -> UInt64 {", "        draws += 1", "        return base.next()", "    }", "}",
              "var generator = Counting(base: Xoshiro256StarStar(seed: %d))" % seed,
              "_ = graph.fruchtermanReingoldLayout(using: &generator)",
              "#expect(generator.draws == %d)" % draws,
              "var stepperGenerator = Counting(base: Xoshiro256StarStar(seed: %d))" % seed,
              "var stepper = FruchtermanReingoldLayout(graph, using: &stepperGenerator)",
              "#expect(stepperGenerator.draws == %d)" % draws, "stepper.run()",
              "#expect(stepperGenerator.draws == %d)" % draws]
    elif n == 170:
        b += ["struct Counting: RandomNumberGenerator {", "    var base: Xoshiro256StarStar", "    var draws = 0",
              "    mutating func next() -> UInt64 {", "        draws += 1", "        return base.next()", "    }", "}",
              "var generator = Counting(base: Xoshiro256StarStar(seed: 1))",
              "let layout = graph.fruchtermanReingoldLayout(using: &generator)",
              "#expect(layout.isEmpty && layout == Drawing<Int>() && generator.draws == 0)",
              "var stepper = FruchtermanReingoldLayout(graph, using: &generator)", "stepper.run()",
              "#expect(stepper.drawing.isEmpty && stepper.isFinished && generator.draws == 0)"]
    elif n == 172:
        b += ["var first = Xoshiro256StarStar(seed: 9), second = Xoshiro256StarStar(seed: 9)",
              "let a = graph.fruchtermanReingoldLayout(using: &first)", "let b = graph.fruchtermanReingoldLayout(using: &second)",
              "#expect(a == b && first == second)",
              "#expect(a.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite })",
              "var third = Xoshiro256StarStar(seed: 9)", "var stepper = FruchtermanReingoldLayout(graph, using: &third)", "stepper.run()",
              "#expect(stepper.drawing == a)"]
    elif n == 174:
        b += ["var generator = Xoshiro256StarStar(seed: 1)",
              "var layout = FruchtermanReingoldLayout(graph, iterations: 2, using: &generator)",
              "#expect(!layout.isFinished && layout.iteration == 0)",
              "layout.step()", "let afterOne = layout.drawing", "layout.step()",
              "#expect(layout.isFinished && layout.iteration == 2)", "let afterTwo = layout.drawing",
              "#expect(afterOne != afterTwo)", "let temperature = layout.temperature",
              "layout.step()", "#expect(layout.drawing == afterTwo && layout.iteration == 2 && layout.temperature == temperature)",
              "layout.run()", "#expect(layout.drawing == afterTwo && layout.isFinished)"]
    elif n == 175:
        b += ["var generator = Xoshiro256StarStar(seed: 1)",
              "var layout = FruchtermanReingoldLayout(graph, iterations: 50, using: &generator)",
              "var temperatures = [layout.temperature]", "var steps = 0",
              "while !layout.isFinished {", "    layout.step()", "    steps += 1", "    temperatures.append(layout.temperature)", "}",
              "#expect(layout.iteration <= 50 && layout.iteration == steps && layout.iteration >= 1)",
              "// The temperature falls by the same amount each step (t₀ / (iterations + 1)).",
              "let drop = temperatures[0] - temperatures[1]",
              "#expect(drop > 0 && zip(temperatures, temperatures.dropFirst()).allSatisfy { abs(($0 - $1) - drop) <= 1e-12 })",
              "#expect(abs(drop - temperatures[0] / 51) <= 1e-12)",
              "var again = Xoshiro256StarStar(seed: 1)",
              "#expect(graph.fruchtermanReingoldLayout(iterations: 50, using: &again) == layout.drawing)"]
    elif n == 177:
        p0, _ = ref.initial_random(2, 1)
        b += ["var generator = Xoshiro256StarStar(seed: 1)",
              "let layout = graph.fruchtermanReingoldLayout(iterations: 500, optimalDistance: 1, using: &generator)",
              "let delta = layout.positions[0] - layout.positions[1]",
              "#expect(abs((delta * delta).sum().squareRoot() - 1) <= 1e-3)"]
    elif n in range(178, 184) or n in (186, 187):
        bound = float(ex.split("≤ ")[1])
        bh = "barnesHutTheta" in o
        b += hop_lines("") + normalized_lines("")
        b += ["var values: [Double] = []", "for seed in UInt64(1) ... 20 {", "    var generator = Xoshiro256StarStar(seed: seed)",
              "    let layout = graph.fruchtermanReingoldLayout(%susing: &generator)" % ("barnesHutTheta: 1.2, " if bh else ""),
              "    values.append(normalizedStress(layout.positions))", "}",
              "let sorted = values.sorted()", "let median = (sorted[9] + sorted[10]) / 2",
              "#expect(median <= %s, \"median normalized stress \\(median)\")" % d(bound)]
    elif n in (184, 185):
        bound = int(ex.split("≤ ")[1])
        b += crossing_lines("")
        b += ["var values: [Int] = []", "for seed in UInt64(1) ... 20 {", "    var generator = Xoshiro256StarStar(seed: seed)",
              "    values.append(crossings(graph.fruchtermanReingoldLayout(using: &generator).positions))", "}",
              "let sorted = values.sorted()", "let median = Double(sorted[9] + sorted[10]) / 2",
              "#expect(median <= %d, \"median crossings \\(median)\")" % bound]
    elif n == 188:
        b += ["for seed in UInt64(1) ... 3 {",
              "    var first = Xoshiro256StarStar(seed: seed), second = Xoshiro256StarStar(seed: seed)",
              "    let exact = graph.fruchtermanReingoldLayout(using: &first)",
              "    let tree = graph.fruchtermanReingoldLayout(barnesHutTheta: 0, using: &second)",
              "    #expect(first == second && exact.vertices == tree.vertices)",
              "    for (a, b) in zip(exact.positions, tree.positions) {",
              "        #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, \"\\(a) vs \\(b)\")",
              "    }", "}"]
    else:
        raise AssertionError(n)
    return L + ["        " + x if x else "" for x in b] + ["    }"]


# ---------------------------------------------------------------------------------------------
# Stress majorization (DR-190 – DR-204)
# ---------------------------------------------------------------------------------------------

def raw_stress_lines(ind):
    return [ind + x for x in [
        "// Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².",
        "func rawStress(_ p: [SIMD2<Double>]) -> Double {",
        "    var s = 0.0",
        "    for i in 0 ..< n {",
        "        for j in i + 1 ..< n {",
        "            let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()",
        "            let delta = p[i] - p[j]",
        "            let e = (delta * delta).sum().squareRoot()",
        "            s += (e - dij) * (e - dij) / (dij * dij)",
        "        }",
        "    }",
        "    return s",
        "}",
    ]]


def stress_test(n):
    import re
    spec, o, ex = inp(n), op(n), cell(n)
    g = ref.parse(spec)
    L = header(n) + ["    func dr%03d() {" % n, "        // %s; %s → %s" % (spec, o, ex)]
    b = undirected_graph(g, "") + graph_shape(g, "")
    if n in (190, 191):
        P, s, _ = ref.stress_majorization(g)
        assert ex == f"{fmt_pts([tuple(p) for p in P], 12)}; stress {ref.num(s, 12)}"
        b += ["let layout = graph.stressMajorizationLayout()", "#expect(Array(layout.vertices) == Array(0 ..< %d))" % g.n]
        b += close_lines("layout.positions", [tuple(p) for p in P], "")
        b += ["var stepper = StressMajorizationLayout(graph)", "stepper.run()",
              "#expect(stepper.isFinished && stepper.drawing == layout)", "#expect(abs(stepper.stress) <= 1e-12)"]
    elif n in range(192, 202):
        P, s, _ = ref.stress_majorization(g)
        m = re.match(r"stress ≈ (\S+) \(±1%\)", ex)
        b += ["var stepper = StressMajorizationLayout(graph)", "stepper.run()",
              "let layout = graph.stressMajorizationLayout()",
              "#expect(stepper.isFinished && stepper.drawing == layout)",
              "#expect(Array(layout.vertices) == Array(0 ..< %d))" % g.n]
        if m:
            target = float(m.group(1))
            assert f"{s:.6g}" == m.group(1)
            b.append("#expect(abs(stepper.stress - %s) <= 0.01 * %s, \"stress \\(stepper.stress)\")" % (d(target), d(target)))
        else:
            assert ex.startswith("stress ≤ 0.001")
            b.append("#expect(stepper.stress <= 0.001, \"stress \\(stepper.stress)\")")
        b += hop_lines("") + raw_stress_lines("")
        b += ["// `stress` is the stress of `drawing`, with the target distances rounded to single precision.",
              "#expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-5 * Swift.max(1, stepper.stress))"]
        m2 = re.search(r"normalized ≤ (\S+) ", ex)
        if m2:
            b += normalized_lines("")
            b.append("#expect(normalizedStress(layout.positions) <= %s, \"normalized \\(normalizedStress(layout.positions))\")" % d(float(m2.group(1))))
    elif n == 202:
        b += ["var layout = StressMajorizationLayout(graph)", "var previous = layout.stress", "var steps = 0",
              "#expect(layout.iteration == 0 && !layout.isFinished)",
              "while !layout.isFinished {", "    layout.step()", "    steps += 1",
              "    #expect(layout.stress <= previous * (1 + 1e-12), \"step \\(steps): \\(layout.stress) after \\(previous)\")",
              "    previous = layout.stress", "}",
              "#expect(layout.iteration == steps && steps >= 1 && steps <= 1000)",
              "let finished = layout.drawing", "layout.step()",
              "#expect(layout.drawing == finished && layout.iteration == steps)"]
    elif n == 203:
        b += ["let first = graph.stressMajorizationLayout()", "let second = graph.stressMajorizationLayout()",
              "#expect(first == second)",
              "// The default start is circularLayout(): passing it gives the same drawing.",
              "#expect(graph.stressMajorizationLayout(initial: graph.circularLayout()) == first)",
              "let start = Drawing(vertices: 0 ..< 25, positions: (0 ..< 25).map { SIMD2(Double($0 % 5), Double($0 / 5) * 1.5) })",
              "#expect(graph.stressMajorizationLayout(initial: start) == graph.stressMajorizationLayout(initial: start))",
              "var stepper = StressMajorizationLayout(graph, initial: start, maxIterations: 0)",
              "#expect(stepper.drawing == start)", "stepper.run()", "#expect(stepper.drawing == start && stepper.iteration == 0)"]
    elif n == 204:
        # The default start is circularLayout(radius: L̄), L̄ the mean edge length, and the
        # localized update is homogeneous: with every length 2, each iterate is exactly twice the
        # unit one (every step scales by a power of 2), so the runs stop at the same step.
        P1, s1, it1 = ref.stress_majorization(ref.parse(spec))
        P2, s2, it2 = ref.stress_majorization(ref.parse(spec), length=2.0)
        assert (P2 == 2 * P1).all() and it1 == it2
        b += ["let unit = graph.stressMajorizationLayout()",
              "let doubled = graph.stressMajorizationLayout(edgeLength: { _ in 2 })",
              "#expect(unit.vertices == doubled.vertices)",
              "#expect(doubled.positions == unit.positions.map { 2 * $0 })",
              "// The default start is scaled by the mean edge length, and so is every step.",
              "#expect(StressMajorizationLayout(graph, edgeLength: { _ in 2 }).drawing == graph.circularLayout(radius: 2))",
              "var unitStepper = StressMajorizationLayout(graph)", "unitStepper.run()",
              "var doubledStepper = StressMajorizationLayout(graph, edgeLength: { _ in 2 })", "doubledStepper.run()",
              "#expect(doubledStepper.iteration == unitStepper.iteration && doubledStepper.stress == unitStepper.stress)",
              "#expect(doubledStepper.drawing == doubled)"]
    else:
        raise AssertionError(n)
    return L + ["        " + x if x else "" for x in b] + ["    }"]


# ---------------------------------------------------------------------------------------------
# Traps
# ---------------------------------------------------------------------------------------------

def trap_test(n):
    spec, o = inp(n), op(n)
    L = header(n) + ["    func dr%03d() async {" % n, "        // %s; %s → **trap**" % (spec, o)]
    child, after = [], []
    if n == 7:
        child = [TWO_LET, "let position = drawing.position(of: 4)", "_ = position"]
        after = [TWO_LET, "#expect(throws: VertexNotFound.self) { try drawing.position(checked: 4) }", "#expect(drawing.count == 2)"]
    elif n == 10:
        child = ["_ = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0)])"]
        after = ["#expect(Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)]).count == 2)"]
    elif n == 11:
        child = ["_ = Drawing(vertices: [5, 5], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)])"]
        after = ["#expect(Drawing(vertices: [5, 6], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 1.0)]).count == 2)"]
    elif n in (31, 32):
        g = ref.parse(spec)
        call = "graph.circularLayout(radius: -1)" if n == 31 else "graph.circularLayout(center: SIMD2(.nan, 0))"
        child = undirected_graph(g, "") + ["_ = " + call]
        after = undirected_graph(g, "") + ["#expect(graph.circularLayout(radius: 0).positions == [SIMD2(0.0, 0.0), SIMD2(0.0, 0.0), SIMD2(0.0, 0.0)])",
                                           "#expect(graph.circularLayout(center: SIMD2(0, 0)).count == 3)"]
    elif n in (161, 164, 165):
        g = ref.parse(spec)
        call = {161: "_ = graph.sugiyamaLayout(layers: { [-1, 0][$0] })", 164: "_ = graph.sugiyamaLayout().layer(of: 9)",
                165: "_ = graph.sugiyamaLayout().bends(ofEdgeAt: 5)"}[n]
        child = directed_graph(g, "") + [call]
        after = directed_graph(g, "") + ["let layered = graph.sugiyamaLayout()",
                                         "#expect(layered.layer(of: 0) == 0 && layered.layer(of: 1) == 1 && layered.bends(ofEdgeAt: 0).isEmpty)",
                                         "#expect(graph.sugiyamaLayout(layers: { [0, 1][$0] }).drawing == layered.drawing)"]
    elif n in (173, 176, 189):
        g = ref.parse(spec)
        call = {173: "_ = graph.fruchtermanReingoldLayout(initial: Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0)]))",
                176: "var generator = Xoshiro256StarStar(seed: 1)\n_ = graph.fruchtermanReingoldLayout(iterations: -1, using: &generator)",
                189: "var generator = Xoshiro256StarStar(seed: 1)\n_ = graph.fruchtermanReingoldLayout(barnesHutTheta: -1, using: &generator)"}[n]
        child = undirected_graph(g, "") + call.split("\n")
        after = undirected_graph(g, "") + [
            "let start = Drawing(vertices: [0, 1, 2], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(0.0, 1.0)])",
            "#expect(graph.fruchtermanReingoldLayout(initial: start, iterations: 0) == start)",
            "var generator = Xoshiro256StarStar(seed: 1)",
            "#expect(graph.fruchtermanReingoldLayout(iterations: 0, barnesHutTheta: 0, using: &generator).count == 3)"]
    elif n in (205, 206):
        g = ref.parse(spec)
        call = "_ = graph.stressMajorizationLayout(edgeLength: { _ in 0 })" if n == 205 else "_ = graph.stressMajorizationLayout(tolerance: -1)"
        child = undirected_graph(g, "") + [call]
        after = undirected_graph(g, "") + ["#expect(graph.stressMajorizationLayout(edgeLength: { _ in 0.5 }, tolerance: 0).count == 2)"]
    else:
        raise AssertionError(n)
    L.append("        await #expect(processExitsWith: .failure) {")
    L += ["            " + x for x in child]
    L.append("        }")
    L.append("        // Without the call: the same setup answers.")
    L += ["        " + x for x in after]
    L.append("    }")
    return L


# ---------------------------------------------------------------------------------------------
# Phase 2 (DR-207 – DR-214), written with --phase2
# ---------------------------------------------------------------------------------------------

def phase2_test(n):
    spec, o, ex = inp(n), op(n), cell(n)
    L = header(n) + ["    func dr%03d() {" % n, "        // %s; %s → %s" % (spec, o, ex)]
    b = []
    if n in (207, 208, 209):
        g = ref.parse(spec)
        p, _ = ref.spectral(g)
        assert ex == fmt_pts(p, 9)
        b += undirected_graph(g, "") + graph_shape(g, "") + ["let layout = graph.spectralLayout()"]
        b += close_lines("layout.positions", p, "", "1e-8")
    elif n == 210:
        g = ref.parse(spec)
        b += undirected_graph(g, "") + ["let layout = graph.spectralLayout()", "let fiedler = graph.fiedlerVector()?.values ?? []",
                                        "#expect(fiedler.count == 5)",
                                        "#expect(zip(layout.positions.map(\\.x), fiedler).allSatisfy { abs($0 - $1) <= 1e-9 })"]
    elif n == 211:
        g = ref.parse("U: P(0,1,2), 1-3, 3-4")
        vals = eval(ex)
        b += undirected_graph(g, "") + ["let layout = graph.bfsLayout(start: 0)"] + close_lines("layout.positions", vals, "")
    elif n == 212:
        g = ref.parse("U: n=5; 0-2, 1-3, 2-4")
        vals = eval(ex)
        b += undirected_graph(g, "") + ["let layout = graph.multipartiteLayout(layer: { [0, 0, 1, 1, 2][$0] })"] + close_lines("layout.positions", vals, "")
    elif n in (213, 214):
        g = ref.parse(spec)
        bound = float(ex.split("≤ ")[1])
        b += undirected_graph(g, "") + hop_lines("") + normalized_lines("")
        b += ["var values: [Double] = []", "for seed in UInt64(1) ... 20 {", "    var generator = Xoshiro256StarStar(seed: seed)",
              "    values.append(normalizedStress(graph.forceAtlas2Layout(using: &generator).positions))", "}",
              "let sorted = values.sorted()", "#expect((sorted[9] + sorted[10]) / 2 <= %s)" % d(bound)]
    return L + ["        " + x if x else "" for x in b] + ["    }"]


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def test_for(n):
    if is_trap(n):
        return trap_test(n)
    gr = group(n)
    if gr == "Drawing":
        return drawing_test(n)
    if gr == "Circular":
        return circular_test(n)
    if gr == "Tree":
        return tree_test(n)
    if gr == "Layered":
        return layered_test(n)
    if gr == "ForceDirected":
        return fr_test(n)
    if gr == "Stress":
        return stress_test(n)
    if gr == "Phase 2":
        return phase2_test(n)
    raise AssertionError(n)


def ids(*groups):
    return [n for n in PHASE1 if group(n) in groups and not is_trap(n)]


TRAPS = [n for n in PHASE1 if is_trap(n)]
FILES = [
    ("DrawingTests.swift", "Drawing", ids("Drawing"),
     "Drawing (catalog DR-001 – DR-021): a position per vertex in the order given, lookup by vertex\n"
     "// (`position(of:)`, `position(checked:)`, `setPosition(_:of:)`), (vertex, position) elements, equality\n"
     "// in order, the bounding box, and `rescaled(scale:center:)` (NetworkX's rescale_layout, then a\n"
     "// translation). Exact."),
    ("CircularLayoutTests.swift", "circularLayout", ids("Circular"),
     "circularLayout (catalog DR-022 – DR-030): vertex i of n at center + radius (cos 2πi/n, sin 2πi/n),\n"
     "// one vertex at the centre, edges not read. Compared within 1e-9 (cos and sin)."),
    ("ReingoldTilfordLayoutTests.swift", "reingoldTilfordLayout", ids("Tree"),
     "reingoldTilfordLayout and its circular form (catalog DR-033 – DR-063): Walker's algorithm in\n"
     "// Buchheim, Jünger and Leipert's linear form, separation 1, y = depth, root at x = 0, exact; the\n"
     "// circular form is igraph's polar map, compared within 1e-9."),
    ("SugiyamaLayoutTests.swift", "sugiyamaLayout", ids("Layered"),
     "sugiyamaLayout (catalog DR-064 – DR-163): Eades–Lin–Smyth (`Cycles.feedbackArcSet()`), minimum-span\n"
     "// layering, barycenter crossing reduction, Brandes–Köpf. Where the optimal layering is unique,\n"
     "// each row checks the whole layered drawing: layers, layer count, crossings, positions, the bends\n"
     "// of every edge, reversed edges, and feedbackArcSet(). Exact."),
    ("FruchtermanReingoldLayoutTests.swift", "fruchtermanReingoldLayout", ids("ForceDirected"),
     "fruchtermanReingoldLayout (catalog DR-166 – DR-188): the start (x then y per vertex, top 53 bits of\n"
     "// one draw each, exactly 2n draws) exactly; the stepper; the two-vertex equilibrium; and quality as\n"
     "// the median over seeds 1…20 of Xoshiro256StarStar of normalized stress or crossings, computed\n"
     "// inline from `positions`, against the catalog's bound."),
    ("StressMajorizationLayoutTests.swift", "stressMajorizationLayout", ids("Stress"),
     "stressMajorizationLayout (catalog DR-190 – DR-204): the converged stress within ±1%, the normalized\n"
     "// stress against 1.02 × NetworkX's Kamada–Kawai (+ 1e-4), `stress` equal to the stress of `drawing`\n"
     "// computed inline, monotone steps, determinism, and edge lengths."),
    ("GraphDrawingPreconditionTests.swift", "GraphDrawing preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the call, so the trap is the call's and not the\n"
     "// setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]
if PHASE2:
    FILES.append(("GraphDrawingPhase2Tests.swift", "GraphDrawing phase 2", list(range(207, 215)),
                  "Phase 2 (catalog DR-207 – DR-214): spectral, BFS, multipartite and ForceAtlas2 layouts. Written\n"
                  "// only with swiftgen.py --phase2, once those entry points exist."))

IMPORTS = [("Cycles", "feedbackArcSet("), ("DirectedAcyclicGraphModule", "DirectedAcyclicGraph<"),
           ("GrafluentTestSupport", ".tags("), ("Multigraphs", "Pseudograph<"), ("RandomGraphs", "Xoshiro256StarStar"),
           ("Trees", "RootedTree("), ("SpectralGraphTheory", "fiedlerVector(")]


def write(fname, suite, rows, comment):
    tests = [test_for(n) for n in rows]
    if fname == "GraphDrawingPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphDrawing", "GraphProtocols", "Testing"]
    for module, needle in IMPORTS:
        if needle in text:
            imports.append(module)
    if fname == "GraphDrawingPreconditionTests.swift" and "GrafluentTestSupport" not in imports:
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "GraphDrawingPreconditionTests.swift" else ""
    out = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
for fname, suite, rows, comment in FILES:
    k = write(fname, suite, rows, comment)
    print(fname, k)
    total += k
    rows_total += len(rows)
assert rows_total == (N if PHASE2 else 206), rows_total
print("catalog rows", rows_total, "tests", total)


# ---------------------------------------------------------------------------------------------
# Minimum-span layering against a linear-program solver (not catalog rows)
# ---------------------------------------------------------------------------------------------

def lp_layering_cases(count=400, seed=3):
    """Random DAGs from a SplitMix64 stream: n = 3 + draw % 25 vertices, draw % 3n arc attempts
    (a, b) with a ≠ b drawn as min → max. Each with the least total span of the ranking LP
    (min Σ r_head − r_tail subject to r_head − r_tail ≥ 1, r ≥ 0), solved by scipy's HiGHS; the
    constraint matrix is totally unimodular, so the optimum is integral."""
    import numpy as np
    from scipy.optimize import linprog
    state = seed
    mask = (1 << 64) - 1

    def draw():
        nonlocal state
        state = (state + 0x9E3779B97F4A7C15) & mask
        z = state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & mask
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & mask
        return (z ^ (z >> 31)) >> 2

    out = []
    for _ in range(count):
        n = 3 + draw() % 25
        m = draw() % (3 * n)
        arcs = []
        for _ in range(m):
            a, b = draw() % n, draw() % n
            if a != b:
                arcs.append((min(a, b), max(a, b)))
        span = 0
        if arcs:
            cost = np.zeros(n)
            A = np.zeros((len(arcs), n))
            for k, (a, b) in enumerate(arcs):
                cost[b] += 1
                cost[a] -= 1
                A[k, a] = 1
                A[k, b] = -1
            r = linprog(cost, A_ub=A, b_ub=-np.ones(len(arcs)), bounds=[(0, None)] * n, method="highs")
            assert r.status == 0
            span = round(r.fun)
            assert abs(r.fun - span) < 1e-6
        out.append((n, arcs, span))
    return out


def short_arcs_dag(n, seed=1):
    """n vertices; from each v two arcs v → v + 1 + draw % 20 (kept when below n), draws from the
    catalog's LCG (the state's top 31 bits after a step)."""
    x = seed
    arcs = []
    for v in range(n):
        for _ in range(2):
            x = (x * 6364136223846793005 + 1442695040888963407) & ((1 << 64) - 1)
            w = v + 1 + (x >> 33) % 20
            if w < n:
                arcs.append((v, w))
    return arcs


def lp_span(n, arcs):
    """The ranking LP's optimum by scipy's HiGHS, sparse."""
    import numpy as np
    from scipy.optimize import linprog
    from scipy.sparse import coo_matrix
    m = len(arcs)
    cost = np.zeros(n)
    rows, cols, vals = [], [], []
    for k, (a, b) in enumerate(arcs):
        cost[b] += 1
        cost[a] -= 1
        rows += [k, k]
        cols += [a, b]
        vals += [1.0, -1.0]
    A = coo_matrix((vals, (rows, cols)), shape=(m, n)).tocsr()
    r = linprog(cost, A_ub=A, b_ub=-np.ones(m), bounds=[(0, None)] * n, method="highs")
    assert r.status == 0
    span = round(r.fun)
    assert abs(r.fun - span) < 1e-6
    return span


def write_lp_test():
    large_n = 50_000
    large_span = lp_span(large_n, short_arcs_dag(large_n))
    cases = lp_layering_cases()
    lines = ["%d %s= %d" % (n, "".join("%d>%d " % a for a in arcs), span) for n, arcs, span in cases]
    out = [
        "// Minimum-span layering against a linear-program solver: 400 random DAGs (up to 27 vertices and",
        "// 80 arcs, from a SplitMix64 stream) with the least total span that scipy's HiGHS finds for the",
        "// ranking LP, precomputed by swiftgen.py (lp_layering_cases), so no solver runs here. Each line is",
        "// `n arcs… = span`. Generated by swiftgen.py; see README.md.",
        "",
        "import GraphDrawing",
        "import GraphProtocols",
        "import Multigraphs",
        "import Testing",
        "",
        '@Suite("Sugiyama layering against a linear program")',
        "struct SugiyamaLayeringLinearProgramTests {",
        '    @Test("The total edge span is the LP optimum on 400 random DAGs, every edge spans ≥ 1, each component starts at 0")',
        "    func spansMatchTheLinearProgram() {",
        '        let cases = """',
    ]
    out += ["            " + l for l in lines]
    out += [
        '            """',
        '        for line in cases.split(separator: "\\n") {',
        '            let fields = line.split(separator: " ")',
        "            let n = Int(fields[0])!, expected = Int(fields[fields.count - 1])!",
        "            let arcs = fields[1 ..< fields.count - 2].map { field in",
        '                let ends = field.split(separator: ">")',
        "                return DirectedEdge(from: Int(ends[0])!, to: Int(ends[1])!)",
        "            }",
        "            let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)",
        "            let layered = graph.sugiyamaLayout()",
        "            let spans = arcs.map { layered.layer(of: $0.target) - layered.layer(of: $0.source) }",
        '            #expect(layered.reversedEdges.isEmpty, "\\(line)")',
        '            #expect(spans.allSatisfy { $0 >= 1 }, "\\(line)")',
        '            #expect(spans.reduce(0, +) == expected, "\\(line)")',
        "            // Each weakly connected component's least layer is 0.",
        "            var component = Array(0 ..< n)",
        "            func find(_ x: Int) -> Int { component[x] == x ? x : find(component[x]) }",
        "            for arc in arcs { component[find(arc.source)] = find(arc.target) }",
        "            var least = [Int: Int]()",
        "            for v in 0 ..< n { least[find(v)] = min(least[find(v)] ?? .max, layered.layer(of: v)) }",
        '            #expect(least.values.allSatisfy { $0 == 0 }, "\\(line)")',
        "        }",
        "    }",
        "",
        "    // Release: 0.23 s; Gansner's pivots, searching a side of a cut each, took 1.5 s. The",
        "    // bound is for a debug build. Crossing reduction is off: the layering is under test.",
        '    @Test("At 5 × 10⁴ vertices with short random arcs: the LP optimum (HiGHS: %d)", .timeLimit(.minutes(1)))' % large_span,
        "    func largeSpanMatchesTheLinearProgram() async {",
        "        await Task {",
        "            let n = %d" % large_n,
        "            var x: UInt64 = 1",
        "            var arcs: [DirectedEdge<Int>] = []",
        "            for v in 0 ..< n {",
        "                for _ in 0 ..< 2 {",
        "                    x = x &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407",
        "                    let w = v + 1 + Int((x >> 33) % 20)",
        "                    if w < n { arcs.append(DirectedEdge(from: v, to: w)) }",
        "                }",
        "            }",
        "            let graph = DirectedPseudograph<Int>(vertices: 0 ..< n, edges: arcs)",
        "            let clock = ContinuousClock()",
        "            let start = clock.now",
        "            let layered = graph.sugiyamaLayout(maxIterations: 0)",
        "            let elapsed = clock.now - start",
        '            #expect(elapsed < .seconds(30), "\\(elapsed)")',
        "            let spans = arcs.map { layered.layer(of: $0.target) - layered.layer(of: $0.source) }",
        "            #expect(spans.allSatisfy { $0 >= 1 })",
        "            #expect(spans.reduce(0, +) == %d)" % large_span,
        "        }.value",
        "    }",
        "}",
    ]
    with open(os.path.join(OUT, "SugiyamaLayeringLinearProgramTests.swift"), "w") as f:
        f.write("\n".join(out) + "\n")
    print("SugiyamaLayeringLinearProgramTests.swift", len(cases), "cases")


write_lp_test()
