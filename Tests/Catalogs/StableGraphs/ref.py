"""Reference model for StableGraphs' StableDirectedGraph (see api.md).

    uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/StableGraphs/ref.py
        checks cases.md against the model
    ... ref.py --write    regenerates cases.md
    ... ref.py --stress   also runs the random operation sequences (rustworkx and NetworkX shadows)
    ... ref.py --bench    times rustworkx (petgraph StableGraph) on the benchmark instance

`Port` is a direct port of the proposed storage: vertex slots and edge records that are never
reused, with tombstones, and doubly linked out- and in-lists threaded through the edge records.
`Spec` is the specification written plainly: everything lives at a monotone position and every
order is position order. Every state is checked port == spec, against the DirectedGraph and
BidirectionalDirectedGraph laws (including the state-dependent index bounds), and, in --stress,
against a rustworkx PyDiGraph (petgraph StableGraph) and a NetworkX MultiDiGraph driven by the
same calls.
"""
import json
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
NIL = -1


class Trap(Exception):
    pass


def need(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------------------------------------
# The port of the proposed storage.

class Port:
    """Per-slot and per-position fields are dicts keyed by live slot or position: a hole, and every
    position of a freed page, has no key, so a gap of any length costs nothing (decoding a payload
    whose end is far past its elements is O(elements))."""

    def __init__(self):
        self.removeAll()

    # storage ------------------------------------------------------------------------------
    def removeAll(self):
        self.vert = {}           # live slot -> vertex
        self.slot = {}           # vertex -> slot
        self.head_out, self.tail_out, self.head_in, self.tail_in = {}, {}, {}, {}
        self.outdeg, self.indeg = {}, {}
        self.src, self.dst = {}, {}          # live position -> slot
        self.prev_out, self.next_out, self.prev_in, self.next_in = {}, {}, {}, {}
        self.vend = 0
        self.eend = 0
        self.vcount = 0
        self.ecount = 0

    def removeAllEdges(self):
        for s in self.vert:
            self.head_out[s] = self.tail_out[s] = self.head_in[s] = self.tail_in[s] = NIL
            self.outdeg[s] = self.indeg[s] = 0
        self.src, self.dst = {}, {}
        self.prev_out, self.next_out, self.prev_in, self.next_in = {}, {}, {}, {}
        self.eend = 0
        self.ecount = 0

    def _s(self, v):
        need(v in self.slot, "not a vertex")
        return self.slot[v]

    # mutation -----------------------------------------------------------------------------
    def insert(self, v):
        if v in self.slot:
            return (False, v)
        s = self.vend
        self.vend += 1
        self.vert[s] = v; self.slot[v] = s
        for a in (self.head_out, self.tail_out, self.head_in, self.tail_in):
            a[s] = NIL
        self.outdeg[s] = 0; self.indeg[s] = 0
        self.vcount += 1
        return (True, v)

    def _link_out(self, p, a):
        """Links position p into slot a's out-list at its place in position order."""
        q = self.tail_out[a]
        while q != NIL and q > p:
            q = self.prev_out[q]
        nxt = self.head_out[a] if q == NIL else self.next_out[q]
        self.prev_out[p], self.next_out[p] = q, nxt
        if q == NIL: self.head_out[a] = p
        else: self.next_out[q] = p
        if nxt == NIL: self.tail_out[a] = p
        else: self.prev_out[nxt] = p
        self.outdeg[a] += 1

    def _link_in(self, p, b):
        q = self.tail_in[b]
        while q != NIL and q > p:
            q = self.prev_in[q]
        nxt = self.head_in[b] if q == NIL else self.next_in[q]
        self.prev_in[p], self.next_in[p] = q, nxt
        if q == NIL: self.head_in[b] = p
        else: self.next_in[q] = p
        if nxt == NIL: self.tail_in[b] = p
        else: self.prev_in[nxt] = p
        self.indeg[b] += 1

    def _unlink_out(self, p):
        a = self.src[p]
        po, no = self.prev_out[p], self.next_out[p]
        if po == NIL: self.head_out[a] = no
        else: self.next_out[po] = no
        if no == NIL: self.tail_out[a] = po
        else: self.prev_out[no] = po
        self.outdeg[a] -= 1

    def _unlink_in(self, p):
        b = self.dst[p]
        pi, ni = self.prev_in[p], self.next_in[p]
        if pi == NIL: self.head_in[b] = ni
        else: self.next_in[pi] = ni
        if ni == NIL: self.tail_in[b] = pi
        else: self.prev_in[ni] = pi
        self.indeg[b] -= 1

    def insert_edge(self, u, v):
        self.insert(u); self.insert(v)
        a, b = self.slot[u], self.slot[v]
        need(self.eend < 2 ** 63 - 1, "edge positions exhausted")
        p = self.eend
        self.eend += 1
        self.src[p] = a; self.dst[p] = b
        self._link_out(p, a)
        self._link_in(p, b)
        self.ecount += 1
        return p

    def _unlink(self, p):
        a, b = self.src[p], self.dst[p]
        self._unlink_out(p)
        self._unlink_in(p)
        for d in (self.src, self.dst, self.prev_out, self.next_out, self.prev_in, self.next_in):
            del d[p]
        self.ecount -= 1
        return (self.vert[a], self.vert[b])

    def is_edge(self, p):
        return p in self.src

    def remove_edgeAt(self, p):
        need(self.is_edge(p), "not an edge position")
        return self._unlink(p)

    def change_target(self, p, v):
        need(self.is_edge(p), "not an edge position")
        b = self._s(v)
        if b != self.dst[p]:
            self._unlink_in(p); self.dst[p] = b; self._link_in(p, b)
        return None

    def change_source(self, p, u):
        need(self.is_edge(p), "not an edge position")
        a = self._s(u)
        if a != self.src[p]:
            self._unlink_out(p); self.src[p] = a; self._link_out(p, a)
        return None

    def change_target_safe(self, p, v):
        if not self.is_edge(p) or v not in self.slot: return False
        self.change_target(p, v); return True

    def change_source_safe(self, p, u):
        if not self.is_edge(p) or u not in self.slot: return False
        self.change_source(p, u); return True

    def remove_edge(self, u, v):
        if u not in self.slot or v not in self.slot:
            return None
        b = self.slot[v]
        p = self.tail_out[self.slot[u]]      # newest copy: walk back from the tail
        while p != NIL and self.dst[p] != b:
            p = self.prev_out[p]
        return None if p == NIL else self._unlink(p)

    def removeAllEdges_between(self, u, v):
        if u not in self.slot or v not in self.slot:
            return 0
        b, n = self.slot[v], 0
        p = self.tail_out[self.slot[u]]
        while p != NIL:
            q = self.prev_out[p]
            if self.dst[p] == b:
                self._unlink(p); n += 1
            p = q
        return n

    def removeAllEdges_from_where(self, u, chosen):
        """One pass over u's out-row, oldest first; the predicate is membership in `chosen`."""
        if u not in self.slot:
            return 0
        n, p = 0, self.head_out[self.slot[u]]
        while p != NIL:
            q = self.next_out[p]
            if p in chosen:
                self._unlink(p); n += 1
            p = q
        return n

    def removeAllEdges_where(self, chosen):
        """Each live vertex's out-row in turn, in vertices order."""
        return sum(self.removeAllEdges_from_where(v, chosen) for v, _ in self.vertices())

    def visit_order(self, u=None):
        """The positions the predicate sees: u's out-row, or every out-row in vertices order."""
        if u is not None:
            return self.out_edges(u) if u in self.slot else []
        return [p for v, _ in self.vertices() for p in self.out_edges(v)]

    def insert_safe(self, u, v):
        if u not in self.slot or v not in self.slot:
            return None
        return self.insert_edge(u, v)

    def remove(self, v):
        if v not in self.slot:
            return None
        s = self.slot.pop(v)
        while self.head_out[s] != NIL:
            self._unlink(self.head_out[s])
        while self.head_in[s] != NIL:
            self._unlink(self.head_in[s])
        for d in (self.vert, self.head_out, self.tail_out, self.head_in, self.tail_in, self.outdeg, self.indeg):
            del d[s]
        self.vcount -= 1
        return v

    # queries ------------------------------------------------------------------------------
    def vertices(self):
        return [(self.vert[s], s) for s in sorted(self.vert)]

    def edges(self):
        return [(p, self.vert[self.src[p]], self.vert[self.dst[p]]) for p in sorted(self.src)]

    def out_edges(self, v):
        s, r = self._s(v), []
        p = self.head_out[s]
        while p != NIL:
            r.append(p); p = self.next_out[p]
        return r

    def in_edges(self, v):
        s, r = self._s(v), []
        p = self.head_in[s]
        while p != NIL:
            r.append(p); p = self.next_in[p]
        return r

    def source(self, p):
        need(self.is_edge(p), "not an edge position")
        return self.vert[self.src[p]]

    def target(self, p):
        need(self.is_edge(p), "not an edge position")
        return self.vert[self.dst[p]]

    def vertex_end(self): return self.vend
    def edge_end(self): return self.eend

    def vertexIndexBound(self):
        return self.vcount if self.vcount == self.vend else None

    def edgeIndexBound(self):
        return self.ecount if self.ecount == self.eend else None


# ---------------------------------------------------------------------------------------------
# The specification, written plainly.

class Spec:
    def __init__(self):
        self.V = []      # (vertex, slot) in slot order
        self.E = []      # (position, u, v) in position order
        self.vend = 0
        self.eend = 0

    def has(self, v): return any(x == v for x, _ in self.V)

    def insert(self, v):
        if self.has(v): return (False, v)
        self.V.append((v, self.vend)); self.vend += 1
        return (True, v)

    def insert_edge(self, u, v):
        self.insert(u); self.insert(v)
        p = self.eend; self.eend += 1
        self.E.append((p, u, v))
        return p

    def remove_edgeAt(self, p):
        for i, (q, u, v) in enumerate(self.E):
            if q == p:
                del self.E[i]; return (u, v)
        raise Trap("not an edge position")

    def remove_edge(self, u, v):
        copies = [q for q, a, b in self.E if (a, b) == (u, v)]
        return self.remove_edgeAt(copies[-1]) if copies else None

    def removeAllEdges_between(self, u, v):
        copies = [q for q, a, b in self.E if (a, b) == (u, v)]
        for q in copies: self.remove_edgeAt(q)
        return len(copies)

    def removeAllEdges_from_where(self, u, chosen):
        if not self.has(u): return 0
        copies = [q for q, a, _ in self.E if a == u and q in chosen]
        for q in copies: self.remove_edgeAt(q)
        return len(copies)

    def removeAllEdges_where(self, chosen):
        copies = [q for q, _, _ in self.E if q in chosen]
        for q in copies: self.remove_edgeAt(q)
        return len(copies)

    def insert_safe(self, u, v):
        return self.insert_edge(u, v) if self.has(u) and self.has(v) else None

    def change_target(self, p, v):
        i = next((i for i, e in enumerate(self.E) if e[0] == p), None)
        need(i is not None, "not an edge position"); need(self.has(v), "not a vertex")
        self.E[i] = (p, self.E[i][1], v)

    def change_source(self, p, u):
        i = next((i for i, e in enumerate(self.E) if e[0] == p), None)
        need(i is not None, "not an edge position"); need(self.has(u), "not a vertex")
        self.E[i] = (p, u, self.E[i][2])

    def change_target_safe(self, p, v):
        if not any(e[0] == p for e in self.E) or not self.has(v): return False
        self.change_target(p, v); return True

    def change_source_safe(self, p, u):
        if not any(e[0] == p for e in self.E) or not self.has(u): return False
        self.change_source(p, u); return True

    def remove(self, v):
        if not self.has(v): return None
        self.E = [e for e in self.E if v not in (e[1], e[2])]
        self.V = [x for x in self.V if x[0] != v]
        return v

    def removeAll(self): self.__init__()

    def removeAllEdges(self): self.E = []; self.eend = 0

    def vertices(self): return list(self.V)
    def edges(self): return list(self.E)

    def out_edges(self, v):
        need(self.has(v), "not a vertex")
        return [q for q, a, _ in self.E if a == v]

    def in_edges(self, v):
        need(self.has(v), "not a vertex")
        return [q for q, _, b in self.E if b == v]

    def vertex_end(self): return self.vend
    def edge_end(self): return self.eend
    def vertexIndexBound(self): return len(self.V) if len(self.V) == self.vend else None
    def edgeIndexBound(self): return len(self.E) if len(self.E) == self.eend else None


# ---------------------------------------------------------------------------------------------
# Laws.

def snapshot(g):
    V, E = g.vertices(), g.edges()
    rows = {v: (g.out_edges(v), g.in_edges(v)) for v, _ in V}
    return (V, E, rows, g.vertex_end(), g.edge_end(), g.vertexIndexBound(), g.edgeIndexBound())


def check_laws(g):
    V, E, rows, vend, eend, vib, eib = snapshot(g)
    verts = [v for v, _ in V]
    assert len(set(verts)) == len(verts)
    slots = [s for _, s in V]
    assert slots == sorted(slots) and all(0 <= s < vend for s in slots), "vertex positions increase"
    pos = [p for p, _, _ in E]
    assert pos == sorted(set(pos)) and all(0 <= p < eend for p in pos), "edge positions increase"
    by = {p: (u, v) for p, u, v in E}
    assert all(u in verts and v in verts for u, v in by.values())
    outs = []
    for v in verts:
        o, i = rows[v]
        assert o == sorted(o) and i == sorted(i), "rows in position (insertion) order"
        assert all(by[p][0] == v for p in o) and all(by[p][1] == v for p in i)
        outs += o
        assert sorted(i) == sorted(p for p in pos if by[p][1] == v)
    assert sorted(outs) == pos, "out-degrees sum to edgeCount, each position once"
    assert (vib is not None) == (vend == len(V)), "vertex indices exactly when no vertex holes"
    assert (eib is not None) == (eend == len(E)), "edge indices exactly when no edge holes"
    if vib is not None:
        assert vib == len(V) and slots == list(range(vib)), "vertex(atIndex: i) is the ith vertex"
    if eib is not None:
        assert eib == len(E) and pos == list(range(eib)), "edgeIndex(of: p) == p, edges in index order"


def same(port, spec):
    a, b = snapshot(port), snapshot(spec)
    assert a == b, f"port {a}\nspec {b}"


# ---------------------------------------------------------------------------------------------
# Running a case: both models, same calls.

def fmt(x):
    return json.dumps(x) if isinstance(x, str) else str(x)


def show_state(g):
    V, E, rows, vend, eend, vib, eib = snapshot(g)
    s = "V [" + ", ".join(f"{fmt(v)}#{k}" for v, k in V) + f"] end {vend}; "
    s += "E [" + ", ".join(f"{p}:{fmt(u)}→{fmt(v)}" for p, u, v in E) + f"] end {eend}; "
    s += f"bounds {vib if vib is not None else 'nil'}/{eib if eib is not None else 'nil'}"
    by = {p: (u, v) for p, u, v in E}
    out = " ".join(f"{fmt(v)}:[" + ", ".join(f"{fmt(by[p][1])}@{p}" for p in rows[v][0]) + "]" for v, _ in V if rows[v][0])
    inn = " ".join(f"{fmt(v)}:[" + ", ".join(f"{fmt(by[p][0])}@{p}" for p in rows[v][1]) + "]" for v, _ in V if rows[v][1])
    return s + f"; out {out or '-'}; in {inn or '-'}"


def show_result(r):
    if r is None: return "nil"
    if isinstance(r, tuple) and len(r) == 2 and isinstance(r[0], bool):
        return f"({str(r[0]).lower()}, {fmt(r[1])})"
    if isinstance(r, tuple): return f"{fmt(r[0])}→{fmt(r[1])}"
    if isinstance(r, bool): return str(r).lower()
    if isinstance(r, list): return "[" + ", ".join(show_result(x) for x in r) + "]"
    return fmt(r)


def apply(g, op):
    k = op[0]
    if k == "insert": return g.insert(op[1])
    if k == "edge": return g.insert_edge(op[1], op[2])
    if k == "remove": return g.remove(op[1])
    if k == "removeEdge": return g.remove_edge(op[1], op[2])
    if k == "removeAt": return g.remove_edgeAt(op[1])
    if k == "removeAllBetween": return g.removeAllEdges_between(op[1], op[2])
    if k == "removeFromWhere": return g.removeAllEdges_from_where(op[1], set(op[2]))
    if k == "removeWhere": return g.removeAllEdges_where(set(op[1]))
    if k == "insertSafe": return g.insert_safe(op[1], op[2])
    if k == "changeTarget": return g.change_target(op[1], op[2])
    if k == "changeSource": return g.change_source(op[1], op[2])
    if k == "changeTargetSafe": return g.change_target_safe(op[1], op[2])
    if k == "changeSourceSafe": return g.change_source_safe(op[1], op[2])
    if k == "churn":
        # n times: a new copy of u→v, then the oldest live edge removed.
        for _ in range(op[1]):
            g.insert_edge(op[2], op[3]); g.remove_edgeAt(min(p for p, _, _ in g.edges()))
        return None
    if k == "vertexChurn":
        # For i in start..<start+n: an edge i→i+1, then vertex i removed.
        for i in range(op[1], op[1] + op[2]):
            g.insert_edge(i, i + 1); g.remove(i)
        return None
    if k == "removeAll": g.removeAll(); return None
    if k == "removeAllEdges": g.removeAllEdges(); return None
    # queries that may trap
    if k == "successors":
        d = {q: b for q, _, b in g.edges()}
        return [d[p] for p in g.out_edges(op[1])]
    if k == "outEdges": return g.out_edges(op[1])
    if k == "inEdges": return g.in_edges(op[1])
    if k == "source":
        if isinstance(g, Port): return g.source(op[1])
        d = {q: a for q, a, _ in g.E}; need(op[1] in d, "not an edge position"); return d[op[1]]
    if k == "edgeAt":
        d = {q: (a, b) for q, a, b in g.edges()}; need(op[1] in d, "not an edge position"); return d[op[1]]
    if k == "vertexAtIndex":
        vib = g.vertexIndexBound(); need(vib is not None, "no vertex indices"); need(0 <= op[1] < vib, "index out of range")
        return g.vertices()[op[1]][0]
    if k == "vertexIndex":
        vib = g.vertexIndexBound(); need(vib is not None, "no vertex indices")
        d = dict(g.vertices()); need(op[1] in d, "not a vertex"); return d[op[1]]
    if k == "edgeIndex":
        eib = g.edgeIndexBound(); need(eib is not None, "no edge indices")
        need(op[1] in [p for p, _, _ in g.edges()], "not an edge position"); return op[1]
    if k == "vertexAt":
        d = {s: v for v, s in g.vertices()}; need(op[1] in d, "not a vertex position"); return d[op[1]]
    if k == "edgesIndicesContains": return op[1] in [p for p, _, _ in g.edges()]
    if k == "verticesIndicesContains": return op[1] in [s for _, s in g.vertices()]
    if k == "contains": return any(v == op[1] for v, _ in g.vertices())
    if k == "containsEdge": return any((a, b) == (op[1], op[2]) for _, a, b in g.edges())
    if k == "edgesFromTo": return [p for p, a, b in g.edges() if (a, b) == (op[1], op[2])]
    if k == "degrees":
        o, i = len(g.out_edges(op[1])), len(g.in_edges(op[1]))
        return [o, i, o + i]
    if k == "bfs": return bfs(g, op[1])
    if k in SAFE:
        # The safe: lookups: nil for a non-vertex, otherwise the trapping spelling's answer.
        if not any(v == op[1] for v, _ in g.vertices()): return None
        return apply(g, (SAFE[k], op[1]))
    if k == "outDegree": return len(g.out_edges(op[1]))
    if k == "inDegree": return len(g.in_edges(op[1]))
    if k == "predecessors":
        d = {q: a for q, a, _ in g.edges()}
        return [d[p] for p in g.in_edges(op[1])]
    if k == "descendants": return reach(g, op[1], forward=True)
    if k == "ancestors": return reach(g, op[1], forward=False)
    if k == "numbering": return [v for v, _ in g.vertices()]
    if k == "compact": return compact(g)
    raise ValueError(op)


SAFE = {"successorsSafe": "successors", "predecessorsSafe": "predecessors", "outEdgesSafe": "outEdges",
        "inEdgesSafe": "inEdges", "outDegreeSafe": "outDegree", "inDegreeSafe": "inDegree",
        "descendantsSafe": "descendants", "ancestorsSafe": "ancestors"}


def reach(g, s, forward):
    """Traversal's descendants / ancestors: every vertex reachable from s (or reaching it), s itself
    excluded even on a cycle, sorted for display (the result is a Set)."""
    need(any(v == s for v, _ in g.vertices()), "not a vertex")
    E = g.edges()
    seen, stack = {s}, [s]
    while stack:
        u = stack.pop()
        for _, a, b in E:
            x, y = (a, b) if forward else (b, a)
            if x == u and y not in seen:
                seen.add(y); stack.append(y)
    return sorted(seen - {s})


def predicate(chosen):
    return "{ " + lst(chosen) + ".contains($0) }" if chosen else "{ _ in false }"


def show_op(op):
    k = op[0]
    if k == "removeFromWhere": return f"removeAllEdges(from: {fmt(op[1])}, where: {predicate(op[2])})"
    if k == "removeWhere": return f"removeAllEdges(where: {predicate(op[1])})"
    if k == "insertSafe": return f"insert(safe: {fmt(op[1])}→{fmt(op[2])})"
    if k in ("changeTarget", "changeSource", "changeTargetSafe", "changeSourceSafe"):
        name = "changeTarget" if "Target" in k else "changeSource"
        return f"{name}(ofEdgeAt: {op[1]}, {'safe' if k.endswith('Safe') else 'to'}: {fmt(op[2])})"
    if k == "churn":
        return f"{op[1]} × {{ insert(edge: {fmt(op[2])}→{fmt(op[3])}); remove(edgeAt: edges.startIndex) }}"
    if k == "vertexChurn":
        return f"for i in {op[1]}..<{op[1] + op[2]} {{ insert(edge: i→i+1); remove(i) }}"
    if k in SAFE: return f"{SAFE[k]}(safe: {fmt(op[1])})"
    two = {"edge": "insert(edge: {}→{})", "removeEdge": "remove(edge: {}→{})",
           "removeAllBetween": "removeAllEdges(from: {}, to: {})", "containsEdge": "contains(edge: {}→{})",
           "edgesFromTo": "edges(from: {}, to: {})"}
    one = {"insert": "insert({})", "remove": "remove({})", "removeAt": "remove(edgeAt: {})",
           "successors": "successors(of: {})", "outEdges": "outEdges(of: {})", "inEdges": "inEdges(of: {})",
           "source": "source(ofEdgeAt: {})", "edgeAt": "edges[{}]", "vertexAtIndex": "vertex(atIndex: {})",
           "vertexIndex": "vertexIndex(of: {})", "edgeIndex": "edgeIndex(of: {})", "vertexAt": "vertices[{}]",
           "edgesIndicesContains": "edges.indices.contains({})", "verticesIndicesContains": "vertices.indices.contains({})",
           "contains": "contains({})", "degrees": "degrees({})", "bfs": "breadthFirstSearch(from: {})"}
    if k in two: return two[k].format(fmt(op[1]), fmt(op[2]))
    if k in one: return one[k].format(fmt(op[1]))
    return {"removeAll": "removeAll()", "removeAllEdges": "removeAllEdges()",
            "numbering": "vertex numbering", "compact": "DirectedPseudograph(g)"}[k]


def bfs(g, s):
    """Breadth-first order from s, successors in outEdges order: what Traversal produces."""
    by = {p: b for p, _, b in g.edges()}
    seen, order, q = {s}, [s], [s]
    need(any(v == s for v, _ in g.vertices()), "not a vertex")
    while q:
        u = q.pop(0)
        for p in g.out_edges(u):
            w = by[p]
            if w not in seen:
                seen.add(w); order.append(w); q.append(w)
    return order


def compact(g):
    """DirectedPseudograph(g): vertices in order, edge k is the kth live position."""
    return "V [" + ", ".join(fmt(v) for v, _ in g.vertices()) + "]; E [" + ", ".join(
        f"{k}:{fmt(u)}→{fmt(v)}" for k, (_, u, v) in enumerate(g.edges())) + "] (from " + "[" + ", ".join(
        str(p) for p, _, _ in g.edges()) + "])"


def run(V, E, ops):
    port, spec = Port(), Spec()
    for v in V: port.insert(v); spec.insert(v)
    for u, v in E: port.insert_edge(u, v); spec.insert_edge(u, v)
    check_laws(port); same(port, spec)
    results = []
    for op in ops:
        try:
            a = apply(port, op)
        except Trap:
            try: apply(spec, op)
            except Trap: return results, "trap", port
            raise AssertionError(f"port traps, spec does not: {op}")
        b = apply(spec, op)
        if op[0] == "compact": b = a
        assert a == b, (op, a, b)
        check_laws(port); same(port, spec)
        results.append(show_result(a) if op[0] != "compact" else a)
    return results, None, port


# ---------------------------------------------------------------------------------------------
# Codable.

def encode(g):
    V, E = g.vertices(), g.edges()
    k = {v: i for i, (v, _) in enumerate(V)}
    return {"vertices": [v for v, _ in V], "vertexPositions": [s for _, s in V], "vertexEnd": g.vertex_end(),
            "edges": [x for _, u, v in E for x in (k[u], k[v])], "edgePositions": [p for p, _, _ in E],
            "edgeEnd": g.edge_end()}


def decode(d):
    """Mirrors the proposed decoder. Returns a Port or an error string."""
    V, VP, vend = d["vertices"], d["vertexPositions"], d["vertexEnd"]
    E, EP, eend = d["edges"], d["edgePositions"], d["edgeEnd"]
    if len(V) != len(VP): return "dataCorrupted(vertexPositions): Count differs from vertices"
    if len(set(V)) != len(V): return "dataCorrupted(vertices): Repeated vertex"
    if not plausible(vend, VP[0] if VP else None, len(V)): return "dataCorrupted(vertexEnd): End leaves too many empty pages"
    if any(b <= a for a, b in zip(VP, VP[1:])) or (VP and (VP[0] < 0 or VP[-1] >= vend)) or vend < len(V):
        return "dataCorrupted(vertexPositions): Positions not increasing within vertexEnd"
    if len(E) % 2: return "dataCorrupted(edges): Edge list has odd length"
    if len(E) // 2 != len(EP): return "dataCorrupted(edgePositions): Count differs from edges"
    if any(not (0 <= x < len(V)) for x in E): return "dataCorrupted(edges): Edge endpoint out of range"
    if not plausible(eend, EP[0] if EP else None, len(EP)): return "dataCorrupted(edgeEnd): End leaves too many empty pages"
    if any(b <= a for a, b in zip(EP, EP[1:])) or (EP and (EP[0] < 0 or EP[-1] >= eend)) or eend < len(EP):
        return "dataCorrupted(edgePositions): Positions not increasing within edgeEnd"
    g = Port()
    for v, s in zip(V, VP):
        g.vend = s             # the positions before it are holes: no key, no storage
        g.insert(v)
    g.vend = vend
    for k, p in enumerate(EP):
        g.eend = p
        g.insert_edge(V[E[2 * k]], V[E[2 * k + 1]])
    g.eend = eend
    return g


PAGE = 1024


def plausible(end, first, count):
    """Decoding allocates a page table entry per page of 1024 positions from the first listed
    position (the end, with none listed) to the end: at most 16 per listed element plus 64."""
    if end < 0: return True
    span = end // PAGE - max(first if first is not None else end, 0) // PAGE + 1
    return span <= 16 * count + 64


# ---------------------------------------------------------------------------------------------
# The catalog.

ROWS = []


def case(group, title, V, E, ops=(), note=None):
    inp = f"V {lst(V)}; E [" + ", ".join(f"{fmt(u)}→{fmt(v)}" for u, v in E) + "]"
    if ops: inp += " / " + " / ".join(show_op(o) for o in ops)
    res, trap, g = run(V, E, list(ops))
    if trap:
        exp = ("; ".join(res) + "; " if res else "") + "**trap**"
    else:
        exp = ("; ".join(res) + " ⇒ " if res else "") + show_state(g)
    if note: exp += f" ({note})"
    ROWS.append((group, title, inp, exp))


def raw(group, title, inp, exp):
    ROWS.append((group, title, inp, exp))


def lst(xs): return "[" + ", ".join(map(fmt, xs)) + "]"


def define():
    C, X = "Construction", "Insertion"
    case(C, "empty", [], [])
    case(C, "isolated vertices, repeat inserted once", [0, 1, 1, 2], [])
    case(C, "endpoints in first-appearance order", [], [(2, 0), (1, 2)])
    case(C, "listed vertices first, then new endpoints", [5], [(3, 5), (5, 4)])
    case(C, "parallel copies and self-loops kept", [], [(0, 1), (0, 1), (1, 1), (1, 0)])
    case(C, "string vertices", ["a", "b"], [("a", "b"), ("b", "c")])
    case(X, "insert(_:) returns inserted and member", [0], [], [("insert", 1), ("insert", 0)])
    case(X, "insert(edge:) returns edges.endIndex", [0, 1], [(0, 1)], [("edge", 1, 0), ("edge", 0, 1)])
    case(X, "insert(edge:) inserts missing endpoints", [], [], [("edge", 7, 8), ("edge", 8, 9)])
    case(X, "self-loop: once in out-row, once in in-row", [0], [], [("edge", 0, 0), ("degrees", 0)])

    R = "Edge removal"
    case(R, "remove(edgeAt:) leaves a hole; no move", [0, 1, 2], [(0, 1), (0, 2), (1, 2)], [("removeAt", 0)])
    case(R, "middle hole keeps both neighbours' positions", [0, 1, 2], [(0, 1), (0, 2), (0, 1)], [("removeAt", 1)])
    case(R, "last position removed: end stays", [0, 1], [(0, 1), (1, 0)], [("removeAt", 1)])
    case(R, "new edge after a hole gets a fresh position", [0, 1], [(0, 1), (1, 0)], [("removeAt", 0), ("edge", 1, 1)])
    case(R, "removed position never returns", [0, 1], [(0, 1)], [("removeAt", 0), ("edge", 0, 1), ("removeAt", 1), ("edge", 0, 1)])
    case(R, "remove(edge:) removes the newest copy", [0, 1], [(0, 1), (1, 0), (0, 1)], [("removeEdge", 0, 1)])
    case(R, "remove(edge:) twice", [0, 1], [(0, 1), (0, 1), (0, 1)], [("removeEdge", 0, 1), ("removeEdge", 0, 1)])
    case(R, "remove(edge:) absent copy: nil", [0, 1], [(0, 1)], [("removeEdge", 1, 0)])
    case(R, "remove(edge:) non-vertex: nil, no insert", [0], [], [("removeEdge", 0, 9)])
    case(R, "remove(edge:) self-loop", [0], [(0, 0), (0, 0)], [("removeEdge", 0, 0)])
    case(R, "removeAllEdges(from:to:) keeps reverse copies", [0, 1], [(0, 1), (1, 0), (0, 1), (0, 0)], [("removeAllBetween", 0, 1)])
    case(R, "removeAllEdges(from:to:) none: 0", [0, 1], [(0, 1)], [("removeAllBetween", 1, 0), ("removeAllBetween", 3, 4)])
    case(R, "row order kept across removals", [0, 1, 2, 3], [(0, 1), (0, 2), (0, 3), (0, 1), (0, 2)], [("removeAt", 1), ("removeAt", 3), ("edge", 0, 3)])
    case(R, "in-row order kept across removals", [0, 1, 2, 3], [(1, 0), (2, 0), (3, 0), (1, 0)], [("removeAt", 0), ("edge", 2, 0)])
    case(R, "remove every edge one by one: bounds stay nil", [0, 1], [(0, 1), (1, 0)], [("removeAt", 0), ("removeAt", 1)])

    W = "Vertex removal"
    case(W, "isolated vertex: vertex hole", [0, 1, 2], [], [("remove", 1)])
    case(W, "vertex with edges: its edges become holes", [0, 1, 2], [(0, 1), (1, 2), (2, 0), (0, 2)], [("remove", 1)])
    case(W, "self-loops and copies at the vertex", [0, 1], [(0, 0), (0, 1), (1, 0), (0, 0), (1, 1)], [("remove", 0)])
    case(W, "absent: nil", [0], [], [("remove", 5)])
    case(W, "re-inserted vertex goes last (insertion order)", [0, 1, 2], [], [("remove", 0), ("insert", 0)])
    case(W, "re-inserted vertex gets a fresh position", [0, 1, 2], [(0, 1)], [("remove", 1), ("insert", 1), ("edge", 0, 1)])
    case(W, "insert(edge:) re-creates a removed endpoint at the end", [0, 1, 2], [(0, 1)], [("remove", 0), ("edge", 0, 2)])
    case(W, "remove all vertices: empty, ends kept", [0, 1], [(0, 1)], [("remove", 0), ("remove", 1)])
    case(W, "neighbours' rows keep order", [0, 1, 2, 3], [(0, 1), (0, 2), (0, 3), (2, 0), (3, 0)], [("remove", 2)])

    I = "Interleaving"
    case(I, "insert/remove/insert edges and vertices", [0, 1, 2], [(0, 1), (1, 2)],
         [("edge", 2, 0), ("remove", 1), ("insert", 3), ("edge", 3, 0), ("removeAt", 2), ("edge", 0, 0)])
    case(I, "churn on one pair", [0, 1], [], [("edge", 0, 1), ("edge", 0, 1), ("removeEdge", 0, 1), ("edge", 0, 1), ("removeAt", 0), ("edge", 1, 0)])
    case(I, "remove and re-add the same vertex twice", [0, 1], [(0, 1)], [("remove", 1), ("edge", 0, 1), ("remove", 1), ("edge", 1, 0)])
    case(I, "FlowNavigation: replace a screen keeps others' edge ids", ["root", "a", "b"],
         [("root", "a"), ("root", "b"), ("a", "b")], [("remove", "a"), ("edge", "root", "c"), ("edge", "c", "b"), ("outEdges", "root")])
    case(I, "removeAllEdges() resets edge positions", [0, 1], [(0, 1), (1, 0)], [("removeAt", 0), ("removeAllEdges",), ("edge", 1, 0)],
         note="the one way an edge position comes back; see open question 4")
    case(I, "removeAll() resets both", [0, 1], [(0, 1)], [("remove", 0), ("removeAll",), ("edge", 5, 6)])

    Q = "Queries"
    case(Q, "successors/outEdges/inEdges in insertion order", [0, 1, 2], [(0, 2), (0, 1), (2, 0), (0, 2)],
         [("successors", 0), ("outEdges", 0), ("inEdges", 2)])
    case(Q, "edges(from:to:) oldest first, skips holes", [0, 1], [(0, 1), (0, 1), (1, 0), (0, 1)], [("removeAt", 1), ("edgesFromTo", 0, 1)])
    case(Q, "edges(from:to:) non-vertex: empty", [0], [], [("edgesFromTo", 0, 9)])
    case(Q, "contains / contains(edge:) after removal", [0, 1], [(0, 1)], [("removeAt", 0), ("containsEdge", 0, 1), ("remove", 1), ("contains", 1), ("containsEdge", 0, 1)])
    case(Q, "degrees after removals", [0, 1, 2], [(0, 1), (1, 0), (0, 0), (2, 0)], [("removeAt", 1), ("degrees", 0)])
    case(Q, "edges.indices.contains: live, hole, past end", [0, 1], [(0, 1), (0, 1)], [("removeAt", 0), ("edgesIndicesContains", 0), ("edgesIndicesContains", 1), ("edgesIndicesContains", 2), ("edgesIndicesContains", -1)])
    case(Q, "vertices.indices.contains: live, hole", [0, 1], [], [("remove", 0), ("verticesIndicesContains", 0), ("verticesIndicesContains", 1)])
    case(Q, "vertices[p] and edges[p] at live positions", [0, 1, 2], [(0, 1), (1, 2)], [("remove", 0), ("vertexAt", 1), ("edgeAt", 1)])
    case(Q, "source(ofEdgeAt:) live", [0, 1], [(1, 0)], [("source", 0)])

    T = "Traps"
    case(T, "successors(of:) non-vertex", [0], [], [("successors", 9)])
    case(T, "outEdges(of:) removed vertex", [0, 1], [(0, 1)], [("remove", 0), ("outEdges", 0)])
    case(T, "inEdges(of:) non-vertex", [0], [], [("inEdges", 9)])
    case(T, "remove(edgeAt:) hole", [0, 1], [(0, 1), (0, 1)], [("removeAt", 0), ("removeAt", 0)])
    case(T, "remove(edgeAt:) past end", [0, 1], [(0, 1)], [("removeAt", 1)])
    case(T, "remove(edgeAt:) negative", [0, 1], [(0, 1)], [("removeAt", -1)])
    case(T, "source(ofEdgeAt:) hole", [0, 1], [(0, 1)], [("removeAt", 0), ("source", 0)])
    case(T, "edges[p] hole", [0, 1], [(0, 1), (1, 0)], [("removeAt", 0), ("edgeAt", 0)])
    case(T, "vertices[p] hole", [0, 1], [], [("remove", 0), ("vertexAt", 0)])
    case(T, "vertex(atIndex:) with vertex holes", [0, 1, 2], [], [("vertexAtIndex", 2), ("remove", 0), ("vertexAtIndex", 0)])
    case(T, "vertexIndex(of:) with vertex holes", [0, 1], [], [("vertexIndex", 1), ("remove", 0), ("vertexIndex", 1)])
    case(T, "edgeIndex(of:) with edge holes", [0, 1], [(0, 1), (1, 0)], [("edgeIndex", 1), ("removeAt", 0), ("edgeIndex", 1)])
    case("Conformance", "edge removal alone keeps vertex indices", [0, 1], [(0, 1)], [("removeAt", 0), ("vertexIndex", 1), ("edgeIndex", 0)])
    case(T, "vertex(atIndex:) past bound", [0, 1], [], [("vertexAtIndex", 2)])
    raw(T, "index(after:) at endIndex", "V [0]; E [0→0] / edges.index(after: edges.endIndex)", "**trap**")
    raw(T, "reserveCapacity negative", "V []; E [] / reserveCapacity(vertexCount: -1, edgeCount: 0)", "**trap**")

    P = "Conformance"
    case(P, "no holes: dense indices, slot = index", [0, 1, 2], [(0, 1), (2, 1)], [("vertexIndex", 2), ("vertexAtIndex", 1), ("edgeIndex", 1)])
    case(P, "vertex hole: vertexIndexBound nil, edges still indexed", [0, 1, 2], [(0, 1)], [("remove", 2)])
    case(P, "edge hole only: edgeIndexBound nil, vertices indexed", [0, 1], [(0, 1), (1, 0)], [("removeAt", 0)])
    case(P, "vertex numbering with holes: live vertices 0..<n in order", [0, 1, 2, 3], [], [("remove", 1), ("insert", 1), ("numbering",)],
         note="what _listedVertices / _VertexIdentifiers produce when vertexIndexBound is nil")
    case(P, "BFS follows outEdges order across removals", [0, 1, 2, 3], [(0, 3), (0, 1), (0, 2), (1, 2), (3, 2)], [("removeAt", 0), ("edge", 0, 3), ("bfs", 0)])
    case(P, "BFS after vertex removal", [0, 1, 2, 3], [(0, 1), (1, 2), (0, 3), (3, 2)], [("remove", 1), ("bfs", 0)])
    case(P, "compacting conversion to DirectedPseudograph", [0, 1, 2], [(0, 1), (1, 2), (2, 0), (0, 2)], [("remove", 1), ("edge", 2, 2), ("compact",)])
    case(P, "compacting conversion without holes is positional", [0, 1], [(0, 1), (1, 1)], [("compact",)])
    raw(P, "init(_:) from DirectedPseudograph", "StableDirectedGraph(DirectedPseudograph(V [2, 0]; E [2→0, 0→0, 2→0]))",
        show_state(_built([2, 0], [(2, 0), (0, 0), (2, 0)])))
    raw(P, "init(_:) from a StableDirectedGraph keeps holes", "StableDirectedGraph(g) where g = V [0, 1]; E [0→1, 1→0] / remove(edgeAt: 0)",
        show_state(_after([0, 1], [(0, 1), (1, 0)], [("removeAt", 0)])))
    raw(P, "undirected view keeps positions and nil bounds", "(V [0, 1, 2]; E [0→1, 1→2] / remove(edgeAt: 0)).undirected",
        "edges [1:1–2]; incidentEdges(of: 1) [1]; incidentEdges(of: 0) []; vertexIndexBound 3; edgeIndexBound nil")
    raw(P, "algorithms on a holed graph match the compacted copy", "for each of stronglyConnectedComponents, topologicalSort, shortestPaths (weights by position): on g and on DirectedPseudograph(g)",
        "equal results, edge positions mapped through the conversion's position list")

    Q2 = "Equality and hashing"
    raw(Q2, "positions do not matter", "V [0, 1]; E [0→1, 0→1] / remove(edgeAt: 0)  ==  V [0, 1]; E [0→1]", "true; equal hashes")
    raw(Q2, "vertex holes do not matter", "V [9, 0]; E [] / remove(9) / insert(1)  ==  V [0, 1]; E []", "true")
    raw(Q2, "copies count", "V [0, 1]; E [0→1, 0→1]  ==  V [0, 1]; E [0→1]", "false")
    raw(Q2, "orientation counts", "V [0, 1]; E [0→1]  ==  V [0, 1]; E [1→0]", "false")

    K = "Codable"
    g = _after([0, 1, 2], [(0, 1), (1, 2), (2, 0), (0, 0)], [("remove", 1), ("insert", 3)])
    raw(K, "encode keeps positions and ends", "V [0, 1, 2]; E [0→1, 1→2, 2→0, 0→0] / remove(1) / insert(3)", json.dumps(encode(g), separators=(",", ":")))
    raw(K, "round trip keeps the next fresh positions", "decode(encode(g)) for the graph above / insert(4) / insert(edge: 4→0)",
        (_roundtrip_then(g, [("insert", 4), ("edge", 4, 0)])))
    e = _after([], [], [])
    raw(K, "empty", "V []; E []", json.dumps(encode(e), separators=(",", ":")))
    h = _after([0], [(0, 0), (0, 0)], [("removeAt", 0), ("removeAt", 1), ("remove", 0)])
    raw(K, "all holes round trip", "V [0]; E [0→0, 0→0] / remove(edgeAt: 0) / remove(edgeAt: 1) / remove(0)",
        json.dumps(encode(h), separators=(",", ":")) + " ⇒ " + (_roundtrip_then(h, [])))
    for title, d in [
        ("odd edge list", {"vertices": [0, 1], "vertexPositions": [0, 1], "vertexEnd": 2, "edges": [0], "edgePositions": [0], "edgeEnd": 1}),
        ("repeated vertex", {"vertices": [0, 0], "vertexPositions": [0, 1], "vertexEnd": 2, "edges": [], "edgePositions": [], "edgeEnd": 0}),
        ("vertex positions count", {"vertices": [0, 1], "vertexPositions": [0], "vertexEnd": 2, "edges": [], "edgePositions": [], "edgeEnd": 0}),
        ("vertex positions not increasing", {"vertices": [0, 1], "vertexPositions": [1, 0], "vertexEnd": 2, "edges": [], "edgePositions": [], "edgeEnd": 0}),
        ("vertex position past end", {"vertices": [0], "vertexPositions": [3], "vertexEnd": 3, "edges": [], "edgePositions": [], "edgeEnd": 0}),
        ("edge endpoint out of range", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 1, "edges": [0, 1], "edgePositions": [0], "edgeEnd": 1}),
        ("edge positions count", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 1, "edges": [0, 0], "edgePositions": [], "edgeEnd": 1}),
        ("edge positions repeated", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 1, "edges": [0, 0, 0, 0], "edgePositions": [1, 1], "edgeEnd": 2}),
        ("edge position past end", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 1, "edges": [0, 0], "edgePositions": [2], "edgeEnd": 2}),
    ]:
        raw(K, title, json.dumps(d, separators=(",", ":")), str(decode(d)))

    D = "Description"
    raw(D, "description lists live vertices and edges", "V [0, 1, 2]; E [0→1, 1→2] / remove(edgeAt: 0)", "[0, 1, 2]; [1→2]")
    raw(D, "debugDescription", "V [0, 1]; E [0→1] / remove(0)",
        "StableDirectedGraph<Int>(vertexCount: 1, edgeCount: 0, vertices: [1], edges: [])")
    define_flow_navigation()


def define_flow_navigation():
    """The FlowNavigation additions and the review fixes, after the phase-1 rows (SG-097 on)."""
    R = "Edge removal"
    case(R, "removeAllEdges(from:where:) sees only the vertex's out-row, oldest first", [0, 1, 2],
         [(0, 1), (0, 2), (1, 2), (0, 1), (0, 0)], [("removeFromWhere", 0, [0, 2, 3, 4]), ("removeAt", 1), ("edge", 0, 2)])
    case(R, "removeAllEdges(from:where:) non-vertex or nothing chosen: 0", [0, 1], [(0, 1)],
         [("removeFromWhere", 9, [0]), ("removeFromWhere", 0, [])])
    case(R, "removeAllEdges(from:where:) self-loops and in-edges", [0, 1], [(1, 0), (0, 0), (0, 1), (0, 0)],
         [("removeFromWhere", 0, [1, 2]), ("removeAt", 3), ("edge", 0, 0)])
    case(R, "removeAllEdges(from:to:) one pass over the shorter row", [0, 1, 2], [(0, 1), (0, 2), (0, 2), (2, 1), (0, 1), (0, 2)],
         [("removeAllBetween", 0, 1), ("removeAt", 3), ("edge", 2, 1)])
    case(R, "removeAllEdges(where:) over every edge", [0, 1, 2], [(0, 1), (1, 2), (2, 0), (0, 2), (1, 1)],
         [("removeWhere", [1, 3, 4]), ("edge", 1, 1)])
    case(R, "removeAllEdges(where:) with a vertex hole", [0, 1, 2], [(0, 1), (1, 2), (2, 0), (0, 2)],
         [("remove", 1), ("removeWhere", []), ("removeWhere", [3])])

    X = "Insertion"
    case(X, "insert(safe:) with both endpoints: the new position", [0, 1], [(0, 1)], [("insertSafe", 1, 0), ("insertSafe", 1, 1)])
    case(X, "insert(safe:) with a missing endpoint: nil, nothing changes", [0, 1], [(0, 0)],
         [("insertSafe", 0, 9), ("insertSafe", 9, 0), ("insertSafe", 9, 9), ("remove", 1), ("insertSafe", 0, 1)])

    Q = "Queries"
    case(Q, "safe: lookups on a vertex", [0, 1, 2], [(0, 1), (2, 0), (0, 0)],
         [("successorsSafe", 0), ("predecessorsSafe", 0), ("outEdgesSafe", 0), ("inEdgesSafe", 0), ("outDegreeSafe", 0), ("inDegreeSafe", 0)])
    case(Q, "safe: lookups on a removed vertex or a non-vertex: nil", [0, 1], [(0, 1)],
         [("remove", 1), ("successorsSafe", 1), ("predecessorsSafe", 1), ("outEdgesSafe", 9), ("inEdgesSafe", 1),
          ("outDegreeSafe", 1), ("inDegreeSafe", 9)])
    case(Q, "descendants(safe:) and ancestors(safe:)", [0, 1, 2, 3], [(0, 1), (1, 2), (2, 0), (2, 3)],
         [("descendantsSafe", 1), ("ancestorsSafe", 3), ("remove", 0), ("descendantsSafe", 1), ("descendantsSafe", 0), ("ancestorsSafe", 9)])

    K = "Codable"
    for title, d in [
        ("vertexEnd far past the payload: no vertex, so one page", {"vertices": [], "vertexPositions": [], "vertexEnd": 4611686018427387903, "edges": [], "edgePositions": [], "edgeEnd": 0}),
        ("edgeEnd at Int.max with no edge: one page", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 1, "edges": [], "edgePositions": [], "edgeEnd": 9223372036854775807}),
        ("vertexEnd 65554 with one vertex: 65 pages, within the bound", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 65554, "edges": [], "edgePositions": [], "edgeEnd": 0}),
        ("edgeEnd 65554 with one edge: 65 pages, within the bound", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 1, "edges": [0, 0], "edgePositions": [0], "edgeEnd": 65554}),
        ("ends at 65553 decode", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 65553, "edges": [0, 0], "edgePositions": [0], "edgeEnd": 65553}),
    ]:
        decoded_row(K, title, d)
    define_paging()


DECODED = {}


def decoded_row(group, title, d):
    """A payload that decodes: the state, checked against the laws."""
    g = decode(d)
    assert isinstance(g, Port), (title, g)
    check_laws(g)
    DECODED[len(ROWS) + 1] = d
    raw(group, title, json.dumps(d, separators=(",", ":")), show_state(g))


def define_paging():
    """Paged storage (SG-113 on): the page-span bound on decoding, churn across freed pages,
    re-pointing an edge, and VertexMap / EdgeMap."""
    K = "Codable"
    for title, d in [
        ("vertex page span one past 16 × count + 64", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 81920, "edges": [], "edgePositions": [], "edgeEnd": 0}),
        ("edge page span one past 16 × count + 64", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 1, "edges": [0, 0], "edgePositions": [0], "edgeEnd": 81920}),
    ]:
        raw(K, title, json.dumps(d, separators=(",", ":")), str(decode(d)))
    decoded_row(K, "page spans at the bound decode", {"vertices": [0], "vertexPositions": [0], "vertexEnd": 81919, "edges": [0, 0], "edgePositions": [0], "edgeEnd": 81919})
    decoded_row(K, "elements far along: the pages before them cost nothing",
                {"vertices": [7, 8], "vertexPositions": [4611686018427387000, 4611686018427387001], "vertexEnd": 4611686018427387904,
                 "edges": [0, 1], "edgePositions": [9223372036854775000], "edgeEnd": 9223372036854775001})

    G = "Paging"
    case(G, "edge churn across freed pages keeps every live position", [0, 1], [(0, 1)],
         [("churn", 2500, 0, 1), ("edgesIndicesContains", 0), ("edgesIndicesContains", 1500), ("edgesIndicesContains", 2500),
          ("edge", 1, 0), ("removeAt", 2500)])
    case(G, "vertex churn across freed pages", [0], [],
         [("vertexChurn", 0, 2500), ("verticesIndicesContains", 0), ("verticesIndicesContains", 2500), ("contains", 7), ("edge", 2500, 0)])
    case(G, "source(ofEdgeAt:) at a position in a freed page traps", [0, 1], [(0, 1)], [("churn", 2500, 0, 1), ("source", 5)])
    case(G, "vertices[p] at a position in a freed page traps", [0], [], [("vertexChurn", 0, 2100), ("vertexAt", 3)])
    case(G, "removeAll() after churn resets both ends", [0, 1], [(0, 1)], [("churn", 2100, 0, 1), ("vertexChurn", 2, 1100), ("removeAll",), ("edge", 3, 4)])
    case(G, "algorithms after churn see the live vertices only", [0], [],
         [("vertexChurn", 0, 2100), ("edge", 2100, 2102), ("edge", 2102, 2101), ("edge", 2101, 2100), ("bfs", 2100), ("descendantsSafe", 2102)])

    C = "Edge change"
    case(C, "changeTarget keeps the position and the place in the source's row", [0, 1, 2], [(0, 1), (0, 2), (0, 1), (2, 1)],
         [("changeTarget", 0, 2), ("outEdges", 0), ("inEdges", 2), ("inEdges", 1)])
    case(C, "changeSource joins the new source's row in position order", [0, 1, 2], [(0, 2), (1, 2), (1, 0), (0, 1)],
         [("changeSource", 1, 0), ("outEdges", 0), ("outEdges", 1), ("inEdges", 2)])
    case(C, "self-loops before and after; the same endpoint changes nothing", [0, 1], [(0, 0), (0, 1), (1, 1)],
         [("changeTarget", 0, 1), ("changeTarget", 1, 0), ("changeTarget", 1, 0), ("changeSource", 2, 0), ("changeSource", 0, 1)])
    case(C, "back and forth: the edge returns to its old place", [0, 1, 2], [(0, 1), (2, 1), (0, 1), (0, 2)],
         [("changeTarget", 0, 2), ("changeTarget", 0, 1), ("changeSource", 1, 0), ("changeSource", 1, 2), ("inEdges", 1)])
    case(C, "changes after removals and with copies", [0, 1, 2], [(0, 1), (0, 1), (1, 2), (0, 1), (2, 0)],
         [("removeAt", 1), ("changeTarget", 3, 2), ("remove", 1), ("edge", 2, 2), ("changeSource", 3, 2), ("removeEdge", 2, 2)])
    case(C, "changeTarget(ofEdgeAt:to:) to a non-vertex traps", [0, 1], [(0, 1)], [("changeTarget", 0, 1), ("changeTarget", 0, 9)])
    case(C, "changeSource(ofEdgeAt:to:) at a hole traps", [0, 1], [(0, 1), (1, 0)], [("removeAt", 0), ("changeSource", 0, 1)])
    case(C, "safe: variants return false and change nothing", [0, 1, 2], [(0, 1), (1, 2)],
         [("removeAt", 0), ("changeTargetSafe", 0, 2), ("changeTargetSafe", 1, 9), ("changeSourceSafe", 5, 0), ("changeSourceSafe", -1, 0),
          ("changeTargetSafe", 1, 0), ("changeSourceSafe", 1, 0)])

    M = "Maps"
    map_case(M, "attached EdgeMap: set, get, nil removes; removing the edge clears its value", [0, 1, 2], [(0, 1), (1, 2), (2, 0)],
             [("addEdgeMap", "labels", "String"), ("eset", "labels", 0, "a"), ("eset", "labels", 1, "b"), ("eset", "labels", 2, "c"),
              ("eget", "labels", 1), ("eset", "labels", 2, None), ("eget", "labels", 2), ("removeAt", 1), ("eget", "labels", 1),
              ("edge", 0, 2), ("eget", "labels", 3), ("evalues", "labels")])
    map_case(M, "every edge removal path clears the attached maps", [0, 1, 2, 3],
             [(0, 1), (0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (1, 1), (2, 2)],
             [("addEdgeMap", "w", "Int")] + [("eset", "w", p, p * 10) for p in range(8)] +
             [("removeEdge", 0, 1), ("evalues", "w"), ("removeAllBetween", 2, 3), ("removeFromWhere", 0, [5]),
              ("removeWhere", [6]), ("remove", 3), ("evalues", "w"), ("removeAllEdges",), ("edge", 1, 2), ("eget", "w", 0),
              ("evalues", "w")])
    map_case(M, "attached VertexMap: by position and by vertex; removal and churn clear", [0, 1], [],
             [("addVertexMap", "names", "String"), ("vsetOf", "names", 0, "zero"), ("vset", "names", 1, "one"), ("vgetOf", "names", 1),
              ("vget", "names", 0), ("vgetOf", "names", 9), ("vertexChurn", 1, 2000), ("vsetOf", "names", 2001, "last"),
              ("vvalues", "names"), ("remove", 0), ("vvalues", "names"), ("removeAll",), ("edge", 5, 6), ("vget", "names", 0),
              ("vvalues", "names")])
    map_case(M, "several maps, copy-on-write, changeTarget keeps values, removeEdgeMap", [0, 1, 2], [(0, 1), (1, 2)],
             [("addEdgeMap", "a", "Int"), ("addEdgeMap", "b", "String"), ("eset", "a", 0, 1), ("eset", "b", 0, "x"), ("eset", "a", 1, 2),
              ("snapshot",), ("changeTarget", 0, 2), ("eget", "a", 0), ("removeAt", 1), ("eset", "b", 0, "y"), ("evalues", "a"),
              ("evalues", "b"), ("snapshotValues", "a"), ("snapshotValues", "b"), ("removeMap", "a"), ("evalues", "b")])


MAPS = {}
MAP_OPS = {"addEdgeMap", "addVertexMap", "eset", "eget", "vset", "vget", "vsetOf", "vgetOf", "evalues", "vvalues",
           "snapshot", "snapshotValues", "removeMap"}


class MapModel:
    """Attached maps as the graph keeps them: a dict per map, every removed element's entry
    cleared in the same call, both kinds emptied by removeAll and edge maps by removeAllEdges."""

    def __init__(self):
        self.kind, self.values = {}, {}

    def settle(self, g, op):
        live_e = {p for p, _, _ in g.edges()}
        live_v = {s for _, s in g.vertices()}
        for name, kind in self.kind.items():
            if op[0] == "removeAll" or (op[0] == "removeAllEdges" and kind == "Edge"):
                self.values[name] = {}
            live = live_e if kind == "Edge" else live_v
            self.values[name] = {p: x for p, x in self.values[name].items() if p in live}

    def copy(self):
        c = MapModel()
        c.kind = dict(self.kind)
        c.values = {k: dict(v) for k, v in self.values.items()}
        return c


def map_step(g, maps, snap, op):
    """One map call: (shown result or None, new snapshot)."""
    k = op[0]
    if k in ("addEdgeMap", "addVertexMap"):
        maps.kind[op[1]] = "Edge" if k == "addEdgeMap" else "Vertex"
        maps.values[op[1]] = {}
        return None, snap
    if k == "removeMap":
        del maps.kind[op[1]], maps.values[op[1]]
        return None, snap
    if k in ("eset", "vset"):
        live = {p for p, _, _ in g.edges()} if k == "eset" else {s for _, s in g.vertices()}
        if op[3] is None: maps.values[op[1]].pop(op[2], None)
        else:
            need(op[2] in live, "no element to hold a value"); maps.values[op[1]][op[2]] = op[3]
        return None, snap
    if k == "vsetOf":
        d = dict(g.vertices()); need(op[2] in d, "not a vertex")
        maps.values[op[1]][d[op[2]]] = op[3]
        return None, snap
    if k in ("eget", "vget"):
        r = maps.values[op[1]].get(op[2])
        return ("nil" if r is None else fmt(r)), snap
    if k == "vgetOf":
        d = dict(g.vertices())
        r = maps.values[op[1]].get(d[op[2]]) if op[2] in d else None
        return ("nil" if r is None else fmt(r)), snap
    if k in ("evalues", "vvalues"): return show_map(maps.values[op[1]]), snap
    if k == "snapshot": return None, (snapshot(g), maps.copy())
    if k == "snapshotValues": return show_map(snap[1].values[op[1]]), snap
    raise ValueError(op)


def map_run(V, E, ops):
    port, spec = Port(), Spec()
    for v in V: port.insert(v); spec.insert(v)
    for u, v in E: port.insert_edge(u, v); spec.insert_edge(u, v)
    maps, snap, res = MapModel(), None, []
    for op in ops:
        if op[0] in MAP_OPS:
            r, snap = map_step(port, maps, snap, op)
            if r is not None: res.append(r)
            continue
        a = apply(port, op); b = apply(spec, op)
        assert a == b, (op, a, b)
        check_laws(port); same(port, spec)
        maps.settle(port, op)
        res.append(show_result(a))
    return res, port, maps


def show_map(m):
    return "[" + ", ".join(f"{p}: {fmt(x)}" for p, x in sorted(m.items())) + "]"


def show_map_op(op):
    k = op[0]
    if k in ("addEdgeMap", "addVertexMap"): return f"let {op[1]} = {k}(of: {op[2]}.self)"
    if k == "removeMap": return f"remove{'Edge'}Map({op[1]})"
    if k in ("eset", "vset"):
        return f"[map: {op[1]}, of{'Edge' if k == 'eset' else 'Vertex'}At: {op[2]}] = {'nil' if op[3] is None else fmt(op[3])}"
    if k == "vsetOf": return f"[map: {op[1]}, of: {fmt(op[2])}] = {fmt(op[3])}"
    if k in ("eget", "vget"): return f"[map: {op[1]}, of{'Edge' if k == 'eget' else 'Vertex'}At: {op[2]}]"
    if k == "vgetOf": return f"[map: {op[1]}, of: {fmt(op[2])}]"
    if k in ("evalues", "vvalues"): return f"values of {op[1]}"
    if k == "snapshot": return "let copy = graph"
    if k == "snapshotValues": return f"values of {op[1]} in copy"
    return show_op(op)


def map_case(group, title, V, E, ops):
    res, port, _ = map_run(V, E, ops)
    inp = f"V {lst(V)}; E [" + ", ".join(f"{fmt(u)}→{fmt(v)}" for u, v in E) + "] / " + " / ".join(show_map_op(o) for o in ops)
    MAPS[len(ROWS) + 1] = (V, E, ops)
    raw(group, title, inp, "; ".join(res) + " ⇒ " + show_state(port))


def _built(V, E):
    return run(V, E, [])[2]


def _after(V, E, ops):
    return run(V, E, ops)[2]


def _roundtrip_then(g, ops):
    h = decode(encode(g))
    assert isinstance(h, Port) and snapshot(h) == snapshot(g), "round trip"
    for op in ops: apply(h, op)
    check_laws(h)
    return show_state(h)


def render():
    out = ["# StableGraphs: case catalog (phase 1)", "",
           "Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1",
           "python3 Tests/Catalogs/StableGraphs/ref.py`; `--write` regenerates this file, `--stress` adds the random",
           "sequences). Every Expected is the output of a port of the proposed storage, checked at every state",
           "against a plain specification model and the DirectedGraph / BidirectionalDirectedGraph laws.",
           "",
           "Conventions:",
           "",
           "* Input `V [...]; E [...]` is `StableDirectedGraph(vertices: V, edges: E)`; calls follow, separated by `/`.",
           "  Expected lists each call's result, then `⇒` and the final state.",
           "* State: `V [v#k, …] end n` is `vertices` with each vertex's position `k` (its index in",
           "  `vertices`), and `n` is `vertices.endIndex`; `E [p:u→v, …] end m` is `edges` with positions and",
           "  `edges.endIndex`; `bounds a/b` is `vertexIndexBound` / `edgeIndexBound`; `out` / `in` are",
           "  `successors` / `predecessors` zipped with `outEdges` / `inEdges` (`w@p`), empty rows omitted.",
           "* Positions are never reused: a new vertex or edge always gets the current `endIndex`, so every",
           "  order (vertices, edges, each out- and in-row) is position order, which is insertion order.",
           "  Only `removeAll()` and `removeAllEdges()` reset an `endIndex`.",
           "* `degrees(v)` is `outDegree`, `inDegree`, `degree`.",
           "* `**trap**` rows are preconditions, run as exit tests (`#expect(processExitsWith:)`); results before",
           "  the trap are listed.",
           "* Codable payloads are `{vertices, vertexPositions, vertexEnd, edges, edgePositions, edgeEnd}`;",
           "  `edges` are index pairs into `vertices`. Errors are `DecodingError` cases with their debug description.",
           "",
           "| ID | Group | Case | Input / call | Expected |", "|---|---|---|---|---|"]
    for i, (g, t, inp, exp) in enumerate(ROWS, 1):
        cell = lambda s: s.replace("|", "\\|")
        out.append(f"| SG-{i:03d} | {g} | {cell(t)} | {cell(inp)} | {cell(exp)} |")
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------------------------------------
# Stress: random sequences against both models, rustworkx and NetworkX.

def stress(seeds=300, steps=60):
    import random
    import networkx as nx
    import rustworkx as rx
    reused = diverged = 0
    for seed in range(seeds):
        rng = random.Random(seed)
        port, spec = Port(), Spec()
        rg = rx.PyDiGraph(multigraph=True)
        ng = nx.MultiDiGraph()
        rnode = {}          # vertex -> rustworkx node index
        redge = {}          # our position -> rustworkx edge index
        nkey = {}           # our position -> NetworkX key
        r_used_nodes, r_used_edges = set(), set()
        r_free_nodes, r_free_edges = set(), set()
        ours_seen = set()
        pool = range(8)

        def r_add_node(v):
            i = rg.add_node(v)
            assert i in r_free_nodes or i not in r_used_nodes, "rustworkx hands out a vacated or fresh index"
            nonlocal reused
            if i in r_used_nodes: reused += 1
            r_used_nodes.add(i); r_free_nodes.discard(i); rnode[v] = i

        for _ in range(steps):
            k = rng.random()
            u, v = rng.choice(pool), rng.choice(pool)
            if k < 0.15:
                op = ("insert", u)
            elif k < 0.55:
                op = ("edge", u, v)
            elif k < 0.65:
                op = ("remove", u)
            elif k < 0.8:
                op = ("removeEdge", u, v)
            elif k < 0.95 and port.ecount:
                op = ("removeAt", rng.choice([p for p, _, _ in port.edges()]))
            else:
                op = ("removeAllBetween", u, v)
            before = {p: (a, b) for p, a, b in port.edges()}
            a = apply(port, op); b = apply(spec, op)
            assert a == b, (seed, op, a, b)
            check_laws(port); same(port, spec)
            # shadows
            if op[0] == "insert" and a[0]:
                r_add_node(u); ng.add_node(u)
            elif op[0] == "edge":
                for w in (u, v):
                    if w not in rnode: r_add_node(w)
                e = rg.add_edge(rnode[u], rnode[v], a)
                if e in r_used_edges: reused += 1
                r_used_edges.add(e); r_free_edges.discard(e); redge[a] = e
                nkey[a] = ng.add_edge(u, v)
                assert a not in ours_seen and a == port.edge_end() - 1, "our position is fresh"
                ours_seen.add(a)
            elif op[0] == "remove" and a is not None:
                for p in before:
                    if u in before[p]:
                        r_free_edges.add(redge.pop(p)); nkey.pop(p)
                rg.remove_node(rnode[u]); r_free_nodes.add(rnode.pop(u)); ng.remove_node(u)
            elif op[0] in ("removeEdge", "removeAt", "removeAllBetween"):
                gone = set(before) - {p for p, _, _ in port.edges()}
                for p in gone:
                    rg.remove_edge_from_index(redge[p]); r_free_edges.add(redge.pop(p))
                    x, y = before[p]; ng.remove_edge(x, y, key=nkey.pop(p))
            # compare
            live = [w for w, _ in port.vertices()]
            assert sorted(rg.nodes()) == sorted(live) and set(ng.nodes) == set(live)
            assert Counter((x, y) for _, x, y in port.edges()) == Counter((rg[s], rg[t]) for s, t in rg.edge_list())
            assert Counter((x, y) for _, x, y in port.edges()) == Counter((x, y) for x, y, _ in ng.edges(keys=True))
            for w in live:
                outs = port.out_edges(w)
                # petgraph lists a vertex's edges newest first; ours are oldest first.
                assert list(reversed([p for _, _, p in rg.out_edges(rnode[w])])) == outs
                assert list(reversed([p for _, _, p in rg.in_edges(rnode[w])])) == port.in_edges(w)
                assert rg.out_degree(rnode[w]) == len(outs) == ng.out_degree(w)
                assert rg.in_degree(rnode[w]) == len(port.in_edges(w)) == ng.in_degree(w)
            if [rg[i] for i in rg.node_indices()] != live:
                diverged += 1
    return reused, diverged


def bench():
    import time
    import rustworkx as rx
    n, m = 10 ** 5, 5 * 10 ** 5
    x, pairs = 1, []
    for _ in range(m):
        x = (x * 6364136223846793005 + 1442695040888963407) % 2 ** 64; a = (x >> 33) % n
        x = (x * 6364136223846793005 + 1442695040888963407) % 2 ** 64; b = (x >> 33) % n
        pairs.append((a, b))

    def build():
        g = rx.PyDiGraph(multigraph=True); g.add_nodes_from(range(n)); g.add_edges_from_no_data(pairs); return g

    def best(f, k=3):
        r = []
        for _ in range(k):
            t = time.perf_counter(); f(); r.append(time.perf_counter() - t)
        return min(r) * 1e3

    def timed_after_build(f):
        r = []
        for _ in range(3):
            g = build(); t = time.perf_counter(); f(g); r.append(time.perf_counter() - t)
        return min(r) * 1e3

    g = build()
    print(f"build (add_nodes_from + add_edges_from_no_data)  {best(build):7.1f} ms")
    print(f"remove 10% of vertices (remove_nodes_from)        {timed_after_build(lambda g: g.remove_nodes_from(list(range(0, n, 10)))):7.1f} ms")
    print(f"remove every other edge by index (Python loop)    {timed_after_build(lambda g: [g.remove_edge_from_index(i) for i in range(0, m, 2)]):7.1f} ms")
    print(f"weakly connected components                        {best(lambda: rx.number_weakly_connected_components(g)):7.1f} ms")
    print(f"strongly connected components                      {best(lambda: rx.strongly_connected_components(g)):7.1f} ms")
    g.remove_nodes_from(list(range(0, n, 10)))
    print(f"weakly connected components, 10% vertex holes      {best(lambda: rx.number_weakly_connected_components(g)):7.1f} ms")


def main():
    define()
    text = render()
    path = os.path.join(HERE, "cases.md")
    if "--write" in sys.argv:
        open(path, "w").write(text)
        print(f"wrote {len(ROWS)} rows")
    else:
        if not os.path.exists(path) or open(path).read() != text:
            print("cases.md differs from the model (run with --write)"); sys.exit(1)
        print(f"cases.md matches the model: {len(ROWS)} rows")
    if "--stress" in sys.argv:
        reused, diverged = stress()
        print(f"stress: 300 sequences x 60 steps agree with the spec, the laws, rustworkx and NetworkX; "
              f"rustworkx reused a vacated index {reused} times, and its node_indices order left insertion order "
              f"in {diverged} states (ours never reuses)")
    if "--bench" in sys.argv:
        bench()


if __name__ == "__main__":
    main()
