"""Writes the catalog-row test files of Tests/GraphOperationsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 python3 Tests/Catalogs/GraphOperations/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/GraphOperationsTests

First checks that ref.py's model reproduces cases.md byte for byte. Then it re-runs every row on the
model (ref.py's ports of the bases, each view and result checked against NetworkX, igraph and the
laws), asserts that each value matches its catalog cell, and writes one @Test per row. A view's
state is written out in full: every vertex's index both ways, the edges with their positions and
ends, both bounds and the counts, every row by label and by index (out and in, or incident, with
the degrees), every edge index, and `contains(edge:)` for every ordered pair of vertices. A
materialized result is checked edge by edge, with its rows. Rows that count `hashes` also run on a
vertex type, local to the test, whose `hash(into:)` counts. A trap row runs the trapping call in a
child process (exit test) and then, in this process, the same setup without the fault. Hand-written
exit tests spliced into the precondition file: extra_traps.swift.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "GraphOperationsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and the structured arguments of every row
# ---------------------------------------------------------------------------------------------
REC = {}
_AL, _UL, _view_case, _built_case, _no_indices = ref.AL, ref.UL, ref.view_case, ref.built_case, ref.no_indices


def _rec_AL(vs, es):
    b, t = _AL(vs, es)
    b.spec = ("AL", vs.split() if vs else [], ref.E(es))
    return b, t


def _rec_UL(vs, es):
    b, t = _UL(vs, es)
    b.spec = ("UL", vs.split() if vs else [], ref.U(es))
    return b, t


def _rec_no_indices(base):
    b = _no_indices(base)
    b.spec = ("Stable", b.labels(), [(b.label(s), b.label(t)) for s, t in b.arcs])
    return b


def _rec_view(group, title, base_text, make, call_text, spec=None, extra=None):
    REC[len(ref.ROWS) + 1] = ("view", base_text[0].spec, make, call_text, extra)
    _view_case(group, title, base_text, make, call_text, spec, extra)


def _rec_built(group, title, inputs, make, call_text, spec=None):
    REC[len(ref.ROWS) + 1] = ("built", [b.spec for b, _ in inputs], make, call_text, None)
    _built_case(group, title, inputs, make, call_text, spec)


ref.AL, ref.UL, ref.view_case, ref.built_case, ref.no_indices = _rec_AL, _rec_UL, _rec_view, _rec_built, _rec_no_indices
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| GO-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 105 and sorted(REC) == list(range(1, N + 1))


def group(n): return CELLS[n][1]
def title(n): return CELLS[n][2]
def inp(n): return CELLS[n][3]
def cell(n): return CELLS[n][4]
def is_trap(n): return "**trap**" in cell(n)


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def s(x): return json.dumps(str(x), ensure_ascii=False)
def strs(xs): return "[" + ", ".join(s(x) for x in xs) + "]" if xs else "[] as [String]"
def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "]" if xs else "[] as [Int]"
def str_pairs(ps): return "[" + ", ".join(strs(list(p)) for p in ps) + "]" if ps else "[] as [[String]]"
def int_pairs(ps): return "[" + ", ".join(ints(list(p)) for p in ps) + "]" if ps else "[] as [[Int]]"
def bools(xs): return "[" + ", ".join("true" if x else "false" for x in xs) + "]" if xs else "[] as [Bool]"
def opt(x): return "nil" if x is None else str(x)


def has_multi(kind, es):
    if any(a == b for a, b in es):
        return True
    keys = [(a, b) if kind != "UL" else frozenset((a, b)) for a, b in es]
    return len(set(keys)) != len(keys)


def base_type(spec, label="String"):
    kind, vs, es = spec
    if kind == "Stable":
        return "StableDirectedGraph<%s>" % label
    multi = has_multi(kind, es)
    if kind == "AL":
        return ("DirectedPseudograph<%s>" if multi else "AdjacencyList<%s>") % label
    return ("Pseudograph<%s>" if multi else "UndirectedAdjacencyList<%s>") % label


def edge_lit(kind, a, b):
    if kind == "UL":
        return "UndirectedEdge(%s, %s)" % (s(a), s(b))
    return "DirectedEdge(from: %s, to: %s)" % (s(a), s(b))


def edges_lit(kind, es):
    if not es:
        return "[] as [UndirectedEdge<String>]" if kind == "UL" else "[] as [DirectedEdge<String>]"
    return "[" + ", ".join(edge_lit(kind, a, b) for a, b in es) + "]"


def construct(spec, var="graph"):
    """The base, as the catalog writes it. A Stable base gets a hole: one more vertex, removed."""
    kind, vs, es = spec
    if kind == "Stable":
        return ["var %s = StableDirectedGraph<String>(vertices: %s, edges: %s)" % (var, strs(vs + ["removed"]), edges_lit("AL", es)),
                "_ = %s.remove(\"removed\")" % var]
    return ["let %s = %s(vertices: %s, edges: %s)" % (var, base_type(spec), strs(vs), edges_lit(kind, es))]


def swift_chain(call_text):
    """A catalog call (`.inducedSubgraph(on: [a, b])`) in Swift, labels quoted."""
    def quote(m):
        items = [x.strip() for x in m.group(2).split(",") if x.strip()]
        return m.group(1) + ("[" + ", ".join(s(x) for x in items) + "]" if items else "[] as [String]")

    def ints_(m):
        items = [x.strip() for x in m.group(2).split(",") if x.strip()]
        return m.group(1) + ("[" + ", ".join(items) + "]" if items else "[] as [Int]")
    t = re.sub(r"((?:on|vertices): )\[([^\]]*)\]", quote, call_text)
    t = re.sub(r"(edges: )\[([^\]]*)\]", ints_, t)
    return t


# ---------------------------------------------------------------------------------------------
# A view's state, written out from the model
# ---------------------------------------------------------------------------------------------

def is_pair(p): return isinstance(p, tuple)


def directed_positions(v, ps, expr):
    """Positions compared as values: Int positions directly, the complement's through their ends."""
    if ps and is_pair(ps[0]) or (not ps and isinstance(v, ref.ComplementView)):
        return "#expect(%s.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == %s)" % (expr, int_pairs([list(p) for p in ps]))
    return "#expect(Array(%s) == %s)" % (expr, ints(ps))


def undirected_positions(v, ps, expr):
    if ps and is_pair(ps[0]) or (not ps and isinstance(v, ref.ComplementView)):
        return "#expect(%s.map { [view.endpointIndices(ofEdgeAt: $0).u, view.endpointIndices(ofEdgeAt: $0).v] } == %s)" % (expr, int_pairs([list(p) for p in ps]))
    return "#expect(Array(%s) == %s)" % (expr, ints(ps))


def view_state(v):
    n = v.n()
    L = [v.label(i) for i in range(n)]
    ps = v.positions()
    b = v.edge_bound()
    out = ["#expect(Array(view.vertices) == %s)" % strs(L),
           "#expect(view.vertices.map { view.vertexIndex(of: $0) } == %s)" % ints(list(range(n))),
           "#expect((0 ..< %d).map { view.vertex(atIndex: $0) } == %s)" % (n, strs(L)),
           "#expect(view.vertexCount == %d && view.edgeCount == %d && view.edges.count == %d)" % (n, len(ps), len(ps)),
           "#expect(view.vertexIndexBound == %d && view.edgeIndexBound == %s)" % (n, opt(b))]
    if v.directed:
        arcs = [(v.src(p), v.tgt(p)) for p in ps]
        out.append(directed_positions(v, ps, "view.edges.indices"))
        out.append("#expect(view.edges.map { [$0.source, $0.target] } == %s)" % str_pairs([(L[a], L[c]) for a, c in arcs]))
        if ps:
            out.append("#expect(view.edges.indices.map { [view.source(ofEdgeAt: $0), view.target(ofEdgeAt: $0)] } == %s)" % str_pairs([(L[a], L[c]) for a, c in arcs]))
            out.append("#expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == %s)" % int_pairs(arcs))
        if b is not None and ps:
            out.append("#expect(view.edges.indices.map { view.edgeIndex(of: $0) } == %s)" % ints([v.edge_index(p) for p in ps]))
        for i, l in enumerate(L):
            o = v.out_edges(i)
            succ = [v.tgt(p) for p in o]
            out.append("#expect(view.contains(%s))" % s(l))
            out.append("#expect(Array(view.successors(of: %s)) == %s)" % (s(l), strs([L[j] for j in succ])))
            out.append("#expect(Array(view.successorIndices(ofIndex: %d)) == %s)" % (i, ints(succ)))
            out.append(directed_positions(v, o, "view.outEdges(of: %s)" % s(l)))
            out.append(directed_positions(v, o, "view.outEdges(ofIndex: %d)" % i))
            out.append("#expect(view.outDegree(of: %s) == %d && view.outDegree(ofIndex: %d) == %d)" % (s(l), len(o), i, len(o)))
            if v.bidirectional:
                ie = v.in_edges(i)
                pred = [v.src(p) for p in ie]
                out.append("#expect(Array(view.predecessors(of: %s)) == %s)" % (s(l), strs([L[j] for j in pred])))
                out.append("#expect(Array(view.predecessorIndices(ofIndex: %d)) == %s)" % (i, ints(pred)))
                out.append(directed_positions(v, ie, "view.inEdges(of: %s)" % s(l)))
                out.append(directed_positions(v, ie, "view.inEdges(ofIndex: %d)" % i))
                out.append("#expect(view.inDegree(of: %s) == %d && view.inDegree(ofIndex: %d) == %d && view.degree(of: %s) == %d)"
                           % (s(l), len(ie), i, len(ie), s(l), len(ie) + len(o)))
        if n:
            arcset = set(arcs)
            matrix = [(i, j) in arcset for i in range(n) for j in range(n)]
            for i in range(n):
                for j in range(n):
                    assert v.contains_edge(i, j) == ((i, j) in arcset)
            out.append("// contains(edge:) for every ordered pair, source-major.")
            out.append("#expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: DirectedEdge(from: s, to: t)) } } == %s)" % bools(matrix))
    else:
        ends = [v.ends(p) for p in ps]
        out.append(undirected_positions(v, ps, "view.edges.indices"))
        out.append("#expect(view.edges.map { [$0.u, $0.v] } == %s)" % str_pairs([(L[a], L[c]) for a, c in ends]))
        if ps:
            out.append("#expect(view.edges.indices.map { [view.endpointIndices(ofEdgeAt: $0).u, view.endpointIndices(ofEdgeAt: $0).v] } == %s)" % int_pairs(ends))
        if b is not None and ps:
            out.append("#expect(view.edges.indices.map { view.edgeIndex(of: $0) } == %s)" % ints([v.edge_index(p) for p in ps]))
        for i, l in enumerate(L):
            inc = v.incident(i)
            nb = []
            for p in inc:
                a, c = v.ends(p)
                nb.append(c if a == i else a)
            out.append("#expect(view.contains(%s))" % s(l))
            out.append("#expect(Array(view.neighbors(of: %s)) == %s)" % (s(l), strs([L[j] for j in nb])))
            out.append("#expect(Array(view.neighborIndices(ofIndex: %d)) == %s)" % (i, ints(nb)))
            out.append(undirected_positions(v, inc, "view.incidentEdges(of: %s)" % s(l)))
            out.append(undirected_positions(v, inc, "view.incidentEdges(ofIndex: %d)" % i))
            out.append("#expect(view.degree(of: %s) == %d && view.degree(ofIndex: %d) == %d)" % (s(l), len(inc), i, len(inc)))
            if inc:
                out.append("#expect(view.incidentEdges(of: %s).map { view.oppositeVertex(to: %s, acrossEdgeAt: $0) } == %s)" % (s(l), s(l), strs([L[j] for j in nb])))
            if b is not None:
                out.append("#expect(Array(view.incidentEdgeIndices(ofIndex: %d)) == %s)" % (i, ints([v.edge_index(p) for p in inc])))
        if n:
            es = {frozenset(e) for e in ends}
            matrix = [frozenset((i, j)) in es for i in range(n) for j in range(n)]
            for i in range(n):
                for j in range(n):
                    assert v.contains_edge(i, j) == (frozenset((i, j)) in es)
            out.append("// contains(edge:) for every ordered pair, first-end-major.")
            out.append("#expect(view.vertices.flatMap { s in view.vertices.map { t in view.contains(edge: UndirectedEdge(s, t)) } } == %s)" % bools(matrix))
    return out


def fresh(spec):
    kind, vs, es = spec
    if kind == "UL":
        return ref.UBase(vs, es)
    b = ref.DiBase(vs, es)
    if kind == "Stable":
        b.has_vertex_indices = False
    return b


def base_state(spec, var="graph"):
    """The setup on its own: the base's vertices and edges, in order."""
    kind, vs, es = spec
    b = fresh(spec)
    L = b.labels()
    out = ["#expect(Array(%s.vertices) == %s)" % (var, strs(L))]
    if kind == "UL":
        out.append("#expect(%s.edges.map { [$0.u, $0.v] } == %s)" % (var, str_pairs(es)))
    else:
        out.append("#expect(%s.edges.map { [$0.source, $0.target] } == %s)" % (var, str_pairs(es)))
    out.append("#expect(%s.vertexIndexBound == %s)" % (var, "nil" if kind == "Stable" else str(len(L))))
    return out


# ---------------------------------------------------------------------------------------------
# A materialized result, written out from the model
# ---------------------------------------------------------------------------------------------

def built_state(r, var="result"):
    n = r.n()
    es = list(r.es)
    out = ["#expect(%s.vertexCount == %d && %s.edgeCount == %d)" % (var, n, var, len(es)),
           "#expect(Array(%s.vertices) == %s)" % (var, ints(list(range(n)))),
           "#expect(Array(%s.edges.indices) == %s)" % (var, ints(list(range(len(es)))))]
    if r.directed:
        out.append("#expect(%s.edges.map { [$0.source, $0.target] } == %s)" % (var, int_pairs(es)))
        for i in range(n):
            out.append("#expect(Array(%s.successors(of: %d)) == %s)" % (var, i, ints([t for s_, t in es if s_ == i])))
    else:
        out.append("#expect(%s.edges.map { [$0.u, $0.v] } == %s)" % (var, int_pairs(es)))
        for i in range(n):
            nb = [b if a == i else a for a, b in es if i in (a, b)]
            out.append("#expect(Array(%s.neighbors(of: %d)) == %s)" % (var, i, ints(nb)))
    return out


# ---------------------------------------------------------------------------------------------
# Hash counting
# ---------------------------------------------------------------------------------------------
COUNTED = [
    "// Vertex hashes, counted by a vertex type whose hash(into:) counts. The base's dictionary",
    "// hashes a vertex once per lookup.",
    "final class Tally {",
    "    var hashes = 0",
    "}",
    "struct Counted: Hashable {",
    "    let name: String",
    "    let tally: Tally",
    "    static func == (lhs: Counted, rhs: Counted) -> Bool { lhs.name == rhs.name }",
    "    func hash(into hasher: inout Hasher) {",
    "        tally.hashes += 1",
    "        hasher.combine(name)",
    "    }",
    "}",
    "let tally = Tally()",
    "func label(_ name: String) -> Counted { Counted(name: name, tally: tally) }",
]


def counted_base(spec):
    kind, vs, es = spec
    E = "[" + ", ".join("DirectedEdge(from: label(%s), to: label(%s))" % (s(a), s(b)) for a, b in es) + "]" if es else "[] as [DirectedEdge<Counted>]"
    return "let counted = %s(vertices: %s.map(label), edges: %s)" % (base_type(spec, "Counted"), strs(vs), E)


def hash_lines(n, spec):
    lines = list(COUNTED) + [counted_base(spec)]
    if n == 9:
        lines += ["let reversed = counted.reverseView",
                  "tally.hashes = 0",
                  "let out = Array(reversed.outEdges(of: label(\"b\")))",
                  "#expect(tally.hashes == 1)",
                  "tally.hashes = 0",
                  "let into = Array(reversed.inEdges(ofIndex: 1))",
                  "let row = Array(reversed.successorIndices(ofIndex: 1)) + Array(reversed.predecessorIndices(ofIndex: 1))",
                  "#expect(tally.hashes == 0)",
                  "#expect(out == [0, 1] && into == [] && row == [0, 2])"]
    elif n == 20:
        lines += ["tally.hashes = 0",
                  "let induced = counted.inducedSubgraph(on: [\"b\", \"c\", \"d\", \"c\"].map(label))",
                  "#expect(tally.hashes == 4)",
                  "tally.hashes = 0",
                  "let row = Array(induced.successorIndices(ofIndex: 0))",
                  "let bound = induced.edgeIndexBound",
                  "let rows = (0 ..< 3).map { Array(induced.successorIndices(ofIndex: $0)) + Array(induced.predecessorIndices(ofIndex: $0)) }",
                  "let positions = (0 ..< 3).map { Array(induced.outEdges(ofIndex: $0)) + Array(induced.inEdges(ofIndex: $0)) }",
                  "#expect(tally.hashes == 0)",
                  "#expect(row == [1] && bound == nil)",
                  "#expect(rows == [[1], [2, 0], [1]] && positions == [[1], [2, 1], [2]])"]
    elif n == 62:
        lines += ["let complement = counted.complement",
                  "tally.hashes = 0",
                  "let out = complement.outEdges(ofIndex: 0).map { [complement.sourceIndex(ofEdgeAt: $0), complement.targetIndex(ofEdgeAt: $0)] }",
                  "let rows = (0 ..< 3).map { Array(complement.successorIndices(ofIndex: $0)) + Array(complement.predecessorIndices(ofIndex: $0)) }",
                  "let bounds = [complement.vertexIndexBound, complement.edgeIndexBound]",
                  "#expect(tally.hashes == 0)",
                  "#expect(out == [[0, 2]] && rows == [[2, 1, 2], [0, 2, 2], [0, 1, 0, 1]] && bounds == [3, nil])",
                  "// contains(edge:) takes vertices, so it looks them up; the answers are the base's negated.",
                  "#expect(!complement.contains(edge: DirectedEdge(from: label(\"a\"), to: label(\"b\"))))",
                  "#expect(!complement.contains(edge: DirectedEdge(from: label(\"b\"), to: label(\"b\"))))",
                  "#expect(complement.contains(edge: DirectedEdge(from: label(\"b\"), to: label(\"a\"))))"]
    return lines


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

def header(n, async_=False):
    return ['    @Test("GO-%03d %s")' % (n, title(n)), "    func go%03d()%s {" % (n, " async" if async_ else "")]


def split_call(call_text):
    parts = [p.strip() for p in call_text.split(" / ")]
    return parts[0], parts[1:]


EXTRA = {
    7: ["#expect(view.edgeIndex(of: 2) == 2 && view.sourceIndex(ofEdgeAt: 2) == 0)"],
    8: ["// The reverse of a reverse is the base itself, of the base's type.",
        "let back: %s = graph.reverseView.reverseView",
        "#expect(back == graph)"],
    19: ["#expect(Array(view.predecessors(of: \"a\")) == [\"c\", \"d\"])"],
    21: ["#expect(view.edgeCount == 2)"],
    24: ["#expect(!view.contains(\"b\") && !view.contains(\"z\"))"],
    35: ["#expect(view.vertexIndex(of: \"c\") == 2 && graph.vertexIndex(of: \"c\") == 2)"],
    56: ["#expect(Array(view.predecessors(of: \"c\")) == [\"b\"])"],
    57: ["// The base of the outer complement is the inner one, whose base is the graph.",
        "#expect(view.base.base == graph)"],
}


def view_test(n):
    _, spec, make, call_text, extra = REC[n]
    chain, trailing = split_call(call_text)
    b = fresh(spec)
    v = make(b)
    ref.check(v)
    exp = ref.fmt_state(v)
    assert cell(n).startswith(exp), (n, exp, cell(n))
    if "rows [" in cell(n):
        assert ref.fmt_rows(v) in cell(n), (n, ref.fmt_rows(v), cell(n))
    lines = header(n)
    lines.append("        // %s" % inp(n))
    lines.append("        // Expected: %s" % cell(n))
    lines += ["        " + l for l in construct(spec)]
    lines.append("        let view = graph%s" % swift_chain(chain))
    ex = list(EXTRA.get(n, []))
    if n == 8:
        ex[1] = ex[1] % base_type(spec)
    lines += ["        " + l for l in ex]
    lines += ["        " + l for l in view_state(v)]
    if n in (9, 20, 62):
        lines.append("        // Hashes, on the same graph over a counting vertex type.")
        lines.append("        do {")
        lines += ["            " + l for l in hash_lines(n, spec)]
        lines.append("        }")
    lines.append("    }")
    return lines


def built_swift(n, call_text):
    """The Swift call of a materialized row: `Type.member(of: g ...)`."""
    t = call_text
    t = t.replace("(of: g)", "(of: graph)").replace("(of: g, by:", "(of: graph, by:").replace("(g, h)", "(graph, other)")
    t = t.replace("DirectedAcyclicGraph<AdjacencyList<Int>>(g.condensation())", "DirectedAcyclicGraph<AdjacencyList<Int>>(graph.condensation())")

    def blocks(m):
        inner = re.findall(r"\[([^\[\]]*)\]", m.group(1))
        out = []
        for b in inner:
            items = [x.strip() for x in b.split(",") if x.strip()]
            out.append("[" + ", ".join(s(x) for x in items) + "]")
        return "by: [" + ", ".join(out) + "])"
    t = re.sub(r"by: \[(.*)\]\)$", blocks, t)
    return t


def built_test(n):
    _, specs, make, call_text, _ = REC[n]
    bases = [fresh(sp) for sp in specs]
    r = make(*bases)
    ref.check(r)
    assert ref.fmt_built(r) == cell(n), (n, ref.fmt_built(r), cell(n))
    lines = header(n)
    lines.append("        // %s" % inp(n))
    lines.append("        // Expected: %s" % cell(n))
    lines += ["        " + l for l in construct(specs[0])]
    if len(specs) > 1:
        lines += ["        " + l for l in construct(specs[1], "other")]
    call = built_swift(n, call_text)
    if group(n) == "Condensation":
        comps = r.comp_labels
        lines.append("        let condensation = graph.condensation()")
        lines.append("        #expect(condensation.components.map { Array($0) } == %s)" % str_pairs([[str(x) for x in c] for c in comps]))
        lines.append("        let result = DirectedAcyclicGraph<AdjacencyList<Int>>(condensation)")
        lines += ["        " + l for l in built_state(r)]
        lines.append("        #expect(Array(result.topologicalOrder) == %s)" % ints(r.order))
        lines.append("        #expect(result.base == AdjacencyList<Int>(vertices: 0 ..< %d, edges: %s))" % (
            r.n(), "[" + ", ".join("DirectedEdge(from: %d, to: %d)" % e for e in r.es) + "]" if r.es else "[] as [DirectedEdge<Int>]"))
        lines.append("        // Vertex i of the DAG is component i, and its edges are the condensation's.")
        lines.append("        #expect(result.edges.map { [$0.source, $0.target] } == condensation.graph.edges.map { [$0.source, $0.target] })")
    else:
        lines.append("        let result = %s" % call)
        lines += ["        " + l for l in built_state(r)]
    lines.append("    }")
    return lines


TRAP_CHILD = {
    23: (".inducedSubgraph(on: [a])", "_ = view.vertexIndex(of: \"b\")"),
}
TRAP_FIX = {  # the call without the fault, run in this process
    22: ".inducedSubgraph(on: [a])",
    23: ".inducedSubgraph(on: [a])",
    36: ".spanningSubgraph(edges: [0])",
    44: ".subgraph(vertices: [a], edges: [0])",
    45: ".subgraph(vertices: [a], edges: [0])",
    92: [["a"], ["b"]],
    93: [["a", "b"], ["c"]],
    94: [["a", "b"]],
}


def trap_test(n):
    kind_, spec_or_specs, make, call_text, _ = REC[n]
    lines = header(n, True)
    lines.append("        // %s → %s" % (inp(n), cell(n)))
    specs = spec_or_specs if kind_ == "built" else [spec_or_specs]
    lines.append("        await #expect(processExitsWith: .failure) {")
    lines += ["            " + l for l in construct(specs[0])]
    if len(specs) > 1:
        lines += ["            " + l for l in construct(specs[1], "other")]
    if kind_ == "view":
        chain, trailing = split_call(call_text)
        if n in TRAP_CHILD:
            lines.append("            let view = graph%s" % swift_chain(TRAP_CHILD[n][0]))
            lines.append("            " + TRAP_CHILD[n][1])
        else:
            lines.append("            _ = graph%s" % swift_chain(chain))
    else:
        lines.append("            _ = %s" % built_swift(n, call_text))
    lines.append("        }")
    # Without the fault.
    if specs[0][0] == "Stable":
        kind, vs, es = specs[0]
        dense = ("AL", vs, es)
        lines.append("        // Without the removal the same base has vertex indices, and the call is accepted.")
        lines.append("        let graph = StableDirectedGraph<String>(vertices: %s, edges: %s)" % (strs(vs), edges_lit("AL", es)))
        lines.append("        #expect(graph.vertexIndexBound == %d)" % len(vs))
        chain, _ = split_call(call_text)
        lines.append("        let view = graph%s" % swift_chain(chain))
        b = fresh(dense)
        v = make(b)
        ref.check(v)
        lines += ["        " + l for l in view_state(v)]
        lines.append("        // The removal itself leaves a hole.")
        lines += ["        " + l for l in construct(specs[0], "holed")]
        lines.append("        #expect(holed.vertexIndexBound == nil && Array(holed.vertices) == %s)" % strs(vs))
    else:
        lines.append("        // Without the fault: the same setup, accepted.")
        lines += ["        " + l for l in construct(specs[0])]
        lines += ["        " + l for l in base_state(specs[0])]
        if len(specs) > 1:
            lines += ["        " + l for l in construct(specs[1], "other")]
            lines += ["        " + l for l in base_state(specs[1], "other")]
        if n in TRAP_FIX and kind_ == "view":
            fix = TRAP_FIX[n]
            lines.append("        let view = graph%s" % swift_chain(fix))
            b = fresh(specs[0])
            m = re.match(r"\.(\w+)\(", fix)
            name = m.group(1)
            if name == "inducedSubgraph":
                v = ref.induced_subgraph(b, ["a"])
            elif name == "spanningSubgraph":
                v = ref.spanning_subgraph(b, [0])
            else:
                v = ref.subgraph(b, ["a"], [0])
            ref.check(v)
            lines += ["        " + l for l in view_state(v)]
        elif n in TRAP_FIX:
            blocks = TRAP_FIX[n]
            b = fresh(specs[0])
            r = ref.quotient(b, blocks)
            lines.append("        let result = UndirectedAdjacencyList<Int>.quotient(of: graph, by: %s)" % ("[" + ", ".join(strs(x) for x in blocks) + "]"))
            lines += ["        " + l for l in built_state(r)]
    lines.append("    }")
    return lines


def test_for(n):
    if is_trap(n):
        return trap_test(n)
    return view_test(n) if REC[n][0] == "view" else built_test(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(*groups):
    return [n for n in range(1, N + 1) if group(n) in groups and not is_trap(n)]


TRAPS = [n for n in range(1, N + 1) if is_trap(n)]
FILES = [
    ("ReverseViewTests.swift", "GraphOperations reverseView", ids("Reverse"),
     "reverseView (catalog GO-001 – GO-009): every arc flipped, vertices, indices and positions the\n"
     "// base's; successors are the base's predecessors in its in-row order; the reverse of a reverse\n"
     "// is the base; a label-space row hashes once and an index-space row not at all."),
    ("SubgraphViewTests.swift", "GraphOperations subgraph views", ids("Induced", "Spanning", "Subgraph"),
     "Subgraph views (catalog GO-010 – GO-047): kept vertices renumbered in base order, positions the\n"
     "// base's; an induced subgraph that drops a vertex has no edge indices (one on every vertex has\n"
     "// the base's); an edge set gives dense edge indices by rank in base index order, counting only\n"
     "// edges with both ends kept; a self-loop twice in an undirected row; views of views."),
    ("ComplementViewTests.swift", "GraphOperations complement", ids("Complement"),
     "complement (catalog GO-048 – GO-062): every non-edge between distinct vertices, rows ascending\n"
     "// by index, positions as index pairs in row-major order, self-loops and parallel edges of the\n"
     "// base ignored; index-space rows hash nothing."),
    ("LineGraphTests.swift", "GraphOperations lineGraph(of:)", ids("LineGraph"),
     "lineGraph(of:) (catalog GO-064 – GO-077): vertex k is the edge with edgeIndex k; directed, e→f\n"
     "// where e's target is f's source; undirected, edges sharing an end, parallel edges joined once,\n"
     "// a self-loop adjacent to the edges at its vertex."),
    ("CondensationDAGTests.swift", "GraphOperations condensation as a DirectedAcyclicGraph", ids("Condensation"),
     "DirectedAcyclicGraph(_ condensation:) (catalog GO-078 – GO-084): vertex i is component i, in\n"
     "// Connectivity's order; the edges are the condensation's; the topological order is n−1, …, 0."),
    ("QuotientTests.swift", "GraphOperations quotient(of:by:)", ids("Quotient"),
     "quotient(of:by:) (catalog GO-085 – GO-091): block i is vertex i; an edge between two blocks\n"
     "// wherever the graph has one, merged; edges inside a block dropped; an empty block isolated."),
    ("DisjointUnionJoinTests.swift", "GraphOperations disjointUnion and join", ids("DisjointUnion", "Join"),
     "disjointUnion and join (catalog GO-095 – GO-104): g's vertices first, then h's offset by |V(g)|;\n"
     "// parallel edges merge; the join adds every edge across (both ways, directed)."),
    ("GraphOperationsPreconditionTests.swift", "GraphOperations preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the fault, so the trap is the call's and not the\n"
     "// setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]
IMPORTS = {"AdjacencyListModule": ["AdjacencyList<", "UndirectedAdjacencyList<"], "Multigraphs": ["Pseudograph<"],
           "StableGraphs": ["StableDirectedGraph"], "CompressedSparseRowModule": ["CompressedSparseRow"],
           "DirectedAcyclicGraphModule": ["DirectedAcyclicGraph"], "Connectivity": [".condensation()"]}


def write(fname, suite, rows, comment):
    tests = [test_for(n) for n in rows]
    if fname == "GraphOperationsPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphOperations", "GraphProtocols", "Testing"]
    for module, needles in IMPORTS.items():
        if any(x in text for x in needles):
            imports.append(module)
    if fname == "GraphOperationsPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "GraphOperationsPreconditionTests.swift" else ""
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
