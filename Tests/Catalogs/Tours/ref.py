"""Tours phase 1: reference models and independent checks for every catalog row.

Run:  uv run --quiet --no-project --with networkx==3.7 --with igraph==1.0.0 --with rustworkx==0.18.1
      python3 Tests/Catalogs/Tours/ref.py [--stress] [--write]

Without --write the rendered catalog is compared with cases.md byte for byte (exit 1 on any
difference or failed check). --write regenerates cases.md. --stress adds random graphs (see
stress()).

Two optional native cross-checks, switched on by environment variables:

* IGRAPH_C_LIB=<path to libigraph.dylib / .so, igraph 1.0.0>. python-igraph 1.0.0 does not expose
  igraph_is_eulerian / igraph_eulerian_path / igraph_eulerian_cycle (no Graph method, and the C
  symbols are not linked into its extension), so the C library is called through ctypes in a
  separate worker process (`ref.py --igraph-worker`) that first installs
  igraph_error_handler_ignore, so an igraph error comes back as a return code and never aborts.
  Build: the igraph-1.0.0 release tarball, `cmake .. -DBUILD_SHARED_LIBS=ON` and
  `cmake --build . --target igraph`.
* JGRAPHT_CLASSPATH=<jgrapht-core-1.5.2.jar:jheaps-0.14.jar:apfloat-1.10.1.jar> (Maven Central).
  The embedded Java harness (JAVA_SOURCE) is compiled with javac into a temporary directory.

The Checked column never depends on whether these are present: each igraph and JGraphT claim is
computed from a Python model of that library's own procedure (igraph's Hierholzer with its
incidence order, JGraphT's TwoOptHeuristicTSP.improve, HeldKarpTSP.reconstructTour,
NearestNeighborHeuristicTSP's swap array), and the native run, when available, checks that the
model reproduces the library on every row. --write refuses to run without both, so every claim
in a committed cases.md was checked against the real libraries.

What decides Expected, per entry point (api.md, Determinism):

* isEulerian / hasEulerianTrail   the definitions: the vertices of nonzero degree lie in one
      (weakly) connected component, and every degree is even (in = out), or exactly two are odd
      (one vertex has out - in = 1 and one in - out = 1). Isolated vertices are ignored; an
      edgeless graph, the empty graph included, is Eulerian.
* eulerianCircuit() / eulerianTrail() / (from:)   Hierholzer's algorithm, pinned: from the start,
      take the first unused edge in the current vertex's incidentEdges (outEdges) order; when
      there is none, pop the vertex onto the output; the output reversed. Start: the first vertex
      of nonzero degree for a circuit (and for a trail of an Eulerian graph), the first odd vertex
      (undirected) or the vertex with out - in = 1 (directed) for a trail otherwise.
* hamiltonianPath / hamiltonianCycle   the first one a depth-first search meets: starts in
      vertices order (the cycle from the first vertex), each vertex's edges in incidentEdges
      (outEdges) order; a cycle closes through the first edge back to the start not already used.
      Equivalently the least by (start index, row index of each edge taken, row index of the
      closing edge): brute force over every permutation checks it (n <= 8), a bitmask DP
      checks existence (n <= 16).
* nearestNeighborTour   from the start, the nearest unvisited vertex, the first in vertices order
      on ties; the edges the lightest copy of each pair (the earliest on ties).
* christofidesTour   the canonical minimum spanning tree (SpanningTrees: weight, then position);
      its odd vertices in vertices order; minimumWeightMatching on their complete graph (pairs i < j
      lexicographic), which is NetworkX max_weight_matching(maxcardinality=True) on
      (1 + the greatest weight) - w with nodes in that order; the multigraph H of the tree edges
      (in position order) then the matched pairs (in that edge order); Hierholzer on H from the
      first vertex; first visits kept (shortcutting).
* twoOptTour(improving:)   JGraphT TwoOptHeuristicTSP.improve exactly: the tour as an array
      t[0..n] from the given tour's first vertex; repeat: the best move (i, j), 0 <= i < n - 2,
      i + 2 <= j < n, by the least change d(t_i, t_j) + d(t_i+1, t_j+1) - d(t_i, t_i+1) -
      d(t_j, t_j+1) < 0, the first (i, j) on ties; reverse t[i+1..j]; until no change is negative.
      twoOptTour(weight:) improves nearestNeighborTour from the first vertex.
* shortestTour   Held-Karp: the least weight Hamiltonian cycle of the simple graph, the
      lexicographically least by vertex index among the optimal ones when listed from the first
      vertex (JGraphT HeldKarpTSP's reconstruction). Checked by brute force over permutations.
* every tour: nil below three vertices; a Cycle of the graph through the lightest copies.
"""
import ctypes
import itertools
import json
import os
import random
import subprocess
import sys
import tempfile

try:
    import networkx as nx
    from networkx.algorithms import approximation as nxa
except ImportError:
    os.execvp("uv", ["uv", "run", "--quiet", "--no-project", "--with", "networkx==3.7", "--with", "igraph==1.0.0",
                     "--with", "rustworkx==0.18.1", "python3", *sys.argv])

FAILS = []


def fail(msg):
    FAILS.append(msg)


# ---------------------------------------------------------------------------------------------
# Graphs


class G:
    """Vertices 0..n-1 shown by `labels`; edges (u, v) by position, optional weights."""

    def __init__(self, labels, edges, directed=False, w=None, token=None, wtype="Int"):
        self.labels = list(labels)
        self.n = len(self.labels)
        self.index = {x: i for i, x in enumerate(self.labels)}
        self.E = [(self.index[u], self.index[v]) for u, v in edges]
        self.directed = directed
        self.w = list(w) if w is not None else None
        self.token = token
        self.wtype = wtype

    @property
    def m(self):
        return len(self.E)

    def lab(self, i):
        return self.labels[i]

    def multi(self):
        seen = set()
        for u, v in self.E:
            if u == v:
                return True
            k = (u, v) if self.directed else (min(u, v), max(u, v))
            if k in seen:
                return True
            seen.add(k)
        return False

    def rows(self, order="position"):
        """incidentEdges / outEdges rows as (edge, neighbor), a self-loop twice when undirected."""
        rows = [[] for _ in range(self.n)]
        for e, (u, v) in enumerate(self.E):
            rows[u].append((e, v))
            if not self.directed:
                rows[v].append((e, u))
        if order == "igraph":
            # igraph's incidence lists: neighbor ascending, then edge id descending, a loop once.
            out = []
            for v, r in enumerate(rows):
                seen, rr = set(), []
                for e, x in r:
                    if x == v and e in seen:
                        continue
                    seen.add(e)
                    rr.append((e, x))
                out.append(sorted(rr, key=lambda t: (t[1], -t[0])))
            return out
        return rows

    def text(self):
        if self.token:
            return self.token
        arrow = "→" if self.directed else "-"
        parts = []
        for e, (u, v) in enumerate(self.E):
            s = f"{self.lab(u)}{arrow}{self.lab(v)}"
            if self.w is not None:
                s += f" {fmtv(self.w[e])}"
            parts.append(s)
        kind = ""
        if self.multi():
            kind = "multigraph "
        if self.w is not None and self.wtype != "Int":
            kind = f"{self.wtype} " + kind
        return f"{kind}V [{', '.join(str(x) for x in self.labels)}]; E [{', '.join(parts)}]"


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


def lcgwalk(n, length, seed, directed=False, closed=True):
    """A random walk of `length` steps from vertex 0 (each next vertex d % n, staying allowed: a
    self-loop), its edges in walk order; closed: a last edge back to 0 is added unless the walk
    ended there. Eulerian (closed) or with an Eulerian trail (open) by construction."""
    g = LCG(seed)
    walk = [0]
    for _ in range(length):
        walk.append(g.next() % n)
    if closed and walk[-1] != 0:
        walk.append(0)
    E = [(walk[i], walk[i + 1]) for i in range(len(walk) - 1)]
    kind = "lcgwalkd" if directed else "lcgwalk"
    return G(range(n), E, directed, token=f"{kind}({n},{length},{seed}{'' if closed else ',open'})")


def lcg(n, m, seed, directed=False):
    """m edges u = d % n, v = d % n; u = v and repeated pairs skipped (simple)."""
    g = LCG(seed)
    E, seen = [], set()
    while len(E) < m:
        u, v = g.next() % n, g.next() % n
        k = (u, v) if directed else (min(u, v), max(u, v))
        if u == v or k in seen:
            continue
        seen.add(k)
        E.append((u, v))
    return G(range(n), E, directed, token=f"{'lcgd' if directed else 'lcg'}({n},{m},{seed})")


def K(n, directed=False, w=None, token=None, wtype="Int"):
    if directed:
        E = [(i, j) for i in range(n) for j in range(n) if i != j]
    else:
        E = [(i, j) for i in range(n) for j in range(i + 1, n)]
    return G(range(n), E, directed, w=w, token=token or (f"Kd({n})" if directed else f"K({n})"), wtype=wtype)


def C(n, directed=False):
    return G(range(n), [(i, (i + 1) % n) for i in range(n)], directed, token=f"Cd({n})" if directed else f"C({n})")


def P(n, directed=False):
    return G(range(n), [(i, i + 1) for i in range(n - 1)], directed, token=f"Pd({n})" if directed else f"P({n})")


def grid(r, c):
    E = []
    for i in range(r):
        for j in range(c):
            v = i * c + j
            if j + 1 < c:
                E.append((v, v + 1))
            if i + 1 < r:
                E.append((v, v + c))
    return G(range(r * c), E, token=f"grid({r},{c})")


def named(name, *args):
    h = getattr(nx, name)(*args)
    nodes = list(h.nodes())
    idx = {x: i for i, x in enumerate(nodes)}
    tok = f"nx({name}{''.join(',' + str(a) for a in args)})"
    return G(range(len(nodes)), [(idx[u], idx[v]) for u, v in h.edges()], token=tok)


def Kb(a, b):
    return G(range(a + b), [(i, a + j) for i in range(a) for j in range(b)], token=f"Kb({a},{b})")


def wheel(k):
    E = [(0, i) for i in range(1, k + 1)] + [(i, i % k + 1) for i in range(1, k + 1)]
    return G(range(k + 1), E, token=f"wheel({k})")


def knight(r, c):
    E = []
    for i in range(r):
        for j in range(c):
            for di, dj in ((1, 2), (2, 1), (2, -1), (1, -2)):
                a, b = i + di, j + dj
                if 0 <= a < r and 0 <= b < c:
                    E.append((i * c + j, a * c + b))
    return G(range(r * c), E, token=f"knight({r},{c})")


def tournament(n, seed):
    g = LCG(seed)
    E = []
    for i in range(n):
        for j in range(i + 1, n):
            E.append((i, j) if g.next() % 2 == 0 else (j, i))
    return G(range(n), E, True, token=f"tournament({n},{seed})")


def pts_graph(points, token):
    """The complete graph on the points, pairs i < j lexicographic, weight the Manhattan distance
    (a metric, exact in integers)."""
    n = len(points)
    E, W = [], []
    for i in range(n):
        for j in range(i + 1, n):
            E.append((i, j))
            W.append(abs(points[i][0] - points[j][0]) + abs(points[i][1] - points[j][1]))
    return G(range(n), E, w=W, token=token)


def lcgpts(n, seed, span):
    g = LCG(seed)
    pts = [(g.next() % span, g.next() % span) for _ in range(n)]
    return pts_graph(pts, f"lcgpts({n},{seed},{span})")


def lcgK(n, seed, wmax, wtype="Int"):
    """K(n) with weight 1 + d % wmax per edge (not metric in general)."""
    g = LCG(seed)
    E = [(i, j) for i in range(n) for j in range(i + 1, n)]
    W = [1 + g.next() % wmax for _ in E]
    if wtype == "Double":
        W = [x / 4 for x in W]
    return G(range(n), E, w=W, token=f"lcgK({n},{seed},{wmax}{'' if wtype == 'Int' else ',/4'})", wtype=wtype)


# ---------------------------------------------------------------------------------------------
# Eulerian model


def degrees(g):
    out, inn = [0] * g.n, [0] * g.n
    for u, v in g.E:
        out[u] += 1
        inn[v] += 1
    return out, inn


def edge_component_count(g):
    parent = list(range(g.n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for u, v in g.E:
        a, b = find(u), find(v)
        if a != b:
            parent[a] = b
    return len({find(u) for u, _ in g.E})


def euler_status(g):
    """(isEulerian, hasEulerianTrail, trail start or None)."""
    if g.m == 0:
        return True, True, (0 if g.n else None)
    if edge_component_count(g) != 1:
        return False, False, None
    out, inn = degrees(g)
    first = min(v for v in range(g.n) if out[v] + inn[v])
    if not g.directed:
        odd = [v for v in range(g.n) if (out[v] + inn[v]) % 2]
        if not odd:
            return True, True, first
        if len(odd) == 2:
            return False, True, odd[0]
        return False, False, None
    diff = [out[v] - inn[v] for v in range(g.n)]
    if all(d == 0 for d in diff):
        return True, True, first
    plus = [v for v in range(g.n) if diff[v] == 1]
    minus = [v for v in range(g.n) if diff[v] == -1]
    if len(plus) == 1 and len(minus) == 1 and all(d in (-1, 0, 1) for d in diff):
        return False, True, plus[0]
    return False, False, None


def hierholzer(g, start, rows):
    used = [False] * g.m
    ptr = [0] * g.n
    stack = [(start, None)]
    res = []
    while stack:
        v, e = stack[-1]
        r = rows[v]
        while ptr[v] < len(r) and used[r[ptr[v]][0]]:
            ptr[v] += 1
        if ptr[v] < len(r):
            f, w = r[ptr[v]]
            used[f] = True
            stack.append((w, f))
        else:
            stack.pop()
            res.append((v, e))
    res.reverse()
    return [x for x, _ in res], [e for _, e in res[1:]]


def deg(g, v):
    out, inn = degrees(g)
    return out[v] + inn[v]


def euler_circuit(g, start=None, order="position"):
    eu, _, _ = euler_status(g)
    if not eu or g.m == 0:
        return None
    if start is None:
        start = min(v for v in range(g.n) if deg(g, v))
    elif deg(g, start) == 0:
        return None
    vs, es = hierholzer(g, start, g.rows(order))
    return vs[:-1], es


def euler_trail(g, start=None, order="position"):
    eu, tr, s0 = euler_status(g)
    if not tr or g.n == 0:
        return None
    if g.m == 0:
        return ([0 if start is None else start], [])
    if start is None:
        start = s0
    elif eu:
        if deg(g, start) == 0:
            return None
    else:
        out, inn = degrees(g)
        if g.directed:
            if out[start] - inn[start] != 1:
                return None
        elif (out[start] + inn[start]) % 2 == 0:
            return None
    return hierholzer(g, start, g.rows(order))


def check_trail(g, vs, es, closed):
    """vs/es is a trail (closed: a circuit, start not repeated) that uses every edge once."""
    if sorted(es) != list(range(g.m)):
        return False
    k = len(es)
    if closed:
        if len(vs) != k:
            return False
    elif len(vs) != k + 1:
        return False
    for i, e in enumerate(es):
        a, b = vs[i], vs[(i + 1) % len(vs)] if closed else vs[i + 1]
        u, v = g.E[e]
        if g.directed:
            if (u, v) != (a, b):
                return False
        elif {u, v} != {a, b}:
            return False
    return True


def nx_graph(g):
    if g.directed:
        h = nx.MultiDiGraph() if g.multi() else nx.DiGraph()
    else:
        h = nx.MultiGraph() if g.multi() else nx.Graph()
    h.add_nodes_from(range(g.n))
    h.add_edges_from(g.E)
    return h


def nx_euler_facts(g):
    """NetworkX's answers, or the exception's name."""
    h = nx_graph(g)
    res = {}
    for name, f in (("is_eulerian", nx.is_eulerian), ("has_eulerian_path", nx.has_eulerian_path),
                    ("is_semieulerian", nx.is_semieulerian)):
        try:
            res[name] = f(h)
        except Exception as e:  # noqa: BLE001
            res[name] = type(e).__name__
    return res


def nx_sequence(walk_edges, multi):
    """NetworkX edges (u, v[, k]) to a vertex list."""
    if not walk_edges:
        return []
    vs = [walk_edges[0][0]]
    for t in walk_edges:
        vs.append(t[1])
    return vs


# ---------------------------------------------------------------------------------------------
# igraph C, through a worker process


IGRAPH_CALLS = []   # (n, E, directed, kind, expected) where expected is the igraph model's answer


def igraph_model(g, kind):
    """igraph_is_eulerian's (has_path, has_cycle), and igraph_eulerian_path / _cycle as (vertex
    list, edge list) by igraph's own procedure, or None for IGRAPH_ENOSOL."""
    eu, tr, _ = euler_status(g)
    if g.m == 0 or g.n <= 1:
        has_path, has_cycle = True, True
    else:
        has_path, has_cycle = tr, eu
    if kind == "is":
        return [has_path, has_cycle]
    if (kind == "path" and not has_path) or (kind == "cycle" and not has_cycle):
        return None
    if g.m == 0:
        return [[], []]
    out, inn = degrees(g)
    if g.directed:
        plus = [v for v in range(g.n) if out[v] - inn[v] == 1]
        s = plus[0] if (kind == "path" and plus) else min(v for v in range(g.n) if out[v] + inn[v])
    else:
        d = [out[v] + inn[v] for v in range(g.n)]
        odd = [v for v in range(g.n) if d[v] % 2]
        s = odd[0] if (kind == "path" and odd) else min(v for v in range(g.n) if d[v])
    vs, es = hierholzer(g, s, g.rows("igraph"))
    return [vs, es]


def igraph_claim(g, kind):
    ans = igraph_model(g, kind)
    IGRAPH_CALLS.append((g.n, g.E, g.directed, kind, ans))
    return ans


def igraph_worker():
    lib = ctypes.CDLL(os.environ["IGRAPH_C_LIB"])
    # First, before anything can fail: errors become return codes, never abort().
    lib.igraph_set_error_handler(ctypes.cast(lib.igraph_error_handler_ignore, ctypes.c_void_p))
    lib.igraph_set_warning_handler(None)
    lib.igraph_setup()
    lib.igraph_vector_int_size.restype = ctypes.c_int64

    class Vec(ctypes.Structure):
        _fields_ = [("b", ctypes.POINTER(ctypes.c_int64)), ("se", ctypes.POINTER(ctypes.c_int64)),
                    ("e", ctypes.POINTER(ctypes.c_int64))]

    def vec(xs):
        v = Vec()
        if lib.igraph_vector_int_init(ctypes.byref(v), ctypes.c_int64(len(xs))) != 0:
            raise RuntimeError("igraph_vector_int_init")
        for i, x in enumerate(xs):
            v.b[i] = x
        return v

    def tolist(v):
        return [v.b[i] for i in range(lib.igraph_vector_int_size(ctypes.byref(v)))]

    out = []
    for line in sys.stdin:
        n, E, directed, kind = json.loads(line)
        g = ctypes.create_string_buffer(4096)
        ev = vec([x for e in E for x in e])
        if lib.igraph_create(g, ctypes.byref(ev), ctypes.c_int64(n), ctypes.c_bool(directed)) != 0:
            out.append("create failed")
            continue
        if kind == "is":
            hp, hc = ctypes.c_bool(), ctypes.c_bool()
            rc = lib.igraph_is_eulerian(g, ctypes.byref(hp), ctypes.byref(hc))
            out.append([hp.value, hc.value] if rc == 0 else f"rc {rc}")
        else:
            e, vv = vec([]), vec([])
            rc = getattr(lib, "igraph_eulerian_" + kind)(g, ctypes.byref(e), ctypes.byref(vv))
            out.append([tolist(vv), tolist(e)] if rc == 0 else None)
        lib.igraph_vector_int_destroy(ctypes.byref(ev))
        lib.igraph_destroy(g)
    print(json.dumps(out))


def run_igraph():
    if not os.environ.get("IGRAPH_C_LIB"):
        return False
    payload = "".join(json.dumps([n, E, d, k]) + "\n" for n, E, d, k, _ in IGRAPH_CALLS)
    p = subprocess.run([sys.executable, os.path.abspath(__file__), "--igraph-worker"], input=payload,
                       capture_output=True, text=True, timeout=600)
    if p.returncode != 0:
        fail(f"igraph worker failed: {p.stderr[-500:]}")
        return True
    got = json.loads(p.stdout)
    for (n, E, d, k, want), have in zip(IGRAPH_CALLS, got):
        if want != have:
            fail(f"igraph model differs from igraph C ({k}, n={n}, directed={d}, E={E}): model {want}, igraph {have}")
    return True


# ---------------------------------------------------------------------------------------------
# JGraphT, through the Java harness


JAVA_SOURCE = r"""
import java.io.*;
import java.util.*;
import org.jgrapht.*;
import org.jgrapht.graph.*;
import org.jgrapht.alg.cycle.HierholzerEulerianCycle;
import org.jgrapht.alg.tour.*;

public class ToursCheck {
    static Graph<Integer, DefaultWeightedEdge> weighted(StringTokenizer t, boolean simple, boolean directed) {
        int n = Integer.parseInt(t.nextToken()), m = Integer.parseInt(t.nextToken());
        Graph<Integer, DefaultWeightedEdge> g = simple ? new SimpleWeightedGraph<>(DefaultWeightedEdge.class)
            : directed ? new DirectedWeightedPseudograph<>(DefaultWeightedEdge.class) : new WeightedPseudograph<>(DefaultWeightedEdge.class);
        for (int i = 0; i < n; i++) g.addVertex(i);
        for (int i = 0; i < m; i++) {
            int u = Integer.parseInt(t.nextToken()), v = Integer.parseInt(t.nextToken());
            double w = Double.parseDouble(t.nextToken());
            DefaultWeightedEdge e = g.addEdge(u, v);
            g.setEdgeWeight(e, w);
        }
        return g;
    }
    static String verts(GraphPath<Integer, ?> p) {
        if (p == null) return "null";
        StringBuilder b = new StringBuilder();
        for (Integer v : p.getVertexList()) { if (b.length() > 0) b.append(' '); b.append(v); }
        return b.toString();
    }
    public static void main(String[] a) throws IOException {
        BufferedReader r = new BufferedReader(new InputStreamReader(System.in));
        PrintWriter out = new PrintWriter(new BufferedWriter(new OutputStreamWriter(System.out)));
        String line;
        while ((line = r.readLine()) != null) {
            StringTokenizer t = new StringTokenizer(line);
            String op = t.nextToken();
            try {
                switch (op) {
                case "EUL": {
                    boolean directed = t.nextToken().equals("1");
                    int n = Integer.parseInt(t.nextToken()), m = Integer.parseInt(t.nextToken());
                    Graph<Integer, DefaultEdge> g = directed ? new DirectedPseudograph<>(DefaultEdge.class) : new Pseudograph<>(DefaultEdge.class);
                    for (int i = 0; i < n; i++) g.addVertex(i);
                    for (int i = 0; i < m; i++) g.addEdge(Integer.parseInt(t.nextToken()), Integer.parseInt(t.nextToken()));
                    HierholzerEulerianCycle<Integer, DefaultEdge> h = new HierholzerEulerianCycle<>();
                    boolean e = h.isEulerian(g);
                    String extra = "";
                    if (e && m > 0) {
                        GraphPath<Integer, DefaultEdge> c = h.getEulerianCycle(g);
                        boolean ok = c.getEdgeList().size() == m && new HashSet<>(c.getEdgeList()).size() == m
                            && c.getStartVertex().equals(c.getEndVertex());
                        extra = ok ? " valid" : " invalid";
                    }
                    out.println(e + extra);
                    break;
                }
                case "HK": {
                    boolean directed = t.nextToken().equals("1");
                    out.println(verts(new HeldKarpTSP<Integer, DefaultWeightedEdge>().getTour(weighted(t, false, directed))));
                    break;
                }
                case "NN": {
                    Integer s = Integer.valueOf(t.nextToken());
                    out.println(verts(new NearestNeighborHeuristicTSP<Integer, DefaultWeightedEdge>(s).getTour(weighted(t, true, false))));
                    break;
                }
                case "CHR": {
                    GraphPath<Integer, DefaultWeightedEdge> p = new ChristofidesThreeHalvesApproxMetricTSP<Integer, DefaultWeightedEdge>().getTour(weighted(t, true, false));
                    out.println(p.getWeight());
                    break;
                }
                case "TWO": {
                    Graph<Integer, DefaultWeightedEdge> g = weighted(t, true, false);
                    List<Integer> tour = new ArrayList<>();
                    while (t.hasMoreTokens()) tour.add(Integer.parseInt(t.nextToken()));
                    tour.add(tour.get(0));
                    GraphPath<Integer, DefaultWeightedEdge> init = new GraphWalk<>(g, tour, 0.0);
                    out.println(verts(new TwoOptHeuristicTSP<Integer, DefaultWeightedEdge>(1, new RandomTourTSP<>(new Random(1)), 1e-8).improveTour(init)));
                    break;
                }
                default: out.println("unknown");
                }
            } catch (RuntimeException e) { out.println("exception " + e.getClass().getSimpleName()); }
        }
        out.flush();
    }
}
"""

JG_CALLS = []   # (line, expected output line, description)


def jg_edges(g, simple):
    if simple:
        W = simple_weights(g)
        items = [(u, v, W[u][v][0]) for u in range(g.n) for v in range(u + 1, g.n) if W[u][v] is not None]
    else:
        items = [(u, v, g.w[e]) for e, (u, v) in enumerate(g.E)]
    return f"{g.n} {len(items)} " + " ".join(f"{u} {v} {float(w)!r}" for u, v, w in items)


def jg_claim(line, expected, what):
    JG_CALLS.append((line, expected, what))


def run_jgrapht():
    cp = os.environ.get("JGRAPHT_CLASSPATH")
    if not cp:
        return False
    d = tempfile.mkdtemp(prefix="tours-jgrapht-")
    with open(os.path.join(d, "ToursCheck.java"), "w") as f:
        f.write(JAVA_SOURCE)
    p = subprocess.run(["javac", "-cp", cp, "-d", d, os.path.join(d, "ToursCheck.java")], capture_output=True, text=True, timeout=300)
    if p.returncode != 0:
        fail(f"javac failed: {p.stderr[-500:]}")
        return True
    payload = "".join(line + "\n" for line, _, _ in JG_CALLS)
    p = subprocess.run(["java", "-cp", d + os.pathsep + cp, "ToursCheck"], input=payload, capture_output=True, text=True, timeout=1200)
    got = p.stdout.splitlines()
    if len(got) != len(JG_CALLS):
        fail(f"JGraphT harness returned {len(got)} lines for {len(JG_CALLS)} calls: {p.stderr[-500:]}")
        return True
    for (line, want, what), have in zip(JG_CALLS, got):
        if callable(want):
            msg = want(have)
            if msg:
                fail(f"JGraphT {what}: {msg} ({line[:120]})")
        elif want != have:
            fail(f"JGraphT {what}: model {want!r}, JGraphT {have!r} ({line[:120]})")
    return True


# ---------------------------------------------------------------------------------------------
# Hamiltonian model


def ham_search(g, starts, target=None, cycle=False):
    """The first Hamiltonian path (or cycle) of the depth-first search. Pruning (a vertex no
    longer reachable) only cuts dead subtrees, so it never changes which one is first."""
    n = g.n
    rows = g.rows()
    for s in starts:
        if n == 1:
            if cycle:
                for e, x in rows[s]:
                    if x == s:
                        return [s], [e]
                return None
            if target is None or target == s:
                return [s], []
            return None
        if target is not None and target == s:
            continue
        visited = [False] * n
        visited[s] = True
        path, edges = [s], []
        ptr = [0]
        while ptr:
            v = path[-1]
            r = rows[v]
            if len(path) == n:
                ok = None
                if cycle:
                    used = set(edges)
                    for e, x in r:
                        if x == s and e not in used:
                            ok = e
                            break
                    if ok is not None:
                        return path[:], edges + [ok]
                elif target is None or v == target:
                    return path[:], edges[:]
                # backtrack
                ptr.pop()
                visited[path.pop()] = False
                if edges:
                    edges.pop()
                continue
            k = ptr[-1]
            advanced = False
            while k < len(r):
                e, x = r[k]
                k += 1
                if not visited[x] and (target is None or x != target or len(path) == n - 1):
                    ptr[-1] = k
                    visited[x] = True
                    if reachable_ok(g, rows, visited, x, s if cycle else None, target):
                        path.append(x)
                        edges.append(e)
                        ptr.append(0)
                        advanced = True
                        break
                    visited[x] = False
            if not advanced:
                ptr.pop()
                visited[path.pop()] = False
                if edges:
                    edges.pop()
    return None


def reachable_ok(g, rows, visited, cur, start, target):
    """Every unvisited vertex reachable from `cur` through unvisited vertices (and, for a cycle,
    the start reachable back: checked only at the end). A sound prune."""
    n = g.n
    left = n - sum(visited)
    if left == 0:
        return True
    seen = {cur}
    stack = [cur]
    count = 0
    while stack:
        v = stack.pop()
        for _, x in rows[v]:
            if not visited[x] and x not in seen:
                seen.add(x)
                count += 1
                stack.append(x)
    if count != left:
        return False
    return True


def ham_path(g, start=None, target=None):
    if g.n == 0:
        return None
    starts = range(g.n) if start is None else [start]
    return ham_search(g, starts, target)


def ham_cycle(g):
    if g.n == 0:
        return None
    return ham_search(g, [0], cycle=True)


def row_index(rows, v, e, x):
    for k, (f, y) in enumerate(rows[v]):
        if f == e and y == x:
            return k
    raise AssertionError


def ham_brute(g, start=None, target=None, cycle=False):
    """The least by (start, row index of each edge, closing row index) over every Hamiltonian
    path / cycle, by enumeration (independent of the search)."""
    rows = g.rows()
    n = g.n
    best = None
    if n == 0:
        return None
    if cycle:
        perms = ([0] + list(p) for p in itertools.permutations(range(1, n)))
    else:
        perms = (list(p) for p in itertools.permutations(range(n)))
    for perm in perms:
        if start is not None and perm[0] != start:
            continue
        if target is not None and perm[-1] != target:
            continue
        steps = []
        for i in range(n - 1):
            a, b = perm[i], perm[i + 1]
            steps.append([(k, e) for k, (e, x) in enumerate(rows[a]) if x == b])
            if not steps[-1]:
                break
        else:
            for choice in itertools.product(*steps):
                es = [e for _, e in choice]
                if len(set(es)) != len(es):
                    continue
                key = [perm[0]] + [k for k, _ in choice]
                res = (perm, es)
                if cycle:
                    last = perm[-1]
                    close = [(k, e) for k, (e, x) in enumerate(rows[last]) if x == perm[0] and e not in es]
                    if not close:
                        continue
                    key.append(close[0][0])
                    res = (perm, es + [close[0][1]])
                if best is None or key < best[0]:
                    best = (key, res)
    return None if best is None else best[1]


def ham_dp_exists(g, cycle=False, start=None, target=None):
    """Existence by a bitmask DP over the simple underlying graph (cycles of length 1 and 2 by
    the edges themselves)."""
    n = g.n
    if n == 0:
        return False
    if cycle and n == 1:
        return any(u == v for u, v in g.E)
    if cycle and n == 2:
        if g.directed:
            return (0, 1) in g.E and (1, 0) in g.E
        return sum(1 for u, v in g.E if u != v) >= 2
    adj = [set() for _ in range(n)]
    for u, v in g.E:
        if u != v:
            adj[u].add(v)
            if not g.directed:
                adj[v].add(u)
    full = (1 << n) - 1
    srcs = [0] if cycle else (range(n) if start is None else [start])
    for s in srcs:
        reach = {(1 << s, s)}
        frontier = [(1 << s, s)]
        dp = [set() for _ in range(1 << n)]
        dp[1 << s].add(s)
        for mask in range(1 << n):
            if not (mask >> s) & 1:
                continue
            for v in dp[mask]:
                for x in adj[v]:
                    if not (mask >> x) & 1:
                        dp[mask | (1 << x)].add(x)
        for v in dp[full]:
            if cycle and s in adj[v]:
                return True
            if not cycle and (target is None or v == target):
                return True
        del reach, frontier
    return False


# ---------------------------------------------------------------------------------------------
# Tours


def simple_weights(g):
    """W[u][v] = (weight, position) of the lightest copy (the earliest on ties), None if absent."""
    W = [[None] * g.n for _ in range(g.n)]
    for e, (u, v) in enumerate(g.E):
        if u == v:
            continue
        c = (g.w[e], e)
        for a, b in ((u, v), (v, u)):
            if W[a][b] is None or c < W[a][b]:
                W[a][b] = c
    return W


def complete(g):
    W = simple_weights(g)
    return all(W[u][v] is not None for u in range(g.n) for v in range(g.n) if u != v)


def tour_of(g, order):
    W = simple_weights(g)
    es = [W[order[i]][order[(i + 1) % len(order)]][1] for i in range(len(order))]
    total = type(g.w[0])(0) if g.w else 0
    for e in es:
        total = total + g.w[e]
    return order, es, total


def tour_weight(W, order):
    return sum(W[order[i]][order[(i + 1) % len(order)]][0] for i in range(len(order)))


def nearest_neighbor(g, start=0):
    if g.n < 3:
        return None
    W = simple_weights(g)
    order, seen = [start], {start}
    while len(order) < g.n:
        cur = order[-1]
        best = None
        for v in range(g.n):
            if v not in seen and (best is None or W[cur][v][0] < W[cur][best][0]):
                best = v
        order.append(best)
        seen.add(best)
    return order


def nn_ties(g, start=0):
    """Whether some step of nearest neighbour had a tie for the nearest."""
    W = simple_weights(g)
    order, seen = [start], {start}
    tie = False
    while len(order) < g.n:
        cur = order[-1]
        ws = sorted(W[cur][v][0] for v in range(g.n) if v not in seen)
        if len(ws) > 1 and ws[0] == ws[1]:
            tie = True
        best = min((v for v in range(g.n) if v not in seen), key=lambda v: (W[cur][v][0], v))
        order.append(best)
        seen.add(best)
    return tie


def jgrapht_nn_model(g, s):
    """NearestNeighborHeuristicTSP(first) step for step: the swap array over vertexSet order."""
    W = simple_weights(g)
    n = g.n
    path = list(range(n)) + [None]
    path[0], path[s] = path[s], path[0]
    for i in range(1, n - 1):
        v = path[i - 1]
        closest, best = -1, None
        for j in range(i, n):
            d = W[v][path[j]][0]
            if best is None or d < best:
                closest, best = j, d
        path[i], path[closest] = path[closest], path[i]
    path[n] = path[0]
    return path


def two_opt(g, order):
    """JGraphT TwoOptHeuristicTSP.improve, best improvement, the first (i, j) on ties."""
    W = simple_weights(g)
    n = len(order)
    t = list(order) + [order[0]]

    def d(a, b):
        return W[a][b][0]

    while True:
        best, bi, bj = None, -1, -1
        for i in range(n - 2):
            for j in range(i + 2, n):
                ci, ci1, cj, cj1 = t[i], t[i + 1], t[j], t[j + 1]
                change = d(ci, cj) + d(ci1, cj1) - d(ci, ci1) - d(cj, cj1)
                if change < 0 and (best is None or change < best):
                    best, bi, bj = change, i, j
        if bi < 0:
            return t[:n]
        t[bi + 1:bj + 1] = reversed(t[bi + 1:bj + 1])


def two_opt_optimal(g, order):
    W = simple_weights(g)
    n = len(order)
    for i in range(n):
        for j in range(i + 2, n):
            if i == 0 and j == n - 1:
                continue
            a, b, c, e = order[i], order[i + 1], order[j], order[(j + 1) % n]
            if W[a][c][0] + W[b][e][0] < W[a][b][0] + W[c][e][0]:
                return False
    return True


def kruskal(g):
    """The canonical minimum spanning forest: (weight, position), loops skipped."""
    parent = list(range(g.n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    tree = []
    for e in sorted((e for e, (u, v) in enumerate(g.E) if u != v), key=lambda e: (g.w[e], e)):
        u, v = g.E[e]
        a, b = find(u), find(v)
        if a != b:
            parent[a] = b
            tree.append(e)
    return tree


def our_matching(W, odd, floating):
    """MatchingModule.minimumWeightMatching on the complete graph over `odd` (pairs i < j
    lexicographic): NetworkX max_weight_matching on (1 + the greatest weight) - w, nodes in that
    order, maxcardinality, which MatchingModule follows operation for operation."""
    if not odd:
        return []
    pairs = [(a, b) for i, a in enumerate(odd) for b in odd[i + 1:]]
    top = max(W[a][b][0] for a, b in pairs)
    inv = nx.Graph()
    inv.add_nodes_from(odd)
    for a, b in pairs:
        inv.add_edge(a, b, weight=(1 + top) - W[a][b][0])
    mate = nx.max_weight_matching(inv, maxcardinality=True)
    chosen = sorted((min(a, b), max(a, b)) for a, b in mate)
    order = {p: k for k, p in enumerate(pairs)}
    return sorted(chosen, key=lambda p: order[p])


def brute_matching_weight(W, odd):
    if not odd:
        return 0
    a = odd[0]
    best = None
    for k in range(1, len(odd)):
        b = odd[k]
        rest = odd[1:k] + odd[k + 1:]
        w = W[a][b][0] + brute_matching_weight(W, rest)
        if best is None or w < best:
            best = w
    return best


def christofides(g):
    """The pinned procedure; returns (order, tree, odd, matching)."""
    if g.n < 3:
        return None
    W = simple_weights(g)
    tree = kruskal(g)
    tdeg = [0] * g.n
    for e in tree:
        u, v = g.E[e]
        tdeg[u] += 1
        tdeg[v] += 1
    odd = [v for v in range(g.n) if tdeg[v] % 2]
    match = our_matching(W, odd, g.wtype == "Double")
    H = G(range(g.n), [g.E[e] for e in sorted(tree)] + match)
    vs, _ = hierholzer(H, 0, H.rows())
    order, seen = [], set()
    for v in vs:
        if v not in seen:
            seen.add(v)
            order.append(v)
    return order, tree, odd, match


def held_karp(g):
    """The least-weight tour, lexicographically least from vertex 0 among the optimal ones, as
    JGraphT HeldKarpTSP reconstructs it; None when there is none (or n < 3)."""
    n = g.n
    if n < 3:
        return None
    W = simple_weights(g)
    INF = None
    full = (1 << n) - 1
    memo = {}

    def c(prev, state):
        key = (prev, state)
        if key in memo:
            return memo[key]
        if state == full:
            r = W[prev][0][0] if W[prev][0] is not None else INF
        else:
            r = INF
            for i in range(n):
                if not (state >> i) & 1 and W[prev][i] is not None:
                    sub = c(i, state | (1 << i))
                    if sub is not INF:
                        val = W[prev][i][0] + sub
                        if r is INF or val < r:
                            r = val
        memo[key] = r
        return r

    total = c(0, 1)
    if total is INF:
        return None
    order, last, state = [0], 0, 1
    for _ in range(1, n):
        for node in range(1, n):
            if not (state >> node) & 1 and W[last][node] is not None:
                sub = c(node, state | (1 << node))
                if sub is not INF and sub + W[last][node][0] == c(last, state):
                    order.append(node)
                    state |= 1 << node
                    last = node
                    break
    return order


def brute_tsp(g):
    """Optimum and the lexicographically least optimal tour from vertex 0, by permutations."""
    W = simple_weights(g)
    best = None
    for p in itertools.permutations(range(1, g.n)):
        order = [0] + list(p)
        if any(W[order[i]][order[(i + 1) % g.n]] is None for i in range(g.n)):
            continue
        w = tour_weight(W, order)
        if best is None or w < best[0] or (w == best[0] and order < best[1]):
            best = (w, order)
    return best


def is_metric(g):
    W = simple_weights(g)
    n = g.n
    return all(W[a][c][0] <= W[a][b][0] + W[b][c][0] for a in range(n) for b in range(n) for c in range(n)
               if len({a, b, c}) == 3)


# ---------------------------------------------------------------------------------------------
# Rows


CASES = []


def add(group, name, inp, call, expected, checks):
    CASES.append((group, name, inp, call, expected, "; ".join(c for c in checks if c)))


def labs(g, xs):
    return fmtl(g.lab(x) for x in xs)


def show_walk(g, kind, res, weight=False):
    if res is None:
        return "nil"
    vs, es = res
    s = f"{kind} {labs(g, vs)}; edges {fmtl(es)}"
    if weight:
        total = 0 if g.wtype == "Int" else 0.0
        for e in es:
            total = total + g.w[e]
        s += f"; weight {fmtv(total)}"
    return s


def nx_note(g, facts, key, ours):
    v = facts[key]
    if isinstance(v, str):
        return f"NetworkX {key} raises {v}"
    if v == ours:
        return f"= NetworkX {key}"
    return f"NetworkX {key} {v} (isolated vertices count there)" if isolated_with_edges_or_two(g) else f"NetworkX {key} {v}"


def isolated_with_edges_or_two(g):
    out, inn = degrees(g)
    return any(out[v] + inn[v] == 0 for v in range(g.n)) and g.n > 1


def jg_euler_expect(g):
    eu, _, _ = euler_status(g)
    want = "false" if g.n == 0 else ("true" if eu else "false")
    if want == "true" and g.m > 0:
        want += " valid"
    return want


def euler_rows(group_suffix, name, g, which="ITCP"):
    """isEulerian, hasEulerianTrail, eulerianCircuit(), eulerianTrail() for one graph."""
    inp = g.text()
    eu, tr, _ = euler_status(g)
    facts = nx_euler_facts(g)
    jg_line = f"EUL {1 if g.directed else 0} {g.n} {g.m} " + " ".join(f"{u} {v}" for u, v in g.E)
    if "I" in which:
        hp, hc = igraph_claim(g, "is")
        checks = [nx_note(g, facts, "is_eulerian", eu),
                  "= igraph has_cycle" if hc == eu else f"igraph has_cycle {str(hc).lower()}",
                  ("= JGraphT isEulerian" if (g.n > 0 or not eu) else "JGraphT isEulerian false (null graph)")]
        jg_claim(jg_line, jg_euler_expect(g), "HierholzerEulerianCycle")
        add("IsEulerian" + group_suffix, name, inp, "isEulerian", str(eu).lower(), checks)
    if "T" in which:
        hp, hc = igraph_model(g, "is")
        checks = [nx_note(g, facts, "has_eulerian_path", tr),
                  "= igraph has_path" if hp == tr else f"igraph has_path {str(hp).lower()}"]
        add("HasEulerianTrail" + group_suffix, name, inp, "hasEulerianTrail", str(tr).lower(), checks)
    if "C" in which:
        res = euler_circuit(g)
        checks = []
        if res is not None:
            if not check_trail(g, res[0], res[1], True):
                fail(f"{name}: circuit invalid")
            checks.append("a circuit through every edge")
        ig = igraph_claim(g, "cycle")
        if ig is None:
            checks.append("igraph eulerian_cycle: no solution")
        elif res is None:
            checks.append("igraph eulerian_cycle: zero-length (no edges)" if g.m == 0 else "igraph eulerian_cycle differs")
        elif ig[1] == res[1]:
            checks.append("= igraph eulerian_cycle")
        else:
            checks.append("igraph eulerian_cycle: another circuit (its rows: neighbor order, then edge id descending)")
        checks.append(nx_circuit_note(g, res))
        add("EulerianCircuit" + group_suffix, name, inp, "eulerianCircuit()", show_walk(g, "circuit", res), checks)
    if "P" in which:
        res = euler_trail(g)
        checks = []
        if res is not None and g.m > 0:
            if not check_trail(g, res[0], res[1], False):
                fail(f"{name}: trail invalid")
            checks.append("a trail through every edge")
        ig = igraph_claim(g, "path")
        if ig is None:
            checks.append("igraph eulerian_path: no solution")
        elif res is None:
            checks.append("igraph eulerian_path: zero-length (no vertex)")
        elif g.m == 0:
            checks.append("igraph eulerian_path: zero-length")
        elif ig[1] == res[1] and ig[0] == res[0]:
            checks.append("= igraph eulerian_path")
        else:
            checks.append("igraph eulerian_path: another trail (its rows)")
        checks.append(nx_trail_note(g, res))
        add("EulerianTrail" + group_suffix, name, inp, "eulerianTrail()", show_walk(g, "trail", res), checks)


def nx_circuit_note(g, res):
    h = nx_graph(g)
    try:
        if g.n and nx.is_eulerian(h):
            src = res[0][0] if res else 0
            out = list(nx.eulerian_circuit(h, source=src, keys=True)) if h.is_multigraph() else list(nx.eulerian_circuit(h, source=src))
            if len(out) != g.m:
                fail("NetworkX circuit length")
            if res is not None and not g.multi() and not g.directed:
                vs = nx_sequence(out, False)
                # NetworkX lists an undirected circuit backward (its pop order).
                if vs[::-1][:-1] == res[0]:
                    return "= NetworkX eulerian_circuit(source:) reversed"
                return "NetworkX eulerian_circuit: another circuit"
            return "NetworkX eulerian_circuit: a circuit as long" if g.m else "NetworkX eulerian_circuit: no edges"
        if not g.n:
            return "NetworkX raises NetworkXPointlessConcept"
        return "NetworkX: not Eulerian (it counts isolated vertices)" if euler_status(g)[0] else "NetworkX: not Eulerian"
    except nx.NetworkXException as e:
        return f"NetworkX raises {type(e).__name__}"


def nx_trail_note(g, res):
    h = nx_graph(g)
    try:
        if not g.n:
            nx.has_eulerian_path(h)
        if not nx.has_eulerian_path(h):
            return "NetworkX: no Eulerian path (it counts isolated vertices)" if euler_status(g)[1] else "NetworkX: no Eulerian path"
        src = res[0][0] if res else None
        out = list(nx.eulerian_path(h, source=src)) if src is not None else list(nx.eulerian_path(h))
        if len(out) != g.m:
            fail("NetworkX path length")
        if res is not None and g.m and not g.multi() and not g.directed:
            if nx_sequence(out, False) == res[0]:
                return "= NetworkX eulerian_path(source:)"
            return "NetworkX eulerian_path: another trail"
        return "NetworkX eulerian_path: a trail as long" if g.m else "NetworkX eulerian_path: no edges"
    except nx.NetworkXException as e:
        return f"NetworkX raises {type(e).__name__}"


def circuit_from_rows(group, name, g, start, note=None):
    res = euler_circuit(g, start)
    checks = []
    if res is not None:
        if not check_trail(g, res[0], res[1], True) or res[0][0] != start:
            fail(f"{name}: circuit(from:) invalid")
        checks.append("a circuit through every edge, from the start")
        checks.append(nx_circuit_note(g, res))
    elif note:
        checks.append(note)
    add(group, name, g.text(), f"eulerianCircuit(from: {g.lab(start)})", show_walk(g, "circuit", res), checks)


def trail_from_rows(group, name, g, start, note=None):
    res = euler_trail(g, start)
    checks = []
    if res is not None:
        if g.m and (not check_trail(g, res[0], res[1], False) or res[0][0] != start):
            fail(f"{name}: trail(from:) invalid")
        checks.append("a trail through every edge, from the start" if g.m else "the trivial trail")
        h = nx_graph(g)
        try:
            if nx.has_eulerian_path(h, source=start):
                checks.append("= NetworkX has_eulerian_path(source:)")
            else:
                checks.append("NetworkX has_eulerian_path(source:) False")
        except nx.NetworkXException as e:
            checks.append(f"NetworkX raises {type(e).__name__}")
    else:
        h = nx_graph(g)
        try:
            checks.append("= NetworkX has_eulerian_path(source:)" if not nx.has_eulerian_path(h, source=start) else "NetworkX has_eulerian_path(source:) True")
        except nx.NetworkXException as e:
            checks.append(f"NetworkX raises {type(e).__name__}")
    if note:
        checks.append(note)
    add(group, name, g.text(), f"eulerianTrail(from: {g.lab(start)})", show_walk(g, "trail", res), checks)


def trap(group, name, inp, call, reason, checks=""):
    add(group, name, inp, call, f"trap: {reason}", [checks])


def ham_rows(name, g, which="PC", note=None):
    inp = g.text()
    suf = "Directed" if g.directed else ""
    if "P" in which:
        res = ham_path(g)
        checks = [check_ham(g, res, "path")]
        if g.n <= 8:
            b = ham_brute(g)
            if (b is None) != (res is None) or (b is not None and (b[0], b[1]) != (res[0], res[1])):
                fail(f"{name}: path brute {b} vs {res}")
            checks.append("= the least by brute force")
        if g.n <= 16:
            if ham_dp_exists(g) != (res is not None):
                fail(f"{name}: path DP")
            checks.append("existence = bitmask DP")
        if note:
            checks.append(note)
        add("HamiltonianPath" + suf, name, inp, "hamiltonianPath()", show_walk(g, "path", res), checks)
    if "C" in which:
        res = ham_cycle(g)
        checks = [check_ham(g, res, "cycle")]
        if g.n <= 8:
            b = ham_brute(g, cycle=True)
            if (b is None) != (res is None) or (b is not None and (b[0], b[1]) != (res[0], res[1])):
                fail(f"{name}: cycle brute {b} vs {res}")
            checks.append("= the least by brute force")
        if g.n <= 16:
            if ham_dp_exists(g, cycle=True) != (res is not None):
                fail(f"{name}: cycle DP")
            checks.append("existence = bitmask DP")
        if note:
            checks.append(note)
        add("HamiltonianCycle" + suf, name, inp, "hamiltonianCycle()", show_walk(g, "cycle", res), checks)


def check_ham(g, res, kind):
    if res is None:
        return ""
    vs, es = res
    if sorted(vs) != list(range(g.n)) or len(set(es)) != len(es):
        fail(f"hamiltonian {kind} invalid {res}")
    k = len(vs)
    for i, e in enumerate(es):
        a = vs[i]
        b = vs[(i + 1) % k] if kind == "cycle" else vs[i + 1]
        u, v = g.E[e]
        if (g.directed and (u, v) != (a, b)) or (not g.directed and {u, v} != {a, b}):
            fail(f"hamiltonian {kind} edge {e} does not join {a}, {b}")
    return f"a Hamiltonian {kind}"


def ham_from_rows(name, g, s, t=None):
    res = ham_path(g, s, t)
    checks = [check_ham(g, res, "path")]
    if g.n <= 8:
        b = ham_brute(g, start=s, target=t)
        if (b is None) != (res is None) or (b is not None and (b[0], b[1]) != (res[0], res[1])):
            fail(f"{name}: path(from:) brute {b} vs {res}")
        checks.append("= the least by brute force")
    if g.n <= 16 and (t is None or s != t or g.n == 1):
        if ham_dp_exists(g, start=s, target=t) != (res is not None):
            fail(f"{name}: path(from:) DP")
        checks.append("existence = bitmask DP")
    call = f"hamiltonianPath(from: {g.lab(s)})" if t is None else f"hamiltonianPath(from: {g.lab(s)}, to: {g.lab(t)})"
    add("HamiltonianPathFrom" + ("Directed" if g.directed else ""), name, g.text(), call, show_walk(g, "path", res), checks)


def tour_text(g, order):
    if order is None:
        return "nil"
    vs, es, total = tour_of(g, order)
    return f"cycle {labs(g, vs)}; edges {fmtl(es)}; weight {fmtv(total)}"


def opt_note(g):
    if g.n < 3 or not g.n <= 9:
        return ""
    b = brute_tsp(g)
    return f"optimum {fmtv(b[0])}" if b else ""


def nx_simple_weighted(g):
    W = simple_weights(g)
    h = nx.Graph()
    h.add_nodes_from(range(g.n))
    for u in range(g.n):
        for v in range(u + 1, g.n):
            if W[u][v] is not None:
                h.add_edge(u, v, weight=W[u][v][0])
    return h


def nn_rows(name, g, start=None):
    s = 0 if start is None else start
    order = nearest_neighbor(g, s)
    checks = []
    if order is not None:
        h = nx_simple_weighted(g)
        nxo = nxa.greedy_tsp(h, source=s)[:-1]
        checks.append("= NetworkX greedy_tsp(source:)" if nxo == order else f"NetworkX greedy_tsp(source:) {labs(g, nxo)} (its tie order)")
        jm = jgrapht_nn_model(g, s)
        jg_claim(f"NN {s} " + jg_edges(g, True), " ".join(str(x) for x in jm), "NearestNeighborHeuristicTSP")
        checks.append("= JGraphT NearestNeighborHeuristicTSP(first)" if jm[:-1] == order else f"JGraphT NearestNeighborHeuristicTSP(first) {labs(g, jm[:-1])} (its swap-array tie order)")
        checks.append(opt_note(g))
    call = "nearestNeighborTour(weight:)" if start is None else f"nearestNeighborTour(from: {g.lab(s)}, weight:)"
    add("NearestNeighborTour", name, g.text(), call, tour_text(g, order), checks)


def christofides_rows(name, g):
    r = christofides(g)
    checks = []
    if r is not None:
        order, tree, odd, match = r
        W = simple_weights(g)
        if len(odd) <= 12:
            mw = sum(W[a][b][0] for a, b in match)
            if mw != brute_matching_weight(W, odd):
                fail(f"{name}: matching not minimum")
            checks.append(f"matching {', '.join(f'{g.lab(a)}-{g.lab(b)}' for a, b in match) or 'none'} minimum by brute force")
        h = nx_simple_weighted(g)
        nxt = nx.minimum_spanning_tree(h)
        tw = sum(g.w[e] for e in tree)
        if nxt.size(weight="weight") != tw:
            fail(f"{name}: tree weight vs NetworkX")
        checks.append("tree weight = NetworkX minimum_spanning_tree")
        nxtour = nxa.christofides(h)[:-1]
        ours_w = tour_weight(W, order)
        nx_w = tour_weight(W, nxtour)
        if sorted(nxtour) != list(range(g.n)):
            fail("NetworkX christofides tour")
        same = nxtour == order or nxtour == [order[0]] + order[1:][::-1] or (nxtour[0] == order[0] and False)
        rot = any(nxtour[k:] + nxtour[:k] in (order, [order[0]] + order[1:][::-1]) for k in range(g.n))
        checks.append("= NetworkX christofides (as a cycle)" if rot or same else f"NetworkX christofides weight {fmtv(nx_w)}")
        if g.n <= 9:
            b = brute_tsp(g)
            if is_metric(g):
                if ours_w > 1.5 * b[0] + 1e-9:
                    fail(f"{name}: christofides above 3/2")
                checks.append(f"metric; <= 3/2 x optimum {fmtv(b[0])}")
            else:
                checks.append(f"not metric; optimum {fmtv(b[0])}")
        jg_claim("CHR " + jg_edges(g, True), (lambda have, b=ours_w, met=is_metric(g), gg=g:
                                               None if (not met or gg.n > 9 or float(have) <= 1.5 * brute_tsp(gg)[0] + 1e-9) else f"weight {have} above 3/2 OPT"),
                 "ChristofidesThreeHalvesApproxMetricTSP")
    add("ChristofidesTour", name, g.text(), "christofidesTour(weight:)", tour_text(g, None if r is None else r[0]), checks)


def two_opt_rows(name, g, initial=None):
    if g.n < 3:
        add("TwoOptTour", name, g.text(), "twoOptTour(weight:)", "nil", [])
        return
    start = nearest_neighbor(g, 0) if initial is None else initial
    order = two_opt(g, start)
    checks = []
    if not two_opt_optimal(g, order):
        fail(f"{name}: not 2-optimal")
    checks.append("2-optimal (no improving move)")
    W = simple_weights(g)
    if tour_weight(W, order) > tour_weight(W, start):
        fail(f"{name}: 2-opt got worse")
    checks.append(f"from {labs(g, start)}, weight {fmtv(tour_weight(W, start))}")
    jg_claim("TWO " + jg_edges(g, True) + " " + " ".join(str(x) for x in start),
             " ".join(str(x) for x in order + [order[0]]), "TwoOptHeuristicTSP.improveTour")
    checks.append("= JGraphT TwoOptHeuristicTSP.improveTour")
    checks.append(opt_note(g))
    if initial is None:
        call = "twoOptTour(weight:)"
    else:
        call = f"twoOptTour(improving: {labs(g, initial)}, weight:)"
    add("TwoOptTour" if initial is None else "TwoOptTourImproving", name, g.text(), call, tour_text(g, order), checks)


def shortest_rows(name, g):
    order = held_karp(g)
    checks = []
    if g.n >= 3 and g.n <= 9:
        b = brute_tsp(g)
        if (b is None) != (order is None) or (b and (b[1] != order)):
            fail(f"{name}: held-karp {order} vs brute {b}")
        checks.append("= brute force (optimum, then lexicographically least)")
    if g.n >= 3:
        jg_claim("HK 0 " + jg_edges(g, False), "null" if order is None else " ".join(str(x) for x in order + [0]), "HeldKarpTSP")
        checks.append("= JGraphT HeldKarpTSP")
    elif g.n >= 1:
        checks.append("JGraphT HeldKarpTSP: a closed walk (singleton or a,b,a)")
    add("ShortestTour", name, g.text(), "shortestTour(weight:)", tour_text(g, order), checks)


def weighted(g, W, wtype="Int", token=None):
    return G(g.labels, [(g.lab(u), g.lab(v)) for u, v in g.E], g.directed, w=W, token=token, wtype=wtype)


# ---------------------------------------------------------------------------------------------
# The catalog


def build():
    # ----- Eulerian, undirected
    U = []
    U.append(("empty graph", G([], [])))
    U.append(("one vertex", G([0], [])))
    U.append(("two isolated vertices (isolated vertices ignored)", G([0, 1], [])))
    U.append(("one self-loop", G([0], [(0, 0)])))
    U.append(("two self-loops at one vertex", G([0], [(0, 0), (0, 0)])))
    U.append(("self-loop beside an isolated vertex", G([0, 1], [(1, 1)])))
    U.append(("self-loops at two vertices: two components with edges", G([0, 1], [(0, 0), (1, 1)])))
    U.append(("one edge: a trail, no circuit", G([0, 1], [(0, 1)])))
    U.append(("two parallel edges: a circuit of length 2", G([0, 1], [(0, 1), (0, 1)])))
    U.append(("three parallel edges: odd at both ends", G([0, 1], [(0, 1), (1, 0), (0, 1)])))
    U.append(("path P(3)", P(3)))
    U.append(("path P(4)", P(4)))
    U.append(("triangle C(3)", C(3)))
    U.append(("cycle C(5)", C(5)))
    U.append(("triangle beside an isolated vertex", G([0, 1, 2, 3], [(0, 1), (1, 2), (2, 0)])))
    U.append(("isolated first vertex: the circuit starts at the first vertex with an edge", G([0, 1, 2, 3], [(1, 2), (2, 3), (3, 1)])))
    U.append(("two triangles apart", G(range(6), [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)])))
    U.append(("bowtie: two triangles at a shared vertex", G(range(5), [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)])))
    U.append(("triangle with a loop: loops add 2", G([0, 1, 2], [(0, 1), (0, 0), (1, 2), (2, 0)])))
    U.append(("edge with a loop at the end: odd 0 and 1", G([0, 1], [(0, 1), (1, 1)])))
    U.append(("loop at a vertex, an edge elsewhere: two components", G([0, 1, 2], [(0, 0), (1, 2)])))
    U.append(("star(3): four odd vertices", G(range(4), [(0, 1), (0, 2), (0, 3)])))
    U.append(("K(4): every degree 3", K(4)))
    U.append(("K(5): every degree 4", K(5)))
    U.append(("Königsberg: seven bridges, four odd land masses", G(["A", "B", "C", "D"], [("A", "B"), ("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")])))
    U.append(("Königsberg less one A–B bridge: a trail", G(["A", "B", "C", "D"], [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")])))
    U.append(("house: odd at the base", G(range(5), [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 3)])))
    U.append(("vertex order, not label order", G(["d", "a", "c", "b"], [("a", "c"), ("c", "b"), ("b", "a"), ("d", "a"), ("d", "c")])))
    U.append(("odd vertices last in the order", G(range(5), [(4, 3), (3, 0), (0, 1), (1, 2), (2, 0), (0, 4), (4, 1)])))
    U.append(("grid(3,3): four odd corners' neighbours", grid(3, 3)))
    U.append(("Petersen: every degree 3", named("petersen_graph")))
    U.append(("octahedral: every degree 4", named("octahedral_graph")))
    U.append(("wheel(4): rim odd", wheel(4)))
    U.append(("K(3,3) less nothing: degree 3", Kb(3, 3)))
    U.append(("Kb(2,4): even sides", Kb(2, 4)))
    U.append(("rows decide: the first edge out of 0 is the second chord", G(range(5), [(0, 3), (0, 1), (1, 2), (2, 0), (3, 4), (4, 0)])))
    U.append(("parallel edges inside a longer circuit", G(range(3), [(0, 1), (1, 2), (1, 2), (1, 2), (2, 0), (1, 1)])))
    U.append(("lcgwalk(6,14,1)", lcgwalk(6, 14, 1)))
    U.append(("lcgwalk(8,30,2)", lcgwalk(8, 30, 2)))
    U.append(("lcgwalk(5,20,3,open)", lcgwalk(5, 20, 3, closed=False)))
    U.append(("lcgwalk(10,40,4,open)", lcgwalk(10, 40, 4, closed=False)))
    for name, g in U:
        euler_rows("", name, g)

    D = []
    D.append(("empty digraph", G([], [], True)))
    D.append(("one vertex", G([0], [], True)))
    D.append(("one self-loop: in 1, out 1", G([0], [(0, 0)], True)))
    D.append(("one edge 0→1", G([0, 1], [(0, 1)], True)))
    D.append(("antiparallel pair", G([0, 1], [(0, 1), (1, 0)], True)))
    D.append(("parallel pair 0→1 twice: unbalanced by 2", G([0, 1], [(0, 1), (0, 1)], True)))
    D.append(("directed cycle Cd(3)", C(3, True)))
    D.append(("directed path Pd(4)", P(4, True)))
    D.append(("two sources: no trail", G(range(3), [(0, 2), (1, 2)], True)))
    D.append(("balanced but two components", G(range(4), [(0, 1), (1, 0), (2, 3), (3, 2)], True)))
    D.append(("Cd(3) beside an isolated vertex", G(range(4), [(0, 1), (1, 2), (2, 0)], True)))
    D.append(("isolated first vertex", G(range(4), [(1, 2), (2, 3), (3, 1)], True)))
    D.append(("start is the vertex with out − in = 1, not the first", G(range(4), [(1, 2), (2, 0), (0, 1), (2, 3), (3, 1), (1, 3)], True)))
    D.append(("two directed cycles at a shared vertex", G(range(5), [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)], True)))
    D.append(("loop on a directed cycle", G(range(3), [(0, 1), (1, 1), (1, 2), (2, 0)], True)))
    D.append(("Cd(3) with a chord: a trail from 0", G(range(3), [(0, 1), (1, 2), (2, 0), (0, 2)], True)))
    D.append(("in − out = 2 at one vertex", G(range(3), [(0, 2), (1, 2), (2, 1), (1, 0), (0, 2)], True)))
    D.append(("Kd(3): every in = out = 2", K(3, True)))
    D.append(("Kd(4)", K(4, True)))
    D.append(("self-loop and an edge elsewhere", G(range(3), [(0, 0), (1, 2)], True)))
    D.append(("lcgwalkd(6,14,1)", lcgwalk(6, 14, 1, directed=True)))
    D.append(("lcgwalkd(8,30,2)", lcgwalk(8, 30, 2, directed=True)))
    D.append(("lcgwalkd(5,20,3,open)", lcgwalk(5, 20, 3, directed=True, closed=False)))
    D.append(("lcgwalkd(9,40,5,open)", lcgwalk(9, 40, 5, directed=True, closed=False)))
    for name, g in D:
        euler_rows("Directed", name, g)

    # ----- From a given start
    g = C(4)
    for s in range(2):
        circuit_from_rows("EulerianCircuitFrom", f"C(4) from {s}", g, s)
    g = G(range(5), [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)])
    circuit_from_rows("EulerianCircuitFrom", "bowtie from the shared vertex", g, 2)
    circuit_from_rows("EulerianCircuitFrom", "bowtie from a wing", g, 4)
    g = G(range(4), [(0, 1), (1, 2), (2, 0)])
    circuit_from_rows("EulerianCircuitFrom", "isolated start: nil", g, 3, "no circuit starts at a vertex without edges")
    circuit_from_rows("EulerianCircuitFrom", "not Eulerian: nil", P(3), 1)
    circuit_from_rows("EulerianCircuitFrom", "edgeless: nil (a circuit has an edge)", G([0, 1], []), 0)
    circuit_from_rows("EulerianCircuitFrom", "one self-loop", G([0], [(0, 0)]), 0)
    gd = G(range(5), [(0, 1), (1, 2), (2, 0), (0, 3), (3, 4), (4, 0)], True)
    circuit_from_rows("EulerianCircuitFromDirected", "two directed cycles from 3", gd, 3)
    circuit_from_rows("EulerianCircuitFromDirected", "Kd(3) from 2", K(3, True), 2)
    circuit_from_rows("EulerianCircuitFromDirected", "unbalanced: nil", P(3, True), 0)

    g = P(4)
    trail_from_rows("EulerianTrailFrom", "P(4) from 0", g, 0)
    trail_from_rows("EulerianTrailFrom", "P(4) from 3: the other odd end", g, 3)
    trail_from_rows("EulerianTrailFrom", "P(4) from an even vertex: nil", g, 1)
    trail_from_rows("EulerianTrailFrom", "Eulerian: a closed trail from any vertex with an edge", C(4), 2)
    trail_from_rows("EulerianTrailFrom", "Eulerian, isolated start: nil", G(range(4), [(0, 1), (1, 2), (2, 0)]), 3)
    trail_from_rows("EulerianTrailFrom", "edgeless: the trivial trail at the start", G([0, 1], []), 1)
    trail_from_rows("EulerianTrailFrom", "no trail: nil", K(4), 0)
    kn = G(["A", "B", "C", "D"], [("A", "B"), ("A", "C"), ("A", "C"), ("A", "D"), ("B", "D"), ("C", "D")])
    trail_from_rows("EulerianTrailFrom", "Königsberg less one bridge, from D", kn, 3)
    trail_from_rows("EulerianTrailFrom", "loop at the end vertex", G([0, 1], [(0, 1), (1, 1)]), 1)
    trail_from_rows("EulerianTrailFromDirected", "Pd(4) from 0", P(4, True), 0)
    trail_from_rows("EulerianTrailFromDirected", "Pd(4) from the end: nil", P(4, True), 3)
    trail_from_rows("EulerianTrailFromDirected", "Cd(3) from 1", C(3, True), 1)
    trail_from_rows("EulerianTrailFromDirected", "chord: from 0 only", G(range(3), [(0, 1), (1, 2), (2, 0), (0, 2)], True), 2)

    # ----- Traps (Eulerian)
    trap("EulerianCircuitFrom", "start not a vertex", "C(3)", "eulerianCircuit(from: 7)", "the start is not a vertex of the graph")
    trap("EulerianTrailFrom", "start not a vertex", "P(3)", "eulerianTrail(from: 7)", "the start is not a vertex of the graph")
    trap("EulerianCircuitFromDirected", "start not a vertex", "Cd(3)", "eulerianCircuit(from: 7)", "the start is not a vertex of the graph")
    trap("EulerianTrailFromDirected", "start not a vertex", "Pd(3)", "eulerianTrail(from: 7)", "the start is not a vertex of the graph")
    trap("EulerianCircuitFrom", "start not a vertex of the empty graph", "V []; E []", "eulerianCircuit(from: 0)", "the start is not a vertex of the graph")

    # ----- Hamiltonian, undirected
    H = [
        ("empty graph", G([], [])),
        ("one vertex", G([0], [])),
        ("one vertex with a self-loop: a cycle of length 1", G([0], [(0, 0)])),
        ("two vertices, one edge: a path, no cycle", G([0, 1], [(0, 1)])),
        ("two parallel edges: a cycle of length 2", G([0, 1], [(0, 1), (1, 0)])),
        ("two isolated vertices", G([0, 1], [])),
        ("self-loops never help", G([0, 1, 2], [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)])),
        ("triangle", C(3)),
        ("path P(5)", P(5)),
        ("cycle C(6)", C(6)),
        ("star(3): no path", G(range(4), [(0, 1), (0, 2), (0, 3)])),
        ("K(4)", K(4)),
        ("K(5)", K(5)),
        ("Kb(2,3): a path, no cycle", Kb(2, 3)),
        ("Kb(3,3)", Kb(3, 3)),
        ("Kb(2,4): no path", Kb(2, 4)),
        ("triangle with a pendant: a path, no cycle", G(range(4), [(0, 1), (1, 2), (2, 0), (2, 3)])),
        ("two triangles apart: none", G(range(6), [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3)])),
        ("bowtie: a path, no cycle", G(range(5), [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 2)])),
        ("vertex order, not label order", G(["d", "a", "c", "b"], [("a", "c"), ("c", "b"), ("b", "d"), ("d", "a"), ("a", "b")])),
        ("parallel copies: the first in the row", G(range(3), [(0, 2), (0, 1), (0, 1), (1, 2), (2, 0)])),
        ("rows decide: the first edge of 0 leads to the dead end", G(range(4), [(0, 3), (0, 1), (1, 2), (2, 3)])),
        ("wheel(5)", wheel(5)),
        ("grid(3,3): a path, no cycle (odd bipartite)", grid(3, 3)),
        ("grid(3,4)", grid(3, 4)),
        ("Petersen: a path, no cycle", named("petersen_graph")),
        ("dodecahedral", named("dodecahedral_graph")),
        ("knight(3,4): open tour", knight(3, 4)),
        ("knight(4,4): no tour at all", knight(4, 4)),
        ("lcg(10,20,1)", lcg(10, 20, 1)),
        ("lcg(12,30,2)", lcg(12, 30, 2)),
        ("lcg(14,22,3): sparse", lcg(14, 22, 3)),
    ]
    for name, g in H:
        ham_rows(name, g)
    HD = [
        ("empty digraph", G([], [], True)),
        ("one vertex with a self-loop", G([0], [(0, 0)], True)),
        ("one edge 0→1: a path, no cycle", G([0, 1], [(0, 1)], True)),
        ("antiparallel pair: a cycle of length 2", G([0, 1], [(0, 1), (1, 0)], True)),
        ("edge 1→0 only: the path starts at 1", G([0, 1], [(1, 0)], True)),
        ("directed cycle Cd(4)", C(4, True)),
        ("directed path Pd(4)", P(4, True)),
        ("two sinks: no path", G(range(3), [(0, 1), (0, 2)], True)),
        ("Kd(4)", K(4, True)),
        ("transitive tournament: one path, no cycle", G(range(4), [(i, j) for i in range(4) for j in range(i + 1, 4)], True)),
        ("tournament(6,1)", tournament(6, 1)),
        ("tournament(8,2)", tournament(8, 2)),
        ("lcgd(9,25,1)", lcg(9, 25, 1, True)),
        ("lcgd(10,40,2)", lcg(10, 40, 2, True)),
    ]
    for name, g in HD:
        ham_rows(name, g)

    for s in range(3):
        ham_from_rows(f"P(3) from {s}", P(3), s)
    ham_from_rows("C(5) from 2", C(5), 2)
    ham_from_rows("Petersen from 4", named("petersen_graph"), 4)
    ham_from_rows("P(4) from 0 to 3", P(4), 0, 3)
    ham_from_rows("P(4) from 0 to 2: nil", P(4), 0, 2)
    ham_from_rows("K(4) from 1 to 0", K(4), 1, 0)
    ham_from_rows("one vertex from 0 to 0: the trivial path", G([0], []), 0, 0)
    ham_from_rows("same ends, two vertices: nil", P(2), 0, 0)
    ham_from_rows("grid(3,3) from corner to corner", grid(3, 3), 0, 8)
    ham_from_rows("grid(3,3) from corner to an edge midpoint: nil (parity)", grid(3, 3), 0, 1)
    ham_from_rows("Pd(3) from 0", P(3, True), 0)
    ham_from_rows("Pd(3) from 1: nil", P(3, True), 1)
    ham_from_rows("Kd(4) from 3 to 2", K(4, True), 3, 2)
    trap("HamiltonianPathFrom", "start not a vertex", "P(3)", "hamiltonianPath(from: 7)", "the start is not a vertex of the graph")
    trap("HamiltonianPathFrom", "end not a vertex", "P(3)", "hamiltonianPath(from: 0, to: 7)", "the end is not a vertex of the graph")
    trap("HamiltonianPathFromDirected", "start not a vertex", "Pd(3)", "hamiltonianPath(from: 7)", "the start is not a vertex of the graph")

    # ----- Tours
    sq = pts_graph([(0, 0), (0, 1), (1, 1), (1, 0)], "pts[(0,0),(0,1),(1,1),(1,0)]")
    T = [
        ("square: the perimeter", sq),
        ("square listed crosswise", pts_graph([(0, 0), (1, 1), (0, 1), (1, 0)], "pts[(0,0),(1,1),(0,1),(1,0)]")),
        ("five points on a line", pts_graph([(0, 0), (3, 0), (1, 0), (4, 0), (2, 0)], "pts[(0,0),(3,0),(1,0),(4,0),(2,0)]")),
        ("all weights equal: K(5) weight 1", weighted(K(5), [1] * 10, token="K(5) weight 1")),
        ("K(4) with weights 1..6", weighted(K(4), [1, 2, 3, 4, 5, 6], token="K(4) weights 1, 2, 3, 4, 5, 6 in edge order")),
        ("lcgpts(6,1,10)", lcgpts(6, 1, 10)),
        ("lcgpts(8,2,20)", lcgpts(8, 2, 20)),
        ("lcgpts(9,3,30)", lcgpts(9, 3, 30)),
        ("lcgK(7,4,9): not metric", lcgK(7, 4, 9)),
        ("lcgK(8,5,20): not metric", lcgK(8, 5, 20)),
        ("lcgK(6,6,9,/4): Double weights", lcgK(6, 6, 9, "Double")),
        ("negative weights", weighted(K(4), [-1, 2, -3, 4, 0, -2], token="K(4) weights -1, 2, -3, 4, 0, -2")),
        ("parallel copies: the lightest", G(range(3), [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)], w=[5, 2, 1, 3, 3])),
        ("self-loops ignored", G(range(3), [(0, 0), (0, 1), (1, 2), (1, 1), (2, 0)], w=[-9, 1, 2, -9, 3])),
        ("vertex order, not label order", G(["d", "a", "c", "b"], [("d", "a"), ("d", "c"), ("d", "b"), ("a", "c"), ("a", "b"), ("c", "b")], w=[1, 4, 2, 2, 5, 1])),
    ]
    small = [
        ("one vertex: nil", G([0], [], w=[])),
        ("two vertices: nil", G([0, 1], [(0, 1)], w=[3])),
        ("two vertices, parallel edges: nil (tours read the simple graph)", G([0, 1], [(0, 1), (0, 1)], w=[3, 4])),
        ("empty graph: nil", G([], [], w=[])),
    ]
    for name, g in T + small:
        nn_rows(name, g)
    for name, g in [("square from 2", sq), ("lcgpts(8,2,20) from 5", lcgpts(8, 2, 20)), ("lcgK(7,4,9) from 3", lcgK(7, 4, 9))]:
        nn_rows(name, g, int(name.split()[-1]))
    for name, g in T + small:
        christofides_rows(name, g)
    christofides_rows("lcgpts(12,7,50)", lcgpts(12, 7, 50))
    christofides_rows("lcgpts(16,8,100)", lcgpts(16, 8, 100))
    for name, g in T + small:
        two_opt_rows(name, g)
    two_opt_rows("lcgpts(12,7,50)", lcgpts(12, 7, 50))
    two_opt_rows("lcgpts(20,9,100)", lcgpts(20, 9, 100))
    two_opt_rows("crossed square", sq, [0, 2, 1, 3])
    two_opt_rows("already 2-optimal: unchanged", sq, [0, 1, 2, 3])
    two_opt_rows("reversed start: the first vertex stays", sq, [3, 2, 1, 0])
    two_opt_rows("lcgpts(9,3,30) from index order", lcgpts(9, 3, 30), list(range(9)))
    two_opt_rows("lcgK(8,5,20) from index order", lcgK(8, 5, 20), list(range(8)))
    for name, g in T + small:
        shortest_rows(name, g)
    shortest_rows("not complete: C(5) is its only tour", weighted(C(5), [1, 2, 3, 4, 5], token="C(5) weights 1, 2, 3, 4, 5"))
    shortest_rows("not complete, no Hamiltonian cycle: nil", weighted(G(range(4), [(0, 1), (0, 2), (0, 3), (1, 2)]), [1, 1, 1, 1]))
    shortest_rows("Petersen weight 1: nil", weighted(named("petersen_graph"), [1] * 15, token="nx(petersen_graph) weight 1"))
    shortest_rows("lcgpts(12,7,50)", lcgpts(12, 7, 50))

    trap("NearestNeighborTour", "not complete", "C(4) weight 1", "nearestNeighborTour(weight:)", "the graph is not complete (0 and 2 are not adjacent)")
    trap("ChristofidesTour", "not complete", "C(4) weight 1", "christofidesTour(weight:)", "the graph is not complete")
    trap("TwoOptTour", "not complete", "C(4) weight 1", "twoOptTour(weight:)", "the graph is not complete")
    trap("TwoOptTourImproving", "tour misses a vertex", "pts[(0,0),(0,1),(1,1),(1,0)]", "twoOptTour(improving: [0, 1, 2], weight:)", "the tour does not list every vertex once")
    trap("TwoOptTourImproving", "tour repeats a vertex", "pts[(0,0),(0,1),(1,1),(1,0)]", "twoOptTour(improving: [0, 1, 2, 1], weight:)", "the tour does not list every vertex once")
    trap("NearestNeighborTour", "start not a vertex", "pts[(0,0),(0,1),(1,1),(1,0)]", "nearestNeighborTour(from: 7, weight:)", "the start is not a vertex of the graph")
    trap("NearestNeighborTour", "NaN weight", "Double K(3) weights 1.0, nan, 2.0", "nearestNeighborTour(weight:)", "a weight is NaN")
    trap("ChristofidesTour", "NaN weight", "Double K(3) weights 1.0, nan, 2.0", "christofidesTour(weight:)", "a weight is NaN")
    trap("ShortestTour", "NaN weight", "Double K(3) weights 1.0, nan, 2.0", "shortestTour(weight:)", "a weight is NaN")
    trap("ShortestTour", "too many vertices", "K(32) weight 1", "shortestTour(weight:)", "more than 31 vertices (JGraphT HeldKarpTSP's limit)")


# ---------------------------------------------------------------------------------------------
# Stress


def stress():
    rng = random.Random(20261010)
    counts = {"euler": 0, "hamilton": 0, "tsp": 0}
    for trial in range(1500):
        n = rng.randint(1, 8)
        directed = rng.random() < 0.5
        kind = rng.random()
        if kind < 0.5:
            walk = [rng.randrange(n) for _ in range(rng.randint(1, 14))]
            if rng.random() < 0.6:
                walk.append(walk[0])
            E = [(walk[i], walk[i + 1]) for i in range(len(walk) - 1)]
            rng.shuffle(E)
            if not directed:
                E = [(u, v) if rng.random() < .5 else (v, u) for u, v in E]
        else:
            E = [(rng.randrange(n), rng.randrange(n)) for _ in range(rng.randint(0, 12))]
        g = G(range(n), E, directed)
        eu, tr, _ = euler_status(g)
        # brute force: an Eulerian trail / circuit by search over edge orders (m <= 8)
        if g.m <= 8:
            bt, bc = brute_euler(g)
            if g.m == 0:
                bt, bc = g.n > 0 or True, True
            if (bt, bc) != (tr, eu):
                fail(f"stress euler {trial}: brute {(bt, bc)} vs {(tr, eu)} on {E} directed={directed} n={n}")
        res = euler_circuit(g)
        if res is not None and not check_trail(g, res[0], res[1], True):
            fail(f"stress circuit {trial}")
        res = euler_trail(g)
        if res is not None and g.m and not check_trail(g, res[0], res[1], False):
            fail(f"stress trail {trial}")
        for k in ("is", "path", "cycle"):
            igraph_claim(g, k)
        if g.n:
            jg_claim(f"EUL {1 if directed else 0} {g.n} {g.m} " + " ".join(f"{u} {v}" for u, v in g.E), jg_euler_expect(g), "stress HierholzerEulerianCycle")
        facts = nx_euler_facts(g)
        nx_expect = (eu and edge_cover_all(g)) if g.n else "NetworkXPointlessConcept"
        if facts["is_eulerian"] != nx_expect:
            fail(f"stress {trial}: NetworkX is_eulerian {facts['is_eulerian']} vs {nx_expect} on {E}")
        if not directed and not g.multi() and g.m and tr and nx.has_eulerian_path(nx_graph(g)):
            # NetworkX's Hierholzer is ours on G.copy()'s adjacency (api.md).
            h = nx_graph(g)
            c = h.copy()
            pos = {(min(u, v), max(u, v)): e for e, (u, v) in enumerate(g.E)}
            rows = [[(pos[(min(v, x), max(v, x))], x) for x in c.adj[v]] for v in range(g.n)]
            s0 = euler_status(g)[2]
            if hierholzer(g, s0, rows)[0] != nx_sequence(list(nx.eulerian_path(h, source=s0)), False):
                fail(f"stress {trial}: NetworkX eulerian_path is not Hierholzer on its copy's rows")
            counts["networkx order"] = counts.get("networkx order", 0) + 1
        counts["euler"] += 1
    simple = 0
    while simple < 200:
        # Simple graphs with an Eulerian trail: the NetworkX row-order claim, on a batch of its own.
        n = rng.randint(2, 8)
        walk = [rng.randrange(n) for _ in range(rng.randint(2, 12))]
        if rng.random() < 0.5:
            walk.append(walk[0])
        E, seen = [], set()
        for u, v in zip(walk, walk[1:]):
            k = (min(u, v), max(u, v))
            if u != v and k not in seen:
                seen.add(k)
                E.append((u, v))
        g = G(range(n), E)
        h = nx_graph(g)
        if not E or not euler_status(g)[1] or not nx.has_eulerian_path(h):
            continue
        c = h.copy()
        pos = {(min(u, v), max(u, v)): e for e, (u, v) in enumerate(g.E)}
        rows = [[(pos[(min(v, x), max(v, x))], x) for x in c.adj[v]] for v in range(g.n)]
        s0 = euler_status(g)[2]
        if hierholzer(g, s0, rows)[0] != nx_sequence(list(nx.eulerian_path(h, source=s0)), False):
            fail(f"stress simple {simple}: NetworkX eulerian_path is not Hierholzer on its copy's rows")
        simple += 1
    counts["networkx order"] = counts.get("networkx order", 0) + simple
    for trial in range(400):
        n = rng.randint(1, 7)
        directed = rng.random() < 0.5
        E = [(rng.randrange(n), rng.randrange(n)) for _ in range(rng.randint(0, 3 * n))]
        g = G(range(n), E, directed)
        for res, b in ((ham_path(g), ham_brute(g)), (ham_cycle(g), ham_brute(g, cycle=True))):
            if (res is None) != (b is None) or (res is not None and (res[0], res[1]) != (b[0], b[1])):
                fail(f"stress hamilton {trial}: {res} vs {b} on {E} directed={directed}")
        if (ham_path(g) is not None) != ham_dp_exists(g) or (ham_cycle(g) is not None) != ham_dp_exists(g, cycle=True):
            fail(f"stress hamilton DP {trial}")
        counts["hamilton"] += 1
    for trial in range(300):
        n = rng.randint(3, 8)
        if rng.random() < 0.5:
            pts = [(rng.randrange(20), rng.randrange(20)) for _ in range(n)]
            g = pts_graph(pts, "")
        else:
            g = K(n)
            g.w = [rng.randint(-5, 20) for _ in g.E]
        b = brute_tsp(g)
        hk = held_karp(g)
        if hk != b[1]:
            fail(f"stress held-karp {trial}")
        jg_claim("HK 0 " + jg_edges(g, False), " ".join(str(x) for x in hk + [0]), "stress HeldKarpTSP")
        start = nearest_neighbor(g, 0)
        jm = jgrapht_nn_model(g, 0)
        jg_claim("NN 0 " + jg_edges(g, True), " ".join(str(x) for x in jm), "stress NearestNeighborHeuristicTSP")
        t2 = two_opt(g, start)
        if not two_opt_optimal(g, t2):
            fail(f"stress 2-opt {trial}")
        jg_claim("TWO " + jg_edges(g, True) + " " + " ".join(str(x) for x in start), " ".join(str(x) for x in t2 + [t2[0]]), "stress TwoOpt")
        r = christofides(g)
        W = simple_weights(g)
        if is_metric(g) and tour_weight(W, r[0]) > 1.5 * b[0]:
            fail(f"stress christofides {trial}")
        if brute_matching_weight(W, r[2]) != sum(W[x][y][0] for x, y in r[3]):
            fail(f"stress matching {trial}")
        counts["tsp"] += 1
    print("stress: " + ", ".join(f"{k} {v}" for k, v in counts.items()) + " random cases pass")


def edge_cover_all(g):
    """NetworkX's extra condition: every vertex is touched (or the graph has one vertex)."""
    if g.n == 1:
        return True
    out, inn = degrees(g)
    return all(out[v] + inn[v] > 0 for v in range(g.n))


def brute_euler(g):
    """(has trail, has circuit) by depth-first search over edge sequences."""
    m = g.m
    rows = g.rows()
    has_trail = has_circuit = False
    for s in range(g.n):
        used = [False] * m

        def go(v, k):
            nonlocal has_trail, has_circuit
            if k == m:
                has_trail = True
                if v == s:
                    has_circuit = True
                return
            for e, x in rows[v]:
                if not used[e]:
                    used[e] = True
                    go(x, k + 1)
                    used[e] = False

        go(s, 0)
    return has_trail, has_circuit


HEADER = """# Tours: case catalog (TO-001 – TO-{last}, {count} cases)

Generated and checked by `ref.py` (`uv run --quiet --no-project --with networkx==3.7 --with
igraph==1.0.0 --with rustworkx==0.18.1 python3 Tests/Catalogs/Tours/ref.py`; without `--write` it
renders the catalog and compares it with this file byte for byte; `--write` regenerates it and
needs `IGRAPH_C_LIB` and `JGRAPHT_CLASSPATH`; `--stress` adds about 2,200 random graphs). Expected
is the API's documented output (api.md, Determinism); the last column says what each row was
checked against.

## Notation

* **Graphs.** `V [..]; E [..]`: vertices in order (their vertex indices), then edges at positions
  0, 1, …, each `u-v` (undirected, an `UndirectedAdjacencyList` built by inserting `E` in order)
  or `u→v` (directed, an `AdjacencyList`), with its weight after it in tour rows. Rows
  list incident edges in position order (a self-loop twice, consecutively). `multigraph` rows have
  parallel edges or self-loops: `Pseudograph` / `DirectedPseudograph`. A leading `Double` is the
  weight type (default `Int`).
* **Generators.** `K(n)` every pair i < j lexicographic; `Kd(n)` every ordered pair i ≠ j, i then j
  ascending; `C(n)` / `Cd(n)` edges i–(i+1) mod n; `P(n)` / `Pd(n)` edges i–(i+1); `Kb(a,b)` left
  0..<a, right a..<a+b, row-major; `wheel(k)` hub 0, spokes 0–i, then rim i–(i mod k + 1);
  `grid(r,c)` vertex i·c+j, edges right then down, row-major; `knight(r,c)` square i·c+j, from each
  square in row-major order its moves (+1,+2), (+2,+1), (+2,−1), (+1,−2) on the board;
  `nx(name)` NetworkX's graph, nodes and `edges()` in order. A 64-bit LCG, x ← x·6364136223846793005
  + 1442695040888963407 (mod 2⁶⁴), each draw x >> 33: `lcgwalk(n,len,seed)` a walk from 0 of `len`
  steps, each to vertex d % n (staying put is a self-loop), closed by an edge back to 0 unless it
  ended there, its edges in walk order (`,open`: not closed); `lcgwalkd` the same directed;
  `lcg(n,m,seed)` / `lcgd` m edges u = d % n, v = d % n, loops and repeated pairs skipped;
  `tournament(n,seed)` for each i < j, i→j when d is even, else j→i. `pts[(x,y), …]` the complete
  graph on the points (pairs i < j lexicographic) weighted by Manhattan distance, a metric;
  `lcgpts(n,seed,s)` n points (d % s, d % s); `lcgK(n,seed,w)` K(n) with weight 1 + d % w per edge
  in edge order (`,/4`: that over 4, `Double`).
* **Results.** `circuit [..]; edges [..]` a `Circuit` (its vertices, the start not repeated, and
  edge positions, edge i from vertex i to vertex i + 1 mod count); `trail`, `path` the same for a
  `Trail` / `Path` (one more vertex than edges); `cycle [..]; edges [..]; weight w` a `Cycle`,
  with `cycle.weight(weight)` in tour rows. `nil` is no result.
* **Checked.** "= igraph …" compares with igraph 1.0's C functions `igraph_is_eulerian`,
  `igraph_eulerian_cycle`, `igraph_eulerian_path` (python-igraph 1.0 does not expose them); its
  rows list incident edges by neighbor, then edge id descending, so its Hierholzer walk can differ
  from ours. NetworkX conventions differ where noted (it counts isolated vertices, raises on the
  null graph, lists an undirected circuit backward). JGraphT is 1.5.2.
* **trap** rows are preconditions: tests run them as exit tests (`#expect(processExitsWith:)`).

| ID | Group | Case | Input | Call | Expected | Checked |
|---|---|---|---|---|---|---|
"""


def render():
    out = HEADER.replace("{last}", f"{len(CASES):03d}").replace("{count}", str(len(CASES)))
    for i, (grp, name, inp, call, exp, chk) in enumerate(CASES):
        out += f"| TO-{i + 1:03d} | {grp} | {name} | {inp} | `{call}` | {exp} | {chk} |\n"
    return out


def main():
    if "--igraph-worker" in sys.argv:
        igraph_worker()
        return
    here = os.path.dirname(os.path.abspath(__file__))
    if "--write" in sys.argv and not (os.environ.get("IGRAPH_C_LIB") and os.environ.get("JGRAPHT_CLASSPATH")):
        print("--write needs IGRAPH_C_LIB and JGRAPHT_CLASSPATH, so that every igraph and JGraphT claim is checked")
        sys.exit(2)
    build()
    n_rows = len(CASES)
    if "--stress" in sys.argv:
        stress()
    ran_ig = run_igraph()
    ran_jg = run_jgrapht()
    if FAILS:
        print("\n".join(FAILS[:50]))
        print(f"{len(FAILS)} failures")
        sys.exit(1)
    del CASES[n_rows:]
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
    native = []
    native.append(f"igraph C {len(IGRAPH_CALLS)} calls agree" if ran_ig else "igraph C skipped (IGRAPH_C_LIB unset)")
    native.append(f"JGraphT {len(JG_CALLS)} calls agree" if ran_jg else "JGraphT skipped (JGRAPHT_CLASSPATH unset)")
    print(f"{len(CASES)} cases; all values agree; cases.md matches; " + "; ".join(native))


if __name__ == "__main__":
    main()
