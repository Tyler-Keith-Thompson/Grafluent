"""Flows phase 1: reference models and independent checks for every catalog row.

Run:  uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1
      python3 ref.py [--stress] [--write]

Without --write the rendered catalog is compared with cases.md byte for byte (exit 1 on any
difference or failed check). --stress adds random networks (see stress()).

What decides Expected, per entry point (api.md, Determinism), and what each row is checked by:

* maximumFlow / dinicMaximumFlow / maximumFlowValue (from:to:capacity:)
      the maximum flow value and the canonical minimum cut. The flow itself is not pinned (any
      maximum flow). Checked: Edmonds-Karp, Dinic and FIFO push-relabel models agree on the value
      and on the canonical cut computed from each one's residual network; the cut computed from
      push-relabel's phase-1 preflow is the same; NetworkX maximum_flow_value with every flow_func;
      NetworkX minimum_cut's partition; igraph maxflow's partition; brute force over every
      s-t cut when n <= 12.
* edmondsKarpMaximumFlow  the flow of every edge, pinned by the procedure (api.md): residual rows
      in edge-position order, breadth-first search from the source that stops when the sink is
      discovered, augment by the bottleneck.
* minimumCut(from:to:capacity:)  the canonical cut: the sink side is the set of vertices that can
      reach the sink in the residual network of a maximum flow (the inclusion-minimal sink side;
      NetworkX's and igraph's partition). Its edges are every edge from the source side to the
      sink side, zero capacities included.
* minimumCut(capacity:) on Graph   a minimum cut with the first vertex on its source side (api.md;
      Nagamochi-Ibaraki, not pinned among several); nil below two vertices; the component of the
      first vertex when positive-capacity edges do not connect the graph. The sides are shown when
      that rule or uniqueness (brute force over every cut, n <= 12) pins them. The value: Stoer-
      Wagner's phases here; checked against brute force, NetworkX stoer_wagner, rustworkx
      stoer_wagner_min_cut and igraph mincut.
* minimumCut(capacity:) on DirectedGraph   a minimum cut (Hao-Orlin, not pinned among several), sides
      shown when unique. The value: the least canonical cut among v_i -> v_(i+1 mod n) (Schnorr
      1979; Esfahanian's Algorithm 8). Checked: brute force, igraph mincut value.
* gomoryHuTree(capacity:)  Gusfield's algorithm with the canonical cut, vertices in index order,
      root the first vertex. Checked: equal to NetworkX gomory_hu_tree edge for edge (the same
      procedure); every tree edge's split is a minimum cut between its ends (brute force); every
      pair's minimum cut value is the least capacity on its tree path.
* minimumCostFlow / minimumCostMaximumFlow   the least cost, and the flow when it is the only
      optimum (each edge's flow forced: raising or lowering it by one costs more). Checked: a
      successive-shortest-path model, NetworkX network_simplex and capacity_scaling (cost, and
      infeasibility), NetworkX max_flow_min_cost, brute force over integer flows when small, no
      negative cycle in the final residual network.
* edgeDisjointPaths / vertexDisjointPaths   how many: lambda(s, t) and kappa(s, t), against NetworkX
      edge_disjoint_paths / node_disjoint_paths and igraph edge_disjoint_paths /
      vertex_disjoint_paths. The paths themselves are not pinned.
* edgeConnectivity / vertexConnectivity / minimumVertexCut   flows on unit and split networks;
      Even's pair order for the global vertex cut (api.md). Checked: brute force over removed sets
      (n <= 10), NetworkX node_connectivity / edge_connectivity values (simple graphs), igraph
      vertex_connectivity / edge_connectivity values.
"""
import itertools
import random
import sys
from fractions import Fraction

try:
    import networkx as nx
    import igraph as ig
    import rustworkx as rx
except ImportError:
    import os
    os.execvp("uv", ["uv", "run", "--quiet", "--no-project", "--with", "networkx==3.7", "--with", "igraph==1.0.0",
                     "--with", "rustworkx==0.18.1", "python3", *sys.argv])

FAILS = []


def fail(msg):
    FAILS.append(msg)


# ---------------------------------------------------------------------------------------------
# Networks


class Net:
    """Vertices 0..n-1 shown by `labels`; edges (u, v) by position with capacities (and costs)."""

    def __init__(self, labels, edges, cap=None, cost=None, supply=None, directed=True, ctype="Int", token=None):
        self.labels = list(labels)
        self.n = len(self.labels)
        self.index = {x: i for i, x in enumerate(self.labels)}
        self.E = [(self.index[u], self.index[v]) for u, v in edges]
        self.cap = list(cap) if cap is not None else None
        self.cost = list(cost) if cost is not None else None
        self.supply = list(supply) if supply is not None else None
        self.directed = directed
        self.ctype = ctype
        self.token = token

    @property
    def m(self):
        return len(self.E)

    def caps(self):
        return self.cap if self.cap is not None else [1] * self.m

    def lab(self, i):
        return self.labels[i]

    def has_parallel(self):
        seen = set()
        for u, v in self.E:
            if u == v:
                continue
            k = (u, v) if self.directed else (min(u, v), max(u, v))
            if k in seen:
                return True
            seen.add(k)
        return False

    def has_loop(self):
        return any(u == v for u, v in self.E)

    def text(self):
        if self.token:
            return self.token
        arrow = "→" if self.directed else "–"
        parts = []
        for e, (u, v) in enumerate(self.E):
            s = f"{self.lab(u)}{arrow}{self.lab(v)}"
            if self.cap is not None:
                s += f" {fmtv(self.cap[e])}"
            if self.cost is not None:
                s += f" @{self.cost[e]}"
            parts.append(s)
        out = ""
        if self.ctype != "Int":
            out += f"{self.ctype} "
        if self.directed is False:
            out += "undirected "
        out += f"V [{', '.join(str(x) for x in self.labels)}]; E [{', '.join(parts)}]"
        if self.supply is not None:
            nz = [f"{self.lab(i)}: {b}" for i, b in enumerate(self.supply) if b != 0]
            out += f"; supply [{', '.join(nz)}]"
        return out


def fmtv(x):
    if isinstance(x, float):
        return repr(x)
    return str(x)


def fmtl(xs):
    return "[" + ", ".join(str(x) for x in xs) + "]"


class LCG:
    def __init__(self, seed):
        self.x = seed

    def next(self):
        self.x = (self.x * 6364136223846793005 + 1442695040888963407) % (1 << 64)
        return self.x >> 33


def lcgnet(n, m, seed, cmax):
    """n vertices, m directed edges (u = d % n, v = d % n; u = v skipped; repeats kept), capacity
    1 + d % cmax."""
    g = LCG(seed)
    E, C = [], []
    while len(E) < m:
        u, v = g.next() % n, g.next() % n
        if u == v:
            continue
        E.append((u, v))
        C.append(1 + g.next() % cmax)
    return Net(range(n), E, C, token=f"lcgnet({n},{m},{seed},{cmax})")


def lcgund(n, m, seed, cmax):
    """The undirected version: an edge u–v per draw pair, u = v skipped, repeats kept."""
    g = LCG(seed)
    E, C = [], []
    while len(E) < m:
        u, v = g.next() % n, g.next() % n
        if u == v:
            continue
        E.append((u, v))
        C.append(1 + g.next() % cmax)
    return Net(range(n), E, C, directed=False, token=f"lcgund({n},{m},{seed},{cmax})")


def lcgcost(n, m, seed, cmax, wlo, whi):
    """Directed, capacity 1 + d % cmax, cost wlo + d % (whi - wlo + 1)."""
    g = LCG(seed)
    E, C, W = [], [], []
    while len(E) < m:
        u, v = g.next() % n, g.next() % n
        if u == v:
            continue
        E.append((u, v))
        C.append(1 + g.next() % cmax)
        W.append(wlo + g.next() % (whi - wlo + 1))
    return Net(range(n), E, C, W, token=f"lcgcost({n},{m},{seed},{cmax},{wlo},{whi})")


def K(n, directed=False):
    if directed:
        E = [(i, j) for i in range(n) for j in range(n) if i != j]
        return Net(range(n), E, directed=True, token=f"Kd({n})")
    E = [(i, j) for i in range(n) for j in range(i + 1, n)]
    return Net(range(n), E, directed=False, token=f"K({n})")


def C(n, directed=False):
    E = [(i, (i + 1) % n) for i in range(n)]
    return Net(range(n), E, directed=directed, token=f"{'Cd' if directed else 'C'}({n})")


def P(n, directed=False):
    E = [(i, i + 1) for i in range(n - 1)]
    return Net(range(n), E, directed=directed, token=f"{'Pd' if directed else 'P'}({n})")


def grid(r, c):
    E = []
    for i in range(r):
        for j in range(c):
            if j + 1 < c:
                E.append((i * c + j, i * c + j + 1))
            if i + 1 < r:
                E.append((i * c + j, (i + 1) * c + j))
    return Net(range(r * c), E, directed=False, token=f"grid({r},{c})")


def named(name, *args):
    g = getattr(nx, name)(*args)
    nodes = list(g.nodes())
    tok = f"nx({name}{',' + ','.join(map(str, args)) if args else ''})"
    return Net(nodes, list(g.edges()), directed=False, token=tok)


def Kb(a, b):
    E = [(i, a + j) for i in range(a) for j in range(b)]
    return Net(range(a + b), E, directed=False, token=f"Kb({a},{b})")


def wheel(k):
    E = [(0, i) for i in range(1, k + 1)] + [(i, i % k + 1) for i in range(1, k + 1)]
    return Net(range(k + 1), E, directed=False, token=f"wheel({k})")


def hypercube(d):
    E = [(i, i ^ (1 << b)) for i in range(1 << d) for b in range(d) if i < i ^ (1 << b)]
    return Net(range(1 << d), E, directed=False, token=f"Q({d})")


# ---------------------------------------------------------------------------------------------
# Residual networks (index space)


def residual(net, cap=None, rows_order=True):
    """Arc 2e from u to v and arc 2e+1 back, for every non-loop edge e. Directed: residuals c and
    0. Undirected: c and c (one edge used either way). Rows in edge-position order."""
    cap = net.caps() if cap is None else cap
    n = net.n
    head, r, rows = {}, {}, [[] for _ in range(n)]
    for e, (u, v) in enumerate(net.E):
        if u == v:
            continue
        a, b = 2 * e, 2 * e + 1
        head[a], head[b] = v, u
        r[a] = cap[e]
        r[b] = cap[e] if not net.directed else type(cap[e])(0)
        rows[u].append(a)
        rows[v].append(b)
    return head, r, rows


def tail_of(net, a):
    u, v = net.E[a // 2]
    return u if a % 2 == 0 else v


def edmonds_karp(net, s, t, cap=None):
    head, r, rows = residual(net, cap)
    value = 0
    while True:
        parent = {s: None}
        queue = [s]
        found = False
        qi = 0
        while qi < len(queue) and not found:
            x = queue[qi]
            qi += 1
            for a in rows[x]:
                y = head[a]
                if r[a] > 0 and y not in parent:
                    parent[y] = a
                    if y == t:
                        found = True
                        break
                    queue.append(y)
        if not found:
            break
        path = []
        y = t
        while y != s:
            a = parent[y]
            path.append(a)
            y = tail_of(net, a)
        delta = min(r[a] for a in path)
        for a in path:
            r[a] -= delta
            r[a ^ 1] += delta
        value += delta
    return value, r


def dinic(net, s, t, cap=None):
    head, r, rows = residual(net, cap)
    n = net.n
    value = 0
    while True:
        level = [-1] * n
        level[s] = 0
        q = [s]
        for x in q:
            for a in rows[x]:
                if r[a] > 0 and level[head[a]] < 0:
                    level[head[a]] = level[x] + 1
                    q.append(head[a])
        if level[t] < 0:
            break
        it = [0] * n

        def dfs(x, f):
            if x == t:
                return f
            while it[x] < len(rows[x]):
                a = rows[x][it[x]]
                y = head[a]
                if r[a] > 0 and level[y] == level[x] + 1:
                    d = dfs(y, min(f, r[a]))
                    if d > 0:
                        r[a] -= d
                        r[a ^ 1] += d
                        return d
                it[x] += 1
            return 0

        while True:
            f = dfs(s, float("inf"))
            if not f:
                break
            value += f
    return value, r


def push_relabel(net, s, t, cap=None, phase2=True):
    """FIFO push-relabel. Phase 1 ends with a maximum preflow; phase 2 returns excess to s."""
    head, r, rows = residual(net, cap)
    n = net.n
    h = [0] * n
    ex = [0] * n
    h[s] = n
    for a in rows[s]:
        d = r[a]
        if d > 0:
            r[a] -= d
            r[a ^ 1] += d
            ex[head[a]] += d
            ex[s] -= d
    from collections import deque

    def run(limit_sink):
        active = deque(v for v in range(n) if v != s and v != t and ex[v] > 0)
        inq = set(active)
        while active:
            x = active.popleft()
            inq.discard(x)
            while ex[x] > 0:
                pushed = False
                for a in rows[x]:
                    y = head[a]
                    if r[a] > 0 and h[x] == h[y] + 1:
                        d = min(ex[x], r[a])
                        r[a] -= d
                        r[a ^ 1] += d
                        ex[x] -= d
                        ex[y] += d
                        if y != s and y != t and y not in inq:
                            active.append(y)
                            inq.add(y)
                        pushed = True
                        if ex[x] == 0:
                            break
                if ex[x] > 0 and not pushed:
                    hs = [h[head[a]] for a in rows[x] if r[a] > 0]
                    h[x] = 1 + min(hs)
                    if limit_sink and h[x] >= n:
                        break  # phase 1 leaves this excess for phase 2

    run(True)
    pre = dict(r)
    if phase2:
        for v in range(n):
            if v != s and v != t and ex[v] > 0 and h[v] < n:
                h[v] = n
        run(False)
    value = ex[t]
    return value, r, pre


def sink_side(net, r, t):
    """Vertices that reach t over arcs with residual > 0."""
    into = [[] for _ in range(net.n)]
    for a in r:
        into[(net.E[a // 2][1] if a % 2 == 0 else net.E[a // 2][0])].append(a)
    T = {t}
    q = [t]
    for y in q:
        for a in into[y]:
            x = tail_of(net, a)
            if r[a] > 0 and x not in T:
                T.add(x)
                q.append(x)
    return T


def cut_edges(net, T):
    out = []
    for e, (u, v) in enumerate(net.E):
        if u == v:
            continue
        if net.directed:
            if u not in T and v in T:
                out.append(str(e))
        else:
            if (u not in T) != (v not in T):
                out.append(str(e) if u not in T else f"{e}r")
    return out


def cut_value(net, S, cap=None):
    cap = net.caps() if cap is None else cap
    tot = 0
    for e, (u, v) in enumerate(net.E):
        if u == v:
            continue
        if net.directed:
            if u in S and v not in S:
                tot += cap[e]
        elif (u in S) != (v in S):
            tot += cap[e]
    return tot


def edge_flows(net, r, cap=None):
    cap = net.caps() if cap is None else cap
    out = []
    for e, (u, v) in enumerate(net.E):
        if u == v:
            out.append(type(cap[e])(0))
        elif net.directed:
            out.append(r[2 * e + 1])
        else:
            out.append(cap[e] - r[2 * e])
    return out


def check_flow(net, s, t, flows, value, cap=None, tag=""):
    cap = net.caps() if cap is None else cap
    bal = [0] * net.n
    for e, (u, v) in enumerate(net.E):
        f = flows[e]
        if net.directed and not (0 <= f <= cap[e]):
            fail(f"{tag}: capacity on edge {e}")
        if not net.directed and not (-cap[e] <= f <= cap[e]):
            fail(f"{tag}: capacity on edge {e}")
        bal[u] -= f
        bal[v] += f
    # Floating capacities: conservation and the value hold up to rounding.
    eps = 1e-12 if any(isinstance(c, float) for c in cap) else 0
    for x in range(net.n):
        if x not in (s, t) and abs(bal[x]) > eps:
            fail(f"{tag}: conservation at {x}")
    if abs(bal[t] - value) > eps or abs(bal[s] + value) > eps:
        fail(f"{tag}: value {value} vs balance {bal[t]}")


def brute_st_cut(net, s, t, cap=None):
    """(min value, inclusion-minimal sink side) over every s-t cut."""
    others = [x for x in range(net.n) if x not in (s, t)]
    best, sinks = None, []
    for k in range(len(others) + 1):
        for sub in itertools.combinations(others, k):
            S = set(sub) | {s}
            val = cut_value(net, S, cap)
            if best is None or val < best:
                best, sinks = val, [set(range(net.n)) - S]
            elif val == best:
                sinks.append(set(range(net.n)) - S)
    inter = set.intersection(*sinks)
    return best, inter


# ---------------------------------------------------------------------------------------------
# NetworkX / igraph conversions (parallel edges summed: their flow functions take simple graphs)


def nx_flow_graph(net, cap=None):
    cap = net.caps() if cap is None else cap
    G = nx.DiGraph() if net.directed else nx.Graph()
    G.add_nodes_from(range(net.n))
    for e, (u, v) in enumerate(net.E):
        if u == v:
            continue
        if G.has_edge(u, v):
            G[u][v]["capacity"] += cap[e]
        else:
            G.add_edge(u, v, capacity=cap[e])
    return G


def ig_graph(net):
    return ig.Graph(n=net.n, edges=[(u, v) for u, v in net.E], directed=net.directed)


# ---------------------------------------------------------------------------------------------
# Catalog


CASES = []


def add(group, name, inp, call, expected, checks):
    CASES.append((group, name, inp, call, expected, "; ".join(c for c in checks if c)))


def lab_list(net, xs):
    return fmtl(net.lab(x) for x in sorted(xs))


def canonical(net, s, t, cap=None):
    """Everything the flow rows need, with every cross-check run once."""
    v1, r1 = edmonds_karp(net, s, t, cap)
    v2, r2 = dinic(net, s, t, cap)
    v3, r3, pre = push_relabel(net, s, t, cap)
    T1, T2, T3, T4 = (sink_side(net, r, t) for r in (r1, r2, r3, pre))
    checks = []
    tag = f"{net.text()} {s}->{t}"
    if not (v1 == v2 == v3):
        fail(f"{tag}: values EK {v1} Dinic {v2} PR {v3}")
    if not (T1 == T2 == T3 == T4):
        fail(f"{tag}: canonical cuts differ {T1} {T2} {T3} {T4}")
    flows = edge_flows(net, r1, cap)
    check_flow(net, s, t, flows, v1, cap, tag)
    check_flow(net, s, t, edge_flows(net, r2, cap), v2, cap, tag + " dinic")
    check_flow(net, s, t, edge_flows(net, r3, cap), v3, cap, tag + " push-relabel")
    S = set(range(net.n)) - T1
    if cut_value(net, S, cap) != v1:
        fail(f"{tag}: cut value {cut_value(net, S, cap)} != flow {v1}")
    checks.append("EK = Dinic = push-relabel, same cut (phase-1 preflow too)")
    if net.n <= 12:
        bv, bT = brute_st_cut(net, s, t, cap)
        if bv != v1 or bT != T1:
            fail(f"{tag}: brute force {bv} {bT} vs {v1} {T1}")
        checks.append("brute force: least cut, least sink side")
    G = nx_flow_graph(net, cap)
    from networkx.algorithms import flow as nf
    vals = {fn.__name__: nx.maximum_flow_value(G, s, t, flow_func=fn)
            for fn in (nf.edmonds_karp, nf.dinitz, nf.preflow_push, nf.shortest_augmenting_path, nf.boykov_kolmogorov)}
    if any(x != v1 for x in vals.values()):
        if all(isinstance(x, float) for x in vals.values()) and all(abs(x - v1) < 1e-9 for x in vals.values()):
            checks.append("≈ NetworkX (rounding)")
        else:
            fail(f"{tag}: NetworkX values {vals} vs {v1}")
    else:
        checks.append("= NetworkX maximum_flow_value (5 flow_funcs)")
    _, (nS, nT) = nx.minimum_cut(G, s, t)
    if set(nT) == T1:
        checks.append("= NetworkX minimum_cut partition")
    else:
        checks.append(f"NetworkX minimum_cut sink side {lab_list(net, nT)}")
    try:
        f = ig_graph(net).maxflow(s, t, capacity=[float(c) for c in (cap or net.caps())])
        if abs(f.value - float(v1)) > 1e-9:
            fail(f"{tag}: igraph value {f.value}")
        if set(f.partition[1]) == T1:
            checks.append("= igraph maxflow partition")
        else:
            checks.append(f"igraph maxflow sink side {lab_list(net, f.partition[1])}")
    except Exception as ex:  # noqa: BLE001
        checks.append(f"igraph raises {type(ex).__name__}")
    return v1, flows, T1, checks


def flow_rows(name, net, s, t, note=None, rows="MEDVC", cap=None):
    si, ti = net.index[s], net.index[t]
    value, flows, T, checks = canonical(net, si, ti, cap)
    S = set(range(net.n)) - T
    cut = f"S {lab_list(net, S)}; T {lab_list(net, T)}; cut {fmtl(cut_edges(net, T))}"
    inp = net.text()
    nm = name + (f": {note}" if note else "")
    st = f"from: {s}, to: {t}"
    if "M" in rows:
        add("MaximumFlow", nm, inp, f"maximumFlow({st}, capacity:)", f"value {fmtv(value)}; {cut}", checks)
    if "E" in rows:
        add("EdmondsKarp", nm, inp, f"edmondsKarpMaximumFlow({st}, capacity:)",
            f"value {fmtv(value)}; flow {fmtl(fmtv(x) for x in flows)}; {cut}",
            ["the documented procedure; capacity and conservation hold"])
    if "D" in rows:
        add("Dinic", nm, inp, f"dinicMaximumFlow({st}, capacity:)", f"value {fmtv(value)}; {cut}", checks[:1])
    if "V" in rows:
        add("MaximumFlowValue", nm, inp, f"maximumFlowValue({st}, capacity:)", fmtv(value), checks[:1])
    if "C" in rows:
        add("MinimumCut", nm, inp, f"minimumCut({st}, capacity:)", f"value {fmtv(value)}; {cut}", checks)


def trap(group, name, inp, call, reason, checks=""):
    add(group, name, inp, call, f"trap: {reason}", [checks])


# ---------------------------------------------------------------------------------------------
# Stoer-Wagner and the directed global cut


def components_positive(net, cap):
    parent = list(range(net.n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for e, (u, v) in enumerate(net.E):
        if u != v and cap[e] > 0:
            parent[find(u)] = find(v)
    return find


def stoer_wagner(net, cap=None):
    cap = net.caps() if cap is None else cap
    n = net.n
    if n < 2:
        return None
    find = components_positive(net, cap)
    if any(find(x) != find(0) for x in range(n)):
        S = {x for x in range(n) if find(x) == find(0)}
        return 0, set(range(n)) - S
    w = [[0] * n for _ in range(n)]
    for e, (u, v) in enumerate(net.E):
        if u != v:
            w[u][v] += cap[e]
            w[v][u] += cap[e]
    members = {x: {x} for x in range(n)}
    active = list(range(n))
    best, best_side = None, None
    while len(active) > 1:
        A = [0]
        conn = {x: w[0][x] for x in active if x != 0}
        last_w = None
        while conn:
            x = min(conn, key=lambda y: (-conn[y], y))
            last_w = conn.pop(x)
            A.append(x)
            for y in conn:
                conn[y] += w[x][y]
        s_, t_ = A[-2], A[-1]
        if best is None or last_w < best:
            best, best_side = last_w, set(members[t_])
        members[s_] |= members.pop(t_)
        for y in active:
            if y not in (s_, t_):
                w[s_][y] += w[t_][y]
                w[y][s_] = w[s_][y]
        active.remove(t_)
    return best, best_side


def brute_global(net, cap=None):
    n = net.n
    best = None
    for k in range(1, n):
        for sub in itertools.combinations(range(n), k):
            S = set(sub)
            if net.directed or 0 in S:
                val = cut_value(net, S, cap)
                if best is None or val < best:
                    best = val
    return best


def directed_global(net, cap=None):
    n = net.n
    if n < 2:
        return None
    best = None
    for i in range(n):
        s, t = i, (i + 1) % n
        v, r = edmonds_karp(net, s, t, cap)
        if best is None or v < best[0]:
            best = (v, sink_side(net, r, t))
    return best


def all_global_minimum_sides(net, cap=None):
    """(least value, every source side of a cut with that value): on Graph only the sides holding
    the first vertex (each cut counted once); n <= 12."""
    n = net.n
    best, sides = None, []
    for k in range(1, n):
        for sub in itertools.combinations(range(n), k):
            S = set(sub)
            if not net.directed and 0 not in S:
                continue
            val = cut_value(net, S, cap)
            if best is None or val < best:
                best, sides = val, [S]
            elif val == best:
                sides.append(S)
    return best, sides


def global_cut(net, cap=None):
    """minimumCut(capacity:) as api.md specifies it: nil below two vertices; on Graph, when the
    positive edges leave several components, value 0 with the first vertex's component as the
    source side (pinned); otherwise a minimum cut, pinned only when it is the only one (with the
    first vertex on its source side, on Graph). Returns None, or (value, sink side or None, why).
    The value comes from Stoer-Wagner's phases (undirected) or the least canonical cut over the
    cyclic pairs v_i -> v_(i+1) (directed; every proper set separates such a pair: Schnorr 1979,
    Esfahanian's Algorithm 8), both checked against brute force."""
    capv = net.caps() if cap is None else cap
    n = net.n
    if n < 2:
        return None
    if not net.directed:
        find = components_positive(net, capv)
        if any(find(x) != find(0) for x in range(n)):
            return 0, {x for x in range(n) if find(x) != find(0)}, "the first vertex's component"
    val = stoer_wagner(net, capv)[0] if not net.directed else directed_global(net, capv)[0]
    if n > 12:
        return val, None, "not enumerated"
    bv, sides = all_global_minimum_sides(net, capv)
    if bv != val:
        fail(f"{net.text()}: global model {val} vs brute force {bv}")
    if len(sides) == 1:
        return val, set(range(n)) - sides[0], "the only minimum cut"
    return val, None, f"{len(sides)} minimum cuts"


def global_expected(net, res):
    if res is None:
        return "nil"
    val, T, _ = res
    if T is None:
        return f"value {fmtv(val)} (one of several minimum cuts)"
    S = set(range(net.n)) - T
    return f"value {fmtv(val)}; S {lab_list(net, S)}; T {lab_list(net, T)}; cut {fmtl(cut_edges(net, T))}"


def global_rows(name, net, note=None, cap=None, checks_extra=()):
    nm = name + (f": {note}" if note else "")
    capv = net.caps() if cap is None else cap
    res = global_cut(net, capv)
    checks = list(checks_extra)
    if res is None:
        checks.append("fewer than two vertices")
    else:
        val, T, why = res
        if T is not None:
            S = set(range(net.n)) - T
            if cut_value(net, S, capv) != val:
                fail(f"{nm}: global cut value")
        if net.n <= 12:
            if brute_global(net, capv) != val:
                fail(f"{nm}: brute global {brute_global(net, capv)} vs {val}")
            checks.append(f"brute force: least cut ({why})")
        if not net.directed:
            G = nx_flow_graph(net, capv)
            for _, _, d in G.edges(data=True):
                d["weight"] = d["capacity"]
            try:
                nv, _ = nx.stoer_wagner(G)
                if nv != val:
                    fail(f"{nm}: NetworkX stoer_wagner {nv}")
                checks.append("= NetworkX stoer_wagner value")
            except nx.NetworkXError as ex:
                checks.append(f"NetworkX stoer_wagner raises ({ex})")
            R = rx.PyGraph()
            R.add_nodes_from(range(net.n))
            for e, (u, v) in enumerate(net.E):
                if u != v:
                    R.add_edge(u, v, capv[e])
            rv = rx.stoer_wagner_min_cut(R, weight_fn=lambda x: float(x))
            if rv is not None and abs(rv[0] - float(val)) < 1e-9:
                checks.append("= rustworkx value")
            else:
                fail(f"{nm}: rustworkx {rv}")
        gi = ig_graph(net)
        c = gi.mincut(capacity=[float(x) for x in capv])
        if abs(c.value - float(val)) > 1e-9:
            fail(f"{nm}: igraph mincut {c.value} vs {val}")
        checks.append("= igraph mincut value")
    add("GlobalMinimumCut" if not net.directed else "DirectedGlobalMinimumCut", nm, net.text(),
        "minimumCut(capacity:)", global_expected(net, res), checks)


# ---------------------------------------------------------------------------------------------
# Gomory-Hu (Gusfield) with the canonical cut


def gomory_hu(net, cap=None):
    n = net.n
    if n == 0:
        return None
    p = [0] * n
    fl = [None] * n
    for s in range(1, n):
        t = p[s]
        v, r = edmonds_karp(net, s, t, cap)
        T = sink_side(net, r, t)
        X = set(range(n)) - T
        fl[s] = v
        for i in range(1, n):
            if i != s and i in X and p[i] == t:
                p[i] = s
        if t != 0 and p[t] in X:
            p[s] = p[t]
            p[t] = s
            fl[s] = fl[t]
            fl[t] = v
    return p, fl


def tree_path_min(n, p, fl, a, b):
    adj = {x: [] for x in range(n)}
    for i in range(1, n):
        adj[i].append((p[i], fl[i]))
        adj[p[i]].append((i, fl[i]))
    stack = [(a, None)]
    prev = {a: None}
    while stack:
        x, _ = stack.pop()
        for y, c in adj[x]:
            if y not in prev:
                prev[y] = (x, c)
                stack.append((y, c))
    best = None
    y = b
    while y != a:
        x, c = prev[y]
        best = c if best is None else min(best, c)
        y = x
    return best


def gh_rows(name, net, note=None):
    nm = name + (f": {note}" if note else "")
    res = gomory_hu(net)
    checks = []
    if res is None:
        add("GomoryHu", nm, net.text(), "gomoryHuTree(capacity:)", "nil", ["no vertex"])
        return
    p, fl = res
    n = net.n
    edges = [f"{net.lab(i)}–{net.lab(p[i])} {fmtv(fl[i])}" for i in range(1, n)]
    # NetworkX: the same procedure, so the same tree.
    G = nx_flow_graph(net)
    T = nx.gomory_hu_tree(G)
    mine = {frozenset((i, p[i])): fl[i] for i in range(1, n)}
    theirs = {frozenset((u, v)): d["weight"] for u, v, d in T.edges(data=True)}
    if mine == theirs:
        checks.append("= NetworkX gomory_hu_tree")
    else:
        fail(f"{nm}: NetworkX gomory_hu_tree differs: {theirs}")
    if n <= 10:
        for i in range(1, n):
            # Removing tree edge i splits the tree; that split is a minimum cut between i and p[i].
            adj = {x: [] for x in range(n)}
            for j in range(1, n):
                if j != i:
                    adj[j].append(p[j])
                    adj[p[j]].append(j)
            comp = {i}
            q = [i]
            for x in q:
                for y in adj[x]:
                    if y not in comp:
                        comp.add(y)
                        q.append(y)
            if cut_value(net, comp) != fl[i]:
                fail(f"{nm}: tree edge {i} split value {cut_value(net, comp)} vs {fl[i]}")
            if brute_st_cut(net, i, p[i])[0] != fl[i]:
                fail(f"{nm}: tree edge {i} is not a minimum cut")
        for a in range(n):
            for b in range(a + 1, n):
                if tree_path_min(n, p, fl, a, b) != brute_st_cut(net, a, b)[0]:
                    fail(f"{nm}: pair {a},{b}")
        checks.append("every tree split a minimum cut; every pair's least path edge (brute force)")
    add("GomoryHu", nm, net.text(), "gomoryHuTree(capacity:)", f"edges {fmtl(edges)}", checks)


# ---------------------------------------------------------------------------------------------
# Minimum-cost flow


def mcf(n, arcs, supply):
    """arcs: (u, v, cap, cost, lower). Least cost and flows, or None when infeasible.
    Self-loops carry their capacity when their cost is negative, else their lower bound."""
    if sum(supply) != 0:
        return None
    b = list(supply)
    f = [0] * len(arcs)
    for i, (u, v, c, w, lo) in enumerate(arcs):
        if lo > c:
            return None
        if u == v:
            f[i] = c if w < 0 else lo
            continue
        f[i] = c if w < 0 else lo
        b[u] -= f[i]
        b[v] += f[i]
    S, T = n, n + 1
    total = sum(x for x in b if x > 0)
    shipped = 0
    while True:
        # residual arcs: (from, to, residual, cost, arc, sign)
        res = []
        for i, (u, v, c, w, lo) in enumerate(arcs):
            if u == v:
                continue
            if f[i] < c:
                res.append((u, v, c - f[i], w, i, 1))
            if f[i] > lo:
                res.append((v, u, f[i] - lo, -w, i, -1))
        sent = [0] * n
        for x in range(n):
            if b[x] > 0:
                res.append((S, x, b[x], 0, -1, x))
            elif b[x] < 0:
                res.append((x, T, -b[x], 0, -2, x))
        INF = float("inf")
        dist = [INF] * (n + 2)
        pre = [None] * (n + 2)
        dist[S] = 0
        for _ in range(n + 2):
            changed = False
            for k, (x, y, rr, w, i, sg) in enumerate(res):
                if rr > 0 and dist[x] + w < dist[y]:
                    dist[y] = dist[x] + w
                    pre[y] = k
                    changed = True
            if not changed:
                break
        if dist[T] == INF:
            break
        path = []
        y = T
        while y != S:
            k = pre[y]
            path.append(k)
            y = res[k][0]
        d = min(res[k][2] for k in path)
        for k in path:
            x, y, rr, w, i, sg = res[k]
            if i >= 0:
                f[i] += d * sg
            elif i == -1:
                b[sg] -= d
            else:
                b[sg] += d
        shipped += d
    if shipped != total:
        return None
    cost = sum(f[i] * arcs[i][3] for i in range(len(arcs)))
    # certificate: no negative cycle in the residual network
    res = []
    for i, (u, v, c, w, lo) in enumerate(arcs):
        if u == v:
            continue
        if f[i] < c:
            res.append((u, v, w))
        if f[i] > lo:
            res.append((v, u, -w))
    dist = [0] * n
    for _ in range(n + 1):
        changed = False
        for x, y, w in res:
            if dist[x] + w < dist[y]:
                dist[y] = dist[x] + w
                changed = True
        if not changed:
            break
    if changed:
        fail(f"mcf: negative residual cycle at the optimum {arcs} {supply}")
    return cost, f


def mcf_net(net, supply, cap=None):
    cap = net.caps() if cap is None else cap
    arcs = [(u, v, cap[e], net.cost[e], 0) for e, (u, v) in enumerate(net.E)]
    return mcf(net.n, arcs, supply)


def unique_flow(net, supply, cost, f):
    cap = net.caps()
    for e, (u, v) in enumerate(net.E):
        if u == v:
            continue
        for lo, hi in ((f[e] + 1, cap[e]), (0, f[e] - 1)):
            if lo > hi or hi < 0:
                continue
            arcs = [(a, b, (hi if k == e else cap[k]), net.cost[k], (lo if k == e else 0)) for k, (a, b) in enumerate(net.E)]
            r = mcf(net.n, arcs, supply)
            if r is not None and r[0] == cost:
                return False
    return True


def brute_mcf(net, supply):
    cap = net.caps()
    space = 1
    for c in cap:
        space *= c + 1
    if space > 60000:
        return "skip"
    best = None
    for fl in itertools.product(*[range(c + 1) for c in cap]):
        bal = list(supply)
        for e, (u, v) in enumerate(net.E):
            bal[u] -= fl[e]
            bal[v] += fl[e]
        if any(bal):
            continue
        c = sum(fl[e] * net.cost[e] for e in range(net.m))
        if best is None or c < best:
            best = c
    return best


def nx_mcf_graph(net, supply):
    G = nx.MultiDiGraph()
    for x in range(net.n):
        G.add_node(x, demand=-supply[x])
    for e, (u, v) in enumerate(net.E):
        G.add_edge(u, v, capacity=net.caps()[e], weight=net.cost[e])
    return G


def mcf_rows(name, net, note=None):
    nm = name + (f": {note}" if note else "")
    supply = net.supply
    res = mcf_net(net, supply)
    checks = []
    G = nx_mcf_graph(net, supply)
    if net.n == 0:
        checks.append("NetworkX network_simplex raises (graph has no nodes)")
    else:
        for fn in (nx.network_simplex, nx.capacity_scaling):
            try:
                c, _ = fn(G)
                if res is None or c != res[0]:
                    fail(f"{nm}: NetworkX {fn.__name__} {c} vs {res}")
            except nx.NetworkXUnfeasible as ex:
                if res is not None:
                    fail(f"{nm}: NetworkX {fn.__name__} infeasible ({ex}) vs {res}")
        checks.append("= NetworkX network_simplex, capacity_scaling" + (" (NetworkXUnfeasible)" if res is None else ""))
    bf = brute_mcf(net, supply)
    if bf != "skip":
        if (bf if bf is not None else None) != (res[0] if res else None):
            fail(f"{nm}: brute {bf} vs {res}")
        checks.append("brute force")
    if res is None:
        exp = "nil"
    else:
        cost, f = res
        uniq = unique_flow(net, supply, cost, f)
        exp = f"cost {cost}; flow {fmtl(f)}" + ("" if uniq else " (one of several optima)")
        checks.append("no negative residual cycle" + ("; the only optimum" if uniq else ""))
    add("MinimumCostFlow", nm, net.text(), "minimumCostFlow(supply:capacity:cost:)", exp, checks)


def mcmf_rows(name, net, s, t, note=None):
    nm = name + (f": {note}" if note else "")
    si, ti = net.index[s], net.index[t]
    value, _ = edmonds_karp(net, si, ti)
    supply = [0] * net.n
    supply[si], supply[ti] = value, -value
    cost, f = mcf_net(net, supply)
    uniq = unique_flow(net, supply, cost, f)
    checks = ["max flow then minimumCostFlow"]
    if not net.has_parallel():
        G = nx.DiGraph()
        G.add_nodes_from(range(net.n))
        for e, (u, v) in enumerate(net.E):
            G.add_edge(u, v, capacity=net.caps()[e], weight=net.cost[e])
        fd = nx.max_flow_min_cost(G, si, ti)
        nc = nx.cost_of_flow(G, fd)
        if nc != cost:
            fail(f"{nm}: NetworkX max_flow_min_cost {nc} vs {cost}")
        checks.append("= NetworkX max_flow_min_cost cost")
    bsum = brute_mcf(Net(net.labels, [(net.lab(u), net.lab(v)) for u, v in net.E], net.cap, net.cost), supply)
    if bsum != "skip":
        if bsum != cost:
            fail(f"{nm}: brute {bsum} vs {cost}")
        checks.append("brute force")
    exp = f"value {value}; cost {cost}; flow {fmtl(f)}" + ("" if uniq else " (one of several optima)")
    add("MinimumCostMaximumFlow", nm, net.text(), f"minimumCostMaximumFlow(from: {s}, to: {t}, capacity:cost:)", exp, checks)


# ---------------------------------------------------------------------------------------------
# Connectivity


def adjacent(net, s, t):
    for u, v in net.E:
        if u == v:
            continue
        if (u, v) == (s, t) or (not net.directed and (v, u) == (s, t)):
            return True
    return False


def split_net(net, s, t, drop_direct):
    """v_in = 2v, v_out = 2v + 1; v_in -> v_out capacity 1 (n for s and t); u_out -> v_in
    capacity n per edge (both ways when undirected). drop_direct removes s_out -> t_in arcs."""
    n = net.n
    E, Cs = [], []
    for v in range(n):
        E.append((2 * v, 2 * v + 1))
        Cs.append(n if v in (s, t) else 1)
    for u, v in net.E:
        if u == v:
            continue
        for a, b in ((u, v), (v, u)) if not net.directed else ((u, v),):
            if drop_direct and (a, b) == (s, t):
                continue
            E.append((2 * a + 1, 2 * b))
            Cs.append(n)
    return Net(range(2 * n), E, Cs)


def local_vertex(net, s, t):
    """(vertexConnectivity(from:to:), minimumVertexCut(from:to:) or None)."""
    adj = adjacent(net, s, t)
    H = split_net(net, s, t, drop_direct=True)
    v, r = edmonds_karp(H, 2 * s + 1, 2 * t)
    if adj:
        return v + 1, None
    T = sink_side(H, r, 2 * t)
    cut = [x for x in range(net.n) if (2 * x) not in T and (2 * x + 1) in T]
    if len(cut) != v:
        fail(f"local vertex cut size {cut} vs {v}")
    return v, cut


def connected_without(net, removed):
    keep = [x for x in range(net.n) if x not in removed]
    if len(keep) <= 1:
        return False  # trivial
    adj = {x: set() for x in keep}
    radj = {x: set() for x in keep}
    for u, v in net.E:
        if u in adj and v in adj and u != v:
            adj[u].add(v)
            radj[v].add(u)
            if not net.directed:
                adj[v].add(u)
                radj[u].add(v)

    def reach(a, nb):
        seen = {a}
        q = [a]
        for x in q:
            for y in nb[x]:
                if y not in seen:
                    seen.add(y)
                    q.append(y)
        return seen

    return len(reach(keep[0], adj)) == len(keep) and len(reach(keep[0], radj)) == len(keep)


def global_vertex(net):
    n = net.n
    if n <= 1:
        return 0, []
    best, cut = n - 1, list(range(1, n))
    i = 0
    while i < n and i <= best:
        for j in range(i + 1, n):
            pairs = [(i, j)] if not net.directed else [(i, j), (j, i)]
            for a, b in pairs:
                if adjacent(net, a, b):
                    continue
                v, c = local_vertex(net, a, b)
                if v < best:
                    best, cut = v, c
        i += 1
    return best, cut


def brute_kappa(net):
    n = net.n
    if n <= 1:
        return 0
    for k in range(0, n - 1):
        for X in itertools.combinations(range(n), k):
            if not connected_without(net, set(X)):
                return k
    return n - 1


def local_edge(net, s, t):
    v, _ = edmonds_karp(net, s, t, [1] * net.m)
    return v


def global_edge(net):
    if net.n < 2:
        return 0
    if net.directed:
        return directed_global(net, [1] * net.m)[0]
    return stoer_wagner(net, [1] * net.m)[0]


def nx_simple(net):
    G = nx.DiGraph() if net.directed else nx.Graph()
    G.add_nodes_from(range(net.n))
    G.add_edges_from((u, v) for u, v in net.E if u != v)
    return G


def conn_rows(name, net, note=None, pairs=()):
    nm = name + (f": {note}" if note else "")
    inp = net.text()
    k, cut = global_vertex(net)
    lam = global_edge(net)
    checks_k, checks_l = [], []
    if net.n <= 10:
        if brute_kappa(net) != k:
            fail(f"{nm}: brute kappa {brute_kappa(net)} vs {k}")
        checks_k.append("brute force")
        bl = brute_global(net, [1] * net.m) if net.n >= 2 else 0
        if bl != lam:
            fail(f"{nm}: brute lambda {bl} vs {lam}")
        checks_l.append("brute force")
    if net.n >= 1:
        G = nx_simple(net)
        nk = nx.node_connectivity(G)
        if nk != k:
            fail(f"{nm}: NetworkX node_connectivity {nk} vs {k}")
        checks_k.append("= NetworkX node_connectivity")
        if not net.has_parallel():
            nl = nx.edge_connectivity(G)
            if nl != lam:
                fail(f"{nm}: NetworkX edge_connectivity {nl} vs {lam}")
            checks_l.append("= NetworkX edge_connectivity")
        else:
            checks_l.append(f"NetworkX edge_connectivity {nx.edge_connectivity(G)} (it drops parallel edges)")
        gi = ig_graph(net)
        if not net.has_parallel() and not net.has_loop():
            if gi.vertex_connectivity() != k:
                fail(f"{nm}: igraph vertex_connectivity {gi.vertex_connectivity()} vs {k}")
            checks_k.append("= igraph vertex_connectivity")
        if gi.edge_connectivity() != lam:
            fail(f"{nm}: igraph edge_connectivity {gi.edge_connectivity()} vs {lam}")
        checks_l.append("= igraph edge_connectivity")
    else:
        checks_k.append("NetworkX raises NetworkXPointlessConcept")
        checks_l.append("NetworkX raises NetworkXPointlessConcept")
    if len(cut) != k:
        fail(f"{nm}: cut size")
    if net.n >= 2 and k < net.n - 1 and connected_without(net, set(cut)):
        fail(f"{nm}: vertex cut does not separate")
    add("VertexConnectivity", nm, inp, "vertexConnectivity()", str(k), checks_k)
    add("MinimumVertexCut", nm, inp, "minimumVertexCut()", lab_list(net, cut),
        ["size κ; removing it disconnects or leaves one vertex"] + ([f"NetworkX minimum_node_cut {lab_list(net, nx.minimum_node_cut(nx_simple(net)))}"] if net.n >= 2 and (nx.is_strongly_connected(nx_simple(net)) if net.directed else nx.is_connected(nx_simple(net))) else []))
    add("EdgeConnectivity", nm, inp, "edgeConnectivity()", str(lam), checks_l)
    for s, t in pairs:
        si, ti = net.index[s], net.index[t]
        kv, kc = local_vertex(net, si, ti)
        lv = local_edge(net, si, ti)
        G = nx_simple(net)
        ch = []
        nk = nx.node_connectivity(G, si, ti)
        if nk != kv:
            fail(f"{nm}: NetworkX local node {nk} vs {kv}")
        ch.append("= NetworkX node_connectivity(s, t)")
        if kc is not None and net.n <= 10:
            # brute: the least set separating s from t
            others = [x for x in range(net.n) if x not in (si, ti)]
            best = None
            for kk in range(len(others) + 1):
                for X in itertools.combinations(others, kk):
                    H = Net(range(net.n), [(u, v) for u, v in net.E if u not in X and v not in X], directed=net.directed)
                    if local_edge(H, si, ti) == 0:
                        best = kk
                        break
                if best is not None:
                    break
            if best != kv:
                fail(f"{nm}: brute local vertex {best} vs {kv}")
            ch.append("brute force")
        add("VertexConnectivity", nm, inp, f"vertexConnectivity(from: {s}, to: {t})", str(kv), ch)
        add("MinimumVertexCut", nm, inp, f"minimumVertexCut(from: {s}, to: {t})",
            "nil" if kc is None else lab_list(net, kc), ["s→t adjacent" if kc is None else "size κ(s, t); the cut nearest t"])
        chl = []
        if not net.has_parallel():
            nl = nx.edge_connectivity(G, si, ti)
            if nl != lv:
                fail(f"{nm}: NetworkX local edge {nl} vs {lv}")
            chl.append("= NetworkX edge_connectivity(s, t)")
        il = ig_graph(net).edge_connectivity(si, ti)
        if il != lv:
            fail(f"{nm}: igraph local edge {il} vs {lv}")
        chl.append("= igraph edge_connectivity(s, t)")
        add("EdgeConnectivity", nm, inp, f"edgeConnectivity(from: {s}, to: {t})", str(lv), chl)


def paths_word(k):
    return f"{k} path" + ("" if k == 1 else "s")


def paths_rows(name, net, s, t, note=None):
    """edgeDisjointPaths / vertexDisjointPaths(from:to:): how many (lambda(s, t), kappa(s, t)); which
    paths is not pinned, the tests check each path and their disjointness."""
    nm = name + (f": {note}" if note else "")
    si, ti = net.index[s], net.index[t]
    lv = local_edge(net, si, ti)
    kv, _ = local_vertex(net, si, ti)
    G = nx_simple(net)

    def nx_count(fn):
        try:
            return len(list(fn(G, si, ti)))
        except nx.NetworkXNoPath:
            return 0

    gi = ig_graph(net)
    ce = []
    ne = nx_count(nx.edge_disjoint_paths)
    if not net.has_parallel():
        if ne != lv:
            fail(f"{nm}: NetworkX edge_disjoint_paths {ne} vs {lv}")
        ce.append("= NetworkX edge_disjoint_paths count")
    else:
        ce.append(f"NetworkX edge_disjoint_paths {ne} (it drops parallel edges)")
    ie = gi.edge_disjoint_paths(si, ti)
    if ie != lv:
        fail(f"{nm}: igraph edge_disjoint_paths {ie} vs {lv}")
    ce.append("= igraph edge_disjoint_paths; = edgeConnectivity(from:to:)")
    cv = []
    nv = nx_count(nx.node_disjoint_paths)
    if nv != kv:
        fail(f"{nm}: NetworkX node_disjoint_paths {nv} vs {kv}")
    cv.append("= NetworkX node_disjoint_paths count")
    iv = gi.vertex_disjoint_paths(si, ti, neighbors="ignore") + (1 if adjacent(net, si, ti) else 0)
    if iv != kv:
        fail(f"{nm}: igraph vertex_disjoint_paths {iv} vs {kv}")
    cv.append("= igraph vertex_disjoint_paths (neighbors ignored) + the edge s→t; = vertexConnectivity(from:to:)")
    st = f"from: {s}, to: {t}"
    add("EdgeDisjointPaths", nm, net.text(), f"edgeDisjointPaths({st})", paths_word(lv), ce)
    add("VertexDisjointPaths", nm, net.text(), f"vertexDisjointPaths({st})", paths_word(kv), cv)


# ---------------------------------------------------------------------------------------------
# The catalog


CLRS = Net(["s", "v1", "v2", "v3", "v4", "t"],
           [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")],
           [16, 13, 12, 4, 14, 9, 20, 7, 4])
CLRS2 = Net(["s", "v1", "v2", "v3", "v4", "t"],
            [("s", "v1"), ("s", "v2"), ("v1", "v2"), ("v2", "v1"), ("v1", "v3"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")],
            [16, 13, 10, 4, 12, 14, 9, 20, 7, 4])
NXDOC = Net(["x", "a", "b", "c", "d", "e", "y"],
            [("x", "a"), ("x", "b"), ("a", "c"), ("b", "c"), ("b", "d"), ("d", "e"), ("c", "y"), ("e", "y")],
            [3.0, 1.0, 3.0, 5.0, 4.0, 2.0, 2.0, 3.0], ctype="Double")
FF = Net(["s", "a", "b", "t"], [("s", "a"), ("s", "b"), ("a", "b"), ("a", "t"), ("b", "t")], [1000, 1000, 1, 1000, 1000])
SW_PAPER = Net(range(1, 9), [(1, 2), (1, 5), (2, 3), (2, 5), (2, 6), (3, 4), (3, 7), (4, 7), (4, 8), (5, 6), (6, 7), (7, 8)],
               [2, 3, 3, 2, 2, 4, 2, 2, 2, 3, 1, 3], directed=False)
GH_WIKI = Net(range(6), [(0, 1), (0, 2), (1, 2), (1, 3), (1, 4), (2, 4), (3, 4), (3, 5), (4, 5)],
              [1, 7, 1, 3, 2, 4, 1, 6, 2], directed=False)


def build():
    # --- maximum flow: degenerate inputs
    flow_rows("one edge", Net([0, 1], [(0, 1)], [5]), 0, 1)
    flow_rows("no edge", Net([0, 1], [], []), 0, 1, note="value 0, the sink alone on its side")
    flow_rows("no path: edge into the source only", Net([0, 1], [(1, 0)], [5]), 0, 1)
    flow_rows("no path: disconnected", Net([0, 1, 2, 3], [(0, 1), (2, 3)], [4, 4]), 0, 3)
    flow_rows("zero capacity", Net([0, 1], [(0, 1)], [0]), 0, 1, note="a zero edge still crosses the cut")
    flow_rows("zero capacities on the only path", Net([0, 1, 2], [(0, 1), (1, 2)], [3, 0]), 0, 2)
    flow_rows("path: the first bottleneck from the sink", Net([0, 1, 2, 3], [(0, 1), (1, 2), (2, 3)], [2, 2, 2]), 0, 3,
              note="every edge is a minimum cut; the one nearest t")
    flow_rows("path with a later bottleneck", Net([0, 1, 2, 3], [(0, 1), (1, 2), (2, 3)], [1, 3, 2]), 0, 3)
    flow_rows("source and sink not first and last", Net(["a", "t", "s"], [("s", "a"), ("a", "t")], [2, 3]), "s", "t")
    flow_rows("isolated extra vertex", Net([0, 1, 2], [(0, 2)], [3]), 0, 2, note="unreachable vertices sit on the source side")
    flow_rows("vertex reaching only the sink", Net([0, 1, 2], [(0, 2), (1, 2)], [3, 9]), 0, 2, note="1 can reach t: sink side")
    flow_rows("dead end off the source", Net([0, 1, 2], [(0, 1), (0, 2)], [7, 3]), 0, 2)
    flow_rows("self-loop ignored", Net([0, 1], [(0, 0), (0, 1), (1, 1)], [9, 4, 9]), 0, 1, note="loops carry no flow, never cross")
    flow_rows("parallel edges add", Net([0, 1, 2], [(0, 1), (0, 1), (1, 2), (1, 2)], [2, 3, 1, 9]), 0, 2)
    flow_rows("antiparallel pair", Net([0, 1, 2], [(0, 1), (1, 0), (1, 2)], [5, 3, 4]), 0, 2,
              note="each arc its own reverse")
    flow_rows("antiparallel pair on the path", Net([0, 1, 2, 3], [(0, 1), (0, 2), (1, 2), (2, 1), (1, 3), (2, 3)], [3, 3, 2, 2, 1, 5]), 0, 3)
    flow_rows("edge into the source and out of the sink", Net([0, 1, 2], [(1, 0), (0, 1), (2, 1), (1, 2), (2, 0)], [4, 3, 6, 2, 8]), 0, 2)
    flow_rows("CLRS figure 26.1", CLRS, "s", "t", note="value 23")
    flow_rows("CLRS 2nd ed., with v1⇄v2", CLRS2, "s", "t")
    flow_rows("Ford–Fulkerson's slow case", FF, "s", "t", note="Edmonds–Karp needs two augmentations")
    flow_rows("NetworkX docs example", NXDOC, "x", "y")
    flow_rows("diamond, two equal cuts", Net([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3)], [1, 1, 1, 1]), 0, 3)
    flow_rows("cut not at either end", Net([0, 1, 2, 3, 4, 5], [(0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5), (1, 2)], [5, 5, 1, 1, 5, 5, 3]), 0, 5)
    flow_rows("bipartite matching as flow", Net(["s", "a", "b", "c", "x", "y", "z", "t"],
                                                [("s", "a"), ("s", "b"), ("s", "c"), ("a", "x"), ("a", "y"), ("b", "x"), ("c", "x"), ("c", "z"),
                                                 ("x", "t"), ("y", "t"), ("z", "t")], [1] * 11), "s", "t")
    flow_rows("lcgnet(8,20,8,9)", lcgnet(8, 20, 8, 9), 0, 7)
    flow_rows("lcgnet(10,30,10,20)", lcgnet(10, 30, 10, 20), 0, 9)
    flow_rows("lcgnet(12,40,3,5)", lcgnet(12, 40, 3, 5), 0, 11)
    flow_rows("lcgnet(16,60,4,100)", lcgnet(16, 60, 4, 100), 0, 15, rows="MEDV")
    flow_rows("lcgnet(30,150,5,50)", lcgnet(30, 150, 5, 50), 0, 29, rows="MDVC")
    flow_rows("lcgnet(30,150,5,50) reversed ends", lcgnet(30, 150, 5, 50), 29, 0, rows="MV")

    # numeric types
    flow_rows("Double, dyadic", Net([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3), (1, 2)], [0.5, 0.75, 0.25, 1.0, 0.125], ctype="Double"), 0, 3,
              note="exact in binary")
    flow_rows("Double, rounding", Net([0, 1, 2], [(0, 1), (0, 1), (1, 2)], [0.1, 0.2, 0.3], ctype="Double"), 0, 2, rows="MV",
              note="0.1 + 0.2 > 0.3 in Double: the cut is the 0.3 edge")
    flow_rows("Double, irrational-like", Net([0, 1, 2, 3], [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)],
                                               [2 ** 0.5, 3 ** 0.5, 1.0, 1.0, 2.0], ctype="Double"), 0, 3, rows="MEV")
    flow_rows("Int8 near overflow", Net([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3)], [100, 27, 127, 127], ctype="Int8"), 0, 3,
              rows="MEV", note="source capacities sum to Int8.max")
    flow_rows("UInt8", Net([0, 1, 2], [(0, 1), (1, 2), (0, 2)], [200, 50, 5], ctype="UInt8"), 0, 2, rows="MV")
    big = (1 << 62)
    flow_rows("Int, large", Net([0, 1, 2], [(0, 1), (0, 2), (1, 2)], [big, big - 1, big], ctype="Int"), 0, 2, rows="MEV",
              note="2^63 - 1 total, Int.max")

    # undirected
    flow_rows("undirected: one edge both ways", Net([0, 1], [(0, 1)], [5], directed=False), 1, 0, note="flow -5 on edge 0")
    flow_rows("undirected path", Net([0, 1, 2], [(0, 1), (1, 2)], [2, 3], directed=False), 0, 2)
    flow_rows("undirected: an edge used against its order", Net([0, 1, 2, 3], [(0, 1), (2, 1), (2, 3), (0, 2)], [4, 4, 4, 1], directed=False), 0, 3)
    flow_rows("undirected: parallel edges and a loop", Net([0, 1, 2], [(0, 1), (1, 0), (1, 1), (1, 2)], [2, 2, 7, 9], directed=False), 0, 2)
    flow_rows("undirected: flows meet head on", Net([0, 1, 2, 3], [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)], [3, 3, 5, 1, 5], directed=False), 0, 3)
    flow_rows("undirected Stoer–Wagner paper graph, 1 to 8", SW_PAPER, 1, 8)
    flow_rows("undirected Wikipedia Gomory–Hu graph, 0 to 5", GH_WIKI, 0, 5)
    flow_rows("undirected lcgund(10,25,6,9)", lcgund(10, 25, 6, 9), 0, 9)
    flow_rows("undirected grid(4,4), unit", grid(4, 4), 0, 15, rows="MDVC")
    flow_rows("undirected Double", Net(["a", "b", "c"], [("a", "b"), ("b", "c"), ("a", "c")], [0.5, 1.5, 0.25], directed=False, ctype="Double"), "a", "c")

    # --- traps
    one = Net([0, 1], [(0, 1)], [5])
    for call in ["maximumFlow", "edmondsKarpMaximumFlow", "dinicMaximumFlow", "maximumFlowValue", "minimumCut"]:
        trap("Preconditions", "source is the sink", one.text(), f"{call}(from: 0, to: 0, capacity:)", "source == sink (NetworkX raises)")
    trap("Preconditions", "source not a vertex", one.text(), "maximumFlow(from: 7, to: 1, capacity:)", "not a vertex")
    trap("Preconditions", "sink not a vertex", one.text(), "maximumFlow(from: 0, to: 7, capacity:)", "not a vertex")
    trap("Preconditions", "negative capacity", Net([0, 1], [(0, 1)], [-1]).text(), "maximumFlow(from: 0, to: 1, capacity:)", "a capacity is negative")
    trap("Preconditions", "negative capacity off every path", Net([0, 1, 2], [(0, 1), (2, 1)], [1, -1]).text(), "maximumFlow(from: 0, to: 1, capacity:)",
         "a capacity is negative (every non-loop edge is checked)")
    trap("Preconditions", "NaN capacity", Net([0, 1], [(0, 1)], [float("nan")], ctype="Double").text(), "maximumFlow(from: 0, to: 1, capacity:)", "a capacity is NaN")
    trap("Preconditions", "infinite capacity", Net([0, 1], [(0, 1)], [float("inf")], ctype="Double").text(), "maximumFlow(from: 0, to: 1, capacity:)",
         "a capacity is infinite (c − c ≠ 0)")
    trap("Preconditions", "source capacities overflow", Net([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3)], [100, 100, 50, 50], ctype="Int8").text(),
         "maximumFlow(from: 0, to: 3, capacity:)", "the capacities out of the source sum past Int8.max, though the value 100 fits")
    trap("Preconditions", "source capacities overflow, Int", Net([0, 1], [(0, 1), (0, 1)], [2 ** 63 - 1, 1]).text(),
         "maximumFlowValue(from: 0, to: 1, capacity:)", "Int.max + 1")
    trap("Preconditions", "undirected: capacities at the source overflow", Net([0, 1, 2], [(1, 0), (0, 2)], [100, 28], directed=False, ctype="Int8").text(),
         "maximumFlow(from: 0, to: 2, capacity:)", "edges at the source sum past Int8.max")

    # --- global minimum cut, undirected (Stoer–Wagner)
    global_rows("empty graph", Net([], [], [], directed=False))
    global_rows("one vertex", Net([0], [(0, 0)], [3], directed=False))
    global_rows("two vertices, one edge", Net([0, 1], [(0, 1)], [4], directed=False))
    global_rows("two vertices, parallel edges", Net([0, 1], [(0, 1), (1, 0), (0, 1)], [4, 1, 2], directed=False), note="weights add")
    global_rows("two vertices, no edge", Net([0, 1], [], [], directed=False))
    global_rows("disconnected", Net([0, 1, 2, 3], [(0, 1), (2, 3)], [5, 6], directed=False), note="value 0, the first vertex's component")
    global_rows("disconnected, first vertex isolated", Net([0, 1, 2], [(1, 2)], [5], directed=False))
    global_rows("connected only by a zero edge", Net([0, 1, 2, 3], [(0, 1), (1, 2), (2, 3)], [5, 0, 6], directed=False),
                note="positive edges decide the components")
    global_rows("self-loops ignored", Net([0, 1, 2], [(0, 0), (0, 1), (1, 2), (2, 2), (0, 2)], [9, 2, 3, 9, 4], directed=False))
    global_rows("triangle, equal weights", K(3), note="ties: three minimum cuts")
    global_rows("path P(5)", P(5))
    global_rows("cycle C(6)", C(6))
    global_rows("K(5)", K(5))
    global_rows("Stoer–Wagner paper (1997, figure 1)", SW_PAPER, note="value 4")
    global_rows("NetworkX stoer_wagner docs example", Net(["x", "a", "b", "c", "d", "e", "y"],
                [("x", "a"), ("x", "b"), ("a", "c"), ("b", "c"), ("b", "d"), ("d", "e"), ("c", "y"), ("e", "y")],
                [3, 1, 3, 5, 4, 2, 2, 3], directed=False))
    global_rows("Wikipedia Gomory–Hu graph", GH_WIKI)
    global_rows("two K(4) joined by one light edge", Net(range(8), [(i, j) for i in range(4) for j in range(i + 1, 4)] +
                [(i, j) for i in range(4, 8) for j in range(i + 1, 8)] + [(3, 4)], [3] * 12 + [1], directed=False))
    global_rows("Petersen, unit", named("petersen_graph"))
    global_rows("grid(3,4), unit", grid(3, 4), note="a corner")
    global_rows("lcgund(10,25,6,9)", lcgund(10, 25, 6, 9))
    global_rows("lcgund(12,40,7,20)", lcgund(12, 40, 7, 20))
    global_rows("Double weights", Net([0, 1, 2], [(0, 1), (1, 2), (0, 2)], [0.5, 0.25, 0.125], directed=False, ctype="Double"))
    trap("Preconditions", "negative weight", Net([0, 1], [(0, 1)], [-1], directed=False).text(), "minimumCut(capacity:)", "a capacity is negative")

    # --- global minimum cut, directed
    global_rows("directed: one vertex", Net([0], [], []))
    global_rows("directed: one edge", Net([0, 1], [(0, 1)], [4]), note="1 cannot reach 0: value 0")
    global_rows("directed: two-cycle", Net([0, 1], [(0, 1), (1, 0)], [4, 2]))
    global_rows("directed: cycle Cd(4)", C(4, directed=True))
    global_rows("directed: complete Kd(4)", K(4, directed=True))
    global_rows("directed: CLRS figure 26.1", CLRS, note="t has no out-edge")
    global_rows("directed: lcgnet(8,30,8,9)", lcgnet(8, 30, 8, 9))
    global_rows("directed: lcgnet(10,40,21,5)", lcgnet(10, 40, 21, 5))

    # --- Gomory–Hu
    gh_rows("empty graph", Net([], [], [], directed=False))
    gh_rows("one vertex", Net([0], [], [], directed=False))
    gh_rows("two vertices", Net([0, 1], [(0, 1), (0, 1)], [2, 3], directed=False))
    gh_rows("disconnected", Net([0, 1, 2], [(1, 2)], [4], directed=False), note="zero edges join the pieces")
    gh_rows("path", Net([0, 1, 2, 3], [(0, 1), (1, 2), (2, 3)], [3, 1, 2], directed=False))
    gh_rows("star", Net([0, 1, 2, 3], [(0, 1), (0, 2), (0, 3)], [3, 1, 2], directed=False))
    gh_rows("triangle", Net([0, 1, 2], [(0, 1), (1, 2), (0, 2)], [1, 2, 3], directed=False))
    gh_rows("K(4), unit", K(4))
    gh_rows("cycle C(5), unit", C(5))
    gh_rows("Wikipedia Gomory–Hu graph", GH_WIKI)
    gh_rows("Stoer–Wagner paper graph", SW_PAPER)
    gh_rows("igraph example: triangle with a pendant", Net([0, 1, 2, 3], [(0, 1), (1, 2), (2, 0), (2, 3)], [1, 1, 1, 1], directed=False))
    gh_rows("labels, not indices", Net(["d", "b", "a", "c"], [("a", "b"), ("b", "c"), ("c", "d"), ("d", "a"), ("a", "c")], [1, 2, 3, 4, 5], directed=False))
    gh_rows("self-loop and parallel edges", Net([0, 1, 2], [(0, 0), (0, 1), (1, 0), (1, 2)], [5, 1, 1, 3], directed=False))
    gh_rows("lcgund(9,20,10,9)", lcgund(9, 20, 10, 9))
    gh_rows("Petersen, unit", named("petersen_graph"))
    trap("Preconditions", "Gomory–Hu: negative capacity", Net([0, 1], [(0, 1)], [-2], directed=False).text(), "gomoryHuTree(capacity:)", "a capacity is negative")

    # --- minimum-cost flow
    def M(labels, edges, cap, cost, supply, **kw):
        idx = {x: i for i, x in enumerate(labels)}
        sup = [0] * len(labels)
        for k, b in supply.items():
            sup[idx[k]] = b
        return Net(labels, edges, cap, cost, sup, **kw)

    mcf_rows("NetworkX docs example", M(["a", "b", "c", "d"], [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")], [4, 10, 9, 5], [3, 6, 1, 2],
             {"a": 5, "d": -5}), note="cost 24")
    mcf_rows("no vertices", M([], [], [], [], {}))
    mcf_rows("no supply, no edges", M([0, 1], [], [], [], {}))
    mcf_rows("no supply, positive costs", M([0, 1], [(0, 1), (1, 0)], [3, 3], [1, 1], {}), note="nothing moves")
    mcf_rows("no supply, a negative cycle", M([0, 1, 2], [(0, 1), (1, 2), (2, 0)], [2, 3, 4], [1, -5, 1], {}), note="saturated to capacity 2")
    mcf_rows("negative self-loop saturated", M([0, 1], [(0, 0), (0, 1)], [3, 1], [-2, 1], {0: 1, 1: -1}))
    mcf_rows("zero-cost self-loop carries nothing", M([0, 1], [(0, 0), (0, 1)], [3, 1], [0, 1], {0: 1, 1: -1}))
    mcf_rows("one edge", M([0, 1], [(0, 1)], [5], [2], {0: 3, 1: -3}))
    mcf_rows("supply over capacity: infeasible", M([0, 1], [(0, 1)], [1], [1], {0: 2, 1: -2}))
    mcf_rows("unbalanced supplies", M([0, 1], [(0, 1)], [3], [1], {0: 1, 1: -2}), note="nil (NetworkX: total node demand is not zero)")
    mcf_rows("unbalanced, more supply", M([0, 1], [(0, 1)], [3], [1], {0: 2}))
    mcf_rows("no path to the demand", M([0, 1, 2], [(0, 1)], [3], [1], {0: 1, 2: -1}))
    mcf_rows("cheaper long way", M([0, 1, 2], [(0, 2), (0, 1), (1, 2)], [5, 5, 5], [5, 1, 1], {0: 4, 2: -4}))
    mcf_rows("cheaper long way, capacity spills", M([0, 1, 2], [(0, 2), (0, 1), (1, 2)], [5, 2, 5], [5, 1, 1], {0: 4, 2: -4}))
    mcf_rows("ties: two equal routes", M([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3)], [2, 2, 2, 2], [1, 1, 1, 1], {0: 2, 3: -2}))
    mcf_rows("parallel edges, different costs", M([0, 1], [(0, 1), (0, 1), (0, 1)], [2, 2, 2], [3, 1, 2], {0: 3, 1: -3}))
    mcf_rows("antiparallel edges", M([0, 1], [(0, 1), (1, 0)], [5, 5], [2, 1], {0: 2, 1: -2}), note="the back edge carries nothing")
    mcf_rows("negative cost on the route", M([0, 1, 2], [(0, 1), (1, 2), (0, 2)], [3, 3, 3], [-2, 1, 0], {0: 2, 2: -2}))
    mcf_rows("negative cycle beside the route", M([0, 1, 2, 3], [(0, 3), (1, 2), (2, 1)], [1, 2, 2], [1, -3, 1], {0: 1, 3: -1}))
    mcf_rows("transshipment vertex", M(["p", "w", "c1", "c2"], [("p", "w"), ("w", "c1"), ("w", "c2"), ("p", "c1")],
                                         [10, 10, 10, 2], [1, 1, 2, 5], {"p": 6, "c1": -3, "c2": -3}))
    mcf_rows("two supplies, two demands (transportation)", M(["s1", "s2", "d1", "d2"],
             [("s1", "d1"), ("s1", "d2"), ("s2", "d1"), ("s2", "d2")], [9, 9, 9, 9], [4, 6, 5, 3], {"s1": 3, "s2": 4, "d1": -5, "d2": -2}))
    mcf_rows("assignment 3×3 as flow", M(["r0", "r1", "r2", "c0", "c1", "c2"],
             [(f"r{i}", f"c{j}") for i in range(3) for j in range(3)], [1] * 9, [4, 1, 3, 2, 0, 5, 3, 2, 2],
             {"r0": 1, "r1": 1, "r2": 1, "c0": -1, "c1": -1, "c2": -1}), note="scipy linear_sum_assignment cost 5")
    mcf_rows("infeasible behind a cut", M([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3)], [5, 5, 1, 1], [1, 1, 1, 1], {0: 3, 3: -3}))
    mcf_rows("demand reached only against an edge", M([0, 1], [(1, 0)], [5], [1], {0: 1, 1: -1}))
    mcf_rows("zero-capacity edges", M([0, 1, 2], [(0, 1), (0, 2), (2, 1)], [0, 2, 2], [-9, 1, 1], {0: 1, 1: -1}))
    mcf_rows("supply at a vertex with only a loop", M([0], [(0, 0)], [4], [-1], {}))
    mcf_rows("lcgcost(8,20,11,5,0,9)", lcg_with_supply(lcgcost(8, 20, 11, 5, 0, 9), {0: 4, 7: -4}))
    mcf_rows("lcgcost(8,20,6,5,-4,9)", lcg_with_supply(lcgcost(8, 20, 6, 5, -4, 9), {0: 3, 5: -1, 7: -2}), note="negative costs")
    mcf_rows("lcgcost(10,30,13,6,-5,5)", lcg_with_supply(lcgcost(10, 30, 13, 6, -5, 5), {}), note="a circulation")
    mcf_rows("lcgcost(12,40,14,9,1,20)", lcg_with_supply(lcgcost(12, 40, 14, 9, 1, 20), {0: 6, 1: 3, 10: -4, 11: -5}))
    mcf_rows("lcgcost(6,8,15,2,1,3)", lcg_with_supply(lcgcost(6, 8, 15, 2, 1, 3), {0: 9, 5: -9}), note="more supply than the network carries")
    trap("Preconditions", "min-cost: negative capacity", M([0, 1], [(0, 1)], [-1], [1], {}).text(), "minimumCostFlow(supply:capacity:cost:)", "a capacity is negative")
    trap("Preconditions", "min-cost: cost total overflows", M([0, 1], [(0, 1)], [100], [2], {0: 1, 1: -1}, ctype="Int8").text(),
         "minimumCostFlow(supply:capacity:cost:)", "capacity × cost magnitude summed past Int8.max (checked before solving)")

    # --- minimum-cost maximum flow
    def MM(labels, edges, cap, cost, **kw):
        return Net(labels, edges, cap, cost, **kw)

    mcmf_rows("one edge", MM([0, 1], [(0, 1)], [3], [2]), 0, 1)
    mcmf_rows("no path", MM([0, 1, 2], [(0, 1)], [3], [2]), 0, 2, note="value 0, cost 0")
    mcmf_rows("cheaper of two routes first", MM([0, 1, 2, 3], [(0, 1), (0, 2), (1, 3), (2, 3)], [2, 2, 2, 2], [1, 3, 1, 3]), 0, 3)
    mcmf_rows("maximum before cheap", MM([0, 1, 2], [(0, 2), (0, 1), (1, 2)], [1, 5, 5], [100, 1, 1]), 0, 2, note="the dear edge is still used")
    mcmf_rows("CLRS figure 26.1 with unit costs", MM(CLRS.labels, [(CLRS.lab(u), CLRS.lab(v)) for u, v in CLRS.E], CLRS.cap, [1] * 9), "s", "t")
    mcmf_rows("negative cycle off the path is saturated", MM([0, 1, 2, 3], [(0, 3), (1, 2), (2, 1)], [1, 2, 2], [1, -1, -1]), 0, 3,
              note="NetworkX max_flow_min_cost too")
    mcmf_rows("negative self-loop", MM([0, 1], [(0, 1), (1, 1)], [2, 4], [1, -1]), 0, 1)
    mcmf_rows("parallel edges", MM([0, 1, 2], [(0, 1), (0, 1), (1, 2)], [2, 2, 3], [5, 1, 0]), 0, 2)
    mcmf_rows("cancel along a reverse arc", MM([0, 1, 2, 3], [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)], [1, 1, 1, 1, 1], [1, 5, 1, 5, 1]), 0, 3)
    mcmf_rows("lcgcost(8,24,21,5,0,9)", lcgcost(8, 24, 21, 5, 0, 9), 0, 7)
    mcmf_rows("lcgcost(10,30,17,5,-3,9)", lcgcost(10, 30, 17, 5, -3, 9), 0, 9)
    trap("Preconditions", "min-cost max flow: source is the sink", MM([0, 1], [(0, 1)], [1], [1]).text(),
         "minimumCostMaximumFlow(from: 0, to: 0, capacity:cost:)", "source == sink")

    # --- connectivity
    conn_rows("empty graph", Net([], [], directed=False))
    conn_rows("one vertex", Net([0], [], directed=False))
    conn_rows("two isolated vertices", Net([0, 1], [], directed=False), pairs=[(0, 1)])
    conn_rows("K(2)", K(2), note="κ = n − 1: all but the first vertex", pairs=[(0, 1)])
    conn_rows("K(2) with parallel edges", Net([0, 1], [(0, 1), (0, 1), (1, 0)], directed=False), note="λ counts copies, κ does not", pairs=[(0, 1)])
    conn_rows("self-loops ignored", Net([0, 1, 2], [(0, 0), (0, 1), (1, 2), (2, 2)], directed=False), pairs=[(0, 2)])
    conn_rows("path P(4)", P(4), pairs=[(0, 3), (0, 1)])
    conn_rows("cycle C(5)", C(5), pairs=[(0, 2)])
    conn_rows("K(5)", K(5), pairs=[(0, 4)])
    conn_rows("Kb(3,3)", Kb(3, 3), pairs=[(0, 1), (0, 3)])
    conn_rows("wheel(5)", wheel(5), pairs=[(1, 3)])
    conn_rows("two triangles sharing a vertex", Net(range(5), [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)], directed=False),
              note="κ 1, λ 2", pairs=[(0, 4)])
    conn_rows("two K(4) joined by two edges", Net(range(8), [(i, j) for i in range(4) for j in range(i + 1, 4)] +
              [(i, j) for i in range(4, 8) for j in range(i + 1, 8)] + [(0, 4), (1, 5)], directed=False), pairs=[(2, 6)])
    conn_rows("disconnected", Net(range(4), [(0, 1), (2, 3)], directed=False), pairs=[(0, 3)])
    conn_rows("Petersen", named("petersen_graph"), pairs=[(0, 7)])
    conn_rows("hypercube Q(3)", hypercube(3), pairs=[(0, 7)])
    conn_rows("grid(3,4)", grid(3, 4), pairs=[(0, 11)])
    conn_rows("karate club", named("karate_club_graph"), pairs=[(0, 33)])
    conn_rows("directed: one edge", Net([0, 1], [(0, 1)]), pairs=[(0, 1), (1, 0)])
    conn_rows("directed: two-cycle", Net([0, 1], [(0, 1), (1, 0)]), pairs=[(0, 1)])
    conn_rows("directed: cycle Cd(4)", C(4, directed=True), pairs=[(0, 2)])
    conn_rows("directed: complete Kd(4)", K(4, directed=True), pairs=[(0, 3)])
    conn_rows("directed: adjacent pair counts the edge", Net([0, 1, 2], [(0, 1), (0, 2), (2, 1)]), pairs=[(0, 1), (1, 0)])
    conn_rows("directed: weakly but not strongly connected", Net(range(4), [(0, 1), (1, 2), (2, 0), (2, 3)]), pairs=[(3, 0), (0, 3)])
    conn_rows("directed: bidirected C(5)", Net(range(5), [(i, (i + 1) % 5) for i in range(5)] + [((i + 1) % 5, i) for i in range(5)]),
              pairs=[(0, 2)])
    conn_rows("directed: parallel arcs", Net([0, 1, 2], [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]), pairs=[(0, 1)])
    for call in ["vertexConnectivity(from: 0, to: 0)", "minimumVertexCut(from: 0, to: 0)", "edgeConnectivity(from: 0, to: 0)"]:
        trap("Preconditions", "connectivity: source is the target", P(3).text(), call, "source == target")

    # --- added after the critical review (FL-488 on): Int.max capacities in minimum-cost flow, the
    # artificial cost bound gone, small capacity types and floating point in the global cuts and
    # Gomory-Hu, and disjoint paths.
    imax = 2 ** 63 - 1
    mcf_rows("Int.max capacities, a negative cycle", M([0, 1], [(0, 1), (1, 0)], [imax, imax], [0, -1], {0: 5, 1: -5}),
             note="both arcs near Int.max (only the solver's own arcs are unbounded)")
    mcf_rows("Int.max capacities, the negative arc first", M([0, 1], [(0, 1), (1, 0)], [imax, imax], [-1, 0], {0: 5, 1: -5}))
    mcmf_rows("Int.max capacity against a negative arc", MM([1, 0], [(0, 1), (1, 0)], [3, imax], [-2, 0]), 1, 0,
              note="the value is Int.max, so the negative arc cannot be used")
    mcf_rows("Int8 costs on 130 vertices", M(list(range(130)), [(0, 1)], [1], [1], {0: 1, 1: -1}, ctype="Int8"),
             note="no bound on (n + 1) × the greatest cost")
    REVIEW = [(1, 5, 5), (2, 3, 16), (4, 7, 21), (4, 0, 3), (3, 7, 39), (6, 3, 33), (6, 0, 43), (2, 0, 46), (5, 0, 1), (6, 2, 39),
              (2, 6, 119), (6, 1, 12), (0, 7, 33), (7, 2, 20), (0, 4, 66), (4, 5, 24), (1, 3, 42), (5, 1, 10), (7, 3, 40), (1, 4, 22),
              (4, 7, 50), (4, 1, 20), (3, 0, 20), (3, 0, 12), (6, 3, 8), (3, 6, 1), (2, 3, 7)]
    review = Net(range(8), [(u, v) for u, v, _ in REVIEW], [c for _, _, c in REVIEW], directed=False, ctype="UInt8")
    global_rows("UInt8, every vertex within 255", review, note="a merged group's connection passes 255")
    fuzz = Net([6, 2, 3, 5, 4, 0, 1], [(2, 3), (3, 6), (6, 4), (2, 0), (2, 5), (6, 5), (5, 1), (4, 5)],
               [40, 63, 63, 63, 63, 63, 40, 63], directed=False, ctype="UInt8")
    global_rows("UInt8, labels shuffled", fuzz, note="the fuzzer's case: the greatest vertex sum 229")
    star = Net([0, 1, 2, 3], [(0, 1), (0, 2), (0, 3)], [200, 200, 200], directed=False, ctype="UInt8")
    global_rows("UInt8 star, the centre's sum past 255", star, note="the answer 200 fits")
    gh_rows("UInt8, every vertex within 255", review)
    gh_rows("UInt8 star, the centre's sum past 255", star)
    global_rows("directed: UInt8, the capacities into a vertex past 255", Net([0, 1, 2], [(1, 0), (2, 0), (0, 1), (0, 2), (1, 2), (2, 1)],
                [200, 200, 5, 5, 3, 3], ctype="UInt8"))
    global_rows("directed: UInt8, the review's edges as arcs", Net(range(8), [(u, v) for u, v, _ in REVIEW], [c for _, _, c in REVIEW], ctype="UInt8"))
    global_rows("Double cycle, ties", Net(range(4), [(i, (i + 1) % 4) for i in range(4)], [0.5] * 4, directed=False, ctype="Double"))
    global_rows("Double, one light edge", Net(range(4), [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)], [0.75, 0.25, 0.75, 0.5, 0.125], directed=False, ctype="Double"))
    global_rows("directed: Double", Net([0, 1, 2], [(0, 1), (1, 2), (2, 0), (1, 0)], [0.25, 0.5, 0.75, 0.125], ctype="Double"))

    # --- disjoint paths
    paths_rows("one edge", Net([0, 1], [(0, 1)]), 0, 1)
    paths_rows("no path", Net(range(4), [(0, 1), (2, 3)], directed=False), 0, 3)
    paths_rows("K(2) with parallel edges", Net([0, 1], [(0, 1), (0, 1), (1, 0)], directed=False), 0, 1, note="each copy an edge path, one vertex path")
    paths_rows("directed: adjacent pair", Net([0, 1, 2], [(0, 1), (0, 2), (2, 1)]), 0, 1, note="the edge counts as one path")
    paths_rows("directed: parallel arcs", Net([0, 1, 2], [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]), 2, 1)
    paths_rows("two triangles sharing a vertex", Net(range(5), [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)], directed=False), 0, 4,
               note="2 edge paths, 1 vertex path")
    paths_rows("CLRS figure 26.1, unit", Net(CLRS.labels, [(CLRS.lab(u), CLRS.lab(v)) for u, v in CLRS.E]), "s", "t")
    paths_rows("Petersen", named("petersen_graph"), 0, 7)
    paths_rows("grid(3,4)", grid(3, 4), 0, 11)
    paths_rows("directed: bidirected C(5)", Net(range(5), [(i, (i + 1) % 5) for i in range(5)] + [((i + 1) % 5, i) for i in range(5)]), 0, 2)
    paths_rows("self-loops and a cycle on the way", Net(range(4), [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]), 0, 3)
    for call in ["edgeDisjointPaths(from: 0, to: 0)", "vertexDisjointPaths(from: 0, to: 0)"]:
        trap("Preconditions", "disjoint paths: source is the target", P(3).text(), call, "source == target")
    wide = Net([0, 1, 2], [(0, 1), (1, 2)], [imax, imax], directed=False)
    global_rows("Int.max path", wide, note="the middle vertex's sum passes Int, so the sums run in Int128")
    gh_rows("Int.max path", wide)
    late = [(2, 0, 1), (4, 1, 1), (5, 2, 2), (4, 0, 2), (0, 5, 2), (3, 1, 3), (1, 0, 1)]
    global_rows("found only in a later phase", Net(range(6), [(u, v) for u, v, _ in late], [c for _, _, c in late], directed=False),
                note="Nagamochi–Ibaraki's first phase misses it")
    lateD = [(0, 3, 9), (0, 1, 8), (2, 3, 6), (2, 3, 8), (4, 0, 8), (4, 5, 8), (1, 5, 5)]
    global_rows("Double, found only in a later phase", Net(range(6), [(u, v) for u, v, _ in lateD], [c / 4 for _, _, c in lateD], directed=False, ctype="Double"),
                note="on the heap rather than the bucket queue")
    paths_rows("directed: a flow cycle the decomposition drops", Net(range(9), [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]), 5, 6)


def lcg_with_supply(net, supply):
    sup = [0] * net.n
    for k, b in supply.items():
        sup[k] = b
    net.supply = sup
    net.token = net.token + (f"; supply [{', '.join(f'{k}: {b}' for k, b in supply.items())}]" if supply else "; supply []")
    return net


# ---------------------------------------------------------------------------------------------
# Stress


def stress():
    rnd = random.Random(20261010)
    counts = {"flow": 0, "global": 0, "gh": 0, "mcf": 0, "conn": 0}
    for trial in range(600):
        n = rnd.randint(2, 9)
        directed = rnd.random() < 0.7
        m = rnd.randint(0, 3 * n)
        E = [(rnd.randrange(n), rnd.randrange(n)) for _ in range(m)]
        cap = [rnd.choice([0, 1, 1, 2, 3, 5, 8]) for _ in range(m)]
        net = Net(range(n), E, cap, directed=directed)
        s, t = rnd.sample(range(n), 2)
        v1, r1 = edmonds_karp(net, s, t)
        v2, r2 = dinic(net, s, t)
        v3, r3, pre = push_relabel(net, s, t)
        Ts = [sink_side(net, r, t) for r in (r1, r2, r3, pre)]
        bv, bT = brute_st_cut(net, s, t)
        if not (v1 == v2 == v3 == bv) or any(T != bT for T in Ts):
            fail(f"stress flow {trial}: {v1} {v2} {v3} {bv}")
        G = nx_flow_graph(net)
        _, (_, nT) = nx.minimum_cut(G, s, t)
        if set(nT) != bT:
            fail(f"stress flow {trial}: NetworkX sink side")
        counts["flow"] += 1
        if not directed:
            sw = stoer_wagner(net)
            if sw[0] != brute_global(net):
                fail(f"stress SW {trial}")
            counts["global"] += 1
            p, fl = gomory_hu(net)
            for a in range(n):
                for b in range(a + 1, n):
                    if tree_path_min(n, p, fl, a, b) != brute_st_cut(net, a, b)[0]:
                        fail(f"stress GH {trial}")
            T = nx.gomory_hu_tree(G) if G.number_of_nodes() else None
            mine = {frozenset((i, p[i])): fl[i] for i in range(1, n)}
            theirs = {frozenset((u, v)): d["weight"] for u, v, d in T.edges(data=True)}
            if mine != theirs:
                fail(f"stress GH {trial}: NetworkX tree differs")
            counts["gh"] += 1
        else:
            dg = directed_global(net)
            if dg[0] != brute_global(net):
                fail(f"stress directed global {trial}")
            counts["global"] += 1
        simple = Net(range(n), [(u, v) for u, v in set(E) if u != v and (directed or (v, u) not in set(E) or u < v)], directed=directed)
        k, cut = global_vertex(simple)
        if k != brute_kappa(simple) or k != nx.node_connectivity(nx_simple(simple)):
            fail(f"stress kappa {trial}")
        if len(cut) != k or (k < n - 1 and connected_without(simple, set(cut))):
            fail(f"stress vertex cut {trial}")
        if global_edge(simple) != nx.edge_connectivity(nx_simple(simple)):
            fail(f"stress lambda {trial}")
        counts["conn"] += 1
    for trial in range(400):
        n = rnd.randint(1, 6)
        m = rnd.randint(0, 7)
        E = [(rnd.randrange(n), rnd.randrange(n)) for _ in range(m)]
        cap = [rnd.randint(0, 3) for _ in range(m)]
        cost = [rnd.randint(-3, 5) for _ in range(m)]
        sup = [0] * n
        for _ in range(rnd.randint(0, 3)):
            a, b = rnd.randrange(n), rnd.randrange(n)
            q = rnd.randint(1, 3)
            sup[a] += q
            sup[b] -= q
        if rnd.random() < 0.1:
            sup[0] += 1
        net = Net(range(n), E, cap, cost, sup)
        res = mcf_net(net, sup)
        bf = brute_mcf(net, sup)
        if bf != "skip" and bf != (res[0] if res else None):
            fail(f"stress mcf {trial}: brute {bf} vs {res}")
        try:
            c, _ = nx.network_simplex(nx_mcf_graph(net, sup))
            if res is None or c != res[0]:
                fail(f"stress mcf {trial}: NetworkX {c} vs {res}")
        except nx.NetworkXUnfeasible:
            if res is not None:
                fail(f"stress mcf {trial}: NetworkX infeasible")
        counts["mcf"] += 1
    print("stress: " + ", ".join(f"{k} {v}" for k, v in counts.items()) + " random cases pass")


HEADER = """# Flows: case catalog (FL-001 – FL-{last}, {count} cases)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
igraph==1.0.0 --with rustworkx==0.18.1 python3 ref.py`; without `--write` it renders the catalog
and compares it with this file byte for byte; `--write` regenerates it; `--stress` adds about
1,000 random networks). Expected is the API's documented output (api.md, Determinism); the last
column says what each row was checked against.

## Notation

* **Networks.** `V [..]; E [..]`: vertices in order (their vertex indices), then edges at
  positions 0, 1, …, each `u→v c` (directed) or `u–v c` (undirected) with its capacity `c`, and
  `@w` its cost in minimum-cost rows. Edges without `c` have capacity 1 (connectivity rows take no
  capacities). A leading `Double`, `Int8` or `UInt8` is the capacity type (default `Int`).
  `supply [v: b, …]` lists the nonzero supplies (positive supplies, negative demands; LEMON's and
  OR-Tools' sign). Rows with parallel edges need a multigraph representation (`DirectedPseudograph`,
  `Pseudograph`) or an in-file conformer.
* **Generators.** `K(n)`: every pair i < j lexicographic; `Kd(n)`: every ordered pair i ≠ j, i then
  j ascending; `C(n)` / `Cd(n)`: edges i–(i+1) mod n; `P(n)`: the path i–(i+1); `Kb(a,b)`: left
  0..<a, right a..<a+b, row-major; `wheel(k)`: hub 0, spokes 0–i, then rim i–(i mod k + 1);
  `Q(d)`: the hypercube, edges i–(i xor 2^b) for i < i xor 2^b, i then b ascending; `grid(r,c)`:
  vertex i·c+j, edges right then down, row-major; `nx(name)`: NetworkX's graph, nodes and
  `edges()` in order. `lcgnet(n,m,seed,cmax)`: a 64-bit LCG, x ← x·6364136223846793005 +
  1442695040888963407 (mod 2⁶⁴), each draw x >> 33; an edge u→v is two draws (u = d % n, v =
  d % n), skipped when u = v (parallel and antiparallel edges kept), then its capacity
  1 + d % cmax, until m edges. `lcgund` is the same with undirected edges. `lcgcost(n,m,seed,cmax,
  lo,hi)` adds a third draw per edge, the cost lo + d % (hi − lo + 1).
* **Flows and cuts.** `value v` is the flow value. `S [..]; T [..]` are the cut's source and sink
  sides (vertices listed by index), the canonical cut: T is every vertex that can reach the sink
  in the residual network of a maximum flow (the least sink side of any minimum cut; NetworkX's and
  igraph's). `cut [..]` lists the edges from S to T by position, zero capacities included; on an
  undirected graph `3r` is edge 3 crossed against its stored order (the `DirectedView` arc with
  `reversed: true`). `flow [..]` gives each edge's flow by position; on an undirected graph the
  signed flow along the stored order (negative: against it). Only `edmondsKarpMaximumFlow` and the
  minimum-cost rows pin flows; other maximum flows are any maximum flow.
* **Global cuts.** `minimumCut(capacity:)` rows show the cut's sides only where they are pinned:
  where it is the only minimum cut (on an undirected graph, the only one with the first vertex on
  its source side), or, undirected, where the positive edges leave several components (the first
  vertex's component). Elsewhere "value v (one of several minimum cuts)": tests check the value,
  the cut's edges and value from its sides, and the first vertex on the source side (undirected).
* **Disjoint paths.** `k paths`: how many edge- or internally vertex-disjoint paths
  `edgeDisjointPaths` / `vertexDisjointPaths` return; which paths is not pinned, so tests check
  each one (a path from s to t along its edges) and that no edge (no inner vertex) repeats.
* **Gomory–Hu.** `edges [i–p c, …]`: the tree edge at position k joins vertex k+1 (by index) and its
  parent, with capacity c, the minimum cut value between them.
* **Minimum cost.** `cost c; flow [..]`: the least cost and each edge's flow. "(one of several
  optima)" means other flows have the same cost: tests then check the cost, feasibility and
  optimality, not the flow.
* **trap** rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Input | Call | Expected | Checked |
|---|---|---|---|---|---|---|
"""


def render():
    out = HEADER.replace("{last}", f"{len(CASES):03d}").replace("{count}", str(len(CASES)))
    for i, (grp, name, inp, call, exp, chk) in enumerate(CASES):
        out += f"| FL-{i + 1:03d} | {grp} | {name} | {inp} | `{call}` | {exp} | {chk} |\n"
    return out


def main():
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    if "--stress" in sys.argv:
        stress()
    build()
    if FAILS:
        print("\n".join(FAILS))
        sys.exit(1)
    text = render()
    path = os.path.join(here, "cases.md")
    if "--write" in sys.argv:
        open(path, "w").write(text)
    else:
        try:
            current = open(path).read()
        except FileNotFoundError:
            current = None
        if current != text:
            print("cases.md differs from the rendered catalog (run with --write)")
            sys.exit(1)
    print(f"{len(CASES)} cases; all values agree; cases.md matches")


if __name__ == "__main__":
    main()
