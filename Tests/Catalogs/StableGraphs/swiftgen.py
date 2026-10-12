"""Writes the catalog-row test files of Tests/StableGraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/StableGraphs/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/StableGraphsTests

First checks that ref.py's model reproduces cases.md byte for byte, then re-runs every row on the
model (ref.py's port of the storage, checked against its plain specification and the laws after
every call), asserts that each value matches its catalog cell, and writes one @Test per row. Each
call's result is checked; after each mutation the test checks the positions (`vertices` and
`edges` with their indices and end indices, and the index bounds), and the final state is written
out in full: every vertex's position and rows (empty ones included, where the catalog omits them),
every live position's ends, and `edges(from:to:)` / `edgeCount(from:to:)` for every pair with an
edge. Hand-written exit tests spliced into the precondition file: extra_traps.swift.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "StableGraphsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and the structured arguments of every row
# ---------------------------------------------------------------------------------------------
ROWS = {}
_case, _raw = ref.case, ref.raw


def _rec_case(group, title, V, E, ops=(), note=None):
    ROWS[len(ref.ROWS) + 1] = ("case", group, title, V, E, list(ops), note)
    _case(group, title, V, E, ops, note)


def _rec_raw(group, title, inp, exp):
    ROWS[len(ref.ROWS) + 1] = ("raw", group, title, inp, exp)
    _raw(group, title, inp, exp)


ref.case, ref.raw = _rec_case, _rec_raw
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| SG-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[int(parts[0][3:])] = parts
N = len(CELLS)
assert N == 138 and sorted(ROWS) == list(range(1, N + 1))


def title(n): return CELLS[n][2]
def renamed(s): return s.replace("StableDiGraph", "StableDirectedGraph")  # the type's name before the rename
def inp(n): return renamed(CELLS[n][3])
def cell(n): return renamed(CELLS[n][4])


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def lit(x):
    return json.dumps(x, ensure_ascii=False) if isinstance(x, str) else str(x)


def vty(*seqs):
    def has_str(x):
        return isinstance(x, str) or (isinstance(x, (tuple, list)) and any(has_str(y) for y in x))
    return "String" if any(has_str(s) for s in seqs) else "Int"


def arr(xs, t):
    return "[" + ", ".join(lit(x) for x in xs) + "]" + ("" if xs else " as [%s]" % t)


def nested(xss, t):
    return "[" + ", ".join(arr(xs, t) for xs in xss) + "]" + ("" if xss else " as [[%s]]" % t)


def edge(a, b):
    return "DirectedEdge(from: %s, to: %s)" % (lit(a), lit(b))


def edges_lit(E, t):
    return "[" + ", ".join(edge(a, b) for a, b in E) + "]" if E else "[] as [DirectedEdge<%s>]" % t


def opt(x):
    return "nil" if x is None else lit(x)


def construct(V, E, t, var="graph", mutable=True):
    return "%s %s = StableDirectedGraph<%s>(vertices: %s, edges: %s)" % ("var" if mutable else "let", var, t, arr(V, t), edges_lit(E, t))


STATEMENTS = {"removeAll", "removeAllEdges", "churn", "vertexChurn", "changeTarget", "changeSource"}
MUTATING = {"insert", "edge", "remove", "removeEdge", "removeAt", "removeAllBetween", "removeAll", "removeAllEdges",
            "changeTarget", "changeSource", "changeTargetChecked", "changeSourceChecked", "churn", "vertexChurn",
            "removeFromWhere", "removeWhere", "insertChecked"}
CHECKED = {"insertChecked", "outDegreeChecked", "inDegreeChecked", "degreeChecked", "successorsChecked", "predecessorsChecked",
           "outEdgesChecked", "inEdgesChecked", "descendantsChecked", "ancestorsChecked", "changeTargetChecked",
           "changeSourceChecked", "vertexIndexChecked", "sourceChecked", "targetChecked"}

# ---------------------------------------------------------------------------------------------
# Running a row on the model, one call at a time
# ---------------------------------------------------------------------------------------------


def build(V, E):
    port, spec = ref.Port(), ref.Spec()
    for v in V:
        port.insert(v); spec.insert(v)
    for a, b in E:
        port.insert_edge(a, b); spec.insert_edge(a, b)
    ref.check_laws(port); ref.same(port, spec)
    return port, spec


def step(port, spec, op):
    """The call's result, or ref.Trap; both models agree and the laws hold after it."""
    try:
        a = ref.apply(port, op)
    except ref.Trap:
        try:
            ref.apply(spec, op)
        except ref.Trap:
            raise
        raise AssertionError(op)
    b = ref.apply(spec, op)
    if op[0] != "compact":
        assert a == b, (op, a, b)
    ref.check_laws(port); ref.same(port, spec)
    return a


def position_lines(g, t, var="graph", ind="        "):
    V, E, rows, vend, eend, vib, eib = ref.snapshot(g)
    out = [
        "#expect(Array(%s.vertices) == %s)" % (var, arr([v for v, _ in V], t)),
        "#expect(Array(%s.vertices.indices) == %s)" % (var, arr([s for _, s in V], "Int")),
        "#expect(%s.vertices.startIndex == %d)" % (var, V[0][1] if V else vend),
        "#expect(%s.vertices.endIndex == %d)" % (var, vend),
        "#expect(%s.edges.map { [$0.source, $0.target] } == %s)" % (var, nested([[a, b] for _, a, b in E], t)),
        "#expect(Array(%s.edges.indices) == %s)" % (var, arr([p for p, _, _ in E], "Int")),
        "#expect(%s.edges.startIndex == %d)" % (var, E[0][0] if E else eend),
        "#expect(%s.edges.endIndex == %d)" % (var, eend),
        "#expect(%s.vertexIndexBound == %s)" % (var, opt(vib)),
        "#expect(%s.edgeIndexBound == %s)" % (var, opt(eib)),
    ]
    return [ind + l for l in out]


def state_lines(g, t, var="graph", ind="        "):
    """Every value of the model's state."""
    V, E, rows, vend, eend, vib, eib = ref.snapshot(g)
    by = {p: (a, b) for p, a, b in E}
    out = [l.strip() for l in position_lines(g, t, var)]
    out += ["#expect(%s.vertexCount == %d)" % (var, len(V)), "#expect(%s.vertices.count == %d)" % (var, len(V)),
            "#expect(%s.edgeCount == %d)" % (var, len(E)), "#expect(%s.edges.count == %d)" % (var, len(E))]
    if E:
        out.append("#expect(%s.edges.indices.map { [%s.source(ofEdgeAt: $0), %s.target(ofEdgeAt: $0)] } == %s)"
                   % (var, var, var, nested([[a, b] for _, a, b in E], t)))
        out.append("#expect(%s.edges.indices.map { %s.edges[$0] } == %s)" % (var, var, edges_lit([(a, b) for _, a, b in E], t)))
    for v, s in V:
        o, i = rows[v]
        out.append("#expect(%s.vertices.firstIndex(of: %s) == %d)" % (var, lit(v), s))
        out.append("#expect(%s.vertices[%d] == %s)" % (var, s, lit(v)))
        out.append("#expect(Array(%s.successors(of: %s)) == %s)" % (var, lit(v), arr([by[p][1] for p in o], t)))
        out.append("#expect(Array(%s.outEdges(of: %s)) == %s)" % (var, lit(v), arr(o, "Int")))
        out.append("#expect(Array(%s.predecessors(of: %s)) == %s)" % (var, lit(v), arr([by[p][0] for p in i], t)))
        out.append("#expect(Array(%s.inEdges(of: %s)) == %s)" % (var, lit(v), arr(i, "Int")))
        out.append("#expect(%s.outDegree(of: %s) == %d && %s.inDegree(of: %s) == %d && %s.degree(of: %s) == %d)"
                   % (var, lit(v), len(o), var, lit(v), len(i), var, lit(v), len(o) + len(i)))
    pairs = []
    for _, a, b in E:
        if (a, b) not in pairs:
            pairs.append((a, b))
    for a, b in pairs:
        ps = [p for p, x, y in E if (x, y) == (a, b)]
        out.append("#expect(Array(%s.edges(from: %s, to: %s)) == %s)" % (var, lit(a), lit(b), arr(ps, "Int")))
        out.append("#expect(%s.edgeCount(from: %s, to: %s) == %d)" % (var, lit(a), lit(b), len(ps)))
        out.append("#expect(%s.contains(edge: %s))" % (var, edge(a, b)))
    if vib is not None:
        out.append("#expect(%s.vertices.map { %s.vertexIndex(of: $0) } == %s)" % (var, var, arr(list(range(vib)), "Int")))
        out.append("#expect((0 ..< %d).map { %s.vertex(atIndex: $0) } == %s)" % (vib, var, arr([v for v, _ in V], t)))
    if eib is not None:
        out.append("#expect(%s.edges.indices.map { %s.edgeIndex(of: $0) } == %s)" % (var, var, arr(list(range(eib)), "Int")))
    return [ind + l for l in out]


def call_text(op):
    """The Swift call, and whether its result is discardable noise in a child process."""
    k = op[0]
    a = op[1:] if len(op) > 1 else ()
    return {
        "insert": lambda: "graph.insert(%s)" % lit(a[0]),
        "edge": lambda: "graph.insert(edge: %s)" % edge(*a),
        "remove": lambda: "graph.remove(%s)" % lit(a[0]),
        "removeEdge": lambda: "graph.remove(edge: %s)" % edge(*a),
        "removeAt": lambda: "graph.remove(edgeAt: %d)" % a[0],
        "removeAllBetween": lambda: "graph.removeAllEdges(from: %s, to: %s)" % (lit(a[0]), lit(a[1])),
        "removeAll": lambda: "graph.removeAll()",
        "removeAllEdges": lambda: "graph.removeAllEdges()",
        "successors": lambda: "Array(graph.successors(of: %s))" % lit(a[0]),
        "outEdges": lambda: "Array(graph.outEdges(of: %s))" % lit(a[0]),
        "inEdges": lambda: "Array(graph.inEdges(of: %s))" % lit(a[0]),
        "source": lambda: "graph.source(ofEdgeAt: %d)" % a[0],
        "edgeAt": lambda: "graph.edges[%d]" % a[0],
        "vertexAtIndex": lambda: "graph.vertex(atIndex: %d)" % a[0],
        "vertexIndex": lambda: "graph.vertexIndex(of: %s)" % lit(a[0]),
        "edgeIndex": lambda: "graph.edgeIndex(of: %d)" % a[0],
        "vertexAt": lambda: "graph.vertices[%d]" % a[0],
        "edgesIndicesContains": lambda: "graph.edges.indices.contains(%d)" % a[0],
        "verticesIndicesContains": lambda: "graph.vertices.indices.contains(%d)" % a[0],
        "contains": lambda: "graph.contains(%s)" % lit(a[0]),
        "containsEdge": lambda: "graph.contains(edge: %s)" % edge(*a),
        "edgesFromTo": lambda: "Array(graph.edges(from: %s, to: %s))" % (lit(a[0]), lit(a[1])),
        "insertChecked": lambda: "try graph.insert(checked: %s)" % edge(*a),
        "outDegreeChecked": lambda: "try graph.outDegree(checked: %s)" % lit(a[0]),
        "inDegreeChecked": lambda: "try graph.inDegree(checked: %s)" % lit(a[0]),
        "degreeChecked": lambda: "try graph.degree(checked: %s)" % lit(a[0]),
        "successorsChecked": lambda: "try graph.successors(checked: %s)" % lit(a[0]),
        "predecessorsChecked": lambda: "try graph.predecessors(checked: %s)" % lit(a[0]),
        "outEdgesChecked": lambda: "try graph.outEdges(checked: %s)" % lit(a[0]),
        "inEdgesChecked": lambda: "try graph.inEdges(checked: %s)" % lit(a[0]),
        "descendantsChecked": lambda: "try graph.descendants(checked: %s)" % lit(a[0]),
        "ancestorsChecked": lambda: "try graph.ancestors(checked: %s)" % lit(a[0]),
        "vertexIndexChecked": lambda: "try graph.vertexIndex(checked: %s)" % lit(a[0]),
        "sourceChecked": lambda: "try graph.source(checkedEdgeAt: %d)" % a[0],
        "targetChecked": lambda: "try graph.target(checkedEdgeAt: %d)" % a[0],
        "changeTarget": lambda: "graph.changeTarget(ofEdgeAt: %d, to: %s)" % (a[0], lit(a[1])),
        "changeSource": lambda: "graph.changeSource(ofEdgeAt: %d, to: %s)" % (a[0], lit(a[1])),
        "changeTargetChecked": lambda: "try graph.changeTarget(ofEdgeAt: %d, checked: %s)" % (a[0], lit(a[1])),
        "changeSourceChecked": lambda: "try graph.changeSource(ofEdgeAt: %d, checked: %s)" % (a[0], lit(a[1])),
        "churn": lambda: "for _ in 0 ..< %d { graph.insert(edge: %s); graph.remove(edgeAt: graph.edges.startIndex) }" % (a[0], edge(a[1], a[2])),
        "vertexChurn": lambda: "for i in %d ..< %d { graph.insert(edge: DirectedEdge(from: i, to: i + 1)); graph.remove(i) }" % (a[0], a[0] + a[1]),
    }[k]()


def predicate_body(chosen):
    """The Swift predicate of a removeAllEdges(…where:) row, recording the positions it is called with."""
    return "{ visited.append($0); return %s }" % ("%s.contains($0)" % arr(chosen, "Int") if chosen else "false")


def call_lines(port, spec, op, t, ind="        "):
    k = op[0]
    if k in ("removeFromWhere", "removeWhere"):
        # The predicate sees each candidate position once, in row order (rows in vertices order).
        visit = port.visit_order(op[1] if k == "removeFromWhere" else None)
        r = step(port, spec, op)
        call = ("graph.removeAllEdges(from: %s, where: %s)" % (lit(op[1]), predicate_body(op[2])) if k == "removeFromWhere"
                else "graph.removeAllEdges(where: %s)" % predicate_body(op[1]))
        return r, [ind + "do {", ind + "    var visited: [Int] = []", ind + "    let removed = " + call,
                   ind + "    #expect(removed == %d)" % r, ind + "    #expect(visited == %s)" % arr(visit, "Int"), ind + "}"]
    r = step(port, spec, op)
    if isinstance(r, ref.Throws):
        # A failed checked: call; the state lines after it show nothing changed.
        # A struct error is matched by type; a case of the compound ElementNotFound by value.
        error = r.error if "." in r.error else r.error + ".self"
        return r, [ind + "#expect(throws: %s) { %s }" % (error, call_text(op))]
    if k in ("insertChecked", "outDegreeChecked", "inDegreeChecked", "degreeChecked", "vertexIndexChecked", "sourceChecked",
             "targetChecked"):
        return r, [ind + "#expect(%s == %s)" % (call_text(op), lit(r))]
    if k in ("successorsChecked", "predecessorsChecked", "outEdgesChecked", "inEdgesChecked"):
        return r, [ind + "#expect(try Array(%s) == %s)" % (call_text(op)[4:], arr(r, "Int" if k in ("outEdgesChecked", "inEdgesChecked") else t))]
    if k in ("descendantsChecked", "ancestorsChecked"):
        return r, [ind + "#expect(%s == Set(%s))" % (call_text(op), arr(r, t))]
    if k in ("changeTargetChecked", "changeSourceChecked"):
        assert isinstance(r, ref.Done)
        return r, [ind + call_text(op)]
    if k == "insert":
        return r, [ind + "do {", ind + "    let result = graph.insert(%s)" % lit(op[1]),
                   ind + "    #expect(%sresult.inserted)" % ("" if r[0] else "!"),
                   ind + "    #expect(result.memberAfterInsert == %s)" % lit(r[1]), ind + "}"]
    if k in ("removeEdge", "removeAt", "edgeAt"):
        return r, [ind + "#expect(%s == %s)" % (call_text(op), "nil" if r is None else edge(*r))]
    if k in STATEMENTS:
        return r, [ind + call_text(op)]
    if k in ("successors", "outEdges", "inEdges", "edgesFromTo"):
        return r, [ind + "#expect(%s == %s)" % (call_text(op), arr(r, "Int" if k in ("outEdges", "inEdges", "edgesFromTo") else t))]
    if k == "remove":
        return r, [ind + "#expect(%s == %s)" % (call_text(op), opt(r))]
    if k in ("edge", "removeAllBetween", "source", "vertexAtIndex", "vertexIndex", "edgeIndex", "vertexAt"):
        return r, [ind + "#expect(%s == %s)" % (call_text(op), lit(r))]
    if k in ("edgesIndicesContains", "verticesIndicesContains", "contains", "containsEdge"):
        return r, [ind + "#expect(%s%s)" % ("" if r else "!", call_text(op))]
    if k == "degrees":
        v = lit(op[1])
        return r, [ind + "#expect(graph.outDegree(of: %s) == %d)" % (v, r[0]), ind + "#expect(graph.inDegree(of: %s) == %d)" % (v, r[1]),
                   ind + "#expect(graph.degree(of: %s) == %d)" % (v, r[2])]
    if k == "bfs":
        return r, [ind + "let discovered = graph.breadthFirstSearch(from: %s).compactMap { event -> %s? in" % (lit(op[1]), t),
                   ind + "    if case .discover(let vertex) = event { return vertex }",
                   ind + "    return nil", ind + "}", ind + "#expect(discovered == %s)" % arr(r, t)]
    if k == "numbering":
        # With no edges, each vertex is its own weak component, numbered in `vertices` order:
        # the numbering an algorithm uses when vertexIndexBound is nil.
        assert not port.edges()
        return r, [ind + "#expect(graph.weaklyConnectedComponents().map { Array($0) } == %s)" % nested([[v] for v in r], t),
                   ind + "#expect(graph.vertexIndexBound == nil)"]
    if k == "compact":
        V, E = port.vertices(), port.edges()
        return r, [ind + "let compacted = DirectedPseudograph<%s>(graph)" % t,
                   ind + "#expect(Array(compacted.vertices) == %s)" % arr([v for v, _ in V], t),
                   ind + "#expect(compacted.edges.map { [$0.source, $0.target] } == %s)" % nested([[a, b] for _, a, b in E], t),
                   ind + "#expect(Array(compacted.edges.indices) == %s)" % arr(list(range(len(E))), "Int"),
                   ind + "// Edge k of the copy is the kth live position.",
                   ind + "#expect(Array(graph.edges.indices) == %s)" % arr([p for p, _, _ in E], "Int"),
                   ind + "#expect(compacted.vertexIndexBound == %d)" % len(V),
                   ind + "#expect(compacted.edgeIndexBound == %d)" % len(E)]
    raise ValueError(op)


def header(n, tags=()):
    return ['    @Test("SG-%03d %s"%s)' % (n, title(n), (", .tags(%s)" % ", ".join(tags)) if tags else "")]


def case_test(n):
    _, group, ttl, V, E, ops, note = ROWS[n]
    t = vty(V, E, [o[1:] for o in ops])
    lines = header(n)
    lines.append("    func sg%03d()%s {" % (n, " throws" if any(o[0] in CHECKED for o in ops) else ""))
    lines.append("        // %s" % inp(n))
    port, spec = build(V, E)
    mut = any(o[0] in MUTATING for o in ops)
    lines.append("        " + construct(V, E, t, mutable=mut))
    shown = []
    for i, op in enumerate(ops):
        r, ls = call_lines(port, spec, op, t)
        shown.append(r if op[0] == "compact" else ref.show_result(r))
        lines += ls
        if op[0] in MUTATING and i != len(ops) - 1 and any(o[0] in MUTATING for o in ops[i + 1:]):
            lines.append("        // Positions after %s." % ref.show_op(op))
            lines += position_lines(port, t)
    exp = ("; ".join(shown) + " ⇒ " if shown else "") + ref.show_state(port) + (" (%s)" % note if note else "")
    assert exp == cell(n), (n, exp, cell(n))
    lines.append("        // Final state.")
    lines += state_lines(port, t)
    lines += alternatives(n, V, E, t)
    lines.append("    }")
    return lines


def alternatives(n, V, E, t):
    """The other initializers, on the construction rows they fit: the same state."""
    if n > 6:
        return []
    port, _ = build(V, E)
    out = []
    if n == 1:
        out.append(["let built = StableDirectedGraph<%s>()" % t])
    if not E:
        out.append(["let built = StableDirectedGraph<%s>(vertices: %s)" % (t, arr(V, t))])
    if not V:
        out.append(["let built = StableDirectedGraph<%s>(edges: %s)" % (t, edges_lit(E, t))])
    if V or E:
        out.append(["let built = StableDirectedGraph<%s> {" % t] + ["    " + lit(v) for v in V] + ["    " + edge(a, b) for a, b in E] + ["}"])
    lines = []
    for build_lines in out:
        lines.append("        do {")
        lines += ["            " + l for l in build_lines]
        lines += ["    " + l for l in state_lines(port, t, var="built")]
        lines.append("        }")
    return lines


def trap_test(n):
    _, group, ttl, V, E, ops, note = ROWS[n]
    t = vty(V, E, [o[1:] for o in ops])
    *setup, last = ops
    lines = header(n)
    lines.append("    func sg%03d() async {" % n)
    lines.append("        // %s → %s" % (inp(n), cell(n)))
    port, spec = build(V, E)
    mut = any(o[0] in MUTATING for o in ops)
    lines.append("        await #expect(processExitsWith: .failure) {")
    lines.append("            " + construct(V, E, t, mutable=mut))
    for op in setup + [last]:
        c = call_text(op)
        lines.append("            " + (c if op[0] in STATEMENTS else "_ = " + c))
    lines.append("        }")
    lines.append("        // Without the call: the setup's results and the state the call would apply to.")
    setup_mut = any(o[0] in MUTATING for o in setup)
    lines.append("        " + construct(V, E, t, mutable=setup_mut))
    shown = []
    for op in setup:
        r, ls = call_lines(port, spec, op, t)
        shown.append(ref.show_result(r))
        lines += ls
    try:
        step(port, spec, last)
        raise AssertionError("no trap: %d" % n)
    except ref.Trap:
        pass
    assert ("; ".join(shown) + "; " if shown else "") + "**trap**" == cell(n), n
    lines += state_lines(port, t)
    lines.append("    }")
    return lines


# ---------------------------------------------------------------------------------------------
# Raw rows
# ---------------------------------------------------------------------------------------------

def model_after(V, E, ops):
    port, spec = build(V, E)
    for op in ops:
        step(port, spec, op)
    return port


def setup_lines(V, E, ops, t, var="graph"):
    lines = ["        " + construct(V, E, t, var=var, mutable=bool(ops))]
    for op in ops:
        c = call_text(op).replace("graph.", var + ".", 1)
        lines.append("        " + (c if op[0] in STATEMENTS else "_ = " + c))
    return lines


def raw_074():
    n = 74
    g = model_after([2, 0], [(2, 0), (0, 0), (2, 0)], [])
    assert cell(n) == ref.show_state(g)
    lines = header(n, [".conformance"]) + ["    func sg074() {", "        // %s" % inp(n)]
    lines.append("        let source = DirectedPseudograph<Int>(vertices: [2, 0], edges: %s)" % edges_lit([(2, 0), (0, 0), (2, 0)], "Int"))
    lines.append("        let graph = StableDirectedGraph<Int>(source)")
    lines += state_lines(g, "Int")
    lines.append("    }")
    return lines


def raw_075():
    n = 75
    g = model_after([0, 1], [(0, 1), (1, 0)], [("removeAt", 0)])
    assert cell(n) == ref.show_state(g)
    lines = header(n, [".conformance"]) + ["    func sg075() {", "        // %s" % inp(n)]
    lines += setup_lines([0, 1], [(0, 1), (1, 0)], [("removeAt", 0)], "Int", var="original")
    lines.append("        // Through the concrete argument and through a generic one: unchanged, holes and ends kept.")
    lines.append("        func rebuilt<G: DirectedGraph<Int>>(_ graph: G) -> StableDirectedGraph<Int> { StableDirectedGraph(graph) }")
    lines.append("        for graph in [StableDirectedGraph<Int>(original), rebuilt(original)] {")
    lines += ["    " + l for l in state_lines(g, "Int")]
    lines.append("        }")
    lines.append("    }")
    return lines


def raw_076():
    n = 76
    g = model_after([0, 1, 2], [(0, 1), (1, 2)], [("removeAt", 0)])
    V, E, rows, _, _, vib, eib = ref.snapshot(g)
    by = {p: (a, b) for p, a, b in E}
    exp = "edges [%s]; incidentEdges(of: 1) %s; incidentEdges(of: 0) %s; vertexIndexBound %s; edgeIndexBound %s" % (
        ", ".join("%d:%s–%s" % (p, a, b) for p, a, b in E), ref.lst(rows[1][0] + rows[1][1]), ref.lst(rows[0][0] + rows[0][1]),
        opt(vib), opt(eib))
    assert exp == cell(n), (exp, cell(n))
    lines = header(n, [".conformance"]) + ["    func sg076() {", "        // %s" % inp(n)]
    lines += setup_lines([0, 1, 2], [(0, 1), (1, 2)], [("removeAt", 0)], "Int")
    lines.append("        let view = graph.undirected")
    lines.append("        #expect(Array(view.edges.indices) == %s)" % arr([p for p, _, _ in E], "Int"))
    lines.append("        #expect(view.edges.map { [$0.u, $0.v] } == %s)" % nested([[a, b] for _, a, b in E], "Int"))
    for v, _ in V:
        o, i = rows[v]
        lines.append("        #expect(Array(view.incidentEdges(of: %s)) == %s)" % (lit(v), arr(o + i, "Int")))
        lines.append("        #expect(Array(view.neighbors(of: %s)) == %s)" % (lit(v), arr([by[p][1] for p in o] + [by[p][0] for p in i], "Int")))
    lines.append("        #expect(view.vertexIndexBound == %s)" % opt(vib))
    lines.append("        #expect(view.edgeIndexBound == %s)" % opt(eib))
    lines.append("    }")
    return lines


def raw_077():
    n = 77
    # A graph with vertex and edge holes; checked on the model that the instance has both kinds.
    V = [0, 1, 2, 3, 4, 5, 6]
    E = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 3), (4, 5), (5, 6), (6, 5), (0, 6), (3, 3), (1, 4)]
    ops = [("remove", 1), ("removeAt", 5), ("edge", 6, 1), ("edge", 1, 0), ("removeAt", 8)]
    g = model_after(V, E, ops)
    assert g.vertexIndexBound() is None and g.edgeIndexBound() is None
    D = [0, 1, 2, 3, 4, 5]
    DE = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4), (0, 5), (5, 4)]
    dops = [("remove", 1), ("removeAt", 4), ("edge", 1, 3)]
    d = model_after(D, DE, dops)
    assert d.vertexIndexBound() is None and d.edgeIndexBound() is None
    lines = header(n, [".conformance"]) + ["    func sg077() throws {", "        // %s → %s" % (inp(n), cell(n))]
    lines += setup_lines(V, E, ops, "Int")
    lines.append("        #expect(graph.vertexIndexBound == nil && graph.edgeIndexBound == nil)")
    lines.append("        let compacted = DirectedPseudograph<Int>(graph)")
    lines.append("        let positions = Array(graph.edges.indices)")
    lines.append("        #expect(Array(graph.stronglyConnectedComponents().map { Array($0) }) == Array(compacted.stronglyConnectedComponents().map { Array($0) }))")
    lines.append("        // Weights by position, in an array sized edges.endIndex; the copy reads them through `positions`.")
    lines.append("        let weight = (0 ..< graph.edges.endIndex).map { ($0 * 7 + 3) % 5 + 1 }")
    lines.append("        for source in graph.vertices {")
    lines.append("            let tree = graph.dijkstraShortestPaths(from: source) { weight[$0] }")
    lines.append("            let copy = compacted.dijkstraShortestPaths(from: source) { weight[positions[$0]] }")
    lines.append("            for vertex in graph.vertices {")
    lines.append("                #expect(tree.distance(to: vertex) == copy.distance(to: vertex))")
    lines.append("                #expect(tree.parentEdge(of: vertex) == copy.parentEdge(of: vertex).map { positions[$0] })")
    lines.append("            }")
    lines.append("        }")
    lines.append("        // An acyclic graph with holes sorts as its compacted copy does.")
    lines += [l.replace(" graph ", " dag ") for l in setup_lines(D, DE, dops, "Int", var="dag")]
    lines.append("        #expect(dag.vertexIndexBound == nil && dag.edgeIndexBound == nil)")
    lines.append("        let order = try #require(dag.topologicalSort())")
    lines.append("        #expect(order == DirectedPseudograph<Int>(dag).topologicalSort())")
    lines.append("        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })")
    lines.append("        #expect(dag.edges.allSatisfy { rank[$0.source]! < rank[$0.target]! })")
    lines.append("        #expect(graph.topologicalSort() == nil)")
    lines.append("    }")
    return lines


EQS = {
    78: (([0, 1], [(0, 1), (0, 1)], [("removeAt", 0)]), ([0, 1], [(0, 1)], [])),
    79: (([9, 0], [], [("remove", 9), ("insert", 1)]), ([0, 1], [], [])),
    80: (([0, 1], [(0, 1), (0, 1)], []), ([0, 1], [(0, 1)], [])),
    81: (([0, 1], [(0, 1)], []), ([0, 1], [(1, 0)], [])),
}


def equality_test(n):
    (V1, E1, o1), (V2, E2, o2) = EQS[n]
    g, h = model_after(V1, E1, o1), model_after(V2, E2, o2)
    from collections import Counter
    eq = (set(v for v, _ in g.vertices()) == set(v for v, _ in h.vertices())
          and Counter((a, b) for _, a, b in g.edges()) == Counter((a, b) for _, a, b in h.edges()))
    assert cell(n) == ("true; equal hashes" if eq and n == 78 else str(eq).lower()), n
    lines = header(n, [".conformance"]) + ["    func sg%03d() {" % n, "        // %s → %s" % (inp(n), cell(n))]
    lines += setup_lines(V1, E1, o1, "Int", var="lhs")
    lines += setup_lines(V2, E2, o2, "Int", var="rhs")
    if eq:
        lines += ["        #expect(lhs == rhs)", "        #expect(rhs == lhs)", "        #expect(lhs.hashValue == rhs.hashValue)",
                  "        #expect(Set([lhs, rhs]).count == 1)",
                  "        // Equal values can still differ in positions.",
                  "        #expect(Array(lhs.edges.indices) != Array(rhs.edges.indices) || Array(lhs.vertices.indices) != Array(rhs.vertices.indices))"]
    else:
        lines += ["        #expect(lhs != rhs)", "        #expect(rhs != lhs)", "        #expect(Set([lhs, rhs]).count == 2)"]
    lines += ["        #expect(lhs == lhs)", "    }"]
    return lines


def swift_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def sorted_json(d):
    return json.dumps(d, separators=(",", ":"), sort_keys=True, ensure_ascii=False)


def encode_test(n, V, E, ops, then=(), roundtrip_cell=False):
    g = model_after(V, E, ops)
    payload = ref.encode(g)
    catalog = json.dumps(payload, separators=(",", ":"))
    lines = header(n, [".conformance"]) + ["    func sg%03d() throws {" % n, "        // %s" % inp(n)]
    lines += setup_lines(V, E, ops, "Int")
    lines.append("        let encoder = JSONEncoder()")
    lines.append("        encoder.outputFormatting = .sortedKeys")
    lines.append("        let data = try encoder.encode(graph)")
    lines.append("        #expect(String(decoding: data, as: UTF8.self) == %s)" % swift_string(sorted_json(payload)))
    lines.append("        // The payload as the catalog writes it decodes the same way.")
    lines.append("        for payload in [data, Data(%s.utf8)] {" % swift_string(catalog))
    lines.append("            var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)")
    lines.append("            #expect(decoded == graph)")
    h = ref.decode(payload)
    assert ref.snapshot(h) == ref.snapshot(g)
    lines += ["    " + l for l in state_lines(h, "Int", var="decoded")]
    # The plain model of the decoded state, so later calls step both models.
    sp = ref.Spec()
    sp.V, sp.vend, sp.E, sp.eend = list(g.vertices()), g.vertex_end(), list(g.edges()), g.edge_end()
    lines.append("            // The next insertions get the fresh positions they would have got before encoding.")
    for op in then:
        r, ls = call_lines(h, sp, op, "Int", ind="            ")
        lines += [l.replace("graph.", "decoded.") for l in ls]
    if then:
        lines += ["    " + l for l in state_lines(h, "Int", var="decoded")]
    else:
        lines.append("            #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == %d)" % g.edge_end())
        lines.append("            #expect(decoded.vertices.firstIndex(of: -1) == %d)" % g.vertex_end())
    lines.append("        }")
    lines.append("    }")
    return lines, catalog, h


def codable_tests():
    out = {}
    V, E, ops = [0, 1, 2], [(0, 1), (1, 2), (2, 0), (0, 0)], [("remove", 1), ("insert", 3)]
    lines, catalog, _ = encode_test(82, V, E, ops)
    assert catalog == cell(82)
    out[82] = lines
    lines, _, h = encode_test(83, V, E, ops, then=[("insert", 4), ("edge", 4, 0)])
    assert ref.show_state(h) == cell(83)
    out[83] = lines
    lines, catalog, _ = encode_test(84, [], [], [])
    assert catalog == cell(84)
    out[84] = lines
    hv = ([0], [(0, 0), (0, 0)], [("removeAt", 0), ("removeAt", 1), ("remove", 0)])
    lines, catalog, h = encode_test(85, *hv)
    assert catalog + " ⇒ " + ref.show_state(h) == cell(85)
    out[85] = lines
    for n in [n for n in range(86, N + 1) if CELLS[n][1] == "Codable" and cell(n).startswith("dataCorrupted(")]:
        payload = inp(n)
        err = str(ref.decode(json.loads(payload)))
        assert err == cell(n)
        key, message = err[len("dataCorrupted("):].split("): ")
        out[n] = header(n, [".conformance"]) + [
            "    func sg%03d() {" % n, "        // %s → %s" % (payload, cell(n)),
            "        let payload = Data(%s.utf8)" % swift_string(payload),
            "        do {",
            "            let decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: payload)",
            "            Issue.record(\"decoded \\(decoded)\")",
            "        } catch let DecodingError.dataCorrupted(context) {",
            "            #expect(context.debugDescription == %s)" % swift_string(message),
            "            #expect(context.codingPath.last?.stringValue == %s)" % swift_string(key),
            "        } catch {",
            "            Issue.record(\"unexpected error \\(error)\")",
            "        }",
            "    }"]
    # Payloads that decode, far ends included: the full state, then the next fresh positions.
    for n, d in ref.DECODED.items():
        payload = inp(n)
        assert json.loads(payload) == d
        h = ref.decode(d)
        assert ref.show_state(h) == cell(n)
        out[n] = header(n, [".conformance"]) + [
            "    func sg%03d() throws {" % n, "        // %s → %s" % (payload, cell(n)),
            "        var decoded = try JSONDecoder().decode(StableDirectedGraph<Int>.self, from: Data(%s.utf8))" % swift_string(payload)]
        out[n] += state_lines(h, "Int", var="decoded")
        if h.edge_end() < 2 ** 63 - 1:
            out[n].append("        #expect(decoded.insert(edge: DirectedEdge(from: -1, to: -1)) == %d)" % h.edge_end())
        else:
            out[n].append("        // edgeEnd is Int.max: no edge position is left (extra_traps.swift traps on the next insert).")
            out[n].append("        #expect(decoded.insert(-1).inserted)")
        out[n] += ["        #expect(decoded.vertices.firstIndex(of: -1) == %d)" % h.vertex_end(), "    }"]
    return out


def map_values_lines(var, name, kind, m, value, ind="        "):
    """Every position below the end: the ones with a value, and the values, so a dead position
    holding a value fails too."""
    items = sorted(m.items())
    at = "ofEdgeAt" if kind == "Edge" else "ofVertexAt"
    end = "%s.%s.endIndex" % (var, "edges" if kind == "Edge" else "vertices")
    return [ind + "#expect((0 ..< %s).filter { %s[%s, %s: $0] != nil } == %s)" % (end, var, name, at, arr([p for p, _ in items], "Int")),
            ind + "#expect((0 ..< %s).compactMap { %s[%s, %s: $0] } == %s)" % (end, var, name, at, arr([x for _, x in items], value))]


def map_test(n):
    V, E, ops = ref.MAPS[n]
    t = vty(V, E, [o[1:] for o in ops if o[0] not in ref.MAP_OPS])
    port, spec = build(V, E)
    lines = header(n) + ["    func sg%03d() {" % n, "        // %s" % inp(n)]
    lines.append("        " + construct(V, E, t, mutable=True))
    maps, snap, shown, types = ref.MapModel(), None, [], {}
    for op in ops:
        k = op[0]
        if k in ref.MAP_OPS:
            r, snap = ref.map_step(port, maps, snap, op)
            if r is not None: shown.append(r)
            if k in ("addEdgeMap", "addVertexMap"):
                types[op[1]] = op[2]
                lines.append("        let %s = graph.%s(of: %s.self)" % (op[1], k, op[2]))
            elif k == "removeMap":
                lines.append("        graph.removeEdgeMap(%s)" % op[1])
            elif k in ("eset", "vset"):
                lines.append("        graph[%s, %s: %d] = %s" % (op[1], "ofEdgeAt" if k == "eset" else "ofVertexAt", op[2], opt(op[3])))
            elif k == "vsetOf":
                lines.append("        graph[%s, of: %s] = %s" % (op[1], lit(op[2]), lit(op[3])))
            elif k in ("eget", "vget"):
                lines.append("        #expect(graph[%s, %s: %d] == %s)" % (op[1], "ofEdgeAt" if k == "eget" else "ofVertexAt", op[2], "nil" if r == "nil" else lit(json.loads(r) if r.startswith('"') else int(r))))
            elif k == "vgetOf":
                lines.append("        #expect(graph[%s, of: %s] == %s)" % (op[1], lit(op[2]), "nil" if r == "nil" else lit(json.loads(r) if r.startswith('"') else int(r))))
            elif k in ("evalues", "vvalues"):
                lines += map_values_lines("graph", op[1], maps.kind[op[1]], maps.values[op[1]], types[op[1]])
            elif k == "snapshot":
                lines.append("        let copy = graph")
            elif k == "snapshotValues":
                lines += map_values_lines("copy", op[1], snap[1].kind[op[1]], snap[1].values[op[1]], types[op[1]])
        else:
            r, ls = call_lines(port, spec, op, t)
            maps.settle(port, op)
            shown.append(ref.show_result(r))
            lines += ls
    assert "; ".join(shown) + " ⇒ " + ref.show_state(port) == cell(n), n
    lines.append("        // Final state.")
    lines += state_lines(port, t)
    lines.append("    }")
    return lines


def description_tests():
    out = {}
    g = model_after([0, 1, 2], [(0, 1), (1, 2)], [("removeAt", 0)])
    d = ref.lst([v for v, _ in g.vertices()]) + "; [" + ", ".join("%s→%s" % (a, b) for _, a, b in g.edges()) + "]"
    assert d == cell(95)
    out[95] = header(95) + ["    func sg095() {", "        // %s" % inp(95)] + setup_lines([0, 1, 2], [(0, 1), (1, 2)], [("removeAt", 0)], "Int") + [
        "        #expect(graph.description == %s)" % swift_string(d),
        "        #expect(String(describing: graph) == %s)" % swift_string(d), "    }"]
    g = model_after([0, 1], [(0, 1)], [("remove", 0)])
    dd = "StableDirectedGraph<Int>(vertexCount: %d, edgeCount: %d, vertices: %s, edges: [%s])" % (
        len(g.vertices()), len(g.edges()), ref.lst([v for v, _ in g.vertices()]), ", ".join("%s→%s" % (a, b) for _, a, b in g.edges()))
    assert dd == cell(96)
    out[96] = header(96) + ["    func sg096() {", "        // %s" % inp(96)] + setup_lines([0, 1], [(0, 1)], [("remove", 0)], "Int") + [
        "        #expect(graph.debugDescription == %s)" % swift_string(dd),
        "        #expect(String(reflecting: graph) == %s)" % swift_string(dd), "    }"]
    return out


def raw_trap(n):
    if n == 64:
        assert inp(n) == "V [0]; E [0→0] / edges.index(after: edges.endIndex)"
        return header(n) + ["    func sg064() async {", "        // %s → %s" % (inp(n), cell(n)),
                            "        await #expect(processExitsWith: .failure) {",
                            "            let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])",
                            "            _ = graph.edges.index(after: graph.edges.endIndex)", "        }",
                            "        // Without the call: the last live position steps to endIndex.",
                            "        let graph = StableDirectedGraph<Int>(vertices: [0], edges: [DirectedEdge(from: 0, to: 0)])",
                            "        #expect(graph.edges.index(after: 0) == graph.edges.endIndex)",
                            "        #expect(graph.edges.endIndex == 1)", "    }"]
    if n == 65:
        assert inp(n) == "V []; E [] / reserveCapacity(vertexCount: -1, edgeCount: 0)"
        return header(n) + ["    func sg065() async {", "        // %s → %s" % (inp(n), cell(n)),
                            "        await #expect(processExitsWith: .failure) {",
                            "            var graph = StableDirectedGraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])",
                            "            graph.reserveCapacity(vertexCount: -1, edgeCount: 0)", "        }",
                            "        // Without the trap: zero is allowed and changes nothing.",
                            "        var graph = StableDirectedGraph<Int>(vertices: [] as [Int], edges: [] as [DirectedEdge<Int>])",
                            "        graph.reserveCapacity(vertexCount: 0, edgeCount: 0)",
                            "        #expect(graph == StableDirectedGraph<Int>())", "        #expect(graph.vertices.endIndex == 0)",
                            "        #expect(graph.edges.endIndex == 0)", "    }"]
    raise ValueError(n)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def is_trap(n):
    return cell(n).endswith("**trap**")


TRAPS = [n for n in range(1, N + 1) if is_trap(n)]
CODABLE = codable_tests()
DESCRIPTIONS = description_tests()


def test_for(n):
    row = ROWS[n]
    if row[0] == "case":
        return trap_test(n) if is_trap(n) else case_test(n)
    if n in (64, 65):
        return raw_trap(n)
    if n in (74, 75, 76, 77):
        return {74: raw_074, 75: raw_075, 76: raw_076, 77: raw_077}[n]()
    if n in EQS:
        return equality_test(n)
    if n in CODABLE:
        return CODABLE[n]
    if n in DESCRIPTIONS:
        return DESCRIPTIONS[n]
    if n in ref.MAPS:
        return map_test(n)
    raise ValueError(n)


def ids(group):
    return [n for n in range(1, N + 1) if CELLS[n][1] == group and n not in TRAPS]


FILES = [
    ("StableGraphConstructionTests.swift", "StableGraphs construction", ids("Construction"),
     "Construction (catalog SG-001 – SG-006): listed vertices first (a repeat once), then endpoints in\n"
     "// first-appearance order; copies and self-loops kept; every initializer gives the same state."),
    ("StableGraphInsertionTests.swift", "StableGraphs insertion", ids("Insertion"),
     "Insertion (catalog SG-007 – SG-010, SG-103, SG-104): `insert(edge:)` returns the old `edges.endIndex`\n"
     "// and inserts missing endpoints; a self-loop is once in its out-row and once in its in-row;\n"
     "// `insert(checked:)` inserts only between existing vertices and otherwise throws `VertexNotFound`,\n"
     "// changing nothing."),
    ("StableGraphEdgeRemovalTests.swift", "StableGraphs edge removal", ids("Edge removal"),
     "Edge removal (catalog SG-011 – SG-025, SG-097 – SG-102): a removed edge leaves a hole, nothing\n"
     "// moves, a removed position never returns, `remove(edge:)` takes the newest copy, rows keep\n"
     "// insertion order, and `edgeIndexBound` is nil while an edge hole exists; the one-pass bulk\n"
     "// removals call their predicate once per candidate position, in row order."),
    ("StableGraphVertexRemovalTests.swift", "StableGraphs vertex removal", ids("Vertex removal"),
     "Vertex removal (catalog SG-026 – SG-034): the vertex's slot and its edges become holes; a\n"
     "// re-inserted vertex gets a fresh position and goes last; the neighbours' rows keep their order."),
    ("StableGraphSequenceTests.swift", "StableGraphs sequences", ids("Interleaving"),
     "Interleaved sequences (catalog SG-035 – SG-040): mixed insertions and removals, churn on one pair,\n"
     "// a FlowNavigation-shaped replacement, and the two resets, `removeAllEdges()` and `removeAll()`."),
    ("StableGraphQueryTests.swift", "StableGraphs queries", ids("Queries"),
     "Queries (catalog SG-041 – SG-049, SG-105 – SG-107, SG-135 – SG-137): rows and `edges(from:to:)` in\n"
     "// insertion order across holes, membership after removals, the O(1) live-or-stale checks\n"
     "// `edges.indices.contains` and `vertices.indices.contains`, and the `checked:` lookups, which throw\n"
     "// `VertexNotFound` for a vertex not in the graph and `EdgeNotFound` for a dead edge position."),
    ("StableGraphIndexTests.swift", "StableGraphs indices, views and conversions", [n for n in ids("Conformance")],
     "Indices, views and conversions (catalog SG-066 – SG-077 without SG-062): dense indices exactly while\n"
     "// there are no holes, vertex and edge holes independent; algorithms on a graph with holes (BFS,\n"
     "// components, strongly connected components, Dijkstra by position, topological sort) against the\n"
     "// compacting `DirectedPseudograph(g)`; `init(_:)` both ways; the undirected view."),
    ("StableGraphEqualityTests.swift", "StableGraphs equality", ids("Equality and hashing"),
     "Equality and hashing (catalog SG-078 – SG-081): equal vertex sets and equal edge multisets;\n"
     "// positions and holes do not matter."),
    ("StableGraphCodableTests.swift", "StableGraphs Codable", ids("Codable"),
     "Codable (catalog SG-082 – SG-094, SG-108 – SG-116): `{vertices, vertexPositions, vertexEnd, edges, edgePositions,\n"
     "// edgeEnd}`. Encoding is checked byte for byte (with sorted keys); decoding keeps every position\n"
     "// and both ends, so the next insertions get the positions they would have got before encoding.\n"
     "// Far ends decode in O(elements); corrupt payloads, a page span past 16 × count + 64 included, throw\n"
     "// `DecodingError.dataCorrupted` with the catalog's key and message."),
    ("StableGraphDescriptionTests.swift", "StableGraphs descriptions", ids("Description"),
     "Descriptions (catalog SG-095, SG-096): the live vertices and edges, holes skipped."),
    ("StableGraphPagingTests.swift", "StableGraphs paging", ids("Paging"),
     "Paging (catalog SG-117 – SG-122): churn across freed pages keeps every live position and its\n"
     "// identity, a position in a freed page reads as removed, and algorithms see only the live vertices."),
    ("StableGraphEdgeChangeTests.swift", "StableGraphs edge changes", ids("Edge change"),
     "Edge changes (catalog SG-123 – SG-130): `changeTarget(ofEdgeAt:to:)` and `changeSource(ofEdgeAt:to:)`\n"
     "// (LEMON's `changeTarget` / `changeSource`) keep the position and the place in the unchanged\n"
     "// endpoint's row, and join the new endpoint's row in position order; the `checked:` spellings throw\n"
     "// `ElementNotFound.edge` for a dead position, then `.vertex` for a missing endpoint, and change\n"
     "// nothing."),
    ("StableGraphMapTests.swift", "StableGraphs maps", ids("Maps"),
     "Maps (catalog SG-131 – SG-134): maps attached to the graph (`addEdgeMap(of:)`, `addVertexMap(of:)`),\n"
     "// values by position or vertex, every removal path clearing the removed element's values, several\n"
     "// maps, a copy keeping its values, `changeTarget` keeping them, and `removeEdgeMap`."),
    ("StableGraphPreconditionTests.swift", "StableGraphs preconditions", TRAPS,
     "Preconditions (catalog SG-050 – SG-065): each trapping call runs in a child process (exit test).\n"
     "// The same setup then runs in this process one step short of the precondition, so the trap is\n"
     "// the call's and not the setup's. Then the preconditions the catalog does not list\n"
     "// (extra_traps.swift)."),
]

IMPORTS = {"Foundation": "Data(", "Traversal": "breadthFirstSearch(", "Connectivity": "ConnectedComponents(",
           "ShortestPaths": "dijkstraShortestPaths(", "Multigraphs": "DirectedPseudograph"}


def write(fname, suite, rows, comment):
    tests = [test_for(n) for n in rows]
    if fname == "StableGraphPreconditionTests.swift":
        extra = open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n")
        tests.append(extra)
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text_body = "\n".join(body)
    imports = ["GraphProtocols", "StableGraphs", "Testing"]
    for module, needle in IMPORTS.items():
        if needle in text_body or (module == "Connectivity" and "stronglyConnectedComponents(" in text_body) \
                or (module == "Traversal" and ("topologicalSort(" in text_body or "descendants(checked:" in text_body)):
            imports.append(module)
    if ".tags(" in text_body or fname == "StableGraphPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname == "StableGraphPreconditionTests.swift" else ""
    out = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


total = rows_total = 0
for fname, suite, rows, comment in FILES:
    k = write(fname, suite, rows, comment)
    print(fname, k)
    total += k
    rows_total += len(rows)
assert rows_total == N, rows_total
print("catalog rows", rows_total, "tests", total)
