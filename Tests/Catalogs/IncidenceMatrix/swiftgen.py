"""Writes the catalog-row test files of Tests/IncidenceMatrixTests from cases.md and ref.py.

    uv run --quiet --no-project --with networkx==3.7 --with xgi==0.10.2 \
        python3 Tests/Catalogs/IncidenceMatrix/swiftgen.py [OUT_DIR]
    # default OUT_DIR: Tests/IncidenceMatrixTests

First checks that ref.py's model reproduces cases.md byte for byte. Then it re-runs every row on the
model (ref.py's port of the bit planes, checked against NetworkX, XGI, the algebraic identities and
the protocol laws after every call), asserts that each value matches its catalog cell, and writes
one @Test per row. Each call's result is checked; after a mutation that another mutation follows,
the test checks the cells; the final state is written out in full: every cell (or entry), every
column's members (or two sides) and size, every row's incident columns and degrees, by vertex and by
index, the protocol bounds, and membership of every column. Hand-written exit tests are spliced into
the precondition file: extra_traps.swift.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ref  # noqa: E402

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "IncidenceMatrixTests")

SPEC = {}
_case, _eq = ref.case, ref.eq_case


def _rec_case(group, title, text, make, calls=(), show_state=True, source=None, oriented=False, graph=None):
    SPEC["IM-%03d" % (len(ref.ROWS) + 1)] = ("case", text, make, list(calls), oriented, source, graph)
    _case(group, title, text, make, calls, show_state, source, oriented, graph)


def _rec_eq(title, ta, a, tb, b):
    SPEC["IM-%03d" % (len(ref.ROWS) + 1)] = ("eq", ta, a, tb, b)
    _eq(title, ta, a, tb, b)


ref.case, ref.eq_case = _rec_case, _rec_eq
ref.define()
TEXT = ref.render()
with open(os.path.join(HERE, "cases.md")) as f:
    assert f.read() == TEXT, "cases.md is not ref.py's output"
CELLS = {}
for line in TEXT.splitlines():
    if line.startswith("| IM-"):
        parts = [p.strip().replace("\\|", "|") for p in line.strip().strip("|").split(" | ")]
        CELLS[parts[0]] = parts
IDS = list(CELLS)
assert len(IDS) == 63 and sorted(IDS) == sorted(SPEC)


def group(r): return CELLS[r][1]
def title(r): return CELLS[r][2]
def inp(r): return CELLS[r][3]
def cell(r): return CELLS[r][4]
def is_trap(r): return "**trap**" in cell(r)


# ---------------------------------------------------------------------------------------------
# Swift literals and constructions
# ---------------------------------------------------------------------------------------------

def ints(xs): return "[" + ", ".join(str(x) for x in xs) + "]"
def intlists(xss): return "[" + ", ".join(ints(x) for x in xss) + "]"


def hyperedge_list(es):
    if len(es) > 8 and all(e == es[0] for e in es):
        return "Array(repeating: %s, count: %d)" % (ints(es[0]), len(es))
    return "%s as [[Int]]" % intlists(es)


def pairs(es):
    return "[" + ", ".join("(sources: %s, targets: %s)" % (ints(s), ints(t)) for s, t in es) + "] as [(sources: [Int], targets: [Int])]"


def arcs(es):
    return "[" + ", ".join("DirectedEdge(from: %d, to: %d)" % e for e in es) + "]" if es else "[] as [DirectedEdge<Int>]"


def uedges(es):
    return "[" + ", ".join("UndirectedEdge(%d, %d)" % e for e in es) + "]" if es else "[] as [UndirectedEdge<Int>]"


def parse_text(text):
    """The construction a catalog input names, as Swift."""
    m = re.match(r"^IM n (-?\d+); E (\[.*\])$", text)
    if m:
        es = [[int(x) for x in g.split(", ") if x] for g in re.findall(r"\{([^}]*)\}", m.group(2))]
        return "IncidenceMatrix(vertexCount: %s, hyperedges: %s)" % (m.group(1), hyperedge_list(es))
    m = re.match(r"^OIM n (\d+); A \[(.*)\]$", text)
    if m:
        es = [tuple(int(x) for x in a.split("→")) for a in m.group(2).split(", ") if a]
        return "OrientedIncidenceMatrix(vertexCount: %s, edges: %s)" % (m.group(1), arcs(es))
    m = re.match(r"^OIM n (\d+); E \[(.*)\]$", text)
    if m:
        es = []
        for s, t in re.findall(r"\{([^}]*)\}→\{([^}]*)\}", m.group(2)):
            es.append(([int(x) for x in s.split(", ") if x], [int(x) for x in t.split(", ") if x]))
        return "OrientedIncidenceMatrix(vertexCount: %s, hyperedges: %s)" % (m.group(1), pairs(es))
    raise ValueError(text)


def construct(rid):
    _, text, make, calls, oriented, source, graph = SPEC[rid]
    if text.startswith("IM n") and "×" in text:
        n = int(text.split()[2].rstrip(";"))
        return "IncidenceMatrix(vertexCount: %d, hyperedges: %s)" % (n, hyperedge_list(source[1]))
    if text.startswith("IncidenceMatrix(Pseudograph"):
        _, n, es = source
        return "IncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< %d, edges: %s))" % (n, uedges(es))
    if text.startswith("IncidenceMatrix(DirectedPseudograph"):
        _, n, es = source
        return "IncidenceMatrix(DirectedPseudograph<Int>(vertices: 0 ..< %d, edges: %s))" % (n, arcs(es))
    if text.startswith("OrientedIncidenceMatrix(Pseudograph"):
        _, n, es = graph
        return "OrientedIncidenceMatrix(Pseudograph<Int>(vertices: 0 ..< %d, edges: %s))" % (n, uedges(es))
    if text.startswith("IM n") and source:
        n = int(text.split()[2].rstrip(";"))
        return "IncidenceMatrix(vertexCount: %d, hyperedges: %s)" % (n, hyperedge_list(source[1]))
    return parse_text(text)


# ---------------------------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------------------------

def im_state(M, var, short=False):
    n, m = M.n, M.m
    rows = [M.row_bits(v) for v in range(n)]
    out = ["#expect(%s.vertexCount == %d && %s.hyperedgeCount == %d)" % (var, n, var, m),
           "#expect((0 ..< %d).map { v in String((0 ..< %d).map { p -> Character in %s[vertex: v, hyperedge: p] ? \"1\" : \"0\" }) } == %s)"
           % (n, m, var, json.dumps(rows))]
    if short:
        return out
    cols = [M.members(p) for p in range(m)]
    out += ["#expect(%s.hyperedges.map { Array($0) } == %s)" % (var, intlists(cols)),
            "#expect(%s.vertices == 0 ..< %d && %s.vertexIndexBound == %d && %s.hyperedgeIndexBound == %d)" % (var, n, var, n, var, m),
            "#expect(%s.hyperedges.indices.map { %s.hyperedgeIndex(of: $0) } == %s)" % (var, var, ints(range(m)))]
    for p in range(m):
        out.append("#expect(Array(%s.members(ofHyperedgeAt: %d)) == %s && Array(%s.memberIndices(ofHyperedgeAt: %d)) == %s && %s.size(ofHyperedgeAt: %d) == %d)"
                   % (var, p, ints(cols[p]), var, p, ints(cols[p]), var, p, len(cols[p])))
        out.append("#expect(%s.contains(hyperedge: %s as [Int]))" % (var, ints(list(reversed(cols[p])))))
    for v in range(n):
        inc = M.incident(v)
        out.append("#expect(Array(%s.incidentHyperedges(of: %d)) == %s && Array(%s.incidentHyperedges(ofIndex: %d)) == %s)"
                   % (var, v, ints(inc), var, v, ints(inc)))
        out.append("#expect(%s.degree(of: %d) == %d && %s.degree(ofIndex: %d) == %d && %s.vertexIndex(of: %d) == %d && %s.vertex(atIndex: %d) == %d)"
                   % (var, v, len(inc), var, v, len(inc), var, v, v, var, v, v))
    return out


def oim_state(M, var, short=False):
    n, m = M.n, M.m
    rows = [M.row_text(v) for v in range(n)]
    sides = [[sorted(s), sorted(t)] for s, t in M.cols]
    out = ["#expect(%s.vertexCount == %d && %s.hyperedgeCount == %d)" % (var, n, var, m),
           "#expect((0 ..< %d).map { v in String((0 ..< %d).map { p -> Character in [\"-\", \"0\", \"+\"][%s[vertex: v, hyperedge: p] + 1] }) } == %s)"
           % (n, m, var, json.dumps(rows)),
           "#expect(%s.hyperedges.map { [Array($0.sources), Array($0.targets)] } == %s)"
           % (var, "[" + ", ".join("[%s, %s]" % (ints(a), ints(b)) for a, b in sides) + "]")]
    if short:
        return out
    out += ["#expect(%s.vertices == 0 ..< %d && %s.vertexIndexBound == %d && %s.hyperedgeIndexBound == %d)" % (var, n, var, n, var, m),
            "#expect(%s.hyperedges.indices.map { %s.hyperedgeIndex(of: $0) } == %s)" % (var, var, ints(range(m)))]
    for p, (s, t) in enumerate(sides):
        out.append("#expect(Array(%s.sources(ofHyperedgeAt: %d)) == %s && Array(%s.sourceIndices(ofHyperedgeAt: %d)) == %s)"
                   % (var, p, ints(s), var, p, ints(s)))
        out.append("#expect(Array(%s.targets(ofHyperedgeAt: %d)) == %s && Array(%s.targetIndices(ofHyperedgeAt: %d)) == %s)"
                   % (var, p, ints(t), var, p, ints(t)))
        out.append("#expect(%s.contains(sources: %s as [Int], targets: %s as [Int]))" % (var, ints(list(reversed(s))), ints(list(reversed(t)))))
    for v in range(n):
        o, k = M.out_h(v), M.in_h(v)
        out.append("#expect(Array(%s.outHyperedges(of: %d)) == %s && Array(%s.outHyperedges(ofIndex: %d)) == %s)" % (var, v, ints(o), var, v, ints(o)))
        out.append("#expect(Array(%s.inHyperedges(of: %d)) == %s && Array(%s.inHyperedges(ofIndex: %d)) == %s)" % (var, v, ints(k), var, v, ints(k)))
        out.append("#expect(%s.outDegree(of: %d) == %d && %s.inDegree(of: %d) == %d && %s.outDegree(ofIndex: %d) == %d && %s.inDegree(ofIndex: %d) == %d && %s.degree(of: %d) == %d)"
                   % (var, v, len(o), var, v, len(k), var, v, len(o), var, v, len(k), var, v, len(o) + len(k)))
    return out


def state(M, var, ind, short=False):
    lines = oim_state(M, var, short) if isinstance(M, ref.OIM) else im_state(M, var, short)
    return [ind + l for l in lines]


# ---------------------------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------------------------
MUTATING = {"appendVertex", "insert(hyperedge:)", "insert(_:intoHyperedgeAt:)", "remove(_:fromHyperedgeAt:)", "removeAll",
            "insert(sources:targets:)", "insert(_:intoSourcesOfHyperedgeAt:)", "insert(_:intoTargetsOfHyperedgeAt:)",
            "remove(_:fromSourcesOfHyperedgeAt:)", "remove(_:fromTargetsOfHyperedgeAt:)"}


def call_lines(M, call, var="matrix"):
    r = ref.run_call(M, call)
    name, *a = call

    def ex(text): return ["#expect(%s)" % text]

    if name == "subscript":
        if isinstance(M, ref.OIM):
            return r, ex("%s[vertex: %d, hyperedge: %d] == %d" % (var, a[0], a[1], r))
        return r, ex("%s%s[vertex: %d, hyperedge: %d]" % ("" if r else "!", var, a[0], a[1]))
    if name in ("members", "sources", "targets"):
        return r, ex("Array(%s.%s(ofHyperedgeAt: %d)) == %s" % (var, name, a[0], ints(r)))
    if name == "size":
        return r, ex("%s.size(ofHyperedgeAt: %d) == %d" % (var, a[0], r))
    if name in ("incidentHyperedges", "outHyperedges", "inHyperedges"):
        return r, ex("Array(%s.%s(of: %d)) == %s" % (var, name, a[0], ints(r)))
    if name in ("degree", "outDegree", "inDegree"):
        return r, ex("%s.%s(of: %d) == %d" % (var, name, a[0], r))
    if name == "appendVertex":
        return r, ex("%s.appendVertex() == %d" % (var, r))
    if name == "insert(hyperedge:)":
        return r, ex("%s.insert(hyperedge: %s as [Int]) == %d" % (var, ints(a), r))
    if name == "insert(sources:targets:)":
        return r, ex("%s.insert(sources: %s as [Int], targets: %s as [Int]) == %d" % (var, ints(a[0]), ints(a[1]), r))
    if name.startswith(("insert(_:", "remove(_:")):
        base, label = name.split("(_:")
        return r, ["do {", "    let changed = %s.%s(%d, %s: %d)" % (var, base, a[0], label[:-2], a[1]),
                   "    #expect(%schanged)" % ("" if r else "!"), "}"]
    if name == "removeAll":
        return r, ["%s.removeAll()" % var]
    if name == "counts":
        n_, m_ = r.split("/")
        return r, ex("%s.vertexCount == %s && %s.hyperedgeCount == %s" % (var, n_, var, m_))
    if name == "transposed":
        return r, ["do {", "    let transposed = %s.transposed()" % var] + state(r, "transposed", "    ") + [
            "    #expect(transposed.transposed() == %s)" % var, "}"]
    if name == "reversed":
        return r, ["do {", "    let reversed = %s.reversed" % var] + state(r, "reversed", "    ") + [
            "    #expect(reversed.reversed == %s)" % var,
            "    #expect((0 ..< %d).allSatisfy { v in (0 ..< %d).allSatisfy { reversed[vertex: v, hyperedge: $0] == -%s[vertex: v, hyperedge: $0] } })" % (M.n, M.m, var),
            "}"]
    if name == "IncidenceMatrix(_:)":
        return r, ["do {", "    let unoriented = IncidenceMatrix(%s)" % var] + state(r, "unoriented", "    ") + ["}"]
    raise ValueError(call)


def child_call(call, var="matrix"):
    name, *a = call
    if name == "subscript":
        return "_ = %s[vertex: %d, hyperedge: %d]" % (var, a[0], a[1])
    if name in ("members", "targets", "sources"):
        return "_ = %s.%s(ofHyperedgeAt: %d)" % (var, name, a[0])
    if name in ("incidentHyperedges", "outHyperedges"):
        return "_ = %s.%s(of: %d)" % (var, name, a[0])
    if name == "insert(hyperedge:)":
        return "%s.insert(hyperedge: %s as [Int])" % (var, ints(a))
    if name == "insert(sources:targets:)":
        return "%s.insert(sources: %s as [Int], targets: %s as [Int])" % (var, ints(a[0]), ints(a[1]))
    if name == "remove(_:fromHyperedgeAt:)":
        return "%s.remove(%d, fromHyperedgeAt: %d)" % (var, a[0], a[1])
    raise ValueError(call)


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

def header(rid, tags=()):
    return ['    @Test("%s %s"%s)' % (rid, title(rid), (", .tags(%s)" % ", ".join(tags)) if tags else "")]


def fname(rid): return rid.replace("-", "").lower()


def row_test(rid):
    _, text, make, calls, oriented, source, graph = SPEC[rid]
    M = make()
    mut = any(c[0] in MUTATING for c in calls)
    lines = header(rid) + ["    func %s() {" % fname(rid), "        // %s" % inp(rid),
                           "        %s matrix = %s" % ("var" if mut else "let", construct(rid))]
    shown = []
    for i, c in enumerate(calls):
        r, ls = call_lines(M, c)
        shown.append(ref.fmt(r))
        lines += ["        " + l for l in ls]
        if c[0] in MUTATING and any(x[0] in MUTATING for x in calls[i + 1:]):
            lines.append("        // After %s." % ref.call_text(c))
            lines += state(M, "matrix", "        ", short=True)
    exp = "; ".join(shown)
    if "⇒" in cell(rid) or not calls:
        exp = (exp + " ⇒ " if exp else "") + (ref.fmt_oim(M) if oriented else ref.fmt_im(M))
    assert exp == cell(rid), (rid, exp, cell(rid))
    lines.append("        // Final state.")
    lines += state(M, "matrix", "        ")
    if group(rid) in ("Construction", "From a graph") and not oriented:
        # The same matrix through the hypergraph conversions and by appending one column at a time.
        lines.append("        // The same matrix from an incidence-list copy, and by appending one column at a time.")
        lines.append("        #expect(IncidenceMatrix(UndirectedIncidenceList<Int>(matrix)) == matrix)")
        lines.append("        do {")
        lines.append("            %s built = IncidenceMatrix(vertexCount: %d)" % ("var" if M.m else "let", M.n))
        for p in range(M.m):
            lines.append("            #expect(built.insert(hyperedge: %s as [Int]) == %d)" % (ints(M.members(p)), p))
        lines.append("            #expect(built == matrix)")
        lines.append("        }")
    if oriented and group(rid).startswith("Oriented") and not calls:
        lines.append("        // The same matrix from an incidence-list copy, and by appending one column at a time.")
        lines.append("        #expect(OrientedIncidenceMatrix(IncidenceList<Int>(matrix)) == matrix)")
        lines.append("        do {")
        lines.append("            %s built = OrientedIncidenceMatrix(vertexCount: %d)" % ("var" if M.m else "let", M.n))
        for p, (s, t) in enumerate(M.cols):
            lines.append("            #expect(built.insert(sources: %s as [Int], targets: %s as [Int]) == %d)" % (ints(sorted(s)), ints(sorted(t)), p))
        lines.append("            #expect(built == matrix)")
        lines.append("        }")
    lines.append("    }")
    return lines


def trap_test(rid):
    _, text, make, calls, oriented, source, graph = SPEC[rid]
    lines = header(rid) + ["    func %s() async {" % fname(rid), "        // %s → %s" % (inp(rid), cell(rid))]
    if not calls:
        # The construction traps.
        try:
            make()
            raise AssertionError("no trap: " + rid)
        except ref.Trap as e:
            assert cell(rid) == "**trap** (%s)" % e, rid
        if rid == "IM-006":
            bad, good = "IncidenceMatrix(vertexCount: -1, hyperedges: [] as [[Int]])", "IncidenceMatrix(vertexCount: 0, hyperedges: [] as [[Int]])"
        else:
            bad = construct(rid)
            good = bad.replace("vertexCount: 2", "vertexCount: 3")
        lines += ["        await #expect(processExitsWith: .failure) {", "            _ = " + bad, "        }",
                  "        // Without the fault: accepted.", "        let matrix = " + good]
        lines += state(ref.IM(0 if rid == "IM-006" else 3, [] if rid == "IM-006" else source[1]), "matrix", "        ")
        return lines + ["    }"]
    *setup, last = calls
    assert not setup
    M = make()
    try:
        ref.run_call(M, last)
        raise AssertionError("no trap: " + rid)
    except ref.Trap as e:
        assert cell(rid) == "**trap** (%s)" % e, rid
    M = make()
    mut = last[0] in MUTATING
    lines += ["        await #expect(processExitsWith: .failure) {",
              "            %s matrix = %s" % ("var" if mut else "let", construct(rid)),
              "            " + child_call(last), "        }",
              "        // Without the call: the state the call would apply to.",
              "        let matrix = " + construct(rid)]
    lines += state(M, "matrix", "        ")
    return lines + ["    }"]


def eq_test(rid):
    _, ta, a, tb, b = SPEC[rid]
    eq = a() == b()
    assert cell(rid) == ref.fmt(eq), rid
    lines = header(rid, [".conformance"]) + ["    func %s() {" % fname(rid), "        // %s → %s" % (inp(rid), cell(rid)),
                                            "        let lhs = " + parse_text(ta), "        let rhs = " + parse_text(tb)]
    if eq:
        lines += ["        #expect(lhs == rhs && rhs == lhs)", "        #expect(lhs.hashValue == rhs.hashValue)",
                  "        #expect(Set([lhs, rhs]).count == 1)"]
    else:
        lines += ["        #expect(lhs != rhs && rhs != lhs)", "        #expect(Set([lhs, rhs]).count == 2)"]
    return lines + ["        #expect(lhs == lhs)", "    }"]


def test_for(rid):
    if SPEC[rid][0] == "eq":
        return eq_test(rid)
    return trap_test(rid) if is_trap(rid) else row_test(rid)


def ids(*groups):
    return [r for r in IDS if group(r) in groups and not is_trap(r)]


TRAPS = [r for r in IDS if is_trap(r)]
FILES = [
    ("IncidenceMatrixConstructionTests.swift", "IncidenceMatrix construction and reads", ids("Construction", "From a graph", "Reads"),
     "Construction and reads (catalog IM-001 – IM-018): columns in input order, a repeated member one bit,\n"
     "// repeated and empty columns kept; from a graph one column per edge in edges order, a self-loop one\n"
     "// bit (NetworkX: a zero column), both ends from a digraph; cells, columns, rows and degrees; the\n"
     "// same matrix through an incidence-list copy and by appending one column at a time."),
    ("IncidenceMatrixMutationTests.swift", "IncidenceMatrix mutation, transpose and equality", ids("Mutation", "Transpose", "Equality"),
     "Mutation, transpose and equality (catalog IM-023 – IM-037, IM-060 – IM-063): rows and columns grow\n"
     "// past 64; a cell is set or cleared once; transposed() is the dual and an involution; equality is\n"
     "// cell for cell with equal shape, column order observable, both planes compared when oriented."),
    ("OrientedIncidenceMatrixTests.swift", "OrientedIncidenceMatrix", ids("Oriented, from a graph", "Oriented hypergraph", "Oriented mutation"),
     "OrientedIncidenceMatrix (catalog IM-038 – IM-055): −1 at each source and +1 at each target, 0 for a\n"
     "// vertex on both sides with both bits kept (a self-loop included, as NetworkX's zero column); the\n"
     "// union matrix, the transposed dual, reversal as negation, and the plane edits."),
    ("IncidenceMatrixPreconditionTests.swift", "IncidenceMatrix preconditions", TRAPS,
     "Preconditions (catalog trap rows): each trapping call runs in a child process (exit test). The\n"
     "// same setup then runs in this process without the call, so the trap is the call's and not the\n"
     "// setup's. Then the preconditions the catalog does not list (extra_traps.swift)."),
]


def write(fname_, suite, rows, comment):
    tests = [test_for(r) for r in rows]
    if fname_ == "IncidenceMatrixPreconditionTests.swift":
        tests.append(open(os.path.join(HERE, "extra_traps.swift")).read().rstrip("\n").split("\n"))
    body = []
    for i, t in enumerate(tests):
        if i:
            body.append("")
        body += t
    text = "\n".join(body)
    imports = ["GraphProtocols", "IncidenceMatrixModule", "Testing"]
    if "Pseudograph" in text:
        imports.append("Multigraphs")
    if "IncidenceList" in text:
        imports.append("Hypergraphs")
    if ".tags(" in text or fname_ == "IncidenceMatrixPreconditionTests.swift":
        imports.append("GrafluentTestSupport")
    imports.sort(key=str.lower)
    tags = ", .tags(.precondition)" if fname_ == "IncidenceMatrixPreconditionTests.swift" else ""
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
