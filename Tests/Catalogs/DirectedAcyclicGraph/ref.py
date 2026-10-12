"""Reference model for DirectedAcyclicGraphModule's DirectedAcyclicGraph<Base> (see api.md).

    uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1 python3 Tests/Catalogs/DirectedAcyclicGraph/ref.py
        checks cases.md against the model
    ... ref.py --write    regenerates cases.md
    ... ref.py --stress   also runs the random operation sequences (NetworkX spec, rustworkx shadow)
                          and the Pearce-Kelly / Marchetti-Spaccamela work counts

`SwapBase` ports the storage of AdjacencyList (simple) and DirectedPseudograph (copies): dense
slots and edge positions with swap-remove, rows that swap-remove their entries. `StableBase` ports
StableDirectedGraph: positions never reused, rows in position order. `DAG` is a port of the
proposed wrapper: the order kept as a list of base keys (slot, or position on the stable base) and
each key's place in it, maintained by Pearce-Kelly (PK). `Spec` is written from the definitions
with NetworkX: an edge is rejected exactly when it is a self-loop or its target reaches its
source, and after an accepted backward edge the affected sets are NetworkX descendants and
ancestors filtered by the old order, placed as PK places them. Every state is checked port == spec,
plus: the order is a permutation of the vertices with every edge going forward, every witness is a
path of the graph from the edge's target to its source, and (in --stress) a rustworkx
PyDiGraph(check_cycle=True) accepts and rejects the same edges.
"""
import copy
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


class Trap(Exception):
    pass


def need(cond, msg):
    if not cond:
        raise Trap(msg)


# ---------------------------------------------------------------------------------------------
# Bases.

class SwapBase:
    """AdjacencyList (simple=True) or DirectedPseudograph (simple=False)."""

    def __init__(self, simple):
        self.simple = simple
        self.V, self.slot, self.rec, self.out, self.inn = [], {}, [], [], []
        self.stamp = 0

    kind = property(lambda self: "AdjacencyList" if self.simple else "DirectedPseudograph")

    def key(self, v): return self.slot.get(v)
    def vertex(self, k): return self.V[k]
    def keys(self): return list(range(len(self.V)))
    def has_key(self, k): return 0 <= k < len(self.V)
    def vcount(self): return len(self.V)

    def add_vertex(self, v):
        self.slot[v] = len(self.V); self.V.append(v); self.out.append([]); self.inn.append([])
        return self.slot[v]

    def copies(self, ks, kt):
        return sorted((r[2], p) for p, r in enumerate(self.rec) if r[0] == ks and r[1] == kt)

    def add_edge(self, ks, kt):
        if self.simple:
            c = self.copies(ks, kt)
            if c: return c[0][1], False
        p = len(self.rec)
        self.rec.append([ks, kt, self.stamp]); self.stamp += 1
        self.out[ks].append(p); self.inn[kt].append(p)
        return p, True

    def is_edge(self, p): return 0 <= p < len(self.rec)

    def _swap_remove(self, row, p):
        i = row.index(p); row[i] = row[-1]; row.pop()

    def remove_edge_at(self, p):
        s, t, _ = self.rec[p]
        self._swap_remove(self.out[s], p); self._swap_remove(self.inn[t], p)
        last = len(self.rec) - 1
        if p != last:
            self.rec[p] = self.rec[last]
            ms, mt, _ = self.rec[p]
            self.out[ms][self.out[ms].index(last)] = p
            self.inn[mt][self.inn[mt].index(last)] = p
        self.rec.pop()
        return s, t

    def newest_copy(self, ks, kt):
        c = self.copies(ks, kt)
        return c[-1][1] if c else None

    def remove_vertex(self, k):
        while self.out[k]: self.remove_edge_at(self.out[k][-1])
        while self.inn[k]: self.remove_edge_at(self.inn[k][-1])
        last, moved = len(self.V) - 1, None
        removed = self.V[k]
        if k != last:
            for p in self.out[last]: self.rec[p][0] = k
            for p in self.inn[last]: self.rec[p][1] = k
            self.V[k] = self.V[last]; self.slot[self.V[k]] = k
            self.out[k], self.inn[k] = self.out[last], self.inn[last]
            moved = (last, k)
        self.V.pop(); self.out.pop(); self.inn.pop(); del self.slot[removed]
        return moved

    def out_row(self, k): return [(self.rec[p][1], p) for p in self.out[k]]
    def in_row(self, k): return [(self.rec[p][0], p) for p in self.inn[k]]
    def edges(self): return [(p, r[0], r[1]) for p, r in enumerate(self.rec)]

    def remove_all(self): self.__init__(self.simple)

    def remove_all_edges(self):
        self.rec = []; self.out = [[] for _ in self.V]; self.inn = [[] for _ in self.V]

    def fresh(self): return SwapBase(self.simple)


class StableBase:
    """StableDirectedGraph: positions never reused; rows in position order."""
    kind = "StableDirectedGraph"
    simple = False

    def __init__(self):
        self.V, self.slot, self.vend = {}, {}, 0
        self.rec, self.eend = {}, 0
        self.out, self.inn = {}, {}

    def key(self, v): return self.slot.get(v)
    def vertex(self, k): return self.V[k]
    def keys(self): return sorted(self.V)
    def has_key(self, k): return k in self.V
    def vcount(self): return len(self.V)

    def add_vertex(self, v):
        k = self.vend; self.vend += 1
        self.V[k] = v; self.slot[v] = k; self.out[k] = []; self.inn[k] = []
        return k

    def add_edge(self, ks, kt):
        p = self.eend; self.eend += 1
        self.rec[p] = (ks, kt); self.out[ks].append(p); self.inn[kt].append(p)
        return p, True

    def is_edge(self, p): return p in self.rec

    def remove_edge_at(self, p):
        s, t = self.rec.pop(p)
        self.out[s].remove(p); self.inn[t].remove(p)
        return s, t

    def newest_copy(self, ks, kt):
        c = [p for p in self.out[ks] if self.rec[p][1] == kt]
        return c[-1] if c else None

    def remove_vertex(self, k):
        for p in list(self.out[k]) + list(self.inn[k]):
            if p in self.rec: self.remove_edge_at(p)
        v = self.V.pop(k); del self.slot[v]; del self.out[k]; del self.inn[k]
        return None

    def out_row(self, k): return [(self.rec[p][1], p) for p in self.out[k]]
    def in_row(self, k): return [(self.rec[p][0], p) for p in self.inn[k]]
    def edges(self): return [(p, s, t) for p, (s, t) in sorted(self.rec.items())]

    def remove_all(self): self.__init__()

    def remove_all_edges(self):
        self.rec, self.eend = {}, 0
        for k in self.V: self.out[k] = []; self.inn[k] = []

    def fresh(self): return StableBase()


def make_base(kind):
    return {"AL": lambda: SwapBase(True), "DP": lambda: SwapBase(False), "SG": StableBase}[kind]()


# ---------------------------------------------------------------------------------------------
# The proposed wrapper.

WORK = {"fwd": 0, "bwd": 0, "region": 0, "delta": 0.0, "reorders": 0}


class DAG:
    def __init__(self, base):
        self.b = base
        self.order = []   # keys, topological
        self.ord = {}     # key -> place in order

    # bulk construction: the base as given, then Kahn's algorithm (FIFO, roots in vertices order)
    @staticmethod
    def build(kind, V, E):
        b = make_base(kind)
        for v in V:
            if b.key(v) is None: b.add_vertex(v)
        for u, v in E:
            ku = b.key(u); ku = b.add_vertex(u) if ku is None else ku
            kv = b.key(v); kv = b.add_vertex(v) if kv is None else kv
            b.add_edge(ku, kv)
        g = DAG(b)
        order = kahn(b)
        if order is None: return None
        g.order = order; g.ord = {k: i for i, k in enumerate(order)}
        return g

    def _need_vertex(self, v):
        k = self.b.key(v); need(k is not None, f"{v} is not a vertex"); return k

    def insert_vertex(self, v):
        k = self.b.key(v)
        if k is not None: return (False, v)
        k = self.b.add_vertex(v); self.ord[k] = len(self.order); self.order.append(k)
        return (True, v)

    def insert_edge(self, u, v, checked=False):
        """The new edge's position (the existing one's on a simple base), or None: the edge would close
        a cycle (a self-loop included, checked first so that nothing is inserted), or, with checked=True,
        an endpoint is missing. A rejected edge changes nothing; `rejection` names the error thrown."""
        if checked and (self.b.key(u) is None or self.b.key(v) is None): return None
        if u == v: return None
        if self.b.key(u) is None and self.b.key(v) is not None:
            # a new source to an existing target is placed first: the edge goes forward
            k = self.b.add_vertex(u); self.order.insert(0, k); self.ord = {x: i for i, x in enumerate(self.order)}
        self.insert_vertex(u); self.insert_vertex(v)
        ku, kv = self.b.key(u), self.b.key(v)
        if self.ord[ku] > self.ord[kv] and self._pearce_kelly(ku, kv) is not None: return None
        p, _ = self.b.add_edge(ku, kv)
        return p

    def _pearce_kelly(self, ku, kv):
        """Reorders for an edge ku -> kv placed backward and returns None, or returns True, changing
        nothing, when kv reaches ku (the edge would close a cycle)."""
        ub, lb = self.ord[ku], self.ord[kv]
        # forward: depth-first from kv through keys placed before ku
        F, stack = {kv}, [kv]
        while stack:
            w = stack.pop()
            for t, _ in self.b.out_row(w):
                WORK["fwd"] += 1
                if t == ku: return True
                if self.ord[t] < ub and t not in F: F.add(t); stack.append(t)
        # backward: from ku through keys placed after kv
        B, stack = {ku}, [ku]
        while stack:
            w = stack.pop()
            for s, _ in self.b.in_row(w):
                WORK["bwd"] += 1
                if self.ord[s] > lb and s not in B:
                    B.add(s); stack.append(s)
        WORK["region"] += ub - lb + 1
        d = len(B) + len(F); WORK["delta"] += d * max(1.0, math.log2(d))
        WORK["reorders"] += 1
        self._place(sorted(B, key=self.ord.get) + sorted(F, key=self.ord.get))
        return None

    def _place(self, moved):
        slots = sorted(self.ord[k] for k in moved)
        for k, i in zip(moved, slots):
            self.ord[k] = i; self.order[i] = k

    def remove_vertex(self, v):
        k = self.b.key(v)
        if k is None: return None
        i = self.ord.pop(k); del self.order[i]
        for j in range(i, len(self.order)): self.ord[self.order[j]] = j
        moved = self.b.remove_vertex(k)
        if moved:
            last, to = moved
            j = self.ord.pop(last); self.ord[to] = j; self.order[j] = to
        return v

    def remove_edge(self, u, v):
        ku, kv = self.b.key(u), self.b.key(v)
        if ku is None or kv is None: return None
        p = self.b.newest_copy(ku, kv)
        if p is None: return None
        self.b.remove_edge_at(p)
        return (u, v)

    def remove_edge_at(self, p):
        need(self.b.is_edge(p), f"no edge at position {p}")
        s, t = self.b.remove_edge_at(p)
        return (self.b.vertex(s), self.b.vertex(t))

    def remove_all(self): self.b.remove_all(); self.order, self.ord = [], {}
    def remove_all_edges(self): self.b.remove_all_edges()

    def topological_order(self): return [self.b.vertex(k) for k in self.order]
    def position(self, v): return self.ord[self._need_vertex(v)]

    def position_checked(self, v):
        k = self.b.key(v); return None if k is None else self.ord[k]

    def has_path(self, a, b):
        ka, kb = self._need_vertex(a), self._need_vertex(b)
        if ka == kb: return True
        if self.ord[ka] > self.ord[kb]: return False
        bound, seen, stack = self.ord[kb], {ka}, [ka]
        while stack:
            w = stack.pop()
            for t, _ in self.b.out_row(w):
                if t == kb: return True
                if self.ord[t] < bound and t not in seen: seen.add(t); stack.append(t)
        return False

    def _reach(self, k):
        seen, stack = set(), [k]
        while stack:
            w = stack.pop()
            for t, _ in self.b.out_row(w):
                if t not in seen: seen.add(t); stack.append(t)
        return seen

    def transitive_closure(self):
        g = copy.deepcopy(self)
        for ku in self.order:
            reach = self._reach(ku)
            have = {t for t, _ in g.b.out_row(ku)}
            for kw in self.order:
                if kw in reach and kw not in have: g.b.add_edge(ku, kw)
        return g

    def transitive_reduction(self):
        keep, first = [], set()
        far = {}
        for k in self.b.keys():
            far[k] = set()
            for t, _ in self.b.out_row(k): far[k] |= self._reach(t)
        for p, s, t in self.b.edges():
            if t in far[s] or (s, t) in first: continue
            first.add((s, t)); keep.append((s, t))
        b = self.b.fresh(); newkey = {}
        for k in self.b.keys(): newkey[k] = b.add_vertex(self.b.vertex(k))
        for s, t in keep: b.add_edge(newkey[s], newkey[t])
        g = DAG(b); g.order = [newkey[k] for k in self.order]; g.ord = {k: i for i, k in enumerate(g.order)}
        return g

    def longest_path(self):
        if not self.order: return None
        dist, best = {}, {}
        for k in self.order:
            dist[k] = 0
            for s, p in self.b.in_row(k):
                if dist[s] + 1 > dist[k]: dist[k] = dist[s] + 1; best[k] = (s, p)
        top = max(dist.values())
        end = next(k for k in self.order if dist[k] == top)
        ks, ps = [end], []
        while ks[-1] in best:
            s, p = best[ks[-1]]; ps.append(p); ks.append(s)
        return [self.b.vertex(k) for k in ks[::-1]], ps[::-1]

    def longest_path_weighted(self, w):
        """NetworkX's dag_longest_path(weight=, topo_order=order), per edge: the first in-edge (in
        in-row order) with the greatest dist + w; a vertex whose best is negative, or with no in-edge,
        starts afresh at 0; the path ends at the first vertex in the order with the greatest dist."""
        if not self.order: return None
        dist, best = {}, {}
        for k in self.order:
            top = None
            for s, p in self.b.in_row(k):
                c = dist[s] + w[p]
                if top is None or c > top[0]: top = (c, s, p)
            if top is not None and top[0] >= 0: dist[k] = top[0]; best[k] = (top[1], top[2])
            else: dist[k] = 0
        m = max(dist.values())
        end = next(k for k in self.order if dist[k] == m)
        ks, ps = [end], []
        while ks[-1] in best:
            s, p = best[ks[-1]]; ps.append(p); ks.append(s)
        return [self.b.vertex(k) for k in ks[::-1]], ps[::-1], m

    def dag_shortest_paths(self, src, w):
        """Boost's dag_shortest_paths in this order: each reached vertex's out-edges relaxed once, in
        out-row order; the first relaxation to the final distance wins. {key: (dist, parent key, edge)}."""
        ks = self._need_vertex(src)
        state = {ks: (0, None, None)}
        for k in self.order:
            if k not in state: continue
            d = state[k][0]
            for t, p in self.b.out_row(k):
                c = d + w[p]
                if t not in state or c < state[t][0]: state[t] = (c, k, p)
        return state

    def __eq__(self, other):
        def ms(g):
            return sorted((repr(g.b.vertex(s)), repr(g.b.vertex(t))) for _, s, t in g.b.edges())
        return sorted(map(repr, (self.b.vertex(k) for k in self.b.keys()))) == \
            sorted(map(repr, (other.b.vertex(k) for k in other.b.keys()))) and ms(self) == ms(other)


def kahn(b):
    indeg = {k: len(b.in_row(k)) for k in b.keys()}
    queue = [k for k in b.keys() if indeg[k] == 0]
    i = 0
    while i < len(queue):
        k = queue[i]; i += 1
        for t, _ in b.out_row(k):
            indeg[t] -= 1
            if indeg[t] == 0: queue.append(t)
    return queue if len(queue) == b.vcount() else None


def decode(kind, V, E, order, removed=()):
    """Codable: {base, order}, order as indices into base.vertices; re-checked. `removed` vertices
    are removed from the base first (holes in a Stable base)."""
    g = DAG.build(kind, V, E)
    if g is None: return "DecodingError.dataCorrupted (a cycle)"
    for v in removed: g.remove_vertex(v)
    keys = g.b.keys()
    if sorted(order) != list(range(len(keys))): return "DecodingError.dataCorrupted (not a permutation)"
    place = {keys[i]: j for j, i in enumerate(order)}
    if any(place[s] >= place[t] for _, s, t in g.b.edges()):
        return "DecodingError.dataCorrupted (an edge goes backward)"
    g.order = [keys[i] for i in order]; g.ord = place
    return g


def decode_stable(vertices, positions, vend, order):
    """Codable on a StableDirectedGraph payload with no edges, positions as given."""
    b = StableBase()
    for v, p in zip(vertices, positions):
        b.V[p] = v; b.slot[v] = p; b.out[p] = []; b.inn[p] = []
    b.vend = vend
    g = DAG(b)
    keys = b.keys()
    g.order = [keys[i] for i in order]; g.ord = {k: i for i, k in enumerate(g.order)}
    return g


HOSTILE = 1 << 50
HOSTILE_JSON = ('{"base": {"vertices": [7], "vertexPositions": [%d], "vertexEnd": %d, "edges": [], "edgePositions": [], '
                '"edgeEnd": 0}, "order": [0]}' % (HOSTILE, HOSTILE + 1))


# ---------------------------------------------------------------------------------------------
# Checks.

def check_laws(g):
    keys = g.b.keys()
    assert sorted(g.order) == sorted(keys), "order is a permutation of the vertices"
    assert all(g.order[g.ord[k]] == k for k in keys)
    for _, s, t in g.b.edges():
        assert g.ord[s] < g.ord[t], "every edge goes forward"


def shortest_paths(g, a, b):
    """Every shortest path of g from a to b by edge count, as (vertices, positions), out-edges in
    outEdges(of:) order: the paths Traversal's bidirectionalShortestPath(from: a, to: b) may return."""
    ka, kb = g._need_vertex(a), g._need_vertex(b)
    dist, frontier = {ka: 0}, [ka]
    while frontier and kb not in dist:
        nxt = []
        for w in frontier:
            for t, _ in g.b.out_row(w):
                if t not in dist: dist[t] = dist[w] + 1; nxt.append(t)
        frontier = nxt
    if kb not in dist: return []
    out = []

    def walk(k, ks, ps):
        if k == kb: out.append(([g.b.vertex(x) for x in ks], ps)); return
        for t, p in g.b.out_row(k):
            if dist.get(t) == dist[k] + 1 and dist[t] <= dist[kb]: walk(t, ks + [t], ps + [p])

    walk(ka, [ka], [])
    return out


def witness(g, u, v):
    """The witness for a rejected u -> v: bidirectionalShortestPath(from: v, to: u)."""
    paths = shortest_paths(g, v, u)
    for vs, ps in paths: check_witness(g, u, v, vs, ps)
    return ("paths", paths)


def check_witness(g, u, v, vs, ps):
    """A path of g from v to u: with the edge u -> v it closes a cycle."""
    if u == v:
        assert vs == [u] and ps == []; return
    assert vs[0] == v and vs[-1] == u and len(vs) == len(ps) + 1 and len(set(vs)) == len(vs)
    for i, p in enumerate(ps):
        assert g.b.is_edge(p)
        s, t = [x for x in g.b.edges() if x[0] == p][0][1:]
        assert (g.b.vertex(s), g.b.vertex(t)) == (vs[i], vs[i + 1])


class Spec:
    """The order and the accept/reject rule from the definitions, via NetworkX."""

    def __init__(self, g):
        import networkx as nx
        self.nx = nx
        self.G = nx.MultiDiGraph()
        for k in g.b.keys(): self.G.add_node(g.b.vertex(k))
        for _, s, t in g.b.edges(): self.G.add_edge(g.b.vertex(s), g.b.vertex(t))
        self.order = g.topological_order()
        self.simple = g.b.simple

    def insert_edge(self, u, v):
        nx = self.nx
        if u != v and u not in self.G and v in self.G: self.G.add_node(u); self.order.insert(0, u)
        for w in (u, v):
            if u != v and w not in self.G: self.G.add_node(w); self.order.append(w)
        if u == v: return False
        place = {w: i for i, w in enumerate(self.order)}
        if place[u] > place[v]:
            if nx.has_path(self.G, v, u): return False
            ub, lb = place[u], place[v]
            F = [w for w in {v} | nx.descendants(self.G, v) if place[w] < ub]
            B = [w for w in {u} | nx.ancestors(self.G, u) if place[w] > lb]
            moved = sorted(B, key=place.get) + sorted(F, key=place.get)
            for w, i in zip(moved, sorted(place[w] for w in moved)): self.order[i] = w
        if not (self.simple and self.G.has_edge(u, v)): self.G.add_edge(u, v)
        return True

    def remove_vertex(self, v):
        if v in self.G: self.G.remove_node(v); self.order.remove(v)

    def sync_edges(self, g):
        G = self.nx.MultiDiGraph(); G.add_nodes_from(self.G.nodes)
        for _, s, t in g.b.edges(): G.add_edge(g.b.vertex(s), g.b.vertex(t))
        self.G = G

    def same(self, g):
        assert self.order == g.topological_order(), (self.order, g.topological_order())
        assert sorted(map(repr, self.G.nodes)) == sorted(map(repr, (g.b.vertex(k) for k in g.b.keys())))
        assert sorted((repr(a), repr(b)) for a, b in self.G.edges()) == \
            sorted((repr(g.b.vertex(s)), repr(g.b.vertex(t))) for _, s, t in g.b.edges())


# ---------------------------------------------------------------------------------------------
# Rendering.

def fmt(x): return f'"{x}"' if isinstance(x, str) else str(x)
def lst(xs): return "[" + ", ".join(map(fmt, xs)) + "]"


def show_path(vs, ps): return f"{lst(vs)} via {ps}"


def rejection(g, op):
    """The error a rejected call throws (its result was None; a rejection changes nothing, so the
    membership checked here is the one before the call)."""
    if op[0] == "positionChecked": return "VertexNotFound"
    if op[0] == "checked" and (g.b.key(op[1]) is None or g.b.key(op[2]) is None): return ".missingEndpoint"
    return ".selfLoop" if op[1] == op[2] else ".cycle"


def show_call_result(g, op, r):
    """A call's result as the catalog shows it: a throwing call that threw shows `throws` and the error."""
    if r is None and op[0] in ("edge", "checked", "positionChecked"): return "throws " + rejection(g, op)
    return show_result(r)


def show_result(r):
    if r is None: return "nil"
    if isinstance(r, bool): return "true" if r else "false"
    if isinstance(r, int): return str(r)
    if isinstance(r, str): return r
    if isinstance(r, tuple) and r and r[0] == "paths": return " or ".join(show_path(vs, ps) for vs, ps in r[1]) or "nil"
    if isinstance(r, tuple) and r and r[0] == "path": return show_path(r[1], r[2])
    if isinstance(r, tuple) and r and r[0] == "graph": return "{" + show_state(r[1]) + "}"
    if isinstance(r, tuple) and r and r[0] == "tree": return show_tree(r[1], r[2])
    if isinstance(r, tuple) and len(r) == 2 and isinstance(r[0], bool): return f"({show_result(r[0])}, {fmt(r[1])})"
    if isinstance(r, tuple) and len(r) == 2: return f"{fmt(r[0])}→{fmt(r[1])}"
    if isinstance(r, list): return lst(r)
    return str(r)


def tree_path(g, st, k):
    """The edge positions of the tree path to key k."""
    ps = []
    while st[k][1] is not None: ps.append(st[k][2]); k = st[k][1]
    return ps[::-1]


def show_tree(rows, g):
    """Each vertex, in vertices order: its distance and the positions of its path, or nil."""
    st = {g.b.key(v): x for v, x in rows if x is not None}
    out = []
    for v, x in rows:
        out.append(f"{fmt(v)}: nil" if x is None else f"{fmt(v)}: {x[0]} via {tree_path(g, st, g.b.key(v))}")
    return "{" + ", ".join(out) + "}"


def show_state(g):
    vs = ", ".join(fmt(g.b.vertex(k)) for k in g.b.keys())
    es = ", ".join(f"{p}:{fmt(g.b.vertex(s))}→{fmt(g.b.vertex(t))}" for p, s, t in g.b.edges())
    return f"order {lst(g.topological_order())}; V [{vs}]; E [{es}]"


def show_op(op):
    k = op[0]
    if k == "insert": return f"insert({fmt(op[1])})"
    if k == "edge": return f"insert(edge: {fmt(op[1])}→{fmt(op[2])})"
    if k == "checked": return f"insert(checked: {fmt(op[1])}→{fmt(op[2])})"
    if k == "remove": return f"remove({fmt(op[1])})"
    if k == "removeEdge": return f"remove(edge: {fmt(op[1])}→{fmt(op[2])})"
    if k == "removeAt": return f"remove(edgeAt: {op[1]})"
    if k == "removeAll": return "removeAll()"
    if k == "removeAllEdges": return "removeAllEdges()"
    if k == "position": return f"topologicalPosition(of: {fmt(op[1])})"
    if k == "positionChecked": return f"topologicalPosition(checked: {fmt(op[1])})"
    if k == "order": return "topologicalOrder"
    if k == "hasPath": return f"hasPath(from: {fmt(op[1])}, to: {fmt(op[2])})"
    if k == "witness": return f"bidirectionalShortestPath(from: {fmt(op[1])}, to: {fmt(op[2])})"
    if k == "closure": return "transitiveClosure()"
    if k == "reduction": return "transitiveReduction()"
    if k == "longest": return "longestPath()"
    if k == "orderAt": return f"topologicalOrder[{op[1]}]"
    if k == "longestW": return f"longestPath(weight: {op[1]})"
    if k == "dagSP": return f"dagShortestPaths(from: {fmt(op[1])}, weight: {op[2]})"
    if k == "equals": return f"== DirectedAcyclicGraph<{NAMES[op[1]]}>(vertices: {lst(op[2])}, edges: [" + ", ".join(f"{fmt(a)}→{fmt(b)}" for a, b in op[3]) + "])"
    raise ValueError(op)


def apply(g, op):
    k = op[0]
    if k == "insert": return g.insert_vertex(op[1])
    if k == "edge": return g.insert_edge(op[1], op[2])
    if k == "checked": return g.insert_edge(op[1], op[2], checked=True)
    if k == "remove": return g.remove_vertex(op[1])
    if k == "removeEdge": return g.remove_edge(op[1], op[2])
    if k == "removeAt": return g.remove_edge_at(op[1])
    if k == "removeAll": g.remove_all(); return "()"
    if k == "removeAllEdges": g.remove_all_edges(); return "()"
    if k == "position": return g.position(op[1])
    if k == "positionChecked": return g.position_checked(op[1])
    if k == "order": return g.topological_order()
    if k == "orderAt":
        o = g.topological_order(); need(0 <= op[1] < len(o), "index out of range"); return fmt(o[op[1]])
    if k == "hasPath": return g.has_path(op[1], op[2])
    if k == "witness": return witness(g, op[2], op[1])
    if k == "closure": return ("graph", g.transitive_closure())
    if k == "reduction": return ("graph", g.transitive_reduction())
    if k == "longest":
        r = g.longest_path(); return None if r is None else ("path",) + r
    if k == "longestW":
        r = g.longest_path_weighted(op[1]); return None if r is None else ("path",) + r[:2]
    if k == "dagSP":
        st = g.dag_shortest_paths(op[1], op[2])
        return ("tree", [(g.b.vertex(k), st.get(k)) for k in g.b.keys()], g)
    if k == "equals":
        other = DAG.build(op[1], op[2], op[3]); return g == other
    raise ValueError(op)


def run(kind, V, E, ops):
    g = DAG.build(kind, V, E)
    if g is None: return ["nil"], False, None
    check_laws(g)
    res = []
    for op in ops:
        try:
            r = apply(g, op)
        except Trap:
            return res, True, g
        check_laws(g)
        if isinstance(r, tuple) and r and r[0] == "graph": check_laws(r[1])
        if op[0] in ("edge", "checked") and r is None and g.b.key(op[1]) is not None and g.b.key(op[2]) is not None:
            assert g.has_path(op[2], op[1]) and witness(g, op[1], op[2])[1], "a rejected edge has a witness"
        res.append(show_call_result(g, op, r))
    return res, False, g


# ---------------------------------------------------------------------------------------------
# The catalog.

ROWS = []
NAMES = {"AL": "AdjacencyList", "DP": "DirectedPseudograph", "SG": "StableDirectedGraph"}


def case(group, title, kind, V, E, ops=(), note=None):
    inp = f"{NAMES[kind]}; V {lst(V)}; E [" + ", ".join(f"{fmt(u)}→{fmt(v)}" for u, v in E) + "]"
    if ops: inp += " / " + " / ".join(show_op(o) for o in ops)
    res, trap, g = run(kind, V, E, list(ops))
    if g is None:
        exp = "nil"
    elif trap:
        exp = ("; ".join(res) + "; " if res else "") + "**trap**"
    else:
        exp = ("; ".join(res) + " ⇒ " if res else "") + show_state(g)
    if note: exp += f" ({note})"
    ROWS.append((group, title, inp, exp))


def raw(group, title, inp, exp):
    ROWS.append((group, title, inp, exp))


def chain(n): return [(i, i + 1) for i in range(n - 1)]


def define():
    C = "Construction"
    case(C, "empty", "DP", [], [])
    case(C, "edgeless: order is vertices order", "DP", [2, 0, 1], [])
    case(C, "Kahn FIFO, roots in vertices order", "DP", [0, 1, 2, 3], [(3, 1), (0, 1), (1, 2), (3, 2)])
    case(C, "diamond: generations flattened", "DP", [], [(0, 1), (0, 2), (1, 3), (2, 3)])
    case(C, "not the DFS order (Traversal's topologicalSort gives [3, 2, 1, 0])", "DP", [0, 1, 2, 3], [])
    case(C, "parallel copies kept on DirectedPseudograph", "DP", [], [(0, 1), (0, 1), (1, 2)])
    case(C, "parallel copies collapse on AdjacencyList", "AL", [], [(0, 1), (0, 1), (1, 2)])
    case(C, "StableDirectedGraph base", "SG", [5], [(3, 5), (5, 4)])
    case(C, "a cycle: nil", "DP", [], [(0, 1), (1, 2), (2, 0)])
    case(C, "a self-loop: nil", "AL", [0, 1], [(0, 1), (1, 1)])
    case(C, "string vertices", "AL", ["b", "a"], [("a", "b"), ("c", "a")])

    I = "Insertion"
    case(I, "insert(_:) appends to the order", "DP", [0], [(0, 1)], [("insert", 2), ("insert", 0)])
    case(I, "forward edge: no reordering", "DP", [0, 1, 2], [], [("edge", 0, 2), ("edge", 1, 2)])
    case(I, "two new endpoints placed last, source first; a new source to an old target placed first", "DP", [], [], [("edge", 7, 8), ("edge", 9, 7)])
    case(I, "new target: always forward", "DP", [0, 1], [(0, 1)], [("edge", 1, 5)])
    case(I, "new source to an old vertex: placed first, no reordering", "DP", [0, 1], [(0, 1)], [("edge", 5, 0)])
    case(I, "new source placed first in the order, not just before its target", "DP", [0, 1, 2], [], [("edge", 5, 1)])
    case(I, "sources arriving last build a chain without reordering", "AL", [], [], [("edge", 1, 0), ("edge", 2, 1), ("edge", 3, 2), ("position", 0), ("position", 3)])
    case(I, "twenty new sources: the free front slots grow", "DP", [0], [], [("edge", i, 0) for i in range(1, 21)] + [("position", 0), ("position", 20), ("orderAt", 0), ("edge", 0, 21)])
    case(I, "parallel copy on DirectedPseudograph: a new position", "DP", [0, 1], [(0, 1)], [("edge", 0, 1)])
    case(I, "existing edge on AdjacencyList: its position, nothing changes", "AL", [0, 1, 2], [(1, 2), (0, 1)], [("edge", 0, 1)])
    case(I, "StableDirectedGraph: position is edges.endIndex", "SG", [0, 1], [(0, 1)], [("removeAt", 0), ("edge", 0, 1)])

    P = "Reordering"
    case(P, "backward edge between isolated vertices: swap", "DP", [0, 1], [], [("edge", 1, 0)])
    case(P, "only the affected region moves", "DP", [0, 1, 2, 3, 4], [], [("edge", 3, 1)])
    case(P, "forward set F follows the source", "DP", [0, 1, 2, 3, 4], [(1, 2)], [("edge", 3, 1)])
    case(P, "backward set B precedes the target", "DP", [0, 1, 2, 3, 4], [(2, 3)], [("edge", 3, 1)])
    case(P, "both sets; unrelated vertices in the region stay", "DP", [0, 1, 2, 3, 4, 5], [(1, 2), (3, 4)], [("edge", 4, 1)])
    case(P, "F bounded by the source's place (vertices after it do not move)", "DP", [0, 1, 2, 3], [(0, 3)], [("edge", 2, 0)])
    case(P, "reverse a chain one edge at a time", "DP", [0, 1, 2, 3], [], [("edge", 3, 2), ("edge", 2, 1), ("edge", 1, 0)])
    case(P, "interleaved sets: B then F take the pooled slots; 6 and 7 stay", "DP", list(range(8)), [(0, 2), (2, 4), (1, 3), (3, 5)], [("edge", 5, 0)])
    case(P, "order independent of row order (same sets)", "DP", [0, 1, 2, 3], [(1, 3), (1, 2)], [("edge", 3, 0)])
    case(P, "incremental build, then the edge closing a five-cycle", "AL", [], [], [("edge", 2, 3), ("edge", 0, 1), ("edge", 3, 0), ("edge", 1, 4), ("edge", 4, 2), ("witness", 2, 4)])

    Y = "Cycle witness"
    case(Y, "self-loop: throws .selfLoop, nothing inserted; the witness is the trivial path", "DP", [0], [], [("edge", 0, 0), ("witness", 0, 0)])
    case(Y, "self-loop on a non-vertex inserts nothing", "AL", [0], [], [("edge", 9, 9)])
    case(Y, "two-cycle: the existing edge", "DP", [0, 1], [(0, 1)], [("edge", 1, 0), ("witness", 0, 1)])
    case(Y, "long cycle: the path from target to source", "DP", [], chain(5), [("edge", 4, 0), ("witness", 0, 4)])
    case(Y, "two shortest paths: either", "DP", [0, 1, 2, 3], [(0, 2), (0, 1), (1, 3), (2, 3)], [("edge", 3, 0), ("witness", 0, 3)])
    case(Y, "a dead branch and a long way round: the shortest path", "DP", [0, 1, 2, 3], [(0, 1), (1, 2), (2, 3), (0, 3)], [("edge", 3, 0), ("witness", 0, 3)])
    case(Y, "parallel copies: either copy", "DP", [0, 1], [(0, 1), (0, 1)], [("edge", 1, 0), ("witness", 0, 1)])
    case(Y, "witness positions after a swap-remove", "DP", [0, 1, 2], [(0, 1), (1, 2), (0, 2)], [("removeAt", 0), ("edge", 2, 0), ("witness", 0, 2)])
    case(Y, "Stable positions in the witness", "SG", [0, 1, 2], [(0, 1), (0, 1), (1, 2)], [("removeAt", 0), ("edge", 2, 0), ("witness", 0, 2)])
    case(Y, "rejected edge changes nothing; later insert works", "AL", [0, 1, 2], [(0, 1), (1, 2)], [("edge", 2, 0), ("edge", 0, 2)])
    case(Y, "rejection found through vertices placed between the endpoints only", "DP", [0, 1, 2, 3], [(1, 2), (0, 3), (2, 3)], [("edge", 2, 1), ("witness", 1, 2), ("edge", 3, 0), ("witness", 0, 3)])

    S = "insert(checked:)"
    case(S, "both endpoints present: as insert(edge:)", "DP", [0, 1], [], [("checked", 1, 0)])
    case(S, "missing endpoint: throws .missingEndpoint, nothing inserted", "DP", [0], [], [("checked", 0, 1), ("checked", 2, 0)])
    case(S, "cycle: throws .cycle, nothing changes", "AL", [0, 1], [(0, 1)], [("checked", 1, 0), ("witness", 0, 1)])
    case(S, "self-loop: .selfLoop on a vertex, .missingEndpoint on a non-vertex", "SG", [0], [], [("checked", 0, 0), ("checked", 3, 3)])
    case(S, "existing edge on AdjacencyList: its position", "AL", [0, 1], [(0, 1)], [("checked", 0, 1)])

    R = "Removal"
    case(R, "remove(edge:) keeps the order", "DP", [0, 1, 2], [(1, 0), (0, 2)], [("removeEdge", 1, 0)])
    case(R, "remove(edge:) newest copy; absent: nil", "DP", [0, 1], [(0, 1), (0, 1)], [("removeEdge", 0, 1), ("removeEdge", 1, 0), ("removeEdge", 0, 9)])
    case(R, "remove(edgeAt:) swap-moves the last edge, order kept", "DP", [0, 1, 2], [(0, 1), (1, 2), (0, 2)], [("removeAt", 0)])
    case(R, "remove(edgeAt:) out of range traps", "DP", [0, 1], [(0, 1)], [("removeAt", 1)])
    case(R, "remove(edgeAt:) at a Stable hole traps", "SG", [0, 1], [(0, 1), (0, 1)], [("removeAt", 0), ("removeAt", 0)])
    case(R, "remove(_:) closes the gap in the order", "DP", [0, 1, 2, 3], chain(4), [("remove", 1)])
    case(R, "remove(_:) follows the swap-remove (last slot moves in)", "AL", [3, 2, 1, 0], [(3, 0), (2, 0)], [("remove", 3), ("position", 0), ("position", 1)])
    case(R, "after the swap-remove, reordering uses the moved vertex's new slot", "AL", [0, 1, 2, 3], [(0, 1)], [("remove", 0), ("edge", 3, 1), ("edge", 2, 3)])
    case(R, "remove(_:) on Stable: holes, nothing renamed", "SG", [0, 1, 2], [(2, 0), (0, 1)], [("remove", 2), ("insert", 2)])
    case(R, "remove(_:) absent: nil", "AL", [0], [], [("remove", 4)])
    case(R, "remove(_:) in the middle: a hole; places count past it", "DP", [0, 1, 2, 3, 4, 5], [], [("remove", 2), ("position", 1), ("position", 3), ("position", 5), ("orderAt", 2), ("orderAt", 4), ("positionChecked", 2)])
    case(R, "reordering across holes", "DP", [0, 1, 2, 3, 4, 5, 6], [(1, 3)], [("remove", 2), ("remove", 4), ("edge", 5, 1), ("position", 5), ("position", 3), ("edge", 6, 0)])
    case(R, "removing the first and last vertices trims the holes they uncover", "DP", [0, 1, 2, 3, 4], [], [("remove", 1), ("remove", 0), ("remove", 3), ("remove", 4), ("position", 2), ("edge", 9, 2), ("edge", 2, 8)])
    case(R, "holes outnumbering the vertices: the slots are compacted", "DP", [0, 1, 2, 3, 4, 5, 6, 7], [(0, 7)], [("remove", 1), ("remove", 2), ("remove", 3), ("remove", 4), ("remove", 5), ("position", 6), ("position", 7), ("edge", 7, 6), ("edge", 9, 0), ("orderAt", 0)])
    case(R, "new sources placed first while there are holes", "AL", [0, 1, 2, 3], [], [("remove", 1)] + [("edge", 10 + i, 2) for i in range(18)] + [("position", 2), ("position", 0), ("orderAt", 18)])
    case(R, "removing every vertex, then inserting again", "SG", [0, 1, 2], [(0, 1)], [("remove", 1), ("remove", 0), ("remove", 2), ("edge", 3, 4), ("edge", 5, 3)])
    case(R, "Stable: holes in the order and in the positions", "SG", [0, 1, 2, 3, 4], [(4, 0), (1, 2)], [("remove", 1), ("remove", 3), ("edge", 2, 4), ("position", 2), ("position", 0), ("orderAt", 1)])
    case(R, "the moved vertex keeps its slot while there are holes", "AL", [0, 1, 2, 3, 4], [(4, 1)], [("remove", 2), ("remove", 0), ("position", 4), ("edge", 3, 4)])
    case(R, "removeAllEdges() keeps vertices and order", "DP", [0, 1, 2], [], [("edge", 2, 0), ("removeAllEdges",), ("edge", 1, 2)])
    case(R, "removeAll() then rebuild", "SG", [0, 1], [(1, 0)], [("removeAll",), ("edge", 1, 0)])
    case(R, "removing an edge makes a reverse edge acceptable", "DP", [0, 1], [(0, 1)], [("removeEdge", 0, 1), ("edge", 1, 0)])

    O = "Order queries"
    case(O, "topologicalPosition(of:)", "DP", [0, 1, 2], [(2, 0)], [("position", 2), ("position", 0), ("position", 1)])
    case(O, "topologicalPosition(of:) non-vertex traps", "DP", [0], [], [("position", 9)])
    case(O, "topologicalPosition(checked:)", "AL", [0, 1], [(1, 0)], [("positionChecked", 1), ("positionChecked", 9)])
    case(O, "topologicalOrder subscript", "DP", [0, 1, 2], [(2, 1)], [("orderAt", 0), ("orderAt", 2)])
    case(O, "topologicalOrder subscript out of range traps", "DP", [0], [], [("orderAt", 1)])
    case(O, "hasPath: same vertex true", "DP", [0], [], [("hasPath", 0, 0)])
    case(O, "hasPath: placed later, so false without a search", "DP", [0, 1], [(0, 1)], [("hasPath", 1, 0)])
    case(O, "hasPath: placed earlier, searched within the bound", "DP", [0, 1, 2, 3], [(0, 1), (1, 3), (0, 2)], [("hasPath", 0, 3), ("hasPath", 2, 3)])
    case(O, "hasPath: non-vertex traps", "DP", [0], [], [("hasPath", 0, 9)])
    case(O, "equality ignores the order", "DP", [0, 1], [], [("edge", 1, 0), ("removeEdge", 1, 0), ("equals", "DP", [0, 1], [])])
    case(O, "equality: different edges", "AL", [0, 1], [(0, 1)], [("equals", "AL", [0, 1], [])])

    A = "Algorithms"
    case(A, "transitiveClosure: chain", "DP", [], chain(4), [("closure",)])
    case(A, "transitiveClosure: existing edges keep their positions", "DP", [0, 1, 2], [(1, 2), (0, 1), (0, 2)], [("closure",)])
    case(A, "transitiveClosure: copies kept, none added", "DP", [], [(0, 1), (0, 1)], [("closure",)])
    case(A, "transitiveClosure: diamond plus tail", "AL", [], [(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)], [("closure",)])
    case(A, "transitiveClosure: empty", "SG", [], [], [("closure",)])
    case(A, "transitiveClosure: missing edges appended in topological order, not vertices order", "DP", [0, 1, 2, 3], [(0, 3), (3, 2), (2, 1)], [("closure",)])
    case(A, "transitiveReduction: drops the shortcut", "DP", [0, 1, 2], [(0, 1), (1, 2), (0, 2)], [("reduction",)])
    case(A, "transitiveReduction: copies collapse to the first", "DP", [], [(0, 1), (1, 2), (0, 1)], [("reduction",)])
    case(A, "transitiveReduction: closure of a chain reduces to the chain", "AL", [], [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)], [("reduction",)])
    case(A, "transitiveReduction: Stable base is compacted", "SG", [0, 1, 2, 3], [(0, 1), (1, 2), (0, 2), (2, 3)], [("remove", 1), ("reduction",)])
    case(A, "transitiveReduction keeps the order", "DP", [0, 1, 2], [], [("edge", 2, 0), ("edge", 1, 0), ("edge", 2, 1), ("reduction",)])
    case(A, "longestPath: empty is nil", "DP", [], [], [("longest",)])
    case(A, "longestPath: edgeless is the first vertex", "DP", [3, 1], [], [("longest",)])
    case(A, "longestPath: chain", "AL", [], chain(4), [("longest",)])
    case(A, "longestPath: ties go to the first in-edge and the first end in order", "DP", [0, 1, 2, 3], [(0, 2), (1, 2), (0, 3)], [("longest",)])
    case(A, "longestPath: the longer branch wins", "DP", [], [(0, 1), (1, 2), (2, 5), (0, 3), (3, 5)], [("longest",)])
    case(A, "longestPath: parallel copies, the first in-edge", "DP", [], [(0, 1), (0, 1)], [("longest",)])
    case(A, "after removals: hasPath, closure, reduction and longest path skip the holes", "DP", [0, 1, 2, 3, 4, 5, 6], [(0, 2), (2, 4), (4, 6), (0, 6), (1, 5), (3, 5)], [("remove", 1), ("remove", 3), ("hasPath", 0, 6), ("hasPath", 6, 0), ("hasPath", 5, 6), ("closure",), ("reduction",), ("longest",)])
    case(A, "longestPath(weight:): a heavy shortcut beats the long way", "DP", [], [(0, 1), (1, 2), (0, 2)], [("longestW", [1, 1, 5])])
    case(A, "longestPath(weight:): a negative best restarts at zero", "DP", [], [(0, 1), (1, 2)], [("longestW", [-3, 2])])
    case(A, "longestPath(weight:): a zero-weight edge extends the path", "AL", [], [(0, 1), (1, 2)], [("longestW", [0, 1])])
    case(A, "longestPath(weight:): every weight negative gives the first vertex", "DP", [], [(0, 1), (1, 2)], [("longestW", [-1, -1])])
    case(A, "longestPath(weight:): ties go to the first in-edge and the first end", "DP", [0, 1, 2, 3], [(0, 2), (1, 2), (0, 3)], [("longestW", [2, 2, 2])])
    case(A, "longestPath(weight:): the heavier of parallel copies", "DP", [], [(0, 1), (0, 1), (1, 2)], [("longestW", [1, 4, 1])])
    case(A, "longestPath(weight:) on Stable positions with holes", "SG", [0, 1, 2, 3], [(0, 1), (1, 2), (0, 2), (2, 3)], [("removeAt", 0), ("remove", 1), ("longestW", [9, 9, 3, 4])])
    case(A, "longestPath(weight:): empty is nil", "SG", [], [], [("longestW", [])])
    case(A, "dagShortestPaths: a negative edge, and an unreached vertex placed before the source", "DP", [3], [(3, 0), (0, 1), (1, 2), (0, 2)], [("dagSP", 0, [1, 2, -5, 1])])
    case(A, "dagShortestPaths: ties go to the first relaxation in the order", "DP", [], [(0, 1), (0, 2), (1, 3), (2, 3)], [("dagSP", 0, [1, 1, 1, 1])])
    case(A, "dagShortestPaths: parallel copies, the lighter", "DP", [], [(0, 1), (0, 1)], [("dagSP", 0, [3, 2])])
    case(A, "dagShortestPaths after removals and reordering (Stable holes)", "SG", [0, 1, 2, 3, 4], [(0, 1), (1, 2), (3, 4)], [("remove", 3), ("edge", 4, 0), ("dagSP", 4, [5, 1, 99, -2])])
    case(A, "dagShortestPaths on AdjacencyList after a swap-remove", "AL", [0, 1, 2, 3], [(0, 1), (1, 3), (0, 2), (2, 3)], [("remove", 0), ("edge", 2, 1), ("dagSP", 2, [4, 1, 1, 1])])

    D = "Codable"
    for kind, title, V, E, removed, order in [
        ("DP", "round trip keeps the order", [0, 1, 2], [(2, 0)], [], [1, 2, 0]),
        ("DP", "cyclic base rejected", [0, 1], [(0, 1), (1, 0)], [], [0, 1]),
        ("DP", "order not a permutation rejected", [0, 1], [], [], [0, 0]),
        ("DP", "edge going backward in the order rejected", [0, 1], [(0, 1)], [], [1, 0]),
        ("AL", "AdjacencyList: round trip keeps the order", [0, 1, 2, 3], [(3, 1), (1, 0)], [], [2, 3, 1, 0]),
        ("AL", "AdjacencyList: edge going backward rejected", [0, 1, 2], [(1, 2)], [], [2, 1, 0]),
        ("SG", "StableDirectedGraph with holes: offsets into the live vertices", [0, 1, 2, 3, 4], [(4, 0), (0, 2)], [1, 3], [2, 0, 1]),
        ("SG", "StableDirectedGraph with holes: an offset past the live vertices rejected", [0, 1, 2], [], [1], [0, 2]),
    ]:
        codable_row(D, kind, title, V, E, removed, order)
    raw(D, "StableDirectedGraph: a vertex at position 2⁵⁰ costs one page, not a table to it",
        "StableDirectedGraph; decode " + HOSTILE_JSON, show_state(decode_stable([7], [HOSTILE], HOSTILE + 1, [0])))
    for kind, title, V, E, removed, order in [
        ("DP", "an order shorter than the vertices rejected", [0, 1], [], [], [0]),
        ("AL", "an order longer than the vertices rejected", [0, 1], [(0, 1)], [], [0, 1, 2]),
        ("SG", "a negative offset rejected", [0, 1], [(0, 1)], [], [-1, 1]),
    ]:
        codable_row(D, kind, title, V, E, removed, order)


def codable_row(D, kind, title, V, E, removed, order):
    r = decode(kind, V, E, order, removed)
    inp = f"{NAMES[kind]}; decode {{base: V {lst(V)}; E [" + ", ".join(f"{u}→{v}" for u, v in E) + "]" + \
        "".join(f" / remove({x})" for x in removed) + f", order: {order}}}"
    raw(D, title, inp, r if isinstance(r, str) else show_state(r))


def render():
    head = open(os.path.join(HERE, "cases.head.md")).read() if os.path.exists(os.path.join(HERE, "cases.head.md")) else HEAD
    lines = [head, "| ID | Group | Case | Input / call | Expected |", "|---|---|---|---|---|"]
    for i, (grp, title, inp, exp) in enumerate(ROWS, 1):
        lines.append(f"| DAG-{i:03d} | {grp} | {title} | {inp} | {exp} |")
    return "\n".join(lines) + "\n"


HEAD = """# DirectedAcyclicGraphModule: case catalog (phase 1)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with rustworkx==0.18.1
python3 Tests/Catalogs/DirectedAcyclicGraph/ref.py`; `--write` regenerates this file, `--stress` adds the random
sequences). Every Expected is the output of a port of the proposed wrapper over ports of the three bases,
checked at every state against the laws (the order is a permutation of the vertices, every edge goes forward)
and every witness against the graph; `--stress` also checks a NetworkX specification and a rustworkx shadow.

Conventions:

* Input `Base; V [...]; E [...]` is `DirectedAcyclicGraph<Base>(vertices: V, edges: E)`, the failable bulk
  initializer (Expected `nil` when the edges have a cycle); calls follow, separated by `/`. Expected lists each
  call's result, then `⇒` and the final state.
* State: `order [...]` is `topologicalOrder`; `V [...]` is `vertices`; `E [p:u→v, …]` is `edges` with positions.
* Bulk construction orders by Kahn's algorithm (FIFO, roots in `vertices` order): Traversal's
  `topologicalGenerations()` flattened. Later inserts maintain the order by Pearce–Kelly, a deterministic
  function of the order and the reachability sets, so it does not depend on row order.
* `insert(edge:)` returns the edge's position `p`, or throws `AcyclicEdgeError` (`throws .cycle`, or
  `throws .selfLoop`) when the edge would close a cycle; `insert(checked:)` also throws `.missingEndpoint` when
  an endpoint is missing, checked first. A rejected edge changes nothing. A `checked:` query on a non-vertex
  throws `VertexNotFound`.
  The witness for a rejected u→v is Traversal's `bidirectionalShortestPath(from: v, to: u)`, a `Path`
  (`[vertices] via [edge positions]`); where several shortest paths tie, the cell lists each (`… or …`).
* `transitiveClosure()` / `transitiveReduction()` results are shown in braces with their own state.
* `longestPath()` is a `Path` (`[vertices] via [positions]`), `nil` for the empty graph.
* `**trap**` rows are preconditions, run as exit tests; results before the trap are listed.
* Codable rows give the payload `{base, order}` (`order` as offsets into `base.vertices`) and the decoded state
  or the `DecodingError` case.
"""


# ---------------------------------------------------------------------------------------------
# Stress.

def stress():
    import networkx as nx
    import rustworkx as rx
    rng = random.Random(7)
    self_loop_quirk = [0, 0]
    for kind in ("AL", "DP", "SG"):
        for seed in range(150):
            rng.seed(seed * 31 + len(kind))
            n0 = rng.randint(0, 6)
            g = DAG.build(kind, list(range(n0)), [])
            spec = Spec(g)
            rg = rx.PyDiGraph(check_cycle=True, multigraph=(kind != "AL")); rnode = {}
            for v in range(n0): rnode[v] = rg.add_node(v)
            pristine = True
            for _ in range(60):
                k = rng.random(); u, v = rng.randrange(9), rng.randrange(9)
                live = [g.b.vertex(x) for x in g.b.keys()]
                if k < 0.55:
                    op = ("edge", u, v)
                elif k < 0.62:
                    op = ("checked", u, v)
                elif k < 0.67:
                    op = ("insert", u)
                elif k < 0.80:
                    op = ("removeEdge", u, v)
                elif k < 0.86 and kind != "AL" and g.b.edges():
                    op = ("removeAt", rng.choice(g.b.edges())[0])
                elif k < 0.97:
                    op = ("remove", rng.choice(live) if live else u)
                elif k < 0.985:
                    op = ("removeAllEdges",)
                else:
                    op = ("removeAll",)
                r = apply(g, op)
                check_laws(g)
                if op[0] in ("edge", "checked"):
                    if op[0] == "checked" and (u not in spec.G or v not in spec.G):
                        assert r is None, (seed, op, r)
                    else:
                        ok = spec.insert_edge(u, v)
                        assert ok == (r is not None), (seed, op, r)
                        if not ok and u in spec.G: assert witness(g, u, v)[1], (seed, op)
                        for w in (u, v):
                            if u != v and w not in rnode: rnode[w] = rg.add_node(w)
                        if u == v:
                            if u in rnode:
                                # rustworkx skips its check when the source has no in-edges or the
                                # target no out-edges, so it accepts some self-loops.
                                try:
                                    rg.add_edge(rnode[u], rnode[u], None)
                                    self_loop_quirk[0] += 1
                                    rg.remove_edge(rnode[u], rnode[u])
                                except rx.DAGWouldCycle:
                                    self_loop_quirk[1] += 1
                        else:
                            try:
                                if kind == "AL" and rg.has_edge(rnode[u], rnode[v]): pass
                                else: rg.add_edge(rnode[u], rnode[v], None)
                                racc = True
                            except rx.DAGWouldCycle:
                                racc = False
                            assert racc == ok, (seed, op)
                elif op[0] == "insert":
                    if u not in spec.G: spec.G.add_node(u); spec.order.append(u); rnode[u] = rg.add_node(u)
                elif op[0] == "remove":
                    if r is not None:
                        spec.remove_vertex(op[1]); rg.remove_node(rnode.pop(op[1])); pristine = False
                elif op[0] in ("removeEdge", "removeAt", "removeAllEdges"):
                    if r is not None:
                        spec.sync_edges(g); pristine = False
                        rg.remove_edges_from(list(rg.edge_list()))
                        for _, s, t in g.b.edges(): rg.add_edge(rnode[g.b.vertex(s)], rnode[g.b.vertex(t)], None)
                elif op[0] == "removeAll":
                    spec = Spec(g); rg = rx.PyDiGraph(check_cycle=True, multigraph=(kind != "AL")); rnode = {}
                    pristine = False
                spec.same(g)
                # algorithms against NetworkX on the current state
                G = spec.G
                tc = g.transitive_closure(); check_laws(tc)
                want = set(nx.transitive_closure_dag(nx.DiGraph(G)).edges())
                assert {(tc.b.vertex(s), tc.b.vertex(t)) for _, s, t in tc.b.edges()} == want
                tr = g.transitive_reduction(); check_laws(tr)
                want = set(nx.transitive_reduction(nx.DiGraph(G)).edges())
                assert sorted((tr.b.vertex(s), tr.b.vertex(t)) for _, s, t in tr.b.edges()) == sorted(want)
                lp = g.longest_path()
                if G.number_of_nodes():
                    assert len(lp[1]) == nx.dag_longest_path_length(G)
                    if pristine:
                        assert lp[0] == nx.dag_longest_path(G, topo_order=g.topological_order()), (seed, lp)
                for a in list(G.nodes)[:3]:
                    for b in list(G.nodes)[:3]:
                        assert g.has_path(a, b) == nx.has_path(G, a, b)
                # weighted longest path and DAG shortest paths against NetworkX, random weights
                if G.number_of_nodes():
                    w = {p: rng.randint(-3, 5) for p, _, _ in g.b.edges()}
                    W = nx.MultiDiGraph(); W.add_nodes_from(G.nodes)
                    for p, s_, t_ in g.b.edges(): W.add_edge(g.b.vertex(s_), g.b.vertex(t_), weight=w[p])
                    vs, ps, length = g.longest_path_weighted(w)
                    assert length == sum(w[p] for p in ps) == nx.dag_longest_path_length(W, weight="weight"), (seed, length)
                    src = g.b.vertex(g.order[0])
                    st = g.dag_shortest_paths(src, w)
                    want = nx.single_source_bellman_ford_path_length(W, src)
                    assert {g.b.vertex(k): d for k, (d, _, _) in st.items()} == want, (seed, st, want)
    return self_loop_quirk


def work_counts():
    """Work on random sparse insert sequences: PK = forward + backward edge visits + |delta| log |delta|
    (the sort); MNR = forward edge visits + the size of the shifted region [lb, ub]."""
    out = []
    for hidden, n, m in ((False, 1000, 3000), (False, 1000, 10000), (False, 5000, 20000),
                         (True, 1000, 3000), (True, 1000, 10000), (True, 5000, 20000)):
        rng = random.Random(n + m + hidden)
        WORK.update(fwd=0, bwd=0, region=0, delta=0.0, reorders=0)
        g = DAG.build("DP", list(range(n)), [])
        rank = list(range(n)); rng.shuffle(rank)
        rej = 0
        for _ in range(m):
            u, v = rng.randrange(n), rng.randrange(n)
            if hidden and rank[u] > rank[v]: u, v = v, u   # edges of a DAG with a hidden order (PK's model)
            r = g.insert_edge(u, v)
            rej += r is None
        check_laws(g)
        pk = WORK["fwd"] + WORK["bwd"] + WORK["delta"]; mnr = WORK["fwd"] + WORK["region"]
        out.append(("hidden-order DAG" if hidden else "random pairs", n, m, rej, WORK["reorders"], round(pk), mnr))
    return out


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
        q = stress()
        print(f"stress: 450 sequences x 60 steps (AdjacencyList, DirectedPseudograph, StableDirectedGraph) agree "
              f"with the NetworkX spec, the laws and rustworkx check_cycle; rustworkx check_cycle accepted {q[0]} of the {q[0] + q[1]} self-loops tried (its in/out-degree shortcut), which we reject")
        for model, n, m, rej, ro, pk, mnr in work_counts():
            print(f"work {model} n={n} m={m}: {rej} rejected, {ro} reorders; Pearce-Kelly {pk}, Marchetti-Spaccamela {mnr} "
                  f"({mnr / max(pk, 1):.2f}x PK)")


if __name__ == "__main__":
    main()
