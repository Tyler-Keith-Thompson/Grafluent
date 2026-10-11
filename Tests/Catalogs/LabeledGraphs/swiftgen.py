"""Writes the catalog-row test files of Tests/LabeledGraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 python3 Tests/Catalogs/LabeledGraphs/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/LabeledGraphsTests

First checks that ref.py's model reproduces cases.md byte for byte, then re-runs every row on the
model (ref.py's port of the storage, checked against its NetworkX specification and the laws after
every call), asserts that each value matches its catalog cell, and writes one @Test per row. Each
call's result is checked; after a mutation that another mutation follows, the test checks the
labels and the edges with their positions; the final state is written out in full: every label's
index both ways, every row by label and by index (empty ones included, where the catalog omits
them), every position's ends, the base, and the bounds. Rows that read `hashes()` also run on a
label type whose `hash(into:)` counts, with 16 isolated labels appended so that the OrderedSet has
a hash table (it scans linearly up to 15 elements). Hand-written exit tests spliced into the
precondition file: extra_traps.swift.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "LabeledGraphsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and the structured arguments of every row
# ---------------------------------------------------------------------------------------------
MAKE, SPEC, CALLS, PAIRS = {}, {}, {}, {}
_case, _labeled, _builder = ref.case, ref.labeled, ref.builder


def _rec_labeled(kind, vs, es):
    mk, t = _labeled(kind, vs, es)
    mk.spec = (kind, vs.split() if vs else [], ref.E(es))
    # The two graphs of an Equality or Hashing row are built just before the row is appended.
    PAIRS.setdefault(len(ref.ROWS) + 1, []).append(mk.spec)
    return mk, t


def _rec_builder(kind, statements):
    mk, t = _builder(kind, statements)
    toks = statements.split()
    mk.spec = (kind, [x for x in toks if ">" not in x], [tuple(x.split(">")) for x in toks if ">" in x])
    mk.statements = toks
    return mk, t


def _rec_case(group, title, make, input_text, calls=(), show_state=True):
    n = len(ref.ROWS) + 1
    MAKE[n], SPEC[n], CALLS[n] = make, getattr(make, "spec", None), list(calls)
    BUILDER[n] = getattr(make, "statements", None)
    _case(group, title, make, input_text, calls, show_state)


ref.labeled, ref.case, ref.builder = _rec_labeled, _rec_case, _rec_builder
BUILDER = {}
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| LG-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 96
EQ_ROWS = [n for n in range(1, N + 1) if CELLS[n][1] in ("Equality", "Hashing")]
assert EQ_ROWS == list(range(89, 97)) and sorted(MAKE) == list(range(1, 89))
EQ_SPEC = {n: tuple(PAIRS[n]) for n in EQ_ROWS}
assert all(len(p) == 2 for p in EQ_SPEC.values())


def title(n): return CELLS[n][2]
def inp(n): return CELLS[n][3]
def cell(n): return CELLS[n][4]
def is_trap(n): return "**trap**" in cell(n)


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------
BASE = {"CSR": "CompressedSparseRow", "M": "AdjacencyMatrix", "U": "AdjacencyMatrix"}
MUTATING = {"insert", "insert(edge:)", "insert(safe:)", "remove(edge:)", "removeAllEdges", "removeAll",
            "removeEdges(from:)", "removeEdges(to:)", "removeEdges(incidentTo:)", "transposed"}


def s(x): return json.dumps(x, ensure_ascii=False)
def strs(xs): return "[" + ", ".join(s(x) for x in xs) + "]" if xs else "[] as [String]"
def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "]" if xs else "[] as [Int]"
def str_pairs(ps): return "[" + ", ".join(strs(list(p)) for p in ps) + "]" if ps else "[] as [[String]]"
def int_pairs(ps): return "[" + ", ".join(ints(list(p)) for p in ps) + "]" if ps else "[] as [[Int]]"
def dedge(a, b): return "DirectedEdge(from: %s, to: %s)" % (s(a), s(b))
def dedges(E): return "[" + ", ".join(dedge(a, b) for a, b in E) + "]" if E else "[] as [DirectedEdge<String>]"
def iedges(E): return "[" + ", ".join("DirectedEdge(from: %d, to: %d)" % e for e in E) + "]" if E else "[] as [DirectedEdge<Int>]"
def opt(x): return "nil" if x is None else str(x)


def poslit(ps, kind):
    return ints(ps) if kind == "CSR" else int_pairs(ps)


def posexpr(expr, kind):
    return "Array(%s)" % expr if kind == "CSR" else "%s.map { [$0.source, $0.target] }" % expr


def poscmp(expr, ps, kind):
    return "#expect(%s == %s)" % (posexpr(expr, kind), poslit(ps, kind))


def cellvar(p):
    return "cell%d%d" % p


def cell_decl(p):
    """A matrix position: the cell (source, target), taken from a matrix that has that one edge."""
    return "let %s = AdjacencyMatrix(vertexCount: %d, edges: [DirectedEdge(from: %d, to: %d)]).edges.startIndex" % (
        cellvar(p), max(p) + 1, p[0], p[1])


def posarg(p):
    return cellvar(p) if isinstance(p, tuple) else str(p)


def cells_of(calls):
    out = []
    for c in calls:
        for a in c[1:]:
            if isinstance(a, tuple) and a not in out:
                out.append(a)
    return out


def construct(kind, V, E, mutable, var="graph"):
    return "%s %s = LabeledGraph<String, %s>(vertices: %s, edges: %s)" % (
        "var" if mutable else "let", var, BASE[kind], strs(V), dedges(E))


def construct_builder(kind, statements, ind):
    """The result-builder spelling: one statement per line, a bare label or a DirectedEdge."""
    lines = [ind + "let graph = LabeledGraph<String, %s> {" % BASE[kind]]
    for t in statements:
        lines.append(ind + "    " + (dedge(*t.split(">")) if ">" in t else s(t)))
    return lines + [ind + "}"]


# ---------------------------------------------------------------------------------------------
# State: everything the model knows, written out
# ---------------------------------------------------------------------------------------------

def directed_state(g, kind, var="graph", short=False):
    """g: ref.Labeled over CSR or Matrix."""
    L, b = g.labels, g.base
    n = len(L)
    E = g.edges()
    ps = [p for p, _ in E]
    arcs = [list(e) for _, e in E]
    out = ["#expect(Array(%s.vertices) == %s)" % (var, strs(L)),
           "#expect(%s.edges.map { [$0.source, $0.target] } == %s)" % (var, str_pairs(arcs)),
           poscmp("%s.edges.indices" % var, ps, kind)]
    if short:
        return out
    out += ["#expect(%s.vertexCount == %d && %s.edgeCount == %d && %s.edges.count == %d)" % (var, n, var, len(E), var, len(E)),
            "#expect(%s.vertexIndexBound == %d)" % (var, n),
            "#expect(%s.edgeIndexBound == %s)" % (var, opt(b.edge_index_bound)),
            "#expect(%s.vertices.map { %s.vertexIndex(of: $0) } == %s)" % (var, var, ints(list(range(n)))),
            "#expect((0 ..< %d).map { %s.vertex(atIndex: $0) } == %s)" % (n, var, strs(L))]
    if E:
        out.append("#expect(%s.edges.indices.map { [%s.source(ofEdgeAt: $0), %s.target(ofEdgeAt: $0)] } == %s)" % (var, var, var, str_pairs(arcs)))
        out.append("#expect(%s.edges.indices.map { %s.edges[$0] } == %s)" % (var, var, dedges([tuple(a) for a in arcs])))
    out.append("#expect(%s.base.vertexCount == %d)" % (var, n))
    out.append("#expect(Array(%s.base.edges) == %s)" % (var, iedges([b.arc(p) for p in ps])))
    for i, l in enumerate(L):
        o = b.out_edges(i)
        succ = b.successor_indices(i)
        out.append("#expect(%s.contains(%s))" % (var, s(l)))
        out.append("#expect(Array(%s.successors(of: %s)) == %s)" % (var, s(l), strs([L[j] for j in succ])))
        out.append(poscmp("%s.outEdges(of: %s)" % (var, s(l)), o, kind))
        out.append("#expect(%s.outDegree(of: %s) == %d)" % (var, s(l), len(o)))
        out.append("#expect(Array(%s.successorIndices(ofIndex: %d)) == %s)" % (var, i, ints(succ)))
        out.append(poscmp("%s.outEdges(ofIndex: %d)" % (var, i), o, kind))
        if kind == "M":
            ie = b.in_edges(i)
            pred = b.predecessor_indices(i)
            out.append("#expect(Array(%s.predecessors(of: %s)) == %s)" % (var, s(l), strs([L[j] for j in pred])))
            out.append(poscmp("%s.inEdges(of: %s)" % (var, s(l)), ie, kind))
            out.append("#expect(%s.inDegree(of: %s) == %d && %s.degree(of: %s) == %d)" % (var, s(l), len(ie), var, s(l), len(ie) + len(o)))
            out.append("#expect(Array(%s.predecessorIndices(ofIndex: %d)) == %s)" % (var, i, ints(pred)))
            out.append(poscmp("%s.inEdges(ofIndex: %d)" % (var, i), ie, kind))
    for a, c in arcs:
        out.append("#expect(%s.contains(edge: %s))" % (var, dedge(a, c)))
    if kind == "CSR" and E:
        out.append("#expect(%s.edges.indices.map { %s.edgeIndex(of: $0) } == %s)" % (var, var, ints(list(range(len(E))))))
    return out


def view_state(g, var="view"):
    """g: ref.Labeled over UView."""
    L, u = g.labels, g.base
    n = len(L)
    E = g.edges()
    ps = [p for p, _ in E]
    arcs = [list(e) for _, e in E]
    out = ["#expect(Array(%s.vertices) == %s)" % (var, strs(L)),
           "#expect(%s.edges.map { [$0.u, $0.v] } == %s)" % (var, str_pairs(arcs)),
           poscmp("%s.edges.indices" % var, ps, "M"),
           "#expect(%s.vertexCount == %d && %s.edgeCount == %d)" % (var, n, var, len(E)),
           "#expect(%s.vertexIndexBound == %d && %s.edgeIndexBound == nil)" % (var, n, var),
           "#expect(%s.vertices.map { %s.vertexIndex(of: $0) } == %s)" % (var, var, ints(list(range(n)))),
           "#expect((0 ..< %d).map { %s.vertex(atIndex: $0) } == %s)" % (n, var, strs(L))]
    if E:
        out.append("#expect(%s.edges.indices.map { %s.oppositeVertex(to: %s.edges[$0].u, acrossEdgeAt: $0) } == %s)"
                   % (var, var, var, strs([e[1] for e in arcs])))
    for i, l in enumerate(L):
        inc = u.incident_edges(i)
        nb = u.neighbor_indices(i)
        out.append("#expect(Array(%s.neighbors(of: %s)) == %s)" % (var, s(l), strs([L[j] for j in nb])))
        out.append(poscmp("%s.incidentEdges(of: %s)" % (var, s(l)), inc, "M"))
        out.append("#expect(%s.degree(of: %s) == %d)" % (var, s(l), len(inc)))
        out.append("#expect(Array(%s.neighborIndices(ofIndex: %d)) == %s)" % (var, i, ints(nb)))
        out.append(poscmp("%s.incidentEdges(ofIndex: %d)" % (var, i), inc, "M"))
    for a, c in arcs:
        out.append("#expect(%s.contains(edge: UndirectedEdge(%s, %s)) && %s.contains(edge: UndirectedEdge(%s, %s)))" % (var, s(c), s(a), var, s(a), s(c)))
    return out


def state(g, kind, ind="        ", short=False):
    if kind == "U":
        d = ref.Labeled(g.base.m, g.labels)
        lines = directed_state(d, "M", short=short) + ([] if short else ["// The undirected view."] + view_state(g))
    else:
        lines = directed_state(g, kind, short=short)
    return [ind + l for l in lines]


# ---------------------------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------------------------

def child_call(kind, call):
    """The call as a statement for a child process."""
    name, *a = call
    v = "view" if kind == "U" else "graph"
    return {
        "successors": lambda: "_ = Array(graph.successors(of: %s))" % s(a[0]),
        "outDegree": lambda: "_ = graph.outDegree(of: %s)" % s(a[0]),
        "predecessors": lambda: "_ = Array(graph.predecessors(of: %s))" % s(a[0]),
        "vertexIndex": lambda: "_ = graph.vertexIndex(of: %s)" % s(a[0]),
        "vertex(atIndex:)": lambda: "_ = graph.vertex(atIndex: %d)" % a[0],
        "source": lambda: "_ = graph.source(ofEdgeAt: %s)" % posarg(a[0]),
        "edgeIndex": lambda: "_ = graph.edgeIndex(of: %s)" % posarg(a[0]),
        "descendants": lambda: "_ = graph.descendants(of: %s)" % s(a[0]),
        "oppositeVertex": lambda: "_ = %s.oppositeVertex(to: %s, acrossEdgeAt: %s)" % (v, s(a[0]), posarg(a[1])),
        "neighbors": lambda: "_ = Array(%s.neighbors(of: %s))" % (v, s(a[0])),
    }[name]()


def call_lines(g, kind, call, ind="        "):
    """The call's result on the model, and the Swift lines that check it."""
    r = ref.run_call(g, call)
    ref.check(g)
    name, *a = call
    v = "view" if kind == "U" else "graph"
    pk = "M" if kind == "U" else kind

    def ex(text): return [ind + "#expect(%s)" % text]

    if name in ("successors", "predecessors"):
        return r, ex("Array(graph.%s(of: %s)) == %s" % (name, s(a[0]), strs(r)))
    if name in ("outEdges", "inEdges"):
        return r, [ind + poscmp("graph.%s(of: %s)" % (name, s(a[0])), r, pk)]
    if name in ("outDegree", "inDegree", "degree"):
        return r, ex("%s.%s(of: %s) == %d" % (v if name == "degree" else "graph", name, s(a[0]), r))
    if name == "neighbors":
        return r, ex("Array(view.neighbors(of: %s)) == %s" % (s(a[0]), strs(r)))
    if name == "incidentEdges":
        return r, [ind + poscmp("view.incidentEdges(of: %s)" % s(a[0]), r, "M")]
    if name == "oppositeVertex":
        return r, ex("view.oppositeVertex(to: %s, acrossEdgeAt: %s) == %s" % (s(a[0]), posarg(a[1]), s(r)))
    if name == "contains":
        return r, ex("%sgraph.contains(%s)" % ("" if r else "!", s(a[0])))
    if name == "contains(edge:)":
        e = "UndirectedEdge(%s, %s)" % (s(a[0]), s(a[1])) if kind == "U" else dedge(*a)
        return r, ex("%s%s.contains(edge: %s)" % ("" if r else "!", v, e))
    if name in ("vertexIndex", "vertexIndex(safe:)"):
        return r, ex("graph.vertexIndex(%s: %s) == %s" % ("of" if name == "vertexIndex" else "safe", s(a[0]), opt(r)))
    if name == "vertex(atIndex:)":
        return r, ex("graph.vertex(atIndex: %d) == %s" % (a[0], s(r)))
    if name in ("successorIndices(ofIndex:)", "predecessorIndices(ofIndex:)"):
        return r, ex("Array(graph.%s %d)) == %s" % (name[:-2] + ":", a[0], ints(r)))
    if name == "neighborIndices(ofIndex:)":
        return r, ex("Array(view.neighborIndices(ofIndex: %d)) == %s" % (a[0], ints(r)))
    if name == "edges[p]":
        return r, ex("graph.edges[%s] == %s" % (posarg(a[0]), dedge(*r)))
    if name in ("source", "target"):
        return r, ex("graph.%s(ofEdgeAt: %s) == %s" % (name, posarg(a[0]), s(r)))
    if name == "edgeIndex":
        return r, ex("graph.edgeIndex(of: %s) == %d" % (posarg(a[0]), r))
    if name in ("successors(safe:)", "predecessors(safe:)"):
        return r, ex("graph.%s %s).map { Array($0) } == %s" % (name[:-2] + ":", s(a[0]), "nil" if r is None else strs(r)))
    if name in ("outEdges(safe:)", "inEdges(safe:)"):
        m = ".map { Array($0) }" if pk == "CSR" else ".map { $0.map { [$0.source, $0.target] } }"
        return r, ex("graph.%s %s)%s == %s" % (name[:-2] + ":", s(a[0]), m, "nil" if r is None else poslit(r, pk)))
    if name in ("outDegree(safe:)", "inDegree(safe:)", "degree(safe:)"):
        return r, ex("graph.%s %s) == %s" % (name[:-2] + ":", s(a[0]), opt(r)))
    if name == "descendants":
        return r, ex("graph.descendants(of: %s) == %s" % (s(a[0]), "Set(%s)" % strs(sorted(r)) if r else "Set<String>()"))
    if name == "topologicalSort":
        return r, ex("graph.topologicalSort() == %s" % ("nil" if r is None else strs(r)))
    if name == "insert":
        return r, [ind + "do {", ind + "    let result = graph.insert(%s)" % s(a[0]),
                   ind + "    #expect(%sresult.inserted)" % ("" if r[0] else "!"),
                   ind + "    #expect(result.memberAfterInsert == %s)" % s(r[1]), ind + "}"]
    if name in ("insert(edge:)", "insert(safe:)"):
        label = "edge" if name == "insert(edge:)" else "safe"
        if r is None:
            return r, [ind + "#expect(graph.insert(safe: %s) == nil)" % dedge(*a)]
        q = "?" if label == "safe" else ""
        return r, [ind + "do {", ind + "    let result = graph.insert(%s: %s)" % (label, dedge(*a)),
                   ind + "    #expect(result%s.inserted == %s)" % (q, "true" if r[0] else "false"),
                   ind + "    #expect(result%s.memberAfterInsert == %s)" % (q, dedge(*r[1])), ind + "}"]
    if name == "remove(edge:)":
        return r, ex("graph.remove(edge: %s) == %s" % (dedge(*a), "nil" if r is None else dedge(*r)))
    if name in ("removeAllEdges", "removeAll"):
        return r, [ind + "graph.%s()" % name]
    if name in ("removeEdges(from:)", "removeEdges(to:)", "removeEdges(incidentTo:)"):
        return r, ex("graph.%s %s) == %d" % (name[:-2] + ":", s(a[0]), r))
    if name == "transposed":
        return r, [ind + "graph = graph.transposed()"]
    if name == "hashes":
        return r, [ind + "// hashes() is %d here: see the counted copy below." % r]
    raise ValueError(call)


# ---------------------------------------------------------------------------------------------
# Hash counting (rows that read hashes())
# ---------------------------------------------------------------------------------------------
PADS = ["pad%d" % k for k in range(16)]

COUNTED = [
    "// Label hashes, counted by a label whose hash(into:) counts. OrderedSet hashes only from 16",
    "// elements (up to 15 it scans), so 16 isolated labels follow the catalog's; they come after",
    "// every index above and change none of them.",
    "final class Tally {",
    "    var hashes = 0",
    "    var comparisons = 0",
    "}",
    "struct Counted: Hashable {",
    "    let name: String",
    "    let tally: Tally",
    "    static func == (lhs: Counted, rhs: Counted) -> Bool {",
    "        lhs.tally.comparisons += 1",
    "        return lhs.name == rhs.name",
    "    }",
    "    func hash(into hasher: inout Hasher) {",
    "        tally.hashes += 1",
    "        hasher.combine(name)",
    "    }",
    "}",
    "let tally = Tally()",
    "func label(_ name: String) -> Counted { Counted(name: name, tally: tally) }",
]


def counted_lines(n, kind, g0, calls, ind="        "):
    """g0: the model as built (before any call)."""
    L = g0.labels
    E = [e for _, e in g0.edges()]
    view = kind == "U"
    lines = list(COUNTED)
    lines.append("let pads = (0 ..< 16).map { \"pad\\($0)\" }")
    build = "LabeledGraph<Counted, %s>(vertices: (%s + pads).map(label), edges: %s.map { DirectedEdge(from: label($0[0]), to: label($0[1])) })" % (
        BASE[kind], strs(L), str_pairs([list(e) for e in E]))
    lines.append("let counted = " + build + (".undirected" if view else ""))
    lines.append("tally.hashes = 0")
    lines.append("tally.comparisons = 0")
    later = []
    k = 0
    for c in calls:
        name, *a = c
        k += 1
        if name == "hashes":
            r = ref.run_call(G_SHADOW[n], c)
            if any(x[0] == "descendants" for x in calls):
                lines += ["// descendants(of:) looks its source up once (vertexIndex(of:), which also checks it is a",
                          "// vertex) and hashes each vertex it reaches into its Set result, which a fresh Set built",
                          "// in the same order hashes the same number of times. Nothing is hashed per edge.",
                          "let hashes%d = tally.hashes" % k,
                          "tally.hashes = 0",
                          "var rebuilt = Set<Counted>()",
                          "for name in %s { rebuilt.insert(label(name)) }" % strs(DESC_ORDER[n]),
                          "#expect(hashes%d == %d + tally.hashes)" % (k, r)]
            else:
                lines.append("#expect(tally.hashes == %d)" % r)
                if r == 0:
                    lines.append("#expect(tally.comparisons == 0)")
            continue
        r = ref.run_call(G_SHADOW[n], c)
        x = "r%d" % k
        if name == "successorIndices(ofIndex:)":
            lines.append("let %s = Array(counted.successorIndices(ofIndex: %d))" % (x, a[0]))
            later.append("#expect(%s == %s)" % (x, ints(r)))
        elif name == "neighborIndices(ofIndex:)":
            lines.append("let %s = Array(counted.neighborIndices(ofIndex: %d))" % (x, a[0]))
            later.append("#expect(%s == %s)" % (x, ints(r)))
        elif name == "vertex(atIndex:)":
            lines.append("let %s = counted.vertex(atIndex: %d).name" % (x, a[0]))
            later.append("#expect(%s == %s)" % (x, s(r)))
        elif name == "edges[p]":
            lines.append("let %s = counted.edges[%s]" % (x, posarg(a[0])))
            later.append("#expect([%s.source.name, %s.target.name] == %s)" % (x, x, strs(list(r))))
        elif name in ("successors", "neighbors"):
            lines.append("let %s = Array(counted.%s(of: label(%s))).map(\\.name)" % (x, name, s(a[0])))
            later.append("#expect(%s == %s)" % (x, strs(r)))
        elif name == "descendants":
            lines.append("let %s = counted.descendants(of: label(%s))" % (x, s(a[0])))
            later.append("#expect(Set(%s.map(\\.name)) == Set(%s))" % (x, strs(sorted(r))))
        elif name == "transposed":
            lines.append("let %s = counted.transposed()" % x)
            later.append("#expect(%s.base == counted.base.transposed())" % x)
            later.append("#expect(%s.vertices == counted.vertices)" % x)
        elif name == "topologicalSort":
            lines.append("let %s = counted.topologicalSort()" % x)
            later.append("// The padding is isolated; without it the order is the catalog's.")
            later.append("#expect(%s?.map(\\.name).filter { !$0.hasPrefix(\"pad\") } == %s)" % (x, strs(r)))
        else:
            raise ValueError(c)
    lines += later
    return [ind + l for l in lines]


G_SHADOW, DESC_ORDER = {}, {}

# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

def header(n, tags=()):
    return ['    @Test("LG-%03d %s"%s)' % (n, title(n), (", .tags(%s)" % ", ".join(tags)) if tags else "")]


BASE_INIT = {
    16: ("CSR", "LabeledGraph(CompressedSparseRow(vertexCount: 3, edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2)]), labels: [\"x\", \"y\", \"z\"])"),
    17: ("M", "LabeledGraph(AdjacencyMatrix(vertexCount: 2, edges: [DirectedEdge(from: 1, to: 0)]), labels: [\"u\", \"v\"])"),
    24: ("M", "LabeledGraph(AdjacencyMatrix(), labels: [] as [String])"),
}


def alternatives(n, kind, V, E, g):
    """The other initializers, on the construction rows they fit: the same state."""
    if CELLS[n][1] != "Construction":
        return []
    t = BASE[kind]
    alts = []
    if not V and not E:
        alts.append("LabeledGraph<String, %s>()" % t)
    if not E:
        alts.append("LabeledGraph<String, %s>(vertices: %s)" % (t, strs(V)))
    if not V:
        alts.append("LabeledGraph<String, %s>(edges: %s)" % (t, dedges(E)))
    if n == 15:
        alts.append("LabeledGraph<String, %s>(vertices: %s, edges: %s)" % (t, strs(V), dedges(E)))
    alts.append("LabeledGraph<String, %s>(AdjacencyList<String>(vertices: %s, edges: %s))" % (t, strs(V), dedges(E)))
    alts.append("LabeledGraph(graph.base, labels: graph.vertices)")
    out = ["        // The other initializers give the same state."]
    for k, a in enumerate(alts):
        out.append("        do {")
        out.append("            let built = " + a)
        out += ["            " + l for l in directed_state(g, kind, var="built", short=True)]
        out.append("            #expect(built.base == graph.base)")
        out.append("            #expect(built == graph)")
        out.append("        }")
    return out


def row_test(n):
    make, calls = MAKE[n], CALLS[n]
    spec = SPEC[n]
    if spec:
        kind, V, E = spec
    else:
        kind = BASE_INIT[n][0]
    g = make()
    g.hashes = 0
    ref.check(g)
    has_hashes = any(c[0] == "hashes" for c in calls)
    if has_hashes:
        g0 = make()
        shadow = make()
        shadow.hashes = 0
        G_SHADOW[n] = shadow
        for c in calls:
            if c[0] == "descendants":
                reached = shadow.descendants(c[1])
                shadow.hashes -= 1
                order = [l for l in shadow.labels if l in reached]
                DESC_ORDER[n] = order
    mut = any(c[0] in MUTATING for c in calls)
    lines = header(n, [".conformance"] if CELLS[n][1] == "Equality" else [])
    lines.append("    func lg%03d() {" % n)
    lines.append("        // %s" % inp(n))
    for p in cells_of(calls):
        lines.append("        " + cell_decl(p))
    if BUILDER[n]:
        lines += construct_builder(kind, BUILDER[n], "        ")
    elif spec:
        if n == 15:
            lines.append("        let graph = LabeledGraph<String, CompressedSparseRow>(DirectedPseudograph<String>(vertices: %s, edges: %s))" % (strs(V), dedges(E)))
        else:
            lines.append("        " + construct(kind, V, E, mut))
    else:
        lines.append("        let graph = " + BASE_INIT[n][1])
    if kind == "U":
        lines.append("        let view = graph.undirected")
    shown = []
    for i, c in enumerate(calls):
        r, ls = call_lines(g, kind, c)
        shown.append(ref.fmt(r))
        lines += ls
        if c[0] in MUTATING and any(x[0] in MUTATING for x in calls[i + 1:]):
            lines.append("        // After %s." % ref.call_text(c))
            lines += state(g, kind, short=True)
    exp = ("; ".join(shown) + " ⇒ " if shown else "") + ref.fmt_state(g)
    assert exp == cell(n), (n, exp, cell(n))
    lines.append("        // Final state.")
    lines += state(g, kind)
    if spec:
        lines += alternatives(n, kind, V, E, g)
    if has_hashes:
        lines += counted_lines(n, kind, g0, calls)
    lines.append("    }")
    return lines


def trap_test(n):
    make, calls = MAKE[n], CALLS[n]
    spec = SPEC[n]
    lines = header(n)
    lines.append("    func lg%03d() async {" % n)
    lines.append("        // %s → %s" % (inp(n), cell(n)))
    if spec is None:
        return lines + base_init_trap(n) + ["    }"]
    kind, V, E = spec
    *setup, last = calls
    assert not setup
    g = make()
    g.hashes = 0
    try:
        ref.run_call(g, last)
        raise AssertionError("no trap: %d" % n)
    except ref.Trap as t:
        assert cell(n) == "**trap** (%s)" % t, n
    lines.append("        await #expect(processExitsWith: .failure) {")
    for p in cells_of(calls):
        lines.append("            " + cell_decl(p))
    lines.append("            " + construct(kind, V, E, False))
    if kind == "U":
        lines.append("            let view = graph.undirected")
    lines.append("            " + child_call(kind, last))
    lines.append("        }")
    lines.append("        // Without the call: the state the call would apply to.")
    lines.append("        " + construct(kind, V, E, False))
    if kind == "U":
        lines.append("        let view = graph.undirected")
    lines += state(g, kind)
    lines.append("    }")
    return lines


def base_init_trap(n):
    cases = {
        18: ("LabeledGraph(CompressedSparseRow(vertexCount: 3), labels: [\"x\", \"y\"])",
             "LabeledGraph(CompressedSparseRow(vertexCount: 3), labels: [\"x\", \"y\", \"z\"])", ["x", "y", "z"]),
        19: ("LabeledGraph(CompressedSparseRow(vertexCount: 1), labels: [\"x\", \"y\"])",
             "LabeledGraph(CompressedSparseRow(vertexCount: 1), labels: [\"x\"])", ["x"]),
        20: ("LabeledGraph(CompressedSparseRow(vertexCount: 2), labels: [\"x\", \"x\"])",
             "LabeledGraph(CompressedSparseRow(vertexCount: 2), labels: [\"x\", \"y\"])", ["x", "y"]),
        21: ("LabeledGraph(AdjacencyList<Int>(vertices: [5, 6]), labels: [\"x\", \"y\"])",
             "LabeledGraph(AdjacencyList<Int>(vertices: [0, 1]), labels: [\"x\", \"y\"])", ["x", "y"]),
        22: ("LabeledGraph(AdjacencyList<Int>(vertices: [1, 0]), labels: [\"x\", \"y\"])",
             "LabeledGraph(AdjacencyList<Int>(vertices: [0, 1]), labels: [\"x\", \"y\"])", ["x", "y"]),
    }
    try:
        MAKE[n]()
        raise AssertionError("no trap: %d" % n)
    except ref.Trap as t:
        assert cell(n) == "**trap** (%s)" % t, n
    if n == 23:
        return ["        await #expect(processExitsWith: .failure) {",
                "            var base = StableDirectedGraph<Int>(vertices: [0, 1, 2])",
                "            _ = base.remove(1)",
                "            _ = LabeledGraph(base, labels: [\"x\", \"y\"])",
                "        }",
                "        // Without the removal: dense, and accepted.",
                "        let base = StableDirectedGraph<Int>(vertices: [0, 1, 2])",
                "        #expect(base.vertexIndexBound == 3)",
                "        let graph = LabeledGraph(base, labels: [\"x\", \"y\", \"z\"])",
                "        #expect(Array(graph.vertices) == [\"x\", \"y\", \"z\"])",
                "        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == [0, 1, 2])",
                "        #expect(graph.vertexIndexBound == 3 && graph.edgeCount == 0)"]
    bad, good, L = cases[n]
    return ["        await #expect(processExitsWith: .failure) {",
            "            _ = " + bad,
            "        }",
            "        // Without the fault: accepted.",
            "        let graph = " + good,
            "        #expect(Array(graph.vertices) == %s)" % strs(L),
            "        #expect(graph.vertices.map { graph.vertexIndex(of: $0) } == %s)" % ints(list(range(len(L)))),
            "        #expect((0 ..< %d).map { graph.vertex(atIndex: $0) } == %s)" % (len(L), strs(L)),
            "        #expect(graph.vertexIndexBound == %d && graph.edgeCount == 0)" % len(L)]


def equality_test(n):
    (ka, Va, Ea), (kb, Vb, Eb) = EQ_SPEC[n]
    ga, gb = ref.build(ka, Va, Ea), ref.build(kb, Vb, Eb)
    eq = ga == gb
    lines = header(n, [".conformance"]) + ["    func lg%03d() {" % n, "        // %s → %s" % (inp(n), cell(n))]
    lines.append("        " + construct(ka, Va, Ea, False, var="lhs"))
    lines.append("        " + construct(kb, Vb, Eb, False, var="rhs"))
    if CELLS[n][1] == "Hashing":
        assert cell(n) == str(len({ga.canonical(), gb.canonical()})), n
        lines.append("        #expect(Set([lhs, rhs]).count == %s)" % cell(n))
        if eq:
            lines += ["        #expect(lhs == rhs)", "        #expect(lhs.hashValue == rhs.hashValue)"]
            if ga.labels != gb.labels:
                lines.append("        // Equal values with different index assignments.")
                lines.append("        #expect(Array(lhs.vertices) == %s && Array(rhs.vertices) == %s)" % (strs(ga.labels), strs(gb.labels)))
        else:
            lines.append("        #expect(lhs != rhs)")
        lines += ["        #expect(lhs.hashValue == lhs.hashValue)", "    }"]
        return lines
    assert cell(n) == ref.fmt(eq), n
    if eq:
        lines += ["        #expect(lhs == rhs)", "        #expect(rhs == lhs)"]
        if ga.labels != gb.labels:
            lines.append("        // Equal values with different index assignments.")
            lines.append("        #expect(Array(lhs.vertices) == %s && Array(rhs.vertices) == %s)" % (strs(ga.labels), strs(gb.labels)))
    else:
        lines += ["        #expect(lhs != rhs)", "        #expect(rhs != lhs)"]
    lines += ["        #expect(lhs == lhs)", "    }"]
    return lines


def test_for(n):
    if n in EQ_ROWS:
        return equality_test(n)
    return trap_test(n) if is_trap(n) else row_test(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups):
    return [n for n in range(1, N + 1) if CELLS[n][1] in groups and not is_trap(n)]


TRAPS = [n for n in range(1, N + 1) if is_trap(n)]
FILES = [
    ("LabeledGraphConstructionTests.swift", "LabeledGraphs construction", ids("Construction", "Base init", "Builder", "Transpose"),
     "Construction (catalog LG-001 – LG-017, LG-024, LG-085 – LG-088): listed labels first (a repeat\n"
     "// once), then new endpoints in first-appearance order; parallel edges collapse; positions are the\n"
     "// base's; every initializer that fits gives the same state; `init(_:labels:)` names base vertex i\n"
     "// by labels[i]; the result builder lists its bare labels first; `transposed()` keeps the labels."),
    ("LabeledGraphReadTests.swift", "LabeledGraphs reads", ids("Reads"),
     "Reads (catalog LG-025 – LG-053): rows in the base's (ascending index) order, membership, the index\n"
     "// conversions both ways, the index-space rows forwarded from the base, positions, and the `safe:`\n"
     "// lookups, nil for a label that is not a vertex."),
    ("LabeledGraphBoundaryTests.swift", "LabeledGraphs boundary", ids("Boundary"),
     "Boundary (catalog LG-054 – LG-060): algorithms see the base through the index-space members, so\n"
     "// index-space reads hash no label and a label-space read hashes one; topologicalSort and\n"
     "// descendants are the base's results through the labels."),
    ("LabeledGraphUndirectedTests.swift", "LabeledGraphs undirected view", ids("Undirected"),
     "The undirected view (catalog LG-062 – LG-068): `labeled.undirected`, neighbours as successors then\n"
     "// predecessors, opposite arcs parallel, a loop twice, label-space reads hashing twice."),
    ("LabeledGraphMutationTests.swift", "LabeledGraphs mutation", ids("Mutation"),
     "Mutation over AdjacencyMatrix (catalog LG-069 – LG-084): a new label appends base vertex n;\n"
     "// `insert(edge:)` inserts missing endpoints, source first; `insert(safe:)` and `remove(edge:)`\n"
     "// change nothing for a non-vertex; the two resets; `removeEdges` by row, column or both."),
    ("LabeledGraphEqualityTests.swift", "LabeledGraphs equality", EQ_ROWS,
     "Equality and hashing (catalog LG-089 – LG-096): equal label sets and equal labeled edge sets,\n"
     "// whatever the index assignment, and equal values hash alike."),
    ("LabeledGraphPreconditionTests.swift", "LabeledGraphs preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the call, so the trap is the call's and not the\n"
     "// setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]
IMPORTS = {"AdjacencyListModule": "AdjacencyList<", "AdjacencyMatrixModule": "AdjacencyMatrix",
           "CompressedSparseRowModule": "CompressedSparseRow", "Multigraphs": "DirectedPseudograph",
           "StableGraphs": "StableDirectedGraph"}


def write(fname, suite, rows, comment):
    tests = [test_for(n) for n in rows]
    if fname == "LabeledGraphPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphProtocols", "LabeledGraphs", "Testing"]
    for module, needle in IMPORTS.items():
        if needle in text:
            imports.append(module)
    if "descendants(" in text or "topologicalSort(" in text:
        imports.append("Traversal")
    if ".tags(" in text or fname == "LabeledGraphPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "LabeledGraphPreconditionTests.swift" else ""
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
assert rows_total == N, rows_total
print("catalog rows", rows_total, "tests", total)
