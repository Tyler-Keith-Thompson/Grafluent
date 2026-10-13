"""Writes the catalog-row test files of Tests/RandomGraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/RandomGraphs/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/RandomGraphsTests

First checks that ref.py reproduces cases.md byte for byte (ref.py checks the generator's published
vectors and NetworkX on the same stream as it builds the rows). Then it re-runs every row on ref.py's
port of the procedures, asserts that each value is the row's cell, and writes one @Test per row.

* Exact rows run their family on every conformer api.md lists, each with a fresh generator: the
  undirected form on UndirectedAdjacencyList, Pseudograph and Multigraph; the directed form (every
  family's: both arcs of every edge for Watts–Strogatz, random geometric and random regular graphs)
  on CompressedSparseRow, AdjacencyMatrix, AdjacencyList, DirectedPseudograph, DirectedMultigraph
  and StableDirectedGraph; random bipartite graphs also on BipartiteGraph; random DAGs on
  DirectedAcyclicGraph over AdjacencyList, StableDirectedGraph and DirectedPseudograph. The form the
  catalog does not show comes from the same model. Each checks the vertices, the edges in order,
  the degrees, the positions of a geometric graph, the Prüfer code of a tree, and the number of
  draws (the generator after the call equals a fresh one advanced that many times).
* Statistical rows recompute the exact aggregate over the same seeds on every conformer of the
  row's kind, and check the law with the tolerance api.md gives. The chi-square rows pin the count
  of every outcome, from the model.
* Trap rows run the call as an exit test on every conformer the rule covers, then run a valid
  neighbour of the call in this process.
"""
import itertools
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "RandomGraphsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and the structured arguments of every row
# ---------------------------------------------------------------------------------------------
EXACT, TRAPFN = {}, {}
_exact, _trap = ref.exact_row, ref.trap_row


def _rec_exact(group, case, call, kind, args, seed, fn, show_positions=False):
    EXACT[len(ref.ROWS) + 1] = (kind, args, seed, fn, call.replace("SEED", str(seed)))
    return _exact(group, case, call, kind, args, seed, fn, show_positions)


def _rec_trap(group, case, call, fn):
    TRAPFN[len(ref.ROWS) + 1] = fn
    return _trap(group, case, call, fn)


ref.exact_row, ref.trap_row = _rec_exact, _rec_trap
ref.check_vectors()
ref.build_rows()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| RG-"):
        parts = [p.strip() for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 151


def group(n): return CELLS[n][1]
def title(n): return CELLS[n][2]
def call(n): return CELLS[n][3].strip("`")
def cell(n): return CELLS[n][4]
def is_trap(n): return cell(n).startswith("**trap**")


# Rows the catalog writes as statistics but that are exact runs.
EXACT[20] = ("gnp", (1000, 1e-300, False), 0, lambda rng: ref.gnp(1000, 1e-300, rng), call(20))
EXACT[21] = ("gnp", (20000, 1e-12, False), 3, lambda rng: ref.gnp(20000, 1e-12, rng), call(21))
EXACT[94] = ("sbm", ([5, 5], [[0.0, 1.0], [1.0, 0.0]], False), 0,
             lambda rng: ref.sbm([5, 5], [[0.0, 1.0], [1.0, 0.0]], rng), call(94))

UNDIRECTED = ["UndirectedAdjacencyList<Int>", "Pseudograph<Int>", "Multigraph<Int>"]
DIRECTED = ["CompressedSparseRow", "AdjacencyMatrix", "AdjacencyList<Int>", "DirectedPseudograph<Int>",
            "DirectedMultigraph<Int>", "StableDirectedGraph<Int>"]
DAGS = ["DirectedAcyclicGraph<AdjacencyList<Int>>", "DirectedAcyclicGraph<StableDirectedGraph<Int>>",
        "DirectedAcyclicGraph<DirectedPseudograph<Int>>"]


def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "] as [Int]"
def pairs(es): return "[" + ", ".join("[%d, %d]" % tuple(e) for e in es) + "] as [[Int]]"
def doubles(xs): return "[" + ", ".join(repr(x) for x in xs) + "] as [Double]"


def swift_call(kind, args, typ):
    """The factory call for `typ`, drawing from `generator`."""
    if kind in ("gnp", "dag_gnp"):
        n, p = args[0], args[1]
        return "%s.erdosRenyi(vertexCount: %d, edgeProbability: %r, using: &generator)" % (typ, n, p)
    if kind in ("gnm", "dag_gnm"):
        return "%s.erdosRenyi(vertexCount: %d, edgeCount: %d, using: &generator)" % (typ, args[0], args[1])
    if kind == "ba":
        return "%s.barabasiAlbert(vertexCount: %d, edgesPerVertex: %d, using: &generator)" % (typ, args[0], args[1])
    if kind == "ws":
        return "%s.wattsStrogatz(vertexCount: %d, nearestNeighborCount: %d, rewiringProbability: %r, using: &generator)" % (typ, *args)
    if kind == "rgg":
        return "%s.randomGeometric(vertexCount: %d, radius: %r, dimension: %d, using: &generator)" % (typ, *args)
    if kind == "sbm":
        return "%s.stochasticBlockModel(blockSizes: %r, edgeProbabilities: %r, using: &generator)" % (typ, args[0], args[1])
    if kind == "tree":
        return "Tree<Int>.random(vertexCount: %d, using: &generator)" % args[0]
    if kind == "reg":
        return "%s.randomRegular(vertexCount: %d, degree: %d, using: &generator)" % (typ, *args)
    if kind == "bip":
        return "%s.randomBipartite(leftCount: %d, rightCount: %d, edgeProbability: %r, using: &generator)" % (typ, *args)
    raise AssertionError(kind)


def model(kind, args, seed, directed):
    """(result, draws), or the Trap."""
    rng = ref.Xoshiro256StarStar(seed)
    try:
        if kind == "gnp":
            r = ref.gnp(args[0], args[1], rng, directed)
        elif kind == "gnm":
            r = ref.gnm(args[0], args[1], rng, directed)
        elif kind == "ba":
            r = ref.barabasi_albert(args[0], args[1], rng, directed)
        elif kind == "sbm":
            r = ref.sbm(args[0], args[1], rng, directed)
        elif kind == "ws":
            r = ref.watts_strogatz(*args, rng, directed)
        elif kind == "rgg":
            r = ref.random_geometric(args[0], args[1], rng, args[2], directed)
        elif kind == "reg":
            r = ref.random_regular(*args, rng, directed)
        elif kind == "bip":
            r = ref.random_bipartite(*args, rng, directed)
        elif kind == "tree":
            r = ref.random_tree(args[0], rng)
        elif kind == "dag_gnp":
            r = ref.dag_gnp(args[0], args[1], rng)
        elif kind == "dag_gnm":
            r = ref.dag_gnm(args[0], args[1], rng)
        else:
            raise AssertionError(kind)
    except ref.Trap as t:
        return t, None
    return r, rng.draws


def degrees(r):
    if r.directed:
        out, inn = [0] * r.n, [0] * r.n
        for u, v in r.edges:
            out[u] += 1
            inn[v] += 1
        return out, inn
    d = [0] * r.n
    for u, v in r.edges:
        d[u] += 1
        d[v] += 1
    return d


def draws_lines(seed, draws, i):
    return [i + "var expected = Xoshiro256StarStar(seed: %d)" % seed,
            i + "for _ in 0 ..< %d { _ = expected.next() }" % draws,
            i + "#expect(generator == expected, \"\\(type): %d draws\")" % draws]


def undirected_check(r, draws, seed, ind, positions=False):
    n, m = r.n, len(r.edges)
    sig = "_ graph: some Graph<Int>, " + ("_ positions: [Double], " if positions else "") + "_ generator: Xoshiro256StarStar, _ type: String"
    L = [ind + "func check(%s) {" % sig]
    i = ind + "    "
    L.append(i + "#expect(graph.vertexCount == %d && graph.edgeCount == %d && graph.edges.count == %d, \"\\(type)\")" % (n, m, m))
    L.append(i + "#expect(Array(graph.vertices) == Array(0 ..< %d), \"\\(type)\")" % n)
    L.append(i + "#expect(graph.edges.map { [$0.u, $0.v] } == %s, \"\\(type)\")" % pairs(r.edges))
    if n <= 64:
        L.append(i + "#expect((0 ..< %d).map { graph.degree(of: $0) } == %s, \"\\(type)\")" % (n, ints(degrees(r))))
    else:
        L.append(i + "#expect((0 ..< %d).allSatisfy { graph.degree(of: $0) == 0 }, \"\\(type)\")" % n)
        assert m == 0
    if positions:
        flat = [x for p in r.positions for x in p]
        L.append(i + "#expect(positions == %s, \"\\(type)\")" % doubles(flat))
    L += draws_lines(seed, draws, i)
    L.append(ind + "}")
    return L


def directed_check(r, draws, seed, ind, dag=False, positions=False):
    n, m = r.n, len(r.edges)
    out, inn = degrees(r)
    sig = "_ graph: some DirectedGraph<Int>, " + ("_ positions: [Double], " if positions else "") + "_ generator: Xoshiro256StarStar, _ type: String"
    L = [ind + "func check%s(%s) {" % ("DAG" if dag else "Directed", sig)]
    i = ind + "    "
    L.append(i + "#expect(graph.vertexCount == %d && graph.edgeCount == %d && graph.edges.count == %d, \"\\(type)\")" % (n, m, m))
    L.append(i + "#expect(Array(graph.vertices) == Array(0 ..< %d), \"\\(type)\")" % n)
    L.append(i + "#expect(graph.edges.map { [$0.source, $0.target] } == %s, \"\\(type)\")" % pairs(r.edges))
    # The geometric rows write a large empty graph's degrees as a rule.
    if n <= 64 or not positions:
        L.append(i + "#expect((0 ..< %d).map { graph.outDegree(of: $0) } == %s, \"\\(type)\")" % (n, ints(out)))
        L.append(i + "var inDegrees = [Int](repeating: 0, count: %d)" % n)
        L.append(i + "for edge in graph.edges { inDegrees[edge.target] += 1 }")
        L.append(i + "#expect(inDegrees == %s, \"\\(type)\")" % ints(inn))
    else:
        assert m == 0
        L.append(i + "#expect((0 ..< %d).allSatisfy { graph.outDegree(of: $0) == 0 }, \"\\(type)\")" % n)
    if positions:
        flat = [x for p in r.positions for x in p]
        L.append(i + "#expect(positions == %s, \"\\(type)\")" % doubles(flat))
    L += draws_lines(seed, draws, i)
    L.append(ind + "}")
    return L


def header(n, is_async=False):
    return ['    @Test("RG-%03d %s")' % (n, title(n)),
            "    func rg%03d()%s {" % (n, " async" if is_async else ""),
            "        // %s → %s" % (call(n), cell(n))]


def block(seed, construct, check_call):
    return ["        do {",
            "            var generator = Xoshiro256StarStar(seed: %d)" % seed,
            "            " + construct,
            "            " + check_call,
            "        }"]


def exact_test(n):
    kind, args, seed, fn, catalog_call = EXACT[n]
    directed_row = catalog_call.startswith("CompressedSparseRow")
    if kind in ("gnp", "gnm", "ba", "sbm"):
        base = args[:2]
    else:
        base = args
    # The catalog's call is ours with the generator spelled out.
    own_type = catalog_call.split(".")[0] if not catalog_call.startswith("Tree") else "Tree<Int>"
    mine = swift_call(kind, base, own_type).replace("&generator", "&Xoshiro256StarStar(seed: %d)" % seed)
    if "using: &…" in catalog_call:
        mine = swift_call(kind, base, own_type).replace("&generator", "&…")
    if n != 94:
        assert mine == catalog_call, (n, mine, catalog_call)
    L = header(n)
    if kind == "tree":
        r, draws = model(kind, base, seed, False)
        text = "n %d; m %d; code %s; E [%s]; draws %d" % (r.n, len(r.edges), r.code, ", ".join("%d–%d" % e for e in r.edges), draws)
        assert cell(n).startswith(text), (n, text)
        L.append("        var generator = Xoshiro256StarStar(seed: %d)" % seed)
        L.append("        let tree = " + swift_call(kind, base, ""))
        L.append("        #expect(tree.vertexCount == %d && tree.edgeCount == %d)" % (r.n, len(r.edges)))
        L.append("        #expect(Array(tree.vertices) == Array(0 ..< %d))" % r.n)
        L.append("        // Tree(pruferSequence:)'s order: edge k joins the k-th leaf removed to the k-th code element.")
        L.append("        #expect(tree.edges.map { [$0.u, $0.v] } == %s)" % pairs(r.edges))
        L.append("        #expect((0 ..< %d).map { tree.degree(of: $0) } == %s)" % (r.n, ints(degrees(r))))
        L.append("        #expect(tree.pruferSequence == %s)" % ("nil" if r.n < 2 else ints(r.code).replace(" as [Int]", "")))
        L.append("        var expected = Xoshiro256StarStar(seed: %d)" % seed)
        L.append("        for _ in 0 ..< %d { _ = expected.next() }" % draws)
        L.append("        #expect(generator == expected, \"%d draws\")" % draws)
        L.append("    }")
        return L
    if kind.startswith("dag"):
        r, draws = model(kind, base, seed, True)
        assert cell(n).startswith("n %d; m %d; E [%s]; draws %d" % (r.n, len(r.edges), ", ".join("%d→%d" % e for e in r.edges), draws)), n
        L += directed_check(r, draws, seed, "        ", dag=True)
        for t in DAGS:
            L += block(seed, "let graph = " + swift_call(kind, base, t), "checkDAG(graph, generator, \"%s\")" % t)
            L.insert(len(L) - 1, "            #expect(Array(graph.topologicalOrder) == Array(0 ..< %d), \"%s\")" % (r.n, t))
        # The same draws as the undirected procedure, each edge oriented upward.
        ru, du = model("gnp" if kind == "dag_gnp" else "gnm", base, seed, False)
        assert [tuple(e) for e in ru.edges] == [tuple(e) for e in r.edges] and du == draws
        L.append("        // The undirected procedure on the same stream: the same pairs, the same draws.")
        L += block(seed, "let graph = " + swift_call(kind, base, "UndirectedAdjacencyList<Int>"),
                   "#expect(graph.edges.map { [$0.u, $0.v] } == %s)" % pairs(r.edges))
        L.append("    }")
        return L
    for directed in [False, True]:
        r, draws = model(kind, base, seed, directed)
        if isinstance(r, ref.Trap):
            assert directed != directed_row
            continue
        if directed == directed_row:
            if n == 94:
                assert cell(n).startswith("m %d;" % len(r.edges))
            elif n == 21:
                assert cell(n) == "n %d; m %d; E []" % (r.n, len(r.edges))
            else:
                sep = "→" if directed else "–"
                text = "n %d; m %d; E [%s]" % (r.n, len(r.edges), ", ".join("%d%s%d" % (u, sep, v) for u, v in r.edges))
                assert cell(n).startswith(text), (n, text, cell(n))
                if "pos [" in cell(n):
                    text += "; pos [" + ", ".join("(" + ", ".join(repr(c) for c in p) + ")" for p in r.positions) + "]"
                assert cell(n).startswith(text + "; draws %d" % draws), (n, text)
        else:
            L.append("        // The %s form, from the same model." % ("directed" if directed else "undirected"))
        rgg = kind == "rgg"
        if directed:
            L += directed_check(r, draws, seed, "        ", positions=rgg)
            for t in DIRECTED:
                if rgg:
                    L += block(seed, "let (graph, positions) = " + swift_call(kind, base, t), "checkDirected(graph, positions, generator, \"%s\")" % t)
                else:
                    L += block(seed, "let graph = " + swift_call(kind, base, t), "checkDirected(graph, generator, \"%s\")" % t)
        else:
            L += undirected_check(r, draws, seed, "        ", positions=rgg)
            for t in UNDIRECTED:
                if rgg:
                    L += block(seed, "let (graph, positions) = " + swift_call(kind, base, t), "check(graph, positions, generator, \"%s\")" % t)
                else:
                    L += block(seed, "let graph = " + swift_call(kind, base, t), "check(graph, generator, \"%s\")" % t)
            if kind == "bip":
                a, b = base[0], base[1]
                L.append("        // With its sides: left 0..<%d, right %d..<%d, the same edges and draws." % (a, a, a + b))
                L += ["        do {",
                      "            var generator = Xoshiro256StarStar(seed: %d)" % seed,
                      "            let bipartite = " + swift_call(kind, base, "BipartiteGraph<Int>"),
                      "            #expect(Array(bipartite.left) == Array(0 ..< %d) && Array(bipartite.right) == Array(%d ..< %d))" % (a, a, a + b),
                      "            #expect((0 ..< %d).allSatisfy { bipartite.side(of: $0) == ($0 < %d ? .left : .right) })" % (a + b, a),
                      "            check(bipartite, generator, \"BipartiteGraph<Int>\")",
                      "        }"]
    if n == 94:
        L.append("        // K5,5: the same graph as NamedGraphs' completeBipartite.")
        for t in UNDIRECTED:
            L += block(seed, "let graph = " + swift_call(kind, base, t), "#expect(graph == %s.completeBipartite(leftCount: 5, rightCount: 5))" % t)
    L.append("    }")
    return L


# ---------------------------------------------------------------------------------------------
# Traps: (calls run as exit tests, valid neighbour, its n and m, and the model of the neighbour)
# ---------------------------------------------------------------------------------------------

def on(types, kind, args):
    return [(t, swift_call(kind, args, t)) for t in types]


TRAPS = {
    22: (on(UNDIRECTED + DIRECTED + DAGS, "gnp", (-1, 0.5)), ("gnp", (0, 0.5))),
    23: (on(UNDIRECTED + DIRECTED + DAGS, "gnp", (5, 1.5)), ("gnp", (5, 1.0))),
    24: (on(UNDIRECTED + DIRECTED + DAGS, "gnp", (5, -0.1)), ("gnp", (5, 0.0))),
    25: ([(t, c.replace("nan", ".nan")) for t, c in on(UNDIRECTED + DIRECTED + DAGS, "gnp", (5, float("nan")))], ("gnp", (5, 0.5))),
    40: (on(UNDIRECTED + DAGS, "gnm", (4, 7)), ("gnm", (4, 6))),
    41: (on(DIRECTED, "gnm", (3, 7)), ("gnm", (3, 6))),
    42: (on(UNDIRECTED + DIRECTED + DAGS, "gnm", (4, -1)), ("gnm", (4, 0))),
    43: (on(UNDIRECTED + DIRECTED + DAGS, "gnm", (1, 1)), ("gnm", (1, 0))),
    55: (on(UNDIRECTED + DIRECTED, "ba", (5, 0)), ("ba", (5, 1))),
    56: (on(UNDIRECTED + DIRECTED, "ba", (5, 5)), ("ba", (5, 4))),
    57: (on(UNDIRECTED + DIRECTED, "ba", (1, 1)), ("ba", (2, 1))),
    69: (on(UNDIRECTED + DIRECTED, "ws", (10, 3, 0.1)), ("ws", (10, 2, 0.1))),
    70: (on(UNDIRECTED + DIRECTED, "ws", (4, 6, 0.1)), ("ws", (4, 4, 0.1))),
    71: (on(UNDIRECTED + DIRECTED, "ws", (10, 4, 1.5)), ("ws", (10, 4, 1.0))),
    80: (on(UNDIRECTED + DIRECTED, "rgg", (5, -0.1, 2)), ("rgg", (5, 0.0, 2))),
    81: ([(t, c.replace("nan", ".nan")) for t, c in on(UNDIRECTED + DIRECTED, "rgg", (5, float("nan"), 2))], ("rgg", (5, 0.1, 2))),
    82: (on(UNDIRECTED + DIRECTED, "rgg", (5, 0.1, 0)), ("rgg", (5, 0.1, 1))),
    89: (on(UNDIRECTED, "sbm", ([2, 2], [[0.5, 0.1], [0.2, 0.5]])), ("sbm", ([2, 2], [[0.5, 0.1], [0.1, 0.5]]))),
    90: (on(UNDIRECTED + DIRECTED, "sbm", ([2, 2], [[0.5, 0.1]])), ("sbm", ([2, 2], [[0.5, 0.1], [0.1, 0.5]]))),
    91: (on(UNDIRECTED + DIRECTED, "sbm", ([2], [[1.5]])), ("sbm", ([2], [[1.0]]))),
    92: (on(UNDIRECTED + DIRECTED, "sbm", ([2, -1], [[0.5, 0.1], [0.1, 0.5]])), ("sbm", ([2, 0], [[0.5, 0.1], [0.1, 0.5]]))),
    101: ([("Tree<Int>", swift_call("tree", (0,), "")), ("Tree<Int>", swift_call("tree", (-1,), ""))], ("tree", (1,))),
    107: (on(DAGS, "gnm", (4, 7)), ("dag_gnm", (4, 6))),
    121: (on(UNDIRECTED + DIRECTED, "reg", (5, 5)), ("reg", (5, 4))),
    122: (on(UNDIRECTED + DIRECTED, "reg", (5, -1)), ("reg", (5, 0))),
    123: (on(UNDIRECTED + DIRECTED, "reg", (5, 3)), ("reg", (5, 2))),
    124: (on(UNDIRECTED + DIRECTED, "reg", (-1, 0)), ("reg", (1, 0))),
    136: (on(UNDIRECTED + DIRECTED + ["BipartiteGraph<Int>"], "bip", (-1, 3, 0.5)), ("bip", (0, 3, 0.5))),
    137: (on(UNDIRECTED + DIRECTED + ["BipartiteGraph<Int>"], "bip", (3, -1, 0.5)), ("bip", (3, 0, 0.5))),
    138: (on(UNDIRECTED + DIRECTED + ["BipartiteGraph<Int>"], "bip", (3, 3, 1.5)), ("bip", (3, 3, 1.0))),
    139: ([(t, c.replace("nan", ".nan")) for t, c in on(UNDIRECTED + DIRECTED + ["BipartiteGraph<Int>"], "bip", (3, 3, float("nan")))],
          ("bip", (3, 3, 0.5))),
    146: (on(UNDIRECTED + DIRECTED, "ws", (0, 2, 0.5)), ("ws", (0, 0, 0.5))),
    147: (on(UNDIRECTED + DIRECTED, "rgg", (3, 0.6, 0)), ("rgg", (3, 0.6, 1))),
    148: (on(UNDIRECTED + DIRECTED, "reg", (4, 4)), ("reg", (4, 3))),
    149: (on(UNDIRECTED + DIRECTED, "sbm", ([1, -1], [[0.5, 0.5], [0.5, 0.5]])), ("sbm", ([1, 0], [[0.5, 0.5], [0.5, 0.5]]))),
    150: (on(UNDIRECTED + DIRECTED, "sbm", ([2, 2], [[0.5, 0.1], [0.1, 0.5], [0.1, 0.5]])), ("sbm", ([2, 2], [[0.5, 0.1], [0.1, 0.5]]))),
    151: (on(UNDIRECTED + DIRECTED, "sbm", ([2, 2], [[0.5, 0.1, 0.1], [0.1, 0.5, 0.1]])), ("sbm", ([2, 2], [[0.5, 0.1], [0.1, 0.5]]))),
}


def ref_trap(kind, args, directed):
    rng = ref.Xoshiro256StarStar(0)
    f = {"gnp": lambda: ref.gnp(args[0], args[1], rng, directed), "gnm": lambda: ref.gnm(args[0], args[1], rng, directed),
         "ba": lambda: ref.barabasi_albert(args[0], args[1], rng, directed), "ws": lambda: ref.watts_strogatz(*args, rng),
         "rgg": lambda: ref.random_geometric(args[0], args[1], rng, args[2]),
         "sbm": lambda: ref.sbm(args[0], args[1], rng, directed), "tree": lambda: ref.random_tree(args[0], rng),
         "reg": lambda: ref.random_regular(*args, rng, directed), "bip": lambda: ref.random_bipartite(*args, rng, directed)}[kind]
    try:
        f()
    except ref.Trap as t:
        return str(t)
    return None


def trap_test(n):
    if n == 2:
        L = header(n, True)
        L += ["        await #expect(processExitsWith: .failure) {",
              "            _ = Xoshiro256StarStar(state: (0, 0, 0, 0))",
              "        }",
              "        // Without the fault: any one nonzero word is a valid state.",
              "        var generator = Xoshiro256StarStar(state: (0, 0, 0, 1))",
              "        #expect(generator.next() == 0 && generator.next() == 0 && generator.next() != 0)",
              "    }"]
        assert ref.Xoshiro256StarStar(state=[0, 0, 0, 1]).next() == 0
        x = ref.Xoshiro256StarStar(state=[0, 0, 0, 1])
        assert [x.next() for _ in range(3)][2] != 0
        return L
    calls, (vkind, vargs) = TRAPS[n]
    # Each call traps in the model, and one of them with the row's message.
    msgs = set()
    for t, c in calls:
        directed = t in DIRECTED or t in DAGS
        if ".erdosRenyi(" in c and "edgeProbability" in c:
            m = re.search(r"vertexCount: (-?\d+), edgeProbability: (\S+?),", c)
            p = float(m.group(2).replace(".nan", "nan"))
            msg = ref_trap("gnp", (int(m.group(1)), p), directed and t not in DAGS)
        elif ".erdosRenyi(" in c:
            m = re.search(r"vertexCount: (-?\d+), edgeCount: (-?\d+),", c)
            msg = ref_trap("gnm", (int(m.group(1)), int(m.group(2))), directed and t not in DAGS)
        elif ".barabasiAlbert(" in c:
            m = re.search(r"vertexCount: (-?\d+), edgesPerVertex: (-?\d+),", c)
            msg = ref_trap("ba", (int(m.group(1)), int(m.group(2))), directed)
        elif ".wattsStrogatz(" in c:
            m = re.search(r"vertexCount: (-?\d+), nearestNeighborCount: (-?\d+), rewiringProbability: (\S+?),", c)
            msg = ref_trap("ws", (int(m.group(1)), int(m.group(2)), float(m.group(3))), False)
        elif ".randomGeometric(" in c:
            m = re.search(r"vertexCount: (-?\d+), radius: (\S+?), dimension: (-?\d+),", c)
            msg = ref_trap("rgg", (int(m.group(1)), float(m.group(2).replace(".nan", "nan")), int(m.group(3))), False)
        elif ".randomRegular(" in c:
            m = re.search(r"vertexCount: (-?\d+), degree: (-?\d+),", c)
            msg = ref_trap("reg", (int(m.group(1)), int(m.group(2))), directed)
        elif ".randomBipartite(" in c:
            m = re.search(r"leftCount: (-?\d+), rightCount: (-?\d+), edgeProbability: (\S+?),", c)
            msg = ref_trap("bip", (int(m.group(1)), int(m.group(2)), float(m.group(3).replace(".nan", "nan"))), directed)
        elif ".stochasticBlockModel(" in c:
            m = re.search(r"blockSizes: (\[.*?\]), edgeProbabilities: (\[\[.*?\]\]),", c)
            msg = ref_trap("sbm", (eval(m.group(1)), eval(m.group(2))), directed)
        else:
            m = re.search(r"vertexCount: (-?\d+),", c)
            msg = ref_trap("tree", (int(m.group(1)),), False)
        assert msg is not None, (n, c)
        msgs.add(msg)
    assert cell(n) == "**trap**: %s" % (msgs & {cell(n)[len("**trap**: "):]}).pop(), (n, msgs)
    L = header(n, True)
    for t, c in calls:
        L.append("        await #expect(processExitsWith: .failure) {")
        L.append("            var generator = Xoshiro256StarStar(seed: 0)")
        L.append("            _ = " + c)
        L.append("        }")
    vt, _ = calls[0]
    vdirected = vt in DIRECTED
    r, draws = model(vkind if not vt.startswith("DirectedAcyclic") else ("dag_" + vkind if not vkind.startswith("dag") else vkind),
                     vargs, 0, vdirected)
    assert not isinstance(r, ref.Trap), n
    L.append("        // Without the fault: accepted.")
    L.append("        var generator = Xoshiro256StarStar(seed: 0)")
    vc = swift_call(vkind.replace("dag_", ""), vargs, vt if vt != "Tree<Int>" else "")
    L.append("        let graph = %s%s" % (vc, ".graph" if vkind == "rgg" else ""))
    L.append("        #expect(graph.vertexCount == %d && graph.edgeCount == %d)" % (r.n, len(r.edges)))
    L.append("    }")
    return L


# ---------------------------------------------------------------------------------------------
# Generator rows and statistical rows
# ---------------------------------------------------------------------------------------------

def generator_test(n):
    L = header(n)
    if n == 1:
        x = ref.Xoshiro256StarStar(state=[1, 2, 3, 4])
        v = [x.next() for _ in range(4)]
        assert cell(n) == str(v)
        L += ["        var generator = Xoshiro256StarStar(state: (1, 2, 3, 4))",
              "        #expect((0 ..< 4).map { _ in generator.next() } == %s)" % str(v).replace("]", "] as [UInt64]")]
    elif n in (3, 4, 5, 6):
        seed = int(call(n).split("seed: ")[1].split(")")[0])
        x = ref.Xoshiro256StarStar(seed)
        v = [x.next() for _ in range(4)]
        assert cell(n) == str(v)
        L += ["        var generator = Xoshiro256StarStar(seed: %d)" % seed,
              "        #expect((0 ..< 4).map { _ in generator.next() } == %s)" % str(v).replace("]", "] as [UInt64]")]
    elif n == 7:
        x = ref.Xoshiro256StarStar(5)
        v = [x.next() for _ in range(3)]
        assert cell(n) == "both %s" % v
        L += ["        var a = Xoshiro256StarStar(seed: 5)",
              "        var b = a",
              "        #expect(a == b)",
              "        let first = (0 ..< 3).map { _ in a.next() }",
              "        #expect(a != b)",
              "        let second = (0 ..< 3).map { _ in b.next() }",
              "        #expect(first == %s)" % str(v).replace("]", "] as [UInt64]"),
              "        #expect(second == first)",
              "        #expect(a == b && a.hashValue == b.hashValue)"]
    elif n == 8:
        L += ["        var generator = Xoshiro256StarStar(seed: 8)",
              "        for _ in 0 ..< 1000 {",
              "            #expect((1 ... 6).contains(Int.random(in: 1 ... 6, using: &generator)))",
              "            let x = Double.random(in: 0 ..< 1, using: &generator)",
              "            #expect(x >= 0 && x < 1)",
              "        }",
              "        #expect(Array(0 ..< 10).shuffled(using: &generator).sorted() == Array(0 ..< 10))",
              "        #expect([1, 2, 3].randomElement(using: &generator) != nil)"]
    L.append("    }")
    return L


def seeds_loop(S):
    return "for seed in 0 ..< UInt64(%d)" % S


def chi2(counts, probs, S):
    return sum((counts.get(k, 0) - S * p) ** 2 / (S * p) for k, p in probs.items())


def outcome_dict(counts):
    return "[" + ", ".join("%s: %d" % (pairs(k).replace(" as [[Int]]", ""), v) for k, v in sorted(counts.items())) + "]"


def stat_test(n):
    L = header(n)
    c = cell(n)
    i = "        "
    if n in (26, 27, 108):
        directed = n == 27
        S, nn, p = 200, (60 if n == 108 else 100), (0.1 if n == 108 else 0.05)
        if n == 108:
            tot = sum(len(ref.dag_gnp(nn, p, ref.Xoshiro256StarStar(s)).edges) for s in range(S))
        else:
            tot = sum(len(ref.gnp(nn, p, ref.Xoshiro256StarStar(s), directed).edges) for s in range(S))
        assert c.startswith("Σ %d over seeds 0..<%d" % (tot, S)), n
        pairs_ = nn * (nn - 1) // (1 if directed else 2)
        types = DAGS if n == 108 else (DIRECTED if directed else UNDIRECTED)
        for t in types:
            L.append(i + "do {")
            L.append(i + "    var total = 0")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        let graph = %s.erdosRenyi(vertexCount: %d, edgeProbability: %r, using: &generator)" % (t, nn, p))
            if n == 108:
                L.append(i + "        #expect(Array(graph.topologicalOrder) == Array(0 ..< %d), \"%s seed \\(seed)\")" % (nn, t))
                L.append(i + "        #expect(graph.edges.allSatisfy { $0.source < $0.target }, \"%s seed \\(seed)\")" % t)
            L.append(i + "        total += graph.edgeCount")
            L.append(i + "    }")
            L.append(i + "    #expect(total == %d, \"%s\")" % (tot, t))
            L.append(i + "}")
        L.append(i + "// The law: |z| ≤ 4 against E[m] = %d·%r per seed." % (pairs_, p))
        L.append(i + "let mean = Double(%d) / %d" % (tot, S))
        L.append(i + "let z = (mean - %d * %r) / (%d * %r * (1 - %r) / %d).squareRoot()" % (pairs_, p, pairs_, p, p, S))
        L.append(i + "#expect(abs(z) <= 4)")
    elif n == 28:
        S = 200
        degs = []
        for s in range(S):
            d = [0] * 100
            for u, v in ref.gnp(100, 0.05, ref.Xoshiro256StarStar(s)).edges:
                d[u] += 1
                d[v] += 1
            degs.extend(d)
        total = sum(degs)
        mean = total / len(degs)
        var = sum((x - mean) ** 2 for x in degs) / (len(degs) - 1)
        assert c.startswith("variance %.4f" % var)
        for t in UNDIRECTED:
            L.append(i + "do {")
            L.append(i + "    var degrees: [Int] = []")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        let graph = %s.erdosRenyi(vertexCount: 100, edgeProbability: 0.05, using: &generator)" % t)
            L.append(i + "        degrees += (0 ..< 100).map { graph.degree(of: $0) }")
            L.append(i + "    }")
            L.append(i + "    #expect(degrees.reduce(0, +) == %d, \"%s\")" % (total, t))
            L.append(i + "    let mean = Double(degrees.reduce(0, +)) / Double(degrees.count)")
            L.append(i + "    let variance = degrees.reduce(0.0) { $0 + (Double($1) - mean) * (Double($1) - mean) } / Double(degrees.count - 1)")
            L.append(i + "    #expect(abs(variance - %.4f) <= 0.00005, \"%s: \\(variance)\")" % (var, t))
            L.append(i + "    // The law: within 5 % of (n − 1)p(1 − p).")
            L.append(i + "    #expect(abs(variance - 99 * 0.05 * 0.95) / (99 * 0.05 * 0.95) < 0.05, \"%s\")" % t)
            L.append(i + "}")
    elif n in (29, 44, 45, 46, 102, 126):
        if n == 126:
            S, counts = 3000, {}
            for s in range(S):
                e = tuple(ref.random_regular(4, 2, ref.Xoshiro256StarStar(s)).edges)
                counts[e] = counts.get(e, 0) + 1
            probs = {((0, 1), (0, 2), (1, 3), (2, 3)): 1 / 3, ((0, 1), (0, 3), (1, 2), (2, 3)): 1 / 3,
                     ((0, 2), (0, 3), (1, 2), (1, 3)): 1 / 3}
            types, make, directed = UNDIRECTED, "randomRegular(vertexCount: 4, degree: 2, using: &generator)", False
        elif n == 29:
            S, probs, label = 4000, {}, "G(3, 0.3)"
            allp = [(0, 1), (0, 2), (1, 2)]
            for k in range(4):
                for sub in itertools.combinations(allp, k):
                    probs[tuple(sub)] = 0.3 ** k * 0.7 ** (3 - k)
            counts = {}
            for s in range(S):
                e = tuple(ref.gnp(3, 0.3, ref.Xoshiro256StarStar(s)).edges)
                counts[e] = counts.get(e, 0) + 1
            types, make, directed = UNDIRECTED, "erdosRenyi(vertexCount: 3, edgeProbability: 0.3, using: &generator)", False
        elif n in (44, 45, 46):
            nn, m, directed, S = {44: (4, 3, False, 4000), 45: (4, 5, False, 1200), 46: (3, 2, True, 3000)}[n]
            counts = {}
            for s in range(S):
                e = tuple(ref.gnm(nn, m, ref.Xoshiro256StarStar(s), directed).edges)
                counts[e] = counts.get(e, 0) + 1
            allp = list(itertools.permutations(range(nn), 2) if directed else itertools.combinations(range(nn), 2))
            probs = {tuple(sorted(sub)): 1 / math.comb(len(allp), m) for sub in itertools.combinations(allp, m)}
            types = DIRECTED if directed else UNDIRECTED
            make = "erdosRenyi(vertexCount: %d, edgeCount: %d, using: &generator)" % (nn, m)
        else:
            S = 3200
            counts = {}
            for s in range(S):
                r = ref.random_tree(4, ref.Xoshiro256StarStar(s))
                key = tuple(sorted((min(u, v), max(u, v)) for u, v in r.edges))
                counts[key] = counts.get(key, 0) + 1
            probs = {}
            for code in itertools.product(range(4), repeat=2):
                key = tuple(sorted((min(u, v), max(u, v)) for u, v in ref.prufer_decode(list(code))))
                probs[key] = 1 / 16
            types, make, directed = ["Tree<Int>"], "random(vertexCount: 4, using: &generator)", False
        x = chi2(counts, probs, S)
        df = len(probs) - 1
        bound = ref.CHI2_999[df]
        assert c == "%d outcomes over seeds 0..<%d; χ² %.2f ≤ %s (df %d, 0.999)" % (len(probs), S, x, bound, df), (n, c)
        assert set(counts) <= set(probs)
        L.append(i + "// Every outcome's count over the seeds, from the model.")
        L.append(i + "let expected: [[[Int]]: Int] = %s" % outcome_dict(counts))
        for t in types:
            L.append(i + "do {")
            L.append(i + "    var counts: [[[Int]]: Int] = [:]")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        let graph = %s.%s" % (t, make))
            if t == "Tree<Int>":
                L.append(i + "        let key = graph.edges.map { [min($0.u, $0.v), max($0.u, $0.v)] }.sorted { $0.lexicographicallyPrecedes($1) }")
            elif directed:
                L.append(i + "        let key = graph.edges.map { [$0.source, $0.target] }")
            else:
                L.append(i + "        let key = graph.edges.map { [$0.u, $0.v] }")
            L.append(i + "        counts[key, default: 0] += 1")
            L.append(i + "    }")
            L.append(i + "    #expect(counts == expected, \"%s\")" % t)
            L.append(i + "}")
        L.append(i + "// The law: χ² over the %d outcomes, each with its probability, below the 0.999 quantile." % len(probs))
        L.append(i + "let probabilities: [[[Int]]: Double] = [%s]" % ", ".join(
            "%s: %r" % (pairs(k).replace(" as [[Int]]", ""), v) for k, v in sorted(probs.items())))
        L.append(i + "let chiSquare = probabilities.reduce(0.0) { sum, outcome in")
        L.append(i + "    let observed = Double(expected[outcome.key] ?? 0), predicted = %d * outcome.value" % S)
        L.append(i + "    return sum + (observed - predicted) * (observed - predicted) / predicted")
        L.append(i + "}")
        L.append(i + "#expect(abs(chiSquare - %.2f) <= 0.005 && chiSquare <= %s, \"\\(chiSquare)\")" % (x, bound))
    elif n in (58, 59):
        S, nn, m = 50, 1000, 2
        low = 0
        for s in range(S):
            d = degrees(ref.barabasi_albert(nn, m, ref.Xoshiro256StarStar(s)))
            low += sum(1 for x in d if x == m)
        if n == 59:
            assert c.startswith("%d of %d" % (low, S * nn))
        for t in UNDIRECTED:
            L.append(i + "do {")
            if n == 59:
                L.append(i + "    var lowDegree = 0")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        let graph = %s.barabasiAlbert(vertexCount: %d, edgesPerVertex: %d, using: &generator)" % (t, nn, m))
            if n == 58:
                L.append(i + "        #expect(graph.edgeCount == %d, \"%s seed \\(seed)\")" % (m * (nn - m), t))
                L.append(i + "        #expect((0 ..< %d).map { graph.degree(of: $0) }.reduce(0, +) == %d, \"%s seed \\(seed)\")" % (nn, 2 * m * (nn - m), t))
                L.append(i + "        #expect((%d ..< %d).allSatisfy { graph.degree(of: $0) >= %d }, \"%s seed \\(seed)\")" % (m + 1, nn, m, t))
                L.append(i + "        #expect(graph.edges.allSatisfy { $0.u < $0.v }, \"%s seed \\(seed)\")" % t)
            else:
                L.append(i + "        lowDegree += (0 ..< %d).filter { graph.degree(of: $0) == %d }.count" % (nn, m))
            L.append(i + "    }")
            if n == 59:
                L.append(i + "    #expect(lowDegree == %d, \"%s\")" % (low, t))
            L.append(i + "}")
        if n == 58:
            L.append(i + "// Directed (new vertex → older vertex): the hub has no out-arc, 1…m one each, every later vertex m.")
            for t in DIRECTED:
                L.append(i + "do {")
                L.append(i + "    " + seeds_loop(S) + " {")
                L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
                L.append(i + "        let graph = %s.barabasiAlbert(vertexCount: %d, edgesPerVertex: %d, using: &generator)" % (t, nn, m))
                L.append(i + "        #expect(graph.edgeCount == %d, \"%s seed \\(seed)\")" % (m * (nn - m), t))
                L.append(i + "        #expect((0 ..< %d).map { graph.outDegree(of: $0) } == [0] + Array(repeating: 1, count: %d) + Array(repeating: %d, count: %d), \"%s seed \\(seed)\")"
                         % (nn, m, m, nn - m - 1, t))
                L.append(i + "        #expect(graph.edges.allSatisfy { $0.source > $0.target }, \"%s seed \\(seed)\")" % t)
                L.append(i + "    }")
                L.append(i + "}")
        else:
            L.append(i + "// The law: the share of degree-m vertices is 2/(m + 2) ± 0.02.")
            L.append(i + "#expect(abs(Double(%d) / %d - 2.0 / %d) < 0.02)" % (low, S * nn, m + 2))
    elif n in (72, 73):
        S, nn, k, p = 100, 200, 6, 0.2
        missing = 0
        for s in range(S):
            E = set(ref.watts_strogatz(nn, k, p, ref.Xoshiro256StarStar(s)).edges)
            missing += sum(1 for u in range(nn) for j in range(1, k // 2 + 1)
                           if (min(u, (u + j) % nn), max(u, (u + j) % nn)) not in E)
        if n == 73:
            assert c.startswith("%d of %d" % (missing, S * nn * k // 2))
        for t in UNDIRECTED:
            L.append(i + "do {")
            if n == 73:
                L.append(i + "    var gone = 0")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        let graph = %s.wattsStrogatz(vertexCount: %d, nearestNeighborCount: %d, rewiringProbability: %r, using: &generator)" % (t, nn, k, p))
            if n == 72:
                L.append(i + "        #expect(graph.edgeCount == %d, \"%s seed \\(seed)\")" % (nn * k // 2, t))
                L.append(i + "        #expect((0 ..< %d).allSatisfy { graph.degree(of: $0) >= %d }, \"%s seed \\(seed)\")" % (nn, k // 2, t))
                L.append(i + "        #expect(graph.edges.allSatisfy { $0.u < $0.v }, \"%s seed \\(seed)\")" % t)
            else:
                L.append(i + "        for u in 0 ..< %d {" % nn)
                L.append(i + "            for j in 1 ... %d where !graph.contains(edge: UndirectedEdge(u, (u + j) %% %d)) { gone += 1 }" % (k // 2, nn))
                L.append(i + "        }")
            L.append(i + "    }")
            if n == 73:
                L.append(i + "    #expect(gone == %d, \"%s\")" % (missing, t))
            L.append(i + "}")
        if n == 73:
            L.append(i + "// The law: the share of ring edges gone is p ± 0.01.")
            L.append(i + "#expect(abs(Double(%d) / %d - %r) < 0.01)" % (missing, S * nn * k // 2, p))
    elif n == 83:
        S, nn, radius = 100, 100, 0.1
        tot = sum(len(ref.random_geometric(nn, radius, ref.Xoshiro256StarStar(s)).edges) for s in range(S))
        assert c.startswith("Σ %d over seeds 0..<%d" % (tot, S))
        for t in UNDIRECTED:
            L.append(i + "do {")
            L.append(i + "    var total = 0")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        total += %s.randomGeometric(vertexCount: %d, radius: %r, using: &generator).graph.edgeCount" % (t, nn, radius))
            L.append(i + "    }")
            L.append(i + "    #expect(total == %d, \"%s\")" % (tot, t))
            L.append(i + "}")
        L.append(i + "// The law: |z| ≤ 4 against C(n, 2)(πr² − 8r³/3 + r⁴/2), with the variance bounded by pairs·q·(1 + 2(n − 2)q).")
        L.append(i + "let q = Double.pi * 0.01 - 8 * 0.001 / 3 + 0.0001 / 2")
        L.append(i + "let expectedMean = 4950 * q")
        L.append(i + "let z = (Double(%d) / %d - expectedMean) / (4950 * q * (1 + 2 * 98 * q) / %d).squareRoot()" % (tot, S, S))
        L.append(i + "#expect(abs(z) <= 4)")
    elif n == 93:
        S = 200
        sizes, P = [30, 20, 50], [[0.2, 0.01, 0.02], [0.01, 0.3, 0.005], [0.02, 0.005, 0.1]]
        tot = sum(len(ref.sbm(sizes, P, ref.Xoshiro256StarStar(s)).edges) for s in range(S))
        assert c.startswith("Σ %d over seeds 0..<%d" % (tot, S))
        for t in UNDIRECTED:
            L.append(i + "do {")
            L.append(i + "    var total = 0")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        total += %s.stochasticBlockModel(blockSizes: %r, edgeProbabilities: %r, using: &generator).edgeCount" % (t, sizes, P))
            L.append(i + "    }")
            L.append(i + "    #expect(total == %d, \"%s\")" % (tot, t))
            L.append(i + "}")
        L.append(i + "// The law: |z| ≤ 4 against Σ pairs(i, j)·p(i, j).")
        L.append(i + "let sizes = %r, p = %r" % (sizes, P))
        L.append(i + "var mean = 0.0, variance = 0.0")
        L.append(i + "for a in 0 ..< 3 {")
        L.append(i + "    for b in a ..< 3 {")
        L.append(i + "        let count = Double(a == b ? sizes[a] * (sizes[a] - 1) / 2 : sizes[a] * sizes[b])")
        L.append(i + "        mean += count * p[a][b]")
        L.append(i + "        variance += count * p[a][b] * (1 - p[a][b])")
        L.append(i + "    }")
        L.append(i + "}")
        L.append(i + "#expect(abs((Double(%d) / %d - mean) / (variance / %d).squareRoot()) <= 4)" % (tot, S, S))
    elif n == 125:
        S, nn, d = 50, 100, 3
        for s in range(S):
            r = ref.random_regular(nn, d, ref.Xoshiro256StarStar(s))
            assert len(r.edges) == nn * d // 2 and degrees(r) == [d] * nn
        for t in UNDIRECTED:
            L.append(i + "do {")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        let graph = %s.randomRegular(vertexCount: %d, degree: %d, using: &generator)" % (t, nn, d))
            L.append(i + "        #expect(graph.edgeCount == %d, \"%s seed \\(seed)\")" % (nn * d // 2, t))
            L.append(i + "        #expect((0 ..< %d).allSatisfy { graph.degree(of: $0) == %d }, \"%s seed \\(seed)\")" % (nn, d, t))
            L.append(i + "        #expect(graph.edges.allSatisfy { $0.u < $0.v }, \"%s seed \\(seed)\")" % t)
            L.append(i + "        #expect(Set(graph.edges.map { [$0.u, $0.v] }).count == %d, \"%s seed \\(seed)\")" % (nn * d // 2, t))
            L.append(i + "    }")
            L.append(i + "}")
        L.append(i + "// Directed: both arcs of every edge, so in- and out-degree d everywhere.")
        for t in DIRECTED:
            L.append(i + "do {")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        let graph = %s.randomRegular(vertexCount: %d, degree: %d, using: &generator)" % (t, nn, d))
            L.append(i + "        #expect(graph.edgeCount == %d, \"%s seed \\(seed)\")" % (nn * d, t))
            L.append(i + "        #expect((0 ..< %d).allSatisfy { graph.outDegree(of: $0) == %d }, \"%s seed \\(seed)\")" % (nn, d, t))
            L.append(i + "        #expect(graph.edges.allSatisfy { graph.contains(edge: DirectedEdge(from: $0.target, to: $0.source)) }, \"%s seed \\(seed)\")" % t)
            L.append(i + "    }")
            L.append(i + "}")
    elif n in (140, 141):
        directed = n == 141
        S, a, b, p = 200, 30, 20, 0.1
        tot = sum(len(ref.random_bipartite(a, b, p, ref.Xoshiro256StarStar(s), directed).edges) for s in range(S))
        assert c.startswith("Σ %d over seeds 0..<%d" % (tot, S)), n
        pairs_ = a * b * (2 if directed else 1)
        for t in (DIRECTED if directed else UNDIRECTED):
            L.append(i + "do {")
            L.append(i + "    var total = 0")
            L.append(i + "    " + seeds_loop(S) + " {")
            L.append(i + "        var generator = Xoshiro256StarStar(seed: seed)")
            L.append(i + "        let graph = %s.randomBipartite(leftCount: %d, rightCount: %d, edgeProbability: %r, using: &generator)" % (t, a, b, p))
            L.append(i + "        #expect(graph.edges.allSatisfy { (%s < %d) != (%s < %d) }, \"%s seed \\(seed)\")"
                     % ((("$0.source", a, "$0.target", a) if directed else ("$0.u", a, "$0.v", a)) + (t,)))
            L.append(i + "        total += graph.edgeCount")
            L.append(i + "    }")
            L.append(i + "    #expect(total == %d, \"%s\")" % (tot, t))
            L.append(i + "}")
        L.append(i + "// The law: |z| ≤ 4 against E[m] = %d·%r per seed." % (pairs_, p))
        L.append(i + "let mean = Double(%d) / %d" % (tot, S))
        L.append(i + "let z = (mean - %d * %r) / (%d * %r * (1 - %r) / %d).squareRoot()" % (pairs_, p, pairs_, p, p, S))
        L.append(i + "#expect(abs(z) <= 4)")
    elif n == 103:
        S, nn = 50, 200
        L.append(i + seeds_loop(S) + " {")
        L.append(i + "    var generator = Xoshiro256StarStar(seed: seed)")
        L.append(i + "    let tree = Tree<Int>.random(vertexCount: %d, using: &generator)" % nn)
        L.append(i + "    #expect(tree.vertexCount == %d && tree.edgeCount == %d, \"seed \\(seed)\")" % (nn, nn - 1))
        L.append(i + "    // Connected: a search from 0 reaches every vertex.")
        L.append(i + "    var seen = Set([0]), stack = [0]")
        L.append(i + "    while let v = stack.popLast() {")
        L.append(i + "        for w in tree.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }")
        L.append(i + "    }")
        L.append(i + "    #expect(seen.count == %d, \"seed \\(seed)\")" % nn)
        L.append(i + "    // The code: n − 2 draws below(n) on the same stream, CPython's rejection on the top bits.")
        L.append(i + "    var replay = Xoshiro256StarStar(seed: seed)")
        L.append(i + "    var code: [Int] = []")
        L.append(i + "    let bits = Int.bitWidth - %d.leadingZeroBitCount" % nn)
        L.append(i + "    while code.count < %d {" % (nn - 2))
        L.append(i + "        let r = Int(replay.next() >> UInt64(64 - bits))")
        L.append(i + "        if r < %d { code.append(r) }" % nn)
        L.append(i + "    }")
        L.append(i + "    #expect(replay == generator, \"seed \\(seed)\")")
        L.append(i + "    #expect(tree.pruferSequence == code, \"seed \\(seed)\")")
        L.append(i + "    #expect((0 ..< %d).allSatisfy { v in tree.degree(of: v) == 1 + code.filter { $0 == v }.count }, \"seed \\(seed)\")" % nn)
        L.append(i + "}")
    else:
        raise AssertionError(n)
    L.append("    }")
    return L


def test_for(n):
    if is_trap(n):
        return trap_test(n)
    if group(n) == "Generator":
        return generator_test(n)
    if n in EXACT:
        return exact_test(n)
    return stat_test(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups, stats=None):
    out = [n for n in range(1, N + 1) if group(n) in groups and not is_trap(n)]
    if stats is not None:
        out = [n for n in out if (n in EXACT or group(n) == "Generator") != stats]
    return out


STAT_GROUPS = ("ErdosRenyiGnp", "ErdosRenyiGnm", "BarabasiAlbert", "WattsStrogatz", "RandomGeometric",
               "StochasticBlockModel", "RandomTree", "RandomDAG", "RandomRegular", "RandomBipartite")
FILES = [
    ("GeneratorTests.swift", "RandomGraphs generator", ids("Generator"),
     "The generator (catalog RG-001 – RG-008): xoshiro256** from a given state reproduces rand_xoshiro's\n"
     "// test vector; init(seed:) fills the state from SplitMix64; a copy replays the stream; the\n"
     "// standard library's random APIs accept it."),
    ("ErdosRenyiTests.swift", "RandomGraphs Erdős–Rényi exact outputs", ids("ErdosRenyiGnp", "ErdosRenyiGnm", stats=False),
     "G(n, p) and G(n, m) for fixed seeds (catalog RG-009 – RG-039): Batagelj–Brandes skipping and\n"
     "// the rejection loop, draw for draw, on every conformer, with the number of draws."),
    ("PreferentialAttachmentTests.swift", "RandomGraphs Barabási–Albert and Watts–Strogatz exact outputs",
     ids("BarabasiAlbert", "WattsStrogatz", stats=False),
     "Barabási–Albert and Watts–Strogatz for fixed seeds (catalog RG-047 – RG-068, RG-109,\n"
     "// RG-142, RG-144): the repeated-nodes list with targets appended in ascending order, and the ring rewiring."),
    ("GeometricBlockModelTests.swift", "RandomGraphs random geometric graphs and block models exact outputs",
     ids("RandomGeometric", "StochasticBlockModel", stats=False),
     "Random geometric graphs and stochastic block models for fixed seeds (catalog RG-074 – RG-094,\n"
     "// RG-110 – RG-113, RG-145): positions vertex by vertex, edges by squared distance; block pairs skipped\n"
     "// geometrically."),
    ("RandomTreeDAGTests.swift", "RandomGraphs random trees and DAGs exact outputs", ids("RandomTree", "RandomDAG", stats=False),
     "Random trees and random DAGs for fixed seeds (catalog RG-095 – RG-106): a Prüfer code of n − 2\n"
     "// draws, decoded by Tree(pruferSequence:); G(n, p) and G(n, m) oriented upward, with 0..<n as the\n"
     "// topological order."),
    ("RegularBipartiteTests.swift", "RandomGraphs random regular and random bipartite exact outputs",
     ids("RandomRegular", "RandomBipartite", stats=False),
     "Random regular and random bipartite graphs for fixed seeds (catalog RG-114 – RG-135, RG-143): the\n"
     "// stub pairing with its repair rounds, and Batagelj–Brandes skipping over the left–right pairs."),
    ("StatisticalLawTests.swift", "RandomGraphs statistical laws", ids(*STAT_GROUPS, stats=True),
     "Statistical laws (catalog rows with seeds 0..<S): the exact aggregate of the pinned procedure over\n"
     "// the seeds on every conformer of the row's kind, then the law with api.md's tolerance."),
    ("RandomGraphPreconditionTests.swift", "RandomGraphs preconditions", [n for n in range(1, N + 1) if is_trap(n)],
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test), on every\n"
     "// conformer the rule covers. A valid neighbour of the call then runs in this process."),
]
IMPORTS = {"AdjacencyListModule": ("AdjacencyList<", "UndirectedAdjacencyList<"), "AdjacencyMatrixModule": ("AdjacencyMatrix",),
           "CompressedSparseRowModule": ("CompressedSparseRow",), "Multigraphs": ("Pseudograph<", "Multigraph<"),
           "StableGraphs": ("StableDirectedGraph",), "Trees": ("Tree<",), "DirectedAcyclicGraphModule": ("DirectedAcyclicGraph<",),
           "NamedGraphs": (".completeBipartite(",), "BipartiteGraphs": ("BipartiteGraph<",)}


def write(fname, suite, rws, comment):
    body = []
    for k, n in enumerate(rws):
        if k:
            body.append("")
        body += test_for(n)
    text = "\n".join(body)
    imports = ["GraphProtocols", "RandomGraphs", "Testing"]
    for module, needles in IMPORTS.items():
        if any(x in text for x in needles):
            imports.append(module)
    pre = fname == "RandomGraphPreconditionTests.swift"
    if pre:
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    out = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, ", .tags(.precondition)" if pre else ""), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
seen = []
for fname, suite, rws, comment in FILES:
    k = write(fname, suite, rws, comment)
    print(fname, k)
    total += k
    rows_total += len(rws)
    seen += rws
assert sorted(seen) == list(range(1, N + 1)) and total == N, (sorted(set(range(1, N + 1)) - set(seen)), total)
print("catalog rows", rows_total, "tests", total)
