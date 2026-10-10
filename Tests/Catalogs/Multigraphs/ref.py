"""Reference model for the proposed Multigraphs API (api.md), checked against NetworkX 3.7.

    uv run --quiet --no-project --with networkx==3.7 python3 ref.py           # validate cases.md
    uv run --quiet --no-project --with networkx==3.7 python3 ref.py --write   # regenerate it

The model is an exact port of the storage the API proposes: `UndirectedAdjacencyList`'s and
`AdjacencyList`'s slots, rows and swap-remove mutation, with the vertex-pair map replaced by a
parallel class per pair (first, last, count) and a doubly linked list of copies threaded through
the edge positions in insertion order. `remove(edge:)` takes the class's last (newest) copy.

Every state the cases reach is checked three ways:
* Laws: the Graph / BidirectionalDirectedGraph laws (each row lists each edge end once, rows parallel,
  stored offsets right, degrees sum to 2m or m), the class lists (every position in exactly one
  class, keyed by its slots, in insertion order), and for a freshly built graph the rows equal
  ReferencePseudograph / ReferenceDirectedMultigraph's (each edge appended at u then at v).
* NetworkX: a MultiGraph / MultiDiGraph driven by the same operations, with each of our copies
  mapped to its NetworkX key. Compared: nodes, edge count, degree / in / out degree of every
  vertex, number_of_edges(u, v) for every pair, number_of_selfloops, which copy remove_edge(u, v)
  removes, and the order of our edges(between:) against G[u][v]'s key order.
* Conversions to the simple lists are checked against nx.Graph / nx.DiGraph of the multigraph.
"""
import sys, os, json
from collections import Counter
import networkx as nx

HERE = os.path.dirname(os.path.abspath(__file__))
CASES_MD = os.path.join(HERE, "cases.md")


class Trap(Exception):
    pass


def swap_remove(row, off):
    """_RowPool.swapRemove: the last entry moves into `off`; returns it, or None if `off` was last."""
    last = row.pop()
    if off < len(row):
        row[off] = last
        return last
    return None


def fmt(x):
    return '"%s"' % x if isinstance(x, str) else str(x)


# ---------------------------------------------------------------------------------------------
# Undirected: Pseudograph (loops), Multigraph (no loops), and simple mode (UndirectedAdjacencyList)
# ---------------------------------------------------------------------------------------------

class U:
    directed = False

    def __init__(s, kind="Pseudograph"):
        s.kind = kind
        s.loops = kind != "Multigraph"
        s.parallel = kind != "UndirectedAdjacencyList"
        s.V, s.slot, s.nb, s.inc, s.rec = [], {}, [], [], []   # rec: [u, v, uOffset, vOffset]
        s.prev, s.next, s.uid, s.cls = [], [], [], {}          # cls: key -> [first, last, count]
        s.stamp = 0
        s.fresh = True  # only insertions so far (rows must equal the reference conformer's)

    @staticmethod
    def key(a, b):
        return (a, b) if a <= b else (b, a)

    def _append_slot(s, x):
        s.slot[x] = len(s.V)
        s.V.append(x)
        s.nb.append([])
        s.inc.append([])
        return s.slot[x]

    def insert_vertex(s, x):
        if x in s.slot:
            return False
        s._append_slot(x)
        return True

    def insert_edge(s, a, b):
        if a == b and not s.loops:
            raise Trap("self-loop in a %s" % s.kind)
        u = s.slot[a] if a in s.slot else s._append_slot(a)
        v = s.slot[b] if b in s.slot else s._append_slot(b)
        k = s.key(u, v)
        if not s.parallel and k in s.cls:
            return None
        p = len(s.rec)
        s.nb[u].append(v); uo = len(s.nb[u]) - 1; s.inc[u].append(p)
        s.nb[v].append(u); vo = len(s.nb[v]) - 1; s.inc[v].append(p)
        s.rec.append([u, v, uo, vo])
        s.uid.append(s.stamp); s.stamp += 1
        c = s.cls.get(k)
        if c:
            s.prev.append(c[1]); s.next.append(-1); s.next[c[1]] = p; c[1] = p; c[2] += 1
        else:
            s.prev.append(-1); s.next.append(-1); s.cls[k] = [p, p, 1]
        return p

    def _unlink(s, p):
        r = s.rec[p]
        k = s.key(r[0], r[1])
        c = s.cls[k]
        pr, nx_ = s.prev[p], s.next[p]
        if pr != -1: s.next[pr] = nx_
        else: c[0] = nx_
        if nx_ != -1: s.prev[nx_] = pr
        else: c[1] = pr
        c[2] -= 1
        if c[2] == 0:
            del s.cls[k]

    def _remove_end(s, row, off):
        last_off = len(s.nb[row]) - 1
        swap_remove(s.nb[row], off)
        moved = swap_remove(s.inc[row], off)
        if moved is None:
            return
        m = s.rec[moved]
        if m[0] == row and m[2] == last_off: m[2] = off
        else: m[3] = off

    def _detach(s, p):
        s.fresh = False
        r = list(s.rec[p])
        s._unlink(p)
        if r[2] > r[3] or r[0] != r[1]:
            s._remove_end(r[0], r[2]); s._remove_end(r[1], r[3])
        else:
            s._remove_end(r[1], r[3]); s._remove_end(r[0], r[2])
        last = len(s.rec) - 1
        if p != last:
            m = s.rec[last]
            s.rec[p] = m
            s.inc[m[0]][m[2]] = p
            s.inc[m[1]][m[3]] = p
            s.prev[p], s.next[p], s.uid[p] = s.prev[last], s.next[last], s.uid[last]
            c = s.cls[s.key(m[0], m[1])]
            if s.prev[p] != -1: s.next[s.prev[p]] = p
            else: c[0] = p
            if s.next[p] != -1: s.prev[s.next[p]] = p
            else: c[1] = p
        for arr in (s.rec, s.prev, s.next, s.uid):
            arr.pop()
        return (s.V[r[0]], s.V[r[1]])

    def remove_vertex(s, x):
        if x not in s.slot:
            return None
        s.fresh = False
        slot = s.slot[x]
        while s.inc[slot]:
            s._detach(s.inc[slot][-1])
        last = len(s.V) - 1
        if slot != last:
            for p in list(s.inc[last]):
                r = s.rec[p]
                if not (r[0] == last or r[1] == last):
                    continue
                ok = s.key(r[0], r[1])
                if r[0] == last: s.nb[r[1]][r[3]] = slot
                if r[1] == last: s.nb[r[0]][r[2]] = slot
                if r[0] == last: r[0] = slot
                if r[1] == last: r[1] = slot
                if ok in s.cls:
                    s.cls[s.key(r[0], r[1])] = s.cls.pop(ok)
            s.V[slot], s.V[last] = s.V[last], s.V[slot]
            s.slot[s.V[slot]] = slot
            s.nb[slot], s.inc[slot] = s.nb[last], s.inc[last]
        s.V.pop(); s.nb.pop(); s.inc.pop()
        del s.slot[x]
        return x

    def _class(s, a, b):
        if a not in s.slot or b not in s.slot:
            return None
        return s.cls.get(s.key(s.slot[a], s.slot[b]))

    def remove_edge(s, a, b):
        c = s._class(a, b)
        if not c:
            return None
        return s._detach(c[1])

    def remove_edge_at(s, p):
        if not (0 <= p < len(s.rec)):
            raise Trap("edge position out of range")
        return s._detach(p)

    def remove_edges_between(s, a, b):
        n = 0
        while s.remove_edge(a, b) is not None:
            n += 1
        return n

    def edges_between(s, a, b):
        c = s._class(a, b)
        out, p = [], (c[0] if c else -1)
        while p != -1:
            out.append(p); p = s.next[p]
        return out

    def count_between(s, a, b):
        c = s._class(a, b)
        return c[2] if c else 0

    def degree(s, x):
        if x not in s.slot:
            raise Trap("not a vertex")
        return len(s.nb[s.slot[x]])

    def edge(s, p):
        r = s.rec[p]
        return (s.V[r[0]], s.V[r[1]])

    def edges(s):
        return [s.edge(p) for p in range(len(s.rec))]

    def remove_all_edges(s):
        s.fresh = False
        s.nb = [[] for _ in s.V]; s.inc = [[] for _ in s.V]
        s.rec, s.prev, s.next, s.uid, s.cls = [], [], [], [], {}

    def remove_all(s):
        s.__init__(s.kind)
        s.fresh = False

    def sep(s):
        return "–"

    def state(s):
        rows = " ".join("%s:[%s]" % (fmt(s.V[i]), ", ".join("%s@%d" % (fmt(s.V[w]), e) for w, e in zip(s.nb[i], s.inc[i])))
                        for i in range(len(s.V)))
        return "V [%s]; E [%s]; rows %s" % (", ".join(map(fmt, s.V)), ", ".join(fmt(a) + "–" + fmt(b) for a, b in s.edges()),
                                            rows if rows else "-")

    def edge_multiset(s):
        return Counter(tuple(sorted((a, b), key=repr)) for a, b in s.edges())

    def check_laws(s):
        n, m = len(s.V), len(s.rec)
        assert len(s.slot) == n and all(s.slot[v] == i for i, v in enumerate(s.V))
        assert sum(len(r) for r in s.nb) == 2 * m
        ends = Counter()
        for i in range(n):
            assert len(s.nb[i]) == len(s.inc[i])
            for k, (w, e) in enumerate(zip(s.nb[i], s.inc[i])):
                r = s.rec[e]
                assert (r[0] == i and r[2] == k and r[1] == w) or (r[1] == i and r[3] == k and r[0] == w), (i, k, r)
                ends[e] += 1
        assert all(ends[e] == 2 for e in range(m))
        seen = set()
        for k, (f, l, c) in s.cls.items():
            p, pr, order = f, -1, []
            while p != -1:
                assert s.prev[p] == pr and s.key(s.rec[p][0], s.rec[p][1]) == k
                order.append(p); pr = p; p = s.next[p]
            assert pr == l and len(order) == c
            assert [s.uid[q] for q in order] == sorted(s.uid[q] for q in order)
            seen |= set(order)
            if not s.parallel: assert c == 1
        assert seen == set(range(m))
        if not s.loops: assert all(r[0] != r[1] for r in s.rec)
        if s.fresh:  # ReferencePseudograph's rows: each edge at u, then at v, in position order
            ref = [[] for _ in range(n)]
            for e, r in enumerate(s.rec):
                ref[r[0]].append(e); ref[r[1]].append(e)
            assert ref == s.inc, (ref, s.inc)


# ---------------------------------------------------------------------------------------------
# Directed: DirectedPseudograph (loops), DirectedMultigraph (no loops), simple mode (AdjacencyList)
# ---------------------------------------------------------------------------------------------

class D:
    directed = True

    def __init__(s, kind="DirectedPseudograph"):
        s.kind = kind
        s.loops = kind != "DirectedMultigraph"
        s.parallel = kind != "AdjacencyList"
        s.V, s.slot = [], {}
        s.out, s.oute, s.inn, s.ine = [], [], [], []
        s.rec = []  # [source, target, outOffset, inOffset]
        s.prev, s.next, s.uid, s.cls = [], [], [], {}
        s.stamp = 0
        s.fresh = True

    def _append_slot(s, x):
        s.slot[x] = len(s.V)
        s.V.append(x)
        for a in (s.out, s.oute, s.inn, s.ine):
            a.append([])
        return s.slot[x]

    def insert_vertex(s, x):
        if x in s.slot:
            return False
        s._append_slot(x)
        return True

    def insert_edge(s, a, b):
        if a == b and not s.loops:
            raise Trap("self-loop in a %s" % s.kind)
        u = s.slot[a] if a in s.slot else s._append_slot(a)
        v = s.slot[b] if b in s.slot else s._append_slot(b)
        k = (u, v)
        if not s.parallel and k in s.cls:
            return None
        p = len(s.rec)
        s.out[u].append(v); oo = len(s.out[u]) - 1; s.oute[u].append(p)
        s.inn[v].append(u); io = len(s.inn[v]) - 1; s.ine[v].append(p)
        s.rec.append([u, v, oo, io])
        s.uid.append(s.stamp); s.stamp += 1
        c = s.cls.get(k)
        if c:
            s.prev.append(c[1]); s.next.append(-1); s.next[c[1]] = p; c[1] = p; c[2] += 1
        else:
            s.prev.append(-1); s.next.append(-1); s.cls[k] = [p, p, 1]
        return p

    def _unlink(s, p):
        r = s.rec[p]
        k = (r[0], r[1])
        c = s.cls[k]
        pr, nx_ = s.prev[p], s.next[p]
        if pr != -1: s.next[pr] = nx_
        else: c[0] = nx_
        if nx_ != -1: s.prev[nx_] = pr
        else: c[1] = pr
        c[2] -= 1
        if c[2] == 0:
            del s.cls[k]

    def _detach(s, p):
        s.fresh = False
        r = list(s.rec[p])
        s._unlink(p)
        swap_remove(s.out[r[0]], r[2])
        moved = swap_remove(s.oute[r[0]], r[2])
        if moved is not None: s.rec[moved][2] = r[2]
        swap_remove(s.inn[r[1]], r[3])
        moved = swap_remove(s.ine[r[1]], r[3])
        if moved is not None: s.rec[moved][3] = r[3]
        last = len(s.rec) - 1
        if p != last:
            m = s.rec[last]
            s.rec[p] = m
            s.oute[m[0]][m[2]] = p
            s.ine[m[1]][m[3]] = p
            s.prev[p], s.next[p], s.uid[p] = s.prev[last], s.next[last], s.uid[last]
            c = s.cls[(m[0], m[1])]
            if s.prev[p] != -1: s.next[s.prev[p]] = p
            else: c[0] = p
            if s.next[p] != -1: s.prev[s.next[p]] = p
            else: c[1] = p
        for arr in (s.rec, s.prev, s.next, s.uid):
            arr.pop()
        return (s.V[r[0]], s.V[r[1]])

    def remove_vertex(s, x):
        if x not in s.slot:
            return None
        s.fresh = False
        slot = s.slot[x]
        while s.oute[slot]:
            s._detach(s.oute[slot][-1])
        while s.ine[slot]:
            s._detach(s.ine[slot][-1])
        last = len(s.V) - 1
        if slot != last:
            renamed = list(s.oute[last]) + [p for p in s.ine[last] if s.rec[p][0] != last]
            for p in renamed:
                r = s.rec[p]
                ok = (r[0], r[1])
                if r[0] == last:
                    s.inn[r[1]][r[3]] = slot
                    r[0] = slot
                if r[1] == last:
                    s.out[last if r[0] == slot else r[0]][r[2]] = slot
                    r[1] = slot
                if ok in s.cls:
                    s.cls[(r[0], r[1])] = s.cls.pop(ok)
            s.V[slot], s.V[last] = s.V[last], s.V[slot]
            s.slot[s.V[slot]] = slot
            for a in (s.out, s.oute, s.inn, s.ine):
                a[slot] = a[last]
        s.V.pop()
        for a in (s.out, s.oute, s.inn, s.ine):
            a.pop()
        del s.slot[x]
        return x

    def _class(s, a, b):
        if a not in s.slot or b not in s.slot:
            return None
        return s.cls.get((s.slot[a], s.slot[b]))

    remove_edge = U.remove_edge
    remove_edges_between = U.remove_edges_between
    edges_between = U.edges_between
    count_between = U.count_between

    def remove_edge_at(s, p):
        if not (0 <= p < len(s.rec)):
            raise Trap("edge position out of range")
        return s._detach(p)

    def degree(s, x):
        if x not in s.slot:
            raise Trap("not a vertex")
        i = s.slot[x]
        return (len(s.out[i]), len(s.inn[i]), len(s.out[i]) + len(s.inn[i]))

    def edge(s, p):
        r = s.rec[p]
        return (s.V[r[0]], s.V[r[1]])

    def edges(s):
        return [s.edge(p) for p in range(len(s.rec))]

    def remove_all_edges(s):
        s.fresh = False
        for name in ("out", "oute", "inn", "ine"):
            setattr(s, name, [[] for _ in s.V])
        s.rec, s.prev, s.next, s.uid, s.cls = [], [], [], [], {}

    def remove_all(s):
        s.__init__(s.kind)
        s.fresh = False

    def state(s):
        def rows(nb, es):
            t = " ".join("%s:[%s]" % (fmt(s.V[i]), ", ".join("%s@%d" % (fmt(s.V[w]), e) for w, e in zip(nb[i], es[i])))
                         for i in range(len(s.V)) if nb[i])
            return t if t else "-"
        return "V [%s]; E [%s]; out %s; in %s" % (", ".join(map(fmt, s.V)), ", ".join(fmt(a) + "→" + fmt(b) for a, b in s.edges()),
                                                  rows(s.out, s.oute), rows(s.inn, s.ine))

    def edge_multiset(s):
        return Counter(s.edges())

    def check_laws(s):
        n, m = len(s.V), len(s.rec)
        assert len(s.slot) == n and all(s.slot[v] == i for i, v in enumerate(s.V))
        assert sum(len(r) for r in s.out) == m and sum(len(r) for r in s.inn) == m
        for i in range(n):
            assert len(s.out[i]) == len(s.oute[i]) and len(s.inn[i]) == len(s.ine[i])
            for k, (w, e) in enumerate(zip(s.out[i], s.oute[i])):
                r = s.rec[e]; assert r[0] == i and r[1] == w and r[2] == k
            for k, (w, e) in enumerate(zip(s.inn[i], s.ine[i])):
                r = s.rec[e]; assert r[1] == i and r[0] == w and r[3] == k
        seen = set()
        for k, (f, l, c) in s.cls.items():
            p, pr, order = f, -1, []
            while p != -1:
                assert s.prev[p] == pr and (s.rec[p][0], s.rec[p][1]) == k
                order.append(p); pr = p; p = s.next[p]
            assert pr == l and len(order) == c
            assert [s.uid[q] for q in order] == sorted(s.uid[q] for q in order)
            seen |= set(order)
            if not s.parallel: assert c == 1
        assert seen == set(range(m))
        if not s.loops: assert all(r[0] != r[1] for r in s.rec)
        if s.fresh:  # ReferenceDirectedMultigraph's rows
            ro = [[] for _ in range(n)]; ri = [[] for _ in range(n)]
            for e, r in enumerate(s.rec):
                ro[r[0]].append(e); ri[r[1]].append(e)
            assert ro == s.oute and ri == s.ine


def new(kind):
    return D(kind) if kind.startswith("Directed") or kind == "AdjacencyList" else U(kind)


# ---------------------------------------------------------------------------------------------
# NetworkX shadow: the same operations on a MultiGraph / MultiDiGraph
# ---------------------------------------------------------------------------------------------

class Shadow:
    def __init__(s, g):
        s.g = g
        s.G = nx.MultiDiGraph() if g.directed else nx.MultiGraph()
        s.key = {}  # our uid -> nx key

    def sync_insert_vertex(s, x):
        s.G.add_node(x)

    def sync_insert_edge(s, a, b, p):
        if p is None:
            return
        s.key[s.g.uid[p]] = s.G.add_edge(a, b)

    def before_remove_at(s, p):
        a, b = s.g.edge(p)
        return (a, b, s.key[s.g.uid[p]])

    def remove_at(s, t):
        s.G.remove_edge(*t)

    def remove_edge(s, a, b, removed_uid):
        if not s.G.has_edge(a, b):
            assert removed_uid is None
            return
        before = set(s.G[a][b])
        s.G.remove_edge(a, b)  # NetworkX removes the last-added copy
        gone = before - set(s.G[a][b]) if s.G.has_edge(a, b) else before
        assert gone == {s.key[removed_uid]}, (gone, removed_uid)

    def check(s):
        g, G = s.g, s.G
        assert set(G.nodes) == set(g.V)
        assert G.number_of_edges() == len(g.rec)
        assert nx.number_of_selfloops(G) == sum(1 for a, b in g.edges() if a == b)
        for x in g.V:
            if g.directed:
                assert (G.out_degree(x), G.in_degree(x), G.degree(x)) == g.degree(x)
            else:
                assert G.degree(x) == g.degree(x)
        for a in g.V:
            for b in g.V:
                assert G.number_of_edges(a, b) == g.count_between(a, b), (a, b)
                if G.has_edge(a, b):
                    ours = [s.key[g.uid[p]] for p in g.edges_between(a, b)]
                    assert ours == list(G[a][b]), (a, b, ours, list(G[a][b]))
        # Conversion to the simple representation collapses copies: nx.Graph / nx.DiGraph.
        H = (nx.DiGraph if g.directed else nx.Graph)(G)
        simple = collapse(g)
        assert set(H.nodes) == set(simple.V)
        assert sorted(map(repr, (H.edges if g.directed else [tuple(sorted(e, key=repr)) for e in H.edges]))) == \
            sorted(map(repr, (simple.edges() if g.directed else [tuple(sorted(e, key=repr)) for e in simple.edges()])))


def collapse(g):
    """UndirectedAdjacencyList(g) / AdjacencyList(g): vertices in order, edges in position order, a
    repeat dropped (the first copy wins)."""
    h = new("AdjacencyList" if g.directed else "UndirectedAdjacencyList")
    for v in g.V: h.insert_vertex(v)
    for a, b in g.edges(): h.insert_edge(a, b)
    return h


def copy_generic(g, kind, vertices=None, edges=None):
    """The generic `init(_ graph:)`: vertices in order, then every edge in `edges` order."""
    h = new(kind)
    for v in (g.V if vertices is None else vertices): h.insert_vertex(v)
    try:
        for a, b in (g.edges() if edges is None else edges): h.insert_edge(a, b)
    except Trap:
        return None
    return h


# ---------------------------------------------------------------------------------------------
# Running a case: build, apply operations, render
# ---------------------------------------------------------------------------------------------

def build(kind, V, E):
    g = new(kind)
    for v in V: g.insert_vertex(v)
    sh = Shadow(g)
    for v in g.V: sh.sync_insert_vertex(v)
    for a, b in E:
        if a == b and not g.loops:
            return None, None
        p = g.insert_edge(a, b)
        sh.sync_insert_edge(a, b, p)
    return g, sh


def show_edge(g, e):
    if e is None: return "nil"
    return fmt(e[0]) + ("→" if g.directed else "–") + fmt(e[1])


def apply(g, sh, op):
    name = op[0]
    if name == "insV":
        r = g.insert_vertex(op[1]); sh.sync_insert_vertex(op[1]); return "inserted %s" % str(r).lower()
    if name == "ins":
        p = g.insert_edge(op[1], op[2]); sh.sync_insert_edge(op[1], op[2], p); return str(p)
    if name == "rm":
        c = g._class(op[1], op[2]); uid = g.uid[c[1]] if c else None
        e = g.remove_edge(op[1], op[2]); sh.remove_edge(op[1], op[2], uid); return show_edge(g, e)
    if name == "rmAt":
        if not (0 <= op[1] < len(g.rec)): raise Trap("edge position out of range")
        t = sh.before_remove_at(op[1]); e = g.remove_edge_at(op[1]); sh.remove_at(t); return show_edge(g, e)
    if name == "rmAll":
        n = 0
        while True:
            c = g._class(op[1], op[2])
            if not c: break
            uid = g.uid[c[1]]; g.remove_edge(op[1], op[2]); sh.remove_edge(op[1], op[2], uid); n += 1
        return str(n)
    if name == "rmV":
        r = g.remove_vertex(op[1])
        if r is not None: sh.G.remove_node(op[1])
        return "nil" if r is None else fmt(r)
    if name == "rmAllEdges":
        g.remove_all_edges(); sh.G.remove_edges_from(list(sh.G.edges(keys=True))); return "()"
    if name == "rmAllV":
        g.remove_all(); sh.G.clear(); return "()"
    if name == "between":
        return "[%s]" % ", ".join(map(str, g.edges_between(op[1], op[2])))
    if name == "count":
        return str(g.count_between(op[1], op[2]))
    if name == "contains":
        return str(g.count_between(op[1], op[2]) > 0).lower()
    if name == "deg":
        d = g.degree(op[1])
        return ("out %d in %d degree %d" % d) if g.directed else str(d)
    raise ValueError(op)


def show_op(g, op):
    name = op[0]
    d = (lambda a, b: "from: %s, to: %s" % (fmt(a), fmt(b))) if g.directed else (lambda a, b: "between: %s, and: %s" % (fmt(a), fmt(b)))
    E = (lambda a, b: "DirectedEdge(from: %s, to: %s)" % (fmt(a), fmt(b))) if g.directed else (lambda a, b: "UndirectedEdge(%s, %s)" % (fmt(a), fmt(b)))
    return {
        "insV": lambda: "insert(%s)" % fmt(op[1]),
        "ins": lambda: "insert(edge: %s)" % E(op[1], op[2]),
        "rm": lambda: "remove(edge: %s)" % E(op[1], op[2]),
        "rmAt": lambda: "remove(edgeAt: %d)" % op[1],
        "rmAll": lambda: "removeAllEdges(%s)" % d(op[1], op[2]),
        "rmV": lambda: "remove(%s)" % fmt(op[1]),
        "rmAllEdges": lambda: "removeAllEdges()",
        "rmAllV": lambda: "removeAll()",
        "between": lambda: "edges(%s)" % d(op[1], op[2]),
        "count": lambda: "edgeCount(%s)" % d(op[1], op[2]),
        "contains": lambda: "contains(edge: %s)" % E(op[1], op[2]),
        "deg": lambda: ("degrees(%s)" if g.directed else "degree(of: %s)") % fmt(op[1]),
    }[name]()


def lst(xs): return "[" + ", ".join(map(fmt, xs)) + "]"


def edge_list(kind, E):
    directed = kind.startswith("Directed") or kind == "AdjacencyList"
    return "[" + ", ".join(fmt(a) + ("→" if directed else "–") + fmt(b) for a, b in E) + "]"


def run_ops(kind, V, E, ops):
    """Returns (input, expected). A trap row stops at the trapping call."""
    g, sh = build(kind, V, E)
    inp = "%s V %s; E %s" % (kind, lst(V), edge_list(kind, E))
    if g is None:
        return inp, "init nil (self-loop)"
    g.check_laws(); sh.check()
    calls, results = [], []
    for op in ops:
        calls.append(show_op(g, op))
        try:
            results.append(apply(g, sh, op))
        except Trap as t:
            results.append("trap (%s)" % t)
            return inp + "; " + " / ".join(calls), " / ".join(results)
        g.check_laws(); sh.check()
    exp = (" / ".join(results) + " ⇒ " if results else "") + g.state()
    return inp + ("; " + " / ".join(calls) if calls else ""), exp


# ---------------------------------------------------------------------------------------------
# Equality, Codable, descriptions, conversions
# ---------------------------------------------------------------------------------------------

def build_ops(kind, V, E, ops=()):
    g, sh = build(kind, V, E)
    for op in ops: apply(g, sh, op)
    return g


def equal(g, h):
    return set(g.V) == set(h.V) and g.edge_multiset() == h.edge_multiset()


def encode(g):
    flat = []
    for r in g.rec: flat += [r[0], r[1]]
    return json.dumps({"vertices": g.V, "edges": flat}, separators=(",", ":"), ensure_ascii=False)


def decode(kind, payload):
    d = json.loads(payload)
    if "vertices" not in d: return "keyNotFound(vertices)"
    if "edges" not in d: return "keyNotFound(edges)"
    V, E = d["vertices"], d["edges"]
    if len(E) % 2: return "dataCorrupted(Edge list has odd length)"
    g = new(kind)
    for v in V:
        if not g.insert_vertex(v): return "dataCorrupted(Repeated vertex)"
    for i in range(0, len(E), 2):
        if not (0 <= E[i] < len(V) and 0 <= E[i + 1] < len(V)): return "dataCorrupted(Edge endpoint out of range)"
        a, b = V[E[i]], V[E[i + 1]]
        if a == b and not g.loops: return "dataCorrupted(Self-loop)"
        if g.insert_edge(a, b) is None: return "dataCorrupted(Repeated edge)"
    g.check_laws()
    return g


def description(g, limit=16):
    def l(items):
        parts = items[:limit] + (["…"] if len(items) > limit else [])
        return "[" + ", ".join(parts) + "]"
    sep = "→" if g.directed else "–"
    vs = l([fmt(v) for v in g.V]); es = l([fmt(a) + sep + fmt(b) for a, b in g.edges()])
    return vs + "; " + es, vs, es


# ---------------------------------------------------------------------------------------------
# The catalog
# ---------------------------------------------------------------------------------------------

P, M, DP, DM = "Pseudograph", "Multigraph", "DirectedPseudograph", "DirectedMultigraph"
CASES = []


def case(group, title, kind, V, E, ops=(), note=None):
    inp, exp = run_ops(kind, V, E, list(ops))
    CASES.append((group, title, inp, exp))


def row(group, title, inp, exp):
    CASES.append((group, title, inp, exp))


def define():
    # Construction
    for kind in (P, M, DP, DM):
        case("Construction", "empty", kind, [], [])
    case("Construction", "isolated vertices, repeats once", P, [0, 1, 1, 2], [])
    case("Construction", "endpoints appended in first-appearance order", P, [], [(2, 0), (1, 2)])
    case("Construction", "listed vertices first, then new endpoints", P, [5], [(3, 5), (5, 4)])
    case("Construction", "string vertices", P, ["a", "b"], [("a", "b"), ("b", "c")])
    case("Construction", "directed endpoints in first-appearance order", DP, [], [(2, 0), (1, 2)])
    case("Construction", "multigraph with no loop builds", M, [], [(0, 1), (1, 0)])
    case("Construction", "multigraph with a loop is nil", M, [], [(0, 1), (1, 1)])
    case("Construction", "directed multigraph with a loop is nil", DM, [], [(0, 0)])
    case("Construction", "directed multigraph, opposite arcs", DM, [], [(0, 1), (1, 0)])
    case("Construction", "builder: same as vertices + edges", P, [9], [(0, 1), (0, 1)])

    # Parallel copies
    case("Parallel", "two copies, both orientations kept", P, [], [(0, 1), (1, 0)], [("between", 0, 1), ("between", 1, 0), ("count", 0, 1)])
    case("Parallel", "three copies", P, [], [(0, 1)] * 3, [("between", 0, 1), ("count", 1, 0), ("deg", 0), ("deg", 1)])
    case("Parallel", "copies interleaved with other edges", P, [], [(0, 1), (1, 2), (0, 1), (2, 0), (1, 0)],
         [("between", 0, 1), ("between", 1, 2), ("between", 0, 2), ("count", 0, 1)])
    case("Parallel", "absent pair: empty, 0, false", P, [0, 1, 2], [(0, 1)], [("between", 0, 2), ("count", 0, 2), ("contains", 0, 2)])
    case("Parallel", "non-vertex: empty, 0, false, no trap", P, [0, 1], [(0, 1)], [("between", 0, 9), ("count", 9, 9), ("contains", 9, 0)])
    case("Parallel", "directed copies are directional", DP, [], [(0, 1), (0, 1), (1, 0)],
         [("between", 0, 1), ("between", 1, 0), ("count", 0, 1), ("count", 1, 0), ("contains", 1, 0)])
    case("Parallel", "directed non-vertex", DP, [0], [], [("between", 0, 7), ("count", 7, 0), ("contains", 7, 7)])
    case("Parallel", "multigraph copies", M, [], [(0, 1), (0, 1), (1, 2)], [("between", 1, 0), ("count", 0, 1)])
    case("Parallel", "directed multigraph copies", DM, [], [(0, 1), (0, 1), (1, 0), (1, 0)], [("between", 1, 0), ("count", 0, 1)])
    case("Parallel", "ten copies", P, [], [(0, 1)] * 10, [("count", 0, 1), ("deg", 0)])
    case("Parallel", "string copies", P, [], [("a", "b"), ("b", "a"), ("a", "b")], [("between", "b", "a")])

    # Loops
    case("Loops", "one loop: listed twice in its row, degree 2", P, [], [(0, 0)], [("deg", 0), ("between", 0, 0), ("count", 0, 0)])
    case("Loops", "two loops", P, [], [(0, 0), (0, 0)], [("deg", 0), ("between", 0, 0), ("count", 0, 0)])
    case("Loops", "loop beside an edge", P, [], [(0, 1), (0, 0), (1, 0)], [("deg", 0), ("deg", 1), ("between", 0, 0)])
    case("Loops", "loop on an isolated listed vertex", P, [0, 1], [(1, 1)], [("deg", 0), ("deg", 1)])
    case("Loops", "directed loop: once out, once in", DP, [], [(0, 0)], [("deg", 0), ("between", 0, 0)])
    case("Loops", "directed two loops and an arc", DP, [], [(0, 0), (0, 1), (0, 0)], [("deg", 0), ("deg", 1), ("count", 0, 0)])
    case("Loops", "multigraph insert loop traps", M, [0], [], [("ins", 0, 0)])
    case("Loops", "multigraph insert loop with new vertex traps", M, [], [], [("ins", 5, 5)])
    case("Loops", "directed multigraph insert loop traps", DM, [0, 1], [(0, 1)], [("ins", 1, 1)])

    # Degrees
    case("Degrees", "degrees count copies", P, [], [(0, 1), (0, 1), (0, 2)], [("deg", 0), ("deg", 1), ("deg", 2)])
    case("Degrees", "sum is twice the edge count with loops", P, [], [(0, 0), (0, 1), (1, 1), (1, 1)], [("deg", 0), ("deg", 1)])
    case("Degrees", "isolated vertex 0", P, [0, 1], [], [("deg", 0)])
    case("Degrees", "directed degrees", DP, [], [(0, 1), (0, 1), (1, 0), (2, 0)], [("deg", 0), ("deg", 1), ("deg", 2)])
    case("Degrees", "degree of a non-vertex traps", P, [0], [], [("deg", 1)])
    case("Degrees", "directed degree of a non-vertex traps", DP, [0], [], [("deg", 1)])
    case("Degrees", "multigraph degrees", M, [], [(0, 1), (1, 0), (1, 2)], [("deg", 0), ("deg", 1), ("deg", 2)])

    # Rows order
    case("Rows", "rows in insertion order, u end then v end", P, [], [(0, 1), (2, 0), (0, 0), (1, 2)])
    case("Rows", "loop's two ends adjacent in its row", P, [], [(0, 1), (1, 1), (1, 2)])
    case("Rows", "directed rows: out by position, in by position", DP, [], [(0, 1), (1, 0), (0, 1), (1, 1), (2, 1)])
    case("Rows", "edge stored in given orientation", P, [], [(1, 0), (0, 1)])
    case("Rows", "star of copies", P, [], [(0, 1), (0, 2), (0, 1), (0, 3), (0, 2)])

    # insert(edge:) returns the position
    case("Insert", "positions 0, 1, 2 for copies", P, [], [], [("ins", 0, 1), ("ins", 0, 1), ("ins", 1, 0)])
    case("Insert", "inserting endpoints", P, [0], [], [("ins", 1, 2), ("ins", 0, 1)])
    case("Insert", "insert loop", P, [], [], [("ins", 3, 3), ("ins", 3, 3)])
    case("Insert", "insert vertex twice", P, [], [], [("insV", 0), ("insV", 0), ("insV", 1)])
    case("Insert", "directed inserts", DP, [], [], [("ins", 0, 1), ("ins", 1, 0), ("ins", 0, 1), ("ins", 0, 0)])
    case("Insert", "multigraph inserts", M, [], [], [("ins", 0, 1), ("ins", 1, 0)])
    case("Insert", "directed multigraph inserts", DM, [], [], [("ins", 0, 1), ("ins", 0, 1)])
    case("Insert", "insert after removal reuses the end position", P, [], [(0, 1), (1, 2), (2, 0)], [("rmAt", 0), ("ins", 0, 1)])

    # remove(edge:) removes the newest copy
    case("Remove edge", "newest copy of three (last position)", P, [], [(0, 1), (0, 1), (0, 1)], [("rm", 0, 1)])
    case("Remove edge", "newest copy not at the last position", P, [], [(0, 1), (0, 1), (1, 2)], [("rm", 0, 1)])
    case("Remove edge", "orientation-free, returns stored orientation", P, [], [(1, 0), (0, 1), (2, 1)], [("rm", 1, 0)])
    case("Remove edge", "absent pair returns nil, no change", P, [], [(0, 1)], [("rm", 0, 2), ("rm", 0, 9)])
    case("Remove edge", "remove until gone", P, [], [(0, 1), (0, 1)], [("rm", 0, 1), ("rm", 0, 1), ("rm", 0, 1)])
    case("Remove edge", "newest after a re-insert", P, [], [(0, 1), (0, 1), (1, 2)], [("rm", 0, 1), ("ins", 0, 1), ("between", 0, 1), ("rm", 1, 0)])
    case("Remove edge", "loop copies", P, [], [(0, 0), (0, 1), (0, 0)], [("rm", 0, 0), ("deg", 0)])
    case("Remove edge", "directed newest copy", DP, [], [(0, 1), (1, 0), (0, 1), (1, 2)], [("rm", 0, 1)])
    case("Remove edge", "directed opposite arc absent", DP, [], [(0, 1)], [("rm", 1, 0)])
    case("Remove edge", "directed loop", DP, [], [(0, 0), (0, 1), (0, 0)], [("rm", 0, 0)])
    case("Remove edge", "copies order survives the move of the last edge", P, [], [(0, 1), (2, 3), (0, 1), (0, 1), (2, 3)],
         [("rmAt", 0), ("between", 0, 1), ("between", 2, 3), ("rm", 0, 1), ("between", 0, 1)])
    case("Remove edge", "multigraph", M, [], [(0, 1), (1, 2), (0, 1)], [("rm", 1, 0)])
    case("Remove edge", "directed multigraph", DM, [], [(0, 1), (1, 2), (0, 1)], [("rm", 0, 1)])

    # remove(edgeAt:)
    case("Remove at", "first position: last edge moves in", P, [], [(0, 1), (1, 2), (2, 0)], [("rmAt", 0)])
    case("Remove at", "last position: nothing moves", P, [], [(0, 1), (1, 2), (2, 0)], [("rmAt", 2)])
    case("Remove at", "a chosen copy, not the newest", P, [], [(0, 1), (0, 1), (0, 1)], [("rmAt", 0), ("between", 0, 1)])
    case("Remove at", "middle copy", P, [], [(0, 1), (0, 1), (0, 1)], [("rmAt", 1), ("between", 0, 1)])
    case("Remove at", "loop, both ends leave the row", P, [], [(0, 1), (0, 0), (0, 2)], [("rmAt", 1)])
    case("Remove at", "loop moved into the hole", P, [], [(0, 1), (1, 2), (1, 1)], [("rmAt", 0)])
    case("Remove at", "loop with swapped ends", P, [], [(0, 0), (0, 1), (0, 0)], [("rmAt", 0), ("rmAt", 0)])
    case("Remove at", "out of range traps", P, [], [(0, 1)], [("rmAt", 1)])
    case("Remove at", "negative traps", P, [], [(0, 1)], [("rmAt", -1)])
    case("Remove at", "empty graph traps", P, [0], [], [("rmAt", 0)])
    case("Remove at", "directed first position", DP, [], [(0, 1), (1, 2), (2, 0), (0, 1)], [("rmAt", 0)])
    case("Remove at", "directed loop moved", DP, [], [(0, 1), (1, 1), (1, 1)], [("rmAt", 0)])
    case("Remove at", "directed out of range traps", DP, [], [], [("rmAt", 0)])
    case("Remove at", "every position from the front", P, [], [(0, 1), (0, 1), (1, 1), (1, 2)], [("rmAt", 0)] * 4)
    case("Remove at", "every position from the back", P, [], [(0, 1), (0, 1), (1, 1), (1, 2)], [("rmAt", 3), ("rmAt", 2), ("rmAt", 1), ("rmAt", 0)])
    case("Remove at", "directed every position from the front", DP, [], [(0, 1), (1, 0), (1, 1), (0, 1)], [("rmAt", 0)] * 4)

    # removeEdges(between:and:)
    case("Remove all copies", "three copies among others", P, [], [(0, 1), (1, 2), (0, 1), (2, 0), (1, 0)], [("rmAll", 0, 1)])
    case("Remove all copies", "absent pair: 0", P, [], [(0, 1)], [("rmAll", 0, 2), ("rmAll", 5, 6)])
    case("Remove all copies", "loops", P, [], [(0, 0), (0, 1), (0, 0), (0, 0)], [("rmAll", 0, 0), ("deg", 0)])
    case("Remove all copies", "directed one direction only", DP, [], [(0, 1), (1, 0), (0, 1), (1, 0)], [("rmAll", 0, 1)])
    case("Remove all copies", "multigraph", M, [], [(1, 0), (0, 1), (1, 2)], [("rmAll", 0, 1)])
    case("Remove all copies", "keeps both vertices", P, [], [(0, 1), (0, 1)], [("rmAll", 1, 0)])

    # Vertex removal
    case("Remove vertex", "last slot moves into the hole", P, [], [(0, 1), (1, 2), (2, 0), (0, 1)], [("rmV", 0)])
    case("Remove vertex", "last vertex: nothing moves", P, [], [(0, 1), (1, 2), (2, 0)], [("rmV", 2)])
    case("Remove vertex", "removes every copy", P, [], [(0, 1), (0, 1), (1, 2)], [("rmV", 1)])
    case("Remove vertex", "removes its loops", P, [], [(0, 0), (0, 1), (0, 0), (1, 2)], [("rmV", 0)])
    case("Remove vertex", "moved vertex has loops and copies", P, [], [(0, 1), (2, 2), (2, 1), (1, 2), (2, 2)], [("rmV", 0), ("between", 1, 2), ("between", 2, 2)])
    case("Remove vertex", "non-vertex returns nil", P, [0], [], [("rmV", 1)])
    case("Remove vertex", "copies between survivors keep order", P, [], [(1, 2), (0, 1), (1, 2), (0, 2), (1, 2)], [("rmV", 0), ("between", 1, 2)])
    case("Remove vertex", "isolated", P, [0, 1, 2], [(1, 2)], [("rmV", 0)])
    case("Remove vertex", "directed: last slot moves in", DP, [], [(0, 1), (1, 2), (2, 0), (2, 1), (1, 2)], [("rmV", 0)])
    case("Remove vertex", "directed with loops on the moved vertex", DP, [], [(0, 1), (2, 2), (2, 1), (1, 2), (2, 2)], [("rmV", 0), ("between", 2, 2)])
    case("Remove vertex", "directed removes its loops", DP, [], [(0, 0), (0, 1), (1, 0), (0, 0)], [("rmV", 0)])
    case("Remove vertex", "directed non-vertex", DP, [], [(0, 1)], [("rmV", 3)])
    case("Remove vertex", "multigraph", M, [], [(0, 1), (1, 2), (0, 2), (1, 2)], [("rmV", 0)])
    case("Remove vertex", "directed multigraph", DM, [], [(0, 1), (1, 2), (2, 0), (1, 2)], [("rmV", 1)])
    case("Remove vertex", "every vertex", P, [], [(0, 1), (1, 1), (1, 2), (2, 0)], [("rmV", 0), ("rmV", 1), ("rmV", 2)])

    # Mutation sequences
    case("Sequence", "insert, remove, insert", P, [], [], [("ins", 0, 1), ("ins", 1, 2), ("ins", 0, 1), ("rm", 0, 1), ("ins", 2, 2), ("rmAt", 0), ("between", 0, 1)])
    case("Sequence", "copies around vertex removal", P, [], [(0, 1), (1, 2), (0, 1), (2, 3), (3, 0), (1, 2)],
         [("rmV", 2), ("ins", 1, 3), ("ins", 1, 3), ("rm", 3, 1), ("between", 0, 1), ("between", 1, 3)])
    case("Sequence", "loops and swaps", P, [], [(0, 0), (1, 1), (0, 1), (0, 0), (1, 1)], [("rmAt", 0), ("rmAt", 0), ("rmV", 1), ("between", 0, 0)])
    case("Sequence", "directed sequence", DP, [], [], [("ins", 0, 1), ("ins", 1, 0), ("ins", 0, 1), ("ins", 1, 1), ("rm", 0, 1), ("rmV", 0), ("ins", 1, 2), ("ins", 2, 1)])
    case("Sequence", "removeAllEdges keeps vertices", P, [], [(0, 1), (0, 1), (1, 1)], [("rmAllEdges",), ("ins", 1, 0)])
    case("Sequence", "removeAll", DP, [], [(0, 1), (0, 1)], [("rmAllV",), ("ins", 5, 6)])
    case("Sequence", "strings", P, [], [("a", "b"), ("b", "c"), ("a", "b"), ("c", "c")], [("rmV", "a"), ("ins", "c", "b"), ("rm", "b", "c")])
    case("Sequence", "re-insert removed vertex", P, [], [(0, 1), (0, 1)], [("rmV", 0), ("ins", 0, 1), ("between", 0, 1)])
    case("Sequence", "directed multigraph sequence", DM, [], [(0, 1), (1, 0), (0, 1)], [("rmAt", 0), ("ins", 2, 0), ("rmV", 1), ("between", 2, 0)])
    case("Sequence", "multigraph sequence", M, [], [(0, 1), (1, 2), (2, 0), (0, 1)], [("rmAll", 0, 1), ("ins", 0, 2), ("rmV", 2)])

    # Equality and hashing
    eqs = [
        ("same edges, other order", P, ([], [(0, 1), (0, 1), (1, 2)]), ([], [(1, 2), (0, 1), (1, 0)]), ()),
        ("copy count differs", P, ([], [(0, 1), (0, 1)]), ([], [(0, 1)]), ()),
        ("orientation ignored", P, ([], [(0, 1)]), ([], [(1, 0)]), ()),
        ("isolated vertex differs", P, ([2], [(0, 1)]), ([], [(0, 1)]), ()),
        ("vertex order ignored", P, ([0, 1, 2], []), ([2, 1, 0], []), ()),
        ("loop count differs", P, ([], [(0, 0)]), ([], [(0, 0), (0, 0)]), ()),
        ("after removal equal to fresh", P, ([], [(0, 1), (1, 2), (0, 1)]), ([], [(1, 2), (0, 1)]), (("rmAt", 0),)),
        ("directed orientation matters", DP, ([], [(0, 1)]), ([], [(1, 0)]), ()),
        ("directed copies", DP, ([], [(0, 1), (0, 1), (1, 0)]), ([], [(1, 0), (0, 1), (0, 1)]), ()),
        ("directed copy count differs", DP, ([], [(0, 1), (1, 0)]), ([], [(0, 1), (0, 1)]), ()),
        ("empty graphs", P, ([], []), ([], []), ()),
        ("multigraph same edges", M, ([], [(0, 1), (1, 0)]), ([], [(0, 1), (0, 1)]), ()),
        ("same edge multiset, different pairs", P, ([], [(0, 1), (2, 3)]), ([], [(0, 2), (1, 3)]), ()),
        ("strings", P, ([], [("a", "b"), ("b", "a")]), ([], [("b", "a"), ("a", "b")]), ()),
    ]
    for title, kind, (V1, E1), (V2, E2), ops in eqs:
        g = build_ops(kind, V1, E1, ops); h = build_ops(kind, V2, E2)
        e = equal(g, h)
        row("Equality", title, "%s V %s E %s%s vs V %s E %s" % (kind, lst(V1), edge_list(kind, E1), (" then " + " / ".join(show_op(g, o) for o in ops)) if ops else "", lst(V2), edge_list(kind, E2)),
            "== %s%s" % (str(e).lower(), "; equal hashes" if e else ""))

    # Codable round trips and corrupt payloads
    trips = [
        (P, [], [(0, 1), (0, 1), (1, 1)], ()),
        (P, [3], [(0, 1)], ()),
        (P, [], [(0, 1), (1, 2), (0, 1), (2, 2)], (("rmAt", 0),)),
        (P, ["a", "b"], [("b", "a"), ("a", "b")], ()),
        (M, [], [(0, 1), (1, 0)], ()),
        (DP, [], [(0, 1), (0, 1), (1, 0), (1, 1)], ()),
        (DM, [], [(0, 1), (0, 1)], ()),
        (P, [], [], ()),
    ]
    for kind, V, E, ops in trips:
        g = build_ops(kind, V, E, ops)
        payload = encode(g)
        back = decode(kind, payload)
        assert back.state() == g.state() or ops, (back.state(), g.state())
        assert equal(back, g) and back.edges() == g.edges() and back.V == g.V
        row("Codable", "round trip keeps vertex order and positions", "%s V %s E %s%s" % (kind, lst(V), edge_list(kind, E), (" then " + " / ".join(show_op(g, o) for o in ops)) if ops else ""),
            "encodes %s; decodes to %s" % (payload, back.state()))
    corrupt = [
        (P, '{"vertices":[0,1],"edges":[0,1,0,1]}', "copies accepted"),
        (P, '{"vertices":[0],"edges":[0,0,0,0]}', "loops accepted"),
        (M, '{"vertices":[0],"edges":[0,0]}', "loop rejected"),
        (DM, '{"vertices":[0,1],"edges":[0,1,1,1]}', "directed loop rejected"),
        (DP, '{"vertices":[0],"edges":[0,0]}', "directed loop accepted"),
        (P, '{"vertices":[0,1],"edges":[0]}', "odd length"),
        (P, '{"vertices":[0,0],"edges":[]}', "repeated vertex"),
        (P, '{"vertices":[0,1],"edges":[0,2]}', "endpoint out of range"),
        (P, '{"vertices":[0,1],"edges":[-1,0]}', "negative endpoint"),
        (DP, '{"vertices":[],"edges":[0,0]}', "endpoint with no vertices"),
        (P, '{"edges":[]}', "missing vertices"),
        (DP, '{"vertices":[]}', "missing edges"),
        (P, '{"vertices":["a","b"],"edges":[1,0,0,1]}', "string vertices"),
        (DM, '{"vertices":[0,1],"edges":[0,1,0,1,1,0]}', "directed copies accepted"),
    ]
    for kind, payload, title in corrupt:
        r = decode(kind, payload)
        row("Codable", title, "%s decode %s" % (kind, payload), r if isinstance(r, str) else r.state())
    # Cross-type payloads: the simple lists use the same format
    ual = new("UndirectedAdjacencyList")
    for a, b in [(0, 1), (1, 1)]: ual.insert_edge(a, b)
    p = encode(ual)
    row("Codable", "UndirectedAdjacencyList payload decodes as Pseudograph", "Pseudograph decode %s" % p, decode(P, p).state())
    row("Codable", "Pseudograph payload with copies fails as UndirectedAdjacencyList", "UndirectedAdjacencyList decode %s" % '{"vertices":[0,1],"edges":[0,1,1,0]}',
        decode("UndirectedAdjacencyList", '{"vertices":[0,1],"edges":[0,1,1,0]}'))
    row("Codable", "AdjacencyList payload with a loop fails as DirectedMultigraph", "DirectedMultigraph decode %s" % '{"vertices":[0],"edges":[0,0]}', decode(DM, '{"vertices":[0],"edges":[0,0]}'))

    # Descriptions
    for kind, V, E in [(P, [], [(0, 1), (0, 1), (1, 1)]), (DP, [], [(0, 1), (0, 1), (1, 1)]), (P, [], []), (M, ["a"], [("a", "b"), ("b", "a")]),
                       (DM, [], [(0, 1), (1, 0)]), (P, [], [(0, 1)] * 17)]:
        g = build_ops(kind, V, E)
        d, vs, es = description(g)
        row("Description", "description and debugDescription", "%s V %s E %s" % (kind, lst(V), edge_list(kind, E) if len(E) < 17 else "[0–1 × 17]"),
            "%s ‖ %s<%s>(vertexCount: %d, edgeCount: %d, vertices: %s, edges: %s)" % (d, kind, "String" if any(isinstance(v, str) for v in g.V) else "Int", len(g.V), len(g.rec), vs, es))

    # Conversions
    conv = [
        (P, [3], [(0, 1), (1, 0), (1, 1), (1, 1), (1, 2)], (), "UndirectedAdjacencyList(g): first copy wins"),
        (P, [], [(1, 0), (0, 1)], (), "UndirectedAdjacencyList(g): orientation of the first copy"),
        (P, [], [(0, 1), (1, 2), (0, 1), (2, 0)], (("rmAt", 0),), "UndirectedAdjacencyList(g) after removal"),
        (DP, [], [(0, 1), (1, 0), (0, 1), (0, 0), (0, 0)], (), "AdjacencyList(g): first copy wins"),
        (M, [], [(0, 1), (0, 1), (2, 1)], (), "UndirectedAdjacencyList(multigraph)"),
        (DM, [2], [(0, 1), (0, 1)], (), "AdjacencyList(directedMultigraph)"),
    ]
    for kind, V, E, ops, title in conv:
        g = build_ops(kind, V, E, ops)
        row("Conversion", title, "%s V %s E %s%s" % (kind, lst(V), edge_list(kind, E), (" then " + " / ".join(show_op(g, o) for o in ops)) if ops else ""),
            collapse(g).state())
    # Simple to multi: positions kept; rows rebuilt in position order
    ual = new("UndirectedAdjacencyList")
    for a, b in [(0, 1), (0, 2), (0, 3), (1, 2)]: ual.insert_edge(a, b)
    ual.remove_edge_at(0)
    pg = copy_generic(ual, P); pg.check_laws()
    row("Conversion", "Pseudograph(ual): positions kept, rows by position",
        "UndirectedAdjacencyList E [0–1, 0–2, 0–3, 1–2] then remove(edge: 0–1) = " + ual.state(), pg.state())
    al = new("AdjacencyList")
    for a, b in [(0, 1), (1, 1), (1, 0), (2, 1)]: al.insert_edge(a, b)
    al.remove_edge_at(0)
    dp = copy_generic(al, DP); dp.check_laws()
    row("Conversion", "DirectedPseudograph(adjacencyList): positions kept, rows by position",
        "AdjacencyList E [0→1, 1→1, 1→0, 2→1] then remove(edge: 0→1) = " + al.state(), dp.state())
    ual = new("UndirectedAdjacencyList"); ual.insert_edge(0, 1); ual.insert_edge(1, 1)
    row("Conversion", "Multigraph(ual) with a loop is nil", "UndirectedAdjacencyList E [0–1, 1–1]", "nil" if copy_generic(ual, M) is None else "?")
    ual = new("UndirectedAdjacencyList"); ual.insert_edge(0, 1); ual.insert_edge(1, 2)
    row("Conversion", "Multigraph(ual) without loops", "UndirectedAdjacencyList E [0–1, 1–2]", copy_generic(ual, M).state())
    g = build_ops(P, [], [(0, 1), (0, 1), (1, 2)])
    row("Conversion", "Multigraph(pseudograph), no loops", "Pseudograph E [0–1, 0–1, 1–2]", copy_generic(g, M).state())
    g = build_ops(P, [], [(0, 1), (1, 1)])
    row("Conversion", "Multigraph(pseudograph) with a loop is nil", "Pseudograph E [0–1, 1–1]", "nil" if copy_generic(g, M) is None else "?")
    g = build_ops(M, [7], [(0, 1), (0, 1)])
    row("Conversion", "Pseudograph(multigraph): the same value", "Multigraph V [7] E [0–1, 0–1]", copy_generic(g, P).state())
    g = build_ops(DP, [], [(0, 1), (1, 0), (1, 1)])
    und = [(a, b) for a, b in g.edges()]  # UndirectedView: each arc an edge at its own position
    h = copy_generic(g, P, edges=und); h.check_laws()
    row("Conversion", "Pseudograph(digraph.undirected): opposite arcs become copies", "DirectedPseudograph E [0→1, 1→0, 1→1]", h.state())
    g = build_ops(P, [], [(0, 1), (0, 1), (1, 1)])
    dirs = []
    for a, b in g.edges(): dirs += [(a, b), (b, a)]  # DirectedView: u→v then v→u per edge
    h = copy_generic(g, DP, edges=dirs); h.check_laws()
    row("Conversion", "DirectedPseudograph(graph.directed): two arcs per edge, a loop's two arcs", "Pseudograph E [0–1, 0–1, 1–1]", h.state())
    h = copy_generic(g, DM, edges=dirs)
    row("Conversion", "DirectedMultigraph(graph.directed) with a loop is nil", "Pseudograph E [0–1, 0–1, 1–1]", "nil" if h is None else "?")
    g = build_ops(DP, [], [(0, 1), (0, 1), (1, 1)])
    row("Conversion", "DirectedMultigraph(directedPseudograph) with a loop is nil", "DirectedPseudograph E [0→1, 0→1, 1→1]", "nil" if copy_generic(g, DM) is None else "?")
    g = build_ops(DM, [], [(0, 1), (0, 1)])
    row("Conversion", "DirectedPseudograph(directedMultigraph)", "DirectedMultigraph E [0→1, 0→1]", copy_generic(g, DP).state())
    g = build_ops(P, [], [(0, 1), (1, 2), (0, 1), (2, 2)], [("rmAt", 0)])
    row("Conversion", "Pseudograph(pseudograph) returns it unchanged (rows included)", "Pseudograph E [0–1, 1–2, 0–1, 2–2] then remove(edgeAt: 0)", g.state())

    # Traps (preconditions; exit tests)
    traps = [
        ("degree(of:) non-vertex", P, "degree(of: 5)"),
        ("neighbors(of:) non-vertex", P, "neighbors(of: 5)"),
        ("incidentEdges(of:) non-vertex", P, "incidentEdges(of: 5)"),
        ("vertexIndex(of:) non-vertex", P, "vertexIndex(of: 5)"),
        ("oppositeVertex non-endpoint", P, "oppositeVertex(to: 2, acrossEdgeAt: 0) with E [0–1]"),
        ("oppositeVertex position out of range", P, "oppositeVertex(to: 0, acrossEdgeAt: 1) with E [0–1]"),
        ("edges[p] out of range", P, "edges[1] with E [0–1]"),
        ("source(ofEdgeAt:) out of range", DP, "source(ofEdgeAt: 1) with E [0→1]"),
        ("successors(of:) non-vertex", DP, "successors(of: 5)"),
        ("predecessors(of:) non-vertex", DP, "predecessors(of: 5)"),
        ("inDegree(of:) non-vertex", DP, "inDegree(of: 5)"),
        ("reserveCapacity negative vertices", P, "reserveCapacity(vertexCount: -1, edgeCount: 0)"),
        ("reserveCapacity negative edges", DM, "reserveCapacity(vertexCount: 0, edgeCount: -1)"),
        ("DirectedMultigraph remove(edgeAt:) out of range", DM, "remove(edgeAt: 2) with E [0→1, 0→1]"),
    ]
    for title, kind, call in traps:
        row("Trap", title, "%s %s" % (kind, call), "trap")


def render():
    out = [HEADER, "| ID | Group | Case | Input / call | Expected |", "|---|---|---|---|---|"]
    for i, (g, t, inp, exp) in enumerate(CASES, 1):
        esc = lambda x: x.replace("|", "\\|")
        out.append("| MG-%03d | %s | %s | %s | %s |" % (i, g, esc(t), esc(inp), esc(exp)))
    return "\n".join(out) + "\n"


HEADER = """# Multigraphs: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 python3 ref.py`;
`--write` regenerates this file). Every Expected is the model's output (an exact port of the
proposed storage), and every state a row reaches is checked against the Graph laws, the class
lists, the reference conformers' rows (for freshly built graphs), and a NetworkX 3.7
MultiGraph / MultiDiGraph driven by the same calls (degrees, number_of_edges(u, v) for every pair,
self-loop count, the copy remove_edge(u, v) removes, the key order of G[u][v]).

Conventions:

* Input `Kind V [...]; E [...]` is `Kind(vertices: V, edges: E)`: vertices in order, then edges at
  positions 0, 1, … (a Multigraph / DirectedMultigraph row with a self-loop is the failable init
  returning nil). Calls follow, separated by `/`; Expected lists each call's result, then `⇒` and
  the final state.
* State: `V` is `vertices` (vertex index order); `E` is `edges` by position, each in its stored
  orientation; undirected `rows v:[w@e, …]` is `neighbors(of: v)` zipped with
  `incidentEdges(of: v)` (a self-loop twice); directed `out` / `in` are `successors` /
  `predecessors` zipped with `outEdges` / `inEdges` (empty rows omitted).
* `edges(between:and:)` / `edges(from:to:)` list positions oldest copy first; `remove(edge:)`
  removes the newest copy (NetworkX's `remove_edge(u, v)`); a removal moves the last edge into
  the hole and each row's last entry into its hole; removing a vertex moves the last slot into
  its place (UndirectedAdjacencyList's and AdjacencyList's rules).
* `degrees(v)` (directed) is `outDegree`, `inDegree`, `degree`.
* `trap` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`).
* Codable payloads are `{"vertices": […], "edges": [u0, v0, u1, v1, …]}` (indices into vertices),
  the simple lists' format; errors are `DecodingError` cases with their debug description.

"""


def stress(seed_count=300, steps=40):
    """Random operation sequences on all four kinds: laws and NetworkX after every call."""
    import random
    for seed in range(seed_count):
        rnd = random.Random(seed)
        for kind in (P, M, DP, DM):
            g, sh = build(kind, [], [])
            for _ in range(steps):
                r = rnd.random(); a, b = rnd.randrange(5), rnd.randrange(5)
                if not g.loops and a == b: b = (a + 1) % 5
                if r < 0.45: op = ("ins", a, b)
                elif r < 0.6: op = ("rm", a, b)
                elif r < 0.75 and g.rec: op = ("rmAt", rnd.randrange(len(g.rec)))
                elif r < 0.85: op = ("rmV", a)
                elif r < 0.9: op = ("rmAll", a, b)
                else: op = ("insV", a)
                apply(g, sh, op)
                g.check_laws(); sh.check()


def main():
    stress()
    define()
    text = render()
    if "--write" in sys.argv:
        open(CASES_MD, "w").write(text)
        print("wrote %d cases" % len(CASES))
        return
    existing = open(CASES_MD).read() if os.path.exists(CASES_MD) else ""
    if existing != text:
        print("cases.md differs from the model (run with --write)"); sys.exit(1)
    print("ok: %d cases and 1200 random sequences, every state checked against the laws and NetworkX %s" % (len(CASES), nx.__version__))


if __name__ == "__main__":
    main()
