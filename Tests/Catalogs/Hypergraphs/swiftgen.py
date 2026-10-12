"""Writes the catalog-row test files of Tests/HypergraphsTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 --with hypernetx==2.4.3 --with halp==1.0.0 \
        python3 Tests/Catalogs/Hypergraphs/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/HypergraphsTests

First checks that ref.py's model reproduces cases.md byte for byte. Then it re-runs every row on the
model (ref.py's port of both storages, checked against XGI, HyperNetX, halp, NetworkX and the laws
after every call), asserts that each value matches its catalog cell, and writes one @Test per row.
Each call's result is checked; after a mutation that another mutation follows, the test checks the
vertices and the hyperedges; the final state is written out in full: every vertex's index both ways,
every row by vertex and by index (empty ones included), every hyperedge's members (or sides) and
their indices, membership of every vertex and every hyperedge, and the bounds. Rows that read
`hashes()` also run on a vertex type whose `hash(into:)` counts, with 16 isolated vertices appended
so that the OrderedSet has a hash table (it scans linearly up to 15 elements). Hand-written exit
tests are spliced into the precondition file: extra_traps.swift.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "HypergraphsTests")

# ---------------------------------------------------------------------------------------------
# Catalog check, and the structured arguments of every row
# ---------------------------------------------------------------------------------------------
SPEC = {}   # row id -> ("case", prefix, vs, es, calls) | ("decode", prefix, obj) | ("eq", prefix, a, b, hashing)
_case, _dcase, _decode, _eq = ref.case, ref.dcase, ref.decode_case, ref.eq_case


def _next(prefix):
    return f"{prefix}-{sum(1 for r in ref.ROWS if r[0].startswith(prefix)) + 1:03d}"


def _rec_case(group, title, vs, es, calls=(), show_state=True):
    SPEC[_next("HG")] = ("case", "HG", list(vs), [list(e) for e in es], list(calls))
    _case(group, title, vs, es, calls, show_state)


def _rec_dcase(group, title, vs, es, calls=(), show_state=True):
    SPEC[_next("DH")] = ("case", "DH", list(vs), [(list(s), list(t)) for s, t in es], list(calls))
    _dcase(group, title, vs, es, calls, show_state)


def _rec_decode(prefix, cls, title, obj):
    SPEC[_next(prefix)] = ("decode", prefix, obj)
    _decode(prefix, cls, title, obj)


def _rec_eq(prefix, title, a, b, hashing=False):
    SPEC[_next(prefix)] = ("eq", prefix, a, b, hashing)
    _eq(prefix, title, a, b, hashing)


ref.case, ref.dcase, ref.decode_case, ref.eq_case = _rec_case, _rec_dcase, _rec_decode, _rec_eq
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| HG-") or line.startswith("| DH-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[parts[0]] = parts
IDS = list(CELLS)
assert len(IDS) == 151 and sorted(IDS) == sorted(SPEC), (len(IDS), len(SPEC))


def group(r): return CELLS[r][1]
def title(r): return CELLS[r][2]
def inp(r): return CELLS[r][3]
def cell(r): return CELLS[r][4]
def is_trap(r): return "**trap**" in cell(r)


# ---------------------------------------------------------------------------------------------
# Swift literals
# ---------------------------------------------------------------------------------------------

def s(x): return json.dumps(x, ensure_ascii=False)
def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "]"
def vlist(xs): return "[" + ", ".join(s(x) for x in xs) + "]"
def vlists(xss): return "[" + ", ".join(vlist(x) for x in xss) + "]"
def intlists(xss): return "[" + ", ".join(ints(x) for x in xss) + "]"


def vtype(vs, es, prefix):
    every = list(vs)
    for e in es:
        every += (list(e[0]) + list(e[1])) if prefix == "DH" else list(e)
    return "Int" if every and isinstance(every[0], int) else "String"


def u_build(t, vs, es):
    return "UndirectedIncidenceList<%s>(vertices: %s as [%s], hyperedges: %s as [[%s]])" % (t, vlist(vs), t, vlists(es), t)


def d_pairs(t, es):
    return "[" + ", ".join("(sources: %s, targets: %s)" % (vlist(a), vlist(b)) for a, b in es) + "] as [(sources: [%s], targets: [%s])]" % (t, t)


def d_build(t, vs, es):
    return "IncidenceList<%s>(vertices: %s as [%s], hyperedges: %s)" % (t, vlist(vs), t, d_pairs(t, es))


def build(prefix, t, vs, es):
    return u_build(t, vs, es) if prefix == "HG" else d_build(t, vs, es)


# ---------------------------------------------------------------------------------------------
# State: everything the model knows, written out
# ---------------------------------------------------------------------------------------------

def u_state(g, var, short=False):
    L, n, m = g.vs, len(g.vs), len(g.rows)
    lab = [[L[i] for i in r] for r in g.rows]
    out = ["#expect(Array(%s.vertices) == %s)" % (var, vlist(L)),
           "#expect(%s.hyperedges.map { Array($0) } == %s)" % (var, vlists(lab))]
    if short:
        return out
    out += ["#expect(%s.vertexCount == %d && %s.hyperedgeCount == %d && %s.hyperedges.count == %d)" % (var, n, var, m, var, m),
            "#expect(%s.vertexIndexBound == %d && %s.hyperedgeIndexBound == %d)" % (var, n, var, m),
            "#expect(%s.vertices.map { %s.vertexIndex(of: $0) } == %s)" % (var, var, ints(range(n))),
            "#expect((0 ..< %d).map { %s.vertex(atIndex: $0) } == %s)" % (n, var, vlist(L)),
            "#expect(%s.hyperedges.indices.map { %s.hyperedgeIndex(of: $0) } == %s)" % (var, var, ints(range(m)))]
    for p, r in enumerate(g.rows):
        out.append("#expect(Array(%s.members(ofHyperedgeAt: %d)) == %s && Array(%s.memberIndices(ofHyperedgeAt: %d)) == %s && %s.size(ofHyperedgeAt: %d) == %d)"
                   % (var, p, vlist(lab[p]), var, p, ints(r), var, p, len(r)))
        out.append("#expect(%s.contains(hyperedge: %s as [%s]))" % (var, vlist(list(reversed(lab[p]))), vtype(L, [], "HG")))
    for i, v in enumerate(L):
        inc = g.inc[i]
        out.append("#expect(%s.contains(%s))" % (var, s(v)))
        out.append("#expect(Array(%s.incidentHyperedges(of: %s)) == %s && Array(%s.incidentHyperedges(ofIndex: %d)) == %s)"
                   % (var, s(v), ints(inc), var, i, ints(inc)))
        out.append("#expect(%s.degree(of: %s) == %d && %s.degree(ofIndex: %d) == %d)" % (var, s(v), len(inc), var, i, len(inc)))
    return out


def d_state(g, var, short=False):
    L, n, m = g.vs, len(g.vs), len(g.src)
    ls = [[L[i] for i in r] for r in g.src]
    lt = [[L[i] for i in r] for r in g.tgt]
    out = ["#expect(Array(%s.vertices) == %s)" % (var, vlist(L)),
           "#expect(%s.hyperedges.map { [Array($0.sources), Array($0.targets)] } == %s)"
           % (var, "[" + ", ".join("[%s, %s]" % (vlist(a), vlist(b)) for a, b in zip(ls, lt)) + "]")]
    if short:
        return out
    t = vtype(L, [], "HG")
    out += ["#expect(%s.vertexCount == %d && %s.hyperedgeCount == %d && %s.hyperedges.count == %d)" % (var, n, var, m, var, m),
            "#expect(%s.vertexIndexBound == %d && %s.hyperedgeIndexBound == %d)" % (var, n, var, m),
            "#expect(%s.vertices.map { %s.vertexIndex(of: $0) } == %s)" % (var, var, ints(range(n))),
            "#expect((0 ..< %d).map { %s.vertex(atIndex: $0) } == %s)" % (n, var, vlist(L)),
            "#expect(%s.hyperedges.indices.map { %s.hyperedgeIndex(of: $0) } == %s)" % (var, var, ints(range(m)))]
    for p in range(m):
        out.append("#expect(Array(%s.sources(ofHyperedgeAt: %d)) == %s && Array(%s.sourceIndices(ofHyperedgeAt: %d)) == %s)"
                   % (var, p, vlist(ls[p]), var, p, ints(g.src[p])))
        out.append("#expect(Array(%s.targets(ofHyperedgeAt: %d)) == %s && Array(%s.targetIndices(ofHyperedgeAt: %d)) == %s)"
                   % (var, p, vlist(lt[p]), var, p, ints(g.tgt[p])))
        out.append("#expect(%s.contains(sources: %s as [%s], targets: %s as [%s]))"
                   % (var, vlist(list(reversed(ls[p]))), t, vlist(list(reversed(lt[p]))), t))
    for i, v in enumerate(L):
        o, k = g.out[i], g.inn[i]
        out.append("#expect(%s.contains(%s))" % (var, s(v)))
        out.append("#expect(Array(%s.outHyperedges(of: %s)) == %s && Array(%s.outHyperedges(ofIndex: %d)) == %s)"
                   % (var, s(v), ints(o), var, i, ints(o)))
        out.append("#expect(Array(%s.inHyperedges(of: %s)) == %s && Array(%s.inHyperedges(ofIndex: %d)) == %s)"
                   % (var, s(v), ints(k), var, i, ints(k)))
        out.append("#expect(%s.outDegree(of: %s) == %d && %s.outDegree(ofIndex: %d) == %d && %s.inDegree(of: %s) == %d && %s.inDegree(ofIndex: %d) == %d)"
                   % (var, s(v), len(o), var, i, len(o), var, s(v), len(k), var, i, len(k)))
        out.append("#expect(%s.degree(of: %s) == %d)" % (var, s(v), len(o) + len(k)))
    return out


def state(g, var, ind, short=False):
    lines = d_state(g, var, short) if isinstance(g, ref.DHG) else u_state(g, var, short)
    return [ind + l for l in lines]


# ---------------------------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------------------------
MUTATING = {"insert", "insert(hyperedge:)", "insert(checked:)", "insert(sources:targets:)", "insert(checked:targets:)", "removeAll"}


def view_lines(x, var, directed, ind):
    _, count, edges, arrow = x
    out = ["let view = %s.incidenceGraphView" % var,
           "#expect(view.vertices == 0 ..< %d)" % count,
           "#expect(view.edges.map { [$0.%s, $0.%s] } == %s)" % ((("source", "target") if directed else ("u", "v")) + (intlists(edges),)),
           "#expect(Array(view.edges.indices) == %s)" % ints(range(len(edges))),
           "#expect(view.vertexCount == %d && view.edgeCount == %d && view.vertexIndexBound == %d && view.edgeIndexBound == %d)"
           % (count, len(edges), count, len(edges)),
           "#expect(view.base == %s)" % var]
    for x_ in range(count):
        if directed:
            o = [q for q, (a, b) in enumerate(edges) if a == x_]
            k = [q for q, (a, b) in enumerate(edges) if b == x_]
            succ, pred = [edges[q][1] for q in o], [edges[q][0] for q in k]
            out.append("#expect(Array(view.successors(of: %d)) == %s && Array(view.successorIndices(ofIndex: %d)) == %s && Array(view.outEdges(of: %d)) == %s && Array(view.outEdges(ofIndex: %d)) == %s)"
                       % (x_, ints(succ), x_, ints(succ), x_, ints(o), x_, ints(o)))
            out.append("#expect(Array(view.predecessors(of: %d)) == %s && Array(view.predecessorIndices(ofIndex: %d)) == %s && Array(view.inEdges(of: %d)) == %s && Array(view.inEdges(ofIndex: %d)) == %s)"
                       % (x_, ints(pred), x_, ints(pred), x_, ints(k), x_, ints(k)))
            out.append("#expect(view.outDegree(of: %d) == %d && view.inDegree(of: %d) == %d && view.outDegree(ofIndex: %d) == %d && view.inDegree(ofIndex: %d) == %d)"
                       % (x_, len(o), x_, len(k), x_, len(o), x_, len(k)))
        else:
            inc = [q for q, (a, b) in enumerate(edges) if x_ in (a, b)]
            nb = [edges[q][1] if edges[q][0] == x_ else edges[q][0] for q in inc]
            out.append("#expect(Array(view.neighbors(of: %d)) == %s && Array(view.neighborIndices(ofIndex: %d)) == %s)" % (x_, ints(nb), x_, ints(nb)))
            out.append("#expect(Array(view.incidentEdges(of: %d)) == %s && Array(view.incidentEdges(ofIndex: %d)) == %s && Array(view.incidentEdgeIndices(ofIndex: %d)) == %s)"
                       % (x_, ints(inc), x_, ints(inc), x_, ints(inc)))
            out.append("#expect(view.degree(of: %d) == %d && view.degree(ofIndex: %d) == %d)" % (x_, len(inc), x_, len(inc)))
    if edges:
        if directed:
            out.append("#expect(view.edges.indices.map { [view.sourceIndex(ofEdgeAt: $0), view.targetIndex(ofEdgeAt: $0)] } == %s)" % intlists(edges))
            out.append("#expect(view.edges.indices.map { view.edgeIndex(of: $0) } == %s)" % ints(range(len(edges))))
        else:
            out.append("#expect(view.edges.indices.map { [view.endpointIndices(ofEdgeAt: $0).u, view.endpointIndices(ofEdgeAt: $0).v] } == %s)" % intlists(edges))
            out.append("#expect(view.edges.indices.map { view.edgeIndex(of: $0) } == %s)" % ints(range(len(edges))))
    return ["do {"] + ["    " + l for l in out] + ["}"]


def call_lines(g, call, var="hypergraph"):
    """The call's result on the model, and the Swift lines that check it."""
    r = ref.run_call(g, call)
    (ref.check_d if isinstance(g, ref.DHG) else ref.check)(g)
    name, *a = call
    directed = isinstance(g, ref.DHG)

    def ex(text): return ["#expect(%s)" % text]

    def checked(call, wrap, expected):
        """A `checked:` call: its value through `try`, or the throw."""
        if r is ref.NOT_FOUND:
            return r, ["#expect(throws: VertexNotFound.self) { try %s.%s }" % (var, call)]
        return r, ex("try %s == %s" % (wrap % ("%s.%s" % (var, call)), expected))

    t = vtype(g.vs, [], "HG") if g.vs else "String"
    if name in ref.AT_LABEL:
        if name.endswith("Indices"):
            return r, ex("Array(%s.%s(ofHyperedgeAt: %d)) == %s" % (var, name, a[0], ints(r)))
        if name == "size":
            return r, ex("%s.size(ofHyperedgeAt: %d) == %d" % (var, a[0], r))
        return r, ex("Array(%s.%s(ofHyperedgeAt: %d)) == %s" % (var, name, a[0], vlist(r)))
    if name in ("incidentHyperedges", "outHyperedges", "inHyperedges"):
        return r, ex("Array(%s.%s(of: %s)) == %s" % (var, name, s(a[0]), ints(r)))
    if name in ("incidentHyperedges(ofIndex:)", "outHyperedges(ofIndex:)", "inHyperedges(ofIndex:)"):
        return r, ex("Array(%s.%s %d)) == %s" % (var, name[:-2] + ":", a[0], ints(r)))
    if name in ("incidentHyperedges(checked:)", "outHyperedges(checked:)", "inHyperedges(checked:)"):
        return checked("%s %s)" % (name[:-2] + ":", s(a[0])), "Array(%s)", "" if r is ref.NOT_FOUND else ints(r))
    if name in ("degree", "outDegree", "inDegree"):
        return r, ex("%s.%s(of: %s) == %d" % (var, name, s(a[0]), r))
    if name == "degree(ofIndex:)":
        return r, ex("%s.degree(ofIndex: %d) == %d" % (var, a[0], r))
    if name in ("degree(checked:)", "outDegree(checked:)", "inDegree(checked:)"):
        return checked("%s %s)" % (name[:-2] + ":", s(a[0])), "%s", "" if r is ref.NOT_FOUND else str(r))
    if name == "contains":
        return r, ex("%s%s.contains(%s)" % ("" if r else "!", var, s(a[0])))
    if name == "contains(hyperedge:)":
        return r, ex("%s%s.contains(hyperedge: %s as [%s])" % ("" if r else "!", var, vlist(a), t))
    if name == "contains(sources:targets:)":
        return r, ex("%s%s.contains(sources: %s as [%s], targets: %s as [%s])" % ("" if r else "!", var, vlist(a[0]), t, vlist(a[1]), t))
    if name == "vertexIndex":
        return r, ex("%s.vertexIndex(of: %s) == %s" % (var, s(a[0]), r))
    if name == "vertexIndex(checked:)":
        return checked("vertexIndex(checked: %s)" % s(a[0]), "%s", "" if r is ref.NOT_FOUND else str(r))
    if name == "vertex(atIndex:)":
        return r, ex("%s.vertex(atIndex: %d) == %s" % (var, a[0], s(r)))
    if name == "counts":
        n_, m_ = r.split("/")
        return r, ex("%s.vertexCount == %s && %s.hyperedgeCount == %s" % (var, n_, var, m_))
    if name == "insert":
        return r, ["do {", "    let result = %s.insert(%s)" % (var, s(a[0])),
                   "    #expect(%sresult.inserted && result.memberAfterInsert == %s)" % ("" if r[0] else "!", s(r[1])), "}"]
    if name == "insert(hyperedge:)":
        return r, ex("%s.insert(hyperedge: %s as [%s]) == %d" % (var, vlist(a), t, r))
    if name == "insert(checked:)":
        return checked("insert(checked: %s as [%s])" % (vlist(a), t), "%s", "" if r is ref.NOT_FOUND else str(r))
    if name == "insert(sources:targets:)":
        return r, ex("%s.insert(sources: %s as [%s], targets: %s as [%s]) == %d" % (var, vlist(a[0]), t, vlist(a[1]), t, r))
    if name == "insert(checked:targets:)":
        return checked("insert(checked: %s as [%s], targets: %s as [%s])" % (vlist(a[0]), t, vlist(a[1]), t), "%s",
                       "" if r is ref.NOT_FOUND else str(r))
    if name == "removeAll":
        return r, ["%s.removeAll()" % var]
    if name in ("neighbors", "bConnectedVertices(from:)", "fConnectedVertices(to:)"):
        label = {"neighbors": "of", "bConnectedVertices(from:)": "from", "fConnectedVertices(to:)": "to"}[name]
        return r, ex("%s.%s(%s: %s) == %s" % (var, name.split("(")[0], label, s(a[0]), vlist(r)))
    if name in ("isBConnected(from:to:)", "isFConnected(from:to:)"):
        return r, ex("%s%s.%s(from: %s, to: %s)" % ("" if r else "!", var, name.split("(")[0], s(a[0]), s(a[1])))
    if name in ("rank",):
        return r, ex("%s.rank == %d" % (var, r))
    if name == "isUniform(size:)":
        return r, ex("%s%s.isUniform(size: %d)" % ("" if r else "!", var, a[0]))
    if name in ("isConnected", "isWeaklyConnected", "isStronglyConnected", "isBHypergraph", "isFHypergraph", "isBFHypergraph"):
        return r, ex("%s%s.%s" % ("" if r else "!", var, name))
    if name.endswith("Histogram"):
        return r, ex("%s.%s() == %s" % (var, name, ints(r)))
    if name in ("connectedComponents", "weaklyConnectedComponents", "stronglyConnectedComponents"):
        return r, ex("%s.%s() == %s" % (var, name, vlists(r)))
    if name == "sConnectedComponents(s:)":
        return r, ex("%s.sConnectedComponents(s: %d) == %s" % (var, a[0], intlists(r)))
    if name == "dual().sConnectedComponents(s:)":
        return r, ex("%s.dual().sConnectedComponents(s: %d) == %s" % (var, a[0], intlists(r)))
    if name == "dual":
        return r, ["do {", "    let dual = %s.dual()" % var] + state(r, "dual", "    ") + ["}"]
    if name == "reversed":
        return r, (["do {", "    let reversed = %s.reversed" % var] + state(r, "reversed", "    ")
                   + ["    #expect(reversed.reversed == %s)" % var, "}"])
    if name == "incidenceGraphView":
        return r, view_lines(r, var, directed, "")
    if name == "cliqueExpansion":
        _, vs, edges, arrow = r
        ends = ("source", "target") if directed else ("u", "v")
        return r, ["do {", "    let expansion = %s.cliqueExpansion()" % var,
                   "    #expect(Array(expansion.vertices) == %s)" % vlist(vs),
                   "    #expect(expansion.edges.map { [$0.%s, $0.%s] } == %s)" % (ends[0], ends[1], vlists([list(e) for e in edges])),
                   "    #expect(expansion.vertexCount == %d && expansion.edgeCount == %d)" % (len(vs), len(edges)), "}"]
    if name == "lineGraph(s:)":
        _, count, edges, _ = r
        return r, ["do {", "    let line = %s.lineGraph(s: %d)" % (var, a[0]),
                   "    #expect(Array(line.vertices) == %s)" % ints(range(count)),
                   "    #expect(line.edges.map { [$0.u, $0.v] } == %s)" % intlists(edges),
                   "    #expect(line.vertexCount == %d && line.edgeCount == %d)" % (count, len(edges)), "}"]
    if name in ("description", "debugDescription"):
        return r, ex("%s.%s == %s" % (var, name, s(r)))
    if name == "encode":
        obj = json.loads(r)
        if directed:
            payload = ["    struct Payload: Decodable, Equatable { let vertices: [%s]; let sources: [[Int]]; let targets: [[Int]] }" % t,
                       "    #expect(try JSONDecoder().decode(Payload.self, from: data) == Payload(vertices: %s, sources: %s, targets: %s))"
                       % (vlist(obj["vertices"]), intlists(obj["sources"]), intlists(obj["targets"]))]
            back = "IncidenceList<%s>" % t
        else:
            payload = ["    struct Payload: Decodable, Equatable { let vertices: [%s]; let hyperedges: [[Int]] }" % t,
                       "    #expect(try JSONDecoder().decode(Payload.self, from: data) == Payload(vertices: %s, hyperedges: %s))"
                       % (vlist(obj["vertices"]), intlists(obj["hyperedges"]))]
            back = "UndirectedIncidenceList<%s>" % t
        return r, (["do {", "    // %s" % r, "    let data = try JSONEncoder().encode(%s)" % var] + payload
                   + ["    let decoded = try JSONDecoder().decode(%s.self, from: data)" % back]
                   + state(g, "decoded", "    ", short=True) + ["    #expect(decoded == %s)" % var, "}"])
    if name == "hashes":
        return r, ["// hashes() is %d here: see the counted copy below." % r]
    raise ValueError(call)


def child_call(call, var="hypergraph"):
    name, *a = call
    if name in ref.AT_LABEL:
        return "_ = %s.%s(ofHyperedgeAt: %d)" % (var, name, a[0])
    if name in ("incidentHyperedges", "outHyperedges", "inHyperedges", "degree", "neighbors"):
        return "_ = %s.%s(of: %s)" % (var, name, s(a[0]))
    if name in ("incidentHyperedges(ofIndex:)", "inHyperedges(ofIndex:)", "outHyperedges(ofIndex:)"):
        return "_ = %s.%s %d)" % (var, name[:-2] + ":", a[0])
    if name == "vertex(atIndex:)":
        return "_ = %s.vertex(atIndex: %d)" % (var, a[0])
    if name == "lineGraph(s:)":
        return "_ = %s.lineGraph(s: %d)" % (var, a[0])
    if name == "sConnectedComponents(s:)":
        return "_ = %s.sConnectedComponents(s: %d)" % (var, a[0])
    if name == "isUniform(size:)":
        return "_ = %s.isUniform(size: %d)" % (var, a[0])
    if name == "bConnectedVertices(from:)":
        return "_ = %s.bConnectedVertices(from: %s)" % (var, s(a[0]))
    if name == "isFConnected(from:to:)":
        return "_ = %s.isFConnected(from: %s, to: %s)" % (var, s(a[0]), s(a[1]))
    raise ValueError(call)


# ---------------------------------------------------------------------------------------------
# Hash counting (rows that read hashes())
# ---------------------------------------------------------------------------------------------
COUNTED = [
    "// Vertex hashes, counted by a vertex whose hash(into:) counts. OrderedSet hashes only from 16",
    "// elements (up to 15 it scans), so 16 isolated vertices follow the catalog's; they come after",
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
    "let pads = (0 ..< 16).map { \"pad\\($0)\" }",
]


def counted_lines(prefix, vs, es, calls, ind="        "):
    g = ref.UHG(vs, es) if prefix == "HG" else ref.DHG(vs, es)
    g.hashes = 0
    lines = list(COUNTED)
    if prefix == "HG":
        lines.append("let counted = UndirectedIncidenceList<Counted>(vertices: (%s + pads).map(label), hyperedges: %s.map { $0.map(label) })"
                     % (vlist(vs), vlists(es)))
    else:
        lines.append("let counted = IncidenceList<Counted>(vertices: (%s + pads).map(label), hyperedges: %s.map { (sources: $0[0].map(label), targets: $0[1].map(label)) })"
                     % (vlist(vs), "[" + ", ".join("[%s, %s]" % (vlist(a), vlist(b)) for a, b in es) + "]"))
    lines += ["tally.hashes = 0", "tally.comparisons = 0"]
    later = []
    for k, c in enumerate(calls, 1):
        name, *a = c
        r = ref.run_call(g, c)
        x = "r%d" % k
        if name == "hashes":
            lines.append("#expect(tally.hashes == %d)" % r)
            if r == 0:
                lines.append("#expect(tally.comparisons == 0)")
            continue
        if name in ("incidentHyperedges(ofIndex:)", "outHyperedges(ofIndex:)", "inHyperedges(ofIndex:)"):
            lines.append("let %s = Array(counted.%s %d))" % (x, name[:-2] + ":", a[0]))
            later.append("#expect(%s == %s)" % (x, ints(r)))
        elif name == "degree(ofIndex:)":
            lines.append("let %s = counted.degree(ofIndex: %d)" % (x, a[0]))
            later.append("#expect(%s == %d)" % (x, r))
        elif name in ("memberIndices", "sourceIndices"):
            lines.append("let %s = Array(counted.%s(ofHyperedgeAt: %d))" % (x, name, a[0]))
            later.append("#expect(%s == %s)" % (x, ints(r)))
        elif name in ("incidentHyperedges", "outHyperedges"):
            lines.append("let %s = Array(counted.%s(of: label(%s)))" % (x, name, s(a[0])))
            later.append("#expect(%s == %s)" % (x, ints(r)))
        elif name.endswith("(checked:)") and r is ref.NOT_FOUND:
            lines.append("#expect(throws: VertexNotFound.self) { try counted.%s label(%s)) }" % (name[:-2] + ":", s(a[0])))
        elif name in ("incidentHyperedges(checked:)", "outHyperedges(checked:)", "inHyperedges(checked:)"):
            lines.append("let %s = try Array(counted.%s label(%s)))" % (x, name[:-2] + ":", s(a[0])))
            later.append("#expect(%s == %s)" % (x, ints(r)))
        elif name in ("degree(checked:)", "outDegree(checked:)", "inDegree(checked:)", "vertexIndex(checked:)"):
            lines.append("let %s = try counted.%s label(%s))" % (x, name[:-2] + ":", s(a[0])))
            later.append("#expect(%s == %d)" % (x, r))
        else:
            raise ValueError(c)
    lines += later
    return [ind + l for l in lines]


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

def fname(rid):
    return rid.replace("-", "").lower()


def header(rid, tags=()):
    return ['    @Test("%s %s"%s)' % (rid, title(rid), (", .tags(%s)" % ", ".join(tags)) if tags else "")]


def alternatives(prefix, t, vs, es, g):
    """Other initializers that give the same state, on the construction rows."""
    if group_of_spec(prefix, vs, es) != "Construction":
        return []
    U = prefix == "HG"
    T = ("UndirectedIncidenceList<%s>" if U else "IncidenceList<%s>") % t
    alts = []
    if not vs and not es:
        alts.append(("%s()" % T, None))
    if not es:
        alts.append(("%s(vertices: %s as [%s])" % (T, vlist(vs), t), None))
    if not vs:
        alts.append(("%s(hyperedges: %s)" % (T, ("%s as [[%s]]" % (vlists(es), t)) if U else d_pairs(t, es)), None))
    alts.append(("%s(hypergraph)" % T, None))
    steps = ["var built = %s()" % T]
    steps += ["built.insert(%s)" % s(v) for v in vs]
    for e in es:
        steps.append(("built.insert(hyperedge: %s as [%s])" % (vlist(e), t)) if U else
                     ("built.insert(sources: %s as [%s], targets: %s as [%s])" % (vlist(e[0]), t, vlist(e[1]), t)))
    out = ["        // The other initializers, and inserting one at a time, give the same state."]
    for a, _ in alts:
        out += ["        do {", "            let built = " + a] + state(g, "built", "            ", short=True)
        out += ["            #expect(built == hypergraph)", "        }"]
    if len(steps) > 1:
        out += ["        do {"] + ["            " + x for x in steps] + state(g, "built", "            ", short=True)
        out += ["            #expect(built == hypergraph)", "        }"]
    return out


def group_of_spec(prefix, vs, es):
    return CURRENT_GROUP[0]


CURRENT_GROUP = [None]


def row_test(rid):
    _, prefix, vs, es, calls = SPEC[rid]
    CURRENT_GROUP[0] = group(rid)
    t = vtype(vs, es, prefix)
    g = ref.UHG(vs, es) if prefix == "HG" else ref.DHG(vs, es)
    g.hashes = 0
    mut = any(c[0] in MUTATING for c in calls)
    throws = any(c[0] == "encode" or c[0].startswith("insert(checked:") or c[0].endswith("(checked:)") for c in calls)
    lines = header(rid, [".conformance"] if group(rid) in ("Codable", "Description") else [])
    lines.append("    func %s()%s {" % (fname(rid), " throws" if throws else ""))
    lines.append("        // %s" % inp(rid))
    lines.append("        %s hypergraph = %s" % ("var" if mut else "let", build(prefix, t, vs, es)))
    shown = []
    for i, c in enumerate(calls):
        r, ls = call_lines(g, c)
        shown.append(ref.fmt(r))
        lines += ["        " + l for l in ls]
        if c[0] in MUTATING and any(x[0] in MUTATING for x in calls[i + 1:]):
            lines.append("        // After %s." % ref.call_text(c))
            lines += state(g, "hypergraph", "        ", short=True)
    exp = "; ".join(shown)
    if "⇒" in cell(rid) or not calls:
        exp = (exp + " ⇒ " if exp else "") + ref.fmt_state(g)
    assert exp == cell(rid), (rid, exp, cell(rid))
    lines.append("        // Final state.")
    lines += state(g, "hypergraph", "        ")
    lines += alternatives(prefix, t, vs, es, g)
    if any(c[0] == "hashes" for c in calls):
        lines += counted_lines(prefix, vs, es, calls)
    lines.append("    }")
    return lines


def trap_test(rid):
    _, prefix, vs, es, calls = SPEC[rid]
    t = vtype(vs, es, prefix)
    *setup, last = calls
    assert not setup
    g = ref.UHG(vs, es) if prefix == "HG" else ref.DHG(vs, es)
    try:
        ref.run_call(g, last)
        raise AssertionError("no trap: " + rid)
    except ref.Trap as e:
        assert cell(rid) == "**trap** (%s)" % e, rid
    lines = header(rid) + ["    func %s() async {" % fname(rid), "        // %s → %s" % (inp(rid), cell(rid)),
                           "        await #expect(processExitsWith: .failure) {",
                           "            let hypergraph = " + build(prefix, t, vs, es),
                           "            " + child_call(last), "        }",
                           "        // Without the call: the state the call would apply to.",
                           "        let hypergraph = " + build(prefix, t, vs, es)]
    lines += state(g, "hypergraph", "        ")
    return lines + ["    }"]


def decode_test(rid):
    _, prefix, obj = SPEC[rid]
    text = json.dumps(obj, separators=(",", ":"))
    T = "UndirectedIncidenceList<String>" if prefix == "HG" else "IncidenceList<String>"
    lines = header(rid, [".conformance"]) + ["    func %s() throws {" % fname(rid), "        // %s → %s" % (inp(rid), cell(rid)),
                                            "        let payload = Data(#\"%s\"#.utf8)" % text]
    if cell(rid).startswith("throws"):
        lines += ["        do {",
                  "            let decoded = try JSONDecoder().decode(%s.self, from: payload)" % T,
                  "            Issue.record(\"decoded \\(decoded)\")",
                  "        } catch DecodingError.dataCorrupted {",
                  "        } catch {",
                  "            Issue.record(\"unexpected error \\(error)\")",
                  "        }"]
    else:
        g = (ref.UHG if prefix == "HG" else ref.DHG).decode(obj)
        assert ref.fmt_state(g) == cell(rid), rid
        lines.append("        let hypergraph = try JSONDecoder().decode(%s.self, from: payload)" % T)
        lines += state(g, "hypergraph", "        ")
        lines.append("        #expect(try JSONDecoder().decode(%s.self, from: JSONEncoder().encode(hypergraph)) == hypergraph)" % T)
    return lines + ["    }"]


def eq_test(rid):
    _, prefix, a, b, hashing = SPEC[rid]
    cls = ref.UHG if prefix == "HG" else ref.DHG
    ga, gb = cls(*a), cls(*b)
    eq = ga == gb
    ta, tb = vtype(*a, prefix), vtype(*b, prefix)
    t = ta if ta == tb else "String"
    lines = header(rid, [".conformance"]) + ["    func %s() {" % fname(rid), "        // %s → %s" % (inp(rid), cell(rid)),
                                            "        let lhs = " + build(prefix, t, *a),
                                            "        let rhs = " + build(prefix, t, *b)]
    if hashing:
        assert cell(rid) == str(len({ga, gb})), rid
        lines.append("        #expect(Set([lhs, rhs]).count == %s)" % cell(rid))
    else:
        assert cell(rid) == ref.fmt(eq), rid
    if eq:
        lines += ["        #expect(lhs == rhs && rhs == lhs)", "        #expect(lhs.hashValue == rhs.hashValue)"]
        if ga.vs != gb.vs:
            lines.append("        // Equal values with different index assignments.")
            lines.append("        #expect(Array(lhs.vertices) == %s && Array(rhs.vertices) == %s)" % (vlist(ga.vs), vlist(gb.vs)))
    else:
        lines += ["        #expect(lhs != rhs && rhs != lhs)"]
    lines += ["        #expect(lhs == lhs)", "    }"]
    return lines


def test_for(rid):
    kind = SPEC[rid][0]
    if kind == "decode":
        return decode_test(rid)
    if kind == "eq":
        return eq_test(rid)
    return trap_test(rid) if is_trap(rid) else row_test(rid)


# ---------------------------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------------------------

def ids(prefix, *groups):
    return [r for r in IDS if r.startswith(prefix) and group(r) in groups and not is_trap(r)]


TRAPS = [r for r in IDS if is_trap(r)]
FILES = [
    ("UndirectedIncidenceListConstructionTests.swift", "UndirectedIncidenceList construction and mutation", ids("HG", "Construction", "Mutation"),
     "Construction and mutation (catalog HG-001 – HG-011, HG-035 – HG-042): listed vertices first (a repeat\n"
     "// once), then new members by first appearance; members stored once and in vertex-index order;\n"
     "// repeated and empty hyperedges kept at their own positions; every initializer that fits, and\n"
     "// inserting one at a time, give the same state; insert(checked:) throws and changes nothing for a\n"
     "// non-vertex."),
    ("UndirectedIncidenceListReadTests.swift", "UndirectedIncidenceList reads", ids("HG", "Reads"),
     "Reads (catalog HG-012 – HG-024): members, sizes, incident hyperedges in ascending position, degrees,\n"
     "// membership of vertices and of member sets, the index conversions, the checked: lookups, neighbors,\n"
     "// and the hash law: index-space reads hash nothing and a vertex-space read hashes once."),
    ("UndirectedIncidenceListAlgorithmTests.swift", "UndirectedIncidenceList algorithms",
     ids("HG", "Measures", "Dual", "Incidence graph", "Clique expansion", "Line graph", "Connectivity", "s-connectivity"),
     "Algorithms on Hypergraph (catalog HG-043 – HG-077): rank, uniformity, the histograms, the dual,\n"
     "// the incidence-graph view (vertex indices, then n + p; edge q is incidence q), the clique\n"
     "// expansion and the s-line graph (every vertex or position, edges by index pair), connected\n"
     "// components and s-components."),
    ("UndirectedIncidenceListValueTests.swift", "UndirectedIncidenceList equality, description and Codable",
     ids("HG", "Equality", "Hashing", "Description", "Codable"),
     "Equality, hashing, description and Codable (catalog HG-078 – HG-094): equal vertex sets and equal\n"
     "// multisets of member sets whatever the order; String(reflecting:) lists elided after 16; Codable as\n"
     "// {vertices, hyperedges} with ascending rows, and the decoder's re-checks as dataCorrupted."),
    ("IncidenceListConstructionTests.swift", "IncidenceList construction and mutation", ids("DH", "Construction", "Mutation"),
     "Construction and mutation (catalog DH-001 – DH-007, DH-018 – DH-021): listed vertices, then each new\n"
     "// hyperedge's sources, then its targets, by first appearance; each side stored once in index order;\n"
     "// empty sides, the empty hyperedge, a vertex on both sides and repeats are kept."),
    ("IncidenceListReadTests.swift", "IncidenceList reads", ids("DH", "Reads"),
     "Reads (catalog DH-008 – DH-012, DH-057): the forward and backward stars in ascending position,\n"
     "// degrees as in + out, contains(sources:targets:), the checked: lookups and the hash law."),
    ("IncidenceListAlgorithmTests.swift", "IncidenceList algorithms",
     ids("DH", "Reversal", "Dual", "Incidence graph", "Components", "B-connectivity", "F-connectivity", "Hyperedge classes",
         "Clique expansion", "Measures"),
     "Algorithms on DirectedHypergraph (catalog DH-022 – DH-045): reversal, the dual, the directed\n"
     "// incidence-graph view (source incidences, then target incidences), weak and strong components,\n"
     "// B-Visit and F-Visit (Gallo et al. 1993), the B-, F- and BF-classes, the directed clique expansion\n"
     "// and the histograms."),
    ("IncidenceListValueTests.swift", "IncidenceList equality, description and Codable",
     ids("DH", "Equality", "Hashing", "Description", "Codable"),
     "Equality, hashing, description and Codable (catalog DH-046 – DH-056): equal vertex sets and equal\n"
     "// multisets of (source set, target set) pairs; Codable as {vertices, sources, targets}, and the\n"
     "// decoder's re-checks as dataCorrupted."),
    ("HypergraphPreconditionTests.swift", "Hypergraphs preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the call, so the trap is the call's and not the\n"
     "// setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]


def write(fname_, suite, rows, comment):
    tests = [test_for(r) for r in rows]
    if fname_ == "HypergraphPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphProtocols", "Hypergraphs", "Testing"]
    if "JSONDecoder" in text or "Data(" in text:
        imports.append("Foundation")
    if ".tags(" in text or fname_ == "HypergraphPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    if "AdjacencyList" in text or "lineGraph" in text or "cliqueExpansion" in text:
        imports.append("AdjacencyListModule")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname_ == "HypergraphPreconditionTests.swift" else ""
    out = ["// " + comment, "// Generated from cases.md by swiftgen.py; see README.md.", ""]
    out += ["import " + m for m in imports]
    out += ["", '@Suite("%s"%s)' % (suite, tags), "struct %s {" % fname_[:-6]]
    out += body
    out.append("}")
    with open(os.path.join(OUT, fname_), "w") as f:
        f.write("\n".join(out) + "\n")
    return sum(1 for l in body if l.lstrip().startswith("@Test("))


os.makedirs(OUT, exist_ok=True)
total = rows_total = 0
for fname_, suite, rows, comment in FILES:
    k = write(fname_, suite, rows, comment)
    print(fname_, k)
    total += k
    rows_total += len(rows)
assert rows_total == len(IDS), rows_total
print("catalog rows", rows_total, "tests", total)
